#if defined _zombie_included
    #endinput
#endif
#define _zombie_included

native bool Zombie_IsActive();

public SharedPlugin __pl_zombie = 
{
    name = "zombie",
    file = "zombie.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};
