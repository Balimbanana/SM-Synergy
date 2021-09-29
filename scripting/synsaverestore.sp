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
bool IsVehicleMap = false;
bool dbg = false;
bool allowvotereloadsaves = false; //Set by cvar sm_reloadsaves
bool allowvotecreatesaves = false; //Set by cvar sm_createsaves
bool rmsaves = false; //Set by cvar sm_disabletransition
bool nodel = true; //Set by cvar sm_disabletransition 3
bool transitionply = false; //Set by cvar sm_disabletransition 2
bool fallbackequip = false; //Set by cvar sm_equipfallback_disable
bool reloadaftersetup = false;
bool BMActive = false;
bool SynLaterAct = false;
bool bLinuxAct = false;
bool SkipVer = false;
bool bTransitionMode = false;
int WeapList = -1;
int reloadtype = 0;
int logsv = -1;
int logplyprox = -1;
int saveresetm = 1;
int iCreatedTable = 0;
float votetime = 0.0;
float perclimit = 0.80; //Set by cvar sm_voterestore
float perclimitsave = 0.60; //Set by cvar sm_votecreatesave
float landmarkorigin[3];
float mapstarttime;

//Handle globalsarr = INVALID_HANDLE;
//Handle globalsiarr = INVALID_HANDLE;
Handle transitionid = INVALID_HANDLE;
Handle transitiondp = INVALID_HANDLE;
Handle transitionplyorigin = INVALID_HANDLE;
Handle transitionents = INVALID_HANDLE;
Handle globalstransition = INVALID_HANDLE;
Handle ignoreent = INVALID_HANDLE;
Handle timouthndl = INVALID_HANDLE;
Handle equiparr = INVALID_HANDLE;
ConVar hDelTransitionPly;
ConVar hDelTransitionEnts;
ConVar hLandMarkBox;
ConVar hLandMarkBoxSize;

char landmarkname[64];
char mapbuf[128];
char maptochange[64];
char prevmap[64];
char savedir[64];
char reloadthissave[32];

#define PLUGIN_VERSION "2.184"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synsaverestoreupdater.txt"

Menu g_hVoteMenu = null;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

enum voteType
{
	question
}

voteType g_voteType = question;

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
	//globalsarr = CreateArray(32);
	//globalsiarr = CreateArray(32);
	transitionid = CreateArray(128);
	transitiondp = CreateArray(128);
	transitionplyorigin = CreateArray(128);
	transitionents = CreateArray(256);
	globalstransition = CreateArray(16);
	ignoreent = CreateArray(256);
	equiparr = CreateArray(32);
	RegAdminCmd("savegame",savecurgame,ADMFLAG_RESERVATION,".");
	RegAdminCmd("loadgame",loadgame,ADMFLAG_PASSWORD,".");
	RegAdminCmd("deletesave",delsave,ADMFLAG_PASSWORD,".");
	RegConsoleCmd("votereload",votereloadchk);
	RegConsoleCmd("votereloadmap",votereloadmap);
	RegConsoleCmd("votereloadsave",votereload);
	RegConsoleCmd("voterecreatesave",votecreatesave);
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves");
	if (!DirExists(savepath)) CreateDirectory(savepath,511);
	Handle votereloadcvarh = CreateConVar("sm_reloadsaves", "1", "Enable anyone to vote to reload a saved game, default is 1", _, true, 0.0, true, 1.0);
	if (votereloadcvarh != INVALID_HANDLE) allowvotereloadsaves = GetConVarBool(votereloadcvarh);
	HookConVarChange(votereloadcvarh, votereloadcvar);
	CloseHandle(votereloadcvarh);
	Handle votecreatesavecvarh = CreateConVar("sm_createsaves", "1", "Enable anyone to vote to create a save game, default is 1", _, true, 0.0, true, 1.0);
	if (votecreatesavecvarh != INVALID_HANDLE) allowvotecreatesaves = GetConVarBool(votecreatesavecvarh);
	HookConVarChange(votecreatesavecvarh, votesavecvar);
	CloseHandle(votecreatesavecvarh);
	Handle votepercenth = CreateConVar("sm_voterestore", "0.80", "People need to vote to at least this percent to pass checkpoint and map reload.", _, true, 0.0, true, 1.0);
	perclimit = GetConVarFloat(votepercenth);
	HookConVarChange(votepercenth, restrictvotepercch);
	CloseHandle(votepercenth);
	Handle votecspercenth = CreateConVar("sm_votecreatesave", "0.60", "People need to vote to at least this percent to pass creating a save.", _, true, 0.0, true, 1.0);
	perclimitsave = GetConVarFloat(votecspercenth);
	HookConVarChange(votecspercenth, restrictvotepercsch);
	CloseHandle(votecspercenth);
	Handle disabletransitionh = CreateConVar("sm_disabletransition", "2", "Disable transition save/reloads. 2 rebuilds transitions using SourceMod. 3 rebuilds and will not delete certain save data.", _, true, 0.0, true, 3.0);
	if (GetConVarInt(disabletransitionh) >= 2)
	{
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
		if (GetConVarInt(disabletransitionh) == 3) nodel = true;
		else nodel = false;
		rmsaves = true;
		transitionply = true;
	}
	else if (GetConVarInt(disabletransitionh) == 1)
	{
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
		rmsaves = true;
		nodel = false;
		transitionply = false;
	}
	else if (GetConVarInt(disabletransitionh) == 0)
	{
		rmsaves = false;
		nodel = true;
		transitionply = false;
	}
	HookConVarChange(disabletransitionh, disabletransitionch);
	CloseHandle(disabletransitionh);
	Handle equipfallbh = CreateConVar("sm_equipfallback_disable", "0", "Disables fallback equips when player spawns after transition.", _, true, 0.0, true, 1.0);
	if (GetConVarBool(equipfallbh) == true) fallbackequip = false;
	else fallbackequip = true;
	HookConVarChange(equipfallbh, equipfallbch);
	CloseHandle(equipfallbh);
	Handle transitiondbgh = CreateConVar("sm_transitiondebug", "0", "Logs transition entities for both save and restore.", _, true, 0.0, true, 1.0);
	if (GetConVarBool(transitiondbgh) == true) dbg = true;
	else dbg = false;
	HookConVarChange(transitiondbgh, transitiondbgch);
	CloseHandle(transitiondbgh);
	transitiondbgh = FindConVar("sm_transitionskipver");
	if (transitiondbgh == INVALID_HANDLE) transitiondbgh = CreateConVar("sm_transitionskipver", "0", "Skip version check and run full transition overrides.", _, true, 0.0, true, 1.0);
	if (GetConVarBool(transitiondbgh) == true) SkipVer = true;
	else SkipVer = false;
	HookConVarChange(transitiondbgh, transitionskipverch);
	CloseHandle(transitiondbgh);
	transitiondbgh = FindConVar("sm_transition_mode");
	if (transitiondbgh == INVALID_HANDLE) transitiondbgh = CreateConVar("sm_transition_mode", "0", "Changes mode of what entities to transition. 0 is base list, 1 is all stable entities.", _, true, 0.0, true, 1.0);
	bTransitionMode = GetConVarBool(transitiondbgh);
	HookConVarChange(transitiondbgh, transitionmodech);
	CloseHandle(transitiondbgh);
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
	hDelTransitionPly = FindConVar("sm_transition_rmply");
	if (hDelTransitionPly == INVALID_HANDLE) hDelTransitionPly = CreateConVar("sm_transition_rmply", "0", "Remove player entities over map change. May increase stability.", _, true, 0.0, true, 1.0);
	hDelTransitionEnts = FindConVar("sm_transition_rments");
	if (hDelTransitionEnts == INVALID_HANDLE) hDelTransitionEnts = CreateConVar("sm_transition_rments", "1", "Remove transition ents after store.", _, true, 0.0, true, 1.0);
	hLandMarkBox = FindConVar("sm_transition_landmark_usebounds");
	if (hLandMarkBox == INVALID_HANDLE) hLandMarkBox = CreateConVar("sm_transition_landmark_usebounds", "1", "Transition entities in a bounding box around the info_landmark.", _, true, 0.0, true, 1.0);
	hLandMarkBoxSize = FindConVar("sm_transition_landmark_boundsize");
	if (hLandMarkBoxSize == INVALID_HANDLE) hLandMarkBoxSize = CreateConVar("sm_transition_landmark_boundsize", "200.0", "info_landmark transition bounding box scale size.", _, true, 5.0, true, 1000.0);
	RegServerCmd("changelevel",resettransition);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("GetCustomEntList");
	MarkNativeAsOptional("SynFixesReadCache");
}

public int Updater_OnPluginUpdated()
{
	if (timouthndl == INVALID_HANDLE)
	{
		Handle nullpl = INVALID_HANDLE;
		ReloadPlugin(nullpl);
	}
	else
	{
		reloadaftersetup = true;
	}
}

public void votereloadcvar(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0) allowvotereloadsaves = false;
	else allowvotereloadsaves = true;
}

public void votesavecvar(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0) allowvotecreatesaves = false;
	else allowvotecreatesaves = true;
}

public void restrictvotepercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public void restrictvotepercsch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimitsave = StringToFloat(newValue);
}

public void disabletransitionch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) >= 2)
	{
		if (StringToInt(newValue) == 3) nodel = true;
		else nodel = false;
		rmsaves = true;
		transitionply = true;
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
	}
	else if (StringToInt(newValue) == 1)
	{
		rmsaves = true;
		nodel = false;
		transitionply = false;
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
	}
	else if (StringToInt(newValue) == 0)
	{
		rmsaves = false;
		nodel = true;
		transitionply = false;
	}
}

public void equipfallbch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) fallbackequip = false;
	else fallbackequip = true;
}

public void transitiondbgch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) dbg = true;
	else dbg = false;
}

