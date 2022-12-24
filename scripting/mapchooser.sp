/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Mapchooser Plugin
 * Creates a map vote at appropriate times, setting sm_nextmap to the winning
 * vote
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
 
#pragma semicolon 1;
#pragma dynamic 65536;
#include <sourcemod>
#include <mapchooser>
#include <sdktools>
#include <nextmap>

public Plugin:myinfo =
{
	name = "MapChooser",
	author = "AlliedModders LLC",
	description = "Automated Map Voting",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

/* Valve ConVars */
ConVar g_Cvar_Winlimit;
ConVar g_Cvar_Maxrounds;
ConVar g_Cvar_Fraglimit;
ConVar g_Cvar_Bonusroundtime;

/* Plugin ConVars */
ConVar g_Cvar_StartTime;
ConVar g_Cvar_StartRounds;
ConVar g_Cvar_StartFrags;
ConVar g_Cvar_ExtendTimeStep;
ConVar g_Cvar_ExtendRoundStep;
ConVar g_Cvar_ExtendFragStep;
ConVar g_Cvar_ExcludeMaps;
ConVar g_Cvar_IncludeMaps;
ConVar g_Cvar_NoVoteMode;
ConVar g_Cvar_Extend;
ConVar g_Cvar_DontChange;
ConVar g_Cvar_EndOfMapVote;
ConVar g_Cvar_VoteDuration;
ConVar g_Cvar_RunOff;
ConVar g_Cvar_RunOffPercent;
ConVar g_Cvar_CycleFile;
ConVar g_Cvar_UseDialogs;

Handle g_VoteTimer = INVALID_HANDLE;
Handle g_RetryTimer = INVALID_HANDLE;

/* Data Handles */
Handle g_MapList = null;
Handle g_NominateList = null;
Handle g_NominateOwners = null;
Handle g_OldMapList = null;
Handle g_NextMapList = null;
Handle g_ActiveVotesList = INVALID_HANDLE;
Menu g_VoteMenu;

int g_Extends;
int g_TotalRounds;
bool g_HasVoteStarted;
bool g_WaitingForVote;
bool g_MapVoteCompleted;
bool g_ChangeMapAtRoundEnd;
bool g_ChangeMapInProgress;
//new g_mapFileSerial = -1;
bool mapchangeinprogress = false;
bool bSynAct = false;
int g_VoteInts[12];
char maptag[64];
char gamename[64];

new MapChange:g_ChangeTime;

Handle g_NominationsResetForward = null;
Handle g_MapVoteStartedForward = null;

/* Upper bound of how many team there could be */
#define MAXTEAMS 10
int g_winCount[MAXTEAMS];

#define VOTE_EXTEND "##extend##"
#define VOTE_DONTCHANGE "##dontchange##"

public OnPluginStart()
{
	LoadTranslations("mapchooser.phrases");
	LoadTranslations("common.phrases");
	
	GetGameFolderName(gamename,sizeof(gamename));
	if (StrEqual(gamename,"synergy",false)) bSynAct = true;
	
	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);
	g_NominateList = CreateArray(arraySize);
	g_NominateOwners = CreateArray(1);
	g_OldMapList = CreateArray(arraySize);
	g_NextMapList = CreateArray(arraySize);
	g_ActiveVotesList = CreateArray(12);
	
	g_Cvar_EndOfMapVote = CreateConVar("sm_mapvote_endvote", "1", "Specifies if MapChooser should run an end of map vote", _, true, 0.0, true, 1.0);

	g_Cvar_StartTime = CreateConVar("sm_mapvote_start", "3.0", "Specifies when to start the vote based on time remaining.", _, true, 1.0);
	g_Cvar_StartRounds = CreateConVar("sm_mapvote_startround", "2.0", "Specifies when to start the vote based on rounds remaining. Use 0 on TF2 to start vote during bonus round time", _, true, 0.0);
	g_Cvar_StartFrags = CreateConVar("sm_mapvote_startfrags", "5.0", "Specifies when to start the vote base on frags remaining.", _, true, 1.0);
	g_Cvar_ExtendTimeStep = CreateConVar("sm_extendmap_timestep", "15", "Specifies how much many more minutes each extension makes", _, true, 5.0);
	g_Cvar_ExtendRoundStep = CreateConVar("sm_extendmap_roundstep", "5", "Specifies how many more rounds each extension makes", _, true, 1.0);
	g_Cvar_ExtendFragStep = CreateConVar("sm_extendmap_fragstep", "10", "Specifies how many more frags are allowed when map is extended.", _, true, 5.0);	
	g_Cvar_ExcludeMaps = CreateConVar("sm_mapvote_exclude", "5", "Specifies how many past maps to exclude from the vote.", _, true, 0.0);
	g_Cvar_IncludeMaps = CreateConVar("sm_mapvote_include", "5", "Specifies how many maps to include in the vote.", _, true, 2.0, true, 6.0);
	g_Cvar_NoVoteMode = CreateConVar("sm_mapvote_novote", "1", "Specifies whether or not MapChooser should pick a map if no votes are received.", _, true, 0.0, true, 1.0);
	g_Cvar_Extend = CreateConVar("sm_mapvote_extend", "0", "Number of extensions allowed each map.", _, true, 0.0);
	g_Cvar_DontChange = CreateConVar("sm_mapvote_dontchange", "1", "Specifies if a 'Don't Change' option should be added to early votes", _, true, 0.0);
	g_Cvar_VoteDuration = CreateConVar("sm_mapvote_voteduration", "20", "Specifies how long the mapvote should be available for.", _, true, 5.0);
	g_Cvar_RunOff = CreateConVar("sm_mapvote_runoff", "0", "Hold run of votes if winning choice is less than a certain margin", _, true, 0.0, true, 1.0);
	g_Cvar_RunOffPercent = CreateConVar("sm_mapvote_runoffpercent", "50", "If winning choice has less than this percent of votes, hold a runoff", _, true, 0.0, true, 100.0);
	g_Cvar_CycleFile = FindConVar("sm_nominate_mapcyclefile");
	if (g_Cvar_CycleFile == INVALID_HANDLE) g_Cvar_CycleFile = CreateConVar("sm_nominate_mapcyclefile", "mapcyclecfg", "Specifies the mapcycle file to use for nominations list", 0);
	g_Cvar_UseDialogs = FindConVar("sm_nominate_usedialogs");
	if (g_Cvar_UseDialogs == INVALID_HANDLE) g_Cvar_UseDialogs = CreateConVar("sm_nominate_usedialogs", "0", "Uses dialogs for nomination menu.", 0, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_mapvote", Command_Mapvote, ADMFLAG_CHANGEMAP, "sm_mapvote - Forces MapChooser to attempt to run a map vote now.");
	RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "sm_setnextmap <map>");
	RegServerCmd("sm_generatemaplist", Command_GenerateMapList);
	RegConsoleCmd("sm_mapchooservote", Command_VoteSpecificInt);

	g_Cvar_Winlimit = FindConVar("mp_winlimit");
	g_Cvar_Maxrounds = FindConVar("mp_maxrounds");
	g_Cvar_Fraglimit = FindConVar("mp_fraglimit");
	g_Cvar_Bonusroundtime = FindConVar("mp_bonusroundtime");
	
	if (g_Cvar_Winlimit || g_Cvar_Maxrounds)
	{
		if (strcmp(gamename, "tf") == 0)
		{
			HookEvent("teamplay_win_panel", Event_TeamPlayWinPanel);
			HookEvent("teamplay_restart_round", Event_TFRestartRound);
			HookEvent("arena_win_panel", Event_TeamPlayWinPanel);
		}
		else if (strcmp(gamename, "nucleardawn") == 0)
		{
			HookEvent("round_win", Event_RoundEnd);
		}
		else
		{
			HookEvent("round_end", Event_RoundEnd);
		}
	}
	/*
	if (g_Cvar_Fraglimit)
	{
		HookEvent("player_death", Event_PlayerDeath);		
	}
	*/
	AutoExecConfig(true, "mapchooser");
	
	//Change the mp_bonusroundtime max so that we have time to display the vote
	//If you display a vote during bonus time good defaults are 17 vote duration and 19 mp_bonustime
	if (g_Cvar_Bonusroundtime)
	{
		g_Cvar_Bonusroundtime.SetBounds(ConVarBound_Upper, true, 30.0);		
	}
	
	g_NominationsResetForward = CreateGlobalForward("OnNominationRemoved", ET_Ignore, Param_String, Param_Cell);
	g_MapVoteStartedForward = CreateGlobalForward("OnMapVoteStarted", ET_Ignore);
	CreateTimer(0.1,recheckchangelevels,_,TIMER_REPEAT);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("mapchooser");	
	
	CreateNative("NominateMap", Native_NominateMap);
	CreateNative("RemoveNominationByMap", Native_RemoveNominationByMap);
	CreateNative("RemoveNominationByOwner", Native_RemoveNominationByOwner);
	CreateNative("InitiateMapChooserVote", Native_InitiateVote);
	CreateNative("CanMapChooserStartVote", Native_CanVoteStart);
	CreateNative("HasEndOfMapVoteFinished", Native_CheckVoteDone);
	CreateNative("GetExcludeMapList", Native_GetExcludeMapList);
	CreateNative("GetNominatedMapList", Native_GetNominatedMapList);
	CreateNative("EndOfMapVoteEnabled", Native_EndOfMapVoteEnabled);

	return APLRes_Success;
}

