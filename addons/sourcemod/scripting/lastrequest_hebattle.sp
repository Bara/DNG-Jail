#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <hosties>
#include <lastrequest>
#include <dng-jail>

#define HEBATTLE_VERSION "1.0.2"

new g_LREntryNum;
new LR_Player_Guard = -1;
new LR_Player_Prisoner = -1;
new String:g_sLR_Name[64];
new bool:IsThisLRInProgress = false;
new g_iHealth;
new starthp = 100;
new Handle:g_Cvar_Health;

public Plugin:myinfo =
{
	name = "Last Request: HE Battle",
	author = "Jason Bourne & Kolapsicle",
	description = "",
	version = HEBATTLE_VERSION,
	url = ""
};


public OnPluginStart()
{
	LoadTranslations("hebattle.phrases");
	
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Name", LANG_SERVER);
	
	HookEvent("hegrenade_detonate", GrenadeDetonate);
	
	g_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
	if (g_iHealth == -1)
	{
	SetFailState("Error - Unable to get offset for CSSPlayer::m_iHealth");
	}
	
	g_Cvar_Health = CreateConVar("sm_hebattle_health", "100", "How much health should be given?", _, true, 0.0, false);
	AutoExecConfig(true, "hebattle");
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
	
	LR_Player_Prisoner = -1;
	LR_Player_Guard = -1;

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}


public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsThisLRInProgress)
	{
		if (victim == LR_Player_Prisoner || victim == LR_Player_Guard)
		{
			char sGrenade[32];
			GetEdictClassname(inflictor, sGrenade, sizeof(sGrenade));
			
			if (StrContains(sGrenade, "_projectile", false) != -1)
			{
				return Plugin_Continue;
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}


public OnConfigsExecuted ()
{
	starthp = GetConVarInt(g_Cvar_Health);
	
	static bool:bAddedCustomLR = false;
	if ( ! bAddedCustomLR)
	{
		g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, g_sLR_Name);
		bAddedCustomLR = true;
	}
}


public OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, g_sLR_Name);
}


public LR_Start(Handle:LR_Array, iIndexInArray)
{
	new This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (This_LR_Type == g_LREntryNum)
	{
		LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);

		// check datapack value
		new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);
		switch (LR_Pack_Value)
		{
			case -1:
			{
				PrintToServer("no info included");
			}
		}

		SetEntityHealth(LR_Player_Prisoner, starthp);
		SetEntityHealth(LR_Player_Guard, starthp);

		StripAllWeapons(LR_Player_Prisoner);
		StripAllWeapons(LR_Player_Guard);

		GivePlayerItem(LR_Player_Prisoner, "weapon_hegrenade");
		GivePlayerItem(LR_Player_Guard, "weapon_hegrenade");

		IsThisLRInProgress = true;
		CPrintToChatAll("%t", "LR Start", LR_Player_Prisoner, LR_Player_Guard);
	}
}


public LR_Stop(This_LR_Type, Player_Prisoner, Player_Guard)
{
	if (IsThisLRInProgress && This_LR_Type == g_LREntryNum)
	{
		LR_Player_Prisoner = Player_Prisoner;
		LR_Player_Guard = Player_Guard;

		if (IsPlayerAlive(LR_Player_Prisoner) && IsPlayerAlive(LR_Player_Guard))
		{
			SetEntityHealth(LR_Player_Prisoner, 100);
			int iKnife = GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
			EquipPlayerWeapon(LR_Player_Prisoner, iKnife);
			SetEntityHealth(LR_Player_Guard, 100);
			iKnife = GivePlayerItem(LR_Player_Guard, "weapon_knife");
			EquipPlayerWeapon(LR_Player_Guard, iKnife);
			CPrintToChatAll("%t", "LR No Winner");
		} else if (IsPlayerAlive(LR_Player_Prisoner)) 
		{
			SetEntityHealth(LR_Player_Prisoner, 100);
			int iKnife = GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
			EquipPlayerWeapon(LR_Player_Prisoner, iKnife);
			CPrintToChatAll("%t", "LR Winner", LR_Player_Prisoner);
		} else if (IsPlayerAlive(LR_Player_Guard)) 
		{
			SetEntityHealth(LR_Player_Guard, 100);
			int iKnife = GivePlayerItem(LR_Player_Guard, "weapon_knife");
			EquipPlayerWeapon(LR_Player_Guard, iKnife);
			CPrintToChatAll("%t", "LR Winner", LR_Player_Guard);
		}
	}
	
	LR_Player_Prisoner = -1;
	LR_Player_Guard = -1;

	IsThisLRInProgress = false;
}




public Action:GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(StrEqual(name, "hegrenade_detonate"))
	{
		if (IsThisLRInProgress && (client == LR_Player_Guard || client == LR_Player_Prisoner))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}
	
	return Plugin_Handled;
}
