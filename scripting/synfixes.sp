#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
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
float entrefresh = 0.0;
float removertimer = 30.0;
int WeapList = -1;
bool friendlyfire = false;
bool seqenablecheck = true;
bool voteinprogress = false;
bool instswitch = true;
bool mapchoosercheck = false;
bool linact = false;
bool syn56act = false;

#define PLUGIN_VERSION "1.57"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synfixesupdater.txt"

public Plugin:myinfo =
{
	name = "SynFixes",
	author = "Balimbanana",
	description = "Attempts to fix sequences by checking for missing actors, entities that have fallen out of the world, players not spawning with weapons, and vehicle pulling from side to side.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

Menu g_hVoteMenu = null;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"
float perclimit = 0.66;
float delaylimit = 66.0;
float votetime[64];
int clused = 0;
int voteact = 0;


enum voteType
{
	question
}

new voteType:g_voteType = voteType:question;

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
	CreateTimer(60.0,resetrot,_,TIMER_REPEAT);
	if ((FileExists("addons/metamod/bin/server.so",false,NULL_STRING)) && (FileExists("addons/metamod/bin/metamod.2.sdk2013.so",false,NULL_STRING))) linact = true;
	else linact = false;
	equiparr = CreateArray(32);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	entlist = CreateArray(1024);
	entnames = CreateArray(128);
	physboxarr = CreateArray(64);
	physboxharr = CreateArray(64);
	RegConsoleCmd("alyx",fixalyx);
	RegConsoleCmd("barney",fixbarney);
	RegConsoleCmd("stuck",stuckblck);
	RegConsoleCmd("propaccuracy",setpropaccuracy);
	RegConsoleCmd("con",enablecon);
	RegConsoleCmd("npc_freeze",admblock);
	RegConsoleCmd("npc_freeze_unselected",admblock);
	CreateTimer(10.0,dropshipchk,_,TIMER_REPEAT);
	AutoExecConfig(true, "synfixes");
}

