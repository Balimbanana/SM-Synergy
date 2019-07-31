#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#tryinclude <mapchooser>
#tryinclude <voteglobalset>
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
float entrefresh = 0.0;
float removertimer = 30.0;
int WeapList = -1;
int spawneramt = 20;
int restrictmode = 0;
int clrocket[64];
int longjumpactive = false;
int slavezap = 10;
bool allownoguide = true;
bool guiderocket[64];
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

#define PLUGIN_VERSION "1.982"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synfixesupdater.txt"

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
	Handle noguidecv = CreateConVar("sm_allownoguide","1","Sets whether or not to allow setting no guide on rpg rockets.",_,true,0.0,true,1.0);
	allownoguide = GetConVarBool(noguidecv);
	HookConVarChange(noguidecv,noguidech);
	CloseHandle(noguidecv);
	CreateTimer(60.0,resetrot,_,TIMER_REPEAT);
	//if ((FileExists("addons/metamod/bin/server.so",false,NULL_STRING)) && (FileExists("addons/metamod/bin/metamod.2.sdk2013.so",false,NULL_STRING))) linact = true;
	//else linact = false;
	equiparr = CreateArray(32);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	entlist = CreateArray(1024);
	entnames = CreateArray(128);
	physboxarr = CreateArray(64);
	physboxharr = CreateArray(64);
	elevlist = CreateArray(64);
	inputsarrorigincls = CreateArray(768);
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
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_controller_health","100","Alien Controller health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_human_assassin_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_human_assassin_health","50","Human Assassin health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_sentry_ceiling_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_sentry_ceiling_health","50","Ceiling Sentry health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_apache_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_apache_health","1500","Apache health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_houndeye_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_houndeye_health","50","Houndeye health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_gonarch_health");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_gonarch_health","1000","Gonarch health.",_,true,0.0,false);
	cvarchk = FindConVar("sk_gonarch_dmg_strike");
	if (cvarchk == INVALID_HANDLE) cvarchk = CreateConVar("sk_gonarch_dmg_strike","30.0","Gonarch strike damage.",_,true,1.0,false);
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
	for (int i = 1;i<MaxClients+1;i++)
	{
		guiderocket[i] = true;
	}
	hasread = false;
	voteinprogress = false;
	playerteleports = false;
	entrefresh = 0.0;
	ClearArray(entlist);
	ClearArray(equiparr);
	ClearArray(entnames);
	ClearArray(physboxarr);
	ClearArray(physboxharr);
	ClearArray(elevlist);
	ClearArray(inputsarrorigincls);
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
	HookEntityOutput("npc_citizen","OnDeath",EntityOutput:entdeath);
	HookEntityOutput("func_physbox","OnPhysGunPunt",EntityOutput:physpunt);
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
	
	FindSaveTPHooks();
	CreateTimer(0.1,rehooksaves);
	
	collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			CreateTimer(1.0,clspawnpost,i);
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
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public Action fixalyx(int client, int args)
{
	char tmpmap[24];
	GetCurrentMap(tmpmap,sizeof(tmpmap));
	if ((StrEqual(tmpmap,"ep2_outland_12",false)) || (StrEqual(tmpmap,"ep2_outland_11b",false)) || (StrEqual(tmpmap,"ep2_outland_02",false)) || (StrEqual(tmpmap,"d3_breen_01",false))) return Plugin_Handled;
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

public Action cmdblock(int client, int args)
{
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
		if ((voteinprogress) || (IsVoteInProgress()))
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
			voteinprogress = true;
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
			voteinprogress = true;
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
				voteinprogress = false;
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
		voteinprogress = false;
	}
	return 0;
}

