#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1
#pragma newdecls required;

Handle Handle_Database = INVALID_HANDLE;
ConVar hSEresetgame;
ConVar hSEscoreforheal;
ConVar hSEscoreperhit;
ConVar hSEdisable;
ConVar hSEqdbg;
char mapbuf[64];
char contentdata[32];
char clmap[128][32];
char SteamIDbuf[128][32];
bool bStored[128];
int kills[128];
int deaths[128];
int score[128];
int bitChanged[128];
int timesretried = 0;
float Healchk[128];
#define PLUGIN_VERSION "0.91"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/scoresextendedupdater.txt"

enum
{
	SE_KillsChanged = (1<<0),
	SE_DeathsChanged = (1<<1),
	SE_ScoreChanged = (1<<2),
	SE_CDataChanged = (1<<3)
}

public Plugin myinfo =
{
	name = "ScoresExtended",
	author = "Balimbanana",
	description = "Persistent scores, with configurations.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	RegAdminCmd("se_resetscores", ResetScores, ADMFLAG_ROOT, "Reset all clients scores.");
	hSEresetgame = CreateConVar("se_resetongamechange", "1", "0 is never reset, 1 resets all clients scores on game/mod change, 2 resets on map change.", _, true, 0.0, true, 2.0);
	hSEscoreforheal = CreateConVar("se_scoreforheal", "1", "Allows clients to get score when healing other players.", _, true, 0.0, true, 1.0);
	hSEscoreperhit = CreateConVar("se_scoreperhit", "1", "Allows clients to get score per hit depending on how much damage they do.", _, true, 0.0, true, 1.0);
	hSEqdbg = CreateConVar("se_qdbg", "0", "Shows queries.", _, true, 0.0, true, 1.0);
	AutoExecConfig(true,"scoresextended");
	CreateTimer(0.1,AdditionalCV);
	RegConsoleCmd("drophealth", eyeposchk);
	bool conf = SQL_CheckConfig("ScoresExtended");
	if (!conf)
	{
		char error[100];
		Handle_Database = SQLite_UseDatabase("sourcemod-local",error,sizeof(error));
		if (Handle_Database == INVALID_HANDLE)
			LogError("SQLite error: %s",error);
		if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS persistentscores('SteamID' VARCHAR(32) NOT NULL PRIMARY KEY,'h1' INT NOT NULL,'h2' INT NOT NULL,'h3' INT NOT NULL,'lastcdata' VARCHAR(32) NOT NULL);"))
		{
			char Err[100];
			SQL_GetError(Handle_Database,Err,100);
			LogError("SQLite error: %s",Err);
			return;
		}
	}
	else
	{
		SQL_TConnect(threadedcon,"ScoresExtended");
	}
	CreateTimer(0.11, reloadscoreclients);
	CreateTimer(0.1, hooknpcs);
	//Fallback saves, clients already save on map change and disconnect.
	//But if the server crashes, clients could lose all progress on current map.
	CreateTimer(10.0, SaveClients, _, TIMER_REPEAT);
}

public Action AdditionalCV(Handle timer)
{
	hSEdisable = CreateConVar("se_disable", "0", "Disables loading scores, use for specific map configurations.", _, true, 0.0, true, 1.0);
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
	ReloadPlugin(INVALID_HANDLE);
}

public Action reloadscoreclients(Handle timer)
{
	for (int client = 1; client<MaxClients+1 ;client++)
	{
		if (IsValidEntity(client))
		{
			if ((client != -1) && (IsClientInGame(client)))
			{
				GetClientAuthId(client,AuthId_Steam2,SteamIDbuf[client],32-1);
				LoadClient(client);
			}
		}
	}
}

