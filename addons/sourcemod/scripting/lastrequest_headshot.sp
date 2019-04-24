#include <sourcemod>
#include <sdktools>
#include <hosties>
#include <cstrike>
#include <lastrequest>
#include <sdkhooks>
#include <dng-jail>

#pragma newdecls required

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"

int g_LREntryNum;
int This_LR_Type;
int LR_Player_Prisoner;
int LR_Player_Guard;
Handle HSMenu;

public Plugin myinfo = 
{
	name = "[Outbreak] LastRequest: HeadShot", 
	author = "Bara (xShakedDev)", 
	description = "Boom... Headshot!", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("hsmodelr.phrases");
	HSMenu = CreateMenu(HSMenuHandler);
	SetMenuTitle(HSMenu, "HeadShot Mode");
	AddMenuItem(HSMenu, "M1", "AWP");
	AddMenuItem(HSMenu, "M2", "Desert Eagle");
	AddMenuItem(HSMenu, "M3", "USP");
	AddMenuItem(HSMenu, "M4", "AK-47");
	AddMenuItem(HSMenu, "M5", "M4A1-S");
	SetMenuExitButton(HSMenu, false);

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public int HSMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0) // AWP
		{
			LR_AfterMenu(0);
		}
		if (param2 == 1) // DGL
		{
			LR_AfterMenu(1);
		}
		if (param2 == 2) // USP
		{
			LR_AfterMenu(2);
		}
		if (param2 == 3) // AK-47
		{
			LR_AfterMenu(3);
		}
		if (param2 == 4) // M4A1
		{
			LR_AfterMenu(4);
		}
	}
}

public void LR_AfterMenu(int weapon)
{
	SetEntityHealth(LR_Player_Prisoner, 999);
	SetEntityHealth(LR_Player_Guard, 999);
	StripAllWeapons(LR_Player_Prisoner);
	StripAllWeapons(LR_Player_Guard);
	CPrintToChat(LR_Player_Guard, "%t", "PLAYER SELECT", LR_Player_Prisoner);
	int wep1;
	int wep2;
	char wpnname[32];
	switch (weapon)
	{
		case 0:
		{
			wep1 = GivePlayerItem(LR_Player_Prisoner, "weapon_awp");
			wep2 = GivePlayerItem(LR_Player_Guard, "weapon_awp");
			wpnname = "AWP";
			CPrintToChatAll("%t", "LR Started", wpnname, LR_Player_Prisoner, LR_Player_Guard);
		}
		case 1:
		{
			wep1 = GivePlayerItem(LR_Player_Prisoner, "weapon_deagle");
			wep2 = GivePlayerItem(LR_Player_Guard, "weapon_deagle");
			
			wpnname = "DEAGLE";
			CPrintToChatAll("%t", "LR Started", wpnname, LR_Player_Prisoner, LR_Player_Guard);
		}
		case 2:
		{
			wep1 = GivePlayerItem(LR_Player_Prisoner, "weapon_usp_silencer");
			wep2 = GivePlayerItem(LR_Player_Guard, "weapon_usp_silencer");
			
			wpnname = "USP";
			CPrintToChatAll("%t", "LR Started", wpnname, LR_Player_Prisoner, LR_Player_Guard);
		}
		case 3:
		{
			wep1 = GivePlayerItem(LR_Player_Prisoner, "weapon_ak47");
			wep2 = GivePlayerItem(LR_Player_Guard, "weapon_ak47");
			
			wpnname = "AK-47";
			CPrintToChatAll("%t", "LR Started", wpnname, LR_Player_Prisoner, LR_Player_Guard);
		}
		case 4:
		{
			wep1 = GivePlayerItem(LR_Player_Prisoner, "weapon_m4a1_silencer");
			wep2 = GivePlayerItem(LR_Player_Guard, "weapon_m4a1_silencer");
			
			wpnname = "M4A1-S";
			CPrintToChatAll("%t", "LR Started", wpnname, LR_Player_Prisoner, LR_Player_Guard);
		}
	}
	SetEntProp(wep1, Prop_Send, "m_iClip1", 250);
	SetEntProp(wep2, Prop_Send, "m_iClip1", 250);
	InitializeLR(LR_Player_Prisoner);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int HitGroup)
{
	if ((attacker == LR_Player_Prisoner || LR_Player_Guard) || (victim == LR_Player_Prisoner || LR_Player_Guard))
	{
		if(damagetype & CS_DMG_HEADSHOT)
		{
			damage = float(GetClientHealth(victim));
			CPrintToChatAll("%t", "LR WIN", attacker, victim);
			return Plugin_Changed;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	static bool bAddedLR = false;
	if (!bAddedLR)
	{
		g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, "HeadShot Mode", false);
		bAddedLR = true;
	}
}

public void OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, "HeadShot Mode");
}

public int LR_Start(Handle LR_Array, int iIndexInArray)
{
	This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType)); // get this lr from selection
	if (This_LR_Type == g_LREntryNum)
	{
		LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Prisoner)); // get prisoner's id
		LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Guard)); // get guard's id
		
		
		SDKHook(LR_Player_Prisoner, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		SDKHook(LR_Player_Guard, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		
		int LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Global1));
		switch (LR_Pack_Value)
		{
			case  - 1:
			{
				PrintToServer("no info included");
			}
		}
		
		DisplayMenu(HSMenu, LR_Player_Prisoner, 0);
	}
}

public int LR_Stop(int Type, int Prisoner, int Guard)
{
	SDKUnhook(LR_Player_Prisoner, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKUnhook(LR_Player_Guard, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	
	if (IsClientInGame(Prisoner))
	{
		if (IsPlayerAlive(Prisoner))
		{
			SetEntityGravity(Prisoner, 1.0);
			SetEntityHealth(Prisoner, 100);
			StripAllWeapons(Prisoner);
			GivePlayerItem(Prisoner, "weapon_knife");
		}
	}
	if (IsClientInGame(Guard))
	{
		if (IsPlayerAlive(Guard))
		{
			SetEntityGravity(Guard, 1.0);
			SetEntityHealth(Guard, 100);
			StripAllWeapons(Guard);
			GivePlayerItem(Guard, "weapon_knife");
			GivePlayerItem(Guard, "weapon_ak47");
		}
	}
}
