#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <healthdisplay>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.91"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synswepsupdater.txt"

bool friendlyfire = false;
bool tauknockback = false;
int g_LastButtons[MAXPLAYERS+1];
int difficulty = 1;
int WeapList = -1;
int SL8Scope = -1;
int OICWScope = -1;
int clsummonfil = -1;
int CLManhackRel = -1;
int mdlus = -1;
int mdlus3 = -1;
int beamindx = -1;
int haloindx = -1;
int gluonbeam = -1;
int taubeam = -1;
int tauhl1beam = -1;
int tauhl2beam = -1;
int headgroup = 2;
int flareammo[MAXPLAYERS+1];
int ManHackAmmo[MAXPLAYERS+1];
int CGuardAmm[MAXPLAYERS+1];
int EnergyAmm[MAXPLAYERS+1];
int HiveAmm[MAXPLAYERS+1];
int SnarkAmm[MAXPLAYERS+1];
int SatchelAmm[MAXPLAYERS+1];
int TripMineAmm[MAXPLAYERS+1];
int Ammo3Reset[MAXPLAYERS+1];
int Ammo12Reset[MAXPLAYERS+1];
int Ammo24Reset[MAXPLAYERS+1];
int CLManhack[MAXPLAYERS+1];
int clsummontarg[MAXPLAYERS+1];
int EndTarg[MAXPLAYERS+1];
int HandAttach[MAXPLAYERS+1];
int TauCharge[MAXPLAYERS+1];
int CLInScope[MAXPLAYERS+1];
int CLAttachment[MAXPLAYERS+1];
float Healchk[MAXPLAYERS+1];
float MedkitAmm[MAXPLAYERS+1];
float centnextatk[MAXPLAYERS+1];
float clsummoncdc[MAXPLAYERS+1];
float antispamchk[MAXPLAYERS+1];
float WeapSnd[MAXPLAYERS+1];
float WeapAttackSpeed[MAXPLAYERS+1];
char SteamID[32][MAXPLAYERS+1];
char mapbuf[64];

Handle sweps = INVALID_HANDLE;
Handle precachedarr = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SynSweps",
	author = "Balimbanana",
	description = "Adds a few scripted weapons.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	sweps = CreateArray(32);
	precachedarr = CreateArray(32);
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	Handle cvar = FindConVar("sk_flaregun_ignighttime");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_flaregun_ignighttime", "10", "Time to ignight for.", _, true, 1.0, true, 99.0);
	cvar = FindConVar("sk_immolator_ignighttime");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_immolator_ignighttime", "10", "Time to ignight for.", _, true, 1.0, true, 99.0);
	cvar = FindConVar("sk_max_flaregun");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_flaregun", "20", "Maximum ammo for the flaregun.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_max_manhackgun");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_manhackgun", "3", "Maximum ammo for the manhack gun.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_max_energy");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_energy", "100", "Maximum ammo for the gluon and tau cannon.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_max_hivehand");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_max_hivehand", "100", "Maximum ammo for the hivehand.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_gluon");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_gluon", "30.0", "Damage per tick for the gluon gun.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_sl8");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_sl8", "8.0", "Damage for the SL8 weapon.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_oicw");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_oicw", "15.0", "Damage for the OICW.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_tau");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_tau", "20.0", "Damage for the Tau cannon.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_axe");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_axe", "20.0", "Damage for the FireAxe.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_m4");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_m4", "9.0", "Damage for the M4.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_g36c");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_g36c", "11.0", "Damage for the M4.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_tripmine_radius");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_tripmine_radius", "200", "Explosion radius of player tripmines.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_tripmine");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_tripmine", "150", "Explosion damage of player tripmines.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_satchel_radius");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_satchel_radius", "150", "Explosion radius of player satchels.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_satchel");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_satchel", "150", "Explosion damage of player satchels.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("sk_plr_dmg_glock");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sk_plr_dmg_glock", "20", "Damage for the glock.", _, true, 1.0, true, 999.0);
	cvar = FindConVar("syn_tauknockback");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_tauknockback", "0", "Enables knock back effect for players from Tau cannon charged shots.", _, true, 0.0, true, 1.0);
	tauknockback = GetConVarBool(cvar);
	HookConVarChange(cvar, tauknockch);
	cvar = FindConVar("sk_npc_head");
	if (cvar != INVALID_HANDLE)
	{
		headgroup = GetConVarInt(cvar);
		HookConVarChange(cvar, headgrpch);
	}
	cvar = FindConVar("mp_friendlyfire");
	if (cvar != INVALID_HANDLE)
	{
		friendlyfire = GetConVarBool(cvar);
		HookConVarChange(cvar, ffhch);
	}
	cvar = FindConVar("skill");
	if (cvar != INVALID_HANDLE)
	{
		difficulty = GetConVarInt(cvar);
		HookConVarChange(cvar, difficultych);
	}
	CloseHandle(cvar);
	CreateTimer(0.1, weaponticks, _, TIMER_REPEAT);
	CreateTimer(1.0, chkdisttargs, _, TIMER_REPEAT);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	RegConsoleCmd("dropweapon",dropcustweap);
	RegConsoleCmd("inventory",inventory);
	RegAdminCmd("sweps",sweplist,ADMFLAG_ROOT,"List of sweps.");
	//AddAmbientSoundHook(weapsoundchecks);
	//AddNormalSoundHook(weapnormsoundchecks);
	//HookUserMessage(GetUserMessageId("ItemPickup"),pickupusrmsg,true,_);
}

