public Action STAMM_OnClientGetPoints_PRE(int client, int &points)
{
	if(!IsClientValid(client))
	{
		return Plugin_Continue;
	}
	
	bool changed = false;
	
	if(g_cEnableExtraPointsCT.BoolValue && GetClientTeam(client) == CS_TEAM_CT)
	{
		points *= 2;
		CPrintToChat(client, "Sie bekommen für das Spielen als CT's die %sdoppelte %sStammpunkte!", SPECIAL, TEXT);
		changed = true;
	}
	
	char sName[64], sTag[32];
	GetClientName(client, sName, sizeof(sName));
	CS_GetClientClanTag(client, sTag, sizeof(sTag));
	
	if	(	g_cEnableExtraPointsTag.BoolValue && 
			((StrContains(sName, "#DNG", false) != -1) || (StrContains(sName, "deadnationgaming.eu", false) != -1) || // Name Check
			(StrEqual(sTag, "#DNG", false)))
		)
	{
		int iPoints = GetRandomInt(1, 3);
		
		points += iPoints;
		
		CPrintToChat(client, "Sie haben für das Tragen des Community Tags %s%d %szusätzliche Stammpunkte bekommen!", SPECIAL, iPoints, TEXT);
		
		changed = true;
	}
	
	if(!changed)
	{
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Changed;
	}
}
