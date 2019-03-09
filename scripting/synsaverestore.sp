#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#tryinclude <voteglobalset>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

bool enterfrom04 = false;
bool enterfrom04pb = false;
bool enterfrom03 = false;
bool enterfrom03pb = false;
bool enterfrom08 = false;
bool enterfrom08pb = false;
bool reloadingmap = false;
bool allowvotereloadsaves = false; //Set by cvar sm_reloadsaves
bool allowvotecreatesaves = false; //Set by cvar sm_createsaves
bool rmsaves = false; //Set by cvar sm_disabletransition
bool transitionply = false;
bool reloadaftersetup = false;
int WeapList = -1;
int reloadtype = 0;
int logsv = -1;
float votetime = 0.0;
float perclimit = 0.80; //Set by cvar sm_voterestore
float perclimitsave = 0.60; //Set by cvar sm_votecreatesave
float landmarkorigin[3];

Handle globalsarr = INVALID_HANDLE;
Handle globalsiarr = INVALID_HANDLE;
Handle transitionid = INVALID_HANDLE;
Handle transitiondp = INVALID_HANDLE;
Handle transitionplyorigin = INVALID_HANDLE;
Handle transitionents = INVALID_HANDLE;
Handle timouthndl = INVALID_HANDLE;
Handle equiparr = INVALID_HANDLE;

char landmarkname[64];
char mapbuf[128];
char savedir[64];
char reloadthissave[32];

#define PLUGIN_VERSION "1.54"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synsaverestoreupdater.txt"

public Plugin:myinfo = 
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
	globalsarr = CreateArray(32);
	globalsiarr = CreateArray(32);
	transitionid = CreateArray(MAXPLAYERS);
	transitiondp = CreateArray(MAXPLAYERS);
	transitionplyorigin = CreateArray(MAXPLAYERS);
	transitionents = CreateArray(128);
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
	Handle disabletransitionh = CreateConVar("sm_disabletransition", "0", "Disable transition save/reloads.", _, true, 0.0, true, 2.0);
	if (GetConVarInt(disabletransitionh) == 2)
	{
		Handle svcvar = FindConVar("mp_save_disable");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,0,false,false);
		svcvar = FindConVar("sv_autosave");
		if (svcvar != INVALID_HANDLE) SetConVarInt(svcvar,1,false,false);
		CloseHandle(svcvar);
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
		transitionply = false;
	}
	else if (GetConVarInt(disabletransitionh) == 0)
	{
		rmsaves = false;
		transitionply = false;
	}
	HookConVarChange(disabletransitionh, disabletransitionch);
	CloseHandle(disabletransitionh);
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
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
	reloadaftersetup = true;
}

public votereloadcvar(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0) allowvotereloadsaves = false;
	else allowvotereloadsaves = true;
}

public votesavecvar(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0) allowvotecreatesaves = false;
	else allowvotecreatesaves = true;
}

public restrictvotepercch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimit = StringToFloat(newValue);
}

public restrictvotepercsch(Handle convar, const char[] oldValue, const char[] newValue)
{
	perclimitsave = StringToFloat(newValue);
}

public disabletransitionch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 2)
	{
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
		transitionply = false;
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
	menu.AddItem("checkpoint","The current last checkpoint");
	if (allowvotereloadsaves)
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
	if ((logsv != 0) && (logsv != -1) && (IsValidEntity(logsv)))
	{
		saveresetveh();
	}
	else
	{
		logsv = CreateEntityByName("logic_autosave");
		if ((logsv != -1) && (IsValidEntity(logsv)))
		{
			DispatchSpawn(logsv);
			ActivateEntity(logsv);
			saveresetveh();
		}
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
		if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
			GetClientAbsAngles(i,plyangs);
			GetClientAbsOrigin(i,plyorigin);
			char push[128];
			Format(push,sizeof(push),"%sb%1.f %1.f %1.fb%1.f %1.f %1.f",SteamID,plyangs[0],plyangs[1],plyangs[2],plyorigin[0],plyorigin[1],plyorigin[2]);
			WriteFileLine(plyinf,push);
		}
	}
	CloseHandle(plyinf);
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

