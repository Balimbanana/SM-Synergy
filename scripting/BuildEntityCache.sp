#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "0.1"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/buildentitycache.txt"

bool hasreadcache = false;
bool WriteCache = false;
char mapbuf[64];

public Plugin myinfo =
{
	name = "BuildEntityCache",
	author = "Balimbanana",
	description = "Builds the entity cache of the current map for use in other plugins and entity input hooking.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	
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

public void OnMapStart()
{
	if (GetMapHistorySize() > 0)
	{
		GetCurrentMap(mapbuf,sizeof(mapbuf));
		char contentdata[64];
		Handle cvar = FindConVar("content_metadata");
		if (cvar != INVALID_HANDLE)
		{
			GetConVarString(cvar,contentdata,sizeof(contentdata));
			char fixuptmp[16][16];
			ExplodeString(contentdata," ",fixuptmp,16,16,true);
			Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		}
		CloseHandle(cvar);
		if (strlen(contentdata) < 1) Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s.ent",mapbuf);
		else Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s_%s.ent",contentdata,mapbuf);
		Handle mdirlisting = OpenDirectory("maps/ent_cachebuilt", false);
		if (mdirlisting == INVALID_HANDLE)
		{
			CreateDirectory("maps/ent_cache",511);
		}
		CloseHandle(mdirlisting);
		hasreadcache = false;
		CreateTimer(1.0,buildinfodelay,_,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action buildinfodelay(Handle timer)
{
	if (!FileExists(mapbuf,true,NULL_STRING))
	{
		PrintToServer("\n\n\nStart building entity cache\nThis may take a while...\n\n\n");
		buildcache(0);
	}
	return Plugin_Handled;
}

void buildcache(int startline)
{
	if (hasreadcache) return;
	char curmap[64];
	GetCurrentMap(curmap,sizeof(curmap));
	Format(curmap,sizeof(curmap),"maps/%s.bsp",curmap);
	Handle cachefile = INVALID_HANDLE;
	if (startline == 0) cachefile = OpenFile(mapbuf,"w");
	else cachefile = OpenFile(mapbuf,"a");
	Handle filehandle = OpenFile(curmap,"rb",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		if (startline != 0) FileSeek(filehandle,startline,SEEK_SET);
		char line[256];
		int nextline = 0;
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			if ((nextline >= 25000) && (!WriteCache))
			{
				startline = FilePosition(filehandle);
				CreateTimer(0.1,nextlines,startline,TIMER_FLAG_NO_MAPCHANGE);
				break;
			}
			nextline++;
			if (((strlen(line) > 2) && (StrContains(line,"\"",false) != -1)) || (StrContains(line,"{",false) != -1) || ((StrContains(line,"}",false) != -1) && (strlen(line) < 3)))
			{
				if ((StrContains(line,"\"world_maxs\"",false) == 0) && (!WriteCache))
				{
					PrintToServer("Found first line of entity cache");
					WriteCache = true;
					startline = FilePosition(filehandle)-strlen(line)-2;
					CreateTimer(0.1,nextlines,startline,TIMER_FLAG_NO_MAPCHANGE);
					break;
				}
				else if (WriteCache)
				{
					TrimString(line);
					if ((StrContains(line,"┬",false) != -1) || (StrContains(line,"Ÿ",false) != -1) || (StrContains(line,"{~") == 0) || (StrContains(line,"<",false) != -1) || (StrContains(line,">",false) != -1) || (StrContains(line,"Å",false) != -1) || (StrContains(line,"ÿ",false) != -1) || (StrContains(line,"┼",false) != -1) || (StrContains(line,"",false) != -1))
					{
						WriteCache = false;
						PrintToServer("Finished writing cache %s",mapbuf);
						hasreadcache = true;
						break;
					}
					else
					{
						WriteFileLine(cachefile,line);
					}
				}
			}
		}
	}
	CloseHandle(cachefile);
	CloseHandle(filehandle);
}

public Action nextlines(Handle timer, int startline)
{
	buildcache(startline);
}