#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <synmodes>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;

#include <multicolors>
#include <morecolors>

#define PLUGIN_VERSION "1.33"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synmodesupdater.txt"

public Plugin myinfo = 
{
	name = "SynModes",
	author = "Balimbanana",
	description = "Synergy Instant Spawn, default SaySounds, and DM/TDM/Survival gametypes",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy/"
}

float antispamchk[MAXPLAYERS+1];
Handle equiparr = INVALID_HANDLE;

bool dmact = false;
bool dmset = false;
bool hasstarted = false;
bool survivalact = false;
bool hasread = false;
bool allowendspawn = false;
bool ResetOnAllDead = false;
int WeapList = -1;
int scoreshow = -1;
int scoreshowstat = -1;
int dmkills[MAXPLAYERS+1];
int teamnum[MAXPLAYERS+1];
float scoreshowcd[MAXPLAYERS+1];
char SteamID[MAXPLAYERS+1][65];
char g_sDMSoundTrack[128];
int g_iDMSoundTrackVol = 80;
int g_iDMSoundTrack = -1;

bool instspawnb = false;
bool instspawnuse = false;
bool isvehiclemap = false;
bool clspawnforce = false;
bool clinspectate[MAXPLAYERS+1];
Handle globalsarr = INVALID_HANDLE;
Handle changelevels = INVALID_HANDLE;
Handle respawnids = INVALID_HANDLE;
Handle inputsarrorigincls = INVALID_HANDLE;
Handle afkids = INVALID_HANDLE;
bool clspawntimeallow[MAXPLAYERS+1];
int clspawntime[MAXPLAYERS+1];
int clspawntimemax = 10;
int lastspawned[MAXPLAYERS+1];
int clused = 0;
int canceltimer = 0;

bool teambalance = true;
int teambalancelimit = 0;
float endfreezetime = 6.0;
float roundtime = 150.0;
float roundstartedat = 0.0;
float roundstarttime = 5.0;
bool falldamagedis = false;
int fraglimit = 20;
int redteamkills;
int blueteamkills;
float changeteamcd[MAXPLAYERS+1];
char mapbuf[64];
char activecheckpoint[64];
char activegamemode[64];
int resetmode = 0;
bool resetvehpass = false;
bool aggro = false;

public void OnPluginStart()
{
	HookEvent("round_start",roundstart,EventHookMode_Post);
	HookEvent("round_end",roundintermission,EventHookMode_Post);
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	HookEvent("synergy_entity_death",Event_SynKilled,EventHookMode_Pre);
	RegConsoleCmd("saysound",saysoundslist);
	RegConsoleCmd("saysounds",saysoundslist);
	RegConsoleCmd("hud_player_info_enable",dmblock);
	RegConsoleCmd("changeteam",changeteam);
	RegConsoleCmd("afk",setupafk);
	RegAdminCmd("gamemode",setupdm,ADMFLAG_ROOT,".");
	RegConsoleCmd("showscoresdm",scoreboardsh);
	RegConsoleCmd("instantspawn",setinstspawn);
	RegAdminCmd("instspawnply",spawnallply,ADMFLAG_BAN,".");
	
	equiparr = CreateArray(16);
	RegConsoleCmd("spec_next",Atkspecpress);
	
	Handle instspawn = INVALID_HANDLE;
	instspawn = CreateConVar("sm_instspawn", "0", "Instspawn, default is 0", _, true, 0.0, true, 2.0);
	HookConVarChange(instspawn, instspawnch);
	if (GetConVarInt(instspawn) == 1)
	{
		instspawnuse = false;
		instspawnb = true;
	}
	else if (GetConVarInt(instspawn) == 2)
	{
		instspawnb = false;
		instspawnuse = true;
	}
	else
	{
		instspawnuse = false;
		instspawnb = false;
	}
	globalsarr = CreateArray(32);
	changelevels = CreateArray(16);
	respawnids = CreateArray(65);
	afkids = CreateArray(65);
	inputsarrorigincls = CreateArray(768);
	Handle instspawntime = INVALID_HANDLE;
	instspawntime = CreateConVar("sm_instspawntime", "10", "Instspawn time, default is 10", _, true, 0.0, false);
	clspawntimemax = GetConVarInt(instspawntime);
	HookConVarChange(instspawntime, instspawntimech);
	CloseHandle(instspawntime);
	CloseHandle(instspawn);
	Handle instspawnforce = INVALID_HANDLE;
	instspawnforce = CreateConVar("sm_instspawnforce", "0", "Force player spawn after instspawntime.", _, true, 0.0, true, 1.0);
	clspawnforce = GetConVarBool(instspawnforce);
	HookConVarChange(instspawnforce, instspawnforcech);
	CloseHandle(instspawnforce);
	Handle mpcvar = INVALID_HANDLE;
	mpcvar = CreateConVar("mp_autoteambalance", "1", "Enable auto team balance.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 0.0, true, 1.0);
	HookConVarChange(mpcvar,teambalancech);
	if (GetConVarInt(mpcvar) == 1) teambalance = true;
	else teambalance = false;
	CloseHandle(mpcvar);
	mpcvar = CreateConVar("mp_teams_unbalance_limit", "0", "Teams are unbalanced when one team has this many more players than the other team. (0 disables check)", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 0.0, true, 64.0);
	HookConVarChange(mpcvar,teambalancelimitch);
	teambalancelimit = GetConVarInt(mpcvar);
	CloseHandle(mpcvar);
	mpcvar = CreateConVar("mp_freezetime", "6", "How many seconds to keep players frozen when the round starts.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 1.0, true, 60.0);
	HookConVarChange(mpcvar,freezetimech);
	endfreezetime = GetConVarFloat(mpcvar);
	CloseHandle(mpcvar);
	mpcvar = CreateConVar("mp_roundtime", "2.5", "How many minutes each round lasts. (0 for no time limit)", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 0.0, true, 60.0);
	HookConVarChange(mpcvar,roundtimech);
	roundtime = GetConVarFloat(mpcvar)*60;
	CloseHandle(mpcvar);
	mpcvar = CreateConVar("mp_round_restart_delay", "5.0", "Number of seconds to delay before restarting a round after a win.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 1.0, true, 60.0);
	HookConVarChange(mpcvar,restartdelch);
	roundstarttime = GetConVarFloat(mpcvar);
	CloseHandle(mpcvar);
	mpcvar = CreateConVar("mp_disablefalldamage", "0", "Disable fall damage.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 0.0, true, 1.0);
	HookConVarChange(mpcvar,falldmgch);
	if (GetConVarInt(mpcvar) == 1) falldamagedis = true;
	else falldamagedis = false;
	CloseHandle(mpcvar);
	mpcvar = FindConVar("mp_fraglimit");
	if (mpcvar == INVALID_HANDLE) mpcvar = CreateConVar("mp_fraglimit", "20", "Number kills a team has to get to win the round.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 1.0, true, 60.0);
	else if (GetConVarInt(mpcvar) == 0) SetConVarInt(mpcvar,20,false,false);
	HookConVarChange(mpcvar,fraglimch);
	fraglimit = GetConVarInt(mpcvar);
	CloseHandle(mpcvar);
	mpcvar = FindConVar("mp_dmsoundtrack");
	if (mpcvar == INVALID_HANDLE) mpcvar = CreateConVar("mp_dmsoundtrack", "music/hl2_song14.mp3", "Song or sound to play every round.", FCVAR_PRINTABLEONLY);
	HookConVarChange(mpcvar,soundtrackch);
	GetConVarString(mpcvar,g_sDMSoundTrack,sizeof(g_sDMSoundTrack));
	CloseHandle(mpcvar);
	mpcvar = FindConVar("mp_dmsoundtrack_volume");
	if (mpcvar == INVALID_HANDLE) mpcvar = CreateConVar("mp_dmsoundtrack_volume", "50", "Volume of the song to play every round. Goes from 0 to 100.", FCVAR_PRINTABLEONLY, true, 0.0, true, 100.0);
	HookConVarChange(mpcvar,soundtrackvolch);
	g_iDMSoundTrackVol = GetConVarInt(mpcvar);
	CloseHandle(mpcvar);
	mpcvar = FindConVar("sm_allowendspawn");
	if (mpcvar == INVALID_HANDLE) mpcvar = CreateConVar("sm_allowendspawn", "0", "Allow instant spawn and time spawn to spawn players on other players at trigger_changelevel", _, true, 0.0, true, 1.0);
	HookConVarChange(mpcvar,allowendspawnch);
	allowendspawn = GetConVarBool(mpcvar);
	CloseHandle(mpcvar);
	mpcvar = FindConVar("mp_reset");
	if (mpcvar == INVALID_HANDLE) mpcvar = CreateConVar("mp_reset", "0", "Reload the last checkpoint on all players dead.", _, true, 0.0, true, 1.0);
	HookConVarChange(mpcvar,reloadonalldeadch);
	ResetOnAllDead = GetConVarBool(mpcvar);
	CloseHandle(mpcvar);
	Handle resetmodeh = CreateConVar("sm_resetmode", "0", "Reset mode for survival gamemode. 0 is reload checkpoint, 1 is reload map, 2 is respawn all players.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 0.0, true, 2.0);
	HookConVarChange(resetmodeh,resetmodech);
	resetmode = GetConVarInt(resetmodeh);
	CloseHandle(resetmodeh);
	Handle aggroh = CreateConVar("syn_extraaggro", "0", "Increases awareness of enemies.", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, true, 0.0, true, 2.0);
	HookConVarChange(aggroh,aggroch);
	aggro = GetConVarBool(aggroh);
	CloseHandle(aggroh);
	CreateTimer(1.0,roundtimeout,_,TIMER_REPEAT);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	AutoExecConfig(true, "synmodes");
	mpcvar = CreateConVar("sm_gamemodeset", "coop", "", FCVAR_REPLICATED|FCVAR_PRINTABLEONLY, false, 0.0, false);
	HookConVarChange(mpcvar,gmch);
	char curgamemode[16];
	GetConVarString(mpcvar,curgamemode,sizeof(curgamemode));
	if (StrEqual(curgamemode,"dm",false)) setupdmfor("dm");
	else if (StrEqual(curgamemode,"tdm",false)) setupdmfor("tdm");
	else if (StrEqual(curgamemode,"survival",false)) setupdmfor("survival");
	else setupdmfor("coop");
	CloseHandle(mpcvar);
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("SynModes");
	CreateNative("GetCLTeam", Native_GetCLTeam);
	return APLRes_Success;
}

public int Native_GetCLTeam(Handle plugin, int numParams)
{
	if (numParams > 0)
	{
		int client = GetNativeCell(1);
		if ((IsValidEntity(client)) && (client < MaxClients+1) && (client > 0))
		{
			return teamnum[client];
		}
	}
	return 0;
}

public void OnAllPluginsLoaded()
{
	Handle sfixchk = FindConVar("seqdbg");
	if (sfixchk != INVALID_HANDLE) resetvehpass = true;
	else resetvehpass = false;
	CloseHandle(sfixchk);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (aggro)
	{
		if (IsValidEntity(entity))
		{
			if (IsEntNetworkable(entity))
			{
				CreateTimer(0.1,recheck,entity,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action recheck(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		if (IsEntNetworkable(entity))
		{
			int scr = -1;
			if (HasEntProp(entity,Prop_Data,"m_hTarget")) scr = GetEntPropEnt(entity,Prop_Data,"m_hTarget");
			if ((scr == -1) && (HasEntProp(entity,Prop_Data,"m_hTargetEnt"))) scr = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
			if (scr == -1)
			{
				if (HasEntProp(entity,Prop_Data,"m_bShouldPatrol"))
				{
					SetEntProp(entity,Prop_Data,"m_bShouldPatrol",1);
					AcceptEntityInput(entity,"SetReadinessHigh");
					SetVariantString("High");
					AcceptEntityInput(entity,"LockReadiness");
					if (HasEntProp(entity,Prop_Data,"m_iNumGrenades"))
					{
						int gren = GetEntProp(entity,Prop_Data,"m_iNumGrenades");
						if (gren < 1) SetEntProp(entity,Prop_Data,"m_iNumGrenades",3);
						else SetEntProp(entity,Prop_Data,"m_iNumGrenades",gren+1);
					}
					if (HasEntProp(entity,Prop_Data,"m_bWakeSquad"))
					{
						SetEntProp(entity,Prop_Data,"m_bWakeSquad",1);
						SetEntPropFloat(entity,Prop_Data,"m_flWakeRadius",2048.0);
					}
					if (HasEntProp(entity,Prop_Data,"m_bNoExpirationTime"))
					{
						SetEntProp(entity,Prop_Data,"m_bNoExpirationTime",1);
					}
					if (HasEntProp(entity,Prop_Data,"m_bNoShootWhileMove"))
					{
						SetEntProp(entity,Prop_Data,"m_bNoShootWhileMove",0);
					}
				}
			}
		}
	}
}

public void instspawnch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		instspawnuse = false;
		instspawnb = true;
		int cvarflag = GetCommandFlags("mp_respawndelay");
		SetCommandFlags("mp_respawndelay", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_respawndelay", (cvarflag & ~FCVAR_NOTIFY));
		Handle resdelay = FindConVar("mp_respawndelay");
		SetConVarInt(resdelay,0,false,false);
		CloseHandle(resdelay);
		cvarflag = GetCommandFlags("mp_reset");
		SetCommandFlags("mp_reset", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_reset", (cvarflag & ~FCVAR_NOTIFY));
		resdelay = FindConVar("mp_reset");
		SetConVarInt(resdelay,0,false,false);
		CloseHandle(resdelay);
		Handle resforce = FindConVar("mp_forcerespawn");
		cvarflag = GetCommandFlags("mp_forcerespawn");
		SetCommandFlags("mp_forcerespawn", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_forcerespawn", (cvarflag & ~FCVAR_NOTIFY));
		SetConVarInt(resforce,0,false,false);
		resforce = FindConVar("mp_spawntime");
		cvarflag = GetCommandFlags("mp_spawntime");
		SetCommandFlags("mp_spawntime", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_spawntime", (cvarflag & ~FCVAR_NOTIFY));
		SetConVarInt(resforce,0,false,false);
		CloseHandle(resforce);
		for (int i = 1; i<MaxClients+1; i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				{
					if (!IsPlayerAlive(i))
					{
						clused = 0;
						CreateTimer(0.1,tpclspawnnew,i);
					}
				}
			}
		}
	}
	else if (StringToInt(newValue) == 2)
	{
		instspawnuse = true;
		instspawnb = false;
		int cvarflag = GetCommandFlags("mp_respawndelay");
		SetCommandFlags("mp_respawndelay", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_respawndelay", (cvarflag & ~FCVAR_NOTIFY));
		Handle resdelay = FindConVar("mp_respawndelay");
		SetConVarInt(resdelay,0,false,false);
		CloseHandle(resdelay);
		cvarflag = GetCommandFlags("mp_reset");
		SetCommandFlags("mp_reset", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_reset", (cvarflag & ~FCVAR_NOTIFY));
		resdelay = FindConVar("mp_reset");
		SetConVarInt(resdelay,0,false,false);
		CloseHandle(resdelay);
		Handle resforce = FindConVar("mp_forcerespawn");
		cvarflag = GetCommandFlags("mp_forcerespawn");
		SetCommandFlags("mp_forcerespawn", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_forcerespawn", (cvarflag & ~FCVAR_NOTIFY));
		SetConVarInt(resforce,0,false,false);
		resforce = FindConVar("mp_spawntime");
		cvarflag = GetCommandFlags("mp_spawntime");
		SetCommandFlags("mp_spawntime", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_spawntime", (cvarflag & ~FCVAR_NOTIFY));
		SetConVarInt(resforce,0,false,false);
		CloseHandle(resforce);
	}
	else
	{
		int cvarflag = GetCommandFlags("mp_respawndelay");
		SetCommandFlags("mp_respawndelay", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_respawndelay", (cvarflag & ~FCVAR_NOTIFY));
		Handle resdelay = FindConVar("mp_respawndelay");
		SetConVarInt(resdelay,1,false,false);
		CloseHandle(resdelay);
		cvarflag = GetCommandFlags("mp_reset");
		SetCommandFlags("mp_reset", (cvarflag & ~FCVAR_REPLICATED));
		SetCommandFlags("mp_reset", (cvarflag & ~FCVAR_NOTIFY));
		resdelay = FindConVar("mp_reset");
		SetConVarInt(resdelay,0,false,false);
		CloseHandle(resdelay);
		instspawnuse = false;
		instspawnb = false;
		spawnallply(0,0);
	}
}

public void instspawntimech(Handle convar, const char[] oldValue, const char[] newValue)
{
	clspawntimemax = StringToInt(newValue);
}

public void instspawnforcech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) clspawnforce = true;
	else clspawnforce = false;
}

public void teambalancech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		teambalance = true;
		balanceteams();
	}
	else teambalance = false;
}

public void teambalancelimitch(Handle convar, const char[] oldValue, const char[] newValue)
{
	teambalancelimit = StringToInt(newValue);
}

public void freezetimech(Handle convar, const char[] oldValue, const char[] newValue)
{
	endfreezetime = StringToFloat(newValue);
}

public void roundtimech(Handle convar, const char[] oldValue, const char[] newValue)
{
	roundtime = StringToFloat(newValue)*60;
}

public void restartdelch(Handle convar, const char[] oldValue, const char[] newValue)
{
	roundstarttime = StringToFloat(newValue);
}

public void falldmgch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) falldamagedis = true;
	else falldamagedis = false;
}

public void fraglimch(Handle convar, const char[] oldValue, const char[] newValue)
{
	fraglimit = StringToInt(newValue);
}

public void soundtrackch(Handle convar, const char[] oldValue, const char[] newValue)
{
	Format(g_sDMSoundTrack,sizeof(g_sDMSoundTrack),"%s",newValue);
}

public void soundtrackvolch(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iDMSoundTrackVol = StringToInt(newValue);
}

public void allowendspawnch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) allowendspawn = true;
	else allowendspawn = false;
}

public void reloadonalldeadch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) ResetOnAllDead = true;
	else ResetOnAllDead = false;
}

public void resetmodech(Handle convar, const char[] oldValue, const char[] newValue)
{
	resetmode = StringToInt(newValue);
}

public void aggroch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		aggro = true;
		for (int i = MaxClients+1;i<GetMaxEntities();i++)
		{
			if (IsValidEntity(i))
			{
				if (IsEntNetworkable(i))
				{
					if (HasEntProp(i,Prop_Data,"m_bShouldPatrol"))
					{
						SetEntProp(i,Prop_Data,"m_bShouldPatrol",1);
						AcceptEntityInput(i,"SetReadinessHigh");
						SetVariantString("High");
						AcceptEntityInput(i,"LockReadiness");
						if (HasEntProp(i,Prop_Data,"m_iNumGrenades"))
						{
							int gren = GetEntProp(i,Prop_Data,"m_iNumGrenades");
							if (gren < 1) SetEntProp(i,Prop_Data,"m_iNumGrenades",3);
							else SetEntProp(i,Prop_Data,"m_iNumGrenades",gren+1);
						}
					}
				}
			}
		}
		float orgs[3];
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i))
				{
					if (IsPlayerAlive(i))
					{
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",orgs);
						else if (HasEntProp(i,Prop_Data,"m_vecOrigin")) GetEntPropVector(i,Prop_Data,"m_vecOrigin",orgs);
						int finder = CreateEntityByName("npc_enemyfinder");
						if (finder != -1)
						{
							DispatchKeyValue(finder,"spawnflags","0");
							DispatchKeyValue(finder,"FieldOfView","-1");
							DispatchKeyValue(finder,"MaxSearchDist","4096");
							DispatchKeyValue(finder,"StartOn","1");
							TeleportEntity(finder,orgs,NULL_VECTOR,NULL_VECTOR);
							DispatchSpawn(finder);
							ActivateEntity(finder);
							SetVariantString("!activator");
							AcceptEntityInput(finder,"SetParent",i);
						}
						char apoint[64];
						GetClientAuthId(i,AuthId_Steam2,apoint,sizeof(apoint));
						Format(apoint,sizeof(apoint),"%sapoint",apoint);
						finder = CreateEntityByName("assault_assaultpoint");
						if (finder != -1)
						{
							DispatchKeyValue(finder,"targetname",apoint);
							DispatchKeyValue(finder,"assaulttimeout","10");
							DispatchKeyValue(finder,"allowdiversion","1");
							DispatchKeyValue(finder,"nevertimeout","1");
							TeleportEntity(finder,orgs,NULL_VECTOR,NULL_VECTOR);
							DispatchSpawn(finder);
							ActivateEntity(finder);
							SetVariantString("!activator");
							AcceptEntityInput(finder,"SetParent",i);
						}
						finder = CreateEntityByName("assault_rallypoint");
						if (finder != -1)
						{
							DispatchKeyValue(finder,"assaultpoint",apoint);
							TeleportEntity(finder,orgs,NULL_VECTOR,NULL_VECTOR);
							DispatchSpawn(finder);
							ActivateEntity(finder);
							SetVariantString("!activator");
							AcceptEntityInput(finder,"SetParent",i);
						}
					}
				}
			}
		}
	}
	else aggro = false;
}

