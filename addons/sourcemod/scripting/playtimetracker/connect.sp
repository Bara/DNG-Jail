void DatabaseInit()
{
    SQL_TConnect(OnDatabaseConnected, "player_analytics", ++g_iSequence);
}

public void OnDatabaseConnected(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == null || strlen(error) > 0)
    {
        SetFailState("Error initializing database: %s", error);
        return;
    }
    
    // Ignore old connection attempts.
    if(g_iSequence != data)
    {
        CloseHandle(hndl);
        return;
    }
    
    g_hSQL = CloneHandle(hndl);
    
    // Set default charset
    
    SQL_SetCharset(g_hSQL, "utf8mb4");
    SQL_TQuery(g_hSQL, Query_DoNothing, "SET NAMES 'utf8mb4';");
    
    char sDefaultCharset[32]/*, sQuery[1024]*/;
    strcopy(sDefaultCharset, sizeof(sDefaultCharset), " ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    
    // Create table query
    
    /* Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `playtimetracker` (`id` int unsigned not null PRIMARY KEY AUTO_INCREMENT,`steamid` varchar(32) UNIQUE NOT NULL, `playername` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `time_t` int NOT NULL, `time_ct` int NOT NULL, `time_total` int NOT NULL)%s", sDefaultCharset);
    SQL_TQuery(g_hSQL, Query_DoNothing, sQuery); */
    
    if (g_bLateLoaded)
        LoopClients(iClient)
            GetPlayerTime(iClient);
}

/* Get playtime for a player */

void GetPlayerTime(int client)
{
    g_bPlayerChecked[client] = false;
    
    char sAuth[32], sQuery[512];
    if (GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth)))
    {
        Format(sQuery, sizeof(sQuery), "SELECT steamid, playername, time_t, time_ct FROM playtimetracker WHERE steamid='%s';", sAuth);
        SQL_TQuery(g_hSQL, Query_GetPlayerTime, sQuery, GetClientUserId(client));
    }
}

public void Query_GetPlayerTime(Handle owner, Handle hndl, const char[] error, any userid)
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
    
    while(SQL_FetchRow(hndl))
    {
        g_iPlayerTime[client][PlayerInfo_TimeT] = SQL_FetchInt(hndl, 2);
        g_iPlayerTime[client][PlayerInfo_TimeCT] = SQL_FetchInt(hndl, 3);
    }
    
    g_bPlayerChecked[client] = true;
}