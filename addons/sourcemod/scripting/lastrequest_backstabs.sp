#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <hosties>
#include <lastrequest>
#include <multicolors>
#include <dng-jail>

#define BS_VERSION "1.0.3"
#define COLLISION_NOBLOCK 2
#define COLLISION_BLOCK 5

new g_LREntryNum;
new LR_Player_Prisoner = -1;
new LR_Player_Guard = -1;

new g_iHealth;

public Plugin:myinfo =
{
	name = "Last Request: Backstabs",
	author = "Jason Bourne & Kolapsicle",
	description = "Win the LR by backstabbing your opponent.",
	version = BS_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=243262"
};


public OnPluginStart()
{
	g_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");

	if (g_iHealth == -1)
	{
		SetFailState("Error - Unable to get offset for CSSPlayer::m_iHealth");
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public void OnClientPutInServer(int i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnConfigsExecuted()
{
	static bool:bAddedCustomLR = false;
	if ( ! bAddedCustomLR)
	{
		g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, "Backstab Knife");
		bAddedCustomLR = true;
	}
}


public OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, "Backstab Knife");
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
		
		SetEntityHealth(LR_Player_Prisoner, 100);
		SetEntityHealth(LR_Player_Guard, 100);
		
		StripAllWeapons(LR_Player_Prisoner);
		StripAllWeapons(LR_Player_Guard);
		
		int iKnife = -1;
		iKnife = GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
		EquipPlayerWeapon(LR_Player_Prisoner, iKnife);
		
		iKnife = -1;
		iKnife = GivePlayerItem(LR_Player_Guard, "weapon_knife");
		EquipPlayerWeapon(LR_Player_Guard, iKnife);
		
		CPrintToChatAll("%N spielt gegen %N Backstab Knife", LR_Player_Prisoner, LR_Player_Guard);
		CPrintToChatAll("Versuche deinen Gegner im Rücken zu messern!");
	}
}


public LR_Stop(This_LR_Type, Player_Prisoner, Player_Guard)
{
	if (This_LR_Type == g_LREntryNum && LR_Player_Prisoner != -1)
	{
		if (IsClientInGame(LR_Player_Prisoner))
		{
			if (IsPlayerAlive(LR_Player_Prisoner))
			{
				SetEntityHealth(LR_Player_Prisoner, 100);
				CPrintToChatAll("%N hat Backstab Knife gegen %N gewonnen!", LR_Player_Prisoner, LR_Player_Guard);
			}
		}

		if (IsClientInGame(LR_Player_Guard))
		{
			if (IsPlayerAlive(LR_Player_Guard))
			{
				SetEntityHealth(LR_Player_Guard, 100);
				CPrintToChatAll("%N hat Backstab Knife gegen %N gewonnen!", LR_Player_Guard, LR_Player_Prisoner);
			}
		}

		LR_Player_Prisoner = -1;
		LR_Player_Guard = -1;
	}
}


public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsClientValid(attacker) || !IsClientValid(victim))
		return Plugin_Continue;
	
	if (LR_Player_Prisoner != -1)
	{
		char wname[64];
		GetEdictClassname(weapon, wname, sizeof(wname));
		
		if(IsClientInGame(victim) && IsClientInGame(attacker))
		{
			if(IsClientInLastRequest(victim))
			{
				if((StrContains(wname, "knife", false) == -1 || StrContains(wname, "bayonet", false) == -1) || (attacker != LR_Player_Prisoner && attacker != LR_Player_Guard) || (damage < 130))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
			else if(!IsClientInLastRequest(victim) && IsClientInLastRequest(attacker))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}