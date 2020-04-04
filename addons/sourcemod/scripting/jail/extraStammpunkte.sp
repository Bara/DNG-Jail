public Action STAMM_OnClientGetPoints_PRE(int client, int &points)
{
	if(!IsClientValid(client))
	{
		return Plugin_Continue;
	}
	
	bool changed = false;
	
	if(g_cEnableExtraPointsCT.BoolValue && GetClientTeam(client) == CS_TEAM_CT)
	{
		points *= ((g_cPlayAsCT.FloatValue / 100) + 1.0);
		CPrintToChat(client, "Sie bekommen für das Spielen als CT's die %sdoppelte %sStammpunkte!", SPECIAL, TEXT);
		changed = true;
	}
	
	char sName[64], sTag[32];
	GetClientName(client, sName, sizeof(sName));
	CS_GetClientClanTag(client, sTag, sizeof(sTag));

	char sPTag[32], sPDomain[64];
	g_cPTag.GetString(sPTag, sizeof(sPTag));
	g_cPDomain.GetString(sPDomain, sizeof(sPDomain));
	
	if	(	g_cEnableExtraPointsTag.BoolValue && 
			((StrContains(sName, sPTag, false) != -1) || (StrContains(sName, sPDomain, false) != -1) || // Name Check
			(StrEqual(sTag, sPTag, false)))
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