public void OnMapStart()
{
	GetCurrentMap(mapbuf,sizeof(mapbuf));
	ClearArray(sweps);
	ClearArray(precachedarr);
	PushArrayString(sweps,"weapon_flaregun");
	PushArrayString(sweps,"weapon_manhack");
	PushArrayString(sweps,"weapon_manhackgun");
	PushArrayString(sweps,"weapon_manhacktoss");
	PushArrayString(sweps,"weapon_immolator");
	PushArrayString(sweps,"weapon_cguard");
	PushArrayString(sweps,"weapon_medkit");
	PushArrayString(sweps,"weapon_hivehand");
	PushArrayString(sweps,"weapon_hornetgun");
	PushArrayString(sweps,"weapon_snark");
	PushArrayString(sweps,"weapon_satchel");
	PushArrayString(sweps,"weapon_tripmine");
	PushArrayString(sweps,"weapon_handgrenade");
	PushArrayString(sweps,"weapon_mp5");
	PushArrayString(sweps,"weapon_sl8");
	PushArrayString(sweps,"weapon_oicw");
	PushArrayString(sweps,"weapon_glock");
	PushArrayString(sweps,"weapon_gauss");
	PushArrayString(sweps,"weapon_tau");
	PushArrayString(sweps,"weapon_gluon");
	PushArrayString(sweps,"weapon_m4");
	PushArrayString(sweps,"weapon_axe");
	PushArrayString(sweps,"weapon_g36c");
	PushArrayString(sweps,"weapon_colt");
	PushArrayString(sweps,"weapon_dualmp5k");
	WeapList = -1;
	OICWScope = -1;
	SL8Scope = -1;
	clsummonfil = -1;
	CLManhackRel = -1;
	mdlus = PrecacheModel("effects/strider_pinch_dudv.vmt");
	mdlus3 = PrecacheModel("effects/strider_bulge_dudv.vmt");
	beamindx = PrecacheModel("sprites/bluelaser1.vmt");
	haloindx = PrecacheModel("sprites/blueshaft1.vmt");
	gluonbeam = PrecacheModel("effects/gluon_beam.vmt");
	taubeam = PrecacheModel("effects/tau_beam.vmt");
	tauhl1beam = PrecacheModel("sprites/smoke.vmt");
	tauhl2beam = PrecacheModel("sprites/laserbeam.vmt");
	for (int i = 1;i<MaxClients+1;i++)
	{
		MedkitAmm[i] = 0.0;
		Healchk[i] = 0.0;
		antispamchk[i] = 0.0;
		WeapSnd[i] = 0.0;
		WeapAttackSpeed[i] = 0.0;
		CLManhack[i] = 0;
		clsummontarg[i] = 0;
		EndTarg[i] = 0;
		HandAttach[i] = 0;
		TauCharge[i] = 0;
		CLInScope[i] = 0;
		CLAttachment[i] = 0;
		HiveAmm[i] = 0;
		SnarkAmm[i] = 0;
		SatchelAmm[i] = 0;
		TripMineAmm[i] = 0;
		Ammo3Reset[i] = 0;
		Ammo12Reset[i] = 0;
		Ammo24Reset[i] = 0;
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			CreateTimer(1.0,clspawnpost,i);
		}
	}
	if (FileExists("sound/weapons/flaregun/fire.wav",true,NULL_STRING)) PrecacheSound("weapons\\flaregun\\fire.wav",true);
	if (FileExists("sound/weapons/flaregun/flaregun_reload.wav",true,NULL_STRING)) PrecacheSound("weapons\\flaregun\\flaregun_reload.wav",true);
	if (FileExists("materials/models/HealthVial/plr_healthvial.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/HealthVial/plr_healthvial.vmt");
	if (FileExists("materials/models/HealthVial/plr_healthvial.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/HealthVial/plr_healthvial.vtf");
	if (FileExists("materials/models/weapons/V_FlareGun/flaregun_normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_FlareGun/flaregun_normal.vtf");
	if (FileExists("materials/models/weapons/V_FlareGun/flaregun_sheet.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_FlareGun/flaregun_sheet.vmt");
	if (FileExists("materials/models/weapons/V_FlareGun/flaregun_sheet.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_FlareGun/flaregun_sheet.vtf");
	if (FileExists("materials/models/weapons/W_FlareGun/w_flaregun.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_FlareGun/w_flaregun.vmt");
	if (FileExists("materials/models/weapons/W_FlareGun/w_flaregun.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_FlareGun/w_flaregun.vtf");
	if (FileExists("models/items/boxflares.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.dx80.vtx");
	if (FileExists("models/items/boxflares.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.dx90.vtx");
	if (FileExists("models/items/boxflares.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.mdl");
	if (FileExists("models/items/boxflares.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.phy");
	if (FileExists("models/items/boxflares.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.sw.vtx");
	if (FileExists("models/items/boxflares.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/items/boxflares.vvd");
	if (FileExists("models/weapons/v_flaregun.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.dx80.vtx");
	if (FileExists("models/weapons/v_flaregun.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.dx90.vtx");
	if (FileExists("models/weapons/v_flaregun.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.mdl");
	if (FileExists("models/weapons/v_flaregun.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.sw.vtx");
	if (FileExists("models/weapons/v_flaregun.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_flaregun.vvd");
	if (FileExists("models/weapons/v_medkit.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.dx80.vtx");
	if (FileExists("models/weapons/v_medkit.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.dx90.vtx");
	if (FileExists("models/weapons/v_medkit.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.mdl");
	if (FileExists("models/weapons/v_medkit.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.sw.vtx");
	if (FileExists("models/weapons/v_medkit.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_medkit.vvd");
	if (FileExists("models/weapons/W_FlareGun.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.dx80.vtx");
	if (FileExists("models/weapons/W_FlareGun.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.dx90.vtx");
	if (FileExists("models/weapons/w_flaregun.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_flaregun.mdl");
	if (FileExists("models/weapons/W_FlareGun.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.phy");
	if (FileExists("models/weapons/W_FlareGun.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_FlareGun.sw.vtx");
	if (FileExists("models/weapons/w_flaregun.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_flaregun.vvd");
	if (FileExists("models/weapons/W_medkitweap.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.dx80.vtx");
	if (FileExists("models/weapons/W_medkitweap.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.dx90.vtx");
	if (FileExists("models/weapons/w_medkitweap.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_medkitweap.mdl");
	if (FileExists("models/weapons/W_medkitweap.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.phy");
	if (FileExists("models/weapons/W_medkitweap.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/W_medkitweap.sw.vtx");
	if (FileExists("models/weapons/w_medkitweap.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_medkitweap.vvd");
	if (FileExists("models/weapons/v_sl8.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.dx80.vtx");
	if (FileExists("models/weapons/v_sl8.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.dx90.vtx");
	if (FileExists("models/weapons/v_sl8.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.mdl");
	if (FileExists("models/weapons/v_sl8.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.sw.vtx");
	if (FileExists("models/weapons/v_sl8.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_sl8.vvd");
	if (FileExists("models/weapons/w_sl8.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.dx80.vtx");
	if (FileExists("models/weapons/w_sl8.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.dx90.vtx");
	if (FileExists("models/weapons/w_sl8.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.mdl");
	if (FileExists("models/weapons/w_sl8.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.phy");
	if (FileExists("models/weapons/w_sl8.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.sw.vtx");
	if (FileExists("models/weapons/w_sl8.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_sl8.vvd");
	if (FileExists("materials/models/weapons/V_SL8/base.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/base.vmt");
	if (FileExists("materials/models/weapons/V_SL8/base.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/base.vtf");
	if (FileExists("materials/models/weapons/V_SL8/Base_Normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Base_Normal.vtf");
	if (FileExists("materials/models/weapons/V_SL8/Scope.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Scope.vmt");
	if (FileExists("materials/models/weapons/V_SL8/Scope.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Scope.vtf");
	if (FileExists("materials/models/weapons/V_SL8/Scope_Normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/V_SL8/Scope_Normal.vtf");
	if (FileExists("materials/models/weapons/W_SL8/wbase.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_SL8/wbase.vmt");
	if (FileExists("materials/models/weapons/W_SL8/wbase.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_SL8/wbase.vtf");
	if (FileExists("materials/models/weapons/W_SL8/wbase-n.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_SL8/wbase-n.vtf");
	if (FileExists("sound/weapons/SL8/sl8_boltback.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_boltback.wav");
	if (FileExists("sound/weapons/SL8/sl8_boltforward.wav.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_boltforward.wav.wav");
	if (FileExists("sound/weapons/SL8/sl8_magin.wav.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_magin.wav.wav");
	if (FileExists("sound/weapons/SL8/sl8_magout.wav.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/sl8_magout.wav.wav");
	if (FileExists("sound/weapons/SL8/SL8-1.wav.wav",true,NULL_STRING)) AddFileToDownloadsTable("sound/weapons/SL8/SL8-1.wav.wav");
	if (FileExists("materials/sprites/scope01.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/sprites/scope01.vtf");
	if (FileExists("materials/sprites/scope01.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/sprites/scope01.vmt");
	if (FileExists("materials/models/weapons/v_oicw/v_oicw_sheet.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/v_oicw/v_oicw_sheet.vmt");
	if (FileExists("materials/models/weapons/v_oicw/v_oicw_sheet.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/v_oicw/v_oicw_sheet.vtf");
	if (FileExists("materials/models/weapons/v_oicw/v_oicw_sheet_normal.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/v_oicw/v_oicw_sheet_normal.vtf");
	if (FileExists("materials/models/weapons/W_oicw/w_oicw.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_oicw/w_oicw.vmt");
	if (FileExists("materials/models/weapons/W_oicw/w_oicw.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/models/weapons/W_oicw/w_oicw.vtf");
	if (FileExists("materials/overlays/weapons/oicw/scope.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/overlays/weapons/oicw/scope.vtf");
	if (FileExists("materials/overlays/weapons/oicw/scope2.vtf",true,NULL_STRING)) AddFileToDownloadsTable("materials/overlays/weapons/oicw/scope2.vtf");
	if (FileExists("materials/overlays/weapons/oicw/scope_lens.vmt",true,NULL_STRING)) AddFileToDownloadsTable("materials/overlays/weapons/oicw/scope_lens.vmt");
	if (FileExists("models/weapons/v_oicw.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.dx80.vtx");
	if (FileExists("models/weapons/v_oicw.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.dx90.vtx");
	if (FileExists("models/weapons/v_oicw.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.mdl");
	if (FileExists("models/weapons/v_oicw.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.sw.vtx");
	if (FileExists("models/weapons/v_oicw.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/v_oicw.vvd");
	if (FileExists("models/weapons/w_oicw.dx80.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.dx80.vtx");
	if (FileExists("models/weapons/w_oicw.dx90.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.dx90.vtx");
	if (FileExists("models/weapons/w_oicw.mdl",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.mdl");
	if (FileExists("models/weapons/w_oicw.phy",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.phy");
	if (FileExists("models/weapons/w_oicw.sw.vtx",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.sw.vtx");
	if (FileExists("models/weapons/w_oicw.vvd",true,NULL_STRING)) AddFileToDownloadsTable("models/weapons/w_oicw.vvd");
	if (FileExists("scripts/weapon_flaregun.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_flaregun.txt");
	if (FileExists("scripts/weapon_medkit.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_medkit.txt");
	if (FileExists("scripts/weapon_sl8.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_sl8.txt");
	if (FileExists("scripts/weapon_oicw.txt",true,NULL_STRING)) AddFileToDownloadsTable("scripts/weapon_oicw.txt");
	findentlist(-1,"npc_*");
	findentlist(-1,"monster_*");
	findentlist(-1,"generic_actor");
	findentlist(-1,"monster_generic");
	findentlist(-1,"item_ammo*");
}

public Action sweplist(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	if (GetArraySize(sweps) > 0)
	{
		Menu menu = new Menu(MenuHandlerSweps);
		menu.SetTitle("Sweps");
		for (int i = 0;i<GetArraySize(sweps);i++)
		{
			char swep[64];
			GetArrayString(sweps,i,swep,sizeof(swep));
			char swepchk[72];
			Format(swepchk,sizeof(swepchk),"scripts/%s.txt",swep);
			if (FileExists(swepchk,true,NULL_STRING))
			{
				if (client == 0) PrintToServer("%s",swep);
				else
				{
					char weapclsren[64];
					Format(weapclsren,sizeof(weapclsren),"%s",swep);
					ReplaceStringEx(weapclsren,sizeof(weapclsren),"weapon_","");
					if (strlen(weapclsren) < 5)
					{
						for (int j = 0;j<strlen(weapclsren)+1;j++)
						{
							if (StringToInt(weapclsren[j]) == 0)
								weapclsren[j] &= ~(1 << 5);
						}
					}
					else
					{
						weapclsren[0] &= ~(1 << 5);
					}
					menu.AddItem(swep,weapclsren);
				}
			}
		}
		if (client != 0)
		{
			menu.ExitButton = true;
			menu.Display(client, 120);
		}
		else CloseHandle(menu);
	}
	return Plugin_Handled;
}

findentlist(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char classname[32];
		GetEntityClassname(thisent,classname,sizeof(classname));
		if ((StrEqual(classname,"item_ammo_flare_box",false)) || (StrEqual(classname,"item_box_flare_rounds",false)) || (StrEqual(classname,"item_ammo_manhack",false)) || (StrEqual(classname,"item_ammo_energy",false)))
		{
			SDKHookEx(thisent, SDKHook_StartTouch, StartTouchAmmoPickup);
		}
		else if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"prop_physics",false)) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"env_xen_portal",false)) && (!StrEqual(classname,"env_xen_portal_template",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)) && (StrContains(classname,"info_",false) == -1) && (StrContains(classname,"game_",false) == -1) && (StrContains(classname,"trigger_",false) == -1))
		{
			SDKHookEx(thisent, SDKHook_OnTakeDamage, OnNPCTakeDamage);
		}
		findentlist(thisent++,clsname);
	}
}

public Action OnNPCTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (HasEntProp(attacker,Prop_Data,"m_hOwnerEntity"))
	{
		int client = GetEntPropEnt(attacker,Prop_Data,"m_hOwnerEntity");
		if (IsValidEntity(client))
		{
			char clschk[32];
			GetEntityClassname(client,clschk,sizeof(clschk));
			if (StrEqual(clschk,"env_explosion",false))
			{
				client = GetEntPropEnt(client,Prop_Data,"m_hEffectEntity");
			}
		}
		if ((!IsValidEntity(client)) || (client > MaxClients) || (client == 0))
		{
			if ((attacker > 0) && (attacker < MaxClients+1)) client = attacker;
		}
		if ((client > 0) && (client < MaxClients+1))
		{
			char weapdmg[64];
			int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (weap != -1)
			{
				inflictor = weap;
				GetEntityClassname(weap,weapdmg,sizeof(weapdmg));
				if (FindStringInArray(sweps,weapdmg) != -1)
				{
					char clsname[64];
					GetEntityClassname(victim,clsname,sizeof(clsname));
					if (StrEqual(clsname,"generic_actor",false))
					{
						int parchk = GetEntPropEnt(victim,Prop_Data,"m_hParent");
						if (IsValidEntity(parchk))
						{
							victim = parchk;
							GetEntityClassname(victim,clsname,sizeof(clsname));
						}
					}
					if (CheckNPCAlly(clsname,victim))
					{
						damage = 0.0;
						return Plugin_Changed;
					}
					attacker = client;
					ReplaceStringEx(weapdmg,sizeof(weapdmg),"weapon_","sk_plr_dmg_");
					Handle cvar = FindConVar(weapdmg);
					if (cvar != INVALID_HANDLE)
					{
						damage = GetConVarFloat(cvar);
						float tkscale = 1.0;
						char scalechk[32];
						Format(scalechk,sizeof(scalechk),"sk_dmg_inflict_scale%i",difficulty);
						Handle scaleh = FindConVar(scalechk);
						if (scaleh != INVALID_HANDLE) tkscale = GetConVarFloat(scaleh);
						CloseHandle(scaleh);
						damage = damage/tkscale;
						if (StrEqual(weapdmg,"sk_plr_dmg_tau",false))
						{
							if (TauCharge[client] > 1)
							{
								damage = damage*(1.0+TauCharge[client]/2);
							}
							damagetype = 256;
						}
						else if (StrEqual(weapdmg,"sk_plr_dmg_gluon",false))
						{
							damagetype = 1024;
						}
					}
					CloseHandle(cvar);
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	int killed = GetEventInt(event, "entindex_killed");
	if ((killed > 0) && (killed < MaxClients+1))
	{
		FindStrayWeaps(-1,killed);
	}
}

public tauknockch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) tauknockback = true;
	else tauknockback = false;
}

public headgrpch(Handle convar, const char[] oldValue, const char[] newValue)
{
	headgroup = StringToInt(newValue);
}

public ffhch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) friendlyfire = true;
	else friendlyfire = false;
}

public difficultych(Handle convar, const char[] oldValue, const char[] newValue)
{
	difficulty = StringToInt(newValue);
}

FindStrayWeaps(int ent, int client)
{
	int thisent = FindEntityByClassname(ent,"weapon_*");
	if ((IsValidEntity(thisent)) && (thisent != 0))
	{
		if (HasEntProp(thisent,Prop_Data,"m_hParent"))
		{
			int parentchk = GetEntPropEnt(thisent,Prop_Data,"m_hParent");
			if (parentchk == client) AcceptEntityInput(thisent,"ClearParent");
		}
		FindStrayWeaps(thisent++,client);
	}
}

public OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public OnEntityCreated(int entity, const char[] classname)
{
	if ((StrContains(classname,"item_ammo",false) == 0) || (StrContains(classname,"weapon_",false) == 0))
	{
		CreateTimer(0.5,waititem,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"env_xen_portal",false)) && (!StrEqual(classname,"env_xen_portal_template",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)) && (StrContains(classname,"info_",false) == -1) && (StrContains(classname,"game_",false) == -1) && (StrContains(classname,"trigger_",false) == -1))
	{
		SDKHookEx(entity, SDKHook_OnTakeDamage, OnNPCTakeDamage);
	}
}

public void OnEntityDestroyed(int entity)
{
	SDKUnhook(entity, SDKHook_OnTakeDamage, OnNPCTakeDamage);
}

public Action inventory(int client, int args)
{
	if (IsValidEntity(client))
	{
		if (IsPlayerAlive(client))
		{
			Menu menu = new Menu(MenuHandler);
			menu.SetTitle("Inventory");
			if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
			if (WeapList != -1)
			{
				for (int j; j<104; j += 4)
				{
					int tmpi = GetEntDataEnt2(client,WeapList + j);
					if (tmpi != -1)
					{
						char weapcls[64];
						GetEntityClassname(tmpi,weapcls,sizeof(weapcls));
						char weapclsren[64];
						Format(weapclsren,sizeof(weapclsren),"%s",weapcls);
						ReplaceStringEx(weapclsren,sizeof(weapclsren),"weapon_","");
						if (strlen(weapclsren) < 5)
						{
							for (int i = 0;i<strlen(weapclsren)+1;i++)
							{
								if (StringToInt(weapclsren[i]) == 0)
									weapclsren[i] &= ~(1 << 5);
							}
						}
						else
						{
							weapclsren[0] &= ~(1 << 5);
						}
						menu.AddItem(weapcls,weapclsren);
					}
				}
			}
			menu.ExitButton = true;
			menu.Display(client, 120);
		}
	}
	return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (IsValidEntity(param1)))
	{
		if (IsPlayerAlive(param1))
		{
			char info[128];
			menu.GetItem(param2, info, sizeof(info));
			if (strlen(info) > 0)
			{
				ClientCommand(param1,"use %s",info);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlerSweps(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (IsValidEntity(param1)))
	{
		if (IsPlayerAlive(param1))
		{
			char info[128];
			menu.GetItem(param2, info, sizeof(info));
			if (strlen(info) > 0)
			{
				char weapscr[72];
				Format(weapscr,sizeof(weapscr),"scripts/%s.txt",info);
				if (FileExists(weapscr,true,NULL_STRING))
				{
					char basecls[32];
					if (StrEqual(info,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
					else if (StrEqual(info,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
					else if ((StrEqual(info,"weapon_glock",false)) || (StrEqual(info,"weapon_pistol_worker",false)) || (StrEqual(info,"weapon_flaregun",false)) || (StrEqual(info,"weapon_manhack",false)) || (StrEqual(info,"weapon_manhackgun",false)) || (StrEqual(info,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
					else if ((StrEqual(info,"weapon_medkit",false)) || (StrEqual(info,"weapon_snark",false)) || (StrEqual(info,"weapon_hivehand",false)) || (StrEqual(info,"weapon_hornetgun",false)) || (StrEqual(info,"weapon_satchel",false)) || (StrEqual(info,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
					else if ((StrEqual(info,"weapon_mp5",false)) || (StrEqual(info,"weapon_m4",false)) || (StrEqual(info,"weapon_sl8",false)) || (StrEqual(info,"weapon_g36c",false)) || (StrEqual(info,"weapon_oicw",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
					else if ((StrEqual(info,"weapon_gauss",false)) || (StrEqual(info,"weapon_tau",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
					else if (StrEqual(info,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
					else if (StrEqual(info,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
					int ent = CreateEntityByName(basecls);
					if (ent != -1)
					{
						float clorigin[3];
						GetClientAbsOrigin(param1,clorigin);
						clorigin[2]+=20.0;
						TeleportEntity(ent,clorigin,NULL_VECTOR,NULL_VECTOR);
						DispatchKeyValue(ent,"classname",info);
						DispatchSpawn(ent);
						ActivateEntity(ent);
						Handle dp = CreateDataPack();
						WritePackCell(dp,param1);
						WritePackString(dp,info);
						CreateTimer(0.1,useweap,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else
				{
					PrintToChat(param1,"Cannot spawn this swep. Most likely not currently mounted.");
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action useweap(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		char weap[64];
		ResetPack(dp);
		int client = ReadPackCell(dp);
		ReadPackString(dp,weap,sizeof(weap));
		CloseHandle(dp);
		if ((strlen(weap) > 0) && (IsValidEntity(client)))
		{
			ClientCommand(client,"use %s",weap);
		}
	}
}

public Action dropcustweap(int client, int args)
{
	int weapdrop = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
	if ((weapdrop != 0) && (IsValidEntity(weapdrop)))
	{
		char weapcls[64];
		GetEntityClassname(weapdrop,weapcls,sizeof(weapcls));
		if (FindStringInArray(sweps,weapcls) != -1)
		{
			if (HasEntProp(weapdrop,Prop_Data,"m_fEffects")) SetEntProp(weapdrop,Prop_Data,"m_fEffects",128);
			if (HasEntProp(weapdrop,Prop_Send,"m_fEffects")) SetEntProp(weapdrop,Prop_Send,"m_fEffects",128);
			if (HasEntProp(weapdrop,Prop_Data,"m_nViewModelIndex")) SetEntProp(weapdrop,Prop_Data,"m_nViewModelIndex",0);
			if (HasEntProp(weapdrop,Prop_Data,"m_usSolidFlags")) SetEntProp(weapdrop,Prop_Data,"m_usSolidFlags",136);
			SetEntityMoveType(weapdrop,MOVETYPE_VPHYSICS);
			AcceptEntityInput(weapdrop,"ClearParent");
		}
	}
	return Plugin_Continue;
}

public Action weaponticks(Handle timer)
{
	if (GetClientCount(false))
	{
		float Time = GetTickedTime();
		for (int client = 1;client<MaxClients+1;client++)
		{
			if (IsValidEntity(client))
			{
				if ((IsClientInGame(client)) && (IsPlayerAlive(client)))
				{
					char curweap[24];
					GetClientWeapon(client,curweap,sizeof(curweap));
					int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
					int useent = GetEntPropEnt(client,Prop_Data,"m_hUseEntity");
					if ((vehicle == -1) && (useent == -1) && (FindStringInArray(sweps,curweap) != -1))
					{
						if ((StrEqual(curweap,"weapon_medkit",false)) && (MedkitAmm[client] <= Time))
						{
							int medkitammo = GetEntProp(client,Prop_Data,"m_iHealthPack");
							if (medkitammo < 100)
							{
								if (medkitammo+5 < 100) SetEntProp(client,Prop_Data,"m_iHealthPack",medkitammo+5);
								else SetEntProp(client,Prop_Data,"m_iHealthPack",100);
								ChangeEdictState(client);
							}
							MedkitAmm[client] = Time+1.0;
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if ((StrContains(curweap,"weapon_manhack",false) == 0) || (StrEqual(curweap,"weapon_cguard",false)) || (StrEqual(curweap,"weapon_gauss",false)))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if (StrEqual(curweap,"weapon_gluon",false))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 3)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
						else if (StrEqual(curweap,"weapon_tau",false))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							float idletime = GetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle");
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",idletime+0.1);
							ChangeEdictState(weap);
							if ((idletime > 1.0) && (centnextatk[client] < Time))
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if ((seq < 4) && (seq > 0))
									{
										int rand = GetRandomInt(1,3);
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
										if (rand == 3) centnextatk[client] = Time+GetRandomFloat(6.0,10.0);
										else centnextatk[client] = Time+GetRandomFloat(1.0,4.0);
									}
									else if (seq > 10)
									{
										int rand = GetRandomInt(1,3);
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									}
								}
							}
						}
						else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							float idletime = GetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle");
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",idletime+0.1);
							ChangeEdictState(weap);
							if ((idletime > 10.0) && (idletime < 10.2))
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if ((seq != 3) && (seq != 4))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
										CreateTimer(1.0,resetviewmdl,viewmdl);
									}
								}
							}
							if (idletime > 1.0)
							{
								int maxhivehand = 100;
								Handle cvar = FindConVar("sk_max_hivehand");
								if (cvar != INVALID_HANDLE) maxhivehand = GetConVarInt(cvar);
								CloseHandle(cvar);
								if (GetEntProp(weap,Prop_Data,"m_iClip1") < maxhivehand)
								{
									HiveAmm[client]++;
									SetEntProp(weap,Prop_Data,"m_iClip1",HiveAmm[client]);
								}
							}
						}
						else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							if (weap != -1)
							{
								int mdlseq = 2;
								int lowerseq = 7;
								int maxclip = 30;
								char snd[64];
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
								{
									mdlseq = 3;
									maxclip = 50;
								}
								else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
								{
									mdlseq = 7;
									Format(snd,sizeof(snd),"weapons\\m4\\m4_reload.wav");
								}
								else if (StrEqual(curweap,"weapon_g36c",false))
								{
									mdlseq = 9;
									Format(snd,sizeof(snd),"weapons\\g36c\\g36c_reload.wav");
								}
								else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
								{
									mdlseq = 9;
									Format(snd,sizeof(snd),"weapons\\mp5\\mp5_reload.wav");
								}
								else
								{
									Format(snd,sizeof(snd),"weapons\\mp5\\reload.wav");
								}
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (inreload))
								{
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq != mdlseq)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
											if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
								}
								else if (!inreload)
								{
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if ((seq == mdlseq) || (seq == lowerseq))
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										}
									}
								}
								StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_sl8",false))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							if (weap != -1)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
								int mdlseq = 2;
								int maxclip = 20;
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								SetEntPropFloat(weap,Prop_Data,"m_fFireDuration",0.0);
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (inreload))
								{
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq != mdlseq)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
											StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
											if (FileExists("sound/weapons/sl8/sl8_magout.wav",true,NULL_STRING))
											{
												char snd[64];
												Format(snd,sizeof(snd),"weapons\\sl8\\sl8_magout.wav");
												EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
												CreateTimer(0.6,resetviewmdl,viewmdl);
											}
										}
									}
								}
								else if (!inreload)
								{
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq == 1)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										}
									}
								}
								StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_oicw",false))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							if (weap != -1)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
								int mdlseq = 5;
								int maxclip = 30;
								int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
								SetEntPropFloat(weap,Prop_Data,"m_fFireDuration",0.0);
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (inreload))
								{
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq != mdlseq)
										{
											SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
											if (FileExists("sound/weapons/oicw/oicw_reload.wav",true,NULL_STRING))
											{
												char snd[64];
												Format(snd,sizeof(snd),"weapons\\oicw\\oicw_reload.wav");
												EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
												CreateTimer(2.3,resetviewmdl,viewmdl);
												SetEntProp(weap,Prop_Data,"m_bInReload",1);
											}
										}
									}
								}
								else if (!inreload)
								{
									int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
									if (viewmdl != -1)
									{
										int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
										if (seq == 5)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
										}
										else if (seq == 9)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
										}
									}
								}
								StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
							}
						}
						else if (StrEqual(curweap,"weapon_glock",false))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							if (weap != -1)
							{
								int maxclip = 17;
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int mdlseq = 0;
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									char snd[64];
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										mdlseq = 5;
										Format(snd,sizeof(snd),"weapons\\reload%i.wav",GetRandomInt(1,3));
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										maxclip = 15;
										mdlseq = 9;
										Format(snd,sizeof(snd),"weapons\\pistol\\glock_reload1.wav");
									}
									else
									{
										Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
									}
									if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (GetEntProp(weap,Prop_Data,"m_bInReload") == 1))
									{
										if (((seq != 6) && (seq != 7)) && ((mdlseq != 0) && (seq != mdlseq)))
										{
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											if (mdlseq != 0) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
											else SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(6,7));
											if (strlen(snd) > 0)
											{
												EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
											}
										}
									}
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										if (seq == 8) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										if (seq == 10) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
									}
									else
									{
										if (seq == 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
									}
								}
							}
						}
						else if (StrEqual(curweap,"weapon_flaregun",false))
						{
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							if (weap != -1)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
									SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
									ChangeEdictState(weap);
									if (seq == 4) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
						else if (StrEqual(curweap,"weapon_tripmine",false))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 7) SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
							}
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if (StrEqual(curweap,"weapon_satchel",false))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
							}
							int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
							SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
							SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+100.0);
							ChangeEdictState(weap);
						}
						else if (StrEqual(curweap,"weapon_snark",false))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
								float idletime = GetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle");
								SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",idletime+0.1);
								if ((seq == 6) && (SnarkAmm[client] > 0)) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								else if (((seq <= 2) || (seq >= 10)) && (idletime > 14.0))
								{
									if (IsValidEntity(weap))
									{
										int rand = GetRandomInt(1,3);
										if (rand == 3) rand = GetRandomInt(10,15);
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
										if (rand != 12) SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",GetRandomFloat(8.0,12.0));
										else SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
									}
								}
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
								ChangeEdictState(weap);
							}
						}
						else if (StrEqual(curweap,"weapon_colt",false))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
								int maxclip = 8;
								if ((GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip) && (GetEntProp(weap,Prop_Data,"m_bInReload") == 1))
								{
									int mdlseq = 4;
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									}
								}
							}
						}
						else if (StrEqual(curweap,"weapon_dualmp5k",false))
						{
							
						}
					}
				}
			}
		}
	}
}

public Action waititem(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		if (IsEntNetworkable(entity))
		{
			char cls[32];
			GetEntityClassname(entity,cls,sizeof(cls));
			if ((StrEqual(cls,"item_ammo_flare_box",false)) || (StrEqual(cls,"item_box_flare_rounds",false)) || (StrEqual(cls,"item_ammo_manhack",false)) || (StrEqual(cls,"item_ammo_energy",false)))
			{
				SDKHook(entity, SDKHook_StartTouch, StartTouchAmmoPickup);
			}
			else if (FindStringInArray(sweps,cls) != -1)
			{
				HookSingleEntityOutput(entity,"OnCacheInteraction",EntityOutput:SweapCacheInteraction);
			}
			if ((StrEqual(cls,"weapon_satchel",false)) || (StrEqual(cls,"weapon_tripmine",false)))
			{
				SDKHook(entity, SDKHook_StartTouch, StartTouchAmmoPickup);
			}
		}
	}
}

public Action SweapCacheInteraction(const char[] output, int caller, int activator, float delay)
{
	if (HasEntProp(caller,Prop_Data,"m_iRespawnCount"))
	{
		int respawns = GetEntProp(caller,Prop_Data,"m_iRespawnCount");
		if (respawns != 0)
		{
			char cls[32];
			char basecls[32];
			GetEntityClassname(caller,cls,sizeof(cls));
			float orgs[3];
			float angs[3];
			if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",orgs);
			if (StrEqual(cls,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
			else if ((StrEqual(cls,"weapon_glock",false)) || (StrEqual(cls,"weapon_colt",false)) || (StrEqual(cls,"weapon_pistol_worker",false)) || (StrEqual(cls,"weapon_flaregun",false)) || (StrEqual(cls,"weapon_manhack",false)) || (StrEqual(cls,"weapon_manhackgun",false)) || (StrEqual(cls,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
			else if ((StrEqual(cls,"weapon_medkit",false)) || (StrEqual(cls,"weapon_snark",false)) || (StrEqual(cls,"weapon_hivehand",false)) || (StrEqual(cls,"weapon_hornetgun",false)) || (StrEqual(cls,"weapon_satchel",false)) || (StrEqual(cls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
			else if ((StrEqual(cls,"weapon_mp5",false)) || (StrEqual(cls,"weapon_m4",false)) || (StrEqual(cls,"weapon_sl8",false)) || (StrEqual(cls,"weapon_g36c",false)) || (StrEqual(cls,"weapon_oicw",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
			else if ((StrEqual(cls,"weapon_gauss",false)) || (StrEqual(cls,"weapon_tau",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
			else if (StrEqual(cls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
			else if (StrEqual(cls,"weapon_dualmp5k",false)) Format(basecls,sizeof(basecls),"weapon_mp5k");
			else if (StrEqual(cls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
			int respawnweap = CreateEntityByName(basecls);
			if (respawnweap != -1)
			{
				DispatchKeyValue(respawnweap,"classname",cls);
				TeleportEntity(respawnweap,orgs,angs,NULL_VECTOR);
				DispatchSpawn(respawnweap);
				ActivateEntity(respawnweap);
			}
		}
	}
	return Plugin_Continue;
}

public Action StartTouchAmmoPickup(int entity, int other)
{
	if ((IsValidEntity(entity)) && (IsValidEntity(other)) && (other != 0) && (entity != 0))
	{
		if ((other > 0) && (other < MaxClients+1))
		{
			char cls[32];
			GetEntityClassname(entity,cls,sizeof(cls));
			if ((StrEqual(cls,"item_ammo_flare_box",false)) || (StrEqual(cls,"item_box_flare_rounds",false)))
			{
				Handle cvar = FindConVar("sk_max_flaregun");
				int maxamm = GetConVarInt(cvar);
				CloseHandle(cvar);
				if (flareammo[other] < maxamm)
				{
					if (flareammo[other]+5 < maxamm)
					{
						flareammo[other]+=5;
					}
					else
					{
						flareammo[other] = maxamm;
					}
					EmitGameSoundToAll("HL2Player.PickupWeapon",other);
					Handle pickuph = StartMessageOne("ItemPickup",other);
					BfWriteString(pickuph,"item_ammo_pistol");
					EndMessage();
					AcceptEntityInput(entity,"kill");
				}
			}
			else if (StrEqual(cls,"item_ammo_manhack",false))
			{
				Handle cvar = FindConVar("sk_max_manhackgun");
				int maxamm = GetConVarInt(cvar);
				CloseHandle(cvar);
				if (ManHackAmmo[other] < maxamm)
				{
					if (ManHackAmmo[other]+2 < maxamm)
					{
						ManHackAmmo[other]+=2;
					}
					else
					{
						ManHackAmmo[other] = maxamm;
					}
					EmitGameSoundToAll("HL2Player.PickupWeapon",other);
					Handle pickuph = StartMessageOne("ItemPickup",other);
					BfWriteString(pickuph,"item_ammo_pistol");
					EndMessage();
					AcceptEntityInput(entity,"kill");
				}
			}
			else if (StrEqual(cls,"item_ammo_energy",false))
			{
				Handle cvar = FindConVar("sk_max_energy");
				int maxamm = GetConVarInt(cvar);
				CloseHandle(cvar);
				if (EnergyAmm[other] < maxamm)
				{
					if (EnergyAmm[other]+20 < maxamm)
					{
						EnergyAmm[other]+=20;
					}
					else
					{
						EnergyAmm[other] = maxamm;
					}
					EmitGameSoundToAll("HL2Player.PickupWeapon",other);
					Handle pickuph = StartMessageOne("ItemPickup",other);
					BfWriteString(pickuph,"item_ammo_energy");
					EndMessage();
					int weap = GetEntPropEnt(other,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						char weapcls[24];
						GetEntityClassname(weap,weapcls,sizeof(weapcls));
						if ((StrEqual(weapcls,"weapon_gluon",false)) || (StrEqual(weapcls,"weapon_tau",false)))
						{
							if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[other]);
							if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[other]);
						}
					}
					AcceptEntityInput(entity,"kill");
				}
			}
			else if (StrEqual(cls,"weapon_satchel",false))
			{
				if (HasWeapon(other,cls))
				{
					int maxamm = 10;
					Handle cvar = FindConVar("sk_max_satchel");
					if (cvar != INVALID_HANDLE) maxamm = GetConVarInt(cvar);
					CloseHandle(cvar);
					if (SatchelAmm[other] < maxamm)
					{
						SatchelAmm[other]++;
						EmitGameSoundToAll("HL2Player.PickupWeapon",other);
						int weap = GetEntPropEnt(other,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							char weapcls[24];
							GetEntityClassname(weap,weapcls,sizeof(weapcls));
							if (StrEqual(weapcls,"weapon_satchel",false))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",SatchelAmm[other]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",SatchelAmm[other]);
							}
						}
						AcceptEntityInput(entity,"kill");
					}
				}
			}
			else if (StrEqual(cls,"weapon_tripmine",false))
			{
				if (HasWeapon(other,cls))
				{
					int maxamm = 10;
					Handle cvar = FindConVar("sk_max_tripmine");
					if (cvar != INVALID_HANDLE) maxamm = GetConVarInt(cvar);
					CloseHandle(cvar);
					if (TripMineAmm[other] < maxamm)
					{
						TripMineAmm[other]++;
						EmitGameSoundToAll("HL2Player.PickupWeapon",other);
						int weap = GetEntPropEnt(other,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							char weapcls[24];
							GetEntityClassname(weap,weapcls,sizeof(weapcls));
							if (StrEqual(weapcls,"weapon_tripmine",false))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",TripMineAmm[other]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",TripMineAmm[other]);
							}
						}
						AcceptEntityInput(entity,"kill");
					}
				}
			}
		}
	}
}

public Action StartTouchFlare(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(activator))
	{
		char clsname[64];
		GetEntityClassname(activator,clsname,sizeof(clsname));
		if (!CheckNPCAlly(clsname,activator))
		{
			int client = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if (client == -1) client = caller;
			char flareduration[8];
			Format(flareduration,sizeof(flareduration),"10");
			Handle cvar = FindConVar("sk_flaregun_ignighttime");
			if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
			CloseHandle(cvar);
			SetVariantString(flareduration);
			AcceptEntityInput(activator,"Ignite",client);
			float dmgset = 10.0;
			float damageForce[3];
			float curorg[3];
			GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",curorg);
			SDKHooks_TakeDamage(activator,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
		}
		else if (StrEqual(clsname,"prop_physics",false))
		{
			char mdl[64];
			GetEntPropString(activator,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrContains(mdl,"wood_",false) != -1)
			{
				int client = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
				if (client == -1) client = caller;
				char flareduration[8];
				Format(flareduration,sizeof(flareduration),"10");
				Handle cvar = FindConVar("sk_flaregun_ignighttime");
				if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
				CloseHandle(cvar);
				SetVariantString(flareduration);
				AcceptEntityInput(activator,"Ignite",client);
				float dmgset = 10.0;
				float damageForce[3];
				float curorg[3];
				GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",curorg);
				SDKHooks_TakeDamage(activator,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
			}
		}
	}
}

public Action StartTouchFlaretch(int entity, int other)
{
	if ((IsValidEntity(entity)) && (IsValidEntity(other)) && (other != 0) && (entity != 0))
	{
		char clsname[64];
		GetEntityClassname(other,clsname,sizeof(clsname));
		if (!CheckNPCAlly(clsname,other))
		{
			int client = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			if (client == -1) client = entity;
			char flareduration[8];
			Format(flareduration,sizeof(flareduration),"10");
			Handle cvar = FindConVar("sk_flaregun_ignighttime");
			if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
			CloseHandle(cvar);
			SetVariantString(flareduration);
			AcceptEntityInput(other,"Ignite",client);
			float dmgset = 10.0;
			float damageForce[3];
			float curorg[3];
			GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
			SDKHooks_TakeDamage(other,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
		}
		else if (StrEqual(clsname,"prop_physics",false))
		{
			char mdl[64];
			GetEntPropString(other,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (StrContains(mdl,"wood_",false) != -1)
			{
				int client = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
				if (client == -1) client = entity;
				char flareduration[8];
				Format(flareduration,sizeof(flareduration),"10");
				Handle cvar = FindConVar("sk_flaregun_ignighttime");
				if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
				CloseHandle(cvar);
				SetVariantString(flareduration);
				AcceptEntityInput(other,"Ignite",client);
				float dmgset = 10.0;
				float damageForce[3];
				float curorg[3];
				GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				SDKHooks_TakeDamage(other,client,client,dmgset,DMG_BURN,-1,damageForce,curorg);
			}
		}
	}
}

public OnClientDisconnect_Post(int client)
{
	g_LastButtons[client] = 0;
	MedkitAmm[client] = 0.0;
	Healchk[client] = 0.0;
	CLManhack[client] = 0;
	clsummontarg[client] = 0;
	EndTarg[client] = 0;
	HandAttach[client] = 0;
	TauCharge[client] = 0;
	CLInScope[client] = 0;
	CLAttachment[client] = 0;
	clsummoncdc[client] = 0.0;
	WeapSnd[client] = 0.0;
	WeapAttackSpeed[client] = 0.0;
	SteamID[client] = "";
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	bool setbuttons = true;
	char curweap[24];
	GetClientWeapon(client,curweap,sizeof(curweap));
	int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
	int useent = GetEntPropEnt(client,Prop_Data,"m_hUseEntity");
	if ((vehicle == -1) && (useent == -1))
	{
		if (buttons & IN_ATTACK)
		{
			if (!(g_LastButtons[client] & IN_ATTACK))
			{
				if (StrEqual(curweap,"weapon_immolator",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (IsValidEntity(weap))
					{
						if (HasEntProp(weap,Prop_Data,"m_flNextPrimaryAttack"))
						{
							float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
							if (centnextatk[client] < nextatk)
							{
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",nextatk-0.1);
								centnextatk[client] = nextatk+0.05;
								//create fireball sprite moving from cl with cone
								//check collision dist from sprite, remove when out of world or timer
							}
							setbuttons = false;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_flaregun",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if ((GetEntProp(weap,Prop_Data,"m_iClip1") > 0) && (WeapAttackSpeed[client] < Time))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 1;
								char mdl[64];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (!StrEqual(mdl,"models/weapons/v_flaregun.mdl",false))
									mdlseq = 2;
								if (seq != mdlseq)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",GetEntProp(weap,Prop_Data,"m_iClip1")-1);
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									ChangeEdictState(viewmdl);
									CreateTimer(0.6,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
									int flare = CreateEntityByName("env_flare");
									if (flare != -1)
									{
										float plyfirepos[3];
										float plyang[3];
										GetClientEyeAngles(client,plyang);
										GetClientEyePosition(client,plyfirepos);
										char flareduration[8];
										Format(flareduration,sizeof(flareduration),"10");
										Handle cvar = FindConVar("sk_flaregun_ignighttime");
										if (cvar != INVALID_HANDLE) GetConVarString(cvar,flareduration,sizeof(flareduration));
										CloseHandle(cvar);
										DispatchKeyValue(flare,"duration",flareduration);
										TeleportEntity(flare,plyfirepos,plyang,NULL_VECTOR);
										DispatchSpawn(flare);
										ActivateEntity(flare);
										SetVariantString("900 0 10");
										AcceptEntityInput(flare,"Launch");
										int flarebox = CreateEntityByName("trigger_multiple");
										if (flarebox != -1)
										{
											DispatchKeyValue(flarebox,"spawnflags","66");
											DispatchKeyValue(flarebox,"wait","1");
											if (!IsModelPrecached("*1")) PrecacheModel("*1",true);
											DispatchKeyValue(flarebox,"model","*1");
											TeleportEntity(flarebox,plyfirepos,plyang,NULL_VECTOR);
											DispatchSpawn(flarebox);
											ActivateEntity(flarebox);
											SetVariantString("!activator");
											AcceptEntityInput(flarebox,"SetParent",flare);
											HookSingleEntityOutput(flarebox,"OnTrigger",EntityOutput:StartTouchFlare);
											SDKHook(flarebox, SDKHook_StartTouch, StartTouchFlaretch);
											SDKHook(flare, SDKHook_StartTouch, StartTouchFlaretch);
											float small[3];
											small[0] = -30.0;
											small[1] = -30.0;
											small[2] = -30.0;
											SetEntPropVector(flarebox,Prop_Data,"m_vecMins",small);
											small[0] = 30.0;
											small[1] = 30.0;
											small[2] = 30.0;
											SetEntPropVector(flarebox,Prop_Data,"m_vecMaxs",small);
											SetEntPropEnt(flarebox,Prop_Data,"m_hEffectEntity",client);
											SetEntPropEnt(flare,Prop_Data,"m_hEffectEntity",client);
										}
									}
									if (FileExists("sound/weapons/flaregun/fire.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\flaregun\\fire.wav", weap, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
								}
							}
							WeapAttackSpeed[client] = Time+1.0;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_medkit",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int medkitammo = GetEntProp(client,Prop_Data,"m_iHealthPack");
						if (medkitammo > 0)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 3;
								if (seq != mdlseq)
								{
									int targ = GetClientAimTarget(client, false);
									if ((targ > 0) && (targ < MaxClients+1))
									{
										char clsname[24];
										GetEntityClassname(targ,clsname,sizeof(clsname));
										float orgs[3];
										float targorgs[3];
										GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", orgs);
										GetEntPropVector(targ, Prop_Data, "m_vecAbsOrigin", targorgs);
										float chkdist = GetVectorDistance(orgs, targorgs, false);
										if ((StrEqual(clsname, "player")) && (RoundFloat(chkdist) < 91))
										{
											int a,b;
											if (HasEntProp(client,Prop_Data,"m_iTeamNum")) a = GetEntProp(client,Prop_Data,"m_iTeamNum");
											if (HasEntProp(targ,Prop_Data,"m_iTeamNum")) b = GetEntProp(targ,Prop_Data,"m_iTeamNum");
											if (a == b)
											{
												int targh = GetClientHealth(targ);
												int targmh = 100;
												if (HasEntProp(targ,Prop_Send,"m_iMaxHealth")) targmh = GetEntProp(targ,Prop_Send,"m_iMaxHealth");
												if (targh < targmh)
												{
													float Time = GetTickedTime();
													if (Time >= Healchk[client])
													{
														if (medkitammo-10 < 0) SetEntProp(client, Prop_Data, "m_iHealthPack", 0);
														else SetEntProp(client, Prop_Data, "m_iHealthPack", medkitammo-10);
														if (targh+10 > targmh) SetEntProp(targ, Prop_Data, "m_iHealth", targmh);
														else SetEntProp(targ, Prop_Data, "m_iHealth", targh+10);
														Healchk[client] = Time+0.6;
														EmitSoundToAll("items/medshot4.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
													}
												}
											}
										}
									}
									else if (IsValidEntity(targ))
									{
										char clsname[24];
										GetEntityClassname(targ,clsname,sizeof(clsname));
										if ((StrContains(clsname,"npc_",false) == 0) || (StrContains(clsname,"monster_",false) == 0))
										if (CheckNPCAlly(clsname,targ))
										{
											int targh = GetEntProp(targ,Prop_Data,"m_iHealth");
											int targmh = 100;
											if (HasEntProp(targ,Prop_Data,"m_iMaxHealth")) targmh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
											if (targh < targmh)
											{
												float Time = GetTickedTime();
												if (Time >= Healchk[client])
												{
													if (medkitammo-10 < 0) SetEntProp(client, Prop_Data, "m_iHealthPack", 0);
													else SetEntProp(client, Prop_Data, "m_iHealthPack", medkitammo-10);
													if (targh+10 > targmh) SetEntProp(targ, Prop_Data, "m_iHealth", targmh);
													else SetEntProp(targ, Prop_Data, "m_iHealth", targh+10);
													Healchk[client] = Time+0.6;
													EmitSoundToAll("items/medshot4.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
												}
											}
										}
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									ChangeEdictState(viewmdl);
									CreateTimer(0.6,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_manhacktoss",false)) || (StrEqual(curweap,"weapon_manhackgun",false)) || (StrEqual(curweap,"weapon_manhack",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if ((seq >= 3) && (seq <= 6))
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(5,6));
								ChangeEdictState(viewmdl);
								CreateTimer(0.75,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
								ManHackGo(client);
							}
							else if (ManHackAmmo[client] > 0)
							{
								int mdlseq = 2;
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									ChangeEdictState(viewmdl);
									CreateTimer(2.0,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_cguard"))
				{
					float Time = GetTickedTime();
					if ((antispamchk[client] <= Time) && (CGuardAmm[client] > 0))
					{
						cstr(client);
						antispamchk[client] = Time + 1.5;
						CGuardAmm[client]--;
					}
				}
				else if (StrEqual(curweap,"weapon_gluon",false))
				{
					setbuttons = false;
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if ((EnergyAmm[client] < 1) && (seq == 1))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
								float orgs[3];
								if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
								else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",2);
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\gluon\\special1.wav");
								StopSound(weap,SNDCHAN_WEAPON,snd);
								if (WeapSnd[client] > 0.0) EmitAmbientSound(snd, orgs, weap, SNDLEVEL_TRAIN, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
								Format(snd,sizeof(snd),"weapons\\gluon\\special2.wav");
								EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								CreateTimer(0.2,resetviewmdl,viewmdl);
								WeapSnd[client] = 0.0;
								if ((EndTarg[client] != 0) && (IsValidEntity(EndTarg[client])))
								{
									int effect = CreateEntityByName("info_particle_system");
									if (effect != -1)
									{
										float endorg[3];
										if (HasEntProp(EndTarg[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(EndTarg[client],Prop_Data,"m_vecAbsOrigin",endorg);
										else if (HasEntProp(EndTarg[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(EndTarg[client],Prop_Send,"m_vecOrigin",endorg);
										float angs[3];
										if (HasEntProp(EndTarg[client],Prop_Data,"m_angAbsRotation")) GetEntPropVector(EndTarg[client],Prop_Data,"m_angAbsRotation",angs);
										DispatchKeyValue(effect,"effect_name","gluon_beam_burst");
										DispatchKeyValue(effect,"start_active","1");
										TeleportEntity(effect,endorg,angs,NULL_VECTOR);
										DispatchSpawn(effect);
										ActivateEntity(effect);
										AcceptEntityInput(effect,"Start");
										int entindx = EntIndexToEntRef(effect);
										CreateTimer(0.5,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
										int beam = GetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity");
										if ((beam != 0) && (IsValidEntity(beam)))
										{
											int beam2 = GetEntPropEnt(beam,Prop_Data,"m_hEffectEntity");
											if ((beam2 != 0) && (IsValidEntity(beam2))) AcceptEntityInput(beam2,"kill");
											AcceptEntityInput(beam,"kill");
										}
										if ((HandAttach[client] != 0) && (IsValidEntity(HandAttach[client])))
										{
											int sprite = GetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity");
											if ((sprite != 0) && (IsValidEntity(sprite)))
											{
												SetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity",-1);
												AcceptEntityInput(sprite,"kill");
											}
										}
										AcceptEntityInput(EndTarg[client],"kill");
									}
									EndTarg[client] = 0;
								}
							}
							else if (EnergyAmm[client] > 0)
							{
								if (seq != 1)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
								}
								else
								{
									if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
									if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
									if (HasEntProp(weap,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weap,Prop_Data,"m_iPrimaryAmmoType",12);
									int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
									if (ammover > 0)
									{
										Ammo12Reset[client] = ammover;
										SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
									}
									float Time = GetTickedTime();
									//GameSounds: weapon_gluon.Empty weapon_gluon.Special1 weapon_gluon.Special2 weapon_gluon.Special3
									if (WeapSnd[client] < Time)
									{
										char snd[64];
										Format(snd,sizeof(snd),"weapons\\gluon\\special1.wav");
										StopSound(weap,SNDCHAN_WEAPON,snd);
										if (WeapSnd[client] > 0.0)
										{
											float orgs[3];
											if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
											else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
											EmitAmbientSound(snd, orgs, weap, SNDLEVEL_TRAIN, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
											EmitAmbientSound(snd, orgs, weap, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
										}
										else EmitSoundToAll(snd, weap, SNDCHAN_WEAPON, SNDLEVEL_TRAIN);
										WeapSnd[client] = Time+9.0;
									}
									float endpos[3];
									float plyfirepos[3];
									float plyang[3];
									GetClientEyeAngles(client,plyang);
									GetClientEyePosition(client,plyfirepos);
									TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
									TR_GetEndPosition(endpos);
									if (WeapAttackSpeed[client] < Time)
									{
										int targ = TR_GetEntityIndex();
										int hitgroup = 0;
										if ((IsValidEntity(targ)) && (targ != 0)) hitgroup = TR_GetHitGroup();
										int ent = CreateEntityByName("env_explosion");
										if (ent != -1)
										{
											DispatchKeyValue(ent,"iMagnitude","20");
											DispatchKeyValue(ent,"iRadiusOverride","50");
											DispatchKeyValue(ent,"spawnflags","9084");
											TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(ent);
											SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
											AcceptEntityInput(ent,"Explode");
											AcceptEntityInput(ent,"Kill");
										}
										//Push effect
										ent = CreateEntityByName("env_physexplosion");
										if (ent != -1)
										{
											DispatchKeyValue(ent,"magnitude","20");
											DispatchKeyValue(ent,"radius","100");
											DispatchKeyValue(ent,"inner_radius","0");
											DispatchKeyValue(ent,"spawnflags","10");
											TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(ent);
											SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
											AcceptEntityInput(ent,"Explode");
											AcceptEntityInput(ent,"Kill");
										}
										if ((EndTarg[client] == 0) || (!IsValidEntity(EndTarg[client])))
										{
											EndTarg[client] = CreateEntityByName("generic_actor");
											if (EndTarg[client] != -1)
											{
												DispatchKeyValue(EndTarg[client],"rendermode","10");
												DispatchKeyValue(EndTarg[client],"DisableShadows","1");
												DispatchKeyValue(EndTarg[client],"solid","0");
												DispatchKeyValue(EndTarg[client],"model","models/props_junk/popcan01a.mdl");
												TeleportEntity(EndTarg[client],endpos,plyang,NULL_VECTOR);
												DispatchSpawn(EndTarg[client]);
												ActivateEntity(EndTarg[client]);
												if (HasEntProp(EndTarg[client],Prop_Data,"m_CollisionGroup")) SetEntProp(EndTarg[client],Prop_Data,"m_CollisionGroup",5);
												if (HasEntProp(EndTarg[client],Prop_Data,"m_bloodColor")) SetEntProp(EndTarg[client],Prop_Data,"m_bloodColor",3);
											}
											if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
											{
												HandAttach[client] = CreateEntityByName("info_target");
												if (HandAttach[client] != -1)
												{
													TeleportEntity(HandAttach[client],plyfirepos,plyang,NULL_VECTOR);
													DispatchSpawn(HandAttach[client]);
													ActivateEntity(HandAttach[client]);
													SetVariantString("!activator");
													AcceptEntityInput(HandAttach[client],"SetParent",client);
													SetVariantString("anim_attachment_RH");
													AcceptEntityInput(HandAttach[client],"SetParentAttachment");
													float orgoffs[3];
													orgoffs[0] = 5.0;
													orgoffs[1] = 0.0;
													orgoffs[2] = 5.0;
													SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
													int effect = CreateEntityByName("env_sprite");
													if (effect != -1)
													{
														DispatchKeyValue(effect,"model","sprites/glow01.spr");
														DispatchKeyValue(effect,"scale","1.0");
														DispatchKeyValue(effect,"GlowProxySize","8");
														DispatchKeyValue(effect,"rendermode","9");
														DispatchKeyValue(effect,"rendercolor","100 100 200");
														TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
														DispatchSpawn(effect);
														ActivateEntity(effect);
														AcceptEntityInput(effect,"Activate");
														SetVariantString("!activator");
														AcceptEntityInput(effect,"SetParent",client);
														SetVariantString("anim_attachment_RH");
														AcceptEntityInput(effect,"SetParentAttachment");
														orgoffs[0] = 7.0;
														orgoffs[1] = 0.0;
														orgoffs[2] = 0.0;
														SetEntPropVector(effect,Prop_Data,"m_vecOrigin",orgoffs);
													}
													SetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity",effect);
												}
											}
											int effect = CreateEntityByName("env_sprite");
											if (effect != -1)
											{
												DispatchKeyValue(effect,"model","sprites/glow01.spr");//effects/glowball.vmt
												DispatchKeyValue(effect,"scale","1.0");
												DispatchKeyValue(effect,"GlowProxySize","8");
												DispatchKeyValue(effect,"rendermode","9");//2
												DispatchKeyValue(effect,"rendercolor","200 200 255");
												TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
												DispatchSpawn(effect);
												ActivateEntity(effect);
												AcceptEntityInput(effect,"Activate");
												SetVariantString("!activator");
												AcceptEntityInput(effect,"SetParent",EndTarg[client]);
											}
											int beam = CreateEntityByName("beam");
											if (beam != -1)
											{
												DispatchKeyValue(beam,"model","effects/gluon_beam.vmt");
												DispatchKeyValue(beam,"texture","effects/gluon_beam.vmt");
												SetEntProp(beam,Prop_Data,"m_nModelIndex",gluonbeam);
												SetEntProp(beam,Prop_Data,"m_nHaloIndex",gluonbeam);
												TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(beam);
												ActivateEntity(beam);
												SetEntityRenderColor(beam,255,255,255,255);
												SetEntProp(beam,Prop_Data,"m_nBeamType",1);
												SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
												SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
												SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
												//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",client,0);
												//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
												//SetEntProp(beam,Prop_Data,"m_nAttachIndex",handatt,0);
												SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
												SetEntPropEnt(beam,Prop_Data,"m_hEndEntity",EndTarg[client]);
												//SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
												SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",2.0);
												SetEntPropFloat(beam,Prop_Data,"m_fWidth",4.0);
												SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",8.0);
												SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
												SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
												SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
												SetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity",beam);
											}
											int beam2 = CreateEntityByName("beam");
											if (beam2 != -1)
											{
												DispatchKeyValue(beam2,"model","effects/gluon_beam.vmt");
												DispatchKeyValue(beam2,"texture","effects/gluon_beam.vmt");
												SetEntProp(beam2,Prop_Data,"m_nModelIndex",gluonbeam);
												TeleportEntity(beam2,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(beam2);
												ActivateEntity(beam2);
												SetEntityRenderColor(beam2,255,255,255,255);
												SetEntProp(beam2,Prop_Data,"m_nBeamType",1);
												SetEntProp(beam2,Prop_Data,"m_nBeamFlags",0);
												SetEntProp(beam2,Prop_Data,"m_nNumBeamEnts",2);
												SetEntPropEnt(beam2,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
												//SetEntPropEnt(beam2,Prop_Data,"m_hAttachEntity",client,0);
												//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
												//SetEntProp(beam2,Prop_Data,"m_nAttachIndex",handatt,0);
												SetEntPropEnt(beam2,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
												SetEntPropEnt(beam2,Prop_Data,"m_hEndEntity",EndTarg[client]);
												//SetEntPropVector(beam2,Prop_Data,"m_vecEndPos",endpos);
												SetEntPropFloat(beam2,Prop_Data,"m_fAmplitude",4.0);
												SetEntPropFloat(beam2,Prop_Data,"m_fWidth",8.0);
												SetEntPropFloat(beam2,Prop_Data,"m_fEndWidth",4.0);
												SetEntPropFloat(beam2,Prop_Data,"m_fSpeed",1.0);
												SetEntPropFloat(beam2,Prop_Data,"m_flFrameRate",1.0);
												SetEntPropFloat(beam2,Prop_Data,"m_flHDRColorScale",1.0);
												SetEntProp(beam2,Prop_Data,"m_nDissolveType",-1);
												SetEntProp(beam2,Prop_Data,"m_nRenderMode",2);
												SetEntPropEnt(beam,Prop_Data,"m_hEffectEntity",beam2);
											}
										}
										else
										{
											SetEntProp(EndTarg[client],Prop_Data,"m_MoveType",8);
											float endorg[3];
											if (HasEntProp(EndTarg[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(EndTarg[client],Prop_Data,"m_vecAbsOrigin",endorg);
											else if (HasEntProp(EndTarg[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(EndTarg[client],Prop_Send,"m_vecOrigin",endorg);
											float shootvel[3];
											MakeVectorFromPoints(endorg,endpos,shootvel);
											ScaleVector(shootvel,3.0);
											if (((shootvel[0] < 100.0) && (shootvel[0] > -100.0)) || ((shootvel[1] < 100.0) && (shootvel[1] > -100.0)))
												ScaleVector(shootvel,2.0);
											TeleportEntity(EndTarg[client],NULL_VECTOR,plyang,shootvel);
											int decal = CreateEntityByName("infodecal");
											if (decal != -1)
											{
												//effects/glowball
												DispatchKeyValue(decal,"texture","decals/scorch2");
												DispatchKeyValue(decal,"LowPriority","1");
												TeleportEntity(decal,endorg,NULL_VECTOR,NULL_VECTOR);
												DispatchSpawn(decal);
												ActivateEntity(decal);
												AcceptEntityInput(decal,"Activate");
											}
										}
										if ((IsValidEntity(targ)) && (targ != 0))
										{
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\gluon\\hit%i.wav",GetRandomInt(1,4));
											EmitSoundToAll(snd, targ, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
											char clsname[32];
											GetEntityClassname(targ,clsname,sizeof(clsname));
											float damage = 1.0;
											Handle cvar = FindConVar("sk_plr_dmg_gluon");
											if (cvar != INVALID_HANDLE)
											{
												damage = GetConVarFloat(cvar);
												float inflictscale = 1.0;
												char scalechk[32];
												Format(scalechk,sizeof(scalechk),"sk_dmg_inflict_scale%i",difficulty);
												Handle scaleh = FindConVar(scalechk);
												if (scaleh != INVALID_HANDLE) inflictscale = GetConVarFloat(scaleh);
												CloseHandle(scaleh);
												damage = damage/inflictscale;
												if (hitgroup == headgroup) damage = damage*2.0;
											}
											CloseHandle(cvar);
											if ((!CheckNPCAlly(clsname,targ)) || ((targ < MaxClients+1) && (targ > 0) && (friendlyfire)))
											{
												SDKHooks_TakeDamage(targ,client,client,damage,DMG_ENERGYBEAM|DMG_SONIC,-1,NULL_VECTOR,endpos);
											}
										}
										EnergyAmm[client]--;
										WeapAttackSpeed[client] = Time+0.25;
									}
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false)))
				{
					setbuttons = false;
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							float Time = GetTickedTime();
							if ((EnergyAmm[client] > 0) && (WeapAttackSpeed[client] < Time) && (seq != 4))
							{
								EnergyAmm[client]--;
								char mdl[64];
								char snd[64];
								char beammdl[64];
								int taubeammdl = taubeam;
								int posside = 8;
								float posz = 12.0;
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								Format(beammdl,sizeof(beammdl),"effects/tau_beam.vmt");
								if (StrEqual(mdl,"models/v_gauss.mdl",false))
								{
									Format(snd,sizeof(snd),"weapons\\gauss2.wav");
									taubeammdl = tauhl1beam;
									Format(beammdl,sizeof(beammdl),"sprites/smoke.vmt");
									if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
									posside = 5;
								}
								else if (StrEqual(mdl,"models/weapons/v_gauss_suit.mdl",false))
								{
									float cycle = GetEntPropFloat(viewmdl,Prop_Data,"m_flCycle");
									if (seq != 4) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									else if ((seq == 4) && (cycle > 0.2)) SetEntPropFloat(viewmdl,Prop_Data,"m_flCycle",0.0);
									Format(snd,sizeof(snd),"weapons\\gauss\\fire1.wav");
									taubeammdl = tauhl2beam;
									Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
									posside = 5;
									posz = 8.0;
								}
								else
								{
									int randsnd = GetRandomInt(1,5);
									if (randsnd == 4) Format(snd,sizeof(snd),"weapons\\tau\\single.wav");
									else if (randsnd == 5) Format(snd,sizeof(snd),"weapons\\tau\\single2.wav");
									else Format(snd,sizeof(snd),"weapons\\tau\\single0%i.wav",randsnd);
									if (seq == 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
									else SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
								}
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
								EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								CreateTimer(0.2,resetviewmdl,viewmdl);
								WeapAttackSpeed[client] = Time+0.3;
								SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
								float endpos[3];
								float plyfirepos[3];
								float plyang[3];
								float traceNormal[3];
								GetClientEyeAngles(client,plyang);
								GetClientEyePosition(client,plyfirepos);
								TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
								TR_GetEndPosition(endpos);
								TR_GetPlaneNormal(INVALID_HANDLE,traceNormal);
								/* from SDK vehicle_jeep
									//Draw the main beam shaft
									CBeam *pBeam = CBeam::BeamCreate( GAUSS_BEAM_SPRITE, 0.5 );
									
									pBeam->SetStartPos( startPos );
									pBeam->PointEntInit( endPos, this );
									pBeam->SetEndAttachment( LookupAttachment("Muzzle") );
									//Value of width charged beam 9.6 regular 2.4
									pBeam->SetWidth( width );
									pBeam->SetEndWidth( 0.05f );
									pBeam->SetBrightness( 255 );
									pBeam->SetColor( 255, 185+random->RandomInt( -16, 16 ), 40 );
									pBeam->RelinkBeam();
									pBeam->LiveForTime( 0.1f );

									//Draw electric bolts along shaft
									pBeam = CBeam::BeamCreate( GAUSS_BEAM_SPRITE, 3.0f );
									
									pBeam->SetStartPos( startPos );
									pBeam->PointEntInit( endPos, this );
									pBeam->SetEndAttachment( LookupAttachment("Muzzle") );

									pBeam->SetBrightness( random->RandomInt( 64, 255 ) );
									pBeam->SetColor( 255, 255, 150+random->RandomInt( 0, 64 ) );
									pBeam->RelinkBeam();
									pBeam->LiveForTime( 0.1f );
									pBeam->SetNoise( 1.6f );
									pBeam->SetEndWidth( 0.1f );
								*/
								int beam = CreateEntityByName("beam");
								if (beam != -1)
								{
									DispatchKeyValue(beam,"model",beammdl);
									DispatchKeyValue(beam,"texture",beammdl);
									SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
									SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
									SetVariantString("OnUser4 !self:kill::0.1:-1")
									AcceptEntityInput(beam,"addoutput");
									AcceptEntityInput(beam,"FireUser4");
									plyang[1]-=90.0;
									plyfirepos[0] = (plyfirepos[0] + (posside * Cosine(DegToRad(plyang[1]))));
									plyfirepos[1] = (plyfirepos[1] + (posside * Sine(DegToRad(plyang[1]))));
									plyang[1]+=90.0;
									plyfirepos[0] = (plyfirepos[0] + (8 * Cosine(DegToRad(plyang[1]))));
									plyfirepos[1] = (plyfirepos[1] + (8 * Sine(DegToRad(plyang[1]))));
									plyfirepos[2]-=posz;
									TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
									DispatchSpawn(beam);
									ActivateEntity(beam);
									SetEntityRenderColor(beam,255,GetRandomInt(150,220),40,255);
									SetEntProp(beam,Prop_Data,"m_nBeamType",1);
									SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
									SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
									//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
									//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",client,0);
									//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
									//SetEntProp(beam,Prop_Data,"m_nAttachIndex",handatt,0);
									//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
									//SetEntPropEnt(beam,Prop_Data,"m_hEndEntity",EndTarg[client]);
									SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
									SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",0.0);
									SetEntPropFloat(beam,Prop_Data,"m_fWidth",2.4);
									SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",0.05);
									SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
									SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
									SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
									SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
									SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
									for (int i = 0;i<3;i++)
									{
										beam = CreateEntityByName("beam");
										if (beam != -1)
										{
											DispatchKeyValue(beam,"model",beammdl);
											DispatchKeyValue(beam,"texture",beammdl);
											SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
											SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
											TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
											DispatchSpawn(beam);
											ActivateEntity(beam);
											SetVariantString("OnUser4 !self:kill::0.1:-1")
											AcceptEntityInput(beam,"addoutput");
											AcceptEntityInput(beam,"FireUser4");
											SetEntityRenderColor(beam,255,255,GetRandomInt(150,214),GetRandomInt(64,255));
											SetEntProp(beam,Prop_Data,"m_nBeamType",1);
											SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
											SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
											SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
											SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",2.6+i);
											SetEntPropFloat(beam,Prop_Data,"m_fWidth",3.0+i);
											SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",0.1);
											SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
											SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
											SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
											SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
											SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
										}
									}
									int ent = CreateEntityByName("env_physexplosion");
									if(ent != -1)
									{
										DispatchKeyValueFloat(ent,"magnitude",20.0);
										DispatchKeyValue(ent,"radius","0");
										DispatchKeyValue(ent,"inner_radius","0");
										DispatchKeyValue(ent,"spawnflags","10");
										TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
										DispatchSpawn(ent);
										SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
										AcceptEntityInput(ent,"Explode");
										AcceptEntityInput(ent,"Kill");
									}
									int decal = CreateEntityByName("infodecal");
									if (decal != -1)
									{
										DispatchKeyValue(decal,"texture","decals/scorch2");
										DispatchKeyValue(decal,"LowPriority","1");
										TeleportEntity(decal,endpos,NULL_VECTOR,NULL_VECTOR);
										DispatchSpawn(decal);
										ActivateEntity(decal);
										AcceptEntityInput(decal,"Activate");
									}
									//From weapon_gauss CustomGuns plugin:
									float vecFwd[3], vecUp[3], vecRight[3];
									GetAngleVectors(plyang, vecFwd, vecRight, vecUp);
									float vecDir[3];
									float x, y, z;
									//Gassian spread
									do {
										x = GetRandomFloat(-0.5,0.5) + GetRandomFloat(-0.5,0.5);
										y = GetRandomFloat(-0.5,0.5) + GetRandomFloat(-0.5,0.5);
										z = x*x+y*y;
									} while (z > 1);
								 
									vecDir[0] = vecFwd[0] + x * 0.00873 * vecRight[0] + y * 0.00873 * vecUp[0];
									vecDir[1] = vecFwd[1] + x * 0.00873 * vecRight[1] + y * 0.00873 * vecUp[1];
									vecDir[2] = vecFwd[2] + x * 0.00873 * vecRight[2] + y * 0.00873 * vecUp[2];
									float hitAngle = -GetVectorDotProduct(traceNormal, vecDir);
									if ( hitAngle < 0.5 )
									{
										float vReflection[3];
										vReflection[0] = 2.0 * traceNormal[0] * hitAngle + vecDir[0];
										vReflection[1] = 2.0 * traceNormal[1] * hitAngle + vecDir[1];
										vReflection[2] = 2.0 * traceNormal[2] * hitAngle + vecDir[2];
										GetVectorAngles(vReflection, plyang);
										plyfirepos = endpos;
										TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
										TR_GetEndPosition(endpos);
										for (int i = 0;i<3;i++)
										{
											beam = CreateEntityByName("beam");
											if (beam != -1)
											{
												DispatchKeyValue(beam,"model",beammdl);
												DispatchKeyValue(beam,"texture",beammdl);
												SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
												SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
												TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(beam);
												ActivateEntity(beam);
												SetVariantString("OnUser4 !self:kill::0.1:-1")
												AcceptEntityInput(beam,"addoutput");
												AcceptEntityInput(beam,"FireUser4");
												if (i == 0)
												{
													SetEntPropFloat(beam,Prop_Data,"m_fWidth",2.4);
													SetEntityRenderColor(beam,255,GetRandomInt(150,220),40,255);
												}
												else
												{
													SetEntPropFloat(beam,Prop_Data,"m_fWidth",3.0);
													SetEntityRenderColor(beam,255,255,GetRandomInt(150,214),GetRandomInt(64,255));
												}
												SetEntProp(beam,Prop_Data,"m_nBeamType",1);
												SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
												SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
												SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
												SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",GetRandomFloat(1.0,1.7));
												SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",0.1);
												SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
												SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
												SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
												SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
											}
										}
										TE_Start("GaussExplosion");
										TE_WriteFloat("m_vecOrigin[0]",endpos[0]);
										TE_WriteFloat("m_vecOrigin[1]",endpos[1]);
										TE_WriteFloat("m_vecOrigin[2]",endpos[2]);
										TE_WriteNum("m_nType",0);
										TE_WriteVector("m_vecDirection",traceNormal);
										TE_SendToAll();
										ent = CreateEntityByName("env_physexplosion");
										if(ent != -1)
										{
											DispatchKeyValueFloat(ent,"magnitude",20.0);
											DispatchKeyValue(ent,"radius","0");
											DispatchKeyValue(ent,"inner_radius","0");
											DispatchKeyValue(ent,"spawnflags","10");
											TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(ent);
											SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
											AcceptEntityInput(ent,"Explode");
											AcceptEntityInput(ent,"Kill");
										}
										decal = CreateEntityByName("infodecal");
										if (decal != -1)
										{
											DispatchKeyValue(decal,"texture","decals/scorch2");//decals/redglowfade
											DispatchKeyValue(decal,"LowPriority","1");
											TeleportEntity(decal,endpos,NULL_VECTOR,NULL_VECTOR);
											DispatchSpawn(decal);
											ActivateEntity(decal);
											AcceptEntityInput(decal,"Activate");
										}
									}
									else
									{
										TE_Start("GaussExplosion");
										TE_WriteFloat("m_vecOrigin[0]",endpos[0]);
										TE_WriteFloat("m_vecOrigin[1]",endpos[1]);
										TE_WriteFloat("m_vecOrigin[2]",endpos[2]);
										TE_WriteNum("m_nType",0);
										TE_WriteVector("m_vecDirection",traceNormal);
										TE_SendToAll();
									}
									int effect = CreateEntityByName("env_sprite");
									if (effect != -1)
									{
										DispatchKeyValue(effect,"model","sprites/glow01.spr");
										DispatchKeyValue(effect,"scale","1.0");
										DispatchKeyValue(effect,"GlowProxySize","3");
										DispatchKeyValue(effect,"rendermode","9");
										DispatchKeyValue(effect,"rendercolor","200 200 0");
										TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
										DispatchSpawn(effect);
										ActivateEntity(effect);
										AcceptEntityInput(effect,"Activate");
										SetVariantString("OnUser4 !self:kill::0.1:-1")
										AcceptEntityInput(effect,"addoutput");
										AcceptEntityInput(effect,"FireUser4");
									}
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_glock",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						setbuttons = false;
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
						float Time = GetTickedTime();
						if ((nextatk < GetGameTime()+0.04) && (WeapSnd[client] < Time))
						{
							StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_fire2.wav");
							char snd[64];
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
							{
								if (CLAttachment[client] == 1)
								{
									Format(snd,sizeof(snd),"weapons\\pl_gun1.wav");
									SetEntPropFloat(client,Prop_Data,"m_flFlashTime",0.0);
								}
								else Format(snd,sizeof(snd),"weapons\\pl_gun3.wav");
							}
							else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
							{
								Format(snd,sizeof(snd),"weapons\\pistol\\glock_fire.wav");
							}
							else
							{
								Format(snd,sizeof(snd),"weapons\\glock\\single.wav");
							}
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
							if ((amm > 0) && (!inreload))
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq == 3)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									}
									else
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
									}
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
									WeapSnd[client] = Time+0.05;
								}
							}
							else if (inreload)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										if ((seq != 5) && (seq != 6))
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(5,6));
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
										}
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										if (seq != 9)
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											Format(snd,sizeof(snd),"weapons\\pistol\\glock_reload.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
									else if ((seq != 6) && (seq != 7))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(6,7));
										StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
										Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
										EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									}
								}
							}
							else
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != 0)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
									}
								}
							}
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if ((amm > 0) && (!inreload))
						{
							float Time = GetTickedTime();
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								char snd[64];
								if (FileExists("sound/weapons/mp5/single1.wav",true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\mp5\\single%i.wav",GetRandomInt(1,3));
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
								{
									Format(snd,sizeof(snd),"weapons\\hks%i.wav",GetRandomInt(1,3));
									if (seq == 6)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
									}
									else
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
									}
								}
								else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
								{
									int rand = GetRandomInt(0,3);
									if (seq == rand)
									{
										if (rand == 3) rand--;
										else rand++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									Format(snd,sizeof(snd),"weapons\\m4\\m4_fire.wav");
								}
								else if (StrEqual(curweap,"weapon_g36c",false))
								{
									int rand = GetRandomInt(1,6);
									if (seq == rand)
									{
										if (rand == 6) rand--;
										else rand++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									Format(snd,sizeof(snd),"weapons\\g36c\\g36c_fire.wav");
								}
								else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
								{
									int rand = GetRandomInt(1,6);
									if (seq == rand)
									{
										if (rand == 3) rand--;
										else rand++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
									Format(snd,sizeof(snd),"weapons\\mp5\\mp5_fire.wav");
								}
								else
								{
									if (seq == 3)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
									}
									else
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
									}
								}
								EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								WeapAttackSpeed[client] = Time+0.1;
							}
						}
						else if (inreload)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int mdlseq = 2;
								char snd[64];
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
								{
									mdlseq = 3;
									Format(snd,sizeof(snd),"weapons\\reload3.wav");
								}
								else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
								{
									mdlseq = 7;
									Format(snd,sizeof(snd),"weapons\\m4\\m4_reload.wav");
								}
								else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
								{
									mdlseq = 9;
									Format(snd,sizeof(snd),"weapons\\g36c\\g36c_reload.wav");
								}
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_ITEM, SNDLEVEL_DISHWASHER);
								}
							}
						}
						else
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 0)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_sl8",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if ((amm > 0) && (!inreload))
						{
							float Time = GetTickedTime();
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								EmitSoundToAll("weapons\\SL8\\SL8-1.wav", client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq == 1)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
								else
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
								}
								WeapAttackSpeed[client] = Time+0.2;
								int shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
								SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
								float orgs[3];
								float angs[3];
								GetClientEyeAngles(client, angs);
								if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
								{
									HandAttach[client] = CreateEntityByName("info_target");
									if (HandAttach[client] != -1)
									{
										float plyfirepos[3];
										GetClientEyePosition(client,plyfirepos);
										TeleportEntity(HandAttach[client],plyfirepos,angs,NULL_VECTOR);
										DispatchSpawn(HandAttach[client]);
										ActivateEntity(HandAttach[client]);
										SetVariantString("!activator");
										AcceptEntityInput(HandAttach[client],"SetParent",client);
										SetVariantString("anim_attachment_RH");
										AcceptEntityInput(HandAttach[client],"SetParentAttachment");
										float orgoffs[3];
										orgoffs[0] = 5.0;
										orgoffs[1] = 0.0;
										orgoffs[2] = 5.0;
										SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
									}
								}
								if (HasEntProp(HandAttach[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(HandAttach[client],Prop_Data,"m_vecAbsOrigin",orgs);
								else if (HasEntProp(HandAttach[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(HandAttach[client],Prop_Send,"m_vecOrigin",orgs);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",amm-1);
								float maxspread = 0.5+(shotsfired/2);
								if (maxspread > 2.0) maxspread = 2.0;
								int sideoffs = 5;
								ShootBullet(client,curweap,orgs,angs,sideoffs,maxspread);
							}
						}
						else if ((amm <= 0) && (!inreload))
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 2;
							if (seq != mdlseq)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
								if (FileExists("sound/weapons/sl8/sl8_magout.wav",true,NULL_STRING))
								{
									char snd[64];
									Format(snd,sizeof(snd),"weapons\\sl8\\sl8_magout.wav");
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									CreateTimer(0.6,resetviewmdl,viewmdl);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_oicw",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/smg1/smg1_fire1.wav");
						int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if ((amm > 0) && (!inreload))
						{
							float Time = GetTickedTime();
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								if (FileExists("sound/weapons/oicw/oicw_fire1.wav",true,NULL_STRING))
								{
									char snd[64];
									Format(snd,sizeof(snd),"weapons\\oicw\\oicw_fire%i.wav",GetRandomInt(1,3));
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								}
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(1,3);
								if (rand == seq)
								{
									if (rand+1 > 3) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								WeapAttackSpeed[client] = Time+0.1;
								float orgs[3];
								float angs[3];
								GetClientEyeAngles(client, angs);
								if ((HandAttach[client] == 0) || (!IsValidEntity(HandAttach[client])))
								{
									HandAttach[client] = CreateEntityByName("info_target");
									if (HandAttach[client] != -1)
									{
										float plyfirepos[3];
										GetClientEyePosition(client,plyfirepos);
										TeleportEntity(HandAttach[client],plyfirepos,angs,NULL_VECTOR);
										DispatchSpawn(HandAttach[client]);
										ActivateEntity(HandAttach[client]);
										SetVariantString("!activator");
										AcceptEntityInput(HandAttach[client],"SetParent",client);
										SetVariantString("anim_attachment_RH");
										AcceptEntityInput(HandAttach[client],"SetParentAttachment");
										float orgoffs[3];
										orgoffs[0] = 5.0;
										orgoffs[1] = 0.0;
										orgoffs[2] = 5.0;
										SetEntPropVector(HandAttach[client],Prop_Data,"m_vecOrigin",orgoffs);
									}
								}
								if (HasEntProp(HandAttach[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(HandAttach[client],Prop_Data,"m_vecAbsOrigin",orgs);
								else if (HasEntProp(HandAttach[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(HandAttach[client],Prop_Send,"m_vecOrigin",orgs);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",amm-1);
								int shotsfired = GetEntProp(weap,Prop_Data,"m_nShotsFired");
								SetEntProp(weap,Prop_Data,"m_nShotsFired",shotsfired+1);
								int sideoffs = 5;
								float maxspread = 0.5+(shotsfired/2);
								if (maxspread > 2.0) maxspread = 2.0;
								ShootBullet(client,curweap,orgs,angs,sideoffs,maxspread);
							}
						}
						else if ((amm <= 0) && (!inreload))
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 5;
							if (seq != mdlseq)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
								if (FileExists("sound/weapons/oicw/oicw_reload.wav",true,NULL_STRING))
								{
									EmitSoundToAll("weapons\\oicw\\oicw_reload.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									CreateTimer(2.3,resetviewmdl,viewmdl);
									SetEntProp(weap,Prop_Data,"m_bInReload",1);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if (amm > 0)
						{
							float Time = GetTickedTime();
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
								EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(7,12);
								if (seq == rand)
								{
									if (seq > 11) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
								WeapAttackSpeed[client] = Time+0.5;
								CreateHornet(client,weap);
							}
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
						}
						setbuttons = false;
					}
				}
				else if ((StrEqual(curweap,"weapon_handgrenade",false)) || (StrEqual(curweap,"weapon_satchel",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if (WeapAttackSpeed[client] < Time)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int hasammo = 0;
								int mdlseq = 2;
								char mdl[32];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
								if ((seq != mdlseq) && (hasammo))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									if (!StrEqual(curweap,"weapon_handgrenade",false))
									{
										CreateTimer(0.75,resetviewmdl,viewmdl);
										float targpos[3];
										float shootvel[3];
										float plyfirepos[3];
										float plyang[3];
										float maxscaler = 500.0;
										float sideadj = 0.0;
										char grenademdl[64];
										GetClientEyeAngles(client,plyang);
										if (StrEqual(curweap,"weapon_satchel",false))
										{
											sideadj = 10.0;
											Format(grenademdl,sizeof(grenademdl),"models/weapons/w_satchel.mdl");
										}
										else
										{
											sideadj = -10.0;
											maxscaler = 800.0;
											Format(grenademdl,sizeof(grenademdl),"models/items/boxmrounds.mdl");
										}
										plyang[1]+=sideadj;
										GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
										plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
										plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
										if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
										else plyfirepos[2]+=48.0;
										plyang[1]-=sideadj;
										TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
										TR_GetEndPosition(targpos);
										MakeVectorFromPoints(plyfirepos,targpos,shootvel);
										ScaleVector(shootvel,2.5);
										if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
										{
											while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
											{
												ScaleVector(shootvel,0.95);
											}
										}
										SatchelAmm[client]--;
										if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",SatchelAmm[client]);
										int satchel = CreateEntityByName("prop_physics_override");
										if (satchel != -1)
										{
											DispatchKeyValue(satchel,"classname","grenade_satchel");
											if (StrEqual(mdl,"models/v_satchel.mdl",false)) DispatchKeyValue(satchel,"model","models/items/boxmrounds.mdl");
											else DispatchKeyValue(satchel,"model",grenademdl);
											DispatchKeyValue(satchel,"solid","6");
											DispatchKeyValue(satchel,"spawnflags","256");
											TeleportEntity(satchel,plyfirepos,plyang,NULL_VECTOR);
											DispatchSpawn(satchel);
											ActivateEntity(satchel);
											if (StrEqual(mdl,"models/v_satchel.mdl",false))
											{
												if (!IsModelPrecached("models/w_satchel.mdl")) PrecacheModel("models/w_satchel.mdl",true);
												SetEntityModel(satchel,"models/w_satchel.mdl");
												SetEntProp(satchel,Prop_Data,"m_usSolidFlags",1);
											}
											TeleportEntity(satchel,NULL_VECTOR,NULL_VECTOR,shootvel);
											int endpoint = CreateEntityByName("env_explosion");
											if (endpoint != -1)
											{
												char dmgmag[8] = "300";
												char radius[8] = "150";
												Handle cvar = FindConVar("sk_plr_dmg_satchel");
												SDKHookEx(satchel,SDKHook_OnTakeDamage,grenademinetkdmg);
												if (cvar != INVALID_HANDLE) GetConVarString(cvar,dmgmag,sizeof(dmgmag));
												cvar = FindConVar("sk_satchel_radius");
												if (cvar != INVALID_HANDLE) GetConVarString(cvar,radius,sizeof(radius));
												CloseHandle(cvar);
												DispatchKeyValue(endpoint,"imagnitude",dmgmag);
												DispatchKeyValue(endpoint,"iRadiusOverride",radius);
												DispatchKeyValue(endpoint,"rendermode","0");
												TeleportEntity(endpoint,plyfirepos,plyang,NULL_VECTOR);
												DispatchSpawn(endpoint);
												ActivateEntity(endpoint);
												SetVariantString("!activator");
												AcceptEntityInput(endpoint,"SetParent",satchel);
												SetEntPropEnt(satchel,Prop_Data,"m_hOwnerEntity",endpoint);
												SetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity",client);
											}
										}
									}
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_tripmine",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						float Time = GetTickedTime();
						if (WeapAttackSpeed[client] < Time)
						{
							float plyfirepos[3];
							float angs[3];
							float endpos[3];
							GetClientEyePosition(client,plyfirepos);
							GetClientEyeAngles(client,angs);
							TR_TraceRayFilter(plyfirepos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
							TR_GetEndPosition(endpos);
							float chkdist = GetVectorDistance(plyfirepos,endpos,false);
							if (chkdist < 100.0)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int mdlseq = 6;
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									if (StrEqual(mdl,"models/v_tripmine.mdl",false)) mdlseq = 3;
									int hasammo = 0;
									if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
									if ((seq != mdlseq) && (hasammo))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
										CreateTimer(0.15,resetviewmdl,viewmdl);
									}
								}
								WeapAttackSpeed[client] = Time+1.0;
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_axe",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
						if (nextatk < GetGameTime())
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								float plyfirepos[3];
								float angs[3];
								float endpos[3];
								GetClientEyePosition(client,plyfirepos);
								GetClientEyeAngles(client,angs);
								TR_TraceRayFilter(plyfirepos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
								TR_GetEndPosition(endpos);
								float chkdist = GetVectorDistance(plyfirepos,endpos,false);
								if (chkdist > 80.0)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int randmiss = GetRandomInt(3,5);
									if (seq == randmiss)
									{
										if (randmiss == 5) randmiss--;
										else randmiss++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",randmiss);
								}
								else
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									int randhit = GetRandomInt(6,7);
									if (randhit == 5) randhit = 3;
									if (seq == randhit)
									{
										if (randhit == 7) randhit--;
										else if (randhit == 3) randhit = 6;
										else randhit++;
									}
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",randhit);
								}
							}
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_snark",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 3;
							int type = 1;
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_squeak.mdl",false))
							{
								mdlseq = 5;
								type = 0;
							}
							if ((seq != mdlseq) && (SnarkAmm[client] > 0))
							{
								SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								CreateTimer(0.5,resetviewmdl,viewmdl);
								SnarkAmm[client]--;
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",SnarkAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",SnarkAmm[client]);
								CreateSnark(client,type);
								ChangeEdictState(weap);
							}
							else
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_colt",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int hasammo = 0;
							if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
							if (nextatk < GetGameTime()+0.05)
							{
								if (((seq != 1) || (seq != 2)) && (hasammo > 0) && (!inreload))
								{
									if (seq == 2) SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
									else SetEntProp(viewmdl,Prop_Send,"m_nSequence",2);
								}
								else if (inreload)
								{
									if (seq != 4)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									}
								}
							}
							setbuttons = false;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_dualmp5k",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int inreload = GetEntProp(weap,Prop_Data,"m_bInReload");
							int hasammo = 0;
							if (HasEntProp(weap,Prop_Send,"m_iClip1")) hasammo = GetEntProp(weap,Prop_Send,"m_iClip1");
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if ((hasammo > 0) && (!inreload))
							{
								int rand = GetRandomInt(1,6);
								if (seq == rand)
								{
									if (rand == 6) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
							}
							else if (inreload)
							{
								if (seq != 8)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
								}
							}
							setbuttons = false;
						}
					}
				}
			}
		}
		else if (buttons & IN_ATTACK2)
		{
			if (!(g_LastButtons[client] & IN_ATTACK2))
			{
				if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (IsValidEntity(weap))
					{
						float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack");
						if (nextatk < GetGameTime()+0.1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int amm = GetEntProp(client,Prop_Send,"m_iAmmo",_,9);
								if (amm > 0)
								{
									int mdlseq = 1;
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									if (StrEqual(mdl,"models/v_9mmAR.mdl",false)) mdlseq = 5;
									else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
									{
										mdlseq = 6;
										EmitSoundToAll("weapons\\m4\\m4_altfire.wav", client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
									}
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
									}
									CreateTimer(0.5,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								}
								else
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
								}
							}
						}
					}
					setbuttons = false;
				}
				else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int amm = GetEntProp(weap,Prop_Data,"m_iClip1");
						if (amm > 0)
						{
							float Time = GetTickedTime();
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if ((viewmdl != -1) && (WeapAttackSpeed[client] < Time))
							{
								CreateHornet(client,weap);
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
								EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int rand = GetRandomInt(7,12);
								if (seq == rand)
								{
									if (seq > 11) rand--;
									else rand++;
								}
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",rand);
								SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
								WeapAttackSpeed[client] = Time+0.2;
							}
							SetEntPropFloat(weap,Prop_Data,"m_flTimeWeaponIdle",0.0);
						}
						setbuttons = false;
					}
				}
				else if (StrEqual(curweap,"weapon_sl8",false))
				{
					int fov = GetEntProp(client,Prop_Send,"m_iFOV");
					if ((fov > 60) || (fov == 0))
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",30);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((SL8Scope != 0) && (IsValidEntity(SL8Scope)))
						{
							CLInScope[client] = SL8Scope;
							AcceptEntityInput(SL8Scope,"StartOverlays",client);
						}
						else
						{
							SL8Scope = CreateEntityByName("env_screenoverlay");
							if (SL8Scope != -1)
							{
								DispatchKeyValue(SL8Scope,"spawnflags","1");
								DispatchKeyValue(SL8Scope,"OverlayName1","sprites/scope01");
								DispatchSpawn(SL8Scope);
								ActivateEntity(SL8Scope);
								CLInScope[client] = SL8Scope;
								AcceptEntityInput(SL8Scope,"StartOverlays",client);
							}
						}
					}
					else
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",90);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((SL8Scope != 0) && (IsValidEntity(SL8Scope)))
						{
							AcceptEntityInput(SL8Scope,"StopOverlays",client);
							CLInScope[client] = 0;
						}
					}
				}
				else if (StrEqual(curweap,"weapon_oicw",false))
				{
					int fov = GetEntProp(client,Prop_Send,"m_iFOV");
					if ((fov > 60) || (fov == 0))
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",36);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((OICWScope != 0) && (IsValidEntity(OICWScope)))
						{
							CLInScope[client] = OICWScope;
							AcceptEntityInput(OICWScope,"StartOverlays",client);
						}
						else
						{
							OICWScope = CreateEntityByName("env_screenoverlay");
							if (OICWScope != -1)
							{
								DispatchKeyValue(OICWScope,"spawnflags","1");
								DispatchKeyValue(OICWScope,"OverlayName1","overlays/weapons/oicw/scope_lens");
								DispatchSpawn(OICWScope);
								ActivateEntity(OICWScope);
								CLInScope[client] = OICWScope;
								AcceptEntityInput(OICWScope,"StartOverlays",client);
							}
						}
					}
					else
					{
						SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
						SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
						SetEntProp(client,Prop_Send,"m_iFOV",90);
						SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
						if ((OICWScope != 0) && (IsValidEntity(OICWScope)))
						{
							AcceptEntityInput(OICWScope,"StopOverlays",client);
							CLInScope[client] = 0;
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false)))
				{
					setbuttons = false;
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							float Time = GetTickedTime();
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							int mdlseq = 4;
							int pitch = 100;
							int flags = SND_NOFLAGS;
							char mdl[64];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							char snd[64];
							Format(snd,sizeof(snd),"weapons\\tau\\gauss_spinup.wav");
							if (StrEqual(mdl,"models/v_gauss.mdl",false))
							{
								mdlseq = 3;
								if ((seq == 3) && (TauCharge[client] > 3)) mdlseq = 4;
								pitch+=TauCharge[client]*8;
								if ((WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20)) flags = SND_CHANGEPITCH;
								Format(snd,sizeof(snd),"ambience\\pulsemachine.wav");
							}
							else if (StrEqual(mdl,"models/weapons/v_gauss_suit.mdl",false))
							{
								mdlseq = 2;
								if ((seq == 2) || (TauCharge[client] > 3)) mdlseq = 3;
								pitch+=TauCharge[client]*8;
								if ((WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20)) flags = SND_CHANGEPITCH;
								Format(snd,sizeof(snd),"weapons\\gauss\\chargeloop.wav");
							}
							if ((EnergyAmm[client] > 0) && (WeapAttackSpeed[client] < Time) && (TauCharge[client] < 20))
							{
								EnergyAmm[client]--;
								TauCharge[client]++;
								//m_flPlaybackRate
								if (HasEntProp(weap,Prop_Data,"m_iClip1")) SetEntProp(weap,Prop_Data,"m_iClip1",EnergyAmm[client]);
								if (HasEntProp(weap,Prop_Send,"m_iClip1")) SetEntProp(weap,Prop_Send,"m_iClip1",EnergyAmm[client]);
								if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
								EmitSoundToAll(snd, weap, SNDCHAN_WEAPON, SNDLEVEL_TRAIN, flags, _, pitch);
								WeapAttackSpeed[client] = Time+0.2;
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_glock",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						char mdl[32];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
								CreateTimer(0.5,resetviewmdl,viewmdl);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_satchel",false))
				{
					DetSatchels(-1,client);
				}
				else if (StrEqual(curweap,"weapon_colt",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						float nextsecondary = GetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack");
						if (nextsecondary < GetGameTime())
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if (seq != 8)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
									SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+0.5);
									ChangeEdictState(weap);
									CreateTimer(0.2,resetviewmdl,viewmdl);
									int targ = GetClientAimTarget(client,false)
									if ((targ != 0) && (IsValidEntity(targ)))
									{
										char cls[32];
										GetEntityClassname(targ,cls,sizeof(cls));
										if (!CheckNPCAlly(cls,targ))
										{
											float curorgs[3];
											float targorgs[3];
											GetClientAbsOrigin(client,curorgs);
											if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",targorgs);
											else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",targorgs);
											float chkdist = GetVectorDistance(curorgs,targorgs,false);
											if (chkdist < 100.0)
											{
												float damageForce[3];
												damageForce[0] = 5.0;
												damageForce[1] = 5.0;
												damageForce[2] = 5.0;
												SDKHooks_TakeDamage(targ,client,client,15.0,DMG_CLUB,-1,damageForce,curorgs);
												EmitSoundToAll("npc/zombie/zombie_hit.wav", weap, SNDCHAN_WEAPON, SNDLEVEL_TRAIN);
											}
										}
									}
								}
							}
						}
						StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_empty.wav");
					}
				}
			}
		}
		else if (!(buttons & IN_ATTACK))
		{
			if (StrEqual(curweap,"weapon_gluon",false))
			{
				setbuttons = false;
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 1)
						{
							float orgs[3];
							if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
							else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",2);
							char snd[64];
							Format(snd,sizeof(snd),"weapons\\gluon\\special1.wav");
							StopSound(weap,SNDCHAN_WEAPON,snd);
							if (WeapSnd[client] > 0.0) EmitAmbientSound(snd, orgs, weap, SNDLEVEL_TRAIN, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 1.5);
							Format(snd,sizeof(snd),"weapons\\gluon\\special2.wav");
							EmitSoundToAll(snd, weap, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
							CreateTimer(0.2,resetviewmdl,viewmdl);
							WeapSnd[client] = 0.0;
							if ((EndTarg[client] != 0) && (IsValidEntity(EndTarg[client])))
							{
								int effect = CreateEntityByName("info_particle_system");
								if (effect != -1)
								{
									float endorg[3];
									if (HasEntProp(EndTarg[client],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(EndTarg[client],Prop_Data,"m_vecAbsOrigin",endorg);
									else if (HasEntProp(EndTarg[client],Prop_Send,"m_vecOrigin")) GetEntPropVector(EndTarg[client],Prop_Send,"m_vecOrigin",endorg);
									float angs[3];
									if (HasEntProp(EndTarg[client],Prop_Data,"m_angAbsRotation")) GetEntPropVector(EndTarg[client],Prop_Data,"m_angAbsRotation",angs);
									DispatchKeyValue(effect,"effect_name","gluon_beam_burst");
									DispatchKeyValue(effect,"start_active","1");
									TeleportEntity(effect,endorg,angs,NULL_VECTOR);
									DispatchSpawn(effect);
									ActivateEntity(effect);
									AcceptEntityInput(effect,"Start");
									int entindx = EntIndexToEntRef(effect);
									CreateTimer(0.5,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
									int beam = GetEntPropEnt(EndTarg[client],Prop_Data,"m_hEffectEntity");
									if ((beam != 0) && (IsValidEntity(beam)))
									{
										int beam2 = GetEntPropEnt(beam,Prop_Data,"m_hEffectEntity");
										if ((beam2 != 0) && (IsValidEntity(beam2))) AcceptEntityInput(beam2,"kill");
										AcceptEntityInput(beam,"kill");
									}
									if ((HandAttach[client] != 0) && (IsValidEntity(HandAttach[client])))
									{
										int sprite = GetEntPropEnt(HandAttach[client],Prop_Data,"m_hEffectEntity");
										if ((sprite != 0) && (IsValidEntity(sprite)))
										{
											AcceptEntityInput(sprite,"kill");
											AcceptEntityInput(HandAttach[client],"kill");
											HandAttach[client] = 0;
										}
									}
									AcceptEntityInput(EndTarg[client],"kill");
								}
								EndTarg[client] = 0;
							}
						}
					}
				}
			}
			else if ((StrEqual(curweap,"weapon_hivehand",false)) || (StrEqual(curweap,"weapon_hornetgun",false)))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if ((seq != 0) && (seq != 4) && (seq != 3))
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
				}
			}
			else if (StrEqual(curweap,"weapon_handgrenade",false))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int curamm = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
						if (seq == 2)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(3,5));
							SetEntProp(client,Prop_Data,"m_iAmmo",curamm-1,_,12);
							WeapAttackSpeed[client] = GetTickedTime()+1.0;
							CreateTimer(0.5,resetviewmdl,viewmdl);
							CreateTimer(1.0,resetviewmdl,viewmdl);
							float targpos[3];
							float shootvel[3];
							float plyfirepos[3];
							float plyang[3];
							float maxscaler = 800.0;
							float sideadj = -10.0;
							GetClientEyeAngles(client,plyang);
							plyang[1]+=sideadj;
							GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
							plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
							plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
							if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
							else plyfirepos[2]+=48.0;
							plyang[1]-=sideadj;
							TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
							TR_GetEndPosition(targpos);
							float chkdist = GetVectorDistance(plyfirepos,targpos,false);
							if (chkdist < 200.0) targpos[2]+=60.0;
							else targpos[2]+=20.0;
							MakeVectorFromPoints(plyfirepos,targpos,shootvel);
							ScaleVector(shootvel,2.5);
							if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
							{
								while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
								{
									ScaleVector(shootvel,0.95);
								}
							}
							int grenade = CreateEntityByName("prop_physics_override");
							if (grenade != -1)
							{
								DispatchKeyValue(grenade,"classname","grenade_frag");
								DispatchKeyValue(grenade,"model","models/items/357ammobox.mdl");
								DispatchKeyValue(grenade,"solid","6");
								DispatchKeyValue(grenade,"spawnflags","256");
								TeleportEntity(grenade,plyfirepos,plyang,NULL_VECTOR);
								DispatchSpawn(grenade);
								ActivateEntity(grenade);
								if (!IsModelPrecached("models/w_grenade.mdl")) PrecacheModel("models/w_grenade.mdl",true);
								SetEntityModel(grenade,"models/w_grenade.mdl");
								if (HasEntProp(grenade,Prop_Data,"m_CollisionGroup")) SetEntProp(grenade,Prop_Data,"m_CollisionGroup",5);
								TeleportEntity(grenade,NULL_VECTOR,NULL_VECTOR,shootvel);
								int endpoint = CreateEntityByName("env_explosion");
								if (endpoint != -1)
								{
									char dmgmag[8] = "300";
									char radius[8] = "150";
									Handle cvar = FindConVar("sk_plr_dmg_handgrenade");
									if (cvar != INVALID_HANDLE) GetConVarString(cvar,dmgmag,sizeof(dmgmag));
									cvar = FindConVar("sk_grenade_radius");
									if (cvar != INVALID_HANDLE) GetConVarString(cvar,radius,sizeof(radius));
									CloseHandle(cvar);
									DispatchKeyValue(endpoint,"imagnitude",dmgmag);
									DispatchKeyValue(endpoint,"iRadiusOverride",radius);
									DispatchKeyValue(endpoint,"rendermode","0");
									DispatchKeyValue(endpoint,"OnUser4","!self,Explode,,4,-1");
									plyfirepos[2]+=2.0;
									TeleportEntity(endpoint,plyfirepos,plyang,NULL_VECTOR);
									DispatchSpawn(endpoint);
									ActivateEntity(endpoint);
									SetVariantString("!activator");
									AcceptEntityInput(endpoint,"SetParent",grenade);
									AcceptEntityInput(endpoint,"FireUser4",grenade);
									SetEntPropEnt(grenade,Prop_Data,"m_hOwnerEntity",endpoint);
									SetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity",client);
									CreateTimer(4.0,GrenadeExpl,grenade,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
						}
					}
				}
			}
			else if (StrEqual(curweap,"weapon_oicw",false))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					SetEntProp(weap,Prop_Data,"m_nShotsFired",0);
				}
			}
		}
		if (!(buttons & IN_ATTACK2))
		{
			if (((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false))) && (TauCharge[client] > 0))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int mdlseq = 4;
						int mdlseq2 = 4;
						int mdlseqfire = 7;
						int taubeammdl = taubeam;
						int posside = 8;
						float posz = 12.0;
						char mdl[64];
						char snd[64];
						char stopsnd[64];
						char beammdl[64];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						Format(snd,sizeof(snd),"weapons\\tau\\gauss_overcharged.wav");
						Format(stopsnd,sizeof(stopsnd),"weapons\\tau\\gauss_spinup.wav");
						Format(beammdl,sizeof(beammdl),"effects/tau_beam.vmt");
						if (StrEqual(mdl,"models/v_gauss.mdl",false))
						{
							Format(snd,sizeof(snd),"weapons\\gauss2.wav");
							Format(stopsnd,sizeof(stopsnd),"ambience\\pulsemachine.wav");
							mdlseq2 = 3;
							mdlseq = 4;
							mdlseqfire = 5;
							taubeammdl = tauhl1beam;
							Format(beammdl,sizeof(beammdl),"sprites/smoke.vmt");
						}
						else if (StrEqual(mdl,"models/weapons/v_gauss_suit.mdl",false))
						{
							Format(snd,sizeof(snd),"weapons\\gauss\\fire1.wav");
							Format(stopsnd,sizeof(stopsnd),"weapons\\gauss\\chargeloop.wav");
							taubeammdl = tauhl2beam;
							Format(beammdl,sizeof(beammdl),"sprites/laserbeam.vmt");
							posside = 5;
							posz = 8.0;
						}
						if ((seq == mdlseq) || (seq == mdlseq2))
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseqfire);
							StopSound(weap,SNDCHAN_WEAPON,stopsnd);
							EmitSoundToAll(snd, weap, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
							float endpos[3];
							float plyfirepos[3];
							float plyang[3];
							GetClientEyeAngles(client,plyang);
							GetClientEyePosition(client,plyfirepos);
							TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
							TR_GetEndPosition(endpos);
							float dmg = 20.0;
							Handle cvar = FindConVar("sk_plr_dmg_tau");
							if (cvar != INVALID_HANDLE) dmg = GetConVarFloat(cvar);
							CloseHandle(cvar);
							int beam = CreateEntityByName("beam");
							if (beam != -1)
							{
								DispatchKeyValue(beam,"model",beammdl);
								DispatchKeyValue(beam,"texture",beammdl);
								SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
								SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
								SetVariantString("OnUser4 !self:kill::0.1:-1")
								AcceptEntityInput(beam,"addoutput");
								AcceptEntityInput(beam,"FireUser4");
								plyang[1]-=90.0;
								plyfirepos[0] = (plyfirepos[0] + (posside * Cosine(DegToRad(plyang[1]))));
								plyfirepos[1] = (plyfirepos[1] + (posside * Sine(DegToRad(plyang[1]))));
								plyang[1]+=90.0;
								plyfirepos[0] = (plyfirepos[0] + (8 * Cosine(DegToRad(plyang[1]))));
								plyfirepos[1] = (plyfirepos[1] + (8 * Sine(DegToRad(plyang[1]))));
								plyfirepos[2]-=posz;
								TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
								DispatchSpawn(beam);
								ActivateEntity(beam);
								SetEntityRenderColor(beam,255,255,GetRandomInt(150,220),255);
								SetEntProp(beam,Prop_Data,"m_nBeamType",1);
								SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
								SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
								//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",HandAttach[client],0);
								//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",client,0);
								//int handatt = GetEntProp(weap,Prop_Data,"m_iParentAttachment");
								//SetEntProp(beam,Prop_Data,"m_nAttachIndex",handatt,0);
								//SetEntPropEnt(beam,Prop_Data,"m_hAttachEntity",EndTarg[client],1);
								//SetEntPropEnt(beam,Prop_Data,"m_hEndEntity",EndTarg[client]);
								SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
								SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",2.0);
								SetEntPropFloat(beam,Prop_Data,"m_fWidth",4.0);
								SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",8.0);
								SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
								SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
								SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
								SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
								SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
								for (int i = 0;i<3;i++)
								{
									beam = CreateEntityByName("beam");
									if (beam != -1)
									{
										DispatchKeyValue(beam,"model",beammdl);
										DispatchKeyValue(beam,"texture",beammdl);
										SetEntProp(beam,Prop_Data,"m_nModelIndex",taubeammdl);
										SetEntProp(beam,Prop_Data,"m_nHaloIndex",taubeammdl);
										TeleportEntity(beam,plyfirepos,plyang,NULL_VECTOR);
										DispatchSpawn(beam);
										ActivateEntity(beam);
										SetVariantString("OnUser4 !self:kill::0.1:-1")
										AcceptEntityInput(beam,"addoutput");
										AcceptEntityInput(beam,"FireUser4");
										SetEntityRenderColor(beam,255,255,GetRandomInt(150,220),255);
										SetEntProp(beam,Prop_Data,"m_nBeamType",1);
										SetEntProp(beam,Prop_Data,"m_nBeamFlags",0);
										SetEntProp(beam,Prop_Data,"m_nNumBeamEnts",2);
										SetEntPropVector(beam,Prop_Data,"m_vecEndPos",endpos);
										SetEntPropFloat(beam,Prop_Data,"m_fAmplitude",GetRandomFloat(8.0,15.0));
										SetEntPropFloat(beam,Prop_Data,"m_fWidth",GetRandomFloat(1.0,6.0));
										SetEntPropFloat(beam,Prop_Data,"m_fEndWidth",8.0);
										SetEntPropFloat(beam,Prop_Data,"m_fSpeed",20.0);
										SetEntPropFloat(beam,Prop_Data,"m_flFrameRate",20.0);
										SetEntPropFloat(beam,Prop_Data,"m_flHDRColorScale",1.0);
										SetEntProp(beam,Prop_Data,"m_nDissolveType",-1);
										SetEntProp(beam,Prop_Data,"m_nRenderMode",2);
									}
								}
								int ent = CreateEntityByName("env_physexplosion");
								if(ent != -1)
								{
									float magnitude = dmg*TauCharge[client];
									DispatchKeyValueFloat(ent,"magnitude",magnitude);
									DispatchKeyValue(ent,"radius","256");
									DispatchKeyValue(ent,"inner_radius","0");
									DispatchKeyValue(ent,"spawnflags","10");
									TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(ent);
									SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
									AcceptEntityInput(ent,"Explode");
									AcceptEntityInput(ent,"Kill");
								}
								int decal = CreateEntityByName("infodecal");
								if (decal != -1)
								{
									DispatchKeyValue(decal,"texture","decals/scorch2");
									DispatchKeyValue(decal,"LowPriority","1");
									TeleportEntity(decal,endpos,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(decal);
									ActivateEntity(decal);
									AcceptEntityInput(decal,"Activate");
								}
								int effect = CreateEntityByName("env_sprite");
								if (effect != -1)
								{
									DispatchKeyValue(effect,"model","sprites/glow01.spr");
									DispatchKeyValue(effect,"scale","1.0");
									DispatchKeyValue(effect,"GlowProxySize","9");
									DispatchKeyValue(effect,"rendermode","9");
									DispatchKeyValue(effect,"rendercolor","200 200 0");
									TeleportEntity(effect,endpos,plyang,NULL_VECTOR);
									DispatchSpawn(effect);
									ActivateEntity(effect);
									AcceptEntityInput(effect,"Activate");
									SetVariantString("OnUser4 !self:kill::0.1:-1")
									AcceptEntityInput(effect,"addoutput");
									AcceptEntityInput(effect,"FireUser4");
								}
							}
							if (tauknockback)
							{
								float launch[3];
								GetAngleVectors(plyang, launch, NULL_VECTOR, NULL_VECTOR);
								ScaleVector(launch,-(dmg*TauCharge[client]));
								launch[2]+=(dmg/2)*TauCharge[client];
								TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,launch);
							}
							TauCharge[client] = 0;
							WeapAttackSpeed[client] = GetTickedTime()+1.0;
						}
					}
				}
			}
		}
		if (buttons & IN_RELOAD)
		{
			if (!(g_LastButtons[client] & IN_RELOAD))
			{
				if (StrEqual(curweap,"weapon_flaregun",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						if ((GetEntProp(weap,Prop_Data,"m_iClip1") < 1) && (flareammo[client] > 0))
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								int mdlseq = 1;
								char mdl[64];
								GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (!StrEqual(mdl,"models/weapons/v_flaregun.mdl",false))
									mdlseq = 2;
								if (seq != mdlseq)
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
									ChangeEdictState(viewmdl);
									CreateTimer(2.2,resetviewmdl,viewmdl,TIMER_FLAG_NO_MAPCHANGE);
									if (FileExists("sound/weapons/flaregun/flaregun_reload.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\flaregun\\flaregun_reload.wav", weap, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
								}
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_glock",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						if (GetEntProp(client,Prop_Send,"m_iAmmo",_,3) > 0)
						{
							int maxclip = 17;
							if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0)) maxclip = 15;
							if (GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									char mdl[32];
									GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
									if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
									{
										if ((seq != 5) && (seq != 6))
										{
											SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(5,6));
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
										}
									}
									else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
										if (FileExists("sound/weapons/pistol/glock_reload1.wav",true,NULL_STRING))
										{
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\pistol\\glock_reload1.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
									else if ((seq != 6) && (seq != 7))
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",GetRandomInt(6,7));
										if (FileExists("sound/weapons/glock/reload.wav",true,NULL_STRING))
										{
											StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
											EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										}
									}
								}
							}
							else
							{
								StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
								SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
								SetEntProp(weap,Prop_Data,"m_bInReload",0);
								CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
							}
							setbuttons = false;
						}
					}
				}
				else if ((StrEqual(curweap,"weapon_mp5",false)) || (StrEqual(curweap,"weapon_m4",false)) || (StrEqual(curweap,"weapon_g36c",false)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						if (GetEntProp(client,Prop_Send,"m_iAmmo",_,4) > 0)
						{
							int mdlseq = 2;
							int maxclip = 30;
							char snd[64];
							char mdl[32];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_9mmAR.mdl",false))
							{
								mdlseq = 3;
								maxclip = 50;
								Format(snd,sizeof(snd),"weapons\\reload3.wav");
							}
							else if (StrEqual(mdl,"models/weapons/v_m4m203.mdl",false))
							{
								mdlseq = 7;
								Format(snd,sizeof(snd),"weapons\\m4\\m4_reload.wav");
							}
							else if (StrEqual(curweap,"weapon_g36c",false))
							{
								mdlseq = 9;
								Format(snd,sizeof(snd),"weapons\\g36c\\g36c_reload.wav");
							}
							else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
							{
								mdlseq = 9;
								Format(snd,sizeof(snd),"weapons\\mp5\\mp5_reload.wav");
							}
							else if (FileExists("sound/weapons/mp5/reload.wav",true,NULL_STRING)) Format(snd,sizeof(snd),"weapons\\mp5\\reload.wav");
							if (GetEntProp(weap,Prop_Data,"m_iClip1") < maxclip)
							{
								int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
								if (viewmdl != -1)
								{
									int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
									if (seq != mdlseq)
									{
										SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
										StopSound(client,SNDCHAN_ITEM,"weapons/smg1/smg1_reload.wav");
										if (strlen(snd) > 0) EmitSoundToAll(snd, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
									}
								}
							}
							else
							{
								SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
								SetEntProp(weap,Prop_Data,"m_bInReload",0);
								CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
								SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_hivehand",false))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (weap != -1)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1)
						{
							int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
							if (seq != 4)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
								CreateTimer(21.0,resetviewmdl,viewmdl);
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_colt",false))
				{
					if (GetEntProp(client,Prop_Send,"m_iAmmo",_,3) > 0)
					{
						int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
								int maxclip = 8;
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if ((seq != 4) && (clip < maxclip))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
									CreateTimer(2.0,resetviewmdl,viewmdl);
								}
								else if (seq != 4)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
									SetEntProp(weap,Prop_Data,"m_bInReload",0);
									CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
									StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
									setbuttons = false;
								}
								
							}
						}
					}
				}
				else if (StrEqual(curweap,"weapon_dualmp5k",false))
				{
					if (GetEntProp(client,Prop_Send,"m_iAmmo",_,4) > 0)
					{
						int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
							if (viewmdl != -1)
							{
								int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
								int maxclip = 64;
								int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
								if ((seq != 8) && (clip < maxclip))
								{
									SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
								}
								else if (seq != 8)
								{
									SetEntProp(weap,Prop_Data,"m_iClip1",maxclip);
									SetEntProp(weap,Prop_Data,"m_bInReload",0);
									CreateTimer(0.1,resetinreload,weap,TIMER_FLAG_NO_MAPCHANGE);
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",0.0);
									StopSound(client,SNDCHAN_ITEM,"weapons/pistol/pistol_reload1.wav");
									setbuttons = false;
								}
							}
						}
					}
				}
			}
		}
		if (buttons & IN_USE)
		{
			if (!(g_LastButtons[client] & IN_RELOAD))
			{
				int targ = GetClientAimTarget(client,false);
				if (targ != -1)
				{
					char cls[32];
					GetEntityClassname(targ,cls,sizeof(cls));
					if (StrEqual(cls,"grenade_satchel",false))
					{
						int owner = -1;
						int expl = GetEntPropEnt(targ,Prop_Data,"m_hOwnerEntity");
						if (expl != -1) owner = GetEntPropEnt(expl,Prop_Data,"m_hOwnerEntity");
						if (owner == client)
						{
							float orgs[3];
							float proporgs[3];
							if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
							else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",proporgs);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",proporgs);
							float chkdist = GetVectorDistance(orgs,proporgs,false);
							if (chkdist < 80.0)
							{
								//plays on same channel as USE EmitGameSoundToAll("HL2Player.PickupWeapon",client);
								int sndlvl,pitch,channel;
								float vol;
								char snd[64];
								if (GetGameSoundParams("HL2Player.PickupWeapon",channel,sndlvl,vol,pitch,snd,sizeof(snd),client))
								{
									EmitSoundToAll(snd, client, SNDCHAN_AUTO, sndlvl, _, vol, pitch);
								}
								Handle pickuph = StartMessageOne("ItemPickup",client);
								BfWriteString(pickuph,"weapon_pistol");
								EndMessage();
								AcceptEntityInput(targ,"kill");
								SatchelAmm[client]++;
								if (StrEqual(curweap,"weapon_satchel",false))
								{
									int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
									if (weap != -1)
									{
										SetEntProp(weap,Prop_Data,"m_iClip1",SatchelAmm[client]);
									}
								}
							}
						}
					}
				}
			}
		}
		if (setbuttons) g_LastButtons[client] = buttons;
	}
	else if (FindStringInArray(sweps,curweap) != -1)
	{
		int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
		if (viewmdl != -1)
		{
			int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
			if ((StrEqual(curweap,"weapon_flaregun",false)) || (StrEqual(curweap,"weapon_medkit",false)))
			{
				if (seq != 4) SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
			}
			else if (StrEqual(curweap,"weapon_manhack",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_manhackgun",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_manhacktoss",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);//need to check
			}
			else if (StrEqual(curweap,"weapon_immolator",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);//need to check
			}
			else if (StrEqual(curweap,"weapon_snark",false))
			{
				if (seq != 6) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
			}
			else if (StrEqual(curweap,"weapon_mp5",false))
			{
				if (seq != 7) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
			}
			else if ((StrEqual(curweap,"weapon_sl8",false)) || (StrEqual(curweap,"weapon_cguard",false)) || (StrEqual(curweap,"weapon_g36c",false)))
			{
				if (seq != 0) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1) SetEntProp(weap,Prop_Data,"m_fEffects",161);
			}
			else if (StrEqual(curweap,"weapon_m4",false))
			{
				SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
			}
			else if (StrEqual(curweap,"weapon_oicw",false))
			{
				if (seq != 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
			}
			else if (StrEqual(curweap,"weapon_glock",false))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
					{
						if (seq != 8) SetEntProp(viewmdl,Prop_Send,"m_nSequence",8);
					}
					else if ((StrContains(mapbuf,"wc_0",false) == 0) || (StrContains(mapbuf,"wc_intro",false) == 0))
					{
						if (seq != 10) SetEntProp(viewmdl,Prop_Send,"m_nSequence",10);
					}
					else
					{
						if (seq != 9) SetEntProp(viewmdl,Prop_Send,"m_nSequence",9);
					}
				}
			}
			else if (StrEqual(curweap,"weapon_tripmine",false))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					int mdlseq = 7;
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_tripmine.mdl",false)) mdlseq = 5;
					if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
				}
			}
			else if (StrEqual(curweap,"weapon_satchel",false))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (weap != -1)
				{
					int mdlseq = 5;
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_satchel.mdl",false)) mdlseq = 3;
					if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
				}
			}
			else if (StrEqual(curweap,"weapon_handgrenade",false))
			{
				int mdlseq = 6;
				if (seq != mdlseq) SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlseq);
			}
			else if (StrEqual(curweap,"weapon_gauss",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_tau",false))
			{
				if (seq != 5) SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
			}
			else if (StrEqual(curweap,"weapon_gluon",false))
			{
				if (seq != 3) SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
			}
		}
	}
	return Plugin_Continue;
}

public Action resetinreload(Handle timer, int weap)
{
	if (IsValidEntity(weap))
	{
		char curweap[64];
		GetEntityClassname(weap,curweap,sizeof(curweap));
		if (HasEntProp(weap,Prop_Data,"m_bInReload")) SetEntProp(weap,Prop_Data,"m_bInReload",0);
		if (StrEqual(curweap,"weapon_mp5",false))
		{
			SetEntProp(weap,Prop_Data,"m_iClip1",30);
			int owner = GetEntPropEnt(weap,Prop_Data,"m_hOwner");
			if ((owner > 0) && (owner < MaxClients+1) && (IsValidEntity(owner)))
			{
				int viewmdl = GetEntPropEnt(owner,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
				{
					SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
				}
			}
		}
	}
}

public OnClientPutInServer(int client)
{
	CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
}

public Action clspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponUse);
		flareammo[client] = 5;
		ManHackAmmo[client] = 1;
		CGuardAmm[client] = 5;
		EnergyAmm[client] = 40;
		HiveAmm[client] = 100;
		SnarkAmm[client] = 5;
		SatchelAmm[client] = 2;
		TripMineAmm[client] = 2;
		Ammo12Reset[client] = 0;
		Ammo24Reset[client] = 0;
		GetClientAuthId(client,AuthId_Steam2,SteamID[client],32-1);
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(0.5,clspawnpost,client);
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if ((client > 0) && (client < MaxClients+1))
	{
		flareammo[client] = 5;
		ManHackAmmo[client] = 1;
		CGuardAmm[client] = 5;
		EnergyAmm[client] = 40;
		HiveAmm[client] = 100;
		SnarkAmm[client] = 5;
		SatchelAmm[client] = 2;
		TripMineAmm[client] = 2;
		Ammo3Reset[client] = 0;
		Ammo12Reset[client] = 0;
		Ammo24Reset[client] = 0;
	}
	return Plugin_Continue;
}

public Action OnWeaponUse(int client, int weapon)
{
	if (IsValidEntity(client))
	{
		if (Ammo3Reset[client] > 0)
		{
			SetEntProp(client,Prop_Data,"m_iAmmo",Ammo3Reset[client],_,3);
			Ammo3Reset[client] = 0;
		}
		if (Ammo12Reset[client] > 0)
		{
			SetEntProp(client,Prop_Data,"m_iAmmo",Ammo12Reset[client],_,12);
			Ammo12Reset[client] = 0;
		}
		if (Ammo24Reset[client] > -1)
		{
			SetEntProp(client,Prop_Data,"m_iAmmo",Ammo24Reset[client],_,24);
			Ammo24Reset[client] = 0;
		}
		if ((SL8Scope != 0) && (IsValidEntity(SL8Scope)) && (CLInScope[client] == SL8Scope))
		{
			AcceptEntityInput(SL8Scope,"StopOverlays",client);
			CLInScope[client] = 0;
		}
		if ((OICWScope != 0) && (IsValidEntity(OICWScope)) && (CLInScope[client] == OICWScope))
		{
			AcceptEntityInput(OICWScope,"StopOverlays",client);
			CLInScope[client] = 0;
		}
		TauCharge[client] = 0;
		if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
		if (WeapList != -1)
		{
			for (int j; j<104; j += 4)
			{
				int tmpi = GetEntDataEnt2(client,WeapList + j);
				if (tmpi != -1)
				{
					if (HasEntProp(tmpi,Prop_Data,"m_nViewModelIndex"))
					{
						if (GetEntProp(tmpi,Prop_Data,"m_nViewModelIndex") == 1)
						{
							SetEntProp(tmpi,Prop_Data,"m_nViewModelIndex",0);
							ChangeEdictState(tmpi);
							char weapcls[64];
							GetEntityClassname(tmpi,weapcls,sizeof(weapcls));
							if (FindStringInArray(sweps,weapcls) != -1) SetEntProp(tmpi,Prop_Data,"m_fEffects",161);
						}
					}
				}
			}
		}
		int fov = GetEntProp(client,Prop_Send,"m_iFOV");
		if ((fov < 75) && (fov != 0))
		{
			SetEntProp(client,Prop_Send,"m_iFOVStart",fov);
			SetEntPropFloat(client,Prop_Send,"m_flFOVTime",GetGameTime());
			SetEntProp(client,Prop_Send,"m_iFOV",90);
			SetEntPropFloat(client,Prop_Send,"m_flFOVRate",0.4);
		}
		if ((IsValidEntity(weapon)) && (weapon != -1))
		{
			char weapname[32];
			GetEntityClassname(weapon,weapname,sizeof(weapname));
			if ((StrEqual(weapname,"weapon_snark",false)) || (StrEqual(weapname,"weapon_satchel",false)) || (StrEqual(weapname,"weapon_frag",false)) || (StrEqual(weapname,"weapon_tripmine",false)))
			{
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1) SetEntProp(viewmdl,Prop_Send,"m_nBody",1);
			}
			if (StrEqual(weapname,"weapon_flaregun",false))
			{
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",0);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",3);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,3);
				if (ammover > 0)
				{
					Ammo3Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",flareammo[client],_,3);
				}
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				//SetEntProp(weapon,Prop_Data,"m_iParentAttachment",3);
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				char mdl[64];
				GetEntPropString(weapon,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (!StrEqual(mdl,"models/weapons/v_flaregun.mdl",false))
				{
					float angset[3];
					angset[0] = -90.0;
					angset[1] = 90.0;
					SetEntPropVector(weapon,Prop_Data,"m_angRotation",angset);
				}
			}
			else if ((StrEqual(weapname,"weapon_manhacktoss",false)) || (StrEqual(weapname,"weapon_manhack",false)))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",0);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				//SetEntProp(weapon,Prop_Data,"m_iParentAttachment",3);
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				float angset[3];
				angset[0] = 90.0;
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				if ((CLManhack[client] != 0) && (IsValidEntity(CLManhack[client])))
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
						CreateTimer(0.1,resetviewmdl,viewmdl);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
			}
			else if (StrEqual(weapname,"weapon_medkit",false))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",1);
				SetEntProp(weapon,Prop_Data,"m_bFireOnEmpty",1);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				SetEntProp(weapon,Prop_Data,"m_iClip1",1);
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Send,"m_iAmmo",1,_,24);
			}
			else if (StrEqual(weapname,"weapon_cguard",false))
			{
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_gluon",false))
			{
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",0);
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 35.0;
				orgreset[1] = 22.0;
				orgreset[2] = -20.0;
				angreset[0] = -50.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.2,resetviewmdl,viewmdl);
				if (FindStringInArray(precachedarr,"weapon_gluon") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/gluon/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_gluon");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
			}
			else if ((StrEqual(weapname,"weapon_tau",false)) || (StrEqual(weapname,"weapon_gauss",false)))
			{
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				float orgreset[3];
				float angreset[3];
				char mdl[64];
				GetEntPropString(weapon,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (StrEqual(mdl,"models/v_gauss.mdl",false))
				{
					orgreset[2] = -5.0;
					angreset[0] = 10.0;
					angreset[1] = 180.0;
					SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.9);
				}
				else
				{
					orgreset[2] = -5.0;
					angreset[0] = -20.0;
				}
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				if (FindStringInArray(precachedarr,"weapon_tau") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/tau/");
					recursion(searchprecache);
					if (FileExists("sound/ambience/pulsemachine.wav",true,NULL_STRING)) PrecacheSound("ambience\\pulsemachine.wav",true);
					if (FileExists("sound/weapons/gauss2.wav",true,NULL_STRING)) PrecacheSound("weapons\\gauss2.wav",true);
					if (FileExists("sound/weapons/gauss/fire1.wav",true,NULL_STRING)) PrecacheSound("weapons\\gauss\\fire1.wav",true);
					if (FileExists("sound/weapons/gauss/chargeloop.wav",true,NULL_STRING)) PrecacheSound("weapons\\gauss\\chargeloop.wav",true);
					PushArrayString(precachedarr,"weapon_tau");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",EnergyAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
			}
			else if (StrEqual(weapname,"weapon_glock",false))
			{
				if (FindStringInArray(precachedarr,"weapon_glock") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/glock/");
					recursion(searchprecache);
					PrecacheSound("weapons/pistol/pistol_fire2.wav",true);
					PrecacheSound("weapons/pistol/pistol_reload1.wav",true);
					if (FileExists("sound/weapons/pl_gun1.wav",true,NULL_STRING)) PrecacheSound("weapons\\pl_gun1.wav",true);
					if (FileExists("sound/weapons/pl_gun2.wav",true,NULL_STRING)) PrecacheSound("weapons\\pl_gun2.wav",true);
					if (FileExists("sound/weapons/pl_gun3.wav",true,NULL_STRING)) PrecacheSound("weapons\\pl_gun3.wav",true);
					if (FileExists("sound/weapons/reload1.wav",true,NULL_STRING))
					{
						PrecacheSound("weapons\\reload1.wav",true);
						PrecacheSound("weapons\\reload2.wav",true);
						PrecacheSound("weapons\\reload3.wav",true);
					}
					if (FileExists("sound/weapons/pistol/glock_fire.wav",true,NULL_STRING))
					{
						Format(searchprecache,sizeof(searchprecache),"sound/weapons/pistol/");
						recursion(searchprecache);
					}
					PushArrayString(precachedarr,"weapon_glock");
				}
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",3);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				char mdl[64];
				GetEntPropString(weapon,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				if (StrEqual(mdl,"models/v_9mmhandgun.mdl",false))
				{
					int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
					if (viewmdl != -1)
					{
						int bodygrp = GetEntProp(viewmdl,Prop_Send,"m_nBody");
						if (bodygrp != CLAttachment[client])
						{
							SetEntProp(viewmdl,Prop_Send,"m_nBody",CLAttachment[client]);
						}
					}
				}
			}
			else if ((StrEqual(weapname,"weapon_mp5",false)) || (StrEqual(weapname,"weapon_m4",false)))
			{
				if (FindStringInArray(precachedarr,"weapon_mp5") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/mp5/");
					recursion(searchprecache);
					PrecacheSound("weapons/smg1/smg1_fire1.wav",true);
					PrecacheSound("weapons/smg1/smg1_reload.wav",true);
					if (FileExists("sound/weapons/hks1.wav",true,NULL_STRING))
					{
						PrecacheSound("weapons\\hks1.wav",true);
						PrecacheSound("weapons\\hks2.wav",true);
						PrecacheSound("weapons\\hks3.wav",true);
						PrecacheSound("weapons\\reload3.wav",true);
					}
					if (FileExists("sound/weapons/m4/m4_fire.wav",true,NULL_STRING))
					{
						PrecacheSound("weapons\\m4\\m4_reload.wav",true);
						PrecacheSound("weapons\\m4\\m4_altfire.wav",true);
						PrecacheSound("weapons\\m4\\m4_fire.wav",true);
					}
					PushArrayString(precachedarr,"weapon_mp5");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",4);
				if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",9);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_g36c",false))
			{
				if (FindStringInArray(precachedarr,"weapon_g36c") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/g36c/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_g36c");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",1);
				if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",-1);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.3,resetviewmdl,viewmdl);
			}
			else if ((StrEqual(weapname,"weapon_sl8",false)) || (StrEqual(weapname,"weapon_oicw",false)))
			{
				if (FindStringInArray(precachedarr,"weapon_sl8") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/sl8/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_sl8");
				}
				if (FindStringInArray(precachedarr,"weapon_oicw") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/oicw/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_oicw");
				}
				SetEntProp(weapon,Prop_Data,"m_fEffects",129);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",4);
				if (HasEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",-1);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if ((StrEqual(weapname,"weapon_hivehand",false)) || (StrEqual(weapname,"weapon_hornetgun",false)))
			{
				if (FindStringInArray(precachedarr,"weapon_hivehand") == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/hivehand/");
					recursion(searchprecache);
					Format(searchprecache,sizeof(searchprecache),"sound/hornet/");
					recursion(searchprecache);
					PushArrayString(precachedarr,"weapon_hivehand");
				}
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",HiveAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",HiveAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				SetEntProp(weapon,Prop_Data,"m_bFiresUnderwater",1);
				SetEntProp(weapon,Prop_Data,"m_bFireOnEmpty",1);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,24);
				if (ammover > -1)
				{
					Ammo24Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				}
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 5.0;
				orgreset[1] = 3.0;
				angreset[1] = 30.0;
				if (StrEqual(weapname,"weapon_hornetgun",false))
				{
					angreset[1] = 215.0;
					orgreset[0] = 4.0;
					orgreset[1] = 1.0;
					orgreset[2] = -4.0;
					SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.6);
				}
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_snark",false))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",SnarkAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",SnarkAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.5);
				SetEntPropFloat(weapon,Prop_Data,"m_flTimeWeaponIdle",0.0);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				float orgreset[3];
				orgreset[1] = 2.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_satchel",false))
			{
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",SatchelAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",SatchelAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				SetVariantString("anim_attachment_LH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.5);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 2.7;
				orgreset[1] = 1.0;
				angreset[0] = 90.0;
				angreset[1] = -45.0;
				angreset[2] = 45.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				SetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+100.0);
			}
			else if (StrEqual(weapname,"weapon_tripmine",false))
			{
				if (FindStringInArray(precachedarr,weapname) == -1)
				{
					char searchprecache[128];
					Format(searchprecache,sizeof(searchprecache),"sound/weapons/tripmine/");
					recursion(searchprecache);
					PrecacheSound("weapons\\mine_activate.wav",true);
					PrecacheSound("weapons\\mine_charge.wav",true);
					PrecacheSound("weapons\\mine_deploy.wav",true);
					PushArrayString(precachedarr,weapname);
				}
				SetEntProp(weapon,Prop_Data,"m_iSecondaryAmmoType",24);
				SetEntProp(weapon,Prop_Data,"m_bReloadsSingly",1);
				if (HasEntProp(weapon,Prop_Data,"m_iClip1")) SetEntProp(weapon,Prop_Data,"m_iClip1",TripMineAmm[client]);
				if (HasEntProp(weapon,Prop_Send,"m_iClip1")) SetEntProp(weapon,Prop_Send,"m_iClip1",TripMineAmm[client]);
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				int ammover = GetEntProp(client,Prop_Send,"m_iAmmo",_,12);
				if (ammover > 0)
				{
					Ammo12Reset[client] = ammover;
					SetEntProp(client,Prop_Data,"m_iAmmo",0,_,12);
				}
				if (GetEntProp(client,Prop_Send,"m_iAmmo",_,24) < 1) SetEntProp(client,Prop_Data,"m_iAmmo",1,_,24);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.5);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				float orgreset[3];
				float angreset[3];
				orgreset[0] = 2.0;
				orgreset[1] = 3.0;
				orgreset[2] = 1.0;
				angreset[1] = 180.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
			}
			else if (StrEqual(weapname,"weapon_handgrenade",false))
			{
				if (FindStringInArray(precachedarr,weapname) == -1)
				{
					PrecacheSound("weapons\\g_bounce1.wav",true);
					PrecacheSound("weapons\\g_bounce2.wav",true);
					PrecacheSound("weapons\\g_bounce3.wav",true);
					PrecacheSound("weapons\\g_bounce4.wav",true);
					PrecacheSound("weapons\\g_bounce5.wav",true);
					PushArrayString(precachedarr,weapname);
				}
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",12);
				SetVariantString("!activator");
				AcceptEntityInput(weapon,"SetParent",client);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				SetEntPropFloat(weapon,Prop_Data,"m_flModelScale",0.8);
				float orgreset[3];
				float angreset[3];
				orgreset[1] = 5.0;
				angreset[0] = 30.0;
				angreset[2] = 90.0;
				SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",orgreset);
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_357",false))
			{
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",5);
			}
			else if (StrEqual(weapname,"weapon_axe",false))
			{
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(weapon,"SetParentAttachment");
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
				float angreset[3];
				angreset[1] = 180.0;
				SetEntPropVector(weapon,Prop_Data,"m_angRotation",angreset);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
				int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
				if (viewmdl != -1)
					CreateTimer(0.1,resetviewmdl,viewmdl);
			}
			else if (StrEqual(weapname,"weapon_colt",false))
			{
				if (HasEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType")) SetEntProp(weapon,Prop_Data,"m_iPrimaryAmmoType",3);
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_dualmp5k",false))
			{
				SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",0);
				CreateTimer(0.1,resetviewindex,weapon,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(weapname,"weapon_immolator",false))
			{
				
			}
		}
	}
	return Plugin_Continue;
}

public Action resetviewmdl(Handle timer, int viewmdl)
{
	if ((IsValidEntity(viewmdl)) && (viewmdl != 0))
	{
		if (HasEntProp(viewmdl,Prop_Data,"m_hOwner"))
		{
			int client = GetEntPropEnt(viewmdl,Prop_Data,"m_hOwner");
			if (IsValidEntity(client))
			{
				int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				if (IsValidEntity(weap))
				{
					char curweap[24];
					GetClientWeapon(client,curweap,sizeof(curweap));
					if (StrEqual(curweap,"weapon_flaregun",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 3)
						{
							flareammo[client]--;
							SetEntProp(weap,Prop_Data,"m_iClip1",1);
							SetEntProp(client,Prop_Data,"m_iAmmo",flareammo[client],_,3);
						}
					}
					if ((StrEqual(curweap,"weapon_manhacktoss",false)) || (StrEqual(curweap,"weapon_manhackgun",false)) || (StrEqual(curweap,"weapon_manhack",false)))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 2)
						{
							ManHackAmmo[client]--;
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
							CreateTimer(0.5,resetviewmdl,viewmdl);
							if ((CLManhack[client] == 0) || (!IsValidEntity(CLManhack[client])))
							{
								float Time = GetTickedTime();
								clsummoncdc[client] = Time + 0.5;
								float PlayerOrigin[3];
								float clangles[3];
								GetClientEyeAngles(client, clangles);
								GetClientAbsOrigin(client, PlayerOrigin);
								PlayerOrigin[0] = (PlayerOrigin[0] + (40 * Cosine(DegToRad(clangles[1]))));
								PlayerOrigin[1] = (PlayerOrigin[1] + (40 * Sine(DegToRad(clangles[1]))));
								PlayerOrigin[2] = (PlayerOrigin[2] + 40);
								if ((clsummonfil == 0) || (!IsValidEntity(clsummonfil)))
								{
									clsummonfil = CreateEntityByName("filter_activator_class");
									DispatchKeyValue(clsummonfil,"filterclass","player");
									DispatchKeyValue(clsummonfil,"Negated","1");
									DispatchKeyValue(clsummonfil,"targetname","noplayer");
									DispatchSpawn(clsummonfil);
									ActivateEntity(clsummonfil);
								}
								int stuff = CreateEntityByName("npc_manhack");
								if (stuff != -1)
								{
									TeleportEntity(stuff, PlayerOrigin, clangles, NULL_VECTOR);
									DispatchKeyValue(stuff,"targetname",SteamID[client]);
									DispatchKeyValue(stuff,"spawnflags","65536");
									DispatchKeyValue(stuff,"ignoreclipbrushes","0");
									DispatchKeyValue(stuff,"damagefilter","noplrdmg");
									DispatchSpawn(stuff);
									ActivateEntity(stuff);
									if ((CLManhackRel == 0) || (!IsValidEntity(CLManhackRel)))
									{
										CLManhackRel = CreateEntityByName("ai_relationship");
										DispatchKeyValue(CLManhackRel,"disposition","3");
										DispatchKeyValue(CLManhackRel,"subject",SteamID[client]);
										DispatchKeyValue(CLManhackRel,"target","player");
										DispatchKeyValue(CLManhackRel,"rank","99");
										DispatchKeyValue(CLManhackRel,"reciprocal","1");
										DispatchKeyValue(CLManhackRel,"StartActive","1");
										DispatchSpawn(CLManhackRel);
										ActivateEntity(CLManhackRel);
										AcceptEntityInput(CLManhackRel,"ApplyRelationship");
									}
									else AcceptEntityInput(CLManhackRel,"ApplyRelationship");
									CreateTimer(0.5,unpack,stuff);
									CLManhack[client] = stuff;
								}
							}
						}
						if ((seq >= 4) && (seq <= 6))
						{
							if ((CLManhack[client] == 0) || (!IsValidEntity(CLManhack[client]))) SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
							else SetEntProp(viewmdl,Prop_Send,"m_nSequence",3);
						}
						if ((seq == 0) && (CLManhack[client] != 0) && (IsValidEntity(CLManhack[client])))
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
						}
					}
					else if (StrEqual(curweap,"weapon_gluon",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if ((seq == 0) || (seq == 2))
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
						}
						else SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if (StrEqual(curweap,"weapon_handgrenade",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq != 7)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
							//models/grenade.mdl -- starttouch bounce sounds -- env_explosion with ownerset
							//TR, shootvel, clamp max vel
						}
						else
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_satchel",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (SatchelAmm[client] == 0)
						{
							if (seq != 6) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
						}
						else if (seq == 2)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",5);
						}
						else
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_tripmine",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						int mdlseq = 6;
						int mdlreset = 9;
						int mdlout = 7;
						char mdl[32];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if (StrEqual(mdl,"models/v_tripmine.mdl",false))
						{
							mdlseq = 3;
							mdlreset = 6;
							mdlout = 5;
						}
						if (TripMineAmm[client] == 0)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlout);
						}
						else if (seq == mdlseq)
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",mdlreset);
							CreateTripMine(client);
						}
					}
					else if (StrEqual(curweap,"weapon_sl8",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						float Time = GetTickedTime();
						if ((seq == 2) && (WeapSnd[client] < Time))
						{
							EmitSoundToAll("weapons\\sl8\\sl8_magin.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							CreateTimer(0.7,resetviewmdl,viewmdl);
							WeapSnd[client] = Time+1.0;
						}
						else
						{
							EmitSoundToAll("weapons\\sl8\\sl8_boltback.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							SetEntProp(weap,Prop_Data,"m_bInReload",0);
							int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
							SetEntProp(weap,Prop_Data,"m_iClip1",20);
							int ammo = GetEntProp(client,Prop_Send,"m_iAmmo",_,4);
							SetEntProp(client,Prop_Data,"m_iAmmo",ammo-(20-clip),_,4);
						}
					}
					else if (StrEqual(curweap,"weapon_oicw",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (seq == 5)
						{
							SetEntProp(weap,Prop_Data,"m_bInReload",0);
							int clip = GetEntProp(weap,Prop_Data,"m_iClip1");
							SetEntProp(weap,Prop_Data,"m_iClip1",20);
							int ammo = GetEntProp(client,Prop_Send,"m_iAmmo",_,4);
							SetEntProp(client,Prop_Data,"m_iAmmo",ammo-(20-clip),_,4);
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_m4",false))
					{
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",4);
					}
					else if (StrEqual(curweap,"weapon_tau",false))
					{
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",1);
					}
					else if (StrEqual(curweap,"weapon_glock",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						char mdl[64];
						GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
						if ((seq == 9) && (StrEqual(mdl,"models/v_9mmhandgun.mdl",false)))
						{
							int bodygrp = GetEntProp(viewmdl,Prop_Send,"m_nBody");
							if (bodygrp == 1)
							{
								SetEntProp(viewmdl,Prop_Send,"m_nBody",0);
								CLAttachment[client] = 0;
							}
							else
							{
								SetEntProp(viewmdl,Prop_Send,"m_nBody",1);
								CLAttachment[client] = 1;
							}
						}
						else SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else if (StrEqual(curweap,"weapon_snark",false))
					{
						int seq = GetEntProp(viewmdl,Prop_Send,"m_nSequence");
						if (SnarkAmm[client] == 0)
						{
							if (seq != 6) SetEntProp(viewmdl,Prop_Send,"m_nSequence",6);
						}
						else
						{
							SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
						}
					}
					else if (StrEqual(curweap,"weapon_colt",false))
					{
						StopSound(client,SNDCHAN_WEAPON,"weapons/pistol/pistol_empty.wav");
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
					}
					else
						SetEntProp(viewmdl,Prop_Send,"m_nSequence",0);
				}
			}
		}
	}
}

public Action resetviewindex(Handle timer, int weapon)
{
	if (IsValidEntity(weapon))
	{
		if (HasEntProp(weapon,Prop_Data,"m_nViewModelIndex"))
		{
			SetEntProp(weapon,Prop_Data,"m_nViewModelIndex",1);
			char weapcls[32];
			GetEntityClassname(weapon,weapcls,sizeof(weapcls));
			if (StrEqual(weapcls,"weapon_tau",false))
			{
				SetEntProp(weapon,Prop_Data,"m_fEffects",16);
			}
		}
	}
}

public Action cstr(int client)
{
	if (client == 0)
		return Plugin_Handled;
	float Location[3];
	float fhitpos[3];
	float clangles[3];
	GetClientEyeAngles(client, clangles);
	GetClientEyePosition(client, Location);
	Location[0] = (Location[0] + (25 * Cosine(DegToRad(clangles[1]))));
	Location[1] = (Location[1] + (25 * Sine(DegToRad(clangles[1]))));
	//Location[2] = (Location[2] + 10);
	Handle hhitpos = INVALID_HANDLE;
	TR_TraceRay(Location,clangles,MASK_SHOT,RayType_Infinite);
	TR_GetEndPosition(fhitpos,hhitpos);
	fhitpos[2] = (fhitpos[2] + 15);
	CloseHandle(hhitpos);
	TE_SetupBeamPoints(Location, fhitpos, beamindx, haloindx, 1, 1, 1.2, 10.0, 10.0, 5, 20.0, {255, 255, 255, 255}, 1);
	TE_SendToAll();
	PrecacheSound("npc/strider/charging.wav");
	EmitSoundToAll("npc/strider/charging.wav", client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
	TE_SetupBeamRingPoint(Location, 1.0, 100.0, mdlus, mdlus3, 0, 10, 1.2, 20.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	int endpointe = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(endpointe,Location,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpointe,"scale","2.0");
	DispatchKeyValue(endpointe,"spawnflags","2");
	DispatchSpawn(endpointe);
	ActivateEntity(endpointe);
	SetVariantFloat(0.5);
	AcceptEntityInput(endpointe,"StartCharge");
	int entindx = EntIndexToEntRef(endpointe);
	CreateTimer(1.0,cleanup,entindx);
	Handle dp = CreateDataPack();
	WritePackCell(dp,client);
	WritePackFloat(dp,fhitpos[0]);
	WritePackFloat(dp,fhitpos[1]);
	WritePackFloat(dp,fhitpos[2]);
	CreateTimer(1.2,explcstr,dp);
	return Plugin_Handled;
}

public Action explcstr(Handle timer, Handle dp)
{
	if (dp == INVALID_HANDLE) return Plugin_Handled;
	ResetPack(dp);
	int client = ReadPackCell(dp);
	float fhitpos[3];
	fhitpos[0] = ReadPackFloat(dp);
	fhitpos[1] = ReadPackFloat(dp);
	fhitpos[2] = ReadPackFloat(dp);
	CloseHandle(dp);
	//TE_SetupGlowSprite(fhitpos,mdlus,0.5,10.0,50)
	//TE_SendToAll();
	TE_SetupBeamRingPoint(fhitpos, 16.0, 300.0, mdlus, mdlus3, 0, 2, 0.3, 128.0, 0.0, {255, 255, 255, 24}, 128, FBEAM_SHADEOUT);
	TE_SendToAll();
	float damageForce[3];
	damageForce[0]+=40.0;
	damageForce[1]+=40.0;
	damageForce[2]+=40.0;
	for (int i = 1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_dynamic",false) != -1) || (StrContains(clsname,"prop_physics",false) != -1))
			{
				float entpos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				float chkdist = GetVectorDistance(entpos,fhitpos,false);
				if ((RoundFloat(chkdist) < 150) && (!CheckNPCAlly(clsname,i)) && (IsValidEntity(i)))
				{
					SDKHooks_TakeDamage(i,client,client,300.0,DMG_BLAST|DMG_DISSOLVE,-1,damageForce,fhitpos);
				}
				else if (CheckNPCAlly(clsname,i))
				{
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				}
			}
			else if (StrEqual(clsname,"player",false))
			{
				float entpos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);
				float chkdist = GetVectorDistance(entpos,fhitpos,false);
				if ((RoundFloat(chkdist) < 150) && (IsValidEntity(i)) && (IsPlayerAlive(i)))
				{
					if (friendlyfire)
						SDKHooks_TakeDamage(i,client,client,300.0,DMG_BLAST|DMG_DISSOLVE,-1,damageForce,fhitpos);
				}
			}
		}
	}
	int endpointe = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(endpointe,fhitpos,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpointe,"scale","3.5");
	DispatchKeyValue(endpointe,"spawnflags","2");
	DispatchSpawn(endpointe);
	ActivateEntity(endpointe);
	int entindx = EntIndexToEntRef(endpointe);
	CreateTimer(0.4,cleanup,entindx);
	int endpoint = CreateEntityByName("env_explosion");
	TeleportEntity(endpoint,fhitpos,NULL_VECTOR,NULL_VECTOR);
	DispatchKeyValue(endpoint,"imagnitude","300");
	DispatchKeyValue(endpoint,"targetname","syn_stricann");
	DispatchKeyValue(endpoint,"iradiusoverride","150");
	DispatchKeyValue(endpoint,"spawnflags","348");
	DispatchKeyValue(endpoint,"fireballsprite","effects/strider_pinch_dudv.vmt");
	DispatchSpawn(endpoint);
	ActivateEntity(endpoint);
	AcceptEntityInput(endpoint,"Explode");
	PrecacheSound("npc/strider/fire.wav");
	EmitSoundToAll("npc/strider/fire.wav", endpoint, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	AcceptEntityInput(endpoint,"kill");
	return Plugin_Handled;
}

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	char targn[32];
	GetEntPropString(attacker,Prop_Data,"m_iName",targn,sizeof(targn));
	if (StrEqual(targn,"syn_stricann",false))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool ManHackGo(int client)
{
	if ((CLManhack[client] != 0) && (IsValidEntity(CLManhack[client])))
	{
		float Time = GetTickedTime();
		if (clsummoncdc[client] >= Time) return false;
		float PlayerOrigin[3];
		float clangles[3];
		float fhitpos[3];
		GetClientEyeAngles(client, clangles);
		GetClientAbsOrigin(client, PlayerOrigin);
		PlayerOrigin[0] = (PlayerOrigin[0] + (40 * Cosine(DegToRad(clangles[1]))));
		PlayerOrigin[1] = (PlayerOrigin[1] + (40 * Sine(DegToRad(clangles[1]))));
		PlayerOrigin[2] = (PlayerOrigin[2] + 40);
		Handle hhitpos = INVALID_HANDLE;
		TR_TraceRay(PlayerOrigin,clangles,MASK_SHOT,RayType_Infinite);
		TR_GetEndPosition(fhitpos,hhitpos);
		float chkdist = GetVectorDistance(PlayerOrigin,fhitpos,false);
		int cltarg = GetClientAimTarget(client, false);
		if ((RoundFloat(chkdist) <= 1000) && (IsValidEntity(cltarg)) && (cltarg > MaxClients))
		{
			char clsnam[32];
			GetEntityClassname(cltarg, clsnam, sizeof(clsnam));
			if (StrContains(clsnam,"npc_",false) != -1)
			{
				findsummonstargs(MaxClients+1,"npc_bullseye",client);
				if (IsValidEntity(clsummontarg[client]) && (clsummontarg[client] != 0))
					AcceptEntityInput(clsummontarg[client],"kill");
				char authstrtarg[36];
				Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[client]);
				if (clsummonfil == 0)
				{
					clsummonfil = CreateEntityByName("filter_activator_class");
					DispatchKeyValue(clsummonfil,"filterclass","player");
					DispatchKeyValue(clsummonfil,"Negated","1");
					DispatchKeyValue(clsummonfil,"targetname","noplayer");
					DispatchSpawn(clsummonfil);
					ActivateEntity(clsummonfil);
				}
				char targn[64];
				GetEntPropString(cltarg,Prop_Data,"m_iName",targn,sizeof(targn));
				if (strlen(targn) < 1)
				{
					SetVariantString("targetname sxpmtemp");
					AcceptEntityInput(cltarg,"AddOutput");
					Format(targn,sizeof(targn),"sxpmtemp");
				}
				int gototarg = CreateEntityByName("aiscripted_schedule");
				DispatchKeyValue(gototarg,"targetname",authstrtarg);
				DispatchKeyValue(gototarg,"m_iszEntity",SteamID[client]);
				DispatchKeyValue(gototarg,"m_flRadius","0");
				DispatchKeyValue(gototarg,"forcestate","3");
				DispatchKeyValue(gototarg,"schedule","6");
				DispatchKeyValue(gototarg,"goalent",targn);
				DispatchSpawn(gototarg);
				ActivateEntity(gototarg);
				AcceptEntityInput(gototarg,"StartSchedule");
				//npc_enemyfinder
			}
		}
		else if (RoundFloat(chkdist) <= 1000)
		{
			findsummonstargs(MaxClients+1,"npc_bullseye",client);
			if (IsValidEntity(clsummontarg[client]) && (clsummontarg[client] != 0))
				AcceptEntityInput(clsummontarg[client],"kill");
			char authstrtarg[36];
			Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[client]);
			if (clsummonfil == 0)
			{
				clsummonfil = CreateEntityByName("filter_activator_class");
				DispatchKeyValue(clsummonfil,"filterclass","player");
				DispatchKeyValue(clsummonfil,"Negated","1");
				DispatchKeyValue(clsummonfil,"targetname","noplayer");
				DispatchSpawn(clsummonfil);
				ActivateEntity(clsummonfil);
			}
			int gototarg = CreateEntityByName("npc_bullseye");
			TeleportEntity(gototarg, fhitpos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(gototarg,"targetname",authstrtarg);
			DispatchKeyValue(gototarg,"health","1");
			DispatchKeyValue(gototarg,"spawnflags","65536");
			DispatchKeyValue(gototarg,"damagefilter","noplayer");
			DispatchSpawn(gototarg);
			ActivateEntity(gototarg);
			int changetarg = CreateEntityByName("ai_changetarget");
			DispatchKeyValue(changetarg,"target",SteamID[client]);
			DispatchKeyValue(changetarg,"m_iszNewTarget",authstrtarg);
			DispatchSpawn(changetarg);
			ActivateEntity(changetarg);
			AcceptEntityInput(changetarg,"Activate");
			int stuffrel = CreateEntityByName("ai_relationship");
			DispatchKeyValue(stuffrel,"disposition","1");
			DispatchKeyValue(stuffrel,"subject",SteamID[client]);
			DispatchKeyValue(stuffrel,"target",authstrtarg);
			DispatchKeyValue(stuffrel,"rank","99");
			DispatchKeyValue(stuffrel,"reciprocal","1");
			DispatchKeyValue(stuffrel,"StartActive","1");
			DispatchSpawn(stuffrel);
			ActivateEntity(stuffrel);
			AcceptEntityInput(stuffrel,"ApplyRelationship");
			int entindx = EntIndexToEntRef(changetarg);
			CreateTimer(0.1,cleanup,entindx);
			clsummontarg[client] = gototarg;
		}
		else
		{
			if (IsValidEntity(clsummontarg[client]) && (clsummontarg[client] != 0))
				AcceptEntityInput(clsummontarg[client],"kill");
			char authstrtarg[36];
			Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[client]);
			if (clsummonfil == 0)
			{
				clsummonfil = CreateEntityByName("filter_activator_class");
				DispatchKeyValue(clsummonfil,"filterclass","player");
				DispatchKeyValue(clsummonfil,"Negated","1");
				DispatchKeyValue(clsummonfil,"targetname","noplayer");
				DispatchSpawn(clsummonfil);
				ActivateEntity(clsummonfil);
			}
			int gototarg = CreateEntityByName("npc_bullseye");
			TeleportEntity(gototarg, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(gototarg,"targetname",authstrtarg);
			DispatchKeyValue(gototarg,"health","1");
			DispatchKeyValue(gototarg,"spawnflags","65536");
			DispatchKeyValue(gototarg,"damagefilter","noplayer");
			DispatchSpawn(gototarg);
			ActivateEntity(gototarg);
			int changetarg = CreateEntityByName("ai_changetarget");
			DispatchKeyValue(changetarg,"target",SteamID[client]);
			DispatchKeyValue(changetarg,"m_iszNewTarget",authstrtarg);
			DispatchSpawn(changetarg);
			ActivateEntity(changetarg);
			AcceptEntityInput(changetarg,"Activate");
			int stuffrel = CreateEntityByName("ai_relationship");
			DispatchKeyValue(stuffrel,"disposition","1");
			DispatchKeyValue(stuffrel,"subject",SteamID[client]);
			DispatchKeyValue(stuffrel,"target",authstrtarg);
			DispatchKeyValue(stuffrel,"rank","99");
			DispatchKeyValue(stuffrel,"reciprocal","1");
			DispatchKeyValue(stuffrel,"StartActive","1");
			DispatchSpawn(stuffrel);
			ActivateEntity(stuffrel);
			AcceptEntityInput(stuffrel,"ApplyRelationship");
			int entindx = EntIndexToEntRef(changetarg);
			CreateTimer(0.1,cleanup,entindx);
			clsummontarg[client] = gototarg;
		}
		clsummoncdc[client] = Time + 1.0;
	}
	return true;
}

public Action findsummonstargs(int ent, char[] clsname, int client)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char prevtmp[48];
		GetEntPropString(thisent,Prop_Data,"m_iName",prevtmp,sizeof(prevtmp));
		if (StrContains(prevtmp,SteamID[client],false) != -1)
		{
			AcceptEntityInput(thisent,"kill");
			clsummontarg[client] = 0;
		}
		findsummonstargs(thisent++,clsname,client++);
	}
	return Plugin_Handled;
}

public Action unpack(Handle timer,any stuff)
{
	if (IsValidEntity(stuff))
		AcceptEntityInput(stuff,"Unpack");
}

public Action cleanup(Handle timer, int changetarg)
{
	int entindx = EntRefToEntIndex(changetarg);
	if ((IsValidEntity(entindx)) && (entindx != 0) && (entindx > MaxClients))
		AcceptEntityInput(entindx,"kill");
}

public Action chkdisttargs(Handle timer)
{
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
		{
			if (IsClientInGame(i))
			{
				char curweap[32];
				GetClientWeapon(i,curweap,sizeof(curweap));
				if (FindStringInArray(sweps,curweap) != -1)
				{
					if ((StrEqual(curweap,"weapon_tau",false)) || (StrEqual(curweap,"weapon_gauss",false)))
					{
						int weap = GetEntPropEnt(i,Prop_Data,"m_hActiveWeapon");
						if (weap != -1)
						{
							char mdl[64];
							float orgreset[3];
							float angreset[3];
							GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
							if (StrEqual(mdl,"models/v_gauss.mdl",false))
							{
								orgreset[2] = -5.0;
								angreset[0] = 10.0;
								angreset[1] = 180.0;
							}
							else
							{
								orgreset[2] = -5.0;
								angreset[0] = -20.0;
							}
							SetVariantString("anim_attachment_RH");
							AcceptEntityInput(weap,"SetParentAttachment");
							SetEntPropVector(weap,Prop_Data,"m_vecOrigin",orgreset);
							SetEntPropVector(weap,Prop_Data,"m_angRotation",angreset);
						}
					}
				}
				if ((CLManhack[i] != 0) && (IsValidEntity(CLManhack[i])) && (clsummontarg[i] != 0) && (IsValidEntity(clsummontarg[i])))
				{
					char summoncls[32];
					GetEntityClassname(CLManhack[i],summoncls, sizeof(summoncls));
					char summontcls[32];
					GetEntityClassname(clsummontarg[i],summontcls, sizeof(summontcls));
					if ((StrEqual(summoncls,"npc_manhack",false)) && (StrEqual(summontcls,"npc_bullseye",false)))
					{
						float manhack[3];
						float target[3];
						GetEntPropVector(CLManhack[i],Prop_Send,"m_vecOrigin",manhack);
						GetEntPropVector(clsummontarg[i],Prop_Send,"m_vecOrigin",target);
						float chkdist = GetVectorDistance(manhack,target,false);
						int held = GetEntProp(CLManhack[i],Prop_Data,"m_bHeld");
						if ((RoundFloat(chkdist) <= 100) || (held != 0))
						{
							AcceptEntityInput(clsummontarg[i],"kill");
							clsummontarg[i] = 0;
						}
					}
					else
					{
						CLManhack[i] = 0;
						clsummontarg[i] = 0;
					}
				}
				else if ((CLManhack[i] != 0) && (IsValidEntity(CLManhack[i])))
				{
					char summoncls[32];
					GetEntityClassname(CLManhack[i],summoncls, sizeof(summoncls));
					if (StrEqual(summoncls,"npc_manhack",false))
					{
						float PlayerOrigin[3];
						float manhack[3];
						GetClientAbsOrigin(i, PlayerOrigin);
						GetEntPropVector(CLManhack[i],Prop_Send,"m_vecOrigin",manhack);
						float chkdist = GetVectorDistance(manhack,PlayerOrigin,false);
						int held = GetEntProp(CLManhack[i],Prop_Data,"m_bHeld");
						int hasenemy = GetEntPropEnt(CLManhack[i],Prop_Data,"m_hEnemy");
						//PrintToServer("%i host %i %i %i %i",RoundFloat(chkdist),hasenemy);
						if ((RoundFloat(chkdist) >= 1000) && (held == 0) && (hasenemy == -1))
						{
							if (IsValidEntity(clsummontarg[i]) && (clsummontarg[i] != 0))
								AcceptEntityInput(clsummontarg[i],"kill");
							char authstrtarg[36];
							Format(authstrtarg,sizeof(authstrtarg),"%starg",SteamID[i]);
							if (clsummonfil == 0)
							{
								clsummonfil = CreateEntityByName("filter_activator_class");
								DispatchKeyValue(clsummonfil,"filterclass","player");
								DispatchKeyValue(clsummonfil,"Negated","1");
								DispatchKeyValue(clsummonfil,"targetname","noplayer");
								DispatchSpawn(clsummonfil);
								ActivateEntity(clsummonfil);
							}
							int gototarg = CreateEntityByName("npc_bullseye");
							TeleportEntity(gototarg, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
							DispatchKeyValue(gototarg,"targetname",authstrtarg);
							DispatchKeyValue(gototarg,"health","1");
							DispatchKeyValue(gototarg,"spawnflags","65536");
							DispatchKeyValue(gototarg,"damagefilter","noplayer");
							DispatchSpawn(gototarg);
							ActivateEntity(gototarg);
							int changetarg = CreateEntityByName("ai_changetarget");
							DispatchKeyValue(changetarg,"target",SteamID[i]);
							DispatchKeyValue(changetarg,"m_iszNewTarget",authstrtarg);
							DispatchSpawn(changetarg);
							ActivateEntity(changetarg);
							AcceptEntityInput(changetarg,"Activate");
							int stuffrel = CreateEntityByName("ai_relationship");
							DispatchKeyValue(stuffrel,"disposition","1");
							DispatchKeyValue(stuffrel,"subject",SteamID[i]);
							DispatchKeyValue(stuffrel,"target",authstrtarg);
							DispatchKeyValue(stuffrel,"rank","99");
							DispatchKeyValue(stuffrel,"reciprocal","1");
							DispatchKeyValue(stuffrel,"StartActive","1");
							DispatchSpawn(stuffrel);
							ActivateEntity(stuffrel);
							AcceptEntityInput(stuffrel,"ApplyRelationship");
							int entindx = EntIndexToEntRef(changetarg);
							CreateTimer(0.1,cleanup,entindx);
							clsummontarg[i] = gototarg;
						}
					}
					else
					{
						CLManhack[i] = 0;
					}
				}
			}
		}
	}
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

public Action StartTouchHornet(int entity, int other)
{
	if (IsValidEntity(other))
	{
		int client = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if (client != other)
		{
			if (((other > MaxClients) || (friendlyfire)) && (other != 0))
			{
				float damageForce[3];
				float dmgset = 5.0;
				float dmgforce = 5.0;
				damageForce[0] = dmgforce;
				damageForce[1] = dmgforce;
				damageForce[2] = dmgforce;
				if (IsValidEntity(client)) SDKHooks_TakeDamage(other,client,client,dmgset,DMG_CLUB,-1,damageForce);
				else SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_CLUB,-1,damageForce);
				if (FileExists("sound/weapons/hivehand/bug_impact.wav",true,NULL_STRING))
				{
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
					int effect = CreateEntityByName("info_particle_system");
					if (effect != -1)
					{
						float curorg[3];
						if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
						else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
						float angs[3];
						if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
						DispatchKeyValue(effect,"effect_name","grenade_hornet_detonate");
						DispatchKeyValue(effect,"start_active","1");
						TeleportEntity(effect,curorg,angs,NULL_VECTOR);
						DispatchSpawn(effect);
						ActivateEntity(effect);
						AcceptEntityInput(effect,"Start");
						int entindx = EntIndexToEntRef(effect);
						CreateTimer(0.5,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if (FileExists("sound/hornet/ag_hornethit1.wav",true,NULL_STRING))
				{
					char snd[64];
					Format(snd,sizeof(snd),"hornet\\ag_hornethit%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
			}
			AcceptEntityInput(entity,"kill");
		}
	}
}

CreateHornet(int client, int weap)
{
	if ((IsValidEntity(client)) && (IsValidEntity(weap)))
	{
		float targpos[3];
		float shootvel[3];
		float plyfirepos[3];
		float plyang[3];
		GetClientEyeAngles(client,plyang);
		plyang[1]-=10.0;
		GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
		plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
		plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
		if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
		else plyfirepos[2]+=48.0;
		plyang[1]+=10.0;
		TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
		TR_GetEndPosition(targpos);
		MakeVectorFromPoints(plyfirepos,targpos,shootvel);
		ScaleVector(shootvel,1.25);
		if (((shootvel[0] < 500.0) && (shootvel[0] > -500.0)) || ((shootvel[1] < 500.0) && (shootvel[1] > -500.0)))
			ScaleVector(shootvel,3.0);
		int spitball = CreateEntityByName("generic_actor");
		if (spitball != -1)
		{
			if (FileExists("models/weapons/w_hornet.mdl",true,NULL_STRING)) DispatchKeyValue(spitball,"model","models/weapons/w_hornet.mdl");
			else DispatchKeyValue(spitball,"model","models/hornet.mdl");
			DispatchKeyValue(spitball,"classname","npc_hornet");
			DispatchKeyValue(spitball,"OnDeath","!self,kill,,0,-1");
			TeleportEntity(spitball,plyfirepos,plyang,NULL_VECTOR);
			DispatchSpawn(spitball);
			ActivateEntity(spitball);
			SetEntityMoveType(spitball,MOVETYPE_FLY);
			if (HasEntProp(spitball,Prop_Data,"m_CollisionGroup")) SetEntProp(spitball,Prop_Data,"m_CollisionGroup",5);
			CreateTimer(0.25,resetcoll,spitball,TIMER_FLAG_NO_MAPCHANGE);
			SDKHook(spitball, SDKHook_StartTouch, StartTouchHornet);
			SetEntPropEnt(spitball,Prop_Data,"m_hEffectEntity",client);
			if (HasEntProp(spitball,Prop_Data,"m_bloodColor")) SetEntProp(spitball,Prop_Data,"m_bloodColor",2);
			char mdl[64];
			GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			if (!StrEqual(mdl,"models/v_hgun.mdl"))
			{
				int effect = CreateEntityByName("info_particle_system");
				if (effect != -1)
				{
					DispatchKeyValue(effect,"effect_name","hornet_trail");
					DispatchKeyValue(effect,"start_active","1");
					TeleportEntity(effect,plyfirepos,plyang,NULL_VECTOR);
					DispatchSpawn(effect);
					ActivateEntity(effect);
					SetVariantString("!activator");
					AcceptEntityInput(effect,"SetParent",spitball);
					AcceptEntityInput(effect,"Start");
					int entindx = EntIndexToEntRef(effect);
					CreateTimer(2.0,cleanup,entindx,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else
			{
				int trail = CreateEntityByName("env_spritetrail");
				DispatchKeyValue(trail,"lifetime","0.2");
				DispatchKeyValue(trail,"startwidth","2.0");
				DispatchKeyValue(trail,"endwidth","1.0");
				DispatchKeyValue(trail,"spritename","sprites/bluelaser1.vmt");
				DispatchKeyValue(trail,"renderamt","255");
				DispatchKeyValue(trail,"rendermode","5");
				DispatchKeyValue(trail,"rendercolor","255 50 10");
				TeleportEntity(trail,plyfirepos,plyang,NULL_VECTOR);
				DispatchSpawn(trail);
				ActivateEntity(trail);
				SetVariantString("!activator");
				AcceptEntityInput(trail,"SetParent",spitball);
			}
			SetEntProp(spitball,Prop_Data,"m_MoveType",4);
			TeleportEntity(spitball,NULL_VECTOR,NULL_VECTOR,shootvel);
		}
		HiveAmm[client]--;
		SetEntProp(weap,Prop_Send,"m_iClip1",HiveAmm[client]);
	}
}

CreateSnark(int client, int type)
{
	if (IsValidEntity(client))
	{
		float targpos[3];
		float shootvel[3];
		float plyfirepos[3];
		float plyang[3];
		GetClientEyeAngles(client,plyang);
		plyang[1]-=10.0;
		GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",plyfirepos);
		plyfirepos[0] = (plyfirepos[0] + (40 * Cosine(DegToRad(plyang[1]))));
		plyfirepos[1] = (plyfirepos[1] + (40 * Sine(DegToRad(plyang[1]))));
		if (GetEntProp(client,Prop_Data,"m_bDucked")) plyfirepos[2]+=28.0;
		else plyfirepos[2]+=48.0;
		plyang[1]+=10.0;
		targpos[0] = (plyfirepos[0] + (200 * Cosine(DegToRad(plyang[1]))));
		targpos[1] = (plyfirepos[1] + (200 * Sine(DegToRad(plyang[1]))));
		targpos[2] = plyfirepos[2];
		MakeVectorFromPoints(plyfirepos,targpos,shootvel);
		int snark = CreateEntityByName("npc_headcrab_fast");
		if (snark != -1)
		{
			char clsnark[64];
			Format(clsnark,sizeof(clsnark),"%ssnark",SteamID[client]);
			if (type == 1) DispatchKeyValue(snark,"classname","npc_snark");
			else DispatchKeyValue(snark,"classname","monster_snark");
			DispatchKeyValue(snark,"targetname",clsnark);
			DispatchKeyValue(snark,"rendermode","10");
			DispatchKeyValue(snark,"renderfx","6");
			TeleportEntity(snark,plyfirepos,plyang,NULL_VECTOR);
			DispatchSpawn(snark);
			ActivateEntity(snark);
			TeleportEntity(snark,NULL_VECTOR,NULL_VECTOR,shootvel);
			MakeAlly(clsnark);
		}
	}
}

MakeAlly(char[] clsnark)
{
	Handle liarr = GetLIList();
	Handle htarr = GetHTList();
	if (GetArraySize(liarr) > 0)
	{
		for (int i = 0;i<GetArraySize(liarr);i++)
		{
			char targ[64];
			GetArrayString(liarr,i,targ,sizeof(targ));
			int aidisp = CreateEntityByName("ai_relationship");
			DispatchKeyValue(aidisp,"disposition","3");
			DispatchKeyValue(aidisp,"subject",clsnark);
			DispatchKeyValue(aidisp,"target",targ);
			DispatchKeyValue(aidisp,"targetname","syn_relations");
			DispatchKeyValue(aidisp,"rank","99");
			DispatchKeyValue(aidisp,"reciprocal","1");
			DispatchKeyValue(aidisp,"StartActive","1");
			DispatchSpawn(aidisp);
			ActivateEntity(aidisp);
			AcceptEntityInput(aidisp,"ApplyRelationship");
			AcceptEntityInput(aidisp,"kill");
		}
	}
	if (GetArraySize(htarr) > 0)
	{
		for (int i = 0;i<GetArraySize(htarr);i++)
		{
			char targ[64];
			GetArrayString(htarr,i,targ,sizeof(targ));
			//Can't include self in HT or it will attack any, friend or enemy.
			if ((!StrEqual(targ,"npc_snark",false)) && (!StrEqual(targ,"monster_snark",false)))
			{
				int aidisp = CreateEntityByName("ai_relationship");
				DispatchKeyValue(aidisp,"disposition","1");
				DispatchKeyValue(aidisp,"subject",clsnark);
				DispatchKeyValue(aidisp,"target",targ);
				DispatchKeyValue(aidisp,"targetname","syn_relations");
				DispatchKeyValue(aidisp,"rank","99");
				DispatchKeyValue(aidisp,"reciprocal","1");
				DispatchKeyValue(aidisp,"StartActive","1");
				DispatchSpawn(aidisp);
				ActivateEntity(aidisp);
				AcceptEntityInput(aidisp,"ApplyRelationship");
				AcceptEntityInput(aidisp,"kill");
			}
		}
	}
	CloseHandle(liarr);
	CloseHandle(htarr);
}

DetSatchels(int ent, int client)
{
	int thisent = FindEntityByClassname(ent,"grenade_satchel");
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		int owner = -1;
		int endpoint = GetEntPropEnt(thisent,Prop_Data,"m_hOwnerEntity");
		if (endpoint != -1) owner = GetEntPropEnt(endpoint,Prop_Data,"m_hOwnerEntity");
		if (owner == client)
		{
			if ((endpoint != 0) && (IsValidEntity(endpoint)) && (endpoint > MaxClients))
			{
				AcceptEntityInput(endpoint,"ClearParent");
				CreateTimer(0.1,explodedelay,endpoint,TIMER_FLAG_NO_MAPCHANGE);
			}
			AcceptEntityInput(thisent,"kill");
		}
		DetSatchels(thisent++,client);
	}
}

public Action grenademinetkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((victim != 0) && (IsValidEntity(victim)) && (damage > 0.1))
	{
		int endpoint = GetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity");
		if ((endpoint != 0) && (IsValidEntity(endpoint)))
		{
			SetEntPropEnt(victim,Prop_Data,"m_hOwnerEntity",-1);
			AcceptEntityInput(endpoint,"ClearParent");
			CreateTimer(0.1,explodedelay,endpoint,TIMER_FLAG_NO_MAPCHANGE);
		}
		AcceptEntityInput(victim,"kill");
	}
}

public Action explodedelay(Handle timer, int expl)
{
	if ((IsValidEntity(expl)) && (expl != 0))
	{
		AcceptEntityInput(expl,"Explode");
	}
}

CreateTripMine(int client)
{
	if (IsValidEntity(client))
	{
		float plyfirepos[3];
		float angs[3];
		float mineang[3];
		GetClientEyePosition(client,plyfirepos);
		GetClientEyeAngles(client,angs);
		plyfirepos[0] = (plyfirepos[0] + (10 * Cosine(DegToRad(angs[1]))));
		plyfirepos[1] = (plyfirepos[1] + (10 * Sine(DegToRad(angs[1]))));
		float fhitpos[3];
		TR_TraceRayFilter(plyfirepos,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,client);
		TR_GetEndPosition(fhitpos);
		TR_GetPlaneNormal(INVALID_HANDLE,mineang);
		GetVectorAngles(mineang,angs);
		int mine = CreateEntityByName("prop_physics");
		if (mine != -1)
		{
			char minemdl[64];
			Format(minemdl,sizeof(minemdl),"models/weapons/w_tripmine.mdl");
			TripMineAmm[client]--;
			int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (weap != -1)
			{
				char weapcls[32];
				GetEntityClassname(weap,weapcls,sizeof(weapcls));
				if (StrEqual(weapcls,"weapon_tripmine",false))
				{
					SetEntProp(weap,Prop_Data,"m_iClip1",TripMineAmm[client]);
					if (TripMineAmm[client] == 0)
					{
						int viewmdl = GetEntPropEnt(client,Prop_Data,"m_hViewModel");
						if (viewmdl != -1) SetEntProp(viewmdl,Prop_Send,"m_nSequence",7);
					}
					char mdl[32];
					GetEntPropString(weap,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					if (StrEqual(mdl,"models/v_tripmine.mdl",false))
					{
						Format(minemdl,sizeof(minemdl),"models/w_tripmine.mdl");
						fhitpos[0] = (fhitpos[0] + (5 * Cosine(DegToRad(angs[1]))));
						fhitpos[1] = (fhitpos[1] + (5 * Sine(DegToRad(angs[1]))));
					}
				}
			}
			DispatchKeyValue(mine,"model",minemdl);
			DispatchKeyValue(mine,"spawnflags","8");
			DispatchKeyValue(mine,"classname","grenade_tripmine");
			TeleportEntity(mine,fhitpos,angs,NULL_VECTOR);
			DispatchSpawn(mine);
			ActivateEntity(mine);
			if (FileExists("sound/weapons/tripmine/warmup.wav",true,NULL_STRING))
			{
				EmitSoundToAll("weapons\\tripmine\\warmup.wav", mine, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				CreateTimer(1.5,SetupMine,mine,TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (FileExists("sound/weapons/mine_deploy.wav",true,NULL_STRING))
			{
				EmitSoundToAll("weapons\\mine_deploy.wav", mine, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
				CreateTimer(0.2,ChargeUpSnd,mine,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(2.25,SetupMine,mine,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action ChargeUpSnd(Handle timer, int mine)
{
	if (IsValidEntity(mine))
	{
		if (FileExists("sound/weapons/mine_charge.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\mine_charge.wav", mine, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
	}
}

public Action SetupMine(Handle timer, int mine)
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
				char radius[8] = "250";
				char dmgmag[8] = "300";
				Handle cvar = FindConVar("sk_tripmine_radius");
				if (cvar != INVALID_HANDLE)
				{
					if (GetConVarInt(cvar) < 1) SetConVarInt(cvar,250,false,false);
					GetConVarString(cvar,radius,sizeof(radius));
				}
				cvar = FindConVar("sk_plr_dmg_tripmine");
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
				HookSingleEntityOutput(beam,"OnTouchedByEntity",EntityOutput:TripMineExpl);
				ChangeEdictState(mine);
			}
		}
		SDKHookEx(mine,SDKHook_OnTakeDamage,TripMineTKdmg);
		if (FileExists("sound/weapons/tripmine/activate.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\tripmine\\activate.wav", mine, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
		else if (FileExists("sound/weapons/mine_activate.wav",true,NULL_STRING)) EmitSoundToAll("weapons\\mine_activate.wav", mine, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
	}
}

public Action TripMineTKdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
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
			CreateTimer(0.1,explodedelay,expl,TIMER_FLAG_NO_MAPCHANGE);
		}
		SDKUnhook(victim, SDKHook_OnTakeDamage, TripMineTKdmg);
		AcceptEntityInput(victim,"kill");
	}
}

public TripMineExpl(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		int tripmine = GetEntPropEnt(caller,Prop_Data,"m_hOwnerEntity");
		if (IsValidEntity(tripmine))
		{
			int parexpl = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if ((parexpl != -1) && (IsValidEntity(parexpl))) AcceptEntityInput(parexpl,"Explode");
			AcceptEntityInput(tripmine,"kill");
			UnhookSingleEntityOutput(caller,"OnTouchedByEntity",EntityOutput:TripMineExpl);
			AcceptEntityInput(caller,"kill");
		}
	}
}

public Action GrenadeExpl(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity != 0))
	{
		AcceptEntityInput(entity,"kill");
	}
}

ShootBullet(int client, char[] curweap, float orgs[3], float angs[3], int sideoffs, float maxspread)
{
	if (IsValidEntity(client))
	{
		float endpos[3];
		float shootvel[3];
		orgs[2]+=13.0;
		if (GetEntProp(client,Prop_Data,"m_bDucked")) orgs[2]-=28.0;
		TE_Start("Shotgun Shot");
		angs[1]+=90.0;
		orgs[0] = (orgs[0] + (sideoffs * Cosine(DegToRad(angs[1]))));
		orgs[1] = (orgs[1] + (sideoffs * Sine(DegToRad(angs[1]))));
		angs[1]-=90.0;
		TE_WriteVector("m_vecOrigin", orgs);
		float spread = GetRandomFloat(-maxspread,maxspread);
		angs[0] = angs[0]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[1] = angs[1]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[2] = angs[2]+spread;
		TR_TraceRayFilter(orgs, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
		TR_GetEndPosition(endpos);
		int hitgroup = TR_GetHitGroup();
		int targ = TR_GetEntityIndex();
		MakeVectorFromPoints(orgs,endpos,shootvel);
		TE_WriteVector("m_vecDir", shootvel);
		TE_WriteNum("m_iAmmoID", 1);
		TE_WriteNum("m_iSeed", 0);
		TE_WriteNum("m_iShots", 1);
		TE_WriteNum("m_iPlayer", client);
		TE_WriteFloat("m_flSpread", 0.0);
		TE_WriteNum("m_bDoImpacts", 1);
		TE_WriteNum("m_bDoTracers", 1);
		TE_SendToAll(0.0);
		SetEntPropFloat(client,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
		if ((targ != 0) && (IsValidEntity(targ)))
		{
			char clsname[32];
			GetEntityClassname(targ,clsname,sizeof(clsname));
			float damage = 1.0;
			char weapdmg[32];
			Format(weapdmg,sizeof(weapdmg),"%s",curweap);
			ReplaceStringEx(weapdmg,sizeof(weapdmg),"weapon_","sk_plr_dmg_");
			Handle cvar = FindConVar(weapdmg);
			if (cvar != INVALID_HANDLE)
			{
				damage = GetConVarFloat(cvar);
				float inflictscale = 1.0;
				char scalechk[32];
				Format(scalechk,sizeof(scalechk),"sk_dmg_inflict_scale%i",difficulty);
				Handle scaleh = FindConVar(scalechk);
				if (scaleh != INVALID_HANDLE) inflictscale = GetConVarFloat(scaleh);
				CloseHandle(scaleh);
				damage = damage/inflictscale;
				if (hitgroup == headgroup) damage = damage*2.0;
			}
			CloseHandle(cvar);
			if ((!CheckNPCAlly(clsname,targ)) || ((targ < MaxClients+1) && (targ > 0) && (friendlyfire)))
			{
				ScaleVector(shootvel,2.0);
				SDKHooks_TakeDamage(targ,client,client,damage,DMG_BULLET,-1,shootvel,orgs);
			}
			else if ((StrContains(clsname,"prop_",false) != -1) || (StrEqual(clsname,"func_breakable",false)))
			{
				SDKHooks_TakeDamage(targ,client,client,damage,DMG_BULLET,-1,shootvel,orgs);
				ScaleVector(shootvel,1.5);
				float maxscaler = damage;
				if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
				{
					while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
					{
						ScaleVector(shootvel,0.95);
					}
				}
				TeleportEntity(targ,NULL_VECTOR,NULL_VECTOR,shootvel);
			}
		}
	}
}

bool HasWeapon(int client, char[] cls)
{
	if ((IsValidEntity(client)) && (client != 0) && (strlen(cls) > 0))
	{
		if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
		if (WeapList != -1)
		{
			for (int j; j<104; j += 4)
			{
				int tmpi = GetEntDataEnt2(client,WeapList + j);
				if (tmpi != -1)
				{
					char weapcls[64];
					GetEntityClassname(tmpi,weapcls,sizeof(weapcls));
					if (StrEqual(weapcls,cls,false)) return true;
				}
			}
		}
	}
	return false;
}

public Action resetcoll(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_CollisionGroup")) SetEntProp(entity,Prop_Data,"m_CollisionGroup",10);
	}
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (IsValidEntity(entity))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"npc_hornet",false)) return false;
	}
	return true;
}
