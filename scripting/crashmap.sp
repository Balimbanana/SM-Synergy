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
#define PLUGIN_VERSION "1.61"
#pragma semicolon 1;
#pragma newdecls required;

static char FileLoc[128];
char logPath[PLATFORM_MAX_PATH];
Handle logFileHandle = INVALID_HANDLE;
Handle dataFileHandle = INVALID_HANDLE;
Handle sm_crashmap_enabled = INVALID_HANDLE;
Handle sm_crashmap_recovertime = INVALID_HANDLE;
Handle sm_crashmap_interval = INVALID_HANDLE;
Handle sm_crashmap_maxrestarts = INVALID_HANDLE;
Handle TimeleftHandle = INVALID_HANDLE;
bool Recovered = false;
bool TimelimitChanged = false;
bool Overwrite = false;
int newTimelimit;

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
	sm_crashmap_recovertime = CreateConVar("sm_crashmap_recovertime", "0", "Recover timelimit? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_crashmap_interval = CreateConVar("sm_crashmap_interval", "20", "Interval between timeleft updates (in seconds)", FCVAR_NOTIFY, true, 1.0);
	sm_crashmap_maxrestarts = CreateConVar("sm_crashmap_maxrestarts", "5", "How many consecutive crashes until server loads the default map", FCVAR_NOTIFY, true, 3.0);
	AutoExecConfig(true, "plugin.crashmap");
	HookConVarChange(sm_crashmap_recovertime, TimerState);
	HookConVarChange(sm_crashmap_interval, IntervalChange);
	Handle cvar = FindConVar("hostname");
	if (cvar != INVALID_HANDLE) HookConVarChange(cvar, HostNameChange);
	CloseHandle(cvar);
	
	if (GetConVarInt(sm_crashmap_recovertime) == 1)
	{
		TimeleftHandle = CreateTimer(GetConVarFloat(sm_crashmap_interval), SaveTimeleft, _, TIMER_REPEAT);
	}
	BuildPath(Path_SM, FileLoc, 128, "data/crashmap.txt");
	if (!FileExists(FileLoc))
	{
		dataFileHandle = OpenFile(FileLoc,"a");
		WriteFileLine(dataFileHandle,"SavedMap");
		WriteFileLine(dataFileHandle,"{");
		WriteFileLine(dataFileHandle,"}");
		CloseHandle(dataFileHandle);
	}
	
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
	GetConVarString(hostnam,srvname,sizeof(srvname));
	CloseHandle(hostnam);
	if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS srvcm('srvname' VARCHAR(32) NOT NULL PRIMARY KEY,'mapname' VARCHAR(32) NOT NULL,'restarts' INT NOT NULL);"))
	{
		char Err[100];
		SQL_GetError(Handle_Database,Err,100);
		LogError("SQLite error: %s",Err);
		return;
	}
}



