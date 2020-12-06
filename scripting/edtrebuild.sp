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

Handle cvaroriginals = INVALID_HANDLE;
Handle cvarmods = INVALID_HANDLE;
Handle g_DeleteClasses = INVALID_HANDLE;
Handle g_DeleteClassOrigin = INVALID_HANDLE;
Handle g_DeleteTargets = INVALID_HANDLE;
Handle g_EditClasses = INVALID_HANDLE;
Handle g_EditClassOrigin = INVALID_HANDLE;
Handle g_EditTargets = INVALID_HANDLE;
Handle g_EditClassesData = INVALID_HANDLE;
Handle g_EditClassOrgData = INVALID_HANDLE;
Handle g_EditTargetsData = INVALID_HANDLE;
Handle g_CreateEnts = INVALID_HANDLE;
Handle g_ModifyCase = INVALID_HANDLE;

char lastmap[72];
char LineSpanning[256];
int dbglvl = 0;
int method = 0;
bool VintageMode = false;
bool AntirushDisable = false;
bool GenerateEnt2 = false;
bool RemoveGlobals = false;
bool LogEDTErr = false;
bool IncludeNextLines = false;

#define PLUGIN_VERSION "0.62"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/edtrebuildupdater.txt"

public Plugin myinfo =
{
	name = "EDTRebuild",
	author = "Balimbanana",
	description = "Rebuilds EDT system to prevent memory leak in 56.16. Also enables other games/mods to use Synergys EDT system.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	cvaroriginals = CreateArray(64);
	cvarmods = CreateArray(64);
	Handle cvar = FindConVar("edtdbg");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("edtdbg", "0", "Set debug level of EDT read.", _, true, 0.0, true, 4.0);
	dbglvl = GetConVarInt(cvar);
	HookConVarChange(cvar,dbgch);
	CloseHandle(cvar);
	cvar = FindConVar("edtmethod");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("edtmethod", "1", "Set method of EntityCache modify.", _, true, 0.0, true, 3.0);
	method = GetConVarInt(cvar);
	HookConVarChange(cvar,methodch);
	CloseHandle(cvar);
	cvar = FindConVar("mp_vintage_mode");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("mp_vintage_mode", "0", "Remove most modifications and additions while maintaining core functionality and support.", _, true, 0.0, true, 1.0);
	VintageMode = GetConVarBool(cvar);
	HookConVarChange(cvar,vintagech);
	CloseHandle(cvar);
	cvar = FindConVar("mp_antirush_disable");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("mp_antirush_disable", "0", "Disable progression prevention methods at the end of applicable levels.", _, true, 0.0, true, 1.0);
	AntirushDisable = GetConVarBool(cvar);
	HookConVarChange(cvar,antirushch);
	CloseHandle(cvar);
	cvar = FindConVar("edtgenerateent2");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("edtgenerateent2", "0", "Generate .ent2 instead of .ent cache files.", _, true, 0.0, true, 1.0);
	GenerateEnt2 = GetConVarBool(cvar);
	HookConVarChange(cvar,generateent2ch);
	CloseHandle(cvar);
	cvar = FindConVar("edtremoveglobals");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("edtremoveglobals", "0", "Remove global names from all entities.", _, true, 0.0, true, 1.0);
	RemoveGlobals = GetConVarBool(cvar);
	HookConVarChange(cvar,rmglobalsch);
	CloseHandle(cvar);
	cvar = FindConVar("edtlog_getbspmodel");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("edtlog_getbspmodel", "0", "Logs errors in edt_getbspmodelfor_ values that dont point to existing entities.", _, true, 0.0, true, 1.0);
	LogEDTErr = GetConVarBool(cvar);
	HookConVarChange(cvar,loggetbspch);
	CloseHandle(cvar);
	cvar = FindConVar("edtprefix");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("edtprefix", "", "Add prefix to check for EDTs starting with this first. Functions as prefix_mapname.edt.", _, false);
	CloseHandle(cvar);
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name,"updater",false))
    {
        Updater_AddPlugin(PLUGIN_VERSION);
    }
}

