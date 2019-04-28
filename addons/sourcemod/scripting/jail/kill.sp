public Action Command_kill(int client, int args)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
				
				CPrintToChatAll("%s%N %shat sich selbst erschlagen!", SPECIAL, client, TEXT);
			}
			else
			{
				CPrintToChat(client, "Das ergibt keinen Sinn..?!");
			}
		}
		else
		{
			CPrintToChat(client, "Das ergibt keinen Sinn..?!");
		}
	}
	
	return Plugin_Handled;
}

public Action ConsoleKill(int client, const char[] command, int argc)
{
	if(IsClientValid(client) && IsPlayerAlive(client))
	{
		CPrintToChatAll("%s%N %shat sich selbst erschlagen!", SPECIAL, client, TEXT);
	}
}

void Kill_OnPluginStart()
{
	AddCommandListener(ConsoleKill, "kill");
}