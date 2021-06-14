#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <synfixes>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#tryinclude <mapchooser>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;

int debuglvl = 0;
int collisiongroup = -1;
char mapbuf[64];
char ChapterTitle[64];
char PreviousTitle[64];
Handle equiparr = INVALID_HANDLE;
Handle entlist = INVALID_HANDLE;
Handle entnames = INVALID_HANDLE;
Handle physboxarr = INVALID_HANDLE;
Handle physboxharr = INVALID_HANDLE;
Handle elevlist = INVALID_HANDLE;
Handle inputsarrorigincls = INVALID_HANDLE;
Handle ignoretrigs = INVALID_HANDLE;
Handle dctimeoutarr = INVALID_HANDLE;
Handle SFEntInputHook = INVALID_HANDLE;
Handle addedinputs = INVALID_HANDLE;
float entrefresh = 0.0;
float removertimer = 30.0;
int WeapList = -1;
int spawneramt = 20;
int restrictmode = 0;
int clrocket[64];
int longjumpactive = false;
int slavezap = 10;
int playercapadj = 20;
int instswitch = 1;
bool allownoguide = true;
bool guiderocket[65];
bool restrictact = false;
bool friendlyfire = false;
bool seqenablecheck = true;
bool forcehdr = false;
bool mapchoosercheck = false;
bool syn56act = false;
bool vehiclemaphook = false;
bool playerteleports = false;
bool hasread = false;
bool DisplayedChapterTitle[65];
bool appliedlargeplayeradj = false;
bool bBlockEx = true;
bool bFixRebind = false;
bool TrainBlockFix = true;
bool GroundStuckFix = true;
bool BlockChoreoSuicide = true;
bool BlockTripMineDamage = true;

#define PLUGIN_VERSION "1.99982"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synfixesupdater.txt"

Menu g_hVoteMenu = null;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