public Action OnLevelInit(const char[] szMapName, char szMapEntities[2097152])
{
	g_DeleteClasses = CreateArray(128);
	g_DeleteClassOrigin = CreateArray(128);
	g_DeleteTargets = CreateArray(128);
	g_EditClasses = CreateArray(128);
	g_EditClassOrigin = CreateArray(128);
	g_EditTargets = CreateArray(128);
	g_EditClassesData = CreateArray(128);
	g_EditClassOrgData = CreateArray(128);
	g_EditTargetsData = CreateArray(128);
	g_CreateEnts = CreateArray(128);
	g_ModifyCase = CreateArray(128);
	IncludeNextLines = false;
	LineSpanning = "";
	if (GetArraySize(cvaroriginals) > 0)
	{
		for (int i = 0;i<GetArraySize(cvaroriginals);i++)
		{
			char tmparr[128];
			GetArrayString(cvaroriginals,i,tmparr,sizeof(tmparr));
			ServerCommand(tmparr);
		}
		CloseHandle(cvaroriginals);
		cvaroriginals = CreateArray(64);
	}
	char contentdata[64];
	Handle cvar = FindConVar("content_metadata");
	if (cvar != INVALID_HANDLE)
	{
		GetConVarString(cvar,contentdata,sizeof(contentdata));
		char fixuptmp[16][16];
		ExplodeString(contentdata," ",fixuptmp,16,16,true);
		if (StrEqual(fixuptmp[1],"|",false)) Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		else if (StrEqual(fixuptmp[0],szMapName,false)) Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		else Format(contentdata,sizeof(contentdata),"%s",fixuptmp[0]);
	}
	CloseHandle(cvar);
	char curmap[128];
	char curmap2[128];
	Format(curmap,sizeof(curmap),"maps/%s.edt",szMapName);
	Format(curmap2,sizeof(curmap2),"maps/%s.edt2",szMapName);
	if (strlen(contentdata) > 0)
	{
		Format(curmap,sizeof(curmap),"maps/%s_%s.edt",contentdata,szMapName);
		Format(curmap2,sizeof(curmap2),"maps/%s_%s.edt2",contentdata,szMapName);
		if ((FileExists(curmap,true,NULL_STRING)) || (FileExists(curmap2,true,NULL_STRING)))
		{
			if (FileExists(curmap2,true,NULL_STRING)) Format(curmap,sizeof(curmap),"%s",curmap2);
		}
		else
		{
			Format(curmap,sizeof(curmap),"maps/%s.edt",szMapName);
			Format(curmap2,sizeof(curmap2),"maps/%s.edt2",szMapName);
		}
	}
	if (FileExists("cfg/globaledt.edt",false)) ReadEDT("cfg/globaledt.edt");
	cvar = FindConVar("edtprefix");
	if (cvar != INVALID_HANDLE)
	{
		char prefix[64];
		char mapchk[128];
		GetConVarString(cvar,prefix,sizeof(prefix));
		if (strlen(prefix) > 0)
		{
			Format(prefix,sizeof(prefix),"maps/%s_",prefix);
			Format(mapchk,sizeof(mapchk),"%s",curmap);
			ReplaceStringEx(mapchk,sizeof(mapchk),"maps/",prefix,_,_,false);
			if (FileExists(mapchk,true,NULL_STRING)) Format(curmap2,sizeof(curmap2),"%s",mapchk);
			else
			{
				Format(mapchk,sizeof(mapchk),"%s",curmap2);
				ReplaceStringEx(mapchk,sizeof(mapchk),"maps/",prefix,_,_,false);
				if (FileExists(mapchk,true,NULL_STRING)) Format(curmap2,sizeof(curmap2),"%s",mapchk);
			}
		}
	}
	CloseHandle(cvar);
	if (FileExists(curmap2,true,NULL_STRING)) Format(curmap,sizeof(curmap),"%s",curmap2);
	if (FileExists(curmap,true,NULL_STRING))
	{
		if (dbglvl) PrintToServer("EDT %s exists",curmap);
		ReadEDT(curmap);
		if (method == 1)
		{
			char szMapEntitiesbuff[2097152];
			char tmpbuf[8196];
			char tmpwriter[131136];
			char cls[64];
			char clsorg[64];
			char tmpexpl[4][64];
			char edtdata[128];
			char replacedata[128];
			char edt_map[64];
			char edt_landmark[64];
			char portalnumber[64];
			char edtkey[128];
			char edtval[128];
			if (GetArraySize(g_ModifyCase) > 0)
			{
				for (int k = 0;k<GetArraySize(g_ModifyCase);k++)
				{
					Handle passedarr = GetArrayCell(g_ModifyCase,k);
					if (passedarr != INVALID_HANDLE)
					{
						for (int j = 0;j<GetArraySize(passedarr);j++)
						{
							char first[128];
							GetArrayString(passedarr,j,first,sizeof(first));
							j++;
							if (j >= GetArraySize(passedarr)) break;
							char second[128];
							GetArrayString(passedarr,j,second,sizeof(second));
							bool ReplaceWildCard = false;
							ReplaceString(first,sizeof(first),"\"","");
							ReplaceString(second,sizeof(second),"\"","");
							TrimString(first);
							TrimString(second);
							int finder = StrContains(first," ",false);
							if (finder != -1)
							{
								Format(cls,finder+1,"%s",first);
								Format(edtkey,sizeof(edtkey),"%s",first);
								ReplaceStringEx(edtkey,sizeof(edtkey),cls,"");
								TrimString(edtkey);
								if (StrEqual(edtkey,"*",false))
								{
									ReplaceWildCard = true;
									Format(first,sizeof(first),"\"%s\" \"",cls);
								}
								else Format(first,sizeof(first),"\"%s\" \"%s\"",cls,edtkey);
							}
							finder = StrContains(second," ",false);
							if (finder != -1)
							{
								Format(cls,finder+1,"%s",second);
								Format(edtkey,sizeof(edtkey),"%s",second);
								ReplaceStringEx(edtkey,sizeof(edtkey),cls,"");
								TrimString(edtkey);
								Format(second,sizeof(second),"\"%s\" \"%s\"",cls,edtkey);
							}
							if (dbglvl > 1) PrintToServer("ModifyCase Replace %s with %s",first,second);
							if (ReplaceWildCard)
							{
								char removerchar[64];
								int findpos = StrContains(szMapEntities,first,false);
								if (findpos != -1)
								{
									Format(removerchar,sizeof(removerchar),"%s",szMapEntities[findpos]);
									ExplodeString(removerchar,"\n",tmpexpl,4,64);
									Format(removerchar,sizeof(removerchar),"%s",tmpexpl[0]);
									TrimString(removerchar);
									ReplaceString(szMapEntities,sizeof(szMapEntities),removerchar,second,false);
									Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[findpos]);
									if (dbglvl > 2) PrintToServer("Replaced %s with %s",removerchar,second);
									bool endofcache = false;
									while (!endofcache)
									{
										findpos = StrContains(szMapEntitiesbuff,first,false);
										if (findpos != -1)
										{
											Format(removerchar,sizeof(removerchar),"%s",szMapEntitiesbuff[findpos]);
											ExplodeString(removerchar,"\n",tmpexpl,4,64);
											Format(removerchar,sizeof(removerchar),"%s",tmpexpl[0]);
											TrimString(removerchar);
											Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[findpos+StrContains(szMapEntities,szMapEntitiesbuff,false)+strlen(removerchar)]);
											ReplaceString(szMapEntities,sizeof(szMapEntities),removerchar,second,false);
											if (dbglvl > 2) PrintToServer("Replaced %s with %s",removerchar,second);
										}
										else endofcache = true;
									}
								}
							}
							else ReplaceString(szMapEntities,sizeof(szMapEntities),first,second,false);
						}
					}
					CloseHandle(passedarr);
				}
			}
			CloseHandle(g_ModifyCase);
			if (GetArraySize(g_CreateEnts) > 0)
			{
				for (int k = 0;k<GetArraySize(g_CreateEnts);k++)
				{
					Handle passedarr = GetArrayCell(g_CreateEnts,k);
					if (passedarr != INVALID_HANDLE)
					{
						char edtclass[64];
						char edtclassorg[64];
						bool ItemClassSpecified = false;
						bool OriginSpecified = false;
						Format(tmpwriter,sizeof(tmpwriter),"%s{",tmpwriter);
						for (int j = 0;j<GetArraySize(passedarr);j++)
						{
							char first[128];
							GetArrayString(passedarr,j,first,sizeof(first));
							char second[128];
							Format(second,sizeof(second),"%s",first);
							int secondpos = StrContains(first," ",false);
							if (secondpos != -1)
							{
								Format(second,sizeof(second),"%s",second[secondpos]);
								ReplaceStringEx(first,sizeof(first),second,"");
								ReplaceString(first,sizeof(first),"\"","");
								ReplaceString(second,sizeof(second),"\"","");
								TrimString(first);
								TrimString(second);
								if (StrEqual(first,"edt_getbspmodelfor_targetname",false))
								{
									Format(tmpwriter,sizeof(tmpwriter),"%s\n\"%s\" \"%s\"",tmpwriter,first,second);
									char findtn[128];
									Format(findtn,sizeof(findtn),"\"targetname\" \"%s\"",second);
									int findorg = StrContains(szMapEntities,findtn,false);
									if (findorg != -1)
									{
										Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findorg]);
										while (StrContains(tmpbuf,"{",false) != 0)
										{
											Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findorg--]);
										}
										int findend = StrContains(tmpbuf,"}",false);
										if (findend != -1) Format(tmpbuf,findend+2,"%s",tmpbuf);
										int findmdl = StrContains(tmpbuf,"\"model\"",false);
										if (findmdl != -1)
										{
											Format(tmpbuf,sizeof(tmpbuf),"%s",tmpbuf[findmdl]);
											ExplodeString(tmpbuf,"\"",tmpexpl,4,64);
											Format(first,sizeof(first),"model");
											Format(second,sizeof(second),"%s",tmpexpl[3]);
										}
									}
									else
									{
										PrintToServer("Failed to get BSP Model from Targetname %s",second);
										if (LogEDTErr) LogMessage("Failed to get BSP Model from Targetname %s",second);
										bool noplaceholder = false;
										for (int m = 0;m<GetArraySize(passedarr);m++)
										{
											char tmpchk[128];
											GetArrayString(passedarr,m,tmpchk,sizeof(tmpchk));
											char tmpchk2[128];
											Format(tmpchk2,sizeof(tmpchk2),"%s",tmpchk);
											secondpos = StrContains(tmpchk," ",false);
											if (secondpos != -1)
											{
												Format(tmpchk2,sizeof(tmpchk2),"%s",tmpchk2[secondpos]);
												ReplaceStringEx(tmpchk,sizeof(tmpchk),tmpchk2,"");
												ReplaceString(tmpchk,sizeof(tmpchk),"\"","");
												TrimString(tmpchk);
												if (StrEqual(tmpchk,"model",false))
												{
													noplaceholder = true;
													break;
												}
											}
										}
										if (!noplaceholder)
										{
											Format(tmpwriter,sizeof(tmpwriter),"%s\n\"model\" \"*1\"",tmpwriter);
										}
									}
								}
								if (StrEqual(first,"edt_getbspmodelfor_classname",false))
								{
									Format(edtclass,sizeof(edtclass),"%s",second);
									Format(tmpwriter,sizeof(tmpwriter),"%s\n\"%s\" \"%s\"",tmpwriter,first,second);
								}
								else if (StrEqual(first,"edt_getbspmodelfor_origin",false))
								{
									Format(edtclassorg,sizeof(edtclassorg),"%s",second);
									Format(tmpwriter,sizeof(tmpwriter),"%s\n\"%s\" \"%s\"",tmpwriter,first,second);
								}
								else Format(tmpwriter,sizeof(tmpwriter),"%s\n\"%s\" \"%s\"",tmpwriter,first,second);
								if (StrEqual(first,"classname",false))
								{
									Format(cls,sizeof(cls),"%s",second);
								}
								if (StrEqual(first,"ItemClass",false))
								{
									ItemClassSpecified = true;
								}
								else if (StrEqual(first,"origin",false))
								{
									OriginSpecified = true;
								}
							}
						}
						if ((strlen(edtclass) > 0) && (strlen(edtclassorg) > 0))
						{
							bool FailedToGetModel = false;
							char findclass[128];
							Format(findclass,sizeof(findclass),"\"classname\" \"%s\"",edtclass);
							char sfindorg[128];
							Format(sfindorg,sizeof(sfindorg),"\"origin\" \"%s\"",edtclassorg);
							int findorg = StrContains(szMapEntities,sfindorg,false);
							if (findorg != -1)
							{
								Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findorg]);
								while (StrContains(tmpbuf,"{",false) != 0)
								{
									Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findorg--]);
								}
								int findend = StrContains(tmpbuf,"}",false);
								if (findend != -1) Format(tmpbuf,findend+1,"%s",tmpbuf);
								if (StrContains(tmpbuf,edtclass,false) != -1)
								{
									int findmdl = StrContains(tmpbuf,"\"model\"",false);
									if (findmdl != -1)
									{
										Format(tmpbuf,sizeof(tmpbuf),"%s",tmpbuf[findmdl]);
										ExplodeString(tmpbuf,"\"",tmpexpl,4,64);
										Format(tmpwriter,sizeof(tmpwriter),"%s\n\"model\" \"%s\"",tmpwriter,tmpexpl[3]);
									}
								}
								else
								{
									bool FoundMdl = false;
									int findorgnext = StrContains(szMapEntities[findorg+strlen(tmpbuf)],sfindorg,false);
									while (findorgnext != -1)
									{
										if (findorgnext != -1)
										{
											int posreset = findorgnext+findorg;
											Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[posreset]);
											while (StrContains(tmpbuf,"{",false) != 0)
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[posreset--]);
											}
											findend = StrContains(tmpbuf,"}",false);
											if (findend != -1) Format(tmpbuf,findend+1,"%s",tmpbuf);
											if (StrContains(tmpbuf,edtclass,false) != -1)
											{
												int findmdl = StrContains(tmpbuf,"\"model\"",false);
												if (findmdl != -1)
												{
													Format(tmpbuf,sizeof(tmpbuf),"%s",tmpbuf[findmdl]);
													ExplodeString(tmpbuf,"\"",tmpexpl,4,64);
													Format(tmpwriter,sizeof(tmpwriter),"%s\n\"model\" \"%s\"",tmpwriter,tmpexpl[3]);
													FoundMdl = true;
													break;
												}
											}
											else
											{
												findorg = posreset+strlen(tmpbuf);
												findorgnext = StrContains(szMapEntities[findorg],sfindorg,false);
											}
										}
									}
									if (!FoundMdl)
									{
										PrintToServer("Failed to get BSP Model from Classname %s at origin %s",edtclass,edtclassorg);
										if (LogEDTErr) LogMessage("Failed to get BSP Model from Classname %s at origin %s",edtclass,edtclassorg);
										FailedToGetModel = true;
									}
								}
							}
							else
							{
								PrintToServer("Failed to get BSP Model from Classname %s at origin %s",edtclass,edtclassorg);
								if (LogEDTErr) LogMessage("Failed to get BSP Model from Classname %s at origin %s",edtclass,edtclassorg);
								FailedToGetModel = true;
							}
							if (FailedToGetModel)
							{
								bool noplaceholder = false;
								for (int m = 0;m<GetArraySize(passedarr);m++)
								{
									char tmpchk[128];
									GetArrayString(passedarr,m,tmpchk,sizeof(tmpchk));
									char tmpchk2[128];
									Format(tmpchk2,sizeof(tmpchk2),"%s",tmpchk);
									int secondpos = StrContains(tmpchk," ",false);
									if (secondpos != -1)
									{
										Format(tmpchk2,sizeof(tmpchk2),"%s",tmpchk2[secondpos]);
										ReplaceStringEx(tmpchk,sizeof(tmpchk),tmpchk2,"");
										ReplaceString(tmpchk,sizeof(tmpchk),"\"","");
										TrimString(tmpchk);
										if (StrEqual(tmpchk,"model",false))
										{
											noplaceholder = true;
											break;
										}
									}
								}
								if (!noplaceholder)
								{
									Format(tmpwriter,sizeof(tmpwriter),"%s\n\"model\" \"*1\"",tmpwriter);
								}
							}
						}
						if ((StrEqual(cls,"item_item_crate",false)) && (!ItemClassSpecified))
						{
							Format(tmpwriter,sizeof(tmpwriter),"%s\n\"ItemClass\" \"item_dynamic_resupply\"",tmpwriter);
						}
						if (!OriginSpecified)
						{
							Format(tmpwriter,sizeof(tmpwriter),"%s\n\"origin\" \"0 0 0\"",tmpwriter);
						}
						Format(tmpwriter,sizeof(tmpwriter),"%s\n}\n",tmpwriter);
						if (dbglvl == 4) PrintToServer("Create %s",cls);
						CloseHandle(passedarr);
					}
				}
			}
			if (GetArraySize(g_DeleteClasses) > 0)
			{
				int finder = -1;
				for (int i = 0;i<GetArraySize(g_DeleteClasses);i++)
				{
					GetArrayString(g_DeleteClasses,i,cls,sizeof(cls));
					Format(cls,sizeof(cls),"\"classname\" \"%s\"",cls);
					bool endofcache = false;
					while (!endofcache)
					{
						finder = StrContains(szMapEntities,cls,false);
						if (finder != -1)
						{
							Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[finder]);
							while (StrContains(tmpbuf,"{",false) != 0)
							{
								Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[finder--]);
							}
							int findend = StrContains(tmpbuf,"}",false);
							if (findend != -1) Format(tmpbuf,findend+2,"%s\n",tmpbuf);
							ReplaceString(szMapEntities,sizeof(szMapEntities),tmpbuf,"");
							if (dbglvl == 4) PrintToServer("Delete %s\n%s",cls,tmpbuf);
						}
						else endofcache = true;
					}
				}
			}
			if (GetArraySize(g_DeleteTargets) > 0)
			{
				int finder = -1;
				for (int i = 0;i<GetArraySize(g_DeleteTargets);i++)
				{
					GetArrayString(g_DeleteTargets,i,cls,sizeof(cls));
					Format(cls,sizeof(cls),"\"targetname\" \"%s\"",cls);
					bool endofcache = false;
					while (!endofcache)
					{
						finder = StrContains(szMapEntities,cls,false);
						if (finder != -1)
						{
							Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[finder]);
							while (StrContains(tmpbuf,"{",false) != 0)
							{
								Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[finder--]);
							}
							int findend = StrContains(tmpbuf,"}",false);
							if (findend != -1) Format(tmpbuf,findend+2,"%s\n",tmpbuf);
							ReplaceString(szMapEntities,sizeof(szMapEntities),tmpbuf,"");
							if (dbglvl == 4) PrintToServer("Delete %s\n%s",cls,tmpbuf);
						}
						else endofcache = true;
					}
				}
			}
			if (GetArraySize(g_DeleteClassOrigin) > 0)
			{
				int finder = -1;
				int finderorg = -1;
				int finderorground = -1;
				int finderorground2dec = -1;
				int findend = -1;
				char clsorground[32];
				char clsorground2dec[32];
				char orgexpl[4096][32];
				int arrsize = ExplodeString(szMapEntities,"\n\"origin\" \"",orgexpl,4096,32);
				for (int i = 0;i<GetArraySize(g_DeleteClassOrigin);i++)
				{
					GetArrayString(g_DeleteClassOrigin,i,cls,sizeof(cls));
					ExplodeString(cls,",",tmpexpl,4,64);
					Format(cls,sizeof(cls),"\"classname\" \"%s\"",tmpexpl[0]);
					Format(clsorg,sizeof(clsorg),"\"origin\" \"%s\"",tmpexpl[1]);
					float org[3];
					ExplodeString(tmpexpl[1]," ",tmpexpl,4,64);
					org[0] = StringToFloat(tmpexpl[0]);
					org[1] = StringToFloat(tmpexpl[1]);
					org[2] = StringToFloat(tmpexpl[2]);
					Format(clsorground,sizeof(clsorground),"%i %i %i",RoundFloat(org[0]),RoundFloat(org[1]),RoundFloat(org[2]));
					Format(clsorground2dec,sizeof(clsorground2dec),"%1.2f %1.2f %1.2f",org[0],org[1],org[2]);
					ReplaceString(clsorground2dec,sizeof(clsorground2dec),".00","");
					finder = StrContains(szMapEntities,cls,false);
					finderorg = StrContains(szMapEntities,clsorg,false);
					finderorground = StrContains(szMapEntities,clsorground,false);
					finderorground2dec = StrContains(szMapEntities,clsorground2dec,false);
					if ((finderorg == -1) && (finderorground == -1) && (finderorground2dec == -1))
					{
						char orgoriginal[48];
						char orgrounded[48];
						for (int j = 0;j<arrsize;j++)
						{
							ExplodeString(orgexpl[j],"\n",tmpexpl,4,32);
							ReplaceString(tmpexpl[0],sizeof(tmpexpl[]),"\"","");
							Format(orgoriginal,sizeof(orgoriginal),"%s",tmpexpl[0]);
							ExplodeString(tmpexpl[0]," ",tmpexpl,4,32);
							org[0] = StringToFloat(tmpexpl[0]);
							org[1] = StringToFloat(tmpexpl[1]);
							org[2] = StringToFloat(tmpexpl[2]);
							Format(tmpbuf,sizeof(tmpbuf),"%1.2f %1.2f %1.2f",org[0],org[1],org[2]);
							Format(orgrounded,sizeof(orgrounded),"%i %i %i",RoundFloat(org[0]),RoundFloat(org[1]),RoundFloat(org[2]));
							ReplaceString(tmpbuf,sizeof(tmpbuf),".00","");
							finderorground2dec = StrContains(tmpbuf,clsorground2dec,false);
							finderorground = StrContains(orgrounded,clsorground,false);
							if ((finderorground2dec != -1) || (finderorground != -1))
							{
								Format(orgoriginal,sizeof(orgoriginal),"\"origin\" \"%s\"",orgoriginal);
								finderorground2dec = StrContains(szMapEntities,orgoriginal,false);
								break;
							}
						}
					}
					if ((finderorg == -1) && (finderorground2dec != -1)) finderorg = finderorground2dec;
					else if ((finderorg == -1) && (finderorground != -1)) finderorg = finderorground;
					if ((finder != -1) && (finderorg != -1))
					{
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finderorg]);
						while (StrContains(szMapEntitiesbuff,"{",false) != 0)
						{
							Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finderorg--]);
						}
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finderorg--]);
						findend = StrContains(szMapEntitiesbuff,"}",false);
						if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
						finder = StrContains(szMapEntitiesbuff,cls,false);
						if ((strlen(szMapEntitiesbuff) > 1) && (finder != -1))
						{
							bool reading = true;
							finderorg = StrContains(szMapEntitiesbuff,clsorg,false);
							finderorground = StrContains(szMapEntitiesbuff,clsorground,false);
							finderorground2dec = StrContains(szMapEntitiesbuff,clsorground2dec,false);
							int recheck = -1;
							while (reading)
							{
								recheck = StrContains(szMapEntitiesbuff,cls,false);
								if (recheck != -1)
								{
									finder = ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,"");
									if (dbglvl == 4) PrintToServer("Delete %s %s\n%s",cls,clsorg,szMapEntitiesbuff);
								}
								else if (recheck == -1) break;
								if (finder != -1)
								{
									Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder]);
									finder = StrContains(szMapEntities,cls,false);
									finderorg = StrContains(szMapEntities,clsorg,false);
									if ((finder != -1) && (finderorg != -1))
									{
										Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finderorg]);
										finderorground = StrContains(szMapEntitiesbuff,clsorground,false);
										finderorground2dec = StrContains(szMapEntitiesbuff,clsorground2dec,false);
										recheck = finderorg;
										if ((recheck == -1) && (finderorground2dec != -1)) recheck = finderorground2dec;
										else if ((recheck == -1) && (finderorground != -1)) recheck = finderorground;
										if ((finder != -1) && (finderorg != -1) && (recheck != -1))
										{
											findend = StrContains(szMapEntitiesbuff,"}",false);
											if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
											while (StrContains(szMapEntitiesbuff,"{",false) != 0)
											{
												Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finderorg--]);
											}
											findend = StrContains(szMapEntitiesbuff,"}",false);
											if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
										}
										else break;
									}
									else break;
								}
								else break;
							}
						}
					}
				}
			}
			if (GetArraySize(g_EditClasses) > 0)
			{
				int finder = -1;
				int findend = -1;
				int findstartpos = -1;
				Handle passedarr = INVALID_HANDLE;
				for (int i = 0;i<GetArraySize(g_EditClasses);i++)
				{
					bool lastent = false;
					GetArrayString(g_EditClasses,i,cls,sizeof(cls));
					Format(cls,sizeof(cls),"\"classname\" \"%s\"",cls);
					finder = StrContains(szMapEntities,cls,false);
					if (finder != -1)
					{
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder]);
						findend = StrContains(szMapEntitiesbuff,"}",false);
						if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
						Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
						while (StrContains(tmpbuf,"{",false) != 0)
						{
							Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[finder--]);
						}
						//Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
						findend = StrContains(tmpbuf,"}",false);
						if (findend != -1) Format(tmpbuf,findend+2,"%s\n",tmpbuf);
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
						finder = StrContains(szMapEntitiesbuff,cls,false);
						if ((strlen(szMapEntitiesbuff) > 1) && (finder != -1))
						{
							bool endofcache = false;
							while (!endofcache)
							{
								if (StrContains(szMapEntitiesbuff,cls,false) != -1)
								{
									if (dbglvl == 4) PrintToServer("Edit %s\n%s",cls,szMapEntitiesbuff);
									passedarr = GetArrayCell(g_EditClassesData,i);
									if (passedarr != INVALID_HANDLE)
									{
										for (int j = 0;j<GetArraySize(passedarr);j++)
										{
											GetArrayString(passedarr,j,edtdata,sizeof(edtdata));
											//ExplodeString(edtdata," ",tmpexpl,4,64);
											findend = StrContains(edtdata," ",false);
											if (findend != -1)
											{
												Format(edtkey,findend+1,"%s",edtdata);
											}
											//Format(edtkey,sizeof(edtkey),"%s",tmpexpl[0]);
											Format(edtval,sizeof(edtval),"%s",edtdata);
											ReplaceStringEx(edtval,sizeof(edtval),edtkey,"");
											TrimString(edtval);
											if (StrContains(edtkey,"\"",false) != -1) ReplaceString(edtkey,sizeof(edtkey),"\"","");
											Format(edtkey,sizeof(edtkey),"\"%s\"",edtkey);
											if (StrContains(edtval,"\"",false) != -1) ReplaceString(edtval,sizeof(edtval),"\"","");
											int findedit = StrContains(szMapEntitiesbuff,edtkey,false);
											if ((GetArraySize(passedarr) == 1) && (StrEqual(edtkey,"\"classname\"",false)))
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
												ExplodeString(tmpbuf,"\n",tmpexpl,4,64);
												Format(tmpexpl[1],sizeof(tmpexpl[]),"%s",tmpexpl[0]);
												findend = StrContains(tmpexpl[0]," ",false);
												if (findend != -1)
												{
													Format(tmpexpl[0],findend+1,"%s",tmpbuf);
													TrimString(tmpexpl[0]);
												}
												ReplaceStringEx(tmpexpl[1],sizeof(tmpexpl[]),tmpexpl[0],"");
												ReplaceString(tmpexpl[0],sizeof(tmpexpl[]),"\"","");
												ReplaceString(tmpexpl[1],sizeof(tmpexpl[]),"\"","");
												TrimString(tmpexpl[1]);
												if (strlen(tmpexpl[1]) < 3) Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[1]);
												else Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[1]);
												TrimString(replacedata);
												Format(edtkey,sizeof(edtkey),"%s \"%s\"",edtkey,edtval);
												ReplaceString(szMapEntities,sizeof(szMapEntities),replacedata,edtkey);
												if (dbglvl >= 3) PrintToServer("ReplaceAll %s with %s",replacedata,edtkey);
												break;
											}
											if (StrEqual(edtkey,"\"edt_map\"",false))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"map\" \"",false);
												if (findedit != -1)
												{
													Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
													ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"map\" ","");
													findend = StrContains(tmpbuf,"\n",false);
													if (findend != -1)
													{
														Format(tmpbuf,findend,"%s",tmpbuf);
														ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
														TrimString(tmpbuf);
														if (StrEqual(tmpbuf,edtval,false))
														{
															Format(edt_map,sizeof(edt_map),"%s",edtval);
															edtkey = "";
														}
														else break;
													}
												}
											}
											if (StrEqual(edtkey,"\"edt_landmark\"",false))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"landmark\" \"",false);
												if (findedit != -1)
												{
													Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
													ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"landmark\" ","");
													findend = StrContains(tmpbuf,"\n",false);
													if (findend != -1)
													{
														Format(tmpbuf,findend,"%s",tmpbuf);
														ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
														TrimString(tmpbuf);
														if (StrEqual(tmpbuf,edtval,false))
														{
															Format(edt_landmark,sizeof(edt_landmark),"%s",edtval);
															edtkey = "";
														}
														else break;
													}
												}
											}
											if (StrEqual(edtkey,"\"portalnumber\"",false))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"portalnumber\" \"",false);
												if (findedit != -1)
												{
													Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
													ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"portalnumber\" ","");
													findend = StrContains(tmpbuf,"\n",false);
													if (findend != -1)
													{
														Format(tmpbuf,findend,"%s",tmpbuf);
														ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
														TrimString(tmpbuf);
														if (StrEqual(tmpbuf,edtval,false))
														{
															Format(portalnumber,sizeof(portalnumber),"%s",edtval);
															edtkey = "";
														}
														else break;
													}
												}
												else edtkey = "";
											}
											if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_removespawnflags\"",false)))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"spawnflags\"",false);
											}
											//if ((findedit != -1) && (strlen(edt_landmark) > 0) && (strlen(edt_map) > 0))
											if ((findedit != -1) && (StrContains(edtkey,"\"On",false) != 0) && (StrContains(edtkey,"\"PlayerO",false) != 0) && (StrContains(edtkey,"\"Pressed",false) != 0) && (StrContains(edtkey,"\"Unpressed",false) != 0) && (strlen(edtkey) > 1))
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
												ExplodeString(tmpbuf,"\n",tmpexpl,4,64);
												ExplodeString(tmpexpl[0],"\" \"",tmpexpl,4,64);
												findend = StrContains(tmpexpl[0]," ",false);
												if (findend != -1)
												{
													Format(tmpexpl[0],findend+1,"%s",tmpbuf);
												}
												ReplaceStringEx(tmpexpl[1],sizeof(tmpexpl[]),tmpexpl[0],"");
												ReplaceString(tmpexpl[0],sizeof(tmpexpl[]),"\"","");
												ReplaceString(tmpexpl[1],sizeof(tmpexpl[]),"\"","");
												if (strlen(tmpexpl[1]) < 3) Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[1]);
												else Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[1]);
												TrimString(replacedata);
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
												if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)))
												{
													int curval = StringToInt(tmpexpl[1]);
													Format(edtval,sizeof(edtval),"%i",curval+StringToInt(edtval));
													Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
												}
												else if (StrEqual(edtkey,"\"edt_removespawnflags\"",false))
												{
													int checkneg = StringToInt(tmpexpl[1]);
													checkneg = checkneg-StringToInt(edtval);
													if (checkneg < 0) checkneg = 0;
													Format(edtval,sizeof(edtval),"%i",checkneg);
													Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
												}
												Format(edtkey,sizeof(edtkey),"%s \"%s\"",edtkey,edtval);
												if (StrEqual(edtkey,replacedata,false)) continue;
												if (dbglvl >= 3) PrintToServer("Replace %s with %s",replacedata,edtkey);
												ReplaceString(tmpbuf,sizeof(tmpbuf),replacedata,edtkey);
												if (StrContains(szMapEntities,szMapEntitiesbuff,false) != -1)
												{
													ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,tmpbuf);
													//Additional replaces
													Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
												}
											}
											else if ((strlen(szMapEntitiesbuff) > 0) && (strlen(edtkey) > 1))
											{
												//{
												//Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s%s",rmchar,szMapEntitiesbuff);
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
												ReplaceString(tmpbuf,sizeof(tmpbuf),"}","");
												if (StrContains(tmpbuf,"\n\n",false) != -1) ReplaceString(tmpbuf,sizeof(tmpbuf),"\n\n","\n");
												if (dbglvl >= 3) PrintToServer("Add KV to %s\n%s \"%s\"",cls,edtkey,edtval);
												Format(tmpbuf,sizeof(tmpbuf),"%s%s \"%s\"\n}\n",tmpbuf,edtkey,edtval);
												ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,tmpbuf);
												ReplaceString(szMapEntities,sizeof(szMapEntities),"\n\n","\n");
												Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
											}
										}
									}
								}
								findstartpos = StrContains(szMapEntities,szMapEntitiesbuff,false);
								if (findstartpos != -1)
								{
									findend = findstartpos;
									Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[findend]);
									finder = StrContains(szMapEntitiesbuff,"}",false);
									if ((finder != -1) && (!lastent))
									{
										if (finder > 2000) finder+=1000;
										finder+=findend;
										Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder+3]);
										finder = StrContains(szMapEntitiesbuff,cls,false);
										//PrintToServer("%i %s",finder,szMapEntitiesbuff);
										if (finder != -1)
										{
											if (finder > 2000) Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntitiesbuff[finder-1500]);
											findend = StrContains(szMapEntitiesbuff,"{",false);
											//PrintToServer("%i %i",finder,findend);
											while ((findend < finder) && (finder != -1) && (findend != -1))
											{
												Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntitiesbuff[findend+2]);
												finder = StrContains(szMapEntitiesbuff,cls,false);
												findend = StrContains(szMapEntitiesbuff,"{",false);
											}
											if ((findend == -1) || (finder == -1))
											{
												finder = StrContains(szMapEntities,szMapEntitiesbuff,false);
												if (finder != -1)
												{
													Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
													if (StrContains(szMapEntitiesbuff,"{",false) == -1) lastent = true;
													while (StrContains(szMapEntitiesbuff,"{",false) != 0)
													{
														if (finder-1 != -1) Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
														else break;
														//PrintToServer("Pos %i %i",StrContains(szMapEntitiesbuff,"{",false),finder);
													}
												}
											}
											findend = StrContains(szMapEntitiesbuff,"}",false);
											if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
											if (StrContains(szMapEntitiesbuff,"\n\n",false) != -1) ReplaceString(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"\n\n","\n");
										}
										else endofcache = true;
									}
									else endofcache = true;
								}
								else endofcache = true;
							}
						}
					}
				}
			}
			if (GetArraySize(g_EditClassOrigin) > 0)
			{
				int finder = -1;
				int finderorg = -1;
				int findend = -1;
				int findstartpos = -1;
				Handle passedarr = INVALID_HANDLE;
				char targned[128];
				for (int i = 0;i<GetArraySize(g_EditClassOrigin);i++)
				{
					int finderorground2dec = -1;
					GetArrayString(g_EditClassOrigin,i,cls,sizeof(cls));
					findend = StrContains(cls,",",false);
					if (findend != -1)
					{
						Format(clsorg,sizeof(clsorg),"\"origin\" \"%s\"",cls[findend+1]);
						ReplaceStringEx(cls,sizeof(cls),cls[findend],"");
					}
					Format(targned,sizeof(targned),"\"targetname\" \"%s\"",cls);
					Format(cls,sizeof(cls),"\"classname\" \"%s\"",cls);
					finder = StrContains(szMapEntities,clsorg,false);
					if (finder == -1) finder = StrContains(szMapEntities,targned,false);
					if (finder == -1)
					{
						float org[3];
						char orgexpl[4096][32];
						int arrsize = ExplodeString(szMapEntities,"\n\"origin\" \"",orgexpl,4096,32);
						int finderorground = -1;
						char orgoriginal[48];
						char orgrounded[48];
						char clsorground2dec[48];
						char clsorground[48];
						Format(tmpbuf,sizeof(clsorg),"%s",clsorg);
						ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"origin\" \"","");
						ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
						ExplodeString(tmpbuf," ",tmpexpl,4,64);
						org[0] = StringToFloat(tmpexpl[0]);
						org[1] = StringToFloat(tmpexpl[1]);
						org[2] = StringToFloat(tmpexpl[2]);
						Format(clsorground,sizeof(clsorground),"%i %i %i",RoundFloat(org[0]),RoundFloat(org[1]),RoundFloat(org[2]));
						Format(clsorground2dec,sizeof(clsorground2dec),"%1.2f %1.2f %1.2f",org[0],org[1],org[2]);
						ReplaceString(clsorground2dec,sizeof(clsorground2dec),".00","");
						for (int j = 0;j<arrsize;j++)
						{
							ExplodeString(orgexpl[j],"\n",tmpexpl,4,32);
							ReplaceString(tmpexpl[0],sizeof(tmpexpl[]),"\"","");
							Format(orgoriginal,sizeof(orgoriginal),"%s",tmpexpl[0]);
							ExplodeString(tmpexpl[0]," ",tmpexpl,4,32);
							org[0] = StringToFloat(tmpexpl[0]);
							org[1] = StringToFloat(tmpexpl[1]);
							org[2] = StringToFloat(tmpexpl[2]);
							Format(tmpbuf,sizeof(tmpbuf),"%1.2f %1.2f %1.2f",org[0],org[1],org[2]);
							Format(orgrounded,sizeof(orgrounded),"%i %i %i",RoundFloat(org[0]),RoundFloat(org[1]),RoundFloat(org[2]));
							ReplaceString(tmpbuf,sizeof(tmpbuf),".00","");
							finderorground2dec = StrContains(tmpbuf,clsorground2dec,false);
							finderorground = StrContains(orgrounded,clsorground,false);
							if ((finderorground2dec != -1) || (finderorground != -1))
							{
								Format(orgoriginal,sizeof(orgoriginal),"\"origin\" \"%s\"",orgoriginal);
								finderorground2dec = StrContains(szMapEntities,orgoriginal,false);
								Format(clsorg,sizeof(clsorg),"%s",orgoriginal);
								break;
							}
						}
						if (finderorground2dec != -1) finder = finderorground2dec;
					}
					if (finder != -1)
					{
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder]);
						while (StrContains(szMapEntitiesbuff,"{",false) != 0)
						{
							Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
						}
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
						findend = StrContains(szMapEntitiesbuff,"}",false);
						if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
						finder = StrContains(szMapEntitiesbuff,clsorg,false);
						if ((strlen(szMapEntitiesbuff) > 1) && (finder != -1))
						{
							bool endofcache = false;
							while (!endofcache)
							{
								finderorg = StrContains(szMapEntitiesbuff,clsorg,false);
								if ((finderorg != -1) && (StrContains(szMapEntitiesbuff,cls,false) != -1))
								{
									if (dbglvl == 4) PrintToServer("Edit %s\n%s",cls,szMapEntitiesbuff);
									passedarr = GetArrayCell(g_EditClassOrgData,i);
									if (passedarr != INVALID_HANDLE)
									{
										for (int j = 0;j<GetArraySize(passedarr);j++)
										{
											GetArrayString(passedarr,j,edtdata,sizeof(edtdata));
											//ExplodeString(edtdata," ",tmpexpl,4,64);
											findend = StrContains(edtdata," ",false);
											if (findend != -1)
											{
												Format(edtkey,findend+1,"%s",edtdata);
											}
											//Format(edtkey,sizeof(edtkey),"%s",tmpexpl[0]);
											Format(edtval,sizeof(edtval),"%s",edtdata);
											ReplaceStringEx(edtval,sizeof(edtval),edtkey,"");
											TrimString(edtval);
											if (StrContains(edtkey,"\"",false) != -1) ReplaceString(edtkey,sizeof(edtkey),"\"","");
											Format(edtkey,sizeof(edtkey),"\"%s\"",edtkey);
											if (StrContains(edtval,"\"",false) != -1) ReplaceString(edtval,sizeof(edtval),"\"","");
											int findedit = StrContains(szMapEntitiesbuff,edtkey,false);
											if (StrEqual(edtkey,"\"edt_map\"",false))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"map\" \"",false);
												if (findedit != -1)
												{
													Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
													ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"map\" ","");
													findend = StrContains(tmpbuf,"\n",false);
													if (findend != -1)
													{
														Format(tmpbuf,findend,"%s",tmpbuf);
														ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
														TrimString(tmpbuf);
														if (StrEqual(tmpbuf,edtval,false))
														{
															Format(edt_map,sizeof(edt_map),"%s",edtval);
															edtkey = "";
														}
														else break;
													}
												}
											}
											if (StrEqual(edtkey,"\"edt_landmark\"",false))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"landmark\" \"",false);
												if (findedit != -1)
												{
													Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
													ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"landmark\" ","");
													findend = StrContains(tmpbuf,"\n",false);
													if (findend != -1)
													{
														Format(tmpbuf,findend,"%s",tmpbuf);
														ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
														TrimString(tmpbuf);
														if (StrEqual(tmpbuf,edtval,false))
														{
															Format(edt_landmark,sizeof(edt_landmark),"%s",edtval);
															edtkey = "";
														}
														else break;
													}
												}
											}
											if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_removespawnflags\"",false)))
											{
												findedit = StrContains(szMapEntitiesbuff,"\"spawnflags\"",false);
											}
											//if ((findedit != -1) && (strlen(edt_landmark) > 0) && (strlen(edt_map) > 0))
											if ((findedit != -1) && (StrContains(edtkey,"\"On",false) != 0) && (StrContains(edtkey,"\"PlayerO",false) != 0) && (StrContains(edtkey,"\"Pressed",false) != 0) && (StrContains(edtkey,"\"Unpressed",false) != 0) && (strlen(edtkey) > 1))
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
												ExplodeString(tmpbuf,"\n",tmpexpl,4,64);
												Format(tmpexpl[1],sizeof(tmpexpl[]),"%s",tmpexpl[0]);
												findend = StrContains(tmpexpl[0]," ",false);
												if (findend != -1)
												{
													Format(tmpexpl[0],findend+1,"%s",tmpbuf);
													TrimString(tmpexpl[0]);
												}
												ReplaceStringEx(tmpexpl[1],sizeof(tmpexpl[]),tmpexpl[0],"");
												ReplaceString(tmpexpl[0],sizeof(tmpexpl[]),"\"","");
												ReplaceString(tmpexpl[1],sizeof(tmpexpl[]),"\"","");
												TrimString(tmpexpl[1]);
												if (strlen(tmpexpl[1]) < 3) Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[1]);
												else Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[1]);
												TrimString(replacedata);
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
												if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)))
												{
													int curval = StringToInt(tmpexpl[1]);
													Format(edtval,sizeof(edtval),"%i",curval+StringToInt(edtval));
													Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
												}
												else if (StrEqual(edtkey,"\"edt_removespawnflags\"",false))
												{
													int checkneg = StringToInt(tmpexpl[1]);
													checkneg = checkneg-StringToInt(edtval);
													if (checkneg < 0) checkneg = 0;
													Format(edtval,sizeof(edtval),"%i",checkneg);
													Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
												}
												Format(edtkey,sizeof(edtkey),"%s \"%s\"",edtkey,edtval);
												if (StrEqual(edtkey,replacedata,false)) continue;
												if (dbglvl >= 3) PrintToServer("Replace %s with %s",replacedata,edtkey);
												ReplaceString(tmpbuf,sizeof(tmpbuf),replacedata,edtkey);
												if (StrContains(szMapEntities,szMapEntitiesbuff,false) != -1)
												{
													ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,tmpbuf);
													//Additional replaces
													Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
												}
											}
											else if ((strlen(szMapEntitiesbuff) > 0) && (strlen(edtkey) > 1))
											{
												//{
												//Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s%s",rmchar,szMapEntitiesbuff);
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
												ReplaceString(tmpbuf,sizeof(tmpbuf),"}","");
												if (StrContains(tmpbuf,"\n\n",false) != -1) ReplaceString(tmpbuf,sizeof(tmpbuf),"\n\n","\n");
												if (dbglvl >= 3) PrintToServer("Add KV to %s\n%s \"%s\"",cls,edtkey,edtval);
												Format(tmpbuf,sizeof(tmpbuf),"%s%s \"%s\"\n}\n",tmpbuf,edtkey,edtval);
												ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,tmpbuf);
												Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
											}
										}
									}
								}
								findstartpos = StrContains(szMapEntities,szMapEntitiesbuff,false);
								if (findstartpos != -1)
								{
									findend = findstartpos;
									Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[findend]);
									finder = StrContains(szMapEntitiesbuff,"}",false);
									if (finder != -1)
									{
										finder+=findend;
										Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder+1]);
										finder = StrContains(szMapEntitiesbuff,clsorg,false);
										if (finder != -1)
										{
											findend = StrContains(szMapEntitiesbuff,"{",false);
											while (findend < finder)
											{
												Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntitiesbuff[findend+1]);
												finder = StrContains(szMapEntitiesbuff,clsorg,false);
												findend = StrContains(szMapEntitiesbuff,"{",false);
											}
											findend = StrContains(szMapEntitiesbuff,"}",false);
											if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
											if (StrContains(szMapEntitiesbuff,"\n\n",false) != -1) ReplaceString(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"\n\n","\n");
										}
										else endofcache = true;
									}
									else endofcache = true;
								}
								else endofcache = true;
							}
						}
					}
				}
			}
			if (GetArraySize(g_EditTargets) > 0)
			{
				int finder = -1;
				int findend = -1;
				int findstartpos = -1;
				Handle passedarr = INVALID_HANDLE;
				for (int i = 0;i<GetArraySize(g_EditTargets);i++)
				{
					bool lastent = false;
					GetArrayString(g_EditTargets,i,cls,sizeof(cls));
					Format(cls,sizeof(cls),"\"targetname\" \"%s\"",cls);
					finder = StrContains(szMapEntities,cls,false);
					if (finder != -1)
					{
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder]);
						while (StrContains(szMapEntitiesbuff,"{",false) != 0)
						{
							Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
						}
						Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
						findend = StrContains(szMapEntitiesbuff,"}",false);
						if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
						finder = StrContains(szMapEntitiesbuff,cls,false);
						if ((strlen(szMapEntitiesbuff) > 1) && (finder != -1))
						{
							bool endofcache = false;
							while (!endofcache)
							{
								if (dbglvl == 4) PrintToServer("Edit %s\n%s",cls,szMapEntitiesbuff);
								passedarr = GetArrayCell(g_EditTargetsData,i);
								if (passedarr != INVALID_HANDLE)
								{
									for (int j = 0;j<GetArraySize(passedarr);j++)
									{
										GetArrayString(passedarr,j,edtdata,sizeof(edtdata));
										//ExplodeString(edtdata," ",tmpexpl,4,64);
										findend = StrContains(edtdata," ",false);
										if (findend != -1)
										{
											Format(edtkey,findend+1,"%s",edtdata);
										}
										//Format(edtkey,sizeof(edtkey),"%s",tmpexpl[0]);
										Format(edtval,sizeof(edtval),"%s",edtdata);
										ReplaceStringEx(edtval,sizeof(edtval),edtkey,"");
										TrimString(edtval);
										if (StrContains(edtkey,"\"",false) != -1) ReplaceString(edtkey,sizeof(edtkey),"\"","");
										Format(edtkey,sizeof(edtkey),"\"%s\"",edtkey);
										if (StrContains(edtval,"\"",false) != -1) ReplaceString(edtval,sizeof(edtval),"\"","");
										int findedit = StrContains(szMapEntitiesbuff,edtkey,false);
										if (StrEqual(edtkey,"\"edt_map\"",false))
										{
											findedit = StrContains(szMapEntitiesbuff,"\"map\" \"",false);
											if (findedit != -1)
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
												ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"map\" ","");
												findend = StrContains(tmpbuf,"\n",false);
												if (findend != -1)
												{
													Format(tmpbuf,findend,"%s",tmpbuf);
													ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
													TrimString(tmpbuf);
													if (StrEqual(tmpbuf,edtval,false))
													{
														Format(edt_map,sizeof(edt_map),"%s",edtval);
														edtkey = "";
													}
													else break;
												}
											}
										}
										if (StrEqual(edtkey,"\"edt_landmark\"",false))
										{
											findedit = StrContains(szMapEntitiesbuff,"\"landmark\" \"",false);
											if (findedit != -1)
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
												ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"landmark\" ","");
												findend = StrContains(tmpbuf,"\n",false);
												if (findend != -1)
												{
													Format(tmpbuf,findend,"%s",tmpbuf);
													ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
													TrimString(tmpbuf);
													if (StrEqual(tmpbuf,edtval,false))
													{
														Format(edt_landmark,sizeof(edt_landmark),"%s",edtval);
														edtkey = "";
													}
													else break;
												}
											}
										}
										if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_removespawnflags\"",false)))
										{
											findedit = StrContains(szMapEntitiesbuff,"\"spawnflags\"",false);
										}
										//if ((findedit != -1) && (strlen(edt_landmark) > 0) && (strlen(edt_map) > 0))
										if ((findedit != -1) && (StrContains(edtkey,"\"On",false) != 0) && (StrContains(edtkey,"\"PlayerO",false) != 0) && (StrContains(edtkey,"\"Pressed",false) != 0) && (StrContains(edtkey,"\"Unpressed",false) != 0) && (strlen(edtkey) > 1))
										{
											Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff[findedit]);
											ExplodeString(tmpbuf,"\n",tmpexpl,4,64);
											//ExplodeString(tmpexpl[0]," ",tmpexpl,4,64);
											findend = StrContains(tmpexpl[0]," ",false);
											if (findend != -1)
											{
												Format(replacedata,findend+1,"%s",tmpexpl[0]);
												Format(tmpexpl[1],sizeof(tmpexpl[]),"%s",tmpexpl[0]);
											}
											ReplaceString(replacedata,sizeof(replacedata),"\"","");
											ReplaceStringEx(tmpexpl[1],sizeof(tmpexpl[]),replacedata,"");
											ReplaceString(tmpexpl[1],sizeof(tmpexpl[]),"\"","");
											TrimString(tmpexpl[1]);
											Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",replacedata,tmpexpl[1]);
											TrimString(replacedata);
											Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
											if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)))
											{
												int curval = StringToInt(tmpexpl[1]);
												Format(edtval,sizeof(edtval),"%i",curval+StringToInt(edtval));
												Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
											}
											else if (StrEqual(edtkey,"\"edt_removespawnflags\"",false))
											{
												int checkneg = StringToInt(tmpexpl[1]);
												checkneg = checkneg-StringToInt(edtval);
												if (checkneg < 0) checkneg = 0;
												Format(edtval,sizeof(edtval),"%i",checkneg);
												Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
											}
											Format(edtkey,sizeof(edtkey),"%s \"%s\"",edtkey,edtval);
											if (StrEqual(edtkey,replacedata,false)) continue;
											if (dbglvl >= 3) PrintToServer("Replace %s with %s",replacedata,edtkey);
											ReplaceString(tmpbuf,sizeof(tmpbuf),replacedata,edtkey);
											if (StrContains(szMapEntities,szMapEntitiesbuff,false) != -1)
											{
												ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,tmpbuf);
												//Additional replaces
												Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
											}
										}
										else if ((strlen(szMapEntitiesbuff) > 0) && (strlen(edtkey) > 1))
										{
											//{
											//Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s%s",rmchar,szMapEntitiesbuff);
											Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntitiesbuff);
											ReplaceString(tmpbuf,sizeof(tmpbuf),"}","");
											if (StrContains(tmpbuf,"\n\n",false) != -1) ReplaceString(tmpbuf,sizeof(tmpbuf),"\n\n","\n");
											if (dbglvl >= 3) PrintToServer("Add KV to %s\n%s \"%s\"",cls,edtkey,edtval);
											Format(tmpbuf,sizeof(tmpbuf),"%s%s \"%s\"\n}\n",tmpbuf,edtkey,edtval);
											ReplaceStringEx(szMapEntities,sizeof(szMapEntities),szMapEntitiesbuff,tmpbuf);
											Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",tmpbuf);
										}
									}
								}
								findstartpos = StrContains(szMapEntities,szMapEntitiesbuff,false);
								if (findstartpos != -1)
								{
									findend = findstartpos+strlen(szMapEntitiesbuff);
									Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[findend]);
									finder = StrContains(szMapEntitiesbuff,cls,false);
									//PrintToServer("Contain %s %i %i",cls,findend,finder);
									if ((finder != -1) && (!lastent))
									{
										finder+=findend;
										Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder+1]);
										findend = StrContains(szMapEntitiesbuff,"}",false);
										if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s\n",szMapEntitiesbuff);
										if (StrContains(szMapEntitiesbuff,"{",false) == -1) lastent = true;
										while (StrContains(szMapEntitiesbuff,"{",false) != 0)
										{
											if (finder-1 != -1) Format(szMapEntitiesbuff,sizeof(szMapEntitiesbuff),"%s",szMapEntities[finder--]);
											else break;
											//PrintToServer("Pos %i",StrContains(szMapEntitiesbuff,"{",false));
										}
										findend = StrContains(szMapEntitiesbuff,"}",false);
										if (findend != -1) Format(szMapEntitiesbuff,findend+2,"%s",szMapEntitiesbuff);
										//PrintToServer("CheckNext %s",szMapEntitiesbuff);
									}
									else endofcache = true;
								}
								else endofcache = true;
							}
						}
					}
				}
			}
			if (RemoveGlobals)
			{
				char globalremove[64];
				int findglobals = StrContains(szMapEntities,"\"globalname\" \"",false);
				if (findglobals != -1)
				{
					Format(globalremove,sizeof(globalremove),"%s",szMapEntities[findglobals]);
					ExplodeString(globalremove,"\n",tmpexpl,4,64);
					Format(globalremove,sizeof(globalremove),"%s",tmpexpl[0]);
					TrimString(globalremove);
					ReplaceString(szMapEntities,sizeof(szMapEntities),globalremove,"");
					if (dbglvl > 2) PrintToServer("Removed global name %s",globalremove);
					bool endofcache = false;
					while (!endofcache)
					{
						findglobals = StrContains(szMapEntities,"\"globalname\" \"",false);
						if (findglobals != -1)
						{
							Format(globalremove,sizeof(globalremove),"%s",szMapEntities[findglobals]);
							ExplodeString(globalremove,"\n",tmpexpl,4,64);
							Format(globalremove,sizeof(globalremove),"%s",tmpexpl[0]);
							TrimString(globalremove);
							ReplaceString(szMapEntities,sizeof(szMapEntities),globalremove,"");
							if (dbglvl > 2) PrintToServer("Removed global name %s",globalremove);
						}
						else endofcache = true;
					}
				}
			}
			if (strlen(tmpwriter) > 0) StrCat(szMapEntities,sizeof(szMapEntities),tmpwriter);
			ReplaceString(szMapEntities,sizeof(szMapEntities),"\n\n","\n");
		}
		else
		{
			char curbuf[4096][512];
			char rmchar[2];
			Format(rmchar,sizeof(rmchar),"%s%s",szMapEntities[0],szMapEntities[1]);
			int lastarr = ExplodeString(szMapEntities,"{",curbuf,4096,512);
			char tmpline[6148];
			char tmpbuf[4096];
			char buffadded[6148];
			char cls[64];
			char clsorg[64];
			char clsorground[64];
			char originch[64];
			char globalremove[64];
			char targn[64];
			char tmpexpl[4][64];
			char edtdata[128];
			char replacedata[128];
			char edt_map[64];
			char edt_landmark[64];
			char portalnumber[32];
			char edtkey[128];
			char edtval[128];
			Format(tmpline,sizeof(tmpline),"%s",curbuf[lastarr-1]);
			int findbufend = StrContains(szMapEntities,tmpline,false);
			if (StrContains(tmpline,"}",false) == -1)
			{
				Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findbufend+strlen(tmpline)]);
				int findend = StrContains(tmpbuf,"}",false);
				if (findend != -1)
				{
					Format(tmpbuf,findend+2,"%s",tmpbuf);
					Format(tmpline,sizeof(tmpline),"%s%s",tmpline,tmpbuf);
				}
			}
			if (StrContains(tmpline,"}",false) == -1) StrCat(szMapEntities,sizeof(szMapEntities),"}");
			bool CheckDelClasses,CheckEdClasses,CheckDelClassorg,CheckDelTargets,CheckEdClassOrg,CheckEdTargets;
			if (GetArraySize(g_DeleteTargets) > 0) CheckDelTargets = true;
			if (GetArraySize(g_EditClassOrigin) > 0) CheckEdClassOrg = true;
			if (GetArraySize(g_EditTargets) > 0) CheckEdTargets = true;
			if (GetArraySize(g_DeleteClasses) > 0) CheckDelClasses = true;
			if (GetArraySize(g_EditClasses) > 0) CheckEdClasses = true;
			if (GetArraySize(g_DeleteClassOrigin) > 0) CheckDelClassorg = true;
			//Need to run create first for edt_getbspmodelfor_* keys
			if (GetArraySize(g_CreateEnts) > 0)
			{
				for (int k = 0;k<GetArraySize(g_CreateEnts);k++)
				{
					Handle passedarr = GetArrayCell(g_CreateEnts,k);
					if (passedarr != INVALID_HANDLE)
					{
						char edtclass[64];
						char edtclassorg[64];
						Format(tmpbuf,sizeof(tmpbuf),"\n{");
						for (int j = 0;j<GetArraySize(passedarr);j++)
						{
							char first[128];
							GetArrayString(passedarr,j,first,sizeof(first));
							char second[128];
							Format(second,sizeof(second),"%s",first);
							int secondpos = StrContains(first," ",false);
							if (secondpos != -1)
							{
								Format(second,sizeof(second),"%s",second[secondpos]);
								ReplaceStringEx(first,sizeof(first),second,"");
								ReplaceString(first,sizeof(first),"\"","");
								ReplaceString(second,sizeof(second),"\"","");
								TrimString(first);
								TrimString(second);
								if (StrEqual(first,"edt_getbspmodelfor_targetname",false))
								{
									char findtn[128];
									Format(findtn,sizeof(findtn),"\"targetname\" \"%s\"",second);
									for (int i = 1;i<4096;i++)
									{
										if (strlen(curbuf[i]) > 0)
										{
											if (StrContains(curbuf[i],findtn,false) != -1)
											{
												int findmdl = StrContains(curbuf[i],"\"model\"",false);
												if (findmdl != -1)
												{
													Format(tmpline,sizeof(tmpline),"%s",curbuf[i]);
													Format(tmpline,sizeof(tmpline),"%s",tmpline[findmdl]);
													ExplodeString(tmpline,"\"",tmpexpl,4,64);
													Format(first,sizeof(first),"model");
													Format(second,sizeof(second),"%s",tmpexpl[3]);
												}
												else
												{
													PrintToServer("Failed to get BSP Model from Targetname %s",second);
												}
												break;
											}
										}
									}
								}
								if (StrEqual(first,"edt_getbspmodelfor_classname",false))
								{
									Format(edtclass,sizeof(edtclass),"%s",second);
								}
								else if (StrEqual(first,"edt_getbspmodelfor_origin",false))
								{
									Format(edtclassorg,sizeof(edtclassorg),"%s",second);
								}
								else Format(tmpbuf,sizeof(tmpbuf),"%s\n\"%s\" \"%s\"",tmpbuf,first,second);
							}
						}
						if ((strlen(edtclass) > 0) && (strlen(edtclassorg) > 0))
						{
							char findclass[128];
							Format(findclass,sizeof(findclass),"\"classname\" \"%s\"",edtclass);
							char findorg[128];
							Format(findorg,sizeof(findorg),"\"origin\" \"%s\"",edtclassorg);
							for (int i = 1;i<4096;i++)
							{
								if (strlen(curbuf[i]) > 0)
								{
									if ((StrContains(curbuf[i],findclass,false) != -1) && (StrContains(curbuf[i],findorg,false) != -1))
									{
										int findmdl = StrContains(curbuf[i],"\"model\"",false);
										if (findmdl != -1)
										{
											Format(tmpline,sizeof(tmpline),"%s",curbuf[i]);
											Format(tmpline,sizeof(tmpline),"%s",tmpline[findmdl]);
											ExplodeString(tmpline,"\"",tmpexpl,4,64);
											Format(tmpbuf,sizeof(tmpbuf),"%s\n\"model\" \"%s\"",tmpbuf,tmpexpl[3]);
										}
										else
										{
											PrintToServer("Failed to get BSP Model from Classname %s at origin %s",edtclass,edtclassorg);
										}
										break;
									}
								}
							}
						}
						Format(tmpbuf,sizeof(tmpbuf),"%s\n}",tmpbuf);
						if (dbglvl == 4) PrintToServer("Create %s",tmpbuf);
						StrCat(szMapEntities,sizeof(szMapEntities),tmpbuf);
						CloseHandle(passedarr);
					}
				}
			}
			for (int i = 1;i<4096;i++)
			{
				if (strlen(curbuf[i]) > 0)
				{
					Format(tmpline,sizeof(tmpline),"%s",curbuf[i]);
					findbufend = StrContains(szMapEntities,tmpline,false);
					if (StrContains(tmpline,"}",false) == -1)
					{
						Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findbufend+strlen(tmpline)]);
						int findend = StrContains(tmpbuf,"}",false);
						if (findend != -1)
						{
							Format(tmpbuf,findend+2,"%s",tmpbuf);
							Format(tmpline,sizeof(tmpline),"%s%s",tmpline,tmpbuf);
						}
					}
					bool RunEDT = false;
					if (CheckDelClasses)
					{
						for (int j = 0;j<GetArraySize(g_DeleteClasses);j++)
						{
							GetArrayString(g_DeleteClasses,j,cls,sizeof(cls));
							if (StrContains(tmpline,cls,false) != -1)
							{
								RunEDT = true;
								break;
							}
						}
					}
					if ((!RunEDT) && (CheckEdClasses))
					{
						for (int j = 0;j<GetArraySize(g_EditClasses);j++)
						{
							GetArrayString(g_EditClasses,j,cls,sizeof(cls));
							if (StrContains(tmpline,cls,false) != -1)
							{
								RunEDT = true;
								break;
							}
						}
					}
					if ((!RunEDT) && (CheckDelTargets))
					{
						for (int j = 0;j<GetArraySize(g_DeleteTargets);j++)
						{
							GetArrayString(g_DeleteTargets,j,cls,sizeof(cls));
							if (StrContains(tmpline,cls,false) != -1)
							{
								RunEDT = true;
								break;
							}
						}
					}
					if ((!RunEDT) && (CheckEdTargets))
					{
						for (int j = 0;j<GetArraySize(g_EditTargets);j++)
						{
							GetArrayString(g_EditTargets,j,cls,sizeof(cls));
							if (StrContains(tmpline,cls,false) != -1)
							{
								RunEDT = true;
								break;
							}
						}
					}
					if ((!RunEDT) && (CheckDelClassorg))
					{
						for (int j = 0;j<GetArraySize(g_DeleteClassOrigin);j++)
						{
							GetArrayString(g_DeleteClassOrigin,j,cls,sizeof(cls));
							int findend = StrContains(cls,",",false);
							if (findend != -1)
							{
								Format(clsorg,findend+1,"%s",cls);
								ReplaceString(cls,sizeof(cls),clsorg,"");
								ReplaceString(cls,sizeof(cls),",","");
								if (StrContains(tmpline,cls,false) != -1)
								{
									RunEDT = true;
									break;
								}
							}
						}
					}
					if ((!RunEDT) && (CheckEdClassOrg))
					{
						for (int j = 0;j<GetArraySize(g_EditClassOrigin);j++)
						{
							GetArrayString(g_EditClassOrigin,j,cls,sizeof(cls));
							int findend = StrContains(cls,",",false);
							if (findend != -1)
							{
								Format(clsorg,findend+1,"%s",cls);
								ReplaceString(cls,sizeof(cls),clsorg,"");
								ReplaceString(cls,sizeof(cls),",","");
								if (StrContains(tmpline,cls,false) != -1)
								{
									RunEDT = true;
									break;
								}
							}
						}
					}
					if (RunEDT)
					{
						originch = "";
						cls = "";
						clsorground = "";
						targn = "";
						//if (StrContains(curbuf[i],"",false) != -1) ReplaceString(curbuf[i],sizeof(curbuf[]),"",",");
						if (RemoveGlobals)
						{
							int findglobals = StrContains(tmpline,"\"globalname\"",false);
							if (findglobals != -1)
							{
								Format(globalremove,sizeof(globalremove),"%s",tmpline[findglobals]);
								ExplodeString(globalremove,"\"",tmpexpl,4,64);
								Format(globalremove,sizeof(globalremove),"%s",tmpexpl[3]);
								TrimString(globalremove);
								Format(globalremove,sizeof(globalremove),"\"globalname\" \"%s\"\n",globalremove);
								ReplaceString(szMapEntities,sizeof(szMapEntities),globalremove,"");
								ReplaceString(tmpline,sizeof(tmpline),globalremove,"");
							}
						}
						int findcls = StrContains(tmpline,"\"classname\" \"",false);
						if (findcls != -1)
						{
							Format(cls,sizeof(cls),"%s",tmpline[findcls]);
							ReplaceStringEx(cls,sizeof(cls),"\"classname\" \"","");
							int findend = StrContains(cls,"\"",false);
							if (findend != -1)
							{
								Format(cls,findend+1,"%s",cls);
								ReplaceString(cls,sizeof(cls),"\"","");
								TrimString(cls);
							}
							else
							{
								Format(cls,sizeof(cls),"%s",tmpline[findcls]);
								ExplodeString(cls,"\"",tmpexpl,4,64);
								Format(cls,sizeof(cls),"%s",tmpexpl[3]);
								TrimString(cls);
							}
						}
						int findorg = StrContains(tmpline,"\"origin\" \"",false);
						if (findorg != -1)
						{
							Format(originch,sizeof(originch),"%s",tmpline[findorg]);
							ReplaceStringEx(originch,sizeof(originch),"\"origin\" \"","");
							int findend = StrContains(originch,"\"",false);
							if (findend != -1)
							{
								Format(originch,findend+1,"%s",originch);
								ReplaceString(originch,sizeof(originch),"\"","");
								TrimString(originch);
							}
							else
							{
								Format(originch,sizeof(originch),"%s",tmpline[findorg]);
								ExplodeString(originch,"\"",tmpexpl,4,64);
								Format(originch,sizeof(originch),"%s",tmpexpl[3]);
								TrimString(originch);
							}
						}
						int findtargn = StrContains(tmpline,"\"targetname\" \"",false);
						if (findtargn != -1)
						{
							Format(targn,sizeof(targn),"%s",tmpline[findtargn]);
							ReplaceStringEx(targn,sizeof(targn),"\"targetname\" \"","");
							int findend = StrContains(targn,"\"",false);
							if (findend != -1)
							{
								Format(targn,findend+1,"%s",targn);
								ReplaceString(targn,sizeof(targn),"\"","");
								TrimString(targn);
							}
							else
							{
								Format(targn,sizeof(targn),"%s",tmpline[findtargn]);
								ExplodeString(targn,"\"",tmpexpl,4,64);
								Format(targn,sizeof(targn),"%s",tmpexpl[3]);
								TrimString(targn);
							}
						}
						Format(clsorg,sizeof(clsorg),"%s,%s",cls,originch);
						if (StrEqual(cls,"logic_auto",false))
						{
							float org[3];
							ExplodeString(originch," ",tmpexpl,4,64);
							org[0] = StringToFloat(tmpexpl[0]);
							org[1] = StringToFloat(tmpexpl[1]);
							org[2] = StringToFloat(tmpexpl[2]);
							Format(clsorground,sizeof(clsorground),"%s,%i %i %i",cls,RoundFloat(org[0]),RoundFloat(org[1]),RoundFloat(org[2]));
						}
						if ((FindStringInArray(g_DeleteClasses,cls) != -1) || (FindStringInArray(g_DeleteClassOrigin,clsorg) != -1) || ((FindStringInArray(g_DeleteClassOrigin,clsorground) != -1) && (strlen(clsorground) > 0)) || ((FindStringInArray(g_DeleteTargets,targn) != -1) && (strlen(targn) > 0)))
						{
							int findprev = StrContains(szMapEntities,tmpline,false);
							if (findprev != -1)
							{
								Format(tmpline,sizeof(tmpline),"%s%s",rmchar,tmpline);
								ReplaceString(szMapEntities,sizeof(szMapEntities),tmpline,"");
								if (dbglvl == 4) PrintToServer("Delete %s\n%s from %s %i %i",cls,tmpline,clsorg,FindStringInArray(g_DeleteClassOrigin,clsorg),FindStringInArray(g_DeleteClasses,cls));
								/*
								if (StrContains(tmpline,"}",false) == -1)
								{
									Format(tmpbuf,sizeof(tmpbuf),"%s",szMapEntities[findprev-1]);
									int findend = StrContains(tmpbuf,"}",false);
									if (findend != -1)
									{
										Format(tmpbuf,findend+2,"%s",tmpbuf);
									}
									//PrintToServer("RM %s %i",tmpbuf,findend);
									ReplaceString(szMapEntities,sizeof(szMapEntities),tmpbuf,"");
								}
								*/
							}
						}
						else if ((FindStringInArray(g_EditClasses,cls) != -1) || (FindStringInArray(g_EditClassOrigin,clsorg) != -1) || (FindStringInArray(g_EditTargets,targn) != -1))
						{
							Handle passedarr = INVALID_HANDLE;
							int findarr = FindStringInArray(g_EditTargets,targn);
							if (findarr != -1) passedarr = GetArrayCell(g_EditTargetsData,findarr);
							if (findarr == -1) findarr = FindStringInArray(g_EditClassOrigin,clsorg);
							if ((findarr != -1) && (passedarr == INVALID_HANDLE)) passedarr = GetArrayCell(g_EditClassOrgData,findarr);
							if (findarr == -1) findarr = FindStringInArray(g_EditClasses,cls);
							if ((findarr != -1) && (passedarr == INVALID_HANDLE)) passedarr = GetArrayCell(g_EditClassesData,findarr);
							if (findarr != -1)
							{
								if (passedarr != INVALID_HANDLE)
								{
									for (int j = 0;j<GetArraySize(passedarr);j++)
									{
										GetArrayString(passedarr,j,edtdata,sizeof(edtdata));
										//ExplodeString(edtdata," ",tmpexpl,4,64);
										int findend = StrContains(edtdata," ",false);
										if (findend != -1)
										{
											Format(edtkey,findend+1,"%s",edtdata);
										}
										//Format(edtkey,sizeof(edtkey),"%s",tmpexpl[0]);
										Format(edtval,sizeof(edtval),"%s",edtdata);
										ReplaceStringEx(edtval,sizeof(edtval),edtkey,"");
										TrimString(edtval);
										if (StrContains(edtkey,"\"",false) != -1) ReplaceString(edtkey,sizeof(edtkey),"\"","");
										Format(edtkey,sizeof(edtkey),"\"%s\"",edtkey);
										if (StrContains(edtval,"\"",false) != -1) ReplaceString(edtval,sizeof(edtval),"\"","");
										int findedit = StrContains(tmpline,edtkey,false);
										if (StrEqual(edtkey,"\"edt_map\"",false))
										{
											findedit = StrContains(tmpline,"\"map\" \"",false);
											if (findedit != -1)
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",tmpline[findedit]);
												ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"map\" ","");
												findend = StrContains(tmpbuf,"\n",false);
												if (findend != -1)
												{
													Format(tmpbuf,findend,"%s",tmpbuf);
													ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
													TrimString(tmpbuf);
													if (StrEqual(tmpbuf,edtval,false))
													{
														Format(edt_map,sizeof(edt_map),"%s",edtval);
														edtkey = "";
													}
													else break;
												}
											}
										}
										if (StrEqual(edtkey,"\"edt_landmark\"",false))
										{
											findedit = StrContains(tmpline,"\"landmark\" \"",false);
											if (findedit != -1)
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",tmpline[findedit]);
												ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"landmark\" ","");
												findend = StrContains(tmpbuf,"\n",false);
												if (findend != -1)
												{
													Format(tmpbuf,findend,"%s",tmpbuf);
													ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
													TrimString(tmpbuf);
													if (StrEqual(tmpbuf,edtval,false))
													{
														Format(edt_landmark,sizeof(edt_landmark),"%s",edtval);
														edtkey = "";
													}
													else break;
												}
											}
										}
										if (StrEqual(edtkey,"\"portalnumber\"",false))
										{
											findedit = StrContains(tmpline,"\"portalnumber\" \"",false);
											if (findedit != -1)
											{
												Format(tmpbuf,sizeof(tmpbuf),"%s",tmpline[findedit]);
												ReplaceStringEx(tmpbuf,sizeof(tmpbuf),"\"portalnumber\" ","");
												findend = StrContains(tmpbuf,"\n",false);
												if (findend != -1)
												{
													Format(tmpbuf,findend,"%s",tmpbuf);
													ReplaceString(tmpbuf,sizeof(tmpbuf),"\"","");
													TrimString(tmpbuf);
													if (StrEqual(tmpbuf,edtval,false))
													{
														Format(portalnumber,sizeof(portalnumber),"%s",edtval);
														edtkey = "";
													}
													else break;
												}
											}
											else edtkey = "";
										}
										if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_removespawnflags\"",false)))
										{
											findedit = StrContains(tmpline,"\"spawnflags\"",false);
										}
										//if ((findedit != -1) && (strlen(edt_landmark) > 0) && (strlen(edt_map) > 0))
										if ((findedit != -1) && (StrContains(edtkey,"\"On",false) != 0) && (StrContains(edtkey,"\"PlayerO",false) != 0) && (StrContains(edtkey,"\"Pressed",false) != 0) && (StrContains(edtkey,"\"Unpressed",false) != 0) && (strlen(edtkey) > 1))
										{
											Format(buffadded,sizeof(buffadded),"%s",tmpline[findedit]);
											ExplodeString(buffadded,"\"",tmpexpl,4,64);
											if (strlen(tmpexpl[1]) < 3) Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[0],tmpexpl[2]);
											else Format(replacedata,sizeof(replacedata),"\"%s\" \"%s\"",tmpexpl[1],tmpexpl[3]);
											TrimString(replacedata);
											Format(buffadded,sizeof(buffadded),"%s",tmpline);
											if ((StrEqual(edtkey,"\"edt_addspawnflags\"",false)) || (StrEqual(edtkey,"\"edt_addedspawnflags\"",false)))
											{
												int curval = 0;
												if (strlen(tmpexpl[2]) > 0) curval = StringToInt(tmpexpl[2]);
												else curval = StringToInt(tmpexpl[3]);
												Format(edtval,sizeof(edtval),"%i",curval+StringToInt(edtval));
												Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
											}
											else if (StrEqual(edtkey,"\"edt_removespawnflags\"",false))
											{
												int checkneg = 0;
												if (strlen(tmpexpl[2]) > 0) checkneg = StringToInt(tmpexpl[2]);
												else checkneg = StringToInt(tmpexpl[3]);
												checkneg = checkneg-StringToInt(edtval);
												if (checkneg < 0) checkneg = 0;
												Format(edtval,sizeof(edtval),"%i",checkneg);
												Format(edtkey,sizeof(edtkey),"\"spawnflags\"");
											}
											Format(edtkey,sizeof(edtkey),"%s \"%s\"",edtkey,edtval);
											if (StrEqual(edtkey,replacedata,false)) continue;
											if (dbglvl >= 3) PrintToServer("Replace %s with %s",replacedata,edtkey);
											ReplaceString(buffadded,sizeof(buffadded),replacedata,edtkey);
											if (StrContains(szMapEntities,tmpline,false) != -1)
											{
												ReplaceString(szMapEntities,sizeof(szMapEntities),tmpline,buffadded);
												//Additional replaces
												Format(tmpline,sizeof(tmpline),"%s",buffadded);
											}
										}
										else if ((strlen(tmpline) > 0) && (strlen(edtkey) > 1))
										{
											//{
											//Format(tmpline,sizeof(tmpline),"%s%s",rmchar,tmpline);
											Format(buffadded,sizeof(buffadded),"%s",tmpline);
											ReplaceString(buffadded,sizeof(buffadded),"}","");
											if (StrContains(buffadded,"\n\n",false) != -1) ReplaceString(buffadded,sizeof(buffadded),"\n\n","\n");
											if (dbglvl >= 3) PrintToServer("Add KV to %s %s\n%s %s",clsorg,targn,edtkey,edtval);
											Format(buffadded,sizeof(buffadded),"%s%s \"%s\"\n}\n",buffadded,edtkey,edtval);
											ReplaceString(szMapEntities,sizeof(szMapEntities),tmpline,buffadded);
											Format(tmpline,sizeof(tmpline),"%s",buffadded);
										}
									}
								}
							}
						}
					}
				}
				else break;
			}
		}
		ClearArrayHandles(g_EditClassesData);
		ClearArrayHandles(g_EditTargetsData);
		ClearArrayHandles(g_EditClassOrgData);
		CloseHandle(g_DeleteClasses);
		CloseHandle(g_DeleteClassOrigin);
		CloseHandle(g_DeleteTargets);
		CloseHandle(g_EditClasses);
		CloseHandle(g_EditClassOrigin);
		CloseHandle(g_EditTargets);
		CloseHandle(g_EditClassesData);
		CloseHandle(g_EditTargetsData);
		CloseHandle(g_EditClassOrgData);
		CloseHandle(g_CreateEnts);
		char szMapNameadj[64];
		if (strlen(contentdata) < 1) Format(szMapNameadj,sizeof(szMapNameadj),"maps/ent_cache/%s.ent",szMapName);
		else Format(szMapNameadj,sizeof(szMapNameadj),"maps/ent_cache/%s_%s.ent",contentdata,szMapName);
		if (GenerateEnt2)
		{
			if (FileExists(szMapNameadj,true,NULL_STRING))
			{
				DeleteFile(szMapNameadj,true,NULL_STRING);
				ReplaceStringEx(szMapNameadj,sizeof(szMapNameadj),".ent",".ent2");
			}
		}
		Handle writefile = OpenFile(szMapNameadj,"wb",true,NULL_STRING);
		if (writefile != INVALID_HANDLE)
		{
			WriteFileString(writefile,szMapEntities,false);
		}
		CloseHandle(writefile);
		if (strlen(lastmap) > 1)
		{
			char lastmapchk[72];
			Format(lastmapchk,sizeof(lastmapchk),"\"map\" \"%s\"",lastmap);
			if (StrContains(szMapEntities,lastmapchk,false) == -1)
			{
				char tmplastmap[512];
				Format(tmplastmap,sizeof(tmplastmap),"\n{\n\"classname\" \"trigger_changelevel\"\n\"map\" \"%s\"\n\"spawnflags\" \"6\"\n}",lastmap);
				StrCat(szMapEntities,sizeof(szMapEntities),tmplastmap);
			}
		}
		if (dbglvl > 0) PrintToServer("Finished EntCache Rebuild");
		Format(lastmap,sizeof(lastmap),"%s",szMapName);
		return Plugin_Changed;
	}
	else if (dbglvl > 0)
	{
		PrintToServer("No EDT found at %s or %s",curmap,curmap2);
		char szMapNameadj[64];
		if (strlen(contentdata) < 1) Format(szMapNameadj,sizeof(szMapNameadj),"maps/ent_cache/%s.ent",szMapName);
		else Format(szMapNameadj,sizeof(szMapNameadj),"maps/ent_cache/%s_%s.ent",contentdata,szMapName);
		Handle writefile = OpenFile(szMapNameadj,"wb",true,NULL_STRING);
		if (writefile != INVALID_HANDLE)
		{
			WriteFileString(writefile,szMapEntities,false);
		}
		CloseHandle(writefile);
	}
	CloseHandle(g_DeleteClasses);
	CloseHandle(g_DeleteClassOrigin);
	CloseHandle(g_DeleteTargets);
	CloseHandle(g_EditClasses);
	CloseHandle(g_EditClassOrigin);
	CloseHandle(g_EditTargets);
	CloseHandle(g_EditClassesData);
	CloseHandle(g_EditTargetsData);
	CloseHandle(g_EditClassOrgData);
	CloseHandle(g_CreateEnts);
	Format(lastmap,sizeof(lastmap),"%s",szMapName);
	return Plugin_Continue;
}

