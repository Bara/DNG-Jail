#pragma semicolon 1
#pragma newdecls optional

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dng-jail>
#include <clientprefs>
#include <autoexecconfig>
#include <emitsoundany>
#include <menu-stocks>
#include <multicolors>
#include <lastrequest>
#include <dice>
#include <stamm>
#include <glow>
#include <hide>
#include <zombie>

#undef REQUIRED_PLUGIN
#include <store>

#pragma newdecls required

#define PL_NAME "Jail"

bool g_bStore = false;

Handle g_hOnMySQLConnect = null;
Database g_dDB = null;

// CT Boost
ConVar g_cEnableCTBoost = null;
ConVar g_cCTBoostHealth = null;
ConVar g_cCTBoostHealthMulti = null;
ConVar g_cCTBoostArmor = null;
ConVar g_cCTBoostHelm = null;
ConVar g_cEnableFreeday = null;
ConVar g_cEnableFreedayTeams = null;
ConVar g_cEnableShowDamage = null;
ConVar g_cEnableVoiceMenu = null;
ConVar g_cEnableLRPoints = null;
ConVar g_cLRPointsMode = null;
#if defined _store_included
ConVar g_cLRPointsStoreCredits = null;
#endif
ConVar g_cLRPointsStammpoints = null;
ConVar g_cEnableExtraPointsCT = null;
ConVar g_cEnableExtraPointsTag = null;
ConVar g_cEnableNewBeacon = null;
ConVar g_cNewBeaconPoints = null;

#include "jail/ergeben.sp"
#include "jail/verweigern.sp"
#include "jail/freedayteams.sp"
#include "jail/teamdamage.sp"
#include "jail/freeday.sp"
#include "jail/freekill.sp"
#include "jail/spawnweapons.sp"
#include "jail/kill.sp"
#include "jail/showdamage.sp"
#include "jail/lrStammpunkte.sp"
#include "jail/extraStammpunkte.sp"
#include "jail/newBeacon.sp"
#include "jail/mysql.sp"
#include "jail/ctboost.sp"
#include "jail/voicemenu.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnMySQLConnect = CreateGlobalForward("Jail_OnMySQLCOnnect", ET_Ignore, Param_Cell);
	
	CreateNative("Jail_GetDatabase", Native_GetDatabase);
	CreateNative("Jail_IsClientCapitulate", Native_IsCapitulate);

	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
	
	RegPluginLibrary("jail");
	
	return APLRes_Success;
}
public Plugin myinfo =
{
	name = "Jail - Collection of jail functions", 
	author = "Bara", 
	description = "", 
	version = "1.0", 
	url = "github.com/Bara"
};

