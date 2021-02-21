#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "1.71"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/modelloaderupdater.txt"

public Plugin myinfo = 
{
	name = "ModelLoader",
	author = "Balimbanana",
	description = "Model Loader",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

Handle modelarray = INVALID_HANDLE;
Handle matarray = INVALID_HANDLE;
Handle Handle_Database = INVALID_HANDLE;
char szSteamIDbuf[128][32];
char curmodel[128][128];
char desmodel[128][128];
float antispamchk[128];

bool dlactive = false;
bool soundfix = true;

Handle magisterarray = INVALID_HANDLE;
Handle darxarray = INVALID_HANDLE;
Handle gmodarray = INVALID_HANDLE;
Handle hl2sarray = INVALID_HANDLE;
Handle qncarray = INVALID_HANDLE;
Handle n7larray = INVALID_HANDLE;
Handle kudarray = INVALID_HANDLE;
Handle cssarray = INVALID_HANDLE;
Handle cs16array = INVALID_HANDLE;
Handle mawsarray = INVALID_HANDLE;
Handle hl1array = INVALID_HANDLE;
Handle l4darray = INVALID_HANDLE;
Handle scarray = INVALID_HANDLE;
Handle modelarray2 = INVALID_HANDLE;
Handle precachedarr = INVALID_HANDLE;

Handle bclcookieh = INVALID_HANDLE;
Handle bclcookie2h = INVALID_HANDLE;
int bclcookie[128];
int bclcookie2[128];

public void OnPluginStart()
{
	LoadTranslations("modelloader.phrases");
	PrintToServer("ModelLoader Loaded");
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	RegConsoleCmd("models", modelmenu);
	RegConsoleCmd("model", modelmenu);
	modelarray = CreateArray(768);
	modelarray2 = CreateArray(768);
	matarray = CreateArray(512);
	//ocarray = CreateArray(392);
	precachedarr = CreateArray(256);
	char Error[100];
	Handle_Database = SQLite_UseDatabase("sourcemod-local",Error,100-1);
	if (Handle_Database == INVALID_HANDLE)
		LogError("SQLite error: %s",Error);
	if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS modelloader('SteamID' VARCHAR(32) NOT NULL PRIMARY KEY,'mdl' VARCHAR(64) NOT NULL);"))
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return;
	}
	reloadmdlclients();
	matarraypopulate();
	Handle modelloaderdlh = CreateConVar("sm_modelloaderdl", "0", "Specifies if ModelLoader will add all found models to download list. But it will not add models inside VPKs", _, true, 0.0, true, 1.0);
	dlactive = GetConVarBool(modelloaderdlh);
	HookConVarChange(modelloaderdlh,dlch);
	CloseHandle(modelloaderdlh);
	Handle modelloadersndh = CreateConVar("sm_modelloader_soundfix", "1", "Applies sound fix for pain response on custom models.", _, true, 0.0, true, 1.0);
	soundfix = GetConVarBool(modelloadersndh);
	HookConVarChange(modelloadersndh,sndfixch);
	CloseHandle(modelloadersndh);
	CreateTimer(1.0, sortarray);
	CreateTimer(10.0, recheckmodel, _, TIMER_REPEAT);
	RegConsoleCmd("modelskin",setmodelskin);
	RegConsoleCmd("modelbody",setmodelbody);
	RegConsoleCmd("modelpack",showmodelpacks);
	RegConsoleCmd("modelpacks",showmodelpacks);
	bclcookieh = RegClientCookie("PlayerModelSkinNum", "Model skin number Settings", CookieAccess_Private);
	bclcookie2h = RegClientCookie("PlayerModelBodyNum", "Model body number Settings", CookieAccess_Private);
	AddNormalSoundHook(customsoundchecksnorm);
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public void dlch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		dlactive = true;
		matarraypopulate();
	}
	else dlactive = false;
}

public Action onsuitpickup(const char[] output, int caller, int activator, float delay)
{
	if (IsPlayerAlive(activator))
	{
		float Time = GetTickedTime();
		if (antispamchk[activator] <= Time)
		{
			for (int client = 1; client<MaxClients+1 ;client++)
			{
				if (IsValidEntity(client))
				{
					if (IsClientConnected(client))
					{
						CreateTimer(0.1, setmodeltimer, client);
						antispamchk[activator] = Time + 3.0;
					}
				}
			}
		}
	}
}

public Action reloadmdlclients()
{
	for (int client = 0; client<MaxClients+1 ;client++)
	{
		if (client != 0)
		{
			if (IsValidEntity(client))
			{
				if ((client != -1) && (IsClientInGame(client)))
				{
					GetClientAuthId(client,AuthId_Steam2,szSteamIDbuf[client],32-1);
					GetClientModel(client, curmodel[client], sizeof(curmodel[]));
					LoadClient(client);
					CreateTimer(0.1, setmodeltimer, client);
				}
			}
		}
	}
}

void LoadClient(int client)
{
	char Query[128];
	if (!Stored(client))
	{
		QueryClientConVar(client,"cl_playermodel",plymdlchk);
		return;
	}
	Format(Query,sizeof(Query),"SELECT mdl FROM modelloader WHERE SteamID = '%s';",szSteamIDbuf[client]);
	Handle hQuery = SQL_Query(Handle_Database,Query);
	if (hQuery == INVALID_HANDLE)
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s with query %s",Err,Query);
	}
	SQL_FetchString(hQuery, 0, desmodel[client], sizeof(desmodel[]));
	CloseHandle(hQuery);
	return;
}

