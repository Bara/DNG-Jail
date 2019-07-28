// Alte Werte: 2.5 und 3.0
#define TIME_WEAPONTIMER 0.1
#define TIME_WEAPONUSETIMER 0.2

Handle g_hWeaponTimer[MAXPLAYERS + 1] =  { null, ... };
Handle g_hWeaponUseTimer[MAXPLAYERS + 1] =  { null, ... };

bool g_bWeaponUse[MAXPLAYERS + 1] =  { false, ... };

int g_iClip1 = -1;

void Spawnweapons_OnPluginStart()
{
	g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	if (g_iClip1 == -1)
	{
		SetFailState("Unable to find offset for clip.");
	}
}

void Spawnweapons_PlayerSpawn(int client)
{
	for(int offset = 0; offset < 128; offset += 4)
    {
        int weapon = GetEntDataEnt2(client, g_iMyWeapons + offset);

        if (IsValidEntity(weapon))
        {
            char sClass[32];
            GetEntityClassname(weapon, sClass, sizeof(sClass));

            if (StrContains(sClass, "knife", false) == -1 && StrContains(sClass, "bayonet", false) == -1 )
            {
                SafeRemoveWeapon(client, weapon);
            }
        }
    }
	
	g_bWeaponUse[client] = true;
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUseSpawn);
	
	g_hWeaponTimer[client] = CreateTimer(TIME_WEAPONTIMER, WeaponTimer, client);
	g_hWeaponUseTimer[client] = CreateTimer(TIME_WEAPONUSETIMER, WeaponUseTimer, client);
}

public Action WeaponTimer(Handle timer, any client)
{
	if(IsClientValid(client) && g_hWeaponTimer[client] != null && IsPlayerAlive(client))
	{
		int weapon = -1;
		if(!Dice_LoseAll(client) && GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == -1)
		{
			weapon = GivePlayerItem(client, "weapon_knife");
			EquipPlayerWeapon(client, weapon);
		}
		
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
			
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				weapon = -1;
				weapon = GivePlayerItem(client, "weapon_m4a1");
				EquipPlayerWeapon(client, weapon);
			}
			
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				weapon = -1;
				weapon = GivePlayerItem(client, "weapon_deagle");
				EquipPlayerWeapon(client, weapon);
			}

			weapon = GivePlayerItem(client, "weapon_taser");
			SetEntData(weapon, g_iClip1, 2);
		}
	}
	
	g_hWeaponTimer[client] = null;
	return Plugin_Stop;
}

public Action WeaponUseTimer(Handle timer, any client)
{
	if(IsClientValid(client) && g_hWeaponUseTimer[client] != null)
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUseSpawn);
		g_bWeaponUse[client] = false;
	}
	
	g_hWeaponUseTimer[client] = null;
	return Plugin_Stop;
}

public Action OnWeaponCanUseSpawn(int client, int weapon)
{
	if(g_bWeaponUse[client])
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
			
		if(StrContains(sWeapon, "taser", false) != -1)
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void ResetSpawnweapons(int client)
{
	g_bWeaponUse[client] = false;
	delete g_hWeaponTimer[client];
	delete g_hWeaponUseTimer[client];
}