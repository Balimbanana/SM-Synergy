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
#pragma dynamic 2097152;

#define PLUGIN_VERSION "0.41"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/buildentitycache.txt"

bool AutoBuild = false;
bool startedreading = false;
bool WriteCache = false;
bool Reverse = false;
char mapbuf[64];
char curmap[64];
char globaldots[48];
int openbrackets = 0;

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
	RegAdminCmd("buildedt",BuildEDTFor,ADMFLAG_ROOT,"Build a template EDT using some info provided by entity cache.");
	RegAdminCmd("buildloader",BuildLoaderFor,ADMFLAG_ROOT,"Build a content loader for a specified sourcemod.");
	RegAdminCmd("buildantirush",BuildAntirush,ADMFLAG_ROOT,"Build antirush in EDT using some info provided by the current map.");
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
		openbrackets = 0;
		buildcache(0,INVALID_HANDLE);
	}
	else
	{
		char specmap[64];
		if (args == 2)
		{
			char tag[16];
			GetCmdArg(1,tag,sizeof(tag));
			GetCmdArg(2,specmap,sizeof(specmap));
			Format(curmap,sizeof(curmap),"maps/%s.bsp",specmap);
			Format(specmap,sizeof(specmap),"%s_%s",tag,specmap);
		}
		else
		{
			GetCmdArg(1,specmap,sizeof(specmap));
			Format(curmap,sizeof(curmap),"maps/%s.bsp",specmap);
		}
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
		openbrackets = 0;
		buildcache(0,INVALID_HANDLE);
	}
	return Plugin_Handled;
}

