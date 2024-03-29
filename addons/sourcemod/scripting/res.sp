#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <clientprefs>
#include <cstrike>
#include <emitsoundany>

#pragma newdecls required // 2015 rules 
#pragma semicolon 1

//MapSounds Stuff
int g_iSoundEnts[2048];
int g_iNumSounds;

//Cvars
Handle g_hCTPath;
Handle g_hTRPath;
Handle g_hPlayType;
Handle g_hCookie;
Handle g_hStop;
Handle g_PlayPrint;
Handle g_roundDrawPlay;
Handle g_ClientSettings;

bool SoundsTRSucess = false;
bool SoundsCTSucess = false;
bool SamePath = false;
//Sounds Arrays
ArrayList ctSound;
ArrayList trSound;

public Plugin myinfo =
{
	name = "Round End Sounds",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara"
}

public void OnPluginStart()
{  
	//Cvars
	g_hTRPath	               = CreateConVar("res_tr_path", "outbreak717v3/res", "Path off tr sounds in /cstrike/sound");
	g_hCTPath   	           = CreateConVar("res_ct_path", "outbreak717v3/res", "Path off ct sounds in /cstrike/sound");
	g_hPlayType                = CreateConVar("res_play_type", "1", "1 - Random, 2- Play in queue");
	g_hStop                    = CreateConVar("res_stop_map_music", "1", "Stop map musics");	
	g_PlayPrint                = CreateConVar("res_print_to_chat_mp3_name", "1", "Print mp3 name in chat (Suggested by m22b)");
	g_roundDrawPlay            = CreateConVar("res_rounddraw_play", "1", "0 - Don´t play sounds, 1 - Play TR sounds, 2 - Play CT sounds.");
	g_ClientSettings	       = CreateConVar("res_client_preferences", "1", "Enable/Disable client preferences");
	
	//ClientPrefs
	g_hCookie = RegClientCookie("Round End Sounds", "", CookieAccess_Private);
	SetCookieMenuItem(SoundCookieHandler, 0, "Round End Sounds");
	
	LoadTranslations("common.phrases");
	LoadTranslations("res.phrases");
	AutoExecConfig(true, "res2");

	RegAdminCmd("res_refresh", CommandLoad, ADMFLAG_SLAY);
	RegConsoleCmd("res", Commamnd_RES);
	RegAdminCmd("sm_playres", Command_PlayRes, ADMFLAG_ROOT);
	
	HookConVarChange(g_hTRPath, PathChange);
	HookConVarChange(g_hCTPath, PathChange);
	HookConVarChange(g_hPlayType, PathChange);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	
	ctSound = new ArrayList(512);
	trSound = new ArrayList(512);
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public void StopMapMusic()
{
	char sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	for(int i=1;i<=MaxClients;i++){
		if(!IsClientInGame(i)){ continue; }
		for (int u=0; u<g_iNumSounds; u++){
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE){
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
}

stock void Client_StopSound(int client, int entity, int channel, const char[] name)
{
	EmitSoundToClientAny(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int winner = GetEventInt(event, "winner");
	if(winner != 2 && winner != 3) //Validação para round draw
	{
		if(GetConVarInt(g_roundDrawPlay) == 1) winner = CS_TEAM_T;
		else if(GetConVarInt(g_roundDrawPlay) == 2) winner = CS_TEAM_CT;
	}
	
	if((winner == CS_TEAM_CT && SamePath) || winner == CS_TEAM_T)
	{
		if(SoundsTRSucess)
		{
			PlaySoundTR();
		}
		else
		{
			if(!SamePath) 
			{
				PrintToServer("[DNG] TR_SOUNDS ERROR: Sounds not loaded.");
				CPrintToChatAll("{green}[DNG] {default}TR_SOUNDS ERROR: Sounds not loaded.");
			}
			else
			{
				PrintToServer("[DNG] SOUNDS ERROR: Sounds not loaded.");
				CPrintToChatAll("{green}[DNG] {default}SOUNDS ERROR: Sounds not loaded.");
			}
			return;
		}
	}
	else if(winner == CS_TEAM_CT)
	{
		if(SoundsCTSucess)
		{
			PlaySoundCT();
		}
		else
		{
			PrintToServer("[DNG] CT_SOUNDS ERROR: Sounds not loaded.");
			CPrintToChatAll("{green}[DNG] {default}CT_SOUNDS ERROR: Sounds not loaded.");
			return;
		}
	}
	
	if(GetConVarInt(g_hStop) == 1)
		StopMapMusic();
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_hStop) == 1)
	{
		// Ents are recreated every round.
		g_iNumSounds = 0;
		
		// Find all ambient sounds played by the map.
		char sSound[PLATFORM_MAX_PATH];
		int entity = INVALID_ENT_REFERENCE;
		
		while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
			
			int len = strlen(sSound);
			if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
			{
				g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
			}
		}
	}
}

public void SoundCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	Commamnd_RES(client, 0);
}

