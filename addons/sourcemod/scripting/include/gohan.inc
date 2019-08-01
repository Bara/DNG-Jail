#if defined _gohan_included
 #endinput
#endif
#define _gohan_included


native void SetGohanMode(int client, bool status);

public SharedPlugin __pl_gohan = 
{
	name = "gohan",
	file = "gohan.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gohan_SetNTVOptional()
{
	MarkNativeAsOptional("SetGohanMode");
}
#endif
