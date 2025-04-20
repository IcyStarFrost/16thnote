SXNOTE = SXNOTE or {}
util.AddNetworkString( "16thnote_combatstatus" )

-- Checks whether the player is in combat or not
function SXNOTE:InCombat( ply )
    local enemyrequirement = ply:GetInfoNum( "16thnote_combatthreshold", 1 )
    local losonly = tobool( ply:GetInfoNum( "16thnote_los", 0 ) )
    local totalenemies = 0

    if ply.SXNOTEPlayerAttacked and ply.SXNOTEPlayerAttacked > CurTime() then
        return true
    end

    for _, ent in ents.Iterator() do
        if ent.GetEnemy and IsValid( ent:GetEnemy() ) and ( ent:GetEnemy():IsPlayer() and ent:GetEnemy() == ply ) and ( losonly and ent:Visible( ent:GetEnemy() ) or !losonly )  then
            totalenemies = totalenemies + 1
        end
    end

    return totalenemies >= enemyrequirement
end


-- Allows PVP music
hook.Add( "PostEntityFireBullets", "16thnote_playernearshot", function( ent, data ) 
    for k, ply in player.Iterator() do
        if ply:Visible( ent ) and ply:GetInfoNum( "16thnote_pvp", 0 ) == 1 and data.Trace.Normal:Dot( ( ply:WorldSpaceCenter() - ent:WorldSpaceCenter() ):GetNormalized() ) >= 0.97 then
            ply.SXNOTEPlayerAttacked = CurTime() + 5
        end
    end
end )

hook.Add( "PlayerHurt", "16thnote_playerattack", function( ply, attacker, info )
    if attacker:IsPlayer() and ply:GetInfoNum( "16thnote_pvp", 0 ) == 1 then
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