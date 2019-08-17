#pragma semicolon 1
#pragma newdecls optional

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dng-jail>
#include <clientprefs>
#include <autoexecconfig>
#include <emitsoundany>
#include <menu-stocks>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <store>
#include <lastrequest>
#include <dice>
#include <stamm>
#include <glow>
#include <myjailbreak>

#pragma newdecls required

#define PL_NAME "Jail"

bool g_bStore = false;
bool g_bHosties = false;
bool g_bDice = false;
bool g_bStamm = false;
// bool g_bGlow = false;
bool g_bMyJB = false;

Handle g_hOnMySQLConnect = null;
Database g_dDB = null;

// CT Boost
ConVar g_cEnableCTBoost = null;
ConVar g_cCTBoostHealth = null;
ConVar g_cCTBoostHealthMulti = null;
ConVar g_cCTBoostArmor = null;
ConVar g_cCTBoostHelm = null;
ConVar g_cEnableFreeday = null;
ConVar g_cEnableFreedayTeams = null;
ConVar g_cEnableShowDamage = null;
ConVar g_cEnableVoiceMenu = null;
ConVar g_cEnableLRPoints = null;
ConVar g_cLRPointsMode = null;
#if defined _Store_INCLUDED
ConVar g_cLRPointsStoreCredits = null;
#endif
ConVar g_cLRPointsStammpoints = null;
ConVar g_cEnableExtraPointsCT = null;
ConVar g_cEnableExtraPointsTag = null;
ConVar g_cEnableNewBeacon = null;
ConVar g_cNewBeaconPoints = null;

bool g_bCanSeeName[MAXPLAYERS+1] = { false, ... };
Handle g_hResetCanSeeName[MAXPLAYERS+1] = { null, ... };

int g_iMyWeapons = -1;

char g_sCMDs[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog",
    "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin",
    "getout", "negative","enemydown", "compliment", "thanks", "cheer"};

