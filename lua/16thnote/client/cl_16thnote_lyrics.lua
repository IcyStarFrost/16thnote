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

    FORMAT:

    SXNOTE.LyricData[ {PATH TO SOUNDFILE} ] = {
        keyframes = {
            { id = 1, time = 1, typespeed = 0.1, lyric = "" },
            { id = 1, time = 3, typespeed = 0.1, lyric = "" },
            so on... 
        }

    }



    EXAMPLE:

    SXNOTE.LyricData[ "sound/16thnote/limbus company/ambient/Fly My Wings.mp3" ] = {
        keyframes = {
            { id = 1, time = 13, typespeed = 0.1, lyric = "Fly, broken wings" },
            { id = 1, time = 16, typespeed = 0.1, lyric = "I know you are still with me" },
            { id = 1, time = 21, typespeed = 0.1, lyric = "All I need is a nudge to get me started" },
             so on...
             
        }
    }

    Lyrics will automatically play when the song plays

 ]]
SXNOTE.LyricDisplays = SXNOTE.LyricDisplays or {}

for id, lyricobject in pairs( SXNOTE.LyricDisplays ) do
    lyricobject:Fade()
    SXNOTE.LyricDisplays[ id ] = nil
end



function SXNOTE:DisplayLimbusStyleLyric( id, type_speed, lyric ) 
    if SXNOTE.LyricDisplays[ id ] then
        SXNOTE.LyricDisplays[ id ]:Fade()
    end

    local lyricobject = {}

    local color = Color( 255, 224, 141 )

    lyricobject.IsValid = function( self ) return true end
    lyricobject.Kill = function( self ) self.remove = true end

    lyricobject.Fade = function( self ) self.fadeout = true end

    surface.SetFont("16thnote_limbuslyric")

    local scale = 0.4
    local forward = EyeAngles():Forward()
    local right = EyeAngles():Right()

    local totalWidth = 0
    for i = 1, #lyric do
        local ch = lyric[i]
        local ch_width = surface.GetTextSize(ch)
        totalWidth = totalWidth + ch_width
    end
    totalWidth = totalWidth * 0.1

    local pos = EyePos() + forward * math.random( totalWidth, 1000 ) + right * math.random( -200, 200 ) + Vector( 0, 0, math.random( 10, 200 ) )
    local ang = EyeAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)

    local expiretime = SysTime() + 10
    local lyric_index = 0
    local shake = {}
    local nexttype = SysTime() + type_speed

    local offsetpitch = Angle( math.random( -30, 30 ), 0, 0 )
    local fadeoutoffset = Vector()

    hook.Add( "PreDrawEffects", lyricobject, function()
        if lyricobject.remove then hook.Remove( "PreDrawEffects", lyricobject ) return end
        
        if nexttype < SysTime() and lyric_index < #lyric then
            lyric_index = lyric_index + 1
            nexttype = SysTime() + type_speed
        end

        if expiretime < SysTime() then
            lyricobject:Fade()
        end

        if lyricobject.fadeout then
            color.a = math.Clamp( color.a - 2, 0, 255 )

            fadeoutoffset = fadeoutoffset + ang:Up() * -1

            if color.a <= 0 then
                lyricobject:Kill()
            end
        end
        
        surface.SetFont( "16thnote_limbuslyric" )

        local origin = pos
        local baseAng = ang + offsetpitch
        local drawOffset = Vector(0, 0, 0) + fadeoutoffset
    
        for i = 1, lyric_index do
            shake[i] = shake[i] or { nextshake = 0, shakep = 0 }
    
            if shake[i].nextshake < SysTime() then
                shake[i].shakep = math.Rand(-2, 2)
                shake[i].nextshake = SysTime() + 0.08
            end
    
            local ch = lyric[i]
            local ch_width = surface.GetTextSize(ch)
    
            local charAng = baseAng + Angle(shake[i].shakep, 0, 0)
    
            cam.Start3D2D(origin + drawOffset, charAng, scale)

                render.DepthRange( 0, 0 )
                    draw.DrawText(ch, "16thnote_limbuslyric", 0, 0, color, TEXT_ALIGN_LEFT)
                    draw.DrawText(ch, "16thnote_limbuslyric_glow", 0, 0, color, TEXT_ALIGN_LEFT)
                render.DepthRange( 0, 1 )
            cam.End3D2D()
    

            local right = baseAng:Forward() * (ch_width * scale)
            drawOffset = drawOffset + right * 1.5
        end
        

    end )

    SXNOTE.LyricDisplays[ id ] = lyricobject
end


local allowlyrics = GetConVar( "16thnote_allowlyrics" )
hook.Add( "Think", "16thnote_limbus-styled-lyrics", function()
    if !allowlyrics:GetBool() then return end
    local currentsong = SXNOTE:GetCurrentChannel()

    if !currentsong then return end

    local filename = currentsong:GetFileName()

    if !SXNOTE.LyricData[ filename ] then return end

    local lyrics = SXNOTE.LyricData[ filename ]
    local time = math.Round( currentsong:GetTime(), 1 )

    for _, keyframes in ipairs( lyrics.keyframes ) do
        local id, lyric_time, type_speed, lyric = keyframes.id, keyframes.time, keyframes.typespeed, keyframes.lyric

        if lyric_time == time and ( !keyframes.cooldown or SysTime() > keyframes.cooldown ) then
            SXNOTE:DisplayLimbusStyleLyric( id, type_speed, lyric ) 
            keyframes.cooldown = SysTime() + 1.1
            
        end
    end
end )