public void transitionskipverch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) SkipVer = true;
	else SkipVer = false;
}

public void transitionmodech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) bTransitionMode = true;
	else bTransitionMode = false;
}

public void transitionresetmch(Handle convar, const char[] oldValue, const char[] newValue)
{
	saveresetm = StringToInt(newValue);
	if (GetMapHistorySize() > -1)
	{
		if ((IsValidEntity(logsv)) && (logsv != 0)) AcceptEntityInput(logsv,"kill");
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
		Format(curmapchk,sizeof(curmapchk),"%s/%s.hl2",savedir,mapbuf);
		if (FileExists(curmapchk))
		{
			bAddCur = true;
		}
		else
		{
			Format(curmapchk,sizeof(curmapchk),"%s/autosave.hl1",savedir);
			if (FileExists(curmapchk))
			{
				if (FileSize(curmapchk) > 15)
					bAddCur = true;
			}
		}
	}
	else bAddCur = true;
	if (bAddCur) menu.AddItem("checkpoint","The current last checkpoint");
	else menu.AddItem("checkpoint","The current last checkpoint",ITEMDRAW_DISABLED);
	if (allowvotereloadsaves)
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
	if (allowvotecreatesaves)
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
	if (GetArraySize(equiparr) > 0)
	{
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
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
				if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorigin);
				else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorigin);
				if (HasEntProp(i,Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",plyangs);
				int vck = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
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
			if (WeapList != -1)
			{
				for (int j; j<104; j += 4)
				{
					int tmpi = GetEntDataEnt2(i,WeapList + j);
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
			char push[564];
			Format(push,sizeof(push),"%s,%1.f %1.f %1.f,%1.f %1.f %1.f,%s,%i %i %i %i %i,%s",SteamID,plyangs[0],plyangs[1],plyangs[2],plyorigin[0],plyorigin[1],plyorigin[2],curweap,curh,cura,medkitamm,crouching,suitset,ammbufchk);
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
						char targn[32];
						char mdl[64];
						float porigin[3];
						float angs[3];
						float speed = 0.0;
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",porigin);
						else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",porigin);
						GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
						char vehscript[64];
						char additionalequip[32];
						char spawnercls[64];
						char spawnertargn[64];
						char parentname[32];
						char npctarg[4];
						char npctargpath[32];
						char defanim[32];
						char response[64];
						int doorstate, sleepstate, sequence, parentattach, body, maxh, curh, sf, hdw, skin, state, npctype, invulnerable;
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
						if (HasEntProp(i,Prop_Data,"m_eDoorState")) doorstate = GetEntProp(i,Prop_Data,"m_eDoorState");
						if (HasEntProp(i,Prop_Data,"m_SleepState")) sleepstate = GetEntProp(i,Prop_Data,"m_SleepState");
						else sleepstate = -10;
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
						if (HasEntProp(i,Prop_Data,"m_ChildTargetName")) GetEntPropString(i,Prop_Data,"m_ChildTargetName",spawnertargn,sizeof(spawnertargn));
						if (HasEntProp(i,Prop_Data,"m_nSequence")) sequence = GetEntProp(i,Prop_Data,"m_nSequence");
						if (HasEntProp(i,Prop_Data,"m_iParentAttachment")) parentattach = GetEntProp(i,Prop_Data,"m_iParentAttachment");
						if (HasEntProp(i,Prop_Data,"m_nBody")) body = GetEntProp(i,Prop_Data,"m_nBody");
						if (HasEntProp(i,Prop_Data,"m_iszDefaultAnim")) GetEntPropString(i,Prop_Data,"m_iszDefaultAnim",defanim,sizeof(defanim));
						if (HasEntProp(i,Prop_Data,"m_flSpeed")) speed = GetEntPropFloat(i,Prop_Data,"m_flSpeed");
						if (HasEntProp(i,Prop_Data,"m_bInvulnerable")) invulnerable = GetEntProp(i,Prop_Data,"m_bInvulnerable");
						char pushch[256];
						Format(pushch,sizeof(pushch),"\"origin\" \"%f %f %f\"",porigin[0],porigin[1],porigin[2]);
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
						if (strlen(targn) > 0)
						{
							Format(pushch,sizeof(pushch),"\"targetname\" \"%s\"",targn);
							WriteFileLine(custentinf,pushch);
						}
						if (strlen(mdl) > 0)
						{
							Format(pushch,sizeof(pushch),"\"model\" \"%s\"",mdl);
							WriteFileLine(custentinf,pushch);
						}
						if (sleepstate != -10)
						{
							Format(pushch,sizeof(pushch),"\"sleepstate\" \"%i\"",sleepstate);
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
						if (strlen(spawnertargn) > 0)
						{
							Format(pushch,sizeof(pushch),"\"NPCTargetname\" \"%s\"",spawnertargn);
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
						if (doorstate != 0)
						{
							Format(pushch,sizeof(pushch),"\"doorstate\" \"%i\"",doorstate);
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
						if (speed > 0.0)
						{
							Format(pushch,sizeof(pushch),"\"speed\" \"%1.f\"",speed);
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
			char targn[128];
			GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
			Format(findpathname,128,"%s",targn);
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
		delthissave(info,param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void loadthissave(char[] info)
{
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
			dp = CreateDataPack();
			Handle reloadids = CreateArray(128);
			Handle reloadangs = CreateArray(128);
			Handle reloadorgs = CreateArray(128);
			Handle reloadammset = CreateArray(128);
			Handle reloadstatsset = CreateArray(128);
			Handle reloadcurweaps = CreateArray(128);
			char sets[6][64];
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
					PushArrayString(reloadids,sets[0]);
					PushArrayString(reloadangs,sets[1]);
					PushArrayString(reloadorgs,sets[2]);
					PushArrayString(reloadcurweaps,sets[3]);
					PushArrayString(reloadstatsset,sets[4+adjustarr]);
					ReplaceString(line,sizeof(line),sets[0],"");
					ReplaceString(line,sizeof(line),sets[1],"");
					ReplaceString(line,sizeof(line),sets[2],"");
					ReplaceString(line,sizeof(line),sets[3],"");
					ReplaceString(line,sizeof(line),sets[4],"");
					if ((strlen(sets[5]) > 0) && (adjustarr)) ReplaceString(line,sizeof(line),sets[5],"");
					ReplaceString(line,sizeof(line),",,,,,","");
					ReplaceString(line,sizeof(line),"bbb","");
					if (strlen(line) > 1) PushArrayString(reloadammset,line);
				}
			}
			CloseHandle(plyinf);
			WritePackCell(dp,reloadids);
			WritePackCell(dp,reloadangs);
			WritePackCell(dp,reloadorgs);
			WritePackCell(dp,reloadammset);
			WritePackCell(dp,reloadstatsset);
			WritePackCell(dp,reloadcurweaps);
			WritePackString(dp,sets[3]);
		}
		Handle savepathdp = CreateDataPack();
		WritePackString(savepathdp,savepath);
		CreateTimer(1.0,reloadtimer,savepathdp);
		CreateTimer(1.1,reloadtimersetupcl,dp);
	}
}

void delthissave(char[] info, int client)
{
	char saverm[256];
	BuildPath(Path_SM,saverm,sizeof(saverm),"data/SynSaves/%s/%s",mapbuf,info);
	Handle savedirh = OpenDirectory(saverm, false);
	if (savedirh == INVALID_HANDLE)
	{
		if (client == 0) PrintToServer("Save: %s does not exist.",info);
		else PrintToChat(client,"Save: %s does not exist.",info);
		delsave(client,0);
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
	delsave(client,0);
	return;
}

public Action reloadtimer(Handle timer, Handle savepathdp)
{
	int thereload = CreateEntityByName("player_loadsaved");
	DispatchSpawn(thereload);
	ActivateEntity(thereload);
	AcceptEntityInput(thereload, "Reload");
	if (GetArraySize(equiparr) > 0)
	{
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
	if (SynFixesRunning)
	{
		CreateTimer(0.1,reloadentcache,savepathdp);
	}
}

public Action reloadentcache(Handle timer, Handle savepathdp)
{
	char savepath[256];
	if (savepathdp != INVALID_HANDLE)
	{
		ResetPack(savepathdp);
		ReadPackString(savepathdp,savepath,sizeof(savepath));
		CloseHandle(savepathdp);
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

public Action reloadtimersetupcl(Handle timer, Handle dp)
{
	if (GetArraySize(equiparr) > 0)
	{
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		Handle reloadids = ReadPackCell(dp);
		Handle reloadangs = ReadPackCell(dp);
		Handle reloadorgs = ReadPackCell(dp);
		Handle reloadammset = ReadPackCell(dp);
		Handle reloadstatsset = ReadPackCell(dp);
		Handle reloadcurweaps = ReadPackCell(dp);
		CloseHandle(dp);
		if (GetArraySize(reloadids) > 0)
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
					int arrindx = FindStringInArray(reloadids,SteamID);
					char angch[32];
					char originch[32];
					char ammoch[600];
					char ammosets[64][32];
					char statsch[64];
					char statssets[5][24];
					if (arrindx != -1)
					{
						GetArrayString(reloadangs,arrindx,angch,sizeof(angch));
						GetArrayString(reloadorgs,arrindx,originch,sizeof(originch));
						if (GetArraySize(reloadammset) > 0)
						{
							GetArrayString(reloadammset,arrindx,ammoch,sizeof(ammoch));
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
						if (GetArraySize(reloadstatsset) > 0)
						{
							GetArrayString(reloadstatsset,arrindx,statsch,sizeof(statsch));
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
						if (GetArraySize(reloadcurweaps) > 0) GetArrayString(reloadcurweaps,arrindx,curweap,sizeof(curweap));
						if (strlen(curweap) > 0) ClientCommand(i,"use %s",curweap);
					}
					else
					{
						int rand = GetRandomInt(0,GetArraySize(reloadids)-1);
						GetArrayString(reloadangs,rand,angch,sizeof(angch));
						GetArrayString(reloadorgs,rand,originch,sizeof(originch));
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
		CloseHandle(reloadids);
		CloseHandle(reloadangs);
		CloseHandle(reloadorgs);
		CloseHandle(reloadammset);
		CloseHandle(reloadstatsset);
		CloseHandle(reloadcurweaps);
	}
}

public Action delsave(int client, int args)
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
			delthissave(h,client);
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
			char buff[32];
			g_voteType = question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(buff,sizeof(buff),"Reload Current Map?");
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 2;
		}
		else if ((StrEqual(info,"createsave",false)) && (votetime <= Time))
		{
			char buff[32];
			g_voteType = question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(buff,sizeof(buff),"Create Save Point?");
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 4;
		}
		else if ((StrEqual(info,"checkpoint",false)) && (votetime <= Time))
		{
			char buff[32];
			g_voteType = question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(buff,sizeof(buff),"Reload Last Checkpoint?");
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 1;
		}
		else if ((strlen(info) > 1) && (strlen(reloadthissave) < 1) && (votetime <= Time))
		{
			char buff[64];
			g_voteType = question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			Format(buff,sizeof(buff),"Reload the %s Save?",info);
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 3;
			Format(reloadthissave,sizeof(reloadthissave),info);
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
	 	if (g_voteType != question)
	 	{
			//an error occurred somewhere.
		}
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
		float perclimitlocal;
		if (reloadtype == 4) perclimitlocal = perclimitsave;
		else perclimitlocal = perclimit;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes;
		}
		
		percent = float(votes)/float(totalVotes);

		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,perclimitlocal) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t","Vote Failed", RoundToNearest(100.0*perclimitlocal), RoundToNearest(100.0*percent), totalVotes);
			Format(reloadthissave,sizeof(reloadthissave),"");
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
			else if ((reloadtype == 3) && (strlen(reloadthissave) > 0))
			{
				loadthissave(reloadthissave);
				Format(reloadthissave,sizeof(reloadthissave),"");
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
	mapstarttime = GetTickedTime()+2.0;
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
					float spawnposg[3];
					spawnposg[0] = -3106.0;
					spawnposg[1] = -9455.0;
					spawnposg[2] = -3077.0;
					TeleportEntity(spawnpos,spawnposg,NULL_VECTOR,NULL_VECTOR);
					DispatchSpawn(spawnpos);
					ActivateEntity(spawnpos);
				}
				int loginp = CreateEntityByName("logic_auto");
				if (loginp != -1)
				{
					DispatchKeyValue(loginp, "spawnflags","1");
					DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Enable,,0,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Trigger,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,TouchTest,,0.1,-1");
					DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_3rebuild,0,-1");
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
				}
				int iEnt = -1;
				char szTargn[32];
				while((iEnt = FindEntityByClassname(iEnt,"path_track")) != INVALID_ENT_REFERENCE)
				{
					if (IsValidEntity(iEnt))
					{
						if (HasEntProp(iEnt,Prop_Data,"m_iName"))
						{
							GetEntPropString(iEnt,Prop_Data,"m_iName",szTargn,sizeof(szTargn));
							if (StrEqual(szTargn,"pathTrack_elevator_top4",false))
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
					int starttp = CreateEntityByName("info_teleport_destination");
					if (starttp != -1)
					{
						DispatchKeyValue(starttp,"targetname","syn_startspawntp");
						float orgs[3];
						orgs[0] = 7737.0;
						orgs[1] = 9744.0;
						orgs[2] = -444.0;
						float angs[3];
						angs[1] = 90.0;
						TeleportEntity(starttp,orgs,angs,NULL_VECTOR);
						DispatchSpawn(starttp);
						ActivateEntity(starttp);
					}
					DispatchKeyValue(trigtp,"model","*13");
					DispatchKeyValue(trigtp,"spawnflags","1");
					DispatchKeyValue(trigtp,"target","syn_startspawntp");
					float orgs[3];
					orgs[0] = 7735.0;
					orgs[1] = 8150.0;
					orgs[2] = -395.0;
					float angs[3];
					angs[1] = 90.0;
					TeleportEntity(trigtp,orgs,angs,NULL_VECTOR);
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
					float tporigin[3];
					tporigin[0] = -3735.0;
					tporigin[1] = -5.0;
					tporigin[2] = -3440.0;
					TeleportEntity(trigtpstart,tporigin,NULL_VECTOR,NULL_VECTOR);
					trigtpstart = CreateEntityByName("trigger_teleport");
					DispatchKeyValue(trigtpstart,"spawnflags","1");
					DispatchKeyValue(trigtpstart,"targetname","syn_starttptransition");
					DispatchKeyValue(trigtpstart,"model","*1");
					DispatchKeyValue(trigtpstart,"target","syn_transition_dest");
					DispatchSpawn(trigtpstart);
					ActivateEntity(trigtpstart);
					tporigin[0] = -736.0;
					tporigin[1] = 864.0;
					tporigin[2] = -3350.0;
					TeleportEntity(trigtpstart,tporigin,NULL_VECTOR,NULL_VECTOR);
				}
			}
			else if (enterfrom03pb)
				enterfrom03pb = false;
			if ((enterfrom08pb) && (StrEqual(mapbuf,"d2_coast_07",false)))
			{
				if ((rmsaves) && (GetArraySize(transitionents) > 0)) findtransitionback(-1);
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
					float tporigin[3];
					tporigin[0] = 3200.0;
					tporigin[1] = 5216.0;
					tporigin[2] = 1544.0;
					TeleportEntity(trigtpstart,tporigin,NULL_VECTOR,NULL_VECTOR);
					trigtpstart = CreateEntityByName("trigger_teleport");
					DispatchKeyValue(trigtpstart,"spawnflags","1");
					DispatchKeyValue(trigtpstart,"targetname","syn_starttptransition");
					DispatchKeyValue(trigtpstart,"model","*9");
					DispatchKeyValue(trigtpstart,"target","syn_transition_dest");
					DispatchSpawn(trigtpstart);
					ActivateEntity(trigtpstart);
					tporigin[0] = -7616.0;
					tporigin[1] = 5856.0;
					tporigin[2] = 1601.0;
					TeleportEntity(trigtpstart,tporigin,NULL_VECTOR,NULL_VECTOR);
				}
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
			/*
			if (GetArraySize(globalsarr) > 0)
			{
				int loginp = -1;
				for (int i = 0;i<GetArraySize(globalsarr);i++)
				{
					char itmp[32];
					GetArrayString(globalsarr, i, itmp, sizeof(itmp));
					int itmpval = GetArrayCell(globalsiarr,i);
					if (!IsValidEntity(loginp))
					{
						loginp = CreateEntityByName("logic_auto");
						DispatchKeyValue(loginp, "spawnflags","1");
					}
					char formt[64];
					if (itmpval == 1)
						Format(formt,sizeof(formt),"%s,TurnOn,,0,-1",itmp);
					else
						Format(formt,sizeof(formt),"%s,TurnOff,,0,-1",itmp);
					DispatchKeyValue(loginp, "OnMapSpawn", formt);
					//PrintToServer("Setting %s to %i",itmp,itmpval);
				}
				if (IsValidEntity(loginp))
				{
					DispatchSpawn(loginp);
					ActivateEntity(loginp);
				}
			}
			*/
			findprevlvls(-1);
			reloadingmap = false;
		}
		//ClearArray(globalsarr);
		//ClearArray(globalsiarr);
		ClearArray(equiparr);
		ClearArray(ignoreent);
		IsVehicleMap = findvmap(-1);
		Format(reloadthissave,sizeof(reloadthissave),"");
		HookEntityOutput("trigger_changelevel","OnChangeLevel",onchangelevel);
		if (rmsaves)
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
						if ((StrContains(subfilen,"autosave.hl1",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,prevmap,false) == -1))
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
			if ((!SynLaterAct) || (SkipVer)) CreateTimer(0.1,redel);
			if ((logsv != -1) && (IsValidEntity(logsv)) && ((!SynLaterAct) || (SkipVer))) saveresetveh(false);
			if ((transitionply) && (IsVehicleMap))
			{
				findent(MaxClients+1,"info_player_equip");
				if (GetArraySize(equiparr) > 0)
				{
					for (int j; j<GetArraySize(equiparr); j++)
					{
						int jtmp = GetArrayCell(equiparr, j);
						if (IsValidEntity(jtmp))
							AcceptEntityInput(jtmp,"Disable");
					}
				}
				timouthndl = CreateTimer(121.0,transitiontimeout,_,TIMER_FLAG_NO_MAPCHANGE);
			}
			int alyxtransition = -1;
			bool alyxenter = false;
			float aljeepchk[3];
			float aljeepchkj[3];
			if (strlen(landmarkname) > 0)
			{
				findlandmark(-1,"info_landmark");
				if (SynFixesRunning)
				{
					char custentinffile[256];
					Format(custentinffile,sizeof(custentinffile),"%s\\customenttransitioninf.txt",savedir);
					if (FileExists(custentinffile,false))
					{
						ReplaceString(custentinffile,sizeof(custentinffile),"/","\\");
						SynFixesReadCache(0,custentinffile,landmarkorigin);
						DeleteFile(custentinffile,false);
					}
				}
				if (dbg) LogMessage("%i entities to restore over map change.",GetArraySize(transitionents));
				if (GetArraySize(transitionents) > 0)
				{
					for (int i = 0;i<GetArraySize(transitionents);i++)
					{
						Handle dp = GetArrayCell(transitionents,i);
						ResetPack(dp);
						char clsname[32];
						char targn[32];
						char mdl[64];
						bool editent = false;
						ReadPackString(dp,clsname,sizeof(clsname));
						ReadPackString(dp,targn,sizeof(targn));
						ReadPackString(dp,mdl,sizeof(mdl));
						if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
						if (StrContains(mdl,"*",false) != -1)
						{
							editent = true;
						}
						int curh = ReadPackCell(dp);
						float porigin[3];
						float angs[3];
						char vehscript[64];
						porigin[0] = ReadPackFloat(dp);
						porigin[1] = ReadPackFloat(dp);
						porigin[2] = ReadPackFloat(dp);
						porigin[0]+=landmarkorigin[0];
						porigin[1]+=landmarkorigin[1];
						porigin[2]+=landmarkorigin[2];
						angs[0] = ReadPackFloat(dp);
						angs[1] = ReadPackFloat(dp);
						angs[2] = ReadPackFloat(dp);
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
						int doorstate = ReadPackCell(dp);
						int sleepstate = ReadPackCell(dp);
						char npctype[4];
						ReadPackString(dp,npctype,sizeof(npctype));
						char solidity[4];
						ReadPackString(dp,solidity,sizeof(solidity));
						int gunenable = ReadPackCell(dp);
						int tkdmg = ReadPackCell(dp);
						int mvtype = ReadPackCell(dp);
						int gameend = ReadPackCell(dp);
						char gunenablech[4];
						Format(gunenablech,sizeof(gunenablech),"%i",gunenable);
						char defanim[32];
						ReadPackString(dp,defanim,sizeof(defanim));
						char response[64];
						ReadPackString(dp,response,sizeof(response));
						char scriptinf[1024];
						ReadPackString(dp,scriptinf,sizeof(scriptinf));
						bool ragdoll = false;
						if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"d2_prison_08",false)))
						{
							porigin[0] = -2497.0;
							porigin[1] = 2997.0;
							porigin[2] = 999.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"d3_c17_01",false)))
						{
							porigin[0] = -7180.0;
							porigin[1] = -1200.0;
							porigin[2] = 48.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep2_outland_05",false)))
						{
							porigin[0] = -2952.0;
							porigin[1] = 736.0;
							porigin[2] = 190.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep2_outland_06",false)))
						{
							porigin[0] = -448.0;
							porigin[1] = 112.0;
							porigin[2] = 878.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep2_outland_11b",false)))
						{
							porigin[0] = 453.0;
							porigin[1] = -9489.0;
							porigin[2] = -283.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep1_citadel_01",false)))
						{
							porigin[0] = -6208.0;
							porigin[1] = 6424.0;
							porigin[2] = 2685.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep1_citadel_02",false)))
						{
							porigin[0] = -8602.0;
							porigin[1] = 924.0;
							porigin[2] = 837.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep1_citadel_02b",false)))
						{
							porigin[0] = 1951.0;
							porigin[1] = 4367.0;
							porigin[2] = 2532.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep1_c17_00a",false)))
						{
							porigin[0] = 800.0;
							porigin[1] = 2600.0;
							porigin[2] = 353.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep1_c17_01",false)))
						{
							porigin[0] = 4881.0;
							porigin[1] = -339.0;
							porigin[2] = -203.0;
						}
						else if ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false)) && (StrEqual(mapbuf,"ep1_c17_02a",false)))
						{
							porigin[0] = 5364.0;
							porigin[1] = 6440.0;
							porigin[2] = -2511.0;
						}
						else if ((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(targn,"vort",false)) && (StrEqual(mapbuf,"ep2_outland_06",false)))
						{
							porigin[0] = -448.0;
							porigin[1] = 40.0;
							porigin[2] = 878.0;
						}
						else if ((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(targn,"vort",false)) && (StrEqual(mapbuf,"ep2_outland_04",false)))
						{
							porigin[0] = 4244.0;
							porigin[1] = -1708.0;
							porigin[2] = 425.0;
						}
						else if ((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(targn,"vort",false)) && (StrEqual(mapbuf,"ep2_outland_03",false)))
						{
							porigin[0] = -1300.0;
							porigin[1] = -3885.0;
							porigin[2] = -855.0;
						}
						else if ((StrEqual(clsname,"npc_barney",false)) && (StrEqual(targn,"barney",false)) && (StrEqual(mapbuf,"d3_c17_10a",false)))
						{
							porigin[0] = -4083.0;
							porigin[1] = 6789.0;
							porigin[2] = 48.0;
						}
						bool skipoow = false;
						if (((StrEqual(clsname,"npc_vortigaunt",false)) && (StrEqual(targn,"vort",false))) || ((StrEqual(clsname,"npc_barney",false)) && (StrEqual(targn,"barney",false))) || ((StrEqual(clsname,"npc_alyx",false)) && (StrEqual(targn,"alyx",false))))
						{
							skipoow = true;
							if (OutOfWorldBounds(porigin,2.0)) skipoow = false;
						}
						if (StrEqual(clsname,"prop_physics",false)) Format(clsname,sizeof(clsname),"prop_physics_override",false);
						else if (StrEqual(clsname,"prop_dynamic",false)) Format(clsname,sizeof(clsname),"prop_dynamic_override",false);
						else if (StrEqual(clsname,"prop_ragdoll",false))
						{
							Format(clsname,sizeof(clsname),"generic_actor");
							ragdoll = true;
						}
						int ent = -1;
						if (editent)
						{
							Handle returnarr = CreateArray(3);
							char tptarg[128];
							Format(tptarg,sizeof(tptarg),"%s",targn);
							SearchForClass(tptarg,returnarr);
							if (GetArraySize(returnarr) > 0)
							{
								int replace = GetArrayCell(returnarr,0);
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
							CloseHandle(returnarr);
						}
						else
						{
							Handle returnarr = CreateArray(3);
							char tptarg[128];
							Format(tptarg,sizeof(tptarg),"%s",targn);
							SearchForClass(tptarg,returnarr);
							if (GetArraySize(returnarr) > 0)
							{
								for (int k = 0;k<GetArraySize(returnarr);k++)
								{
									int dupeent = GetArrayCell(returnarr,k);
									if (IsValidEntity(dupeent))
									{
										char dupecls[64];
										GetEntityClassname(dupeent,dupecls,sizeof(dupecls));
										if (StrEqual(dupecls,"prop_dynamic",false)) Format(dupecls,sizeof(dupecls),"prop_dynamic_override");
										if (StrEqual(dupecls,"prop_physics",false)) Format(dupecls,sizeof(dupecls),"prop_physics_override");
										if (StrEqual(dupecls,clsname,false))
										{
											float dupepos[3];
											if (HasEntProp(dupeent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(dupeent,Prop_Data,"m_vecAbsOrigin",dupepos);
											else if (HasEntProp(dupeent,Prop_Send,"m_vecOrigin")) GetEntPropVector(dupeent,Prop_Send,"m_vecOrigin",dupepos);
											if (GetVectorDistance(porigin,dupepos,false) > 9.0) ent = CreateEntityByName(clsname);
										}
										else ent = CreateEntityByName(clsname);
									}
								}
							}
							else ent = CreateEntityByName(clsname);
							CloseHandle(returnarr);
						}
						if ((TR_PointOutsideWorld(porigin)) && (!skipoow))
						{
							if (dbg) LogMessage("Delete Transition Ent (OutOfWorld) %s info: Model \"%s\" TargetName \"%s\" Solid \"%i\" spawnflags \"%i\" movetype \"%i\"",clsname,mdl,targn,StringToInt(solidity),StringToInt(spawnflags),mvtype);
							if ((IsValidEntity(ent)) && (ent != 0)) AcceptEntityInput(ent,"kill");
							ent = -1;
						}
						if (ent != -1)
						{
							if (dbg) LogMessage("Restore Ent %s Transition info: Model \"%s\" TargetName \"%s\" Solid \"%i\" spawnflags \"%i\" movetype \"%i\" to origin \"%1.f %1.f %1.f\"",clsname,mdl,targn,StringToInt(solidity),StringToInt(spawnflags),mvtype,porigin[0],porigin[1],porigin[2]);
							bool beginseq = false;
							bool applypropafter = false;
							if (StrEqual(clsname,"npc_alyx",false))
							{
								alyxtransition = ent;
								aljeepchk[0] = porigin[0];
								aljeepchk[1] = porigin[1];
								aljeepchk[2] = porigin[2];
							}
							if (StrEqual(clsname,"prop_vehicle_jeep_episodic",false))
							{
								if (StrEqual(targn,"jeep",false))
								{
									char tmp[128];
									Format(tmp,sizeof(tmp),"alyx,EnterVehicle,%s,0,-1",targn);
									DispatchKeyValue(ent,"PlayerOn",tmp);
									Format(tmp,sizeof(tmp),"alyx,ExitVehicle,,0,-1");
									DispatchKeyValue(ent,"PlayerOff",tmp);
								}
								alyxenter = true;
								aljeepchkj[0] = porigin[0];
								aljeepchkj[1] = porigin[1];
								aljeepchkj[2] = porigin[2];
							}
							if (StrEqual(clsname,"info_particle_system",false)) DispatchKeyValue(ent,"effect_name",mdl);
							if (strlen(targn) > 0) DispatchKeyValue(ent,"targetname",targn);
							DispatchKeyValue(ent,"model",mdl);
							if (strlen(vehscript) > 0) DispatchKeyValue(ent,"VehicleScript",vehscript);
							if (strlen(additionalequip) > 0) DispatchKeyValue(ent,"AdditionalEquipment",additionalequip);
							if (strlen(hdwtype) > 0) DispatchKeyValue(ent,"hardware",hdwtype);
							if (strlen(parentname) > 0) DispatchKeyValue(ent,"ParentName",parentname);
							if (strlen(state) > 0) DispatchKeyValue(ent,"State",state);
							if (strlen(target) > 0) DispatchKeyValue(ent,"Target",target);
							if (HasEntProp(ent,Prop_Data,"m_Type")) DispatchKeyValue(ent,"citizentype",npctype);
							if (HasEntProp(ent,Prop_Data,"m_nSolidType")) DispatchKeyValue(ent,"solid",solidity);
							if (HasEntProp(ent,Prop_Data,"m_bHasGun")) DispatchKeyValue(ent,"EnableGun",gunenablech);
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
							if (strlen(parentname) > 0)
							{
								SetVariantString(parentname);
								AcceptEntityInput(ent,"SetParent");
								if ((StrEqual(clsname,"prop_dynamic_override",false)) || (StrEqual(clsname,"prop_dynamic",false)) || (StrEqual(clsname,"prop_physics_override",false)) || (StrEqual(clsname,"prop_physics",false))) AcceptEntityInput(ent,"Enable");
							}
							if (curh != 0) SetEntProp(ent,Prop_Data,"m_iHealth",curh);
							TeleportEntity(ent,porigin,angs,NULL_VECTOR);
							if ((HasEntProp(ent,Prop_Data,"m_eDoorState")) && (doorstate != 1)) SetEntProp(ent,Prop_Data,"m_eDoorState",doorstate);
							if (HasEntProp(ent,Prop_Data,"m_SleepState")) SetEntProp(ent,Prop_Data,"m_SleepState",sleepstate);
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
													if ((doorstate == 1) && (StrEqual(scriptexp[j],"m_angGoal",false)))
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
						}
						CloseHandle(dp);
					}
				}
			}
			if ((dbg) && (GetArraySize(transitionents) > 0)) LogMessage("ClearTransitionEnts Array after restore of %i ents",GetArraySize(transitionents));
			//ClearArrayHandles(transitionents);
			ClearArray(transitionents);
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
							char targn[16];
							GetEntPropString(aldouble2,Prop_Data,"m_iName",targn,sizeof(targn));
							if (StrEqual(targn,"alyx",false)) AcceptEntityInput(aldouble2,"kill");
						}
					}
				}
				if ((aldouble != -1) && (IsValidEntity(aldouble)) && (aldouble != alyxtransition))
				{
					char targn[16];
					GetEntPropString(aldouble,Prop_Data,"m_iName",targn,sizeof(targn));
					if (StrEqual(targn,"alyx",false)) AcceptEntityInput(aldouble,"kill");
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
						if (dbg) LogMessage("Alyx entered jalopy on transition at %1.f %1.f %1.f",aljeepchkj[0],aljeepchkj[1],aljeepchkj[2]);
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

public void Ep2ElevatorPass(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		int iEnt = -1;
		char szTargn[32];
		while((iEnt = FindEntityByClassname(iEnt,"scripted_sequence")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(iEnt))
			{
				if (HasEntProp(iEnt,Prop_Data,"m_iName"))
				{
					GetEntPropString(iEnt,Prop_Data,"m_iName",szTargn,sizeof(szTargn));
					if (StrEqual(szTargn,"vort_enter_on_elevator_ss_1",false))
					{
						AcceptEntityInput(iEnt,"CancelSequence");
					}
					else if (StrEqual(szTargn,"vort_ride_elevator_from_04",false))
					{
						AcceptEntityInput(iEnt,"BeginSequence");
					}
				}
			}
		}
		UnhookSingleEntityOutput(caller,output,Ep2ElevatorPass);
	}
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
		if (GetArraySize(globalstransition) > 0)
		{
			CreateTimer(0.1,rechkglobal,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action rechkglobal(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		for (int i = 0;i<GetArraySize(globalstransition);i++)
		{
			Handle dp = GetArrayCell(globalstransition,i);
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
			GetEntPropString(entity,Prop_Data,"m_globalstate",statechk,sizeof(statechk));
			if (StrEqual(statechk,m_globalstate,false))
			{
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
		}
	}
	return Plugin_Handled;
}

public bool OutOfWorldBounds(float origin[3], float scale)
{
	float vMins[3];
	float vMaxs[3];
	GetEntPropVector(0,Prop_Data,"m_WorldMins",vMins);
	GetEntPropVector(0,Prop_Data,"m_WorldMaxs",vMaxs);
	ScaleVector(vMins,scale);
	ScaleVector(vMaxs,scale);
	if ((origin[0] < vMins[0]) || (origin[1] < vMins[1]) || (origin[2] < vMins[2]) || (origin[0] > vMaxs[0]) || (origin[1] > vMaxs[1]) || (origin[2] > vMaxs[2]))
	{
		if (TR_PointOutsideWorld(origin))
			return true;
	}
	return false;
}

public Action redel(Handle timer)
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
	if ((rmsaves) && (reloadingmap))
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
		if (!nodel)
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
								if ((StrContains(subfilen,"autosave.hl1",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,prevmap,false) == -1))
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
		ClearArray(transitionid);
		ClearArrayHandles(transitiondp);
		ClearArray(transitiondp);
		ClearArray(transitionplyorigin);
		if (dbg) LogMessage("ClearTransitionEnts Array");
		ClearArrayHandles(transitionents);
		ClearArray(transitionents);
		ClearArrayHandles(globalstransition);
		ClearArray(globalstransition);
		ClearArray(equiparr);
		prevmap = "";
	}
}

public Action transitiontimeout(Handle timer)
{
	timouthndl = INVALID_HANDLE;
	ClearArray(transitionid);
	ClearArrayHandles(transitiondp);
	ClearArray(transitiondp);
	ClearArray(transitionplyorigin);
	if (GetArraySize(equiparr) > 0)
	{
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
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
	if (GetArraySize(equiparr) > 0)
	{
		for (int j; j<GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
			if (IsValidEntity(jtmp))
				AcceptEntityInput(jtmp,"Enable");
		}
	}
}

public Action resettransition(int args)
{
	if (!reloadingmap)
	{
		ClearArray(transitionid);
		ClearArrayHandles(transitiondp);
		ClearArray(transitiondp);
		ClearArray(transitionplyorigin);
		ClearArray(equiparr);
		prevmap = "";
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
	if (rmsaves)
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
		ClearArray(transitionid);
		ClearArrayHandles(transitiondp);
		ClearArray(transitiondp);
		ClearArray(transitionplyorigin);
		ClearArray(ignoreent);
		GetCurrentMap(prevmap,sizeof(prevmap));
		if (validchange) GetEntPropString(caller,Prop_Data,"m_szMapName",maptochange,sizeof(maptochange));
		else maptochange = "";
		if (StrEqual(maptochange,"sp_ending",false)) return Plugin_Continue;
		if ((StrEqual(prevmap,"d1_town_03",false)) && (StrEqual(maptochange,"d1_town_02",false)))
		{
			enterfrom03pb = true;
		}
		else if ((StrEqual(prevmap,"d2_coast_08",false)) && (StrEqual(maptochange,"d2_coast_07",false)))
		{
			enterfrom08pb = true;
		}
		else if ((StrEqual(prevmap,"ep2_outland_04",false)) && (StrEqual(maptochange,"ep2_outland_02",false)))
		{
			enterfrom04pb = true;
		}
		else if ((StrEqual(prevmap,"bm_c2a4g",false)) && (StrEqual(maptochange,"bm_c2a4fedt",false)))
		{
			enterfrom4g = true;
		}
		reloadingmap = true;
		if (!nodel)
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
								if ((StrContains(subfilen,"autosave.hl",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,prevmap,false) == -1))
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
		if (transitionply)
		{
			if (validchange) GetEntPropString(caller,Prop_Data,"m_szLandmarkName",landmarkname,sizeof(landmarkname));
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
			if ((hLandMarkBox.BoolValue) && (validchange))
			{
				mins[0] = landmarkorigin[0]-hLandMarkBoxSize.FloatValue;
				mins[1] = landmarkorigin[1]-hLandMarkBoxSize.FloatValue;
				mins[2] = landmarkorigin[2]-hLandMarkBoxSize.FloatValue;
				maxs[0] = landmarkorigin[0]+hLandMarkBoxSize.FloatValue;
				maxs[1] = landmarkorigin[1]+hLandMarkBoxSize.FloatValue;
				maxs[2] = landmarkorigin[2]+hLandMarkBoxSize.FloatValue;
				findtouchingents(mins,maxs,false);
			}
			if (BMActive) transitionglobals(-1);
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
					if ((FindStringInArray(transitionplyorigin,SteamID) != -1) && (IsPlayerAlive(i)))
					{
						//GetClientAbsOrigin(i,plyorigin);
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorigin);
						else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorigin);
						if (HasEntProp(i,Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",plyangs);
						plyorigin[0]-=landmarkorigin[0];
						plyorigin[1]-=landmarkorigin[1];
						plyorigin[2]-=landmarkorigin[2];
					}
					else
					{
						plyorigin[0] = 0.0;
						plyorigin[1] = 0.0;
						plyorigin[2] = 0.0;
					}
					PushArrayString(transitionid,SteamID);
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
					if (suitset) bFutureSuit = true;
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
					if (WeapList != -1)
					{
						for (int j; j<104; j += 4)
						{
							int tmpi = GetEntDataEnt2(i,WeapList + j);
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
					PushArrayCell(transitiondp,dp);
					if (dbg) LogMessage("Transition CL %N Transition info health: %i armor: %i ducking: %i Offset %1.f %1.f %1.f",i,curh,cura,crouching,plyorigin[0],plyorigin[1],plyorigin[2]);
					if (hDelTransitionPly.BoolValue) AcceptEntityInput(i,"kill");
				}
			}
		}
		else
		{
			Format(landmarkname,sizeof(landmarkname),"");
			landmarkorigin[0] = 0.0;
			landmarkorigin[1] = 0.0;
			landmarkorigin[2] = 0.0;
		}
	}
	return Plugin_Continue;
}

void findlandmark(int ent,char[] classname)
{
	int thisent = FindEntityByClassname(ent,classname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char targn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
		if (StrEqual(targn,landmarkname))
		{
			if (StrEqual(classname,"info_landmark",false)) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",landmarkorigin);
			else if (StrEqual(classname,"trigger_transition"))
			{
				float mins[3];
				float maxs[3];
				GetEntPropVector(thisent,Prop_Send,"m_vecMins",mins);
				GetEntPropVector(thisent,Prop_Send,"m_vecMaxs",maxs);
				if (dbg) LogMessage("Found trigger_transition %s",targn);
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
		char targn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
		if (StrEqual(targn,landmarkname))
		{
			float mins[3];
			float maxs[3];
			GetEntPropVector(thisent,Prop_Send,"m_vecMins",mins);
			GetEntPropVector(thisent,Prop_Send,"m_vecMaxs",maxs);
			if (dbg) LogMessage("Found trigger_transition %s",targn);
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
		if ((StrEqual(mapchbuf,prevmap,false)) && (!StrEqual(mapchbuf,"d1_town_02",false))) AcceptEntityInput(thisent,"Disable");
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
	char targn[32];
	char mdl[64];
	float porigin[3];
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
	if (dbg) LogMessage("Transition Mins %1.f %1.f %1.f Maxs %1.f %1.f %1.f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
	char custentinffile[256];
	char writemode[8];
	char parentglobal[16];
	Format(writemode,sizeof(writemode),"a");
	Format(custentinffile,sizeof(custentinffile),"%s\\customenttransitioninf.txt",savedir);
	if (!FileExists(custentinffile,false)) Format(writemode,sizeof(writemode),"w");
	ReplaceString(custentinffile,sizeof(custentinffile),"/","\\");
	Handle custentlist = INVALID_HANDLE;
	Handle custentinf = INVALID_HANDLE;
	if (SynFixesRunning)
	{
		custentlist = GetCustomEntList();
		custentinf = OpenFile(custentinffile,writemode);
	}
	char szTmp[64];
	float angax[3];
	for (int i = 1;i<GetMaxEntities()+1;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i) && (FindValueInArray(ignoreent,i) == -1))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (StrContains(clsname,"game_",false) == 0) continue;
			if ((SynLaterAct) && (!SkipVer))
			{
				if (custentlist != INVALID_HANDLE)
				{
					if ((FindStringInArray(custentlist,clsname) == -1) && (!StrEqual(clsname,"player",false)))
					{
						continue;
					}
				}
				else if (!StrEqual(clsname,"player",false)) continue;
			}
			int alwaystransition = 0;
			if (HasEntProp(i,Prop_Data,"m_bAlwaysTransition")) alwaystransition = GetEntProp(i,Prop_Data,"m_bAlwaysTransition");
			if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",porigin);
			else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",porigin);
			if ((i < MaxClients+1) && (i > 0))
			{
				if (IsPlayerAlive(i))
				{
					GetClientAbsOrigin(i,porigin);
					if (GetEntityRenderFx(i) == RENDERFX_DISTORT) alwaystransition = 1;
				}
			}
			if (StrEqual(clsname,"prop_door_rotating",false))
			{
				GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
				if ((StrEqual(targn,"door.into.09.garage",false)) || (SynLaterAct))
				{
					AcceptEntityInput(i,"kill");
					porigin[0] = mins[0]-mins[0];
					porigin[1] = mins[1]-mins[1];
					porigin[2] = mins[2]-mins[2];
					alwaystransition = -1;
					clsname = "";
				}
			}
			else if (StrEqual(clsname,"point_viewcontrol",false))
			{
				AcceptEntityInput(i,"kill");
				alwaystransition = -1;
				clsname = "";
			}
			if ((StrEqual(clsname,"npc_alyx",false)) || (StrEqual(clsname,"npc_vortigaunt",false)) || (StrEqual(clsname,"prop_vehicle_jeep_episodic",false)))
			{
				GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
				if ((!StrEqual(mapbuf,"d1_town_05",false)) || (SynLaterAct))
				{
					if ((StrEqual(targn,"alyx",false)) || (StrEqual(targn,"vort",false)) || (StrEqual(targn,"jeep",false)))
						alwaystransition = 1;
				}
			}
			else if ((StrEqual(clsname,"npc_monk",false)) && (StrEqual(mapbuf,"d1_town_02",false)) && (StrEqual(maptochange,"d1_town_02a",false)))
			{
				alwaystransition = 1;
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
				if ((alwaystransition) || ((porigin[0] > mins[0]) && (porigin[1] > mins[1]) && (porigin[2] > mins[2]) && (porigin[0] < maxs[0]) && (porigin[1] < maxs[1]) && (porigin[2] < maxs[2]) && (IsValidEntity(i))))
				{
					//Add func_tracktrain check if exists on next map OnTransition might not fire
					bool bPasschk = false;
					if (!bTransitionMode)
					{
						if (((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_",false) != -1) || (StrContains(clsname,"item_",false) != -1) || (StrContains(clsname,"weapon_",false) != -1)) && (!StrEqual(clsname,"item_ammo_drop",false)) && (!StrEqual(clsname,"item_health_drop",false)) && (!StrEqual(clsname,"npc_template_maker",false)) && (!StrEqual(clsname,"npc_barnacle_tongue_tip",false)) && (!StrEqual(clsname,"light_dynamic",false)) && (!StrEqual(clsname,"info_particle_system",false)) && (!StrEqual(clsname,"npc_maker",false)) && (!StrEqual(clsname,"npc_antlion_template_maker",false)) && (!StrEqual(clsname,"npc_heli_avoidsphere",false)) && (StrContains(clsname,"env_",false) == -1) && (!StrEqual(clsname,"info_landmark",false)) && (!StrEqual(clsname,"shadow_control",false)) && (!StrEqual(clsname,"player",false)) && (StrContains(clsname,"light_",false) == -1) && (!StrEqual(clsname,"predicted_viewmodel",false)))
						{
							bPasschk = true;
						}
					}
					else if ((!StrEqual(clsname,"player_loadsaved",false)) && (!StrEqual(clsname,"path_track",false)) && (!StrEqual(clsname,"npc_template_maker",false)) && (StrContains(clsname,"rope",false) == -1) && (StrContains(clsname,"phys",false) != 0) && (!StrEqual(clsname,"item_ammo_drop",false)) && (!StrEqual(clsname,"item_health_drop",false)) && (!StrEqual(clsname,"beam",false)) && (!StrEqual(clsname,"npc_barnacle_tongue_tip",false)) && (!StrEqual(clsname,"info_particle_system",false)) && (!StrEqual(clsname,"npc_maker",false)) && (!StrEqual(clsname,"npc_antlion_template_maker",false)) && (!StrEqual(clsname,"npc_heli_avoidsphere",false)) && (StrContains(clsname,"env_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (!StrEqual(clsname,"info_landmark",false)) && (!StrEqual(clsname,"shadow_control",false)) && (!StrEqual(clsname,"player",false)) && (StrContains(clsname,"light_",false) == -1) && (!StrEqual(clsname,"point_spotlight",false)) && (!StrEqual(clsname,"predicted_viewmodel",false)))
					{
						bPasschk = true;
					}
					if (bPasschk)
					{
						if (HasEntProp(i,Prop_Data,"m_ModelName")) GetEntPropString(i,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if (StrContains(mdl,"*",false) != -1)
						{
							//LogError("Attempt to transition ent with precached model %s %s",clsname,mdl);
							PushArrayCell(ignoreent,i);
						}
						else
						{
							if ((remove) && (i > MaxClients))
							{
								AcceptEntityInput(i,"kill");
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
								porigin[0]-=landmarkorigin[0];
								porigin[1]-=landmarkorigin[1];
								porigin[2]-=landmarkorigin[2];
								GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
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
								char scriptinf[1024];
								int doorstate, sleepstate, gunenable, tkdmg, mvtype, gameend;
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
									PushArrayCell(ignoreent,i);
								}
								if (par != -1)
								{
									if (StrContains(clsname,"weapon_",false) != -1)
									{
										if (dp != INVALID_HANDLE) CloseHandle(dp);
										dp = INVALID_HANDLE;
										transitionthis = false;
										PushArrayCell(ignoreent,i);
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
												PushArrayCell(ignoreent,i);
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
									PushArrayCell(ignoreent,i);
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
								if (HasEntProp(i,Prop_Data,"m_eDoorState")) doorstate = GetEntProp(i,Prop_Data,"m_eDoorState");
								if (HasEntProp(i,Prop_Data,"m_SleepState")) sleepstate = GetEntProp(i,Prop_Data,"m_SleepState");
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
								if (HasEntProp(i,Prop_Data,"m_bHasGun")) gunenable = GetEntProp(i,Prop_Data,"m_bHasGun");
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
									float speed = GetEntPropFloat(i,Prop_Data,"m_flSpeed");
									if (speed > 0.0) Format(scriptinf,sizeof(scriptinf),"%sspeed %1.f ",scriptinf,speed);
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
										char spawnertargn[64];
										if (HasEntProp(i,Prop_Data,"m_iMaxHealth")) maxh = GetEntProp(i,Prop_Data,"m_iMaxHealth");
										if (HasEntProp(i,Prop_Data,"m_iszNPCClassname")) GetEntPropString(i,Prop_Data,"m_iszNPCClassname",spawnercls,sizeof(spawnercls));
										if (HasEntProp(i,Prop_Data,"m_ChildTargetName")) GetEntPropString(i,Prop_Data,"m_ChildTargetName",spawnertargn,sizeof(spawnertargn));
										if (HasEntProp(i,Prop_Data,"m_nSequence")) sequence = GetEntProp(i,Prop_Data,"m_nSequence");
										if (HasEntProp(i,Prop_Data,"m_iParentAttachment")) parentattach = GetEntProp(i,Prop_Data,"m_iParentAttachment");
										if (HasEntProp(i,Prop_Data,"m_nBody")) body = GetEntProp(i,Prop_Data,"m_nBody");
										WriteFileLine(custentinf,"{");
										char pushch[256];
										Format(pushch,sizeof(pushch),"\"origin\" \"%f %f %f\"",porigin[0],porigin[1],porigin[2]);
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
										if (strlen(targn) > 0)
										{
											Format(pushch,sizeof(pushch),"\"targetname\" \"%s\"",targn);
											WriteFileLine(custentinf,pushch);
										}
										if (strlen(mdl) > 0)
										{
											Format(pushch,sizeof(pushch),"\"model\" \"%s\"",mdl);
											WriteFileLine(custentinf,pushch);
										}
										if (sleepstate != -10)
										{
											Format(pushch,sizeof(pushch),"\"sleepstate\" \"%i\"",sleepstate);
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
										if (strlen(spawnertargn) > 0)
										{
											Format(pushch,sizeof(pushch),"\"NPCTargetname\" \"%s\"",spawnertargn);
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
										if (doorstate != 0)
										{
											Format(pushch,sizeof(pushch),"\"doorstate\" \"%i\"",doorstate);
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
										WritePackString(dp,targn);
										WritePackString(dp,mdl);
										WritePackCell(dp,curh);
										WritePackFloat(dp,porigin[0]);
										WritePackFloat(dp,porigin[1]);
										WritePackFloat(dp,porigin[2]);
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
										WritePackCell(dp,doorstate);
										WritePackCell(dp,sleepstate);
										WritePackString(dp,npctype);
										WritePackString(dp,solidity);
										WritePackCell(dp,gunenable);
										WritePackCell(dp,tkdmg);
										WritePackCell(dp,mvtype);
										WritePackCell(dp,gameend);
										WritePackString(dp,defanim);
										WritePackString(dp,response);
										if (strlen(scriptinf) > 0) WritePackString(dp,scriptinf);
										WritePackString(dp,"endofpack");
										PushArrayCell(transitionents,dp);
										PushArrayCell(ignoreent,i);
									}
									if (dbg) LogMessage("Save Transition %s TargetName \"%s\" Model \"%s\" Offset \"%1.f %1.f %1.f\"",clsname,targn,mdl,porigin[0],porigin[1],porigin[2]);
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
						PushArrayString(transitionplyorigin,SteamID);
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
	if (hDelTransitionEnts.BoolValue)
	{
		for (int i = 0;i<GetArraySize(ignoreent);i++)
		{
			int j = GetArrayCell(ignoreent,i);
			if ((IsValidEntity(j)) && (j != 0)) AcceptEntityInput(j,"kill");
		}
	}
}

void transitionglobals(int ent)
{
	int thisent = FindEntityByClassname(ent,"env_global");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char m_globalstate[64];
		char m_iName[64];
		int m_triggermode,m_initialstate,m_counter,m_fEffects,m_lifeState,m_iHealth,m_iMaxHealth,m_iEFlags,m_spawnflags,m_fFlags;
		Handle globaldp = CreateDataPack();
		if (HasEntProp(thisent,Prop_Data,"m_globalstate")) GetEntPropString(thisent,Prop_Data,"m_globalstate",m_globalstate,sizeof(m_globalstate));
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
		PushArrayCell(globalstransition,globaldp);
		transitionglobals(thisent++);
	}
}

void transitionthisent(int i)
{
	if (!IsValidEntity(i)) return;
	char clsname[32];
	GetEntityClassname(i,clsname,sizeof(clsname));
	char targn[32];
	char mdl[64];
	float porigin[3];
	float angs[3];
	if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",porigin);
	else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",porigin);
	Handle dp = CreateDataPack();
	porigin[0]-=landmarkorigin[0];
	porigin[1]-=landmarkorigin[1];
	porigin[2]-=landmarkorigin[2];
	GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
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
	char scriptinf[1024];
	char scrtmp[64];
	char defanim[32];
	int doorstate, sleepstate, gunenable, tkdmg, mvtype, gameend;
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
				AcceptEntityInput(i,"kill");
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
	if (HasEntProp(i,Prop_Data,"m_eDoorState")) doorstate = GetEntProp(i,Prop_Data,"m_eDoorState");
	if (HasEntProp(i,Prop_Data,"m_SleepState")) sleepstate = GetEntProp(i,Prop_Data,"m_SleepState");
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
		float speed = GetEntPropFloat(i,Prop_Data,"m_flSpeed");
		if (speed > 0.0) Format(scriptinf,sizeof(scriptinf),"%sspeed %1.f ",scriptinf,speed);
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
	if (HasEntProp(i,Prop_Data,"m_bHasGun")) gunenable = GetEntProp(i,Prop_Data,"m_bHasGun");
	if (HasEntProp(i,Prop_Data,"m_takedamage")) tkdmg = GetEntProp(i,Prop_Data,"m_takedamage");
	if (HasEntProp(i,Prop_Data,"movetype")) mvtype = GetEntProp(i,Prop_Data,"movetype");
	if (HasEntProp(i,Prop_Data,"m_bGameEndAlly")) gameend = GetEntProp(i,Prop_Data,"m_bGameEndAlly");
	if (HasEntProp(i,Prop_Data,"m_iszDefaultAnim")) GetEntPropString(i,Prop_Data,"m_iszDefaultAnim",defanim,sizeof(defanim));
	if (HasEntProp(i,Prop_Data,"m_iszResponseContext")) GetEntPropString(i,Prop_Data,"m_iszResponseContext",response,sizeof(response));
	TrimString(scriptinf);
	WritePackString(dp,clsname);
	WritePackString(dp,targn);
	WritePackString(dp,mdl);
	WritePackCell(dp,curh);
	WritePackFloat(dp,porigin[0]);
	WritePackFloat(dp,porigin[1]);
	WritePackFloat(dp,porigin[2]);
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
	WritePackCell(dp,doorstate);
	WritePackCell(dp,sleepstate);
	WritePackString(dp,npctype);
	WritePackString(dp,solidity);
	WritePackCell(dp,gunenable);
	WritePackCell(dp,tkdmg);
	WritePackCell(dp,mvtype);
	WritePackCell(dp,gameend);
	WritePackString(dp,defanim);
	WritePackString(dp,response);
	WritePackString(dp,scriptinf);
	PushArrayCell(transitionents,dp);
	PushArrayCell(ignoreent,i);
	return;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (transitionply)
	{
		int client = GetClientOfUserId(GetEventInt(event,"userid"));
		CreateTimer(0.1, transitionspawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}
/*
public Action restoreaim(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		float restoreang[3];
		ResetPack(dp);
		int cl = ReadPackCell(dp);
		if ((IsClientInGame(cl)) && (IsPlayerAlive(cl)))
		{
			restoreang[1] = ReadPackFloat(dp);
			TeleportEntity(cl,NULL_VECTOR,restoreang,NULL_VECTOR);
		}
		CloseHandle(dp);
	}
	return Plugin_Handled;
}
*/

public void OnClientAuthorized(int client, const char[] szAuth)
{
	if ((rmsaves) && ((!SynLaterAct) || (SkipVer)))
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
		if ((!nodel) && (!StrEqual(mapbuf,"ep1_citadel_00",false)))
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
	if (StrContains(mapbuf,"oc_spaceinvaders",false) == -1)
	{
		float Time = GetTickedTime();
		if (mapstarttime <= Time)
		{
			if ((rmsave) && (!nodel) && (strlen(savedir) > 0))
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
								if ((StrContains(subfilen,"autosave.hl1",false) == -1) && (StrContains(subfilen,"customenttransitioninf.txt",false) == -1) && (StrContains(subfilen,prevmap,false) == -1))
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
			int vehicles[128];
			float steerpos[128];
			int vehon[128];
			float throttle[128];
			int speed[128];
			float restoreang[3];
			float ang0[128];
			float ang1[128];
			float ang2[128];
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
								if (HasEntProp(vehicles[i],Prop_Data,"m_nSpeed")) speed[i] = GetEntProp(vehicles[i],Prop_Data,"m_nSpeed");
								if (HasEntProp(vehicles[i],Prop_Data,"m_angRotation")) GetEntPropVector(i,Prop_Data,"m_angRotation",restoreang);
								ang1[i] = restoreang[1];
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
						if (HasEntProp(vehicles[i],Prop_Data,"m_nSpeed")) SetEntProp(vehicles[i],Prop_Data,"m_nSpeed",speed[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_iSoundGear")) SetEntProp(vehicles[i],Prop_Data,"m_iSoundGear",gearsound[i]);
						if (HasEntProp(vehicles[i],Prop_Data,"m_controls.handbrake")) SetEntProp(vehicles[i],Prop_Data,"m_controls.handbrake",1);
						restoreang[0] = ang0[i];
						restoreang[1] = ang1[i];
						restoreang[2] = ang2[i];
						/*
						Handle dp = CreateDataPack();
						WritePackCell(dp,i);
						WritePackFloat(dp,ang1[i]);
						CreateTimer(0.01,
						*/
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
		int arrindx = FindStringInArray(transitionid,SteamID);
		if (arrindx != -1)
		{
			if (!BMActive)
			{
				if (GetArraySize(equiparr) < 1) findent(MaxClients+1,"info_player_equip");
				//Possibility of no equips found.
				bool recheck = false;
				if (GetArraySize(equiparr) > 0)
				{
					for (int j; j<GetArraySize(equiparr); j++)
					{
						int jtmp = GetArrayCell(equiparr, j);
						if (IsValidEntity(jtmp))
						{
							if (IsEntNetworkable(jtmp))
							{
								char clscheck[32];
								GetEntityClassname(jtmp,clscheck,sizeof(clscheck));
								if (StrEqual(clscheck,"info_player_equip",false))
								{
									if (IsVehicleMap)
										AcceptEntityInput(jtmp,"Disable");
								}
								else
								{
									ClearArray(equiparr);
									findent(MaxClients+1,"info_player_equip");
									recheck = true;
									break;
								}
							}
						}
					}
				}
				if ((recheck) && (GetArraySize(equiparr) > 0))
				{
					for (int j; j<GetArraySize(equiparr); j++)
					{
						int jtmp = GetArrayCell(equiparr, j);
						if ((IsValidEntity(jtmp)) && (IsVehicleMap))
							AcceptEntityInput(jtmp,"Disable");
					}
				}
			}
			char ammoset[64];
			char ammosetexp[32][4];
			char ammosettype[64];
			char ammosetamm[16];
			char curweap[64];
			RemoveFromArray(transitionid,arrindx);
			if (GetArraySize(transitiondp) > arrindx)
			{
				Handle dp = GetArrayCell(transitiondp,arrindx);
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
				if ((((plyorigin[0] == 0.0) && (plyorigin[1] == 0.0) && (plyorigin[2] == 0.0))) || (strlen(landmarkname) < 1)) teleport = false;
				plyorigin[0]+=landmarkorigin[0];
				plyorigin[1]+=landmarkorigin[1];
				plyorigin[2]+=landmarkorigin[2];
				if (TR_PointOutsideWorld(plyorigin)) teleport = false;
				if (dbg) LogMessage("Restore CL %N Transition info %i health %i armor Offset \"%1.f %1.f %1.f\" moveto %i",client,curh,cura,plyorigin[0],plyorigin[1],plyorigin[2],teleport);
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
				RemoveFromArray(transitiondp,arrindx);
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
					if (GetArraySize(equiparr) > 0)
					{
						for (int j; j<GetArraySize(equiparr); j++)
						{
							int jtmp = GetArrayCell(equiparr, j);
							if (IsValidEntity(jtmp))
							{
								if (IsEntNetworkable(jtmp))
								{
									char clscheck[32];
									GetEntityClassname(jtmp,clscheck,sizeof(clscheck));
									if (StrEqual(clscheck,"info_player_equip",false))
									{
										if (IsVehicleMap) AcceptEntityInput(jtmp,"Disable");
										AcceptEntityInput(jtmp,"EquipPlayer",client);
										EquipCustom(jtmp,client);
									}
									else
									{
										ClearArray(equiparr);
										findent(MaxClients+1,"info_player_equip");
										recheck = true;
										break;
									}
								}
							}
						}
					}
					if ((recheck) && (GetArraySize(equiparr) > 0))
					{
						for (int j; j<GetArraySize(equiparr); j++)
						{
							int jtmp = GetArrayCell(equiparr, j);
							if (IsValidEntity(jtmp))
							{
								if (IsVehicleMap) AcceptEntityInput(jtmp,"Disable");
								AcceptEntityInput(jtmp,"EquipPlayer",client);
								EquipCustom(jtmp,client);
							}
						}
					}
					if ((GetArraySize(equiparr) < 1) && (!StrEqual(mapbuf,"bm_c0a0c",false)) && (!StrEqual(mapbuf,"bm_c1a0a",false)) && (!StrEqual(mapbuf,"sp_intro",false)) && (!StrEqual(mapbuf,"d1_trainstation_05",false)) && (!StrEqual(mapbuf,"ce_01",false))) CreateTimer(0.1,delayequip,client);
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
	if (fallbackequip) findentwdis(MaxClients+1,"info_player_equip");
	if ((IsClientConnected(client)) && (IsValidEntity(client)) && (IsClientInGame(client)) && (IsPlayerAlive(client)))
	{
		if (GetArraySize(equiparr) > 0)
		{
			for (int j; j<GetArraySize(equiparr); j++)
			{
				int jtmp = GetArrayCell(equiparr, j);
				if (IsValidEntity(jtmp))
				{
					if (IsVehicleMap) AcceptEntityInput(jtmp,"Disable");
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
					if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
					if (WeapList != -1)
					{
						char clschk[64];
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
		char targn[4];
		GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
		if ((bdisabled == 0) && (FindValueInArray(equiparr,thisent) == -1))
			PushArrayCell(equiparr,thisent);
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
		char targneq[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",targneq,sizeof(targneq));
		if (((StrEqual(targneq,"syn_equip_start",false)) || (StrEqual(targneq,"syn_equipment_base",false))) && (FindValueInArray(equiparr,thisent) == -1))
		{
			PushArrayCell(equiparr,thisent);
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
		AcceptEntityInput(thisent,"Kill");
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
/*
public Action findglobalsact(int client, int args)
{
	ClearArray(globalsarr);
	ClearArray(globalsiarr);
	findglobals(-1,"env_global");
	return Plugin_Handled;
}

public Action findglobals(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char prevtmp[16];
		GetEntPropString(thisent,Prop_Data,"m_iName",prevtmp,sizeof(prevtmp));
		char ctst[32];
		GetEntPropString(thisent,Prop_Data,"m_globalstate",ctst,sizeof(ctst));
		//PrintToServer(ctst);
		int loginp = CreateEntityByName("logic_auto");
		DispatchKeyValue(loginp, "spawnflags","1");
		DispatchKeyValue(loginp, "globalstate",ctst);
		char ctstinph[64];
		Format(ctstinph,sizeof(ctstinph),"%s,SetCounter,1,0,-1",prevtmp);
		DispatchKeyValue(loginp,"OnMapSpawn",ctstinph);
		DispatchSpawn(loginp);
		ActivateEntity(loginp);
		CreateTimer(0.5,loginpwait,thisent);
		findglobals(thisent++,clsname);
	}
	return Plugin_Handled;
}

public Action loginpwait(Handle timer, any thisent)
{
	if (IsValidEntity(thisent))
	{
		AcceptEntityInput(thisent,"GetCounter");
		char prevtmp[16];
		GetEntPropString(thisent,Prop_Data,"m_iName",prevtmp,sizeof(prevtmp));
		int initstate = GetEntProp(thisent,Prop_Data,"m_initialstate");
		int offs = FindDataMapInfo(thisent, "m_outCounter");
		int curstate = GetEntData(thisent, offs);
		//PrintToServer("%s %i %i",prevtmp,initstate,curstate);
		if((FindStringInArray(globalsarr, prevtmp) == -1) && (curstate != initstate))
		{
			PushArrayString(globalsarr, prevtmp);
			PushArrayCell(globalsiarr, curstate);
		}
	}
}
*/
int SearchForClass(char tmptarg[128], Handle returnarr)
{
	findtargnbyclass(-1,"logic_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclass(-1,"info_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclass(-1,"env_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclass(-1,"ai_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclass(-1,"math_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclass(-1,"game_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclass(-1,"point_template",tmptarg,returnarr);
	if (GetArraySize(returnarr) < 1)
	{
		for (int i = MaxClients+1; i<GetMaxEntities(); i++)
		{
			if (IsValidEntity(i) && IsEntNetworkable(i))
			{
				if (HasEntProp(i,Prop_Data,"m_iName"))
				{
					char targn[128];
					GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
					if (StrContains(targn,"\"",false) != -1) ReplaceString(targn,sizeof(targn),"\"","");
					if (StrContains(tmptarg,"*",false) == 0)
					{
						char targwithout[128];
						Format(targwithout,sizeof(targwithout),"%s",tmptarg);
						ReplaceString(targwithout,sizeof(targwithout),"*","");
						if (StrContains(targn,targwithout) != -1)
						{
							GetEntityClassname(i,tmptarg,sizeof(tmptarg));
							if (FindValueInArray(returnarr,i) == -1) PushArrayCell(returnarr,i);
						}
					}
					else if (StrContains(tmptarg,"*",false) >= 1)
					{
						char targwithout[128];
						Format(targwithout,sizeof(targwithout),"%s",tmptarg);
						ReplaceString(targwithout,sizeof(targwithout),"*","");
						if (StrContains(targn,targwithout) == 0)
						{
							GetEntityClassname(i,tmptarg,sizeof(tmptarg));
							if (FindValueInArray(returnarr,i) == -1) PushArrayCell(returnarr,i);
						}
					}
					else if (StrEqual(targn,tmptarg))
					{
						GetEntityClassname(i,tmptarg,sizeof(tmptarg));
						if (FindValueInArray(returnarr,i) == -1) PushArrayCell(returnarr,i);
					}
				}
			}
		}
	}
	return GetArraySize(returnarr);
}

public void findtargnbyclass(int ent, char cls[64], char tmptarg[128], Handle returnarr)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if (HasEntProp(thisent,Prop_Data,"m_iName"))
		{
			char targn[128];
			GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
			if (StrContains(tmptarg,"*",false) == 0)
			{
				char targwithout[128];
				Format(targwithout,sizeof(targwithout),"%s",tmptarg);
				ReplaceString(targwithout,sizeof(targwithout),"*","");
				if (StrContains(targn,targwithout) != -1)
				{
					GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
					if (FindValueInArray(returnarr,thisent) == -1) PushArrayCell(returnarr,thisent);
				}
			}
			else if (StrContains(tmptarg,"*",false) >= 1)
			{
				char targwithout[128];
				Format(targwithout,sizeof(targwithout),"%s",tmptarg);
				ReplaceString(targwithout,sizeof(targwithout),"*","");
				if (StrContains(targn,targwithout) == 0)
				{
					GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
					if (FindValueInArray(returnarr,thisent) == -1) PushArrayCell(returnarr,thisent);
				}
			}
			else if (StrEqual(targn,tmptarg,false))
			{
				GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
				if (FindValueInArray(returnarr,thisent) == -1) PushArrayCell(returnarr,thisent);
			}
		}
		findtargnbyclass(thisent++,cls,tmptarg,returnarr);
	}
	return;
}

void VoteMenuClose()
{
	delete g_hVoteMenu;
	g_hVoteMenu = null;
}