#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define TEXT "{default}"
#define SPECIAL "{lightgreen}"

bool g_bBlockCommand;
bool g_bRedie[MAXPLAYERS+1] = { false, ... };
bool g_bNoclipBlock[MAXPLAYERS+1] = { false, ... };

Handle g_hNoclip[MAXPLAYERS+1] = { null, ... };
Handle g_hNoclipReset[MAXPLAYERS+1] = { null, ... };


public Plugin myinfo =
{
	name = "Redie",
	author = "Bara",
	description = "",
	version = "1.0",
	url = "github.com/Bara"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetRedieStatus", Native_GetRedieStatus);
	
	RegPluginLibrary("redie");
	
	return APLRes_Success;
}

public int Native_GetRedieStatus(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	return g_bRedie[client];
}

public void OnPluginStart()
{
	RegAdminCmd("sm_redie", Command_redie, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_reback", Command_reback, ADMFLAG_CUSTOM4);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_team", PlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Pre);
	
	AddNormalSoundHook(view_as<NormalSHook>(OnNormalSoundPlayed));
	
	LoopClients(i)
	{
		SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
		SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
	}

	CSetPrefix("{darkblue}[Redie]{default}");
}

public void OnClientPutInServer(int client)
{
	if (IsClientValid(client))
	{
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
		SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	}
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(g_bRedie[client])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(g_bRedie[victim])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Command_redie(int client, int args)
{
	if(IsClientValid(client))
	{
		if(!IsPlayerAlive(client))
		{
			if(GetClientTeam(client) > CS_TEAM_SPECTATOR)
			{
				if(!g_bBlockCommand)
				{
					g_bRedie[client] = true;
					
					SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
					SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
					
					CS_RespawnPlayer(client);
					
					for(int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
					{
						int index = -1;
						
						while((index = GetPlayerWeaponSlot(client, i)) != -1)
						{
							SafeRemoveWeapon(client, index);
						}
					}

					SetEntProp(client, Prop_Send, "m_lifeState", 1);
		
					g_bRedie[client] = true;
		
					SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
					SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
					
					LoopClients(i)
					{
						SetListenOverride(client, i, Listen_Yes);
						
						if(IsPlayerAlive(i))
							SetListenOverride(i, client, Listen_No);
						else
							SetListenOverride(i, client, Listen_Yes);
					}
		
					CPrintToChat(client, "Du bist nun ein Geist.");
				}
				else
				{
					CPrintToChat(client, "Du musst bis zur nächsten Runde warten.");
				}
			}
			else
			{
				CPrintToChat(client, "Du musst in einem Team sein, um %s!redie %snutzen zu können.", SPECIAL, TEXT);
			}
		}
		else
		{
			CPrintToChat(client, "Du musst tot sein, um %s!redie %snutzen zu können.", SPECIAL, TEXT);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_reback(int client, int args)
{
	if(IsClientValid(client))
	{
		if(g_bRedie[client])
		{
			int iTeam = GetClientTeam(client);
			
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			ChangeClientTeam(client, iTeam);
			
			LoopClients(i)
			{
				SetListenOverride(client, i, Listen_Default);
				SetListenOverride(i, client, Listen_Default);
			}
			
			ResetRedie(client);
		}
		else
		{
			CPrintToChat(client, "Du musst im %s!redie %ssein, um %s!reback %snutzen zu können.", SPECIAL, TEXT, SPECIAL, TEXT);
		}
	}
	
	return Plugin_Handled;
}


// Events

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bBlockCommand = false;
	
	LoopClients(client)
	{
		ResetRedie(client);
		
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	}
	
	int ent = MaxClients + 1;
	
	SDKUnhook(ent, SDKHook_EndTouch, BlockTouch);
	SDKUnhook(ent, SDKHook_StartTouch, BlockTouch);
	SDKUnhook(ent, SDKHook_Touch, BlockTouch);
	
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1)
	{
		SDKHook(ent, SDKHook_EndTouch, BlockTouch);
		SDKHook(ent, SDKHook_StartTouch, BlockTouch);
		SDKHook(ent, SDKHook_Touch, BlockTouch);
	}
	
	while((ent = FindEntityByClassname(ent, "func_door")) != -1)
	{
		SDKHook(ent, SDKHook_EndTouch, BlockTouch);
		SDKHook(ent, SDKHook_StartTouch, BlockTouch);
		SDKHook(ent, SDKHook_Touch, BlockTouch);
	}
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bBlockCommand = true;

	LoopClients(i)
	{
		ResetRedie(i);
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		if(CheckCommandAccess(client, "sm_redie", ADMFLAG_CUSTOM4))
		{
			CPrintToChat(client, "Gib %s!redie %sein, um als Geist weiterzuspielen.", SPECIAL, TEXT);
		}
	}
}

public Action PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
	return Plugin_Changed;
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client) && g_bRedie[client])
	{
		ResetRedie(client);
		CreateTimer(0.5, Timer_FixSolids, GetClientUserId(client));
	}
}

