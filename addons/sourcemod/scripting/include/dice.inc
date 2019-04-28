#if defined _dice_included
 #endinput
#endif
#define _dice_included


native bool Dice_IsClientAssassine(int client);
native bool Dice_HasClientBhop(int client);
native bool Dice_LoseAll(int client);

public SharedPlugin __pl_dice = 
{
	name = "dice",
	file = "dice.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_dice_SetNTVOptional()
{
	MarkNativeAsOptional("Dice_IsClientAssassine");
	MarkNativeAsOptional("Dice_HasClientBhop");
	MarkNativeAsOptional("Dice_LoseAll");
}
#endif
