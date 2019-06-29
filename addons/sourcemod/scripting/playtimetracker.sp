/*
    ToDo
        - Add first connection (with name)
        - Add last connection
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <dng-jail>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

enum PlayerTimes
{
    PlayerInfo_TimeT,
    PlayerInfo_TimeCT
};

Handle g_hSQL = null;

int g_iPlayerTime[MAXPLAYERS+1][PlayerTimes];

bool g_bLateLoaded;
bool g_bPlayerChecked[MAXPLAYERS+1];

int g_iSequence = -1;

ConVar g_cServerType = null;

#include "playtimetracker/stocks.sp"
#include "playtimetracker/connect.sp"
#include "playtimetracker/playtime.sp"
#include "playtimetracker/top.sp"
#include "playtimetracker/natives.sp"

public Plugin myinfo = 
{
    name = "Playtime Tracker",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "dng.xyz"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoaded = late;
    
    RegPluginLibrary("playtimetracker");
    
    CreateNative("PlayTimeTracker_GetPlayerTimeT", Native_GetPlayerTimeT);
    CreateNative("PlayTimeTracker_GetPlayerTimeCT", Native_GetPlayerTimeCT);
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_time", Cmd_PlayTime);
    RegConsoleCmd("sm_time10", Cmd_Top10);
    
    // Connect to database
    DatabaseInit();
    
    g_cServerType = CreateConVar("playtimetracker_server_type", "0", "Change team names... 0 - Normal, 1 - Jail");

    CSetPrefix("{darkred}[PT-Tracker]{default}");
}

public void OnMapStart()
{
    CreateTimer(1.0, CountPlayTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(60.0, SavePlayTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if(!IsFakeClient(client))
        GetPlayerTime(client);
}

public void OnClientDisconnect(int client)
{
    if(!IsFakeClient(client))
        SavePlayerTime(client);
    
    g_iPlayerTime[client][PlayerInfo_TimeT] = 0;
    g_iPlayerTime[client][PlayerInfo_TimeCT] = 0;
    g_bPlayerChecked[client] = false;
}

void SavePlayerTime(int client)
{
    if(!g_bPlayerChecked[client])
        return;
    
    char sAuth[32];
    
    if(GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth)))
    {
        char sName[MAX_NAME_LENGTH], sNameEscaped[MAX_NAME_LENGTH*2+1];
        GetClientName(client, sName, sizeof(sName));
        SQL_EscapeString(g_hSQL, sName, sNameEscaped, sizeof(sNameEscaped));
            
        int iTimeT = g_iPlayerTime[client][PlayerInfo_TimeT];
        int iTimeCT = g_iPlayerTime[client][PlayerInfo_TimeCT];
        
        char sQuery[1024];
        Format(sQuery, sizeof(sQuery), "INSERT INTO playtimetracker (steamid, playername, time_t, time_ct, time_total) VALUES ('%s', '%s', %d, %d, %d) \
                    ON DUPLICATE KEY UPDATE playername='%s', time_t='%d', time_ct='%d', time_total='%d';", sAuth, sNameEscaped, iTimeT, iTimeCT, iTimeT+iTimeCT, sNameEscaped, iTimeT, iTimeCT, iTimeT+iTimeCT);
        
        SQL_TQuery(g_hSQL, Query_DoNothing, sQuery);
    }
}

public Action CountPlayTime(Handle timer, any data)
{
    LoopClients(iClient)
    {
        if(g_bPlayerChecked[iClient])
        {
            int iTeam = GetClientTeam(iClient);
            
            if(iTeam == CS_TEAM_T)
            {
                ++g_iPlayerTime[iClient][PlayerInfo_TimeT];
            }
            else if(iTeam == CS_TEAM_CT)
            {
                ++g_iPlayerTime[iClient][PlayerInfo_TimeCT];
            }
        }
    }
}

public Action SavePlayTime(Handle timer, any data)
{
    LoopClients(iClient)
    {
        if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT)
        {
            SavePlayerTime(iClient);
        }
    }
    
    return Plugin_Continue;
}

public void Query_CheckPlayer(Handle owner, Handle hndl, const char[] error, any userid)
{
    if(hndl == null || strlen(error) > 0)
    {
        LogError("Failed to get player playtime: %s", error);
        return;
    }
    
    int client = GetClientOfUserId(userid);
    if(!client)
        return;
    
    // player is not in our db
    if(SQL_GetRowCount(hndl) == 0)
    {
        g_bPlayerChecked[client] = true;
        return;
    }
    
    g_bPlayerChecked[client] = true;
}