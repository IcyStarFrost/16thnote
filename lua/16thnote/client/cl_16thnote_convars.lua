SXNOTE.Cvars = {}

function SXNOTE:CreateConVar( name, default, save, userinfo, desc, min, max )
    local cvar = CreateClientConVar( name, default, save, userinfo, desc, min, max )
    self.Cvars[ name ] = cvar
    return cvar
end

function SXNOTE:GetCvar( name )
    return self.Cvars[ name ]
end

-- Individual volume controls
SXNOTE:CreateConVar( "16thnote_ambientvolume", 1, true, false, "The volume of ambient music", 0, 10 )
SXNOTE:CreateConVar( "16thnote_combatvolume", 1, true, false, "The volume of combat music", 0, 10 )

-- Other
SXNOTE:CreateConVar( "16thnote_playpairs", 0, true, false, "If both the Ambient track and Combat track should always play from the same pack", 0, 1 )
SXNOTE:CreateConVar( "16thnote_combatthreshold", 1, true, true, "How many enemies are required for Combat tracks to start playing", 1, 10 )
SXNOTE:CreateConVar( "16thnote_debug", 0, false, false, "Enables Debug mode", 0, 1 )
SXNOTE:CreateConVar( "16thnote_alwayswarn", 0, true, false, "If 16th note should always warn you of music that failed to load", 0, 1 )
SXNOTE:CreateConVar( "16thnote_pvp", 1, true, true, "Allows combat music to play if 16th Note believes a player is attacking you", 0, 1 )
SXNOTE:CreateConVar( "16thnote_forceplaytype", "none", true, false, "Forces a certain type to always play regardless of combat state" )

-- Track Display
SXNOTE:CreateConVar( "16thnote_currenttrackdisplay_x", 0, true, false, "The X position of the current track display as a percentage of your screen", 0, 1 )
SXNOTE:CreateConVar( "16thnote_currenttrackdisplay_y", 0, true, false, "The Y position of the current track display as a percentage of your screen", 0, 1 )
SXNOTE:CreateConVar( "16thnote_enabletrackdisplay", 1, true, false, "Enables the current track display", 0, 1 )
SXNOTE:CreateConVar( "16thnote_permanentdisplay", 0, true, false, "Whether the track display should be rendered permanently", 0, 1 )

-- LOS only option
SXNOTE:CreateConVar( "16thnote_los", 1, true, true, "If combat music should only play if the enemy has line of sight to the player", 0, 1 )

cvars.AddChangeCallback( "16thnote_currenttrackdisplay_x", function()
    SXNOTE.TrackDisplayTime = SysTime() + SXNOTE.DisplayTimeConstant
end )

cvars.AddChangeCallback( "16thnote_enabletrackdisplay", function()
    SXNOTE.TrackDisplayTime = SysTime() + SXNOTE.DisplayTimeConstant
end )

cvars.AddChangeCallback( "16thnote_currenttrackdisplay_y", function()
    SXNOTE.TrackDisplayTime = SysTime() + SXNOTE.DisplayTimeConstant
end )