public void gmch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue,oldValue,false))
	{
		if (StrEqual(newValue,"dm",false)) setupdmfor("dm");
		else if (StrEqual(newValue,"tdm",false)) setupdmfor("tdm");
		else if (StrEqual(newValue,"survival",false)) setupdmfor("survival");
		else setupdmfor("coop");
	}
}

public Action setinstspawn(int client, int args)
{
	if (client == 0)
	{
		if (args < 1) PrintToServer("instantspawn <0 1 2> 0 is off, 1 is instant, 2 is %i second timer.",clspawntimemax);
		else
		{
			char h[8];
			GetCmdArg(1,h,sizeof(h));
			int set = StringToInt(h);
			if (set > 1) set = 2;
			else if (set < 0) set = 0;
			Handle chcv = FindConVar("sm_instspawn");
			if (chcv != INVALID_HANDLE)
				SetConVarInt(chcv,set,false,false);
			CloseHandle(chcv);
			//ServerCommand("synconfoverr %i",set);
		}
		return Plugin_Handled;
	}
	if (GetUserFlagBits(client)&ADMFLAG_CUSTOM1 > 0 || GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
	{
		if (args < 1)
		{
			if (client != 0) PrintToChat(client,"instantspawn <0 1 2> 0 is off, 1 is instant, 2 is %i second timer.",clspawntimemax);
			else PrintToServer("instantspawn <0 1 2> 0 is off, 1 is instant, 2 is %i second timer.",clspawntimemax);
		}
		else
		{
			char h[8];
			GetCmdArg(1,h,sizeof(h));
			int set = StringToInt(h);
			if (set > 1) set = 2;
			else if (set < 0) set = 0;
			Handle chcv = FindConVar("sm_instspawn");
			if (chcv != INVALID_HANDLE)
				SetConVarInt(chcv,set,false,false);
			CloseHandle(chcv);
			//ServerCommand("synconfoverr %i",set);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action timeleftinround(int client, int args)
{
	if ((dmact) || (dmset))
	{
		float Time = GetTickedTime();
		if (client == 0) PrintToServer("Time left: %1.f",1.0*(roundstartedat-Time));
		else if (IsValidEntity(client))
		{
			if (roundtime < 1) PrintToChat(client,"No time limit on this round.");
			else PrintToChat(client,"Time left: %1.f",1.0*(roundstartedat-Time));
		}
	}
	return Plugin_Continue;
}

public Action Atkspecpress(int client, int args)
{
	if ((clspawntimeallow[client]) && (!IsPlayerAlive(client)))
	{
		if (clinspectate[client])
		{
			int spectarg = GetEntPropEnt(client,Prop_Data,"m_hObserverTarget");
			if (spectarg != -1)
			{
				float orgreset[3];
				if (HasEntProp(spectarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spectarg,Prop_Data,"m_vecAbsOrigin",orgreset);
				else if (HasEntProp(spectarg,Prop_Data,"m_vecOrigin")) GetEntPropVector(spectarg,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(client,Prop_Data,"m_vecOrigin",orgreset);
			}
			return Plugin_Continue;
		}
		//bool nozero = false;
		clspawntimeallow[client] = false;
		clused = GetEntPropEnt(client,Prop_Send,"m_hObserverTarget");
		if ((clused != -1) && (IsPlayerAlive(clused)) && (!cltouchend(clused)))
			CreateTimer(0.1,tpclspawnnew,client,TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			clused = 0;
			CreateTimer(0.1,tpclspawnnew,client,TIMER_FLAG_NO_MAPCHANGE);
		}
		/*
		if (lastspawned[client] == 0) lastspawned[client]++;
		if (lastspawned[client] > MaxClients) lastspawned[client] = 1;
		for (int i = lastspawned[client]; i<MaxClients+1; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
			{
				int vck = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
				if (vck == -1)
				{
					clused = i;
					lastspawned[client]++;
					CreateTimer(0.1,tpclspawnnew,client);
					nozero = true;
					break;
				}
			}
		}
		if (!nozero)
		{
			clused = 0;
			CreateTimer(0.1,tpclspawnnew,client);
		}
		*/
	}
	return Plugin_Continue;
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	int killed = GetEventInt(event, "entindex_killed");
	if ((killed <= MaxClients) && (killed > 0))
	{
		if (clinspectate[killed])
		{
			return Plugin_Continue;
		}
		if (instspawnb)
		{
			if (ResetOnAllDead)
			{
				bool reset = true;
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsClientConnected(i))
					{
						if (IsClientInGame(i))
						{
							if (IsPlayerAlive(i))
							{
								reset = false;
							}
						}
					}
				}
				if (reset)
				{
					return Plugin_Continue;
				}
			}
			if (((!dmset) && (!dmact)) && (lastspawned[killed] == 0)) lastspawned[killed]++;
			if (((!dmset) && (!dmact)) && (lastspawned[killed] > MaxClients)) lastspawned[killed] = 1;
			for (int i = lastspawned[killed]; i<MaxClients+1; i++)
			{
				if (i != 0)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && (killed != i))
					{
						int vck = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
						if ((vck == -1) && (teamnum[killed] == teamnum[i]) && (killed != i))
						{
							clused = i;
							CreateTimer(0.1,tpclspawnnew,killed,TIMER_FLAG_NO_MAPCHANGE);
							lastspawned[killed] = clused+1;
							//PrintToServer("cl %i spawned on %i, next spawn %i",killed,i,lastspawned[killed]);
							return Plugin_Continue;
						}
					}
				}
			}
			if ((!dmset) && (!dmact)) lastspawned[killed] = 0;
			clused = 0;
			//PrintToServer("CL %i will spawn on %i last %i",killed,clused,lastspawned[killed]);
			CreateTimer(0.1,tpclspawnnew,killed,TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (instspawnuse)
		{
			clspawntimeallow[killed] = false;
			if (!survivalact)
			{
				clspawntime[killed] = clspawntimemax;
				char resspawn[64];
				Format(resspawn,sizeof(resspawn),"Allowed to respawn in: %i",clspawntime[killed]);
				SetHudTextParams(0.016, 0.05, 1.0, 255, 255, 0, 255, 1, 1.0, 1.0, 1.0);
				ShowHudText(killed, 3, "%s",resspawn);
				CreateTimer(1.0,respawntime,killed);
			}
			else if (survivalact)
			{
				char resspawn[64];
				Format(resspawn,sizeof(resspawn),"You will respawn at the next checkpoint.");
				SetHudTextParams(0.016, 0.05, 5.0, 255, 255, 0, 255, 1, 1.0, 1.0, 1.0);
				ShowHudText(killed, 3, "%s",resspawn);
				PushArrayString(respawnids,SteamID[killed]);
				bool reset = true;
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsClientConnected(i))
					{
						if (IsClientInGame(i))
						{
							if (IsPlayerAlive(i))
							{
								reset = false;
							}
						}
					}
				}
				if (reset)
				{
					if (resetmode == 0)
					{
						int loadsave = CreateEntityByName("player_loadsaved");
						DispatchSpawn(loadsave);
						ActivateEntity(loadsave);
						AcceptEntityInput(loadsave,"Reload");
					}
					else if (resetmode == 1)
					{
						char curmap[64];
						GetCurrentMap(curmap,sizeof(curmap));
						ServerCommand("changelevel %s",curmap);
					}
					else if (resetmode == 2)
					{
						for (int i = 1;i<MaxClients+1;i++)
						{
							if (IsClientConnected(i))
							{
								if (IsClientInGame(i))
								{
									CreateTimer(0.1,tpclspawnnew,i,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action respawntime(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		if (clspawntime[client] > 1)
		{
			clspawntime[client] -= 1;
			char resspawn[32];
			Format(resspawn,sizeof(resspawn),"Allowed to respawn in: %i",clspawntime[client]);
			SetHudTextParams(0.016, 0.05, 1.0, 255, 255, 0, 255, 1, 1.0, 1.0, 1.0);
			ShowHudText(client, 3, "%s",resspawn);
			CreateTimer(1.0,respawntime,client);
		}
		else if ((!IsPlayerAlive(client)) && (!clspawnforce))
		{
			char resspawn[32];
			Format(resspawn,sizeof(resspawn),"Click to respawn");
			SetHudTextParams(0.016, 0.05, 1.0, 255, 255, 0, 255, 1, 1.0, 1.0, 1.0);
			ShowHudText(client, 3, "%s",resspawn);
			clspawntimeallow[client] = true;
			CreateTimer(1.0,respawntime,client);
		}
		else if ((!IsPlayerAlive(client)) && (clspawnforce))
		{
			clspawntimeallow[client] = false;
			clused = GetEntPropEnt(client,Prop_Send,"m_hObserverTarget");
			if ((clused != -1) && (IsPlayerAlive(clused)) && (!cltouchend(clused)))
				CreateTimer(0.1,tpclspawnnew,client);
			else
			{
				clused = 0;
				CreateTimer(0.1,tpclspawnnew,client);
			}
		}
	}
}

public Action dmblock(int client, int args)
{
	if (dmact)
	{
		char h[8];
		if (args > 0) GetCmdArg(1,h,sizeof(h));
		if (StrEqual(h,"0",false)) return Plugin_Continue;
		else
		{
			ClientCommand(client,"hud_player_info_enable 0");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action changeteam(int client, int args)
{
	float Time = GetTickedTime();
	if (changeteamcd[client] > Time)
	{
		PrintToChat(client,"You cannot change teams for another %1.f seconds.",changeteamcd[client]-Time);
		return Plugin_Handled;
	}
	if ((dmact) && (!dmset))
	{
		char nick[64];
		GetClientName(client, nick, sizeof(nick));
		int blueteam,redteam;
		for (int i = 1;i<MaxClients+1;i++)
		{
			if ((IsClientConnected(i)) && (IsClientInGame(i)))
			{
				if (teamnum[i] == 2) blueteam++;
				else redteam++;
			}
		}
		if (teamnum[client] == 2)
		{
			if ((redteam > blueteam+teambalancelimit) && (teambalancelimit != 0))
			{
				PrintToChat(client,"Too many people on Red team.");
				return Plugin_Handled;
			}
			//SetEntProp(client,Prop_Data,"m_iTeamNum",3);
			teamnum[client] = 3;
			PrintToChatAll("%s has joined the Red team",nick);
		}
		else
		{
			if ((blueteam > redteam+teambalancelimit) && (teambalancelimit != 0))
			{
				PrintToChat(client,"Too many people on Blue team.");
				return Plugin_Handled;
			}
			//SetEntProp(client,Prop_Data,"m_iTeamNum",2);
			teamnum[client] = 2;
			PrintToChatAll("%s has joined the Blue team",nick);
		}
		float damageForce[3];
		float fhitpos[3];
		GetClientAbsOrigin(client,fhitpos);
		if (IsPlayerAlive(client)) SDKHooks_TakeDamage(client,client,client,1000.0,DMG_DISSOLVE,-1,damageForce,fhitpos);
		changeteamcd[client] = Time + 5.0;
		return Plugin_Handled;
	}
	else if (dmset)
	{
		PrintToChat(client,"Current gamemode is free-for-all deathmatch.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action setupdm(int client, int args)
{
	char gametype[32];
	if (args == 1) GetCmdArg(1,gametype,sizeof(gametype));
	else
	{
		if (client == 0) PrintToServer("Usage: gamemode <DM TDM COOP SURVIVAL>");
		else PrintToChat(client,"Usage: gamemode <DM TDM COOP SURVIVAL>");
		return Plugin_Handled;
	}
	Handle gmcv = FindConVar("sm_gamemodeset");
	if (gmcv != INVALID_HANDLE) SetConVarString(gmcv,gametype,false,false);
	CloseHandle(gmcv);
	return Plugin_Handled;
}

void setupdmfor(char[] gametype)
{
	char gametypedisp[32];
	dmact = true;
	if (StrEqual(gametype,"dm",false))
	{
		dmset = true;
		survivalact = false;
		Format(gametypedisp,sizeof(gametypedisp),"Deathmatch");
	}
	else if (StrEqual(gametype,"tdm",false))
	{
		dmset = false;
		survivalact = false;
		Format(gametypedisp,sizeof(gametypedisp),"Team Deathmatch");
	}
	else if (StrEqual(gametype,"coop",false))
	{
		dmact = false;
		dmset = false;
		survivalact = false;
		Format(gametypedisp,sizeof(gametypedisp),"Co-op");
	}
	else if (StrEqual(gametype,"survival",false))
	{
		dmact = false;
		dmset = false;
		survivalact = true;
		Format(gametypedisp,sizeof(gametypedisp),"Survival");
	}
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsClientConnected(i)) && (IsClientInGame(i)))
		{
			dmkills[i] = 0;
			int rand = 1;
			if (!dmset) rand = GetRandomInt(2,3);
			if ((!dmact) && (!dmset))
			{
				rand = 0;
				ClientCommand(i,"hud_player_info_enable 1");
				ClientCommand(i,"bind tab +showscores");
			}
			else ClientCommand(i,"hud_player_info_enable 0");
			teamnum[i] = rand;
			//SetEntProp(i,Prop_Data,"m_iTeamNum",rand);
		}
	}
	int globalset = FindEntityByClassname(-1,"info_global_settings");
	if ((globalset == -1) && (dmact) && (hasstarted))
	{
		globalset = CreateEntityByName("info_global_settings");
		DispatchKeyValue(globalset,"IsVehicleMap","1");
		DispatchSpawn(globalset);
		ActivateEntity(globalset);
	}
	else if ((dmact) && (hasstarted))
	{
		SetVariantString("IsVehicleMap 1");
		AcceptEntityInput(globalset,"AddOutput");
	}
	if ((!dmact) && (!dmset))
	{
		Handle cvarset = FindConVar("sv_glow_enable");
		if (cvarset != INVALID_HANDLE)
		{
			int flags = GetConVarFlags(cvarset);
			SetConVarFlags(cvarset, flags & ~FCVAR_NOTIFY);
			SetConVarInt(cvarset,1,false,false);
			SetConVarFlags(cvarset, flags);
		}
		cvarset = FindConVar("mp_friendlyfire");
		if (cvarset != INVALID_HANDLE)
		{
			int flags = GetConVarFlags(cvarset);
			SetConVarFlags(cvarset, flags & ~FCVAR_NOTIFY);
			SetConVarInt(cvarset,0,false,false);
			SetConVarFlags(cvarset, flags);
		}
		cvarset = FindConVar("sm_instspawn");
		if (cvarset != INVALID_HANDLE)
		{
			if (survivalact)
			{
				SetConVarInt(cvarset,2,false,false);
			}
			else if (GetConVarInt(cvarset) < 1)
			{
				SetConVarInt(cvarset,1,false,false);
			}
		}
		CloseHandle(cvarset);
	}
	else
	{
		Handle cvarset = FindConVar("sv_glow_enable");
		if (cvarset != INVALID_HANDLE)
		{
			int flags = GetConVarFlags(cvarset);
			SetConVarFlags(cvarset, flags & ~FCVAR_NOTIFY);
			SetConVarInt(cvarset,0,false,false);
			SetConVarFlags(cvarset, flags);
		}
		cvarset = FindConVar("mp_friendlyfire");
		if (cvarset != INVALID_HANDLE)
		{
			int flags = GetConVarFlags(cvarset);
			SetConVarFlags(cvarset, flags & ~FCVAR_NOTIFY);
			SetConVarInt(cvarset,1,false,false);
			SetConVarFlags(cvarset, flags);
		}
		cvarset = FindConVar("sm_instspawn");
		if (cvarset != INVALID_HANDLE) SetConVarInt(cvarset,1,false,false);
		CloseHandle(cvarset);
		if (teambalance) balanceteams();
		Handle startround = CreateEvent("round_start");
		SetEventFloat(startround,"timelimit",roundtime);
		SetEventFloat(startround,"fraglimit",roundtime);
		FireEvent(startround,false);
	}
	if (!StrEqual(activegamemode,gametypedisp,false))
	{
		PrintToChatAll("GameMode changed to %s",gametypedisp);
		Format(activegamemode,sizeof(activegamemode),"%s",gametypedisp);
	}
}

void balanceteams()
{
	int redteam,blueteam;
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsClientConnected(i)) && (IsClientInGame(i)))
		{
			if (teamnum[i] == 2) blueteam++;
			else if (teamnum[i] == 3) redteam++;
		}
	}
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsClientConnected(i)) && (IsClientInGame(i)))
		{
			char nick[64];
			GetClientName(i, nick, sizeof(nick));
			if (blueteam < redteam)
			{
				//SetEntProp(i,Prop_Data,"m_iTeamNum",2);
				teamnum[i] = 2;
				blueteam++;
				redteam--;
				CPrintToChatAll("{BLUE}%s {DEFAULT}has joined the {BLUE}Blue team",nick);
			}
			else if (redteam < blueteam)
			{
				//SetEntProp(i,Prop_Data,"m_iTeamNum",3);
				teamnum[i] = 3;
				redteam++;
				blueteam--;
				CPrintToChatAll("{RED}%s {DEFAULT}has joined the {RED}Red team",nick);
			}
		}
	}
}

public Action setupafk(int client, int args)
{
	if ((!IsValidEntity(client)) || (client == 0)) return Plugin_Handled;
	if ((!instspawnb) && (!instspawnuse))
	{
		PrintToChat(client,"Not supported in this mode.");
		return Plugin_Handled;
	}
	if (!clinspectate[client])
	{
		clinspectate[client] = true;
		SetVariantInt(1);
		AcceptEntityInput(client,"SetTeamNum");
		SetEntProp(client,Prop_Data,"m_iTeamNum",1);
		teamnum[client] = 1;
		SetEntProp(client,Prop_Data,"deadflag",1);
		SetEntProp(client,Prop_Data,"m_iObserverMode",5);
		SetEntProp(client,Prop_Data,"m_iHideHUD",2056);
		SetEntProp(client,Prop_Data,"m_fEffects",40);
		ForcePlayerSuicide(client);
		PrintToChatAll("%N has joined the spectators",client);
		if (strlen(SteamID[client]) < 1) GetClientAuthId(client,AuthId_Steam2,SteamID[client],sizeof(SteamID[]));
		if (FindStringInArray(afkids,SteamID[client]) == -1) PushArrayString(afkids,SteamID[client]);
	}
	else
	{
		SetVariantInt(0);
		AcceptEntityInput(client,"SetTeamNum");
		SetEntProp(client,Prop_Data,"m_iTeamNum",0);
		teamnum[client] = 0;
		PrintToChatAll("%N has left spectators.",client);
		int find = FindStringInArray(afkids,SteamID[client]);
		if (find != -1) RemoveFromArray(afkids,find);
		clinspectate[client] = false;
		if (instspawnb)
		{
			if (((!dmset) && (!dmact)) && (lastspawned[client] == 0)) lastspawned[client]++;
			if (((!dmset) && (!dmact)) && (lastspawned[client] > MaxClients)) lastspawned[client] = 1;
			for (int i = lastspawned[client]; i<MaxClients+1; i++)
			{
				if (i != 0)
				{
					if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && (client != i))
					{
						int vck = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
						if ((vck == -1) && (teamnum[client] == teamnum[i]) && (client != i))
						{
							clused = i;
							CreateTimer(0.2,tpclspawnnew,client);
							lastspawned[client] = clused+1;
							return Plugin_Continue;
						}
					}
				}
			}
			if ((!dmset) && (!dmact)) lastspawned[client] = 0;
			clused = 0;
			CreateTimer(0.2,tpclspawnnew,client);
		}
		else if (instspawnuse)
		{
			clspawntimeallow[client] = false;
			if (!survivalact)
			{
				clspawntime[client] = clspawntimemax;
				char resspawn[64];
				Format(resspawn,sizeof(resspawn),"Allowed to respawn in: %i",clspawntime[client]);
				SetHudTextParams(0.016, 0.05, 1.0, 255, 255, 0, 255, 1, 1.0, 1.0, 1.0);
				ShowHudText(client, 3, "%s",resspawn);
				CreateTimer(1.0,respawntime,client);
			}
			else if (survivalact)
			{
				char resspawn[64];
				Format(resspawn,sizeof(resspawn),"You will respawn at the next checkpoint.");
				SetHudTextParams(0.016, 0.05, 5.0, 255, 255, 0, 255, 1, 1.0, 1.0, 1.0);
				ShowHudText(client, 3, "%s",resspawn);
				if (FindStringInArray(respawnids,SteamID[client]) == -1) PushArrayString(respawnids,SteamID[client]);
			}
		}
	}
	return Plugin_Handled;
}

public Action scoreboardsh(int client, int args)
{
	if ((dmact) && (!dmset))
	{
		if ((scoreshow == -1) || (!IsValidEntity(scoreshow)) || (scoreshow == 0))
		{
			scoreshow = CreateEntityByName("game_text");
			DispatchKeyValue(scoreshow,"x","0.2");
			DispatchKeyValue(scoreshow,"y","0.2");
			DispatchKeyValue(scoreshow,"channel","1");
			DispatchKeyValue(scoreshow,"color","255 255 255");
			DispatchKeyValue(scoreshow,"fadein","0.1");
			DispatchKeyValue(scoreshow,"fadeout","0.1");
			DispatchKeyValue(scoreshow,"holdtime","2.0");
		}
		if ((scoreshowstat == -1) || (!IsValidEntity(scoreshowstat)) || (scoreshowstat == 0))
		{
			scoreshowstat = CreateEntityByName("game_text");
			DispatchKeyValue(scoreshowstat,"x","0.6");
			DispatchKeyValue(scoreshowstat,"y","0.2");
			DispatchKeyValue(scoreshowstat,"channel","2");
			DispatchKeyValue(scoreshowstat,"color","255 255 255");
			DispatchKeyValue(scoreshowstat,"fadein","0.1");
			DispatchKeyValue(scoreshowstat,"fadeout","0.1");
			DispatchKeyValue(scoreshowstat,"holdtime","2.0");
		}
		char tmpall[255];
		char tmpallstat[255];
		Format(tmpall,sizeof(tmpall),"Name\n");
		StrCat(tmpall,sizeof(tmpall),"Blue Team:\n");
		Format(tmpallstat,sizeof(tmpallstat),"Score|Kills|Deaths\n");
		Handle tmparrblue = CreateArray(MaxClients+1);
		Handle tmparrred = CreateArray(MaxClients+1);
		int score,deaths,blueteamscore,blueteamdeaths,redteamscore,redteamdeaths;
		for (int i = 1;i<MaxClients+1;i++)
		{
			if ((IsClientConnected(i)) && (IsClientInGame(i)))
			{
				deaths = GetEntProp(i, Prop_Data, "m_iDeaths");
				if (HasEntProp(i,Prop_Data,"m_iPoints"))
					score = GetEntProp(i, Prop_Data, "m_iPoints");
				if (teamnum[i] == 2)
				{
					PushArrayCell(tmparrblue,i);
					blueteamscore+=score;
					blueteamdeaths+=deaths;
				}
				else if (teamnum[i] == 3)
				{
					PushArrayCell(tmparrred,i);
					redteamscore+=score;
					redteamdeaths+=deaths;
				}
			}
		}
		char tmpstat[64];
		char blanksp[8];
		char blanksp2[8];
		char blanksp3[8];
		if ((blueteamscore > 10) && (blueteamscore < 100)) Format(blanksp,sizeof(blanksp),"");
		else Format(blanksp,sizeof(blanksp)," ");
		if ((blueteamscore > 10) && (blueteamscore < 100) && (blueteamkills < 10)) Format(blanksp2,sizeof(blanksp2)," ");
		if ((blueteamscore < 10) && (blueteamkills < 10) && (blueteamdeaths > 9))
		{
			Format(blanksp2,sizeof(blanksp2)," ");
			Format(blanksp3,sizeof(blanksp3)," ");
		}
		Format(tmpstat,sizeof(tmpstat)," %s%i       %s%i       %s%i\n",blanksp,blueteamscore,blanksp2,blueteamkills,blanksp3,blueteamdeaths);
		StrCat(tmpallstat,sizeof(tmpallstat),tmpstat);
		if (GetArraySize(tmparrblue) > 0)
		{
			for (int i = 0;i<GetArraySize(tmparrblue);i++)
			{
				int j = GetArrayCell(tmparrblue,i);
				Format(blanksp,sizeof(blanksp),"");
				Format(blanksp2,sizeof(blanksp2),"");
				Format(blanksp3,sizeof(blanksp3),"");
				if ((IsClientConnected(j)) && (IsClientInGame(j)))
				{
					char nick[64];
					GetClientName(j,nick,sizeof(nick));
					deaths = GetEntProp(j, Prop_Data, "m_iDeaths");
					if (HasEntProp(j,Prop_Data,"m_iPoints"))
						score = GetEntProp(j, Prop_Data, "m_iPoints");
					char tmp[64];
					Format(tmp,sizeof(tmp),"%s\n",nick);
					if ((score > 10) && (score < 100)) Format(blanksp,sizeof(blanksp),"");
					else Format(blanksp,sizeof(blanksp)," ");
					if ((score > 10) && (score < 100) && (dmkills[j] < 10)) Format(blanksp2,sizeof(blanksp2)," ");
					if ((score < 10) && (dmkills[j] < 10) && (deaths > 9))
					{
						Format(blanksp2,sizeof(blanksp2)," ");
						Format(blanksp3,sizeof(blanksp3)," ");
					}
					Format(tmpstat,sizeof(tmpstat)," %s%i       %s%i       %s%i\n",blanksp,score,blanksp2,dmkills[j],blanksp3,deaths);
					StrCat(tmpall,sizeof(tmpall),tmp);
					StrCat(tmpallstat,sizeof(tmpallstat),tmpstat);
				}
			}
		}
		StrCat(tmpall,sizeof(tmpall),"Red Team:\n");
		if ((redteamscore > 10) && (redteamscore < 100)) Format(blanksp,sizeof(blanksp),"");
		else Format(blanksp,sizeof(blanksp)," ");
		if ((redteamscore > 10) && (redteamscore < 100) && (redteamkills < 10)) Format(blanksp2,sizeof(blanksp2)," ");
		if ((redteamscore < 10) && (redteamkills < 10) && (redteamdeaths > 9))
		{
			Format(blanksp2,sizeof(blanksp2)," ");
			Format(blanksp3,sizeof(blanksp3)," ");
		}
		Format(tmpstat,sizeof(tmpstat)," %s%i       %s%i       %s%i\n",blanksp,redteamscore,blanksp2,redteamkills,blanksp3,redteamdeaths);
		StrCat(tmpallstat,sizeof(tmpallstat),tmpstat);
		if (GetArraySize(tmparrred) > 0)
		{
			for (int i = 0;i<GetArraySize(tmparrred);i++)
			{
				int j = GetArrayCell(tmparrred,i);
				if ((IsClientConnected(j)) && (IsClientInGame(j)))
				{
					char nick[64];
					GetClientName(j,nick,sizeof(nick));
					deaths = GetEntProp(j, Prop_Data, "m_iDeaths");
					if (HasEntProp(j,Prop_Data,"m_iPoints"))
						score = GetEntProp(j, Prop_Data, "m_iPoints");
					char tmp[64];
					Format(tmp,sizeof(tmp),"%s\n",nick);
					if ((score > 10) && (score < 100)) Format(blanksp,sizeof(blanksp),"");
					else Format(blanksp,sizeof(blanksp)," ");
					if ((score > 10) && (score < 100) && (dmkills[j] < 10)) Format(blanksp2,sizeof(blanksp2)," ");
					if ((score < 10) && (dmkills[j] < 10) && (deaths > 9))
					{
						Format(blanksp2,sizeof(blanksp2)," ");
						Format(blanksp3,sizeof(blanksp3)," ");
					}
					Format(tmpstat,sizeof(tmpstat)," %s%i       %s%i       %s%i\n",blanksp,score,blanksp2,dmkills[j],blanksp3,deaths);
					StrCat(tmpall,sizeof(tmpall),tmp);
					StrCat(tmpallstat,sizeof(tmpallstat),tmpstat);
				}
			}
		}
		CloseHandle(tmparrblue);
		CloseHandle(tmparrred);
		DispatchKeyValue(scoreshow,"message",tmpall);
		AcceptEntityInput(scoreshow,"Display",client);
		DispatchKeyValue(scoreshowstat,"message",tmpallstat);
		AcceptEntityInput(scoreshowstat,"Display",client);
	}
	return Plugin_Handled;
}

int buttonscoreboard = (1 << 16);
int g_LastButtons[MAXPLAYERS+1];

public void OnButtonPressscoreboard(int client, int button)
{
	if ((dmact) && (!dmset))
	{
		float Time = GetTickedTime();
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)) && (scoreshowcd[client] < Time))
		{
			scoreboardsh(client,0);
			ClientCommand(client,"-showscores");
			scoreshowcd[client] = Time + 2.0;
		}
	}
}

public Action Event_SynKilled(Handle event, const char[] name, bool Broadcast)
{
	if (dmact)
	{
		int killid = GetEventInt(event, "killerID");
		int vicid = GetEventInt(event, "victimID");
		int suicidechk = GetEventBool(event, "suicide");
		if ((killid < MaxClients+1) && (killid > 0) && (vicid < MaxClients+1) && (vicid > 0))
		{
			int a = teamnum[killid];//GetEntProp(killid,Prop_Data,"m_iTeamNum");
			int b = teamnum[vicid];//GetEntProp(vicid,Prop_Data,"m_iTeamNum");
			//-6921216 is blue -16083416 is green -16777041 is red -1052689 is white -3644216 is purple
			if (a == 2)
			{
				SetEventInt(event,"killercolor",-6921216);
				if (!suicidechk) blueteamkills++;
			}
			if (a == 3)
			{
				SetEventInt(event,"killercolor",-16777041);
				if (!suicidechk) redteamkills++;
			}
			if (b == 2) SetEventInt(event,"victimcolor",-6921216);
			if (b == 3) SetEventInt(event,"victimcolor",-16777041);
			if (dmset)
			{
				SetEventInt(event,"killercolor",-1052689);
				SetEventInt(event,"victimcolor",-1052689);
			}
			int score;
			if (!suicidechk) dmkills[killid]++;
			if (HasEntProp(killid,Prop_Data,"m_iFrags"))
			{
				SetEntProp(killid,Prop_Data,"m_iFrags",dmkills[killid]);
			}
			if ((HasEntProp(killid,Prop_Data,"m_iPoints")) && (!suicidechk))
			{
				score = GetEntProp(killid, Prop_Data, "m_iPoints");
				SetEntProp(killid, Prop_Data, "m_iPoints", score+35);
			}
			if ((dmset) && (dmkills[killid] >= fraglimit))
			{
				Handle endround = CreateEvent("round_end");
				SetEventInt(endround,"winner",killid);
				SetEventInt(endround,"reason",1);
				SetEventString(endround,"message","FragLimit Reached");
				FireEvent(endround,false);
				char nick[64];
				GetClientName(killid,nick,sizeof(nick));
				PrintCenterTextAll("%s Wins!",nick);
				PrintToChatAll("%s Wins!",nick);
				canceltimer++;
			}
			else if (blueteamkills >= fraglimit)
			{
				Handle endround = CreateEvent("round_end");
				SetEventInt(endround,"winner",2);
				SetEventInt(endround,"reason",1);
				SetEventString(endround,"message","FragLimit Reached");
				FireEvent(endround,false);
				PrintCenterTextAll("Blue Team Wins!");
				PrintToChatAll("Blue Team Wins!");
				canceltimer++;
			}
			else if (redteamkills >= fraglimit)
			{
				Handle endround = CreateEvent("round_end");
				SetEventInt(endround,"winner",3);
				SetEventInt(endround,"reason",1);
				SetEventString(endround,"message","FragLimit Reached");
				FireEvent(endround,false);
				PrintCenterTextAll("Red Team Wins!");
				PrintToChatAll("Red Team Wins!");
				canceltimer++;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action tpclspawnnew(Handle timer, int i)
{
	ClearArray(respawnids);
	if ((!IsValidEntity(i)) || (clinspectate[i])) return Plugin_Handled;
	if (!IsClientInGame(i)) return Plugin_Handled;
	bool relocglo = false;
	if (GetArraySize(globalsarr) < 1)
	{
		ClearArray(globalsarr);
		findglobals(-1,"info_global_settings");
		for (int j = 0;j<GetArraySize(globalsarr);j++)
		{
			int glo = GetArrayCell(globalsarr,j);
			if (IsValidEntity(glo))
			{
				char clsname[32];
				GetEntityClassname(glo,clsname,sizeof(clsname));
				if (StrContains(clsname,"global",false) != -1)
				{
					int state2 = GetEntProp(glo,Prop_Data,"m_bIsVehicleMap");
					if (state2 == 1)
						isvehiclemap = true;
					else if (state2 == 0)
						isvehiclemap = false;
				}
				else
					relocglo = true;
			}
		}
	}
	else
	{
		for (int j = 0;j<GetArraySize(globalsarr);j++)
		{
			char itmp[32];
			GetArrayString(globalsarr, j, itmp, sizeof(itmp));
			int glo = StringToInt(itmp);
			if (IsValidEntity(glo))
			{
				char clsname[32];
				GetEntityClassname(glo,clsname,sizeof(clsname));
				if (StrContains(clsname,"global",false) != -1)
				{
					int state2 = GetEntProp(glo,Prop_Data,"m_bIsVehicleMap");
					if (state2 == 1)
						isvehiclemap = true;
					else if (state2 == 0)
						isvehiclemap = false;
				}
				else
					relocglo = true;
			}
		}
	}
	if (relocglo)
	{
		ClearArray(globalsarr);
		findglobals(-1,"info_global_settings");
	}
	if (!IsValidEntity(clused)) clused = 0;
	if (instspawnuse)
	{
		int vck = -1;
		if (HasEntProp(clused,Prop_Data,"m_hVehicle")) vck = GetEntPropEnt(clused,Prop_Data,"m_hVehicle");
		if (vck != -1)
			clused = 0;
	}
	if ((isvehiclemap) || (clused == i))
		clused = 0;
	if ((clused > 0) && (IsValidEntity(clused)) && (!allowendspawn))
	{
		if (IsClientConnected(clused))
		{
			if (IsClientInGame(clused))
			{
				if (IsPlayerAlive(clused))
				{
					if (GetEntityRenderFx(clused) == RENDERFX_DISTORT)
					{
						clused = 0;
					}
				}
			}
		}
	}
	if ((clused > 0) && (IsValidEntity(clused)))
	{
		DispatchSpawn(i);
		int vck = GetEntPropEnt(clused,Prop_Data,"m_hVehicle");
		int crouching = GetEntProp(clused,Prop_Send,"m_bDucked");
		float pos[3];
		GetClientAbsOrigin(clused, pos);
		float plyang[3];
		GetClientEyeAngles(clused, plyang);
		plyang[2] = 0.0;
		if (vck != -1)
		{
			pos[2] += 50.0;
		}
		else if (crouching)
		{
			pos[2] += 0.1;
			SetEntProp(i,Prop_Send,"m_bDucking",1);
		}
		else
			pos[2] += 10.0;
		TeleportEntity(i, pos, plyang, NULL_VECTOR);
		findent(MaxClients+1,"info_player_equip");
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
			if (IsValidEntity(jtmp))
			{
				AcceptEntityInput(jtmp,"EquipPlayer",i);
				if (HasEntProp(jtmp,Prop_Data,"m_iszResponseContext"))
				{
					EquipCustom(jtmp,i);
				}
			}
		}
		ClearArray(equiparr);
	}
	else if ((clused == 0) && (IsClientInGame(i)))
	{
		findent(MaxClients+1,"info_player_equip");
		if (isvehiclemap)
		{
			for (int j; j<GetArraySize(equiparr); j++)
			{
				int jtmp = GetArrayCell(equiparr, j);
				if (IsValidEntity(jtmp))
					AcceptEntityInput(jtmp,"Disable");
			}
		}
		DispatchSpawn(i);
		if (GetArraySize(equiparr) > 0)
		{
			for (int j; j<GetArraySize(equiparr); j++)
			{
				int jtmp = GetArrayCell(equiparr, j);
				char clsnam[32];
				GetEntityClassname(jtmp,clsnam,sizeof(clsnam));
				if (IsValidEntity(jtmp))
				{
					AcceptEntityInput(jtmp,"EquipPlayer",i);
					if (HasEntProp(jtmp,Prop_Data,"m_iszResponseContext"))
					{
						EquipCustom(jtmp,i);
					}
				}
			}
		}
		else
		{
			findentwdis(MaxClients+1,"info_player_equip");
			if (GetArraySize(equiparr) > 0)
			{
				for (int j; j<GetArraySize(equiparr); j++)
				{
					int jtmp = GetArrayCell(equiparr, j);
					char clsnam[32];
					GetEntityClassname(jtmp,clsnam,sizeof(clsnam));
					if (IsValidEntity(jtmp))
					{
						AcceptEntityInput(jtmp,"EquipPlayer",i);
						if (HasEntProp(jtmp,Prop_Data,"m_iszResponseContext"))
						{
							EquipCustom(jtmp,i);
						}
					}
				}
			}
		}
		if (isvehiclemap)
		{
			for (int j; j<GetArraySize(equiparr); j++)
			{
				int jtmp = GetArrayCell(equiparr, j);
				if (IsValidEntity(jtmp))
					AcceptEntityInput(jtmp,"Enable");
			}
		}
		ClearArray(equiparr);
	}
	float pos[3];
	GetClientAbsOrigin(i, pos);
	//(!dmset) && (dmact)
	if ((isvehiclemap) || (((pos[0] <= 10.0) && (pos[0] >= -10.0)) && ((pos[1] <= 10.0) && (pos[1] >= -10.0)) && ((pos[2] <= 10.0) && (pos[2] >= -10.0))))
	{
		//Player most likely spawned at 0 0 0, or on a player when they shouldn't have, need to attempt recovery...
		ClearArray(equiparr);
		if (teamnum[i] == 2) findent(MaxClients+1,"info_player_rebel");
		else if (teamnum[i] == 3) findent(MaxClients+1,"info_player_combine");
		else if (teamnum[i] == 1) findent(MaxClients+1,"info_player_deathmatch");
		if ((GetArraySize(equiparr) < 1) && (teamnum[i] != 0)) findent(MaxClients+1,"info_player_deathmatch");
		if (GetArraySize(equiparr) < 1) findent(MaxClients+1,"info_player_coop");
		if (GetArraySize(equiparr) < 1)
		{
			findent(MaxClients+1,"info_player_start");
			if (GetArraySize(equiparr) > 0)
			{
				int firstarr = GetArrayCell(equiparr,0);
				float vec[3];
				float spawnang[3];
				if (HasEntProp(firstarr,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(firstarr,Prop_Data,"m_vecAbsOrigin",vec);
				else if (HasEntProp(firstarr,Prop_Send,"m_vecOrigin")) GetEntPropVector(firstarr,Prop_Send,"m_vecOrigin",vec);
				GetEntPropVector(firstarr,Prop_Send,"m_angRotation",spawnang);
				TeleportEntity(i, vec, spawnang, NULL_VECTOR);
				lastspawned[i] = firstarr;
			}
		}
		else
		{
			int spawnent = GetArrayCell(equiparr,0);
			if ((lastspawned[i] != spawnent) && (!dmact))
			{
				lastspawned[i] = spawnent;
			}
			else
			{
				for (int j = GetRandomInt(0,GetArraySize(equiparr));j<GetArraySize(equiparr);j++)
				{
					int tmpsp = GetArrayCell(equiparr,j);
					bool rangechk = true;
					float spawnpos[3];
					if (HasEntProp(tmpsp,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(tmpsp,Prop_Data,"m_vecAbsOrigin",spawnpos);
					else if (HasEntProp(tmpsp,Prop_Send,"m_vecOrigin")) GetEntPropVector(tmpsp,Prop_Send,"m_vecOrigin",spawnpos);
					if ((dmact) && (!dmset))
					{
						for (int k = 1;k<MaxClients+1;k++)
						{
							if ((IsValidEntity(k)) && (i != k))
							{
								if ((IsClientInGame(k)) && (IsPlayerAlive(k)))
								{
									float plypos[3];
									GetClientAbsOrigin(k,plypos);
									float chkdist = GetVectorDistance(spawnpos,plypos,false);
									if ((chkdist < 200) && (teamnum[i] != teamnum[k])) rangechk = false;
								}
							}
						}
					}
					if ((lastspawned[i] != tmpsp) && (rangechk))
					{
						spawnent = tmpsp;
						lastspawned[i] = tmpsp;
						break;
					}
				}
			}
			//PrintToServer("CheckPoint %s spawnent %i lastspawned %i",activecheckpoint,spawnent,lastspawned[i]);
			float vec[3];
			float spawnang[3];
			if (HasEntProp(spawnent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spawnent,Prop_Data,"m_vecAbsOrigin",vec);
			else if (HasEntProp(spawnent,Prop_Send,"m_vecOrigin")) GetEntPropVector(spawnent,Prop_Send,"m_vecOrigin",vec);
			GetEntPropVector(spawnent,Prop_Send,"m_angRotation",spawnang);//m_angAbsRotation m_vecAngles
			TeleportEntity(i, vec, spawnang, NULL_VECTOR);
		}
		ClearArray(equiparr);
	}
	return Plugin_Handled;
}

public void EquipCustom(int equip, int client)
{
	if ((IsValidEntity(equip)) && (IsValidEntity(client)))
	{
		float pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2]+=20.0;
		float plyang[3];
		GetClientEyeAngles(client, plyang);
		char additionalweaps[256];
		GetEntPropString(equip,Prop_Data,"m_iszResponseContext",additionalweaps,sizeof(additionalweaps));
		if (strlen(additionalweaps) > 0)
		{
			char additionalweap[64][64];
			char basecls[64];
			ExplodeString(additionalweaps," ",additionalweap,64,64,true);
			for (int k = 0;k<64;k++)
			{
				if (strlen(additionalweap[k]) > 0)
				{
					TrimString(additionalweap[k]);
					bool addweap = true;
					if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
					if (WeapList != -1)
					{
						char clschk[32];
						for (int j; j<104; j += 4)
						{
							int tmpi = GetEntDataEnt2(client,WeapList + j);
							if ((tmpi != 0) && (IsValidEntity(tmpi)))
							{
								GetEntityClassname(tmpi,clschk,sizeof(clschk));
								if (StrEqual(clschk,additionalweap[k],false)) addweap = false;
							}
						}
					}
					if (addweap)
					{
						Format(basecls,sizeof(basecls),"%s",additionalweap[k]);
						if (StrEqual(basecls,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
						else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
						else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
						else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
						else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
						else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
						else if (StrEqual(basecls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
						else if (StrEqual(basecls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
						int ent = CreateEntityByName(basecls);
						if (ent != -1)
						{
							TeleportEntity(ent,pos,plyang,NULL_VECTOR);
							DispatchKeyValue(ent,"classname",additionalweap[k]);
							DispatchSpawn(ent);
							ActivateEntity(ent);
						}
					}
				}
			}
		}
	}
}

void findent(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		int bdisabled = 0;
		if (HasEntProp(thisent,Prop_Data,"m_bDisabled")) bdisabled = GetEntProp(thisent,Prop_Data,"m_bDisabled");
		if (StrEqual(clsname,"info_player_coop",false))
		{
			if (strlen(activecheckpoint) > 0)
			{
				char targn[64];
				GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
				if (StrEqual(targn,activecheckpoint,false)) bdisabled = 0;
				else bdisabled = 1;
			}
		}
		if (bdisabled == 0)
			PushArrayCell(equiparr,thisent);
		findent(thisent++,clsname);
	}
}

void findentwdis(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		PushArrayCell(equiparr,thisent);
		findent(thisent++,clsname);
	}
}

public Action findglobals(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if((thisent >= 0) && (FindValueInArray(globalsarr,thisent) == -1))
		{
			PushArrayCell(globalsarr,thisent);
		}
		findglobals(thisent++,clsname);
	}
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if ((!IsValidEntity(client)) || (client == 0)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (StrEqual(sArgs,"!timeleft",false))
	{
		timeleftinround(client,0);
	}
	if (StrContains(sArgs, "*moan*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			int randsound = GetRandomInt(1,5);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			char plymdl[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"female") != -1)
				Format(randcat,sizeof(randcat),"vo\\npc\\female01\\moan0%s.wav",randcat);
			else if (StrContains(plymdl,"combine") != -1)
			{
				if (randsound > 3)
					Format(randcat,sizeof(randcat),"3");
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\die%s.wav",randcat);
			}
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
			{
				if (randsound > 4)
					Format(randcat,sizeof(randcat),"4");
				Format(randcat,sizeof(randcat),"npc\\metropolice\\die%s.wav",randcat);
				antispamchk[client] += 1.0;
			}
			else
				Format(randcat,sizeof(randcat),"ambient\\voices\\citizen_beaten%s.wav",randcat);
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*pain*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			int randsound = GetRandomInt(1,9);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			char plymdl[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"female") != -1)
				Format(randcat,sizeof(randcat),"vo\\npc\\female01\\pain0%s.wav",randcat);
			else if (StrContains(plymdl,"combine") != -1)
			{
				if (randsound > 3)
					Format(randcat,sizeof(randcat),"3");
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\pain%s.wav",randcat);
			}
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
			{
				if (randsound > 4)
					Format(randcat,sizeof(randcat),"4");
				Format(randcat,sizeof(randcat),"npc\\metropolice\\pain%s.wav",randcat);
			}
			else
				Format(randcat,sizeof(randcat),"vo\\npc\\male01\\pain0%s.wav",randcat);
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*dead*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 5.0;
			int randsound = GetRandomInt(1,20);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			char plymdl[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			bool noplay = false;
			if (StrContains(plymdl,"female") != -1)
			{
				if (randsound < 10)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\gordead_ans0%s.wav",randcat);
				else
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\gordead_ans%s.wav",randcat);
			}
			else if (StrContains(plymdl,"combine") != -1)
				noplay = true;
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
				Format(randcat,sizeof(randcat),"npc\\metropolice\\die%s.wav",randcat);
			else
			{
				if (randsound < 10)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\gordead_ans0%s.wav",randcat);
				else
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\gordead_ans%s.wav",randcat);
			}
			if (!noplay)
			{
				PrecacheSound(randcat,true);
				EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*strider*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			char strisound[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"combine") != -1)
				Format(strisound,sizeof(strisound),"npc\\combine_soldier\\vo\\heavyresistance.wav");
			else if (StrContains(plymdl,"female") != -1)
				Format(strisound,sizeof(strisound),"vo\\npc\\female01\\strider.wav");
			else
				Format(strisound,sizeof(strisound),"vo\\npc\\male01\\strider.wav");
			PrecacheSound(strisound,true);
			EmitSoundToAll(strisound, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*enemy*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			int targ = GetClientAimTarget(client,false);
			char clsname[64];
			if (targ != -1) GetEntityClassname(targ,clsname,sizeof(clsname));
			char plymdl[64];
			char randcat[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"combine") != -1)
			{
				int randsound = GetRandomInt(1,26);
				switch(randsound)
				{
					case 1:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\heavyresistance.wav");
					case 2:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\bouncerbouncer.wav");
					case 3:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\block31mace.wav");
					case 4:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\alert1.wav");
					case 5:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\bouncerbouncer.wav");
					case 6:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\callhotpoint.wav");
					case 7:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\closing.wav");
					case 8:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\closing2.wav");
					case 9:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\contact.wav");
					case 10:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\contactconfim.wav");
					case 11:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\contactconfirmprosecuting.wav");
					case 12:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\displace.wav");
					case 13:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\displace2.wav");
					case 14:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\executingfullresponse.wav");
					case 15:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\gosharp.wav");
					case 16:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\inbound.wav");
					case 17:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\infected.wav");
					case 18:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\necroticsinbound.wav");
					case 19:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\outbreak.wav");
					case 20:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\overwatchreportspossiblehostiles.wav");
					case 21:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\overwatchrequestreinforcement.wav");
					case 22:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\overwatchrequestreserveactivation.wav");
					case 23:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\prepforcontact.wav");
					case 24:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\prosecuting.wav");
					case 25:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\readyweaponshostilesinbound.wav");
					case 26:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\ripcordripcord.wav");
				}
			}
			else if (StrContains(plymdl,"female") != -1)
			{
				if (StrEqual(clsname,"npc_combinedropship",false))
				{
					int randsound = GetRandomInt(1,2);
					switch(randsound)
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\coast\\barn\\female01\\incomingdropship.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\coast\\barn\\female01\\crapships.wav");
					}
				}
				else if (StrEqual(clsname,"npc_combinegunship",false))
				{
					int randsound = GetRandomInt(1,3);
					if (randsound == 3) Format(randcat,sizeof(randcat),"vo\\npc\\female01\\gunship02.wav");
					else Format(randcat,sizeof(randcat),"vo\\coast\\barn\\female01\\lite_gunship0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_metropolice",false))
				{
					int randsound = GetRandomInt(1,4);
					switch(randsound)
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\civilprotection01.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\civilprotection02.wav");
						case 3:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\cps01.wav");
						case 4:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\cps02.wav");
					}
				}
				else if (StrEqual(clsname,"npc_combine_s",false))
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\combine0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_manhack",false))
				{
					int randsound = GetRandomInt(1,8);
					if (randsound < 3) Format(randcat,sizeof(randcat),"vo\\npc\\female01\\hacks0%i.wav",randsound);
					else if (randsound < 5)
					{
						randsound-=2;
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\herecomehacks0%i.wav",randsound);
					}
					else if (randsound < 7)
					{
						randsound-=4;
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\itsamanhack0%i.wav",randsound);
					}
					else
					{
						randsound-=6;
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\thehacks0%i.wav",randsound);
					}
				}
				else if (StrContains(clsname,"headcrab",false) != -1)
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\headcrabs0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_cscanner",false))
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\scanners0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_strider",false)) Format(randcat,sizeof(randcat),"vo\\npc\\female01\\strider.wav");
				else if (StrContains(clsname,"zombie",false) != -1)
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\zombies0%i.wav",randsound);
				}
				else
				{
					int randsound = GetRandomInt(1,13);
					switch(randsound)
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\behindyou01.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\behindyou02.wav");
						case 3:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\getdown02.wav");
						case 4:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\gethellout.wav");
						case 5:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\headsup01.wav");
						case 6:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\headsup02.wav");
						case 7:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\incoming02.wav");
						case 8:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\runforyourlife01.wav");
						case 9:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\runforyourlife02.wav");
						case 10:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\strider_run.wav");
						case 11:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\takecover02.wav");
						case 12:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\uhoh.wav");
						case 13:
							Format(randcat,sizeof(randcat),"vo\\npc\\female01\\watchout.wav");
					}
				}
			}
			else
			{
				if (StrEqual(clsname,"npc_combinedropship",false))
				{
					int randsound = GetRandomInt(1,2);
					switch(randsound)
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\coast\\barn\\male01\\incomingdropship.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\coast\\barn\\male01\\crapships.wav");
					}
				}
				else if (StrEqual(clsname,"npc_combinegunship",false))
				{
					int randsound = GetRandomInt(1,3);
					if (randsound == 3) Format(randcat,sizeof(randcat),"vo\\npc\\male01\\gunship02.wav");
					else Format(randcat,sizeof(randcat),"vo\\coast\\barn\\male01\\lite_gunship0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_metropolice",false))
				{
					int randsound = GetRandomInt(1,4);
					switch(randsound)
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\civilprotection01.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\civilprotection02.wav");
						case 3:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\cps01.wav");
						case 4:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\cps02.wav");
					}
				}
				else if (StrEqual(clsname,"npc_combine_s",false))
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\combine0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_manhack",false))
				{
					int randsound = GetRandomInt(1,8);
					if (randsound < 3) Format(randcat,sizeof(randcat),"vo\\npc\\male01\\hacks0%i.wav",randsound);
					else if (randsound < 5)
					{
						randsound-=2;
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\herecomehacks0%i.wav",randsound);
					}
					else if (randsound < 7)
					{
						randsound-=4;
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\itsamanhack0%i.wav",randsound);
					}
					else
					{
						randsound-=6;
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\thehacks0%i.wav",randsound);
					}
				}
				else if (StrContains(clsname,"headcrab",false) != -1)
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\headcrabs0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_cscanner",false))
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\scanners0%i.wav",randsound);
				}
				else if (StrEqual(clsname,"npc_strider",false)) Format(randcat,sizeof(randcat),"vo\\npc\\male01\\strider.wav");
				else if (StrContains(clsname,"zombie",false) != -1)
				{
					int randsound = GetRandomInt(1,2);
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\zombies0%i.wav",randsound);
				}
				else
				{
					int randsound = GetRandomInt(1,10);
					switch(randsound)
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\behindyou01.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\behindyou02.wav");
						case 3:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\getdown02.wav");
						case 4:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\gethellout.wav");
						case 5:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\headsup01.wav");
						case 6:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\headsup02.wav");
						case 7:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\incoming02.wav");
						case 8:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\runforyourlife01.wav");
						case 9:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\runforyourlife02.wav");
						case 10:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\strider_run.wav");
						case 11:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\takecover02.wav");
						case 12:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\uhoh.wav");
						case 13:
							Format(randcat,sizeof(randcat),"vo\\npc\\male01\\watchout.wav");
					}
				}
			}
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*run*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			char strisound[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"female") != -1)
				Format(strisound,sizeof(strisound),"vo\\npc\\female01\\strider_run.wav");
			else
				Format(strisound,sizeof(strisound),"vo\\npc\\male01\\strider_run.wav");
			PrecacheSound(strisound,true);
			EmitSoundToAll(strisound, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*help*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			int randsound = GetRandomInt(1,3);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"combine") != -1)
			{
				switch(randsound)
				{
					case 1:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\coverhurt.wav");
					case 2:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\requeststimdose.wav");
					case 3:
						Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\requestmedical.wav");
				}
			}
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
				Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\officerneedshelp.wav");
			else if (StrContains(plymdl,"female") != -1)
				Format(randcat,sizeof(randcat),"vo\\player\\female01\\help0%s.wav",randcat);
			else
				Format(randcat,sizeof(randcat),"vo\\player\\male01\\help0%s.wav",randcat);
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if ((StrContains(sArgs, "*helpbro*", false) != -1) || (StrContains(sArgs, "*helpbrother*", false) != -1))
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			int randsound = GetRandomInt(1,5);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			Format(randcat,sizeof(randcat),"vo\\ravenholm\\monk_helpme0%s.wav",randcat);
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*scream*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 5.0;
			if (FileExists("sound/scientist/scream01.wav",true,NULL_STRING))
			{
				int randsound = GetRandomInt(0,25);
				char randcat[64];
				IntToString(randsound,randcat,sizeof(randcat));
				if (randsound == 0)
					Format(randcat,sizeof(randcat),"scientist\\c1a0_sci_catscream.wav");
				else if (randsound < 10)
					Format(randcat,sizeof(randcat),"scientist\\scream0%s.wav",randcat);
				else
					Format(randcat,sizeof(randcat),"scientist\\scream%s.wav",randcat);
				PrecacheSound(randcat,true);
				EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
			else
			{
				char plymdl[64];
				GetClientModel(client, plymdl, sizeof(plymdl));
				char randcat[64];
				if (StrContains(plymdl,"female") != -1)
					Format(randcat,sizeof(randcat),"ambient\\voices\\f_scream1.wav");
				else
					Format(randcat,sizeof(randcat),"ambient\\voices\\m_scream1.wav");
				PrecacheSound(randcat,true);
				EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if ((StrContains(sArgs, "*vort*", false) != -1) || (StrContains(sArgs, "*vortigaunt*", false) != -1))
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.0;
			int randsound = GetRandomInt(1,14);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			if (randsound < 10)
				Format(randcat,sizeof(randcat),"vo\\npc\\male01\\vanswer0%s.wav",randcat);
			else
				Format(randcat,sizeof(randcat),"vo\\npc\\male01\\vanswer%s.wav",randcat);
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*gunship*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			int randsound = GetRandomInt(1,3);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"combine") != -1)
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\block64jet.wav");
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
				Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\officerneedshelp.wav");
			else if (StrContains(plymdl,"female") != -1)
			{
				if (randsound == 3)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\gunship02.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\barn\\female01\\lite_gunship0%s.wav",randcat);
			}
			else
			{
				if (randsound == 3)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\gunship02.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\barn\\male01\\lite_gunship0%s.wav",randcat);
			}
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*dropship*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			char randcat[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"combine") != -1)
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\block64jet.wav");
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\block64jet.wav");
			else if (StrContains(plymdl,"female") != -1)
			{
				int rand = GetRandomInt(1,2);
				if (rand == 1)
					Format(randcat,sizeof(randcat),"vo\\coast\\barn\\female01\\incomingdropship.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\barn\\female01\\crapships.wav");
			}
			else
			{
				int rand = GetRandomInt(1,2);
				if (rand == 1)
					Format(randcat,sizeof(randcat),"vo\\coast\\barn\\male01\\incomingdropship.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\barn\\male01\\crapships.wav");
			}
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (StrContains(sArgs, "*cheer*", false) != -1)
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			int randsound = GetRandomInt(1,4);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			GetClientModel(client, plymdl, sizeof(plymdl));
			if (StrContains(plymdl,"combine",false) != -1)
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\vo\\thatsitwrapitup.wav");
			else if ((StrContains(plymdl,"metropolice",false) != -1) || (StrContains(plymdl,"metrocop") != -1))
				Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\assaultpointsecureadvance.wav");
			else if (StrContains(plymdl,"female",false) != -1)
			{
				if (randsound == 4)
					Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\female01\\nlo_cheer03.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\female01\\nlo_cheer0%s.wav",randcat);
			}
			else
			{
				Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\male01\\nlo_cheer0%s.wav",randcat);
			}
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if ((StrContains(sArgs, "*follow*", false) != -1) || (StrContains(sArgs, "*followme*", false) != -1))
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			char randcat[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"combine") != -1) || (StrContains(plymdl,"metrocop") != -1))
			{
				int rand = GetRandomInt(1,4);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\allunitsmaintainthiscp.wav");
					case 2:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\allunitscloseonsuspect.wav");
					case 3:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\allunitscode2.wav");
					case 4:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\allunitsrespondcode3.wav");
				}
			}
			else if (StrContains(plymdl,"barney") != -1)
			{
				int rand = GetRandomInt(1,4);
				if (rand != 4)
					Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_followme0%i.wav",rand);
				else
					Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_followme05.wav");
			}
			else if (StrContains(plymdl,"vort") != -1)
			{
				int rand = GetRandomInt(1,2);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"vo\\npc\\vortigaunt\\fmmustfollow.wav");
					case 2:
						Format(randcat,sizeof(randcat),"vo\\npc\\vortigaunt\\followfm.wav");
				}
			}
			else if (StrContains(plymdl,"female") != -1)
			{
				int rand = GetRandomInt(1,6);
				if (rand < 5)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\squad_follow0%i.wav",rand);
				else if (rand == 5)
					Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\female01\\stairman_follow01.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\female01\\stairman_follow03.wav");
			}
			else
			{
				int rand = GetRandomInt(1,6);
				if (rand < 5)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\squad_follow0%i.wav",rand);
				else if (rand == 5)
					Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\male01\\stairman_follow01.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\coast\\odessa\\male01\\stairman_follow03.wav");
			}
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if ((StrContains(sArgs, "*lead*", false) != -1) || (StrContains(sArgs, "*leadon*", false) != -1))
	{
		float Time = GetTickedTime();
		if (antispamchk[client] <= Time)
		{
			antispamchk[client] = Time + 1.5;
			char plymdl[64];
			char randcat[64];
			GetClientModel(client, plymdl, sizeof(plymdl));
			if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"combine") != -1) || (StrContains(plymdl,"metrocop") != -1))
			{
				int rand = GetRandomInt(1,5);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\readytoprosecute.wav");
					case 2:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\readytojudge.wav");
					case 3:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\prosecute.wav");
					case 4:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\keepmoving.wav");
					case 5:
						Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\inpositiononeready.wav");
				}
			}
			else if (StrContains(plymdl,"barney") != -1)
			{
				int rand = GetRandomInt(1,3);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_letsgo.wav",rand);
					case 2:
						Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_letsdoit.wav");
					case 3:
						Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_imwithyou.wav");
				}
			}
			else if (StrContains(plymdl,"vort") != -1)
			{
				int rand = GetRandomInt(1,4);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"vo\\npc\\vortigaunt\\honorfollow.wav");
					case 2:
						Format(randcat,sizeof(randcat),"vo\\npc\\vortigaunt\\wefollowfm.wav");
					case 3:
						Format(randcat,sizeof(randcat),"vo\\npc\\vortigaunt\\leadon.wav");
					case 4:
						Format(randcat,sizeof(randcat),"vo\\npc\\vortigaunt\\leadus.wav");
				}
			}
			else if (StrContains(plymdl,"female") != -1)
			{
				int rand = GetRandomInt(1,4);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\leadon01.wav");
					case 2:
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\leadon02.wav");
					case 3:
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\leadtheway01.wav");
					case 4:
						Format(randcat,sizeof(randcat),"vo\\npc\\female01\\leadtheway02.wav");
				}
			}
			else
			{
				int rand = GetRandomInt(1,4);
				switch(rand)
				{
					case 1:
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\leadon01.wav");
					case 2:
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\leadon02.wav");
					case 3:
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\leadtheway01.wav");
					case 4:
						Format(randcat,sizeof(randcat),"vo\\npc\\male01\\leadtheway02.wav");
				}
			}
			PrecacheSound(randcat,true);
			EmitSoundToAll(randcat, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		}
		else
			PrintToChat(client,"Can't do that for another %.1f seconds.",antispamchk[client]-Time);
		return Plugin_Handled;
	}
	else if (dmact)
	{
		char nick[64];
		GetClientName(client,nick,sizeof(nick));
		if (StrEqual(command,"say_team",false))
		{
			for (int i = 1;i<MaxClients+1;i++)
			{
				if (IsClientInGame(i))
				{
					if (teamnum[client] == teamnum[i])
					{
						if (teamnum[client] == 3) CPrintToChat(i,"{DEFAULT}(TEAM) {RED}%s{DEFAULT}: %s",nick,sArgs);
						else if (teamnum[client] == 2) CPrintToChat(i,"{DEFAULT}(TEAM) {BLUE}%s{DEFAULT}: %s",nick,sArgs);
					}
				}
			}
		}
		else
		{
			if (teamnum[client] == 2) CPrintToChatAll("{BLUE}%s{DEFAULT}: %s",nick,sArgs);
			else if (teamnum[client] == 3) CPrintToChatAll("{RED}%s{DEFAULT}: %s",nick,sArgs);
			else if (clinspectate[client]) PrintToChatAll("*SPEC* %s: %s",nick,sArgs);
			else PrintToChatAll("%s: %s",nick,sArgs);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action saysoundslist(int client, int args)
{
	if (client == 0) PrintToServer("*moan* *pain* *dead* *strider* *run* *help* *helpbro* *scream* *vort* *gunship* *dropship* *cheer* *follow* *lead* *enemy*");
	else PrintToChat(client,"*moan* *pain* *dead* *strider* *run* *help* *helpbro* *scream* *vort* *gunship* *dropship* *cheer* *follow* *lead* *enemy*");
	return Plugin_Handled;
}

public Action spawnallply(int client, int args)
{
	if (args == 0)
	{
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsClientInGame(i) && !IsPlayerAlive(i))
			{
				char name[64];
				GetClientName(i,name,sizeof(name));
				if (client == 0) PrintToServer("Respawned %i %s",i,name);
				else PrintToChat(client,"Respawned %i %s",i,name);
				clused = client;
				CreateTimer(0.1,tpclspawnnew,i);
			}
		}
	}
	else
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int i = StringToInt(h);
		if (IsClientInGame(i) && !IsPlayerAlive(i))
		{
			char name[64];
			GetClientName(i,name,sizeof(name));
			if (client == 0) PrintToServer("Respawned %i %s",i,name);
			else PrintToChat(client,"Respawned %i %s",i,name);
			clused = client;
			CreateTimer(0.1,tpclspawnnew,i);
		}
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	clspawntimeallow[client] = false;
	if (FindStringInArray(afkids,SteamID[client]) != -1)
	{
		clinspectate[client] = true;
		SetVariantInt(1);
		AcceptEntityInput(client,"SetTeamNum");
		SetEntProp(client,Prop_Data,"m_iTeamNum",1);
		teamnum[client] = 1;
		SetEntProp(client,Prop_Data,"deadflag",1);
		SetEntProp(client,Prop_Data,"m_iObserverMode",5);
		SetEntProp(client,Prop_Data,"m_iHideHUD",2056);
		SetEntProp(client,Prop_Data,"m_fEffects",40);
		//SetEntProp(client,Prop_Data,"m_lifeState",1);
		//ForcePlayerSuicide(client);
		return Plugin_Handled;
	}
	CreateTimer(2.0, joincfg, client);
	return Plugin_Continue;
}

