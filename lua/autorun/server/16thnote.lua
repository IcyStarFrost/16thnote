SXNOTE = SXNOTE or {}
util.AddNetworkString( "16thnote_combatstatus" )

-- Checks whether the player is being targetted or not
function SXNOTE:PlyBeingTargetted( ply )
    local losonly = tobool( ply:GetInfoNum( "16thnote_los", 0 ) )
    for _, ent in ents.Iterator() do
        if ent.GetEnemy and IsValid( ent:GetEnemy() ) and ent:GetEnemy():IsPlayer() and ent:GetEnemy() == ply and ( losonly and ent:Visible( ent:GetEnemy() ) or !losonly )  then
            return true
        end
    end
    return false
end

-- Main function for informing the clients that they are being targetted or not
local cooldown = 0
hook.Add( "Tick", "16thnote_combatdetermine", function()
    if CurTime() < cooldown then return end

    for _, ply in player.Iterator() do
        local istargetted = SXNOTE:PlyBeingTargetted( ply )

        if istargetted and !ply.SXNOTEInCombat then
            ply.SXNOTEInCombat = true
            ply.SXNOTEWaitOff = CurTime() + 4 -- Prevents the combat track from instantly fading out

            net.Start( "16thnote_combatstatus" )
            net.WriteBool( true )
            net.Send( ply )
        elseif !istargetted and ply.SXNOTEInCombat and ( ply.SXNOTEWaitOff and CurTime() > ply.SXNOTEWaitOff or !ply.SXNOTEWaitOff ) then
            ply.SXNOTEInCombat = false

            net.Start( "16thnote_combatstatus" )
            net.WriteBool( false )
            net.Send( ply )
        end
    end

    cooldown = CurTime() + 0.5 -- No need to run this hook every tick.
end )