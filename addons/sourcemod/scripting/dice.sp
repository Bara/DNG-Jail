#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <dng-jail>
#include <emitsoundany>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <jail>
#include <myjailbreak>
#include <knockout>
#include <lastrequest>

#pragma newdecls required

#define DICE_SOUND     "dng/jail/dice/dice.mp3"
#define NEGATIVE_SOUND "dng/jail/dice/negative.mp3"
#define NEUTRAL_SOUND "dng/jail/dice/neutral.mp3"
#define POSITIVE_SOUND "dng/jail/dice/positive.mp3"

int g_iCount[MAXPLAYERS + 1] =  { 0, ... };
int g_iNoclipCounter[MAXPLAYERS+1] = {5, ...};
int g_iFroggyAir[MAXPLAYERS+1] =  { 0, ... };

// T-Dice
bool g_bInWater[MAXPLAYERS + 1] = {false, ...};
bool g_bFroggyjump[MAXPLAYERS + 1] =  { false, ... };
bool g_bFroggyPressed[MAXPLAYERS+1] =  { false, ... };
bool g_bLongjump[MAXPLAYERS+1] =  { false, ... };
bool g_bBhop[MAXPLAYERS+1] =  { false, ... };
bool g_bAssassine[MAXPLAYERS+1] =  { false, ... };
bool g_bTollpatsch[MAXPLAYERS+1] =  { false, ... };
bool g_bLose[MAXPLAYERS + 1] =  { false, ... };

// CT-Dice
float g_fDamage[MAXPLAYERS+1] = {0.0, ...};
bool g_bCTMoreDamage[MAXPLAYERS+1] = {false, ...};
bool g_bCTLessDamage[MAXPLAYERS+1] = {false, ...};
bool g_bCTHeadshot[MAXPLAYERS+1] = {false, ...};
bool g_bCTRespawn[MAXPLAYERS+1] = {false, ...};

Handle g_hLowGravity[MAXPLAYERS + 1] =  { null, ... };
Handle g_hHighGravity[MAXPLAYERS + 1] =  { null, ... };
Handle g_hNoclip[MAXPLAYERS+1] =  { null, ... };

Database g_dDB = null;

bool g_bHosties = false;
bool g_bJail = false;
bool g_bMyJB = false;
bool g_bKnockout = false;

bool g_bBusy[MAXPLAYERS + 1] = {false, ...};
Handle g_hTimer[MAXPLAYERS + 1] = {null, ...};

ConVar g_cDebug = null;

#include "dice/t.sp"
#include "dice/ct.sp"

public Plugin myinfo =
{
    name = "Dice - Dice that includes CT and 2 T dices", 
    author = "Bara", 
    description = "", 
    version = "1.0", 
    url = "github.com/Bara"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("Dice_IsClientAssassine", Native_IsAssassine);
    CreateNative("Dice_HasClientBhop", Native_HasClientBhop);
    CreateNative("Dice_LoseAll", Native_LoseAll);
    
    RegPluginLibrary("dice");
    
    return APLRes_Success;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_w", Command_Dice);
    
    HookEvent("player_jump", Event_PlayerJump);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    HookEvent("round_end", Event_RoundEnd);

    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("plugin.dice");
    g_cDebug = AutoExecConfig_CreateConVar("dice_debug", "0", "Enable/Disable debug mode for dice", _, true, 0.0, true, 1.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    LoopClients(i)
    {
        SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    }

    CSetPrefix("{green}[%s]{default}", DNG_BASE);

    g_bHosties = LibraryExists("hosties");
    g_bJail = LibraryExists("jail");
    g_bMyJB = LibraryExists("myjailbreak");
    g_bKnockout = LibraryExists("knockout");
}

public void OnAllPluginsLoaded()
{
    if(LibraryExists("hosties"))
    {
        g_bHosties = true;
    }
    else if(LibraryExists("jail"))
    {
        g_bJail = true;
    }
    else if(LibraryExists("myjailbreak"))
    {
        g_bMyJB = true;
    }
    else if(LibraryExists("knockout"))
    {
        g_bKnockout = true;
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "hosties"))
    {
        g_bHosties = true;
    }
    else if (StrEqual(name, "jail"))
    {
        g_bJail = true;
    }
    else if (StrEqual(name, "myjailbreak"))
    {
        g_bMyJB = true;
    }
    else if (StrEqual(name, "knockout"))
    {
        g_bKnockout = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "hosties"))
    {
        g_bHosties = false;
    }
    else if (StrEqual(name, "jail"))
    {
        g_bJail = false;
    }
    else if (StrEqual(name, "myjailbreak"))
    {
        g_bMyJB = false;
    }
    else if (StrEqual(name, "knockout"))
    {
        g_bKnockout = false;
    }
}