public OnConfigsExecuted()
{
	/*
	if (ReadMapList(g_MapList,
					 g_mapFileSerial, 
					 "mapchooser",
					 MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		!= null)
		
	{
		if (g_mapFileSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}
	*/
	ClearArray(g_MapList);
	char pathtomapcycle[128];
	GetConVarString(g_Cvar_CycleFile, pathtomapcycle, sizeof(pathtomapcycle));
	Format(pathtomapcycle, sizeof(pathtomapcycle),"cfg/%s.txt", pathtomapcycle);
	if (!FileExists(pathtomapcycle,false))
	{
		PrintToServer("Mapcycle config: cfg/%s does not exist.", pathtomapcycle);
		Format(pathtomapcycle, sizeof(pathtomapcycle), "cfg/mapcyclecfg.txt");
	}
	Handle thishandle = INVALID_HANDLE;
	if (FileExists(pathtomapcycle))
	{
		thishandle = OpenFile(pathtomapcycle, "r");
	}
	else
	{
		if (FileExists("mapcycle.txt", false))
			thishandle = OpenFile("mapcycle.txt", "r");
		else if (FileExists("cfg/mapcycle_default.txt", true, NULL_STRING))
			thishandle = OpenFile("cfg/mapcycle_default.txt", "r");
	}
	
	if (thishandle == INVALID_HANDLE)
	{
		if (FileExists("cfg/mapcyclecfg_default.txt", true, NULL_STRING))
		{
			thishandle = OpenFile("cfg/mapcyclecfg_default.txt", "r");
		}
	}
	
	if (thishandle != INVALID_HANDLE)
	{
		char line[128];
		char szMapPath[128];
		while(!IsEndOfFile(thishandle) && ReadFileLine(thishandle, line, sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line, "//", false) != -1)
			{
				int commentpos = StrContains(line, "//", false);
				if (commentpos != -1)
				{
					Format(line, commentpos+1, "%s", line);
				}
			}
			if (strlen(line) > 0)
			{
				if (!bSynAct)
				{
					Format(szMapPath, sizeof(szMapPath), "maps/%s.bsp", line);
					if (FileExists(szMapPath, true, NULL_STRING))
					{
						PushArrayString(g_MapList, line);
					}
					else
					{
						PrintToServer("MapCycle has invalid map: '%s'", line);
					}
				}
				else
				{
					PushArrayString(g_MapList, line);
				}
			}
		}
		CloseHandle(thishandle);
	}
	
	CreateNextVote();
	SetupTimeleftTimer();
	
	g_TotalRounds = 0;
	
	g_Extends = 0;
	
	g_MapVoteCompleted = false;
	
	ClearArray(g_NominateList);
	ClearArray(g_NominateOwners);
	
	for (new i=0; i<MAXTEAMS; i++)
	{
		g_winCount[i] = 0;	
	}
	

	/* Check if mapchooser will attempt to start mapvote during bonus round time - TF2 Only */
	if (g_Cvar_Bonusroundtime && !g_Cvar_StartRounds.IntValue)
	{
		if (g_Cvar_Bonusroundtime.FloatValue <= g_Cvar_VoteDuration.FloatValue)
		{
			LogError("Warning - Bonus Round Time shorter than Vote Time. Votes during bonus round may not have time to complete");
		}
	}
	
	return;
}

public OnMapEnd()
{
	g_HasVoteStarted = false;
	g_WaitingForVote = false;
	g_ChangeMapAtRoundEnd = false;
	g_ChangeMapInProgress = false;
	
	g_VoteTimer = null;
	g_RetryTimer = null;
	
	decl String:map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	PushArrayString(g_OldMapList, map);
				
	if (GetArraySize(g_OldMapList) > g_Cvar_ExcludeMaps.IntValue)
	{
		RemoveFromArray(g_OldMapList, 0);
	}	
	mapchangeinprogress = false;
}

public void OnMapStart()
{
	mapchangeinprogress = false;
}

public OnClientDisconnect(int client)
{
	new index = FindValueInArray(g_NominateOwners, client);
	
	if (index == -1)
	{
		return;
	}
	
	char oldmap[PLATFORM_MAX_PATH];
	GetArrayString(g_NominateList, index, oldmap, sizeof(oldmap));
	Call_StartForward(g_NominationsResetForward);
	Call_PushString(oldmap);
	Call_PushCell(GetArrayCell(g_NominateOwners, index));
	Call_Finish();
	
	RemoveFromArray(g_NominateOwners, index);
	RemoveFromArray(g_NominateList, index);
}

public Action Command_SetNextmap(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setnextmap <map>");
		return Plugin_Handled;
	}

	decl String:map[PLATFORM_MAX_PATH];
	GetCmdArg(1, map, sizeof(map));
/*
	if (!IsMapValid(map))
	{
		ReplyToCommand(client, "[SM] %t", "Map was not found", map);
		return Plugin_Handled;
	}
*/
	ShowActivity(client, "%t", "Changed Next Map", map);
	LogAction(client, -1, "\"%L\" changed nextmap to \"%s\"", client, map);

	//SetNextMap(map);
	g_MapVoteCompleted = true;

	return Plugin_Handled;
}

public Action Command_GenerateMapList(int args)
{
	char iszFullPath[512];
	char iszContentPath[128];
	char iszWriteString[65536];
	int iMapsFound = 0;
	if (DirExists("maps",true,NULL_STRING))
	{
		Handle hSubDirs = OpenDirectory("maps",false,NULL_STRING);
		if (hSubDirs != INVALID_HANDLE)
		{
			while (ReadDirEntry(hSubDirs, iszFullPath, sizeof(iszFullPath)))
			{
				if ((hSubDirs != INVALID_HANDLE) && (!StrEqual(iszFullPath,".")) && (!StrEqual(iszFullPath,"..")))
				{
					TrimString(iszFullPath);
					if ((StrContains(iszFullPath,".bsp",false) != -1) && (StrContains(iszFullPath,".bsp.",false) == -1))
					{
						ReplaceString(iszFullPath,sizeof(iszFullPath),".bsp","",false);
						PrintToServer("Found map %s from mount point custom",iszFullPath);
						Format(iszFullPath,sizeof(iszFullPath),"custom %s\n",iszFullPath);
						StrCat(iszWriteString,sizeof(iszWriteString),iszFullPath);
						iMapsFound++;
					}
				}
			}
		}
		CloseHandle(hSubDirs);
	}
	if (DirExists("content",true,NULL_STRING))
	{
		Handle hSubDirs = OpenDirectory("content",true,NULL_STRING);
		if (hSubDirs != INVALID_HANDLE)
		{
			char iszDats[120];
			char iszLine[128];
			while (ReadDirEntry(hSubDirs, iszDats, sizeof(iszDats)))
			{
				if ((hSubDirs != INVALID_HANDLE) && (!StrEqual(iszDats,".")) && (!StrEqual(iszDats,"..")))
				{
					if ((StrContains(iszDats,".dat",false) != -1) && (!StrEqual(iszDats,"synergy.dat",false)))
					{
						char iszModName[128];
						bool bIsFirstLine = true;
						char szRootPath[64];
						char szContentTag[32];
						char szContentPath[512];
						Format(iszContentPath,sizeof(iszContentPath),"content/%s",iszDats);
						Handle hDatF = OpenFile(iszContentPath,"r",true,NULL_STRING);
						if (hDatF != INVALID_HANDLE)
						{
							bool bReadingMaps = false;
							while(!IsEndOfFile(hDatF)&&ReadFileLine(hDatF,iszLine,sizeof(iszLine)))
							{
								TrimString(iszLine);
								if (StrContains(iszLine,"//",false) != -1)
								{
									int iCommentPos = StrContains(iszLine,"//",false);
									if (iCommentPos == 0) iszLine = "";
									else
									{
										Format(iszLine,iCommentPos+1,"%s",iszLine);
									}
								}
								if (strlen(iszLine) > 0)
								{
									if (bIsFirstLine)
									{
										bIsFirstLine = false;
										Format(iszModName,sizeof(iszModName),"%s",iszLine);
										ReplaceString(iszModName,sizeof(iszModName),"\"","",false);
									}
									if (((StrEqual(iszLine,"\"maps\"",false)) || (StrEqual(iszLine,"maps",false))) && (!bReadingMaps))
									{
										bReadingMaps = true;
									}
									else if (StrContains(iszLine,"\"tag\"",false) == 0)
									{
										Format(szContentTag,sizeof(szContentTag),"%s",iszLine);
										ReplaceString(szContentTag,sizeof(szContentTag),"\"tag\"","",false);
										ReplaceString(szContentTag,sizeof(szContentTag),"\"","",false);
										TrimString(szContentTag);
									}
									else if (StrContains(iszLine,"\"path\"",false) == 0)
									{
										Format(szContentPath,sizeof(szContentPath),"%s",iszLine);
										ReplaceString(szContentPath,sizeof(szContentPath),"\"path\"","",false);
										ReplaceString(szContentPath,sizeof(szContentPath),"\"","",false);
										TrimString(szContentPath);
									}
									else if (StrContains(iszLine,"\"root\"",false) == 0)
									{
										Format(szRootPath,sizeof(szRootPath),"%s",iszLine);
										ReplaceString(szRootPath,sizeof(szRootPath),"\"root\"","",false);
										ReplaceString(szRootPath,sizeof(szRootPath),"\"","",false);
										TrimString(szRootPath);
									}
									else if (bReadingMaps)
									{
										if (StrContains(iszLine,"}",false) != -1)
										{
											bReadingMaps = false;
											break;
										}
										else if (StrContains(iszLine,"{",false) == -1)
										{
											char iszMapName[64];
											int iSpace = StrContains(iszLine," ",false);
											int iTab = StrContains(iszLine,"	",false);
											if (((iSpace < iTab) || (iTab == -1)) && (iSpace != -1))
												Format(iszMapName,iSpace+1,"%s",iszLine);
											else if (((iTab < iSpace) || (iSpace != -1)) && (iTab != -1))
												Format(iszMapName,iTab+1,"%s",iszLine);
											else if (iTab != -1)
												Format(iszMapName,iTab+1,"%s",iszLine);
											ReplaceString(iszMapName,sizeof(iszMapName),"\"","",false);
											if (strlen(szRootPath) > 0)
											{
												Format(iszFullPath,sizeof(iszFullPath),"../../../%s/%s/maps/%s.bsp",szRootPath,szContentPath,iszMapName);
												if (!FileExists(iszFullPath,true,NULL_STRING)) Format(iszFullPath,sizeof(iszFullPath),"../../%s/%s/maps/%s.bsp",szRootPath,szContentPath,iszMapName);
											}
											else
											{
												Format(iszFullPath,sizeof(iszFullPath),"../../../sourcemods/%s/maps/%s.bsp",szContentPath,iszMapName);
												if (!FileExists(iszFullPath,true,NULL_STRING)) Format(iszFullPath,sizeof(iszFullPath),"../../sourcemods/%s/maps/%s.bsp",szContentPath,iszMapName);
											}
											if (FileExists(iszFullPath,true,NULL_STRING))
											{
												PrintToServer("Found map %s from mount point %s",iszMapName,iszDats);
												Format(iszMapName,sizeof(iszMapName),"%s %s\n",szContentTag,iszMapName);
												StrCat(iszWriteString,sizeof(iszWriteString),iszMapName);
												iMapsFound++;
											}
										}
									}
								}
							}
						}
						CloseHandle(hDatF);
					}
				}
			}
		}
		CloseHandle(hSubDirs);
	}
	if (strlen(iszWriteString) > 0)
	{
		PrintToServer("Found %i valid maps. Placed template in cfg/mapcycletemplate.txt",iMapsFound);
		TrimString(iszWriteString);
		Handle hWriteFile = OpenFile("cfg/mapcycletemplate.txt","wb",false,NULL_STRING);
		if (hWriteFile != INVALID_HANDLE)
		{
			WriteFileString(hWriteFile,iszWriteString,false);
		}
		CloseHandle(hWriteFile);
	}
}

