#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PAINTBALL_VERSION      "1.2.0"

//#define PAINTBALL_DEBUG 1

public Plugin:myinfo = 
{
    name = "Paintball",
    author = "otstrel.ru Team",
    description = "Add paintball impacts on the map after shots.",
    version = PAINTBALL_VERSION,
    url = "otstrel.ru"
}

new g_SpriteIndex[128];
new g_SpriteIndexCount = 0;

public OnPluginStart()
{
    LoadTranslations("paintball.phrases");

    HookEvent("bullet_impact", Event_BulletImpact);
}
    
public OnMapStart()
{
    #if defined PAINTBALL_DEBUG
        LogError("[PAINTBALL_DEBUG] OnMapStart()");
    #endif
    g_SpriteIndexCount = 0;
    
    // Load config file with colors
    new Handle:KvColors = CreateKeyValues("colors");
    new String:ConfigFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/paintball.cfg");
    if ( !FileToKeyValues(KvColors, ConfigFile) )
    {
        CloseHandle(KvColors);
        LogError("[ERROR] paintball can not convert file to keyvalues: %s", ConfigFile);
        return;
    }

    // Find first color section
    KvRewind(KvColors);
    new bool:sectionExists;
    sectionExists = KvGotoFirstSubKey(KvColors);
    if ( !sectionExists )
    {
        CloseHandle(KvColors);
        LogError("[ERROR] paintball can not find first keyvalues subkey in file: %s", ConfigFile);
        return;
    }

    new String:filename[PLATFORM_MAX_PATH];
    // Load all colors
    while ( sectionExists )
    {
        #if defined PAINTBALL_DEBUG
            LogError("[PAINTBALL_DEBUG] OnMapStart :: check if color enabled : %i", KvGetNum(KvColors, "enabled") );
        #endif
        if ( KvGetNum(KvColors, "enabled") )
        {
            KvGetString(KvColors, "primary", filename, sizeof(filename));
            g_SpriteIndex[g_SpriteIndexCount++] = precachePaintballDecal(filename);
            KvGetString(KvColors, "secondary", filename, sizeof(filename));
            precachePaintballDecal(filename);
        }

        sectionExists = KvGotoNextKey(KvColors);
    }
    
    CloseHandle(KvColors);
}

precachePaintballDecal(const String:filename[])
{
    #if defined PAINTBALL_DEBUG
        LogError("[PAINTBALL_DEBUG] precachePaintballDecal(%s)", filename);
    #endif
    new String:tmpPath[PLATFORM_MAX_PATH];
    new result = 0;
    result = PrecacheDecal(filename, true);
    Format(tmpPath,sizeof(tmpPath),"materials/%s",filename);
    AddFileToDownloadsTable(tmpPath);
    #if defined PAINTBALL_DEBUG
        LogError("[PAINTBALL_DEBUG] precachePaintballDecal :: return %i", result);
    #endif
    return result;
}

public Action:Event_BulletImpact(Handle:event, const String:weaponName[], bool:dontBroadcast)
{
    static Float:pos[3];
    pos[0] = GetEventFloat(event,"x");
    pos[1] = GetEventFloat(event,"y");
    pos[2] = GetEventFloat(event,"z");

    // Setup new decal
    TE_SetupWorldDecal(pos, g_SpriteIndex[GetRandomInt(0, g_SpriteIndexCount - 1)]);
    TE_SendToAll();
}

TE_SetupWorldDecal(const Float:vecOrigin[3], index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("m_nIndex",index);
}
