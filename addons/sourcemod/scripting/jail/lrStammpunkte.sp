static bool g_bValidRound = false;

static Handle g_hTimer = null;

static bool g_bInRound[MAXPLAYERS + 1] =  { false, ... };


void LrStammpunkte_RoundStart()
{
	ResetLrStammpunkte();
	
	LoopClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
		{
			g_bInRound[i] = true;
		}
	}
	
	g_hTimer = CreateTimer(240.0, LrTimer);
}

void LrStammpunkte_RoundEnd()
{
	LoopClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
		{
			g_bInRound[i] = false;
		}
	}
}

void ResetClientLrStammpunkte(int client)
{
	g_bInRound[client] = false;
}

public Action LrTimer(Handle timer)
{
	g_bValidRound = true;
	
	g_hTimer = null;
	return Plugin_Stop;
}

void LrStammpunkte_PlayerDeath()
{
	if (!g_cEnableLRPoints.BoolValue)
	{
		return;
	}

	int iPlayerCount = 0;
	
	LoopClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
		{
			if(g_bInRound[i])
			{
				iPlayerCount++;
			}
		}
	}

	int iMinPlayers = 5;
	ConVar cvar = FindConVar("stamm_min_player");

	if (cvar != null)
	{
		iMinPlayers = cvar.IntValue;
	}
	
	if(iPlayerCount >= iMinPlayers && GetAlivePlayers() == 1)
	{
		if(g_bValidRound)
		{
			int client = GetLastAlivePlayer();
			if ((g_cLRPointsMode.IntValue == 1 || g_cLRPointsMode.IntValue == 2) && g_cLRPointsStammpoints.IntValue > 0)
			{
				CPrintToChatAll("%s%N %serhält %s%d Stammpunkte%s, da er der letzte Überlebende ist.", SPECIAL, client, TEXT, SPECIAL, g_cLRPointsStammpoints.IntValue, TEXT);
				STAMM_AddClientPoints(client, g_cLRPointsStammpoints.IntValue);	
			}

#if defined _store_included
			if ((g_cLRPointsMode.IntValue == 0 || g_cLRPointsMode.IntValue == 2) && g_cLRPointsStoreCredits.IntValue > 0)
			{
				CPrintToChatAll("%s%N %serhält %s%d Credits%s, da er der letzte Überlebende ist.", SPECIAL, client, TEXT, SPECIAL, g_cLRPointsStoreCredits.IntValue, TEXT);
				Store_SetClientCredits(client, Store_GetClientCredits(client) + g_cLRPointsStoreCredits.IntValue);	
			}
#endif
		}
		else
		{
			CPrintToChatAll("Die Runde muss mindestens 4 Minuten laufen und es müssen mind. 5 Spieler auf dem Server spielen, um extra Store Credits und/oder Stammpunkte zu bekommen.");
		}
	}
}

void ResetLrStammpunkte()
{
	g_bValidRound = false;

	delete g_hTimer;
}