public Action Command_VoteSpecificInt(int client, int args)
{
	if ((client == 0) || (!IsClientConnected(client))) return Plugin_Handled;
	if (args > 0)
	{
		char szArg[16];
		GetCmdArg(1,szArg,sizeof(szArg));
		if (StrEqual(szArg,"nochange",false))
		{
			g_VoteInts[11]++;
		}
		else if (StrEqual(szArg,"extend",false))
		{
			g_VoteInts[10]++;
		}
		else if ((StringToInt(szArg) > 0) && (StringToInt(szArg) < 10))
		{
			g_VoteInts[StringToInt(szArg)]++;
		}
		int totalvotes = 0;
		for (int i = 1;i<12;i++)
		{
			totalvotes+=g_VoteInts[i];
		}
		int clcount = 0;
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsClientConnected(i))
			{
				if (IsClientInGame(i))
				{
					if (!IsFakeClient(i))
					{
						clcount++;
					}
				}
			}
		}
		if (clcount <= totalvotes)
			CreateTimer(0.1,EndVoteDialogs,_,TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public OnMapTimeLeftChanged()
{
	if (GetArraySize(g_MapList))
	{
		SetupTimeleftTimer();
	}
}

SetupTimeleftTimer()
{
	new time;
	if (GetMapTimeLeft(time) && time > 0)
	{
		new startTime = g_Cvar_StartTime.IntValue * 60;
		if (time - startTime < 0 && g_Cvar_EndOfMapVote.BoolValue && !g_MapVoteCompleted && !g_HasVoteStarted)
		{
			InitiateVote(MapChange_MapEnd, null);		
		}
		else
		{
			if (g_VoteTimer != null)
			{
				KillTimer(g_VoteTimer);
				g_VoteTimer = null;
			}	
			
			//g_VoteTimer = CreateTimer(float(time - startTime), Timer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
			Handle data;
			g_VoteTimer = CreateDataTimer(float(time - startTime), Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(data, _:MapChange_MapEnd);
			WritePackCell(data, _:INVALID_HANDLE);
			ResetPack(data);
		}		
	}
}

public Action:Timer_StartMapVote(Handle:timer, Handle:data)
{
	if (timer == g_RetryTimer)
	{
		g_WaitingForVote = false;
		g_RetryTimer = null;
	}
	else
	{
		g_VoteTimer = null;
	}
	
	if (!GetArraySize(g_MapList) || !g_Cvar_EndOfMapVote.BoolValue || g_MapVoteCompleted || g_HasVoteStarted)
	{
		return Plugin_Stop;
	}
	
	new MapChange:mapChange = MapChange:ReadPackCell(data);
	Handle hndl = Handle:ReadPackCell(data);

	InitiateVote(mapChange, hndl);

	return Plugin_Stop;
}

public Event_TFRestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Game got restarted - reset our round count tracking */
	g_TotalRounds = 0;	
}

public Event_TeamPlayWinPanel(Event event, const String:name[], bool:dontBroadcast)
{
	if (g_ChangeMapAtRoundEnd)
	{
		g_ChangeMapAtRoundEnd = false;
		CreateTimer(2.0, Timer_ChangeMap, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		g_ChangeMapInProgress = true;
	}
	
	new bluescore = event.GetInt("blue_score");
	new redscore = event.GetInt("red_score");
		
	if (event.GetInt("round_complete") == 1 || StrEqual(name, "arena_win_panel"))
	{
		g_TotalRounds++;
		
		if (!GetArraySize(g_MapList) || g_HasVoteStarted || g_MapVoteCompleted || !g_Cvar_EndOfMapVote.BoolValue)
		{
			return;
		}
		
		CheckMaxRounds(g_TotalRounds);
		
		switch(event.GetInt("winning_team"))
		{
			case 3:
			{
				CheckWinLimit(bluescore);
			}
			case 2:
			{
				CheckWinLimit(redscore);				
			}			
			//We need to do nothing on winning_team == 0 this indicates stalemate.
			default:
			{
				return;
			}			
		}
	}
}
/* You ask, why don't you just use team_score event? And I answer... Because CSS doesn't. */
public Event_RoundEnd(Event event, const String:name[], bool:dontBroadcast)
{
	if (g_ChangeMapAtRoundEnd)
	{
		g_ChangeMapAtRoundEnd = false;
		CreateTimer(2.0, Timer_ChangeMap, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		g_ChangeMapInProgress = true;
	}
	
	new winner;
	if (strcmp(name, "round_win") == 0)
	{
		// Nuclear Dawn
		winner = event.GetInt("team");
	}
	else
	{
		winner = event.GetInt("winner");
	}
	
	if (winner == 0 || winner == 1 || !g_Cvar_EndOfMapVote.BoolValue)
	{
		return;
	}
	
	if (winner >= MAXTEAMS)
	{
		SetFailState("Mod exceed maximum team count - Please file a bug report.");	
	}

	g_TotalRounds++;
	
	g_winCount[winner]++;
	
	if (!GetArraySize(g_MapList) || g_HasVoteStarted || g_MapVoteCompleted)
	{
		return;
	}
	
	CheckWinLimit(g_winCount[winner]);
	CheckMaxRounds(g_TotalRounds);
}

public CheckWinLimit(winner_score)
{	
	if (g_Cvar_Winlimit)
	{
		int winlimit = g_Cvar_Winlimit.IntValue;
		if (winlimit)
		{			
			if (winner_score >= (winlimit - g_Cvar_StartRounds.IntValue))
			{
				InitiateVote(MapChange_MapEnd, null);
			}
		}
	}
}

public CheckMaxRounds(roundcount)
{		
	if (g_Cvar_Maxrounds)
	{
		int maxrounds = g_Cvar_Maxrounds.IntValue;
		if (maxrounds)
		{
			if (roundcount >= (maxrounds - g_Cvar_StartRounds.IntValue))
			{
				InitiateVote(MapChange_MapEnd, null);
			}			
		}
	}
}

public Event_PlayerDeath(Event event, const String:name[], bool:dontBroadcast)
{
	if (!GetArraySize(g_MapList) || !g_Cvar_Fraglimit || g_HasVoteStarted)
	{
		return;
	}
	
	if (!g_Cvar_Fraglimit.IntValue || !g_Cvar_EndOfMapVote.BoolValue)
	{
		return;
	}

	if (g_MapVoteCompleted)
	{
		return;
	}

	new fragger = GetClientOfUserId(event.GetInt("attacker"));

	if (!fragger)
	{
		return;
	}

	if (GetClientFrags(fragger) >= (g_Cvar_Fraglimit.IntValue - g_Cvar_StartFrags.IntValue))
	{
		InitiateVote(MapChange_MapEnd, null);
	}
}

public Action:Command_Mapvote(client, args)
{
	InitiateVote(MapChange_MapEnd, null);

	return Plugin_Handled;	
}

/**
 * Starts a new map vote
 *
 * @param when			When the resulting map change should occur.
 * @param inputlist		Optional list of maps to use for the vote, otherwise an internal list of nominations + random maps will be used.
 * @param noSpecials	Block special vote options like extend/nochange (upgrade this to bitflags instead?)
 */
InitiateVote(MapChange:when, Handle:inputlist=null)
{
	g_WaitingForVote = true;
	
	if (IsVoteInProgress())
	{
		// Can't start a vote, try again in 5 seconds.
		//g_RetryTimer = CreateTimer(5.0, Timer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
		
		Handle data;
		g_RetryTimer = CreateDataTimer(5.0, Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, _:when);
		WritePackCell(data, _:inputlist);
		ResetPack(data);
		return;
	}
	
	/* If the main map vote has completed (and chosen result) and its currently changing (not a delayed change) we block further attempts */
	if (g_MapVoteCompleted && g_ChangeMapInProgress)
	{
		return;
	}
	
	g_ChangeTime = when;
	
	g_WaitingForVote = false;
		
	g_HasVoteStarted = true;
	Handle gKV = INVALID_HANDLE;
	if (g_Cvar_UseDialogs.BoolValue)
	{
		gKV = CreateKeyValues("data");
		KvSetString(gKV, "title", "Vote Nextmap");
		KvSetNum(gKV, "level", 2);
		KvSetColor(gKV, "color", 255, 255, 0, 255);
		KvSetNum(gKV, "time", 20);
	}
	else
	{
		g_VoteMenu = new Menu(Handler_MapVoteMenu, MenuAction:MENU_ACTIONS_ALL);
		g_VoteMenu.SetTitle("Vote Nextmap");
		g_VoteMenu.VoteResultCallback = Handler_MapVoteFinished;
	}

	/* Call OnMapVoteStarted() Forward */
	Call_StartForward(g_MapVoteStartedForward);
	Call_Finish();
	
	/**
	 * TODO: Make a proper decision on when to clear the nominations list.
	 * Currently it clears when used, and stays if an external list is provided.
	 * Is this the right thing to do? External lists will probably come from places
	 * like sm_mapvote from the adminmenu in the future.
	 */
	 
	char map[PLATFORM_MAX_PATH];
	char szInt[4] = "0";
	char szDesc[64];
	ClearArray(g_ActiveVotesList);
	
	/* No input given - User our internal nominations and maplist */
	if (inputlist == null)
	{
		int nominateCount = GetArraySize(g_NominateList);
		int voteSize = g_Cvar_IncludeMaps.IntValue;
		
		/* Smaller of the two - It should be impossible for nominations to exceed the size though (cvar changed mid-map?) */
		int nominationsToAdd = nominateCount >= voteSize ? voteSize : nominateCount;
		
		for (new i=0; i<nominationsToAdd; i++)
		{
			GetArrayString(g_NominateList, i, map, sizeof(map));
			GetMapTag(map);
			char mapmod[128];
			Format(mapmod,sizeof(mapmod),"%s (%s)",map,maptag);
			if (g_Cvar_UseDialogs.BoolValue)
			{
				PushArrayString(g_ActiveVotesList,map);
				Format(szInt,sizeof(szInt),"%i",i+1);
				KvJumpToKey(gKV, szInt, true);
				KvSetString(gKV, "msg", mapmod);
				Format(szDesc,sizeof(szDesc),"sm_mapchooservote %i",i+1);
				KvSetString(gKV, "command", szDesc);
				KvRewind(gKV);
			}
			else g_VoteMenu.AddItem(map, mapmod);
			RemoveStringFromArray(g_NextMapList, map);
			
			/* Notify Nominations that this map is now free */
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(map);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();
		}
		
		/* Clear out the rest of the nominations array */
		for (new i=nominationsToAdd; i<nominateCount; i++)
		{
			GetArrayString(g_NominateList, i, map, sizeof(map));
			/* These maps shouldn't be excluded from the vote as they weren't really nominated at all */
			
			/* Notify Nominations that this map is now free */
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(map);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();			
		}
		
		/* There should currently be 'nominationsToAdd' unique maps in the vote */
		
		new i = nominationsToAdd;
		new count = 0;
		new availableMaps = GetArraySize(g_NextMapList);
		
		while (i < voteSize)
		{
			if (count >= availableMaps)
			{
				//Run out of maps, this will have to do.
				break;
			}
			
			GetArrayString(g_NextMapList, count, map, sizeof(map));
			count++;
			
			/* Insert the map and increment our count */
			GetMapTag(map);
			char mapmod[128];
			Format(mapmod,sizeof(mapmod),"%s (%s)",map,maptag);
			if (g_Cvar_UseDialogs.BoolValue)
			{
				PushArrayString(g_ActiveVotesList,map);
				Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
				KvJumpToKey(gKV, szInt, true);
				KvSetString(gKV, "msg", mapmod);
				Format(szDesc,sizeof(szDesc),"sm_mapchooservote %i",i+1);
				KvSetString(gKV, "command", szDesc);
				KvRewind(gKV);
			}
			else g_VoteMenu.AddItem(map, mapmod);
			i++;
		}
		
		/* Wipe out our nominations list - Nominations have already been informed of this */
		ClearArray(g_NominateOwners);
		ClearArray(g_NominateList);
	}
	else //We were given a list of maps to start the vote with
	{
		new size = GetArraySize(inputlist);

		for (new i=0; i<size; i++)
		{
			GetArrayString(inputlist, i, map, sizeof(map));
			
			//if (IsMapValid(map))
			//{
			GetMapTag(map);
			char mapmod[128];
			Format(mapmod,sizeof(mapmod),"%s (%s)",map,maptag);
			if (g_Cvar_UseDialogs.BoolValue)
			{
				PushArrayString(g_ActiveVotesList,map);
				Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
				KvJumpToKey(gKV, szInt, true);
				KvSetString(gKV, "msg", mapmod);
				Format(szDesc,sizeof(szDesc),"sm_mapchooservote %i",i+1);
				KvSetString(gKV, "command", szDesc);
				KvRewind(gKV);
			}
			else g_VoteMenu.AddItem(map, mapmod);
			//}	
		}
	}
	
	/* Do we add any special items? */
	if ((when == MapChange_Instant || when == MapChange_RoundEnd) && g_Cvar_DontChange.BoolValue)
	{
		if (g_Cvar_UseDialogs.BoolValue)
		{
			Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
			KvJumpToKey(gKV, szInt, true);
			KvSetString(gKV, "msg", "Don't Change");
			Format(szDesc,sizeof(szDesc),"sm_mapchooservote nochange");
			KvSetString(gKV, "command", szDesc);
			KvRewind(gKV);
		}
		else g_VoteMenu.AddItem(VOTE_DONTCHANGE, "Don't Change");
	}
	else if (g_Cvar_Extend.BoolValue && g_Extends < g_Cvar_Extend.IntValue)
	{
		if (g_Cvar_UseDialogs.BoolValue)
		{
			Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
			KvJumpToKey(gKV, szInt, true);
			KvSetString(gKV, "msg", "Extend Map");
			Format(szDesc,sizeof(szDesc),"sm_mapchooservote extend");
			KvSetString(gKV, "command", szDesc);
			KvRewind(gKV);
		}
		else g_VoteMenu.AddItem(VOTE_EXTEND, "Extend Map");
	}
	
	if (!g_Cvar_UseDialogs.BoolValue)
	{
		/* There are no maps we could vote for. Don't show anything. */
		if (g_VoteMenu.ItemCount == 0)
		{
			g_HasVoteStarted = false;
			delete g_VoteMenu;
			g_VoteMenu = null;
			return;
		}
	}
	
	int voteDuration = g_Cvar_VoteDuration.IntValue;

	if (g_Cvar_UseDialogs.BoolValue)
	{
		g_HasVoteStarted = true;
		for (int i = 1;i<12;i++)
		{
			g_VoteInts[i] = 0;
		}
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsClientConnected(i))
			{
				if (IsClientInGame(i))
				{
					if (!IsFakeClient(i))
					{
						CreateDialog(i, gKV, DialogType_Menu);
					}
				}
			}
		}
		CreateTimer(g_Cvar_VoteDuration.FloatValue,EndVoteDialogs,_,TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_VoteMenu.ExitButton = false;
		g_VoteMenu.DisplayVoteToAll(voteDuration);
	}
	CloseHandle(gKV);

	LogAction(-1, -1, "Voting for next map has started.");
	PrintToChatAll("[SM] %t", "Nextmap Voting Started");
	if (g_Cvar_UseDialogs.BoolValue) PrintToChatAll("[SM] Press Esc to vote");
}

public Action EndVoteDialogs(Handle timer)
{
	if (!g_HasVoteStarted) return Plugin_Handled;
	g_HasVoteStarted = false;
	int iHighestVote = -1;
	int totalvotes = 0;
	for (int i = 1;i<12;i++)
	{
		if (g_VoteInts[i] > iHighestVote) iHighestVote = i;
		totalvotes+=g_VoteInts[i];
	}
	if (iHighestVote < 1)
	{
		LogAction(-1, -1, "Vote ended with no votes.");
		return Plugin_Handled;
	}
	if (iHighestVote == 10)
	{
		// Vote Extended
		g_Extends++;
		
		int time;
		if (GetMapTimeLimit(time))
		{
			if (time > 0)
			{
				ExtendMapTimeLimit(g_Cvar_ExtendTimeStep.IntValue * 60);						
			}
		}
		
		if (g_Cvar_Winlimit)
		{
			int winlimit = g_Cvar_Winlimit.IntValue;
			if (winlimit)
			{
				g_Cvar_Winlimit.IntValue = winlimit + g_Cvar_ExtendRoundStep.IntValue;
			}					
		}
		
		if (g_Cvar_Maxrounds)
		{
			new maxrounds = g_Cvar_Maxrounds.IntValue;
			if (maxrounds)
			{
				g_Cvar_Maxrounds.IntValue = maxrounds + g_Cvar_ExtendRoundStep.IntValue;
			}
		}
		
		if (g_Cvar_Fraglimit)
		{
			int fraglimit = g_Cvar_Fraglimit.IntValue;
			if (fraglimit)
			{
				g_Cvar_Fraglimit.IntValue = fraglimit + g_Cvar_ExtendFragStep.IntValue;
			}
		}

		PrintToChatAll("[SM] %t", "Current Map Extended", RoundToFloor(float(g_VoteInts[iHighestVote])/float(totalvotes)*100), totalvotes);
		LogAction(-1, -1, "Voting for next map has finished. The current map has been extended.");
		
		// We extended, so we'll have to vote again.
		g_HasVoteStarted = false;
		CreateNextVote();
		SetupTimeleftTimer();
	}
	else if (iHighestVote == 11)
	{
		// Vote Dont change
		PrintToChatAll("[SM] %t", "Current Map Stays", RoundToFloor(float(g_VoteInts[iHighestVote])/float(totalvotes)*100), totalvotes);
		LogAction(-1, -1, "Voting for next map has finished. 'No Change' was the winner");
		char clsnam[32] = "trigger_changelevel";
		char clsnami[16] = "info_landmark";
		for (new i = 0;i<10240;i++)
		{
			if (IsValidEntity(i))
			{
				new thisent = FindEntityByClassname(i, clsnam);
				new thatent = FindEntityByClassname(i, clsnami);
				if (thisent > 0)
				{
					AcceptEntityInput(thisent, "enable");
				}
				if (thatent > 0)
				{
					AcceptEntityInput(thatent, "enable");
				}
			}
		}
		g_HasVoteStarted = false;
		CreateNextVote();
		SetupTimeleftTimer();
	}
	else if (iHighestVote-1 < GetArraySize(g_ActiveVotesList))
	{
		char map[PLATFORM_MAX_PATH];
		GetArrayString(g_ActiveVotesList,iHighestVote-1,map,sizeof(map));
		if (strlen(map) > 0)
		{
			if (g_ChangeTime == MapChange_MapEnd)
			{
				//SetNextMap(map);
			}
			else if (g_ChangeTime == MapChange_Instant)
			{
				Handle data;
				CreateDataTimer(2.0, Timer_ChangeMap, data);
				WritePackString(data, map);
				g_ChangeMapInProgress = false;
			}
			else // MapChange_RoundEnd
			{
				//SetNextMap(map);
				g_ChangeMapAtRoundEnd = true;
			}
			
			g_HasVoteStarted = false;
			g_MapVoteCompleted = true;
			
			PrintToChatAll("[SM] %t", "Nextmap Voting Finished", map, RoundToFloor(float(g_VoteInts[iHighestVote])/float(totalvotes)*100), totalvotes);
			LogAction(-1, -1, "Voting for next map has finished. Nextmap: %s.", map);
		}
	}
	return Plugin_Handled;
}

public Handler_VoteFinishedGeneric(Menu menu,
						   num_votes, 
						   num_clients,
						   const client_info[][2], 
						   num_items,
						   const item_info[][2])
{
	char map[PLATFORM_MAX_PATH];
	menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], map, sizeof(map));

	if (strcmp(map, VOTE_EXTEND, false) == 0)
	{
		g_Extends++;
		
		int time;
		if (GetMapTimeLimit(time))
		{
			if (time > 0)
			{
				ExtendMapTimeLimit(g_Cvar_ExtendTimeStep.IntValue * 60);						
			}
		}
		
		if (g_Cvar_Winlimit)
		{
			int winlimit = g_Cvar_Winlimit.IntValue;
			if (winlimit)
			{
				g_Cvar_Winlimit.IntValue = winlimit + g_Cvar_ExtendRoundStep.IntValue;
			}					
		}
		
		if (g_Cvar_Maxrounds)
		{
			new maxrounds = g_Cvar_Maxrounds.IntValue;
			if (maxrounds)
			{
				g_Cvar_Maxrounds.IntValue = maxrounds + g_Cvar_ExtendRoundStep.IntValue;
			}
		}
		
		if (g_Cvar_Fraglimit)
		{
			int fraglimit = g_Cvar_Fraglimit.IntValue;
			if (fraglimit)
			{
				g_Cvar_Fraglimit.IntValue = fraglimit + g_Cvar_ExtendFragStep.IntValue;
			}
		}

		PrintToChatAll("[SM] %t", "Current Map Extended", RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES])/float(num_votes)*100), num_votes);
		LogAction(-1, -1, "Voting for next map has finished. The current map has been extended.");
		
		// We extended, so we'll have to vote again.
		g_HasVoteStarted = false;
		CreateNextVote();
		SetupTimeleftTimer();
		
	}
	else if (strcmp(map, VOTE_DONTCHANGE, false) == 0)
	{
		PrintToChatAll("[SM] %t", "Current Map Stays", RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES])/float(num_votes)*100), num_votes);
		LogAction(-1, -1, "Voting for next map has finished. 'No Change' was the winner");
		char clsnam[32] = "trigger_changelevel";
		char clsnami[16] = "info_landmark";
		for (new i = 0;i<10240;i++)
		{
			if (IsValidEntity(i))
			{
				new thisent = FindEntityByClassname(i, clsnam);
				new thatent = FindEntityByClassname(i, clsnami);
				if (thisent > 0)
				{
					AcceptEntityInput(thisent, "enable");
				}
				if (thatent > 0)
				{
					AcceptEntityInput(thatent, "enable");
				}
			}
		}
		g_HasVoteStarted = false;
		CreateNextVote();
		SetupTimeleftTimer();
	}
	else
	{
		if (g_ChangeTime == MapChange_MapEnd)
		{
			//SetNextMap(map);
		}
		else if (g_ChangeTime == MapChange_Instant)
		{
			Handle data;
			CreateDataTimer(2.0, Timer_ChangeMap, data);
			WritePackString(data, map);
			g_ChangeMapInProgress = false;
		}
		else // MapChange_RoundEnd
		{
			//SetNextMap(map);
			g_ChangeMapAtRoundEnd = true;
		}
		
		g_HasVoteStarted = false;
		g_MapVoteCompleted = true;
		/*
		char clsnam[32] = "trigger_changelevel";
		char clsnami[16] = "info_landmark";
		for (new i = 0;i<10240;i++)
		{
			if (IsValidEntity(i))
			{
				new thisent = FindEntityByClassname(i, clsnam);
				new thatent = FindEntityByClassname(i, clsnami);
				if (thisent > 0)
				{
					AcceptEntityInput(thisent, "kill");
				}
				if (thatent > 0)
				{
					AcceptEntityInput(thatent, "kill");
				}
			}
		}
		*/
		PrintToChatAll("[SM] %t", "Nextmap Voting Finished", map, RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES])/float(num_votes)*100), num_votes);
		LogAction(-1, -1, "Voting for next map has finished. Nextmap: %s.", map);
	}	
}

