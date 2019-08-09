public Action cmd_stop(int client, int args)
{
	if (MyJailbreak_IsEventDayRunning())
	{
		return;
	}

	if (g_iPlayers[client][INGAME])
	{
		if (g_bAllowStop)
		{
			Stop_View_Client(client);
		}
		else CPrintToChat(client, "%T", "DDR_Please_Wait", client, g_sLogo[client]);
	}
	else CPrintToChat(client, "%T", "DDR_Not_InGame", client, g_sLogo[client]);
}

public Action cmd_reset(int client, int args)
{
	if (MyJailbreak_IsEventDayRunning())
	{
		return Plugin_Handled;
	}
	
	if (!DNG_HasFlags(client, "b") && (GetClientTeam(client) != CS_TEAM_CT || !IsPlayerAlive(client)))
	{
		return Plugin_Handled;
	}
	
	FullReset();
	
	LoopClients(j)
		CPrintToChat(j, "%T", "DDR_Admin_Reset", j, g_sLogo[j], client);
	
	CPrintToChatAll("{lightblue}Während eines Freeday ist {green}!reset {lightblue}verboten! Versucht es mit {green}!stopm{lightblue}!!!");
	
	return Plugin_Handled;
}

public Action cmd_start(int client, int args)
{
	if (MyJailbreak_IsEventDayRunning())
	{
		return Plugin_Handled;
	}
	
	if (!DNG_HasFlags(client, "b") && (GetClientTeam(client) != CS_TEAM_CT || !IsPlayerAlive(client)))
	{
		return Plugin_Handled;
	}
	
	if (g_iCountdown > 6 && g_iCountdown < 30)
		g_iCountdown = 6;
	
	return Plugin_Handled;
}

public Action cmd_stopm(int client, int args)
{
	if (MyJailbreak_IsEventDayRunning())
	{
		return;
	}
	
	if (g_iLastPlayedId != -1)
	{
		char sPath[256];
		ArrayMusicFile.GetString(g_iLastPlayedId, sPath, sizeof(sPath));
		Format(sPath, sizeof(sPath), "%s/%s", PATH_SOUND_SONGS, sPath);
		PrintToChat(client, sPath);
		StopSoundAny(client, SNDCHAN_VOICE, sPath);
	}
}
