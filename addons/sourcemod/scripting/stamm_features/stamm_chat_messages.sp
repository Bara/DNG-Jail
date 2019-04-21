/**
 * -----------------------------------------------------
 * File        stamm_chat_messages.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */


// Icnludes
#include <sourcemod>
#include <sdktools>
#include <dng-jail>
#include <stamm>
#include <cstrike>

#pragma semicolon 1




new g_iWelcome = -1;




public Plugin:myinfo =
{
	name = "[Outbreak] Dis-Connect Messages",
	author = "Bara ( Popoklopsi )",
	version = "1.4.0",
	description = "",
	url = ""
};



public OnPluginStart()
{
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);
}

public Action:Event_PlayerConnect(Event event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (STAMM_IsClientValid(client))
	{
			event.BroadcastDisabled = true;
			return Plugin_Changed;
	}
	return Plugin_Continue;
}


public Action:Event_PlayerDisconnect(Event event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (STAMM_IsClientValid(client))
	{
			event.BroadcastDisabled = true;
			return Plugin_Changed;
	}
	return Plugin_Continue;
}


// ADd Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();	
	STAMM_RegisterFeature("VIP Chat Messages");
}




// Feature loaded
public STAMM_OnFeatureLoaded(const String:basename[])
{

	// Get Blocks
	g_iWelcome = STAMM_GetBlockOfName("welcome");
	

	if (g_iWelcome == -1)
	{
		SetFailState("Found neither block welcome nor block leave!");
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	if (block == g_iWelcome)
	{
		Format(fmt, sizeof(fmt), "%T", "GetWelcomeMessages", client);
		
		PushArrayString(array, fmt);
	}
}




// Client Ready
public STAMM_OnClientReady(client)
{
	if (IsClientValid(client) && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
		return;
	
	decl String:name[MAX_NAME_LENGTH + 1];
	decl String:tag[64];


	GetClientName(client, name, sizeof(name));
	STAMM_GetTag(tag, sizeof(tag));


	// Gets a welcome message?
	if (g_iWelcome != -1 && STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client, g_iWelcome))
	{
		CPrintToChatAll("%s %t", tag, "WelcomeMessage", name);
	}
	else
		CPrintToChatAll("%s %s%N %shat das Spiel betreten.", SPECIAL, client, TEXT);
}