public Handler_MapVoteFinished(Menu menu,
						   int num_votes, 
						   int num_clients,
						   const client_info[][2], 
						   int num_items,
						   const item_info[][2])
{
	if (g_Cvar_RunOff.BoolValue && num_items > 1)
	{
		float winningvotes = float(item_info[0][VOTEINFO_ITEM_VOTES]);
		float required = num_votes * (g_Cvar_RunOffPercent.FloatValue / 100.0);
		
		if (winningvotes < required)
		{
			/* Insufficient Winning margin - Lets do a runoff */
			g_VoteMenu = CreateMenu(Handler_MapVoteMenu, MenuAction:MENU_ACTIONS_ALL);
			g_VoteMenu.SetTitle("Runoff Vote Nextmap");
			SetVoteResultCallback(g_VoteMenu, Handler_VoteFinishedGeneric);

			char map[PLATFORM_MAX_PATH];
			char info1[PLATFORM_MAX_PATH];
			char info2[PLATFORM_MAX_PATH];
			
			menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], map, sizeof(map), _, info1, sizeof(info1));
			g_VoteMenu.AddItem(map, info1);
			menu.GetItem(item_info[1][VOTEINFO_ITEM_INDEX], map, sizeof(map), _, info2, sizeof(info2));
			g_VoteMenu.AddItem(map, info2);
			
			int voteDuration = g_Cvar_VoteDuration.IntValue;
			g_VoteMenu.ExitButton = false;
			g_VoteMenu.DisplayVoteToAll(voteDuration);
			
			/* Notify */
			float map1percent = float(item_info[0][VOTEINFO_ITEM_VOTES])/ float(num_votes) * 100;
			float map2percent = float(item_info[1][VOTEINFO_ITEM_VOTES])/ float(num_votes) * 100;
			
			
			PrintToChatAll("[SM] %t", "Starting Runoff", g_Cvar_RunOffPercent.FloatValue, info1, map1percent, info2, map2percent);
			LogMessage("Voting for next map was indecisive, beginning runoff vote");
					
			return;
		}
	}
	
	Handler_VoteFinishedGeneric(menu, num_votes, num_clients, client_info, num_items, item_info);
}

