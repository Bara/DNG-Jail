#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <dng-jail>


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
    RegConsoleCmd("sm_chair", Command_Chair);
}

public void OnMapStart()
{
    PrecacheModel("models/props_interiors/furniture_chair03a.mdl");
    PrecacheModel("models/props/gg_tibet/modernchair.mdl");
    PrecacheModel("models/props_urban/hotel_chair001.mdl");
    PrecacheModel("models/props_urban/plastic_chair001.mdl");
    PrecacheModel("models/props_c17/furniturechair001a_static.mdl");

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
    /* PrintToChat(client, "SpawnChair - 1");
    int iEnt = CreateEntityByName("prop_physics_override");

    if (iEnt == -1)
        return;
    
    PrintToChat(client, "SpawnChair - 2, Ent: %d", iEnt);
    
    if (!IsModelPrecached("models/props_interiors/furniture_chair03a.mdl"))
        PrecacheModel("models/props_interiors/furniture_chair03a.mdl");
    
    PrintToChat(client, "SpawnChair - 3, Model precached");
    
    SetEntityModel(iEnt, "models/props_interiors/furniture_chair03a.mdl");
    DispatchKeyValue(iEnt, "StartDisabled", "false"); 
    DispatchKeyValue(iEnt, "physdamagescale", "50.0");
    DispatchKeyValue(iEnt, "spawnflags", "8"); 
    DispatchKeyValue(iEnt, "Solid", "6"); 
    SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
    SetEntityRenderColor(iEnt, 255, 255, 255, 255);
    
    SetEntProp(iEnt, Prop_Send, "m_nSolidType", 6);
    
    if (DispatchSpawn(iEnt))
    {
        PrintToChat(client, "SpawnChair - 4, Spawn");

        float fPosition[3];
        GetClientEyePosition(client, fPosition);

        TeleportEntity(iEnt, fPosition, NULL_VECTOR, NULL_VECTOR);
    } */

    int iEnt = CreateEntityByName("prop_physics_multiplayer");
    if (iEnt != -1)
    {
        float clientPos[3];
        GetClientAbsOrigin(client, clientPos);
        clientPos[0] += 40.0;
        SetEntProp(iEnt, Prop_Send, "m_hOwnerEntity", client);
        DispatchKeyValue(iEnt, "model", "models/props_c17/furniturechair001a_static.mdl");
        // DispatchKeyValue(iEnt, "model", "models/props_urban/plastic_chair001.mdl");
        // DispatchKeyValue(iEnt, "model", "models/props_urban/hotel_chair001.mdl");
        // DispatchKeyValue(iEnt, "model", "models/props/gg_tibet/modernchair.mdl");
        // DispatchKeyValue(iEnt, "model", "models/props_interiors/furniture_chair03a.mdl");
        DispatchSpawn(iEnt);
        SetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 5);
        SetEntProp(iEnt, Prop_Data, "m_nSolidType", 6);
        AcceptEntityInput(iEnt, "EnableMotion");
        SetEntityMoveType(iEnt, MOVETYPE_VPHYSICS);
        TeleportEntity(iEnt, clientPos, NULL_VECTOR, NULL_VECTOR);

        ConVar cvar = FindConVar("phys_pushscale");

        if (cvar != null)
        {
            int iOld = cvar.IntValue;
            PrintToChat(client, "Old Value: %d", iOld);
            cvar.SetInt(13);
        }
    }

    
}
