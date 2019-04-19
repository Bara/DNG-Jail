#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <autoexecconfig>

int g_iColorT[4] =  {255, 0, 0};
int g_iColorCT[4] =  {0, 0, 255};

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Glow"

ConVar g_cDGlow = null;
ConVar g_cDebug = null;

int g_iPlayerModels[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE,...};
int g_iPlayerModelsIndex[MAXPLAYERS+1] = {-1,...};

Handle g_hOnGlowCheck = null;

public Plugin myinfo =
{
    name = "Glow - Core",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "github.com/Bara"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_hOnGlowCheck = CreateGlobalForward("OnGlowCheck", ET_Event, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef);
    
    RegPluginLibrary("glow");

    return APLRes_Success;
}

public void OnPluginStart()
{
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("glow");
    CreateConVar("glow_version", "1.0.0", "", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_REPLICATED);
    g_cDGlow = AutoExecConfig_CreateConVar("glow_detective_enable", "1", "CT see the glows of other CTs. 0 to disable.", _, true, 0.0, true, 1.0);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
    
}

public void OnPluginEnd()
{
    destoryGlows();
}

public void OnConfigsExecuted()
{
    g_cDebug = FindConVar("ttt_debug_mode");
    
    ConVar cvar = FindConVar("sv_force_transmit_players");
    cvar.SetBool(true, true, false);
}

public void TTT_OnClientGetRole(int client, int role)
{
    checkGlows();
}

public Action TTT_OnPlayerDeath(int victim, int attacker)
{
    checkGlows();
}

public void checkGlows() {
    destoryGlows();
    createGlows();
}

public void destoryGlows() {
    for(int client = 1; client <= MaxClients; client++) {
        if(IsClientInGame(client)) {
            RemoveSkin(client);
        }
    }
}

public void createGlows() {
    char model[PLATFORM_MAX_PATH];
    int skin = -1;
    for(int client = 1; client <= MaxClients; client++) {
        if(!IsClientInGame(client) || !IsPlayerAlive(client)) {
            continue;
        }
        
        int iTeam = GetClientTeam(client);
        if(iTeam <= 1) {
            continue;
        }
        
        if (!g_cDGlow.BoolValue && iTeam == CS_TEAM_CT)
        {
            continue;
        }
        
        GetClientModel(client, model, sizeof(model));
        skin = CreatePlayerModelProp(client, model);
        if(skin > MaxClients) {
            if(SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit_All)) {
                setGlowTeam(skin, iTeam, client);
            }
        }
    }
}

public Action OnSetTransmit_All(int skin, int client) {
    int iTeam = GetClientTeam(client);

    int target = -1;
    
    LoopClients(i)
    {
        if (i < 1)
        {
            continue;
        }

        if (client == i)
        {
            continue;
        }

        if (!g_cDebug.BoolValue && IsFakeClient(i))
        {
            continue;
        }

        if (!IsPlayerAlive(i))
        {
            continue;
        }

        if (g_iPlayerModelsIndex[i] != skin)
        {
            continue;
        }
        
        target = i;
    }
    
    if (target == -1)
    {
        return Plugin_Handled;
    }
    
    int iTTeam = GetClientTeam(target);
        
    if (iTeam == CS_TEAM_CT && iTeam == iTTeam)
    {
        return Plugin_Continue;
    }
    
    bool seeTarget = false;
    bool override = false;
    int red = 255;
    int green = 255;
    int blue = 255;
    int alpha = 255;
    int style = 0;
    
    Call_StartForward(g_hOnGlowCheck);
    Call_PushCell(client);
    Call_PushCell(target);
    Call_PushCellRef(seeTarget);
    Call_PushCellRef(override);
    Call_PushCellRef(red);
    Call_PushCellRef(green);
    Call_PushCellRef(blue);
    Call_PushCellRef(alpha);
    Call_PushCellRef(style);
    Call_Finish();
    
    if (seeTarget)
    {
        return Plugin_Continue;
    }
    
    return Plugin_Handled;
}

public void setGlowTeam(int skin, int team, int client) {
    if(team >= 2) {
        if (GetClientTeam(client) == CS_TEAM_CT)
        {
            SetupGlow(skin, g_iColorCT);
        }
        else if (GetClientTeam(client) == CS_TEAM_T)
        {
            SetupGlow(skin, g_iColorT);
        }
    }
}

public void SetupGlow(int skin, int color[4]) {
    int offset;
    // Get sendprop offset for prop_dynamic_override
    if (!offset && (offset = GetEntSendPropOffs(skin, "m_clrGlow")) == -1) {
        LogError("Unable to find property offset: \"m_clrGlow\"!");
        return;
    }

    // Enable glow for custom skin
    SetEntProp(skin, Prop_Send, "m_bShouldGlow", true, true);
    SetEntProp(skin, Prop_Send, "m_nGlowStyle", 0);
    SetEntPropFloat(skin, Prop_Send, "m_flGlowMaxDist", 10000000.0);

    // So now setup given glow colors for the skin
    for(int i=0;i<3;i++) {
        SetEntData(skin, offset + i, color[i], _, true); 
    }
}

public int CreatePlayerModelProp(int client, char[] sModel) {
    RemoveSkin(client);
    int skin = CreateEntityByName("prop_dynamic_override");
    DispatchKeyValue(skin, "model", sModel);
    DispatchKeyValue(skin, "disablereceiveshadows", "1");
    DispatchKeyValue(skin, "disableshadows", "1");
    DispatchKeyValue(skin, "solid", "0");
    DispatchKeyValue(skin, "spawnflags", "256");
    SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
    DispatchSpawn(skin);
    SetEntityRenderMode(skin, RENDER_TRANSALPHA);
    SetEntityRenderColor(skin, 0, 0, 0, 0);
    SetEntProp(skin, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);
    SetVariantString("!activator");
    AcceptEntityInput(skin, "SetParent", client, skin);
    SetVariantString("primary");
    AcceptEntityInput(skin, "SetParentAttachment", skin, skin, 0);
    g_iPlayerModels[client] = EntIndexToEntRef(skin);
    g_iPlayerModelsIndex[client] = skin;
    return skin;
}

public void RemoveSkin(int client) {
    if(IsValidEntity(g_iPlayerModels[client])) {
        AcceptEntityInput(g_iPlayerModels[client], "Kill");
    }
    g_iPlayerModels[client] = INVALID_ENT_REFERENCE;
    g_iPlayerModelsIndex[client] = -1;
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
