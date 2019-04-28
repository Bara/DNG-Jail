#if defined _jail_included
 #endinput
#endif
#define _jail_included


forward void Jail_OnMySQLCOnnect(Database database);

native Database Jail_GetDatabase();

public SharedPlugin __pl_jail = 
{
	name = "jail",
	file = "jail.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_jail_SetNTVOptional()
{
	MarkNativeAsOptional("Jail_GetDatabase");
}
#endif
