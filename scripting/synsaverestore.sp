#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool enterfrom04 = false;
bool enterfrom04pb = false;
bool enterfrom03 = false;
bool enterfrom03pb = false;
bool enterfrom08 = false;
bool enterfrom08pb = false;
bool reloadingmap = false;
bool allowreloadsaves = false;
int reloadtype = 0;
float votetime = 0.0;
float perclimit = 0.80; //Percent of all players to vote yes

Handle globalsarr = INVALID_HANDLE;
Handle globalsiarr = INVALID_HANDLE;

char mapbuf[128];
char savedir[64];
char reloadthissave[32];

public Plugin:myinfo = 
{
	name = "SynSaveRestore",
	author = "Balimbanana",
	description = "Allows you to create persistant saves and reload them per-map.",
	version = "1.0",
	url = "https://github.com/Balimbanana/SM-Synergy"
}

enum voteType
{
	question
}
Menu g_hVoteMenu = null;
new voteType:g_voteType = voteType:question;
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

public void OnPluginStart()
{
	LoadTranslations("basevotes.phrases");
	globalsarr = CreateArray(32);
	globalsiarr = CreateArray(32);
	RegAdminCmd("savegame",savecurgame,ADMFLAG_RESERVATION,".");
	RegAdminCmd("loadgame",loadgame,ADMFLAG_PASSWORD,".");
	RegConsoleCmd("votereload",votereloadchk);
	char savepath[256];
	BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves");
	if (!DirExists(savepath)) CreateDirectory(savepath,511);
	Handle votereloadcvarh = CreateConVar("sm_reloadsaves", "1", "Enable anyone to vote to reload a saved game, default is 1", _, true, 0.0, true, 1.0);
	if (votereloadcvarh != INVALID_HANDLE) allowreloadsaves = GetConVarBool(votereloadcvarh);
	HookConVarChange(votereloadcvarh, votereloadcvar);
	CloseHandle(votereloadcvarh);
	Handle votepercenth = CreateConVar("sm_voterestore", "0.80", "People need to vote to at least this percent to pass checkpoint and map reload.", _, true, 0.0, true, 1.0);
	perclimit = GetConVarFloat(votepercenth);
	HookConVarChange(votepercenth, restrictvotepercch);
}

public votereloadcvar(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0) allowreloadsaves = false;
	else allowreloadsaves = true;
}

public restrictvotepercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public Action votereloadchk(int client, int args)
{
	Handle panel = CreatePanel();
	SetPanelTitle(panel, "Reload Type");
	DrawPanelItem(panel, "Reload Map");
	DrawPanelItem(panel, "Reload Checkpoint");
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
	menu.AddItem("checkpoint","The current last checkpoint");
	if (allowreloadsaves)
	{
		char savepath[256];
		BuildPath(Path_SM,savepath,sizeof(savepath),"data/SynSaves/%s",mapbuf);
		Handle savedirh = OpenDirectory(savepath, false);
		if (savedirh != INVALID_HANDLE)
		{
			char subfilen[32];
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

public Action savecurgame(int client, int args)
{
	int loginp = FindEntityByClassname(0, "logic_autosave");
	if (loginp == -1)
	{
		loginp = CreateEntityByName("logic_autosave");
		if (loginp != -1)
		{
			DispatchKeyValue(loginp, "targetname","syn_autosave");
			DispatchSpawn(loginp);
			ActivateEntity(loginp);
			AcceptEntityInput(loginp,"Save");
		}
	}
	else if ((loginp > 0) || (loginp < -1))
	{
		AcceptEntityInput(loginp,"Save");
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
			return Plugin_Handled;
		}
	}
	CloseHandle(dp);
	Format(fchk,sizeof(fchk),"%s\\%s",savepath,ctimestamp);
	if (!DirExists(fchk)) CreateDirectory(fchk,511);
	Handle savedirh = OpenDirectory(savedir, false);
	char subfilen[32];
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
					char nullb[2];
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
	if (DirExists(fchk))
	{
		if (client == 0) PrintToServer("Save created with name: %s",ctimestamp);
		else PrintToChat(client,"Save created with name: %s",ctimestamp);
	}
	return Plugin_Handled;
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
	char subfilen[32];
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

public MenuHandler(Menu menu, MenuAction action, int param1, int param2)
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

loadthissave(char[] info)
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
				if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
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
		CreateTimer(1.0,reloadtimer);
	}
}

public Action reloadtimer(Handle timer)
{
	new thereload = CreateEntityByName("player_loadsaved");
	DispatchSpawn(thereload);
	ActivateEntity(thereload);
	AcceptEntityInput(thereload, "Reload");
}

public MenuHandlervote(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		float Time = GetTickedTime();
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info,"back",false))
			votereloadchk(param1,0);
		else if ((StrEqual(info,"map",false)) && (votetime <= Time))
		{
			new String:buff[32];
			g_voteType = voteType:question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
			Format(buff,sizeof(buff),"Reload Current Map?");
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 2;
		}
		else if ((StrEqual(info,"checkpoint",false)) && (votetime <= Time))
		{
			new String:buff[32];
			g_voteType = voteType:question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
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
			new String:buff[64];
			g_voteType = voteType:question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
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

public PanelHandlervotetype(Handle:menu, MenuAction:action, int client, int param1)
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
		CloseHandle(menu);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
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
		
		percent = GetVotePercent(votes, totalVotes);

		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,perclimit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t","Vote Failed", RoundToNearest(100.0*perclimit), RoundToNearest(100.0*percent), totalVotes);
			Format(reloadthissave,sizeof(reloadthissave),"");
		}
		else
		{
			if (reloadtype == 1) CreateTimer(0.1,reloadtimer);
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
			PrintToChatAll("%t","Vote Successful", RoundToNearest(100.0*percent), totalVotes);
		}
	}
	return 0;
}

