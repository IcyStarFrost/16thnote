SXNOTE.Warnfailedsound = true

-- Debug messages
function SXNOTE:Msg( ... )
    if !self:GetCvar( "16thnote_debug" ):GetBool() then return end
    print( "SXNOTE DEBUG: ", ... )
end

-- Type: Ambient or Combat
-- Plays a particular file under the type of Ambient or Combat
function SXNOTE:PlayTrack( file, type, callback )

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

    sound.PlayFile( file, "noplay", function( snd, code, err )
        if !IsValid( snd ) then 
            print( "SXNOTE WARNING: " .. file .. " failed to load due to error code " .. code .. " " .. err ) 
            print( "SXNOTE: Most errors occur due to filenames. Ensure file names are based on letters and numbers only. Make sure there are no double spaces and make sure there are no \".\" (periods) in the filename other than the file extension." )

            if SXNOTE.Warnfailedsound and !SXNOTE:GetCvar( "16thnote_alwayswarn" ):GetBool() then
                chat.AddText( "A 16th Note music track failed to load! " .. file .. " Check console for details. This message will not repeat for the rest of the session unless you enable Always Warn." )
                SXNOTE.Warnfailedsound = false
            elseif SXNOTE:GetCvar( "16thnote_alwayswarn" ):GetBool() then
                chat.AddText( "A 16th Note music track failed to load! " .. file .. " Check console for details" )
            end
            return 
        end -- :troll:

        local filename = snd:GetFileName()
        local tracksplit = string.Explode( "/", filename )
        local trackname = string.StripExtension( tracksplit[ #tracksplit ] )
        local packname = tracksplit[ 3 ]

        
        if type == "Combat" and SXNOTE.InCombat then
            SXNOTE.TrackDisplayTime = SysTime() + SXNOTE.DisplayTimeConstant
        end

        if type == "Ambient" and !SXNOTE.InCombat then
            SXNOTE.TrackDisplayTime = SysTime() + SXNOTE.DisplayTimeConstant
        end

        if type == "Ambient" then 
            SXNOTE.CurrentAmbientTrack = trackname
            SXNOTE.CurrentAmbientPack = packname 
            SXNOTE.AmbientTrackPhrase = "Ambient Track: \"" .. trackname .. "\" from " .. packname  
        end

        if type == "Combat" then 
            SXNOTE.CurrentCombatTrack = trackname
            SXNOTE.CurrentCombatPack = packname 
            SXNOTE.CombatTrackPhrase = "Combat Track: \"" .. trackname .. "\" from " .. packname  
        end

        if IsValid( SXNOTE.CurrentAmbientTrackLabel ) and type == "Ambient" then
            SXNOTE.CurrentAmbientTrackLabel:SetText( "Ambient Track: \"" .. trackname .. "\" from " .. packname )
        end

        if IsValid( SXNOTE.CurrentCombatTrackLabel ) and type == "Combat" then
            SXNOTE.CurrentCombatTrackLabel:SetText( "Combat Track: \"" .. trackname .. "\" from " .. packname )
        end

        self[ type ] = snd
        snd:SetVolume( 0 )
        snd:Play()

        if callback then callback( snd ) end
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

function SXNOTE:GetAmbientTracks( packname )
    if file.Exists( "sound/16thnote/" .. packname .. "/ambient", "GAME" ) then
        local tracks = file.Find( "sound/16thnote/" .. packname .. "/ambient/*", "GAME" )
        local names = {}
        for _, v in ipairs( tracks ) do
            names[ #names + 1 ] = "sound/16thnote/" .. packname .. "/ambient/" .. v
        end
        return names
    end
end

function SXNOTE:GetCombatTracks( packname )
    if file.Exists( "sound/16thnote/" .. packname .. "/combat", "GAME" ) then
        local tracks = file.Find( "sound/16thnote/" .. packname .. "/combat/*", "GAME" )
        local names = {}
        for _, v in ipairs( tracks ) do
            names[ #names + 1 ] = "sound/16thnote/" .. packname .. "/combat/" .. v
        end
        return names
    end
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

-- Checks whether the 16thnote pack supports lyrics
function SXNOTE:PackSupportsLyrics( packname )
    local tracks = self:GetAmbientTracks( packname )
    table.Add( tracks, self:GetCombatTracks( packname ) )

    for _, v in ipairs( tracks ) do
        if self.LyricData[ v ] then return true end
    end
    return false
end

-- Returns the current sound channel being played
function SXNOTE:GetCurrentChannel()
    return self:IsInCombat() and SXNOTE.Combat or !self:IsInCombat() and SXNOTE.Ambient
end

function SXNOTE:GetSoloPack()
    local data = self:GetEnabledData()
    for pack, packdata in pairs( data ) do
        if packdata.solo then return pack end
    end
end

-- Updates a given music pack's enabled data
function SXNOTE:UpdatePackData( packname, ambientenabled, combatenabled, solo )
    local data = self:GetEnabledData()

    data[ packname ] = { ambientenabled = ambientenabled, combatenabled = combatenabled, solo = solo }

    if solo then
        self.SoloWarning:SetText( "NOTE! " .. packname .. " is attributed solo! Other music packs will not play unless solo is disabled for the pack!" )
        for datapackname, packdata in pairs( data ) do
            if packname != datapackname and packdata.solo then
                data[ datapackname ].solo = false
            end 
        end
    end

    self:Msg( "Updating " .. packname .. "'s enabled data" )

    file.Write( "16thnote/enableddata.json", util.TableToJSON( data, true ) )

    if !self:GetSoloPack() and IsValid( self.SoloWarning ) then
        self.SoloWarning:SetText( "" )
    end
end

-- Returns a table of packs that can be used
function SXNOTE:GetFilteredPacks( type )
    local _, musicpacks = file.Find( "sound/16thnote/*", "GAME" )

    -- NOMBAT --
    local _, nombatpacks = file.Find( "sound/nombat/*", "GAME" )
    for k, v in ipairs( nombatpacks ) do nombatpacks[ k ] = v .. "_NOMBAT" end

    table.Add( musicpacks, nombatpacks )
    ------------

    -- Remove Disabled Packs/Packs that do not contain "type" --
    for k, pack in pairs( musicpacks ) do
        local solopack = SXNOTE:GetSoloPack()

        if type == "Ambient" and !self:IsAmbientEnabled( pack ) then self:Msg( pack, " ambient music is disabled! Removing from possible tracks" ) musicpacks[ k ] = nil continue end
        if type == "Combat" and !self:IsCombatEnabled( pack ) then self:Msg( pack, " combat music is disabled! Removing from possible tracks" ) musicpacks[ k ] = nil continue end
        if solopack and pack != solopack then self:Msg( solopack .. " is set as the solo pack! Removing " .. pack .. " from possible tracks due to the presence of a solo pack" ) musicpacks[ k ] = nil continue end 

        if type == "Ambient" and !self:HasAmbientTracks( pack ) then
            musicpacks[ k ] = nil
            self:Msg( pack, " does not have Ambient files" )
        elseif type == "Combat" and !self:HasCombatTracks( pack ) then
            musicpacks[ k ] = nil
            self:Msg( pack, " does not have Combat files" )
        end
    end
    musicpacks = table.ClearKeys( musicpacks )

    return musicpacks
end

-- Returns a random track for the given type and from the given pack (if given)
-- Type: Ambient or Combat
function SXNOTE:GetRandomTrack( type, overridepack )
    local musicpacks = self:GetFilteredPacks( type )

    local randomaddon = musicpacks[ math.random( #musicpacks ) ] -- Picks a random music pack

    randomaddon = overridepack or randomaddon -- Prioritize overridepack
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

    return randomtrack and "sound/16thnote/" .. randomaddon .. "/" .. string.lower( type ) .. "/" .. randomtrack or nil, randomaddon
end

function SXNOTE:PlayRandomCombatTrack()
    local combattrack, pack = self:GetRandomTrack( "Combat" )

    -- Play in pairs
    if self:GetCvar( "16thnote_playpairs" ):GetBool() then
        local ambienttrack = self:GetRandomTrack( "Ambient", pack )
        if ambienttrack then
            self:Msg( "Starting new Ambient Track", ambienttrack )
            self:PlayTrack( ambienttrack, "Ambient" )
            self.AmbientTimeDelay = CurTime() + 3 -- Prevent track spamming which can severely degrade FPS
        else
            self:Msg( "Failed to load sound: Ambient", ambienttrack )
            self.AmbientTimeDelay = CurTime() + 30
        end
    end
    ----------------------

    if combattrack then
        self:Msg( "Starting new Combat Track", combattrack )
        self:PlayTrack( combattrack, "Combat" )
        self.CombatTimeDelay = CurTime() + 3 -- Prevent track spamming which can severely degrade FPS
    else
        self:Msg( "Failed to load sound: Combat", combattrack )
        self.CombatTimeDelay = CurTime() + 30
    end
end

function SXNOTE:PlayRandomAmbientTrack()
    local ambienttrack, pack = self:GetRandomTrack( "Ambient" )

    -- Play in pairs
    if self:GetCvar( "16thnote_playpairs" ):GetBool() then
        local combattrack = self:GetRandomTrack( "Combat", pack )
        if combattrack then
            self:Msg( "Starting new Combat Track", combattrack )
            self:PlayTrack( combattrack, "Combat" )
            self.CombatTimeDelay = CurTime() + 3 -- Prevent track spamming which can severely degrade FPS
        else
            self:Msg( "Failed to load sound: Combat", combattrack )
            self.CombatTimeDelay = CurTime() + 30
        end
    end
    ----------------------

    if ambienttrack then
        self:Msg( "Starting new Ambient Track", ambienttrack )
        self:PlayTrack( ambienttrack, "Ambient" )
        self.AmbientTimeDelay = CurTime() + 3 -- Prevent track spamming which can severely degrade FPS
    else
        self:Msg( "Failed to load sound: Ambient", ambienttrack )
        self.AmbientTimeDelay = CurTime() + 30
    end
end