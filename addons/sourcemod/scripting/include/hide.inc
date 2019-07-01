#if defined _hide_included
    #endinput
#endif
#define _hide_included

native bool Hide_IsActive();

public SharedPlugin __pl_hide = 
{
    name = "hide",
    file = "hide.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};
