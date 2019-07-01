public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ValidRound_ResetRoundStuff();
	
	LoopClients(client)
	{
		if (g_bBanned[client] && g_iRounds[client] > 0)
		{
			ValidRound_ResetClientStuff(client);
		}
	}
	
	int iCount = 0;
	LoopClients(i)
	{
		if (IsClientValid(i))
		{
			if (GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
			{
				if (!g_bBanned[i])
				{
					iCount++;
				}
			}
		}
	}
	
	if (!IsFreeday() && (iCount >= 8))
	{
		g_bRoundStarted = true;
		g_iRoundStart = GetTime();
		
		float fGraceTime = g_cGraceTime.FloatValue + 1.0;
		
		g_hGraceTimer = CreateTimer(fGraceTime, Timer_CheckValidRound, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRoundStarted && (g_iRoundStart + 300) <= GetTime())
	{
		LogMessage("[VALID ROUND] Start: %d, End: %d, Started: %d", g_iRoundStart, GetTime(), g_bRoundStarted);

		CPrintToChatAll("{default}Dies war eine {lightblue}valide Runde{default}!");
		
		LoopClients(client)
		{
			if (g_bBanned[client] && g_bInRound[client])
			{
				UpdateCTBan(client);
				
				ValidRound_ResetClientStuff(client);
			}
		}
	}
	
	ValidRound_ResetRoundStuff();
}

public Action Timer_CheckValidRound(Handle timer)
{
	if (g_bRoundStarted)
	{
		LoopClients(client)
		{
			if (GetClientTeam(client) == CS_TEAM_T && g_bBanned[client] && g_iRounds[client] > 0)
			{
				g_bInRound[client] = true;
			}
		}
	}
	
	g_hGraceTimer = null;
	return Plugin_Stop;
}

void ValidRound_JoinTeam(int client, int team)
{
	if (g_bBanned[client] && g_iRounds[client] > 0 && g_bInRound[client] && team != CS_TEAM_T)
	{
		g_bInRound[client] = false;
	}
}

void ValidRound_ResetRoundStuff()
{
	g_iRoundStart = -1;
	g_bRoundStarted = false;
	
	delete g_hGraceTimer;
	g_hGraceTimer = null;
}

void ValidRound_ResetClientStuff(int client)
{
	g_bInRound[client] = false;
}

bool IsFreeday()
{
	int iCTCount = GetTeamClientCount(CS_TEAM_CT);
	int iTCount = GetTeamClientCount(CS_TEAM_T);
	
	if(iCTCount > 1 && iTCount > 1)
	{
		int iFreedayteams = iTCount / 2;
	
		if(iFreedayteams < iCTCount)
		{
			return true;
		}
	}
	
	return false;
}