void ClearArrayHandles(Handle array)
{
	if (array != INVALID_HANDLE)
	{
		if (view_as<int>(array) != 1634494062)
		{
			if (GetArraySize(array) > 0)
			{
				for (int i = 0;i<GetArraySize(array);i++)
				{
					Handle closearr = GetArrayCell(array,i);
					if (closearr != INVALID_HANDLE) CloseHandle(closearr);
				}
			}
		}
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public void OnMapStart()
{
	if (GetArraySize(cvarmods) > 0)
	{
		for (int i = 0;i<GetArraySize(cvarmods);i++)
		{
			char tmparr[64];
			GetArrayString(cvarmods,i,tmparr,sizeof(tmparr));
			char kvs[4][64];
			ExplodeString(tmparr," ",kvs,4,64);
			Handle cvarchk = FindConVar(kvs[0]);
			if (cvarchk != INVALID_HANDLE)
			{
				if (strlen(kvs[1]) > 0)
				{
					ReplaceString(kvs[1],sizeof(kvs[]),"\"","");
					SetConVarString(cvarchk,kvs[1],true,true);
				}
			}
			CloseHandle(cvarchk);
			ServerCommand("%s",tmparr);
		}
		CloseHandle(cvarmods);
		cvarmods = CreateArray(64);
	}
}

void ReadEDT(char[] edtfile)
{
	if (FileExists(edtfile,true,NULL_STRING))
	{
		bool CreatingEnt = false;
		bool EditingEnt = false;
		bool DeletingEnt = false;
		bool ModifyCase = false;
		bool CVars = false;
		bool origindefined = false;
		bool TargnDefined = false;
		bool EditByTargn = false;
		bool ReadString = false;
		bool reading = true;
		char line[512];
		char cls[128];
		char targn[64];
		char originch[128];
		int linenum = 0;
		Handle passedarr = CreateArray(64);
		int iCurHndl = view_as<int>(passedarr);
		Handle filehandle = INVALID_HANDLE;
		if (FileExists(edtfile,false)) filehandle = OpenFile(edtfile,"rt",false);
		else filehandle = OpenFile(edtfile,"rt",true,NULL_STRING);
		int iFHandle = view_as<int>(filehandle);
		int iFilePos = -1;
		//bool bCorruptHandle = false;
		while(reading && (!IsEndOfFile(filehandle)))
		{
			if (!ReadString) reading = ReadFileLine(filehandle,line,sizeof(line));
			else
			{
				int readstatus = ReadFileString(filehandle,line,sizeof(line));
				if (readstatus == -1)
				{
					reading = false;
					break;
				}
				else reading = true;
			}
			TrimString(line);
			linenum+=1;
			if (((strlen(line) > 0) || (ReadString) || (IncludeNextLines)) && (StrContains(line,"//",false) != 0))
			{
				if ((strlen(line) < 4) && (!IncludeNextLines) && (StrContains(line,"//",false) != 0) && (!StrEqual(line,"{",false)) && (!StrEqual(line,"}",false)) && (!StrEqual(line,"} }",false)) && (!StrEqual(line,"}}",false)))
				{
					char additional[32];
					ReadFileString(filehandle,additional,sizeof(additional));
					Format(line,sizeof(line),"%s%s",line,additional);
					while (ReadFileString(filehandle,additional,sizeof(additional)) > 0)
					{
						if (StrEqual(additional,"\n",false))
						{
							ReplaceString(line,sizeof(line),"\n","");
							ReadString = true;
							break;
						}
						Format(line,sizeof(line),"%s%s",line,additional);
					}
					TrimString(line);
				}
				if (StrContains(line,"//",false) != 0)
				{
					int commentpos = StrContains(line,"//",false);
					if (commentpos != -1)
					{
						Format(line,commentpos+1,"%s",line);
					}
				}
				if ((StrEqual(line,"console",false)) || ((StrContains(line,"console",false) <= 1) && (StrContains(line,"console",false) != -1)))
				{
					CVars = true;
				}
				if (CVars)
				{
					if ((StrContains(line,"entity",false) != -1) || (StrEqual(line,"}",false)))
					{
						CVars = false;
					}
					else
					{
						Handle consolearr = CreateArray(16);
						FormatKVs(consolearr,line,"");
						/*
						Handle tmphndl = FormatKVs(consolearr,line,"");
						consolearr = CloneArray(tmphndl);
						CloseHandle(tmphndl);
						*/
						if (GetArraySize(consolearr) > 0)
						{
							for (int i = 0;i<GetArraySize(consolearr);i++)
							{
								char tmparr[128];
								GetArrayString(consolearr,i,tmparr,sizeof(tmparr));
								if (dbglvl) PrintToServer("CVar %s",tmparr);
								char kvs[4][64];
								ExplodeString(tmparr," ",kvs,4,64);
								Handle cvarchk = FindConVar(kvs[0]);
								if (cvarchk != INVALID_HANDLE)
								{
									char originalval[128];
									GetConVarString(cvarchk,originalval,sizeof(originalval));
									Format(originalval,sizeof(originalval),"%s %s",kvs[0],originalval);
									if (FindStringInArray(cvaroriginals,originalval) == -1) PushArrayString(cvaroriginals,originalval);
									if (strlen(kvs[1]) > 0) SetConVarString(cvarchk,kvs[1],true,true);
								}
								CloseHandle(cvarchk);
								ServerCommand("%s",tmparr);
								if (FindStringInArray(cvarmods,tmparr) == -1) PushArrayString(cvarmods,tmparr);
							}
						}
						CloseHandle(consolearr);
					}
				}
				if ((StrContains(line,"create",false) == 0) || (StrContains(line,"create",false) == 1))
					CreatingEnt = true;
				else if ((StrContains(line,"edit",false) == 0) || (StrContains(line,"edit",false) == 1))
					EditingEnt = true;
				else if ((StrContains(line,"delete",false) == 0) || (StrContains(line,"delete",false) == 1))
					DeletingEnt = true;
				else if ((StrContains(line,"modifycase",false) == 0) || (StrContains(line,"modifycase",false) == 1))
					ModifyCase = true;
				if ((StrContains(line,"classname",false) != -1) && (strlen(cls) < 1))
				{
					char removeprev[64];
					int findclass = StrContains(line,"classname",false);
					if (findclass != -1)
					{
						Format(removeprev,findclass+1,"%s",line);
					}
					Format(cls,sizeof(cls),"%s",line);
					if (strlen(removeprev) > 0)
						ReplaceString(cls,sizeof(cls),removeprev,"");
					if (StrContains(cls,"\"",false) != -1)
					{
						ReplaceString(cls,sizeof(cls),"\"","");
					}
					ReplaceString(cls,sizeof(cls),"}","");
					ReplaceStringEx(cls,sizeof(cls),"classname","");
					TrimString(cls);
					char kvs[64][64];
					ExplodeString(cls," ",kvs,64,64);
					Format(cls,sizeof(cls),"%s",kvs[0]);
					TrimString(cls);
					if (TargnDefined) EditByTargn = true;
				}
				if ((StrContains(line,"origin",false) != -1) && (!origindefined) && (!((EditByTargn) && (StrContains(line,"values",false) == -1))))
				{
					char removeprev[128];
					int findclass = StrContains(line,"origin",false);
					int containval = StrContains(line,"values",false);
					if (findclass != -1)
					{
						bool nosetorg = false;
						if (containval != -1)
						{
							if (findclass > containval) nosetorg = true;
						}
						if (!nosetorg) Format(removeprev,findclass+1,"%s",line);
					}
					Format(originch,sizeof(originch),"%s",line);
					if (strlen(removeprev) > 0) ReplaceString(originch,sizeof(originch),removeprev,"");
					if (findclass != -1)
					{
						ReplaceString(originch,sizeof(originch),"\"","");
						ReplaceString(originch,sizeof(originch),"origin","");
						ReplaceString(originch,sizeof(originch),"{","");
						ReplaceString(originch,sizeof(originch),"}","");
						TrimString(originch);
						char kvs[64][64];
						ExplodeString(originch," ",kvs,64,64);
						if (!StrEqual(kvs[0],"edit",false))
						{
							Format(originch,sizeof(originch),"%s %s %s",kvs[0],kvs[1],kvs[2]);
							origindefined = true;
						}
					}
				}
				if ((StrContains(line,"targetname",false) != -1) && ((EditingEnt) || (DeletingEnt)) && (!TargnDefined))
				{
					bool gettn = true;
					if (StrContains(line,"values",false) != -1)
					{
						if ((StrContains(line,"targetname",false)) >= (StrContains(line,"values",false))) gettn = false;
					}
					if (gettn)
					{
						Handle tmp = CreateArray(16);
						FormatKVs(tmp,line,"targetname");
						/*
						Handle tmphndl = FormatKVs(tmp,line,"targetname");
						tmp = CloneArray(tmphndl);
						CloseHandle(tmphndl);
						*/
						if (GetArraySize(tmp) > 0)
						{
							for (int ikvs = 0;ikvs<GetArraySize(tmp);ikvs++)
							{
								char tmparr[256];
								GetArrayString(tmp,ikvs,tmparr,sizeof(tmparr));
								char kvs[64][64];
								ExplodeString(tmparr," ",kvs,64,64);
								Format(targn,sizeof(targn),"%s",kvs[0]);
								if (StrEqual(kvs[2],"\"\"",false)) Format(targn,sizeof(targn),"%s %s",kvs[0],kvs[1]);
								ReplaceString(targn,sizeof(targn),"\"","");
								ReplaceString(targn,sizeof(targn),"}","");
								if ((strlen(targn) > 0) && (!StrEqual(targn,"classname",false)))
								{
									TargnDefined = true;
									break;
								}
							}
						}
						CloseHandle(tmp);
					}
				}
				if ((IncludeNextLines) && (strlen(line) < 2))
				{
					Format(LineSpanning,sizeof(LineSpanning),"%s\n\n",LineSpanning);
				}
				if (((CreatingEnt) || (EditingEnt) || (DeletingEnt) || (ModifyCase)) && (strlen(line) > 0))
				{
					if (iCurHndl != view_as<int>(passedarr))
					{
						PrintToServer("EDTError on line %i %s",linenum,line);
						CloseHandle(passedarr);
						passedarr = CreateArray(64);
						iCurHndl = view_as<int>(passedarr);
					}
					else FormatKVs(passedarr,line,cls);
					if (iFHandle != view_as<int>(filehandle))
					{
						/*
						bCorruptHandle = true;
						break;
						*/
						if (LogEDTErr) LogMessage("EDTError on line %i %s",linenum,line);
						else PrintToServer("EDTError on line %i %s",linenum,line);
						if (FileExists(edtfile,false)) filehandle = OpenFile(edtfile,"rt",false);
						else filehandle = OpenFile(edtfile,"rt",true,NULL_STRING);
						FileSeek(filehandle,iFilePos,SEEK_SET);
						iFHandle = view_as<int>(filehandle);
					}
					else iFilePos = FilePosition(filehandle);
				}
				if ((StrContains(line,"}",false) != -1) && (CreatingEnt))
				{
					if (strlen(cls) > 0)
					{
						bool DelEnt = false;
						if ((AntirushDisable) || (VintageMode))
						{
							if (GetArraySize(passedarr) > 0)
							{
								for (int i = 0;i<GetArraySize(passedarr);i++)
								{
									char tmparr[128];
									GetArrayString(passedarr,i,tmparr,sizeof(tmparr));
									if (StrContains(tmparr,"targetname",false) != -1)
									{
										if (AntirushDisable)
										{
											if (StrContains(tmparr,"syn_antirush",false) != -1)
											{
												DelEnt = true;
												break;
											}
										}
										if (VintageMode)
										{
											if (StrContains(tmparr,"syn_vint",false) != -1)
											{
												DelEnt = true;
												break;
											}
										}
									}
								}
							}
						}
						if (!DelEnt)
						{
							char edtcls[64];
							Format(edtcls,sizeof(edtcls),"%s",cls);
							if (dbglvl > 0) PrintToServer("Create %s at origin %s With %i KVs",cls,originch,GetArraySize(passedarr));
							else if (dbglvl) PrintToServer("Create %s at origin %s",cls,originch);
							Format(edtcls,sizeof(edtcls),"classname \"%s\"",edtcls);
							if (FindStringInArray(passedarr,edtcls) == -1) PushArrayString(passedarr,edtcls);
							Handle dupearr = CloneArray(passedarr);
							PushArrayCell(g_CreateEnts,dupearr);
						}
					}
					else
					{
						if (LogEDTErr) LogMessage("EDT Error: Attempted to create entity with no classname on line %i",linenum);
						else PrintToServer("EDT Error: Attempted to create entity with no classname on line %i",linenum);
					}
					ClearArray(passedarr);
					cls = "";
					targn = "";
					originch = "";
					origindefined = false;
					CreatingEnt = false;
					EditingEnt = false;
					DeletingEnt = false;
					ModifyCase = false;
					TargnDefined = false;
					EditByTargn = false;
				}
				if ((StrContains(line,"}",false) != -1) && ((EditingEnt) || (DeletingEnt) || (ModifyCase)))
				{
					if (ModifyCase)
					{
						if (GetArraySize(passedarr) > 1)
						{
							Handle dupearr = CloneArray(passedarr);
							PushArrayCell(g_ModifyCase,dupearr);
						}
					}
					else if ((origindefined) && (strlen(cls) > 0) && (!EditByTargn))
					{
						if (DeletingEnt)
						{
							if (dbglvl) PrintToServer("Delete %s at origin %s",cls,originch);
							char deletion[64];
							Format(deletion,sizeof(deletion),"%s,%s",cls,originch);
							if (FindStringInArray(g_DeleteClassOrigin,deletion) == -1) PushArrayString(g_DeleteClassOrigin,deletion);
						}
						else
						{
							if (dbglvl > 0) PrintToServer("Edit %s at origin %s with %i KVs",cls,originch,GetArraySize(passedarr));
							else if (dbglvl) PrintToServer("Edit %s at origin %s",cls,originch);
							char resetent[128];
							Format(resetent,sizeof(resetent),"%s,%s",cls,originch);
							Handle dupearr = CloneArray(passedarr);
							PushArrayString(g_EditClassOrigin,resetent);
							PushArrayCell(g_EditClassOrgData,dupearr);
						}
					}
					else if ((!TargnDefined) && (strlen(cls) > 0))
					{
						if (DeletingEnt)
						{
							if (dbglvl) PrintToServer("Delete all %s",cls);
							if (FindStringInArray(g_DeleteClasses,cls) == -1) PushArrayString(g_DeleteClasses,cls);
						}
						else
						{
							if (dbglvl) PrintToServer("Edit all %s",cls);
							PushArrayString(g_EditClasses,cls);
							Handle dupearr = CloneArray(passedarr);
							PushArrayCell(g_EditClassesData,dupearr);
						}
					}
					else if (strlen(targn) > 0)
					{
						if (origindefined)
						{
							if (DeletingEnt)
							{
								if (dbglvl) PrintToServer("Delete %s at origin %s",targn,originch);
								char deletion[64];
								Format(deletion,sizeof(deletion),"%s,%s",targn,originch);
								if (FindStringInArray(g_DeleteClassOrigin,deletion) == -1) PushArrayString(g_DeleteClassOrigin,deletion);
							}
							else
							{
								if (dbglvl > 0) PrintToServer("Edit %s at origin %s with %i KVs",targn,originch,GetArraySize(passedarr));
								else if (dbglvl) PrintToServer("Edit %s at origin %s",targn,originch);
								char resetent[128];
								Format(resetent,sizeof(resetent),"%s,%s",targn,originch);
								Handle dupearr = CloneArray(passedarr);
								PushArrayString(g_EditClassOrigin,resetent);
								PushArrayCell(g_EditClassOrgData,dupearr);
							}
						}
						else
						{
							if (DeletingEnt)
							{
								if (dbglvl) PrintToServer("Delete all by targetname %s",targn);
								if (FindStringInArray(g_DeleteTargets,targn) == -1) PushArrayString(g_DeleteTargets,targn);
							}
							else
							{
								if (dbglvl) PrintToServer("Edit all by targetname %s",targn);
								if (FindStringInArray(g_EditTargets,targn) == -1)
								{
									PushArrayString(g_EditTargets,targn);
									Handle dupearr = CloneArray(passedarr);
									PushArrayCell(g_EditTargetsData,dupearr);
									/*
									if (GetArraySize(passedarr) > 0)
									{
										for (int i = 0;i<GetArraySize(passedarr);i++)
										{
											char tmpar[64];
											GetArrayString(passedarr,i,tmpar,sizeof(tmpar));
											PrintToServer("AllByTargn %s",tmpar);
										}
									}
									*/
								}
							}
						}
					}
					ClearArray(passedarr);
					cls = "";
					targn = "";
					originch = "";
					origindefined = false;
					CreatingEnt = false;
					EditingEnt = false;
					DeletingEnt = false;
					ModifyCase = false;
					TargnDefined = false;
					EditByTargn = false;
				}
			}
			if ((view_as<int>(filehandle) == 2002874483) || (linenum > 20000))
			{
				PrintToServer("EDTRead Ended at line %i",linenum);
				CloseHandle(passedarr);
				return;
			}
		}
		if (dbglvl > 1) PrintToServer("EDTRead Ended at line %i",linenum+1);
		CloseHandle(passedarr);
		//if (!bCorruptHandle) CloseHandle(filehandle);
		CloseHandle(filehandle);
		//Re-apply after for late setup
		if (GetArraySize(cvarmods) > 0)
		{
			for (int i = 0;i<GetArraySize(cvarmods);i++)
			{
				char tmparr[64];
				GetArrayString(cvarmods,i,tmparr,sizeof(tmparr));
				char kvs[4][64];
				ExplodeString(tmparr," ",kvs,4,64);
				Handle cvarchk = FindConVar(kvs[0]);
				if (cvarchk != INVALID_HANDLE)
				{
					if (strlen(kvs[1]) > 0)
					{
						ReplaceString(kvs[1],sizeof(kvs[]),"\"","");
						SetConVarString(cvarchk,kvs[1],true,true);
					}
				}
				CloseHandle(cvarchk);
				ServerCommand("%s",tmparr);
			}
			CloseHandle(cvarmods);
			cvarmods = CreateArray(64);
		}
	}
	return;
}
//public Handle FormatKVs(Handle arrpass, char[] passchar, char[] cls)
void FormatKVs(Handle passedarr, char[] passchar, char[] cls)
{
	if ((strlen(passchar) > 0) && (StrContains(passchar,"//",false) != 0) && (passedarr != INVALID_HANDLE))
	{
		/*
		Handle passedarr = INVALID_HANDLE;
		if (view_as<int>(arrpass) == 1634494062) passedarr = CreateArray(64);
		else passedarr = CloneArray(arrpass);
		*/
		char kvs[128][256];
		char fmt[256];
		ReplaceStringEx(passchar,256,"	"," ");
		ReplaceString(passchar,256,"	","");
		int runthrough = ExplodeString(passchar," ",kvs,128,256);
		int valdef = -1;
		for (int i = 0;i<runthrough;i++)
		{
			if (StrContains(kvs[i+1],"}",false) == 0)
			{
				break;
			}
			else
			{
				if (StrEqual(kvs[i],"{",false)) i++;
				if ((strlen(kvs[i]) > 0) && ((strlen(kvs[i+1]) > 0) || (IncludeNextLines)))
				{
					if ((StrContains(passchar,"values",false) > StrContains(passchar,"classname",false)) && (StrContains(passchar,"classname",false) != -1) && (StrContains(passchar,"edit",false) != -1) && (valdef < 1))
					{
						valdef = StrContains(passchar,"classname",false)+11;
					}
					if ((StrContains(kvs[i],cls,false) != -1) && (StrContains(kvs[i],"for_targetname",false) == -1) && (strlen(cls) > 0))
					{
						i++;
						if ((StrContains(kvs[i],"origin",false) != -1) && (StrContains(kvs[i],"for_origin",false) == -1))
						{
							i+=4;
							//valdef = StrContains(kvs[i],"origin",false)+2;
						}
						if (i+1 >= runthrough) break;
					}
					if (StrContains(kvs[i],"values",false) == 0)
					{
						char chklong[64];
						Format(chklong,sizeof(chklong),"%s",kvs[i]);
						ReplaceStringEx(chklong,sizeof(chklong),"values","",-1,-1,false);
						if (strlen(chklong) > 1)
						{
							if (StrContains(kvs[i],"{",false) == 0) ReplaceString(kvs[i],sizeof(kvs[]),"{","");
							Format(kvs[i],sizeof(kvs[]),"%s",chklong);
						}
					}
					if ((StrContains(kvs[i],"values",false) == -1) && (StrContains(kvs[i],"create",false) == -1) && (StrContains(kvs[i],"edit",false) == -1) && (StrContains(kvs[i],"delete",false) == -1) && (StrContains(kvs[i],"modifycase",false) == -1) || ((StrContains(kvs[i],"origin",false) > StrContains(passchar,"values",false)) || (StrContains(kvs[i],"for_origin",false) != -1)))
					{
						char key[128];
						char val[256];
						int set = 0;
						ReplaceString(kvs[i],sizeof(kvs[]),"{","");
						ReplaceString(kvs[i+1],sizeof(kvs[]),"}","");
						if ((StrEqual(cls,"targetname",false)) && (StrContains(kvs[i],"\"",false) == 0) && (StrContains(kvs[i+1],"\"",false) > -1)) Format(key,sizeof(key),"%s %s",kvs[i],kvs[i+1]);
						if ((StrContains(kvs[i],"\"",false) == -1) && (!IncludeNextLines)) Format(key,sizeof(key),"%s",kvs[i]);
						else if (StrContains(kvs[i],"\"",false) == 0)
						{
							char tmp[128];
							Format(tmp,sizeof(tmp),"%s",kvs[i]);
							ReplaceStringEx(tmp,sizeof(tmp),"\"","");
							if (StrContains(tmp,"\"",false) > 0)
							{
								Format(key,sizeof(key),"%s",kvs[i]);
							}
						}
						else if (IncludeNextLines)
						{
							if (!StrEqual(LineSpanning[strlen(LineSpanning)-1],"\n",false)) Format(LineSpanning,sizeof(LineSpanning),"%s %s",LineSpanning,kvs[i]);
							else Format(LineSpanning,sizeof(LineSpanning),"%s%s",LineSpanning,kvs[i]);
							if (StrContains(kvs[i],"\"",false) > 0)
							{
								Format(key,sizeof(key),"%s\n",LineSpanning,kvs[i]);
								IncludeNextLines = false;
							}
						}
						if ((StrContains(kvs[i+1],"\"",false) == -1) && (!IncludeNextLines)) Format(val,sizeof(val),"%s",kvs[i+1]);
						else if (StrContains(kvs[i+1],"\"",false) == 0)
						{
							char tmp[128];
							Format(tmp,sizeof(tmp),"%s",kvs[i+1]);
							ReplaceStringEx(tmp,sizeof(tmp),"\"","");
							if (StrContains(tmp,"\"",false) > 0)
							{
								Format(val,sizeof(val),"%s",kvs[i+1]);
								if (IncludeNextLines)
								{
									Format(LineSpanning,sizeof(LineSpanning),"%s%s",LineSpanning,val);
									Format(key,sizeof(key),"%s",LineSpanning);
									int split = StrContains(key," ",false);
									if (split != -1)
									{
										Format(key,split+1,"%s",key);
										Format(val,sizeof(val),"%s",LineSpanning);
										ReplaceStringEx(val,sizeof(val),key,"");
									}
								}
								IncludeNextLines = false;
							}
							else if (StrContains(tmp,"\"",false) == 0)
							{
								Format(val,sizeof(val),"\"\"");
							}
							else
							{
								for (int j = i+2;j<runthrough;j++)
								{
									if (strlen(kvs[j]) > 0) Format(kvs[i+1],sizeof(kvs[]),"%s %s",kvs[i+1],kvs[j]);
									if (StrContains(kvs[j],"\"",false) > 0)
									{
										set = j;
										Format(val,sizeof(val),"%s",kvs[i+1]);
										if (IncludeNextLines)
										{
											Format(LineSpanning,sizeof(LineSpanning),"%s%s",LineSpanning,val);
											Format(key,sizeof(key),"%s",LineSpanning);
											int split = StrContains(key," ",false);
											if (split != -1)
											{
												Format(key,split+1,"%s",key);
												Format(val,sizeof(val),"%s",LineSpanning);
												ReplaceStringEx(val,sizeof(val),key,"");
											}
										}
										IncludeNextLines = false;
										break;
									}
								}
								if (set == 0)
								{
									set = i+2;
									//no ending quote found might be on next lines
									Format(val,sizeof(val),"%s",kvs[i+1]);
									//TrimString(val);
									if (!IncludeNextLines) Format(LineSpanning,sizeof(LineSpanning),"%s %s\n",key,val);
									else Format(LineSpanning,sizeof(LineSpanning),"%s\n%s",LineSpanning,val);
									key = "";
									IncludeNextLines = true;
								}
							}
						}
						else if (IncludeNextLines)
						{
							Format(LineSpanning,sizeof(LineSpanning),"%s %s",LineSpanning,kvs[i+1]);
							if (StrContains(kvs[i+2],"\"",false) != -1)
							{
								Format(LineSpanning,sizeof(LineSpanning),"%s %s",LineSpanning,kvs[i+2]);
								Format(key,sizeof(key),"%s",LineSpanning);
								int split = StrContains(key," ",false);
								if (split != -1)
								{
									Format(key,split+1,"%s",key);
									Format(val,sizeof(val),"%s",LineSpanning);
									ReplaceStringEx(val,sizeof(val),key,"");
								}
								IncludeNextLines = false;
							}
						}
						if ((strlen(key) > 0) && (StrContains(key,"//",false) != 0))
						{
							ReplaceString(key,sizeof(key),"\"","");
							ReplaceString(key,sizeof(key),"{","");
							ReplaceString(key,sizeof(key),"}","");
							if (strlen(val) < 1) Format(val,sizeof(val),"\"\"");
							else
							{
								//ReplaceString(val,sizeof(val),"\"","");
								ReplaceString(val,sizeof(val),"}","");
							}
							if (StrEqual(key,"classname",false))
							{
								if (StrContains(passchar,val,false) <= valdef)
								{
									key = "";
								}
							}
							if (strlen(key) > 0)
							{
								if ((i >= runthrough) || (i < 0)) break;
								Format(fmt,sizeof(fmt),"%s %s",key,val);
								if (view_as<int>(passedarr) != 1634494062)
								{
									PushArrayString(passedarr,fmt);
								}
								/*
								else
								{
									Handle tmphndl = CreateArray(64);
									passedarr = CloneHandle(tmphndl);
									PushArrayString(passedarr,fmt);
								}
								*/
							}
						}
						if (set == 0) i++;
						else i = set;
					}
				}
			}
		}
		if (IncludeNextLines) Format(LineSpanning,sizeof(LineSpanning),"%s\n",LineSpanning);
		//return passedarr;
		return;
	}
	//return INVALID_HANDLE;
	return;
}

public void dbgch(Handle convar, const char[] oldValue, const char[] newValue)
{
	dbglvl = StringToInt(newValue);
}

public void methodch(Handle convar, const char[] oldValue, const char[] newValue)
{
	method = StringToInt(newValue);
}

public void generateent2ch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0) GenerateEnt2 = true;
	else GenerateEnt2 = false;
}