//"round_start"
//{
//	"timelimit"	"long"		// round time limit in seconds
//	"fraglimit"	"long"		// frag limit in seconds
//	"objective"	"string"	// round objective
//}
//"round_end"
//{
//	"winner"	"byte"		// winner team/user i
//	"reason"	"byte"		// reson why team won
//	"message"	"string"	// end round message 
//}

public Action roundstart(Handle event, const char[] name, bool dontBroadcast)
{
	float plyeyeang[3];
	float nullvec[3];
	float Time = GetTickedTime();
	roundstartedat = Time+999.0;
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			float pos[3];
			if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",pos);
			else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",pos);
			ClearArray(equiparr);
			if (teamnum[i] == 2) findent(MaxClients+1,"info_player_rebel");
			else if (teamnum[i] == 3) findent(MaxClients+1,"info_player_combine");
			else if (teamnum[i] == 1) findent(MaxClients+1,"info_player_deathmatch");
			if ((GetArraySize(equiparr) < 1) && (teamnum[i] != 0)) findent(MaxClients+1,"info_player_deathmatch");
			if (GetArraySize(equiparr) < 1) findent(MaxClients+1,"info_player_coop");
			if (GetArraySize(equiparr) < 1)
			{
				findent(MaxClients+1,"info_player_start");
				if (GetArraySize(equiparr) > 0)
				{
					float vec[3];
					float spawnang[3];
					GetEntPropVector(GetArrayCell(equiparr,0),Prop_Send,"m_vecOrigin",vec);
					GetEntPropVector(GetArrayCell(equiparr,0),Prop_Send,"m_angRotation",spawnang);
					TeleportEntity(i, vec, spawnang, NULL_VECTOR);
					lastspawned[i] = GetArrayCell(equiparr,0);
				}
			}
			else
			{
				int spawnent = GetArrayCell(equiparr,0);
				if ((lastspawned[i] != spawnent) && (!dmact))
				{
					lastspawned[i] = spawnent;
				}
				else
				{
					for (int j = GetRandomInt(0,GetArraySize(equiparr));j<GetArraySize(equiparr);j++)
					{
						int tmpsp = GetArrayCell(equiparr,j);
						bool rangechk = true;
						float spawnpos[3];
						if (HasEntProp(tmpsp,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(tmpsp,Prop_Data,"m_vecAbsOrigin",spawnpos);
						else if (HasEntProp(tmpsp,Prop_Send,"m_vecOrigin")) GetEntPropVector(tmpsp,Prop_Send,"m_vecOrigin",spawnpos);
						if ((dmact) && (!dmset))
						{
							for (int k = 1;k<MaxClients+1;k++)
							{
								if ((IsValidEntity(k)) && (i != k))
								{
									if ((IsClientInGame(k)) && (IsPlayerAlive(k)))
									{
										float plypos[3];
										GetClientAbsOrigin(k,pos);
										float chkdist = GetVectorDistance(spawnpos,plypos,false);
										if ((chkdist < 200) && (teamnum[i] != teamnum[k])) rangechk = false;
									}
								}
							}
						}
						if ((lastspawned[i] != tmpsp) && (rangechk))
						{
							spawnent = tmpsp;
							lastspawned[i] = tmpsp;
							break;
						}
					}
				}
				float vec[3];
				float spawnang[3];
				GetEntPropVector(spawnent,Prop_Send,"m_vecOrigin",vec);
				GetEntPropVector(spawnent,Prop_Send,"m_angRotation",spawnang);//m_angAbsRotation m_vecAngles
				TeleportEntity(i, vec, spawnang, NULL_VECTOR);
			}
			ClearArray(equiparr);
			GetClientAbsOrigin(i, pos);
			GetClientEyeAngles(i, plyeyeang);
			int cam = CreateEntityByName("point_viewcontrol");
			TeleportEntity(cam, pos, plyeyeang, nullvec);
			DispatchKeyValue(cam, "spawnflags","45");
			DispatchKeyValue(cam, "targetname","roundstartpv");
			DispatchSpawn(cam);
			ActivateEntity(cam);
			AcceptEntityInput(cam,"Enable",i);
			SetVariantString("!activator");
			AcceptEntityInput(cam,"SetParent",i);
			changeteamcd[i] = Time + roundstarttime + 2.0;
			SetEntProp(i,Prop_Data,"m_iHealth",100);
			SetEntProp(i,Prop_Data,"m_ArmorValue",0);
			CreateTimer(0.1,stopcams,cam,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	PrintCenterTextAll("Starting next round in %1.f seconds\nFrags To Win: %i Round End in %1.1f mins",roundstarttime,fraglimit,roundtime/60.0);
	CreateTimer(roundstarttime,nextroundrelease);
	return Plugin_Continue;
}

public Action stopcams(Handle timer, int cam)
{
	if (IsValidEntity(cam))
	{
		char cls[32];
		GetEntityClassname(cam,cls,sizeof(cls));
		if (StrEqual(cls,"point_viewcontrol",false))
		{
			float nullvec[3];
			TeleportEntity(cam, NULL_VECTOR, NULL_VECTOR, nullvec);
		}
	}
}

public Action nextroundrelease(Handle timer)
{
	int loginp = CreateEntityByName("logic_auto");
	DispatchKeyValue(loginp,"spawnflags","1");
	DispatchKeyValue(loginp,"OnMapSpawn","roundstartpv,Disable,,0,-1");
	DispatchKeyValue(loginp,"OnMapSpawn","roundstartpv,kill,,0.1,-1");
	DispatchSpawn(loginp);
	ActivateEntity(loginp);
	roundstartedat = GetTickedTime()+roundtime;
	if (strlen(g_sDMSoundTrack) > 0)
	{
		char sndchk[128];
		Format(sndchk,sizeof(sndchk),"sound/%s",g_sDMSoundTrack);
		if (FileExists(sndchk,true,NULL_STRING))
		{
			if ((IsValidEntity(g_iDMSoundTrack)) && (g_iDMSoundTrack != 0))
			{
				if (HasEntProp(g_iDMSoundTrack,Prop_Data,"m_iszSound"))
				{
					char tmpchk[128];
					GetEntPropString(g_iDMSoundTrack,Prop_Data,"m_iszSound",tmpchk,sizeof(tmpchk));
					if (!StrEqual(g_sDMSoundTrack,tmpchk,false))
					{
						SetEntPropString(g_iDMSoundTrack,Prop_Data,"m_iszSound",g_sDMSoundTrack);
					}
				}
				if (HasEntProp(g_iDMSoundTrack,Prop_Data,"m_iSoundLevel"))
				{
					int cursndlvl = GetEntProp(g_iDMSoundTrack,Prop_Data,"m_iSoundLevel");
					if (cursndlvl != g_iDMSoundTrackVol)
					{
						SetEntProp(g_iDMSoundTrack,Prop_Data,"m_iSoundLevel",g_iDMSoundTrackVol);
					}
				}
				AcceptEntityInput(g_iDMSoundTrack,"PlaySound");
			}
			else
			{
				g_iDMSoundTrack = CreateEntityByName("ambient_generic");
				if (g_iDMSoundTrack != -1)
				{
					DispatchKeyValue(g_iDMSoundTrack,"message",g_sDMSoundTrack);
					DispatchKeyValue(g_iDMSoundTrack,"health","10");
					DispatchKeyValue(g_iDMSoundTrack,"spawnflags","1");
					DispatchSpawn(g_iDMSoundTrack);
					ActivateEntity(g_iDMSoundTrack);
					SetEntProp(g_iDMSoundTrack,Prop_Data,"m_iSoundLevel",g_iDMSoundTrackVol);
					AcceptEntityInput(g_iDMSoundTrack,"PlaySound");
				}
			}
		}
		else
		{
			PrintToServer("Deathmatch song %s does not exist",g_sDMSoundTrack);
		}
	}
}

public Action roundintermission(Handle event, const char[] name, bool dontBroadcast)
{
	if ((IsValidEntity(g_iDMSoundTrack)) && (g_iDMSoundTrack != 0))
	{
		AcceptEntityInput(g_iDMSoundTrack,"StopSound");
	}
	float plyeyeang[3];
	float nullvec[3];
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			float pos[3];
			if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",pos);
			else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",pos);
			ClearArray(equiparr);
			if (teamnum[i] == 2) findent(MaxClients+1,"info_player_rebel");
			else if (teamnum[i] == 3) findent(MaxClients+1,"info_player_combine");
			else if (teamnum[i] == 1) findent(MaxClients+1,"info_player_deathmatch");
			if ((GetArraySize(equiparr) < 1) && (teamnum[i] != 0)) findent(MaxClients+1,"info_player_deathmatch");
			if (GetArraySize(equiparr) < 1) findent(MaxClients+1,"info_player_coop");
			if (GetArraySize(equiparr) < 1)
			{
				findent(MaxClients+1,"info_player_start");
				if (GetArraySize(equiparr) > 0)
				{
					float vec[3];
					float spawnang[3];
					GetEntPropVector(GetArrayCell(equiparr,0),Prop_Send,"m_vecOrigin",vec);
					GetEntPropVector(GetArrayCell(equiparr,0),Prop_Send,"m_angRotation",spawnang);
					TeleportEntity(i, vec, spawnang, NULL_VECTOR);
					lastspawned[i] = GetArrayCell(equiparr,0);
				}
			}
			else
			{
				int spawnent = GetArrayCell(equiparr,0);
				if ((lastspawned[i] != spawnent) && (!dmact))
				{
					lastspawned[i] = spawnent;
				}
				else
				{
					for (int j = GetRandomInt(0,GetArraySize(equiparr));j<GetArraySize(equiparr);j++)
					{
						int tmpsp = GetArrayCell(equiparr,j);
						bool rangechk = true;
						float spawnpos[3];
						if (HasEntProp(tmpsp,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(tmpsp,Prop_Data,"m_vecAbsOrigin",spawnpos);
						else if (HasEntProp(tmpsp,Prop_Send,"m_vecOrigin")) GetEntPropVector(tmpsp,Prop_Send,"m_vecOrigin",spawnpos);
						if ((dmact) && (!dmset))
						{
							for (int k = 1;k<MaxClients+1;k++)
							{
								if ((IsValidEntity(k)) && (i != k))
								{
									if ((IsClientInGame(k)) && (IsPlayerAlive(k)))
									{
										float plypos[3];
										GetClientAbsOrigin(k,pos);
										float chkdist = GetVectorDistance(spawnpos,plypos,false);
										if ((chkdist < 200) && (teamnum[i] != teamnum[k])) rangechk = false;
									}
								}
							}
						}
						if ((lastspawned[i] != tmpsp) && (rangechk))
						{
							spawnent = tmpsp;
							lastspawned[i] = tmpsp;
							break;
						}
					}
				}
				float vec[3];
				float spawnang[3];
				GetEntPropVector(spawnent,Prop_Send,"m_vecOrigin",vec);
				GetEntPropVector(spawnent,Prop_Send,"m_angRotation",spawnang);//m_angAbsRotation m_vecAngles
				TeleportEntity(i, vec, spawnang, NULL_VECTOR);
			}
			ClearArray(equiparr);
			GetClientAbsOrigin(i, pos);
			GetClientEyeAngles(i, plyeyeang);
			int cam = CreateEntityByName("point_viewcontrol");
			TeleportEntity(cam, pos, plyeyeang, nullvec);
			CreateTimer(0.1,stopcams,cam,TIMER_FLAG_NO_MAPCHANGE);
			DispatchKeyValue(cam, "spawnflags","45");
			DispatchKeyValue(cam, "targetname","roundendpv");
			DispatchSpawn(cam);
			ActivateEntity(cam);
			AcceptEntityInput(cam,"Enable",i);
		}
	}
	PrintCenterTextAll("Starting next round in %1.f seconds",endfreezetime);
	CreateTimer(endfreezetime,nextroundstart);
	return Plugin_Continue;
}

public Action nextroundstart(Handle timer)
{
	for (int i = 1;i<MaxClients+1;i++)
	{
		dmkills[i] = 0;
		if (IsValidEntity(i))
		{
			if ((IsClientInGame(i)) && (IsPlayerAlive(i)))
			{
				if (HasEntProp(i,Prop_Data,"m_iFrags"))
				{
					SetEntProp(i,Prop_Data,"m_iFrags",0);
				}
			}
		}
	}
	redteamkills = 0;
	blueteamkills = 0;
	int loginp = CreateEntityByName("logic_auto");
	DispatchKeyValue(loginp,"spawnflags","1");
	DispatchKeyValue(loginp,"OnMapSpawn","roundendpv,Disable,,0,-1");
	DispatchKeyValue(loginp,"OnMapSpawn","roundendpv,kill,,0.1,-1");
	DispatchSpawn(loginp);
	ActivateEntity(loginp);
	Handle startround = CreateEvent("round_start");
	SetEventFloat(startround,"timelimit",roundtime);
	SetEventFloat(startround,"fraglimit",roundtime);
	FireEvent(startround,false);
	return Plugin_Handled;
}

public Action roundtimeout(Handle timer)
{
	if (((dmact) || (dmset)) && (roundtime != 0))
	{
		float Time = GetTickedTime();
		if (1.0*(roundstartedat-Time) < 1.0)
		{
			Handle endround = CreateEvent("round_end");
			SetEventInt(endround,"winner",0);
			SetEventInt(endround,"reason",0);
			SetEventString(endround,"message","Round Timed Out");
			FireEvent(endround,false);
			int topscore = 0;
			char winners[128];
			char clname[64];
			Handle arrayoftop = CreateArray(65);
			for (int i = 1;i<MaxClients+1;i++)
			{
				if (IsValidEntity(i))
				{
					if ((IsClientConnected(i)) && (IsClientInGame(i)))
					{
						if ((dmkills[i] >= topscore) && (dmkills[i] > 0))
						{
							if (dmkills[i] > topscore) ClearArray(arrayoftop);
							if (FindValueInArray(arrayoftop,i) == -1) PushArrayCell(arrayoftop,i);
							topscore = dmkills[i];
						}
					}
				}
			}
			if (GetArraySize(arrayoftop) > 0)
			{
				for (int i = 0;i<GetArraySize(arrayoftop);i++)
				{
					int j = GetArrayCell(arrayoftop,i);
					if (IsValidEntity(j))
					{
						if ((IsClientConnected(j)) && (IsClientInGame(j)))
						{
							GetClientName(j,clname,sizeof(clname));
							Format(winners,sizeof(winners),"%s%s ",winners,clname);
						}
					}
				}
			}
			if (strlen(winners) > 0)
			{
				TrimString(winners);
				if (GetArraySize(arrayoftop) > 1)
				{
					PrintCenterTextAll("%s\nTied For First Place",winners);
					PrintToChatAll("%s\nTied For First Place",winners);
				}
				else
				{
					PrintCenterTextAll("%s Wins",winners);
					PrintToChatAll("%s Wins",winners);
				}
			}
			else
			{
				PrintCenterTextAll("Nobody Wins");
				PrintToChatAll("Nobody Wins");
			}
			CloseHandle(arrayoftop);
			roundstartedat = Time + 999.0;
		}
		else if (RoundFloat(1.0*(roundstartedat-Time)) == 10)
		{
			PrintCenterTextAll("10 seconds left!");
		}
		else if ((RoundFloat(1.0*(roundstartedat-Time)) == 30) && (roundtime > 30.0))
		{
			PrintCenterTextAll("30 seconds left!");
		}
		else if ((RoundFloat(1.0*(roundstartedat-Time)) == 60) && (roundtime > 61.0))
		{
			PrintCenterTextAll("1 minute left!");
		}
	}
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
		{
			if ((IsClientConnected(i)) && (IsClientInGame(i)))
			{
				if (clinspectate[i])
				{
					int spectarg = GetEntPropEnt(i,Prop_Data,"m_hObserverTarget");
					if ((GetEntProp(i,Prop_Data,"m_lifeState") == 0) && (spectarg != -1)) SetEntProp(i,Prop_Data,"m_lifeState",2);
					if (spectarg != -1)
					{
						float orgreset[3];
						if (HasEntProp(spectarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spectarg,Prop_Data,"m_vecAbsOrigin",orgreset);
						else if (HasEntProp(spectarg,Prop_Data,"m_vecOrigin")) GetEntPropVector(spectarg,Prop_Data,"m_vecOrigin",orgreset);
						SetEntPropVector(i,Prop_Data,"m_vecOrigin",orgreset);
					}
					else ClientCommand(i,"spec_next");
				}
			}
		}
	}
}

bool cltouchend(int client)
{
	if (GetArraySize(changelevels) < 1)
	{
		findtrigs(-1,"trigger_changelevel");
		for (int i = 0;i<GetArraySize(changelevels);i++)
		{
			int j = GetArrayCell(changelevels,j);
			if (IsValidEntity(j))
			{
				float mins[3];
				float maxs[3];
				GetEntPropVector(j,Prop_Send,"m_vecMins",mins);
				GetEntPropVector(j,Prop_Send,"m_vecMaxs",maxs);
				float porigin[3];
				GetClientAbsOrigin(client,porigin);
				if ((porigin[0] > mins[0]) && (porigin[1] > mins[1]) && (porigin[2] > mins[2]) && (porigin[0] < maxs[0]) && (porigin[1] < maxs[1]) && (porigin[2] < maxs[2]))
				{
					return true;
				}
			}
		}
	}
	else
	{
		for (int i = 0;i<GetArraySize(changelevels);i++)
		{
			int j = GetArrayCell(changelevels,j);
			if (IsValidEntity(j))
			{
				char clschk[32];
				GetEntityClassname(j,clschk,sizeof(clschk));
				if (!StrEqual(clschk,"trigger_changelevel",false))
				{
					ClearArray(changelevels);
					findtrigs(-1,"trigger_changelevel");
					break;
				}
				float mins[3];
				float maxs[3];
				GetEntPropVector(j,Prop_Send,"m_vecMins",mins);
				GetEntPropVector(j,Prop_Send,"m_vecMaxs",maxs);
				float porigin[3];
				GetClientAbsOrigin(client,porigin);
				if ((porigin[0] > mins[0]) && (porigin[1] > mins[1]) && (porigin[2] > mins[2]) && (porigin[0] < maxs[0]) && (porigin[1] < maxs[1]) && (porigin[2] < maxs[2]))
				{
					return true;
				}
			}
		}
	}
	return false;
}

void findtrigs(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if((thisent >= MaxClients+1) && (FindValueInArray(changelevels, thisent) == -1))
		{
			PushArrayCell(changelevels, thisent);
		}
		findtrigs(thisent++,clsname);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	CreateTimer(1.0,joincfg,client);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	//int cl1team = GetEntProp(attacker,Prop_Data,"m_iTeamNum");
	//int cl2team = GetEntProp(victim,Prop_Data,"m_iTeamNum");
	if ((attacker < MaxClients+1) && (victim < MaxClients+1))
	{
		if ((teamnum[attacker] == teamnum[victim]) && (dmact) && (!dmset))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		if ((damagetype == 32) && (falldamagedis))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & buttonscoreboard) {
		if (!(g_LastButtons[client] & buttonscoreboard)) {
			OnButtonPressscoreboard(client, buttonscoreboard);
		}
	}
}

public Action joincfg(Handle timer, int client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		ClientCommand(client,"crosshair 1");
		if (HasEntProp(client,Prop_Send,"m_bDisplayReticle"))
			SetEntProp(client,Prop_Send,"m_bDisplayReticle",1);
		if (FindStringInArray(afkids,SteamID[client]) != -1)
		{
			clinspectate[client] = true;
			SetVariantInt(1);
			AcceptEntityInput(client,"SetTeamNum");
			SetEntProp(client,Prop_Data,"m_iTeamNum",1);
			teamnum[client] = 1;
			SetEntProp(client,Prop_Data,"deadflag",1);
			SetEntProp(client,Prop_Data,"m_iObserverMode",5);
			SetEntProp(client,Prop_Data,"m_iHideHUD",2056);
			SetEntProp(client,Prop_Data,"m_fEffects",40);
			//SetEntProp(client,Prop_Data,"m_lifeState",1);
			//ForcePlayerSuicide(client);
			return Plugin_Handled;
		}
		if (dmact)
		{
			if (teamnum[client] == 0)
			{
				int rand = 1;
				if (!dmset) rand = GetRandomInt(2,3);
				//SetEntProp(client,Prop_Data,"m_iTeamNum",rand);
				teamnum[client] = rand;
			}
			ClientCommand(client,"hud_player_info_enable 0");
		}
		else
		{
			ClientCommand(client,"hud_player_info_enable 1");
			ClientCommand(client,"bind tab +showscores");
			//SetEntProp(client,Prop_Data,"m_iTeamNum",0);
			teamnum[client] = 0;
		}
		if (survivalact)
		{
			int arrindx = FindStringInArray(respawnids,SteamID[client]);
			if (arrindx != -1)
			{
				ForcePlayerSuicide(client);
				PrintToChat(client,"You cannot respawn yet.");
			}
		}
		findent(MaxClients+1,"info_player_equip");
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
			if (IsValidEntity(jtmp))
			{
				if (HasEntProp(jtmp,Prop_Data,"m_iszResponseContext"))
				{
					EquipCustom(jtmp,client);
				}
			}
		}
		ClearArray(equiparr);
		if (aggro)
		{
			float orgs[3];
			if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(client,Prop_Data,"m_vecOrigin")) GetEntPropVector(client,Prop_Data,"m_vecOrigin",orgs);
			char apoint[64];
			GetClientAuthId(client,AuthId_Steam2,apoint,sizeof(apoint));
			Format(apoint,sizeof(apoint),"%sapoint",apoint);
			int finder = CreateEntityByName("assault_assaultpoint");
			if (finder != -1)
			{
				DispatchKeyValue(finder,"targetname",apoint);
				DispatchKeyValue(finder,"assaulttimeout","10");
				DispatchKeyValue(finder,"allowdiversion","1");
				DispatchKeyValue(finder,"nevertimeout","1");
				TeleportEntity(finder,orgs,NULL_VECTOR,NULL_VECTOR);
				DispatchSpawn(finder);
				ActivateEntity(finder);
				SetVariantString("!activator");
				AcceptEntityInput(finder,"SetParent",client);
			}
			finder = CreateEntityByName("assault_rallypoint");
			if (finder != -1)
			{
				DispatchKeyValue(finder,"assaultpoint",apoint);
				TeleportEntity(finder,orgs,NULL_VECTOR,NULL_VECTOR);
				DispatchSpawn(finder);
				ActivateEntity(finder);
				SetVariantString("!activator");
				AcceptEntityInput(finder,"SetParent",client);
			}
		}
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(1.0,joincfg,client);
	}
	return Plugin_Handled;
}

