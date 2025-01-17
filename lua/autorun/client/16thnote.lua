SXNOTE = SXNOTE or {}
SXNOTE.CombatTimeDelay = 0
SXNOTE.AmbientTimeDelay = 0
-- Individual volume controls
local ambientvolume = CreateClientConVar( "16thnote_ambientvolume", 1, true, false, "The volume of ambient music", 0, 10 )
local combatvolume = CreateClientConVar( "16thnote_combatvolume", 1, true, false, "The volume of combat music", 0, 10 )
local debugmode = CreateClientConVar( "16thnote_debug", 0, false, false, "Enables Debug mode", 0, 1 )
file.CreateDir( "16thnote" )

-- LOS only option
CreateClientConVar( "16thnote_los", 1, true, true, "If combat music should only play if the enemy has line of sight to the player", 0, 1 )


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

-- Returns data about enabled/disabled ambient/combat music packs
function SXNOTE:GetEnabledData()
    local data = file.Read( "16thnote/enableddata.json", "DATA" )
    if !data then
        file.Write( "16thnote/enableddata.json", util.TableToJSON( {} ) )
        return {}
    end

    return util.JSONToTable( data )
end

-- Automatically adds packs that are not in the enabled database and deletes packs that are no longer installed from the database
function SXNOTE:PopulateEnabledData()
    local data = self:GetEnabledData()
    local packs = self:GetPacks()

    for _, pack in ipairs( packs ) do
        if !data[ pack ] then
            self:UpdatePackData( pack, true, true )
        end
    end

    local inverted = table.Flip( packs )
    for pack, data in pairs( data ) do
        if !inverted[ pack ] then
            self:Msg( "Prompting " .. pack .. "'s deletion due to it not being installed anymore" )
            self:DeletePackData( pack )
        end
    end
end

-- Returns whether ambient music is enabled for this pack or not
function SXNOTE:IsAmbientEnabled( pack )
    local data = self:GetEnabledData()
    local packdata = data[ pack ]

    if packdata then
        return packdata.ambientenabled
    else
        self:Msg( "WARNING! Attempted to determine if " .. pack .. " was able to play ambient tracks without any enabled data!")
        return false 
    end
end

-- Returns whether combat music is enabled for this pack or not
function SXNOTE:IsCombatEnabled( pack )
    local data = self:GetEnabledData()
    local packdata = data[ pack ]

    if packdata then
        return packdata.combatenabled
    else
        self:Msg( "WARNING! Attempted to determine if " .. pack .. " was able to play combat tracks without any enabled data!")
        return false 
    end
end

-- Deletes a pack's enabled data
function SXNOTE:DeletePackData( packname )
    local data = self:GetEnabledData()
    data[ packname ] = nil
    self:Msg( "Deleting " .. packname .. "'s enabled data" )

    file.Write( "16thnote/enableddata.json", util.TableToJSON( data, true ) )
end

-- Updates a given music pack's enabled data
function SXNOTE:UpdatePackData( packname, ambientenabled, combatenabled )
    local data = self:GetEnabledData()

    data[ packname ] = { ambientenabled = ambientenabled, combatenabled = combatenabled,}

    self:Msg( "Updating " .. packname .. "'s enabled data" )

    file.Write( "16thnote/enableddata.json", util.TableToJSON( data, true ) )
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
    for k, pack in pairs( addontracks ) do
        if type == "Ambient" and !self:IsAmbientEnabled( pack ) then self:Msg( pack, " ambient music is disabled! Removing from possible tracks" ) addontracks[ k ] = nil continue end
        if type == "Combat" and !self:IsCombatEnabled( pack ) then self:Msg( pack, " combat music is disabled! Removing from possible tracks" ) addontracks[ k ] = nil continue end

        if type == "Ambient" and !self:HasAmbientTracks( pack ) then
            addontracks[ k ] = nil
            self:Msg( pack, " does not have Ambient files" )
        elseif type == "Combat" and !self:HasCombatTracks( pack ) then
            addontracks[ k ] = nil
            self:Msg( pack, " does not have Combat files" )
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