public Action BuildAntirush(int client, int args)
{
	Handle changelevels = CreateArray(8);
	for (int i = MaxClients+1;i<2048;i++)
	{
		if (IsValidEntity(i))
		{
			if (IsEntNetworkable(i))
			{
				char cls[32];
				GetEntityClassname(i,cls,sizeof(cls));
				if (StrEqual(cls,"trigger_changelevel",false))
				{
					PushArrayCell(changelevels,i);
				}
				if (HasEntProp(i,Prop_Data,"m_iName"))
				{
					char targn[64];
					GetEntPropString(i,Prop_Data,"m_iName",targn,sizeof(targn));
					if (StrContains(targn,"syn_antirush",false) != -1)
					{
						PrintToConsole(client,"Antirush already exists on current map");
						CloseHandle(changelevels);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	if (GetArraySize(changelevels) > 0)
	{
		char mapname[72];
		GetCurrentMap(mapname,sizeof(mapname));
		Format(mapname,sizeof(mapname),"maps/%s.edt",mapname);
		if (FileExists(mapname,true,NULL_STRING))
		{
			Handle filecontentsarray = CreateArray(1024);
			char line[128];
			Handle filehandle = OpenFile(mapname,"r",true,NULL_STRING);
			while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
			{
				if (StrContains(line,"\"syn_antirush_",false) != -1)
				{
					PrintToConsole(client,"Antirush already exists in EDT, you may need to restart the map for it to take effect.");
					CloseHandle(changelevels);
					CloseHandle(filecontentsarray);
					CloseHandle(filehandle);
					return Plugin_Handled;
				}
				//TrimString will remove blank spaces and tabs.
				//But without it, newlines are also appended.
				int numtabs = 0;
				int tabs = StrContains(line,"	",false);
				if (tabs != -1)
				{
					numtabs = 1;
					while (tabs == 0)
					{
						tabs = StrContains(line[tabs+numtabs],"	",false);
						if (tabs == 0) numtabs++;
					}
				}
				TrimString(line);
				for (int i = 0;i<numtabs;i++)
				{
					Format(line,sizeof(line),"	%s",line);
				}
				PushArrayString(filecontentsarray,line);
			}
			CloseHandle(filehandle);
			if (GetArraySize(filecontentsarray) > 2)
			{
				RemoveFromArray(filecontentsarray,GetArraySize(filecontentsarray)-1);
				RemoveFromArray(filecontentsarray,GetArraySize(filecontentsarray)-1);
				filehandle = OpenFile(mapname,"w",true,NULL_STRING);
				for (int i = 0;i<GetArraySize(filecontentsarray);i++)
				{
					GetArrayString(filecontentsarray,i,line,sizeof(line));
					WriteFileLine(filehandle,line);
				}
				for (int j = 0;j<GetArraySize(changelevels);j++)
				{
					int i = GetArrayCell(changelevels,j);
					if (IsValidEntity(i))
					{
						float mins[3];
						float maxs[3];
						GetEntPropVector(i,Prop_Data,"m_vecMins",mins);
						GetEntPropVector(i,Prop_Data,"m_vecMaxs",maxs);
						float actualmaxs[3];
						float actualmins[3];
						actualmaxs[0] = maxs[0]-mins[0];
						actualmaxs[1] = maxs[1]-mins[1];
						actualmaxs[2] = maxs[2]-mins[2];
						actualmins[0] = mins[0]-maxs[0];
						actualmins[1] = mins[1]-maxs[1];
						actualmins[2] = mins[2]-maxs[2];
						float position[3];
						position[0] = mins[0]+(actualmaxs[0]/2);
						position[1] = mins[1]+(actualmaxs[1]/2);
						position[2] = mins[2]+(actualmaxs[2]/2);
						int sf = GetEntProp(i,Prop_Data,"m_spawnflags");
						if (!(sf & 2)) //Includes spawnflags 2 and 4 if not by <<
						{
							char changelevelmdl[32];
							GetEntPropString(i,Prop_Data,"m_ModelName",changelevelmdl,sizeof(changelevelmdl));
							PrintToConsole(client,"trigger_changelevel Position %1.f %1.f %1.f Maxs %1.f %1.f %1.f Mins %1.f %1.f %1.f",position[0],position[1],position[2],actualmaxs[0],actualmaxs[1],actualmaxs[2],actualmins[0],actualmins[1],actualmins[2]);
							WriteFileLine(filehandle,"		create {classname \"trigger_coop\" origin \"%1.f %1.f %1.f\"",position[0],position[1],position[2]);
							WriteFileLine(filehandle,"			values");
							WriteFileLine(filehandle,"			{");
							WriteFileLine(filehandle,"				targetname \"syn_antirush_coop%i\"",j);
							WriteFileLine(filehandle,"				spawnflags \"1\"");
							WriteFileLine(filehandle,"				edt_mins \"%1.f %1.f %1.f\"",actualmins[0]*1.5,actualmins[1]*1.5,actualmins[2]*1.5);
							WriteFileLine(filehandle,"				edt_maxs \"%1.f %1.f %1.f\"",actualmaxs[0]*1.5,actualmaxs[1]*1.5,actualmaxs[2]*1.5);
							WriteFileLine(filehandle,"				UseHud \"1\"");
							WriteFileLine(filehandle,"				CountType \"1\"");
							WriteFileLine(filehandle,"				PlayerValue \"66\"");
							WriteFileLine(filehandle,"				OnPlayersIn \"syn_antirush_block%i,kill,,0,-1\"",j);
							WriteFileLine(filehandle,"				OnPlayersIn \"!self,kill,,0.1,-1\"");
							WriteFileLine(filehandle,"			}");
							WriteFileLine(filehandle,"		}");
							WriteFileLine(filehandle,"		create {classname \"func_brush\" origin \"0 0 0\"");
							WriteFileLine(filehandle,"			values");
							WriteFileLine(filehandle,"			{");
							WriteFileLine(filehandle,"				targetname \"syn_antirush_block%i\"",j);
							WriteFileLine(filehandle,"				spawnflags \"2\"");
							WriteFileLine(filehandle,"				Solidity \"2\"");
							WriteFileLine(filehandle,"				solidbsp \"1\"");
							WriteFileLine(filehandle,"				edt_mins \"%1.f %1.f %1.f\"",actualmins[0],actualmins[1],actualmins[2]);
							WriteFileLine(filehandle,"				edt_maxs \"%1.f %1.f %1.f\"",actualmaxs[0],actualmaxs[1],actualmaxs[2]);
							WriteFileLine(filehandle,"				model \"%s\"",changelevelmdl);
							WriteFileLine(filehandle,"				RenderMode \"10\"");
							WriteFileLine(filehandle,"				RenderFX \"6\"");
							WriteFileLine(filehandle,"			}");
							WriteFileLine(filehandle,"		}");
						}
					}
				}
				WriteFileLine(filehandle,"	}");
				WriteFileLine(filehandle,"}");
				CloseHandle(filehandle);
			}
			CloseHandle(filecontentsarray);
		}
		else
		{
			PrintToConsole(client,"Could not find EDT of current map");
		}
	}
	else PrintToConsole(client,"Could not find any trigger_changelevel's on current map");
	CloseHandle(changelevels);
	return Plugin_Handled;
}

public Action BuildEDTFor(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	char spec[64];
	char edtmap[64];
	char cachepath[64];
	if (args > 1)
	{
		GetCmdArg(1,spec,sizeof(spec));
		char content[32];
		GetCmdArg(2,content,sizeof(content));
		if (StrEqual(spec,"all",false))
		{
			char contentdat[64];
			Format(contentdat,sizeof(contentdat),"content/%s.dat",content);
			if (FileExists(contentdat,true,NULL_STRING))
			{
				Handle curmappass = CreateDataPack();
				bool foundmaps = false;
				bool readuntilnext = false;
				char maptag[32];
				char modpath[128];
				Format(modpath,sizeof(modpath),"..\\sourcemods");
				char line[128];
				Handle filehandle = OpenFile(contentdat,"r",true,NULL_STRING);
				if (filehandle != INVALID_HANDLE)
				{
					while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
					{
						TrimString(line);
						if (StrContains(line,"tag",false) != -1)
						{
							ReplaceString(line,sizeof(line),"	","");
							char fixuptmp[4][16];
							ExplodeString(line,"\"\"",fixuptmp,4,16,true);
							Format(maptag,sizeof(maptag),"%s",fixuptmp[1]);
							ReplaceString(maptag,sizeof(maptag),"\"","");
							PrintToServer("Found tag %s",maptag);
						}
						else if (StrContains(line,"root",false) != -1)
						{
							ReplaceString(line,sizeof(line),"	","");
							char fixuptmp[4][64];
							ExplodeString(line,"\"\"",fixuptmp,4,64,true);
							Format(modpath,sizeof(modpath),"%s",fixuptmp[1]);
						}
						else if (StrContains(line,"path",false) != -1)
						{
							ReplaceString(line,sizeof(line),"	","");
							char fixuptmp[4][64];
							ExplodeString(line,"\"\"",fixuptmp,4,64,true);
							Format(modpath,sizeof(modpath),"..\\..\\%s\\%s\\maps",modpath,fixuptmp[1]);
							ReplaceString(modpath,sizeof(modpath),"\"","");
							if (DirExists(modpath,true,NULL_STRING))
							{
								PrintToServer("Found path %s",modpath);
							}
							else
							{
								PrintToServer("Could not find mod at path %s",modpath);
							}
						}
						else if (StrContains(line,"maps",false) != -1)
						{
							readuntilnext = true;
						}
						else if (readuntilnext)
						{
							if (StrContains(line,"}",false) != -1) break;
							else if (StrContains(line,"{",false) == -1)
							{
								ReplaceString(line,sizeof(line),"	","");
								ReplaceString(line,sizeof(line),"\"","");
								if (StrContains(line,"//",false) != 0)
								{
									int commentpos = StrContains(line,"//",false);
									if (commentpos != -1)
									{
										Format(line,commentpos+1,"%s",line);
									}
									foundmaps = true;
									char write[128];
									char readpath[128];
									Format(readpath,sizeof(readpath),"%s\\%s.bsp",modpath,line);
									if (FileExists(readpath,true,NULL_STRING))
									{
										if (FileSize(readpath,true,NULL_STRING) > 1)
										{
											PrintToServer("Readmap %s",line);
											Format(write,sizeof(write),"maps/ent_cache/%s_%s.ent",maptag,line);
											WritePackString(curmappass,write);
											WritePackString(curmappass,readpath);
										}
										else PrintToServer("Skip empty map %s",line);
									}
									else
									{
										PrintToServer("Could not find map %s",line);
									}
								}
							}
						}
					}
				}
				CloseHandle(filehandle);
				if (foundmaps)
				{
					//Format(curmap,sizeof(curmap),"%s\\%s.bsp",modpath,mapbuf);
					//Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s_%s.ent",maptag,mapbuf);
					WritePackString(curmappass,"endofpack");
					ResetPack(curmappass);
					if (curmappass != INVALID_HANDLE)
					{
						ReadPackString(curmappass,mapbuf,sizeof(mapbuf));
						if (!StrEqual(mapbuf,"endofpack",false))
						{
							globaldots = "";
							Reverse = false;
							ReadPackString(curmappass,curmap,sizeof(curmap));
							PrintToServer("WriteTo %s\nRead %s",mapbuf,curmap);
							buildcache(0,curmappass);
						}
						else CloseHandle(curmappass);
					}
				}
				else CloseHandle(curmappass);
			}
			return Plugin_Handled;
		}
		else
		{
			char contentdata[16];
			GetCmdArg(1,contentdata,sizeof(contentdata));
			GetCmdArg(2,edtmap,sizeof(edtmap));
			Format(cachepath,sizeof(cachepath),"maps/ent_cache/%s_%s.ent",contentdata,edtmap);
		}
	}
	else if (args == 1)
	{
		GetCmdArg(1,edtmap,sizeof(edtmap));
		Format(cachepath,sizeof(cachepath),"maps/ent_cache/%s.ent",edtmap);
	}
	else
	{
		GetCurrentMap(edtmap,sizeof(edtmap));
		char contentdata[64];
		Handle cvar = FindConVar("content_metadata");
		if (cvar != INVALID_HANDLE)
		{
			GetConVarString(cvar,contentdata,sizeof(contentdata));
			char fixuptmp[4][16];
			ExplodeString(contentdata," ",fixuptmp,4,16,true);
			Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		}
		CloseHandle(cvar);
		if (strlen(contentdata) < 1) Format(cachepath,sizeof(cachepath),"maps/ent_cache/%s.ent",edtmap);
		else Format(cachepath,sizeof(cachepath),"maps/ent_cache/%s_%s.ent",contentdata,edtmap);
	}
	if (FileExists(cachepath,true,NULL_STRING))
	{
		ReadCache(cachepath,edtmap);
	}
	else
	{
		PrintToConsole(client,"Unable to find entity cache, you may need to build the cache first.");
	}
	return Plugin_Handled;
}

public Action BuildLoaderFor(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	if (args < 3)
	{
		PrintToConsole(client,"Syntax: buildloader <contenttag> <loaderfilename> <sourcemods directory>");
		return Plugin_Handled;
	}
	if (args >= 3)
	{
		char newtag[16];
		char loadername[32];
		char sourcemodpath[128];
		char sourcemod[64];
		char titlepath[128];
		char gameurl[72];
		char deps[32];
		GetCmdArg(1,newtag,sizeof(newtag));
		GetCmdArg(2,loadername,sizeof(loadername));
		GetCmdArg(3,sourcemod,sizeof(sourcemod));
		Format(loadername,sizeof(loadername),"content/%s.dat",loadername);
		if (FileExists(loadername,true,NULL_STRING))
		{
			PrintToConsole(client,"Loader %s already exists",loadername);
			return Plugin_Handled;
		}
		Format(titlepath,sizeof(titlepath),"..\\..\\..\\sourcemods\\%s\\gameinfo.txt",sourcemod);
		Format(sourcemodpath,sizeof(sourcemodpath),"..\\..\\..\\sourcemods\\%s\\maps",sourcemod);
		if (!DirExists(sourcemodpath,true,NULL_STRING))
		{
			PrintToConsole(client,"Could not determine sourcemod path");
			return Plugin_Handled;
		}
		if (FileExists(titlepath,true,NULL_STRING))
		{
			char line[128];
			Handle filehandle = OpenFile(titlepath,"r",true,NULL_STRING);
			if (filehandle != INVALID_HANDLE)
			{
				bool readdeps = false;
				bool foundname = false;
				bool foundurl = false;
				while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
				{
					TrimString(line);
					if (StrContains(line,"//",false) != 0)
					{
						if ((StrContains(line,"game",false) != -1) && (StrContains(line,"gameinfo",false) == -1) && (!foundname))
						{
							ReplaceString(line,sizeof(line),"	","");
							ReplaceString(line,sizeof(line),"game","");
							ReplaceString(line,sizeof(line),"\"","");
							TrimString(line);
							Format(titlepath,sizeof(titlepath),"%s",line);
							foundname = true;
						}
						else if ((StrContains(line,"developer_url",false) != -1) && (!foundurl))
						{
							ReplaceString(line,sizeof(line),"	","");
							ReplaceString(line,sizeof(line),"developer_url","");
							ReplaceString(line,sizeof(line),"\"","");
							Format(gameurl,sizeof(gameurl),"%s",line);
							foundurl = true;
						}
						else if (StrContains(line,"SearchPaths",false) != -1)
						{
							readdeps = true;
						}
						else if (readdeps)
						{
							if (StrContains(line,"ep2",false) != -1)
							{
								Format(deps,sizeof(deps),"ep2 ep1");
								readdeps = false;
							}
							else if (StrContains(line,"episodic",false) != -1)
							{
								if (strlen(deps) < 1) Format(deps,sizeof(deps),"ep1");
							}
						}
					}
				}
			}
			CloseHandle(filehandle);
		}
		Handle regularmaps = CreateArray(64);
		Handle backgroundmaps = CreateArray(32);
		Handle mdirlisting = OpenDirectory(sourcemodpath,true,NULL_STRING);
		if (mdirlisting != INVALID_HANDLE)
		{
			char buff[64];
			while (ReadDirEntry(mdirlisting, buff, sizeof(buff)))
			{
				if ((!(mdirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
				{
					if ((!(StrContains(buff, ".ztmp", false) != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
					{
						if (StrContains(buff,".bsp",false) != -1)
						{
							if ((StrContains(buff,"background",false) != -1) || (StrContains(buff,"loading",false) != -1))
							{
								ReplaceString(buff,sizeof(buff),".bsp","");
								PrintToConsole(client,"Found backgroundmap %s",buff);
								PushArrayString(backgroundmaps,buff);
							}
							else if (StrContains(buff,"test_",false) != -1)
							{
								ReplaceString(buff,sizeof(buff),".bsp","");
								PrintToConsole(client,"Found testmap %s",buff);
								Format(buff,sizeof(buff),"//%s",buff);
								PushArrayString(regularmaps,buff);
							}
							else
							{
								ReplaceString(buff,sizeof(buff),".bsp","");
								PrintToConsole(client,"Found map %s",buff);
								PushArrayString(regularmaps,buff);
							}
						}
					}
				}
			}
		}
		CloseHandle(mdirlisting);
		PrintToConsole(client,"Create loader %s gamename %s contenttag %s dependencies of %s",loadername,titlepath,newtag,deps);
		Handle loaderdat = OpenFile(loadername,"w");
		if (loaderdat != INVALID_HANDLE)
		{
			WriteFileLine(loaderdat,"\"%s\"",titlepath);
			WriteFileLine(loaderdat,"{");
			WriteFileLine(loaderdat,"	\"tag\"	\"%s\"",newtag);
			WriteFileLine(loaderdat,"	\"web\"	\"%s\"",gameurl);
			WriteFileLine(loaderdat,"	\"path\"	\"%s\"",sourcemod);
			WriteFileLine(loaderdat,"	\"sup\"	\"2\"");
			if (strlen(deps) > 1) WriteFileLine(loaderdat,"	\"deps\"	\"%s\"",deps);
			WriteFileLine(loaderdat,"	");
			WriteFileLine(loaderdat,"	\"maps\"");
			WriteFileLine(loaderdat,"	{");
			for (int i = 0;i<GetArraySize(regularmaps);i++)
			{
				char mapname[64];
				GetArrayString(regularmaps,i,mapname,sizeof(mapname));
				WriteFileLine(loaderdat,"		%s		\"\"",mapname);
			}
			WriteFileLine(loaderdat,"	}");
			if (GetArraySize(backgroundmaps) > 0)
			{
				WriteFileLine(loaderdat,"	");
				WriteFileLine(loaderdat,"	\"maps_background\"");
				WriteFileLine(loaderdat,"	{");
				for (int i = 0;i<GetArraySize(backgroundmaps);i++)
				{
					char mapname[64];
					GetArrayString(backgroundmaps,i,mapname,sizeof(mapname));
					WriteFileLine(loaderdat,"		%s		\"\"",mapname);
				}
				WriteFileLine(loaderdat,"	}");
			}
			WriteFileLine(loaderdat,"}");
		}
		CloseHandle(loaderdat);
		CloseHandle(regularmaps);
		CloseHandle(backgroundmaps);
	}
	return Plugin_Handled;
}

public Action ReadCacheDelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char cache[64];
		char mapedt[64];
		ReadPackString(dp,cache,sizeof(cache));
		ReadPackString(dp,mapedt,sizeof(mapedt));
		CloseHandle(dp);
		ReadCache(cache,mapedt);
	}
}

void ReadCache(char[] cache, char[] mapedt)
{
	char edtfilepath[64];
	Format(edtfilepath,sizeof(edtfilepath),"maps/%s.edt",mapedt);
	if (FileExists(edtfilepath))
	{
		PrintToServer("EDT %s already exists",edtfilepath);
		return;
	}
	Handle edtfile = OpenFile(edtfilepath,"w");
	if (edtfile != INVALID_HANDLE)
	{
		WriteFileLine(edtfile,"%s",mapedt);
		WriteFileLine(edtfile,"{");
		WriteFileLine(edtfile,"	entity");
		WriteFileLine(edtfile,"	{");
		WriteFileLine(edtfile,"		delete {classname \"info_player_start\"}");
		WriteFileLine(edtfile,"		edit {classname \"game_text\" values {spawnflags \"1\"} }");
		WriteFileLine(edtfile,"		edit {classname \"func_areaportal\" values {targetname \"disabledPortal\" StartOpen \"1\"} }");
		WriteFileLine(edtfile,"		edit {classname \"point_viewcontrol\" values {edt_addedspawnflags \"128\"} }");
		WriteFileLine(edtfile,"		create {classname \"info_spawn_manager\" values {targetname \"syn_spawn_manager\"} }");
	}
	Handle filehandle = OpenFile(cache,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		char line[172];
		char origin[64];
		char originalorgs[64];
		char angs[64];
		char cls[48];
		int spawns = 0;
		int vehiclespawns = 0;
		float orgpos[3];
		bool ismain = false;
		bool WriteEnt = false;
		Handle itemsarr = CreateArray(64);
		Handle logicautos = CreateArray(64);
		Handle hudtimer = CreateArray(64);
		Handle mainspawn = CreateArray(64);
		Handle passedarr = CreateArray(64);
		Handle equipsarrays = CreateArray(64);
		Handle mapremovals = CreateArray(64);
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line,"\"classname\"",false) == 0)
			{
				char clschk[172];
				Format(clschk,sizeof(clschk),line);
				char kvs[4][128];
				ExplodeString(clschk, "\"", kvs, 4, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[3],sizeof(kvs[]),"\"","",false);
				Format(cls,sizeof(cls),"%s",kvs[3]);
				if ((StrEqual(kvs[3],"info_player_start")) || (StrEqual(kvs[3],"logic_auto",false)) || (StrEqual(kvs[3],"prop_vehicle_jeep",false)) || (StrEqual(kvs[3],"prop_vehicle_airboat",false)) || (StrContains(kvs[3],"weapon_",false) == 0) || (StrContains(kvs[3],"item_",false) == 0))
				{
					WriteEnt = true;
				}
			}
			if ((!StrEqual(line,"}",false)) || (!StrEqual(line,"{",false)) || (!StrEqual(line,"}{",false)))
			{
				char kvs[128][128];
				char lineedt[256];
				Format(lineedt,sizeof(lineedt),line);
				ExplodeString(lineedt, "\"", kvs, 128, 128, true);
				ReplaceString(kvs[0],sizeof(kvs[]),"\"","",false);
				ReplaceString(kvs[1],sizeof(kvs[]),"\"","",false);
				Format(lineedt,sizeof(lineedt),"%s \"%s\"",kvs[1],kvs[3]);
				if (((StrContains(line,",Lock,,",false) != -1) || (StrContains(line,",Reload,,",false) != -1)) && (!StrEqual(cls,"logic_auto",false)) && (!StrEqual(cls,"hud_timer",false)) && (!WriteEnt))
				{
					WriteEnt = true;
					char deletion[128];
					if (StrContains(line,",Reload,,",false) != -1)
					{
						Format(deletion,sizeof(deletion),"		delete {classname \"%s\" %s}//Entity contains Reload Input",cls,origin);
						StrCat(lineedt,sizeof(lineedt),"//May need to edit this Reload");
					}
					else if (StrContains(line,",Lock,,",false) != -1)
					{
						Format(deletion,sizeof(deletion),"		delete {classname \"%s\" %s}//Entity contains Lock Input",cls,origin);
						StrCat(lineedt,sizeof(lineedt),"//May need to edit this Lock");
					}
					WriteFileLine(edtfile,deletion);
					
				}
				if ((strlen(kvs[1]) > 0) && (!StrEqual(kvs[1],"classname",false)))
				{
					if (StrContains(kvs[1],"angles",false) == 0)
					{
						Format(angs,sizeof(angs),"%s",lineedt);
					}
					if (StrContains(line,"\"origin\"",false) == 0)
					{
						Format(origin,sizeof(origin),"%s",lineedt);
					}
					else if (StrContains(line,"\"hammerid\"",false) == -1)
					{
						PushArrayString(passedarr,lineedt);
					}
				}
			}
			if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false) || (StrEqual(line,"}{",false))))
			{
				if (!WriteEnt)
				{
					ClearArray(passedarr);
				}
				else
				{
					if (StrEqual(cls,"logic_auto",false))
					{
						for (int i = 0;i<GetArraySize(passedarr);i++)
						{
							char tmparr[128];
							GetArrayString(passedarr,i,tmparr,sizeof(tmparr));
							if (StrContains(tmparr,"spawnflags",false) == -1)
							{
								if (FindStringInArray(hudtimer,tmparr) == -1) PushArrayString(hudtimer,tmparr);
							}
						}
						char deletion[72];
						Format(deletion,sizeof(deletion),"logic_auto\" %s}//Replaced in hud_timer",origin);
						if (FindStringInArray(mapremovals,deletion) == -1) PushArrayString(mapremovals,deletion);
					}
					else
					{
						if (StrEqual(cls,"prop_vehicle_jeep",false))
						{
							Format(cls,sizeof(cls),"info_vehicle_spawn");
							
							PushArrayString(passedarr,"VehicleType \"4\"");
							PushArrayString(passedarr,"VehicleSize \"192\"");
							PushArrayString(passedarr,"StartEnabled \"1\"");
							PushArrayString(passedarr,"StartGunEnabled \"1\"");
						}
						else if (StrEqual(cls,"prop_vehicle_airboat",false))
						{
							Format(cls,sizeof(cls),"info_vehicle_spawn");
							PushArrayString(passedarr,"VehicleType \"2\"");
							PushArrayString(passedarr,"VehicleSize \"192\"");
							PushArrayString(passedarr,"StartEnabled \"1\"");
							PushArrayString(passedarr,"StartGunEnabled \"1\"");
						}
						if (StrEqual(cls,"info_player_start",false))
						{
							Format(cls,sizeof(cls),"info_player_coop");
							for (int i = 0;i<GetArraySize(passedarr);i++)
							{
								char tmparr[128];
								GetArrayString(passedarr,i,tmparr,sizeof(tmparr));
								if (StrContains(tmparr,"spawnflags",false) == 0)
								{
									ReplaceStringEx(tmparr,sizeof(tmparr),"spawnflags \"","");
									ReplaceStringEx(tmparr,sizeof(tmparr),"\"","");
									if (StrEqual(tmparr,"1",false)) ismain = true;
								}
							}
							if (ismain)
							{
								Format(originalorgs,sizeof(originalorgs),origin);
								ClearArray(mainspawn);
								char spawnpoints[64];
								if (spawns < 10) Format(spawnpoints,sizeof(spawnpoints),"targetname \"syn_spawnpoint_0%i\"",spawns);
								else Format(spawnpoints,sizeof(spawnpoints),"targetname \"syn_spawnpoint_%i\"",spawns);
								PushArrayString(passedarr,spawnpoints);
								if (spawns > 0) PushArrayString(passedarr,"startdisabled \"1\"");
								else
								{
									WriteFileLine(edtfile,"		create {classname \"trigger_once\" %s",origin);
									WriteFileLine(edtfile,"			values");
									WriteFileLine(edtfile,"			{");
									WriteFileLine(edtfile,"				spawnflags \"1\"");
									WriteFileLine(edtfile,"				edt_maxs \"20 20 20\"");
									WriteFileLine(edtfile,"				edt_mins \"-20 -20 -20\"");
									WriteFileLine(edtfile,"				OnTrigger \"syn_hudtimer,Start,20,0,-1\"");
									WriteFileLine(edtfile,"				OnTrigger \"syn_viewcontrol,Enable,,0,-1\"");
									WriteFileLine(edtfile,"			}");
									WriteFileLine(edtfile,"		}");
									char kvs[6][128];
									char lineedt[128];
									Format(lineedt,sizeof(lineedt),origin);
									ExplodeString(lineedt, "\"", kvs, 6, 128, true);
									ExplodeString(kvs[1], " ", kvs, 6, 128, true);
									orgpos[0] = StringToFloat(kvs[0]);
									orgpos[1] = StringToFloat(kvs[1]);
									orgpos[2] = StringToFloat(kvs[2]);
									Format(lineedt,sizeof(lineedt),"origin \"%s %s %1.f\"",kvs[0],kvs[1],StringToFloat(kvs[2])+60.0);
									WriteFileLine(edtfile,"		create {classname \"point_viewcontrol\" %s",lineedt);
									WriteFileLine(edtfile,"			values");
									WriteFileLine(edtfile,"			{");
									WriteFileLine(edtfile,"				targetname \"syn_viewcontrol\"");
									WriteFileLine(edtfile,"				spawnflags \"140\"");
									if (strlen(angs) < 1) WriteFileLine(edtfile,"				angles \"0 0 0\"");
									else
									{
										char angset[64];
										Format(angset,sizeof(angset),"				%s",angs);
										WriteFileLine(edtfile,angset);
									}
									WriteFileLine(edtfile,"			}");
									WriteFileLine(edtfile,"		}");
								}
								spawns++;
								WriteFileLine(edtfile,"		create {classname \"%s\" %s",cls,origin);
								WriteFileLine(edtfile,"			values");
								WriteFileLine(edtfile,"			{");
								for (int i = 0;i<GetArraySize(passedarr);i++)
								{
									char tmparr[128];
									GetArrayString(passedarr,i,tmparr,sizeof(tmparr));
									if ((StrContains(tmparr,"classname",false) == -1) && (StrContains(tmparr,"}",false) == -1) && (strlen(tmparr) > 0))
										WriteFileLine(edtfile,"				%s",tmparr);
								}
								WriteFileLine(edtfile,"			}");
								WriteFileLine(edtfile,"		}");
							}
							else
							{
								Format(originalorgs,sizeof(originalorgs),origin);
								ClearArray(mainspawn);
								mainspawn = CloneArray(passedarr);
							}
						}
						else if ((StrContains(cls,"weapon_",false) == 0) || (StrContains(cls,"item_",false) == 0))
						{
							char kvs[6][128];
							char lineedt[128];
							Format(lineedt,sizeof(lineedt),origin);
							ExplodeString(lineedt, "\"", kvs, 6, 128, true);
							ExplodeString(kvs[1], " ", kvs, 6, 128, true);
							Format(lineedt,sizeof(lineedt),"%s,%s %s %s",cls,kvs[0],kvs[1],kvs[2]);
							PushArrayString(itemsarr,lineedt);
						}
						else
						{
							WriteFileLine(edtfile,"		create {classname \"%s\" %s",cls,origin);
							WriteFileLine(edtfile,"			values");
							WriteFileLine(edtfile,"			{");
							for (int i = 0;i<GetArraySize(passedarr);i++)
							{
								char tmparr[128];
								GetArrayString(passedarr,i,tmparr,sizeof(tmparr));
								if (StrEqual(cls,"info_vehicle_spawn",false))
								{
									if (StrContains(tmparr,"model",false) == 0)
									{
										if (StrContains(tmparr,"models/buggy.mdl",false) != -1)
											ReplaceStringEx(tmparr,sizeof(tmparr),"models/buggy.mdl","models\\vehicles\\buggy_p2.mdl");
										else if (StrContains(tmparr,"models/vehicle.mdl",false) != -1)
										{
											int replace = FindStringInArray(passedarr,"VehicleType \"4\"");
											if (replace != -1)
											{
												RemoveFromArray(passedarr,replace);
												PushArrayString(passedarr,"VehicleType \"3\"");
											}
											replace = FindStringInArray(passedarr,"StartGunEnabled \"1\"");
											if (replace != -1)
											{
												RemoveFromArray(passedarr,replace);
											}
										}
									}
									if ((StrContains(tmparr,"PlayerOff",false) != -1) || (StrContains(tmparr,"PlayerOn",false) != -1)) tmparr = "";
									else if (StrContains(tmparr,"targetname",false) == 0)
									{
										vehiclespawns++;
										if (vehiclespawns < 10) Format(tmparr,sizeof(tmparr),"targetname \"syn_vehicle_spawn_0%i\"",vehiclespawns);
										else Format(tmparr,sizeof(tmparr),"targetname \"syn_vehicle_spawn_%i\"",vehiclespawns);
									}
								}
								if ((StrContains(tmparr,"classname",false) == -1) && (StrContains(tmparr,"}",false) == -1) && (strlen(tmparr) > 0))
									WriteFileLine(edtfile,"				%s",tmparr);
							}
							WriteFileLine(edtfile,"			}");
							WriteFileLine(edtfile,"		}");
						}
					}
					angs = "";
					cls = "";
					WriteEnt = false;
					ClearArray(passedarr);
				}
			}
		}
		if ((GetArraySize(mainspawn) > 0) && (!ismain))
		{
			char spawnpoints[64];
			Format(spawnpoints,sizeof(spawnpoints),"targetname \"syn_spawnpoint_00\"");
			PushArrayString(mainspawn,spawnpoints);
			if (GetArraySize(hudtimer) > 0)
			{
				WriteFileLine(edtfile,"		create {classname \"trigger_once\" %s",originalorgs);
				WriteFileLine(edtfile,"			values");
				WriteFileLine(edtfile,"			{");
				WriteFileLine(edtfile,"				spawnflags \"1\"");
				WriteFileLine(edtfile,"				edt_maxs \"20 20 20\"");
				WriteFileLine(edtfile,"				edt_mins \"-20 -20 -20\"");
				WriteFileLine(edtfile,"				OnTrigger \"syn_hudtimer,Start,20,0,-1\"");
				WriteFileLine(edtfile,"				OnTrigger \"syn_viewcontrol,Enable,,0,-1\"");
				WriteFileLine(edtfile,"			}");
				WriteFileLine(edtfile,"		}");
				char kvs[6][128];
				char lineedt[128];
				Format(lineedt,sizeof(lineedt),originalorgs);
				ExplodeString(lineedt, "\"", kvs, 6, 128, true);
				ExplodeString(kvs[1], " ", kvs, 6, 128, true);
				orgpos[0] = StringToFloat(kvs[0]);
				orgpos[1] = StringToFloat(kvs[1]);
				orgpos[2] = StringToFloat(kvs[2]);
				Format(lineedt,sizeof(lineedt),"origin \"%s %s %1.f\"",kvs[0],kvs[1],StringToFloat(kvs[2])+60.0);
				WriteFileLine(edtfile,"		create {classname \"point_viewcontrol\" %s",lineedt);
				WriteFileLine(edtfile,"			values");
				WriteFileLine(edtfile,"			{");
				WriteFileLine(edtfile,"				targetname \"syn_viewcontrol\"");
				WriteFileLine(edtfile,"				spawnflags \"140\"");
				if (strlen(angs) < 1) WriteFileLine(edtfile,"				angles \"0 0 0\"");
				else
				{
					char angset[64];
					Format(angset,sizeof(angset),"				%s",angs);
					WriteFileLine(edtfile,angset);
				}
				WriteFileLine(edtfile,"			}");
				WriteFileLine(edtfile,"		}");
			}
			WriteFileLine(edtfile,"		create {classname \"info_player_coop\" %s",originalorgs);
			WriteFileLine(edtfile,"			values");
			WriteFileLine(edtfile,"			{");
			for (int i = 0;i<GetArraySize(mainspawn);i++)
			{
				char tmparr[128];
				GetArrayString(mainspawn,i,tmparr,sizeof(tmparr));
				if (StrContains(tmparr,"OnMapSpawn",false) == 0) ReplaceStringEx(tmparr,sizeof(tmparr),"OnMapSpawn","OnTimer");
				if ((StrContains(tmparr,"classname",false) == -1) && (StrContains(tmparr,"}",false) == -1))
					WriteFileLine(edtfile,"				%s",tmparr);
			}
			WriteFileLine(edtfile,"			}");
			WriteFileLine(edtfile,"		}");
		}
		if (GetArraySize(hudtimer) > 0)
		{
			WriteFileLine(edtfile,"		create {classname \"hud_timer\"");
			WriteFileLine(edtfile,"			values");
			WriteFileLine(edtfile,"			{");
			WriteFileLine(edtfile,"				targetname \"syn_hudtimer\"");
			WriteFileLine(edtfile,"				TimerText \"WAITING FOR PLAYERS\"");
			WriteFileLine(edtfile,"				TimerType \"1\"");
			WriteFileLine(edtfile,"				OnTimer \"syn_viewcontrol,Disable,,0,-1\"");
			for (int i = 0;i<GetArraySize(hudtimer);i++)
			{
				char tmparr[128];
				GetArrayString(hudtimer,i,tmparr,sizeof(tmparr));
				if ((StrContains(tmparr,"OnMapTransition") == 0) || ((StrContains(tmparr,"OnMapSpawn",false) == 0) && (StrContains(tmparr,"AddOutput",false) != -1)))
				{
					PushArrayString(logicautos,tmparr);
					tmparr = "";
				}
				else if (StrContains(tmparr,"OnMapSpawn",false) == 0) ReplaceStringEx(tmparr,sizeof(tmparr),"OnMapSpawn","OnTimer");
				if (strlen(tmparr) > 1)
				{
					WriteFileLine(edtfile,"				%s",tmparr);
				}
			}
			WriteFileLine(edtfile,"			}");
			WriteFileLine(edtfile,"		}");
		}
		if (GetArraySize(itemsarr) > 0)
		{
			WriteFileLine(edtfile,"		create {classname \"info_player_equip\"");
			WriteFileLine(edtfile,"			values");
			WriteFileLine(edtfile,"			{");
			WriteFileLine(edtfile,"				targetname \"syn_equipment_base\"");
			SortADTArray(itemsarr,Sort_Ascending,Sort_String);
			Handle duplicates = CreateArray(64);
			for (int i = 0;i<GetArraySize(itemsarr);i++)
			{
				char tmparr[128];
				GetArrayString(itemsarr,i,tmparr,sizeof(tmparr));
				char kvs2[64][128];
				ExplodeString(tmparr, ",", kvs2, 64, 128, true);
				Format(tmparr,sizeof(tmparr),"%s",kvs2[0]);
				ExplodeString(kvs2[1], " ", kvs2, 64, 128, true);
				if (FindStringInArray(duplicates,tmparr) == -1)
				{
					float itempos[3];
					itempos[0] = StringToFloat(kvs2[0]);
					itempos[1] = StringToFloat(kvs2[1]);
					itempos[2] = StringToFloat(kvs2[2]);
					if (GetVectorDistance(orgpos,itempos,false) < 60.0)
					{
						PushArrayString(duplicates,tmparr);
						if (StrEqual(tmparr,"item_box_buckshot",false)) Format(tmparr,sizeof(tmparr),"ammo_buckshot \"6\"");
						else if (StrEqual(tmparr,"item_rpg_round",false)) Format(tmparr,sizeof(tmparr),"ammo_rpg_round \"2\"");
						else if (StrEqual(tmparr,"item_battery",false)) Format(tmparr,sizeof(tmparr),"item_armor \"15\"");
						else if (StrEqual(tmparr,"item_ar2_grenade",false)) Format(tmparr,sizeof(tmparr),"ammo_ar2_altfire \"1\"");
						else if (StrEqual(tmparr,"item_box_mrounds",false)) Format(tmparr,sizeof(tmparr),"ammo_smg1 \"90\"");
						else if (StrEqual(tmparr,"item_box_srounds",false)) Format(tmparr,sizeof(tmparr),"ammo_pistol \"36\""); //But also sniper rounds
						else if (StrEqual(tmparr,"item_box_lrounds",false)) Format(tmparr,sizeof(tmparr),"ammo_ar2 \"30\"");
						else
						{
							if (StrEqual(tmparr,"item_suit",false))
							{
								char deletion[72];
								Format(deletion,sizeof(deletion),"%s\" %s}",tmparr,origin);
								if (FindStringInArray(mapremovals,deletion) == -1) PushArrayString(mapremovals,deletion);
							}
							if ((StrContains(tmparr,"item_ammo",false) == 0) && (!StrEqual(tmparr,"item_suit",false)))
							{
								ReplaceStringEx(tmparr,sizeof(tmparr),"item_","");
								if (StrContains(tmparr,"grenade",false) != -1) StrCat(tmparr,sizeof(tmparr)," \"3\"");
								else StrCat(tmparr,sizeof(tmparr)," \"12\"");
							}
							else
							{
								StrCat(tmparr,sizeof(tmparr)," \"1\"");
							}
						}
						WriteFileLine(edtfile,"				%s",tmparr);
					}
					else if (StrContains(tmparr,"item_",false) == -1)
					{
						char push[128];
						char tmptrunc[4];
						int truncatedat = StrContains(tmparr,"_",false);
						if (truncatedat == -1) truncatedat = 0;
						else truncatedat++;
						Format(tmptrunc,sizeof(tmptrunc),"%s",tmparr[truncatedat]);
						Format(push,sizeof(push),"OnMapSpawn \"%s,AddOutput,OnPlayerPickup %spickup:Enable::0:-1,0,-1\"",tmparr,tmptrunc);
						if (FindStringInArray(logicautos,push) == -1) PushArrayString(logicautos,push);
						Format(push,sizeof(push),"OnMapSpawn \"%s,AddOutput,OnPlayerPickup %spickup:EquipAllPlayers::0.1:-1,0,-1\"",tmparr,tmptrunc);
						if (FindStringInArray(logicautos,push) == -1) PushArrayString(logicautos,push);
						Format(push,sizeof(push),"%s %spickup",tmparr,tmptrunc);
						if (FindStringInArray(equipsarrays,push) == -1) PushArrayString(equipsarrays,push);
					}
				}
			}
			CloseHandle(duplicates);
			WriteFileLine(edtfile,"			}");
			WriteFileLine(edtfile,"		}");
		}
		if (GetArraySize(mapremovals) > 0)
		{
			for (int i = 0;i<GetArraySize(mapremovals);i++)
			{
				char tmparr[128];
				GetArrayString(mapremovals,i,tmparr,sizeof(tmparr));
				WriteFileLine(edtfile,"		delete {classname \"%s",tmparr);
			}
		}
		if (GetArraySize(logicautos) > 0)
		{
			WriteFileLine(edtfile,"		create {classname \"logic_auto\"");
			WriteFileLine(edtfile,"			values");
			WriteFileLine(edtfile,"			{");
			WriteFileLine(edtfile,"				spawnflags \"1\"");
			for (int i = 0;i<GetArraySize(logicautos);i++)
			{
				char tmparr[128];
				GetArrayString(logicautos,i,tmparr,sizeof(tmparr));
				WriteFileLine(edtfile,"				%s",tmparr);
			}
			WriteFileLine(edtfile,"			}");
			WriteFileLine(edtfile,"		}");
		}
		if (GetArraySize(equipsarrays) > 0)
		{
			char largerline[256];
			for (int i = 0;i<GetArraySize(equipsarrays);i++)
			{
				GetArrayString(equipsarrays,i,largerline,sizeof(largerline));
				char kvs[128][128];
				ExplodeString(largerline, " ", kvs, 128, 128, true);
				char ammtype[32];
				Format(ammtype,sizeof(ammtype),"%s",kvs[0]);
				ReplaceStringEx(ammtype,sizeof(ammtype),"weapon_","sk_max_");
				ReplaceString(ammtype,sizeof(ammtype),"\"","");
				if (StrEqual(ammtype,"sk_max_shotgun",false)) Format(ammtype,sizeof(ammtype),"sk_max_buckshot");
				int ammamount = 1;
				Handle cvarchk = FindConVar(ammtype);
				if (cvarchk != INVALID_HANDLE) ammamount = GetConVarInt(cvarchk)/4;
				CloseHandle(cvarchk);
				ReplaceStringEx(ammtype,sizeof(ammtype),"sk_max_","ammo_");
				if (StrEqual(ammtype,"ammo_rpg",false)) Format(ammtype,sizeof(ammtype),"ammo_rpg_round");
				else if (StrEqual(ammtype,"ammo_frag",false)) Format(ammtype,sizeof(ammtype),"ammo_grenade");
				else if (StrEqual(ammtype,"ammo_shotgun",false)) Format(ammtype,sizeof(ammtype),"ammo_buckshot");
				else if (StrEqual(ammtype,"ammo_crossbow",false)) Format(ammtype,sizeof(ammtype),"ammo_xbowbolt");
				else if ((StrEqual(ammtype,"ammo_crowbar",false)) || (StrEqual(ammtype,"ammo_physcannon",false)) || (StrEqual(ammtype,"ammo_portalgun",false)) || (StrEqual(ammtype,"ammo_suit",false))) ammtype = "";
				if (strlen(ammtype) > 1) Format(largerline,sizeof(largerline),"		create {classname \"info_player_equip\" values {targetname \"%s\" startdisabled \"1\" %s \"1\" %s \"%i\"} }",kvs[1],kvs[0],ammtype,ammamount);
				else Format(largerline,sizeof(largerline),"		create {classname \"info_player_equip\" values {targetname \"%s\" startdisabled \"1\" %s \"1\"} }",kvs[1],kvs[0]);
				WriteFileLine(edtfile,largerline);
			}
		}
		CloseHandle(passedarr);
		CloseHandle(mainspawn);
		CloseHandle(logicautos);
		CloseHandle(hudtimer);
		CloseHandle(itemsarr);
		CloseHandle(equipsarrays);
		CloseHandle(mapremovals);
	}
	if (edtfile != INVALID_HANDLE)
	{
		WriteFileLine(edtfile,"	}");
		WriteFileLine(edtfile,"}");
	}
	CloseHandle(filehandle);
	CloseHandle(edtfile);
	PrintToServer("Finished writing EDT %s",edtfilepath);
	return;
}

public void OnMapStart()
{
	Handle mdirlisting = OpenDirectory("maps/ent_cache", false);
	if (mdirlisting == INVALID_HANDLE)
	{
		CreateDirectory("maps/ent_cache",511);
	}
	CloseHandle(mdirlisting);
	globaldots = "";
	Reverse = false;
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
		/*
		if (AutoBuild)
		{
			CreateTimer(1.0,buildinfodelay,_,TIMER_FLAG_NO_MAPCHANGE);
		}
		*/
	}
}

public Action OnLevelInit(const char[] szMapName, char szMapEntities[2097152])
{
	if (AutoBuild)
	{
		char contentdata[64];
		char szMapNameadj[64];
		Handle cvar = FindConVar("content_metadata");
		if (cvar != INVALID_HANDLE)
		{
			GetConVarString(cvar,contentdata,sizeof(contentdata));
			char fixuptmp[16][16];
			ExplodeString(contentdata," ",fixuptmp,16,16,true);
			Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		}
		CloseHandle(cvar);
		if (strlen(contentdata) < 1) Format(szMapNameadj,sizeof(szMapNameadj),"maps/ent_cache/%s.ent",szMapName);
		else Format(szMapNameadj,sizeof(szMapNameadj),"maps/ent_cache/%s_%s.ent",contentdata,szMapName);
		if (!FileExists(szMapNameadj,false))
		{
			Handle writefile = OpenFile(szMapNameadj,"wb",true,NULL_STRING);
			if (writefile != INVALID_HANDLE)
			{
				ReplaceString(szMapEntities,sizeof(szMapEntities),"",",",false);
				WriteFileString(writefile,szMapEntities,false);
			}
			CloseHandle(writefile);
		}
	}
	return Plugin_Continue;
}

public Action buildinfodelay(Handle timer)
{
	if (!FileExists(mapbuf,true,NULL_STRING))
	{
		openbrackets = 0;
		PrintToServer("\n\n\nStart building entity cache\nThis may take a while...\n\n\n");
		buildcache(0,INVALID_HANDLE);
	}
	return Plugin_Handled;
}

void buildcache(int startline, Handle mapset)
{
	Handle cachefile = INVALID_HANDLE;
	if (startline == 0) cachefile = OpenFile(mapbuf,"w");
	else cachefile = OpenFile(mapbuf,"a");
	Handle filehandle = INVALID_HANDLE;
	if (mapset == INVALID_HANDLE) filehandle = OpenFile(curmap,"rb",true,NULL_STRING);
	else filehandle = OpenFile(curmap,"rb");
	if (filehandle != INVALID_HANDLE)
	{
		startedreading = true;
		if (startline != 0) FileSeek(filehandle,startline,SEEK_SET);
		char line[256];
		int nextline = 0;
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			if ((nextline >= 25000) && (!WriteCache))
			{
				startline = FilePosition(filehandle);
				Handle dp = CreateDataPack();
				WritePackCell(dp,startline);
				WritePackCell(dp,mapset);
				if (strlen(globaldots) > 0) PrintToServer("%s",globaldots);
				if ((!Reverse) && (strlen(globaldots) > 46)) Reverse = true;
				else if ((Reverse) && (strlen(globaldots) < 1)) Reverse = false;
				if ((Reverse) && (strlen(globaldots) > 0)) ReplaceStringEx(globaldots,sizeof(globaldots),".","");
				else StrCat(globaldots,sizeof(globaldots),".");
				CreateTimer(0.1,nextlines,dp,TIMER_FLAG_NO_MAPCHANGE);
				break;
			}
			nextline++;
			int quotepos = StrContains(line,"\"",false);
			if (((strlen(line) > 5) && (quotepos != -1)) || ((StrContains(line,"{",false) != -1) && (strlen(line) < 3)) || ((StrContains(line,"}",false) != -1) && (strlen(line) < 3)))
			{
				char additionalquote[128];
				Format(additionalquote,sizeof(additionalquote),"%s",line[quotepos+1]);
				if (((strlen(line) > 5) && (StrContains(additionalquote,"\"",false) != -1) && (StrContains(additionalquote," ",false) != -1)) || ((StrContains(line,"{",false) != -1) && (strlen(line) < 3)) || ((StrContains(line,"}",false) != -1) && (strlen(line) < 3)))
				{
					if ((StrContains(line,"\"world_maxs\"",false) == 0) && (!WriteCache))
					{
						PrintToServer("Found first line of entity cache");
						WriteCache = true;
						startline = FilePosition(filehandle)-strlen(line)-2;
						Handle dp = CreateDataPack();
						WritePackCell(dp,startline);
						WritePackCell(dp,mapset);
						CreateTimer(0.1,nextlines,dp,TIMER_FLAG_NO_MAPCHANGE);
						break;
					}
					else if (WriteCache)
					{
						TrimString(line);
						if (StrContains(line,"",false) != -1) ReplaceString(line,sizeof(line),"",",");
						if (StrContains(line,"{",false) == 0) openbrackets = 0;
						else if (StrContains(line,"}",false) == 0) openbrackets++;
						if ((openbrackets > 1) || (StrContains(line,"(",false) == 0) || (StrContains(line,"|",false) != -1) || (StrContains(line,"ý",false) != -1) || (StrContains(line,"┬",false) != -1) || (StrContains(line,"╙",false) != -1) || (StrContains(line,"ü",false) == 0) || (StrContains(line,"õ",false) != -1) || (StrContains(line,"Ó",false) != -1) || (StrContains(line,"Ÿ",false) != -1) || (StrContains(line,"{~") == 0) || (StrContains(line,"<",false) != -1) || (StrContains(line,">",false) != -1) || (StrContains(line,"Å",false) != -1) || (StrContains(line,"ÿ",false) != -1) || (StrContains(line,"┼",false) != -1) || (StrContains(line,"",false) != -1))
						{
							WriteCache = false;
							PrintToServer("Finished writing cache %s",mapbuf);
							if (mapset != INVALID_HANDLE)
							{
								char edtmap[128];
								Format(edtmap,sizeof(edtmap),"%s",curmap);
								ReplaceString(edtmap,sizeof(edtmap),".bsp","");
								int contained = StrContains(edtmap,"maps\\",false);
								Format(edtmap,sizeof(edtmap),"%s",edtmap[contained]);
								ReplaceString(edtmap,sizeof(edtmap),"maps\\","");
								Handle delayedread = CreateDataPack();
								WritePackString(delayedread,mapbuf);
								WritePackString(delayedread,edtmap);
								CreateTimer(0.1,ReadCacheDelay,delayedread,TIMER_FLAG_NO_MAPCHANGE);
								//ReadCache(mapbuf,edtmap);
								ReadPackString(mapset,mapbuf,sizeof(mapbuf));
								if (!StrEqual(mapbuf,"endofpack",false))
								{
									ReadPackString(mapset,curmap,sizeof(curmap));
									globaldots = "";
									Reverse = false;
									PrintToServer("WriteTo %s\nRead %s",mapbuf,curmap);
									buildcache(0,mapset);
								}
								else
								{
									PrintToServer("Finished writing map set");
									CloseHandle(mapset);
									break;
								}
							}
							else
							{
								CloseHandle(mapset);
							}
							globaldots = "";
							Reverse = false;
							startedreading = false;
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
	}
	CloseHandle(cachefile);
	CloseHandle(filehandle);
	openbrackets = 0;
}

public void OnMapEnd()
{
	if (startedreading)
	{
		//Need to free file handles
	}
}

public Action nextlines(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int startline = ReadPackCell(dp);
		Handle hndl = ReadPackCell(dp);
		CloseHandle(dp);
		buildcache(startline,hndl);
	}
}