public void OnPluginStart()
{
#if defined _store_included
	// Fix warning with store.inc
	if (g_cvarChatTag) {}
#endif

	MySQL_OnPluginStart();
	Teamdamage_OnPluginStart();
	Freekill_OnPluginStart();
	Kill_OnPluginStart();
	VoiceMenu_OnPluginStart();
	Spawnweapons_OnPluginStart();
	NewBeacon_OnPluginStart();

	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_e", Command_ergeben);
	RegConsoleCmd("sm_v", Command_verweigern);
	RegConsoleCmd("sm_vreset", Command_vreset);
	RegConsoleCmd("sm_teamdamage", Command_teamdamage);
	RegConsoleCmd("sm_td", Command_teamdamage);
	RegConsoleCmd("sm_fd", Command_freeday);
	RegConsoleCmd("sm_kill", Command_kill);
	RegConsoleCmd("sm_fk", Command_freekill);
	RegConsoleCmd("sm_noob", Command_Noob);
	
	RegAdminCmd("sm_fixws", Command_FixWS, ADMFLAG_GENERIC);
	
	Handle hCvar = FindConVar("mp_teammates_are_enemies");
	int flags = GetConVarFlags(hCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(hCvar, flags);
	delete hCvar;
	
	RegAdminCmd("sm_fkban", Command_fkBan, ADMFLAG_GENERIC);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_hurt", PlayerHurt);
	
	AutoExecConfig_SetCreateDirectory(true);
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("jail");
	g_cEnableCTBoost = AutoExecConfig_CreateConVar("jail_enable_ctboost", "1", "Enable CT Boost?", _, true, 0.0, true, 1.0);
	g_cCTBoostHealth = AutoExecConfig_CreateConVar("jail_enable_ctboost_health", "1", "Enable Health CT Boost?", _, true, 0.0, true, 1.0);
	g_cCTBoostHealthMulti = AutoExecConfig_CreateConVar("jail_ctboot_health_multi", "10.2842", "Faktor for CT Boost Health");
	g_cCTBoostArmor = AutoExecConfig_CreateConVar("jail_enable_armor", "1", "Enable Armor CT Boost?", _, true, 0.0, true, 1.0);
	g_cCTBoostHelm = AutoExecConfig_CreateConVar("jail_enable_helm", "1", "Enable Helm CT Boost?", _, true, 0.0, true, 1.0);
	g_cEnableFreeday = AutoExecConfig_CreateConVar("jail_enable_freeday", "1", "Enable Freeday?", _, true, 0.0, true, 1.0);
	g_cEnableFreedayTeams = AutoExecConfig_CreateConVar("jail_enable_freeday_teams", "1", "Enable Freeday Teams?", _, true, 0.0, true, 1.0);
	g_cEnableShowDamage = AutoExecConfig_CreateConVar("jail_enable_showdamage", "1", "Enable Show Damage?", _, true, 0.0, true, 1.0);
	g_cEnableVoiceMenu = AutoExecConfig_CreateConVar("jail_enable_voicemenu", "1", "Enable Voice Menu?", _, true, 0.0, true, 1.0);
	g_cEnableLRPoints = AutoExecConfig_CreateConVar("jail_enable_lr_points", "1", "Enable LR Points?", _, true, 0.0, true, 1.0);
	g_cEnableExtraPointsCT = AutoExecConfig_CreateConVar("jail_enable_extra_points_name", "1", "Enable Extra Points as CT?", _, true, 0.0, true, 1.0);
	g_cEnableExtraPointsTag = AutoExecConfig_CreateConVar("jail_enable_extra_points_tag", "1", "Enable Extra Points for Tag (Name/Clantag)?", _, true, 0.0, true, 1.0);
	g_cEnableNewBeacon = AutoExecConfig_CreateConVar("jail_enable_newBeacon", "1", "Enable Beacon for new Players?", _, true, 0.0, true, 1.0);
	g_cNewBeaconPoints = AutoExecConfig_CreateConVar("jail_newBeacon_points", "240", "Until how much points will get a player the glow effect?");
	g_cLRPointsMode = AutoExecConfig_CreateConVar("jail_lr_points_mode", "0", "Which points the player get after won lr? ( 0 - Store Credits, 1 - Stammpoints, 2 - Both", _, true, 0.0, true, 2.0);
#if defined _store_included
	g_cLRPointsStoreCredits = AutoExecConfig_CreateConVar("jail_lr_points_store_credits", "10", "How much store credits after lr win? ( 0 = Disabled)");
#endif
	g_cLRPointsStammpoints = AutoExecConfig_CreateConVar("jail_lr_points_stammpoints", "10", "How much stammpoints after lr win? ( 0 = Disabled)");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	

	LoopClients(client)
	{
		OnClientCookiesCached(client);
	}

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public void OnAllPluginsLoaded()
{
	g_bStore = LibraryExists("store");
}

public void OnMapStart()
{
	Freeday_OnMapStart();
	Freekill_OnMapStart();
}

public void OnClientCookiesCached(int client)
{
	Freekill_OnClientCookiesCached(client);
	NewBeacon_OnClientCookiesCached(client);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Freedayteams_RoundStart();
	Freekill_RoundStart();
#if defined _stamm_included
	LrStammpunkte_RoundStart();
#endif
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Teamdamage_RoundEnd();

#if defined _stamm_included
	LrStammpunkte_RoundEnd();
#endif
	
	LoopClients(client)
	{
		ResetErgeben(client);
		ResetVerweigern(client);
		ResetFreeday(client);
		ResetFreekill(client);
		ResetSpawnweapons(client);
	}
}

public Action Command_FixWS(int client, int args)
{
	ServerCommand("sm plugins unload CSGO_Items");
	CreateTimer(0.3, Timer_FixWS, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_FixWS(Handle timer)
{
	ServerCommand("sm plugins load CSGO_Items");
}

public void OnClientPostAdminCheck(int client)
{
	if(IsClientValid(client) && g_dDB != null)
		Freekill_GetStatus(client);
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		ResetErgeben(client);
		ResetVerweigern(client);
		ResetFreeday(client);
		ResetFreekill(client);
		VoiceMenu_ResetSettings(client);

		if (!Zombie_IsActive() && !Hide_IsActive())
		{
			Spawnweapons_PlayerSpawn(client);
			NewBeacon_PlayerSpawn(client);
			CTBoost_PlayerSpawn(client);
		}
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
#if defined _stamm_included
	LrStammpunkte_PlayerDeath();
#endif

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(IsClientValid(client))
	{
		CPrintToChat(client, "Zu früh gestorben? Es gibt auch Minispiele wie %s!tetris, !snake %sund %s!pong", SPECIAL, TEXT, SPECIAL);
		if(IsClientValid(attacker))
		{
			Freekill_PlayerDeath(client, attacker);
		}
	}
}

public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(IsClientValid(attacker))
	{
		int damage = event.GetInt("dmg_health");
		
		Showdamage_PlayerHurt(attacker, damage);
	}
}

public void OnClientDisconnect(int client)
{
	ResetErgeben(client);
	ResetVerweigern(client);
	ResetFreeday(client);
	ResetFreekill(client);
	ResetSpawnweapons(client);
	ResetClientLrStammpunkte(client);
	NewBeacon_OnClientDisconnect(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientValid(client))
	{
		return Plugin_Continue;
	}

	if(IsPlayerAlive(client))
	{
		CS_SetClientContributionScore(client, 1);
	}
	else
	{
		CS_SetClientContributionScore(client, 0);
	}
	
	if(IsPlayerAlive(client) && g_bFreeday[client])
	{
		if(buttons & IN_JUMP)
		{
			if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
			{
				SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
				
				if(!(GetEntityFlags(client) & FL_ONGROUND))
				{
					buttons &= ~IN_JUMP;
				}
			}
		}
	}

	return Plugin_Continue;
}
