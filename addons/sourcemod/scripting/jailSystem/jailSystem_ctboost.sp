void CTBoost_PlayerSpawn(int client)
{
	if (!g_cEnableCTBoost.BoolValue)
	{
		return;
	}

	if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		int iT = GetTeamClientCount(CS_TEAM_T);
		int iCT = GetTeamClientCount(CS_TEAM_CT);
		
		// Health
		if (g_cCTBoostHealth.BoolValue)
		{
			int iHP = RoundToCeil(iT / iCT * g_cCTBoostHealthMulti.FloatValue);
			int iNewHP = GetClientHealth(client) + iHP;
			SetEntityHealth(client, iNewHP);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", iNewHP);
		}
		
		
		// Armor
		if (g_cCTBoostArmor.BoolValue)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", GetEntProp(client, Prop_Send, "m_ArmorValue") + 110);
		}

		if (g_cCTBoostHelm.BoolValue)
		{
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		}
	}
}
