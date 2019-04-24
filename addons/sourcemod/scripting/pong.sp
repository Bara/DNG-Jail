#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <dng-jail>

#define PREFIX "{darkred}[Snake]{green} "

#define CHAR_PADLEFT "▐"
#define CHAR_PADRIGHT "▌"
#define CHAR_BALL "█"
#define CHAR_SPACE "░"
#define CHAR_WALL "█"

#define PONG_GAME_SIZE_Y 7
#define PONG_GAME_SIZE_X 20

#define PONG_PAD_FRAMERATE 12
#define PONG_BALL_FRAMERATE 4

#define PONG_COUNT_DOWN 3

#define UP 0
#define DOWN 1
#define LEFT 0
#define RIGHT 1

new g_iPongGameSession[MAXPLAYERS+1] = {-1,...};
new g_iPadPosition[MAXPLAYERS+1] = {6,...};

new Handle:g_hPongThink[32] = {INVALID_HANDLE,...};
new Handle:g_hPongCountdown[32] = {INVALID_HANDLE,...};
new g_iBallPosition[32][2];
new g_iBallDirection[32][2];
new g_iBallTick[32] = {0,...};
new g_iBallCountDown[32] = {PONG_COUNT_DOWN,...};

new g_iClientAttackCount[MAXPLAYERS+1] = {0,...};

// Max games
int g_iMax = 2;
int g_iMaxVIP = 4;
int g_iCount[MAXPLAYERS + 1] =  { 0, ... };

public Plugin:myinfo = 
{
	name = "Pong",
	author = "Bara (Peace-Maker)",
	description = "",
	version = "1.0.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath);
	
	RegConsoleCmd("sm_pong", Command_Pong, "Start a new Pong game.");
	RegConsoleCmd("sm_pquit", Command_QuitPong, "Surrender from your current pong game.");
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientValid(client))
		g_iCount[client] = 0;
}

public OnClientDisconnect(client)
{
	// Reset pong game
	g_iPadPosition[client] = PONG_GAME_SIZE_Y / 2;
	g_iClientAttackCount[client] = 0;
	if(g_iPongGameSession[client] != -1)
	{
		ClearTimer(g_hPongThink[g_iPongGameSession[client]]);
		ClearTimer(g_hPongThink[g_iPongGameSession[client]]);
		g_iBallPosition[g_iPongGameSession[client]][0] = -1;
		g_iBallPosition[g_iPongGameSession[client]][1] = -1;
		g_iBallDirection[g_iPongGameSession[client]][0] = -1;
		g_iBallDirection[g_iPongGameSession[client]][1] = -1;
		g_iBallTick[g_iPongGameSession[client]] = 0;
		g_iBallCountDown[g_iPongGameSession[client]] = PONG_COUNT_DOWN;
		
		// Inform the other player
		for(new i=1;i<=MaxClients;i++)
		{
			if(i != client && g_iPongGameSession[i] == g_iPongGameSession[client])
			{
				g_iPadPosition[i] = PONG_GAME_SIZE_Y / 2;
				g_iClientAttackCount[i] = 0;
				g_iPongGameSession[i] = -1;
				SetEntityMoveType(i, MOVETYPE_WALK);
				CPrintToChat(i, "%sYour opponent left.", PREFIX);
				break;
			}
		}
		
		g_iPongGameSession[client] = -1;
	}
}

