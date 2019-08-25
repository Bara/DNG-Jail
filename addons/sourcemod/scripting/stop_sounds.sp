#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "Stop Annoying Map Sounds",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "github.com/Bara"
};

public void OnPluginStart()
{
    AddAmbientSoundHook(OnAmbientSound);
    AddNormalSoundHook(OnNormalSound);
}

public Action OnAmbientSound(char sample[PLATFORM_MAX_PATH], int& entity, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
    // PrintToConsoleAll("(OnAmbientSound) Sound from %d with sample: %s", entity, sample);

    if (StrContains(sample, "jb_undertale/core.mp3", false) != -1)
    {
        EmitAmbientSound(sample, pos, entity, level, flags, 0.1, pitch, delay);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public Action OnNormalSound(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
    // PrintToConsoleAll("(OnNormalSound) Sound from %d with sample: %s", entity, sample);

    if (StrContains(sample, "~doors/doormove7.wav", false) != -1)
    {
        volume = 0.1;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}
