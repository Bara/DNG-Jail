#if defined _knockout_included
    #endinput
#endif
#define _knockout_included

native bool IsClientKnockout(int client);
native bool SetClientKnockout(int client);

public SharedPlugin __pl_knockout = 
{
    name = "knockout",
    file = "knockout.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_knockout_SetNTVOptional()
{
	MarkNativeAsOptional("IsClientKnockout");
	MarkNativeAsOptional("SetClientKnockout");
}
#endif

