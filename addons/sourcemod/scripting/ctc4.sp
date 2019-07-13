#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <dng-jail> 

public Plugin myinfo =
{
	name = "CT - C4",
	author = "Bara",
	version = "1.0.0",
	description = "",
	url = "github.com/Bara"
};

ConVar g_cBombPlant = null;
bool g_bWait = false;
bool g_bHolding[MAXPLAYERS+1] = { false, ... };

int iBomb = INVALID_ENT_REFERENCE;

public void OnPluginStart()
{
	g_cBombPlant = CreateConVar("ctc4_canplant", "0", "Defines if CTs can plant the bomb. Default = 0");
	
	HookEvent("bomb_dropped", Event_BombDropped);
	HookEvent("bomb_pickup", Event_BombPickup);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_beginplant", Event_BombBeginplant);
	HookEvent("round_end", Event_RoundEnd);

	LoopClients(i)
	{
		SDKHook(i, SDKHook_Touch, Touch);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_Touch, Touch);
}

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_Touch, Touch);
		
		g_bHolding[client] = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Get the entity index of the bomb
	if(StrEqual(classname, "weapon_c4"))
	{
		iBomb = entity;
	}
	
	// If the bomb is planted, set the bomb entity index to -1
	if(StrEqual(classname, "planted_c4"))
	{
		iBomb = INVALID_ENT_REFERENCE;
	}
}

public Action Touch(int client, int entity)
{
	if(!g_bWait && client > 0 && client <= MaxClients && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && 
		!g_bHolding[client] && iBomb != INVALID_ENT_REFERENCE && entity == iBomb)
	{
		RemoveEdict(entity);
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
		GivePlayerItem(client, "weapon_c4");
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
		
		g_bHolding[client] = true;
	}
}

public Action Event_BombDropped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		g_bWait = true;
		CreateTimer(0.5, Timer_Wait);
		g_bHolding[client] = false;
	}
}

public Action Event_BombPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		g_bHolding[client] = true;
	}
}

public Action Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		g_bHolding[client] = false;
	}
}


public Action Event_BombBeginplant(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT && !GetConVarBool(g_cBombPlant))
	{
		int iC4 = GetPlayerWeaponSlot(client, CS_SLOT_C4);
		
		RemovePlayerItem(client, iC4);
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
		GivePlayerItem(client, "weapon_c4");
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
		
		g_bHolding[client] = true;
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && g_bHolding[i])
		{
			g_bHolding[i] = false;
		}
	}
}

public Action Timer_Wait(Handle timer)
{
	g_bWait = false;
}
