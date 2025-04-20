SXNOTE = SXNOTE or {}
util.AddNetworkString( "16thnote_combatstatus" )

-- If ent2 is visible to ent1
local function Visible( ent1, ent2 )
    local tr = util.TraceLine( {
        start = ent1:WorldSpaceCenter(),
        endpos = ent2:WorldSpaceCenter(),
        mask = MASK_SHOT_HULL,
        collisiongroup = COLLISION_GROUP_WORLD
    } )
    print(tr.Entity)
    return !tr.Hit
end

-- Whether ent poses a threat to the player
local function IsEntAThreat( ent, ply )
    local losonly = tobool( ply:GetInfoNum( "16thnote_los", 0 ) )
    local presence = tobool( ply:GetInfoNum( "16thnote_enemypresence", 0 ) )


    if presence and 
        ent.Disposition and 
        ent:Disposition( ply ) == D_HT and 
        ent:GetPos():DistToSqr( ply:GetPos() ) <= 3000 ^ 2 and 
    ( losonly and Visible( ent, ply ) or !losonly ) then return true end
    
    if ent.GetEnemy and 
        IsValid( ent:GetEnemy() ) and 
        ( ent:GetEnemy():IsPlayer() and 
        ent:GetEnemy() == ply ) and 
    ( losonly and Visible( ent, ent:GetEnemy() ) or !losonly ) then return true end
    return false
end

-- Checks whether the player is in combat or not
function SXNOTE:InCombat( ply )
    local requiredhealthpool = ply:GetInfoNum( "16thnote_healthpoolthreshold", 0 )
    local healthsum = 0

    if ply.SXNOTEPlayerAttacked and ply.SXNOTEPlayerAttacked > CurTime() then
        return true
    end

    for _, ent in ents.Iterator() do
        if IsEntAThreat( ent, ply ) then
            healthsum = healthsum + ent:GetMaxHealth()
        end
    end

    return healthsum >= requiredhealthpool
end


-- Allows PVP music
hook.Add( "PostEntityFireBullets", "16thnote_playernearshot", function( ent, data )
    if !IsValid( data.Attacker ) or !data.Attacker:IsPlayer()  then return end
    for k, ply in player.Iterator() do
        if ply:Visible( ent ) and ply:GetInfoNum( "16thnote_pvp", 0 ) == 1 and data.Trace.Normal:Dot( ( ply:WorldSpaceCenter() - ent:WorldSpaceCenter() ):GetNormalized() ) >= 0.97 then
            ply.SXNOTEPlayerAttacked = CurTime() + 5
        end
    end
end )

hook.Add( "PlayerHurt", "16thnote_playerattack", function( ply, attacker, info )
    if attacker != ply and attacker:IsPlayer() and ply:GetInfoNum( "16thnote_pvp", 0 ) == 1 then
        ply.SXNOTEPlayerAttacked = CurTime() + 5
    end
end )

-- Main function for informing the clients that they are being targetted or not
local cooldown = 0
hook.Add( "Tick", "16thnote_combatdetermine", function()
    if CurTime() < cooldown then return end

    for _, ply in player.Iterator() do
        local incombat = SXNOTE:InCombat( ply )

        if incombat then
            ply.SXNOTEWaitOff = CurTime() + 4 -- Prevents the combat track from instantly fading out
        end

        if incombat and !ply.SXNOTEInCombat then
            ply.SXNOTEInCombat = true

            net.Start( "16thnote_combatstatus" )
            net.WriteBool( true )
            net.Send( ply )
        elseif !incombat and ply.SXNOTEInCombat and ( ply.SXNOTEWaitOff and CurTime() > ply.SXNOTEWaitOff or !ply.SXNOTEWaitOff ) then
            ply.SXNOTEInCombat = false

            net.Start( "16thnote_combatstatus" )
            net.WriteBool( false )
            net.Send( ply )
        end
    end

    cooldown = CurTime() + 0.5 -- No need to run this hook every tick.
end )