public Action Timer_FixSolids(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (IsClientValid(client))
	{
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(client, Prop_Data, "m_nSolidType", 0);
		SetEntProp(client, Prop_Send, "m_usSolidFlags", 4);

		CPrintToChat(client, "m_CollisionGroup: %d", GetEntProp(client, Prop_Data, "m_CollisionGroup"));
		CPrintToChat(client, "m_nSolidType: %d", GetEntProp(client, Prop_Data, "m_nSolidType"));
		CPrintToChat(client, "m_usSolidFlags: %d", GetEntProp(client, Prop_Send, "m_usSolidFlags"));
	}
}

// Timer

public Action NoclipTimer(Handle timer, any client)
{
	if(IsClientValid(client) && g_bRedie[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		g_hNoclipReset[client] = CreateTimer(5.0, NoclipReset, client);
	}
	
	g_hNoclip[client] = null;
}

public Action NoclipReset(Handle timer, any client)
{
	if(IsClientValid(client) && g_bRedie[client])
	{
		g_bNoclipBlock[client] = false;
	}
	
	g_hNoclipReset[client] = null;
}

public Action BlockTouch(int entity, int other)
{
	if(IsClientValid(other) && g_bRedie[other])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnNormalSoundPlayed(int[] clients, int &numClients, char[] sample, int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char[] soundEntry, int &seed)
{
	if(IsClientValid(entity) && g_bRedie[entity])
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_bRedie[client])
	{
		buttons &= ~IN_USE;
		
		if(buttons & IN_RELOAD)
		{
			if(!g_bNoclipBlock[client])
			{
				g_bNoclipBlock[client] = true;
				
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				g_hNoclip[client] = CreateTimer(1.0, NoclipTimer, client);
				
				CPrintToChat(client, "Du hast für %s1 Sekunde %sNoclip.", SPECIAL, TEXT);
			}
		}
	}
}

void ResetRedie(int client)
{
	g_bRedie[client] = false;
	g_bNoclipBlock[client] = false;
	
	LoopClients(i)
	{
		SetListenOverride(client, i, Listen_Default);
		SetListenOverride(i, client, Listen_Default);
	}

	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	
	delete g_hNoclip[client];
	delete g_hNoclipReset[client];
}

public void OnClientDisconnect(int client)
{
	ResetRedie(client);
}

stock bool IsClientValid(int client, bool bots = false)
{
    if (client > 0 && client <= MaxClients)
    {
        if(IsClientInGame(client) && (bots || !IsFakeClient(client)) && !IsClientSourceTV(client))
        {
            return true;
        }
    }
    
    return false;
}

stock bool SafeRemoveWeapon(int iClient, int iWeapon)
{
    if (!IsValidEntity(iWeapon) || !IsValidEdict(iWeapon))
        return false;
    
    if (!HasEntProp(iWeapon, Prop_Send, "m_hOwnerEntity"))
        return false;
    
    int iOwnerEntity = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
    
    if (iOwnerEntity != iClient)
        SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iClient);
    
    CS_DropWeapon(iClient, iWeapon, false);
    
    if (HasEntProp(iWeapon, Prop_Send, "m_hWeaponWorldModel"))
    {
        int iWorldModel = GetEntPropEnt(iWeapon, Prop_Send, "m_hWeaponWorldModel");
        
        if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
            if (!AcceptEntityInput(iWorldModel, "Kill"))
                return false;
    }
    
    if (!AcceptEntityInput(iWeapon, "Kill"))
        return false;
    
    return true;
}
