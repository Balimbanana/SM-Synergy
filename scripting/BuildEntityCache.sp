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

bool AutoBuild = false;
bool hasreadcache = false;
bool WriteCache = false;
char mapbuf[64];
char curmap[64];

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
	Handle cvar = FindConVar("autobuildcache");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("autobuildcache", "0", "Enable automatic entity cache build on map start if none is found.", _, true, 0.0, true, 1.0);
	AutoBuild = GetConVarBool(cvar);
	HookConVarChange(cvar, autobuildch);
	CloseHandle(cvar);
	RegAdminCmd("buildcache",BuildCacheFor,ADMFLAG_ROOT,"Build the entity cache for specified map. No arguments will do current map.");
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

public void autobuildch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) AutoBuild = true;
	else AutoBuild = false;
}

public Action BuildCacheFor(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	if (args == 0)
	{
		GetCurrentMap(curmap,sizeof(curmap));
		PrintToConsole(client,"Building cache for %s",curmap);
		Format(curmap,sizeof(curmap),"maps/%s.bsp",curmap);
		buildcache(0);
	}
	else
	{
		char specmap[64];
		if (args == 2)
		{
			char tag[16];
			GetCmdArg(1,tag,sizeof(tag));
			GetCmdArg(2,specmap,sizeof(specmap));
			Format(specmap,sizeof(specmap),"%s_%s",tag,specmap);
		}
		else GetCmdArg(1,specmap,sizeof(specmap));
		Format(curmap,sizeof(curmap),"maps/%s.bsp",specmap);
		Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s.ent",specmap);
		if (FileExists(mapbuf,true,NULL_STRING))
		{
			PrintToConsole(client,"Entity cache for map %s already exists.",specmap);
			return Plugin_Handled;
		}
		else if (FileExists(curmap,true,NULL_STRING)) PrintToConsole(client,"Building cache for %s",specmap);
		else
		{
			PrintToConsole(client,"Could not find map: %s",specmap);
			return Plugin_Handled;
		}
		buildcache(0);
	}
	return Plugin_Handled;
}

public void OnMapStart()
{
	if (GetMapHistorySize() > 0)
	{
		GetCurrentMap(curmap,sizeof(curmap));
		Format(curmap,sizeof(curmap),"maps/%s.bsp",curmap);
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
		if (AutoBuild)
		{
			CreateTimer(1.0,buildinfodelay,_,TIMER_FLAG_NO_MAPCHANGE);
		}
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
			if (((strlen(line) > 2) && (StrContains(line,"\"",false) != -1)) || ((StrContains(line,"{",false) != -1) && (strlen(line) < 3)) || ((StrContains(line,"}",false) != -1) && (strlen(line) < 3)))
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
