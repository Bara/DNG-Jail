#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike> 
#include <sdktools>
#include <lastrequest>
#include <dng-jail>
#include <multicolors>

#define MAX_BUTTONS 25

int g_iLastButtons[MAXPLAYERS + 1] =  { -1, ... };

int g_iCurrentLR = -1;
int g_iLR = -1;
int g_iLRPrisoner = -1;
int g_iLRGuard = -1;
int g_iCountdown = -1;

bool g_bChat = false;

bool g_bAction = false;
int g_iButton = -1;

public Plugin myinfo = 
{
	name = "LastRequest: Last Reaction", 
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
	static bool bAddedLR = false;
	if (!bAddedLR)
	{
		g_iLR = AddLastRequestToList(LR_Start, LR_Stop, "Last Reaction", false);
		bAddedLR = true;
	}
}

public void OnPluginEnd()
{
	RemoveLastRequestFromList(LR_Start, LR_Stop, "Last Reaction");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetSettings();
}

public int LR_Start(Handle LR_Array, int iIndexInArray)
{
	g_iCurrentLR = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
	
	if(g_iCurrentLR == g_iLR)
		StartLR(LR_Array, iIndexInArray);
}

public int LR_Stop(int Type, int Prisoner, int Guard)
{
	ResetSettings();
}

void StartLR(Handle hArray, int inArray)
{
	g_iLRPrisoner = GetArrayCell(hArray, inArray, view_as<int>(Block_Prisoner));
	g_iLRGuard = GetArrayCell(hArray, inArray, view_as<int>(Block_Guard));
	
	// int iOption = GetRandomInt(0, 1);
	int iOption = 1;
	
	if (iOption == 0)
	{
		g_bChat = true;
	}
	else
	{
		g_bAction = true;
	}
	
	CPrintToChatAll("%N spielt gegen %N Last Reaction.", g_iLRPrisoner, g_iLRGuard);
	
	g_iCountdown = 3;
	g_iButton = -1;
	
	RequestFrame(Frame_StartCountdown);
	
	InitializeLR(g_iLRPrisoner);
}

public void Frame_StartCountdown(any data)
{
	CPrintToChatAll("Last Reaction beginnt in %s Sekunden", g_iCountdown);
	CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
}

public Action Timer_Countdown(Handle timer)
{
	if (g_iCountdown >= 2)
	{
		g_iCountdown--;
		CPrintToChatAll("Last Reaction beginnt in %s Sekunden", g_iCountdown);
		
		return Plugin_Continue;
	}
	else if (g_iCountdown == 1)
	{
		g_iCountdown--;
		CPrintToChatAll("Last Reaction beginnt in 1 Sekunde");
		return Plugin_Continue;
	}
	else if (g_iCountdown == 0)
	{
		CPrintToChatAll("Last Reaction beginnt...");
		RequestFrame(Frame_StartLR);
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Stop;
	}
}

public void Frame_StartLR(any data)
{
	if (g_bChat)
	{
		// code...
	}
	
	if (g_bAction)
	{
		int iOption = GetRandomInt(0, 7);
		
		if (iOption == 0)
		{
			g_iButton = IN_JUMP;
			CPrintToChatAll("Last Reaction... {lime}SPRINGEN");
		}
		else if (iOption == 1)
		{
			g_iButton = IN_DUCK;
			CPrintToChatAll("Last Reaction... {lime}DUCKEN");
		}
		else if (iOption == 2)
		{
			g_iButton = IN_ATTACK;
			CPrintToChatAll("Last Reaction... {lime}LINKSKLICK");
		}
		else if (iOption == 3)
		{
			g_iButton = IN_ATTACK2;
			CPrintToChatAll("Last Reaction... {lime}RECHTSKLICK");
		}
		else if (iOption == 4)
		{
			g_iButton = IN_FORWARD;
			CPrintToChatAll("Last Reaction... {lime}NACH VORNE LAUFEN");
		}
		else if (iOption == 5)
		{
			g_iButton = IN_BACK;
			CPrintToChatAll("Last Reaction... {lime}NACH HINTEN LAUFEN");
		}
		else if (iOption == 6)
		{
			g_iButton = IN_MOVERIGHT;
			CPrintToChatAll("Last Reaction... {lime}NACH RECHTS LAUFEN");
		}
		else if (iOption == 7)
		{
			g_iButton = IN_MOVELEFT;
			CPrintToChatAll("Last Reaction... {lime}NACH LINKS LAUFEN");
		}
	}
}

void OnButtonPress(int client, int button)
{
	if (IsClientValid(g_iLRPrisoner) && IsClientValid(g_iLRGuard))
	{
		if (IsPlayerAlive(g_iLRPrisoner) && IsPlayerAlive(g_iLRGuard))
		{
			if (client == g_iLRPrisoner || client == g_iLRGuard)
			{
				if (button & g_iButton)
				{
					if (client == g_iLRPrisoner)
					{
						CPrintToChatAll("%N hat gewonnen!", g_iLRPrisoner);
						ForcePlayerSuicide(g_iLRGuard);
					}
					else if (client == g_iLRGuard)
					{
						CPrintToChatAll("%N hat gewonnen!", g_iLRGuard);
						ForcePlayerSuicide(g_iLRPrisoner);
					}
				}
			}
		}
	}
}

void ResetSettings()
{
	g_bAction = false;
	g_bChat = false;
	
	g_iLRPrisoner = -1;
	g_iLRGuard = -1;
	
	g_iCurrentLR = -1;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	for (int i = 0; i < MAX_BUTTONS; i++)
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
