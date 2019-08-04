#pragma semicolon 1

#include <sourcemod>
#include <kstore>

public Action Store_OnFPDeathCamera(int client)
{
    return Plugin_Stop;
}