public void OnMapStart()
{
	voteinprogress = false;
	entrefresh = 0.0;
	ClearArray(entlist);
	ClearArray(equiparr);
	ClearArray(entnames);
	ClearArray(physboxarr);
	ClearArray(physboxharr);
	char gamedescoriginal[24];
	GetGameDescription(gamedescoriginal,sizeof(gamedescoriginal),false);
	if (StrEqual(gamedescoriginal,"synergy 56.16",false)) syn56act = true;
	else syn56act = false;
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
					if (debuglvl > 1) PrintToServer("Found ent cache %s",mapbuf);
					break;
				}
			}
		}
	}
	HookEntityOutput("scripted_sequence","OnBeginSequence",EntityOutput:trigout);
	HookEntityOutput("scripted_scene","OnStart",EntityOutput:trigout);
	HookEntityOutput("logic_choreographed_scene","OnStart",EntityOutput:trigout);
	HookEntityOutput("instanced_scripted_scene","OnStart",EntityOutput:trigout);
	HookEntityOutput("func_tracktrain","OnStart",EntityOutput:elevatorstart);
	HookEntityOutput("trigger_changelevel","OnChangeLevel",EntityOutput:mapendchg);
	HookEntityOutput("npc_citizen","OnDeath",EntityOutput:entdeath);
	HookEntityOutput("func_physbox","OnPhysGunPunt",EntityOutput:physpunt);
	collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			CreateTimer(1.0,clspawnpost,i);
		}
	}
	findentlist(MaxClients+1,"npc_*");
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
	if ((StrEqual(tmpmap,"ep2_outland_12",false)) || (StrEqual(tmpmap,"ep2_outland_11b",false))) return Plugin_Handled;
	findgfollow(-1,"alyx");
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
	if (GetEntityRenderFx(client) == RENDERFX_DISTORT)
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
		if (voteinprogress)
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
			Location[2] = (PlayerOrigin[2] + 10);
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
		if ((clorigin[0] < vMins[0]) || (clorigin[1] < vMins[1]) || (clorigin[2] < vMins[2]) || (clorigin[0] > vMaxs[0]) || (clorigin[1] > vMaxs[1]) || (clorigin[2] > vMaxs[2]) || (TR_PointOutsideWorld(clorigin)))
		{
			if (debugoowlvl) PrintToServer("%N spawned out of map, moving to active checkpoint.",client);
			findspawnpos(client);
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
			else if ((HasEntProp(i,Prop_Data,"m_vecOrigin")) && (StrContains(clsname,"func_",false) == -1) && (StrContains(clsname,"trigger_",false) == -1) && (StrContains(clsname,"point_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (StrContains(clsname,"npc_",false) == -1) && (StrContains(clsname,"monster_",false) == -1) && (StrContains(clsname,"info_",false) == -1) && (StrContains(clsname,"env_",false) == -1) && (StrContains(clsname,"scripted",false) == -1) && (!StrEqual(clsname,"momentary_rot_button",false)) && (!StrEqual(clsname,"syn_transition_wall",false)) && (!StrEqual(clsname,"prop_dynamic",false)) && (StrContains(clsname,"light_",false) == -1))
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
	float origin[3];
	GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
	for (int i = MaxClients+1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if ((StrEqual(clsname,"prop_physics",false)) || (StrEqual(clsname,"prop_ragdoll",false)))
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

public Action mapendchg(const char[] output, int caller, int activator, float delay)
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

readoutputs(int scriptent, char[] targn)
{
	Handle filehandle = OpenFile(mapbuf,"r");
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		bool readnextlines = false;
		char lineoriginfixup[128];
		char kvs[128][64];
		bool reverse = true;
		bool returntostart = false;
		bool passvars = false;
		int ent = -1;
		Handle passedarr = CreateArray(64);
		int linepospass = 0;
		int lastpos = 0;
		float fileorigin[3];
		char clsscript[32];
		GetEntityClassname(scriptent,clsscript,sizeof(clsscript));
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrEqual(line,"{",false))
			{
				if (linact)
				{
					lastpos = FilePosition(filehandle)-2;
				}
				else if ((lastpos != linepospass) || (lastpos == 0))
				{
					lastpos = linepospass;
				}
				linepospass = FilePosition(filehandle)-2;
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
				if (debuglvl == 3) PrintToServer("Found matching %s on line %i, reading from %i",targn,linepos,linepospass);
				returntostart = true;
				reverse = false;
				break;
			}
		}
		FileSeek(filehandle,lastpos,SEEK_SET);
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (returntostart)
			{
				if (StrEqual(line,"{",false))
				{
					returntostart = false;
					readnextlines = true;
					ReadFileLine(filehandle,line,sizeof(line));
				}
				else
				{
					int linepos = FilePosition(filehandle);
					int linel = strlen(line);
					FileSeek(filehandle,linepos-linel,SEEK_SET);
				}
			}
			if (readnextlines)
			{
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
							DispatchKeyValue(ent,ktmp,ktmp2);
						}
						ClearArray(passedarr);
					}
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),line);
					ExplodeString(tmpchar, "\"", kvs, 64, 128, true);
					ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
					if (debuglvl > 1) PrintToServer("%s %s",kvs[1],kvs[3]);
					if (passvars)
					{
						PushArrayString(passedarr,kvs[1]);
						PushArrayString(passedarr,kvs[3]);
					}
					else
					{
						DispatchKeyValue(ent,kvs[1],kvs[3]);
					}
				}
				if ((StrEqual(line,"}",false)) || (StrEqual(line,"{",false)))
				{
					readnextlines = false;
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
			if ((StrContains(line,"\"classname\"",false) != -1) && (readnextlines))
			{
				if (StrContains(line,"point_template",false) != -1)
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
				else if (ent == -1)
				{
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"classname\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					if (StrEqual(tmpchar,"worldspawn",false)) break;
					ent = CreateEntityByName(tmpchar);
					if (debuglvl == 3) PrintToServer("Created Ent as %s",tmpchar);
					PushArrayCell(entlist,ent);
				}
			}
		}
		CloseHandle(passedarr);
	}
	CloseHandle(filehandle);
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
	if (FindValueInArray(physboxarr,attacker) != -1)
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

public OnEntityCreated(int entity, const char[] classname)
{
	if ((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false)) && (FindValueInArray(entlist,entity) == -1))
	{
		PushArrayCell(entlist,entity);
		if ((StrEqual(classname,"npc_citizen",false)) && (!(StrContains(mapbuf,"cd",false) == 0))) SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	if ((StrEqual(classname,"item_health_drop",false)) || (StrEqual(classname,"item_ammo_drop",false)))
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
		if (StrEqual(clscoll,"prop_dynamic",false))
		{
			char clscollname[64];
			GetEntPropString(other,Prop_Data,"m_iName",clscollname,sizeof(clscollname));
			if (strlen(clscollname) > 0)
			{
				if ((StrContains(clscollname,"elev",false) != -1) || (StrContains(clscollname,"basket",false) != -1))
					AcceptEntityInput(entity,"kill");
			}
		}
		else if (StrEqual(clscoll,"func_tracktrain",false))
			AcceptEntityInput(entity,"kill");
	}
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
		PushArrayCell(entlist,thisent);
		findentlist(thisent++,clsname);
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
