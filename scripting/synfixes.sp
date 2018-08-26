#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int debuglvl = 0;
int debugoowlvl = 0;
int collisiongroup = -1;
char mapbuf[64];
Handle equiparr = INVALID_HANDLE;
int WeapList = -1;

public Plugin:myinfo = 
{
	name = "SynFixes",
	author = "Balimbanana",
	description = "Attempts to fix sequences by checking for missing actors, entities that have fallen out of the world, players not spawning with weapons, and vehicle pulling from side to side.",
	version = "1.0",
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
	Handle dbgoh = INVALID_HANDLE;
	dbgh = CreateConVar("seqdbg", "0", "Set debug level of sequence checks.", _, true, 0.0, true, 3.0);
	dbgoh = CreateConVar("oowdbg", "0", "Set debug level of out of world checks.", _, true, 0.0, true, 1.0);
	HookConVarChange(dbgh, dbghch);
	HookConVarChange(dbgoh, dbghoch);
	debuglvl = GetConVarInt(dbgh);
	debugoowlvl = GetConVarInt(dbgoh);
	CloseHandle(dbgh);
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
	CreateTimer(60.0,resetrot,_,TIMER_REPEAT);
	equiparr = CreateArray(32);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	RegConsoleCmd("alyx",fixalyx);
	RegConsoleCmd("barney",fixbarney);
	RegConsoleCmd("stuck",stuckblck);
	RegConsoleCmd("propaccuracy",setpropaccuracy);
	AutoExecConfig(true, "synfixes");
}

public void OnMapStart()
{
	ClearArray(equiparr);
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
	collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			CreateTimer(1.0,clspawnpost,i);
		}
	}
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

public Action fixalyx(int client, int args)
{
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
	}
	return 0;
}

public OnClientAuthorized(int client, const char[] szAuth)
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
		if ((FindStringInArray(weaparr,"weapon_physcannon") == -1) || (GetEntProp(client,Prop_Send,"m_bWearingSuit") > 0))
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
				if ((angs[0] > 400.0) || (angs[1] > 400.0) || (angs[2] > 400.0))
				{
					AcceptEntityInput(i,"StopAtStartPos");
					AcceptEntityInput(i,"Start");
				}
			}
			else if ((HasEntProp(i,Prop_Data,"m_vecOrigin")) && (StrContains(clsname,"func_",false) == -1) && (StrContains(clsname,"trigger_",false) == -1) && (StrContains(clsname,"ai_",false) == -1) && (StrContains(clsname,"npc_",false) == -1) && (StrContains(clsname,"momentary_rot_button",false) == -1))
			{
				float pos[3];
				GetEntPropVector(i,Prop_Data,"m_vecOrigin",pos);
				if ((TR_PointOutsideWorld(pos)) && ((pos[0] < vMins[0]) || (pos[1] < vMins[1]) && (pos[2] < vMins[2])) && !(((pos[0] <= 1.0) && (pos[0] >= -1.0)) && ((pos[1] <= 1.0) && (pos[1] >= -1.0)) && ((pos[2] <= 1.0) && (pos[2] >= -1.0))))
				{
					if (debugoowlvl)
					{
						char fname[32];
						GetEntPropString(i,Prop_Data,"m_iName",fname,sizeof(fname));
						PrintToServer("%i %s with name %s fell out of world, removing...",i,clsname,fname);
					}
					if (i>MaxClients) AcceptEntityInput(i,"kill");
				}
			}
		}
	}
}

