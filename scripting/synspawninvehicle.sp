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

int debuglvl = 0;
int debugoowlvl = 0;
int collisiongroup = -1;
char mapbuf[64];
Handle equiparr = INVALID_HANDLE;
Handle entlist = INVALID_HANDLE;
Handle entnames = INVALID_HANDLE;
Handle physboxarr = INVALID_HANDLE;
Handle physboxharr = INVALID_HANDLE;
Handle elevlist = INVALID_HANDLE;
Handle inputsarrorigincls = INVALID_HANDLE;
Handle hounds = INVALID_HANDLE;
Handle houndsmdl = INVALID_HANDLE;
Handle squids = INVALID_HANDLE;
Handle squidsmdl = INVALID_HANDLE;
Handle tents = INVALID_HANDLE;
Handle tentsmdl = INVALID_HANDLE;
Handle tentssnd = INVALID_HANDLE;
Handle grenlist = INVALID_HANDLE;
Handle tripmines = INVALID_HANDLE;
Handle templateslist = INVALID_HANDLE;
Handle templatetargs = INVALID_HANDLE;
Handle templateents = INVALID_HANDLE;
Handle conveyors = INVALID_HANDLE;
Handle d_li = INVALID_HANDLE;
Handle d_ht = INVALID_HANDLE;
Handle customrelations = INVALID_HANDLE;
Handle restorecustoments = INVALID_HANDLE;
Handle ignoretrigs = INVALID_HANDLE;
Handle spawnerswait = INVALID_HANDLE;
Handle precachedarr = INVALID_HANDLE;
Handle customentlist = INVALID_HANDLE;
float entrefresh = 0.0;
float removertimer = 30.0;
float centnextatk[2048];
float centlastposchk[2048];
float centlastang[2048];
float lastseen[2048];
int WeapList = -1;
int spawneramt = 20;
int restrictmode = 0;
int clrocket[65];
int mdlus = -1;
int mdlus3 = -1;
int isattacking[2048];
int timesattacked[2048];
int matmod = -1;
int tripminefilter = -1;
int autorebuild = 0;
int slavezap = 10;
bool rebuildnodes = false;
bool guiderocket[65];
bool restrictact = false;
bool friendlyfire = false;
bool seqenablecheck = true;
bool instswitch = true;
bool forcehdr = false;
bool mapchoosercheck = false;
//bool linact = false;
bool syn56act = false;
bool vehiclemaphook = false;
bool playerteleports = false;
bool hasread = false;
bool reloadaftersetup = false;
bool customents = false;
bool customspawners = false;
bool relsetvort = false;
bool relsetzsec = false;
bool relsethound = false;
bool relsetabram = false;
bool relsetsci = false;
bool weapmanagersplaced = false;
bool mapchanging = false;

#define PLUGIN_VERSION "1.95"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synfixesupdater.txt"

Menu g_hVoteMenu = null;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

enum voteType
{
	question
}

new voteType:g_voteType = voteType:question;

public Plugin:myinfo =
{
	name = "SynFixes",
	author = "Balimbanana",
	description = "Attempts to fix sequences by checking for missing actors, entities that have fallen out of the world, players not spawning with weapons, and vehicle pulling from side to side.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

float perclimit = 0.66;
float delaylimit = 66.0;
float votetime[64];
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
	dbgoh = CreateConVar("oowdbg", "0", "Set debug level of out of world checks.", _, true, 0.0, true, 1.0);
	HookConVarChange(dbgh, dbghch);
	HookConVarChange(dbgallowh, dbgallowhch);
	HookConVarChange(dbgoh, dbghoch);
	debuglvl = GetConVarInt(dbgh);
	seqenablecheck = GetConVarBool(dbgallowh);
	debugoowlvl = GetConVarInt(dbgoh);
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
	Handle instphyswitch = CreateConVar("sm_instantswitch", "1", "Allow instant weapon switch for physcannon.", _, true, 0.0, true, 1.0);
	instswitch = GetConVarBool(instphyswitch);
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
	CreateTimer(60.0,resetrot,_,TIMER_REPEAT);
	//if ((FileExists("addons/metamod/bin/server.so",false,NULL_STRING)) && (FileExists("addons/metamod/bin/metamod.2.sdk2013.so",false,NULL_STRING))) linact = true;
	//else linact = false;
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	equiparr = CreateArray(32);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	entlist = CreateArray(1024);
	entnames = CreateArray(128);
	physboxarr = CreateArray(64);
	physboxharr = CreateArray(64);
	elevlist = CreateArray(64);
	hounds = CreateArray(128);
	houndsmdl = CreateArray(128);
	squids = CreateArray(128);
	squidsmdl = CreateArray(128);
	tents = CreateArray(128);
	tentsmdl = CreateArray(128);
	tentssnd = CreateArray(128);
	grenlist = CreateArray(256);
	tripmines = CreateArray(256);
	templateslist = CreateArray(256);
	templatetargs = CreateArray(256);
	templateents = CreateArray(256);
	d_li = CreateArray(128);
	d_ht = CreateArray(128);
	customrelations = CreateArray(128);
	ignoretrigs = CreateArray(1024);
	spawnerswait = CreateArray(256);
	precachedarr = CreateArray(32);
	customentlist = CreateArray(128);
	conveyors = CreateArray(128);
	restorecustoments = CreateArray(256);
	inputsarrorigincls = CreateArray(768);
	RegConsoleCmd("alyx",fixalyx);
	RegConsoleCmd("barney",fixbarney);
	RegConsoleCmd("stuck",stuckblck);
	RegConsoleCmd("propaccuracy",setpropaccuracy);
	RegConsoleCmd("con",enablecon);
	RegConsoleCmd("npc_freeze",admblock);
	RegConsoleCmd("npc_freeze_unselected",admblock);
	RegConsoleCmd("changelevel",resetgraphs);
	Handle autorebuildh = CreateConVar("rebuildents","0","Set auto rebuild of custom entities, 1 is dynamic, 2 is static npc list.",_,true,0.0,true,2.0);
	autorebuild = GetConVarInt(autorebuildh);
	HookConVarChange(autorebuildh,autorebuildch);
	CloseHandle(autorebuildh);
	Handle rebuildnodesh = CreateConVar("rebuildnodes","0","Set force rebuild ai nodes on every map (not nav_generate).",_,true,0.0,true,1.0);
	rebuildnodes = GetConVarBool(rebuildnodesh);
	HookConVarChange(rebuildnodesh,rebuildnodeshch);
	CloseHandle(rebuildnodesh);
	RegAdminCmd("sm_rebuildents",rebuildents,ADMFLAG_ROOT,".");
	CreateTimer(10.0,dropshipchk,_,TIMER_REPEAT);
	AutoExecConfig(true, "synfixes");
	CreateTimer(0.1,bmcvars);
}

public Action bmcvars(Handle timer)
{
	Handle cvarchk = FindConVar("synfixes_houndtint");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("synfixes_houndtint","1","Sets whether or not to use houndeye tint effect when charging.",_,true,0.0,true,1.0);
	cvarchk = FindConVar("sk_human_security_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_security_health","40","Human Security health.",_,true,1.0,false);
	cvarchk = FindConVar("sk_human_commander_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_commander_health","50","Human Commander health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_human_grunt_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_grunt_health","50","Human Grunt health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_human_medic_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_medic_health","50","Human Medic health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_zombie_scientist_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_zombie_scientist_health","40","Zombie Scientist health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_zombie_security_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_zombie_security_health","50","Zombie Security health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_alien_slave_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_alien_slave_health","38","Alien Slave health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_bullsquid_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_bullsquid_health","60",".",_,true,0.0,false);
	cvarchk = FindConVar("sk_alien_grunt_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_alien_grunt_health","90",".",_,true,0.0,false);
	cvarchk = FindConVar("sk_controller_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_controller_health","60","Alien Controller health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_human_assassin_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_assassin_health","50","Human Assassin health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_sentry_ceiling_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_sentry_ceiling_health","50","Ceiling Sentry health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_apache_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_apache_health","2000","Apache health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_houndeye_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_houndeye_health","50","Houndeye health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_osprey_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_osprey_health","300","Osprey health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_alien_slave_dmg_zap");
	if (cvarchk == INVALID_HANDLE)
	{
		cvarchk = CreateConVar("sk_alien_slave_dmg_zap","10","Alien Slave zap damage.",_,true,0.0,false);
		slavezap = 10;
	}
	else
	{
		slavezap = GetConVarInt(cvarchk);
	}
	HookConVarChange(cvarchk,vortzapch);
	CloseHandle(cvarchk);
	return Plugin_Handled;
}

public void OnMapStart()
{
	mapchanging = false;
	customents = false;
	if (reloadaftersetup)
	{
		reloadaftersetup = false;
		Handle nullpl = INVALID_HANDLE;
		ReloadPlugin(nullpl);
	}
	int rellogsv = CreateEntityByName("logic_auto");
	if ((rellogsv != -1) && (IsValidEntity(rellogsv)))
	{
		DispatchKeyValue(rellogsv,"targetname","syn_logicauto");
		DispatchKeyValue(rellogsv,"spawnflags","0");
		DispatchSpawn(rellogsv);
		ActivateEntity(rellogsv);
		HookEntityOutput("logic_auto","OnMapSpawn",EntityOutput:onreload);
	}
	hasread = false;
	playerteleports = false;
	customspawners = false;
	relsetvort = false;
	relsetzsec = false;
	relsethound = false;
	relsetabram = false;
	relsetsci = false;
	weapmanagersplaced = false;
	mdlus = PrecacheModel("sprites/blueglow2.vmt");
	mdlus3 = PrecacheModel("effects/strider_bulge_dudv.vmt");
	entrefresh = 0.0;
	matmod = -1;
	tripminefilter = -1;
	ClearArray(entlist);
	ClearArray(equiparr);
	ClearArray(entnames);
	ClearArray(physboxarr);
	ClearArray(physboxharr);
	ClearArray(elevlist);
	ClearArray(inputsarrorigincls);
	ClearArray(restorecustoments);
	ClearArray(hounds);
	ClearArray(houndsmdl);
	ClearArray(squids);
	ClearArray(squidsmdl);
	ClearArray(tents);
	ClearArray(tentsmdl);
	ClearArray(tentssnd);
	ClearArray(grenlist);
	ClearArray(tripmines);
	ClearArray(templateslist);
	ClearArray(templatetargs);
	ClearArray(templateents);
	ClearArray(d_li);
	ClearArray(d_ht);
	ClearArray(customrelations);
	ClearArray(ignoretrigs);
	ClearArray(spawnerswait);
	ClearArray(precachedarr);
	ClearArray(conveyors);
	for (int i = 1;i<MaxClients+1;i++)
	{
		guiderocket[i] = true;
		PushArrayCell(entlist,i);
	}
	for (int i = 1;i<2048;i++)
	{
		timesattacked[i] = 0;
		isattacking[i] = 0;
	}
	char gamedescoriginal[24];
	GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
	GetCurrentMap(mapbuf,sizeof(mapbuf));
	bool rebuildentsset = false;
	if (StrEqual(gamedescoriginal,"synergy 56.16",false))
	{
		syn56act = true;
		if (StrContains(mapbuf,"bm_c",false) != -1) rebuildentsset = true;
	}
	else syn56act = false;
	if (restrictmode == 1)
	{
		if ((StrContains(mapbuf,"js_",false) != -1) || (StrContains(mapbuf,"coop_",false)))
			restrictact = true;
		else
			restrictact = false;
	}
	if (((StrEqual(mapbuf,"d1_canals_13",false)) || (StrEqual(mapbuf,"d1_canals_11",false))) && (syn56act))
	{
		int skycam = FindEntityByClassname(-1,"sky_camera");
		if (skycam != -1) AcceptEntityInput(skycam,"kill");
	}
	if ((StrContains(mapbuf,"d1_",false) == -1) && (StrContains(mapbuf,"d2_",false) == -1) && (!StrEqual(mapbuf,"d3_breen_01",false)) && (StrContains(mapbuf,"ep1_",false) == -1))
	{
		HookEntityOutput("scripted_sequence","OnBeginSequence",EntityOutput:trigout);
		HookEntityOutput("scripted_scene","OnStart",EntityOutput:trigout);
		HookEntityOutput("logic_choreographed_scene","OnStart",EntityOutput:trigout);
		HookEntityOutput("instanced_scripted_scene","OnStart",EntityOutput:trigout);
		if (StrContains(mapbuf,"bm_c",false) == -1)
			HookEntityOutput("func_tracktrain","OnStart",EntityOutput:elevatorstart);
		HookEntityOutput("func_door","OnOpen",EntityOutput:createelev);
		HookEntityOutput("func_door","OnClose",EntityOutput:createelev);
	}
	HookEntityOutput("trigger_changelevel","OnChangeLevel",EntityOutput:mapendchg);
	HookEntityOutput("func_physbox","OnPhysGunPunt",EntityOutput:physpunt);
	Format(mapbuf,sizeof(mapbuf),"%s.ent",mapbuf);
	Handle mdirlisting = OpenDirectory("maps/ent_cache", false);
	if (mdirlisting != INVALID_HANDLE)
	{
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
	}
	CloseHandle(mdirlisting);
	
	CreateTimer(0.1,rehooksaves);
	
	collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			CreateTimer(1.0,clspawnpost,i);
		}
	}
	findstraymdl(-1,"prop_dynamic");
	findstraymdl(-1,"point_template");
	findstraymdl(-1,"npc_zombie_scientist");
	findstraymdl(-1,"npc_zombie_security");
	findstraymdl(-1,"game_weapon_manager");
	findstraymdl(-1,"item_healthkit");
	findstraymdl(-1,"item_battery");
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
			if (((StrEqual(clsname,"npc_citizen",false)) || (StrEqual(clsname,"npc_alyx",false))) && (!(StrContains(mapbuf,"cd",false) == 0))) SDKHook(jtmp, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	ClearArray(customentlist);
	PushArrayString(customentlist,"trigger_auto");
	PushArrayString(customentlist,"npc_sentry_ground");
	PushArrayString(customentlist,"env_xen_portal");
	PushArrayString(customentlist,"env_xen_portal_template");
	PushArrayString(customentlist,"npc_human_security");
	PushArrayString(customentlist,"npc_human_scientist");
	PushArrayString(customentlist,"npc_human_scientist_female");
	PushArrayString(customentlist,"npc_human_scientist_eli");
	PushArrayString(customentlist,"npc_human_scientist_kleiner");
	PushArrayString(customentlist,"npc_alien_slave");
	PushArrayString(customentlist,"npc_zombie_security");
	PushArrayString(customentlist,"npc_zombie_security_torso");
	PushArrayString(customentlist,"npc_zombie_scientist");
	PushArrayString(customentlist,"npc_zombie_scientist_torso");
	PushArrayString(customentlist,"npc_human_grunt");
	PushArrayString(customentlist,"npc_human_commander");
	PushArrayString(customentlist,"npc_human_grenadier");
	PushArrayString(customentlist,"npc_human_medic");
	PushArrayString(customentlist,"npc_osprey");
	PushArrayString(customentlist,"npc_houndeye");
	PushArrayString(customentlist,"npc_bullsquid");
	PushArrayString(customentlist,"npc_sentry_ceiling");
	PushArrayString(customentlist,"npc_tentacle");
	PushArrayString(customentlist,"prop_train_awesome");
	PushArrayString(customentlist,"prop_train_apprehension");
	PushArrayString(customentlist," item_ammo_smg1_grenade");
	PushArrayString(customentlist,"item_weapon_tripmine");
	PushArrayString(customentlist,"item_weapon_satchel");
	PushArrayString(customentlist,"item_grenade_rpg");
	PushArrayString(customentlist,"item_weapon_rpg");
	PushArrayString(customentlist,"item_weapon_crossbow");
	PushArrayString(customentlist,"multi_manager");
	PushArrayString(customentlist,"npc_alien_grunt");
	PushArrayString(customentlist,"npc_alien_grunt_unarmored");
	PushArrayString(customentlist,"npc_snark");
	PushArrayString(customentlist,"npc_abrams");
	PushArrayString(customentlist,"npc_apache");
	PushArrayString(customentlist,"grenade_tripmine");
	PushArrayString(customentlist,"item_crate");
	PushArrayString(customentlist,"trigger_lift");
	PushArrayString(customentlist,"func_conveyor");
	PushArrayString(customentlist,"func_minefield");
	PushArrayString(customentlist,"func_50cal");
	PushArrayString(customentlist,"func_tow");
	if ((rebuildentsset) && (!customents))
	{
		findstraymdl(-1,"npc_template_maker");
		findstraymdl(-1,"env_xen_portal_template");
		findstraymdl(-1,"func_conveyor");
		readcache(0,mapbuf);
		char mapspec[128];
		GetCurrentMap(mapspec,sizeof(mapspec));
		ReplaceString(mapspec,sizeof(mapspec),"bm_","sound/vo/");
		if (StrEqual(mapspec,"sound/vo/c1a1c",false)) recursion("sound/BMS_scripted/uc/");
		if (StrEqual(mapspec,"sound/vo/c1a2b",false)) recursion("sound/vo/c1a2a");
		if (StrEqual(mapspec,"sound/vo/c1a2c",false)) recursion("sound/vo/c1a2b");
		if (StrEqual(mapspec,"sound/vo/c2a1a",false)) recursion("sound/vo/c2a2a");
		if (StrEqual(mapspec,"sound/vo/c2a4f",false)) recursion("sound/vo/c1a3a");
		if (StrEqual(mapspec,"sound/vo/c2a4g",false)) recursion("sound/vo/c2a4f");
		if (StrEqual(mapspec,"sound/vo/c3a2b",false)) recursion("sound/vo/c3a2a");
		if (StrEqual(mapspec,"sound/vo/c3a2c",false)) recursion("sound/vo/c3a2b");
		if (StrEqual(mapspec,"sound/vo/c3a2g",false)) recursion("sound/vo/c3a2d");
		if (StrEqual(mapspec,"sound/vo/c3a2h",false))
		{
			recursion("sound/vo/c3a2e");
			recursion("sound/BMS_objects/clickbeep");
		}
		recursion(mapspec);
		Format(mapspec,sizeof(mapspec),"sound/npc/zombie/");
		recursion(mapspec);
		resetchargers(-1,"item_healthcharger");
		resetchargers(-1,"item_suitcharger");
		resetspawners(-1,"npc_maker");
		resetspawners(-1,"env_xen_portal");
	}
	else if (autorebuild == 1)
	{
		readcacheexperimental(0);
		resetspawners(-1,"npc_maker");
		resetspawners(-1,"env_xen_portal");
	}
	else if (autorebuild == 2)
	{
		readcache(0,mapbuf);
		resetspawners(-1,"npc_maker");
		resetspawners(-1,"env_xen_portal");
	}
	else if (customents)
	{
		resetspawners(-1,"npc_maker");
		resetspawners(-1,"env_xen_portal");
	}
	int nullfil = CreateEntityByName("filter_activator_class");
	if (nullfil != -1)
	{
		DispatchKeyValue(nullfil,"targetname","nullfil");
		DispatchKeyValue(nullfil,"Negated","0");
		DispatchSpawn(nullfil);
		ActivateEntity(nullfil);
	}
	if (syn56act)
	{
		HookEntityOutput("scripted_sequence","OnCancelSequence",EntityOutput:custentend);
		HookEntityOutput("npc_maker","OnSpawnNPC",EntityOutput:onxenspawn);
		HookEntityOutput("env_xen_portal","OnSpawnNPC",EntityOutput:onxenspawn);
		HookEntityOutput("env_xen_portal_template","OnSpawnNPC",EntityOutput:onxenspawn);
	}
	PrecacheSound("npc\\roller\\code2.wav",true);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if ((StrEqual(sArgs,"stuck",false)) || (StrEqual(sArgs,"unstuck",false)) || (StrEqual(sArgs,"!stuck",false)) || (StrEqual(sArgs,"!unstuck",false)))
	{
		ClientCommand(client,"stuck");
	}
}

public OnLibraryAdded(const char[] name)
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

public Updater_OnPluginUpdated()
{
	if (customents)
	{
		reloadaftersetup = true;
	}
	else
	{
		Handle nullpl = INVALID_HANDLE;
		ReloadPlugin(nullpl);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	RegPluginLibrary("SynFixes");
	CreateNative("GetCustomEntList", Native_GetCustomEntList);
	CreateNative("SynFixesReadCache", Native_ReadCache);
	MarkNativeAsOptional("GetCustomEntList");
	MarkNativeAsOptional("SynFixesReadCache");
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
	if ((StrEqual(tmpmap,"ep2_outland_12",false)) || (StrEqual(tmpmap,"ep2_outland_11b",false)) || (StrEqual(tmpmap,"ep2_outland_02",false))) return Plugin_Handled;
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
	if ((client == 0) || (!IsPlayerAlive(client))) return Plugin_Handled;
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

public MenuHandler(Menu menu, MenuAction action, int param1, int param2)
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
			g_voteType = voteType:question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
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
			g_voteType = voteType:question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
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

public Handler_VoteCallback(Menu menu, MenuAction action, param1, param2)
{
	if (action == MenuAction_End)
	{
		return 0;
	}
	else if (action == MenuAction_Display)
	{
	 	if (g_voteType != voteType:question)
	 	{
			char title[64];
			menu.GetTitle(title, sizeof(title));
			
	 		char buffer[255];
			Format(buffer, sizeof(buffer), "%s", param1);

			Panel panel = Panel:param2;
			panel.SetTitle(buffer);
		}
	}
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			decl String:buffer[255];
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
		percent = FloatDiv(float(votes),float(totalVotes));
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

public OnClientPutInServer(int client)
{
	CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	if (forcehdr) QueryClientConVar(client,"mat_hdr_level",hdrchk,0);
}

public Action clspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		float clorigin[3], vMins[3], vMaxs[3];
		GetClientAbsOrigin(client,clorigin);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
		if (debugoowlvl)
		{
			PrintToServer("%N spawned in at %1.f %1.f %1.f\nWorldMins: %1.f %1.f %1.f\nWorldMaxs %1.f %1.f %1.f",client,clorigin[0],clorigin[1],clorigin[2],vMins[0],vMins[1],vMins[2],vMaxs[0],vMaxs[1],vMaxs[2]);
		}
		if (StrContains(mapbuf,"bm_c2a5c",false) == -1)
		{
			if ((clorigin[0] < vMins[0]) || (clorigin[1] < vMins[1]) || (clorigin[2] < vMins[2]) || (clorigin[0] > vMaxs[0]) || (clorigin[1] > vMaxs[1]) || (clorigin[2] > vMaxs[2]) || (TR_PointOutsideWorld(clorigin)))
			{
				if (debugoowlvl) PrintToServer("%N spawned out of map, moving to active checkpoint.",client);
				findspawnpos(client);
			}
		}
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
			if (GetEntProp(client,Prop_Data,"m_bPlayerUnderwater") > 0)
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
		ClientCommand(client,"snd_restart");
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

public dbghch(Handle convar, const char[] oldValue, const char[] newValue)
{
	debuglvl = StringToInt(newValue);
}

public dbghoch(Handle convar, const char[] oldValue, const char[] newValue)
{
	debugoowlvl = StringToInt(newValue);
}

public dbgallowhch(Handle convar, const char[] oldValue, const char[] newValue)
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
			else if ((HasEntProp(i,Prop_Data,"m_vecOrigin")) && (StrContains(clsname,"func_",false) == -1) && (StrContains(clsname,"trigger_",false) == -1) && (StrContains(clsname,"point_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (!StrEqual(clsname,"material_modify_control",false)) && (!StrEqual(clsname,"keyframe_rope",false)) && (!StrEqual(clsname,"move_rope",false)) && (StrContains(clsname,"npc_",false) == -1) && (StrContains(clsname,"monster_",false) == -1) && (StrContains(clsname,"info_",false) == -1) && (StrContains(clsname,"env_",false) == -1) && (StrContains(clsname,"scripted",false) == -1) && (!StrEqual(clsname,"momentary_rot_button",false)) && (!StrEqual(clsname,"syn_transition_wall",false)) && (!StrEqual(clsname,"prop_dynamic",false)) && (StrContains(clsname,"light_",false) == -1))
			{
				float pos[3];
				GetEntPropVector(i,Prop_Data,"m_vecOrigin",pos);
				char fname[32];
				GetEntPropString(i,Prop_Data,"m_iName",fname,sizeof(fname));
				if ((TR_PointOutsideWorld(pos)) && (StrContains(fname,"elevator",false) == -1) && ((pos[0] < vMins[0]) || (pos[1] < vMins[1]) && (pos[2] < vMins[2])) && !(((pos[0] <= 1.0) && (pos[0] >= -1.0)) && ((pos[1] <= 1.0) && (pos[1] >= -1.0)) && ((pos[2] <= 1.0) && (pos[2] >= -1.0))))
				{
					if (debugoowlvl) PrintToServer("%i %s with name %s fell out of world, removing...",i,clsname,fname);
					if (i>MaxClients) AcceptEntityInput(i,"kill");
				}
			}
		}
	}
}

public Action elevatorstart(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		float origin[3];
		GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
		float origin2[3];
		origin2[0]=origin[0];
		origin2[1]=origin[1];
		origin2[2]=origin[2];
		origin[2]-=60.0;
		origin2[2]+=200.0;
		char elevtargn[32];
		GetEntPropString(caller,Prop_Data,"m_iName",elevtargn,sizeof(elevtargn));
		float espeed;
		if (HasEntProp(caller,Prop_Data,"m_flSpeed")) espeed = GetEntPropFloat(caller,Prop_Data,"m_flSpeed");
		if (espeed > 150.0)
		{
			for (int i = MaxClients+1; i<GetMaxEntities(); i++)
			{
				if (IsValidEntity(i) && IsEntNetworkable(i))
				{
					char clsname[32];
					GetEntityClassname(i,clsname,sizeof(clsname));
					if ((StrEqual(clsname,"prop_physics",false)) || (StrEqual(clsname,"prop_ragdoll",false)) || ((StrContains(clsname,"item_",false) != -1) && (!StrEqual(clsname,"item_healthcharger",false)) && (!StrEqual(clsname,"item_suitcharger",false))))
					{
						float proporigin[3];
						GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",proporigin);
						int parentchk = 0;
						if (HasEntProp(i,Prop_Data,"m_hParent"))
							parentchk = GetEntPropEnt(i,Prop_Data,"m_hParent");
						if (parentchk < 1)
						{
							float chkdist = GetVectorDistance(origin,proporigin,false);
							float chkdist2 = GetVectorDistance(origin2,proporigin,false);
							//chk if within bounds of elev
							bool below = true;
							if ((origin[2] < 0) && (origin[2] < proporigin[2])) below = false;
							else if ((origin[2] > -1) && (origin[2] > proporigin[2])) below = false;
							if (((chkdist < 200.0) || (chkdist2 < 200.0)) && (!below))
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
	CreateTimer(0.1,elevatorstartpost,caller);
	//Post check
	CreateTimer(5.0,elevatorstartpost,caller);
}

public Action elevatorstartpost(Handle timer, int elev)
{
	if (IsValidEntity(elev))
	{
		float origin[3];
		GetEntPropVector(elev,Prop_Data,"m_vecAbsOrigin",origin);
		origin[2]+=10.0;
		float origin2[3];
		origin2[0]=origin[0];
		origin2[1]=origin[1];
		origin2[2]=origin[2];
		origin2[2]+=200.0;
		char elevtargn[32];
		GetEntPropString(elev,Prop_Data,"m_iName",elevtargn,sizeof(elevtargn));
		float espeed;
		if (HasEntProp(elev,Prop_Data,"m_flSpeed")) espeed = GetEntPropFloat(elev,Prop_Data,"m_flSpeed");
		if (espeed > 150.0)
		{
			for (int i = MaxClients+1; i<GetMaxEntities(); i++)
			{
				if (IsValidEntity(i) && IsEntNetworkable(i))
				{
					char clsname[32];
					GetEntityClassname(i,clsname,sizeof(clsname));
					if ((StrEqual(clsname,"prop_physics",false)) || (StrEqual(clsname,"prop_ragdoll",false)) || ((StrContains(clsname,"item_",false) != -1) && (!StrEqual(clsname,"item_healthcharger",false)) && (!StrEqual(clsname,"item_suitcharger",false))))
					{
						float proporigin[3];
						GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",proporigin);
						int parentchk = 0;
						if (HasEntProp(i,Prop_Data,"m_hParent"))
							parentchk = GetEntPropEnt(i,Prop_Data,"m_hParent");
						if (parentchk < 1)
						{
							float chkdist = GetVectorDistance(origin,proporigin,false);
							float chkdist2 = GetVectorDistance(origin2,proporigin,false);
							bool below = true;
							if ((origin[2] < 0) && (origin[2] < proporigin[2])) below = false;
							else if ((origin[2] > -1) && (origin[2] > proporigin[2])) below = false;
							if (((chkdist < 200.0) || (chkdist2 < 200.0)) && (!below))
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
			if (rebuildnodes)
			{
				char findnode[128];
				Format(findnode,sizeof(findnode),"maps\\graphs\\%s.ain",maptochange);
				if (FileExists(findnode,false))
				{
					DeleteFile(findnode);
				}
			}
			Handle data;
			data = CreateDataPack();
			WritePackString(data, maptochange);
			WritePackString(data, curmapbuf);
			CreateTimer(1.0,changeleveldelay,data);
			mapchanging = true;
		}
	}
}

public Action resetgraphs(int client, int args)
{
	if ((client == 0) && (args > 0))
	{
		char findnode[128];
		GetCmdArg(1,findnode,sizeof(findnode));
		Format(findnode,sizeof(findnode),"maps\\graphs\\%s.ain",findnode);
		if (FileExists(findnode,false))
		{
			DeleteFile(findnode);
			PrintToServer("Removed ain for %s",findnode);
		}
	}
	return Plugin_Continue;
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
			ServerCommand("changelevel Custom %s",maptochange);
			ServerCommand("changelevel syn %s",maptochange);
		}
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
	int arrindx = FindValueInArray(physboxarr,caller)
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
			if ((HasEntProp(i,Prop_Data,"m_iGlobalname")) && ((StrEqual(clsname,"func_tracktrain",false)) || (StrContains(clsname,"prop_",false) != -1)) && (syn56act))
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

public Action custentend(const char[] output, int caller, int activator, float delay)
{
	if ((customents) && (!mapchanging))
	{
		if (IsValidEntity(caller))
		{
			char targn[32];
			int targent;
			if (HasEntProp(caller,Prop_Data,"m_iszEntity")) GetEntPropString(caller,Prop_Data,"m_iszEntity",targn,sizeof(targn));
			if (strlen(targn) > 0)
			{
				for (int i = 0;i<GetArraySize(entlist);i++)
				{
					char targ2[32];
					int j = GetArrayCell(entlist,i);
					if ((IsValidEntity(j)) && (j != 0) && (j > MaxClients))
					{
						if (HasEntProp(j,Prop_Data,"m_iName")) GetEntPropString(j,Prop_Data,"m_iName",targ2,sizeof(targ2));
						if (StrEqual(targn,targ2,false))
						{
							targent = j;
							break;
						}
					}
				}
			}
			if ((targent != 0) && (IsValidEntity(targent)))
			{
				if (HasEntProp(caller,Prop_Data,"m_fMoveTo"))
				{
					int moveto = GetEntProp(caller,Prop_Data,"m_fMoveTo");
					char entryanim[32];
					char actanim[32];
					char idleanim[32];
					if (HasEntProp(caller,Prop_Data,"m_iszEntry")) GetEntPropString(caller,Prop_Data,"m_iszEntry",entryanim,sizeof(entryanim));
					if (HasEntProp(caller,Prop_Data,"m_iszPlay")) GetEntPropString(caller,Prop_Data,"m_iszPlay",actanim,sizeof(actanim));
					if (HasEntProp(caller,Prop_Data,"m_iszPreIdle")) GetEntPropString(caller,Prop_Data,"m_iszPreIdle",idleanim,sizeof(idleanim));
					if ((moveto != 0) && ((strlen(entryanim) > 0) || (strlen(actanim) > 0) || (strlen(idleanim) > 0)))
					{
						char clschk[32];
						GetEntityClassname(targent,clschk,sizeof(clschk));
						if (StrEqual(clschk,"npc_houndeye",false))
						{
							if (StrEqual(actanim,"houndeye_jump_windowc1a1c",false))
							{
								float origin[3];
								float angs[3];
								float loc[3];
								if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
								if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
								else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
								loc[0] = (origin[0] - (120 * Cosine(DegToRad(angs[1]))));
								loc[1] = (origin[1] + (430 * Sine(DegToRad(angs[1]))));
								loc[2] = (origin[2] - 28);
								angs[1]-=90.0;
								if (debuglvl == 3) PrintToServer("TP scripted seq ent %i %i %s %1.f %1.f %1.f",targent,caller,clschk,origin[0],origin[1],origin[2]);
								TeleportEntity(targent,loc,angs,NULL_VECTOR);
							}
						}
						if ((StrContains(clschk,"npc_human_",false) != -1) && ((HasEntProp(targent,Prop_Data,"m_strHullName")) || (StrEqual(clschk,"npc_human_scientist",false))))
						{
							if (!StrEqual(actanim,"Idle_to_Sit_Office_Chair_behind",false))
							{
								float origin[3];
								float angs[3];
								if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
								if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
								else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
								if (debuglvl == 3) PrintToServer("TP scripted seq ent %i %i %s %1.f %1.f %1.f",targent,caller,clschk,origin[0],origin[1],origin[2]);
								TeleportEntity(targent,origin,angs,NULL_VECTOR);
								Handle dp = CreateDataPack();
								WritePackCell(dp,targent);
								WritePackFloat(dp,origin[0]);
								WritePackFloat(dp,origin[1]);
								WritePackFloat(dp,origin[2]);
								WritePackFloat(dp,angs[0]);
								WritePackFloat(dp,angs[1]);
								WritePackFloat(dp,angs[2]);
								CreateTimer(0.1,retp,dp,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
			}
		}
	}
}

public Action retp(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int ent = ReadPackCell(dp);
		float origin[3];
		float angs[3];
		origin[0] = ReadPackFloat(dp);
		origin[1] = ReadPackFloat(dp);
		origin[2] = ReadPackFloat(dp);
		angs[0] = ReadPackFloat(dp);
		angs[1] = ReadPackFloat(dp);
		angs[2] = ReadPackFloat(dp);
		CloseHandle(dp);
		if ((ent != 0) && (IsValidEntity(ent)))
		{
			TeleportEntity(ent,origin,angs,NULL_VECTOR);
		}
	}
}

public Action onxenspawn(const char[] output, int caller, int activator, float delay)
{
	if (customents)
	{
		if (IsValidEntity(caller))
		{
			char clschk[24];
			GetEntityClassname(caller,clschk,sizeof(clschk));
			if (StrEqual(clschk,"npc_maker",false))
			{
				char spawnname[64];
				GetEntPropString(caller,Prop_Data,"m_ChildTargetName",spawnname,sizeof(spawnname));
				if (StrContains(spawnname,"npc_human_security",false) == 0)
				{
					ReplaceStringEx(spawnname,sizeof(spawnname),"npc_human_security","");
					for (int i = 0;i<GetArraySize(entlist);i++)
					{
						int j = GetArrayCell(entlist,i);
						if (IsValidEntity(j))
						{
							char targn[64];
							if (HasEntProp(j,Prop_Data,"m_iName"))
							{
								GetEntPropString(j,Prop_Data,"m_iName",targn,sizeof(targn));
								if (StrEqual(targn,spawnname))
								{
									if (IsValidEntity(activator))
									{
										GetEntityClassname(activator,clschk,sizeof(clschk));
										if (StrEqual(clschk,"npc_citizen",false))
											AcceptEntityInput(activator,"kill");
									}
									break;
								}
							}
						}
					}
				}
			}
			else
			{
				int dispent = CreateEntityByName("env_sprite");
				if (dispent != -1)
				{
					float origin[3];
					float angs[3];
					if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
					if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
					else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
					DispatchKeyValue(dispent,"model","materials/effects/tele_exit.vmt");
					DispatchKeyValue(dispent,"scale","0.4");
					DispatchKeyValue(dispent,"rendermode","2");
					origin[2]+=25.0;
					TeleportEntity(dispent,origin,angs,NULL_VECTOR);
					DispatchSpawn(dispent);
					ActivateEntity(dispent);
					CreateTimer(0.1,reducescale,dispent,TIMER_FLAG_NO_MAPCHANGE);
				}
				int rand = GetRandomInt(1,3);
				char snd[64];
				Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
				EmitSoundToAll(snd, caller, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				AcceptEntityInput(caller,"FireUser2");
			}
		}
	}
	return Plugin_Continue;
}

public Action reducescale(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		float scale = 1.0;
		if (HasEntProp(entity,Prop_Data,"m_flSpriteScale")) scale = GetEntPropFloat(entity,Prop_Data,"m_flSpriteScale");
		if (scale < 0.01) AcceptEntityInput(entity,"kill");
		else
		{
			scale-=0.05;
			char scalch[8];
			Format(scalch,sizeof(scalch),"%f",scale);
			SetVariantString(scalch);
			AcceptEntityInput(entity,"SetScale");
			CreateTimer(0.1,reducescale,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

public TripMineExpl(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		if (HasEntProp(caller,Prop_Data,"m_iszStartEntity"))
		{
			int tripmine = GetEntPropEnt(caller,Prop_Data,"m_hOwnerEntity");
			if (IsValidEntity(tripmine))
			{
				int parexpl = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
				if ((parexpl != -1) && (IsValidEntity(parexpl))) AcceptEntityInput(parexpl,"Explode");
				AcceptEntityInput(tripmine,"FireUser2");
				AcceptEntityInput(tripmine,"kill");
				AcceptEntityInput(caller,"kill");
			}
			int find = FindValueInArray(tripmines,caller);
			if (find != -1)
				RemoveFromArray(tripmines,find);
		}
	}
}

public Action tripminetkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	int find = FindValueInArray(tripmines,victim);
	if (find != -1)
	{
		int beam = GetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity");
		if ((IsValidEntity(beam)) && (beam != 0))
		{
			AcceptEntityInput(beam,"kill");
			SetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity",-1);
		}
		int expl = GetEntPropEnt(victim,Prop_Data,"m_hEffectEntity");
		if ((IsValidEntity(expl)) && (expl != 0))
		{
			SetEntPropEnt(victim,Prop_Data,"m_hEffectEntity",-1);
			CreateTimer(0.1,tripmineexplode,expl,TIMER_FLAG_NO_MAPCHANGE);
		}
		RemoveFromArray(tripmines,find);
		AcceptEntityInput(victim,"FireUser2");
		SDKUnhook(victim, SDKHook_OnTakeDamage, tripminetkdmg);
		AcceptEntityInput(victim,"kill");
	}
}

public Action tripmineexplode(Handle timer, int expl)
{
	if ((IsValidEntity(expl)) && (expl != 0))
	{
		AcceptEntityInput(expl,"Explode");
	}
}

findpts(char[] targn, float delay)
{
	//PrintToServer("PT search %s %f %i",targn,delay,GetArraySize(templateslist));
	Handle temparr = CreateArray(128);
	for (int j = 0;j<GetArraySize(templateslist);j++)
	{
		int i = GetArrayCell(templateslist,j);
		if (IsValidEntity(i))
		{
			char tmpname[64];
			if (HasEntProp(i,Prop_Data,"m_iName")) GetEntPropString(i,Prop_Data,"m_iName",tmpname,sizeof(tmpname));
			//PrintToServer("Template named %s",tmpname);
			if (StrEqual(tmpname,targn,false))
			{
				PushArrayCell(temparr,i);
			}
		}
	}
	if ((GetArraySize(templatetargs) > 0) && (GetArraySize(temparr) > 0))
	{
		for (int i = 0;i<GetArraySize(temparr);i++)
		{
			int templateent = GetArrayCell(temparr,i);
			char clschk[24];
			GetEntityClassname(templateent,clschk,sizeof(clschk));
			if (StrEqual(clschk,"point_template"))
			{
				char tmpchk[32];
				for (int j = 0;j<16;j++)
				{
					Format(tmpchk,sizeof(tmpchk),"m_iszTemplateEntityNames[%i]",j);
					if (HasEntProp(templateent,Prop_Data,tmpchk))
					{
						char templatename[32];
						GetEntPropString(templateent,Prop_Data,tmpchk,templatename,sizeof(templatename));
						if (strlen(templatename) > 0)
						{
							int find = FindStringInArray(templatetargs,templatename);
							if (find != -1)
							{
								if (debuglvl >= 2) PrintToServer("point_template spawn custom ent %s",templatename);
								Handle dp = GetArrayCell(templateents,find);
								if (delay > 0.01) CreateTimer(delay,restoreentdp,dp,TIMER_FLAG_NO_MAPCHANGE);
								else
								{
									restoreentarr(dp);
									RemoveFromArray(templateents,find);
									RemoveFromArray(templatetargs,find);
								}
							}
						}
					}
				}
			}
			else
			{
				if (HasEntProp(templateent,Prop_Data,"m_ChildTargetName"))
				{
					char templatename[32];
					GetEntPropString(templateent,Prop_Data,"m_ChildTargetName",templatename,sizeof(templatename));
					if (strlen(templatename) > 0)
					{
						ReplaceStringEx(templatename,sizeof(templatename),"pttemplate","");
						int find = FindStringInArray(templatetargs,templatename);
						if (find != -1)
						{
							if (debuglvl >= 2) PrintToServer("npc_template_maker spawn custom ent %s",templatename);
							Handle dp = GetArrayCell(templateents,find);
							if (delay > 0.01)
							{
								CreateTimer(delay,restoreentdp,dp,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(delay,restoreentfire,templateent,TIMER_FLAG_NO_MAPCHANGE);
							}
							else
							{
								restoreentarr(dp);
								AcceptEntityInput(templateent,"FireUser1");
							}
						}
					}
				}
			}
		}
	}
	CloseHandle(temparr);
}

findmassset(Handle dp, float delay)
{
	if (dp != INVALID_HANDLE)
	{
		if (delay > 0.01) CreateTimer(delay,resetmasstimer,dp,TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			ResetPack(dp);
			char targn[128];
			char massset[32];
			ReadPackString(dp,targn,sizeof(targn));
			ReadPackString(dp,massset,sizeof(massset));
			CloseHandle(dp);
			int targ = FindByTargetName(targn);
			if ((IsValidEntity(targ)) && (targ != 0))
			{
				SetEntityMoveType(targ,MOVETYPE_NOCLIP);
				int convert = CreateEntityByName("phys_convert");
				if (convert != -1)
				{
					DispatchKeyValue(convert,"target",targn);
					DispatchKeyValue(convert,"swapmodel",targn);
					DispatchKeyValue(convert,"massoverride",massset);
					DispatchSpawn(convert);
					ActivateEntity(convert);
					AcceptEntityInput(convert,"ConvertTarget");
					AcceptEntityInput(convert,"kill");
				}
			}
		}
	}
}

public Action restoreentdp(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		restoreentarr(dp);
	}
}

public Action resetmasstimer(Handle timer, Handle dp)
{
	findmassset(dp,0.0);
}

public Action restoreentfire(Handle timer, int ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent,"FireUser1");
	}
}

public Action trigout(const char[] output, int caller, int activator, float delay)
{
	char scenes[128];
	if (HasEntProp(caller,Prop_Data,"m_iszPlay")) GetEntPropString(caller,Prop_Data,"m_iszPlay",scenes,sizeof(scenes));
	if (StrEqual(scenes,"uc_sci_vent_pull",false))
	{
		if (FileExists("sound\\BMS_scripted\\uc\\sci_ventpull_sfxHIT02.wav",true,NULL_STRING)) PrecacheSound("BMS_scripted\\uc\\sci_ventpull_sfxHIT02.wav",true);
		if (FileExists("sound\\BMS_scripted\\uc\\sci_ventpull_sfxHIT.wav",true,NULL_STRING)) PrecacheSound("BMS_scripted\\uc\\sci_ventpull_sfxHIT.wav",true);
	}
	if (seqenablecheck)
	{
		scenes = "";
		char targn[128];
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
		if (strlen(targn) < 1)
		{
			int targent;
			if (HasEntProp(caller,Prop_Data,"m_hTargetEnt")) targent = GetEntPropEnt(caller,Prop_Data,"m_hTargetEnt");
			if ((targent != 0) && (IsValidEntity(targent)))
			{
				if (HasEntProp(targent,Prop_Data,"m_iName")) GetEntPropString(targent,Prop_Data,"m_iName",targn,sizeof(targn));
			}
		}
		if (strlen(targn) < 1)
		{
			int targent;
			for (int i = 1;i<9;i++)
			{
				char targstr[32];
				Format(targstr,sizeof(targstr),"m_hTarget%i",i);
				char targstr2[32];
				Format(targstr2,sizeof(targstr2),"m_iszTarget%i",i);
				char targ2[32];
				if (HasEntProp(caller,Prop_Data,targstr)) targent = GetEntPropEnt(caller,Prop_Data,targstr);
				if (HasEntProp(caller,Prop_Data,targstr2)) GetEntPropString(caller,Prop_Data,targstr2,targ2,sizeof(targ2));
				if ((targent != 0) && (IsValidEntity(targent)))
				{
					if (HasEntProp(targent,Prop_Data,"m_iName"))
					{
						GetEntPropString(targent,Prop_Data,"m_iName",targn,sizeof(targn));
						break;
					}
				}
				else if (strlen(targ2) > 0)
				{
					Format(targn,sizeof(targn),"%s",targ2);
					break;
				}
			}
		}
		if (FindStringInArray(entnames,targn) != -1) return Plugin_Continue;
		if (strlen(scenes) < 1)
		{
			if (HasEntProp(caller,Prop_Data,"m_iszPlay")) GetEntPropString(caller,Prop_Data,"m_iszPlay",scenes,sizeof(scenes));
		}
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
		if (IsValidEntity(caller))
		{
			char clsname[24];
			GetEntityClassname(caller,clsname,sizeof(clsname));
			if (((StrEqual(clsname,"hud_timer",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"logic_choreographed_scene",false))) && ((actmod > MaxClients) || (actmod < 1)))
			{
				skipactchk = true;
				actmod = 0;
			}
			if ((StrEqual(clsname,"trigger_multiple",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"func_door",false)) || (StrEqual(clsname,"trigger_coop",false)) || (StrEqual(clsname,"hud_timer",false)))
			{
				UnhookSingleEntityOutput(caller,tmpout,EntityOutput:trigtp);
				PushArrayCell(ignoretrigs,caller);
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
			if (playerteleports) readoutputstp(targn,tmpout,"Teleport",origin,actmod);
			if (vehiclemaphook) readoutputstp(targn,tmpout,"Save",origin,actmod);
			if (customents)
			{
				readoutputstp(targn,tmpout,"StartPortal",origin,actmod);
				readoutputstp(targn,tmpout,"Deploy",origin,actmod);
				readoutputstp(targn,tmpout,"Retire",origin,actmod);
				readoutputstp(targn,tmpout,"Spawn",origin,actmod);
				readoutputstp(targn,tmpout,"ForceSpawn",origin,actmod);
			}
			readoutputstp(targn,tmpout,"SetMass",origin,actmod);
		}
		else
		{
			char targn[64];
			GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
			if (strlen(targn) < 1) Format(targn,sizeof(targn),"notargn");
			float origin[3];
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
			if (playerteleports) readoutputstp(targn,tmpout,"Teleport",origin,actmod);
			if (vehiclemaphook) readoutputstp(targn,tmpout,"Save",origin,actmod);
			if (customents)
			{
				readoutputstp(targn,tmpout,"StartPortal",origin,actmod);
				readoutputstp(targn,tmpout,"Deploy",origin,actmod);
				readoutputstp(targn,tmpout,"Retire",origin,actmod);
				readoutputstp(targn,tmpout,"Spawn",origin,actmod);
				readoutputstp(targn,tmpout,"ForceSpawn",origin,actmod);
			}
			readoutputstp(targn,tmpout,"SetMass",origin,actmod);
		}
	}
}

public Action centcratebreak(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		if (HasEntProp(caller,Prop_Data,"m_iszResponseContext"))
		{
			char breakitems[128];
			char breakitemsexpl[64][16];
			GetEntPropString(caller,Prop_Data,"m_iszResponseContext",breakitems,sizeof(breakitems));
			if (strlen(breakitems) > 0)
			{
				float porigin[3];
				float pangs[3];
				if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",porigin);
				else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",porigin);
				if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",pangs);
				ExplodeString(breakitems,",",breakitemsexpl,16,128,true);
				for (int i = 0;i<16;i++)
				{
					if (strlen(breakitemsexpl[i]) > 0)
					{
						TrimString(breakitemsexpl[i]);
						if (StrEqual(breakitemsexpl[i],"item_ammo_mp5",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"item_ammo_smg1");
						else if (StrEqual(breakitemsexpl[i],"item_ammo_glock",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"item_ammo_pistol");
						else if (StrEqual(breakitemsexpl[i],"item_weapon_frag",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"weapon_frag");
						else if (StrEqual(breakitemsexpl[i],"item_weapon_tripmine",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"weapon_slam");
						else if (StrEqual(breakitemsexpl[i],"item_weapon_satchel",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"weapon_slam");
						else if (StrEqual(breakitemsexpl[i],"item_grenade_rpg",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"item_rpg_round");
						else if (StrEqual(breakitemsexpl[i],"item_grenade_mp5",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"item_ammo_smg1_grenade");
						int ent = CreateEntityByName(breakitemsexpl[i]);
						if (ent != -1)
						{
							TeleportEntity(ent,porigin,pangs,NULL_VECTOR);
							DispatchSpawn(ent);
							ActivateEntity(ent);
						}
						else if (debuglvl > 1) PrintToServer("item_crate attempted to spawn invalid ent %s",breakitemsexpl[i]);
					}
				}
			}
		}
	}
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
			if (strlen(mdlname) > 0)
			{
				int sf = GetEntProp(caller,Prop_Data,"m_spawnflags");
				if ((!(sf & 4)) && (GetEntityCount() < 2000))
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

public Action rebuildents(int client, int args)
{
	if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		if (StrEqual(h,"0"))
		{
			readcache(client,mapbuf);
			char mapspec[128];
			GetCurrentMap(mapspec,sizeof(mapspec));
			ReplaceString(mapspec,sizeof(mapspec),"bm_","sound/vo/");
			recursion(mapspec);
		}
		else if (StrEqual(h,"1"))
		{
			readcacheexperimental(client);
			char mapspec[128];
			GetCurrentMap(mapspec,sizeof(mapspec));
			ReplaceString(mapspec,sizeof(mapspec),"bm_","sound/vo/");
			recursion(mapspec);
		}
		else
		{
			PrintToConsole(client,"Use sm_rebuildents 0 or 1\n0 is static sets, 1 is experimental detection.");
			return Plugin_Handled;
		}
	}
	else
	{
		readcache(client,mapbuf);
		char mapspec[128];
		GetCurrentMap(mapspec,sizeof(mapspec));
		ReplaceString(mapspec,sizeof(mapspec),"bm_","sound/vo/");
		recursion(mapspec);
	}
	return Plugin_Handled;
}

public recursion(char sbuf[128])
{
	char buff[128];
	Handle msubdirlisting = OpenDirectory(sbuf,true,NULL_STRING);
	if (msubdirlisting != INVALID_HANDLE)
	{
		while (ReadDirEntry(msubdirlisting, buff, sizeof(buff)))
		{
			if ((!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))) && (!(msubdirlisting == INVALID_HANDLE)))
			{
				if ((!(StrContains(buff, ".ztmp") != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
				{
					char buff2[128];
					Format(buff2,sizeof(buff2),"%s/%s",sbuf,buff);
					if (StrContains(buff2,"//",false) != -1)
						ReplaceString(buff2,sizeof(buff2),"//","/",false);
					if (StrContains(buff2, ".wav", false) != -1)
					{
						char tmpbuf[128];
						Format(tmpbuf,sizeof(tmpbuf),"%s",buff2);
						ReplaceString(tmpbuf,sizeof(tmpbuf),"sound/","");
						ReplaceString(tmpbuf,sizeof(tmpbuf),"/","\\");
						PrecacheSound(tmpbuf,true);
						Format(tmpbuf,sizeof(tmpbuf),"*%s",tmpbuf);
						PrecacheSound(tmpbuf,true);
						//if (debuglvl == 3) PrintToServer("Precached %s",tmpbuf);
					}
					if (!(StrContains(buff2, ".", false) != -1))
					{
						recursion(buff2);
					}
				}
			}
		}
	}
	CloseHandle(msubdirlisting);
}

void resetchargers(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		if (StrEqual(clsname,"item_healthcharger",false))
		{
			char mdl[128];
			Format(mdl,sizeof(mdl),"models/props_blackmesa/health_charger.mdl");
			if (FileExists(mdl,true,NULL_STRING))
			{
				SetEntPropString(thisent,Prop_Data,"m_ModelName",mdl);
				DispatchKeyValue(thisent,"model",mdl);
				if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
				SetEntityModel(thisent,mdl);
			}
		}
		else if (StrEqual(clsname,"item_suitcharger",false))
		{
			char mdl[128];
			Format(mdl,sizeof(mdl),"models/props_blackmesa/hev_charger.mdl");
			if (FileExists(mdl,true,NULL_STRING))
			{
				SetEntPropString(thisent,Prop_Data,"m_ModelName",mdl);
				DispatchKeyValue(thisent,"model",mdl);
				if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
				SetEntityModel(thisent,mdl);
			}
		}
		resetchargers(thisent++,clsname);
	}
}

void resetspawners(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char clschk[32];
		if (HasEntProp(thisent,Prop_Data,"m_iszNPCClassname")) GetEntPropString(thisent,Prop_Data,"m_iszNPCClassname",clschk,sizeof(clschk));
		char clstarg[128];
		if (HasEntProp(thisent,Prop_Data,"m_ChildTargetName")) GetEntPropString(thisent,Prop_Data,"m_ChildTargetName",clstarg,sizeof(clstarg));
		//if ((StrEqual(clschk,"npc_houndeye",false)) || (StrEqual(clschk,"npc_bullsquid",false)) || (StrContains(clschk,"npc_human_s",false) != -1) || (StrContains(clschk,"npc_alien_slave",false) != -1) || (StrContains(clschk,"npc_zombie_security",false) != -1) || (StrContains(clschk,"npc_zombie_scientist",false) != -1) || (StrEqual(clschk,"npc_human_grunt",false)) || (StrEqual(clschk,"npc_human_commander",false)) || (StrEqual(clschk,"npc_human_medic",false)) || (StrEqual(clschk,"npc_human_grenadier",false)))
		if ((StrEqual(clschk,"npc_headcrab",false)) && (StrContains(clstarg,"pttemplate",false) == 0))
		{
			AcceptEntityInput(thisent,"Disable");
			//CreateTimer(1.0,waitinitspawner,thisent,TIMER_FLAG_NO_MAPCHANGE);
		}
		if ((FindStringInArray(customentlist,clschk) != -1) && (!StrEqual(clsname,"info_target",false)))
		{
			customspawners = true;
			char addequip[24];
			Format(clstarg,sizeof(clstarg),"%s%s",clschk,clstarg);
			SetEntPropString(thisent,Prop_Data,"m_ChildTargetName",clstarg);
			if (HasEntProp(thisent,Prop_Data,"m_spawnEquipment"))
			{
				GetEntPropString(thisent,Prop_Data,"m_spawnEquipment",addequip,sizeof(addequip));
				if (StrEqual(addequip,"weapon_glock",false)) SetEntPropString(thisent,Prop_Data,"m_spawnEquipment","weapon_pistol");
				else if (StrEqual(addequip,"weapon_mp5",false)) SetEntPropString(thisent,Prop_Data,"m_spawnEquipment","weapon_smg1");
				else if (StrEqual(addequip,"q",false)) SetEntPropString(thisent,Prop_Data,"m_spawnEquipment","weapon_rpg");
			}
			char xencls[24];
			GetEntityClassname(thisent,xencls,sizeof(xencls));
			if (StrEqual(xencls,"env_xen_portal",false))
			{
				float orgs[3];
				if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",orgs);
				orgs[2]-=55.0;
				TeleportEntity(thisent,orgs,NULL_VECTOR,NULL_VECTOR);
			}
			else
			{
				if ((HasEntProp(thisent,Prop_Data,"m_bDisabled")) && (HasEntProp(thisent,Prop_Data,"m_nMaxNumNPCs")) && (HasEntProp(thisent,Prop_Data,"m_iName")))
				{
					int startdisabled = GetEntProp(thisent,Prop_Data,"m_bDisabled");
					int maxnpc = GetEntProp(thisent,Prop_Data,"m_nMaxNumNPCs");
					if ((startdisabled == 0) && (maxnpc == 1))
					{
						AcceptEntityInput(thisent,"Disable");
						PushArrayCell(spawnerswait,thisent);
					}
				}
			}
			if ((StrEqual(clschk,"npc_zombie_security",false)) || (StrEqual(clschk,"npc_zombie_security_torso",false)))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_zombine");
				DispatchKeyValue(thisent,"NPCType","npc_zombine");
			}
			else if (StrContains(clschk,"npc_zombie_",false) != -1)
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_zombie");
				DispatchKeyValue(thisent,"NPCType","npc_zombie");
			}
			else if (StrEqual(clschk,"npc_human_scientist_eli",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_eli");
				DispatchKeyValue(thisent,"NPCType","npc_eli");
			}
			else if (StrEqual(clschk,"npc_human_scientist_kleiner",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_kleiner");
				DispatchKeyValue(thisent,"NPCType","npc_kleiner");
			}
			else if (StrEqual(clschk,"npc_alien_slave",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_vortigaunt");
				DispatchKeyValue(thisent,"NPCType","npc_vortigaunt");
				if (!relsetvort)
				{
					setuprelations(clschk);
					relsetvort = true;
				}
			}
			else if ((StrEqual(clschk,"npc_alien_grunt",false)) || (StrEqual(clschk,"npc_alien_grunt_unarmored",false)))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_combine_s");
				DispatchKeyValue(thisent,"NPCType","npc_combine_s");
				if (FindStringInArray(precachedarr,"npc_alien_grunt") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/npc/alien_grunt/");
					recursion(searchprecache);
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/hivehand/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"npc_alien_grunt");
				}
			}
			else if ((StrEqual(clschk,"npc_human_grunt",false)) || (StrEqual(clschk,"npc_human_commander",false)) || (StrEqual(clschk,"npc_human_grenadier",false)) || (StrEqual(clschk,"npc_human_medic",false)) || (StrEqual(clschk,"npc_abrams",false)))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_combine_s");
				DispatchKeyValue(thisent,"NPCType","npc_combine_s");
			}
			else if (StrEqual(clschk,"npc_osprey",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_combinedropship");
				DispatchKeyValue(thisent,"NPCType","npc_combinedropship");
			}
			else if (StrEqual(clschk,"npc_snark",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_headcrab_fast");
				DispatchKeyValue(thisent,"NPCType","npc_headcrab_fast");
			}
			else if ((StrEqual(clschk,"npc_houndeye",false)) || (StrEqual(clschk,"npc_bullsquid",false)))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_antlion");
				DispatchKeyValue(thisent,"NPCType","npc_antlion");
			}
			else
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_citizen");
				DispatchKeyValue(thisent,"NPCType","npc_citizen");
			}
		}
		else if (FindStringInArray(customentlist,clstarg) != -1) customspawners = true;
		resetspawners(thisent++,clsname);
	}
}

public int FindByTargetName(char[] entname)
{
	int startent = MaxClients+1;
	for (int i = startent;i<GetMaxEntities()+1;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			if (HasEntProp(i,Prop_Data,"m_iName"))
			{
				char chkname[64];
				GetEntPropString(i,Prop_Data,"m_iName",chkname,sizeof(chkname));
				if (StrEqual(chkname,entname))
				{
					return i;
				}
			}
		}
	}
	return -1;
}
/*
public Action waitinitspawner(Handle timer, int spawnerent)
{
	char templatename[128];
	if (HasEntProp(spawnerent,Prop_Data,"m_ChildTargetName")) GetEntPropString(spawnerent,Prop_Data,"m_ChildTargetName",templatename,sizeof(templatename));
	ReplaceStringEx(templatename,sizeof(templatename),"pttemplate","");
	int findtemplateent = FindByTargetName(templatename);
	if ((findtemplateent != 0) && (findtemplateent != -1))
	{
		float ptorigin[3];
		float ptangs[3];
		if (HasEntProp(spawnerent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spawnerent,Prop_Data,"m_vecAbsOrigin",ptorigin);
		else if (HasEntProp(spawnerent,Prop_Send,"m_vecOrigin")) GetEntPropVector(spawnerent,Prop_Send,"m_vecOrigin",ptorigin);
		if (HasEntProp(spawnerent,Prop_Data,"m_angRotation")) GetEntPropVector(spawnerent,Prop_Data,"m_angRotation",ptangs);
		TeleportEntity(findtemplateent,ptorigin,ptangs,NULL_VECTOR);
		if (debuglvl == 3) PrintToServer("%i %s ent spawn from npctemplate",findtemplateent,templatename);
		char targfind[32];
		PropFieldType type;
		FindDataMapInfo(findtemplateent,"m_target",type);
		if (type == PropField_String)
		{
			GetEntPropString(findtemplateent,Prop_Data,"m_target",targfind,sizeof(targfind));
		}
		Handle dp = packent(findtemplateent,targfind);
		if (dp != INVALID_HANDLE)
		{
			PushArrayString(templatetargs,templatename);
			PushArrayCell(templateents,dp);
		}
		AcceptEntityInput(findtemplateent,"kill");
	}
}
*/
void readcache(int client, char[] cache)
{
	Handle filehandle = OpenFile(cache,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		Handle passedarr = CreateArray(64);
		bool createent = false;
		bool storetemplate = false;
		int pttemplate = -1;
		int ent = -1;
		float fileorigin[3];
		float angs[3];
		char kvs[128][64];
		char oldcls[32];
		bool passvars = false;
		bool createsit = false;
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line,"classname",false))
			{
				char clschk[128];
				Format(clschk,sizeof(clschk),line);
				ExplodeString(clschk, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				//if ((StrContains(line,"monster_",false) != -1) || ((StrContains(line,"trigger_auto",false) != -1) && (StrContains(line,"trigger_autosave",false) == -1)) || (StrContains(line,"env_xen_portal",false) != -1) || (StrContains(line,"npc_human_security",false) != -1) || (StrContains(line,"npc_human_scientist",false) != -1) || (StrContains(line,"npc_human_scientist_female",false) != -1) || (StrContains(line,"npc_human_scientist_eli",false) != -1) || (StrContains(line,"npc_human_scientist_kleiner",false) != -1) || (StrContains(line,"npc_alien_slave",false) != -1) || (StrContains(line,"npc_zombie_security",false) != -1) || (StrContains(line,"npc_zombie_scientist",false) != -1) || (StrContains(line,"npc_human_grunt",false) != -1) || (StrContains(line,"npc_human_commander",false) != -1) || (StrContains(line,"npc_human_grenadier",false) != -1) || (StrContains(line,"npc_human_medic",false) != -1) || (StrContains(line,"npc_osprey",false) != -1) || (StrContains(line,"npc_houndeye",false) != -1) || (StrContains(line,"npc_bullsquid",false) != -1) || (StrContains(line,"npc_sentry_ceiling",false) != -1) || (StrContains(line,"npc_tentacle",false) != -1) || (StrContains(line,"item_weapon_tripmine",false) != -1) || (StrContains(line,"prop_train_awesome",false) != -1) || (StrContains(line," item_ammo_smg1_grenade",false) != -1) || (StrContains(line,"item_weapon_satchel",false) != -1) || (StrContains(line,"npc_sentry_ground",false) != -1))
				//else if ((StrContains(line,"classname",false) != -1) && ((StrContains(line,"monster_",false) == -1) || ((StrContains(line,"trigger_auto",false) == -1) && (StrContains(line,"trigger_autosave",false) != -1)) || (StrContains(line,"env_xen_portal",false) == -1) || (StrContains(line,"npc_human_security",false) == -1) || (StrContains(line,"npc_human_scientist",false) == -1) || (StrContains(line,"npc_human_scientist_female",false) == -1) || (StrContains(line,"npc_human_scientist_eli",false) == -1) || (StrContains(line,"npc_human_scientist_kleiner",false) == -1) || (StrContains(line,"npc_alien_slave",false) == -1) || (StrContains(line,"npc_zombie_security",false) == -1) || (StrContains(line,"npc_zombie_scientist",false) == -1) || (StrContains(line,"npc_human_grunt",false) == -1) || (StrContains(line,"npc_human_commander",false) == -1) || (StrContains(line,"npc_human_grenadier",false) == -1) || (StrContains(line,"npc_human_medic",false) == -1) || (StrContains(line,"npc_osprey",false) == -1) || (StrContains(line,"npc_houndeye",false) == -1) || (StrContains(line,"npc_bullsquid",false) == -1) || (StrContains(line,"npc_sentry_ceiling",false) == -1) || (StrContains(line,"npc_tentacle",false) == -1) || (StrContains(line,"item_weapon_tripmine",false) == -1) || (StrContains(line,"prop_train_awesome",false) == -1) || (StrContains(line," item_ammo_smg1_grenade",false) == -1) || (StrContains(line,"item_weapon_satchel",false) == -1) || (StrContains(line,"npc_sentry_ground",false) == -1)))
				if (FindStringInArray(customentlist,kvs[3]) != -1)
				{
					createent = true;
					PushArrayString(passedarr,kvs[1]);
					PushArrayString(passedarr,kvs[3]);
				}
				else if (StrEqual(kvs[3],"npc_template_maker",false))
				{
					storetemplate = true;
				}
				else if ((StrEqual(kvs[1],"classname",false)) && (FindStringInArray(customentlist,kvs[3]) == -1))
				{
					createent = false;
				}
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
						if (StrEqual(ktmp,"liftaccel",false))
						{
							Format(ktmp,sizeof(ktmp),"Speed");
							int speedadjust = StringToInt(ktmp2);
							speedadjust = speedadjust*10;
							if (speedadjust > 1000) speedadjust = 1000;
							Format(ktmp2,sizeof(ktmp2),"%i",speedadjust);
						}
						DispatchKeyValue(ent,ktmp,ktmp2);
					}
				}
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				if ((StrEqual(kvs[1],"OnStartPortal",false)) || (StrEqual(kvs[1],"OnFinishPortal",false))) Format(kvs[1],sizeof(kvs[]),"OnUser2");
				else if (StrEqual(kvs[1],"OnDetonate",false)) Format(kvs[1],sizeof(kvs[]),"OnUser2");
				if ((StrEqual(kvs[1],"AdditionalEquipment",false)) && (StrEqual(kvs[3],"weapon_glock",false))) Format(kvs[3],sizeof(kvs[]),"weapon_pistol");
				else if ((StrEqual(kvs[1],"AdditionalEquipment",false)) && (StrEqual(kvs[3],"weapon_mp5",false))) Format(kvs[3],sizeof(kvs[]),"weapon_smg1");
				else if ((StrEqual(kvs[1],"AdditionalEquipment",false)) && (StrEqual(kvs[3],"q",false))) Format(kvs[3],sizeof(kvs[]),"weapon_rpg");
				if (StrEqual(kvs[1],"liftaccel",false))
				{
					Format(kvs[1],sizeof(kvs[]),"Speed");
					int speedadjust = StringToInt(kvs[3]);
					speedadjust = speedadjust*10;
					if (speedadjust > 1000) speedadjust = 1000;
					Format(kvs[3],sizeof(kvs[]),"%i",speedadjust);
				}
				if (passvars)
				{
					PushArrayString(passedarr,kvs[1]);
					PushArrayString(passedarr,kvs[3]);
				}
				else
				{
					DispatchKeyValue(ent,kvs[1],kvs[3]);
					//Still pass for later info
					PushArrayString(passedarr,kvs[1]);
					PushArrayString(passedarr,kvs[3]);
				}
			}
			if (StrContains(line,"\"origin\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				char origch[16][16];
				ExplodeString(tmpchar," ",origch,16,16);
				fileorigin[0] = StringToFloat(origch[0]);
				fileorigin[1] = StringToFloat(origch[1]);
				fileorigin[2] = StringToFloat(origch[2]);
			}
			else if (StrContains(line,"\"angles\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"angles\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				char origch[16][16];
				ExplodeString(tmpchar," ",origch,16,16);
				angs[0] = StringToFloat(origch[0]);
				angs[1] = StringToFloat(origch[1]);
				angs[2] = StringToFloat(origch[2]);
			}
			if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)) && (ent == -1))
			{
				if (storetemplate)
				{
					int findtemplatename = FindStringInArray(passedarr,"TemplateName");
					if (findtemplatename != -1)
					{
						char tmpchar[64];
						findtemplatename++;
						GetArrayString(passedarr,findtemplatename,tmpchar,sizeof(tmpchar));
						pttemplate = CreateEntityByName("npc_maker");
						if (pttemplate != -1)
						{
							Format(tmpchar,sizeof(tmpchar),"pttemplate%s",tmpchar);
							DispatchKeyValue(pttemplate,"NPCType","npc_headcrab");
							DispatchKeyValue(pttemplate,"NPCTargetname",tmpchar);
							DispatchKeyValue(pttemplate,"StartDisabled","1");
							for (int i = 0;i<GetArraySize(passedarr);i++)
							{
								char arrchk[32];
								GetArrayString(passedarr,i,arrchk,sizeof(arrchk));
								if ((StrEqual(arrchk,"OnSpawnNPC",false)) || (StrEqual(arrchk,"OnAllSpawned",false)) || (StrEqual(arrchk,"OnAllLiveChildrenDead",false)) || (StrEqual(arrchk,"OnAllSpawnedDead",false)))
								{
									int findoutarr = i+1;
									char output[128];
									GetArrayString(passedarr,findoutarr,output,sizeof(output));
									//PrintToServer("Pass output %s %s",arrchk,output);
									DispatchKeyValue(pttemplate,arrchk,output);
								}
								else if (StrEqual(arrchk,"Targetname",false))
								{
									int findoutarr = i+1;
									char tmptarg[128];
									GetArrayString(passedarr,findoutarr,tmptarg,sizeof(tmptarg));
									DispatchKeyValue(pttemplate,"targetname",tmptarg);
								}
							}
							DispatchSpawn(pttemplate);
							ActivateEntity(pttemplate);
							TeleportEntity(pttemplate,fileorigin,angs,NULL_VECTOR);
							PushArrayCell(templateslist,pttemplate);
						}
					}
				}
				ClearArray(passedarr);
				passvars = true;
				storetemplate = false;
				pttemplate = -1;
			}
			else if (createent)
			{
				char cls[32];
				int arrindx = FindStringInArray(passedarr,"classname");
				if (arrindx != -1)
				{
					char tmpchar[128];
					GetArrayString(passedarr,arrindx+1,tmpchar,sizeof(tmpchar));
					Format(cls,sizeof(cls),"%s",tmpchar);
					/*
					ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
					ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
					if (StrContains(kvs[3],"_",false) != -1)
					{
						Format(cls,sizeof(cls),"%s",kvs[3]);
					}
					*/
				}
				if ((ent == -1) && (strlen(cls) > 0))
				{
					if (StrEqual(cls,"worldspawn",false)) break;
					char setupent[24];
					Handle dp = INVALID_HANDLE;
					Format(oldcls,sizeof(oldcls),"%s",cls);
					if (StrEqual(cls,"monster_headcrab",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/headcrab.mdl");
					}
					else if ((StrEqual(cls,"monster_scientist",false)) || (StrEqual(cls,"monster_scientist_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/scientist.mdl");
					}
					else if (StrEqual(cls,"monster_sitting_scientist",false))
					{
						Format(cls,sizeof(cls),"prop_dynamic");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/scientist.mdl");
						PushArrayString(passedarr,"solid");
						PushArrayString(passedarr,"6");
						PushArrayString(passedarr,"DefaultAnim");
						PushArrayString(passedarr,"sitting3");
						createsit = true;
					}
					else if ((StrEqual(cls,"monster_barney",false)) || (StrEqual(cls,"monster_barney_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/barney.mdl");
					}
					else if (StrEqual(cls,"monster_gman",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/gman.mdl");
					}
					else if (StrEqual(cls,"monster_osprey",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/osprey.mdl");
					}
					else if (StrEqual(cls,"monster_houndeye",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/houndeye.mdl");
					}
					else if (StrEqual(cls,"monster_barnacle",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/barnacle.mdl");
					}
					else if (StrEqual(cls,"monster_zombie",false))
					{
						Format(cls,sizeof(cls),"npc_zombie");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombie.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombie.mdl");
					}
					else if (StrEqual(cls,"monster_sentry",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/sentry.mdl");
					}
					else if (StrEqual(cls,"monster_alien_slave",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/islave.mdl");
					}
					else if ((StrEqual(cls,"monster_human_grunt",false)) || (StrEqual(cls,"monster_hgrunt_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/hgrunt.mdl");
					}
					else if (StrEqual(cls,"monster_cockroach",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/roach.mdl");
					}
					else if (StrEqual(cls,"monster_bullchicken",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/bullsquid.mdl");
					}
					else if (StrEqual(cls,"trigger_auto",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Trigger,,0,1");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Kill,,0.5,1");
					}
					else if (StrEqual(cls,"npc_human_security",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char humanp[128];
							Format(humanp,sizeof(humanp),"sound/vo/npc/barneys/");
							recursion(humanp);
							PushArrayString(precachedarr,cls);
						}
						int find = FindStringInArray(passedarr,"additionalequipment");
						if (find != -1)
						{
							find++;
							char addweap[32];
							GetArrayString(passedarr,find,addweap,sizeof(addweap));
							if (StrEqual(addweap,"default",false)) Format(cls,sizeof(cls),"generic_actor");
							else
							{
								Format(cls,sizeof(cls),"npc_citizen");
								PushArrayString(passedarr,"spawnflags");
								PushArrayString(passedarr,"1048576");
								dp = CreateDataPack();
								WritePackString(dp,"models/humans/guard.mdl");
							}
						}
						else Format(cls,sizeof(cls),"generic_actor");
						int findsk = FindStringInArray(passedarr,"skin");
						if (findsk == -1)
						{
							PushArrayString(passedarr,"skin");
							char randsk[8];
							int rand = GetRandomInt(0,14);
							Format(randsk,sizeof(randsk),"%i",rand);
							PushArrayString(passedarr,randsk);
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/guard.mdl");
					}
					else if (StrEqual(cls,"npc_human_scientist",false))
					{
						PushArrayString(passedarr,"model");
						char mdlset[128];
						int rand = GetRandomInt(0,1);
						if (rand == 0) Format(mdlset,sizeof(mdlset),"models/humans/scientist.mdl");
						else Format(mdlset,sizeof(mdlset),"models/humans/scientist_02.mdl");
						PushArrayString(passedarr,mdlset);
						if (!relsetsci)
						{
							setuprelations(cls);
							relsetsci = true;
						}
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char humanp[128];
							Format(humanp,sizeof(humanp),"sound/vo/npc/scientist_male01/");
							recursion(humanp);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"generic_actor");
					}
					else if (StrEqual(cls,"npc_human_scientist_female",false))
					{
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/scientist_female.mdl");
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char humanp[128];
							Format(humanp,sizeof(humanp),"sound/vo/npc/scientist_female01/");
							recursion(humanp);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"generic_actor");
					}
					else if (StrEqual(cls,"npc_alien_slave",false))
					{
						Format(cls,sizeof(cls),"npc_vortigaunt");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/vortigaunt_slave.mdl");
						if (!relsetvort)
						{
							setuprelations(cls);
							relsetvort = true;
						}
					}
					else if (StrEqual(cls,"npc_human_scientist_kleiner",false))
					{
						Format(cls,sizeof(cls),"npc_kleiner");
						//PushArrayString(passedarr,"model");
						//PushArrayString(passedarr,"models/humans/scientist_kliener.mdl");
						//Model invisible?
					}
					else if (StrEqual(cls,"npc_human_scientist_eli",false))
					{
						Format(cls,sizeof(cls),"npc_eli");
					}
					else if (StrEqual(cls,"npc_zombie_security_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						Handle cvarchk = FindConVar("sk_zombie_soldier_health");
						if (GetConVarInt(cvarchk) < 6) SetConVarInt(cvarchk,100,false,false);
						CloseHandle(cvarchk);
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_guard_torso.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_guard_torso.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_security",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						Handle cvarchk = FindConVar("sk_zombie_soldier_health");
						if (GetConVarInt(cvarchk) < 6) SetConVarInt(cvarchk,100,false,false);
						CloseHandle(cvarchk);
						if (!relsetzsec)
						{
							setuprelations(cls);
							relsetzsec = true;
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_guard.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_guard.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_scientist_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombie_torso");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_sci_torso.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_sci_torso.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_scientist",false))
					{
						Format(cls,sizeof(cls),"npc_zombie");
						if (!relsetzsec)
						{
							setuprelations(cls);
							relsetzsec = true;
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_sci.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_sci.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if ((StrEqual(cls,"npc_human_grunt",false)) || (StrEqual(cls,"npc_human_commander",false)) || (StrEqual(cls,"npc_human_grenadier",false)) || (StrEqual(cls,"npc_human_medic",false)))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/marine.mdl");
						Format(setupent,sizeof(setupent),"marine");
					}
					else if (StrEqual(cls,"npc_osprey",false))
					{
						Format(cls,sizeof(cls),"npc_combinedropship");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/osprey.mdl");
					}
					else if (StrEqual(cls,"npc_tentacle",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/tentacle/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/tentacle.mdl");
						Format(setupent,sizeof(setupent),"tentacle");
					}
					else if (StrEqual(cls,"npc_houndeye",false))
					{
						Format(cls,sizeof(cls),"npc_antlion");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/houndeye.mdl");
						PushArrayString(passedarr,"modelscale");
						PushArrayString(passedarr,"0.6");
						dp = CreateDataPack();
						WritePackString(dp,"models/xenians/houndeye.mdl");
						Format(setupent,sizeof(setupent),"hound");
						if (FindStringInArray(precachedarr,"npc_houndeye") == -1)
						{
							PrecacheSound("npc\\houndeye\\blast1.wav",true);
							PrecacheSound("npc\\houndeye\\he_step1.wav",true);
							PrecacheSound("npc\\houndeye\\he_step2.wav",true);
							PrecacheSound("npc\\houndeye\\he_step3.wav",true);
							PrecacheSound("npc\\houndeye\\charge1.wav",true);
							PrecacheSound("npc\\houndeye\\charge2.wav",true);
							PrecacheSound("npc\\houndeye\\charge3.wav",true);
							PrecacheSound("npc\\houndeye\\die1.wav",true);
							PrecacheSound("npc\\houndeye\\pain1.wav",true);
							PrecacheSound("npc\\houndeye\\pain2.wav",true);
							PrecacheSound("npc\\houndeye\\pain3.wav",true);
							PushArrayString(precachedarr,"npc_houndeye");
						}
						if (!relsethound)
						{
							setuprelations(cls);
							relsethound = true;
						}
					}
					else if (StrEqual(cls,"npc_bullsquid",false))
					{
						Format(cls,sizeof(cls),"npc_antlion");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/bullsquid.mdl");
						PushArrayString(passedarr,"modelscale");
						PushArrayString(passedarr,"0.5");
						Format(setupent,sizeof(setupent),"squid");
						dp = CreateDataPack();
						WritePackString(dp,"models/xenians/bullsquid.mdl");
					}
					else if (StrEqual(cls,"npc_sentry_ceiling",false))
					{
						Format(cls,sizeof(cls),"npc_turret_ceiling");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"env_xen_portal",false))
					{
						if (FindStringInArray(precachedarr,"env_xen_portal") == -1)
						{
							PrecacheSound("BMS_objects\\portal\\portal_In_01.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_02.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_03.wav",true);
							PushArrayString(precachedarr,"env_xen_portal");
						}
						Format(cls,sizeof(cls),"npc_maker");
					}
					else if (StrEqual(cls,"env_xen_portal_template",false))
					{
						if (FindStringInArray(precachedarr,"env_xen_portal") == -1)
						{
							PrecacheSound("BMS_objects\\portal\\portal_In_01.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_02.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_03.wav",true);
							PushArrayString(precachedarr,"env_xen_portal");
						}
						Format(cls,sizeof(cls),"npc_template_maker");
					}
					else if (StrEqual(cls,"multi_manager",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
					}
					else if (StrEqual(cls,"item_weapon_tripmine",false))
					{
						Format(cls,sizeof(cls),"weapon_slam");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"prop_train_awesome",false))
					{
						Format(cls,sizeof(cls),"prop_dynamic");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/oar_awesome_tram.mdl");
					}
					else if (StrEqual(cls,"prop_train_apprehension",false))
					{
						Format(cls,sizeof(cls),"prop_physics_multiplayer");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						find = FindStringInArray(passedarr,"solid");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"solid");
						PushArrayString(passedarr,"0");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/oar_tram.mdl");
					}
					else if (StrEqual(cls," item_ammo_smg1_grenade",false)) //wat
					{
						Format(cls,sizeof(cls),"item_ammo_smg1_grenade");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if ((StrEqual(cls,"item_weapon_satchel",false)) || (StrEqual(cls,"item_weapon_tripmine",false)))
					{
						Format(cls,sizeof(cls),"weapon_slam");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"item_grenade_rpg",false))
					{
						Format(cls,sizeof(cls),"item_rpg_round");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"item_weapon_rpg",false))
					{
						Format(cls,sizeof(cls),"weapon_rpg");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"item_weapon_crossbow",false))
					{
						Format(cls,sizeof(cls),"weapon_crossbow");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"npc_sentry_ground",false))
					{
						Format(cls,sizeof(cls),"npc_turret_floor");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"npc_alien_grunt",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/alien_grunt/");
							recursion(searchprecache);
							Format(searchprecache,sizeof(searchprecache),"sound/weapons/hivehand/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/agrunt.mdl");
						if (!relsetvort)
						{
							setuprelations(cls);
							relsetvort = true;
						}
						Format(setupent,sizeof(setupent),"agrunt");
					}
					else if (StrEqual(cls,"npc_alien_grunt_unarmored",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/alien_grunt/");
							recursion(searchprecache);
							Format(searchprecache,sizeof(searchprecache),"sound/weapons/hivehand/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/agrunt_unarmored.mdl");
						Format(setupent,sizeof(setupent),"agrunt");
					}
					else if (StrEqual(cls,"npc_snark",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/snark/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"npc_headcrab_fast");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/snark.mdl");
						Format(setupent,sizeof(setupent),"snark");
					}
					else if (StrEqual(cls,"npc_abrams",false))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/abrams.mdl");
						if (!relsetabram)
						{
							setuprelations(cls);
							relsetabram = true;
						}
						dp = CreateDataPack();
						WritePackString(dp,"models/props_vehicles/abrams.mdl");
					}
					else if (StrEqual(cls,"npc_apache",false))
					{
						Format(cls,sizeof(cls),"npc_helicopter");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/apache.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/props_vehicles/apache.mdl");
					}
					else if (StrEqual(cls,"trigger_lift",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						Format(cls,sizeof(cls),"trigger_push");
						PushArrayString(passedarr,"pushdir");
						PushArrayString(passedarr,"-90 0 0");
					}
					else if (StrEqual(cls,"grenade_tripmine",false))
					{
						/*
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						*/
						//dp = CreateDataPack();
						//WritePackString(dp,"models/weapons/w_tripmine.mdl");
						PushArrayString(passedarr,"spawnflags");
						PushArrayString(passedarr,"8");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/weapons/w_tripmine.mdl");
						Format(cls,sizeof(cls),"prop_physics");
					}
					else if (StrEqual(cls,"item_crate",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						Format(cls,sizeof(cls),"prop_physics");
					}
					else if (StrEqual(cls,"func_minefield",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						Format(cls,sizeof(cls),"trigger_once");
					}
					else if ((StrEqual(cls,"func_50cal",false)) || (StrEqual(cls,"func_tow",false)))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						Format(cls,sizeof(cls),"func_tank");
					}
					ent = CreateEntityByName(cls);
					if (StrEqual(setupent,"hound"))
					{
						SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
						PushArrayCell(hounds,ent);
						int entmdl = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
						DispatchKeyValue(entmdl,"solid","0");
						float tmpset[3];
						tmpset[2]-=5.0;
						TeleportEntity(entmdl,tmpset,NULL_VECTOR,NULL_VECTOR);
						DispatchSpawn(entmdl);
						ActivateEntity(entmdl);
						SetVariantString("!activator");
						AcceptEntityInput(entmdl,"SetParent",ent);
						PushArrayCell(houndsmdl,entmdl);
						SDKHookEx(ent,SDKHook_Think,houndthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,houndtkdmg);
						HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
					}
					else if (StrEqual(setupent,"squid"))
					{
						SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
						PushArrayCell(squids,ent);
						int entmdl = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
						DispatchKeyValue(entmdl,"solid","0");
						DispatchSpawn(entmdl);
						ActivateEntity(entmdl);
						SetVariantString("!activator");
						AcceptEntityInput(entmdl,"SetParent",ent);
						PushArrayCell(squidsmdl,entmdl);
						SDKHookEx(ent,SDKHook_Think,squidthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,squidtkdmg);
						HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
					}
					else if (StrEqual(setupent,"zombie"))
					{
						SDKHookEx(ent,SDKHook_Think,zomthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
					}
					else if (StrEqual(setupent,"marine"))
					{
						if (StrEqual(oldcls,"npc_human_medic",false))
						{
							int rand = GetRandomInt(0,2);
							if (rand == 0) rand = GetRandomInt(32,35);
							else if (rand == 1) rand = GetRandomInt(40,43);
							else if (rand == 2) rand = GetRandomInt(56,59);
							SetVariantInt(rand);
							AcceptEntityInput(ent,"SetBodyGroup");
						}
						else
						{
							int rand = GetRandomInt(0,70);
							if ((rand >= 32) && (rand <= 35)) rand = GetRandomInt(0,31);
							else if ((rand >= 40) && (rand <= 43)) rand = GetRandomInt(36,39);
							else if ((rand >= 56) && (rand <= 59)) rand = GetRandomInt(60,70);
							SetVariantInt(rand);
							AcceptEntityInput(ent,"SetBodyGroup");
						}
						if (FindStringInArray(passedarr,"skin") == -1)
						{
							int rand = GetRandomInt(0,14);
							SetVariantInt(rand);
							AcceptEntityInput(ent,"skin");
						}
						if (StrEqual(oldcls,"npc_human_grenadier",false))
						{
							SDKHookEx(ent,SDKHook_Think,grenthink);
						}
					}
					else if (StrEqual(setupent,"tentacle"))
					{
						PushArrayCell(tents,ent);
						int entmdl = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(entmdl,"model","models/xenians/tentacle.mdl");
						DispatchKeyValue(entmdl,"targetname","syn_xeniantentaclemdl");
						DispatchKeyValue(entmdl,"solid","6");
						DispatchKeyValue(entmdl,"DefaultAnim","floor_idle");
						DispatchSpawn(entmdl);
						ActivateEntity(entmdl);
						PushArrayCell(tentsmdl,entmdl);
						int entsnd = CreateEntityByName("ambient_generic");
						DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
						DispatchSpawn(entsnd);
						ActivateEntity(entsnd);
						SetVariantString("!activator");
						AcceptEntityInput(entsnd,"SetParent",entmdl);
						SetVariantString("Eye");
						AcceptEntityInput(entsnd,"SetParentAttachment");
						PushArrayCell(tentssnd,entsnd);
						SDKHookEx(ent,SDKHook_Think,tentaclethink);
						HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
					}
					else if (StrEqual(setupent,"agrunt"))
					{
						SDKHookEx(ent,SDKHook_Think,agruntthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,agrunttkdmg);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
						HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
					}
					else if (StrEqual(setupent,"snark"))
					{
						SDKHookEx(ent,SDKHook_Think,snarkthink);
						SDKHook(ent,SDKHook_StartTouch,StartTouchSnark);
					}
					else if (StrEqual(oldcls,"trigger_lift",false))
					{
						DispatchKeyValue(ent,"pushdir","-90 0 0");
					}
					else if (StrEqual(oldcls,"item_crate",false))
					{
						HookSingleEntityOutput(ent,"OnBreak",EntityOutput:centcratebreak);
					}
					else if (StrEqual(oldcls,"npc_alien_slave",false))
					{
						SDKHookEx(ent,SDKHook_Think,aslavethink);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
						if (!relsetvort)
						{
							setuprelations(oldcls);
							relsetvort = true;
						}
					}
					customents = true;
					if (debuglvl > 1) PrintToConsole(client,"Created %s Ent as %s",oldcls,cls);
					if (FindValueInArray(entlist,ent) == -1)
						PushArrayCell(entlist,ent);
					if (dp != INVALID_HANDLE)
					{
						WritePackCell(dp,ent);
						CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				if (StrEqual(line,"}",false))
				{
					int findbase = FindStringInArray(passedarr,"baseclass");
					if (findbase != -1)
					{
						Handle dp = INVALID_HANDLE;
						findbase++;
						GetArrayString(passedarr,findbase,cls,sizeof(cls));
						if (StrEqual(oldcls,"npc_human_scientist",false))
						{
							char mdlset[128];
							int rand = GetRandomInt(0,1);
							if (rand == 0) Format(mdlset,sizeof(mdlset),"models/humans/scientist.mdl");
							else Format(mdlset,sizeof(mdlset),"models/humans/scientist_02.mdl");
							dp = CreateDataPack();
							WritePackString(dp,mdlset);
						}
						else if (StrEqual(oldcls,"npc_human_scientist_female",false))
						{
							char mdlset[128];
							Format(mdlset,sizeof(mdlset),"models/humans/scientist_female.mdl");
							dp = CreateDataPack();
							WritePackString(dp,mdlset);
						}
						AcceptEntityInput(ent,"kill");
						if (debuglvl > 1) PrintToConsole(client,"Reset %s Ent as %s",oldcls,cls);
						ent = CreateEntityByName(cls);
						for (int k = 0;k<GetArraySize(passedarr);k++)
						{
							char ktmp[128];
							char ktmp2[128];
							GetArrayString(passedarr, k, ktmp, sizeof(ktmp));
							k++;
							GetArrayString(passedarr, k, ktmp2, sizeof(ktmp2));
							if (StrEqual(ktmp,"liftaccel",false))
							{
								Format(ktmp,sizeof(ktmp),"Speed");
								int speedadjust = StringToInt(ktmp2);
								speedadjust = speedadjust*10;
								if (speedadjust > 1000) speedadjust = 1000;
								Format(ktmp2,sizeof(ktmp2),"%i",speedadjust);
							}
							DispatchKeyValue(ent,ktmp,ktmp2);
						}
						if (dp != INVALID_HANDLE)
						{
							WritePackCell(dp,ent);
							CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					DispatchSpawn(ent);
					ActivateEntity(ent);
					if (createsit) fileorigin[2]-=25.0;
					if ((StrEqual(oldcls,"prop_train_awesome",false)) || (StrEqual(oldcls,"prop_train_apprehension",false)))
					{
						int find = FindStringInArray(passedarr,"parentname");
						if (find != -1)
						{
							char parentn[64];
							find++;
							GetArrayString(passedarr,find,parentn,sizeof(parentn));
							if (strlen(parentn) > 0)
							{
								SetVariantString(parentn);
								AcceptEntityInput(ent,"SetParent");
								if (HasEntProp(ent,Prop_Data,"m_hParent"))
								{
									int parentchk = GetEntPropEnt(ent,Prop_Data,"m_hParent");
									if ((parentchk != -1) && (IsValidEntity(parentchk)))
									{
										float origin[3];
										float parentangs[3];
										if (HasEntProp(parentchk,Prop_Data,"m_angRotation")) GetEntPropVector(parentchk,Prop_Data,"m_angRotation",parentangs);
										if (HasEntProp(parentchk,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(parentchk,Prop_Data,"m_vecAbsOrigin",origin);
										else if (HasEntProp(parentchk,Prop_Send,"m_vecOrigin")) GetEntPropVector(parentchk,Prop_Send,"m_vecOrigin",origin);
										parentangs[1]+=90.0;
										AcceptEntityInput(ent,"ClearParent");
										SetVariantString("spawnflags 641");
										AcceptEntityInput(parentchk,"AddOutput");
										origin[0]-=1.0;
										origin[1]-=2.0;
										origin[2]-=35.0;
										if (StrEqual(oldcls,"prop_train_apprehension",false))
										{
											parentangs[1]-=90.0;
											origin[0] = (origin[0] + (90 * Cosine(DegToRad(parentangs[1]))));
											origin[1] = (origin[1] + (90 * Sine(DegToRad(parentangs[1]))));
											parentangs[1]+=90.0;
											AcceptEntityInput(ent,"DisableDamageForces");
										}
										TeleportEntity(ent,origin,parentangs,NULL_VECTOR);
										SetVariantString(parentn);
										AcceptEntityInput(ent,"SetParent");
									}
								}
							}
						}
					}
					else if (StrEqual(oldcls,"trigger_lift",false))
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					else
						TeleportEntity(ent,fileorigin,angs,NULL_VECTOR);
					if (StrContains(oldcls,"item_weapon_",false) == 0)
					{
						fileorigin[2]+=1.5;
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					if ((StrEqual(oldcls,"npc_sentry_ground",false)) || (StrEqual(oldcls,"npc_sentry_ceiling",false)))
					{
						int findsf = FindStringInArray(passedarr,"spawnflags");
						if (findsf != -1)
						{
							findsf++;
							char sfch[16];
							GetArrayString(passedarr,findsf,sfch,sizeof(sfch));
							int sf = StringToInt(sfch);
							if (sf & 65536) AcceptEntityInput(ent,"Disable");
						}
					}
					else if (StrEqual(oldcls,"npc_tentacle",false))
					{
						SetEntityMoveType(ent,MOVETYPE_FLY);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
						int find = FindValueInArray(tents,ent);
						if (find != -1)
						{
							int entmdl = GetArrayCell(tentsmdl,find);
							TeleportEntity(entmdl,fileorigin,angs,NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(entmdl,"SetParent",ent);
						}
					}
					else if (StrEqual(oldcls,"npc_human_commander",false))
					{
						SetEntProp(ent,Prop_Data,"m_fIsElite",1);
					}
					else if (StrEqual(oldcls,"npc_abrams"))
					{
						int findpath = FindStringInArray(passedarr,"target");
						if (findpath != -1)
						{
							findpath++;
							char targetpath[32];
							GetArrayString(passedarr,findpath,targetpath,sizeof(targetpath));
							int driver = CreateEntityByName("func_tracktrain");
							if (driver != -1)
							{
								DispatchKeyValue(driver,"target",targetpath);
								DispatchKeyValue(driver,"orientationtype","1");
								DispatchKeyValue(driver,"speed","80");
								//Setup for -90 (270)
								/*
								angs[0]+=90.0;
								if (angs[0] > 360.0) angs[0]-=360.0;
								angs[1]+=45.0;
								if (angs[1] > 360.0) angs[1]-=360.0;
								angs[2]-=135.0;
								if (angs[2] < -180.0) angs[2]+=360.0;
								
								if (angs[1] < 0.0) angs[1]+=360.0;
								angs[0] = angs[1]-180.0;
								if (angs[0] > 360.0) angs[0]-=360.0;
								angs[1]+=angs[1]/6.0;
								if (angs[1] > 360.0) angs[1]-=360.0;
								angs[2]-=angs[1]/2.0;
								if (angs[2] < -180.0) angs[2]+=360.0;
								*/
								DispatchSpawn(driver);
								ActivateEntity(driver);
								TeleportEntity(driver,fileorigin,angs,NULL_VECTOR);
								AcceptEntityInput(driver,"StartForward");
								//TeleportEntity(ent,NULL_VECTOR,angs,NULL_VECTOR);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",driver);
							}
						}
						float vmins[3];
						float vmaxs[3];
						GetEntPropVector(ent,Prop_Data,"m_vecMins",vmins);
						GetEntPropVector(ent,Prop_Data,"m_vecMaxs",vmaxs);
						int mainturret = CreateEntityByName("func_tank");
						if (mainturret != -1)
						{
							DispatchKeyValue(mainturret,"spawnflags","1");
							DispatchKeyValue(mainturret,"model","*1");
							DispatchKeyValue(mainturret,"yawrate","30");
							DispatchKeyValue(mainturret,"yawrange","180");
							DispatchKeyValue(mainturret,"yawtolerance","45");
							DispatchKeyValue(mainturret,"pitchtolerance","45");
							DispatchKeyValue(mainturret,"pitchrange","60");
							DispatchKeyValue(mainturret,"pitchrate","120");
							DispatchKeyValue(mainturret,"barrel","100");
							DispatchKeyValue(mainturret,"barrelz","8");
							DispatchKeyValue(mainturret,"bullet","3");
							DispatchKeyValue(mainturret,"ignoregraceupto","768");
							DispatchKeyValue(mainturret,"firerate","15");
							DispatchKeyValue(mainturret,"firespread","3");
							DispatchKeyValue(mainturret,"persistence","3");
							DispatchKeyValue(mainturret,"maxRange","2048");
							DispatchKeyValue(mainturret,"spritescale","1");
							DispatchKeyValue(mainturret,"gun_base_attach","minigun1_base");
							DispatchKeyValue(mainturret,"gun_barrel_attach","minigun1_muzzle");
							DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun1_yaw"); //aim_yaw
							//DispatchKeyValue(mainturret,"gun_pitch_pose_param","aim_pitch");
							DispatchKeyValue(mainturret,"ammo_count","-1");
							DispatchKeyValue(mainturret,"effecthandling","1");
							TeleportEntity(mainturret,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(mainturret);
							ActivateEntity(mainturret);
							SetVariantString("!activator");
							AcceptEntityInput(mainturret,"SetParent",ent);
							SetVariantString("minigun1");
							AcceptEntityInput(mainturret,"SetParentAttachment");
							SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
							SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
							SetVariantString("!player");
							AcceptEntityInput(mainturret,"SetTargetEntityName");
						}
						int turretflash = CreateEntityByName("env_muzzleflash");
						if (turretflash != -1)
						{
							DispatchKeyValue(turretflash,"scale","5");
							DispatchSpawn(turretflash);
							ActivateEntity(turretflash);
							SetVariantString("!activator");
							AcceptEntityInput(turretflash,"SetParent",ent);
							SetVariantString("muzzle");
							AcceptEntityInput(turretflash,"SetParentAttachment");
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",turretflash);
						}
						/* Do in think rpg_missile
						mainturret = CreateEntityByName("func_tankrocket");
						if (mainturret != -1)
						{
							DispatchKeyValue(mainturret,"spawnflags","1");
							DispatchKeyValue(mainturret,"model","*1");
							DispatchKeyValue(mainturret,"yawrate","30");
							DispatchKeyValue(mainturret,"yawrange","180");
							DispatchKeyValue(mainturret,"yawtolerance","45");
							DispatchKeyValue(mainturret,"pitchtolerance","45");
							DispatchKeyValue(mainturret,"pitchrange","60");
							DispatchKeyValue(mainturret,"pitchrate","120");
							DispatchKeyValue(mainturret,"barrel","0");
							DispatchKeyValue(mainturret,"barrelz","5");
							DispatchKeyValue(mainturret,"bullet","3");
							DispatchKeyValue(mainturret,"ignoregraceupto","768");
							DispatchKeyValue(mainturret,"firerate","1");
							DispatchKeyValue(mainturret,"firespread","2");
							DispatchKeyValue(mainturret,"persistence","3");
							DispatchKeyValue(mainturret,"maxRange","2048");
							DispatchKeyValue(mainturret,"spritescale","1");
							DispatchKeyValue(mainturret,"gun_base_attach","gunbase");
							DispatchKeyValue(mainturret,"gun_barrel_attach","gun");
							DispatchKeyValue(mainturret,"gun_yaw_pose_param","aim_yaw");
							DispatchKeyValue(mainturret,"gun_pitch_pose_param","aim_pitch");
							DispatchKeyValue(mainturret,"ammo_count","-1");
							DispatchKeyValue(mainturret,"effecthandling","0");
							DispatchKeyValue(mainturret,"rocketspeed","9999");
							TeleportEntity(mainturret,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(mainturret);
							ActivateEntity(mainturret);
							SetVariantString("!activator");
							AcceptEntityInput(mainturret,"SetParent",ent);
							SetVariantString("muzzle");
							AcceptEntityInput(mainturret,"SetParentAttachment");
							SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
							SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
							SetVariantString("!player");
							AcceptEntityInput(mainturret,"SetTargetEntityName");
						}
						*/
						mainturret = CreateEntityByName("func_tank");
						if (mainturret != -1)
						{
							DispatchKeyValue(mainturret,"spawnflags","1");
							DispatchKeyValue(mainturret,"model","*1");
							DispatchKeyValue(mainturret,"yawrate","30");
							DispatchKeyValue(mainturret,"yawrange","180");
							DispatchKeyValue(mainturret,"yawtolerance","45");
							DispatchKeyValue(mainturret,"pitchtolerance","45");
							DispatchKeyValue(mainturret,"pitchrange","60");
							DispatchKeyValue(mainturret,"pitchrate","120");
							DispatchKeyValue(mainturret,"barrel","100");
							DispatchKeyValue(mainturret,"barrelz","8");
							DispatchKeyValue(mainturret,"bullet","3");
							DispatchKeyValue(mainturret,"ignoregraceupto","768");
							DispatchKeyValue(mainturret,"firerate","15");
							DispatchKeyValue(mainturret,"firespread","3");
							DispatchKeyValue(mainturret,"persistence","3");
							DispatchKeyValue(mainturret,"maxRange","2048");
							DispatchKeyValue(mainturret,"spritescale","1");
							DispatchKeyValue(mainturret,"gun_base_attach","minigun2_base");
							DispatchKeyValue(mainturret,"gun_barrel_attach","minigun2_muzzle");
							DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun2_yaw");
							DispatchKeyValue(mainturret,"ammo_count","-1");
							DispatchKeyValue(mainturret,"effecthandling","1");
							TeleportEntity(mainturret,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(mainturret);
							ActivateEntity(mainturret);
							SetVariantString("!activator");
							AcceptEntityInput(mainturret,"SetParent",ent);
							SetVariantString("minigun2");
							AcceptEntityInput(mainturret,"SetParentAttachment");
							SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
							SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
							SetVariantString("!player");
							AcceptEntityInput(mainturret,"SetTargetEntityName");
						}
						//WritePackString(dp,"models/props_vehicles/abrams.mdl");
						if (HasEntProp(ent,Prop_Data,"m_iHealth"))
						{
							int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
							int maxh = 500;
							if (hchk != maxh)
							{
								SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
								SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
							}
						}
						/*
						int entmdl = CreateEntityByName("prop_dynamic");
						DispatchKeyValue(entmdl,"model","models/props_vehicles/abrams.mdl");
						DispatchKeyValue(entmdl,"solid","6");
						DispatchKeyValue(entmdl,"rendermode","10");
						TeleportEntity(entmdl,fileorigin,angs,NULL_VECTOR);
						DispatchSpawn(entmdl);
						ActivateEntity(entmdl);
						SetVariantString("!activator");
						AcceptEntityInput(entmdl,"SetParent",ent);
						*/
						SDKHookEx(ent,SDKHook_Think,abramsthink);
						//asfasf SetParentAttachment muzzle for fire cannon pos
						//minigun1_muzzle for minigun
					}
					else if (StrEqual(oldcls,"item_crate",false))
					{
						int find = FindStringInArray(passedarr,"spawnonbreak");
						if (find != -1)
						{
							char breakitems[128];
							find++;
							GetArrayString(passedarr,find,breakitems,sizeof(breakitems));
							SetEntPropString(ent,Prop_Data,"m_iszResponseContext",breakitems);
						}
					}
					else if ((StrEqual(oldcls,"env_xen_portal",false)) || (StrEqual(oldcls,"env_xen_portal_template",false)))
					{
						fileorigin[2]+=20.0;
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					else if (StrEqual(oldcls,"grenade_tripmine",false))
					{
						//TeleportEntity(ent,NULL_VECTOR,angs,NULL_VECTOR);
						/*
						int findown = FindEntityByClassname(-1,"npc_human_grunt");
						if (findown == -1) findown = FindEntityByClassname(-1,"npc_combine_s");
						if (findown == -1)
						{
							for (int i = 1;i<MaxClients+1;i++)
							{
								if (IsValidEntity(i))
									if (IsClientConnected(i))
										if (IsClientInGame(i))
										{
											findown = i;
											break;
										}
							}
						}
						SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",findown);
						SetEntProp(ent,Prop_Data,"m_MoveType",0);
						*/
						//angs[0]+=90.0;
						float loc[3];
						loc[0] = (fileorigin[0] + (20 * Cosine(DegToRad(angs[1]))));
						loc[1] = (fileorigin[1] + (20 * Sine(DegToRad(angs[1]))));
						loc[2] = fileorigin[2];
						float fhitpos[3];
						Handle hhitpos = INVALID_HANDLE;
						//if (angs[1]+180.0 > 360) angs[1]-=180.0;
						//else angs[1]+=180.0;
						TR_TraceRayFilter(loc,angs,MASK_SHOT,RayType_Infinite,TraceSlamFilter);
						TR_GetEndPosition(fhitpos,hhitpos);
						char endpointtn[32];
						char targn[32];
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							GetArrayString(passedarr,findtn,targn,sizeof(targn));
						}
						if (strlen(targn) < 1)
						{
							Format(targn,sizeof(targn),"tripmine%i",ent);
							SetEntPropString(ent,Prop_Data,"m_iName",targn);
						}
						else
						{
							Format(targn,sizeof(targn),"%s%i",targn,ent);
						}
						int endpoint = CreateEntityByName("info_target");
						if (endpoint != -1)
						{
							Format(endpointtn,sizeof(endpointtn),"%s%itargend",targn,endpoint);
							DispatchKeyValue(endpoint,"targetname",endpointtn);
							TeleportEntity(endpoint,fhitpos,angs,NULL_VECTOR);
							DispatchSpawn(endpoint);
							ActivateEntity(endpoint);
						}
						int startpoint = CreateEntityByName("info_target");
						if (startpoint != -1)
						{
							DispatchKeyValue(startpoint,"targetname",targn);
							TeleportEntity(startpoint,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(startpoint);
							ActivateEntity(startpoint);
						}
						//SetEntPropVector(ent,Prop_Data,"m_vecEnd",fhitpos);
						int beam = CreateEntityByName("env_beam");
						if (beam != -1)
						{
							DispatchKeyValue(beam,"spawnflags","1");
							DispatchKeyValue(beam,"life","0");
							DispatchKeyValue(beam,"texture","sprites/laserbeam.spr");
							DispatchKeyValue(beam,"TextureScroll","35");
							DispatchKeyValue(beam,"framerate","10");
							DispatchKeyValue(beam,"rendercolor","255 0 0");
							DispatchKeyValue(beam,"BoltWidth","0.5");
							DispatchKeyValue(beam,"LightningStart",targn);
							DispatchKeyValue(beam,"LightningEnd",endpointtn);
							DispatchKeyValue(beam,"TouchType","4");
							//DispatchKeyValue(beam,"filtername","syn_tripmine_filter");
							if ((tripminefilter = -1) || (!IsValidEntity(tripminefilter)))
							{
								tripminefilter = CreateEntityByName("filter_activator_class");
								DispatchKeyValue(tripminefilter,"filterclass","grenade_tripmine");
								DispatchKeyValue(tripminefilter,"targetname","syn_tripmine_filter");
								DispatchKeyValue(tripminefilter,"Negated","1");
								DispatchSpawn(tripminefilter);
								ActivateEntity(tripminefilter);
							}
							TeleportEntity(beam,loc,angs,NULL_VECTOR);
							DispatchSpawn(beam);
							ActivateEntity(beam);
							int expl = CreateEntityByName("env_explosion");
							if (expl != -1)
							{
								TeleportEntity(expl,loc,angs,NULL_VECTOR);
								DispatchKeyValue(expl,"imagnitude","300");
								DispatchKeyValue(expl,"iradiusoverride","250");
								DispatchKeyValue(expl,"rendermode","0");
								DispatchSpawn(expl);
								ActivateEntity(expl);
								SetEntPropEnt(beam,Prop_Data,"m_hOwnerEntity",ent);
								SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",expl);
								SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",beam);
								SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",expl);
								PushArrayCell(tripmines,ent);
								HookSingleEntityOutput(beam,"OnTouchedByEntity",EntityOutput:TripMineExpl);
							}
						}
						SDKHookEx(ent,SDKHook_OnTakeDamage,tripminetkdmg);
						/*
						//m_vecEnd
						float vecdir[3];
						if (angs[1] == 0.0)
						{
							vecdir[0] = 1.0;
							vecdir[1] = 0.0;
							vecdir[2] = 0.0;
						}
						else if (angs[1] == 90.0)
						{
							vecdir[0] = 0.0;
							vecdir[1] = 1.0;
							vecdir[2] = 0.0;
						}
						else if (angs[1] == 180.0)
						{
							vecdir[0] = -1.0;
							vecdir[1] = 0.0;
							vecdir[2] = 0.0;
						}
						else if ((angs[1] == -90.0) || (angs[1] == 270.0))
						{
							vecdir[0] = 0.0;
							vecdir[1] = -1.0;
							vecdir[2] = 0.0;
						}
						SetEntPropVector(ent,Prop_Data,"m_vecDir",vecdir);
						*/
					}
					else if (StrEqual(oldcls,"npc_apache",false))
					{
						SDKHookEx(ent,SDKHook_Think,apachethink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
					}
					else if (StrEqual(oldcls,"env_xen_portal_template",false))
					{
						if (FindValueInArray(templateslist,ent) == -1) PushArrayCell(templateslist,ent);
					}
					else if (StrEqual(oldcls,"func_minefield",false))
					{
						SetVariantString("spawnflags 1");
						AcceptEntityInput(ent,"AddOutput");
						int findminect = FindStringInArray(passedarr,"minecount");
						if (findminect != -1)
						{
							findminect++;
							char mineamntch[16];
							GetArrayString(passedarr,findminect,mineamntch,sizeof(mineamntch));
							int minecount = StringToInt(mineamntch);
							if (minecount == 1)
							{
								HookSingleEntityOutput(ent,"OnStartTouch",EntityOutput:MineFieldTouch);
							}
						}
					}
					char cvarchk[64];
					Format(cvarchk,sizeof(cvarchk),"%s_health",oldcls);
					ReplaceString(cvarchk,sizeof(cvarchk),"npc_","sk_",false);
					Handle cvar = FindConVar(cvarchk);
					if (cvar != INVALID_HANDLE)
					{
						int maxh = GetConVarInt(cvar);
						if (maxh > 0)
						{
							char maxhch[24];
							Format(maxhch,sizeof(maxhch),"%i",maxh);
							DispatchKeyValue(ent,"max_health",maxhch);
							Format(maxhch,sizeof(maxhch),"max_health %i",maxh);
							SetVariantString(maxhch);
							AcceptEntityInput(ent,"AddOutput");
							if (HasEntProp(ent,Prop_Data,"m_iHealth")) SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
							if (HasEntProp(ent,Prop_Data,"m_iMaxHealth")) SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
						}
					}
					CloseHandle(cvar);
					int findcurh = FindStringInArray(passedarr,"health");
					if (findcurh != -1)
					{
						findcurh++;
						char hsetc[8];
						GetArrayString(passedarr,findcurh,hsetc,sizeof(hsetc));
						int hset = StringToInt(hsetc);
						if (hset != 0)
						{
							if (HasEntProp(ent,Prop_Data,"m_iHealth")) SetEntProp(ent,Prop_Data,"m_iHealth",hset);
						}
					}
					AcceptEntityInput(ent,"FireUser3");
					int findtn = FindStringInArray(passedarr,"targetname");
					if (findtn != -1)
					{
						findtn++;
						char entname[32];
						GetArrayString(passedarr,findtn,entname,sizeof(entname));
						int findsf = FindStringInArray(passedarr,"spawnflags");
						if (findsf != -1)
						{
							findsf++;
							char sfch[16];
							GetArrayString(passedarr,findsf,sfch,sizeof(sfch));
							int sf = StringToInt(sfch);
							if (sf & 2048)
							{
								if (debuglvl == 3) PrintToServer("Storing template maker ent %s",entname);
								PushArrayString(templatetargs,entname);
								Handle dupearr = CloneArray(passedarr);
								PushArrayCell(templateents,dupearr);
								AcceptEntityInput(ent,"kill");
								Format(entname,sizeof(entname),"");
							}
						}
						if ((strlen(entname) > 0) && (GetArraySize(templateslist) > 0))
						{
							for (int j = 0;j<GetArraySize(templateslist);j++)
							{
								int i = GetArrayCell(templateslist,j);
								if (IsValidEntity(i))
								{
									char clschk[24];
									GetEntityClassname(i,clschk,sizeof(clschk));
									if (StrEqual(clschk,"point_template"))
									{
										char tmpchk[64];
										for (int h = 0;h<16;h++)
										{
											Format(tmpchk,sizeof(tmpchk),"m_iszTemplateEntityNames[%i]",h);
											if (HasEntProp(i,Prop_Data,tmpchk))
											{
												char templatename[32];
												GetEntPropString(i,Prop_Data,tmpchk,templatename,sizeof(templatename));
												if (StrEqual(templatename,entname))
												{
													if (debuglvl == 3) PrintToServer("%i %s ent spawn from template",ent,templatename);
													PushArrayString(templatetargs,entname);
													Handle dupearr = CloneArray(passedarr);
													PushArrayCell(templateents,dupearr);
													//Hooks too late for most sequences
													//HookSingleEntityOutput(i,"OnEntitySpawned",EntityOutput:ptspawnent);
													AcceptEntityInput(ent,"kill");
												}
											}
										}
									}
								}
							}
						}
					}
					if (GetArraySize(customrelations) > 0)
					{
						for (int i = 0;i<GetArraySize(customrelations);i++)
						{
							int j = GetArrayCell(customrelations,i);
							if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
						}
					}
					if (StrEqual(oldcls,"func_conveyor",false))
					{
						int finddir = FindStringInArray(passedarr,"direction");
						int findmdl = FindStringInArray(passedarr,"model");
						if ((finddir != -1) && (findmdl != -1))
						{
							finddir++;
							findmdl++;
							char fmdl[16];
							char fdir[64];
							GetArrayString(passedarr,finddir,fdir,sizeof(fdir));
							GetArrayString(passedarr,findmdl,fmdl,sizeof(fmdl));
							//PrintToServer("conveyorsarr %i",GetArraySize(conveyors));
							for (int i = 0;i<GetArraySize(conveyors);i++)
							{
								Handle conveydp = GetArrayCell(conveyors,i);
								if (conveydp != INVALID_HANDLE)
								{
									ResetPack(conveydp);
									int conveyor = ReadPackCell(conveydp);
									char mdl[16];
									ReadPackString(conveydp,mdl,sizeof(mdl));
									//PrintToServer("Check match %s %s",mdl,fmdl);
									if (StrEqual(mdl,fmdl))
									{
										char direxpl[16][4];
										char dirset[64];
										ExplodeString(fdir, " ", direxpl, 4, 16, true);
										Format(dirset,sizeof(dirset),"%s %s %s",direxpl[0],direxpl[1],direxpl[2]);
										float vecdir[3];
										float dirchk = StringToFloat(direxpl[1]);
										if (dirchk == 0.0)
										{
											vecdir[0] = 1.0;
											vecdir[1] = 0.0;
											vecdir[2] = 0.0;
										}
										else if (dirchk == 90.0)
										{
											vecdir[0] = 0.0;
											vecdir[1] = 1.0;
											vecdir[2] = 0.0;
										}
										else if (dirchk == 180.0)
										{
											vecdir[0] = -1.0;
											vecdir[1] = 0.0;
											vecdir[2] = 0.0;
										}
										else if ((dirchk == -90.0) || (dirchk == 270.0))
										{
											vecdir[0] = 0.0;
											vecdir[1] = -1.0;
											vecdir[2] = 0.0;
										}
										DispatchKeyValue(conveyor,"movedir",dirset);
										Format(dirset,sizeof(dirset),"movedir %s",dirset);
										SetVariantString(dirset);
										AcceptEntityInput(conveyor,"AddOutput");
										SetEntPropVector(conveyor,Prop_Data,"m_vecMoveDir",vecdir);
									}
								}
							}
						}
						//Do not actually create this
						AcceptEntityInput(ent,"kill");
					}
					ent = -1;
					passvars = false;
					createsit = false;
					ClearArray(passedarr);
					createent = false;
				}
			}
		}
		CloseHandle(passedarr);
	}
	CloseHandle(filehandle);
}

void readcacheexperimental(int client)
{
	Handle filehandle = OpenFile(mapbuf,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		Handle passedarr = CreateArray(64);
		bool createent = false;
		int ent = -1;
		float fileorigin[3];
		float angs[3];
		char kvs[128][64];
		char cls[32];
		char oldcls[32];
		bool passvars = false;
		bool createsit = false;
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			char clschk[128];
			Format(clschk,sizeof(clschk),line);
			ExplodeString(clschk, "\"", kvs, 64, 128, true);
			ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
			ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
			//if ((StrContains(line,"classname",false) != -1) && ((StrContains(line,"npc_",false) != -1) || (StrContains(line,"monster_",false) != -1) || (StrContains(line,"multi_manager",false) != -1) || (StrContains(line,"item_weapon_tripmine",false) != -1) || (StrContains(line,"prop_train_awesome",false) != -1) || (StrContains(line," item_ammo_smg1_grenade",false) != -1)))
			if ((StrContains(line,"classname",false) != -1) && ((StrContains(line,"npc_",false) != -1) || (StrContains(line,"monster_",false) != -1) || (FindStringInArray(customentlist,kvs[3]) != -1)))
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				PushArrayString(passedarr,kvs[1]);
				PushArrayString(passedarr,kvs[3]);
				int entchk = CreateEntityByName(kvs[3]);
				if (entchk == -1)
				{
					createent = true;
					Format(oldcls,sizeof(oldcls),kvs[3]);
				}
				else
				{
					createent = false;
					AcceptEntityInput(entchk,"kill");
				}
			}
			if ((!StrEqual(line,"}",false)) || (!StrEqual(line,"{",false)))
			{
				if (ent == -1) passvars = true;
				else if ((passvars) && (ent != -1))
				{
					passvars = false;
					for (int k;k<GetArraySize(passedarr);k++)
					{
						char ktmp[128];
						char ktmp2[128];
						GetArrayString(passedarr, k, ktmp, sizeof(ktmp));
						k++;
						GetArrayString(passedarr, k, ktmp2, sizeof(ktmp2));
						DispatchKeyValue(ent,ktmp,ktmp2);
					}
				}
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				if (StrEqual(kvs[1],"enemy",false)) Format(kvs[1],sizeof(kvs[]),"\"enemy\"");
				PushArrayString(passedarr,kvs[1]);
				PushArrayString(passedarr,kvs[3]);
				if (ent != -1)
				{
					DispatchKeyValue(ent,kvs[1],kvs[3]);
				}
			}
			if (StrContains(line,"\"origin\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				char origch[16][16];
				ExplodeString(tmpchar," ",origch,16,16);
				fileorigin[0] = StringToFloat(origch[0]);
				fileorigin[1] = StringToFloat(origch[1]);
				fileorigin[2] = StringToFloat(origch[2]);
			}
			if (StrContains(line,"\"angles\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"angles\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				char origch[16][16];
				ExplodeString(tmpchar," ",origch,16,16);
				angs[0] = StringToFloat(origch[0]);
				angs[1] = StringToFloat(origch[1]);
				angs[2] = StringToFloat(origch[2]);
			}
			if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)) && (ent == -1))
			{
				ClearArray(passedarr);
				passvars = true;
			}
			else if (createent)
			{
				int arrindx = FindStringInArray(passedarr,"baseclass");
				if (arrindx != -1)
				{
					char tmpchar[128];
					GetArrayString(passedarr,arrindx+1,tmpchar,sizeof(tmpchar));
					ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
					ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
					if (StrContains(kvs[3],"_",false) != -1)
					{
						Format(cls,sizeof(cls),"%s",kvs[3]);
					}
				}
				if ((ent == -1) && (strlen(cls) > 0))
				{
					if (StrEqual(cls,"worldspawn",false)) break;
					Handle dp = INVALID_HANDLE;
					char setupent[24];
					//Format(oldcls,sizeof(oldcls),"%s",cls);
					if (StrEqual(cls,"monster_headcrab",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/headcrab.mdl");
					}
					else if ((StrEqual(cls,"monster_scientist",false)) || (StrEqual(cls,"monster_scientist_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/scientist.mdl");
					}
					else if (StrEqual(cls,"monster_sitting_scientist",false))
					{
						Format(cls,sizeof(cls),"prop_dynamic");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/scientist.mdl");
						PushArrayString(passedarr,"solid");
						PushArrayString(passedarr,"6");
						PushArrayString(passedarr,"DefaultAnim");
						PushArrayString(passedarr,"sitting3");
						createsit = true;
					}
					else if ((StrEqual(cls,"monster_barney",false)) || (StrEqual(cls,"monster_barney_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/barney.mdl");
					}
					else if (StrEqual(cls,"monster_gman",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/gman.mdl");
					}
					else if (StrEqual(cls,"monster_osprey",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/osprey.mdl");
					}
					else if (StrEqual(cls,"monster_houndeye",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/houndeye.mdl");
					}
					else if (StrEqual(cls,"monster_barnacle",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/barnacle.mdl");
					}
					else if (StrEqual(cls,"monster_zombie",false))
					{
						Format(cls,sizeof(cls),"npc_zombie");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombie.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombie.mdl");
					}
					else if (StrEqual(cls,"monster_sentry",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/sentry.mdl");
					}
					else if (StrEqual(cls,"monster_alien_slave",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/islave.mdl");
					}
					else if ((StrEqual(cls,"monster_human_grunt",false)) || (StrEqual(cls,"monster_hgrunt_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/hgrunt.mdl");
					}
					else if (StrEqual(cls,"monster_cockroach",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/roach.mdl");
					}
					else if (StrEqual(cls,"monster_bullchicken",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/bullsquid.mdl");
					}
					else if (StrEqual(cls,"trigger_auto",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Trigger,,0,1");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Kill,,0.5,1");
					}
					else if (StrEqual(cls,"npc_human_security",false))
					{
						if (FindStringInArray(precachedarr,"npc_human_security") == -1)
						{
							char humansecp[128];
							Format(humansecp,sizeof(humansecp),"sound/vo/npc/barneys/");
							recursion(humansecp);
							PushArrayString(precachedarr,"npc_human_security");
						}
						int find = FindStringInArray(passedarr,"additionalequipment");
						if (find != -1)
						{
							find++;
							char addweap[32];
							GetArrayString(passedarr,find,addweap,sizeof(addweap));
							if (StrEqual(addweap,"default",false)) Format(cls,sizeof(cls),"generic_actor");
							else
							{
								Format(cls,sizeof(cls),"npc_citizen");
								PushArrayString(passedarr,"spawnflags");
								PushArrayString(passedarr,"1048576");
							}
						}
						else Format(cls,sizeof(cls),"generic_actor");
						int findsk = FindStringInArray(passedarr,"skin");
						if (findsk == -1)
						{
							PushArrayString(passedarr,"skin");
							char randsk[8];
							int rand = GetRandomInt(0,14);
							Format(randsk,sizeof(randsk),"%i",rand);
							PushArrayString(passedarr,randsk);
						}
						int mdlindx = FindStringInArray(passedarr,"model");
						if (mdlindx != -1)
						{
							mdlindx++;
							char mdlchk[128];
							GetArrayString(passedarr,mdlindx,mdlchk,sizeof(mdlchk));
							if (!FileExists(mdlchk,true,NULL_STRING))
							{
								PushArrayString(passedarr,"model");
								PushArrayString(passedarr,"models/humans/guard.mdl");
							}
						}
						Format(setupent,sizeof(setupent),"humansec");
					}
					else if (StrEqual(cls,"npc_human_scientist",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						int rand = GetRandomInt(0,1);
						if (rand == 0) PushArrayString(passedarr,"models/humans/scientist.mdl");
						else PushArrayString(passedarr,"models/humans/scientist_02.mdl");
					}
					else if (StrEqual(cls,"npc_human_scientist_female",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/scientist_female.mdl");
					}
					else if (StrEqual(cls,"npc_alien_slave",false))
					{
						Format(cls,sizeof(cls),"npc_vortigaunt");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/vortigaunt_slave.mdl");
						if (!relsetvort)
						{
							setuprelations(cls);
							relsetvort = true;
						}
					}
					else if (StrEqual(cls,"npc_human_scientist_kleiner",false))
					{
						Format(cls,sizeof(cls),"npc_kleiner");
						//PushArrayString(passedarr,"model");
						//PushArrayString(passedarr,"models/humans/scientist_kliener.mdl");
						//Model invisible?
					}
					else if (StrEqual(cls,"npc_human_scientist_eli",false))
					{
						Format(cls,sizeof(cls),"npc_eli");
						if (!IsModelPrecached("models/eli.mdl"))
						{
							if (!IsModelPrecached("models/humans/scientist_eli.mdl")) PrecacheModel("models/humans/scientist_eli.mdl",true);
							dp = CreateDataPack();
							WritePackString(dp,"models/humans/scientist_eli.mdl");
						}
					}
					else if (StrEqual(cls,"npc_zombie_security",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						Handle cvarchk = FindConVar("sk_zombie_soldier_health");
						if (GetConVarInt(cvarchk) < 6) SetConVarInt(cvarchk,100,false,false);
						CloseHandle(cvarchk);
						if (!relsetzsec)
						{
							setuprelations(cls);
							relsetzsec = true;
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_guard.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_guard.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_security_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						Handle cvarchk = FindConVar("sk_zombie_soldier_health");
						if (GetConVarInt(cvarchk) < 6) SetConVarInt(cvarchk,100,false,false);
						CloseHandle(cvarchk);
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_guard_torso.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_guard_torso.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_scientist",false))
					{
						Format(cls,sizeof(cls),"npc_zombie");
						if (!relsetzsec)
						{
							setuprelations(cls);
							relsetzsec = true;
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_sci.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_sci.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_scientist_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombie_torso");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_sci_torso.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_sci_torso.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if ((StrEqual(cls,"npc_human_grunt",false)) || (StrEqual(cls,"npc_human_commander",false)) || (StrEqual(cls,"npc_human_grenadier",false)) || (StrEqual(cls,"npc_human_medic",false)))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/marine.mdl");
					}
					else if (StrEqual(cls,"npc_osprey",false))
					{
						Format(cls,sizeof(cls),"npc_combinedropship");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/osprey.mdl");
					}
					else if (StrEqual(cls,"npc_houndeye",false))
					{
						Format(cls,sizeof(cls),"npc_antlion");
						int mdlindx = FindStringInArray(passedarr,"model");
						if (mdlindx != -1)
						{
							mdlindx++;
							char mdlchk[128];
							GetArrayString(passedarr,mdlindx,mdlchk,sizeof(mdlchk));
							if (!FileExists(mdlchk,true,NULL_STRING))
							{
								PushArrayString(passedarr,"model");
								PushArrayString(passedarr,"models/xenians/houndeye.mdl");
								PushArrayString(passedarr,"modelscale");
								PushArrayString(passedarr,"0.6");
							}
						}
						if (!relsethound)
						{
							setuprelations(cls);
							relsethound = true;
						}
						dp = CreateDataPack();
						WritePackString(dp,"models/xenians/houndeye.mdl");
						Format(setupent,sizeof(setupent),"hound");
					}
					else if (StrEqual(cls,"npc_bullsquid",false))
					{
						Format(cls,sizeof(cls),"npc_antlion");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/bullsquid.mdl");
						PushArrayString(passedarr,"modelscale");
						PushArrayString(passedarr,"0.5");
						dp = CreateDataPack();
						WritePackString(dp,"models/xenians/bullsquid.mdl");
						Format(setupent,sizeof(setupent),"squid");
					}
					else if (StrEqual(cls,"npc_sentry_ceiling",false))
					{
						Format(cls,sizeof(cls),"npc_turret_ceiling");
					}
					else if (StrEqual(cls,"env_xen_portal",false))
					{
						Format(cls,sizeof(cls),"npc_maker");
						if (FindStringInArray(precachedarr,"env_xen_portal") == -1)
						{
							PrecacheSound("BMS_objects\\portal\\portal_In_01.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_02.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_03.wav",true);
							PushArrayString(precachedarr,"env_xen_portal");
						}
					}
					else if (StrEqual(cls,"env_xen_portal_template",false))
					{
						Format(cls,sizeof(cls),"npc_template_maker");
						if (FindStringInArray(precachedarr,"env_xen_portal") == -1)
						{
							PrecacheSound("BMS_objects\\portal\\portal_In_01.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_02.wav",true);
							PrecacheSound("BMS_objects\\portal\\portal_In_03.wav",true);
							PushArrayString(precachedarr,"env_xen_portal");
						}
					}
					else if (StrEqual(cls,"multi_manager",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
					}
					else if (StrEqual(cls,"item_weapon_tripmine",false))
					{
						Format(cls,sizeof(cls),"weapon_slam");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"prop_train_awesome",false))
					{
						Format(cls,sizeof(cls),"prop_dynamic");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/oar_awesome_tram.mdl");
					}
					else if (StrEqual(cls," item_ammo_smg1_grenade",false)) //wat
					{
						Format(cls,sizeof(cls),"item_ammo_smg1_grenade");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"npc_sentry_ground",false))
					{
						Format(cls,sizeof(cls),"npc_turret_floor");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else
					{
						int clsindx = FindStringInArray(passedarr,"baseclass");
						if (clsindx != -1)
						{
							clsindx++;
							GetArrayString(passedarr,clsindx,cls,sizeof(cls));
						}
						else
						{
							if (StrContains(cls,"zombie",false) != -1) Format(cls,sizeof(cls),"npc_zombie");
							else Format(cls,sizeof(cls),"generic_actor");
						}
						bool findmdl = false;
						char mdlchk[128];
						int mdlindx = FindStringInArray(passedarr,"model");
						if (mdlindx != -1)
						{
							mdlindx++;
							GetArrayString(passedarr,mdlindx,mdlchk,sizeof(mdlchk));
							if (!FileExists(mdlchk,true,NULL_STRING))
							{
								findmdl = true;
								if (debuglvl > 0) PrintToConsole(client,"Failed to find model: \"%s\" attempting to find model.",mdlchk);
							}
						}
						if (findmdl)
						{
							Format(mdlchk,sizeof(mdlchk),"%s.mdl",oldcls);
							ReplaceStringEx(mdlchk,sizeof(mdlchk),"npc_","models/");
							ReplaceStringEx(mdlchk,sizeof(mdlchk),"monster_","models/");
							ReplaceString(mdlchk,sizeof(mdlchk),"_","/");
							if (FileExists(mdlchk,true,NULL_STRING))
							{
								PushArrayString(passedarr,"model");
								PushArrayString(passedarr,mdlchk);
							}
							else
							{
								ReplaceString(mdlchk,sizeof(mdlchk),"models/","models/npc/");
								if (FileExists(mdlchk,true,NULL_STRING))
								{
									PushArrayString(passedarr,"model");
									PushArrayString(passedarr,mdlchk);
								}
								else
								{
									if (StrContains(oldcls,"zombie",false) != -1)
									{
										ReplaceString(mdlchk,sizeof(mdlchk),"models/npc/","models/zombies/");
										if (FileExists(mdlchk,true,NULL_STRING))
										{
											PushArrayString(passedarr,"model");
											PushArrayString(passedarr,mdlchk);
										}
										ReplaceString(mdlchk,sizeof(mdlchk),"models/zombies/","models/zombie/");
										if (FileExists(mdlchk,true,NULL_STRING))
										{
											PushArrayString(passedarr,"model");
											PushArrayString(passedarr,mdlchk);
										}
									}
									else
									{
										ReplaceString(mdlchk,sizeof(mdlchk),"models/npc/","models/xenians/");
										if (FileExists(mdlchk,true,NULL_STRING))
										{
											PushArrayString(passedarr,"model");
											PushArrayString(passedarr,mdlchk);
										}
										else
										{
											Format(mdlchk,sizeof(mdlchk),"%s.mdl",oldcls);
											ReplaceStringEx(mdlchk,sizeof(mdlchk),"npc_","models/");
											ReplaceStringEx(mdlchk,sizeof(mdlchk),"monster_","models/");
											if (debuglvl > 1) PrintToConsole(client,"Run recursion on %s",oldcls);
											recursionmdl(mdlchk,"models");
											if (FileExists(mdlchk,true,NULL_STRING))
											{
												if (debuglvl > 1) PrintToConsole(client,"Found mdl %s",mdlchk);
												PushArrayString(passedarr,"model");
												PushArrayString(passedarr,mdlchk);
											}
										}
									}
								}
							}
						}
						if ((FindStringInArray(passedarr,"model") != -1) && (strlen(mdlchk) > 0))
						{
							dp = CreateDataPack();
							WritePackString(dp,mdlchk);
						}
					}
					if (((StrEqual(cls,"generic_actor",false)) || (StrEqual(cls,"monster_generic",false))) && (FindStringInArray(passedarr,"model") == -1))
					{
						//not
					}
					else
					{
						ent = CreateEntityByName(cls);
						if (StrEqual(setupent,"hound"))
						{
							SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
							PushArrayCell(hounds,ent);
							int entmdl = CreateEntityByName("prop_dynamic");
							DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
							DispatchKeyValue(entmdl,"solid","0");
							float tmpset[3];
							tmpset[2]-=5.0;
							TeleportEntity(entmdl,tmpset,NULL_VECTOR,NULL_VECTOR);
							DispatchSpawn(entmdl);
							ActivateEntity(entmdl);
							SetVariantString("!activator");
							AcceptEntityInput(entmdl,"SetParent",ent);
							PushArrayCell(houndsmdl,entmdl);
							if (FindStringInArray(precachedarr,"npc_houndeye") == -1)
							{
								PrecacheSound("npc\\houndeye\\blast1.wav",true);
								PrecacheSound("npc\\houndeye\\he_step1.wav",true);
								PrecacheSound("npc\\houndeye\\he_step2.wav",true);
								PrecacheSound("npc\\houndeye\\he_step3.wav",true);
								PrecacheSound("npc\\houndeye\\charge1.wav",true);
								PrecacheSound("npc\\houndeye\\charge2.wav",true);
								PrecacheSound("npc\\houndeye\\charge3.wav",true);
								PrecacheSound("npc\\houndeye\\die1.wav",true);
								PrecacheSound("npc\\houndeye\\pain1.wav",true);
								PrecacheSound("npc\\houndeye\\pain2.wav",true);
								PrecacheSound("npc\\houndeye\\pain3.wav",true);
								PushArrayString(precachedarr,"npc_houndeye");
							}
							SDKHookEx(ent,SDKHook_Think,houndthink);
							SDKHookEx(ent,SDKHook_OnTakeDamage,houndtkdmg);
							HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
						}	
						else if (StrEqual(setupent,"humansec",false))
						{
							if (StrEqual(cls,"npc_citizen",false))
							{
								PushArrayString(passedarr,"spawnflags");
								PushArrayString(passedarr,"1048576");
								DispatchKeyValue(ent,"spawnflags","1048576");
							}
						}
						else if (StrEqual(setupent,"squid",false))
						{
							SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
							PushArrayCell(squids,ent);
							int entmdl = CreateEntityByName("prop_dynamic");
							DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
							DispatchKeyValue(entmdl,"solid","0");
							DispatchSpawn(entmdl);
							ActivateEntity(entmdl);
							SetVariantString("!activator");
							AcceptEntityInput(entmdl,"SetParent",ent);
							PushArrayCell(squidsmdl,entmdl);
							SDKHookEx(ent,SDKHook_Think,squidthink);
							SDKHookEx(ent,SDKHook_OnTakeDamage,squidtkdmg);
							HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
						}
						else if (StrEqual(setupent,"zombie"))
						{
							SDKHookEx(ent,SDKHook_Think,zomthink);
							SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
						}
						customents = true;
						if (debuglvl > 1) PrintToConsole(client,"Created %s Ent as %s",oldcls,cls);
						if (FindValueInArray(entlist,ent) == -1)
							PushArrayCell(entlist,ent);
						if (dp != INVALID_HANDLE)
						{
							WritePackCell(dp,ent);
							CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
				if (StrEqual(line,"}",false))
				{
					DispatchSpawn(ent);
					ActivateEntity(ent);
					if (createsit) fileorigin[2]-=25.0;
					if (StrEqual(oldcls,"prop_train_awesome",false))
					{
						int find = FindStringInArray(passedarr,"parentname");
						if (find != -1)
						{
							char parentn[64];
							find++;
							GetArrayString(passedarr,find,parentn,sizeof(parentn));
							if (strlen(parentn) > 0)
							{
								SetVariantString(parentn);
								AcceptEntityInput(ent,"SetParent");
								if (HasEntProp(ent,Prop_Data,"m_hParent"))
								{
									int parentchk = GetEntPropEnt(ent,Prop_Data,"m_hParent");
									if ((parentchk != -1) && (IsValidEntity(parentchk)))
									{
										float origin[3];
										float parentangs[3];
										if (HasEntProp(parentchk,Prop_Data,"m_angRotation")) GetEntPropVector(parentchk,Prop_Data,"m_angRotation",parentangs);
										if (HasEntProp(parentchk,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(parentchk,Prop_Data,"m_vecAbsOrigin",origin);
										else if (HasEntProp(parentchk,Prop_Send,"m_vecOrigin")) GetEntPropVector(parentchk,Prop_Send,"m_vecOrigin",origin);
										parentangs[1]+=90.0;
										AcceptEntityInput(ent,"ClearParent");
										SetVariantString("spawnflags 641");
										AcceptEntityInput(parentchk,"AddOutput");
										origin[0]-=1.0;
										origin[1]-=2.0;
										origin[2]-=35.0;
										TeleportEntity(ent,origin,parentangs,NULL_VECTOR);
										SetVariantString(parentn);
										AcceptEntityInput(ent,"SetParent");
									}
								}
							}
						}
					}
					else
						TeleportEntity(ent,fileorigin,angs,NULL_VECTOR);
					if (StrEqual(oldcls,"npc_sentry_ground",false))
					{
						int findsf = FindStringInArray(passedarr,"spawnflags");
						if (findsf != -1)
						{
							findsf++;
							char sfch[16];
							GetArrayString(passedarr,findsf,sfch,sizeof(sfch));
							int sf = StringToInt(sfch);
							if (sf & 65536) AcceptEntityInput(ent,"Disable");
						}
					}
					char cvarchk[32];
					Format(cvarchk,sizeof(cvarchk),"%s_health",oldcls);
					ReplaceString(cvarchk,sizeof(cvarchk),"npc_","sk_",false);
					Handle cvar = FindConVar(cvarchk);
					if (cvar != INVALID_HANDLE)
					{
						int maxh = GetConVarInt(cvar);
						if (maxh > 0)
						{
							char maxhch[8];
							Format(maxhch,sizeof(maxhch),"%i",maxh);
							DispatchKeyValue(ent,"max_health",maxhch);
							if (HasEntProp(ent,Prop_Data,"m_iHealth")) SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
							if (HasEntProp(ent,Prop_Data,"m_iMaxHealth")) SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
						}
					}
					CloseHandle(cvar);
					AcceptEntityInput(ent,"FireUser3");
					int enindx = FindStringInArray(passedarr,"\"enemy\"");
					if (enindx != -1)
					{
						enindx++;
						char enval[4];
						GetArrayString(passedarr,enindx,enval,sizeof(enval));
						char targn[64];
						int targnindx = FindStringInArray(passedarr,"targetname");
						if (targnindx != -1)
						{
							targnindx++;
							GetArrayString(passedarr,targnindx,targn,sizeof(targn));
						}
						if (StrEqual(enval,"1",false))
							addht(oldcls,targn);
						else
							addli(oldcls,targn);
					}
					Handle dp = INVALID_HANDLE;
					bool findmdl = false;
					char mdlchk[128];
					int mdlindx = FindStringInArray(passedarr,"model");
					if (mdlindx != -1)
					{
						mdlindx++;
						GetArrayString(passedarr,mdlindx,mdlchk,sizeof(mdlchk));
						if (!FileExists(mdlchk,true,NULL_STRING))
						{
							findmdl = true;
							if (debuglvl > 0) PrintToConsole(client,"Failed to find model: \"%s\" attempting to find model.",mdlchk);
						}
					}
					if (findmdl)
					{
						Format(mdlchk,sizeof(mdlchk),"%s.mdl",oldcls);
						ReplaceStringEx(mdlchk,sizeof(mdlchk),"npc_","models/");
						ReplaceStringEx(mdlchk,sizeof(mdlchk),"monster_","models/");
						ReplaceString(mdlchk,sizeof(mdlchk),"_","/");
						if (FileExists(mdlchk,true,NULL_STRING))
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,mdlchk);
						}
						else
						{
							ReplaceString(mdlchk,sizeof(mdlchk),"models/","models/npc/");
							if (FileExists(mdlchk,true,NULL_STRING))
							{
								PushArrayString(passedarr,"model");
								PushArrayString(passedarr,mdlchk);
							}
							else
							{
								if (StrContains(oldcls,"zombie",false) != -1)
								{
									ReplaceString(mdlchk,sizeof(mdlchk),"models/npc/","models/zombies/");
									if (FileExists(mdlchk,true,NULL_STRING))
									{
										PushArrayString(passedarr,"model");
										PushArrayString(passedarr,mdlchk);
									}
									ReplaceString(mdlchk,sizeof(mdlchk),"models/zombies/","models/zombie/");
									if (FileExists(mdlchk,true,NULL_STRING))
									{
										PushArrayString(passedarr,"model");
										PushArrayString(passedarr,mdlchk);
									}
								}
								else
								{
									ReplaceString(mdlchk,sizeof(mdlchk),"models/npc/","models/xenians/");
									if (FileExists(mdlchk,true,NULL_STRING))
									{
										PushArrayString(passedarr,"model");
										PushArrayString(passedarr,mdlchk);
									}
									else
									{
										Format(mdlchk,sizeof(mdlchk),"%s.mdl",oldcls);
										ReplaceStringEx(mdlchk,sizeof(mdlchk),"npc_","models/");
										ReplaceStringEx(mdlchk,sizeof(mdlchk),"monster_","models/");
										if (debuglvl > 1) PrintToConsole(client,"Run recursion on %s",oldcls);
										recursionmdl(mdlchk,"models");
										if (FileExists(mdlchk,true,NULL_STRING))
										{
											if (debuglvl > 1) PrintToConsole(client,"Found mdl %s",mdlchk);
											PushArrayString(passedarr,"model");
											PushArrayString(passedarr,mdlchk);
										}
									}
								}
							}
						}
					}
					if ((FindStringInArray(passedarr,"model") != -1) && (strlen(mdlchk) > 0))
					{
						dp = CreateDataPack();
						WritePackString(dp,mdlchk);
					}
					else if (FindStringInArray(passedarr,"model") == -1)
					{
						if (debuglvl > 0) PrintToConsole(client,"Unable to determine model for entity: %s",oldcls);
					}
					if (dp != INVALID_HANDLE)
					{
						WritePackCell(dp,ent);
						CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
					ent = -1;
					passvars = false;
					createsit = false;
					ClearArray(passedarr);
					createent = false;
				}
			}
		}
		CloseHandle(passedarr);
	}
	else
	{
		PrintToConsole(client,"Unable to find entity cache, the map may have been renamed from the original, or an ent cache was never generated. Create an edt or rename this map to its original name.");
	}
	CloseHandle(filehandle);
}

void houndthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int mdlarr = FindValueInArray(hounds,entity);
			if (mdlarr != -1)
			{
				int houndmdl = GetArrayCell(houndsmdl,mdlarr);
				if (IsValidEntity(houndmdl))
				{
					if (HasEntProp(entity,Prop_Data,"m_nSequence"))
					{
						int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
						float Time = GetTickedTime();
						if ((isattacking[entity]) && (centnextatk[entity] > Time))
						{
							if ((IsValidEntity(matmod)) && (matmod != 0) && (matmod != -1))
							{
								char charge[8];
								Format(charge,sizeof(charge),"%i",RoundFloat(centnextatk[entity]-Time*50.0));
								SetVariantString(charge);
								AcceptEntityInput(matmod,"SetMaterialVar");
							}
							else if (matmod == -1)
							{
								matmod = CreateEntityByName("material_modify_control");
								if (matmod == -1) matmod = 0;
								else
								{
									int propstat = CreateEntityByName("prop_dynamic");
									DispatchKeyValue(propstat,"rendermode","10");
									DispatchKeyValue(propstat,"renderfx","5");
									DispatchKeyValue(propstat,"targetname","syn_matmodprop");
									DispatchKeyValue(propstat,"model","models/xenians/houndeye.mdl");
									DispatchKeyValue(propstat,"solid","0");
									DispatchSpawn(propstat);
									ActivateEntity(propstat);
									DispatchKeyValue(matmod,"targetname","syn_matmodmod");
									DispatchKeyValue(matmod,"materialName","models/xenians/houndeye/houndeye.vmt");
									DispatchKeyValue(matmod,"materialVar","$selfillumtint");
									DispatchSpawn(matmod);
									ActivateEntity(matmod);
									SetVariantString("!activator");
									AcceptEntityInput(matmod,"SetParent",propstat);
									SetVariantString("Attachment1");
									AcceptEntityInput(matmod,"SetParentAttachment");
								}
							}
						}
						if ((targ != -1) && (IsValidEntity(targ)) && (!isattacking[entity]) && (centnextatk[entity] < Time))
						{
							float curorg[3];
							float enorg[3];
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
							if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
							else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
							float chkdist = GetVectorDistance(curorg,enorg,false);
							if (chkdist < 120.0)
							{
								SetEntPropEnt(entity,Prop_Data,"m_hEnemy",-1);
								SetVariantString("attack");
								AcceptEntityInput(houndmdl,"SetAnimation");
								SetVariantString("nullfil");
								AcceptEntityInput(entity,"SetEnemyFilter");
								SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
								SetEntProp(houndmdl,Prop_Data,"m_nRenderFX",0);
								//SetEntityRenderMode(entity,RENDER_NONE);
								//SetEntityRenderMode(houndmdl,RENDER_NORMAL);
								isattacking[entity] = true;
								centnextatk[entity] = Time+2.0;
								int rand = GetRandomInt(1,3);
								char snd[64];
								Format(snd,sizeof(snd),"npc\\houndeye\\charge%i.wav",rand);
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								CreateTimer(1.6,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
								if ((IsValidEntity(matmod)) && (matmod != 0) && (matmod != -1))
								{
									SetVariantString("0");
									AcceptEntityInput(matmod,"SetMaterialVar");
								}
							}
						}
						int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
						int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
						if ((seq == 0) && (statechk == 3)) SetEntProp(entity,Prop_Data,"m_NPCState",2);
						if (seq == 0)
						{
							if (!isattacking[entity])
							{
								SetVariantString("idle4");
								AcceptEntityInput(houndmdl,"SetAnimation");
							}
							SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
							SetEntProp(houndmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(houndmdl,RENDER_NORMAL);
						}
						else if (!isattacking[entity])
						{
							int seqmdl = GetEntProp(houndmdl,Prop_Data,"m_nSequence");
							if (seqmdl != seq)
							{
								SetEntProp(houndmdl,Prop_Data,"m_nSequence",seq);
							}
							SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
							SetEntProp(houndmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(houndmdl,RENDER_NORMAL);
						}
						if ((seq == 2) && (!isattacking[entity]) && (centnextatk[entity] < Time))
						{
							int rand = GetRandomInt(1,3);
							centnextatk[entity] = Time+0.1;
							char snd[64];
							Format(snd,sizeof(snd),"npc\\houndeye\\he_step%i.wav",rand);
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						}
					}
				}
			}
		}
	}
}

public Action houndtkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
			if (damage > curh)
			{
				EmitSoundToAll("npc\\houndeye\\die1.wav", victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
			else if (damage > 1)
			{
				int rand = GetRandomInt(0,5);
				switch(rand)
				{
					case 1:
					{
						EmitSoundToAll("npc\\houndeye\\pain1.wav", victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					case 2:
					{
						EmitSoundToAll("npc\\houndeye\\pain2.wav", victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					case 3:
					{
						EmitSoundToAll("npc\\houndeye\\pain3.wav", victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action resetatk(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		SetVariantString("");
		AcceptEntityInput(entity,"SetEnemyFilter");
		float curorg[3];
		if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
		else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"npc_houndeye",false))
		{
			TE_SetupBeamRingPoint(curorg,-1.0,200.0,mdlus,mdlus3,0,5,0.5,2.0,1.0,{255, 255, 255, 255},255,FBEAM_SOLID);
			TE_SendToAll(0.0);
			EmitSoundToAll("npc\\houndeye\\blast1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			float damageForce[3];
			float dmgset = 20.0;
			float dmgforce = 40.0;
			if ((IsValidEntity(matmod)) && (matmod != 0) && (matmod != -1))
			{
				SetVariantString("0");
				AcceptEntityInput(matmod,"SetMaterialVar");
			}
			Handle houndblast = FindConVar("sk_houndeye_blast_dmg");
			if (houndblast != INVALID_HANDLE)
				dmgset = GetConVarFloat(houndblast);
			CloseHandle(houndblast);
			Handle houndblastf = FindConVar("sk_houndeye_blast_force");
			if (houndblastf != INVALID_HANDLE)
				dmgforce = GetConVarFloat(houndblastf);
			CloseHandle(houndblastf);
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			for (int i = 1; i<GetMaxEntities(); i++)
			{
				if (IsValidEntity(i) && IsEntNetworkable(i))
				{
					char clsname[32];
					GetEntityClassname(i,clsname,sizeof(clsname));
					if (((!StrEqual(clsname,"npc_houndeye",false)) && (!StrEqual(clsname,"npc_bullsquid",false)) && (!StrEqual(clsname,"npc_gargantua",false)) && (!StrEqual(clsname,"npc_snark",false)) && (!StrEqual(clsname,"npc_alien_slave",false)) && (!StrEqual(clsname,"npc_tentacle",false))) && ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_dynamic",false) != -1) || (StrContains(clsname,"prop_physics",false) != -1)))
					{
						float entpos[3];
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						float chkdist = GetVectorDistance(entpos,curorg,false);
						if ((RoundFloat(chkdist) < 150) && (IsValidEntity(i)))
						{
							SDKHooks_TakeDamage(i,entity,entity,dmgset,DMG_BLAST,-1,damageForce,curorg);
						}
					}
					else if (StrEqual(clsname,"player",false))
					{
						float entpos[3];
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
						float chkdist = GetVectorDistance(entpos,curorg,false);
						if ((RoundFloat(chkdist) < 150) && (IsValidEntity(i)) && (IsPlayerAlive(i)))
						{
							SDKHooks_TakeDamage(i,entity,entity,dmgset,DMG_BLAST,-1,damageForce,curorg);
						}
					}
				}
			}
		}
		else if (StrEqual(cls,"npc_tentacle"))
		{
			int find = FindValueInArray(tents,entity);
			if (find != -1)
			{
				int entmdl = GetArrayCell(tentsmdl,find);
				//isattacking[entmdl] = seq;
				float tiporg[3];
				int sndtarg = GetArrayCell(tentssnd,find);
				if (HasEntProp(sndtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(sndtarg,Prop_Data,"m_vecAbsOrigin",tiporg);
				else if (HasEntProp(sndtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(sndtarg,Prop_Send,"m_vecOrigin",tiporg);
				float angs[3];
				float loc[3];
				if (HasEntProp(entmdl,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entmdl,Prop_Data,"m_angAbsRotation",angs);
				loc[0] = (tiporg[0] + (90 * Cosine(DegToRad(angs[1]))));
				loc[1] = (tiporg[1] + (90 * Sine(DegToRad(angs[1]))));
				loc[2] = (tiporg[2] - 45);
				int endpoint = CreateEntityByName("env_explosion");
				TeleportEntity(endpoint,loc,NULL_VECTOR,NULL_VECTOR);
				DispatchKeyValue(endpoint,"imagnitude","300");
				DispatchKeyValue(endpoint,"targetname","syn_tentacleblast");
				DispatchKeyValue(endpoint,"iradiusoverride","150");
				DispatchKeyValue(endpoint,"rendermode","0");
				DispatchKeyValue(endpoint,"spawnflags","9084");
				DispatchSpawn(endpoint);
				ActivateEntity(endpoint);
				AcceptEntityInput(endpoint,"Explode");
			}
		}
		else if (StrEqual(cls,"npc_alien_slave"))
		{
			SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
			if ((isattacking[entity] != -1) && (IsValidEntity(isattacking[entity])))
			{
				float meleedmg = 10.0;
				Handle cvarchk = FindConVar("sk_alien_slave_dmg_claw");
				if (cvarchk != INVALID_HANDLE)
					meleedmg = GetConVarFloat(cvarchk);
				CloseHandle(cvarchk);
				float damageForce[3];
				float dmgforce = 10.0;
				damageForce[0] = dmgforce;
				damageForce[1] = dmgforce;
				damageForce[2] = dmgforce;
				SDKHooks_TakeDamage(isattacking[entity],entity,entity,meleedmg,DMG_CLUB,-1,damageForce,curorg);
			}
		}
		else if (StrEqual(cls,"rpg_missile",false))
		{
			SetEntProp(entity,Prop_Data,"m_nRenderMode",0);
		}
	}
	isattacking[entity] = false;
}

void squidthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int mdlarr = FindValueInArray(squids,entity);
			if (mdlarr != -1)
			{
				int entmdl = GetArrayCell(squidsmdl,mdlarr);
				if ((IsValidEntity(entmdl)) && (HasEntProp(entity,Prop_Data,"m_nSequence")))
				{
					int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
					float Time = GetTickedTime();
					int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
					int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
					if ((seq == 0) && (statechk == 3)) SetEntProp(entity,Prop_Data,"m_NPCState",2);
					if (!isattacking[entity])
					{
						int seqmdl = GetEntProp(entmdl,Prop_Data,"m_nSequence");
						if (seqmdl != seq)
						{
							SetEntProp(entmdl,Prop_Data,"m_nSequence",seq);
							switch(seq)
							{
								case 1:
								{
									SetVariantString("run");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 2:
								{
									SetVariantString("walk");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 3:
								{
									SetVariantString("turnL");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 4:
								{
									SetVariantString("turnR");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 5:
								{
									SetVariantString("turn180");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 6:
								{
									SetVariantString("idle");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 7:
								{
									SetVariantString("idle2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 8:
								{
									SetVariantString("idle3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 9:
								{
									SetVariantString("idle_combat");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 10:
								{
									SetVariantString("eat");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 11:
								{
									SetVariantString("spin_whip");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 12:
								{
									SetVariantString("bite");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 13:
								{
									SetVariantString("bite2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 14:
								{
									SetVariantString("range");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
							}
						}
						SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
						SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
						//SetEntityRenderMode(entity,RENDER_NONE);
						//SetEntityRenderMode(entmdl,RENDER_NORMAL);
					}
					if ((targ != -1) && (IsValidEntity(targ)) && (!isattacking[entity]) && (centnextatk[entity] < Time))
					{
						float curorg[3];
						float enorg[3];
						if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
						if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
						else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
						float chkdist = GetVectorDistance(curorg,enorg,false);
						float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
						float whiprange = 135.0;
						float biterange = 76.0;
						float spitrange = 1000.0;
						Handle cvarchk = FindConVar("sk_bullsquid_whip_range");
						if (cvarchk != INVALID_HANDLE)
							whiprange = GetConVarFloat(cvarchk);
						cvarchk = FindConVar("sk_bullsquid_bite_range");
						if (cvarchk != INVALID_HANDLE)
							biterange = GetConVarFloat(cvarchk);
						cvarchk = FindConVar("sk_bullsquid_spit_range");
						if (cvarchk != INVALID_HANDLE)
							spitrange = GetConVarFloat(cvarchk);
						CloseHandle(cvarchk);
						if (chkdist <= biterange)
						{
							int rand = GetRandomInt(0,1);
							if (rand == 0)
							{
								SetVariantString("bite");
								AcceptEntityInput(entmdl,"SetAnimation");
							}
							else
							{
								SetVariantString("bite2");
								AcceptEntityInput(entmdl,"SetAnimation");
							}
							//SetVariantString("nullfil");
							//AcceptEntityInput(entity,"SetEnemyFilter");
							SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
							SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(entmdl,RENDER_NORMAL);
							isattacking[entity] = true;
							centnextatk[entity] = Time+0.5;
							float damageForce[3];
							float dmgset = 25.0;
							float dmgforce = 20.0;
							Handle squidbite = FindConVar("sk_bullsquid_bite_dmg");
							if (squidbite != INVALID_HANDLE)
								dmgset = GetConVarFloat(squidbite);
							CloseHandle(squidbite);
							damageForce[0] = dmgforce;
							damageForce[1] = dmgforce;
							damageForce[2] = dmgforce;
							SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
							CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (chkdist <= whiprange)
						{
							SetVariantString("spin_whip");
							AcceptEntityInput(entmdl,"SetAnimation");
							//SetVariantString("nullfil");
							//AcceptEntityInput(entity,"SetEnemyFilter");
							SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
							SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(entmdl,RENDER_NORMAL);
							isattacking[entity] = true;
							centnextatk[entity] = Time+0.5;
							float damageForce[3];
							float dmgset = 35.0;
							float dmgforce = 450.0;
							Handle squidwhip = FindConVar("sk_bullsquid_whip_dmg");
							if (squidwhip != INVALID_HANDLE)
								dmgset = GetConVarFloat(squidwhip);
							CloseHandle(squidwhip);
							Handle squidforce = FindConVar("sk_bullsquid_whip_force");
							if (squidforce != INVALID_HANDLE)
								dmgforce = GetConVarFloat(squidforce);
							CloseHandle(squidforce);
							damageForce[0] = dmgforce;
							damageForce[1] = dmgforce;
							damageForce[2] = dmgforce;
							SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
							CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
						}
						else if ((chkdist <= spitrange) && (chkdist > 300.0) && (lastsaw > lastseen[entity]))
						{
							lastseen[entity] = lastsaw;
							SetVariantString("range");
							AcceptEntityInput(entmdl,"SetAnimation");
							//SetVariantString("nullfil");
							//AcceptEntityInput(entity,"SetEnemyFilter");
							SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
							SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(entmdl,RENDER_NORMAL);
							isattacking[entity] = true;
							centnextatk[entity] = Time+2.0;
							float dmgset = 5.0;
							Handle spitdmg = FindConVar("sk_bullsquid_spit_dmg");
							if (spitdmg != INVALID_HANDLE)
								dmgset = GetConVarFloat(spitdmg);
							CloseHandle(spitdmg);
							float angs[3];
							float loc[3];
							if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
							for (int i = 0;i<3;i++)
							{
								int randpos = GetRandomInt(70,80);
								loc[0] = (curorg[0] + (randpos * Cosine(DegToRad(angs[1]))));
								loc[1] = (curorg[1] + (randpos * Sine(DegToRad(angs[1]))));
								loc[2] = (curorg[2] + 25);
								float shootvel[3];
								MakeVectorFromPoints(loc,enorg,shootvel);
								float randheight = GetRandomFloat(50.0,80.0);
								//if (shootvel[2] < 0.0) shootvel[2]+=randheight;
								shootvel[2]+=randheight;
								float randscale = GetRandomFloat(2.0,5.0);
								ScaleVector(shootvel,randscale);
								int spitball = CreateEntityByName("grenade_spit");
								if (spitball != -1)
								{
									if (!FileExists("models/spitball_large.mdl",true,NULL_STRING)) DispatchKeyValue(spitball,"RenderMode","10");
									DispatchSpawn(spitball);
									ActivateEntity(spitball);
									SetEntPropEnt(spitball,Prop_Data,"m_hThrower",entity);
									SetEntPropFloat(spitball,Prop_Data,"m_flDamage",dmgset);
									TeleportEntity(spitball,loc,angs,shootvel);
								}
							}
							CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
}

public Action squidtkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((IsValidEntity(victim)) && (IsValidEntity(attacker)))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			if (IsEntNetworkable(attacker))
			{
				char clschk[24];
				GetEntityClassname(attacker,clschk,sizeof(clschk));
				if (StrEqual(clschk,"grenade_spit",false))
				{
					int ownent = GetEntPropEnt(attacker,Prop_Data,"m_hThrower");
					if (ownent == victim)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
					else if ((IsValidEntity(ownent)) && (IsEntNetworkable(ownent)))
					{
						GetEntityClassname(ownent,clschk,sizeof(clschk));
						if (StrEqual(clschk,"npc_bullsquid",false))
						{
							damage = 0.0;
							return Plugin_Changed;
						}
					}
				}
				else if ((attacker == victim) || (StrEqual(clschk,"npc_bullsquid",false)))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

void snarkthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				float curorg[3];
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				float jumprange = 200.0;
				if ((chkdist <= jumprange) && (lastsaw > lastseen[entity]))
				{
					isattacking[entity] = true;
					lastseen[entity] = lastsaw;
					float shootvel[3];
					curorg[2]+=0.1;
					MakeVectorFromPoints(curorg,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,8.0);
					TeleportEntity(entity,curorg,angs,shootvel);
					CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					int rand = GetRandomInt(1,3);
					char snd[64];
					Format(snd,sizeof(snd),"npc\\snark\\deploy%i.wav",rand);
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
			}
		}
	}
}

public Action StartTouchSnark(int entity, int other)
{
	if ((IsValidEntity(other)) && (isattacking[entity]))
	{
		float damageForce[3];
		float dmgset = 5.0;
		float dmgforce = 5.0;
		damageForce[0] = dmgforce;
		damageForce[1] = dmgforce;
		damageForce[2] = dmgforce;
		SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_CLUB,-1,damageForce);
		int rand = GetRandomInt(1,5);
		char snd[64];
		Format(snd,sizeof(snd),"npc\\snark\\bite0%i.wav",rand);
		int pitchshift = 100+(10*timesattacked[entity]);
		EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, pitchshift);
		if (timesattacked[entity] >= 10)
		{
			timesattacked[entity] = 0;
			Format(snd,sizeof(snd),"npc\\snark\\blast1.wav");
			EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			SetVariantInt(0);
			AcceptEntityInput(entity,"SetHealth");
		}
		else timesattacked[entity]++;
	}
}

void ichythink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int scripting = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
			if ((!IsValidEntity(scripting)) || (scripting == 0))
			{
				float Time = GetTickedTime();
				int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
				int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
				float curorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				if ((!IsValidEntity(isattacking[entity])) || (isattacking[entity] == 0))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					int prop = CreateEntityByName("prop_dynamic");
					if (prop != -1)
					{
						//Massive hitbox in certain directions makes this unusable
						//if ((StrContains(mapbuf,"bm_c",false) != -1) && (FileExists("models/xenians/ichthyosaur.mdl",true,NULL_STRING)))
						//{
						//	if (!IsModelPrecached("models/xenians/ichthyosaur.mdl")) PrecacheModel("models/xenians/ichthyosaur.mdl",true);
						//	DispatchKeyValue(prop,"model","models/xenians/ichthyosaur.mdl");
						//	SetEntityModel(entity,"models/xenians/ichthyosaur.mdl");
						//}
						DispatchKeyValue(prop,"model","models/ichthyosaur.mdl");
						DispatchKeyValue(prop,"solid","0");
						DispatchKeyValue(prop,"DefaultAnim","swim");
						TeleportEntity(prop,curorg,angs,NULL_VECTOR);
						DispatchSpawn(prop);
						ActivateEntity(prop);
						isattacking[entity] = prop;
						SetVariantString("!activator");
						AcceptEntityInput(prop,"SetParent",entity);
						SetEntityMoveType(entity,MOVETYPE_FLYGRAVITY);
					}
				}
				int propseq = GetEntProp(isattacking[entity],Prop_Data,"m_nSequence");
				if ((propseq != seq) && (seq != 0))
				{
					SetEntProp(isattacking[entity],Prop_Data,"m_nSequence",seq);
				}
				else if ((seq == 0) && (propseq != 1))
				{
					SetVariantString("swim");
					AcceptEntityInput(isattacking[entity],"SetAnimation");
				}
				if (IsValidEntity(targ))
				{
					if (HasEntProp(targ,Prop_Data,"m_nWaterLevel"))
					{
						int waterlv = GetEntProp(targ,Prop_Data,"m_nWaterLevel");
						if (waterlv == 0)
						{
							targ = -1;
							SetEntPropEnt(entity,Prop_Data,"m_hEnemy",-1);
						}
					}
				}
				if (IsValidEntity(targ))
				{
					float enorg[3];
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
					else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
					float shootvel[3];
					MakeVectorFromPoints(curorg,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=0.5;
					else shootvel[2]-=0.5;
					//ScaleVector(shootvel,1.0);
					TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
				}
				else
				{
					int waterlv = GetEntProp(entity,Prop_Data,"m_nWaterLevel");
					if (waterlv == 2)
					{
						angs[0]+=10.0;
						if (centnextatk[entity] < Time)
						{
							if (FileExists("sound\\npc\\ichthyosaur\\watermove3.wav",true,NULL_STRING))
							{
								int randsnd = GetRandomInt(1,3);
								char snd[64];
								Format(snd,sizeof(snd),"npc\\ichthyosaur\\watermove%i.wav",randsnd);
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
								centnextatk[entity] = Time+1.5;
							}
						}
					}
					float fhitpos[3];
					Handle hhitpos = INVALID_HANDLE;
					int rand = GetRandomInt(1,4);
					if (rand == 1) angs[1]+=45.0;
					else if (rand == 2) angs[1]-=45.0;
					TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
					TR_GetEndPosition(fhitpos,hhitpos);
					float chkdist = GetVectorDistance(curorg,fhitpos,false);
					if (chkdist < 50.0)
					{
						angs[1]+=90.0;
						TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
						TR_GetEndPosition(fhitpos,hhitpos);
						chkdist = GetVectorDistance(curorg,fhitpos,false);
						if (chkdist < 50.0)
						{
							angs[1]+=90.0;
							TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
							TR_GetEndPosition(fhitpos,hhitpos);
							chkdist = GetVectorDistance(curorg,fhitpos,false);
							if (chkdist < 50.0)
							{
								angs[1]+=90.0;
								TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
								TR_GetEndPosition(fhitpos,hhitpos);
							}
						}
					}
					float shootvel[3];
					MakeVectorFromPoints(curorg,fhitpos,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=0.25;
					else shootvel[2]-=0.25;
					//ScaleVector(shootvel,1.0);
					TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
				}
				if (centnextatk[entity] < Time)
				{
					if (FileExists("sound\\npc\\ichthyosaur\\underwatermove3.wav",true,NULL_STRING))
					{
						int randsnd = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\ichthyosaur\\underwatermove%i.wav",randsnd);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						centnextatk[entity] = Time+2.0;
					}
					else if (FileExists("sound\\npc\\ichthyosaur\\water_breath.wav",true,NULL_STRING))
					{
						char snd[64];
						Format(snd,sizeof(snd),"npc\\ichthyosaur\\water_breath.wav");
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						centnextatk[entity] = Time+7.0;
					}
				}
			}
		}
	}
}

public bool TraceIchyFilter(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if (StrEqual(clsname,"npc_ichthyosaur",false))
			return false;
	}
	return true;
}

public bool TraceSlamFilter(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if (StrEqual(clsname,"grenade_tripmine",false))
			return false;
	}
	return true;
}

void aslavethink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float meleerange = 75.0;
				Handle cvarchk = FindConVar("sk_alien_slave_claw_range");
				if (cvarchk != INVALID_HANDLE)
					meleerange = GetConVarFloat(cvarchk);
				CloseHandle(cvarchk);
				float targvec[3];
				MakeVectorFromPoints(curorg,enorg,targvec);
				float toang[3];
				GetVectorAngles(targvec,toang);
				bool withinradius = false;
				if (angs[1] > toang[1])
				{
					if ((angs[1]-toang[1] > 180) && (angs[1]-toang[1] < 220)) withinradius = false;
					else if ((toang[1]-angs[1] < -180) && (toang[1]-angs[1] > -220)) withinradius = false;
					else withinradius = true;
				}
				else if (toang[1] > angs[1])
				{
					if ((toang[1]-angs[1] > 180) && (toang[1]-angs[1] < 220)) withinradius = false;
					else if ((angs[1]-toang[1] < -180) && (angs[1]-toang[1] > -220)) withinradius = false;
					else withinradius = true;
				}
				if ((chkdist <= meleerange) && (seq != 40) && (withinradius))
				{
					SetVariantString("nullfil");
					AcceptEntityInput(entity,"SetEnemyFilter");
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((!IsValidEntity(propset)) || (propset == 0))
					{
						int propshow = CreateEntityByName("prop_dynamic");
						if (propshow != -1)
						{
							DispatchKeyValue(propshow,"solid","0");
							DispatchKeyValue(propshow,"model","models/vortigaunt_slave.mdl");
							DispatchKeyValue(propshow,"DefaultAnim","MeleeHigh3");
							TeleportEntity(propshow,curorg,angs,NULL_VECTOR);
							DispatchSpawn(propshow);
							ActivateEntity(propshow);
							SetVariantString("!activator");
							AcceptEntityInput(propshow,"SetParent",entity);
							int rand = GetRandomInt(36,40);
							if (rand == 40) rand = 62;
							SetEntProp(propshow,Prop_Data,"m_nSequence",rand);
							float tmp;
							tmp+=propshow;
							centlastang[entity] = tmp;
						}
					}
					isattacking[entity] = targ;
					centnextatk[entity] = Time+1.0;
					CreateTimer(0.7,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					//Seq 36 - 39 || 62
				}
				else
				{
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((IsValidEntity(propset)) && (propset != 0))
					{
						char clschk[24];
						GetEntityClassname(propset,clschk,sizeof(clschk));
						if (StrEqual(clschk,"prop_dynamic",false))
							AcceptEntityInput(propset,"kill");
						centlastang[entity] = 0.0;
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
				}
			}
			else if ((isattacking[entity]) && (centnextatk[entity] > Time))
			{
				SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
				/*
				int propset;
				if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
				if ((IsValidEntity(propset)) && (propset != 0))
				{
					char clschk[24];
					GetEntityClassname(propset,clschk,sizeof(clschk));
					if (StrEqual(clschk,"prop_dynamic",false))
						AcceptEntityInput(propset,"kill");
					centlastang[entity] = 0.0;
				}
				*/
			}
		}
	}
}

void agruntthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
			if ((seq == 0) && (statechk == 3)) SetEntProp(entity,Prop_Data,"m_NPCState",2);
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				float meleerange = 75.0;
				float jumprange = 166.0;
				float hornetminrange = 256.0;
				float hornetmaxrange = 2048.0;
				Handle cvarchk = FindConVar("sk_alien_grunt_melee_range");
				if (cvarchk != INVALID_HANDLE)
					meleerange = GetConVarFloat(cvarchk);
				cvarchk = FindConVar("sk_alien_grunt_melee_jump_range");
				if (cvarchk != INVALID_HANDLE)
					jumprange = GetConVarFloat(cvarchk);
				cvarchk = FindConVar("sk_alien_grunt_hornet_min_range");
				if (cvarchk != INVALID_HANDLE)
					hornetminrange = GetConVarFloat(cvarchk);
				cvarchk = FindConVar("sk_alien_grunt_hornet_max_range");
				if (cvarchk != INVALID_HANDLE)
					hornetmaxrange = GetConVarFloat(cvarchk);
				CloseHandle(cvarchk);
				float targvec[3];
				MakeVectorFromPoints(curorg,enorg,targvec);
				float toang[3];
				GetVectorAngles(targvec,toang);
				bool withinradius = false;
				if (angs[1] > toang[1])
				{
					if ((angs[1]-toang[1] > 180) && (angs[1]-toang[1] < 220)) withinradius = false;
					else if ((toang[1]-angs[1] < -180) && (toang[1]-angs[1] > -220)) withinradius = false;
					else withinradius = true;
				}
				else if (toang[1] > angs[1])
				{
					if ((toang[1]-angs[1] > 180) && (toang[1]-angs[1] < 220)) withinradius = false;
					else if ((angs[1]-toang[1] < -180) && (angs[1]-toang[1] > -220)) withinradius = false;
					else withinradius = true;
				}
				if ((chkdist <= meleerange) && ((seq == 16) || (seq == 20)) && (withinradius))
				{
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((IsValidEntity(propset)) && (propset != 0))
					{
						char clschk[24];
						GetEntityClassname(propset,clschk,sizeof(clschk));
						if (StrEqual(clschk,"prop_dynamic",false))
							AcceptEntityInput(propset,"kill");
						centlastang[entity] = 0.0;
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					isattacking[entity] = true;
					centnextatk[entity] = Time+0.5;
					float damageForce[3];
					float dmgset = 25.0;
					float dmgforce = 40.0;
					Handle meleedmg = FindConVar("sk_alien_grunt_melee_dmg");
					if (meleedmg != INVALID_HANDLE)
						dmgset = GetConVarFloat(meleedmg);
					CloseHandle(meleedmg);
					damageForce[0] = dmgforce;
					damageForce[1] = dmgforce;
					damageForce[2] = dmgforce;
					SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
					CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
				}
				else if ((chkdist <= jumprange) && (withinradius))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((!IsValidEntity(propset)) || (propset == 0))
					{
						int propshow = CreateEntityByName("prop_dynamic");
						if (propshow != -1)
						{
							DispatchKeyValue(propshow,"solid","0");
							DispatchKeyValue(propshow,"model","models/xenians/agrunt.mdl");
							DispatchKeyValue(propshow,"DefaultAnim","attack_leap");
							TeleportEntity(propshow,curorg,angs,NULL_VECTOR);
							DispatchSpawn(propshow);
							ActivateEntity(propshow);
							SetVariantString("!activator");
							AcceptEntityInput(propshow,"SetParent",entity);
							int rand = GetRandomInt(17,19);
							SetEntProp(propshow,Prop_Data,"m_nSequence",rand);
							float tmp;
							tmp+=propshow;
							centlastang[entity] = tmp;
						}
					}
					centnextatk[entity] = Time+1.0;
					float damageForce[3];
					float dmgset = 30.0;
					float dmgforce = 450.0;
					Handle meleedmg = FindConVar("sk_alien_grunt_melee_dmg");
					if (meleedmg != INVALID_HANDLE)
						dmgset = GetConVarFloat(meleedmg)*1.2;
					CloseHandle(meleedmg);
					damageForce[0] = dmgforce;
					damageForce[1] = dmgforce;
					damageForce[2] = dmgforce;
					SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
					CreateTimer(1.0,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
				}
				else if ((chkdist <= hornetmaxrange) && (chkdist > hornetminrange) && (lastsaw > lastseen[entity]) && (withinradius))
				{
					int clawfind = CreateEntityByName("prop_dynamic");
					if (clawfind != -1)
					{
						DispatchKeyValue(clawfind,"rendermode","10");
						DispatchKeyValue(clawfind,"solid","0");
						DispatchKeyValue(clawfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(clawfind);
						ActivateEntity(clawfind);
						TeleportEntity(clawfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(clawfind,"SetParent",entity);
						SetVariantString("rightclaw");
						AcceptEntityInput(clawfind,"SetParentAttachment");
						if (HasEntProp(clawfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(clawfind,Prop_Data,"m_vecAbsOrigin",curorg);
						else if (HasEntProp(clawfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(clawfind,Prop_Send,"m_vecOrigin",curorg);
						AcceptEntityInput(clawfind,"kill");
					}
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((IsValidEntity(propset)) && (propset != 0))
					{
						char clschk[24];
						GetEntityClassname(propset,clschk,sizeof(clschk));
						if (StrEqual(clschk,"prop_dynamic",false))
							AcceptEntityInput(propset,"kill");
						centlastang[entity] = 0.0;
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					int rand = GetRandomInt(41,42);
					SetEntProp(entity,Prop_Data,"m_nSequence",rand);
					lastseen[entity] = lastsaw;
					isattacking[entity] = true;
					centnextatk[entity] = Time+0.5;
					float loc[3];
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (curorg[0] + (55 * Cosine(DegToRad(angs[1]))));
						loc[1] = (curorg[1] + (55 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (curorg[0] + (35 * Cosine(DegToRad(angs[1]))));
						loc[1] = (curorg[1] + (35 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (curorg[2] - 5);
					float shootvel[3];
					MakeVectorFromPoints(loc,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,5.0);
					int spitball = CreateEntityByName("prop_physics");
					if (spitball != -1)
					{
						DispatchKeyValue(spitball,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(spitball);
						ActivateEntity(spitball);
						if (!IsModelPrecached("models/weapons/w_hornet.mdl")) PrecacheModel("models/weapons/w_hornet.mdl",true);
						SetEntityModel(spitball,"models/weapons/w_hornet.mdl");
						SetEntityMoveType(spitball,MOVETYPE_FLY);
						SDKHook(spitball, SDKHook_StartTouch, StartTouchHornet);
						TeleportEntity(spitball,loc,angs,shootvel);
						int ent = CreateEntityByName("env_spritetrail");
						DispatchKeyValue(ent,"lifetime","2.0");
						DispatchKeyValue(ent,"startwidth","8.0");
						DispatchKeyValue(ent,"endwidth","6.0");
						DispatchKeyValue(ent,"spritename","sprites/bluelaser1.vmt");
						DispatchKeyValue(ent,"renderamt","150");
						DispatchKeyValue(ent,"rendermode","5");
						char colorstr[64];
						Format(colorstr,sizeof(colorstr),"145 42 42");
						DispatchKeyValue(ent,"rendercolor",colorstr);
						TeleportEntity(ent,loc,NULL_VECTOR,NULL_VECTOR);
						DispatchSpawn(ent);
						ActivateEntity(ent);
						SetVariantString("!activator");
						AcceptEntityInput(ent,"SetParent",spitball);
					}
					CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action StartTouchHornet(int entity, int other)
{
	if (IsValidEntity(other))
	{
		char clschk[24];
		GetEntityClassname(other,clschk,sizeof(clschk));
		if (StrContains(clschk,"npc_alien_",false) == -1)
		{
			float damageForce[3];
			float dmgset = 5.0;
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_CLUB,-1,damageForce);
			int rand = GetRandomInt(1,2);
			switch(rand)
			{
				case 1:
				{
					char snd[64];
					Format(snd,sizeof(snd),"weapons\\hivehand\\bug_impact.wav");
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				case 2:
				{
					char snd[64];
					Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
			}
		}
		AcceptEntityInput(entity,"kill");
	}
}

public Action agrunttkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((IsValidEntity(victim)) && (IsValidEntity(attacker)))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			if (IsEntNetworkable(attacker))
			{
				char clschk[24];
				GetEntityClassname(attacker,clschk,sizeof(clschk));
				if ((attacker == victim) || (StrEqual(clschk,"npc_alien_grunt",false)))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
				else if (damage > 4.0)
				{
					float Time = GetTickedTime();
					if (centlastposchk[victim] <= Time)
					{
						int rand = GetRandomInt(1,4);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\alien_grunt\\PAIN_%i.wav",rand);
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						centlastposchk[victim] = Time+2.5;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void apachethink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				if ((chkdist < 3000.0) && (lastsaw > lastseen[entity]))
				{
					//m_hCrashPoint crash point ent m_bInvulnerable m_vecDesiredPosition
					float lorg[3];
					int leftfind = CreateEntityByName("prop_dynamic");
					if (leftfind != -1)
					{
						DispatchKeyValue(leftfind,"rendermode","10");
						DispatchKeyValue(leftfind,"solid","0");
						DispatchKeyValue(leftfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(leftfind);
						ActivateEntity(leftfind);
						TeleportEntity(leftfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(leftfind,"SetParent",entity);
						SetVariantString("rocketpodl");
						AcceptEntityInput(leftfind,"SetParentAttachment");
						if (HasEntProp(leftfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(leftfind,Prop_Data,"m_vecAbsOrigin",lorg);
						else if (HasEntProp(leftfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(leftfind,Prop_Send,"m_vecOrigin",lorg);
						AcceptEntityInput(leftfind,"kill");
					}
					angs[0]+=20.0;
					float loc[3];
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (lorg[0] + (300 * Cosine(DegToRad(angs[1]))));
						loc[1] = (lorg[1] + (300 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (lorg[0] + (275 * Cosine(DegToRad(angs[1]))));
						loc[1] = (lorg[1] + (275 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (lorg[2] - 100);
					if (angs[0] > 30.0) loc[2]-=50.0;
					float shootvel[3];
					MakeVectorFromPoints(loc,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,2.0);
					int missile = CreateEntityByName("rpg_missile");
					if (missile != -1)
					{
						DispatchSpawn(missile);
						ActivateEntity(missile);
						TeleportEntity(missile,loc,angs,shootvel);
						SetEntPropEnt(missile,Prop_Data,"m_hOwnerEntity",entity);
					}
					float rorg[3];
					int rightfind = CreateEntityByName("prop_dynamic");
					if (rightfind != -1)
					{
						DispatchKeyValue(rightfind,"rendermode","10");
						DispatchKeyValue(rightfind,"solid","0");
						DispatchKeyValue(rightfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(rightfind);
						ActivateEntity(rightfind);
						TeleportEntity(rightfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(rightfind,"SetParent",entity);
						SetVariantString("rocketpodr");
						AcceptEntityInput(rightfind,"SetParentAttachment");
						if (HasEntProp(rightfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(rightfind,Prop_Data,"m_vecAbsOrigin",rorg);
						else if (HasEntProp(rightfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(rightfind,Prop_Send,"m_vecOrigin",rorg);
						AcceptEntityInput(rightfind,"kill");
					}
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (rorg[0] + (350 * Cosine(DegToRad(angs[1]))));
						loc[1] = (rorg[1] + (350 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (rorg[0] + (325 * Cosine(DegToRad(angs[1]))));
						loc[1] = (rorg[1] + (325 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (rorg[2] - 100);
					if (angs[0] > 30.0) loc[2]-=50.0;
					MakeVectorFromPoints(loc,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,2.0);
					missile = CreateEntityByName("rpg_missile");
					if (missile != -1)
					{
						DispatchSpawn(missile);
						ActivateEntity(missile);
						TeleportEntity(missile,loc,angs,shootvel);
						SetEntPropEnt(missile,Prop_Data,"m_hOwnerEntity",entity);
					}
					//CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					timesattacked[entity]++;
					if (timesattacked[entity] > 9)
					{
						centnextatk[entity] = Time+10;
						timesattacked[entity] = 0;
					}
					else
					{
						centnextatk[entity] = Time+0.5;
					}
					lastseen[entity] = lastsaw;
				}
			}
		}
	}
}

public Action apachetkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((IsValidEntity(victim)) && (IsValidEntity(inflictor)))
	{
		if (HasEntProp(inflictor,Prop_Data,"m_hOwnerEntity"))
		{
			int ownerent = GetEntPropEnt(inflictor,Prop_Data,"m_hOwnerEntity");
			if (ownerent == victim)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		if (((attacker < MaxClients+1) && (attacker > 0)) || ((inflictor < MaxClients+1) && (inflictor > 0)))
		{
			int health = GetEntProp(victim,Prop_Data,"m_iHealth");
			if (health-damage < 1)
			{
				Handle entkilled = CreateEvent("synergy_entity_death");
				SetEventInt(entkilled,"killercolor",-16083416);
				SetEventInt(entkilled,"victimcolor",-1052689);
				char weap[24];
				char clsname2[24];
				GetEntityClassname(inflictor,clsname2,sizeof(clsname2));
				if ((attacker < MaxClients+1) && (attacker > 0))
					GetClientWeapon(attacker,weap,sizeof(weap));
				else if ((inflictor < MaxClients+1) && (inflictor > 0))
					GetClientWeapon(inflictor,weap,sizeof(weap));
				if (StrContains(clsname2,"npc_",false) != -1)
				{
					Format(weap,sizeof(weap),"%s",clsname2);
					ReplaceString(weap,sizeof(weap),"npc_","",false);
				}
				else if ((StrEqual(clsname2,"prop_physics",false)) || (StrEqual(clsname2,"rpg_missile",false)))
				{
					Format(weap,sizeof(weap),"%s",clsname2);
					ReplaceString(weap,sizeof(weap),"prop_","",false);
				}
				if (strlen(weap) < 1)
					Format(weap,sizeof(weap),"hands");
				else
				{
					ReplaceString(weap,sizeof(weap),"weapon_","",false);
				}
				SetEventString(entkilled,"weapon",weap);
				SetEventInt(entkilled,"killerID",attacker);
				SetEventInt(entkilled,"victimID",victim);
				SetEventBool(entkilled,"suicide",false);
				char tmpchar[96];
				GetClientName(attacker,tmpchar,sizeof(tmpchar));
				SetEventString(entkilled,"killername",tmpchar);
				SetEventString(entkilled,"victimname","Apache");
				SetEventInt(entkilled,"iconcolor",-1052689);
				FireEvent(entkilled,false);
			}
		}
	}
	return Plugin_Continue;
}

void abramsthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				float driverangs[3];
				int driver = GetEntPropEnt(entity,Prop_Data,"m_hParent");
				if (driver != -1)
				{
					if (HasEntProp(driver,Prop_Data,"m_angAbsRotation"))
					{
						GetEntPropVector(driver,Prop_Data,"m_angAbsRotation",driverangs);
						driverangs[1]+=45.0;
						if ((angs[0] != driverangs[0]) || (angs[1] != driverangs[1]) || (angs[2] != driverangs[2]))
							TeleportEntity(entity,NULL_VECTOR,driverangs,NULL_VECTOR);
					}
				}
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				if ((chkdist < 3000.0) && (lastsaw > lastseen[entity]))
				{
					//m_hCrashPoint crash point ent m_bInvulnerable m_vecDesiredPosition
					float lorg[3];
					int cannonfind = CreateEntityByName("prop_dynamic");
					if (cannonfind != -1)
					{
						DispatchKeyValue(cannonfind,"rendermode","10");
						DispatchKeyValue(cannonfind,"solid","0");
						DispatchKeyValue(cannonfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(cannonfind);
						ActivateEntity(cannonfind);
						TeleportEntity(cannonfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(cannonfind,"SetParent",entity);
						SetVariantString("muzzle");
						AcceptEntityInput(cannonfind,"SetParentAttachment");
						if (HasEntProp(cannonfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(cannonfind,Prop_Data,"m_vecAbsOrigin",lorg);
						else if (HasEntProp(cannonfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(cannonfind,Prop_Send,"m_vecOrigin",lorg);
						if (HasEntProp(cannonfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(cannonfind,Prop_Data,"m_angAbsRotation",angs);
						AcceptEntityInput(cannonfind,"kill");
					}
					//angs[0]+=20.0;
					/*
					float loc[3];
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (lorg[0] + (300 * Cosine(DegToRad(angs[1]))));
						loc[1] = (lorg[1] + (300 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (lorg[0] + (275 * Cosine(DegToRad(angs[1]))));
						loc[1] = (lorg[1] + (275 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (lorg[2] - 100);
					if (angs[0] > 30.0) loc[2]-=50.0;
					*/
					//lorg[0] = (lorg[0] + (20 * Cosine(DegToRad(angs[1]))));
					//lorg[1] = (lorg[1] + (20 * Sine(DegToRad(angs[1]))));
					lorg[2]+=5.0;
					float shootvel[3];
					MakeVectorFromPoints(lorg,enorg,shootvel);
					/*
					if (shootvel[2] < 0.0) shootvel[2]+=55.0;
					else shootvel[2]-=55.0;
					ScaleVector(shootvel,2.0);
					*/
					char snd[128];
					int randsnd = GetRandomInt(3,5);
					Format(snd,sizeof(snd),"weapons/weap_explode/explode%i.wav",randsnd);
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
					float toang[3];
					float fhitpos[3];
					GetVectorAngles(shootvel,toang);
					Handle hhitpos = INVALID_HANDLE;
					TR_TraceRay(lorg,toang,MASK_SHOT,RayType_Infinite);
					TR_GetEndPosition(fhitpos,hhitpos);
					int endpoint = CreateEntityByName("env_explosion");
					TeleportEntity(endpoint,fhitpos,NULL_VECTOR,NULL_VECTOR);
					DispatchKeyValue(endpoint,"imagnitude","300");
					DispatchKeyValue(endpoint,"targetname","syn_abramsblast");
					DispatchKeyValue(endpoint,"iradiusoverride","150");
					DispatchKeyValue(endpoint,"rendermode","0");
					//DispatchKeyValue(endpoint,"spawnflags","9084");
					DispatchSpawn(endpoint);
					ActivateEntity(endpoint);
					AcceptEntityInput(endpoint,"Explode");
					if (HasEntProp(entity,Prop_Data,"m_hEffectEntity"))
					{
						int turretflash = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
						if (turretflash != -1) AcceptEntityInput(turretflash,"Fire");
					}
					//CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					centnextatk[entity] = Time+7.0;
					lastseen[entity] = lastsaw;
				}
			}
		}
	}
}

void zomthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_nSequence"))
		{
			float Time = GetTickedTime();
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			if (centnextatk[entity] < Time)
			{
				if ((seq == 31) || (seq == 33) || (seq == 98))
				{
					Time-=0.3;
					if (FileExists("npc\\zombie\\pound_door1.wav",true,NULL_STRING))
						EmitSoundToAll("npc\\zombie\\pound_door1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					else
						EmitSoundToAll("npc\\zombie\\zombie_pound_door.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if (seq == 32)
				{
					Time+=3.0;
					if (FileExists("npc\\zombie\\pound_door1.wav",true,NULL_STRING))
						EmitSoundToAll("npc\\zombie\\pound_door1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					else
						EmitSoundToAll("npc\\zombie\\zombie_pound_door.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if (seq == 34)
				{
					if (FileExists("npc\\zombie\\pound_door1.wav",true,NULL_STRING))
						EmitSoundToAll("npc\\zombie\\pound_door1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					else
						EmitSoundToAll("npc\\zombie\\zombie_pound_door.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if ((seq == 59) || (seq == 60))
				{
					int rand = GetRandomInt(1,5);
					char snd[64];
					Format(snd,sizeof(snd),"npc\\zombie\\moan%i.wav",rand);
					if (rand == 5) Time+=12.0;
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if ((seq == 78) || (seq == 8) || (seq == 10) || (seq == 12) || (seq == 14) || (seq == 16) || (seq == 18) || (seq == 20) || (seq == 22) || (seq == 24))
				{
					if (FileExists("sound\\npc\\zombie\\alert1.wav",true,NULL_STRING))
					{
						int rand = GetRandomInt(1,6);
						char snd[64];
						switch(rand)
						{
							case 1:
								Format(snd,sizeof(snd),"npc\\zombie\\alert1.wav");
							case 2:
								Format(snd,sizeof(snd),"npc\\zombie\\alert2.wav");
							case 3:
								Format(snd,sizeof(snd),"npc\\zombie\\alert05.wav");
							case 4:
								Format(snd,sizeof(snd),"npc\\zombie\\alert06.wav");
							case 5:
								Format(snd,sizeof(snd),"npc\\zombie\\alert07.wav");
							case 6:
								Format(snd,sizeof(snd),"npc\\zombie\\alert08.wav");
						}
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\zombie_alert%i.wav",rand);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
				else if ((seq > 54) && (seq < 58))
				{
					if (FileExists("sound\\npc\\zombie\\idle1.wav",true,NULL_STRING))
					{
						int rand = GetRandomInt(1,6);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\idle%i.wav",rand);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						int rand = GetRandomInt(1,14);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\zombie_voice_idle%i.wav",rand);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					Time+=1.0;
				}
				centnextatk[entity] = Time+0.8;
			}
		}
	}
}

public Action zomtkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			float Time = GetTickedTime();
			if (centnextatk[victim] < Time)
			{
				int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
				if (damage > curh)
				{
					if (FileExists("sound\\npc\\zombie\\die1.wav",true,NULL_STRING))
					{
						int rand = GetRandomInt(1,5);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\die%i.wav",rand);
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\zombie_die%i.wav",rand);
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
				else if (damage > 1)
				{
					int rand = GetRandomInt(1,10);
					char snd[64];
					if ((!FileExists("sound\\npc\\zombie\\pain08.wav",true,NULL_STRING)) && (rand > 6)) rand = 6;
					if (rand < 7)
						Format(snd,sizeof(snd),"npc\\zombie\\pain%i.wav",rand);
					else if (rand < 10)
						Format(snd,sizeof(snd),"npc\\zombie\\pain0%i.wav",rand);
					else
						Format(snd,sizeof(snd),"npc\\zombie\\pain10.wav");
					EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				centnextatk[victim] = Time+0.2;
			}
		}
	}
	return Plugin_Continue;
}

void grenthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		char curweap[24];
		int weap;
		if (HasEntProp(entity,Prop_Data,"m_hActiveWeapon"))
		{
			weap = GetEntPropEnt(entity,Prop_Data,"m_hActiveWeapon");
			if ((IsValidEntity(weap)) && (weap != 0))
				GetEntityClassname(weap,curweap,sizeof(curweap));
		}
		if ((HasEntProp(entity,Prop_Data,"m_nSequence")) && (StrEqual(curweap,"weapon_rpg",false)))
		{
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			if ((IsValidEntity(isattacking[entity])) && (isattacking[entity] != 0) && (seq != 0))
			{
				AcceptEntityInput(isattacking[entity],"kill");
				//SetEntityRenderMode(entity,RENDER_NORMAL);
				//SetEntityRenderMode(weap,RENDER_NORMAL);
				SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
				SetEntProp(weap,Prop_Data,"m_nRenderFX",0);
				isattacking[entity] = 0;
			}
			else if ((seq == 0) && (isattacking[entity] == 0))
			{
				//SetEntityRenderMode(entity,RENDER_NONE);
				//SetEntityRenderMode(weap,RENDER_NONE);
				SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
				SetEntProp(weap,Prop_Data,"m_nRenderFX",5);
				int entmdl = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdl,"model","models/humans/marine.mdl");
				DispatchKeyValue(entmdl,"solid","0");
				float origin[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",origin);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
				TeleportEntity(entmdl,origin,angs,NULL_VECTOR);
				DispatchSpawn(entmdl);
				ActivateEntity(entmdl);
				SetVariantString("!activator");
				AcceptEntityInput(entmdl,"SetParent",entity);
				SetEntProp(entmdl,Prop_Data,"m_nSequence",22);
				int body = GetEntProp(entity,Prop_Data,"m_nBody");
				SetEntProp(entmdl,Prop_Data,"m_nBody",body);
				isattacking[entity] = entmdl;
				int entmdlweap = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdlweap,"model","models/weapons/w_rocket_launcher.mdl");
				DispatchKeyValue(entmdlweap,"solid","0");
				TeleportEntity(entmdlweap,origin,angs,NULL_VECTOR);
				DispatchSpawn(entmdlweap);
				ActivateEntity(entmdlweap);
				SetVariantString("!activator");
				AcceptEntityInput(entmdlweap,"SetParent",entmdl);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(entmdlweap,"SetParentAttachment");
			}
		}
	}
}

void tentaclethink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int mdlarr = FindValueInArray(tents,entity);
			if (mdlarr != -1)
			{
				int entmdl = GetArrayCell(tentsmdl,mdlarr);
				if (IsValidEntity(entmdl))
				{
					if (HasEntProp(entmdl,Prop_Data,"m_hParent"))
					{
						int parentchk = GetEntPropEnt(entmdl,Prop_Data,"m_hParent");
						if (parentchk != -1) AcceptEntityInput(entmdl,"ClearParent");
					}
					int seqmdl = GetEntProp(entmdl,Prop_Data,"m_nSequence");
					int seq = isattacking[entmdl];
					int targ = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
					//bottomfloor += 100.0 floor_idle
					//firstfloor += 292.0 level1_idle
					//secondfloor += 484.0 level2_idle
					//thirdfloor += 675.0 level3_idle
					int mvfloor;
					float origin[3];
					if (HasEntProp(entmdl,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entmdl,Prop_Data,"m_vecAbsOrigin",origin);
					else if (HasEntProp(entmdl,Prop_Send,"m_vecOrigin")) GetEntPropVector(entmdl,Prop_Send,"m_vecOrigin",origin);
					for (int k = 0;k<GetArraySize(grenlist);k++)
					{
						int i = GetArrayCell(grenlist,k);
						if ((IsValidEntity(i)) && (IsEntNetworkable(i)))
						{
							char clschk[24];
							GetEntityClassname(i,clschk,sizeof(clschk));
							if (StrEqual(clschk,"npc_grenade_frag",false))
							{
								float plyorg[3];
								if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorg);
								else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorg);
								if ((seqmdl > 3) && (seqmdl < 11))
								{
									//atfloor0
									origin[2]+=100.0;
									mvfloor = 0;
								}
								else if ((seqmdl > 10) && (seqmdl < 18))
								{
									//atfloor1
									origin[2]+=292.0;
									mvfloor = 1;
								}
								else if ((seqmdl > 17) && (seqmdl < 25))
								{
									//atfloor2
									origin[2]+=484.0;
									mvfloor = 2;
								}
								else if ((seqmdl > 24) && (seqmdl < 32))
								{
									//atfloor3
									origin[2]+=675.0;
									mvfloor = 3;
								}
								float closest;
								int closestt;
								for (int h = 0;h<GetArraySize(tents);h++)
								{
									int j = GetArrayCell(tents,h);
									float atkorg[3];
									if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",atkorg);
									else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",atkorg);
									atkorg[2] = plyorg[2];
									float chkdist = GetVectorDistance(atkorg,plyorg,false);
									if (chkdist < 600.0)
									{
										if ((chkdist < closest) || (closest == 0.0))
										{
											closest = chkdist;
											closestt = j;
										}
									}
								}
								if ((closest != 0.0) && (closestt != 0))
								{
									if (FindValueInArray(tents,isattacking[i]) == -1) isattacking[i] = 0;
									if ((isattacking[i] != 0) && (IsValidEntity(isattacking[i])))
									{
										float atkorg[3];
										if (HasEntProp(isattacking[i],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(isattacking[i],Prop_Data,"m_vecAbsOrigin",atkorg);
										else if (HasEntProp(isattacking[i],Prop_Send,"m_vecOrigin")) GetEntPropVector(isattacking[i],Prop_Send,"m_vecOrigin",atkorg);
										atkorg[2] = plyorg[2];
										float chkdist = GetVectorDistance(origin,atkorg,false);
										chkdist+=10.0;
										if (chkdist < closest)
										{
											SetEntPropEnt(isattacking[i],Prop_Data,"m_hTargetEnt",-1);
											isattacking[i] = 0;
										}
									}
									if (isattacking[i] == 0)
									{
										SetEntPropEnt(closestt,Prop_Data,"m_hTargetEnt",i);
										isattacking[i] = closestt;
										break;
									}
								}
							}
						}
					}
					if (!IsValidEntity(targ))
					{
						for (int k = 0;k<GetArraySize(entlist);k++)
						{
							int i = GetArrayCell(entlist,k);
							if ((IsValidEntity(i)) && (IsEntNetworkable(i)))
							{
								char clschk[24];
								GetEntityClassname(i,clschk,sizeof(clschk));
								if ((!StrEqual(clschk,"npc_tentacle",false)) && ((StrContains(clschk,"npc_human",false) == 0) || (StrContains(clschk,"npc_alien",false) == 0)) || (StrEqual(clschk,"player",false)))
								{
									float plyorg[3];
									if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorg);
									else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorg);
									if ((seqmdl > 3) && (seqmdl < 11))
									{
										//atfloor0
										origin[2]+=100.0;
										mvfloor = 0;
									}
									else if ((seqmdl > 10) && (seqmdl < 18))
									{
										//atfloor1
										origin[2]+=292.0;
										mvfloor = 1;
									}
									else if ((seqmdl > 17) && (seqmdl < 25))
									{
										//atfloor2
										origin[2]+=484.0;
										mvfloor = 2;
									}
									else if ((seqmdl > 24) && (seqmdl < 32))
									{
										//atfloor3
										origin[2]+=675.0;
										mvfloor = 3;
									}
									float closest;
									int closestt;
									for (int h = 0;h<GetArraySize(tents);h++)
									{
										int j = GetArrayCell(tents,h);
										float atkorg[3];
										if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",atkorg);
										else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",atkorg);
										float chkdist = GetVectorDistance(atkorg,plyorg,false);
										if (chkdist < 600.0)
										{
											if ((chkdist < closest) || (closest == 0.0))
											{
												closest = chkdist;
												closestt = j;
											}
										}
									}
									if ((closest != 0.0) && (closestt != 0))
									{
										if (FindValueInArray(tents,isattacking[i]) == -1) isattacking[i] = 0;
										if ((isattacking[i] != 0) && (IsValidEntity(isattacking[i])))
										{
											float atkorg[3];
											if (HasEntProp(isattacking[i],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(isattacking[i],Prop_Data,"m_vecAbsOrigin",atkorg);
											else if (HasEntProp(isattacking[i],Prop_Send,"m_vecOrigin")) GetEntPropVector(isattacking[i],Prop_Send,"m_vecOrigin",atkorg);
											float chkdist = GetVectorDistance(origin,atkorg,false);
											chkdist+=10.0;
											if (chkdist < closest)
											{
												SetEntPropEnt(isattacking[i],Prop_Data,"m_hTargetEnt",-1);
												isattacking[i] = 0;
											}
										}
										if (isattacking[i] == 0)
										{
											SetEntPropEnt(closestt,Prop_Data,"m_hTargetEnt",i);
											isattacking[i] = closestt;
											break;
										}
									}
								}
							}
						}
					}
					float Time = GetTickedTime();
					int sndtarg = GetArrayCell(tentssnd,mdlarr);
					//Attachments Tip Eye
					if (centnextatk[entity] < Time)
					{
						if (targ == -1)
						{
							if (IsValidEntity(sndtarg))
							{
								char snd[64];
								int rand = GetRandomInt(1,10);
								Format(snd,sizeof(snd),"npc\\tentacle\\tent_sing_close%i.wav",rand);
								EmitSoundToAll(snd,sndtarg,SNDCHAN_AUTO,SNDLEVEL_DISHWASHER);
								centnextatk[entity] = Time+4.0;
							}
							float tiporg[3];
							if (HasEntProp(sndtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(sndtarg,Prop_Data,"m_vecAbsOrigin",tiporg);
							else if (HasEntProp(sndtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(sndtarg,Prop_Send,"m_vecOrigin",tiporg);
							float lowestdist;
							int clpass;
							for (int i = 1;i<MaxClients+1;i++)
							{
								if ((IsValidEntity(i)) && (IsClientInGame(i)))
								{
									float plyorg[3];
									GetClientAbsOrigin(i,plyorg);
									float chkdist = GetVectorDistance(tiporg,plyorg,false);
									if (((chkdist < lowestdist) || (lowestdist == 0.0)) && (isattacking[clpass] != 0))
									{
										lowestdist = chkdist;
										clpass = i;
									}
								}
							}
							if ((lowestdist < 600.0) && (lowestdist != 0.0))
							{
								SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",clpass);
								isattacking[clpass] = 0;
								SetEntProp(entity,Prop_Data,"m_nSequence",seq);
							}
						}
						if ((IsValidEntity(targ)) && (targ != 0))
						{
							origin[0] = 0.0;
							origin[1] = 0.0;
							origin[2] = 0.0;
							if (HasEntProp(entmdl,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entmdl,Prop_Data,"m_vecAbsOrigin",origin);
							else if (HasEntProp(entmdl,Prop_Send,"m_vecOrigin")) GetEntPropVector(entmdl,Prop_Send,"m_vecOrigin",origin);
							if ((seqmdl > 3) && (seqmdl < 11))
							{
								//atfloor0
								origin[2]+=100.0;
								mvfloor = 0;
							}
							else if ((seqmdl > 10) && (seqmdl < 18))
							{
								//atfloor1
								origin[2]+=292.0;
								mvfloor = 1;
							}
							else if ((seqmdl > 17) && (seqmdl < 25))
							{
								//atfloor2
								origin[2]+=484.0;
								mvfloor = 2;
							}
							else if ((seqmdl > 24) && (seqmdl < 32))
							{
								//atfloor3
								origin[2]+=675.0;
								mvfloor = 3;
							}
							float plyorg[3];
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",plyorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",plyorg);
							float chkdist = GetVectorDistance(origin,plyorg,false);
							if (chkdist > 600.0)
							{
								SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
								isattacking[targ] = 0;
								targ = -1;
							}
							else if (origin[2] > plyorg[2])
							{
								if (origin[2]-plyorg[2] > 120.0)
								{
									if (mvfloor == 3)
									{
										seq = GetRandomInt(18,21);
									}
									else if (mvfloor == 2)
									{
										seq = GetRandomInt(11,14);
									}
									else if (mvfloor == 1)
									{
										seq = GetRandomInt(4,7);
									}
									char snd[64];
									int rand = GetRandomInt(1,4);
									Format(snd,sizeof(snd),"npc\\tentacle\\tent_move%i.wav",rand);
									EmitSoundToAll(snd,sndtarg,SNDCHAN_AUTO,SNDLEVEL_DISHWASHER);
									isattacking[entmdl] = seq;
								}
							}
							else if (origin[2] < plyorg[2])
							{
								if (plyorg[2]-origin[2] > 120.0)
								{
									if (mvfloor == 2)
									{
										seq = GetRandomInt(25,28);
									}
									else if (mvfloor == 1)
									{
										seq = GetRandomInt(18,21);
									}
									else if (mvfloor == 0)
									{
										seq = GetRandomInt(11,14);
									}
									isattacking[entmdl] = seq;
								}
							}
							centnextatk[entity] = Time+2.0;
						}
						
					}
					if ((seqmdl == 32) && (seq == 0))
					{
						float plyorg[3];
						if (IsValidEntity(targ))
						{
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",plyorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",plyorg);
						}
						if (origin[2] > plyorg[2])
						{
							if (origin[2]-plyorg[2] > 120.0)
							{
								if (mvfloor == 3)
								{
									seq = GetRandomInt(18,21);
								}
								else if (mvfloor == 2)
								{
									seq = GetRandomInt(11,14);
								}
								else if (mvfloor == 1)
								{
									seq = GetRandomInt(4,7);
								}
								if (seq != 0)
									isattacking[entmdl] = seq;
							}
						}
						else if (origin[2] < plyorg[2])
						{
							if (plyorg[2]-origin[2] > 120.0)
							{
								if (mvfloor == 2)
								{
									seq = GetRandomInt(25,28);
								}
								else if (mvfloor == 1)
								{
									seq = GetRandomInt(18,21);
								}
								else if (mvfloor == 0)
								{
									seq = GetRandomInt(11,14);
								}
								if (seq != 0)
									isattacking[entmdl] = seq;
							}
						}
						SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
						targ = -1;
					}
					if ((seqmdl != seq) && (seq != 0))
					{
						bool contseqset = true;
						if (IsValidEntity(targ))
						{
							if (centnextatk[targ] > Time)
								contseqset = false;
						}
						if (contseqset)
						{
							char atkanim[32];
							switch(seq)
							{
								case 1:
								{
									SetVariantString("gesture_level1_idle_blend");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 2:
								{
									SetVariantString("gesture_level2_idle_blend");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 3:
								{
									SetVariantString("gesture_level3_idle_blend");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 4:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle");
								}
								case 5:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle2");
								}
								case 6:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle3");
								}
								case 7:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle4");
								}
								case 8:
								{
									SetVariantString("floor_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 9:
								{
									SetVariantString("floor_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 10:
								{
									SetVariantString("floor_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 11:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle");
								}
								case 12:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle2");
								}
								case 13:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle3");
								}
								case 14:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle4");
								}
								case 15:
								{
									SetVariantString("level1_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 16:
								{
									SetVariantString("level1_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 17:
								{
									SetVariantString("level1_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 18:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle");
								}
								case 19:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle2");
								}
								case 20:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle3");
								}
								case 21:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle4");
								}
								case 22:
								{
									SetVariantString("level2_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 23:
								{
									SetVariantString("level2_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 24:
								{
									SetVariantString("level2_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 25:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle");
								}
								case 26:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle2");
								}
								case 27:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle3");
								}
								case 28:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle4");
								}
								case 29:
								{
									SetVariantString("level3_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 30:
								{
									SetVariantString("level3_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 31:
								{
									SetVariantString("level3_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 32:
								{
									Format(atkanim,sizeof(atkanim),"floor_to_level1");
								}
								case 33:
								{
									Format(atkanim,sizeof(atkanim),"level1_to_floor");
									
								}
								case 34:
								{
									Format(atkanim,sizeof(atkanim),"level1_to_level2");
								}
								case 35:
								{
									Format(atkanim,sizeof(atkanim),"level2_to_level1");
								}
								case 36:
								{
									Format(atkanim,sizeof(atkanim),"level0_to_level2");
								}
								case 37:
								{
									Format(atkanim,sizeof(atkanim),"level2_to_level0");
								}
								case 38:
								{
									Format(atkanim,sizeof(atkanim),"level2_to_level3");
								}
								case 39:
								{
									Format(atkanim,sizeof(atkanim),"level3_to_level2");
								}
								case 40:
								{
									Format(atkanim,sizeof(atkanim),"floor_to_level3");
								}
								case 41:
								{
									Format(atkanim,sizeof(atkanim),"level3_to_floor");
								}
								case 42:
								{
									Format(atkanim,sizeof(atkanim),"level1_to_level3");
								}
								case 43:
								{
									Format(atkanim,sizeof(atkanim),"level3_to_level1");
								}
								case 44:
								{
									Format(atkanim,sizeof(atkanim),"level3_idlerear");
								}
								case 45:
								{
									Format(atkanim,sizeof(atkanim),"level2_idlerear");
								}
								case 46:
								{
									Format(atkanim,sizeof(atkanim),"level1_idlerear");
								}
								case 47:
								{
									Format(atkanim,sizeof(atkanim),"floor_idlerear");
								}
								case 48:
								{
									SetVariantString("floor_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 49:
								{
									SetVariantString("level1_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 50:
								{
									SetVariantString("level2_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 51:
								{
									SetVariantString("level3_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 52:
								{
									SetVariantString("tentacle_controlroom_smash");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 53:
								{
									SetVariantString("gesture_rotateright");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 54:
								{
									SetVariantString("gesture_rotateleft");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 55:
								{
									SetVariantString("death1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 56:
								{
									SetVariantString("death2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 57:
								{
									SetVariantString("death3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
							}
							if (strlen(atkanim) > 4)
							{
								SetVariantString(atkanim);
								AcceptEntityInput(entmdl,"SetAnimation");
								//SetVariantString(atkanim);
								//AcceptEntityInput(entmdl,"SetDefaultAnimation");
								seqmdl = GetEntProp(entmdl,Prop_Data,"m_nSequence");
								//SetEntProp(entity,Prop_Data,"m_nSequence",seqmdl);
							}
							//SetEntProp(entmdl,Prop_Data,"m_nSequence",seq);
							isattacking[entmdl] = seq;
						}
					}
					else if ((IsValidEntity(targ)) && (targ != 0) && (IsValidEntity(sndtarg)))
					{
						float enorg[3];
						float tiporg[3];
						if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
						if (HasEntProp(sndtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(sndtarg,Prop_Data,"m_vecAbsOrigin",tiporg);
						else if (HasEntProp(sndtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(sndtarg,Prop_Send,"m_vecOrigin",tiporg);
						//if ((tiporg[2]-enorg[2] < 200.0) && (enorg[2]-tiporg[2] < 200.0))
						//{
						float toang[3];
						float angs[3];
						if (HasEntProp(entmdl,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entmdl,Prop_Data,"m_angAbsRotation",angs);
						if (centlastposchk[entmdl] < Time)
						{
							float loc[3];
							loc[0] = (tiporg[0] + (60 * Cosine(DegToRad(angs[1]))));
							loc[1] = (tiporg[1] + (60 * Sine(DegToRad(angs[1]))));
							loc[2] = (tiporg[2] - 25);
							float shootvel[3];
							MakeVectorFromPoints(loc,enorg,shootvel);
							GetVectorAngles(shootvel,toang);
							centlastang[entmdl] = toang[1];
							centlastposchk[entmdl] = Time+2.0;
						}
						else
						{
							toang[1] = centlastang[entmdl];
						}
						if (angs[1] > toang[1])
						{
							if (angs[1]-toang[1] > 180) angs[1]+=1.0;
							else if (toang[1]-angs[1] < -180) angs[1]+=1.0;
							else angs[1]-=1.0;
						}
						else if (toang[1] > angs[1])
						{
							if (toang[1]-angs[1] > 180) angs[1]-=1.0;
							else if (angs[1]-toang[1] < -180) angs[1]-=1.0;
							else angs[1]+=1.0;
						}
						if (angs[1] < 0.0) angs[1]+=360.0;
						if (angs[1] > 360) angs[1]-=360.0;
						TeleportEntity(entmdl,NULL_VECTOR,angs,NULL_VECTOR);
						//}
						if (centnextatk[targ] < Time)
						{
							float chkdist = GetVectorDistance(tiporg,enorg,false);
							if ((chkdist < 250.0) && (tiporg[2] > enorg[2]))
							{
								centnextatk[targ] = Time+0.7;
								char atk[64];
								int randatk = GetRandomInt(1,3);
								if ((seqmdl > 3) && (seqmdl < 11))
								{
									//atfloor0
									Format(atk,sizeof(atk),"floor_strike%i",randatk);
								}
								else if ((seqmdl > 10) && (seqmdl < 18))
								{
									//atfloor1
									Format(atk,sizeof(atk),"level1_strike%i",randatk);
								}
								else if ((seqmdl > 17) && (seqmdl < 25))
								{
									//atfloor2
									Format(atk,sizeof(atk),"level2_strike%i",randatk);
								}
								else if ((seqmdl > 24) && (seqmdl < 32))
								{
									//atfloor3
									Format(atk,sizeof(atk),"level3_strike%i",randatk);
								}
								if (strlen(atk) > 4)
								{
									SetVariantString(atk);
									AcceptEntityInput(entmdl,"SetAnimation");
									//seq = GetEntProp(entmdl,Prop_Data,"m_nSequence");
									isattacking[entmdl] = seqmdl;
									SetEntProp(entity,Prop_Data,"m_nSequence",seqmdl);
									CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
							else
							{
								float lowestdist;
								int clpass;
								for (int i = 1;i<MaxClients+1;i++)
								{
									if ((IsValidEntity(i)) && (IsClientInGame(i)))
									{
										float plyorg[3];
										GetClientAbsOrigin(i,plyorg);
										chkdist = GetVectorDistance(tiporg,plyorg,false);
										if ((chkdist < lowestdist) || (lowestdist == 0.0))
										{
											lowestdist = chkdist;
											clpass = i;
										}
									}
								}
								if ((lowestdist < 200.0) && (lowestdist != 0.0))
								{
									centnextatk[clpass] = Time+0.7;
									char atk[64];
									int randatk = GetRandomInt(1,3);
									if ((seqmdl > 3) && (seqmdl < 11))
									{
										//atfloor0
										Format(atk,sizeof(atk),"floor_strike%i",randatk);
									}
									else if ((seqmdl > 10) && (seqmdl < 18))
									{
										//atfloor1
										Format(atk,sizeof(atk),"level1_strike%i",randatk);
									}
									else if ((seqmdl > 17) && (seqmdl < 25))
									{
										//atfloor2
										Format(atk,sizeof(atk),"level2_strike%i",randatk);
									}
									else if ((seqmdl > 24) && (seqmdl < 32))
									{
										//atfloor3
										Format(atk,sizeof(atk),"level3_strike%i",randatk);
									}
									if (strlen(atk) > 1)
									{
										SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",clpass);
										SetVariantString(atk);
										AcceptEntityInput(entmdl,"SetAnimation");
										//seq = GetEntProp(entmdl,Prop_Data,"m_nSequence");
										isattacking[entmdl] = seqmdl;
										isattacking[clpass] = 0;
										SetEntProp(entity,Prop_Data,"m_nSequence",seqmdl);
										CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
									}
								}
							}
						}
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
					//SetEntityRenderMode(entity,RENDER_NONE);
					//SetEntityRenderMode(entmdl,RENDER_NORMAL);
				}
			}
		}
	}
}

public Action resetmdl(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char mdl[128];
		ReadPackString(dp,mdl,sizeof(mdl));
		int ent = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(ent)) && (ent > MaxClients))
		{
			SetEntPropString(ent,Prop_Data,"m_ModelName",mdl);
			DispatchKeyValue(ent,"model",mdl);
			if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
			if (StrEqual(mdl,"models/zombies/zombie_sci.mdl",false))
			{
				SetVariantString("headcrab1");
				AcceptEntityInput(ent,"SetBodyGroup");
			}
			else if (StrEqual(mdl,"models/zombies/zombie_sci_torso.mdl",false))
			{
				SetVariantString("body");
				AcceptEntityInput(ent,"SetBodyGroup");
			}
			SetEntityModel(ent,mdl);
			char cvarchk[32];
			char clsname[32];
			GetEntityClassname(ent,clsname,sizeof(clsname));
			if ((StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"npc_alien_grunt_unarmored",false)) || (StrEqual(clsname,"npc_alien_slave",false)) || (StrEqual(clsname,"npc_ichthyosaur",false)))
				SetEntProp(ent,Prop_Data,"m_nRenderFX",0);
			Format(cvarchk,sizeof(cvarchk),"%s_health",clsname);
			ReplaceString(cvarchk,sizeof(cvarchk),"npc_","sk_",false);
			Handle cvar = FindConVar(cvarchk);
			if (cvar != INVALID_HANDLE)
			{
				int maxh = GetConVarInt(cvar);
				if (maxh > 0)
				{
					char maxhch[8];
					Format(maxhch,sizeof(maxhch),"%i",maxh);
					DispatchKeyValue(ent,"max_health",maxhch);
					if (HasEntProp(ent,Prop_Data,"m_iHealth")) SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
					if (HasEntProp(ent,Prop_Data,"m_iMaxHealth")) SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
				}
			}
			CloseHandle(cvar);
		}
	}
	return Plugin_Handled;
}

public Action resetattach(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int ent = ReadPackCell(dp);
		char attachment[32];
		ReadPackString(dp,attachment,sizeof(attachment));
		CloseHandle(dp);
		if (HasEntProp(ent,Prop_Data,"m_hParent"))
		{
			int parentchk = GetEntPropEnt(ent,Prop_Data,"m_hParent");
			if (parentchk != -1)
			{
				SetVariantString(attachment);
				AcceptEntityInput(ent,"SetParentAttachment");
			}
		}
	}
}

char recursionmdl(char mdl[128], char[] dir)
{
	char buff[128];
	Handle msubdirlisting = OpenDirectory(dir,true,NULL_STRING);
	if (msubdirlisting != INVALID_HANDLE)
	{
		while (ReadDirEntry(msubdirlisting, buff, sizeof(buff)))
		{
			if ((!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))) && (!(msubdirlisting == INVALID_HANDLE)))
			{
				if ((!(StrContains(buff, ".ztmp") != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
				{
					char buff2[128];
					Format(buff2,sizeof(buff2),"%s/%s",dir,buff);
					if (StrEqual(buff,mdl,false))
					{
						return buff2;
					}
					if (!(StrContains(buff2, ".", false) != -1))
					{
						recursionmdl(mdl,buff2);
					}
				}
			}
		}
	}
	CloseHandle(msubdirlisting);
	Format(mdl,sizeof(mdl),"");
	return mdl;
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	char atk[64];
	char clsname[64];
	char clsname2[64];
	int killed = GetEventInt(event, "entindex_killed");
	int attacker = GetEventInt(event, "entindex_attacker");
	int inflictor = GetEventInt(event, "entindex_inflictor");
	if ((killed < MaxClients+1) && (killed > 0))
	{
		CreateTimer(0.1,checkvalidity,killed);
	}
	if (attacker > MaxClients)
	{
		GetEntityClassname(attacker, atk, sizeof(atk));
	}
	GetEntityClassname(killed, clsname, sizeof(clsname));
	GetEntityClassname(inflictor, clsname2, sizeof(clsname2));
	if (StrEqual(clsname,"npc_houndeye",false))
	{
		int find = FindValueInArray(hounds,killed);
		if (find != -1)
		{
			int mdl = GetArrayCell(houndsmdl,find);
			if (IsValidEntity(mdl))
				AcceptEntityInput(mdl,"kill");
			RemoveFromArray(hounds,find);
			RemoveFromArray(houndsmdl,find);
			if (FindEntityByClassname(-1,"npc_houndeye") <= 0)
			{
				if ((IsValidEntity(matmod)) && (matmod != -1) && (matmod != 0))
				{
					SetVariantString("0");
					AcceptEntityInput(matmod,"SetMaterialVar");
				}
			}
		}
	}
	else if (StrEqual(clsname,"npc_bullsquid",false))
	{
		int find = FindValueInArray(squids,killed);
		if (find != -1)
		{
			int mdl = GetArrayCell(squidsmdl,find);
			if (IsValidEntity(mdl))
				AcceptEntityInput(mdl,"kill");
			RemoveFromArray(squids,find);
			RemoveFromArray(squidsmdl,find);
		}
	}
	else if (StrEqual(clsname,"npc_tentacle",false))
	{
		int find = FindValueInArray(tents,killed);
		if (find != -1)
		{
			int mdl = GetArrayCell(tentsmdl,find);
			if (IsValidEntity(mdl))
				AcceptEntityInput(mdl,"kill");
			RemoveFromArray(tents,find);
			RemoveFromArray(tentsmdl,find);
			RemoveFromArray(tentssnd,find);
		}
	}
	if ((HasEntProp(killed,Prop_Data,"m_iName")) && (StrContains(clsname,"npc_",false) != -1))
	{
		char entname[32];
		GetEntPropString(killed,Prop_Data,"m_iName",entname,sizeof(entname));
		if (FindStringInArray(entnames,entname) == -1) PushArrayString(entnames,entname);
	}
	if ((attacker < MaxClients+1) && (attacker > 0))
	{
		if (IsClientInGame(attacker))
		{
			int viccol = -1052689;
			if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_grenadier",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_abrams",false)))
			{
				viccol = -6921216;
			}
			else if (StrContains(clsname,"npc_zombie_",false) != -1)
			{
				viccol = -16777041;
			}
			else if (StrEqual(clsname,"npc_ichthyosaur",false))
			{
				viccol = -16732161;
				EmitSoundToAll("npc\\ichthyosaur\\die1.wav", killed, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
			else if (StrEqual(clsname,"npc_snark",false))
			{
				char snd[64];
				int rand = GetRandomInt(1,4);
				if (rand == 1) Format(snd,sizeof(snd),"npc\\snark\\die1.wav");
				else Format(snd,sizeof(snd),"npc\\snark\\die0%i.wav",rand);
				EmitSoundToAll(snd, killed, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				viccol = -16732161;
			}
			if ((FindStringInArray(customentlist,clsname) != -1) || (StrEqual(clsname,"npc_ichthyosaur",false)))
			{
				//-6921216 is blue -16083416 is green -16777041 is red -1052689 is white -3644216 is purple -16732161 is yellow
				Handle entkilled = CreateEvent("synergy_entity_death");
				SetEventInt(entkilled,"killercolor",-16083416);
				SetEventInt(entkilled,"victimcolor",viccol);
				char weap[24];
				GetClientWeapon(attacker,weap,sizeof(weap));
				if (StrContains(clsname2,"npc_",false) != -1)
				{
					Format(weap,sizeof(weap),"%s",clsname2);
					ReplaceString(weap,sizeof(weap),"npc_","",false);
				}
				else if ((StrEqual(clsname2,"prop_physics",false)) || (StrEqual(clsname2,"rpg_missile",false)))
				{
					Format(weap,sizeof(weap),"%s",clsname2);
					ReplaceString(weap,sizeof(weap),"prop_","",false);
				}
				if (strlen(weap) < 1)
					Format(weap,sizeof(weap),"hands");
				else
				{
					ReplaceString(weap,sizeof(weap),"weapon_","",false);
				}
				SetEventString(entkilled,"weapon",weap);
				SetEventInt(entkilled,"killerID",attacker);
				SetEventInt(entkilled,"victimID",killed);
				SetEventBool(entkilled,"suicide",false);
				char tmpchar[96];
				GetClientName(attacker,tmpchar,sizeof(tmpchar));
				SetEventString(entkilled,"killername",tmpchar);
				ReplaceString(clsname,sizeof(clsname),"npc_","",false);
				clsname[0] &= ~(1 << 5);
				char rebuildupper[32][32];
				ExplodeString(clsname,"_",rebuildupper,32,32);
				clsname = "";
				for (int i = 0;i<32;i++)
				{
					if (strlen(rebuildupper[i]) > 0)
					{
						rebuildupper[i][0] &= ~(1 << 5);
						if (strlen(clsname) > 0)
							Format(clsname,sizeof(clsname),"%s %s",clsname,rebuildupper[i]);
						else
							Format(clsname,sizeof(clsname),"%s",rebuildupper[i]);
					}
					else break;
				}
				SetEventString(entkilled,"victimname",clsname);
				SetEventInt(entkilled,"iconcolor",-1052689);
				FireEvent(entkilled,false);
			}
		}
	}
	return Plugin_Continue;
}

public Action checkvalidity(Handle timer, int client)
{
	if ((!IsValidEntity(client)) && (IsClientConnected(client)) && (StrContains(mapbuf,"bm_c",false) != -1))
	{
		Handle resetchk = FindConVar("mp_reset");
		if (resetchk != INVALID_HANDLE)
		{
			int willreset = GetConVarInt(resetchk);
			if (willreset == 0) ClientCommand(client,"retry");
			else
			{
				bool retry = true;
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsValidEntity(i))
						if (IsClientConnected(i))
							if (IsClientInGame(i))
								if (IsPlayerAlive(i))
									retry = false;
				}
				if (retry) ClientCommand(client,"retry");
			}
		}
		CloseHandle(resetchk);
	}
	return Plugin_Handled;
}

readoutputs(int scriptent, char[] targn)
{
	if (strlen(targn) < 1) return;
	if (debuglvl == 3) PrintToServer("Read outputs for script ents");
	Handle filehandle = OpenFile(mapbuf,"r",true,NULL_STRING);
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
		GetEntityClassname(scriptent,clsscript,sizeof(clsscript));
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line,"\"targetname\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				TrimString(tmpchar);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
			}
			else if (StrContains(line,"\"template0",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"template0","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				strcopy(tmpchar,sizeof(tmpchar),tmpchar[2]);
				TrimString(tmpchar);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
			}
			else if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
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
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
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
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),line);
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
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
				{
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"actor\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				char cls[32];
				int arrindx = FindStringInArray(passedarr,"classname");
				if (arrindx != -1)
				{
					char tmpchar[128];
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
					char tmpchar[128];
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
		CloseHandle(passedarr);
	}
	CloseHandle(filehandle);
	return;
}

readoutputstp(char[] targn, char[] output, char[] input, float origin[3], int activator)
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
		for (int i = 0;i<GetArraySize(inputsarrorigincls);i++)
		{
			GetArrayString(inputsarrorigincls,i,tmpch,sizeof(tmpch));
			ExplodeString(tmpch,"\"",clsorfixup,16,128);
			//if ((StrContains(tmpch,tmpoutpchk,false) != -1) || ((StrContains(tmpch,origintargnfind,false) != -1) && (StrEqual(clsorfixup[1],originchar,false))))
			if (((StrEqual(clsorfixup[1],originchar)) && (StrEqual(clsorfixup[0],targn))) || ((StrEqual(clsorfixup[0],targn)) && (StrEqual(clsorfixup[1],originchar))) || (StrContains(clsorfixup[3],tmpoutpchk,false) != -1))
			{
				if (StrContains(tmpch,output) != -1)
				{
					char lineorgrescom[16][64];
					if ((StrContains(clsorfixup[5],",") != -1) && (StrContains(clsorfixup[3],"::") == -1))
					{
						ExplodeString(clsorfixup[5],",",lineorgrescom,16,64);
						if (StrEqual(input,lineorgrescom[1]))
						{
							ReplaceString(lineorgrescom[0],sizeof(lineorgrescom[])," ","");
							float delay = StringToFloat(lineorgrescom[3]);
							if (debuglvl >= 2) PrintToServer("%s Input from %s to %s %s",input,targn,lineorgrescom[0],clsorfixup[5]);
							if (StrEqual(input,"teleport",false)) findpointtp(-1,lineorgrescom[0],activator,delay);
							else if (StrEqual(input,"save",false))
							{
								resetvehicles(delay);
								if (delay == 0.0) CreateTimer(0.01,recallreset);
							}
							else if (StrEqual(input,"startportal",false))
							{
								findxenporttp(-1,"env_xen_portal",lineorgrescom[0],delay);
								findxenporttp(-1,"env_xen_portal_template",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Deploy",false))
							{
								findsentriesd(-1,"npc_turret_floor",lineorgrescom[0],delay);
								findsentriesd(-1,"npc_turret_ceiling",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Retire",false))
							{
								findsentriesr(-1,"npc_turret_floor",lineorgrescom[0],delay);
								findsentriesr(-1,"npc_turret_ceiling",lineorgrescom[0],delay);
							}
							else if ((StrEqual(input,"ForceSpawn",false)) || (StrEqual(input,"Spawn",false))) findpts(lineorgrescom[0],delay);
							else if (StrEqual(input,"SetMass",false))
							{
								Handle dp = CreateDataPack();
								WritePackString(dp,lineorgrescom[0]);
								WritePackString(dp,lineorgrescom[2]);
								findmassset(dp,delay);
							}
						}
					}
					else
					{
						ExplodeString(clsorfixup[3],":",lineorgrescom,16,64);
						if (StrEqual(input,lineorgrescom[1]))
						{
							char delaystr[64];
							Format(delaystr,sizeof(delaystr),lineorgrescom[3]);
							float delay = StringToFloat(lineorgrescom[3]);
							if (StrContains(lineorgrescom[0],tmpoutpchk) == 0) ReplaceString(lineorgrescom[0],sizeof(lineorgrescom[]),tmpoutpchk,"");
							if (debuglvl >= 2) PrintToServer("%s AddedInput to %s %s",input,lineorgrescom[0],clsorfixup[3]);
							if (StrEqual(input,"teleport",false)) findpointtp(-1,lineorgrescom[0],activator,delay);
							else if (StrEqual(input,"save",false))
							{
								resetvehicles(delay);
								if (delay == 0.0) CreateTimer(0.01,recallreset);
							}
							else if (StrEqual(input,"startportal",false))
							{
								findxenporttp(-1,"env_xen_portal",lineorgrescom[0],delay);
								findxenporttp(-1,"env_xen_portal_template",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Deploy",false))
							{
								findsentriesd(-1,"npc_turret_floor",lineorgrescom[0],delay);
								findsentriesd(-1,"npc_turret_ceiling",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Retire",false))
							{
								findsentriesr(-1,"npc_turret_floor",lineorgrescom[0],delay);
								findsentriesr(-1,"npc_turret_ceiling",lineorgrescom[0],delay);
							}
							else if ((StrEqual(input,"ForceSpawn",false)) || (StrEqual(input,"Spawn",false))) findpts(lineorgrescom[0],delay);
							else if (StrEqual(input,"SetMass",false))
							{
								Handle dp = CreateDataPack();
								WritePackString(dp,lineorgrescom[0]);
								WritePackString(dp,lineorgrescom[2]);
								findmassset(dp,delay);
							}
						}
					}
				}
			}
		}
	}
	return;
}

readoutputsforinputs()
{
	if (hasread) return;
	if (debuglvl > 1) PrintToServer("Read outputs for inputs");
	hasread = true;
	Handle inputclasshooks = CreateArray(64);
	Handle filehandle = OpenFile(mapbuf,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		char inputadded[64];
		Format(inputadded,sizeof(inputadded),":Teleport::");
		char inputdef[64];
		Format(inputdef,sizeof(inputdef),",Teleport,,");
		char inputadded2[64];
		Format(inputadded2,sizeof(inputadded2),":Save::");
		char inputdef2[64];
		Format(inputdef2,sizeof(inputdef2),",Save,,");
		char inputadded3[64];
		Format(inputadded3,sizeof(inputadded3),":StartPortal::");
		char inputdef3[64];
		Format(inputdef3,sizeof(inputdef3),",StartPortal,,");
		char inputadded4[64];
		Format(inputadded4,sizeof(inputadded4),":Deploy::");
		char inputdef4[64];
		Format(inputdef4,sizeof(inputdef4),",Deploy,,");
		char inputadded5[64];
		Format(inputadded5,sizeof(inputadded5),":Retire::");
		char inputdef5[64];
		Format(inputdef5,sizeof(inputdef5),",Retire,,");
		char inputadded6[64];
		char inputdef6[64];
		char inputadded7[64];
		char inputdef7[64];
		if (customents)
		{
			Format(inputadded6,sizeof(inputadded6),":ForceSpawn::");
			Format(inputdef6,sizeof(inputdef6),",ForceSpawn,,");
			Format(inputadded7,sizeof(inputadded7),":Spawn::");
			Format(inputdef7,sizeof(inputdef7),",Spawn,,");
		}
		else
		{
			Format(inputadded6,sizeof(inputadded6),"::NotAnInput::");
			Format(inputdef6,sizeof(inputdef6),",,NotAnInput,,");
			Format(inputadded7,sizeof(inputadded7),"::NotAnInput::");
			Format(inputdef7,sizeof(inputdef7),",,NotAnInput,,");
		}
		char inputadded8[64];
		Format(inputadded8,sizeof(inputadded8),":SetMass:");
		char inputdef8[64];
		Format(inputdef8,sizeof(inputdef8),",SetMass,");
		char lineorgres[128];
		char lineorgresexpl[4][16];
		char lineoriginfixup[128];
		char lineadj[128];
		bool hastargn = false;
		bool hasorigin = false;
		char classhook[64];
		char kvs[128][64];
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)))
			{
				if ((strlen(lineoriginfixup) > 0) && (strlen(lineorgres) > 0) && (hastargn) && (hasorigin) && (FindStringInArray(inputsarrorigincls,lineadj) == -1))
				{
					Format(lineadj,sizeof(lineadj),"%s %s",lineoriginfixup,lineorgres);
					PushArrayString(inputsarrorigincls,lineadj);
					if (debuglvl == 3)
					{
						PrintToServer("%s",lineadj);
					}
					char outpchk[128];
					Format(outpchk,sizeof(outpchk),line);
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
						HookEntityOutput(classhook,kvs[1],EntityOutput:trigtp);
						PushArrayString(inputclasshooks,outpchk);
					}
				}
				lineoriginfixup = "";
				hastargn = false;
				hasorigin = false;
			}
			if ((StrContains(line,"\"origin\"",false) == 0) && (!hasorigin))
			{
				char tmpchar[64];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				ExplodeString(tmpchar, " ", lineorgresexpl, 4, 16);
				if (hastargn) Format(lineoriginfixup,sizeof(lineoriginfixup),"%s%i %i %i\"",lineoriginfixup,RoundFloat(StringToFloat(lineorgresexpl[0])),RoundFloat(StringToFloat(lineorgresexpl[1])),RoundFloat(StringToFloat(lineorgresexpl[2])))
				else Format(lineoriginfixup,sizeof(lineoriginfixup),"%i %i %i\"",RoundFloat(StringToFloat(lineorgresexpl[0])),RoundFloat(StringToFloat(lineorgresexpl[1])),RoundFloat(StringToFloat(lineorgresexpl[2])))
				hasorigin = true;
			}
			else if ((StrContains(line,"\"targetname\"",false) == 0) && (!hastargn))
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" \"","");
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","");
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s\"%s",tmpchar,lineoriginfixup);
				hastargn = true;
			}
			else if (StrContains(line,"\"classname\"",false) == 0)
			{
				char clschk[128];
				Format(clschk,sizeof(clschk),line);
				ExplodeString(clschk, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				Format(classhook,sizeof(classhook),kvs[3]);
			}
			else if (((StrContains(line,",AddOutput,",false) != -1) && ((StrContains(line,inputadded,false) != -1) || (StrContains(line,inputadded2,false) != -1) || (StrContains(line,inputadded3,false) != -1) || (StrContains(line,inputadded4,false) != -1) || (StrContains(line,inputadded5,false) != -1) || (StrContains(line,inputadded6,false) != -1) || (StrContains(line,inputadded7,false) != -1) || (StrContains(line,inputadded8,false) != -1))) || (StrContains(line,inputdef,false) != -1) || (StrContains(line,inputdef2,false) != -1) || (StrContains(line,inputdef3,false) != -1) || (StrContains(line,inputdef4,false) != -1) || (StrContains(line,inputdef5,false) != -1) || (StrContains(line,inputdef6,false) != -1) || (StrContains(line,inputdef7,false) != -1) || (StrContains(line,inputdef8,false) != -1))
			{
				Format(lineorgres,sizeof(lineorgres),line);
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
					Format(tmpchar,sizeof(tmpchar),line);
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
					if (debuglvl == 3)
					{
						PrintToServer("%s",lineadj);
					}
					char outpchk[128];
					Format(outpchk,sizeof(outpchk),line);
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
						HookEntityOutput(classhook,kvs[1],EntityOutput:trigtp);
						PushArrayString(inputclasshooks,outpchk);
					}
					//lineoriginfixup = "";
					//hastargn = false;
					//hasorigin = false;
				}
			}
		}
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

SearchForClass(char tmptarg[128])
{
	for (int i = 1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			if (HasEntProp(i,Prop_Data,"m_iName"))
			{
				char targn[128];
				GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
				if (StrContains(tmptarg,"*",false) == 0)
				{
					char targwithout[128];
					Format(targwithout,sizeof(targwithout),"%s",tmptarg);
					ReplaceString(targwithout,sizeof(targwithout),"*","");
					if (StrContains(targn,targwithout) != -1) GetEntityClassname(i,tmptarg,sizeof(tmptarg));
				}
				else if (StrContains(tmptarg,"*",false) >= 1)
				{
					char targwithout[128];
					Format(targwithout,sizeof(targwithout),"%s",tmptarg);
					ReplaceString(targwithout,sizeof(targwithout),"*","");
					if (StrContains(targn,targwithout) == 0) GetEntityClassname(i,tmptarg,sizeof(tmptarg));
				}
				else if (StrEqual(targn,tmptarg))
				{
					GetEntityClassname(i,tmptarg,sizeof(tmptarg));
				}
			}
		}
	}
}

findpointtp(int ent, char[] targn, int cl, float delay)
{
	int thisent = FindEntityByClassname(ent,"point_teleport");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[32];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		char pttarget[32];
		GetEntPropString(thisent,Prop_Data,"m_target",pttarget,sizeof(pttarget));
		if ((StrEqual(targn,enttargn,false)) && (StrEqual(pttarget,"!activator",false)) && (cl != 0))
		{
			float origin[3];
			GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",origin);
			float angs[3];
			GetEntPropVector(thisent,Prop_Data,"m_angAbsRotation",angs);
			origin[2]+=5.0;
			//PrintToServer("Teleport %i to %i %s",cl,thisent,enttargn);
			if (delay > 0.1)
			{
				Handle dp = CreateDataPack();
				WritePackCell(dp, cl);
				WritePackFloat(dp,origin[0]);
				WritePackFloat(dp,origin[1]);
				WritePackFloat(dp,origin[2]);
				WritePackFloat(dp,angs[0]);
				WritePackFloat(dp,angs[1]);
				CreateTimer(delay,teleportdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
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
				Handle dp = CreateDataPack();
				WritePackFloat(dp,origin[0]);
				WritePackFloat(dp,origin[1]);
				WritePackFloat(dp,origin[2]);
				WritePackFloat(dp,angs[0]);
				WritePackFloat(dp,angs[1]);
				CreateTimer(delay,teleportdelayallply,dp,TIMER_FLAG_NO_MAPCHANGE);
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
}

findxenporttp(int ent, char[] cls, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[32];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1) CreateTimer(delay,xenspawndelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			else
			{
				if (HasEntProp(thisent,Prop_Data,"m_iszNPCClassname"))
				{
					char clschk[24];
					GetEntPropString(thisent,Prop_Data,"m_iszNPCClassname",clschk,sizeof(clschk));
					if (strlen(clschk) < 1)
					{
						int dispent = CreateEntityByName("env_sprite");
						if (dispent != -1)
						{
							float origin[3];
							float angs[3];
							if (HasEntProp(thisent,Prop_Data,"m_angRotation")) GetEntPropVector(thisent,Prop_Data,"m_angRotation",angs);
							if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",origin);
							else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",origin);
							DispatchKeyValue(dispent,"model","materials/effects/tele_exit.vmt");
							DispatchKeyValue(dispent,"scale","0.4");
							DispatchKeyValue(dispent,"rendermode","2");
							origin[2]+=25.0;
							TeleportEntity(dispent,origin,angs,NULL_VECTOR);
							DispatchSpawn(dispent);
							ActivateEntity(dispent);
							CreateTimer(0.1,reducescale,dispent,TIMER_FLAG_NO_MAPCHANGE);
						}
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
						EmitSoundToAll(snd, thisent, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
						AcceptEntityInput(thisent,"FireUser2");
					}
					else
						AcceptEntityInput(thisent,"Spawn");
				}
				else
					AcceptEntityInput(thisent,"Spawn");
			}
		}
		findxenporttp(thisent,cls,targn,delay);
	}
}

findsentriesd(int ent, char[] cls, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[32];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1) CreateTimer(delay,sentryddelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			else AcceptEntityInput(thisent,"Enable");
		}
		findsentriesd(thisent,cls,targn,delay);
	}
}

findsentriesr(int ent, char[] cls, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[32];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1) CreateTimer(delay,sentryrdelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			else AcceptEntityInput(thisent,"Disable");
		}
		findsentriesr(thisent,cls,targn,delay);
	}
}

public Action sentryddelay(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity > 0))
	{
		AcceptEntityInput(entity,"Enable");
	}
}

public Action sentryrdelay(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity > 0))
	{
		AcceptEntityInput(entity,"Disable");
	}
}

public Action xenspawndelay(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity > 0))
	{
		if (HasEntProp(entity,Prop_Data,"m_iszNPCClassname"))
		{
			char clschk[24];
			GetEntPropString(entity,Prop_Data,"m_iszNPCClassname",clschk,sizeof(clschk));
			if (strlen(clschk) < 1)
			{
				int dispent = CreateEntityByName("env_sprite");
				if (dispent != -1)
				{
					float origin[3];
					float angs[3];
					if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",origin);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
					DispatchKeyValue(dispent,"model","materials/effects/tele_exit.vmt");
					DispatchKeyValue(dispent,"scale","0.4");
					DispatchKeyValue(dispent,"rendermode","2");
					origin[2]+=25.0;
					TeleportEntity(dispent,origin,angs,NULL_VECTOR);
					DispatchSpawn(dispent);
					ActivateEntity(dispent);
					CreateTimer(0.1,reducescale,dispent,TIMER_FLAG_NO_MAPCHANGE);
				}
				int rand = GetRandomInt(1,3);
				char snd[64];
				Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
				EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				AcceptEntityInput(entity,"FireUser2");
			}
			else
				AcceptEntityInput(entity,"Spawn");
		}
		else
			AcceptEntityInput(entity,"Spawn");
	}
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
	float origin[3];
	float angs[3];
	ResetPack(dp);
	origin[0] = ReadPackFloat(dp);
	origin[1] = ReadPackFloat(dp);
	origin[2] = ReadPackFloat(dp);
	angs[0] = ReadPackFloat(dp);
	angs[1] = ReadPackFloat(dp);
	CloseHandle(dp);
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
			if (IsClientConnected(i))
				if (IsClientInGame(i))
					if (IsPlayerAlive(i))
						TeleportEntity(i,origin,angs,NULL_VECTOR);
	}
}

findgfollow(int ent, char[] targn)
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
		CreateTimer(0.1,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
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

public OnClientDisconnect(int client)
{
	votetime[client] = 0.0;
}

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
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
	if (StrEqual(clsnamechk,"npc_turret_floor",false))
	{
		if (HasEntProp(inflictor,Prop_Data,"m_bCarriedByPlayer"))
		{
			if (GetEntProp(inflictor,Prop_Data,"m_bCarriedByPlayer") != 0)
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
		}
		damage = slavezap*tkscale;
		return Plugin_Changed;
	}
	if (FindValueInArray(physboxarr,attacker) != -1)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	if ((attacker == 0) && (inflictor == 0) && (damagetype != 32) && ((StrEqual(clsnamechk,"npc_citizen",false)) || (StrEqual(clsnamechk,"npc_alyx",false))))
	{
		damage = 0.0;
		return Plugin_Changed;
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
			/* Handled within hookent inputs
			else if (StrEqual(clsname,"logic_relay",false))
			{
				HookSingleEntityOutput(i,"OnTimer",EntityOutput:trigtp);
			}
			else if (StrEqual(clsname,"logic_choreographed_scene",false))
			{
				char tmpoutphook[24];
				for (int j = 1;j<17;j++)
				{
					Format(tmpoutphook,sizeof(tmpoutphook),"OnTrigger%i",j);
					HookSingleEntityOutput(i,tmpoutphook,EntityOutput:trigtp);
				}
			}
			else if (StrEqual(clsname,"hud_timer",false))
			{
				HookSingleEntityOutput(i,"OnTimer",EntityOutput:trigtp);
			}
			else if (StrEqual(clsname,"func_door",false))
			{
				HookSingleEntityOutput(i,"OnOpen",EntityOutput:trigtp);
				HookSingleEntityOutput(i,"OnFullyOpen",EntityOutput:trigtp);
				HookSingleEntityOutput(i,"OnClose",EntityOutput:trigtp);
				HookSingleEntityOutput(i,"OnFullyClosed",EntityOutput:trigtp);
			}
			*/
		}
	}
	/* Handled within hookent inputs
	HookEntityOutput("logic_relay","OnTrigger",EntityOutput:trigtp);
	HookEntityOutput("trigger_coop","OnPlayersIn",EntityOutput:trigtp);
	HookEntityOutput("trigger_coop","OnStartTouch",EntityOutput:trigtp);
	HookEntityOutput("trigger_multiple","OnTrigger",EntityOutput:trigtp);
	HookEntityOutput("trigger_multiple","OnStartTouch",EntityOutput:trigtp);
	HookEntityOutput("trigger_once","OnTrigger",EntityOutput:trigtp);
	HookEntityOutput("trigger_once","OnStartTouch",EntityOutput:trigtp);
	HookEntityOutput("point_viewcontrol","OnEndFollow",EntityOutput:trigtp);
	HookEntityOutput("func_button","OnPressed",EntityOutput:trigtp);
	HookEntityOutput("func_button","OnUseLocked",EntityOutput:trigtp);
	HookEntityOutput("math_counter","OnHitMax",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnOpen",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnFullyOpen",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnClose",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnFullyClosed",EntityOutput:trigtp);
	*/
}

public Action rehooksaves(Handle timer)
{
	resetspawners(-1,"env_xen_portal");
	if (GetArraySize(spawnerswait) > 0)
	{
		for (int i = 0;i<GetArraySize(spawnerswait);i++)
		{
			int j = GetArrayCell(spawnerswait,i);
			if (IsValidEntity(j))
			{
				AcceptEntityInput(j,"Enable");
			}
		}
	}
	ClearArray(spawnerswait);
	if (!weapmanagersplaced)
	{
		int weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_smg1");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_ar2");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_pistol");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_357");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_crowbar");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_bugbait");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_physcannon");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_rpg");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_crossbow");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_stunstick");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_slam");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapres = CreateEntityByName("game_weapon_manager");
		if (weapres != -1)
		{
			DispatchKeyValue(weapres,"weaponname","weapon_shotgun");
			DispatchKeyValue(weapres,"maxpieces","20");
			DispatchKeyValue(weapres,"targetname","synweapmanagers");
			DispatchSpawn(weapres);
			ActivateEntity(weapres);
		}
		weapmanagersplaced = true;
	}
	findsavetrigs(-1,"trigger_autosave");
	readoutputsforinputs();
	FindSaveTPHooks();
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

CreateTrig(float origins[3], char[] mdlnum)
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
	resetvehicles(0.0);
}

void resetvehicles(float delay)
{
	if (vehiclemaphook)
	{
		if (delay > 0.0) CreateTimer(delay,recallreset,TIMER_FLAG_NO_MAPCHANGE);
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
	if (customents)
	{
		ClearArray(restorecustoments);
		findcustoments();
	}
}

public Action recallreset(Handle timer)
{
	resetvehicles(0.0);
}

public OnEntityCreated(int entity, const char[] classname)
{
	if ((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false)) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (FindValueInArray(entlist,entity) == -1))
	{
		PushArrayCell(entlist,entity);
		if (((StrEqual(classname,"npc_citizen",false)) || (StrEqual(classname,"npc_alyx",false))) && (!(StrContains(mapbuf,"cd",false) == 0))) SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
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
	if (StrEqual(classname,"phys_bone_follower",false))
	{
		if (GetEntityCount() >= 2000)
		{
			int findrope = FindEntityByClassname(-1,"move_rope");
			if (findrope != -1) AcceptEntityInput(findrope,"kill");
			else
			{
				findrope = FindEntityByClassname(-1,"keyframe_rope");
				if (findrope != -1) AcceptEntityInput(findrope,"kill");
				else
				{
					AcceptEntityInput(entity,"kill");
				}
			}
		}
	}
	if (StrContains(classname,"weapon_",false) != -1)
	{
		int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
		if (sf == 1)
			SetEntityMoveType(entity,MOVETYPE_FLY);
	}
	if (StrEqual(classname,"rpg_missile",false))
	{
		if (IsValidEntity(entity))
		{
			CreateTimer(0.3,resetown,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if ((IsValidEntity(entity)) && (customspawners))
	{
		if (HasEntProp(entity,Prop_Data,"m_iName"))
		{
			CreateTimer(0.1,custent,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if ((IsValidEntity(entity)) && (customents) && (StrEqual(classname,"prop_ragdoll",false)))
	{
		if (HasEntProp(entity,Prop_Data,"m_strSourceClassName"))
		{
			char clschk[32];
			GetEntPropString(entity,Prop_Data,"m_strSourceClassName",clschk,sizeof(clschk));
			char mdl[128];
			GetEntPropString(entity,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrEqual(clschk,"npc_zombie_scientist"))
			{
				if (StrEqual(mdl,"models/zombie/classic_torso.mdl",false))
				{
					DispatchKeyValue(entity,"model","models/zombies/zombie_sci_torso.mdl");
					SetEntityModel(entity,"models/zombies/zombie_sci_torso.mdl");
				}
			}
			else if (StrEqual(clschk,"npc_zombie_security"))
			{
				if (StrEqual(mdl,"models/zombie/zombie_soldier.mdl",false))
				{
					DispatchKeyValue(entity,"model","models/zombies/zombie_guard.mdl");
					SetEntityModel(entity,"models/zombies/zombie_guard.mdl");
				}
			}
			CreateTimer(0.1,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if ((StrEqual(classname,"helicopter_chunk",false)) && (customents))
	{
		CreateTimer(0.1,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if ((StrEqual(classname,"npc_grenade_frag",false)) && (customents))
	{
		if (FindValueInArray(grenlist,entity) == -1)
			PushArrayCell(grenlist,entity);
	}
	if (StrEqual(classname,"npc_ichthyosaur",false))
	{
		SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
		SDKHookEx(entity,SDKHook_Think,ichythink);
		if ((FindStringInArray(precachedarr,classname) == -1) && (FileExists("sound\\npc\\ichthyosaur\\watermove3.wav",true,NULL_STRING)))
		{
			PrecacheSound("npc\\ichthyosaur\\watermove1.wav",true);
			PrecacheSound("npc\\ichthyosaur\\watermove2.wav",true);
			PrecacheSound("npc\\ichthyosaur\\watermove3.wav",true);
			PrecacheSound("npc\\ichthyosaur\\underwatermove1.wav",true);
			PrecacheSound("npc\\ichthyosaur\\underwatermove2.wav",true);
			PrecacheSound("npc\\ichthyosaur\\underwatermove3.wav",true);
			PrecacheSound("npc\\ichthyosaur\\die1.wav",true);
			PushArrayString(precachedarr,classname);
		}
	}
	if (((StrEqual(classname,"item_healthkit",false)) || (StrEqual(classname,"item_health_drop",false)) || (StrEqual(classname,"item_battery",false))) && (customents))
	{
		CreateTimer(0.1,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if ((StrEqual(classname,"npc_antlion",false)) || (StrEqual(classname,"npc_antlion_worker",false)) || (StrEqual(classname,"npc_gargantua",false)))
	{
		CreateTimer(0.5,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnEntityDestroyed(int entity)
{
	int find = FindValueInArray(hounds,entity);
	if (find != -1)
	{
		int mdl = GetArrayCell(houndsmdl,find);
		if (IsValidEntity(mdl))
			AcceptEntityInput(mdl,"kill");
		RemoveFromArray(hounds,find);
		RemoveFromArray(houndsmdl,find);
	}
	find = FindValueInArray(squids,entity);
	if (find != -1)
	{
		int mdl = GetArrayCell(squidsmdl,find);
		if (IsValidEntity(mdl))
			AcceptEntityInput(mdl,"kill");
		RemoveFromArray(squids,find);
		RemoveFromArray(squidsmdl,find);
	}
	find = FindValueInArray(tents,entity);
	if (find != -1)
	{
		int mdl = GetArrayCell(tentsmdl,find);
		if (IsValidEntity(mdl))
			AcceptEntityInput(mdl,"kill");
		RemoveFromArray(tents,find);
		RemoveFromArray(tentsmdl,find);
		RemoveFromArray(tentssnd,find);
	}
	find = FindValueInArray(tripmines,entity);
	if (find != -1)
	{
		if (HasEntProp(entity,Prop_Data,"m_hEffectEntity"))
		{
			int beam = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			if (IsValidEntity(beam))
				AcceptEntityInput(beam,"kill");
		}
		if (HasEntProp(entity,Prop_Data,"m_hOwnerEntity"))
		{
			int expl = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
			if (IsValidEntity(expl))
				AcceptEntityInput(expl,"kill");
		}
		RemoveFromArray(tripmines,find);
	}
	find = FindValueInArray(grenlist,entity);
	if (find != -1) RemoveFromArray(grenlist,find);
}

public Action OnCDeath(const char[] output, int caller, int activator, float delay)
{
	int find = FindValueInArray(hounds,caller);
	if (find != -1)
	{
		int mdl = GetArrayCell(houndsmdl,find);
		if (IsValidEntity(mdl))
			AcceptEntityInput(mdl,"kill");
		RemoveFromArray(hounds,find);
		RemoveFromArray(houndsmdl,find);
	}
	find = FindValueInArray(squids,caller);
	if (find != -1)
	{
		int mdl = GetArrayCell(squidsmdl,find);
		if (IsValidEntity(mdl))
			AcceptEntityInput(mdl,"kill");
		RemoveFromArray(squids,find);
		RemoveFromArray(squidsmdl,find);
	}
	find = FindValueInArray(tents,caller);
	if (find != -1)
	{
		int mdl = GetArrayCell(tentsmdl,find);
		if (IsValidEntity(mdl))
			AcceptEntityInput(mdl,"kill");
		RemoveFromArray(tents,find);
		RemoveFromArray(tentsmdl,find);
		RemoveFromArray(tentssnd,find);
	}
	find = FindValueInArray(tripmines,caller);
	if (find != -1)
	{
		if (HasEntProp(caller,Prop_Data,"m_hEffectEntity"))
		{
			int beam = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if (IsValidEntity(beam))
				AcceptEntityInput(beam,"kill");
		}
		if (HasEntProp(caller,Prop_Data,"m_hOwnerEntity"))
		{
			int expl = GetEntPropEnt(caller,Prop_Data,"m_hOwnerEntity");
			if (IsValidEntity(expl))
				AcceptEntityInput(expl,"kill");
		}
		RemoveFromArray(tripmines,find);
	}
	find = FindValueInArray(grenlist,caller);
	if (find != -1) RemoveFromArray(grenlist,find);
}

public Action MineFieldTouch(const char[] output, int caller, int activator, float delay)
{
	float orgs[3];
	float angs[3];
	angs[0] = 90.0;
	if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",orgs);
	else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",orgs);
	float fhitpos[3];
	Handle hhitpos = INVALID_HANDLE;
	TR_TraceRay(orgs,angs,MASK_SHOT,RayType_Infinite);
	TR_GetEndPosition(fhitpos,hhitpos);
	int endpoint = CreateEntityByName("env_explosion");
	TeleportEntity(endpoint,fhitpos,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpoint,"imagnitude","300");
	DispatchKeyValue(endpoint,"targetname","syn_minefieldblast");
	DispatchKeyValue(endpoint,"iradiusoverride","150");
	DispatchKeyValue(endpoint,"rendermode","0");
	DispatchKeyValue(endpoint,"spawnflags","9084");
	DispatchSpawn(endpoint);
	ActivateEntity(endpoint);
	AcceptEntityInput(endpoint,"Explode");
}

public Action custent(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		char cls[128];
		if (HasEntProp(entity,Prop_Data,"m_iName")) GetEntPropString(entity,Prop_Data,"m_iName",cls,sizeof(cls));
		if (strlen(cls) > 0)
		{
			Handle dp = CreateDataPack();
			if (StrContains(cls,"pttemplate",false) == 0)
			{
				ReplaceStringEx(cls,sizeof(cls),"pttemplate","");
				findpts(cls,0.0);
				AcceptEntityInput(entity,"Kill");
			}
			else if (StrContains(cls,"npc_human_security",false) == 0)
			{
				if (FileExists("models/humans/guard.mdl",true,NULL_STRING))
				{
					if (FindStringInArray(precachedarr,"npc_human_security") == -1)
					{
						char humansecp[128];
						Format(humansecp,sizeof(humansecp),"sound/vo/npc/barneys/");
						recursion(humansecp);
						PushArrayString(precachedarr,"npc_human_security");
					}
					DispatchKeyValue(entity,"classname","npc_human_security");
					ReplaceString(cls,sizeof(cls),"npc_human_security","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/guard.mdl");
					WritePackString(dp,"models/humans/guard.mdl");
				}
			}
			else if (StrContains(cls,"npc_human_scientist",false) == 0)
			{
				if (FileExists("models/humans/scientist.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_human_scientist");
					ReplaceString(cls,sizeof(cls),"npc_human_scientist","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					int rand = GetRandomInt(0,1);
					if (rand == 0)
					{
						DispatchKeyValue(entity,"model","models/humans/scientist.mdl");
						WritePackString(dp,"models/humans/scientist.mdl");
					}
					else
					{
						DispatchKeyValue(entity,"model","models/humans/scientist_02.mdl");
						WritePackString(dp,"models/humans/scientist_02.mdl");
					}
					setuprelations(cls);
				}
			}
			else if (StrContains(cls,"npc_human_scientist_female",false) == 0)
			{
				if (FileExists("models/humans/scientist_female.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_human_scientist_female");
					ReplaceString(cls,sizeof(cls),"npc_human_scientist_female","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/scientist_female.mdl");
					WritePackString(dp,"models/humans/scientist_female.mdl");
				}
			}
			else if (StrContains(cls,"npc_alien_slave",false) == 0)
			{
				if (FileExists("models/vortigaunt_slave.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					DispatchKeyValue(entity,"classname","npc_alien_slave");
					ReplaceString(cls,sizeof(cls),"npc_alien_slave","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/vortigaunt_slave.mdl");
					WritePackString(dp,"models/vortigaunt_slave.mdl");
					setuprelations(cls);
					SDKHookEx(entity,SDKHook_Think,aslavethink);
				}
			}
			else if (StrContains(cls,"npc_zombie_security_torso",false) == 0)
			{
				if (FileExists("models/zombies/zombie_guard_torso.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_zombie_security_torso");
					ReplaceString(cls,sizeof(cls),"npc_zombie_security_torso","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/zombies/zombie_guard_torso.mdl");
					WritePackString(dp,"models/zombies/zombie_guard_torso.mdl");
					SDKHookEx(entity,SDKHook_Think,zomthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,zomtkdmg);
				}
			}
			else if (StrContains(cls,"npc_zombie_security",false) == 0)
			{
				if (FileExists("models/zombies/zombie_guard.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_zombie_security");
					ReplaceString(cls,sizeof(cls),"npc_zombie_security","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/zombies/zombie_guard.mdl");
					WritePackString(dp,"models/zombies/zombie_guard.mdl");
					setuprelations(cls);
					SDKHookEx(entity,SDKHook_Think,zomthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,zomtkdmg);
				}
			}
			else if (StrContains(cls,"npc_zombie_scientist_torso",false) == 0)
			{
				if (FileExists("models/zombies/zombie_sci_torso.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_zombie_scientist_torso");
					ReplaceString(cls,sizeof(cls),"npc_zombie_scientist_torso","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/zombies/zombie_sci_torso.mdl");
					WritePackString(dp,"models/zombies/zombie_sci_torso.mdl");
					SDKHookEx(entity,SDKHook_Think,zomthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,zomtkdmg);
				}
			}
			else if (StrContains(cls,"npc_zombie_scientist",false) == 0)
			{
				if (FileExists("models/zombies/zombie_sci.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_zombie_scientist");
					ReplaceString(cls,sizeof(cls),"npc_zombie_scientist","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/zombies/zombie_sci.mdl");
					WritePackString(dp,"models/zombies/zombie_sci.mdl");
					setuprelations(cls);
					SDKHookEx(entity,SDKHook_Think,zomthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,zomtkdmg);
				}
			}
			else if (StrContains(cls,"npc_human_grunt",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_human_grunt");
					ReplaceString(cls,sizeof(cls),"npc_human_grunt","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/marine.mdl");
					WritePackString(dp,"models/humans/marine.mdl");
					int rand = GetRandomInt(0,70);
					if ((rand >= 32) && (rand <= 35)) rand = GetRandomInt(0,31);
					else if ((rand >= 40) && (rand <= 43)) rand = GetRandomInt(36,39);
					else if ((rand >= 56) && (rand <= 59)) rand = GetRandomInt(60,70);
					SetVariantInt(rand);
					AcceptEntityInput(entity,"SetBodyGroup");
				}
			}
			else if (StrContains(cls,"npc_human_commander",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_human_commander");
					ReplaceString(cls,sizeof(cls),"npc_human_commander","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/marine.mdl");
					WritePackString(dp,"models/humans/marine.mdl");
					int rand = GetRandomInt(0,70);
					if ((rand >= 32) && (rand <= 35)) rand = GetRandomInt(0,31);
					else if ((rand >= 40) && (rand <= 43)) rand = GetRandomInt(36,39);
					else if ((rand >= 56) && (rand <= 59)) rand = GetRandomInt(60,70);
					SetVariantInt(rand);
					AcceptEntityInput(entity,"SetBodyGroup");
					//SetEntProp(entity,Prop_Data,"m_fIsElite",1);
				}
			}
			else if (StrContains(cls,"npc_human_grenadier",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					DispatchKeyValue(entity,"classname","npc_human_grenadier");
					ReplaceString(cls,sizeof(cls),"npc_human_grenadier","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/marine.mdl");
					WritePackString(dp,"models/humans/marine.mdl");
					int rand = GetRandomInt(0,70);
					if ((rand >= 32) && (rand <= 35)) rand = GetRandomInt(0,31);
					else if ((rand >= 40) && (rand <= 43)) rand = GetRandomInt(36,39);
					else if ((rand >= 56) && (rand <= 59)) rand = GetRandomInt(60,70);
					SetVariantInt(rand);
					AcceptEntityInput(entity,"SetBodyGroup");
				}
			}
			else if (StrContains(cls,"npc_human_medic",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_human_medic");
					ReplaceString(cls,sizeof(cls),"npc_human_medic","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/marine.mdl");
					WritePackString(dp,"models/humans/marine.mdl");
					int rand = GetRandomInt(0,2);
					if (rand == 0) rand = GetRandomInt(32,35);
					else if (rand == 1) rand = GetRandomInt(40,43);
					else if (rand == 2) rand = GetRandomInt(56,59);
					SetVariantInt(rand);
					AcceptEntityInput(entity,"SetBodyGroup");
				}
			}
			else if (StrContains(cls,"npc_osprey",false) == 0)
			{
				if (FileExists("models/props_vehicles/osprey.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_osprey");
					ReplaceString(cls,sizeof(cls),"npc_osprey","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/props_vehicles/osprey.mdl");
					WritePackString(dp,"models/props_vehicles/osprey.mdl");
				}
			}
			else if (StrContains(cls,"npc_houndeye",false) == 0)
			{
				if (FileExists("models/xenians/houndeye.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					DispatchKeyValue(entity,"classname","npc_houndeye");
					ReplaceString(cls,sizeof(cls),"npc_houndeye","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/houndeye.mdl");
					WritePackString(dp,"models/xenians/houndeye.mdl");
					setuprelations(cls);
				}
			}
			else if (StrContains(cls,"npc_bullsquid",false) == 0)
			{
				if (FileExists("models/xenians/bullsquid.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					DispatchKeyValue(entity,"classname","npc_bullsquid");
					ReplaceString(cls,sizeof(cls),"npc_bullsquid","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/bullsquid.mdl");
					WritePackString(dp,"models/xenians/bullsquid.mdl");
				}
			}
			else if (StrContains(cls,"npc_alien_grunt",false) == 0)
			{
				if (FileExists("models/xenians/agrunt.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					DispatchKeyValue(entity,"classname","npc_alien_grunt");
					ReplaceString(cls,sizeof(cls),"npc_alien_grunt","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/agrunt.mdl");
					WritePackString(dp,"models/xenians/agrunt.mdl");
					SDKHookEx(entity,SDKHook_Think,agruntthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,agrunttkdmg);
					setuprelations(cls);
				}
			}
			else if (StrContains(cls,"npc_alien_grunt_unarmored",false) == 0)
			{
				if (FileExists("models/xenians/agrunt_unarmored.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",5);
					DispatchKeyValue(entity,"classname","npc_alien_grunt_unarmored");
					ReplaceString(cls,sizeof(cls),"npc_alien_grunt_unarmored","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/agrunt_unarmored.mdl");
					WritePackString(dp,"models/xenians/agrunt_unarmored.mdl");
					setuprelations(cls);
				}
			}
			else if (StrContains(cls,"npc_snark",false) == 0)
			{
				if (FileExists("models/xenians/snark.mdl",true,NULL_STRING))
				{
					if (FindStringInArray(precachedarr,"npc_snark") == -1)
					{
						char searchprecache[128];
						Format(searchprecache,sizeof(searchprecache),"sound/npc/snark/");
						recursion(searchprecache);
						PushArrayString(precachedarr,"npc_snark");
					}
					DispatchKeyValue(entity,"classname","npc_snark");
					ReplaceString(cls,sizeof(cls),"npc_snark","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/snark.mdl");
					WritePackString(dp,"models/xenians/snark.mdl");
					SDKHookEx(entity,SDKHook_Think,snarkthink);
					SDKHook(entity,SDKHook_StartTouch,StartTouchSnark);
				}
			}
			else if (StrContains(cls,"npc_abrams",false) == 0)
			{
				if (FileExists("models/props_vehicles/abrams.mdl",true,NULL_STRING))
				{
					if (FindStringInArray(precachedarr,"npc_abrams") == -1)
					{
						PrecacheSound("weapons/weap_explode/explode3.wav",true);
						PrecacheSound("weapons/weap_explode/explode4.wav",true);
						PrecacheSound("weapons/weap_explode/explode5.wav",true);
						PushArrayString(precachedarr,"npc_abrams");
					}
					DispatchKeyValue(entity,"classname","npc_abrams");
					ReplaceString(cls,sizeof(cls),"npc_abrams","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/props_vehicles/abrams.mdl");
					CloseHandle(dp);
					dp = INVALID_HANDLE;
					float vmins[3];
					float vmaxs[3];
					GetEntPropVector(entity,Prop_Data,"m_vecMins",vmins);
					GetEntPropVector(entity,Prop_Data,"m_vecMaxs",vmaxs);
					float orgs[3];
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
					float angs[3];
					GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
					int mainturret = CreateEntityByName("func_tank");
					if (mainturret != -1)
					{
						DispatchKeyValue(mainturret,"spawnflags","1");
						DispatchKeyValue(mainturret,"model","*1");
						DispatchKeyValue(mainturret,"yawrate","30");
						DispatchKeyValue(mainturret,"yawrange","180");
						DispatchKeyValue(mainturret,"yawtolerance","45");
						DispatchKeyValue(mainturret,"pitchtolerance","45");
						DispatchKeyValue(mainturret,"pitchrange","60");
						DispatchKeyValue(mainturret,"pitchrate","120");
						DispatchKeyValue(mainturret,"barrel","100");
						DispatchKeyValue(mainturret,"barrelz","8");
						DispatchKeyValue(mainturret,"bullet","3");
						DispatchKeyValue(mainturret,"ignoregraceupto","768");
						DispatchKeyValue(mainturret,"firerate","15");
						DispatchKeyValue(mainturret,"firespread","3");
						DispatchKeyValue(mainturret,"persistence","3");
						DispatchKeyValue(mainturret,"maxRange","2048");
						DispatchKeyValue(mainturret,"spritescale","1");
						DispatchKeyValue(mainturret,"gun_base_attach","minigun1_base");
						DispatchKeyValue(mainturret,"gun_barrel_attach","minigun1_muzzle");
						DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun1_yaw"); //aim_yaw
						//DispatchKeyValue(mainturret,"gun_pitch_pose_param","aim_pitch");
						DispatchKeyValue(mainturret,"ammo_count","-1");
						DispatchKeyValue(mainturret,"effecthandling","1");
						TeleportEntity(mainturret,orgs,angs,NULL_VECTOR);
						DispatchSpawn(mainturret);
						ActivateEntity(mainturret);
						SetVariantString("!activator");
						AcceptEntityInput(mainturret,"SetParent",entity);
						SetVariantString("minigun1");
						AcceptEntityInput(mainturret,"SetParentAttachment");
						SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
						SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
						SetVariantString("!player");
						AcceptEntityInput(mainturret,"SetTargetEntityName");
					}
					int turretflash = CreateEntityByName("env_muzzleflash");
					if (turretflash != -1)
					{
						DispatchKeyValue(turretflash,"scale","5");
						DispatchSpawn(turretflash);
						ActivateEntity(turretflash);
						SetVariantString("!activator");
						AcceptEntityInput(turretflash,"SetParent",entity);
						SetVariantString("muzzle");
						AcceptEntityInput(turretflash,"SetParentAttachment");
						SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",turretflash);
					}
					/* Do in think rpg_missile
					mainturret = CreateEntityByName("func_tankrocket");
					if (mainturret != -1)
					{
						DispatchKeyValue(mainturret,"spawnflags","1");
						DispatchKeyValue(mainturret,"model","*1");
						DispatchKeyValue(mainturret,"yawrate","30");
						DispatchKeyValue(mainturret,"yawrange","180");
						DispatchKeyValue(mainturret,"yawtolerance","45");
						DispatchKeyValue(mainturret,"pitchtolerance","45");
						DispatchKeyValue(mainturret,"pitchrange","60");
						DispatchKeyValue(mainturret,"pitchrate","120");
						DispatchKeyValue(mainturret,"barrel","0");
						DispatchKeyValue(mainturret,"barrelz","5");
						DispatchKeyValue(mainturret,"bullet","3");
						DispatchKeyValue(mainturret,"ignoregraceupto","768");
						DispatchKeyValue(mainturret,"firerate","1");
						DispatchKeyValue(mainturret,"firespread","2");
						DispatchKeyValue(mainturret,"persistence","3");
						DispatchKeyValue(mainturret,"maxRange","2048");
						DispatchKeyValue(mainturret,"spritescale","1");
						DispatchKeyValue(mainturret,"gun_base_attach","gunbase");
						DispatchKeyValue(mainturret,"gun_barrel_attach","gun");
						DispatchKeyValue(mainturret,"gun_yaw_pose_param","aim_yaw");
						DispatchKeyValue(mainturret,"gun_pitch_pose_param","aim_pitch");
						DispatchKeyValue(mainturret,"ammo_count","-1");
						DispatchKeyValue(mainturret,"effecthandling","0");
						DispatchKeyValue(mainturret,"rocketspeed","9999");
						TeleportEntity(mainturret,orgs,angs,NULL_VECTOR);
						DispatchSpawn(mainturret);
						ActivateEntity(mainturret);
						SetVariantString("!activator");
						AcceptEntityInput(mainturret,"SetParent",entity);
						SetVariantString("muzzle");
						AcceptEntityInput(mainturret,"SetParentAttachment");
						SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
						SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
						SetVariantString("!player");
						AcceptEntityInput(mainturret,"SetTargetEntityName");
					}
					*/
					mainturret = CreateEntityByName("func_tank");
					if (mainturret != -1)
					{
						DispatchKeyValue(mainturret,"spawnflags","1");
						DispatchKeyValue(mainturret,"model","*1");
						DispatchKeyValue(mainturret,"yawrate","30");
						DispatchKeyValue(mainturret,"yawrange","180");
						DispatchKeyValue(mainturret,"yawtolerance","45");
						DispatchKeyValue(mainturret,"pitchtolerance","45");
						DispatchKeyValue(mainturret,"pitchrange","60");
						DispatchKeyValue(mainturret,"pitchrate","120");
						DispatchKeyValue(mainturret,"barrel","100");
						DispatchKeyValue(mainturret,"barrelz","8");
						DispatchKeyValue(mainturret,"bullet","3");
						DispatchKeyValue(mainturret,"ignoregraceupto","768");
						DispatchKeyValue(mainturret,"firerate","15");
						DispatchKeyValue(mainturret,"firespread","3");
						DispatchKeyValue(mainturret,"persistence","3");
						DispatchKeyValue(mainturret,"maxRange","2048");
						DispatchKeyValue(mainturret,"spritescale","1");
						DispatchKeyValue(mainturret,"gun_base_attach","minigun2_base");
						DispatchKeyValue(mainturret,"gun_barrel_attach","minigun2_muzzle");
						DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun2_yaw");
						DispatchKeyValue(mainturret,"ammo_count","-1");
						DispatchKeyValue(mainturret,"effecthandling","1");
						TeleportEntity(mainturret,orgs,angs,NULL_VECTOR);
						DispatchSpawn(mainturret);
						ActivateEntity(mainturret);
						SetVariantString("!activator");
						AcceptEntityInput(mainturret,"SetParent",entity);
						SetVariantString("minigun2");
						AcceptEntityInput(mainturret,"SetParentAttachment");
						SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
						SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
						SetVariantString("!player");
						AcceptEntityInput(mainturret,"SetTargetEntityName");
					}
					//WritePackString(dp,"models/props_vehicles/abrams.mdl");
					if (HasEntProp(entity,Prop_Data,"m_iHealth"))
					{
						int hchk = GetEntProp(entity,Prop_Data,"m_iHealth");
						int maxh = 500;
						if (hchk != maxh)
						{
							SetEntProp(entity,Prop_Data,"m_iMaxHealth",maxh);
							SetEntProp(entity,Prop_Data,"m_iHealth",maxh);
						}
					}
					SDKHookEx(entity,SDKHook_Think,abramsthink);
				}
			}
			else return Plugin_Handled;
			if (FindValueInArray(entlist,entity) == -1)
				PushArrayCell(entlist,entity);
			if (dp != INVALID_HANDLE)
			{
				WritePackCell(dp,entity);
				CreateTimer(0.1,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			float origin[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",origin);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
			if (TR_PointOutsideWorld(origin))
			{
				origin[2]+=20.0;
				if (TR_PointOutsideWorld(origin))
				{
					origin[2]+=20.0;
					if (!TR_PointOutsideWorld(origin))
					{
						TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
					}
				}
				else
					TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
			}
			origin[2]+=60.0;
			if (TR_PointOutsideWorld(origin))
			{
				origin[2]-=20.0;
				if (TR_PointOutsideWorld(origin))
				{
					origin[2]-=20.0;
					if (!TR_PointOutsideWorld(origin))
					{
						TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
					}
				}
				else
					TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
			}
			if (GetArraySize(customrelations) > 0)
			{
				for (int i = 0;i<GetArraySize(customrelations);i++)
				{
					int j = GetArrayCell(customrelations,i);
					if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
				}
			}
		}
	}
	return Plugin_Handled;
}

void setuprelations(char[] cls)
{
	bool foundrelations = false;
	if (GetArraySize(customrelations) < 1) FindRelations(-1,cls);
	else
	{
		for (int i = 0;i<GetArraySize(customrelations);i++)
		{
			int j = GetArrayCell(customrelations,i);
			if (IsValidEntity(j))
			{
				if (HasEntProp(j,Prop_Data,"m_iszSubject"))
				{
					char target[32];
					GetEntPropString(j,Prop_Data,"m_iszSubject",target,sizeof(target));
					if (StrEqual(target,cls,false)) foundrelations = true;
				}
			}
		}
	}
	if (foundrelations)
	{
		if (GetArraySize(customrelations) > 0)
		{
			for (int i = 0;i<GetArraySize(customrelations);i++)
			{
				int j = GetArrayCell(customrelations,i);
				if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
			}
		}
		return;
	}
	if ((StrEqual(cls,"npc_alien_slave",false)) || (StrEqual(cls,"npc_alien_grunt",false)) || (StrEqual(cls,"npc_alien_grunt_unarmored",false)))
	{
		Handle zapdmg = FindConVar("sk_alien_slave_dmg_zap");
		Handle zapover = FindConVar("sk_vortigaunt_dmg_zap");
		if ((zapdmg != INVALID_HANDLE) && (zapover != INVALID_HANDLE))
		{
			int dmgchk = GetConVarInt(zapdmg);
			SetConVarInt(zapdmg,dmgchk,false,false);
			SetConVarInt(zapover,dmgchk,false,false);
		}
		CloseHandle(zapdmg);
		CloseHandle(zapover);
		int aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_alien_slave");
		DispatchKeyValue(aidisp,"target","player");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","3");
		DispatchKeyValue(aidisp,"subject","npc_alien_slave");
		DispatchKeyValue(aidisp,"target","npc_alien_grunt");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","99");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_alien_grunt");
		DispatchKeyValue(aidisp,"target","npc_human_grenadier");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_alien_grunt");
		DispatchKeyValue(aidisp,"target","npc_human_commander");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_alien_grunt");
		DispatchKeyValue(aidisp,"target","npc_human_medic");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_alien_grunt");
		DispatchKeyValue(aidisp,"target","npc_human_grunt");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_turret_ceiling");
		DispatchKeyValue(aidisp,"target","npc_alien_grunt");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","40");
		DispatchKeyValue(aidisp,"reciprocal","0");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","3");
		DispatchKeyValue(aidisp,"subject","npc_alien_grunt");
		DispatchKeyValue(aidisp,"target","npc_headcrab");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","99");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
	}
	else if (StrEqual(cls,"npc_houndeye",false))
	{
		int aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_houndeye");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_security");
		DispatchKeyValue(aidisp,"target","npc_houndeye");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","3");
		DispatchKeyValue(aidisp,"subject","npc_houndeye");
		DispatchKeyValue(aidisp,"target","npc_alien_slave");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
	}
	else if ((StrEqual(cls,"npc_zombie_scientist",false)) || (StrEqual(cls,"npc_zombie_security",false)))
	{
		int aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_zombie_security");
		DispatchKeyValue(aidisp,"target","npc_human_security");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","99");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","3");
		DispatchKeyValue(aidisp,"subject","npc_zombie_security");
		DispatchKeyValue(aidisp,"target","npc_gman");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","99");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_zombie_scientist");
		DispatchKeyValue(aidisp,"target","npc_human_security");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","99");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","3");
		DispatchKeyValue(aidisp,"subject","npc_zombie_scientist");
		DispatchKeyValue(aidisp,"target","npc_gman");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","99");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_barnacle");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
	}
	else if (StrEqual(cls,"npc_human_scientist",false))
	{
		int aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_turret_floor");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_human_grunt");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_human_commander");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_human_grenadier");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_human_medic");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_alien_slave");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_alien_grunt");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_human_scientist");
		DispatchKeyValue(aidisp,"target","npc_barnacle");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
	}
	else if (StrEqual(cls,"npc_abrams",false))
	{
		int aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_abrams");
		DispatchKeyValue(aidisp,"target","player");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_abrams");
		DispatchKeyValue(aidisp,"target","npc_alien_slave");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
		aidisp = CreateEntityByName("ai_relationship");
		DispatchKeyValue(aidisp,"disposition","1");
		DispatchKeyValue(aidisp,"subject","npc_abrams");
		DispatchKeyValue(aidisp,"target","npc_alien_grunt");
		DispatchKeyValue(aidisp,"targetname","syn_relations");
		DispatchKeyValue(aidisp,"rank","80");
		DispatchKeyValue(aidisp,"reciprocal","1");
		DispatchKeyValue(aidisp,"StartActive","1");
		DispatchSpawn(aidisp);
		ActivateEntity(aidisp);
		AcceptEntityInput(aidisp,"ApplyRelationship");
		PushArrayCell(customrelations,aidisp);
	}
	if (GetArraySize(customrelations) > 0)
	{
		for (int i = 0;i<GetArraySize(customrelations);i++)
		{
			int j = GetArrayCell(customrelations,i);
			if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
		}
	}
	return;
}

void FindRelations(int ent, char[] cls)
{
	int thisent = FindEntityByClassname(ent,"ai_relationship");
	if (IsValidEntity(thisent))
	{
		char targn[32];
		GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
		if (StrEqual(targn,"syn_relations",false))
		{
			if (FindValueInArray(customrelations,thisent) == -1) PushArrayCell(customrelations,thisent);
		}
		FindRelations(thisent++,cls);
	}
}

addht(char[] cls, char[] targn)
{
	if (strlen(targn) > 0)
	{
		int find = FindStringInArray(d_li,targn);
		if (find != -1) RemoveFromArray(d_li,find);
		if (FindStringInArray(d_ht,targn) == -1)
		{
			int aidisp = CreateEntityByName("ai_relationship");
			DispatchKeyValue(aidisp,"disposition","1");
			DispatchKeyValue(aidisp,"subject",targn);
			DispatchKeyValue(aidisp,"target","player");
			DispatchKeyValue(aidisp,"rank","80");
			DispatchKeyValue(aidisp,"reciprocal","1");
			DispatchKeyValue(aidisp,"StartActive","1");
			DispatchSpawn(aidisp);
			ActivateEntity(aidisp);
			AcceptEntityInput(aidisp,"ApplyRelationship");
			PushArrayString(d_ht,targn);
		}
	}
	else if (strlen(cls) > 0)
	{
		int find = FindStringInArray(d_li,targn);
		if (find != -1) RemoveFromArray(d_li,find);
		if (FindStringInArray(d_ht,cls) == -1)
		{
			int aidisp = CreateEntityByName("ai_relationship");
			DispatchKeyValue(aidisp,"disposition","1");
			DispatchKeyValue(aidisp,"subject",cls);
			DispatchKeyValue(aidisp,"target","player");
			DispatchKeyValue(aidisp,"rank","80");
			DispatchKeyValue(aidisp,"reciprocal","1");
			DispatchKeyValue(aidisp,"StartActive","1");
			DispatchSpawn(aidisp);
			ActivateEntity(aidisp);
			AcceptEntityInput(aidisp,"ApplyRelationship");
			PushArrayString(d_ht,cls);
		}
	}
}

addli(char[] cls, char[] targn)
{
	if (strlen(targn) > 0)
	{
		int find = FindStringInArray(d_ht,targn);
		if (find != -1) RemoveFromArray(d_ht,find);
		if (FindStringInArray(d_li,targn) == -1)
		{
			int aidisp = CreateEntityByName("ai_relationship");
			DispatchKeyValue(aidisp,"disposition","3");
			DispatchKeyValue(aidisp,"subject",targn);
			DispatchKeyValue(aidisp,"target","player");
			DispatchKeyValue(aidisp,"rank","99");
			DispatchKeyValue(aidisp,"reciprocal","1");
			DispatchKeyValue(aidisp,"StartActive","1");
			DispatchSpawn(aidisp);
			ActivateEntity(aidisp);
			AcceptEntityInput(aidisp,"ApplyRelationship");
			PushArrayString(d_li,targn);
		}
	}
	else if (strlen(cls) > 0)
	{
		int find = FindStringInArray(d_ht,targn);
		if (find != -1) RemoveFromArray(d_ht,find);
		if (FindStringInArray(d_li,cls) == -1)
		{
			int aidisp = CreateEntityByName("ai_relationship");
			DispatchKeyValue(aidisp,"disposition","3");
			DispatchKeyValue(aidisp,"subject",cls);
			DispatchKeyValue(aidisp,"target","player");
			DispatchKeyValue(aidisp,"rank","99");
			DispatchKeyValue(aidisp,"reciprocal","1");
			DispatchKeyValue(aidisp,"StartActive","1");
			DispatchSpawn(aidisp);
			ActivateEntity(aidisp);
			AcceptEntityInput(aidisp,"ApplyRelationship");
			PushArrayString(d_li,cls);
		}
	}
}

void findcustoments()
{
	for (int i = 1;i<2048;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			bool saveent = false;
			if ((FindValueInArray(hounds,i) != -1) || (FindValueInArray(houndsmdl,i) != -1) || (FindValueInArray(squids,i) != -1) || (FindValueInArray(squidsmdl,i) != -1) || (FindValueInArray(tents,i) != -1) || (FindValueInArray(tentsmdl,i) != -1) || (FindValueInArray(tentssnd,i) != -1) || (FindStringInArray(customentlist,clsname) != -1)) saveent = true;
			//if ((StrContains(clsname,"npc_human",false) != -1) || (StrContains(clsname,"npc_zombie_s",false) != -1) || (StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"npc_bullsquid",false)) || (StrEqual(clsname,"npc_osprey",false)) || (StrEqual(clsname,"npc_tentacle",false)) || (StrContains(clsname,"npc_alien",false) != -1))
			//	saveent = true;
			if (saveent)
			{
				Handle dp = packent(i,"");
				if (dp != INVALID_HANDLE)
					PushArrayCell(restorecustoments,dp);
			}
		}
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
		if (GetArraySize(restorecustoments) > 0)
		{
			ClearArray(hounds);
			ClearArray(houndsmdl);
			ClearArray(squids);
			ClearArray(squidsmdl);
			ClearArray(tents);
			ClearArray(tentsmdl);
			ClearArray(tentssnd);
			ClearArray(grenlist);
			ClearArray(tripmines);
			ClearArray(conveyors);
			ClearArray(templateslist);
			findstraymdl(-1,"prop_dynamic");
			findstraymdl(-1,"point_template");
			findstraymdl(-1,"npc_template_maker");
			findstraymdl(-1,"env_xen_portal_template");
			for (int i = 0;i<GetArraySize(restorecustoments);i++)
			{
				Handle dp = GetArrayCell(restorecustoments,i);
				restoreent(dp);
			}
			ClearArray(restorecustoments);
			findstraymdl(-1,"npc_zombie_scientist");
			findstraymdl(-1,"npc_zombie_security");
			findstraymdl(-1,"game_weapon_manager");
			findstraymdl(-1,"item_healthkit");
			findstraymdl(-1,"item_battery");
			resetchargers(-1,"item_healthcharger");
			resetchargers(-1,"item_suitcharger");
		}
	}
	return Plugin_Continue;
}

Handle packent(int i, char[] targpass)
{
	Handle dp = CreateDataPack();
	if (IsValidEntity(i))
	{
		char clsname[32];
		GetEntityClassname(i,clsname,sizeof(clsname));
		char targn[32];
		char mdl[64];
		float porigin[3];
		float angs[3];
		if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",porigin);
		else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",porigin);
		GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
		int curh = 0;
		char vehscript[64];
		char additionalequip[32];
		char spawnflags[32];
		char spawnercls[64];
		char spawnertargn[64];
		char skin[4];
		char hdwtype[4];
		char parentname[32];
		char state[4];
		char npctype[4];
		char npctarg[4];
		char npctargpath[32];
		char defanim[32];
		int doorstate, sleepstate, sequence, parentattach, body;
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
		if (HasEntProp(i,Prop_Data,"m_state"))
		{
			int istate = GetEntProp(i,Prop_Data,"m_state");
			Format(state,sizeof(state),"%i",istate);
		}
		if (HasEntProp(i,Prop_Data,"m_hParent"))
		{
			int parchk = GetEntPropEnt(i,Prop_Data,"m_hParent");
			if (IsValidEntity(parchk))
			{
				if (HasEntProp(parchk,Prop_Data,"m_iName")) GetEntPropString(parchk,Prop_Data,"m_iName",parentname,sizeof(parentname));
			}
		}
		if (HasEntProp(i,Prop_Data,"m_iszNPCClassname")) GetEntPropString(i,Prop_Data,"m_iszNPCClassname",spawnercls,sizeof(spawnercls));
		if (HasEntProp(i,Prop_Data,"m_ChildTargetName")) GetEntPropString(i,Prop_Data,"m_ChildTargetName",spawnertargn,sizeof(spawnertargn));
		if (HasEntProp(i,Prop_Data,"m_eDoorState")) doorstate = GetEntProp(i,Prop_Data,"m_eDoorState");
		if (HasEntProp(i,Prop_Data,"m_SleepState")) sleepstate = GetEntProp(i,Prop_Data,"m_SleepState");
		if (HasEntProp(i,Prop_Data,"m_Type"))
		{
			int inpctype = GetEntProp(i,Prop_Data,"m_Type");
			Format(npctype,sizeof(npctype),"%i",inpctype);
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
		if ((HasEntProp(i,Prop_Data,"m_target")) && (strlen(targpass) < 1))
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
		else if (strlen(targpass) > 0)
		{
			Format(npctargpath,sizeof(npctargpath),targpass);
		}
		if (HasEntProp(i,Prop_Data,"m_nSequence")) sequence = GetEntProp(i,Prop_Data,"m_nSequence");
		if (HasEntProp(i,Prop_Data,"m_iParentAttachment")) parentattach = GetEntProp(i,Prop_Data,"m_iParentAttachment");
		if (HasEntProp(i,Prop_Data,"m_nBody")) body = GetEntProp(i,Prop_Data,"m_nBody");
		if (HasEntProp(i,Prop_Data,"m_iszDefaultAnim")) GetEntPropString(i,Prop_Data,"m_iszDefaultAnim",defanim,sizeof(defanim));
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
		WritePackString(dp,npctarg);
		WritePackString(dp,npctargpath);
		WritePackCell(dp,doorstate);
		WritePackCell(dp,sleepstate);
		WritePackString(dp,npctype);
		WritePackCell(dp,sequence);
		WritePackCell(dp,parentattach);
		WritePackCell(dp,body);
		WritePackString(dp,defanim);
		WritePackString(dp,spawnercls);
		WritePackString(dp,spawnertargn);
		WritePackString(dp,"endofpack");
		return dp;
	}
	CloseHandle(dp);
	return INVALID_HANDLE;
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

void restoreent(Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char clsname[32];
		char targn[32];
		char mdl[64];
		ReadPackString(dp,clsname,sizeof(clsname));
		ReadPackString(dp,targn,sizeof(targn));
		ReadPackString(dp,mdl,sizeof(mdl));
		if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
		int curh = ReadPackCell(dp);
		float porigin[3];
		float angs[3];
		char vehscript[64];
		porigin[0] = ReadPackFloat(dp);
		porigin[1] = ReadPackFloat(dp);
		porigin[2] = ReadPackFloat(dp);
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
		char target[4];
		ReadPackString(dp,target,sizeof(target));
		char targetpath[32];
		ReadPackString(dp,targetpath,sizeof(targetpath));
		int doorstate = ReadPackCell(dp);
		int sleepstate = ReadPackCell(dp);
		char npctype[4];
		ReadPackString(dp,npctype,sizeof(npctype));
		int sequence = ReadPackCell(dp);
		int parentattach = ReadPackCell(dp);
		int body = ReadPackCell(dp);
		char defanim[32];
		ReadPackString(dp,defanim,sizeof(defanim));
		char spawnercls[64];
		char spawnertargn[64];
		ReadPackString(dp,spawnercls,sizeof(spawnercls));
		ReadPackString(dp,spawnertargn,sizeof(spawnertargn));
		char scriptinf[256];
		ReadPackString(dp,scriptinf,sizeof(scriptinf));
		char oldcls[32];
		Format(oldcls,sizeof(oldcls),"%s",clsname);
		if (StrEqual(clsname,"npc_human_scientist_kleiner",false))
			Format(clsname,sizeof(clsname),"npc_kleiner");
		else if (StrEqual(clsname,"npc_human_scientist_eli",false))
			Format(clsname,sizeof(clsname),"npc_eli");
		else if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_human_grenadier",false)))
			Format(clsname,sizeof(clsname),"npc_combine_s");
		else if (StrEqual(clsname,"monster_headcrab",false))
			Format(clsname,sizeof(clsname),"npc_headcrab");
		else if ((StrEqual(clsname,"npc_human_security",false)) && ((!StrEqual(additionalequip,"Default",false)) || (strlen(additionalequip) > 1)))
			Format(clsname,sizeof(clsname),"npc_citizen");
		else if ((StrContains(clsname,"npc_human_",false) != -1) || (StrEqual(clsname,"npc_tentacle",false)) || (StrEqual(clsname,"monster_bullchicken",false)) || (StrEqual(clsname,"monster_cockroach",false)) || (StrEqual(clsname,"monster_human_grunt",false)) || (StrEqual(clsname,"monster_hgrunt_dead",false)) || (StrEqual(clsname,"monster_sentry",false)) || (StrEqual(clsname,"monster_houndeye",false)) || (StrEqual(clsname,"monster_scientist",false)) || (StrEqual(clsname,"monster_osprey",false)) || (StrEqual(clsname,"monster_gman",false)) || (StrEqual(clsname,"monster_scientist_dead",false)) || (StrEqual(clsname,"monster_barney",false)) || (StrEqual(clsname,"monster_barney_dead",false)))
			Format(clsname,sizeof(clsname),"generic_actor");
		else if (StrEqual(clsname,"monster_barnacle",false))
			Format(clsname,sizeof(clsname),"npc_barnacle");
		else if ((StrEqual(clsname,"monster_zombie",false)) || (StrEqual(clsname,"npc_zombie_scientist",false)))
			Format(clsname,sizeof(clsname),"npc_zombie");
		else if (StrEqual(clsname,"npc_zombie_scientist_torso",false))
			Format(clsname,sizeof(clsname),"npc_zombie_torso");
		else if ((StrEqual(clsname,"monster_alien_slave",false)) || (StrEqual(clsname,"npc_alien_slave",false)))
			Format(clsname,sizeof(clsname),"npc_vortigaunt");
		else if ((StrEqual(clsname,"npc_zombie_security",false)) || (StrEqual(clsname,"npc_zombie_security_torso",false)))
			Format(clsname,sizeof(clsname),"npc_zombine");
		else if (StrEqual(clsname,"npc_osprey",false))
			Format(clsname,sizeof(clsname),"npc_combinedropship");
		else if ((StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"npc_bullsquid",false)))
			Format(clsname,sizeof(clsname),"npc_antlion");
		else if (StrEqual(clsname,"npc_snark",false))
			Format(clsname,sizeof(clsname),"npc_headcrab_fast");
		else if ((StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"npc_alien_grunt_unarmored",false)) || (StrEqual(clsname,"npc_abrams",false)))
			Format(clsname,sizeof(clsname),"npc_combine_s");
		else if (StrEqual(clsname,"grenade_tripmine",false))
			Format(clsname,sizeof(clsname),"prop_physics");
		else if (StrEqual(clsname,"npc_apache",false))
			Format(clsname,sizeof(clsname),"npc_helicopter");
		int ent = CreateEntityByName(clsname);
		if ((TR_PointOutsideWorld(porigin)) && (ent != -1))
		{
			AcceptEntityInput(ent,"kill");
			ent = -1;
		}
		if ((ent != -1) && (IsValidEntity(ent)))
		{
			bool setmdl = true;
			if (strlen(targn) > 0) DispatchKeyValue(ent,"targetname",targn);
			DispatchKeyValue(ent,"model",mdl);
			if (strlen(vehscript) > 0) DispatchKeyValue(ent,"VehicleScript",vehscript);
			if (strlen(additionalequip) > 0) DispatchKeyValue(ent,"AdditionalEquipment",additionalequip);
			if (strlen(hdwtype) > 0) DispatchKeyValue(ent,"hardware",hdwtype);
			if (strlen(parentname) > 0) DispatchKeyValue(ent,"ParentName",parentname);
			if (strlen(state) > 0) DispatchKeyValue(ent,"State",state);
			if (strlen(defanim) > 0) DispatchKeyValue(ent,"DefaultAnim",defanim);
			if ((strlen(target) > 0) && (HasEntProp(ent,Prop_Data,"m_hTargetEnt")))
			{
				int targent = StringToInt(target);
				SetEntPropEnt(ent,Prop_Data,"m_hTargetEnt",targent);
			}
			if (strlen(targetpath) > 0) DispatchKeyValue(ent,"target",targetpath);
			if (HasEntProp(ent,Prop_Data,"m_Type")) DispatchKeyValue(ent,"citizentype",npctype);
			if (HasEntProp(ent,Prop_Data,"m_nSequence")) SetEntProp(ent,Prop_Data,"m_nSequence",sequence);
			if (!StrEqual(scriptinf,"endofpack",false))
			{
				char scriptexp[28][64];
				ExplodeString(scriptinf," ",scriptexp,28,64);
				for (int j = 0;j<28;j++)
				{
					int jadd = j+1;
					if ((strlen(scriptexp[j]) > 0) && (strlen(scriptexp[jadd]) > 0))
					{
						//PrintToServer("Pushing %s %s",scriptexp[j],scriptexp[jadd]);
						DispatchKeyValue(ent,scriptexp[j],scriptexp[jadd]);
					}
					j++;
				}
			}
			DispatchKeyValue(ent,"spawnflags",spawnflags);
			DispatchKeyValue(ent,"skin",skin);
			DispatchKeyValue(ent,"classname",oldcls);
			DispatchSpawn(ent);
			ActivateEntity(ent);
			if (curh != 0) SetEntProp(ent,Prop_Data,"m_iHealth",curh);
			TeleportEntity(ent,porigin,angs,NULL_VECTOR);
			if (HasEntProp(ent,Prop_Data,"m_eDoorState")) SetEntProp(ent,Prop_Data,"m_eDoorState",doorstate);
			if (HasEntProp(ent,Prop_Data,"m_SleepState")) SetEntProp(ent,Prop_Data,"m_SleepState",sleepstate);
			if (HasEntProp(ent,Prop_Data,"m_iParentAttachment")) SetEntProp(ent,Prop_Data,"m_iParentAttachment",parentattach);
			if (HasEntProp(ent,Prop_Data,"m_nBody")) SetEntProp(ent,Prop_Data,"m_nBody",body);
			if ((HasEntProp(ent,Prop_Data,"m_iszNPCClassname")) && (strlen(spawnercls) > 0)) SetEntPropString(ent,Prop_Data,"m_iszNPCClassname",spawnercls);
			if ((HasEntProp(ent,Prop_Data,"m_ChildTargetName")) && (strlen(spawnertargn) > 0)) SetEntPropString(ent,Prop_Data,"m_ChildTargetName",spawnertargn);
			if (StrEqual(oldcls,"npc_houndeye",false))
			{
				SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
				PushArrayCell(hounds,ent);
				int entmdl = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
				DispatchKeyValue(entmdl,"solid","0");
				porigin[2]-=5.0;
				TeleportEntity(entmdl,porigin,angs,NULL_VECTOR);
				DispatchSpawn(entmdl);
				ActivateEntity(entmdl);
				SetVariantString("!activator");
				AcceptEntityInput(entmdl,"SetParent",ent);
				PushArrayCell(houndsmdl,entmdl);
				SDKHookEx(ent,SDKHook_Think,houndthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,houndtkdmg);
				HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
				Format(mdl,sizeof(mdl),"models/xenians/houndeye.mdl");
				SetVariantString("0.6");
				AcceptEntityInput(ent,"SetModelScale");
			}
			else if (StrEqual(oldcls,"npc_bullsquid",false))
			{
				SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
				PushArrayCell(squids,ent);
				int entmdl = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
				DispatchKeyValue(entmdl,"solid","0");
				TeleportEntity(entmdl,porigin,angs,NULL_VECTOR);
				DispatchSpawn(entmdl);
				ActivateEntity(entmdl);
				SetVariantString("!activator");
				AcceptEntityInput(entmdl,"SetParent",ent);
				PushArrayCell(squidsmdl,entmdl);
				SDKHookEx(ent,SDKHook_Think,squidthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,squidtkdmg);
				HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
				Format(mdl,sizeof(mdl),"models/xenians/bullsquid.mdl");
				SetVariantString("0.5");
				AcceptEntityInput(ent,"SetModelScale");
			}
			else if (StrEqual(oldcls,"npc_tentacle",false))
			{
				if (FindStringInArray(precachedarr,oldcls) == -1)
				{
					char humanp[128];
					Format(humanp,sizeof(humanp),"sound/npc/tentacle/");
					recursion(humanp);
					PushArrayString(precachedarr,oldcls);
				}
				PushArrayCell(tents,ent);
				int entmdl = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdl,"model","models/xenians/tentacle.mdl");
				DispatchKeyValue(entmdl,"targetname","syn_xeniantentaclemdl");
				DispatchKeyValue(entmdl,"solid","6");
				DispatchKeyValue(entmdl,"DefaultAnim","floor_idle");
				DispatchSpawn(entmdl);
				ActivateEntity(entmdl);
				PushArrayCell(tentsmdl,entmdl);
				int entsnd = CreateEntityByName("ambient_generic");
				DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
				DispatchSpawn(entsnd);
				ActivateEntity(entsnd);
				SetVariantString("!activator");
				AcceptEntityInput(entsnd,"SetParent",entmdl);
				SetVariantString("Eye");
				AcceptEntityInput(entsnd,"SetParentAttachment");
				PushArrayCell(tentssnd,entsnd);
				SDKHookEx(ent,SDKHook_Think,tentaclethink);
				HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
			}
			else if (StrContains(oldcls,"npc_zombie_s",false) == 0)
			{
				SDKHookEx(ent,SDKHook_Think,zomthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
			}
			else if (StrEqual(oldcls,"npc_ichthyosaur",false))
			{
				SDKHookEx(ent,SDKHook_Think,ichythink);
				HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
			}
			else if (StrEqual(oldcls,"npc_human_grenadier",false))
			{
				SDKHookEx(ent,SDKHook_Think,grenthink);
			}
			else if ((StrEqual(oldcls,"npc_alien_grunt")) || (StrEqual(oldcls,"npc_alien_grunt_unarmored")))
			{
				SDKHookEx(ent,SDKHook_Think,agruntthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,agrunttkdmg);
				SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
				HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
			}
			else if (StrEqual(oldcls,"npc_snark"))
			{
				SDKHookEx(ent,SDKHook_Think,snarkthink);
				SDKHook(ent,SDKHook_StartTouch,StartTouchSnark);
			}
			else if (StrEqual(oldcls,"npc_abrams"))
			{
				if (FindStringInArray(precachedarr,"npc_abrams") == -1)
				{
					PrecacheSound("weapons/weap_explode/explode3.wav",true);
					PrecacheSound("weapons/weap_explode/explode4.wav",true);
					PrecacheSound("weapons/weap_explode/explode5.wav",true);
					PushArrayString(precachedarr,"npc_abrams");
				}
				int driver = CreateEntityByName("func_tracktrain");
				if (driver != -1)
				{
					DispatchKeyValue(driver,"target",targetpath);
					DispatchKeyValue(driver,"orientationtype","1");
					DispatchKeyValue(driver,"speed","80");
					DispatchSpawn(driver);
					ActivateEntity(driver);
					TeleportEntity(driver,porigin,angs,NULL_VECTOR);
					AcceptEntityInput(driver,"StartForward");
					SetVariantString("!activator");
					AcceptEntityInput(ent,"SetParent",driver);
				}
				float vmins[3];
				float vmaxs[3];
				GetEntPropVector(ent,Prop_Data,"m_vecMins",vmins);
				GetEntPropVector(ent,Prop_Data,"m_vecMaxs",vmaxs);
				int mainturret = CreateEntityByName("func_tank");
				if (mainturret != -1)
				{
					DispatchKeyValue(mainturret,"spawnflags","1");
					DispatchKeyValue(mainturret,"model","*1");
					DispatchKeyValue(mainturret,"yawrate","30");
					DispatchKeyValue(mainturret,"yawrange","180");
					DispatchKeyValue(mainturret,"yawtolerance","45");
					DispatchKeyValue(mainturret,"pitchtolerance","45");
					DispatchKeyValue(mainturret,"pitchrange","60");
					DispatchKeyValue(mainturret,"pitchrate","120");
					DispatchKeyValue(mainturret,"barrel","100");
					DispatchKeyValue(mainturret,"barrelz","8");
					DispatchKeyValue(mainturret,"bullet","3");
					DispatchKeyValue(mainturret,"ignoregraceupto","768");
					DispatchKeyValue(mainturret,"firerate","15");
					DispatchKeyValue(mainturret,"firespread","3");
					DispatchKeyValue(mainturret,"persistence","3");
					DispatchKeyValue(mainturret,"maxRange","2048");
					DispatchKeyValue(mainturret,"spritescale","1");
					DispatchKeyValue(mainturret,"gun_base_attach","minigun1_base");
					DispatchKeyValue(mainturret,"gun_barrel_attach","minigun1_muzzle");
					DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun1_yaw"); //aim_yaw
					//DispatchKeyValue(mainturret,"gun_pitch_pose_param","aim_pitch");
					DispatchKeyValue(mainturret,"ammo_count","-1");
					DispatchKeyValue(mainturret,"effecthandling","1");
					TeleportEntity(mainturret,porigin,angs,NULL_VECTOR);
					DispatchSpawn(mainturret);
					ActivateEntity(mainturret);
					SetVariantString("!activator");
					AcceptEntityInput(mainturret,"SetParent",ent);
					SetVariantString("minigun1");
					AcceptEntityInput(mainturret,"SetParentAttachment");
					SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
					SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
					SetVariantString("!player");
					AcceptEntityInput(mainturret,"SetTargetEntityName");
				}
				int turretflash = CreateEntityByName("env_muzzleflash");
				if (turretflash != -1)
				{
					DispatchKeyValue(turretflash,"scale","5");
					DispatchSpawn(turretflash);
					ActivateEntity(turretflash);
					SetVariantString("!activator");
					AcceptEntityInput(turretflash,"SetParent",ent);
					SetVariantString("muzzle");
					AcceptEntityInput(turretflash,"SetParentAttachment");
					SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",turretflash);
				}
				mainturret = CreateEntityByName("func_tank");
				if (mainturret != -1)
				{
					DispatchKeyValue(mainturret,"spawnflags","1");
					DispatchKeyValue(mainturret,"model","*1");
					DispatchKeyValue(mainturret,"yawrate","30");
					DispatchKeyValue(mainturret,"yawrange","180");
					DispatchKeyValue(mainturret,"yawtolerance","45");
					DispatchKeyValue(mainturret,"pitchtolerance","45");
					DispatchKeyValue(mainturret,"pitchrange","60");
					DispatchKeyValue(mainturret,"pitchrate","120");
					DispatchKeyValue(mainturret,"barrel","100");
					DispatchKeyValue(mainturret,"barrelz","8");
					DispatchKeyValue(mainturret,"bullet","3");
					DispatchKeyValue(mainturret,"ignoregraceupto","768");
					DispatchKeyValue(mainturret,"firerate","15");
					DispatchKeyValue(mainturret,"firespread","3");
					DispatchKeyValue(mainturret,"persistence","3");
					DispatchKeyValue(mainturret,"maxRange","2048");
					DispatchKeyValue(mainturret,"spritescale","1");
					DispatchKeyValue(mainturret,"gun_base_attach","minigun2_base");
					DispatchKeyValue(mainturret,"gun_barrel_attach","minigun2_muzzle");
					DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun2_yaw");
					DispatchKeyValue(mainturret,"ammo_count","-1");
					DispatchKeyValue(mainturret,"effecthandling","1");
					TeleportEntity(mainturret,porigin,angs,NULL_VECTOR);
					DispatchSpawn(mainturret);
					ActivateEntity(mainturret);
					SetVariantString("!activator");
					AcceptEntityInput(mainturret,"SetParent",ent);
					SetVariantString("minigun2");
					AcceptEntityInput(mainturret,"SetParentAttachment");
					SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
					SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
					SetVariantString("!player");
					AcceptEntityInput(mainturret,"SetTargetEntityName");
				}
				if (HasEntProp(ent,Prop_Data,"m_iHealth"))
				{
					int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
					int maxh = 500;
					if (hchk != maxh)
					{
						SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
						SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
					}
				}
				SDKHookEx(ent,SDKHook_Think,abramsthink);
				/*asfasf
				int entmdl = CreateEntityByName("prop_dynamic");
				if (entmdl != -1)
				{
					DispatchKeyValue(entmdl,"model","models/props_vehicles/abrams.mdl");
					DispatchKeyValue(entmdl,"solid","6");
					DispatchKeyValue(entmdl,"rendermode","10");
					TeleportEntity(entmdl,porigin,angs,NULL_VECTOR);
					DispatchSpawn(entmdl);
					ActivateEntity(entmdl);
					SetVariantString("!activator");
					AcceptEntityInput(entmdl,"SetParent",ent);
					int collpair = CreateEntityByName("logic_collisionpair");
					if (collpair != -1)
					{
						char entmdltarg[32];
						Format(entmdltarg,sizeof(entmdltarg),"%smodel",targn);
						DispatchKeyValue(collpair,"attach1",targn);
						DispatchKeyValue(collpair,"attach2",entmdltarg);
						DispatchKeyValue(collpair,"StartDisabled","1");
						DispatchSpawn(collpair);
						ActivateEntity(collpair);
					}
				}
				*/
				setmdl = false;
			}
			else if (StrEqual(oldcls,"grenade_tripmine",false))
			{
				float loc[3];
				angs[1]+=90.0;
				loc[0] = (porigin[0] + (20 * Cosine(DegToRad(angs[1]))));
				loc[1] = (porigin[1] + (20 * Sine(DegToRad(angs[1]))));
				loc[2] = porigin[2];
				float fhitpos[3];
				Handle hhitpos = INVALID_HANDLE;
				TR_TraceRayFilter(loc,angs,MASK_SHOT,RayType_Infinite,TraceSlamFilter);
				TR_GetEndPosition(fhitpos,hhitpos);
				char endpointtn[32];
				if (strlen(targn) < 1)
				{
					Format(targn,sizeof(targn),"tripmine%i",ent);
					SetEntPropString(ent,Prop_Data,"m_iName",targn);
				}
				int endpoint = CreateEntityByName("info_target");
				if (endpoint != -1)
				{
					Format(endpointtn,sizeof(endpointtn),"%s%itargend",targn,endpoint);
					DispatchKeyValue(endpoint,"targetname",endpointtn);
					TeleportEntity(endpoint,fhitpos,angs,NULL_VECTOR);
					DispatchSpawn(endpoint);
					ActivateEntity(endpoint);
				}
				int beam = CreateEntityByName("env_beam");
				if (beam != -1)
				{
					DispatchKeyValue(beam,"spawnflags","1");
					DispatchKeyValue(beam,"life","0");
					DispatchKeyValue(beam,"texture","sprites/laserbeam.spr");
					DispatchKeyValue(beam,"TextureScroll","35");
					DispatchKeyValue(beam,"framerate","10");
					DispatchKeyValue(beam,"rendercolor","255 0 0");
					DispatchKeyValue(beam,"BoltWidth","0.5");
					DispatchKeyValue(beam,"LightningStart",targn);
					DispatchKeyValue(beam,"LightningEnd",endpointtn);
					DispatchKeyValue(beam,"TouchType","4");
					if ((tripminefilter = -1) || (!IsValidEntity(tripminefilter)))
					{
						tripminefilter = CreateEntityByName("filter_activator_class");
						DispatchKeyValue(tripminefilter,"filterclass","grenade_tripmine");
						DispatchKeyValue(tripminefilter,"targetname","syn_tripmine_filter");
						DispatchKeyValue(tripminefilter,"Negated","1");
						DispatchSpawn(tripminefilter);
						ActivateEntity(tripminefilter);
					}
					TeleportEntity(beam,loc,angs,NULL_VECTOR);
					DispatchSpawn(beam);
					ActivateEntity(beam);
					int expl = CreateEntityByName("env_explosion");
					if (expl != -1)
					{
						TeleportEntity(expl,loc,angs,NULL_VECTOR);
						DispatchKeyValue(expl,"imagnitude","300");
						DispatchKeyValue(expl,"iradiusoverride","250");
						DispatchKeyValue(expl,"rendermode","0");
						DispatchSpawn(expl);
						ActivateEntity(expl);
						SetEntPropEnt(beam,Prop_Data,"m_hOwnerEntity",ent);
						SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",expl);
						SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",beam);
						SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",expl);
						PushArrayCell(tripmines,ent);
						HookSingleEntityOutput(beam,"OnTouchedByEntity",EntityOutput:TripMineExpl);
					}
				}
				SDKHookEx(ent,SDKHook_OnTakeDamage,tripminetkdmg);
			}
			else if (StrEqual(oldcls,"npc_alien_slave",false))
			{
				SDKHookEx(ent,SDKHook_Think,aslavethink);
				SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
				if (!relsetvort)
				{
					setuprelations(oldcls);
					relsetvort = true;
				}
			}
			else if (StrEqual(oldcls,"npc_apache",false))
			{
				Format(mdl,sizeof(mdl),"models/props_vehicles/apache.mdl");
				SDKHookEx(ent,SDKHook_Think,apachethink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
			}
			if (StrEqual(clsname,"generic_actor",false)) setmdl = false;
			if (setmdl)
			{
				Handle dpres = CreateDataPack();
				WritePackString(dpres,mdl);
				WritePackCell(dpres,ent);
				CreateTimer(0.5,resetmdl,dpres,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if (GetArraySize(customrelations) > 0)
				{
					for (int i = 0;i<GetArraySize(customrelations);i++)
					{
						int j = GetArrayCell(customrelations,i);
						if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
					}
				}
			}
		}
		CloseHandle(dp);
	}
}

void restoreentarr(Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		if (GetArraySize(dp) > 0)
		{
			char clsname[64];
			char additionalequip[64];
			float porigin[3];
			float angs[3];
			int findcls = FindStringInArray(dp,"classname");
			if (findcls != -1)
			{
				findcls++;
				GetArrayString(dp,findcls,clsname,sizeof(clsname));
			}
			int findorigin = FindStringInArray(dp,"origin");
			if (findorigin != -1)
			{
				findorigin++;
				char orgch[128];
				GetArrayString(dp,findorigin,orgch,sizeof(orgch));
				char orgexpl[32][32];
				ExplodeString(orgch," ",orgexpl,32,32,true);
				porigin[0] = StringToFloat(orgexpl[0]);
				porigin[1] = StringToFloat(orgexpl[1]);
				porigin[2] = StringToFloat(orgexpl[2]);
			}
			int findangs = FindStringInArray(dp,"angles");
			if (findangs != -1)
			{
				findangs++;
				char angch[128];
				GetArrayString(dp,findangs,angch,sizeof(angch));
				char angexpl[32][32];
				ExplodeString(angch," ",angexpl,32,32,true);
				angs[0] = StringToFloat(angexpl[0]);
				angs[1] = StringToFloat(angexpl[1]);
				angs[2] = StringToFloat(angexpl[2]);
			}
			int findequip = FindStringInArray(dp,"additionalequipment");
			if (findequip != -1)
			{
				findequip++;
				GetArrayString(dp,findequip,additionalequip,sizeof(additionalequip));
			}
			char oldcls[64];
			Format(oldcls,sizeof(oldcls),"%s",clsname);
			if (StrEqual(clsname,"npc_human_scientist_kleiner",false))
				Format(clsname,sizeof(clsname),"npc_kleiner");
			else if (StrEqual(clsname,"npc_human_scientist_eli",false))
				Format(clsname,sizeof(clsname),"npc_eli");
			else if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_human_grenadier",false)))
				Format(clsname,sizeof(clsname),"npc_combine_s");
			else if (StrEqual(clsname,"monster_headcrab",false))
				Format(clsname,sizeof(clsname),"npc_headcrab");
			else if ((StrEqual(clsname,"npc_human_security",false)) && (!StrEqual(additionalequip,"Default",false)) && (strlen(additionalequip) > 1))
				Format(clsname,sizeof(clsname),"npc_citizen");
			else if ((StrContains(clsname,"npc_human_",false) != -1) || (StrEqual(clsname,"npc_tentacle",false)) || (StrEqual(clsname,"monster_bullchicken",false)) || (StrEqual(clsname,"monster_cockroach",false)) || (StrEqual(clsname,"monster_human_grunt",false)) || (StrEqual(clsname,"monster_hgrunt_dead",false)) || (StrEqual(clsname,"monster_sentry",false)) || (StrEqual(clsname,"monster_houndeye",false)) || (StrEqual(clsname,"monster_scientist",false)) || (StrEqual(clsname,"monster_osprey",false)) || (StrEqual(clsname,"monster_gman",false)) || (StrEqual(clsname,"monster_scientist_dead",false)) || (StrEqual(clsname,"monster_barney",false)) || (StrEqual(clsname,"monster_barney_dead",false)))
				Format(clsname,sizeof(clsname),"generic_actor");
			else if (StrEqual(clsname,"monster_barnacle",false))
				Format(clsname,sizeof(clsname),"npc_barnacle");
			else if ((StrEqual(clsname,"monster_zombie",false)) || (StrEqual(clsname,"npc_zombie_scientist",false)))
				Format(clsname,sizeof(clsname),"npc_zombie");
			else if (StrEqual(clsname,"npc_zombie_scientist_torso",false))
				Format(clsname,sizeof(clsname),"npc_zombie_torso");
			else if ((StrEqual(clsname,"monster_alien_slave",false)) || (StrEqual(clsname,"npc_alien_slave",false)))
				Format(clsname,sizeof(clsname),"npc_vortigaunt");
			else if ((StrEqual(clsname,"npc_zombie_security",false)) || (StrEqual(clsname,"npc_zombie_security_torso",false)))
				Format(clsname,sizeof(clsname),"npc_zombine");
			else if (StrEqual(clsname,"npc_osprey",false))
				Format(clsname,sizeof(clsname),"npc_combinedropship");
			else if ((StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"npc_bullsquid",false)))
				Format(clsname,sizeof(clsname),"npc_antlion");
			else if (StrEqual(clsname,"npc_snark",false))
				Format(clsname,sizeof(clsname),"npc_headcrab_fast");
			else if ((StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"npc_alien_grunt_unarmored",false)) || (StrEqual(clsname,"npc_abrams",false)))
				Format(clsname,sizeof(clsname),"npc_combine_s");
			else if (StrEqual(clsname,"grenade_tripmine",false))
				Format(clsname,sizeof(clsname),"prop_physics");
			else if (StrEqual(clsname,"npc_apache",false))
				Format(clsname,sizeof(clsname),"npc_helicopter");
			int ent = CreateEntityByName(clsname);
			//PrintToServer("RestoreEntArray %i %s %1.f %1.f %1.f",ent,clsname,porigin[0],porigin[1],porigin[2]);
			if ((TR_PointOutsideWorld(porigin)) && (ent != -1))
			{
				AcceptEntityInput(ent,"kill");
				ent = -1;
			}
			if ((ent != -1) && (IsValidEntity(ent)))
			{
				TeleportEntity(ent,porigin,angs,NULL_VECTOR);
				char mdl[128];
				char targetpath[128];
				char targn[128];
				bool setmdl = true;
				for (int i = 0;i<GetArraySize(dp);i++)
				{
					char kv[64];
					char kvv[128];
					GetArrayString(dp,i,kv,sizeof(kv));
					i++;
					GetArrayString(dp,i,kvv,sizeof(kvv));
					if (StrEqual(kv,"model",false)) Format(mdl,sizeof(mdl),"%s",kvv);
					else if (StrEqual(kv,"target",false)) Format(targetpath,sizeof(targetpath),"%s",kvv);
					else if (StrEqual(kv,"targetname",false)) Format(targn,sizeof(targn),"%s",kvv);
					DispatchKeyValue(ent,kv,kvv);
				}
				DispatchSpawn(ent);
				ActivateEntity(ent);
				if (StrEqual(oldcls,"npc_houndeye",false))
				{
					SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
					PushArrayCell(hounds,ent);
					int entmdl = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
					DispatchKeyValue(entmdl,"solid","0");
					porigin[2]-=5.0;
					TeleportEntity(entmdl,porigin,angs,NULL_VECTOR);
					DispatchSpawn(entmdl);
					ActivateEntity(entmdl);
					SetVariantString("!activator");
					AcceptEntityInput(entmdl,"SetParent",ent);
					PushArrayCell(houndsmdl,entmdl);
					SDKHookEx(ent,SDKHook_Think,houndthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,houndtkdmg);
					HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
					Format(mdl,sizeof(mdl),"models/xenians/houndeye.mdl");
					SetVariantString("0.6");
					AcceptEntityInput(ent,"SetModelScale");
				}
				else if (StrEqual(oldcls,"npc_bullsquid",false))
				{
					SetEntProp(ent,Prop_Data,"m_bDisableJump",1);
					PushArrayCell(squids,ent);
					int entmdl = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
					DispatchKeyValue(entmdl,"solid","0");
					TeleportEntity(entmdl,porigin,angs,NULL_VECTOR);
					DispatchSpawn(entmdl);
					ActivateEntity(entmdl);
					SetVariantString("!activator");
					AcceptEntityInput(entmdl,"SetParent",ent);
					PushArrayCell(squidsmdl,entmdl);
					SDKHookEx(ent,SDKHook_Think,squidthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,squidtkdmg);
					HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
					Format(mdl,sizeof(mdl),"models/xenians/bullsquid.mdl");
					SetVariantString("0.5");
					AcceptEntityInput(ent,"SetModelScale");
				}
				else if (StrEqual(oldcls,"npc_tentacle",false))
				{
					if (FindStringInArray(precachedarr,oldcls) == -1)
					{
						char humanp[128];
						Format(humanp,sizeof(humanp),"sound/npc/tentacle/");
						recursion(humanp);
						PushArrayString(precachedarr,oldcls);
					}
					PushArrayCell(tents,ent);
					int entmdl = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(entmdl,"model","models/xenians/tentacle.mdl");
					DispatchKeyValue(entmdl,"targetname","syn_xeniantentaclemdl");
					DispatchKeyValue(entmdl,"solid","6");
					DispatchKeyValue(entmdl,"DefaultAnim","floor_idle");
					DispatchSpawn(entmdl);
					ActivateEntity(entmdl);
					PushArrayCell(tentsmdl,entmdl);
					int entsnd = CreateEntityByName("ambient_generic");
					DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
					DispatchSpawn(entsnd);
					ActivateEntity(entsnd);
					SetVariantString("!activator");
					AcceptEntityInput(entsnd,"SetParent",entmdl);
					SetVariantString("Eye");
					AcceptEntityInput(entsnd,"SetParentAttachment");
					PushArrayCell(tentssnd,entsnd);
					SDKHookEx(ent,SDKHook_Think,tentaclethink);
					HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
				}
				else if (StrContains(oldcls,"npc_zombie_s",false) == 0)
				{
					SDKHookEx(ent,SDKHook_Think,zomthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
				}
				else if (StrEqual(oldcls,"npc_ichthyosaur",false))
				{
					SDKHookEx(ent,SDKHook_Think,ichythink);
					HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
				}
				else if (StrEqual(oldcls,"npc_human_grenadier",false))
				{
					SDKHookEx(ent,SDKHook_Think,grenthink);
				}
				else if ((StrEqual(oldcls,"npc_alien_grunt")) || (StrEqual(oldcls,"npc_alien_grunt_unarmored")))
				{
					SDKHookEx(ent,SDKHook_Think,agruntthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,agrunttkdmg);
					SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
					HookSingleEntityOutput(ent,"OnDeath",EntityOutput:OnCDeath);
				}
				else if (StrEqual(oldcls,"npc_snark"))
				{
					SDKHookEx(ent,SDKHook_Think,snarkthink);
					SDKHook(ent,SDKHook_StartTouch,StartTouchSnark);
				}
				else if (StrEqual(oldcls,"npc_abrams"))
				{
					if (FindStringInArray(precachedarr,"npc_abrams") == -1)
					{
						PrecacheSound("weapons/weap_explode/explode3.wav",true);
						PrecacheSound("weapons/weap_explode/explode4.wav",true);
						PrecacheSound("weapons/weap_explode/explode5.wav",true);
						PushArrayString(precachedarr,"npc_abrams");
					}
					int driver = CreateEntityByName("func_tracktrain");
					if (driver != -1)
					{
						DispatchKeyValue(driver,"target",targetpath);
						DispatchKeyValue(driver,"orientationtype","1");
						DispatchKeyValue(driver,"speed","80");
						/*
						//Setup for -90 (270)
						angs[0]+=90.0;
						if (angs[0] > 360.0) angs[0]-=360.0;
						angs[1]+=45.0;
						if (angs[1] > 360.0) angs[1]-=360.0;
						angs[2]-=135.0;
						if (angs[2] < -180.0) angs[2]+=360.0;
						PrintToServer("StartAng %1.f %1.f %1.f",angs[0],angs[1],angs[2]);
						if (angs[1] < 0.0) angs[1]+=360.0;
						float angset = angs[0]+90.0;
						angs[0] = angset;
						if (angs[0] > 360.0) angs[0]-=360.0;
						angset = angs[1]/6;
						float angset2 = angs[1]/2;
						angs[1]+=angset;
						if (angs[1] > 360.0) angs[1]-=360.0;
						angs[2]-=angset2;
						if (angs[2] < -180.0) angs[2]+=360.0;
						PrintToServer("Setangs %1.f %1.f %1.f",angs[0],angs[1],angs[2]);
						*/
						DispatchSpawn(driver);
						ActivateEntity(driver);
						TeleportEntity(driver,porigin,angs,NULL_VECTOR);
						AcceptEntityInput(driver,"StartForward");
						SetVariantString("!activator");
						AcceptEntityInput(ent,"SetParent",driver);
					}
					float vmins[3];
					float vmaxs[3];
					GetEntPropVector(ent,Prop_Data,"m_vecMins",vmins);
					GetEntPropVector(ent,Prop_Data,"m_vecMaxs",vmaxs);
					int mainturret = CreateEntityByName("func_tank");
					if (mainturret != -1)
					{
						DispatchKeyValue(mainturret,"spawnflags","1");
						DispatchKeyValue(mainturret,"model","*1");
						DispatchKeyValue(mainturret,"yawrate","30");
						DispatchKeyValue(mainturret,"yawrange","180");
						DispatchKeyValue(mainturret,"yawtolerance","45");
						DispatchKeyValue(mainturret,"pitchtolerance","45");
						DispatchKeyValue(mainturret,"pitchrange","60");
						DispatchKeyValue(mainturret,"pitchrate","120");
						DispatchKeyValue(mainturret,"barrel","100");
						DispatchKeyValue(mainturret,"barrelz","8");
						DispatchKeyValue(mainturret,"bullet","3");
						DispatchKeyValue(mainturret,"ignoregraceupto","768");
						DispatchKeyValue(mainturret,"firerate","15");
						DispatchKeyValue(mainturret,"firespread","3");
						DispatchKeyValue(mainturret,"persistence","3");
						DispatchKeyValue(mainturret,"maxRange","2048");
						DispatchKeyValue(mainturret,"spritescale","1");
						DispatchKeyValue(mainturret,"gun_base_attach","minigun1_base");
						DispatchKeyValue(mainturret,"gun_barrel_attach","minigun1_muzzle");
						DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun1_yaw"); //aim_yaw
						//DispatchKeyValue(mainturret,"gun_pitch_pose_param","aim_pitch");
						DispatchKeyValue(mainturret,"ammo_count","-1");
						DispatchKeyValue(mainturret,"effecthandling","1");
						TeleportEntity(mainturret,porigin,angs,NULL_VECTOR);
						DispatchSpawn(mainturret);
						ActivateEntity(mainturret);
						SetVariantString("!activator");
						AcceptEntityInput(mainturret,"SetParent",ent);
						SetVariantString("minigun1");
						AcceptEntityInput(mainturret,"SetParentAttachment");
						SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
						SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
						SetVariantString("!player");
						AcceptEntityInput(mainturret,"SetTargetEntityName");
					}
					int turretflash = CreateEntityByName("env_muzzleflash");
					if (turretflash != -1)
					{
						DispatchKeyValue(turretflash,"scale","5");
						DispatchSpawn(turretflash);
						ActivateEntity(turretflash);
						SetVariantString("!activator");
						AcceptEntityInput(turretflash,"SetParent",ent);
						SetVariantString("muzzle");
						AcceptEntityInput(turretflash,"SetParentAttachment");
						SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",turretflash);
					}
					mainturret = CreateEntityByName("func_tank");
					if (mainturret != -1)
					{
						DispatchKeyValue(mainturret,"spawnflags","1");
						DispatchKeyValue(mainturret,"model","*1");
						DispatchKeyValue(mainturret,"yawrate","30");
						DispatchKeyValue(mainturret,"yawrange","180");
						DispatchKeyValue(mainturret,"yawtolerance","45");
						DispatchKeyValue(mainturret,"pitchtolerance","45");
						DispatchKeyValue(mainturret,"pitchrange","60");
						DispatchKeyValue(mainturret,"pitchrate","120");
						DispatchKeyValue(mainturret,"barrel","100");
						DispatchKeyValue(mainturret,"barrelz","8");
						DispatchKeyValue(mainturret,"bullet","3");
						DispatchKeyValue(mainturret,"ignoregraceupto","768");
						DispatchKeyValue(mainturret,"firerate","15");
						DispatchKeyValue(mainturret,"firespread","3");
						DispatchKeyValue(mainturret,"persistence","3");
						DispatchKeyValue(mainturret,"maxRange","2048");
						DispatchKeyValue(mainturret,"spritescale","1");
						DispatchKeyValue(mainturret,"gun_base_attach","minigun2_base");
						DispatchKeyValue(mainturret,"gun_barrel_attach","minigun2_muzzle");
						DispatchKeyValue(mainturret,"gun_yaw_pose_param","gun2_yaw");
						DispatchKeyValue(mainturret,"ammo_count","-1");
						DispatchKeyValue(mainturret,"effecthandling","1");
						TeleportEntity(mainturret,porigin,angs,NULL_VECTOR);
						DispatchSpawn(mainturret);
						ActivateEntity(mainturret);
						SetVariantString("!activator");
						AcceptEntityInput(mainturret,"SetParent",ent);
						SetVariantString("minigun2");
						AcceptEntityInput(mainturret,"SetParentAttachment");
						SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
						SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
						SetVariantString("!player");
						AcceptEntityInput(mainturret,"SetTargetEntityName");
					}
					if (HasEntProp(ent,Prop_Data,"m_iHealth"))
					{
						int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
						int maxh = 500;
						if (hchk != maxh)
						{
							SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
							SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
						}
					}
					SDKHookEx(ent,SDKHook_Think,abramsthink);
					setmdl = false;
				}
				else if (StrEqual(oldcls,"grenade_tripmine",false))
				{
					float loc[3];
					angs[1]+=90.0;
					loc[0] = (porigin[0] + (20 * Cosine(DegToRad(angs[1]))));
					loc[1] = (porigin[1] + (20 * Sine(DegToRad(angs[1]))));
					loc[2] = porigin[2];
					float fhitpos[3];
					Handle hhitpos = INVALID_HANDLE;
					TR_TraceRayFilter(loc,angs,MASK_SHOT,RayType_Infinite,TraceSlamFilter);
					TR_GetEndPosition(fhitpos,hhitpos);
					char endpointtn[32];
					if (strlen(targn) < 1)
					{
						Format(targn,sizeof(targn),"tripmine%i",ent);
						SetEntPropString(ent,Prop_Data,"m_iName",targn);
					}
					int endpoint = CreateEntityByName("info_target");
					if (endpoint != -1)
					{
						Format(endpointtn,sizeof(endpointtn),"%s%itargend",targn,endpoint);
						DispatchKeyValue(endpoint,"targetname",endpointtn);
						TeleportEntity(endpoint,fhitpos,angs,NULL_VECTOR);
						DispatchSpawn(endpoint);
						ActivateEntity(endpoint);
					}
					int beam = CreateEntityByName("env_beam");
					if (beam != -1)
					{
						DispatchKeyValue(beam,"spawnflags","1");
						DispatchKeyValue(beam,"life","0");
						DispatchKeyValue(beam,"texture","sprites/laserbeam.spr");
						DispatchKeyValue(beam,"TextureScroll","35");
						DispatchKeyValue(beam,"framerate","10");
						DispatchKeyValue(beam,"rendercolor","255 0 0");
						DispatchKeyValue(beam,"BoltWidth","0.5");
						DispatchKeyValue(beam,"LightningStart",targn);
						DispatchKeyValue(beam,"LightningEnd",endpointtn);
						DispatchKeyValue(beam,"TouchType","4");
						if ((tripminefilter = -1) || (!IsValidEntity(tripminefilter)))
						{
							tripminefilter = CreateEntityByName("filter_activator_class");
							DispatchKeyValue(tripminefilter,"filterclass","grenade_tripmine");
							DispatchKeyValue(tripminefilter,"targetname","syn_tripmine_filter");
							DispatchKeyValue(tripminefilter,"Negated","1");
							DispatchSpawn(tripminefilter);
							ActivateEntity(tripminefilter);
						}
						TeleportEntity(beam,loc,angs,NULL_VECTOR);
						DispatchSpawn(beam);
						ActivateEntity(beam);
						int expl = CreateEntityByName("env_explosion");
						if (expl != -1)
						{
							TeleportEntity(expl,loc,angs,NULL_VECTOR);
							DispatchKeyValue(expl,"imagnitude","300");
							DispatchKeyValue(expl,"iradiusoverride","250");
							DispatchKeyValue(expl,"rendermode","0");
							DispatchSpawn(expl);
							ActivateEntity(expl);
							SetEntPropEnt(beam,Prop_Data,"m_hOwnerEntity",ent);
							SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",expl);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",beam);
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",expl);
							PushArrayCell(tripmines,ent);
							HookSingleEntityOutput(beam,"OnTouchedByEntity",EntityOutput:TripMineExpl);
						}
					}
					SDKHookEx(ent,SDKHook_OnTakeDamage,tripminetkdmg);
				}
				else if (StrEqual(oldcls,"npc_alien_slave",false))
				{
					SDKHookEx(ent,SDKHook_Think,aslavethink);
					SetEntProp(ent,Prop_Data,"m_nRenderFX",5);
					if (!relsetvort)
					{
						setuprelations(oldcls);
						relsetvort = true;
					}
				}
				else if (StrEqual(oldcls,"npc_apache",false))
				{
					Format(mdl,sizeof(mdl),"models/props_vehicles/apache.mdl");
					SDKHookEx(ent,SDKHook_Think,apachethink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
				}
				if (StrEqual(clsname,"generic_actor",false)) setmdl = false;
				if (setmdl)
				{
					Handle dpres = CreateDataPack();
					WritePackString(dpres,mdl);
					WritePackCell(dpres,ent);
					CreateTimer(0.5,resetmdl,dpres,TIMER_FLAG_NO_MAPCHANGE);
				}
				if (GetArraySize(customrelations) > 0)
				{
					for (int i = 0;i<GetArraySize(customrelations);i++)
					{
						int j = GetArrayCell(customrelations,i);
						if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
					}
				}
			}
			CloseHandle(dp);
		}
	}
}

void findstraymdl(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		if ((StrEqual(clsname,"point_template",false)) || (StrEqual(clsname,"npc_template_maker",false)) || (StrEqual(clsname,"env_xen_portal_template",false)))
		{
			if (FindValueInArray(templateslist,thisent) == -1) PushArrayCell(templateslist,thisent);
		}
		else if (HasEntProp(thisent,Prop_Data,"m_iName"))
		{
			char targn[32];
			GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
			if (StrEqual(targn,"syn_xeniantentaclemdl",false))
				AcceptEntityInput(thisent,"kill");
			else if (StrEqual(targn,"synweapmanagers",false))
				weapmanagersplaced = true;
			else if (HasEntProp(thisent,Prop_Data,"m_hParent"))
			{
				int parentchk = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
				if (IsValidEntity(parentchk))
				{
					char parcls[24];
					GetEntityClassname(parentchk,parcls,sizeof(parcls));
					if (StrEqual(parcls,"npc_houndeye",false))
					{
						if (FindValueInArray(hounds,parentchk) == -1)
						{
							PushArrayCell(hounds,parentchk);
							PushArrayCell(houndsmdl,thisent);
							SDKHookEx(parentchk,SDKHook_Think,houndthink);
							SDKHookEx(parentchk,SDKHook_OnTakeDamage,houndtkdmg);
							HookSingleEntityOutput(parentchk,"OnDeath",EntityOutput:OnCDeath);
						}
					}
					else if (StrEqual(parcls,"npc_bullsquid",false))
					{
						if (FindValueInArray(squids,parentchk) == -1)
						{
							PushArrayCell(squids,parentchk);
							PushArrayCell(squidsmdl,thisent);
							SDKHookEx(parentchk,SDKHook_Think,squidthink);
							SDKHookEx(parentchk,SDKHook_OnTakeDamage,squidtkdmg);
							HookSingleEntityOutput(parentchk,"OnDeath",EntityOutput:OnCDeath);
						}
					}
				}
			}
			else if ((StrEqual(clsname,"npc_zombie_security",false)) || (StrEqual(clsname,"npc_zombie_scientist",false)))
			{
				SDKHookEx(thisent,SDKHook_Think,zomthink);
				SDKHookEx(thisent,SDKHook_OnTakeDamage,zomtkdmg);
			}
		}
		if ((StrEqual(clsname,"item_healthkit",false)) || (StrEqual(clsname,"item_battery",false)))
		{
			CreateTimer(0.1,rechk,thisent,TIMER_FLAG_NO_MAPCHANGE);
		}
		if (StrEqual(clsname,"func_conveyor",false))
		{
			Handle dp = CreateDataPack();
			if (dp != INVALID_HANDLE)
			{
				char mdl[16];
				GetEntPropString(thisent,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				WritePackCell(dp,thisent);
				WritePackString(dp,mdl);
				PushArrayCell(conveyors,dp);
			}
		}
		findstraymdl(thisent++,clsname);
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

public Action rechkcol(Handle timer, int logent)
{
	if (IsValidEntity(logent))
	{
		char entname[32];
		if (HasEntProp(logent,Prop_Data,"m_iName")) GetEntPropString(logent,Prop_Data,"m_iName",entname,sizeof(entname));
		if (StrEqual(entname,"vort",false))
		{
			SetEntData(logent, collisiongroup, 5, 4, true);
		}
	}
}

public Action rechk(Handle timer, int logent)
{
	if (IsValidEntity(logent))
	{
		char clsname[32];
		GetEntityClassname(logent,clsname,sizeof(clsname));
		if (StrEqual(clsname,"logic_auto",false))
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
		else if (StrEqual(clsname,"npc_houndeye",false))
		{
			if (FindValueInArray(hounds,logent) == -1)
			{
				if (FindStringInArray(precachedarr,"npc_houndeye") == -1)
				{
					PrecacheSound("npc\\houndeye\\blast1.wav",true);
					PrecacheSound("npc\\houndeye\\he_step1.wav",true);
					PrecacheSound("npc\\houndeye\\he_step2.wav",true);
					PrecacheSound("npc\\houndeye\\he_step3.wav",true);
					PrecacheSound("npc\\houndeye\\charge1.wav",true);
					PrecacheSound("npc\\houndeye\\charge2.wav",true);
					PrecacheSound("npc\\houndeye\\charge3.wav",true);
					PrecacheSound("npc\\houndeye\\die1.wav",true);
					PrecacheSound("npc\\houndeye\\pain1.wav",true);
					PrecacheSound("npc\\houndeye\\pain2.wav",true);
					PrecacheSound("npc\\houndeye\\pain3.wav",true);
					PushArrayString(precachedarr,"npc_houndeye");
				}
				SetEntPropFloat(logent,Prop_Data,"m_flModelScale",0.6);
				SetVariantString("0.6");
				AcceptEntityInput(logent,"SetModelScale");
				if (FileExists("models/xenians/houndeye.mdl",true,NULL_STRING))
				{
					if (!IsModelPrecached("models/xenians/houndeye.mdl")) PrecacheModel("models/xenians/houndeye.mdl",true);
					SetEntProp(logent,Prop_Data,"m_bDisableJump",1);
					PushArrayCell(hounds,logent);
					int entmdl = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
					DispatchKeyValue(entmdl,"solid","0");
					float orgs[3];
					float angs[3];
					if (HasEntProp(logent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(logent,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(logent,Prop_Send,"m_vecOrigin")) GetEntPropVector(logent,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(logent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(logent,Prop_Data,"m_angAbsRotation",angs);
					orgs[2]-=5.0;
					TeleportEntity(entmdl,orgs,angs,NULL_VECTOR);
					DispatchSpawn(entmdl);
					ActivateEntity(entmdl);
					SetVariantString("!activator");
					AcceptEntityInput(entmdl,"SetParent",logent);
					PushArrayCell(houndsmdl,entmdl);
					SDKHookEx(logent,SDKHook_Think,houndthink);
					SDKHookEx(logent,SDKHook_OnTakeDamage,houndtkdmg);
					HookSingleEntityOutput(logent,"OnDeath",EntityOutput:OnCDeath);
					Handle dp = CreateDataPack();
					WritePackString(dp,"models/xenians/houndeye.mdl");
					WritePackCell(dp,logent);
					CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
					customents = true;
				}
			}
		}
		else if (StrEqual(clsname,"npc_bullsquid",false))
		{
			if (FindValueInArray(squids,logent) == -1)
			{
				if (FileExists("models/xenians/bullsquid.mdl",true,NULL_STRING))
				{
					if (!IsModelPrecached("models/xenians/bullsquid.mdl")) PrecacheModel("models/xenians/bullsquid.mdl",true);
					SetVariantString("0.5");
					AcceptEntityInput(logent,"SetModelScale");
					SetEntProp(logent,Prop_Data,"m_bDisableJump",1);
					Handle dp = CreateDataPack();
					WritePackString(dp,"models/xenians/bullsquid.mdl");
					WritePackCell(dp,logent);
					CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
					customents = true;
					PushArrayCell(squids,logent);
					int entmdl = CreateEntityByName("prop_dynamic");
					DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
					DispatchKeyValue(entmdl,"solid","0");
					float orgs[3];
					float angs[3];
					if (HasEntProp(logent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(logent,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(logent,Prop_Send,"m_vecOrigin")) GetEntPropVector(logent,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(logent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(logent,Prop_Data,"m_angAbsRotation",angs);
					TeleportEntity(entmdl,orgs,angs,NULL_VECTOR);
					DispatchSpawn(entmdl);
					ActivateEntity(entmdl);
					SetVariantString("!activator");
					AcceptEntityInput(entmdl,"SetParent",logent);
					PushArrayCell(squidsmdl,entmdl);
					SDKHookEx(logent,SDKHook_Think,squidthink);
					SDKHookEx(logent,SDKHook_OnTakeDamage,squidtkdmg);
					HookSingleEntityOutput(logent,"OnDeath",EntityOutput:OnCDeath);
				}
			}
		}
		else if (StrEqual(clsname,"prop_ragdoll"))
		{
			char clschk[32];
			GetEntPropString(logent,Prop_Data,"m_strSourceClassName",clschk,sizeof(clschk));
			char mdl[128];
			GetEntPropString(logent,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrEqual(clschk,"npc_zombie_scientist"))
			{
				if (StrEqual(mdl,"models/zombie/classic_torso.mdl",false))
				{
					if (!IsModelPrecached("models/zombies/zombie_sci_torso.mdl")) PrecacheModel("models/zombies/zombie_sci_torso.mdl",true);
					DispatchKeyValue(logent,"model","models/zombies/zombie_sci_torso.mdl");
					SetEntityModel(logent,"models/zombies/zombie_sci_torso.mdl");
				}
			}
			else if (StrEqual(clschk,"npc_zombie_security"))
			{
				if (StrEqual(mdl,"models/zombie/zombie_soldier.mdl",false))
				{
					if (!IsModelPrecached("models/zombies/zombie_guard.mdl")) PrecacheModel("models/zombies/zombie_guard.mdl",true);
					DispatchKeyValue(logent,"model","models/zombies/zombie_guard.mdl");
					SetEntityModel(logent,"models/zombies/zombie_guard.mdl");
				}
			}
			else if (StrEqual(clschk,"npc_snark"))
			{
				AcceptEntityInput(logent,"kill");
			}
		}
		else if ((StrEqual(clsname,"helicopter_chunk",false)) && (customents))
		{
			char mdl[64];
			GetEntPropString(logent,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrEqual(mdl,"models/gibs/helicopter_brokenpiece_04_cockpit.mdl",false))
			{
				if (FileExists("models/gibs/apache_gibs/apache_fueselage.mdl",true,NULL_STRING))
				{
					if (!IsModelPrecached("models/gibs/apache_gibs/apache_fueselage.mdl")) PrecacheModel("models/gibs/apache_gibs/apache_fueselage.mdl",true);
					//SetEntityModel(logent,"models/gibs/apache_gibs/apache_fueselage.mdl");
					float orgs[3];
					float angs[3];
					if (HasEntProp(logent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(logent,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(logent,Prop_Send,"m_vecOrigin")) GetEntPropVector(logent,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(logent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(logent,Prop_Data,"m_angAbsRotation",angs);
					AcceptEntityInput(logent,"kill");
					int prop = CreateEntityByName("prop_physics");
					if (prop != -1)
					{
						DispatchKeyValue(prop,"solid","6");
						DispatchKeyValue(prop,"model","models/gibs/apache_gibs/apache_fueselage.mdl");
						TeleportEntity(prop,orgs,angs,NULL_VECTOR);
						DispatchSpawn(prop);
						ActivateEntity(prop);
					}
				}
			}
			else if (StrEqual(mdl,"models/gibs/helicopter_brokenpiece_06_body.mdl",false))
			{
				AcceptEntityInput(logent,"kill");
			}
		}
		else if ((StrEqual(clsname,"npc_gargantua",false)) && (customents))
		{
			SetVariantString("0.9");
			AcceptEntityInput(logent,"SetModelScale");
		}
		else if ((StrEqual(clsname,"item_healthkit",false)) || (StrEqual(clsname,"item_health_drop",false)))
		{
			if (FileExists("models/weapons/w_medkit.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/weapons/w_medkit.mdl")) PrecacheModel("models/weapons/w_medkit.mdl",true);
				SetEntityModel(logent,"models/weapons/w_medkit.mdl");
			}
		}
		else if (StrEqual(clsname,"item_battery",false))
		{
			if (FileExists("models/weapons/w_battery.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/weapons/w_battery.mdl")) PrecacheModel("models/weapons/w_battery.mdl",true);
				SetEntityModel(logent,"models/weapons/w_battery.mdl");
			}
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
	if (instswitch)
	{
		if ((IsValidEntity(weapon)) && (weapon != -1))
		{
			char weapname[32];
			GetEntityClassname(weapon,weapname,sizeof(weapname));
			if (StrEqual(weapname,"weapon_physcannon",false))
			{
				Handle data;
				data = CreateDataPack();
				WritePackCell(data, client);
				WritePackCell(data, weapon);
				CreateTimer(0.1,resetinst,data,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action resetinst(Handle timer, any:data)
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

findspawnpos(int client)
{
	int fallbackspawn = -1;
	bool teleported = false;
	for (int i = 1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (StrEqual(clsname,"info_player_coop",false))
			{
				if (GetEntProp(i,Prop_Data,"m_bDisabled") != 1)
				{
					float origin[3];
					GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",origin);
					float angs[3];
					GetEntPropVector(i,Prop_Data,"m_angAbsRotation",angs);
					TeleportEntity(client,origin,angs,NULL_VECTOR);
					teleported = true;
					break;
				}
			}
			if (StrEqual(clsname,"info_player_start",false))
				fallbackspawn = i;
		}
	}
	if ((!teleported) && (fallbackspawn != -1))
	{
		float origin[3];
		GetEntPropVector(fallbackspawn,Prop_Data,"m_vecAbsOrigin",origin);
		float angs[3];
		GetEntPropVector(fallbackspawn,Prop_Data,"m_angAbsRotation",angs);
		TeleportEntity(client,origin,angs,NULL_VECTOR);
	}
}

findent(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		int bdisabled = GetEntProp(thisent,Prop_Data,"m_bDisabled");
		if (bdisabled == 0)
			PushArrayCell(equiparr,thisent);
		findent(thisent++,clsname);
	}
}

findentlist(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char clsofent[24];
		GetEntityClassname(thisent,clsofent,sizeof(clsofent));
		if ((StrEqual(clsofent,"npc_template_maker",false)) || (StrEqual(clsofent,"npc_maker",false)))
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
				if (debuglvl == 1) PrintToServer("%i has %i max npcs resetting to %i",thisent,maxnpc,spawneramt);
				SetVariantInt(spawneramt);
				AcceptEntityInput(thisent,"SetMaxChildren");
			}
		}
		if (StrEqual(clsofent,"npc_houndeye",false))
		{
			SetEntProp(thisent,Prop_Data,"m_bDisableJump",1);
			PushArrayCell(hounds,thisent);
			int entmdl = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
			DispatchKeyValue(entmdl,"solid","0");
			float tmpset[3];
			tmpset[2]-=5.0;
			TeleportEntity(entmdl,tmpset,NULL_VECTOR,NULL_VECTOR);
			DispatchSpawn(entmdl);
			ActivateEntity(entmdl);
			SetVariantString("!activator");
			AcceptEntityInput(entmdl,"SetParent",thisent);
			PushArrayCell(houndsmdl,entmdl);
			SDKHookEx(thisent,SDKHook_Think,houndthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,houndtkdmg);
			HookSingleEntityOutput(thisent,"OnDeath",EntityOutput:OnCDeath);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_bullsquid",false))
		{
			SetEntProp(thisent,Prop_Data,"m_bDisableJump",1);
			PushArrayCell(squids,thisent);
			int entmdl = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
			DispatchKeyValue(entmdl,"solid","0");
			DispatchSpawn(entmdl);
			ActivateEntity(entmdl);
			SetVariantString("!activator");
			AcceptEntityInput(entmdl,"SetParent",thisent);
			PushArrayCell(squidsmdl,entmdl);
			SDKHookEx(thisent,SDKHook_Think,squidthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,squidtkdmg);
			HookSingleEntityOutput(thisent,"OnDeath",EntityOutput:OnCDeath);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_tentacle",false))
		{
			if (FindStringInArray(precachedarr,clsofent) == -1)
			{
				char humanp[128];
				Format(humanp,sizeof(humanp),"sound/npc/tentacle/");
				recursion(humanp);
				PushArrayString(precachedarr,clsofent);
			}
			PushArrayCell(tents,thisent);
			int entmdl = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(entmdl,"model","models/xenians/tentacle.mdl");
			DispatchKeyValue(entmdl,"targetname","syn_xeniantentaclemdl");
			DispatchKeyValue(entmdl,"solid","6");
			DispatchKeyValue(entmdl,"DefaultAnim","floor_idle");
			DispatchSpawn(entmdl);
			ActivateEntity(entmdl);
			PushArrayCell(tentsmdl,entmdl);
			int entsnd = CreateEntityByName("ambient_generic");
			DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
			DispatchSpawn(entsnd);
			ActivateEntity(entsnd);
			SetVariantString("!activator");
			AcceptEntityInput(entsnd,"SetParent",entmdl);
			SetVariantString("Eye");
			AcceptEntityInput(entsnd,"SetParentAttachment");
			PushArrayCell(tentssnd,entsnd);
			SDKHookEx(thisent,SDKHook_Think,tentaclethink);
			HookSingleEntityOutput(thisent,"OnDeath",EntityOutput:OnCDeath);
			float tentor[3];
			float tentang[3];
			GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",tentor);
			GetEntPropVector(thisent,Prop_Data,"m_angRotation",tentang);
			TeleportEntity(entmdl,tentor,tentang,NULL_VECTOR);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_ichthyosaur",false))
		{
			SDKHookEx(thisent,SDKHook_Think,ichythink);
			HookSingleEntityOutput(thisent,"OnDeath",EntityOutput:OnCDeath);
			if ((FindStringInArray(precachedarr,clsofent) == -1) && (FileExists("sound\\npc\\ichthyosaur\\watermove3.wav",true,NULL_STRING)))
			{
				PrecacheSound("npc\\ichthyosaur\\watermove1.wav",true);
				PrecacheSound("npc\\ichthyosaur\\watermove2.wav",true);
				PrecacheSound("npc\\ichthyosaur\\watermove3.wav",true);
				PrecacheSound("npc\\ichthyosaur\\underwatermove1.wav",true);
				PrecacheSound("npc\\ichthyosaur\\underwatermove2.wav",true);
				PrecacheSound("npc\\ichthyosaur\\underwatermove3.wav",true);
				PrecacheSound("npc\\ichthyosaur\\die1.wav",true);
				PushArrayString(precachedarr,clsofent);
			}
		}
		else if (StrEqual(clsofent,"npc_alien_slave",false))
		{
			SDKHookEx(thisent,SDKHook_Think,aslavethink);
			SetEntProp(thisent,Prop_Data,"m_nRenderFX",5);
			if (!relsetvort)
			{
				setuprelations(clsofent);
				relsetvort = true;
			}
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_abrams",false))
		{
			if (FindStringInArray(precachedarr,"npc_abrams") == -1)
			{
				PrecacheSound("weapons/weap_explode/explode3.wav",true);
				PrecacheSound("weapons/weap_explode/explode4.wav",true);
				PrecacheSound("weapons/weap_explode/explode5.wav",true);
				PushArrayString(precachedarr,"npc_abrams");
			}
			if (GetEntPropEnt(thisent,Prop_Data,"m_hEffectEntity") == -1)
			{
				int turretflash = CreateEntityByName("env_muzzleflash");
				if (turretflash != -1)
				{
					DispatchKeyValue(turretflash,"scale","5");
					DispatchSpawn(turretflash);
					ActivateEntity(turretflash);
					SetVariantString("!activator");
					AcceptEntityInput(turretflash,"SetParent",thisent);
					SetVariantString("muzzle");
					AcceptEntityInput(turretflash,"SetParentAttachment");
					SetEntPropEnt(thisent,Prop_Data,"m_hEffectEntity",turretflash);
				}
			}
			SDKHookEx(thisent,SDKHook_Think,abramsthink);
			customents = true;
		}
		if (FindValueInArray(entlist,thisent) == -1)
			PushArrayCell(entlist,thisent);
		findentlist(thisent++,clsname);
	}
}

int g_LastButtons[MAXPLAYERS+1];

public OnClientDisconnect_Post(int client)
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

public OnButtonPress(int client, int button)
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

public Native_GetCustomEntList(Handle plugin, int numParams)
{
	return _:customentlist;
}

public Native_ReadCache(Handle plugin, int numParams)
{
	if ((numParams < 2) || (numParams > 2))
	{
		PrintToServer("Error: SynFixesReadCache must have two parameters. <client> <pathtocache>");
		return;
	}
	else
	{
		int client = GetNativeCell(1);
		char entcache[256];
		GetNativeString(2,entcache,sizeof(entcache));
		if (!FileExists(entcache,true,NULL_STRING))
		{
			PrintToServer("SynFixesReadCache Error: Unable to find cache file %s",entcache);
			return;
		}
		else
		{
			readcache(client,entcache);
		}
	}
}

public pushch(Handle convar, const char[] oldValue, const char[] newValue)
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

public ffhch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) friendlyfire = true;
	else friendlyfire = false;
}

public instphych(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) instswitch = true;
	else instswitch = false;
}

public forcehdrch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) forcehdr = true;
	else forcehdr = false;
}

public removertimerch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToFloat(newValue) > 0.0)
		removertimer = StringToFloat(newValue);
	else
		removertimer = 30.0;
}

public restrictpercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public restrictvotech(Handle convar, const char[] oldValue, const char[] newValue)
{
	delaylimit = StringToFloat(newValue);
}

public spawneramtch(Handle convar, const char[] oldValue, const char[] newValue)
{
	spawneramt = StringToInt(newValue);
}

public spawneramtresch(Handle convar, const char[] oldValue, const char[] newValue)
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

public autorebuildch(Handle convar, const char[] oldValue, const char[] newValue)
{
	autorebuild = StringToInt(newValue);
}

public rebuildnodeshch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		rebuildnodes = true;
	else
		rebuildnodes = false;
}

public vortzapch(Handle convar, const char[] oldValue, const char[] newValue)
{
	slavezap = StringToInt(newValue);
}