public Action ResetScores(int client, int args)
{
	for (int i = 1; i<MaxClients+1 ;i++)
	{
		if ((IsValidEntity(i)) && (IsClientConnected(i)))
		{
			GetClientAuthId(i,AuthId_Steam2,SteamIDbuf[i],32-1);
			kills[i] = 0;
			deaths[i] = 0;
			score[i] = 0;
			bitChanged[i] = 15;
			SetEntProp(i, Prop_Data, "m_iFrags", kills[i]);
			SetEntProp(i, Prop_Data, "m_iDeaths", deaths[i]);
			SetEntProp(i, Prop_Data, "m_iPoints", score[i]);
		}
	}
}

void LoadClient(int client)
{
	if ((Handle_Database != INVALID_HANDLE) && (!hSEdisable.BoolValue))
	{
		char Query[128];
		Format(Query,sizeof(Query),"SELECT * FROM persistentscores WHERE SteamID = '%s';",SteamIDbuf[client]);
		if (hSEqdbg.BoolValue) PrintToServer("%s",Query);
		SQL_TQuery(Handle_Database,LoadCL,Query,client);
	}
}

public void LoadCL(Handle owner, Handle hndl, const char[] error, any data)
{
	if ((hndl == INVALID_HANDLE) || (owner == INVALID_HANDLE))
	{
		PrintToServer("SEStoreSQLErr: '%s'",error);
		return;
	}
	if (!SQL_FetchRow(hndl))
	{
		char chk1[256];
		Format(chk1,sizeof(chk1),"INSERT INTO persistentscores VALUES( '%s', '0', '0', '0', '%s');",SteamIDbuf[data],contentdata);
		if (hSEqdbg.BoolValue) PrintToServer("%s",chk1);
		SQL_TQuery(Handle_Database,Store,chk1);
	}
	else
	{
		kills[data] = SQL_FetchInt(hndl,1);
		deaths[data] = SQL_FetchInt(hndl,2);
		score[data] = SQL_FetchInt(hndl,3);
		SQL_FetchString(hndl,4,clmap[data],sizeof(clmap[]));
		bStored[data] = true;
	}
	return;
}

