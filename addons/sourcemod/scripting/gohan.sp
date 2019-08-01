#pragma semicolon 1

#define PLUGIN_AUTHOR "Bara & Rachnus"
#define PLUGIN_VERSION "1.06"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dng-jail>
#include <emitsoundany>

#pragma newdecls required
#define BEAM_REFRESH_RATE 0.1
#define BEAM_SOUND "superheromod/beamhead.mp3"
#define HA_SOUND "superheromod/gohan_ha.mp3"
#define KAMEHAME_SOUND "superheromod/gohan_kamehame.mp3"
#define BEAM_HEAD "materials/superheromod/kamehamehahead.vmt"
#define BEAM_EXPLOSION "materials/superheromod/kamehamehaexplosion.vmt"
#define BEAM_TRAIL "materials/effects/blueblacklargebeam.vmt"
EngineVersion g_Game;

ConVar g_SSJGohanDamageMultiplier;
ConVar g_SSJGohanRadiusMultiplier;
ConVar g_SSJGohanCooldown;
ConVar g_SSJGohanBeamSpeed;
ConVar g_SSJGohanMinChargeTime;
ConVar g_SSJGohanMaxChargeTime;
ConVar g_SSJGohanParentPlayerWithBeam;

float g_fChargeTime[MAXPLAYERS + 1];
float g_fChargeAmount[MAXPLAYERS + 1];
float g_vecEndPos[MAXPLAYERS + 1][3];
int g_iTrail;
int g_iFreeze = -1;
int g_iExplosion;
int g_iBeam[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iBeamHead[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
bool g_bFiringBeam[MAXPLAYERS + 1];
bool g_bCharging[MAXPLAYERS + 1];
Handle g_hTimerCharge[MAXPLAYERS + 1] = { null, ... };
Handle g_hHudCharge;
bool g_bCooldown[MAXPLAYERS + 1] =  { false, ... };
int g_iLastButtons[MAXPLAYERS + 1] =  { -1, ... };
bool g_bHasKame[MAXPLAYERS + 1] =  { false, ... };

public Plugin myinfo = 
{
	name = "[Outbreak] Gohan",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://github.com/Bara20"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SetGohanMode", Native_SetGohanMode);
	
	RegPluginLibrary("gohan");
	
	return APLRes_Success;
}

public int Native_SetGohanMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool status = view_as<bool>(GetNativeCell(2));
	
	g_bHasKame[client] = status;
}

public void OnPluginStart()
{
	LoadTranslations("ssjgohan.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	g_SSJGohanDamageMultiplier = CreateConVar("gohan_damage_multiplier", "50", "Amount of times charge time damage (If charged 2 seconds, then damage will be 2 * this convar)");
	g_SSJGohanRadiusMultiplier = CreateConVar("gohan_explosion_radius_multiplier", "90", "Amount of radius of the kamehameha wave (Charge time * this convar value)");
	g_SSJGohanCooldown = CreateConVar("gohan_cooldown", "60", "Seconds until next available kamehameha", FCVAR_NOTIFY);
	g_SSJGohanBeamSpeed = CreateConVar("gohan_speed", "1500", "Speed of the kamehameha");
	g_SSJGohanMinChargeTime = CreateConVar("gohan_min_charge_time", "2", "Min amount of time in seconds you can charge the kamehameha");
	g_SSJGohanMaxChargeTime = CreateConVar("gohan_max_charge_time", "8", "Max amount of time in seconds you can charge the kamehameha");
	g_SSJGohanParentPlayerWithBeam = CreateConVar("gohan_parent_player_with_beam", "1", "Should the player fly with the beam if only the player gets hit and not world?");

	RegAdminCmd("sm_gohan", Command_Gohan, ADMFLAG_ROOT);
	
	AutoExecConfig(true, "gohan", "sourcemod");
	
	g_hHudCharge = CreateHudSynchronizer();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_iFreeze = FindSendPropInfo("CBasePlayer", "m_fFlags");
	if(g_iFreeze == -1)
		SetFailState("CBasePlayer:m_fFlags not found");
}

public Action Command_Gohan(int client, int args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "sm_gohan <#UserID|Name> <status 0/1>");
		return Plugin_Handled;
	}
	
	int targets[129];
	bool ml = false;
	char buffer[MAX_NAME_LENGTH], arg1[MAX_NAME_LENGTH], arg2[4];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	int count = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, buffer, sizeof(buffer), ml);
	if (count <= 0)
	{
		ReplyToCommand(client, "Invalid Target");
	}
	else for (int i = 0; i < count; i++)
	{
		int target = targets[i];
		
		if(!IsClientValid(target))
		{
			return Plugin_Handled;
		}
		
		g_bHasKame[target] = view_as<bool>(StringToInt(arg2));
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsClientValid(client))
	{
		g_bCooldown[client] = false;
		g_bFiringBeam[client] = false;
		g_bCharging[client] = false;
		g_bHasKame[client] = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!g_bHasKame[client])
	{
		return Plugin_Continue;
	}
	
	for (int i = 0; i < 25; i++)
	{
		int button = (1 << i);
		
		if ((buttons & button))
		{
			if (!(g_iLastButtons[client] & button))
			{
				OnButtonPress(client, button);
			}
		}
		else if ((g_iLastButtons[client] & button))
		{
			// OnButtonRelease(client, button);
		}
	}
	
	g_iLastButtons[client] = buttons;
	
	return Plugin_Continue;
}


