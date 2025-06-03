SXNOTE.LyricData = SXNOTE.LyricData or {}

--[[ 
    Inspired by Limbus Company

    In your music pack, add this file path: {Your addonname}/lua/16thnote/lyrics/cl_{insert unique name}.lua
    Inside your lua file, you will paste the following format.


    -- LYRIC DATA FORMAT

    id | Number | The id of the lyric. Lyrics with the same id will cause the older lyric to fade out. Usually you will want lyrics to be the same id unless there are multiple singers
    time | Number | The timestamp in the music where the lyric will show
    typespeed | Number | Time in seconds for the next text character to be shown
    lyric | String | The actual lyric text
    textcolor | Color or nil | The color of the text. Optional
    glowcolor | Color or nil | The color of the glow behind the text. Optional

    FORMAT. COPY THIS:

    SXNOTE.LyricData[ {PATH TO SOUNDFILE} ] = {
        keyframes = {
            { id = 1, time = 1, typespeed = 0.1, lyric = "", textcolor = Color(), glowcolor = Color() },
            { id = 1, time = 3, typespeed = 0.1, lyric = "", textcolor = Color(), glowcolor = Color() },
            -- so on... 
        }

    }



    EXAMPLE:

    SXNOTE.LyricData[ "sound/16thnote/limbus company/combat/Between Two Worlds.mp3" ] = {
        keyframes = {
            { id = 1, time = 2.5, typespeed = 0.2, lyric = "Ooh" },
            { id = 1, time = 6, typespeed = 0.2, lyric = "It is this time of the year" },
            { id = 1, time = 16, typespeed = 0.2, lyric = "A very so merry night we hold dear" },
            { id = 1, time = 29.5, typespeed = 0.2, lyric = "So many, so many regrets bring me to tears" },
            { id = 1, time = 43.5, typespeed = 0.2, lyric = "Not many, not many notice nor care" },
            { id = 1, time = 57, typespeed = 0.2, lyric = "Ooh" },
            { id = 1, time = 60, typespeed = 0.2, lyric = "My savior" },
            { id = 1, time = 60 + 4, typespeed = 0.2, lyric = "Ooh" },
            { id = 1, time = 60 + 6.5, typespeed = 0.2, lyric = "Why does a common fire hold so much power?" },
            { id = 1, time = 60 + 21, typespeed = 0.2, lyric = "If only we could be forever naive and pure" },
            { id = 1, time = 60 + 35, typespeed = 0.2, lyric = "If only we could lead painless futures" },
            { id = 1, time = 60 + 48.3, typespeed = 0.2, lyric = "If only there could be a forgiving world" },

            -- Realm of darkness

            { id = 1, time = 120 + 16, typespeed = 0.1, lyric = "Maybe that was when" },
            { id = 1, time = 120 + 22.2, typespeed = 0.1, lyric = "I chose to stay fallen" },
            { id = 1, time = 120 + 30, typespeed = 0.01, lyric = "Lights", textcolor = Color( 0, 0, 0 ), glowcolor = Color( 255, 0, 0 ) },
            { id = 1, time = 120 + 33, typespeed = 0.01, lyric = "A star", textcolor = Color( 0, 0, 0 ), glowcolor = Color( 255, 0, 0 ) },
            { id = 1, time = 120 + 36, typespeed = 0.01, lyric = "A voice", textcolor = Color( 0, 0, 0 ), glowcolor = Color( 255, 0, 0 ) },

            ...
            ...
            ...
        }
    }

    Lyrics will automatically play when the song plays

 ]]
SXNOTE.LyricDisplays = SXNOTE.LyricDisplays or {}

for id, lyricobject in pairs( SXNOTE.LyricDisplays ) do
    lyricobject:Fade()
    SXNOTE.LyricDisplays[ id ] = nil
end


-- Dumps all currently installed lyrics into a dat file that can be referred to when playing on servers that do not have the lyrics
-- Essentially allows the lyrics to be played on any server
function SXNOTE:CacheLyrics()
    self:ClearLyricCooldowns()
    local json = util.TableToJSON( self.LyricData )
    local compresseddata = util.Compress( json )

    file.Write( "16thnote/cachedlyrics.dat", compresseddata )
    self:Msg( "Cached Lyrics" )
end

-- I did not consider that the addon would save keyframe SysTime cooldowns. This function will solve the problems that come with that (i.e lyrics not playing in multiplayer).
function SXNOTE:ClearLyricCooldowns()
    local data = self:GetLyricData()

    for filepath, lyricdata in pairs( data ) do
        for _, keyframes in ipairs( lyricdata.keyframes ) do
            keyframes.cooldown = 0
        end
    end
end

-- Cache lyrics on disconnect
gameevent.Listen( "client_disconnect" )
hook.Add( "client_disconnect", "16thnote_cachelyrics", function()
    if game.SinglePlayer() then
        SXNOTE:CacheLyrics()
    end
end )

-- In singleplayer, return lyric data
-- In multiplayer check our lyric cache and attempt to apply it to lyric data.
function SXNOTE:GetLyricData()
    if game.SinglePlayer() or self.AppliedLyricCache then return self.LyricData end

    self:Msg( "Fetching Lyric Cache" )

    -- Fetch the lyric cache if possible
    if !self.CachedLyricData then
        self.CachedLyricData = file.Read( "16thnote/cachedlyrics.dat", "DATA" )
        if self.CachedLyricData then
            self.CachedLyricData = util.Decompress( self.CachedLyricData )
            self.CachedLyricData = util.JSONToTable( self.CachedLyricData )
        end
    end

    -- Apply the cache to lyric data
    if self.CachedLyricData then
        for filepath, data in pairs( self.CachedLyricData ) do
            if !self.LyricData[ filepath ] then
                self.LyricData[ filepath ] = data 
                self.LyricData[ string.lower( filepath ) ] = data -- Incase this is from an addon since filenames are forced to lowercase
                self:Msg( "Adding " .. filepath .. " lyrics to data" )
            end 
        end

        self:Msg( "Applied lyric cache to lyric data" )
        self.AppliedLyricCache = true
    end


