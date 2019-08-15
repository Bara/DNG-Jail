#pragma semicolon 1

#include <sourcemod>
#include <store>
#include <stamm>
#include <multicolors>

#pragma newdecls required // Stamm don't have new syntax...

Database g_dDB = null;

ArrayList g_aWhitelist = null;

char g_sFile[PLATFORM_MAX_PATH + 1];

public Plugin myinfo =
{
    name = "Whitelist - Bonus",
    author = "Bara",
    description = "",
    version = "1.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    Database.Connect(OnDatabaseConnect, "player_analytics");

    BuildPath(Path_SM, g_sFile, sizeof(g_sFile), "configs/whitelist.ini");

    LoadList();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            OnClientPostAdminCheck(i);
        }
    }

    CSetPrefix("{green}[Whitelist]");
}

public void OnDatabaseConnect(Database db, const char[] error, any data)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("(OnDatabaseConnect) Connection error: %s", error);
        return;
    }

    g_dDB = db;
}

public void OnClientPostAdminCheck(int client)
{
    CreateTimer(10.0, Timer_CheckPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckPlayer(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
    {
        char sAuth[32];
        if (!GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth)))
        {
            return;
        }

        int iIndex = g_aWhitelist.FindString(sAuth);

        if (iIndex != -1)
        {
            g_aWhitelist.Erase(iIndex);

            GetClientPlaytime(client);
            UpdateWhitelist();
        }
    }
}

void GetClientPlaytime(int client)
{
    char sAuth[32];
    
    if (!GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth)))
    {
        return;
    }

    char sQuery[256];
    Format(sQuery, sizeof(sQuery), "SELECT time_total FROM ptt_test WHERE steamid = \"%s\"", sAuth);
    g_dDB.Query(Query_GetClientPlaytime, sQuery, GetClientUserId(client));
}

public void Query_GetClientPlaytime(Database db, DBResultSet results, const char[] error, int userid)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("(Query_GetClientPlaytime) Connection error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientInGame(client))
    {
        return;
    }

    if (results.RowCount > 0 && results.FetchRow())
	{
        int iTotal = results.FetchInt(0);

        int iPoints = 0;
        int iCredits = 0;

        if (iTotal >= 70000)
        {
            iPoints = 250;
            iCredits = 1000;

        }
        else if (iTotal < 70000 && iTotal >= 35000)
        {
            iPoints = 150;
            iCredits = 750;
        }
        else if (iTotal < 35000 && iTotal >= 10000)
        {
            iPoints = 50;
            iCredits = 500;
        }
        else
        {
            iCredits = 250;
        }

        if (iPoints > 0)
        {
            STAMM_AddClientPoints(client, iPoints);
            CPrintToChat(client, "Du hast einmalig {lightgreen}%d Stammpunkte {default}als Jail Tester bekommen.", iPoints);
        }

        if (iCredits > 0)
        {
            int iNewCredits = Store_GetClientCredits(client) + iCredits;
            Store_SetClientCredits(client, iNewCredits, "Jail Tester");
            CPrintToChat(client, "Du hast einmalig {lightgreen}%d Credits {default}als Jail Tester bekommen.", iCredits);
        }
    }
}

void UpdateWhitelist()
{
    if (FileExists(g_sFile))
    {
        DeleteFile(g_sFile);
    }

    File fFile = OpenFile(g_sFile, "a+");

    for (int i = 0; i < g_aWhitelist.Length; i++)
    {
        char sAuth[32];

        g_aWhitelist.GetString(i, sAuth, sizeof(sAuth));

        if (strlen(sAuth) > 2)
        {
            fFile.WriteLine(sAuth);
        }
    }

    delete fFile;
}

void LoadList()
{
    delete g_aWhitelist;

    File fFile = OpenFile(g_sFile, "rt");

    if (fFile == null)
    {
        SetFailState("[Whitelist] Can't open File: %s", g_sFile);
        return;
    }

    g_aWhitelist = new ArrayList(32);

    char sLine[32];

    while (!fFile.EndOfFile() && fFile.ReadLine(sLine, sizeof(sLine)))
    {
        StripQuotes(sLine);
        TrimString(sLine);
        
        if (strlen(sLine) > 1 && StrContains(sLine, "//", false) == -1)
        {
            g_aWhitelist.PushString(sLine);
        }
    }

    delete fFile;
}
