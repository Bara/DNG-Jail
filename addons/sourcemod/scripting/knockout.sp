#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dng-jail>
#include <sourcecomms>
#include <dice>
#include <hide>
#include <zombie>

public Plugin myinfo =
{
    name = "Knockout - Core",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "dng.xyz"
}

int g_iFreeze = -1;
int g_iMyWeapons = -1;

bool g_bKnockout[MAXPLAYERS+1] = {false, ...};
int g_iRagdoll[MAXPLAYERS+1] = {-1, ...};

UserMsg g_uFade;
int g_iCamera[MAXPLAYERS + 1] = { -1, ... };

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("IsClientKnockout", Native_IsKnockout);
    CreateNative("SetClientKnockout", Native_SetKnockout);

    RegPluginLibrary("knockout");

    return APLRes_Success;
}

public void OnPluginStart()
{
    g_iFreeze = FindSendPropInfo("CBasePlayer", "m_fFlags");
    if(g_iFreeze == -1)
    {
        SetFailState("CBasePlayer:m_fFlags not found");
        return;
    }
    
    g_iMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
    if (g_iMyWeapons == -1)
    {
        SetFailState("CBasePlayer:m_hMyWeapons not found");
        return;
    }

    g_uFade = GetUserMessageId("Fade");

    LoopClients(i)
    {
        OnClientPutInServer(i);
    }
    
    RegAdminCmd("sm_knockout", Command_Knockout, ADMFLAG_GENERIC);
    
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnClientDisconnect(int client)
{
    g_bKnockout[client] = false;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    g_bKnockout[client] = false;
}

public Action Command_Knockout(int client, int args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "sm_knockout <#UserID|Name>");
        return Plugin_Handled;
    }
    
    int targets[129];
    bool ml = false;
    char buffer[MAX_NAME_LENGTH], arg1[MAX_NAME_LENGTH], arg2[512];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    Format(arg2, sizeof(arg2), "");
    
    if (args >= 2)
    {
        for (int i = 2; i <= args; i++)
        {
            char sBuffer[64];
            GetCmdArg(i, sBuffer, sizeof(sBuffer));
            Format(arg2, sizeof(arg2), "%s %s", arg2, sBuffer);
        }
    }
    
    int count = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, buffer, sizeof(buffer), ml);
    if (count <= 0)
    {
        ReplyToCommand(client, "Invalid Target");
    }
    else for (int i = 0; i < count; i++)
    {
        int target = targets[i];
        
        if(!IsClientValid(target))
        {
            return Plugin_Handled;
        }
        
        if (!g_bKnockout[target])
        {
            KnockoutPlayer(target);
        }
    }
    
    return Plugin_Continue;
}

