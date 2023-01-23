/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Rock The Vote Plugin
 * Creates a map vote when the required number of players have requested one.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
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

#include <sourcemod>
#include <mapchooser>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Map Nominations",
	author = "AlliedModders LLC",
	description = "Provides Map Nominations",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

ConVar g_Cvar_ExcludeOld;
ConVar g_Cvar_ExcludeCurrent;
ConVar g_Cvar_CycleFile;
ConVar g_Cvar_UseDialogs;

Menu g_MapMenu = null;
Handle g_MapList = null;
//int g_mapFileSerial = -1;
char currentMap[32];
int passedcl = 0;
int modsact = 0;
Handle modlist = INVALID_HANDLE;

#define MAPSTATUS_ENABLED (1<<0)
#define MAPSTATUS_DISABLED (1<<1)
#define MAPSTATUS_EXCLUDE_CURRENT (1<<2)
#define MAPSTATUS_EXCLUDE_PREVIOUS (1<<3)
#define MAPSTATUS_EXCLUDE_NOMINATED (1<<4)

StringMap g_mapTrie = null;
char maptag[128];

bool bSynAct = false;
char gamename[64];

public void OnPluginStart()
{
	modlist = CreateArray(64);
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	
	GetGameFolderName(gamename,sizeof(gamename));
	if (StrEqual(gamename,"synergy",false)) bSynAct = true;
	
	int arraySize = ByteCountToCells(33);
	g_MapList = CreateArray(arraySize);
	
	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);
	g_Cvar_CycleFile = FindConVar("sm_nominate_mapcyclefile");
	if (g_Cvar_CycleFile == INVALID_HANDLE) g_Cvar_CycleFile = CreateConVar("sm_nominate_mapcyclefile", "mapcyclecfg", "Specifies the mapcycle file to use for nominations list", 0);
	g_Cvar_UseDialogs = FindConVar("sm_nominate_usedialogs");
	if (g_Cvar_UseDialogs == INVALID_HANDLE) g_Cvar_UseDialogs = CreateConVar("sm_nominate_usedialogs", "0", "Uses dialogs for nomination menu.", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("nom", Command_Nominate);
	RegConsoleCmd("sm_nominate", Command_Nominate);
	RegConsoleCmd("sm_nominate_dialog", AttemptNominate);
	
	RegAdminCmd("sm_nominate_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_nominate_addmap <mapname> - Forces a map to be on the next mapvote.");
	
	g_mapTrie = new StringMap();
	RegConsoleCmd("maplist", fullmapslist);
}

