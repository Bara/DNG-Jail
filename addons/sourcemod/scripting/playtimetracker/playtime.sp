public Action Cmd_PlayTime(int client, int args)
{
    if(!client)
    {
        ReplyToCommand(client, "[SM] command ingame only!");
        return Plugin_Handled;
    }
    
    char sAuth[32], sQuery[512];
    
    GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth));
    
    Format(sQuery, sizeof(sQuery), "SELECT time_t, time_ct, time_total FROM playtimetracker WHERE steamid='%s';", sAuth);
    SQL_TQuery(g_hSQL, Query_ShowPlayTimeTracker, sQuery, GetClientUserId(client));	
    
    return Plugin_Handled;
}

public void Query_ShowPlayTimeTracker(Handle owner, Handle hndl, const char[] error, any userid)
{
    if(hndl == null || strlen(error) > 0)
    {
        LogError("Failed to get player playtime (command): %s", error);
        return;
    }
    
    int client = GetClientOfUserId(userid);

    if (!client || GetClientTeam(client) == CS_TEAM_NONE || GetClientTeam(client) == CS_TEAM_SPECTATOR)
        return;
    
    // player is not in our db
    if(SQL_GetRowCount(hndl) == 0)
    {
        CPrintToChat(client, "You're not in our database.");
        return;
    }
    
    char sName[MAX_NAME_LENGTH], sBuffer[512];
    int iTimeT, iTimeCT, iTimeTotal;
    
    GetClientName(client, sName, sizeof(sName));
    
    while(SQL_FetchRow(hndl))
    {
        // get times
        iTimeT = SQL_FetchInt(hndl, 0);
        iTimeCT = SQL_FetchInt(hndl, 1);
        iTimeTotal = SQL_FetchInt(hndl, 2);
    }
    
    // T
    int iHoursT = (iTimeT/60/60);
    int iMinutesT = (iTimeT/60)%(60);
    //int iSecondsT = (iTimeT%60);
    
    // CT
    int iHoursCT = (iTimeCT/60/60);
    int iMinutesCT = (iTimeCT/60)%(60);
    //int iSecondsCT = (iTimeCT%60);
    
    // Total
    int iHoursTotal = (iTimeTotal/60/60);
    int iMinutesTotal = (iTimeTotal/60)%(60);
    //int iSecondsTotal = (iTimeTotal%60);
        
    // Menu
    Handle hMenu = CreateMenu(MenuHandler_PlayerTime);
    
    if(iMinutesTotal > 0 || iHoursTotal > 0 )
    {
        int type = g_cServerType.IntValue;
        
        SetMenuTitle(hMenu, "Playtime Overview:");
        
        if(type == 0)
            AddMenuItem(hMenu, "", "Playtime as terrorist:");
        else if(type == 1)
            AddMenuItem(hMenu, "", "Playtime as prisoner:");
        
        Format(sBuffer, sizeof(sBuffer), "%d hours %d minute(s)", iHoursT, iMinutesT);
        AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
        
        if(type == 0)
            AddMenuItem(hMenu, "", "Playtime as counter terrorist:");
        else if(type == 1)
            AddMenuItem(hMenu, "", "Playtime as guard:");
        
        Format(sBuffer, sizeof(sBuffer), "%d hours %d minute(s)", iHoursCT, iMinutesCT);
        AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
        AddMenuItem(hMenu, "", "Total playtime:");
        Format(sBuffer, sizeof(sBuffer), "%d hours %d minute(s)", iHoursTotal, iMinutesTotal);
        AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
        SetMenuExitButton(hMenu, true);
        DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
    }
    
    /* char sText[128];
    
    if (GetClientTeam(client) == CS_TEAM_CT)
        Format(sText, sizeof(sText), "{fullred}%d{gold}std. {fullred}%d{gold}min. {blue}[CT]{gold}", iHoursCT, iMinutesCT);
    else if (GetClientTeam(client) == CS_TEAM_T)
        Format(sText, sizeof(sText), "{fullred}%d{gold}std. {fullred}%d{gold}min. {red}[T]{gold}", iHoursT, iMinutesT);
    
    CPrintToChatAll("%s%s spielt seit %s und {lightgreen}%d{default}std. {lightgreen}%d{default}min. [Insgesamt]", OB, sName, sText, iHoursTotal, iMinutesTotal); */
}

public int MenuHandler_PlayerTime(Handle hMenu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(hMenu);
}