public Plugin myinfo =
{
	name = "SynFixes",
	author = "Balimbanana",
	description = "Attempts to fix sequences by checking for missing actors, entities that have fallen out of the world, players not spawning with weapons, and vehicle pulling from side to side.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

float perclimit = 0.66;
float delaylimit = 66.0;
float votetime[65];
int clused = 0;
int voteact = 0;

public void OnPluginStart()
{
	LoadTranslations("basevotes.phrases");
	Handle dbgh = INVALID_HANDLE;
	Handle dbgallowh = INVALID_HANDLE;
	Handle dbgoh = INVALID_HANDLE;
	dbgh = CreateConVar("seqdbg", "0", "Set debug level of sequence checks.", _, true, 0.0, true, 3.0);
	dbgallowh = CreateConVar("seqenablecheck", "0", "Enables or disables sequence checking.", _, true, 0.0, true, 1.0);
	HookConVarChange(dbgh, dbghch);
	HookConVarChange(dbgallowh, dbgallowhch);
	debuglvl = GetConVarInt(dbgh);
	seqenablecheck = GetConVarBool(dbgallowh);
	CloseHandle(dbgh);
	CloseHandle(dbgallowh);
	CloseHandle(dbgoh);
	Handle votepercenth = CreateConVar("sm_votealyxpercent", "0.66", "People need to vote to at least this percent to pass.", _, true, 0.0, true, 1.0);
	perclimit = GetConVarFloat(votepercenth);
	HookConVarChange(votepercenth, restrictpercch);
	CloseHandle(votepercenth);
	Handle votedelayh = CreateConVar("sm_votealyxtime", "30", "Time to wait between votes.", _, true, 0.0, false);
	delaylimit = GetConVarFloat(votedelayh);
	HookConVarChange(votedelayh, restrictvotech);
	CloseHandle(votedelayh);
	Handle pushh = FindConVar("sv_player_push");
	if (pushh != INVALID_HANDLE) HookConVarChange(pushh, pushch);
	CloseHandle(pushh);
	Handle instphyswitch = CreateConVar("sm_instantswitch", "1", "Allow instant weapon switch for physcannon. 2 is for every weapon.", _, true, 0.0, true, 2.0);
	instswitch = GetConVarInt(instphyswitch);
	HookConVarChange(instphyswitch, instphych);
	CloseHandle(instphyswitch);
	Handle forcehdrh = CreateConVar("sm_forcehdr", "0", "Force clients to use HDR (fixes fullbright).", _, true, 0.0, true, 1.0);
	forcehdr = GetConVarBool(forcehdrh);
	HookConVarChange(forcehdrh, forcehdrch);
	CloseHandle(forcehdrh);
	Handle removertimerh = CreateConVar("sm_removedrops", "30", "Remove healthkits and ammo drops after this many seconds.", _, true, 1.0, true, 100.0);
	removertimer = GetConVarFloat(removertimerh);
	HookConVarChange(removertimerh, removertimerch);
	CloseHandle(removertimerh);
	Handle ffh = FindConVar("mp_friendlyfire");
	if (ffh != INVALID_HANDLE)
	{
		friendlyfire = GetConVarBool(ffh);
		HookConVarChange(ffh, ffhch);
	}
	CloseHandle(ffh);
	Handle resetspawnersh = CreateConVar("sm_forcespawners", "20", "Force npc_makers above this number to be reset to this number.", _, true, -1.0, true, 1000.0);
	spawneramt = GetConVarInt(resetspawnersh);
	HookConVarChange(resetspawnersh, spawneramtch);
	CloseHandle(resetspawnersh);
	Handle resetspawnermodesh = CreateConVar("sm_forcespawnersmode", "0", "Set mode of spawner restrictions. 1 is coop and js map prefix. 2 is always.", _, true, 0.0, true, 2.0);
	restrictact = GetConVarBool(resetspawnermodesh);
	HookConVarChange(resetspawnermodesh, spawneramtresch);
	CloseHandle(resetspawnermodesh);
	Handle noguidecv = CreateConVar("sm_allownoguide","1","Sets whether or not to allow setting no guide on rpg rockets.",_,true,0.0,true,1.0);
	allownoguide = GetConVarBool(noguidecv);
	HookConVarChange(noguidecv,noguidech);
	CloseHandle(noguidecv);
	Handle cvar = FindConVar("sm_playertriggerapply");
	if (cvar != INVALID_HANDLE)
	{
		playercapadj = GetConVarInt(cvar);
		HookConVarChange(cvar, plytrigch);
	}
	else
	{
		cvar = CreateConVar("sm_playertriggerapply", "20", "Set player trigger amount for map adjustments such as additional vehicle spawns. 0 disables.", _, true, 0.0, true, 128.0);
		playercapadj = GetConVarInt(cvar);
		HookConVarChange(cvar, plytrigch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_blockex");
	if (cvar != INVALID_HANDLE)
	{
		bBlockEx = GetConVarBool(cvar);
		HookConVarChange(cvar, blckexch);
	}
	else
	{
		cvar = CreateConVar("sm_blockex", "1", ".", _, true, 0.0, true, 1.0);
		bBlockEx = GetConVarBool(cvar);
		HookConVarChange(cvar, blckexch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("syn_fixrebind");
	if (cvar != INVALID_HANDLE)
	{
		bFixRebind = GetConVarBool(cvar);
		HookConVarChange(cvar, sfixrebindch);
	}
	else
	{
		cvar = CreateConVar("syn_fixrebind", "0", "Rebinds a few default keys automatically.", _, true, 0.0, true, 1.0);
		bFixRebind = GetConVarBool(cvar);
		HookConVarChange(cvar, sfixrebindch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_fixblockedtrains");
	if (cvar != INVALID_HANDLE)
	{
		TrainBlockFix = GetConVarBool(cvar);
		HookConVarChange(cvar, trainblckch);
	}
	else
	{
		cvar = CreateConVar("sm_fixblockedtrains", "1", "Removes items and weapons that are clipping with func_tracktrains, checks once every 10 seconds.", _, true, 0.0, true, 1.0);
		TrainBlockFix = GetConVarBool(cvar);
		HookConVarChange(cvar, trainblckch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_fixgroundstuck");
	if (cvar != INVALID_HANDLE)
	{
		GroundStuckFix = GetConVarBool(cvar);
		HookConVarChange(cvar, groundstuckch);
	}
	else
	{
		cvar = CreateConVar("sm_fixgroundstuck", "1", "Moves players on top of whatever they are stuck half-way in to.", _, true, 0.0, true, 1.0);
		GroundStuckFix = GetConVarBool(cvar);
		HookConVarChange(cvar, groundstuckch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_blockchoreokill");
	if (cvar != INVALID_HANDLE)
	{
		BlockChoreoSuicide = GetConVarBool(cvar);
		HookConVarChange(cvar, antikillch);
	}
	else
	{
		cvar = CreateConVar("sm_blockchoreokill", "1", "Prevent players from suiciding while in choreo vehicles.", _, true, 0.0, true, 1.0);
		BlockChoreoSuicide = GetConVarBool(cvar);
		HookConVarChange(cvar, antikillch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_blocktripmine_damage");
	if (cvar != INVALID_HANDLE)
	{
		BlockTripMineDamage = GetConVarBool(cvar);
		HookConVarChange(cvar, blocktripmindmgech);
	}
	else
	{
		cvar = CreateConVar("sm_blocktripmine_damage", "1", "Prevent players from breaking eachothers planted tripmines.", _, true, 0.0, true, 1.0);
		BlockTripMineDamage = GetConVarBool(cvar);
		HookConVarChange(cvar, blocktripmindmgech);
	}
	CloseHandle(cvar);
	CreateTimer(60.0,resetrot,_,TIMER_REPEAT);
	//if ((FileExists("addons/metamod/bin/server.so",false,NULL_STRING)) && (FileExists("addons/metamod/bin/metamod.2.sdk2013.so",false,NULL_STRING))) linact = true;
	//else linact = false;
	HookEventEx("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	HookEventEx("player_disconnect",Event_PlayerDisconnect,EventHookMode_Post);
	equiparr = CreateArray(32);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	entlist = CreateArray(1024);
	entnames = CreateArray(128);
	physboxarr = CreateArray(64);
	physboxharr = CreateArray(64);
	elevlist = CreateArray(64);
	inputsarrorigincls = CreateArray(768);
	ignoretrigs = CreateArray(1024);
	dctimeoutarr = CreateArray(MAXPLAYERS+1);
	if (addedinputs == INVALID_HANDLE) addedinputs = CreateArray(64);
	RegConsoleCmd("alyx",fixalyx);
	RegConsoleCmd("barney",fixbarney);
	RegConsoleCmd("stuck",stuckblck);
	RegConsoleCmd("propaccuracy",setpropaccuracy);
	RegConsoleCmd("con",enablecon);
	RegConsoleCmd("whois",admblock);
	RegConsoleCmd("npc_freeze",admblock);
	RegConsoleCmd("npc_freeze_unselected",admblock);
	RegConsoleCmd("mp_switchteams",admblock);
	RegConsoleCmd("lightprobe",admblock);
	RegConsoleCmd("buildcubemaps",admblock);
	RegConsoleCmd("sv_benchmark_force_start",admblock);
	RegConsoleCmd("mm_add_item",cmdblock);
	RegConsoleCmd("mm_add_player",cmdblock);
	RegConsoleCmd("mm_session_info",cmdblock);
	RegConsoleCmd("mm_message",cmdblock);
	RegConsoleCmd("mm_stats",cmdblock);
	RegConsoleCmd("mm_select_session",cmdblock);
	RegConsoleCmd("kill",suicideblock);
	RegConsoleCmd("explode",suicideblock);
	CreateTimer(10.0,dropshipchk,_,TIMER_REPEAT);
	CreateTimer(0.5,resetclanim,_,TIMER_REPEAT);
	AutoExecConfig(true, "synfixes");
	SFEntInputHook = CreateGlobalForward("SFHookEntityInput", ET_Ignore, Param_String, Param_Cell, Param_String, Param_String, Param_Float);
}

public void OnMapStart()
{
	if (GetMapHistorySize() > 0)
	{
		for (int i = 1;i<65;i++)
		{
			guiderocket[i] = true;
		}
		int rellogsv = CreateEntityByName("logic_auto");
		if ((rellogsv != -1) && (IsValidEntity(rellogsv)))
		{
			DispatchKeyValue(rellogsv,"targetname","syn_logicauto");
			DispatchKeyValue(rellogsv,"spawnflags","0");
			DispatchSpawn(rellogsv);
			ActivateEntity(rellogsv);
			HookEntityOutput("logic_auto","OnMapSpawn",onreload);
		}
		hasread = false;
		playerteleports = false;
		appliedlargeplayeradj = false;
		entrefresh = 0.0;
		ChapterTitle = "";
		ClearArray(entlist);
		ClearArray(equiparr);
		ClearArray(entnames);
		ClearArray(physboxarr);
		ClearArray(physboxharr);
		ClearArray(elevlist);
		ClearArray(inputsarrorigincls);
		ClearArray(ignoretrigs);
		char gamedescoriginal[24];
		GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
		if (StrEqual(gamedescoriginal,"synergy 56.16",false)) syn56act = true;
		else syn56act = false;
		GetCurrentMap(mapbuf,sizeof(mapbuf));
		if (restrictmode == 1)
		{
			if ((StrContains(mapbuf,"js_",false) != -1) || (StrContains(mapbuf,"coop_",false)))
				restrictact = true;
			else
				restrictact = false;
		}
		if ((StrEqual(mapbuf,"d1_canals_13",false)) && (syn56act))
		{
			int skycam = FindEntityByClassname(-1,"sky_camera");
			if (skycam != -1) AcceptEntityInput(skycam,"kill");
		}
		if (StrEqual(mapbuf,"d2_prison_08",false))
		{
			bool bSpawnedAlyx = false;
			int iFindAlyx = FindEntityByClassname(-1,"npc_alyx");
			if (IsValidEntity(iFindAlyx))
			{
				char szTargn[32];
				if (HasEntProp(iFindAlyx,Prop_Data,"m_iName")) GetEntPropString(iFindAlyx,Prop_Data,"m_iName",szTargn,sizeof(szTargn));
				if (!StrEqual(szTargn,"alyx",false))
				{
					while((iFindAlyx = FindEntityByClassname(iFindAlyx,"npc_template_maker")) != INVALID_ENT_REFERENCE)
					{
						if (IsValidEntity(iFindAlyx))
						{
							if (HasEntProp(iFindAlyx,Prop_Data,"m_iName"))
							{
								GetEntPropString(iFindAlyx,Prop_Data,"m_iName",szTargn,sizeof(szTargn));
								if (StrEqual(szTargn,"spawn_alyx",false))
								{
									AcceptEntityInput(iFindAlyx,"ForceSpawn");
									bSpawnedAlyx = true;
									break;
								}
							}
						}
					}
				}
				else bSpawnedAlyx = true;
			}
			else
			{
				char szTargn[32];
				while((iFindAlyx = FindEntityByClassname(iFindAlyx,"npc_template_maker")) != INVALID_ENT_REFERENCE)
				{
					if (IsValidEntity(iFindAlyx))
					{
						if (HasEntProp(iFindAlyx,Prop_Data,"m_iName"))
						{
							GetEntPropString(iFindAlyx,Prop_Data,"m_iName",szTargn,sizeof(szTargn));
							if (StrEqual(szTargn,"spawn_alyx",false))
							{
								AcceptEntityInput(iFindAlyx,"ForceSpawn");
								bSpawnedAlyx = true;
								break;
							}
						}
					}
				}
			}
			if (!bSpawnedAlyx)
			{
				PrintToServer("Failed to find or spawn Alyx using map entities. Falling back to static spawn.");
				iFindAlyx = CreateEntityByName("npc_alyx");
				if (IsValidEntity(iFindAlyx))
				{
					DispatchKeyValue(iFindAlyx,"targetname","alyx");
					DispatchKeyValue(iFindAlyx,"additionalequipment","weapon_alyxgun");
					DispatchKeyValue(iFindAlyx,"spawnflags","6148");
					DispatchKeyValue(iFindAlyx,"model","models/alyx.mdl");
					DispatchKeyValue(iFindAlyx,"hintlimiting","0");
					DispatchKeyValue(iFindAlyx,"physdamagescale","0");
					DispatchKeyValue(iFindAlyx,"OnDeath","text_alyx_died,ShowMessage,,0,-1");
					DispatchKeyValue(iFindAlyx,"OnDeath","loadsaved_alyx_died,Reload,,0,-1");
					float vecOrigin[3];
					float vecAngles[3];
					vecOrigin[0] = -2497.0;
					vecOrigin[1] = 2997.0;
					vecOrigin[2] = 961.881;
					vecAngles[1] = 326.0;
					TeleportEntity(iFindAlyx,vecOrigin,vecAngles,NULL_VECTOR);
					DispatchSpawn(iFindAlyx);
					ActivateEntity(iFindAlyx);
				}
			}
		}
		if ((StrContains(mapbuf,"d1_",false) == -1) && (StrContains(mapbuf,"d2_",false) == -1) && (!StrEqual(mapbuf,"d3_breen_01",false)) && (StrContains(mapbuf,"ep1_",false) == -1))
		{
			HookEntityOutput("scripted_sequence","OnBeginSequence",trigout);
			HookEntityOutput("scripted_scene","OnStart",trigout);
			HookEntityOutput("logic_choreographed_scene","OnStart",trigout);
			HookEntityOutput("instanced_scripted_scene","OnStart",trigout);
			if (StrContains(mapbuf,"bm_c",false) == -1)
				HookEntityOutput("func_tracktrain","OnStart",elevatorstart);
			HookEntityOutput("func_door","OnOpen",createelev);
			HookEntityOutput("func_door","OnClose",createelev);
		}
		if (StrEqual(mapbuf,"ep1_citadel_03",false))
		{
			HookEntityOutput("func_door","OnOpen",createelev);
			HookEntityOutput("func_door","OnClose",createelev);
		}
		HookEntityOutput("trigger_changelevel","OnChangeLevel",mapendchg);
		HookEntityOutput("npc_citizen","OnDeath",entdeath);
		HookEntityOutput("func_physbox","OnPhysGunPunt",physpunt);
		if (DirExists("maps/ent_cache",false))
		{
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
							if (debuglvl > 1) PrintToServer("Found ent cache %s",mapbuf);
							break;
						}
					}
				}
			}
			CloseHandle(mdirlisting);
		}
		
		FindSaveTPHooks();
		CreateTimer(0.1,rehooksaves,_,TIMER_FLAG_NO_MAPCHANGE);
		
		collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
		for (int i = 1;i<MaxClients+1;i++)
		{
			DisplayedChapterTitle[i] = false;
			if (IsClientConnected(i) && !IsFakeClient(i))
			{
				CreateTimer(1.0,clspawnpost,i,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		findentlist(MaxClients+1,"npc_template_maker");
		findentlist(MaxClients+1,"npc_*");
		int jstat = FindEntityByClassname(MaxClients+1,"prop_vehicle_jeep");
		int jspawn = FindEntityByClassname(MaxClients+1,"info_vehicle_spawn");
		int jstatmp = FindEntityByClassname(MaxClients+1,"prop_vehicle_mp");
		if ((jstat != -1) || (jspawn != -1) || (jstatmp != -1))
		{
			Handle cvarchk = FindConVar("sv_player_push");
			if (cvarchk != INVALID_HANDLE)
			{
				if (GetConVarInt(cvarchk) == 1)
				{
					if (debuglvl == 3) PrintToServer("Vehicle map was detected, for best experience, sv_player_push will be set to 0");
					int cvarflag = GetCommandFlags("sv_player_push");
					SetCommandFlags("sv_player_push", (cvarflag & ~FCVAR_REPLICATED));
					SetCommandFlags("sv_player_push", (cvarflag & ~FCVAR_NOTIFY));
					SetConVarInt(cvarchk,0,false,false);
				}
			}
			CloseHandle(cvarchk);
			vehiclemaphook = true;
		}
		for (int j; j<GetArraySize(entlist); j++)
		{
			int jtmp = GetArrayCell(entlist, j);
			if (IsValidEntity(jtmp))
			{
				char clsname[16];
				GetEntityClassname(jtmp,clsname,sizeof(clsname));
				if ((StrEqual(clsname,"npc_citizen",false)) && (!(StrContains(mapbuf,"cd",false) == 0))) SDKHook(jtmp, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		CreateTimer(0.1,RecheckChangeLevels,_,TIMER_FLAG_NO_MAPCHANGE);
		PrecacheSound("npc\\roller\\code2.wav",true);
	}
}

public Action RecheckChangeLevels(Handle timer)
{
	Handle arr = CreateArray(32);
	FindAllByClassname(arr,-1,"trigger_changelevel");
	if (GetArraySize(arr) > 0)
	{
		for (int i = 0;i<GetArraySize(arr);i++)
		{
			int entity = GetArrayCell(arr,i);
			if (IsValidEntity(entity))
			{
				if (HasEntProp(entity,Prop_Data,"m_szMapName"))
				{
					char mapchk[64];
					GetEntPropString(entity,Prop_Data,"m_szMapName",mapchk,sizeof(mapchk));
					char curmap[64];
					GetCurrentMap(curmap,sizeof(curmap));
					if (StrEqual(mapchk,curmap,false))
					{
						if (debuglvl) PrintToServer("Warning: trigger_changelevel created with same map name as current map. Removing...");
						AcceptEntityInput(entity,"kill");
					}
				}
			}
		}
	}
	CloseHandle(arr);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if ((StrEqual(sArgs,"stuck",false)) || (StrEqual(sArgs,"unstuck",false)) || (StrEqual(sArgs,"!stuck",false)) || (StrEqual(sArgs,"!unstuck",false)))
	{
		ClientCommand(client,"stuck");
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	if (StrEqual(name,"mapchooser",false))
	{
		mapchoosercheck = true;
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("SynFixes");
	CreateNative("GetCustomEntList", Native_GetCustomEntList);
	CreateNative("SynFixesReadCache", Native_ReadCache);
	CreateNative("SFAddHookEntityInput", Native_AddToInputHooks);
	MarkNativeAsOptional("GetCustomEntList");
	MarkNativeAsOptional("SynFixesReadCache");
	MarkNativeAsOptional("SFAddHookEntityInput");
	SynFixesRunning = true;
	return APLRes_Success;
}

public void OnPluginEnd()
{
	if (SynFixesRunning) SynFixesRunning = false;
}

public Action fixalyx(int client, int args)
{
	char tmpmap[24];
	GetCurrentMap(tmpmap,sizeof(tmpmap));
	if ((StrEqual(tmpmap,"ep2_outland_12",false)) || (StrEqual(tmpmap,"ep2_outland_11b",false)) || (StrEqual(tmpmap,"ep2_outland_08",false)) || (StrEqual(tmpmap,"ep2_outland_02",false)) || (StrEqual(tmpmap,"d3_breen_01",false)) || (StrEqual(tmpmap,"d1_town_05",false))) return Plugin_Handled;
	if (!StrEqual(tmpmap,"ep2_outland_12a",false)) findgfollow(-1,"alyx");
	if (!findtargn("alyx"))
		readoutputs(client,"alyx");
	else
	{
		Menu menu = new Menu(MenuHandler);
		menu.SetTitle("Teleport Alyx");
		menu.AddItem("tptocl", "Vote to teleport Alyx to you");
		menu.ExitButton = true;
		menu.Display(client, 120);
	}
	return Plugin_Handled;
}

public Action fixbarney(int client, int args)
{
	char tmpmap[24];
	GetCurrentMap(tmpmap,sizeof(tmpmap));
	if (StrEqual(tmpmap,"ep1_c17_06",false)) return Plugin_Handled;
	findgfollow(-1,"barney");
	if (!findtargn("barney"))
		readoutputs(client,"barney");
	else
	{
		Menu menu = new Menu(MenuHandler);
		menu.SetTitle("Teleport Barney");
		menu.AddItem("tpbarntocl", "Vote to teleport Barney to you");
		menu.ExitButton = true;
		menu.Display(client, 120);
	}
	return Plugin_Handled;
}

public Action stuckblck(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	if ((client == 0) || (!IsClientInGame(client)) || (!IsPlayerAlive(client))) return Plugin_Handled;
	int vckent = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	char vckcls[32];
	if (vckent != -1) GetEntityClassname(vckent,vckcls,sizeof(vckcls));
	float CurVec = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	if (RoundFloat(CurVec) < -800)
	{
		PrintToChat(client,"> Can't use while falling too fast.");
		return Plugin_Handled;
	}
	else if ((StrContains(vckcls,"choreo",false) != -1) || (StrContains(vckcls,"prisoner_pod",false) != -1))
	{
		PrintToChat(client,"> Can't use while in a choreo vehicle.");
		return Plugin_Handled;
	}
	else if (GetEntityRenderFx(client) == RENDERFX_DISTORT)
	{
		PrintToChat(client,"> Can't use after reaching end of level.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action setpropaccuracy(int client, int args)
{
	if (args == 1)
	{
		char h[8];
		GetCmdArg(1,h,sizeof(h));
		if (StrEqual(h,"1",false) || StrEqual(h,"yes",false))
			QueryClientConVar(client,"cl_predict",setpropacc,1);
		else if (StrEqual(h,"0",false) || StrEqual(h,"no",false))
			QueryClientConVar(client,"cl_predict",setpropacc,2);
	}
	else
		QueryClientConVar(client,"cl_predict",setpropacc,0);
	return Plugin_Handled;
}

public Action enablecon(int client, int args)
{
	ClientCommand(client,"con_enable 1");
	ClientCommand(client,"toggleconsole");
	return Plugin_Handled;
}

public void setpropacc(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	int cllatency = RoundFloat(GetClientLatency(client,NetFlow_Outgoing) * 1000) - 30;
	if ((cllatency > 100) && ((value == 0) || (value == 2))) PrintToChat(client,"Warning, your latency may affect how smooth movement is with this on.");
	if (value == 0)
	{
		if (StrEqual(cvarValue,"0",false))
		{
			ClientCommand(client,"cl_interp 0.1");
			ClientCommand(client,"cl_predict 1");
			ClientCommand(client,"cl_interp_ratio 2");
			PrintToChat(client,"Set prop accuracy to default.");
		}
		else
		{
			ClientCommand(client,"cl_interp 0");
			ClientCommand(client,"cl_predict 0");
			ClientCommand(client,"cl_interp_ratio 0");
			PrintToChat(client,"Set prop accuracy to accurate.");
		}
	}
	else if (value == 1)
	{
		ClientCommand(client,"cl_interp 0");
		ClientCommand(client,"cl_predict 0");
		ClientCommand(client,"cl_interp_ratio 0");
		PrintToChat(client,"Set prop accuracy to accurate.");
	}
	else if (value == 2)
	{
		ClientCommand(client,"cl_interp 0.1");
		ClientCommand(client,"cl_predict 1");
		ClientCommand(client,"cl_interp_ratio 2");
		PrintToChat(client,"Set prop accuracy to default.");
	}
}

public Action admblock(int client, int args)
{
	if (GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action cmdblock(int client, int args)
{
	return Plugin_Handled;
}

public Action suicideblock(int client, int args)
{
	if (BlockChoreoSuicide)
	{
		if (IsValidEntity(client))
		{
			if (HasEntProp(client,Prop_Send,"m_hVehicle"))
			{
				int vck = GetEntProp(client, Prop_Send, "m_hVehicle");
				if (IsValidEntity(vck))
				{
					char vckcls[64];
					GetEntityClassname(vck,vckcls,sizeof(vckcls));
					if ((StrContains(vckcls,"choreo",false) != -1) || (StrContains(vckcls,"prisoner_pod",false) != -1))
					{
						PrintToChat(client,"> Can't use while in a choreo vehicle.");
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		float Time = GetTickedTime();
		if (votetime[param1] > Time)
		{
			PrintToChat(param1,"You must wait %1.f seconds before you can vote again.",votetime[param1]-Time);
			return 0;
		}
		if (mapchoosercheck)
		{
			if (!CanMapChooserStartVote())
			{
				PrintToChat(param1,"There is a vote already in progress.");
				return 0;
			}
		}
		if (IsVoteInProgress())
		{
			PrintToChat(param1,"There is a vote already in progress.");
			return 0;
		}
		char info[128];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info,"tptocl",false))
		{
			clused = param1;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			char buff[64];
			Format(buff,sizeof(buff),"Teleport Alyx to %N?",param1);
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime[param1] = Time + delaylimit;
			voteact = 1;
		}
		if (StrEqual(info,"tpbarntocl",false))
		{
			clused = param1;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MENU_ACTIONS_ALL);
			char buff[64];
			Format(buff,sizeof(buff),"Teleport Barney to %N?",param1);
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime[param1] = Time + delaylimit;
			voteact = 0;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		return 0;
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
		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes;
		}
		percent = float(votes)/float(totalVotes);
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,perclimit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t","Vote Failed", RoundToNearest(100.0*perclimit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("%t","Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			float PlayerOrigin[3];
			float Location[3];
			float clangles[3];
			if (!IsClientInGame(clused) || !IsPlayerAlive(clused))
			{
				return 0;
			}
			GetClientEyeAngles(clused, clangles);
			clangles[0] = 0.0;
			clangles[2] = 0.0;
			GetClientAbsOrigin(clused, Location);
			PlayerOrigin[0] = (Location[0] + (60 * Cosine(DegToRad(clangles[1]))));
			PlayerOrigin[1] = (Location[1] + (60 * Sine(DegToRad(clangles[1]))));
			PlayerOrigin[2] = (Location[2] + 10);
			Location[0] = (PlayerOrigin[0] + (10 * Cosine(DegToRad(clangles[1]))));
			Location[1] = (PlayerOrigin[1] + (10 * Sine(DegToRad(clangles[1]))));
			Location[2] = PlayerOrigin[2];
			if (voteact == 1)
			{
				int al = FindEntityByClassname(MaxClients+1,"npc_alyx");
				if (al != -1)
					TeleportEntity(al,Location,clangles,NULL_VECTOR);
				voteact = 0;
			}
			else
			{
				int ba = FindEntityByClassname(MaxClients+1,"npc_barney");
				if (ba != -1)
					TeleportEntity(ba,Location,clangles,NULL_VECTOR);
				voteact = 0;
			}
		}
	}
	return 0;
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		CreateTimer(0.5,clspawnpost,client);
		if (forcehdr) QueryClientConVar(client,"mat_hdr_level",hdrchk,0);
		if ((GetClientCount(true) >= playercapadj) && (!appliedlargeplayeradj) && (playercapadj > 0))
		{
			appliedlargeplayeradj = true;
			Handle spawns = CreateArray(32);
			FindAllByClassname(spawns,-1,"info_vehicle_spawn");
			if (GetArraySize(spawns) > 0)
			{
				for (int i = 0;i<GetArraySize(spawns);i++)
				{
					int ent = GetArrayCell(spawns,i);
					if (IsValidEntity(ent))
					{
						float origin[3];
						float angs[3];
						float loc[3];
						if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
						if (HasEntProp(ent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(ent,Prop_Data,"m_vecAbsOrigin",origin);
						else if (HasEntProp(ent,Prop_Send,"m_vecOrigin")) GetEntPropVector(ent,Prop_Send,"m_vecOrigin",origin);
						//horizontal right check
						angs[1]-=90.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						loc[2] = origin[2];
						if (CheckBounds(loc,angs))
						{
							//get original just in case
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//horizontal left check
						angs[1]+=180.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						if (CheckBounds(loc,angs))
						{
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//forward check
						angs[1]-=90.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						if (CheckBounds(loc,angs))
						{
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//backwards check
						angs[1]-=180.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						if (CheckBounds(loc,angs))
						{
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						
						//run all over again with +50 z
						origin[2]+=50.0;
						if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
						//horizontal right check
						angs[1]-=90.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						loc[2] = origin[2];
						if (CheckBounds(loc,angs))
						{
							//get original just in case
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//horizontal left check
						angs[1]+=180.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						if (CheckBounds(loc,angs))
						{
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//forward check
						angs[1]-=90.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						if (CheckBounds(loc,angs))
						{
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//backwards check
						angs[1]-=180.0;
						loc[0] = (origin[0] + (200 * Cosine(DegToRad(angs[1]))));
						loc[1] = (origin[1] + (200 * Sine(DegToRad(angs[1]))));
						if (CheckBounds(loc,angs))
						{
							if (HasEntProp(ent,Prop_Data,"m_angRotation")) GetEntPropVector(ent,Prop_Data,"m_angRotation",angs);
							SetupVehicleSpawn(ent,loc,angs);
							continue;
						}
						//asfasf
					}
				}
			}
			CloseHandle(spawns);
		}
		char SteamID[64];
		GetClientAuthId(client,AuthId_Steam3,SteamID,sizeof(SteamID));
		int findid = FindStringInArray(dctimeoutarr,SteamID);
		if ((findid == -1) && (syn56act)) ClientCommand(client,"r_flushlod");
		else if (findid != -1) RemoveFromArray(dctimeoutarr,findid);
	}
}

bool CheckBounds(float loc[3], float angs[3])
{
	if (!TR_PointOutsideWorld(loc))
	{
		float trpos[3];
		int posworks = 0;
		TR_TraceRay(loc,angs,MASK_PLAYERSOLID,RayType_Infinite);
		TR_GetEndPosition(trpos);
		if (GetVectorDistance(loc,trpos,false) > 100.0) posworks++;
		//left
		angs[1]+=180.0;
		TR_TraceRay(loc,angs,MASK_PLAYERSOLID,RayType_Infinite);
		TR_GetEndPosition(trpos);
		if (GetVectorDistance(loc,trpos,false) > 100.0) posworks++;
		//forwards
		angs[1]-=90.0;
		TR_TraceRay(loc,angs,MASK_PLAYERSOLID,RayType_Infinite);
		TR_GetEndPosition(trpos);
		if (GetVectorDistance(loc,trpos,false) > 100.0) posworks++;
		//back
		angs[1]+=180.0;
		TR_TraceRay(loc,angs,MASK_PLAYERSOLID,RayType_Infinite);
		TR_GetEndPosition(trpos);
		if (GetVectorDistance(loc,trpos,false) > 100.0) posworks++;
		angs[1]-=180.0;
		//up
		angs[0]-=90.0;
		TR_TraceRay(loc,angs,MASK_PLAYERSOLID,RayType_Infinite);
		TR_GetEndPosition(trpos);
		if (GetVectorDistance(loc,trpos,false) > 80.0) posworks++;
		angs[0]+=90.0;
		if (posworks >= 5)
		{
			return true;
		}
		return false;
	}
	return false;
}

void SetupVehicleSpawn(int ent, float loc[3], float angs[3])
{
	char targn[128];
	if (HasEntProp(ent,Prop_Data,"m_iName")) GetEntPropString(ent,Prop_Data,"m_iName",targn,sizeof(targn));
	char vehscript[128];
	if (HasEntProp(ent,Prop_Data,"m_iVehicleScript")) GetEntPropString(ent,Prop_Data,"m_iVehicleScript",vehscript,sizeof(vehscript));
	char vehmdl[128];
	if (HasEntProp(ent,Prop_Data,"m_ModelName")) GetEntPropString(ent,Prop_Data,"m_ModelName",vehmdl,sizeof(vehmdl));
	char vehicletype[8];
	Format(vehicletype,sizeof(vehicletype),"1");
	if (HasEntProp(ent,Prop_Data,"m_iVehicleType"))
	{
		int vehtype = GetEntProp(ent,Prop_Data,"m_iVehicleType");
		Format(vehicletype,sizeof(vehicletype),"%i",vehtype);
	}
	bool enablegun = false;
	bool enabled = false;
	if (HasEntProp(ent,Prop_Data,"m_bEnableGun"))
	{
		if (GetEntProp(ent,Prop_Data,"m_bEnableGun")) enablegun = true;
	}
	if (HasEntProp(ent,Prop_Data,"m_bEnabled"))
	{
		if (GetEntProp(ent,Prop_Data,"m_bEnabled")) enabled = true;
	}
	if (strlen(vehmdl) > 1)
	{
		int nextspawn = CreateEntityByName("info_vehicle_spawn");
		if (nextspawn != -1)
		{
			DispatchKeyValue(nextspawn,"vehiclescript",vehscript);
			DispatchKeyValue(nextspawn,"targetname",targn);
			DispatchKeyValue(nextspawn,"skin","0");
			DispatchKeyValue(nextspawn,"solid","6");
			DispatchKeyValue(nextspawn,"model",vehmdl);
			DispatchKeyValue(nextspawn,"VehicleType",vehicletype);
			DispatchKeyValue(nextspawn,"VehicleSize","192");
			if (enabled) DispatchKeyValue(nextspawn,"StartEnabled","1");
			if (enablegun) DispatchKeyValue(nextspawn,"StartGunEnabled","1");
			TeleportEntity(nextspawn,loc,angs,NULL_VECTOR);
			DispatchSpawn(nextspawn);
			ActivateEntity(nextspawn);
		}
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	CreateTimer(0.1,everyspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action everyspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		if (longjumpactive)
		{
			int hudhint = CreateEntityByName("env_hudhint");
			if (hudhint != -1)
			{
				char msg[64];
				Format(msg,sizeof(msg),"Ctrl + Jump LONG JUMP");
				DispatchKeyValue(hudhint,"spawnflags","0");
				DispatchKeyValue(hudhint,"message",msg);
				DispatchSpawn(hudhint);
				ActivateEntity(hudhint);
				AcceptEntityInput(hudhint,"ShowHudHint",client);
				Handle dp = CreateDataPack();
				WritePackCell(dp,hudhint);
				WritePackString(dp,"env_hudhint");
				CreateTimer(0.5,cleanup,dp);
			}
		}
		if (GetArraySize(equiparr) > 0)
		{
			float clorigin[3];
			GetClientAbsOrigin(client,clorigin);
			clorigin[2]+=10.0;
			for (int j; j<GetArraySize(equiparr); j++)
			{
				int jtmp = GetArrayCell(equiparr, j);
				if (IsValidEntity(jtmp))
				{
					if (HasEntProp(jtmp,Prop_Data,"m_iszResponseContext"))
					{
						char additionalweaps[256];
						GetEntPropString(jtmp,Prop_Data,"m_iszResponseContext",additionalweaps,sizeof(additionalweaps));
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
										for (int l; l<104; l += 4)
										{
											int tmpi = GetEntDataEnt2(client,WeapList + l);
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
										else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
										else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
										else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
										else if (StrEqual(basecls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
										else if (StrEqual(basecls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
										int ent = CreateEntityByName(basecls);
										if (ent != -1)
										{
											TeleportEntity(ent,clorigin,NULL_VECTOR,NULL_VECTOR);
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
			}
		}
		else
		{
			findent(MaxClients+1,"info_player_equip");
		}
		if ((strlen(ChapterTitle) > 0) && (!DisplayedChapterTitle[client])) CreateTimer(5.0,DisplayChapterTitle,client,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (IsClientConnected(client)) CreateTimer(0.1,everyspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
}

public Action DisplayChapterTitle(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		DisplayedChapterTitle[client] = true;
		//SetHudTextParams(-1.0, 0.6, 1.0, 200, 200, 200, 255, 1, 1.0, 1.0, 1.0);
		//ShowHudText(client,3,"%s",ChapterTitle);
		int gametext = CreateEntityByName("game_text");
		if (gametext != -1)
		{
			DispatchKeyValue(gametext,"x","-1");
			DispatchKeyValue(gametext,"y","0.58");
			DispatchKeyValue(gametext,"message",ChapterTitle);
			DispatchKeyValue(gametext,"channel","1");
			DispatchKeyValue(gametext,"color","150 150 150");
			DispatchKeyValue(gametext,"fadein","0.1");
			DispatchKeyValue(gametext,"fadeout","1.0");
			DispatchKeyValue(gametext,"holdtime","1.5");
			DispatchKeyValue(gametext,"effect","2");
			DispatchSpawn(gametext);
			ActivateEntity(gametext);
			AcceptEntityInput(gametext,"Display",client);
			Handle dp = CreateDataPack();
			WritePackCell(dp,gametext);
			WritePackString(dp,"game_text");
			CreateTimer(1.0,cleanup,dp);
		}
	}
}

public Action clspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		float clorigin[3], vMins[3], vMaxs[3];
		GetClientAbsOrigin(client,clorigin);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
		if (GetArraySize(equiparr) < 1)
			findent(MaxClients+1,"info_player_equip");
		Handle weaparr = CreateArray(16);
		if (WeapList != -1)
		{
			for (int j; j<48; j += 4)
			{
				int tmp = GetEntDataEnt2(client,WeapList + j);
				if (tmp != -1)
				{
					char name[24];
					GetEntityClassname(tmp,name,sizeof(name));
					PushArrayString(weaparr,name);
				}
			}
		}
		int vck = -1;
		if (HasEntProp(client,Prop_Send,"m_hVehicle"))
			vck = GetEntProp(client, Prop_Send, "m_hVehicle");
		if ((vck == -1) && ((FindStringInArray(weaparr,"weapon_physcannon") == -1) || (GetEntProp(client,Prop_Send,"m_bWearingSuit") > 0)))
		{
			for (int j; j<GetArraySize(equiparr); j++)
			{
				int jtmp = GetArrayCell(equiparr, j);
				if (IsValidEntity(jtmp))
					AcceptEntityInput(jtmp,"EquipPlayer",client);
			}
		}
		CloseHandle(weaparr);
		ClearArray(equiparr);
		if (HasEntProp(client,Prop_Data,"m_bPlayerUnderwater"))
		{
			SetEntProp(client,Prop_Data,"m_bPlayerUnderwater",1);
			SetEntProp(client,Prop_Data,"m_bPlayerUnderwater",0);
		}
		int ViewEnt = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
		if (ViewEnt > MaxClients)
		{
			char cls[25];
			GetEntityClassname(ViewEnt, cls, sizeof(cls));
			if (!StrEqual(cls, "point_viewcontrol", false))
			{
				float PlayerOrigin[3];
				float PlyAng[3];
				GetClientAbsOrigin(client, PlayerOrigin);
				GetClientEyeAngles(client, PlyAng);
				int cam = CreateEntityByName("point_viewcontrol");
				TeleportEntity(cam, PlayerOrigin, PlyAng, NULL_VECTOR);
				DispatchKeyValue(cam, "spawnflags","1");
				DispatchSpawn(cam);
				ActivateEntity(cam);
				AcceptEntityInput(cam,"Enable",client);
				AcceptEntityInput(cam,"Disable",client);
				AcceptEntityInput(cam,"Kill");
			}
		}
		else
		{
			float PlayerOrigin[3];
			float PlyAng[3];
			GetClientAbsOrigin(client, PlayerOrigin);
			GetClientEyeAngles(client, PlyAng);
			int cam = CreateEntityByName("point_viewcontrol");
			TeleportEntity(cam, PlayerOrigin, PlyAng, NULL_VECTOR);
			DispatchKeyValue(cam, "spawnflags","1");
			DispatchSpawn(cam);
			ActivateEntity(cam);
			AcceptEntityInput(cam,"Enable",client);
			AcceptEntityInput(cam,"Disable",client);
			AcceptEntityInput(cam,"Kill");
		}
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponUse);
		if (bFixRebind)
		{
			ClientCommand(client,"bind f1 vote_yes");
			ClientCommand(client,"bind f2 vote_no");
		}
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(0.5,clspawnpost,client);
	}
}

public void hdrchk(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if ((StrEqual(cvarValue,"0",false)) || (StrEqual(cvarValue,"1",false)))
		ClientCommand(client,"mat_hdr_level 2");
}

public void dbghch(Handle convar, const char[] oldValue, const char[] newValue)
{
	debuglvl = StringToInt(newValue);
}

public void dbgallowhch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) seqenablecheck = true;
	else seqenablecheck = false;
}

public Action resetrot(Handle timer)
{
	float vMins[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
	for (int i = 1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (StrContains(clsname,"func_rotating",false) != -1)
			{
				float angs[3];
				GetEntPropVector(i,Prop_Data,"m_angRotation",angs);
				if (((angs[0] > 400.0) || (angs[1] > 400.0) || (angs[2] > 400.0)) || ((angs[0] < -400.0) || (angs[1] < -400.0) || (angs[2] < -400.0)))
				{
					AcceptEntityInput(i,"StopAtStartPos");
					AcceptEntityInput(i,"Start");
				}
			}
		}
	}
}

public Action elevatorstart(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(0.1,elevatorstartpost,caller,TIMER_FLAG_NO_MAPCHANGE);
	//Post check
	CreateTimer(5.0,elevatorstartpost,caller,TIMER_FLAG_NO_MAPCHANGE);
}

public Action elevatorstartpost(Handle timer, int elev)
{
	if (IsValidEntity(elev))
	{
		float origin[3];
		GetEntPropVector(elev,Prop_Data,"m_vecAbsOrigin",origin);
		for (int i = MaxClients+1; i<GetMaxEntities(); i++)
		{
			if (IsValidEntity(i) && IsEntNetworkable(i))
			{
				char clsname[32];
				GetEntityClassname(i,clsname,sizeof(clsname));
				if ((StrEqual(clsname,"prop_physics",false)) || (StrEqual(clsname,"prop_ragdoll",false)) || (StrContains(clsname,"item_",false) != -1))
				{
					float proporigin[3];
					GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",proporigin);
					int parentchk = 0;
					if (HasEntProp(i,Prop_Data,"m_hParent"))
						parentchk = GetEntPropEnt(i,Prop_Data,"m_hParent");
					if (parentchk < 1)
					{
						float chkdist = GetVectorDistance(origin,proporigin,false);
						bool below = true;
						if ((origin[2] < 0) && (origin[2] > proporigin[2])) below = false;
						else if ((origin[2] > -1) && (origin[2] < proporigin[2])) below = false;
						if (StrEqual(clsname,"prop_ragdoll",false)) below = false;
						if ((chkdist < 200.0) && (!below))
						{
							if (debuglvl > 0)
							{
								char targn[32];
								GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
								PrintToServer("Removed %i %s %s colliding with elevator",i,targn,clsname);
							}
							AcceptEntityInput(i,"kill");
						}
					}
				}
			}
		}
	}
}

public Action mapendchg(const char[] output, int caller, int activator, float delay)
{
	if ((IsValidEntity(caller)) && (IsEntNetworkable(caller)))
	{
		char clschk[32];
		GetEntityClassname(caller,clschk,sizeof(clschk));
		if (StrEqual(clschk,"trigger_changelevel",false))
		{
			char maptochange[64];
			char curmapbuf[64];
			GetCurrentMap(curmapbuf,sizeof(curmapbuf));
			GetEntPropString(caller,Prop_Data,"m_szMapName",maptochange,sizeof(maptochange));
			Handle data;
			data = CreateDataPack();
			WritePackString(data, maptochange);
			WritePackString(data, curmapbuf);
			CreateTimer(1.0,changeleveldelay,data);
		}
	}
}

public Action changeleveldelay(Handle timer, Handle data)
{
	if (data != INVALID_HANDLE)
	{
		char maptochange[64];
		char curmapbuf[64];
		ResetPack(data);
		ReadPackString(data,maptochange,sizeof(maptochange));
		ReadPackString(data,curmapbuf,sizeof(curmapbuf));
		CloseHandle(data);
		char mapchk[64];
		GetCurrentMap(mapchk,sizeof(mapchk));
		if (StrEqual(mapchk,curmapbuf,false))
		{
			if (debuglvl > 1) PrintToServer("Failed to change map to %s attempting to change manually.",maptochange);
			ServerCommand("changelevel %s",maptochange);
			ServerCommand("changelevel ep1 %s",maptochange);
			ServerCommand("changelevel ep2 %s",maptochange);
			ServerCommand("changelevel Custom %s",maptochange);
			ServerCommand("changelevel syn %s",maptochange);
		}
	}
}

public Action entdeath(const char[] output, int caller, int activator, float delay)
{
	if (HasEntProp(caller,Prop_Data,"m_iName"))
	{
		char entname[32];
		GetEntPropString(caller,Prop_Data,"m_iName",entname,sizeof(entname));
		if (FindStringInArray(entnames,entname) == -1) PushArrayString(entnames,entname);
	}
}

public Action physpunt(const char[] output, int caller, int activator, float delay)
{
	if (friendlyfire) return Plugin_Continue;
	if (HasEntProp(caller,Prop_Data,"m_hParent"))
	{
		int parentent = GetEntPropEnt(caller,Prop_Data,"m_hParent");
		if (parentent > 0) return Plugin_Continue;
	}
	int arrindx = FindValueInArray(physboxarr,caller);
	if (arrindx == -1)
	{
		PushArrayCell(physboxarr,caller);
		Handle tmptime = CreateTimer(5.0,RemoveFromArr,caller);
		PushArrayCell(physboxharr,tmptime);
	}
	else
	{
		Handle tmptime = GetArrayCell(physboxharr,arrindx);
		if (tmptime != INVALID_HANDLE)
		{
			RemoveFromArray(physboxarr,arrindx);
			RemoveFromArray(physboxharr,arrindx);
			KillTimer(tmptime);
			Handle tmptimepost = CreateTimer(5.0,RemoveFromArr,caller);
			PushArrayCell(physboxarr,caller);
			PushArrayCell(physboxharr,tmptimepost);
		}
	}
	return Plugin_Continue;
}

public Action RemoveFromArr(Handle timer, int physbox)
{
	int arrindx = FindValueInArray(physboxarr,physbox);
	if (arrindx != -1)
	{
		RemoveFromArray(physboxarr,arrindx);
		RemoveFromArray(physboxharr,arrindx);
	}
}

public Action resetclanim(Handle timer)
{
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsValidEntity(i)) && (i != 0))
		{
			if (IsClientConnected(i))
			{
				if (IsClientInGame(i))
				{
					if (IsPlayerAlive(i))
					{
						if (HasEntProp(i,Prop_Data,"m_bClientSideAnimation"))
						{
							SetEntProp(i,Prop_Data,"m_bClientSideAnimation",0);
							SetEntProp(i,Prop_Data,"m_bClientSideAnimation",1);
						}
						if (GroundStuckFix)
						{
							if (HasEntProp(i,Prop_Data,"m_hVehicle"))
							{
								if (GetEntPropEnt(i,Prop_Data,"m_hVehicle") != -1) continue;
							}
							if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin"))
							{
								float vEyePos[3], vFeetPos[3], vTRPos[3], vAngs[3];
								GetClientEyePosition(i,vEyePos);
								GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",vFeetPos);
								vAngs[0]+=90.0;
								TR_TraceRayFilter(vEyePos,vAngs,MASK_SHOT,RayType_Infinite,TraceEntityFilterPly,i);
								TR_GetEndPosition(vTRPos);
								int hitent = TR_GetEntityIndex();
								if ((hitent > 0) && (IsValidEntity(hitent)))
								{
									char cls[32];
									GetEntityClassname(hitent,cls,sizeof(cls));
									if (StrContains(cls,"func_",false) == -1) continue;
								}
								if ((vFeetPos[2] < vTRPos[2]) && (GetVectorDistance(vFeetPos,vTRPos,false) > 10.0))
								{
									vTRPos[2]+=65.0;
									if (TR_PointOutsideWorld(vTRPos)) continue;
									vTRPos[2]-=65.0;
									vFeetPos[2] = vTRPos[2];
									TeleportEntity(i,vFeetPos,NULL_VECTOR,NULL_VECTOR);
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action dropshipchk(Handle timer)
{
	for (int i = MaxClients+1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (StrEqual(clsname,"npc_combinedropship",false))
			{
				int lastdropped = 0;
				int curdrop = GetEntProp(i,Prop_Data,"m_iCurrentTroopExiting");
				char m_sNPCTemplatechar[64];
				for (int j = 0;j<6;j++)
				{
					char tmp[4];
					Format(m_sNPCTemplatechar,sizeof(m_sNPCTemplatechar),"m_sNPCTemplate[%i]",j);
					GetEntPropString(i,Prop_Data,m_sNPCTemplatechar,tmp,sizeof(tmp));
					if (strlen(tmp) > 0)
						lastdropped = j+1;
				}
				if (curdrop == lastdropped)
				{
					CreateTimer(10.0,rmcolliding,i);
				}
			}
			if ((HasEntProp(i,Prop_Data,"m_iGlobalname")) && (StrContains(clsname,"prop_",false) != -1) && (syn56act))
			{
				char glname[32];
				GetEntPropString(i,Prop_Data,"m_iGlobalname",glname,sizeof(glname));
				if (strlen(glname) > 1)
				{
					if (debuglvl > 2) PrintToServer("Ent %i %s had globalname %s reloads will remove this on 56.16",i,clsname,glname);
					SetEntPropString(i,Prop_Data,"m_iGlobalname","");
					char localname[32];
					GetEntPropString(i,Prop_Data,"m_iName",localname,sizeof(localname));
					if (strlen(localname) < 1) SetEntPropString(i,Prop_Data,"m_iName",glname);
				}
			}
			if (StrEqual(clsname,"env_rockettrail",false))
			{
				int parentent = GetEntPropEnt(i,Prop_Data,"m_hParent");
				if (parentent == -1)
				{
					AcceptEntityInput(i,"kill");
				}
			}
			if ((TrainBlockFix) && (StrEqual(clsname,"func_tracktrain",false)))
			{
				float mins[3];
				float maxs[3];
				GetEntPropVector(i,Prop_Data,"m_vecSurroundingMins",mins);
				GetEntPropVector(i,Prop_Data,"m_vecSurroundingMaxs",maxs);
				findtouchingents(mins,maxs,i);
			}
		}
	}
}

public Action rmcolliding(Handle timer, int caller)
{
	//int landtarg = GetEntProp(i,Prop_Data,"m_bHasDroppedOff");
	if ((caller == -1) || (!IsValidEntity(caller))) return Plugin_Handled;
	char clschk[24];
	GetEntityClassname(caller,clschk,sizeof(clschk));
	if (!StrEqual(clschk,"npc_combinedropship",false)) return Plugin_Handled;
	float origin[3];
	GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
	origin[2]-=100.0;
	for (int i = MaxClients+1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if ((StrContains(clsname,"npc_",false) != -1) && (!StrEqual(clsname,"npc_combinedropship",false)) && (!StrEqual(clsname,"npc_bullseye",false)))
			{
				int dropspawnflags = GetEntProp(i,Prop_Data,"m_spawnflags");
				if (dropspawnflags & 2048)
				{
					float npcorigin[3];
					GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",npcorigin);
					float chkdist = GetVectorDistance(origin,npcorigin,false);
					if (chkdist < 80.0)
					{
						if (debuglvl > 1) PrintToServer("Template %i %s is %1.f away from ship",i,clsname,chkdist);
						int targent = GetEntPropEnt(caller,Prop_Data,"m_hLandTarget");
						if (targent != -1)
						{
							float targorigin[3];
							GetEntPropVector(targent,Prop_Data,"m_vecAbsOrigin",targorigin);
							float targang[3];
							GetEntPropVector(targent,Prop_Data,"m_angAbsRotation",targang);
							TeleportEntity(i,targorigin,targang,NULL_VECTOR);
						}
						else
						{
							SetVariantInt(0);
							AcceptEntityInput(i,"SetHealth");
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

void findtouchingents(float mins[3], float maxs[3], int ent)
{
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
	float entorg[3];
	if (HasEntProp(ent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(ent,Prop_Data,"m_vecAbsOrigin",entorg);
	else if (HasEntProp(ent,Prop_Send,"m_vecOrigin")) GetEntPropVector(ent,Prop_Send,"m_vecOrigin",entorg);
	mins[0]+=entorg[0];
	mins[1]+=entorg[1];
	mins[2]+=entorg[2];
	maxs[0]+=entorg[0];
	maxs[1]+=entorg[1];
	maxs[2]+=entorg[2];
	float porigin[3];
	for (int i = 1;i<GetMaxEntities();i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i) && (i != ent))
		{
			if (HasEntProp(i,Prop_Data,"m_hParent"))
			{
				if ((GetEntPropEnt(i,Prop_Data,"m_hParent") == ent) || (GetEntPropEnt(i,Prop_Data,"m_hParent") != -1)) continue;
			}
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",porigin);
			else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",porigin);
			if ((porigin[0] > mins[0]) && (porigin[1] > mins[1]) && (porigin[2] > mins[2]) && (porigin[0] < maxs[0]) && (porigin[1] < maxs[1]) && (porigin[2] < maxs[2]))
			{
				if ((StrContains(clsname,"weapon_",false) == 0) || (StrContains(clsname,"item_",false) == 0))
				{
					if (HasEntProp(i,Prop_Data,"m_hOwner"))
					{
						if (GetEntPropEnt(i,Prop_Data,"m_hOwner") != -1) continue;
					}
					if (debuglvl == 3) PrintToServer("%i %s touching train %i removed...",i,clsname,ent);
					AcceptEntityInput(i,"kill");
				}
			}
		}
	}
}

public Action trigout(const char[] output, int caller, int activator, float delay)
{
	if (seqenablecheck)
	{
		char targn[128];
		char scenes[128];
		if (HasEntProp(caller,Prop_Data,"m_iszEntity"))
			GetEntPropString(caller,Prop_Data,"m_iszEntity",targn,sizeof(targn));
		else
		{
			if (HasEntProp(caller,Prop_Data,"m_iszSceneFile"))
				GetEntPropString(caller,Prop_Data,"m_iszSceneFile",scenes,sizeof(scenes));
			if ((StrContains(scenes,"alyx",false) != -1) || (StrContains(scenes,"/al_",false) != -1))
				Format(targn,sizeof(targn),"alyx");
			else if ((StrContains(scenes,"barn",false) != -1) || (StrContains(scenes,"/ba_",false) != -1))
				Format(targn,sizeof(targn),"barney");
			else if ((StrContains(scenes,"eli",false) != -1) || (StrContains(scenes,"/eli_",false) != -1))
				Format(targn,sizeof(targn),"eli");
			else if ((StrContains(scenes,"mag",false) != -1) || (StrContains(scenes,"/ma_",false) != -1))
				Format(targn,sizeof(targn),"magnusson");
			else if ((StrContains(scenes,"breen",false) != -1) || (StrContains(scenes,"/br_",false) != -1))
				Format(targn,sizeof(targn),"breen");
		}
		float origin[3];
		GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
		char sname[128];
		GetEntPropString(caller,Prop_Data,"m_iName",sname,sizeof(sname));
		if (strlen(targn) < 1)
			GetEntPropString(caller,Prop_Data,"m_target",targn,sizeof(targn));
		if (FindStringInArray(entnames,targn) != -1) return Plugin_Continue;
		if ((StrContains(sname,"al_vort",false) != -1) && ((!StrEqual(targn,"alyx")) || (!StrEqual(targn,"vort"))))
		{
			if (!findtargn("alyx"))
				readoutputs(caller,"alyx");
			findgfollow(-1,"alyx");
			if (!findtargn("vort"))
				readoutputs(caller,"vort");
			findgfollow(-1,"vort");
		}
		else
		{
			if (StrContains(scenes,"ep1_intro_alyx",false) == -1)
			{
				if ((!findtargn(targn)) && (strlen(targn) > 0))
				{
					if (debuglvl > 0) PrintToServer("Could not find actor with name %s",targn);
					readoutputs(caller,targn);
				}
			}
		}
		if (debuglvl == 3) PrintToServer("Sequence ent %i with name %s started with %s target\nPlaying %s\nAt: %1.f %1.f %1.f",caller,sname,targn,scenes,origin[0],origin[1],origin[2]);
	}
	return Plugin_Continue;
}

public Action trigtp(const char[] output, int caller, int activator, float delay)
{
	if (FindValueInArray(ignoretrigs,caller) == -1)
	{
		int actmod = activator;
		bool skipactchk = false;
		char tmpout[32];
		Format(tmpout,sizeof(tmpout),output);
		char clsname[24];
		if (IsValidEntity(caller))
		{
			GetEntityClassname(caller,clsname,sizeof(clsname));
			if (((StrEqual(clsname,"hud_timer",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"logic_choreographed_scene",false))) && ((actmod > MaxClients) || (actmod < 1)))
			{
				skipactchk = true;
				actmod = 0;
			}
			if ((StrEqual(clsname,"trigger_multiple",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"func_door",false)) || (StrEqual(clsname,"trigger_coop",false)) || (StrEqual(clsname,"hud_timer",false)))
			{
				UnhookSingleEntityOutput(caller,output,trigtp);
				PushArrayCell(ignoretrigs,caller);
			}
			if ((StrContains(clsname,"env_xen_portal",false) == 0) && (StrEqual(tmpout,"OnUser2",false)))
			{
				Format(tmpout,sizeof(tmpout),"OnFinishPortal");
			}
			if (caller == activator)
			{
				if (activator > MaxClients)
				{
					for (int j = 1;j<MaxClients+1;j++)
					{
						if (IsValidEntity(j))
						{
							if (IsClientConnected(j))
							{
								if (IsClientInGame(j))
								{
									if (IsPlayerAlive(j))
									{
										if (HasEntProp(j,Prop_Data,"m_hUseEntity"))
										{
											int useent = GetClientAimTarget(j,false);
											if (useent == activator)
											{
												float clpos[3];
												GetClientAbsOrigin(j,clpos);
												float entpos[3];
												if (HasEntProp(activator,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(activator,Prop_Data,"m_vecAbsOrigin",entpos);
												else if (HasEntProp(activator,Prop_Send,"m_vecOrigin")) GetEntPropVector(activator,Prop_Send,"m_vecOrigin",entpos);
												if (GetVectorDistance(clpos,entpos,false) < 150.0)
												{
													actmod = j;
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
		}
		if (skipactchk)
		{
			char targn[64];
			GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
			if (strlen(targn) < 1) Format(targn,sizeof(targn),"notargn");
			float origin[3];
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
			if (playerteleports) readoutputstp(caller,targn,tmpout,"Teleport",origin,actmod);
			if (vehiclemaphook) readoutputstp(caller,targn,tmpout,"Save",origin,actmod);
			readoutputstp(caller,targn,tmpout,"SetCheckPoint",origin,actmod);
			if (GetArraySize(addedinputs) > 0)
			{
				char inputadded[64];
				for (int i = 0;i<GetArraySize(addedinputs);i++)
				{
					GetArrayString(addedinputs,i,inputadded,sizeof(inputadded));
					readoutputstp(caller,targn,tmpout,inputadded,origin,actmod);
				}
			}
		}
		else
		{
			char targn[64];
			GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
			if (strlen(targn) < 1) Format(targn,sizeof(targn),"notargn");
			float origin[3];
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
			if (playerteleports) readoutputstp(caller,targn,tmpout,"Teleport",origin,actmod);
			if (vehiclemaphook) readoutputstp(caller,targn,tmpout,"Save",origin,actmod);
			readoutputstp(caller,targn,tmpout,"SetCheckPoint",origin,actmod);
			if (GetArraySize(addedinputs) > 0)
			{
				char inputadded[64];
				for (int i = 0;i<GetArraySize(addedinputs);i++)
				{
					GetArrayString(addedinputs,i,inputadded,sizeof(inputadded));
					readoutputstp(caller,targn,tmpout,inputadded,origin,actmod);
				}
			}
		}
	}
}

public Action trigpicker(const char[] output, int caller, int activator, float delay)
{
	int actmod = activator;
	char tmpout[32];
	Format(tmpout,sizeof(tmpout),output);
	if ((actmod > 1) && (actmod < MaxClients+1))
	{
		if (IsValidEntity(activator))
		{
			if (IsPlayerAlive(activator))
			{
				char targn[64];
				GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
				if (strlen(targn) < 1) Format(targn,sizeof(targn),"notargn");
				float origin[3];
				readoutputstp(caller,targn,tmpout,"!picker",origin,actmod);
			}
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action createelev(const char[] output, int caller, int activator, float delay)
{
	if (FindValueInArray(elevlist,caller) == -1)
	{
		PushArrayCell(elevlist,caller);
		char targn[32];
		GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
		if (strlen(targn) > 0)
		{
			char mdlname[64];
			float elevorg[3];
			float angs[3];
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",elevorg);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",elevorg);
			if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
			GetEntPropString(caller,Prop_Data,"m_ModelName",mdlname,sizeof(mdlname));
			if ((strlen(mdlname) > 0) && (StrContains(mapbuf,"r_map3",false) == -1) && (StrContains(mapbuf,"01_spymap_ep3",false) == -1))
			{
				int sf = GetEntProp(caller,Prop_Data,"m_spawnflags");
				if ((!(sf & 1<<3)) && (GetEntityCount() < 2000))
				{
					int brushent;
					if (StrContains(mdlname,"*",false) == 0)
						brushent = CreateEntityByName("func_tracktrain");
					else
						brushent = CreateEntityByName("func_brush");
					DispatchKeyValue(brushent,"model",mdlname);
					DispatchKeyValue(brushent,"rendermode","10");
					DispatchKeyValue(brushent,"renderamt","255");
					DispatchKeyValue(brushent,"rendercolor","0 0 0");
					DispatchKeyValue(brushent,"disablereceiveshadows","1");
					DispatchKeyValue(brushent,"DisableShadows","1");
					DispatchKeyValue(brushent,"solid","6");
					elevorg[2] = elevorg[2]-1.0;
					TeleportEntity(brushent,elevorg,angs,NULL_VECTOR);
					DispatchSpawn(brushent);
					ActivateEntity(brushent);
					SetVariantString("!activator");
					AcceptEntityInput(brushent,"SetParent",caller);
					if (debuglvl == 3) PrintToServer("Created brush at %1.f %1.f %1.f with model of:\n%s parented to %s",elevorg[0],elevorg[1],elevorg[2],mdlname,targn);
				}
			}
		}
	}
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	int killed = GetEventInt(event, "entindex_killed");
	if (IsValidEntity(killed))
	{
		if (HasEntProp(killed,Prop_Data,"m_bGameEndAlly"))
		{
			if (GetEntProp(killed,Prop_Data,"m_bGameEndAlly") > 0)
			{
				int gametext = CreateEntityByName("game_text");
				if (gametext != -1)
				{
					DispatchKeyValue(gametext,"x","-1");
					DispatchKeyValue(gametext,"y","-1");
					DispatchKeyValue(gametext,"message","#HL2_GameOver_Ally");
					DispatchKeyValue(gametext,"channel","1");
					DispatchKeyValue(gametext,"color","150 150 150");
					DispatchKeyValue(gametext,"fadein","0.035");
					DispatchKeyValue(gametext,"fadeout","1.5");
					DispatchKeyValue(gametext,"holdtime","3.0");
					DispatchKeyValue(gametext,"effect","2");
					DispatchKeyValue(gametext,"spawnflags","1");
					DispatchSpawn(gametext);
					ActivateEntity(gametext);
					AcceptEntityInput(gametext,"Display");
				}
			}
		}
	}
}

public Action Event_PlayerDisconnect( Handle event, const char[] name, bool dontBroadcast )
{
	/*
	"userid"	"short"		// user ID on server
	"reason"	"string"	// "self", "kick", "ban", "cheat", "error"
	"name"		"string"	// player name
	"networkid"	"string"	// player network (i.e steam) id
	"bot"		"short"		// is a bot
	*/
	char dcchar[256];
	char netid[64];
	GetEventString(event,"reason",dcchar,sizeof(dcchar));
	GetEventString(event,"networkid",netid,sizeof(netid));
	if (StrContains(dcchar,"timed out",false) != -1) PushArrayString(dctimeoutarr,netid);
}

void readoutputs(int scriptent, char[] targn)
{
	if (debuglvl == 3) PrintToServer("Read outputs for script ents");
	Handle filehandle = OpenFile(mapbuf,"r");
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		char lineoriginfixup[128];
		char kvs[128][64];
		bool reverse = true;
		bool createent = false;
		bool passvars = false;
		int ent = -1;
		Handle passedarr = CreateArray(64);
		float fileorigin[3];
		char clsscript[32];
		char tmpchar[128];
		GetEntityClassname(scriptent,clsscript,sizeof(clsscript));
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (strlen(line) > 0)
			{
				if (StrContains(line,"\"targetname\"",false) == 0)
				{
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				else if (StrContains(line,"\"template0",false) == 0)
				{
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"template0","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					strcopy(tmpchar,sizeof(tmpchar),tmpchar[2]);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				else if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
				{
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"actor\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				if ((StrEqual(targn,lineoriginfixup,false)) && (reverse))
				{
					int linepos = FilePosition(filehandle);
					if (debuglvl == 3) PrintToServer("Found matching %s on line %i",targn,linepos);
					reverse = false;
					createent = true;
				}
				if ((!StrEqual(line,"}",false)) || (!StrEqual(line,"{",false)))
				{
					if (ent == -1) passvars = true;
					else
					{
						passvars = false;
						for (int k;k<GetArraySize(passedarr);k++)
						{
							char ktmp[128];
							char ktmp2[128];
							GetArrayString(passedarr, k, ktmp, sizeof(ktmp));
							k++;
							GetArrayString(passedarr, k, ktmp2, sizeof(ktmp2));
							if ((debuglvl > 1) && (createent)) PrintToServer("%s %s",ktmp,ktmp2);
							DispatchKeyValue(ent,ktmp,ktmp2);
						}
					}
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
					ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
					if (passvars)
					{
						PushArrayString(passedarr,kvs[1]);
						PushArrayString(passedarr,kvs[3]);
					}
				}
				if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)) && (ent == -1))
				{
					ClearArray(passedarr);
					passvars = true;
				}
				else if (createent)
				{
					if ((StrEqual(line,"}",false)) || (StrEqual(line,"{",false)))
					{
						float origin[3];
						if (!StrEqual(clsscript,"logic_choreographed_scene",false))
							GetEntPropVector(scriptent,Prop_Data,"m_vecAbsOrigin",origin);
						if ((origin[0] == 0.0) && (origin[1] == 0.0) && (origin[2] == 0.0))
						{
							origin[0] = fileorigin[0];
							origin[1] = fileorigin[1];
							origin[2] = fileorigin[2];
						}
						float angs[3];
						GetEntPropVector(scriptent,Prop_Data,"m_angAbsRotation",angs);
						if ((ent != -1) && (!StrEqual(clsscript,"ai_goal_follow",false)))
						{
							DispatchSpawn(ent);
							ActivateEntity(ent);
							SetEntData(ent, collisiongroup, 17, 4, true);
							TeleportEntity(ent,origin,angs,NULL_VECTOR);
							if (TR_PointOutsideWorld(origin))
							{
								origin[2]+=5.0;
								TeleportEntity(ent,origin,angs,NULL_VECTOR);
								origin[2]-=5.0;
							}
							origin[2]+=80.0;
							if (TR_PointOutsideWorld(origin))
							{
								origin[2]-=90.0;
								TeleportEntity(ent,origin,angs,NULL_VECTOR);
							}
						}
						if (StrEqual(clsscript,"scripted_sequence",false))
							AcceptEntityInput(scriptent,"BeginSequence");
						else if (StrEqual(clsscript,"ai_goal_follow",false) && (ent != -1))
							AcceptEntityInput(ent,"Activate");
						else if (StrEqual(clsscript,"ai_goal_follow",false))
							AcceptEntityInput(scriptent,"Activate");
						else
							AcceptEntityInput(scriptent,"Start");
						break;
					}
					if (StrContains(line,"\"origin\"",false) == 0)
					{
						Format(tmpchar,sizeof(tmpchar),"%s",line);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
						char origch[16][16];
						ExplodeString(tmpchar," ",origch,16,16);
						fileorigin[0] = StringToFloat(origch[0]);
						fileorigin[1] = StringToFloat(origch[1]);
						fileorigin[2] = StringToFloat(origch[2]);
					}
					if (StrContains(line,"\"targetname\"",false) == 0)
					{
						Format(tmpchar,sizeof(tmpchar),"%s",line);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
						TrimString(tmpchar);
						Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
					}
					if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
					{
						Format(tmpchar,sizeof(tmpchar),"%s",line);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"actor\" ","",false);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
						TrimString(tmpchar);
						Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
					}
					char cls[32];
					int arrindx = FindStringInArray(passedarr,"classname");
					if (arrindx != -1)
					{
						GetArrayString(passedarr,arrindx+1,tmpchar,sizeof(tmpchar));
						ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
						ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
						ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
						Format(cls,sizeof(cls),"%s",kvs[3]);
					}
					if (StrContains(cls,"point_template",false) != -1)
					{
						int loginp = CreateEntityByName("logic_auto");
						DispatchKeyValue(loginp,"spawnflags","1");
						char tmpchar2[128];
						char sname[128];
						GetEntPropString(scriptent,Prop_Data,"m_iName",sname,sizeof(sname));
						Format(tmpchar,sizeof(tmpchar),"%s,ForceSpawn,,0,-1",lineoriginfixup);
						DispatchKeyValue(loginp,"OnMapSpawn",tmpchar);
						if (StrEqual(clsscript,"scripted_sequence",false))
							Format(tmpchar2,sizeof(tmpchar2),"%s,BeginSequence,,1,-1",sname);
						else if (StrEqual(clsscript,"ai_goal_follow",false))
						{
							AcceptEntityInput(scriptent,"Activate");
						}
						else
							Format(tmpchar2,sizeof(tmpchar2),"%s,Start,,1,-1",sname);
						DispatchKeyValue(loginp,"OnMapSpawn",tmpchar2);
						DispatchSpawn(loginp);
						ActivateEntity(loginp);
						if (debuglvl > 0) PrintToServer("Found point_template: %s that can spawn this npc",lineoriginfixup);
					}
					else if ((ent == -1) && (strlen(cls) > 0))
					{
						if (StrEqual(cls,"worldspawn",false)) break;
						ent = CreateEntityByName(cls);
						if (debuglvl == 3) PrintToServer("Created Ent as %s",cls);
						if (FindValueInArray(entlist,ent) == -1)
							PushArrayCell(entlist,ent);
					}
				}
			}
		}
		CloseHandle(passedarr);
	}
	CloseHandle(filehandle);
}

void readoutputstp(int caller, char[] targn, char[] output, char[] input, float origin[3], int activator)
{
	if (GetArraySize(inputsarrorigincls) < 1) readoutputsforinputs();
	else
	{
		char tmpoutpchk[128];
		Format(tmpoutpchk,sizeof(tmpoutpchk),"%s,AddOutput,%s ",targn,output);
		char originchar[64];
		Format(originchar,sizeof(originchar),"%i %i %i",RoundFloat(origin[0]),RoundFloat(origin[1]),RoundFloat(origin[2]));
		//char origintargnfind[128];
		//if (strlen(targn) > 0) Format(origintargnfind,sizeof(origintargnfind),"%s\"%s\"",targn,originchar);
		//else Format(origintargnfind,sizeof(origintargnfind),"notargn\"%s\"",originchar);
		char tmpch[128];
		char clsorfixup[16][128];
		Handle tmpremove = CreateArray(64);
		for (int i = 0;i<GetArraySize(inputsarrorigincls);i++)
		{
			GetArrayString(inputsarrorigincls,i,tmpch,sizeof(tmpch));
			ExplodeString(tmpch,"\"",clsorfixup,16,128);
			//if ((StrContains(tmpch,tmpoutpchk,false) != -1) || ((StrContains(tmpch,origintargnfind,false) != -1) && (StrEqual(clsorfixup[1],originchar,false))))
			if ((StrEqual(input,"!picker",false)) && (StrContains(tmpch,output) != -1) && (StrEqual(clsorfixup[0],targn)))
			{
				char lineorgrescom[16][128];
				if ((StrContains(clsorfixup[5],",") != -1) && (StrContains(clsorfixup[3],":") == -1))
				{
					ExplodeString(clsorfixup[5],",",lineorgrescom,16,128);
					if (StrEqual(input,lineorgrescom[0]))
					{
						float delay = StringToFloat(lineorgrescom[3]);
						firepicker(lineorgrescom[1],activator,delay);
					}
				}
			}
			if (((StrEqual(clsorfixup[1],originchar)) && (StrEqual(clsorfixup[0],targn))) || ((StrEqual(clsorfixup[0],targn)) && (StrEqual(clsorfixup[1],originchar))) || (StrContains(clsorfixup[3],tmpoutpchk,false) != -1))
			{
				if (StrContains(tmpch,output,false) != -1)
				{
					char lineorgrescom[16][128];
					if ((StrContains(clsorfixup[5],",") != -1) && (StrContains(clsorfixup[3],":") == -1))
					{
						ExplodeString(clsorfixup[5],",",lineorgrescom,16,128);
						if (StrEqual(input,lineorgrescom[1],false))
						{
							ReplaceString(lineorgrescom[0],sizeof(lineorgrescom[])," ","");
							float delay = StringToFloat(lineorgrescom[3]);
							if (debuglvl >= 2) PrintToServer("%s Input from %s to %s %s",input,targn,lineorgrescom[0],clsorfixup[5]);
							if (StringToInt(lineorgrescom[4]) == 1) PushArrayCell(tmpremove,i);
							if (StrEqual(input,"teleport",false)) findpointtp(-1,lineorgrescom[0],activator,delay);
							else if (StrEqual(input,"save",false))
							{
								resetvehicles(delay);
								if (delay == 0.0) CreateTimer(0.01,recallreset);
							}
							else if (StrEqual(input,"SetCheckPoint",false))
							{
								spawnpointstates(lineorgrescom[2],delay);
							}
							Call_StartForward(SFEntInputHook);
							Call_PushString(input);
							Call_PushCell(activator);
							Call_PushString(lineorgrescom[0]);
							Call_PushString(lineorgrescom[2]);
							Call_PushFloat(delay);
							Call_Finish();
							int findignore = FindValueInArray(ignoretrigs,caller);
							if (findignore != -1)
							{
								RemoveFromArray(ignoretrigs,findignore);
								Handle dp = CreateDataPack();
								WritePackCell(dp,caller);
								WritePackString(dp,output);
								CreateTimer(delay,ReHookTrigTP,dp,TIMER_FLAG_NO_MAPCHANGE);
								//HookSingleEntityOutput(caller,output,trigtp);
							}
						}
					}
					else
					{
						ExplodeString(clsorfixup[3],":",lineorgrescom,16,128);
						if (StrEqual(input,lineorgrescom[1],false))
						{
							char delaystr[64];
							Format(delaystr,sizeof(delaystr),lineorgrescom[3]);
							float delay = StringToFloat(lineorgrescom[3]);
							if (StrContains(lineorgrescom[0],tmpoutpchk) == 0) ReplaceString(lineorgrescom[0],sizeof(lineorgrescom[]),tmpoutpchk,"");
							if (debuglvl >= 2) PrintToServer("%s AddedInput to %s %s",input,lineorgrescom[0],clsorfixup[3]);
							if (StringToInt(lineorgrescom[4]) == 1) PushArrayCell(tmpremove,i);
							if (StrEqual(input,"teleport",false)) findpointtp(-1,lineorgrescom[0],activator,delay);
							else if (StrEqual(input,"save",false))
							{
								resetvehicles(delay);
								if (delay == 0.0) CreateTimer(0.01,recallreset);
							}
							else if (StrEqual(input,"SetCheckPoint",false))
							{
								spawnpointstates(lineorgrescom[2],delay);
							}
							Call_StartForward(SFEntInputHook);
							Call_PushString(input);
							Call_PushCell(activator);
							Call_PushString(lineorgrescom[0]);
							Call_PushString(lineorgrescom[2]);
							Call_PushFloat(delay);
							Call_Finish();
							int findignore = FindValueInArray(ignoretrigs,caller);
							if (findignore != -1)
							{
								RemoveFromArray(ignoretrigs,findignore);
								Handle dp = CreateDataPack();
								WritePackCell(dp,caller);
								WritePackString(dp,output);
								CreateTimer(delay,ReHookTrigTP,dp,TIMER_FLAG_NO_MAPCHANGE);
								//HookSingleEntityOutput(caller,output,trigtp);
							}
						}
					}
				}
			}
		}
		if (GetArraySize(tmpremove) > 0)
		{
			for (int i = 0;i<GetArraySize(tmpremove);i++)
			{
				int j = GetArrayCell(tmpremove,i);
				RemoveFromArray(inputsarrorigincls,j-i);
				UnhookSingleEntityOutput(caller,output,trigtp);
			}
		}
		CloseHandle(tmpremove);
	}
	return;
}

public Action ReHookTrigTP(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int caller = ReadPackCell(dp);
		char output[64];
		ReadPackString(dp,output,sizeof(output));
		CloseHandle(dp);
		if (IsValidEntity(caller))
		{
			HookSingleEntityOutput(caller,output,trigtp);
		}
	}
}

void readoutputsforinputs()
{
	if (hasread) return;
	if (debuglvl > 1) PrintToServer("Read outputs for inputs");
	hasread = true;
	Handle inputclasshooks = CreateArray(64);
	Handle filehandle = OpenFile(mapbuf,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		Handle inputs = CreateArray(32);
		PushArrayString(inputs,",Teleport,,");
		PushArrayString(inputs,",Save,,");
		PushArrayString(inputs,",SetCheckPoint,");
		if (syn56act)
		{
			PushArrayString(inputs,"!picker,");
		}
		if (GetArraySize(addedinputs) > 0)
		{
			char inputadded[64];
			for (int i = 0;i<GetArraySize(addedinputs);i++)
			{
				GetArrayString(addedinputs,i,inputadded,sizeof(inputadded));
				Format(inputadded,sizeof(inputadded),",%s,",inputadded);
				if (FindStringInArray(inputs,inputadded) == -1)
				{
					if (debuglvl > 0) PrintToServer("Added Search Hook %s",inputadded);
					PushArrayString(inputs,inputadded);
				}
			}
		}
		char lineorgres[256];
		char lineorgresexpl[4][16];
		char lineoriginfixup[128];
		char lineadj[256];
		char prevtargn[128];
		bool hastargn = false;
		bool hasorigin = false;
		char classhook[64];
		char kvs[128][64];
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (strlen(line) > 0)
			{
				if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)) || (StrEqual(line,"}{",false)))
				{
					if ((strlen(lineadj) > 0) && (strlen(prevtargn) > 0) && (StrContains(lineadj,"notargn\"",false) == 0))
					{
						//PrintToServer("Lineadj %s prevtn %s",lineadj,prevtargn);
						Format(prevtargn,sizeof(prevtargn),"%s\"",prevtargn);
						if (GetArraySize(inputsarrorigincls) > 0)
						{
							for (int i = 0;i<GetArraySize(inputsarrorigincls);i++)
							{
								char tmpchk[128];
								GetArrayString(inputsarrorigincls,i,tmpchk,sizeof(tmpchk));
								//PrintToServer("\nCheck %s %s\n",tmpchk,lineoriginfixup);
								if (StrContains(tmpchk,lineoriginfixup,false) == 0)
								{
									ReplaceString(tmpchk,sizeof(tmpchk),"notargn\"",prevtargn);
									if (FindStringInArray(inputsarrorigincls,tmpchk) == -1)
									{
										PushArrayString(inputsarrorigincls,tmpchk);
										if ((debuglvl == 3) && (strlen(tmpchk) > 0))
										{
											PrintToServer("%s",tmpchk);
										}
									}
								}
							}
						}
						ReplaceString(lineoriginfixup,sizeof(lineoriginfixup),"notargn\"",prevtargn,false);
						ReplaceString(lineadj,sizeof(lineadj),"notargn\"",prevtargn,false);
					}
					if ((strlen(lineoriginfixup) > 0) && (strlen(lineorgres) > 0) && (strlen(lineadj) > 0) && (hastargn) && (hasorigin) && (FindStringInArray(inputsarrorigincls,lineadj) == -1))
					{
						Format(lineadj,sizeof(lineadj),"%s %s",lineoriginfixup,lineorgres);
						PushArrayString(inputsarrorigincls,lineadj);
						if (debuglvl == 3)
						{
							PrintToServer("%s",lineadj);
						}
						char outpchk[128];
						Format(outpchk,sizeof(outpchk),lineadj);
						ExplodeString(outpchk, "\"", kvs, 64, 128, true);
						ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
						ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
						ReplaceString(kvs[2],sizeof(kvs[]),"\"","",false);
						ReplaceString(kvs[3],sizeof(kvs[]),"\"","",false);
						if (StrContains(lineadj,"AddOutput",false) != -1)
						{
							char tmpexpl[128][64];
							ExplodeString(kvs[3], ":", tmpexpl, 64, 128, true);
							ExplodeString(tmpexpl[0], ",", tmpexpl, 64, 128, true);
							//Format(tmpexpl[0],sizeof(tmpexpl[]),"%s %s",tmpexpl[0],tmpexpl[3]);
							char tmptarg[128];
							Format(tmptarg,sizeof(tmptarg),"%s",tmpexpl[0]);
							ExplodeString(tmpexpl[2], " ", tmpexpl, 64, 128, true);
							if (debuglvl == 3) PrintToServer("Targetname %s Outp %s",tmptarg,tmpexpl[0]);
							SearchForClass(tmptarg);
							Format(outpchk,sizeof(outpchk),"%s %s",tmptarg,tmpexpl[0]);
							if (StrEqual(classhook,"prop_physics_override",false)) Format(classhook,sizeof(classhook),"prop_physics");
							Format(classhook,sizeof(classhook),"%s",tmptarg);
							Format(kvs[3],sizeof(kvs[]),"%s",tmpexpl[0]);
						}
						else Format(outpchk,sizeof(outpchk),"%s %s",classhook,kvs[3]);
						if (StrEqual(kvs[3],"OnFinishPortal",false))
						{
							Format(outpchk,sizeof(outpchk),"%s OnUser2",classhook);
						}
						if (FindStringInArray(inputclasshooks,outpchk) == -1)
						{
							if (StrEqual(classhook,"prop_physics_override",false)) Format(classhook,sizeof(classhook),"prop_physics");
							if (StrContains(kvs[5],"!picker",false) != -1) HookEntityOutput(classhook,kvs[3],trigpicker);
							else HookEntityOutput(classhook,kvs[3],trigtp);
							PushArrayString(inputclasshooks,outpchk);
						}
					}
					lineoriginfixup = "";
					lineadj = "";
					prevtargn = "";
					hastargn = false;
					hasorigin = false;
				}
				if (StrContains(line,"\"chaptertitle\"",false) == 0)
				{
					char tmpexpl[64][64];
					ReplaceString(line,sizeof(line),"\"","",false);
					ExplodeString(line," ",tmpexpl,64,64,true);
					if (StrContains(mapbuf,"hl2_",false) != -1)
						Format(ChapterTitle,sizeof(ChapterTitle),"HL2_%s",tmpexpl[1]);
					else if (StrContains(mapbuf,"ep1_",false) != -1)
					{
						Format(ChapterTitle,sizeof(ChapterTitle),"%s",tmpexpl[1]);
						ReplaceStringEx(ChapterTitle,sizeof(ChapterTitle),"EP1_","episodic_",-1,-1,false);
						if ((StrContains(ChapterTitle,"episodic_",false) == -1) && (StrContains(ChapterTitle,"Chapter",false) != -1)) Format(ChapterTitle,sizeof(ChapterTitle),"episodic_%s",ChapterTitle);
					}
					else if (StrContains(mapbuf,"bms_bm_c",false) != -1)
						Format(ChapterTitle,sizeof(ChapterTitle),"BMS_%s",tmpexpl[1]);
					else
						Format(ChapterTitle,sizeof(ChapterTitle),"%s",tmpexpl[1]);
					if (StrEqual(ChapterTitle,PreviousTitle,false)) ChapterTitle = "";
					else Format(PreviousTitle,sizeof(PreviousTitle),"%s",ChapterTitle);
				}
				if ((StrContains(line,"\"origin\"",false) == 0) && (!hasorigin))
				{
					char tmpchar[64];
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					ExplodeString(tmpchar, " ", lineorgresexpl, 4, 16);
					if (hastargn) Format(lineoriginfixup,sizeof(lineoriginfixup),"%s%i %i %i\"",lineoriginfixup,RoundFloat(StringToFloat(lineorgresexpl[0])),RoundFloat(StringToFloat(lineorgresexpl[1])),RoundFloat(StringToFloat(lineorgresexpl[2])));
					else Format(lineoriginfixup,sizeof(lineoriginfixup),"%i %i %i\"",RoundFloat(StringToFloat(lineorgresexpl[0])),RoundFloat(StringToFloat(lineorgresexpl[1])),RoundFloat(StringToFloat(lineorgresexpl[2])));
					hasorigin = true;
				}
				else if (StrContains(line,"\"targetname\"",false) == 0)
				{
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" \"","");
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","");
					Format(prevtargn,sizeof(prevtargn),"%s",tmpchar);
					if (!hastargn)
					{
						Format(lineoriginfixup,sizeof(lineoriginfixup),"%s\"%s",tmpchar,lineoriginfixup);
						hastargn = true;
					}
				}
				else if (StrContains(line,"\"classname\"",false) == 0)
				{
					char clschk[128];
					Format(clschk,sizeof(clschk),"%s",line);
					ExplodeString(clschk, "\"", kvs, 64, 128, true);
					ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
					Format(classhook,sizeof(classhook),kvs[3]);
				}
				else if (StrContains(line,",",false) != -1)
				{
					bool formatinput = false;
					char chkinp[64];
					char chkinpadded[64];
					for (int i = 0;i<GetArraySize(inputs);i++)
					{
						GetArrayString(inputs,i,chkinp,sizeof(chkinp));
						Format(chkinpadded,sizeof(chkinpadded),"%s",chkinp);
						ReplaceString(chkinpadded,sizeof(chkinpadded),",",":",false);
						if ((StrContains(line,chkinp,false) != -1) || (StrContains(line,chkinpadded,false) != -1))
						{
							formatinput = true;
							break;
						}
					}
					if (formatinput)
					{
						Format(lineorgres,sizeof(lineorgres),"%s",line);
						ReplaceString(lineorgres,sizeof(lineorgres),"\"OnMapSpawn\" ","");
						if ((!hastargn) && (StrContains(line,",AddOutput,",false) == -1))
						{
							Format(lineoriginfixup,sizeof(lineoriginfixup),"notargn\"%s",lineoriginfixup);
							hastargn = true;
						}
						else if ((!hastargn) && (StrContains(line,",AddOutput,",false) != -1))
						{
							char linenamef[8][128];
							char tmpchar[128];
							Format(tmpchar,sizeof(tmpchar),"%s",line);
							ExplodeString(tmpchar,"\"",linenamef,8,128);
							Format(tmpchar,sizeof(tmpchar),linenamef[3]);
							ExplodeString(tmpchar,",",linenamef,8,128);
							Format(lineoriginfixup,sizeof(lineoriginfixup),"%s\"0 0 0\"",linenamef[0]);
							hastargn = true;
							hasorigin = true;
						}
						Format(lineadj,sizeof(lineadj),"%s %s",lineoriginfixup,lineorgres);
						if ((FindStringInArray(inputsarrorigincls,lineadj) == -1) && (hastargn) && (hasorigin))
						{
							PushArrayString(inputsarrorigincls,lineadj);
							if ((debuglvl == 3) && (strlen(lineadj) > 0))
							{
								PrintToServer("%s",lineadj);
							}
							char outpchk[128];
							Format(outpchk,sizeof(outpchk),"%s",line);
							ExplodeString(outpchk, "\"", kvs, 64, 128, true);
							ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
							ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
							if (StrContains(lineadj,"AddOutput",false) != -1)
							{
								char tmpexpl[128][64];
								ExplodeString(kvs[3], ":", tmpexpl, 64, 128, true);
								ExplodeString(tmpexpl[0], ",", tmpexpl, 64, 128, true);
								//Format(tmpexpl[0],sizeof(tmpexpl[]),"%s %s",tmpexpl[0],tmpexpl[3]);
								char tmptarg[128];
								Format(tmptarg,sizeof(tmptarg),"%s",tmpexpl[0]);
								ExplodeString(tmpexpl[2], " ", tmpexpl, 64, 128, true);
								if (debuglvl == 3) PrintToServer("Targetname %s Outp %s",tmptarg,tmpexpl[0]);
								SearchForClass(tmptarg);
								Format(outpchk,sizeof(outpchk),"%s %s",tmptarg,tmpexpl[0]);
								if (StrEqual(classhook,"prop_physics_override",false)) Format(classhook,sizeof(classhook),"prop_physics");
								Format(classhook,sizeof(classhook),"%s",tmptarg);
								Format(kvs[1],sizeof(kvs[]),"%s",tmpexpl[0]);
								/*
								if (StrEqual(tmpexpl[0],"OnPressed",false))
								{
									Format(outpchk,sizeof(outpchk),"func_button OnPressed");
									Format(kvs[1],sizeof(kvs[]),"OnPressed");
									Format(classhook,sizeof(classhook),"func_button");
								}
								*/
							}
							else Format(outpchk,sizeof(outpchk),"%s %s",classhook,kvs[1]);
							if (StrEqual(kvs[1],"OnFinishPortal",false))
							{
								Format(outpchk,sizeof(outpchk),"%s OnUser2",classhook);
							}
							if (FindStringInArray(inputclasshooks,outpchk) == -1)
							{
								if (StrEqual(classhook,"prop_physics_override",false)) Format(classhook,sizeof(classhook),"prop_physics");
								if (StrContains(kvs[3],"!picker",false) != -1) HookEntityOutput(classhook,kvs[1],trigpicker);
								else HookEntityOutput(classhook,kvs[1],trigtp);
								PushArrayString(inputclasshooks,outpchk);
							}
							if (StrContains(lineadj,"notargn\"",false) == -1) lineorgres = "";
							//lineoriginfixup = "";
							//hastargn = false;
							//hasorigin = false;
						}
					}
				}
			}
		}
		CloseHandle(inputs);
	}
	if (debuglvl > 1)
	{
		if (GetArraySize(inputclasshooks) > 0)
		{
			for (int i = 0;i<GetArraySize(inputclasshooks);i++)
			{
				char tmp[128];
				GetArrayString(inputclasshooks,i,tmp,sizeof(tmp));
				PrintToServer("Hook for %s",tmp);
			}
		}
	}
	CloseHandle(filehandle);
	CloseHandle(inputclasshooks);
	return;
}

int SearchForClass(char tmptarg[128])
{
	int returnent = -1;
	findtargnbyclass(-1,"logic_*",tmptarg,returnent);
	if ((returnent != 0) && (returnent != -1)) return returnent;
	findtargnbyclass(-1,"info_*",tmptarg,returnent);
	if ((returnent != 0) && (returnent != -1)) return returnent;
	findtargnbyclass(-1,"env_*",tmptarg,returnent);
	if ((returnent != 0) && (returnent != -1)) return returnent;
	findtargnbyclass(-1,"ai_*",tmptarg,returnent);
	if ((returnent != 0) && (returnent != -1)) return returnent;
	findtargnbyclass(-1,"math_*",tmptarg,returnent);
	if ((returnent != 0) && (returnent != -1)) return returnent;
	findtargnbyclass(-1,"game_*",tmptarg,returnent);
	if ((returnent != 0) && (returnent != -1)) return returnent;
	findtargnbyclass(-1,"point_template",tmptarg,returnent);
	if ((returnent == 0) || (returnent == -1))
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
							return i;
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
							return i;
						}
					}
					else if (StrEqual(targn,tmptarg))
					{
						GetEntityClassname(i,tmptarg,sizeof(tmptarg));
						return i;
					}
				}
			}
		}
	}
	return returnent;
}

public void findtargnbyclass(int ent, char cls[64], char tmptarg[128], int& retent)
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
					retent = thisent;
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
					retent = thisent;
				}
			}
			else if (StrEqual(targn,tmptarg,false))
			{
				GetEntityClassname(thisent,tmptarg,sizeof(tmptarg));
				retent = thisent;
			}
		}
		findtargnbyclass(thisent++,cls,tmptarg,retent);
	}
	return;
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

public void findtargnbyclassarr(int ent, char cls[64], char tmptarg[128], Handle returnarr)
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
		findtargnbyclassarr(thisent++,cls,tmptarg,returnarr);
	}
	return;
}

void findpointtp(int ent, char[] targn, int cl, float delay)
{
	int thisent = FindEntityByClassname(ent,"point_teleport");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[32];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		char pttarget[32];
		GetEntPropString(thisent,Prop_Data,"m_target",pttarget,sizeof(pttarget));
		if ((StrEqual(targn,enttargn,false)) && (StrEqual(pttarget,"!activator",false)))
		{
			float origin[3];
			GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",origin);
			float angs[3];
			GetEntPropVector(thisent,Prop_Data,"m_angAbsRotation",angs);
			origin[2]+=5.0;
			//PrintToServer("Teleport %i to %i %s",cl,thisent,enttargn);
			if (delay > 0.1)
			{
				char originstr[24];
				char angstr[16];
				Format(originstr,sizeof(originstr),"%1.f %1.f %1.f",origin[0],origin[1],origin[2]);
				Format(angstr,sizeof(angstr),"%1.f %1.f",angs[0],angs[1]);
				Handle dp = CreateDataPack();
				WritePackCell(dp, cl);
				WritePackString(dp,originstr);
				WritePackString(dp,angstr);
				CreateTimer(delay,teleportdelay,dp);
			}
			else TeleportEntity(cl,origin,angs,NULL_VECTOR);
		}
		else if ((StrEqual(targn,enttargn,false)) && ((StrEqual(pttarget,"!player",false)) || (StrEqual(pttarget,"player",false))))
		{
			float origin[3];
			GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",origin);
			float angs[3];
			GetEntPropVector(thisent,Prop_Data,"m_angAbsRotation",angs);
			origin[2]+=1.0;
			if (delay > 0.1)
			{
				char originstr[24];
				char angstr[16];
				Format(originstr,sizeof(originstr),"%1.f %1.f %1.f",origin[0],origin[1],origin[2]);
				Format(angstr,sizeof(angstr),"%1.f %1.f",angs[0],angs[1]);
				Handle dp = CreateDataPack();
				WritePackString(dp,originstr);
				WritePackString(dp,angstr);
				CreateTimer(delay,teleportdelayallply,dp);
			}
			else
			{
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsValidEntity(i))
						if (IsClientConnected(i))
							if (IsClientInGame(i))
								if (IsPlayerAlive(i))
									TeleportEntity(i,origin,angs,NULL_VECTOR);
				}
			}
		}
		else findpointtp(thisent,targn,cl,delay);
	}
	return;
}

public Action teleportdelay(Handle timer, Handle dp)
{
	ResetPack(dp);
	int cl = ReadPackCell(dp);
	char originstr[24];
	ReadPackString(dp,originstr,sizeof(originstr));
	char angstr[16];
	ReadPackString(dp,angstr,sizeof(angstr));
	CloseHandle(dp);
	if ((IsValidEntity(cl)) && (cl < MaxClients+1) && (cl > 0))
	{
		if (IsClientConnected(cl))
			if (IsClientInGame(cl))
				if (IsPlayerAlive(cl))
				{
					float origin[3];
					float angs[3];
					char originarr[24][3];
					char angarr[16][3];
					ExplodeString(originstr, " ", originarr, 3, 24);
					ExplodeString(angstr, " ", angarr, 3, 16);
					origin[0] = StringToFloat(originarr[0]);
					origin[1] = StringToFloat(originarr[1]);
					origin[2] = StringToFloat(originarr[2]);
					angs[0] = StringToFloat(angarr[0]);
					angs[1] = StringToFloat(angarr[1]);
					TeleportEntity(cl,origin,angs,NULL_VECTOR);
				}
	}
}

public Action teleportdelayallply(Handle timer, Handle dp)
{
	ResetPack(dp);
	char originstr[24];
	ReadPackString(dp,originstr,sizeof(originstr));
	char angstr[16];
	ReadPackString(dp,angstr,sizeof(angstr));
	CloseHandle(dp);
	float origin[3];
	float angs[3];
	char originarr[24][3];
	char angarr[16][3];
	ExplodeString(originstr, " ", originarr, 3, 24);
	ExplodeString(angstr, " ", angarr, 3, 16);
	origin[0] = StringToFloat(originarr[0]);
	origin[1] = StringToFloat(originarr[1]);
	origin[2] = StringToFloat(originarr[2]);
	angs[0] = StringToFloat(angarr[0]);
	angs[1] = StringToFloat(angarr[1]);
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
			if (IsClientConnected(i))
				if (IsClientInGame(i))
					if (IsPlayerAlive(i))
						TeleportEntity(i,origin,angs,NULL_VECTOR);
	}
}

void firepicker(char[] input, int activator, float delay)
{
	if (delay > 0.1)
	{
		Handle dp = CreateDataPack();
		WritePackString(dp,input);
		WritePackCell(dp,activator);
		CreateTimer(delay,recallpicker,dp,TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if ((IsValidEntity(activator)) && (activator > 0) && (activator < MaxClients+1))
		{
			int targ = GetClientAimTarget(activator,false);
			if (targ != -1)
			{
				AcceptEntityInput(targ,input,activator);
				//PrintToServer("Activator %i Input %s",activator,input);
			}
		}
	}
}

public Action recallpicker(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		char input[128];
		ResetPack(dp);
		ReadPackString(dp,input,sizeof(input));
		int activator = ReadPackCell(dp);
		CloseHandle(dp);
		if (IsValidEntity(activator))
			firepicker(input,activator,0.0);
	}
}

public Action onreload(const char[] output, int caller, int activator, float delay)
{
	char logn[32];
	if (IsValidEntity(caller))
	{
		if (HasEntProp(caller,Prop_Data,"m_iName")) GetEntPropString(caller,Prop_Data,"m_iName",logn,sizeof(logn));
	}
	if (StrEqual(logn,"syn_logicauto",false))
	{
		ClearArray(ignoretrigs);
	}
	return Plugin_Continue;
}

void findgfollow(int ent, char[] targn)
{
	int thisent = FindEntityByClassname(ent,"ai_goal_follow");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char actor[128];
		GetEntPropString(thisent,Prop_Data,"m_iszActor",actor,sizeof(actor));
		if ((strlen(actor) > 0) && (StrEqual(actor,targn,false)))
		{
			AcceptEntityInput(thisent,"Activate");
		}
		else
			findgfollow(thisent++,targn);
	}
	else
	{
		int aiglent = CreateEntityByName("ai_goal_follow");
		DispatchSpawn(aiglent);
		ActivateEntity(aiglent);
		readoutputs(aiglent,targn);
		Handle data;
		data = CreateDataPack();
		WritePackCell(data, aiglent);
		WritePackString(data, "ai_goal_follow");
		CreateTimer(0.1,cleanup,data);
	}
}

void spawnpointstates(char[] targn, float delay)
{
	Handle arr = CreateArray(64);
	FindAllByClassname(arr,-1,"info_player_coop");
	if (GetArraySize(arr) > 0)
	{
		for (int i = 0;i<GetArraySize(arr);i++)
		{
			int ent = GetArrayCell(arr,i);
			if (IsValidEntity(ent))
			{
				if (HasEntProp(ent,Prop_Data,"m_iName"))
				{
					char enttargn[64];
					GetEntPropString(ent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
					if (StrEqual(targn,enttargn,false))
					{
						if (delay > 0.1) CreateTimer(delay,spawnpointstatesdelay,ent,TIMER_FLAG_NO_MAPCHANGE);
						else CreateTimer(0.1,spawnpointstatesdelay,ent,TIMER_FLAG_NO_MAPCHANGE);
						break;
					}
				}
			}
		}
	}
	CloseHandle(arr);
}

public Action spawnpointstatesdelay(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		Handle arr = CreateArray(64);
		FindAllByClassname(arr,-1,"info_player_coop");
		if (GetArraySize(arr) > 0)
		{
			for (int i = 0;i<GetArraySize(arr);i++)
			{
				int ent = GetArrayCell(arr,i);
				if (IsValidEntity(ent))
				{
					if (HasEntProp(ent,Prop_Data,"m_bDisabled")) SetEntProp(ent,Prop_Data,"m_bDisabled",1);
				}
			}
		}
		CloseHandle(arr);
		if (HasEntProp(entity,Prop_Data,"m_bDisabled")) SetEntProp(entity,Prop_Data,"m_bDisabled",0);
	}
}

public Action cleanup(Handle timer, Handle data)
{
	ResetPack(data);
	int cleanupent = ReadPackCell(data);
	char clsname[32];
	ReadPackString(data,clsname,sizeof(clsname));
	CloseHandle(data);
	if ((IsValidEntity(cleanupent)) && (cleanupent > MaxClients))
	{
		char tmpcls[32];
		GetEntityClassname(cleanupent,tmpcls,sizeof(tmpcls));
		if (StrEqual(tmpcls,clsname,false))
			AcceptEntityInput(cleanupent,"kill");
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	ClientCommand(client,"alias sv_shutdown \"echo nope\"");
	if (bBlockEx) ClientCommand(client,"alias exec \"echo nope\"");
	return true;
}

public void OnClientDisconnect(int client)
{
	votetime[client] = 0.0;
	DisplayedChapterTitle[client] = false;
}

public Action SynTripmineTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (BlockTripMineDamage)
	{
		int owner = -1;
		if (HasEntProp(victim,Prop_Data,"m_hOwner")) owner = GetEntPropEnt(victim,Prop_Data,"m_hOwner");
		if ((owner == -1) && (HasEntProp(victim,Prop_Data,"m_hThrower"))) owner = GetEntPropEnt(victim,Prop_Data,"m_hThrower");
		if ((IsValidEntity(owner)) && (owner < MaxClients+1) && (attacker > 0) && (attacker < MaxClients+1))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (HasEntProp(attacker,Prop_Data,"m_hPhysicsAttacker"))
	{
		int atk = GetEntPropEnt(attacker,Prop_Data,"m_hPhysicsAttacker");
		if (((!friendlyfire) && (atk < MaxClients+1)) && (atk > 0))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	if (HasEntProp(attacker,Prop_Data,"m_hLastAttacker"))
	{
		int atk = GetEntPropEnt(attacker,Prop_Data,"m_hLastAttacker");
		if (((!friendlyfire) && (atk < MaxClients+1)) && (atk > 0))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	if (HasEntProp(inflictor,Prop_Data,"m_hEffectEntity"))
	{
		int atk = GetEntPropEnt(inflictor,Prop_Data,"m_hEffectEntity");
		if ((!friendlyfire) && (atk < MaxClients+1) && (atk > 0) && (victim != atk))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	char clsnamechk[32];
	GetEntityClassname(inflictor,clsnamechk,sizeof(clsnamechk));
	if ((StrEqual(clsnamechk,"npc_turret_floor",false)) || (StrEqual(clsnamechk,"npc_manhack",false)))
	{
		if (HasEntProp(inflictor,Prop_Data,"m_bCarriedByPlayer"))
		{
			if (GetEntProp(inflictor,Prop_Data,"m_bCarriedByPlayer") != 0)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		if (HasEntProp(inflictor,Prop_Data,"m_bHeld"))
		{
			if (GetEntProp(inflictor,Prop_Data,"m_bHeld") != 0)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	else if (StrEqual(clsnamechk,"simple_physics_prop",false))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else if (StrContains(clsnamechk,"npc_zombie_s",false) == 0)
	{
		int rand = GetRandomInt(1,3);
		char snd[64];
		Format(snd,sizeof(snd),"npc\\zombie\\claw_strike%i.wav",rand);
		EmitSoundToAll(snd, inflictor, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
	}
	else if (StrEqual(clsnamechk,"npc_alien_slave",false))
	{
		float tkscale = 1.0;
		Handle skillchk = FindConVar("skill");
		if (skillchk != INVALID_HANDLE)
		{
			Handle tkscalechk = INVALID_HANDLE;
			int skill = GetConVarInt(skillchk);
			if (skill == 1) tkscalechk = FindConVar("sk_dmg_take_scale1");
			else if (skill == 2) tkscalechk = FindConVar("sk_dmg_take_scale2");
			else if (skill == 3) tkscalechk = FindConVar("sk_dmg_take_scale3");
			if (tkscalechk != INVALID_HANDLE)
			{
				tkscale = GetConVarFloat(tkscalechk);
			}
			CloseHandle(tkscalechk);
		}
		CloseHandle(skillchk);
		damage = slavezap*tkscale;
		return Plugin_Changed;
	}
	if (FindValueInArray(physboxarr,attacker) != -1)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	char atkcls[64];
	GetEntityClassname(attacker,atkcls,sizeof(atkcls));
	//PrintToServer("%i %i %i inf %s atk %s %1.f",attacker,inflictor,damagetype,clsnamechk,atkcls,damage);
	if ((attacker == 0) && (inflictor == 0) && (damagetype == 1) && (StrEqual(clsnamechk,"worldspawn",false)) && (StrEqual(atkcls,"worldspawn",false)))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	if (HasEntProp(victim,Prop_Data,"m_bitsDamageType"))
	{
		int dmgbit = GetEntProp(victim,Prop_Data,"m_bitsDamageType");
		if ((dmgbit == 1179648) || (dmgbit == 1048576)) SetEntProp(victim,Prop_Data,"m_bitsDamageType",0);
	}
	if ((damagetype == 32) && (longjumpactive) && (victim < MaxClients+1))
	{
		damage = damage/3.0;
		if (damage < 10.0) damage = 0.0;
		return Plugin_Changed;
	}
	if ((damagetype == 32) && (HasEntProp(victim,Prop_Data,"m_hGroundEntity")))
	{
		int groundentchk = GetEntPropEnt(victim,Prop_Data,"m_hGroundEntity");
		if (IsValidEntity(groundentchk))
		{
			char cls[32];
			GetEntityClassname(groundentchk,cls,sizeof(cls));
			if (StrEqual(cls,"env_xen_pushpad",false))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	//Check disconnect projectile hit ply
	//m_bThrownByPlayer
	//m_nPhysgunState
	//m_hPhysicsAttacker
	//m_hLastAttacker
	//m_flLastPhysicsInfluenceTime
	//m_iTeamNum
	//m_iInitialTeamNum
	
	//m_bClientSideAnimation
	//m_bClientSideFrameReset
	//m_flGravity
	//m_flFriction
	//PrintToServer("Vic %i Atk %i Inf %i Dmg %1.f",victim,attacker,inflictor,damage);
	return Plugin_Continue;
}

void FindSaveTPHooks()
{
	for (int i = MaxClients+1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (StrEqual(clsname,"point_teleport",false))
			{
				char pttarget[32];
				GetEntPropString(i,Prop_Data,"m_target",pttarget,sizeof(pttarget));
				if ((StrEqual(pttarget,"!activator",false)) || (StrEqual(pttarget,"!player",false)) || (StrEqual(pttarget,"player",false))) playerteleports = true;
			}
			/*
			else if (StrEqual(clsname,"logic_relay",false))
			{
				HookSingleEntityOutput(i,"OnTrigger",trigtp);
			}
			else if (StrEqual(clsname,"func_door",false))
			{
				HookSingleEntityOutput(i,"OnOpen",trigtp);
				HookSingleEntityOutput(i,"OnFullyOpen",trigtp);
				HookSingleEntityOutput(i,"OnClose",trigtp);
				HookSingleEntityOutput(i,"OnFullyClosed",trigtp);
			}
			*/
		}
	}
	/*
	HookEntityOutput("trigger_coop","OnPlayersIn",trigtp);
	HookEntityOutput("trigger_coop","OnStartTouch",trigtp);
	HookEntityOutput("trigger_multiple","OnTrigger",trigtp);
	HookEntityOutput("trigger_multiple","OnStartTouch",trigtp);
	HookEntityOutput("trigger_once","OnTrigger",trigtp);
	HookEntityOutput("trigger_once","OnStartTouch",trigtp);
	HookEntityOutput("point_viewcontrol","OnEndFollow",trigtp);
	HookEntityOutput("func_button","OnPressed",trigtp);
	HookEntityOutput("func_button","OnUseLocked",trigtp);
	//HookEntityOutput("prop_door_rotating","OnOpen",trigtp);
	//HookEntityOutput("prop_door_rotating","OnFullyOpen",trigtp);
	//HookEntityOutput("prop_door_rotating","OnClose",trigtp);
	//HookEntityOutput("prop_door_rotating","OnFullyClosed",trigtp);
	*/
}

public Action rehooksaves(Handle timer)
{
	//fix non-initialized cvars
	DefaultCVarCheck("sk_zombie_soldier_health",100);
	DefaultCVarCheck("sk_antlion_air_attack_dmg",10);
	DefaultCVarCheck("sk_antlion_worker_spit_speed",600);
	DefaultCVarCheck("sk_antlion_worker_health",60);
	DefaultCVarCheck("sk_vortigaunt_armor_charge",15);
	DefaultCVarCheck("sk_vortigaunt_armor_charge_per_token",5);
	DefaultCVarCheck("sk_vortigaunt_dmg_zap",25);
	DefaultCVarCheck("sk_headcrab_poison_npc_damage",20);
	DefaultCVarCheck("sk_advisor_health",1000);
	DefaultCVarCheck("sk_barnacle_health",35);
	DefaultCVarCheck("sk_barney_health",35);
	DefaultCVarCheck("sk_bullseye_health",35);
	DefaultCVarCheck("sk_citizen_health",40);
	DefaultCVarCheck("sk_combine_s_health",50);
	DefaultCVarCheck("sk_combine_s_kick",10);
	DefaultCVarCheck("sk_combine_guard_health",70);
	DefaultCVarCheck("sk_combine_guard_kick",15);
	DefaultCVarCheck("sk_strider_health",350);
	DefaultCVarCheck("sk_headcrab_health",10);
	DefaultCVarCheck("sk_headcrab_melee_dmg",5);
	DefaultCVarCheck("sk_headcrab_fast_health",10);
	DefaultCVarCheck("sk_headcrab_poison_health",35);
	DefaultCVarCheck("sk_manhack_health",25);
	DefaultCVarCheck("sk_manhack_melee_dmg",20);
	DefaultCVarCheck("sk_metropolice_health",40);
	DefaultCVarCheck("sk_metropolice_stitch_reaction",1);
	DefaultCVarCheck("sk_metropolice_stitch_tight_hitcount",2);
	DefaultCVarCheck("sk_metropolice_stitch_at_hitcount",1);
	DefaultCVarCheck("sk_metropolice_stitch_behind_hitcount",3);
	DefaultCVarCheck("sk_metropolice_stitch_along_hitcount",2);
	DefaultCVarCheck("sk_rollermine_shock",10);
	DefaultCVarCheck("sk_rollermine_stun_delay",3);
	DefaultCVarCheck("sk_rollermine_vehicle_intercept",1);
	DefaultCVarCheck("sk_scanner_health",30);
	DefaultCVarCheck("sk_scanner_dmg_dive",25);
	DefaultCVarCheck("sk_stalker_health",50);
	DefaultCVarCheck("sk_stalker_melee_dmg",5);
	DefaultCVarCheck("sk_vortigaunt_health",100);
	DefaultCVarCheck("sk_vortigaunt_dmg_claw",10);
	DefaultCVarCheck("sk_vortigaunt_dmg_rake",25);
	DefaultCVarCheck("sk_zombie_health",50);
	DefaultCVarCheck("sk_zombie_dmg_one_slash",10);
	DefaultCVarCheck("sk_zombie_dmg_both_slash",25);
	DefaultCVarCheck("sk_zombie_poison_health",175);
	DefaultCVarCheck("sk_zombie_poison_dmg_spit",20);
	DefaultCVarCheck("sk_antlion_health",30);
	DefaultCVarCheck("sk_antlion_swipe_damage",5);
	DefaultCVarCheck("sk_antlion_jump_damage",5);
	DefaultCVarCheck("sk_antlionguard_health",500);
	DefaultCVarCheck("sk_antlionguard_dmg_charge",20);
	DefaultCVarCheck("sk_antlionguard_dmg_shove",10);
	DefaultCVarCheck("sk_antliongrub_health",5);
	DefaultCVarCheck("sk_ichthyosaur_health",200);
	DefaultCVarCheck("sk_ichthyosaur_melee_dmg",8);
	DefaultCVarCheck("sk_gunship_burst_size",15);
	DefaultCVarCheck("sk_gunship_health_increments",5);
	DefaultCVarCheck("sk_npc_dmg_gunship",40);
	DefaultCVarCheck("sk_npc_dmg_gunship_to_plr",3);
	DefaultCVarCheck("sk_npc_dmg_helicopter",6);
	DefaultCVarCheck("sk_npc_dmg_helicopter_to_plr",3);
	DefaultCVarCheck("sk_helicopter_grenadedamage",30);
	DefaultCVarCheck("sk_helicopter_grenaderadius",275);
	DefaultCVarCheck("sk_helicopter_grenadeforce",55000);
	DefaultCVarCheck("sk_npc_dmg_dropship",2);
	DefaultCVarCheck("sk_apc_health",750);
	DefaultCVarCheck("sk_plr_dmg_ar2",8);
	DefaultCVarCheck("sk_npc_dmg_ar2",3);
	DefaultCVarCheck("sk_max_ar2",60);
	DefaultCVarCheck("sk_max_ar2_altfire",3);
	DefaultCVarCheck("sk_plr_dmg_pistol",5);
	DefaultCVarCheck("sk_npc_dmg_pistol",3);
	DefaultCVarCheck("sk_max_pistol",150);
	DefaultCVarCheck("sk_plr_dmg_smg1",4);
	DefaultCVarCheck("sk_npc_dmg_smg1",3);
	DefaultCVarCheck("sk_max_smg1",225);
	DefaultCVarCheck("sk_plr_dmg_buckshot",8);
	DefaultCVarCheck("sk_npc_dmg_buckshot",3);
	DefaultCVarCheck("sk_max_buckshot",30);
	DefaultCVarCheck("sk_plr_dmg_rpg_round",100);
	DefaultCVarCheck("sk_npc_dmg_rpg_round",50);
	DefaultCVarCheck("sk_max_rpg_round",3);
	DefaultCVarCheck("sk_plr_dmg_smg1_grenade",100);
	DefaultCVarCheck("sk_npc_dmg_smg1_grenade",50);
	DefaultCVarCheck("sk_max_smg1_grenade",3);
	DefaultCVarCheck("sk_smg1_grenade_radius",250);
	DefaultCVarCheck("sk_plr_dmg_357",40);
	DefaultCVarCheck("sk_npc_dmg_357",30);
	DefaultCVarCheck("sk_max_357",12);
	DefaultCVarCheck("sk_plr_dmg_crossbow",100);
	DefaultCVarCheck("sk_npc_dmg_crossbow",10);
	DefaultCVarCheck("sk_max_crossbow",10);
	DefaultCVarCheck("sk_plr_dmg_airboat",3);
	DefaultCVarCheck("sk_npc_dmg_airboat",3);
	DefaultCVarCheck("sk_plr_dmg_grenade",150);
	DefaultCVarCheck("sk_npc_dmg_grenade",75);
	DefaultCVarCheck("sk_max_grenade",5);
	DefaultCVarCheck("sk_plr_dmg_crowbar",10);
	DefaultCVarCheck("sk_npc_dmg_crowbar",5);
	DefaultCVarCheck("sk_plr_dmg_stunstick",10);
	DefaultCVarCheck("sk_npc_dmg_stunstick",40);
	DefaultCVarCheck("sk_plr_dmg_satchel",150);
	DefaultCVarCheck("sk_npc_dmg_satchel",75);
	DefaultCVarCheck("sk_satchel_radius",150);
	DefaultCVarCheck("sk_dmg_energy_grenade",2);
	DefaultCVarCheck("sk_energy_grenade_radius",100);
	DefaultCVarCheck("sk_dmg_homer_grenade",20);
	DefaultCVarCheck("sk_homer_grenade_radius",100);
	DefaultCVarCheck("sk_dmg_spit_grenade",5);
	DefaultCVarCheck("sk_spit_grenade_radius",50);
	DefaultCVarCheck("sk_plr_dmg_fraggrenade",125);
	DefaultCVarCheck("sk_npc_dmg_fraggrenade",75);
	DefaultCVarCheck("sk_fraggrenade_radius",250);
	DefaultCVarCheck("sk_battery",15);
	DefaultCVarCheck("sk_healthcharger",50);
	DefaultCVarCheck("sk_healthkit",25);
	DefaultCVarCheck("sk_healthvial",10);
	DefaultCVarCheck("sk_suitcharger",75);
	DefaultCVarCheck("sk_suitcharger_citadel",500);
	DefaultCVarCheck("sk_suitcharger_citadel_maxarmor",200);
	DefaultCVarCheck("sk_npc_head",3);
	DefaultCVarCheck("sk_npc_chest",1);
	DefaultCVarCheck("sk_npc_stomach",1);
	DefaultCVarCheck("sk_npc_arm",1);
	DefaultCVarCheck("sk_npc_leg",1);
	DefaultCVarCheck("sk_player_head",3);
	DefaultCVarCheck("sk_player_chest",1);
	DefaultCVarCheck("sk_player_stomach",1);
	DefaultCVarCheck("sk_player_arm",1);
	DefaultCVarCheck("sk_player_leg",1);
	int weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_smg1");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_ar2");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_pistol");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_357");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_crowbar");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_bugbait");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_physcannon");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_rpg");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_crossbow");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_stunstick");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_slam");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	weapres = CreateEntityByName("game_weapon_manager");
	if (weapres != -1)
	{
		DispatchKeyValue(weapres,"weaponname","weapon_shotgun");
		DispatchKeyValue(weapres,"maxpieces","20");
		DispatchSpawn(weapres);
		ActivateEntity(weapres);
	}
	findsavetrigs(-1,"trigger_autosave");
	readoutputsforinputs();
}

void DefaultCVarCheck(char[] cvarname, int defaultvalue)
{
	Handle cvar = FindConVar(cvarname);
	if (cvar != INVALID_HANDLE)
	{
		if (GetConVarInt(cvar) == 0) SetConVarInt(cvar,defaultvalue,false,false);
	}
	CloseHandle(cvar);
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

void CreateTrig(float origins[3], char[] mdlnum)
{
	int autostrig = CreateEntityByName("trigger_once");
	DispatchKeyValue(autostrig,"model",mdlnum);
	DispatchKeyValue(autostrig,"spawnflags","1");
	TeleportEntity(autostrig,origins,NULL_VECTOR,NULL_VECTOR);
	DispatchSpawn(autostrig);
	ActivateEntity(autostrig);
	HookSingleEntityOutput(autostrig,"OnStartTouch",autostrigout,true);
	return;
}

public Action autostrigout(const char[] output, int caller, int activator, float delay)
{
	resetvehicles(0.0);
}

void resetvehicles(float delay)
{
	if (vehiclemaphook)
	{
		if (delay > 0.0) CreateTimer(delay,recallreset);
		else
		{
			Handle ignorelist = CreateArray(64);
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					int vehicles = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
					if (vehicles > MaxClients)
					{
						int driver = GetEntProp(i,Prop_Data,"m_iHideHUD");
						int running = 1;
						if (HasEntProp(vehicles,Prop_Data,"m_bIsOn")) running = GetEntProp(vehicles,Prop_Data,"m_bIsOn");
						if ((driver == 3328) && (running))
						{
							char clsname[32];
							GetEntityClassname(vehicles,clsname,sizeof(clsname));
							if (((StrEqual(clsname,"prop_vehicle_jeep",false)) || (StrEqual(clsname,"prop_vehicle_mp",false))) && (FindValueInArray(ignorelist,vehicles) == -1))
							{
								SetEntProp(vehicles,Prop_Data,"m_controls.handbrake",1);
								PushArrayCell(ignorelist,vehicles);
								if (debuglvl == 3) PrintToServer("Reset %i vehicle over save.",vehicles);
							}
						}
					}
				}
			}
			CloseHandle(ignorelist);
		}
	}
}

public Action recallreset(Handle timer)
{
	resetvehicles(0.0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_enemyfinder",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"env_xen_portal",false)) && (!StrEqual(classname,"env_xen_portal_template",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)) && (StrContains(classname,"info_",false) == -1) && (StrContains(classname,"game_",false) == -1) && (StrContains(classname,"trigger_",false) == -1) && (FindValueInArray(entlist,entity) == -1))
	{
		PushArrayCell(entlist,entity);
		if (((StrEqual(classname,"npc_citizen",false)) || (StrEqual(classname,"npc_alyx",false))) && (!(StrContains(mapbuf,"cd",false) == 0))) SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		if ((StrEqual(classname,"npc_vortigaunt",false)) || (StrEqual(classname,"npc_dog",false)) || (StrEqual(classname,"npc_gman",false)) || (StrEqual(classname,"npc_monk",false)))
		{
			int flageffects = GetEntProp(entity,Prop_Data,"m_iEFlags");
			if (!(flageffects & 1<<30))
			{
				SetEntProp(entity,Prop_Data,"m_iEFlags",flageffects+1073741824);
			}
		}
		else if ((StrEqual(classname,"npc_tripmine",false)) || (StrEqual(classname,"npc_satchel",false)))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, SynTripmineTakeDamage);
		}
	}
	if ((StrEqual(classname,"item_health_drop",false)) || (StrEqual(classname,"item_ammo_drop",false)) || (StrEqual(classname,"item_ammo_pack",false)))
	{
		SDKHook(entity, SDKHook_StartTouch, StartTouchprop);
		Handle data;
		data = CreateDataPack();
		WritePackCell(data, entity);
		WritePackString(data, classname);
		CreateTimer(removertimer,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
	}
	if (StrEqual(classname,"logic_auto",false))
	{
		CreateTimer(1.0,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if (StrEqual(classname,"npc_vortigaunt",false))
	{
		CreateTimer(1.0,rechkcol,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if ((StrEqual(classname,"phys_bone_follower",false)) || (StrEqual(classname,"entityflame",false)) || (StrEqual(classname,"_firesmoke",false)) || (StrEqual(classname,"env_fire",false)))
	{
		if (GetEntityCount() > 2000) AcceptEntityInput(entity,"kill");
	}
	else if (GetEntityCount() >= 2000)
	{
		int findrope = FindEntityByClassname(-1,"move_rope");
		if (findrope != -1) AcceptEntityInput(findrope,"kill");
		else
		{
			findrope = FindEntityByClassname(-1,"keyframe_rope");
			if (findrope != -1) AcceptEntityInput(findrope,"kill");
			else
			{
				findrope = FindEntityByClassname(-1,"entityflame");
				if (findrope != -1) AcceptEntityInput(findrope,"kill");
				else
				{
					findrope = FindEntityByClassname(-1,"_firesmoke");
					if (findrope != -1) AcceptEntityInput(findrope,"kill");
				}
			}
		}
	}
	if ((StrContains(classname,"weapon_",false) == 0) && (!StrEqual(classname,"weapon_striderbuster",false)))
	{
		SDKHookEx(entity,SDKHook_SpawnPost,resetweapmv);
	}
	if (StrEqual(classname,"rpg_missile",false))
	{
		if (IsValidEntity(entity))
		{
			CreateTimer(0.3,resetown,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_iName"))
		{
			CreateTimer(0.1,custent,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	int find = FindValueInArray(entlist,entity);
	if (find != -1) RemoveFromArray(entlist,find);
	if ((IsValidEntity(entity)) && (entity > MaxClients))
	{
		char cls[64];
		GetEntityClassname(entity,cls,sizeof(cls));
		if ((StrContains(cls,"choreo",false) != -1) || (StrEqual(cls,"prop_vehicle_prisoner_pod",false)))
		{
			if (HasEntProp(entity,Prop_Data,"m_hPlayer"))
			{
				int ply = GetEntPropEnt(entity,Prop_Data,"m_hPlayer");
				if ((IsValidEntity(ply)) && (ply < MaxClients+1))
				{
					AcceptEntityInput(entity,"ExitVehicle",ply);
				}
			}
		}
	}
}

public Action resetown(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		int own = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
		if ((own > 0) && (own < MaxClients+1))
		{
			if (IsClientInGame(own))
			{
				if (!guiderocket[own])
				{
					clrocket[own] = entity;
					SetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity",0);
					SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",own);
					SDKHook(entity,SDKHook_StartTouch,StartTouchRPG);
					int weap = GetEntPropEnt(own,Prop_Data,"m_hActiveWeapon");
					char weapn[24];
					GetClientWeapon(own,weapn,sizeof(weapn));
					if (StrEqual(weapn,"weapon_rpg",false))
					{
						SetEntProp(weap,Prop_Send,"m_bGuiding",0);
						SetEntProp(weap,Prop_Data,"m_bInReload",0);
						SetEntProp(weap,Prop_Data,"m_nSequence",2);
					}
				}
			}
		}
	}
}

public Action StartTouchRPG(int entity, int other)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEffectEntity"))
		{
			int ownerchk = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
			int effectchk = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			if (((ownerchk == -1) || (ownerchk == 0)) && (effectchk != -1))
				SetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity",effectchk);
		}
	}
}

public void resetweapmv(int entity)
{
	SDKUnhook(entity,SDKHook_SpawnPost,resetweapmv);
	if (IsValidEntity(entity))
	{
		char clsrecheck[32];
		GetEntityClassname(entity,clsrecheck,sizeof(clsrecheck));
		if ((StrContains(clsrecheck,"weapon_",false) == 0) || (StrContains(clsrecheck,"item_weapon_",false) == 0))
		{
			int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
			int parent = GetEntPropEnt(entity,Prop_Data,"m_hParent");
			bool CustChecks = false;
			if (StrContains(mapbuf,"bm_",false) != -1)
			{
				if (sf & 1<<1) CustChecks = true;
			}
			else if ((sf & 1<<0) && (!(sf & 1<<1))) CustChecks = true;
			if ((CustChecks) && (!IsValidEntity(parent)))
			{
				SetEntProp(entity,Prop_Data,"m_MoveType",0);
				float orgs[3];
				GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
				Handle dp = CreateDataPack();
				WritePackCell(dp,entity);
				WritePackFloat(dp,orgs[0]);
				WritePackFloat(dp,orgs[1]);
				WritePackFloat(dp,orgs[2]);
				CreateTimer(0.1,resetweappos,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			if (StrEqual(clsrecheck,"weapon_glock",false))
			{
				if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",3);
			}
			else if (StrEqual(clsrecheck,"weapon_mp5",false))
			{
				if (HasEntProp(entity,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iPrimaryAmmoType",4);
				if (HasEntProp(entity,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(entity,Prop_Data,"m_iSecondaryAmmoType",9);
			}
		}
	}
}

public Action resetweappos(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int entity = ReadPackCell(dp);
		float orgs[3];
		orgs[0] = ReadPackFloat(dp);
		orgs[1] = ReadPackFloat(dp);
		orgs[2] = ReadPackFloat(dp);
		CloseHandle(dp);
		if (IsValidEntity(entity))
		{
			char clsrecheck[32];
			GetEntityClassname(entity,clsrecheck,sizeof(clsrecheck));
			if ((StrContains(clsrecheck,"weapon_",false) == 0) || (StrContains(clsrecheck,"item_weapon_",false) == 0))
			{
				int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
				int parent = GetEntPropEnt(entity,Prop_Data,"m_hParent");
				SetVariantString("spawnflags 0");
				AcceptEntityInput(entity,"AddOutput");
				if ((sf > 0) && (!IsValidEntity(parent)))
				{
					SetEntProp(entity,Prop_Data,"m_MoveType",0);
					TeleportEntity(entity,orgs,NULL_VECTOR,NULL_VECTOR);
				}
			}
		}
	}
}

public Action custent(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		char entcls[128];
		GetEntityClassname(entity,entcls,sizeof(entcls));
		if (StrEqual(entcls,"npc_barnacle",false))
		{
			SetVariantString("npc_ichthyosaur D_LI 99");
			AcceptEntityInput(entity,"SetRelationship");
		}
		else if (StrContains(entcls,"prop_vehicle",false) == 0)
		{
			if (HasEntProp(entity,Prop_Data,"m_vehicleScript"))
			{
				char curscr[64];
				GetEntPropString(entity,Prop_Data,"m_vehicleScript",curscr,sizeof(curscr));
				if (strlen(curscr) < 2)
				{
					if (StrEqual(entcls,"prop_vehicle_airboat",false)) SetEntPropString(entity,Prop_Data,"m_vehicleScript","scripts/vehicles/airboat.txt");
					else if (StrEqual(entcls,"prop_vehicle_prisoner_pod",false)) SetEntPropString(entity,Prop_Data,"m_vehicleScript","scripts/vehicles/prisoner_pod.txt");
					else SetEntPropString(entity,Prop_Data,"m_vehicleScript","scripts/vehicles/jeep_test.txt");
				}
			}
			if (HasEntProp(entity,Prop_Data,"m_ModelName"))
			{
				char curmdl[64];
				GetEntPropString(entity,Prop_Data,"m_ModelName",curmdl,sizeof(curmdl));
				if (strlen(curmdl) > 1)
				{
					if (FileExists(curmdl,true,NULL_STRING))
					{
						if (!IsModelPrecached(curmdl)) PrecacheModel(curmdl,true);
					}
					else
					{
						PrintToServer("Vehicle %s spawned with invalid model: %s",entcls,curmdl);
						AcceptEntityInput(entity,"kill");
						return Plugin_Handled;
					}
				}
				else
				{
					PrintToServer("Vehicle %s spawned without model!",entcls);
					if (StrEqual(entcls,"prop_vehicle_airboat",false))
					{
						PrintToServer("Set airboat to default mdl");
						if (!IsModelPrecached("models/airboat.mdl")) PrecacheModel("models/airboat.mdl",true);
						SetEntityModel(entity,"models/airboat.mdl");
					}
					else if (StrEqual(entcls,"prop_vehicle_jeep",false))
					{
						PrintToServer("Set jeep to default mdl");
						if (!IsModelPrecached("models/buggy.mdl")) PrecacheModel("models/buggy.mdl",true);
						SetEntityModel(entity,"models/buggy.mdl");
					}
					else
					{
						AcceptEntityInput(entity,"kill");
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action rechkcol(Handle timer, int logent)
{
	if (IsValidEntity(logent))
	{
		char entname[32];
		if (HasEntProp(logent,Prop_Data,"m_iName")) GetEntPropString(logent,Prop_Data,"m_iName",entname,sizeof(entname));
		if (collisiongroup == -1) collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
		if (collisiongroup != -1)
		{
			if (StrEqual(entname,"vort",false))
			{
				SetEntData(logent, collisiongroup, 5, 4, true);
			}
		}
	}
}

public Action rechk(Handle timer, int logent)
{
	if (IsValidEntity(logent))
	{
		char entname[32];
		if (HasEntProp(logent,Prop_Data,"m_iName")) GetEntPropString(logent,Prop_Data,"m_iName",entname,sizeof(entname));
		if (!StrEqual(entname,"syn_logicauto",false))
		{
			DispatchKeyValue(logent,"spawnflags","1");
			SetVariantString("spawnflags 1");
			AcceptEntityInput(logent,"AddOutput");
		}
	}
}

public Action StartTouchprop(int entity, int other)
{
	if ((other > MaxClients) && (other > 0) && (IsValidEntity(other)))
	{
		char clscoll[64];
		GetEntityClassname(other,clscoll,sizeof(clscoll));
		if ((StrEqual(clscoll,"prop_dynamic",false)) || (StrEqual(clscoll,"func_clip_vphysics",false)))
		{
			char clscollname[64];
			GetEntPropString(other,Prop_Data,"m_iName",clscollname,sizeof(clscollname));
			if (strlen(clscollname) > 0)
			{
				if ((StrContains(clscollname,"elev",false) != -1) || (StrContains(clscollname,"basket",false) != -1))
					AcceptEntityInput(entity,"kill");
				return Plugin_Continue;
			}
			int parentchk = 0;
			if (HasEntProp(other,Prop_Data,"m_hParent"))
				parentchk = GetEntPropEnt(other,Prop_Data,"m_hParent");
			if ((parentchk > MaxClients) && (IsValidEntity(parentchk)))
			{
				GetEntityClassname(parentchk,clscoll,sizeof(clscoll));
				if (StrEqual(clscoll,"func_tracktrain",false))
					AcceptEntityInput(entity,"kill");
				return Plugin_Continue;
			}
		}
		else if ((StrEqual(clscoll,"func_tracktrain",false)) || (StrEqual(clscoll,"func_brush",false)))
			AcceptEntityInput(entity,"kill");
	}
	return Plugin_Continue;
}

public Action OnWeaponUse(int client, int weapon)
{
	if (instswitch > 0)
	{
		if ((IsValidEntity(weapon)) && (weapon != -1) && (IsValidEntity(client)))
		{
			char weapname[32];
			GetEntityClassname(weapon,weapname,sizeof(weapname));
			if ((StrEqual(weapname,"weapon_physcannon",false)) || (instswitch == 2))
			{
				Handle data;
				data = CreateDataPack();
				WritePackCell(data, client);
				WritePackCell(data, weapon);
				CreateTimer(0.1,resetinst,data);
			}
		}
	}
	return Plugin_Continue;
}

public Action resetinst(Handle timer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int weap = ReadPackCell(data);
	CloseHandle(data);
	if ((IsValidEntity(weap)) && (IsValidEntity(client)) && (HasEntProp(weap,Prop_Send,"m_flNextPrimaryAttack")))
	{
		float curtime = GetGameTime();
		SetEntPropFloat(weap,Prop_Send,"m_flNextPrimaryAttack",curtime,0);
		SetEntPropFloat(weap,Prop_Send,"m_flNextSecondaryAttack",curtime,0);
		int viewmdl = GetEntPropEnt(client,Prop_Send,"m_hViewModel");
		if (IsValidEntity(viewmdl))
			SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
		SetEntPropFloat(client,Prop_Send,"m_flNextAttack",curtime);
	}
}

bool findtargn(char[] targn)
{
	if (strlen(targn) < 1) return false;
	float Time = GetTickedTime();
	if (entrefresh <= Time)
	{
		ClearArray(entlist);
		entrefresh = Time + 10.0;
	}
	int found,lastfound;
	if (GetArraySize(entlist) < 1)
	{
		for (int i = 1; i<GetMaxEntities(); i++)
		{
			if (IsValidEntity(i) && IsEntNetworkable(i))
			{
				char clsname[32];
				GetEntityClassname(i,clsname,sizeof(clsname));
				if ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"monster_",false) != -1) || (StrEqual(clsname,"generic_actor",false)) || (StrEqual(clsname,"generic_monster",false)))
				{
					PushArrayCell(entlist,i);
					char ename[128];
					GetEntPropString(i,Prop_Data,"m_iName",ename,sizeof(ename));
					if (StrEqual(ename,targn,false))
					{
						found++;
						lastfound = i;
					}
				}
			}
		}
	}
	else
	{
		for (int jtmp = 0; jtmp<GetArraySize(entlist); jtmp++)
		{
			int i = GetArrayCell(entlist, jtmp);
			if (IsValidEntity(i) && IsEntNetworkable(i))
			{
				char clsname[32];
				GetEntityClassname(i,clsname,sizeof(clsname));
				if ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"monster_",false) != -1) || (StrEqual(clsname,"generic_actor",false)) || (StrEqual(clsname,"generic_monster",false)))
				{
					char ename[128];
					GetEntPropString(i,Prop_Data,"m_iName",ename,sizeof(ename));
					if (StrEqual(ename,targn,false))
					{
						found++;
						lastfound = i;
					}
				}
			}
		}
	}
	if (found == 1)
		return true;
	else if (found > 1)
	{
		AcceptEntityInput(lastfound,"kill");
		return true;
	}
	return false;
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
		if ((bdisabled == 0) || (strlen(targn) < 2))
			PushArrayCell(equiparr,thisent);
		findent(thisent++,clsname);
	}
}

void findentlist(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		if ((StrEqual(clsname,"npc_template_maker",false)) || (StrEqual(clsname,"npc_maker",false)))
		{
			int maxnpc = GetEntProp(thisent,Prop_Data,"m_nMaxNumNPCs");
			char rescls[32];
			if (HasEntProp(thisent,Prop_Data,"m_iszNPCClassname")) GetEntPropString(thisent,Prop_Data,"m_iszNPCClassname",rescls,sizeof(rescls));
			if ((restrictact) && ((StrEqual(rescls,"npc_vortigaunt",false)) || (StrEqual(rescls,"npc_helicopter",false)) || (StrEqual(rescls,"npc_combinegunship",false))))
			{
				SetVariantInt(1);
				AcceptEntityInput(thisent,"SetMaxChildren");
			}
			else if ((maxnpc > spawneramt) && (restrictact))
			{
				if (debuglvl >= 1) PrintToServer("%i has %i max npcs resetting to %i",thisent,maxnpc,spawneramt);
				SetVariantInt(spawneramt);
				AcceptEntityInput(thisent,"SetMaxChildren");
			}
		}
		if (FindValueInArray(entlist,thisent) == -1)
			PushArrayCell(entlist,thisent);
		findentlist(thisent++,clsname);
	}
}

int g_LastButtons[MAXPLAYERS+1];

public void OnClientDisconnect_Post(int client)
{
	g_LastButtons[client] = 0;
	clrocket[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_ATTACK2) {
		if (!(g_LastButtons[client] & IN_ATTACK2)) {
			OnButtonPress(client,IN_ATTACK2);
		}
	}
	else if (buttons & IN_USE) {
		if (!(g_LastButtons[client] & IN_USE)) {
			OnButtonPressUse(client);
		}
	}
	if (impulse == 100)
	{
		int vehicles = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
		if ((vehicles > MaxClients) && (IsValidEntity(vehicles)))
		{
			int driver = GetEntProp(client,Prop_Data,"m_iHideHUD");
			int running = 1;
			if (HasEntProp(vehicles,Prop_Data,"m_bIsOn")) running = GetEntProp(vehicles,Prop_Data,"m_bIsOn");
			if ((driver == 3328) && (running))
			{
				char clsname[32];
				GetEntityClassname(vehicles,clsname,sizeof(clsname));
				if ((StrEqual(clsname,"prop_vehicle_jeep",false)) || (StrEqual(clsname,"prop_vehicle_mp",false)))
				{
					if (HasEntProp(vehicles,Prop_Data,"m_bHeadlightIsOn"))
					{
						if (GetEntProp(vehicles,Prop_Data,"m_bHeadlightIsOn")) SetEntProp(vehicles,Prop_Data,"m_bHeadlightIsOn",0);
						else SetEntProp(vehicles,Prop_Data,"m_bHeadlightIsOn",1);
						EmitSoundToAll("items/flashlight1.wav", vehicles, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
			}
		}
	}
	g_LastButtons[client] = buttons;
}

public void OnButtonPress(int client, int button)
{
	if (allownoguide)
	{
		char curweap[24];
		GetClientWeapon(client,curweap,sizeof(curweap));
		int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
		if ((StrEqual(curweap,"weapon_rpg",false)) && (vehicle == -1))
		{
			if (guiderocket[client])
			{
				guiderocket[client] = false;
				PrintToChat(client,"Turned off rocket guide.");
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				SetEntProp(weap,Prop_Send,"m_bGuiding",0);
				SetEntProp(weap,Prop_Data,"m_bInReload",0);
				SetEntProp(weap,Prop_Data,"m_nSequence",2);
			}
			else
			{
				guiderocket[client] = true;
				PrintToChat(client,"Turned on rocket guide.");
			}
			findrockets(-1,client);
		}
	}
}

public void OnButtonPressUse(int client)
{
	if (IsValidEntity(client))
	{
		int targ = GetClientAimTarget(client,false);
		if ((IsValidEntity(targ)) && (targ != 0))
		{
			float orgs[3];
			float targorgs[3];
			if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
			if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",targorgs);
			else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",targorgs);
			float chkdist = GetVectorDistance(orgs,targorgs,false);
			char cls[32];
			GetEntityClassname(targ,cls,sizeof(cls));
			if ((StrEqual(cls,"npc_tripmine",false)) && (chkdist < 91.0))
			{
				if (HasEntProp(targ,Prop_Data,"m_hOwner"))
				{
					if (client == GetEntPropEnt(targ,Prop_Data,"m_hOwner"))
					{
						Handle beamarr = CreateArray(256);
						FindAllByClassname(beamarr,-1,"beam");
						if (GetArraySize(beamarr) > 0)
						{
							for (int i = 0;i<GetArraySize(beamarr);i++)
							{
								int beam = GetArrayCell(beamarr,i);
								if (IsValidEntity(beam))
								{
									if (HasEntProp(beam,Prop_Data,"m_hEndEntity"))
									{
										int endent = GetEntPropEnt(beam,Prop_Data,"m_hEndEntity");
										if (endent == targ)
										{
											AcceptEntityInput(beam,"kill");
											break;
										}
									}
								}
							}
						}
						CloseHandle(beamarr);
						int curamm = GetEntProp(client,Prop_Send,"m_iAmmo",_,24);
						curamm++;
						AcceptEntityInput(targ,"kill");
						SetEntProp(client,Prop_Data,"m_iAmmo",curamm,_,24);
						//plays on same channel as USE EmitGameSoundToAll("HL2Player.PickupWeapon",client);
						int sndlvl,pitch,channel;
						float vol;
						char snd[64];
						if (GetGameSoundParams("HL2Player.PickupWeapon",channel,sndlvl,vol,pitch,snd,sizeof(snd),client))
						{
							EmitSoundToAll(snd, client, SNDCHAN_AUTO, sndlvl, _, vol, pitch);
						}
					}
				}
			}
		}
	}
}

void findrockets(int ent, int client)
{
	int thisent = FindEntityByClassname(ent,"rpg_missile");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		int owner = GetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity");
		if ((owner == client) || (thisent == clrocket[client]))
		{
			if (guiderocket[client])
				SetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity",client);
			else
				SetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity",0);
			clrocket[client] = thisent;
		}
		findrockets(thisent++,client);
	}
	return;
}

public int Native_GetCustomEntList(Handle plugin, int numParams)
{
	return view_as<int>(INVALID_HANDLE);
	//return _:customentlist;
}

public int Native_ReadCache(Handle plugin, int numParams)
{
	if ((numParams < 3) || (numParams > 3))
	{
		PrintToServer("Error: SynFixesReadCache must have three parameters. <client> <pathtocache> <spawnoffset>");
		return 0;
	}
	return 0;
}

public int Native_AddToInputHooks(Handle plugin, int numParams)
{
	if (numParams < 1) return;
	char inputname[64];
	GetNativeString(1,inputname,sizeof(inputname));
	if (strlen(inputname) > 0)
	{
		if (addedinputs == INVALID_HANDLE) addedinputs = CreateArray(64);
		if (GetArraySize(addedinputs) > 0)
		{
			if (FindStringInArray(addedinputs,inputname) == -1) PushArrayString(addedinputs,inputname);
		}
		else
		{
			PushArrayString(addedinputs,inputname);
		}
	}
	return;
}

public void pushch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		int jstat = FindEntityByClassname(MaxClients+1,"prop_vehicle_jeep");
		int jspawn = FindEntityByClassname(MaxClients+1,"info_vehicle_spawn");
		if ((jstat != -1) || (jspawn != -1))
		{
			Handle cvarchk = FindConVar("sv_player_push");
			if (cvarchk != INVALID_HANDLE)
			{
				if (GetConVarInt(cvarchk) == 1)
				{
					if (debuglvl == 3) PrintToServer("Vehicle map was detected, for best experience, sv_player_push will be set to 0");
					int cvarflag = GetCommandFlags("sv_player_push");
					SetCommandFlags("sv_player_push", (cvarflag & ~FCVAR_REPLICATED));
					SetCommandFlags("sv_player_push", (cvarflag & ~FCVAR_NOTIFY));
					SetConVarInt(cvarchk,0,false,false);
				}
			}
			CloseHandle(cvarchk);
		}
	}
}

public void ffhch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) friendlyfire = true;
	else friendlyfire = false;
}

public void instphych(Handle convar, const char[] oldValue, const char[] newValue)
{
	instswitch = StringToInt(newValue);
}

public void forcehdrch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) forcehdr = true;
	else forcehdr = false;
}

public void removertimerch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToFloat(newValue) > 0.0)
		removertimer = StringToFloat(newValue);
	else
		removertimer = 30.0;
}

public void restrictpercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public void restrictvotech(Handle convar, const char[] oldValue, const char[] newValue)
{
	delaylimit = StringToFloat(newValue);
}

public void spawneramtch(Handle convar, const char[] oldValue, const char[] newValue)
{
	spawneramt = StringToInt(newValue);
}

public void spawneramtresch(Handle convar, const char[] oldValue, const char[] newValue)
{
	restrictmode = StringToInt(newValue);
	if (restrictmode == 0)
		restrictact = false;
	else if (restrictmode == 1)
	{
		char maploc[64];
		GetCurrentMap(maploc,sizeof(maploc));
		if ((StrContains(maploc,"js_",false) != -1) || (StrContains(maploc,"coop_",false)))
			restrictact = true;
		else
			restrictact = false;
	}
	else if (restrictmode == 2)
	{
		restrictact = true;
		if (GetArraySize(entlist) > 0)
		{
			for (int i = 0;i<GetArraySize(entlist);i++)
			{
				int entl = GetArrayCell(entlist,i);
				char clsname[32];
				GetEntityClassname(entl,clsname,sizeof(clsname));
				if ((StrEqual(clsname,"npc_template_maker",false)) || (StrEqual(clsname,"npc_maker",false)))
				{
					int maxnpc = GetEntProp(entl,Prop_Data,"m_nMaxNumNPCs");
					if (maxnpc > spawneramt)
					{
						if (debuglvl == 1) PrintToServer("%i has %i max npcs resetting to %i",entl,maxnpc,spawneramt);
						SetVariantInt(spawneramt);
						AcceptEntityInput(entl,"SetMaxChildren");
					}
				}
			}
		}
	}
}

public void plytrigch(Handle convar, const char[] oldValue, const char[] newValue)
{
	playercapadj = StringToInt(newValue);
}

public void blckexch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0) bBlockEx = true;
	else bBlockEx = false;
}

public void sfixrebindch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0) bFixRebind = true;
	else bFixRebind = false;
}

public void trainblckch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		TrainBlockFix = true;
	else
		TrainBlockFix = false;
}

public void groundstuckch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		GroundStuckFix = true;
	else
		GroundStuckFix = false;
}

public void antikillch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		BlockChoreoSuicide = true;
	else
		BlockChoreoSuicide = false;
}

public void blocktripmindmgech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		BlockTripMineDamage = true;
	else
		BlockTripMineDamage = false;
}

public void noguidech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) allownoguide = true;
	else
	{
		allownoguide = false;
		for (int i = 1;i<MaxClients+1;i++)
		{
			guiderocket[i] = true;
		}
	}
}

public bool TraceEntityFilterPly(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		if (IsValidEntity(data))
		{
			if (HasEntProp(data,Prop_Data,"m_hParent"))
			{
				int parent = GetEntPropEnt(data,Prop_Data,"m_hParent");
				if (entity == parent) return false;
			}
		}
		if ((entity < MaxClients+1) && (entity > 0)) return false;
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if ((StrEqual(clsname,"func_vehicleclip",false)) || (StrEqual(clsname,"npc_sentry_ceiling",false)) || (entity == data))
			return false;
	}
	return true;
}