public void rmglobalsch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0) RemoveGlobals = true;
	else RemoveGlobals = false;
}

public void loggetbspch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0) LogEDTErr = true;
	else LogEDTErr = false;
}

public void vintagech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) != StringToInt(oldValue))
	{
		if (StringToInt(newValue) > 0)
		{
			VintageMode = true;
			Handle arr = CreateArray(128);
			findentsarrtarg(arr,"syn_vint*");
			if (arr != INVALID_HANDLE)
			{
				if (view_as<int>(arr) != 1634494062)
				{
					if (GetArraySize(arr) > 0)
					{
						for (int i = 0;i<GetArraySize(arr);i++)
						{
							int entity = GetArrayCell(arr,i);
							if ((IsValidEntity(entity)) && (entity != 0))
							{
								AcceptEntityInput(entity,"kill");
							}
						}
					}
				}
			}
			CloseHandle(arr);
		}
		else
		{
			VintageMode = false;
		}
	}
}

public void antirushch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) != StringToInt(oldValue))
	{
		if (StringToInt(newValue) > 0)
		{
			AntirushDisable = true;
			Handle arr = CreateArray(128);
			findentsarrtarg(arr,"syn_vint*");
			if (arr != INVALID_HANDLE)
			{
				if (view_as<int>(arr) != 1634494062)
				{
					if (GetArraySize(arr) > 0)
					{
						char cls[42];
						for (int i = 0;i<GetArraySize(arr);i++)
						{
							int entity = GetArrayCell(arr,i);
							if ((IsValidEntity(entity)) && (entity != 0))
							{
								AcceptEntityInput(entity,"Disable");
								GetEntityClassname(entity,cls,sizeof(cls));
								if (StrEqual(cls,"syn_antirush_wall",false))
								{
									if (HasEntProp(entity,Prop_Data,"m_CollisionGroup")) SetEntProp(entity,Prop_Data,"m_CollisionGroup",5);
								}
								else if (HasEntProp(entity,Prop_Data,"m_ModelName"))
								{
									GetEntPropString(entity,Prop_Data,"m_ModelName",cls,sizeof(cls));
									if (StrEqual(cls,"models/synergy/tools/syn_transition.mdl",false))
									{
										if (HasEntProp(entity,Prop_Data,"m_CollisionGroup")) SetEntProp(entity,Prop_Data,"m_CollisionGroup",5);
									}
								}
							}
						}
					}
				}
			}
			CloseHandle(arr);
		}
		else
		{
			AntirushDisable = false;
			Handle arr = CreateArray(128);
			findentsarrtarg(arr,"syn_vint*");
			if (arr != INVALID_HANDLE)
			{
				if (view_as<int>(arr) != 1634494062)
				{
					if (GetArraySize(arr) > 0)
					{
						char cls[42];
						for (int i = 0;i<GetArraySize(arr);i++)
						{
							int entity = GetArrayCell(arr,i);
							if ((IsValidEntity(entity)) && (entity != 0))
							{
								AcceptEntityInput(entity,"Enable");
								GetEntityClassname(entity,cls,sizeof(cls));
								if (StrEqual(cls,"syn_antirush_wall",false))
								{
									if (HasEntProp(entity,Prop_Data,"m_CollisionGroup")) SetEntProp(entity,Prop_Data,"m_CollisionGroup",0);
								}
								else if (HasEntProp(entity,Prop_Data,"m_ModelName"))
								{
									GetEntPropString(entity,Prop_Data,"m_ModelName",cls,sizeof(cls));
									if (StrEqual(cls,"models/synergy/tools/syn_transition.mdl",false))
									{
										if (HasEntProp(entity,Prop_Data,"m_CollisionGroup")) SetEntProp(entity,Prop_Data,"m_CollisionGroup",0);
									}
								}
							}
						}
					}
				}
			}
			CloseHandle(arr);
		}
	}
}