public Action:Command_Pong(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(!ValidTeam(client))
		return Plugin_Handled;
	
	// He isn't playing pong already
	if(g_iPongGameSession[client] == -1)
	{
		if(!ValidTeam(client))
		{
			ReplyToCommand(client, "%sYou have to be dead to play Pong.", PREFIX);
			return Plugin_Handled;
		}
		
		new Handle:menu = CreateMenu(Menu_StartPong);
		SetMenuExitButton(menu, true);
		SetMenuTitle(menu, "Pong");
		AddMenuItem(menu, "chooseopponent", "Play against a player");
		AddMenuItem(menu, "computer", "Play against the computer");
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
		AddMenuItem(menu, "", "Use your walking keys to move up and down.", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
		AddMenuItem(menu, "", "Type \"!pquit\" to quit a pong game.", ITEMDRAW_DISABLED);
		
		DisplayMenu(menu, client, 20);
	}
	else
	{
		ReplyToCommand(client, "%sYou're already in a game! Write !pquit to surrender.", PREFIX);
	}
	

	return Plugin_Handled;
}

public Action:Command_QuitPong(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(g_iPongGameSession[client] != -1)
	{
		// Get the opponent
		new iOpponent = -1;
		for(new i=1;i<=MaxClients;i++)
		{
			if(i != client && g_iPongGameSession[i] == g_iPongGameSession[client])
			{
				iOpponent = i;
				break;
			}
		}
		
		ClearTimer(g_hPongThink[g_iPongGameSession[client]]);
		ClearTimer(g_hPongThink[g_iPongGameSession[client]]);
		g_iBallPosition[g_iPongGameSession[client]][0] = -1;
		g_iBallPosition[g_iPongGameSession[client]][1] = -1;
		g_iBallDirection[g_iPongGameSession[client]][0] = -1;
		g_iBallDirection[g_iPongGameSession[client]][1] = -1;
		g_iBallTick[g_iPongGameSession[client]] = 0;
		g_iBallCountDown[g_iPongGameSession[client]] = PONG_COUNT_DOWN;
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		// He's playing against the computer.
		if(iOpponent == -1)
		{
			g_iPadPosition[client] = PONG_GAME_SIZE_Y / 2;
			g_iClientAttackCount[client] = 0;
			g_iPongGameSession[client] = -1;
			CPrintToChat(client, "%sYou surrender. Computer won!", PREFIX);
		}
		else
		{
			g_iPadPosition[client] = PONG_GAME_SIZE_Y / 2;
			g_iClientAttackCount[client] = 0;
			g_iPongGameSession[client] = -1;
			g_iPadPosition[iOpponent] = PONG_GAME_SIZE_Y / 2;
			g_iClientAttackCount[iOpponent] = 0;
			g_iPongGameSession[iOpponent] = -1;
			SetEntityMoveType(iOpponent, MOVETYPE_WALK);
			CPrintToChat(client, "%sYou surrender. %N won!", PREFIX, iOpponent);
			CPrintToChat(iOpponent, "%s%N surrendered. You won!", PREFIX, client);
		}
		
	}
	else
	{
		ReplyToCommand(client, "%sYou're not in a game! Write !pong to start one.", PREFIX);
	}
	return Plugin_Handled;
}

public Menu_StartPong(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		// Show player list
		if(StrEqual(info, "chooseopponent"))
		{
			new Handle:menu2 = CreateMenu(Menu_SelectPlayer);
			SetMenuTitle(menu2, "Pong: Choose Opponent");
			SetMenuExitButton(menu2, true);
			
			decl String:user_id[12];
			decl String:name[MAX_NAME_LENGTH];
			decl String:display[MAX_NAME_LENGTH+12];
			new bool:bAddedPlayer = false;
			for (new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && i != param1 && g_iPongGameSession[i] == -1)
				{
					// Skip dead players
					if(!ValidTeam(i))
						continue;
					
					IntToString(GetClientUserId(i), user_id, sizeof(user_id));
					GetClientName(i, name, sizeof(name));
					Format(display, sizeof(display), "%s (%s)", name, user_id);
					AddMenuItem(menu2, user_id, display);
					bAddedPlayer = true;
				}
			}
			if(!bAddedPlayer)
			{
				CPrintToChat(param1, "%sNo players available.", PREFIX);
				CloseHandle(menu2);
			}
			else
				DisplayMenu(menu2, param1, 20);
		}
		// Start a game against the computer
		else if(StrEqual(info, "computer"))
		{
			StartPongSession(param1, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new iTarget = GetClientOfUserId(StringToInt(info));
		
		if(!IsClientInGame(iTarget))
		{
			CPrintToChat(param1, "%sTarget already left the server.", PREFIX);
			Command_Pong(param1, 0);
		}
		else if(g_iPongGameSession[iTarget] != -1)
		{
			CPrintToChat(param1, "%sTarget is currently in an other pong game.", PREFIX);
			CPrintToChat(iTarget, "%s%N wanted to play with you either.", PREFIX, param1);
			Command_Pong(param1, 0);
		}
		else if(!ValidTeam(param1))
		{
			CPrintToChat(param1, "%sYou have to be dead.", PREFIX);
		}
		else if(!ValidTeam(iTarget))
		{
			CPrintToChat(param1, "%sTarget has to be dead.", PREFIX);
			Command_Pong(param1, 0);
		}
		else
		{
			// Invite player to a game
			decl String:sBuffer[30];
			new Handle:menu2 = CreateMenu(Menu_AskPlayer);
			SetMenuTitle(menu2, "%N wants to play Pong with you!", param1);
			SetMenuExitButton(menu2, false);
			Format(sBuffer, sizeof(sBuffer), "1|%d", GetClientUserId(param1));
			AddMenuItem(menu2, sBuffer, "Let's play!");
			Format(sBuffer, sizeof(sBuffer), "0|%d", GetClientUserId(param1));
			AddMenuItem(menu2, sBuffer, "Not interested.");
			AddMenuItem(menu2, "", "", ITEMDRAW_SPACER);
			AddMenuItem(menu2, "", "Use your walking keys to move up and down.", ITEMDRAW_DISABLED);
			AddMenuItem(menu2, "", "", ITEMDRAW_SPACER);
			AddMenuItem(menu2, "", "Type \"!pquit\" to quit a pong game.", ITEMDRAW_DISABLED);
			
			DisplayMenu(menu2, iTarget, 15);
			CPrintToChat(param1, "%sSent an invitation to %N.", PREFIX, iTarget);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_AskPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], String:sAnswer[2];
		GetMenuItem(menu, param2, info, sizeof(info));
		SplitString(info, "|", sAnswer, sizeof(sAnswer));
		new iAsker = GetClientOfUserId(StringToInt(info[2]));
		
		// He denied
		if(StrEqual(sAnswer, "0"))
		{
			if(IsClientInGame(iAsker))
			{
				CPrintToChat(iAsker, "%s%N denied your invitation.", PREFIX, param1);
				CPrintToChat(param1, "%sYou denied %N's invitation.", PREFIX, iAsker);
			}
		}
		else
		{
			if(IsClientInGame(iAsker))
			{
				if(g_iPongGameSession[iAsker] != -1)
				{
					CPrintToChat(param1, "%s%N started a different pong game without you already.", PREFIX, iAsker);
					CPrintToChat(iAsker, "%s%N accepted your invitation, but you're in a game.", PREFIX, param1);
				}
				else
				{
					CPrintToChat(iAsker, "%s%N accepted your invitation.", PREFIX, param1);
					CPrintToChat(param1, "%sYou accepted %N's invitation.", PREFIX, iAsker);
					StartPongSession(iAsker, param1);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

StartPongSession(iFirstPlayer, iSecondPlayer)
{
	g_iCount[iFirstPlayer]++;
	if(IsClientValid(iSecondPlayer) && !IsFakeClient(iSecondPlayer))
		g_iCount[iSecondPlayer]++;
	
	// Get unused gamesession
	new bool:bSkip = false;
	for(new pgs=0;pgs<32;pgs++)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(g_iPongGameSession[i] == pgs)
			{
				bSkip = true;
				break;
			}
			else
				bSkip = false;
		}
		if(bSkip)
			continue;
		
		g_iPongGameSession[iFirstPlayer] = pgs;
		if(iSecondPlayer != -1)
			g_iPongGameSession[iSecondPlayer] = pgs;
		break;
	}
	g_iPadPosition[iFirstPlayer] = PONG_GAME_SIZE_Y / 2;
	g_iClientAttackCount[iFirstPlayer] = 0;
	if(iSecondPlayer != -1)
	{
		g_iPadPosition[iSecondPlayer] = PONG_GAME_SIZE_Y / 2;
		g_iClientAttackCount[iSecondPlayer] = 0;
	}
	
	// Ball direction
	g_iBallDirection[g_iPongGameSession[iFirstPlayer]][0] = GetRandomInt(0, 1); // x. 0=left, 1=right
	g_iBallDirection[g_iPongGameSession[iFirstPlayer]][1] = GetRandomInt(0, 1); // y. 0=up, 1=down
	
	// Ball position
	g_iBallPosition[g_iPongGameSession[iFirstPlayer]][0] = PONG_GAME_SIZE_X / 2;
	g_iBallPosition[g_iPongGameSession[iFirstPlayer]][1] = GetRandomInt(1, PONG_GAME_SIZE_Y);
	
	g_iBallTick[g_iPongGameSession[iFirstPlayer]] = 0;
	g_iBallCountDown[g_iPongGameSession[iFirstPlayer]] = 3;
	
	//PrintToServer("%N started a new Pong session. (#%d)", iFirstPlayer, g_iPongGameSession[iFirstPlayer]);
	
	if(iSecondPlayer == -1)
	{
		SetEntityMoveType(iFirstPlayer, MOVETYPE_NONE);
		CPrintToChat(iFirstPlayer, "%sStarted a new game against the computer. You're on the left. Use your walking keys to move up and down.", PREFIX);
	}
	else
	{
		SetEntityMoveType(iFirstPlayer, MOVETYPE_NONE);
		SetEntityMoveType(iSecondPlayer, MOVETYPE_NONE);
		if(iFirstPlayer < iSecondPlayer)
		{
			CPrintToChat(iFirstPlayer, "%sStarted a new game against %N. You're on the left.", PREFIX, iSecondPlayer);
			CPrintToChat(iSecondPlayer, "%sStarted a new game against %N. You're on the right.", PREFIX, iFirstPlayer);
		}
		else
		{
			CPrintToChat(iFirstPlayer, "%sStarted a new game against %N. You're on the right.", PREFIX, iSecondPlayer);
			CPrintToChat(iSecondPlayer, "%sStarted a new game against %N. You're on the left.", PREFIX, iFirstPlayer);
		}
	}
	g_hPongThink[g_iPongGameSession[iFirstPlayer]] = CreateTimer(0.1, Timer_DrawPong, g_iPongGameSession[iFirstPlayer], TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	g_hPongCountdown[g_iPongGameSession[iFirstPlayer]] = CreateTimer(1.0, Timer_CountDown, g_iPongGameSession[iFirstPlayer], TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action:Timer_DrawPong(Handle:timer, any:iPongGameSession)
{
	// Get who's on which side
	new iLeftPlayer = -1;
	new iRightPlayer = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if(g_iPongGameSession[i] == iPongGameSession)
		{
			if(iLeftPlayer == -1)
				iLeftPlayer = i;
			else
			{
				iRightPlayer = i;
				break;
			}
		}
	}
	
	// No players? Stop here.
	if(iLeftPlayer == -1 && iRightPlayer == -1)
	{
		g_hPongThink[iPongGameSession] = INVALID_HANDLE;
		ClearTimer(g_hPongCountdown[iPongGameSession]);
		return Plugin_Stop;
	}
	
	// Playing against the cpu
	if(iLeftPlayer == -1 || iRightPlayer == -1)
	{
		iLeftPlayer = (iLeftPlayer == -1?iRightPlayer:iLeftPlayer);
		iRightPlayer = -1;
	}
	// The lower client index is the left player
	else if(iLeftPlayer > iRightPlayer)
	{
		new iSwap = iLeftPlayer;
		iLeftPlayer = iRightPlayer;
		iRightPlayer = iSwap;
	}
	
	new Handle:panel = CreatePanel();
	decl String:sGameLine[PONG_GAME_SIZE_X*4+20];
	for(new i=1;i<=PONG_GAME_SIZE_Y;i++)
	{
		// Put in start line
		Format(sGameLine, sizeof(sGameLine), CHAR_WALL);
		
		// Draw left player
		if(g_iPadPosition[iLeftPlayer] == i)
		{
			Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_PADLEFT);
		}
		else
		{
			Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_SPACE);
		}
		
		// Fill the game field
		for(new x=1;x<=PONG_GAME_SIZE_X;x++)
		{
			// Countdown
			if(i == (PONG_GAME_SIZE_Y / 2) && x == (PONG_GAME_SIZE_X / 2) && g_iBallCountDown[iPongGameSession] > 0)
			{
				Format(sGameLine, sizeof(sGameLine), "%s%d", sGameLine, g_iBallCountDown[iPongGameSession]);
			}
			// Ball
			else if(g_iBallPosition[iPongGameSession][1] == i
				&& g_iBallPosition[iPongGameSession][0] == x)
			{
				Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_BALL);
			}
			else
			{
				Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_SPACE);
			}
		}
		
		// Computer player
		if(iRightPlayer == -1 && g_iBallPosition[iPongGameSession][1] == i)
		{
			Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_PADRIGHT);
		}
		// Draw right player
		else if(iRightPlayer != -1 && g_iPadPosition[iRightPlayer] == i)
		{
			Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_PADRIGHT);
		}
		else
			Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_SPACE);
		
		Format(sGameLine, sizeof(sGameLine), "%s%s", sGameLine, CHAR_WALL);
		DrawPanelText(panel, sGameLine);
	}
	
	SetPanelKeys(panel, (1<<9));
	SendPanelToClient(panel, iLeftPlayer, Menu_PongPanel, 5);
	if(iRightPlayer != -1)
		SendPanelToClient(panel, iRightPlayer, Menu_PongPanel, 5);
 
	CloseHandle(panel);
	
	// ****** Check for breakthroughs ******
	if(g_iBallPosition[iPongGameSession][0] <= 1
		&& g_iBallPosition[iPongGameSession][1] != g_iPadPosition[iLeftPlayer])
	{
		g_iPadPosition[iLeftPlayer] = PONG_GAME_SIZE_Y / 2;
		g_iClientAttackCount[iLeftPlayer] = 0;
		g_iPongGameSession[iLeftPlayer] = -1;
		g_iBallPosition[iPongGameSession][0] = -1;
		g_iBallPosition[iPongGameSession][1] = -1;
		g_iBallDirection[iPongGameSession][0] = -1;
		g_iBallDirection[iPongGameSession][1] = -1;
		g_iBallTick[iPongGameSession] = 0;
		g_iBallCountDown[iPongGameSession] = PONG_COUNT_DOWN;
		SetEntityMoveType(iLeftPlayer, MOVETYPE_WALK);
		
		//PrintToServer("Ball went through the left pad. Right player won!");
		
		if(iRightPlayer != -1)
		{
			CPrintToChat(iLeftPlayer, "%sYou loose. %N won!", PREFIX, iRightPlayer);
			CPrintToChat(iRightPlayer, "%sYou won. %N loose!", PREFIX, iLeftPlayer);
			g_iPadPosition[iRightPlayer] = PONG_GAME_SIZE_Y / 2;
			g_iClientAttackCount[iRightPlayer] = 0;
			g_iPongGameSession[iRightPlayer] = -1;
			SetEntityMoveType(iRightPlayer, MOVETYPE_WALK);
		}
		else
		{
			CPrintToChat(iLeftPlayer, "%sYou loose. Computer won!", PREFIX);
		}
		
		g_hPongThink[iPongGameSession] = INVALID_HANDLE;
		ClearTimer(g_hPongCountdown[iPongGameSession]);
		
		return Plugin_Stop;
	}
	
	if(iRightPlayer != -1 
	    && g_iBallPosition[iPongGameSession][0] >= PONG_GAME_SIZE_X
		&& g_iBallPosition[iPongGameSession][1] != g_iPadPosition[iRightPlayer])
	{
		g_iPadPosition[iRightPlayer] = PONG_GAME_SIZE_Y / 2;
		g_iClientAttackCount[iRightPlayer] = 0;
		g_iPongGameSession[iRightPlayer] = -1;
		g_iPadPosition[iLeftPlayer] = PONG_GAME_SIZE_Y / 2;
		g_iClientAttackCount[iLeftPlayer] = 0;
		g_iPongGameSession[iLeftPlayer] = -1;
		g_iBallPosition[iPongGameSession][0] = -1;
		g_iBallPosition[iPongGameSession][1] = -1;
		g_iBallDirection[iPongGameSession][0] = -1;
		g_iBallDirection[iPongGameSession][1] = -1;
		g_iBallTick[iPongGameSession] = 0;
		g_iBallCountDown[iPongGameSession] = PONG_COUNT_DOWN;
		SetEntityMoveType(iLeftPlayer, MOVETYPE_WALK);
		SetEntityMoveType(iRightPlayer, MOVETYPE_WALK);
		
		//PrintToServer("Ball went through the right pad. Left player won!");
		
		CPrintToChat(iRightPlayer, "%sYou loose. %N won!", PREFIX, iLeftPlayer);
		CPrintToChat(iLeftPlayer, "%sYou won. %N loose!", PREFIX, iRightPlayer);
		
		g_hPongThink[iPongGameSession] = INVALID_HANDLE;
		ClearTimer(g_hPongCountdown[iPongGameSession]);
		
		return Plugin_Stop;
	}
	
	// Start moving the ball after the countdown
	if(g_iBallCountDown[iPongGameSession] == 0 && g_iBallTick[iPongGameSession] == 0)
	{
		// Move the ball
		// moving left
		if(g_iBallDirection[iPongGameSession][0] == LEFT)
			g_iBallPosition[iPongGameSession][0]--;
		// moving right
		else
			g_iBallPosition[iPongGameSession][0]++;
		
		// moving up
		if(g_iBallDirection[iPongGameSession][1] == UP)
			g_iBallPosition[iPongGameSession][1]--;
		// moving down
		else
			g_iBallPosition[iPongGameSession][1]++;
		
		//PrintToServer("Ball position: x: %d y: %d, pad: %d", g_iBallPosition[iPongGameSession][0], g_iBallPosition[iPongGameSession][1], g_iPadPosition[iRightPlayer]);
	}
	
	// Only move the ball every PONG_BALL_FRAMERATE timer calls
	g_iBallTick[iPongGameSession]++;
	if(g_iBallTick[iPongGameSession] == PONG_BALL_FRAMERATE)
		g_iBallTick[iPongGameSession] = 0;
	
	// ****** Check for collisions ******
	// Ball hit the upper limit -> bounce down
	if(g_iBallPosition[iPongGameSession][1] < 1)
	{
		//PrintToServer("Ball hit upper limit: %d. Changing direction to DOWN, setting ball Y to 2, pad: %d", g_iBallPosition[iPongGameSession][1], (PONG_GAME_SIZE_Y-1), g_iPadPosition[iRightPlayer]);
		g_iBallPosition[iPongGameSession][1] = 2;
		g_iBallDirection[iPongGameSession][1] = DOWN;
	}
	// Ball hit the lower limit -> bounce up
	else if(g_iBallPosition[iPongGameSession][1] > PONG_GAME_SIZE_Y)
	{
		//PrintToServer("Ball hit lower limit: %d. Changing direction to UP, setting ball Y to %d, pad: %d", g_iBallPosition[iPongGameSession][1], (PONG_GAME_SIZE_Y-1), g_iPadPosition[iRightPlayer]);
		g_iBallPosition[iPongGameSession][1] = PONG_GAME_SIZE_Y-1;
		g_iBallDirection[iPongGameSession][1] = UP;
	}
	
	// Ball hit the left pad -> bounce right
	if(g_iBallPosition[iPongGameSession][0] == 1
		&& g_iBallPosition[iPongGameSession][1] == g_iPadPosition[iLeftPlayer])
	{
		//PrintToServer("Ball hit left paddle: %d. Changing direction to RIGHT, setting ball X to %d, pad: %d", g_iBallPosition[iPongGameSession][0], (g_iBallPosition[iPongGameSession][0]+1), g_iPadPosition[iLeftPlayer]);
		//g_iBallPosition[iPongGameSession][0]++;
		g_iBallDirection[iPongGameSession][0] = RIGHT;
	}
	// Ball hit the right pad -> bounce left
	else if(g_iBallPosition[iPongGameSession][0] == PONG_GAME_SIZE_X
		&& (iRightPlayer == -1
		|| g_iBallPosition[iPongGameSession][1] == g_iPadPosition[iRightPlayer]))
	{
		//PrintToServer("Ball hit right paddle: %d. Changing direction to LEFT, setting ball X to %d, pad: %d", g_iBallPosition[iPongGameSession][0], (g_iBallPosition[iPongGameSession][0]-1), g_iPadPosition[iRightPlayer]);
		//g_iBallPosition[iPongGameSession][0]--;
		g_iBallDirection[iPongGameSession][0] = LEFT;
	}
	
	return Plugin_Continue;
}

