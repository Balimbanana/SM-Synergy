#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <synfixes>
#include <synfixes/synfixesglobals>
#include <synfixes/env_mortar_controller>
#include <synfixes/env_dispenser>
#include <synfixes/npc_abrams>
#include <synfixes/npc_alien_controller>
#include <synfixes/npc_alien_grunt>
#include <synfixes/npc_alien_slave>
#include <synfixes/npc_apache>
#include <synfixes/npc_bmsgargantua>
#include <synfixes/npc_human_assassin>
#include <synfixes/npc_bullsquid>
#include <synfixes/npc_gonarch>
#include <synfixes/npc_hgrunts>
#include <synfixes/npc_houndeye>
#include <synfixes/npc_ichthyosaur>
#include <synfixes/npc_osprey>
#include <synfixes/npc_sentries>
#include <synfixes/npc_snark>
#include <synfixes/npc_tentacle>
#include <synfixes/npc_zombies>
#include <synfixes/npc_synth_scanner>
#include <synfixes/monster_zombie>
#include <synfixes/prop_surgerybot>
#include <synfixes/logic_merchant_relay>
#include <synfixes/npc_merchant>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#tryinclude <mapchooser>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;
#pragma dynamic 2097152;

char szMapEntitiesBuff[2097152]; //Used as fallback entity cache if none generated
char restorelang[128][32];
char ChapterTitle[128];
char PreviousTitle[128];
Handle equiparr = INVALID_HANDLE;
Handle physboxarr = INVALID_HANDLE;
Handle physboxharr = INVALID_HANDLE;
Handle elevlist = INVALID_HANDLE;
Handle inputsarrorigincls = INVALID_HANDLE;
Handle conveyors = INVALID_HANDLE;
Handle delayedsounds = INVALID_HANDLE;
Handle delayedspeech = INVALID_HANDLE;
Handle passedstrings = INVALID_HANDLE;
Handle restorecustoments = INVALID_HANDLE;
Handle ignoretrigs = INVALID_HANDLE;
Handle spawnerswait = INVALID_HANDLE;
Handle globalsarr = INVALID_HANDLE;
Handle dctimeoutarr = INVALID_HANDLE;
//Handle nextweapreset = INVALID_HANDLE;
Handle SFEntInputHook = INVALID_HANDLE;
Handle addedinputs = INVALID_HANDLE;
Handle hTemplateData = INVALID_HANDLE;
ConVar hWeaponRespawn;
float entrefresh = 0.0;
float removertimer = 30.0;
float fadingtime[128];
float antispamchk[128];
float LastJump[128];
int WeapList = -1;
int tauhl2beam = -1;
int spawneramt = 20;
int restrictmode = 0;
int clrocket[128];
int mdlus = -1;
int mdlus3 = -1;
int longjumpactive = false;
int autorebuild = 0;
int playercapadj = 20;
int instswitch = 1;
bool rebuildnodes = false;
bool allownoguide = true;
bool guiderocket[128];
bool isfading[128];
bool bPrevOpen[128];
bool bPrevWeapRPG[128];
bool restrictact = false;
bool friendlyfire = false;
bool seqenablecheck = true;
bool forcehdr = false;
bool mapchoosercheck = false;
//bool linact = false;
bool syn56act = false;
bool vehiclemaphook = false;
bool playerteleports = false;
bool hasread = false;
bool hasreadscriptents = false;
bool reloadaftersetup = false;
bool weapmanagersplaced = false;
bool mapchanging = false;
bool DisplayedChapterTitle[128];
bool appliedlargeplayeradj = false;
bool antlionguardhard = false;
bool incfixer = false;
bool bBlockEx = true;
bool bFixRebind = false;
bool RestartedMap = false;
bool AutoFixEp2Req = false;
bool TrainBlockFix = true;
bool GroundStuckFix = true;
bool BlockChoreoSuicide = true;
bool LongJumpMode = false;
bool norunagain = false;
bool BlockTripMineDamage = true;
bool FixWeapSnd = true;
bool bFixSoundScapes = true;
bool bFixNPCStuck = true;
bool bPortalParticleAvailable = false;

#define PLUGIN_VERSION "2.0032"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synfixesdevupdater.txt"

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
	name = "SynFixesDev",
	author = "Balimbanana",
	description = "Attempts to fix sequences by checking for missing actors, entities that have fallen out of the world, players not spawning with weapons, and vehicle pulling from side to side. Plus custom entity support.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

float perclimit = 0.66;
float delaylimit = 66.0;
float votetime[128];
int cllastsscape[128];
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
	Handle instphyswitch = CreateConVar("sm_instantswitch", "1", "Allow instant weapon switch for physcannon. 2 is for every weapon.", _, true, 0.0, true, 2.0);
	instswitch = GetConVarInt(instphyswitch);
	HookConVarChange(instphyswitch, instphych);
	CloseHandle(instphyswitch);
	Handle forcehdrh = CreateConVar("sm_forcehdr", "1", "Force clients to use HDR (fixes fullbright).", _, true, 0.0, true, 1.0);
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
	Handle cvar = FindConVar("skill");
	if (cvar != INVALID_HANDLE)
	{
		difficulty = GetConVarInt(cvar);
		HookConVarChange(cvar, difficultych);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sk_player_head");
	if (cvar != INVALID_HANDLE)
	{
		headgroup = GetConVarInt(cvar);
		HookConVarChange(cvar, headgrpch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_playertriggerapply");
	if (cvar != INVALID_HANDLE)
	{
		playercapadj = GetConVarInt(cvar);
		HookConVarChange(cvar, plytrigch);
	}
	else
	{
		cvar = CreateConVar("sm_playertriggerapply", "64", "Set player trigger amount for map adjustments such as additional vehicle spawns. 0 disables.", _, true, 0.0, true, 128.0);
		playercapadj = GetConVarInt(cvar);
		HookConVarChange(cvar, plytrigch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_antlionhardmode");
	if (cvar != INVALID_HANDLE)
	{
		antlionguardhard = GetConVarBool(cvar);
		HookConVarChange(cvar, antliongch);
	}
	else
	{
		cvar = CreateConVar("sm_antlionhardmode", "0", "Enables hard mode for antlion guards.", _, true, 0.0, true, 1.0);
		antlionguardhard = GetConVarBool(cvar);
		HookConVarChange(cvar, antliongch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("sm_incfilefixer");
	if (cvar != INVALID_HANDLE)
	{
		incfixer = GetConVarBool(cvar);
		HookConVarChange(cvar, incfixerch);
	}
	else
	{
		cvar = CreateConVar("sm_incfilefixer", "0", "Enable attempt force content mount for maps with .inc files.", _, true, 0.0, true, 1.0);
		incfixer = GetConVarBool(cvar);
		HookConVarChange(cvar, incfixerch);
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
	cvar = FindConVar("sm_autofixreq_ep2");
	if (cvar != INVALID_HANDLE)
	{
		AutoFixEp2Req = GetConVarBool(cvar);
		HookConVarChange(cvar, ep2reqch);
	}
	else
	{
		cvar = CreateConVar("sm_autofixreq_ep2", "0", "When map starts, it will be checked for episodic entities and whether or not Ep2 is mounted. If there are Ep2 entities and Ep2 is not mounted, sv_content_optional will be used and the map will restart automatically.", _, true, 0.0, true, 1.0);
		AutoFixEp2Req = GetConVarBool(cvar);
		HookConVarChange(cvar, ep2reqch);
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
	cvar = FindConVar("sm_longjumpmode");
	if (cvar != INVALID_HANDLE)
	{
		LongJumpMode = GetConVarBool(cvar);
		HookConVarChange(cvar, longjumpmodech);
	}
	else
	{
		cvar = CreateConVar("sm_longjumpmode", "0", "Set mode of longjump, 0 is HL1 version, 1 is Black Mesa version.", _, true, 0.0, true, 1.0);
		LongJumpMode = GetConVarBool(cvar);
		HookConVarChange(cvar, longjumpmodech);
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
	cvar = FindConVar("sm_fixweaponsounds");
	if (cvar != INVALID_HANDLE)
	{
		FixWeapSnd = GetConVarBool(cvar);
		HookConVarChange(cvar, fixweapsndch);
	}
	else
	{
		cvar = CreateConVar("sm_fixweaponsounds", "1", "Fixes predicted sounds not being played.", _, true, 0.0, true, 1.0);
		FixWeapSnd = GetConVarBool(cvar);
		HookConVarChange(cvar, fixweapsndch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("synfixes_fixsoundscapes");
	if (cvar != INVALID_HANDLE)
	{
		bFixSoundScapes = GetConVarBool(cvar);
		HookConVarChange(cvar, fixsndscapech);
	}
	else
	{
		cvar = CreateConVar("synfixes_fixsoundscapes", "1", "Fixes soundscapes not applied correctly.", _, true, 0.0, true, 1.0);
		bFixSoundScapes = GetConVarBool(cvar);
		HookConVarChange(cvar, fixsndscapech);
	}
	CloseHandle(cvar);
	cvar = FindConVar("synfixes_stuckinnpc");
	if (cvar != INVALID_HANDLE)
	{
		bFixNPCStuck = GetConVarBool(cvar);
		HookConVarChange(cvar, stuckinnpcch);
	}
	else
	{
		cvar = CreateConVar("synfixes_stuckinnpc", "1", "Removes collisions between players and NPCs when they are stuck inside each other.", _, true, 0.0, true, 1.0);
		bFixNPCStuck = GetConVarBool(cvar);
		HookConVarChange(cvar, stuckinnpcch);
	}
	CloseHandle(cvar);
	cvar = FindConVar("npc_merchant_currency");
	if (cvar != INVALID_HANDLE)
	{
		iMerchantCType = GetConVarInt(cvar);
		HookConVarChange(cvar, merchcurrencych);
	}
	else
	{
		cvar = CreateConVar("npc_merchant_currency", "0", "0 is kills. 1 is points. 2 is property defined by npc_merchant_currency_type.", _, true, 0.0, true, 2.0);
		iMerchantCType = GetConVarInt(cvar);
		HookConVarChange(cvar, merchcurrencych);
	}
	CloseHandle(cvar);
	hMerchCVar = FindConVar("npc_merchant_currency_type");
	if (hMerchCVar != INVALID_HANDLE)
	{
		GetConVarString(hMerchCVar, szMerchPropType, sizeof(szMerchPropType));
		HookConVarChange(hMerchCVar, merchcurrencypropch);
	}
	else
	{
		hMerchCVar = CreateConVar("npc_merchant_currency_type", "m_iFrags", ".", _);
		GetConVarString(hMerchCVar, szMerchPropType, sizeof(szMerchPropType));
		HookConVarChange(hMerchCVar, merchcurrencypropch);
	}
	//sv_hl2mp_weapon_respawn_time default CVar for time to spawn
	hWeaponRespawn = FindConVar("mp_respawnweapons");
	if (hWeaponRespawn == INVALID_HANDLE) hWeaponRespawn = CreateConVar("mp_respawnweapons", "0", "Respawn weapons picked up off the ground.", _, true, 0.0, true, 1.0);
	HookConVarChange(hWeaponRespawn, weaponrespawnch);
	//hRRReduceWeapons = FindConVar("rr_reduceweapons");
	//if (hRRReduceWeapons == INVALID_HANDLE) hRRReduceWeapons = CreateConVar("rr_reduceweapons", "0", "Reduce spawn equipment to rr_weaponslist.", _, true, 0.0, true, 1.0);
	CreateTimer(60.0,resetrot,_,TIMER_REPEAT);
	//if ((FileExists("addons/metamod/bin/server.so",false,NULL_STRING)) && (FileExists("addons/metamod/bin/metamod.2.sdk2013.so",false,NULL_STRING))) linact = true;
	//else linact = false;
	HookEventEx("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	HookEventEx("synergy_entity_death",Event_SynEntityKilled,EventHookMode_Pre);
	HookEventEx("player_disconnect",Event_PlayerDisconnect,EventHookMode_Post);
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
	controllers = CreateArray(256);
	templateslist = CreateArray(256);
	templatetargs = CreateArray(256);
	templateents = CreateArray(256);
	d_li = CreateArray(128);
	d_ht = CreateArray(128);
	customrelations = CreateArray(128);
	ignoretrigs = CreateArray(1024);
	spawnerswait = CreateArray(256);
	globalsarr = CreateArray(32);
	dctimeoutarr = CreateArray(128);
	precachedarr = CreateArray(128);
	customentlist = CreateArray(128);
	conveyors = CreateArray(128);
	delayedsounds = CreateArray(64);
	delayedspeech = CreateArray(6);
	passedstrings = CreateArray(128);
	restorecustoments = CreateArray(256);
	inputsarrorigincls = CreateArray(768);
	merchantscr = CreateArray(32);
	merchantscrd = CreateArray(32);
	//nextweapreset = CreateArray(512);
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
	RegConsoleCmd("perfvisualbenchmark",admblock);
	RegConsoleCmd("ai_dump_hints",admblock);
	RegConsoleCmd("commentary_finishnode",admblock);
	RegConsoleCmd("dbghist_dump",admblock);
	RegConsoleCmd("dbghist_addline",admblock);
	RegConsoleCmd("mm_add_item",cmdblock);
	RegConsoleCmd("mm_add_player",cmdblock);
	RegConsoleCmd("mm_session_info",cmdblock);
	RegConsoleCmd("mm_message",cmdblock);
	RegConsoleCmd("mm_stats",cmdblock);
	RegConsoleCmd("mm_select_session",cmdblock);
	RegConsoleCmd("kill",suicideblock);
	RegConsoleCmd("explode",suicideblock);
	RegConsoleCmd("flushfix",ReallowFlush);
	AddCommandListener(flushcmd,"blckreset");
	RegConsoleCmd("changelevel",resetgraphs);
	Handle rebuildnodesh = CreateConVar("rebuildnodes","0","Set force rebuild ai nodes on every map (not nav_generate).",_,true,0.0,true,1.0);
	rebuildnodes = GetConVarBool(rebuildnodesh);
	HookConVarChange(rebuildnodesh,rebuildnodeshch);
	CloseHandle(rebuildnodesh);
	Handle noguidecv = CreateConVar("sm_allownoguide","1","Sets whether or not to allow setting no guide on rpg rockets.",_,true,0.0,true,1.0);
	allownoguide = GetConVarBool(noguidecv);
	HookConVarChange(noguidecv,noguidech);
	CloseHandle(noguidecv);
	AutoExecConfig(true, "synfixes");
	Handle autorebuildh = CreateConVar("rebuildents","0","Set auto rebuild of custom entities, 1 is dynamic, 2 is static npc list.",_,true,0.0,true,2.0);
	autorebuild = GetConVarInt(autorebuildh);
	HookConVarChange(autorebuildh,autorebuildch);
	CloseHandle(autorebuildh);
	RegAdminCmd("sm_rebuildents",rebuildents,ADMFLAG_ROOT,".");
	RegServerCmd("synfixes_listaddedhooks",listaddedhooks);
	CreateTimer(10.0,dropshipchk,_,TIMER_REPEAT);
	CreateTimer(0.5,resetclanim,_,TIMER_REPEAT);
	CreateTimer(0.1,clticks,_,TIMER_REPEAT);
	CreateTimer(0.1,bmcvars);
	AddAmbientSoundHook(customsoundchecks);
	AddNormalSoundHook(customsoundchecksnorm);
	SFEntInputHook = CreateGlobalForward("SFHookEntityInput", ET_Ignore, Param_String, Param_Cell, Param_String, Param_String, Param_Float);
}

public Action bmcvars(Handle timer)
{
	Handle cvarchk = FindConVar("synfixes_houndtint");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("synfixes_houndtint","1","Sets whether or not to use houndeye tint effect when charging.",_,true,0.0,true,1.0);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_human_security_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_security_health","40","Human Security health.",_,true,1.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_human_scientist_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_scientist_health","20","Human Scientist health.",_,true,1.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_human_commander_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_commander_health","50","Human Commander health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_human_grunt_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_grunt_health","50","Human Grunt health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_human_medic_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_medic_health","50","Human Medic health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_zombie_scientist_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_zombie_scientist_health","40","Zombie Scientist health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_zombie_security_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_zombie_security_health","50","Zombie Security health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_alien_slave_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_alien_slave_health","38","Alien Slave health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_bullsquid_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_bullsquid_health","60","BullSquid health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_bullsquid_bite_dmg");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_bullsquid_bite_dmg","25","BullSquid bite damage.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_bullsquid_whip_dmg");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_bullsquid_whip_dmg","35","BullSquid whip damage.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_bullsquid_whip_force");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_bullsquid_whip_force","300","BullSquid whip throw force.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_alien_grunt_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_alien_grunt_health","90","Alien Grunt health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_controller_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_controller_health","100","Alien Controller health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_human_assassin_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_assassin_health","50","Human Assassin health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_sentry_ceiling_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_sentry_ceiling_health","50","Ceiling Sentry health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_apache_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_apache_health","1500","Apache health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_houndeye_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_houndeye_health","50","Houndeye health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_gonarch_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_gonarch_health","1000","Gonarch health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_gonarch_dmg_strike");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_gonarch_dmg_strike","30.0","Gonarch strike damage.",_,true,1.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_osprey_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_osprey_health","300","Osprey health.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_npc_dmg_glock");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_npc_dmg_glock","5","Damage that NPCs will do with glocks.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_dmg_sentry");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_dmg_sentry","4","Sentries damage per shot.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_dmg_bmsgargantua_melee");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_dmg_bmsgargantua_melee","30","Black Mesa Gargantua melee damage.",_,true,0.0,false);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_bmsgargantua_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_bmsgargantua_health","800","Black Mesa Gargantua health.",_,true,0.0,false);
	CloseHandle(cvarchk);
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
	cvarchk = FindConVar("sk_sentry_firerate");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_sentry_firerate","0.1","Sentry Fire Rate per second.",_,true,0.0,false);
	flSentryFireRate = GetConVarFloat(cvarchk);
	HookConVarChange(cvarchk, sentryfireratech);
	CloseHandle(cvarchk);
	cvarchk = FindConVar("sk_plr_dmg_mp5");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_plr_dmg_mp5","5","MP5 damage.",_,true,0.0,false);
	CloseHandle(cvarchk);
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"plugins");
	Format(savepath,sizeof(savepath),"%s/synfixes.smx",savepath);
	if (FileExists(savepath))
	{
		PrintToServer("Cannot run both SynFixesDev and SynFixes at the same time.\nSynFixes default removed...");
		DeleteFile(savepath);
		ServerCommand("sm plugins unload synfixes");
	}
	return Plugin_Handled;
}

public Action OnLevelInit(const char[] szMapName, char szMapEntities[2097152])
{
	Format(szMapEntitiesBuff,sizeof(szMapEntitiesBuff),"%s",szMapEntities);
	return Plugin_Continue;
}

public void OnMapStart()
{
	mapchanging = false;
	customents = false;
	appliedlargeplayeradj = false;
	ChapterTitle = "";
	if (reloadaftersetup)
	{
		reloadaftersetup = false;
		Handle nullpl = INVALID_HANDLE;
		ReloadPlugin(nullpl);
	}
	if (GetMapHistorySize() > -1)
	{
		norunagain = false;
		GetCurrentMap(mapbuf,sizeof(mapbuf));
		if (AutoFixEp2Req)
		{
			char mdl[64];
			Handle ep2ents = CreateArray(32);
			FindAllByClassname(ep2ents,-1,"npc_zombine");
			FindAllByClassname(ep2ents,-1,"npc_maker");
			if (GetArraySize(ep2ents) > 0)
			{
				for (int i = 0;i<GetArraySize(ep2ents);i++)
				{
					int ent = GetArrayCell(ep2ents,i);
					if (IsValidEntity(ent))
					{
						if (HasEntProp(ent,Prop_Data,"m_ModelName"))
						{
							GetEntPropString(ent,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if ((StrEqual(mdl,"models/error.mdl",false)) || (!FileExists(mdl,true,NULL_STRING)))
							{
								RestartedMap = true;
								break;
							}
						}
						if (HasEntProp(ent,Prop_Data,"m_iszNPCClassname"))
						{
							GetEntPropString(ent,Prop_Data,"m_iszNPCClassname",mdl,sizeof(mdl));
							if (StrEqual(mdl,"npc_zombine",false))
							{
								if (!FileExists("models/zombie/zombie_soldier.mdl",true,NULL_STRING))
								{
									RestartedMap = true;
									break;
								}
							}
						}
					}
				}
			}
			CloseHandle(ep2ents);
			if (RestartedMap)
			{
				Handle srvcvar = FindConVar("sv_content_optional");
				if (srvcvar != INVALID_HANDLE)
				{
					SetConVarString(srvcvar,"ep2 ep1",true,false);
				}
				CloseHandle(srvcvar);
				ServerCommand("changelevel %s",mapbuf);
			}
			else RestartedMap = false;
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
		longjumpactive = false;
		hasread = false;
		hasreadscriptents = false;
		playerteleports = false;
		relsetvort = false;
		relsetzsec = false;
		relsethound = false;
		relsetabram = false;
		relsetsci = false;
		relsetsec = false;
		weapmanagersplaced = false;
		mdlus = PrecacheModel("sprites/blueglow2.vmt");
		mdlus3 = PrecacheModel("effects/strider_bulge_dudv.vmt");
		entrefresh = 0.0;
		matmod = -1;
		tauhl2beam = PrecacheModel("sprites/laserbeam.vmt");
		ClearArray(entlist);
		ClearArray(equiparr);
		ClearArray(entnames);
		ClearArray(physboxarr);
		ClearArray(physboxharr);
		ClearArray(elevlist);
		ClearArray(inputsarrorigincls);
		ClearArrayHandles(restorecustoments);
		CloseHandle(restorecustoments);
		restorecustoments = CreateArray(256);
		ClearArray(hounds);
		ClearArray(houndsmdl);
		ClearArray(squids);
		ClearArray(squidsmdl);
		ClearArray(tents);
		ClearArray(tentsmdl);
		ClearArray(tentssnd);
		ClearArray(grenlist);
		ClearArray(tripmines);
		ClearArray(controllers);
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
		ClearArray(delayedsounds);
		ClearArray(delayedspeech);
		ClearArray(passedstrings);
		ClearArray(globalsarr);
		ClearArray(merchantscr);
		ClearArrayHandles(merchantscrd);
		CloseHandle(merchantscrd);
		merchantscrd = CreateArray(32);
		//ClearArray(nextweapreset);
		bulletindx = PrecacheModel("models/weapons/w_bullet.mdl");
		FindGlobals(-1);
		for (int i = 1;i<MaxClients+1;i++)
		{
			guiderocket[i] = true;
			LastJump[i] = 0.0;
			DisplayedChapterTitle[i] = false;
			PushArrayCell(entlist,i);
		}
		for (int i = 1;i<2048;i++)
		{
			centnextatk[i] = 0.0;
			timesattacked[i] = 0;
			isattacking[i] = 0;
			centnextsndtime[i] = 0.0;
			glotext[i] = "";
		}
		char gamedescoriginal[24];
		GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
		bool rebuildentsset = false;
		//if (StrEqual(mapbuf,"bm_c2a4c",false))
		//{
		//	if (FileExists("maps\\ent_cache\\bms_bm_c2a4e.ent",false))
		//		DeleteFile("maps\\ent_cache\\bms_bm_c2a4e.ent");
		//}
		Handle autobuildcv = FindConVar("rebuildents");
		if (autobuildcv != INVALID_HANDLE) autorebuild = GetConVarInt(autobuildcv);
		CloseHandle(autobuildcv);
		if (StrContains(gamedescoriginal,"LFE",false) != -1)
		{
			rebuildentsset = true;
		}
		bool syn1810act = false;
		if (StrContains(gamedescoriginal,"synergy",false) != -1)
		{
			syn56act = true;
			syn1810act = false;
			if ((StrContains(mapbuf,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c",false) == 0) || (StrContains(mapbuf,"hls0",false) == 0) || (StrContains(mapbuf,"hls1",false) == 0))
			{
				Handle ragdollchk = FindConVar("ai_force_serverside_ragdoll");
				if (ragdollchk != INVALID_HANDLE)
				{
					if (GetConVarInt(ragdollchk) != 0) SetConVarInt(ragdollchk,0,false,false);
				}
				CloseHandle(ragdollchk);
				rebuildentsset = true;
			}
			else if ((StrContains(mapbuf,"ch00_",false) == 0) || (StrContains(mapbuf,"ch01_",false) == 0) || (StrContains(mapbuf,"ch02_",false) == 0))
			{
				autorebuild = 2;
				Handle cvar = FindConVar("player_throwforce");
				if (cvar != INVALID_HANDLE)
				{
					int cvarflag = GetCommandFlags("player_throwforce");
					SetCommandFlags("player_throwforce", (cvarflag & ~FCVAR_REPLICATED));
					SetCommandFlags("player_throwforce", (cvarflag & ~FCVAR_NOTIFY));
					SetCommandFlags("player_throwforce", (cvarflag & ~FCVAR_CHEAT));
					SetConVarInt(cvar,5000,false,false);
					SetCommandFlags("player_throwforce", cvarflag);
				}
				CloseHandle(cvar);
			}
		}
		else if (StrEqual(gamedescoriginal,"synergy 18.10",false))
		{
			syn1810act = true;
			syn56act = false;
			if (StrContains(mapbuf,"testchmb_",false) == 0) rebuildentsset = true;
		}
		else syn56act = false;
		if (restrictmode == 1)
		{
			if ((StrContains(mapbuf,"js_",false) != -1) || (StrContains(mapbuf,"coop_",false) != -1))
				restrictact = true;
			else
				restrictact = false;
		}
		if (((StrEqual(mapbuf,"d1_canals_13",false)) || (StrEqual(mapbuf,"d1_canals_11",false))) && (syn56act))
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
			if ((StrContains(mapbuf,"r_map3",false) == -1) && (StrContains(mapbuf,"pxg_level_",false) == -1))
			{
				if (StrContains(mapbuf,"bm_c",false) == -1)
					HookEntityOutput("func_tracktrain","OnStart",elevatorstart);
				HookEntityOutput("func_door","OnOpen",createelev);
				HookEntityOutput("func_door","OnClose",createelev);
			}
		}
		if (StrEqual(mapbuf,"ep1_citadel_03",false))
		{
			HookEntityOutput("func_door","OnOpen",createelev);
			HookEntityOutput("func_door","OnClose",createelev);
		}
		if (StrContains(mapbuf,"ep1_",false) == 0)
		{
			if (FileExists("resource/closecaption_ep1bulgarian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1bulgarian.dat");
			if (FileExists("resource/closecaption_ep1bulgarian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1bulgarian.txt");
			if (FileExists("resource/closecaption_ep1danish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1danish.dat");
			if (FileExists("resource/closecaption_ep1danish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1danish.txt");
			if (FileExists("resource/closecaption_ep1dutch.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1dutch.dat");
			if (FileExists("resource/closecaption_ep1dutch.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1dutch.txt");
			if (FileExists("resource/closecaption_ep1english.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1english.dat");
			if (FileExists("resource/closecaption_ep1english.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1english.txt");
			if (FileExists("resource/closecaption_ep1finnish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1finnish.dat");
			if (FileExists("resource/closecaption_ep1finnish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1finnish.txt");
			if (FileExists("resource/closecaption_ep1french.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1french.dat");
			if (FileExists("resource/closecaption_ep1french.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1french.txt");
			if (FileExists("resource/closecaption_ep1german.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1german.dat");
			if (FileExists("resource/closecaption_ep1german.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1german.txt");
			if (FileExists("resource/closecaption_ep1hungarian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1hungarian.dat");
			if (FileExists("resource/closecaption_ep1hungarian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1hungarian.txt");
			if (FileExists("resource/closecaption_ep1italian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1italian.dat");
			if (FileExists("resource/closecaption_ep1italian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1italian.txt");
			if (FileExists("resource/closecaption_ep1japanese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1japanese.dat");
			if (FileExists("resource/closecaption_ep1japanese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1japanese.txt");
			if (FileExists("resource/closecaption_ep1korean.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1korean.dat");
			if (FileExists("resource/closecaption_ep1korean.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1korean.txt");
			if (FileExists("resource/closecaption_ep1koreana.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1koreana.dat");
			if (FileExists("resource/closecaption_ep1koreana.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1koreana.txt");
			if (FileExists("resource/closecaption_ep1norwegian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1norwegian.dat");
			if (FileExists("resource/closecaption_ep1norwegian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1norwegian.txt");
			if (FileExists("resource/closecaption_ep1polish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1polish.dat");
			if (FileExists("resource/closecaption_ep1polish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1polish.txt");
			if (FileExists("resource/closecaption_ep1portuguese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1portuguese.dat");
			if (FileExists("resource/closecaption_ep1portuguese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1portuguese.txt");
			if (FileExists("resource/closecaption_ep1russian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1russian.dat");
			if (FileExists("resource/closecaption_ep1russian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1russian.txt");
			if (FileExists("resource/closecaption_ep1schinese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1schinese.dat");
			if (FileExists("resource/closecaption_ep1schinese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1schinese.txt");
			if (FileExists("resource/closecaption_ep1spanish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1spanish.dat");
			if (FileExists("resource/closecaption_ep1spanish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1spanish.txt");
			if (FileExists("resource/closecaption_ep1swedish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1swedish.dat");
			if (FileExists("resource/closecaption_ep1swedish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1swedish.txt");
			if (FileExists("resource/closecaption_ep1tchinese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1tchinese.dat");
			if (FileExists("resource/closecaption_ep1tchinese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1tchinese.txt");
			if (FileExists("resource/closecaption_ep1thai.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1thai.dat");
			if (FileExists("resource/closecaption_ep1thai.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1thai.txt");
			if (FileExists("resource/closecaption_ep1turkish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1turkish.dat");
			if (FileExists("resource/closecaption_ep1turkish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep1turkish.txt");
		}
		else if (StrContains(mapbuf,"ep2_outland_",false) == 0)
		{
			if (FileExists("resource/closecaption_ep2bulgarian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2bulgarian.dat");
			if (FileExists("resource/closecaption_ep2bulgarian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2bulgarian.txt");
			if (FileExists("resource/closecaption_ep2danish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2danish.dat");
			if (FileExists("resource/closecaption_ep2danish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2danish.txt");
			if (FileExists("resource/closecaption_ep2dutch.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2dutch.dat");
			if (FileExists("resource/closecaption_ep2dutch.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2dutch.txt");
			if (FileExists("resource/closecaption_ep2english.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2english.dat");
			if (FileExists("resource/closecaption_ep2english.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2english.txt");
			if (FileExists("resource/closecaption_ep2finnish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2finnish.dat");
			if (FileExists("resource/closecaption_ep2finnish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2finnish.txt");
			if (FileExists("resource/closecaption_ep2french.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2french.dat");
			if (FileExists("resource/closecaption_ep2french.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2french.txt");
			if (FileExists("resource/closecaption_ep2german.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2german.dat");
			if (FileExists("resource/closecaption_ep2german.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2german.txt");
			if (FileExists("resource/closecaption_ep2hungarian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2hungarian.dat");
			if (FileExists("resource/closecaption_ep2hungarian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2hungarian.txt");
			if (FileExists("resource/closecaption_ep2italian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2italian.dat");
			if (FileExists("resource/closecaption_ep2italian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2italian.txt");
			if (FileExists("resource/closecaption_ep2japanese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2japanese.dat");
			if (FileExists("resource/closecaption_ep2japanese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2japanese.txt");
			if (FileExists("resource/closecaption_ep2korean.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2korean.dat");
			if (FileExists("resource/closecaption_ep2korean.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2korean.txt");
			if (FileExists("resource/closecaption_ep2koreana.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2koreana.dat");
			if (FileExists("resource/closecaption_ep2koreana.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2koreana.txt");
			if (FileExists("resource/closecaption_ep2norwegian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2norwegian.dat");
			if (FileExists("resource/closecaption_ep2norwegian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2norwegian.txt");
			if (FileExists("resource/closecaption_ep2polish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2polish.dat");
			if (FileExists("resource/closecaption_ep2polish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2polish.txt");
			if (FileExists("resource/closecaption_ep2portuguese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2portuguese.dat");
			if (FileExists("resource/closecaption_ep2portuguese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2portuguese.txt");
			if (FileExists("resource/closecaption_ep2russian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2russian.dat");
			if (FileExists("resource/closecaption_ep2russian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2russian.txt");
			if (FileExists("resource/closecaption_ep2schinese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2schinese.dat");
			if (FileExists("resource/closecaption_ep2schinese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2schinese.txt");
			if (FileExists("resource/closecaption_ep2spanish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2spanish.dat");
			if (FileExists("resource/closecaption_ep2spanish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2spanish.txt");
			if (FileExists("resource/closecaption_ep2swedish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2swedish.dat");
			if (FileExists("resource/closecaption_ep2swedish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2swedish.txt");
			if (FileExists("resource/closecaption_ep2tchinese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2tchinese.dat");
			if (FileExists("resource/closecaption_ep2tchinese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2tchinese.txt");
			if (FileExists("resource/closecaption_ep2thai.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2thai.dat");
			if (FileExists("resource/closecaption_ep2thai.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2thai.txt");
			if (FileExists("resource/closecaption_ep2turkish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2turkish.dat");
			if (FileExists("resource/closecaption_ep2turkish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_ep2turkish.txt");
		}
		else if ((StrContains(mapbuf,"sp_",false) == 0) && (StrContains(mapbuf, "sp_c14_", false) == -1))
		{
			if (FileExists("resource/closecaption_cit2english.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_cit2english.txt");
			if (FileExists("resource/closecaption_cit2french.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_cit2french.txt");
			if (FileExists("resource/closecaption_cit2german.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_cit2german.txt");
			if (FileExists("resource/closecaption_cit2spanish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_cit2spanish.txt");
		}
		if (FileExists("materials/sprites/merchant_buysyn.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/sprites/merchant_buysyn.vmt");
		if (FileExists("materials/sprites/merchant_buysyn.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/sprites/merchant_buysyn.vtf");
		HookEntityOutput("trigger_changelevel","OnChangeLevel",mapendchg);
		HookEntityOutput("func_physbox","OnPhysGunPunt",physpunt);
		HookEntityOutput("prop_vehicle_jeep","PlayerOn",vehicleseatadjust);
		HookUserMessage(GetUserMessageId("Fade"),blockfade,true);
		Format(mapbuf,sizeof(mapbuf),"_%s.ent2",mapbuf);
		char contentdata[64];
		Handle cvar = FindConVar("content_metadata");
		if (cvar != INVALID_HANDLE)
		{
			GetConVarString(cvar,contentdata,sizeof(contentdata));
			char fixuptmp[16][16];
			ExplodeString(contentdata," ",fixuptmp,16,16,true);
			if (StrEqual(fixuptmp[1],"|",false)) Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
			else Format(contentdata,sizeof(contentdata),"%s",fixuptmp[0]);
		}
		else
		{
			ReplaceStringEx(mapbuf,sizeof(mapbuf),"_","");
		}
		CloseHandle(cvar);
		if (strlen(contentdata) > 1)
		{
			Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s%s",contentdata,mapbuf);
			if (!FileExists(mapbuf,true,NULL_STRING)) ReplaceStringEx(mapbuf,sizeof(mapbuf),".ent2",".ent");
			else
			{
				char mapcachecheck[128];
				Format(mapcachecheck,sizeof(mapcachecheck),"%s",mapbuf);
				ReplaceStringEx(mapcachecheck,sizeof(mapcachecheck),".ent2",".ent");
				if (GetFileTime(mapbuf,FileTime_LastChange) < GetFileTime(mapcachecheck,FileTime_LastChange)) Format(mapbuf,sizeof(mapbuf),"%s",mapcachecheck);
			}
		}
		else if (!FileExists(mapbuf,true,NULL_STRING)) ReplaceStringEx(mapbuf,sizeof(mapbuf),".ent2",".ent");
		else
		{
			char mapcachecheck[128];
			Format(mapcachecheck,sizeof(mapcachecheck),"%s",mapbuf);
			ReplaceStringEx(mapcachecheck,sizeof(mapcachecheck),".ent2",".ent");
			if (GetFileTime(mapbuf,FileTime_LastChange) < GetFileTime(mapcachecheck,FileTime_LastChange)) Format(mapbuf,sizeof(mapbuf),"%s",mapcachecheck);
		}
		if ((!FileExists(mapbuf,true,NULL_STRING)) && (DirExists("maps/ent_cache",false)))
		{
			Handle mdirlisting = OpenDirectory("maps/ent_cache",false);
			if (mdirlisting != INVALID_HANDLE)
			{
				char buff[64];
				while (ReadDirEntry(mdirlisting, buff, sizeof(buff)))
				{
					if ((!(mdirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
					{
						if ((!(StrContains(buff, ".ztmp", false) != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
						{
							if (StrContains(mapbuf,buff,false) != -1)
							{
								char tmp[64];
								Format(tmp,sizeof(tmp),"%s",buff);
								ReplaceStringEx(tmp,sizeof(tmp),mapbuf,"");
								// Fix for maps with similar names such as
								// bms_bm_c0a0a and hl1_c0a0a HL1 c0a0a will come up as BMS first without this check
								if (StrContains(tmp,"_",false) == -1)
								{
									Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s",buff);
									if (debuglvl > 1) PrintToServer("Found ent cache %s",mapbuf);
									break;
								}
							}
						}
					}
				}
			}
			CloseHandle(mdirlisting);
		}
		else if (debuglvl > 1) PrintToServer("Found ent cache %s",mapbuf);
		if (!FileExists(mapbuf,true,NULL_STRING))
		{
			GetCurrentMap(mapbuf,sizeof(mapbuf));
			if (strlen(contentdata) < 1) Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s_%s.ent",mapbuf,contentdata);
			else Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s.ent",mapbuf);
			if (debuglvl > 1) PrintToServer("Ent cache was not found, writing a new one...");
			if (!DirExists("maps/ent_cache",false)) CreateDirectory("maps/ent_cache",511,false);
			Handle writefile = OpenFile(mapbuf,"wb",true,NULL_STRING);
			if (writefile != INVALID_HANDLE)
			{
				WriteFileString(writefile,szMapEntitiesBuff,false);
			}
			CloseHandle(writefile);
		}
		
		bPortalParticleAvailable = false;
		int ParticleTable = FindStringTable("ParticleEffectNames");
		if (ParticleTable != INVALID_STRING_TABLE)
		{
			int iStrCount = GetStringTableNumStrings(ParticleTable);
			char szStrD[24];
			for (int j = 0;j<iStrCount;j++)
			{
				ReadStringTable(ParticleTable,j,szStrD,sizeof(szStrD));
				if (strlen(szStrD) > 0)
				{
					if (StrEqual(szStrD,"teleport_lambda_exit",false))
					{
						bPortalParticleAvailable = true;
						break;
					}
				}
			}
		}
		if (StrContains(mapbuf,"ptsd2_ptsd_2",false) != -1)
		{
			autorebuild = 2;
		}
		
		collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsClientConnected(i) && !IsFakeClient(i))
			{
				CreateTimer(1.0,clspawnpost,i,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		int cvarmodefl = GetCommandFlags("firstperson");
		if (cvarmodefl != INVALID_FCVAR_FLAGS)
		{
			SetCommandFlags("firstperson", (cvarmodefl & ~FCVAR_CHEAT));
			SetCommandFlags("firstperson", (cvarmodefl & ~FCVAR_SPONLY));
		}
		cvarmodefl = GetCommandFlags("thirdperson");
		if (cvarmodefl != INVALID_FCVAR_FLAGS)
		{
			SetCommandFlags("thirdperson", (cvarmodefl & ~FCVAR_CHEAT));
			SetCommandFlags("thirdperson", (cvarmodefl & ~FCVAR_SPONLY));
		}
		cvarmodefl = GetCommandFlags("flush");
		if (cvarmodefl != INVALID_FCVAR_FLAGS)
		{
			SetCommandFlags("flush", (cvarmodefl & ~FCVAR_CHEAT));
			SetCommandFlags("flush", (cvarmodefl & ~FCVAR_SPONLY));
		}
		findstraymdl(-1,"prop_dynamic");
		findstraymdl(-1,"point_template");
		findstraymdl(-1,"npc_zombie_scientist");
		findstraymdl(-1,"npc_zombie_security");
		findstraymdl(-1,"game_weapon_manager");
		findstraymdl(-1,"item_healthkit");
		findstraymdl(-1,"item_battery");
		findstraymdl(-1,"env_xen_pushpad");
		findstraymdl(-1,"env_mortar_controller");
		findstraymdl(-1,"env_dispenser");
		findstraymdl(-1,"trigger_once");
		findentlist(MaxClients+1,"npc_*");
		findentlist(MaxClients+1,"monster_*");
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
		PushArrayString(customentlist,"npc_human_security");
		PushArrayString(customentlist,"npc_scientist");
		PushArrayString(customentlist,"npc_human_scientist");
		PushArrayString(customentlist,"npc_human_scientist_female");
		PushArrayString(customentlist,"npc_human_scientist_eli");
		PushArrayString(customentlist,"npc_human_scientist_kleiner");
		PushArrayString(customentlist,"npc_zombie_security");
		PushArrayString(customentlist,"npc_zombie_security_torso");
		PushArrayString(customentlist,"npc_zombie_scientist");
		PushArrayString(customentlist,"npc_zombie_scientist_torso");
		PushArrayString(customentlist,"npc_zombie_worker");
		PushArrayString(customentlist,"npc_human_grunt");
		PushArrayString(customentlist,"npc_human_commander");
		PushArrayString(customentlist,"npc_human_grenadier");
		PushArrayString(customentlist,"npc_human_medic");
		PushArrayString(customentlist,"npc_human_assassin");
		PushArrayString(customentlist,"npc_assassin");
		PushArrayString(customentlist,"npc_odell");
		PushArrayString(customentlist,"npc_osprey");
		PushArrayString(customentlist,"npc_houndeye");
		PushArrayString(customentlist,"monster_houndeye");
		PushArrayString(customentlist,"npc_bullsquid");
		PushArrayString(customentlist,"monster_bullchicken");
		PushArrayString(customentlist,"npc_alien_slave");
		PushArrayString(customentlist,"npc_alien_controller");
		PushArrayString(customentlist,"npc_alien_grunt");
		PushArrayString(customentlist,"npc_alien_grunt_unarmored");
		PushArrayString(customentlist,"npc_snark");
		PushArrayString(customentlist,"npc_sentry_ceiling");
		PushArrayString(customentlist,"npc_tentacle");
		PushArrayString(customentlist,"npc_gonarch");
		PushArrayString(customentlist,"npc_babycrab");
		PushArrayString(customentlist,"npc_bmsgargantua");
		PushArrayString(customentlist,"npc_synth_scanner");
		PushArrayString(customentlist,"monster_gman");
		PushArrayString(customentlist,"monster_scientist");
		PushArrayString(customentlist,"monster_sitting_scientist");
		PushArrayString(customentlist,"monster_barney");
		PushArrayString(customentlist,"monster_ichthyosaur");
		PushArrayString(customentlist,"monster_headcrab");
		PushArrayString(customentlist,"monster_barnacle");
		PushArrayString(customentlist,"monster_alien_grunt");
		PushArrayString(customentlist,"monster_gargantua");
		PushArrayString(customentlist,"monster_human_assassin");
		PushArrayString(customentlist,"prop_train_awesome");
		PushArrayString(customentlist,"prop_train_apprehension");
		PushArrayString(customentlist,"item_weapon_tripmine");
		PushArrayString(customentlist,"item_weapon_satchel");
		PushArrayString(customentlist,"item_grenade_rpg");
		PushArrayString(customentlist,"item_weapon_rpg");
		PushArrayString(customentlist,"item_weapon_crossbow");
		PushArrayString(customentlist,"item_weapon_glock");
		PushArrayString(customentlist,"item_weapon_shotgun");
		PushArrayString(customentlist,"item_ammo_mp5");
		PushArrayString(customentlist,"item_grenade_mp5");
		PushArrayString(customentlist,"item_ammo_shotgun");
		PushArrayString(customentlist,"item_ammo_glock");
		PushArrayString(customentlist,"item_longjump");
		PushArrayString(customentlist,"weapon_flaregun");
		PushArrayString(customentlist,"item_ammo_flare_box");
		PushArrayString(customentlist,"item_box_flare_rounds");
		PushArrayString(customentlist,"item_custom");
		PushArrayString(customentlist,"weapon_medkit");
		PushArrayString(customentlist,"weapon_camera");
		PushArrayString(customentlist,"weapon_manhack");
		PushArrayString(customentlist,"weapon_manhackgun");
		PushArrayString(customentlist,"weapon_manhacktoss");
		PushArrayString(customentlist,"weapon_gluon");
		PushArrayString(customentlist,"weapon_gauss");
		PushArrayString(customentlist,"weapon_tau");
		PushArrayString(customentlist,"weapon_sniperrifle");
		PushArrayString(customentlist,"weapon_snark");
		PushArrayString(customentlist,"weapon_hivehand");
		PushArrayString(customentlist,"weapon_mp5");
		PushArrayString(customentlist,"weapon_glock");
		PushArrayString(customentlist,"weapon_m4");
		PushArrayString(customentlist,"weapon_oicw");
		PushArrayString(customentlist,"weapon_sl8");
		PushArrayString(customentlist,"weapon_uzi");
		PushArrayString(customentlist,"weapon_healer");
		PushArrayString(customentlist,"weapon_pistol1");
		PushArrayString(customentlist,"weapon_pistol2");
		PushArrayString(customentlist,"weapon_isa_knife");
		PushArrayString(customentlist,"weapon_ls13");
		PushArrayString(customentlist,"weapon_lugergun");
		PushArrayString(customentlist,"weapon_rifle1");
		PushArrayString(customentlist,"weapon_smg3");
		PushArrayString(customentlist,"weapon_smg4");
		PushArrayString(customentlist,"weapon_vc32sniperrifle");
		PushArrayString(customentlist,"weapon_camera");
		PushArrayString(customentlist,"weapon_goop");
		PushArrayString(customentlist,"weapon_bhg");
		PushArrayString(customentlist,"weapon_molotov");
		PushArrayString(customentlist,"item_weapon_gluon");
		PushArrayString(customentlist,"item_ammo_energy");
		PushArrayString(customentlist,"item_weapon_gauss");
		PushArrayString(customentlist,"item_weapon_tau");
		PushArrayString(customentlist,"item_weapon_snark");
		PushArrayString(customentlist,"item_weapon_hivehand");
		PushArrayString(customentlist,"item_weapon_mp5");
		PushArrayString(customentlist,"ladder_useable");
		PushArrayString(customentlist,"ladder_dismount");
		PushArrayString(customentlist,"weapon_immolator");
		PushArrayString(customentlist,"weapon_pistol_worker");
		PushArrayString(customentlist,"multi_manager");
		PushArrayString(customentlist,"npc_abrams");
		PushArrayString(customentlist,"npc_apache");
		PushArrayString(customentlist,"grenade_tripmine");
		PushArrayString(customentlist,"item_crate");
		PushArrayString(customentlist,"trigger_lift");
		PushArrayString(customentlist,"env_xen_portal");
		PushArrayString(customentlist,"env_xen_portal_template");
		PushArrayString(customentlist,"env_mortar_controller");
		PushArrayString(customentlist,"env_mortar_launcher");
		PushArrayString(customentlist,"env_xen_pushpad");
		PushArrayString(customentlist,"env_dispenser");
		PushArrayString(customentlist,"prop_surgerybot");
		PushArrayString(customentlist,"func_conveyor");
		PushArrayString(customentlist,"func_minefield");
		PushArrayString(customentlist,"func_50cal");
		PushArrayString(customentlist,"func_tow");
		PushArrayString(customentlist,"info_player_rebel");
		PushArrayString(customentlist,"info_player_combine");
		PushArrayString(customentlist,"info_player_deathmatch");
		PushArrayString(customentlist,"game_player_equip");
		PushArrayString(customentlist,"trigger_once_oc");
		PushArrayString(customentlist,"trigger_multiple_oc");
		PushArrayString(customentlist,"game_text_quick");
		PushArrayString(customentlist,"point_message_multiplayer");
		PushArrayString(customentlist,"weapon_scripted");
		PushArrayString(customentlist,"logic_merchant_relay");
		PushArrayString(customentlist,"logic_player_branch");
		PushArrayString(customentlist,"npc_merchant");
		PushArrayString(customentlist,"game_countdown_timer");
		PushArrayString(customentlist,"hlss_camera_output");
		PushArrayString(customentlist,"hlss_weaponstripper");
		if (syn1810act) PushArrayString(customentlist,"point_energy_ball_launcher");
		if ((!autorebuild) && (!rebuildentsset)) CreateTimer(0.1,rehooksaves,_,TIMER_FLAG_NO_MAPCHANGE);
		if ((rebuildentsset) && (!customents))
		{
			char mapspec[128];
			GetCurrentMap(mapspec,sizeof(mapspec));
			findstraymdl(-1,"npc_template_maker");
			findstraymdl(-1,"env_xen_portal_template");
			findstraymdl(-1,"func_conveyor");
			findstraymdl(-1,"env_mortar_controller");
			//This might break everything, or make it better
			//readcache(0,mapbuf,NULL_VECTOR);
			CreateTimer(0.1,readcachedelay,_,TIMER_FLAG_NO_MAPCHANGE);
			if (StrEqual(mapspec,"bm_c2a4fedt",false)) Format(mapspec,sizeof(mapspec),"bm_c2a4f");
			ReplaceString(mapspec,sizeof(mapspec),"bm_","sound/vo/");
			if (StrEqual(mapspec,"sound/vo/c1a0a",false)) recursion("sound/vo/c0a0c/");
			if (StrEqual(mapspec,"sound/vo/c1a1c",false)) recursion("sound/BMS_scripted/uc/");
			if (StrEqual(mapspec,"sound/vo/c1a2b",false)) recursion("sound/vo/c1a2a");
			if (StrEqual(mapspec,"sound/vo/c1a2c",false)) recursion("sound/vo/c1a2b");
			if (StrEqual(mapspec,"sound/vo/c2a1a",false)) recursion("sound/vo/c2a2a");
			if (StrEqual(mapspec,"sound/vo/c2a4f",false)) recursion("sound/vo/c1a3a");
			if (StrEqual(mapspec,"sound/vo/c2a4g",false)) recursion("sound/vo/c2a4f");
			if (StrEqual(mapspec,"sound/vo/c3a2b",false))
			{
				recursion("sound/vo/c3a2a");
				recursion("sound/BMS_objects/clickbeep/");
				PrecacheSound("BMS_objects\\doors\\doorslide_opened1.wav",true);
			}
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
			resetspawners(-1,"env_xen_portal_template");
			
			if (FileExists("resource/closecaption_bmsenglish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsenglish.txt");
			if (FileExists("resource/closecaption_bmsenglish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsenglish.dat");
			if (FileExists("resource/closecaption_bmsfinnish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsfinnish.txt");
			if (FileExists("resource/closecaption_bmsfinnish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsfinnish.dat");
			if (FileExists("resource/closecaption_bmsgerman.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsgerman.txt");
			if (FileExists("resource/closecaption_bmsgerman.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsgerman.dat");
			if (FileExists("resource/closecaption_bmsitalian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsitalian.txt");
			if (FileExists("resource/closecaption_bmsitalian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsitalian.dat");
			if (FileExists("resource/closecaption_bmsnorwegian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsnorwegian.txt");
			if (FileExists("resource/closecaption_bmsnorwegian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsnorwegian.dat");
			if (FileExists("resource/closecaption_bmsspanish.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsspanish.txt");
			if (FileExists("resource/closecaption_bmsspanish.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsspanish.dat");
			if (FileExists("resource/closecaption_bmsrussian.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsrussian.txt");
			if (FileExists("resource/closecaption_bmsrussian.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsrussian.dat");
			if (FileExists("resource/closecaption_bmsfrench.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsfrench.txt");
			if (FileExists("resource/closecaption_bmsfrench.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsfrench.dat");
			if (FileExists("resource/closecaption_bmsportuguese.txt",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsportuguese.txt");
			if (FileExists("resource/closecaption_bmsportuguese.dat",true,NULL_STRING)) AddFileToDownloadsTable("resource/closecaption_bmsportuguese.dat");
		}
		else if (autorebuild == 1)
		{
			//readcacheexperimental(0);
			CreateTimer(0.1,readexperimentalcachedelay,_,TIMER_FLAG_NO_MAPCHANGE);
			Handle cvarch = FindConVar("rebuildents");
			if (cvarch != INVALID_HANDLE) SetConVarInt(cvarch,0,false,false);
			CloseHandle(cvarch);
		}
		else if (autorebuild == 2)
		{
			CreateTimer(0.1,readcachedelay,_,TIMER_FLAG_NO_MAPCHANGE);
			
			//readcache(0,mapbuf,NULL_VECTOR);
			resetspawners(-1,"npc_maker");
			resetspawners(-1,"env_xen_portal");
			resetspawners(-1,"env_xen_portal_template");
			
			Handle cvarch = FindConVar("rebuildents");
			if (cvarch != INVALID_HANDLE) SetConVarInt(cvarch,0,false,false);
			CloseHandle(cvarch);
		}
		else if (customents)
		{
			resetspawners(-1,"npc_maker");
			resetspawners(-1,"env_xen_portal");
			resetspawners(-1,"env_xen_portal_template");
		}
		int nullfil = CreateEntityByName("filter_activator_class");
		if (nullfil != -1)
		{
			DispatchKeyValue(nullfil,"targetname","nullfil");
			DispatchKeyValue(nullfil,"Negated","0");
			DispatchSpawn(nullfil);
			ActivateEntity(nullfil);
		}
		if ((customents) || (autorebuild > 0) || (rebuildentsset))
		{
			HookEntityOutput("scripted_sequence","OnCancelSequence",custentend);
			HookEntityOutput("npc_maker","OnSpawnNPC",onxenspawn);
			HookEntityOutput("env_xen_portal","OnSpawnNPC",onxenspawn);
			HookEntityOutput("env_xen_portal_template","OnSpawnNPC",onxenspawn);
			HookEntityOutput("npc_human_security","OnFoundEnemy",SecFoundEnemy);
			HookEntityOutput("env_entity_maker","OnEntitySpawned",ptadditionalspawn);
		}
		CreateTimer(0.1,RecheckChangeLevels,_,TIMER_FLAG_NO_MAPCHANGE);
		PrecacheSound("npc\\roller\\code2.wav",true);
		PrecacheSound("npc\\roller\\mine\\rmine_moveslow_loop1.wav",true);
		PrecacheSound("npc\\roller\\mine\\rmine_movefast_loop1.wav",true);
		PrecacheSound("npc\\roller\\mine\\rmine_seek_loop2.wav",true);
		PrecacheSound("npc\\turret_floor\\alarm.wav",true);
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

public Action readcachedelay(Handle timer)
{
	readcache(0,mapbuf,NULL_VECTOR);
	resetchargers(-1,"item_healthcharger");
	resetchargers(-1,"item_suitcharger");
	resetspawners(-1,"npc_maker");
	resetspawners(-1,"env_xen_portal");
	resetspawners(-1,"env_xen_portal_template");
	return Plugin_Handled;
}

public Action readexperimentalcachedelay(Handle timer)
{
	readcacheexperimental(0);
	resetspawners(-1,"npc_maker");
	resetspawners(-1,"env_xen_portal");
	resetspawners(-1,"env_xen_portal_template");
	return Plugin_Handled;
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
	CloseHandle(entlist);
	CloseHandle(equiparr);
	CloseHandle(entnames);
	CloseHandle(physboxarr);
	CloseHandle(physboxharr);
	CloseHandle(elevlist);
	CloseHandle(inputsarrorigincls);
	ClearArrayHandles(restorecustoments);
	CloseHandle(restorecustoments);
	CloseHandle(hounds);
	CloseHandle(houndsmdl);
	CloseHandle(squids);
	CloseHandle(squidsmdl);
	CloseHandle(tents);
	CloseHandle(tentsmdl);
	CloseHandle(tentssnd);
	CloseHandle(grenlist);
	CloseHandle(tripmines);
	CloseHandle(controllers);
	CloseHandle(templateslist);
	CloseHandle(templatetargs);
	CloseHandle(templateents);
	CloseHandle(d_li);
	CloseHandle(d_ht);
	CloseHandle(customrelations);
	CloseHandle(ignoretrigs);
	CloseHandle(spawnerswait);
	CloseHandle(precachedarr);
	CloseHandle(conveyors);
	CloseHandle(delayedsounds);
	CloseHandle(delayedspeech);
	CloseHandle(passedstrings);
	CloseHandle(globalsarr);
	CloseHandle(merchantscr);
	ClearArrayHandles(merchantscrd);
	CloseHandle(merchantscrd);
}

public Action fixalyx(int client, int args)
{
	if (IsValidEntity(client))
	{
		if (HasEntProp(client,Prop_Data,"m_hViewEntity"))
		{
			if (GetEntPropEnt(client,Prop_Data,"m_hViewEntity") != -1)
			{
				PrintToChat(client,"You cannot do that while in a view control.");
				return Plugin_Handled;
			}
		}
	}
	char tmpmap[24];
	GetCurrentMap(tmpmap,sizeof(tmpmap));
	if ((StrEqual(tmpmap,"ep2_outland_12",false)) || (StrEqual(tmpmap,"ep2_outland_11b",false)) || (StrEqual(tmpmap,"ep2_outland_08",false)) || (StrEqual(tmpmap,"ep2_outland_02",false)) || (StrEqual(tmpmap,"ep1_citadel_04",false)) || (StrEqual(tmpmap,"d3_breen_01",false)) || (StrEqual(tmpmap,"d1_town_05",false))) return Plugin_Handled;
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
	if (IsValidEntity(client))
	{
		if (HasEntProp(client,Prop_Data,"m_hViewEntity"))
		{
			if (GetEntPropEnt(client,Prop_Data,"m_hViewEntity") != -1)
			{
				PrintToChat(client,"You cannot do that while in a view control.");
				return Plugin_Handled;
			}
		}
	}
	char tmpmap[24];
	GetCurrentMap(tmpmap,sizeof(tmpmap));
	if ((StrEqual(tmpmap,"ep1_c17_06",false)) || (StrEqual(tmpmap,"d1_trainstation_06",false))) return Plugin_Handled;
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
	if (client == 0) return Plugin_Continue;
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
			g_voteType = question;
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
			g_voteType = question;
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
	else if (action == MenuAction_Display)
	{
	 	if (g_voteType != question)
	 	{
			char title[64];
			menu.GetTitle(title, sizeof(title));
			
	 		char buffer[255];
			Format(buffer, sizeof(buffer), "%s", param1);

			//Panel panel = Panel param2;
			//panel.SetTitle(buffer);
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
		centnextatk[client] = 0.0;
		CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0,ReBuildClientCustoms,_,TIMER_FLAG_NO_MAPCHANGE);
		if (forcehdr) QueryClientConVar(client,"mat_hdr_level",hdrchk,0);
		if (StrContains(mapbuf,"bm_c",false) != -1) QueryClientConVar(client,"viewmodel_fov",viewmdlchk,1);
		else QueryClientConVar(client,"viewmodel_fov",viewmdlchk,0);
		QueryClientConVar(client,"cc_lang",langchk,0);
		showcc[client] = false;
		QueryClientConVar(client,"closecaption",checkccsettings,0);
		if ((GetClientCount(true) >= playercapadj) && (!appliedlargeplayeradj) && (playercapadj > 0))
		{
			appliedlargeplayeradj = true;
			reloadaftersetup = true;
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

public Action ReBuildClientCustoms(Handle timer)
{
	Handle arrayofents = CreateArray(128);
	if (GetArraySize(restorecustoments) > 0)
	{
		for (int i = 0;i<GetArraySize(restorecustoments);i++)
		{
			Handle dp = GetArrayCell(restorecustoments,i);
			if (dp != INVALID_HANDLE)
			{
				ResetPack(dp);
				char clsname[32];
				char targn[64];
				char mdl[64];
				ReadPackString(dp,clsname,sizeof(clsname));
				ReadPackString(dp,targn,sizeof(targn));
				ReadPackString(dp,mdl,sizeof(mdl));
				ReadPackCell(dp);
				float porigin[3];
				porigin[0] = ReadPackFloat(dp);
				porigin[1] = ReadPackFloat(dp);
				porigin[2] = ReadPackFloat(dp);
				if ((StrContains(clsname,"weapon_",false) == 0) || (StrContains(clsname,"custom_",false) == 0))
				{
					Handle dpsmall = CreateDataPack();
					WritePackString(dpsmall,clsname);
					WritePackString(dpsmall,targn);
					WritePackString(dpsmall,mdl);
					WritePackFloat(dpsmall,porigin[0]);
					WritePackFloat(dpsmall,porigin[1]);
					WritePackFloat(dpsmall,porigin[2]);
					PushArrayCell(arrayofents,dpsmall);
				}
			}
		}
	}
	findcustomweaps(-1,"weapon_*",arrayofents);
	findcustomweaps(-1,"custom_*",arrayofents);
	CloseHandle(arrayofents);
}

void findcustomweaps(int ent, char[] customtype, Handle arrayofents)
{
	int thisent = FindEntityByClassname(ent,customtype);
	if (IsValidEntity(thisent) && IsEntNetworkable(thisent))
	{
		char clsname[32];
		GetEntityClassname(thisent,clsname,sizeof(clsname));
		char globalname[64];
		GetEntPropString(thisent,Prop_Data,"m_iGlobalname",globalname,sizeof(globalname));
		bool saveent = false;
		if ((FindValueInArray(hounds,thisent) != -1) || (FindValueInArray(houndsmdl,thisent) != -1) || (FindValueInArray(squids,thisent) != -1) || (FindValueInArray(squidsmdl,thisent) != -1) || (FindValueInArray(tents,thisent) != -1) || (FindValueInArray(tentsmdl,thisent) != -1) || (FindValueInArray(tentssnd,thisent) != -1) || (FindStringInArray(customentlist,clsname) != -1)) saveent = true;
		if (saveent)
		{
			if (GetArraySize(arrayofents) > 0)
			{
				float orgs[3];
				char mdl[64];
				char targn[64];
				if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",orgs);
				if (HasEntProp(thisent,Prop_Data,"m_iName")) GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
				if (HasEntProp(thisent,Prop_Data,"m_ModelName")) GetEntPropString(thisent,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				for (int i = 0;i<GetArraySize(arrayofents);i++)
				{
					Handle dp = GetArrayCell(arrayofents,i);
					if (dp != INVALID_HANDLE)
					{
						float porigin[3];
						char tmpcls[32];
						char tmptarg[64];
						char tmpmdl[64];
						ResetPack(dp);
						ReadPackString(dp,tmpcls,sizeof(tmpcls));
						ReadPackString(dp,tmptarg,sizeof(tmptarg));
						ReadPackString(dp,tmpmdl,sizeof(tmpmdl));
						porigin[0] = ReadPackFloat(dp);
						porigin[1] = ReadPackFloat(dp);
						porigin[2] = ReadPackFloat(dp);
						if ((StrEqual(clsname,tmpcls,false)) && (StrEqual(targn,tmptarg,false)) && (StrEqual(mdl,tmpmdl,false)) && (orgs[0] == porigin[0]) && (orgs[1] == porigin[1]) && (orgs[2] == porigin[2]))
						{
							saveent = false;
						}
					}
				}
			}
			if (saveent)
			{
				char targent[8];
				if (StrContains(clsname,"weapon_",false) == 0)
				{
					if (HasEntProp(thisent,Prop_Data,"m_hOwner"))
					{
						int ownerent = GetEntPropEnt(thisent,Prop_Data,"m_hOwner");
						if (ownerent != -1)
						{
							Format(targent,sizeof(targent),"%i",ownerent);
						}
					}
				}
				Handle dp = packent(thisent,targent);
				if (dp != INVALID_HANDLE)
					PushArrayCell(restorecustoments,dp);
			}
		}
		findcustomweaps(thisent++,customtype,arrayofents);
	}
}

public Action everyspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		if (!IsFakeClient(client))
		{
			if (longjumpactive)
			{
				int hudhint = CreateEntityByName("env_hudhint");
				if (hudhint != -1)
				{
					char msg[64];
					if (LongJumpMode) Format(msg,sizeof(msg),"Jump + Direction + Jump LONG JUMP");
					else Format(msg,sizeof(msg),"Ctrl + Jump LONG JUMP");
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
											if ((StrEqual(basecls,"weapon_gluon",false)) || (StrEqual(basecls,"weapon_goop",false))) Format(basecls,sizeof(basecls),"weapon_shotgun");
											else if (StrEqual(basecls,"weapon_isa_knife",false)) Format(basecls,sizeof(basecls),"weapon_crowbar");
											else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
											else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false)) || (StrEqual(basecls,"weapon_p911",false)) || (StrEqual(basecls,"weapon_pistol2",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
											else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false)) || (StrEqual(basecls,"weapon_molotov",false))) Format(basecls,sizeof(basecls),"weapon_slam");
											else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false)) || (StrEqual(basecls,"weapon_camera",false)) || (StrEqual(basecls,"weapon_smg3",false)) || (StrEqual(basecls,"weapon_smg4",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
											else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false)) || (StrEqual(basecls,"weapon_vc32sniperrifle",false)) || (StrEqual(basecls,"weapon_bhg",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
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
																else if (StrEqual(scrline,"grenade",false)) Format(scrline,sizeof(scrline),"crowbar");
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
		if (!IsFakeClient(client))
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
			Handle weaparr = CreateArray(32);
			if (WeapList != -1)
			{
				for (int j; j<104; j += 4)
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
			if (HasEntProp(client,Prop_Send,"m_hVehicle")) vck = GetEntProp(client, Prop_Send, "m_hVehicle");
			if ((vck == -1) && ((FindStringInArray(weaparr,"weapon_physcannon") == -1) || (GetEntProp(client,Prop_Send,"m_bWearingSuit") > 0)) && (StrContains(mapbuf,"bm_c1a0a",false) == -1) && (StrContains(mapbuf,"d1_trainstation_05",false) == -1))
			{
				for (int j; j<GetArraySize(equiparr); j++)
				{
					int jtmp = GetArrayCell(equiparr, j);
					if (IsValidEntity(jtmp))
					{
						AcceptEntityInput(jtmp,"EquipPlayer",client);
					}
				}
			}
			if (GetArraySize(equiparr) > 0) //Run additional weapons separate
			{
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
											if ((StrEqual(basecls,"weapon_gluon",false)) || (StrEqual(basecls,"weapon_goop",false))) Format(basecls,sizeof(basecls),"weapon_shotgun");
											else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
											else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
											else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false)) || (StrEqual(basecls,"weapon_molotov",false))) Format(basecls,sizeof(basecls),"weapon_slam");
											else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_m4",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false)) || (StrEqual(basecls,"weapon_g36c",false)) || (StrEqual(basecls,"weapon_oicw",false)) || (StrEqual(basecls,"weapon_camera",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
											else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false)) || (StrEqual(basecls,"weapon_bhg",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
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
				bool ApplyVC = true;
				char cls[25];
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsValidEntity(i))
					{
						if (HasEntProp(i,Prop_Data,"m_hViewEntity"))
						{
							ViewEnt = GetEntPropEnt(i,Prop_Data,"m_hViewEntity");
							if ((IsValidEntity(ViewEnt)) && (ViewEnt > MaxClients))
							{
								GetEntityClassname(ViewEnt, cls, sizeof(cls));
								if (StrEqual(cls, "point_viewcontrol", false))
								{
									if (HasEntProp(ViewEnt,Prop_Data,"m_spawnflags"))
									{
										if (GetEntProp(ViewEnt,Prop_Data,"m_spawnflags") & 1<<7)
										{
											ApplyVC = false;//Needs testing, maybe by SetViewEntity Native
											AcceptEntityInput(ViewEnt,"Enable",client);
											break;
										}
									}
								}
							}
						}
					}
				}
				if (ApplyVC)
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
			SetEntProp(client,Prop_Data,"m_bPlayerUnderwater",1);
			if (longjumpactive)
			{
				int hudhint = CreateEntityByName("env_hudhint");
				if (hudhint != -1)
				{
					char msg[64];
					if (LongJumpMode) Format(msg,sizeof(msg),"Jump + Direction + Jump LONG JUMP");
					else Format(msg,sizeof(msg),"Ctrl + Jump LONG JUMP");
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
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_WeaponSwitch, OnWeaponUse);
			//Rebinds for default applications
			if (bFixRebind)
			{
				ClientCommand(client,"bind f1 vote_yes");
				ClientCommand(client,"bind f2 vote_no");
			}
			CreateTimer(0.1,restoresound,client,TIMER_FLAG_NO_MAPCHANGE);
			ClientCommand(client,"snd_restart");
			char briefing[128];
			char mapname[64];
			GetCurrentMap(mapname,sizeof(mapname));
			Format(briefing,sizeof(briefing),"maps/cfg/%s_briefing.txt",mapname);
			if (FileExists(briefing,true,NULL_STRING))
			{
				ShowMOTDPanel(client,mapname,briefing,MOTDPANEL_TYPE_FILE);
			}
			cllastsscape[client] = -1;
		}
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ReallowFlush(int client, int args)
{
	Handle cvar = FindConVar("sv_cheats");
	if (cvar != INVALID_HANDLE) SendConVarValue(client,cvar,"1");
	CloseHandle(cvar);
	ClientCommand(client,"flush;cl_soundscape_flush");
	ClientCommand(client,"blckreset");
	return Plugin_Handled;
}

public Action flushcmd(int client, const char[] command, int argc)
{
	Handle cvar = FindConVar("sv_cheats");
	if (cvar != INVALID_HANDLE) SendConVarValue(client,cvar,"0");
	CloseHandle(cvar);
	return Plugin_Handled;
}

public Action restoresound(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		if (IsClientConnected(client))
		{
			if (IsPlayerAlive(client))
			{
				if (GetArraySize(delayedsounds) > 0)
				{
					Handle removal = CreateArray(64);
					float Time = GetTickedTime();
					for (int j = 0;j<GetArraySize(delayedsounds);j++)
					{
						int i = GetArrayCell(delayedsounds,j);
						if (IsValidEntity(i))
						{
							if (centnextsndtime[i]-Time < -50)
							{
								PushArrayCell(removal,i);
							}
							else
							{
								char snd[64];
								if (HasEntProp(i,Prop_Data,"m_iszSound")) GetEntPropString(i,Prop_Data,"m_iszSound",snd,sizeof(snd));
								if ((StrContains(snd,"loop",false) != -1) || (StrEqual(snd,"d3_citadel.playerpod_move",false)) || (StrContains(snd,"ambien",false) != -1))
								{
									PushArrayCell(removal,i);
								}
								else if (strlen(snd) > 0)
								{
									if ((StrContains(snd,".mp3",false) == -1) && (StrContains(snd,".wav",false) == -1))
									{
										int chan,sndlvl,pitch;
										float vol;
										GetGameSoundParams(snd,chan,sndlvl,vol,pitch,snd,sizeof(snd),0);
									}
									if (StrContains(snd,"#",false) == 0) ReplaceString(snd,sizeof(snd),"#","");
									ClientCommand(client,"sndplaydelay %1.f \"%s\"",centnextsndtime[i]-Time,snd);
									if (debuglvl == 3) PrintToServer("Played delayed sound %s at %1.f seekpos",snd,centnextsndtime[i]-Time);
								}
							}
						}
						else
						{
							PushArrayCell(removal,i);
						}
					}
					if (GetArraySize(removal) > 0)
					{
						for (int j = 0;j<GetArraySize(removal);j++)
						{
							int i = GetArrayCell(removal,j);
							int findrm = FindValueInArray(delayedsounds,i);
							if (findrm != -1) RemoveFromArray(delayedsounds,findrm);
						}
					}
					CloseHandle(removal);
				}
				if (GetArraySize(delayedspeech) > 0)
				{
					Handle removal = CreateArray(6);
					float Time = GetTickedTime();
					char snd[64];
					for (int j = 0;j<GetArraySize(delayedspeech);j++)
					{
						Handle dp = GetArrayCell(delayedspeech,j);
						if (dp != INVALID_HANDLE)
						{
							ResetPack(dp);
							ReadPackString(dp,snd,sizeof(snd));
							int i = ReadPackCell(dp);
							if (centnextsndtime[i]-Time < -50)
							{
								PushArrayCell(removal,i);
							}
							else if (strlen(snd) > 0)
							{
								if ((StrContains(snd,".mp3",false) == -1) && (StrContains(snd,".wav",false) == -1))
								{
									if (StrContains(snd,"\"",false) != -1) ReplaceString(snd,sizeof(snd),"\"","");
									int chan,sndlvl,pitch;
									float vol;
									GetGameSoundParams(snd,chan,sndlvl,vol,pitch,snd,sizeof(snd),0);
								}
								if (StrContains(snd,"#",false) == 0) ReplaceString(snd,sizeof(snd),"#","");
								ClientCommand(client,"sndplaydelay %1.f \"%s\"",centnextsndtime[i]-Time,snd);
								if (debuglvl == 3) PrintToServer("Played delayed speech %s at %1.f seekpos",snd,centnextsndtime[i]-Time);
							}
						}
						else
						{
							PushArrayCell(removal,dp);
						}
					}
					if (GetArraySize(removal) > 0)
					{
						for (int j = 0;j<GetArraySize(removal);j++)
						{
							Handle i = GetArrayCell(removal,j);
							int findrm = FindValueInArray(delayedspeech,i);
							if (findrm != -1)
							{
								RemoveFromArray(delayedspeech,findrm);
								CloseHandle(i);
							}
						}
					}
					CloseHandle(removal);
				}
			}
		}
	}
}

public void hdrchk(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if ((StrEqual(cvarValue,"0",false)) || (StrEqual(cvarValue,"1",false)))
		ClientCommand(client,"mat_hdr_level 2");
}

public void viewmdlchk(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if ((StringToInt(cvarValue) < 80) && (value == 1))
	{
		ClientCommand(client,"viewmodel_fov 86");
	}
	else if ((StringToInt(cvarValue) == 86) && (value == 0))
	{
		ClientCommand(client,"viewmodel_fov 65");
	}
}

public void langchk(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (((StrContains(mapbuf,"maps/ent_cache/bms_bm_c",false) == 0) || (StrContains(mapbuf,"maps/ent_cache/bmsxen_xen_c",false) == 0)) && (FileExists("resource/closecaption_bmsenglish.txt",true,NULL_STRING)))
	{
		//PrintToServer("LangChk %s %s",cvarValue,restorelang[client]);
		if (strlen(cvarValue) < 1)
		{
			if (!StrEqual(cvarName,"cl_language",false)) QueryClientConVar(client,"cl_language",langchk,0);
			else ClientCommand(client,"cc_lang bmsenglish");
		}
		else if (StrContains(cvarValue,"bms",false) == -1)
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			Format(restorelang[client],sizeof(restorelang[]),"%s",tmplang);
			ClientCommand(client,"cc_lang bms%s",tmplang);
		}
		else
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			ClientCommand(client,"cc_lang %s",tmplang);
		}
	}
	else if ((StrContains(mapbuf,"maps/ent_cache/ep1_ep1_",false) == 0) && (FileExists("resource/closecaption_ep1english.txt",true,NULL_STRING)))
	{
		if (strlen(cvarValue) < 1)
		{
			if (!StrEqual(cvarName,"cl_language",false)) QueryClientConVar(client,"cl_language",langchk,0);
			else ClientCommand(client,"cc_lang ep1english");
		}
		else if (StrContains(cvarValue,"ep1",false) == -1)
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			Format(restorelang[client],sizeof(restorelang[]),"%s",tmplang);
			ClientCommand(client,"cc_lang ep1%s",tmplang);
		}
		else
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			ClientCommand(client,"cc_lang %s",tmplang);
		}
	}
	else if ((StrContains(mapbuf,"maps/ent_cache/ep2_ep2_outland_",false) == 0) && (FileExists("resource/closecaption_ep2english.txt",true,NULL_STRING)))
	{
		if (strlen(cvarValue) < 1)
		{
			if (!StrEqual(cvarName,"cl_language",false)) QueryClientConVar(client,"cl_language",langchk,0);
			else ClientCommand(client,"cc_lang ep2english");
		}
		else if (StrContains(cvarValue,"ep2",false) == -1)
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			Format(restorelang[client],sizeof(restorelang[]),"%s",tmplang);
			ClientCommand(client,"cc_lang ep2%s",tmplang);
		}
		else
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			ClientCommand(client,"cc_lang %s",tmplang);
		}
	}
	else if (((StrContains(mapbuf,"maps/ent_cache/custom_sp_",false) == 0) || (StrContains(mapbuf,"maps/ent_cache/cit2_sp_",false) == 0) || (StrContains(mapbuf,"maps/ent_cache/ep2_sp_",false) == 0)) && (StrContains(mapbuf, "sp_c14_", false) == -1) && (FileExists("resource/closecaption_cit2english.txt",true,NULL_STRING)))
	{
		if (strlen(cvarValue) < 1)
		{
			if (!StrEqual(cvarName,"cl_language",false)) QueryClientConVar(client,"cl_language",langchk,0);
			else ClientCommand(client,"cc_lang cit2english");
		}
		else if (StrContains(cvarValue,"cit",false) == -1)
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			if (StrContains(tmplang,"cit2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"cit2","");
			Format(restorelang[client],sizeof(restorelang[]),"%s",tmplang);
			ClientCommand(client,"cc_lang cit2%s",tmplang);
		}
		else
		{
			char tmplang[128];
			Format(tmplang,sizeof(tmplang),"%s",cvarValue);
			if (StrContains(tmplang,"ep1",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep1","");
			if (StrContains(tmplang,"ep2",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"ep2","");
			if (StrContains(tmplang,"bms",false) != -1) ReplaceString(tmplang,sizeof(tmplang),"bms","");
			ClientCommand(client,"cc_lang %s",tmplang);
		}
	}
	else if (strlen(restorelang[client]) > 0)
	{
		ClientCommand(client,"cc_lang %s",restorelang[client]);
	}
}

public void dbghch(Handle convar, const char[] oldValue, const char[] newValue)
{
	debuglvl = StringToInt(newValue);
}

public void dbghoch(Handle convar, const char[] oldValue, const char[] newValue)
{
	debugoowlvl = StringToInt(newValue);
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
			if (StrContains(clsname,"rotating",false) != -1)
			{
				if (HasEntProp(i,Prop_Data,"m_angRotation"))
				{
					float angs[3];
					GetEntPropVector(i,Prop_Data,"m_angRotation",angs);
					if (((angs[0] > 400.0) || (angs[1] > 400.0) || (angs[2] > 400.0)) || ((angs[0] < -400.0) || (angs[1] < -400.0) || (angs[2] < -400.0)))
					{
						if (HasEntProp(i,Prop_Data,"m_angStart"))
						{
							GetEntPropVector(i,Prop_Data,"m_angStart",angs);
							SetEntPropVector(i,Prop_Data,"m_angRotation",angs);
						}
						AcceptEntityInput(i,"StopAtStartPos");
						AcceptEntityInput(i,"Start");
					}
				}
			}
			else if ((HasEntProp(i,Prop_Data,"m_vecOrigin")) && (StrContains(mapbuf,"bm_c2",false) == -1) && (StrContains(clsname,"_",false) != -1) && (StrContains(clsname,"game",false) == -1) && (StrContains(clsname,"func_",false) == -1) && (StrContains(clsname,"path_",false) == -1) && (StrContains(clsname,"trigger_",false) == -1) && (StrContains(clsname,"logic_",false) == -1) && (StrContains(clsname,"ambient_generic",false) == -1) && (StrContains(clsname,"point_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (!StrEqual(clsname,"material_modify_control",false)) && (!StrEqual(clsname,"keyframe_rope",false)) && (!StrEqual(clsname,"move_rope",false)) && (StrContains(clsname,"npc_",false) == -1) && (StrContains(clsname,"monster_",false) == -1) && (StrContains(clsname,"info_",false) == -1) && (StrContains(clsname,"env_",false) == -1) && (StrContains(clsname,"scripted",false) == -1) && (!StrEqual(clsname,"momentary_rot_button",false)) && (!StrEqual(clsname,"syn_transition_wall",false)) && (!StrEqual(clsname,"prop_dynamic",false)) && (StrContains(clsname,"light_",false) == -1))
			{
				float pos[3];
				if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",pos);
				else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",pos);
				char fname[32];
				GetEntPropString(i,Prop_Data,"m_iName",fname,sizeof(fname));
				if (HasEntProp(i,Prop_Data,"m_hOwner"))
				{
					int owner = GetEntPropEnt(i,Prop_Data,"m_hOwner");
					if (owner != -1) continue;
				}
				if ((StrContains(fname,"elevator",false) == -1) && (((TR_PointOutsideWorld(pos)) && ((pos[0] < vMins[0]) || (pos[1] < vMins[1]) && (pos[2] < vMins[2])) && !(((pos[0] <= 1.0) && (pos[0] >= -1.0)) && ((pos[1] <= 1.0) && (pos[1] >= -1.0)) && ((pos[2] <= 1.0) && (pos[2] >= -1.0))))))
				{
					if ((debugoowlvl) && (i>MaxClients)) PrintToServer("%i %s with name %s fell out of world, removing...",i,clsname,fname);
					if (i>MaxClients) AcceptEntityInput(i,"kill");
					else
					{
						if (debugoowlvl) PrintToServer("%s %i with name %N fell out of world, moving back to spawn...",clsname,i,i);
						findspawnpos(i);
					}
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
			if (incfixer)
			{
				char findinc[128];
				Format(findinc,sizeof(findinc),"maps/%s.inc",maptochange);
				if (FileExists(findinc,true,NULL_STRING))
				{
					char includes[32];
					Handle incfile = OpenFile(findinc,"r",true,NULL_STRING);
					if (incfile != INVALID_HANDLE)
					{
						ReadFileLine(incfile,includes,sizeof(includes));
					}
					CloseHandle(incfile);
					if (strlen(includes) > 0)
					{
						TrimString(includes);
						//ServerCommand("sv_content_optional \"%s\"",includes);
						Handle srvcvar = FindConVar("sv_content_optional");
						if (srvcvar != INVALID_HANDLE)
						{
							SetConVarString(srvcvar,includes,true,false);
						}
						CloseHandle(srvcvar);
					}
				}
				else
				{
					//ServerCommand("sv_content_optional \"\"");
					Handle srvcvar = FindConVar("sv_content_optional");
					if (srvcvar != INVALID_HANDLE)
					{
						SetConVarString(srvcvar,"",true,false);
					}
					CloseHandle(srvcvar);
				}
			}
			if (rebuildnodes)
			{
				char findnode[128];
				Format(findnode,sizeof(findnode),"maps\\graphs\\%s.ain",maptochange);
				if (FileExists(findnode,false))
				{
					DeleteFile(findnode);
				}
			}
			Handle data = CreateDataPack();
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
		if (!RestartedMap)
		{
			char findnode[128];
			char mapname[128];
			char ctag[16];
			GetCmdArg(1,mapname,sizeof(mapname));
			if (args > 1)
			{
				Format(ctag,sizeof(ctag),"%s_",mapname);
				GetCmdArg(2,mapname,sizeof(mapname));
			}
			if (strlen(mapname) > 0)
			{
				TrimString(mapname);
				ReplaceString(mapname,sizeof(mapname),".bsp","",false);
			}
			if (incfixer)
			{
				char findinc[128];
				Format(findinc,sizeof(findinc),"maps/%s.inc",mapname);
				if (FileExists(findinc,true,NULL_STRING))
				{
					char includes[32];
					Handle incfile = OpenFile(findinc,"r",true,NULL_STRING);
					if (incfile != INVALID_HANDLE)
					{
						ReadFileLine(incfile,includes,sizeof(includes));
					}
					CloseHandle(incfile);
					if (strlen(includes) > 0)
					{
						//ServerCommand("sv_content_optional \"%s\"",includes);
						Handle srvcvar = FindConVar("sv_content_optional");
						if (srvcvar != INVALID_HANDLE)
						{
							SetConVarString(srvcvar,includes,true,false);
						}
						CloseHandle(srvcvar);
					}
				}
				else
				{
					//ServerCommand("sv_content_optional \"\"");
					Handle srvcvar = FindConVar("sv_content_optional");
					if (srvcvar != INVALID_HANDLE)
					{
						SetConVarString(srvcvar,"",true,false);
					}
					CloseHandle(srvcvar);
				}
			}
			char chkedt[128];
			Format(chkedt,sizeof(chkedt),"maps/%s%s.edt",ctag,mapname);
			if (!FileExists(chkedt,true,NULL_STRING)) Format(chkedt,sizeof(chkedt),"maps/%s%s.edt2",ctag,mapname);
			if (!FileExists(chkedt,true,NULL_STRING)) Format(chkedt,sizeof(chkedt),"maps/%s.edt",mapname);
			if (!FileExists(chkedt,true,NULL_STRING)) Format(chkedt,sizeof(chkedt),"maps/%s.edt2",mapname);
			if (FileExists(chkedt,true,NULL_STRING))
			{
				Handle readpreinstruct = OpenFile(chkedt,"r",true,NULL_STRING);
				if (readpreinstruct != INVALID_HANDLE)
				{
					char line[128];
					int linesread = 0;
					while(!IsEndOfFile(readpreinstruct)&&ReadFileLine(readpreinstruct,line,sizeof(line)))
					{
						TrimString(line);
						linesread++;
						if (StrContains(line,"sv_content_optional",false) != -1)
						{
							ReplaceString(line,sizeof(line),"sv_content_optional","",false);
							ReplaceString(line,sizeof(line),"\"","",false);
							TrimString(line);
							Handle srvcvar = FindConVar("sv_content_optional");
							if (srvcvar != INVALID_HANDLE)
							{
								SetConVarString(srvcvar,line,true,false);
							}
							CloseHandle(srvcvar);
							break;
						}
						if (linesread > 30) break;
					}
				}
				CloseHandle(readpreinstruct);
			}
			Format(findnode,sizeof(findnode),"maps\\graphs\\%s.ain",mapname);
			if (FileExists(findnode,false))
			{
				DeleteFile(findnode);
				PrintToServer("Removed ain for %s",mapname);
			}
			if ((StrContains(mapname,"bm_c",false) != -1) || (StrContains(mapbuf,"xen_c",false) != -1))
			{
				char gamedescoriginal[24];
				GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
				if ((StrEqual(gamedescoriginal,"synergy 20.1",false)) || (StrEqual(gamedescoriginal,"synergy 20.3",false)))
				{
					Handle srvcvar = FindConVar("sv_content_optional");
					if (srvcvar != INVALID_HANDLE)
					{
						SetConVarString(srvcvar,"ep2 ep1",true,false);
					}
					CloseHandle(srvcvar);
				}
			}
			if (!norunagain)
			{
				norunagain = true;
				char curmapbuf[64];
				GetCurrentMap(curmapbuf,sizeof(curmapbuf));
				if (!StrEqual(curmapbuf,mapname,false))
				{
					Handle data = CreateDataPack();
					WritePackString(data, mapname);
					WritePackString(data, curmapbuf);
					CreateTimer(1.0,changeleveldelay,data);
				}
			}
		}
		else RestartedMap = false;
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
			norunagain = true;
			if (StrContains(maptochange,".bsp",false) != -1) ReplaceString(maptochange,sizeof(maptochange),".bsp","",false);
			if (debuglvl > 1) PrintToServer("Failed to change map to %s attempting to change manually.",maptochange);
			Handle mdirlisting = OpenDirectory("maps",true,NULL_STRING);
			if (mdirlisting != INVALID_HANDLE)
			{
				char buff[64];
				while (ReadDirEntry(mdirlisting, buff, sizeof(buff)))
				{
					if ((!(mdirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
					{
						if (StrContains(buff,".bsp",false) != -1)
						{
							if (StrContains(maptochange,buff,false) != -1)
							{
								//case-sensitive map changes
								ReplaceString(buff,sizeof(buff),".bsp","",false);
								Format(maptochange,sizeof(maptochange),"%s",buff);
								break;
							}
						}
					}
				}
			}
			CloseHandle(mdirlisting);
			Handle cvar = FindConVar("content_metadata");
			if (cvar != INVALID_HANDLE)
			{
				char contentdata[64];
				GetConVarString(cvar,contentdata,sizeof(contentdata));
				char fixuptmp[16][16];
				ExplodeString(contentdata," ",fixuptmp,16,16,true);
				if (StrEqual(fixuptmp[1],"|",false)) Format(contentdata,sizeof(contentdata),"%s %s",fixuptmp[2],maptochange);
				else Format(contentdata,sizeof(contentdata),"%s %s",fixuptmp[2],maptochange);
				ServerCommand("changelevel %s",contentdata);
			}
			CloseHandle(cvar);
			ServerCommand("changelevel %s",maptochange);
			ServerCommand("changelevel ep1 %s",maptochange);
			ServerCommand("changelevel ep2 %s",maptochange);
			ServerCommand("changelevel Custom %s",maptochange);
			ServerCommand("changelevel syn %s",maptochange);
			ServerCommand("changelevel hl2 %s",maptochange);
		}
		else norunagain = false;
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

public Action vehicleseatadjust(const char[] output, int caller, int activator, float delay)
{
	if ((IsValidEntity(caller)) && (IsValidEntity(activator)) && (activator <= MaxClients) && (activator > 0))
	{
		Handle dp = CreateDataPack();
		WritePackCell(dp,caller);
		WritePackCell(dp,activator);
		CreateTimer(2.5,seatadjtimer,dp,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action seatadjtimer(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int vehicle = ReadPackCell(dp);
		int client = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(vehicle)) && (IsValidEntity(client)) && (client <= MaxClients) && (client > 0))
		{
			char mdl[128];
			GetEntPropString(vehicle,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			//PrintToServer("Enter %i %i %s",vehicle,client,mdl);
			if ((StrEqual(mdl,"models/vehicles/combine_apcdrivable.mdl",false)) || (StrEqual(mdl,"models/combine_apc.mdl",false)))
			{
				float seatadj[3];
				seatadj[0] = 1.0;
				seatadj[1] = -30.5;
				seatadj[2] = 60.0;
				SetEntPropVector(client,Prop_Data,"m_vecOrigin",seatadj);
			}
			else if ((StrContains(mapbuf,"ptsd_2_p4",false) != -1) || (StrContains(mapbuf,"ptsd_2_finale",false) != -1))
			{
				char szTargn[32];
				GetEntPropString(vehicle,Prop_Data,"m_iName",szTargn,sizeof(szTargn));
				if (StrContains(szTargn,"boat_test2",false) == 0)
				{
					int driver = GetEntProp(client,Prop_Data,"m_iHideHUD");
					if (driver == 3328)
					{
						float seatadj[3];
						seatadj[0] = -4.4;
						seatadj[1] = -50.46;
						seatadj[2] = 20.75;
						SetEntPropVector(client,Prop_Data,"m_vecOrigin",seatadj);
					}
				}
			}
		}
	}
}
/*
public Action fadebegin(const char[] output, int caller, int activator, float delay)
{
	int sf = GetEntProp(caller,Prop_Data,"m_spawnflags");
	//Include spawnflags 16 for activator only
	if (sf & 1<<4)
	{
		if ((activator > 0) && (activator < MaxClients+1))
		{
			isfading[activator] = true;
			int duration = RoundFloat(GetEntPropFloat(caller,Prop_Data,"m_Duration"));
			int holdtime = RoundFloat(GetEntPropFloat(caller,Prop_Data,"m_HoldTime"));
			int mode = 0;
			if (sf & 1<<1) mode = 1;
			int r,g,b,a;
			GetEntityRenderColor(caller,r,g,b,a);
			Handle userMessage = StartMessageOne("Fade", activator, USERMSG_RELIABLE);
			BfWriteShort(userMessage,duration);
			BfWriteShort(userMessage,holdtime);
			BfWriteShort(userMessage,mode);
			BfWriteByte(userMessage,r);
			BfWriteByte(userMessage,g);
			BfWriteByte(userMessage,b);
			BfWriteByte(userMessage,a);
			EndMessage();
			PrintToServer("Begin Fade to %i Mode %i col %i %i %i %i Dur %i Hold %i",activator,mode,r,g,b,a,duration,holdtime);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
*/
public Action blockfade(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char bfchar[64];
	BfReadString(msg,bfchar,sizeof(bfchar),false);
	if (strlen(bfchar) < 1)
	{
		int client = players[0];
		if (IsValidEntity(client))
		{
			//PrintToServer("Fading %i %i time %1.f %1.f",client,isfading[client],Time,fadingtime[client]);
			if (isfading[client])
			{
				//Sometimes fade can be called several times at once, for one client
				//which is why there must be a time frame for when it is allowed.
				float Time = GetTickedTime();
				if ((fadingtime[client] < Time) && (fadingtime[client] != 0.0)) isfading[client] = false;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
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
						if (bFixSoundScapes)
						{
							if ((HasEntProp(i,Prop_Data,"ent")) && (!IsFakeClient(i)))
							{
								int sscape = GetEntPropEnt(i,Prop_Data,"ent");
								if (IsValidEntity(sscape))
								{
									if (sscape != cllastsscape[i])
									{
										cllastsscape[i] = sscape;
										if ((HasEntProp(sscape,Prop_Data,"m_bDisabled")) && (HasEntProp(sscape,Prop_Data,"m_soundscapeName")))
										{
											char sndscape[64];
											GetEntPropString(sscape,Prop_Data,"m_soundscapeName",sndscape,sizeof(sndscape));
											Handle cvar = FindConVar("sv_cheats");
											if (cvar != INVALID_HANDLE)
											{
												if (GetConVarInt(cvar) < 1)
												{
													SendConVarValue(i,cvar,"1");
												}
											}
											CloseHandle(cvar);
											ClientCommand(i,"playsoundscape \"%s\"",sndscape);
											ClientCommand(i,"blckreset");
										}
									}
								}
							}
						}
						if (bFixNPCStuck)
						{
							char targn[64];
							char targn2[64];
							if (HasEntProp(i,Prop_Data,"m_iName")) GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
							if (strlen(targn) < 1)
							{
								Format(targn,sizeof(targn),"synplayer%i",i);
								SetEntPropString(i,Prop_Data,"m_iName",targn);
							}
							float vFeetPos[3], vNPCPos[3];
							bool bDistWithin = false;
							GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",vFeetPos);
							int ent = -1;
							while((ent = FindEntityByClassname(ent,"npc_*")) != INVALID_ENT_REFERENCE)
							{
								if (ent > MaxClients)
								{
									if (IsValidEntity(ent))
									{
										if (HasEntProp(ent,Prop_Data,"m_CollisionGroup"))
										{
											if (GetEntProp(ent,Prop_Data,"m_CollisionGroup") != 5)
											{
												GetEntPropVector(ent,Prop_Data,"m_vecAbsOrigin",vNPCPos);
												if (GetVectorDistance(vFeetPos,vNPCPos,false) < 10.0) bDistWithin = true;
												else
												{
													// In case player is lifted off ground by collision
													vNPCPos[2]+=20.0;
													if (GetVectorDistance(vFeetPos,vNPCPos,false) < 10.0) bDistWithin = true;
												}
												if (bDistWithin)
												{
													if (HasEntProp(ent,Prop_Data,"m_iName")) GetEntPropString(ent,Prop_Data,"m_iName",targn2,sizeof(targn2));
													if (strlen(targn2) < 1)
													{
														Format(targn2,sizeof(targn2),"synveh%i",ent);
														SetEntPropString(ent,Prop_Data,"m_iName",targn2);
													}
													int logcoll = CreateEntityByName("logic_collision_pair");
													if (logcoll != -1)
													{
														DispatchKeyValue(logcoll,"attach1",targn);
														DispatchKeyValue(logcoll,"attach2",targn2);
														DispatchKeyValue(logcoll,"StartDisabled","1");
														DispatchSpawn(logcoll);
														ActivateEntity(logcoll);
														AcceptEntityInput(logcoll,"DisableCollisions");
														Handle dp2 = CreateDataPack();
														WritePackCell(dp2,logcoll);
														WritePackString(dp2,"logic_collision_pair");
														CreateTimer(0.4,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
													}
													break;
												}
											}
										}
									}
								}
							}
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

public Action clticks(Handle timer)
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
						if (FindEntityByClassname(-1,"point_message") != -1)
						{
							float plypos[3];
							GetClientEyePosition(i,plypos);
							float angs[3];
							float trpos[3];
							GetClientEyeAngles(i,angs);
							TR_TraceRayFilter(plypos,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,i);
							TR_GetEndPosition(trpos);
							ShowPointMessages(-1,i,plypos,trpos,-1,999.0,-1);
						}
						if (HasEntProp(i,Prop_Data,"m_hViewEntity"))
						{
							int ViewEnt = GetEntPropEnt(i,Prop_Data,"m_hViewEntity");
							int hudset = GetEntProp(i,Prop_Data,"m_iHideHUD");
							if ((ViewEnt > MaxClients) && (IsValidEntity(ViewEnt)))
							{
								char cls[25];
								GetEntityClassname(ViewEnt,cls,sizeof(cls));
								if (StrEqual(cls,"point_viewcontrol",false))
								{
									if (HasEntProp(ViewEnt,Prop_Data,"m_spawnflags"))
									{
										if (GetEntProp(ViewEnt,Prop_Data,"m_spawnflags") & 1<<7)
										{
											if (HasEntProp(i,Prop_Data,"m_nRenderFX")) SetEntProp(i,Prop_Data,"m_nRenderFX",6);
										}
									}
									if (hudset != 2072)
									{
										SetEntProp(i,Prop_Data,"m_iHideHUD",2072);
										ChangeEdictState(i);
									}
								}
								else if (hudset == 2072)
								{
									if (HasEntProp(i,Prop_Data,"m_nRenderFX")) SetEntProp(i,Prop_Data,"m_nRenderFX",0);
									SetEntProp(i,Prop_Data,"m_iHideHUD",2048);
									ChangeEdictState(i);
								}
							}
							else if (!IsValidEntity(ViewEnt))
							{
								if (hudset == 2072)
								{
									if (HasEntProp(i,Prop_Data,"m_nRenderFX")) SetEntProp(i,Prop_Data,"m_nRenderFX",0);
									SetEntProp(i,Prop_Data,"m_iHideHUD",2048);
									ChangeEdictState(i);
								}
							}
						}
					}
				}
			}
		}
	}
}

void ShowPointMessages(int ent, int client, float plypos[3], float trpos[3], int closestmsg, float closestdist, int nextmsg)
{
	int thisent = FindEntityByClassname(ent,"point_message");
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		if (HasEntProp(thisent,Prop_Data,"m_drawText"))
		{
			if (GetEntProp(thisent,Prop_Data,"m_drawText") > 0)
			{
				float entpos[3];
				if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",entpos);
				else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",entpos);
				float chkdist = GetVectorDistance(trpos,entpos,false);
				if (chkdist < 60.0)
				{
					float plydist = GetVectorDistance(plypos,entpos,false);
					float displaydist = GetEntProp(thisent,Prop_Data,"m_radius")*0.8;
					if ((chkdist < closestdist) && (plydist < displaydist))
					{
						if (closestdist-chkdist < 3.1)
							nextmsg = closestmsg;
						else
							nextmsg = -1;
						closestmsg = thisent;
						closestdist = chkdist;
					}
				}
			}
		}
		ShowPointMessages(thisent++,client,plypos,trpos,closestmsg,closestdist,nextmsg);
	}
	else if (IsValidEntity(closestmsg))
	{
		char msg[64];
		if (IsValidEntity(nextmsg))
		{
			char msgnext[64];
			GetEntPropString(closestmsg,Prop_Data,"m_messageText",msg,sizeof(msg));
			GetEntPropString(nextmsg,Prop_Data,"m_messageText",msgnext,sizeof(msgnext));
			if (strlen(msg) > strlen(msgnext)) Format(msg,sizeof(msg),"%s\n%s",msg,msgnext);
			else Format(msg,sizeof(msg),"%s\n%s",msgnext,msg);
		}
		else
			GetEntPropString(closestmsg,Prop_Data,"m_messageText",msg,sizeof(msg));
		SetHudTextParams(-1.0, 0.3, 0.1, 200, 200, 200, 255, 1, 0.5, 0.5, 0.5);
		ShowHudText(client,1,"%s",msg);
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
				if (dropspawnflags & 1<<11)
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
					char clschk[32];
					GetEntityClassname(targent,clschk,sizeof(clschk));
					if ((moveto != 0) && ((strlen(entryanim) > 0) || (strlen(actanim) > 0) || (strlen(idleanim) > 0)))
					{
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
					else if (((strlen(entryanim) > 0) || (strlen(actanim) > 0) || (strlen(idleanim) > 0)) && (StrEqual(clschk,"npc_gonarch",false)))
					{
						float origin[3];
						float angs[3];
						if (HasEntProp(targent,Prop_Data,"m_angRotation")) GetEntPropVector(targent,Prop_Data,"m_angRotation",angs);
						if (HasEntProp(targent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targent,Prop_Data,"m_vecAbsOrigin",origin);
						else if (HasEntProp(targent,Prop_Send,"m_vecOrigin")) GetEntPropVector(targent,Prop_Send,"m_vecOrigin",origin);
						origin[0] = (origin[0] + (50.0 * Cosine(DegToRad(angs[1]))));
						origin[1] = (origin[1] + (50.0 * Sine(DegToRad(angs[1]))));
						origin[2]+=5.0;
						TeleportEntity(targent,origin,NULL_VECTOR,NULL_VECTOR);
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
	else CloseHandle(dp);
}

public Action SecFoundEnemy(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		float Time = GetTickedTime();
		if ((HasEntProp(caller,Prop_Data,"m_hEnemy")) && (lastseen[caller] < Time))
		{
			int enemy = GetEntPropEnt(caller,Prop_Data,"m_hEnemy");
			int activeweap = GetEntPropEnt(caller,Prop_Data,"m_hActiveWeapon");
			if ((enemy != -1) && (activeweap == -1))
			{
				if (HasEntProp(caller,Prop_Data,"m_spawnEquipment"))
				{
					char equipped[32];
					GetEntPropString(caller,Prop_Data,"m_spawnEquipment",equipped,sizeof(equipped));
					if (StrEqual(equipped,"Default",false))
					{
						SetVariantString("weapon_pistol");
						AcceptEntityInput(caller,"GiveWeapon");
					}
				}
			}
			else if (enemy != -1)
			{
				char snd[72];
				char enemycls[32];
				GetEntityClassname(enemy,enemycls,sizeof(enemycls));
				if ((StrEqual(enemycls,"npc_bullsquid",false)) || (StrEqual(enemycls,"monster_bullchicken",false)))
				{
					switch(GetRandomInt(1,9))
					{
						case 1:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_frankensquid01.wav");
						case 2:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_frankensquid02.wav");
						case 3:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_itsadinosaur.wav");
						case 4:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_nospit01.wav");
						case 5:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_nospit02.wav");
						case 6:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_nospit03.wav");
						case 7:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_octupus01.wav");
						case 8:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_spitchicken01.wav");
						case 9:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_squidchicken.wav");
					}
				}
				else if (StrContains(enemycls,"headcrab",false) != -1)
				{
					switch(GetRandomInt(1,15))
					{
						case 1:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab_poppingup01.wav");
						case 2:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab_whatarethesethings01.wav");
						case 3:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab_whatwouldyoucalledthesethings.wav");
						case 4:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab_wholedamnthing01.wav");
						case 5:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab01_watchyourhead.wav");
						case 6:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab02_morebuggers.wav");
						case 7:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab03a_competition01.wav");
						case 8:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab04_targetpractice.wav");
						case 9:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab05_watchforlilbuggers01.wav");
						case 10:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab06_yeck01.wav");
						case 11:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab07_cutestthing.wav");
						case 12:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab08.wav");
						case 13:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab09_everywhere01.wav");
						case 14:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab10_heebiejeebies01.wav");
						case 15:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headcrab11_creepy.wav");
					}
				}
				else if ((StrEqual(enemycls,"npc_houndeye",false)) || (StrEqual(enemycls,"monster_houndeye",false)))
				{
					Format(snd,sizeof(snd),"vo\\npc\\barneys\\houndeye0%i.wav",GetRandomInt(1,2));
				}
				else if (StrContains(enemycls,"zombie",false) != -1)
				{
					switch(GetRandomInt(1,15))
					{
						case 1:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_chowtimesover01.wav");
						case 2:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_dammit02.wav");
						case 3:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_donthinkso01.wav");
						case 4:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_donthinkso02.wav");
						case 5:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_eyepeeled01.wav");
						case 6:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_freeze01.wav");
						case 7:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_guests01.wav");
						case 8:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_headthing01.wav");
						case 9:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_heretheycome01.wav");
						case 10:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_letsseeifyoulikethis01.wav");
						case 11:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_nearya01.wav");
						case 12:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_notgood01.wav");
						case 13:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_nottsofast01.wav");
						case 14:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_nowords01.wav");
						case 15:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_openfire01.wav");
						case 16:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_openfire02.wav");
						case 17:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_shootthedamnthing01.wav");
						case 18:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_shootthedamnthing02.wav");
						case 19:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_theyarelikezombies02.wav");
						case 20:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_theyarelikezombies03.wav");
						case 21:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\zombies_wellshit01.wav");
					}
				}
				else
				{
					switch(GetRandomInt(1,3))
					{
						case 1:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headsup01.wav");
						case 2:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headsup02.wav");
						case 3:
							Format(snd,sizeof(snd),"vo\\npc\\barneys\\headsup03a_2009.wav");
					}
				}
				if (strlen(snd) > 0)
				{
					lastseen[caller] = Time+2.0;
					EmitSoundToAll(snd, caller, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
					EmitCC(caller,snd,512.0);
				}
			}
		}
	}
}

public Action onxenspawn(const char[] output, int caller, int activator, float delay)
{
	if (customents)
	{
		//PrintToServer("NPCMaker %i spawn %i",caller,activator);
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
				iActiveSpawnEnt = activator;
				iActiveSpawner = caller;
				if (IsValidEntity(activator))
				{
					char szChildName[128];
					if (HasEntProp(caller,Prop_Data,"m_ChildTargetName")) GetEntPropString(caller,Prop_Data,"m_ChildTargetName",szChildName,sizeof(szChildName));
					if (strlen(szChildName) > 0)
					{
						if (HasEntProp(activator,Prop_Data,"m_iName")) SetEntPropString(activator,Prop_Data,"m_iName",szChildName);
					}
				}
			}
			else
			{
				if (bPortalParticleAvailable)
				{
					int effect = CreateEntityByName("info_particle_system");
					if (effect != -1)
					{
						DispatchKeyValue(effect,"effect_name","teleport_lambda_exit");
						DispatchKeyValue(effect,"start_active","1");
						float origin[3];
						float angs[3];
						if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
						if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
						else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
						origin[2]+=25.0;
						TeleportEntity(effect,origin,angs,NULL_VECTOR);
						DispatchSpawn(effect);
						ActivateEntity(effect);
						AcceptEntityInput(effect,"Start");
						Handle dp2 = CreateDataPack();
						WritePackCell(dp2,effect);
						WritePackString(dp2,"info_particle_system");
						CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
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
				}
				if (IsValidEntity(activator))
				{
					char szChildName[128];
					if (HasEntProp(caller,Prop_Data,"m_ChildTargetName")) GetEntPropString(caller,Prop_Data,"m_ChildTargetName",szChildName,sizeof(szChildName));
					if (strlen(szChildName) > 0)
					{
						if (HasEntProp(activator,Prop_Data,"m_iName")) SetEntPropString(activator,Prop_Data,"m_iName",szChildName);
					}
				}
				int rand = GetRandomInt(1,3);
				char snd[64];
				Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
				EmitSoundToAll(snd, caller, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				AcceptEntityInput(caller,"FireUser2");
				trigtp("OnUser2",caller,caller,0.0);
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

public Action SetupMine(int mine)
{
	if (IsValidEntity(mine))
	{
		float loc[3];
		float angs[3];
		if (HasEntProp(mine,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(mine,Prop_Data,"m_vecAbsOrigin",loc);
		else if (HasEntProp(mine,Prop_Send,"m_vecOrigin")) GetEntPropVector(mine,Prop_Send,"m_vecOrigin",loc);
		if (HasEntProp(mine,Prop_Data,"m_angAbsRotation")) GetEntPropVector(mine,Prop_Data,"m_angAbsRotation",angs);
		loc[0] = (loc[0] + (1 * Cosine(DegToRad(angs[1]))));
		loc[1] = (loc[1] + (1 * Sine(DegToRad(angs[1]))));
		float fhitpos[3];
		TR_TraceRayFilter(loc,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,mine);
		TR_GetEndPosition(fhitpos);
		int beam = CreateEntityByName("env_beam");
		if (beam != -1)
		{
			DispatchKeyValue(beam,"spawnflags","3");
			DispatchKeyValue(beam,"life","0");
			DispatchKeyValue(beam,"texture","sprites/laserbeam.spr");
			DispatchKeyValue(beam,"model","sprites/laserbeam.spr");
			DispatchKeyValue(beam,"TextureScroll","35");
			DispatchKeyValue(beam,"framerate","10");
			DispatchKeyValue(beam,"rendercolor","0 200 200");
			DispatchKeyValue(beam,"BoltWidth","0.5");
			DispatchKeyValue(beam,"TouchType","4");
			TeleportEntity(beam,loc,angs,NULL_VECTOR);
			SetEntPropVector(beam,Prop_Data,"m_vecEndPos",fhitpos);
			SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",mine,0);
			SetEntProp(beam,Prop_Data,"m_nModelIndex",tauhl2beam);
			DispatchSpawn(beam);
			ActivateEntity(beam);
			int expl = CreateEntityByName("env_explosion");
			if (expl != -1)
			{
				char radius[8];
				char dmgmag[8];
				Format(radius,sizeof(radius),"250");
				Format(dmgmag,sizeof(dmgmag),"300");
				Handle cvar = FindConVar("sk_tripmine_radius");
				if (cvar != INVALID_HANDLE)
				{
					if (GetConVarInt(cvar) < 1) SetConVarInt(cvar,250,false,false);
					GetConVarString(cvar,radius,sizeof(radius));
				}
				CloseHandle(cvar);
				cvar = FindConVar("sk_npc_dmg_tripmine");
				if (cvar != INVALID_HANDLE)
				{
					if (GetConVarInt(cvar) < 1) SetConVarInt(cvar,300,false,false);
					GetConVarString(cvar,dmgmag,sizeof(dmgmag));
				}
				CloseHandle(cvar);
				TeleportEntity(expl,loc,angs,NULL_VECTOR);
				DispatchKeyValue(expl,"imagnitude",dmgmag);
				DispatchKeyValue(expl,"iradiusoverride",radius);
				DispatchKeyValue(expl,"rendermode","0");
				DispatchKeyValue(expl,"targetname","syn_tripmineexpl");
				DispatchSpawn(expl);
				ActivateEntity(expl);
				SetEntPropEnt(beam,Prop_Data,"m_hOwnerEntity",mine);
				SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",expl);
				SetEntPropEnt(mine,Prop_Data,"m_hOwnerEntity",beam);
				SetEntPropEnt(mine,Prop_Data,"m_hEffectEntity",expl);
				HookSingleEntityOutput(beam,"OnTouchedByEntity",TripMineExpl);
				ChangeEdictState(mine);
			}
		}
		if (FindValueInArray(tripmines,mine) == -1) PushArrayCell(tripmines,mine);
		SDKHookEx(mine,SDKHook_OnTakeDamage,TripMineTKdmg);
		if (FileExists("sound/weapons/tripmine/activate.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\tripmine\\activate.wav", mine, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
	}
}

public void TripMineExpl(const char[] output, int caller, int activator, float delay)
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

public Action TripMineTKdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
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
		SDKUnhook(victim, SDKHook_OnTakeDamage, TripMineTKdmg);
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

public void ptadditionalspawn(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		if (HasEntProp(caller,Prop_Data,"m_iszTemplate"))
		{
			char targn[64];
			GetEntPropString(caller,Prop_Data,"m_iszTemplate",targn,sizeof(targn));
			if (strlen(targn) > 0)
				findpts(targn,0.0);
		}
	}
}

void findpts(char[] targn, float delay)
{
	//PrintToServer("PT search %s %f %i %i",targn,delay,GetArraySize(templateslist),GetArraySize(templatetargs));
	Handle temparr = CreateArray(128);
	for (int j = 0;j<GetArraySize(templateslist);j++)
	{
		int i = GetArrayCell(templateslist,j);
		if (IsValidEntity(i))
		{
			char tmpname[64];
			char tmpchild[64];
			if (HasEntProp(i,Prop_Data,"m_iName")) GetEntPropString(i,Prop_Data,"m_iName",tmpname,sizeof(tmpname));
			if (HasEntProp(i,Prop_Data,"m_ChildTargetName")) GetEntPropString(i,Prop_Data,"m_ChildTargetName",tmpchild,sizeof(tmpchild));
			ReplaceStringEx(tmpchild,sizeof(tmpchild),"pttemplate","");
			//PrintToServer("Template named %s %s",tmpname,tmpchild);
			if ((StrEqual(tmpname,targn,false)) || (StrEqual(tmpchild,targn,false)))
			{
				PushArrayCell(temparr,i);
			}
		}
	}
	if (GetArraySize(temparr) < 1)
	{
		Handle nextarrchk = CreateArray(128);
		FindAllByClassname(nextarrchk,-1,"env_entity_maker");
		if (GetArraySize(nextarrchk) > 0)
		{
			for (int j = 0;j<GetArraySize(nextarrchk);j++)
			{
				int i = GetArrayCell(nextarrchk,j);
				if (IsValidEntity(i))
				{
					char tmpname[64];
					char tmpchild[64];
					if (HasEntProp(i,Prop_Data,"m_iName")) GetEntPropString(i,Prop_Data,"m_iName",tmpname,sizeof(tmpname));
					if (HasEntProp(i,Prop_Data,"m_iszTemplate")) GetEntPropString(i,Prop_Data,"m_iszTemplate",tmpchild,sizeof(tmpchild));
					ReplaceStringEx(tmpchild,sizeof(tmpchild),"pttemplate","");
					//PrintToServer("Template named %s %s",tmpname,tmpchild);
					if ((StrEqual(tmpname,targn,false)) || (StrEqual(tmpchild,targn,false)))
					{
						PushArrayCell(temparr,i);
					}
				}
			}
		}
		CloseHandle(nextarrchk);
	}
	if ((GetArraySize(templatetargs) > 0) && (GetArraySize(temparr) > 0))
	{
		for (int i = 0;i<GetArraySize(temparr);i++)
		{
			int templateent = GetArrayCell(temparr,i);
			char clschk[24];
			GetEntityClassname(templateent,clschk,sizeof(clschk));
			//PrintToServer("PT %i %s",templateent,clschk);
			if (StrEqual(clschk,"env_entity_maker",false))
			{
				char tmpchild[128];
				if (HasEntProp(templateent,Prop_Data,"m_iszTemplate")) GetEntPropString(templateent,Prop_Data,"m_iszTemplate",tmpchild,sizeof(tmpchild));
				Handle alltargs = CreateArray(64);
				SearchForAllByTargetname(tmpchild,alltargs);
				if (GetArraySize(alltargs) > 0)
				{
					for (int k = 0;k<GetArraySize(alltargs);k++)
					{
						int ptent = GetArrayCell(alltargs,k);
						if (IsValidEntity(ptent))
						{
							char tmpchk[32];
							for (int j = 0;j<16;j++)
							{
								Format(tmpchk,sizeof(tmpchk),"m_iszTemplateEntityNames[%i]",j);
								if (HasEntProp(ptent,Prop_Data,tmpchk))
								{
									char templatename[32];
									GetEntPropString(ptent,Prop_Data,tmpchk,templatename,sizeof(templatename));
									if (strlen(templatename) > 0)
									{
										int find = FindStringInArray(templatetargs,templatename);
										if (find != -1)
										{
											if (debuglvl >= 2) PrintToServer("point_template spawn custom ent %s",templatename);
											Handle dp = GetArrayCell(templateents,find);
											if (delay > 0.01)
											{
												Handle dppass = CreateDataPack();
												WritePackCell(dppass,templateent);
												WritePackCell(dppass,dp);
												CreateTimer(delay,restoreentdp,dppass,TIMER_FLAG_NO_MAPCHANGE);
												CreateTimer(delay,restoreentfire,ptent,TIMER_FLAG_NO_MAPCHANGE);
											}
											else
											{
												restoreentarr(dp,templateent,true);
												//RemoveFromArray(templateents,find);
												//RemoveFromArray(templatetargs,find);
											}
										}
									}
								}
							}
						}
					}
				}
				CloseHandle(alltargs);
			}
			else if (StrEqual(clschk,"point_template"))
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
								if (delay > 0.01)
								{
									Handle dppass = CreateDataPack();
									WritePackCell(dppass,-1);
									WritePackCell(dppass,dp);
									CreateTimer(delay,restoreentdp,dppass,TIMER_FLAG_NO_MAPCHANGE);
									CreateTimer(delay,restoreentfire,templateent,TIMER_FLAG_NO_MAPCHANGE);
								}
								else
								{
									restoreentarr(dp,-1,true);
									//RemoveFromArray(templateents,find);
									//RemoveFromArray(templatetargs,find);
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
					char templatename[128];
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
								Handle dppass = CreateDataPack();
								WritePackCell(dppass,templateent);
								WritePackCell(dppass,dp);
								CreateTimer(delay,restoreentdp,dppass,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(delay,restoreentfire,templateent,TIMER_FLAG_NO_MAPCHANGE);
							}
							else
							{
								restoreentarr(dp,templateent,false);
								if (HasEntProp(templateent,Prop_Data,"m_nLiveChildren"))
								{
									int lvchild = GetEntProp(templateent,Prop_Data,"m_nLiveChildren");
									SetEntProp(templateent,Prop_Data,"m_nLiveChildren",lvchild++);
								}
								AcceptEntityInput(templateent,"FireUser1");
							}
						}
					}
					else
					{
						if (bPortalParticleAvailable)
						{
							int effect = CreateEntityByName("info_particle_system");
							if (effect != -1)
							{
								DispatchKeyValue(effect,"effect_name","teleport_lambda_exit");
								DispatchKeyValue(effect,"start_active","1");
								float origin[3];
								float angs[3];
								if (HasEntProp(templateent,Prop_Data,"m_angRotation")) GetEntPropVector(templateent,Prop_Data,"m_angRotation",angs);
								if (HasEntProp(templateent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(templateent,Prop_Data,"m_vecAbsOrigin",origin);
								else if (HasEntProp(templateent,Prop_Send,"m_vecOrigin")) GetEntPropVector(templateent,Prop_Send,"m_vecOrigin",origin);
								origin[2]+=25.0;
								TeleportEntity(effect,origin,angs,NULL_VECTOR);
								DispatchSpawn(effect);
								ActivateEntity(effect);
								AcceptEntityInput(effect,"Start");
								Handle dp2 = CreateDataPack();
								WritePackCell(dp2,effect);
								WritePackString(dp2,"info_particle_system");
								CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						else
						{
							int dispent = CreateEntityByName("env_sprite");
							if (dispent != -1)
							{
								float origin[3];
								float angs[3];
								if (HasEntProp(templateent,Prop_Data,"m_angRotation")) GetEntPropVector(templateent,Prop_Data,"m_angRotation",angs);
								if (HasEntProp(templateent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(templateent,Prop_Data,"m_vecAbsOrigin",origin);
								else if (HasEntProp(templateent,Prop_Send,"m_vecOrigin")) GetEntPropVector(templateent,Prop_Send,"m_vecOrigin",origin);
								DispatchKeyValue(dispent,"model","materials/effects/tele_exit.vmt");
								DispatchKeyValue(dispent,"scale","0.4");
								DispatchKeyValue(dispent,"rendermode","2");
								origin[2]+=25.0;
								TeleportEntity(dispent,origin,angs,NULL_VECTOR);
								DispatchSpawn(dispent);
								ActivateEntity(dispent);
								CreateTimer(0.1,reducescale,dispent,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
						EmitSoundToAll(snd, templateent, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
						AcceptEntityInput(templateent,"FireUser2");
						trigtp("OnUser2",templateent,templateent,0.0);
					}
				}
			}
		}
	}
	CloseHandle(temparr);
}

void findmassset(Handle dp, float delay)
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
				char clschk[32];
				GetEntityClassname(targ,clschk,sizeof(clschk));
				if (!StrEqual(clschk,"func_physbox",false))
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
	else CloseHandle(dp);
}

public Action restoreentdp(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int templateent = ReadPackCell(dp);
		Handle dppass = ReadPackCell(dp);
		CloseHandle(dp);
		if (IsValidEntity(templateent))
		{
			if (HasEntProp(templateent,Prop_Data,"m_nLiveChildren"))
			{
				int lvchild = GetEntProp(templateent,Prop_Data,"m_nLiveChildren");
				SetEntProp(templateent,Prop_Data,"m_nLiveChildren",lvchild++);
			}
		}
		restoreentarr(dppass,templateent,false);
	}
	else CloseHandle(dp);
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

public void checkccsettings(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (StringToInt(cvarValue) == 1) showcc[client] = true;
	else showcc[client] = false;
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
		char tmpout[32];
		Format(tmpout,sizeof(tmpout),output);
		char clsname[24];
		if (IsValidEntity(caller))
		{
			GetEntityClassname(caller,clsname,sizeof(clsname));
			if (((StrEqual(clsname,"hud_timer",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"logic_choreographed_scene",false))) && ((actmod > MaxClients) || (actmod < 1)))
			{
				actmod = 0;
			}
			if ((StrEqual(clsname,"trigger_multiple",false)) || (StrEqual(clsname,"prop_dynamic",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"func_door",false)) || (StrEqual(clsname,"trigger_coop",false)) || (StrEqual(clsname,"hud_timer",false)))
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
		char targn[64];
		GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
		if (strlen(targn) < 1) Format(targn,sizeof(targn),"notargn");
		float origin[3];
		if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
		else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
		if (StrEqual(clsname,"env_xen_portal",false)) origin[2]-=20.0;
		if (playerteleports) readoutputstp(caller,targn,tmpout,"Teleport",origin,actmod);
		if (vehiclemaphook) readoutputstp(caller,targn,tmpout,"Save",origin,actmod);
		if (customents)
		{
			readoutputstp(caller,targn,tmpout,"StartPortal",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Deploy",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Retire",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Spawn",origin,actmod);
			readoutputstp(caller,targn,tmpout,"SpawnNPCInLine",origin,actmod);
			readoutputstp(caller,targn,tmpout,"ForceSpawn",origin,actmod);
			readoutputstp(caller,targn,tmpout,"BeginRappellingGrunts",origin,actmod);
			readoutputstp(caller,targn,tmpout,"DisplayText",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Purchase",origin,actmod);
			readoutputstp(caller,targn,tmpout,"SetPurchaseName",origin,actmod);
			readoutputstp(caller,targn,tmpout,"SetPurchaseCost",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Disable",origin,actmod);
			readoutputstp(caller,targn,tmpout,"CounterEntity",origin,actmod);
			readoutputstp(caller,targn,tmpout,"ApplyScore",origin,actmod);
			readoutputstp(caller,targn,tmpout,"SetTimerLabel",origin,actmod);
			readoutputstp(caller,targn,tmpout,"StartTimer",origin,actmod);
			readoutputstp(caller,targn,tmpout,"StopTimer",origin,actmod);
			readoutputstp(caller,targn,tmpout,"TakeAmmo",origin,actmod);
			readoutputstp(caller,targn,tmpout,"TakeAllAmmo",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Test",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Activate",origin,actmod);
			readoutputstp(caller,targn,tmpout,"Break",origin,actmod);
		}
		readoutputstp(caller,targn,tmpout,"SetMass",origin,actmod);
		readoutputstp(caller,targn,tmpout,"Fade",origin,actmod);
		readoutputstp(caller,targn,tmpout,"EquipAllPlayers",origin,actmod);
		readoutputstp(caller,targn,tmpout,"EquipPlayer",origin,actmod);
		readoutputstp(caller,targn,tmpout,"SetCheckPoint",origin,actmod);
		readoutputstp(caller,targn,tmpout,"CLCommand",origin,actmod);
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

public Action listaddedhooks(int args)
{
	if (GetArraySize(addedinputs) > 0)
	{
		char inputadded[64];
		char chkinps[128];
		for (int i = 0;i<GetArraySize(addedinputs);i++)
		{
			GetArrayString(addedinputs,i,inputadded,sizeof(inputadded));
			PrintToServer("AddedInputHook %s",inputadded);
			for (int j = 0;j<GetArraySize(inputsarrorigincls);j++)
			{
				GetArrayString(inputsarrorigincls,j,chkinps,sizeof(chkinps));
				if (StrContains(chkinps,inputadded,false) != -1)
				{
					PrintToServer("HookForInput %s",chkinps);
				}
			}
		}
	}
	return Plugin_Handled;
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

public Action centcratebreak(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		if (HasEntProp(caller,Prop_Data,"m_iszResponseContext"))
		{
			char breakitems[128];
			char breakitemsexpl[128][32];
			GetEntPropString(caller,Prop_Data,"m_iszResponseContext",breakitems,sizeof(breakitems));
			if (strlen(breakitems) > 0)
			{
				float porigin[3];
				float pangs[3];
				if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",porigin);
				else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",porigin);
				if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",pangs);
				ExplodeString(breakitems,",",breakitemsexpl,32,128,true);
				for (int i = 0;i<16;i++)
				{
					if (strlen(breakitemsexpl[i]) > 0)
					{
						TrimString(breakitemsexpl[i]);
						if (StrEqual(breakitemsexpl[i],"item_ammo_mp5",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"item_ammo_smg1");
						else if (StrEqual(breakitemsexpl[i],"item_ammo_shotgun",false)) Format(breakitemsexpl[i],sizeof(breakitemsexpl[]),"item_box_buckshot");
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

public Action rebuildents(int client, int args)
{
	if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		if (StrEqual(h,"0"))
		{
			readcache(client,mapbuf,NULL_VECTOR);
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
		readcache(client,mapbuf,NULL_VECTOR);
		char mapspec[128];
		GetCurrentMap(mapspec,sizeof(mapspec));
		ReplaceString(mapspec,sizeof(mapspec),"bm_","sound/vo/");
		recursion(mapspec);
	}
	return Plugin_Handled;
}

public void recursion(char sbuf[128])
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

void FindGlobals(int ent)
{
	int thisent = FindEntityByClassname(ent,"env_global");
	if (thisent != -1)
	{
		if (FindValueInArray(globalsarr,thisent) == -1) PushArrayCell(globalsarr,thisent);
		FindGlobals(thisent++);
	}
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
				char changeskin[128];
				Format(changeskin,sizeof(changeskin),"OnEmpty !self:Skin:1:0:-1,0,-1");
				SetVariantString(changeskin);
				AcceptEntityInput(thisent,"AddOutput");
				Format(changeskin,sizeof(changeskin),"OnFull !self:Skin:2:0:-1,0,-1");
				SetVariantString(changeskin);
				AcceptEntityInput(thisent,"AddOutput");
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
		if ((StrEqual(clschk,"npc_headcrab",false)) && (StrContains(clstarg,"pttemplate",false) == 0))
		{
			AcceptEntityInput(thisent,"Disable");
			//CreateTimer(1.0,waitinitspawner,thisent,TIMER_FLAG_NO_MAPCHANGE);
		}
		if ((FindStringInArray(customentlist,clschk) != -1) && (!StrEqual(clsname,"info_target",false)))
		{
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
					setuprelations("npc_alien_slave");
					relsetvort = true;
				}
			}
			else if (StrEqual(clschk,"npc_alien_controller",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_vortigaunt");
				DispatchKeyValue(thisent,"NPCType","npc_vortigaunt");
				if (!relsetvort)
				{
					setuprelations("npc_alien_slave");
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
			else if (StrEqual(clschk,"monster_alien_grunt",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_combine_s");
				DispatchKeyValue(thisent,"NPCType","npc_combine_s");
				if (FindStringInArray(precachedarr,"monster_alien_grunt") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/npc/agrunt/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"monster_alien_grunt");
				}
			}
			else if (StrEqual(clschk,"monster_gargantua",false))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_gargantua");
				DispatchKeyValue(thisent,"NPCType","npc_gargantua");
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
			else if ((StrEqual(clschk,"npc_houndeye",false)) || (StrEqual(clschk,"monster_houndeye",false)) || (StrEqual(clschk,"npc_bullsquid",false)))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_antlion");
				DispatchKeyValue(thisent,"NPCType","npc_antlion");
			}
			else if ((StrEqual(clschk,"npc_sentry_ground",false)) || (StrEqual(clschk,"npc_sentry_ceiling",false)))
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","generic_actor");
				DispatchKeyValue(thisent,"NPCType","generic_actor");
			}
			else
			{
				SetEntPropString(thisent,Prop_Data,"m_iszNPCClassname","npc_citizen");
				DispatchKeyValue(thisent,"NPCType","npc_citizen");
			}
		}
		resetspawners(thisent++,clsname);
	}
}

public int FindByTargetName(char[] entname)
{
	char staticsize[128];
	Format(staticsize,sizeof(staticsize),"%s",entname);
	int chkents = SearchForClass(staticsize);
	if ((chkents != -1) && (chkents != 0)) return chkents;
	int startent = MaxClients+1;
	for (int i = startent;i<GetMaxEntities()+1;i++)
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
		else CloseHandle(dp);
		AcceptEntityInput(findtemplateent,"kill");
	}
}
*/
void readcache(int client, char[] cache, float offsetpos[3])
{
	if ((debuglvl == 3) && (debugoowlvl > 0)) PrintToServer("Currentents %i",GetEntityCount());
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
		char oldcls[64];
		bool passvars = false;
		bool createsit = false;
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line,"classname",false))
			{
				char clschk[128];
				Format(clschk,sizeof(clschk),"%s",line);
				ExplodeString(clschk, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				if (FindStringInArray(customentlist,kvs[3]) != -1)
				{
					createent = true;
					PushArrayString(passedarr,kvs[1]);
					PushArrayString(passedarr,kvs[3]);
				}
				else if ((StrEqual(kvs[3],"npc_template_maker",false)) || (StrEqual(kvs[3],"env_xen_portal_template",false)))
				{
					storetemplate = true;
					if (FindStringInArray(precachedarr,"env_xen_portal") == -1)
					{
						PrecacheSound("BMS_objects\\portal\\portal_In_01.wav",true);
						PrecacheSound("BMS_objects\\portal\\portal_In_02.wav",true);
						PrecacheSound("BMS_objects\\portal\\portal_In_03.wav",true);
						PushArrayString(precachedarr,"env_xen_portal");
					}
				}
				else if ((StrEqual(kvs[1],"classname",false)) && (FindStringInArray(customentlist,kvs[3]) == -1))
				{
					createent = false;
				}
			}
			if ((!StrEqual(line,"}",false)) || (!StrEqual(line,"{",false)) || (!StrEqual(line,"}{",false)))
			{
				if (ent == -1) passvars = true;
				else if (passvars)
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
						if ((StrEqual(ktmp,"OnStartPortal",false)) || (StrEqual(ktmp,"OnFinishPortal",false))) Format(ktmp,sizeof(ktmp),"OnUser2");
						else if (StrEqual(ktmp,"OnDetonate",false)) Format(ktmp,sizeof(ktmp),"OnUser2");
						DispatchKeyValue(ent,ktmp,ktmp2);
					}
				}
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),"%s",line);
				ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				if ((StrEqual(kvs[1],"OnStartPortal",false)) || (StrEqual(kvs[1],"OnFinishPortal",false))) Format(kvs[1],sizeof(kvs[]),"OnUser2");
				else if (StrEqual(kvs[1],"OnDetonate",false)) Format(kvs[1],sizeof(kvs[]),"OnUser2");
				else if (StrEqual(kvs[1],"OnPostSpawnBall",false)) Format(kvs[1],sizeof(kvs[]),"OnUser2");
				if (StrEqual(kvs[1],"AdditionalEquipment",false))
				{
					if (StrEqual(kvs[3],"weapon_glock",false)) Format(kvs[3],sizeof(kvs[]),"weapon_pistol");
					else if (StrEqual(kvs[3],"weapon_mp5",false)) Format(kvs[3],sizeof(kvs[]),"weapon_smg1");
					else if (StrEqual(kvs[3],"q",false)) Format(kvs[3],sizeof(kvs[]),"weapon_rpg");
				}
				if (StrEqual(kvs[1],"liftaccel",false))
				{
					Format(kvs[1],sizeof(kvs[]),"Speed");
					int speedadjust = StringToInt(kvs[3]);
					speedadjust = speedadjust*10;
					if (speedadjust > 1000) speedadjust = 1000;
					Format(kvs[3],sizeof(kvs[]),"%i",speedadjust);
				}
				PushArrayString(passedarr,kvs[1]);
				PushArrayString(passedarr,kvs[3]);
				if (!passvars)
				{
					DispatchKeyValue(ent,kvs[1],kvs[3]);
				}
			}
			if (StrContains(line,"\"origin\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),"%s",line);
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
				Format(tmpchar,sizeof(tmpchar),"%s",line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"angles\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				char origch[16][16];
				ExplodeString(tmpchar," ",origch,16,16);
				angs[0] = StringToFloat(origch[0]);
				angs[1] = StringToFloat(origch[1]);
				angs[2] = StringToFloat(origch[2]);
			}
			if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false) || (StrEqual(line,"}{",false))) && (ent == -1))
			{
				int iFindCls = FindStringInArray(passedarr,"classname");
				if (iFindCls != -1)
				{
					char tmpchar[128];
					iFindCls++;
					GetArrayString(passedarr,iFindCls,tmpchar,sizeof(tmpchar));
					if (StrEqual(tmpchar,"npc_template_maker",false))
					{
						Handle dupearr = CloneArray(passedarr);
						if (hTemplateData == INVALID_HANDLE) hTemplateData = CreateArray(1024);
						PushArrayCell(hTemplateData,dupearr);
						storetemplate = false;
					}
				}
				if (storetemplate)
				{
					int findtemplatename = FindStringInArray(passedarr,"TemplateName");
					if (findtemplatename != -1)
					{
						char tmpchar[128];
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
								else if ((StrEqual(arrchk,"MaxNPCCount",false)) || (StrEqual(arrchk,"SpawnFrequency",false)) || (StrEqual(arrchk,"MaxLiveChildren",false)) || (StrEqual(arrchk,"Radius",false)))
								{
									int findoutarr = i+1;
									char maxnpc[128];
									GetArrayString(passedarr,findoutarr,maxnpc,sizeof(maxnpc));
									DispatchKeyValue(pttemplate,arrchk,maxnpc);
								}
							}
							DispatchSpawn(pttemplate);
							ActivateEntity(pttemplate);
							fileorigin[0]+=offsetpos[0];
							fileorigin[1]+=offsetpos[1];
							fileorigin[2]+=offsetpos[2];
							TeleportEntity(pttemplate,fileorigin,angs,NULL_VECTOR);
							PushArrayCell(templateslist,pttemplate);
							customents = true;
							int findradius = FindStringInArray(passedarr,"TemplateName");
							if ((findradius != -1) && (HasEntProp(pttemplate,Prop_Data,"m_flRadius")))
							{
								char radiusch[16];
								findradius++;
								GetArrayString(passedarr,findradius,radiusch,sizeof(radiusch));
								SetEntPropFloat(pttemplate,Prop_Data,"m_flRadius",StringToFloat(radiusch));
							}
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
				char cls[64];
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
						Format(cls,sizeof(cls),"npc_headcrab");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/headcrab.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/headcrab.mdl");
					}
					else if ((StrEqual(cls,"monster_scientist",false)) || (StrEqual(cls,"monster_scientist_dead",false)))
					{
						if (FindStringInArray(precachedarr,"monster_scientist") == -1)
						{
							char sndchk[128];
							Format(sndchk,sizeof(sndchk),"sound/scientist/");
							recursion(sndchk);
							PushArrayString(precachedarr,"monster_scientist");
						}
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
						PushArrayString(passedarr,"body");
						char randbody[4];
						Format(randbody,sizeof(randbody),"%i",GetRandomInt(0,6));
						PushArrayString(passedarr,randbody);
						createsit = true;
					}
					else if ((StrEqual(cls,"monster_barney",false)) || (StrEqual(cls,"monster_barney_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/barney.mdl");
					}
					else if (StrEqual(cls,"monster_ichthyosaur",false))
					{
						Format(cls,sizeof(cls),"npc_ichthyosaur");
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
						Format(cls,sizeof(cls),"npc_antlion");
					}
					else if (StrEqual(cls,"monster_barnacle",false))
					{
						Format(cls,sizeof(cls),"npc_barnacle");
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
						Format(cls,sizeof(cls),"npc_antlion");
					}
					else if (StrEqual(cls,"trigger_auto",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Trigger,,1,1");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Kill,,1.5,1");
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
							//if (StrEqual(addweap,"default",false)) Format(cls,sizeof(cls),"generic_actor");
							//else
							//{
							Format(cls,sizeof(cls),"npc_citizen");
							PushArrayString(passedarr,"CitizenType");
							PushArrayString(passedarr,"4");
							//dp = CreateDataPack();
							//WritePackString(dp,"models/humans/guard.mdl");
							//}
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
						if (!relsetsec)
						{
							setuprelations("npc_human_security");
							relsetsec = true;
						}
					}
					else if (StrEqual(cls,"npc_scientist",false))
					{
						PushArrayString(passedarr,"model");
						char mdlset[128];
						Format(mdlset,sizeof(mdlset),"models/humans/group02/male_0%i.mdl",GetRandomInt(2,9));
						PushArrayString(passedarr,mdlset);
						/*
						if (!relsetscidef)
						{
							setuprelations("npc_scientist");
							relsetscidef = true;
						}
						*/
						Format(cls,sizeof(cls),"npc_citizen");
						PushArrayString(passedarr,"CitizenType");
						PushArrayString(passedarr,"4");
					}
					else if (StrEqual(cls,"npc_human_scientist",false))
					{
						PushArrayString(passedarr,"model");
						char mdlset[128];
						int rand = GetRandomInt(0,1);
						if (rand == 0) Format(mdlset,sizeof(mdlset),"models/humans/scientist.mdl");
						else Format(mdlset,sizeof(mdlset),"models/humans/scientist_02.mdl");
						PushArrayString(passedarr,mdlset);
						int findskin = FindStringInArray(passedarr,"skin");
						if (findskin == -1)
						{
							char randskin[4];
							Format(randskin,sizeof(randskin),"%i",GetRandomInt(0,14));
							PushArrayString(passedarr,"skin");
							PushArrayString(passedarr,randskin);
						}
						if (!relsetsci)
						{
							setuprelations("npc_human_scientist");
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
						int findskin = FindStringInArray(passedarr,"skin");
						if (findskin == -1)
						{
							char randskin[4];
							Format(randskin,sizeof(randskin),"%i",GetRandomInt(0,6));
							PushArrayString(passedarr,"skin");
							PushArrayString(passedarr,randskin);
						}
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
							setuprelations("npc_alien_slave");
							relsetvort = true;
						}
					}
					else if (StrEqual(cls,"npc_alien_controller",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/controller.mdl");
						if (!relsetvort)
						{
							setuprelations("npc_alien_slave");
							relsetvort = true;
						}
					}
					else if (StrEqual(cls,"npc_human_scientist_kleiner",false))
					{
						Format(cls,sizeof(cls),"npc_kleiner");
						if (FileExists("models/kleinerbms.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/kleinerbms.mdl");
						}
						/*
						if (!IsModelPrecached("models/kleiner.mdl"))
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/humans/scientist_kliener.mdl");
						}
						else
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/kleiner.mdl");
						}
						*/
						//Model invisible?
					}
					else if (StrEqual(cls,"npc_human_scientist_eli",false))
					{
						Format(cls,sizeof(cls),"npc_eli");
						if (FileExists("models/elibms.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/elibms.mdl");
						}
						/*
						if (!IsModelPrecached("models/eli.mdl"))
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/humans/scientist_kliener.mdl");
						}
						else
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/eli.mdl");
						}
						*/
					}
					else if (StrEqual(cls,"npc_zombie_security_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/zombie/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
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
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/zombie/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						Handle cvarchk = FindConVar("sk_zombie_soldier_health");
						if (GetConVarInt(cvarchk) < 6) SetConVarInt(cvarchk,100,false,false);
						CloseHandle(cvarchk);
						if (!relsetzsec)
						{
							setuprelations("npc_zombie_security");
							relsetzsec = true;
						}
						PushArrayString(passedarr,"model");
						dp = CreateDataPack();
						if (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"models/zombie/zsecurity.mdl");
							WritePackString(dp,"models/zombie/zsecurity.mdl");
						}
						else
						{
							PushArrayString(passedarr,"models/zombies/zombie_guard.mdl");
							WritePackString(dp,"models/zombies/zombie_guard.mdl");
						}
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_scientist_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombie_torso");
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/zombie/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombies/zombie_sci_torso.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_sci_torso.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_scientist",false))
					{
						Format(cls,sizeof(cls),"npc_zombie");
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/zombie/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						if (!relsetzsec)
						{
							setuprelations("npc_zombie_scientist");
							relsetzsec = true;
						}
						PushArrayString(passedarr,"model");
						if (FileExists("models/HDTF/characters/zombies/scientist_zombie.mdl",true,NULL_STRING)) PushArrayString(passedarr,"models/HDTF/characters/zombies/scientist_zombie.mdl");
						else PushArrayString(passedarr,"models/zombies/zombie_sci.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombies/zombie_sci.mdl");
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_worker",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/zombie_new/zombie_worker.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/zombie_new/zombie_worker.mdl");
					}
					else if ((StrEqual(cls,"npc_human_grunt",false)) || (StrEqual(cls,"npc_human_commander",false)) || (StrEqual(cls,"npc_human_grenadier",false)) || (StrEqual(cls,"npc_human_medic",false)))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/marine.mdl");
						Format(setupent,sizeof(setupent),"marine");
					}
					else if (StrEqual(cls,"npc_human_assassin",false))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/humans/hassassin.mdl");
					}
					else if (StrEqual(cls,"monster_human_assassin",false))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/hassassin.mdl");
					}
					else if (StrEqual(cls,"npc_assassin",false))
					{
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/_monsters/combine/assassin.mdl");
					}
					else if (StrEqual(cls,"npc_odell",false))
					{
						Format(cls,sizeof(cls),"npc_citizen");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/_characters/odell.mdl");
						PushArrayString(passedarr,"CitizenType");
						PushArrayString(passedarr,"4");
						//dp = CreateDataPack();
						//WritePackString(dp,"models/_characters/odell.mdl");
					}
					else if (StrEqual(cls,"npc_osprey",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/osprey.mdl");
						//dp = CreateDataPack();
						//WritePackString(dp,"models/props_vehicles/osprey.mdl");
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
					}
					else if (StrEqual(cls,"npc_bullsquid",false))
					{
						Format(cls,sizeof(cls),"npc_antlion");
					}
					else if (StrEqual(cls,"npc_sentry_ceiling",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/NPCs/sentry_ceiling.mdl");
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							PrecacheSound("weapons\\mp5\\empty.wav",true);
							recursion("sound/npc/sentry_ceiling/");
							PushArrayString(precachedarr,cls);
						}
					}
					else if (StrEqual(cls,"npc_sentry_ground",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/NPCs/sentry_ground.mdl");
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							PrecacheSound("weapons\\mp5\\empty.wav",true);
							recursion("sound/npc/sentry_ground/");
							PushArrayString(precachedarr,cls);
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
						Format(cls,sizeof(cls),"npc_maker");
					}
					else if (StrEqual(cls,"env_mortar_launcher",false))
					{
						Format(cls,sizeof(cls),"info_target");
					}
					else if (StrEqual(cls,"env_mortar_controller",false))
					{
						Format(cls,sizeof(cls),"prop_physics_override");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_st/airstrike_map.mdl");
						PushArrayString(passedarr,"spawnflags");
						PushArrayString(passedarr,"264");
					}
					else if (StrEqual(cls,"multi_manager",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
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
						Format(cls,sizeof(cls),"prop_dynamic_override");
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
					else if ((StrEqual(cls,"item_weapon_satchel",false)) || (StrEqual(cls,"item_weapon_tripmine",false)))
					{
						if (StrContains(cls,"item_weapon_",false) == 0)
						{
							int find = FindStringInArray(passedarr,"classname");
							if (find != -1)
							{
								RemoveFromArray(passedarr,find);
								find++;
								RemoveFromArray(passedarr,find);
							}
							ReplaceStringEx(cls,sizeof(cls),"item_","");
							PushArrayString(passedarr,"classname");
							PushArrayString(passedarr,cls);
						}
						Format(cls,sizeof(cls),"weapon_slam");
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
					else if (StrEqual(cls,"item_weapon_shotgun",false))
					{
						Format(cls,sizeof(cls),"weapon_shotgun");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if ((StrEqual(cls,"item_weapon_glock",false)) || (StrEqual(cls,"weapon_glock",false)))
					{
						Format(cls,sizeof(cls),"weapon_pistol");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"classname");
						PushArrayString(passedarr,"weapon_glock");
					}
					else if (StrEqual(cls,"item_ammo_mp5",false))
					{
						Format(cls,sizeof(cls),"item_ammo_smg1");
						if (FileExists("models/weapons/w_9mmarclip.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/weapons/w_9mmarclip.mdl");
						}
					}
					else if (StrEqual(cls,"item_grenade_mp5",false))
					{
						Format(cls,sizeof(cls),"item_ammo_smg1_grenade");
						if (FileExists("models/weapons/w_argrenade.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/weapons/w_argrenade.mdl");
						}
					}
					else if (StrEqual(cls,"item_ammo_shotgun",false))
					{
						Format(cls,sizeof(cls),"item_box_buckshot");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"item_ammo_glock",false))
					{
						Format(cls,sizeof(cls),"item_ammo_smg1");
						if (FileExists("models/weapons/w_9mmclip.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/weapons/w_9mmclip.mdl");
						}
					}
					else if (StrEqual(cls,"item_longjump",false))
					{
						Format(cls,sizeof(cls),"item_healthkit");
					}
					else if (StrEqual(cls,"weapon_immolator",false))
					{
						Format(cls,sizeof(cls),"weapon_shotgun");
					}
					else if ((StrEqual(cls,"weapon_pistol_worker",false)) || (StrEqual(cls,"weapon_flaregun",false)))
					{
						Format(cls,sizeof(cls),"weapon_pistol");
					}
					else if ((StrEqual(cls,"weapon_medkit",false)) || (StrEqual(cls,"weapon_healer",false)) || (StrEqual(cls,"weapon_camera",false)) || (StrEqual(cls,"weapon_molotov",false)))
					{
						Format(cls,sizeof(cls),"weapon_slam");
					}
					else if ((StrEqual(cls,"weapon_manhack",false)) || (StrEqual(cls,"weapon_manhacktoss",false)))
					{
						Format(cls,sizeof(cls),"weapon_pistol");
					}
					else if ((StrEqual(cls,"weapon_gluon",false)) || (StrEqual(cls,"weapon_goop",false)))
					{
						Format(cls,sizeof(cls),"weapon_shotgun");
					}
					else if ((StrEqual(cls,"weapon_pistol1",false)) || (StrEqual(cls,"weapon_pistol2",false)) || (StrEqual(cls,"weapon_isa_knife",false)) || (StrEqual(cls,"weapon_ls13",false)) || (StrEqual(cls,"weapon_lugergun",false)) || (StrEqual(cls,"weapon_rifle1",false)) || (StrEqual(cls,"weapon_smg3",false)) || (StrEqual(cls,"weapon_smg4",false)) || (StrEqual(cls,"weapon_vc32sniperrifle",false)))
					{
						Format(cls,sizeof(cls),"kzsmodifiedweaps/%s",cls);
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"classname");
						PushArrayString(passedarr,cls);
						if ((StrEqual(cls,"kzsmodifiedweaps/weapon_pistol1",false)) || (StrEqual(cls,"kzsmodifiedweaps/weapon_pistol2",false))) Format(cls,sizeof(cls),"weapon_pistol");
						else if (StrEqual(cls,"kzsmodifiedweaps/weapon_isa_knife",false)) Format(cls,sizeof(cls),"weapon_crowbar");
						else if (StrEqual(cls,"kzsmodifiedweaps/weapon_ls13",false)) Format(cls,sizeof(cls),"weapon_shotgun");
						else if ((StrEqual(cls,"kzsmodifiedweaps/weapon_lugergun",false)) || (StrEqual(cls,"kzsmodifiedweaps/weapon_smg3",false)) || (StrEqual(cls,"kzsmodifiedweaps/weapon_smg4",false)) || (StrEqual(cls,"kzsmodifiedweaps/weapon_vc32sniperrifle",false))) Format(cls,sizeof(cls),"weapon_smg1");
					}
					else if (StrEqual(cls,"item_weapon_gluon",false))
					{
						Format(cls,sizeof(cls),"prop_physics_override");
						PushArrayString(passedarr,"spawnflags");
						PushArrayString(passedarr,"256");
						if (FileExists("models/weapons/w_egon_pickup.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"model");
							PushArrayString(passedarr,"models/weapons/w_egon_pickup.mdl");
						}
					}
					else if (StrEqual(cls,"item_ammo_energy",false))
					{
						Format(cls,sizeof(cls),"item_ammo_smg1");
						if (FileExists("models/weapons/w_gaussammo.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/weapons/w_gaussammo.mdl");
						}
						else if (FileExists("models/w_gaussammo.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/w_gaussammo.mdl");
						}
					}
					else if ((StrEqual(cls,"weapon_gauss",false)) || (StrEqual(cls,"weapon_tau",false)) || (StrEqual(cls,"item_weapon_tau",false)) || (StrEqual(cls,"weapon_sniperrifle",false)) || (StrEqual(cls,"weapon_bhg",false)))
					{
						if (StrContains(cls,"item_weapon_",false) == 0)
						{
							int find = FindStringInArray(passedarr,"classname");
							if (find != -1)
							{
								RemoveFromArray(passedarr,find);
								find++;
								RemoveFromArray(passedarr,find);
							}
							ReplaceStringEx(cls,sizeof(cls),"item_","");
							PushArrayString(passedarr,"classname");
							PushArrayString(passedarr,cls);
						}
						Format(cls,sizeof(cls),"weapon_ar2");
					}
					else if ((StrEqual(cls,"weapon_snark",false)) || (StrEqual(cls,"weapon_hivehand",false)) || (StrEqual(cls,"item_weapon_tripmine",false)) || (StrEqual(cls,"item_weapon_snark",false)) || (StrEqual(cls,"item_weapon_hivehand",false)))
					{
						if (StrContains(cls,"item_weapon_",false) == 0)
						{
							int find = FindStringInArray(passedarr,"classname");
							if (find != -1)
							{
								RemoveFromArray(passedarr,find);
								find++;
								RemoveFromArray(passedarr,find);
							}
							ReplaceStringEx(cls,sizeof(cls),"item_","");
							PushArrayString(passedarr,"classname");
							PushArrayString(passedarr,cls);
						}
						Format(cls,sizeof(cls),"weapon_slam");
					}
					else if ((StrEqual(cls,"weapon_mp5",false)) || (StrEqual(cls,"item_weapon_mp5",false)) || (StrEqual(cls,"weapon_m4",false)) || (StrEqual(cls,"weapon_oicw",false)) || (StrEqual(cls,"weapon_sl8",false)) || (StrEqual(cls,"weapon_uzi",false)) || (StrEqual(cls,"weapon_camera",false)))
					{
						if (StrContains(cls,"item_",false) == 0)
						{
							int find = FindStringInArray(passedarr,"classname");
							if (find != -1)
							{
								RemoveFromArray(passedarr,find);
								find++;
								RemoveFromArray(passedarr,find);
							}
							ReplaceStringEx(cls,sizeof(cls),"item_","");
							PushArrayString(passedarr,"classname");
							PushArrayString(passedarr,cls);
						}
						Format(cls,sizeof(cls),"weapon_smg1");
					}
					else if ((StrEqual(cls,"item_ammo_flare_box",false)) || (StrEqual(cls,"item_box_flare_rounds",false)))
					{
						Format(cls,sizeof(cls),"item_ammo_pistol");
						dp = CreateDataPack();
						if (FileExists("models/_weapons/flarebox.mdl",true,NULL_STRING)) WritePackString(dp,"models/_weapons/flarebox.mdl");
						else WritePackString(dp,"models/items/boxflares.mdl");
					}
					else if (StrEqual(cls,"item_custom",false))
					{
						Format(cls,sizeof(cls),"item_ammo_smg1");
					}
					else if (StrEqual(cls,"ladder_useable",false))
					{
						Format(cls,sizeof(cls),"func_useableladder");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
					}
					else if (StrEqual(cls,"ladder_dismount",false))
					{
						Format(cls,sizeof(cls),"info_ladder_dismount");
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
							setuprelations("npc_alien_grunt");
							relsetvort = true;
						}
						Format(setupent,sizeof(setupent),"agrunt");
					}
					else if (StrEqual(cls,"monster_alien_grunt",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/npc/agrunt/");
							recursion(searchprecache);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"npc_combine_s");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/agrunt.mdl");
						if (!relsetvort)
						{
							setuprelations("monster_alien_grunt");
							relsetvort = true;
						}
						Format(setupent,sizeof(setupent),"agrunt");
					}
					else if (StrEqual(cls,"monster_gargantua",false))
					{
						Format(cls,sizeof(cls),"npc_gargantua");
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
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/abrams.mdl");
						if (!relsetabram)
						{
							setuprelations("npc_abrams");
							relsetabram = true;
						}
					}
					else if (StrEqual(cls,"npc_apache",false))
					{
						Format(cls,sizeof(cls),"npc_helicopter");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/apache.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/props_vehicles/apache.mdl");
					}
					else if (StrEqual(cls,"npc_gonarch",false))
					{
						Format(cls,sizeof(cls),"npc_zombine");
						PushArrayString(passedarr,"model");
						dp = CreateDataPack();
						if (FileExists("models/xenians/gonarch.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"models/xenians/gonarch.mdl");
							WritePackString(dp,"models/xenians/gonarch.mdl");
						}
						else
						{
							PushArrayString(passedarr,"models/gonarch.mdl");
							WritePackString(dp,"models/gonarch.mdl");
						}
					}
					else if (StrEqual(cls,"npc_babycrab",false))
					{
						Format(cls,sizeof(cls),"npc_headcrab");
						PushArrayString(passedarr,"model");
						dp = CreateDataPack();
						if (FileExists("models/xenians/babyheadcrab.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"models/xenians/babyheadcrab.mdl");
							WritePackString(dp,"models/xenians/babyheadcrab.mdl");
						}
						else
						{
							PushArrayString(passedarr,"models/xenians/headcrab.mdl");
							WritePackString(dp,"models/xenians/headcrab.mdl");
						}
					}
					else if (StrEqual(cls,"npc_bmsgargantua",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/garg.mdl");
					}
					else if (StrEqual(cls,"npc_synth_scanner",false))
					{
						Format(cls,sizeof(cls),"npc_cscanner");
						dp = CreateDataPack();
						WritePackString(dp,"models/_monsters/combine/synth_scanner.mdl");
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
					else if (StrEqual(cls,"prop_surgerybot",false))
					{
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_questionableethics/qe_surgery_bot_main.mdl");
						PushArrayString(passedarr,"DefaultAnim");
						PushArrayString(passedarr,"active");
						PushArrayString(passedarr,"Solid");
						PushArrayString(passedarr,"6");
						Format(cls,sizeof(cls),"prop_dynamic");
					}
					else if (StrEqual(cls,"env_xen_pushpad",false))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							PrecacheSound("BMS_objects\\xenpushpad\\jumppad1.wav",true);
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"prop_dynamic");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/xenians/jump_pad.mdl");
						PushArrayString(passedarr,"solid");
						PushArrayString(passedarr,"2");
						PushArrayString(passedarr,"DefaultAnim");
						PushArrayString(passedarr,"idle01");
					}
					else if (StrEqual(cls,"env_dispenser",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
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
						PushArrayString(passedarr,"ResponseContext");
						PushArrayString(passedarr,"func_minefield;");
					}
					else if ((StrEqual(cls,"func_50cal",false)) || (StrEqual(cls,"func_tow",false)))
					{
						if (FindStringInArray(precachedarr,cls) == -1)
						{
							recursion("sound/weapons/50cal/");
							recursion("sound/weapons/tow/");
							PushArrayString(precachedarr,cls);
						}
						Format(cls,sizeof(cls),"func_tank");
					}
					else if ((StrEqual(cls,"info_player_rebel",false)) || (StrEqual(cls,"info_player_combine",false)) || (StrEqual(cls,"info_player_deathmatch",false)))
					{
						Format(cls,sizeof(cls),"info_player_coop");
					}
					else if (StrEqual(cls,"game_player_equip",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						Format(cls,sizeof(cls),"info_player_equip");
					}
					else if ((StrEqual(cls,"trigger_once_oc",false)) || (StrEqual(cls,"trigger_multiple_oc",false)))
					{
						ReplaceString(cls,sizeof(cls),"_oc","");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"classname");
						PushArrayString(passedarr,cls);
					}
					else if (StrEqual(cls,"game_text_quick",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"spawnflags");
						PushArrayString(passedarr,"1");
						Format(cls,sizeof(cls),"game_text");
					}
					else if (StrEqual(cls,"point_message_multiplayer",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"developeronly");
						PushArrayString(passedarr,"0");
						Format(cls,sizeof(cls),"point_message");
					}
					else if (StrEqual(cls,"weapon_scripted",false))
					{
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						find = FindStringInArray(passedarr,"customweaponscript");
						if (find != -1)
						{
							find++;
							char scr[128];
							GetArrayString(passedarr,find,scr,sizeof(scr));
							if (strlen(scr) > 0)
							{
								char readscr[64];
								Format(readscr,sizeof(readscr),"scripts/customweapons/%s.txt",scr);
								Format(oldcls,sizeof(oldcls),"customweapons/%s",scr);
								PushArrayString(passedarr,"classname");
								PushArrayString(passedarr,oldcls);
								if (FileExists(readscr,true,NULL_STRING))
								{
									Handle filehandlesub = OpenFile(readscr,"r",true,NULL_STRING);
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
												else if (StrEqual(scrline,"grenade",false)) Format(scrline,sizeof(scrline),"crowbar");
												Format(scrline,sizeof(scrline),"weapon_%s",scrline);
												//PrintToServer("AnimPrefix %s",scrline);
												Format(cls,sizeof(cls),"%s",scrline);
												break;
											}
										}
									}
									CloseHandle(filehandlesub);
									PushArrayString(passedarr,"ResponseContext");
									PushArrayString(passedarr,cls);
								}
							}
						}
						else Format(cls,sizeof(cls),"weapon_smg1");
					}
					else if (StrEqual(cls,"logic_merchant_relay",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
					}
					else if (StrEqual(cls,"logic_player_branch",false))
					{
						Format(cls,sizeof(cls),"math_counter");
					}
					else if (StrEqual(cls,"game_countdown_timer",false))
					{
						Format(cls,sizeof(cls),"hud_timer");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"TimerType");
						PushArrayString(passedarr,"1");
					}
					else if ((StrEqual(cls,"hlss_camera_output",false)) || (StrEqual(cls,"hlss_weaponstripper",false)))
					{
						Format(cls,sizeof(cls),"logic_relay");
					}
					else if (StrEqual(cls,"point_energy_ball_launcher",false))
					{
						Format(cls,sizeof(cls),"point_combine_ball_launcher");
						int find = FindStringInArray(passedarr,"classname");
						if (find != -1)
						{
							RemoveFromArray(passedarr,find);
							find++;
							RemoveFromArray(passedarr,find);
						}
						PushArrayString(passedarr,"maxballbounces");
						PushArrayString(passedarr,"8");
					}
					else if (StrEqual(cls,"npc_merchant",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
					}
					ent = CreateEntityByName(cls);
					if (StrEqual(setupent,"zombie"))
					{
						SDKHookEx(ent,SDKHook_Think,zomthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
					}
					else if (StrEqual(setupent,"marine"))
					{
						//PushArrayCell(nextweapreset,ent+1);
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
						else SDKHookEx(ent,SDKHook_Think,hgruntthink);
						AcceptEntityInput(ent,"GagEnable");
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
						SetEntPropEnt(entmdl,Prop_Data,"m_hOwnerEntity",ent);
						int entsnd = CreateEntityByName("ambient_generic");
						DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
						DispatchSpawn(entsnd);
						ActivateEntity(entsnd);
						SetVariantString("!activator");
						AcceptEntityInput(entsnd,"SetParent",entmdl);
						SetVariantString("Eye");
						AcceptEntityInput(entsnd,"SetParentAttachment");
						SetEntPropEnt(entmdl,Prop_Data,"m_hEffectEntity",entsnd);
						PushArrayCell(tentssnd,entsnd);
						SDKHookEx(ent,SDKHook_Think,tentaclethink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,tentacletkdmg);
						HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
					}
					else if (StrEqual(setupent,"agrunt"))
					{
						AcceptEntityInput(ent,"GagEnable");
						SDKHookEx(ent,SDKHook_Think,agruntthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,agrunttkdmg);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
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
						HookSingleEntityOutput(ent,"OnBreak",centcratebreak);
					}
					customents = true;
					if (debuglvl > 1) PrintToConsole(client,"Created %s Ent as %s",oldcls,cls);
					if (FindValueInArray(entlist,ent) == -1)
						PushArrayCell(entlist,ent);
					if (dp != INVALID_HANDLE)
					{
						WritePackCell(dp,ent);
						WritePackString(dp,oldcls);
						CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						CloseHandle(dp);
						dp = INVALID_HANDLE;
						CreateTimer(0.1,resethealth,ent,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				if ((StrEqual(line,"}",false)) || (StrEqual(line,"}{",false)))
				{
					int findbase = FindStringInArray(passedarr,"baseclass");
					if (findbase != -1)
					{
						findbase++;
						GetArrayString(passedarr,findbase,cls,sizeof(cls));
						AcceptEntityInput(ent,"kill");
						if (debuglvl > 1) PrintToConsole(client,"Reset %s Ent as %s",oldcls,cls);
						ent = CreateEntityByName(cls);
						if (StrEqual(cls,"npc_citizen",false))
						{
							DispatchKeyValue(ent,"CitizenType","4");
						}
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
					}
					if (StrEqual(oldcls,"env_xen_portal_template",false))
					{
						int findtn = FindStringInArray(passedarr,"TemplateName");
						if (findtn != -1)
						{
							findtn++;
							char templatetn[128];
							GetArrayString(passedarr,findtn,templatetn,sizeof(templatetn));
							Format(templatetn,sizeof(templatetn),"pttemplate%s",templatetn);
							DispatchKeyValue(ent,"NPCType","npc_headcrab");
							DispatchKeyValue(ent,"NPCTargetname",templatetn);
						}
						PushArrayCell(templateslist,ent);
					}
					else if (StrEqual(oldcls,"item_longjump",false))
					{
						for (int k = 0;k<GetArraySize(passedarr);k++)
						{
							char ktmp[128];
							char ktmp2[128];
							GetArrayString(passedarr, k, ktmp, sizeof(ktmp));
							k++;
							GetArrayString(passedarr, k, ktmp2, sizeof(ktmp2));
							if (StrEqual(ktmp,"OnPlayerPickup",false))
							{
								Format(ktmp,sizeof(ktmp),"OnCacheInteraction");
								DispatchKeyValue(ent,ktmp,ktmp2);
							}
						}
					}
					else if (StrEqual(oldcls,"item_custom",false))
					{
						int ammtype = FindStringInArray(passedarr,"AmmoName");
						if (ammtype != -1)
						{
							ammtype++;
							GetArrayString(passedarr,ammtype,cls,sizeof(cls));
							int findcls = FindStringInArray(passedarr,"classname");
							if (findcls != -1)
							{
								RemoveFromArray(passedarr,findcls);
								findcls++;
								RemoveFromArray(passedarr,findcls);
							}
							DispatchKeyValue(ent,"classname",cls);
							int findmdl = FindStringInArray(passedarr,"model");
							if (findmdl != -1)
							{
								char mdlfind[64];
								findmdl++;
								GetArrayString(passedarr,findmdl,mdlfind,sizeof(mdlfind));
								Handle dp = CreateDataPack();
								WritePackString(dp,mdlfind);
								WritePackCell(dp,ent);
								WritePackString(dp,cls);
								CreateTimer(1.0,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
					else if (StrEqual(oldcls,"point_message_multiplayer",false))
					{
						//Still doesn't work. Will only show to cl 0
						//CBasePlayer *pPlayer = UTIL_GetLocalPlayer();
						if (HasEntProp(ent,Prop_Data,"m_bDeveloperOnly")) SetEntProp(ent,Prop_Data,"m_bDeveloperOnly",0);
						if (HasEntProp(ent,Prop_Data,"m_drawText")) SetEntProp(ent,Prop_Data,"m_drawText",1);
					}
					else if (StrEqual(oldcls,"logic_merchant_relay",false))
					{
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char arrstart[64];
							char arrnext[128];
							GetArrayString(passedarr,i,arrstart,sizeof(arrstart));
							i++;
							if (i < GetArraySize(passedarr)) GetArrayString(passedarr,i,arrnext,sizeof(arrnext));
							i+=2;
							if (StrEqual(arrstart,"IsShared",false)) SetEntProp(ent,Prop_Data,"m_bInvulnerable",StringToInt(arrnext));
							else if (StrEqual(arrstart,"AnnounceCashNeeded",false)) SetEntPropFloat(ent,Prop_Data,"m_flSpeed",StringToFloat(arrnext));
							else if (StrEqual(arrstart,"purchasesound",false)) SetEntPropString(ent,Prop_Data,"m_iszResponseContext",arrnext);
							else if (StrEqual(arrstart,"CostOf",false)) SetEntProp(ent,Prop_Data,"m_iHealth",StringToInt(arrnext));
							else if (StrEqual(arrstart,"MaxPointsTake",false)) SetEntProp(ent,Prop_Data,"m_iMaxHealth",StringToInt(arrnext));
							else if (StrEqual(arrstart,"PurchaseName",false)) SetEntPropString(ent,Prop_Data,"m_target",arrnext);
							else if (StrEqual(arrstart,"OnPurchased",false)) DispatchKeyValue(ent,"OnUser1",arrnext);
							else if (StrEqual(arrstart,"OnNotEnoughCash",false)) DispatchKeyValue(ent,"OnUser2",arrnext);
							else if (StrEqual(arrstart,"OnCashReduced",false)) DispatchKeyValue(ent,"OnUser3",arrnext);
							else if (StrEqual(arrstart,"OnDisabled",false)) DispatchKeyValue(ent,"OnUser4",arrnext);
							HookSingleEntityOutput(ent,"OnUser1",LogMerchPurchased);
							HookSingleEntityOutput(ent,"OnUser2",LogMerchNotEnough);
							HookSingleEntityOutput(ent,"OnUser3",LogMerchCashReduced);
							HookSingleEntityOutput(ent,"OnUser4",LogMerchDisabled);
						}
					}
					else if (StrEqual(oldcls,"logic_player_branch",false))
					{
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char arrstart[64];
							char arrnext[128];
							GetArrayString(passedarr,i,arrstart,sizeof(arrstart));
							i++;
							GetArrayString(passedarr,i,arrnext,sizeof(arrnext));
							if (StrEqual(arrstart,"InitialValue",false))
							{
								PushArrayString(passedarr,"max");
								PushArrayString(passedarr,arrnext);
							}
							else if (StrEqual(arrstart,"OnTrue",false))
							{
								PushArrayString(passedarr,"OnHitMax");
								PushArrayString(passedarr,arrnext);
							}
						}
					}
					else if (StrEqual(oldcls,"npc_merchant",false))
					{
						bool foundmdl = false;
						char merchicon[64];
						if (FileExists("materials/sprites/merchant_buy.vmt",true,NULL_STRING)) Format(merchicon,sizeof(merchicon),"sprites/merchant_buy.vmt");
						else Format(merchicon,sizeof(merchicon),"sprites/merchant_buysyn.vmt");
						int starticonon = 1;
						float posabove = 80.0;
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char arrstart[64];
							char arrnext[128];
							GetArrayString(passedarr,i,arrstart,sizeof(arrstart));
							if (StrEqual(arrstart,"model",false)) foundmdl = true;
							i++;
							GetArrayString(passedarr,i,arrnext,sizeof(arrnext));
							if (StrEqual(arrstart,"MerchantScript",false)) DispatchKeyValue(ent,"ResponseContext",arrnext);
							else if (StrEqual(arrstart,"MerchantIconMaterial",false)) Format(merchicon,sizeof(merchicon),"%s",arrnext);
							else if (StrEqual(arrstart,"ShowIcon",false)) starticonon = StringToInt(arrnext);
							else if (StrEqual(arrstart,"IconHeight",false)) posabove = StringToFloat(arrnext);
							else if (StrEqual(arrstart,"OnPlayerUse",false)) DispatchKeyValue(ent,"OnUser1",arrnext);
							else if (StrEqual(arrstart,"MerchantSound",false))
							{
								if (HasEntProp(ent,Prop_Data,"m_initialDelay")) SetEntPropFloat(ent,Prop_Data,"m_initialDelay",StringToFloat(arrnext));
							}
						}
						if (!foundmdl)
						{
							DispatchKeyValue(ent,"model","models/humans/group01/male_01.mdl");
						}
						DispatchKeyValue(ent,"citizentype","4");
						SetEntProp(ent,Prop_Data,"m_bInvulnerable",1);
						if (HasEntProp(ent,Prop_Data,"m_takedamage")) SetEntProp(ent,Prop_Data,"m_takedamage",0);
						char merchiconfull[72];
						Format(merchiconfull,sizeof(merchiconfull),"materials/%s",merchicon);
						if (FileExists(merchiconfull,true,NULL_STRING))
						{
							int sprite = CreateEntityByName("env_sprite");
							if (sprite != -1)
							{
								DispatchKeyValue(sprite,"model",merchicon);
								DispatchKeyValue(sprite,"framerate","1");
								DispatchKeyValue(sprite,"RenderMode","5");
								DispatchKeyValue(sprite,"scale","0.5");
								if (starticonon) DispatchKeyValue(sprite,"spawnflags","1");
								else DispatchKeyValue(sprite,"spawnflags","0");
								float startpos[3];
								startpos[0] = fileorigin[0];
								startpos[1] = fileorigin[1];
								startpos[2] = fileorigin[2]+posabove;
								TeleportEntity(sprite,startpos,NULL_VECTOR,NULL_VECTOR);
								DispatchSpawn(sprite);
								ActivateEntity(sprite);
								SetVariantString("!activator");
								AcceptEntityInput(sprite,"SetParent",ent);
							}
						}
						else PrintToServer("Merchant Icon \"%s\" not found",merchiconfull);
						HookSingleEntityOutput(ent,"OnUser1",MerchantUse);
						int flageffects = GetEntProp(ent,Prop_Data,"m_iEFlags");
						if (!(flageffects & 1<<30))
						{
							SetEntProp(ent,Prop_Data,"m_iEFlags",flageffects+1073741824);
						}
					}
					else if (StrEqual(oldcls,"game_player_equip",false))
					{
						AcceptEntityInput(ent,"kill");
						ent = CreateEntityByName("info_player_equip");
						if (ent != -1)
						{
							char response[128];
							for (int i = 0;i<GetArraySize(passedarr);i++)
							{
								bool nodispatch = false;
								char arrstart[64];
								char arrnext[128];
								GetArrayString(passedarr,i,arrstart,sizeof(arrstart));
								i++;
								GetArrayString(passedarr,i,arrnext,sizeof(arrnext));
								if (StrContains(arrstart,"item_ammo_",false) == 0)
								{
									ReplaceStringEx(arrstart,sizeof(arrstart),"item_ammo_","ammo_",-1,-1,false);
									if (StrContains(arrstart,"_large",false) == 0)
									{
										ReplaceStringEx(arrstart,sizeof(arrstart),"_large","",-1,-1,false);
										Format(arrnext,sizeof(arrnext),"90");
									}
								}
								else if (StrEqual(arrstart,"item_rpg_round",false))
								{
									Format(arrstart,sizeof(arrstart),"ammo_rpg");
									Format(arrnext,sizeof(arrnext),"1");
								}
								else if (StrEqual(arrstart,"item_box_buckshot",false))
								{
									Format(arrstart,sizeof(arrstart),"ammo_buckshot");
									Format(arrnext,sizeof(arrnext),"6");
								}
								else if (StrEqual(arrstart,"item_box_sniper_rounds",false))
								{
									Format(arrstart,sizeof(arrstart),"ammo_sniper_rounds");
									Format(arrnext,sizeof(arrnext),"10");
								}
								else if (StrContains(arrstart,"custom_",false) == 0)
								{
									if (strlen(response) < 2) Format(response,sizeof(response),"customweapons/%s",arrstart);
									else Format(response,sizeof(response),"%s customweapons/%s",response,arrstart);
									nodispatch = true;
								}
								else if ((StrEqual(arrstart,"weapon_uzi",false)) || (StrEqual(arrstart,"weapon_sniperrifle",false)) || (StrEqual(arrstart,"weapon_manhack",false)) || (StrEqual(arrstart,"weapon_guass",false)))
								{
									if (strlen(response) < 2) Format(response,sizeof(response),"%s",arrstart);
									else Format(response,sizeof(response),"%s %s",response,arrstart);
									nodispatch = true;
								}
								if (!nodispatch) DispatchKeyValue(ent,arrstart,arrnext);
							}
							if (strlen(response) > 0)
							{
								TrimString(response);
								DispatchKeyValue(ent,"ResponseContext",response);
							}
						}
					}
					else if (StrEqual(oldcls,"hlss_camera_output",false))
					{
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char arrstart[64];
							char arrnext[128];
							GetArrayString(passedarr,i,arrstart,sizeof(arrstart));
							i++;
							GetArrayString(passedarr,i,arrnext,sizeof(arrnext));
							if (StrEqual(arrstart,"OnPhotoTaken",false))
							{
								DispatchKeyValue(ent,"OnTrigger",arrnext);
							}
							else if (StrEqual(arrstart,"photo_target",false))
							{
								DispatchKeyValue(ent,"target",arrnext);
							}
							else if (StrEqual(arrstart,"enabled",false))
							{
								if (StringToInt(arrnext) > 0) DispatchKeyValue(ent,"StartDisabled","0");
								else DispatchKeyValue(ent,"StartDisabled","1");
							}
						}
					}
					else if (StrEqual(oldcls,"hlss_weaponstripper",false))
					{
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char arrstart[64];
							char arrnext[128];
							GetArrayString(passedarr,i,arrstart,sizeof(arrstart));
							i++;
							GetArrayString(passedarr,i,arrnext,sizeof(arrnext));
							if (StrEqual(arrstart,"AmmoRemoved",false))
							{
								DispatchKeyValue(ent,"OnUser1",arrnext);
							}
							else if (StrEqual(arrstart,"NoAmmo",false))
							{
								DispatchKeyValue(ent,"OnUser2",arrnext);
							}
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
					{
						fileorigin[0]+=offsetpos[0];
						fileorigin[1]+=offsetpos[1];
						fileorigin[2]+=offsetpos[2];
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					else
					{
						//PrintToServer("Created ent at %1.f %1.f %1.f offs %1.f %1.f %1.f",fileorigin[0],fileorigin[1],fileorigin[2],offsetpos[0],offsetpos[1],offsetpos[2]);
						fileorigin[0]+=offsetpos[0];
						fileorigin[1]+=offsetpos[1];
						fileorigin[2]+=offsetpos[2];
						TeleportEntity(ent,fileorigin,angs,NULL_VECTOR);
					}
					if (FindStringInArray(customentlist,oldcls) == -1)
					{
						//Attempting to create entity that is not on the list?
						AcceptEntityInput(ent,"kill");
					}
					if (StrContains(oldcls,"item_weapon_",false) == 0)
					{
						fileorigin[2]+=1.5;
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					if (StrEqual(oldcls,"npc_human_scientist",false))
					{
						SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
					}
					else if ((StrEqual(oldcls,"npc_sentry_ground",false)) || (StrEqual(oldcls,"npc_sentry_ceiling",false)))
					{
						int findsf = FindStringInArray(passedarr,"spawnflags");
						if (findsf != -1)
						{
							findsf++;
							char sfch[16];
							GetArrayString(passedarr,findsf,sfch,sizeof(sfch));
							int sf = StringToInt(sfch);
							if (sf & 1<<17)
							{
								AcceptEntityInput(ent,"Disable");
								SetEntProp(ent,Prop_Data,"m_bDisabled",1);
							}
							if (sf & 1<<9)
							{
								SetEntProp(ent,Prop_Data,"m_iAmmo",-10,0);
							}
							SetVariantString("spawnflags 32");
							AcceptEntityInput(ent,"AddOutput");
						}
						if (StrEqual(oldcls,"npc_sentry_ceiling",false))
						{
							if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
							if (HasEntProp(ent,Prop_Data,"m_MoveType")) SetEntProp(ent,Prop_Data,"m_MoveType",3);
							int mhchk = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
							Handle cvar = FindConVar("sk_sentry_ceiling_health");
							if (cvar != INVALID_HANDLE)
							{
								int cvarh = GetConVarInt(cvar);
								if (mhchk != cvarh)
								{
									SetEntProp(ent,Prop_Data,"m_iHealth",cvarh);
									SetEntProp(ent,Prop_Data,"m_iMaxHealth",cvarh);
								}
							}
							CloseHandle(cvar);
							SDKHookEx(ent,SDKHook_Think,sentriesthink);
							fileorigin[2]-=0.1;
							Handle dppass = CreateDataPack();
							WritePackCell(dppass,ent);
							WritePackFloat(dppass,fileorigin[0]);
							WritePackFloat(dppass,fileorigin[1]);
							WritePackFloat(dppass,fileorigin[2]);
							CreateTimer(0.1,resetorgs,dppass,TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (StrEqual(oldcls,"npc_sentry_ground",false))
						{
							if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
							if (HasEntProp(ent,Prop_Data,"m_MoveType")) SetEntProp(ent,Prop_Data,"m_MoveType",3);
							int mhchk = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
							Handle cvar = FindConVar("sk_sentry_ground_health");
							if (cvar != INVALID_HANDLE)
							{
								int cvarh = GetConVarInt(cvar);
								if (mhchk != cvarh)
								{
									SetEntProp(ent,Prop_Data,"m_iHealth",cvarh);
									SetEntProp(ent,Prop_Data,"m_iMaxHealth",cvarh);
								}
							}
							CloseHandle(cvar);
							if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
							SetVariantString("1.1");
							AcceptEntityInput(ent,"SetModelScale");
							float vecs[3];
							vecs[0] = 1.0;
							vecs[1] = 1.0;
							vecs[2] = 1.0;
							SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vecs);
							vecs[0] = -16.0;
							vecs[1] = -12.0;
							vecs[2] = -1.0;
							SetEntPropVector(ent,Prop_Data,"m_vecMins",vecs);
							//SetEntProp(ent,Prop_Data,"m_MoveType",0);
							SetEntData(ent, collisiongroup, 17, 4, true);
							int propphy = CreateEntityByName("prop_physics_override");
							if (propphy != -1)
							{
								char targn[64];
								char restoretn[64];
								int findtn = FindStringInArray(passedarr,"targetname");
								if (findtn != -1)
								{
									findtn++;
									GetArrayString(passedarr,findtn,targn,sizeof(targn));
								}
								Format(restoretn,sizeof(restoretn),"%s",targn);
								Format(targn,sizeof(targn),"%s%iprop",targn,ent);
								DispatchKeyValue(propphy,"model","models/NPCs/sentry_ground.mdl");
								DispatchKeyValue(propphy,"DisableBoneFollowers","1");
								DispatchKeyValue(propphy,"DisableShadows","1");
								DispatchKeyValue(propphy,"rendermode","10");
								DispatchKeyValue(propphy,"renderfx","6");
								DispatchKeyValue(propphy,"rendercolor","0 0 0");
								DispatchKeyValue(propphy,"renderamt","0");
								DispatchKeyValue(propphy,"modelscale","1.1");
								DispatchKeyValue(propphy,"targetname",targn);
								fileorigin[2]+=3.0;
								TeleportEntity(propphy,fileorigin,angs,NULL_VECTOR);
								DispatchSpawn(propphy);
								ActivateEntity(propphy);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",propphy);
								int logcoll = CreateEntityByName("logic_collision_pair");
								if (logcoll != -1)
								{
									DispatchKeyValue(logcoll,"attach1",targn);
									Format(targn,sizeof(targn),"%s%isentry",restoretn,ent);
									DispatchKeyValue(logcoll,"attach2",targn);
									DispatchKeyValue(logcoll,"StartDisabled","1");
									DispatchSpawn(logcoll);
									ActivateEntity(logcoll);
									AcceptEntityInput(logcoll,"DisableCollisions");
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,logcoll);
									WritePackString(dp2,"logic_collision_pair");
									CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
									Handle dppass = CreateDataPack();
									WritePackString(dppass,restoretn);
									WritePackCell(dppass,ent);
									WritePackCell(dppass,logcoll);
									CreateTimer(0.1,restoretargn,dppass,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
							SDKHookEx(ent,SDKHook_Think,sentriesthink);
							SDKHookEx(ent,SDKHook_OnTakeDamage,notkdmg);
						}
					}
					else if ((StrEqual(oldcls,"npc_houndeye",false)) || (StrEqual(oldcls,"monster_houndeye",false)))
					{
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							char targn[64];
							GetArrayString(passedarr,findtn,targn,sizeof(targn));
							SetEntPropString(ent,Prop_Data,"m_iName",targn);
						}
						setuphound(ent);
					}
					else if ((StrEqual(oldcls,"npc_bullsquid",false)) || (StrEqual(oldcls,"monster_bullchicken",false)))
					{
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							char targn[64];
							GetArrayString(passedarr,findtn,targn,sizeof(targn));
							SetEntPropString(ent,Prop_Data,"m_iName",targn);
						}
						setupsquid(ent);
					}
					else if (StrEqual(oldcls,"npc_tentacle",false))
					{
						SetEntityMoveType(ent,MOVETYPE_FLY);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						int find = FindValueInArray(tents,ent);
						if (find != -1)
						{
							int entmdl = GetArrayCell(tentsmdl,find);
							TeleportEntity(entmdl,fileorigin,angs,NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(entmdl,"SetParent",ent);
						}
					}
					else if (StrEqual(oldcls,"monster_scientist",false))
					{
						SDKHookEx(ent,SDKHook_OnTakeDamage,scihl1tkdmg);
						if (GetEntProp(ent,Prop_Data,"m_nBody") == -1) SetEntProp(ent,Prop_Data,"m_nBody",GetRandomInt(1,3));
					}
					else if (StrEqual(oldcls,"npc_gonarch",false))
					{
						float vMins[3];
						float vMaxs[3];
						vMins[0] = -30.0;
						vMins[1] = -30.0;
						vMins[2] = 0.0;
						vMaxs[0] = 30.0;
						vMaxs[1] = 30.0;
						vMaxs[2] = 72.0;
						SetEntPropVector(ent,Prop_Data,"m_vecMins",vMins);
						SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vMaxs);
					}
					else if (StrEqual(oldcls,"npc_human_security",false))
					{
						int find = FindStringInArray(passedarr,"setbodygroup");
						if (find == -1)
						{
							char randbody[8];
							Format(randbody,sizeof(randbody),"%i",GetRandomInt(0,20));
							SetVariantString(randbody);
							AcceptEntityInput(ent,"SetBodyGroup");
						}
						int findsf = FindStringInArray(passedarr,"spawnflags");
						if (findsf != -1)
						{
							findsf++;
							bool predisaster = GetStateOf("predisaster");
							char sfch[16];
							GetArrayString(passedarr,findsf,sfch,sizeof(sfch));
							int sf = StringToInt(sfch);
							if ((sf & 1<<17) || (predisaster))
							{
								SetVariantString("spawnflags 1064960");
								AcceptEntityInput(ent,"AddOutput");
							}
						}
						SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
					}
					else if (StrEqual(oldcls,"npc_human_commander",false))
					{
						SetEntProp(ent,Prop_Data,"m_fIsElite",1);
					}
					else if (StrEqual(oldcls,"npc_abrams"))
					{
						if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
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
								DispatchSpawn(driver);
								ActivateEntity(driver);
								TeleportEntity(driver,fileorigin,angs,NULL_VECTOR);
								AcceptEntityInput(driver,"StartForward");
								//TeleportEntity(ent,NULL_VECTOR,angs,NULL_VECTOR);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",driver);
							}
						}
						int boundbox = CreateEntityByName("prop_dynamic");
						if (boundbox != -1)
						{
							char targn[64];
							int find = FindStringInArray(passedarr,"targetname");
							if (find != -1)
							{
								find++;
								GetArrayString(passedarr,find,targn,sizeof(targn));
							}
							else
							{
								Format(targn,sizeof(targn),"npc_abrams%i",ent);
								SetEntPropString(ent,Prop_Data,"m_iName",targn);
							}
							char boundbtarg[64];
							Format(boundbtarg,sizeof(boundbtarg),"abramsbox%i",boundbox);
							DispatchKeyValue(boundbox,"rendermode","10");
							DispatchKeyValue(boundbox,"solid","6");
							DispatchKeyValue(boundbox,"model","models/props_vehicles/abrams.mdl");
							TeleportEntity(boundbox,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(boundbox);
							ActivateEntity(boundbox);
							SetVariantString("!activator");
							AcceptEntityInput(boundbox,"SetParent",ent);
							SDKHookEx(boundbox,SDKHook_OnTakeDamage,abramstkdmg);
							SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",boundbox);
							int logcoll = CreateEntityByName("logic_collision_pair");
							if (logcoll != -1)
							{
								DispatchKeyValue(logcoll,"attach1",targn);
								DispatchKeyValue(logcoll,"attach2",boundbtarg);
								DispatchKeyValue(logcoll,"StartDisabled","1");
								DispatchSpawn(logcoll);
								ActivateEntity(logcoll);
							}
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
						if (HasEntProp(ent,Prop_Data,"m_iHealth"))
						{
							int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
							int maxh = 250;
							if (hchk != maxh)
							{
								SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
								SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
							}
						}
						SDKHookEx(ent,SDKHook_Think,abramsthink);
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
					else if (StrEqual(oldcls,"prop_surgerybot",false))
					{
						char botname[64];
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							GetArrayString(passedarr,findtn,botname,sizeof(botname));
							Format(botname,sizeof(botname),"%sattachments",botname);
						}
						else
						{
							Format(botname,sizeof(botname),"surgerybot%iattachments",ent);
						}
						int spark = CreateEntityByName("env_spark");
						if (spark != -1)
						{
							DispatchKeyValue(spark,"targetname",botname);
							DispatchKeyValue(spark,"maxdelay","2");
							DispatchKeyValue(spark,"magnitude","2");
							DispatchKeyValue(spark,"TrailLength","1");
							DispatchKeyValue(spark,"spawnflags","64");
							DispatchSpawn(spark);
							ActivateEntity(spark);
							SetVariantString("!activator");
							AcceptEntityInput(spark,"SetParent",ent);
							SetVariantString("Spark2");
							AcceptEntityInput(spark,"SetParentAttachment");
						}
						spark = CreateEntityByName("env_spark");
						if (spark != -1)
						{
							DispatchKeyValue(spark,"targetname",botname);
							DispatchKeyValue(spark,"maxdelay","2");
							DispatchKeyValue(spark,"magnitude","2");
							DispatchKeyValue(spark,"TrailLength","1");
							DispatchKeyValue(spark,"spawnflags","64");
							DispatchSpawn(spark);
							ActivateEntity(spark);
							SetVariantString("!activator");
							AcceptEntityInput(spark,"SetParent",ent);
							SetVariantString("Spark3");
							AcceptEntityInput(spark,"SetParentAttachment");
						}
						float hurtmins[3];
						float hurtmaxs[3];
						hurtmins[0]=-10.0;
						hurtmins[1]=-10.0;
						hurtmins[2]=-10.0;
						hurtmaxs[0]=10.0;
						hurtmaxs[1]=10.0;
						hurtmaxs[2]=10.0;
						for (int i = 1;i<5;i++)
						{
							int hurt = CreateEntityByName("trigger_hurt");
							if (hurt != -1)
							{
								DispatchKeyValue(hurt,"model","*1");
								DispatchKeyValue(hurt,"damage","70");
								DispatchKeyValue(hurt,"damagecap","999");
								DispatchKeyValue(hurt,"damagetype","4");
								DispatchKeyValue(hurt,"spawnflags","1");
								DispatchKeyValue(hurt,"targetname",botname);
								DispatchSpawn(hurt);
								ActivateEntity(hurt);
								SetVariantString("!activator");
								AcceptEntityInput(hurt,"SetParent",ent);
								char hurtattach[64];
								Format(hurtattach,sizeof(hurtattach),"Q%i_knife_blade",i);
								SetVariantString(hurtattach);
								AcceptEntityInput(hurt,"SetParentAttachment");
								SetEntPropVector(hurt,Prop_Data,"m_vecMins",hurtmins);
								SetEntPropVector(hurt,Prop_Data,"m_vecMaxs",hurtmaxs);
							}
							hurt = CreateEntityByName("trigger_hurt");
							if (hurt != -1)
							{
								DispatchKeyValue(hurt,"model","*1");
								DispatchKeyValue(hurt,"damage","50");
								DispatchKeyValue(hurt,"damagecap","999");
								DispatchKeyValue(hurt,"damagetype","4");
								DispatchKeyValue(hurt,"spawnflags","1");
								DispatchKeyValue(hurt,"targetname",botname);
								DispatchSpawn(hurt);
								ActivateEntity(hurt);
								SetVariantString("!activator");
								AcceptEntityInput(hurt,"SetParent",ent);
								char hurtattach[64];
								Format(hurtattach,sizeof(hurtattach),"Q%i_saw_blade",i);
								SetVariantString(hurtattach);
								AcceptEntityInput(hurt,"SetParentAttachment");
								SetEntPropVector(hurt,Prop_Data,"m_vecMins",hurtmins);
								SetEntPropVector(hurt,Prop_Data,"m_vecMaxs",hurtmaxs);
							}
						}
						int smokestack = CreateEntityByName("env_smokestack");
						if (smokestack != -1)
						{
							if (findtn != -1)
							{
								GetArrayString(passedarr,findtn,botname,sizeof(botname));
							}
							else
							{
								Format(botname,sizeof(botname),"surgerybot%i",ent);
							}
							DispatchKeyValue(smokestack,"targetname",botname);
							DispatchKeyValue(smokestack,"InitialState","1");
							DispatchKeyValue(smokestack,"BaseSpread","5");
							DispatchKeyValue(smokestack,"SpreadSpeed","10");
							DispatchKeyValue(smokestack,"Speed","30");
							DispatchKeyValue(smokestack,"StartSize","5");
							DispatchKeyValue(smokestack,"EndSize","10");
							DispatchKeyValue(smokestack,"Rate","5");
							DispatchKeyValue(smokestack,"JetLength","100");
							DispatchKeyValue(smokestack,"SmokeMaterial","particle/SmokeStack.vmt");
							DispatchSpawn(smokestack);
							ActivateEntity(smokestack);
							SetVariantString("!activator");
							AcceptEntityInput(smokestack,"SetParent",ent);
							SetVariantString("Smoke1");
							AcceptEntityInput(smokestack,"SetParentAttachment");
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",smokestack);
							Format(botname,sizeof(botname),"surgerybot%ibase",ent);
							SetEntPropString(ent,Prop_Data,"m_iName",botname);
							//m_bEmit
							SDKHookEx(ent,SDKHook_Think,surgerybotthink);
						}
					}
					else if ((StrEqual(oldcls,"env_xen_portal",false)) || (StrEqual(oldcls,"env_xen_portal_template",false)))
					{
						fileorigin[2]+=20.0;
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					else if (StrEqual(oldcls,"env_mortar_controller",false))
					{
						int findlauncher = FindStringInArray(passedarr,"MortarLauncher");
						if (findlauncher != -1)
						{
							findlauncher++;
							char launchtarg[64];
							GetArrayString(passedarr,findlauncher,launchtarg,sizeof(launchtarg));
							SetEntPropString(ent,Prop_Data,"m_iszResponseContext",launchtarg);
							int controlpv = CreateEntityByName("point_viewcontrol");
							if (controlpv != -1)
							{
								float fileoriginz[3];
								float angsset[3];
								char mortarpv[64];
								angsset[0] = 90.0;
								angsset[1] = 90.0;
								fileoriginz[0] = fileorigin[0];
								fileoriginz[1] = fileorigin[1];
								fileoriginz[2] = fileorigin[2]+1500.0;
								Format(mortarpv,sizeof(mortarpv),"%spv",launchtarg);
								DispatchKeyValue(controlpv,"targetname",mortarpv);
								DispatchKeyValue(controlpv,"spawnflags","8");
								TeleportEntity(controlpv,fileoriginz,angsset,NULL_VECTOR);
								DispatchSpawn(controlpv);
								ActivateEntity(controlpv);
								SetEntPropEnt(controlpv,Prop_Data,"m_hEffectEntity",ent);
							}
							int setupcontrol = CreateEntityByName("game_ui");
							if (setupcontrol != -1)
							{
								char launchtargpv[128];
								Format(launchtargpv,sizeof(launchtargpv),"%sui",launchtarg);
								DispatchKeyValue(setupcontrol,"targetname",launchtargpv);
								DispatchKeyValue(setupcontrol,"spawnflags","480");
								DispatchKeyValue(setupcontrol,"FieldOfView","-1");
								Format(launchtargpv,sizeof(launchtargpv),"%spv,Enable,,0,-1",launchtarg);
								DispatchKeyValue(setupcontrol,"PlayerOn",launchtargpv);
								Format(launchtargpv,sizeof(launchtargpv),"%spv,Disable,,0,-1",launchtarg);
								DispatchKeyValue(setupcontrol,"PlayerOff",launchtargpv);
								DispatchSpawn(setupcontrol);
								ActivateEntity(setupcontrol);
								HookSingleEntityOutput(setupcontrol,"PressedMoveLeft",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedMoveRight",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedForward",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedBack",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedAttack",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedMoveLeft",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedMoveRight",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedForward",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedBack",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PlayerOff",env_mortarcontroller);
								SetEntPropEnt(setupcontrol,Prop_Data,"m_hEffectEntity",controlpv);
								SDKHookEx(setupcontrol,SDKHook_Think,camthink);
							}
							//HookSingleEntityOutput(ent,"OnPlayerPickup",env_mortarcontroller);
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",setupcontrol);
							SDKHookEx(ent,SDKHook_Use,env_mortarcontrolleractivate);
						}
					}
					else if (StrEqual(oldcls,"grenade_tripmine",false))
					{
						SetupMine(ent);
					}
					else if ((StrEqual(oldcls,"func_50cal",false)) || (StrEqual(oldcls,"func_tow",false)))
					{
						SDKHookEx(ent,SDKHook_Think,functankthink);
					}
					else if (StrEqual(oldcls,"npc_apache",false))
					{
						SDKHookEx(ent,SDKHook_Think,apachethink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
					}
					else if (StrEqual(oldcls,"npc_osprey",false))
					{
						SDKHookEx(ent,SDKHook_Think,ospreythink);
						//SetEntProp(ent,Prop_Data,"m_nRenderMode",10);
						//SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						SetEntProp(ent,Prop_Data,"m_MoveType",4);
						int animprop = CreateEntityByName("prop_dynamic");
						if (animprop != -1)
						{
							DispatchKeyValue(animprop,"model","models/props_vehicles/osprey.mdl");
							DispatchKeyValue(animprop,"solid","4");
							DispatchKeyValue(animprop,"rendermode","10");
							DispatchKeyValue(animprop,"renderfx","6");
							DispatchKeyValue(animprop,"DefaultAnim","idle_flying");
							TeleportEntity(animprop,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(animprop);
							ActivateEntity(animprop);
							SetVariantString("!activator");
							AcceptEntityInput(animprop,"SetParent",ent);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",animprop);
							SDKHookEx(animprop,SDKHook_OnTakeDamage,abramstkdmg);
							SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
						}
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
								DispatchKeyValue(driver,"orientationtype","2");
								DispatchKeyValue(driver,"speed","300");
								DispatchSpawn(driver);
								ActivateEntity(driver);
								TeleportEntity(driver,fileorigin,angs,NULL_VECTOR);
								AcceptEntityInput(driver,"StartForward");
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",driver);
							}
						}
						Handle templatearr = CreateArray(9);
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char keychk[64];
							GetArrayString(passedarr,i,keychk,sizeof(keychk));
							i++;
							if (StrContains(keychk,"NPCTemplate",false) == 0)
							{
								char vchk[64];
								GetArrayString(passedarr,i,vchk,sizeof(vchk));
								PushArrayString(templatearr,vchk);
							}
						}
						if (GetArraySize(templatearr) > 0)
						{
							int templatestore = CreateEntityByName("point_template");
							if (templatestore != -1)
							{
								for (int i = 0;i<GetArraySize(templatearr);i++)
								{
									char tmp[64];
									char tmp2[64];
									Format(tmp,sizeof(tmp),"Template0%i",i);
									GetArrayString(templatearr,i,tmp2,sizeof(tmp2));
									DispatchKeyValue(templatestore,tmp,tmp2);
								}
								DispatchSpawn(templatestore);
								ActivateEntity(templatestore);
								SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",templatestore);
							}
						}
						CloseHandle(templatearr);
					}
					else if (StrEqual(oldcls,"env_xen_portal_template",false))
					{
						if (FindValueInArray(templateslist,ent) == -1) PushArrayCell(templateslist,ent);
					}
					else if (StrEqual(oldcls,"env_xen_pushpad",false))
					{
						SDKHook(ent,SDKHook_StartTouch,StartTouchPushPad);
						float maxs[3];
						GetEntPropVector(ent,Prop_Data,"m_vecMaxs",maxs);
						maxs[2] = 10.0;
						SetEntPropVector(ent,Prop_Data,"m_vecMaxs",maxs);
						int findjumpheight = FindStringInArray(passedarr,"height");
						if (findjumpheight != -1)
						{
							findjumpheight++;
							char jumpheight[16];
							GetArrayString(passedarr,findjumpheight,jumpheight,sizeof(jumpheight));
							SetEntPropFloat(ent,Prop_Data,"m_flSpeed",StringToFloat(jumpheight));
						}
						else SetEntPropFloat(ent,Prop_Data,"m_flSpeed",512.0);
						int findjumptarg = FindStringInArray(passedarr,"target");
						if (findjumptarg != -1)
						{
							findjumptarg++;
							char jumptarg[64];
							GetArrayString(passedarr,findjumptarg,jumptarg,sizeof(jumptarg));
							SetEntPropString(ent,Prop_Data,"m_iszResponseContext",jumptarg);
							findinfotarg(-1,jumptarg,ent);
						}
					}
					else if (StrEqual(oldcls,"env_dispenser",false))
					{
						char vals[64];
						int findval = FindStringInArray(passedarr,"spawnmodel");
						if (findval != -1)
						{
							findval++;
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							DispatchKeyValue(ent,"model",vals);
						}
						findval = FindStringInArray(passedarr,"spawnangles");
						if (findval != -1)
						{
							findval++;
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							DispatchKeyValue(ent,"angles",vals);
						}
						findval = FindStringInArray(passedarr,"capacity");
						if (findval != -1)
						{
							findval++;
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							DispatchKeyValue(ent,"max_health",vals);
						}
						findval = FindStringInArray(passedarr,"skinmin");
						if (findval != -1)
						{
							findval++;
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							SetEntProp(ent,Prop_Data,"m_iTeamNum",StringToInt(vals));
						}
						findval = FindStringInArray(passedarr,"skinmax");
						if (findval != -1)
						{
							findval++;
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							SetEntProp(ent,Prop_Data,"m_iInitialTeamNum",StringToInt(vals));
						}
					}
					else if (StrEqual(oldcls,"func_minefield",false))
					{
						SetVariantString("spawnflags 11");//3
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
								HookSingleEntityOutput(ent,"OnStartTouch",MineFieldTouch);
							}
						}
					}
					else if (StrEqual(oldcls,"npc_human_assassin",false))
					{
						SDKHookEx(ent,SDKHook_Think,assassinthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
						char mdlchk[64];
						GetEntPropString(ent,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
						if (!StrEqual(mdlchk,"models/humans/hassassin.mdl",false))
						{
							if (!IsModelPrecached("models/humans/hassassin.mdl")) PrecacheModel("models/humans/hassassin.mdl",true);
							DispatchKeyValue(ent,"model","models/humans/hassassin.mdl");
							SetEntPropString(ent,Prop_Data,"m_ModelName","models/humans/hassassin.mdl");
							SetEntityModel(ent,"models/humans/hassassin.mdl");
						}
						int pistol = CreateEntityByName("prop_physics");
						if (pistol != -1)
						{
							DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
							DispatchKeyValue(pistol,"solid","0");
							SetVariantString("!activator");
							AcceptEntityInput(pistol,"SetParent",ent);
							SetVariantString("anim_attachment_LH");
							AcceptEntityInput(pistol,"SetParentAttachment");
							DispatchSpawn(pistol);
							ActivateEntity(pistol);
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",pistol);
						}
						pistol = CreateEntityByName("prop_physics");
						if (pistol != -1)
						{
							DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
							DispatchKeyValue(pistol,"solid","0");
							SetVariantString("!activator");
							AcceptEntityInput(pistol,"SetParent",ent);
							SetVariantString("anim_attachment_RH");
							AcceptEntityInput(pistol,"SetParentAttachment");
							DispatchSpawn(pistol);
							ActivateEntity(pistol);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",pistol);
						}
						if (FindStringInArray(precachedarr,"npc_human_assassin") == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/weapons/glock/");
							recursion(searchprecache);
							Format(searchprecache,sizeof(searchprecache),"sound/npc/assassin/");
							recursion(searchprecache);
							PushArrayString(precachedarr,"npc_human_assassin");
						}
					}
					else if (StrEqual(oldcls,"monster_human_assassin",false))
					{
						SDKHookEx(ent,SDKHook_Think,assassinthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
						char mdlchk[64];
						GetEntPropString(ent,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
						if (!StrEqual(mdlchk,"models/hassassin.mdl",false))
						{
							if (!IsModelPrecached("models/hassassin.mdl")) PrecacheModel("models/hassassin.mdl",true);
							DispatchKeyValue(ent,"model","models/hassassin.mdl");
							SetEntPropString(ent,Prop_Data,"m_ModelName","models/hassassin.mdl");
							SetEntityModel(ent,"models/hassassin.mdl");
						}
						if (FindStringInArray(precachedarr,"monster_human_assassin") == -1)
						{
							PrecacheSound("common\\bodydrop1.wav",true);
							PrecacheSound("common\\bodydrop2.wav",true);
							PrecacheSound("common\\bodydrop3.wav",true);
							PrecacheSound("common\\bodydrop4.wav",true);
							PrecacheSound("weapons\\pl_gun1.wav",true);
							PrecacheSound("weapons\\pl_gun2.wav",true);
							PushArrayString(precachedarr,"monster_human_assassin");
						}
					}
					else if (StrEqual(oldcls,"npc_alien_slave",false))
					{
						SDKHookEx(ent,SDKHook_Think,aslavethink);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						if (!relsetvort)
						{
							setuprelations("npc_alien_slave");
							relsetvort = true;
						}
					}
					else if (StrEqual(oldcls,"npc_alien_controller",false))
					{
						if (FindStringInArray(precachedarr,"npc_alien_controller") == -1)
						{
							recursion("sound/npc/alien_controller/");
							PushArrayString(precachedarr,"npc_alien_controller");
						}
						if (HasEntProp(ent,Prop_Data,"m_iHealth"))
						{
							int maxh = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
							Handle cvar = FindConVar("sk_controller_health");
							if (cvar != INVALID_HANDLE)
							{
								int maxhchk = GetConVarInt(cvar);
								if (maxh != maxhchk)
								{
									SetEntProp(ent,Prop_Data,"m_iHealth",maxhchk);
									SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxhchk);
								}
							}
							CloseHandle(cvar);
						}
						if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",1);
						SDKHookEx(ent,SDKHook_Think,controllerthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,controllertkdmg);
						PushArrayCell(controllers,ent);
					}
					else if (StrEqual(oldcls,"npc_synth_scanner",false))
					{
						HookSingleEntityOutput(ent,"OnPhotographNPC",SynthScannerAttack);
						HookSingleEntityOutput(ent,"OnPhotographPlayer",SynthScannerAttack);
					}
					else if (StrEqual(oldcls,"item_weapon_gluon",false))
					{
						HookSingleEntityOutput(ent,"OnPlayerUse",EquipGluon);
						HookSingleEntityOutput(ent,"OnPlayerPickup",EquipGluon);
					}
					else if (StrEqual(oldcls,"monster_zombie",false))
					{
						SDKHookEx(ent,SDKHook_Think,monstzomthink);
					}
					int findparent = FindStringInArray(passedarr,"parentname");
					if (findparent != -1)
					{
						findparent++;
						char parentname[64];
						GetArrayString(passedarr,findparent,parentname,sizeof(parentname));
						if (strlen(parentname) > 0)
						{
							SetVariantString(parentname);
							AcceptEntityInput(ent,"SetParent");
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
					if (!StrEqual(oldcls,"logic_merchant_relay",false)) AcceptEntityInput(ent,"FireUser3");
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
							if (sf & 1<<11)
							{
								//Create new npc_template_maker with new info
								char szTemplateData[8192];
								char szTmp[64];
								char szTmp2[256];
								for (int j = 0;j<GetArraySize(passedarr);j++)
								{
									GetArrayString(passedarr,j,szTmp,sizeof(szTmp));
									Format(szTemplateData,sizeof(szTemplateData),"%s\"%s\"",szTemplateData,szTmp);
									j++;
									GetArrayString(passedarr,j,szTmp2,sizeof(szTmp2));
									if ((StrContains(szTmp,"classname",false) != -1) || (StrContains(szTmp,"additionalequipment",false) != -1))
									{
										GetBaseClassFor(szTmp2,szTmp2,sizeof(szTmp2));
									}
									Format(szTemplateData,sizeof(szTemplateData),"%s %\"%s\"\n",szTemplateData,szTmp2);
								}
								Format(szTemplateData,sizeof(szTemplateData),"%s}",szTemplateData);
								PushArrayString(passedarr,"szTemplateData");
								PushArrayString(passedarr,szTemplateData);
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
													//HookSingleEntityOutput(i,"OnEntitySpawned",ptspawnent);
													if ((StrEqual(oldcls,"npc_osprey",false)) || (StrEqual(oldcls,"npc_abrams",false)))
													{
														int parenttrain = GetEntPropEnt(ent,Prop_Data,"m_hParent");
														if ((parenttrain != 0) && (IsValidEntity(parenttrain))) AcceptEntityInput(parenttrain,"kill");
													}
													AcceptEntityInput(ent,"kill");
												}
											}
										}
									}
								}
							}
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
		if ((debuglvl == 3) && (debugoowlvl > 0)) PrintToServer("EntsAfterCreate %i",GetEntityCount());
	}
	CloseHandle(filehandle);
	CreateTimer(1.0,reapplyrelations,_,TIMER_FLAG_NO_MAPCHANGE);
	if (hTemplateData != INVALID_HANDLE)
	{
		if (GetArraySize(hTemplateData) > 0)
		{
			char szTargn[128];
			char szTemplateTarg[128];
			//char szTemplateData[8192];
			int iFindTemplateTarg = -1;
			for (int i = 0;i<GetArraySize(templateents);i++)
			{
				Handle hChkArr = GetArrayCell(templateents,i);
				if (hChkArr != INVALID_HANDLE)
				{
					int iFindTN = FindStringInArray(hChkArr,"targetname");
					int iFindEntD = FindStringInArray(hChkArr,"szTemplateData");
					if ((iFindTN != -1) && (iFindEntD != -1))
					{
						iFindEntD++;
						iFindTN++;
						GetArrayString(hChkArr,iFindTN,szTargn,sizeof(szTargn));
						//GetArrayString(hChkArr,iFindEntD,szTemplateData,sizeof(szTemplateData));
						for (int j = 0;j<GetArraySize(hTemplateData);j++)
						{
							Handle hTemplateSet = GetArrayCell(hTemplateData,j);
							char szTmp[64];
							char szTmp2[128];
							for (int k = 0;k<GetArraySize(hTemplateSet);k++)
							{
								GetArrayString(hTemplateSet,k,szTmp,sizeof(szTmp));
								k++;
								GetArrayString(hTemplateSet,k,szTmp2,sizeof(szTmp2));
							}
							iFindTemplateTarg = FindStringInArray(hTemplateSet,"TemplateName");
							if (iFindTemplateTarg == -1) iFindTemplateTarg = FindStringInArray(hTemplateSet,"Templatename");
							if (iFindTemplateTarg == -1) iFindTemplateTarg = FindStringInArray(hTemplateSet,"templatename");
							if (iFindTemplateTarg != -1)
							{
								iFindTemplateTarg++;
								GetArrayString(hTemplateSet,iFindTemplateTarg,szTemplateTarg,sizeof(szTemplateTarg));
								if (StrEqual(szTargn,szTemplateTarg,false))
								{
									PushArrayString(hTemplateSet,"szTemplateData");
									PushArrayString(hTemplateSet,szTargn);
									//PrintToServer("Addtemplate %s",szTemplateData);
								}
							}
						}
					}
				}
			}
			CreateTimer(0.1,ReCreateTemplateMakers,_,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if (!weapmanagersplaced) CreateTimer(0.1,rehooksaves);
}

public Action ReCreateTemplateMakers(Handle timer)
{
	//PrintToServer("Re-create npc template sets");
	//hTemplateData is passedarr of all npc_template_maker
	for (int i = 0;i<GetArraySize(hTemplateData);i++)
	{
		Handle hTemplateSet = GetArrayCell(hTemplateData,i);
		if (FindStringInArray(hTemplateSet,"szTemplateData") != -1)
		{
			int iTemplateMaker = CreateEntityByName("npc_template_maker");
			if (iTemplateMaker != -1)
			{
				char szTmp[128];
				char szTmp2[256];
				char szTemplateData[8192];
				for (int j = 0;j<GetArraySize(hTemplateSet);j++)
				{
					GetArrayString(hTemplateSet,j,szTmp,sizeof(szTmp));
					j++;
					GetArrayString(hTemplateSet,j,szTmp2,sizeof(szTmp2));
					if (StrEqual(szTmp,"szTemplateData",false))
					{
						int iFindArrIndx = FindStringInArray(templatetargs,szTmp2);
						if (iFindArrIndx != -1)
						{
							Handle passedarr = GetArrayCell(templateents,iFindArrIndx);
							for (int k = 0;k<GetArraySize(passedarr);k++)
							{
								GetArrayString(passedarr,k,szTmp,sizeof(szTmp));
								k++;
								if (!StrEqual(szTmp,"szTemplateData",false))
								{
									GetArrayString(passedarr,k,szTmp2,sizeof(szTmp2));
									if (StrContains(szTmp,"classname",false) != -1)
									{
										Format(szTmp,sizeof(szTmp),"ResponseContext\" \"%s\"\n\"classname",szTmp2);
										GetBaseClassFor(szTmp2,szTmp2,sizeof(szTmp2));
									}
									else if (StrContains(szTmp,"additionalequipment",false) != -1)
									{
										GetBaseClassFor(szTmp2,szTmp2,sizeof(szTmp2));
									}
									Format(szTemplateData,sizeof(szTemplateData),"%s\"%s\" \"%s\"\n",szTemplateData,szTmp,szTmp2);
									//Format(szTemplateData,sizeof(szTemplateData),"%s \"%s\"\n",szTemplateData,szTmp2);
								}
							}
							Format(szTemplateData,sizeof(szTemplateData),"%s}",szTemplateData);
							//GetArrayString(hTemplateSet,j,szTemplateData,sizeof(szTemplateData));
							SetEntPropString(iTemplateMaker,Prop_Data,"m_iszTemplateData",szTemplateData);
							RemoveFromArray(templatetargs,iFindArrIndx);
							RemoveFromArray(templateents,iFindArrIndx);
						}
					}
					else DispatchKeyValue(iTemplateMaker,szTmp,szTmp2);
				}
				DispatchSpawn(iTemplateMaker);
				HookSingleEntityOutput(iTemplateMaker,"OnSpawnNPC",OnNPCTemplateSpawn,false);
			}
		}
		CloseHandle(hTemplateSet);
	}
	CloseHandle(hTemplateData);
	hTemplateData = INVALID_HANDLE;
}

public Action OnNPCTemplateSpawn(const char[] output, int caller, int activator, float delay)
{
	char szActCls[64];
	if (IsValidEntity(activator))
	{
		GetEntityClassname(activator,szActCls,sizeof(szActCls));
		if (HasEntProp(activator,Prop_Data,"m_iszResponseContext"))
		{
			char szOldCls[64];
			GetEntPropString(activator,Prop_Data,"m_iszResponseContext",szOldCls,sizeof(szOldCls));
			if (IsValidEntity(caller))
			{
				if (HasEntProp(caller,Prop_Data,"m_iszTemplateData"))
				{
					char szTemplateData[8192];
					GetEntPropString(caller,Prop_Data,"m_iszTemplateData",szTemplateData,sizeof(szTemplateData));
					if (StrContains(szTemplateData,"\"waitingtorappel\" \"1\"",false) != -1)
					{
						AcceptEntityInput(activator,"BeginRappel");
						CreateTimer(0.5,RefireRappel,activator,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			if (FindStringInArray(customentlist,szOldCls) != -1)
			{
				SetEntPropString(activator,Prop_Data,"m_iClassname",szOldCls);
				SetupLivingEnt(activator);
				/*
				if ((StrEqual(szOldCls,"npc_human_grunt",false)) || (StrEqual(szOldCls,"npc_human_commander",false)) || (StrEqual(szOldCls,"npc_human_medic",false)))
				{
					if (StrEqual(szOldCls,"npc_human_medic",false))
					{
						int rand = GetRandomInt(0,2);
						if (rand == 0) rand = GetRandomInt(32,35);
						else if (rand == 1) rand = GetRandomInt(40,43);
						else if (rand == 2) rand = GetRandomInt(56,59);
						SetVariantInt(rand);
						AcceptEntityInput(activator,"SetBodyGroup");
					}
					else
					{
						int rand = GetRandomInt(0,70);
						if ((rand >= 32) && (rand <= 35)) rand = GetRandomInt(0,31);
						else if ((rand >= 40) && (rand <= 43)) rand = GetRandomInt(36,39);
						else if ((rand >= 56) && (rand <= 59)) rand = GetRandomInt(60,70);
						SetVariantInt(rand);
						AcceptEntityInput(activator,"SetBodyGroup");
					}
					if (GetEntProp(activator,Prop_Data,"m_nSkin") == 0)
					{
						int rand = GetRandomInt(0,14);
						SetVariantInt(rand);
						AcceptEntityInput(activator,"skin");
					}
					if (StrEqual(szOldCls,"npc_human_grenadier",false))
					{
						SDKHookEx(activator,SDKHook_Think,grenthink);
					}
					else SDKHookEx(activator,SDKHook_Think,hgruntthink);
					AcceptEntityInput(activator,"GagEnable");
				}
				else if ((StrEqual(szOldCls,"npc_houndeye",false)) || (StrEqual(szOldCls,"monster_houndeye",false)))
				{
					setuphound(activator);
				}
				else if ((StrEqual(szOldCls,"npc_bullsquid",false)) || (StrEqual(szOldCls,"monster_bullchicken",false)))
				{
					setupsquid(activator);
				}
				*/
			}
		}
	}
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
			char clsfind[128];
			Format(clsfind,sizeof(clsfind),"%s",line);
			ExplodeString(clsfind, "\"", kvs, 64, 128, true);
			ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
			ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
			//if ((StrContains(line,"classname",false) != -1) && ((StrContains(line,"npc_",false) != -1) || (StrContains(line,"monster_",false) != -1) || (StrContains(line,"multi_manager",false) != -1) || (StrContains(line,"item_weapon_tripmine",false) != -1) || (StrContains(line,"prop_train_awesome",false) != -1) || (StrContains(line," item_ammo_smg1_grenade",false) != -1)))
			if ((StrContains(line,"classname",false) != -1) && ((StrContains(line,"npc_",false) != -1) || (StrContains(line,"monster_",false) != -1) || (FindStringInArray(customentlist,kvs[3]) != -1)))
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),"%s",line);
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
			if ((!StrEqual(line,"}",false)) || (!StrEqual(line,"{",false)) || (!StrEqual(line,"}{",false)))
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
				Format(tmpchar,sizeof(tmpchar),"%s",line);
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
				Format(tmpchar,sizeof(tmpchar),"%s",line);
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
				Format(tmpchar,sizeof(tmpchar),"%s",line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"angles\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				char origch[16][16];
				ExplodeString(tmpchar," ",origch,16,16);
				angs[0] = StringToFloat(origch[0]);
				angs[1] = StringToFloat(origch[1]);
				angs[2] = StringToFloat(origch[2]);
			}
			if (((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)) || (StrEqual(line,"}{",false))) && (ent == -1))
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
						Format(cls,sizeof(cls),"npc_headcrab");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/headcrab.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/headcrab.mdl");
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
						PushArrayString(passedarr,"body");
						char randbody[4];
						Format(randbody,sizeof(randbody),"%i",GetRandomInt(0,6));
						PushArrayString(passedarr,randbody);
						createsit = true;
					}
					else if ((StrEqual(cls,"monster_barney",false)) || (StrEqual(cls,"monster_barney_dead",false)))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/barney.mdl");
					}
					else if (StrEqual(cls,"monster_ichthyosaur",false))
					{
						Format(cls,sizeof(cls),"npc_ichthyosaur");
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
						Format(cls,sizeof(cls),"npc_barnacle");
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
						Format(cls,sizeof(cls),"npc_combine_s");
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
						Format(cls,sizeof(cls),"npc_antlion");
					}
					else if (StrEqual(cls,"trigger_auto",false))
					{
						Format(cls,sizeof(cls),"logic_relay");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Trigger,,1,1");
						PushArrayString(passedarr,"OnUser3");
						PushArrayString(passedarr,"!self,Kill,,1.5,1");
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
							//if (StrEqual(addweap,"default",false)) Format(cls,sizeof(cls),"generic_actor");
							//else
							//{
							Format(cls,sizeof(cls),"npc_citizen");
							PushArrayString(passedarr,"spawnflags");
							PushArrayString(passedarr,"1048576");
							PushArrayString(passedarr,"CitizenType");
							PushArrayString(passedarr,"4");
							//}
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
							setuprelations("npc_alien_slave");
							relsetvort = true;
						}
					}
					else if (StrEqual(cls,"npc_human_scientist_kleiner",false))
					{
						Format(cls,sizeof(cls),"npc_kleiner");
						if (FileExists("models/kleinerbms.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/kleinerbms.mdl");
						}
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
						else if (FileExists("models/elibms.mdl",true,NULL_STRING))
						{
							dp = CreateDataPack();
							WritePackString(dp,"models/elibms.mdl");
						}
					}
					else if (StrEqual(cls,"npc_zombie_security",false))
					{
						Handle cvarchk = FindConVar("sk_zombie_soldier_health");
						if (GetConVarInt(cvarchk) < 6) SetConVarInt(cvarchk,100,false,false);
						CloseHandle(cvarchk);
						if (!relsetzsec)
						{
							setuprelations("npc_zombie_security");
							relsetzsec = true;
						}
						Format(cls,sizeof(cls),"npc_zombine");
						PushArrayString(passedarr,"model");
						dp = CreateDataPack();
						if (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING))
						{
							PushArrayString(passedarr,"models/zombie/zsecurity.mdl");
							WritePackString(dp,"models/zombie/zsecurity.mdl");
						}
						else
						{
							PushArrayString(passedarr,"models/zombies/zombie_guard.mdl");
							WritePackString(dp,"models/zombies/zombie_guard.mdl");
						}
						Format(setupent,sizeof(setupent),"zombie");
					}
					else if (StrEqual(cls,"npc_zombie_security_torso",false))
					{
						Format(cls,sizeof(cls),"npc_zombie");
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
						if (!relsetzsec)
						{
							setuprelations("npc_zombie_scientist");
							relsetzsec = true;
						}
						Format(cls,sizeof(cls),"npc_zombie");
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
					else if (StrEqual(cls,"npc_odell",false))
					{
						Format(cls,sizeof(cls),"npc_citizen");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/_characters/odell.mdl");
						dp = CreateDataPack();
						WritePackString(dp,"models/_characters/odell.mdl");
					}
					else if (StrEqual(cls,"npc_osprey",false))
					{
						Format(cls,sizeof(cls),"generic_actor");
						PushArrayString(passedarr,"model");
						PushArrayString(passedarr,"models/props_vehicles/osprey.mdl");
					}
					else if (StrEqual(cls,"npc_houndeye",false))
					{
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
							setuprelations("npc_houndeye");
							relsethound = true;
						}
						Format(cls,sizeof(cls),"npc_antlion");
						dp = CreateDataPack();
						WritePackString(dp,"models/xenians/houndeye.mdl");
					}
					else if (StrEqual(cls,"monster_houndeye",false))
					{
						int mdlindx = FindStringInArray(passedarr,"model");
						if (mdlindx != -1)
						{
							mdlindx++;
							char mdlchk[128];
							GetArrayString(passedarr,mdlindx,mdlchk,sizeof(mdlchk));
							if (!FileExists(mdlchk,true,NULL_STRING))
							{
								PushArrayString(passedarr,"model");
								PushArrayString(passedarr,"models/houndeye.mdl");
								PushArrayString(passedarr,"modelscale");
								PushArrayString(passedarr,"0.6");
							}
						}
						if (!relsethound)
						{
							setuprelations("npc_houndeye");
							relsethound = true;
						}
						Format(cls,sizeof(cls),"npc_antlion");
						dp = CreateDataPack();
						WritePackString(dp,"models/houndeye.mdl");
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
					}
					else if ((StrEqual(cls,"info_player_rebel",false)) || (StrEqual(cls,"info_player_combine",false)) || (StrEqual(cls,"info_player_deathmatch",false)))
					{
						Format(cls,sizeof(cls),"info_player_coop");
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
							HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
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
							WritePackString(dp,oldcls);
							CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
						}
						else CloseHandle(dp);
					}
				}
				if ((StrEqual(line,"}",false)) || (StrEqual(line,"}{",false)))
				{
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
					{
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					else
					{
						TeleportEntity(ent,fileorigin,angs,NULL_VECTOR);
					}
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
							if (sf & 1<<17)
							{
								AcceptEntityInput(ent,"Disable");
								SetEntProp(ent,Prop_Data,"m_bDisabled",1);
							}
							if (sf & 1<<9)
							{
								SetEntProp(ent,Prop_Data,"m_iAmmo",-10,0);
							}
							SetVariantString("spawnflags 32");
							AcceptEntityInput(ent,"AddOutput");
						}
						if (StrEqual(oldcls,"npc_sentry_ceiling",false))
						{
							if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
							if (HasEntProp(ent,Prop_Data,"m_MoveType")) SetEntProp(ent,Prop_Data,"m_MoveType",3);
							int mhchk = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
							Handle cvar = FindConVar("sk_sentry_ceiling_health");
							if (cvar != INVALID_HANDLE)
							{
								int cvarh = GetConVarInt(cvar);
								if (mhchk != cvarh)
								{
									SetEntProp(ent,Prop_Data,"m_iHealth",cvarh);
									SetEntProp(ent,Prop_Data,"m_iMaxHealth",cvarh);
								}
							}
							CloseHandle(cvar);
							SDKHookEx(ent,SDKHook_Think,sentriesthink);
							fileorigin[2]-=0.1;
							Handle dppass = CreateDataPack();
							WritePackCell(dppass,ent);
							WritePackFloat(dppass,fileorigin[0]);
							WritePackFloat(dppass,fileorigin[1]);
							WritePackFloat(dppass,fileorigin[2]);
							CreateTimer(0.1,resetorgs,dppass,TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (StrEqual(oldcls,"npc_sentry_ground",false))
						{
							if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
							if (HasEntProp(ent,Prop_Data,"m_MoveType")) SetEntProp(ent,Prop_Data,"m_MoveType",3);
							int mhchk = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
							Handle cvar = FindConVar("sk_sentry_ground_health");
							if (cvar != INVALID_HANDLE)
							{
								int cvarh = GetConVarInt(cvar);
								if (mhchk != cvarh)
								{
									SetEntProp(ent,Prop_Data,"m_iHealth",cvarh);
									SetEntProp(ent,Prop_Data,"m_iMaxHealth",cvarh);
								}
							}
							CloseHandle(cvar);
							if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
							SetVariantString("1.1");
							AcceptEntityInput(ent,"SetModelScale");
							float vecs[3];
							vecs[0] = 1.0;
							vecs[1] = 1.0;
							vecs[2] = 1.0;
							SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vecs);
							vecs[0] = -16.0;
							vecs[1] = -12.0;
							vecs[2] = -1.0;
							SetEntPropVector(ent,Prop_Data,"m_vecMins",vecs);
							//SetEntProp(ent,Prop_Data,"m_MoveType",0);
							SetEntData(ent, collisiongroup, 17, 4, true);
							int propphy = CreateEntityByName("prop_physics_override");
							if (propphy != -1)
							{
								char targn[64];
								char restoretn[64];
								int findtn = FindStringInArray(passedarr,"targetname");
								if (findtn != -1)
								{
									findtn++;
									GetArrayString(passedarr,findtn,targn,sizeof(targn));
								}
								Format(restoretn,sizeof(restoretn),"%s",targn);
								Format(targn,sizeof(targn),"%s%iprop",targn,ent);
								DispatchKeyValue(propphy,"model","models/NPCs/sentry_ground.mdl");
								DispatchKeyValue(propphy,"DisableBoneFollowers","1");
								DispatchKeyValue(propphy,"DisableShadows","1");
								DispatchKeyValue(propphy,"rendermode","10");
								DispatchKeyValue(propphy,"renderfx","6");
								DispatchKeyValue(propphy,"rendercolor","0 0 0");
								DispatchKeyValue(propphy,"renderamt","0");
								DispatchKeyValue(propphy,"modelscale","1.1");
								DispatchKeyValue(propphy,"targetname",targn);
								fileorigin[2]+=3.0;
								TeleportEntity(propphy,fileorigin,angs,NULL_VECTOR);
								DispatchSpawn(propphy);
								ActivateEntity(propphy);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",propphy);
								int logcoll = CreateEntityByName("logic_collision_pair");
								if (logcoll != -1)
								{
									DispatchKeyValue(logcoll,"attach1",targn);
									Format(targn,sizeof(targn),"%s%isentry",restoretn,ent);
									DispatchKeyValue(logcoll,"attach2",targn);
									DispatchKeyValue(logcoll,"StartDisabled","1");
									DispatchSpawn(logcoll);
									ActivateEntity(logcoll);
									AcceptEntityInput(logcoll,"DisableCollisions");
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,logcoll);
									WritePackString(dp2,"logic_collision_pair");
									CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
									Handle dppass = CreateDataPack();
									WritePackString(dppass,restoretn);
									WritePackCell(dppass,ent);
									WritePackCell(dppass,logcoll);
									CreateTimer(0.1,restoretargn,dppass,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
							SDKHookEx(ent,SDKHook_Think,sentriesthink);
							SDKHookEx(ent,SDKHook_OnTakeDamage,notkdmg);
						}
					}
					else if ((StrEqual(oldcls,"npc_houndeye",false)) || (StrEqual(oldcls,"monster_houndeye",false)))
					{
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							char targn[64];
							GetArrayString(passedarr,findtn,targn,sizeof(targn));
							SetEntPropString(ent,Prop_Data,"m_iName",targn);
						}
						setuphound(ent);
					}
					else if ((StrEqual(oldcls,"npc_bullsquid",false)) || (StrEqual(oldcls,"monster_bullchicken",false)))
					{
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							char targn[64];
							GetArrayString(passedarr,findtn,targn,sizeof(targn));
							SetEntPropString(ent,Prop_Data,"m_iName",targn);
						}
						setupsquid(ent);
					}
					else if (StrEqual(oldcls,"npc_tentacle",false))
					{
						SetEntityMoveType(ent,MOVETYPE_FLY);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						int find = FindValueInArray(tents,ent);
						if (find != -1)
						{
							int entmdl = GetArrayCell(tentsmdl,find);
							TeleportEntity(entmdl,fileorigin,angs,NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(entmdl,"SetParent",ent);
						}
					}
					else if (StrEqual(oldcls,"npc_gonarch",false))
					{
						float vMins[3];
						float vMaxs[3];
						vMins[0] = -30.0;
						vMins[1] = -30.0;
						vMins[2] = 0.0;
						vMaxs[0] = 30.0;
						vMaxs[1] = 30.0;
						vMaxs[2] = 72.0;
						SetEntPropVector(ent,Prop_Data,"m_vecMins",vMins);
						SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vMaxs);
					}
					else if (StrEqual(oldcls,"npc_human_security",false))
					{
						int find = FindStringInArray(passedarr,"setbodygroup");
						if (find == -1)
						{
							char randbody[8];
							Format(randbody,sizeof(randbody),"%i",GetRandomInt(0,20));
							SetVariantString(randbody);
							AcceptEntityInput(ent,"SetBodyGroup");
						}
						int findsf = FindStringInArray(passedarr,"spawnflags");
						if (findsf != -1)
						{
							findsf++;
							char sfch[16];
							GetArrayString(passedarr,findsf,sfch,sizeof(sfch));
							int sf = StringToInt(sfch);
							if (sf & 1<<17)
							{
								SetVariantString("spawnflags 1064960");
								AcceptEntityInput(ent,"AddOutput");
							}
						}
						SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
					}
					else if (StrEqual(oldcls,"npc_human_commander",false))
					{
						SetEntProp(ent,Prop_Data,"m_fIsElite",1);
					}
					else if (StrEqual(oldcls,"npc_abrams"))
					{
						if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
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
								DispatchSpawn(driver);
								ActivateEntity(driver);
								TeleportEntity(driver,fileorigin,angs,NULL_VECTOR);
								AcceptEntityInput(driver,"StartForward");
								//TeleportEntity(ent,NULL_VECTOR,angs,NULL_VECTOR);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",driver);
							}
						}
						int boundbox = CreateEntityByName("prop_dynamic");
						if (boundbox != -1)
						{
							char targn[64];
							int find = FindStringInArray(passedarr,"targetname");
							if (find != -1)
							{
								find++;
								GetArrayString(passedarr,find,targn,sizeof(targn));
							}
							else
							{
								Format(targn,sizeof(targn),"npc_abrams%i",ent);
								SetEntPropString(ent,Prop_Data,"m_iName",targn);
							}
							char boundbtarg[64];
							Format(boundbtarg,sizeof(boundbtarg),"abramsbox%i",boundbox);
							DispatchKeyValue(boundbox,"rendermode","10");
							DispatchKeyValue(boundbox,"solid","6");
							DispatchKeyValue(boundbox,"model","models/props_vehicles/abrams.mdl");
							TeleportEntity(boundbox,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(boundbox);
							ActivateEntity(boundbox);
							SetVariantString("!activator");
							AcceptEntityInput(boundbox,"SetParent",ent);
							SDKHookEx(boundbox,SDKHook_OnTakeDamage,abramstkdmg);
							SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",boundbox);
							int logcoll = CreateEntityByName("logic_collision_pair");
							if (logcoll != -1)
							{
								DispatchKeyValue(logcoll,"attach1",targn);
								DispatchKeyValue(logcoll,"attach2",boundbtarg);
								DispatchKeyValue(logcoll,"StartDisabled","1");
								DispatchSpawn(logcoll);
								ActivateEntity(logcoll);
							}
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
						if (HasEntProp(ent,Prop_Data,"m_iHealth"))
						{
							int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
							int maxh = 250;
							if (hchk != maxh)
							{
								SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
								SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
							}
						}
						SDKHookEx(ent,SDKHook_Think,abramsthink);
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
					else if (StrEqual(oldcls,"prop_surgerybot",false))
					{
						char botname[64];
						int findtn = FindStringInArray(passedarr,"targetname");
						if (findtn != -1)
						{
							findtn++;
							GetArrayString(passedarr,findtn,botname,sizeof(botname));
							Format(botname,sizeof(botname),"%sattachments",botname);
						}
						else
						{
							Format(botname,sizeof(botname),"surgerybot%iattachments",ent);
						}
						int spark = CreateEntityByName("env_spark");
						if (spark != -1)
						{
							DispatchKeyValue(spark,"targetname",botname);
							DispatchKeyValue(spark,"maxdelay","2");
							DispatchKeyValue(spark,"magnitude","2");
							DispatchKeyValue(spark,"TrailLength","1");
							DispatchKeyValue(spark,"spawnflags","64");
							DispatchSpawn(spark);
							ActivateEntity(spark);
							SetVariantString("!activator");
							AcceptEntityInput(spark,"SetParent",ent);
							SetVariantString("Spark2");
							AcceptEntityInput(spark,"SetParentAttachment");
						}
						spark = CreateEntityByName("env_spark");
						if (spark != -1)
						{
							DispatchKeyValue(spark,"targetname",botname);
							DispatchKeyValue(spark,"maxdelay","2");
							DispatchKeyValue(spark,"magnitude","2");
							DispatchKeyValue(spark,"TrailLength","1");
							DispatchKeyValue(spark,"spawnflags","64");
							DispatchSpawn(spark);
							ActivateEntity(spark);
							SetVariantString("!activator");
							AcceptEntityInput(spark,"SetParent",ent);
							SetVariantString("Spark3");
							AcceptEntityInput(spark,"SetParentAttachment");
						}
						float hurtmins[3];
						float hurtmaxs[3];
						hurtmins[0]=-10.0;
						hurtmins[1]=-10.0;
						hurtmins[2]=-10.0;
						hurtmaxs[0]=10.0;
						hurtmaxs[1]=10.0;
						hurtmaxs[2]=10.0;
						for (int i = 1;i<5;i++)
						{
							int hurt = CreateEntityByName("trigger_hurt");
							if (hurt != -1)
							{
								DispatchKeyValue(hurt,"model","*1");
								DispatchKeyValue(hurt,"damage","70");
								DispatchKeyValue(hurt,"damagecap","999");
								DispatchKeyValue(hurt,"damagetype","4");
								DispatchKeyValue(hurt,"spawnflags","1");
								DispatchKeyValue(hurt,"targetname",botname);
								DispatchSpawn(hurt);
								ActivateEntity(hurt);
								SetVariantString("!activator");
								AcceptEntityInput(hurt,"SetParent",ent);
								char hurtattach[64];
								Format(hurtattach,sizeof(hurtattach),"Q%i_knife_blade",i);
								SetVariantString(hurtattach);
								AcceptEntityInput(hurt,"SetParentAttachment");
								SetEntPropVector(hurt,Prop_Data,"m_vecMins",hurtmins);
								SetEntPropVector(hurt,Prop_Data,"m_vecMaxs",hurtmaxs);
							}
							hurt = CreateEntityByName("trigger_hurt");
							if (hurt != -1)
							{
								DispatchKeyValue(hurt,"model","*1");
								DispatchKeyValue(hurt,"damage","50");
								DispatchKeyValue(hurt,"damagecap","999");
								DispatchKeyValue(hurt,"damagetype","4");
								DispatchKeyValue(hurt,"spawnflags","1");
								DispatchKeyValue(hurt,"targetname",botname);
								DispatchSpawn(hurt);
								ActivateEntity(hurt);
								SetVariantString("!activator");
								AcceptEntityInput(hurt,"SetParent",ent);
								char hurtattach[64];
								Format(hurtattach,sizeof(hurtattach),"Q%i_saw_blade",i);
								SetVariantString(hurtattach);
								AcceptEntityInput(hurt,"SetParentAttachment");
								SetEntPropVector(hurt,Prop_Data,"m_vecMins",hurtmins);
								SetEntPropVector(hurt,Prop_Data,"m_vecMaxs",hurtmaxs);
							}
						}
						int smokestack = CreateEntityByName("env_smokestack");
						if (smokestack != -1)
						{
							if (findtn != -1)
							{
								GetArrayString(passedarr,findtn,botname,sizeof(botname));
							}
							else
							{
								Format(botname,sizeof(botname),"surgerybot%i",ent);
							}
							DispatchKeyValue(smokestack,"targetname",botname);
							DispatchKeyValue(smokestack,"InitialState","1");
							DispatchKeyValue(smokestack,"BaseSpread","5");
							DispatchKeyValue(smokestack,"SpreadSpeed","10");
							DispatchKeyValue(smokestack,"Speed","30");
							DispatchKeyValue(smokestack,"StartSize","5");
							DispatchKeyValue(smokestack,"EndSize","10");
							DispatchKeyValue(smokestack,"Rate","5");
							DispatchKeyValue(smokestack,"JetLength","100");
							DispatchKeyValue(smokestack,"SmokeMaterial","particle/SmokeStack.vmt");
							DispatchSpawn(smokestack);
							ActivateEntity(smokestack);
							SetVariantString("!activator");
							AcceptEntityInput(smokestack,"SetParent",ent);
							SetVariantString("Smoke1");
							AcceptEntityInput(smokestack,"SetParentAttachment");
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",smokestack);
							Format(botname,sizeof(botname),"surgerybot%ibase",ent);
							SetEntPropString(ent,Prop_Data,"m_iName",botname);
							//m_bEmit
							SDKHookEx(ent,SDKHook_Think,surgerybotthink);
						}
					}
					else if ((StrEqual(oldcls,"env_xen_portal",false)) || (StrEqual(oldcls,"env_xen_portal_template",false)))
					{
						fileorigin[2]+=20.0;
						TeleportEntity(ent,fileorigin,NULL_VECTOR,NULL_VECTOR);
					}
					else if (StrEqual(oldcls,"env_mortar_controller",false))
					{
						int findlauncher = FindStringInArray(passedarr,"MortarLauncher");
						if (findlauncher != -1)
						{
							findlauncher++;
							char launchtarg[64];
							GetArrayString(passedarr,findlauncher,launchtarg,sizeof(launchtarg));
							SetEntPropString(ent,Prop_Data,"m_iszResponseContext",launchtarg);
							int controlpv = CreateEntityByName("point_viewcontrol");
							if (controlpv != -1)
							{
								float fileoriginz[3];
								float angsset[3];
								char mortarpv[64];
								angsset[0] = 90.0;
								angsset[1] = 90.0;
								fileoriginz[0] = fileorigin[0];
								fileoriginz[1] = fileorigin[1];
								fileoriginz[2] = fileorigin[2]+1500.0;
								Format(mortarpv,sizeof(mortarpv),"%spv",launchtarg);
								DispatchKeyValue(controlpv,"targetname",mortarpv);
								DispatchKeyValue(controlpv,"spawnflags","8");
								TeleportEntity(controlpv,fileoriginz,angsset,NULL_VECTOR);
								DispatchSpawn(controlpv);
								ActivateEntity(controlpv);
								SetEntPropEnt(controlpv,Prop_Data,"m_hEffectEntity",ent);
							}
							int setupcontrol = CreateEntityByName("game_ui");
							if (setupcontrol != -1)
							{
								char launchtargpv[128];
								Format(launchtargpv,sizeof(launchtargpv),"%sui",launchtarg);
								DispatchKeyValue(setupcontrol,"targetname",launchtargpv);
								DispatchKeyValue(setupcontrol,"spawnflags","480");
								DispatchKeyValue(setupcontrol,"FieldOfView","-1");
								Format(launchtargpv,sizeof(launchtargpv),"%spv,Enable,,0,-1",launchtarg);
								DispatchKeyValue(setupcontrol,"PlayerOn",launchtargpv);
								Format(launchtargpv,sizeof(launchtargpv),"%spv,Disable,,0,-1",launchtarg);
								DispatchKeyValue(setupcontrol,"PlayerOff",launchtargpv);
								DispatchSpawn(setupcontrol);
								ActivateEntity(setupcontrol);
								HookSingleEntityOutput(setupcontrol,"PressedMoveLeft",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedMoveRight",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedForward",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedBack",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PressedAttack",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedMoveLeft",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedMoveRight",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedForward",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"UnpressedBack",env_mortarcontroller);
								HookSingleEntityOutput(setupcontrol,"PlayerOff",env_mortarcontroller);
								SetEntPropEnt(setupcontrol,Prop_Data,"m_hEffectEntity",controlpv);
								SDKHookEx(setupcontrol,SDKHook_Think,camthink);
							}
							//HookSingleEntityOutput(ent,"OnPlayerPickup",env_mortarcontroller);
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",setupcontrol);
							SDKHookEx(ent,SDKHook_Use,env_mortarcontrolleractivate);
						}
					}
					else if (StrEqual(oldcls,"grenade_tripmine",false))
					{
						SetupMine(ent);
					}
					else if ((StrEqual(oldcls,"func_50cal",false)) || (StrEqual(oldcls,"func_tow",false)))
					{
						SDKHookEx(ent,SDKHook_Think,functankthink);
					}
					else if (StrEqual(oldcls,"npc_apache",false))
					{
						SDKHookEx(ent,SDKHook_Think,apachethink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
					}
					else if (StrEqual(oldcls,"npc_osprey",false))
					{
						SDKHookEx(ent,SDKHook_Think,ospreythink);
						//SetEntProp(ent,Prop_Data,"m_nRenderMode",10);
						//SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						SetEntProp(ent,Prop_Data,"m_MoveType",4);
						int animprop = CreateEntityByName("prop_dynamic");
						if (animprop != -1)
						{
							DispatchKeyValue(animprop,"model","models/props_vehicles/osprey.mdl");
							DispatchKeyValue(animprop,"solid","4");
							DispatchKeyValue(animprop,"rendermode","10");
							DispatchKeyValue(animprop,"renderfx","6");
							DispatchKeyValue(animprop,"DefaultAnim","idle_flying");
							TeleportEntity(animprop,fileorigin,angs,NULL_VECTOR);
							DispatchSpawn(animprop);
							ActivateEntity(animprop);
							SetVariantString("!activator");
							AcceptEntityInput(animprop,"SetParent",ent);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",animprop);
							SDKHookEx(animprop,SDKHook_OnTakeDamage,abramstkdmg);
							SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
						}
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
								DispatchKeyValue(driver,"orientationtype","2");
								DispatchKeyValue(driver,"speed","300");
								DispatchSpawn(driver);
								ActivateEntity(driver);
								TeleportEntity(driver,fileorigin,angs,NULL_VECTOR);
								AcceptEntityInput(driver,"StartForward");
								SetVariantString("!activator");
								AcceptEntityInput(ent,"SetParent",driver);
							}
						}
						Handle templatearr = CreateArray(9);
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char keychk[64];
							GetArrayString(passedarr,i,keychk,sizeof(keychk));
							i++;
							if (StrContains(keychk,"NPCTemplate",false) == 0)
							{
								char vchk[64];
								GetArrayString(passedarr,i,vchk,sizeof(vchk));
								PushArrayString(templatearr,vchk);
							}
						}
						if (GetArraySize(templatearr) > 0)
						{
							int templatestore = CreateEntityByName("point_template");
							if (templatestore != -1)
							{
								for (int i = 0;i<GetArraySize(templatearr);i++)
								{
									char tmp[64];
									char tmp2[64];
									Format(tmp,sizeof(tmp),"Template0%i",i);
									GetArrayString(templatearr,i,tmp2,sizeof(tmp2));
									DispatchKeyValue(templatestore,tmp,tmp2);
								}
								DispatchSpawn(templatestore);
								ActivateEntity(templatestore);
								SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",templatestore);
							}
						}
						CloseHandle(templatearr);
					}
					else if (StrEqual(oldcls,"env_xen_portal_template",false))
					{
						if (FindValueInArray(templateslist,ent) == -1) PushArrayCell(templateslist,ent);
					}
					else if (StrEqual(oldcls,"env_xen_pushpad",false))
					{
						SDKHook(ent,SDKHook_StartTouch,StartTouchPushPad);
						float maxs[3];
						GetEntPropVector(ent,Prop_Data,"m_vecMaxs",maxs);
						maxs[2] = 10.0;
						SetEntPropVector(ent,Prop_Data,"m_vecMaxs",maxs);
						int findjumpheight = FindStringInArray(passedarr,"height");
						if (findjumpheight != -1)
						{
							findjumpheight++;
							char jumpheight[16];
							GetArrayString(passedarr,findjumpheight,jumpheight,sizeof(jumpheight));
							SetEntPropFloat(ent,Prop_Data,"m_flSpeed",StringToFloat(jumpheight));
						}
						else SetEntPropFloat(ent,Prop_Data,"m_flSpeed",512.0);
						int findjumptarg = FindStringInArray(passedarr,"target");
						if (findjumptarg != -1)
						{
							findjumptarg++;
							char jumptarg[64];
							GetArrayString(passedarr,findjumptarg,jumptarg,sizeof(jumptarg));
							SetEntPropString(ent,Prop_Data,"m_iszResponseContext",jumptarg);
							findinfotarg(-1,jumptarg,ent);
						}
					}
					else if (StrEqual(oldcls,"env_dispenser",false))
					{
						char vals[64];
						int findval = FindStringInArray(passedarr,"spawnmodel");
						if (findval != -1)
						{
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							DispatchKeyValue(ent,"model",vals);
						}
						findval = FindStringInArray(passedarr,"spawnangles");
						if (findval != -1)
						{
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							DispatchKeyValue(ent,"angles",vals);
						}
						findval = FindStringInArray(passedarr,"capacity");
						if (findval != -1)
						{
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							DispatchKeyValue(ent,"max_health",vals);
						}
						findval = FindStringInArray(passedarr,"skinmin");
						if (findval != -1)
						{
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							isattacking[ent] = StringToInt(vals);
						}
						findval = FindStringInArray(passedarr,"skinmax");
						if (findval != -1)
						{
							GetArrayString(passedarr,findval,vals,sizeof(vals));
							timesattacked[ent] = StringToInt(vals);
						}
					}
					else if (StrEqual(oldcls,"func_minefield",false))
					{
						SetVariantString("spawnflags 11");
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
								HookSingleEntityOutput(ent,"OnStartTouch",MineFieldTouch);
							}
						}
					}
					else if (StrEqual(oldcls,"npc_human_assassin",false))
					{
						SDKHookEx(ent,SDKHook_Think,assassinthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
						char mdlchk[64];
						GetEntPropString(ent,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
						if (!StrEqual(mdlchk,"models/humans/hassassin.mdl",false))
						{
							DispatchKeyValue(ent,"model","models/humans/hassassin.mdl");
							SetEntPropString(ent,Prop_Data,"m_ModelName","models/humans/hassassin.mdl");
							SetEntityModel(ent,"models/humans/hassassin.mdl");
						}
						int pistol = CreateEntityByName("prop_physics");
						if (pistol != -1)
						{
							DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
							DispatchKeyValue(pistol,"solid","0");
							SetVariantString("!activator");
							AcceptEntityInput(pistol,"SetParent",ent);
							SetVariantString("anim_attachment_LH");
							AcceptEntityInput(pistol,"SetParentAttachment");
							DispatchSpawn(pistol);
							ActivateEntity(pistol);
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",pistol);
						}
						pistol = CreateEntityByName("prop_physics");
						if (pistol != -1)
						{
							DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
							DispatchKeyValue(pistol,"solid","0");
							SetVariantString("!activator");
							AcceptEntityInput(pistol,"SetParent",ent);
							SetVariantString("anim_attachment_RH");
							AcceptEntityInput(pistol,"SetParentAttachment");
							DispatchSpawn(pistol);
							ActivateEntity(pistol);
							SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",pistol);
						}
						if (FindStringInArray(precachedarr,"npc_human_assassin") == -1)
						{
							char searchprecache[128];
							Format(searchprecache,sizeof(searchprecache),"sound/weapons/glock/");
							recursion(searchprecache);
							Format(searchprecache,sizeof(searchprecache),"sound/npc/assassin/");
							recursion(searchprecache);
							PushArrayString(precachedarr,"npc_human_assassin");
						}
					}
					else if (StrEqual(oldcls,"monster_human_assassin",false))
					{
						SDKHookEx(ent,SDKHook_Think,assassinthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
						if (FindStringInArray(precachedarr,"monster_human_assassin") == -1)
						{
							PrecacheSound("common\\bodydrop1.wav",true);
							PrecacheSound("common\\bodydrop2.wav",true);
							PrecacheSound("common\\bodydrop3.wav",true);
							PrecacheSound("common\\bodydrop4.wav",true);
							PrecacheSound("weapons\\pl_gun1.wav",true);
							PrecacheSound("weapons\\pl_gun2.wav",true);
							PushArrayString(precachedarr,"monster_human_assassin");
						}
					}
					else if (StrEqual(oldcls,"npc_alien_slave",false))
					{
						SDKHookEx(ent,SDKHook_Think,aslavethink);
						SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
						if (!relsetvort)
						{
							setuprelations("npc_alien_slave");
							relsetvort = true;
						}
					}
					else if (StrEqual(oldcls,"npc_alien_controller",false))
					{
						if (FindStringInArray(precachedarr,"npc_alien_controller") == -1)
						{
							recursion("sound/npc/alien_controller/");
							PushArrayString(precachedarr,"npc_alien_controller");
						}
						if (HasEntProp(ent,Prop_Data,"m_iHealth"))
						{
							int maxh = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
							Handle cvar = FindConVar("sk_controller_health");
							if (cvar != INVALID_HANDLE)
							{
								int maxhchk = GetConVarInt(cvar);
								if (maxh != maxhchk)
								{
									SetEntProp(ent,Prop_Data,"m_iHealth",maxhchk);
									SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxhchk);
								}
							}
							CloseHandle(cvar);
						}
						if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",1);
						SDKHookEx(ent,SDKHook_Think,controllerthink);
						SDKHookEx(ent,SDKHook_OnTakeDamage,controllertkdmg);
						PushArrayCell(controllers,ent);
					}
					else if (StrEqual(oldcls,"monster_zombie",false))
					{
						SDKHookEx(ent,SDKHook_Think,monstzomthink);
					}
					int findparent = FindStringInArray(passedarr,"parentname");
					if (findparent != -1)
					{
						findparent++;
						char parentname[64];
						GetArrayString(passedarr,findparent,parentname,sizeof(parentname));
						if (strlen(parentname) > 0)
						{
							SetVariantString(parentname);
							AcceptEntityInput(ent,"SetParent");
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
							if (sf & 1<<11)
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
													//HookSingleEntityOutput(i,"OnEntitySpawned",ptspawnent);
													if ((StrEqual(oldcls,"npc_osprey",false)) || (StrEqual(oldcls,"npc_abrams",false)))
													{
														int parenttrain = GetEntPropEnt(ent,Prop_Data,"m_hParent");
														if ((parenttrain != 0) && (IsValidEntity(parenttrain))) AcceptEntityInput(parenttrain,"kill");
													}
													AcceptEntityInput(ent,"kill");
												}
											}
										}
									}
								}
							}
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
					Format(cvarchk,sizeof(cvarchk),"%s_health",oldcls);
					ReplaceString(cvarchk,sizeof(cvarchk),"npc_","sk_",false);
					cvar = FindConVar(cvarchk);
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
						WritePackString(dp,oldcls);
						CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
					else CloseHandle(dp);
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
	if (!weapmanagersplaced) CreateTimer(0.1,rehooksaves);
}

public Action reapplyrelations(Handle timer)
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
		if ((StrEqual(cls,"npc_houndeye",false)) || (StrEqual(cls,"monster_houndeye",false)))
		{
			if (HasEntProp(entity,Prop_Data,"m_iHealth"))
			{
				if (GetEntProp(entity,Prop_Data,"m_iHealth") < 1)
				{
					AcceptEntityInput(entity,"kill");
					return Plugin_Handled;
				}
			}
			//houndeye_sonic_attack info_particle_system too large range
			/*
			if (hHoundEyeSonicEffect.BoolValue)
			{
				int effect = CreateEntityByName("info_particle_system");
				if (effect != -1)
				{
					DispatchKeyValue(effect,"effect_name","houndeye_sonic_attack");
					DispatchKeyValue(effect,"start_active","1");
					float angs[3];
					if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
					curorg[2]+=2.0;
					TeleportEntity(effect,curorg,angs,NULL_VECTOR);
					DispatchSpawn(effect);
					ActivateEntity(effect);
					AcceptEntityInput(effect,"Start");
					Handle dp2 = CreateDataPack();
					WritePackCell(dp2,effect);
					WritePackString(dp2,"info_particle_system");
					CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else
			{
			*/
			TE_SetupBeamRingPoint(curorg,-1.0,200.0,mdlus,mdlus3,0,5,0.5,2.0,1.0,{255, 255, 255, 255},255,FBEAM_SOLID);
			TE_SendToAll(0.0);
			if (FileExists("sound/npc/houndeye/he_blast1.wav",true,NULL_STRING))
			{
				char snd[128];
				Format(snd,sizeof(snd),"npc\\houndeye\\he_blast%i.wav",GetRandomInt(1,3));
				EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			}
			else if (FileExists("sound/npc/houndeye/blast1.wav",true,NULL_STRING))
			{
				EmitSoundToAll("npc\\houndeye\\blast1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			}
			else
			{
				StopSound(entity,SNDCHAN_WEAPON,"sound\\houndeye\\he_attack1.wav");
				StopSound(entity,SNDCHAN_WEAPON,"sound\\houndeye\\he_attack2.wav");
				StopSound(entity,SNDCHAN_WEAPON,"sound\\houndeye\\he_attack3.wav");
				char snd[128];
				Format(snd,sizeof(snd),"houndeye\\he_blast%i.wav",GetRandomInt(1,3));
				EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			}
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
			char szHoundSquad[32];
			char szEntSquad[32];
			if (HasEntProp(entity,Prop_Data,"m_SquadName")) GetEntPropString(entity,Prop_Data,"m_SquadName",szHoundSquad,sizeof(szHoundSquad));
			for (int i = 1; i<GetMaxEntities(); i++)
			{
				if (IsValidEntity(i) && IsEntNetworkable(i))
				{
					char clsname[32];
					GetEntityClassname(i,clsname,sizeof(clsname));
					if (((!StrEqual(clsname,"npc_houndeye",false)) && (!StrEqual(clsname,"npc_bullsquid",false)) && (!StrEqual(clsname,"npc_gargantua",false)) && (!StrEqual(clsname,"npc_snark",false)) && (!StrEqual(clsname,"npc_alien_slave",false)) && (!StrEqual(clsname,"npc_tentacle",false))) && ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_dynamic",false) != -1) || (StrContains(clsname,"prop_physics",false) != -1)))
					{
						if (strlen(szHoundSquad) > 0)
						{
							szEntSquad = "";
							if (HasEntProp(i,Prop_Data,"m_SquadName"))
							{
								GetEntPropString(i,Prop_Data,"m_SquadName",szEntSquad,sizeof(szEntSquad));
								if (StrEqual(szHoundSquad,szEntSquad,false)) continue;
							}
						}
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
				DispatchKeyValue(endpoint,"imagnitude","80");
				DispatchKeyValue(endpoint,"targetname","syn_tentacleblast");
				DispatchKeyValue(endpoint,"iradiusoverride","150");
				DispatchKeyValue(endpoint,"rendermode","0");
				DispatchKeyValue(endpoint,"spawnflags","9084");
				SetEntPropEnt(endpoint,Prop_Data,"m_hEffectEntity",entity);
				DispatchSpawn(endpoint);
				ActivateEntity(endpoint);
				AcceptEntityInput(endpoint,"Explode");
			}
		}
		else if (StrEqual(cls,"npc_alien_slave"))
		{
			if (HasEntProp(entity,Prop_Data,"m_iHealth"))
			{
				if (GetEntProp(entity,Prop_Data,"m_iHealth") < 1)
				{
					AcceptEntityInput(entity,"kill");
					return Plugin_Handled;
				}
			}
			SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
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
		else if ((StrEqual(cls,"npc_human_assassin",false)) || (StrEqual(cls,"monster_human_assassin",false)))
		{
			SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
		}
		else if (StrEqual(cls,"env_xen_pushpad",false))
		{
			if (GetArraySize(entlist) > 0)
			{
				float Time = GetTickedTime();
				float jumpheight = GetEntPropFloat(entity,Prop_Data,"m_flSpeed");
				if (jumpheight == 0.0)
				{
					jumpheight = 512.0;
					SetEntPropFloat(entity,Prop_Data,"m_flSpeed",512.0);
				}
				float shootvel[3];
				float loc[3];
				int targjump = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
				if ((IsValidEntity(targjump)) && (targjump != 0))
				{
					if (HasEntProp(targjump,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targjump,Prop_Data,"m_vecAbsOrigin",loc);
					else if (HasEntProp(targjump,Prop_Send,"m_vecOrigin")) GetEntPropVector(targjump,Prop_Send,"m_vecOrigin",loc);
				}
				else
				{
					loc[0] = curorg[0];
					loc[1] = curorg[1];
					loc[2] = curorg[2]+jumpheight;
				}
				MakeVectorFromPoints(curorg,loc,shootvel);
				shootvel[2]+=jumpheight;
				if (jumpheight < 1500) ScaleVector(shootvel,1.3);
				/*
				if ((StrContains(mapbuf,"xen_c4",false) == -1) && (StrContains(mapbuf,"xen_c5",false) == -1))
				{
					float scale = jumpheight/100.0;
					if (jumpheight < 256.0) scale = jumpheight/40;
					if (scale > 1.0) ScaleVector(shootvel,scale);
				}
				*/
				for (int j = 0;j<GetArraySize(entlist);j++)
				{
					int i = GetArrayCell(entlist,j);
					if ((IsValidEntity(i)) && (i != 0))
					{
						int groundent = -1;
						if (HasEntProp(i,Prop_Data,"m_hGroundEntity")) groundent = GetEntPropEnt(i,Prop_Data,"m_hGroundEntity");
						if (groundent == entity)
						{
							float entpos[3];
							if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",entpos);
							else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",entpos);
							entpos[2]+=1.0;
							if (HasEntProp(i,Prop_Send,"m_vecVelocity[0]")) shootvel[0]+=GetEntPropFloat(i, Prop_Send, "m_vecVelocity[0]");
							if (HasEntProp(i,Prop_Send,"m_vecVelocity[1]")) shootvel[1]+=GetEntPropFloat(i, Prop_Send, "m_vecVelocity[1]");
							TeleportEntity(i,entpos,NULL_VECTOR,shootvel);
						}
					}
				}
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
									int groundent = -1;
									if ((groundent == entity) || (centlasttouch[i] > Time))
									{
										float entpos[3];
										if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",entpos);
										else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",entpos);
										entpos[2]+=1.0;
										if (HasEntProp(i,Prop_Send,"m_vecVelocity[0]")) shootvel[0] = GetEntPropFloat(i, Prop_Send, "m_vecVelocity[0]");
										if (HasEntProp(i,Prop_Send,"m_vecVelocity[1]")) shootvel[1] = GetEntPropFloat(i, Prop_Send, "m_vecVelocity[1]");
										TeleportEntity(i,entpos,NULL_VECTOR,shootvel);
									}
								}
							}
						}
					}
				}
			}
		}
	}
	isattacking[entity] = false;
	return Plugin_Handled;
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

void functankthink(int entity)
{
	if (IsValidEntity(entity))
	{
		int animprop = GetEntPropEnt(entity,Prop_Data,"m_hParent");
		if ((animprop != 0) && (IsValidEntity(animprop)) && (HasEntProp(entity,Prop_Data,"m_hController")))
		{
			int controller = GetEntPropEnt(entity,Prop_Data,"m_hController");
			if ((controller != 0) && (IsValidEntity(controller)))
			{
				if (HasEntProp(animprop,Prop_Data,"m_flPoseParameter"))
				{
					if (HasEntProp(animprop,Prop_Data,"m_hOwnerEntity")) SetEntPropEnt(animprop,Prop_Data,"m_hOwnerEntity",entity);
					float angs[3];
					float propang[3];
					float toang[3];
					float orgs[3];
					float shootvel[3];
					if (HasEntProp(animprop,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(animprop,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(animprop,Prop_Send,"m_vecOrigin")) GetEntPropVector(animprop,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(animprop,Prop_Data,"m_angAbsRotation")) GetEntPropVector(animprop,Prop_Data,"m_angAbsRotation",propang);
					char barrelfind[32];
					GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",toang);
					if ((controller > 0) && (controller < MaxClients+1))
					{
						GetClientEyeAngles(controller,toang);
						float fhitpos[3];
						float loc[3];
						loc[0] = (orgs[0] + (40 * Cosine(DegToRad(propang[1]))));
						loc[1] = (orgs[1] + (40 * Sine(DegToRad(propang[1]))));
						loc[2] = (orgs[2]);
						Handle hhitpos = INVALID_HANDLE;
						TR_TraceRayFilter(loc,toang,MASK_SOLID_BRUSHONLY,RayType_Infinite,TraceEntityFilter,animprop);
						TR_GetEndPosition(fhitpos,hhitpos);
						CloseHandle(hhitpos);
						MakeVectorFromPoints(orgs,fhitpos,shootvel);
						GetVectorAngles(shootvel,toang);
						toang[0]-=4.0;
					}
					else if (HasEntProp(controller,Prop_Data,"m_goalHeadDirection"))
					{
						int targ = -1;
						float enorg[3];
						if (HasEntProp(controller,Prop_Data,"m_hEnemy")) targ = GetEntPropEnt(controller,Prop_Data,"m_hEnemy");
						if (IsValidEntity(targ))
						{
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
							float loc[3];
							propang[1]-=30.0;
							loc[0] = (orgs[0] + (40 * Cosine(DegToRad(propang[1]))));
							loc[1] = (orgs[1] + (40 * Sine(DegToRad(propang[1]))));
							loc[2] = (orgs[2]);
							MakeVectorFromPoints(loc,enorg,shootvel);
							GetVectorAngles(shootvel,toang);
							toang[0]-=4.0;
							toang[0] = toang[0]*0.5;
						}
					}
					GetEntPropString(entity,Prop_Data,"m_iszBarrelAttachment",barrelfind,sizeof(barrelfind));
					float pose = GetEntPropFloat(animprop,Prop_Data,"m_flPoseParameter",0);
					float prevpose = pose;
					float posepitch = GetEntPropFloat(animprop,Prop_Data,"m_flPoseParameter",1);
					if (propang[1] > 180.0) propang[1]-=270.0;
					if (propang[1] < -180.0) propang[1]+=180.0;
					int attachfind = CreateEntityByName("prop_dynamic");
					if (attachfind != -1)
					{
						DispatchKeyValue(attachfind,"rendermode","10");
						DispatchKeyValue(attachfind,"solid","0");
						DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(attachfind);
						ActivateEntity(attachfind);
						SetVariantString("!activator");
						AcceptEntityInput(attachfind,"SetParent",animprop);
						SetVariantString(barrelfind);
						AcceptEntityInput(attachfind,"SetParentAttachment");
						if (HasEntProp(attachfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(attachfind,Prop_Data,"m_angAbsRotation",angs);
						AcceptEntityInput(attachfind,"kill");
					}
					//angs[1] = angs[1]-(360.0*pose);
					angs[1]+=propang[1];
					//angs[1]+=165.0;
					angs[0] = (90.0*posepitch)-30.0;
					//angs[0] = (180.0*posepitch)-110.0;
					if (toang[0] > 270.0) toang[0]-=180.0;
					if (toang[0] < 90.0) toang[0] = -1.0 * toang[0];
					if (toang[0] < -90) toang[0]+=180.0;
					if (toang[1] > 180.0+propang[1]) toang[1]-=180.0;
					//toang[1] = toang[1]*1.5;
					if (toang[0] > 8.0) toang[0] = 6.0;
					if (angs[1] > toang[1])
					{
						if (angs[1]-toang[1] < 90) pose+=0.02;
						else if (toang[1]-angs[1] > -90) pose-=0.02;
						else pose-=0.02;
					}
					else if (toang[1] > angs[1])
					{
						if ((toang[1]-angs[1] < 180) && (toang[1]-angs[1] > 90)) pose+=0.02;
						else if (angs[1]-toang[1] < 0) pose-=0.02;
						else pose+=0.02;
					}
					/*
					if (angs[1] > toang[1])
					{
						if (angs[1]-toang[1] > 180) pose+=0.02;
						else if (toang[1]-angs[1] < -180) pose+=0.02;
						else pose-=0.02;
					}
					else if (toang[1] > angs[1])
					{
						if (toang[1]-angs[1] > 180) pose-=0.02;
						else if (angs[1]-toang[1] < -180) pose-=0.02;
						else pose+=0.02;
					}
					*/
					if (angs[0] > toang[0])
					{
						if (angs[0]-toang[0] > 90) posepitch+=0.02;
						else if (toang[0]-angs[0] < -90) posepitch+=0.02;
						else posepitch-=0.02;
					}
					else if (toang[0] > angs[0])
					{
						if (toang[0]-angs[0] > 90) posepitch-=0.02;
						else if (angs[0]-toang[0] < -90) posepitch-=0.02;
						else posepitch+=0.02;
					}
					if ((angs[1] > -180.0) && (toang[1] < 0.0) && (controller > MaxClients)) angs[1]-=180.0;
					//PrintToServer("Toang %1.f %1.f %1.f CurAng %1.f %1.f %1.f sub %1.f %1.f",toang[0],toang[1],toang[2],angs[0],angs[1],angs[2],toang[0]-angs[0],angs[1]-toang[1]);
					if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)))
					{
						if (pose < prevpose) pose+=0.015;
						else pose-=0.015;
					}
					else if ((toang[1]-angs[1] < 15.0) || (angs[1]-toang[1] < 15.0))
					{
						if (pose < prevpose) pose+=0.0125;
						else pose-=0.0125;
					}
					bool withinradius = false;
					float diff = 3.0;
					if (((angs[1]-toang[1] > 174.0) && (angs[1]-toang[1] < 186.0) || ((toang[1]-angs[1] > 174.0) && (toang[1]-angs[1] < 186.0)))) diff = 184.0;
					if ((toang[1]-angs[1] > diff) || (angs[1]-toang[1] > diff))
					{
						if (pose < 0.00)
						{
							pose = 0.0;
						}
						else if (pose > 1.00)
						{
							pose = 1.0;
						}
						SetEntPropFloat(animprop,Prop_Data,"m_flPoseParameter",pose,0);
					}
					else if (controller > MaxClients)
					{
						withinradius++;
					}
					if ((toang[0]-angs[0] > 3.0) || (angs[0]-toang[0] > 3.0))
					{
						if (posepitch < 0.00)
						{
							posepitch = 0.0;
						}
						else if (posepitch > 1.00)
						{
							posepitch = 1.0;
						}
						SetEntPropFloat(animprop,Prop_Data,"m_flPoseParameter",posepitch,1);
					}
					int animset = GetEntProp(animprop,Prop_Data,"m_bClientSideAnimation");
					if (animset == 0) SetEntProp(animprop,Prop_Data,"m_bClientSideAnimation",1);
					else if (timesattacked[animprop] > 1)
					{
						SetEntProp(animprop,Prop_Data,"m_bClientSideAnimation",0);
						timesattacked[animprop] = 0;
					}
					timesattacked[animprop]++;
					ChangeEdictState(animprop);
					if (withinradius)
					{
						int targ = -1;
						if (HasEntProp(controller,Prop_Data,"m_hEnemy")) targ = GetEntPropEnt(controller,Prop_Data,"m_hEnemy");
						float Time = GetTickedTime();
						if ((centnextatk[entity] < Time) && (IsValidEntity(targ)))
						{
							char tankcls[32];
							GetEntityClassname(entity,tankcls,sizeof(tankcls));
							if (StrEqual(tankcls,"func_50cal",false))
							{
								int bulletmuzzle = CreateEntityByName("env_muzzleflash");
								if (bulletmuzzle != -1)
								{
									DispatchKeyValue(bulletmuzzle,"scale","0.8");
									TeleportEntity(bulletmuzzle,orgs,toang,NULL_VECTOR);
									DispatchSpawn(bulletmuzzle);
									ActivateEntity(bulletmuzzle);
									SetVariantString("!activator");
									AcceptEntityInput(bulletmuzzle,"SetParent",animprop);
									SetVariantString("muzzle");
									AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
									AcceptEntityInput(bulletmuzzle,"Fire");
									if (HasEntProp(bulletmuzzle,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(bulletmuzzle,Prop_Data,"m_vecAbsOrigin",orgs);
									else if (HasEntProp(bulletmuzzle,Prop_Send,"m_vecOrigin")) GetEntPropVector(bulletmuzzle,Prop_Send,"m_vecOrigin",orgs);
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,bulletmuzzle);
									WritePackString(dp2,"env_muzzleflash");
									CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
								}
								orgs[2]-=20.0;
								float fhitpos[3];
								Handle hhitpos = INVALID_HANDLE;
								TR_TraceRayFilter(orgs,toang,MASK_SHOT,RayType_Infinite,TraceEntityFilter,animprop);
								TR_GetEndPosition(fhitpos,hhitpos);
								CloseHandle(hhitpos);
								if (targ != -1)
								{
									if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",fhitpos);
									else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",fhitpos);
								}
								MakeVectorFromPoints(orgs,fhitpos,shootvel);
								int orb = CreateEntityByName("generic_actor");
								if (orb != -1)
								{
									DispatchKeyValue(orb,"rendermode","10");
									DispatchKeyValue(orb,"renderfx","6");
									DispatchKeyValue(orb,"rendercolor","0 0 0");
									DispatchKeyValue(orb,"renderamt","0");
									DispatchKeyValue(orb,"solid","6");
									DispatchKeyValue(orb,"modelscale","0.1");
									DispatchKeyValue(orb,"model","models/roller.mdl");
									ScaleVector(shootvel,3.0);
									TeleportEntity(orb,orgs,toang,NULL_VECTOR);
									DispatchSpawn(orb);
									ActivateEntity(orb);
									SetEntProp(orb,Prop_Data,"m_MoveType",4);
									SetEntProp(orb,Prop_Data,"m_nRenderMode",10);
									SetEntProp(orb,Prop_Data,"m_nRenderFX",6);
									if (HasEntProp(orb,Prop_Data,"m_bloodColor")) SetEntProp(orb,Prop_Data,"m_bloodColor",3);
									if (HasEntProp(orb,Prop_Data,"m_hEffectEntity")) SetEntPropEnt(orb,Prop_Data,"m_hEffectEntity",controller);
									SDKHook(orb, SDKHook_StartTouch, StartTouchBullet);
									SetEntProp(orb,Prop_Data,"m_iHealth",300);
									SetEntProp(orb,Prop_Data,"m_iMaxHealth",30);
									TeleportEntity(orb,NULL_VECTOR,NULL_VECTOR,shootvel);
									char snd[64];
									Format(snd,sizeof(snd),"weapons\\50cal\\single%i.wav",GetRandomInt(1,3));
									if ((bulletmuzzle != 0) && (IsValidEntity(bulletmuzzle))) EmitSoundToAll(snd, bulletmuzzle, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									else EmitSoundToAll(snd, animprop, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,orb);
									WritePackString(dp2,"generic_actor");
									CreateTimer(2.0,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
									int silvertrail = CreateEntityByName("env_spritetrail");
									DispatchKeyValue(silvertrail,"lifetime","0.2");
									DispatchKeyValue(silvertrail,"startwidth","8.0");
									DispatchKeyValue(silvertrail,"endwidth","6.0");
									DispatchKeyValue(silvertrail,"spritename","sprites/bluelaser1.vmt");
									DispatchKeyValue(silvertrail,"renderamt","255");
									DispatchKeyValue(silvertrail,"rendermode","5");
									DispatchKeyValue(silvertrail,"rendercolor","50 35 35");
									TeleportEntity(silvertrail,orgs,toang,NULL_VECTOR);
									DispatchSpawn(silvertrail);
									ActivateEntity(silvertrail);
									SetVariantString("!activator");
									AcceptEntityInput(silvertrail,"SetParent",orb);
								}
								centnextatk[entity] = Time+0.2;
							}
							else if (StrEqual(tankcls,"func_tow",false))
							{
								int bulletmuzzle = CreateEntityByName("env_muzzleflash");
								if (bulletmuzzle != -1)
								{
									DispatchKeyValue(bulletmuzzle,"scale","1.0");
									DispatchSpawn(bulletmuzzle);
									ActivateEntity(bulletmuzzle);
									SetVariantString("!activator");
									AcceptEntityInput(bulletmuzzle,"SetParent",animprop);
									SetVariantString("muzzle");
									AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
									AcceptEntityInput(bulletmuzzle,"Fire");
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,bulletmuzzle);
									WritePackString(dp2,"env_muzzleflash");
									CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
									if (HasEntProp(bulletmuzzle,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(bulletmuzzle,Prop_Data,"m_vecAbsOrigin",orgs);
									else if (HasEntProp(bulletmuzzle,Prop_Send,"m_vecOrigin")) GetEntPropVector(bulletmuzzle,Prop_Send,"m_vecOrigin",orgs);
									GetEntPropVector(bulletmuzzle,Prop_Data,"m_angAbsRotation",angs);
								}
								int rpg = CreateEntityByName("rpg_missile");
								if (rpg != -1)
								{
									float loc[3];
									loc[0] = (orgs[0] + (20 * Cosine(DegToRad(angs[1]))));
									loc[1] = (orgs[1] + (20 * Sine(DegToRad(angs[1]))));
									loc[2] = (orgs[2]);
									TeleportEntity(rpg,loc,angs,NULL_VECTOR);
									DispatchSpawn(rpg);
									ActivateEntity(rpg);
									SetEntProp(rpg,Prop_Data,"m_MoveType",4);
									SetEntPropEnt(rpg,Prop_Data,"m_hOwnerEntity",controller);
									SetEntPropFloat(rpg,Prop_Data,"m_flDamage",300.0);
								}
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\tow\\single1.wav");
								if ((bulletmuzzle != 0) && (IsValidEntity(bulletmuzzle))) EmitSoundToAll(snd, bulletmuzzle, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								else EmitSoundToAll(snd, animprop, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								centnextatk[entity] = Time+3.0;
							}
						}
					}
				}
			}
		}
	}
}

public int findtrack(int ent, char[] cls, char[] targn)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		char name[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",name,sizeof(name));
		if (StrEqual(name,targn)) return thisent;
		findtrack(thisent++,cls,targn);
	}
	return -1;
}

public Action notkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidEntity(victim))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action scihl1tkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ((IsValidEntity(victim)) && (damage > 1.0))
	{
		if (FileExists("sound/scientist/sci_pain1.wav",true,NULL_STRING))
		{
			char snd[64];
			Format(snd,sizeof(snd),"scientist\\sci_pain%i.wav",GetRandomInt(1,10));
			EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
		}
	}
}

void findmovechild(int ent)
{
	int thisent = FindEntityByClassname(ent,"prop_dynamic");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if ((HasEntProp(thisent,Prop_Data,"m_nRenderMode")) && (HasEntProp(thisent,Prop_Data,"m_hParent")))
		{
			int parchk = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
			int rendermd = GetEntProp(thisent,Prop_Data,"m_nRenderMode");
			if ((rendermd == 10) && (parchk == -1))
				AcceptEntityInput(thisent,"kill");
		}
		findmovechild(thisent++);
	}
}

public Action StartTouchBullet(int entity, int other)
{
	if (IsValidEntity(other))
	{
		char clschk[24];
		GetEntityClassname(other,clschk,sizeof(clschk));
		bool dmg = true;
		int effectent = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if ((effectent != 0) && (IsValidEntity(effectent)))
		{
			char ownerchk[32];
			GetEntityClassname(effectent,ownerchk,sizeof(ownerchk));
			//if (((StrEqual(ownerchk,"npc_abrams",false)) || (StrEqual(ownerchk,"npc_human_assassin",false)) || (StrEqual(ownerchk,"npc_sentry_ground",false)) || (StrEqual(ownerchk,"npc_sentry_ceiling",false))) && ((!StrEqual(clschk,"npc_human_grunt",false)) && (!StrEqual(clschk,"npc_sentry_ground",false)) && (!StrEqual(clschk,"npc_human_commander",false)) && (!StrEqual(clschk,"npc_human_medic",false)) && (!StrEqual(clschk,"npc_human_grenadier",false)) && (!StrEqual(clschk,"npc_human_assassin",false))) && (!StrEqual(ownerchk,clschk,false)))
			if ((StrEqual(ownerchk,clschk,false)) || (effectent == other))
				dmg = false;
		}
		if ((dmg) && (other != 0))
		{
			float damageForce[3];
			float dmgset = 5.0;
			if (HasEntProp(entity,Prop_Data,"m_iMaxHealth"))
			{
				int dmgi = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
				dmgset+=dmgi;
			}
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_BULLET,-1,damageForce);
		}
		AcceptEntityInput(entity,"kill");
	}
}

public Action resetmdl(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char mdl[128];
		char clschk[32];
		ReadPackString(dp,mdl,sizeof(mdl));
		int ent = ReadPackCell(dp);
		ReadPackString(dp,clschk,sizeof(clschk));
		CloseHandle(dp);
		if ((IsValidEntity(ent)) && (ent > MaxClients))
		{
			char clsname[32];
			GetEntityClassname(ent,clsname,sizeof(clsname));
			if (!StrEqual(clsname,clschk,false)) return Plugin_Handled;
			if (!IsModelPrecached(mdl)) PrecacheModel(mdl,true);
			char szChkMdl[128];
			GetEntPropString(ent,Prop_Data,"m_ModelName",szChkMdl,sizeof(szChkMdl));
			if (StrEqual(szChkMdl,mdl,false)) return Plugin_Handled;
			SetEntPropString(ent,Prop_Data,"m_ModelName",mdl);
			DispatchKeyValue(ent,"model",mdl);
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
			if ((StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"monster_alien_grunt",false)) || (StrEqual(clsname,"npc_alien_grunt_unarmored",false)) || (StrEqual(clsname,"monster_gargantua",false)) || (StrEqual(clsname,"npc_alien_slave",false)) || (StrEqual(clsname,"npc_ichthyosaur",false)) || (StrEqual(clsname,"monster_ichthyosaur",false)))
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
			if (StrEqual(clsname,"npc_gonarch",false))
			{
				float vMins[3];
				float vMaxs[3];
				vMins[0] = -30.0; //-13
				vMins[1] = -30.0;
				vMins[2] = 0.0;
				vMaxs[0] = 30.0;
				vMaxs[1] = 30.0;
				vMaxs[2] = 72.0;
				SetEntPropVector(ent,Prop_Data,"m_vecMins",vMins);
				SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vMaxs);
				if (FindStringInArray(precachedarr,"npc_gonarch") == -1)
				{
					recursion("sound/gonarch/");
					PushArrayString(precachedarr,"npc_gonarch");
				}
				if (!IsModelPrecached("*1")) PrecacheModel("*1",true);
				int brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("LEG2_U");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -60.0;
					vMins[1] = -8.2;
					vMins[2] = -14.1;
					vMaxs[0] = 2.0;
					vMaxs[1] = 7.9;
					vMaxs[2] = 14.1;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("LEG_U");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -60.0;
					vMins[1] = -8.2;
					vMins[2] = -14.1;
					vMaxs[0] = 2.0;
					vMaxs[1] = 7.9;
					vMaxs[2] = 14.1;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("LEG2");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -94.0;
					vMins[1] = -10.0;
					vMins[2] = -13.99;
					vMaxs[0] = 26.0;
					vMaxs[1] = 10.0;
					vMaxs[2] = 14.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("LEG");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -94.0;
					vMins[1] = -10.0;
					vMins[2] = -13.99;
					vMaxs[0] = 26.0;
					vMaxs[1] = 10.0;
					vMaxs[2] = 14.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("ARM2_U");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -60.0;
					vMins[1] = -8.2;
					vMins[2] = -14.0;
					vMaxs[0] = 2.0;
					vMaxs[1] = 7.9;
					vMaxs[2] = 14.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("ARM_U");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -60.0;
					vMins[1] = -8.2;
					vMins[2] = -14.0;
					vMaxs[0] = 2.0;
					vMaxs[1] = 7.9;
					vMaxs[2] = 14.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("ARM");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -94.0;
					vMins[1] = -10.0;
					vMins[2] = -13.99;
					vMaxs[0] = 26.0;
					vMaxs[1] = 10.0;
					vMaxs[2] = 14.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("ARM2");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -94.0;
					vMins[1] = -10.0;
					vMins[2] = -13.99;
					vMaxs[0] = 26.0;
					vMaxs[1] = 10.0;
					vMaxs[2] = 14.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("UP");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -77.0;
					vMins[1] = -35.0;
					vMins[2] = -77.0;
					vMaxs[0] = 77.0;
					vMaxs[1] = 35.0;
					vMaxs[2] = 77.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				brushes = CreateEntityByName("func_brush");
				if (brushes != -1)
				{
					DispatchKeyValue(brushes,"model","*1");
					DispatchKeyValue(brushes,"spawnflags","2");
					DispatchKeyValue(brushes,"startdisabled","0");
					DispatchKeyValue(brushes,"excludednpc","npc_gonarch");
					DispatchKeyValue(brushes,"solidbsp","1");
					DispatchKeyValue(brushes,"Solidity","2");
					DispatchKeyValue(brushes,"rendermode","10");
					DispatchSpawn(brushes);
					ActivateEntity(brushes);
					SetVariantString("!activator");
					AcceptEntityInput(brushes,"SetParent",ent);
					SetVariantString("Down");
					AcceptEntityInput(brushes,"SetParentAttachment");
					vMins[0] = -27.0;
					vMins[1] = -50.5;
					vMins[2] = -27.0;
					vMaxs[0] = 27.0;
					vMaxs[1] = 50.5;
					vMaxs[2] = 27.0;
					SetEntPropVector(brushes,Prop_Send,"m_vecMins",vMins);
					SetEntPropVector(brushes,Prop_Send,"m_vecMaxs",vMaxs);
				}
				SDKHookEx(ent,SDKHook_Think,gonarchthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,gonarchtkdmg);
			}
			else if ((StrEqual(clsname,"npc_babycrab",false)) || (StrEqual(clsname,"npc_snark",false)) || (StrEqual(clsname,"monster_snark",false)))
			{
				SetEntProp(ent,Prop_Data,"m_nRenderMode",0);
				SetEntProp(ent,Prop_Data,"m_nRenderFX",0);
				SetVariantString("rendercolor 255 255 255");
				AcceptEntityInput(ent,"AddOutput");
				SetVariantString("renderamt 255");
				AcceptEntityInput(ent,"AddOutput");
			}
		}
	}
	return Plugin_Handled;
}

public Action resethealth(Handle timer, int ent)
{
	if ((IsValidEntity(ent)) && (ent > MaxClients))
	{
		char cvarchk[32];
		char clsname[32];
		GetEntityClassname(ent,clsname,sizeof(clsname));
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
	return Plugin_Handled;
}

public Action resetorgs(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int ent = ReadPackCell(dp);
		float orgs[3];
		orgs[0] = ReadPackFloat(dp);
		orgs[1] = ReadPackFloat(dp);
		orgs[2] = ReadPackFloat(dp);
		CloseHandle(dp);
		if (IsValidEntity(ent))
		{
			if (HasEntProp(ent,Prop_Data,"m_MoveType")) SetEntProp(ent,Prop_Data,"m_MoveType",5);
			char cls[32];
			GetEntityClassname(ent,cls,sizeof(cls));
			TeleportEntity(ent,orgs,NULL_VECTOR,NULL_VECTOR);
			if (StrEqual(cls,"npc_sentry_ceiling",false))
			{
				int maxh = GetEntProp(ent,Prop_Data,"m_iMaxHealth");
				Handle cvar = FindConVar("sk_sentry_ceiling_health");
				if (cvar != INVALID_HANDLE)
				{
					int maxhchk = GetConVarInt(cvar);
					if (maxh != maxhchk)
					{
						SetEntProp(ent,Prop_Data,"m_iHealth",maxhchk);
						SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxhchk);
					}
				}
				CloseHandle(cvar);
			}
		}
	}
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
	char entname[64];
	int killed = GetEventInt(event, "entindex_killed");
	int attacker = GetEventInt(event, "entindex_attacker");
	int inflictor = GetEventInt(event, "entindex_inflictor");
	if (killed > 0)
	{
		isattacking[killed] = 0;
		centnextatk[killed] = 0.0;
	}
	if ((killed < MaxClients+1) && (killed > 0))
	{
		fadingtime[killed] = 0.0;
		antispamchk[killed] = 0.0;
		CreateTimer(0.1,checkvalidity,killed);
	}
	if (attacker > MaxClients)
	{
		GetEntityClassname(attacker, atk, sizeof(atk));
	}
	GetEntityClassname(killed, clsname, sizeof(clsname));
	GetEntityClassname(inflictor, clsname2, sizeof(clsname2));
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
	if (StrEqual(atk,"npc_human_security",false))
	{
		if (FileExists("sound/vo/npc/barneys/gotone01.wav",true,NULL_STRING))
		{
			char snd[64];
			if ((StrEqual(clsname,"npc_bullsquid",false)) || (StrEqual(clsname,"monster_bullchicken",false)))
			{
				Format(snd,sizeof(snd),"vo\\npc\\barneys\\bullsquid_dead0%i.wav",GetRandomInt(1,2));
				EmitSoundToAll(snd, attacker, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			}
			else
			{
				int randgot = GetRandomInt(1,12);
				if (randgot < 10) Format(snd,sizeof(snd),"vo\\npc\\barneys\\gotone0%i.wav",randgot);
				else Format(snd,sizeof(snd),"vo\\npc\\barneys\\gotone%i.wav",randgot);
				EmitSoundToAll(snd, attacker, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			}
		}
	}
	if ((StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"monster_houndeye",false)))
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
		/*
		Handle ragdollchk = FindConVar("ai_force_serverside_ragdoll");
		if (ragdollchk != INVALID_HANDLE)
		{
			char mdlset[64];
			GetEntPropString(killed,Prop_Data,"m_ModelName",mdlset,sizeof(mdlset));
			if (strlen(mdlset) > 0)
			{
				int ragdollmade = GetConVarInt(ragdollchk);
				if (ragdollmade == 0)
				{
					int ragdoll = CreateEntityByName("prop_ragdoll");
					if (ragdoll != -1)
					{
						float mdlscale = GetEntPropFloat(killed,Prop_Data,"m_flModelScale");
						mdlscale+=0.4;
						char mdlscalech[16];
						Format(mdlscalech,sizeof(mdlscalech),"%f",mdlscale);
						float orgs[3];
						float angs[3];
						if (HasEntProp(killed,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(killed,Prop_Data,"m_vecAbsOrigin",orgs);
						else if (HasEntProp(killed,Prop_Send,"m_vecOrigin")) GetEntPropVector(killed,Prop_Send,"m_vecOrigin",orgs);
						GetEntPropVector(killed,Prop_Data,"m_angRotation",angs);
						int body = GetEntProp(killed,Prop_Data,"m_nBody");
						char bodych[4];
						Format(bodych,sizeof(bodych),"%i",body);
						int skin = GetEntProp(killed,Prop_Data,"m_nSkin");
						char skinch[4];
						Format(skinch,sizeof(skinch),"%i",skin);
						DispatchKeyValue(ragdoll,"model",mdlset);
						DispatchKeyValue(ragdoll,"modelscale",mdlscalech);
						DispatchKeyValue(ragdoll,"spawnflags","4");
						//DispatchKeyValue(ragdoll,"solid","6");
						DispatchKeyValue(ragdoll,"skin",skinch);
						DispatchKeyValue(ragdoll,"body",bodych);
						DispatchKeyValue(ragdoll,"fadescale","1");
						DispatchKeyValue(ragdoll,"fademindist","-1");
						DispatchKeyValue(ragdoll,"StartDisabled","0");
						TeleportEntity(ragdoll,orgs,angs,NULL_VECTOR);
						SetEntPropString(ragdoll,Prop_Data,"m_strSourceClassName","npc_houndeye");
						DispatchSpawn(ragdoll);
						ActivateEntity(ragdoll);
					}
				}
			}
		}
		CloseHandle(ragdollchk);
		*/
	}
	else if ((StrEqual(clsname,"npc_bullsquid",false)) || (StrEqual(clsname,"monster_bullchicken",false)))
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
	else if (StrEqual(clsname,"npc_sentry_ceiling",false))
	{
		if (HasEntProp(killed,Prop_Data,"m_hEffectEntity"))
		{
			int mdl = GetEntPropEnt(killed,Prop_Data,"m_hEffectEntity");
			if ((mdl != 0) && (IsValidEntity(mdl))) AcceptEntityInput(mdl,"kill");
		}
	}
	else if (StrEqual(clsname,"npc_babycrab",false))
	{
		if (HasEntProp(killed,Prop_Data,"m_hEffectEntity"))
		{
			int gonarch = GetEntPropEnt(killed,Prop_Data,"m_hEffectEntity");
			if ((IsValidEntity(gonarch)) && (gonarch != 0))
			{
				if (timesattacked[gonarch] > 0) timesattacked[gonarch]--;
			}
		}
	}
	else if (StrEqual(clsname,"npc_zombie_security",false))
	{
		char mdl[64];
		GetEntPropString(killed,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
		if (StrEqual(mdl,"models/zombie/zombie_soldier.mdl",false))
		{
			if (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING))
				SetEntityModel(killed,"models/zombie/zsecurity.mdl");
			else
				SetEntityModel(killed,"models/zombies/zombie_guard.mdl");
			AcceptEntityInput(killed,"BecomeRagdoll");
		}
	}
	if ((HasEntProp(killed,Prop_Data,"m_iName")) && (StrContains(clsname,"npc_",false) != -1))
	{
		GetEntPropString(killed,Prop_Data,"m_iName",entname,sizeof(entname));
		if (FindStringInArray(entnames,entname) == -1) PushArrayString(entnames,entname);
	}
	if (StrEqual(clsname,"npc_abrams",false))
	{
		findmovechild(-1);
		float orgs[3];
		float angs[3];
		if (HasEntProp(killed,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(killed,Prop_Data,"m_vecAbsOrigin",orgs);
		else if (HasEntProp(killed,Prop_Send,"m_vecOrigin")) GetEntPropVector(killed,Prop_Send,"m_vecOrigin",orgs);
		if (HasEntProp(killed,Prop_Send,"m_angRotation")) GetEntPropVector(killed,Prop_Data,"m_angRotation",angs);
		int smokeeff = CreateEntityByName("env_ar2explosion");
		if (smokeeff != -1)
		{
			DispatchKeyValue(smokeeff,"material","particle/particle_noisesphere");
			TeleportEntity(smokeeff,orgs,angs,NULL_VECTOR);
			DispatchSpawn(smokeeff);
			ActivateEntity(smokeeff);
			AcceptEntityInput(smokeeff,"Explode");
			Handle dp = CreateDataPack();
			WritePackCell(dp,smokeeff);
			WritePackString(dp,"env_ar2explosion");
			CreateTimer(0.1,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
		}
		int prop = CreateEntityByName("prop_physics");
		if (prop != -1)
		{
			DispatchKeyValue(prop,"solid","6");
			DispatchKeyValue(prop,"model","models/gibs/m1a1_abrams_gibs/m1_gib_base.mdl");
			TeleportEntity(prop,orgs,angs,NULL_VECTOR);
			DispatchSpawn(prop);
			ActivateEntity(prop);
		}
		prop = CreateEntityByName("prop_physics");
		if (prop != -1)
		{
			orgs[2]+=70.0;
			DispatchKeyValue(prop,"solid","6");
			DispatchKeyValue(prop,"model","models/gibs/m1a1_abrams_gibs/m1_gib_turret.mdl");
			TeleportEntity(prop,orgs,angs,NULL_VECTOR);
			DispatchSpawn(prop);
			ActivateEntity(prop);
		}
		AcceptEntityInput(killed,"kill");
	}
	else if (StrEqual(clsname,"npc_osprey",false))
	{
		int animprop = GetEntPropEnt(killed,Prop_Data,"m_hOwnerEntity");
		int parent = GetEntPropEnt(killed,Prop_Data,"m_hParent");
		if ((animprop != 0) && (IsValidEntity(animprop)))
		{
			int soundent = GetEntPropEnt(animprop,Prop_Data,"m_hEffectEntity");
			if ((soundent != 0) && (IsValidEntity(soundent)))
			{
				SetVariantString("0");
				AcceptEntityInput(soundent,"Volume");
				AcceptEntityInput(soundent,"StopSound");
				Handle dp = CreateDataPack();
				WritePackCell(dp,soundent);
				WritePackString(dp,"ambient_generic");
				CreateTimer(0.5,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		float orgs[3];
		float angs[3];
		if (HasEntProp(killed,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(killed,Prop_Data,"m_vecAbsOrigin",orgs);
		else if (HasEntProp(killed,Prop_Send,"m_vecOrigin")) GetEntPropVector(killed,Prop_Send,"m_vecOrigin",orgs);
		if ((parent != 0) && (IsValidEntity(parent)))
			if (HasEntProp(parent,Prop_Send,"m_angRotation")) GetEntPropVector(parent,Prop_Data,"m_angRotation",angs);
		int smokeeff = CreateEntityByName("env_ar2explosion");
		if (smokeeff != -1)
		{
			DispatchKeyValue(smokeeff,"material","particle/particle_noisesphere");
			TeleportEntity(smokeeff,orgs,angs,NULL_VECTOR);
			DispatchSpawn(smokeeff);
			ActivateEntity(smokeeff);
			AcceptEntityInput(smokeeff,"Explode");
			Handle dp = CreateDataPack();
			WritePackCell(dp,smokeeff);
			WritePackString(dp,"env_ar2explosion");
			CreateTimer(0.1,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
		}
		int prop = CreateEntityByName("prop_physics");
		if (prop != -1)
		{
			DispatchKeyValue(prop,"solid","6");
			DispatchKeyValue(prop,"model","models/gibs/v22_gibs/v22_gib_fuselage.mdl");
			TeleportEntity(prop,orgs,angs,NULL_VECTOR);
			DispatchSpawn(prop);
			ActivateEntity(prop);
		}
		if ((parent != 0) && (IsValidEntity(parent)))
		{
			char parcls[32];
			GetEntityClassname(parent,parcls,sizeof(parcls));
			if (StrEqual(parcls,"func_tracktrain",false)) AcceptEntityInput(parent,"kill");
		}
		AcceptEntityInput(killed,"kill");
	}
	else if ((StrEqual(clsname,"generic_actor",false)) || (StrEqual(clsname,"prop_physics",false)))
	{
		char mdl[64];
		if (HasEntProp(killed,Prop_Data,"m_ModelName"))
		{
			GetEntPropString(killed,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if ((StrEqual(mdl,"models/roller.mdl",false)) || (StrContains(mdl,"models/xen_props/gib/gon_spit",false) == 0))
				AcceptEntityInput(killed,"kill");
		}
	}
	else if (StrEqual(clsname,"npc_hornet",false))
	{
		AcceptEntityInput(killed,"kill");
	}
	else if ((StrEqual(clsname,"npc_alien_slave",false)) || (StrEqual(clsname,"npc_alien_controller",false)) || (StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"monster_alien_grunt",false)))
	{
		int propset;
		if (RoundFloat(centlastang[killed]) > 0) propset = RoundFloat(centlastang[killed]);
		if ((IsValidEntity(propset)) && (propset != 0))
		{
			char propcls[32];
			GetEntityClassname(propset,propcls,sizeof(propcls));
			if (StrEqual(propcls,"prop_dynamic",false))
			{
				AcceptEntityInput(propset,"kill");
				centlastang[killed] = 0.0;
			}
		}
		else if (HasEntProp(killed,Prop_Data,"m_hEffectEntity"))
		{
			propset = GetEntPropEnt(killed,Prop_Data,"m_hEffectEntity");
			if ((IsValidEntity(propset)) && (propset != 0))
			{
				char propcls[32];
				GetEntityClassname(propset,propcls,sizeof(propcls));
				if (StrEqual(propcls,"prop_dynamic",false))
					AcceptEntityInput(propset,"kill");
			}
		}
	}
	if ((inflictor < MaxClients+1) && (inflictor > 0)) attacker = inflictor;
	if ((attacker < MaxClients+1) && (attacker > 0))
	{
		if (IsClientInGame(attacker))
		{
			if (StrEqual(clsname,"npc_human_scientist",false))
			{
				Handle sci = CreateArray(256);
				FindAllByClassname(sci,-1,"npc_human_scientist");
				if (GetArraySize(sci) > 0)
				{
					float orgs[3];
					float sciorgs[3];
					if (HasEntProp(attacker,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(attacker,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(attacker,Prop_Send,"m_vecOrigin")) GetEntPropVector(attacker,Prop_Send,"m_vecOrigin",orgs);
					for (int i = 0;i<GetArraySize(sci);i++)
					{
						int j = GetArrayCell(sci,i);
						if ((IsValidEntity(j)) && (killed != j))
						{
							if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",sciorgs);
							else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",sciorgs);
							float chkdist = GetVectorDistance(sciorgs,orgs,false);
							if (chkdist < 512.0)
							{
								char snd[64];
								switch(GetRandomInt(1,11))
								{
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp01_sp03.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp02_sp03.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp03_sp03.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp04_sp03.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp04_sp03_take02.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp05_sp03.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp06_sp03.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp07_sp03.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp08_sp03_take01.wav");
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp08_sp03_take02.wav");
									case 11:
										Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\heretohelp09_sp03.wav");
								}
								if (strlen(snd) > 0)
								{
									EmitSoundToAll(snd, j, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									EmitCC(j,snd,512.0);
								}
								break;
							}
						}
					}
				}
				CloseHandle(sci);
			}
			bool CustEventSet = false;
			int viccol = -1052689;
			if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_grenadier",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_abrams",false)))
			{
				viccol = -6921216;
			}
			else if (StrEqual(clsname,"npc_bullseye",false))
			{
				CustEventSet = true;
				if (StrEqual(entname,"dra_bull_eye",false))
				{
					Format(clsname,sizeof(clsname),"npc_doramn_window");
				}
				else if (StrEqual(entname,"dra_bull",false))
				{
					Format(clsname,sizeof(clsname),"npc_doramn_power_cell");
				}
				else CustEventSet = false;
			}
			else if ((StrContains(clsname,"npc_zombie_",false) != -1) || (StrEqual(clsname,"npc_babycrab",false)) || (StrEqual(clsname,"npc_gonarch",false)))
			{
				viccol = -16777041;
			}
			else if ((StrEqual(clsname,"npc_ichthyosaur",false)) || (StrEqual(clsname,"monster_ichthyosaur",false)))
			{
				viccol = -16732161;
				EmitSoundToAll("npc\\ichthyosaur\\die1.wav", killed, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				CustEventSet = true;
			}
			else if (StrEqual(clsname,"npc_bmsgargantua",false))
			{
				float orgs[3];
				float angs[3];
				if (HasEntProp(killed,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(killed,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(killed,Prop_Data,"m_vecOrigin")) GetEntPropVector(killed,Prop_Data,"m_vecOrigin",orgs);
				if (HasEntProp(killed,Prop_Data,"m_angRotation")) GetEntPropVector(killed,Prop_Data,"m_angRotation",angs);
				EmitAmbientSound("npc\\garg\\garg_beam_start.wav", orgs, killed, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
				EmitAmbientSound("npc\\garg\\garg_beam_stop.wav", orgs, killed, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
				for (int i = 0;i<4;i++)
				{
					if ((IsValidEntity(gargfiretarg[killed][i])) && (gargfiretarg[killed][i] != 0))
					{
						AcceptEntityInput(gargfiretarg[killed][i],"kill");
						gargfiretarg[killed][i] = 0;
					}
				}
				int mdlset = GetEntPropEnt(killed,Prop_Data,"m_hEffectEntity");
				if (IsValidEntity(mdlset))
				{
					isattacking[mdlset] = 5;
				}
				RunSeq(killed,orgs,angs,"powerup_electrocute","",0,true);
				CreateTimer(7.2,DissolveGarg,killed,TIMER_FLAG_NO_MAPCHANGE);
				viccol = -16732161;
				EmitSoundToAll("npc\\garg\\garg_die1.wav", killed, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				Format(clsname,sizeof(clsname),"npc_gargantua");
				CustEventSet = true;
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
			if (((FindStringInArray(customentlist,clsname) != -1) || (CustEventSet)) && (!StrEqual(clsname,"monster_alien_grunt",false)) && (!StrEqual(clsname,"monster_gargantua",false)))
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
				else if (StrEqual(weap,"weapon_rpg",false))
				{
					Format(weap,sizeof(weap),"rpg_missile");
				}
				else
				{
					ReplaceString(weap,sizeof(weap),"weapon_","",false);
				}
				//PrintToServer("%i killed %s with weap %s atk %s cls2 %s",attacker,clsname,weap,atk,clsname2);
				if ((StrEqual(weap,"player",false)) && (StrEqual(atk,"rpg_missile",false)))
				{
					Format(weap,sizeof(weap),"rpg_missile");
				}
				else if (StrEqual(atk,"npc_grenade_frag",false))
				{
					Format(weap,sizeof(weap),"grenade_frag");
				}
				if (StrEqual(weap,"crossbow",false)) Format(weap,sizeof(weap),"crossbow_bolt");
				else if (StrEqual(weap,"glock",false)) Format(weap,sizeof(weap),"pistol");
				else if (StrEqual(weap,"mp5",false)) Format(weap,sizeof(weap),"smg1");
				SetEventString(entkilled,"weapon",weap);
				SetEventInt(entkilled,"killerID",attacker);
				SetEventInt(entkilled,"victimID",killed);
				SetEventBool(entkilled,"suicide",false);
				char tmpchar[96];
				GetClientName(attacker,tmpchar,sizeof(tmpchar));
				SetEventString(entkilled,"killername",tmpchar);
				ReplaceString(clsname,sizeof(clsname),"npc_","",false);
				ReplaceString(clsname,sizeof(clsname),"monster_","",false);
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

public Action Event_SynEntityKilled(Handle event, const char[] name, bool Broadcast)
{
	char killername[64];
	GetEventString(event,"killername",killername,sizeof(killername));
	int killed = GetEventInt(event, "victimID");
	if (strlen(killername) < 1)
	{
		int attacker = GetEventInt(event,"killerID");
		if ((IsValidEntity(attacker)) && (attacker != 0) && (killed > 0) && (killed < MaxClients+1))
		{
			char clsname[64];
			char weap[64];
			char plyname[64];
			GetClientName(killed,plyname,sizeof(plyname));
			GetEntityClassname(attacker,clsname,sizeof(clsname));
			if ((StrEqual(clsname,"generic_actor",false)) || (StrEqual(clsname,"env_explosion",false)))
			{
				char targn[64];
				if (HasEntProp(attacker,Prop_Data,"m_iName")) GetEntPropString(attacker,Prop_Data,"m_iName",targn,sizeof(targn));
				int effectent = GetEntPropEnt(attacker,Prop_Data,"m_hEffectEntity");
				if ((effectent != 0) && (IsValidEntity(effectent)))
				{
					char clschk[32];
					GetEntityClassname(effectent,clschk,sizeof(clschk));
					if (StrContains(clschk,"npc_",false) == 0)
					{
						Format(clsname,sizeof(clsname),"%s",clschk);
					}
					else if (StrEqual(clschk,"trigger_once",false))
					{
						Format(clsname,sizeof(clsname),"Mine");
					}
					else if (FindValueInArray(tentsmdl,effectent) != -1)
					{
						Format(clsname,sizeof(clsname),"Tentacle");
					}
				}
				if (StrEqual(targn,"syn_tripmineexpl",false))
				{
					Format(clsname,sizeof(clsname),"Trip Mine");
				}
				else if (StrEqual(targn,"syn_mortarexpl",false))
				{
					Format(clsname,sizeof(clsname),"Mortar");
				}
			}
			else if (StrEqual(clsname,"trigger_hurt",false))
			{
				if (HasEntProp(attacker,Prop_Data,"m_bitsDamageInflict"))
				{
					if (HasEntProp(attacker,Prop_Data,"m_hParent"))
					{
						int parent = GetEntPropEnt(attacker,Prop_Data,"m_hParent");
						if (IsValidEntity(parent))
						{
							char parcls[32];
							GetEntityClassname(parent,parcls,sizeof(parcls));
							if (StrEqual(parcls,"func_tracktrain",false))
							{
								Format(clsname,sizeof(clsname),"Train");
							}
						}
					}
					int damagetype = GetEntProp(attacker,Prop_Data,"m_bitsDamageInflict");
					if (damagetype == 1) Format(clsname,sizeof(clsname),"Crushed");
					else if (damagetype == 4) Format(clsname,sizeof(clsname),"Sliced");
					else if (damagetype == 8) Format(clsname,sizeof(clsname),"Fire");
					else if (damagetype == 16) Format(clsname,sizeof(clsname),"Frozen");
					else if (damagetype == 32) Format(clsname,sizeof(clsname),"Gravity");
					else if (damagetype == 64) Format(clsname,sizeof(clsname),"Blast");
					else if (damagetype == 256) Format(clsname,sizeof(clsname),"Shock");
					else if (damagetype == 512) Format(clsname,sizeof(clsname),"Sonic");
					else if (damagetype == 1024) Format(clsname,sizeof(clsname),"Energy Beam");
					else if (damagetype == 16384) Format(clsname,sizeof(clsname),"Drown");
					else if (damagetype == 32768) Format(clsname,sizeof(clsname),"Paralyse");
					else if (damagetype == 65536) Format(clsname,sizeof(clsname),"Nerve Gas");
					else if (damagetype == 131072) Format(clsname,sizeof(clsname),"Poison");
					else if (damagetype == 262144) Format(clsname,sizeof(clsname),"Radiation");
					else if (damagetype == 1048576) Format(clsname,sizeof(clsname),"Chemical");
					else if (damagetype == 2097152) Format(clsname,sizeof(clsname),"Slow Burn");
					else if (damagetype == 4194304) Format(clsname,sizeof(clsname),"Slow Freeze");
				}
			}
			int viccol = -1052689;
			if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_grenadier",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_abrams",false)) || (StrEqual(clsname,"npc_combinegunship")))
			{
				viccol = -6921216;
			}
			else if ((StrContains(clsname,"npc_zombie_",false) != -1) || (StrEqual(clsname,"npc_babycrab",false)) || (StrEqual(clsname,"npc_gonarch",false)))
			{
				viccol = -16777041;
			}
			else if ((StrEqual(clsname,"npc_ichthyosaur",false)) || (StrEqual(clsname,"monster_ichthyosaur",false)) || (StrEqual(clsname,"npc_bmsgargantua",false)))
			{
				viccol = -16732161;
			}
			else if (StrEqual(clsname,"npc_snark",false))
			{
				viccol = -16732161;
			}
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
			if (StrEqual(clsname,"Combinegunship",false)) Format(clsname,sizeof(clsname),"Combine Gunship");
			if (HasEntProp(attacker,Prop_Data,"m_hActiveWeapon"))
			{
				int weapindx = GetEntPropEnt(attacker,Prop_Data,"m_hActiveWeapon");
				if ((weapindx != 0) && (IsValidEntity(weapindx)))
				{
					GetEntityClassname(weapindx,weap,sizeof(weap));
					if (StrContains(weap,"npc_",false) != -1)
					{
						Format(weap,sizeof(weap),"%s",clsname);
						ReplaceString(weap,sizeof(weap),"npc_","",false);
					}
					else if (StrEqual(weap,"prop_physics",false))
					{
						ReplaceString(weap,sizeof(weap),"prop_","",false);
					}
					if (strlen(weap) < 1)
						Format(weap,sizeof(weap),"hands");
					else if (StrEqual(weap,"weapon_rpg",false))
					{
						Format(weap,sizeof(weap),"rpg_missile");
					}
					else if (StrEqual(weap,"weapon_crossbow",false))
					{
						Format(weap,sizeof(weap),"crossbow_bolt");
					}
					else
						ReplaceString(weap,sizeof(weap),"weapon_","",false);
				}
			}
			SetEventInt(event,"killercolor",viccol);
			SetEventString(event,"victimname",plyname);
			SetEventString(event,"killername",clsname);
			SetEventString(event,"weapon",weap);
			Broadcast = true;
			return Plugin_Changed;
		}
	}
	else if ((IsValidEntity(killed)) && (killed > MaxClients))
	{
		char clsname[24];
		GetEntityClassname(killed,clsname,sizeof(clsname));
		char vicname[64];
		GetEventString(event,"victimname",vicname,sizeof(vicname));
		if ((StrEqual(clsname,"npc_bullseye",false)) && (StrEqual(vicname,"Combine Ground Turret")))
		{
			if (HasEntProp(killed,Prop_Data,"m_hDamageFilter"))
			{
				int dmgfilter = GetEntPropEnt(killed,Prop_Data,"m_hDamageFilter");
				if (IsValidEntity(dmgfilter))
				{
					if (HasEntProp(dmgfilter,Prop_Data,"m_iDamageType"))
					{
						if (GetEntProp(dmgfilter,Prop_Data,"m_iDamageType") == 64)
						{
							return Plugin_Continue;
						}
					}
				}
			}
			Broadcast = false;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
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

public Action checkvalidity(Handle timer, int client)
{
	if ((!IsValidEntity(client)) && (!IsClientInGame(client)) && (IsClientConnected(client)) && (StrContains(mapbuf,"bm_c",false) != -1))
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

void readoutputs(int scriptent, char[] targn)
{
	if ((strlen(targn) < 1) || (hasreadscriptents)) return;
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
		if (!StrEqual(clsscript,"ai_goal_follow",false))
		{
			hasreadscriptents = true;
		}
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (strlen(line) > 0)
			{
				if (StrContains(line,"\"targetname\"",false) == 0)
				{
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				else if (StrContains(line,"\"template0",false) == 0)
				{
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"template0","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					strcopy(tmpchar,sizeof(tmpchar),tmpchar[2]);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				else if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
				{
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"actor\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					TrimString(tmpchar);
					Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
				}
				if ((StrEqual(targn,lineoriginfixup,false)) && (reverse))
				{
					if (!findtargn(targn))
					{
						int linepos = FilePosition(filehandle);
						if (debuglvl == 3) PrintToServer("Found matching %s on line %i",targn,linepos);
						reverse = false;
						createent = true;
					}
					else hasreadscriptents = true;
				}
				if ((!StrEqual(line,"}",false)) || (!StrEqual(line,"{",false)) || (!StrEqual(line,"}{",false)))
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
					Format(tmpchar,sizeof(tmpchar),"%s",line);
					ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
					ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
					if (passvars)
					{
						if (FindStringInArray(passedarr,kvs[1]) == -1)
						{
							PushArrayString(passedarr,kvs[1]);
							PushArrayString(passedarr,kvs[3]);
						}
					}
					else if (ent != -1) DispatchKeyValue(ent,kvs[1],kvs[3]);
				}
				if (((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)) || (StrEqual(line,"}{",false))) && (ent == -1))
				{
					ClearArray(passedarr);
					passvars = true;
				}
				else if (createent)
				{
					if ((StrEqual(line,"}",false)) || (StrEqual(line,"{",false)) || (StrEqual(line,"}{",false)))
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
						char tmpchar[128];
						Format(tmpchar,sizeof(tmpchar),"%s",line);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
						ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
						TrimString(tmpchar);
						Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
					}
					if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
					{
						char tmpchar[128];
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
						else if (StrEqual(cls,"ai_goal_actbusy",false))
						{
							createent = false;
							ClearArray(passedarr);
						}
						else
						{
							ent = CreateEntityByName(cls);
							if (debuglvl == 3) PrintToServer("Created Ent as %s",cls);
							if (FindValueInArray(entlist,ent) == -1)
								PushArrayCell(entlist,ent);
						}
					}
				}
			}
		}
		CloseHandle(passedarr);
	}
	CloseHandle(filehandle);
	return;
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
							else if (StrEqual(input,"Deploy",false))
							{
								findsentriesd(-1,"npc_sentry_ground",lineorgrescom[0],delay);
								findsentriesd(-1,"npc_sentry_ceiling",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Retire",false))
							{
								findsentriesr(-1,"npc_sentry_ground",lineorgrescom[0],delay);
								findsentriesr(-1,"npc_sentry_ceiling",lineorgrescom[0],delay);
							}
							else if ((StrEqual(input,"ForceSpawn",false)) || (StrEqual(input,"Spawn",false)) || (StrEqual(input,"SpawnNPCInLine",false))) findpts(lineorgrescom[0],delay);
							else if (StrEqual(input,"SetMass",false))
							{
								Handle dp = CreateDataPack();
								WritePackString(dp,lineorgrescom[0]);
								WritePackString(dp,lineorgrescom[2]);
								findmassset(dp,delay);
							}
							if ((StrEqual(input,"StartPortal",false)) || (StrEqual(input,"Spawn",false)) || (StrEqual(input,"SpawnNPCInLine",false)))
							{
								findxenporttp(-1,"env_xen_portal",lineorgrescom[0],delay);
								findxenporttp(-1,"env_xen_portal_template",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"BeginRappellingGrunts",false))
							{
								findospreys(-1,lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Fade",false))
							{
								findfades(-1,lineorgrescom[0],activator,delay);
							}
							else if (StrEqual(input,"EquipAllPlayers",false))
							{
								findequips(-1,lineorgrescom[0],input,0,delay);
							}
							else if (StrEqual(input,"EquipPlayer",false))
							{
								if ((activator > MaxClients) || (activator < 0)) activator = 0;
								findequips(-1,lineorgrescom[0],input,activator,delay);
							}
							else if ((StrEqual(input,"DisplayText",false)) || (StrEqual(input,"CounterEntity",false)))
							{
								finddisplays(-1,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if (StrEqual(input,"ApplyScore",false))
							{
								if ((IsValidEntity(activator)) && (activator > 0) && (activator <= MaxClients))
								{
									if (HasEntProp(activator,Prop_Data,"m_iPoints"))
									{
										int scoreadd = GetEntProp(activator,Prop_Data,"m_iPoints");
										int targ = FindByTargetName(lineorgrescom[0]);
										if ((IsValidEntity(targ)) && (targ != 0))
										{
											scoreadd+=GetEntProp(targ,Prop_Data,"m_Score");
										}
										SetEntProp(activator,Prop_Data,"m_iPoints",scoreadd);
									}
								}
							}
							else if ((StrEqual(input,"SetTimerLabel",false)) || (StrEqual(input,"StartTimer",false)) || (StrEqual(input,"StopTimer",false)))
							{
								hudtimers(-1,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if ((StrEqual(input,"Purchase",false)) || (StrEqual(input,"SetPurchaseName",false)) || (StrEqual(input,"SetPurchaseCost",false)) || (StrEqual(input,"Disable",false)))
							{
								logmerches(-1,activator,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if (StrEqual(input,"SetCheckPoint",false))
							{
								spawnpointstates(lineorgrescom[2],delay);
							}
							else if ((StrEqual(input,"Activate",false)) || (StrEqual(input,"Break",false)))
							{
								FindDispensers(input,lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"CLCommand",false))
							{
								if (strlen(lineorgrescom[2]) > 0) CLToAllComm(lineorgrescom[2],delay);
							}
							else if (((StrEqual(input,"TakeAmmo",false)) || (StrEqual(input,"TakeAllAmmo",false))) && (activator > 0) && (activator < MaxClients+1))
							{
								weapammoremovers(activator,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if (StrEqual(input,"Test",false))
							{
								playerbranches(lineorgrescom[0],delay);
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
							else if (StrEqual(input,"Deploy",false))
							{
								findsentriesd(-1,"npc_sentry_ground",lineorgrescom[0],delay);
								findsentriesd(-1,"npc_sentry_ceiling",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Retire",false))
							{
								findsentriesr(-1,"npc_sentry_ground",lineorgrescom[0],delay);
								findsentriesr(-1,"npc_sentry_ceiling",lineorgrescom[0],delay);
							}
							else if ((StrEqual(input,"ForceSpawn",false)) || (StrEqual(input,"Spawn",false)) || (StrEqual(input,"SpawnNPCInLine",false))) findpts(lineorgrescom[0],delay);
							else if (StrEqual(input,"SetMass",false))
							{
								Handle dp = CreateDataPack();
								WritePackString(dp,lineorgrescom[0]);
								WritePackString(dp,lineorgrescom[2]);
								findmassset(dp,delay);
							}
							if ((StrEqual(input,"startportal",false)) || (StrEqual(input,"Spawn",false)) || (StrEqual(input,"SpawnNPCInLine",false)))
							{
								findxenporttp(-1,"env_xen_portal",lineorgrescom[0],delay);
								findxenporttp(-1,"env_xen_portal_template",lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"BeginRappellingGrunts",false))
							{
								findospreys(-1,lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"Fade",false))
							{
								findfades(-1,lineorgrescom[0],activator,delay);
							}
							else if (StrEqual(input,"EquipAllPlayers",false))
							{
								findequips(-1,lineorgrescom[0],input,activator,delay);
							}
							else if (StrEqual(input,"EquipPlayer",false))
							{
								if ((activator > MaxClients) || (activator < 0)) activator = 0;
								findequips(-1,lineorgrescom[0],input,activator,delay);
							}
							else if ((StrEqual(input,"DisplayText",false)) || (StrEqual(input,"CounterEntity",false)))
							{
								finddisplays(-1,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if (StrEqual(input,"ApplyScore",false))
							{
								if ((IsValidEntity(activator)) && (activator > 0) && (activator <= MaxClients))
								{
									if (HasEntProp(activator,Prop_Data,"m_iPoints"))
									{
										int scoreadd = GetEntProp(activator,Prop_Data,"m_iPoints");
										int targ = FindByTargetName(lineorgrescom[0]);
										if ((IsValidEntity(targ)) && (targ != 0))
										{
											scoreadd+=GetEntProp(targ,Prop_Data,"m_Score");
										}
										SetEntProp(activator,Prop_Data,"m_iPoints",scoreadd);
									}
								}
							}
							else if ((StrEqual(input,"SetTimerLabel",false)) || (StrEqual(input,"StartTimer",false)) || (StrEqual(input,"StopTimer",false)))
							{
								hudtimers(-1,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if ((StrEqual(input,"Purchase",false)) || (StrEqual(input,"SetPurchaseName",false)) || (StrEqual(input,"SetPurchaseCost",false)) || (StrEqual(input,"Disable",false)))
							{
								logmerches(-1,activator,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if (StrEqual(input,"SetCheckPoint",false))
							{
								spawnpointstates(lineorgrescom[2],delay);
							}
							else if ((StrEqual(input,"Activate",false)) || (StrEqual(input,"Break",false)))
							{
								FindDispensers(input,lineorgrescom[0],delay);
							}
							else if (StrEqual(input,"CLCommand",false))
							{
								if (strlen(lineorgrescom[2]) > 0) CLToAllComm(lineorgrescom[2],delay);
							}
							else if (((StrEqual(input,"TakeAmmo",false)) || (StrEqual(input,"TakeAllAmmo",false))) && (activator > 0) && (activator < MaxClients+1))
							{
								weapammoremovers(activator,input,lineorgrescom[0],lineorgrescom[2],delay);
							}
							else if (StrEqual(input,"Test",false))
							{
								playerbranches(lineorgrescom[0],delay);
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
	if (debuglvl > 1) PrintToServer("Read outputs for inputs from %s",mapbuf);
	hasread = true;
	Handle inputclasshooks = CreateArray(64);
	Handle filehandle = OpenFile(mapbuf,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		Handle inputs = CreateArray(32);
		PushArrayString(inputs,",Teleport,,");
		PushArrayString(inputs,",Save,,");
		PushArrayString(inputs,",StartPortal,,");
		PushArrayString(inputs,",Deploy,,");
		PushArrayString(inputs,",Retire,,");
		PushArrayString(inputs,",EquipAllPlayers,,");
		PushArrayString(inputs,",EquipPlayer,,");
		PushArrayString(inputs,",SetMass,");
		PushArrayString(inputs,",Fade,,");
		PushArrayString(inputs,",SetCheckPoint,");
		PushArrayString(inputs,",CLCommand,");
		if (customents)
		{
			PushArrayString(inputs,",ForceSpawn,,");
			PushArrayString(inputs,",Spawn,,");
			PushArrayString(inputs,",SpawnNPCInLine,,");
			PushArrayString(inputs,",BeginRappellingGrunts,,");
			PushArrayString(inputs,",DisplayText,,");
			PushArrayString(inputs,",Purchase,,");
			PushArrayString(inputs,",SetPurchaseName,");
			PushArrayString(inputs,",SetPurchaseCost,");
			PushArrayString(inputs,",CounterEntity,");
			PushArrayString(inputs,",ApplyScore,,");
			PushArrayString(inputs,",SetTimerLabel,");
			PushArrayString(inputs,",StartTimer,");
			PushArrayString(inputs,",StopTimer,,");
			PushArrayString(inputs,",TakeAmmo,");
			PushArrayString(inputs,",TakeAllAmmo,");
			PushArrayString(inputs,",Test,,");
			PushArrayString(inputs,",Activate,,");
			PushArrayString(inputs,",Break,,");
		}
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

int SearchForAllByTargetname(char tmptarg[128], Handle returnarr)
{
	findtargnbyclassarr(-1,"logic_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclassarr(-1,"info_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclassarr(-1,"env_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclassarr(-1,"ai_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclassarr(-1,"math_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclassarr(-1,"game_*",tmptarg,returnarr);
	if (GetArraySize(returnarr) > 0) return GetArraySize(returnarr);
	findtargnbyclassarr(-1,"point_template",tmptarg,returnarr);
	char renamereturn[64];
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
							GetEntityClassname(i,renamereturn,sizeof(renamereturn));
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
							GetEntityClassname(i,renamereturn,sizeof(renamereturn));
							if (FindValueInArray(returnarr,i) == -1) PushArrayCell(returnarr,i);
						}
					}
					else if (StrEqual(targn,tmptarg))
					{
						GetEntityClassname(i,renamereturn,sizeof(renamereturn));
						if (FindValueInArray(returnarr,i) == -1) PushArrayCell(returnarr,i);
					}
				}
			}
		}
	}
	if (strlen(renamereturn) > 0) Format(tmptarg,sizeof(tmptarg),"%s",renamereturn);
	return GetArraySize(returnarr);
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
		char enttargn[64];
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
			else
			{
				float nullvec[3];
				TeleportEntity(cl,origin,angs,nullvec);
			}
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
				float nullvec[3];
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsValidEntity(i))
						if (IsClientConnected(i))
							if (IsClientInGame(i))
								if (IsPlayerAlive(i))
									TeleportEntity(i,origin,angs,nullvec);
				}
			}
		}
		else findpointtp(thisent,targn,cl,delay);
	}
}

void findospreys(int ent, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,"npc_osprey");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1) CreateTimer(delay,ospreyrappeldelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			else
			{
				timesattacked[thisent] = 0;
				isattacking[thisent] = true;
			}
		}
		findospreys(thisent++,targn,delay);
	}
}

public Action ospreyrappeldelay(Handle timer, int entity)
{
	isattacking[entity] = true;
}

void findfades(int ent, char[] targn, int activator, float delay)
{
	int thisent = FindEntityByClassname(ent,"env_fade");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1)
			{
				Handle dp = CreateDataPack();
				WritePackCell(dp,thisent);
				WritePackCell(dp,activator);
				CreateTimer(delay,fadeinterceptdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				fadeintercept(thisent,activator);
			}
		}
		findfades(thisent++,targn,activator,delay);
	}
}

public Action fadeinterceptdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int ent = ReadPackCell(dp);
		int activator = ReadPackCell(dp);
		CloseHandle(dp);
		fadeintercept(ent,activator);
	}
}

void fadeintercept(int ent, int activator)
{
	if ((!IsValidEntity(activator)) || (activator == 0))
	{
		for (int i = 1;i<MaxClients+1;i++)
		{
			isfading[i] = true;
			fadingtime[i] = GetTickedTime()+0.1;
		}
	}
	else
	{
		int sf = GetEntProp(ent,Prop_Data,"m_spawnflags");
		if (sf & 1<<4)
		{
			isfading[activator] = true;
			fadingtime[activator] = GetTickedTime()+0.1;
		}
		else
		{
			for (int i = 1;i<MaxClients+1;i++)
			{
				isfading[i] = true;
				fadingtime[i] = GetTickedTime()+0.1;
			}
		}
	}
}

void findequips(int ent, char[] targn, char[] input, int activator, float delay)
{
	int thisent = FindEntityByClassname(ent,"info_player_equip");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1)
			{
				if ((StrEqual(input,"EquipPlayer",false)) && (activator != 0))
				{
					Handle dp = CreateDataPack();
					WritePackCell(dp,thisent);
					WritePackCell(dp,activator);
					CreateTimer(delay,equipdelaydp,dp,TIMER_FLAG_NO_MAPCHANGE);
				}
				else CreateTimer(delay,equipdelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if ((StrEqual(input,"EquipPlayer",false)) && (activator != 0))
				{
					EquipCustom(thisent,activator);
				}
				else
				{
					for (int i = 1;i<MaxClients+1;i++)
					{
						if (IsValidEntity(i))
							if (IsClientConnected(i))
								if (IsPlayerAlive(i))
									EquipCustom(thisent,i);
					}
				}
			}
		}
		findequips(thisent++,targn,input,activator,delay);
	}
}

public Action equipdelay(Handle timer, int equip)
{
	if (IsValidEntity(equip))
	{
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
				if (IsClientConnected(i))
					if (IsPlayerAlive(i))
						EquipCustom(equip,i);
		}
	}
}

public Action equipdelaydp(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int equip = ReadPackCell(dp);
		int activator = ReadPackCell(dp);
		CloseHandle(dp);
		if (IsValidEntity(equip))
		{
			if ((IsValidEntity(activator)) && (activator != 0)) EquipCustom(equip,activator);
			else
			{
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsValidEntity(i))
						if (IsClientConnected(i))
							if (IsPlayerAlive(i))
								EquipCustom(equip,i);
				}
			}
		}
	}
}

public void EquipCustom(int equip, int client)
{
	if ((IsValidEntity(equip)) && (IsValidEntity(client)))
	{
		if (HasEntProp(equip,Prop_Data,"m_iszResponseContext"))
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
				int arrloop = ExplodeString(additionalweaps," ",additionalweap,64,64,true);
				for (int k = 0;k<arrloop;k++)
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
							if ((StrEqual(basecls,"weapon_gluon",false)) || (StrEqual(basecls,"weapon_goop",false))) Format(basecls,sizeof(basecls),"weapon_shotgun");
							else if (StrEqual(basecls,"weapon_isa_knife",false)) Format(basecls,sizeof(basecls),"weapon_crowbar");
							else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
							else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false)) || (StrEqual(basecls,"weapon_p911",false)) || (StrEqual(basecls,"weapon_pistol2",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
							else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_molotov",false))) Format(basecls,sizeof(basecls),"weapon_slam");
							else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false)) || (StrEqual(basecls,"weapon_camera",false)) || (StrEqual(basecls,"weapon_smg3",false)) || (StrEqual(basecls,"weapon_smg4",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
							else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false)) || (StrEqual(basecls,"weapon_vc32sniperrifle",false)) || (StrEqual(basecls,"weapon_bhg",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
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
												else if (StrEqual(scrline,"grenade",false)) Format(scrline,sizeof(scrline),"crowbar");
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
}

void finddisplays(int ent, char[] input, char[] targn, char[] parampass, float delay)
{
	int thisent = FindEntityByClassname(ent,"game_text*");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1)
			{
				Handle dp = CreateDataPack();
				WritePackCell(dp,thisent);
				WritePackString(dp,parampass);
				WritePackString(dp,input);
				CreateTimer(delay,displaycustomdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if (StrEqual(input,"CounterEntity",false))
				{
					char findtn[128];
					Format(findtn,sizeof(findtn),"%s",parampass);
					int targ = -1;
					findtargnbyclass(-1,"math_*",findtn,targ);
					if ((targ != -1) && (targ != 0))
					{
						int offset = FindDataMapInfo(targ,"m_OutValue");
						if (offset != -1)
						{
							HookSingleEntityOutput(targ,"OutValue",mathcountout);
							HookSingleEntityOutput(targ,"OnGetValue",mathcountout);
							SetEntPropEnt(targ,Prop_Data,"m_hEffectEntity",ent);
							char returnval[64];
							GetEntPropString(ent,Prop_Data,"m_iszMessage",returnval,sizeof(returnval));
							Format(glotext[ent],sizeof(glotext[]),"%s",returnval);
							char repl[16];
							Format(repl,sizeof(repl),"%i",RoundFloat(GetEntDataFloat(targ,offset)));
							ReplaceString(returnval,sizeof(returnval),"(math)",repl,false);
							SetEntPropString(ent,Prop_Data,"m_iszMessage",returnval);
						}
					}
				}
				else
				{
					SetEntPropString(thisent,Prop_Data,"m_iszMessage",parampass);
					AcceptEntityInput(thisent,"Display");
				}
			}
		}
		finddisplays(thisent++,input,targn,parampass,delay);
	}
}

void hudtimers(int ent, char[] input, char[] targn, char[] parampass, float delay)
{
	int thisent = FindEntityByClassname(ent,"hud_timer");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[128];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1)
			{
				Handle dp = CreateDataPack();
				WritePackCell(dp,thisent);
				WritePackString(dp,parampass);
				WritePackString(dp,input);
				CreateTimer(delay,hudtimerdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				hudtimerinputs(thisent,input,parampass);
			}
		}
		hudtimers(thisent++,input,targn,parampass,delay);
	}
}

public Action hudtimerdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int thisent = ReadPackCell(dp);
		char parampass[64];
		char input[64];
		ReadPackString(dp,parampass,sizeof(parampass));
		ReadPackString(dp,input,sizeof(input));
		CloseHandle(dp);
		hudtimerinputs(thisent,input,parampass);
	}
}

void hudtimerinputs(int ent, char[] input, char[] parampass)
{
	if (StrEqual(input,"SetTimerLabel",false))
	{
		if (HasEntProp(ent,Prop_Data,"m_iszTimerText"))
		{
			SetEntPropString(ent,Prop_Data,"m_iszTimerText",parampass);
		}
	}
	else if (StrEqual(input,"StartTimer",false))
	{
		SetVariantString(parampass);
		AcceptEntityInput(ent,"Start");
	}
	else if (StrEqual(input,"StopTimer",false))
	{
		AcceptEntityInput(ent,"Stop");
	}
}

public Action displaycustomdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		char parampass[128];
		char input[32];
		ResetPack(dp);
		int ent = ReadPackCell(dp);
		ReadPackString(dp,parampass,sizeof(parampass));
		ReadPackString(dp,input,sizeof(input));
		CloseHandle(dp);
		if ((IsValidEntity(ent)) && (ent != 0))
		{
			if (StrEqual(input,"CounterEntity",false))
			{
				char findtn[128];
				Format(findtn,sizeof(findtn),"%s",parampass);
				int targ = -1;
				findtargnbyclass(-1,"math_*",findtn,targ);
				if ((targ != -1) && (targ != 0))
				{
					int offset = FindDataMapInfo(targ,"m_OutValue");
					if (offset != -1)
					{
						HookSingleEntityOutput(targ,"OutValue",mathcountout);
						HookSingleEntityOutput(targ,"OnGetValue",mathcountout);
						SetEntPropEnt(targ,Prop_Data,"m_hEffectEntity",ent);
						char returnval[64];
						GetEntPropString(ent,Prop_Data,"m_iszMessage",returnval,sizeof(returnval));
						Format(glotext[ent],sizeof(glotext[]),"%s",returnval);
						char repl[16];
						Format(repl,sizeof(repl),"%i",RoundFloat(GetEntDataFloat(targ,offset)));
						ReplaceString(returnval,sizeof(returnval),"(math)",repl,false);
						SetEntPropString(ent,Prop_Data,"m_iszMessage",returnval);
					}
				}
			}
			else
			{
				SetEntPropString(ent,Prop_Data,"m_iszMessage",parampass);
				AcceptEntityInput(ent,"Display");
			}
		}
	}
}

public Action mathcountout(const char[] output, int caller, int activator, float delay)
{
	int effecttxt = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
	if (effecttxt != -1)
	{
		int offset = FindDataMapInfo(caller,"m_OutValue");
		if (offset != -1)
		{
			char returnval[64];
			Format(returnval,sizeof(returnval),"%s",glotext[effecttxt]);
			char repl[16];
			Format(repl,sizeof(repl),"%i",RoundFloat(GetEntDataFloat(caller,offset)));
			ReplaceString(returnval,sizeof(returnval),"(math)",repl,false);
			SetEntPropString(effecttxt,Prop_Data,"m_iszMessage",returnval);
		}
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

void findxenporttp(int ent, char[] cls, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
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
						if (bPortalParticleAvailable)
						{
							int effect = CreateEntityByName("info_particle_system");
							if (effect != -1)
							{
								DispatchKeyValue(effect,"effect_name","teleport_lambda_exit");
								DispatchKeyValue(effect,"start_active","1");
								float origin[3];
								float angs[3];
								if (HasEntProp(thisent,Prop_Data,"m_angRotation")) GetEntPropVector(thisent,Prop_Data,"m_angRotation",angs);
								if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",origin);
								else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",origin);
								origin[2]+=25.0;
								TeleportEntity(effect,origin,angs,NULL_VECTOR);
								DispatchSpawn(effect);
								ActivateEntity(effect);
								AcceptEntityInput(effect,"Start");
								Handle dp2 = CreateDataPack();
								WritePackCell(dp2,effect);
								WritePackString(dp2,"info_particle_system");
								CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						else
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
						}
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
						EmitSoundToAll(snd, thisent, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
						AcceptEntityInput(thisent,"FireUser2");
						trigtp("OnUser2",thisent,thisent,0.0);
					}
					else
					{
						AcceptEntityInput(thisent,"Spawn");
						AcceptEntityInput(thisent,"FireUser2");
						trigtp("OnUser2",thisent,thisent,0.0);
					}
				}
				else
				{
					AcceptEntityInput(thisent,"Spawn");
					AcceptEntityInput(thisent,"FireUser2");
					trigtp("OnUser2",thisent,thisent,0.0);
				}
			}
		}
		findxenporttp(thisent,cls,targn,delay);
	}
}

void findsentriesd(int ent, char[] cls, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1) CreateTimer(delay,sentryddelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			else
			{
				SetEntProp(thisent,Prop_Data,"m_bDisabled",0);
				float Time = GetTickedTime();
				centlastposchk[thisent] = Time+2.0;
				AcceptEntityInput(thisent,"Enable");
			}
		}
		findsentriesd(thisent,cls,targn,delay);
	}
}

void findsentriesr(int ent, char[] cls, char[] targn, float delay)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[64];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1) CreateTimer(delay,sentryrdelay,thisent,TIMER_FLAG_NO_MAPCHANGE);
			else
			{
				SetEntProp(thisent,Prop_Data,"m_bDisabled",1);
				float Time = GetTickedTime();
				centlastposchk[thisent] = Time+2.0;
				AcceptEntityInput(thisent,"Disable");
			}
		}
		findsentriesr(thisent,cls,targn,delay);
	}
}

public Action sentryddelay(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity > 0))
	{
		SetEntProp(entity,Prop_Data,"m_bDisabled",0);
		float Time = GetTickedTime();
		centlastposchk[entity] = Time+2.0;
		AcceptEntityInput(entity,"Enable");
	}
}

public Action sentryrdelay(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity > 0))
	{
		SetEntProp(entity,Prop_Data,"m_bDisabled",1);
		float Time = GetTickedTime();
		centlastposchk[entity] = Time+2.0;
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
				if (bPortalParticleAvailable)
				{
					int effect = CreateEntityByName("info_particle_system");
					if (effect != -1)
					{
						DispatchKeyValue(effect,"effect_name","teleport_lambda_exit");
						DispatchKeyValue(effect,"start_active","1");
						float origin[3];
						float angs[3];
						if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
						if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",origin);
						else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
						origin[2]+=25.0;
						TeleportEntity(effect,origin,angs,NULL_VECTOR);
						DispatchSpawn(effect);
						ActivateEntity(effect);
						AcceptEntityInput(effect,"Start");
						Handle dp2 = CreateDataPack();
						WritePackCell(dp2,effect);
						WritePackString(dp2,"info_particle_system");
						CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else
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
				}
				int rand = GetRandomInt(1,3);
				char snd[64];
				Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
				EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				AcceptEntityInput(entity,"FireUser2");
				trigtp("OnUser2",entity,entity,0.0);
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
	float origin[3];
	float angs[3];
	float nullvec[3];
	origin[0] = ReadPackFloat(dp);
	origin[1] = ReadPackFloat(dp);
	origin[2] = ReadPackFloat(dp);
	angs[0] = ReadPackFloat(dp);
	angs[1] = ReadPackFloat(dp);
	CloseHandle(dp);
	if ((IsValidEntity(cl)) && (cl < MaxClients+1) && (cl > 0))
	{
		if (IsClientConnected(cl))
			if (IsClientInGame(cl))
				if (IsPlayerAlive(cl))
				{
					TeleportEntity(cl,origin,angs,nullvec);
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
	float nullvec[3];
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
			if (IsClientConnected(i))
				if (IsClientInGame(i))
					if (IsPlayerAlive(i))
						TeleportEntity(i,origin,angs,nullvec);
	}
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
		CreateTimer(0.1,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
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

void CLToAllComm(char[] cmd, float delay)
{
	if (delay > 0.1)
	{
		Handle dp = CreateDataPack();
		WritePackString(dp,cmd);
		CreateTimer(delay,CLToAllCommdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i))
				{
					if (!IsFakeClient(i))
					{
						ClientCommand(i,cmd);
					}
				}
			}
		}
	}
}

public Action CLToAllCommdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char cmd[64];
		ReadPackString(dp,cmd,sizeof(cmd));
		CloseHandle(dp);
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i))
				{
					if (!IsFakeClient(i))
					{
						ClientCommand(i,cmd);
						//Open menu for video play
						if (StrContains(cmd,"playvideo",false) == 0) ClientCommand(i,"con");
					}
				}
			}
		}
	}
}

void weapammoremovers(int activator, char[] input, char[] targn, char[] ammtype, float delay)
{
	Handle arr = CreateArray(64);
	FindAllByClassname(arr,-1,"hlss_weaponstripper");
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
						if (delay > 0.1)
						{
							Handle dp = CreateDataPack();
							WritePackCell(dp,activator);
							WritePackCell(dp,ent);
							WritePackString(dp,input);
							WritePackString(dp,ammtype);
							CreateTimer(delay,weapammoremoversdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
						}
						else RMAmmCheck(ent,activator,input,ammtype);
						break;
					}
				}
			}
		}
	}
	CloseHandle(arr);
}

public Action weapammoremoversdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int activator = ReadPackCell(dp);
		int ent = ReadPackCell(dp);
		char input[32];
		char ammtype[32];
		ReadPackString(dp,input,sizeof(input));
		ReadPackString(dp,ammtype,sizeof(ammtype));
		CloseHandle(dp);
		RMAmmCheck(ent,activator,input,ammtype);
	}
}

void RMAmmCheck(int ent, int activator, char[] input, char[] ammtype)
{
	if ((IsValidEntity(activator)) && (activator > 0) && (activator < MaxClients+1))
	{
		if (strlen(ammtype) > 0)
		{
			int elem = 0;
			if (StrEqual(ammtype,"Buckshot",false)) elem = 7;
			else if (StrEqual(ammtype,"rpg_round",false)) elem = 8;
			else if (StrEqual(ammtype,"Pistol",false)) elem = 3;
			else if (StrEqual(ammtype,"SniperRound",false)) elem = 0;//This is 10 but ammo icon crash occurs
			else if ((StrEqual(ammtype,"Manhack",false)) || (StrEqual(ammtype,"ManhacksOnline",false)) || (StrEqual(ammtype,"Stunstick",false))) elem = 24;
			else if ((StrEqual(ammtype,"grenade",false)) || (StrEqual(ammtype,"SmokeGrenade",false))) elem = 12;
			else if (StrEqual(ammtype,"XBowBolt",false)) elem = 6;
			else if (StrEqual(ammtype,"AlyxGun",false)) elem = 0;
			else if (StrEqual(ammtype,"TurretHealth",false)) elem = 0;
			else if (StrEqual(ammtype,"357",false)) elem = 5;
			else if (StrEqual(ammtype,"SMG1",false)) elem = 4;
			else if (StrEqual(ammtype,"SMG1_Grenade",false)) elem = 9;
			else if (StrEqual(ammtype,"AR2AltFire",false)) elem = 22;
			else if (StrEqual(ammtype,"AR2",false)) elem = 1;
			if (elem != 0)
			{
				if (StrEqual(input,"TakeAllAmmo",false))
				{
					SetEntProp(activator, Prop_Data, "m_iAmmo", 0, _, elem);
					AcceptEntityInput(ent,"FireUser1",activator);
				}
				else
				{
					int ammchk = GetEntProp(activator, Prop_Send, "m_iAmmo", _, elem);
					if (ammchk < 1)
					{
						AcceptEntityInput(ent,"FireUser2",activator);
					}
					else
					{
						SetEntProp(activator, Prop_Data, "m_iAmmo", ammchk-1, _, elem);
						AcceptEntityInput(ent,"FireUser1",activator);
					}
				}
			}
			else
			{
				//Don't know what ammo type was specified, run AmmoRemoved outputs as a failsave.
				AcceptEntityInput(ent,"FireUser1",activator);
			}
		}
	}
	return;
}

void playerbranches(char[] targn, float delay)
{
	Handle arr = CreateArray(64);
	FindAllByClassname(arr,-1,"logic_player_branch");
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
						if (delay > 0.1)
						{
							CreateTimer(delay,logplybranchdelay,ent,TIMER_FLAG_NO_MAPCHANGE);
						}
						else logplybranchfire(ent);
						break;
					}
				}
			}
		}
	}
	CloseHandle(arr);
}

public Action logplybranchdelay(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		logplybranchfire(entity);
	}
}

void logplybranchfire(int entity)
{
	if (IsValidEntity(entity))
	{
		int curply = GetClientCount(false);
		SetVariantInt(curply);
		AcceptEntityInput(entity,"SetValue");
		CreateTimer(0.1,logplybranchreset,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action logplybranchreset(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		SetVariantInt(0);
		AcceptEntityInput(entity,"SetValue");
	}
}

public Action cleanup(Handle timer, Handle data)
{
	ResetPack(data);
	int cleanupent = ReadPackCell(data);
	char clsname[32];
	ReadPackString(data,clsname,sizeof(clsname));
	CloseHandle(data);
	if ((IsValidEntity(cleanupent)) && ((cleanupent > MaxClients) || (cleanupent < -1)))
	{
		char tmpcls[32];
		GetEntityClassname(cleanupent,tmpcls,sizeof(tmpcls));
		if (StrEqual(tmpcls,clsname,false))
		{
			if (StrEqual(tmpcls,"logic_collision_pair",false)) AcceptEntityInput(cleanupent,"DisableCollisions");
			AcceptEntityInput(cleanupent,"kill");
		}
	}
}

public void OnClientDisconnect(int client)
{
	cllastsscape[client] = 0;
	votetime[client] = 0.0;
	fadingtime[client] = 0.0;
	antispamchk[client] = 0.0;
	LastJump[client] = 0.0;
	showcc[client] = false;
	bPrevOpen[client] = false;
	bPrevWeapRPG[client] = false;
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

public Action TakeDamageAnts(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	char atkcls[32];
	if (IsValidEntity(attacker)) GetEntityClassname(attacker,atkcls,sizeof(atkcls));
	char infcls[32];
	if (IsValidEntity(inflictor)) GetEntityClassname(inflictor,infcls,sizeof(infcls));
	char viccls[32];
	if (IsValidEntity(victim)) GetEntityClassname(victim,viccls,sizeof(viccls));
	if ((StrEqual(viccls,"npc_antlion",false)) && ((StrEqual(infcls,"npc_antlionguard",false)) || (StrEqual(atkcls,"npc_antlionguard",false))))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action TakeDamageCustom(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	char atkcls[32];
	if (IsValidEntity(attacker)) GetEntityClassname(attacker,atkcls,sizeof(atkcls));
	char infcls[32];
	if (IsValidEntity(inflictor)) GetEntityClassname(inflictor,infcls,sizeof(infcls));
	//PrintToServer("Tk damage %i %i %s %i %s %f %i",victim,attacker,atkcls,inflictor,infcls,damage,damagetype);
	if ((StrEqual(atkcls,"grenade_mortar_large",false)) || (StrEqual(infcls,"grenade_mortar_large",false)))
	{
		damage = damage*2.0;
		damagetype = 64;
		return Plugin_Changed;
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
	if ((IsValidEntity(attacker)) && (IsValidEntity(victim)))
	{
		char cls[32];
		GetEntityClassname(attacker,cls,sizeof(cls));
		if ((StrEqual(cls,"func_platrot",false)) || (StrEqual(cls,"func_door",false)))
		{
			if (HasEntProp(victim,Prop_Data,"m_hGroundEntity"))
			{
				int groundchk = GetEntPropEnt(victim,Prop_Data,"m_hGroundEntity");
				if (groundchk == attacker)
				{
					float orgs[3];
					if (HasEntProp(victim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(victim,Prop_Data,"m_vecOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecOrigin",orgs);
					orgs[2]+=15.0;
					TeleportEntity(victim,orgs,NULL_VECTOR,NULL_VECTOR);
					damage = 0.0;
					if (debuglvl == 3) PrintToServer("Moved ply %i because of damage from standing ent %i %s",victim,attacker,cls);
					return Plugin_Changed;
				}
			}
		}
		else if (StrEqual(cls,"trigger_hurt",false))
		{
			if ((HasEntProp(victim,Prop_Data,"m_hVehicle")) && (HasEntProp(attacker,Prop_Data,"m_bitsDamageInflict")) && (HasEntProp(attacker,Prop_Data,"m_spawnflags")))
			{
				if (GetEntProp(attacker,Prop_Data,"m_spawnflags") & (1<<9))
				{
					if (GetEntPropEnt(victim,Prop_Data,"m_hVehicle") != -1)
					{
						damage = 0.0;
						damagetype = 0;
						return Plugin_Changed;
					}
				}
			}
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
		Handle tkscalechk = INVALID_HANDLE;
		if (difficulty == 1) tkscalechk = FindConVar("sk_dmg_take_scale1");
		else if (difficulty == 2) tkscalechk = FindConVar("sk_dmg_take_scale2");
		else if (difficulty == 3) tkscalechk = FindConVar("sk_dmg_take_scale3");
		if (tkscalechk != INVALID_HANDLE)
		{
			tkscale = GetConVarFloat(tkscalechk);
		}
		CloseHandle(tkscalechk);
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
			/* Handled within hookent inputs
			else if (StrEqual(clsname,"logic_relay",false))
			{
				HookSingleEntityOutput(i,"OnTimer",trigtp);
			}
			else if (StrEqual(clsname,"logic_choreographed_scene",false))
			{
				char tmpoutphook[24];
				for (int j = 1;j<17;j++)
				{
					Format(tmpoutphook,sizeof(tmpoutphook),"OnTrigger%i",j);
					HookSingleEntityOutput(i,tmpoutphook,trigtp);
				}
			}
			else if (StrEqual(clsname,"hud_timer",false))
			{
				HookSingleEntityOutput(i,"OnTimer",trigtp);
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
	resetspawners(-1,"env_xen_portal");
	resetspawners(-1,"env_xen_portal_template");
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
	if ((!weapmanagersplaced) && (StrContains(mapbuf,"01_spymap_ep3",false) == -1) && (StrContains(mapbuf,"ep1_c17_02a",false) == -1))
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
	//if (customents)
	//Function now includes global name recreation
	ClearArrayHandles(restorecustoments);
	CloseHandle(restorecustoments);
	restorecustoments = CreateArray(256);
	findcustoments();
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
		else if (StrEqual(classname,"npc_antlionguard",false))
		{
			CreateTimer(1.0,GuardSlowThink,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (StrEqual(classname,"npc_antlion",false))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, TakeDamageAnts);
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
	if ((StrEqual(classname,"logic_auto",false)) || (StrEqual(classname,"env_sprite",false)) || (StrEqual(classname,"env_laser",false)))
	{
		CreateTimer(1.0,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if (StrEqual(classname,"npc_vortigaunt",false))
	{
		CreateTimer(1.0,rechkcol,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if ((StrEqual(classname,"phys_bone_follower",false)) || (StrEqual(classname,"entityflame",false)) || (StrEqual(classname,"_firesmoke",false)) || (StrEqual(classname,"env_fire",false)))
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
					findrope = FindEntityByClassname(-1,"entityflame");
					if (findrope != -1) AcceptEntityInput(findrope,"kill");
					else
					{
						AcceptEntityInput(entity,"kill");
					}
				}
			}
		}
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
					else
					{
						AcceptEntityInput(entity,"kill");
					}
				}
			}
		}
	}
	if ((StrContains(classname,"weapon_",false) == 0) && (!StrEqual(classname,"weapon_striderbuster",false)))
	{
		SDKHookEx(entity,SDKHook_Spawn,resetweapmv);
	}
	if (StrEqual(classname,"generic_actor",false))
	{
		SDKHookEx(entity,SDKHook_Spawn,chkgeneric);
	}
	if (StrEqual(classname,"rpg_missile",false))
	{
		if (IsValidEntity(entity))
		{
			CreateTimer(0.3,resetown,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_iName"))
		{
			if (!SDKHookEx(entity,SDKHook_Spawn,custentspawn))
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
					if (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING))
					{
						DispatchKeyValue(entity,"model","models/zombie/zsecurity.mdl");
						SetEntityModel(entity,"models/zombie/zsecurity.mdl");
					}
					else
					{
						DispatchKeyValue(entity,"model","models/zombies/zombie_guard.mdl");
						SetEntityModel(entity,"models/zombies/zombie_guard.mdl");
					}
				}
			}
			else if ((StrEqual(clschk,"generic_actor")) && (StrEqual(mdl,"models/roller.mdl",false)))
			{
				AcceptEntityInput(entity,"kill");
			}
			//PrintToServer("%s %s",clschk,mdl);
			if (IsValidEntity(entity)) CreateTimer(0.1,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
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
	if ((StrEqual(classname,"npc_ichthyosaur",false)) || (StrEqual(classname,"monster_ichthyosaur",false)))
	{
		SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
		SetEntProp(entity,Prop_Data,"m_MoveType",7);
		if (HasEntProp(entity,Prop_Data,"m_bloodColor")) SetEntProp(entity,Prop_Data,"m_bloodColor",2);
		SDKHookEx(entity,SDKHook_Think,ichythink);
		HookSingleEntityOutput(entity,"OnFoundEnemy",OnIchyFoundPlayer);
	}
	if (((StrEqual(classname,"item_healthkit",false)) || (StrEqual(classname,"item_health_drop",false)) || (StrEqual(classname,"item_battery",false)) || (StrEqual(classname,"item_ammo_pistol",false))) && (customents))
	{
		CreateTimer(0.1,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(classname,"item_ammo_pistol",false))
	{
		CreateTimer(0.1,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if ((StrEqual(classname,"npc_antlion",false)) || (StrEqual(classname,"npc_antlion_worker",false)) || (StrEqual(classname,"generic_actor",false)))
	{
		CreateTimer(0.5,rechk,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(classname,"npc_gargantua",false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, TakeDamageCustom);
	}
	else if (StrEqual(classname,"npc_hunter",false))
	{
		if (!FileExists("models/hunter.mdl",true,NULL_STRING))
		{
			PrintToServer("Attempted to create hunter without Ep2 mounted!");
			AcceptEntityInput(entity,"kill");
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if ((entity > 0) && (entity < 2048))
	{
		centnextatk[entity] = 0.0;
		timesattacked[entity] = 0;
		isattacking[entity] = 0;
		centnextsndtime[entity] = 0.0;
	}
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
	find = FindValueInArray(controllers,entity);
	if (find != -1) RemoveFromArray(controllers,find);
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
	find = FindValueInArray(entlist,entity);
	if (find != -1) RemoveFromArray(entlist,find);
	if ((IsValidEntity(entity)) && (entity > MaxClients))
	{
		char cls[64];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"npc_bmsgargantua",false))
		{
			int effectent = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			if ((IsValidEntity(effectent)) && (effectent > MaxClients))
			{
				int spr = GetEntPropEnt(effectent,Prop_Data,"m_hEffectEntity");
				if ((IsValidEntity(spr)) && (spr > MaxClients))
				{
					AcceptEntityInput(spr,"kill");
				}
				AcceptEntityInput(effectent,"kill");
			}
			for (int i = 0;i<5;i++)
			{
				if ((IsValidEntity(gargfiretarg[entity][i])) && (gargfiretarg[entity][i] != 0))
				{
					AcceptEntityInput(gargfiretarg[entity][i],"kill");
					gargfiretarg[entity][i] = -1;
				}
			}
		}
		else if ((StrContains(cls,"choreo",false) != -1) || (StrEqual(cls,"prop_vehicle_prisoner_pod",false)))
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
		else if (StrEqual(cls,"npc_rollermine",false))
		{
			StopSound(entity,SNDCHAN_WEAPON,"npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(entity,SNDCHAN_WEAPON,"npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(entity,SNDCHAN_WEAPON,"npc/roller/mine/rmine_movefast_loop1.wav");
			float entpos[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",entpos);
			else if (HasEntProp(entity,Prop_Data,"m_vecOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecOrigin",entpos);
			EmitAmbientSound("npc/roller/mine/rmine_seek_loop2.wav", entpos, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
			EmitAmbientSound("npc/roller/mine/rmine_moveslow_loop1.wav", entpos, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
			EmitAmbientSound("npc/roller/mine/rmine_movefast_loop1.wav", entpos, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		}
		else if (StrEqual(cls,"npc_turret_floor",false))
		{
			StopSound(entity,SNDCHAN_VOICE,"npc/turret_floor/alarm.wav");
			StopSound(entity,SNDCHAN_WEAPON,"npc/turret_floor/alarm.wav");
			float entpos[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",entpos);
			else if (HasEntProp(entity,Prop_Data,"m_vecOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecOrigin",entpos);
			EmitAmbientSound("npc/turret_floor/alarm.wav", entpos, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		}
	}
	findmovechild(-1);
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
	find = FindValueInArray(controllers,caller);
	if (find != -1) RemoveFromArray(controllers,find);
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

public Action GuardSlowThink(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"npc_antlionguard",false))
		{
			CreateTimer(1.0,GuardSlowThink,entity,TIMER_FLAG_NO_MAPCHANGE);
			float Time = GetTickedTime();
			if ((centnextatk[entity] < Time) && (antlionguardhard))
			{
				float orgs[3];
				float clorgs[3];
				int clinrange = 0;
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
				for (int i = 1;i<MaxClients+1;i++)
				{
					if (IsValidEntity(i))
					{
						if (IsClientConnected(i))
						{
							if (IsClientInGame(i))
							{
								if (IsPlayerAlive(i))
								{
									if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",clorgs);
									else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",clorgs);
									if (GetVectorDistance(orgs,clorgs,false) < 110.0)
									{
										clinrange++;
									}
								}
							}
						}
					}
				}
				SetEntProp(entity,Prop_Data,"m_bBarkEnabled",1);
				if (GetRandomInt(0,100) > 80)
					if (GetEntProp(entity,Prop_Data,"m_iNumLiveAntlions") > 0) SetEntProp(entity,Prop_Data,"m_iNumLiveAntlions",0);
				if ((clinrange > 0) || (GetRandomInt(0,100) > 92))
				{
					int grenade = CreateEntityByName("env_sporeexplosion");
					if (grenade != -1)
					{
						orgs[2]+=10.0;
						TeleportEntity(grenade,orgs,NULL_VECTOR,NULL_VECTOR);
						DispatchSpawn(grenade);
						ActivateEntity(grenade);
						SetEntPropFloat(grenade,Prop_Data,"m_flSpawnRate",150.0);
						SetEntPropFloat(grenade,Prop_Data,"m_flParticleLifetime",2.0);
						SetEntPropFloat(grenade,Prop_Data,"m_flStartSize",20.0);
						SetEntPropFloat(grenade,Prop_Data,"m_flSpawnRadius",32.0);
						SetEntProp(grenade,Prop_Data,"m_bEmit",1);
						Handle dp = CreateDataPack();
						WritePackCell(dp,grenade);
						WritePackString(dp,"env_sporeexplosion");
						CreateTimer(5.0,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
						int trighurt = CreateEntityByName("trigger_hurt");
						if (trighurt != -1)
						{
							if (!IsModelPrecached("*1")) PrecacheModel("*1",true);
							DispatchKeyValue(trighurt,"spawnflags","1");
							DispatchKeyValue(trighurt,"damagetype","65536");
							DispatchKeyValue(trighurt,"damagecap","20");
							DispatchKeyValue(trighurt,"damage","10");
							DispatchKeyValue(trighurt,"edt_mins","-100 -100 -100");
							DispatchKeyValue(trighurt,"edt_maxs","100 100 100");
							TeleportEntity(trighurt,orgs,NULL_VECTOR,NULL_VECTOR);
							DispatchSpawn(trighurt);
							ActivateEntity(trighurt);
							Handle dp2 = CreateDataPack();
							WritePackCell(dp2,trighurt);
							WritePackString(dp2,"trigger_hurt");
							CreateTimer(5.0,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					centnextatk[entity] = Time+GetRandomFloat(5.0,12.0);
				}
			}
		}
	}
}

public Action MineFieldTouch(const char[] output, int caller, int activator, float delay)
{
	//OnDetonate
	if (IsValidEntity(caller)) AcceptEntityInput(caller,"FireUser2");
	float orgs[3];
	float angs[3];
	angs[0] = 90.0;
	if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",orgs);
	else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",orgs);
	float fhitpos[3];
	Handle hhitpos = INVALID_HANDLE;
	TR_TraceRay(orgs,angs,MASK_SHOT,RayType_Infinite);
	TR_GetEndPosition(fhitpos,hhitpos);
	CloseHandle(hhitpos);
	int endpoint = CreateEntityByName("env_explosion");
	TeleportEntity(endpoint,fhitpos,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpoint,"imagnitude","300");
	DispatchKeyValue(endpoint,"targetname","syn_minefieldblast");
	DispatchKeyValue(endpoint,"iradiusoverride","150");
	//DispatchKeyValue(endpoint,"rendermode","4");
	//DispatchKeyValue(endpoint,"spawnflags","9084");
	SetEntPropEnt(endpoint,Prop_Data,"m_hEffectEntity",caller);
	DispatchSpawn(endpoint);
	ActivateEntity(endpoint);
	AcceptEntityInput(endpoint,"Explode");
	//env_mine_explode add info_particle_system?
}

public Action StartTouchPushPad(int entity, int other)
{
	float Time = GetTickedTime();
	if ((centlastposchk[entity] < Time) && (other != 0))
	{
		char jumptarg[64];
		if (HasEntProp(entity,Prop_Data,"m_iszResponseContext")) GetEntPropString(entity,Prop_Data,"m_iszResponseContext",jumptarg,sizeof(jumptarg));
		if (strlen(jumptarg) > 0) findinfotarg(-1,jumptarg,entity);
		char jumpset[32];
		Format(jumpset,sizeof(jumpset),"jump0%i",GetRandomInt(1,2));
		SetVariantString(jumpset);
		AcceptEntityInput(entity,"SetAnimation");
		centlasttouch[other] = Time + 1.0;
		CreateTimer(0.3,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
		EmitSoundToAll("BMS_objects\\xenpushpad\\jumppad1.wav",entity,SNDCHAN_AUTO,SNDLEVEL_DISHWASHER);
		centlastposchk[entity] = Time + 3.0;
	}
	else if ((other != 0) && (IsValidEntity(other)))
	{
		centlasttouch[other] = Time + 1.0;
	}
}

public Action StartTouchLongJump(int entity, int other)
{
	if (IsValidEntity(entity))
	{
		if ((other < MaxClients+1) && (other > 0))
		{
			AcceptEntityInput(entity,"kill");
			longjumpactive = true;
			int hudhint = CreateEntityByName("env_hudhint");
			if (hudhint != -1)
			{
				char msg[64];
				if (LongJumpMode) Format(msg,sizeof(msg),"Jump + Direction + Jump LONG JUMP");
				else Format(msg,sizeof(msg),"Ctrl + Jump LONG JUMP");
				DispatchKeyValue(hudhint,"spawnflags","1");
				DispatchKeyValue(hudhint,"message",msg);
				DispatchSpawn(hudhint);
				ActivateEntity(hudhint);
				AcceptEntityInput(hudhint,"ShowHudHint");
				Handle dp = CreateDataPack();
				WritePackCell(dp,hudhint);
				WritePackString(dp,"env_hudhint");
				CreateTimer(0.5,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
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

public Action sentryfindtarg(const char[] output, int caller, int activator, float delay)
{
	int enemy = -1;
	if (HasEntProp(caller,Prop_Data,"m_hEnemy")) enemy = GetEntPropEnt(caller,Prop_Data,"m_hEnemy");
	PrintToServer("%i find %i %i",caller,activator,enemy);
}

public void custentspawn(int entity)
{
	SDKUnhook(entity,SDKHook_Spawn,custentspawn);
	SetupLivingEnt(entity);
}

public Action custent(Handle timer, int entity)
{
	SetupLivingEnt(entity);
	return Plugin_Handled;
}

public void SetupLivingEnt(int entity)
{
	if (IsValidEntity(entity))
	{
		bool resetname = true;
		char cls[128];
		char entcls[128];
		if (HasEntProp(entity,Prop_Data,"m_iName")) GetEntPropString(entity,Prop_Data,"m_iName",cls,sizeof(cls));
		GetEntityClassname(entity,entcls,sizeof(entcls));
		if (StrEqual(entcls,"npc_barnacle",false))
		{
			SetVariantString("npc_ichthyosaur D_LI 99");
			AcceptEntityInput(entity,"SetRelationship");
		}
		else if (StrEqual(entcls,"env_laserdot",false))
		{
			if (HasEntProp(entity,Prop_Data,"m_hOwnerEntity"))
			{
				int owner = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
				if ((IsValidEntity(owner)) && (owner > 0) && (owner < MaxClients+1))
				{
					if (!guiderocket[owner]) SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
				}
			}
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
						return;
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
						return;
					}
				}
			}
		}
		if (HasEntProp(entity,Prop_Data,"m_vecMins"))
		{
			float vecMins[3];
			float vecMaxs[3];
			GetEntPropVector(entity,Prop_Data,"m_vecMins",vecMins);
			GetEntPropVector(entity,Prop_Data,"m_vecMaxs",vecMaxs);
			bool bSetMM = false;
			if (vecMaxs[0] < vecMins[0])
			{
				float tmp = vecMaxs[0];
				vecMaxs[0] = vecMins[0];
				vecMins[0] = tmp;
				bSetMM = true;
			}
			if (vecMaxs[1] < vecMins[1])
			{
				float tmp = vecMaxs[1];
				vecMaxs[1] = vecMins[1];
				vecMins[1] = tmp;
				bSetMM = true;
			}
			if (vecMaxs[2] < vecMins[2])
			{
				float tmp = vecMaxs[2];
				vecMaxs[2] = vecMins[2];
				vecMins[2] = tmp;
				bSetMM = true;
			}
			if (bSetMM)
			{
				SetEntPropVector(entity,Prop_Data,"m_vecMins",vecMins);
				SetEntPropVector(entity,Prop_Data,"m_vecMaxs",vecMaxs);
				if (debuglvl)
				{
					PrintToServer("Reset incorrect config for mins/maxs on %i %s",entity,entcls);
				}
			}
		}
		if (StrEqual(entcls,"item_ammo_crate",false))
		{
			if (HasEntProp(entity,Prop_Data,"m_ModelName"))
			{
				char mdl[64];
				GetEntPropString(entity,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (strlen(mdl) > 0)
				{
					if ((!FileExists(mdl,true,NULL_STRING)) && (StrContains(mdl,"ammocrate_smg2.mdl",false) != -1))
					{
						if (FileExists("models/props_hc/items/ammocrate_argrenades.mdl",true,NULL_STRING))
						{
							if (!IsModelPrecached("models/props_hc/items/ammocrate_argrenades.mdl")) PrecacheModel("models/props_hc/items/ammocrate_argrenades.mdl",true);
							SetEntityModel(entity,"models/props_hc/items/ammocrate_argrenades.mdl");
						}
					}
				}
			}
		}
		if ((StrEqual(entcls,"npc_snark",false)) || (StrEqual(entcls,"monster_snark",false)) || (StrEqual(entcls,"npc_babycrab",false)))
		{
			Format(cls,sizeof(cls),"%s",entcls);
			resetname = false;
		}
		else if (StrEqual(entcls,"npc_zombie_security",false))
		{
			if (HasEntProp(entity,Prop_Data,"m_nBody"))
			{
				if (GetEntProp(entity,Prop_Data,"m_nBody") == 1) SetEntProp(entity,Prop_Data,"m_nBody",0);
			}
		}
		else if (StrContains(entcls,"npc_bmsgargantua",false) == 0)
		{
			if (FileExists("models/xenians/garg.mdl",true,NULL_STRING))
			{
				if (FindStringInArray(precachedarr,"npc_bmsgargantua") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/npc/garg/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"npc_bmsgargantua");
				}
				DispatchKeyValue(entity,"classname","npc_bmsgargantua");
				ReplaceString(cls,sizeof(cls),"npc_bmsgargantua","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				SDKHookEx(entity,SDKHook_Think,bmsgargthink);
				SDKHookEx(entity,SDKHook_OnTakeDamage,bmsgargtkdmg);
				int healthset = 800;
				Handle cvarh = FindConVar("sk_bmsgargantua_health");
				if (cvarh != INVALID_HANDLE)
				{
					healthset = GetConVarInt(cvarh);
				}
				CloseHandle(cvarh);
				SetEntProp(entity,Prop_Data,"m_iHealth",healthset);
				SetEntProp(entity,Prop_Data,"m_iMaxHealth",healthset);
			}
		}
		if ((strlen(cls) > 0) && (!StrEqual(entcls,"prop_physics",false)) && (!StrEqual(entcls,"prop_dynamic",false)) && (!StrEqual(entcls,"prop_ragdoll",false)) && (StrContains(entcls,"ai_",false) == -1) && (StrContains(entcls,"logic_",false) == -1) && (StrContains(entcls,"game_",false) == -1))
		{
			if (((StrContains(cls,"npc_",false) != -1) || (StrContains(cls,"monster_",false) != -1) || (StrEqual(cls,"generic_actor",false)) || (StrEqual(cls,"generic_monster",false))) && (!StrEqual(cls,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(cls,"npc_bullseye",false)) && (!StrEqual(cls,"env_xen_portal",false)) && (!StrEqual(cls,"env_xen_portal_template",false)) && (!StrEqual(cls,"npc_maker",false)) && (!StrEqual(cls,"npc_template_maker",false)) && (StrContains(cls,"info_",false) == -1) && (StrContains(cls,"game_",false) == -1) && (StrContains(cls,"trigger_",false) == -1) && (FindValueInArray(entlist,entity) == -1))
				PushArrayCell(entlist,entity);
			Handle dp = CreateDataPack();
			float origin[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",origin);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
			if (StrContains(cls,"pttemplate",false) == 0)
			{
				ReplaceStringEx(cls,sizeof(cls),"pttemplate","");
				findpts(cls,0.0);
				AcceptEntityInput(entity,"Kill");
				CloseHandle(dp);
				dp = INVALID_HANDLE;
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
					float angs[3];
					GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
					char additionalequip[64];
					if (HasEntProp(entity,Prop_Data,"m_spawnEquipment")) GetEntPropString(entity,Prop_Data,"m_spawnEquipment",additionalequip,sizeof(additionalequip));
					DispatchKeyValue(entity,"classname","npc_human_security");
					ReplaceString(cls,sizeof(cls),"npc_human_security","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/humans/guard.mdl");
					DispatchKeyValue(entity,"CitizenType","4");
					int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
					//WritePackString(dp,"models/humans/guard.mdl");
					if (!relsetsec)
					{
						setuprelations("npc_human_security");
						relsetsec = true;
					}
					CloseHandle(dp);
					dp = INVALID_HANDLE;
					AcceptEntityInput(entity,"kill");
					int recreate = CreateEntityByName("npc_citizen");
					if (recreate != -1)
					{
						char sfch[16];
						Format(sfch,sizeof(sfch),"%i",sf);
						DispatchKeyValue(recreate,"additionalequipment",additionalequip);
						DispatchKeyValue(recreate,"spawnflags",sfch);
						DispatchKeyValue(recreate,"classname","npc_human_security");
						DispatchKeyValue(recreate,"targetname",cls);
						DispatchKeyValue(recreate,"model","models/humans/guard.mdl");
						DispatchKeyValue(recreate,"CitizenType","4");
						char randsk[8];
						int rand = GetRandomInt(0,14);
						Format(randsk,sizeof(randsk),"%i",rand);
						DispatchKeyValue(recreate,"Skin",randsk);
						DispatchKeyValue(recreate,"Body",randsk);
						TeleportEntity(recreate,origin,angs,NULL_VECTOR);
						DispatchSpawn(recreate);
						ActivateEntity(recreate);
						if (sf & 1<<17)
						{
							SetVariantString("spawnflags 1064960");
							AcceptEntityInput(recreate,"AddOutput");
						}
						SDKHookEx(recreate,SDKHook_OnTakeDamage,enttkdmgcust);
					}
				}
			}
			else if (StrContains(cls,"npc_human_scientist",false) == 0)
			{
				if (FileExists("models/humans/scientist.mdl",true,NULL_STRING))
				{
					ReplaceString(cls,sizeof(cls),"npc_human_scientist","");
					int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
					float angs[3];
					GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
					CloseHandle(dp);
					dp = INVALID_HANDLE;
					AcceptEntityInput(entity,"kill");
					int recreate = CreateEntityByName("generic_actor");
					if (recreate != -1)
					{
						char sfch[16];
						Format(sfch,sizeof(sfch),"%i",sf);
						DispatchKeyValue(recreate,"spawnflags",sfch);
						DispatchKeyValue(recreate,"classname","npc_human_scientist");
						DispatchKeyValue(recreate,"targetname",cls);
						DispatchKeyValue(recreate,"CitizenType","4");
						char randsk[8];
						Format(randsk,sizeof(randsk),"%i",GetRandomInt(0,14));
						DispatchKeyValue(recreate,"Skin",randsk);
						Format(randsk,sizeof(randsk),"%i",GetRandomInt(0,14));
						DispatchKeyValue(recreate,"Body",randsk);
						TeleportEntity(recreate,origin,angs,NULL_VECTOR);
						if (sf & 1<<17)
						{
							SetVariantString("spawnflags 1064960");
							AcceptEntityInput(recreate,"AddOutput");
						}
						int rand = GetRandomInt(0,1);
						if (rand == 0) DispatchKeyValue(recreate,"model","models/humans/scientist.mdl");
						else DispatchKeyValue(recreate,"model","models/humans/scientist_02.mdl");
						DispatchSpawn(recreate);
						ActivateEntity(recreate);
						SDKHook(recreate, SDKHook_OnTakeDamage, OnTakeDamage);
						SDKHook(recreate, SDKHook_OnTakeDamage, enttkdmgcust);
						setuprelations("npc_human_scientist");
					}
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
					SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				}
			}
			else if (StrContains(cls,"npc_alien_slave",false) == 0)
			{
				if (FileExists("models/vortigaunt_slave.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					DispatchKeyValue(entity,"classname","npc_alien_slave");
					ReplaceString(cls,sizeof(cls),"npc_alien_slave","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/vortigaunt_slave.mdl");
					WritePackString(dp,"models/vortigaunt_slave.mdl");
					setuprelations("npc_alien_slave");
					SDKHookEx(entity,SDKHook_Think,aslavethink);
					origin[2]+=20.0;
					TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
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
				if ((FileExists("models/zombies/zombie_guard.mdl",true,NULL_STRING)) || (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING)))
				{
					DispatchKeyValue(entity,"classname","npc_zombie_security");
					DispatchKeyValue(entity,"body","0");
					ReplaceString(cls,sizeof(cls),"npc_zombie_security","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					if (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING))
					{
						DispatchKeyValue(entity,"model","models/zombie/zsecurity.mdl");
						WritePackString(dp,"models/zombie/zsecurity.mdl");
					}
					else
					{
						DispatchKeyValue(entity,"model","models/zombies/zombie_guard.mdl");
						WritePackString(dp,"models/zombies/zombie_guard.mdl");
					}
					if (HasEntProp(entity,Prop_Data,"m_nBody")) SetEntProp(entity,Prop_Data,"m_nBody",0);
					setuprelations("npc_zombie_security");
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
					setuprelations("npc_zombie_scientist");
					SDKHookEx(entity,SDKHook_Think,zomthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,zomtkdmg);
				}
			}
			else if (StrContains(cls,"monster_zombie",false) == 0)
			{
				DispatchKeyValue(entity,"classname","monster_zombie");
				ReplaceString(cls,sizeof(cls),"monster_zombie","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				DispatchKeyValue(entity,"model","models/zombie.mdl");
				WritePackString(dp,"models/zombie.mdl");
				setuprelations("monster_zombie");
				SDKHookEx(entity,SDKHook_Think,monstzomthink);
			}
			else if (StrContains(cls,"npc_human_grunt",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
					if (!(sf & 262144))
					{
						SetEntProp(entity,Prop_Data,"m_spawnflags",sf+262144);
					}
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
					SDKHookEx(entity,SDKHook_Think,hgruntthink);
					AcceptEntityInput(entity,"GagEnable");
				}
			}
			else if (StrContains(cls,"npc_human_commander",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
					if (!(sf & 262144))
					{
						SetEntProp(entity,Prop_Data,"m_spawnflags",sf+262144);
					}
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
					SDKHookEx(entity,SDKHook_Think,hgruntthink);
					AcceptEntityInput(entity,"GagEnable");
					//SetEntProp(entity,Prop_Data,"m_fIsElite",1);
				}
			}
			else if (StrContains(cls,"npc_human_grenadier",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
					if (!(sf & 262144))
					{
						SetEntProp(entity,Prop_Data,"m_spawnflags",sf+262144);
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
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
					SDKHookEx(entity,SDKHook_Think,grenthink);
				}
			}
			else if (StrContains(cls,"npc_human_medic",false) == 0)
			{
				if (FileExists("models/humans/marine.mdl",true,NULL_STRING))
				{
					int sf = GetEntProp(entity,Prop_Data,"m_spawnflags");
					if (!(sf & 262144))
					{
						SetEntProp(entity,Prop_Data,"m_spawnflags",sf+262144);
					}
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
			else if (StrContains(cls,"npc_human_assassin",false) == 0)
			{
				if (FileExists("models/humans/hassassin.mdl",true,NULL_STRING))
				{
					ReplaceString(cls,sizeof(cls),"npc_human_assassin","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					if (!IsModelPrecached("models/humans/hassassin.mdl")) PrecacheModel("models/humans/hassassin.mdl",true);
					SDKHookEx(entity,SDKHook_Think,assassinthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,assassintkdmg);
					char mdlchk[64];
					GetEntPropString(entity,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
					if (!StrEqual(mdlchk,"models/humans/hassassin.mdl",false))
					{
						DispatchKeyValue(entity,"model","models/humans/hassassin.mdl");
						SetEntPropString(entity,Prop_Data,"m_ModelName","models/humans/hassassin.mdl");
						SetEntityModel(entity,"models/humans/hassassin.mdl");
					}
					int pistol = CreateEntityByName("prop_physics");
					if (pistol != -1)
					{
						DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
						DispatchKeyValue(pistol,"solid","0");
						SetVariantString("!activator");
						AcceptEntityInput(pistol,"SetParent",entity);
						SetVariantString("anim_attachment_LH");
						AcceptEntityInput(pistol,"SetParentAttachment");
						DispatchSpawn(pistol);
						ActivateEntity(pistol);
						SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",pistol);
						/*
						float vmins[3];
						float vmaxs[3];
						GetEntPropVector(pistol,Prop_Data,"m_vecMins",vmins);
						GetEntPropVector(pistol,Prop_Data,"m_vecMaxs",vmaxs);
						int mainturret = CreateEntityByName("func_tank");
						if (mainturret != -1)
						{
							DispatchKeyValue(mainturret,"spawnflags","1");
							DispatchKeyValue(mainturret,"model","*1");
							DispatchKeyValue(mainturret,"rendermode","10");
							DispatchKeyValue(mainturret,"yawrate","30");
							DispatchKeyValue(mainturret,"yawrange","180");
							DispatchKeyValue(mainturret,"yawtolerance","45");
							DispatchKeyValue(mainturret,"pitchtolerance","45");
							DispatchKeyValue(mainturret,"pitchrange","60");
							DispatchKeyValue(mainturret,"pitchrate","120");
							DispatchKeyValue(mainturret,"barrel","100");
							DispatchKeyValue(mainturret,"barrelz","8");
							DispatchKeyValue(mainturret,"bullet","2");
							DispatchKeyValue(mainturret,"ignoregraceupto","768");
							DispatchKeyValue(mainturret,"firerate","15");
							DispatchKeyValue(mainturret,"firespread","3");
							DispatchKeyValue(mainturret,"persistence","3");
							DispatchKeyValue(mainturret,"maxRange","2048");
							DispatchKeyValue(mainturret,"spritescale","1");
							DispatchKeyValue(mainturret,"gun_base_attach","muzzle");
							DispatchKeyValue(mainturret,"gun_barrel_attach","muzzle");
							DispatchKeyValue(mainturret,"ammo_count","-1");
							DispatchKeyValue(mainturret,"effecthandling","1");
							DispatchSpawn(mainturret);
							ActivateEntity(mainturret);
							SetVariantString("!activator");
							AcceptEntityInput(mainturret,"SetParent",pistol);
							SetVariantString("muzzle");
							AcceptEntityInput(mainturret,"SetParentAttachment");
							SetEntPropVector(mainturret,Prop_Data,"m_vecMins",vmins);
							SetEntPropVector(mainturret,Prop_Data,"m_vecMaxs",vmaxs);
							SetVariantString("!player");
							AcceptEntityInput(mainturret,"SetTargetEntityName");
						}
						*/
					}
					pistol = CreateEntityByName("prop_physics");
					if (pistol != -1)
					{
						DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
						DispatchKeyValue(pistol,"solid","0");
						SetVariantString("!activator");
						AcceptEntityInput(pistol,"SetParent",entity);
						SetVariantString("anim_attachment_RH");
						AcceptEntityInput(pistol,"SetParentAttachment");
						DispatchSpawn(pistol);
						ActivateEntity(pistol);
						SetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity",pistol);
					}
					if (FindStringInArray(precachedarr,"npc_human_assassin") == -1)
					{
						char searchprecache[128];
						Format(searchprecache,sizeof(searchprecache),"sound/weapons/glock/");
						recursion(searchprecache);
						Format(searchprecache,sizeof(searchprecache),"sound/npc/assassin/");
						recursion(searchprecache);
						PushArrayString(precachedarr,"npc_human_assassin");
					}
				}
				CloseHandle(dp);
				dp = INVALID_HANDLE;
			}
			else if (StrContains(cls,"monster_human_assassin",false) == 0)
			{
				if (FileExists("models/hassassin.mdl",true,NULL_STRING))
				{
					ReplaceString(cls,sizeof(cls),"monster_human_assassin","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					SDKHookEx(entity,SDKHook_Think,assassinthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,assassintkdmg);
					if (FindStringInArray(precachedarr,"monster_human_assassin") == -1)
					{
						PrecacheSound("common\\bodydrop1.wav",true);
						PrecacheSound("common\\bodydrop2.wav",true);
						PrecacheSound("common\\bodydrop3.wav",true);
						PrecacheSound("common\\bodydrop4.wav",true);
						PrecacheSound("weapons\\pl_gun1.wav",true);
						PrecacheSound("weapons\\pl_gun2.wav",true);
						PushArrayString(precachedarr,"monster_human_assassin");
					}
				}
				CloseHandle(dp);
				dp = INVALID_HANDLE;
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
					SDKHookEx(entity,SDKHook_Think,ospreythink);
				}
			}
			else if ((StrContains(cls,"npc_apache",false) == 0) || (StrEqual(entcls,"npc_apache",false)))
			{
				WritePackString(dp,"models/props_vehicles/apache.mdl");
				SDKHookEx(entity,SDKHook_Think,apachethink);
				SDKHookEx(entity,SDKHook_OnTakeDamage,apachetkdmg);
			}
			else if (StrContains(cls,"npc_houndeye",false) == 0)
			{
				if (FileExists("models/xenians/houndeye.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"model","models/xenians/houndeye.mdl");
					WritePackString(dp,"models/xenians/houndeye.mdl");
				}
				else if (FileExists("models/_monsters/xen/houndeye.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"model","models/_monsters/xen/houndeye.mdl");
					WritePackString(dp,"models/_monsters/xen/houndeye.mdl");
				}
				SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
				DispatchKeyValue(entity,"classname","npc_houndeye");
				ReplaceString(cls,sizeof(cls),"npc_houndeye","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				setuprelations("npc_houndeye");
				AcceptEntityInput(entity,"GagEnable");
				origin[2]+=20.0;
				TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
				setuphound(entity);
			}
			else if (StrContains(cls,"monster_houndeye",false) == 0)
			{
				if (FileExists("models/houndeye.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"model","models/houndeye.mdl");
					WritePackString(dp,"models/houndeye.mdl");
				}
				SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
				DispatchKeyValue(entity,"classname","monster_houndeye");
				ReplaceString(cls,sizeof(cls),"monster_houndeye","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				setuprelations("monster_houndeye");
				AcceptEntityInput(entity,"GagEnable");
				origin[2]+=20.0;
				TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
				setuphound(entity);
			}
			else if (StrContains(cls,"npc_bullsquid",false) == 0)
			{
				if (FileExists("models/xenians/bullsquid.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					DispatchKeyValue(entity,"classname","npc_bullsquid");
					ReplaceString(cls,sizeof(cls),"npc_bullsquid","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/bullsquid.mdl");
					WritePackString(dp,"models/xenians/bullsquid.mdl");
					AcceptEntityInput(entity,"GagEnable");
					origin[2]+=20.0;
					TeleportEntity(entity,origin,NULL_VECTOR,NULL_VECTOR);
					setupsquid(entity);
				}
			}
			else if ((StrContains(cls,"npc_alien_grunt",false) == 0) || (StrEqual(entcls,"npc_alien_grunt",false)))
			{
				if (FileExists("models/xenians/agrunt.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					DispatchKeyValue(entity,"classname","npc_alien_grunt");
					ReplaceString(cls,sizeof(cls),"npc_alien_grunt","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/agrunt.mdl");
					WritePackString(dp,"models/xenians/agrunt.mdl");
					AcceptEntityInput(entity,"GagEnable");
					SDKHookEx(entity,SDKHook_Think,agruntthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,agrunttkdmg);
					setuprelations("npc_alien_grunt");
				}
			}
			else if ((StrContains(cls,"npc_alien_grunt_unarmored",false) == 0) || (StrEqual(entcls,"npc_alien_grunt_unarmored",false)))
			{
				if (FileExists("models/xenians/agrunt_unarmored.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					DispatchKeyValue(entity,"classname","npc_alien_grunt_unarmored");
					ReplaceString(cls,sizeof(cls),"npc_alien_grunt_unarmored","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/xenians/agrunt_unarmored.mdl");
					WritePackString(dp,"models/xenians/agrunt_unarmored.mdl");
					setuprelations("npc_alien_grunt_unarmored");
				}
			}
			else if ((StrContains(cls,"monster_alien_grunt",false) == 0) || (StrEqual(entcls,"monster_alien_grunt",false)))
			{
				if (FileExists("models/agrunt.mdl",true,NULL_STRING))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					DispatchKeyValue(entity,"classname","monster_alien_grunt");
					ReplaceString(cls,sizeof(cls),"monster_alien_grunt","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/agrunt.mdl");
					WritePackString(dp,"models/agrunt.mdl");
					AcceptEntityInput(entity,"GagEnable");
					SDKHookEx(entity,SDKHook_Think,agruntthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,agrunttkdmg);
					setuprelations("npc_alien_grunt");
				}
			}
			else if (StrContains(cls,"monster_gargantua",false) == 0)
			{
				if (FileExists("models/garg.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","monster_gargantua");
					ReplaceString(cls,sizeof(cls),"monster_gargantua","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
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
					if (resetname)
					{
						ReplaceString(cls,sizeof(cls),"npc_snark","");
						SetEntPropString(entity,Prop_Data,"m_iName",cls);
					}
					DispatchKeyValue(entity,"model","models/xenians/snark.mdl");
					WritePackString(dp,"models/xenians/snark.mdl");
					SDKHookEx(entity,SDKHook_Think,snarkthink);
					SDKHook(entity,SDKHook_StartTouch,StartTouchSnark);
				}
			}
			else if (StrContains(cls,"monster_snark",false) == 0)
			{
				if (FileExists("models/w_squeak.mdl",true,NULL_STRING))
				{
					if (FindStringInArray(precachedarr,"monster_snark") == -1)
					{
						char searchprecache[128];
						Format(searchprecache,sizeof(searchprecache),"sound/squeek/");
						recursion(searchprecache);
						PushArrayString(precachedarr,"monster_snark");
					}
					DispatchKeyValue(entity,"classname","monster_snark");
					if (resetname)
					{
						ReplaceString(cls,sizeof(cls),"monster_snark","");
						SetEntPropString(entity,Prop_Data,"m_iName",cls);
					}
					DispatchKeyValue(entity,"model","models/w_squeak.mdl");
					WritePackString(dp,"models/w_squeak.mdl");
					SDKHookEx(entity,SDKHook_Think,snarkthink);
					SDKHook(entity,SDKHook_StartTouch,StartTouchSnark);
				}
				else
				{
					CloseHandle(dp);
					dp = INVALID_HANDLE;
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
						recursion("sound/weapons/50cal/");
						recursion("sound/weapons/m4/");
						PushArrayString(precachedarr,"npc_abrams");
					}
					DispatchKeyValue(entity,"classname","npc_abrams");
					ReplaceString(cls,sizeof(cls),"npc_abrams","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					DispatchKeyValue(entity,"model","models/props_vehicles/abrams.mdl");
					CloseHandle(dp);
					dp = INVALID_HANDLE;
					float orgs[3];
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
					float angs[3];
					GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
					int boundbox = CreateEntityByName("prop_dynamic");
					if (boundbox != -1)
					{
						if (strlen(cls) < 1)
						{
							Format(cls,sizeof(cls),"npc_abrams%i",entity);
							SetEntPropString(entity,Prop_Data,"m_iName",cls);
						}
						char boundbtarg[64];
						Format(boundbtarg,sizeof(boundbtarg),"abramsbox%i",boundbox);
						DispatchKeyValue(boundbox,"rendermode","10");
						DispatchKeyValue(boundbox,"solid","6");
						DispatchKeyValue(boundbox,"model","models/props_vehicles/abrams.mdl");
						TeleportEntity(boundbox,orgs,angs,NULL_VECTOR);
						DispatchSpawn(boundbox);
						ActivateEntity(boundbox);
						SetVariantString("!activator");
						AcceptEntityInput(boundbox,"SetParent",entity);
						SDKHookEx(boundbox,SDKHook_OnTakeDamage,abramstkdmg);
						SDKHookEx(entity,SDKHook_OnTakeDamage,abramstkdmg);
						SetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity",boundbox);
						int logcoll = CreateEntityByName("logic_collision_pair");
						if (logcoll != -1)
						{
							DispatchKeyValue(logcoll,"attach1",cls);
							DispatchKeyValue(logcoll,"attach2",boundbtarg);
							DispatchKeyValue(logcoll,"StartDisabled","1");
							DispatchSpawn(logcoll);
							ActivateEntity(logcoll);
						}
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
					if (HasEntProp(entity,Prop_Data,"m_iHealth"))
					{
						int hchk = GetEntProp(entity,Prop_Data,"m_iHealth");
						int maxh = 250;
						if (hchk != maxh)
						{
							SetEntProp(entity,Prop_Data,"m_iMaxHealth",maxh);
							SetEntProp(entity,Prop_Data,"m_iHealth",maxh);
						}
					}
					SDKHookEx(entity,SDKHook_Think,abramsthink);
				}
			}
			else if (StrContains(cls,"npc_alien_controller",false) == 0)
			{
				if (FileExists("models/xenians/controller.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"classname","npc_alien_controller");
					ReplaceString(cls,sizeof(cls),"npc_alien_controller","");
					SetEntPropString(entity,Prop_Data,"m_iName",cls);
					if (FindStringInArray(precachedarr,"npc_alien_controller") == -1)
					{
						recursion("sound/npc/alien_controller/");
						PushArrayString(precachedarr,"npc_alien_controller");
					}
					if (HasEntProp(entity,Prop_Data,"m_iHealth"))
					{
						int maxh = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
						Handle cvar = FindConVar("sk_controller_health");
						if (cvar != INVALID_HANDLE)
						{
							int maxhchk = GetConVarInt(cvar);
							if (maxh != maxhchk)
							{
								SetEntProp(entity,Prop_Data,"m_iHealth",maxhchk);
								SetEntProp(entity,Prop_Data,"m_iMaxHealth",maxhchk);
							}
						}
						CloseHandle(cvar);
					}
					if (HasEntProp(entity,Prop_Data,"m_bloodColor")) SetEntProp(entity,Prop_Data,"m_bloodColor",1);
					SDKHookEx(entity,SDKHook_Think,controllerthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,controllertkdmg);
					PushArrayCell(controllers,entity);
					char mdlchk[64];
					GetEntPropString(entity,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
					if (StrEqual(mdlchk,"models/vortigaunt.mdl",false))
					{
						WritePackString(dp,"models/xenians/controller.mdl");
					}
					else
					{
						CloseHandle(dp);
						dp = INVALID_HANDLE;
					}
				}
			}
			else if (StrContains(cls,"npc_gonarch",false) == 0)
			{
				DispatchKeyValue(entity,"classname","npc_gonarch");
				ReplaceString(cls,sizeof(cls),"npc_gonarch","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				if (FileExists("models/xenians/gonarch.mdl",true,NULL_STRING))
				{
					DispatchKeyValue(entity,"model","models/xenians/gonarch.mdl");
					WritePackString(dp,"models/xenians/gonarch.mdl");
				}
				else
				{
					DispatchKeyValue(entity,"model","models/gonarch.mdl");
					WritePackString(dp,"models/gonarch.mdl");
				}
			}
			else if ((StrContains(cls,"npc_babycrab",false) == 0) || (StrEqual(entcls,"npc_babycrab",false)))
			{
				DispatchKeyValue(entity,"classname","npc_babycrab");
				ReplaceString(cls,sizeof(cls),"npc_babycrab","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				if (FileExists("models/xenians/babyheadcrab.mdl",true,NULL_STRING))
					WritePackString(dp,"models/xenians/babyheadcrab.mdl");
				else
					WritePackString(dp,"models/xenians/headcrab.mdl");
			}
			else if (StrContains(cls,"npc_sentry_ceiling",false) == 0)
			{
				DispatchKeyValue(entity,"classname","npc_sentry_ceiling");
				ReplaceString(cls,sizeof(cls),"npc_sentry_ceiling","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				if (FileExists("models/NPCs/sentry_ceiling.mdl",true,NULL_STRING))
				{
					WritePackString(dp,"models/NPCs/sentry_ceiling.mdl");
					if (FindStringInArray(precachedarr,"npc_sentry_ground") == -1)
					{
						PrecacheSound("weapons\\mp5\\empty.wav",true);
						recursion("sound/npc/sentry_ceiling/");
						PushArrayString(precachedarr,"npc_sentry_ground");
					}
					int mhchk = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
					Handle cvar = FindConVar("sk_sentry_ceiling_health");
					if (cvar != INVALID_HANDLE)
					{
						int cvarh = GetConVarInt(cvar);
						if (mhchk != cvarh)
						{
							SetEntProp(entity,Prop_Data,"m_iHealth",cvarh);
							SetEntProp(entity,Prop_Data,"m_iMaxHealth",cvarh);
						}
					}
					CloseHandle(cvar);
					SDKHookEx(entity,SDKHook_Think,sentriesthink);
				}
			}
			else if (StrContains(cls,"npc_sentry_ground",false) == 0)
			{
				DispatchKeyValue(entity,"classname","npc_sentry_ground");
				ReplaceString(cls,sizeof(cls),"npc_sentry_ground","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				if (FileExists("models/NPCs/sentry_ground.mdl",true,NULL_STRING))
				{
					WritePackString(dp,"models/NPCs/sentry_ground.mdl");
					if (FindStringInArray(precachedarr,"npc_sentry_ground") == -1)
					{
						PrecacheSound("weapons\\mp5\\empty.wav",true);
						recursion("sound/npc/sentry_ground/");
						PushArrayString(precachedarr,"npc_sentry_ground");
					}
					if (HasEntProp(entity,Prop_Data,"m_bloodColor")) SetEntProp(entity,Prop_Data,"m_bloodColor",3);
					SDKHookEx(entity,SDKHook_Think,sentriesthink);
					SDKHookEx(entity,SDKHook_OnTakeDamage,notkdmg);
				}
			}
			else
			{
				CloseHandle(dp);
				dp = INVALID_HANDLE;
				return;
			}
			if (dp != INVALID_HANDLE)
			{
				WritePackCell(dp,entity);
				GetEntityClassname(entity,entcls,sizeof(entcls));
				WritePackString(dp,entcls);
				CreateTimer(0.1,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			else CloseHandle(dp);
			CreateTimer(0.1,resethealth,entity,TIMER_FLAG_NO_MAPCHANGE);
			//origin[2]-=40.0;
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
			if (HasEntProp(entity,Prop_Data,"m_SquadName"))
			{
				char squadchk[32];
				GetEntPropString(entity,Prop_Data,"m_SquadName",squadchk,sizeof(squadchk));
				if (strlen(squadchk) > 0)
				{
					for (int i = 0;i<GetArraySize(entlist);i++)
					{
						int j = GetArrayCell(entlist,i);
						if (IsValidEntity(j))
						{
							if (HasEntProp(j,Prop_Data,"m_SquadName"))
							{
								char tmpsq[64];
								GetEntPropString(j,Prop_Data,"m_SquadName",squadchk,sizeof(squadchk));
								if (StrEqual(squadchk,tmpsq,false))
								{
									if (strlen(cls) > 0)
									{
										char rel[128];
										char tmpname[64];
										GetEntPropString(j,Prop_Data,"m_iName",tmpname,sizeof(tmpname));
										if (strlen(tmpname) > 0)
										{
											Format(rel,sizeof(rel),"%s D_LI 99",tmpname);
											SetVariantString(rel);
											AcceptEntityInput(entity,"SetRelationship");
											Format(rel,sizeof(rel),"%s D_LI 99",cls);
											SetVariantString(rel);
											AcceptEntityInput(j,"SetRelationship");
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
	return;
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
		AddRel("npc_alien_slave","player","1","99");
		AddRel("npc_alien_controller","npc_alien_slave","3","99");
		AddRel("npc_alien_controller","npc_alien_grunt","3","99");
		AddRel("npc_alien_controller","npc_alien_grunt_unarmored","3","99");
		AddRel("npc_alien_controller","npc_houndeye","3","99");
		AddRel("npc_alien_controller","npc_bullsquid","3","99");
		AddRel("npc_alien_controller","player","1","99");
		AddRel("npc_alien_grunt","player","1","99");
		AddRel("npc_alien_grunt","npc_alien_slave","3","99");
		AddRel("npc_alien_grunt","npc_human_grenadier","1","80");
		AddRel("npc_alien_grunt","npc_human_commander","1","80");
		AddRel("npc_alien_grunt","npc_human_medic","1","80");
		AddRel("npc_alien_grunt","npc_human_grunt","1","80");
		AddRel("npc_alien_grunt","npc_turret_ceiling","1","40");
		AddRel("npc_alien_grunt","npc_headcrab","3","99");
		AddRel("npc_alien_grunt","npc_gargantua","3","99");
		AddRel("monster_alien_grunt","player","1","99");
		AddRel("monster_alien_grunt","npc_alien_slave","3","99");
		AddRel("monster_alien_grunt","npc_human_grenadier","1","80");
		AddRel("monster_alien_grunt","npc_human_commander","1","80");
		AddRel("monster_alien_grunt","npc_human_medic","1","80");
		AddRel("monster_alien_grunt","npc_human_grunt","1","80");
		AddRel("monster_alien_grunt","npc_turret_ceiling","1","40");
		AddRel("monster_alien_grunt","npc_headcrab","3","99");
		AddRel("monster_alien_grunt","npc_gargantua","3","99");
		AddRel("monster_alien_grunt","npc_alien_grunt","3","99");
	}
	else if (StrEqual(cls,"npc_houndeye",false))
	{
		AddRel(cls,"npc_human_scientist","1","80");
		AddRel(cls,"npc_human_security","1","80");
		AddRel(cls,"npc_alien_slave","3","80");
	}
	else if ((StrEqual(cls,"npc_zombie_scientist",false)) || (StrEqual(cls,"npc_zombie_security",false)))
	{
		AddRel("npc_zombie_security","npc_human_security","1","80");
		AddRel("npc_zombie_security","npc_gman","3","99");
		AddRel("npc_zombie_scientist","npc_human_security","1","80");
		AddRel("npc_zombie_scientist","npc_gman","3","99");
		AddRel("npc_barnacle","npc_human_scientist","1","80");
	}
	else if (StrEqual(cls,"npc_human_scientist",false))
	{
		AddRel(cls,"npc_sentry_ground","1","80");
		AddRel(cls,"npc_human_grunt","1","80");
		AddRel(cls,"npc_human_commander","1","80");
		AddRel(cls,"npc_human_grenadier","1","80");
		AddRel(cls,"npc_human_medic","1","80");
		AddRel(cls,"npc_alien_slave","1","80");
		AddRel(cls,"npc_alien_grunt","1","80");
		AddRel(cls,"npc_barnacle","1","80");
		AddRel(cls,"npc_sniper","1","80");
	}
	else if (StrEqual(cls,"npc_human_security",false))
	{
		AddRel(cls,"npc_sentry_ground","1","80");
		AddRel(cls,"npc_human_grunt","1","80");
		AddRel(cls,"npc_human_commander","1","80");
		AddRel(cls,"npc_human_grenadier","1","80");
		AddRel(cls,"npc_human_medic","1","80");
		AddRel(cls,"npc_alien_slave","1","80");
		AddRel(cls,"npc_alien_grunt","1","80");
		AddRel(cls,"npc_barnacle","1","80");
	}
	else if (StrEqual(cls,"npc_abrams",false))
	{
		AddRel(cls,"player","1","80");
		AddRel(cls,"npc_alien_slave","1","80");
		AddRel(cls,"npc_alien_grunt","1","80");
	}
	else if (StrEqual(cls,"npc_bmsgargantua",false))
	{
		AddRel(cls,"npc_zombie","1","70");
		AddRel(cls,"npc_zombine","1","70");
		AddRel(cls,"npc_zombie_scientist","1","70");
		AddRel(cls,"npc_zombie_security","1","70");
		AddRel(cls,"npc_human_scientist","1","70");
		AddRel(cls,"npc_human_security","1","70");
		AddRel(cls,"npc_human_assassin","1","70");
		AddRel(cls,"npc_human_commander","1","70");
		AddRel(cls,"npc_human_grenadier","1","70");
		AddRel(cls,"npc_human_grunt","1","70");
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

void AddRel(char[] cls, char[] target, char[] disp, char[] rank)
{
	int aidisp = CreateEntityByName("ai_relationship");
	DispatchKeyValue(aidisp,"disposition",disp);
	DispatchKeyValue(aidisp,"subject",cls);
	DispatchKeyValue(aidisp,"target",target);
	DispatchKeyValue(aidisp,"targetname","syn_relations");
	DispatchKeyValue(aidisp,"rank",rank);
	DispatchKeyValue(aidisp,"reciprocal","1");
	DispatchKeyValue(aidisp,"StartActive","1");
	DispatchSpawn(aidisp);
	ActivateEntity(aidisp);
	AcceptEntityInput(aidisp,"ApplyRelationship");
	PushArrayCell(customrelations,aidisp);
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

void addht(char[] cls, char[] targn)
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

void addli(char[] cls, char[] targn)
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
			char globalname[64];
			GetEntPropString(i,Prop_Data,"m_iGlobalname",globalname,sizeof(globalname));
			bool saveent = false;
			if ((FindValueInArray(hounds,i) != -1) || (FindValueInArray(houndsmdl,i) != -1) || (FindValueInArray(squids,i) != -1) || (FindValueInArray(squidsmdl,i) != -1) || (FindValueInArray(tents,i) != -1) || (FindValueInArray(tentsmdl,i) != -1) || (FindValueInArray(tentssnd,i) != -1) || (FindStringInArray(customentlist,clsname) != -1)) saveent = true;
			if ((strlen(globalname) > 0) && ((StrEqual(clsname,"prop_physics",false)) || (StrEqual(clsname,"func_tracktrain",false)))) saveent = true;
			if (saveent)
			{
				char targent[8];
				if (StrContains(clsname,"weapon_",false) == 0)
				{
					if (HasEntProp(i,Prop_Data,"m_hOwner"))
					{
						int ownerent = GetEntPropEnt(i,Prop_Data,"m_hOwner");
						if (ownerent != -1)
						{
							Format(targent,sizeof(targent),"%i",ownerent);
						}
					}
				}
				Handle dp = packent(i,targent);
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
			ClearArray(controllers);
			ClearArray(templateslist);
			ClearArray(equiparr);
			ClearArray(merchantscr);
			ClearArray(merchantscrd);
			for (int i = 1;i<GetMaxEntities();i++)
			{
				isattacking[i] = 0;
				if (i < MaxClients+1)
				{
					fadingtime[i] = 0.0;
					antispamchk[i] = 0.0;
					if (IsValidEntity(i))
					{
						if (IsClientConnected(i))
						{
							if (IsClientInGame(i))
							{
								if (IsPlayerAlive(i))
								{
									if (HasEntProp(i,Prop_Data,"m_bWearingSuit"))
									{
										if (GetEntProp(i,Prop_Data,"m_bWearingSuit") < 1)
										{
											RecheckEquips(-1,i,false);
										}
									}
								}
							}
						}
					}
				}
			}
			findstraymdl(-1,"prop_dynamic");
			findstraymdl(-1,"point_template");
			findstraymdl(-1,"npc_template_maker");
			findstraymdl(-1,"env_xen_portal_template");
			findstraymdl(-1,"env_xen_pushpad");
			findstraymdl(-1,"env_mortar_controller");
			findstraymdl(-1,"env_dispenser");
			findent(MaxClients+1,"info_player_equip");
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
			findstraymdl(-1,"trigger_once");
			resetchargers(-1,"item_healthcharger");
			resetchargers(-1,"item_suitcharger");
		}
	}
	return Plugin_Continue;
}

void RecheckEquips(int ent, int client, bool equipping)
{
	int findequip = FindEntityByClassname(ent,"info_player_equip");
	if ((findequip != 0) && (IsValidEntity(findequip)))
	{
		if (HasEntProp(findequip,Prop_Data,"m_ItemNames"))
		{
			if (equipping)
			{
				AcceptEntityInput(findequip,"EquipPlayer",client);
			}
			else
			{
				for (int j = 0;j<8;j++)
				{
					char itemname[24];
					GetEntPropString(findequip,Prop_Data,"m_ItemNames",itemname,sizeof(itemname),j);
					if (StrEqual(itemname,"item_suit",false))
					{
						if (GetEntProp(findequip,Prop_Data,"m_ItemValues",_,j) > 0)
						{
							AcceptEntityInput(findequip,"EquipPlayer",client);
							equipping = true;
						}
					}
				}
			}
		}
		RecheckEquips(findequip++,client,equipping);
	}
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
			Format(npctargpath,sizeof(npctargpath),"%s",targpass);
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

void findinfotarg(int ent, char[] findtargname, int entity)
{
	int thisent = FindEntityByClassname(ent,"info_target");
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		char targn[64];
		if (HasEntProp(thisent,Prop_Data,"m_iName")) GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
		if (StrEqual(findtargname,targn))
		{
			SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",thisent);
			return;
		}
		else findinfotarg(thisent++,findtargname,entity);
	}
	return;
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
		if (StrEqual(clsname,"item_weapon_mp5",false)) Format(clsname,sizeof(clsname),"weapon_mp5");
		Format(oldcls,sizeof(oldcls),"%s",clsname);
		if (StrEqual(clsname,"npc_human_scientist_kleiner",false))
			Format(clsname,sizeof(clsname),"npc_kleiner");
		else if (StrEqual(clsname,"npc_human_scientist_eli",false))
			Format(clsname,sizeof(clsname),"npc_eli");
		else if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_human_grenadier",false)) || (StrEqual(clsname,"npc_assassin",false)) || (StrEqual(clsname,"npc_human_assassin",false)) || (StrEqual(clsname,"monster_human_assassin",false)))
			Format(clsname,sizeof(clsname),"npc_combine_s");
		else if (StrEqual(clsname,"monster_headcrab",false))
			Format(clsname,sizeof(clsname),"npc_headcrab");
		else if ((StrEqual(clsname,"npc_human_security",false)) && (!StrEqual(additionalequip,"Default",false)) && (strlen(additionalequip) > 1))
			Format(clsname,sizeof(clsname),"npc_citizen");
		else if (StrEqual(clsname,"npc_odell",false))
			Format(clsname,sizeof(clsname),"npc_citizen");
		else if ((StrContains(clsname,"npc_human_",false) != -1) || (StrEqual(clsname,"npc_abrams",false)) || (StrEqual(clsname,"npc_tentacle",false)) || (StrEqual(clsname,"monster_bullchicken",false)) || (StrEqual(clsname,"monster_cockroach",false)) || (StrEqual(clsname,"monster_human_grunt",false)) || (StrEqual(clsname,"monster_hgrunt_dead",false)) || (StrEqual(clsname,"monster_sentry",false)) || (StrEqual(clsname,"monster_scientist",false)) || (StrEqual(clsname,"monster_osprey",false)) || (StrEqual(clsname,"monster_gman",false)) || (StrEqual(clsname,"monster_scientist_dead",false)) || (StrEqual(clsname,"monster_barney",false)) || (StrEqual(clsname,"monster_barney_dead",false)))
			Format(clsname,sizeof(clsname),"generic_actor");
		else if (StrEqual(clsname,"monster_barnacle",false))
			Format(clsname,sizeof(clsname),"npc_barnacle");
		else if ((StrEqual(clsname,"monster_zombie",false)) || (StrEqual(clsname,"npc_zombie_scientist",false)))
			Format(clsname,sizeof(clsname),"npc_zombie");
		else if (StrEqual(clsname,"npc_zombie_scientist_torso",false))
			Format(clsname,sizeof(clsname),"npc_zombie_torso");
		else if (StrEqual(clsname,"logic_player_branch"))
				Format(clsname,sizeof(clsname),"math_counter");
		else if ((StrEqual(clsname,"monster_alien_slave",false)) || (StrEqual(clsname,"npc_alien_slave",false)) || (StrEqual(clsname,"npc_alien_controller",false)))
			Format(clsname,sizeof(clsname),"npc_vortigaunt");
		else if ((StrEqual(clsname,"npc_zombie_security",false)) || (StrEqual(clsname,"npc_zombie_security_torso",false)) || (StrEqual(clsname,"npc_gonarch",false)) || (StrEqual(clsname,"npc_zombie_worker",false)))
			Format(clsname,sizeof(clsname),"npc_zombine");
		else if ((StrEqual(clsname,"npc_osprey",false)) || (StrEqual(clsname,"npc_bmsgargantua",false)))
			Format(clsname,sizeof(clsname),"generic_actor");
		else if ((StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"monster_houndeye",false)) || (StrEqual(clsname,"npc_bullsquid",false)))
			Format(clsname,sizeof(clsname),"npc_antlion");
		else if (StrEqual(clsname,"npc_snark",false))
			Format(clsname,sizeof(clsname),"npc_headcrab_fast");
		else if ((StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"npc_alien_grunt_unarmored",false)))
			Format(clsname,sizeof(clsname),"npc_combine_s");
		else if (StrEqual(clsname,"grenade_tripmine",false))
			Format(clsname,sizeof(clsname),"prop_physics");
		else if (StrEqual(clsname,"npc_apache",false))
			Format(clsname,sizeof(clsname),"npc_helicopter");
		else if (StrEqual(clsname,"npc_babycrab",false))
			Format(clsname,sizeof(clsname),"npc_headcrab");
		else if (StrEqual(clsname,"item_longjump",false))
			Format(clsname,sizeof(clsname),"item_healthkit");
		else if (StrEqual(clsname,"weapon_immolator",false))
			Format(clsname,sizeof(clsname),"weapon_physcannon");
		else if (StrEqual(clsname,"weapon_camera",false))
			Format(clsname,sizeof(clsname),"weapon_slam");
		else if ((StrEqual(clsname,"weapon_manhack",false)) || (StrEqual(clsname,"weapon_manhacktoss",false)))
			Format(clsname,sizeof(clsname),"weapon_pistol");
		else if (StrEqual(clsname,"weapon_cguard",false))
			Format(clsname,sizeof(clsname),"weapon_stunstick");
		else if (StrEqual(clsname,"weapon_axe",false))
			Format(clsname,sizeof(clsname),"weapon_pipe");
		else if ((StrEqual(clsname,"item_ammo_flare_box",false)) || (StrEqual(clsname,"item_box_flare_rounds",false)))
			Format(clsname,sizeof(clsname),"item_ammo_pistol");
		else if (StrEqual(clsname,"item_ammo_mp5",false))
			Format(clsname,sizeof(clsname),"item_ammo_smg1");
		else if (StrEqual(clsname,"env_mortar_launcher"))
			Format(clsname,sizeof(clsname),"info_target");
		else if (StrEqual(clsname,"env_mortar_controller"))
			Format(clsname,sizeof(clsname),"prop_physics_override");
		else if (StrEqual(clsname,"monster_ichthyosaur",false))
			Format(clsname,sizeof(clsname),"npc_ichthyosaur");
		else if ((StrEqual(clsname,"weapon_gluon",false)) || (StrEqual(clsname,"weapon_goop",false)))
			Format(clsname,sizeof(clsname),"weapon_shotgun");
		else if (StrEqual(clsname,"weapon_handgrenade",false))
			Format(clsname,sizeof(clsname),"weapon_frag");
		else if ((StrEqual(clsname,"weapon_glock",false)) || (StrEqual(clsname,"weapon_pistol_worker",false)) || (StrEqual(clsname,"weapon_flaregun",false)) || (StrEqual(clsname,"weapon_manhack",false)) || (StrEqual(clsname,"weapon_manhackgun",false)) || (StrEqual(clsname,"weapon_manhacktoss",false)))
			Format(clsname,sizeof(clsname),"weapon_pistol");
		else if ((StrEqual(clsname,"weapon_medkit",false)) || (StrEqual(clsname,"weapon_healer",false)) || (StrEqual(clsname,"weapon_snark",false)) || (StrEqual(clsname,"weapon_hivehand",false)) || (StrEqual(clsname,"weapon_satchel",false)) || (StrEqual(clsname,"weapon_tripmine",false)) || (StrEqual(clsname,"weapon_molotov",false)))
			Format(clsname,sizeof(clsname),"weapon_slam");
		else if ((StrEqual(clsname,"weapon_mp5",false)) || (StrEqual(clsname,"weapon_sl8",false)) || (StrEqual(clsname,"weapon_uzi",false)) || (StrEqual(clsname,"weapon_oicw",false)) || (StrEqual(clsname,"weapon_camera",false)))
			Format(clsname,sizeof(clsname),"weapon_smg1");
		else if ((StrEqual(clsname,"weapon_gauss",false)) || (StrEqual(clsname,"weapon_tau",false)) || (StrEqual(clsname,"weapon_sniperrifle",false)) || (StrEqual(clsname,"weapon_bhg",false)))
			Format(clsname,sizeof(clsname),"weapon_ar2");
		int ent = CreateEntityByName(clsname);
		if ((TR_PointOutsideWorld(porigin)) && (ent != -1))
		{
			AcceptEntityInput(ent,"kill");
			ent = -1;
		}
		//PrintToServer("RestoreEntDP %i %s %1.f %1.f %1.f",ent,clsname,porigin[0],porigin[1],porigin[2]);
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
			if (strlen(targetpath) > 0)
			{
				DispatchKeyValue(ent,"target",targetpath);
				if ((StrContains(oldcls,"weapon_",false) == 0) && (HasEntProp(ent,Prop_Data,"m_hOwner")))
				{
					int clat = StringToInt(targetpath);
					if ((IsValidEntity(clat)) && (clat != 0) && (clat < MaxClients+1))
					{
						if (HasEntProp(clat,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(clat,Prop_Data,"m_vecAbsOrigin",porigin);
						else if (HasEntProp(clat,Prop_Send,"m_vecOrigin")) GetEntPropVector(clat,Prop_Send,"m_vecOrigin",porigin);
						porigin[2]+=20.0;
					}
				}
			}
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
				setuphound(ent);
			}
			else if (StrEqual(oldcls,"npc_bullsquid",false))
			{
				setupsquid(ent);
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
				SetEntPropEnt(entmdl,Prop_Data,"m_hOwnerEntity",ent);
				int entsnd = CreateEntityByName("ambient_generic");
				DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
				DispatchSpawn(entsnd);
				ActivateEntity(entsnd);
				SetVariantString("!activator");
				AcceptEntityInput(entsnd,"SetParent",entmdl);
				SetVariantString("Eye");
				AcceptEntityInput(entsnd,"SetParentAttachment");
				PushArrayCell(tentssnd,entsnd);
				SetEntPropEnt(entmdl,Prop_Data,"m_hEffectEntity",entsnd);
				SDKHookEx(ent,SDKHook_Think,tentaclethink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,tentacletkdmg);
				HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
			}
			else if (StrContains(oldcls,"npc_zombie_s",false) == 0)
			{
				SDKHookEx(ent,SDKHook_Think,zomthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
			}
			else if ((StrEqual(oldcls,"npc_ichthyosaur",false)) || (StrEqual(oldcls,"monster_ichthyosaur",false)))
			{
				SetEntProp(ent,Prop_Data,"m_MoveType",7);
				if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",2);
				SDKHookEx(ent,SDKHook_Think,ichythink);
				HookSingleEntityOutput(ent,"OnFoundEnemy",OnIchyFoundPlayer);
				HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
			}
			else if (StrEqual(oldcls,"npc_human_grunt",false))
			{
				AcceptEntityInput(ent,"GagEnable");
				SDKHookEx(ent,SDKHook_Think,hgruntthink);
			}
			else if (StrEqual(oldcls,"npc_human_grenadier",false))
			{
				AcceptEntityInput(ent,"GagEnable");
				SDKHookEx(ent,SDKHook_Think,grenthink);
			}
			else if (StrEqual(oldcls,"monster_human_assassin",false))
			{
				SDKHookEx(ent,SDKHook_Think,assassinthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
				if (FindStringInArray(precachedarr,"monster_human_assassin") == -1)
				{
					PrecacheSound("common\\bodydrop1.wav",true);
					PrecacheSound("common\\bodydrop2.wav",true);
					PrecacheSound("common\\bodydrop3.wav",true);
					PrecacheSound("common\\bodydrop4.wav",true);
					PrecacheSound("weapons\\pl_gun1.wav",true);
					PrecacheSound("weapons\\pl_gun2.wav",true);
					PushArrayString(precachedarr,"monster_human_assassin");
				}
			}
			else if (StrEqual(oldcls,"npc_human_scientist",false))
			{
				SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
			}
			else if ((StrEqual(oldcls,"npc_alien_grunt")) || (StrEqual(oldcls,"npc_alien_grunt_unarmored")))
			{
				AcceptEntityInput(ent,"GagEnable");
				SDKHookEx(ent,SDKHook_Think,agruntthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,agrunttkdmg);
				SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
				HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
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
					recursion("sound/weapons/50cal/");
					recursion("sound/weapons/m4/");
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
				int boundbox = CreateEntityByName("prop_dynamic");
				if (boundbox != -1)
				{
					if (strlen(targn) < 1)
					{
						Format(targn,sizeof(targn),"npc_abrams%i",ent);
						SetEntPropString(ent,Prop_Data,"m_iName",targn);
					}
					char boundbtarg[64];
					Format(boundbtarg,sizeof(boundbtarg),"abramsbox%i",boundbox);
					DispatchKeyValue(boundbox,"rendermode","10");
					DispatchKeyValue(boundbox,"solid","6");
					DispatchKeyValue(boundbox,"model","models/props_vehicles/abrams.mdl");
					DispatchKeyValue(boundbox,"targetname",boundbtarg);
					TeleportEntity(boundbox,porigin,angs,NULL_VECTOR);
					DispatchSpawn(boundbox);
					ActivateEntity(boundbox);
					SetVariantString("!activator");
					AcceptEntityInput(boundbox,"SetParent",ent);
					SDKHookEx(boundbox,SDKHook_OnTakeDamage,abramstkdmg);
					SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
					SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",boundbox);
					int logcoll = CreateEntityByName("logic_collision_pair");
					if (logcoll != -1)
					{
						DispatchKeyValue(logcoll,"attach1",targn);
						DispatchKeyValue(logcoll,"attach2",boundbtarg);
						DispatchKeyValue(logcoll,"StartDisabled","1");
						DispatchSpawn(logcoll);
						ActivateEntity(logcoll);
					}
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
				if (HasEntProp(ent,Prop_Data,"m_iHealth"))
				{
					int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
					int maxh = 250;
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
				SetupMine(ent);
			}
			else if (StrEqual(oldcls,"npc_alien_slave",false))
			{
				SDKHookEx(ent,SDKHook_Think,aslavethink);
				SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
				if (!relsetvort)
				{
					setuprelations("npc_alien_slave");
					relsetvort = true;
				}
			}
			else if (StrEqual(oldcls,"npc_alien_controller",false))
			{
				if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",1);
				SDKHookEx(ent,SDKHook_Think,controllerthink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,controllertkdmg);
				PushArrayCell(controllers,ent);
				if (!relsetvort)
				{
					setuprelations("npc_alien_slave");
					relsetvort = true;
				}
			}
			else if (StrEqual(oldcls,"npc_apache",false))
			{
				Format(mdl,sizeof(mdl),"models/props_vehicles/apache.mdl");
				SDKHookEx(ent,SDKHook_Think,apachethink);
				SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
			}
			else if (StrEqual(oldcls,"npc_gonarch",false))
			{
				float vMins[3];
				float vMaxs[3];
				vMins[0] = -30.0;
				vMins[1] = -30.0;
				vMins[2] = 0.0;
				vMaxs[0] = 30.0;
				vMaxs[1] = 30.0;
				vMaxs[2] = 72.0;
				SetEntPropVector(ent,Prop_Data,"m_vecMins",vMins);
				SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vMaxs);
			}
			else if (StrEqual(oldcls,"npc_human_security",false))
			{
				DispatchKeyValue(ent,"CitizenType","4");
				if (StringToInt(spawnflags) & 1<<17)
				{
					SetVariantString("spawnflags 1064960");
					AcceptEntityInput(ent,"AddOutput");
				}
				setmdl = false;
				SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
			}
			else if (StrEqual(oldcls,"monster_scientist",false))
			{
				SDKHookEx(ent,SDKHook_OnTakeDamage,scihl1tkdmg);
				if (GetEntProp(ent,Prop_Data,"m_nBody") == -1) SetEntProp(ent,Prop_Data,"m_nBody",GetRandomInt(1,3));
			}
			else if (StrEqual(oldcls,"monster_zombie",false))
			{
				SDKHookEx(ent,SDKHook_Think,monstzomthink);
			}
			if (StrEqual(clsname,"generic_actor",false)) setmdl = false;
			if (setmdl)
			{
				Handle dpres = CreateDataPack();
				WritePackString(dpres,mdl);
				WritePackCell(dpres,ent);
				WritePackString(dpres,oldcls);
				CreateTimer(0.5,resetmdl,dpres,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				CreateTimer(0.1,resethealth,ent,TIMER_FLAG_NO_MAPCHANGE);
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

void restoreentarr(Handle dp, int spawnonent, bool forcespawn)
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
			if (StrEqual(clsname,"item_weapon_mp5",false)) Format(clsname,sizeof(clsname),"weapon_mp5");
			Format(oldcls,sizeof(oldcls),"%s",clsname);
			if (StrEqual(clsname,"npc_human_scientist_kleiner",false))
				Format(clsname,sizeof(clsname),"npc_kleiner");
			else if (StrEqual(clsname,"npc_human_scientist_eli",false))
				Format(clsname,sizeof(clsname),"npc_eli");
			else if ((StrEqual(clsname,"npc_human_grunt",false)) || (StrEqual(clsname,"npc_human_commander",false)) || (StrEqual(clsname,"npc_human_medic",false)) || (StrEqual(clsname,"npc_human_grenadier",false)) || (StrEqual(clsname,"npc_assassin",false)) || (StrEqual(clsname,"npc_human_assassin",false)) || (StrEqual(clsname,"monster_human_assassin",false)))
				Format(clsname,sizeof(clsname),"npc_combine_s");
			else if (StrEqual(clsname,"monster_headcrab",false))
				Format(clsname,sizeof(clsname),"npc_headcrab");
			else if ((StrEqual(clsname,"npc_human_security",false)) || (StrEqual(clsname,"npc_human_scientist",false)) || (StrEqual(clsname,"npc_human_scientist_female",false)))
				Format(clsname,sizeof(clsname),"npc_citizen");
			else if (StrEqual(clsname,"npc_odell",false))
				Format(clsname,sizeof(clsname),"npc_citizen");
			else if ((StrContains(clsname,"npc_human_",false) != -1) || (StrEqual(clsname,"npc_abrams",false)) || (StrEqual(clsname,"npc_tentacle",false)) || (StrEqual(clsname,"monster_bullchicken",false)) || (StrEqual(clsname,"monster_cockroach",false)) || (StrEqual(clsname,"monster_human_grunt",false)) || (StrEqual(clsname,"monster_hgrunt_dead",false)) || (StrEqual(clsname,"monster_sentry",false)) || (StrEqual(clsname,"monster_scientist",false)) || (StrEqual(clsname,"monster_osprey",false)) || (StrEqual(clsname,"monster_gman",false)) || (StrEqual(clsname,"monster_scientist_dead",false)) || (StrEqual(clsname,"monster_barney",false)) || (StrEqual(clsname,"monster_barney_dead",false)))
				Format(clsname,sizeof(clsname),"generic_actor");
			else if (StrEqual(clsname,"monster_barnacle",false))
				Format(clsname,sizeof(clsname),"npc_barnacle");
			else if ((StrEqual(clsname,"monster_zombie",false)) || (StrEqual(clsname,"npc_zombie_scientist",false)))
				Format(clsname,sizeof(clsname),"npc_zombie");
			else if (StrEqual(clsname,"npc_zombie_scientist_torso",false))
				Format(clsname,sizeof(clsname),"npc_zombie_torso");
			else if ((StrEqual(clsname,"monster_alien_slave",false)) || (StrEqual(clsname,"npc_alien_slave",false)) || (StrEqual(clsname,"npc_alien_controller",false)))
				Format(clsname,sizeof(clsname),"npc_vortigaunt");
			else if ((StrEqual(clsname,"npc_zombie_security",false)) || (StrEqual(clsname,"npc_zombie_security_torso",false)) || (StrEqual(clsname,"npc_gonarch",false)) || (StrEqual(clsname,"npc_zombie_worker",false)))
				Format(clsname,sizeof(clsname),"npc_zombine");
			else if ((StrEqual(clsname,"npc_osprey",false)) || (StrEqual(clsname,"npc_bmsgargantua",false)))
				Format(clsname,sizeof(clsname),"generic_actor");
			else if ((StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"monster_houndeye",false)) || (StrEqual(clsname,"npc_bullsquid",false)))
				Format(clsname,sizeof(clsname),"npc_antlion");
			else if (StrEqual(clsname,"npc_snark",false))
				Format(clsname,sizeof(clsname),"npc_headcrab_fast");
			else if ((StrEqual(clsname,"npc_alien_grunt",false)) || (StrEqual(clsname,"npc_alien_grunt_unarmored",false)) || (StrEqual(clsname,"monster_alien_grunt",false)))
				Format(clsname,sizeof(clsname),"npc_combine_s");
			else if (StrEqual(clsname,"monster_gargantua",false))
				Format(clsname,sizeof(clsname),"npc_gargantua");
			else if (StrEqual(clsname,"grenade_tripmine",false))
				Format(clsname,sizeof(clsname),"prop_physics");
			else if (StrEqual(clsname,"npc_apache",false))
				Format(clsname,sizeof(clsname),"npc_helicopter");
			else if (StrEqual(clsname,"npc_babycrab",false))
				Format(clsname,sizeof(clsname),"npc_headcrab");
			else if (StrEqual(clsname,"item_longjump",false))
				Format(clsname,sizeof(clsname),"item_healthkit");
			else if (StrEqual(clsname,"weapon_immolator",false))
				Format(clsname,sizeof(clsname),"weapon_physcannon");
			else if ((StrEqual(clsname,"item_weapon_glock",false)) || (StrEqual(clsname,"weapon_glock",false)) || (StrEqual(clsname,"weapon_pistol_worker",false)) || (StrEqual(clsname,"weapon_flaregun",false)))
				Format(clsname,sizeof(clsname),"weapon_pistol");
			else if ((StrEqual(clsname,"weapon_medkit",false)) || (StrEqual(clsname,"weapon_camera",false)) || (StrEqual(clsname,"weapon_molotov",false)))
				Format(clsname,sizeof(clsname),"weapon_slam");
			else if ((StrEqual(clsname,"weapon_mp5",false)) || (StrEqual(clsname,"weapon_sl8",false)) || (StrEqual(clsname,"weapon_uzi",false)) || (StrEqual(clsname,"weapon_oicw",false)) || (StrEqual(clsname,"weapon_camera",false)))
				Format(clsname,sizeof(clsname),"weapon_smg1");
			else if ((StrEqual(clsname,"weapon_gauss",false)) || (StrEqual(clsname,"weapon_tau",false)) || (StrEqual(clsname,"weapon_sniperrifle",false)))
				Format(clsname,sizeof(clsname),"weapon_ar2");
			else if ((StrEqual(clsname,"weapon_manhack",false)) || (StrEqual(clsname,"weapon_manhacktoss",false)))
				Format(clsname,sizeof(clsname),"weapon_pistol");
			else if ((StrEqual(clsname,"item_ammo_energy",false)) || (StrEqual(clsname,"item_ammo_glock",false)) || (StrEqual(clsname,"item_ammo_flare_box",false)) || (StrEqual(clsname,"item_box_flare_rounds",false)))
				Format(clsname,sizeof(clsname),"item_ammo_pistol");
			else if (StrEqual(clsname,"item_ammo_mp5",false))
				Format(clsname,sizeof(clsname),"item_ammo_smg1");
			else if (StrEqual(clsname,"env_mortar_launcher"))
				Format(clsname,sizeof(clsname),"info_target");
			else if (StrEqual(clsname,"env_mortar_controller"))
				Format(clsname,sizeof(clsname),"prop_physics_override");
			else if (StrEqual(clsname,"monster_ichthyosaur"))
				Format(clsname,sizeof(clsname),"npc_ichthyosaur");
			else if (StrEqual(clsname,"trigger_once_oc"))
				Format(clsname,sizeof(clsname),"trigger_once");
			else if (StrEqual(clsname,"trigger_multiple_oc"))
				Format(clsname,sizeof(clsname),"trigger_multiple");
			else if (StrEqual(clsname,"logic_merchant_relay"))
				Format(clsname,sizeof(clsname),"logic_relay");
			else if (StrEqual(clsname,"logic_player_branch"))
				Format(clsname,sizeof(clsname),"math_counter");
			else if (StrEqual(clsname,"game_countdown_timer"))
				Format(clsname,sizeof(clsname),"hud_timer");
			else if ((StrEqual(clsname,"hlss_camera_output",false)) || (StrEqual(clsname,"hlss_weaponstripper",false)))
				Format(clsname,sizeof(clsname),"logic_relay");
			else if (StrEqual(clsname,"npc_merchant",false))
				Format(clsname,sizeof(clsname),"generic_actor");
			else if (StrContains(clsname,"customweapons/",false) == 0)
			{
				findcls = FindStringInArray(dp,"ResponseContext");
				if (findcls != -1)
				{
					findcls++;
					GetArrayString(dp,findcls,clsname,sizeof(clsname));
				}
			}
			if (strlen(clsname) < 1) Format(clsname,sizeof(clsname),"%s",oldcls);
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
				int spawnflags = 0;
				bool setmdl = true;
				for (int i = 0;i<GetArraySize(dp);i++)
				{
					char kv[64];
					char kvv[128];
					GetArrayString(dp,i,kv,sizeof(kv));
					i++;
					GetArrayString(dp,i,kvv,sizeof(kvv));
					if (StrEqual(kv,"model",false)) Format(mdl,sizeof(mdl),"%s",kvv);
					else if (StrEqual(kv,"spawnflags",false)) spawnflags = StringToInt(kvv);
					else if (StrEqual(kv,"target",false)) Format(targetpath,sizeof(targetpath),"%s",kvv);
					else if (StrEqual(kv,"targetname",false)) Format(targn,sizeof(targn),"%s",kvv);
					DispatchKeyValue(ent,kv,kvv);
				}
				if (IsValidEntity(spawnonent))
				{
					if (HasEntProp(spawnonent,Prop_Data,"m_iName"))
					{
						char targchk[64];
						GetEntPropString(spawnonent,Prop_Data,"m_iName",targchk,sizeof(targchk));
						if (StrEqual(targchk,"rappelfrom",false)) DispatchKeyValue(ent,"waitingtorappel","1");
					}
				}
				if (StrEqual(oldcls,"logic_merchant_relay",false))
				{
					for (int i = 0;i<GetArraySize(dp);i++)
					{
						char arrstart[64];
						char arrnext[128];
						GetArrayString(dp,i,arrstart,sizeof(arrstart));
						i++;
						GetArrayString(dp,i,arrnext,sizeof(arrnext));
						if (StrEqual(arrstart,"IsShared",false)) SetEntProp(ent,Prop_Data,"m_bInvulnerable",StringToInt(arrnext));
						else if (StrEqual(arrstart,"AnnounceCashNeeded",false)) SetEntPropFloat(ent,Prop_Data,"m_flSpeed",StringToFloat(arrnext));
						else if (StrEqual(arrstart,"purchasesound",false)) SetEntPropString(ent,Prop_Data,"m_iszResponseContext",arrnext);
						else if (StrEqual(arrstart,"CostOf",false)) SetEntProp(ent,Prop_Data,"m_iHealth",StringToInt(arrnext));
						else if (StrEqual(arrstart,"MaxPointsTake",false)) SetEntProp(ent,Prop_Data,"m_iMaxHealth",StringToInt(arrnext));
						else if (StrEqual(arrstart,"PurchaseName",false)) SetEntPropString(ent,Prop_Data,"m_target",arrnext);
						else if (StrEqual(arrstart,"OnPurchased",false)) DispatchKeyValue(ent,"OnUser1",arrnext);
						else if (StrEqual(arrstart,"OnNotEnoughCash",false)) DispatchKeyValue(ent,"OnUser2",arrnext);
						else if (StrEqual(arrstart,"OnCashReduced",false)) DispatchKeyValue(ent,"OnUser3",arrnext);
						else if (StrEqual(arrstart,"OnDisabled",false)) DispatchKeyValue(ent,"OnUser4",arrnext);
						HookSingleEntityOutput(ent,"OnUser1",LogMerchPurchased);
						HookSingleEntityOutput(ent,"OnUser2",LogMerchNotEnough);
						HookSingleEntityOutput(ent,"OnUser3",LogMerchCashReduced);
						HookSingleEntityOutput(ent,"OnUser4",LogMerchDisabled);
					}
				}
				else if (StrEqual(oldcls,"logic_player_branch",false))
				{
					for (int i = 0;i<GetArraySize(dp);i++)
					{
						char arrstart[64];
						char arrnext[128];
						GetArrayString(dp,i,arrstart,sizeof(arrstart));
						i++;
						GetArrayString(dp,i,arrnext,sizeof(arrnext));
						if (StrEqual(arrstart,"InitialValue",false))
						{
							DispatchKeyValue(ent,"max",arrnext);
						}
						else if (StrEqual(arrstart,"OnTrue",false))
						{
							DispatchKeyValue(ent,"OnHitMax",arrnext);
						}
					}
				}
				else if (StrEqual(oldcls,"npc_merchant",false))
				{
					char merchicon[64];
					if (FileExists("materials/sprites/merchant_buy.vmt",true,NULL_STRING)) Format(merchicon,sizeof(merchicon),"sprites/merchant_buy.vmt");
					else Format(merchicon,sizeof(merchicon),"sprites/merchant_buysyn.vmt");
					int starticonon = 1;
					float posabove = 80.0;
					for (int i = 0;i<GetArraySize(dp);i++)
					{
						char arrstart[64];
						char arrnext[128];
						GetArrayString(dp,i,arrstart,sizeof(arrstart));
						i++;
						GetArrayString(dp,i,arrnext,sizeof(arrnext));
						if (StrEqual(arrstart,"MerchantScript",false)) DispatchKeyValue(ent,"ResponseContext",arrnext);
						else if (StrEqual(arrstart,"MerchantIconMaterial",false)) Format(merchicon,sizeof(merchicon),"%s",arrnext);
						else if (StrEqual(arrstart,"ShowIcon",false)) starticonon = StringToInt(arrnext);
						else if (StrEqual(arrstart,"IconHeight",false)) posabove = StringToFloat(arrnext);
						else if (StrEqual(arrstart,"OnPlayerUse",false)) DispatchKeyValue(ent,"OnUser1",arrnext);
						else if (StrEqual(arrstart,"MerchantSound",false))
						{
							if (HasEntProp(ent,Prop_Data,"m_initialDelay")) SetEntPropFloat(ent,Prop_Data,"m_initialDelay",StringToFloat(arrnext));
						}
					}
					DispatchKeyValue(ent,"citizentype","4");
					SetEntProp(ent,Prop_Data,"m_bInvulnerable",1);
					if (HasEntProp(ent,Prop_Data,"m_takedamage")) SetEntProp(ent,Prop_Data,"m_takedamage",0);
					int sprite = CreateEntityByName("env_sprite");
					if (sprite != -1)
					{
						DispatchKeyValue(sprite,"model",merchicon);
						DispatchKeyValue(sprite,"framerate","1");
						DispatchKeyValue(sprite,"RenderMode","5");
						DispatchKeyValue(sprite,"scale","0.5");
						if (starticonon) DispatchKeyValue(sprite,"spawnflags","1");
						else DispatchKeyValue(sprite,"spawnflags","0");
						float startpos[3];
						startpos[0] = porigin[0];
						startpos[1] = porigin[1];
						startpos[2] = porigin[2]+posabove;
						TeleportEntity(sprite,startpos,NULL_VECTOR,NULL_VECTOR);
						DispatchSpawn(sprite);
						ActivateEntity(sprite);
						SetVariantString("!activator");
						AcceptEntityInput(sprite,"SetParent",ent);
					}
					HookSingleEntityOutput(ent,"OnUser1",MerchantUse);
					int flageffects = GetEntProp(ent,Prop_Data,"m_iEFlags");
					if (!(flageffects & 1<<30))
					{
						SetEntProp(ent,Prop_Data,"m_iEFlags",flageffects+1073741824);
					}
				}
				else if ((StrEqual(oldcls,"npc_human_security",false)) || (StrEqual(oldcls,"npc_human_scientist",false)) || (StrEqual(oldcls,"npc_human_scientist_female",false)))
				{
					DispatchKeyValue(ent,"citizentype","4");
				}
				else if (StrEqual(oldcls,"item_longjump",false))
				{
					for (int k = 0;k<GetArraySize(dp);k++)
					{
						char ktmp[128];
						char ktmp2[128];
						GetArrayString(dp, k, ktmp, sizeof(ktmp));
						k++;
						GetArrayString(dp, k, ktmp2, sizeof(ktmp2));
						if (StrEqual(ktmp,"OnPlayerPickup",false))
						{
							Format(ktmp,sizeof(ktmp),"OnCacheInteraction");
							DispatchKeyValue(ent,ktmp,ktmp2);
						}
					}
				}
				DispatchSpawn(ent);
				ActivateEntity(ent);
				if (StrEqual(oldcls,"npc_houndeye",false))
				{
					setuphound(ent);
				}
				else if (StrEqual(oldcls,"npc_bullsquid",false))
				{
					setupsquid(ent);
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
					SetEntPropEnt(entmdl,Prop_Data,"m_hOwnerEntity",ent);
					int entsnd = CreateEntityByName("ambient_generic");
					DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
					DispatchSpawn(entsnd);
					ActivateEntity(entsnd);
					SetVariantString("!activator");
					AcceptEntityInput(entsnd,"SetParent",entmdl);
					SetVariantString("Eye");
					AcceptEntityInput(entsnd,"SetParentAttachment");
					PushArrayCell(tentssnd,entsnd);
					SetEntPropEnt(entmdl,Prop_Data,"m_hEffectEntity",entsnd);
					SDKHookEx(ent,SDKHook_Think,tentaclethink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,tentacletkdmg);
					HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
				}
				else if (StrContains(oldcls,"npc_zombie_s",false) == 0)
				{
					SDKHookEx(ent,SDKHook_Think,zomthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,zomtkdmg);
				}
				else if ((StrEqual(oldcls,"npc_ichthyosaur",false)) || (StrEqual(oldcls,"monster_ichthyosaur",false)))
				{
					SetEntProp(ent,Prop_Data,"m_MoveType",7);
					if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",2);
					SDKHookEx(ent,SDKHook_Think,ichythink);
					HookSingleEntityOutput(ent,"OnFoundEnemy",OnIchyFoundPlayer);
					HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
				}
				else if ((StrEqual(oldcls,"npc_human_grunt",false)) || (StrEqual(oldcls,"npc_human_commander",false)) || (StrEqual(oldcls,"npc_human_medic",false)))
				{
					AcceptEntityInput(ent,"GagEnable");
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
					SDKHookEx(ent,SDKHook_Think,hgruntthink);
					setmdl = false;
				}
				else if (StrEqual(oldcls,"npc_human_grenadier",false))
				{
					AcceptEntityInput(ent,"GagEnable");
					SDKHookEx(ent,SDKHook_Think,grenthink);
					setmdl = false;
				}
				else if (StrEqual(oldcls,"npc_human_assassin",false))
				{
					AcceptEntityInput(ent,"GagEnable");
					SDKHookEx(ent,SDKHook_Think,assassinthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
					setmdl = false;
				}
				else if (StrEqual(oldcls,"monster_human_assassin",false))
				{
					AcceptEntityInput(ent,"GagEnable");
					SDKHookEx(ent,SDKHook_Think,assassinthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,assassintkdmg);
					setmdl = false;
				}
				else if (StrEqual(oldcls,"npc_human_scientist",false))
				{
					SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
				}
				else if ((StrEqual(oldcls,"npc_alien_grunt")) || (StrEqual(oldcls,"monster_alien_grunt")) || (StrEqual(oldcls,"npc_alien_grunt_unarmored")))
				{
					AcceptEntityInput(ent,"GagEnable");
					SDKHookEx(ent,SDKHook_Think,agruntthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,agrunttkdmg);
					SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
					HookSingleEntityOutput(ent,"OnDeath",OnCDeath);
				}
				else if (StrEqual(oldcls,"monster_gargantua",false)) setmdl = false;
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
						recursion("sound/weapons/50cal/");
						recursion("sound/weapons/m4/");
						PushArrayString(precachedarr,"npc_abrams");
					}
					int driver = CreateEntityByName("func_tracktrain");
					if (driver != -1)
					{
						DispatchKeyValue(driver,"target",targetpath);
						DispatchKeyValue(driver,"orientationtype","1");
						DispatchKeyValue(driver,"speed","80");
						DispatchKeyValue(driver,"solid","0");
						DispatchKeyValue(driver,"rendermode","10");
						DispatchSpawn(driver);
						ActivateEntity(driver);
						TeleportEntity(driver,porigin,angs,NULL_VECTOR);
						AcceptEntityInput(driver,"StartForward");
						SetVariantString("!activator");
						AcceptEntityInput(ent,"SetParent",driver);
					}
					int boundbox = CreateEntityByName("prop_dynamic");
					if (boundbox != -1)
					{
						if (strlen(targn) < 1)
						{
							Format(targn,sizeof(targn),"npc_abrams%i",ent);
							SetEntPropString(ent,Prop_Data,"m_iName",targn);
						}
						char boundbtarg[64];
						Format(boundbtarg,sizeof(boundbtarg),"abramsbox%i",boundbox);
						DispatchKeyValue(boundbox,"rendermode","10");
						DispatchKeyValue(boundbox,"solid","6");
						DispatchKeyValue(boundbox,"model","models/props_vehicles/abrams.mdl");
						TeleportEntity(boundbox,porigin,angs,NULL_VECTOR);
						DispatchSpawn(boundbox);
						ActivateEntity(boundbox);
						SetVariantString("!activator");
						AcceptEntityInput(boundbox,"SetParent",ent);
						SDKHookEx(boundbox,SDKHook_OnTakeDamage,abramstkdmg);
						SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
						SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",boundbox);
						int logcoll = CreateEntityByName("logic_collision_pair");
						if (logcoll != -1)
						{
							DispatchKeyValue(logcoll,"attach1",targn);
							DispatchKeyValue(logcoll,"attach2",boundbtarg);
							DispatchKeyValue(logcoll,"StartDisabled","1");
							DispatchSpawn(logcoll);
							ActivateEntity(logcoll);
						}
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
					if (HasEntProp(ent,Prop_Data,"m_iHealth"))
					{
						int hchk = GetEntProp(ent,Prop_Data,"m_iHealth");
						int maxh = 250;
						if (hchk != maxh)
						{
							SetEntProp(ent,Prop_Data,"m_iMaxHealth",maxh);
							SetEntProp(ent,Prop_Data,"m_iHealth",maxh);
						}
					}
					if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",3);
					SDKHookEx(ent,SDKHook_Think,abramsthink);
					setmdl = false;
				}
				else if (StrEqual(oldcls,"grenade_tripmine",false))
				{
					SetupMine(ent);
				}
				else if (StrEqual(oldcls,"npc_alien_slave",false))
				{
					SDKHookEx(ent,SDKHook_Think,aslavethink);
					SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
					setuprelations("npc_alien_slave");
				}
				else if (StrEqual(oldcls,"npc_alien_controller",false))
				{
					if (HasEntProp(ent,Prop_Data,"m_bloodColor")) SetEntProp(ent,Prop_Data,"m_bloodColor",1);
					SDKHookEx(ent,SDKHook_Think,controllerthink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,controllertkdmg);
					PushArrayCell(controllers,ent);
					setuprelations("npc_alien_slave");
				}
				else if (StrEqual(oldcls,"npc_apache",false))
				{
					Format(mdl,sizeof(mdl),"models/props_vehicles/apache.mdl");
					SDKHookEx(ent,SDKHook_Think,apachethink);
					SDKHookEx(ent,SDKHook_OnTakeDamage,apachetkdmg);
				}
				else if (StrEqual(oldcls,"npc_osprey",false))
				{
					SDKHookEx(ent,SDKHook_Think,ospreythink);
					//SetEntProp(ent,Prop_Data,"m_nRenderMode",10);
					//SetEntProp(ent,Prop_Data,"m_nRenderFX",6);
					int animprop = CreateEntityByName("prop_dynamic");
					if (animprop != -1)
					{
						DispatchKeyValue(animprop,"model","models/props_vehicles/osprey.mdl");
						DispatchKeyValue(animprop,"solid","4");
						DispatchKeyValue(animprop,"rendermode","10");
						DispatchKeyValue(animprop,"renderfx","6");
						DispatchKeyValue(animprop,"DefaultAnim","idle_flying");
						TeleportEntity(animprop,porigin,angs,NULL_VECTOR);
						DispatchSpawn(animprop);
						ActivateEntity(animprop);
						SetVariantString("!activator");
						AcceptEntityInput(animprop,"SetParent",ent);
						SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",animprop);
						SDKHookEx(animprop,SDKHook_OnTakeDamage,abramstkdmg);
						SDKHookEx(ent,SDKHook_OnTakeDamage,abramstkdmg);
					}
					int driver = CreateEntityByName("func_tracktrain");
					if (driver != -1)
					{
						DispatchKeyValue(driver,"target",targetpath);
						DispatchKeyValue(driver,"orientationtype","2");
						DispatchKeyValue(driver,"speed","300");
						DispatchKeyValue(driver,"solid","0");
						DispatchKeyValue(driver,"rendermode","10");
						DispatchSpawn(driver);
						ActivateEntity(driver);
						TeleportEntity(driver,porigin,angs,NULL_VECTOR);
						AcceptEntityInput(driver,"StartForward");
						SetVariantString("!activator");
						AcceptEntityInput(ent,"SetParent",driver);
					}
					Handle templatearr = CreateArray(9);
					for (int i = 0;i<GetArraySize(dp);i++)
					{
						char keychk[64];
						GetArrayString(dp,i,keychk,sizeof(keychk));
						i++;
						if (StrContains(keychk,"NPCTemplate",false) == 0)
						{
							char vchk[64];
							GetArrayString(dp,i,vchk,sizeof(vchk));
							PushArrayString(templatearr,vchk);
						}
					}
					if (GetArraySize(templatearr) > 0)
					{
						int templatestore = CreateEntityByName("point_template");
						if (templatestore != -1)
						{
							for (int i = 0;i<GetArraySize(templatearr);i++)
							{
								char tmp[64];
								char tmp2[64];
								Format(tmp,sizeof(tmp),"Template0%i",i);
								GetArrayString(templatearr,i,tmp2,sizeof(tmp2));
								DispatchKeyValue(templatestore,tmp,tmp2);
							}
							DispatchSpawn(templatestore);
							ActivateEntity(templatestore);
							SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",templatestore);
						}
					}
					CloseHandle(templatearr);
				}
				else if (StrEqual(oldcls,"item_longjump",false))
				{
					SDKHook(ent,SDKHook_StartTouch,StartTouchLongJump);
				}
				else if (StrEqual(oldcls,"env_mortar_controller",false))
				{
					int findlauncher = FindStringInArray(dp,"MortarLauncher");
					if (findlauncher != -1)
					{
						findlauncher++;
						char launchtarg[64];
						GetArrayString(dp,findlauncher,launchtarg,sizeof(launchtarg));
						SetEntPropString(ent,Prop_Data,"m_iszResponseContext",launchtarg);
						int controlpv = CreateEntityByName("point_viewcontrol");
						if (controlpv != -1)
						{
							float fileoriginz[3];
							float angsset[3];
							char mortarpv[64];
							angsset[0] = 90.0;
							angsset[1] = 90.0;
							fileoriginz[0] = porigin[0];
							fileoriginz[1] = porigin[1];
							fileoriginz[2] = porigin[2]+1500.0;
							Format(mortarpv,sizeof(mortarpv),"%spv",launchtarg);
							DispatchKeyValue(controlpv,"targetname",mortarpv);
							DispatchKeyValue(controlpv,"spawnflags","8");
							TeleportEntity(controlpv,fileoriginz,angsset,NULL_VECTOR);
							DispatchSpawn(controlpv);
							ActivateEntity(controlpv);
							SetEntPropEnt(controlpv,Prop_Data,"m_hEffectEntity",ent);
						}
						int setupcontrol = CreateEntityByName("game_ui");
						if (setupcontrol != -1)
						{
							char launchtargpv[128];
							Format(launchtargpv,sizeof(launchtargpv),"%sui",launchtarg);
							DispatchKeyValue(setupcontrol,"targetname",launchtargpv);
							DispatchKeyValue(setupcontrol,"spawnflags","480");
							DispatchKeyValue(setupcontrol,"FieldOfView","-1");
							Format(launchtargpv,sizeof(launchtargpv),"%spv,Enable,,0,-1",launchtarg);
							DispatchKeyValue(setupcontrol,"PlayerOn",launchtargpv);
							Format(launchtargpv,sizeof(launchtargpv),"%spv,Disable,,0,-1",launchtarg);
							DispatchKeyValue(setupcontrol,"PlayerOff",launchtargpv);
							DispatchSpawn(setupcontrol);
							ActivateEntity(setupcontrol);
							HookSingleEntityOutput(setupcontrol,"PressedMoveLeft",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"PressedMoveRight",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"PressedForward",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"PressedBack",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"PressedAttack",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"UnpressedMoveLeft",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"UnpressedMoveRight",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"UnpressedForward",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"UnpressedBack",env_mortarcontroller);
							HookSingleEntityOutput(setupcontrol,"PlayerOff",env_mortarcontroller);
							SetEntPropEnt(setupcontrol,Prop_Data,"m_hEffectEntity",controlpv);
							SDKHookEx(setupcontrol,SDKHook_Think,camthink);
						}
						//HookSingleEntityOutput(ent,"OnPlayerPickup",env_mortarcontroller);
						SetEntPropEnt(ent,Prop_Data,"m_hEffectEntity",setupcontrol);
						SDKHookEx(ent,SDKHook_Use,env_mortarcontrolleractivate);
					}
				}
				else if (StrEqual(oldcls,"npc_gonarch",false))
				{
					float vMins[3];
					float vMaxs[3];
					vMins[0] = -30.0;
					vMins[1] = -30.0;
					vMins[2] = 0.0;
					vMaxs[0] = 30.0;
					vMaxs[1] = 30.0;
					vMaxs[2] = 72.0;
					SetEntPropVector(ent,Prop_Data,"m_vecMins",vMins);
					SetEntPropVector(ent,Prop_Data,"m_vecMaxs",vMaxs);
				}
				else if ((StrEqual(oldcls,"npc_human_security",false)) || (StrEqual(oldcls,"npc_human_scientist",false)) || (StrEqual(oldcls,"npc_human_scientist_female",false)))
				{
					DispatchKeyValue(ent,"CitizenType","4");
					if (spawnflags & 1<<17)
					{
						SetVariantString("spawnflags 1064960");
						AcceptEntityInput(ent,"AddOutput");
					}
					setmdl = false;
					SDKHookEx(ent,SDKHook_OnTakeDamage,enttkdmgcust);
				}
				else if (StrEqual(oldcls,"monster_scientist",false))
				{
					SDKHookEx(ent,SDKHook_OnTakeDamage,scihl1tkdmg);
					if (GetEntProp(ent,Prop_Data,"m_nBody") == -1) SetEntProp(ent,Prop_Data,"m_nBody",GetRandomInt(1,3));
				}
				else if (StrEqual(oldcls,"monster_zombie",false))
				{
					SDKHookEx(ent,SDKHook_Think,monstzomthink);
				}
				if (StrEqual(clsname,"generic_actor",false)) setmdl = false;
				if (setmdl)
				{
					Handle dpres = CreateDataPack();
					WritePackString(dpres,mdl);
					WritePackCell(dpres,ent);
					WritePackString(dpres,oldcls);
					CreateTimer(0.5,resetmdl,dpres,TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					CreateTimer(0.1,resethealth,ent,TIMER_FLAG_NO_MAPCHANGE);
				}
				if (GetArraySize(customrelations) > 0)
				{
					for (int i = 0;i<GetArraySize(customrelations);i++)
					{
						int j = GetArrayCell(customrelations,i);
						if (IsValidEntity(j)) AcceptEntityInput(j,"ApplyRelationship");
					}
				}
				if (IsValidEntity(spawnonent))
				{
					bool waitforclear = false;
					float spawnat[3];
					float spawnang[3];
					float distchk = 70.0;
					if (StrEqual(oldcls,"npc_apache",false)) distchk = 200.0;
					if (HasEntProp(spawnonent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spawnonent,Prop_Data,"m_vecAbsOrigin",spawnat);
					else if (HasEntProp(spawnonent,Prop_Send,"m_vecOrigin")) GetEntPropVector(spawnonent,Prop_Send,"m_vecOrigin",spawnat);
					if (HasEntProp(spawnonent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(spawnonent,Prop_Data,"m_angAbsRotation",spawnang);
					if (!forcespawn)
					{
						if (GetArraySize(entlist) > 0)
						{
							float entpos[3];
							for (int j = 0;j<GetArraySize(entlist);j++)
							{
								int i = GetArrayCell(entlist,j);
								if ((IsValidEntity(i)) && (i != 0) && (i != ent) && (i != spawnonent))
								{
									char clschk[64];
									GetEntityClassname(i,clschk,sizeof(clschk));
									if ((StrContains(clschk,"scripted",false) == -1) && (StrContains(clschk,"logic",false) == -1) && (StrContains(clschk,"maker",false) == -1) && (StrContains(clschk,"env",false) == -1) && (StrContains(clschk,"point",false) == -1))
									{
										if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",entpos);
										else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",entpos);
										float chkdist = GetVectorDistance(spawnat,entpos,false);
										if (chkdist < distchk)
										{
											waitforclear = true;
											//PrintToServer("%i too close to %i %1.f",ent,i,chkdist);
										}
									}
								}
							}
						}
					}
					if (waitforclear)
					{
						AcceptEntityInput(ent,"kill");
						Handle clonedp = CloneArray(dp);
						Handle dppass = CreateDataPack();
						WritePackCell(dppass,clonedp);
						WritePackCell(dppass,spawnonent);
						CreateTimer(0.5,waitclearspawner,dppass,TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						char targchk[64];
						GetEntPropString(spawnonent,Prop_Data,"m_iName",targchk,sizeof(targchk));
						TeleportEntity(ent,spawnat,spawnang,NULL_VECTOR);
						if (StrEqual(targchk,"rappelfrom",false))
						{
							//Sometimes this fires too early
							AcceptEntityInput(ent,"BeginRappel");
							CreateTimer(0.5,RefireRappel,ent,TIMER_FLAG_NO_MAPCHANGE);
							/*
							int keyframe = CreateEntityByName("keyframe_rope");
							if (keyframe != -1)
							{
								char tmptarg[64];
								Format(tmptarg,sizeof(tmptarg),"%skey%i",targn,keyframe);
								TeleportEntity(keyframe,spawnat,spawnang,NULL_VECTOR);
								DispatchKeyValue(keyframe,"targetname",tmptarg);
								DispatchSpawn(keyframe);
								ActivateEntity(keyframe);
								PrintToServer("Spawn keyframe_rope %i %s",keyframe,tmptarg);
								int rope = CreateEntityByName("move_rope");
								if (rope != -1)
								{
									spawnat[2]+=60.0;
									TeleportEntity(rope,spawnat,spawnang,NULL_VECTOR);
									DispatchKeyValue(rope,"NextKey",tmptarg);
									DispatchSpawn(rope);
									ActivateEntity(rope);
									SetVariantString("!activator");
									AcceptEntityInput(rope,"SetParent",ent);
									PrintToServer("Spawn move_rope %i",rope);
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,rope);
									WritePackString(dp2,"move_rope");
									CreateTimer(5.0,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
									Handle dp3 = CreateDataPack();
									WritePackCell(dp3,keyframe);
									WritePackString(dp3,"keyframe_rope");
									CreateTimer(5.0,cleanup,dp3,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
							*/
						}
					}
				}
			}
			//Do not close handle, as it may be used again for template makers
			//CloseHandle(dp);
		}
	}
}

public Action RefireRappel(Handle timer, int ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent,"BeginRappel");
	}
}

public Action waitclearspawner(Handle timer, Handle dppass)
{
	if (dppass != INVALID_HANDLE)
	{
		ResetPack(dppass);
		Handle dp = ReadPackCell(dppass);
		int spawnonent = ReadPackCell(dppass);
		if (IsValidEntity(spawnonent))
		{
			bool waitforclear = false;
			float spawnat[3];
			float spawnang[3];
			float distchk = 80.0;
			char cls[64];
			int findcls = FindStringInArray(dp,"classname");
			if (findcls != -1)
			{
				findcls++;
				GetArrayString(dp,findcls,cls,sizeof(cls));
			}
			if (StrEqual(cls,"npc_apache",false)) distchk = 150.0;
			if (HasEntProp(spawnonent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spawnonent,Prop_Data,"m_vecAbsOrigin",spawnat);
			else if (HasEntProp(spawnonent,Prop_Send,"m_vecOrigin")) GetEntPropVector(spawnonent,Prop_Send,"m_vecOrigin",spawnat);
			if (HasEntProp(spawnonent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(spawnonent,Prop_Data,"m_angAbsRotation",spawnang);
			if (GetArraySize(entlist) > 0)
			{
				float entpos[3];
				for (int j = 0;j<GetArraySize(entlist);j++)
				{
					int i = GetArrayCell(entlist,j);
					if ((IsValidEntity(i)) && (i != 0) && (i != spawnonent))
					{
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",entpos);
						else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",entpos);
						float chkdist = GetVectorDistance(spawnat,entpos,false);
						if (chkdist < distchk)
						{
							waitforclear = true;
						}
					}
				}
			}
			if (waitforclear)
			{
				CreateTimer(0.5,waitclearspawner,dppass,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				restoreentarr(dp,spawnonent,true);
				char clschk[32];
				GetEntityClassname(spawnonent,clschk,sizeof(clschk));
				if (StrContains(clschk,"env_xen_portal",false) == 0)
				{
					if (bPortalParticleAvailable)
					{
						int effect = CreateEntityByName("info_particle_system");
						if (effect != -1)
						{
							DispatchKeyValue(effect,"effect_name","teleport_lambda_exit");
							DispatchKeyValue(effect,"start_active","1");
							spawnat[2]+=25.0;
							TeleportEntity(effect,spawnat,spawnang,NULL_VECTOR);
							DispatchSpawn(effect);
							ActivateEntity(effect);
							AcceptEntityInput(effect,"Start");
							Handle dp2 = CreateDataPack();
							WritePackCell(dp2,effect);
							WritePackString(dp2,"info_particle_system");
							CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					else
					{
						int dispent = CreateEntityByName("env_sprite");
						if (dispent != -1)
						{
							DispatchKeyValue(dispent,"model","materials/effects/tele_exit.vmt");
							DispatchKeyValue(dispent,"scale","0.4");
							DispatchKeyValue(dispent,"rendermode","2");
							spawnat[2]+=25.0;
							TeleportEntity(dispent,spawnat,spawnang,NULL_VECTOR);
							DispatchSpawn(dispent);
							ActivateEntity(dispent);
							CreateTimer(0.1,reducescale,dispent,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					int rand = GetRandomInt(1,3);
					char snd[64];
					Format(snd,sizeof(snd),"BMS_objects\\portal\\portal_In_0%i.wav",rand);
					EmitSoundToAll(snd, spawnonent, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				}
				CloseHandle(dppass);
			}
		}
	}
}

void findstraymdl(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		if (StrEqual(clsname,"trigger_once",false))
		{
			if (HasEntProp(thisent,Prop_Data,"m_iszResponseContext"))
			{
				char szResponse[32];
				GetEntPropString(thisent,Prop_Data,"m_iszResponseContext",szResponse,sizeof(szResponse));
				if (StrContains(szResponse,"func_minefield",false) == 0)
				{
					HookSingleEntityOutput(thisent,"OnStartTouch",MineFieldTouch);
				}
			}
		}
		else if ((StrEqual(clsname,"point_template",false)) || (StrEqual(clsname,"npc_template_maker",false)) || (StrEqual(clsname,"npc_maker",false)) || (StrEqual(clsname,"env_xen_portal",false)) || (StrEqual(clsname,"env_xen_portal_template",false)))
		{
			if (FindValueInArray(templateslist,thisent) == -1) PushArrayCell(templateslist,thisent);
		}
		else if (StrEqual(clsname,"env_mortar_controller",false))
		{
			int setupcontrol = GetEntPropEnt(thisent,Prop_Data,"m_hEffectEntity");
			if (IsValidEntity(setupcontrol))
			{
				HookSingleEntityOutput(setupcontrol,"PressedMoveLeft",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"PressedMoveRight",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"PressedForward",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"PressedBack",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"PressedAttack",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"UnpressedMoveLeft",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"UnpressedMoveRight",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"UnpressedForward",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"UnpressedBack",env_mortarcontroller);
				HookSingleEntityOutput(setupcontrol,"PlayerOff",env_mortarcontroller);
				SDKHookEx(setupcontrol,SDKHook_Think,camthink);
			}
			SDKHookEx(thisent,SDKHook_Use,env_mortarcontrolleractivate);
		}
		else if (HasEntProp(thisent,Prop_Data,"m_iName"))
		{
			char targn[32];
			GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
			if (StrEqual(targn,"synweapmanagers",false))
				weapmanagersplaced = true;
			else if (HasEntProp(thisent,Prop_Data,"m_hParent"))
			{
				int parentchk = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
				int ownerent = -1;
				if (HasEntProp(thisent,Prop_Data,"m_hOwnerEntity")) ownerent = GetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity");
				if (IsValidEntity(parentchk))
				{
					char parcls[24];
					GetEntityClassname(parentchk,parcls,sizeof(parcls));
					if ((StrEqual(parcls,"npc_houndeye",false)) || (StrEqual(parcls,"monster_houndeye",false)))
					{
						if (FindValueInArray(hounds,parentchk) == -1)
						{
							PushArrayCell(hounds,parentchk);
							PushArrayCell(houndsmdl,thisent);
							SDKHookEx(parentchk,SDKHook_Think,houndthink);
							SDKHookEx(parentchk,SDKHook_OnTakeDamage,houndtkdmg);
							SDKHookEx(thisent,SDKHook_OnTakeDamage,houndbboxtkdmg);
							HookSingleEntityOutput(parentchk,"OnDeath",OnCDeath);
						}
					}
					else if ((StrEqual(parcls,"npc_bullsquid",false)) || (StrEqual(parcls,"monster_bullchicken",false)))
					{
						if (FindValueInArray(squids,parentchk) == -1)
						{
							if (FindStringInArray(precachedarr,"npc_bullsquid") == -1)
							{
								PrecacheSound("npc/antlion/idle1.wav",true);
								PrecacheSound("npc/antlion/idle2.wav",true);
								PrecacheSound("npc/antlion/idle3.wav",true);
								PrecacheSound("npc/antlion/idle4.wav",true);
								PrecacheSound("npc/antlion/idle5.wav",true);
								PrecacheSound("npc/antlion/pain1.wav",true);
								PrecacheSound("npc/antlion/pain2.wav",true);
								PrecacheSound("npc/antlion/attack_single1.wav",true);
								PrecacheSound("npc/antlion/attack_single2.wav",true);
								PrecacheSound("npc/antlion/attack_single3.wav",true);
								recursion("sound/npc/bullsquid/");
								recursion("sound/bullchicken/");
								PushArrayString(precachedarr,"npc_bullsquid");
							}
							PushArrayCell(squids,parentchk);
							PushArrayCell(squidsmdl,thisent);
							SDKHookEx(parentchk,SDKHook_Think,squidthink);
							SDKHookEx(parentchk,SDKHook_OnTakeDamage,squidtkdmg);
							HookSingleEntityOutput(parentchk,"OnDeath",OnCDeath);
							AcceptEntityInput(thisent,"GagEnable");
						}
					}
					else if (StrEqual(parcls,"npc_abrams",false))
					{
						SDKHookEx(parentchk,SDKHook_Think,abramsthink);
						SDKHookEx(parentchk,SDKHook_OnTakeDamage,abramstkdmg);
						SDKHookEx(thisent,SDKHook_OnTakeDamage,abramstkdmg);
					}
				}
				else if ((IsValidEntity(ownerent)) && (ownerent != 0))
				{
					char parcls[24];
					GetEntityClassname(ownerent,parcls,sizeof(parcls));
					if ((StrEqual(targn,"syn_xeniantentaclemdl",false)) && (StrEqual(parcls,"npc_tentacle",false)))
					{
						if (FindValueInArray(tents,ownerent) == -1)
						{
							PushArrayCell(tents,ownerent);
							PushArrayCell(tentsmdl,thisent);
							int sndent = GetEntPropEnt(thisent,Prop_Data,"m_hEffectEntity");
							if (sndent != -1) PushArrayCell(tentssnd,sndent);
							SDKHookEx(ownerent,SDKHook_Think,tentaclethink);
							SDKHookEx(ownerent,SDKHook_OnTakeDamage,tentacletkdmg);
							HookSingleEntityOutput(ownerent,"OnDeath",OnCDeath);
						}
					}
					else if ((StrEqual(parcls,"func_tow",false)) || (StrEqual(parcls,"func_50cal",false)))
					{
						if (FindStringInArray(precachedarr,parcls) == -1)
						{
							recursion("sound/weapons/50cal/");
							recursion("sound/weapons/tow/");
							PushArrayString(precachedarr,parcls);
						}
						SDKHookEx(ownerent,SDKHook_Think,functankthink);
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
		else if (StrEqual(clsname,"env_xen_pushpad",false))
		{
			if (FindStringInArray(precachedarr,clsname) == -1)
			{
				PrecacheSound("BMS_objects\\xenpushpad\\jumppad1.wav",true);
				PushArrayString(precachedarr,clsname);
			}
			SDKHook(thisent,SDKHook_StartTouch,StartTouchPushPad);
		}
		else if (StrEqual(clsname,"func_conveyor",false))
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
			else CloseHandle(dp);
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
		if ((HasEntProp(entity,Prop_Data,"m_ModelName")) && ((StrContains(mapbuf,"_bm_c",false) != -1) || (StrContains(mapbuf,"bmsxen_xen_c",false) != -1)))
		{
			char mdlchk[64];
			GetEntPropString(entity,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
			if (!IsModelPrecached("models/weapons/w_mp5grenade.mdl")) PrecacheModel("models/weapons/w_mp5grenade.mdl",true);
			if (StrEqual(mdlchk,"models/weapons/w_missile.mdl",false))
				SetEntityModel(entity,"models/weapons/w_mp5grenade.mdl");
			else if (StrEqual(mdlchk,"models/weapons/w_missile_launch.mdl",false))
			{
				SetEntityModel(entity,"models/weapons/w_mp5grenade.mdl");
				Handle dp = CreateDataPack();
				WritePackString(dp,"models/weapons/w_mp5grenade.mdl");
				WritePackCell(dp,entity);
				WritePackString(dp,"rpg_missile");
				CreateTimer(0.1,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public void chkgeneric(int entity)
{
	SDKUnhook(entity,SDKHook_Spawn,chkgeneric);
	if (HasEntProp(entity,Prop_Data,"m_ModelName"))
	{
		char mdl[64];
		char cls[64];
		GetEntPropString(entity,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
		GetEntityClassname(entity,cls,sizeof(cls));
		bool CreateBySpawner = false;
		if ((strlen(mdl) < 3) && (StrEqual(cls,"generic_actor",false)))
		{
			if ((iActiveSpawnEnt == entity) && (IsValidEntity(iActiveSpawner)))
			{
				if (HasEntProp(iActiveSpawner,Prop_Data,"m_ChildTargetName"))
				{
					GetEntPropString(iActiveSpawner,Prop_Data,"m_ChildTargetName",cls,sizeof(cls));
					PrintToServer("SpawnerEnt %i %i %s %s",iActiveSpawner,entity,cls,mdl);
					iActiveSpawner = -1;
					iActiveSpawnEnt = -1;
					CreateBySpawner = true;
				}
			}
			else
			{
				iActiveSpawner = -1;
				iActiveSpawnEnt = -1;
				AcceptEntityInput(entity,"kill");
				PrintToServer("ErrorEnt %i %s %s",entity,cls,mdl);
			}
		}
		else if (strlen(mdl) < 3)
		{
			AcceptEntityInput(entity,"kill");
			PrintToServer("ErrorEnt %i %s %s",entity,cls,mdl);
			return;
		}
		if ((StrContains(cls,"npc_sentry_ceiling",false) == 0) && (CreateBySpawner))
		{
			if (FileExists("models/NPCs/sentry_ceiling.mdl",true,NULL_STRING))
			{
				DispatchKeyValue(entity,"model","models/NPCs/sentry_ceiling.mdl");
				DispatchKeyValue(entity,"classname","npc_sentry_ceiling");
				ReplaceStringEx(cls,sizeof(cls),"npc_sentry_ceiling","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				if (!IsModelPrecached("models/NPCs/sentry_ceiling.mdl")) PrecacheModel("models/NPCs/sentry_ceiling.mdl",true);
				SetEntityModel(entity,"models/NPCs/sentry_ceiling.mdl");
				if (FindStringInArray(precachedarr,"npc_sentry_ground") == -1)
				{
					PrecacheSound("weapons\\mp5\\empty.wav",true);
					recursion("sound/npc/sentry_ceiling/");
					PushArrayString(precachedarr,"npc_sentry_ground");
				}
				int mhchk = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
				Handle cvar = FindConVar("sk_sentry_ceiling_health");
				if (cvar != INVALID_HANDLE)
				{
					int cvarh = GetConVarInt(cvar);
					if (mhchk != cvarh)
					{
						SetEntProp(entity,Prop_Data,"m_iHealth",cvarh);
						SetEntProp(entity,Prop_Data,"m_iMaxHealth",cvarh);
					}
				}
				CloseHandle(cvar);
				SDKHookEx(entity,SDKHook_Think,sentriesthink);
			}
			else
			{
				AcceptEntityInput(entity,"kill");
				PrintToServer("ErrorEnt %i %s %s",entity,cls,mdl);
			}
		}
		else if ((StrContains(cls,"npc_sentry_ground",false) == 0) && (CreateBySpawner))
		{
			if (FileExists("models/NPCs/sentry_ground.mdl",true,NULL_STRING))
			{
				DispatchKeyValue(entity,"model","models/NPCs/sentry_ground.mdl");
				DispatchKeyValue(entity,"classname","npc_sentry_ground");
				ReplaceString(cls,sizeof(cls),"npc_sentry_ground","");
				SetEntPropString(entity,Prop_Data,"m_iName",cls);
				if (!IsModelPrecached("models/NPCs/sentry_ground.mdl")) PrecacheModel("models/NPCs/sentry_ground.mdl",true);
				//SetEntityModel(entity,"models/NPCs/sentry_ground.mdl");
				SetEntPropString(entity,Prop_Data,"m_ModelName","models/NPCs/sentry_ground.mdl");
				int propphy = CreateEntityByName("prop_physics_override");
				if (propphy != -1)
				{
					char targn[64];
					char restoretn[64];
					GetEntPropString(entity,Prop_Data,"m_iName",targn,sizeof(targn));
					Format(restoretn,sizeof(restoretn),"%s",targn);
					Format(targn,sizeof(targn),"%s%iprop",targn,entity);
					DispatchKeyValue(propphy,"model","models/NPCs/sentry_ground.mdl");
					DispatchKeyValue(propphy,"DisableBoneFollowers","1");
					DispatchKeyValue(propphy,"DisableShadows","1");
					DispatchKeyValue(propphy,"rendermode","10");
					DispatchKeyValue(propphy,"renderfx","6");
					DispatchKeyValue(propphy,"rendercolor","0 0 0");
					DispatchKeyValue(propphy,"renderamt","0");
					DispatchKeyValue(propphy,"modelscale","1.1");
					DispatchKeyValue(propphy,"targetname",targn);
					DispatchSpawn(propphy);
					ActivateEntity(propphy);
					SetEntPropEnt(propphy,Prop_Data,"m_hEffectEntity",entity);
					//SetVariantString("!activator");
					//AcceptEntityInput(entity,"SetParent",propphy);
					CreateTimer(0.1,SetupSentryDelay,propphy,TIMER_FLAG_NO_MAPCHANGE);
					int logcoll = CreateEntityByName("logic_collision_pair");
					if (logcoll != -1)
					{
						DispatchKeyValue(logcoll,"attach1",targn);
						Format(targn,sizeof(targn),"%s%isentry",restoretn,entity);
						DispatchKeyValue(logcoll,"attach2",targn);
						DispatchKeyValue(logcoll,"StartDisabled","1");
						DispatchSpawn(logcoll);
						ActivateEntity(logcoll);
						AcceptEntityInput(logcoll,"DisableCollisions");
						Handle dp2 = CreateDataPack();
						WritePackCell(dp2,logcoll);
						WritePackString(dp2,"logic_collision_pair");
						CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
						Handle dppass = CreateDataPack();
						WritePackString(dppass,restoretn);
						WritePackCell(dppass,entity);
						WritePackCell(dppass,logcoll);
						CreateTimer(0.5,restoretargn,dppass,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			else
			{
				AcceptEntityInput(entity,"kill");
				PrintToServer("ErrorEnt %i %s %s",entity,cls,mdl);
			}
		}
	}
	return;
}

public void resetweapmv(int entity)
{
	SDKUnhook(entity,SDKHook_Spawn,resetweapmv);
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
			if ((!IsValidEntity(parent)) && (hWeaponRespawn.BoolValue))
			{
				CreateTimer(0.1,ReCheckOwnerWeapon,entity,TIMER_FLAG_NO_MAPCHANGE);
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

public Action ReCheckOwnerWeapon(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hParent"))
		{
			if (GetEntPropEnt(entity,Prop_Data,"m_hParent") == -1)
			{
				if (HasEntProp(entity,Prop_Data,"m_iRespawnCount")) SetEntProp(entity,Prop_Data,"m_iRespawnCount",-1);
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
		else if (StrEqual(clsname,"env_sprite",false))
		{
			float proxysize = GetEntPropFloat(logent,Prop_Data,"m_flGlowProxySize");
			if (proxysize > 256.0) SetEntPropFloat(logent,Prop_Data,"m_flGlowProxySize",256.0);
		}
		else if (StrEqual(clsname,"env_laser",false))
		{
			if (HasEntProp(logent,Prop_Data,"m_flDamage"))
			{
				if (GetEntPropFloat(logent,Prop_Data,"m_flDamage") > 999.0) SetEntPropFloat(logent,Prop_Data,"m_flDamage",999.0);
			}
		}
		else if ((StrEqual(clsname,"npc_houndeye",false)) || (StrEqual(clsname,"monster_houndeye",false)))
		{
			if (FindValueInArray(hounds,logent) == -1)
			{
				if ((FileExists("models/xenians/houndeye.mdl",true,NULL_STRING)) || (FileExists("models/_monsters/xen/houndeye.mdl",true,NULL_STRING)) || (FileExists("models/houndeye.mdl",true,NULL_STRING)))
				{
					setuphound(logent);
				}
			}
		}
		else if ((StrEqual(clsname,"npc_bullsquid",false)) || (StrEqual(clsname,"monster_bullchicken",false)))
		{
			if (FindValueInArray(squids,logent) == -1)
			{
				if ((FileExists("models/xenians/bullsquid.mdl",true,NULL_STRING)) || (FileExists("models/bullsquid.mdl",true,NULL_STRING)))
				{
					setupsquid(logent);
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
					if (FileExists("models/zombie/zsecurity.mdl",true,NULL_STRING))
					{
						if (!IsModelPrecached("models/zombie/zsecurity.mdl")) PrecacheModel("models/zombie/zsecurity.mdl",true);
						DispatchKeyValue(logent,"model","models/zombie/zsecurity.mdl");
						SetEntityModel(logent,"models/zombie/zsecurity.mdl");
					}
					else
					{
						if (!IsModelPrecached("models/zombies/zombie_guard.mdl")) PrecacheModel("models/zombies/zombie_guard.mdl",true);
						DispatchKeyValue(logent,"model","models/zombies/zombie_guard.mdl");
						SetEntityModel(logent,"models/zombies/zombie_guard.mdl");
					}
				}
			}
			else if ((StrEqual(clschk,"npc_snark")) || (StrEqual(mdl,"models/props_vehicles/abrams.mdl",false)))
			{
				AcceptEntityInput(logent,"kill");
			}
			else if ((StrEqual(clschk,"generic_actor")) && (StrEqual(mdl,"models/roller.mdl",false)))
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
			else if (FileExists("models/w_battery.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/w_battery.mdl")) PrecacheModel("models/w_battery.mdl",true);
				SetEntityModel(logent,"models/w_battery.mdl");
			}
		}
		else if (StrEqual(clsname,"item_longjump",false))
		{
			SDKHook(logent,SDKHook_StartTouch,StartTouchLongJump);
			//Until mat fix
			SetEntProp(logent,Prop_Data,"m_nRenderMode",10);
			if (FileExists("models/weapons/w_longjump.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/weapons/w_longjump.mdl")) PrecacheModel("models/weapons/w_longjump.mdl",true);
				SetEntityModel(logent,"models/weapons/w_longjump.mdl");
			}
		}
		else if ((StrEqual(clsname,"item_ammo_flare_box",false)) || (StrEqual(clsname,"item_box_flare_rounds",false)))
		{
			if (FileExists("models/_weapons/flarebox.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/_weapons/flarebox.mdl")) PrecacheModel("models/_weapons/flarebox.mdl",true);
				SetEntityModel(logent,"models/_weapons/flarebox.mdl");
			}
			else if (FileExists("models/items/boxflares.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/items/boxflares.mdl")) PrecacheModel("models/items/boxflares.mdl",true);
				SetEntityModel(logent,"models/items/boxflares.mdl");
			}
		}
		else if (StrEqual(clsname,"item_ammo_energy",false))
		{
			if (FileExists("models/weapons/w_gaussammo.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/weapons/w_gaussammo.mdl")) PrecacheModel("models/weapons/w_gaussammo.mdl",true);
				SetEntityModel(logent,"models/weapons/w_gaussammo.mdl");
			}
			else if (FileExists("models/w_gaussammo.mdl",true,NULL_STRING))
			{
				if (!IsModelPrecached("models/w_gaussammo.mdl")) PrecacheModel("models/w_gaussammo.mdl",true);
				SetEntityModel(logent,"models/w_gaussammo.mdl");
			}
		}
		else if (StrEqual(clsname,"npc_sentry_ceiling",false))
		{
			if (FileExists("models/NPCs/sentry_ceiling.mdl",true,NULL_STRING))
			{
				if (FindStringInArray(precachedarr,clsname) == -1)
				{
					PrecacheSound("weapons\\mp5\\empty.wav",true);
					recursion("sound/npc/sentry_ceiling/");
					PushArrayString(precachedarr,clsname);
				}
				int mhchk = GetEntProp(logent,Prop_Data,"m_iMaxHealth");
				Handle cvar = FindConVar("sk_sentry_ceiling_health");
				if (cvar != INVALID_HANDLE)
				{
					int cvarh = GetConVarInt(cvar);
					if (mhchk != cvarh)
					{
						SetEntProp(logent,Prop_Data,"m_iHealth",cvarh);
						SetEntProp(logent,Prop_Data,"m_iMaxHealth",cvarh);
					}
				}
				CloseHandle(cvar);
				SDKHookEx(logent,SDKHook_Think,sentriesthink);
			}
		}
		else if (StrEqual(clsname,"npc_sentry_ground",false))
		{
			if (FileExists("models/NPCs/sentry_ground.mdl",true,NULL_STRING))
			{
				if (FindStringInArray(precachedarr,clsname) == -1)
				{
					PrecacheSound("weapons\\mp5\\empty.wav",true);
					recursion("sound/npc/sentry_ground/");
					PushArrayString(precachedarr,clsname);
				}
				if (HasEntProp(logent,Prop_Data,"m_bloodColor")) SetEntProp(logent,Prop_Data,"m_bloodColor",3);
				SDKHookEx(logent,SDKHook_Think,sentriesthink);
				SDKHookEx(logent,SDKHook_OnTakeDamage,notkdmg);
			}
		}
		else if (StrEqual(clsname,"npc_alien_controller",false))
		{
			if (FindStringInArray(precachedarr,"npc_alien_controller") == -1)
			{
				recursion("sound/npc/alien_controller/");
				PushArrayString(precachedarr,"npc_alien_controller");
			}
			if (HasEntProp(logent,Prop_Data,"m_iHealth"))
			{
				int maxh = GetEntProp(logent,Prop_Data,"m_iMaxHealth");
				Handle cvar = FindConVar("sk_controller_health");
				if (cvar != INVALID_HANDLE)
				{
					int maxhchk = GetConVarInt(cvar);
					if (maxh != maxhchk)
					{
						SetEntProp(logent,Prop_Data,"m_iHealth",maxhchk);
						SetEntProp(logent,Prop_Data,"m_iMaxHealth",maxhchk);
					}
				}
				CloseHandle(cvar);
			}
			if (HasEntProp(logent,Prop_Data,"m_bloodColor")) SetEntProp(logent,Prop_Data,"m_bloodColor",1);
			SDKHookEx(logent,SDKHook_Think,controllerthink);
			SDKHookEx(logent,SDKHook_OnTakeDamage,controllertkdmg);
			PushArrayCell(controllers,logent);
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
	bPrevOpen[client] = false;
	if (IsValidEntity(weapon))
	{
		char weapname[32];
		GetEntityClassname(weapon,weapname,sizeof(weapname));
		if (instswitch > 0)
		{
			if ((StrEqual(weapname,"weapon_physcannon",false)) || (instswitch == 2))
			{
				Handle data;
				data = CreateDataPack();
				WritePackCell(data, client);
				WritePackCell(data, weapon);
				CreateTimer(0.1,resetinst,data,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if (FixWeapSnd)
		{
			if (bPrevWeapRPG[client])
			{
				EmitSoundToAll("weapons/sniper/sniper_zoomout.wav", client, SNDCHAN_WEAPON, 30);
				bPrevWeapRPG[client] = false;
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

void findspawnpos(int client)
{
	int fallbackspawn = -1;
	bool teleported = false;
	float novel[3];
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
					TeleportEntity(client,origin,angs,novel);
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
		TeleportEntity(client,origin,angs,novel);
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
		char clsofent[24];
		GetEntityClassname(thisent,clsofent,sizeof(clsofent));
		if ((StrEqual(clsofent,"npc_template_maker",false)) || (StrEqual(clsofent,"npc_maker",false)))
		{
			if (HasEntProp(thisent,Prop_Data,"m_nMaxNumNPCs"))
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
		}
		if (StrEqual(clsofent,"npc_houndeye",false))
		{
			setuphound(thisent);
		}
		else if (StrEqual(clsofent,"npc_bullsquid",false))
		{
			setupsquid(thisent);
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
			if (FindValueInArray(tents,thisent) == -1)
			{
				PushArrayCell(tents,thisent);
				int entmdl = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdl,"model","models/xenians/tentacle.mdl");
				DispatchKeyValue(entmdl,"targetname","syn_xeniantentaclemdl");
				DispatchKeyValue(entmdl,"solid","6");
				DispatchKeyValue(entmdl,"DefaultAnim","floor_idle");
				DispatchSpawn(entmdl);
				ActivateEntity(entmdl);
				PushArrayCell(tentsmdl,entmdl);
				SetEntPropEnt(entmdl,Prop_Data,"m_hOwnerEntity",thisent);
				int entsnd = CreateEntityByName("ambient_generic");
				DispatchKeyValue(entsnd,"message","npc/tentacle/tent_sing_close1.wav");
				DispatchSpawn(entsnd);
				ActivateEntity(entsnd);
				SetVariantString("!activator");
				AcceptEntityInput(entsnd,"SetParent",entmdl);
				SetVariantString("Eye");
				AcceptEntityInput(entsnd,"SetParentAttachment");
				PushArrayCell(tentssnd,entsnd);
				SetEntPropEnt(entmdl,Prop_Data,"m_hEffectEntity",entsnd);
				SDKHookEx(thisent,SDKHook_Think,tentaclethink);
				SDKHookEx(thisent,SDKHook_OnTakeDamage,tentacletkdmg);
				HookSingleEntityOutput(thisent,"OnDeath",OnCDeath);
				float tentor[3];
				float tentang[3];
				GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",tentor);
				GetEntPropVector(thisent,Prop_Data,"m_angRotation",tentang);
				TeleportEntity(entmdl,tentor,tentang,NULL_VECTOR);
			}
			customents = true;
		}
		else if ((StrEqual(clsofent,"npc_ichthyosaur",false)) || (StrEqual(clsofent,"monster_ichthyosaur",false)))
		{
			SetEntProp(thisent,Prop_Data,"m_MoveType",7);
			if (HasEntProp(thisent,Prop_Data,"m_bloodColor")) SetEntProp(thisent,Prop_Data,"m_bloodColor",2);
			SDKHookEx(thisent,SDKHook_Think,ichythink);
			HookSingleEntityOutput(thisent,"OnFoundEnemy",OnIchyFoundPlayer);
			HookSingleEntityOutput(thisent,"OnDeath",OnCDeath);
		}
		else if (StrEqual(clsofent,"npc_merchant",false))
		{
			customents = true;
			HookSingleEntityOutput(thisent,"OnUser1",MerchantUse);
		}
		else if (StrEqual(clsofent,"npc_alien_slave",false))
		{
			SDKHookEx(thisent,SDKHook_Think,aslavethink);
			SetEntProp(thisent,Prop_Data,"m_nRenderFX",6);
			if (!relsetvort)
			{
				setuprelations("npc_alien_slave");
				relsetvort = true;
			}
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_alien_grunt",false))
		{
			if (FindStringInArray(precachedarr,"npc_alien_grunt") == -1)
			{
				char searchprecache[128];
				Format(searchprecache,sizeof(searchprecache),"sound/npc/alien_grunt/");
				recursion(searchprecache);
				Format(searchprecache,sizeof(searchprecache),"sound/weapons/hivehand/");
				recursion(searchprecache);
				PushArrayString(precachedarr,"npc_alien_grunt");
			}
			if (!relsetvort)
			{
				setuprelations("npc_alien_grunt");
				relsetvort = true;
			}
			AcceptEntityInput(thisent,"GagEnable");
			SDKHookEx(thisent,SDKHook_Think,agruntthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,agrunttkdmg);
			HookSingleEntityOutput(thisent,"OnDeath",OnCDeath);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_abrams",false))
		{
			if (FindStringInArray(precachedarr,"npc_abrams") == -1)
			{
				PrecacheSound("weapons/weap_explode/explode3.wav",true);
				PrecacheSound("weapons/weap_explode/explode4.wav",true);
				PrecacheSound("weapons/weap_explode/explode5.wav",true);
				recursion("sound/weapons/50cal/");
				recursion("sound/weapons/m4/");
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
			int mdl = GetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity");
			if (mdl != -1)
			{
				SDKHookEx(mdl,SDKHook_OnTakeDamage,abramstkdmg);
			}
			else
			{
				int boundbox = CreateEntityByName("prop_dynamic");
				if (boundbox != -1)
				{
					char targn[64];
					GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
					if (strlen(targn) < 1)
					{
						Format(targn,sizeof(targn),"npc_abrams%i",thisent);
						SetEntPropString(thisent,Prop_Data,"m_iName",targn);
					}
					char boundbtarg[64];
					Format(boundbtarg,sizeof(boundbtarg),"abramsbox%i",boundbox);
					float orgs[3];
					float angs[3];
					if (HasEntProp(thisent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(thisent,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(thisent,Prop_Send,"m_vecOrigin")) GetEntPropVector(thisent,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(thisent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(thisent,Prop_Data,"m_angAbsRotation",angs);
					DispatchKeyValue(boundbox,"rendermode","10");
					DispatchKeyValue(boundbox,"solid","6");
					DispatchKeyValue(boundbox,"model","models/props_vehicles/abrams.mdl");
					TeleportEntity(boundbox,orgs,angs,NULL_VECTOR);
					DispatchSpawn(boundbox);
					ActivateEntity(boundbox);
					SetVariantString("!activator");
					AcceptEntityInput(boundbox,"SetParent",thisent);
					SDKHookEx(boundbox,SDKHook_OnTakeDamage,abramstkdmg);
					SetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity",boundbox);
					int logcoll = CreateEntityByName("logic_collision_pair");
					if (logcoll != -1)
					{
						DispatchKeyValue(logcoll,"attach1",targn);
						DispatchKeyValue(logcoll,"attach2",boundbtarg);
						DispatchKeyValue(logcoll,"StartDisabled","1");
						DispatchSpawn(logcoll);
						ActivateEntity(logcoll);
					}
				}
			}
			SDKHookEx(thisent,SDKHook_Think,abramsthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,abramstkdmg);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_human_assassin",false))
		{
			SDKHookEx(thisent,SDKHook_Think,assassinthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,assassintkdmg);
			char mdlchk[64];
			GetEntPropString(thisent,Prop_Data,"m_ModelName",mdlchk,sizeof(mdlchk));
			if (!StrEqual(mdlchk,"models/humans/hassassin.mdl",false))
			{
				DispatchKeyValue(thisent,"model","models/humans/hassassin.mdl");
				SetEntPropString(thisent,Prop_Data,"m_ModelName","models/humans/hassassin.mdl");
				SetEntityModel(thisent,"models/humans/hassassin.mdl");
			}
			if (GetEntPropEnt(thisent,Prop_Data,"m_hEffectEntity") == -1)
			{
				int pistol = CreateEntityByName("prop_physics");
				if (pistol != -1)
				{
					DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
					DispatchKeyValue(pistol,"solid","0");
					SetVariantString("!activator");
					AcceptEntityInput(pistol,"SetParent",thisent);
					SetVariantString("anim_attachment_LH");
					AcceptEntityInput(pistol,"SetParentAttachment");
					DispatchSpawn(pistol);
					ActivateEntity(pistol);
					SetEntPropEnt(thisent,Prop_Data,"m_hEffectEntity",pistol);
				}
			}
			if (GetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity") == -1)
			{
				int pistol = CreateEntityByName("prop_physics");
				if (pistol != -1)
				{
					DispatchKeyValue(pistol,"model","models/weapons/w_glock_lh.mdl");
					DispatchKeyValue(pistol,"solid","0");
					SetVariantString("!activator");
					AcceptEntityInput(pistol,"SetParent",thisent);
					SetVariantString("anim_attachment_RH");
					AcceptEntityInput(pistol,"SetParentAttachment");
					DispatchSpawn(pistol);
					ActivateEntity(pistol);
					SetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity",pistol);
				}
			}
			if (FindStringInArray(precachedarr,"npc_human_assassin") == -1)
			{
				char searchprecache[128];
				Format(searchprecache,sizeof(searchprecache),"sound/weapons/glock/");
				recursion(searchprecache);
				Format(searchprecache,sizeof(searchprecache),"sound/npc/assassin/");
				recursion(searchprecache);
				PushArrayString(precachedarr,"npc_human_assassin");
			}
			customents = true;
		}
		else if (StrContains(clsofent,"monster_human_assassin",false) == 0)
		{
			if (FileExists("models/hassassin.mdl",true,NULL_STRING))
			{
				SDKHookEx(thisent,SDKHook_Think,assassinthink);
				SDKHookEx(thisent,SDKHook_OnTakeDamage,assassintkdmg);
				if (FindStringInArray(precachedarr,"monster_human_assassin") == -1)
				{
					PrecacheSound("common\\bodydrop1.wav",true);
					PrecacheSound("common\\bodydrop2.wav",true);
					PrecacheSound("common\\bodydrop3.wav",true);
					PrecacheSound("common\\bodydrop4.wav",true);
					PrecacheSound("weapons\\pl_gun1.wav",true);
					PrecacheSound("weapons\\pl_gun2.wav",true);
					PushArrayString(precachedarr,"monster_human_assassin");
				}
			}
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_sentry_ground",false))
		{
			if (FindStringInArray(precachedarr,clsofent) == -1)
			{
				PrecacheSound("weapons\\mp5\\empty.wav",true);
				recursion("sound/npc/sentry_ground/");
				PushArrayString(precachedarr,clsofent);
			}
			if (HasEntProp(thisent,Prop_Data,"m_bloodColor")) SetEntProp(thisent,Prop_Data,"m_bloodColor",3);
			SDKHookEx(thisent,SDKHook_Think,sentriesthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,notkdmg);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_sentry_ceiling",false))
		{
			if (FindStringInArray(precachedarr,clsofent) == -1)
			{
				PrecacheSound("weapons\\mp5\\empty.wav",true);
				recursion("sound/npc/sentry_ceiling/");
				PushArrayString(precachedarr,clsofent);
			}
			SDKHookEx(thisent,SDKHook_Think,sentriesthink);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_alien_controller",false))
		{
			if (FindStringInArray(precachedarr,"npc_alien_controller") == -1)
			{
				recursion("sound/npc/alien_controller/");
				PushArrayString(precachedarr,"npc_alien_controller");
			}
			if (HasEntProp(thisent,Prop_Data,"m_iHealth"))
			{
				int maxh = GetEntProp(thisent,Prop_Data,"m_iMaxHealth");
				Handle cvar = FindConVar("sk_controller_health");
				if (cvar != INVALID_HANDLE)
				{
					int maxhchk = GetConVarInt(cvar);
					if (maxh != maxhchk)
					{
						SetEntProp(thisent,Prop_Data,"m_iHealth",maxhchk);
						SetEntProp(thisent,Prop_Data,"m_iMaxHealth",maxhchk);
					}
				}
				CloseHandle(cvar);
			}
			if (HasEntProp(thisent,Prop_Data,"m_bloodColor")) SetEntProp(thisent,Prop_Data,"m_bloodColor",1);
			SDKHookEx(thisent,SDKHook_Think,controllerthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,controllertkdmg);
			PushArrayCell(controllers,thisent);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_gargantua",false))
		{
			SDKHook(thisent, SDKHook_OnTakeDamage, TakeDamageCustom);
		}
		else if (StrEqual(clsofent,"npc_gonarch",false))
		{
			SDKHookEx(thisent,SDKHook_Think,gonarchthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,gonarchtkdmg);
			customents = true;
		}
		else if (StrEqual(clsofent,"monster_zombie",false))
		{
			SDKHookEx(thisent,SDKHook_Think,monstzomthink);
			customents = true;
		}
		else if (StrEqual(clsofent,"npc_bmsgargantua",false))
		{
			if (FindStringInArray(precachedarr,"npc_bmsgargantua") == -1)
			{
				char searchprecache[128];
				Format(searchprecache,sizeof(searchprecache),"sound/npc/garg/");
				recursion(searchprecache);
				PushArrayString(precachedarr,"npc_bmsgargantua");
			}
			SDKHookEx(thisent,SDKHook_Think,bmsgargthink);
			SDKHookEx(thisent,SDKHook_OnTakeDamage,bmsgargtkdmg);
			customents = true;
		}
		if (((StrContains(clsofent,"npc_",false) != -1) || (StrContains(clsofent,"monster_",false) != -1) || (StrEqual(clsofent,"generic_actor",false)) || (StrEqual(clsofent,"generic_monster",false))) && (!StrEqual(clsofent,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(clsofent,"npc_bullseye",false)) && (!StrEqual(clsofent,"env_xen_portal",false)) && (!StrEqual(clsofent,"env_xen_portal_template",false)) && (!StrEqual(clsofent,"npc_maker",false)) && (!StrEqual(clsofent,"npc_template_maker",false)) && (StrContains(clsofent,"info_",false) == -1) && (StrContains(clsofent,"game_",false) == -1) && (StrContains(clsofent,"trigger_",false) == -1) && (FindValueInArray(entlist,thisent) == -1))
			PushArrayCell(entlist,thisent);
		findentlist(thisent++,clsname);
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	ClientCommand(client,"alias sv_shutdown \"echo nope\"");
	if (bBlockEx) ClientCommand(client,"alias exec \"echo nope\"");
	return true;
}

int g_LastButtons[128];

public void OnClientDisconnect_Post(int client)
{
	g_LastButtons[client] = 0;
	clrocket[client] = 0;
	centnextatk[client] = 0.0;
	custentactive[client] = 0;
	Format(restorelang[client],sizeof(restorelang[]),"");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_DUCK) {
		if ((GetEntProp(client,Prop_Data,"m_bDucked")) && (GetEntProp(client,Prop_Data,"m_bDucking")))
		{
			float Time = GetTickedTime();
			if (antispamchk[client] <= Time)
			{
				antispamchk[client] = Time + 0.1;
			}
			else
			{
				ClientCommand(client,"-duck");
				return Plugin_Changed;
			}
		}
	}
	int vehicles = -1;
	if (HasEntProp(client,Prop_Data,"m_hVehicle")) vehicles = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
	if (buttons & IN_ATTACK) {
		if (!(g_LastButtons[client] & IN_ATTACK)) {
			OnButtonPressTankchk(client,IN_ATTACK);
		}
		int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
		if ((StrContains(mapbuf,"maps/ent_cache/bms_bm_c",false) == 0) || (StrContains(mapbuf,"maps/ent_cache/bms_hc_t",false) == 0) || (StrContains(mapbuf,"maps/ent_cache/bmsxen_xen_c",false) == 0))
		{
			char curweap[24];
			GetClientWeapon(client,curweap,sizeof(curweap));
			if ((StrEqual(curweap,"weapon_crowbar",false)) && (vehicle == -1))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (IsValidEntity(weap))
				{
					if (HasEntProp(weap,Prop_Data,"m_flNextPrimaryAttack"))
					{
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
						if (centnextatk[client] > GetGameTime()+3.0) centnextatk[client] = GetGameTime();
						if (centnextatk[client] < nextatk)
						{
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",nextatk-0.1);
							centnextatk[client] = nextatk+0.05;
						}
					}
				}
			}
		}
		char curweap[24];
		GetClientWeapon(client,curweap,sizeof(curweap));
		if ((StrEqual(curweap,"weapon_crossbow",false)) && (vehicle == -1))
		{
			int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(weap))
			{
				if (HasEntProp(weap,Prop_Data,"m_iClip1"))
				{
					int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
					float Time = GetTickedTime();
					if ((curclip > 0) && (centnextatk[weap] < Time))
					{
						if (HasEntProp(weap,Prop_Data,"m_bReloadsSingly")) SetEntProp(weap,Prop_Data,"m_bReloadsSingly",0);
						if (HasEntProp(weap,Prop_Send,"m_bMustReload"))
						{
							int mustrel = GetEntProp(weap,Prop_Send,"m_bMustReload");
							SetEntProp(weap,Prop_Send,"m_bMustReload",0);
							if (mustrel)
							{
								SetEntProp(weap,Prop_Data,"m_bInReload",0);
								char shootsnd[64];
								int chan,sndlvl,pitch;
								float vol;
								GetGameSoundParams("Weapon_Crossbow.Single",chan,sndlvl,vol,pitch,shootsnd,sizeof(shootsnd),0);
								if (strlen(shootsnd) > 0)
								{
									EmitGameSoundToAll("Weapon_Crossbow.Single",client);
								}
							}
							CreateTimer(0.1,resetweapreload,weap,TIMER_FLAG_NO_MAPCHANGE);
						}
						centnextatk[weap] = Time + 2.0;
					}
				}
			}
		}
		else if (StrEqual(curweap,"weapon_physcannon",false))
		{
			int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			centnextsndtime[weap] = GetTickedTime() + 0.5;
			bPrevOpen[client] = false;
		}
	}
	else if (FixWeapSnd)
	{
		int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
		if (vehicle == -1)
		{
			int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(weap))
			{
				char curweap[24];
				GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));
				if (StrEqual(curweap,"weapon_physcannon",false))
				{
					if (HasEntProp(weap,Prop_Send,"m_bOpen"))
					{
						float Time = GetTickedTime();
						if (centnextsndtime[weap] <= Time)
						{
							int bOpen = GetEntProp(weap,Prop_Send,"m_bOpen");
							int iEffState = GetEntProp(weap,Prop_Send,"m_EffectState");
							if ((bOpen && !bPrevOpen[client]) && (iEffState != 3))
							{
								bPrevOpen[client] = true;
								EmitSoundToAll("weapons/physcannon/physcannon_claws_open.wav", client, SNDCHAN_WEAPON, 35);
							}
							else if (!bOpen && bPrevOpen[client])
							{
								bPrevOpen[client] = false;
								EmitSoundToAll("weapons/physcannon/physcannon_claws_close.wav", client, SNDCHAN_WEAPON, 35);
							}
							if (buttons & IN_ATTACK2)
							{
								if ((iEffState == 3) && (bOpen))
								{
									if (GetEntProp(weap,Prop_Send,"m_bMegaState"))
									{
										
									}
									float flIdle = GetEntPropFloat(weap,Prop_Send,"m_flTimeWeaponIdle");
									float flNextSecond = GetEntPropFloat(weap,Prop_Send,"m_flNextSecondaryAttack");
									if ((flIdle <= flNextSecond+1.0) && (!isattacking[weap]))
									{
										isattacking[weap] = 1;
										EmitSoundToAll("weapons/physcannon/physcannon_pickup.wav", client, SNDCHAN_WEAPON, 35);
									}
								}
							}
							else isattacking[weap] = 0;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_rpg",false))
				{
					if (HasEntProp(weap,Prop_Send,"m_bInitialStateUpdate"))
					{
						int bInit = GetEntProp(weap,Prop_Send,"m_bInitialStateUpdate");
						if (!bInit && bPrevOpen[client])
						{
							bPrevOpen[client] = false;
							EmitSoundToAll("weapons/sniper/sniper_zoomin.wav", client, SNDCHAN_WEAPON, 30);
						}
						else if (bInit) bPrevOpen[client] = true;
						bPrevWeapRPG[client] = true;
						float Time = GetGameTime();
						float flPrimaryAtk = GetEntPropFloat(weap,Prop_Send,"m_flNextPrimaryAttack");
						int iRPGAmm = 8;
						if (HasEntProp(weap,Prop_Send,"m_iPrimaryAmmoType")) iRPGAmm = GetEntProp(weap,Prop_Send,"m_iPrimaryAmmoType");
						int iCurAmm = GetEntProp(client,Prop_Send,"m_iAmmo",_,iRPGAmm);
						if ((iCurAmm == 0) && (!isattacking[weap]) && (flPrimaryAtk > Time+2.0))
						{
							EmitSoundToAll("weapons/sniper/sniper_zoomout.wav", client, SNDCHAN_WEAPON, 30);
							isattacking[weap] = 1;
						}
						else if (iCurAmm > 0) isattacking[weap] = 0;
					}
				}
				else if (StrEqual(curweap,"weapon_crossbow",false))
				{
					int curclip = GetEntProp(weap,Prop_Data,"m_iClip1");
					if ((curclip == 0) && (!bPrevOpen[client]))
					{
						if (HasEntProp(weap,Prop_Data,"m_bInReload"))
						{
							int bInReload = GetEntProp(weap,Prop_Data,"m_bInReload");
							if (bInReload)
							{
								float Time = GetGameTime();
								float flPrimaryAtk = GetEntPropFloat(weap,Prop_Send,"m_flNextPrimaryAttack");
								if (flPrimaryAtk < Time+1.20)
								{
									bPrevOpen[client] = true;
									char shootsnd[64];
									int chan,sndlvl,pitch;
									float vol;
									GetGameSoundParams("Weapon_Crossbow.BoltElectrify",chan,sndlvl,vol,pitch,shootsnd,sizeof(shootsnd),0);
									if (strlen(shootsnd) > 0)
									{
										EmitGameSoundToAll("Weapon_Crossbow.BoltElectrify",client);
									}
								}
							}
							else bPrevOpen[client] = false;
						}
					}
					else if (curclip > 0) bPrevOpen[client] = false;
				}
			}
		}
	}
	if (buttons & IN_ATTACK2) {
		if (!(g_LastButtons[client] & IN_ATTACK2)) {
			OnButtonPress(client,IN_ATTACK2);
		}
	}
	if (impulse == 100)
	{
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
	if (buttons & IN_JUMP) {
		if ((!(g_LastButtons[client] & IN_JUMP)) && (vehicles == -1)) {
			OnButtonPressJump(client,buttons);
		}
	}
	else if (buttons & IN_USE) {
		if (!(g_LastButtons[client] & IN_USE)) {
			OnButtonPressUse(client);
		}
	}
	g_LastButtons[client] = buttons;
	return Plugin_Continue;
}

public Action resetweapreload(Handle timer, int weap)
{
	if (IsValidEntity(weap))
	{
		char clschk[24];
		GetEntityClassname(weap,clschk,sizeof(clschk));
		if (StrContains(clschk,"weapon_",false) == 0)
		{
			SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()-0.01);
			SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()-0.01);
			SetEntProp(weap,Prop_Data,"m_bInReload",0);
			if (HasEntProp(weap,Prop_Send,"m_bMustReload")) SetEntProp(weap,Prop_Send,"m_bMustReload",0);
		}
	}
	return Plugin_Handled;
}

public void OnButtonPressTankchk(int client, int button)
{
	findcontrolledtank(-1,"func_50cal",client);
	findcontrolledtank(-1,"func_tow",client);
}

public void OnButtonPress(int client, int button)
{
	int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
	if (vehicle == -1)
	{
		if (allownoguide)
		{
			char curweap[24];
			GetClientWeapon(client,curweap,sizeof(curweap));
			if (StrEqual(curweap,"weapon_rpg",false))
			{
				if (guiderocket[client])
				{
					guiderocket[client] = false;
					PrintToChat(client,"Turned off rocket guide.");
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					SetEntProp(weap,Prop_Send,"m_bGuiding",0);
					SetEntProp(weap,Prop_Data,"m_bInReload",0);
					SetEntProp(weap,Prop_Data,"m_nSequence",2);
					EmitSoundToAll("weapons/sniper/sniper_zoomout.wav", client, SNDCHAN_WEAPON, 30);
					Handle laserdotarr = CreateArray(256);
					FindAllByClassname(laserdotarr,-1,"env_laserdot");
					if (GetArraySize(laserdotarr) > 0)
					{
						for (int i = 0;i<GetArraySize(laserdotarr);i++)
						{
							int laserdot = GetArrayCell(laserdotarr,i);
							if (IsValidEntity(laserdot))
							{
								if (HasEntProp(laserdot,Prop_Data,"m_hOwnerEntity"))
								{
									int owner = GetEntPropEnt(laserdot,Prop_Data,"m_hOwnerEntity");
									if (owner == client)
									{
										SetEntProp(laserdot,Prop_Data,"m_nRenderFX",6);
										break;
									}
								}
							}
						}
					}
					CloseHandle(laserdotarr);
				}
				else
				{
					guiderocket[client] = true;
					PrintToChat(client,"Turned on rocket guide.");
					EmitSoundToAll("weapons/sniper/sniper_zoomin.wav", client, SNDCHAN_WEAPON, 30);
					Handle laserdotarr = CreateArray(256);
					FindAllByClassname(laserdotarr,-1,"env_laserdot");
					if (GetArraySize(laserdotarr) > 0)
					{
						for (int i = 0;i<GetArraySize(laserdotarr);i++)
						{
							int laserdot = GetArrayCell(laserdotarr,i);
							if (IsValidEntity(laserdot))
							{
								if (HasEntProp(laserdot,Prop_Data,"m_hOwnerEntity"))
								{
									int owner = GetEntPropEnt(laserdot,Prop_Data,"m_hOwnerEntity");
									if (owner == client)
									{
										SetEntProp(laserdot,Prop_Data,"m_nRenderFX",0);
										break;
									}
								}
							}
						}
					}
					CloseHandle(laserdotarr);
				}
				findrockets(-1,client);
			}
		}
		if (FixWeapSnd)
		{
			int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(weap))
			{
				char curweap[24];
				GetEntPropString(weap,Prop_Data,"m_iClassname",curweap,sizeof(curweap));
				if (StrEqual(curweap,"weapon_physcannon",false))
				{
					if (HasEntProp(weap,Prop_Send,"m_bOpen"))
					{
						int bOpen = GetEntProp(weap,Prop_Send,"m_bOpen");
						int iEffState = GetEntProp(weap,Prop_Send,"m_EffectState");
						if (!bOpen)
						{
							EmitSoundToAll("weapons/physcannon/physcannon_tooheavy.wav", client, SNDCHAN_WEAPON, 35);
						}
						else if (iEffState == 2)
						{
							EmitSoundToAll("weapons/physcannon/physcannon_pickup.wav", client, SNDCHAN_WEAPON, 35);
						}
						else if (iEffState == 3)
						{
							EmitSoundToAll("weapons/physcannon/physcannon_drop.wav", client, SNDCHAN_WEAPON, 35);
						}
					}
				}
			}
		}
	}
}

public void OnButtonPressJump(int client, int buttons)
{
	if (longjumpactive)
	{
		if (LongJumpMode)
		{
			if (HasEntProp(client,Prop_Data,"m_hGroundEntity"))
			{
				int groundent = GetEntPropEnt(client,Prop_Data,"m_hGroundEntity");
				if ((LastJump[client] > GetGameTime()) && (groundent == -1))
				{
					float absvel[3];
					GetEntPropVector(client,Prop_Data,"m_vecAbsVelocity",absvel);
					float loc[3];
					float orgs[3];
					float angs[3];
					float shootvel[3];
					if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(client,Prop_Data,"m_angRotation")) GetEntPropVector(client,Prop_Data,"m_angRotation",angs);
					if ((buttons & IN_MOVERIGHT) && (buttons & IN_FORWARD)) angs[1]-=45.0;
					else if ((buttons & IN_MOVELEFT) && (buttons & IN_FORWARD)) angs[1]+=45.0;
					else if ((buttons & IN_MOVERIGHT) && (buttons & IN_BACK)) angs[1]-=135.0;
					else if ((buttons & IN_MOVELEFT) && (buttons & IN_BACK)) angs[1]+=135.0;
					else if (buttons & IN_MOVERIGHT) angs[1]-=90.0;
					else if (buttons & IN_MOVELEFT) angs[1]+=90.0;
					else if (buttons & IN_BACK) angs[1]-=180.0;
					loc[0] = (orgs[0] + (225 * Cosine(DegToRad(angs[1]))));
					loc[1] = (orgs[1] + (225 * Sine(DegToRad(angs[1]))));
					loc[2] = (orgs[2] + 70);
					MakeVectorFromPoints(orgs,loc,shootvel);
					ScaleVector(shootvel,2.0);
					shootvel[0]+=absvel[0];
					shootvel[1]+=absvel[1];
					shootvel[2]+=absvel[2];
					TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,shootvel);
					LastJump[client] = 0.0;
					EmitLongJumpSnd(client);
				}
				else if (groundent != -1)
				{
					LastJump[client] = GetGameTime()+0.5;
				}
			}
		}
		else
		{
			if ((GetEntProp(client,Prop_Send,"m_bDucking")) && (!GetEntProp(client,Prop_Send,"m_bDucked")))
			{
				float loc[3];
				float orgs[3];
				float angs[3];
				float shootvel[3];
				if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
				if (HasEntProp(client,Prop_Data,"m_angRotation")) GetEntPropVector(client,Prop_Data,"m_angRotation",angs);
				loc[0] = (orgs[0] + (250 * Cosine(DegToRad(angs[1]))));
				loc[1] = (orgs[1] + (250 * Sine(DegToRad(angs[1]))));
				loc[2] = (orgs[2] + 100);
				MakeVectorFromPoints(orgs,loc,shootvel);
				ScaleVector(shootvel,3.0);
				orgs[2]+=1.0;
				TeleportEntity(client,orgs,NULL_VECTOR,shootvel);
				EmitLongJumpSnd(client);
			}
		}
	}
}

void EmitLongJumpSnd(int client)
{
	if (IsValidEntity(client))
	{
		if (FindStringInArray(precachedarr,"item_longjump") == -1)
		{
			PrecacheSound("weapons\\jumpmod\\jumpmod_long1.wav",true);
			PrecacheSound("weapons\\jumpmod\\jumpmod_boost1.wav",true);
			PrecacheSound("weapons\\jumpmod\\jumpmod_boost2.wav",true);
			if (FileExists("sound/items/airtank1.wav",true,NULL_STRING)) PrecacheSound("items\\airtank1.wav",true);
			if (FileExists("sound/ambient/gas/cannister_loop.wav",true,NULL_STRING)) PrecacheSound("ambient\\gas\\cannister_loop.wav",true);
			PushArrayString(precachedarr,"item_longjump");
		}
		char snd[64];
		if (FileExists("sound/weapons/jumpmod/jumpmod_long1.wav",true,NULL_STRING))
		{
			int randsnd = GetRandomInt(1,3);
			if (randsnd == 3) Format(snd,sizeof(snd),"weapons\\jumpmod\\jumpmod_long1.wav");
			else Format(snd,sizeof(snd),"weapons\\jumpmod\\jumpmod_boost%i.wav",randsnd);
		}
		else if (FileExists("sound/items/airtank1.wav",true,NULL_STRING))
		{
			Format(snd,sizeof(snd),"items\\airtank1.wav");
		}
		else
		{
			Format(snd,sizeof(snd),"ambient\\gas\\cannister_loop.wav");
			EmitSoundToAll(snd, client, SNDCHAN_ITEM, SNDLEVEL_DISHWASHER, _, _, _, _, _, _, _, 0.5);
			CreateTimer(0.5,StopLoop,client,TIMER_FLAG_NO_MAPCHANGE);
			snd = "";
		}
		if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
	}
}

public Action StopLoop(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		if (IsClientConnected(client))
		{
			StopSound(client,SNDCHAN_ITEM,"ambient\\gas\\cannister_loop.wav");
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
			int npcstate = 0;
			if (HasEntProp(targ,Prop_Data,"m_NPCState")) npcstate = GetEntProp(targ,Prop_Data,"m_NPCState");
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
			if ((StrEqual(cls,"npc_merchant",false)) && (chkdist < 100.0))
			{
				AcceptEntityInput(targ,"FireUser1",client);
				MerchSpeakRef(targ,client,0);
			}
			if (npcstate != 5)//4 is scripting
			{
				if ((StrEqual(cls,"npc_human_security",false)) || (StrEqual(cls,"npc_human_scientist",false)) || (StrEqual(cls,"npc_human_scientist_female",false)))
				{
					if (chkdist < 100)
					{
						int scr = GetEntPropEnt(targ,Prop_Data,"m_hTarget");
						if ((scr == -1) && (HasEntProp(targ,Prop_Data,"m_hTargetEnt")))
						{
							scr = GetEntPropEnt(targ,Prop_Data,"m_hTargetEnt");
							if (IsValidEntity(scr))
							{
								char tmpinf[32];
								GetEntityClassname(scr,tmpinf,sizeof(tmpinf));
								if (StrEqual(tmpinf,"scripted_sequence",false))
								{
									bool resetscr = false;
									if (HasEntProp(scr,Prop_Data,"m_iName"))
									{
										GetEntPropString(scr,Prop_Data,"m_iName",tmpinf,sizeof(tmpinf));
										if (strlen(tmpinf) < 1) resetscr = true;
									}
									if (HasEntProp(scr,Prop_Data,"m_spawnflags"))
									{
										int sf = GetEntProp(scr,Prop_Data,"m_spawnflags");
										if (!(sf & 1<<9)) resetscr = true;
									}
									if (resetscr) scr = -1;
								}
							}
						}
						if (scr == -1)
						{
							bool predis = GetStateOf("predisaster");
							float Time = GetTickedTime();
							if ((!predis) && (centnextsndtime[targ] < Time))
							{
								if (!HasEntProp(targ,Prop_Data,"m_strHullName"))
								{
									char snd[64];
									int sf = GetEntProp(targ,Prop_Data,"m_spawnflags");
									if (!(sf & 1048576))
									{
										SetVariantString("spawnflags 1048576");
										AcceptEntityInput(targ,"AddOutput");
										AcceptEntityInput(targ,"RemoveFromPlayerSquad");
										SetEntProp(targ,Prop_Data,"m_spawnflags",1048576);
										if (StrEqual(cls,"npc_human_security",false))
										{
											if (HasEntProp(targ,Prop_Data,"m_bShouldPatrol")) SetEntProp(targ,Prop_Data,"m_bShouldPatrol",1);
											switch (GetRandomInt(1,5))
											{
												case 1:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\holddownspot01_2009.wav");
												case 2:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\holddownspot02_2009.wav");
												case 3:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\holddownspot03a_2009.wav");
												case 4:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\holddownspot04_2009.wav");
												case 5:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\holddownspot05_2009.wav");
												case 6:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\illstayhere01.wav");
												case 7:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\illstayhere02.wav");
												case 8:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\illstayhere03.wav");
											}
											if (strlen(snd) > 0)
											{
												EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											}
										}
										else if (StrEqual(cls,"npc_human_scientist",false))
										{
											switch (GetRandomInt(1,2))
											{
												case 1:
													Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\illstayhere0%i.wav",GetRandomInt(1,5));
												case 2:
													Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\holddownspot0%i.wav",GetRandomInt(1,5));
											}
											if (strlen(snd) > 0)
											{
												EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											}
										}
										centnextsndtime[targ] = Time + 1.0;
									}
									else
									{
										char varinp[32];
										Format(varinp,sizeof(varinp),"spawnflags %i",sf-1048576);
										SetVariantString(varinp);
										AcceptEntityInput(targ,"AddOutput");
										AcceptEntityInput(targ,"SetCommandable");
										SetEntProp(targ,Prop_Data,"m_spawnflags",sf-1048576);
										if (StrEqual(cls,"npc_human_security",false))
										{
											if (HasEntProp(targ,Prop_Data,"m_bShouldPatrol")) SetEntProp(targ,Prop_Data,"m_bShouldPatrol",0);
											switch (GetRandomInt(1,7))
											{
												case 1:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\leadon0%i.wav",GetRandomInt(1,3));
												case 2:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\leadtheway0%i.wav",GetRandomInt(1,4));
												case 3:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\letsgo0%i.wav",GetRandomInt(1,2));
												case 4:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\leadtheway_goforit01.wav");
												case 5:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\leadtheway_gotyourback01.wav");
												case 6:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\leadtheway_keepyoucovered01.wav");
												case 7:
													Format(snd,sizeof(snd),"vo\\npc\\barneys\\leadtheway_sir02.wav");
											}
											if (strlen(snd) > 0)
											{
												EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											}
										}
										else if (StrEqual(cls,"npc_human_scientist",false))
										{
											switch (GetRandomInt(1,3))
											{
												case 1:
												{
													int rand = GetRandomInt(1,6);
													if (rand == 4) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\leadon04_take02.wav",rand);
													else Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\leadon0%i.wav",rand);
												}
												case 2:
													Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\leadtheway0%i.wav",GetRandomInt(1,4));
												case 3:
												{
													int rand = GetRandomInt(1,6);
													if (rand == 2) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\letsgo02_take02.wav");
													else if (rand == 6) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\letsgo06_take02.wav");
													else Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\letsgo0%i.wav",rand);
												}
											}
											if (strlen(snd) > 0)
											{
												EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											}
										}
										centnextsndtime[targ] = Time + 1.0;
									}
									if (strlen(snd) > 0)
									{
										EmitCC(targ,snd,768.0);
									}
								}
							}
							else if ((predis) && (centnextsndtime[targ] < Time))
							{
								char snd[64];
								if (StrEqual(cls,"npc_human_scientist",false))
								{
									int rand = GetRandomInt(1,43);
									if (rand < 10) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre0%i.wav",rand);
									else if (rand == 13) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre13_sp02_take02.wav");
									else if (rand < 26) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre%i.wav",rand);
									else if (rand == 26) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre26_sp02.wav");
									else if (rand == 27) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre27_sp02_take01.wav");
									else if (rand < 31) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre%i.wav",rand);
									else if (rand < 35) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre%i.wav",rand+3);
									else if (rand == 35) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre38_sp02.wav");
									else if (rand == 36) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre38_sp02_take02.wav");
									else if (rand == 37) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre40.wav");
									else if (rand == 38) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre43a.wav");
									else if (rand < 44) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\question_pre%i.wav",rand+5);
									EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									centnextsndtime[targ] = Time+5.0;
								}
								else if (StrEqual(cls,"npc_human_scientist_female",false))
								{
									int rand = GetRandomInt(1,5);
									switch(rand)
									{
										case 1:
											Format(snd,sizeof(snd),"vo\\npc\\scientist_female01\\question_pre04.wav");
										case 2:
											Format(snd,sizeof(snd),"vo\\npc\\scientist_female01\\question_pre11.wav");
										case 3:
											Format(snd,sizeof(snd),"vo\\npc\\scientist_female01\\question_pre13.wav");
										case 4:
											Format(snd,sizeof(snd),"vo\\npc\\scientist_female01\\question_pre22.wav");
										case 5:
											Format(snd,sizeof(snd),"vo\\npc\\scientist_female01\\question_pre40.wav");
									}
									EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									centnextsndtime[targ] = Time+5.0;
								}
								if (strlen(snd) > 0)
								{
									EmitCC(targ,snd,768.0);
								}
							}
						}
					}
				}
				else if ((StrContains(cls,"weapon_",false) == 0) && (FindStringInArray(customentlist,cls) != -1))
				{
					int owner = GetEntPropEnt(targ,Prop_Data,"m_hOwnerEntity");
					if (owner == -1)
					{
						if (chkdist < 100)
						{
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
										if (StrEqual(clschk,cls,false))
										{
											addweap = false;
											break;
										}
									}
								}
							}
							if (addweap)
							{
								orgs[2]+=20.0;
								TeleportEntity(targ,orgs,NULL_VECTOR,NULL_VECTOR);
								trigtp("OnPlayerPickup",targ,client,0.0);
							}
						}
					}
				}
			}
		}
	}
}

bool GetStateOf(char[] globalstate)
{
	if (GetArraySize(globalsarr) > 0)
	{
		for (int i = 0;i<GetArraySize(globalsarr);i++)
		{
			int j = GetArrayCell(globalsarr,i);
			if ((j != 0) && (IsValidEntity(j)))
			{
				if (HasEntProp(j,Prop_Data,"m_globalstate"))
				{
					char statechk[32];
					GetEntPropString(j,Prop_Data,"m_globalstate",statechk,sizeof(statechk));
					if (StrEqual(statechk,globalstate,false))
					{
						int state = GetEntProp(j,Prop_Data,"m_initialstate");
						if (state > 0) return true;
					}
				}
			}
		}
	}
	return false;
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

void findcontrolledtank(int ent, char[] cls, int client)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if (HasEntProp(thisent,Prop_Data,"m_hController"))
		{
			int controller = GetEntPropEnt(thisent,Prop_Data,"m_hController");
			if (controller == client)
			{
				int readytofire = GetEntProp(thisent,Prop_Data,"m_bReadyToFire");
				if (readytofire)
				{
					float Time = GetTickedTime();
					SetEntProp(thisent,Prop_Data,"m_bReadyToFire",0);
					char barrelfind[64];
					GetEntPropString(thisent,Prop_Data,"m_iszBarrelAttachment",barrelfind,sizeof(barrelfind));
					if (StrEqual(cls,"func_50cal",false))
					{
						float toang[3];
						//float angs[3];
						float orgs[3];
						int propanim = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
						if ((propanim != 0) && (IsValidEntity(propanim)))
						{
							//GetEntPropVector(propanim,Prop_Data,"m_angAbsRotation",angs);
							//GetEntPropVector(thisent,Prop_Data,"m_angAbsRotation",toang);
							//toang[0] = -1.0 * toang[0];
							GetClientEyeAngles(client,toang);
							//float posepitch = GetEntPropFloat(propanim,Prop_Data,"m_flPoseParameter",1);
							//angs[0] = (90.0*posepitch)-30.0;
							if (HasEntProp(propanim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(propanim,Prop_Data,"m_vecAbsOrigin",orgs);
							else if (HasEntProp(propanim,Prop_Send,"m_vecOrigin")) GetEntPropVector(propanim,Prop_Send,"m_vecOrigin",orgs);
							orgs[0] = (orgs[0] + (70 * Cosine(DegToRad(toang[1]))));
							orgs[1] = (orgs[1] + (70 * Sine(DegToRad(toang[1]))));
							orgs[2] = (orgs[2] + 20);
							int bulletmuzzle = CreateEntityByName("env_muzzleflash");
							if (bulletmuzzle != -1)
							{
								DispatchKeyValue(bulletmuzzle,"scale","0.8");
								TeleportEntity(bulletmuzzle,orgs,toang,NULL_VECTOR);
								DispatchSpawn(bulletmuzzle);
								ActivateEntity(bulletmuzzle);
								SetVariantString("!activator");
								AcceptEntityInput(bulletmuzzle,"SetParent",propanim);
								SetVariantString("muzzle");
								AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
								AcceptEntityInput(bulletmuzzle,"Fire");
								Handle dp2 = CreateDataPack();
								WritePackCell(dp2,bulletmuzzle);
								WritePackString(dp2,"env_muzzleflash");
								CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
							}
							float fhitpos[3];
							Handle hhitpos = INVALID_HANDLE;
							TR_TraceRayFilter(orgs,toang,MASK_SHOT,RayType_Infinite,TraceEntityFilter,propanim);
							TR_GetEndPosition(fhitpos,hhitpos);
							CloseHandle(hhitpos);
							float shootvel[3];
							MakeVectorFromPoints(orgs,fhitpos,shootvel);
							int orb = CreateEntityByName("generic_actor");
							if (orb != -1)
							{
								DispatchKeyValue(orb,"rendermode","10");
								DispatchKeyValue(orb,"renderfx","6");
								DispatchKeyValue(orb,"rendercolor","0 0 0");
								DispatchKeyValue(orb,"renderamt","0");
								DispatchKeyValue(orb,"solid","6");
								DispatchKeyValue(orb,"modelscale","0.1");
								DispatchKeyValue(orb,"model","models/roller.mdl");
								ScaleVector(shootvel,2.0);
								TeleportEntity(orb,orgs,toang,NULL_VECTOR);
								DispatchSpawn(orb);
								ActivateEntity(orb);
								SetEntProp(orb,Prop_Data,"m_MoveType",4);
								SetEntProp(orb,Prop_Data,"m_nRenderMode",10);
								SetEntProp(orb,Prop_Data,"m_nRenderFX",6);
								if (HasEntProp(orb,Prop_Data,"m_bloodColor")) SetEntProp(orb,Prop_Data,"m_bloodColor",3);
								if (HasEntProp(orb,Prop_Data,"m_hEffectEntity")) SetEntPropEnt(orb,Prop_Data,"m_hEffectEntity",controller);
								SDKHook(orb, SDKHook_StartTouch, StartTouchBullet);
								SetEntProp(orb,Prop_Data,"m_iHealth",300);
								SetEntProp(orb,Prop_Data,"m_iMaxHealth",30);
								TeleportEntity(orb,NULL_VECTOR,NULL_VECTOR,shootvel);
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\50cal\\single%i.wav",GetRandomInt(1,3));
								if ((bulletmuzzle != 0) && (IsValidEntity(bulletmuzzle))) EmitSoundToAll(snd, bulletmuzzle, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								else EmitSoundToAll(snd, propanim, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								Handle dp2 = CreateDataPack();
								WritePackCell(dp2,orb);
								WritePackString(dp2,"generic_actor");
								CreateTimer(2.0,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
								int silvertrail = CreateEntityByName("env_spritetrail");
								DispatchKeyValue(silvertrail,"lifetime","0.2");
								DispatchKeyValue(silvertrail,"startwidth","8.0");
								DispatchKeyValue(silvertrail,"endwidth","6.0");
								DispatchKeyValue(silvertrail,"spritename","sprites/bluelaser1.vmt");
								DispatchKeyValue(silvertrail,"renderamt","255");
								DispatchKeyValue(silvertrail,"rendermode","5");
								DispatchKeyValue(silvertrail,"rendercolor","50 35 35");
								TeleportEntity(silvertrail,orgs,toang,NULL_VECTOR);
								DispatchSpawn(silvertrail);
								ActivateEntity(silvertrail);
								SetVariantString("!activator");
								AcceptEntityInput(silvertrail,"SetParent",orb);
							}
						}
					}
					else if (StrEqual(cls,"func_tow",false))
					{
						if (centnextatk[thisent] < Time)
						{
							int propanim = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
							if ((propanim != 0) && (IsValidEntity(propanim)))
							{
								float angs[3];
								float orgs[3];
								int bulletmuzzle = CreateEntityByName("env_muzzleflash");
								if (bulletmuzzle != -1)
								{
									DispatchKeyValue(bulletmuzzle,"scale","1.0");
									DispatchSpawn(bulletmuzzle);
									ActivateEntity(bulletmuzzle);
									SetVariantString("!activator");
									AcceptEntityInput(bulletmuzzle,"SetParent",propanim);
									SetVariantString("muzzle");
									AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
									AcceptEntityInput(bulletmuzzle,"Fire");
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,bulletmuzzle);
									WritePackString(dp2,"env_muzzleflash");
									CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
									if (HasEntProp(bulletmuzzle,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(bulletmuzzle,Prop_Data,"m_vecAbsOrigin",orgs);
									else if (HasEntProp(bulletmuzzle,Prop_Send,"m_vecOrigin")) GetEntPropVector(bulletmuzzle,Prop_Send,"m_vecOrigin",orgs);
									GetEntPropVector(bulletmuzzle,Prop_Data,"m_angAbsRotation",angs);
								}
								int rpg = CreateEntityByName("rpg_missile");
								if (rpg != -1)
								{
									float loc[3];
									loc[0] = (orgs[0] + (20 * Cosine(DegToRad(angs[1]))));
									loc[1] = (orgs[1] + (20 * Sine(DegToRad(angs[1]))));
									loc[2] = (orgs[2]);
									TeleportEntity(rpg,loc,angs,NULL_VECTOR);
									DispatchSpawn(rpg);
									ActivateEntity(rpg);
									SetEntProp(rpg,Prop_Data,"m_MoveType",4);
									SetEntPropEnt(rpg,Prop_Data,"m_hOwnerEntity",controller);
									SetEntPropFloat(rpg,Prop_Data,"m_flDamage",300.0);
									centnextatk[thisent] = Time+5.0;
								}
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\tow\\single1.wav");
								if ((bulletmuzzle != 0) && (IsValidEntity(bulletmuzzle))) EmitSoundToAll(snd, bulletmuzzle, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								else EmitSoundToAll(snd, propanim, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
							}
						}
					}
				}
			}
		}
		findcontrolledtank(thisent++,cls,client);
	}
}

public Action EquipGluon(const char[] output, int caller, int activator, float delay)
{
	if ((activator > 0) && (activator < MaxClients+1) && (IsValidEntity(activator)))
	{
		trigtp("OnPlayerPickup",caller,-1,0.0);
		trigtp("OnPlayerUse",caller,-1,0.0);
		bool addweap = true;
		if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
		if (WeapList != -1)
		{
			char clschk[32];
			for (int l; l<104; l += 4)
			{
				int tmpi = GetEntDataEnt2(activator,WeapList + l);
				if ((tmpi != 0) && (IsValidEntity(tmpi)))
				{
					GetEntityClassname(tmpi,clschk,sizeof(clschk));
					if (StrEqual(clschk,"weapon_gluon",false)) addweap = false;
				}
			}
		}
		if (addweap)
		{
			AcceptEntityInput(caller,"kill");
			float orgs[3];
			float angs[3];
			if (HasEntProp(activator,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(activator,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(activator,Prop_Send,"m_vecOrigin")) GetEntPropVector(activator,Prop_Send,"m_vecOrigin",orgs);
			GetEntPropVector(activator,Prop_Data,"m_angAbsRotation",angs);
			int weap = CreateEntityByName("weapon_shotgun");
			if (weap != -1)
			{
				DispatchKeyValue(weap,"classname","weapon_gluon");
				TeleportEntity(weap,orgs,angs,NULL_VECTOR);
				DispatchSpawn(weap);
				ActivateEntity(weap);
				ClientCommand(activator,"use weapon_gluon");
			}
		}
	}
}

public int Native_GetCustomEntList(Handle plugin, int numParams)
{
	return view_as<int>(customentlist);
	//return _:customentlist;
}

public int Native_ReadCache(Handle plugin, int numParams)
{
	if ((numParams < 3) || (numParams > 3))
	{
		PrintToServer("Error: SynFixesReadCache must have three parameters. <client> <pathtocache> <spawnoffset>");
		return;
	}
	else
	{
		int client = GetNativeCell(1);
		char entcache[256];
		GetNativeString(2,entcache,sizeof(entcache));
		float offsetpos[3];
		GetNativeArray(3,offsetpos,3);
		
		if (!FileExists(entcache,true,NULL_STRING))
		{
			PrintToServer("SynFixesReadCache Error: Unable to find cache file %s",entcache);
			return;
		}
		else
		{
			readcache(client,entcache,offsetpos);
		}
	}
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

public Action customsoundchecksnorm(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (((StrContains(sample,"vo\\",false) == 0) || (StrContains(sample,"vo/",false) == 0) || (StrContains(sample,"*vo\\",false) == 0) || (StrContains(sample,"*vo/",false) == 0)) && ((StrContains(sample,"pain",false) == -1) && (StrContains(sample,"HG_ALERT",false) == -1) && (StrContains(sample,"breath",false) == -1)))
	{
		bool addsnd = true;
		if (GetArraySize(delayedspeech) > 0)
		{
			char snd[64];
			for (int j = 0;j<GetArraySize(delayedspeech);j++)
			{
				Handle dp = GetArrayCell(delayedspeech,j);
				if (dp != INVALID_HANDLE)
				{
					ResetPack(dp);
					ReadPackString(dp,snd,sizeof(snd));
					if (StrEqual(snd,sample,false))
					{
						addsnd = false;
						break;
					}
				}
			}
		}
		if (addsnd)
		{
			if (GetArraySize(delayedspeech) > 5) ClearArray(delayedspeech);
			Handle dp = CreateDataPack();
			centnextsndtime[entity] = GetTickedTime();
			WritePackString(dp,sample);
			WritePackCell(dp,entity);
			PushArrayCell(delayedspeech,dp);
			if (debuglvl == 3) PrintToServer("Added %s to delayed speech.",sample);
		}
	}
	if ((StrContains(sample,"vo\\",false) == 0) && (StrContains(mapbuf,"bms_bm_",false) != -1) && (IsValidEntity(entity)))
	{
		//int targent = -1;
		//int npcstate = 0;
		//if (HasEntProp(entity,Prop_Data,"m_NPCState")) npcstate = GetEntProp(entity,Prop_Data,"m_NPCState");
		//if (HasEntProp(entity,Prop_Data,"m_hTargetEnt")) targent = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
		//PrintToServer("VO %s from %i npcstate %i targent %i",sample,entity,npcstate,targent);
		EmitCC(entity,sample,1024.0);
		/*
		char passparam[128];
		Format(passparam,sizeof(passparam),"%s",sample);
		ReplaceString(passparam,sizeof(passparam),"\\","/");
		float choreopos[3];
		float clpos[3];
		if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",choreopos);
		else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",choreopos);
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i))
				{
					if (IsClientInGame(i))
					{
						QueryClientConVar(i,"closecaption",checkccsettings,0);
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",clpos);
						else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",clpos);
						float chkdist = GetVectorDistance(choreopos,clpos,false)
						if (chkdist < 1024.0)
						{
							if (showcc[i]) ClientCommand(i,"cc_emit %s",passparam);
						}
					}
				}
			}
		}
		*/
	}
	//Check SynDev+
	//Check func_door emitter m_NoiseMoving prevent future sounds until SingleEntityOutput OnFullyOpen/OnFullyClosed
	if (IsValidEntity(entity))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"func_door",false))
		{
			if (HasEntProp(entity,Prop_Data,"m_NoiseMoving"))
			{
				char doorsound[128];
				GetEntPropString(entity,Prop_Data,"m_NoiseMoving",doorsound,sizeof(doorsound));
				if (StrEqual(doorsound,sample,false))
				{
					if (flags == 0)
					{
						flags = SND_CHANGEVOL;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action customsoundchecks(char sample[PLATFORM_MAX_PATH], int& entity, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
	if ((StrContains(sample,"ambient/energy/zap",false) == -1) && (StrContains(sample,"alarm",false) == -1) && (StrContains(sample,"shotgun_fire",false) == -1) && (StrContains(sample,"smg1_fire1.wav",false) == -1) && (StrContains(sample,"music",false) != -1) && (!StrEqual(sample,"common/null.wav",false)) && (StrContains(sample,"env_headcrabcanister",false) == -1))
	{
		if (FindValueInArray(delayedsounds,entity) == -1)
		{
			PushArrayCell(delayedsounds,entity);
			centnextsndtime[entity] = GetTickedTime();
		}
	}
}

public void pushch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		int jstat = FindEntityByClassname(-1,"prop_vehicle_jeep");
		int jspawn = FindEntityByClassname(-1,"info_vehicle_spawn");
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

public void difficultych(Handle convar, const char[] oldValue, const char[] newValue)
{
	difficulty = StringToInt(newValue);
}

public void headgrpch(Handle convar, const char[] oldValue, const char[] newValue)
{
	headgroup = StringToInt(newValue);
}

public void plytrigch(Handle convar, const char[] oldValue, const char[] newValue)
{
	playercapadj = StringToInt(newValue);
}

public void antliongch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		antlionguardhard = true;
	else
		antlionguardhard = false;
}

public void incfixerch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		incfixer = true;
	else
		incfixer = false;
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

public void ep2reqch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		AutoFixEp2Req = true;
	else
		AutoFixEp2Req = false;
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

public void fixweapsndch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		FixWeapSnd = true;
	else
		FixWeapSnd = false;
}

public void fixsndscapech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		bFixSoundScapes = true;
	else
		bFixSoundScapes = false;
}

public void stuckinnpcch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		bFixNPCStuck = true;
	else
		bFixNPCStuck = false;
}

public void merchcurrencych(Handle convar, const char[] oldValue, const char[] newValue)
{
	iMerchantCType = StringToInt(newValue);
}

public void merchcurrencypropch(Handle convar, const char[] oldValue, const char[] newValue)
{
	Format(szMerchPropType,sizeof(szMerchPropType),"%s",newValue);
}

public void weaponrespawnch(Handle convar, const char[] oldValue, const char[] newValue)
{
	int iSetProp = -1;
	if (StringToInt(newValue) > 0)
	{
		iSetProp = 1;
	}
	else if (StringToInt(newValue) == 0)
	{
		iSetProp = 0;
	}
	if (iSetProp != -1)
	{
		int ent = -1;
		while((ent = FindEntityByClassname(ent,"weapon_*")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(ent))
			{
				if (HasEntProp(ent,Prop_Data,"m_hParent"))
				{
					if (GetEntPropEnt(ent,Prop_Data,"m_hParent") == -1)
					{
						if (HasEntProp(ent,Prop_Data,"m_iRespawnCount"))
						{
							if (iSetProp == 1) SetEntProp(ent,Prop_Data,"m_iRespawnCount",-1);
							else SetEntProp(ent,Prop_Data,"m_iRespawnCount",0);
						}
					}
				}
			}
		}
	}
}

public void longjumpmodech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		LongJumpMode = true;
	else
		LongJumpMode = false;
}

public void autorebuildch(Handle convar, const char[] oldValue, const char[] newValue)
{
	autorebuild = StringToInt(newValue);
}

public void rebuildnodeshch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		rebuildnodes = true;
	else
		rebuildnodes = false;
}

public void vortzapch(Handle convar, const char[] oldValue, const char[] newValue)
{
	slavezap = StringToInt(newValue);
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

public void sentryfireratech(Handle convar, const char[] oldValue, const char[] newValue)
{
	//StringToFloat more accuracy in specified value
	char iszNew[32];
	Format(iszNew,sizeof(iszNew),"%s",newValue);
	if (StrContains(iszNew,".",false) != -1) StrCat(iszNew,sizeof(iszNew),"00");
	flSentryFireRate = StringToFloat(iszNew);
}