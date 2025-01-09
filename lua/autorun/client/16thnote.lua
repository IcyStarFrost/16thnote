SXNOTE = SXNOTE or {}
SXNOTE.FadeoutIncrement = 0
SXNOTE.CombatTimeDelay = 0
SXNOTE.AmbientTimeDelay = 0
-- Individual volume controls
local ambientvolume = CreateClientConVar( "16thnote_ambientvolume", 1, true, false, "The volume of ambient music", 0, 10 )
local combatvolume = CreateClientConVar( "16thnote_combatvolume", 1, true, false, "The volume of combat music", 0, 10 )
file.CreateDir( "16thnote" )

-- LOS only option
CreateClientConVar( "16thnote_los", 0, true, true, "If combat music should only play if the enemy has line of sight to the player", 0, 1 )

-- Type: Ambient or Combat
-- Plays a particular file under the type of Ambient or Combat
function SXNOTE:PlayTrack( file, type )

    -- Fades out the last track that was playing
    if IsValid( self[ type ] ) then
        local fadeoutsnd = self[ type ]
        self.FadeoutIncrement = self.FadeoutIncrement + 1
        local incre = self.FadeoutIncrement

        hook.Add( "Think", "16thnote_fadeout" .. incre, function()
            if !IsValid( fadeoutsnd ) or fadeoutsnd:GetVolume() <= 0 then
                fadeoutsnd:Stop()
                fadeoutsnd = nil
                hook.Remove( "Think", "16thnote_fadeout" .. incre )
                return
            end
            fadeoutsnd:SetVolume( Lerp( 0.02, fadeoutsnd:GetVolume(), -0.5 ) )
        end )
    end

    sound.PlayFile( file, "noplay", function( snd )
        if !IsValid( snd ) then return end -- :troll:
        self[ type ] = snd
        snd:SetVolume( 0 )
        snd:Play()
    end )
end

-- Returns all music packs 16th Note can see
-- Nombat packs have _NOMBAT appended at the end of their string
function SXNOTE:GetPacks()
    local _, addontracks = file.Find( "sound/16thnote/*", "GAME" )
    local _, nombatpacks = file.Find( "sound/nombat/*", "GAME" )
    for k, v in ipairs( nombatpacks ) do nombatpacks[ k ] = v .. "_NOMBAT" end

    table.Add( addontracks, nombatpacks )

    return addontracks
end

-- Returns all disabled packs
function SXNOTE:GetDisabled()
    if self.DisabledPacks then return self.DisabledPacks end
    local disabled = file.Read( "16thnote/disabledpacks.json", "DATA" )
    if !disabled then return end

    self.DisabledPacks = util.JSONToTable( disabled )
    return self.DisabledPacks
end