public OnClientAuthorized(int client, const char[] szAuth)
{
	GetClientAuthId(client,AuthId_Steam2,SteamID[client],sizeof(SteamID[]));
	CreateTimer(2.0, joincfg, client);
}

public void OnMapStart()
{
	hasread = false;
	activecheckpoint = "";
	GetCurrentMap(mapbuf,sizeof(mapbuf));
	Handle mdirlisting = OpenDirectory("maps/ent_cache", false);
	char buff[64];
	while (ReadDirEntry(mdirlisting, buff, sizeof(buff)))
	{
		if ((!(mdirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
		{
			if ((!(StrContains(buff, ".ztmp", false) != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
			{
				if (StrContains(buff,mapbuf,false) != -1)
				{
					Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s",buff);
					break;
				}
			}
		}
	}
	CloseHandle(mdirlisting);
	ClearArray(respawnids);
	ClearArray(changelevels);
	ClearArray(inputsarrorigincls);
	WeapList = -1;
	scoreshow = -1;
	scoreshowstat = -1;
	g_iDMSoundTrack = -1;
	canceltimer = 0;
	hasstarted = true;
	HookEntityOutput("trigger_once","OnTrigger",EntityOutput:trigsaves);
	HookEntityOutput("trigger_once","OnStartTouch",EntityOutput:trigsaves);
	HookEntityOutput("logic_relay","OnTrigger",EntityOutput:trigsaves);
	HookEntityOutput("trigger_multiple","OnTrigger",EntityOutput:trigsaves);
	HookEntityOutput("trigger_multiple","OnStartTouch",EntityOutput:trigsaves);
	HookEntityOutput("trigger_coop","OnTrigger",EntityOutput:trigsaves);
	HookEntityOutput("trigger_coop","OnStartTouch",EntityOutput:trigsaves);
	HookEntityOutput("point_viewcontrol","OnEndFollow",EntityOutput:trigsaves);
	HookEntityOutput("scripted_sequence","OnBeginSequence",EntityOutput:trigsaves);
	HookEntityOutput("scripted_sequence","OnEndSequence",EntityOutput:trigsaves);
	HookEntityOutput("scripted_scene","OnStart",EntityOutput:trigsaves);
	HookEntityOutput("func_button","OnPressed",EntityOutput:trigsaves);
	HookEntityOutput("func_button","OnUseLocked",EntityOutput:trigsaves);
	HookEntityOutput("func_door","OnOpen",EntityOutput:trigsaves);
	HookEntityOutput("func_door","OnFullyOpen",EntityOutput:trigsaves);
	HookEntityOutput("func_door","OnClose",EntityOutput:trigsaves);
	HookEntityOutput("func_door","OnFullyClosed",EntityOutput:trigsaves);
	for (int i = 1;i<MaxClients+1;i++)
	{
		g_LastButtons[i] = 0;
		clinspectate[i] = false;
		if (IsValidEntity(i))
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				CreateTimer(0.1,joincfg,i);
			}
		}
	}
	CreateTimer(0.1,rehooksaves);
	CreateTimer(30.0,RecheckAFKList,_,TIMER_FLAG_NO_MAPCHANGE);
}

public Action rehooksaves(Handle timer)
{
	findsavetrigs(-1,"trigger_autosave");
	char curgamemode[16];
	Handle cvar = FindConVar("sm_gamemodeset");
	if (cvar != INVALID_HANDLE) GetConVarString(cvar,curgamemode,sizeof(curgamemode));
	CloseHandle(cvar);
	if (StrEqual(curgamemode,"dm",false)) setupdmfor("dm");
	else if (StrEqual(curgamemode,"tdm",false)) setupdmfor("tdm");
	else if (StrEqual(curgamemode,"survival",false)) setupdmfor("survival");
	else setupdmfor("coop");
	readoutputsforinputs();
}

public Action findsavetrigs(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		float origins[3];
		char mdlnum[16];
		GetEntPropVector(thisent, Prop_Send, "m_vecOrigin", origins);
		GetEntPropString(thisent, Prop_Data, "m_ModelName", mdlnum,sizeof(mdlnum));
		CreateTrig(origins,mdlnum);
		findsavetrigs(thisent++,clsname);
	}
	return Plugin_Handled;
}

public Action RecheckAFKList(Handle timer)
{
	for (int client = 1;client<MaxClients+1;client++)
	{
		if (strlen(SteamID[client]) > 0)
		{
			if ((!IsValidEntity(client)) || (!IsClientConnected(client)))
			{
				int find = FindStringInArray(afkids,SteamID[client]);
				if (find != -1) RemoveFromArray(afkids,find);
			}
		}
	}
}

void CreateTrig(float origins[3], char[] mdlnum)
{
	int autostrig = CreateEntityByName("trigger_once");
	DispatchKeyValue(autostrig,"model",mdlnum);
	DispatchKeyValue(autostrig,"spawnflags","1");
	TeleportEntity(autostrig,origins,NULL_VECTOR,NULL_VECTOR);
	DispatchSpawn(autostrig);
	ActivateEntity(autostrig);
	HookSingleEntityOutput(autostrig,"OnStartTouch",EntityOutput:autostrigout,true);
}

public Action autostrigout(const char[] output, int caller, int activator, float delay)
{
	if (survivalact) resetvehicles(0.0,activator);
}

public Action trigsaves(const char[] output, int caller, int activator, float delay)
{
	if (survivalact)
	{
		if ((activator < MaxClients+1) && (activator > 0))
		{
			if (IsPlayerAlive(activator))
			{
				char targn[64];
				GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
				float origin[3];
				if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
				else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
				char tmpout[32];
				Format(tmpout,sizeof(tmpout),output);
				readoutputstp(targn,tmpout,"Save",origin,activator);
				readoutputstp(targn,tmpout,"SetCheckPoint",origin,activator);
			}
		}
	}
	else
	{
		if ((IsValidEntity(caller)) && (IsEntNetworkable(caller)))
		{
			char targn[64];
			if (HasEntProp(caller,Prop_Data,"m_iName")) GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
			float origin[3];
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
			char tmpout[32];
			Format(tmpout,sizeof(tmpout),output);
			readoutputstp(targn,tmpout,"SetCheckPoint",origin,activator);
		}
	}
}

void readoutputstp(char[] targn, char[] output, char[] input, float origin[3], int activator)
{
	if (GetArraySize(inputsarrorigincls) < 1) readoutputsforinputs();
	else
	{
		char tmpoutpchk[128];
		Format(tmpoutpchk,sizeof(tmpoutpchk),"\"%s,AddOutput,%s ",targn,output);
		char originchar[64];
		Format(originchar,sizeof(originchar),"%i %i %i",RoundFloat(origin[0]),RoundFloat(origin[1]),RoundFloat(origin[2]));
		char origintargnfind[128];
		if (strlen(targn) > 0) Format(origintargnfind,sizeof(origintargnfind),"%s\"%s\"",targn,originchar);
		else Format(origintargnfind,sizeof(origintargnfind),"notargn\"%s\"",originchar);
		int arrindx = -1;
		char tmpch[128];
		for (int i = 0;i<GetArraySize(inputsarrorigincls);i++)
		{
			GetArrayString(inputsarrorigincls,i,tmpch,sizeof(tmpch));
			if ((StrContains(tmpch,origintargnfind,false) != -1) || (StrContains(tmpch,tmpoutpchk,false) != -1))
			{
				arrindx = i;
				break;
			}
		}
		if (arrindx == -1) return;
		char originclschar[128];
		char clsorfixup[16][128];
		GetArrayString(inputsarrorigincls,arrindx,originclschar,sizeof(originclschar));
		if (StrContains(originclschar,tmpoutpchk,false) != -1)
		{
			char tmpoutrem[64];
			Format(tmpoutrem,sizeof(tmpoutrem),tmpoutpchk);
			Format(tmpoutrem,sizeof(tmpoutrem),"%s\"%s\" \"",tmpoutrem,output);
			ReplaceString(tmpoutrem,sizeof(tmpoutpchk),tmpoutpchk,"");
			ReplaceString(originclschar,sizeof(originclschar),tmpoutpchk,tmpoutrem);
		}
		ExplodeString(originclschar,"\"",clsorfixup,16,128);
		char inputadded[64];
		Format(inputadded,sizeof(inputadded),":%s::",input);
		char inputdef[64];
		Format(inputdef,sizeof(inputdef),",%s,,",input);
		if ((StrEqual(originchar,clsorfixup[1],false)) || (StrEqual(targn,clsorfixup[0],false)) || (StrContains(inputadded,clsorfixup[1],false)))
		{
			char lineorgrescom[16][64];
			if ((StrContains(clsorfixup[5],",") != -1) && (StrContains(clsorfixup[5],":") == -1))
			{
				if (StrContains(clsorfixup[3],output,false) == -1) return;
				ExplodeString(clsorfixup[5],",",lineorgrescom,16,64);
				//ReplaceString(lineorgrescom[0],sizeof(lineorgrescom[])," ","");
				float delay = StringToFloat(lineorgrescom[3]);
				if (survivalact) resetvehicles(delay,activator);
				if (StrContains(lineorgrescom[1],"SetCheckPoint",false) != -1) Format(activecheckpoint,sizeof(activecheckpoint),lineorgrescom[2]);
			}
			else
			{
				ExplodeString(clsorfixup[5],":",lineorgrescom,16,64);
				if (StrContains(clsorfixup[3],output,false) == -1) return;
				char delaystr[64];
				Format(delaystr,sizeof(delaystr),lineorgrescom[3]);
				//ReplaceString(lineorgrescom[1],64,lineorgrescom[1],"");
				float delay = StringToFloat(lineorgrescom[3]);
				if (survivalact) resetvehicles(delay,activator);
				if (StrContains(lineorgrescom[1],"SetCheckPoint",false) != -1) Format(activecheckpoint,sizeof(activecheckpoint),lineorgrescom[2]);
			}
		}
	}
	return;
}

void readoutputsforinputs()
{
	if (hasread) return;
	hasread = true;
	Handle filehandle = OpenFile(mapbuf,"r");
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		char inputadded[64];
		Format(inputadded,sizeof(inputadded),":SetCheckPoint:");
		char inputdef[64];
		Format(inputdef,sizeof(inputdef),",SetCheckPoint,");
		char inputadded2[64];
		Format(inputadded2,sizeof(inputadded2),":Save::");
		char inputdef2[64];
		Format(inputdef2,sizeof(inputdef2),",Save,,");
		char lineorgres[128];
		char lineorgresexpl[4][16];
		char lineoriginfixup[64];
		char lineadj[128];
		bool hastargn = false;
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)))
			{
				lineoriginfixup = "";
				hastargn = false;
			}
			if (StrContains(line,"\"origin\"",false) == 0)
			{
				char tmpchar[64];
				Format(tmpchar,sizeof(tmpchar),"%s",line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				ExplodeString(tmpchar, " ", lineorgresexpl, 4, 16);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%i %i %i\"",RoundFloat(StringToFloat(lineorgresexpl[0])),RoundFloat(StringToFloat(lineorgresexpl[1])),RoundFloat(StringToFloat(lineorgresexpl[2])));
			}
			else if (StrContains(line,"\"targetname\"",false) == 0)
			{
				char tmpchar[72];
				Format(tmpchar,sizeof(tmpchar),"%s",line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" \"","");
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","");
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s\"%s",tmpchar,lineoriginfixup);
				hastargn = true;
			}
			else if ((StrContains(line,inputadded,false) != -1) || (StrContains(line,inputadded2,false) != -1) || (StrContains(line,inputdef,false) != -1) || (StrContains(line,inputdef2,false) != -1))
			{
				Format(lineorgres,sizeof(lineorgres),"%s",line);
				ReplaceString(lineorgres,sizeof(lineorgres),"\"OnMapSpawn\" ","");
				if (!hastargn)
				{
					Format(lineoriginfixup,sizeof(lineoriginfixup),"notargn\"%s",lineoriginfixup);
					hastargn = true;
				}
				Format(lineadj,sizeof(lineadj),"%s %s",lineoriginfixup,lineorgres);
				if (FindStringInArray(inputsarrorigincls,lineadj) == -1)
				{
					PushArrayString(inputsarrorigincls,lineadj);
				}
			}
			//if (StrContains(line,"\"classname\"",false) == 0)
			//Team 2 is combine
			//Team 3 is rebel
			//info_player_rebel
			//info_player_combine
		}
	}
	CloseHandle(filehandle);
	return;
}