public Handler_MapVoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			g_VoteMenu = null;
			delete menu;
		}
		
		case MenuAction_Display:
		{
	 		decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%T", "Vote Nextmap", param1);

			Panel panel = Panel:param2;
			panel.SetTitle(buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			if (menu.ItemCount - 1 == param2)
			{
				char map[PLATFORM_MAX_PATH], buffer[255];
				GetMapTag(map);
				Format(map,sizeof(map),"%s (%s)",map,maptag);
				menu.GetItem(param2, map, sizeof(map));
				if (strcmp(map, VOTE_EXTEND, false) == 0)
				{
					Format(buffer, sizeof(buffer), "%T", "Extend Map", param1);
					return RedrawMenuItem(buffer);
				}
				else if (strcmp(map, VOTE_DONTCHANGE, false) == 0)
				{
					Format(buffer, sizeof(buffer), "%T", "Dont Change", param1);
					return RedrawMenuItem(buffer);
				}
			}
		}		
	
		case MenuAction_VoteCancel:
		{
			// If we receive 0 votes, pick at random.
			if (param1 == VoteCancel_NoVotes && g_Cvar_NoVoteMode.BoolValue)
			{
				new count = menu.ItemCount;
				decl String:map[PLATFORM_MAX_PATH];
				menu.GetItem(0, map, sizeof(map));
				
				// Make sure the first map in the menu isn't one of the special items.
				// This would mean there are no real maps in the menu, because the special items are added after all maps. Don't do anything if that's the case.
				if (strcmp(map, VOTE_EXTEND, false) != 0 && strcmp(map, VOTE_DONTCHANGE, false) != 0)
				{
					// Get a random map from the list.
					new item = GetRandomInt(0, count - 1);
					menu.GetItem(item, map, sizeof(map));
					
					// Make sure it's not one of the special items.
					while (strcmp(map, VOTE_EXTEND, false) == 0 || strcmp(map, VOTE_DONTCHANGE, false) == 0)
					{
						item = GetRandomInt(0, count - 1);
						menu.GetItem(item, map, sizeof(map));
					}
					
					//SetNextMap(map);
					g_MapVoteCompleted = true;
				}
			}
			else
			{
				// We were actually cancelled. I guess we do nothing.
			}
			
			g_HasVoteStarted = false;
		}
	}
	
	return 0;
}

