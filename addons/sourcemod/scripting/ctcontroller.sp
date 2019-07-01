#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <stamm>
#include <sourcecomms>
#include <emitsoundany>
#include <multicolors>
#include <adminmenu>
#include <discord>
#include <autoexecconfig>
#include <calladmin>
#include <SteamWorks>

#pragma newdecls required

#define CNAME "CT-Verify"

#define SOUND "buttons/button11.wav"
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

ConVar g_cTime = null;
ConVar g_cStammPoints = null;
ConVar g_cWebhook = null;
ConVar g_cColor = null;

bool bLogMessage = true;
bool bDebug = true;

bool g_bReady[MAXPLAYERS + 1] =  { false, ... };
bool g_bVerify[MAXPLAYERS + 1] =  { false, ... };
bool g_bBanned[MAXPLAYERS + 1] =  { false, ... };

char g_sReason[MAXPLAYERS + 1][256];

char g_sClientID[MAXPLAYERS + 1][32];

Database g_dDB = null;

ConVar g_cGraceTime = null;
int g_iRoundStart = -1;
bool g_bRoundStarted = false;
Handle g_hGraceTimer = null;
bool g_bInRound[MAXPLAYERS + 1] =  { false, ... };
int g_iRounds[MAXPLAYERS + 1] =  { -1, ... };

Handle g_hOnPlayerCheck = null;
Handle g_hOnValidCheck = null;

char g_sSymbols[25][1] = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};


#include "ctcontroller/sql.sp"
#include "ctcontroller/stocks.sp"
#include "ctcontroller/commands.sp"
#include "ctcontroller/validround.sp"

public Plugin myinfo =
{
	name = "CT Controller",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnPlayerCheck = CreateGlobalForward("CTC_OnPlayerCheck", ET_Event, Param_Cell);
	g_hOnValidCheck = CreateGlobalForward("CTC_OnValidCheck", ET_Event, Param_Cell, Param_CellByRef);

	CreateNative("CTC_IsClientValidCT", Native_IsClientValidCT);
	CreateNative("CTC_HasClientCTBan", Native_HasClientCTBan);
	CreateNative("CTC_GetClientBanReason", Native_GetClientBanReason);
	
	RegPluginLibrary("ctcontroller");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetCreateDirectory(true);
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("ctcontroller");
	g_cTime = AutoExecConfig_CreateConVar("ct_controller_menu_time", "10", "Time in seconds to show a menu");
	g_cStammPoints = AutoExecConfig_CreateConVar("ct_controller_stamm_points", "500", "Stamm points to play as ct (if the player isn't verified). 0 = Disabled (Verify + Stammpoints Check)", _, true, 0.0);
	g_cWebhook = AutoExecConfig_CreateConVar("ct_controller_discord_webhook", "ctcontroller", "Config key from configs/discord.cfg.");
	g_cColor = AutoExecConfig_CreateConVar("ct_controller_discord_color", "#ff6347", "Discord/Slack attachment color.");
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	RegConsoleCmd("sm_checkvalid", Command_CheckValid);

	// List commands
	RegConsoleCmd("sm_ctlist", Command_CTList);
	RegConsoleCmd("sm_ctbanlist", Command_CTBanList);

	// Verify commands
	RegAdminCmd("sm_verct", Command_VerifyCT, ADMFLAG_BAN);
	RegAdminCmd("sm_vertmpct", Command_VerifyTempCT, ADMFLAG_UNBAN);

	// CT (un-) ban commands
	RegAdminCmd("sm_ctban", Command_CTBan, ADMFLAG_BAN);
	RegAdminCmd("sm_ctunban", Command_CTUnBan, ADMFLAG_UNBAN);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_prestart", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	g_cGraceTime = FindConVar("mp_join_grace_time");

	AddCommandListener(Command_CheckJoin, "jointeam");
	
	LoadTranslations("common.phrases");
	LoadTranslations("ctcontroller.phrases");
	
	ConnectToSQL();
	
	CreateTimer(0.5, Timer_CheckClients, _, TIMER_REPEAT);

	CSetPrefix("{darkred}[CT Controller]{default}");
}

public int Native_IsClientValidCT(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	return IsValidCT(client);
}

public int Native_HasClientCTBan(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	return g_bBanned[client];
}

public int Native_GetClientBanReason(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	SetNativeString(2, g_sReason[client], GetNativeCell(3));

	return g_bBanned[client];
}

public void OnClientPostAdminCheck(int client)
{
	if (GetClientAuthId(client, AuthId_SteamID64, g_sClientID[client], sizeof(g_sClientID[])))
		LoadClient(client);
}

public void OnMapStart()
{
	PrecacheSoundAny(SOUND, true);
	
	ValidRound_ResetRoundStuff();
}

public void OnClientDisconnect(int client)
{
	g_bReady[client] = false;
	
	ValidRound_ResetClientStuff(client);
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_bReady[client] = false;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		int team = GetClientTeam(client);
		
		if(team != CS_TEAM_CT)
		{
			return Plugin_Continue;
		}
		
		if(IsValidCT(client))
		{
			return Plugin_Continue;
		}
		
		PlayBlockSound(client);
		
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			Action res = Plugin_Continue;
			Call_StartForward(g_hOnPlayerCheck);
			Call_PushCell(client);
			Call_Finish(res);

			if (res == Plugin_Handled || res == Plugin_Stop)
			{
				return Plugin_Continue;
			}

			ForcePlayerSuicide(client);
			ChangeClientTeam(client, CS_TEAM_T);
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Command_CheckValid(int client, int args)
{
	LoopClients(i)
	{
		if(bLogMessage && bDebug)
		{
			LogMessage("Spieler: \"%L\" - g_bReady: %d - CTC_HasFlags(b): %d - g_bBanned: %d - SourceComms_GetClientMuteType: %d - g_bVerify: %d - STAMM_GetClientPoints: %d", i, g_bReady[i], CTC_HasFlags(i, "b"), g_bBanned[i], SourceComms_GetClientMuteType(i), g_bVerify[i], STAMM_GetClientPoints(i));
		}
		
		IsValidCT(i, true);
	}
}

public Action Command_CheckJoin(int client, const char[] command, int args)
{
	if(IsClientValid(client))
	{
		char sTeam[2];
		GetCmdArg(1, sTeam, sizeof(sTeam));
		int iTeam = StringToInt(sTeam);
		
		ValidRound_JoinTeam(client, iTeam);
		
		if(iTeam != CS_TEAM_CT)
		{
			return Plugin_Continue;
		}
		
		if(iTeam == 0)
		{
			PlayBlockSound(client);
			return Plugin_Handled;
		}
		
		if(IsValidCT(client))
		{
			return Plugin_Continue;
		}
		
		PlayBlockSound(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Timer_CheckClients(Handle timer)
{
	LoopClients(i)
	{
		if(IsClientValid(i))
		{
			int team = GetClientTeam(i);
			
			if(team != CS_TEAM_CT)
			{
				continue;
			}
			
			if(IsValidCT(i))
				continue;
			
			PlayBlockSound(i);
			
			if(GetClientTeam(i) == CS_TEAM_CT)
			{
				Action res = Plugin_Continue;
				Call_StartForward(g_hOnPlayerCheck);
				Call_PushCell(i);
				Call_Finish(res);

				if (res == Plugin_Handled || res == Plugin_Stop)
				{
					return Plugin_Continue;
				}

				ForcePlayerSuicide(i);
				ChangeClientTeam(i, CS_TEAM_T);
			}
		}
	}
	return Plugin_Continue;
}

public int Panel_DeleteHandle(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;
}