public void plymdlchk(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (strlen(cvarValue) > 0)
	{
		if (FileExists(cvarValue,true,NULL_STRING))
		{
			char chk1[500];
			Format(chk1,sizeof(chk1),"INSERT INTO modelloader VALUES( '%s', '%s');",szSteamIDbuf[client],cvarValue);
			SQL_Query(Handle_Database,chk1);
			LoadClient(client);
			CreateTimer(0.1, setmodeltimer, client);
		}
		else
		{
			char chk1[500];
			Format(chk1,sizeof(chk1),"INSERT INTO modelloader VALUES( '%s', 'male_01.mdl');",szSteamIDbuf[client]);
			SQL_Query(Handle_Database,chk1);
			LoadClient(client);
			CreateTimer(0.1, setmodeltimer, client);
		}
	}
}

public void OnClientAuthorized(int client, const char[] szAuth)
{
	GetClientAuthId(client,AuthId_Steam2,szSteamIDbuf[client],sizeof(szSteamIDbuf[]));
	LoadClient(client);
	if (StrContains(desmodel[client],"models/player/normal") != -1)
	{
		ClientCommand(client, "cl_playermodel %s", desmodel[client]);
	}
	else
	{
		ClientCommand(client, "cl_playermodel models/player/normal/%s", desmodel[client]);
	}
}

public Action setmodelskin(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"Usage: !modelskin #");
		PrintToChat(client,"Sets the skin that your player model will use.");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		PrintToChat(client,"Set your model skin number to %i",numset);
		bclcookie[client] = numset;
		SetClientCookie(client, bclcookieh, h);
		SetVariantInt(bclcookie[client]);
		AcceptEntityInput(client,"Skin");
	}
	return Plugin_Handled;
}

public Action setmodelbody(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"Usage: !modelbody #");
		PrintToChat(client,"Sets the body setting that your player model will use.");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		PrintToChat(client,"Set your model body number to %i",numset);
		bclcookie2[client] = numset;
		SetClientCookie(client, bclcookie2h, h);
		SetVariantInt(bclcookie2[client]);
		AcceptEntityInput(client,"SetBodyGroup");
	}
	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	char sValue[32];
	GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie[client] = 0;
		SetClientCookie(client, bclcookieh, "0");
	}
	else
	{
		bclcookie[client] = StringToInt(sValue);
	}
	GetClientCookie(client, bclcookie2h, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie2[client] = 0;
		SetClientCookie(client, bclcookie2h, "0");
	}
	else
	{
		bclcookie2[client] = StringToInt(sValue);
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	char tmpmdl[128];
	GetClientModel(client, tmpmdl, sizeof(tmpmdl));
	if (StrContains(tmpmdl,"rebel") != -1)
	{
		ReplaceString(tmpmdl,sizeof(tmpmdl),"models/player/rebel/","", false);
	}
	if (!(StrEqual(desmodel[client],tmpmdl)))
	{
		//ClientCommand(client, "cl_playermodel models/player/normal/male_01.mdl");
		//SetEntityModel(client, "models/player/rebel/male_01.mdl");
		CreateTimer(1.1, setmodeltimer, client);
		//Post check
		CreateTimer(5.0, setmodeltimer, client);
	}
	else
	{
		if (StrContains(tmpmdl,"models/player/normal") != -1)
		{
			ClientCommand(client, "cl_playermodel %s", tmpmdl);
			CreateTimer(1.1, setmodeltimer, client);
		}
		else
		{
			ReplaceString(tmpmdl,sizeof(tmpmdl),"models/player/rebel/","", false);
			ClientCommand(client, "cl_playermodel models/player/normal/%s", tmpmdl);
		}
	}
	return Plugin_Continue;
}

public Action setmodeltimer(Handle Timer, any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		GetClientModel(client, curmodel[client], sizeof(curmodel[]));
		if (StrContains( curmodel[client], "models/player/normal") != -1)
		{
			ClientCommand(client, "cl_playermodel %s", curmodel[client]);
		}
		else
		{
			ReplaceString(curmodel[client],sizeof(curmodel[]),"models/player/rebel/","", false);
			ClientCommand(client, "cl_playermodel models/player/normal/%s", curmodel[client]);
		}
		if (!(StrEqual(desmodel[client],curmodel[client])))
		{
			CreateTimer(0.1, setmodeltimer, client);
			setmodel(client, desmodel[client]);
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(1.0, setmodeltimer, client);
	}
	return Plugin_Handled;
}