public Action trigout(const char[] output, int caller, int activator, float delay)
{
	char targn[64];
	char scenes[64];
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
	char sname[64];
	GetEntPropString(caller,Prop_Data,"m_iName",sname,sizeof(sname));
	if (strlen(targn) < 1)
		GetEntPropString(caller,Prop_Data,"m_target",targn,sizeof(targn));
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

readoutputs(int scriptent, char[] targn)
{
	Handle filehandle = OpenFile(mapbuf,"r");
	if (filehandle != INVALID_HANDLE)
	{
		char line[128];
		bool readnextlines = false;
		char lineoriginfixup[64];
		char kvs[128][24];
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
				if ((lastpos != linepospass) || (lastpos == 0))
				{
					lastpos = linepospass;
				}
				linepospass = FilePosition(filehandle)-2;
			}
			if (StrContains(line,"\"targetname\"",false) == 0)
			{
				char tmpchar[64];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				TrimString(tmpchar);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
			}
			else if (StrContains(line,"\"template0",false) == 0)
			{
				char tmpchar[64];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"template0","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				strcopy(tmpchar,sizeof(tmpchar),tmpchar[2]);
				TrimString(tmpchar);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
			}
			else if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
			{
				char tmpchar[64];
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
							char ktmp[64];
							char ktmp2[64];
							GetArrayString(passedarr, k, ktmp, sizeof(ktmp));
							k++;
							GetArrayString(passedarr, k, ktmp2, sizeof(ktmp2));
							DispatchKeyValue(ent,ktmp,ktmp2);
						}
						ClearArray(passedarr);
					}
					char tmpchar[128];
					Format(tmpchar,sizeof(tmpchar),line);
					ExplodeString(tmpchar, "\"", kvs, 24, 128, true);
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
					}
					if (StrEqual(clsscript,"scripted_sequence",false))
						AcceptEntityInput(scriptent,"BeginSequence");
					else if (StrEqual(clsscript,"ai_goal_follow",false))
						AcceptEntityInput(scriptent,"Activate");
					else
						AcceptEntityInput(scriptent,"Start");
					break;
				}
			}
			if (StrContains(line,"\"origin\"",false) == 0)
			{
				char tmpchar[64];
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
				char tmpchar[64];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"targetname\" ","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				TrimString(tmpchar);
				Format(lineoriginfixup,sizeof(lineoriginfixup),"%s",tmpchar);
			}
			if ((StrContains(line,"\"actor\"",false) == 0) && (StrEqual(clsscript,"ai_goal_follow",false)))
			{
				char tmpchar[64];
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
					char tmpchar[64];
					char tmpchar2[64];
					char sname[64];
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
					char tmpchar[64];
					Format(tmpchar,sizeof(tmpchar),line);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"classname\" ","",false);
					ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
					if (StrEqual(tmpchar,"worldspawn",false)) break;
					else if (!StrEqual(clsscript,"ai_goal_follow",false))
					{
						ent = CreateEntityByName(tmpchar);
						if (debuglvl == 3) PrintToServer("Created Ent as %s",tmpchar);
					}
				}
			}
		}
		CloseHandle(passedarr);
	}
	CloseHandle(filehandle);
}

findgfollow(int ent, char[] targn)
{
	PrintToServer("Search %i",ent);
	int thisent = FindEntityByClassname(ent,"ai_goal_follow");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char actor[64];
		GetEntPropString(thisent,Prop_Data,"m_iszActor",actor,sizeof(actor));
		if ((strlen(actor) > 0) && (StrEqual(actor,targn,false)))
			readoutputs(thisent,actor);
		else
			findgfollow(thisent++,targn);
	}
}

public OnClientDisconnect(int client)
{
	votetime[client] = 0.0;
}

bool findtargn(char[] targn)
{
	int found,lastfound;
	for (int i = 1; i<GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if (StrContains(clsname,"npc_",false) != -1)
			{
				char ename[64];
				GetEntPropString(i,Prop_Data,"m_iName",ename,sizeof(ename));
				if (StrEqual(ename,targn,false))
				{
					found++;
					lastfound = i;
					if (found > 1)
						CreateTimer(1.0,rechecktarg,lastfound);
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

public Action rechecktarg(Handle timer,int targ)
{
	if (IsValidEntity(targ))
	{
		if (HasEntProp(targ,Prop_Data,"m_iName"))
		{
			char targn[64];
			GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
			findtargn(targn);
		}
	}
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

public restrictpercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public restrictvotech(Handle convar, const char[] oldValue, const char[] newValue)
{
	delaylimit = StringToFloat(newValue);
}
