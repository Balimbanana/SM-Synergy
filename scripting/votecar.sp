#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <voteglobalset>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

Handle globalsarr = INVALID_HANDLE;
Handle vehiclecustomdir = INVALID_HANDLE;
bool isvehiclemap = false;
bool restrictbyveh = true;
bool restrictbyvehon = false;
bool plyhasenteredvehicle = false;
int restrictrm = 0;

float perclimit = 0.66;
float delaylimit = 66.0;

float vehspawnposx[MAXPLAYERS];
float vehspawnposy[MAXPLAYERS];
float vehspawnposz[MAXPLAYERS];
float vehspawnangx[MAXPLAYERS];
float vehspawnangy[MAXPLAYERS];
float vehspawnangz[MAXPLAYERS];
float votetime[MAXPLAYERS];
int vehholo[MAXPLAYERS];
int vehiclemdltype[MAXPLAYERS];
int plyvehicle[MAXPLAYERS];
int clused = 0;
char vehicletype[64];

char mapbuf[64];

bool BoatsHaveGuns = false;
bool JeepsHaveGuns = false;
int vehsetown = 0;

int useapc = 0;
int usejal = 0;
//int collisiongroup = -1;

public Plugin:myinfo = 
{
	name = "CCreateVehicle",
	author = "Balimbanana",
	description = "Creates vehicles with error correction",
	version = "1.11",
	url = "https://github.com/Balimbanana/SM-Synergy/"
}

public void OnPluginStart()
{
	LoadTranslations("votecar.phrases");
	LoadTranslations("basevotes.phrases");
	globalsarr = CreateArray(16);
	vehiclecustomdir = CreateArray(64);
	RegConsoleCmd("votecar",votecar);
	RegConsoleCmd("votecarskin",votecarskin);
	RegConsoleCmd("votecarremove",removeclvehicle);
	Handle restrictbyvehh = CreateConVar("sm_votecarrestrict", "1", "Restrict voting for cars on non-vehicle maps. 0 is unrestricted, 1 is by info_global_settings and 2 is by first entering vehicle.", _, true, 0.0, true, 2.0);
	if (GetConVarInt(restrictbyvehh) == 0)
	{
		restrictbyveh = false;
		restrictbyvehon = false;
	}
	else if (GetConVarInt(restrictbyvehh) == 1)
	{
		restrictbyveh = true;
		restrictbyvehon = false;
	}
	else if (GetConVarInt(restrictbyvehh) == 2)
	{
		restrictbyveh = false;
		restrictbyvehon = true;
	}
	HookConVarChange(restrictbyvehh, restrictvehch);
	CloseHandle(restrictbyvehh);
	Handle votepercentvehh = CreateConVar("sm_votecarpercent", "0.66", "People need to vote to at least this percent to pass.", _, true, 0.0, true, 1.0);
	perclimit = GetConVarFloat(votepercentvehh);
	HookConVarChange(votepercentvehh, restrictvehpercch);
	CloseHandle(votepercentvehh);
	Handle votedelayvehh = CreateConVar("sm_votecartime", "60", "Time to wait between votes.", _, true, 0.0, false);
	delaylimit = GetConVarFloat(votedelayvehh);
	HookConVarChange(votedelayvehh, restrictvehdelch);
	CloseHandle(votedelayvehh);
	Handle vcarownh = CreateConVar("sm_votecarowner", "0", "Sets cars created by votecar to be owned by the creator.", _, true, 0.0, true, 1.0);
	vehsetown = GetConVarInt(vcarownh);
	HookConVarChange(vcarownh, restrictvehownch);
	CloseHandle(vcarownh);
	Handle vcarrmresh = CreateConVar("sm_votecarremove", "0", "0 allows removing of vehicles while there are passengers, 1 requires vehicle has no passengers to remove.", _, true, 0.0, true, 1.0);
	restrictrm = GetConVarInt(vcarrmresh);
	HookConVarChange(vcarrmresh, restrictvehrmresch);
	CloseHandle(vcarrmresh);
	HookEntityOutput("prop_vehicle_jeep","PlayerOn",EntityOutput:playeron);
	HookEntityOutput("prop_vehicle_jeep_episodic","PlayerOn",EntityOutput:playeron);
	HookEntityOutput("prop_vehicle_airboat","PlayerOn",EntityOutput:playeron);
	HookEntityOutput("prop_vehicle_mp","PlayerOn",EntityOutput:playeron);
	AutoExecConfig(true, "votecar");
}