public Action Timer_ChangeMap(Handle hTimer, Handle dp)
{
	g_ChangeMapInProgress = false;
	
	char map[PLATFORM_MAX_PATH];
	
	if (dp == null)
	{
		if (!GetNextMap(map, sizeof(map)))
		{
			//No passed map and no set nextmap. fail!
			return Plugin_Stop;	
		}
	}
	else
	{
		ResetPack(dp);
		ReadPackString(dp, map, sizeof(map));		
	}
	

	if (mapchangeinprogress)
	{
		PrintToChatAll("Map change prevented due to map change already in progress.");
		return Plugin_Handled;
	}
	
	if (StrContains(map, " gamemode ", false) != -1)
	{
		char tmpexpl[4][64];
		ExplodeString(map, " gamemode ", tmpexpl, 2, 64);
		Format(map, sizeof(map), "%s", tmpexpl[0]);
		
		TrimString(tmpexpl[1]);
		if (strlen(tmpexpl[1]) > 0)
		{
			ConVar hCVar = FindConVar("edtprefix");
			if (hCVar != INVALID_HANDLE)
			{
				hCVar.SetString(tmpexpl[1]);
				CloseHandle(hCVar);
			}
		}
	}
	
	char mapch[128];
	ServerCommand("changelevel %s", map);
	if (bSynAct)
	{
		Format(mapch,sizeof(mapch),"Custom %s",map);
		ServerCommand("changelevel %s", mapch);
		Format(mapch,sizeof(mapch),"syn %s",map);
		ServerCommand("changelevel %s", mapch);
		LogMessage("Mapchange to %s", mapch);
		Format(mapch,sizeof(mapch),"ep1 %s",map);
		ServerCommand("changelevel %s", mapch);
		Format(mapch,sizeof(mapch),"ep2 %s",map);
		ServerCommand("changelevel %s", mapch);
		Format(mapch,sizeof(mapch),"custom %s",map);
		ServerCommand("changelevel %s", mapch);
	}
	mapchangeinprogress = false;
	return Plugin_Stop;
}

bool:RemoveStringFromArray(Handle:array, String:str[])
{
	new index = FindStringInArray(array, str);
	if (index != -1)
	{
		RemoveFromArray(array, index);
		return true;
	}
	
	return false;
}

CreateNextVote()
{
	ClearArray(g_NextMapList);
	
	char map[PLATFORM_MAX_PATH];
	Handle tempMaps  = CloneArray(g_MapList);
	
	GetCurrentMap(map, sizeof(map));
	RemoveStringFromArray(tempMaps, map);
	
	if (g_Cvar_ExcludeMaps.IntValue && GetArraySize(tempMaps) > g_Cvar_ExcludeMaps.IntValue)
	{
		for (int i = 0; i < GetArraySize(g_OldMapList); i++)
		{
			GetArrayString(g_OldMapList, i, map, sizeof(map));
			RemoveStringFromArray(tempMaps, map);
		}
	}

	int limit = (g_Cvar_IncludeMaps.IntValue < GetArraySize(tempMaps) ? g_Cvar_IncludeMaps.IntValue : GetArraySize(tempMaps));
	for (int i = 0; i < limit; i++)
	{
		int b = GetRandomInt(0, GetArraySize(tempMaps) - 1);
		GetArrayString(tempMaps, b, map, sizeof(map));
		if (bSynAct)
		{
			if (StrContains(map,"d1_town_0",false) == 0) Format(map,sizeof(map),"d1_town_01");
			else if (StrContains(map,"d1_canals_",false) == 0) Format(map,sizeof(map),"d1_canals_01");
			else if (StrContains(map,"d1_trainstation_06",false) == 0) Format(map,sizeof(map),"d1_trainstation_06");
			else if (StrContains(map,"d1_trainstation_0",false) == 0) Format(map,sizeof(map),"d1_trainstation_01");
			else if (StrContains(map,"d2_coast_0",false) == 0) Format(map,sizeof(map),"d2_coast_01");
			else if (StrContains(map,"d2_prison_0",false) == 0) Format(map,sizeof(map),"d2_prison_01");
			else if (StrContains(map,"d3_c17_",false) == 0) Format(map,sizeof(map),"d3_c17_01");
			else if (StrContains(map,"bm_c",false) != -1) Format(map,sizeof(map),"d1_town_01");
			//else if (StrContains(map,"bm_c",false) == 0) Format(map,sizeof(map),"bm_c0a0a");
			else if (StrContains(map,"xen_c",false) == 0) Format(map,sizeof(map),"d1_town_01");
			//else if (StrContains(map,"xen_c",false) == 0) Format(map,sizeof(map),"xen_c4a1");
			else if (StrContains(map,"ravenholm",false) == 0) Format(map,sizeof(map),"Ravenholm00");
			else if (StrContains(map,"cd",false) == 0) Format(map,sizeof(map),"cd0");
			else if (StrContains(map,"ce_0",false) == 0) Format(map,sizeof(map),"ce_01");
			else if (StrContains(map,"bonus_earlyprison_0",false) == 0) Format(map,sizeof(map),"bonus_earlyprison_01");
			else if (StrContains(map,"leonHL2-",false) == 0) Format(map,sizeof(map),"leonHL2-2");
			else if (StrContains(map,"lifelostprison_0",false) == 0) Format(map,sizeof(map),"lifelostprison_01");
			else if (StrContains(map,"metastasis_",false) == 0) Format(map,sizeof(map),"metastasis_1");
			else if (StrContains(map,"mimp",false) == 0) Format(map,sizeof(map),"d2_coast_01");
			//else if (StrContains(map,"mimp",false) == 0) Format(map,sizeof(map),"mimp1");
			else if ((StrContains(map,"mine_01_",false) == 0) || (StrContains(map,"mine01_",false) == 0)) Format(map,sizeof(map),"d2_prison_01");
			//else if ((StrContains(map,"mine_01_",false) == 0) || (StrContains(map,"mine01_",false) == 0)) Format(map,sizeof(map),"mine_01_00");
			else if (StrContains(map,"mpr_0",false) == 0) Format(map,sizeof(map),"mpr_010_arrival");
			else if (StrContains(map,"penetration0",false) == 0) Format(map,sizeof(map),"ep1_citadel_00");
			//else if (StrContains(map,"penetration0",false) == 0) Format(map,sizeof(map),"Penetration01");
			else if (StrContains(map,"po_map",false) == 0) Format(map,sizeof(map),"po_map1");
			else if (StrContains(map,"ptsd_",false) == 0) Format(map,sizeof(map),"d2_coast_01");
			//else if (StrContains(map,"ptsd_festive_",false) == 0) Format(map,sizeof(map),"ptsd_festive_1");
			//else if (StrContains(map,"ptsd_",false) == 0) Format(map,sizeof(map),"ptsd_1");
			else if (StrContains(map,"r_map",false) == 0) Format(map,sizeof(map),"r_map1");
			else if (StrContains(map,"ra_c1l",false) == 0) Format(map,sizeof(map),"ra_c1l1");
			else if (StrContains(map,"sh_alchemilla",false) == 0) Format(map,sizeof(map),"sh_alchemilla");
			else if (StrContains(map,"slums_",false) == 0) Format(map,sizeof(map),"slums_1");
			else if ((StrContains(map,"sn_level0",false) == 0) || (StrEqual(map,"sn_outro",false))) Format(map,sizeof(map),"sn_level01a");
			else if (StrContains(map,"sp_c14_",false) == 0) Format(map,sizeof(map),"sp_c14_1");
			else if (StrContains(map,"up_",false) == 0) Format(map,sizeof(map),"up_retreat_a");
			else if (StrContains(map,"uw_",false) == 0) Format(map,sizeof(map),"uw_1");
			else if (StrContains(map,"dw_ep1_",false) == 0) Format(map,sizeof(map),"dw_ep1_00");
			else if (StrContains(map,"ep2_deepdown_",false) == 0) Format(map,sizeof(map),"ep2_deepdown_1");
			else if (StrContains(map,"islandunderground",false) == 0) Format(map,sizeof(map),"islandunderground");
			else if (StrContains(map,"islandplant",false) == 0) Format(map,sizeof(map),"islandplant");
			else if (StrContains(map,"islandbuggy",false) == 0) Format(map,sizeof(map),"islandbuggy");
			else if (StrContains(map,"islandcove",false) == 0) Format(map,sizeof(map),"islandcove");
			else if (StrContains(map,"island",false) == 0) Format(map,sizeof(map),"islandescape");
			else if (StrContains(map,"spymap_ep3",false) != -1) Format(map,sizeof(map),"ep2_outland_01");
			else if (StrContains(map,"lwr",false) == 0) Format(map,sizeof(map),"ep1_citadel_00");
			else if ((StrContains(map,"dayhardpart",false) == 0) || (StrEqual(map,"redrum",false)) || (StrEqual(map,"breencave",false)) || (StrEqual(map,"Finale",false)) || (StrEqual(map,"voyage",false))) Format(map,sizeof(map),"d1_trainstation_01");
			//else if ((StrContains(map,"dayhardpart",false) == 0) || (StrEqual(map,"redrum",false)) || (StrEqual(map,"breencave",false)) || (StrEqual(map,"Finale",false)) || (StrEqual(map,"voyage",false))) Format(map,sizeof(map),"dayhardpart1");
		}
		PushArrayString(g_NextMapList, map);
		RemoveFromArray(tempMaps, b);
	}
	
	delete tempMaps;
}

