#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <hosties>
#include <lastrequest>
#include <multicolors>
#include <dng-jail>

#define BS_VERSION "1.0.0"

new g_LREntryNum;
new LR_Player_Prisoner = -1;
new LR_Player_Guard = -1;

public Plugin:myinfo =
{
	name = "Last Request: Backstabs",
	author = "Bara (Original authors: Jason Bourne and Kolapsicle)",
	description = "Win the LR by backstabbing your opponent.",
	version = BS_VERSION,
	url = "github.com/Bara"
};

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
		
		RemoveAllWeapons(LR_Player_Prisoner);
		RemoveAllWeapons(LR_Player_Guard);
		
		int iKnife = -1;
		iKnife = GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
		EquipPlayerWeapon(LR_Player_Prisoner, iKnife);
		
		iKnife = -1;
		iKnife = GivePlayerItem(LR_Player_Guard, "weapon_knife");
		EquipPlayerWeapon(LR_Player_Guard, iKnife);
		
		CPrintToChatAll("%N spielt gegen %N Backstab Knife", LR_Player_Prisoner, LR_Player_Guard);
		CPrintToChatAll("Versuche deinen Gegner im Rücken zu messern!");

		SDKHook(LR_Player_Prisoner, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(LR_Player_Guard, SDKHook_OnTakeDamage, OnTakeDamage);
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

		SDKUnhook(LR_Player_Prisoner, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(LR_Player_Guard, SDKHook_OnTakeDamage, OnTakeDamage);

		LR_Player_Prisoner = -1;
		LR_Player_Guard = -1;
	}
}


public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsClientValid(attacker) || !IsClientValid(victim))
		return Plugin_Continue;
	
	if (LR_Player_Prisoner != -1 && LR_Player_Guard != -1)
	{
		char wname[64];
		GetEdictClassname(weapon, wname, sizeof(wname));
		
		if(IsClientInGame(victim) && IsClientInGame(attacker))
		{
			if(IsClientInLastRequest(victim) && IsClientInLastRequest(attacker))
			{
				if (damage < 70)
				{
					damage = 0.0;
					return Plugin_Changed;
				}

				if((StrContains(wname, "knife", false) == -1 || StrContains(wname, "bayonet", false) == -1) && damage > 110)
				{
					damage = float(GetClientHealth(victim) + GetClientArmor(victim));
					return Plugin_Changed;
				}
			}
			else
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}