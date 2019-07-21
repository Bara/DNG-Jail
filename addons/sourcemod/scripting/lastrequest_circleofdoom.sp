#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <hosties>
#include <lastrequest>
#include <cstrike>
#include <smlib>
#include <dng-jail>

#pragma newdecls required

#define COD_VERSION "2.0.0"
#define PREPARE_TIME 3.0

int g_LREntryNum;
int LR_Player_Prisoner = -1;
int LR_Player_Guard = -1;
char g_sLR_Name[64];
Handle SpriteTimer = INVALID_HANDLE;
Handle DistanceTimer = INVALID_HANDLE;
float BeamCenter[3];
float RingCenter[3];
float start_radius = 220.1;
float end_radius = 220.0;
float g_fLife = 0.1;
float g_fWidth = 5.0;
int spriteCounter;
int g_Sprite;
int offseta = 0;
int SafeZone = 130;
int colours[7][4] =
{
	{255, 0, 0, 255},
	{255, 127, 0, 255},
	{255, 255, 0, 255},
	{0, 255, 0, 255},
	{0, 0, 255, 255},
	{75, 0, 130, 255},
	{143, 0, 255, 255}
};

bool g_bPreparing = false;
bool g_bLR = false;

public Plugin myinfo =
{
	name = "Last Request: Circle of Doom",
	author = "Jason Bourne & Kolapsicle",
	description = "Circle of Doom Custom LR for SM Hosties Mod",
	version = COD_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=243126"
};


public void OnPluginStart()
{
	LoadTranslations("circleofdoom.phrases");
	
	HookEvent("round_start", Event_RoundStart);
	
	Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "LR Name", LANG_SERVER);

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}


public void OnMapStart()
{
	if(GetEngineVersion() == Engine_CSS)
		g_Sprite = PrecacheModel("materials/sprites/laser.vmt");
	else if(GetEngineVersion() == Engine_CSGO)
		g_Sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}


public void OnConfigsExecuted()
{
	static bool bAddedCustomLR = false;
	if (!bAddedCustomLR)
	{
		g_LREntryNum = AddLastRequestToList(CircleOfDoom_Start, CircleOfDoom_Stop, g_sLR_Name);
		bAddedCustomLR = true;
	}
}


public void OnPluginEnd()
{
	RemoveLastRequestFromList(CircleOfDoom_Start, CircleOfDoom_Stop, g_sLR_Name);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LoopClients(i)
	{
		SDKUnhook(i, SDKHook_TraceAttack, OnTraceAttack);
		SDKUnhook(i, SDKHook_TraceAttack, OnTraceAttack);
	}
	
	if (SpriteTimer != INVALID_HANDLE)
	{
		KillTimer(SpriteTimer);
		SpriteTimer = INVALID_HANDLE;
	}
	
	if (DistanceTimer != INVALID_HANDLE)
	{
		KillTimer(DistanceTimer);
		DistanceTimer = INVALID_HANDLE;
	}
	
	LR_Player_Prisoner = -1;
	LR_Player_Guard = -1;
}

public int CircleOfDoom_Start(Handle LR_Array, int iIndexInArray)
{
	int This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
	if (This_LR_Type == g_LREntryNum)
	{
		LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Prisoner));
		LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Guard));
		
		// check datapack value
		int LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_Global1));
		switch (LR_Pack_Value)
		{
			case -1:
			{
				PrintToServer("no info included");
			}
		}
		
		g_bPreparing = true;
		g_bLR = true;
		
		SetEntityHealth(LR_Player_Prisoner, 100);
		SetEntityHealth(LR_Player_Guard, 100);
		
		RemoveAllWeapons(LR_Player_Prisoner);
		RemoveAllWeapons(LR_Player_Guard);
		
		SDKHook(LR_Player_Prisoner, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(LR_Player_Guard, SDKHook_TraceAttack, OnTraceAttack);
		
		SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
		SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);
		
		int iKnife = -1;
		iKnife = GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
		EquipPlayerWeapon(LR_Player_Prisoner, iKnife);
		
		iKnife = -1;
		iKnife = GivePlayerItem(LR_Player_Guard, "weapon_knife");
		EquipPlayerWeapon(LR_Player_Guard, iKnife);
		
		GetClientAbsOrigin(LR_Player_Prisoner, BeamCenter);
		TeleportEntity(LR_Player_Guard, BeamCenter, NULL_VECTOR, NULL_VECTOR);
		
		SpriteTimer = CreateTimer(0.1, Timer_DrawSprite, _, TIMER_REPEAT);
		DistanceTimer = CreateTimer(0.1, Timer_CheckDistance, _, TIMER_REPEAT);
		CreateTimer(PREPARE_TIME, Timer_Unfreeze);
		
		CPrintToChatAll("%t", "LR Freeze");
		CPrintToChatAll("%t", "LR Start", LR_Player_Prisoner, LR_Player_Guard);
		CPrintToChatAll("%t", "LR Explain");
	}
}


public Action Timer_Unfreeze(Handle timer)
{
	SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_WALK);
	SetEntityMoveType(LR_Player_Guard, MOVETYPE_WALK);
	CPrintToChatAll("%t", "LR Go");
	g_bPreparing = false;
	return Plugin_Stop;
}

