#include <sourcemod>

#define PLUGIN_VERSION "1.1.5"

public Plugin:myinfo = 
{
	name = "Anti Rejoin",
	author = "Bara (Original author: exvel)",
	description = "Blocking people for time from reconnecting",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new bool:g_bKickedByPlugin[MAXPLAYERS+1];

StringMap g_smPlayers = null;

//CVars' handles
ConVar cvar_ar_admin_immunity = null;

public OnPluginStart()
{
	if (g_smPlayers != null)
	{
		delete g_smPlayers;
	}

	g_smPlayers = new StringMap();
	
	CreateConVar("anti_rejoin_version", PLUGIN_VERSION, "Anti Rejoin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_ar_admin_immunity = CreateConVar("anti_rejoin_admin_immunity", "0", "0 = disabled, 1 = protect admins from Anti-Reconnect functionality", _, true, 0.0, true, 1.0);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	AutoExecConfig(true, "plugin.antireconnect");
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bKickedByPlugin[client] || !client)
		return;

	if (IsFakeClient(client))
		return;
	
	if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && cvar_ar_admin_immunity.BoolValue)
		return;
	
	decl String:steamId[30];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	g_smPlayers.SetValue(steamId, GetTime());
}

public OnClientPutInServer(client)
{
	g_bKickedByPlugin[client] = false;
	
	if ( client < 1 || IsFakeClient(client) || !IsClientConnected(client))
		return;

	int disconnect_time = -1;

	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	
	bool bExist = g_smPlayers.GetValue(auth, disconnect_time);

	if (!bExist)
	{
		disconnect_time = -1;
	}
	
	if (disconnect_time == -1)
		return;
	
	ConVar cvar = FindConVar("mp_join_grace_time");

	int iTime = -1;

	if (cvar != null)
	{
		iTime = cvar.IntValue + 3;
	}

	if (iTime == -1)
	{
		return;
	}

	new wait_time = disconnect_time + iTime - GetTime();
	
	if (wait_time <= 0)
	{
		g_smPlayers.Remove(auth);
	}
	else
	{
		g_bKickedByPlugin[client] = true;
		KickClient(client, "You are not allowed to reconnect for %d seconds", wait_time);
		LogAction(-1, client,"Kicked \"%L\". Player is not allowed to reconnect for %d seconds.", client, wait_time);
	}
}

public OnMapStart()
{
	if (g_smPlayers != null)
	{
		delete g_smPlayers;
	}

	g_smPlayers = new StringMap();
}