public void OnMapStart()
{
    PrecacheSoundAny(DICE_SOUND);
    AddFileToDownloadsTable("sound/" ... DICE_SOUND);

    PrecacheSoundAny(NEGATIVE_SOUND);
    AddFileToDownloadsTable("sound/" ... NEGATIVE_SOUND);

    PrecacheSoundAny(NEUTRAL_SOUND);
    AddFileToDownloadsTable("sound/" ... NEUTRAL_SOUND);

    PrecacheSoundAny(POSITIVE_SOUND);
    AddFileToDownloadsTable("sound/" ... POSITIVE_SOUND);
}

public void Jail_OnMySQLCOnnect(Database database)
{
    g_dDB = database;
    
    CreateTables();
}

void CreateTables()
{
    /*
        CREATE TABLE IF NOT EXISTS `dice_logs` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `date` int(11) NOT NULL,
            `map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
            `communityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
            `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
            `dice` tinyint(1) NOT NULL,
            `option` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    */
    
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `dice_logs` (`id` INT NOT NULL AUTO_INCREMENT, `date` int(11) NOT NULL, `map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL, `communityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `dice` tinyint(1) NOT NULL, `option` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    g_dDB.Query(Dice_CreateTables, sQuery);
}

public void Dice_CreateTables(Database db, DBResultSet results, const char[] error, any data)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("(Dice_CreateTables) Fail at Query: %s", error);
        return;
    }
    delete results;
}

void AddDiceToMySQL(int client, int dice, const char[] option)
{
    char sMap[32];
    GetCurrentMap(sMap, sizeof(sMap));
    
    char sAuth[32];
    GetClientAuthId(client, AuthId_SteamID64, sAuth, sizeof(sAuth));
    
    char sName[MAX_NAME_LENGTH];
    GetClientName(client, sName, sizeof(sName));
    
    if (g_bJail && g_dDB == null)
    {
        if (Jail_GetDatabase() != null)
        {
            g_dDB = Jail_GetDatabase();
        }
        else
        {
            LogError("(AddDiceToMySQL) Database is invalid!");
            return;
        }
    }
    
    /*
        CREATE TABLE IF NOT EXISTS `dice_logs` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `date` int(11) NOT NULL,
            `map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
            `communityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
            `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
            `dice` tinyint(1) NOT NULL,
            `option` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    */
    
    char sQuery[512];
    g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `dice_logs` (`date`, `map`, `communityid`, `name`, `dice`, `option`) VALUES (UNIX_TIMESTAMP(), \"%s\", \"%s\", \"%N\", \"%d\", \"%s\");", sMap, sAuth, client, dice, option);
    g_dDB.Query(Dice_InsertQuery, sQuery);
}

public void Dice_InsertQuery(Database db, DBResultSet results, const char[] error, any data)
{
    if(db == null || strlen(error) > 0)
    {
        SetFailState("(Dice_InsertQuery) Fail at Query: %s", error);
        return;
    }
    
    delete results;
}

public int Native_IsAssassine(Handle plugin, int numParams)
{
    return g_bAssassine[GetNativeCell(1)];
}

public int Native_HasClientBhop(Handle plugin, int numParams)
{
    return g_bBhop[GetNativeCell(1)];
}