end

function SXNOTE:DisplayLimbusStyleLyric( id, type_speed, lyric, textcolor, glowcolor ) 
    if SXNOTE.LyricDisplays[ id ] then
        SXNOTE.LyricDisplays[ id ]:Fade()
    end

    local lyricobject = {}

    local textclr = Color( textcolor.r, textcolor.g, textcolor.b )
    local glowclr = Color( glowcolor.r, glowcolor.g, glowcolor.b )

    lyricobject.IsValid = function( self ) return true end
    lyricobject.Kill = function( self ) self.remove = true end

    lyricobject.Fade = function( self ) self.fadeout = true end

    surface.SetFont("16thnote_limbuslyric")

    local scale = 0.4
    local forward = LocalPlayer():EyeAngles():Forward()
    local right = LocalPlayer():EyeAngles():Right()


    local pos = forward * math.random( 400, 1000 ) + right * math.random( -200, 200 ) + Vector( 0, 0, math.random( 10, 200 ) )
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)

    local expiretime = SysTime() + 10
    local extrashaketime = 0
    local lyric_index = 0
    local shake = {}
    local nexttype = SysTime() + type_speed

    local offsetpitch = Angle( math.random( -30, 30 ), 0, 0 )
    local fadeoutoffset = Vector()
    local lyricoffset = Vector( 0, 0, math.Rand( -10, 10 ) )

    hook.Add( "PreDrawEffects", lyricobject, function()
        if lyricobject.remove then hook.Remove( "PreDrawEffects", lyricobject ) return end
        
        if nexttype < SysTime() and lyric_index < #lyric then
            lyric_index = lyric_index + 1
            extrashaketime = SysTime() + 0.4
            expiretime = SysTime() + 10
            nexttype = SysTime() + type_speed
        end

        if expiretime < SysTime() then
            lyricobject:Fade()
        end

        if lyricobject.fadeout then
            textclr.a = math.Clamp( textclr.a - 2, 0, 255 )
            glowclr.a = textclr.a
            extrashaketime = SysTime() + 0.2

            fadeoutoffset = fadeoutoffset + ang:Up() * -1 + Vector( 0, 0, 0.5 )

            if textclr.a <= 0 then
                lyricobject:Kill()
            end
        end
        
        surface.SetFont( "16thnote_limbuslyric" )

        local origin = LocalPlayer():EyePos() + pos
        local baseAng = ang
        local drawOffset = Vector(0, 0, 0) + fadeoutoffset
    
        for i = 1, lyric_index do
            shake[i] = shake[i] or { nextshake = 0, shakep = 0 }
    
            if shake[i].nextshake < SysTime() then
                shake[i].shakep = math.Rand(-2, 2)
                shake[i].nextshake = SysTime() + 0.08
            end
    
            local ch = lyric[i]
            local ch_width = surface.GetTextSize(ch)
    
            local typeshake = extrashaketime > SysTime() and math.Rand( -1, 1 ) or 0
            local charAng = baseAng + Angle(shake[i].shakep + typeshake, 0, 0)
    
            cam.Start3D2D(origin + drawOffset + lyricoffset * i, charAng, scale)

                render.DepthRange( 0, 0 )
                    draw.DrawText(ch, "16thnote_limbuslyric_glow", 0, 0, glowclr, TEXT_ALIGN_LEFT)
                    draw.DrawText(ch, "16thnote_limbuslyric", 0, 0, textclr, TEXT_ALIGN_LEFT)
                render.DepthRange( 0, 1 )
            cam.End3D2D()
    

            local right = baseAng:Forward() * (ch_width * scale)
            drawOffset = drawOffset + right * 1.5
        end
        

    end )

    SXNOTE.LyricDisplays[ id ] = lyricobject
end


hook.Add( "Think", "16thnote_limbus-styled-lyrics", function()
    if !GetConVar( "16thnote_allowlyrics" ):GetBool() then return end
    local currentsong = SXNOTE:GetCurrentChannel()

    if !IsValid( currentsong ) then return end

    local filename = currentsong:GetFileName()

    local data = SXNOTE:GetLyricData()

    if !data or ( !data[ string.lower( filename ) ] and !data[ filename  ] ) then return end

    local lyrics = data[ string.lower( filename ) ] or data[ filename ]

    local time = math.Round( currentsong:GetTime(), 4 )

    for _, keyframes in ipairs( lyrics.keyframes ) do
        local id, lyric_time, type_speed, lyric = keyframes.id, keyframes.time, keyframes.typespeed, keyframes.lyric
        local textcolor = keyframes.textcolor or Color( 255, 224, 141 )
        local glowcolor = keyframes.glowcolor or textcolor

        -- Since sometimes lyrics can be skipped over by using this method, use the new NearlyEqual function to account for possible skips
        if math.IsNearlyEqual( lyric_time, time, 1e-1 ) and ( !keyframes.cooldown or SysTime() > keyframes.cooldown ) then
            SXNOTE:DisplayLimbusStyleLyric( id, type_speed, lyric, textcolor, glowcolor ) 
            keyframes.cooldown = SysTime() + 1.1
            
        end
    end
end )