public void OnMapStart()
{
	voteinprogress = false;
	GetCurrentMap(mapbuf, sizeof(mapbuf));
	//collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	ClearArray(globalsarr);
	if (restrictbyveh)
	{
		isvehiclemap = false;
		findglobals(-1,"info_global_settings");
	}
	useapc = FileExists("models/vehicles/combine_apcdrivable.mdl",false);
	usejal = FileExists("models/vehicle.mdl",true,NULL_STRING);
	if (restrictbyvehon)
		plyhasenteredvehicle = false;
	//PrintToServer("APC: %i, Jalopy %i",useapc,usejal);
	//Override no apc use
	useapc = false;
	ClearArray(vehiclecustomdir);
	if (DirExists("custom/vehiclepack/models"))
	{
		char sbuf[128];
		Format(sbuf, sizeof(sbuf), "custom/vehiclepack");
		recursion(sbuf);
	}
	for (int i = 0; i<MaxClients+1; i++)
		plyvehicle[i] = 0;
}

public Action votecar(int client, int args)
{
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("Type of Vehicle");
	
	menu.AddItem("1","Jeep 2-Seater");
	menu.AddItem("2","Airboat");
	menu.AddItem("3","Van");
	menu.AddItem("4","Truck");
	menu.AddItem("5","Elite Jeep");
	if (usejal)
		menu.AddItem("6","Jalopy");
	if (useapc)
		menu.AddItem("7","APC");
	if (plyvehicle[client])
		menu.AddItem("remvh","Remove Vehicle");
	
	if (GetArraySize(vehiclecustomdir) > 0)
	{
		for (int k;k<GetArraySize(vehiclecustomdir);k++)
		{
			char ktmp[92];
			char ktmpd[92];
			GetArrayString(vehiclecustomdir, k, ktmp, sizeof(ktmp));
			Format(ktmpd,sizeof(ktmpd),ktmp);
			ReplaceString(ktmpd,sizeof(ktmpd),"custom/vehiclepack/models/","", false);
			ReplaceString(ktmpd,sizeof(ktmpd),".mdl","", false);
			ktmpd[0] &= ~(1 << 5);
			menu.AddItem(ktmp, ktmpd);
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, 120);
	
	return Plugin_Handled;
}

public Action votecarskin(int client, int args)
{
	if (plyvehicle[client])
	{
		char h[8];
		GetCmdArg(1,h,sizeof(h));
		int skinnum = StringToInt(h);
		SetVariantInt(skinnum);
		AcceptEntityInput(plyvehicle[client],"Skin");
	}
	else PrintToChat(client,"%T","NoVehicle",client);
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (StrEqual(sArgs,"votecar",false))
	{
		votecar(client,0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	float Time = GetTickedTime();
	char info[128];
	if (action == MenuAction_Select)
	{
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info,"remvh",false))
		{
			remvh(param1,plyvehicle[param1]);
			return 0;
		}
	}
	if ((action == MenuAction_Select) && (votetime[param1] <= Time) && (!voteinprogress))
	{
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info,"remvh",false))
		{
			remvh(param1,plyvehicle[param1]);
			delete menu;
		}
		if ((StringToInt(info) > 0) && (StringToInt(info) < 8))
			vehiclemdltype[param1] = StringToInt(info);
		else
			vehiclemdltype[param1] = 100;
		if (CCreateVehicle(param1,info))
		{
			new String:buff[PLATFORM_MAX_PATH];
			char nick[PLATFORM_MAX_PATH];
			GetClientName(param1,nick,sizeof(nick));
			if (vehiclemdltype[param1] == 1)
			{
				Format(buff,sizeof(buff),"Spawn 2-Seater Jeep where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"2-Seater Jeep");
			}
			else if (vehiclemdltype[param1] == 2)
			{
				Format(buff,sizeof(buff),"Spawn Airboat where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"Airboat");
			}
			else if (vehiclemdltype[param1] == 3)
			{
				Format(buff,sizeof(buff),"Spawn Van where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"Van");
			}
			else if (vehiclemdltype[param1] == 4)
			{
				Format(buff,sizeof(buff),"Spawn Truck where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"Truck");
			}
			else if (vehiclemdltype[param1] == 5)
			{
				Format(buff,sizeof(buff),"Spawn Elite Jeep where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"Elite Jeep");
			}
			else if ((vehiclemdltype[param1] == 6) && (usejal))
			{
				Format(buff,sizeof(buff),"Spawn Jalopy where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"Jalopy");
			}
			else if ((vehiclemdltype[param1] == 7) && (useapc))
			{
				Format(buff,sizeof(buff),"Spawn APC where %s is looking?",nick);
				Format(vehicletype,sizeof(vehicletype),"APC");
			}
			else if (vehiclemdltype[param1] == 100)
			{
				char ktmpd[92];
				Format(ktmpd,sizeof(ktmpd),info);
				ReplaceString(ktmpd,sizeof(ktmpd),"custom/vehiclepack/models/","", false);
				ReplaceString(ktmpd,sizeof(ktmpd),".mdl","", false);
				ktmpd[0] &= ~(1 << 5);
				Format(buff,sizeof(buff),"Spawn %s where %s is looking?",ktmpd,nick);
				Format(vehicletype,sizeof(vehicletype),ktmpd);
			}
			if (strlen(buff) > 1)
			{
				clused = param1;
				g_voteType = voteType:question;
				g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
				g_hVoteMenu.SetTitle(buff);
				g_hVoteMenu.AddItem(VOTE_YES, "Yes");
				g_hVoteMenu.AddItem(VOTE_NO, "No");
				g_hVoteMenu.ExitButton = false;
				g_hVoteMenu.DisplayVoteToAll(20);
				voteinprogress = true;
				votetime[param1] = Time + delaylimit;
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if ((voteinprogress) || (IsVoteInProgress()))
	{
		PrintToChat(param1,"There is a vote already in progress.");
	}
	else if (votetime[param1] > Time)
	{
		PrintToChat(param1,"%T","delaytovote",param1,RoundFloat(votetime[param1])-RoundFloat(Time));
	}
	else
	{
		
	}
	return 0;
}

public recursion(const String:sbuf[128])
{
	char buff[128];
	Handle msubdirlisting = OpenDirectory(sbuf, false);
	while (ReadDirEntry(msubdirlisting, buff, sizeof(buff)))
	{
		if ((!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))) && (!(msubdirlisting == INVALID_HANDLE)))
		{
			if ((!(StrContains(buff, ".ztmp") != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
			{
				char buff2[128];
				Format(buff2,sizeof(buff2),"%s/%s",sbuf,buff);
				if ((StrContains(buff2, ".mdl", false) != -1) && !(StrContains(buff2, "_gib", false) != -1) && !(StrContains(buff2, "_shell", false) != -1) && !(StrContains(buff2, "_wheel", false) != -1) && !(StrContains(buff2, "_static", false) != -1))
					PushArrayString(vehiclecustomdir, buff2);
				if (!(StrContains(buff2, ".", false) != -1))
					recursion(buff2);
			}
		}
	}
	CloseHandle(msubdirlisting);
}

public Handler_VoteCallback(Menu menu, MenuAction action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
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
		if (IsValidEntity(vehholo[clused]) && (vehholo[clused] != 0))
			AcceptEntityInput(vehholo[clused],"kill");
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
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = GetVotePercent(votes, totalVotes);

		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		//PrintToServer("%f %f %i",percent,perclimit,FloatCompare(percent,perclimit));
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,perclimit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t","Vote Failed", RoundToNearest(100.0*perclimit), RoundToNearest(100.0*percent), totalVotes);
			if (IsValidEntity(vehholo[clused]) && (vehholo[clused] != 0))
				AcceptEntityInput(vehholo[clused],"kill");
		}
		else
		{
			char buff[128];
			char nick[PLATFORM_MAX_PATH];
			GetClientName(clused,nick,sizeof(nick));
			Format(buff,sizeof(buff),"Spawning %s where %s defined",vehicletype,nick);
			PrintToChatAll("%t","Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			PrintToChatAll(buff);
			CreateVehicle(clused);
		}
	}
	return 0;
}

bool:CCreateVehicle(client,char[] vehiclemodel)
{
	if (client == 0)
		return false;
	if (restrictbyveh)
	{
		if (GetArraySize(globalsarr) < 1)
			findglobals(-1,"info_global_settings");
		else
		{
			for (int j = 0;j<GetArraySize(globalsarr);j++)
			{
				char itmp[32];
				GetArrayString(globalsarr, j, itmp, sizeof(itmp));
				int glo = StringToInt(itmp);
				if (IsValidEntity(glo))
				{
					int state = GetEntProp(glo,Prop_Data,"m_bIsVehicleMap");
					if (state == 1)
					{
						isvehiclemap = true;
						if ((StrEqual(mapbuf,"ep2_outland_02",false)) || (StrEqual(mapbuf,"jump_portal_b83",false)))
							isvehiclemap = false;
					}
					else if (state == 0)
						isvehiclemap = false;
				}
			}
		}
	}
	else if (restrictbyvehon)
	{
		if (plyhasenteredvehicle)
			isvehiclemap = true;
	}
	else
		isvehiclemap = true;
	int vck = GetEntProp(client, Prop_Send, "m_hVehicle");
	if ((isvehiclemap) && (vck == -1) && (!IsInView(client)) && (!(GetEntityRenderFx(client) == RENDERFX_DISTORT)))
	{
		float PlayerOrigin[3];
		float Location[3];
		float fhitpos[3];
		float clangles[3];
		GetClientEyeAngles(client, clangles);
		GetClientEyePosition(client, Location);
		PlayerOrigin[0] = (Location[0] + (60 * Cosine(DegToRad(clangles[1]))));
		PlayerOrigin[1] = (Location[1] + (60 * Sine(DegToRad(clangles[1]))));
		PlayerOrigin[2] = (Location[2] + 10);
		Location[0] = (PlayerOrigin[0] + (10 * Cosine(DegToRad(clangles[1]))));
		Location[1] = (PlayerOrigin[1] + (10 * Sine(DegToRad(clangles[1]))));
		Location[2] = (PlayerOrigin[2] + 10);
		Handle hhitpos = INVALID_HANDLE;
		TR_TraceRay(Location,clangles,MASK_SHOT,RayType_Infinite);
		TR_GetEndPosition(fhitpos,hhitpos);
		fhitpos[2] += 10.0;
		float chkdist = GetVectorDistance(PlayerOrigin,fhitpos,false);
		
		if ((RoundFloat(chkdist) >= 80) && (RoundFloat(chkdist) <= 500))
		{
			float fhitposx[3];
			hhitpos = INVALID_HANDLE;
			fhitpos[2]+= 10.0;
			float clanglesx[3];
			clanglesx = clangles;
			clanglesx[0] = 0.0;
			TR_TraceRay(fhitpos,clanglesx,MASK_SOLID_BRUSHONLY,RayType_Infinite);
			TR_GetEndPosition(fhitposx,hhitpos);
			chkdist = GetVectorDistance(fhitpos,fhitposx,false);
			
			if (RoundFloat(chkdist) >= 65)
			{
				clanglesx[1] += 90.0;
				TR_TraceRay(fhitpos,clanglesx,MASK_SOLID_BRUSHONLY,RayType_Infinite);
				TR_GetEndPosition(fhitposx,hhitpos);
				float chkdistl = GetVectorDistance(fhitpos,fhitposx,false);
				
				clanglesx[1] -= 180.0;
				TR_TraceRay(fhitpos,clanglesx,MASK_SOLID_BRUSHONLY,RayType_Infinite);
				TR_GetEndPosition(fhitposx,hhitpos);
				float chkdistr = GetVectorDistance(fhitpos,fhitposx,false);
				
				float tmpforward[3];
				tmpforward[0] = (fhitpos[0] + (60 * Cosine(DegToRad(clangles[1]))));
				tmpforward[1] = (fhitpos[1] + (60 * Sine(DegToRad(clangles[1]))));
				tmpforward[2] = fhitpos[2];
				clanglesx[1] -= 180.0;
				TR_TraceRay(tmpforward,clanglesx,MASK_SOLID_BRUSHONLY,RayType_Infinite);
				TR_GetEndPosition(fhitposx,hhitpos);
				float chkdistfr = GetVectorDistance(tmpforward,fhitposx,false);
				
				clanglesx[1] -= 180.0;
				TR_TraceRay(tmpforward,clanglesx,MASK_SOLID_BRUSHONLY,RayType_Infinite);
				TR_GetEndPosition(fhitposx,hhitpos);
				float chkdistfl = GetVectorDistance(tmpforward,fhitposx,false);
				
				//PrintToChat(client,"Left %i Right %i FL %i FR %i",RoundFloat(chkdistl),RoundFloat(chkdistr),RoundFloat(chkdistfr),RoundFloat(chkdistfl));
				
				if ((RoundFloat(chkdistl) > 60) && (RoundFloat(chkdistr) > 60) && (RoundFloat(chkdistfl) > 60) && (RoundFloat(chkdistfr) > 60))
				{
					vehholo[client] = CreateEntityByName("prop_dynamic");
					clangles[0] = 0.0;
					clangles[1] -= 90.0;
					vehspawnposx[client] = fhitpos[0];
					vehspawnposy[client] = fhitpos[1];
					vehspawnposz[client] = fhitpos[2];
					vehspawnangx[client] = clangles[0];
					vehspawnangy[client] = clangles[1];
					vehspawnangz[client] = clangles[2];
					TeleportEntity(vehholo[client], fhitpos, clangles, NULL_VECTOR);
					if (vehiclemdltype[client] == 1)
						DispatchKeyValue(vehholo[client], "model", "models/vehicles/buggy_p2.mdl");
					else if (vehiclemdltype[client] == 2)
						DispatchKeyValue(vehholo[client], "model", "models/airboat.mdl");
					else if (vehiclemdltype[client] == 3)
						DispatchKeyValue(vehholo[client], "model", "models/vehicles/7seatvan.mdl");
					else if (vehiclemdltype[client] == 4)
						DispatchKeyValue(vehholo[client], "model", "models/vehicles/8seattruck.mdl");
					else if (vehiclemdltype[client] == 5)
						DispatchKeyValue(vehholo[client], "model", "models/vehicles/buggy_elite.mdl");
					else if ((vehiclemdltype[client] == 6) && (useapc) && (!usejal))
						DispatchKeyValue(vehholo[client], "model", "models/vehicles/combine_apcdrivable.mdl");
					else if ((vehiclemdltype[client] == 6) && (usejal) && (useapc))
						DispatchKeyValue(vehholo[client], "model", "models/vehicle.mdl");
					else if ((vehiclemdltype[client] == 6) && (usejal) && (!useapc))
						DispatchKeyValue(vehholo[client], "model", "models/vehicle.mdl");
					else if ((vehiclemdltype[client] == 7) && (usejal) && (useapc))
						DispatchKeyValue(vehholo[client], "model", "models/vehicles/combine_apcdrivable.mdl");
					else if (vehiclemdltype[client] == 100)
						DispatchKeyValue(vehholo[client], "model", vehiclemodel);
					DispatchKeyValue(vehholo[client], "solid","0");
					DispatchKeyValue(vehholo[client], "spawnflags","12");
					DispatchSpawn(vehholo[client]);
					ActivateEntity(vehholo[client]);
					SetEntityRenderColor(vehholo[client],255,0,0,255);
					SetEntityRenderFx(vehholo[client],RENDERFX_HOLOGRAM);
					SetEntityMoveType(vehholo[client],MOVETYPE_NOCLIP);
					return true;
				}
				else if ((RoundFloat(chkdistl) <= 60) || (RoundFloat(chkdistfl) > 60))
					PrintToChat(client,"%T","tooclosetoleft",client);
				else if ((RoundFloat(chkdistr) <= 60) || (RoundFloat(chkdistfr) > 60))
					PrintToChat(client,"%T","tooclosetoright",client);
			}
			else if (RoundFloat(chkdist) <= 65)
				PrintToChat(client,"%T","tooclosetofront",client);
		}
		else if (RoundFloat(chkdist) <= 80)
			PrintToChat(client,"%T","tooclosetofront",client);
		//PrintToChat(client,"Player at %i %i %i, spawn vehicle at %i %i %i",RoundFloat(PlayerOrigin[0]),RoundFloat(PlayerOrigin[1]),RoundFloat(PlayerOrigin[2]),RoundFloat(fhitpos[0]),RoundFloat(fhitpos[1]),RoundFloat(fhitpos[2]));
	}
	else
		PrintToChat(client,"%T","cannotspawn",client);
	return false;
}

public restrictvehch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		restrictbyveh = true;
		restrictbyvehon = false;
		ClearArray(globalsarr);
		findglobals(-1,"info_global_settings");
	}
	else if (StringToInt(newValue) == 2)
	{
		restrictbyveh = false;
		restrictbyvehon = true;
		ClearArray(globalsarr);
	}
	else
	{
		restrictbyveh = false;
		restrictbyvehon = false;
	}
}

public restrictvehpercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public restrictvehdelch(Handle convar, const char[] oldValue, const char[] newValue)
{
	delaylimit = StringToFloat(newValue);
}

public restrictvehownch(Handle convar, const char[] oldValue, const char[] newValue)
{
	int nval = StringToInt(newValue);
	if ((nval < 2) && (nval > -1))
		vehsetown = nval;
}

public restrictvehrmresch(Handle convar, const char[] oldValue, const char[] newValue)
{
	int nval = StringToInt(newValue);
	if ((nval < 2) && (nval > -1))
		restrictrm = nval;
}

bool:IsInView(client)
{
	new m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
	char classname[20];
	if (IsValidEdict(m_hViewEntity) && GetEdictClassname(m_hViewEntity, classname, sizeof(classname)))
		if(StrEqual(classname, "point_viewcontrol"))
			return true;
	return false;
}

CreateVehicle(client)
{
	if (clused != 0)
	{
		if ((IsClientConnected(client)) && (IsClientInGame(client)))
		{
			if ((vehspawnposx[client] != 0.0) && (vehspawnposy[client] != 0.0) && (vehspawnposz[client] != 0.0))
			{
				float tmppos[3];
				tmppos[0] = vehspawnposx[client];
				tmppos[1] = vehspawnposy[client];
				tmppos[2] = vehspawnposz[client];
				float tmpang[3];
				tmpang[0] = vehspawnangx[client];
				tmpang[1] = vehspawnangy[client];
				tmpang[2] = vehspawnangz[client];
				int veh = -1;
				if (vehiclemdltype[client] == 1)
				{
					veh = CreateEntityByName("prop_vehicle_jeep");
					DispatchKeyValue(veh, "model", "models/vehicles/buggy_p2.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/jeep_test.txt");
					findent(MaxClients+1,"prop_vehicle_jeep");
					findent(MaxClients+1,"prop_vehicle_mp");
					if (JeepsHaveGuns)
						DispatchKeyValue(veh, "EnableGun","1");
				}
				else if (vehiclemdltype[client] == 2)
				{
					veh = CreateEntityByName("prop_vehicle_airboat");
					DispatchKeyValue(veh, "model", "models/airboat.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/airboat.txt");
					findent(MaxClients+1,"prop_vehicle_airboat");
					if (BoatsHaveGuns)
						DispatchKeyValue(veh, "EnableGun","1");
				}
				else if (vehiclemdltype[client] == 3)
				{
					veh = CreateEntityByName("prop_vehicle_mp");
					DispatchKeyValue(veh, "model", "models/vehicles/7seatvan.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/van.txt");
				}
				else if (vehiclemdltype[client] == 4)
				{
					veh = CreateEntityByName("prop_vehicle_mp");
					DispatchKeyValue(veh, "model", "models/vehicles/8seattruck.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/truck.txt");
				}
				else if (vehiclemdltype[client] == 5)
				{
					veh = CreateEntityByName("prop_vehicle_jeep");
					DispatchKeyValue(veh, "model", "models/vehicles/buggy_elite.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/jeep_elite.txt");
					findent(MaxClients+1,"prop_vehicle_jeep");
					findent(MaxClients+1,"prop_vehicle_mp");
					if (JeepsHaveGuns)
						DispatchKeyValue(veh, "EnableGun","1");
				}
				else if ((vehiclemdltype[client] == 6) && (useapc) && (!usejal))
				{
					veh = CreateEntityByName("prop_vehicle_jeep");
					DispatchKeyValue(veh, "model", "models/vehicles/combine_apcdrivable.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/drivable_apc.txt");
					findent(MaxClients+1,"prop_vehicle_jeep");
					findent(MaxClients+1,"prop_vehicle_mp");
					if (JeepsHaveGuns)
						DispatchKeyValue(veh, "EnableGun","1");
				}
				else if ((vehiclemdltype[client] == 6) && (usejal) && (useapc))
				{
					veh = CreateEntityByName("prop_vehicle_jeep_episodic");
					DispatchKeyValue(veh, "model", "models/vehicle.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/jeep_test.txt");
				}
				else if ((vehiclemdltype[client] == 6) && (usejal) && (!useapc))
				{
					veh = CreateEntityByName("prop_vehicle_jeep_episodic");
					DispatchKeyValue(veh, "model", "models/vehicle.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/jeep_test.txt");
				}
				else if ((vehiclemdltype[client] == 7) && (usejal) && (useapc))
				{
					veh = CreateEntityByName("prop_vehicle_jeep");
					DispatchKeyValue(veh, "model", "models/vehicles/combine_apcdrivable.mdl");
					DispatchKeyValue(veh, "vehiclescript", "scripts/vehicles/drivable_apc.txt");
					findent(MaxClients+1,"prop_vehicle_jeep");
					findent(MaxClients+1,"prop_vehicle_mp");
					if (JeepsHaveGuns)
						DispatchKeyValue(veh, "EnableGun","1");
				}
				else if (vehiclemdltype[client] == 100)
				{
					veh = CreateEntityByName("prop_vehicle_jeep");
					char cmodel[128];
					GetEntPropString(vehholo[client],Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
					char tmpscr[92];
					Format(tmpscr,sizeof(tmpscr),cmodel);
					ReplaceString(tmpscr,sizeof(tmpscr),"/models/","/scripts/vehicles/", false);
					ReplaceString(tmpscr,sizeof(tmpscr),".mdl",".txt", false);
					if (FileExists(tmpscr,false))
						DispatchKeyValue(veh,"vehiclescript",tmpscr);
					else
						DispatchKeyValue(veh,"vehiclescript","scripts/vehicles/jeep_test.txt");
					DispatchKeyValue(veh,"EnableGun","0");
					if (StrContains(cmodel,"mini",false) != -1)
					{
						SetVariantInt(1023);
						AcceptEntityInput(veh,"setbodygroup");
					}
					else if ((StrContains(cmodel,"lambo",false) != -1) || (StrContains(cmodel,"shelby",false) != -1))
					{
						SetVariantInt(511);
						AcceptEntityInput(veh,"setbodygroup");
					}
					else if (StrContains(cmodel,"caterham",false) != -1)
					{
						SetVariantInt(7);
						AcceptEntityInput(veh,"setbodygroup");
					}
					DispatchKeyValue(veh, "model", cmodel);
					findent(MaxClients+1,"prop_vehicle_jeep");
					findent(MaxClients+1,"prop_vehicle_mp");
				}
				if (IsValidEntity(vehholo[client]) && (vehholo[client] != 0))
					AcceptEntityInput(vehholo[client],"kill");
				vehholo[client] = 0;
				TeleportEntity(veh, tmppos, tmpang, NULL_VECTOR);
				DispatchKeyValue(veh, "solid","6");
				DispatchKeyValue(veh, "actionScale","1");
				DispatchKeyValue(veh, "ignorenormals","0");
				DispatchKeyValue(veh, "fadescale","1");
				DispatchKeyValue(veh, "fademindist","-1");
				DispatchKeyValue(veh, "VehicleLocked","0");
				DispatchKeyValue(veh, "screenspacefade","0");
				DispatchKeyValue(veh, "skin","0");
				DispatchSpawn(veh);
				ActivateEntity(veh);
				//SetEntData(veh, collisiongroup, 5, 4, true);
				if ((vehsetown) && (HasEntProp(veh,Prop_Data,"m_iOnlyUser")))
					SetEntProp(veh,Prop_Data,"m_iOnlyUser",client);
				plyvehicle[client] = veh;
			}
		}
	}
	clused = 0;
}

public Action playeron(const char[] output, int caller, int activator, float delay)
{
	plyhasenteredvehicle = true;
	if ((GetEntProp(caller,Prop_Send,"m_iPassengerCount") > 1) && (HasEntProp(caller,Prop_Data,"m_iOnlyUser")))
		SetEntProp(caller,Prop_Data,"m_iOnlyUser",-1);
	return Plugin_Continue;
}

public Action findent(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char prevtmp[16];
		Format(prevtmp, sizeof(prevtmp), "%i", thisent);
		int gunstate = GetEntProp(thisent,Prop_Data,"m_bHasGun");
		if ((StrEqual(clsname,"prop_vehicle_airboat")) && (gunstate))
			BoatsHaveGuns = true;
		else if (gunstate)
			JeepsHaveGuns = true;
		findent(thisent++,clsname);
	}
	return Plugin_Handled;
}

public Action findglobals(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char prevtmp[16];
		Format(prevtmp, sizeof(prevtmp), "%i", thisent);
		int state = GetEntProp(thisent,Prop_Data,"m_bIsVehicleMap");
		if (state == 1)
			isvehiclemap = true;
		else if (state == 0)
			isvehiclemap = false;
		if((thisent >= 0) && (FindStringInArray(globalsarr, prevtmp) == -1))
		{
			PushArrayString(globalsarr, prevtmp);
		}
		findglobals(thisent++,clsname);
	}
	return Plugin_Handled;
}

public OnClientDisconnect(int client)
{
	initcl(client);
}

public initcl(client)
{
	vehspawnposx[client] = 0.0;
	vehspawnposy[client] = 0.0;
	vehspawnposz[client] = 0.0;
	vehspawnangx[client] = 0.0;
	vehspawnangy[client] = 0.0;
	vehspawnangz[client] = 0.0;
	votetime[client] = 0.0;
	if (IsValidEntity(vehholo[client]) && (vehholo[client] != 0))
		AcceptEntityInput(vehholo[client],"kill");
	vehholo[client] = 0;
	vehiclemdltype[client] = 0;
	if (plyvehicle[client] != 0)
		remvh(client,plyvehicle[client]);
	plyvehicle[client] = 0;
}

public Action removeclvehicle(int client, int args)
{
	if (plyvehicle[client] != 0)
	{
		remvh(client,plyvehicle[client]);
	}
	else
		PrintToChat(client,"%T",client,"NoVehicle");
	return Plugin_Handled;
}

remvh(int client, int ent)
{
	if ((ent != 0) && IsValidEntity(ent) && IsEntNetworkable(ent))
	{
		char clsname[32];
		GetEntityClassname(ent,clsname,sizeof(clsname));
		if (StrContains(clsname,"prop_vehicle",false) != -1)
		{
			if (restrictrm)
			{
				char netname[64];
				GetEntityNetClass(ent,netname,sizeof(netname));
				int vehoffs = FindSendPropInfo(netname, "m_hPlayer");
				int plyinvehicle;
				if (vehoffs != -1)
				{
					plyinvehicle = GetEntDataEnt2(ent, vehoffs);
					if (plyinvehicle == -1)
					{
						AcceptEntityInput(ent,"kill");
						plyvehicle[client] = 0;
					}
					else if (IsClientConnected(client))
						PrintToChat(client,"%T","CannotRemove");
				}
			}
			else
			{
				AcceptEntityInput(ent,"kill");
				plyvehicle[client] = 0;
			}
		}
	}
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

VoteMenuClose()
{
	delete g_hVoteMenu;
	g_hVoteMenu = null;
}
