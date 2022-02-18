#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#tryinclude <synfixes>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;
#pragma dynamic 2097152;

bool enterfrom04 = false;
bool enterfrom04pb = false;
bool enterfrom03 = false;
bool enterfrom03pb = false;
bool enterfrom08 = false;
bool enterfrom08pb = false;
bool enterfromep1 = false;
bool enterfromep2 = false;
bool enterfrom4g = false;
bool reloadingmap = false;
bool bIsVehicleMap = false;
bool bRebuildTransition = false; //Set by cvar sm_disabletransition
bool bNoDelete = true; //Set by cvar sm_disabletransition 3
bool bTransitionPlayers = false; //Set by cvar sm_disabletransition 2
bool reloadaftersetup = false;
bool BMActive = false;
bool SynLaterAct = false;
bool bLinuxAct = false;
int iWeaponListOffset = -1;
int reloadtype = 0;
int logsv = -1;
int logplyprox = -1;
int saveresetm = 1;
int iCreatedTable = 0;
int iRestoreProperty[128][2];
float votetime = 0.0;
float g_vecLandmarkOrigin[3];
float flMapStartTime = 0.0;

// Stores Steam IDs to be retrieved from the data packs array
Handle g_hTransitionIDs = INVALID_HANDLE;
Handle g_hTransitionDataPacks = INVALID_HANDLE;
// Stores whether or not to restore origin if player was alive on transition
Handle g_hTransitionPlayerOrigin = INVALID_HANDLE;

Handle g_hTransitionEntities = INVALID_HANDLE;
Handle g_hGlobalsTransition = INVALID_HANDLE;
Handle g_hIgnoredEntities = INVALID_HANDLE;

// Timeout handle for clearing transition data for late connect players
Handle g_hTimeout = INVALID_HANDLE;
// Stores equipment entities for equipping players
Handle g_hEquipEnts = INVALID_HANDLE;

// Deletion CVars
ConVar hCVbDelTransitionPly, hCVbDelTransitionEnts;
// Landmark bounding box transition
ConVar hCVLandMarkBox, hCVLandMarkBoxSize;
// Enable attempting transition of global states
ConVar hCVbTransitionGlobals;
// Vote CVars
ConVar hCVbVoteReloadSaves, hCVbVoteCreateSaves;
ConVar hCVflVoteRestorePercent, hCVflVoteCreateSavePercent;
// Misc CVars
ConVar g_hCVbApplyFallbackEquip, g_hCVbDebugTransitions, g_hCVbTransitionSkipVersion, g_hCVbTransitionMode;

char szLandmarkName[64];
char mapbuf[128];
char szNextMap[64];
char szPreviousMap[64];
char savedir[64];
char szReloadSaveName[32];
char szMapEntitiesBuff[2097152];

#define PLUGIN_VERSION "2.205"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synsaverestoreupdater.txt"

Menu g_hVoteMenu = null;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

public Plugin myinfo = 
{
	name = "SynSaveRestore",
	author = "Balimbanana",
	description = "Allows you to create persistent saves and reload them per-map.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	
	g_hTransitionIDs = CreateArray(128);
	g_hTransitionDataPacks = CreateArray(128);
	g_hTransitionPlayerOrigin = CreateArray(128);
	g_hTransitionEntities = CreateArray(256);
	g_hGlobalsTransition = CreateArray(16);
	g_hIgnoredEntities = CreateArray(256);
	g_hEquipEnts = CreateArray(32);
	
	RegAdminCmd("savegame",savecurgame,ADMFLAG_RESERVATION,".");
	RegAdminCmd("loadgame",loadgame,ADMFLAG_PASSWORD,".");
	RegAdminCmd("deletesave",DeleteSave,ADMFLAG_PASSWORD,".");
	RegConsoleCmd("votereload",votereloadchk);
	RegConsoleCmd("votereloadmap",votereloadmap);
	RegConsoleCmd("votereloadsave",votereload);
	RegConsoleCmd("voterecreatesave",votecreatesave);
	
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	HookEventEx("round_start",Event_RoundStart,EventHookMode_Post);
	
	char szSavePath[256];
	BuildPath(Path_SM,szSavePath,sizeof(szSavePath),"data/SynSaves");
	if (!DirExists(szSavePath)) CreateDirectory(szSavePath,511);
	
	hCVbVoteReloadSaves = CreateConVar("sm_reloadsaves", "1", "Enable anyone to vote to reload a saved game, default is 1", _, true, 0.0, true, 1.0);
	hCVbVoteCreateSaves = CreateConVar("sm_createsaves", "1", "Enable anyone to vote to create a save game, default is 1", _, true, 0.0, true, 1.0);
	hCVflVoteRestorePercent = CreateConVar("sm_voterestore", "0.80", "People need to vote to at least this percent to pass checkpoint and map reload.", _, true, 0.0, true, 1.0);
	hCVflVoteCreateSavePercent = CreateConVar("sm_votecreatesave", "0.60", "People need to vote to at least this percent to pass creating a save.", _, true, 0.0, true, 1.0);
	Handle disabletransitionh = CreateConVar("sm_disabletransition", "2", "Disable transition save/reloads. 2 rebuilds transitions using SourceMod. 3 rebuilds and will not delete certain save data.", _, true, 0.0, true, 3.0);
	if (GetConVarInt(disabletransitionh) >= 2)
	{
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
		if (GetConVarInt(disabletransitionh) == 3) bNoDelete = true;
		else bNoDelete = false;
		bRebuildTransition = true;
		bTransitionPlayers = true;
	}
	else if (GetConVarInt(disabletransitionh) == 1)
	{
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
		bRebuildTransition = true;
		bNoDelete = false;
		bTransitionPlayers = false;
	}
	else if (GetConVarInt(disabletransitionh) == 0)
	{
		bRebuildTransition = false;
		bNoDelete = true;
		bTransitionPlayers = false;
	}
	HookConVarChange(disabletransitionh, disabletransitionch);
	CloseHandle(disabletransitionh);
	g_hCVbApplyFallbackEquip = CreateConVar("sm_equipfallback_disable", "0", "Disables fallback equips when player spawns after transition.", _, true, 0.0, true, 1.0);
	g_hCVbDebugTransitions = CreateConVar("sm_transitiondebug", "0", "Logs transition entities for both save and restore.", _, true, 0.0, true, 1.0);
	g_hCVbTransitionSkipVersion = CreateConVar("sm_transitionskipver", "0", "Skip version check and run full transition overrides.", _, true, 0.0, true, 1.0);
	g_hCVbTransitionMode = CreateConVar("sm_transition_mode", "0", "Changes mode of what entities to transition. 0 is base list, 1 is all stable entities.", _, true, 0.0, true, 1.0);
	Handle saveresetmode = FindConVar("sm_transitionreset_mode");
	if (saveresetmode != INVALID_HANDLE)
	{
		HookConVarChange(saveresetmode, transitionresetmch);
		saveresetm = GetConVarInt(saveresetmode);
	}
	else
	{
		saveresetmode = CreateConVar("sm_transitionreset_mode", "1", "Sets method of reset transition data, 1 is clear/save, 2 is cancelrestore.", _, true, 0.0, true, 2.0);
		HookConVarChange(saveresetmode, transitionresetmch);
		saveresetm = GetConVarInt(saveresetmode);
	}
	CloseHandle(saveresetmode);
	hCVbDelTransitionPly = FindConVar("sm_transition_rmply");
	if (hCVbDelTransitionPly == INVALID_HANDLE) hCVbDelTransitionPly = CreateConVar("sm_transition_rmply", "0", "Remove player entities over map change. May increase stability.", _, true, 0.0, true, 1.0);
	hCVbDelTransitionEnts = FindConVar("sm_transition_rments");
	if (hCVbDelTransitionEnts == INVALID_HANDLE) hCVbDelTransitionEnts = CreateConVar("sm_transition_rments", "1", "Remove transition ents after store.", _, true, 0.0, true, 1.0);
	hCVLandMarkBox = FindConVar("sm_transition_landmark_usebounds");
	if (hCVLandMarkBox == INVALID_HANDLE) hCVLandMarkBox = CreateConVar("sm_transition_landmark_usebounds", "1", "Transition entities in a bounding box around the info_landmark.", _, true, 0.0, true, 1.0);
	hCVLandMarkBoxSize = FindConVar("sm_transition_landmark_boundsize");
	if (hCVLandMarkBoxSize == INVALID_HANDLE) hCVLandMarkBoxSize = CreateConVar("sm_transition_landmark_boundsize", "200.0", "info_landmark transition bounding box scale size.", _, true, 5.0, true, 1000.0);
	hCVbTransitionGlobals = FindConVar("sm_transition_globals");
	if (hCVbTransitionGlobals == INVALID_HANDLE) hCVbTransitionGlobals = CreateConVar("sm_transition_globals", "0", "Transtition global states might not work for every mod.", _, true, 0.0, true, 1.0);
	RegServerCmd("changelevel",resettransition);
	iWeaponListOffset = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	AutoExecConfig(true, "synsaverestore");
	char gamename[64];
	GetGameFolderName(gamename,sizeof(gamename));
	if (StrEqual(gamename,"bms",false)) BMActive = true;
	else BMActive = false;
	if ((FileExists("../bin/engine_srv.so",false)) && (FileExists("bin/server_srv.so",false)) && (FileExists("addons/metamod/bin/server.so",false)))
	{
		bLinuxAct = true;
	}
	else bLinuxAct = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	if (StrEqual(name,"SynFixes",false))
	{
		SynFixesRunning = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name,"SynFixes",false))
	{
		SynFixesRunning = false;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("GetCustomEntList");
	MarkNativeAsOptional("SynFixesReadCache");
}

public int Updater_OnPluginUpdated()
{
	if (g_hTimeout == INVALID_HANDLE)
	{
		Handle nullpl = INVALID_HANDLE;
		ReloadPlugin(nullpl);
	}
	else
	{
		reloadaftersetup = true;
	}
}

public void disabletransitionch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) >= 2)
	{
		if (StringToInt(newValue) == 3) bNoDelete = true;
		else bNoDelete = false;
		bRebuildTransition = true;
		bTransitionPlayers = true;
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
	}
	else if (StringToInt(newValue) == 1)
	{
		bRebuildTransition = true;
		bNoDelete = false;
		bTransitionPlayers = false;
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
	}
	else if (StringToInt(newValue) == 0)
	{
		bRebuildTransition = false;
		bNoDelete = true;
		bTransitionPlayers = false;
	}
}

public void transitionresetmch(Handle convar, const char[] oldValue, const char[] newValue)
{
	saveresetm = StringToInt(newValue);
	if (GetMapHistorySize() > -1)
	{
		if ((IsValidEntity(logsv)) && (logsv != 0)) AcceptEntityInput(logsv, "kill");
		if (saveresetm == 1) logsv = CreateEntityByName("logic_autosave");
		else if (saveresetm == 2) logsv = CreateEntityByName("logic_playerproxy");
	}
}

