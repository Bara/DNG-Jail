#define TIME_VERWEIGERN 30.0

bool g_bVerweigern[MAXPLAYERS + 1] =  { false, ... };

Handle g_hVerweigernTimer[MAXPLAYERS + 1] =  { null, ... };


public Action Command_vreset(int client, int args)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_CT || CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		{
			char sTarget[256];
			GetCmdArgString(sTarget, sizeof(sTarget));
			
			int target = Client_FindByName(sTarget, true, false);
			if(target == -1)
			{
				return Plugin_Handled;
			}
			
			if(!g_bVerweigern[target] || !IsPlayerAlive(target))
			{
				return Plugin_Handled;
			}
			
			CPrintToChatAll("%s%N %sdarf durch %s%N %snun erneut verweigern.", SPECIAL, target, TEXT, SPECIAL, client, TEXT);
			g_bVerweigern[target] = false;
		}
	}
	
	return Plugin_Handled;
}

stock int Client_FindByName(const char[] name, bool partOfName = true, bool caseSensitive = false)
{
	char clientName[MAX_NAME_LENGTH];
	for (int client=1; client <= MaxClients; client++) {
		if (!IsClientAuthorized(client)) {
			continue;
		}

		GetClientName(client, clientName, sizeof(clientName));

		if (partOfName) {
			if (StrContains(clientName, name, caseSensitive) != -1) {
				return client;
			}
		}
		else if (StrEqual(name, clientName, caseSensitive)) {
			return client;
		}
	}

	return -1;
}

public Action Command_verweigern(int client, int args)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client))
		{
			if(!g_bVerweigern[client])
			{
				g_bVerweigern[client] = true;
				CPrintToChatAll("%s%N %shat das Spiel verweigert!", SPECIAL, client, TEXT);
				
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 0, 255, 255);
				
				g_hVerweigernTimer[client] = CreateTimer(TIME_VERWEIGERN, VerweigernTimer, client);
			}
			else
			{
				CPrintToChat(client, "Du hast bereits verweigert.");
			}
		}
		else
		{
			CPrintToChat(client, "Du bist tot oder kein Terrorist.");
		}
	}
	
	return Plugin_Handled;
}

public Action VerweigernTimer(Handle timer, any client)
{
	if(IsClientValid(client) && g_hVerweigernTimer[client] != null)
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	
	g_hVerweigernTimer[client] = null;
	return Plugin_Stop;
}

void ResetVerweigern(int client)
{
	g_bVerweigern[client] = false;
	delete g_hVerweigernTimer[client];
}