#include "jail/ergeben.sp"
#include "jail/verweigern.sp"
#include "jail/freedayteams.sp"
#include "jail/teamdamage.sp"
#include "jail/freeday.sp"
#include "jail/freekill.sp"
#include "jail/spawnweapons.sp"
#include "jail/kill.sp"
#include "jail/showdamage.sp"
#include "jail/lrStammpunkte.sp"
#include "jail/extraStammpunkte.sp"
#include "jail/newBeacon.sp"
#include "jail/mysql.sp"
#include "jail/ctboost.sp"
#include "jail/voicemenu.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_hOnMySQLConnect = CreateGlobalForward("Jail_OnMySQLCOnnect", ET_Ignore, Param_Cell);
    
    CreateNative("Jail_GetDatabase", Native_GetDatabase);
    CreateNative("Jail_IsClientCapitulate", Native_IsCapitulate);

    MarkNativeAsOptional("Store_GetClientCredits");
    MarkNativeAsOptional("Store_SetClientCredits");
    
    RegPluginLibrary("jail");
    
    return APLRes_Success;
}
public Plugin myinfo =
{
    name = "Jail - Collection of jail functions", 
    author = "Bara", 
    description = "", 
    version = "1.0", 
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    g_iMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
    if (g_iMyWeapons == -1)
    {
        SetFailState("CBasePlayer:m_hMyWeapons not found");
        return;
    }
    
    MySQL_OnPluginStart();
    Teamdamage_OnPluginStart();
    Freekill_OnPluginStart();
    Kill_OnPluginStart();
    VoiceMenu_OnPluginStart();
    Spawnweapons_OnPluginStart();
    NewBeacon_OnPluginStart();

    LoadTranslations("common.phrases");

    RegConsoleCmd("sm_e", Command_ergeben);
    RegConsoleCmd("sm_v", Command_verweigern);
    RegConsoleCmd("sm_vreset", Command_vreset);
    RegConsoleCmd("sm_teamdamage", Command_teamdamage);
    RegConsoleCmd("sm_td", Command_teamdamage);
    RegConsoleCmd("sm_fd", Command_freeday);
    RegConsoleCmd("sm_kill", Command_kill);
    RegConsoleCmd("sm_fk", Command_freekill);
    RegConsoleCmd("sm_noob", Command_Noob);
    
    Handle hCvar = FindConVar("mp_teammates_are_enemies");
    int flags = GetConVarFlags(hCvar);
    flags &= ~FCVAR_NOTIFY;
    SetConVarFlags(hCvar, flags);
    delete hCvar;
    
    RegAdminCmd("sm_fkban", Command_fkBan, ADMFLAG_GENERIC);
    
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_hurt", Event_PlayerHurt);
    
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("jail");
    g_cEnableCTBoost = AutoExecConfig_CreateConVar("jail_enable_ctboost", "1", "Enable CT Boost?", _, true, 0.0, true, 1.0);
    g_cCTBoostHealth = AutoExecConfig_CreateConVar("jail_enable_ctboost_health", "1", "Enable Health CT Boost?", _, true, 0.0, true, 1.0);
    g_cCTBoostHealthMulti = AutoExecConfig_CreateConVar("jail_ctboot_health_multi", "10.2842", "Faktor for CT Boost Health");
    g_cCTBoostArmor = AutoExecConfig_CreateConVar("jail_enable_armor", "1", "Enable Armor CT Boost?", _, true, 0.0, true, 1.0);
    g_cCTBoostHelm = AutoExecConfig_CreateConVar("jail_enable_helm", "1", "Enable Helm CT Boost?", _, true, 0.0, true, 1.0);
    g_cEnableFreeday = AutoExecConfig_CreateConVar("jail_enable_freeday", "1", "Enable Freeday?", _, true, 0.0, true, 1.0);
    g_cEnableFreedayTeams = AutoExecConfig_CreateConVar("jail_enable_freeday_teams", "1", "Enable Freeday Teams?", _, true, 0.0, true, 1.0);
    g_cEnableShowDamage = AutoExecConfig_CreateConVar("jail_enable_showdamage", "1", "Enable Show Damage?", _, true, 0.0, true, 1.0);
    g_cEnableVoiceMenu = AutoExecConfig_CreateConVar("jail_enable_voicemenu", "1", "Enable Voice Menu?", _, true, 0.0, true, 1.0);
    g_cEnableLRPoints = AutoExecConfig_CreateConVar("jail_enable_lr_points", "1", "Enable LR Points?", _, true, 0.0, true, 1.0);
    g_cEnableExtraPointsCT = AutoExecConfig_CreateConVar("jail_enable_extra_points_name", "1", "Enable Extra Points as CT?", _, true, 0.0, true, 1.0);
    g_cEnableExtraPointsTag = AutoExecConfig_CreateConVar("jail_enable_extra_points_tag", "1", "Enable Extra Points for Tag (Name/Clantag)?", _, true, 0.0, true, 1.0);
    g_cEnableNewBeacon = AutoExecConfig_CreateConVar("jail_enable_newBeacon", "1", "Enable Beacon for new Players?", _, true, 0.0, true, 1.0);
    g_cNewBeaconPoints = AutoExecConfig_CreateConVar("jail_newBeacon_points", "240", "Until how much points will get a player the glow effect?");
    g_cLRPointsMode = AutoExecConfig_CreateConVar("jail_lr_points_mode", "0", "Which points the player get after won lr? ( 0 - Store Credits, 1 - Stammpoints, 2 - Both", _, true, 0.0, true, 2.0);
#if defined _Store_INCLUDED
    g_cLRPointsStoreCredits = AutoExecConfig_CreateConVar("jail_lr_points_store_credits", "10", "How much store credits after lr win? ( 0 = Disabled)");
#endif
    g_cLRPointsStammpoints = AutoExecConfig_CreateConVar("jail_lr_points_stammpoints", "10", "How much stammpoints after lr win? ( 0 = Disabled)");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
    

    LoopClients(client)
    {
        OnClientCookiesCached(client);
    }

    CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);

    for(int i; i < sizeof(g_sCMDs); i++)
    {
        AddCommandListener(Command_Radio, g_sCMDs[i]);
    }

    g_bStore = LibraryExists("store");
    g_bHosties = LibraryExists("hosties");
    g_bDice = LibraryExists("dice");
    g_bStamm = LibraryExists("stamm");
    // g_bGlow = LibraryExists("glow");
    g_bMyJB = LibraryExists("myjailbreak");
}

public void OnAllPluginsLoaded()
{
    if (LibraryExists("store"))
    {
        g_bStore = true;
    }
    else if (LibraryExists("hosties"))
    {
        g_bHosties = true;
    }
    else if (LibraryExists("dice"))
    {
        g_bDice = true;
    }
    else if (LibraryExists("stamm"))
    {
        g_bStamm = true;
    }
    /* else if (LibraryExists("glow"))
    {
        g_bGlow = true;
    } */
    else if (LibraryExists("myjailbreak"))
    {
        g_bMyJB = true;
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "store"))
    {
        g_bStore = true;
    }
    else if (StrEqual(name, "hosties"))
    {
        g_bHosties = true;
    }
    else if (StrEqual(name, "dice"))
    {
        g_bDice = true;
    }
    else if (StrEqual(name, "stamm"))
    {
        g_bStamm = true;
    }
    /* else if (StrEqual(name, "glow"))
    {
        g_bGlow = true;
    } */
    else if (StrEqual(name, "myjailbreak"))
    {
        g_bMyJB = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "store"))
    {
        g_bStore = false;
    }
    else if (StrEqual(name, "hosties"))
    {
        g_bHosties = false;
    }
    else if (StrEqual(name, "dice"))
    {
        g_bDice = false;
    }
    else if (StrEqual(name, "stamm"))
    {
        g_bStamm = false;
    }
    /* else if (StrEqual(name, "glow"))
    {
        g_bGlow = false;
    } */
    else if (StrEqual(name, "myjailbreak"))
    {
        g_bMyJB = false;
    }
}