public Action Timer_CheckDistance(Handle timer)
{
	if (LR_Player_Prisoner != -1)
	{
		float distance;
		float guardLocation[3];
		float prisonerLocation[3];

		GetClientAbsOrigin(LR_Player_Guard, guardLocation);
		distance = SquareRoot(Pow((guardLocation[0] - BeamCenter[0]), 2.0) + Pow((guardLocation[1] - BeamCenter[1]), 2.0));
		if (distance > SafeZone)
		{
			CPrintToChatAll("%t", "LR Winner", LR_Player_Prisoner);
			ForcePlayerSuicide(LR_Player_Guard);
			return Plugin_Stop;
		}
		else
		{
			GetClientAbsOrigin(LR_Player_Prisoner, prisonerLocation);
			distance = SquareRoot(Pow((prisonerLocation[0] - BeamCenter[0]), 2.0) + Pow((prisonerLocation[1] - BeamCenter[1]), 2.0));
			if (distance > SafeZone)
			{
				CPrintToChatAll("%t", "LR Winner", LR_Player_Guard);
				ForcePlayerSuicide(LR_Player_Prisoner);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

public Action Timer_DrawSprite(Handle timer)
{
	spriteCounter++;

	for (int i = 0; i < 7; i++)
	{
		BeamCenter[2] += 10;
		if (i == 0)
		{
			TE_SetupBeamRingPoint(BeamCenter, start_radius, end_radius, g_Sprite, 0, 0, 25, g_fLife, g_fWidth, 0.0, colours[0], 1, 0);
			TE_SendToAll();
		}
		TE_SetupBeamRingPoint(BeamCenter, start_radius + 70, end_radius + 70, g_Sprite, 0, 0, 25, g_fLife, g_fWidth, 0.0, colours[0], 1, 0);
		TE_SendToAll();
	}

	BeamCenter[2] -= 70;

	float a[3];
	float b[3];
	float c[3];
	float d[3];
	float e[3];
	float f[3];
	offseta += 10;
	int radius = 18;
	float ring_radius = 127.5;
	for (int i = 0; i < 8; i++)
	{
		RingCenter[0] = BeamCenter[0] + ring_radius * Cosine(DegToRad(offseta + i * 45.0));
		RingCenter[1] = BeamCenter[1] + ring_radius * Sine(DegToRad(offseta + i * 45.0));
		RingCenter[2] = BeamCenter[2];

		a[2] = RingCenter[2] + 10;
		b[2] = RingCenter[2] + 10;
		c[2] = RingCenter[2] + 10;
		d[2] = RingCenter[2] + 10;
		e[2] = RingCenter[2] + 10;
		f[2] = RingCenter[2] + 10;

		a[0] = RingCenter[0] + radius * Cosine(DegToRad(90.0));
		a[1] = RingCenter[1] + radius * Sine(DegToRad(90.0));

		b[0] = RingCenter[0] + radius * Cosine(DegToRad(210.0));
		b[1] = RingCenter[1] + radius * Sine(DegToRad(210.0));

		c[0] = RingCenter[0] + radius * Cosine(DegToRad(330.0));
		c[1] = RingCenter[1] + radius * Sine(DegToRad(330.0));

		d[0] = RingCenter[0] + radius * Cosine(DegToRad(270.0));
		d[1] = RingCenter[1] + radius * Sine(DegToRad(270.0));

		e[0] = RingCenter[0] + radius * Cosine(DegToRad(30.0));
		e[1] = RingCenter[1] + radius * Sine(DegToRad(30.0));

		f[0] = RingCenter[0] + radius * Cosine(DegToRad(150.0));
		f[1] = RingCenter[1] + radius * Sine(DegToRad(150.0));

		TE_SetupBeamPoints(a, b, g_Sprite, 0, 0, 25, g_fLife,
					g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
		TE_SendToAll();
		TE_SetupBeamPoints(c, b, g_Sprite, 0, 0, 25, g_fLife,
					g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
		TE_SendToAll();
		TE_SetupBeamPoints(a, c, g_Sprite, 0, 0, 25, g_fLife,
					g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
		TE_SendToAll();
		TE_SetupBeamPoints(d, e, g_Sprite, 0, 0, 25, g_fLife,
					g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
		TE_SendToAll();
		TE_SetupBeamPoints(d, f, g_Sprite, 0, 0, 25, g_fLife,
					g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
		TE_SendToAll();
		TE_SetupBeamPoints(e, f, g_Sprite, 0, 0, 25, g_fLife,
					g_fWidth, g_fWidth, 0, 0.0, colours[3], 0);
		TE_SendToAll();
	}
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (attacker == LR_Player_Guard || attacker == LR_Player_Prisoner)
	{
		if(!g_bPreparing)
			SlapPlayer(victim, 0, true);
	}
	return Plugin_Handled;
}

public int CircleOfDoom_Stop(int This_LR_Type, int Player_Prisoner, int Player_Guard)
{
	if (This_LR_Type == g_LREntryNum)
	{
		SDKUnhook(Player_Prisoner, SDKHook_TraceAttack, OnTraceAttack);
		SDKUnhook(Player_Guard, SDKHook_TraceAttack, OnTraceAttack);

		if (SpriteTimer != INVALID_HANDLE)
		{
			KillTimer(SpriteTimer);
			SpriteTimer = INVALID_HANDLE;
		}

		if (DistanceTimer != INVALID_HANDLE)
		{
			KillTimer(DistanceTimer);
			DistanceTimer = INVALID_HANDLE;
		}

		if (IsClientInGame(Player_Prisoner) && IsClientInGame(Player_Guard))
		{
			if (IsPlayerAlive(Player_Prisoner) && IsPlayerAlive(Player_Guard))
			{
				CPrintToChatAll("%t", "LR Abort");
			}
		}

		LR_Player_Prisoner = -1;
		LR_Player_Guard = -1;
		g_bLR = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_bLR)
	{
		if (IsClientValid(client))
		{
			if (client == LR_Player_Prisoner || client == LR_Player_Guard)
			{
				if(buttons & IN_DUCK)
				{
					buttons &= ~IN_DUCK;
					return Plugin_Changed;
				}
			}
		}
	}
	
	return Plugin_Continue;
}