public void OnMapStart()
{
	if(GetConVarInt(sm_crashmap_enabled) == 0)
	{
		return;
	}
	if(Recovered){
		/*
		char CurrentMap[128];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		Handle SavedMap;
		SavedMap = CreateKeyValues("SavedMap");
		FileToKeyValues(SavedMap, FileLoc);
		KvJumpToKey(SavedMap, "Map", true);
		KvSetString(SavedMap, "Map", CurrentMap);
		KvRewind(SavedMap);
		KeyValuesToFile(SavedMap, FileLoc);
		CloseHandle(SavedMap);
		*/
		
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
		/*
		Handle SavedMap
		SavedMap = CreateKeyValues("SavedMap");
		FileToKeyValues(SavedMap, FileLoc);
		KvJumpToKey(SavedMap, "Map", true);
		KvGetString(SavedMap, "Map", MapToLoad, sizeof(MapToLoad));
		restarts = KvGetNum(SavedMap, "restarts", 0);
		//LogToFile(logPath, "[CMR] Server restarted, restarts is %i", restarts);
		restarts++;
		//LogToFile(logPath, "[CMR] Restarts incremented, restarts is %i", restarts);
		LogToFile(logPath, "Restarts is %i", restarts);
		KvSetNum(SavedMap, "restarts", restarts);
		timeleft = KvGetNum(SavedMap, "Timeleft", 30);
		KvGetString(SavedMap, "Nextmap", nextmap, sizeof(nextmap));
		SetNextMap(nextmap);
		newTimelimit = timeleft/60;
		Recovered = true;
		if(restarts > GetConVarInt(sm_crashmap_maxrestarts)){
			LogToFile(logPath, "[CMR] Error! %s is causing the server to crash. Please fix!", MapToLoad);
			KvSetNum(SavedMap, "restarts", 0);
			KvRewind(SavedMap);
			KeyValuesToFile(SavedMap, FileLoc);
			CloseHandle(SavedMap);
			return;
		}
		KvRewind(SavedMap);
		KeyValuesToFile(SavedMap, FileLoc);
		CloseHandle(SavedMap);
		*/
		
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
			Format(thistemp,sizeof(thistemp),"'%s','%s',0);",srvname,CurrentMap);
			StrCat(Query,256,thistemp);
			SQL_FastQuery(Handle_Database,Query);
			PrintToServer(Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
		}
		int timeleft;
		Recovered = true;
		char MapToLoad[256];
		int restarts;
		SQL_FetchString(hQuery,1,MapToLoad,sizeof(MapToLoad));
		restarts = SQL_FetchInt(hQuery,2);
		//if (StrEqual(MapToLoad,CurrentMap,false));
		restarts++;
		char Query[256];
		Format(Query,256,"UPDATE srvcm SET restarts = %i WHERE srvname = '%s'",restarts,srvname);
		SQL_FastQuery(Handle_Database,Query);
		hQuery = SQL_Query(Handle_Database,origQuery);
		LogToFile(logPath, "Restarts is %i on %s", restarts, srvname);
		
		if(restarts > GetConVarInt(sm_crashmap_maxrestarts)){
			LogToFile(logPath, "[CMR] Error! %s is causing the server to crash. Please fix!", MapToLoad);
			Format(Query,256,"UPDATE srvcm SET restarts = 0 WHERE srvname = '%s'",srvname);
			SQL_FastQuery(Handle_Database,Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
			CloseHandle(hQuery);
			return;
		}
		else
		{
			Format(Query,256,"UPDATE srvcm SET restarts = %i WHERE srvname = '%s'",restarts,srvname);
			SQL_FastQuery(Handle_Database,Query);
			hQuery = SQL_Query(Handle_Database,origQuery);
			CloseHandle(hQuery);
			PrintToServer("Q %s \nOQ %s \n map %s",Query,origQuery,MapToLoad);
		}
		
		
		if(GetConVarInt(sm_crashmap_recovertime) == 1){
			LogToFile(logPath, "[CMR] %s loaded after server crash. Timelimit set to %i", MapToLoad, timeleft/60);
		}else{
			LogToFile(logPath, "[CMR] %s loaded after server crash.", MapToLoad);
		}
		ServerCommand("changelevel %s",MapToLoad);
		ServerCommand("changelevel custom %s",MapToLoad);
		//ForceChangeLevel(MapToLoad, "Crashed Map Recovery")
		return;
	}
}

public Action delayedcheck(Handle timer, Handle hQuery)
{
	if (hQuery != INVALID_HANDLE)
	{
		char CurrentMap[128];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		char Query[256];
		Format(Query,256,"UPDATE srvcm SET mapname = '%s', restarts = 0 WHERE srvname = '%s'",CurrentMap,srvname);
		SQL_FastQuery(Handle_Database,Query);
		//hQuery = SQL_Query(Handle_Database,origQuery);
	}
}

public Action SaveTimeleft(Handle timer)
{
	if(Overwrite){
		int timeleft;
		if(!GetMapTimeLeft(timeleft)){
			if(!GetMapTimeLimit(timeleft)){
				timeleft = 30;
			}
		}
		char nextmap[256];
		GetNextMap(nextmap, sizeof(nextmap));
		Handle SavedMap;
		SavedMap = CreateKeyValues("SavedMap");
		FileToKeyValues(SavedMap, FileLoc);
		KvJumpToKey(SavedMap, "Map", true);
		KvSetNum(SavedMap, "Timeleft", timeleft);
		KvSetString(SavedMap, "Nextmap", nextmap) ;
		KvRewind(SavedMap);
		KeyValuesToFile(SavedMap, FileLoc);
		CloseHandle(SavedMap);
	}
}

public void OnClientAuthorized(int client)
{
	Handle SavedMap;
	SavedMap = CreateKeyValues("SavedMap");
	FileToKeyValues(SavedMap, FileLoc);
	KvJumpToKey(SavedMap, "Map", true);
	KvSetNum(SavedMap, "restarts", 0);
	KvRewind(SavedMap);
	KeyValuesToFile(SavedMap, FileLoc);
	CloseHandle(SavedMap);
	if(!TimelimitChanged && GetConVarInt(sm_crashmap_recovertime) == 1)
	{
		ServerCommand("mp_timelimit %i", newTimelimit);
		TimelimitChanged = true;
		Overwrite = true;
	}
}

public void TimerState(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(GetConVarInt(sm_crashmap_recovertime) < 1)
	{
		if(TimeleftHandle != INVALID_HANDLE)
		{
			KillTimer(TimeleftHandle);
			TimeleftHandle = INVALID_HANDLE;
		}
	}
	if(GetConVarInt(sm_crashmap_recovertime) > 0)
	{
		float newTime = GetConVarFloat(sm_crashmap_interval);
		TimeleftHandle = CreateTimer(newTime, SaveTimeleft, _, TIMER_REPEAT);
		Overwrite = true;
	}
}

public void IntervalChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(TimeleftHandle != INVALID_HANDLE)
	{
		float newTime = StringToFloat(newValue);
		KillTimer(TimeleftHandle);
		TimeleftHandle = INVALID_HANDLE;
		TimeleftHandle = CreateTimer(newTime, SaveTimeleft, _, TIMER_REPEAT);
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