function SXNOTE:OpenEnabledEditor( pack, list )
    if IsValid( self.enablededitormain ) then self.enablededitormain:Remove() end

    local data = SXNOTE:GetEnabledData()

    self.enablededitormain = vgui.Create( "DPanel", GetHUDPanel() )
    self.enablededitormain:SetSize( ScrW(), ScrH() )
    self.enablededitormain:SetDrawOnTop( true )
    self.enablededitormain:MakePopup()

    local main = vgui.Create( "DPanel", self.enablededitormain )
    main:SetSize( 400, 200 )
    main:Center()

    function self.enablededitormain:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 200 )
        surface.DrawRect( 0, 0, w, h )
    end

    function main:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 200 )
        surface.DrawRect( 0, 0, w, h )
    end

    local cancel = vgui.Create( "DButton", main )
    cancel:SetSize( 50, 30 )
    cancel:SetPos( 400 - 50, 200 - 30 )
    cancel:SetText( "CANCEL" )

    local save = vgui.Create( "DButton", main )
    save:SetSize( 100, 30 )
    save:SetPos( 300 - 50, 200 - 30 )
    save:SetText( "SAVE" )

    function save:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    function cancel:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    local title = vgui.Create( "DLabel", main )
    title:SetText( "16th Note Music Type Enabler")
    title:Dock( TOP )
    title:SetFont( "Trebuchet24" )

    local packname = vgui.Create( "DLabel", main )
    packname:SetText( "Editing " .. pack .. " data.." )
    packname:Dock( TOP )
    packname:SetFont( "CreditsText" )


    local ambientenabled = vgui.Create( "DCheckBoxLabel", main )
    ambientenabled:SetPos( 0, 50 )
    ambientenabled:SetText( "Ambient Music Enabled" )

    local combatenabled = vgui.Create( "DCheckBoxLabel", main )
    combatenabled:SetPos( 0, 80 )
    combatenabled:SetText( "Combat Music Enabled" )

    if data[ pack ] then
        ambientenabled:SetChecked( data[ pack ].ambientenabled )
        combatenabled:SetChecked( data[ pack ].combatenabled )
    end

    function save:DoClick()
        SXNOTE:UpdatePackData( pack, ambientenabled:GetChecked(), combatenabled:GetChecked() )

        SXNOTE.CombatTimeDelay = 0
        SXNOTE.AmbientTimeDelay = 0

        local data = SXNOTE:GetEnabledData()
        for _, line in ipairs( list:GetLines() ) do
            local linepack = line:GetColumnText( 1 )

            if linepack == pack then
                line:SetColumnText( 2, tostring( data[ pack ].ambientenabled ) )
                line:SetColumnText( 3, tostring( data[ pack ].combatenabled ) )
            end
        end

        surface.PlaySound( "buttons/button14.wav" )
        SXNOTE.enablededitormain:Remove()
    end
    
    function cancel:DoClick() surface.PlaySound( "buttons/combine_button3.wav" ) SXNOTE.enablededitormain:Remove() end
end

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

        panel:Help( "HAT = Has Ambient Tracks\nHCT = Has Combat Tracks\n\nClick on a pack to enable/disable ambient/combat tracks individually" )
        SXNOTE.EnabledListView = vgui.Create( "DListView", panel )
        SXNOTE.EnabledListView:SetSize( 0, 200 )
        SXNOTE.EnabledListView:AddColumn( "Music Pack Name", 1 )
        SXNOTE.EnabledListView:AddColumn( "Ambient Enabled", 2 )
        SXNOTE.EnabledListView:AddColumn( "Combat Enabled", 3 )
        SXNOTE.EnabledListView:AddColumn( "HAT", 4 )
        SXNOTE.EnabledListView:AddColumn( "HCT", 5 )
        

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



SXNOTE:PopulateEnabledData()