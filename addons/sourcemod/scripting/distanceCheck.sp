#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <multicolors>

int g_iTime[MAXPLAYERS + 1] = { -1, ... };

public Plugin myinfo =
{
    name = "Distance Check",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    CreateTimer(0.2, Timer_CheckDistance, _, TIMER_REPEAT);
}

public Action Timer_CheckDistance(Handle timer)
{
    float fClientPos[3];
    float fTargetPos[3];
    float fDistance;
    float fMeters;

    ArrayList aPlayers[MAXPLAYERS + 1] = { null, ... };

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
        {
            GetClientAbsOrigin(client, fClientPos);

            aPlayers[client] = new ArrayList();

            for (int target = 1; target <= MaxClients; target++)
            {
                if (IsClientInGame(target) && IsPlayerAlive(target) &&
                    (!IsFakeClient(target) && !IsClientSourceTV(target)) &&
                    target != client && (GetClientTeam(client) != GetClientTeam(target))
                    )
                {
                    GetClientAbsOrigin(target, fTargetPos);

                    fDistance = GetVectorDistance(fClientPos, fTargetPos);

                    fMeters = fDistance * 0.01905;

                    if (fMeters < 4.1)
                    {
                        aPlayers[client].Push(GetClientUserId(target));
                    }
                }
            }

            if (aPlayers[client].Length > 0 && (g_iTime[client] == -1 || g_iTime[client] + 3 <= GetTime()))
            {
                CPrintToChat(client, "Spieler die dir nahe sind:");

                for (int i = 0; i < aPlayers[client].Length; i++)
                {
                    int target = GetClientOfUserId(aPlayers[client].Get(i));

                    if (IsClientInGame(target) && IsPlayerAlive(target))
                    {
                        CPrintToChat(client, "- %N", target);
                    }
                }

                g_iTime[client] = GetTime();
            }

            delete aPlayers[client];
        }
    }

    return Plugin_Continue;
}