public OnClientPutInServer(int client)
{
	CreateTimer(0.5,clspawnpost,client);
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
			else if ((HasEntProp(i,Prop_Data,"m_vecOrigin")) && (StrContains(clsname,"func_",false) == -1) && (StrContains(clsname,"trigger_",false) == -1) && (StrContains(clsname,"point_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (!StrEqual(clsname,"material_modify_control",false)) && (StrContains(clsname,"npc_",false) == -1) && (StrContains(clsname,"monster_",false) == -1) && (StrContains(clsname,"info_",false) == -1) && (StrContains(clsname,"env_",false) == -1) && (StrContains(clsname,"scripted",false) == -1) && (!StrEqual(clsname,"momentary_rot_button",false)) && (!StrEqual(clsname,"syn_transition_wall",false)) && (!StrEqual(clsname,"prop_dynamic",false)) && (StrContains(clsname,"light_",false) == -1))
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
			char clsname[32];
			GetEntityClassname(caller,clsname,sizeof(clsname));
			if ((StrEqual(clsname,"trigger_multiple",false)) || (StrEqual(clsname,"logic_relay",false)) || (StrEqual(clsname,"func_door",false)) || (StrEqual(clsname,"trigger_coop",false))) UnhookSingleEntityOutput(caller,tmpout,EntityOutput:trigtp);
			if (playerteleports) readoutputstp(targn,tmpout,"Teleport",origin,activator);
			if (vehiclemaphook) readoutputstp(targn,tmpout,"Save",origin,activator);
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

readoutputs(int scriptent, char[] targn)
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
}

readoutputstp(char[] targn, char[] output, char[] input, float origin[3], int activator)
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
			if ((StrContains(clsorfixup[5],",") != -1) && (StrContains(clsorfixup[5],"::") == -1))
			{
				if (StrContains(clsorfixup[3],output,false) == -1) return;
				ExplodeString(clsorfixup[5],",",lineorgrescom,16,64);
				ReplaceString(lineorgrescom[0],sizeof(lineorgrescom[])," ","");
				float delay = StringToFloat(lineorgrescom[3]);
				if (debuglvl >= 2) PrintToServer("%s Output %s %s",input,lineorgrescom[0],clsorfixup[5]);
				if (StrEqual(input,"teleport",false)) findpointtp(-1,lineorgrescom[0],activator,delay);
				else if (StrEqual(input,"save",false))
				{
					resetvehicles(delay);
					if (delay == 0.0) CreateTimer(0.01,recallreset);
				}
			}
			else
			{
				ExplodeString(clsorfixup[5],":",lineorgrescom,16,64);
				if (StrContains(clsorfixup[3],output,false) == -1) return;
				char delaystr[64];
				Format(delaystr,sizeof(delaystr),lineorgrescom[3]);
				//ReplaceString(lineorgrescom[1],64,lineorgrescom[1],"");
				float delay = StringToFloat(lineorgrescom[3]);
				if (debuglvl >= 2) PrintToServer("%s AddedOutput %s %s",input,lineorgrescom[0],clsorfixup[5]);
				if (StrEqual(input,"teleport",false)) findpointtp(-1,lineorgrescom[0],activator,delay);
				else if (StrEqual(input,"save",false))
				{
					resetvehicles(delay);
					if (delay == 0.0) CreateTimer(0.01,recallreset);
				}
			}
		}
	}
	return;
}