public Action Command_PlayRes(int client, int args)
{
	PlaySoundTR();
}

public Action Commamnd_RES(int client, int args)
{
	if(GetConVarInt(g_ClientSettings) != 1)
	{
		return Plugin_Handled;
	}
	
	int cookievalue = GetIntCookie(client, g_hCookie);
	Handle g_AbNeRMenu = CreateMenu(AbNeRMenuHandler);
	SetMenuTitle(g_AbNeRMenu, "Round End Sounds...");
	char Item[128];
	if(cookievalue == 0)
	{
		Format(Item, sizeof(Item), "%t %t", "RES_ON", "Selected"); 
		AddMenuItem(g_AbNeRMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t", "RES_OFF"); 
		AddMenuItem(g_AbNeRMenu, "OFF", Item);
	}
	else
	{
		Format(Item, sizeof(Item), "%t", "RES_ON");
		AddMenuItem(g_AbNeRMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t %t", "RES_OFF", "Selected"); 
		AddMenuItem(g_AbNeRMenu, "OFF", Item);
	}
	SetMenuExitBackButton(g_AbNeRMenu, true);
	SetMenuExitButton(g_AbNeRMenu, true);
	DisplayMenu(g_AbNeRMenu, client, 30);
	return Plugin_Continue;
}

public int AbNeRMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	Handle g_AbNeRMenu = CreateMenu(AbNeRMenuHandler);
	if (action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				SetClientCookie(param1, g_hCookie, "0");
				Commamnd_RES(param1, 0);
			}
			case 1:
			{
				SetClientCookie(param1, g_hCookie, "1");
				Commamnd_RES(param1, 0);
			}
		}
		CloseHandle(g_AbNeRMenu);
	}
	return 0;
}

public void PathChange(Handle cvar, const char[] oldVal, const char[] newVal)
{       
	RefreshSounds(0);
}

public void OnConfigsExecuted()
{
	RefreshSounds(0);
}

void RefreshSounds(int client)
{
	char soundpath[PLATFORM_MAX_PATH];
	char soundpath2[PLATFORM_MAX_PATH];
	GetConVarString(g_hTRPath, soundpath, sizeof(soundpath));
	GetConVarString(g_hCTPath, soundpath2, sizeof(soundpath2));
	SamePath = StrEqual(soundpath, soundpath2);
	int size;
	if(SamePath)
	{
		size = LoadSoundsTR();
		SoundsTRSucess = (size > 0);
		if(SoundsTRSucess)
		{
			ReplyToCommand(client, "[DNG] SOUNDS: %d sounds loaded.", size);
		}
		else
		{
			ReplyToCommand(client, "[DNG] INVALID SOUND PATH.");
		}
	}
	else
	{
		size = LoadSoundsTR();
		SoundsTRSucess = (size > 0);
		if(SoundsTRSucess)
		{
			ReplyToCommand(client, "[DNG] TR_SOUNDS: %d sounds loaded.", size);
		}
		else
		{
			ReplyToCommand(client, "[DNG] INVALID TR SOUND PATH.");
		}
		
		size = LoadSoundsCT();
		SoundsCTSucess = (size > 0);
		if(SoundsCTSucess)
		{
			ReplyToCommand(client, "[DNG] CT_SOUNDS: %d sounds loaded.", size);
		}
		else
		{
			ReplyToCommand(client, "[DNG] INVALID CT SOUND PATH.");
		}
	}
}
 