bool KnockoutPlayer(int client)
{
    if (Hide_IsActive() || Zombie_IsActive())
    {
        return false;
    }

    if (IsFakeClient(client) || IsClientSourceTV(client))
    {
        return false;
    }
    
    g_bKnockout[client] = true;

    char sModel[256];
    GetClientModel(client, sModel, sizeof(sModel));

    float pos[3];
    GetClientEyePosition(client, pos);

    int iEntity = CreateEntityByName("prop_ragdoll");
    DispatchKeyValue(iEntity, "model", sModel);
    SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
    SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 5);
    DispatchSpawn(iEntity);

    pos[2] -= 16.0;
    TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
    SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 2);

    g_iRagdoll[client] = iEntity;
    SetEntityRenderMode(client, RENDER_NONE);
    StripPlayerWeapons(client);
    Entity_SetNonMoveable(client);

    CreateTimer(0.1, Timer_FixMode, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    CreateTimer(5.0, Timer_Delete, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    SpawnCamAndAttach(client, iEntity);

    PerformBlind(client, 255);
    
    SourceComms_SetClientMute(client, true, 1, false, "Knockout");

    return g_bKnockout[client];
}

public Action Timer_FixMode(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if (IsClientValid(client))
    {
        if (g_bKnockout[client])
        {
            SetEntityRenderMode(client, RENDER_NONE);
        }
        
        return Plugin_Continue;
    }
    
    return Plugin_Stop;
}

public Action OnWeaponCanUse(int client, int weapon)
{
    if(!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    if(g_bKnockout[client])
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (IsClientValid(attacker) && IsClientValid(victim) && IsValidEntity(weapon))
    {
        char sWeapon[32];
        GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
        
        if (StrContains(sWeapon, "taser", false) != -1)
        {
            if (!g_bKnockout[victim])
            {
                KnockoutPlayer(victim);
                return Plugin_Handled;
            }
        }

        if(g_bKnockout[victim])
        {
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public Action Timer_Delete(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if (IsClientValid(client))
    {
        int entity = g_iRagdoll[client];
    
        if (entity > 0 && IsValidEntity(entity))
            AcceptEntityInput(entity, "kill");
        
        int entity2 = EntRefToEntIndex(g_iCamera[client]);
        if(entity2 > 0 && IsValidEntity(entity))
            AcceptEntityInput(entity2, "kill");
        
        g_iCamera[client] = -1;
        g_iRagdoll[client] = -1;
        g_bKnockout[client] = false;
        
        RequestFrame(Frame_WaitTick, GetClientUserId(client));
    }
}

public void Frame_WaitTick(any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client) && IsPlayerAlive(client))
    {
        SourceComms_SetClientMute(client, false);
        Entity_SetMoveable(client);
        SetClientViewEntity(client, client);
        g_iCamera[client] = false;
        PerformBlind(client, 0);

        if(!Dice_LoseAll(client))
        {
            GivePlayerItem(client, "weapon_knife");
        }

        SetEntityRenderMode(client, RENDER_TRANSCOLOR);
        SetEntityRenderColor(client, 255, 255, 255);
    }
}

stock void Entity_SetNonMoveable(int entity)
{
    SetEntData(entity, g_iFreeze, FL_CLIENT|FL_ATCONTROLS, 4, true);
}

stock void Entity_SetMoveable(int entity)
{
    SetEntData(entity, g_iFreeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
}

stock void StripPlayerWeapons(int client)
{
    for(int offset = 0; offset < 128; offset += 4)
    {
        int weapon = GetEntDataEnt2(client, g_iMyWeapons + offset);

        if (IsValidEntity(weapon))
        {
            char sClass[32];
            GetEntityClassname(weapon, sClass, sizeof(sClass));

            if ((StrContains(sClass, "knife", false) != -1) || (StrContains(sClass, "bayonet", false) != -1))
            {
                SafeRemoveWeapon(client, weapon);
            }
            else
            {
                CS_DropWeapon(client, weapon, true, true);
            }
        }
    }
}

stock bool SpawnCamAndAttach(int iClient, int iRagdoll)
{
    char sModel[64];
    Format(sModel, sizeof(sModel), "models/blackout.mdl"); //
    PrecacheModel(sModel, true);

    char sTargetName[64]; 
    Format(sTargetName, sizeof(sTargetName), "ragdoll%d", iClient);
    DispatchKeyValue(iRagdoll, "targetname", sTargetName);

    int iEntity = CreateEntityByName("prop_dynamic");
    if (iEntity == -1)
        return false;

    char sCamName[64]; 
    Format(sCamName, sizeof(sCamName), "ragdollCam%d", iEntity);

    DispatchKeyValue(iEntity, "targetname", sCamName);
    DispatchKeyValue(iEntity, "parentname", sTargetName);
    DispatchKeyValue(iEntity, "model",	  sModel);
    DispatchKeyValue(iEntity, "solid",	  "0");
    DispatchKeyValue(iEntity, "rendermode", "10"); // dont render
    DispatchKeyValue(iEntity, "disableshadows", "1"); // no shadows

    float fAngles[3]; 
    GetClientEyeAngles(iClient, fAngles);
    
    char sCamAngles[64];
    Format(sCamAngles, 64, "%f %f %f", fAngles[0], fAngles[1], fAngles[2]);
    
    DispatchKeyValue(iEntity, "angles", sCamAngles);

    SetEntityModel(iEntity, sModel);
    DispatchSpawn(iEntity);

    SetVariantString(sTargetName);
    AcceptEntityInput(iEntity, "SetParent", iEntity, iEntity, 0);

    SetVariantString("facemask");
    AcceptEntityInput(iEntity, "SetParentAttachment", iEntity, iEntity, 0);

    AcceptEntityInput(iEntity, "TurnOn");

    SetClientViewEntity(iClient, iEntity);
    g_iCamera[iClient] = EntIndexToEntRef(iEntity);

    return true;
}


void PerformBlind(int client, int amount)
{
    int targets[2];
    targets[0] = client;

    int duration = 1536;
    int holdtime = 1536;
    int flags;
    if (amount == 0)
        flags = (0x0001 | 0x0010);
    else flags = (0x0002 | 0x0008);

    int color[4] = { 0, 0, 0, 0 };
    color[3] = amount;

    Handle message = StartMessageEx(g_uFade, targets, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        PbSetInt(message, "duration", duration);
        PbSetInt(message, "hold_time", holdtime);
        PbSetInt(message, "flags", flags);
        PbSetColor(message, "clr", color);
    }
    else
    {
        BfWriteShort(message, duration);
        BfWriteShort(message, holdtime);
        BfWriteShort(message, flags);
        BfWriteByte(message, color[0]);
        BfWriteByte(message, color[1]);
        BfWriteByte(message, color[2]);
        BfWriteByte(message, color[3]);
    }

    EndMessage();
}

public int Native_IsKnockout(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return g_bKnockout[client];
}

public int Native_SetKnockout(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (!g_bKnockout[client])
    {
        return KnockoutPlayer(client);
    }

    return false;
}
