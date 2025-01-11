SXNOTE = SXNOTE or {}
SXNOTE.CombatTimeDelay = 0
SXNOTE.AmbientTimeDelay = 0
-- Individual volume controls
local ambientvolume = CreateClientConVar( "16thnote_ambientvolume", 1, true, false, "The volume of ambient music", 0, 10 )
local combatvolume = CreateClientConVar( "16thnote_combatvolume", 1, true, false, "The volume of combat music", 0, 10 )
local debugmode = CreateClientConVar( "16thnote_debug", 0, false, false, "Enables Debug mode", 0, 1 )
file.CreateDir( "16thnote" )

-- LOS only option
CreateClientConVar( "16thnote_los", 0, true, true, "If combat music should only play if the enemy has line of sight to the player", 0, 1 )


-- Debug messages
function SXNOTE:Msg( ... )
    if !debugmode:GetBool() then return end
    print( "SXNOTE DEBUG: ", ... )
end

-- Type: Ambient or Combat
-- Plays a particular file under the type of Ambient or Combat
function SXNOTE:PlayTrack( file, type )

    SXNOTE:Msg( "Playing track file ", file, " for ", type )

    -- Fades out the last track that was playing
    if IsValid( self[ type ] ) then
        local fadeoutsnd = self[ type ]
        local id = tostring( fadeoutsnd )

        hook.Add( "Think", "16thnote_fadeout" .. id, function()
            if !IsValid( fadeoutsnd ) or fadeoutsnd:GetVolume() <= 0.05 then
                SXNOTE:Msg( "Removing faded out sound: ", fadeoutsnd )
                fadeoutsnd:Stop()
                fadeoutsnd = nil
                hook.Remove( "Think", "16thnote_fadeout" .. id )
                return
            end
            fadeoutsnd:SetVolume( Lerp( 0.02, fadeoutsnd:GetVolume(), 0 ) )
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

function SXNOTE:HasAmbientTracks( addontrackname )
    if string.EndsWith( addontrackname, "_NOMBAT" ) then
        addontrackname = string.Replace( addontrackname, "_NOMBAT", "" )

        local tracks, _ = file.Find( "sound/nombat/" .. addontrackname .. "/*", "GAME" )

        for _, track in ipairs( tracks ) do
            if string.StartWith( track, "a" ) then return true end
        end
        return false
    end

    if file.Exists( "sound/16thnote/" .. addontrackname .. "/ambient", "GAME" ) then
        local tracks = file.Find( "sound/16thnote/" .. addontrackname .. "/ambient/*", "GAME" )
        return #tracks != 0
    else
        return false
    end
end

function SXNOTE:HasCombatTracks( addontrackname )

    if string.EndsWith( addontrackname, "_NOMBAT" ) then
        addontrackname = string.Replace( addontrackname, "_NOMBAT", "" )

        local tracks, _ = file.Find( "sound/nombat/" .. addontrackname .. "/*", "GAME" )
        for _, track in ipairs( tracks ) do
            if string.StartWith( track, "c" ) then return true end
        end
        return false
    end

    if file.Exists( "sound/16thnote/" .. addontrackname .. "/combat", "GAME" ) then
        local tracks = file.Find( "sound/16thnote/" .. addontrackname .. "/combat/*", "GAME" )
        return #tracks != 0
    else
        return false
    end
end

-- Returns all disabled packs
function SXNOTE:GetDisabled()
    if self.DisabledPacks then return self.DisabledPacks end
    local disabled = file.Read( "16thnote/disabledpacks.json", "DATA" )
    if !disabled then 
        file.Write( "16thnote/disabledpacks.json", util.TableToJSON( {} ) )
        return {}
    end

    self.DisabledPacks = util.JSONToTable( disabled )
    return self.DisabledPacks
end


-- Returns a random track for the given type
-- Type: Ambient or Combat
function SXNOTE:GetRandomTrack( type )
    local _, addontracks = file.Find( "sound/16thnote/*", "GAME" )

    -- NOMBAT --
    local _, nombatpacks = file.Find( "sound/nombat/*", "GAME" )
    for k, v in ipairs( nombatpacks ) do nombatpacks[ k ] = v .. "_NOMBAT" end

    table.Add( addontracks, nombatpacks )
    ------------

    -- Remove Disabled Packs/Packs that do not contain "type" --
    local disabled = self:GetDisabled()

    for k, pack in pairs( addontracks ) do
        if disabled[ pack ] then SXNOTE:Msg( pack, " is disabled! Removing from possible tracks" ) addontracks[ k ] = nil end

        if type == "Ambient" and !self:HasAmbientTracks( pack ) then
            addontracks[ k ] = nil
            SXNOTE:Msg( pack, " does not have Ambient files" )
        elseif type == "Combat" and !self:HasCombatTracks( pack ) then
            addontracks[ k ] = nil
            SXNOTE:Msg( pack, " does not have Combat files" )
        end
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

        local usabletracks = {}
        for _, track in ipairs( tracks ) do
            if type == "Ambient" and string.StartWith( track, "a" ) then
                usabletracks[ #usabletracks + 1 ] = track
            elseif type == "Combat" and string.StartWith( track, "c" ) then
                usabletracks[ #usabletracks + 1 ] = track
            end
        end

        local randomtrack = usabletracks[ math.random( #usabletracks ) ]
        
        return randomtrack and "sound/nombat/" .. randomaddon .. "/" .. randomtrack or nil
    end
    ------------

    local typetracks = file.Find( "sound/16thnote/" .. randomaddon .. "/" .. string.lower( type ) .. "/*", "GAME" )

    local randomtrack = typetracks[ math.random( #typetracks ) ]

    return randomtrack and "sound/16thnote/" .. randomaddon .. "/" .. string.lower( type ) .. "/" .. randomtrack or nil
end

-- Main functions
hook.Add( "Think", "16thnote_musicthink", function()

    -- Play a new track if the current one stopped or doesn't exist --
    if ( IsValid( SXNOTE.Combat ) and SXNOTE.Combat:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Combat ) or ( SXNOTE.Combat:GetTime() / SXNOTE.Combat:GetLength() ) >= 0.95 ) and CurTime() > SXNOTE.CombatTimeDelay then
        local combattrack = SXNOTE:GetRandomTrack( "Combat" )

        if combattrack then
            SXNOTE:Msg( "Starting new Combat Track", combattrack )
            SXNOTE:PlayTrack( combattrack, "Combat" )
            SXNOTE.CombatTimeDelay = CurTime() + 3 -- Prevent track spamming which can severely degrade FPS
        else
            SXNOTE:Msg( "Failed to load sound: Combat", combattrack )
            SXNOTE.CombatTimeDelay = CurTime() + 30
        end
    end

    if ( IsValid( SXNOTE.Ambient ) and SXNOTE.Ambient:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Ambient ) or ( SXNOTE.Ambient:GetTime() / SXNOTE.Ambient:GetLength() ) >= 0.95 ) and CurTime() > SXNOTE.AmbientTimeDelay then
        local ambienttrack = SXNOTE:GetRandomTrack( "Ambient" )

        if ambienttrack then
            SXNOTE:Msg( "Starting new Ambient Track", ambienttrack )
            SXNOTE:PlayTrack( ambienttrack, "Ambient" )
            SXNOTE.AmbientTimeDelay = CurTime() + 3 -- Prevent track spamming which can severely degrade FPS
        else
            SXNOTE:Msg( "Failed to load sound: Ambient", ambienttrack )
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

        panel:CheckBox( "Debug", "16thnote_debug" )
        panel:ControlHelp( "Enables the console debug messages" ):SetColor( Color( 255, 102, 0 ) )

        -- Enable/Disable Code --
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

        function SaveDisabledPacks()
            local lines = disabledlist:GetLines()
            local data = {}

            for _, v in pairs( lines ) do
                data[ v:GetColumnText( 1 ) ] = true
            end

            SXNOTE.DisabledPacks = data

            file.Write( "16thnote/disabledpacks.json", util.TableToJSON( data ) )
        end

        function disabledlist:OnRowSelected( index, line )
            self:RemoveLine( index )
            enabledlist:AddLine( line:GetColumnText( 1 ) )

            SXNOTE.CombatTimeDelay = 0
            SXNOTE.AmbientTimeDelay = 0

            SaveDisabledPacks()
        end

        local disabledpacks = file.Read( "16thnote/disabledpacks.json", "DATA" )
        local packs = SXNOTE:GetPacks()
        if disabledpacks then
            disabledpacks = util.JSONToTable( disabledpacks )

            SXNOTE.DisabledPacks = disabledpacks

            for _, line in ipairs( enabledlist:GetLines() ) do
                if disabledpacks[ line:GetColumnText( 1 ) ] then enabledlist:RemoveLine( line:GetID() ) end
            end

            for _, pack in ipairs( packs ) do
                if disabledpacks[ pack ] then
                    disabledlist:AddLine( pack )
                end
            end

            SaveDisabledPacks()
        end


        -------------------------------------------------------------------

        -- Track Skipping --
        local changeambient = vgui.Create( "DButton", panel )
        panel:AddItem( changeambient )
        changeambient:SetText( "Skip Ambient Track" )
        function changeambient:DoClick()
            local ambienttrack = SXNOTE:GetRandomTrack( "Ambient" )
    
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
            local combattrack = SXNOTE:GetRandomTrack( "Combat" )

            if combattrack then
                SXNOTE:PlayTrack( combattrack, "Combat" )
            else
                SXNOTE.CombatTimeDelay = CurTime() + 30
            end
        end
        -----------------------

	end )
end )