int LoadSoundsCT()
{
	ctSound.Clear();
	char name[128];
	char soundname[512];
	char soundpath[PLATFORM_MAX_PATH];
	char soundpath2[PLATFORM_MAX_PATH];
	GetConVarString(g_hCTPath, soundpath, sizeof(soundpath));
	Format(soundpath2, sizeof(soundpath2), "sound/%s/", soundpath);
	Handle pluginsdir = OpenDirectory(soundpath2);
	if(pluginsdir != INVALID_HANDLE)
	{
		while(ReadDirEntry(pluginsdir,name,sizeof(name)))
		{
			int namelen = strlen(name) - 4;
			if(StrContains(name,".mp3",false) == namelen)
			{
				Format(soundname, sizeof(soundname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(soundname);
				Format(soundname, sizeof(soundname), "%s/%s", soundpath, name);
				PrecacheSoundAny(soundname);
				ctSound.PushString(soundname);
			}
		}
	}
	return ctSound.Length;
}

int LoadSoundsTR()
{
	trSound.Clear();
	char name[128];
	char soundname[512];
	char soundpath[PLATFORM_MAX_PATH];
	char soundpath2[PLATFORM_MAX_PATH];
	GetConVarString(g_hTRPath, soundpath, sizeof(soundpath));
	Format(soundpath2, sizeof(soundpath2), "sound/%s/", soundpath);
	Handle pluginsdir = OpenDirectory(soundpath2);
	if(pluginsdir != INVALID_HANDLE)
	{
		while(ReadDirEntry(pluginsdir,name,sizeof(name)))
		{
			int namelen = strlen(name) - 4;
			if(StrContains(name,".mp3",false) == namelen)
			{
				Format(soundname, sizeof(soundname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(soundname);
				Format(soundname, sizeof(soundname), "%s/%s", soundpath, name);
				PrecacheSoundAny(soundname);
				trSound.PushString(soundname);
			}
		}
	}
	return trSound.Length;
}

void PlaySoundCT()
{
	int soundToPlay = 0;
	if(GetConVarInt(g_hPlayType) == 1)
	{
		soundToPlay = GetRandomInt(0, ctSound.Length-1);
	}
	
	char szSound[128];
	ctSound.GetString(soundToPlay, szSound, sizeof(szSound));
	ctSound.Erase(soundToPlay);
	PlayMusicAll(szSound);
	if(ctSound.Length == 0)
		LoadSoundsCT();
}

void PlaySoundTR()
{
	int soundToPlay = 0;
	if(GetConVarInt(g_hPlayType) == 1)
	{
		soundToPlay = GetRandomInt(0, trSound.Length-1);
	}
	
	char szSound[128];
	trSound.GetString(soundToPlay, szSound, sizeof(szSound));
	trSound.Erase(soundToPlay);
	PlayMusicAll(szSound);
	if(trSound.Length == 0)
		LoadSoundsTR();
}

void PlayMusicAll(char[] szSound)
{
	// Format(szSound, PLATFORM_MAX_PATH, "*%s", szSound);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && (GetConVarInt(g_ClientSettings) == 0 || GetIntCookie(i, g_hCookie) == 0)) //Adicionado versão v3.4
		{
			ClientCommand(i, "playgamesound Music.StopAllMusic");
			// ClientCommand(i, "play \"*%s\"", szSound);
			EmitSoundToClientAny(i, szSound, _, _, _, _, 0.4);

			if(GetConVarInt(g_PlayPrint) == 1)
			{
				CPrintToChat(i, "{green}[DNG] {default}%t", "mp3 print", szSound);
			}
		}
	}
}

public Action CommandLoad(int client, int args)
{   
	RefreshSounds(client);
	return Plugin_Handled;
}

int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}
