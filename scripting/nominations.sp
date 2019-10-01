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

public void OnPluginStart()
{
	modlist = CreateArray(64);
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	
	int arraySize = ByteCountToCells(33);
	g_MapList = CreateArray(arraySize);
	
	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);
	
	RegConsoleCmd("sm_nominate", Command_Nominate);
	
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
	Format(pathtomapcycle,sizeof(pathtomapcycle),"cfg/mapcyclecfg.txt");
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
		thishandle = OpenFile("mapcycle.txt","r");
	}
	char line[128];
	while(!IsEndOfFile(thishandle)&&ReadFileLine(thishandle,line,sizeof(line)))
	{
		TrimString(line);
		PushArrayString(g_MapList, line);
	}
	CloseHandle(thishandle);
	
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
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
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
	Format(translate,sizeof(translate),"[SM] %t","Map Nominated", name, map);
	PrintToChatAll("%s (%s)", translate, maptag);
	
	return Plugin_Continue;
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
	char gamedesc[32];
	GetGameFolderName(gamedesc,sizeof(gamedesc));
	if ((StrEqual(gamedesc,"tf",false)) || (modsact == 1))
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
	for (int k;k<GetArraySize(tmparr);k++)
	{
		char ktmp[128];
		GetArrayString(tmparr, k, ktmp, sizeof(ktmp));
		int status;
		g_mapTrie.GetValue(ktmp, status);
		if (status & MAPSTATUS_EXCLUDE_CURRENT)
		{
			char ktmpd[128];
			Format(ktmpd,sizeof(ktmpd),"%s (Current Map)",ktmp);
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
			Format(ktmpd,sizeof(ktmpd),"%s (Nominated)",ktmp);
			if (StrContains(ktmpd,"workshop/",false) != -1)
			{
				GetMapDisplayName(ktmp,ktmpd,sizeof(ktmpd));
				Format(ktmpd,sizeof(ktmpd),"%s (Nominated)",ktmpd);
			}
			menu.AddItem(ktmp, ktmpd, ITEMDRAW_DISABLED);
		}
		else
			menu.AddItem(ktmp, ktmp);
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
	else if ((StrEqual(map,"d1_overboard_01",false)) || (StrEqual(map,"d1_wakeupcall_02",false)) || (StrEqual(map,"d2_breakout_03",false)) || (StrEqual(map,"d2_surfacing_04",false)) || (StrEqual(map,"d3_theescape_05",false)) || (StrEqual(map,"d3_extraction_06",false)))
	{
		Format(modname, sizeof(modname), "Rock 24");
	}
	else if (StrContains(map,"d1_",false) == 0)
	{
		Format(modname, sizeof(modname), "Half-Life 2");
	}
	else if (StrEqual(map,"d2_lostcoast",false))
	{
		Format(modname, sizeof(modname), "Lost Coast");
	}
	else if (StrContains(map,"d2_",false) == 0)
	{
		Format(modname, sizeof(modname), "Half-Life 2");
	}
	else if (StrContains(map,"d3_",false) == 0)
	{
		Format(modname, sizeof(modname), "Half-Life 2");
	}
	else if ((StrContains(map, "c0a0", false) == 0) || (StrContains(map, "c1a", false) == 0) || (StrContains(map, "c2a", false) == 0) || (StrContains(map, "c3a", false) == 0) || (StrContains(map, "c4a", false) == 0) || (StrEqual(map, "c5a1", false)))
	{
		Format(modname, sizeof(modname), "Half-Life 1");
	}
	else if (StrContains(map,"ep1_",false) == 0)
	{
		Format(modname, sizeof(modname), "HL2: Episode 1");
	}
	else if (StrContains(map,"ep2_outland_",false) == 0)
	{
		Format(modname, sizeof(modname), "HL2: Episode 2");
	}
	else if (StrContains(map,"meta",false) == 0)
	{
		Format(modname, sizeof(modname), "Minerva");
	}
	else if (StrContains(map,"sp_c14_",false) == 0)
	{
		Format(modname, sizeof(modname), "Calamity");
	}
	else if (StrContains(map,"sp_",false) == 0)
	{
		Format(modname, sizeof(modname), "The Citizen Returns");
	}
	else if ((StrEqual(map,"mel_lastman_square_f",false)) || (StrEqual(map,"shuter_st_f",false)) || (StrContains(map,"st_michaels_",false) == 0) || (StrEqual(map,"yonge_st_f",false)) || (StrEqual(map,"dundas_square_f",false)) || (StrEqual(map,"subway_system_f",false)))
	{
		Format(modname, sizeof(modname), "City 7: Toronto Conflict");
	}
	else if (StrContains(map,"up_",false) == 0)
	{
		Format(modname, sizeof(modname), "Uncertainty Principle");
	}
	else if (StrContains(map,"ra_c1l",false) == 0)
	{
		Format(modname, sizeof(modname), "Riot Act");
	}
	else if (StrContains(map,"dw_",false) == 0)
	{
		Format(modname, sizeof(modname), "Dangerous World");
	}
	else if (StrContains(map,"r_map",false) == 0)
	{
		Format(modname, sizeof(modname), "Precursor");
	}
	else if ((StrContains(map,"leonhl2",false) == 0) || (StrEqual(map,"final_credits",false)))
	{
		Format(modname, sizeof(modname), "Coastline To Atmosphere");
	}
	else if (StrContains(map,"spymap_ep3",false) != -1)
	{
		Format(modname, sizeof(modname), "Episode 3: The Closure");
	}
	else if (StrContains(map,"island",false) == 0)
	{
		Format(modname, sizeof(modname), "Offshore");
	}
	else if (StrContains(map,"level_",false) == 0)
	{
		Format(modname, sizeof(modname), "Research & Development");
	}
	else if (StrContains(map,"cd",false) == 0)
	{
		Format(modname, sizeof(modname), "Combine Destiny");
	}
	else if (StrContains(map,"nt_",false) == 0)
	{
		Format(modname, sizeof(modname), "Neotokyo");
	}
	else if (StrContains(map,"po_",false) == 0)
	{
		Format(modname, sizeof(modname), "Omega Prison");
	}
	else if (StrContains(map,"mimp",false) == 0)
	{
		Format(modname, sizeof(modname), "Mission Improbable");
	}
	else if (StrContains(map,"_sm_",false) != -1)
	{
		Format(modname, sizeof(modname), "Strider Mountain");
	}
	else if (StrContains(map,"slums_",false) == 0)
	{
		Format(modname, sizeof(modname), "Slums 2: Extended");
	}
	else if (StrContains(map,"ravenholm",false) == 0)
	{
		Format(modname, sizeof(modname), "Ravenholm");
	}
	else if (StrContains(map,"sn_",false) == 0)
	{
		Format(modname, sizeof(modname), "Spherical Nightmares");
	}
	else if (StrContains(map,"ks_mop_",false) == 0)
	{
		Format(modname, sizeof(modname), "Mistake of Pythagoras");
	}
	else if (StrContains(map,"ce_0",false) == 0)
	{
		Format(modname, sizeof(modname), "Causality Effect");
	}
	else if (StrContains(map,"1187",false) == 0)
	{
		Format(modname, sizeof(modname), "1187");
	}
	else if (StrContains(map,"sh_alchemilla",false) == 0)
	{
		Format(modname, sizeof(modname), "Alchemilla");
	}
	else if (StrContains(map,"eots_1",false) == 0)
	{
		Format(modname, sizeof(modname), "Eye of The Storm");
	}
	else if (StrContains(map,"mpr_0",false) == 0)
	{
		Format(modname, sizeof(modname), "The Masked Prisoner");
	}
	else if (StrContains(map, "dwn0", false) == 0)
	{
		Format(modname, sizeof(modname), "DownFall");
	}
	else if (StrContains(map, "sttr_ch", false) == 0)
	{
		Format(modname, sizeof(modname), "Steam Tracks Trouble and Riddles");
	}
	else if ((StrContains(map, "belowice", false) == 0) || (StrEqual(map,"memory",false)))
	{
		Format(modname, sizeof(modname), "Below The Ice");
	}
	else if ((StrContains(map, "lifelostprison_0", false) == 0) || (StrContains(map, "bonus_earlyprison_0", false) == 0))
	{
		Format(modname, sizeof(modname), "Liberation");
	}
	else if ((StrContains(map, "dayhardpart", false) == 0) || (StrEqual(map,"dayhard_menu",false)) || (StrEqual(map,"voyage",false)) || (StrEqual(map,"redrum",false)) || (StrEqual(map,"finale",false)) || (StrEqual(map,"breencave",false)) || (StrEqual(map,"dojo",false)))
	{
		Format(modname, sizeof(modname), "Day Hard");
	}
	else if ((StrContains(map,"mine01_0",false) == 0) || (StrContains(map,"mine_01_0",false) == 0))
	{
		Format(modname, sizeof(modname), "Antlions Everywhere");
	}
	else if ((StrContains(map,"intro0",false) == 0) || (StrContains(map,"mines0",false) == 0) || (StrEqual(map,"sewer01",false)) || (StrContains(map,"scape0",false) == 0) || (StrEqual(map,"ldtd01",false)) || StrEqual(map, "tull01", false) || StrEqual(map, "surreal01", false) || StrEqual(map, "outside01", false) || StrEqual(map, "ending01", false))
	{
		Format(modname, sizeof(modname), "Lost Under The Snow");
	}
	else if ((StrEqual(map,"th_intro",false)) || (StrEqual(map,"drainage",false)) || (StrEqual(map,"church",false)) || (StrEqual(map,"basement",false)) || (StrEqual(map,"cabin",false)) || (StrEqual(map,"cave",false)) || (StrEqual(map,"rift",false)) || (StrEqual(map,"volcano",false)) || (StrEqual(map,"train",false)))
	{
		Format(modname, sizeof(modname), "They Hunger Again");
	}
	else if (StrContains(map,"ep2_deepdown_",false) == 0)
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
	else if (StrContains(map, "bm_c", false) == 0)
	{
		Format(modname, sizeof(modname), "Black Mesa");
	}
	else if ((StrContains(map,"ptsd_",false) == 0) || (StrEqual(map,"boneless_ptsd",false)))
	{
		Format(modname, sizeof(modname), "PTSD");
	}
	else if ((StrEqual(map,"am2",false)) || (StrEqual(map,"am3",false)) || (StrEqual(map,"am4",false)))
	{
		Format(modname, sizeof(modname), "Aftermath");
	}
	else if (StrContains(map,"bm_damo0",false) == 0)
	{
		Format(modname, sizeof(modname), "Black Mesa: Damocles");
	}
	else if ((StrContains(map,"xen_c4a",false) == 0) || (StrEqual(map,"xen_c5a1",false)))
	{
		Format(modname, sizeof(modname), "Black Mesa: Improved Xen");
	}
	else if (StrContains(map,"Penetration0",false) == 0)
	{
		Format(modname, sizeof(modname), "Half-Life 2: Penetration");
	}
	else if (StrContains(map,"sewer",false) == 0)
	{
		Format(modname, sizeof(modname), "The Sewer");
	}
	else if (StrContains(map,"az_c",false) == 0)
	{
		Format(modname, sizeof(modname), "Entropy: Zero");
	}
	else if ((StrContains(map,"Uh_Prologue_",false) == 0) || (StrContains(map,"Uh_Chapter1_",false) == 0) || (StrContains(map,"Uh_Chapter2_",false) == 0) || (StrContains(map,"Uh_House_",false) == 0) || (StrContains(map,"Uh_Dreams_",false) == 0))
	{
		Format(modname, sizeof(modname), "Underhell");
	}
	else
	{
		char gamedesc[32];
		GetGameFolderName(gamedesc,sizeof(gamedesc));
		if (StrEqual(gamedesc,"tf",false))
		{
			Format(maptag, sizeof(maptag), "TF2");
		}
		else
		{
			Format(maptag, sizeof(maptag), "Syn");
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