public MenuHandlerDelSaves(Menu menu, MenuAction action, int param1, int param2)
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
			Handle reloadids = CreateArray(64);
			Handle reloadangs = CreateArray(64);
			Handle reloadorgs = CreateArray(64);
			char sets[3][64];
			char line[72];
			Handle plyinf = OpenFile(plyinffile,"r");
			while(!IsEndOfFile(plyinf)&&ReadFileLine(plyinf,line,sizeof(line)))
			{
				TrimString(line);
				ExplodeString(line,"b",sets,3,64);
				PushArrayString(reloadids,sets[0]);
				PushArrayString(reloadangs,sets[1]);
				PushArrayString(reloadorgs,sets[2]);
				PrintToServer("%s %s %s",sets[0],sets[1],sets[2]);
			}
			CloseHandle(plyinf);
			WritePackCell(dp,reloadids);
			WritePackCell(dp,reloadangs);
			WritePackCell(dp,reloadorgs);
		}
		CreateTimer(1.0,reloadtimer);
		CreateTimer(1.1,reloadtimersetupcl,dp);
	}
}

delthissave(char[] info, int client)
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

public Action reloadtimer(Handle timer)
{
	new thereload = CreateEntityByName("player_loadsaved");
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
					if (arrindx != -1)
					{
						GetArrayString(reloadangs,arrindx,angch,sizeof(angch));
						GetArrayString(reloadorgs,arrindx,originch,sizeof(originch));
						ExplodeString(angch," ",sets,3,64);
						angs[0] = StringToFloat(sets[0]);
						angs[1] = StringToFloat(sets[1]);
						angs[2] = StringToFloat(sets[2]);
						ExplodeString(originch," ",sets,3,64);
						origin[0] = StringToFloat(sets[0]);
						origin[1] = StringToFloat(sets[1]);
						origin[2] = StringToFloat(sets[2]);
						TeleportEntity(i,origin,angs,NULL_VECTOR);
					}
					else
					{
						int rand = GetRandomInt(0,GetArraySize(reloadids)-1);
						GetArrayString(reloadangs,rand,angch,sizeof(angch));
						GetArrayString(reloadorgs,rand,originch,sizeof(originch));
						ExplodeString(angch," ",sets,3,64);
						angs[0] = StringToFloat(sets[0]);
						angs[1] = StringToFloat(sets[1]);
						angs[2] = StringToFloat(sets[2]);
						ExplodeString(originch," ",sets,3,64);
						origin[0] = StringToFloat(sets[0]);
						origin[1] = StringToFloat(sets[1]);
						origin[2] = StringToFloat(sets[2]);
						TeleportEntity(i,origin,angs,NULL_VECTOR);
					}
				}
			}
		}
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
			delthissave(h,client);
		}
		return Plugin_Handled;
	}
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public MenuHandlervote(Menu menu, MenuAction action, int param1, int param2)
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
		else if (voteinprogress)
		{
			PrintToChat(param1,"There is a vote already in progress.");
			return 0;
		}
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
			voteinprogress = true;
		}
		else if ((StrEqual(info,"createsave",false)) && (votetime <= Time))
		{
			new String:buff[32];
			g_voteType = voteType:question;
			g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
			Format(buff,sizeof(buff),"Create Save Point?");
			g_hVoteMenu.SetTitle(buff);
			g_hVoteMenu.AddItem(VOTE_YES, "Yes");
			g_hVoteMenu.AddItem(VOTE_NO, "No");
			g_hVoteMenu.ExitButton = false;
			g_hVoteMenu.DisplayVoteToAll(20);
			votetime = Time + 60;
			reloadtype = 4;
			voteinprogress = true;
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
			voteinprogress = true;
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
			voteinprogress = true;
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
		float perclimitlocal;
		if (reloadtype == 4) perclimitlocal = perclimitsave;
		else perclimitlocal = perclimit;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes;
		}
		
		percent = GetVotePercent(votes, totalVotes);

		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,perclimitlocal) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t","Vote Failed", RoundToNearest(100.0*perclimitlocal), RoundToNearest(100.0*percent), totalVotes);
			Format(reloadthissave,sizeof(reloadthissave),"");
		}
		else
		{
			PrintToChatAll("%t","Vote Successful", RoundToNearest(100.0*percent), totalVotes);
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
			else if (reloadtype == 4)
			{
				if ((logsv != 0) && (logsv != -1) && (IsValidEntity(logsv)))
				{
					saveresetveh();
				}
				else
				{
					logsv = CreateEntityByName("logic_autosave");
					if ((logsv != -1) && (IsValidEntity(logsv)))
					{
						DispatchSpawn(logsv);
						ActivateEntity(logsv);
						saveresetveh();
					}
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
	logsv = CreateEntityByName("logic_autosave");
	if ((logsv != -1) && (IsValidEntity(logsv)))
	{
		DispatchSpawn(logsv);
		ActivateEntity(logsv);
	}
	voteinprogress = false;
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
			findrmstarts(-1,"info_player_start");
			int loginp = CreateEntityByName("logic_auto");
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
			int trigtpstart = CreateEntityByName("info_teleport_destination");
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
		else if (enterfrom03pb)
			enterfrom03pb = false;
		if ((enterfrom08pb) && (StrEqual(mapbuf,"d2_coast_07",false)))
		{
			findrmstarts(-1,"info_player_start");
			int loginp = CreateEntityByName("logic_auto");
			DispatchKeyValue(loginp, "spawnflags","1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_shiz,Trigger,,0,1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_4,0,1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_player_1,kill,,0,1");
			DispatchKeyValue(loginp, "OnMapSpawn","syn_starttptransition,kill,,30,1");
			DispatchSpawn(loginp);
			ActivateEntity(loginp);
			int trigtpstart = CreateEntityByName("info_teleport_destination");
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
	ClearArray(equiparr);
	Format(reloadthissave,sizeof(reloadthissave),"");
	HookEntityOutput("trigger_changelevel","OnChangeLevel",EntityOutput:onchangelevel);
	if (rmsaves)
	{
		Handle savedirrmh = OpenDirectory(savedir, false);
		char subfilen[32];
		while (ReadDirEntry(savedirrmh, subfilen, sizeof(subfilen)))
		{
			if ((!(savedirrmh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
			{
				if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
				{
					Format(subfilen,sizeof(subfilen),"%s\\%s",savedir,subfilen);
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
		CloseHandle(savedirrmh);
		if ((logsv != -1) && (IsValidEntity(logsv))) saveresetveh();
		if (transitionply)
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
			timouthndl = CreateTimer(121.0,transitiontimeout);
		}
		if (strlen(landmarkname) > 0)
		{
			findlandmark(-1,"info_landmark");
			if (GetArraySize(transitionents) > 0)
			{
				for (int i = 0;i<GetArraySize(transitionents);i++)
				{
					Handle dp = GetArrayCell(transitionents,i);
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
					int ent = CreateEntityByName(clsname);
					if (ent != -1)
					{
						DispatchKeyValue(ent,"targetname",targn)
						DispatchKeyValue(ent,"model",mdl);
						if (strlen(vehscript) > 0) DispatchKeyValue(ent,"VehicleScript",vehscript);
						if (strlen(additionalequip) > 0) DispatchKeyValue(ent,"AdditionalEquipment",additionalequip);
						if (strlen(hdwtype) > 0) DispatchKeyValue(ent,"hardware",hdwtype);
						if (strlen(parentname) > 0) DispatchKeyValue(ent,"ParentName",parentname);
						DispatchKeyValue(ent,"spawnflags",spawnflags);
						DispatchKeyValue(ent,"skin",skin);
						DispatchSpawn(ent);
						ActivateEntity(ent);
						if (curh != 0) SetEntProp(ent,Prop_Data,"m_iHealth",curh);
						TeleportEntity(ent,porigin,angs,NULL_VECTOR);
					}
					CloseHandle(dp);
				}
			}
		}
		ClearArray(transitionents);
	}
	char curmapchk[32];
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

public Action transitiontimeout(Handle timer)
{
	timouthndl = INVALID_HANDLE;
	ClearArray(transitionid);
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

public Action onchangelevel(const char[] output, int caller, int activator, float delay)
{
	if (rmsaves)
	{
		if (timouthndl != INVALID_HANDLE) KillTimer(timouthndl);
		ClearArray(transitionid);
		ClearArray(transitiondp);
		ClearArray(transitionplyorigin);
		char maptochange[64];
		char curmapbuf[64];
		GetCurrentMap(curmapbuf,sizeof(curmapbuf));
		GetEntPropString(caller,Prop_Data,"m_szMapName",maptochange,sizeof(maptochange));
		if ((StrEqual(curmapbuf,"d1_town_03",false)) && (StrEqual(maptochange,"d1_town_02",false)))
		{
			reloadingmap = true;
			enterfrom03pb = true;
		}
		else if ((StrEqual(curmapbuf,"d2_coast_08",false)) && (StrEqual(maptochange,"d2_coast_07",false)))
		{
			reloadingmap = true;
			enterfrom08pb = true;
		}
		else if ((StrEqual(curmapbuf,"ep2_outland_04",false)) && (StrEqual(maptochange,"ep2_outland_02",false)))
		{
			reloadingmap = true;
			enterfrom04pb = true;
		}
		else reloadingmap = true;
		Handle savedirh = OpenDirectory(savedir, false);
		char subfilen[32];
		while (ReadDirEntry(savedirh, subfilen, sizeof(subfilen)))
		{
			if ((!(savedirh == INVALID_HANDLE)) && (!(StrEqual(subfilen, "."))) && (!(StrEqual(subfilen, ".."))))
			{
				if ((!(StrContains(subfilen, ".ztmp", false) != -1)) && (!(StrContains(subfilen, ".bz2", false) != -1)))
				{
					Format(subfilen,sizeof(subfilen),"%s/%s",savedir,subfilen);
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
		CloseHandle(savedirh);
		if (transitionply)
		{
			GetEntPropString(caller,Prop_Data,"m_szLandmarkName",landmarkname,sizeof(landmarkname));
			findlandmark(-1,"info_landmark");
			findlandmark(-1,"trigger_transition");
			float plyorigin[3];
			float plyangs[3];
			char SteamID[32];
			Handle dp = INVALID_HANDLE;
			int curh,cura;
			char tmp[16];
			char weapname[24];
			char weapnamepamm[32];
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
				{
					GetClientAbsAngles(i,plyangs);
					GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
					if (FindStringInArray(transitionplyorigin,SteamID) != -1)
					{
						GetClientAbsOrigin(i,plyorigin);
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
					curh = GetEntProp(i,Prop_Data,"m_iHealth");
					WritePackCell(dp,curh);
					cura = GetEntProp(i,Prop_Data,"m_ArmorValue");
					WritePackCell(dp,cura);
					int score = GetEntProp(i,Prop_Data,"m_iPoints");
					int kills = GetEntProp(i,Prop_Data,"m_iFrags");
					int deaths = GetEntProp(i,Prop_Data,"m_iDeaths");
					int suitset = GetEntProp(i,Prop_Send,"m_bWearingSuit");
					int medkitamm = GetEntProp(i,Prop_Send,"m_iHealthPack");
					WritePackCell(dp,score);
					WritePackCell(dp,kills);
					WritePackCell(dp,deaths);
					WritePackCell(dp,suitset);
					WritePackCell(dp,medkitamm);
					WritePackFloat(dp,plyangs[0]);
					WritePackFloat(dp,plyangs[1]);
					WritePackFloat(dp,plyorigin[0]);
					WritePackFloat(dp,plyorigin[1]);
					WritePackFloat(dp,plyorigin[2]);
					for (int j = 0;j<33;j++)
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
						for (int j; j<48; j += 4)
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
					WritePackString(dp,"endofpack");
					PushArrayCell(transitiondp,dp);
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
}

findlandmark(int ent,char[] classname)
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
				findtouchingents(mins,maxs);
			}
		}
		findlandmark(thisent++,classname);
	}
}

findtouchingents(float mins[3], float maxs[3])
{
	char targn[32];
	char mdl[64];
	float porigin[3];
	float angs[3];
	for (int i = 1;i<2048;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",porigin);
			else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",porigin);
			if ((porigin[0] > mins[0]) && (porigin[1] > mins[1]) && (porigin[2] > mins[2]) && (porigin[0] < maxs[0]) && (porigin[1] < maxs[1]) && (porigin[2] < maxs[2]))
			{
				char clsname[32];
				GetEntityClassname(i,clsname,sizeof(clsname));
				//Add func_tracktrain check if exists on next map OnTransition might not fire
				if (((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"prop_",false) != -1)) && (!StrEqual(clsname,"npc_template_maker",false)) && (!StrEqual(clsname,"npc_antlion_template_maker",false)))
				{
					Handle dp = CreateDataPack();
					porigin[0]-=landmarkorigin[0];
					porigin[1]-=landmarkorigin[1];
					porigin[2]-=landmarkorigin[2];
					GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
					if (strlen(targn) < 1) Format(targn,sizeof(targn),"transitionent");
					int curh = 0;
					char vehscript[64];
					char additionalequip[32];
					char spawnflags[32];
					char skin[4];
					char hdwtype[4];
					char parentname[32];
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
						GetEntPropString(par,Prop_Data,"m_iName",parentname,sizeof(parentname));
					}
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
					PushArrayCell(transitionents,dp);
				}
				else if (StrEqual(clsname,"player",false))
				{
					char SteamID[32];
					GetClientAuthId(i,AuthId_Steam2,SteamID,sizeof(SteamID));
					PushArrayString(transitionplyorigin,SteamID);
				}
			}
		}
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (transitionply)
	{
		int client = GetClientOfUserId(GetEventInt(event,"userid"));
		CreateTimer(0.1, transitionspawn, client);
	}
	return Plugin_Continue;
}

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

public OnClientAuthorized(int client, const char[] szAuth)
{
	if (rmsaves)
	{
		if ((logsv != -1) && (IsValidEntity(logsv)))
		{
			saveresetveh();
		}
	}
}

void saveresetveh()
{
	int vehicles[MAXPLAYERS];
	float steerpos[MAXPLAYERS];
	int vehon[MAXPLAYERS];
	float throttle[MAXPLAYERS];
	int speed[MAXPLAYERS];
	float restoreang[3];
	float ang0[MAXPLAYERS];
	float ang1[MAXPLAYERS];
	float ang2[MAXPLAYERS];
	int gearsound[MAXPLAYERS];
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((IsValidEntity(i)) && (IsClientInGame(i)) && (IsPlayerAlive(i)))
		{
			vehicles[i] = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
			if (vehicles[i] > MaxClients)
			{
				char clsname[32];
				GetEntityClassname(vehicles[i],clsname,sizeof(clsname));
				if ((StrEqual(clsname,"prop_vehicle_jeep",false)) || (StrEqual(clsname,"prop_vehicle_mp",false)))
				{
					steerpos[i] = GetEntPropFloat(vehicles[i],Prop_Data,"m_controls.steering");
					throttle[i] = GetEntPropFloat(vehicles[i],Prop_Data,"m_controls.throttle");
					vehon[i] = GetEntProp(vehicles[i],Prop_Data,"m_bIsOn");
					speed[i] = GetEntProp(vehicles[i],Prop_Data,"m_nSpeed");
					GetEntPropVector(i,Prop_Data,"m_angRotation",restoreang);
					ang1[i] = restoreang[1];
					gearsound[i] = GetEntProp(vehicles[i],Prop_Data,"m_iSoundGear");
				}
			}
		}
	}
	AcceptEntityInput(logsv,"Save");
	for (int i = 1;i<MaxClients+1;i++)
	{
		if ((vehicles[i] != 0) && (IsValidEntity(vehicles[i])))
		{
			SetEntPropFloat(vehicles[i],Prop_Data,"m_controls.steering",steerpos[i]);
			SetEntPropFloat(vehicles[i],Prop_Data,"m_controls.throttle",throttle[i]);
			SetEntProp(vehicles[i],Prop_Data,"m_bIsOn",vehon[i]);
			SetEntProp(vehicles[i],Prop_Data,"m_nSpeed",speed[i]);
			SetEntProp(vehicles[i],Prop_Data,"m_controls.handbrake",1);
			SetEntProp(vehicles[i],Prop_Data,"m_iSoundGear",gearsound[i]);
			restoreang[0] = ang0[i];
			restoreang[1] = ang1[i];
			restoreang[2] = ang2[i];
			Handle dp = CreateDataPack();
			WritePackCell(dp,i);
			WritePackFloat(dp,ang1[i]);
			CreateTimer(0.01,restoreaim,dp);
		}
	}
}

public Action transitionspawn(Handle timer, any client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client) && !IsFakeClient(client))
	{
		char SteamID[32];
		GetClientAuthId(client,AuthId_Steam2,SteamID,sizeof(SteamID));
		int arrindx = FindStringInArray(transitionid,SteamID);
		if (arrindx != -1)
		{
			if (GetArraySize(equiparr) < 1) findent(MaxClients+1,"info_player_equip");
			//Possibility of no equips found.
			if (GetArraySize(equiparr) > 0)
			{
				for (int j; j<GetArraySize(equiparr); j++)
				{
					int jtmp = GetArrayCell(equiparr, j);
					if (IsValidEntity(jtmp))
						AcceptEntityInput(jtmp,"Disable");
				}
			}
			char ammoset[24];
			char ammosetexp[24][2];
			char ammosettype[24];
			char ammosetamm[16];
			RemoveFromArray(transitionid,arrindx);
			Handle dp = GetArrayCell(transitiondp,arrindx);
			ResetPack(dp);
			int curh = ReadPackCell(dp);
			int cura = ReadPackCell(dp);
			int score = ReadPackCell(dp);
			int kills = ReadPackCell(dp);
			int deaths = ReadPackCell(dp);
			int suitset = ReadPackCell(dp);
			int medkitamm = ReadPackCell(dp);
			float plyorigin[3];
			float angs[3];
			angs[0] = ReadPackFloat(dp);
			angs[1] = ReadPackFloat(dp);
			plyorigin[0] = ReadPackFloat(dp);
			plyorigin[1] = ReadPackFloat(dp);
			plyorigin[2] = ReadPackFloat(dp);
			plyorigin[0]+=landmarkorigin[0];
			plyorigin[1]+=landmarkorigin[1];
			plyorigin[2]+=landmarkorigin[2];
			SetEntProp(client,Prop_Data,"m_iHealth",curh);
			SetEntProp(client,Prop_Data,"m_ArmorValue",cura);
			SetEntProp(client,Prop_Data,"m_iPoints",score);
			SetEntProp(client,Prop_Data,"m_iFrags",kills);
			SetEntProp(client,Prop_Data,"m_iDeaths",deaths);
			SetEntProp(client,Prop_Send,"m_bWearingSuit",suitset);
			SetEntProp(client,Prop_Send,"m_iHealthPack",medkitamm);
			ReadPackString(dp,ammoset,sizeof(ammoset));
			while (!StrEqual(ammoset,"endofpack",false))
			{
				if (StrContains(ammoset,"weapon_",false) == -1)
				{
					ExplodeString(ammoset," ",ammosetexp,2,24);
					int ammindx = StringToInt(ammosetexp[0]);
					int ammset = StringToInt(ammosetexp[1]);
					SetEntProp(client,Prop_Send,"m_iAmmo",ammset,_,ammindx);
				}
				else if (StrContains(ammoset,"weapon_",false) != -1)
				{
					int breakstr = StrContains(ammoset," ",false);
					Format(ammosettype,sizeof(ammosettype),"%s",ammoset);
					Format(ammosetamm,sizeof(ammosetamm),"%s",ammoset[breakstr+1]);
					ReplaceString(ammosettype,sizeof(ammosettype),ammoset[breakstr],"");
					int weapindx = GivePlayerItem(client,ammosettype);
					if (weapindx != -1)
					{
						int weapamm = StringToInt(ammosetamm);
						SetEntProp(weapindx,Prop_Data,"m_iClip1",weapamm)
					}
				}
				ReadPackString(dp,ammoset,sizeof(ammoset));
			}
			CloseHandle(dp);
			RemoveFromArray(transitiondp,arrindx);
			if ((plyorigin[0] != 0.0) && (plyorigin[1] != 0.0) && (plyorigin[2] != 0.0)) TeleportEntity(client,plyorigin,angs,NULL_VECTOR);
		}
		else
		{
			if (GetArraySize(equiparr) < 1) findent(MaxClients+1,"info_player_equip");
			if (GetArraySize(equiparr) > 0)
			{
				for (int j; j<GetArraySize(equiparr); j++)
				{
					int jtmp = GetArrayCell(equiparr, j);
					if (IsValidEntity(jtmp))
						AcceptEntityInput(jtmp,"EquipPlayer",client);
				}
			}
			if (GetArraySize(equiparr) < 1) CreateTimer(0.1,delayequip);
		}
	}
	else if ((IsClientConnected(client)) && (!IsFakeClient(client)))
	{
		CreateTimer(1.0, transitionspawn, client);
	}
}

public Action delayequip(Handle timer)
{
	findent(MaxClients+1,"info_player_equip");
	return Plugin_Handled;
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

public Action changelevel(Handle timer)
{
	ServerCommand("changelevel %s",mapbuf);
}

findrmstarts(int start, char[] type)
{
	int thisent = FindEntityByClassname(start,type);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		AcceptEntityInput(thisent,"Kill");
	}
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