readoutputsforinputs()
{
	if (hasread) return;
	if (debuglvl == 3) PrintToServer("Read outputs for save/teleport inputs");
	hasread = true;
	Handle filehandle = OpenFile(mapbuf,"r");
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
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"origin\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				ExplodeString(tmpchar, " ", lineorgresexpl, 4, 16);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%i %i %i\"",RoundFloat(StringToFloat(lineorgresexpl[0])),RoundFloat(StringToFloat(lineorgresexpl[1])),RoundFloat(StringToFloat(lineorgresexpl[2])))
			}
			else if (StrContains(line,"\"targetname\"",false) == 0)
			{
				char tmpchar[72];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" \"","");
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","");
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s\"%s",tmpchar,lineoriginfixup);
				hastargn = true;
			}
			else if (((StrContains(line,",AddOutput,",false) != -1) && ((StrContains(line,inputadded,false) != -1) || (StrContains(line,inputadded2,false) != -1))) || (StrContains(line,inputdef,false) != -1) || (StrContains(line,inputdef2,false) != -1))
			{
				Format(lineorgres,sizeof(lineorgres),line);
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
					if (debuglvl == 3) PrintToServer("%s",lineadj);
				}
			}
		}
	}
	CloseHandle(filehandle);
	return;
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
		CreateTimer(0.1,cleanup,data);
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
			else if (StrEqual(clsname,"logic_relay",false))
			{
				HookSingleEntityOutput(i,"OnTrigger",EntityOutput:trigtp);
			}
			else if (StrEqual(clsname,"func_door",false))
			{
				HookSingleEntityOutput(i,"OnOpen",EntityOutput:trigtp);
				HookSingleEntityOutput(i,"OnFullyOpen",EntityOutput:trigtp);
				HookSingleEntityOutput(i,"OnClose",EntityOutput:trigtp);
				HookSingleEntityOutput(i,"OnFullyClosed",EntityOutput:trigtp);
			}
		}
	}
	HookEntityOutput("trigger_coop","OnPlayersIn",EntityOutput:trigtp);
	HookEntityOutput("trigger_coop","OnStartTouch",EntityOutput:trigtp);
	HookEntityOutput("trigger_multiple","OnTrigger",EntityOutput:trigtp);
	HookEntityOutput("trigger_multiple","OnStartTouch",EntityOutput:trigtp);
	HookEntityOutput("trigger_once","OnTrigger",EntityOutput:trigtp);
	HookEntityOutput("trigger_once","OnStartTouch",EntityOutput:trigtp);
	HookEntityOutput("point_viewcontrol","OnEndFollow",EntityOutput:trigtp);
	HookEntityOutput("func_button","OnPressed",EntityOutput:trigtp);
	HookEntityOutput("func_button","OnUseLocked",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnOpen",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnFullyOpen",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnClose",EntityOutput:trigtp);
	//HookEntityOutput("prop_door_rotating","OnFullyClosed",EntityOutput:trigtp);
}

public Action rehooksaves(Handle timer)
{
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

public OnEntityCreated(int entity, const char[] classname)
{
	if ((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false)) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (FindValueInArray(entlist,entity) == -1))
	{
		PushArrayCell(entlist,entity);
		if ((StrEqual(classname,"npc_citizen",false)) && (!(StrContains(mapbuf,"cd",false) == 0))) SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	if ((StrEqual(classname,"item_health_drop",false)) || (StrEqual(classname,"item_ammo_drop",false)) || (StrEqual(classname,"item_ammo_pack",false)))
	{
		SDKHook(entity, SDKHook_StartTouch, StartTouchprop);
		Handle data;
		data = CreateDataPack();
		WritePackCell(data, entity);
		WritePackString(data, classname);
		CreateTimer(removertimer,cleanup,data);
	}
	if (StrEqual(classname,"logic_auto",false))
	{
		CreateTimer(1.0,rechk,entity);
	}
	if (StrEqual(classname,"npc_vortigaunt",false))
	{
		CreateTimer(1.0,rechkcol,entity);
	}
	if (StrEqual(classname,"phys_bone_follower",false))
	{
		if (GetEntityCount() > 2000) AcceptEntityInput(entity,"kill");
	}
	if (StrEqual(classname,"rpg_missile",false))
	{
		if (IsValidEntity(entity))
		{
			CreateTimer(0.3,resetown,entity);
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
				CreateTimer(0.1,resetinst,data);
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
	if ((IsValidEntity(weap)) && (HasEntProp(weap,Prop_Send,"m_flNextPrimaryAttack")))
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
				if (debuglvl == 1) PrintToServer("%i has %i max npcs resetting to %i",thisent,maxnpc,spawneramt);
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

public noguidech(Handle convar, const char[] oldValue, const char[] newValue)
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

public vortzapch(Handle convar, const char[] oldValue, const char[] newValue)
{
	slavezap = StringToInt(newValue);
}