public Action votereloadchk(int client, int args)
{
	Handle panel = CreatePanel();
	SetPanelTitle(panel, "Reload Type");
	DrawPanelItem(panel, "Reload Map");
	DrawPanelItem(panel, "Reload Checkpoint");
	DrawPanelItem(panel, "Create Persistent Save");
	DrawPanelItem(panel, "Close");
	SendPanelToClient(panel, client, PanelHandlervotetype, 20);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action votereloadmap(int client, int args)
{
	Menu menu = new Menu(MenuHandlervote);
	menu.SetTitle("Reload Current Map");
	menu.AddItem("map","Start Vote");
	menu.AddItem("back","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action votereload(int client, int args)
{
	Menu menu = new Menu(MenuHandlervote);
	menu.SetTitle("Reload Checkpoint");
	bool bAddCur = false;
	if (strlen(savedir) > 1)
	{
		char curmapchk[128];
		//Format(curmapchk,sizeof(curmapchk),"%s/%s.hl2",savedir,mapbuf);
		Format(curmapchk,sizeof(curmapchk),"%s/autosave.hl1",savedir);
		if (FileExists(curmapchk))
		{
			if (FileSize(curmapchk) > 15)
				bAddCur = true;
		}
	}
	else bAddCur = true;
	if (bAddCur) menu.AddItem("checkpoint","The current last checkpoint");
	else menu.AddItem("checkpoint","The current last checkpoint",ITEMDRAW_DISABLED);
	if (hCVbVoteReloadSaves.BoolValue)
	{
		char savepath[256];
		BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
		Handle savedirh = OpenDirectory(savepath, false);
		if (savedirh != INVALID_HANDLE)
		{
			char subfilen[64];
			char fullist[512];
			while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
			{
				if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
				{
					if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
					{
						if (client == 0) Format(fullist,sizeof(fullist),"%s\n%s",fullist,subfilen);
						menu.AddItem(subfilen,subfilen);
					}
				}
			}
		}
		CloseHandle(savedirh);
	}
	menu.AddItem("back","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action votecreatesave(int client, int args)
{
	if (hCVbVoteCreateSaves.BoolValue)
	{
		Menu menu = new Menu(MenuHandlervote);
		menu.SetTitle("Create Save of Current Game");
		menu.AddItem("createsave","Start Vote");
		menu.AddItem("back","Back");
		menu.ExitButton = true;
		menu.Display(client, 120);
	}
	else
	{
		PrintToChat(client,"%T","Cannot participate in vote",client);
		votereloadchk(client,0);
	}
	return Plugin_Handled;
}

public Action savecurgame(int client, int args)
{
	if (GetArraySize(g_hEquipEnts) > 0)
	{
		for (int j; j<GetArraySize(g_hEquipEnts); j++)
		{
			int jtmp = GetArrayCell(g_hEquipEnts, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
	if (IsValidEntity(logsv))
	{
		char szCls[32];
		GetEntityClassname(logsv,szCls,sizeof(szCls));
		if (!StrEqual(szCls,"logic_autosave",false))
		{
			logsv = CreateEntityByName("logic_autosave");
			if ((logsv != -1) && (IsValidEntity(logsv)))
			{
				DispatchSpawn(logsv);
				ActivateEntity(logsv);
				saveresetveh(false);
			}
		}
		else saveresetveh(false);
	}
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
	if (!DirExists(savepath)) CreateDirectory(savepath,511);
	Handle data;
	data = CreateDataPack();
	WritePackCell(data, client);
	char h[128];
	if (args > 0)
	{
		char fchk[256];
		GetCmdArgString(h,sizeof(h));
		char ctimestamp[32];
		Format(ctimestamp,sizeof(ctimestamp),h);
		ReplaceString(ctimestamp,sizeof(ctimestamp),"savegame","");
		ReplaceString(ctimestamp,sizeof(ctimestamp),"/","");
		ReplaceString(ctimestamp,sizeof(ctimestamp),"\\","");
		Format(fchk,sizeof(fchk),"%s/%s",savepath,ctimestamp);
		if (DirExists(fchk))
		{
			if (client == 0) PrintToServer("Save already exists with name: %s",ctimestamp);
			else PrintToChat(client,"Save already exists with name: %s",ctimestamp);
			return Plugin_Handled;
		}
	}
	WritePackCell(data, args);
	WritePackString(data, h);
	//Slight delay for open/active files
	CreateTimer(0.5,savecurgamedp,data);
	if (client == 0) PrintToServer("Saving...");
	else PrintToChat(client,"Saving...");
	return Plugin_Handled;
}

public Action savecurgamedp(Handle timer, any dp)
{
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int args = ReadPackCell(dp);
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
	if (!DirExists(savepath)) CreateDirectory(savepath,511);
	char ctimestamp[32];
	char fchk[256];
	if (args < 1)
	{
		FormatTime(ctimestamp,sizeof(ctimestamp),NULL_STRING);
		ReplaceString(ctimestamp,sizeof(ctimestamp),"/","");
		ReplaceString(ctimestamp,sizeof(ctimestamp),"-","");
		ReplaceString(ctimestamp,sizeof(ctimestamp),":","");
	}
	else if (args > 0)
	{
		ReadPackString(dp,ctimestamp,sizeof(ctimestamp));
		ReplaceString(ctimestamp,sizeof(ctimestamp),"savegame","");
		ReplaceString(ctimestamp,sizeof(ctimestamp),"/","");
		ReplaceString(ctimestamp,sizeof(ctimestamp),"\\","");
		Format(fchk,sizeof(fchk),"%s/%s",savepath,ctimestamp);
		if (DirExists(fchk))
		{
			if (client == 0) PrintToServer("Save already exists with name: %s",ctimestamp);
			else PrintToChat(client,"Save already exists with name: %s",ctimestamp);
			CloseHandle(dp);
			return Plugin_Handled;
		}
	}
	CloseHandle(dp);
	Format(fchk,sizeof(fchk),"%s\\%s",savepath,ctimestamp);
	if (!DirExists(fchk)) CreateDirectory(fchk,511);
	char nullb[2];
	//BuildPath(Path_SM,nullb,sizeof(nullb),"data/SynSaves/%s/%s/playerinfo.txt",mapbuf,ctimestamp);
	char plyinffile[256];
	Format(plyinffile,sizeof(plyinffile),"%s\\%s\\playerinfo.txt",savepath,ctimestamp);
	//Format(plyinffile,sizeof(plyinffile),"%s\\playerinfo.txt",savedir);
	ReplaceString(plyinffile,sizeof(plyinffile),"/","\\");
	Handle plyinf = OpenFile(plyinffile,"w");
	char SteamID[32];
	float plyangs[3];
	float plyorigin[3];
	int iScore, iFrags, iDeaths;
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsValidEntity(i)) && (IsClientInGame(i)))
		{
			GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
			if ((strlen(SteamID) < 1) || (StrEqual(SteamID,"STEAM_ID_STOP_IGNORING_RETVALS",false)))
			{
				if (HasEntProp(i,Prop_Data,"m_szNetworkIDString"))
				{
					char searchid[64];
					GetEntPropString(i,Prop_Data,"m_szNetworkIDString",searchid,sizeof(searchid));
					if (strlen(searchid) > 1)
					{
						char Err[100];
						Handle Handle_IDSDB = SQLite_UseDatabase("sourcemod-local",Err,100-1);
						if (!iCreatedTable)
						{
							if (!SQL_FastQuery(Handle_IDSDB,"CREATE TABLE IF NOT EXISTS synbackupids(SteamID VARCHAR(32) NOT NULL PRIMARY KEY,UUID VARCHAR(64) NOT NULL);"))
							{
								PrintToServer("Error in create IDSBackup %s",Err);
								iCreatedTable = 2;
							}
							else iCreatedTable = 1;
						}
						if (iCreatedTable == 1)
						{
							char Querychk[100];
							Format(Querychk,100,"SELECT SteamID FROM synbackupids WHERE UUID = '%s';",searchid);
							Handle HQuery = SQL_Query(Handle_IDSDB,Querychk);
							if (HQuery != INVALID_HANDLE)
							{
								if (SQL_FetchRow(HQuery))
								{
									SQL_FetchString(HQuery,0,SteamID,sizeof(SteamID));
								}
							}
							CloseHandle(HQuery);
						}
						CloseHandle(Handle_IDSDB);
					}
				}
			}
			//GetClientAbsAngles(i,plyangs);
			//GetClientAbsOrigin(i,plyorigin);
			if (IsPlayerAlive(i))
			{
				if (HasEntProp(i, Prop_Data, "m_vecAbsOrigin")) GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", plyorigin);
				else if (HasEntProp(i, Prop_Send, "m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin", plyorigin);
				if (HasEntProp(i, Prop_Data, "v_angle")) GetEntPropVector(i, Prop_Data, "v_angle", plyangs);
				else if (HasEntProp(i, Prop_Data, "m_angRotation")) GetEntPropVector(i, Prop_Data, "m_angRotation", plyangs);
				int vck = GetEntPropEnt(i, Prop_Data, "m_hVehicle");
				if (vck > 0) plyorigin[2]+=60.0;
			}
			char curweap[64];
			char weapname[64];
			char ammbufchk[500];
			GetClientWeaponAccurate(i,curweap,sizeof(curweap));
			if (strlen(curweap) < 1) Format(curweap,sizeof(curweap),"hands");
			for (int j = 0;j<32;j++)
			{
				int ammchk = GetEntProp(i, Prop_Send, "m_iAmmo", _, j);
				if (ammchk > 0)
				{
					Format(ammbufchk,sizeof(ammbufchk),"%s%i %i ",ammbufchk,j,ammchk);
				}
			}
			if (iWeaponListOffset != -1)
			{
				for (int j; j<104; j += 4)
				{
					int tmpi = GetEntDataEnt2(i,iWeaponListOffset + j);
					if (tmpi != -1)
					{
						GetEntityClassname(tmpi,weapname,sizeof(weapname));
						Format(ammbufchk,sizeof(ammbufchk),"%s%s %i ",ammbufchk,weapname,GetEntProp(tmpi,Prop_Data,"m_iClip1"));
					}
				}
			}
			int curh = GetEntProp(i,Prop_Data,"m_iHealth");
			int cura = GetEntProp(i,Prop_Data,"m_ArmorValue");
			int medkitamm = 0;
			if (HasEntProp(i,Prop_Data,"m_iHealthPack")) medkitamm = GetEntProp(i,Prop_Send,"m_iHealthPack");
			int crouching = GetEntProp(i,Prop_Send,"m_bDucked");
			int suitset = GetEntProp(i,Prop_Send,"m_bWearingSuit");
			if (HasEntProp(i,Prop_Data,"m_iPoints")) iScore = GetEntProp(i,Prop_Data,"m_iPoints");
			iFrags = GetEntProp(i,Prop_Data,"m_iFrags");
			iDeaths = GetEntProp(i,Prop_Data,"m_iDeaths");
			char push[564];
			Format(push,sizeof(push),"%s,%1.f %1.f %1.f,%1.f %1.f %1.f,%s,%i %i %i %i %i %i %i %i,%s",SteamID,plyangs[0],plyangs[1],plyangs[2],plyorigin[0],plyorigin[1],plyorigin[2],curweap,curh,cura,medkitamm,crouching,suitset,iScore,iFrags,iDeaths,ammbufchk);
			WriteFileLine(plyinf,push);
		}
	}
	CloseHandle(plyinf);
	char custentinffile[256];
	Format(custentinffile,sizeof(custentinffile),"%s\\%s\\customentinf.txt",savepath,ctimestamp);
	ReplaceString(custentinffile,sizeof(custentinffile),"/","\\");
	if (SynFixesRunning)
	{
		Handle custentlist = GetCustomEntList();
		if (custentlist != INVALID_HANDLE)
		{
			Handle custentinf = OpenFile(custentinffile,"w");
			Handle arr = CreateArray(256);
			FindAllByClassname(arr,-1,"logic_*");
			int maxpass = GetMaxEntities();
			bool usearr = false;
			bool saveafter = false;
			if (GetArraySize(arr) > 0) maxpass++;
			for (int j = MaxClients+1;j<maxpass;j++)
			{
				int i = j;
				if (i == GetMaxEntities())
				{
					j = 0;
					i = GetArrayCell(arr,0);
					maxpass = GetArraySize(arr);
					usearr = true;
				}
				else if (usearr)
				{
					i = GetArrayCell(arr,j);
				}
				if (IsValidEntity(i))
				{
					char cls[64];
					GetEntityClassname(i,cls,sizeof(cls));
					if (StrEqual(cls,"logic_merchant_relay",false))
					{
						//Let default save system handle this entitiy for outputs.
						Format(cls,sizeof(cls),"logic_relay");
						SetEntPropString(i,Prop_Data,"m_iClassname",cls);
						saveafter = true;
					}
					if (FindStringInArray(custentlist,cls) != -1)
					{
						WriteFileLine(custentinf,"{");
						char szTargetname[32];
						char mdl[64];
						float vecOrigin[3];
						float angs[3];
						float flSpeed = 0.0;
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",vecOrigin);
						else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",vecOrigin);
						GetEntPropString(i,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
						char vehscript[64];
						char additionalequip[32];
						char spawnercls[64];
						char szChildSpawnTargetname[64];
						char parentname[32];
						char npctarg[4];
						char npctargpath[32];
						char defanim[32];
						char response[64];
						int iDoorState, iSleepState, sequence, parentattach, body, maxh, curh, sf, hdw, skin, state, npctype, invulnerable;
						if (HasEntProp(i,Prop_Data,"m_iHealth")) curh = GetEntProp(i,Prop_Data,"m_iHealth");
						if (HasEntProp(i,Prop_Data,"m_iMaxHealth")) maxh = GetEntProp(i,Prop_Data,"m_iMaxHealth");
						if (HasEntProp(i,Prop_Data,"m_ModelName")) GetEntPropString(i,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if (HasEntProp(i,Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",angs);
						if (HasEntProp(i,Prop_Data,"m_vehicleScript")) GetEntPropString(i,Prop_Data,"m_vehicleScript",vehscript,sizeof(vehscript));
						if (HasEntProp(i,Prop_Data,"m_spawnEquipment")) GetEntPropString(i,Prop_Data,"m_spawnEquipment",additionalequip,sizeof(additionalequip));
						if (HasEntProp(i,Prop_Data,"m_iszResponseContext")) GetEntPropString(i,Prop_Data,"m_iszResponseContext",response,sizeof(response));
						if (HasEntProp(i,Prop_Data,"m_spawnflags"))
						{
							sf = GetEntProp(i,Prop_Data,"m_spawnflags");
						}
						if (HasEntProp(i,Prop_Data,"m_nSkin"))
						{
							skin = GetEntProp(i,Prop_Data,"m_nSkin");
						}
						if (HasEntProp(i,Prop_Data,"m_nHardwareType"))
						{
							hdw = GetEntProp(i,Prop_Data,"m_nHardwareType");
						}
						if (HasEntProp(i,Prop_Data,"m_state"))
						{
							state = GetEntProp(i,Prop_Data,"m_state");
						}
						if (HasEntProp(i,Prop_Data,"m_hParent"))
						{
							int parchk = GetEntPropEnt(i,Prop_Data,"m_hParent");
							if (IsValidEntity(parchk))
							{
								if (HasEntProp(parchk,Prop_Data,"m_iName")) GetEntPropString(parchk,Prop_Data,"m_iName",parentname,sizeof(parentname));
							}
						}
						if (HasEntProp(i,Prop_Data,"m_eDoorState")) iDoorState = GetEntProp(i,Prop_Data,"m_eDoorState");
						if (HasEntProp(i,Prop_Data,"m_SleepState")) iSleepState = GetEntProp(i,Prop_Data,"m_SleepState");
						else iSleepState = -10;
						if (HasEntProp(i,Prop_Data,"m_Type"))
						{
							npctype = GetEntProp(i,Prop_Data,"m_Type");
						}
						if (HasEntProp(i,Prop_Data,"m_hTargetEnt"))
						{
							int targent = GetEntPropEnt(i,Prop_Data,"m_hTargetEnt");
							if ((IsValidEntity(targent)) && (IsEntNetworkable(targent)))
							{
								if (HasEntProp(targent,Prop_Data,"m_iName")) GetEntPropString(targent,Prop_Data,"m_iName",npctarg,sizeof(npctarg));
								if (strlen(npctarg) < 1) Format(npctarg,sizeof(npctarg),"%i",targent);
							}
						}
						if (HasEntProp(i,Prop_Data,"m_target"))
						{
							PropFieldType type;
							FindDataMapInfo(i,"m_target",type);
							if (type == PropField_String)
							{
								GetEntPropString(i,Prop_Data,"m_target",npctargpath,sizeof(npctargpath));
							}
							else if ((type == PropField_Entity) && (strlen(npctarg) < 1))
							{
								int targent = GetEntPropEnt(i,Prop_Data,"m_target");
								if (targent != -1) Format(npctarg,sizeof(npctarg),"%i",targent);
							}
							if ((strlen(npctargpath) < 1) && (HasEntProp(i,Prop_Data,"m_vecDesiredPosition")))
							{
								float findtargetpos[3];
								GetEntPropVector(i,Prop_Data,"m_vecDesiredPosition",findtargetpos);
								char findpath[128];
								findpathtrack(-1,findtargetpos,findpath);
								if (strlen(findpath) > 0) Format(npctargpath,sizeof(npctargpath),"%s",findpath);
							}
						}
						if (HasEntProp(i,Prop_Data,"m_iszNPCClassname")) GetEntPropString(i,Prop_Data,"m_iszNPCClassname",spawnercls,sizeof(spawnercls));
						if (HasEntProp(i,Prop_Data,"m_ChildTargetName")) GetEntPropString(i,Prop_Data,"m_ChildTargetName",szChildSpawnTargetname,sizeof(szChildSpawnTargetname));
						if (HasEntProp(i,Prop_Data,"m_nSequence")) sequence = GetEntProp(i,Prop_Data,"m_nSequence");
						if (HasEntProp(i,Prop_Data,"m_iParentAttachment")) parentattach = GetEntProp(i,Prop_Data,"m_iParentAttachment");
						if (HasEntProp(i,Prop_Data,"m_nBody")) body = GetEntProp(i,Prop_Data,"m_nBody");
						if (HasEntProp(i,Prop_Data,"m_iszDefaultAnim")) GetEntPropString(i,Prop_Data,"m_iszDefaultAnim",defanim,sizeof(defanim));
						if (HasEntProp(i,Prop_Data,"m_flSpeed")) flSpeed = GetEntPropFloat(i,Prop_Data,"m_flSpeed");
						if (HasEntProp(i,Prop_Data,"m_bInvulnerable")) invulnerable = GetEntProp(i,Prop_Data,"m_bInvulnerable");
						char pushch[256];
						Format(pushch,sizeof(pushch),"\"origin\" \"%f %f %f\"",vecOrigin[0],vecOrigin[1],vecOrigin[2]);
						WriteFileLine(custentinf,pushch);
						Format(pushch,sizeof(pushch),"\"angles\" \"%f %f %f\"",angs[0],angs[1],angs[2]);
						WriteFileLine(custentinf,pushch);
						if (strlen(vehscript) > 0)
						{
							Format(pushch,sizeof(pushch),"\"vehiclescript\" \"%s\"",vehscript);
							WriteFileLine(custentinf,pushch);
						}
						Format(pushch,sizeof(pushch),"\"spawnflags\" \"%i\"",sf);
						WriteFileLine(custentinf,pushch);
						if (strlen(szTargetname) > 0)
						{
							Format(pushch,sizeof(pushch),"\"targetname\" \"%s\"",szTargetname);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(mdl) > 0)
						{
							Format(pushch,sizeof(pushch),"\"model\" \"%s\"",mdl);
							WriteFileLine(custentinf,pushch);
						}
						if (iSleepState != -10)
						{
							Format(pushch,sizeof(pushch),"\"sleepstate\" \"%i\"",iSleepState);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(additionalequip) > 0)
						{
							Format(pushch,sizeof(pushch),"\"additionalequipment\" \"%s\"",additionalequip);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(parentname) > 0)
						{
							Format(pushch,sizeof(pushch),"\"parentname\" \"%s\"",parentname);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(npctarg) > 0)
						{
							Format(pushch,sizeof(pushch),"\"targetentity\" \"%s\"",npctarg);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(npctargpath) > 0)
						{
							Format(pushch,sizeof(pushch),"\"target\" \"%s\"",npctargpath);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(defanim) > 0)
						{
							Format(pushch,sizeof(pushch),"\"DefaultAnim\" \"%s\"",defanim);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(spawnercls) > 0)
						{
							Format(pushch,sizeof(pushch),"\"NPCType\" \"%s\"",spawnercls);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(szChildSpawnTargetname) > 0)
						{
							Format(pushch,sizeof(pushch),"\"NPCTargetname\" \"%s\"",szChildSpawnTargetname);
							WriteFileLine(custentinf,pushch);
						}
						if (curh != 0)
						{
							Format(pushch,sizeof(pushch),"\"health\" \"%i\"",curh);
							WriteFileLine(custentinf,pushch);
						}
						if (maxh != 0)
						{
							Format(pushch,sizeof(pushch),"\"max_health\" \"%i\"",maxh);
							WriteFileLine(custentinf,pushch);
						}
						if (invulnerable != 0)
						{
							Format(pushch,sizeof(pushch),"\"invulnerable\" \"%i\"",invulnerable);
							WriteFileLine(custentinf,pushch);
						}
						if (skin != 0)
						{
							Format(pushch,sizeof(pushch),"\"skin\" \"%i\"",skin);
							WriteFileLine(custentinf,pushch);
						}
						if (hdw != 0)
						{
							Format(pushch,sizeof(pushch),"\"hardware\" \"%i\"",hdw);
							WriteFileLine(custentinf,pushch);
						}
						if (state != 0)
						{
							Format(pushch,sizeof(pushch),"\"npcstate\" \"%i\"",state);
							WriteFileLine(custentinf,pushch);
						}
						if (npctype != 0)
						{
							Format(pushch,sizeof(pushch),"\"citizentype\" \"%i\"",npctype);
							WriteFileLine(custentinf,pushch);
						}
						if (iDoorState != 0)
						{
							Format(pushch,sizeof(pushch),"\"doorstate\" \"%i\"",iDoorState);
							WriteFileLine(custentinf,pushch);
						}
						if (sequence != 0)
						{
							Format(pushch,sizeof(pushch),"\"sequence\" \"%i\"",sequence);
							WriteFileLine(custentinf,pushch);
						}
						if (parentattach != 0)
						{
							Format(pushch,sizeof(pushch),"\"parentattachment\" \"%i\"",parentattach);
							WriteFileLine(custentinf,pushch);
						}
						if (body != 0)
						{
							Format(pushch,sizeof(pushch),"\"body\" \"%i\"",body);
							WriteFileLine(custentinf,pushch);
						}
						if (flSpeed > 0.0)
						{
							Format(pushch,sizeof(pushch),"\"speed\" \"%1.f\"",flSpeed);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(response) > 0)
						{
							Format(pushch,sizeof(pushch),"\"ResponseContext\" \"%s\"",response);
							WriteFileLine(custentinf,pushch);
						}
						Format(pushch,sizeof(pushch),"\"classname\" \"%s\"",cls);
						WriteFileLine(custentinf,pushch);
						WriteFileLine(custentinf,"}");
					}
				}
			}
			CloseHandle(arr);
			CloseHandle(custentinf);
			CloseHandle(custentlist);
			if (saveafter)
			{
				if ((logsv != 0) && (logsv != -1) && (IsValidEntity(logsv)))
				{
					saveresetveh(false);
				}
				else
				{
					if (saveresetm == 1) logsv = CreateEntityByName("logic_autosave");
					else if (saveresetm == 2) logsv = CreateEntityByName("logic_playerproxy");
					if ((logsv != -1) && (IsValidEntity(logsv)))
					{
						DispatchKeyValue(logsv,"NewLevelUnit","1");
						DispatchSpawn(logsv);
						ActivateEntity(logsv);
						saveresetveh(false);
					}
				}
			}
		}
		else CloseHandle(custentlist);
	}
	if (strlen(savedir) > 0)
	{
		if (DirExists(savedir,false))
		{
			Handle savedirh = OpenDirectory(savedir, false);
			char subfilen[64];
			while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
			{
				if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
				{
					if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
					{
						Format(subfilen,sizeof(subfilen),"%s\\%s",savedir,subfilen);
						Handle subfile = OpenFile(subfilen,"rb");
						if (subfile != INVALID_HANDLE)
						{
							char savepathsf[256];
							Format(savepathsf,sizeof(savepathsf),subfilen);
							ReplaceString(savepathsf,sizeof(savepathsf),savedir,"");
							ReplaceString(savepathsf,sizeof(savepathsf),"\\","");
							BuildPath(Path_SM,nullb,sizeof(nullb),"data/SynSaves/%s/%s/%s",mapbuf,ctimestamp,savepathsf);
							Format(savepathsf,sizeof(savepathsf),"%s/%s/%s",savepath,ctimestamp,savepathsf);
							ReplaceString(savepathsf,sizeof(savepathsf),"/","\\");
							Handle subfiletarg = OpenFile(savepathsf,"wb");
							if (subfiletarg != INVALID_HANDLE)
							{
								int itemarr[32];
								while (!IsEndOfFile(subfile))
								{
									ReadFile(subfile,itemarr,32,1);
									WriteFile(subfiletarg,itemarr,32,1);
								}
							}
							CloseHandle(subfiletarg);
						}
						CloseHandle(subfile);
					}
				}
			}
			CloseHandle(savedirh);
		}
	}
	if (DirExists(fchk))
	{
		if (client == 0) PrintToServer("Save created with name: %s",ctimestamp);
		else PrintToChat(client,"Save created with name: %s",ctimestamp);
	}
	return Plugin_Handled;
}

void GetClientWeaponAccurate(int client, char[] szRetBuf, int iSizeBuf)
{
	if (IsValidEntity(client))
	{
		if (HasEntProp(client,Prop_Data,"m_hActiveWeapon"))
		{
			int iWeapon = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(iWeapon))
			{
				if (HasEntProp(iWeapon,Prop_Data,"m_iClassname"))
					GetEntPropString(iWeapon,Prop_Data,"m_iClassname",szRetBuf,iSizeBuf);
				else
					GetEntityClassname(iWeapon,szRetBuf,iSizeBuf);
			}
		}
	}
}

void FindAllByClassname(Handle arr, int ent, char[] classname)
{
	int thisent = FindEntityByClassname(ent,classname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		PushArrayCell(arr,thisent);
		FindAllByClassname(arr,thisent++,classname);
	}
}

void findpathtrack(int ent, float pathorigin[3], char[] findpathname)
{
	int thisent = FindEntityByClassname(ent,"path_track");
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		float orgs[3];
		if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",orgs);
		else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",orgs);
		char orgsch[32];
		char pathorgs[32];
		Format(orgsch,sizeof(orgsch),"%1.f %1.f %1.f",orgs[0],orgs[1],orgs[2]);
		Format(pathorgs,sizeof(pathorgs),"%1.f %1.f %1.f",pathorigin[0],pathorigin[1],pathorigin[2]);
		if (StrEqual(orgsch,pathorgs))
		{
			char szTargetname[128];
			GetEntPropString(thisent,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
			Format(findpathname,128,"%s",szTargetname);
		}
		else findpathtrack(thisent++,pathorigin,findpathname);
	}
}

public Action loadgame(int client, int args)
{
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("Load Game");
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
	Handle savedirh = OpenDirectory(savepath, false);
	if (savedirh == INVALID_HANDLE)
	{
		if (client == 0) PrintToServer("Could not find any save games for this map.");
		else PrintToChat(client,"Could not find any save games for this map.");
		return Plugin_Handled;
	}
	char subfilen[64];
	char fullist[512];
	bool foundsaves = false;
	while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
	{
		if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
		{
			if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
			{
				if (client == 0) Format(fullist,sizeof(fullist),"%s\n%s",fullist,subfilen);
				menu.AddItem(subfilen,subfilen);
				foundsaves = true;
			}
		}
	}
	if (!foundsaves)
	{
		delete menu;
		if (client == 0) PrintToServer("Could not find any save games for this map.");
		else PrintToChat(client,"Could not find any saves for this map.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		delete menu;
		if (args == 0) PrintToServer(fullist);
		else
		{
			char h[256];
			GetCmdArgString(h,sizeof(h));
			loadthissave(h);
		}
		return Plugin_Handled;
	}
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		loadthissave(info);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlerDelSaves(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		DeleteThisSave(info,param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void loadthissave(char[] info)
{
	// This is to fix loading a save too early and all entities are deleted
	int iForceSave = CreateEntityByName("logic_autosave");
	if (IsValidEntity(iForceSave))
	{
		DispatchSpawn(iForceSave);
		ActivateEntity(iForceSave);
		AcceptEntityInput(iForceSave, "Save");
	}
	Handle dp = CreateDataPack();
	WritePackString(dp, info);
	CreateTimer(0.1, LoadSaveDelay, dp);
	return;
}

public Action LoadSaveDelay(Handle timer, Handle hLoadDP)
{
	if (hLoadDP == INVALID_HANDLE) return Plugin_Handled;
	ResetPack(hLoadDP);
	char info[256];
	ReadPackString(hLoadDP, info, sizeof(info));
	CloseHandle(hLoadDP);
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s/%s",mapbuf,info);
	if (DirExists(savepath,false))
	{
		Handle savedirh = OpenDirectory(savepath, false);
		char subfilen[256];
		while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
		{
			if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
			{
				if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)) && (!StrEqual(subfilen,"playerinfo.txt",false)))
				{
					char subfilensm[256];
					Format(subfilensm,sizeof(subfilensm),"%s\\%s",savepath,subfilen);
					Handle subfile = OpenFile(subfilensm,"rb");
					if (subfile != INVALID_HANDLE)
					{
						char savepathsf[128];
						Format(savepathsf,sizeof(savepathsf),"%s\\%s",savedir,subfilen);
						Handle subfiletarg = OpenFile(savepathsf,"wb");
						if (subfiletarg != INVALID_HANDLE)
						{
							int itemarr[32];
							while (!IsEndOfFile(subfile))
							{
								ReadFile(subfile,itemarr,32,1);
								WriteFile(subfiletarg,itemarr,32,1);
							}
						}
						CloseHandle(subfiletarg);
					}
					CloseHandle(subfile);
				}
			}
		}
		char plyinffile[256];
		Format(plyinffile,sizeof(plyinffile),"%s/playerinfo.txt",savepath,info);
		Handle dp = INVALID_HANDLE;
		if (FileExists(plyinffile,false))
		{
			/*
			dp = CreateDataPack();
			Handle hReloadIDs = CreateArray(128);
			Handle hReloadAngles = CreateArray(128);
			Handle hReloadOrigins = CreateArray(128);
			Handle hReloadAmmoSets = CreateArray(128);
			Handle hReloadStats = CreateArray(128);
			Handle hReloadCurrentWeapon = CreateArray(128);
			*/
			char sets[6][64];
			char statssets[8][24];
			char szWeaponsAmmo[64][384];
			char szTmp[32];
			char line[600];
			Handle plyinf = OpenFile(plyinffile,"r");
			while(!IsEndOfFile(plyinf)&&ReadFileLine(plyinf,line,sizeof(line)))
			{
				TrimString(line);
				if (strlen(line) > 0)
				{
					int adjustarr = 0;
					if (StrContains(line,",",false) != -1)
						ExplodeString(line,",",sets,6,64);
					else
						ExplodeString(line,"b",sets,6,64);
					if (StrEqual(sets[3],"weapon_crow",false))
					{
						adjustarr = 1;
						Format(sets[3],sizeof(sets[]),"%sb%s",sets[3],sets[4]);
					}
					/*
					PushArrayString(hReloadIDs,sets[0]);
					PushArrayString(hReloadAngles,sets[1]);
					PushArrayString(hReloadOrigins,sets[2]);
					PushArrayString(hReloadCurrentWeapon,sets[3]);
					PushArrayString(hReloadStats,sets[4+adjustarr]);
					ReplaceString(line,sizeof(line),sets[0],"");
					ReplaceString(line,sizeof(line),sets[1],"");
					ReplaceString(line,sizeof(line),sets[2],"");
					ReplaceString(line,sizeof(line),sets[3],"");
					ReplaceString(line,sizeof(line),sets[4],"");
					if ((strlen(sets[5]) > 0) && (adjustarr)) ReplaceString(line,sizeof(line),sets[5],"");
					ReplaceString(line,sizeof(line),",,,,,","");
					ReplaceString(line,sizeof(line),"bbb","");
					if (strlen(line) > 1) PushArrayString(hReloadAmmoSets,line);
					*/
					PushArrayString(g_hTransitionIDs,sets[0]);
					dp = CreateDataPack();
					
					ExplodeString(sets[4+adjustarr]," ",statssets,8,24);
					if (StringToInt(statssets[0]) > 0) WritePackCell(dp, StringToInt(statssets[0]));
					else WritePackCell(dp, 100);
					if (StringToInt(statssets[1]) > -1) WritePackCell(dp, StringToInt(statssets[1]));
					else WritePackCell(dp, 0);
					
					if (StrContains(statssets[5], ",", false) == -1)
					{
						WritePackCell(dp,StringToInt(statssets[5]));// score
						WritePackCell(dp,StringToInt(statssets[6]));// frags
						WritePackCell(dp,StringToInt(statssets[7]));// deaths
					}
					else
					{
						WritePackCell(dp, 0);
						WritePackCell(dp, 0);
						WritePackCell(dp, 0);
					}
					
					WritePackCell(dp, StringToInt(statssets[4]));//suit
					WritePackCell(dp, StringToInt(statssets[2]));//healthpack
					WritePackCell(dp, StringToInt(statssets[3]));//duck
					
					ExplodeString(sets[1], " ", statssets, 3, 64);
					WritePackFloat(dp, StringToFloat(statssets[0]));
					WritePackFloat(dp, StringToFloat(statssets[1]));
					
					ExplodeString(sets[2], " ", statssets, 3, 64);
					WritePackFloat(dp, StringToFloat(statssets[0]));
					WritePackFloat(dp, StringToFloat(statssets[1]));
					WritePackFloat(dp, StringToFloat(statssets[2]));
					WritePackString(dp, sets[3]);// Cur weapon
					////////////////////// ammo sets at end of line past ,,,,, || bbb
					
					int iLastSplits = ExplodeString(line, ",", szWeaponsAmmo, 8, 384);
					if (strlen(szWeaponsAmmo[iLastSplits-1]) > 1)
					{
						iLastSplits = ExplodeString(szWeaponsAmmo[iLastSplits-1], " ", szWeaponsAmmo, 64, 32);
						for (int j = 0; j < iLastSplits; j+=2)
						{
							if (j >= iLastSplits) break;
							Format(szTmp, sizeof(szTmp), "%s %s",szWeaponsAmmo[j], szWeaponsAmmo[j+1]);
							WritePackString(dp, szTmp);
						}
					}
					
					WritePackString(dp,"endofpack");
					PushArrayCell(g_hTransitionDataPacks,dp);
				}
			}
			CloseHandle(plyinf);
			/*
			WritePackCell(dp,hReloadIDs);
			WritePackCell(dp,hReloadAngles);
			WritePackCell(dp,hReloadOrigins);
			WritePackCell(dp,hReloadAmmoSets);
			WritePackCell(dp,hReloadStats);
			WritePackCell(dp,hReloadCurrentWeapon);
			WritePackString(dp,sets[3]);
			*/
			
			
		}
		Handle hSavePathPack = CreateDataPack();
		WritePackString(hSavePathPack, savepath);
		CreateTimer(1.0, reloadtimer, hSavePathPack);
		//CreateTimer(1.1, reloadtimersetupcl, dp);
		CreateTimer(1.1, ReloadClientsFromSave);
	}
	return Plugin_Handled;
}

void DeleteThisSave(char[] info, int client)
{
	char saverm[256];
	BuildPath(Path_SM,saverm,sizeof(saverm),"data/SynSaves/%s/%s",mapbuf,info);
	Handle savedirh = OpenDirectory(saverm, false);
	if (savedirh == INVALID_HANDLE)
	{
		if (client == 0) PrintToServer("Save: %s does not exist.",info);
		else PrintToChat(client,"Save: %s does not exist.",info);
		DeleteSave(client,0);
		return;
	}
	char subfilen[256];
	while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
	{
		if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
		{
			if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
			{
				Format(subfilen,sizeof(subfilen),"%s\\%s",saverm,subfilen);
				DeleteFile(subfilen);
			}
		}
	}
	CloseHandle(savedirh);
	RemoveDir(saverm);
	if (DirExists(saverm))
	{
		if (client == 0) PrintToServer("Was unable to remove %s",info);
		else PrintToChat(client,"Was unable to remove %s",info);
	}
	else
	{
		if (client == 0) PrintToServer("Removed save %s",info);
		else PrintToChat(client,"Removed save %s",info);
	}
	DeleteSave(client,0);
	return;
}

public Action reloadtimer(Handle timer, Handle hSavePathPack)
{
	int thereload = CreateEntityByName("player_loadsaved");
	DispatchSpawn(thereload);
	ActivateEntity(thereload);
	AcceptEntityInput(thereload, "Reload");
	if (GetArraySize(g_hEquipEnts) > 0)
	{
		for (int j; j<GetArraySize(g_hEquipEnts); j++)
		{
			int jtmp = GetArrayCell(g_hEquipEnts, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
	if (SynFixesRunning)
	{
		CreateTimer(0.1,reloadentcache,hSavePathPack);
	}
}

public Action reloadentcache(Handle timer, Handle hSavePathPack)
{
	char savepath[256];
	if (hSavePathPack != INVALID_HANDLE)
	{
		ResetPack(hSavePathPack);
		ReadPackString(hSavePathPack,savepath,sizeof(savepath));
		CloseHandle(hSavePathPack);
	}
	char entinffile[256];
	Format(entinffile,sizeof(entinffile),"%s/customentinf.txt",savepath);
	ReplaceString(entinffile,sizeof(entinffile),"\\","/");
	//PrintToServer("loadcache %s",entinffile);
	if (FileExists(entinffile,false))
	{
		float offs[3];
		SynFixesReadCache(0,entinffile,offs);
	}
}

public Action ReloadClientsFromSave(Handle timer)
{
	g_vecLandmarkOrigin[0] = 0.0;
	g_vecLandmarkOrigin[1] = 0.0;
	g_vecLandmarkOrigin[2] = 0.0;
	Format(szLandmarkName, sizeof(szLandmarkName), "syn_savereload");
	
	if (g_hTimeout != INVALID_HANDLE) CloseHandle(g_hTimeout);
	g_hTimeout = CreateTimer(60.0, transitiontimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	
	for (int i = 1; i < MaxClients+1; i++)
	{
		if (IsValidEntity(i))
		{
			if (IsClientConnected(i))
			{
				if (IsClientInGame(i))
				{
					CreateTimer(0.1, anotherdelay, i, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	return Plugin_Handled;
}
/*
public Action reloadtimersetupcl(Handle timer, Handle dp)
{
	if (GetArraySize(g_hEquipEnts) > 0)
	{
		for (int j; j<GetArraySize(g_hEquipEnts); j++)
		{
			int jtmp = GetArrayCell(g_hEquipEnts, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		Handle hReloadIDs = ReadPackCell(dp);
		Handle hReloadAngles = ReadPackCell(dp);
		Handle hReloadOrigins = ReadPackCell(dp);
		Handle hReloadAmmoSets = ReadPackCell(dp);
		Handle hReloadStats = ReadPackCell(dp);
		Handle hReloadCurrentWeapon = ReadPackCell(dp);
		CloseHandle(dp);
		if (GetArraySize(hReloadIDs) > 0)
		{
			float angs[3];
			float origin[3];
			char sets[3][64];
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					char SteamID[32];
					GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
					int arrindx = FindStringInArray(hReloadIDs,SteamID);
					char angch[32];
					char originch[32];
					char ammoch[600];
					char ammosets[64][32];
					char statsch[64];
					char statssets[9][24];
					if (arrindx != -1)
					{
						GetArrayString(hReloadAngles,arrindx,angch,sizeof(angch));
						GetArrayString(hReloadOrigins,arrindx,originch,sizeof(originch));
						if (GetArraySize(hReloadAmmoSets) > 0)
						{
							GetArrayString(hReloadAmmoSets,arrindx,ammoch,sizeof(ammoch));
							ExplodeString(ammoch," ",ammosets,32,32);
							for (int j = 0;j<32;j++)
							{
								int arrplus = j+1;
								if (StrContains(ammosets[j],"weapon_",false) != -1)
								{
									int weapindx = GivePlayerItem(i,ammosets[j]);
									if (weapindx != -1)
									{
										int weapamm = StringToInt(ammosets[arrplus]);
										SetEntProp(weapindx,Prop_Data,"m_iClip1",weapamm);
									}
								}
								else if ((strlen(ammosets[j]) > 0) && (strlen(ammosets[arrplus]) > 0))
								{
									int ammindx = StringToInt(ammosets[j]);
									int ammset = StringToInt(ammosets[arrplus]);
									int maxindexes = GetEntPropArraySize(i,Prop_Send,"m_iAmmo");
									if (ammindx <= maxindexes)
										SetEntProp(i,Prop_Send,"m_iAmmo",ammset,_,ammindx);
								}
								j++;
							}
						}
						if (GetArraySize(hReloadStats) > 0)
						{
							GetArrayString(hReloadStats,arrindx,statsch,sizeof(statsch));
							ExplodeString(statsch," ",statssets,5,24);
							if (StringToInt(statssets[0]) > 0) SetEntProp(i,Prop_Data,"m_iHealth",StringToInt(statssets[0]));
							if (StringToInt(statssets[1]) > -1) SetEntProp(i,Prop_Data,"m_ArmorValue",StringToInt(statssets[1]));
							if (StringToInt(statssets[2]) > -1)
							{
								if (HasEntProp(i,Prop_Data,"m_iHealthPack")) SetEntProp(i,Prop_Send,"m_iHealthPack",StringToInt(statssets[2]));
							}
							if (StringToInt(statssets[3]) > -1) SetEntProp(i,Prop_Send,"m_bDucking",StringToInt(statssets[3]));
							if (StringToInt(statssets[4]) > -1) SetEntProp(i,Prop_Send,"m_bWearingSuit",StringToInt(statssets[4]));
						}
						ExplodeString(angch," ",sets,3,64);
						angs[0] = StringToFloat(sets[0]);
						angs[1] = StringToFloat(sets[1]);
						ExplodeString(originch," ",sets,3,64);
						origin[0] = StringToFloat(sets[0]);
						origin[1] = StringToFloat(sets[1]);
						origin[2] = StringToFloat(sets[2]);
						TeleportEntity(i,origin,angs,NULL_VECTOR);
						char curweap[24];
						if (GetArraySize(hReloadCurrentWeapon) > 0) GetArrayString(hReloadCurrentWeapon,arrindx,curweap,sizeof(curweap));
						if (strlen(curweap) > 0) ClientCommand(i,"use %s",curweap);
					}
					else
					{
						int rand = GetRandomInt(0,GetArraySize(hReloadIDs)-1);
						GetArrayString(hReloadAngles,rand,angch,sizeof(angch));
						GetArrayString(hReloadOrigins,rand,originch,sizeof(originch));
						ExplodeString(angch," ",sets,3,64);
						angs[0] = StringToFloat(sets[0]);
						angs[1] = StringToFloat(sets[1]);
						ExplodeString(originch," ",sets,3,64);
						origin[0] = StringToFloat(sets[0]);
						origin[1] = StringToFloat(sets[1]);
						origin[2] = StringToFloat(sets[2]);
						TeleportEntity(i,origin,angs,NULL_VECTOR);
					}
				}
			}
		}
		CloseHandle(hReloadIDs);
		CloseHandle(hReloadAngles);
		CloseHandle(hReloadOrigins);
		CloseHandle(hReloadAmmoSets);
		CloseHandle(hReloadStats);
		CloseHandle(hReloadCurrentWeapon);
	}
}
*/
public Action DeleteSave(int client, int args)
{
	Menu menu = new Menu(MenuHandlerDelSaves);
	menu.SetTitle("Delete Save");
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
	Handle savedirh = OpenDirectory(savepath, false);
	if (savedirh == INVALID_HANDLE)
	{
		if (client == 0) PrintToServer("Could not find any save games for this map.");
		else PrintToChat(client,"Could not find any save games for this map.");
		return Plugin_Handled;
	}
	char subfilen[64];
	char fullist[512];
	bool foundsaves = false;
	while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
	{
		if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
		{
			if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
			{
				if (client == 0) Format(fullist,sizeof(fullist),"%s\n%s",fullist,subfilen);
				menu.AddItem(subfilen,subfilen);
				foundsaves = true;
			}
		}
	}
	if (!foundsaves)
	{
		delete menu;
		if (client == 0) PrintToServer("Could not find any save games for this map.");
		else PrintToChat(client,"Could not find any saves for this map.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		delete menu;
		if (args == 0) PrintToServer(fullist);
		else
		{
			char h[256];
			GetCmdArgString(h,sizeof(h));
			DeleteThisSave(h,client);
		}
		return Plugin_Handled;
	}
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public int MenuHandlervote(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		float Time = GetTickedTime();
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		static char szDisplayBuffer[64];
		if (StrEqual(info,"back",false))
		{
			votereloadchk(param1,0);
			return 0;
		}
		else if (IsVoteInProgress())
		{
			PrintToChat(param1,"There is a vote already in progress.");
			return 0;
		}
		else if ((StrEqual(info,"map",false)) && (votetime <= Time))
		{
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(szDisplayBuffer,sizeof(szDisplayBuffer),"Reload Current Map?");
			g_hVoteMenu.SetTitle(szDisplayBuffer);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 2;
		}
		else if ((StrEqual(info,"createsave",false)) && (votetime <= Time))
		{
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(szDisplayBuffer,sizeof(szDisplayBuffer),"Create Save Point?");
			g_hVoteMenu.SetTitle(szDisplayBuffer);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 4;
		}
		else if ((StrEqual(info,"checkpoint",false)) && (votetime <= Time))
		{
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(szDisplayBuffer,sizeof(szDisplayBuffer),"Reload Last Checkpoint?");
			g_hVoteMenu.SetTitle(szDisplayBuffer);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 1;
		}
		else if ((strlen(info) > 1) && (strlen(szReloadSaveName) < 1) && (votetime <= Time))
		{
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(szDisplayBuffer,sizeof(szDisplayBuffer),"Reload the %s Save?",info);
			g_hVoteMenu.SetTitle(szDisplayBuffer);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 3;
			Format(szReloadSaveName,sizeof(szReloadSaveName),info);
		}
		else if (votetime > Time)
			PrintToChat(param1,"You must wait %i seconds.",RoundFloat(votetime)-RoundFloat(Time));
		else
			PrintToChat(param1,"A vote is probably in progress");
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int PanelHandlervotetype(Handle menu, MenuAction action, int client, int param1)
{
	if (param1 == 1)
	{
		votereloadmap(client,0);
	}
	else if (param1 == 2)
	{
		votereload(client,0);
	}
	else if (param1 == 3)
	{
		votecreatesave(client,0);
	}
	else if (param1 == 4)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return 0;
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
		//an error occurred somewhere.
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%s", display);

			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[64], display[64];
		float percent;
		int votes, totalVotes;
		float flPercentLimit;
		if (reloadtype == 4) flPercentLimit = hCVflVoteCreateSavePercent.FloatValue;
		else flPercentLimit = hCVflVoteRestorePercent.FloatValue;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes;
		}
		
		percent = float(votes)/float(totalVotes);

		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,flPercentLimit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t","Vote Failed", RoundToNearest(100.0*flPercentLimit), RoundToNearest(100.0*percent), totalVotes);
			Format(szReloadSaveName,sizeof(szReloadSaveName),"");
		}
		else
		{
			PrintToChatAll("%t","Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			if (reloadtype == 1) CreateTimer(0.1,reloadtimer,INVALID_HANDLE);
			else if (reloadtype == 2)
			{
				if (StrEqual(mapbuf,"ep2_outland_02",false))
					enterfrom04 = true;
				if (StrEqual(mapbuf,"d1_town_02",false))
				{
					enterfrom03 = true;
					findtrigs(-1,"func_brush");
				}
				if (StrEqual(mapbuf,"d2_coast_07",false))
					enterfrom08 = true;
				findtrigs(-1,"trigger_hurt");
				//findglobals(-1,"env_global");
				if (enterfrom04)
					enterfrom04pb = true;
				if (enterfrom03)
					enterfrom03pb = true;
				if (enterfrom08)
					enterfrom08pb = true;
				reloadingmap = true;
				CreateTimer(0.6,changelevel);
			}
			else if ((reloadtype == 3) && (strlen(szReloadSaveName) > 0))
			{
				loadthissave(szReloadSaveName);
				Format(szReloadSaveName,sizeof(szReloadSaveName),"");
			}
			else if (reloadtype == 4)
			{
				if (IsValidEntity(logsv))
				{
					char szCls[32];
					GetEntityClassname(logsv,szCls,sizeof(szCls));
					if (!StrEqual(szCls,"logic_autosave",false))
					{
						logsv = CreateEntityByName("logic_autosave");
						if ((logsv != -1) && (IsValidEntity(logsv)))
						{
							DispatchSpawn(logsv);
							ActivateEntity(logsv);
							saveresetveh(false);
						}
					}
					else saveresetveh(false);
				}
				char savepath[256];
				BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
				if (!DirExists(savepath)) CreateDirectory(savepath,511);
				char ctimestamp[32];
				FormatTime(ctimestamp,sizeof(ctimestamp),NULL_STRING);
				ReplaceString(ctimestamp,sizeof(ctimestamp),"/","");
				ReplaceString(ctimestamp,sizeof(ctimestamp),"-","");
				ReplaceString(ctimestamp,sizeof(ctimestamp),":","");
				Handle data;
				data = CreateDataPack();
				WritePackCell(data, 0);
				WritePackCell(data, 2);
				WritePackString(data, ctimestamp);
				//Slight delay for open/active files
				CreateTimer(0.5,savecurgamedp,data);
				PrintToChatAll("Saving game as %s",ctimestamp);
			}
			reloadtype = 0;
		}
	}
	return 0;
}

public void OnMapStart()
{
	flMapStartTime = GetTickedTime()+2.0;
	if (GetMapHistorySize() > -1)
	{
		char gamedescoriginal[24];
		GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
		if ((StrContains(gamedescoriginal,"Synergy",false) == 0) && (StrContains(gamedescoriginal,"56.16",false) == -1)) SynLaterAct = true;
		else SynLaterAct = false;
		GetCurrentMap(mapbuf,sizeof(mapbuf));
		if ((!StrEqual(mapbuf,"d3_citadel_03",false)) && (!StrEqual(mapbuf,"ep2_outland_02",false)))
		{
			logplyprox = -1;
			logplyprox = CreateEntityByName("logic_playerproxy");
			if (logplyprox != -1)
			{
				DispatchKeyValue(logplyprox,"targetname","synplyprox");
				DispatchSpawn(logplyprox);
				ActivateEntity(logplyprox);
				AcceptEntityInput(logplyprox,"CancelRestorePlayers");
			}
		}
		logsv = -1;
		if (saveresetm == 1) logsv = CreateEntityByName("logic_autosave");
		else if (saveresetm == 2) logsv = CreateEntityByName("logic_playerproxy");
		if (IsValidEntity(logsv))
		{
			DispatchKeyValue(logsv,"NewLevelUnit","1");
			DispatchSpawn(logsv);
			ActivateEntity(logsv);
		}
		Handle savedirh = FindConVar("sv_savedir");
		if (savedirh != INVALID_HANDLE)
		{
			GetConVarString(savedirh,savedir,sizeof(savedir));
			if (StrContains(savedir,"\\",false) != -1)
				ReplaceString(savedir,sizeof(savedir),"\\","");
			else if (StrContains(savedir,"/",false) != -1)
				ReplaceString(savedir,sizeof(savedir),"/","");
		}
		else
		{
			Format(savedir,sizeof(savedir),"save");
			if (!DirExists("save",false)) CreateDirectory("save",511);
		}
		CloseHandle(savedirh);
		enterfrom04 = true;
		if (StrContains(mapbuf,"_spymap_ep3",false) != -1)
			findtrigs(-1,"trigger_once");
		if ((StrEqual(mapbuf,"remount",false)) && (enterfromep1))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_reltoep1,kill,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_reltoep2,Enable,,0,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
			enterfromep1 = false;
		}
		else if ((StrEqual(mapbuf,"remount",false)) && (enterfromep2))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_reltoep1,kill,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_reltoep2,kill,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_hudtimer,AddOutput,OnTimer syn_reltohl2:Trigger::0:-1,0,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
			int syn_reltohl2 = CreateEntityByName("logic_relay");
			if (syn_reltohl2 != -1)
			{
				DispatchKeyValue(syn_reltohl2, "targetname","syn_reltohl2");
				DispatchKeyValue(syn_reltohl2, "OnTrigger","syn_ps,Command,changelevel hl2 d1_trainstation_01,0,1");
				DispatchSpawn(syn_reltohl2);
				ActivateEntity(syn_reltohl2);
			}
			enterfromep2 = false;
		}
		else if (StrEqual(mapbuf,"d3_c17_01",false))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","alyx,StartScripting,,1,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		else if (StrEqual(mapbuf,"d3_breen_01",false))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","logic_ending_credits,AddOutput,OnTrigger PSCTest:Command:changelevel remount:29:1,0,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		else if (StrEqual(mapbuf,"ep1_c17_06",false))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","citfx_glowtrack3,AddOutput,OnPass theEndCmd:Command:changelevel remount:7.3:1,0,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		else if ((BMActive) && (StrEqual(mapbuf, "bm_c2a4g", false)))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","trigger_changelevel,Enable,,1,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		else if (StrEqual(mapbuf, "bm_c4a1b", false))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","B_Exit_door,Open,,1,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		else if (StrEqual(mapbuf,"bm_c4a3d1",false))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","elevator_exit_door1,Open,,1,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","elevator_exit_door2,Open,,1,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		if (reloadingmap)
		{
			if ((enterfrom04pb) && (StrEqual(mapbuf,"ep2_outland_02",false)))
			{
				int spawnpos = CreateEntityByName("info_player_coop");
				if (spawnpos != -1)
				{
					DispatchKeyValue(spawnpos, "targetname","syn_spawn_player_3rebuild");
					DispatchKeyValue(spawnpos, "StartDisabled","0");
					DispatchKeyValue(spawnpos, "parentname","elevator");
					float vecOrigin[3];
					vecOrigin[0] = -3106.0;
					vecOrigin[1] = -9455.0;
					vecOrigin[2] = -3077.0;
					TeleportEntity(spawnpos,vecOrigin,NULL_VECTOR,NULL_VECTOR);
					DispatchSpawn(spawnpos);
					ActivateEntity(spawnpos);
					SetVariantString("elevator");
					AcceptEntityInput(spawnpos,"SetParent");
				}
				int loginp = CreateEntityByName("logic_auto");
				if (loginp != -1)
				{
					DispatchKeyValue(loginp, "spawnflags","1");
					DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Enable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Trigger,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,TouchTest,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","info_player_coop,Disable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_player_3rebuild,Enable,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_3rebuild,0.1,-1");
					if (!bLinuxAct)
					{
						// Windows works with this
						DispatchKeyValue(loginp, "OnMapSpawn","debug_choreo_start_in_elevator,Trigger,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","pointTemplate_vortCalvary,ForceSpawn,,1,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","ss_heal_loop,BeginSequence,,1.2,-1");
					}
					else
					{
						//DispatchKeyValue(loginp, "OnMapSpawn","debug_choreo_start_in_elevator,Trigger,,0.4,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort_calvary_1,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort_calvary_2,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort_calvary_actor,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","ss_crouch,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","griggs,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","sheckley,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","alyx,kill,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","start_the_elevator_rl,Enable,,0,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","teleport_player_onto_elevator,Teleport,,0.1,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","griggs_sheckley_template,ForceSpawn,,0.1,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort_template,ForceSpawn,,0.1,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort,StartScripting,,0.2,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","vort_enter_on_elevator_ss_1,BeginSequence,,0.3,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","cheat_extract_template,ForceSpawn,,0.3,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","coming_from_04_scene_setup_2,Trigger,,1,-1");
						DispatchKeyValue(loginp, "OnMapSpawn","alyx_interior,StartScripting,,1.1,-1");
					}
					DispatchSpawn(loginp);
					ActivateEntity(loginp);
					CreateTimer(4.0,TransitionPostAdjust,0,TIMER_FLAG_NO_MAPCHANGE);
				}
				int iEnt = -1;
				char szTargetname[32];
				while((iEnt = FindEntityByClassname(iEnt,"path_track")) != INVALID_ENT_REFERENCE)
				{
					if (IsValidEntity(iEnt))
					{
						if (HasEntProp(iEnt,Prop_Data,"m_iName"))
						{
							GetEntPropString(iEnt,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
							if (StrEqual(szTargetname,"pathTrack_elevator_top4",false))
							{
								HookSingleEntityOutput(iEnt,"OnPass",Ep2ElevatorPass);
								break;
							}
						}
					}
				}
			}
			else if (enterfrom04pb)
				enterfrom04pb = false;
			if (StrEqual(mapbuf,"ep1_c17_00",false))
			{
				int loginp = CreateEntityByName("logic_auto");
				if (loginp != -1)
				{
					DispatchKeyValue(loginp, "spawnflags","1");
					DispatchKeyValue(loginp, "OnMapSpawn","ss_alyx_duckunder,CancelSequence,,4,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","ss_alyx_duckunder,BeginSequence,,5,-1");
					DispatchSpawn(loginp);
					ActivateEntity(loginp);
				}
			}
			if (StrEqual(mapbuf,"d1_canals_09",false))
			{
				int trigtp = CreateEntityByName("trigger_teleport");
				if (trigtp != -1)
				{
					float vecAngles[3];
					int starttp = CreateEntityByName("info_teleport_destination");
					if (starttp != -1)
					{
						DispatchKeyValue(starttp,"targetname","syn_startspawntp");
						float vecOrigin[3];
						vecOrigin[0] = 7737.0;
						vecOrigin[1] = 9744.0;
						vecOrigin[2] = -444.0;
						vecAngles[1] = 90.0;
						TeleportEntity(starttp,vecOrigin,vecAngles,NULL_VECTOR);
						DispatchSpawn(starttp);
						ActivateEntity(starttp);
					}
					DispatchKeyValue(trigtp,"model","*13");
					DispatchKeyValue(trigtp,"spawnflags","1");
					DispatchKeyValue(trigtp,"target","syn_startspawntp");
					float vecOrigin[3];
					vecOrigin[0] = 7735.0;
					vecOrigin[1] = 8150.0;
					vecOrigin[2] = -395.0;
					vecAngles[1] = 90.0;
					TeleportEntity(trigtp,vecOrigin,vecAngles,NULL_VECTOR);
					DispatchSpawn(trigtp);
					ActivateEntity(trigtp);
				}
			}
			if ((enterfrom03pb) && (StrEqual(mapbuf,"d1_town_02",false)))
			{
				findrmstarts(-1,"info_player_start");
				int loginp = CreateEntityByName("logic_auto");
				if (loginp != -1)
				{
					DispatchKeyValue(loginp, "spawnflags","1");
					DispatchKeyValue(loginp, "OnMapSpawn","edt_alley_push,Enable,,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_wall_temp_ally,ForceSpawn,,1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_wall_removeme_temp_t02,ForceSpawn,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_3,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_vint_trav_gman,Kill,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_wall_removeme_t03,Kill,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_vint_stopplayerjump_1,Kill,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_player_1,kill,,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_starttptransition,kill,,30,1");
					DispatchSpawn(loginp);
					ActivateEntity(loginp);
				}
				int trigtpstart = CreateEntityByName("info_teleport_destination");
				if (trigtpstart != -1)
				{
					DispatchKeyValue(trigtpstart,"targetname","syn_transition_dest");
					DispatchKeyValue(trigtpstart,"angles","0 70 0");
					DispatchSpawn(trigtpstart);
					ActivateEntity(trigtpstart);
					float tvecOrigin[3];
					tvecOrigin[0] = -3735.0;
					tvecOrigin[1] = -5.0;
					tvecOrigin[2] = -3440.0;
					TeleportEntity(trigtpstart,tvecOrigin,NULL_VECTOR,NULL_VECTOR);
					trigtpstart = CreateEntityByName("trigger_teleport");
					DispatchKeyValue(trigtpstart,"spawnflags","1");
					DispatchKeyValue(trigtpstart,"targetname","syn_starttptransition");
					DispatchKeyValue(trigtpstart,"model","*1");
					DispatchKeyValue(trigtpstart,"target","syn_transition_dest");
					DispatchSpawn(trigtpstart);
					ActivateEntity(trigtpstart);
					tvecOrigin[0] = -736.0;
					tvecOrigin[1] = 864.0;
					tvecOrigin[2] = -3350.0;
					TeleportEntity(trigtpstart,tvecOrigin,NULL_VECTOR,NULL_VECTOR);
				}
			}
			else if (enterfrom03pb)
				enterfrom03pb = false;
			if ((enterfrom08pb) && (StrEqual(mapbuf,"d2_coast_07",false)))
			{
				if ((bRebuildTransition) && (GetArraySize(g_hTransitionEntities) > 0)) findtransitionback(-1);
				findrmstarts(-1,"info_player_start");
				int loginp = CreateEntityByName("logic_auto");
				if (loginp != -1)
				{
					DispatchKeyValue(loginp, "spawnflags","1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_shiz,Trigger,,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_4,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_player_1,kill,,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","dropship,kill,,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","windmill,kill,,0,1");
					DispatchKeyValue(loginp, "OnMapSpawn","bridge_door_2,Unlock,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","bridge_door_2,Close,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","bridge_door_2,Lock,,0.5,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_starttptransition,kill,,30,1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_antiskip_hurt,Disable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","field_trigger,Disable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","bridge_field_02,Disable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","forcefield3_sound_far,StopSound,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","forcefield3_sound_far,kill,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","field_wall_poles,Skin,1,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","gate_sprite,color,0 255 0,0,1");
					DispatchSpawn(loginp);
					ActivateEntity(loginp);
				}
				int trigtpstart = CreateEntityByName("info_teleport_destination");
				if (trigtpstart != -1)
				{
					DispatchKeyValue(trigtpstart,"targetname","syn_transition_dest");
					DispatchKeyValue(trigtpstart,"angles","0 180 0");
					DispatchSpawn(trigtpstart);
					ActivateEntity(trigtpstart);
					float tvecOrigin[3];
					tvecOrigin[0] = 3200.0;
					tvecOrigin[1] = 5216.0;
					tvecOrigin[2] = 1544.0;
					TeleportEntity(trigtpstart,tvecOrigin,NULL_VECTOR,NULL_VECTOR);
					trigtpstart = CreateEntityByName("trigger_teleport");
					DispatchKeyValue(trigtpstart,"spawnflags","1");
					DispatchKeyValue(trigtpstart,"targetname","syn_starttptransition");
					DispatchKeyValue(trigtpstart,"model","*9");
					DispatchKeyValue(trigtpstart,"target","syn_transition_dest");
					DispatchSpawn(trigtpstart);
					ActivateEntity(trigtpstart);
					tvecOrigin[0] = -7616.0;
					tvecOrigin[1] = 5856.0;
					tvecOrigin[2] = 1601.0;
					TeleportEntity(trigtpstart,tvecOrigin,NULL_VECTOR,NULL_VECTOR);
				}
				CreateTimer(0.1,TransitionPostAdjust,1);
			}
			else if (enterfrom08pb)
				enterfrom08pb = false;
			if ((enterfrom4g) && (StrEqual(mapbuf,"bm_c2a4fedt",false)))
			{
				int loginp = CreateEntityByName("logic_auto");
				if (loginp != -1)
				{
					DispatchKeyValue(loginp, "spawnflags","1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_stragglersfailsave,Enable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawnpoint2_00,0,-1");
					DispatchSpawn(loginp);
					ActivateEntity(loginp);
				}
			}
			else if (enterfrom4g)
				enterfrom4g = false;
			findprevlvls(-1);
			reloadingmap = false;
		}
		ClearArray(g_hEquipEnts);
		ClearArray(g_hIgnoredEntities);
		bIsVehicleMap = findvmap(-1);
		Format(szReloadSaveName,sizeof(szReloadSaveName),"");
		HookEntityOutput("trigger_changelevel","OnChangeLevel",onchangelevel);
		if (bRebuildTransition)
		{
			/*
			Handle savedirrmh = OpenDirectory(savedir, false);
			char subfilen[64];
			while (ReadDirEntry(savedirrmh, subfilen, sizeof(subfilen)))
			{
				if ((!(savedirrmh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
				{
					if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
					{
						Format(subfilen,sizeof(subfilen),"%s\\%s",savedir,subfilen);
						if ((StrContains(subfilen,"autosave.hl1",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,szPreviousMap,false) == -1))
						{
							DeleteFile(subfilen,false);
							Handle subfiletarg = OpenFile(subfilen,"wb");
							if (subfiletarg != INVALID_HANDLE)
							{
								WriteFileLine(subfiletarg,"");
							}
							CloseHandle(subfiletarg);
						}
					}
				}
			}
			CloseHandle(savedirrmh);
			*/
			if ((!SynLaterAct) || (g_hCVbTransitionSkipVersion.BoolValue)) CreateTimer(0.1,Timer_ReDelete,_,TIMER_FLAG_NO_MAPCHANGE);
			if ((logsv != -1) && (IsValidEntity(logsv)) && ((!SynLaterAct) || (g_hCVbTransitionSkipVersion.BoolValue))) saveresetveh(false);
			if ((bTransitionPlayers) && (bIsVehicleMap))
			{
				findent(MaxClients+1,"info_player_equip");
				if (GetArraySize(g_hEquipEnts) > 0)
				{
					for (int j; j<GetArraySize(g_hEquipEnts); j++)
					{
						int jtmp = GetArrayCell(g_hEquipEnts, j);
						if (IsValidEntity(jtmp))
							AcceptEntityInput(jtmp,"Disable");
					}
				}
				g_hTimeout = CreateTimer(121.0,transitiontimeout,_,TIMER_FLAG_NO_MAPCHANGE);
			}
			int alyxtransition = -1;
			bool alyxenter = false;
			float aljeepchk[3];
			float aljeepchkj[3];
			float vecOrgs[3];
			int iRestored = 0;
			if (strlen(szLandmarkName) > 0)
			{
				findlandmark(-1,"info_landmark");
				if (SynFixesRunning)
				{
					char custentinffile[256];
					Format(custentinffile,sizeof(custentinffile),"%s\\customenttransitioninf.txt",savedir);
					if (FileExists(custentinffile,false))
					{
						ReplaceString(custentinffile,sizeof(custentinffile),"/","\\");
						SynFixesReadCache(0,custentinffile,g_vecLandmarkOrigin);
						DeleteFile(custentinffile,false);
					}
				}
				if (g_hCVbDebugTransitions.BoolValue) LogMessage("%i entities to restore over map change.",GetArraySize(g_hTransitionEntities));
				if (GetArraySize(g_hTransitionEntities) > 0)
				{
					for (int i = 0;i<GetArraySize(g_hTransitionEntities);i++)
					{
						Handle dp = GetArrayCell(g_hTransitionEntities,i);
						ResetPack(dp);
						char clsname[32];
						char szTargetname[32];
						char mdl[64];
						bool editent = false;
						ReadPackString(dp,clsname,sizeof(clsname));
						ReadPackString(dp,szTargetname,sizeof(szTargetname));
						ReadPackString(dp,mdl,sizeof(mdl));
						if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
						if (StrContains(mdl,"*",false) != -1)
						{
							editent = true;
						}
						int curh = ReadPackCell(dp);
						float vecOrigin[3];
						float vecAngles[3];
						char vehscript[64];
						vecOrigin[0] = ReadPackFloat(dp);
						vecOrigin[1] = ReadPackFloat(dp);
						vecOrigin[2] = ReadPackFloat(dp);
						vecOrigin[0]+=g_vecLandmarkOrigin[0];
						vecOrigin[1]+=g_vecLandmarkOrigin[1];
						vecOrigin[2]+=g_vecLandmarkOrigin[2];
						vecAngles[0] = ReadPackFloat(dp);
						vecAngles[1] = ReadPackFloat(dp);
						vecAngles[2] = ReadPackFloat(dp);
						ReadPackString(dp,vehscript,sizeof(vehscript));
						char spawnflags[32];
						ReadPackString(dp,spawnflags,sizeof(spawnflags));
						char additionalequip[32];
						ReadPackString(dp,additionalequip,sizeof(additionalequip));
						char skin[4];
						ReadPackString(dp,skin,sizeof(skin));
						char hdwtype[4];
						ReadPackString(dp,hdwtype,sizeof(hdwtype));
						char parentname[32];
						ReadPackString(dp,parentname,sizeof(parentname));
						char state[4];
						ReadPackString(dp,state,sizeof(state));
						char target[32];
						ReadPackString(dp,target,sizeof(target));
						int iDoorState = ReadPackCell(dp);
						int iSleepState = ReadPackCell(dp);
						char npctype[4];
						ReadPackString(dp,npctype,sizeof(npctype));
						char solidity[4];
						ReadPackString(dp,solidity,sizeof(solidity));
						int bGunEnable = ReadPackCell(dp);
						int tkdmg = ReadPackCell(dp);
						int mvtype = ReadPackCell(dp);
						int gameend = ReadPackCell(dp);
						char szGunEnable[4];
						Format(szGunEnable,sizeof(szGunEnable),"%i",bGunEnable);
						char defanim[32];
						ReadPackString(dp,defanim,sizeof(defanim));
						char response[64];
						ReadPackString(dp,response,sizeof(response));
						char scriptinf[1280];
						ReadPackString(dp,scriptinf,sizeof(scriptinf));
						CloseHandle(dp);
						bool ragdoll = false;
						if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"d2_prison_08",false)))
						{
							vecOrigin[0] = -2497.0;
							vecOrigin[1] = 2997.0;
							vecOrigin[2] = 999.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"d3_c17_01",false)))
						{
							vecOrigin[0] = -7180.0;
							vecOrigin[1] = -1200.0;
							vecOrigin[2] = 48.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep2_outland_05",false)))
						{
							vecOrigin[0] = -2952.0;
							vecOrigin[1] = 736.0;
							vecOrigin[2] = 190.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep2_outland_06",false)))
						{
							vecOrigin[0] = -448.0;
							vecOrigin[1] = 112.0;
							vecOrigin[2] = 878.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep2_outland_11b",false)))
						{
							vecOrigin[0] = 453.0;
							vecOrigin[1] = -9489.0;
							vecOrigin[2] = -283.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep1_citadel_01",false)))
						{
							vecOrigin[0] = -6208.0;
							vecOrigin[1] = 6424.0;
							vecOrigin[2] = 2685.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep1_citadel_02",false)))
						{
							vecOrigin[0] = -8602.0;
							vecOrigin[1] = 924.0;
							vecOrigin[2] = 837.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep1_citadel_02b",false)))
						{
							vecOrigin[0] = 1951.0;
							vecOrigin[1] = 4367.0;
							vecOrigin[2] = 2532.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep1_c17_00a",false)))
						{
							vecOrigin[0] = 800.0;
							vecOrigin[1] = 2600.0;
							vecOrigin[2] = 353.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep1_c17_01",false)))
						{
							vecOrigin[0] = 4881.0;
							vecOrigin[1] = -339.0;
							vecOrigin[2] = -203.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false)) && (StrEqual(mapbuf,"ep1_c17_02a",false)))
						{
							vecOrigin[0] = 5364.0;
							vecOrigin[1] = 6440.0;
							vecOrigin[2] = -2511.0;
						}
						else if ((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(szTargetname,"vort",false)) && (StrEqual(mapbuf,"ep2_outland_06",false)))
						{
							vecOrigin[0] = -448.0;
							vecOrigin[1] = 40.0;
							vecOrigin[2] = 878.0;
						}
						else if ((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(szTargetname,"vort",false)) && (StrEqual(mapbuf,"ep2_outland_04",false)))
						{
							vecOrigin[0] = 4244.0;
							vecOrigin[1] = -1708.0;
							vecOrigin[2] = 425.0;
						}
						else if ((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(szTargetname,"vort",false)) && (StrEqual(mapbuf,"ep2_outland_03",false)))
						{
							vecOrigin[0] = -1300.0;
							vecOrigin[1] = -3885.0;
							vecOrigin[2] = -855.0;
						}
						else if ((StrEqual(clsname,"npc_barney",false)) && (StrEqual(szTargetname,"barney",false)) && (StrEqual(mapbuf,"d3_c17_10a",false)))
						{
							vecOrigin[0] = -4083.0;
							vecOrigin[1] = 6789.0;
							vecOrigin[2] = 48.0;
						}
						bool skipoow = false;
						if (((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(szTargetname,"vort",false))) || ((StrEqual(clsname,"npc_barney",false)) && (StrEqual(szTargetname,"barney",false))) || ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(szTargetname,"alyx",false))))
						{
							skipoow = true;
							if (OutOfWorldBounds(vecOrigin,2.0)) skipoow = false;
						}
						if (StrEqual(clsname,"prop_physics",false)) Format(clsname,sizeof(clsname),"prop_physics_override",false);
						else if (StrEqual(clsname,"prop_dynamic",false)) Format(clsname,sizeof(clsname),"prop_dynamic_override",false);
						else if (StrEqual(clsname,"prop_ragdoll",false))
						{
							Format(clsname,sizeof(clsname),"generic_actor");
							ragdoll = true;
						}
						int ent = -1;
						Handle hReturnedArray = CreateArray(3);
						char szCheckTargetname[128];
						Format(szCheckTargetname,sizeof(szCheckTargetname),"%s",szTargetname);
						SearchForClass(szCheckTargetname,hReturnedArray);
						if (editent)
						{
							if (GetArraySize(hReturnedArray) > 0)
							{
								int replace = GetArrayCell(hReturnedArray,0);
								if (IsValidEntity(replace))
								{
									if (HasEntProp(replace,Prop_Data,"m_ModelName"))
									{
										char mdlreset[64];
										GetEntPropString(replace,Prop_Data,"m_ModelName",mdlreset,sizeof(mdlreset));
										if (StrContains(mdlreset,"*",false) != -1)
										{
											ent = replace;
											Format(mdl,sizeof(mdl),"%s",mdlreset);
										}
									}
								}
							}
						}
						else
						{
							if (GetArraySize(hReturnedArray) > 0)
							{
								bool bConflicted = false;
								float vecDuplicatePosition[3];
								for (int k = 0;k<GetArraySize(hReturnedArray);k++)
								{
									int iDuplicatedEntity = GetArrayCell(hReturnedArray,k);
									if (IsValidEntity(iDuplicatedEntity))
									{
										char dupecls[64];
										GetEntityClassname(iDuplicatedEntity,dupecls,sizeof(dupecls));
										if (StrEqual(dupecls,"prop_dynamic",false)) Format(dupecls,sizeof(dupecls),"prop_dynamic_override");
										if (StrEqual(dupecls,"prop_physics",false)) Format(dupecls,sizeof(dupecls),"prop_physics_override");
										if (StrEqual(dupecls,clsname,false))
										{
											if (HasEntProp(iDuplicatedEntity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(iDuplicatedEntity,Prop_Data,"m_vecAbsOrigin",vecDuplicatePosition);
											else if (HasEntProp(iDuplicatedEntity,Prop_Send,"m_vecOrigin")) GetEntPropVector(iDuplicatedEntity,Prop_Send,"m_vecOrigin",vecDuplicatePosition);
											if (GetVectorDistance(vecOrigin,vecDuplicatePosition,false) < 6.0)
											{
												//bConflicted = true;
												if (g_hCVbDebugTransitions.BoolValue) LogMessage("Transition Entity conflicted %s %s replacing with transitioned ent.", dupecls, szTargetname);
												AcceptEntityInput(iDuplicatedEntity, "kill");
												break;
											}
										}
									}
								}
								if (!bConflicted) ent = CreateEntityByName(clsname);
							}
							else ent = CreateEntityByName(clsname);
						}
						CloseHandle(hReturnedArray);
						if ((TR_PointOutsideWorld(vecOrigin)) && (!skipoow))
						{
							if (g_hCVbDebugTransitions.BoolValue) LogMessage("Delete Transition Ent (OutOfWorld) %s info: Model \"%s\" TargetName \"%s\" Solid \"%i\" spawnflags \"%i\" movetype \"%i\"",clsname,mdl,szTargetname,StringToInt(solidity),StringToInt(spawnflags),mvtype);
							if ((IsValidEntity(ent)) && (ent != 0)) AcceptEntityInput(ent, "kill");
							ent = -1;
						}
						if (ent != -1)
						{
							if (g_hCVbDebugTransitions.BoolValue) LogMessage("Restore Ent %s Transition info: Model \"%s\" TargetName \"%s\" Solid \"%i\" spawnflags \"%i\" movetype \"%i\" to origin \"%1.f %1.f %1.f\"",clsname,mdl,szTargetname,StringToInt(solidity),StringToInt(spawnflags),mvtype,vecOrigin[0],vecOrigin[1],vecOrigin[2]);
							bool beginseq = false;
							bool applypropafter = false;
							if (StrEqual(clsname,"npc_alyx",false))
							{
								alyxtransition = ent;
								aljeepchk[0] = vecOrigin[0];
								aljeepchk[1] = vecOrigin[1];
								aljeepchk[2] = vecOrigin[2];
							}
							if (StrEqual(clsname,"prop_vehicle_jeep_episodic",false))
							{
								if (StrEqual(szTargetname,"jeep",false))
								{
									char tmp[128];
									Format(tmp,sizeof(tmp),"alyx,EnterVehicle,%s,0,-1",szTargetname);
									DispatchKeyValue(ent,"PlayerOn",tmp);
									Format(tmp,sizeof(tmp),"alyx,ExitVehicle,,0,-1");
									DispatchKeyValue(ent,"PlayerOff",tmp);
								}
								alyxenter = true;
								aljeepchkj[0] = vecOrigin[0];
								aljeepchkj[1] = vecOrigin[1];
								aljeepchkj[2] = vecOrigin[2];
							}
							if (StrEqual(clsname,"info_particle_system",false)) DispatchKeyValue(ent,"effect_name",mdl);
							if (strlen(szTargetname) > 0)
							{
								DispatchKeyValue(ent,"targetname",szTargetname);
								FindOutputsFor(ent,szTargetname);
							}
							DispatchKeyValue(ent,"model",mdl);
							if (strlen(vehscript) > 0) DispatchKeyValue(ent,"VehicleScript",vehscript);
							if (strlen(additionalequip) > 0) DispatchKeyValue(ent,"AdditionalEquipment",additionalequip);
							if (strlen(hdwtype) > 0) DispatchKeyValue(ent,"hardware",hdwtype);
							if (strlen(parentname) > 0) DispatchKeyValue(ent,"ParentName",parentname);
							if (strlen(state) > 0) DispatchKeyValue(ent,"State",state);
							if (strlen(target) > 0) DispatchKeyValue(ent,"Target",target);
							if (HasEntProp(ent,Prop_Data,"m_Type")) DispatchKeyValue(ent,"citizentype",npctype);
							if (HasEntProp(ent,Prop_Data,"m_nSolidType")) DispatchKeyValue(ent,"solid",solidity);
							if (HasEntProp(ent,Prop_Data,"m_bHasGun")) DispatchKeyValue(ent,"EnableGun",szGunEnable);
							if ((strlen(defanim) > 0) && (HasEntProp(ent,Prop_Data,"m_iszDefaultAnim"))) DispatchKeyValue(ent,"DefaultAnim",defanim);
							if ((strlen(response) > 0) && (HasEntProp(ent,Prop_Data,"m_iszResponseContext"))) DispatchKeyValue(ent,"ResponseContext",response);
							char scriptexp[64][128];
							if (!StrEqual(scriptinf,"endofpack",false))
							{
								ExplodeString(scriptinf," ",scriptexp,64,128);
								char firstv[64];
								for (int j = 0;j<64;j++)
								{
									bool skip2 = false;
									int jadd = j+1;
									if ((strlen(scriptexp[j]) > 0) && (strlen(scriptexp[jadd]) > 0))
									{
										if (StrContains(scriptexp[jadd],"\"",false) != -1)
										{
											Format(firstv,sizeof(firstv),"%s",scriptexp[jadd]);
											Format(scriptexp[jadd],sizeof(scriptexp[]),"%s %s %s",scriptexp[jadd],scriptexp[jadd+1],scriptexp[jadd+2]);
											ReplaceString(scriptexp[jadd],sizeof(scriptexp[]),"\"","");
											skip2 = true;
										}
										//PrintToServer("Pushing %s %s",scriptexp[j],scriptexp[jadd]);
										if (StrEqual(scriptexp[j],"axis",false))
										{
											float addz = StringToFloat(scriptexp[jadd+2]);
											addz+=50.0;
											Format(scriptexp[jadd],sizeof(scriptexp[]),"%s, %s %s %1.f",scriptexp[jadd],firstv,scriptexp[jadd+1],addz);
											//PrintToServer("Dispatch %s %s",scriptexp[j],scriptexp[jadd]);
											DispatchKeyValue(ent,scriptexp[j],scriptexp[jadd]);
										}
										else if (StrEqual(scriptexp[j],"m_iszSound",false))
										{
											DispatchKeyValue(ent,"message",scriptexp[jadd]);
										}
										else if (StrEqual(scriptexp[j],"m_iszSceneFile",false))
										{
											DispatchKeyValue(ent,"SceneFile",scriptexp[jadd]);
										}
										else if (StrEqual(scriptexp[j],"m_nAmmoType",false))
										{
											DispatchKeyValue(ent,"AmmoType",scriptexp[jadd]);
										}
										else if (StrEqual(scriptexp[j],"m_strItemClass",false))
										{
											DispatchKeyValue(ent,"ItemClass",scriptexp[jadd]);
										}
										else if (StrEqual(scriptexp[j],"m_clrRender",false))
										{
											skip2 = true;
											int iOffs = GetEntSendPropOffs(ent,"m_clrRender");
											if (iOffs != -1)
											{
												SetEntData(ent,iOffs,StringToInt(scriptexp[jadd]),1,true);
												SetEntData(ent,iOffs + 1,StringToInt(scriptexp[jadd+1]),1,true);
												SetEntData(ent,iOffs + 2,StringToInt(scriptexp[jadd+2]),1,true);
												SetEntData(ent,iOffs + 3,StringToInt(scriptexp[jadd+3]),1,true);
											}
											j++;
										}
										else
										{
											DispatchKeyValue(ent,scriptexp[j],scriptexp[jadd]);
											applypropafter = true;
										}
										/*
										if ((StrContains(scriptexp[j],"m_angRotation",false) == 0) || (StrContains(scriptexp[j],"m_vecOrigin",false) == 0))
										{
											applypropafter = true;
										}
										*/
									}
									if (skip2) j+=2;
									j++;
								}
								beginseq = true;
							}
							DispatchKeyValue(ent,"spawnflags",spawnflags);
							DispatchKeyValue(ent,"skin",skin);
							DispatchSpawn(ent);
							ActivateEntity(ent);
							iRestored++;
							if (strlen(parentname) > 0)
							{
								SetVariantString(parentname);
								AcceptEntityInput(ent,"SetParent");
								if ((StrEqual(clsname,"prop_dynamic_override",false)) || (StrEqual(clsname,"prop_dynamic",false)) || (StrEqual(clsname,"prop_physics_override",false)) || (StrEqual(clsname,"prop_physics",false))) AcceptEntityInput(ent,"Enable");
							}
							if (curh != 0) SetEntProp(ent,Prop_Data,"m_iHealth",curh);
							TeleportEntity(ent,vecOrigin,vecAngles,NULL_VECTOR);
							if ((HasEntProp(ent,Prop_Data,"m_eDoorState")) && (iDoorState != 1)) SetEntProp(ent,Prop_Data,"m_eDoorState",iDoorState);
							if (HasEntProp(ent,Prop_Data,"m_SleepState")) SetEntProp(ent,Prop_Data,"m_SleepState",iSleepState);
							if (HasEntProp(ent,Prop_Data,"m_takedamage")) SetEntProp(ent,Prop_Data,"m_takedamage",tkdmg);
							if (HasEntProp(ent,Prop_Data,"movetype")) SetEntProp(ent,Prop_Data,"movetype",mvtype);
							if (HasEntProp(ent,Prop_Data,"m_bGameEndAlly")) SetEntProp(ent,Prop_Data,"m_bGameEndAlly",gameend);
							if (beginseq) CreateTimer(0.2,beginseqd,ent);
							if (applypropafter)
							{
								for (int j = 0;j<64;j++)
								{
									int jadd = j+1;
									if ((strlen(scriptexp[j]) > 0) && (strlen(scriptexp[jadd]) > 0))
									{
										if (HasEntProp(ent,Prop_Data,scriptexp[j]))
										{
											PropFieldType type;
											FindDataMapInfo(ent,scriptexp[j],type);
											if ((type == PropField_String) || (type == PropField_String_T))
											{
												SetEntPropString(ent,Prop_Data,scriptexp[j],scriptexp[jadd]);
											}
											else if (type == PropField_Entity)
											{
												SetEntPropEnt(ent,Prop_Data,scriptexp[j],StringToInt(scriptexp[jadd]));
											}
											else if (type == PropField_Integer)
											{
												SetEntProp(ent,Prop_Data,scriptexp[j],StringToInt(scriptexp[jadd]));
											}
											else if (type == PropField_Float)
											{
												SetEntPropFloat(ent,Prop_Data,scriptexp[j],StringToFloat(scriptexp[jadd]));
											}
											else if (type == PropField_Vector)
											{
												//PrintToServer("Apply vec %s",scriptexp[j]);
												float entvec[3];
												char vecchk[8][32];
												ExplodeString(scriptexp[jadd]," ",vecchk,8,32);
												if (strlen(vecchk[2]) > 0)
												{
													entvec[0] = StringToFloat(vecchk[0]);
													entvec[1] = StringToFloat(vecchk[1]);
													entvec[2] = StringToFloat(vecchk[2]);
													SetEntPropVector(ent,Prop_Data,scriptexp[j],entvec);
													if ((iDoorState == 1) && (StrEqual(scriptexp[j],"m_angGoal",false)))
													{
														TeleportEntity(ent,NULL_VECTOR,entvec,NULL_VECTOR);
													}
												}
											}
										}
									}
									j++;
								}
							}
							if (StrEqual(clsname,"func_tracktrain",false))
							{
								if (HasEntProp(ent,Prop_Data,"m_iEFlags")) SetEntProp(ent,Prop_Data,"m_iEFlags",12845056);
							}
							if (ragdoll) AcceptEntityInput(ent,"BecomeRagdoll");
							// Find duplicate names on transition
							if (strlen(szTargetname) > 1)
							{
								int iEnt = -1;
								char szSearchTargetname[32];
								while((iEnt = FindEntityByClassname(iEnt,clsname)) != INVALID_ENT_REFERENCE)
								{
									if ((IsValidEntity(iEnt)) && (iEnt != ent))
									{
										if (HasEntProp(iEnt,Prop_Data,"m_iName"))
										{
											GetEntPropString(iEnt, Prop_Data, "m_iName", szSearchTargetname, sizeof(szSearchTargetname));
											if (StrEqual(szSearchTargetname, szTargetname, false))
											{
												if (HasEntProp(iEnt,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(iEnt,Prop_Data,"m_vecAbsOrigin",vecOrgs);
												else if (HasEntProp(iEnt,Prop_Data,"m_vecOrigin")) GetEntPropVector(iEnt,Prop_Data,"m_vecOrigin",vecOrgs);
												if (GetVectorDistance(vecOrigin,vecOrgs,false) < 512.0)
												{
													AcceptEntityInput(iEnt, "kill");
													break;
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			if ((g_hCVbDebugTransitions.BoolValue) && (GetArraySize(g_hTransitionEntities) > 0)) LogMessage("ClearTransitionEnts Array after restore of %i/%i ents",iRestored,GetArraySize(g_hTransitionEntities));
			//ClearArrayHandles(g_hTransitionEntities);
			ClearArray(g_hTransitionEntities);
			if ((alyxtransition != -1) && (IsValidEntity(alyxtransition)))
			{
				int aldouble = FindEntityByClassname(-1,"npc_alyx");
				if ((aldouble != -1) && (!StrEqual(mapbuf,"d1_trainstation_05",false)))
				{
					int aldouble2 = FindEntityByClassname(aldouble+1,"npc_alyx");
					if ((aldouble2 != -1) && (IsValidEntity(aldouble2)) && (aldouble2 != alyxtransition))
					{
						if (HasEntProp(aldouble2,Prop_Data,"m_iName"))
						{
							char szTargetname[16];
							GetEntPropString(aldouble2,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
							if (StrEqual(szTargetname,"alyx",false)) AcceptEntityInput(aldouble2, "kill");
						}
					}
				}
				if (StrEqual(mapbuf,"d1_eli_02",false))
				{
					int iEnt = -1;
					char szTargetname[32];
					while((iEnt = FindEntityByClassname(iEnt,"npc_template_maker")) != INVALID_ENT_REFERENCE)
					{
						if (IsValidEntity(iEnt))
						{
							if (HasEntProp(iEnt,Prop_Data,"m_iName"))
							{
								GetEntPropString(iEnt,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
								if (StrEqual(szTargetname,"spawn_alyx",false))
								{
									AcceptEntityInput(iEnt, "kill");
									break;
								}
							}
						}
					}
				}
				if ((aldouble != -1) && (IsValidEntity(aldouble)) && (aldouble != alyxtransition))
				{
					char szTargetname[16];
					GetEntPropString(aldouble,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
					if (StrEqual(szTargetname,"alyx",false)) AcceptEntityInput(aldouble, "kill");
				}
			}
			if ((alyxenter) && (IsValidEntity(alyxtransition)) && (alyxtransition > MaxClients))
			{
				if (!StrEqual(mapbuf,"ep2_outland_12",false))
				{
					float chkdist = GetVectorDistance(aljeepchk,aljeepchkj,false);
					if (RoundFloat(chkdist) < 200)
					{
						SetVariantString("jeep");
						AcceptEntityInput(alyxtransition,"EnterVehicleImmediately");
						if (g_hCVbDebugTransitions.BoolValue) LogMessage("Alyx entered jalopy on transition at %1.f %1.f %1.f",aljeepchkj[0],aljeepchkj[1],aljeepchkj[2]);
					}
				}
			}
			resetareaportals(-1);
			if (strlen(savedir) > 1)
			{
				char curmapchk[128];
				Format(curmapchk,sizeof(curmapchk),"%s/%s.hl1",savedir,mapbuf);
				if (!FileExists(curmapchk))
				{
					Handle subfiletarg = OpenFile(curmapchk,"wb");
					if (subfiletarg != INVALID_HANDLE)
					{
						WriteFileLine(subfiletarg,"");
					}
					CloseHandle(subfiletarg);
				}
				Format(curmapchk,sizeof(curmapchk),"%s/%s.hl2",savedir,mapbuf);
				if (!FileExists(curmapchk))
				{
					Handle subfiletarg = OpenFile(curmapchk,"wb");
					if (subfiletarg != INVALID_HANDLE)
					{
						WriteFileLine(subfiletarg,"");
					}
					CloseHandle(subfiletarg);
				}
				Format(curmapchk,sizeof(curmapchk),"%s/%s.hl3",savedir,mapbuf);
				if (!FileExists(curmapchk))
				{
					Handle subfiletarg = OpenFile(curmapchk,"wb");
					if (subfiletarg != INVALID_HANDLE)
					{
						WriteFileLine(subfiletarg,"");
					}
					CloseHandle(subfiletarg);
				}
			}
		}
	}
}

public Action OnLevelInit(const char[] szMapName, char szMapEntities[2097152])
{
	Format(szMapEntitiesBuff,sizeof(szMapEntitiesBuff),"%s",szMapEntities);
	return Plugin_Continue;
}

void FindOutputsFor(int ent, char[] szTargetname)
{
	if (!IsValidEntity(ent)) return;
	char szSearch[128];
	static char szMapEntBuff[4096];
	Format(szSearch,sizeof(szSearch),"\"targetname\" \"%s\"",szTargetname);
	int iFindStart = StrContains(szMapEntitiesBuff,szSearch,false);
	if (iFindStart != -1)
	{
		Format(szMapEntBuff,sizeof(szMapEntBuff),"%s",szMapEntitiesBuff[iFindStart]);
		iFindStart = StrContains(szMapEntBuff,"}",false);
		if (iFindStart != -1)
		{
			Format(szMapEntBuff,iFindStart+1,"%s",szMapEntBuff);
			static char szKVs[32][64];
			static char szOuts[4][64];
			int iOut = ExplodeString(szMapEntBuff,"\"On",szKVs,32,64);
			if (iOut > 0)
			{
				for (int i = 1;i<iOut;i++)
				{
					iFindStart = StrContains(szKVs[i],"\n",false);
					if (iFindStart > 0)
					{
						Format(szKVs[i],iFindStart+1,"%s",szKVs[i]);
						int iLast = ExplodeString(szKVs[i]," ",szOuts,4,64);
						if (iLast > 2)
						for (int j = 2;j<iLast;j++)
						{
							Format(szOuts[1],sizeof(szOuts[]),"%s %s",szOuts[1],szOuts[j]);
						}
						Format(szOuts[0],sizeof(szOuts[]),"On%s",szOuts[0]);
						ReplaceString(szOuts[0],sizeof(szOuts[]),"\"","",false);
						ReplaceString(szOuts[1],sizeof(szOuts[]),"\"","",false);
						if (g_hCVbDebugTransitions.BoolValue) LogMessage("RestoreOutput: '%s' '%s'",szOuts[0],szOuts[1]);
						if (strlen(szOuts[0]) && strlen(szOuts[1]))
						{
							DispatchKeyValue(ent,szOuts[0],szOuts[1]);
						}
					}
				}
			}
		}
	}
	return;
}

public Action TransitionPostAdjust(Handle timer, int Indx)
{
	if (Indx == 0)
	{
		bool bVorts[3];
		int iEnt = -1;
		char szTargetname[32];
		while((iEnt = FindEntityByClassname(iEnt,"npc_vortigaunt")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(iEnt))
			{
				if (HasEntProp(iEnt,Prop_Data,"m_iName"))
				{
					GetEntPropString(iEnt,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
					if (StrEqual(szTargetname,"vort_calvary_1",false))
					{
						bVorts[0] = true;
					}
					else if (StrEqual(szTargetname,"vort_calvary_2",false))
					{
						bVorts[1] = true;
					}
					else if (StrEqual(szTargetname,"vort_calvary_actor",false))
					{
						bVorts[2] = true;
					}
				}
			}
		}
		float vecOrigin[3];
		if (!bVorts[0])
		{
			iEnt = CreateEntityByName("npc_vortigaunt");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","vort_calvary_1");
				DispatchKeyValue(iEnt,"squadname","vort_reinforcements");
				DispatchKeyValue(iEnt,"damagefilter","null");
				DispatchKeyValue(iEnt,"model","models/vortigaunt_blue.mdl");
				vecOrigin[0] = -1888.0;
				vecOrigin[1] = -9200.0;
				vecOrigin[2] = -456.0;
				TeleportEntity(iEnt,vecOrigin,NULL_VECTOR,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				AcceptEntityInput(iEnt,"SetReadinessHigh");
				AcceptEntityInput(iEnt,"DisableArmorRecharge");
				SetVariantString("600");
				AcceptEntityInput(iEnt,"LockReadiness");
			}
		}
		if (!bVorts[1])
		{
			iEnt = CreateEntityByName("npc_vortigaunt");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","vort_calvary_2");
				DispatchKeyValue(iEnt,"squadname","vort_reinforcements");
				DispatchKeyValue(iEnt,"damagefilter","null");
				DispatchKeyValue(iEnt,"model","models/vortigaunt_blue.mdl");
				vecOrigin[0] = -1894.0;
				vecOrigin[1] = -9385.0;
				vecOrigin[2] = -456.0;
				TeleportEntity(iEnt,vecOrigin,NULL_VECTOR,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				AcceptEntityInput(iEnt,"SetReadinessHigh");
				AcceptEntityInput(iEnt,"DisableArmorRecharge");
				SetVariantString("600");
				AcceptEntityInput(iEnt,"LockReadiness");
			}
		}
		if (!bVorts[2])
		{
			iEnt = CreateEntityByName("npc_vortigaunt");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","vort_calvary_actor");
				DispatchKeyValue(iEnt,"squadname","vort_reinforcements");
				DispatchKeyValue(iEnt,"damagefilter","null");
				DispatchKeyValue(iEnt,"model","models/vortigaunt_blue.mdl");
				vecOrigin[0] = -1888.0;
				vecOrigin[1] = -9312.0;
				vecOrigin[2] = -455.0;
				TeleportEntity(iEnt,vecOrigin,NULL_VECTOR,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				AcceptEntityInput(iEnt,"SetReadinessHigh");
				AcceptEntityInput(iEnt,"DisableArmorRecharge");
				SetVariantString("600");
				AcceptEntityInput(iEnt,"LockReadiness");
			}
		}
		if ((!bVorts[0]) || (!bVorts[1]) || (!bVorts[2])) SendInput("scripted_sequence","ss_heal_loop","BeginSequence",0);
	}
	if (Indx == 1)
	{
		int iTrainCount = 0;
		int iEnt = -1;
		char szTargetname[32];
		while((iEnt = FindEntityByClassname(iEnt,"prop_dynamic")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(iEnt))
			{
				if (HasEntProp(iEnt,Prop_Data,"m_iName"))
				{
					GetEntPropString(iEnt,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
					if (StrContains(szTargetname,"razortrain_car",false))
					{
						iTrainCount++;
					}
				}
			}
		}
		if (iTrainCount < 4)
		{
			PrintToServer("TrainMissing Count: %i",iTrainCount);
			float vecOrigin[3];
			float vecAngles[3];
			vecOrigin[0] = 472.679931;
			vecOrigin[1] = -12486.0;
			vecOrigin[2] = 2051.59;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","razortrain_car1");
				DispatchKeyValue(iEnt,"model","models/props_combine/CombineTrain01a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 5916.679687;
			vecAngles[1] = 180.0;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","razortrain_car2");
				DispatchKeyValue(iEnt,"model","models/props_combine/CombineTrain01a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 2273.680175;
			vecOrigin[1] = -12486.0;
			vecOrigin[2] = 2175.0;
			vecAngles[1] = 270.0;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","razortrain_car3");
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02b.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 1657.68;
			vecOrigin[1] = -12486.0;
			vecOrigin[2] = 2175.68;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"targetname","razortrain_car4");
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02b.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 1041.68;
			vecOrigin[1] = -12486.0;
			vecOrigin[2] = 2175.59;
			vecAngles[1] = 270.0;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 2885.68;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 3501.68;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 4116.68;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 4733.68;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02b.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
			vecOrigin[0] = 5348.68;
			iEnt = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(iEnt))
			{
				DispatchKeyValue(iEnt,"model","models/props_combine/combine_train02a.mdl");
				DispatchKeyValue(iEnt,"solid","6");
				TeleportEntity(iEnt,vecOrigin,vecAngles,NULL_VECTOR);
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);
				SetVariantString("razortrain");
				AcceptEntityInput(iEnt,"SetParent");
			}
		}
	}
}

public void Ep2ElevatorPass(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		int iEnt = -1;
		char szTargetname[32];
		while((iEnt = FindEntityByClassname(iEnt,"scripted_sequence")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(iEnt))
			{
				if (HasEntProp(iEnt,Prop_Data,"m_iName"))
				{
					GetEntPropString(iEnt,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
					if (StrEqual(szTargetname,"vort_enter_on_elevator_ss_1",false))
					{
						AcceptEntityInput(iEnt,"CancelSequence");
					}
					else if (StrEqual(szTargetname,"vort_ride_elevator_from_04",false))
					{
						AcceptEntityInput(iEnt,"BeginSequence");
					}
				}
			}
		}
		UnhookSingleEntityOutput(caller,output,Ep2ElevatorPass);
	}
}

bool SendInput(char[] szClass, char[] szTargetName, char[] szInput, int iActivator)
{
	bool bRet = false;
	int iEnt = -1;
	char szTargetname[32];
	while((iEnt = FindEntityByClassname(iEnt,szClass)) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(iEnt))
		{
			if (HasEntProp(iEnt,Prop_Data,"m_iName"))
			{
				GetEntPropString(iEnt,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
				if (StrEqual(szTargetname,szTargetName,false))
				{
					bRet = true;
					if (iActivator != 0) AcceptEntityInput(iEnt,szInput,iActivator);
					else AcceptEntityInput(iEnt,szInput);
				}
			}
		}
	}
	return bRet;
}

void ClearArrayHandles(Handle array)
{
	if (array != INVALID_HANDLE)
	{
		if (view_as<int>(array) != 1634494062)
		{
			if (GetArraySize(array) > 0)
			{
				for (int i = 0;i<GetArraySize(array);i++)
				{
					Handle closearr = GetArrayCell(array,i);
					if (closearr != INVALID_HANDLE) CloseHandle(closearr);
				}
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname,"env_global",false))
	{
		if (GetArraySize(g_hGlobalsTransition) > 0)
		{
			CreateTimer(0.1,rechkglobaltimer,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action rechkglobaltimer(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		for (int i = 0;i<GetArraySize(g_hGlobalsTransition);i++)
		{
			Handle dp = GetArrayCell(g_hGlobalsTransition,i);
			ResetPack(dp);
			char m_globalstate[64];
			char m_iName[64];
			ReadPackString(dp,m_globalstate,sizeof(m_globalstate));
			ReadPackString(dp,m_iName,sizeof(m_iName));
			int m_triggermode = ReadPackCell(dp);
			int m_initialstate = ReadPackCell(dp);
			int m_counter = ReadPackCell(dp);
			int m_fEffects = ReadPackCell(dp);
			int m_lifeState = ReadPackCell(dp);
			int m_iHealth = ReadPackCell(dp);
			int m_iMaxHealth = ReadPackCell(dp);
			int m_iEFlags = ReadPackCell(dp);
			int m_spawnflags = ReadPackCell(dp);
			int m_fFlags = ReadPackCell(dp);
			//CloseHandle(dp);
			char statechk[64];
			char szEntName[64];
			GetEntPropString(entity,Prop_Data,"m_globalstate",statechk,sizeof(statechk));
			if (HasEntProp(entity,Prop_Data,"m_iName")) GetEntPropString(entity,Prop_Data,"m_iName",szEntName,sizeof(szEntName));
			if ((StrEqual(statechk,m_globalstate,false)) || (StrEqual(m_iName,szEntName,false)))
			{
				if (g_hCVbDebugTransitions.BoolValue) LogMessage("Set global state for '%s' '%s' State: %i Counter: %i",statechk,m_iName,m_initialstate,m_counter);
				if (HasEntProp(entity,Prop_Data,"m_globalstate")) SetEntPropString(entity,Prop_Data,"m_globalstate",m_globalstate);
				if (HasEntProp(entity,Prop_Data,"m_iName")) SetEntPropString(entity,Prop_Data,"m_iName",m_iName);
				if (HasEntProp(entity,Prop_Data,"m_triggermode")) SetEntProp(entity,Prop_Data,"m_triggermode",m_triggermode);
				if (HasEntProp(entity,Prop_Data,"m_initialstate")) SetEntProp(entity,Prop_Data,"m_initialstate",m_initialstate);
				if (HasEntProp(entity,Prop_Data,"m_counter")) SetEntProp(entity,Prop_Data,"m_counter",m_counter);
				if (HasEntProp(entity,Prop_Data,"m_fEffects")) SetEntProp(entity,Prop_Data,"m_fEffects",m_fEffects);
				if (HasEntProp(entity,Prop_Data,"m_lifeState")) SetEntProp(entity,Prop_Data,"m_lifeState",m_lifeState);
				if (HasEntProp(entity,Prop_Data,"m_iHealth")) SetEntProp(entity,Prop_Data,"m_iHealth",m_iHealth);
				if (HasEntProp(entity,Prop_Data,"m_iMaxHealth")) SetEntProp(entity,Prop_Data,"m_iMaxHealth",m_iMaxHealth);
				if (HasEntProp(entity,Prop_Data,"m_iEFlags")) SetEntProp(entity,Prop_Data,"m_iEFlags",m_iEFlags);
				if (HasEntProp(entity,Prop_Data,"m_spawnflags")) SetEntProp(entity,Prop_Data,"m_spawnflags",m_spawnflags);
				if (HasEntProp(entity,Prop_Data,"m_fFlags")) SetEntProp(entity,Prop_Data,"m_fFlags",m_fFlags);
			}
			if ((m_counter) || (m_initialstate))
			{
				int iEnt = -1;
				char szGlobalState[32];
				while((iEnt = FindEntityByClassname(iEnt,"logic_auto")) != INVALID_ENT_REFERENCE)
				{
					if (IsValidEntity(iEnt))
					{
						if (HasEntProp(iEnt,Prop_Data,"m_globalstate"))
						{
							GetEntPropString(iEnt,Prop_Data,"m_globalstate",szGlobalState,sizeof(szGlobalState));
							if (StrEqual(szGlobalState,m_globalstate,false))
							{
								if (HasEntProp(iEnt,Prop_Data,"m_OnMapSpawn")) FireEntityOutput(iEnt,"OnMapSpawn",0,0.0);
								if (HasEntProp(iEnt,Prop_Data,"m_OnMapTransition")) FireEntityOutput(iEnt,"OnMapTransition",0,0.0);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public bool OutOfWorldBounds(float vecOrigin[3], float scale)
{
	float vecMins[3];
	float vecMaxs[3];
	GetEntPropVector(0,Prop_Data,"m_WorldMins",vecMins);
	GetEntPropVector(0,Prop_Data,"m_WorldMaxs",vecMaxs);
	ScaleVector(vecMins,scale);
	ScaleVector(vecMaxs,scale);
	if ((vecOrigin[0] < vecMins[0]) || (vecOrigin[1] < vecMins[1]) || (vecOrigin[2] < vecMins[2]) || (vecOrigin[0] > vecMaxs[0]) || (vecOrigin[1] > vecMaxs[1]) || (vecOrigin[2] > vecMaxs[2]))
	{
		if (TR_PointOutsideWorld(vecOrigin))
			return true;
	}
	return false;
}

public Action Timer_ReDelete(Handle timer)
{
	saveresetveh(true);
}

public Action beginseqd(Handle timer, int ent)
{
	if (IsValidEntity(ent))
		AcceptEntityInput(ent,"BeginSequence");
}

public void OnMapEnd()
{
	if ((bRebuildTransition) && (reloadingmap))
	{
		if (IsValidEntity(logplyprox))
		{
			char clschk[32];
			GetEntityClassname(logplyprox,clschk,sizeof(clschk));
			if ((StrEqual(clschk,"logic_playerproxy",false)) && (!StrEqual(mapbuf,"d3_citadel_02",false)) && (!StrEqual(mapbuf,"ep2_outland_04",false)))
			{
				AcceptEntityInput(logplyprox,"CancelRestorePlayers");
			}
		}
		else
			logplyprox = -1;
		if (!bNoDelete)
		{
			if (strlen(savedir) > 0)
			{
				if (DirExists(savedir,false))
				{
					Handle savedirrmh = OpenDirectory(savedir, false);
					char subfilen[64];
					while (ReadDirEntry(savedirrmh, subfilen, sizeof(subfilen)))
					{
						if ((!(savedirrmh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
						{
							if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
							{
								Format(subfilen,sizeof(subfilen),"%s\\%s",savedir,subfilen);
								if ((StrContains(subfilen,"autosave.hl1",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,szPreviousMap,false) == -1))
								{
									DeleteFile(subfilen,false);
									/*
									Handle subfiletarg = OpenFile(subfilen,"wb");
									if (subfiletarg != INVALID_HANDLE)
									{
										WriteFileLine(subfiletarg,"");
									}
									CloseHandle(subfiletarg);
									*/
								}
							}
						}
					}
					CloseHandle(savedirrmh);
				}
			}
		}
	}
	else if (!reloadingmap)
	{
		ClearArray(g_hTransitionIDs);
		ClearArrayHandles(g_hTransitionDataPacks);
		ClearArray(g_hTransitionDataPacks);
		ClearArray(g_hTransitionPlayerOrigin);
		if (g_hCVbDebugTransitions.BoolValue) LogMessage("ClearTransitionEnts Array");
		ClearArrayHandles(g_hTransitionEntities);
		ClearArray(g_hTransitionEntities);
		ClearArrayHandles(g_hGlobalsTransition);
		ClearArray(g_hGlobalsTransition);
		ClearArray(g_hEquipEnts);
		szPreviousMap = "";
	}
}

public Action transitiontimeout(Handle timer)
{
	g_hTimeout = INVALID_HANDLE;
	ClearArray(g_hTransitionIDs);
	ClearArrayHandles(g_hTransitionDataPacks);
	ClearArray(g_hTransitionDataPacks);
	ClearArray(g_hTransitionPlayerOrigin);
	if (GetArraySize(g_hEquipEnts) > 0)
	{
		for (int j; j<GetArraySize(g_hEquipEnts); j++)
		{
			int jtmp = GetArrayCell(g_hEquipEnts, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
	if (reloadaftersetup)
	{
		Handle nullpl = INVALID_HANDLE;
		ReloadPlugin(nullpl);
	}
}

public void OnPluginEnd()
{
	if (GetArraySize(g_hEquipEnts) > 0)
	{
		for (int j; j<GetArraySize(g_hEquipEnts); j++)
		{
			int jtmp = GetArrayCell(g_hEquipEnts, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
}

public Action resettransition(int args)
{
	if (!reloadingmap)
	{
		ClearArray(g_hTransitionIDs);
		ClearArrayHandles(g_hTransitionDataPacks);
		ClearArray(g_hTransitionDataPacks);
		ClearArray(g_hTransitionPlayerOrigin);
		ClearArray(g_hEquipEnts);
		szPreviousMap = "";
	}
	char getmap[64];
	GetCmdArg(1,getmap,sizeof(getmap));
	char curmap[64];
	GetCurrentMap(curmap,sizeof(curmap));
	if ((StrEqual(getmap,"remount",false)) && (StrEqual(curmap,"ep1_c17_06",false))) enterfromep1 = true;
	else enterfromep1 = false;
	if ((StrEqual(getmap,"remount",false)) && ((StrEqual(curmap,"ep2_outland_12a",false)) || (StrEqual(curmap,"xen_c5a1",false)))) enterfromep2 = true;
	else enterfromep2 = false;
	return Plugin_Continue;
}

public Action onchangelevel(const char[] output, int caller, int activator, float delay)
{
	bool validchange = false;
	enterfromep1 = false;
	if (bRebuildTransition)
	{
		if (IsValidEntity(logplyprox))
		{
			char clschk[32];
			GetEntityClassname(logplyprox,clschk,sizeof(clschk));
			if ((StrEqual(clschk,"logic_playerproxy",false)) && (!StrEqual(mapbuf,"d3_citadel_02",false)) && (!StrEqual(mapbuf,"ep2_outland_04",false)))
			{
				AcceptEntityInput(logplyprox,"CancelRestorePlayers");
			}
		}
		else
			logplyprox = -1;
		if ((IsValidEntity(caller)) && (IsEntNetworkable(caller)))
		{
			char clschk[32];
			GetEntityClassname(caller,clschk,sizeof(clschk));
			if (StrEqual(clschk,"trigger_changelevel",false)) validchange = true;
		}
		ClearArray(g_hTransitionIDs);
		ClearArrayHandles(g_hTransitionDataPacks);
		ClearArray(g_hTransitionDataPacks);
		ClearArray(g_hTransitionPlayerOrigin);
		ClearArray(g_hIgnoredEntities);
		GetCurrentMap(szPreviousMap,sizeof(szPreviousMap));
		if (validchange) GetEntPropString(caller,Prop_Data,"m_szMapName",szNextMap,sizeof(szNextMap));
		else szNextMap = "";
		if (StrEqual(szNextMap,"sp_ending",false)) return Plugin_Continue;
		if ((StrEqual(szPreviousMap,"d1_town_03",false)) && (StrEqual(szNextMap,"d1_town_02",false)))
		{
			enterfrom03pb = true;
		}
		else if ((StrEqual(szPreviousMap,"d2_coast_08",false)) && (StrEqual(szNextMap,"d2_coast_07",false)))
		{
			enterfrom08pb = true;
		}
		else if ((StrEqual(szPreviousMap,"ep2_outland_04",false)) && (StrEqual(szNextMap,"ep2_outland_02",false)))
		{
			enterfrom04pb = true;
		}
		else if ((StrEqual(szPreviousMap,"bm_c2a4g",false)) && (StrEqual(szNextMap,"bm_c2a4fedt",false)))
		{
			enterfrom4g = true;
		}
		reloadingmap = true;
		if (!bNoDelete)
		{
			if (strlen(savedir) > 0)
			{
				if (DirExists(savedir,false))
				{
					Handle savedirh = OpenDirectory(savedir, false);
					char subfilen[64];
					while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
					{
						if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
						{
							if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
							{
								Format(subfilen,sizeof(subfilen),"%s/%s",savedir,subfilen);
								if ((StrContains(subfilen,"autosave.hl",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,szPreviousMap,false) == -1))
								{
									DeleteFile(subfilen,false);
									/*
									Handle subfiletarg = OpenFile(subfilen,"wb");
									if (subfiletarg != INVALID_HANDLE)
									{
										WriteFileLine(subfiletarg,"");
									}
									CloseHandle(subfiletarg);
									*/
								}
							}
						}
					}
					CloseHandle(savedirh);
				}
			}
		}
		if (bTransitionPlayers)
		{
			if (validchange) GetEntPropString(caller,Prop_Data,"m_szLandmarkName",szLandmarkName,sizeof(szLandmarkName));
			findlandmark(-1,"info_landmark");
			findlandmark(-1,"trigger_transition");
			float mins[3];
			float maxs[3];
			if (validchange)
			{
				GetEntPropVector(caller,Prop_Send,"m_vecMins",mins);
				GetEntPropVector(caller,Prop_Send,"m_vecMaxs",maxs);
				float vecOrgs[3];
				if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",vecOrgs);
				else if (HasEntProp(caller,Prop_Data,"m_vecOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecOrigin",vecOrgs);
				mins[0]+=vecOrgs[0];
				mins[1]+=vecOrgs[1];
				mins[2]+=vecOrgs[2];
				maxs[0]+=vecOrgs[0];
				maxs[1]+=vecOrgs[1];
				maxs[2]+=vecOrgs[2];
			}
			// Even if this is not a valid change, alwaystransition entities will be caught by this check.
			findtouchingents(mins,maxs,false);
			if ((hCVLandMarkBox.BoolValue) && (validchange))
			{
				mins[0] = g_vecLandmarkOrigin[0]-hCVLandMarkBoxSize.FloatValue;
				mins[1] = g_vecLandmarkOrigin[1]-hCVLandMarkBoxSize.FloatValue;
				mins[2] = g_vecLandmarkOrigin[2]-hCVLandMarkBoxSize.FloatValue;
				maxs[0] = g_vecLandmarkOrigin[0]+hCVLandMarkBoxSize.FloatValue;
				maxs[1] = g_vecLandmarkOrigin[1]+hCVLandMarkBoxSize.FloatValue;
				maxs[2] = g_vecLandmarkOrigin[2]+hCVLandMarkBoxSize.FloatValue;
				findtouchingents(mins,maxs,false);
			}
			if ((BMActive) || (hCVbTransitionGlobals.BoolValue)) transitionglobals(-1);
			float plyorigin[3];
			float plyangs[3];
			char SteamID[32];
			Handle dp = INVALID_HANDLE;
			int curh,cura;
			char tmp[16];
			char curweap[64];
			char weapname[64];
			char weapnamepamm[64];
			bool bFutureSuit = false;
			// Have to check through all players for suit and possibly other transition information
			for (int i = 1;i<MaxClients+1;i++)
			{
				iRestoreProperty[i][0] = 0;
				iRestoreProperty[i][1] = 0;
				if (IsValidEntity(i))
				{
					if (HasEntProp(i,Prop_Send,"m_bWearingSuit"))
					{
						if (GetEntProp(i,Prop_Send,"m_bWearingSuit"))
						{
							bFutureSuit = true;
							break;
						}
					}
				}
			}
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((IsValidEntity(i)) && (IsClientInGame(i)))
				{
					//GetClientAbsAngles(i,plyangs);
					GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
					if ((strlen(SteamID) < 1) || (StrEqual(SteamID,"STEAM_ID_STOP_IGNORING_RETVALS",false)))
					{
						if (HasEntProp(i,Prop_Data,"m_szNetworkIDString"))
						{
							char searchid[64];
							GetEntPropString(i,Prop_Data,"m_szNetworkIDString",searchid,sizeof(searchid));
							if (strlen(searchid) > 1)
							{
								char Err[100];
								Handle Handle_IDSDB = SQLite_UseDatabase("sourcemod-local",Err,100-1);
								if (!iCreatedTable)
								{
									if (!SQL_FastQuery(Handle_IDSDB,"CREATE TABLE IF NOT EXISTS synbackupids(SteamID VARCHAR(32) NOT NULL PRIMARY KEY,UUID VARCHAR(64) NOT NULL);"))
									{
										PrintToServer("Error in create IDSBackup %s",Err);
										iCreatedTable = 2;
									}
									else iCreatedTable = 1;
								}
								if (iCreatedTable == 1)
								{
									char Querychk[100];
									Format(Querychk,100,"SELECT SteamID FROM synbackupids WHERE UUID = '%s';",searchid);
									Handle HQuery = SQL_Query(Handle_IDSDB,Querychk);
									if (HQuery != INVALID_HANDLE)
									{
										if (SQL_FetchRow(HQuery))
										{
											SQL_FetchString(HQuery,0,SteamID,sizeof(SteamID));
										}
									}
									CloseHandle(HQuery);
								}
								CloseHandle(Handle_IDSDB);
							}
						}
					}
					if ((FindStringInArray(g_hTransitionPlayerOrigin, SteamID) != -1) && (IsPlayerAlive(i)))
					{
						//GetClientAbsOrigin(i, plyorigin);
						if (HasEntProp(i, Prop_Data, "m_vecAbsOrigin")) GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", plyorigin);
						else if (HasEntProp(i, Prop_Send, "m_vecOrigin")) GetEntPropVector(i, Prop_Send, "m_vecOrigin", plyorigin);
						if (HasEntProp(i, Prop_Data, "v_angle")) GetEntPropVector(i, Prop_Data, "v_angle", plyangs);
						else if (HasEntProp(i, Prop_Data, "m_angRotation")) GetEntPropVector(i, Prop_Data, "m_angRotation", plyangs);
						plyorigin[0]-=g_vecLandmarkOrigin[0];
						plyorigin[1]-=g_vecLandmarkOrigin[1];
						plyorigin[2]-=g_vecLandmarkOrigin[2];
					}
					else
					{
						plyorigin[0] = 0.0;
						plyorigin[1] = 0.0;
						plyorigin[2] = 0.0;
					}
					PushArrayString(g_hTransitionIDs, SteamID);
					dp = CreateDataPack();
					if (!IsPlayerAlive(i))
					{
						curh = 0;
						cura = 0;
					}
					else
					{
						curh = GetEntProp(i,Prop_Data,"m_iHealth");
						cura = GetEntProp(i,Prop_Data,"m_ArmorValue");
					}
					WritePackCell(dp,curh);
					WritePackCell(dp,cura);
					int score = 0;
					if (HasEntProp(i,Prop_Data,"m_iPoints")) score = GetEntProp(i,Prop_Data,"m_iPoints");
					int kills = GetEntProp(i,Prop_Data,"m_iFrags");
					int deaths = GetEntProp(i,Prop_Data,"m_iDeaths");
					int suitset = GetEntProp(i,Prop_Send,"m_bWearingSuit");
					if ((!IsPlayerAlive(i)) && (bFutureSuit)) suitset = 1;
					int medkitamm = 0;
					if (HasEntProp(i,Prop_Data,"m_iHealthPack")) medkitamm = GetEntProp(i,Prop_Send,"m_iHealthPack");
					int crouching = GetEntProp(i,Prop_Send,"m_bDucked");
					WritePackCell(dp,score);
					WritePackCell(dp,kills);
					WritePackCell(dp,deaths);
					WritePackCell(dp,suitset);
					WritePackCell(dp,medkitamm);
					WritePackCell(dp,crouching);
					WritePackFloat(dp,plyangs[0]);
					WritePackFloat(dp,plyangs[1]);
					WritePackFloat(dp,plyorigin[0]);
					WritePackFloat(dp,plyorigin[1]);
					WritePackFloat(dp,plyorigin[2]);
					GetClientWeaponAccurate(i,curweap,sizeof(curweap));
					WritePackString(dp,curweap);
					for (int j = 0;j<32;j++)
					{
						int ammchk = GetEntProp(i, Prop_Send, "m_iAmmo", _, j);
						if (ammchk > 0)
						{
							Format(tmp,sizeof(tmp),"%i %i",j,ammchk);
							WritePackString(dp,tmp);
						}
					}
					if (iWeaponListOffset != -1)
					{
						for (int j; j<104; j += 4)
						{
							int tmpi = GetEntDataEnt2(i,iWeaponListOffset + j);
							if (tmpi != -1)
							{
								GetEntityClassname(tmpi,weapname,sizeof(weapname));
								Format(weapnamepamm,sizeof(weapnamepamm),"%s %i",weapname,GetEntProp(tmpi,Prop_Data,"m_iClip1"));
								WritePackString(dp,weapnamepamm);
							}
						}
					}
					/*
					if (HasEntProp(i,Prop_Send,"m_iClass"))
					{
						char clsprop[64];
						Format(clsprop,sizeof(clsprop),"propset m_iClass 1 %i",GetEntProp(i,Prop_Send,"m_iClass"));
						WritePackString(dp,clsprop);
					}
					*/
					WritePackString(dp,"endofpack");
					PushArrayCell(g_hTransitionDataPacks,dp);
					if (g_hCVbDebugTransitions.BoolValue) LogMessage("Transition CL '%N' Transition info Health: %i Armor: %i Ducking: %i Offset %1.f %1.f %1.f",i,curh,cura,crouching,plyorigin[0],plyorigin[1],plyorigin[2]);
					if (hCVbDelTransitionPly.BoolValue) AcceptEntityInput(i, "kill");
				}
			}
		}
		else
		{
			Format(szLandmarkName,sizeof(szLandmarkName),"");
			g_vecLandmarkOrigin[0] = 0.0;
			g_vecLandmarkOrigin[1] = 0.0;
			g_vecLandmarkOrigin[2] = 0.0;
		}
	}
	return Plugin_Continue;
}

void findlandmark(int ent,char[] classname)
{
	int thisent = FindEntityByClassname(ent,classname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char szTargetname[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
		if (StrEqual(szTargetname,szLandmarkName))
		{
			if (StrEqual(classname,"info_landmark",false)) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",g_vecLandmarkOrigin);
			else if (StrEqual(classname,"trigger_transition"))
			{
				float mins[3];
				float maxs[3];
				GetEntPropVector(thisent,Prop_Send,"m_vecMins",mins);
				GetEntPropVector(thisent,Prop_Send,"m_vecMaxs",maxs);
				if (g_hCVbDebugTransitions.BoolValue) LogMessage("Found trigger_transition %s",szTargetname);
				float vecOrgs[3];
				if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",vecOrgs);
				else if (HasEntProp(thisent,Prop_Data,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecOrigin",vecOrgs);
				mins[0]+=vecOrgs[0];
				mins[1]+=vecOrgs[1];
				mins[2]+=vecOrgs[2];
				maxs[0]+=vecOrgs[0];
				maxs[1]+=vecOrgs[1];
				maxs[2]+=vecOrgs[2];
				findtouchingents(mins,maxs,false);
			}
		}
		findlandmark(thisent++,classname);
	}
}

void findtransitionback(int ent)
{
	int thisent = FindEntityByClassname(ent,"trigger_transition");
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char szTargetname[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
		if (StrEqual(szTargetname,szLandmarkName))
		{
			float mins[3];
			float maxs[3];
			GetEntPropVector(thisent,Prop_Send,"m_vecMins",mins);
			GetEntPropVector(thisent,Prop_Send,"m_vecMaxs",maxs);
			if (g_hCVbDebugTransitions.BoolValue) LogMessage("Found trigger_transition %s",szTargetname);
			float vecOrgs[3];
			if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",vecOrgs);
			else if (HasEntProp(thisent,Prop_Data,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecOrigin",vecOrgs);
			mins[0]+=vecOrgs[0];
			mins[1]+=vecOrgs[1];
			mins[2]+=vecOrgs[2];
			maxs[0]+=vecOrgs[0];
			maxs[1]+=vecOrgs[1];
			maxs[2]+=vecOrgs[2];
			findtouchingents(mins,maxs,true);
		}
		findtransitionback(thisent++);
	}
}

void findprevlvls(int ent)
{
	int thisent = FindEntityByClassname(ent,"trigger_changelevel");
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char mapchbuf[64];
		GetEntPropString(thisent,Prop_Data,"m_szMapName",mapchbuf,sizeof(mapchbuf));
		if ((StrEqual(mapchbuf,szPreviousMap,false)) && (!StrEqual(mapchbuf,"d1_town_02",false))) AcceptEntityInput(thisent,"Disable");
		findprevlvls(thisent++);
	}
}

void resetareaportals(int ent)
{
	int thisent = FindEntityByClassname(ent,"func_areaportal");
	if (IsValidEntity(thisent))
	{
		char targ[64];
		GetEntPropString(thisent,Prop_Data,"m_target",targ,sizeof(targ));
		char addinp[72];
		Format(addinp,sizeof(addinp),"Target %s",targ);
		SetVariantString(addinp);
		AcceptEntityInput(thisent,"AddOutput");
		SetEntPropString(thisent,Prop_Data,"m_target",targ);
		if (strlen(targ) > 0)
		{
			int iDoor = FindByTargetName(targ);
			if ((IsValidEntity(iDoor)) && (iDoor != 0))
			{
				if (HasEntProp(iDoor,Prop_Data,"m_eDoorState"))
				{
					if (GetEntProp(iDoor,Prop_Data,"m_eDoorState") == 2)
					{
						AcceptEntityInput(thisent,"Open");
					}
				}
			}
		}
		resetareaportals(thisent++);
	}
}

public int FindByTargetName(char[] entname)
{
	for (int i = MaxClients+1;i<GetMaxEntities()+1;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			if (HasEntProp(i,Prop_Data,"m_iName"))
			{
				char chkname[64];
				GetEntPropString(i,Prop_Data,"m_iName",chkname,sizeof(chkname));
				if (StrEqual(chkname,entname,false))
				{
					return i;
				}
			}
		}
	}
	return -1;
}

void findtouchingents(float mins[3], float maxs[3], bool remove)
{
	char szTargetname[32];
	char mdl[64];
	float vecOrigin[3];
	float angs[3];
	if (maxs[0] < mins[0])
	{
		float tmp = maxs[0];
		maxs[0] = mins[0];
		mins[0] = tmp;
	}
	if (maxs[1] < mins[1])
	{
		float tmp = maxs[1];
		maxs[1] = mins[1];
		mins[1] = tmp;
	}
	if (maxs[2] < mins[2])
	{
		float tmp = maxs[2];
		maxs[2] = mins[2];
		mins[2] = tmp;
	}
	if (maxs[0]-mins[0] < 11.0)
	{
		mins[0]-=15.0;
		maxs[0]+=15.0;
	}
	if (maxs[1]-mins[1] < 11.0)
	{
		mins[1]-=15.0;
		maxs[1]+=15.0;
	}
	if (maxs[2]-mins[2] < 11.0)
	{
		mins[2]-=5.0;
		maxs[2]+=5.0;
	}
	mins[0]-=5.0;
	maxs[0]+=5.0;
	mins[1]-=5.0;
	maxs[1]+=5.0;
	mins[2]-=5.0;
	maxs[2]+=5.0;
	if (g_hCVbDebugTransitions.BoolValue) LogMessage("Transition Mins %1.f %1.f %1.f Maxs %1.f %1.f %1.f", mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);
	char custentinffile[256];
	char writemode[8];
	char parentglobal[16];
	Format(writemode, sizeof(writemode), "a");
	Format(custentinffile, sizeof(custentinffile), "%s\\customenttransitioninf.txt", savedir);
	if (!FileExists(custentinffile,false)) Format(writemode, sizeof(writemode), "w");
	ReplaceString(custentinffile, sizeof(custentinffile), "/", "\\");
	Handle custentlist = INVALID_HANDLE;
	Handle custentinf = INVALID_HANDLE;
	if (SynFixesRunning)
	{
		custentlist = GetCustomEntList();
		custentinf = OpenFile(custentinffile, writemode);
	}
	char szTmp[64];
	float angax[3];
	Handle hDeletedEntities = CreateArray(2048);
	for (int i = 1;i<GetMaxEntities()+1;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i) && (FindValueInArray(g_hIgnoredEntities, i) == -1))
		{
			char clsname[32];
			GetEntityClassname(i, clsname, sizeof(clsname));
			GetEntPropString(i, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));
			if (StrContains(clsname, "game_", false) == 0) continue;
			if ((SynLaterAct) && (!g_hCVbTransitionSkipVersion.BoolValue))
			{
				if (custentlist != INVALID_HANDLE)
				{
					if ((FindStringInArray(custentlist, clsname) == -1) && (!StrEqual(clsname, "player", false)))
					{
						continue;
					}
				}
				else if (!StrEqual(clsname,"player",false)) continue;
			}
			int alwaystransition = 0;
			if (HasEntProp(i, Prop_Data, "m_bAlwaysTransition")) alwaystransition = GetEntProp(i, Prop_Data, "m_bAlwaysTransition");
			if (HasEntProp(i, Prop_Data, "m_vecAbsOrigin")) GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vecOrigin);
			else if (HasEntProp(i, Prop_Send, "m_vecOrigin")) GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin);
			if ((i < MaxClients+1) && (i > 0))
			{
				if (IsPlayerAlive(i))
				{
					GetClientAbsOrigin(i,vecOrigin);
					if (GetEntityRenderFx(i) == RENDERFX_DISTORT) alwaystransition = 1;
				}
			}
			if (StrEqual(clsname,"prop_door_rotating",false))
			{
				if ((StrEqual(szTargetname, "door.into.09.garage", false)) || (StrEqual(szTargetname, "door_2", false)) || (SynLaterAct))
				{
					PushArrayCell(g_hIgnoredEntities, i);
					continue;
				}
			}
			else if (StrEqual(clsname,"syn_transition_wall",false))
			{
				PushArrayCell(g_hIgnoredEntities, i);
				continue;
			}
			else if (StrEqual(clsname,"prop_dynamic",false))
			{
				if (StrContains(szTargetname,"antirush",false) != -1)
				{
					PushArrayCell(g_hIgnoredEntities, i);
					continue;
				}
			}
			else if (StrEqual(clsname,"point_viewcontrol",false))
			{
				PushArrayCell(g_hIgnoredEntities, i);
				continue;
			}
			if ((StrEqual(clsname,"npc_alyx",false)) || (StrEqual(clsname,"npc_vortigaunt",false)) || (StrEqual(clsname,"prop_vehicle_jeep_episodic",false)))
			{
				if ((!StrEqual(mapbuf,"d1_town_05",false)) || (SynLaterAct))
				{
					if ((StrEqual(szTargetname,"alyx",false)) || (StrEqual(szTargetname,"vort",false)) || (StrEqual(szTargetname,"jeep",false)))
						alwaystransition = 1;
				}
			}
			else if ((StrEqual(clsname,"npc_monk",false)) && (StrEqual(mapbuf,"d1_town_02",false)) && (StrEqual(szNextMap,"d1_town_02a",false)))
			{
				alwaystransition = 1;
			}
			else if (StrEqual(clsname,"npc_manhack",false))
			{
				if (StrContains(szTargetname,"STEAM_0",false) != -1)
				{
					PushArrayCell(g_hIgnoredEntities,i);
					continue;
				}
			}
			int par = -1;
			//if ((StrEqual(clsname,"prop_dynamic",false)) || (StrEqual(clsname,"prop_physics",false)))
			if (HasEntProp(i,Prop_Data,"m_hParent"))
			{
				par = GetEntPropEnt(i,Prop_Data,"m_hParent");
				if (IsValidEntity(par))
				{
					if (HasEntProp(par,Prop_Data,"m_iGlobalname")) GetEntPropString(par,Prop_Data,"m_iGlobalname",parentglobal,sizeof(parentglobal));
					if (strlen(parentglobal) > 1)
					{
						//PrintToServer("Alwaystransition %i %s %s",i,clsname,parentglobal);
						alwaystransition = 1;
					}
				}
			}
			if (alwaystransition != -1)
			{
				if ((alwaystransition) || ((vecOrigin[0] > mins[0]) && (vecOrigin[1] > mins[1]) && (vecOrigin[2] > mins[2]) && (vecOrigin[0] < maxs[0]) && (vecOrigin[1] < maxs[1]) && (vecOrigin[2] < maxs[2]) && (IsValidEntity(i))))
				{
					//Add func_tracktrain check if exists on next map OnTransition might not fire
					bool bPasschk = false;
					if (!g_hCVbTransitionMode.BoolValue)
					{
						if (((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_",false) != -1) || (StrContains(clsname,"item_",false) != -1) || (StrContains(clsname,"weapon_",false) != -1)) && (!StrEqual(clsname,"item_ammo_drop",false)) && (!StrEqual(clsname,"item_ammo_pack",false)) && (!StrEqual(clsname,"item_health_drop",false)) && (!StrEqual(clsname,"npc_template_maker",false)) && (!StrEqual(clsname,"npc_barnacle_tongue_tip",false)) && (!StrEqual(clsname,"light_dynamic",false)) && (!StrEqual(clsname,"info_particle_system",false)) && (!StrEqual(clsname,"npc_maker",false)) && (!StrEqual(clsname,"npc_antlion_template_maker",false)) && (!StrEqual(clsname,"npc_heli_avoidsphere",false)) && (StrContains(clsname,"env_",false) == -1) && (!StrEqual(clsname,"info_landmark",false)) && (!StrEqual(clsname,"shadow_control",false)) && (!StrEqual(clsname,"player",false)) && (StrContains(clsname,"light_",false) == -1) && (!StrEqual(clsname,"predicted_viewmodel",false)))
						{
							bPasschk = true;
						}
					}
					else if ((!StrEqual(clsname,"player_loadsaved",false)) && (!StrEqual(clsname,"path_track",false)) && (!StrEqual(clsname,"npc_template_maker",false)) && (StrContains(clsname,"rope",false) == -1) && (StrContains(clsname,"phys",false) != 0) && (!StrEqual(clsname,"item_ammo_drop",false)) && (!StrEqual(clsname,"item_ammo_pack",false)) && (!StrEqual(clsname,"item_health_drop",false)) && (!StrEqual(clsname,"beam",false)) && (!StrEqual(clsname,"npc_barnacle_tongue_tip",false)) && (!StrEqual(clsname,"info_particle_system",false)) && (!StrEqual(clsname,"npc_maker",false)) && (!StrEqual(clsname,"npc_antlion_template_maker",false)) && (!StrEqual(clsname,"npc_heli_avoidsphere",false)) && (StrContains(clsname,"env_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (!StrEqual(clsname,"info_landmark",false)) && (!StrEqual(clsname,"shadow_control",false)) && (!StrEqual(clsname,"player",false)) && (StrContains(clsname,"light_",false) == -1) && (!StrEqual(clsname,"point_spotlight",false)) && (!StrEqual(clsname,"predicted_viewmodel",false)))
					{
						bPasschk = true;
					}
					if (bPasschk)
					{
						if (HasEntProp(i,Prop_Data,"m_ModelName")) GetEntPropString(i,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if ((StrContains(mdl,"*",false) != -1) || (StrContains(mdl,"transition",false) != -1))
						{
							//LogError("Attempt to transition ent with precached model %s %s",clsname,mdl);
							PushArrayCell(g_hIgnoredEntities,i);
						}
						else
						{
							if ((remove) && (i > MaxClients))
							{
								AcceptEntityInput(i, "kill");
							}
							else
							{
								if (HasEntProp(i,Prop_Data,"m_hTargetEnt"))
								{
									int targent = GetEntPropEnt(i,Prop_Data,"m_hTargetEnt");
									if ((IsValidEntity(targent)) && (IsEntNetworkable(targent)))
									{
										char targentcls[24];
										GetEntityClassname(targent,targentcls,sizeof(targentcls));
										if ((StrEqual(targentcls,"scripted_sequence",false)) && (!StrEqual(mapbuf,"d2_prison_08",false)))
											transitionthisent(targent);
									}
								}
								bool transitionthis = true;
								Handle dp = CreateDataPack();
								vecOrigin[0]-=g_vecLandmarkOrigin[0];
								vecOrigin[1]-=g_vecLandmarkOrigin[1];
								vecOrigin[2]-=g_vecLandmarkOrigin[2];
								int curh = 0;
								char vehscript[64];
								char additionalequip[32];
								char spawnflags[32];
								char skin[4];
								char hdwtype[4];
								char parentname[32];
								char state[4];
								char target[32];
								char npctype[4];
								char npctargpath[64];
								char npctarg[64];
								char solidity[4];
								char defanim[32];
								char response[64];
								char scriptinf[1280];
								int iDoorState, iSleepState, bGunEnable, tkdmg, mvtype, gameend;
								if (HasEntProp(i,Prop_Data,"m_iHealth")) curh = GetEntProp(i,Prop_Data,"m_iHealth");
								if (HasEntProp(i,Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",angs);
								if (HasEntProp(i,Prop_Data,"m_vehicleScript")) GetEntPropString(i,Prop_Data,"m_vehicleScript",vehscript,sizeof(vehscript));
								if (HasEntProp(i,Prop_Data,"m_spawnEquipment")) GetEntPropString(i,Prop_Data,"m_spawnEquipment",additionalequip,sizeof(additionalequip));
								if (HasEntProp(i,Prop_Data,"m_spawnflags"))
								{
									int sf = GetEntProp(i,Prop_Data,"m_spawnflags");
									Format(spawnflags,sizeof(spawnflags),"%i",sf);
								}
								if (HasEntProp(i,Prop_Data,"m_nSkin"))
								{
									int sk = GetEntProp(i,Prop_Data,"m_nSkin");
									Format(skin,sizeof(skin),"%i",sk);
								}
								if (HasEntProp(i,Prop_Data,"m_nHardwareType"))
								{
									int hdw = GetEntProp(i,Prop_Data,"m_nHardwareType");
									Format(hdwtype,sizeof(hdwtype),"%i",hdw);
								}
								if (StrContains(mdl,"weapons/v_",false) != -1)
								{
									if (dp != INVALID_HANDLE) CloseHandle(dp);
									dp = INVALID_HANDLE;
									transitionthis = false;
									PushArrayCell(g_hIgnoredEntities,i);
								}
								if (par != -1)
								{
									if (StrContains(clsname,"weapon_",false) != -1)
									{
										if (dp != INVALID_HANDLE) CloseHandle(dp);
										dp = INVALID_HANDLE;
										transitionthis = false;
										PushArrayCell(g_hIgnoredEntities,i);
									}
									else
									{
										GetEntPropString(par,Prop_Data,"m_iName",parentname,sizeof(parentname));
										if (HasEntProp(par,Prop_Data,"m_iGlobalname")) GetEntPropString(par,Prop_Data,"m_iGlobalname",parentglobal,sizeof(parentglobal));
										if ((!StrEqual(parentname,"train_model",false)) && (strlen(parentglobal) < 1))
										{
											char parentcls[32];
											GetEntityClassname(par,parentcls,sizeof(parentcls));
											if (((StrEqual(parentcls,"func_door",false)) || (StrEqual(parentcls,"func_tracktrain",false))) || (StrContains(clsname,"npc_",false) == -1))
											{
												if (dp != INVALID_HANDLE) CloseHandle(dp);
												dp = INVALID_HANDLE;
												transitionthis = false;
												PushArrayCell(g_hIgnoredEntities,i);
											}
										}
										if (HasEntProp(i,Prop_Data,"m_vecOrigin"))
										{
											float resetoffs[3];
											GetEntPropVector(i,Prop_Data,"m_vecOrigin",resetoffs);
											Format(scriptinf,sizeof(scriptinf),"%sm_vecOrigin \"%1.f %1.f %1.f\" ",scriptinf,resetoffs[0],resetoffs[1],resetoffs[2]);
										}
									}
								}
								if (StrEqual(mdl,"models/alyx_emptool_prop.mdl"))
								{
									if (dp != INVALID_HANDLE) CloseHandle(dp);
									dp = INVALID_HANDLE;
									transitionthis = false;
									PushArrayCell(g_hIgnoredEntities,i);
								}
								if (HasEntProp(i,Prop_Data,"m_state"))
								{
									int istate = GetEntProp(i,Prop_Data,"m_state");
									Format(state,sizeof(state),"%i",istate);
									//PrintToServer("State %s",state);
								}
								if (HasEntProp(i,Prop_Data,"m_hTargetEnt"))
								{
									int targent = GetEntPropEnt(i,Prop_Data,"m_hTargetEnt");
									if ((IsValidEntity(targent)) && (IsEntNetworkable(targent)))
									{
										if (HasEntProp(targent,Prop_Data,"m_iName")) GetEntPropString(targent,Prop_Data,"m_iName",npctarg,sizeof(npctarg));
										if (strlen(npctarg) < 1) Format(npctarg,sizeof(npctarg),"%i",targent);
									}
								}
								if (HasEntProp(i,Prop_Data,"m_target"))
								{
									PropFieldType type;
									FindDataMapInfo(i,"m_target",type);
									if (type == PropField_String)
									{
										GetEntPropString(i,Prop_Data,"m_target",target,sizeof(target));
									}
									else if ((type == PropField_Entity) && (strlen(npctarg) < 1))
									{
										int targent = GetEntPropEnt(i,Prop_Data,"m_target");
										if (targent != -1) Format(npctarg,sizeof(npctarg),"%i",targent);
									}
									if ((strlen(npctargpath) < 1) && (HasEntProp(i,Prop_Data,"m_vecDesiredPosition")))
									{
										float findtargetpos[3];
										GetEntPropVector(i,Prop_Data,"m_vecDesiredPosition",findtargetpos);
										char findpath[128];
										findpathtrack(-1,findtargetpos,findpath);
										if (strlen(findpath) > 0) Format(npctargpath,sizeof(npctargpath),"%s",findpath);
									}
								}
								if (HasEntProp(i,Prop_Data,"m_eDoorState")) iDoorState = GetEntProp(i,Prop_Data,"m_eDoorState");
								if (HasEntProp(i,Prop_Data,"m_SleepState")) iSleepState = GetEntProp(i,Prop_Data,"m_SleepState");
								if (HasEntProp(i,Prop_Data,"m_Type"))
								{
									int inpctype = GetEntProp(i,Prop_Data,"m_Type");
									Format(npctype,sizeof(npctype),"%i",inpctype);
								}
								if (HasEntProp(i,Prop_Data,"m_nSolidType"))
								{
									int solidtype = GetEntProp(i,Prop_Data,"m_nSolidType");
									Format(solidity,sizeof(solidity),"%i",solidtype);
								}
								if (HasEntProp(i,Prop_Data,"m_bHasGun")) bGunEnable = GetEntProp(i,Prop_Data,"m_bHasGun");
								if (HasEntProp(i,Prop_Data,"m_takedamage")) tkdmg = GetEntProp(i,Prop_Data,"m_takedamage");
								if (HasEntProp(i,Prop_Data,"movetype")) mvtype = GetEntProp(i,Prop_Data,"movetype");
								if (HasEntProp(i,Prop_Data,"m_bGameEndAlly")) gameend = GetEntProp(i,Prop_Data,"m_bGameEndAlly");
								if (HasEntProp(i,Prop_Data,"m_iszDefaultAnim")) GetEntPropString(i,Prop_Data,"m_iszDefaultAnim",defanim,sizeof(defanim));
								if (HasEntProp(i,Prop_Data,"m_vecAxis"))
								{
									GetEntPropVector(i,Prop_Data,"m_vecAxis",angax);
									Format(scriptinf,sizeof(scriptinf),"%saxis \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
								}
								if (HasEntProp(i,Prop_Data,"m_flDistance"))
								{
									float dist = GetEntPropFloat(i,Prop_Data,"m_flDistance");
									Format(scriptinf,sizeof(scriptinf),"%sdistance %1.f ",scriptinf,dist);
								}
								if (HasEntProp(i,Prop_Data,"m_flSpeed"))
								{
									float flSpeed = GetEntPropFloat(i,Prop_Data,"m_flSpeed");
									if (flSpeed > 0.0) Format(scriptinf,sizeof(scriptinf),"%sspeed %1.f ",scriptinf,flSpeed);
								}
								if (HasEntProp(i,Prop_Data,"m_angRotationClosed"))
								{
									GetEntPropVector(i,Prop_Data,"m_angRotationClosed",angax);
									Format(scriptinf,sizeof(scriptinf),"%sm_angRotationClosed \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
								}
								if (HasEntProp(i,Prop_Data,"m_angRotationOpenForward"))
								{
									GetEntPropVector(i,Prop_Data,"m_angRotationOpenForward",angax);
									Format(scriptinf,sizeof(scriptinf),"%sm_angRotationOpenForward \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
								}
								if (HasEntProp(i,Prop_Data,"m_angRotationOpenBack"))
								{
									GetEntPropVector(i,Prop_Data,"m_angRotationOpenBack",angax);
									Format(scriptinf,sizeof(scriptinf),"%sm_angRotationOpenBack \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
								}
								if (HasEntProp(i,Prop_Data,"m_angGoal"))
								{
									GetEntPropVector(i,Prop_Data,"m_angGoal",angax);
									Format(scriptinf,sizeof(scriptinf),"%sm_angGoal \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
								}
								if (HasEntProp(i,Prop_Data,"m_iszMagnetName"))
								{
									char magname[64];
									GetEntPropString(i,Prop_Data,"m_iszMagnetName",magname,sizeof(magname));
									Format(scriptinf,sizeof(scriptinf),"%sm_iszMagnetName %s ",scriptinf,magname);
								}
								if (HasEntProp(i,Prop_Data,"m_vecPlayerMountPositionTop"))
								{
									GetEntPropVector(i,Prop_Data,"m_vecPlayerMountPositionTop",angax);
									Format(scriptinf,sizeof(scriptinf),"%sm_vecPlayerMountPositionTop \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
									GetEntPropVector(i,Prop_Data,"m_vecPlayerMountPositionBottom",angax);
									Format(scriptinf,sizeof(scriptinf),"%sm_vecPlayerMountPositionBottom \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
								}
								if (HasEntProp(i,Prop_Data,"m_iszSound"))
								{
									GetEntPropString(i,Prop_Data,"m_iszSound",szTmp,sizeof(szTmp));
									Format(scriptinf,sizeof(scriptinf),"%sm_iszSound %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_sSourceEntName"))
								{
									GetEntPropString(i,Prop_Data,"m_sSourceEntName",szTmp,sizeof(szTmp));
									Format(scriptinf,sizeof(scriptinf),"%sm_sSourceEntName %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszSceneFile"))
								{
									GetEntPropString(i,Prop_Data,"m_iszSceneFile",szTmp,sizeof(szTmp));
									Format(scriptinf,sizeof(scriptinf),"%sm_iszSceneFile %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_nAmmoType"))
								{
									Format(scriptinf,sizeof(scriptinf),"%sm_nAmmoType %i ",scriptinf,GetEntProp(i,Prop_Data,"m_nAmmoType"));
								}
								if (HasEntProp(i,Prop_Data,"m_CrateType"))
								{
									Format(scriptinf,sizeof(scriptinf),"%sm_CrateType %i ",scriptinf,GetEntProp(i,Prop_Data,"m_CrateType"));
								}
								if (HasEntProp(i,Prop_Data,"m_nItemCount"))
								{
									Format(scriptinf,sizeof(scriptinf),"%sm_nItemCount %i ",scriptinf,GetEntProp(i,Prop_Data,"m_nItemCount"));
								}
								if (HasEntProp(i,Prop_Data,"m_strItemClass"))
								{
									GetEntPropString(i,Prop_Data,"m_strItemClass",szTmp,sizeof(szTmp));
									Format(scriptinf,sizeof(scriptinf),"%sm_strItemClass %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_clrRender"))
								{
									if (GetEntProp(i,Prop_Data,"m_clrRender") != -1)
									{
										int iOffs = GetEntSendPropOffs(i,"m_clrRender");
										if (iOffs != -1)
										{
											Format(scriptinf,sizeof(scriptinf),"%sm_clrRender %i %i %i %i ",scriptinf,GetEntData(i,iOffs, 1),GetEntData(i,iOffs + 1, 1),GetEntData(i,iOffs + 2, 1),GetEntData(i,iOffs + 3, 1));
										}
									}
								}
								if (HasEntProp(i,Prop_Data,"m_flModelScale"))
								{
									if (GetEntPropFloat(i,Prop_Data,"m_flModelScale") != 1.0)
									{
										Format(scriptinf,sizeof(scriptinf),"%sm_flModelScale %1.1f ",scriptinf,GetEntPropFloat(i,Prop_Data,"m_flModelScale"));
									}
								}
								if (HasEntProp(i,Prop_Data,"m_iszResumeSceneFile"))
								{
									GetEntPropString(i,Prop_Data,"m_iszResumeSceneFile",szTmp,sizeof(szTmp));
									Format(scriptinf,sizeof(scriptinf),"%sm_iszResumeSceneFile %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszTarget1"))
								{
									for (int j = 1;j<9;j++)
									{
										Format(szTmp,sizeof(szTmp),"m_iszTarget%i",j);
										if (HasEntProp(i,Prop_Data,szTmp))
										{
											GetEntPropString(i,Prop_Data,szTmp,szTmp,sizeof(szTmp));
											Format(scriptinf,sizeof(scriptinf),"%sm_iszTarget%i %s ",scriptinf,j,szTmp);
										}
									}
								}
								if (HasEntProp(i,Prop_Data,"m_iszEntry"))
								{
									GetEntPropString(i,Prop_Data,"m_iszEntry",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszEntry %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszPreIdle"))
								{
									GetEntPropString(i,Prop_Data,"m_iszPreIdle",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPreIdle %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszPlay"))
								{
									GetEntPropString(i,Prop_Data,"m_iszPlay",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPlay %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszPostIdle"))
								{
									GetEntPropString(i,Prop_Data,"m_iszPostIdle",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPostIdle %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszCustomMove"))
								{
									GetEntPropString(i,Prop_Data,"m_iszCustomMove",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszCustomMove %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszNextScript"))
								{
									GetEntPropString(i,Prop_Data,"m_iszNextScript",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszNextScript %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_iszEntity"))
								{
									GetEntPropString(i,Prop_Data,"m_iszEntity",szTmp,sizeof(szTmp));
									if (strlen(szTmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszEntity %s ",scriptinf,szTmp);
								}
								if (HasEntProp(i,Prop_Data,"m_fMoveTo"))
								{
									int scrtmpi = GetEntProp(i,Prop_Data,"m_fMoveTo");
									Format(scriptinf,sizeof(scriptinf),"%sm_fMoveTo %i ",scriptinf,scrtmpi);
								}
								if ((HasEntProp(i,Prop_Data,"m_iszEffectName")) && (strlen(mdl) < 1))
								{
									GetEntPropString(i,Prop_Data,"m_iszEffectName",mdl,sizeof(mdl));
								}
								if (HasEntProp(i,Prop_Data,"m_iszResponseContext"))
								{
									GetEntPropString(i,Prop_Data,"m_iszResponseContext",response,sizeof(response));
								}
								TrimString(scriptinf);
								if (transitionthis)
								{
									bool custenttransition = false;
									if ((custentlist != INVALID_HANDLE) && (SynFixesRunning))
									{
										if (FindStringInArray(custentlist,clsname) != -1) custenttransition = true;
									}
									if (custenttransition)
									{
										int sequence, body, parentattach, maxh;
										char spawnercls[64];
										char szChildSpawnTargetname[64];
										if (HasEntProp(i,Prop_Data,"m_iMaxHealth")) maxh = GetEntProp(i,Prop_Data,"m_iMaxHealth");
										if (HasEntProp(i,Prop_Data,"m_iszNPCClassname")) GetEntPropString(i,Prop_Data,"m_iszNPCClassname",spawnercls,sizeof(spawnercls));
										if (HasEntProp(i,Prop_Data,"m_ChildTargetName")) GetEntPropString(i,Prop_Data,"m_ChildTargetName",szChildSpawnTargetname,sizeof(szChildSpawnTargetname));
										if (HasEntProp(i,Prop_Data,"m_nSequence")) sequence = GetEntProp(i,Prop_Data,"m_nSequence");
										if (HasEntProp(i,Prop_Data,"m_iParentAttachment")) parentattach = GetEntProp(i,Prop_Data,"m_iParentAttachment");
										if (HasEntProp(i,Prop_Data,"m_nBody")) body = GetEntProp(i,Prop_Data,"m_nBody");
										WriteFileLine(custentinf,"{");
										char pushch[256];
										Format(pushch,sizeof(pushch),"\"origin\" \"%f %f %f\"",vecOrigin[0],vecOrigin[1],vecOrigin[2]);
										WriteFileLine(custentinf,pushch);
										Format(pushch,sizeof(pushch),"\"angles\" \"%f %f %f\"",angs[0],angs[1],angs[2]);
										WriteFileLine(custentinf,pushch);
										if (strlen(vehscript) > 0)
										{
											Format(pushch,sizeof(pushch),"\"vehiclescript\" \"%s\"",vehscript);
											WriteFileLine(custentinf,pushch);
										}
										Format(pushch,sizeof(pushch),"\"spawnflags\" \"%s\"",spawnflags);
										WriteFileLine(custentinf,pushch);
										if (strlen(szTargetname) > 0)
										{
											Format(pushch,sizeof(pushch),"\"targetname\" \"%s\"",szTargetname);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(mdl) > 0)
										{
											Format(pushch,sizeof(pushch),"\"model\" \"%s\"",mdl);
											WriteFileLine(custentinf,pushch);
										}
										if (iSleepState != -10)
										{
											Format(pushch,sizeof(pushch),"\"sleepstate\" \"%i\"",iSleepState);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(additionalequip) > 0)
										{
											Format(pushch,sizeof(pushch),"\"additionalequipment\" \"%s\"",additionalequip);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(parentname) > 0)
										{
											Format(pushch,sizeof(pushch),"\"parentname\" \"%s\"",parentname);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(npctarg) > 0)
										{
											Format(pushch,sizeof(pushch),"\"targetentity\" \"%s\"",npctarg);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(npctargpath) > 0)
										{
											Format(pushch,sizeof(pushch),"\"target\" \"%s\"",npctargpath);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(defanim) > 0)
										{
											Format(pushch,sizeof(pushch),"\"DefaultAnim\" \"%s\"",defanim);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(spawnercls) > 0)
										{
											Format(pushch,sizeof(pushch),"\"NPCType\" \"%s\"",spawnercls);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(szChildSpawnTargetname) > 0)
										{
											Format(pushch,sizeof(pushch),"\"NPCTargetname\" \"%s\"",szChildSpawnTargetname);
											WriteFileLine(custentinf,pushch);
										}
										if (curh != 0)
										{
											Format(pushch,sizeof(pushch),"\"health\" \"%i\"",curh);
											WriteFileLine(custentinf,pushch);
										}
										if (maxh != 0)
										{
											Format(pushch,sizeof(pushch),"\"max_health\" \"%i\"",maxh);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(skin) > 0)
										{
											Format(pushch,sizeof(pushch),"\"skin\" \"%s\"",skin);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(hdwtype) > 0)
										{
											Format(pushch,sizeof(pushch),"\"hardware\" \"%s\"",hdwtype);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(state) > 0)
										{
											Format(pushch,sizeof(pushch),"\"npcstate\" \"%s\"",state);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(npctype) > 0)
										{
											Format(pushch,sizeof(pushch),"\"citizentype\" \"%s\"",npctype);
											WriteFileLine(custentinf,pushch);
										}
										if (iDoorState != 0)
										{
											Format(pushch,sizeof(pushch),"\"doorstate\" \"%i\"",iDoorState);
											WriteFileLine(custentinf,pushch);
										}
										if (sequence != 0)
										{
											Format(pushch,sizeof(pushch),"\"sequence\" \"%i\"",sequence);
											WriteFileLine(custentinf,pushch);
										}
										if (parentattach != 0)
										{
											Format(pushch,sizeof(pushch),"\"parentattachment\" \"%i\"",parentattach);
											WriteFileLine(custentinf,pushch);
										}
										if (body != 0)
										{
											Format(pushch,sizeof(pushch),"\"body\" \"%i\"",body);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(response) > 0)
										{
											Format(pushch,sizeof(pushch),"\"ResponseContext\" \"%s\"",response);
											WriteFileLine(custentinf,pushch);
										}
										Format(pushch,sizeof(pushch),"\"classname\" \"%s\"",clsname);
										WriteFileLine(custentinf,pushch);
										WriteFileLine(custentinf,"}");
									}
									else
									{
										WritePackString(dp,clsname);
										WritePackString(dp,szTargetname);
										WritePackString(dp,mdl);
										WritePackCell(dp,curh);
										WritePackFloat(dp,vecOrigin[0]);
										WritePackFloat(dp,vecOrigin[1]);
										WritePackFloat(dp,vecOrigin[2]);
										WritePackFloat(dp,angs[0]);
										WritePackFloat(dp,angs[1]);
										WritePackFloat(dp,angs[2]);
										WritePackString(dp,vehscript);
										WritePackString(dp,spawnflags);
										WritePackString(dp,additionalequip);
										WritePackString(dp,skin);
										WritePackString(dp,hdwtype);
										WritePackString(dp,parentname);
										WritePackString(dp,state);
										WritePackString(dp,npctargpath);
										WritePackCell(dp,iDoorState);
										WritePackCell(dp,iSleepState);
										WritePackString(dp,npctype);
										WritePackString(dp,solidity);
										WritePackCell(dp,bGunEnable);
										WritePackCell(dp,tkdmg);
										WritePackCell(dp,mvtype);
										WritePackCell(dp,gameend);
										WritePackString(dp,defanim);
										WritePackString(dp,response);
										if (strlen(scriptinf) > 0) WritePackString(dp,scriptinf);
										WritePackString(dp,"endofpack");
										PushArrayCell(g_hTransitionEntities,dp);
									}
									PushArrayCell(g_hIgnoredEntities,i);
									if (g_hCVbDebugTransitions.BoolValue) LogMessage("Save Transition %s TargetName \"%s\" Model \"%s\" Offset \"%1.f %1.f %1.f\"",clsname,szTargetname,mdl,vecOrigin[0],vecOrigin[1],vecOrigin[2]);
									if (hCVbDelTransitionEnts.BoolValue) PushArrayCell(hDeletedEntities, i);
								}
							}
						}
					}
					else if ((StrEqual(clsname,"player",false)) && (!remove))
					{
						char SteamID[32];
						GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
						if ((strlen(SteamID) < 1) || (StrEqual(SteamID,"STEAM_ID_STOP_IGNORING_RETVALS",false)))
						{
							if (HasEntProp(i,Prop_Data,"m_szNetworkIDString"))
							{
								char searchid[64];
								GetEntPropString(i,Prop_Data,"m_szNetworkIDString",searchid,sizeof(searchid));
								if (strlen(searchid) > 1)
								{
									char Err[100];
									Handle Handle_IDSDB = SQLite_UseDatabase("sourcemod-local",Err,100-1);
									if (!iCreatedTable)
									{
										if (!SQL_FastQuery(Handle_IDSDB,"CREATE TABLE IF NOT EXISTS synbackupids(SteamID VARCHAR(32) NOT NULL PRIMARY KEY,UUID VARCHAR(64) NOT NULL);"))
										{
											PrintToServer("Error in create IDSBackup %s",Err);
											iCreatedTable = 2;
										}
										else iCreatedTable = 1;
									}
									if (iCreatedTable == 1)
									{
										char Querychk[100];
										Format(Querychk,100,"SELECT SteamID FROM synbackupids WHERE UUID = '%s';",searchid);
										Handle HQuery = SQL_Query(Handle_IDSDB,Querychk);
										if (HQuery != INVALID_HANDLE)
										{
											if (SQL_FetchRow(HQuery))
											{
												SQL_FetchString(HQuery,0,SteamID,sizeof(SteamID));
											}
										}
										CloseHandle(HQuery);
									}
									CloseHandle(Handle_IDSDB);
								}
							}
						}
						PushArrayString(g_hTransitionPlayerOrigin,SteamID);
					}
				}
			}
		}
	}
	CloseHandle(custentlist);
	CloseHandle(custentinf);
	if (FileExists(custentinffile,false))
	{
		if (FileSize(custentinffile,false) < 1)
		{
			DeleteFile(custentinffile,false);
		}
	}
	if (hCVbDelTransitionEnts.BoolValue)
	{
		if (GetArraySize(hDeletedEntities))
		{
			for (int i = 0; i < GetArraySize(hDeletedEntities); i++)
			{
				int j = GetArrayCell(hDeletedEntities, i);
				if ((IsValidEntity(j)) && (j != 0)) AcceptEntityInput(j, "kill");
			}
		}
	}
	CloseHandle(hDeletedEntities);
}

void transitionglobals(int ent)
{
	int thisent = FindEntityByClassname(ent,"env_global");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char m_globalstate[64];
		if (HasEntProp(thisent,Prop_Data,"m_globalstate")) GetEntPropString(thisent,Prop_Data,"m_globalstate",m_globalstate,sizeof(m_globalstate));
		if (GetArraySize(g_hGlobalsTransition) > 0)
		{
			char szGlobalState[64];
			for (int i = 0;i<GetArraySize(g_hGlobalsTransition);i++)
			{
				Handle dp = GetArrayCell(g_hGlobalsTransition,i);
				if (dp != INVALID_HANDLE)
				{
					ResetPack(dp);
					ReadPackString(dp,szGlobalState,sizeof(szGlobalState));
					if (StrEqual(m_globalstate,szGlobalState,false))
					{
						CloseHandle(dp);
						RemoveFromArray(g_hGlobalsTransition,i);
						break;
					}
				}
			}
		}
		char m_iName[64];
		int m_triggermode,m_initialstate,m_counter,m_fEffects,m_lifeState,m_iHealth,m_iMaxHealth,m_iEFlags,m_spawnflags,m_fFlags;
		Handle globaldp = CreateDataPack();
		if (HasEntProp(thisent,Prop_Data,"m_iName")) GetEntPropString(thisent,Prop_Data,"m_iName",m_iName,sizeof(m_iName));
		if (HasEntProp(thisent,Prop_Data,"m_triggermode")) m_triggermode = GetEntProp(thisent,Prop_Data,"m_triggermode");
		if (HasEntProp(thisent,Prop_Data,"m_initialstate")) m_initialstate = GetEntProp(thisent,Prop_Data,"m_initialstate");
		if (HasEntProp(thisent,Prop_Data,"m_counter")) m_counter = GetEntProp(thisent,Prop_Data,"m_counter");
		if (HasEntProp(thisent,Prop_Data,"m_fEffects")) m_fEffects = GetEntProp(thisent,Prop_Data,"m_fEffects");
		if (HasEntProp(thisent,Prop_Data,"m_lifeState")) m_lifeState = GetEntProp(thisent,Prop_Data,"m_lifeState");
		if (HasEntProp(thisent,Prop_Data,"m_iHealth")) m_iHealth = GetEntProp(thisent,Prop_Data,"m_iHealth");
		if (HasEntProp(thisent,Prop_Data,"m_iMaxHealth")) m_iMaxHealth = GetEntProp(thisent,Prop_Data,"m_iMaxHealth");
		if (HasEntProp(thisent,Prop_Data,"m_iEFlags")) m_iEFlags = GetEntProp(thisent,Prop_Data,"m_iEFlags");
		if (HasEntProp(thisent,Prop_Data,"m_spawnflags")) m_spawnflags = GetEntProp(thisent,Prop_Data,"m_spawnflags");
		if (HasEntProp(thisent,Prop_Data,"m_fFlags")) m_fFlags = GetEntProp(thisent,Prop_Data,"m_fFlags");
		WritePackString(globaldp,m_globalstate);
		WritePackString(globaldp,m_iName);
		WritePackCell(globaldp,m_triggermode);
		WritePackCell(globaldp,m_initialstate);
		WritePackCell(globaldp,m_counter);
		WritePackCell(globaldp,m_fEffects);
		WritePackCell(globaldp,m_lifeState);
		WritePackCell(globaldp,m_iHealth);
		WritePackCell(globaldp,m_iMaxHealth);
		WritePackCell(globaldp,m_iEFlags);
		WritePackCell(globaldp,m_spawnflags);
		WritePackCell(globaldp,m_fFlags);
		PushArrayCell(g_hGlobalsTransition,globaldp);
		transitionglobals(thisent++);
	}
}

void transitionthisent(int i)
{
	if (!IsValidEntity(i)) return;
	char clsname[32];
	GetEntityClassname(i,clsname,sizeof(clsname));
	char szTargetname[32];
	char mdl[64];
	float vecOrigin[3];
	float angs[3];
	if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",vecOrigin);
	else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",vecOrigin);
	Handle dp = CreateDataPack();
	vecOrigin[0]-=g_vecLandmarkOrigin[0];
	vecOrigin[1]-=g_vecLandmarkOrigin[1];
	vecOrigin[2]-=g_vecLandmarkOrigin[2];
	GetEntPropString(i,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
	int curh = 0;
	char vehscript[64];
	char additionalequip[32];
	char spawnflags[32];
	char skin[4];
	char hdwtype[4];
	char parentname[32];
	char state[4];
	char target[32];
	char npctype[4];
	char solidity[4];
	char response[64];
	char scriptinf[1280];
	char scrtmp[64];
	char defanim[32];
	int iDoorState, iSleepState, bGunEnable, tkdmg, mvtype, gameend;
	if (HasEntProp(i,Prop_Data,"m_iHealth")) curh = GetEntProp(i,Prop_Data,"m_iHealth");
	if (HasEntProp(i,Prop_Data,"m_ModelName")) GetEntPropString(i,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
	if (HasEntProp(i,Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",angs);
	if (HasEntProp(i,Prop_Data,"m_vehicleScript")) GetEntPropString(i,Prop_Data,"m_vehicleScript",vehscript,sizeof(vehscript));
	if (HasEntProp(i,Prop_Data,"m_spawnEquipment")) GetEntPropString(i,Prop_Data,"m_spawnEquipment",additionalequip,sizeof(additionalequip));
	if (HasEntProp(i,Prop_Data,"m_spawnflags"))
	{
		int sf = GetEntProp(i,Prop_Data,"m_spawnflags");
		Format(spawnflags,sizeof(spawnflags),"%i",sf);
	}
	if (HasEntProp(i,Prop_Data,"m_nSkin"))
	{
		int sk = GetEntProp(i,Prop_Data,"m_nSkin");
		Format(skin,sizeof(skin),"%i",sk);
	}
	if (HasEntProp(i,Prop_Data,"m_nHardwareType"))
	{
		int hdw = GetEntProp(i,Prop_Data,"m_nHardwareType");
		Format(hdwtype,sizeof(hdwtype),"%i",hdw);
	}
	if (HasEntProp(i,Prop_Data,"m_hParent"))
	{
		int par = GetEntPropEnt(i,Prop_Data,"m_hParent");
		if (par != -1)
		{
			GetEntPropString(par,Prop_Data,"m_iName",parentname,sizeof(parentname));
			char parentcls[32];
			GetEntityClassname(par,parentcls,sizeof(parentcls));
			if (StrEqual(parentcls,"func_door",false))
			{
				CloseHandle(dp);
				PushArrayCell(g_hIgnoredEntities, i);
				return;
			}
		}
	}
	if (HasEntProp(i,Prop_Data,"m_state"))
	{
		int istate = GetEntProp(i,Prop_Data,"m_state");
		Format(state,sizeof(state),"%i",istate);
		//PrintToServer("State %s",state);
	}
	if (HasEntProp(i,Prop_Data,"m_target"))
	{
		if (StrEqual(clsname,"npc_combinedropship",false)) GetEntPropString(i,Prop_Data,"m_target",target,sizeof(target));
	}
	if (HasEntProp(i,Prop_Data,"m_eDoorState")) iDoorState = GetEntProp(i,Prop_Data,"m_eDoorState");
	if (HasEntProp(i,Prop_Data,"m_SleepState")) iSleepState = GetEntProp(i,Prop_Data,"m_SleepState");
	if (HasEntProp(i,Prop_Data,"m_Type"))
	{
		int inpctype = GetEntProp(i,Prop_Data,"m_Type");
		Format(npctype,sizeof(npctype),"%i",inpctype);
	}
	if (HasEntProp(i,Prop_Data,"m_iszEntry"))
	{
		GetEntPropString(i,Prop_Data,"m_iszEntry",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"m_iszEntry %s ",scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_iszPreIdle"))
	{
		GetEntPropString(i,Prop_Data,"m_iszPreIdle",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPreIdle %s ",scriptinf,scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_iszPlay"))
	{
		GetEntPropString(i,Prop_Data,"m_iszPlay",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPlay %s ",scriptinf,scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_iszPostIdle"))
	{
		GetEntPropString(i,Prop_Data,"m_iszPostIdle",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPostIdle %s ",scriptinf,scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_iszCustomMove"))
	{
		GetEntPropString(i,Prop_Data,"m_iszCustomMove",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszCustomMove %s ",scriptinf,scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_iszNextScript"))
	{
		GetEntPropString(i,Prop_Data,"m_iszNextScript",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszNextScript %s ",scriptinf,scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_iszEntity"))
	{
		GetEntPropString(i,Prop_Data,"m_iszEntity",scrtmp,sizeof(scrtmp));
		if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszEntity %s ",scriptinf,scrtmp);
	}
	if (HasEntProp(i,Prop_Data,"m_fMoveTo"))
	{
		int scrtmpi = GetEntProp(i,Prop_Data,"m_fMoveTo");
		Format(scriptinf,sizeof(scriptinf),"%sm_fMoveTo %i ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_flRadius"))
	{
		float scrtmpi = GetEntPropFloat(i,Prop_Data,"m_flRadius");
		Format(scriptinf,sizeof(scriptinf),"%sm_flRadius %1.f ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_flRepeat"))
	{
		float scrtmpi = GetEntPropFloat(i,Prop_Data,"m_flRepeat");
		Format(scriptinf,sizeof(scriptinf),"%sm_flRepeat %1.f ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_bLoopActionSequence"))
	{
		int scrtmpi = GetEntProp(i,Prop_Data,"m_bLoopActionSequence");
		Format(scriptinf,sizeof(scriptinf),"%sm_bLoopActionSequence %i ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_bIgnoreGravity"))
	{
		int scrtmpi = GetEntProp(i,Prop_Data,"m_bIgnoreGravity");
		Format(scriptinf,sizeof(scriptinf),"%sm_bIgnoreGravity %i ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_bSynchPostIdles"))
	{
		int scrtmpi = GetEntProp(i,Prop_Data,"m_bSynchPostIdles");
		Format(scriptinf,sizeof(scriptinf),"%sm_bSynchPostIdles %i ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_bDisableNPCCollisions"))
	{
		int scrtmpi = GetEntProp(i,Prop_Data,"m_bDisableNPCCollisions");
		Format(scriptinf,sizeof(scriptinf),"%sm_bDisableNPCCollisions %i ",scriptinf,scrtmpi);
	}
	if (HasEntProp(i,Prop_Data,"m_vecAxis"))
	{
		float angax[3];
		GetEntPropVector(i,Prop_Data,"m_vecAxis",angax);
		Format(scriptinf,sizeof(scriptinf),"%saxis \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
	}
	if (HasEntProp(i,Prop_Data,"m_flDistance"))
	{
		float dist = GetEntPropFloat(i,Prop_Data,"m_flDistance");
		Format(scriptinf,sizeof(scriptinf),"%sdistance %1.f ",scriptinf,dist);
	}
	if (HasEntProp(i,Prop_Data,"m_flSpeed"))
	{
		float flSpeed = GetEntPropFloat(i,Prop_Data,"m_flSpeed");
		if (flSpeed > 0.0) Format(scriptinf,sizeof(scriptinf),"%sspeed %1.f ",scriptinf,flSpeed);
	}
	if (HasEntProp(i,Prop_Data,"m_angRotationClosed"))
	{
		float angax[3];
		GetEntPropVector(i,Prop_Data,"m_angRotationClosed",angax);
		Format(scriptinf,sizeof(scriptinf),"%sm_angRotationClosed \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
	}
	if (HasEntProp(i,Prop_Data,"m_angRotationOpenForward"))
	{
		float angax[3];
		GetEntPropVector(i,Prop_Data,"m_angRotationOpenForward",angax);
		Format(scriptinf,sizeof(scriptinf),"%sm_angRotationOpenForward \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
	}
	if (HasEntProp(i,Prop_Data,"m_angRotationOpenBack"))
	{
		float angax[3];
		GetEntPropVector(i,Prop_Data,"m_angRotationOpenBack",angax);
		Format(scriptinf,sizeof(scriptinf),"%sm_angRotationOpenBack \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
	}
	if (HasEntProp(i,Prop_Data,"m_angGoal"))
	{
		float angax[3];
		GetEntPropVector(i,Prop_Data,"m_angGoal",angax);
		Format(scriptinf,sizeof(scriptinf),"%sm_angGoal \"%1.f %1.f %1.f\" ",scriptinf,angax[0],angax[1],angax[2]);
	}
	if (HasEntProp(i,Prop_Data,"m_iszMagnetName"))
	{
		char magname[64];
		GetEntPropString(i,Prop_Data,"m_iszMagnetName",magname,sizeof(magname));
		Format(scriptinf,sizeof(scriptinf),"%sm_iszMagnetName %s ",scriptinf,magname);
	}
	if (HasEntProp(i,Prop_Data,"m_nSolidType"))
	{
		int solidtype = GetEntProp(i,Prop_Data,"m_nSolidType");
		Format(solidity,sizeof(solidity),"%i",solidtype);
	}
	if (HasEntProp(i,Prop_Data,"m_bHasGun")) bGunEnable = GetEntProp(i,Prop_Data,"m_bHasGun");
	if (HasEntProp(i,Prop_Data,"m_takedamage")) tkdmg = GetEntProp(i,Prop_Data,"m_takedamage");
	if (HasEntProp(i,Prop_Data,"movetype")) mvtype = GetEntProp(i,Prop_Data,"movetype");
	if (HasEntProp(i,Prop_Data,"m_bGameEndAlly")) gameend = GetEntProp(i,Prop_Data,"m_bGameEndAlly");
	if (HasEntProp(i,Prop_Data,"m_iszDefaultAnim")) GetEntPropString(i,Prop_Data,"m_iszDefaultAnim",defanim,sizeof(defanim));
	if (HasEntProp(i,Prop_Data,"m_iszResponseContext")) GetEntPropString(i,Prop_Data,"m_iszResponseContext",response,sizeof(response));
	TrimString(scriptinf);
	WritePackString(dp,clsname);
	WritePackString(dp,szTargetname);
	WritePackString(dp,mdl);
	WritePackCell(dp,curh);
	WritePackFloat(dp,vecOrigin[0]);
	WritePackFloat(dp,vecOrigin[1]);
	WritePackFloat(dp,vecOrigin[2]);
	WritePackFloat(dp,angs[0]);
	WritePackFloat(dp,angs[1]);
	WritePackFloat(dp,angs[2]);
	WritePackString(dp,vehscript);
	WritePackString(dp,spawnflags);
	WritePackString(dp,additionalequip);
	WritePackString(dp,skin);
	WritePackString(dp,hdwtype);
	WritePackString(dp,parentname);
	WritePackString(dp,state);
	WritePackString(dp,target);
	WritePackCell(dp,iDoorState);
	WritePackCell(dp,iSleepState);
	WritePackString(dp,npctype);
	WritePackString(dp,solidity);
	WritePackCell(dp,bGunEnable);
	WritePackCell(dp,tkdmg);
	WritePackCell(dp,mvtype);
	WritePackCell(dp,gameend);
	WritePackString(dp,defanim);
	WritePackString(dp,response);
	WritePackString(dp,scriptinf);
	PushArrayCell(g_hTransitionEntities,dp);
	PushArrayCell(g_hIgnoredEntities,i);
	return;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (bTransitionPlayers)
	{
		int client = GetClientOfUserId(GetEventInt(event,"userid"));
		CreateTimer(0.1, transitionspawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool Broadcast)
{
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
		{
			if (iRestoreProperty[i][0])
			{
				if (HasEntProp(i,Prop_Data,"m_iFrags"))
					SetEntProp(i,Prop_Data,"m_iFrags",iRestoreProperty[i][0]);
			}
			if (iRestoreProperty[i][1])
			{
				if (HasEntProp(i,Prop_Data,"m_iDeaths"))
					SetEntProp(i,Prop_Data,"m_iDeaths",iRestoreProperty[i][1]);
			}
		}
		iRestoreProperty[i][0] = 0;
		iRestoreProperty[i][1] = 0;
	}
}

public void OnClientAuthorized(int client, const char[] szAuth)
{
	if ((bRebuildTransition) && (!BMActive) && ((!SynLaterAct) || (g_hCVbTransitionSkipVersion.BoolValue)))
	{
		if ((!StrEqual(mapbuf,"d3_citadel_03",false)) && (!StrEqual(mapbuf,"ep2_outland_02",false)))
		{
			if (IsValidEntity(logplyprox))
			{
				char clschk[32];
				GetEntityClassname(logplyprox,clschk,sizeof(clschk));
				if (StrEqual(clschk,"logic_playerproxy",false))
				{
					AcceptEntityInput(logplyprox,"CancelRestorePlayers");
				}
				else
				{
					logplyprox = CreateEntityByName("logic_playerproxy");
					if (logplyprox != -1)
					{
						DispatchKeyValue(logplyprox,"targetname","synplyprox");
						DispatchSpawn(logplyprox);
						ActivateEntity(logplyprox);
						AcceptEntityInput(logplyprox,"CancelRestorePlayers");
					}
				}
			}
			else
			{
				logplyprox = CreateEntityByName("logic_playerproxy");
				if (logplyprox != -1)
				{
					DispatchKeyValue(logplyprox,"targetname","synplyprox");
					DispatchSpawn(logplyprox);
					ActivateEntity(logplyprox);
					AcceptEntityInput(logplyprox,"CancelRestorePlayers");
				}
			}
		}
		
		// Intro and van choreo vehicles break on ep1_citadel_00
		if ((!bNoDelete) && (!StrEqual(mapbuf,"ep1_citadel_00",false)))
		{
			if ((logsv != -1) && (IsValidEntity(logsv)))
			{
				saveresetveh(true);
			}
			else
			{
				if (saveresetm == 1) logsv = CreateEntityByName("logic_autosave");
				else if (saveresetm == 2) logsv = CreateEntityByName("logic_playerproxy");
				if ((logsv != -1) && (IsValidEntity(logsv)))
				{
					DispatchKeyValue(logsv,"NewLevelUnit","1");
					DispatchSpawn(logsv);
					ActivateEntity(logsv);
					saveresetveh(true);
				}
			}
		}
	}
}

void saveresetveh(bool rmsave)
{
	if ((StrContains(mapbuf,"oc_spaceinvaders",false) == -1) && (!BMActive))
	{
		float Time = GetTickedTime();
		if (flMapStartTime <= Time)
		{
			if ((rmsave) && (!bNoDelete) && (strlen(savedir) > 0))
			{
				if (DirExists(savedir,false))
				{
					Handle savedirrmh = OpenDirectory(savedir, false);
					char subfilen[64];
					while (ReadDirEntry(savedirrmh, subfilen, sizeof(subfilen)))
					{
						if ((!(savedirrmh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
						{
							if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
							{
								Format(subfilen,sizeof(subfilen),"%s\\%s",savedir,subfilen);
								if ((StrContains(subfilen,"autosave.hl1",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,szPreviousMap,false) == -1))
								{
									DeleteFile(subfilen,false);
								}
							}
						}
					}
					CloseHandle(savedirrmh);
				}
			}
			int vehicles[128];
			float steerpos[128];
			int vehon[128];
			float throttle[128];
			int iSpeed[128];
			float vecRestoreAngles[3];
			float vecAngles[128][3];
			int gearsound[128];
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					vehicles[i] = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
					char vehiclecls[32];
					if (vehicles[i] != -1) GetEntityClassname(vehicles[i],vehiclecls,sizeof(vehiclecls));
					if (vehicles[i] > MaxClients)
					{
						int driver = GetEntProp(i,Prop_Data,"m_iHideHUD");
						vehon[i] = 1;
						if (HasEntProp(vehicles[i],Prop_Data,"m_bIsOn")) vehon[i] = GetEntProp(vehicles[i],Prop_Data,"m_bIsOn");
						if ((driver == 3328) && (vehon[i]))
						{
							char clsname[32];
							GetEntityClassname(vehicles[i],clsname,sizeof(clsname));
							if ((StrEqual(clsname,"prop_vehicle_jeep",false)) || (StrEqual(clsname,"prop_vehicle_mp",false)))
							{
								if (HasEntProp(vehicles[i],Prop_Data,"m_controls.steering")) steerpos[i] = GetEntPropFloat(vehicles[i],Prop_Data,"m_controls.steering");
								if (HasEntProp(vehicles[i],Prop_Data,"m_controls.throttle")) throttle[i] = GetEntPropFloat(vehicles[i],Prop_Data,"m_controls.throttle");
								if (HasEntProp(vehicles[i],Prop_Data,"m_nSpeed")) iSpeed[i] = GetEntProp(vehicles[i],Prop_Data,"m_nSpeed");
								if (HasEntProp(vehicles[i],Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",vecRestoreAngles);
								vecAngles[i][1] = vecRestoreAngles[1];
								if (HasEntProp(vehicles[i],Prop_Data,"m_iSoundGear")) gearsound[i] = GetEntProp(vehicles[i],Prop_Data,"m_iSoundGear");
							}
						}
					}
				}
			}
			if (IsValidEntity(logsv))
			{
				if (saveresetm == 1) AcceptEntityInput(logsv,"Save");
				else if (saveresetm == 2) AcceptEntityInput(logsv,"CancelRestorePlayers");
			}
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((vehicles[i] != 0) && (IsValidEntity(vehicles[i])))
				{
					char clsname[32];
					GetEntityClassname(vehicles[i],clsname,sizeof(clsname));
					if ((StrEqual(clsname,"prop_vehicle_jeep",false)) || (StrEqual(clsname,"prop_vehicle_mp",false)))
					{
						if (HasEntProp(vehicles[i],Prop_Data,"m_controls.steering")) SetEntPropFloat(vehicles[i],Prop_Data,"m_controls.steering",steerpos[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_controls.throttle")) SetEntPropFloat(vehicles[i],Prop_Data,"m_controls.throttle",throttle[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_bIsOn")) SetEntProp(vehicles[i],Prop_Data,"m_bIsOn",vehon[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_nSpeed")) SetEntProp(vehicles[i],Prop_Data,"m_nSpeed",iSpeed[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_iSoundGear")) SetEntProp(vehicles[i],Prop_Data,"m_iSoundGear",gearsound[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_controls.handbrake")) SetEntProp(vehicles[i],Prop_Data,"m_controls.handbrake",1);
						vecRestoreAngles[0] = vecAngles[i][0];
						vecRestoreAngles[1] = vecAngles[i][1];
						vecRestoreAngles[2] = vecAngles[i][2];
					}
					else if ((StrEqual(clsname,"prop_vehicle_prisoner_pod",false)) || (StrContains(clsname,"prop_vehicle_choreo",false) == 0))
					{
						SetVariantString("!activator");
						AcceptEntityInput(vehicles[i],"EnterVehicleImmediate",i);
					}
				}
			}
		}
	}
}

public Action transitionspawn(Handle timer, any client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client) && !IsFakeClient(client))
	{
		CreateTimer(0.1, anotherdelay, client);
	}
	else if ((IsClientConnected(client)) && (!IsFakeClient(client)))
	{
		CreateTimer(1.0, transitionspawn, client);
	}
}

public Action anotherdelay(Handle timer, int client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client) && !IsFakeClient(client))
	{
		//Issue with no suit power, this will reset it
		if (HasEntProp(client,Prop_Data,"m_bPlayerUnderwater")) SetEntProp(client,Prop_Data,"m_bPlayerUnderwater",1);
		char SteamID[32];
		GetClientAuthId(client,AuthId_Steam2,SteamID,sizeof(SteamID));
		if ((strlen(SteamID) < 1) || (StrEqual(SteamID,"STEAM_ID_STOP_IGNORING_RETVALS",false)))
		{
			if (HasEntProp(client,Prop_Data,"m_szNetworkIDString"))
			{
				char searchid[64];
				GetEntPropString(client,Prop_Data,"m_szNetworkIDString",searchid,sizeof(searchid));
				if (strlen(searchid) > 1)
				{
					char Err[100];
					Handle Handle_IDSDB = SQLite_UseDatabase("sourcemod-local",Err,100-1);
					if (!iCreatedTable)
					{
						if (!SQL_FastQuery(Handle_IDSDB,"CREATE TABLE IF NOT EXISTS synbackupids(SteamID VARCHAR(32) NOT NULL PRIMARY KEY,UUID VARCHAR(64) NOT NULL);"))
						{
							PrintToServer("Error in create IDSBackup %s",Err);
							iCreatedTable = 2;
						}
						else iCreatedTable = 1;
					}
					if (iCreatedTable == 1)
					{
						char Querychk[100];
						Format(Querychk,100,"SELECT SteamID FROM synbackupids WHERE UUID = '%s';",searchid);
						Handle HQuery = SQL_Query(Handle_IDSDB,Querychk);
						if (HQuery != INVALID_HANDLE)
						{
							if (SQL_FetchRow(HQuery))
							{
								SQL_FetchString(HQuery,0,SteamID,sizeof(SteamID));
							}
						}
						CloseHandle(HQuery);
					}
					CloseHandle(Handle_IDSDB);
				}
			}
		}
		int arrindx = FindStringInArray(g_hTransitionIDs,SteamID);
		if (arrindx != -1)
		{
			if (!BMActive)
			{
				if (GetArraySize(g_hEquipEnts) < 1) findent(MaxClients+1,"info_player_equip");
				//Possibility of no equips found.
				bool recheck = false;
				if (GetArraySize(g_hEquipEnts) > 0)
				{
					for (int j; j<GetArraySize(g_hEquipEnts); j++)
					{
						int jtmp = GetArrayCell(g_hEquipEnts, j);
						if (IsValidEntity(jtmp))
						{
							if (IsEntNetworkable(jtmp))
							{
								char clscheck[32];
								GetEntityClassname(jtmp,clscheck,sizeof(clscheck));
								if (StrEqual(clscheck,"info_player_equip",false))
								{
									if (bIsVehicleMap)
										AcceptEntityInput(jtmp,"Disable");
								}
								else
								{
									ClearArray(g_hEquipEnts);
									findent(MaxClients+1,"info_player_equip");
									recheck = true;
									break;
								}
							}
						}
					}
				}
				if ((recheck) && (GetArraySize(g_hEquipEnts) > 0))
				{
					for (int j; j<GetArraySize(g_hEquipEnts); j++)
					{
						int jtmp = GetArrayCell(g_hEquipEnts, j);
						if ((IsValidEntity(jtmp)) && (bIsVehicleMap))
							AcceptEntityInput(jtmp,"Disable");
					}
				}
			}
			char ammoset[64];
			char ammosetexp[32][4];
			char ammosettype[64];
			char ammosetamm[16];
			char curweap[64];
			RemoveFromArray(g_hTransitionIDs,arrindx);
			if (GetArraySize(g_hTransitionDataPacks) > arrindx)
			{
				Handle dp = GetArrayCell(g_hTransitionDataPacks,arrindx);
				ResetPack(dp);
				int curh = ReadPackCell(dp);
				int cura = ReadPackCell(dp);
				int score = ReadPackCell(dp);
				int kills = ReadPackCell(dp);
				int deaths = ReadPackCell(dp);
				int suitset = ReadPackCell(dp);
				int medkitamm = ReadPackCell(dp);
				int crouching = ReadPackCell(dp);
				float plyorigin[3];
				float angs[3];
				angs[0] = ReadPackFloat(dp);
				angs[1] = ReadPackFloat(dp);
				bool teleport = true;
				plyorigin[0] = ReadPackFloat(dp);
				plyorigin[1] = ReadPackFloat(dp);
				plyorigin[2] = ReadPackFloat(dp);
				if ((((plyorigin[0] == 0.0) && (plyorigin[1] == 0.0) && (plyorigin[2] == 0.0))) || (strlen(szLandmarkName) < 1)) teleport = false;
				plyorigin[0]+=g_vecLandmarkOrigin[0];
				plyorigin[1]+=g_vecLandmarkOrigin[1];
				plyorigin[2]+=g_vecLandmarkOrigin[2];
				if (TR_PointOutsideWorld(plyorigin)) teleport = false;
				if (g_hCVbDebugTransitions.BoolValue) LogMessage("Restore CL '%N' Transition info: Health: %i Armor: %i Offset \"%1.f %1.f %1.f\" moveto %i",client,curh,cura,plyorigin[0],plyorigin[1],plyorigin[2],teleport);
				ReadPackString(dp,curweap,sizeof(curweap));
				if (curh < 1)
				{
					curh = 100;
					cura = 0;
					EquipPly(client);
				}
				else
				{
					SetEntProp(client,Prop_Data,"m_iHealth",curh);
					SetEntProp(client,Prop_Data,"m_ArmorValue",cura);
				}
				if (HasEntProp(client,Prop_Data,"m_iPoints")) SetEntProp(client,Prop_Data,"m_iPoints",score);
				if (BMActive)
				{
					// Needs to be applied on round start
					iRestoreProperty[client][0] = kills;
					iRestoreProperty[client][1] = deaths;
				}
				SetEntProp(client,Prop_Data,"m_iFrags",kills);
				SetEntProp(client,Prop_Data,"m_iDeaths",deaths);
				SetEntProp(client,Prop_Send,"m_bWearingSuit",suitset);
				if (HasEntProp(client,Prop_Data,"m_iHealthPack")) SetEntProp(client,Prop_Send,"m_iHealthPack",medkitamm);
				SetEntProp(client,Prop_Send,"m_bDucking",crouching);
				ReadPackString(dp,ammoset,sizeof(ammoset));
				int iInit = view_as<int>(dp);
				while (!StrEqual(ammoset,"endofpack",false))
				{
					if (StrContains(ammoset,"propset ",false) == 0)
					{
						ExplodeString(ammoset," ",ammosetexp,4,32);
						if (StringToInt(ammosetexp[2]) == 1)
						{
							if (HasEntProp(client,Prop_Send,ammosetexp[1]))
							{
								SetEntProp(client,Prop_Send,ammosetexp[1],StringToInt(ammosetexp[3]));
							}
						}
						else if (HasEntProp(client,Prop_Data,ammosetexp[1]))
						{
							SetEntProp(client,Prop_Data,ammosetexp[1],StringToInt(ammosetexp[3]));
						}
					}
					else if (StrContains(ammoset,"weapon_",false) == -1)
					{
						ExplodeString(ammoset," ",ammosetexp,2,32);
						int ammindx = StringToInt(ammosetexp[0]);
						int ammset = StringToInt(ammosetexp[1]);
						SetEntProp(client,Prop_Send,"m_iAmmo",ammset,_,ammindx);
					}
					else if (StrContains(ammoset,"weapon_",false) != -1)
					{
						int breakstr = StrContains(ammoset," ",false);
						if (breakstr != -1)
						{
							Format(ammosettype,sizeof(ammosettype),"%s",ammoset);
							Format(ammosetamm,sizeof(ammosetamm),"%s",ammoset[breakstr+1]);
							ReplaceString(ammosettype,sizeof(ammosettype),ammoset[breakstr],"");
							int weapindx = -1;
							char basecls[32];
							if (!BMActive)
							{
								if ((StrEqual(ammosettype,"weapon_gluon",false)) || (StrEqual(ammosettype,"weapon_goop",false))) Format(basecls,sizeof(basecls),"weapon_shotgun");
								else if (StrEqual(ammosettype,"weapon_isa_knife",false)) Format(basecls,sizeof(basecls),"weapon_crowbar");
								else if (StrEqual(ammosettype,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
								else if ((StrEqual(ammosettype,"weapon_glock",false)) || (StrEqual(ammosettype,"weapon_pistol_worker",false)) || (StrEqual(ammosettype,"weapon_flaregun",false)) || (StrEqual(ammosettype,"weapon_manhack",false)) || (StrEqual(ammosettype,"weapon_manhackgun",false)) || (StrEqual(ammosettype,"weapon_manhacktoss",false)) || (StrEqual(ammosettype,"weapon_p911",false)) || (StrEqual(ammosettype,"weapon_pistol2",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
								else if ((StrEqual(ammosettype,"weapon_medkit",false)) || (StrEqual(ammosettype,"weapon_healer",false)) || (StrEqual(ammosettype,"weapon_snark",false)) || (StrEqual(ammosettype,"weapon_hivehand",false)) || (StrEqual(ammosettype,"weapon_satchel",false)) || (StrEqual(ammosettype,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
								else if ((StrEqual(ammosettype,"weapon_mp5",false)) || (StrEqual(ammosettype,"weapon_sl8",false)) || (StrEqual(ammosettype,"weapon_uzi",false)) || (StrEqual(ammosettype,"weapon_camera",false)) || (StrEqual(ammosettype,"weapon_smg3",false)) || (StrEqual(ammosettype,"weapon_smg4",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
								else if ((StrEqual(ammosettype,"weapon_gauss",false)) || (StrEqual(ammosettype,"weapon_tau",false)) || (StrEqual(ammosettype,"weapon_sniperrifle",false)) || (StrEqual(ammosettype,"weapon_vc32sniperrifle",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
								else if (StrEqual(ammosettype,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
								else if (StrEqual(ammosettype,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
								else if (StrContains(ammosettype,"customweapons",false) != -1)
								{
									char findpath[64];
									Format(findpath,sizeof(findpath),"scripts/%s.txt",ammosettype);
									if (FileExists(findpath,true,NULL_STRING))
									{
										Handle filehandlesub = OpenFile(findpath,"r",true,NULL_STRING);
										if (filehandlesub != INVALID_HANDLE)
										{
											char scrline[128];
											while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
											{
												TrimString(scrline);
												if (StrContains(scrline,"\"anim_prefix\"",false) != -1)
												{
													ReplaceStringEx(scrline,sizeof(scrline),"\"anim_prefix\"","",_,_,false);
													ReplaceString(scrline,sizeof(scrline),"\"","");
													TrimString(scrline);
													if (StrEqual(scrline,"python",false)) Format(scrline,sizeof(scrline),"357");
													else if (StrEqual(scrline,"gauss",false)) Format(scrline,sizeof(scrline),"shotgun");
													else if (StrEqual(scrline,"smg2",false)) Format(scrline,sizeof(scrline),"smg1");
													Format(scrline,sizeof(scrline),"weapon_%s",scrline);
													Format(basecls,sizeof(basecls),"%s",scrline);
													break;
												}
											}
										}
										CloseHandle(filehandlesub);
									}
								}
							}
							if (BMActive) Format(basecls,sizeof(basecls),"%s",ammosettype);
							if (strlen(basecls) > 0)
							{
								weapindx = CreateEntityByName(basecls);
								if (weapindx != -1)
								{
									float tmporgs[3];
									GetClientAbsOrigin(client,tmporgs);
									tmporgs[2]+=20.0;
									TeleportEntity(weapindx,tmporgs,angs,NULL_VECTOR);
									DispatchKeyValue(weapindx,"classname",ammosettype);
									DispatchSpawn(weapindx);
									ActivateEntity(weapindx);
								}
							}
							if (!IsValidEntity(weapindx)) weapindx = GivePlayerItem(client,ammosettype);
							if (IsValidEntity(weapindx))
							{
								int weapamm = StringToInt(ammosetamm);
								if (HasEntProp(weapindx,Prop_Data,"m_iClip1"))
								{
									SetEntProp(weapindx,Prop_Data,"m_iClip1",weapamm);
								}
							}
						}
					}
					if (iInit != view_as<int>(dp)) break;
					ReadPackString(dp,ammoset,sizeof(ammoset));
				}
				CloseHandle(dp);
				RemoveFromArray(g_hTransitionDataPacks,arrindx);
				if (teleport)
				{
					Handle dpoffs = CreateDataPack();
					WritePackCell(dpoffs,client);
					WritePackFloat(dpoffs,plyorigin[0]);
					WritePackFloat(dpoffs,plyorigin[1]);
					WritePackFloat(dpoffs,plyorigin[2]);
					WritePackFloat(dpoffs,angs[0]);
					WritePackFloat(dpoffs,angs[1]);
					WritePackFloat(dpoffs,angs[2]);
					if (BMActive) CreateTimer(1.1,tpcltooff,dpoffs,TIMER_FLAG_NO_MAPCHANGE);
					else CreateTimer(0.1,tpcltooff,dpoffs,TIMER_FLAG_NO_MAPCHANGE);
					TeleportEntity(client,plyorigin,angs,NULL_VECTOR);
				}
				ClientCommand(client,"use %s",curweap);
			}
		}
		else if (!BMActive)
		{
			EquipPly(client);
		}
	}
}

void EquipPly(int client)
{
	if (IsValidEntity(client))
	{
		if (IsClientConnected(client))
		{
			if (IsClientInGame(client))
			{
				if (IsPlayerAlive(client))
				{
					findent(MaxClients+1,"info_player_equip");
					bool recheck = false;
					if (GetArraySize(g_hEquipEnts) > 0)
					{
						for (int j; j<GetArraySize(g_hEquipEnts); j++)
						{
							int jtmp = GetArrayCell(g_hEquipEnts, j);
							if (IsValidEntity(jtmp))
							{
								if (IsEntNetworkable(jtmp))
								{
									char clscheck[32];
									GetEntityClassname(jtmp,clscheck,sizeof(clscheck));
									if (StrEqual(clscheck,"info_player_equip",false))
									{
										if (bIsVehicleMap) AcceptEntityInput(jtmp,"Disable");
										AcceptEntityInput(jtmp,"EquipPlayer",client);
										EquipCustom(jtmp,client);
									}
									else
									{
										ClearArray(g_hEquipEnts);
										findent(MaxClients+1,"info_player_equip");
										recheck = true;
										break;
									}
								}
							}
						}
					}
					if ((recheck) && (GetArraySize(g_hEquipEnts) > 0))
					{
						for (int j; j<GetArraySize(g_hEquipEnts); j++)
						{
							int jtmp = GetArrayCell(g_hEquipEnts, j);
							if (IsValidEntity(jtmp))
							{
								if (bIsVehicleMap) AcceptEntityInput(jtmp,"Disable");
								AcceptEntityInput(jtmp,"EquipPlayer",client);
								EquipCustom(jtmp,client);
							}
						}
					}
					if ((GetArraySize(g_hEquipEnts) < 1) && (!StrEqual(mapbuf,"bm_c0a0c",false)) && (!StrEqual(mapbuf,"bm_c1a0a",false)) && (!StrEqual(mapbuf,"sp_intro",false)) && (!StrEqual(mapbuf,"d1_trainstation_05",false)) && (!StrEqual(mapbuf,"ce_01",false))) CreateTimer(0.1,delayequip,client);
				}
			}
		}
	}
}

public Action tpcltooff(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int client = ReadPackCell(dp);
		float plyorigin[3];
		float angs[3];
		plyorigin[0] = ReadPackFloat(dp);
		plyorigin[1] = ReadPackFloat(dp);
		plyorigin[2] = ReadPackFloat(dp);
		angs[0] = ReadPackFloat(dp);
		angs[1] = ReadPackFloat(dp);
		angs[2] = ReadPackFloat(dp);
		CloseHandle(dp);
		if (IsValidEntity(client))
		{
			TeleportEntity(client,plyorigin,angs,NULL_VECTOR);
		}
	}
}

public Action delayequip(Handle timer, int client)
{
	if (g_hCVbApplyFallbackEquip.BoolValue) findentwdis(MaxClients+1,"info_player_equip");
	if ((IsClientConnected(client)) && (IsValidEntity(client)) && (IsClientInGame(client)) && (IsPlayerAlive(client)))
	{
		if (GetArraySize(g_hEquipEnts) > 0)
		{
			for (int j; j<GetArraySize(g_hEquipEnts); j++)
			{
				int jtmp = GetArrayCell(g_hEquipEnts, j);
				if (IsValidEntity(jtmp))
				{
					if (bIsVehicleMap) AcceptEntityInput(jtmp,"Disable");
					AcceptEntityInput(jtmp,"EquipPlayer",client);
					EquipCustom(jtmp,client);
				}
			}
		}
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
					if (iWeaponListOffset == -1) iWeaponListOffset = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
					if (iWeaponListOffset != -1)
					{
						char clschk[64];
						for (int j; j<104; j += 4)
						{
							int tmpi = GetEntDataEnt2(client,iWeaponListOffset + j);
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
						if ((StrEqual(basecls,"weapon_gluon",false)) || (StrEqual(basecls,"weapon_goop",false))) Format(basecls,sizeof(basecls),"weapon_shotgun");
						else if (StrEqual(basecls,"weapon_isa_knife",false)) Format(basecls,sizeof(basecls),"weapon_crowbar");
						else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
						else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false)) || (StrEqual(basecls,"weapon_p911",false)) || (StrEqual(basecls,"weapon_pistol2",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
						else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
						else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false)) || (StrEqual(basecls,"weapon_camera",false)) || (StrEqual(basecls,"weapon_smg3",false)) || (StrEqual(basecls,"weapon_smg4",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
						else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false)) || (StrEqual(basecls,"weapon_vc32sniperrifle",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
						else if (StrEqual(basecls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
						else if (StrEqual(basecls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
						else if (StrContains(basecls,"customweapons",false) != -1)
						{
							char findpath[64];
							Format(findpath,sizeof(findpath),"scripts/%s.txt",basecls);
							if (FileExists(findpath,true,NULL_STRING))
							{
								Handle filehandlesub = OpenFile(findpath,"r",true,NULL_STRING);
								if (filehandlesub != INVALID_HANDLE)
								{
									char scrline[128];
									while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
									{
										TrimString(scrline);
										if (StrContains(scrline,"\"anim_prefix\"",false) != -1)
										{
											ReplaceStringEx(scrline,sizeof(scrline),"\"anim_prefix\"","",_,_,false);
											ReplaceString(scrline,sizeof(scrline),"\"","");
											TrimString(scrline);
											if (StrEqual(scrline,"python",false)) Format(scrline,sizeof(scrline),"357");
											else if (StrEqual(scrline,"gauss",false)) Format(scrline,sizeof(scrline),"shotgun");
											else if (StrEqual(scrline,"smg2",false)) Format(scrline,sizeof(scrline),"smg1");
											Format(scrline,sizeof(scrline),"weapon_%s",scrline);
											Format(basecls,sizeof(basecls),"%s",scrline);
											break;
										}
									}
								}
								CloseHandle(filehandlesub);
							}
						}
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
		if ((bdisabled == 0) && (FindValueInArray(g_hEquipEnts,thisent) == -1))
			PushArrayCell(g_hEquipEnts,thisent);
		findent(thisent++,clsname);
	}
}

bool findvmap(int ent)
{
	int thisent = FindEntityByClassname(ent,"info_global_settings");
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		int bdisabled = GetEntProp(thisent,Prop_Data,"m_bIsVehicleMap");
		if (bdisabled == 1)
			return true;
		findvmap(thisent++);
	}
	return false;
}

void findentwdis(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char szTargetname[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
		if (((StrEqual(szTargetname,"syn_equip_start",false)) || (StrEqual(szTargetname,"syn_equipment_base",false))) && (FindValueInArray(g_hEquipEnts,thisent) == -1))
		{
			PushArrayCell(g_hEquipEnts,thisent);
			findentwdis(thisent++,clsname);
		}
	}
}

public Action changelevel(Handle timer)
{
	char contentdata[72];
	Handle cvar = FindConVar("content_metadata");
	if (cvar != INVALID_HANDLE)
	{
		GetConVarString(cvar,contentdata,sizeof(contentdata));
		char fixuptmp[16][16];
		ExplodeString(contentdata," ",fixuptmp,16,16,true);
		if (StrEqual(fixuptmp[1],"|",false)) Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		else Format(contentdata,sizeof(contentdata),"%s",fixuptmp[0]);
	}
	CloseHandle(cvar);
	if (strlen(contentdata) > 0) ServerCommand("changelevel %s %s",contentdata,mapbuf);
	else ServerCommand("changelevel %s",mapbuf);
}

void findrmstarts(int start, char[] type)
{
	int thisent = FindEntityByClassname(start,type);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		AcceptEntityInput(thisent, "Kill");
	}
}

void findtrigs(int start, char[] type)
{
	int thisent = FindEntityByClassname(start,type);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char prevtmp[48];
		GetEntPropString(thisent,Prop_Data,"m_iName",prevtmp,sizeof(prevtmp));
		//PrintToServer(prevtmp);
		if (StrEqual(prevtmp,"elevator_black_brush",false))
		{
			enterfrom04 = false;
		}
		else if (StrEqual(prevtmp,"syn_vint_stopplayerjump_1",false))
		{
			enterfrom03 = false;
		}
		else if (StrEqual(prevtmp,"trav_antiskip_hurt",false))
		{
			if (!GetEntProp(thisent,Prop_Data,"m_bDisabled"))
				enterfrom08 = false;
		}
		findtrigs(thisent++,type);
	}
}

int SearchForClass(char tmptarg[128], Handle hReturnedArray)
{
	FindTargetnameByClass(-1,"logic_*",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) > 0) return GetArraySize(hReturnedArray);
	FindTargetnameByClass(-1,"info_*",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) > 0) return GetArraySize(hReturnedArray);
	FindTargetnameByClass(-1,"env_*",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) > 0) return GetArraySize(hReturnedArray);
	FindTargetnameByClass(-1,"ai_*",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) > 0) return GetArraySize(hReturnedArray);
	FindTargetnameByClass(-1,"math_*",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) > 0) return GetArraySize(hReturnedArray);
	FindTargetnameByClass(-1,"game_*",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) > 0) return GetArraySize(hReturnedArray);
	FindTargetnameByClass(-1,"point_template",tmptarg,hReturnedArray);
	if (GetArraySize(hReturnedArray) < 1)
	{
		for (int i = MaxClients+1; i<GetMaxEntities(); i++)
		{
			if (IsValidEntity(i) && IsEntNetworkable(i))
			{
				if (HasEntProp(i,Prop_Data,"m_iName"))
				{
					char szTargetname[128];
					GetEntPropString(i,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
					if (StrContains(szTargetname,"\"",false) != -1) ReplaceString(szTargetname,sizeof(szTargetname),"\"","");
					if (StrContains(tmptarg,"*",false) == 0)
					{
						char targwithout[128];
						Format(targwithout,sizeof(targwithout),"%s",tmptarg);
						ReplaceString(targwithout,sizeof(targwithout),"*","");
						if (StrContains(szTargetname,targwithout) != -1)
						{
							GetEntityClassname(i,tmptarg,sizeof(tmptarg));
							if (FindValueInArray(hReturnedArray,i) == -1) PushArrayCell(hReturnedArray,i);
						}
					}
					else if (StrContains(tmptarg,"*",false) >= 1)
					{
						char targwithout[128];
						Format(targwithout,sizeof(targwithout),"%s",tmptarg);
						ReplaceString(targwithout,sizeof(targwithout),"*","");
						if (StrContains(szTargetname,targwithout) == 0)
						{
							GetEntityClassname(i,tmptarg,sizeof(tmptarg));
							if (FindValueInArray(hReturnedArray,i) == -1) PushArrayCell(hReturnedArray,i);
						}
					}
					else if (StrEqual(szTargetname,tmptarg))
					{
						GetEntityClassname(i,tmptarg,sizeof(tmptarg));
						if (FindValueInArray(hReturnedArray,i) == -1) PushArrayCell(hReturnedArray,i);
					}
				}
			}
		}
	}
	return GetArraySize(hReturnedArray);
}

public void FindTargetnameByClass(int ent, char cls[64], char tmptarg[128], Handle hReturnedArray)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if (HasEntProp(thisent,Prop_Data,"m_iName"))
		{
			char szTargetname[128];
			GetEntPropString(thisent,Prop_Data,"m_iName",szTargetname,sizeof(szTargetname));
			if (StrContains(tmptarg,"*",false) == 0)
			{
				char targwithout[128];
				Format(targwithout,sizeof(targwithout),"%s",tmptarg);
				ReplaceString(targwithout,sizeof(targwithout),"*","");
				if (StrContains(szTargetname,targwithout) != -1)
				{
					GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
					if (FindValueInArray(hReturnedArray,thisent) == -1) PushArrayCell(hReturnedArray,thisent);
				}
			}
			else if (StrContains(tmptarg,"*",false) >= 1)
			{
				char targwithout[128];
				Format(targwithout,sizeof(targwithout),"%s",tmptarg);
				ReplaceString(targwithout,sizeof(targwithout),"*","");
				if (StrContains(szTargetname,targwithout) == 0)
				{
					GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
					if (FindValueInArray(hReturnedArray,thisent) == -1) PushArrayCell(hReturnedArray,thisent);
				}
			}
			else if (StrEqual(szTargetname,tmptarg,false))
			{
				GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
				if (FindValueInArray(hReturnedArray,thisent) == -1) PushArrayCell(hReturnedArray,thisent);
			}
		}
		FindTargetnameByClass(thisent++,cls,tmptarg,hReturnedArray);
	}
	return;
}

void VoteMenuClose()
{
	delete g_hVoteMenu;
	g_hVoteMenu = null;
}