public Action setmodel(int client, const char[] model)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		int found = -1;
		for (int k;k<GetArraySize(modelarray);k++)
		{
			char ktmp[64];
			GetArrayString(modelarray, k, ktmp, sizeof(ktmp));
			if (StrContains(ktmp, model) != -1)
			{
				found++;
			}
		}
		if ((StrContains (model, "male") != -1) || (StrContains (model, "female") != -1) || (StrContains (model, "hero") != -1))
		{
			found++;
		}
		if ((found > -1) && (!(StrEqual(model,""))))
		{
			int donstat = 1;
			//if (HasEntProp(client,Prop_Send,"m_iSynergyDonorStat"))
			//	donstat = GetEntProp(client, Prop_Send, "m_iSynergyDonorStat");
			if ((StrContains( model, "hero") != -1) && (donstat > 0))
			{
				if (StrContains( model, "normal") != -1)
				{
					if (!IsModelPrecached(model)) PrecacheModel(model,true);
					ClientCommand(client, "cl_playermodel %s", model);
					SetEntityModel(client, model);
				}
				else
				{
					char modeltmp[128];
					ClientCommand(client, "cl_playermodel models/player/normal/%s", model);
					Format(modeltmp,sizeof(modeltmp),"models/player/rebel/%s", model);
					if (!IsModelPrecached(modeltmp)) PrecacheModel(modeltmp,true);
					SetEntityModel(client, modeltmp);
				}
			}
			else if ((StrContains( model, "hero_male") != -1) || (StrContains( model, "hero_female") != -1))
			{
				if (donstat < 1)
				{
					PrintToChat(client,"%T","DonatorOnly",client);
					ClientCommand(client, "cl_playermodel models/player/normal/male_01.mdl");
					SetEntityModel(client, "models/player/rebel/male_01.mdl");
					Format(desmodel[client],sizeof(desmodel[]),"male_01.mdl");
					char change[254];
					Format(change,254,"UPDATE modelloader SET 'mdl' = 'male_01.mdl' WHERE SteamID = '%s';",szSteamIDbuf[client]);
					SQL_Query(Handle_Database,change);
				}
			}
			else if (StrContains( model, "models/player/normal") != -1)
			{
				if (!FileExists(model,true,NULL_STRING))
				{
					Format(desmodel[client],sizeof(desmodel[]),"male_01.mdl");
					if (!IsModelPrecached("models/player/normal/male_01.mdl")) PrecacheModel("models/player/normal/male_01.mdl",true);
					ClientCommand(client, "cl_playermodel models/player/normal/male_01.mdl");
					SetEntityModel(client, "models/player/normal/male_01.mdl");
				}
				else
				{
					if (!IsModelPrecached(model)) PrecacheModel(model,true);
					ClientCommand(client, "cl_playermodel %s", model);
					SetEntityModel(client, model);
				}
			}
			else
			{
				char modeltmp[128];
				Format(modeltmp,sizeof(modeltmp),"models/player/rebel/%s", model);
				if (!FileExists(modeltmp,true,NULL_STRING))
				{
					Format(desmodel[client],sizeof(desmodel[]),"male_01.mdl");
					Format(modeltmp,sizeof(modeltmp),"models/player/rebel/%s", model);
				}
				ClientCommand(client, "cl_playermodel models/player/normal/%s", model);
				if (!IsModelPrecached(modeltmp)) PrecacheModel(modeltmp,true);
				SetEntityModel(client, modeltmp);
			}
		}
		else
		{
			ClientCommand(client, "cl_playermodel models/player/normal/male_01.mdl");
			SetEntityModel(client, "models/player/rebel/male_01.mdl");
			Format(desmodel[client],sizeof(desmodel[]),"male_01.mdl");
			char change[254];
			Format(change,254,"UPDATE modelloader SET 'mdl' = 'male_01.mdl' WHERE SteamID = '%s';",szSteamIDbuf[client]);
			SQL_Query(Handle_Database,change);
		}
		SetVariantInt(bclcookie[client]);
		AcceptEntityInput(client,"Skin");
		SetVariantInt(bclcookie2[client]);
		AcceptEntityInput(client,"SetBodyGroup");
	}
}

public bool Stored(int client)
{
	char Query[100];
	Format(Query,100,"SELECT mdl FROM modelloader WHERE SteamID = '%s';",szSteamIDbuf[client]);
	Handle hQuery = SQL_Query(Handle_Database,Query);
	if (hQuery == INVALID_HANDLE)
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return false;
	}
	while (SQL_FetchRow(hQuery))
	{
		CloseHandle(hQuery);
		return true;
	}
	CloseHandle(hQuery);
	return false;
}

public void OnClientDisconnect(int client)
{
	int index = client;
	init(index);
}

void init(int index)
{
	szSteamIDbuf[index] = "";
	curmodel[index] = "";
	desmodel[index] = "";
}

public Action recheckmodel(Handle Timer)
{
	//Can't put these all on one line because all checks are compared, causing errors.
	for (int client = 1; client<MaxClients+1 ;client++)
	{
		if (IsValidEntity(client))
			if (IsClientInGame(client))
				if (IsPlayerAlive(client))
					CreateTimer(0.1, setmodeltimer, client);
	}
}

public Action sortarray(Handle Timer)
{
	if (GetArraySize(modelarray) > 0)
	{
		for (int k;k<GetArraySize(modelarray);k++)
		{
			char ktmp[64];
			//char thattemp[64];
			GetArrayString(modelarray, k, ktmp, sizeof(ktmp));
			if (StrContains(ktmp, "- lord darx", false) != -1)
			{
				if (darxarray == INVALID_HANDLE) darxarray = CreateArray(20);
				PushArrayString(darxarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"Lord Darx");
			}
			else if (StrContains(ktmp, "- gmod", false) != -1)
			{
				if (gmodarray == INVALID_HANDLE) gmodarray = CreateArray(20);
				PushArrayString(gmodarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"Gmod");
			}
			else if (StrContains(ktmp, "- m@gister", false) != -1)
			{
				if (magisterarray == INVALID_HANDLE) magisterarray = CreateArray(20);
				PushArrayString(magisterarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"M@gister");
			}
			else if (StrContains(ktmp, "- hl2s", false) != -1)
			{
				if (hl2sarray == INVALID_HANDLE) hl2sarray = CreateArray(30);
				PushArrayString(hl2sarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"HL2S");
			}
			else if (StrContains(ktmp, "- quickninjacat", false) != -1)
			{
				if (qncarray == INVALID_HANDLE) qncarray = CreateArray(20);
				PushArrayString(qncarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"QuickNinjaCat");
			}
			else if (StrContains(ktmp, "- n7legion", false) != -1)
			{
				if (n7larray == INVALID_HANDLE) n7larray = CreateArray(20);
				PushArrayString(n7larray, ktmp);
				//Format(thattemp,sizeof(thattemp),"N7Legion");
			}
			else if ((StrContains(ktmp, "pedo bear -", false) != -1) || (StrContains(ktmp, "soviet soldier - sniper elite v2", false) != -1) || (StrContains(ktmp, "- fairy fencer f", false) != -1) || (StrContains(ktmp, "- touhou project", false) != -1) || (StrContains(ktmp, "uni - maid ver", false) != -1) || (StrContains(ktmp, "- hyperdimension neptunia", false) != -1) || (StrContains(ktmp, "franklin clinton - gta5", false) != -1))
			{
				if (kudarray == INVALID_HANDLE) kudarray = CreateArray(20);
				PushArrayString(kudarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"Kud");
			}
			else if (StrContains(ktmp, "- css", false) != -1)
			{
				if (cssarray == INVALID_HANDLE) cssarray = CreateArray(20);
				PushArrayString(cssarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"CSS");
			}
			else if (StrContains(ktmp, "- cs 1.6", false) != -1)
			{
				if (cs16array == INVALID_HANDLE) cs16array = CreateArray(20);
				PushArrayString(cs16array, ktmp);
				//Format(thattemp,sizeof(thattemp),"CS 1.6");
			}
			else if (StrContains(ktmp, "- mawskeeto", false) != -1)
			{
				if (mawsarray == INVALID_HANDLE) mawsarray = CreateArray(64);
				PushArrayString(mawsarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"Mawskeeto");
			}
			else if (StrContains(ktmp, "- hl1", false) != -1)
			{
				if (hl1array == INVALID_HANDLE) hl1array = CreateArray(20);
				PushArrayString(hl1array, ktmp);
				//Format(thattemp,sizeof(thattemp),"HL1");
			}
			else if (StrContains(ktmp, "- l4d", false) != -1)
			{
				if (l4darray == INVALID_HANDLE) l4darray = CreateArray(10);
				PushArrayString(l4darray, ktmp);
				//Format(thattemp,sizeof(thattemp),"L4D");
			}
			else if (StrContains(ktmp, "sc ", false) == 0)
			{
				if (scarray == INVALID_HANDLE) scarray = CreateArray(20);
				PushArrayString(scarray, ktmp);
				//Format(thattemp,sizeof(thattemp),"Sven Co-op");
			}
			else
			{
				PushArrayString(modelarray2, ktmp);
				//Format(thattemp,sizeof(thattemp),"CU Models");
			}
			//PrintToServer("Added %s to %s array",ktmp,thattemp);
		}
	}
}

