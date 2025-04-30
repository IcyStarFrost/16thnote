
--if !SXNOTE.LoadedFonts then

    surface.CreateFont( "16thnote_limbuslyric", {
        font = "Mikodacs",
        extended = false,
        size = 120,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    } )

    surface.CreateFont( "16thnote_limbuslyric_glow", {
        font = "Mikodacs",
        extended = false,
        size = 120,
        weight = 300,
        blursize = 8,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    } )
    

    --SXNOTE.LoadedFonts = true
--end