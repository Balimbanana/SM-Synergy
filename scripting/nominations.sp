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
bool r24m,lcm,ep1m,ep2m,metam,calm,citm,ci7m,upm,ram,dwm,prem,c2am,ep3m,offm,radm,cdm,ntm,opm,mim,smm,s2em,rhm,snm,mprm,cem,mpm,el87m,alm,esm,dfm,stm,btm,llm,dhm,lum,thm,ddm,amm;

#define MAPSTATUS_ENABLED (1<<0)
#define MAPSTATUS_DISABLED (1<<1)
#define MAPSTATUS_EXCLUDE_CURRENT (1<<2)
#define MAPSTATUS_EXCLUDE_PREVIOUS (1<<3)
#define MAPSTATUS_EXCLUDE_NOMINATED (1<<4)

StringMap g_mapTrie = null;
char maptag[64];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	
	int arraySize = ByteCountToCells(33);
	g_MapList = CreateArray(arraySize);
	
	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);
	
	RegConsoleCmd("sm_nominate", Command_Nominate);
	
	RegAdminCmd("sm_nominate_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_nominate_addmap <mapname> - Forces a map to be on the next mapvote.");
	
	g_mapTrie = new StringMap();
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
	char pathtomapcycle[64];
	Format(pathtomapcycle,sizeof(pathtomapcycle),"cfg/mapcyclecfg.txt");
	Handle thishandle = INVALID_HANDLE;
	if (FileExists(pathtomapcycle))
	{
		thishandle = OpenFile(pathtomapcycle,"r");
	}
	else
	{
		thishandle = OpenFile("mapcycle.txt","r");
	}
	char line[32];
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
	
	char mapname[64];
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
	
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	
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
	
	char name[64];
	GetClientName(client, name, sizeof(name));
	char map[64];
	Format(map,sizeof(map),"%s",mapname);
	GetMapTag(map);
	char translate[128];
	Format(translate,sizeof(translate),"[SM] %t","Map Nominated", name, map);
	PrintToChatAll("%s (%s)", translate, maptag);
	
	return Plugin_Continue;
}

