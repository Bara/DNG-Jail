#if defined _jailSystem_included
 #endinput
#endif
#define _jailSystem_included


forward void jailSystem_OnMySQLCOnnect(Database database);

native Database jailSystem_GetDatabase();

public SharedPlugin __pl_jailSystem = 
{
	name = "jailSystem",
	file = "jailSystem.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_jailSystem_SetNTVOptional()
{
	MarkNativeAsOptional("jailSystem_GetDatabase");
}
#endif
