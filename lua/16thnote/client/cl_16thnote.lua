SXNOTE.CombatTimeDelay = 0
SXNOTE.AmbientTimeDelay = 0
SXNOTE.DisplayTimeConstant = 5
SXNOTE.TrackDisplayTime = SysTime() + 5
SXNOTE.CurrentAlpha = 255


-- Main functions
hook.Add( "Think", "16thnote_musicthink", function()

    -- Play a new track if the current one stopped or doesn't exist --
    if ( IsValid( SXNOTE.Combat ) and SXNOTE.Combat:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Combat ) or ( SXNOTE.Combat:GetTime() / SXNOTE.Combat:GetLength() ) >= 0.95 ) and CurTime() > SXNOTE.CombatTimeDelay then
        SXNOTE:PlayRandomCombatTrack()
    end

    if ( IsValid( SXNOTE.Ambient ) and SXNOTE.Ambient:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Ambient ) or ( SXNOTE.Ambient:GetTime() / SXNOTE.Ambient:GetLength() ) >= 0.95 ) and CurTime() > SXNOTE.AmbientTimeDelay then
        SXNOTE:PlayRandomAmbientTrack()
    end
    -------------------------------------------------------------------

    local lerprate = math.Clamp( 0.03 / ( ( 1 / FrameTime() ) / 75 ) , 0.02, 0.3 )
    -- Volume Control --
    if IsValid( SXNOTE.Combat ) and SXNOTE.InCombat then
        SXNOTE.Combat:SetVolume( Lerp( lerprate, SXNOTE.Combat:GetVolume(), SXNOTE:GetCvar( "16thnote_combatvolume" ):GetFloat() ) )

        if IsValid( SXNOTE.Ambient ) then
            SXNOTE.Ambient:SetVolume( Lerp( lerprate, SXNOTE.Ambient:GetVolume(), 0 ) )
        end
    elseif IsValid( SXNOTE.Combat ) and !SXNOTE.InCombat then
        SXNOTE.Combat:SetVolume( Lerp( lerprate, SXNOTE.Combat:GetVolume(), 0 ) )
    end
    
    if ( !IsValid( SXNOTE.Combat ) or !SXNOTE.InCombat ) and IsValid( SXNOTE.Ambient ) then
        SXNOTE.Ambient:SetVolume( Lerp( lerprate, SXNOTE.Ambient:GetVolume(), SXNOTE:GetCvar( "16thnote_ambientvolume" ):GetFloat() ) )
    end
    ---------------------

end )

-- The server informs us whether we are being targetted or not
net.Receive( "16thnote_combatstatus", function()
    SXNOTE.InCombat = net.ReadBool()

    SXNOTE.TrackDisplayTime = SysTime() + SXNOTE.DisplayTimeConstant
end )


----------------------------------- CURRENT TRACK DISPLAY -----------------------------------
--local scale = ScreenScaleH( 0.44 )
local note = Material( "16thnote/note.png", "smooth" )
local statecol = Color( 255, 102, 0 )
local white = Color( 255, 255, 255 )
hook.Add( "HUDPaint", "16thnote_hud", function()
    if !SXNOTE:GetCvar( "16thnote_enabletrackdisplay" ):GetBool() then return end

    local state = SXNOTE.InCombat and "Combat" or "Ambient"
    local trackname = SXNOTE.InCombat and SXNOTE.CurrentCombatTrack or SXNOTE.CurrentAmbientTrack or ""
    local packname = SXNOTE.InCombat and SXNOTE.CurrentCombatPack or SXNOTE.CurrentAmbientPack or ""

    surface.SetFont( "GModToolHelp" )
    local sizex = surface.GetTextSize( state )

    local phrase = " track from " .. packname .. ": " .. trackname

    -- Origin position of the display
    local x = ScrW() * SXNOTE:GetCvar( "16thnote_currenttrackdisplay_x" ):GetFloat()
    local y = ScrH() * SXNOTE:GetCvar( "16thnote_currenttrackdisplay_y" ):GetFloat()

    local textx = 0
    local texty = 0
    local secondaryx = 0

    local align = TEXT_ALIGN_LEFT

    -- Scripted text/logo positioning
    if x < ScrW() * 0.3 then -- If Left side
        
        textx = 30
        texty = 10
    elseif x > ScrW() * 0.7 then -- If right side
        textx = -60
        texty = 10
        align = TEXT_ALIGN_RIGHT

        local z = surface.GetTextSize( phrase )
        local z2 = surface.GetTextSize( state )
        secondaryx = -z + z2
    elseif x > ScrW() * 0.3 and x < ScrW() * 0.7 then -- If in the center of the screen
        textx = 30
        texty = -20
        align = TEXT_ALIGN_CENTER
        sizex = 0

        surface.SetFont( "GModToolHelp" )
        local z = surface.GetTextSize( phrase )
        local z2 = surface.GetTextSize( state )
        secondaryx = -z * 0.5 - z2 * 0.5
    end

    if x > ScrW() * 0.3 and x < ScrW() * 0.7 and y > ScrH() * 0.5 then -- If in the center of the screen. Moves the phrase text above or below the logo
        texty = texty + 60
    end

    -- Fade in and out
    if SysTime() < SXNOTE.TrackDisplayTime or SXNOTE:GetCvar( "16thnote_permanentdisplay" ):GetBool() then
        SXNOTE.CurrentAlpha = Lerp( FrameTime() * 2, SXNOTE.CurrentAlpha, 255 )
        white.a = SXNOTE.CurrentAlpha
        statecol.a = SXNOTE.CurrentAlpha
    else
        SXNOTE.CurrentAlpha = Lerp( FrameTime() * 2, SXNOTE.CurrentAlpha, 0 )
        white.a = SXNOTE.CurrentAlpha
        statecol.a = SXNOTE.CurrentAlpha
    end

    surface.SetDrawColor( 255, 255, 255, SXNOTE.CurrentAlpha )
    surface.SetMaterial( note )
    surface.DrawTexturedRect( x, y, 32, 32 )

    draw.DrawText( phrase, "GModToolHelp", x + textx + sizex, y + texty, white, align )
    draw.DrawText( state, "GModToolHelp", x + textx + secondaryx, y + texty, statecol, align ) -- Highlighting the state
end )
-----------------------------------


SXNOTE:PopulateEnabledData()