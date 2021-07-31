/*
* Crashed Map Recovery (c) 2009 Jonah Hirsch
* This has been edited by Balimbanana
* 
* 
* Loads the map the server was on before it crashed when server restarts
* 
*  
* Changelog								
* ------------		
* 1.6
*  - Balimbanana changes SQLite database for more reliability and forked server configs.
* 1.5
*  - Messages are now logged to logs/CMR.log
*  - crashmap.txt is now generated automatically
* 1.4.3
*  - Fixed compile warnings
*  - Backs up and restores nextmap on crash + recover (test feature!)
* 1.4.2
*  - Autoconfig added. cfg/sourcemod/plugin.crashmap.cfg
* 1.4.1
*  - Added FCVAR_DONTRECORD to version cvar
* 1.4
*  - Added sm_crashmap_maxrestarts
*  - Added support for checking if the map being changed to crashes the server
* 1.3
*  - Changed method of enabling/disabling recover time to improve performance
*  - Added sm_crashmap_interval
* 1.2
*  - Added timelimit recovery
*  - Added sm_crashmap_recovertime
* 1.1
*  - Added log message when map is recoevered on restart
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.62"
#pragma semicolon 1;
#pragma newdecls required;

//static char FileLoc[128];
char logPath[PLATFORM_MAX_PATH];
Handle logFileHandle = INVALID_HANDLE;
//Handle dataFileHandle = INVALID_HANDLE;
Handle sm_crashmap_enabled = INVALID_HANDLE;
Handle sm_crashmap_maxrestarts = INVALID_HANDLE;
bool Recovered = false;

//new
Handle Handle_Database = INVALID_HANDLE;
char srvname[64];

public Plugin myinfo = 
{
	name = "Crashed Map Recovery",
	author = "Crazydog",
	description = "Reloads map that was being played before server crash",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public void OnPluginStart()
{
	CreateConVar("sm_crashmap_version", PLUGIN_VERSION, "Crashed Map Recovery Version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_crashmap_enabled = CreateConVar("sm_crashmap_enabled", "1", "Enable Crashed Map Recovery? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_crashmap_maxrestarts = CreateConVar("sm_crashmap_maxrestarts", "5", "How many consecutive crashes until server loads the default map", FCVAR_NOTIFY, true, 3.0);
	AutoExecConfig(true, "plugin.crashmap");
	/*
	BuildPath(Path_SM, FileLoc, 128, "data/crashmap.txt");
	if (!FileExists(FileLoc))
	{
		dataFileHandle = OpenFile(FileLoc,"a");
		WriteFileLine(dataFileHandle,"SavedMap");
		WriteFileLine(dataFileHandle,"{");
		WriteFileLine(dataFileHandle,"}");
		CloseHandle(dataFileHandle);
	}
	*/
	BuildPath(Path_SM, logPath, PLATFORM_MAX_PATH, "/logs/CMR.log");
	if (!FileExists(logPath))
	{
		logFileHandle = OpenFile(logPath, "a");
		CloseHandle(logFileHandle);
	}
	//new
	char Error[100];
	Handle_Database = SQLite_UseDatabase("sourcemod-local",Error,100-1);
	if (Handle_Database == INVALID_HANDLE)
		LogError("SQLite error: %s",Error);
	//SQL_FastQuery(Handle_Database,"DROP TABLE srvcm;");
	Handle hostnam = FindConVar("hostname");
	if (hostnam != INVALID_HANDLE)
	{
		HookConVarChange(hostnam, HostNameChange);
		GetConVarString(hostnam,srvname,sizeof(srvname));
	}
	CloseHandle(hostnam);
	if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS srvcm('srvname' VARCHAR(32) NOT NULL PRIMARY KEY,'mapname' VARCHAR(32) NOT NULL,'restarts' INT NOT NULL);"))
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return;
	}
	RegServerCmd("crashmap_changerestoremap",changerestoremap);
	// Plugin reloaded after map changes have occurred
	if (GetMapHistorySize() > 0)
	{
		int ent = -1;
		while((ent = FindEntityByClassname(ent,"trigger_changelevel")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(ent))
			{
				SDKHookEx(ent,SDKHook_StartTouch,TrigChangeRestore);
			}
		}
	}
}