public Action cmodelmenu(int client, int args)
{
	Menu menu = new Menu(MenuHandlersub);
	char tmp[48];
	Format(tmp,sizeof(tmp),"%T","ModelMenuGrp",client);
	menu.SetTitle(tmp);
	if (magisterarray != INVALID_HANDLE)
		if (GetArraySize(magisterarray) > 0)
			menu.AddItem("magister", "M@GISTER");
	if (darxarray != INVALID_HANDLE)
		if (GetArraySize(darxarray) > 0)
			menu.AddItem("darx", "Lord Darx");
	if (hl2sarray != INVALID_HANDLE)
		if (GetArraySize(hl2sarray) > 0)
			menu.AddItem("hl2s", "Half-Life 2: Survivor");
	if (gmodarray != INVALID_HANDLE)
		if (GetArraySize(gmodarray) > 0)
			menu.AddItem("gmod", "Garry's Mod");
	if (qncarray != INVALID_HANDLE)
		if (GetArraySize(qncarray) > 0)
			menu.AddItem("qnc", "QuickNinjaCat");
	if (n7larray != INVALID_HANDLE)
		if (GetArraySize(n7larray) > 0)
			menu.AddItem("n7l", "N7Legion");
	if (kudarray != INVALID_HANDLE)
		if (GetArraySize(kudarray) > 0)
			menu.AddItem("kud", "Kud♪");
	if (cssarray != INVALID_HANDLE)
		if (GetArraySize(cssarray) > 0)
			menu.AddItem("css", "CSS");
	if (cs16array != INVALID_HANDLE)
		if (GetArraySize(cs16array) > 0)
			menu.AddItem("cs16", "CS 1.6");
	if (mawsarray != INVALID_HANDLE)
		if (GetArraySize(mawsarray) > 0)
			menu.AddItem("maws", "Mawskeeto");
	if (hl1array != INVALID_HANDLE)
		if (GetArraySize(hl1array) > 0)
			menu.AddItem("hl1", "HL1");
	if (l4darray != INVALID_HANDLE)
		if (GetArraySize(l4darray) > 0)
			menu.AddItem("l4d", "L4D");
	if (scarray != INVALID_HANDLE)
		if (GetArraySize(scarray) > 0)
			menu.AddItem("scm", "Sven Co-op");
	if (GetArraySize(modelarray2) > 0)
	{
		char tmp2[48];
		Format(tmp2,sizeof(tmp2),"%T","OCM",client);
		menu.AddItem("ocm", tmp2);
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 20);

	return Plugin_Handled;
}

public Action modelmenutype(int client, int type)
{
	Menu menu = new Menu(MenuHandler);
	char tmp[48];
	Format(tmp,sizeof(tmp),"%T","ModelMenu",client);
	menu.SetTitle(tmp);
	Handle tmparray = INVALID_HANDLE;
	if (type == 1)
		tmparray = CloneArray(magisterarray);
	if (type == 2)
		tmparray = CloneArray(darxarray);
	if (type == 3)
		tmparray = CloneArray(gmodarray);
	if (type == 4)
		tmparray = CloneArray(hl2sarray);
	if (type == 5)
		tmparray = CloneArray(qncarray);
	if (type == 6)
		tmparray = CloneArray(modelarray2);
	if (type == 7)
		tmparray = CloneArray(n7larray);
	if (type == 8)
		tmparray = CloneArray(kudarray);
	if (type == 9)
		tmparray = CloneArray(cssarray);
	if (type == 10)
		tmparray = CloneArray(cs16array);
	if (type == 11)
		tmparray = CloneArray(mawsarray);
	if (type == 12)
		tmparray = CloneArray(hl1array);
	if (type == 13)
		tmparray = CloneArray(l4darray);
	if (type == 14)
		tmparray = CloneArray(scarray);
	for (int k;k<GetArraySize(tmparray);k++)
	{
		char ktmp[64];
		char ktmpd[64];
		GetArrayString(tmparray, k, ktmp, sizeof(ktmp));
		Format(ktmpd,sizeof(ktmpd),ktmp);
		ReplaceString(ktmpd,sizeof(ktmpd),".mdl","", false);
		if (StrContains(ktmpd, "normal") != -1)
		{
			char tmp2[48];
			Format(tmp2,sizeof(tmp2),"%T","CIT",client);
			ReplaceString(ktmpd,sizeof(ktmpd),"models/player/normal/",tmp2,false);
		}
		menu.AddItem(ktmp, ktmpd);
	}
	ClearArray(tmparray);
	CloseHandle(tmparray);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 60);
 
	return Plugin_Handled;
}

