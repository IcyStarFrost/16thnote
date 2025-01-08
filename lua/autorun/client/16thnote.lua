SXNOTE = SXNOTE or {}
SXNOTE.FadeoutIncrement = 0

-- Individual volume controls
local ambientvolume = CreateClientConVar( "16thnote_ambientvolume", 1, true, false, "The volume of ambient music", 0, 10 )
local combatvolume = CreateClientConVar( "16thnote_combatvolume", 1, true, false, "The volume of combat music", 0, 10 )

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

-- Retrieves a random track from a random addon module or nombat pack
function SXNOTE:GetRandomTracks()
    local _, addontracks = file.Find( "sound/16thnote/*", "GAME" )

    -- NOMBAT --
    local _, nombatpacks = file.Find( "sound/nombat/*", "GAME" )
    for k, v in ipairs( nombatpacks ) do nombatpacks[ k ] = v .. "_NOMBAT" end

    table.Add( addontracks, nombatpacks )
    ------------

    local randomaddon = addontracks[ math.random( #addontracks ) ] -- Picks a random addon module for 16thnote

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
    if IsValid( SXNOTE.Combat ) and SXNOTE.Combat:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Combat ) or ( SXNOTE.Combat:GetTime() / SXNOTE.Combat:GetLength() ) >= 0.95 then
        local _, combattrack = SXNOTE:GetRandomTracks()
        if combattrack then
            SXNOTE:PlayTrack( combattrack, "Combat" )
        end
    end

    if IsValid( SXNOTE.Ambient ) and SXNOTE.Ambient:GetState() == GMOD_CHANNEL_STOPPED or !IsValid( SXNOTE.Ambient ) or ( SXNOTE.Ambient:GetTime() / SXNOTE.Ambient:GetLength() ) >= 0.95 then
        local ambienttrack = SXNOTE:GetRandomTracks()
        if ambienttrack then
            SXNOTE:PlayTrack( ambienttrack, "Ambient" )
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