public void OnMapStart()
{
	Handle savedirh = FindConVar("sv_savedir");
	if (savedirh != INVALID_HANDLE)
	{
		GetConVarString(savedirh,savedir,sizeof(savedir));
		if (StrContains(savedir,"\\",false) != -1)
			ReplaceString(savedir,sizeof(savedir),"\\","");
		else if (StrContains(savedir,"/",false) != -1)
			ReplaceString(savedir,sizeof(savedir),"/","");
	}
	CloseHandle(savedirh);
	enterfrom04 = true;
	GetCurrentMap(mapbuf,sizeof(mapbuf));
	if (StrContains(mapbuf,"_spymap_ep3",false) != -1)
		findtrigs(-1,"trigger_once");
	if (reloadingmap)
	{
		if ((enterfrom04pb) && (StrEqual(mapbuf,"ep2_outland_02",false)))
		{
			int spawnpos = CreateEntityByName("info_player_coop");
			DispatchKeyValue(spawnpos, "targetname","syn_spawn_player_3rebuild");
			DispatchKeyValue(spawnpos, "StartDisabled","1");
			DispatchKeyValue(spawnpos, "parentname","elevator");
			float spawnposg[3];
			spawnposg[0] = -3106.0;
			spawnposg[1] = -9455.0;
			spawnposg[2] = -3077.0;
			TeleportEntity(spawnpos,spawnposg,NULL_VECTOR,NULL_VECTOR);
			DispatchSpawn(spawnpos);
			ActivateEntity(spawnpos);
			int loginp = CreateEntityByName("logic_auto");
			DispatchKeyValue(loginp, "spawnflags","1");
			DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Enable,,0,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Trigger,,0.1,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,TouchTest,,0.1,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_3rebuild,0,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","debug_choreo_start_in_elevator,Trigger,,0,-1");
			DispatchSpawn(loginp);
			ActivateEntity(loginp);
		}
		else if (enterfrom04pb)
			enterfrom04pb = false;
		if ((enterfrom03pb) && (StrEqual(mapbuf,"d1_town_02",false)))
		{
			int loginp = CreateEntityByName("logic_auto");
			DispatchKeyValue(loginp, "spawnflags","1");
			DispatchKeyValue(loginp, "OnMapSpawn","edt_alley_push,Enable,,0,1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_wall_temp_ally,ForceSpawn,,1,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_wall_removeme_temp_t02,ForceSpawn,,0,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_3,0,1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_vint_trav_gman,Kill,,0,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_wall_removeme_t03,Kill,,0,-1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_vint_stopplayerjump_1,Kill,,0,-1");
			DispatchSpawn(loginp);
			ActivateEntity(loginp);
		}
		else if (enterfrom03pb)
			enterfrom03pb = false;
		if ((enterfrom08pb) && (StrEqual(mapbuf,"d2_coast_07",false)))
		{
			int loginp = CreateEntityByName("logic_auto");
			DispatchKeyValue(loginp, "spawnflags","1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_shiz,Trigger,,0,1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_4,0,1");
			DispatchSpawn(loginp);
			ActivateEntity(loginp);
		}
		else if (enterfrom08pb)
			enterfrom08pb = false;
		if (GetArraySize(globalsarr) > 0)
		{
			int loginp;
			for (int i = 0;i<GetArraySize(globalsarr);i++)
			{
				char itmp[32];
				GetArrayString(globalsarr, i, itmp, sizeof(itmp));
				int itmpval = GetArrayCell(globalsiarr,i);
				loginp = CreateEntityByName("logic_auto");
				DispatchKeyValue(loginp, "spawnflags","1");
				char formt[64];
				if (itmpval == 1)
					Format(formt,sizeof(formt),"%s,TurnOn,,0,-1",itmp);
				else
					Format(formt,sizeof(formt),"%s,TurnOff,,0,-1",itmp);
				DispatchKeyValue(loginp, "OnMapSpawn", formt);
				PrintToServer("Setting %s to %i",itmp,itmpval);
			}
			if (loginp != 0)
			{
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		reloadingmap = false;
	}
	ClearArray(globalsarr);
	ClearArray(globalsiarr);
	Format(reloadthissave,sizeof(reloadthissave),"");
}

public Action changelevel(Handle timer)
{
	ServerCommand("changelevel %s",mapbuf);
}

findtrigs(int start, char[] type)
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
		PrintToServer(ctst);
		int loginp = CreateEntityByName("logic_auto");
		DispatchKeyValue(loginp, "spawnflags","1");
		DispatchKeyValue(loginp, "globalstate",ctst);
		char ctstinph[64];
		Format(ctstinph,sizeof(ctstinph),"%s,SetCounter,1,0,-1",prevtmp);
		DispatchKeyValue(loginp, "OnMapSpawn",ctstinph);
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
		PrintToServer("%s %i %i",prevtmp,initstate,curstate);
		if((FindStringInArray(globalsarr, prevtmp) == -1) && (curstate != initstate))
		{
			PushArrayString(globalsarr, prevtmp);
			PushArrayCell(globalsiarr, curstate);
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