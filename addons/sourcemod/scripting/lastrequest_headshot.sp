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

int g_iEntry = -1;
int g_iType = -1;
int g_iPrisoner = -1;
int g_iGuard = -1;

public Plugin myinfo = 
{
	name = "[Outbreak] LastRequest: HeadShot", 
	author = "Bara (Original author: xShakedDev)", 
	description = "Boom... Headshot!", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("hsmodelr.phrases");

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public int Menu_MainMenu(Menu menu, MenuAction action, int param1, int param2)
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
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void LR_AfterMenu(int weapon)
{
	SetEntityHealth(g_iPrisoner, 999);
	SetEntityHealth(g_iGuard, 999);
	RemoveAllWeapons(g_iPrisoner);
	RemoveAllWeapons(g_iGuard);
	CPrintToChat(g_iGuard, "%t", "PLAYER SELECT", g_iPrisoner);
	int iPWeapon;
	int iPGuard;
	char sWeapon[32];
	switch (weapon)
	{
		case 0:
		{
			iPWeapon = GivePlayerItem(g_iPrisoner, "weapon_awp");
			iPGuard = GivePlayerItem(g_iGuard, "weapon_awp");
			sWeapon = "AWP";
		}
		case 1:
		{
			iPWeapon = GivePlayerItem(g_iPrisoner, "weapon_deagle");
			iPGuard = GivePlayerItem(g_iGuard, "weapon_deagle");
			sWeapon = "DEAGLE";
		}
		case 2:
		{
			iPWeapon = GivePlayerItem(g_iPrisoner, "weapon_usp_silencer");
			iPGuard = GivePlayerItem(g_iGuard, "weapon_usp_silencer");
			sWeapon = "USP";
		}
		case 3:
		{
			iPWeapon = GivePlayerItem(g_iPrisoner, "weapon_ak47");
			iPGuard = GivePlayerItem(g_iGuard, "weapon_ak47");
			sWeapon = "AK-47";
		}
		case 4:
		{
			iPWeapon = GivePlayerItem(g_iPrisoner, "weapon_m4a1_silencer");
			iPGuard = GivePlayerItem(g_iGuard, "weapon_m4a1_silencer");
			sWeapon = "M4A1-S";
		}
	}

	EquipPlayerWeapon(g_iPrisoner, iPWeapon);
	EquipPlayerWeapon(g_iGuard, iPGuard);

	CPrintToChatAll("%t", "LR Started", sWeapon, g_iPrisoner, g_iGuard);

	SetEntProp(iPWeapon, Prop_Send, "m_iClip1", 250);
	SetEntProp(iPGuard, Prop_Send, "m_iClip1", 250);

	InitializeLR(g_iPrisoner);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int HitGroup)
{
	if ((attacker == g_iPrisoner || g_iGuard) || (victim == g_iPrisoner || g_iGuard))
	{
		if(damagetype & CS_DMG_HEADSHOT)
		{
			damage = float(GetClientHealth(victim) + GetClientArmor(victim));

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
		g_iEntry = AddLastRequestToList(LR_Start, LR_Stop, "HeadShot Mode", false);
		bAddedLR = true;
	}
}

public void OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, "HeadShot Mode");
}

public int LR_Start(Handle LR_Array, int iIndexInArray)
{
	g_iType = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType)); // get this lr from selection
	if (g_iType == g_iEntry)
	{
		g_iPrisoner = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Prisoner)); // get prisoner's id
		g_iGuard = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Guard)); // get guard's id
		
		
		SDKHook(g_iPrisoner, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		SDKHook(g_iGuard, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		
		int LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Global1));
		switch (LR_Pack_Value)
		{
			case  - 1:
			{
				PrintToServer("no info included");
			}
		}
		
		Menu menu = new Menu(Menu_MainMenu);
		menu.SetTitle("HeadShot Mode");
		menu.AddItem("M1", "AWP");
		menu.AddItem("M2", "Desert Eagle");
		menu.AddItem("M3", "USP");
		menu.AddItem("M4", "AK-47");
		menu.AddItem("M5", "M4A1-S");
		menu.ExitButton = false;
		menu.Display(g_iPrisoner, 0);
	}
}

public int LR_Stop(int Type, int Prisoner, int Guard)
{
	SDKUnhook(g_iPrisoner, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKUnhook(g_iGuard, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	
	if (IsClientInGame(Prisoner))
	{
		if (IsPlayerAlive(Prisoner))
		{
			SetEntityGravity(Prisoner, 1.0);
			SetEntityHealth(Prisoner, 100);
			RemoveAllWeapons(Prisoner);
			int iKnife = GivePlayerItem(Prisoner, "weapon_knife");

			if (IsValidEntity(iKnife))
			{
				EquipPlayerWeapon(Prisoner, iKnife);
			}
		}
	}
	if (IsClientInGame(Guard))
	{
		if (IsPlayerAlive(Guard))
		{
			SetEntityGravity(Guard, 1.0);
			SetEntityHealth(Guard, 100);
			RemoveAllWeapons(Guard);
			int iWeapon = GivePlayerItem(Guard, "weapon_knife");

			if (IsValidEntity(iWeapon))
			{
				EquipPlayerWeapon(Guard, iWeapon);
			}
			
			iWeapon = GivePlayerItem(Guard, "weapon_ak47");

			if (IsValidEntity(iWeapon))
			{
				EquipPlayerWeapon(Guard, iWeapon);
			}
		}
	}
}
