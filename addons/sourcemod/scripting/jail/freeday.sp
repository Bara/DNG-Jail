#define TIME_BEACON 0.5

bool g_bFreeday[MAXPLAYERS + 1] =  { false, ... };

Handle g_hFreedayTimer[MAXPLAYERS + 1] =  { null, ... };

int g_iBeamSprite = -1;
int g_iBeamHaloSprite = -1;

public Action Command_freeday(int client, int args)
{
	if (!g_cEnableFreeday.BoolValue)
	{
		return Plugin_Handled;
	}

	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) || CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			Menu menu = new Menu(FreedayMenu);
			menu.SetTitle("Freeday für:");
			
			char sName[MAX_NAME_LENGTH];
			
			LoopClients(i)
			{
				if(!IsFakeClient(i) && !IsClientSourceTV(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
				{
					if(!g_bFreeday[i])
					{
						GetClientName(i, sName, sizeof(sName));
						menu.AddItem(sName, sName);
					}
				}
			}
			
			menu.Display(client, MTF);
		}
	}
	
	return Plugin_Handled;
}


// Menu

public int FreedayMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char sName[MAX_NAME_LENGTH];
		menu.GetItem(param, sName, sizeof(sName));
		
		int iTarget = FindTarget(client, sName, true, false);
		
		if(iTarget == -1)
		{
			CPrintToChat(client, "Spieler nicht gefunden.");
		}
		else
		{
			if(IsPlayerAlive(iTarget))
			{
				g_bFreeday[iTarget] = true;
				
				SetEntityRenderMode(iTarget, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iTarget, 205, 205, 0, 255);
				
				g_hFreedayTimer[iTarget] = CreateTimer(TIME_BEACON, FreedayTimer, iTarget, TIMER_REPEAT);
				
				CPrintToChatAll("%s%N %shat %s%N %seinen Freeday gegeben.", SPECIAL, client, TEXT, SPECIAL, iTarget, TEXT);
				CPrintToChat(iTarget, "Du hast einen Freeday von %s%N %sbekommen. Have Fun!", SPECIAL, client, TEXT); // Warum sollte der Spieler die Nachricht 2x bekommen reicht die All message nicht?
			}
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}


// Timer

public Action FreedayTimer(Handle timer, any client)
{
	if(IsClientValid(client) && IsPlayerAlive(client) && g_hFreedayTimer[client] != null && g_bFreeday[client]) // das timer != null wegen ResetFreeday da es nur auf null gesetzt wird (bin mir aber nicht sicher)
	{
		float fClientPos[3];
		GetClientAbsOrigin(client, fClientPos);
		fClientPos[2] += 1;
		
		TE_SetupBeamRingPoint(fClientPos, 50.0, 0.0, g_iBeamSprite, g_iBeamHaloSprite, 65, 60, 0.5, 2.0, 0.5, {128, 128, 0, 255}, 5, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(fClientPos, 30.0, 0.0, g_iBeamSprite, g_iBeamHaloSprite, 65, 60, 0.5, 2.0, 0.5, {128, 128, 0, 255}, 5, 0);
		TE_SendToAll();
		
		return Plugin_Continue;
	}
	
	g_hFreedayTimer[client] = null;
	
	return Plugin_Stop;
}


void Freeday_OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iBeamHaloSprite = PrecacheModel("materials/sprites/glow.vmt");
}

public void ResetFreeday(int client)
{
	g_bFreeday[client] = false;
	delete g_hFreedayTimer[client];
}