public Handle findentsarrtarg(Handle arr, char[] namechk)
{
	if (arr == INVALID_HANDLE) return INVALID_HANDLE;
	for (int i = 1;i<2048;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[64];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if ((StrEqual(clsname,namechk,false)) && (FindValueInArray(arr,i) == -1))
				PushArrayCell(arr, i);
			if ((HasEntProp(i,Prop_Data,"m_iName")) && (FindValueInArray(arr,i) == -1))
			{
				char fname[128];
				GetEntPropString(i,Prop_Data,"m_iName",fname,sizeof(fname));
				if (StrContains(fname,"\"",false) != -1) ReplaceString(fname,sizeof(fname),"\"","");
				if ((StrContains(namechk,"*",false) > 0) && (StrContains(namechk,"*",false) != 0))
				{
					char tmppass[64];
					Format(tmppass,sizeof(tmppass),"%s",namechk);
					ReplaceString(tmppass,sizeof(tmppass),"*","");
					if (StrContains(fname,tmppass,false) != -1)
					{
						if (FindValueInArray(arr,i) == -1) PushArrayCell(arr,i);
					}
				}
				else if ((StrContains(namechk,"*",false) == 0) && (StrContains(namechk,"*",false) > 0))
				{
					char tmppass[64];
					Format(tmppass,sizeof(tmppass),"%s",namechk);
					ReplaceString(tmppass,sizeof(tmppass),"*","");
					if (StrContains(fname,tmppass,false) != -1)
					{
						if (FindValueInArray(arr,i) == -1) PushArrayCell(arr,i);
					}
				}
				else if (StrContains(namechk,"*",false) == 0)
				{
					char tmppass[64];
					char tmpend[64];
					char tmpchar[16];
					Format(tmppass,sizeof(tmppass),"%s",namechk);
					ReplaceString(tmppass,sizeof(tmppass),"*","");
					int endpos = StrContains(fname,tmppass,false);
					if (endpos != -1)
					{
						Format(tmpchar,endpos+1,"%s",fname);
						if (strlen(tmpchar) < 1)
						{
							if (FindValueInArray(arr,i) == -1) PushArrayCell(arr,i);
						}
						else
						{
							Format(tmpend,sizeof(tmpend),"%s",fname);
							ReplaceStringEx(tmpend,sizeof(tmpend),tmpchar,"");
							ReplaceStringEx(tmpend,sizeof(tmpend),tmppass,"");
							if (strlen(tmpend) < 1)
							{
								if (FindValueInArray(arr,i) == -1) PushArrayCell(arr,i);
							}
						}
					}
				}
				if ((StrEqual(fname,namechk,false)) && (FindValueInArray(arr,i) == -1))
					PushArrayCell(arr,i);
			}
		}
	}
	if (GetArraySize(arr) < 1)
	{
		findentsarrtargsub(arr,-1,namechk,"logic_*");
		findentsarrtargsub(arr,-1,namechk,"env_*");
		findentsarrtargsub(arr,-1,namechk,"filter_*");
		findentsarrtargsub(arr,-1,namechk,"point_template");
		findentsarrtargsub(arr,-1,namechk,"info_vehicle_spawn");
		findentsarrtargsub(arr,-1,namechk,"math_counter");
	}
	if (arr != INVALID_HANDLE)
		if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}

public Handle findentsarrtargsub(Handle arr, int ent, char[] namechk, char[] clsname)
{
	if (arr == INVALID_HANDLE) return INVALID_HANDLE;
	int thisent = FindEntityByClassname(ent,clsname);
	if (IsValidEntity(thisent))
	{
		if ((StrEqual(clsname,namechk,false)) && (FindValueInArray(arr,thisent) == -1))
			PushArrayCell(arr, thisent);
		if ((HasEntProp(thisent,Prop_Data,"m_iName")) && (FindValueInArray(arr,thisent) == -1))
		{
			char fname[128];
			GetEntPropString(thisent,Prop_Data,"m_iName",fname,sizeof(fname));
			if (StrContains(fname,"\"",false) != -1) ReplaceString(fname,sizeof(fname),"\"","");
			if (StrEqual(fname,namechk,false))
				PushArrayCell(arr, thisent);
		}
		findentsarrtargsub(arr,thisent++,namechk,clsname);
	}
	if (arr != INVALID_HANDLE)
		if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}