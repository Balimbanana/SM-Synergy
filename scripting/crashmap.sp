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
ConVar hCVReturnMaps;
bool Recovered = false;
int iEnteredFrom = 0;

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
	hCVReturnMaps = FindConVar("sm_crashmap_setreturnmaps");
	if (hCVReturnMaps == INVALID_HANDLE) hCVReturnMaps = CreateConVar("sm_crashmap_setreturnmaps", "1", "Sets whether to set up return maps on crash restore such as d1_town_03 to d1_town_02 transitions.", _, true, 0.0, true, 1.0);
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
		if ((StrEqual(CurrentMap,"d1_town_02",false)) && (iEnteredFrom == 1))
		{
			findrmstarts();
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
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
			}
			int trigtpstart = CreateEntityByName("info_teleport_destination");
			if (trigtpstart != -1)
			{
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
		}
		else if ((StrEqual(CurrentMap,"d2_coast_07",false)) && (iEnteredFrom == 2))
		{
			findrmstarts();
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_shiz,Trigger,,0,1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_4,0,1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_player_1,kill,,0,1");
				DispatchKeyValue(loginp, "OnMapSpawn","dropship,kill,,0,1");
				DispatchKeyValue(loginp, "OnMapSpawn","windmill,kill,,0,1");
				DispatchKeyValue(loginp, "OnMapSpawn","bridge_door_2,Unlock,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","bridge_door_2,Close,,0.1,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","bridge_door_2,Lock,,0.5,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_starttptransition,kill,,30,1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
			int trigtpstart = CreateEntityByName("info_teleport_destination");
			if (trigtpstart != -1)
			{
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
		}
		else if ((StrEqual(CurrentMap,"ep2_outland_02",false)) && (iEnteredFrom == 3))
		{
			int spawnpos = CreateEntityByName("info_player_coop");
			if (spawnpos != -1)
			{
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
			}
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Enable,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,Trigger,,0.1,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","elevator_actor_setup_trigger,TouchTest,,0.1,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawn_player_3rebuild,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","debug_choreo_start_in_elevator,Trigger,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","pointTemplate_vortCalvary,ForceSpawn,,1,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","ss_heal_loop,BeginSequence,,1.2,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		else if ((StrEqual(CurrentMap,"bm_c2a4fedt",false)) && (iEnteredFrom == 4))
		{
			int loginp = CreateEntityByName("logic_auto");
			if (loginp != -1)
			{
				DispatchKeyValue(loginp, "spawnflags","1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_stragglersfailsave,Enable,,0,-1");
				DispatchKeyValue(loginp, "OnMapSpawn","syn_spawn_manager,SetCheckPoint,syn_spawnpoint2_00,0,-1");
				DispatchSpawn(loginp);
				ActivateEntity(loginp);
			}
		}
		iEnteredFrom = 0;
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
		//PrintToServer("MapToLoad \"%s\"",MapToLoad);
		if (StrContains(MapToLoad," d1return",false) != -1)
		{
			ReplaceString(MapToLoad,sizeof(MapToLoad)," d1return","",false);
			iEnteredFrom = 1;
		}
		else if (StrContains(MapToLoad," d2return",false) != -1)
		{
			ReplaceString(MapToLoad,sizeof(MapToLoad)," d2return","",false);
			iEnteredFrom = 2;
		}
		else if (StrContains(MapToLoad," ep2return",false) != -1)
		{
			ReplaceString(MapToLoad,sizeof(MapToLoad)," ep2return","",false);
			iEnteredFrom = 3;
		}
		else if (StrContains(MapToLoad," 4freturn",false) != -1)
		{
			ReplaceString(MapToLoad,sizeof(MapToLoad)," 4freturn","",false);
			iEnteredFrom = 4;
		}
		else iEnteredFrom = 0;
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

void findrmstarts()
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent,"info_player_start")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			AcceptEntityInput(ent,"kill");
		}
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
			if (strlen(szMap))
			{
				if (hCVReturnMaps.BoolValue)
				{
					char szCurMap[128];
					GetCurrentMap(szCurMap, sizeof(szCurMap));
					if ((StrEqual(szCurMap,"d1_town_03",false)) && ((StrEqual(szMap,"d1_town_02",false)) || (StrEqual(szMap,"hl2 d1_town_02",false))))
					{
						StrCat(szMap,sizeof(szMap)," d1return");
					}
					else if ((StrEqual(szCurMap,"d2_coast_08",false)) && ((StrEqual(szMap,"d2_coast_07",false)) || (StrEqual(szMap,"hl2 d2_coast_07",false))))
					{
						StrCat(szMap,sizeof(szMap)," d2return");
					}
					else if ((StrEqual(szCurMap,"ep2_outland_04",false)) && ((StrEqual(szMap,"ep2_outland_02",false)) || (StrEqual(szMap,"ep2 ep2_outland_02",false))))
					{
						StrCat(szMap,sizeof(szMap)," ep2return");
					}
					else if ((StrEqual(szCurMap,"bm_c2a4g",false)) && ((StrEqual(szMap,"bm_c2a4fedt",false)) || (StrEqual(szMap,"bms bm_c2a4fedt",false))))
					{
						StrCat(szMap,sizeof(szMap)," 4freturn");
					}
				}
				//PrintToServer("SetCrashRestoreMap \"%s\"",szMap);
				SetRestoreMap(szMap);
			}
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
		
		char szStoredMap[128];
		SQL_FetchString(hQuery,1,szStoredMap,sizeof(szStoredMap));
		if ((StrContains(szStoredMap,CurrentMap,false) == 0) && (StrContains(szStoredMap,"return",false) != -1))
		{
			// Ensure return maps are not overwritten
			CloseHandle(hQuery);
			return Plugin_Handled;
		}
		
		char Query[256];
		Format(Query,256,"UPDATE srvcm SET mapname = '%s', restarts = 0 WHERE srvname = '%s';",CurrentMap,srvname);
		SQL_FastQuery(Handle_Database,Query);
		//hQuery = SQL_Query(Handle_Database,origQuery);
		CloseHandle(hQuery);
	}
	return Plugin_Handled;
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
