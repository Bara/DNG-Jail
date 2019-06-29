

#if defined _playtimetracker_included
  #endinput
#endif
#define _playtimetracker_included

public SharedPlugin __pl_playtimetracker = 
{
	name = "playtimetracker",
	file = "playtimetracker.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_playtimetracker_SetNTVOptional()
{
	MarkNativeAsOptional("PlayTimeTracker_GetPlayerTimeT");
	MarkNativeAsOptional("PlayTimeTracker_GetPlayerTimeCT");
}
#endif

/**
 * Gets the player playtime in the T Team
 *
 * @return		Time in seconds
 */
native int PlayTimeTracker_GetPlayerTimeT(int client);

/**
 * Gets the player playtime in the CT Team
 *
 * @return		Time in seconds
 */
native int PlayTimeTracker_GetPlayerTimeCT(int client);

