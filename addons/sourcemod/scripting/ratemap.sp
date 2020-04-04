#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#include <autoexecconfig>
#include <multicolors>

#define LoopValidClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientValid(%1))

Database g_dDB = null;

int g_iStars[MAXPLAYERS + 1] = { -1, ... };

bool g_bDebug = true;
bool g_bReason[MAXPLAYERS + 1] = { false, ... };

StringMap g_smMap[MAXPLAYERS + 1 ];

char g_sCommID[MAXPLAYERS + 1][32];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ratemap");

    return APLRes_Success;
}

public Plugin myinfo = 
{
    name = "Rate Map",
    author = "Bara",
    description = "Plugin to rate the current map",
    version = "1.0.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_rate", Command_Rate);
    RegConsoleCmd("sm_ratemap", Command_Rate);

    CSetPrefix("{green}[ RateMap ] {default}");

    HookEvent("player_death", Event_PlayerDeath);

    Database.Connect(OnSQLConnect, "mvotes");
}

public void OnSQLConnect(Database db, const char[] error, any data)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("[RateMap.OnSQLConnect] Database handle is invalid! (Error: %s)", error);
        return;
    }

    g_dDB = db;

    if (g_bDebug)
    {
        LogMessage("[RateMap.OnSQLConnect] Connection was successful!");
    }

    char sCharset[12] = "utf8mb4";

    if (!g_dDB.SetCharset(sCharset))
    {
        Format(sCharset, sizeof(sCharset), "utf8");
        g_dDB.SetCharset(sCharset);
    }

    char sQuery[1024];
    g_dDB.Format(sQuery, sizeof(sQuery), " \
    CREATE TABLE IF NOT EXISTS `ratemap` ( \
        `id` INT NOT NULL AUTO_INCREMENT, \
        `time` INT NOT NULL, \
        `map` VARCHAR(64) COLLATE %s_unicode_ci NOT NULL, \
        `communityid` VARCHAR(32) COLLATE %s_unicode_ci NOT NULL, \
        `stars` INT NOT NULL, \
        `reason` VARCHAR(256) COLLATE %s_unicode_ci NOT NULL, \
        PRIMARY KEY (`id`), \
        UNIQUE KEY (`map`, `communityid`) \
    ) ENGINE=InnoDB DEFAULT CHARSET=%s COLLATE=%s_unicode_ci;", sCharset, sCharset, sCharset, sCharset, sCharset);
    g_dDB.Query(Query_CreateTable, sQuery);

    if (g_bDebug)
    {
        LogMessage("Query_CreateTable: %s", sQuery);
    }
}

public void Query_CreateTable(Database db, DBResultSet results, const char[] error, any data)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_CreateTable) Can't create the table! Error: %s", error);
        return;
    }

    LoopValidClients(i)
    {
        OnClientPostAdminCheck(i);
    }
}

public void OnMapStart()
{
    LoopValidClients(i)
    {
        OnClientPostAdminCheck(i);
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (g_dDB == null)
    {
        return;
    }

    if (client < 1 || IsFakeClient(client) || IsClientSourceTV(client))
    {
        return;
    }

    g_bReason[client] = false;
    g_iStars[client] = -1;

    if (!GetClientAuthId(client, AuthId_SteamID64, g_sCommID[client], sizeof(g_sCommID[])))
    {
        return;
    }

    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));

    g_smMap[client] = new StringMap();

    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "SELECT map, stars, reason FROM ratemap WHERE communityid = \"%s\" AND map = \"%s\"",  g_sCommID[client], sMap);
    g_dDB.Query(Query_SelectPlayer, sQuery, GetClientUserId(client));

    if (g_bDebug)
    {
        LogMessage("Query_SelectPlayer: %s", sQuery);
    }
}

public void Query_SelectPlayer(Database db, DBResultSet results, const char[] error, int userid)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_SelectPlayer) Can't create the table! Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (results.HasResults)
    {
        if (results.FetchRow())
        {
            char sMap[64];
            results.FetchString(0, sMap, sizeof(sMap));
            
            int iStars = results.FetchInt(1);

            char sReason[256];
            results.FetchString(2, sReason, sizeof(sReason));

            g_smMap[client].SetValue("stars", iStars);
            g_smMap[client].SetString("reason", sReason);
        }
    }
}

