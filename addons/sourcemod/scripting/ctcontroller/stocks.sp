void ConnectToSQL()
{
    SQL_TConnect(sqlConnect, "ctcontroller");
}

void CreateTable()
{
    char sQuery[1024];
    Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `ct_controller` ( `id` INT NOT NULL AUTO_INCREMENT, `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `communityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `verify` tinyint(1) DEFAULT 0, `verifyAdmin` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT '', `banned` tinyint(1) DEFAULT 0, `rounds` int(11) DEFAULT 0, `banAdmin` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT '', `banReason` text COLLATE utf8mb4_unicode_ci DEFAULT '', `unbanAdmin` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT '', PRIMARY KEY (`id`), UNIQUE KEY (`communityid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    
    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }
    
    g_dDB.Query(sqlCreateTable, sQuery);
}

void ShowCTVerifyList(int client)
{
    Panel panel = new Panel();
    char sTitle[128];
    Format(sTitle, sizeof(sTitle), "%T", "Menu: Verify List", client);
    panel.SetTitle(sTitle);
    
    char sName[MAX_NAME_LENGTH];
    bool bFound = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientValid(i))
        {
            if(g_bVerify[i])
            {
                bFound = true;
                Format(sName, sizeof(sName), "%N", i);
                panel.DrawText(sName);
            }
        }
    }
    
    if(!bFound)
    {
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "%T", "Menu: No players", client);
        panel.DrawText(sBuffer);
    }
    
    char sBuffer[128];
    Format(sBuffer, sizeof(sBuffer), "%T", "Menu: Close", client);
    panel.DrawItem(sBuffer);
    panel.Send(client, Panel_DeleteHandle, g_cTime.IntValue);
}

void ShowCTBanList(int client)
{
    Panel panel = new Panel();
    char sTitle[128];
    Format(sTitle, sizeof(sTitle), "%T", "Menu: CTBan List", client);
    panel.SetTitle(sTitle);
    
    char sName[MAX_NAME_LENGTH];
    bool bFound = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientValid(i))
        {
            if(g_bBanned[i])
            {
                bFound = true;
                GetClientName(i, sName, sizeof(sName));
                
                if (g_iRounds[i] > 0)
                {
                    if (g_iRounds[i] == 1)
                    {
                        Format(sName, sizeof(sName), "%s [1 Runde]", sName);
                    }
                    else
                    {
                        Format(sName, sizeof(sName), "%s [%d Runden]", sName, g_iRounds[i]);
                    }
                        
                }
                else if (g_iRounds[i] == 0)
                {
                    Format(sName, sizeof(sName), "%s [Perma]", sName);
                }
                
                panel.DrawText(sName);
            }
        }
    }
    
    if(!bFound)
    {
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "%T", "Menu: No ctban players", client);
        panel.DrawText(sBuffer);
    }
    
    char sBuffer[128];
    Format(sBuffer, sizeof(sBuffer), "%T", "Menu: Close", client);
    panel.DrawItem(sBuffer);
    panel.Send(client, Panel_DeleteHandle, g_cTime.IntValue);
}

void LoadClient(int client)
{
    char sQuery[512];
    
    Format(sQuery, sizeof(sQuery), "SELECT verify, banned, rounds, banReason FROM ct_controller WHERE communityid = \"%s\" ORDER BY id DESC LIMIT 1;", g_sClientID[client]);
    
    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }
    
    g_dDB.Query(sqlLoadClient, sQuery, GetClientUserId(client));
}

void VerifyClient(int target, int admin)
{
    char sQuery[1024];
    char sID[24], sAID[24];
    
    if(!GetClientAuthId(target, AuthId_SteamID64, sID, sizeof(sID)))
        return;
    
    if (!GetClientAuthId(admin, AuthId_SteamID64, sAID, sizeof(sAID)))
        return;
    
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `ct_controller` (`communityid`, `name`, `verify`, `verifyAdmin`) VALUES (\"%s\", \"%N\", 1, \"%s\") ON DUPLICATE KEY UPDATE name = \"%N\", verify = '1', verifyAdmin = \"%s\";", sID, target, sAID, target, sAID);

    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }

    CT_LogAction(admin, target, sID, "verify", 1, -1, "", sAID);
    g_dDB.Query(sqlVeriyClient, sQuery, GetClientUserId(target));
    
    g_bVerify[target] = true;
    
    for (int i = 1; i <= MaxClients; i++)
        if(IsClientValid(i))
            CPrintToChat(i, "%T", "Verify Player", i, target, admin);
    
    LogMessage("\"%L\" verified \"%L\"", admin, target);
}

void UnVerifyClient(int target, int admin)
{
    char sQuery[1024];
    char sID[24], sAID[24];
    
    if(!GetClientAuthId(target, AuthId_SteamID64, sID, sizeof(sID)))
        return;
    
    if (!GetClientAuthId(admin, AuthId_SteamID64, sAID, sizeof(sAID)))
        return;

    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `ct_controller` (`communityid`, `name`, `verify`) VALUES (\"%s\", \"%N\", 0) ON DUPLICATE KEY UPDATE name = \"%N\", verify = '0';", sID, target, target);

    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }

    CT_LogAction(admin, target, sID, "verify", 0, -1, "", sAID);
    g_dDB.Query(sqlVeriyClient, sQuery, GetClientUserId(target));
    
    g_bVerify[target] = false;
    
    for (int i = 1; i <= MaxClients; i++)
        if(IsClientValid(i))
            CPrintToChat(i, "%T", "UnVerify Player", i, target, admin);
    
    LogMessage("\"%L\" unverified \"%L\"", admin, target);
}

void TempVerifyClient(int target, int admin)
{
    g_bVerify[target] = true;
    for (int i = 1; i <= MaxClients; i++)
        if(IsClientValid(i))
            CPrintToChat(i, "%T", "Tmp Verify Player", i, target, admin);
    
    char sID[24], sAID[24];
    
    if(!GetClientAuthId(target, AuthId_SteamID64, sID, sizeof(sID)))
        return;
    
    if (!GetClientAuthId(admin, AuthId_SteamID64, sAID, sizeof(sAID)))
        return;
    
    CT_LogAction(admin, target, sID, "tmp verify", 1, -1, "", sAID);
    
    g_bVerify[target] = true;
    
    LogMessage("\"%L\" temporarily verified \"%L\"", admin, target);
}

void UnTempVerifyClient(int target, int admin)
{
    g_bVerify[target] = false;
    for (int i = 1; i <= MaxClients; i++)
        if(IsClientValid(i))
            CPrintToChat(i, "%T", "Tmp UnVerify Player", i, target, admin);
    
    char sID[24], sAID[24];
    
    if(!GetClientAuthId(target, AuthId_SteamID64, sID, sizeof(sID)))
        return;
    
    if (!GetClientAuthId(admin, AuthId_SteamID64, sAID, sizeof(sAID)))
        return;
    
    CT_LogAction(admin, target, sID, "tmp unverify", 0, -1, "", sAID);
    
    g_bVerify[target] = false;
    
    LogMessage("\"%L\" temp unverified \"%L\"", admin, target);
}

void BanCTClient(int target, int admin, int rounds, const char[] sReason)
{
    char sQuery[1024];
    char sID[24], sAID[24];
    
    if(!GetClientAuthId(target, AuthId_SteamID64, sID, sizeof(sID)))
        return;
    
    if (!GetClientAuthId(admin, AuthId_SteamID64, sAID, sizeof(sAID)))
        return;
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO `ct_controller` (`communityid`, `name`, `banned`, `rounds`, `banAdmin`, `banReason`) VALUES (\"%s\", \"%N\", 1, %d, \"%s\", \"%s\") ON DUPLICATE KEY UPDATE name = \"%N\", banned = '1', rounds = %d, banAdmin = \"%s\", banReason = \"%s\", verify = '0';", sID, target, rounds, sAID, sReason, target, rounds, sAID, sReason);
    
    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }
        
    CT_LogAction(admin, target, sID, "ctban", 1, rounds, sReason, sAID);
    g_dDB.Query(sqlCTBanClient, sQuery, GetClientUserId(target));
    
    g_bBanned[target] = true;
    g_iRounds[target] = rounds;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientValid(i))
        {
            if (rounds == 0)
            {
                CPrintToChat(i, "%T", "CTBan Player Perma", i, target, admin, sReason);
            }
            else if (rounds == 1)
            {
                CPrintToChat(i, "%T", "CTBan Player Round", i, target, admin, sReason);
            }
            else
            {
                CPrintToChat(i, "%T", "CTBan Player Rounds", i, target, admin, sReason, rounds);
            }
        }
    }
    
    LogMessage("\"%L\" was ct banned \"%L\" (Rounds: %d, Reason: %s)", admin, target, rounds, sReason);

    strcopy(g_sReason[target], sizeof(g_sReason[]), sReason);

    PerformDiscord(admin, target, rounds, sReason);
    
    PlayBlockSound(target);
    
    if(GetClientTeam(target) == CS_TEAM_CT)
    {
        Action res = Plugin_Continue;
        Call_StartForward(g_hOnPlayerCheck);
        Call_PushCell(target);
        Call_Finish(res);

        if (res == Plugin_Handled || res == Plugin_Stop)
        {
            return;
        }

        ForcePlayerSuicide(target);
        ChangeClientTeam(target, CS_TEAM_T);
    }
}

void UnBanCTClient(int target, int admin)
{
    char sQuery[512];
    char sID[24], sAID[24], sName[MAX_NAME_LENGTH];
    
    if(!GetClientAuthId(target, AuthId_SteamID64, sID, sizeof(sID)))
        return;
    
    if (IsClientValid(admin))
    {
        if (!GetClientAuthId(admin, AuthId_SteamID64, sAID, sizeof(sAID)))
        {
            return;
        }
    }
    else if (admin == -1)
    {
        Format(sAID, sizeof(sAID), "0");
    }

    if(!GetClientName(target, sName, sizeof(sName)))
        return;
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO `ct_controller` (`communityid`, `name`, `banned`) VALUES (\"%s\", \"%N\", 0) ON DUPLICATE KEY UPDATE name = \"%N\", banned = '0', unbanAdmin = \"%s\";", sID, target, target, sAID);
    
    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }
        
    CT_LogAction(admin, target, sID, "ctunban", 0, -1, "", sAID);
    g_dDB.Query(sqlCTUnBanClient, sQuery, GetClientUserId(target));
    
    g_bBanned[target] = false;
    g_iRounds[target] = -1;
    
    if (IsClientValid(admin))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if(IsClientValid(i))
            {
                CPrintToChat(i, "%T", "UnCTBan Player", i, target, admin);
            }
        }
        
        LogMessage("\"%L\" was ct unbanned \"%L\"", admin, target);
    }
    else
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if(IsClientValid(i))
            {
                CPrintToChat(i, "{lightblue}%N {default}ist nun {lightblue}nicht mehr {default}vom CT-Team gebannt!", target);
            }
        }
        
        LogMessage("\"%L\" was ct unbanned", target);
    }
}

bool IsValidCT(int client, bool blockMessage = false)
{
    if(!g_bReady[client] && !CTC_HasFlags(client, "b"))
    {
        if (!blockMessage)
        {
            LogMessage("\"%L\" tried to join ct! (Rejected: g_bReady is false) (g_sClientID: %s) (preValid: %d)", client, g_sClientID[client], preIsClientValid(client));
            CPrintToChat(client, "Sie sind noch nicht bereit...");
        }
        return false;
    }

    bool bAllow = false;
    Action res = Plugin_Continue;
    Call_StartForward(g_hOnValidCheck);
    Call_PushCell(client);
    Call_PushCellRef(bAllow);
    Call_Finish(res);

    if (res == Plugin_Changed)
    {
        return bAllow;
    }
    
    if(g_bBanned[client])
    {
        if (!blockMessage)
        {
            LogMessage("\"%L\" tried to join ct! (Rejected: g_bBanned is true)", client);
            CPrintToChat(client, "{default}Sie sind vom CT-Team {lightblue}gebannt{default}. Melde dich dafür bitte {lightblue}im Forum{default}.");
        }
        return false;
    }
    
    bool bSkip = false;

    if (g_bKnockout && IsClientKnockout(client))
    {
        bSkip = true;
    }

    if(bSkip && SourceComms_GetClientMuteType(client) != bNot)
    {
        if (!blockMessage)
        {
            LogMessage("\"%L\" tried to join ct! (Rejected: SourceComms_GetClientMuteType != bNot)", client);
            CPrintToChat(client, "{lightblue}Stummgeschaltene Spieler {default}können kein CT spielen. Melde dich dafür bitte {lightblue}im Forum{default}.");
        }
        return false;
    }

    if (g_cStammPoints.IntValue == 0)
    {
        return true;
    }
    
    if (g_bStamm)
    {
        if (!g_bVerify[client] && (STAMM_GetClientPoints(client) < g_cStammPoints.IntValue))
        {
            if (!blockMessage)
            {
                if (STAMM_GetClientPoints(client) < g_cStammPoints.IntValue)
                {
                    LogMessage("\"%L\" tried to join ct! (Rejected: g_bVerify is false", client);
                    CPrintToChat(client, "{default}Sie sind {lightblue}nicht freigeschaltet{default}! Melde dich dafür bitte {lightblue}im Forum{default}.");

                    return false;
                }

                if (!g_bVerify[client])
                {
                    LogMessage("\"%L\" tried to join ct! (Rejected: STAMM_GetClientPoints (%d))", client, STAMM_GetClientPoints(client));
                    CPrintToChat(client, "{default}Sie haben {lightblue}nicht genügend Stammpunkte{default}! Vorausgesetzt sind{lightblue} %d Stammpunkte{default}.", g_cStammPoints.IntValue);

                    return false;
                }
            }
        }
    }
    else
    {
        if (!g_bVerify[client])
        {
            if (!blockMessage)
            {
                if (!g_bVerify[client])
                {
                    LogMessage("\"%L\" tried to join ct! (Rejected: STAMM_GetClientPoints (%d))", client, STAMM_GetClientPoints(client));
                    CPrintToChat(client, "{default}Sie haben {lightblue}nicht genügend Stammpunkte{default}! Vorausgesetzt sind{lightblue} %d Stammpunkte{default}.", g_cStammPoints.IntValue);

                    return false;
                }
            }
        }
    }
    
    return true;
}

// CT_LogAction(admin, target, sID, "ctunban", false, "", sAID);
void CT_LogAction(int admin, int target, const char[] communityid, const char[] action, int value, int rounds, const char[] reason, const char[] adminid)
{
    if (!StrEqual(adminid, "0", false))
    {
        if(StrEqual(action, "ctban", false))
        {
            LogAction(admin, target, "\"%L\" %s \"%L\" (Rounds: %d, Reason: %s)", admin, action, target, rounds, reason);
        }
        else
        {
            LogAction(admin, target, "\"%L\" %s \"%L\"", admin, action, target);
        }
    }
    else
    {
        LogAction(0, target, "%s \"%L\"", action, target);
    }
        
    char sQuery[512];
    
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `ct_controller_logs` (`communityid`, `name`, `action`, `value`, `rounds`, `reason`, `adminid`, `date`) VALUES (\"%s\", \"%N\", \"%s\", '%d', '%d', \"%s\", \"%s\", UNIX_TIMESTAMP());", communityid, target, action, value, rounds, reason, adminid);
    
    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }
    
    g_dDB.Query(sqlInsertLog, sQuery);
}

bool preIsClientValid(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
        {
            return true;
        }
    }

    return false;
}

public void PlayBlockSound(int client)
{
    int clients[1];
    clients[0] = client;
    EmitSoundAny(clients, 1, SOUND);

}

void UpdateCTBan(int client)
{
    // -1 = Perma
    if (g_iRounds[client] > 1)
    {
        g_iRounds[client]--;
        
        char sRound[12];
        
        if (g_iRounds[client] == 1)
        {
            Format(sRound, sizeof(sRound), "Runde");
        }
        else
        {
            Format(sRound, sizeof(sRound), "Runden");
        }
        
        SetRounds(client, g_iRounds[client]);
        
        CPrintToChat(client, "{default}Du bist noch {lightblue}%d %s {default}vom CT-Team gebannt!", g_iRounds[client], sRound);
        
        return;
    }
    else if (g_iRounds[client] == 1)
    {
        UnBanCTClient(client, -1);
    }
}

void SetRounds(int client, int rounds)
{
    char sID[24];
    
    if(!GetClientAuthId(client, AuthId_SteamID64, sID, sizeof(sID)))
        return;
        
    char sQuery[1024];
    Format(sQuery, sizeof(sQuery), "UPDATE ct_controller SET rounds = %d WHERE communityid = \"%s\" AND banned = 1 ORDER BY id DESC LIMIT 1;", rounds, sID);
    
    if(bLogMessage && bDebug)
    {
        LogMessage(sQuery);
    }
    
    g_dDB.Query(sqlUpdateRounds, sQuery);
}

void PerformDiscord(int client, int target, int rounds, const char[] reason)
{
    char sMap[16];
    GetCurrentMap(sMap, sizeof(sMap));

    char sColor[8];
    g_cColor.GetString(sColor, sizeof(sColor));
    
    char sAuth[32];
    GetClientAuthId(target, AuthId_Steam2, sAuth, sizeof(sAuth));
    
    char sName[MAX_NAME_LENGTH + 18];
    Format(sName, sizeof(sName), "%N (%s)", target, sAuth);
    
    char sAdmin[MAX_NAME_LENGTH + 18];
    if(client && IsClientInGame(client))
    {
        char sAAuth[32];
        GetClientAuthId(client, AuthId_Steam2, sAAuth, sizeof(sAAuth));

        Format(sAdmin, sizeof(sAdmin), "%N (%s)", client, sAAuth);
    }
    else
    {
        sAdmin = "CONSOLE";
    }
    
    char sLength[32];
    if(rounds == 0)
    {
        Format(sLength, sizeof(sLength), "Permanent");
    }
    else if (rounds == 1)
    {
        Format(sLength, sizeof(sLength), "%d Round", rounds);
    }
    else if (rounds > 1)
    {
        Format(sLength, sizeof(sLength), "%d Rounds", rounds);
    }
    
    EscapeString(sName, strlen(sName));
    EscapeString(sAdmin, strlen(sAdmin));
    
    char sWebhook[32];
    g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
    
    DiscordWebHook hook = new DiscordWebHook(sWebhook);
    hook.SlackMode = true;

    hook.SetUsername("CT Controller");

    char sHostname[512], sIP[24], sLink[512];
    int iPort = CallAdmin_GetHostPort();
    CallAdmin_GetHostName(sHostname, sizeof(sHostname));

    int iPieces[4];
    SteamWorks_GetPublicIP(iPieces);
    Format(sIP, sizeof(sIP), "%d.%d.%d.%d", iPieces[0], iPieces[1], iPieces[2], iPieces[3]);

    Format(sLink, sizeof(sLink), "(steam://connect/%s:%d) # %s%s-%d%d", sIP, iPort, g_sSymbols[GetRandomInt(0, 25-1)], g_sSymbols[GetRandomInt(0, 25-1)], GetRandomInt(0, 9), GetRandomInt(0, 9));

    MessageEmbed Embed = new MessageEmbed();
    Embed.SetColor(sColor);
    Embed.AddField(sHostname, sLink, false);
    Embed.AddField("Map", sMap, false);
    Embed.AddField("Player", sName, true);
    Embed.AddField("Admin", sAdmin, true);
    Embed.AddField("Length", sLength, true);
    Embed.AddField("Reason", reason, true);

    hook.Embed(Embed);
    // hookTracker.Embed(Embed);
    hook.Send();
    // hookTracker.Send();
    delete hook;
    // delete hookTracker;
}

stock void EscapeString(char[] string, int maxlen)
{
    ReplaceString(string, maxlen, "@", "＠");
    ReplaceString(string, maxlen, "'", "＇");
    ReplaceString(string, maxlen, "\"", "＂");
}

stock bool IsClientValid(int client, bool bots = false)
{
    if (client > 0 && client <= MaxClients)
    {
        if(IsClientInGame(client) && (bots || !IsFakeClient(client)) && !IsClientSourceTV(client))
        {
            return true;
        }
    }
    
    return false;
}

stock bool CTC_HasFlags(int client, const char[] flags)
{
    AdminFlag aFlags[16];
    FlagBitsToArray(ReadFlagString(flags), aFlags, sizeof(aFlags));
    
    return HasFlags(client, aFlags);
}

stock bool HasFlags(int client, AdminFlag flags[16])
{
    int iFlags = GetUserFlagBits(client);
    
    if (iFlags & ADMFLAG_ROOT)
        return true;
    
    for (int i = 0; i < sizeof(flags); i++)
        if (iFlags & FlagToBit(flags[i]))
            return true;
    
    return false;
}
