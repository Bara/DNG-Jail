void SecondsToTime(float seconds, char[] buffer, int maxlength, int precision)
{
	int t = RoundToFloor(seconds);
	
	int hour, mins;
	
	if (t >= 3600)
	{
		hour = RoundToFloor(t / 3600.0);
		t = t % 3600;
	}
	
	if (t >= 60)
	{
		mins = RoundToFloor(t / 60.0);
		t = t % 60;
	}
	
	Format(buffer, maxlength, "");
	
	if (hour)
		Format(buffer, maxlength, "%s%02d:", buffer, hour);
	
	Format(buffer, maxlength, "%s%02d:", buffer, mins);
	
	if (precision == 1)
		Format(buffer, maxlength, "%s%04.1f", buffer, view_as<float>(t) + seconds - RoundToFloor(seconds));
	else if (precision == 2)
		Format(buffer, maxlength, "%s%05.2f", buffer, view_as<float>(t) + seconds - RoundToFloor(seconds));
	else if (precision == 3)
		Format(buffer, maxlength, "%s%06.3f", buffer, view_as<float>(t) + seconds - RoundToFloor(seconds));
	else
		Format(buffer, maxlength, "%s%02d", buffer, t);
}

void FullReset()
{
	status = STATUS_NO_WAITLIST;
	
	for (int z = 0; z < MAX_SEQUENCE_LINES; z++)
	{
		TrashTimer(g_hSequenceTimer[z]);
		for (int x = 1; x <= MaxClients; x++)
			g_bHUDArrowCanView[x][z] = false;
	}
	
	Timer_EndMusic(null, 0);
}

float GetSequenceTimeLeft()
{
	return (float(g_iTicksCount) / 1000) - (GetGameTime() - g_fPlayStartTime);
}

void LoadDifficulties()
{
	char sFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sFile, sizeof(sFile), "%s/difficulties.cfg", PATH_CONFIG);
	
	if(!FileExists(sFile))
	{
		SetFailState("(FileExists) Can't read %s", sFile);
		return;
	}
	
	KeyValues kv = new KeyValues("Difficulties");
	
	if(!kv.ImportFromFile(sFile))
	{
		SetFailState("(ImportFromFile) Can't read %s", sFile);
		delete kv;
		return;
	}
	
	if(!kv.GotoFirstSubKey())
	{
		SetFailState("(ImportFromFile) Can't read %s", sFile);
		delete kv;
		return;
	}

	do
	{
		char sID[4];
		kv.GetSectionName(sID, sizeof(sID));
		int id = StringToInt(sID);
		
		g_iDifficulty[id][dID] = id;
		kv.GetString("upperName", g_iDifficulty[id][upperName], 64);
		kv.GetString("lowerName", g_iDifficulty[id][lowerName], 64);
		kv.GetString("shortName", g_iDifficulty[id][shortName], 3);
		kv.GetString("color", g_iDifficulty[id][color], 32);
		g_iDifficulty[id][arrowSpeed] = kv.GetFloat("arrowSpeed");
		g_iDifficulty[id][multiplicator] = kv.GetFloat("multiplicator");
		g_iDifficulty[id][perfectCombo] = kv.GetFloat("perfectCombo");
		g_iDifficulty[id][perfectComboDiff] = kv.GetFloat("perfectComboDiff");
		
		LogMessage("ID: %d, uName: %s, lName: %s, sName %s, Color: %s, aSpeed: %f, multiplicator: %f, pCombo: %f, pComboDiff: %f",
		g_iDifficulty[id][dID], g_iDifficulty[id][upperName], g_iDifficulty[id][lowerName], g_iDifficulty[id][shortName], g_iDifficulty[id][color], g_iDifficulty[id][arrowSpeed], g_iDifficulty[id][multiplicator], g_iDifficulty[id][perfectCombo], g_iDifficulty[id][perfectComboDiff]);
	} while (kv.GotoNextKey());

	delete kv;
}

void ResetWaitlist()
{
	if (ArrayWaitListSongIDClientID != null)
		ArrayWaitListSongIDClientID.Clear();
	
	if (ArrayWaitListSongID != null)
		ArrayWaitListSongID.Clear();
	
	if (ArrayWaitListDifficulty != null)
		ArrayWaitListDifficulty.Clear();
	
	ArrayWaitListSongIDClientID = new ArrayList();
	ArrayWaitListSongID = new ArrayList();
	ArrayWaitListDifficulty = new ArrayList();
	status = STATUS_NO_WAITLIST;
}

bool IsClientInZone(int client)
{
	bool bZone = false;
	int iType = 0;
	
	if (g_bZone1[client])
	{
		iType = 1;
		bZone = true;
	}
	
	if (g_bZone2[client])
	{
		iType = 2;
		bZone = true;
	}
	
	if (g_bZone3[client])
	{
		iType = 3;
		bZone = true;
	}
	
	if (g_bSolo[client])
	{
		iType = 4;
		bZone = true;
	}
	
	if (g_bTeam1[client])
	{
		iType = 5;
		bZone = true;
	}
	
	if (g_bTeam2[client])
	{
		iType = 6;
		bZone = true;
	}
	
	if (g_bSpec[client])
	{
		iType = 7;
		bZone = true;
	}
	
	if (g_iPlayers[client][INGAME])
	{
		iType = 8;
		bZone = true;
	}
	
	LoopClients(i)
	{
		if (!IsPlayerAlive(client))
		{
			int iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			
			if (iSpecMode == SPEC_FIRSTPERSON || iSpecMode == SPEC_3RDPERSON)
			{
				int iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				
				if (QuickZoneCheck(i))
				{
					if (iTarget == i)
					{
						iType = 9;
						bZone = true;
					}
				}
			}
		}
		
		char sAuth[64];
		GetClientAuthId(i, AuthId_SteamID64, sAuth, sizeof(sAuth));
		
		if (StrEqual(sAuth, "76561198041923231", false))
		{
			if(bZone)
			{
				if (iType == 9)
				{
					PrintToConsole(i, "Name: %N - Type: %d (SPECTATOR)", client, iType);
				}
				else if (iType > 0 && iType < 9)
				{
					PrintToConsole(i, "Name: %N - Type: %d", client, iType);
				}
			}
		}
	}
	
	return bZone;
}

bool QuickZoneCheck(int client)
{
	if (g_bZone1[client])
	{
		return true;
	}
	
	if (g_bZone2[client])
	{
		return true;
	}
	
	if (g_bZone3[client])
	{
		return true;
	}
	
	if (g_bSolo[client])
	{
		return true;
	}
	
	if (g_bTeam1[client])
	{
		return true;
	}
	
	if (g_bTeam2[client])
	{
		return true;
	}
	
	if (g_bSpec[client])
	{
		return true;
	}
	
	if (g_iPlayers[client][INGAME])
	{
		return true;
	}
	
	return false;
}
