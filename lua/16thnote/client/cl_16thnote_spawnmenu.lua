
-- Add buttons for quickly enabling or disabling all music packs' ambient/combat music
local function AddToggleButtons( panel )
    local ambienttoggle_bool = true
    local toggleambient = vgui.Create( "DButton", panel )
    panel:AddItem( toggleambient )
    toggleambient:SetText( "Toggle Ambient" )
    function toggleambient:DoClick()
        local data = SXNOTE:GetEnabledData()

        surface.PlaySound( "buttons/button16.wav" )

        for packname, v in pairs( data ) do
            v.ambientenabled = !ambienttoggle_bool

            for _, line in ipairs( SXNOTE.EnabledListView:GetLines() ) do
                if line:GetColumnText( 1 ) == packname then
                    if v.ambientenabled then
                        line:SetColumnText( 2, "true" )
                    else
                        line:SetColumnText( 2, "false" )
                    end
                end
            end
        end

        file.Write( "16thnote/enableddata.json", util.TableToJSON( data, true ) )
        ambienttoggle_bool = !ambienttoggle_bool
    end

    local combattoggle_bool = true
    local togglecombat = vgui.Create( "DButton", panel )
    panel:AddItem( togglecombat )
    togglecombat:SetText( "Toggle Combat" )
    function togglecombat:DoClick()
        local data = SXNOTE:GetEnabledData()

        surface.PlaySound( "buttons/button16.wav" )

        for packname, v in pairs( data ) do
            v.combatenabled = !combattoggle_bool

            for _, line in ipairs( SXNOTE.EnabledListView:GetLines() ) do
                if line:GetColumnText( 1 ) == packname then
                    if v.combatenabled then
                        line:SetColumnText( 3, "true" )
                    else
                        line:SetColumnText( 3, "false" )
                    end
                end
            end
        end

        file.Write( "16thnote/enableddata.json", util.TableToJSON( data, true ) )
        combattoggle_bool = !combattoggle_bool
    end

    panel:ControlHelp( "Toggles ambient/combat music for all music packs (For convienence purposes)" ):SetColor( Color( 255, 102, 0 ) )
end

