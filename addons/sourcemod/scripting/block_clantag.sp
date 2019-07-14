#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

float g_TagChangedTime[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[Outbreak] Block ClanTag Spam",
	author = "Bara",
	description = "",
	version = "1.0",
	url = ""
};

public void OnClientConnected(int client)
{
	g_TagChangedTime[client] = 0.0;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char sCmd[64];
	
	if (kv.GetSectionName(sCmd, sizeof(sCmd)) && StrEqual(sCmd, "ClanTagChanged", false))
	{
		if (g_TagChangedTime[client] && GetGameTime() - g_TagChangedTime[client] <= 5.0)
			return Plugin_Handled;
		
		g_TagChangedTime[client] = GetGameTime();
	}
	
	return Plugin_Continue;
}