public Action:Timer_CountDown(Handle:timer, any:iPongGameSession)
{
	g_iBallCountDown[iPongGameSession]--;
	if(g_iBallCountDown[iPongGameSession] == 0)
	{
		g_hPongCountdown[iPongGameSession] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Menu_PongPanel(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		// surrender
		if(param2 == 9)
		{
			Command_QuitPong(param1, 0);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_iPongGameSession[client] != -1)
	{
		if(buttons & IN_FORWARD && buttons & IN_BACK)
		{
			buttons &= ~IN_FORWARD;
			buttons &= ~IN_BACK;
			return Plugin_Changed;
		}
		
		// Moving paddle down
		if(buttons & IN_BACK)
		{
			if(g_iClientAttackCount[client] == 0)
			{
				g_iPadPosition[client]++;
				if(g_iPadPosition[client] > PONG_GAME_SIZE_Y)
					g_iPadPosition[client] = PONG_GAME_SIZE_Y;
			}
			g_iClientAttackCount[client]++;
			if(g_iClientAttackCount[client] == PONG_PAD_FRAMERATE)
				g_iClientAttackCount[client] = 0;
			
			buttons &= ~IN_BACK;
			return Plugin_Changed;
		}
		else if(buttons & IN_FORWARD)
		{
			if(g_iClientAttackCount[client] == 0)
			{
				g_iPadPosition[client]--;
				if(g_iPadPosition[client] == 0)
					g_iPadPosition[client] = 1;
			}
			
			g_iClientAttackCount[client]++;
			if(g_iClientAttackCount[client] == PONG_PAD_FRAMERATE)
				g_iClientAttackCount[client] = 0;
			
			buttons &= ~IN_FORWARD;
			return Plugin_Changed;
		}
		else
		{
			g_iClientAttackCount[client] = 0;
		}
	}
	
	return Plugin_Continue;
}

stock ClearTimer(&Handle:timer, bool:autoClose=false)
{
	if(timer != INVALID_HANDLE)
		KillTimer(timer, autoClose);
	timer = INVALID_HANDLE;
}

stock bool ValidTeam(int client)
{
	if(!IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		int itMax = -1;
		
		if(CheckCommandAccess(client, "snake_admin", ADMFLAG_CUSTOM4, true))
			itMax = g_iMaxVIP;
		else
			itMax = g_iMax;
		
		if(g_iCount[client] < itMax)
			return true;
	}
	return false;
}