public Action fmodelmenu(int client, int args)
{
	Menu menu = new Menu(MenuHandlerDef);
	char tmp[48];
	Format(tmp,sizeof(tmp),"%T","ModelMenu",client);
	menu.SetTitle(tmp);
	for (int i = 1;i<8;i++)
	{
		if (i != 5)
		{
			char tmp2[48];
			Format(tmp2,sizeof(tmp2),"%T","FemaleNum",client,i);
			char tmp3[48];
			Format(tmp3,sizeof(tmp3),"models/player/normal/female_0%i.mdl",i);
			menu.AddItem(tmp3,tmp2);
		}
	}
	char tmp2i[48];
	Format(tmp2i,sizeof(tmp2i),"%T","FemaleNum",client,0);
	char ktmpd[48];
	ReplaceString(ktmpd,sizeof(ktmpd)," 0",tmp2i,false);
	char tmp2j[48];
	Format(tmp2j,sizeof(tmp2j),"%T","Hero",client,ktmpd);
	menu.AddItem("models/player/normal/hero_female.mdl", tmp2j);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

public Action mmodelmenu(int client, int args)
{
	Menu menu = new Menu(MenuHandlerDef);
	char tmp[48];
	Format(tmp,sizeof(tmp),"%T","ModelMenu",client);
	menu.SetTitle(tmp);
	for (int i = 1;i<10;i++)
	{
		char tmp2[48];
		Format(tmp2,sizeof(tmp2),"%T","MaleNum",client,i);
		char tmp3[48];
		Format(tmp3,sizeof(tmp3),"models/player/normal/male_0%i.mdl",i);
		menu.AddItem(tmp3,tmp2);
	}
	char tmp2i[48];
	char tmp2j[48];
	Format(tmp2i,sizeof(tmp2i),"%T","MaleNum",client,1);
	Format(tmp2j,sizeof(tmp2j),"%T","Hero",client,tmp2i);
	menu.AddItem("models/player/normal/hero_male.mdl",tmp2j);
	char tmp2k[48];
	char tmp2l[48];
	Format(tmp2k,sizeof(tmp2k),"%T","MaleNum",client,2);
	Format(tmp2l,sizeof(tmp2l),"%T","Hero",client,tmp2k);
	menu.AddItem("models/player/normal/hero_male02.mdl",tmp2l);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

public Action rfmodelmenu(int client, int args)
{
	Menu menu = new Menu(MenuHandlerDef);
	char tmp[48];
	Format(tmp,sizeof(tmp),"%T","ModelMenu",client);
	menu.SetTitle(tmp);
	for (int i = 1;i<8;i++)
	{
		if (i != 5)
		{
			char tmp2[48];
			Format(tmp2,sizeof(tmp2),"%T","FemaleNum",client,i);
			char tmp3[48];
			Format(tmp3,sizeof(tmp3),"female_0%i.mdl",i);
			menu.AddItem(tmp3,tmp2);
		}
	}
	char tmp2i[48];
	Format(tmp2i,sizeof(tmp2i),"%T","FemaleNum",client,0);
	char ktmpd[48];
	ReplaceString(ktmpd,sizeof(ktmpd)," 0",tmp2i,false);
	char tmp2j[48];
	Format(tmp2j,sizeof(tmp2j),"%T","Hero",client,ktmpd);
	menu.AddItem("hero_female.mdl", tmp2j);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

public Action rmmodelmenu(int client, int args)
{
	Menu menu = new Menu(MenuHandlerDef);
	char tmp[48];
	Format(tmp,sizeof(tmp),"%T","ModelMenu",client);
	menu.SetTitle(tmp);
	for (int i = 1;i<10;i++)
	{
		char tmp2[48];
		Format(tmp2,sizeof(tmp2),"%T","MaleNum",client,i);
		char tmp3[48];
		Format(tmp3,sizeof(tmp3),"male_0%i.mdl",i);
		menu.AddItem(tmp3,tmp2);
	}
	char tmp2i[48];
	char tmp2j[48];
	Format(tmp2i,sizeof(tmp2i),"%T","MaleNum",client,1);
	Format(tmp2j,sizeof(tmp2j),"%T","Hero",client,tmp2i);
	menu.AddItem("hero_male.mdl",tmp2j);
	char tmp2k[48];
	char tmp2l[48];
	Format(tmp2k,sizeof(tmp2k),"%T","MaleNum",client,2);
	Format(tmp2l,sizeof(tmp2l),"%T","Hero",client,tmp2k);
	menu.AddItem("hero_male02.mdl",tmp2l);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

public int PanelHandler(Handle menu, MenuAction action, int client, int param1)
{
	if (action == MenuAction_Select)
	{
		int args;
		if (param1 == 1)
		{
			mmodelmenu(client, args);
		}
		else if (param1 == 2)
		{
			fmodelmenu(client, args);
		}
		else if (param1 == 3)
		{
			rmmodelmenu(client, args);
		}
		else if (param1 == 4)
		{
			rfmodelmenu(client, args);
		}
		else
		{
			if (GetArraySize(modelarray) < 1)
			{
				PrintToChat(client,"%T","NoCustomModels",client);
				modelmenu(client,0);
			}
			else
			{
				cmodelmenu(client, args);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return 0;
}

public Action modelmenu(int client, int args)
{
	if (args > 0)
	{
		char atmptmdl[64];
		char multfound[1024];
		char ktmp[64];
		char sfound[64];
		int found = 0;
		GetCmdArgString(atmptmdl, sizeof(atmptmdl));
		ReplaceString(atmptmdl,sizeof(atmptmdl),"model ","", false);
		ReplaceString(atmptmdl,sizeof(atmptmdl),"models ","", false);
		for (int k;k<GetArraySize(modelarray);k++)
		{
			GetArrayString(modelarray, k, ktmp, sizeof(ktmp));
			if (StrContains(ktmp, atmptmdl, false) != -1)
			{
				found++;
				Format(multfound,sizeof(multfound),"%s\n%s",multfound,ktmp);
				Format(sfound,sizeof(sfound),"%s",ktmp);
			}
			if (StrEqual(atmptmdl, ktmp))
			{
				found = 1;
				Format(sfound,sizeof(sfound),"%s",ktmp);
				break;
			}
		}
		if (found > 1)
		{
			if (found < 5)
			{
				PrintToChat(client,"%T","MultipleReturnedSearch",client,multfound);
			}
			else
			{
				PrintToChat(client,"%T","TooManyToShowInChat",client);
				PrintToConsole(client,"%T","MultipleReturnedSearchConsole",client,multfound);
			}
		}
		else if (found == 1)
		{
			Format(desmodel[client],sizeof(desmodel[]),"%s",sfound);
			setmodel(client, sfound);
			PrintToChat(client,"%T","SetModelTo",client,sfound);
			char change[254];
			Format(change,254,"UPDATE modelloader SET 'mdl' = '%s' WHERE SteamID = '%s';",sfound,szSteamIDbuf[client]);
			SQL_Query(Handle_Database,change);
		}
		else
		{
			PrintToChat(client,"%T","CouldntFindModel",client,atmptmdl);
		}
		return Plugin_Handled;
	}
	Handle panel = CreatePanel();
	SetPanelTitle(panel, "Select model group:");
	DrawPanelItem(panel, "Male Citizen");
	DrawPanelItem(panel, "Female Citizen");
	DrawPanelItem(panel, "Male Rebel");
	DrawPanelItem(panel, "Female Rebel");
	if (GetArraySize(modelarray) > 0) DrawPanelItem(panel, "Custom");
 
	SendPanelToClient(panel, client, PanelHandler, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

public int MenuHandlerDef(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[128];
		int noch = 0;
		menu.GetItem(param2, info, sizeof(info));
		int donstat = 1;
		if (HasEntProp(param1,Prop_Send,"m_iSynergyDonorStat"))
			donstat = GetEntProp(param1, Prop_Send, "m_iSynergyDonorStat");
		if ((StrContains( info, "hero_male") != -1) || (StrContains( info, "hero_female") != -1))
		{
			if (donstat < 1)
			{
				PrintToChat(param1,"%T","DonatorOnly",param1);
				noch = 1;
			}
		}
		if (noch == 0)
		{
			setmodel(param1, info);
			char change[254];
			Format(change,254,"UPDATE modelloader SET 'mdl' = '%s' WHERE SteamID = '%s';",info,szSteamIDbuf[param1]);
			SQL_Query(Handle_Database,change);
			Format(desmodel[param1],sizeof(desmodel[]),"%s",info);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			modelmenu(param1,0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[128];
		int noch = 0;
		menu.GetItem(param2, info, sizeof(info));
		int donstat = 1;
		if (HasEntProp(param1,Prop_Send,"m_iSynergyDonorStat"))
			donstat = GetEntProp(param1, Prop_Send, "m_iSynergyDonorStat");
		if ((StrContains( info, "hero_male") != -1) || (StrContains( info, "hero_female") != -1))
		{
			if (donstat < 1)
			{
				PrintToChat(param1,"%T","DonatorOnly",param1);
				noch = 1;
			}
		}
		if (noch == 0)
		{
			setmodel(param1, info);
			char change[254];
			Format(change,254,"UPDATE modelloader SET 'mdl' = '%s' WHERE SteamID = '%s';",info,szSteamIDbuf[param1]);
			SQL_Query(Handle_Database,change);
			Format(desmodel[param1],sizeof(desmodel[]),"%s",info);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			cmodelmenu(param1,0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlersub(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "magister"))
			modelmenutype(param1, 1);
		else if (StrEqual(info, "darx"))
			modelmenutype(param1, 2);
		else if (StrEqual(info, "gmod"))
			modelmenutype(param1, 3);
		else if (StrEqual(info, "hl2s"))
			modelmenutype(param1, 4);
		else if (StrEqual(info, "qnc"))
			modelmenutype(param1, 5);
		else if (StrEqual(info, "ocm"))
			modelmenutype(param1, 6);
		else if (StrEqual(info, "n7l"))
			modelmenutype(param1, 7);
		else if (StrEqual(info, "kud"))
			modelmenutype(param1, 8);
		else if (StrEqual(info, "css"))
			modelmenutype(param1, 9);
		else if (StrEqual(info, "cs16"))
			modelmenutype(param1, 10);
		else if (StrEqual(info, "maws"))
			modelmenutype(param1, 11);
		else if (StrEqual(info, "hl1"))
			modelmenutype(param1, 12);
		else if (StrEqual(info, "l4d"))
			modelmenutype(param1, 13);
		else if (StrEqual(info, "scm"))
			modelmenutype(param1, 14);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			modelmenu(param1,0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void matarraypopulate()
{
	Handle ndirlisting = OpenDirectory("models/player", true, NULL_STRING);
	Handle mdirlisting = OpenDirectory("materials", true, NULL_STRING);
	char buff[64];
	while (ReadDirEntry(ndirlisting, buff, sizeof(buff)))
	{
		if ((!(ndirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
		{
			if ((!(StrContains(buff, ".ztmp", false) != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
			{
				char sbuf[128];
				Format(sbuf, sizeof(sbuf), "models/player/%s", buff);
				if ((!(StrContains(sbuf, ".", false) != -1)) && (DirExists(sbuf,true,NULL_STRING)))
				{
					recursion(sbuf);
				}
			}
		}
	}
	if (dlactive)
	{
		while (ReadDirEntry(mdirlisting, buff, sizeof(buff)))
		{
			if ((!(mdirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
			{
				if ((!(StrContains(buff, ".ztmp", false) != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
				{
					char sbuf[128];
					Format(sbuf, sizeof(sbuf), "materials/%s", buff);
					if ((!(StrContains(sbuf, ".", false) != -1)) && (DirExists(sbuf,true,NULL_STRING)))
					{
						recursion(sbuf);
					}
				}
			}
		}
	}
	CloseHandle(mdirlisting);
	CloseHandle(ndirlisting);
}

void recursion(const char sbuf[128])
{
	char buff[128];
	Handle msubdirlisting = OpenDirectory(sbuf, true, NULL_STRING);
	if (msubdirlisting == INVALID_HANDLE) PrintToServer("Stopped at %s",sbuf);
	while (ReadDirEntry(msubdirlisting, buff, sizeof(buff)))
	{
		if ((!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))) && (!(msubdirlisting == INVALID_HANDLE)))
		{
			if ((!(StrContains(buff, ".ztmp") != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
			{
				char buff2[128];
				Format(buff2,sizeof(buff2),"%s/%s",sbuf,buff);
				if ((StrContains(buff2, ".", false) != -1) && (FindStringInArray(matarray, buff2) == -1) && (FileExists(buff2,false)))
				{
					if (dlactive) AddFileToDownloadsTable(buff2);
					PushArrayString(matarray, buff2);
				}
				if ((StrContains(buff2, ".mdl", false) != -1) && !(((StrContains(buff2, "models/player/normal/female_0", false) == 0) || (StrContains(buff2, "models/player/normal/male_0", false) == 0) || (StrEqual(buff2,"models/player/normal/hero_female.mdl",false)) || (StrEqual(buff2,"models/player/normal/hero_male.mdl",false)) || (StrEqual(buff2,"models/player/normal/hero_male02.mdl",false))) || (StrContains(buff2, "models/player/rebel/female_0", false) == 0) || (StrContains(buff2, "models/player/rebel/male_0", false) == 0) || (StrEqual(buff2,"models/player/rebel/hero_female.mdl",false)) || (StrEqual(buff2,"models/player/rebel/hero_male.mdl",false)) || (StrEqual(buff2,"models/player/rebel/hero_male02.mdl",false))))
				{
					if ((StrContains(buff2, "player/normal", false) != -1) && (FindStringInArray(modelarray,buff2) == -1))
					{
						PushArrayString(modelarray, buff2);
					}
					if (StrContains(buff2, "player/rebel", false) != -1)
					{
						char buff3[128];
						Format(buff3,sizeof(buff3),"%s",buff2);
						ReplaceString(buff3,sizeof(buff3),"models/player/rebel/","", false);
						if (FindStringInArray(modelarray,buff3) == -1)
							PushArrayString(modelarray, buff3);
					}
					//PrecacheModel(buff2);
				}
				if ((!(StrContains(buff2, ".", false) != -1)) && (DirExists(buff2,true,NULL_STRING)))
				{
					recursion(buff2);
				}
			}
		}
	}
	CloseHandle(msubdirlisting);
}

public void OnMapStart()
{
	ClearArray(precachedarr);
	if (dlactive)
	{
		for (int k;k<GetArraySize(matarray);k++)
		{
			char ktmp[128];
			GetArrayString(matarray, k, ktmp, sizeof(ktmp));
			AddFileToDownloadsTable(ktmp);
		}
	}
	HookEntityOutput("item_suit", "OnPlayerTouch", onsuitpickup);
}

public Action showmodelpacks(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	QueryClientConVar(client,"cl_motd_disable",panelchk);
	return Plugin_Handled;
}

public void panelchk(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (StrEqual(cvarValue,"1",false))
	{
		ClientCommand(client,"cl_motd_disable 0");
		CreateTimer(0.5,resetmotd,client);
	}
	else
		ShowMOTDPanel(client,"Synergy Workshop","http://steamcommunity.com/sharedfiles/filedetails/?id=947132295",MOTDPANEL_TYPE_URL);
}

public Action resetmotd(Handle timer, int client)
{
	if (IsClientConnected(client))
	{
		ShowMOTDPanel(client,"Synergy Workshop","http://steamcommunity.com/sharedfiles/filedetails/?id=947132295",MOTDPANEL_TYPE_URL);
		ClientCommand(client,"cl_motd_disable 1");
	}
}

public void sndfixch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) soundfix = true;
	else soundfix = false;
}

public Action customsoundchecksnorm(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (soundfix)
	{
		if ((StrContains(sample,"vo",false) != -1) && ((StrContains(sample,"/ow",false) != -1) || (StrContains(sample,"pain",false) != -1) || (StrContains(sample,"gut",false) != -1) || (StrContains(sample,"arm",false) != -1) || (StrContains(sample,"leg",false) != -1)) && (entity > 0) && (entity < MaxClients+1))
		{
			int randsound = GetRandomInt(1,9);
			char randcat[64];
			IntToString(randsound,randcat,sizeof(randcat));
			char plymdl[64];
			GetClientModel(entity, plymdl, sizeof(plymdl));
			if ((StrContains(plymdl,"scientist_female - bms",false) != -1) && (FileExists("sound/vo/npc/scientist_female01/ow01.wav",true,NULL_STRING)))
			{
				if (StrContains(sample,"/ow",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\scientist_female01\\ow0%i.wav",randsound);
				else if (StrContains(sample,"help",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\scientist_female01\\help0%i.wav",GetRandomInt(1,2));
				else
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\pain0%i.wav",randsound);
			}
			else if (StrContains(plymdl,"female") != -1)
			{
				if (StrContains(sample,"gut",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\hitingut0%i.wav",GetRandomInt(1,2));
				else if (StrContains(sample,"arm",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\myarm0%i.wav",GetRandomInt(1,2));
				else if (StrContains(sample,"leg",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\myleg0%i.wav",GetRandomInt(1,2));
				else if (StrContains(sample,"help",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\help01.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\npc\\female01\\pain0%i.wav",GetRandomInt(1,9));
			}
			else if (StrContains(plymdl,"combine") != -1)
			{
				Format(randcat,sizeof(randcat),"npc\\combine_soldier\\pain%i.wav",GetRandomInt(1,3));
			}
			else if ((StrContains(plymdl,"metropolice") != -1) || (StrContains(plymdl,"metrocop") != -1))
			{
				if (StrContains(sample,"help",false) != -1)
					Format(randcat,sizeof(randcat),"npc\\metropolice\\vo\\officerneedshelp.wav");
				else
					Format(randcat,sizeof(randcat),"npc\\metropolice\\pain%i.wav",GetRandomInt(1,4));
			}
			else if (StrContains(plymdl,"robo",false) != -1)
			{
				randsound = GetRandomInt(1,19);
				if ((randsound == 12) || (randsound == 13)) randsound = 11;
				Format(randcat,sizeof(randcat),"buttons\\button%i.wav",randsound);
			}
			else if (StrContains(plymdl,"gman",false) != -1)
			{
				randsound = GetRandomInt(1,9);
				Format(randcat,sizeof(randcat),"vo\\citadel\\gman_exit0%i.wav",randsound);
			}
			else if ((StrContains(plymdl,"barney",false) != -1) || (StrContains(plymdl,"guard - bms",false) != -1))
			{
				if (FileExists("sound/vo/npc/barneys/pain16.wav",true,NULL_STRING))
				{
					if (StrContains(sample,"gut",false) != -1)
						Format(randcat,sizeof(randcat),"vo\\npc\\barneys\\mygut0%i.wav",GetRandomInt(1,3));
					else if (StrContains(sample,"arm",false) != -1)
						Format(randcat,sizeof(randcat),"vo\\npc\\barneys\\myarm0%i.wav",GetRandomInt(1,3));
					else if (StrContains(sample,"leg",false) != -1)
						Format(randcat,sizeof(randcat),"vo\\npc\\barneys\\myleg0%i.wav",GetRandomInt(1,3));
					else if (StrContains(sample,"/ow",false) != -1)
						Format(randcat,sizeof(randcat),"vo\\npc\\barneys\\ow0%i.wav",GetRandomInt(1,5));
					else
					{
						int rand = GetRandomInt(1,16);
						if (rand < 10) Format(randcat,sizeof(randcat),"vo\\npc\\barneys\\pain0%i.wav",rand);
						else Format(randcat,sizeof(randcat),"vo\\npc\\barneys\\pain%i.wav",rand);
					}
				}
				else
				{
					if (StrContains(sample,"help",false) != -1)
						Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_littlehelphere.wav");
					else
					{
						int rand = GetRandomInt(1,10);
						if (rand < 10) Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_pain0%i.wav",rand);
						else Format(randcat,sizeof(randcat),"vo\\npc\\barney\\ba_pain%i.wav",rand);
					}
				}
			}
			else if ((StrContains(plymdl,"scientist - bms",false) != -1) && (FileExists("sound/vo/npc/scientist_male01/pain01.wav",true,NULL_STRING)))
			{
				if (StrContains(sample,"gut",false) != -1)
				{
					switch(GetRandomInt(1,6))
					{
						case 1:
							Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\hitingut01a_sp01.wav");
						case 2:
							Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\hitingut01b_sp01.wav");
						case 3:
							Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\hitingut02_sp01.wav");
						case 4:
							Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\hitingut03_sp01.wav");
						case 5:
							Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\hitingut04_sp01.wav");
						case 6:
							Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\hitingut05_sp01.wav");
					}
				}
				else if (StrContains(sample,"arm",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\myarm01_take01.wav");
				else if (StrContains(sample,"/ow",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\ow0%i.wav",GetRandomInt(1,8));
				else if (StrContains(sample,"help",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\help0%i_sp03.wav",GetRandomInt(1,5));
				else
				{
					randsound = GetRandomInt(1,20);
					if (randsound < 10) Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\pain0%i.wav",randsound);
					else Format(randcat,sizeof(randcat),"vo\\npc\\scientist_male01\\pain%i.wav",randsound);
				}
			}
			else
			{
				if (StrContains(sample,"gut",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\hitingut0%i.wav",GetRandomInt(1,2));
				else if (StrContains(sample,"arm",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\myarm0%i.wav",GetRandomInt(1,2));
				else if (StrContains(sample,"leg",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\myleg0%i.wav",GetRandomInt(1,2));
				else if (StrContains(sample,"help",false) != -1)
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\help01.wav");
				else
					Format(randcat,sizeof(randcat),"vo\\npc\\male01\\pain0%i.wav",randsound);
			}
			if (FindStringInArray(precachedarr,randcat) == -1)
			{
				PrecacheSound(randcat,true);
				PushArrayString(precachedarr,randcat);
			}
			//IsSoundPrecached() always returns true in Synergy.
			//PrintToServer("Changed %s to %s mdl %s",sample,randcat,plymdl);
			Format(sample,sizeof(sample),"%s",randcat);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
