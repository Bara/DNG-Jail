#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties>
#include <cstrike>
#include <lastrequest>
#include <sdkhooks>
#include <dng-jail>
#include <sprays>

#pragma newdecls required

// 111 - Schacht
#define CONTESTSPRAY 111

int g_iCurrentLR = -1;

int g_iLRLow = -1;
int g_iLRHigh = -1;

int g_iLRPrisoner = -1;
int g_iPrisonerSpray = -1;

int g_iLRGuard = -1;
int g_iGuardSpray = -1;

bool g_bRunning = false;

bool g_bPrisonerSprayed = false;
bool g_bGuardSprayed = false;

float g_fPrisonerDistance = 0.0;
float g_fGuardDistance = 0.0;

bool g_bShowPos[MAXPLAYERS + 1] =  { false, ... };

public Plugin myinfo = 
{
	name = "[] LastRequest: SprayContest", 
	author = "Bara", 
	description = "", 
	version = "1.0.0", 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);

	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public void OnConfigsExecuted()
{
	static bool bAddedLR_Low = false;
	if (!bAddedLR_Low)
	{
		g_iLRLow = AddLastRequestToList(LR_StartLow, LR_StopLow, "Spray Contest Low", false);
		bAddedLR_Low = true;
	}
	
	static bool bAddedLR_High = false;
	if (!bAddedLR_High)
	{
		g_iLRHigh = AddLastRequestToList(LR_StartHigh, LR_StopHigh, "Spray Contest High", false);
		bAddedLR_High = true;
	}
}

public void OnPluginEnd()
{
	RemoveLastRequestFromList(LR_StartLow, LR_StopLow, "Spray Contest Low");
	RemoveLastRequestFromList(LR_StartHigh, LR_StopHigh, "Spray Contest High");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetSettings();
}

public int LR_StartLow(Handle LR_Array, int iIndexInArray)
{
	g_iCurrentLR = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
	
	if(g_iCurrentLR == g_iLRLow)
		StartLR(LR_Array, iIndexInArray);
}

public int LR_StartHigh(Handle LR_Array, int iIndexInArray)
{
	g_iCurrentLR = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
	
	if(g_iCurrentLR == g_iLRHigh)
		StartLR(LR_Array, iIndexInArray);
}

public int LR_StopLow(int Type, int Prisoner, int Guard)
{
	// Reset stuff
	ResetSettings();
}

public int LR_StopHigh(int Type, int Prisoner, int Guard)
{
	// Reset stuff
	ResetSettings();
}

void StartLR(Handle hArray, int inArray)
{
	g_iLRPrisoner = GetArrayCell(hArray, inArray, view_as<int>(Block_Prisoner));
	g_iLRGuard = GetArrayCell(hArray, inArray, view_as<int>(Block_Guard));
	
	// Save spray settings
	g_iPrisonerSpray = Sprays_GetClientSpray(g_iLRPrisoner);
	g_iGuardSpray = Sprays_GetClientSpray(g_iLRGuard);
	
	// Set contest spray
	Sprays_SetClientSpray(g_iLRPrisoner, CONTESTSPRAY);
	Sprays_SetClientSpray(g_iLRGuard, CONTESTSPRAY);
	
	char sContest[8];
	if(g_iCurrentLR == g_iLRLow)
		Format(sContest, sizeof(sContest), "Low");
	else if(g_iCurrentLR == g_iLRHigh)
		Format(sContest, sizeof(sContest), "High");
	
	CheckShowPos(g_iLRPrisoner);
	CheckShowPos(g_iLRGuard);
	
	g_bRunning = true;
	
	CPrintToChatAll("%N spielt gegen %N Spray Contest %s.", g_iLRPrisoner, g_iLRGuard, sContest);
	
	CPrintToChat(g_iLRPrisoner, "{darkred}Dein Spray ist für dieses Spiel ein Schacht!");
	CPrintToChat(g_iLRGuard, "{darkred}Dein Spray ist für dieses Spiel ein Schacht!");
	
	Sprays_ResetClientTime(g_iLRPrisoner);
	Sprays_ResetClientTime(g_iLRGuard);
	
	if (IsClientValid(g_iLRPrisoner))
	{
		InitializeLR(g_iLRPrisoner);
	}
}

void CheckShowPos(int client)
{
	QueryClientConVar(client, "cl_showpos", Query_ShowPosAnnounce, 0);
}

public void Query_ShowPosAnnounce(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (StringToInt(cvarValue) == 1)
	{
		CPrintToChatAll("{yellow}%N {green}hat keine Eier und nutzt {yellow}cl_showpos 1{green}!", client);
		g_bShowPos[client] = true;
	}
}

void ResetSettings()
{
	g_bRunning = false;
	
	if(IsClientValid(g_iLRPrisoner))
	{
		Sprays_SetClientSpray(g_iLRPrisoner, g_iPrisonerSpray);
		g_bShowPos[g_iLRPrisoner] = false;
	}
	
	if(IsClientValid(g_iLRGuard))
	{
		Sprays_SetClientSpray(g_iLRGuard, g_iGuardSpray);
		g_bShowPos[g_iLRGuard] = false;
	}
	
	g_iPrisonerSpray = -1;
	g_iGuardSpray = -1;
	
	g_iLRPrisoner = -1;
	g_iLRGuard = -1;
	
	g_bPrisonerSprayed = false;
	g_fPrisonerDistance = 0.0;
	g_bGuardSprayed = false;
	g_fGuardDistance = 0.0;
	
	g_iCurrentLR = -1;
}

