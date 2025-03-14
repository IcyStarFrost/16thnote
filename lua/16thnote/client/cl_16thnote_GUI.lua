
-- Opens an editor that can disable ambient or combat music for a given music pack
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

    local solo = vgui.Create( "DCheckBoxLabel", main )
    solo:SetPos( 0, 120 )
    solo:SetText( "Solo (Other packs won't play unless this is disabled. Only one pack can be set as solo!)" )

    -- If data is present for this pack, load it
    if data[ pack ] then
        ambientenabled:SetChecked( data[ pack ].ambientenabled )
        combatenabled:SetChecked( data[ pack ].combatenabled )
        solo:SetChecked( data[ pack ].solo )
    end

    -- Save new configuration for the given pack
    function save:DoClick()
        SXNOTE:UpdatePackData( pack, ambientenabled:GetChecked(), combatenabled:GetChecked(), solo:GetChecked() )

        SXNOTE.CombatTimeDelay = 0
        SXNOTE.AmbientTimeDelay = 0

        local data = SXNOTE:GetEnabledData()
        for _, line in ipairs( list:GetLines() ) do
            local linepack = line:GetColumnText( 1 )

            if linepack == pack then
                line:SetColumnText( 2, tostring( data[ pack ].ambientenabled ) )
                line:SetColumnText( 3, tostring( data[ pack ].combatenabled ) )
            end

            if SXNOTE:GetSoloPack() == linepack then
                line:SetColumnText( 6, tostring( data[ linepack ].solo or "" ) )
            else
                line:SetColumnText( 6, "" )
            end
        end

        surface.PlaySound( "buttons/button14.wav" )
        SXNOTE.enablededitormain:Remove()
    end
    
    function cancel:DoClick() surface.PlaySound( "buttons/combine_button3.wav" ) SXNOTE.enablededitormain:Remove() end
end

