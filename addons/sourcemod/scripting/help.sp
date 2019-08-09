#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <dng-jail>

char g_sFile[PLATFORM_MAX_PATH + 1];

public Plugin myinfo =
{
    name = "Help Menu",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_help", Command_Help);
    RegConsoleCmd("sm_hilfe", Command_Help);
    RegConsoleCmd("sm_command", Command_Help);
    RegConsoleCmd("sm_commands", Command_Help);

    BuildPath(Path_SM, g_sFile, sizeof(g_sFile), "configs/dng/help/start.cfg");
}

public Action Command_Help(int client, int args)
{
    RequestFrame(Frame_ShowMenu, GetClientUserId(client));
}

public void Frame_ShowMenu(int userid)
{
    int client = GetClientOfUserId(userid);
   
    if (!IsClientValid(client))
    {
        return;
    }

    Menu menu = new Menu(Menu_HelpMain);
    menu.SetTitle("dng.xyz - Help");

    File fFile = OpenFile(g_sFile, "rt");

    if (fFile == null)
    {
        SetFailState("Can't open File: %s", g_sFile);
    }

    delete fFile;

    KeyValues kvRules = new KeyValues("Rules");

    if (!kvRules.ImportFromFile(g_sFile))
    {
        SetFailState("Can't read %s correctly! (ImportFromFile)", g_sFile);
        delete kvRules;
        return;
    }

    if (!kvRules.GotoFirstSubKey())
    {
        SetFailState("Can't read %s correctly! (GotoFirstSubKey)", g_sFile);
        delete kvRules;
        return;
    }

    do
    {
        char sNumber[4];
        char sTitle[64];

        kvRules.GetSectionName(sNumber, sizeof(sNumber));
        kvRules.GetString("title", sTitle, sizeof(sTitle));
        menu.AddItem(sNumber, sTitle);
    }
    while (kvRules.GotoNextKey());

    delete kvRules;

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HelpMain(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char sParam[32];
        menu.GetItem(param, sParam, sizeof(sParam));

        File fFile = OpenFile(g_sFile, "rt");

        if (fFile == null)
        {
            SetFailState("Can't open File: %s", g_sFile);
            return;
        }

        delete fFile;

        KeyValues kvRules = new KeyValues("Rules");

        if (!kvRules.ImportFromFile(g_sFile))
        {
            SetFailState("Can't read %s correctly! (ImportFromFile)", g_sFile);
            delete kvRules;
            return;
        }

        if (kvRules.JumpToKey(sParam, false))
        {
            char sValue[MAX_MESSAGE_LENGTH];

            kvRules.GetString("text", sValue, sizeof(sValue));
            if (strlen(sValue) > 0)
            {
                CPrintToChat(client, sValue);
                RequestFrame(Frame_ShowMenu, GetClientUserId(client));

                delete kvRules;
                return;
            }

            kvRules.GetString("fakecommand", sValue, sizeof(sValue));
            if (strlen(sValue) > 0)
            {
                FakeClientCommand(client, sValue);

                delete kvRules;
                return;
            }

            kvRules.GetString("command", sValue, sizeof(sValue));
            if (strlen(sValue) > 0)
            {
                ClientCommand(client, sValue);

                delete kvRules;
                return;
            }

            kvRules.GetString("file", sValue, sizeof(sValue));
            if (strlen(sValue) > 0)
            {
                char sFile[PLATFORM_MAX_PATH + 1];
                BuildPath(Path_SM, sFile, sizeof(sFile), "configs/dng/help/%s", sValue);

                fFile = OpenFile(sFile, "rt");

                if (fFile == null)
                {
                    SetFailState("Can't open File: %s", sFile);
                    return;
                }

                char sLine[64], sTitle[64];

                Menu rMenu = new Menu(Menu_File);

                kvRules.GetString("title", sTitle, sizeof(sTitle));
                rMenu.SetTitle(sTitle);

                while (!fFile.EndOfFile() && fFile.ReadLine(sLine, sizeof(sLine)))
                {
                    if (strlen(sLine) > 1)
                    {
                        rMenu.AddItem("help", sLine, ITEMDRAW_DISABLED);
                    }
                }

                rMenu.ExitButton = true;
                rMenu.ExitBackButton = true;
                rMenu.Display(client, MENU_TIME_FOREVER);

                delete fFile;
                delete kvRules;

                return;
            }

            delete kvRules;

            return;
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int Menu_File(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Cancel || action == MenuAction_Select || param == MenuCancel_ExitBack)
    {
        if (IsClientValid(client))
        {
            char sParam[32];
            menu.GetItem(param, sParam, sizeof(sParam));
            
            if (StrEqual(sParam, "help", false))
            {
                RequestFrame(Frame_ShowMenu, GetClientUserId(client));
            }
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
