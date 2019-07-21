#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <dng-jail>
#include <lastrequest>

bool g_bRunning = false;

int g_iLR = -1;
int g_iCurrentLR = -1;
int g_iLRMode = -1;

int g_iLRPrisoner = -1;
int g_iLRGuard = -1;
int g_iLRChair[MAXPLAYERS + 1] = { -1, ... };

ConVar g_cPushscale = null;
int g_iOldValue = -1;

public Plugin myinfo =
{
    name = "Lastrequest - Chair", 
    author = "Bara", 
    description = "", 
    version = "1.0", 
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_chair", Command_Chair, ADMFLAG_ROOT);
    
    HookEvent("round_start", Event_RoundStart);

    CSetPrefix("{darkblue}[%s]{default}", DNG_BASE);

    if (g_bRunning) {} // Fix error
}

public void OnConfigsExecuted()
{
    static bool bLastRequest = false;
    if (!bLastRequest)
    {
        g_iLR = AddLastRequestToList(LR_Start, LR_Stop, "Chair Game", false);
        bLastRequest = true;
    }

    g_cPushscale = FindConVar("phys_pushscale");
}

public void OnMapStart()
{
    PrecacheModel("models/props/gg_tibet/modernchair.mdl"); // 1
    PrecacheModel("models/props_urban/hotel_chair001.mdl"); // 2
    PrecacheModel("models/props_urban/plastic_chair001.mdl"); // 3
    PrecacheModel("models/props_c17/furniturechair001a_static.mdl"); // 4
}

public void OnPluginEnd()
{
    RemoveLastRequestFromList(LR_Start, LR_Stop, "Chair Game");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ResetSettings();
}

public int LR_Start(Handle LR_Array, int iIndexInArray)
{
    g_iCurrentLR = GetArrayCell(LR_Array, iIndexInArray, view_as<int>(Block_LRType));
    
    if(g_iCurrentLR == g_iLR)
    {
        StartLR(LR_Array, iIndexInArray);
    }
}

void StartLR(Handle hArray, int inArray)
{
    g_iLRPrisoner = GetArrayCell(hArray, inArray, view_as<int>(Block_Prisoner));
    g_iLRGuard = GetArrayCell(hArray, inArray, view_as<int>(Block_Guard));
    
    g_iLRChair[g_iLRPrisoner] = SpawnChair(g_iLRPrisoner);
    g_iLRChair[g_iLRGuard] = SpawnChair(g_iLRGuard);

    if (g_iLRChair[g_iLRPrisoner] == -1 || g_iLRChair[g_iLRGuard] == -1)
    {
        PrintToChatAll("Something went wrong with spawning chairs... LR will be resetted.");
        ResetSettings();
        CleanupLR(g_iLRPrisoner);
        return;
    }
    
    g_bRunning = true;

    g_iOldValue = g_cPushscale.IntValue;
    g_cPushscale.SetInt(12);
    
    CPrintToChatAll("%N spielt gegen %N Chair Game. Wer zuerst den Stuhl/Sessel aufrecht stehen hat gewinnt.", g_iLRPrisoner, g_iLRGuard);
    
    if (IsClientValid(g_iLRPrisoner))
    {
        InitializeLR(g_iLRPrisoner);
    }
}

public int LR_Stop(int Type, int Prisoner, int Guard)
{
    ResetSettings();
}

public Action Command_Chair(int client, int args)
{
    if (!IsClientValid(client))
    {
        return;
    }

    SpawnChair(client);
}

int SpawnChair(int client)
{
    int iEnt = CreateEntityByName("prop_physics_multiplayer");
    if (iEnt != -1)
    {
        float clientPos[3];
        GetClientAbsOrigin(client, clientPos);
        clientPos[0] += 40.0;

        g_iLRMode = GetRandomInt(1, 4);

        SetEntProp(iEnt, Prop_Send, "m_hOwnerEntity", client);

        if (g_iLRMode == 1)
        {
            DispatchKeyValue(iEnt, "model", "models/props/gg_tibet/modernchair.mdl"); // 1
        }
        else if (g_iLRMode == 2)
        {
            DispatchKeyValue(iEnt, "model", "models/props_urban/hotel_chair001.mdl"); // 2
        }
        else if (g_iLRMode == 3)
        {
            DispatchKeyValue(iEnt, "model", "models/props_urban/plastic_chair001.mdl"); // 3
        }
        else if (g_iLRMode == 4)
        {
            DispatchKeyValue(iEnt, "model", "models/props_c17/furniturechair001a_static.mdl"); // 4
        }
        
        if (DispatchSpawn(iEnt))
        {
            SetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 5);
            SetEntProp(iEnt, Prop_Data, "m_nSolidType", 6);
            AcceptEntityInput(iEnt, "EnableMotion");
            SetEntityMoveType(iEnt, MOVETYPE_VPHYSICS);
            TeleportEntity(iEnt, clientPos, NULL_VECTOR, NULL_VECTOR);
        }
        else
        {
            AcceptEntityInput(iEnt, "kill");
            return -1;
        }
    }

    return iEnt;
}

void ResetSettings()
{
    g_cPushscale.SetInt(g_iOldValue);
    g_iOldValue = -1;

    g_bRunning = false;

    g_iLR = -1;
    g_iCurrentLR = -1;
    g_iLRMode = -1;
    
    g_iLRPrisoner = -1;
    g_iLRGuard = -1;

    LoopClients(i)
    {
        if (IsValidEntity(g_iLRChair[i]))
        {
            AcceptEntityInput(g_iLRChair[i], "kill");
        }

        g_iLRChair[i] = -1;
    }
}
