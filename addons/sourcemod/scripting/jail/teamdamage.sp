ConVar g_cvTeamdamage = null;
static g_iTime[MAXPLAYERS + 1] = { -1, ...};

public Action Command_teamdamage(int client, int args)
{
	if(IsClientValid(client))
	{
		if((IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && (g_iTime[client] == -1 || (g_iTime[client] + 5) < GetTime())) || CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			if(!g_cvTeamdamage.BoolValue)
			{
				g_cvTeamdamage.SetBool(true);
				CPrintToChatAll("Teamdamage wurde {green}aktiviert %svon %s%N%s.", TEXT, SPECIAL, client, TEXT);
			}
			else
			{
				g_cvTeamdamage.SetBool(false);
				CPrintToChatAll("Teamdamage wurde {darkred}deaktiviert %svon %s%N%s.", TEXT, SPECIAL, client, TEXT);
			}

			g_iTime[client] = GetTime();
		}
	}
	
	return Plugin_Handled;
}

void Teamdamage_OnPluginStart()
{
	g_cvTeamdamage = FindConVar("mp_teammates_are_enemies");
}

void Teamdamage_RoundEnd()
{
	g_cvTeamdamage.SetBool(false);
}