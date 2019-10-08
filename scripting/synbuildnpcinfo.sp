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

#define PLUGIN_VERSION "0.9"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synbuildnpcinfoupdater.txt"

bool hasreadcache = false;
Handle npcpacks = INVALID_HANDLE;
char mapbuf[64];

public Plugin myinfo =
{
	name = "SynBuildNPCInfo",
	author = "Balimbanana",
	description = "Builds custom npc info through keys: npcname npchealth model",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	npcpacks = CreateArray(256);
}

public void OnMapStart()
{
	if (GetMapHistorySize() > 0)
	{
		GetCurrentMap(mapbuf,sizeof(mapbuf));
		Format(mapbuf,sizeof(mapbuf),"_%s.ent",mapbuf);
		Handle mdirlisting = OpenDirectory("maps/ent_cache", false);
		if (mdirlisting != INVALID_HANDLE)
		{
			char buff[64];
			while (ReadDirEntry(mdirlisting, buff, sizeof(buff)))
			{
				if ((!(mdirlisting == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
				{
					if ((!(StrContains(buff, ".ztmp", false) != -1)) && (!(StrContains(buff, ".bz2", false) != -1)))
					{
						if (StrContains(buff,mapbuf,false) != -1)
						{
							char tmp[64];
							Format(tmp,sizeof(tmp),"%s",buff);
							ReplaceStringEx(tmp,sizeof(tmp),mapbuf,"");
							// Fix for maps with similar names such as
							// bms_bm_c0a0a and hl1_c0a0a HL1 c0a0a will come up as BMS first without this check
							if (StrContains(tmp,"_",false) == -1)
							{
								Format(mapbuf,sizeof(mapbuf),"maps/ent_cache/%s",buff);
								break;
							}
						}
					}
				}
			}
		}
		CloseHandle(mdirlisting);
		ClearArray(npcpacks);
		hasreadcache = false;
		CreateTimer(1.0,buildinfodelay,_,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action buildinfodelay(Handle timer)
{
	buildnpcinfo();
	return Plugin_Handled;
}

void buildnpcinfo()
{
	if (hasreadcache) return;
	Handle filehandle = OpenFile(mapbuf,"r",true,NULL_STRING);
	if (filehandle != INVALID_HANDLE)
	{
		hasreadcache = true;
		char line[128];
		char targn[72];
		int npchealth = 0;
		char npcmdl[64];
		char npcname[64];
		while(!IsEndOfFile(filehandle)&&ReadFileLine(filehandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrContains(line,"\"npchealth\"",false) == 0)
			{
				char tmpchar[128];
				Format(tmpchar,sizeof(tmpchar),line);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"npchealth\"","",false);
				ReplaceString(tmpchar,sizeof(tmpchar),"\"","",false);
				TrimString(tmpchar);
				npchealth = StringToInt(tmpchar);
			}
			else if (StrContains(line,"\"model\"",false) == 0)
			{
				Format(npcmdl,sizeof(npcmdl),line);
				ReplaceString(npcmdl,sizeof(npcmdl),"\"model\"","",false);
				ReplaceString(npcmdl,sizeof(npcmdl),"\"","",false);
				TrimString(npcmdl);
			}
			else if (StrContains(line,"\"npcname\"",false) == 0)
			{
				Format(npcname,sizeof(npcname),line);
				ReplaceString(npcname,sizeof(npcname),"\"npcname\"","",false);
				ReplaceString(npcname,sizeof(npcname),"\"","",false);
				TrimString(npcname);
			}
			else if (StrContains(line,"\"targetname\"",false) == 0)
			{
				Format(targn,sizeof(targn),line);
				ReplaceString(targn,sizeof(targn),"\"targetname\"","",false);
				ReplaceString(targn,sizeof(targn),"\"","",false);
				TrimString(targn);
			}
			else if ((StrEqual(line,"{",false)) || (StrEqual(line,"}",false)))
			{
				if ((strlen(targn) > 0) && (strlen(npcname) > 0))
				{
					Handle dp = CreateDataPack();
					if (dp != INVALID_HANDLE)
					{
						WritePackString(dp,targn);
						WritePackString(dp,npcname);
						WritePackString(dp,npcmdl);
						WritePackCell(dp,npchealth);
						PushArrayCell(npcpacks,dp);
						//PrintToServer("Pack Created with %s %s %s %i",targn,npcname,npcmdl,npchealth);
					}
				}
				targn = "";
				npcmdl = "";
				npcname = "";
				npchealth = 0;
			}
		}
	}
	if (GetArraySize(npcpacks) > 0) ResetCurrent(-1);
	return;
}

void ResetCurrent(int ent)
{
	int thisent = FindEntityByClassname(ent,"npc_*");
	if ((thisent != -1) && (IsValidEntity(thisent)))
	{
		if (HasEntProp(thisent,Prop_Data,"m_iName"))
		{
			Handle removal = CreateArray(256);
			char targn[64];
			GetEntPropString(thisent,Prop_Data,"m_iName",targn,sizeof(targn));
			for (int i = 0;i<GetArraySize(npcpacks);i++)
			{
				Handle dp = GetArrayCell(npcpacks,i);
				if (dp != INVALID_HANDLE)
				{
					ResetPack(dp);
					char namechk[64];
					ReadPackString(dp,namechk,sizeof(namechk));
					if (StrEqual(targn,namechk,false))
					{
						char npcname[64];
						char npcmodel[64];
						ReadPackString(dp,npcname,sizeof(npcname));
						ReadPackString(dp,npcmodel,sizeof(npcmodel));
						int npchealth = ReadPackCell(dp);
						if (npchealth > 0)
						{
							SetEntProp(thisent,Prop_Data,"m_iHealth",npchealth);
							SetEntProp(thisent,Prop_Data,"m_iMaxHealth",npchealth);
						}
						SetEntPropString(thisent,Prop_Data,"m_iszResponseContext",npcname);
						if (FileExists(npcmodel,true,NULL_STRING))
						{
							if (!IsModelPrecached(npcmodel)) PrecacheModel(npcmodel,true);
							SetEntityModel(thisent,npcmodel);
						}
						break;
					}
				}
				else
				{
					CloseHandle(dp);
					PushArrayCell(removal,i);
				}
			}
			if (GetArraySize(removal) > 0)
			{
				for (int i = 0;i<GetArraySize(removal);i++)
				{
					RemoveFromArray(npcpacks,GetArrayCell(removal,i));
				}
			}
			CloseHandle(removal);
		}
		ResetCurrent(thisent++);
	}
}

public Action ResetThis(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity != 0))
	{
		if (HasEntProp(entity,Prop_Data,"m_iName"))
		{
			Handle removal = CreateArray(256);
			char targn[64];
			GetEntPropString(entity,Prop_Data,"m_iName",targn,sizeof(targn));
			for (int i = 0;i<GetArraySize(npcpacks);i++)
			{
				Handle dp = GetArrayCell(npcpacks,i);
				if (dp != INVALID_HANDLE)
				{
					ResetPack(dp);
					char namechk[64];
					ReadPackString(dp,namechk,sizeof(namechk));
					if (StrEqual(targn,namechk,false))
					{
						char npcname[64];
						char npcmodel[64];
						ReadPackString(dp,npcname,sizeof(npcname));
						ReadPackString(dp,npcmodel,sizeof(npcmodel));
						int npchealth = ReadPackCell(dp);
						if (npchealth > 0)
						{
							SetEntProp(entity,Prop_Data,"m_iHealth",npchealth);
							SetEntProp(entity,Prop_Data,"m_iMaxHealth",npchealth);
						}
						SetEntPropString(entity,Prop_Data,"m_iszResponseContext",npcname);
						if (FileExists(npcmodel,true,NULL_STRING))
						{
							if (!IsModelPrecached(npcmodel)) PrecacheModel(npcmodel,true);
							SetEntityModel(entity,npcmodel);
						}
						break;
					}
				}
				else
				{
					CloseHandle(dp);
					PushArrayCell(removal,i);
				}
			}
			if (GetArraySize(removal) > 0)
			{
				for (int i = 0;i<GetArraySize(removal);i++)
				{
					RemoveFromArray(npcpacks,GetArrayCell(removal,i));
				}
			}
			CloseHandle(removal);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if ((StrContains(classname,"npc_",false) != -1) && (GetArraySize(npcpacks) > 0))
	{
		CreateTimer(0.1,ResetThis,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
}