public Action AttemptNominate(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	Menu menu = new Menu(MenuHandlersub);
	menu.SetTitle("%T", "Nominate Title", client);
	menu.AddItem("syn", "Synergy/Custom");
	menu.AddItem("half-life 2", "Half-Life 2");
	if (ep1m) menu.AddItem("episode 1", "HL2 Episode 1");
	if (ep2m) menu.AddItem("episode 2", "HL2 Episode 2");
	if (r24m) menu.AddItem("rock 24", "Rock 24");
	if (lcm) menu.AddItem("lost coast", "Lost Coast");
	if (metam) menu.AddItem("minerva", "Minerva: Metastasis");
	if (calm) menu.AddItem("calamity", "Calamity");
	if (citm) menu.AddItem("the citizen returns", "The Citizen Returns");
	if (ci7m) menu.AddItem("city 7: toronto conflict", "City 7: Toronto Conflict");
	if (upm) menu.AddItem("uncertainty principle", "Uncertainty Principle");
	if (ram) menu.AddItem("riot act", "Riot Act");
	if (dwm) menu.AddItem("dangerous world", "Dangerous World");
	if (prem) menu.AddItem("precursor", "Precursor");
	if (c2am) menu.AddItem("coastline to atmosphere", "Coastline To Atmosphere");
	if (ep3m) menu.AddItem("episode 3: the closure", "Episode 3: The Closure");
	if (offm) menu.AddItem("offshore", "Offshore");
	if (radm) menu.AddItem("research & development", "Research & Development");
	if (cdm) menu.AddItem("combine destiny", "Combine Destiny");
	if (ntm) menu.AddItem("neotokyo", "Neotokyo");
	if (opm) menu.AddItem("omega prison", "Omega Prison");
	if (mim) menu.AddItem("mission improbable", "Mission Improbable");
	if (smm) menu.AddItem("strider mountain", "Strider Mountain");
	if (s2em) menu.AddItem("slums 2: extended", "Slums 2: Extended");
	if (rhm) menu.AddItem("ravenholm", "Ravenholm");
	if (snm) menu.AddItem("spherical nightmares", "Spherical Nightmares");
	if (mprm) menu.AddItem("the masked prisoner", "The Masked Prisoner");
	if (cem) menu.AddItem("causality effect", "Causality Effect");
	if (mpm) menu.AddItem("mistake of pythagoras", "Mistake of Pythagoras");
	if (el87m) menu.AddItem("1187", "1187");
	if (alm) menu.AddItem("alchemilla", "Silent Hill: Alchemilla");
	if (esm) menu.AddItem("eye of the storm", "Eye of The Storm");
	if (dfm) menu.AddItem("downfall", "DownFall");
	if (stm) menu.AddItem("steam tracks trouble and riddles", "Steam Tracks Trouble and Riddles");
	if (btm) menu.AddItem("below the ice", "Below The Ice");
	if (llm) menu.AddItem("liberation", "Liberation");
	if (dhm) menu.AddItem("day hard", "Day Hard");
	if (lum) menu.AddItem("lost under the snow", "Lost Under The Snow");
	if (thm) menu.AddItem("they hunger again", "They Hunger Again");
	if (ddm) menu.AddItem("deep down", "Deep Down");
	if (amm) menu.AddItem("aftermath", "Aftermath");
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
			char tmp[64];
			GetArrayString(g_MapList,i,tmp,sizeof(tmp));
			GetMapTag(tmp);
			if (StrContains(info,maptag,false) != -1)
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
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle(menutitle);
	for (int k;k<GetArraySize(tmparr);k++)
	{
		char ktmp[64];
		GetArrayString(tmparr, k, ktmp, sizeof(ktmp));
		int status;
		g_mapTrie.GetValue(ktmp, status);
		if (status & MAPSTATUS_EXCLUDE_CURRENT)
		{
			char ktmpd[64];
			Format(ktmpd,sizeof(ktmpd),"%s (Current Map)",ktmp);
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
		char mapname[64];
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
		
		char name[64];
		GetClientName(param1, name, sizeof(name));
		char map[64];
		Format(map,sizeof(map),"%s",mapname);
		GetMapTag(map);
		char translate[128];
		Format(translate,sizeof(translate),"[SM] %t","Map Nominated", name, map);
		PrintToChatAll("%s (%s)", translate, maptag);
	}
	else if (action == MenuAction_DisplayItem)
	{
		char info[32];
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

	char map[64];
	
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
			if (StrEqual(map, currentMap))
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
			char map[64], name[64];
			menu.GetItem(param2, map, sizeof(map));		
			
			GetClientName(param1, name, 64);
	
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
			char map[64];
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
			char map[64];
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
	if ((StrEqual(map,"d1_overboard_01",false)) || (StrEqual(map,"d1_wakeupcall_02",false)) || (StrEqual(map,"d2_breakout_03",false)) || (StrEqual(map,"d2_surfacing_04",false)) || (StrEqual(map,"d3_theescape_05",false)) || (StrEqual(map,"d3_extraction_06",false)))
	{
		r24m = true;
		Format(maptag, sizeof(maptag), "Rock 24");
	}
	else if (StrContains(map,"d1_",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Half-Life 2");
	}
	else if (StrEqual(map,"d2_lostcoast",false))
	{
		lcm = true;
		Format(maptag, sizeof(maptag), "Lost Coast");
	}
	else if (StrContains(map,"d2_",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Half-Life 2");
	}
	else if (StrContains(map,"d3_",false) == 0)
	{
		Format(maptag, sizeof(maptag), "Half-Life 2");
	}
	else if (StrContains(map,"ep1_",false) == 0)
	{
		ep1m = true;
		Format(maptag, sizeof(maptag), "Episode 1");
	}
	else if (StrContains(map,"ep2_outland_",false) == 0)
	{
		ep2m = true;
		Format(maptag, sizeof(maptag), "Episode 2");
	}
	else if (StrContains(map,"meta",false) == 0)
	{
		metam = true;
		Format(maptag, sizeof(maptag), "Minerva");
	}
	else if (StrContains(map,"sp_c14_",false) == 0)
	{
		calm = true;
		Format(maptag, sizeof(maptag), "Calamity");
	}
	else if (StrContains(map,"sp_",false) == 0)
	{
		citm = true;
		Format(maptag, sizeof(maptag), "The Citizen Returns");
	}
	else if ((StrEqual(map,"mel_lastman_square_f",false)) || (StrEqual(map,"shuter_st_f",false)) || (StrContains(map,"st_michaels_",false) == 0) || (StrEqual(map,"yonge_st_f",false)) || (StrEqual(map,"dundas_square_f",false)) || (StrEqual(map,"subway_system_f",false)))
	{
		ci7m = true;
		Format(maptag, sizeof(maptag), "City 7: Toronto Conflict");
	}
	else if (StrContains(map,"up_",false) == 0)
	{
		upm = true;
		Format(maptag, sizeof(maptag), "Uncertainty Principle");
	}
	else if (StrContains(map,"ra_c1l",false) == 0)
	{
		ram = true;
		Format(maptag, sizeof(maptag), "Riot Act");
	}
	else if (StrContains(map,"dw_",false) == 0)
	{
		dwm = true;
		Format(maptag, sizeof(maptag), "Dangerous World");
	}
	else if (StrContains(map,"r_map",false) == 0)
	{
		prem = true;
		Format(maptag, sizeof(maptag), "Precursor");
	}
	else if ((StrContains(map,"leonhl2",false) == 0) || (StrEqual(map,"final_credits",false)))
	{
		c2am = true;
		Format(maptag, sizeof(maptag), "Coastline To Atmosphere");
	}
	else if (StrContains(map,"spymap_ep3",false) != -1)
	{
		ep3m = true;
		Format(maptag, sizeof(maptag), "Episode 3: The Closure");
	}
	else if (StrContains(map,"island",false) == 0)
	{
		offm = true;
		Format(maptag, sizeof(maptag), "Offshore");
	}
	else if (StrContains(map,"level_",false) == 0)
	{
		radm = true;
		Format(maptag, sizeof(maptag), "Research & Development");
	}
	else if (StrContains(map,"cd",false) == 0)
	{
		cdm = true;
		Format(maptag, sizeof(maptag), "Combine Destiny");
	}
	else if (StrContains(map,"nt_",false) == 0)
	{
		ntm = true;
		Format(maptag, sizeof(maptag), "Neotokyo");
	}
	else if (StrContains(map,"po_",false) == 0)
	{
		opm = true;
		Format(maptag, sizeof(maptag), "Omega Prison");
	}
	else if (StrContains(map,"mimp",false) == 0)
	{
		mim = true;
		Format(maptag, sizeof(maptag), "Mission Improbable");
	}
	else if (StrContains(map,"_sm_",false) != -1)
	{
		smm = true;
		Format(maptag, sizeof(maptag), "Strider Mountain");
	}
	else if (StrContains(map,"slums_",false) == 0)
	{
		s2em = true;
		Format(maptag, sizeof(maptag), "Slums 2: Extended");
	}
	else if (StrContains(map,"ravenholm",false) == 0)
	{
		rhm = true;
		Format(maptag, sizeof(maptag), "Ravenholm");
	}
	else if (StrContains(map,"sn_",false) == 0)
	{
		snm = true;
		Format(maptag, sizeof(maptag), "Spherical Nightmares");
	}
	else if (StrContains(map,"ks_mop_",false) == 0)
	{
		mpm = true;
		Format(maptag, sizeof(maptag), "Mistake of Pythagoras");
	}
	else if (StrContains(map,"ce_0",false) == 0)
	{
		cem = true;
		Format(maptag, sizeof(maptag), "Causality Effect");
	}
	else if (StrContains(map,"1187",false) == 0)
	{
		el87m = true;
		Format(maptag, sizeof(maptag), "1187");
	}
	else if (StrContains(map,"sh_alchemilla",false) == 0)
	{
		alm = true;
		Format(maptag, sizeof(maptag), "Silent Hill: Alchemilla");
	}
	else if (StrContains(map,"eots_1",false) == 0)
	{
		esm = true;
		Format(maptag, sizeof(maptag), "Eye of The Storm");
	}
	else if (StrContains(map,"mpr_0",false) == 0)
	{
		mprm = true;
		Format(maptag, sizeof(maptag), "The Masked Prisoner");
	}
	else if (StrContains(map, "dwn0", false) == 0)
	{
		dfm = true;
		Format(maptag, sizeof(maptag), "DownFall");
	}
	else if (StrContains(map, "sttr_ch", false) == 0)
	{
		stm = true;
		Format(maptag, sizeof(maptag), "Steam Tracks Trouble and Riddles");
	}
	else if ((StrContains(map, "belowice", false) == 0) || (StrEqual(map,"memory",false)))
	{
		btm = true;
		Format(maptag, sizeof(maptag), "Below The Ice");
	}
	else if ((StrContains(map, "lifelostprison_0", false) == 0) || (StrContains(map, "bonus_earlyprison_0", false) == 0))
	{
		llm = true;
		Format(maptag, sizeof(maptag), "Liberation");
	}
	else if ((StrContains(map, "dayhardpart", false) == 0) || (StrEqual(map,"dayhard_menu",false)) || (StrEqual(map,"voyage",false)) || (StrEqual(map,"redrum",false)) || (StrEqual(map,"finale",false)) || (StrEqual(map,"breencave",false)) || (StrEqual(map,"dojo",false)))
	{
		dhm = true;
		Format(maptag, sizeof(maptag), "Day Hard");
	}
	else if ((StrContains(map,"intro0",false) == 0) || (StrContains(map,"mines0",false) == 0) || (StrEqual(map,"sewer01",false)) || (StrContains(map,"scape0",false) == 0) || (StrEqual(map,"ldtd01",false)) || StrEqual(map, "tull01", false) || StrEqual(map, "surreal01", false) || StrEqual(map, "outside01", false) || StrEqual(map, "ending01", false))
	{
		lum = true;
		Format(maptag, sizeof(maptag), "Lost Under The Snow");
	}
	else if ((StrEqual(map,"th_intro",false)) || (StrEqual(map,"drainage",false)) || (StrEqual(map,"church",false)) || (StrEqual(map,"basement",false)) || (StrEqual(map,"cabin",false)) || (StrEqual(map,"cave",false)) || (StrEqual(map,"rift",false)) || (StrEqual(map,"volcano",false)) || (StrEqual(map,"train",false)))
	{
		thm = true;
		Format(maptag, sizeof(maptag), "They Hunger Again");
	}
	else if (StrContains(map,"ep2_deepdown_",false) == 0)
	{
		ddm = true;
		Format(maptag, sizeof(maptag), "Deep Down");
	}
	else if ((StrEqual(map,"am2",false)) || (StrEqual(map,"am3",false)) || (StrEqual(map,"am4",false)))
	{
		amm = true;
		Format(maptag, sizeof(maptag), "Aftermath");
	}
	else
	{
		Format(maptag, sizeof(maptag), "Syn");
	}
}
