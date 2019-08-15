#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

char g_sLog[PLATFORM_MAX_PATH + 1];
ArrayList g_aWhitelist = null;

public Plugin myinfo =
{
    name = "Whitelist",
    author = "Bara",
    description = "",
    version = "1.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    char sDate[24];
    FormatTime(sDate, sizeof(sDate), "%y%m%d");
    BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/whitelist_%s.log", sDate);

    RegAdminCmd("sm_reload_whitelist", Command_ReloadWhitelist, ADMFLAG_ROOT);

    LoadList();
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if (!IsFakeClient(client) && !IsClientSourceTV(client))
    {
        int iIndex = g_aWhitelist.FindString(auth);

        if (iIndex == -1)
        {
            KickClient(client, "You are not on the whitelist. Visit us on dng.xyz!");
            LogToFileEx(g_sLog, "\"%N\" (%s) was kicked.", client, auth);
        }
    }
}

public Action Command_ReloadWhitelist(int client, int args)
{
    LoadList();

    ReplyToCommand(client, "Whitelist reloaded!");

    return Plugin_Handled;
}

void LoadList()
{
    delete g_aWhitelist;

    char sFile[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/whitelist.ini");

    File fFile = OpenFile(sFile, "rt");

    if (fFile == null)
    {
        SetFailState("[Whitelist] Can't open File: %s", sFile);
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
            LogToFileEx(g_sLog, "Added steamid %s to whitelist.", sLine);
            g_aWhitelist.PushString(sLine);
        }
    }

    delete fFile;
}