bool:CanVoteStart()
{
	if (g_WaitingForVote || g_HasVoteStarted)
	{
		return false;	
	}
	
	return true;
}

NominateResult:InternalNominateMap(String:map[], bool:force, owner)
{
	/*
	if (!IsMapValid(map))
	{
		return Nominate_InvalidMap;
	}
	*/
	
	/* Map already in the vote */
	if (FindStringInArray(g_NominateList, map) != -1)
	{
		return Nominate_AlreadyInVote;	
	}
	
	new index;

	/* Look to replace an existing nomination by this client - Nominations made with owner = 0 aren't replaced */
	if (owner && ((index = FindValueInArray(g_NominateOwners, owner)) != -1))
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, index, oldmap, sizeof(oldmap));
		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(owner);
		Call_Finish();
		
		SetArrayString(g_NominateList, index, map);
		return Nominate_Replaced;
	}
	
	/* Too many nominated maps. */
	if (GetArraySize(g_NominateList) >= g_Cvar_IncludeMaps.IntValue && !force)
	{
		return Nominate_VoteFull;
	}
	
	PushArrayString(g_NominateList, map);
	PushArrayCell(g_NominateOwners, owner);
	
	while (GetArraySize(g_NominateList) > g_Cvar_IncludeMaps.IntValue)
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, 0, oldmap, sizeof(oldmap));
		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(GetArrayCell(g_NominateOwners, 0));
		Call_Finish();
		
		RemoveFromArray(g_NominateList, 0);
		RemoveFromArray(g_NominateOwners, 0);
	}
	
	return Nominate_Added;
}

/* Add natives to allow nominate and initiate vote to be call */

/* native  bool:NominateMap(const String:map[], bool:force, &NominateError:error); */
public Native_NominateMap(Handle plugin, int numParams)
{
	int len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
	{
	  return false;
	}
	
	char map[PLATFORM_MAX_PATH];
	GetNativeString(1, map, len+1);
	
	return _:InternalNominateMap(map, GetNativeCell(2), GetNativeCell(3));
}

bool InternalRemoveNominationByMap(String:map[])
{	
	for (new i = 0; i < GetArraySize(g_NominateList); i++)
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, i, oldmap, sizeof(oldmap));

		if(strcmp(map, oldmap, false) == 0)
		{
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(oldmap);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();

			RemoveFromArray(g_NominateList, i);
			RemoveFromArray(g_NominateOwners, i);

			return true;
		}
	}
	
	return false;
}

/* native  bool:RemoveNominationByMap(const String:map[]); */
public Native_RemoveNominationByMap(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
	{
	  return false;
	}
	
	char map[PLATFORM_MAX_PATH];//len+1
	GetNativeString(1, map, len+1);
	
	return _:InternalRemoveNominationByMap(map);
}

bool:InternalRemoveNominationByOwner(owner)
{	
	new index;

	if (owner && ((index = FindValueInArray(g_NominateOwners, owner)) != -1))
	{
		char oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, index, oldmap, sizeof(oldmap));

		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(owner);
		Call_Finish();

		RemoveFromArray(g_NominateList, index);
		RemoveFromArray(g_NominateOwners, index);

		return true;
	}
	
	return false;
}

/* native  bool:RemoveNominationByOwner(owner); */
public Native_RemoveNominationByOwner(Handle:plugin, numParams)
{	
	return _:InternalRemoveNominationByOwner(GetNativeCell(1));
}

/* native InitiateMapChooserVote(); */
public Native_InitiateVote(Handle:plugin, numParams)
{
	new MapChange:when = MapChange:GetNativeCell(1);
	Handle inputarray = Handle:GetNativeCell(2);
	
	LogAction(-1, -1, "Starting map vote because outside request");
	InitiateVote(when, inputarray);
}

public Native_CanVoteStart(Handle:plugin, numParams)
{
	return CanVoteStart();	
}

public Native_CheckVoteDone(Handle:plugin, numParams)
{
	return g_MapVoteCompleted;
}

public Native_EndOfMapVoteEnabled(Handle:plugin, numParams)
{
	return g_Cvar_EndOfMapVote.BoolValue;
}

public Native_GetExcludeMapList(Handle:plugin, numParams)
{
	Handle array = Handle:GetNativeCell(1);
	
	if (array == null)
	{
		return;	
	}
	new size = GetArraySize(g_OldMapList);
	decl String:map[PLATFORM_MAX_PATH];
	
	for (new i=0; i<size; i++)
	{
		GetArrayString(g_OldMapList, i, map, sizeof(map));
		PushArrayString(array, map);	
	}
	
	return;
}

public Native_GetNominatedMapList(Handle:plugin, numParams)
{
	Handle maparray = Handle:GetNativeCell(1);
	Handle ownerarray = Handle:GetNativeCell(2);
	
	if (maparray == null)
		return;

	decl String:map[PLATFORM_MAX_PATH];

	for (new i = 0; i < GetArraySize(g_NominateList); i++)
	{
		GetArrayString(g_NominateList, i, map, sizeof(map));
		PushArrayString(maparray, map);

		// If the optional parameter for an owner list was passed, then we need to fill that out as well
		if(ownerarray != null)
		{
			new index = GetArrayCell(g_NominateOwners, i);
			PushArrayCell(ownerarray, index);
		}
	}

	return;
}

