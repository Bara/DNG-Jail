bool g_bMuteAlive[MAXPLAYERS + 1] =  { false, ... };
bool g_bMuteDeath[MAXPLAYERS + 1] =  { false, ... };
bool g_bMuteAll[MAXPLAYERS + 1] =  { false, ... };
bool g_bToAlive[MAXPLAYERS + 1] =  { false, ... };
bool g_bToDeath[MAXPLAYERS + 1] =  { false, ... };
bool g_bToBoth[MAXPLAYERS + 1] =  { false, ... };

void VoiceMenu_OnPluginStart()
{
	RegConsoleCmd("sm_voice", Command_VoiceMenu);
	
	CreateTimer(1.0, Timer_SetVoiceState, _, TIMER_REPEAT);
}

public Action Command_VoiceMenu(int client, int args)
{
	if (!g_cEnableVoiceMenu.BoolValue)
	{
		return Plugin_Handled;
	}

	if(!IsClientValid(client))
		return Plugin_Handled;
	
	int team = GetClientTeam(client);
	
	if(team != CS_TEAM_T && team != CS_TEAM_CT && team != CS_TEAM_SPECTATOR)
		return Plugin_Handled;
	
	if(IsPlayerAlive(client))
		return Plugin_Handled;
	
	VoiceMenu_PlayerDeath(client);
	
	return Plugin_Continue;
}

public Action Timer_SetVoiceState(Handle timer)
{
	if (!g_cEnableVoiceMenu.BoolValue)
	{
		return;
	}

	LoopClients(client)
	{
		int team = GetClientTeam(client);
		
		if((team == CS_TEAM_CT || team == CS_TEAM_T) && !IsPlayerAlive(client))
		{
			LoopClients(i)
			{
				int iTeam2 = GetClientTeam(i);
				if(iTeam2 == CS_TEAM_CT || iTeam2 == CS_TEAM_T)
				{
					if(g_bMuteAlive[client])
					{
						if(IsPlayerAlive(i))
						{
							if (!IsClientAdmin(client) && IsClientAdmin(i))
							{
								SetListenOverride(client, i, Listen_Yes);
								SetListenOverride(i, client, Listen_No);
							}
							else
							{
								SetListenOverride(client, i, Listen_No);
								SetListenOverride(i, client, Listen_No);
							}
						}
						else
						{
							SetListenOverride(client, i, Listen_Yes);
							SetListenOverride(i, client, Listen_Yes);
						}
					}
					else if (g_bMuteDeath[client])
					{
						if(IsPlayerAlive(i))
						{
							SetListenOverride(client, i, Listen_Yes);
							SetListenOverride(i, client, Listen_No);
						}
						else
						{
							if (!IsClientAdmin(client) && IsClientAdmin(i))
							{
								SetListenOverride(client, i, Listen_Yes);
								SetListenOverride(i, client, Listen_No);
							}
							else
							{
								SetListenOverride(client, i, Listen_No);
								SetListenOverride(i, client, Listen_No);
							}
						}
					}
					else if (g_bMuteAll[client])
					{
						if (!IsClientAdmin(client) && IsClientAdmin(i))
						{
							SetListenOverride(client, i, Listen_Yes);
							SetListenOverride(i, client, Listen_No);
						}
						else
						{
							SetListenOverride(client, i, Listen_No);
							SetListenOverride(i, client, Listen_No);
						}
					}
					else if (g_bToAlive[client])
					{
						if(IsPlayerAlive(i))
						{
							SetListenOverride(client, i, Listen_Yes);
							SetListenOverride(i, client, Listen_Yes);
						}
						else
						{
							SetListenOverride(client, i, Listen_No);
							SetListenOverride(i, client, Listen_No);
						}
					}
					else if (g_bToDeath[client])
					{
						if(IsPlayerAlive(i))
						{
							SetListenOverride(client, i, Listen_No);
							SetListenOverride(i, client, Listen_No);
						}
						else
						{
							SetListenOverride(client, i, Listen_Yes);
							SetListenOverride(i, client, Listen_Yes);
						}
					}
					else if (g_bToBoth[client])
					{
						SetListenOverride(client, i, Listen_Yes);
						SetListenOverride(i, client, Listen_Yes);
					}
				}
			}
		}
	}
}

void VoiceMenu_PlayerDeath(int client)
{
	Menu menu = new Menu(Menu_VoiceMenu);
	
	menu.SetTitle("Voice Menu\nEs ist nur eine Option möglich!");
	
	if(g_bMuteAlive[client])
		menu.AddItem("muteAlive", "Lebende muten", ITEMDRAW_DISABLED);
	else
		menu.AddItem("muteAlive", "Lebende muten");
	
	if(g_bMuteDeath[client])
		menu.AddItem("muteDeath", "Tote muten", ITEMDRAW_DISABLED);
	else
		menu.AddItem("muteDeath", "Tote muten");
		
	if(g_bMuteAll[client])
		menu.AddItem("muteAll", "Alle muten", ITEMDRAW_DISABLED);
	else
		menu.AddItem("muteAll", "Alle muten");
	
	if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		if(g_bToAlive[client])
			menu.AddItem("toAlive", "Zu Lebenden reden (muted Tote beidseitig)", ITEMDRAW_DISABLED);
		else
			menu.AddItem("toAlive", "Zu Lebenden reden (muted Tote beidseitig)");
		
		if(g_bToDeath[client])
			menu.AddItem("toDeath", "Zu Toten reden (muted Lebende beidseitig)", ITEMDRAW_DISABLED);
		else
			menu.AddItem("toDeath", "Zu Toten reden (muted Lebende beidseitig)");
		
		if(g_bToBoth[client])
			menu.AddItem("toBoth", "Zu allen gleichzeitig reden", ITEMDRAW_DISABLED);
		else
			menu.AddItem("toBoth", "Zu allen gleichzeitig reden");
	}
	
	menu.AddItem("reset", "Reset (Standard)");
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_VoiceMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client))
			return;
		
		char sOption[MAX_NAME_LENGTH];
		menu.GetItem(param, sOption, sizeof(sOption));
		
		// Reset all options
		VoiceMenu_ResetSettings(client);
		
		// Check if player is death
		if (IsPlayerAlive(client))
			return;
		
		// Set new option
		if(StrEqual(sOption, "muteAlive", false))
			g_bMuteAlive[client] = true;
		else if(StrEqual(sOption, "muteDeath", false))
			g_bMuteDeath[client] = true;
		else if(StrEqual(sOption, "muteAll", false))
			g_bMuteAll[client] = true;
		else if(StrEqual(sOption, "toAlive", false))
			g_bToAlive[client] = true;
		else if(StrEqual(sOption, "toDeath", false))
			g_bToDeath[client] = true;
		else if(StrEqual(sOption, "toBoth", false))
			g_bToBoth[client] = true;
		else if(StrEqual(sOption, "reset", false))
			VoiceMenu_ResetSettings(client);
		
		// Re-Open menu after selection
		VoiceMenu_PlayerDeath(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

void VoiceMenu_ResetSettings(int client)
{
	g_bMuteAlive[client] = false;
	g_bMuteDeath[client] = false;
	g_bMuteAll[client] = false;
	g_bToAlive[client] = false;
	g_bToDeath[client] = false;
	g_bToBoth[client] = false;
	
	LoopClients(i)
	{
		SetListenOverride(i, client, Listen_Default);
		SetListenOverride(client, i, Listen_Default);
	}
}