public void OnMapStart()
{
	Handle hostnam = FindConVar("hostname");
	GetConVarString(hostnam,srvname,sizeof(srvname));
	CloseHandle(hostnam);
	if(GetConVarInt(sm_crashmap_enabled) == 0)
	{
		return;
	}
	if(Recovered){
		
		//new sys sqlite
		char CurrentMap[128];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		char origQuery[256];
		Format(origQuery,256,"SELECT * FROM srvcm WHERE srvname = '%s';",srvname);
		Handle hQuery = SQL_Query(Handle_Database,origQuery);
		if (hQuery == INVALID_HANDLE)
		{
			char Err[100];
			SQL_GetError(Handle_Database,Err,100);
			LogError("SQLite error: %s with query %s",Err,origQuery);
			CloseHandle(hQuery);
		}
		else if (!SQL_FetchRow(hQuery))
		{
			char Query[256];
			Format(Query,256,"INSERT INTO srvcm VALUES(");
			char thistemp[64];
			Handle cvar = FindConVar("content_metadata");
			if (cvar != INVALID_HANDLE)
			{
				char contentdata[64];
				GetConVarString(cvar,contentdata,sizeof(contentdata));
				char fixuptmp[16][16];
				ExplodeString(contentdata," ",fixuptmp,16,16,true);
				Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
				if (strlen(fixuptmp[2]) > 0) Format(CurrentMap,sizeof(CurrentMap),"%s %s",fixuptmp[2],CurrentMap);
			}
			CloseHandle(cvar);
			Format(thistemp,sizeof(thistemp),"'%s','%s',0);",srvname,CurrentMap);
			StrCat(Query,256,thistemp);
			SQL_FastQuery(Handle_Database,Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
			CloseHandle(hQuery);
		}
		else
		{
			CreateTimer(1.0,delayedcheck,hQuery,TIMER_FLAG_NO_MAPCHANGE);
		}
		
		return;
	}
	if(!Recovered){
		//char MapToLoad[256], String:nextmap[256], timeleft, restarts
		//new sys sqlite
		char CurrentMap[128];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		char origQuery[256];
		Format(origQuery,256,"SELECT * FROM srvcm WHERE srvname = '%s';",srvname);
		Handle hQuery = SQL_Query(Handle_Database,origQuery);
		if (hQuery == INVALID_HANDLE)
		{
			char Err[100];
			SQL_GetError(Handle_Database,Err,100);
			LogError("SQLite error: %s with query %s",Err,origQuery);
		}
		else if (!SQL_FetchRow(hQuery))
		{
			char Query[256];
			Format(Query,256,"INSERT INTO srvcm VALUES(");
			char thistemp[128];
			Handle cvar = FindConVar("content_metadata");
			if (cvar != INVALID_HANDLE)
			{
				char contentdata[64];
				GetConVarString(cvar,contentdata,sizeof(contentdata));
				char fixuptmp[16][16];
				ExplodeString(contentdata," ",fixuptmp,16,16,true);
				Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
				if (strlen(fixuptmp[2]) > 0) Format(CurrentMap,sizeof(CurrentMap),"%s %s",fixuptmp[2],CurrentMap);
			}
			CloseHandle(cvar);
			Format(thistemp,sizeof(thistemp),"'%s','%s',0);",srvname,CurrentMap);
			StrCat(Query,256,thistemp);
			SQL_FastQuery(Handle_Database,Query);
			PrintToServer(Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
		}
		Recovered = true;
		char MapToLoad[256];
		int restarts;
		SQL_FetchString(hQuery,1,MapToLoad,sizeof(MapToLoad));
		restarts = SQL_FetchInt(hQuery,2);
		//if (StrEqual(MapToLoad,CurrentMap,false));
		restarts++;
		char Query[256];
		Format(Query,256,"UPDATE srvcm SET restarts = %i WHERE srvname = '%s';",restarts,srvname);
		SQL_FastQuery(Handle_Database,Query);
		hQuery = SQL_Query(Handle_Database,origQuery);
		LogToFile(logPath, "Restarts is %i on %s", restarts, srvname);
		
		if(restarts > GetConVarInt(sm_crashmap_maxrestarts)){
			LogToFile(logPath, "[CMR] Error! %s is causing the server to crash. Please fix!", MapToLoad);
			Format(Query,256,"UPDATE srvcm SET restarts = 0 WHERE srvname = '%s';",srvname);
			SQL_FastQuery(Handle_Database,Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
			CloseHandle(hQuery);
			return;
		}
		else
		{
			Format(Query,256,"UPDATE srvcm SET restarts = %i WHERE srvname = '%s';",restarts,srvname);
			SQL_FastQuery(Handle_Database,Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
			CloseHandle(hQuery);
			LogToFile(logPath,"Q %s \nOQ %s \n map %s",Query,origQuery,MapToLoad);
		}
		char gamedir[16];
		GetGameFolderName(gamedir,sizeof(gamedir));
		if (StrEqual(gamedir,"tf_coop_extended",false))
		{
			Handle dp = CreateDataPack();
			WritePackString(dp,MapToLoad);
			CreateTimer(2.0,ChangeLevelDelay,dp,TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogToFile(logPath, "[CMR] %s loaded after server crash.", MapToLoad);
			ServerCommand("changelevel %s",MapToLoad);
		}
		/*
		char gamedir[16];
		GetGameFolderName(gamedir,sizeof(gamedir));
		if (!StrEqual(gamedir,"bms",false))
		{
			ServerCommand("changelevel Custom %s",MapToLoad);
			ServerCommand("changelevel hl2 %s",MapToLoad);
			ServerCommand("changelevel ep1 %s",MapToLoad);
			ServerCommand("changelevel ep2 %s",MapToLoad);
			ServerCommand("changelevel bms %s",MapToLoad);
		}
		*/
		//ForceChangeLevel(MapToLoad, "Crashed Map Recovery");
		return;
	}
}

public Action ChangeLevelDelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char MapToLoad[256];
		ReadPackString(dp,MapToLoad,sizeof(MapToLoad));
		CloseHandle(dp);
		if (strlen(MapToLoad) > 0)
		{
			LogToFile(logPath, "[CMR] %s loaded after server crash.", MapToLoad);
			ServerCommand("changelevel %s",MapToLoad);
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if (IsValidEntity(entity))
	{
		char szCls[32];
		GetEntityClassname(entity,szCls,sizeof(szCls));
		if (StrEqual(szCls,"trigger_changelevel",false))
		{
			SDKUnhook(entity,SDKHook_StartTouch,TrigChangeRestore);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname,"trigger_changelevel",false))
	{
		SDKHookEx(entity,SDKHook_StartTouch,TrigChangeRestore);
	}
}

public Action TrigChangeRestore(int entity, int other)
{
	if ((other > 0) && (other < MaxClients+1))
	{
		if (HasEntProp(entity,Prop_Data,"m_szMapName"))
		{
			char szMap[128];
			GetEntPropString(entity,Prop_Data,"m_szMapName",szMap,sizeof(szMap));
			Handle cvar = FindConVar("content_metadata");
			if (cvar != INVALID_HANDLE)
			{
				char contentdata[64];
				GetConVarString(cvar,contentdata,sizeof(contentdata));
				char fixuptmp[16][16];
				ExplodeString(contentdata," ",fixuptmp,16,16,true);
				Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
				if (strlen(fixuptmp[2]) > 0) Format(szMap,sizeof(szMap),"%s %s",fixuptmp[2],szMap);
			}
			CloseHandle(cvar);
			//PrintToServer("SetCrashRestoreMap \"%s\"",szMap);
			if (strlen(szMap)) SetRestoreMap(szMap);
			SDKUnhook(entity,SDKHook_StartTouch,TrigChangeRestore);
		}
	}
}

public Action changerestoremap(int args)
{
	if (args > 0)
	{
		char changemap[64];
		GetCmdArg(1,changemap,sizeof(changemap));
		PrintToServer("ChangeRestoreMap %s",changemap);
		SetRestoreMap(changemap);
	}
	return Plugin_Handled;
}

void SetRestoreMap(char[] szMap)
{
	char Query[256];
	Format(Query,256,"UPDATE srvcm SET mapname = '%s', restarts = 0 WHERE srvname = '%s';",szMap,srvname);
	SQL_FastQuery(Handle_Database,Query);
	return;
}

public Action delayedcheck(Handle timer, Handle hQuery)
{
	if (hQuery != INVALID_HANDLE)
	{
		char CurrentMap[128];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		Handle cvar = FindConVar("content_metadata");
		if (cvar != INVALID_HANDLE)
		{
			char contentdata[64];
			GetConVarString(cvar,contentdata,sizeof(contentdata));
			char fixuptmp[16][16];
			ExplodeString(contentdata," ",fixuptmp,16,16,true);
			Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
			if (strlen(fixuptmp[2]) > 0) Format(CurrentMap,sizeof(CurrentMap),"%s %s",fixuptmp[2],CurrentMap);
		}
		CloseHandle(cvar);
		char Query[256];
		Format(Query,256,"UPDATE srvcm SET mapname = '%s', restarts = 0 WHERE srvname = '%s';",CurrentMap,srvname);
		SQL_FastQuery(Handle_Database,Query);
		//hQuery = SQL_Query(Handle_Database,origQuery);
	}
}

public void HostNameChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS srvcm('srvname' VARCHAR(32) NOT NULL PRIMARY KEY,'mapname' VARCHAR(32) NOT NULL,'restarts' INT NOT NULL);"))
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
	}
	Format(srvname,sizeof(srvname),"%s",newValue);
}
