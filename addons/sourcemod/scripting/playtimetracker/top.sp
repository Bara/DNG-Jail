public Action Cmd_Top10(int client, int args)
{
    if(!client)
    {
        ReplyToCommand(client, "[SM] command ingame only!");
        return Plugin_Handled;
    }
    
    char sQuery[512];
    
    Format(sQuery, sizeof(sQuery), "SELECT steamid, playername, time_total FROM playtimetracker WHERE time_total >= 60 ORDER BY time_total DESC LIMIT 10");
    SQL_TQuery(g_hSQL, Query_ShowPlayerTop10, sQuery, GetClientUserId(client));
    
    return Plugin_Handled;
}

public void Query_ShowPlayerTop10(Handle owner, Handle hndl, const char[] error, any userid)
{
    if(hndl == null || strlen(error) > 0)
    {
        LogError("Failed to get player top10: %s", error);
        return;
    }
    
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    Handle hMenu = CreateMenu(MenuHandler_Top10);
    
    char sName[MAX_NAME_LENGTH], sOption[64], sBuffer[256];
    int iOrder = 0;
    
    if(SQL_HasResultSet(hndl))
    {
        SetMenuTitle(hMenu, "Top 10 Playtime:");
        
        while(SQL_FetchRow(hndl))
        {
            iOrder++;
            
            Format(sOption, sizeof(sOption), "option_%i", iOrder);
            
            SQL_FetchString(hndl, 1, sName, sizeof(sName));
            
            int iTimeTotal = SQL_FetchInt(hndl, 2);
            int iHoursTotal = (iTimeTotal/60/60);
            int iMinutesTotal = (iTimeTotal/60)%(60);
            //int iSecondsTotal = (iTimeTotal%60);
            
            Format(sBuffer, sizeof(sBuffer), "%s - %dstd. %dmin.", sName, iHoursTotal, iMinutesTotal);
            
            AddMenuItem(hMenu, sOption, sBuffer, ITEMDRAW_DISABLED);
        }
    }	
    
    if(iOrder < 1)
        AddMenuItem(hMenu, "", "No players found...", ITEMDRAW_DISABLED);
    
    SetMenuExitButton(hMenu, true);
    DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Top10(Handle hMenu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(hMenu);
}