local function PopulateDForm( panel )
    panel:ControlHelp( "Clientside Options = Orange Labels" ):SetColor( Color( 255, 102, 0 ) )
    panel:ControlHelp( "There are no Serverside options" ):SetColor( Color( 0, 119, 255 ) )

    panel:Help( "\n\n-- CURRENT TRACKS --\n" )
    SXNOTE.CurrentAmbientTrackLabel = panel:Help( SXNOTE.AmbientTrackPhrase or "Ambient Track: N/A" )
    SXNOTE.CurrentCombatTrackLabel = panel:Help( SXNOTE.CombatTrackPhrase or "Combat Track: N/A" )
    panel:Help( "\n" )

    local box = panel:ComboBox( "Force Type", "16thnote_forceplaytype" )
    box:AddChoice( "Ambient", "Ambient" )
    box:AddChoice( "None", "none", true )
    box:AddChoice( "Combat", "Combat" )
    panel:ControlHelp( "Forces a certain type of music to always play regardless of combat state" ):SetColor( Color( 255, 102, 0 ) )

    panel:NumSlider( "Ambient Volume", "16thnote_ambientvolume", 0, 10, 2 )
    panel:ControlHelp( "The volume of ambient tracks.\n\n1 is normal volume\n0.5 is half volume\n2 is doubled volume" ):SetColor( Color( 255, 102, 0 ) )

    panel:NumSlider( "Combat Volume", "16thnote_combatvolume", 0, 10, 2 )
    panel:ControlHelp( "The volume of ambient tracks.\n\n1 is normal volume\n0.5 is half volume\n2 is doubled volume" ):SetColor( Color( 255, 102, 0 ) )

    panel:NumSlider( "Combat Threshold", "16thnote_combatthreshold", 1, 10, 0 )
    panel:ControlHelp( "The amount of enemies required for Combat tracks to start playing" ):SetColor( Color( 255, 102, 0 ) )

    panel:CheckBox( "LOS Only", "16thnote_los" )
    panel:ControlHelp( "Whether combat music should only play if the enemy has line of sight to you" ):SetColor( Color( 255, 102, 0 ) )

    panel:CheckBox( "Play in Pairs", "16thnote_playpairs" )
    panel:ControlHelp( "If both the Ambient track and Combat track should attempt to play from the same pack.\n\nNote: This may not always play the same pack for both types if there are either no combat tracks or no ambient tracks available due to a pack not having either one or either type being disabled.\n\nNote 2: Pairing occurs when either Ambient or Combat ends. This means when one type ends, the other will be forced to fade out into the next pack" ):SetColor( Color( 255, 102, 0 ) )

    panel:CheckBox( "Debug", "16thnote_debug" )
    panel:ControlHelp( "Enables the console debug messages" ):SetColor( Color( 255, 102, 0 ) )

    panel:CheckBox( "Always Warn", "16thnote_alwayswarn" )
    panel:ControlHelp( "If 16th Note should always warn you if a music track failed to load" ):SetColor( Color( 255, 102, 0 ) )

    panel:CheckBox( "Enable Track Display", "16thnote_enabletrackdisplay" )
    panel:ControlHelp( "Enables the current track display" ):SetColor( Color( 255, 102, 0 ) )
    
    panel:CheckBox( "Always Render Track Display", "16thnote_permanentdisplay" )
    panel:ControlHelp( "Whether the track display should always be rendered" ):SetColor( Color( 255, 102, 0 ) )
    
    panel:NumSlider( "Track Display X", "16thnote_currenttrackdisplay_x", 0, 1, 3 )
    panel:ControlHelp( "The X (Left right) position of the current track display as a percentage of your screen" ):SetColor( Color( 255, 102, 0 ) )

    panel:NumSlider( "Track Display Y", "16thnote_currenttrackdisplay_y", 0, 1, 3 )
    panel:ControlHelp( "The Y (Up Down) position of the current track display as a percentage of your screen" ):SetColor( Color( 255, 102, 0 ) )

    -- Enable/Disable Code --
    panel:Help( "--- Enable/Disable Music Packs ---" )

    panel:Help( "HAT = Has Ambient Tracks\nHCT = Has Combat Tracks\n\nClick on a pack to enable/disable ambient/combat tracks individually" )

    SXNOTE.SoloWarning = panel:Help( "" )
    SXNOTE.SoloWarning:SetColor( Color( 255, 251, 0 ) )
    local solopack = SXNOTE:GetSoloPack()

    if solopack then
        SXNOTE.SoloWarning:SetText( "NOTE! " .. solopack .. " is attributed solo! Other music packs will not play unless solo is disabled for the pack!" )
    end

    AddToggleButtons( panel )

    SXNOTE.EnabledListView = vgui.Create( "DListView", panel )
    SXNOTE.EnabledListView:SetSize( 0, 200 )
    SXNOTE.EnabledListView:AddColumn( "Music Pack Name", 1 )
    SXNOTE.EnabledListView:AddColumn( "Ambient Enabled", 2 )
    SXNOTE.EnabledListView:AddColumn( "Combat Enabled", 3 )
    SXNOTE.EnabledListView:AddColumn( "HAT", 4 )
    SXNOTE.EnabledListView:AddColumn( "HCT", 5 )
    SXNOTE.EnabledListView:AddColumn( "Solo", 6 )

    panel:AddItem( SXNOTE.EnabledListView )

    local packs = SXNOTE:GetPacks()
    local data = SXNOTE:GetEnabledData()
    for _, pack in ipairs( packs ) do
        local line = SXNOTE.EnabledListView:AddLine( pack )

        line:SetColumnText( 4, tostring( SXNOTE:HasAmbientTracks( pack ) ) )
        line:SetColumnText( 5, tostring( SXNOTE:HasCombatTracks( pack ) ) )
        

        if data[ pack ] then
            line:SetColumnText( 2, tostring( data[ pack ].ambientenabled ) )
            line:SetColumnText( 3, tostring( data[ pack ].combatenabled ) )
            line:SetColumnText( 6, tostring( data[ pack ].solo or "" ) )
        else
            line:SetColumnText( 2, "true" )
            line:SetColumnText( 3, "true" )
            SXNOTE:UpdatePackData( pack, true, true )
        end
    end

    function SXNOTE.EnabledListView:OnRowSelected( index, line )
        SXNOTE:OpenEnabledEditor( line:GetColumnText( 1 ), SXNOTE.EnabledListView )
    end

    -------------------------------------------------------------------

    -- Track Skipping --
    local changeambient = vgui.Create( "DButton", panel )
    panel:AddItem( changeambient )
    changeambient:SetText( "Skip Ambient Track" )
    function changeambient:DoClick()
        SXNOTE:PlayRandomAmbientTrack()
    end

    local changecombat = vgui.Create( "DButton", panel )
    panel:AddItem( changecombat )
    changecombat:SetText( "Skip Combat Track" )
    function changecombat:DoClick()
        SXNOTE:PlayRandomCombatTrack()
    end


    -- Music Picker
    local openpicker = vgui.Create( "DButton", panel )
    panel:AddItem( openpicker )
    openpicker:SetText( "Open Music Picker" )
    function openpicker:DoClick()
        SXNOTE:OpenMusicPicker()
    end

end 

-- SPAWNMENU STUFF --
hook.Add( "AddToolMenuCategories", "16thnote_category", function()
	spawnmenu.AddToolCategory( "Utilities", "16th Note", "16th Note" )
end )

hook.Add( "PopulateToolMenu", "16thnote_spawnmenuoption", function()
	spawnmenu.AddToolMenuOption( "Utilities", "16th Note", "16th_noteoptions", "16th Note", "", "", PopulateDForm )
end )

-- Allows editing of SXNOTE settings when the spawnmenu isn't present
function SXNOTE:OpenSettingsPanel()
    local frame = vgui.Create( "DFrame", GetHUDPanel() )
    frame:SetSize( 400, 500 )
    frame:Center()
    frame:SetTitle( "16th Note Settings" )
    frame:MakePopup()

    local scroll = vgui.Create( "DScrollPanel", frame )
    scroll:Dock( FILL )

    local dform = vgui.Create( "DForm", scroll )
    dform:Dock( FILL )

    PopulateDForm( dform )
end

concommand.Add( "16thnote_opensettings", SXNOTE.OpenSettingsPanel )