void OnButtonPress(int client, int button)
{
	if (!g_bHasKame[client])
	{
		return;
	}
	
	switch(button)
	{
		case IN_RELOAD:
		{
			if(IsFreezeTime() || !IsPlayerAlive(client))
				return;
			
			if(g_bFiringBeam[client] || g_bCharging[client])
				return;
			
			if (g_bCooldown[client])
			{
				return;
			}
			
			int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(wep != INVALID_ENT_REFERENCE)
			{
				char szWeapon[32];
				GetEntityClassname(wep, szWeapon, sizeof(szWeapon));
				if(StrContains(szWeapon, "knife") == -1 && StrContains(szWeapon, "bayonet") == -1)
				{
					SetHudTextParams(0.38, 0.60, 3.0, 255, 255, 0, 255);
					ShowHudText(client, -1, "EQUIP KNIFE TO FIRE KAMEHAMEHA");
					return;
				}
			}

			EmitSoundToAllAny(KAMEHAME_SOUND, client);
			g_fChargeTime[client] = 0.0;
			g_bCharging[client] = true;
			g_hTimerCharge[client] = CreateTimer(BEAM_REFRESH_RATE, Timer_Charge, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case IN_USE:
		{
			if(g_fChargeTime[client] >= g_SSJGohanMinChargeTime.FloatValue && g_bCharging[client] && !g_bFiringBeam[client])
			{
				g_fChargeAmount[client] = g_fChargeTime[client];
				Kamehameha(client);
			}
			else
			{
				g_bCharging[client] = false;
				g_fChargeTime[client] = 0.0;
				StopSoundAny(client, SNDCHAN_AUTO, KAMEHAME_SOUND);
			}
		}
	}
}

public Action Timer_Charge(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if (!IsClientValid(client) || !IsPlayerAlive(client))
	{
		g_bFiringBeam[client] = false;
		g_bCharging[client] = false;
		g_hTimerCharge[client] = null;
		return Plugin_Stop;
	}
	
	if(!g_bCharging[client])
	{
		g_hTimerCharge[client] = null;
		return Plugin_Stop;
	}
	
	if(g_bFiringBeam[client])
	{
		g_hTimerCharge[client] = null;
		return Plugin_Stop;
	}
	
	if(g_fChargeTime[client] >= g_SSJGohanMaxChargeTime.FloatValue)
	{
		g_fChargeAmount[client] = g_fChargeTime[client];
		Kamehameha(client);
		g_hTimerCharge[client] = null;
		return Plugin_Stop;
	}
	
	float percentage = (g_fChargeTime[client] / g_SSJGohanMaxChargeTime.FloatValue) * 100.0;
	char strProgressBar[128];
	for(int i = 0; i < percentage / 5; i++)
			Format(strProgressBar, sizeof(strProgressBar), "%s█", strProgressBar);
	if(percentage > 25.0)
		SetHudTextParams(0.17, 0.04, 0.1, 0, 230, 230, 0, 0, 0.0, 0.0, 0.0);
	else
		SetHudTextParams(0.17, 0.04, 0.1, 255, 0, 0, 0, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hHudCharge, "%.0f%%\n%s", percentage, strProgressBar);
	
	g_fChargeTime[client] += 0.1;
	return Plugin_Continue;
}

public void Kamehameha(int client)
{
	CreateTimer(g_SSJGohanCooldown.FloatValue, Timer_StartCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	g_bCooldown[client] = true;
	g_bCharging[client] = false;
	g_bFiringBeam[client] = true;
	float pos[3];
	GetClientEyePosition(client, pos);
	StopSoundAny(client, SNDCHAN_AUTO, KAMEHAME_SOUND);
	EmitAmbientSoundAny(HA_SOUND, pos, client);
	CreateKameBeam(client);
}

public Action Timer_StartCooldown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsClientValid(client))
	{
		g_bCooldown[client] = false;
	}
}

stock void CreateKameBeam(int client)
{
	float vecView[3], vecFwd[3], vecPos[3];

	GetClientEyeAngles(client, vecView);
	GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(client, vecPos);

	vecPos[0] += vecFwd[0] * 50.0;
	vecPos[1] += vecFwd[1] * 50.0;
	vecPos[2] += vecFwd[2] * 50.0;
	
	int prop = CreateEntityByName("prop_physics_override");
	g_iBeam[client] = EntIndexToEntRef(prop);
	DispatchKeyValue(prop, "targetname", "kamehameha"); 
	DispatchKeyValue(prop, "spawnflags", "4"); 
	DispatchKeyValue(prop, "model", "models/weapons/w_ied_dropped.mdl");
	DispatchSpawn(prop);
	ActivateEntity(prop);
	TeleportEntity(prop, vecPos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(prop, Prop_Data, "m_hOwnerEntity", client);
	SetEntProp(prop, Prop_Send, "m_fEffects", 32); //EF_NODRAW
	int ent = CreateEntityByName("env_sprite_oriented");
	g_iBeamHead[client] = EntIndexToEntRef(ent);
	DispatchKeyValue(ent, "spawnflags", "1");
	float fscale = g_fChargeAmount[client] * 0.3;
	char scale[32];
	Format(scale, sizeof(scale), "%f", fscale);
	DispatchKeyValue(ent, "scale", scale); 
	DispatchKeyValue(ent, "model", BEAM_HEAD); 
	DispatchSpawn(ent);
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", prop);
	
	g_hTimerCharge[client] = CreateTimer(0.1, Timer_Beam, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(7.0, Timer_StopBeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Beam(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	if(IsClientValid(client))
	{
		int entity = EntRefToEntIndex(g_iBeam[client]);
		if(entity == INVALID_ENT_REFERENCE)
		{
			g_hTimerCharge[client] = null;
			return Plugin_Stop;
		}
		
		float entityPos[3];
	
		float eyeAngles[3], eyePos[3];
		GetClientEyeAngles(client, eyeAngles);
		GetClientEyePosition(client, eyePos);
		
		if(IsPlayerAlive(client))
		{
			int activewep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(activewep != INVALID_ENT_REFERENCE)
			{
				char szClassName[32];
				GetEntityClassname(activewep, szClassName, sizeof(szClassName));
				if(StrContains(szClassName, "knife") != -1 || StrContains(szClassName, "bayonet") != -1 )
				{
					Handle trace = TR_TraceRayFilterEx(eyePos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
					if(TR_DidHit(trace))
						TR_GetEndPosition(g_vecEndPos[client], trace);
					CloseHandle(trace);
				}
			}
			else
			{
				//Allow steering kamehameha with no weapon at all
				Handle trace = TR_TraceRayFilterEx(eyePos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
				if(TR_DidHit(trace))
					TR_GetEndPosition(g_vecEndPos[client], trace);
				CloseHandle(trace);
			}
		}
		
		float entityVel[3];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
		float distance = GetVectorDistance(g_vecEndPos[client], entityPos);
		float time = distance / g_SSJGohanBeamSpeed.FloatValue;

		entityVel[0] = (g_vecEndPos[client][0] - entityPos[0]) / time;
		entityVel[1] = (g_vecEndPos[client][1] - entityPos[1]) / time;
		entityVel[2] = (g_vecEndPos[client][2] - entityPos[2]) / time;
		
		TeleportEntity(entity, NULL_VECTOR, view_as<float>({0.0,0.0,0.0}), entityVel);
		int color[4] =  { 0, 230, 230, 200 };
		
		float scale = g_fChargeAmount[client] * 6.0;
		TE_SetupBeamFollow(entity, g_iTrail, g_iTrail, 3.0, scale, scale+0.1, 0, color);
		TE_SendToAll();
		
		float vecMins[3], vecMaxs[3];
		vecMins[0] = -50.0;
		vecMins[1] = -50.0;
		vecMins[2] = -50.0;
		
		vecMaxs[0] = 50.0;
		vecMaxs[1] = 50.0;
		vecMaxs[2] = 50.0;
		entityPos[2] += 40.0;
		Handle ray = TR_TraceHullFilterEx(entityPos, entityPos, vecMins, vecMaxs, MASK_ALL, TraceFilterWorldPlayers, client);
		if(TR_DidHit(ray))
		{
			if(g_SSJGohanParentPlayerWithBeam.BoolValue)
			{
				int playerhit = TR_GetEntityIndex(ray);
				if(IsClientValid(playerhit) /*&& GetClientTeam(playerhit) != GetClientTeam(client)*/)
				{
					//Make the player fly with the beam, fuckin epic
					int sprite = EntRefToEntIndex(g_iBeamHead[client]);
					if(!IsClientValid(GetEntPropEnt(sprite, Prop_Data, "m_hMoveChild")))
					{
						SetEntityMoveType(playerhit, MOVETYPE_NONE);
						SetVariantString("!activator");
						AcceptEntityInput(playerhit, "SetParent", sprite);
					}
				}
				else
				{
					EndKameBeam(client, entity);
					g_hTimerCharge[client] = null;
					return Plugin_Stop;
				}
			}
			else
			{
				EndKameBeam(client, entity);
				g_hTimerCharge[client] = null;
				return Plugin_Stop;
			}
		}
	}
	else
	{
		int entity = EntRefToEntIndex(g_iBeam[client]);
		if(entity != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(entity, "Kill");
			g_iBeam[client] = INVALID_ENT_REFERENCE;
			g_iBeamHead[client] = INVALID_ENT_REFERENCE;
			g_hTimerCharge[client] = null;
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}


public Action Timer_StopBeam(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (IsClientValid(client))
	{
		int entity = EntRefToEntIndex(g_iBeam[client]);
		if(entity == INVALID_ENT_REFERENCE)
		{
			if (g_hTimerCharge[client] != null)
			{
				KillTimer(g_hTimerCharge[client]);
			}
			
			g_hTimerCharge[client] = null;
		}
		
		EndKameBeam(client, entity);
		
		if (g_hTimerCharge[client] != null)
		{
			KillTimer(g_hTimerCharge[client]);
			g_hTimerCharge[client] = null;
		}
	}
	
	return Plugin_Stop;
}

void CS_CreateExplosion(int client, int damage, int radius, float pos[3])
{
	int entity;
	if((entity = CreateEntityByName("env_explosion")) != -1)
	{
		DispatchKeyValue(entity, "spawnflags", "552");
		DispatchKeyValue(entity, "rendermode", "5");
		
		SetEntProp(entity, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(entity, Prop_Data, "m_iRadiusOverride", radius);
		SetEntProp(entity, Prop_Data, "m_iTeamNum", GetClientTeam(client));
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);

		DispatchSpawn(entity);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		
		RequestFrame(TriggerExplosion, entity);
	}
}

public void TriggerExplosion(int entity)
{
	AcceptEntityInput(entity, "explode");
	AcceptEntityInput(entity, "Kill");
}

public void EndKameBeam(int client, int entity)
{
	if (!IsValidEntity(entity))
	{
		return;
	}
	
	float entityPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
	int sprite = EntRefToEntIndex(g_iBeamHead[client]);
	if(sprite != INVALID_ENT_REFERENCE)
	{
		int child = GetEntPropEnt(sprite, Prop_Data, "m_hMoveChild");
		if(child > 0)
		{
			SetEntityMoveType(child, MOVETYPE_WALK);
			AcceptEntityInput(child, "ClearParent");
			TeleportEntity(child, entityPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	//TE_SetupMuzzleFlash(entityPos, NULL_VECTOR, 20.0, 1);
	float scale = g_fChargeAmount[client] * 0.4;
	int chargeAmount = RoundToNearest(g_fChargeAmount[client]);
	CS_CreateExplosion(client, g_SSJGohanDamageMultiplier.IntValue * chargeAmount, g_SSJGohanRadiusMultiplier.IntValue * chargeAmount, entityPos);
	TE_SetupGlowSprite(entityPos, g_iExplosion, 3.0, scale, 50);
	TE_SendToAll();
	AcceptEntityInput(entity, "Kill");
	g_iBeam[client] = INVALID_ENT_REFERENCE;
	g_iBeamHead[client] = INVALID_ENT_REFERENCE;
	g_bCharging[client] = false;
	g_bFiringBeam[client] = false;
}

public Action OnWeaponSwitch(int client, int weapon)
{
	if(g_bCharging[client])
	{
		char szClassName[32];
		GetEntityClassname(weapon, szClassName, sizeof(szClassName));
		if(StrContains(szClassName, "knife") == -1 && StrContains(szClassName, "bayonet") == -1)
		{
			g_bCharging[client] = false;
			StopSoundAny(client, SNDCHAN_AUTO, KAMEHAME_SOUND);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("materials/superheromod/kamehamehahead.vmt");
	AddFileToDownloadsTable("materials/superheromod/kamehamehahead.vtf");
	AddFileToDownloadsTable("materials/superheromod/kamehamehaexplosion.vmt");
	AddFileToDownloadsTable("materials/superheromod/kamehamehaexplosion.vtf");
	
	AddFileToDownloadsTable("sound/superheromod/beamhead.mp3");
	AddFileToDownloadsTable("sound/superheromod/gohan_ha.mp3");
	AddFileToDownloadsTable("sound/superheromod/gohan_kamehame.mp3");
	
	PrecacheSoundAny(BEAM_SOUND, true);
	PrecacheSoundAny(HA_SOUND, true);
	PrecacheSoundAny(KAMEHAME_SOUND, true);
	
	g_iTrail = PrecacheModel(BEAM_TRAIL);
	PrecacheModel(BEAM_HEAD);
	g_iExplosion = PrecacheModel(BEAM_EXPLOSION);
	PrecacheModel("models/weapons/w_ied_dropped.mdl");
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	if(entity == 0 && entityhit != entity)
		return true;
	
	return false;
}

public bool TraceFilterWorldPlayers(int entityhit, int mask, any entity)
{
	if(entityhit > -1 && entityhit <= MAXPLAYERS && entityhit != entity)
	{
		return true;
	}
	
	return false;
}
