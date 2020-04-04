
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <menus>
#include <hosties>
// #include <smlib>
#include <multicolors>
#include <lastrequest>
#include <dng-jail>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

new g_LREntryNum;
new g_This_LR_Type;
new g_LR_Player_Prisoner;
new g_LR_Player_Guard;

new TWep;
new CTWep;

new String:g_sLR_Name[64];

// menu handler
new Handle:hMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Last Request: Hp Fight",
	author = "EGood & Bara",
	description = "hp and speed fights",
	version = PLUGIN_VERSION,
	url = "http://www.GameX.co.il"
};

public OnPluginStart()
{
	// Load translations
	LoadTranslations("lastrequest_hpfight.phrases");
	
	// Name of the LR
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "HP Fight", LANG_SERVER);	
	
	// menu
	
	hMenu = CreateMenu(MenuHandler);
	SetMenuTitle(hMenu, "HP Fight");
	AddMenuItem(hMenu, "M1", "M4A1 Fight");
	AddMenuItem(hMenu, "M2", "AK47 Fight");
	AddMenuItem(hMenu, "M3", "SG556 Fight");
	AddMenuItem(hMenu, "M4", "AUG Fight");
	AddMenuItem(hMenu, "M5", "FAMAS Fight");
	AddMenuItem(hMenu, "M6", "Galil Fight");
	AddMenuItem(hMenu, "M7", "M249 Fight");
	AddMenuItem(hMenu, "M8", "Negev Fight");
	AddMenuItem(hMenu, "M9", "Bizon Fight");
	AddMenuItem(hMenu, "M10", "P90 Fight");
	AddMenuItem(hMenu, "M11", "Mp9 Fight");
	AddMenuItem(hMenu, "M12", "Mp7 Fight");
	AddMenuItem(hMenu, "M13", "Mac10 Fight");
	AddMenuItem(hMenu, "M14", "UMP45 Fight");
	AddMenuItem(hMenu, "M15", "Scout Fight");
	AddMenuItem(hMenu, "M16", "AWP Fight");
	AddMenuItem(hMenu, "M17", "SCAR20 Fight");
	AddMenuItem(hMenu, "M18", "G3SG1 Fight");
	AddMenuItem(hMenu, "M19", "Glock Fight");
	AddMenuItem(hMenu, "M20", "Dualies Fight");
	AddMenuItem(hMenu, "M21", "Deagle Fight");
	AddMenuItem(hMenu, "M22", "Tec9 Fight");
	AddMenuItem(hMenu, "M23", "Fiveseven Fight");
	AddMenuItem(hMenu, "M24", "P250 Fight");
	AddMenuItem(hMenu, "M25", "P2000 Fight");
	AddMenuItem(hMenu, "M26", "Mag7 Fight");
	AddMenuItem(hMenu, "M27", "Nova Fight");
	AddMenuItem(hMenu, "M28", "Sawed-Off Fight");
	AddMenuItem(hMenu, "M29", "XM1014 Fight");
	SetMenuExitButton(hMenu, true);

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public OnConfigsExecuted()
{
	static bool:bAddedLRHPFight = false;
	if (!bAddedLRHPFight)
	{
		g_LREntryNum = AddLastRequestToList(LR_Start, LR_Stop, g_sLR_Name, false);
		bAddedLRHPFight = true;
	}   
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 0) // M4A1
		{
			LR_AfterMenu(0);
		}
		if(param2 == 1) // Ak47
		{
			LR_AfterMenu(1);
		}
		if(param2 == 2) // SG556
		{
			LR_AfterMenu(2);
		}
		if(param2 == 3) // AUG
		{
			LR_AfterMenu(3);
		}
		if(param2 == 4) // FAMAS
		{
			LR_AfterMenu(4);
		}
		if(param2 == 5) // Galil
		{
			LR_AfterMenu(5);
		}
		if(param2 == 6) // M249
		{
			LR_AfterMenu(6);
		}
		if(param2 == 7) // Negev
		{
			LR_AfterMenu(7);
		}
		if(param2 == 8) // Bizon
		{
			LR_AfterMenu(8);
		}
		if(param2 == 9) // P90
		{
			LR_AfterMenu(9);
		}
		if(param2 == 10) // Mp9
		{
			LR_AfterMenu(10);
		}
		if(param2 == 11) // Mp7
		{
			LR_AfterMenu(11);
		}
		if(param2 == 12) // Mac10
		{
			LR_AfterMenu(12);
		}
		if(param2 == 13) // UMP45
		{
			LR_AfterMenu(13);
		}
		if(param2 == 14) // Scout
		{
			LR_AfterMenu(14);
		}
		if(param2 == 15) // AWP
		{
			LR_AfterMenu(15);
		}
		if(param2 == 16) // SCAR20
		{
			LR_AfterMenu(16);
		}
		if(param2 == 17) // G3SG1
		{
			LR_AfterMenu(17);
		}
		if(param2 == 18) // Glock
		{
			LR_AfterMenu(18);
		}
		if(param2 == 19) // Dualies
		{
			LR_AfterMenu(19);
		}
		if(param2 == 20) // Deagle
		{
			LR_AfterMenu(20);
		}
		if(param2 == 21) // Tec9
		{
			LR_AfterMenu(21);
		}
		if(param2 == 22) // Fiveseven
		{
			LR_AfterMenu(22);
		}
		if(param2 == 23) // P250
		{
			LR_AfterMenu(23);
		}
		if(param2 == 24) // P2000
		{
			LR_AfterMenu(24);
		}
		if(param2 == 25) // Mag7
		{
			LR_AfterMenu(25);
		}
		if(param2 == 26) // Nova
		{
			LR_AfterMenu(26);
		}
		if(param2 == 27) // Sawed-Off
		{
			LR_AfterMenu(27);
		}
		if(param2 == 28) // XM1014
		{
			LR_AfterMenu(28);
		}
	}
}

public OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, g_sLR_Name);
}

public LR_Start(Handle:LR_Array, iIndexInArray)
{
	g_This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (g_This_LR_Type == g_LREntryNum)
	{
		g_LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		g_LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);
		
		new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);   
		switch (LR_Pack_Value)
		{
			case -1:
			{
				PrintToServer("no info included");
			}
		}
		DisplayMenu(hMenu, g_LR_Player_Prisoner, MENU_TIME_FOREVER);
		CPrintToChatAll("{default}Get ready! Do NOT reload or you will lose infinite ammo!");
	}
}


public LR_Stop(Type, Prisoner, Guard)
{
	if (Type == g_LREntryNum)
	{
		if (IsClientInGame(Prisoner))
		{
			if (IsPlayerAlive(Prisoner))
			{
				SetEntityGravity(Prisoner, 1.0);
				SetEntityHealth(Prisoner, 100);
				StripAllWeapons(Prisoner);
				int iKnife = GivePlayerItem(Prisoner, "weapon_knife");
				EquipPlayerWeapon(Prisoner, iKnife);
				CPrintToChatAll("{default}Winner: %N!", g_LR_Player_Prisoner);
			}
		}
		if (IsClientInGame(Guard))
		{
			if (IsPlayerAlive(Guard))
			{
				SetEntityGravity(Guard, 1.0);
				SetEntityHealth(Guard, 100);
				StripAllWeapons(Guard);
				int iKnife = GivePlayerItem(Guard, "weapon_knife");
				EquipPlayerWeapon(Guard, iKnife);
				CPrintToChatAll("{default}Winner: %N!", g_LR_Player_Guard);
			}
		}
		SetEntPropFloat(g_LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntPropFloat(g_LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

public LR_AfterMenu(weapon)
{
	StripAllWeapons(g_LR_Player_Prisoner);
	StripAllWeapons(g_LR_Player_Guard);
	
	SetEntityHealth(g_LR_Player_Prisoner, 750);
	SetEntityHealth(g_LR_Player_Guard, 750);
	
	switch(weapon)
	{
		case 0:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m4a1");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_m4a1");
			
			CPrintToChatAll("{default}M4A1 Fight has started!");
		}
		case 1:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ak47");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ak47");
			
			CPrintToChatAll("{default}AK47 Fight has started!");
		}
		case 2:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_sg556");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_sg556");
			
			CPrintToChatAll("{default}SG556 Fight has started!");
		}
		case 3:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_aug");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_aug");
			
			CPrintToChatAll("{default}AUG Fight has started!");
		}
		case 4:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_famas");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_famas");
			
			CPrintToChatAll("{default}FAMAS Fight has started!");
		}
		case 5:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_galilar");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_galilar");
			
			CPrintToChatAll("{default}Galil Fight has started!");
		}
		case 6:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_m249");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_m249");
			
			CPrintToChatAll("{default}M249 Fight has started!");
		}
		case 7:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_negev");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_negev");
			
			CPrintToChatAll("{default}Negev Fight has started!");
		}
		case 8:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_bizon");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_bizon");
			
			CPrintToChatAll("{default}Bizon Fight has started!");
		}
		case 9:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p90");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_p90");
			
			CPrintToChatAll("{default}P90 Fight has started!");
		}
		case 10:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mp9");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mp9");
			
			CPrintToChatAll("{default}Mp9 Fight has started!");
		}
		case 11:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mp7");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mp7");
			
			CPrintToChatAll("{default}Mp7 Fight has started!");
		}
		case 12:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mac10");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mac10");
			
			CPrintToChatAll("{default}Mac10 Fight has started!");
		}
		case 13:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ump45");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ump45");
			
			CPrintToChatAll("{default}UMP45 Fight has started!");
		}
		case 14:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_ssg08");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_ssg08");
			
			CPrintToChatAll("{default}Scout Fight has started!");
		}
		case 15:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_awp");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_awp");
			
			CPrintToChatAll("{default}AWP Fight has started!");
		}
		case 16:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_scar20");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_scar20");
			
			CPrintToChatAll("{default}SCAR20 Fight has started!");
		}
		case 17:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_g3sg1");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_g3sg1");
			
			CPrintToChatAll("{default}G3SG1 Fight has started!");
		}
		case 18:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_glock");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_glock");
			
			CPrintToChatAll("{default}Glock Fight has started!");
		}
		case 19:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_elite");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_elite");
			
			CPrintToChatAll("{default}Dualies Fight has started!");
		}
		case 20:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_deagle");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_deagle");
			
			CPrintToChatAll("{default}Deagle Fight has started!");
		}
		case 21:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_tec9");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_tec9");
			
			CPrintToChatAll("{default}Tec9 Fight has started!");
		}
		case 22:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_fiveseven");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_fiveseven");
			
			CPrintToChatAll("{default}Fiveseven Fight has started!");
		}
		case 23:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p250");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_p250");
			
			CPrintToChatAll("{default}P250 Fight has started!");
		}
		case 24:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_hkp2000");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_hkp2000");
			
			CPrintToChatAll("{default}P2000 Fight has started!");
		}
		case 25:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_mag7");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_mag7");
			
			CPrintToChatAll("{default}Mag7 Fight has started!");
		}
		case 26:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_nova");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_nova");
			
			CPrintToChatAll("{default}Nova Fight has started!");
		}
		case 27:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_sawedoff");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_sawedoff");
			
			CPrintToChatAll("{default}Sawed-Off Fight has started!");
		}
		case 28:
		{
			TWep = GivePlayerItem(g_LR_Player_Prisoner, "weapon_xm1014");
			CTWep = GivePlayerItem(g_LR_Player_Guard, "weapon_xm1014");
			
			CPrintToChatAll("{default}XM1014 Fight has started!");
		}
	}

	CreateTimer(0.1, Timer_Update);
	InitializeLR(g_LR_Player_Prisoner);

	if (IsValidEntity(TWep))
	{
		EquipPlayerWeapon(g_LR_Player_Prisoner, TWep);
	}
	if (IsValidEntity(CTWep))
	{
		EquipPlayerWeapon(g_LR_Player_Guard, CTWep);
	}
}

public Action:Timer_Update(Handle:timer)
{
	SetEntData(TWep, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
	SetEntData(CTWep, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 999);
	
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	SetEntData(g_LR_Player_Prisoner, ammoOffset+(1*4), 0);
	SetEntData(g_LR_Player_Guard, ammoOffset+(1*4), 0);
	
	SetEntityGravity(g_LR_Player_Prisoner, 0.8);
	SetEntityGravity(g_LR_Player_Guard, 0.8);
	
	SetEntPropFloat(g_LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 1.8);
	SetEntPropFloat(g_LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 1.8);
}