public Action Command_Rate(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Handled;
    }

    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));

    char sBuffer[512];

    int iStars = -1;
    bool bFound = g_smMap[client].GetValue("stars", iStars);

    if (!bFound)
    {
        Format(sBuffer, sizeof(sBuffer), "Rate the map:\n%s\n ", sMap);
    }
    else
    {
        char sReason[256];
        g_smMap[client].GetString("reason", sReason, sizeof(sReason));
        Format(sBuffer, sizeof(sBuffer), "Rate the map:\n%s\n \nYour current map rate\nStars: %d\nReason: %s\n ", sMap, iStars, sReason);
    }

    Menu menu = new Menu(Menu_RateMain);
    menu.SetTitle(sBuffer);
    menu.AddItem("1", "1 Star");
    menu.AddItem("2", "2 Stars");
    menu.AddItem("3", "3 Stars");
    menu.AddItem("4", "4 Stars");
    menu.AddItem("5", "5 Stars");
    menu.ExitBackButton = false;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int Menu_RateMain(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[4];
        menu.GetItem(param, sParam, sizeof(sParam));

        g_iStars[client] = StringToInt(sParam);

        CPrintToChat(client, "Your gave the map %d star(s), now we need a reason for this rate. Type reason in chat or abort it with \"!abort\".", g_iStars[client]);
        g_bReason[client] = true;
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
    if (IsClientValid(client) && g_bReason[client] && g_iStars[client] > 0)
    {
        char sReason[256];
        strcopy(sReason, sizeof(sReason), message);

        TrimString(sReason);
        StripQuotes(sReason);

        if (StrContains(sReason, "!abort", false) != -1)
        {
            g_bReason[client] = false;
            g_iStars[client] = -1;

            CPrintToChat(client, "Map rate aborted.");
        }

        if (strlen(sReason) < 6)
        {
            CPrintToChat(client, "Minimum length is 6 characters.");
            return Plugin_Stop;
        }

        if (strlen(sReason) > 255)
        {
            CPrintToChat(client, "Maximal length is 255 characters.");
            return Plugin_Stop;
        }

        char sMap[64];
        GetCurrentMap(sMap, sizeof(sMap));

        int iTemp = -1;
        bool bFound = g_smMap[client].GetValue("stars", iTemp);

        char sQuery[512];
        if (!bFound)
        {
            g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO ratemap (map, time, communityid, stars, reason) VALUES (\"%s\", UNIX_TIMESTAMP(), \"%s\", '%d', \"%s\")", sMap, g_sCommID[client], g_iStars[client], sReason);
        }
        else
        {
            g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE ratemap SET time = UNIX_TIMESTAMP(), stars = '%d', reason = \"%s\" WHERE communityid = \"%s\" AND map = \"%s\"", g_iStars[client], sReason, g_sCommID[client], sMap);
        }
        DataPack pack = new DataPack();
        pack.WriteCell(GetClientUserId(client));
        pack.WriteString(sMap);
        pack.WriteString(sReason);
        pack.WriteCell(g_iStars[client]);
        g_dDB.Query(Query_InsertRate, sQuery, pack);

        if (g_bDebug)
        {
            LogMessage("Query_InsertRate: %s", sQuery);
        }

        g_iStars[client] = -1;
        g_bReason[client] = false;

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public void Query_InsertRate(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if (!IsValidDatabase(db, error))
    {
        SetFailState("(Query_InsertRate) Can't create the table! Error: %s", error);
        delete pack;
        return;
    }

    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());

    char sMap[64];
    pack.ReadString(sMap, sizeof(sMap));
    
    char sReason[256];
    pack.ReadString(sReason, sizeof(sReason));

    int iStars = pack.ReadCell();

    delete pack;

    CPrintToChat(client, "Your rate for %s with %d star(s) and the reason (%s) has been saved. Thanks for your feedback!", sMap, iStars, sReason);

    g_smMap[client].SetValue("stars", iStars);
    g_smMap[client].SetString("reason", sReason);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsClientValid(client))
    {
        int iTemp = -1;
        bool bRated = g_smMap[client].GetValue("stars", iTemp);

        if (!bRated)
        {
            CPrintToChat(client, "It's now possible to rate maps with {lightgreen}!rate {default}.");
        }
    }
}

public void OnClientDisconnect(int client)
{
    if (client < 1 || IsFakeClient(client) || IsClientSourceTV(client))
    {
        return;
    }

    g_bReason[client] = false;
    g_iStars[client] = -1;
    delete g_smMap[client];
}

public void OnMapEnd()
{
    LoopValidClients(i)
    {
        OnClientDisconnect(i);
    }
}

bool IsClientValid(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
        {
            return true;
        }
    }
    
    return false;
}

bool IsValidDatabase(Database db, const char[] error)
{
    if (db == null || strlen(error))
    {
        return false;
    }

    return true;
}
