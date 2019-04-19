#if defined _glow_included
    #endinput
#endif
#define _glow_included

forward Action OnGlowCheck(int client, int target, bool &seeTarget, bool &overrideColor, int &red, int &green, int &blue, int &alpha, int &style);

public SharedPlugin __pl_glow = 
{
    name = "glow",
    file = "glow.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};