public void OnConfigsExecuted()
{
	/*
	if (ReadMapList(g_MapList,
					g_mapFileSerial,
					"nominations",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== null)
	{
		if (g_mapFileSerial == -1)
		{
			SetFailState("Unable to create a valid map list.");
		}
	}
	*/
	ClearArray(g_MapList);
	char pathtomapcycle[128];
	GetConVarString(g_Cvar_CycleFile,pathtomapcycle,sizeof(pathtomapcycle));
	Format(pathtomapcycle,sizeof(pathtomapcycle),"cfg/%s.txt",pathtomapcycle);
	if (!FileExists(pathtomapcycle,false))
	{
		PrintToServer("Mapcycle config: %s does not exist.",pathtomapcycle);
		Format(pathtomapcycle,sizeof(pathtomapcycle),"cfg/mapcyclecfg.txt");
	}
	Handle hostnamh = FindConVar("hostname");
	char hostnam[32];
	GetConVarString(hostnamh,hostnam,sizeof(hostnam));
	CloseHandle(hostnamh);
	if (StrContains(hostnam,"ptsd",false) != -1)
		Format(pathtomapcycle,sizeof(pathtomapcycle),"cfg/mapcyclecfgptsd.txt");
	else if (StrContains(hostnam,"Black Mesa in Synergy",false) != -1)
		Format(pathtomapcycle,sizeof(pathtomapcycle),"cfg/mapcyclecfgbms.txt");
	Handle thishandle = INVALID_HANDLE;
	if (FileExists(pathtomapcycle))
	{
		thishandle = OpenFile(pathtomapcycle,"r");
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
		char szFirst[3][64];
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
					Format(szFirst[0], sizeof(szFirst[]), "%s", line);
					if (StrContains(line, " ", false) != -1)
					{
						ExplodeString(line, " ", szFirst, 3, 64, true);
					}
					Format(szMapPath, sizeof(szMapPath), "maps/%s.bsp", szFirst[0]);
					if (FileExists(szMapPath, true, NULL_STRING))
					{
						PushArrayString(g_MapList, line);
					}
					else
					{
						PrintToServer("MapCycle has invalid map: '%s'", szFirst[0]);
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
	else
	{
		PrintToServer("Failed to get mapcycle or mapcyclecfg!");
	}
	
	BuildMapMenu();
}

public void OnNominationRemoved(const char[] map, int owner)
{
	int status;
	
	/* Is the map in our list? */
	if (!g_mapTrie.GetValue(map, status))
	{
		return;	
	}
	
	/* Was the map disabled due to being nominated */
	if ((status & MAPSTATUS_EXCLUDE_NOMINATED) != MAPSTATUS_EXCLUDE_NOMINATED)
	{
		return;
	}
	
	g_mapTrie.SetValue(map, MAPSTATUS_ENABLED);
}

public Action Command_Addmap(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nominate_addmap <mapname>");
		return Plugin_Handled;
	}
	
	char mapname[128];
	GetCmdArg(1, mapname, sizeof(mapname));

	
	int status;
	if (!g_mapTrie.GetValue(mapname, status))
	{
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
	}
	
	NominateResult result = NominateMap(mapname, true, 0);
	
	if (result > Nominate_Replaced)
	{
		/* We assume already in vote is the casue because the maplist does a Map Validity check and we forced, so it can't be full */
		ReplyToCommand(client, "%t", "Map Already In Vote", mapname);
		
		return Plugin_Handled;	
	}
	
	
	g_mapTrie.SetValue(mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

	
	ReplyToCommand(client, "%t", "Map Inserted", mapname);
	LogAction(client, -1, "\"%L\" inserted map \"%s\".", client, mapname);

	return Plugin_Handled;		
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (!client)
	{
		return;
	}
	
	if (strcmp(sArgs, "nominate", false) == 0)
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		AttemptNominate(client,0);
		
		SetCmdReplySource(old);
	}
}

public Action Command_Nominate(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		AttemptNominate(client,0);
		return Plugin_Handled;
	}
	
	char mapname[128];
	GetCmdArg(1, mapname, sizeof(mapname));
	
	if (StrEqual(mapname,"nextmap",false))
	{
		char curmap[128];
		GetCurrentMap(curmap,sizeof(curmap));
		Handle cvar = FindConVar("content_metadata");
		if (cvar != INVALID_HANDLE)
		{
			char contentdata[64];
			GetConVarString(cvar,contentdata,sizeof(contentdata));
			char fixuptmp[16][16];
			ExplodeString(contentdata," ",fixuptmp,16,16,true);
			if (strlen(fixuptmp[2]) > 0) Format(curmap,sizeof(curmap),"%s %s",fixuptmp[2],curmap);
		}
		CloseHandle(cvar);
		int find = FindStringInArray(g_MapList,curmap);
		if (find != -1)
		{
			find++;
			if (GetArraySize(g_MapList) <= find)
				GetArrayString(g_MapList,find,mapname,sizeof(mapname));
			else
				GetArrayString(g_MapList,0,mapname,sizeof(mapname));
		}
	}
	
	int status;
	if (!g_mapTrie.GetValue(mapname, status))
	{
		if ((GetArraySize(g_MapList) > 0) && (strlen(mapname) > 0))
		{
			int similarmaps = 0;
			char mapsearch[64];
			char lastmapsearch[64];
			Menu menu = new Menu(MenuHandler);
			menu.SetTitle("Partial match list");
			for (int i = 0;i<GetArraySize(g_MapList);i++)
			{
				GetArrayString(g_MapList,i,mapsearch,sizeof(mapsearch));
				if (StrContains(mapsearch,mapname,false) != -1)
				{
					similarmaps++;
					PrintToConsole(client,"%s",mapsearch);
					Format(lastmapsearch,sizeof(lastmapsearch),"%s",mapsearch);
					menu.AddItem(mapsearch,mapsearch);
				}
			}
			if ((similarmaps == 1) && (strlen(lastmapsearch) > 0))
			{
				Format(mapname,sizeof(mapname),"%s",lastmapsearch);
				//g_mapTrie.GetValue(mapname, status);
				CloseHandle(menu);
			}
			else if (similarmaps > 0)
			{
				ReplyToCommand(client, "%t", "Map was not found", mapname);
				ReplyToCommand(client, "But there were %i maps found with similar names. Check console", similarmaps);
				menu.ExitButton = true;
				menu.Display(client, 120);
				return Plugin_Handled;
			}
			else
			{
				CloseHandle(menu);
				ReplyToCommand(client, "%t", "Map was not found", mapname);
				return Plugin_Handled;
			}
		}
		else return Plugin_Handled;
	}
	
	if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
	{
		if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
		{
			ReplyToCommand(client, "[SM] %t", "Can't Nominate Current Map");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
		{
			ReplyToCommand(client, "[SM] %t", "Map in Exclude List");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			ReplyToCommand(client, "[SM] %t", "Map Already Nominated");
		}
		
		return Plugin_Handled;
	}
	
	NominateResult result = NominateMap(mapname, false, client);
	
	if (result > Nominate_Replaced)
	{
		if (result == Nominate_AlreadyInVote)
		{
			ReplyToCommand(client, "%t", "Map Already In Vote", mapname);
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "Map Already Nominated");
		}
		
		return Plugin_Handled;	
	}
	
	/* Map was nominated! - Disable the menu item and update the trie */
	
	g_mapTrie.SetValue(mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);
	
	char name[128];
	GetClientName(client, name, sizeof(name));
	char map[128];
	Format(map,sizeof(map),"%s",mapname);
	GetMapTag(map);
	char translate[128];
	for (int i = 1;i<MaxClients+1;i++)
	{
		if (IsValidEntity(i))
		{
			if (IsClientConnected(i))
			{
				if (IsClientInGame(i))
				{
					if (!IsFakeClient(i))
					{
						Format(translate,sizeof(translate),"[SM] %T","Map Nominated", i, name, map);
						PrintToChat(i,"%s (%s)", translate, maptag);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action fullmapslist(int client, int args)
{
	if (GetArraySize(g_MapList) < 1)
	{
		char mapcyclefind[64];
		if (FileExists("cfg/mapcyclecfg.txt",false))
			Format(mapcyclefind,sizeof(mapcyclefind),"cfg/mapcyclecfg.txt");
		else if (FileExists("cfg/mapcycle.txt",false))
			Format(mapcyclefind,sizeof(mapcyclefind),"cfg/mapcycle.txt");
		if (strlen(mapcyclefind) > 0)
		{
			Handle filehandle = OpenFile(mapcyclefind,"r");
			if (filehandle != INVALID_HANDLE)
			{
				char line[64];
				while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
				{
					TrimString(line);
					if (strlen(line) > 0) PushArrayString(g_MapList,line);
				}
			}
			CloseHandle(filehandle);
		}
		else return Plugin_Handled;
	}
	Handle dp = CreateDataPack();
	WritePackCell(dp,client);
	WritePackCell(dp,0);
	if (client != 0)
	{
		PrintToChat(client,"%i maps on server",GetArraySize(g_MapList));
		ClientCommand(client,"con_enable 1");
		ClientCommand(client,"toggleconsole");
	}
	else PrintToConsole(client,"%i maps on server",GetArraySize(g_MapList));
	CreateTimer(0.1,fullmapslistdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action fullmapslistdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int client = ReadPackCell(dp);
		int arrstart = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(client)) && (IsClientInGame(client)))
		{
			int threeperline = 0;
			char showline[172];
			for (int i = arrstart;i<GetArraySize(g_MapList);i++)
			{
				if (i >= arrstart+20) break;
				else
				{
					char map[64];
					GetArrayString(g_MapList,i,map,sizeof(map));
					GetMapTag(map);
					Format(showline,sizeof(showline),"%s%s From Mod (%s) ",showline,map,maptag);
					if ((strlen(showline) < 50) && (threeperline == 0))
					{
						int tmplen = strlen(showline);
						for (int j = tmplen;j<51;j++)
						{
							StrCat(showline,sizeof(showline)," ");
						}
					}
					else if ((strlen(showline) < 100) && (threeperline == 1))
					{
						int tmplen = strlen(showline);
						for (int j = tmplen;j<101;j++)
						{
							StrCat(showline,sizeof(showline)," ");
						}
					}
					threeperline++;
					if (threeperline >= 3)
					{
						PrintToConsole(client,"%s",showline);
						threeperline = 0;
						showline = "";
					}
					//PrintToConsole(client,"%s From Mod (%s)",map,maptag);
				}
			}
			arrstart+=20;
			if (arrstart < GetArraySize(g_MapList)+19)
			{
				Handle dpnext = CreateDataPack();
				WritePackCell(dpnext,client);
				WritePackCell(dpnext,arrstart);
				CreateTimer(0.2,fullmapslistdelay,dpnext,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Handled;
}

public Action AttemptNominate(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	if (g_Cvar_UseDialogs.BoolValue)
	{
		char szDesc[256];
		Format(szDesc,sizeof(szDesc),"%T","Nominate Title",client);
		Handle gKV = CreateKeyValues("data");
		KvSetString(gKV, "title", szDesc);
		KvSetNum(gKV, "level", 2);
		KvSetColor(gKV, "color", 255, 255, 0, 255);
		KvSetNum(gKV, "time", 20);
		bool bEndOfList = false;
		if (args > 0)
		{
			char szArg[4];
			GetCmdArg(1,szArg,sizeof(szArg));
			if (strlen(szArg) > 0)
			{
				if (StringToInt(szArg) < 0) Format(szArg,sizeof(szArg),"0");
				char szInt[4];
				for (int i = StringToInt(szArg);i<(StringToInt(szArg)+6);i++)
				{
					if (i == GetArraySize(g_MapList))
					{
						bEndOfList = true;
						break;
					}
					Format(szInt,sizeof(szInt),"%i",i+1);
					GetArrayString(g_MapList,i,szDesc,sizeof(szDesc));
					KvJumpToKey(gKV, szInt, true);
					KvSetString(gKV, "msg", szDesc);
					Format(szDesc,sizeof(szDesc),"sm_nominate \"%s\"",szDesc);
					KvSetString(gKV, "command", szDesc);
					KvRewind(gKV);
				}
				if (!bEndOfList)
				{
					Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
					KvJumpToKey(gKV, szInt, true);
					KvSetString(gKV, "msg", "Next page");
					Format(szDesc,sizeof(szDesc),"sm_nominate_dialog %i",StringToInt(szArg)+6);
					KvSetString(gKV, "command", szDesc);
					KvRewind(gKV);
				}
				if (StringToInt(szArg) > 0)
				{
					Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
					KvJumpToKey(gKV, szInt, true);
					KvSetString(gKV, "msg", "Back");
					Format(szDesc,sizeof(szDesc),"sm_nominate_dialog %i",StringToInt(szArg)-6);
					KvSetString(gKV, "command", szDesc);
					KvRewind(gKV);
				}
				
				CreateDialog(client, gKV, DialogType_Menu);
				CloseHandle(gKV);
			}
		}
		else
		{
			char szInt[4];
			for (int i = 0;i<6;i++)
			{
				if (i == GetArraySize(g_MapList))
				{
					bEndOfList = true;
					break;
				}
				Format(szInt,sizeof(szInt),"%i",i+1);
				GetArrayString(g_MapList,i,szDesc,sizeof(szDesc));
				KvJumpToKey(gKV, szInt, true);
				KvSetString(gKV, "msg", szDesc);
				Format(szDesc,sizeof(szDesc),"sm_nominate \"%s\"",szDesc);
				KvSetString(gKV, "command", szDesc);
				KvRewind(gKV);
			}
			if (!bEndOfList)
			{
				Format(szInt,sizeof(szInt),"%i",StringToInt(szInt)+1);
				KvJumpToKey(gKV, szInt, true);
				KvSetString(gKV, "msg", "Next page");
				KvSetString(gKV, "command", "sm_nominate_dialog 6");
				KvRewind(gKV);
			}
			
			CreateDialog(client, gKV, DialogType_Menu);
			CloseHandle(gKV);
		}
		
		return Plugin_Handled;
	}
	if ((StrEqual(gamename,"tf",false)) || (modsact == 1))
	{
		AttemptNominateAllMP(client);
		return Plugin_Handled;
	}
	Menu menu = new Menu(MenuHandlersub);
	menu.SetTitle("%T", "Nominate Title", client);
	if (GetArraySize(modlist) > 0)
	{
		for (int i = 0;i<GetArraySize(modlist);i++)
		{
			char addlist[64];
			GetArrayString(modlist,i,addlist,sizeof(addlist));
			if (StrEqual(addlist,"Syn",false))
				menu.AddItem(addlist,"Synergy/Custom");
			else
				menu.AddItem(addlist,addlist);
		}
	}
	menu.AddItem("allmaps", "All Maps");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandlersub(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info,"allmaps",false))
		{
			AttemptNominateAllMP(param1);
			return;
		}
		int arraySize = ByteCountToCells(33);
		Handle tmparr = CreateArray(arraySize);
		for (int i = 0; i<GetArraySize(g_MapList); i++)
		{
			char tmp[128];
			GetArrayString(g_MapList,i,tmp,sizeof(tmp));
			GetMapTag(tmp);
			if (StrEqual(info,maptag,false))
				PushArrayString(tmparr,tmp);
		}
		tmpmenu(param1,tmparr,info);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else
	{
		
	}
}

void tmpmenu(int client, Handle tmparr, char[] menutitle)
{
	menutitle[0] &= ~(1 << 5);
	char menutitletmp[128];
	char rebuildupper[32][32];
	ExplodeString(menutitle," ",rebuildupper,32,32);
	for (int i = 0;i<32;i++)
	{
		if (strlen(rebuildupper[i]) > 0)
		{
			if (StringToInt(rebuildupper[i]) == 0) rebuildupper[i][0] &= ~(1 << 5);
			if (strlen(menutitletmp) > 0)
				Format(menutitletmp,sizeof(menutitletmp),"%s %s",menutitletmp,rebuildupper[i]);
			else
				Format(menutitletmp,sizeof(menutitletmp),"%s",rebuildupper[i]);
		}
		else break;
	}
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle(menutitletmp);
	
	// Should probably make this better
	bool bSkipSpace = true;
	if (StrEqual(gamename, "tf_coop_extended", false))
	{
		bSkipSpace = false;
	}
	
	for (int k;k<GetArraySize(tmparr);k++)
	{
		char ktmp[128];
		GetArrayString(tmparr, k, ktmp, sizeof(ktmp));
		int status;
		int pos = StrContains(ktmp," ",false);
		if (!bSkipSpace) pos = -1;
		g_mapTrie.GetValue(ktmp, status);
		if (status & MAPSTATUS_EXCLUDE_CURRENT)
		{
			char ktmpd[128];
			Format(ktmpd,sizeof(ktmpd),"%s (Current Map)",ktmp[pos+1]);
			if (StrContains(ktmp,"workshop/",false) != -1)
			{
				GetMapDisplayName(ktmp,ktmpd,sizeof(ktmpd));
				Format(ktmpd,sizeof(ktmpd),"%s (Current Map)",ktmpd);
			}
			menu.AddItem(ktmp, ktmpd, ITEMDRAW_DISABLED);
		}
		else if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			char ktmpd[128];
			Format(ktmpd,sizeof(ktmpd),"%s (Nominated)",ktmp[pos+1]);
			if (StrContains(ktmpd,"workshop/",false) != -1)
			{
				GetMapDisplayName(ktmp,ktmpd,sizeof(ktmpd));
				Format(ktmpd,sizeof(ktmpd),"%s (Nominated)",ktmpd);
			}
			menu.AddItem(ktmp, ktmpd, ITEMDRAW_DISABLED);
		}
		else
		{
			if (pos < 0) menu.AddItem(ktmp, ktmp);
			else menu.AddItem(ktmp, ktmp[pos+1]);
		}
	}
	ClearArray(tmparr);
	CloseHandle(tmparr);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	passedcl = client;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char mapname[128];
		menu.GetItem(param2, mapname, sizeof(mapname));
		int status;
		if (!g_mapTrie.GetValue(mapname, status))
		{
			ReplyToCommand(param1, "%t", "Map was not found", mapname);
			return 0;
		}
		
		if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
		{
			if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
			{
				ReplyToCommand(param1, "[SM] %t", "Can't Nominate Current Map");
			}
			
			if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
			{
				ReplyToCommand(param1, "[SM] %t", "Map in Exclude List");
			}
			
			if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
			{
				ReplyToCommand(param1, "[SM] %t", "Map Already Nominated");
			}
			
			return 0;
		}
		
		NominateResult result = NominateMap(mapname, false, param1);
		
		if (result > Nominate_Replaced)
		{
			if (result == Nominate_AlreadyInVote)
			{
				ReplyToCommand(param1, "%t", "Map Already In Vote", mapname);
			}
			else
			{
				ReplyToCommand(param1, "[SM] %t", "Map Already Nominated");
			}
			
			return 0;
		}
		
		/* Map was nominated! - Disable the menu item and update the trie */
		
		g_mapTrie.SetValue(mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);
		
		char name[128];
		GetClientName(param1, name, sizeof(name));
		char map[128];
		Format(map,sizeof(map),"%s",mapname);
		GetMapTag(map);
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsClientConnected(i))
			{
				if ((IsValidEntity(i)) && (IsClientInGame(i)))
				{
					char translate[128];
					Format(translate,sizeof(translate),"[SM] %T","Map Nominated", i, name, map);
					PrintToChat(i,"%s (%s)", translate, maptag);
				}
			}
		}
	}
	else if (action == MenuAction_DisplayItem)
	{
		char info[128];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info,currentMap,false))
		{
			PrintToServer("map eq");
			return ITEMDRAW_DISABLED;
		}
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		if ((param1 == MenuEnd_ExitBack) && (IsClientInGame(passedcl)))
			AttemptNominate(passedcl,0);
		delete menu;
	}
	else
	{
		
	}
	return 0;
}

void AttemptNominateAllMP(int client)
{
	g_MapMenu.SetTitle("%T", "Nominate Title", client);
	g_MapMenu.Display(client, MENU_TIME_FOREVER);
	
	return;
}

void BuildMapMenu()
{
	delete g_MapMenu;
	
	g_mapTrie.Clear();
	
	g_MapMenu = new Menu(Handler_MapSelectMenu, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);

	char map[128];
	
	ArrayList excludeMaps;
	
	if (g_Cvar_ExcludeOld.BoolValue)
	{	
		excludeMaps = new ArrayList(ByteCountToCells(33));
		GetExcludeMapList(excludeMaps);
	}
	
	if (g_Cvar_ExcludeCurrent.BoolValue)
	{
		GetCurrentMap(currentMap, sizeof(currentMap));
	}
	
		
	for (int i = 0; i < GetArraySize(g_MapList); i++)
	{
		int status = MAPSTATUS_ENABLED;
		
		GetArrayString(g_MapList, i, map, sizeof(map));
		
		if (g_Cvar_ExcludeCurrent.BoolValue)
		{
			char displaymap[128];
			Format(displaymap,sizeof(displaymap),map);
			if (StrContains(displaymap,"workshop/",false) != -1)
				GetMapDisplayName(map,displaymap,sizeof(displaymap));
			int pos = StrContains(displaymap," ",false);
			if (pos != -1) Format(displaymap,sizeof(displaymap),"%s",displaymap[pos+1]);
			if (StrEqual(displaymap,currentMap))
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_CURRENT;
			}
		}
		
		/* Dont bother with this check if the current map check passed */
		if (g_Cvar_ExcludeOld.BoolValue && status == MAPSTATUS_ENABLED)
		{
			if (excludeMaps.FindString(map) != -1)
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_PREVIOUS;
			}
		}
		
		GetMapTag(map);
		char displayname[128];
		Format(displayname,sizeof(displayname),"%s (%s)", map, maptag);
		if (StrContains(displayname,"workshop/",false) != -1)
			Format(displayname,sizeof(displayname),"%s",maptag);
		g_MapMenu.AddItem(map, displayname);
		g_mapTrie.SetValue(map, status);
	}

	g_MapMenu.ExitButton = true;

	delete excludeMaps;
}