void resetvehicles(float delay, int activator)
{
	if (delay > 0.0) CreateTimer(delay,recallreset);
	else
	{
		if ((IsValidEntity(activator)) && (IsClientInGame(activator)) && (IsPlayerAlive(activator))) clused = activator;
		Handle ignorelist = CreateArray(64);
		for (int i = 1;i<MaxClients+1;i++)
		{
			if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)) && (!resetvehpass))
			{
				int vehicles = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
				if (vehicles > MaxClients)
				{
					int driver = GetEntProp(i,Prop_Data,"m_iHideHUD");
					int running = GetEntProp(vehicles,Prop_Data,"m_bIsOn");
					if ((driver == 3328) && (running))
					{
						char clsname[32];
						GetEntityClassname(vehicles,clsname,sizeof(clsname));
						if (((StrEqual(clsname,"prop_vehicle_jeep",false)) || (StrEqual(clsname,"prop_vehicle_mp",false))) && (FindValueInArray(ignorelist,vehicles) == -1))
						{
							SetEntProp(vehicles,Prop_Data,"m_controls.handbrake",1);
							PushArrayCell(ignorelist,vehicles);
						}
					}
				}
			}
			else if ((IsValidEntity(i)) && (IsClientInGame(i)) && (!IsPlayerAlive(i)) && (survivalact))
			{
				clspawntimeallow[i] = true;
				CreateTimer(0.1,tpclspawnnew,i);
			}
		}
		CloseHandle(ignorelist);
	}
}

public Action recallreset(Handle timer)
{
	resetvehicles(0.0,0);
}

public void OnClientDisconnect(int client)
{
	dmkills[client] = 0;
	changeteamcd[client] = 0.0;
	scoreshowcd[client] = 0.0;
	g_LastButtons[client] = 0;
	antispamchk[client] = 0.0;
	clinspectate[client] = false;
	SteamID[client] = "";
}