public void OnConfigsExecuted()
{
    ConVar ignoreGrenade = FindConVar("sv_ignoregrenaderadio");
    ignoreGrenade.SetInt(1);
}

public void OnMapStart()
{
    Freeday_OnMapStart();
    Freekill_OnMapStart();
}

public void OnClientCookiesCached(int client)
{
    Freekill_OnClientCookiesCached(client);
    NewBeacon_OnClientCookiesCached(client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    Freedayteams_RoundStart();
    Freekill_RoundStart();
    TeamDamage_Reset();

    if(g_bStamm)
    {
        LrStammpunkte_RoundStart();
    }
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    TeamDamage_Reset();

    if(g_bStamm)
    {
        LrStammpunkte_RoundEnd();
    }
    
    LoopClients(client)
    {
        ResetErgeben(client);
        ResetVerweigern(client);
        ResetFreeday(client);
        ResetFreekill(client);
        ResetSpawnweapons(client);
    }
}

public void OnClientPostAdminCheck(int client)
{
    if(IsClientValid(client) && g_dDB != null)
        Freekill_GetStatus(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(IsClientValid(client))
    {
        ResetErgeben(client);
        ResetVerweigern(client);
        ResetFreeday(client);
        ResetFreekill(client);
        VoiceMenu_ResetSettings(client);

        bool bValid = true;

        if (g_bMyJB && MyJailbreak_IsEventDayRunning())
        {
            bValid = false;
        }

        if (bValid)
        {
            Spawnweapons_PlayerSpawn(client);
            CTBoost_PlayerSpawn(client);
        }
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(g_bStamm)
    {
        LrStammpunkte_PlayerDeath();
    }


    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if(IsClientValid(client))
    {
        CPrintToChat(client, "Zu früh gestorben? Es gibt auch Minispiele wie %s!tetris, !snake %sund %s!pong", SPECIAL, TEXT, SPECIAL);
        if(IsClientValid(attacker))
        {
            Freekill_PlayerDeath(client, attacker);
        }
    }
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if(IsClientValid(attacker))
    {
        int damage = event.GetInt("dmg_health");
        
        Showdamage_PlayerHurt(attacker, damage);
    }
}

public void OnClientDisconnect(int client)
{
    ResetErgeben(client);
    ResetVerweigern(client);
    ResetFreeday(client);
    ResetFreekill(client);
    ResetSpawnweapons(client);
    ResetClientLrStammpunkte(client);
    NewBeacon_OnClientDisconnect(client);

    g_bCanSeeName[client] = false;
    delete g_hResetCanSeeName[client];
}

public Action Command_Radio(int client, const char[] command, int args) 
{
    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    if(IsPlayerAlive(client))
    {
        CS_SetClientContributionScore(client, 1);
    }
    else
    {
        CS_SetClientContributionScore(client, 0);
    }
    
    if(IsPlayerAlive(client))
    {
        if(g_bFreeday[client] && buttons & IN_JUMP)
        {
            if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
            {
                SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
                
                if(!(GetEntityFlags(client) & FL_ONGROUND))
                {
                    buttons &= ~IN_JUMP;
                }
            }
        }
        else if (buttons & IN_USE)
        {
            GetAimTarget(client);
        }
    }

    return Plugin_Continue;
}

void GetAimTarget(int client)
{
    if(!g_bCanSeeName[client])
    {
        char sWeapon[32];
        GetClientWeapon(client, sWeapon, sizeof(sWeapon));
        
        if(StrContains(sWeapon, "knife", false) != -1 || StrContains(sWeapon, "bayonet", false) != -1)
        {
            int iTarget = GetClientAimTarget(client, true);
            
            if(iTarget != -1)
            {
                int iTargetTeam = GetClientTeam(iTarget);
                
                char sTeam[24];
                sTeam = iTargetTeam == CS_TEAM_CT ? "{darkblue}CT" : "{darkred}T";
                
                CPrintToChat(client, "%s{default}: {green}%N", sTeam, iTarget);
                
                g_bCanSeeName[client] = true;
                g_hResetCanSeeName[client] = CreateTimer(2.0, Timer_ResetCanSeeName, client);
            }
        }
    }
}

public Action Timer_ResetCanSeeName(Handle timer, any client)
{
    g_bCanSeeName[client] = false;
    
    g_hResetCanSeeName[client] = null;
}
