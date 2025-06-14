-- Autoloading for 16thnote


SXNOTE = SXNOTE or {}


if CLIENT then
    file.CreateDir( "16thnote" )
end

local function IncludeDirectory( directory, endcallback )
    directory = directory .. "/"

    
    local lua, dirs = file.Find( directory .. "*", "LUA", "namedesc" )

    -- Loads lua files based on their prefix
    for k, luafile in ipairs( lua ) do 
        if string.StartWith( luafile, "sv_") and SERVER then
            include( directory .. luafile )
            print("16th Note Included server ", directory .. luafile )
        elseif string.StartWith( luafile, "sh_" ) then
            if SERVER then
                AddCSLuaFile( directory .. luafile )
            end
            include( directory .. luafile )
            print("16th Note Included shared ", directory .. luafile )
        elseif string.StartWith( luafile, "cl_" ) then
            if SERVER then
                AddCSLuaFile( directory .. luafile )
            elseif CLIENT then
                include( directory .. luafile )
                print("16th Note Included client ", directory .. luafile )
            end
        end
    end

    for k, dir in ipairs( dirs ) do
        IncludeDirectory( directory .. dir )
    end

    if #dirs == 0 and endcallback then
        endcallback()
    end

end

IncludeDirectory( "16thnote" )

if CLIENT then
    IncludeDirectory( "16thnote_lyric" )
end