public Action Sprays_OnClientSpray(int client, float[3] fPosition2)
{
	if(g_bRunning && (g_iCurrentLR == g_iLRLow || g_iCurrentLR == g_iLRHigh))
	{
		if(client != g_iLRPrisoner && client != g_iLRGuard)
			return;
		
		float endPosUp[3];
		float endPosDown[3];
		
		CheckShowPos(client);
		
		TR_TraceRayFilter(fPosition2, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceRayFilter, client);
		TR_GetEndPosition(endPosDown);
		
		TR_TraceRayFilter(fPosition2, view_as<float>({-90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceRayFilter, client);
		TR_GetEndPosition(endPosUp);
		
		if(GetVectorDistance(fPosition2, endPosUp)>0.0 && GetVectorDistance(fPosition2, endPosDown)>0.0)
		{
			if (GetVectorDistance(fPosition2, endPosUp) < 32.0 || GetVectorDistance(fPosition2, endPosDown) < 32.0)
			{
				if(client == g_iLRPrisoner)
				{
					ForcePlayerSuicide(client);
					CPrintToChatAll("{green}%N {default}hat gewonnen, weil {green}%N {default}den Boden/die Decke berührt hat!", g_iLRGuard, g_iLRPrisoner);
				}
				else if(client == g_iLRGuard)
				{
					ForcePlayerSuicide(client);
					CPrintToChatAll("{green}%N {default}hat gewonnen, weil {green}%N {default}den Boden/die Decke berührt hat!", g_iLRPrisoner, g_iLRGuard);
				}
			}
			else
			{
				float distanceUnits = GetVectorDistance(fPosition2, endPosDown);
				float distanceMeters = UnitsToMeters(distanceUnits-32);
				float distanceMillimeters = distanceMeters * 1000;
				
				if (g_bShowPos[client])
				{
					if (g_iCurrentLR == g_iLRLow)
					{
						distanceMillimeters += 20.0;
						
						CPrintToChatAll("Aufgrund der Nutzung von {yellow}cl_showpos 1 {green}erhält {yellow}%N {green} eine Strafe von +20mm!", client);
					}
					
					if (g_iCurrentLR == g_iLRHigh)
					{
						distanceMillimeters -= 20.0;
						
						CPrintToChatAll("Aufgrund der Nutzung von {yellow}cl_showpos 1 {green}erhält {yellow}%N {green} eine Strafe von -20mm!", client);
					}
				}
				
				if(client == g_iLRPrisoner)
				{
					g_bPrisonerSprayed = true;
					g_fPrisonerDistance = distanceMillimeters;
				}
				else if(client == g_iLRGuard)
				{
					g_bGuardSprayed = true;
					g_fGuardDistance = distanceMillimeters;
				}
				
				CPrintToChatAll("{green}%N {default}hat in höhe von {green}%.2f mm {default}gesprüht.", client, distanceMillimeters);
			}
		}
		
		if(g_bPrisonerSprayed && g_bGuardSprayed)
		{
			if (g_iCurrentLR == g_iLRLow)
			{
				if(g_fGuardDistance < g_fPrisonerDistance) // Guard Win
				{
					CPrintToChatAll("{green}%N {default}gewinnt Spray Contest Low gegen {green}%N {default}mit {green}%.2fmm {default}Unterschied!", g_iLRGuard, g_iLRPrisoner, (g_fGuardDistance - g_fPrisonerDistance));
					ForcePlayerSuicide(g_iLRPrisoner);
				}
				else if(g_fGuardDistance > g_fPrisonerDistance) // Prisoner Win
				{
					CPrintToChatAll("{green}%N {default}gewinnt Spray Contest Low gegen {green}%N {default}mit {green}%.2fmm {default}Unterschied!", g_iLRPrisoner, g_iLRGuard, (g_fPrisonerDistance - g_fGuardDistance));
					ForcePlayerSuicide(g_iLRGuard);
				}
				else if(g_fGuardDistance == g_fPrisonerDistance) // Nobody Win
				{
					CPrintToChatAll("{green}Unentschieden! {default}Keiner gewinnt...");
					LR_StopLow(g_iCurrentLR, g_iLRPrisoner, g_iLRGuard);
				}
			}
			else if(g_iCurrentLR == g_iLRHigh)
			{
				if(g_fGuardDistance < g_fPrisonerDistance) // Guard Win
				{
					CPrintToChatAll("{green}%N {default}gewinnt Spray Contest High gegen {green}%N {default}mit {green}%.2fmm {default}Unterschied!", g_iLRPrisoner, g_iLRGuard, (g_fPrisonerDistance - g_fGuardDistance));
					ForcePlayerSuicide(g_iLRGuard);
				}
				else if(g_fGuardDistance > g_fPrisonerDistance) // Prisoner Win
				{
					CPrintToChatAll("{green}%N {default}gewinnt Spray Contest High gegen {green}%N {default}mit {green}%.2fmm {default}Unterschied!", g_iLRGuard, g_iLRPrisoner, (g_fGuardDistance - g_fPrisonerDistance));
					ForcePlayerSuicide(g_iLRPrisoner);
				}
				else if(g_fGuardDistance == g_fPrisonerDistance) // Nobody Win
				{
					CPrintToChatAll("{green}Unentschieden! {default}Keiner gewinnt...");
					LR_StopHigh(g_iCurrentLR, g_iLRPrisoner, g_iLRGuard);
				}
			}
		}
	}
}

float UnitsToMeters(float units)
{
	return (units * 0.01905);
}

bool TraceRayFilter(int entity, int mask, any data)
{
	if(entity != 0)
		return false;
	return true;
}
