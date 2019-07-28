#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dng-jail>
#include <voiceannounce_ex>

#define SPRITE_PATH_VMT "materials/sprites/sg_micicon64.vmt"
#define SPRITE_PATH_VTF "materials/sprites/sg_micicon64.vtf"

#define SPRITE_SCALE		"0.3"
#define SPRITE_HEIGHT		80.0
#define SPRITE_DUCK_DIFF	18.0

int g_iSpriteEntRef[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };

public Plugin myinfo =
{
	name = "[Outbreak] Voice-Icon",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "outbreak-community.de"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
	AddFileToDownloadsTable(SPRITE_PATH_VMT);
	AddFileToDownloadsTable(SPRITE_PATH_VTF);
	PrecacheModel(SPRITE_PATH_VMT, true);
	
	CreateTimer(0.2, Timer_Update, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client)
{
	g_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect(int client)
{
	ResetSprite(client);
}

public void OnClientSpeakingEx(int client)
{
	if(!IsClientValid(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if(GetClientListeningFlags(client) == VOICE_MUTED)
	{
		return;
	}
	
	CreateSprite(client);
}

public void OnClientSpeakingEnd(int client)
{
	ResetSprite(client);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientValid(client))
	{
		return Plugin_Continue;
	}

	ResetSprite(client);

	return Plugin_Continue;
}

public void ResetSprite(int client)
{
	if(g_iSpriteEntRef[client] == INVALID_ENT_REFERENCE)
	{
		return;
	}

	int iEntity = EntRefToEntIndex(g_iSpriteEntRef[client]);
	g_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
	
	if(iEntity == INVALID_ENT_REFERENCE)
	{
		return;
	}

	AcceptEntityInput(iEntity, "Kill");
}

public void CreateSprite(int client)
{
	if(g_iSpriteEntRef[client] != INVALID_ENT_REFERENCE)
	{
		ResetSprite(client);
	}
	
	int sprite = CreateEntityByName("env_sprite_oriented");
	
	if(sprite != -1)
	{
		DispatchKeyValue(sprite, "classname", "env_sprite_oriented");
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "scale", SPRITE_SCALE);
		DispatchKeyValue(sprite, "rendermode", "1");
		DispatchKeyValue(sprite, "rendercolor", "255 255 255");
		DispatchKeyValue(sprite, "model", SPRITE_PATH_VMT);
		DispatchSpawn(sprite);
		
		float fPos[3];
		GetClientAbsOrigin(client, fPos);
		
		fPos[2] += SPRITE_HEIGHT;
		
		if(GetClientButtons(client) & IN_DUCK)
		{
			fPos[2] -= SPRITE_DUCK_DIFF;
		}

		TeleportEntity(sprite, fPos, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", client);
	}
	
	g_iSpriteEntRef[client] = EntIndexToEntRef(sprite);
}

public Action Timer_Update(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
			
		if(!IsPlayerAlive(i))
		{
			continue;
		}
			
		if(IsFakeClient(i))
		{
			continue;
		}
			
		if(!IsClientSpeaking(i))
		{
			continue;
		}
		
		if(GetClientListeningFlags(i) == VOICE_MUTED)
		{
			continue;
		}
		
		CreateSprite(i);
	}
	
	return Plugin_Continue;
}