public void threadedcon(Handle owner, Handle hndl, const char[] error, any data)
{
	Handle_Database = hndl;
	if (hndl == INVALID_HANDLE)
	{
		if ((StrContains(error,"server host",false) != -1) || (StrContains(error,"couldn't connect",false) != -1) || (StrContains(error,"can't connect",false) != -1))
		{
			if (timesretried > 3)
			{
				LogError("SESQL Failed to connect after 4 retries...\n%s\nUsing local database...",error);
				char Err[100];
				Handle_Database = SQLite_UseDatabase("sourcemod-local",Err,sizeof(Err));
				if (Handle_Database == INVALID_HANDLE)
					LogError("SQLite error: %s",Err);
				if (!SQL_FastQuery(Handle_Database,"CREATE TABLE IF NOT EXISTS persistentscores('SteamID' VARCHAR(32) NOT NULL PRIMARY KEY,'h1' INT NOT NULL,'h2' INT NOT NULL,'h3' INT NOT NULL,'lastcdata' VARCHAR(32) NOT NULL);"))
				{
					SQL_GetError(Handle_Database,Err,100);
					LogError("SQLite error: %s",Err);
				}
			}
			else CreateTimer(1.0,retrycon,_,TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("SESQLConnect error: %s",error);
			return;
		}
	}
	else if (owner == INVALID_HANDLE)
	{
		PrintToServer("Using unknown driver type");
	}
	else
	{
		timesretried = 0;
		SQL_TQuery(Handle_Database,SrvQueries,"CREATE TABLE IF NOT EXISTS persistentscores('SteamID' VARCHAR(32) NOT NULL PRIMARY KEY,'h1' INT NOT NULL,'h2' INT NOT NULL,'h3' INT NOT NULL,'lastcdata' VARCHAR(32) NOT NULL);");
	}
	return;
}

public Action retrycon(Handle timer)
{
	timesretried++;
	SQL_TConnect(threadedcon,"ScoresExtended");
}

public Action waitforvalid(Handle timer, any client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client) && bStored[client])
	{
		if (hSEqdbg.BoolValue) PrintToServer("CLActive %i Kills: %i Deaths: %i Score: %i lastcdata %s cur %s",client,kills[client],deaths[client],score[client],clmap[client],contentdata);
		SetEntProp(client, Prop_Data, "m_iFrags", kills[client]);
		SetEntProp(client, Prop_Data, "m_iDeaths", deaths[client]);
		SetEntProp(client, Prop_Data, "m_iPoints", score[client]);
		//game change or map change
		if ((hSEresetgame.IntValue == 1) && (!StrEqual(contentdata, clmap[client])))
		{
			SetEntProp(client, Prop_Data, "m_iFrags", 0);
			SetEntProp(client, Prop_Data, "m_iDeaths", 0);
			SetEntProp(client, Prop_Data, "m_iPoints", 0);
			kills[client] = 0;
			deaths[client] = 0;
			score[client] = 0;
			bitChanged[client] = 7;
		}
		else if (hSEresetgame.IntValue == 2)
		{
			SetEntProp(client, Prop_Data, "m_iFrags", 0);
			SetEntProp(client, Prop_Data, "m_iDeaths", 0);
			SetEntProp(client, Prop_Data, "m_iPoints", 0);
			kills[client] = 0;
			deaths[client] = 0;
			score[client] = 0;
			bitChanged[client] = 7;
		}
		Format(clmap[client],sizeof(clmap[]),"%s",contentdata);
		bitChanged[client] |= SE_CDataChanged;
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(1.0,waitforvalid,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientAuthorized(int client, const char[] szAuth)
{
	GetClientAuthId(client,AuthId_Steam2,SteamIDbuf[client],sizeof(SteamIDbuf[]));
	if (!hSEdisable.BoolValue)
	{
		LoadClient(client);
		CreateTimer(0.1,waitforvalid,client);
	}
}

public void OnClientDisconnect(int client)
{
	StoreScores(client);
	init(client);
}

void init(int client)
{
	SteamIDbuf[client] = "";
	clmap[client] = "";
	kills[client] = 0;
	deaths[client] = 0;
	score[client] = 0;
	bitChanged[client] = 0;
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	char clsname[64];
	int killed = GetEventInt(event, "entindex_killed");
	int attacker = GetEventInt(event, "entindex_attacker");
	//int inflictor = GetEventInt(event, "entindex_inflictor");
	GetEntityClassname(killed, clsname, sizeof(clsname));
	if ((attacker <= MaxClients) && (attacker != 0))
	{
		//Suicide
		if (StrEqual(clsname,"player"))
		{
			kills[attacker]--;
			score[attacker]--;
			SetEntProp(attacker, Prop_Data, "m_iFrags", kills[attacker]);
			SetEntProp(attacker, Prop_Data, "m_iPoints", score[attacker]);
			bitChanged[attacker] |= SE_DeathsChanged;
		}
		else
		{
			kills[attacker]++;
			score[attacker] = GetEntProp(attacker, Prop_Data, "m_iPoints");
		}
		bitChanged[attacker] |= SE_ScoreChanged;
		bitChanged[attacker] |= SE_KillsChanged;
	}
	if ((killed <= MaxClients) && (killed > 0)) bitChanged[killed] |= SE_DeathsChanged;
}

void StoreScores(int client)
{
	if ((strlen(SteamIDbuf[client]) < 1) || (!IsValidEntity(client)) || (Handle_Database == INVALID_HANDLE) || (hSEdisable.BoolValue)) return;
	if (!bitChanged[client]) return;
	char Query[256];
	char szTmp[64];
	if (bStored[client])
	{
		deaths[client] = GetEntProp(client, Prop_Data, "m_iDeaths");
		StrCat(Query,sizeof(Query),"UPDATE persistentscores SET ");
		if (bitChanged[client] & SE_KillsChanged)
		{
			Format(szTmp,sizeof(szTmp),"h1 = %i, ",kills[client]);
			StrCat(Query,sizeof(Query),szTmp);
		}
		if (bitChanged[client] & SE_DeathsChanged)
		{
			Format(szTmp,sizeof(szTmp),"h2 = %i, ",deaths[client]);
			StrCat(Query,sizeof(Query),szTmp);
		}
		if (bitChanged[client] & SE_ScoreChanged)
		{
			Format(szTmp,sizeof(szTmp),"h3 = %i, ",score[client]);
			StrCat(Query,sizeof(Query),szTmp);
		}
		if (bitChanged[client] & SE_CDataChanged)
		{
			Format(szTmp,sizeof(szTmp),"lastcdata = '%s', ",clmap[client]);
			StrCat(Query,sizeof(Query),szTmp);
		}
		Query[strlen(Query)-2] = '\0';
		Format(szTmp,sizeof(szTmp)," WHERE SteamID = '%s';",SteamIDbuf[client]);
		StrCat(Query,sizeof(Query),szTmp);
	}
	else
	{
		Format(Query,sizeof(Query),"INSERT INTO persistentscores VALUES( '%s', %i, %i, %i, %s);",SteamIDbuf[client],kills[client],deaths[client],score[client],contentdata);
	}
	if (strlen(Query) > 0)
	{
		if (hSEqdbg.BoolValue) PrintToServer("%s",Query);
		SQL_TQuery(Handle_Database,Store,Query,client);
	}
	bitChanged[client] = 0;
}

public void Store(Handle owner, Handle hndl, const char[] error, any data)
{
	if ((hndl == INVALID_HANDLE) || (owner == INVALID_HANDLE))
	{
		PrintToServer("SEStoreSQLErr: '%s'",error);
	}
	else if (data > -1) bStored[data] = true;
}

public void SrvQueries(Handle owner, Handle hndl, const char[] error, any data)
{
	if (strlen(error) > 0) PrintToServer("Err %s",error);
}

public Action hooknpcs(Handle timer)
{
	if (hSEscoreperhit.BoolValue)
	{
		int entity = -1;
		while((entity = FindEntityByClassname(entity,"npc_*")) != INVALID_ENT_REFERENCE)
		{
			if (IsValidEntity(entity)) SDKHookEx(entity, SDKHook_OnTakeDamage, OnNPCTakeDamage);
		}
	}
}

public Action SaveClients(Handle timer)
{
	for (int i = 1; i<MaxClients+1 ;i++)
	{
		if ((bitChanged[i]) && (IsClientConnected(i)))
		{
			StoreScores(i);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if ((StrContains(classname, "npc_") != -1) && (hSEscoreperhit.BoolValue))
	{
		SDKHookEx(entity, SDKHook_OnTakeDamage, OnNPCTakeDamage);
	}
	if (hSEscoreforheal.BoolValue)
	{
		if (StrEqual(classname,"item_health_drop",false))
		{
			CreateTimer(0.14, waitforhook, entity);
		}
	}
}

public Action OnNPCTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (damage > 1.0)
	{
		char atkbuf[16];
		if (IsValidEntity(attacker))
		{
			GetEntityClassname(attacker, atkbuf, sizeof(atkbuf));
		}
		if ((StrEqual(atkbuf,"player",false)) && (IsValidEntity(victim)))
		{
			char victimbuf[24];
			char infbuf[16];
			char wepbuf[24];
			int enth = GetEntProp(victim, Prop_Data, "m_iHealth");
			GetEntityClassname(victim, victimbuf, sizeof(victimbuf));
			GetEntityClassname(inflictor, infbuf, sizeof(infbuf));
			GetClientWeapon(attacker, wepbuf, sizeof(wepbuf));
			if ((StrContains(victimbuf,"npc_turret",false) == -1) && (StrContains(victimbuf,"npc_furniture",false) == -1) && (StrContains(victimbuf,"npc_rollermine",false) == -1))
			{
				char nick[64];
				GetClientName(attacker, nick, sizeof(nick));
				if (RoundFloat(damage) > enth)
				{
					score[attacker]+=RoundToCeil(enth/10.0);
					SetEntProp(attacker,Prop_Data,"m_iPoints",score[attacker]);
					bitChanged[attacker] |= SE_ScoreChanged;
				}
				else
				{
					score[attacker]+=RoundToCeil(damage/10.0);
					SetEntProp(attacker,Prop_Data,"m_iPoints",score[attacker]);
					bitChanged[attacker] |= SE_ScoreChanged;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action eyeposchk(int client, int args)
{
	if (hSEscoreforheal.BoolValue)
	{
		if ((IsClientInGame(client)) && (IsPlayerAlive(client)) && (IsValidEntity(client)))
		{
			int targ = GetClientAimTarget(client, false);
			if (targ > 0)
			{
				char clsname[32];
				int charge;
				int medkitammo;
				float vecCLPos[3];
				float vecEntPos[3];
				GetClientAbsOrigin(client, vecCLPos);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",vecEntPos);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",vecEntPos);
				float chkdist = GetVectorDistance(vecCLPos,vecEntPos,false);
				GetEntityClassname(targ, clsname, sizeof(clsname));
				if((StrEqual(clsname, "item_healthcharger")) && (RoundFloat(chkdist) < 91) && (!(StrContains( mapbuf, "d3_c17_11") != -1)))
				{
					charge = GetEntProp(targ, Prop_Data, "m_iJuice");
					medkitammo = GetEntProp(client, Prop_Send, "m_iHealthPack");
					if ((charge < 1) && (medkitammo >= 20))
					{
						int plyscore = GetEntProp(client, Prop_Data, "m_iPoints");
						SetEntProp(client, Prop_Data, "m_iPoints", plyscore+10);
						score[client] = plyscore+10;
						bitChanged[client] |= SE_ScoreChanged;
					}
				}
				if ((StrEqual(clsname,"player")) && (RoundFloat(chkdist) < 91))
				{
					int targh = GetClientHealth(targ);
					int targmh = GetEntProp(targ,Prop_Send,"m_iMaxHealth");
					medkitammo = GetEntProp(client,Prop_Send,"m_iHealthPack");
					if ((targh < targmh) && (medkitammo >= 10))
					{
						float Time = GetTickedTime();
						if (Time >= Healchk[client])
						{
							Healchk[client] = Time + 2;
							int plyscore = GetEntProp(client, Prop_Data, "m_iPoints");
							SetEntProp(client, Prop_Data, "m_iPoints", plyscore+1);
							score[client] = plyscore+1;
							bitChanged[client] |= SE_ScoreChanged;
						}
					}
				}
			}
		}
	}
}

public Action waitforhook(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_StartTouch, StartTouch);
	}
}

public Action StartTouch(int entity, int other)
{
	int entown = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", 0);
	if ((entown != other) && (other < MaxClients+1) && (IsValidEntity(entown)))
	{
		if (GetClientHealth(other) < GetEntProp(other,Prop_Send,"m_iMaxHealth"))
		{
			int plyscore = GetEntProp(other, Prop_Data, "m_iPoints");
			SetEntProp(other, Prop_Data, "m_iPoints", plyscore+1);
			score[other] = plyscore+1;
			bitChanged[other] |= SE_ScoreChanged;
		}
	}
}

public void OnMapStart()
{
	GetCurrentMap(mapbuf, sizeof(mapbuf));
	Handle cvar = FindConVar("content_metadata");
	if (cvar != INVALID_HANDLE)
	{
		GetConVarString(cvar,contentdata,sizeof(contentdata));
		char fixuptmp[16][16];
		ExplodeString(contentdata," ",fixuptmp,16,16,true);
		if (StrEqual(fixuptmp[1],"|",false)) Format(contentdata,sizeof(contentdata),"%s",fixuptmp[2]);
		else Format(contentdata,sizeof(contentdata),"%s",fixuptmp[0]);
	}
	CloseHandle(cvar);
}