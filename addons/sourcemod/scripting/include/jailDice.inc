#if defined _jailDice_included
 #endinput
#endif
#define _jailDice_included


native bool Dice_IsClientAssassine(int client);
native bool Dice_HasClientBhop(int client);
native bool Dice_LoseAll(int client);

public SharedPlugin __pl_jailDice = 
{
	name = "jailDice",
	file = "jailDice.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_jailDice_SetNTVOptional()
{
	MarkNativeAsOptional("Dice_IsClientAssassine");
	MarkNativeAsOptional("Dice_HasClientBhop");
	MarkNativeAsOptional("Dice_LoseAll");
}
#endif