public int Native_LoseAll(Handle plugin, int numParams)
{
    return g_bLose[GetNativeCell(1)];
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnClientDisconnect(int client)
{
    ResetDice(client);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int HitGroup)
{
    if (IsClientValid(attacker) && IsClientValid(victim))
    {
        if (g_bHosties)
        {
            if (IsClientInLastRequest(attacker) || IsClientInLastRequest(victim))
            {
                return Plugin_Continue;
            }
        }
        
        int aTeam = GetClientTeam(attacker);
        int vTeam = GetClientTeam(victim);

        if (aTeam == CS_TEAM_T && g_bTollpatsch[attacker])
        {
            bool bDamage = view_as<bool>(GetRandomInt(0, 1));

            if (!bDamage)
            {
                damage = 0.0;
                return Plugin_Changed;
            }
        }
        else if (aTeam == CS_TEAM_CT && g_bCTMoreDamage[attacker])
        {
            damage *= g_fDamage[attacker];
            return Plugin_Changed;
        }
        else if (vTeam == CS_TEAM_CT && g_bCTLessDamage[victim])
        {
            damage /= g_fDamage[victim];
            return Plugin_Changed;
        }
        else if (vTeam == CS_TEAM_CT && g_bCTHeadshot[victim] && damagetype & CS_DMG_HEADSHOT)
        {
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action Command_Dice(int client, int args)
{
    int iOption = -1;
    if (g_cDebug.BoolValue)
    {
        char sOption[4];
        GetCmdArg(1, sOption, sizeof(sOption));
        iOption = StringToInt(sOption);
    }

    if (g_bMyJB && MyJailbreak_IsEventDayRunning())
    {
        return Plugin_Handled;
    }

    if(IsClientValid(client))
    {
        if(IsPlayerAlive(client))
        {
            if ((g_bJail && Jail_IsClientCapitulate(client)) || (g_bKnockout && IsClientKnockout(client)))
            {
                return Plugin_Handled;
            }
            
            int team = GetClientTeam(client);
            
            if(g_iCount[client] <= 1 && team == CS_TEAM_T || g_iCount[client] == 0 && team == CS_TEAM_CT)
            {
                if (!g_bBusy[client] && g_hTimer[client] == null)
                {
                    g_bBusy[client] = true;

                    EmitSoundToClientAny(client, DICE_SOUND);

                    Panel panel = new Panel();
                    panel.SetTitle("Bitte warten...");
                    panel.DrawText("(Glücksspiel kann süchtig machen!)");
                    panel.Send(client, Panel_Nothing, 3);
                    delete panel;

                    DataPack pack = new DataPack();
                    pack.WriteCell(GetClientUserId(client));
                    pack.WriteCell(team);
                    pack.WriteCell(iOption);
                    g_hTimer[client] = CreateTimer(2.0, Timer_Dice, pack);
                }
                else
                {
                    CPrintToChat(client, "Der Würfel rollt gerade...");
                }
            }
            else
            {
                CPrintToChat(client, "Du hast schon %s%dx %sgewürfelt.", SPECIAL, g_iCount[client], TEXT);
            }
        }
        else
        {
            CPrintToChat(client, "Das macht kein Sinn...");
        }
        
    }
    
    return Plugin_Handled;
}

public int Panel_Nothing(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action Timer_Dice(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    int team = pack.ReadCell();
    int option = pack.ReadCell();
    delete pack;

    if (IsClientValid(client))
    {
        if (IsPlayerAlive(client))
        {
            // Types: 0 - Negative, 1 - Neutral, 2 - Positive
            int type = -1;

            Panel panel = new Panel();

            if(g_iCount[client] == 0)
            {
                if(team == CS_TEAM_T)
                {
                    type = tDiceOne(client, panel, option);
                    g_iCount[client]++;
                }
                else if(team == CS_TEAM_CT)
                {
                    // We increase it here to fix a bug with redice (redice set g_iCount to 0, but we'll add +1 after ctDiceOne)
                    g_iCount[client]++;

                    type = ctDiceOne(client, panel, option);
                }
            }
            else
            {
                if(GetClientTeam(client) == CS_TEAM_T)
                {
                    type = tDiceTwo(client, panel, option);
                    g_iCount[client]++;
                }
            }

            panel.Send(client, Panel_Nothing, 4);
            delete panel;

            if (type == 0)
            {
                EmitSoundToClientAny(client, NEGATIVE_SOUND);
            }
            else if (type == 1)
            {
                EmitSoundToClientAny(client, NEUTRAL_SOUND);
            }
            else if (type == 2)
            {
                EmitSoundToClientAny(client, POSITIVE_SOUND);
            }
        }
        else
        {
            CPrintToChat(client, "Das macht keinen Sinn mehr...");
        }

        g_bBusy[client] = false;
        g_hTimer[client] = null;
    }

    return Plugin_Stop;
}

void SetHealth(int client, int hp, bool addHP)
{
    int health = GetClientHealth(client);
    
    if (addHP)
    {
        // Plus HP
        SetEntityHealth(client, health + hp);
    }
    else
    {
        // Minus HP
        health -= hp;
        
        if(health <= 0)
        {
            ForcePlayerSuicide(client);
        }
        else
        {
            SetEntityHealth(client, health);
        }
    }
}

void Froggyjump(int client)
{
    float velocity[3];
    float velocity0;
    float velocity1;
    float velocity2;
    float velocity2_new;

    velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
    velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
    velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

    velocity2_new = 260.0;

    if(velocity2 < 150.0)
    {
        velocity2_new = 270.0;
    }

    if(velocity2 < 100.0)
    {
        velocity2_new = 300.0;
    }

    if(velocity2 < 50.0)
    {
        velocity2_new = 330.0;
    }

    if(velocity2 < 0.0)
    {
        velocity2_new = 380.0;
    }

    if(velocity2 < -50.0)
    {
        velocity2_new = 400.0;
    }

    if(velocity2 < -100.0)
    {
        velocity2_new = 430.0;
    }

    if(velocity2 < -150.0)
    {
        velocity2_new = 450.0;
    }

    if(velocity2 < -200.0)
    {
        velocity2_new = 470.0;
    }


    velocity[0] = velocity0 * 0.1;
    velocity[1] = velocity1 * 0.1;
    velocity[2] = velocity2_new;
    
    SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
}

void Longjump(int client)
{
    float velocity[3];
    float velocity0;
    float velocity1;
    
    velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
    velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
    
    velocity[0] = (7.0 * velocity0) * (1.0 / 4.1);
    velocity[1] = (7.0 * velocity1) * (1.0 / 4.1);
    velocity[2] = 0.0;
    
    SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
}


// Events

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(IsClientValid(client) && IsPlayerAlive(client) && g_bLongjump[client])
    {
        Longjump(client);
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(GetAliveTPlayers() == 1 && GetAliveCTPlayers() >= 1)
    {
        LoopClients(client)
        {
            if(IsPlayerAlive(client))
            {
                SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
            }
        }
    }

    if (GetAliveCTPlayers() >= 1)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));

        if (IsClientValid(client))
        {
            if (GetClientTeam(client) == CS_TEAM_CT && g_bCTRespawn[client])
            {
                if (GetRandomInt(1, 2) == 1)
                {
                    CPrintToChat(client, "Du hast durch den CT-Würfel eine 2. Chance verdient! Respawn in 2 Sekunden...");
                    CreateTimer(2.0, Timer_RespawnPlayer, GetClientUserId(client));
                }
            }
        }
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    char sWeapon[32];
    event.GetString("weapon", sWeapon, sizeof(sWeapon));
    
    if (IsClientValid(attacker))
    {
        if (GetClientTeam(attacker) == CS_TEAM_T && g_bAssassine[attacker] && (StrContains(sWeapon, "awp", false) == -1))
        {
            event.BroadcastDisabled = true;
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public Action Timer_RespawnPlayer(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        if (GetAliveCTPlayers() > 1)
        {
            CS_RespawnPlayer(client);
            g_bCTRespawn[client] = false;
        }
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if(IsClientValid(client))
    {
        SetEntityGravity(client, 1.0);
        
        ResetDice(client);
    }
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopClients(client)
    {
        if(IsPlayerAlive(client))
        {
            SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
        }
    }
}


// Timer

public Action NoclipTimer(Handle timer, any client)
{
    if(IsClientValid(client) && IsPlayerAlive(client))
    {
        if(g_iNoclipCounter[client] > 0)
        {
            CPrintToChat(client, "Noclip endet in: %s%i", SPECIAL, g_iNoclipCounter[client]);
            
            g_iNoclipCounter[client]--;
            
            return Plugin_Continue;
        }
        else
        {
            SetEntityMoveType(client, MOVETYPE_WALK);
            
            if (IsClientStuck(client))
            {
                ForcePlayerSuicide(client);
            }
        }
    }
    
    g_hNoclip[client] = null;
    
    return Plugin_Stop;
}

public Action LowGravityTimer(Handle timer, any client)
{
    if(IsClientValid(client) && IsPlayerAlive(client))
    {
        SetEntityGravity(client, 0.5);
        
        return Plugin_Continue;
    }
    
    g_hLowGravity[client] = null;
    
    return Plugin_Stop;
}

public Action HighGravityTimer(Handle timer, any client)
{
    if(IsClientValid(client) && IsPlayerAlive(client))
    {
        if (!g_bInWater[client])
        {
            SetEntityGravity(client, 1.8);
        }
        
        return Plugin_Continue;
    }
    
    g_hHighGravity[client] = null;
    
    return Plugin_Stop;
}


// Andere Methoden

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(IsClientValid(client) && IsPlayerAlive(client))
    {
        if(g_bFroggyjump[client])
        {
            if(GetEntityFlags(client) & FL_ONGROUND)
            {
                g_iFroggyAir[client] = 0;
                g_bFroggyPressed[client] = false;
            }
            else
            {
                if(buttons & IN_JUMP)
                {
                    if(!g_bFroggyPressed[client])
                    {
                        if(g_iFroggyAir[client]++ == 1)
                        {
                            Froggyjump(client);
                        }
                    }
                    
                    g_bFroggyPressed[client] = true;
                }
                else
                {
                    g_bFroggyPressed[client] = false;
                }
            }
        }
        
        if(g_bBhop[client])
        {
            if(buttons & IN_JUMP)
            {
                if(!(GetEntityMoveType(client) & MOVETYPE_LADDER))
                {
                    SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
                    
                    if(!(GetEntityFlags(client) & FL_ONGROUND))
                    {
                        buttons &= ~IN_JUMP;
                    }
                }
            }
        }
        
        // Remove fire with water contact
        if(GetEntityFlags(client) & FL_INWATER)
        {
            int iFire = GetEntPropEnt(client, Prop_Data, "m_hEffectEntity");
    
            if (IsValidEdict(iFire))
            {
                SetEntPropFloat(iFire, Prop_Data, "m_flLifetime", 0.0);
            }

            if (g_hHighGravity[client] != null)
            {
                SetEntityGravity(client, 1.0);
                g_bInWater[client] = true;
            }
        }
        else if(g_bInWater[client] && GetEntityFlags(client) & FL_ONGROUND || GetEntityFlags(client) & FL_DUCKING)
        {
            CreateTimer(0.5, Timer_ResetInWater, GetClientUserId(client));
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_ResetInWater(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        g_bInWater[client] = false;
        
        if (IsPlayerAlive(client) && g_hHighGravity[client] != null)
        {
            SetEntityGravity(client, 1.8);
        }
    }

    return Plugin_Stop;
}

void ResetDice(int client)
{
    g_iCount[client] = 0;
    g_iNoclipCounter[client] = 5;
    g_iFroggyAir[client] = 0;
    
    g_bInWater[client] = false;
    g_bFroggyjump[client] = false;
    g_bFroggyPressed[client] = false;
    g_bLongjump[client] = false;
    g_bBhop[client] = false;
    g_bAssassine[client] = false;
    g_bTollpatsch[client] = false;
    g_bLose[client] = false;

    g_fDamage[client] = 0.0;
    g_bCTMoreDamage[client] = false;
    g_bCTLessDamage[client] = false;
    g_bCTHeadshot[client] = false;
    g_bCTRespawn[client] = false;
    
    g_bBusy[client] = false;
    
    delete g_hNoclip[client];
    delete g_hLowGravity[client];
    delete g_hHighGravity[client];
    delete g_hTimer[client];
}

stock bool IsClientStuck(int client)
{
    float vOrigin[3], vMins[3], vMaxs[3];

    GetClientAbsOrigin(client, vOrigin);

    GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
    GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
    
    TR_TraceHullFilter(vOrigin, vOrigin, vMins, vMaxs, MASK_ALL, FilterOnlyPlayers, client);

    return TR_DidHit();
}

public bool FilterOnlyPlayers(int entity, int contentsMask, any data)
{
    if(entity != data && IsClientValid(entity) && IsClientValid(data))
    {
        return false;
    }
    else if (entity != data)
    {
        return true;
    }
    else
    {
        return false;
    }
}

float GetClientSpeed(int client)
{
    return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

float SetClientSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);

    return GetClientSpeed(client);
}