-- Retrieves a random track from a random addon module or nombat pack
function SXNOTE:GetRandomTracks()
    local _, addontracks = file.Find( "sound/16thnote/*", "GAME" )

    -- NOMBAT --
    local _, nombatpacks = file.Find( "sound/nombat/*", "GAME" )
    for k, v in ipairs( nombatpacks ) do nombatpacks[ k ] = v .. "_NOMBAT" end

    table.Add( addontracks, nombatpacks )
    ------------


    -- Remove Disabled Packs --
    local disabled = self:GetDisabled()

    for k, pack in pairs( addontracks ) do
        if disabled[ pack ] then addontracks[ k ] = nil end
    end
    addontracks = table.ClearKeys( addontracks )
    --------------------------------------

    local randomaddon = addontracks[ math.random( #addontracks ) ] -- Picks a random addon module for 16thnote

    if !randomaddon then return end

    -- NOMBAT --
    -- Only executes if a nombat pack was chosen from the randomaddon variable
    if string.find( randomaddon, "_NOMBAT" ) then
        randomaddon = string.Replace( randomaddon, "_NOMBAT", "" )

        local tracks, _ = file.Find( "sound/nombat/" .. randomaddon .. "/*", "GAME" )

        local ambient = {}
        local combat = {}
        for _, track in ipairs( tracks ) do
            if string.StartWith( track, "a" ) then
                ambient[ #ambient + 1 ] = track 
            else
                combat[ #combat + 1 ] = track 
            end
        end

        local ambienttrack = ambient[ math.random( #ambient ) ]
        local combattrack = combat[ math.random( #combat ) ]
        
        return ambienttrack and "sound/nombat/" .. randomaddon .. "/" .. ambienttrack or nil, combattrack and "sound/nombat/" .. randomaddon .. "/" .. combattrack or nil
    end
    ------------

    local ambienttracks = file.Find( "sound/16thnote/" .. randomaddon .. "/ambient/*", "GAME" )
    local combattracks = file.Find( "sound/16thnote/" .. randomaddon .. "/combat/*", "GAME" )

    local ambienttrack = ambienttracks[ math.random( #ambienttracks ) ]
    local combattrack = combattracks[ math.random( #combattracks ) ]


    return ambienttrack and "sound/16thnote/" .. randomaddon .. "/ambient/" .. ambienttrack or nil, combattrack and "sound/16thnote/" .. randomaddon .. "/combat/" .. combattrack or nil
end


-- Main functions
hook.Add( "Think", "16thnote_musicthink", function()

    -- Play a new track if the current one stopped or doesn't exist --
    if ( IsValid( SXNOTE.Combat ) and SXNOTE.Combat:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Combat ) or ( SXNOTE.Combat:GetTime() / SXNOTE.Combat:GetLength() ) >= 0.95 ) and CurTime() > SXNOTE.CombatTimeDelay then
        local _, combattrack = SXNOTE:GetRandomTracks()

        if combattrack then
            SXNOTE:PlayTrack( combattrack, "Combat" )
        else
            SXNOTE.CombatTimeDelay = CurTime() + 30
        end
    end

    if ( IsValid( SXNOTE.Ambient ) and SXNOTE.Ambient:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Ambient ) or ( SXNOTE.Ambient:GetTime() / SXNOTE.Ambient:GetLength() ) >= 0.95 ) and CurTime() > SXNOTE.AmbientTimeDelay then
        local ambienttrack = SXNOTE:GetRandomTracks()

        if ambienttrack then
            SXNOTE:PlayTrack( ambienttrack, "Ambient" )
        else
            SXNOTE.AmbientTimeDelay = CurTime() + 30
        end
    end
    -------------------------------------------------------------------

    -- Volume Control --
    if IsValid( SXNOTE.Combat ) and SXNOTE.InCombat then
        SXNOTE.Combat:SetVolume( Lerp( 0.02, SXNOTE.Combat:GetVolume(), combatvolume:GetFloat() ) )

        if IsValid( SXNOTE.Ambient ) then
            SXNOTE.Ambient:SetVolume( Lerp( 0.02, SXNOTE.Ambient:GetVolume(), 0 ) )
        end
    elseif IsValid( SXNOTE.Combat ) and !SXNOTE.InCombat then
        SXNOTE.Combat:SetVolume( Lerp( 0.02, SXNOTE.Combat:GetVolume(), 0 ) )
    end
    
    if ( !IsValid( SXNOTE.Combat ) or !SXNOTE.InCombat ) and IsValid( SXNOTE.Ambient ) then
        SXNOTE.Ambient:SetVolume( Lerp( 0.02, SXNOTE.Ambient:GetVolume(), ambientvolume:GetFloat() ) )
    end
    ---------------------

end )

net.Receive( "16thnote_combatstatus", function()
    SXNOTE.InCombat = net.ReadBool()
end )




-- SPAWNMENU STUFF --
hook.Add( "AddToolMenuCategories", "16thnote_category", function()
	spawnmenu.AddToolCategory( "Utilities", "16th Note", "16th Note" )
end )

hook.Add( "PopulateToolMenu", "16thnote_spawnmenuoption", function()
	spawnmenu.AddToolMenuOption( "Utilities", "16th Note", "16th_noteoptions", "16th Note", "", "", function( panel )
        panel:ControlHelp( "Clientside Options = Orange Labels" ):SetColor( Color( 255, 102, 0 ) )
        panel:ControlHelp( "There are no Serverside options" ):SetColor( Color( 0, 119, 255 ) )
        
        panel:NumSlider( "Ambient Volume", "16thnote_ambientvolume", 0, 10, 2 )
        panel:ControlHelp( "The volume of ambient tracks.\n\n1 is normal volume\n0.5 is half volume\n2 is doubled volume" ):SetColor( Color( 255, 102, 0 ) )

        panel:NumSlider( "Combat Volume", "16thnote_combatvolume", 0, 10, 2 )
        panel:ControlHelp( "The volume of ambient tracks.\n\n1 is normal volume\n0.5 is half volume\n2 is doubled volume" ):SetColor( Color( 255, 102, 0 ) )

        panel:CheckBox( "LOS Only", "16thnote_los" )
        panel:ControlHelp( "Whether combat music should only play if the enemy has line of sight to you" ):SetColor( Color( 255, 102, 0 ) )

        panel:Help( "--- Enable/Disable Music Packs ---" )

        local disabledlist
        local SaveDisabledPacks
        local enabledlist = vgui.Create( "DListView", panel )
        enabledlist:SetSize( 0, 200 )
        enabledlist:AddColumn( "Enabled Music Packs", 1 )

        panel:AddItem( enabledlist )

        local packs = SXNOTE:GetPacks()

        for _, pack in ipairs( packs ) do
            enabledlist:AddLine( pack )
        end

        function enabledlist:OnRowSelected( index, line )
            self:RemoveLine( index )
            disabledlist:AddLine( line:GetColumnText( 1 ) )

            SXNOTE.CombatTimeDelay = 0
            SXNOTE.AmbientTimeDelay = 0

            SaveDisabledPacks()
        end

        disabledlist = vgui.Create( "DListView", panel )
        disabledlist:SetSize( 0, 200 )
        disabledlist:AddColumn( "Disabled Music Packs", 1 )
        
        panel:AddItem( disabledlist )

        function disabledlist:OnRowSelected( index, line )
            self:RemoveLine( index )
            enabledlist:AddLine( line:GetColumnText( 1 ) )

            SXNOTE.CombatTimeDelay = 0
            SXNOTE.AmbientTimeDelay = 0

            SaveDisabledPacks()
        end

        local disabledpacks = file.Read( "16thnote/disabledpacks.json", "DATA" )
        if disabledpacks then
            disabledpacks = util.JSONToTable( disabledpacks )

            SXNOTE.DisabledPacks = disabledpacks

            for _, line in ipairs( enabledlist:GetLines() ) do
                if disabledpacks[ line:GetColumnText( 1 ) ] then enabledlist:RemoveLine( line:GetID() ) end
            end

            for k, _ in pairs( disabledpacks ) do
                disabledlist:AddLine( k )
            end
        end


        function SaveDisabledPacks()
            local lines = disabledlist:GetLines()
            local data = {}

            for _, v in pairs( lines ) do
                data[ v:GetColumnText( 1 ) ] = true
            end

            SXNOTE.DisabledPacks = data

            file.Write( "16thnote/disabledpacks.json", util.TableToJSON( data ) )
        end

        -- Track Skipping --
        local changeambient = vgui.Create( "DButton", panel )
        panel:AddItem( changeambient )
        changeambient:SetText( "Skip Ambient Track" )
        function changeambient:DoClick()
            local ambienttrack = SXNOTE:GetRandomTracks()
    
            if ambienttrack then
                SXNOTE:PlayTrack( ambienttrack, "Ambient" )
            else
                SXNOTE.AmbientTimeDelay = CurTime() + 30
            end
        end

        local changecombat = vgui.Create( "DButton", panel )
        panel:AddItem( changecombat )
        changecombat:SetText( "Skip Combat Track" )
        function changecombat:DoClick()
            local _, combattrack = SXNOTE:GetRandomTracks()

            if combattrack then
                SXNOTE:PlayTrack( combattrack, "Combat" )
            else
                SXNOTE.CombatTimeDelay = CurTime() + 30
            end
        end
        -----------------------

	end )
end )