public int Handler_MapSelectMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char map[128], name[128];
			menu.GetItem(param2, map, sizeof(map));		
			
			GetClientName(param1, name, 128);
	
			NominateResult result = NominateMap(map, false, param1);
			
			/* Don't need to check for InvalidMap because the menu did that already */
			if (result == Nominate_AlreadyInVote)
			{
				PrintToChat(param1, "[SM] %t", "Map Already Nominated");
				return 0;
			}
			else if (result == Nominate_VoteFull)
			{
				PrintToChat(param1, "[SM] %t", "Max Nominations");
				return 0;
			}
			
			GetMapTag(map);
			char displayname[128];
			Format(displayname,sizeof(displayname),"%s (%s)", map, maptag);
			
			g_mapTrie.SetValue(map, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

			if (result == Nominate_Replaced)
			{
				PrintToChatAll("[SM] %t", "Map Nomination Changed", name, displayname);
				return 0;	
			}
			
			PrintToChatAll("[SM] %t", "Map Nominated", name, displayname);
		}
		
		case MenuAction_DrawItem:
		{
			char map[128];
			menu.GetItem(param2, map, sizeof(map));
			
			int status;
			
			if (!g_mapTrie.GetValue(map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return ITEMDRAW_DEFAULT;
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				return ITEMDRAW_DISABLED;	
			}
			
			return ITEMDRAW_DEFAULT;
						
		}
		
		case MenuAction_DisplayItem:
		{
			char map[128];
			menu.GetItem(param2, map, sizeof(map));
			
			int status;
			
			if (!g_mapTrie.GetValue(map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return 0;
			}
			
			char display[100];
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
				{
					Format(display, sizeof(display), "%s (%T)", map, "Current Map", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
				{
					Format(display, sizeof(display), "%s (%T)", map, "Recently Played", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
				{
					Format(display, sizeof(display), "%s (%T)", map, "Nominated", param1);
					return RedrawMenuItem(display);
				}
			}
			
			return 0;
		}
	}
	
	return 0;
}

public Action GetMapTag(const char[] map)
{
	char modname[64];
	if (StrContains(map,"workshop/",false) != -1)
	{
		if (modsact < 2) modsact++;
		GetMapDisplayName(map,maptag,sizeof(maptag));
	}
	else if ((StrContains(map,"rock24 d",false) == 0) || (StrEqual(map,"d1_overboard_01",false)) || (StrEqual(map,"d1_wakeupcall_02",false)) || (StrEqual(map,"d2_breakout_03",false)) || (StrEqual(map,"d2_surfacing_04",false)) || (StrEqual(map,"d3_theescape_05",false)) || (StrEqual(map,"d3_extraction_06",false)))
	{
		Format(modname, sizeof(modname), "Rock 24");
	}
	else if ((StrContains(map, "d1_", false) == 0) && (!StrEqual(map, "d1_trainstation_05_d_start_f", false)) && (!StrEqual(map, "d1_trainstation_06_d_ending_f", false)))
	{
		Format(modname, sizeof(modname), "Half-Life 2");
	}
	else if (StrContains(map, "d2_lostcoast", false) == 0)
	{
		Format(modname, sizeof(modname), "Lost Coast");
	}
	else if (((StrContains(map, "d2_", false) == 0) || (StrContains(map, "d3_", false) == 0) || (StrContains(map, "hl2 ",false) == 0)) && (StrContains(map, " gamemode ", false) == -1))
	{
		Format(modname, sizeof(modname), "Half-Life 2");
	}
	else if (StrContains(map, "hl2u ", false) == 0)
	{
		Format(modname, sizeof(modname), "Half-Life 2 Update");
	}
	else if ((StrContains(map, "c0a0", false) == 0) || (StrContains(map, "c1a", false) == 0) || (StrContains(map, "c2a", false) == 0) || (StrContains(map, "c3a", false) == 0) || (StrContains(map, "c4a", false) == 0) || (StrEqual(map, "c5a1", false)))
	{
		Format(modname, sizeof(modname), "Half-Life 1");
	}
	else if ((StrContains(map, "hls", false) == 0) && (StrContains(map, "mrl", false) != -1))
	{
		Format(modname, sizeof(modname), "Half-Life 1 Merged");
	}
	else if (StrContains(map, "ep1", false) == 0)
	{
		Format(modname, sizeof(modname), "HL2: Episode 1");
	}
	else if (StrContains(map, "ep2_outland_", false) == 0)
	{
		Format(modname, sizeof(modname), "HL2: Episode 2");
	}
	else if ((StrContains(map, "metastasis", false) == 0) || (StrContains(map, "meta metastasis", false) == 0))
	{
		Format(modname, sizeof(modname), "Minerva");
	}
	else if ((StrContains(map, "sp_c14_", false) == 0) || (StrContains(map, "cal sp_c14_", false) == 0))
	{
		Format(modname, sizeof(modname), "Calamity");
	}
	else if ((StrContains(map, "cit2 sp", false) == 0) || (StrEqual(map, "sp_canal1", false)) || (StrEqual(map, "sp_canal2", false)) || (StrEqual(map, "sp_base", false)) || (StrEqual(map, "sp_canyon", false)) || (StrEqual(map, "sp_casino", false)) || (StrEqual(map, "sp_casino2", false)) || (StrEqual(map, "sp_ending", false)) || (StrEqual(map, "sp_intro", false)) || (StrEqual(map, "sp_postsquare", false)) || (StrEqual(map, "sp_precasino", false)) || (StrEqual(map, "sp_presquare", false)) || (StrEqual(map, "sp_square", false)) || (StrContains(map, "sp_streetwar", false) == 0) || (StrEqual(map, "sp_waterplant", false)) || (StrEqual(map, "sp_waterplant2", false)))
	{
		Format(modname, sizeof(modname), "The Citizen Returns");
	}
	else if ((StrEqual(map, "d1_trainstation_05_d_start_f", false)) || (StrEqual(map, "d1_trainstation_06_d_ending_f", false)) || (StrContains(map, "shuter_st_f", false) == 0) || (StrContains(map, "st_michaels_", false) == 0) || (StrContains(map, "yonge_st_f", false) == 0) || (StrContains(map, "dundas_square_f", false) == 0) || (StrContains(map, "subway_system_f", false) == 0) || (StrContains(map, "mel_lastman_square_f", false) == 0))
	{
		Format(modname, sizeof(modname), "City 7: Toronto Conflict");
	}
	else if ((StrContains(map, "up_", false) == 0) || (StrContains(map, "up up_", false) == 0))
	{
		Format(modname, sizeof(modname), "Uncertainty Principle");
	}
	else if ((StrContains(map, "ra_c1l", false) == 0) || (StrContains(map, "riotact ra_c1l", false) == 0))
	{
		Format(modname, sizeof(modname), "Riot Act");
	}
	else if ((StrContains(map, "dw_", false) == 0) || (StrContains(map, "dworld dw", false) == 0))
	{
		Format(modname, sizeof(modname), "Dangerous World");
	}
	else if ((StrContains(map, "r_map", false) == 0) || (StrContains(map, "pre r_", false) == 0))
	{
		Format(modname, sizeof(modname), "Precursor");
	}
	else if ((StrContains(map, "leonhl2-2", false) == 0) || (StrContains(map, "final_credits", false) == 0) || (StrContains(map, "ctoa leonHL2", false) == 0) || (StrContains(map, "ctoa final", false) == 0))
	{
		Format(modname, sizeof(modname), "Coastline To Atmosphere");
	}
	else if (StrContains(map, "spymap_ep3", false) != -1)
	{
		Format(modname, sizeof(modname), "Episode 3: The Closure");
	}
	else if ((StrContains(map, "island", false) == 0) || (StrContains(map, "offshore island", false) == 0))
	{
		Format(modname, sizeof(modname), "Offshore");
	}
	else if (StrContains(map, "level_", false) == 0)
	{
		Format(modname, sizeof(modname), "Research & Development");
	}
	else if (StrContains(map, "cd", false) == 0)
	{
		Format(modname, sizeof(modname), "Combine Destiny");
	}
	else if (StrContains(map, "nt_", false) == 0)
	{
		Format(modname, sizeof(modname), "Neotokyo");
	}
	else if ((StrContains(map, "po_", false) == 0) || (StrContains(map, "op po_", false) == 0))
	{
		Format(modname, sizeof(modname), "Omega Prison");
	}
	else if ((StrContains(map, "mimp", false) == 0) || (StrContains(map, "mi mimp", false) == 0))
	{
		Format(modname, sizeof(modname), "Mission Improbable");
	}
	else if (StrContains(map, "_sm_", false) != -1)
	{
		Format(modname, sizeof(modname), "Strider Mountain");
	}
	else if ((StrContains(map, "slums_", false) == 0) || (StrContains(map, "s2e slums_", false) == 0))
	{
		Format(modname, sizeof(modname), "Slums 2: Extended");
	}
	else if ((StrEqual(map, "ravenholmlc1", false)) || (StrContains(map, "rhlc raven", false) == 0))
	{
		Format(modname, sizeof(modname), "Ravenholm: The Lost Chapter");
	}
	else if ((StrContains(map, "ravenholm", false) == 0) || (StrContains(map, "rh ravenholm", false) == 0))
	{
		Format(modname, sizeof(modname), "Ravenholm");
	}
	else if (StrContains(map, "sn_", false) == 0)
	{
		Format(modname, sizeof(modname), "Spherical Nightmares");
	}
	else if ((StrContains(map, "ks_mop_", false) == 0) || (StrContains(map, "mop ks_mop_", false) == 0))
	{
		Format(modname, sizeof(modname), "Mistake of Pythagoras");
	}
	else if ((StrContains(map, "ce_0", false) == 0) || (StrContains(map, "ce ce_0", false) == 0))
	{
		Format(modname, sizeof(modname), "Causality Effect");
	}
	else if (StrContains(map, "1187", false) == 0)
	{
		Format(modname, sizeof(modname), "1187");
	}
	else if ((StrContains(map, "sh_alchemilla", false) == 0) || (StrContains(map, "alc sh_alchemilla", false) == 0))
	{
		Format(modname, sizeof(modname), "Alchemilla");
	}
	else if (StrContains(map, "eots_1", false) == 0)
	{
		Format(modname, sizeof(modname), "Eye of The Storm");
	}
	else if ((StrContains(map, "mpr_0", false) == 0) || (StrContains(map, "mpr mpr_0", false) == 0))
	{
		Format(modname, sizeof(modname), "The Masked Prisoner");
	}
	else if ((StrContains(map, "belowice", false) == 0) || (StrEqual(map,"memory",false)) || (StrContains(map, "bti ", false) == 0))
	{
		Format(modname, sizeof(modname), "Below The Ice");
	}
	else if ((StrContains(map, "dayhardpart", false) == 0) || (StrContains(map, "dh ", false) == 0) || (StrEqual(map,"dayhard_menu",false)) || (StrEqual(map,"voyage",false)) || (StrEqual(map,"redrum",false)) || (StrEqual(map,"finale",false)) || (StrEqual(map,"breencave",false)) || (StrEqual(map,"dojo",false)))
	{
		Format(modname, sizeof(modname), "Day Hard");
	}
	else if ((StrEqual(map,"brighe",false)) || (StrEqual(map,"city-s",false)) || (StrContains(map,"mine01_0",false) == 0) || (StrContains(map,"mine_01_0",false) == 0) || (StrContains(map,"ante ",false) == 0))
	{
		Format(modname, sizeof(modname), "Antlions Everywhere");
	}
	else if (StrEqual(map, "intro01", false) || StrEqual(map, "intro02", false) || StrEqual(map, "mines01", false) || StrEqual(map, "mines02", false) || StrEqual(map, "sewer01", false) || StrEqual(map, "scape01", false) || StrEqual(map, "scape02", false) || StrEqual(map, "scape03", false) || StrEqual(map, "ldtd01", false) || StrEqual(map, "tull01", false) || StrEqual(map, "surreal01", false) || StrEqual(map, "outside01", false) || StrEqual(map, "ending01", false))
	{
		Format(modname, sizeof(modname), "Lost Under The Snow");
	}
	else if ((StrContains(map, "th_intro", false) == 0) || (StrContains(map, "drainage", false) == 0) || (StrContains(map, "church", false) == 0) || (StrContains(map, "basement", false) == 0) || (StrContains(map, "cabin", false) == 0) || (StrContains(map, "cave", false) == 0) || (StrContains(map, "rift", false) == 0) || (StrContains(map, "volcano", false) == 0) || (StrContains(map, "train", false) == 0))
	{
		Format(modname, sizeof(modname), "They Hunger Again");
	}
	else if (StrContains(map, "dwn0", false) == 0)
	{
		Format(modname, sizeof(modname), "DownFall");
	}
	else if ((StrContains(map, "Penetration0",false) == 0) || (StrContains(map, "hl2p Penetration0",false) == 0))
	{
		Format(modname, sizeof(modname), "HL2: Penetration");
	}
	else if (StrContains(map, "sttr_ch", false) == 0)
	{
		Format(modname, sizeof(modname), "Steam Tracks Trouble and Riddles");
	}
	else if (StrContains(map, "testchmb_a_", false) == 0)
	{
		Format(modname, sizeof(modname), "Portal");
	}
	else if ((StrContains(map, "llp ", false) == 0) || (StrContains(map, "lifelostprison_0", false) == 0) || (StrContains(map, "bonus_earlyprison_0", false) == 0))
	{
		Format(modname, sizeof(modname), "Liberation");
	}
	else if ((StrContains(map, "ep2_deepdown_", false) == 0) || (StrContains(map, "deepdown ep2_deepdown_", false) == 0))
	{
		Format(modname, sizeof(modname), "Deep Down");
	}
	else if (StrContains(map, "yla_", false) == 0)
	{
		Format(modname, sizeof(modname), "Year Long Alarm");
	}
	else if (StrContains(map, "ktm_", false) == 0)
	{
		Format(modname, sizeof(modname), "Kill The Monk");
	}
	else if (StrContains(map, "t7_", false) == 0)
	{
		Format(modname, sizeof(modname), "Terminal 7");
	}
	else if (StrContains(map, "hc_t0",false) == 0)
	{
		Format(modname, sizeof(modname), "Black Mesa: Hazard Course");
	}
	else if ((StrContains(map, "bm_c", false) == 0) || (StrContains(map, "bms ", false) == 0))
	{
		Format(modname, sizeof(modname), "Black Mesa");
	}
	else if (StrContains(map,"bm_damo0",false) == 0)
	{
		Format(modname, sizeof(modname), "Black Mesa: Damocles");
	}
	else if ((StrContains(map, "xen_c", false) == 0) || (StrContains(map, "bmsxen ", false) == 0))
	{
		Format(modname, sizeof(modname), "Black Mesa: Improved Xen");
	}
	else if (StrContains(map, "ptsd2 ", false) == 0)
	{
		Format(modname, sizeof(modname), "PTSD 2");
	}
	else if (StrContains(map, "ptcs ", false) == 0)
	{
		Format(modname, sizeof(modname), "PTSD Christmas Special");
	}
	else if ((StrContains(map, "ptsd ", false) == 0) || (StrContains(map, "ptsd_", false) == 0) || (StrEqual(map,"boneless_ptsd",false)) || (StrEqual(map,"the_end",false)))
	{
		Format(modname, sizeof(modname), "PTSD");
	}
	else if ((StrContains(map, "am am", false) == 0) || (StrEqual(map,"am2",false)) || (StrEqual(map,"am3",false)) || (StrEqual(map,"am4",false)))
	{
		Format(modname, sizeof(modname), "Aftermath");
	}
	else if (StrContains(map,"Penetration0",false) == 0)
	{
		Format(modname, sizeof(modname), "Half-Life 2: Penetration");
	}
	else if (StrContains(map,"sewer",false) == 0)
	{
		Format(modname, sizeof(modname), "The Sewer");
	}
	else if ((StrContains(map,"az_c",false) == 0) || (StrEqual(map,"az_intro",false)))
	{
		Format(modname, sizeof(modname), "Entropy: Zero");
	}
	else if (StrContains(map,"oc_",false) == 0)
	{
		Format(modname, sizeof(modname), "Obsidian Conflict");
	}
	else if (StrContains(map,"vektaslums0",false) == 0)
	{
		Format(modname, sizeof(modname), "Killzone Source");
	}
	else if (StrContains(map,"silent_escape_map_",false) == 0)
	{
		Format(modname, sizeof(modname), "Silent Escape");
	}
	else if ((StrContains(map,"Uh_Prologue_",false) == 0) || (StrContains(map,"Uh_Chapter1_",false) == 0) || (StrContains(map,"Uh_Chapter2_",false) == 0) || (StrContains(map,"Uh_House_",false) == 0) || (StrContains(map,"Uh_Dreams_",false) == 0))
	{
		Format(modname, sizeof(modname), "Underhell");
	}
	else if ((StrContains(map,"exesc ",false) == 0) || (StrContains(map,"escape_map_0",false) == 0))
	{
		Format(modname, sizeof(modname), "Escape by Ex-Mo");
	}
	else if ((StrContains(map,"hlesc ",false) == 0) || (StrEqual(map,"substation_1_d",false)) || (StrEqual(map,"canals_v1_d",false)) || (StrEqual(map,"canals_v2_d",false)) || (StrEqual(map,"railway21_d",false)))
	{
		Format(modname, sizeof(modname), "Half-Life Escape");
	}
	else if (StrContains(map,"avenueodessa",false) == 0)
	{
		Format(modname, sizeof(modname), "Avenue Odessa");
	}
	else if ((StrContains(map,"prospekt ",false) == 0) || (StrContains(map,"pxg_level_",false) == 0))
	{
		Format(modname, sizeof(modname), "Prospekt");
	}
	else if ((StrContains(map,"amalgam ",false) == 0) || (StrEqual(map,"intro_1",false)) || (StrEqual(map,"sewers_1",false)) || (StrEqual(map,"coast_1",false)) || (StrEqual(map,"tunnel_1",false)) || (StrEqual(map,"beacon_1",false)))
	{
		Format(modname, sizeof(modname), "Amalgam");
	}
	else if ((StrContains(map,"koth_",false) == 0) || (StrContains(map,"gamemode koth",false) != -1))
	{
		Format(modname, sizeof(modname), "King of The Hill");
	}
	else if ((StrContains(map,"ctf_",false) == 0) || (StrContains(map,"gamemode ctf",false) != -1))
	{
		Format(modname, sizeof(modname), "Capture The Flag");
	}
	else if ((StrContains(map,"cp_",false) == 0) || (StrContains(map,"gamemode cp",false) != -1))
	{
		Format(modname, sizeof(modname), "Control Points");
	}
	else if ((StrContains(map,"pl_",false) == 0) || (StrContains(map,"gamemode pl",false) != -1))
	{
		Format(modname, sizeof(modname), "Payload");
	}
	else
	{
		if (StrEqual(gamename,"tf",false))
		{
			Format(maptag, sizeof(maptag), "TF2");
			Format(modname, sizeof(modname), "TF2");
		}
		else if (StrEqual(gamename,"synergy",false))
		{
			Format(maptag, sizeof(maptag), "Syn");
			Format(modname, sizeof(modname), "Syn");
		}
		else
		{
			Format(maptag, sizeof(maptag), "%s", gamename);
			maptag[0] &= ~(1 << 5);
			ReplaceString(maptag,sizeof(maptag),"_"," ",false);
			Format(modname,sizeof(modname),"%s",maptag);
		}
	}
	if (strlen(modname) > 0)
	{
		if (FindStringInArray(modlist,modname) == -1)
		{
			modsact++;
			PushArrayString(modlist,modname);
		}
		Format(maptag,sizeof(maptag),modname);
	}
}