public Action GetMapTag(const char[] map)
{
	if ((StrContains(map,"rock24 d",false) == 0) || (StrEqual(map,"d1_overboard_01",false)) || (StrEqual(map,"d1_wakeupcall_02",false)) || (StrEqual(map,"d2_breakout_03",false)) || (StrEqual(map,"d2_surfacing_04",false)) || (StrEqual(map,"d3_theescape_05",false)) || (StrEqual(map,"d3_extraction_06",false)))
	{
		Format(maptag, sizeof(maptag), "Rock 24");
	}
	else if (StrContains(map, "d1_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Half-Life 2");
	}
	else if (StrContains(map, "d2_lostcoast", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Lost Coast");
	}
	else if ((StrContains(map, "d2_", false) == 0) || (StrContains(map, "d3_", false) == 0) || (StrContains(map, "hl2 ",false) == 0))
	{
		Format(maptag, sizeof(maptag), "Half-Life 2");
	}
	else if (StrContains(map, "hl2u ", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Half-Life 2 Update");
	}
	else if ((StrContains(map, "c0a0", false) == 0) || (StrContains(map, "c1a", false) == 0) || (StrContains(map, "c2a", false) == 0) || (StrContains(map, "c3a", false) == 0) || (StrContains(map, "c4a", false) == 0) || (StrEqual(map, "c5a1", false)))
	{
		Format(maptag, sizeof(maptag), "Half-Life 1");
	}
	else if ((StrContains(map, "hls", false) == 0) && (StrContains(map, "mrl", false) != -1))
	{
		Format(maptag, sizeof(maptag), "Half-Life 1 Merged");
	}
	else if (StrContains(map, "ep1", false) == 0)
	{
		Format(maptag, sizeof(maptag), "HL2: Episode 1");
	}
	else if (StrContains(map, "ep2_outland_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "HL2: Episode 2");
	}
	else if ((StrContains(map, "metastasis", false) == 0) || (StrContains(map, "meta metastasis", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Minerva");
	}
	else if ((StrContains(map, "sp_c14_", false) == 0) || (StrContains(map, "cal sp_c14_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Calamity");
	}
	else if ((StrContains(map, "cit2 sp", false) == 0) || (StrEqual(map, "sp_canal1", false)) || (StrEqual(map, "sp_canal2", false)) || (StrEqual(map, "sp_base", false)) || (StrEqual(map, "sp_canyon", false)) || (StrEqual(map, "sp_casino", false)) || (StrEqual(map, "sp_casino2", false)) || (StrEqual(map, "sp_ending", false)) || (StrEqual(map, "sp_intro", false)) || (StrEqual(map, "sp_postsquare", false)) || (StrEqual(map, "sp_precasino", false)) || (StrEqual(map, "sp_presquare", false)) || (StrEqual(map, "sp_square", false)) || (StrContains(map, "sp_streetwar", false) == 0) || (StrEqual(map, "sp_waterplant", false)) || (StrEqual(map, "sp_waterplant2", false)))
	{
		Format(maptag, sizeof(maptag), "The Citizen Returns");
	}
	else if ((StrContains(map, "shuter_st_f", false) == 0) || (StrContains(map, "st_michaels_", false) == 0) || (StrContains(map, "yonge_st_f", false) == 0) || (StrContains(map, "dundas_square_f", false) == 0) || (StrContains(map, "subway_system_f", false) == 0) || (StrContains(map, "mel_lastman_square_f", false) == 0))
	{
		Format(maptag, sizeof(maptag), "City 7: Toronto Conflict");
	}
	else if ((StrContains(map, "up_", false) == 0) || (StrContains(map, "up up_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Uncertainty Principle");
	}
	else if ((StrContains(map, "ra_c1l", false) == 0) || (StrContains(map, "riotact ra_c1l", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Riot Act");
	}
	else if ((StrContains(map, "dw_", false) == 0) || (StrContains(map, "dworld dw", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Dangerous World");
	}
	else if ((StrContains(map, "r_map", false) == 0) || (StrContains(map, "pre r_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Precursor");
	}
	else if ((StrContains(map, "leonhl2-2", false) == 0) || (StrContains(map, "final_credits", false) == 0) || (StrContains(map, "ctoa leonHL2", false) == 0) || (StrContains(map, "ctoa final", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Coastline To Atmosphere");
	}
	else if (StrContains(map, "spymap_ep3", false) != -1)
	{
		Format(maptag, sizeof(maptag), "Episode 3: The Closure");
	}
	else if ((StrContains(map, "island", false) == 0) || (StrContains(map, "offshore island", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Offshore");
	}
	else if (StrContains(map, "level_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Research & Development");
	}
	else if (StrContains(map, "cd", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Combine Destiny");
	}
	else if (StrContains(map, "nt_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Neotokyo");
	}
	else if ((StrContains(map, "po_", false) == 0) || (StrContains(map, "op po_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Omega Prison");
	}
	else if ((StrContains(map, "mimp", false) == 0) || (StrContains(map, "mi mimp", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Mission Improbable");
	}
	else if (StrContains(map, "_sm_", false) != -1)
	{
		Format(maptag, sizeof(maptag), "Strider Mountain");
	}
	else if ((StrContains(map, "slums_", false) == 0) || (StrContains(map, "s2e slums_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Slums 2: Extended");
	}
	else if ((StrEqual(map, "ravenholmlc1", false)) || (StrContains(map, "rhlc raven", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Ravenholm: The Lost Chapter");
	}
	else if ((StrContains(map, "ravenholm", false) == 0) || (StrContains(map, "rh ravenholm", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Ravenholm");
	}
	else if (StrContains(map, "sn_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Spherical Nightmares");
	}
	else if ((StrContains(map, "ks_mop_", false) == 0) || (StrContains(map, "mop ks_mop_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Mistake of Pythagoras");
	}
	else if ((StrContains(map, "ce_0", false) == 0) || (StrContains(map, "ce ce_0", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Causality Effect");
	}
	else if (StrContains(map, "1187", false) == 0)
	{
		Format(maptag, sizeof(maptag), "1187");
	}
	else if ((StrContains(map, "sh_alchemilla", false) == 0) || (StrContains(map, "alc sh_alchemilla", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Alchemilla");
	}
	else if (StrContains(map, "eots_1", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Eye of The Storm");
	}
	else if ((StrContains(map, "mpr_0", false) == 0) || (StrContains(map, "mpr mpr_0", false) == 0))
	{
		Format(maptag, sizeof(maptag), "The Masked Prisoner");
	}
	else if ((StrContains(map, "belowice", false) == 0) || (StrEqual(map,"memory",false)) || (StrContains(map, "bti ", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Below The Ice");
	}
	else if ((StrContains(map, "dayhardpart", false) == 0) || (StrContains(map, "dh ", false) == 0) || (StrEqual(map,"dayhard_menu",false)) || (StrEqual(map,"voyage",false)) || (StrEqual(map,"redrum",false)) || (StrEqual(map,"finale",false)) || (StrEqual(map,"breencave",false)) || (StrEqual(map,"dojo",false)))
	{
		Format(maptag, sizeof(maptag), "Day Hard");
	}
	else if ((StrEqual(map,"brighe",false)) || (StrEqual(map,"city-s",false)) || (StrContains(map,"mine01_0",false) == 0) || (StrContains(map,"mine_01_0",false) == 0) || (StrContains(map,"ante ",false) == 0))
	{
		Format(maptag, sizeof(maptag), "Antlions Everywhere");
	}
	else if (StrEqual(map, "intro01", false) || StrEqual(map, "intro02", false) || StrEqual(map, "mines01", false) || StrEqual(map, "mines02", false) || StrEqual(map, "sewer01", false) || StrEqual(map, "scape01", false) || StrEqual(map, "scape02", false) || StrEqual(map, "scape03", false) || StrEqual(map, "ldtd01", false) || StrEqual(map, "tull01", false) || StrEqual(map, "surreal01", false) || StrEqual(map, "outside01", false) || StrEqual(map, "ending01", false))
	{
		Format(maptag, sizeof(maptag), "Lost Under The Snow");
	}
	else if ((StrContains(map, "th_intro", false) == 0) || (StrContains(map, "drainage", false) == 0) || (StrContains(map, "church", false) == 0) || (StrContains(map, "basement", false) == 0) || (StrContains(map, "cabin", false) == 0) || (StrContains(map, "cave", false) == 0) || (StrContains(map, "rift", false) == 0) || (StrContains(map, "volcano", false) == 0) || (StrContains(map, "train", false) == 0))
	{
		Format(maptag, sizeof(maptag), "They Hunger Again");
	}
	else if (StrContains(map, "dwn0", false) == 0)
	{
		Format(maptag, sizeof(maptag), "DownFall");
	}
	else if ((StrContains(map, "Penetration0",false) == 0) || (StrContains(map, "hl2p Penetration0",false) == 0))
	{
		Format(maptag, sizeof(maptag), "HL2: Penetration");
	}
	else if (StrContains(map, "sttr_ch", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Steam Tracks Trouble and Riddles");
	}
	else if (StrContains(map, "testchmb_a_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Portal");
	}
	else if ((StrContains(map, "llp ", false) == 0) || (StrContains(map, "lifelostprison_0", false) == 0) || (StrContains(map, "bonus_earlyprison_0", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Liberation");
	}
	else if ((StrContains(map, "ep2_deepdown_", false) == 0) || (StrContains(map, "deepdown ep2_deepdown_", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Deep Down");
	}
	else if (StrContains(map, "yla_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Year Long Alarm");
	}
	else if (StrContains(map, "ktm_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Kill The Monk");
	}
	else if (StrContains(map, "t7_", false) == 0)
	{
		Format(maptag, sizeof(maptag), "Terminal 7");
	}
	else if (StrContains(map, "hc_t0",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Black Mesa: Hazard Course");
	}
	else if ((StrContains(map, "bm_c", false) == 0) || (StrContains(map, "bms ", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Black Mesa");
	}
	else if (StrContains(map,"bm_damo0",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Black Mesa: Damocles");
	}
	else if ((StrContains(map, "xen_c", false) == 0) || (StrContains(map, "bmsxen ", false) == 0))
	{
		Format(maptag, sizeof(maptag), "Black Mesa: Improved Xen");
	}
	else if (StrContains(map, "ptsd2 ", false) == 0)
	{
		Format(maptag, sizeof(maptag), "PTSD 2");
	}
	else if (StrContains(map, "ptcs ", false) == 0)
	{
		Format(maptag, sizeof(maptag), "PTSD Christmas Special");
	}
	else if ((StrContains(map, "ptsd ", false) == 0) || (StrContains(map, "ptsd_", false) == 0) || (StrEqual(map,"boneless_ptsd",false)) || (StrEqual(map,"the_end",false)))
	{
		Format(maptag, sizeof(maptag), "PTSD");
	}
	else if ((StrContains(map, "am am", false) == 0) || (StrEqual(map,"am2",false)) || (StrEqual(map,"am3",false)) || (StrEqual(map,"am4",false)))
	{
		Format(maptag, sizeof(maptag), "Aftermath");
	}
	else if (StrContains(map,"Penetration0",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Half-Life 2: Penetration");
	}
	else if (StrContains(map,"sewer",false) == 0)
	{
		Format(maptag, sizeof(maptag), "The Sewer");
	}
	else if ((StrContains(map,"az_c",false) == 0) || (StrEqual(map,"az_intro",false)))
	{
		Format(maptag, sizeof(maptag), "Entropy: Zero");
	}
	else if (StrContains(map,"oc_",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Obsidian Conflict");
	}
	else if (StrContains(map,"vektaslums0",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Killzone Source");
	}
	else if (StrContains(map,"silent_escape_map_",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Silent Escape");
	}
	else if ((StrContains(map,"Uh_Prologue_",false) == 0) || (StrContains(map,"Uh_Chapter1_",false) == 0) || (StrContains(map,"Uh_Chapter2_",false) == 0) || (StrContains(map,"Uh_House_",false) == 0) || (StrContains(map,"Uh_Dreams_",false) == 0))
	{
		Format(maptag, sizeof(maptag), "Underhell");
	}
	else if ((StrContains(map,"exesc ",false) == 0) || (StrContains(map,"escape_map_0",false) == 0))
	{
		Format(maptag, sizeof(maptag), "Escape by Ex-Mo");
	}
	else if ((StrContains(map,"hlesc ",false) == 0) || (StrEqual(map,"substation_1_d",false)) || (StrEqual(map,"canals_v1_d",false)) || (StrEqual(map,"canals_v2_d",false)) || (StrEqual(map,"railway21_d",false)))
	{
		Format(maptag, sizeof(maptag), "Half-Life Escape");
	}
	else if (StrContains(map,"avenueodessa",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Avenue Odessa");
	}
	else if ((StrContains(map,"prospekt ",false) == 0) || (StrContains(map,"pxg_level_",false) == 0))
	{
		Format(maptag, sizeof(maptag), "Prospekt");
	}
	else if ((StrContains(map,"amalgam ",false) == 0) || (StrEqual(map,"intro_1",false)) || (StrEqual(map,"sewers_1",false)) || (StrEqual(map,"coast_1",false)) || (StrEqual(map,"tunnel_1",false)) || (StrEqual(map,"beacon_1",false)))
	{
		Format(maptag, sizeof(maptag), "Amalgam");
	}
	else
	{
		if (bSynAct) Format(maptag, sizeof(maptag), "Syn");
		else if (StrEqual(gamename,"tf",false)) Format(maptag, sizeof(maptag), "TF2");
		else
		{
			gamename[0] &= ~(1 << 5);
			ReplaceString(gamename,sizeof(gamename),"_"," ",false);
			Format(maptag,sizeof(maptag),"%s",gamename);
		}
	}
}

public Action recheckchangelevels(Handle timer)
{
	if ((GetClientCount(true)) && (!mapchangeinprogress))
	{
		for (int i = 1; i<MaxClients+1; i++)
		{
			if (IsClientConnected(i) && IsValidEntity(i) && IsClientInGame(i))
			{
				if (GetEntityRenderFx(i) == RENDERFX_DISTORT)
				{
					mapchangeinprogress = true;
				}
			}
		}
	}
}