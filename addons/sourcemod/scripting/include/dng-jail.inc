#if defined _DNG_included
 #endinput
#endif
#define _DNG_included

#define MTF MENU_TIME_FOREVER

#pragma deprecated OB mit MultiColors ersetzen - Einfacher mit mehr Funktionen
#define OB "[\DNG\x01]"

// #define TAG "{darkblue}[DNG]{default}"
#define TAGT "{darkblue}[DNG] {default}%T"
#define TEXT "{default}"
#define SPECIAL "{lightgreen}"
#define ADMFLAG_VIP ADMFLAG_CUSTOM6
#define DNG_BASE "DNG"

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))
#define LoopAllClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1, true))

#include <sdktools>
#include <cstrike>
#include <multicolors>

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

stock bool IsFreezeTime()
{
    if(GameRules_GetProp("m_bFreezePeriod"))
    {
        return true;
    }
    return false;
}

stock void StripWeapons(int client, bool knife = true)
{
    int weapon;
    
    for(int i = 0; i < 5; i++) 
    { 
        if((weapon = GetPlayerWeaponSlot(client, i)) != -1) 
        { 
            SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR); 
            AcceptEntityInput(weapon, "Kill"); 
        } 
    }
    
    if(!knife)
    {
        GivePlayerItem(client, "weapon_knife");
    }
}

stock bool IsClientAdmin(int client)
{
    if (CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC, true) || CheckCommandAccess(client, "sm_admin", ADMFLAG_ROOT, true))
    {
        return true;
    }
    
    return false;
}

public void PrintToBara(const char[] message, any ...) 
{
    LoopClients(i)
    {
        char steamid[64];
        GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
        
        if(StrEqual(steamid, "STEAM_1:1:40828751"))
        {
            char sBuffer[MAX_MESSAGE_LENGTH];
            VFormat(sBuffer, sizeof(sBuffer), message, 2);

            PrintToChat(i, sBuffer);
        }
    }
}

stock int GetAliveTPlayers()
{
    int iTCount = 0;
    
    LoopClients(client)
    {
        if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
        {
            iTCount++;
        }
    }
    
    return iTCount;
}

stock int GetAliveCTPlayers()
{
    int iCTCount = 0;
    
    LoopClients(client)
    {
        if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
        {
            iCTCount++;
        }
    }
    
    return iCTCount;
}

stock int GetAlivePlayers()
{
    int iPlayerCount = 0;
    
    LoopClients(client)
    {
        if(IsPlayerAlive(client))
        {
            iPlayerCount++;
        }
    }
    
    return iPlayerCount;
}

stock int GetLastAlivePlayer()
{
    int lastPlayer;
    
    LoopClients(client)
    {
        if(IsPlayerAlive(client))
        {
            lastPlayer = client;
            break;
        }
    }
    
    return lastPlayer;
}

stock bool DNG_HasFlags(int client, const char[] flags)
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

stock int GetRandomPlayer(int team)
{
    SetRandomSeed(GetTime() * 100 * GetRandomInt(2, 9));
    
    int[] clients = new int[MaxClients + 1];
    int clientCount;
    
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientValid(i) && (GetClientTeam(i) == team) && IsPlayerAlive(i))
            clients[clientCount++] = i;
    
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
} 

stock void DNG_StripAllWeapons(int client)
{
    for(int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
    {
        int index = -1;
        while((index = GetPlayerWeaponSlot(client, i)) != -1)
        {
            SafeRemoveWeapon(client, index);
        }
    }
}

stock void RemoveAllWeapons(int client)
{
    for(int offset = 0; offset < 128; offset += 4)
    {
        int weapon = GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hMyWeapons") + offset);

        if (IsValidEntity(weapon))
        {
            SafeRemoveWeapon(client, weapon);
        }
    }
}

stock bool SafeRemoveWeapon(int iClient, int iWeapon)
{
    if (!IsValidEntity(iWeapon) || !IsValidEdict(iWeapon))
        return false;
    
    if (!HasEntProp(iWeapon, Prop_Send, "m_hOwnerEntity"))
        return false;
    
    int iOwnerEntity = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
    
    if (iOwnerEntity != iClient)
        SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iClient);
    
    CS_DropWeapon(iClient, iWeapon, false);
    
    if (HasEntProp(iWeapon, Prop_Send, "m_hWeaponWorldModel"))
    {
        int iWorldModel = GetEntPropEnt(iWeapon, Prop_Send, "m_hWeaponWorldModel");
        
        if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
            if (!AcceptEntityInput(iWorldModel, "Kill"))
                return false;
    }
    
    if (!AcceptEntityInput(iWeapon, "Kill"))
        return false;
    
    return true;
}

stock int FindClientByName(const char[] name, bool caseSensitive = false)
{
    char clientName[MAX_NAME_LENGTH];
    
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientValid(client))
            continue;

        GetClientName(client, clientName, sizeof(clientName));

        if (StrEqual(name, clientName, caseSensitive))
            return client;
    }

    return -1;
}

stock bool CanTargetPlayer(int client, int target)
{
    char saID[32], stID[32], sSteam[32] = "steam";
    GetClientAuthId(client, AuthId_Steam2, saID, sizeof(saID));
    GetClientAuthId(target, AuthId_Steam2, stID, sizeof(stID));
    
    AdminId aID = FindAdminByIdentity(sSteam, saID);
    AdminId tID = FindAdminByIdentity(sSteam, stID);
    
    return CanAdminTarget(aID, tID);
}