-- Opens a panel that allows for manual selection of music
function SXNOTE:OpenMusicPicker()
    if IsValid( self.MusicPickerPanel ) then self.MusicPickerPanel:Remove() end 

    self.MusicPickerPanel = vgui.Create( "DPanel", GetHUDPanel() )
    self.MusicPickerPanel:SetSize( 400, 500 )
    self.MusicPickerPanel:Center()
    self.MusicPickerPanel:MakePopup()

    local close = vgui.Create( "DButton", self.MusicPickerPanel )
    close:Dock( BOTTOM )
    close:SetText( "Exit" )
    function close:DoClick() SXNOTE.MusicPickerPanel:Remove() end

    local title = vgui.Create( "DLabel", self.MusicPickerPanel )
    title:SetText( "16th Note Music Picker" )
    title:Dock( TOP )
    title:SetFont( "Trebuchet24" )

    local listview = vgui.Create( "DListView", self.MusicPickerPanel )
    listview:Dock( FILL )
    listview:AddColumn( "Pack Name", 1 )

    local holderpanel = vgui.Create( "DPanel", self.MusicPickerPanel )
    holderpanel:SetSize( 1, 200 )
    holderpanel:Dock( BOTTOM )

    local hascombat = vgui.Create( "DLabel", self.MusicPickerPanel )
    hascombat:SetText( "Has Combat Tracks: N/A" )
    hascombat:Dock( BOTTOM )
    hascombat:SetFont( "Trebuchet16" )
    hascombat:SetColor( Color( 255, 79, 79) )

    local hasambient = vgui.Create( "DLabel", self.MusicPickerPanel )
    hasambient:SetText( "Has Ambient Tracks: N/A" )
    hasambient:Dock( BOTTOM )
    hasambient:SetFont( "Trebuchet16" )
    hasambient:SetColor( Color( 92, 255, 92) )

    local selectedtitle = vgui.Create( "DLabel", self.MusicPickerPanel )
    selectedtitle:SetText( "Selected Pack: None" )
    selectedtitle:Dock( BOTTOM )
    selectedtitle:SetFont( "Trebuchet24" )

    local ambientlist = vgui.Create( "DListView", holderpanel )
    ambientlist:SetSize( 200, 0 )
    ambientlist:Dock( LEFT )
    ambientlist:AddColumn( "Ambient Track Name", 1 )
    ambientlist.IsAmbient = true

    local combatlist = vgui.Create( "DListView", holderpanel )
    combatlist:SetSize( 200, 0 )
    combatlist:Dock( RIGHT )
    combatlist:AddColumn( "Combat Track Name", 1 )
    combatlist.IsCombat = true

    local packs = self:GetPacks()
    local selectedpackname = ""
    local cooldown = 0

    for _, packname in ipairs( packs ) do
        listview:AddLine( packname )
    end

    -- Play a track the client selected from either ambientlist or combatlist
    local function SelectTrack( self, packname, trackname )
        if SysTime() < cooldown then return end
        cooldown = SysTime() + 0.1

        -- The automatic track playing sometimes overrules the music picker. This is to prevent that from happening
        SXNOTE.CombatTimeDelay = CurTime() + 1
        SXNOTE.AmbientTimeDelay = CurTime() + 1

        if string.EndsWith( packname, "_NOMBAT" ) then
            local fullname = "sound/nombat/" .. string.Replace( packname, "_NOMBAT", "" ) .. "/" .. trackname
            
            chat.AddText( "Playing " .. trackname .. " for " .. ( self.IsAmbient and "Ambient" or self.IsCombat and "Combat" ) )
            surface.PlaySound( "buttons/button15.wav" )
            SXNOTE:PlayTrack( fullname, self.IsAmbient and "Ambient" or self.IsCombat and "Combat" )
            return
        end

        local full16thnotename = "sound/16thnote/" .. packname .. "/" .. ( self.IsAmbient and "ambient" or self.IsCombat and "combat" ) .. "/" .. trackname

        surface.PlaySound( "buttons/button15.wav" )
        chat.AddText( "Playing " .. trackname .. " for " .. ( self.IsAmbient and "Ambient" or self.IsCombat and "Combat" ) )
        SXNOTE:PlayTrack( full16thnotename, self.IsAmbient and "Ambient" or self.IsCombat and "Combat" )
    end

    function ambientlist:OnRowSelected( id, line )
        SelectTrack( self, selectedpackname, line:GetColumnText( 1 ) )
    end

    function combatlist:OnRowSelected( id, line )
        SelectTrack( self, selectedpackname, line:GetColumnText( 1 ) )
    end

    function listview:OnRowSelected( id, line )
        ambientlist:Clear()
        combatlist:Clear()

        local packname = line:GetColumnText( 1 ) 
        selectedpackname = packname
        
        hasambient:SetText( "Has Ambient Tracks: " .. tostring( SXNOTE:HasAmbientTracks( packname ) ) )
        hascombat:SetText( "Has Combat Tracks: " .. tostring( SXNOTE:HasCombatTracks( packname ) ) )

        selectedtitle:SetText( "Selected Pack: " .. packname )

        -- Populates the ambient/combat lists for nombat
        if string.EndsWith( packname, "_NOMBAT" ) then
            packname = string.Replace( packname, "_NOMBAT", "" )
    
            local tracks, _ = file.Find( "sound/nombat/" .. packname .. "/*", "GAME" )
    
            for _, track in ipairs( tracks ) do
                if string.StartWith( track, "a" ) then
                    ambientlist:AddLine( track )
                elseif string.StartWith( track, "c" ) then
                    combatlist:AddLine( track )
                end
            end
            return false
        end
    
        -- Populates the ambient/combat lists for base 16th note
        if file.Exists( "sound/16thnote/" .. packname .. "/ambient", "GAME" ) then
            local tracks = file.Find( "sound/16thnote/" .. packname .. "/ambient/*", "GAME" )

            for k, track in ipairs( tracks ) do
                ambientlist:AddLine( track )
            end
        end

        if file.Exists( "sound/16thnote/" .. packname .. "/combat", "GAME" ) then
            local tracks = file.Find( "sound/16thnote/" .. packname .. "/combat/*", "GAME" )

            for k, track in ipairs( tracks ) do
                combatlist:AddLine( track )
            end
        end
    end

end
