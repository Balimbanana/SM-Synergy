//TODO:
//		trace walls

#include <sourcemod>
#include <sdktools>
#include <console>
#include <clientprefs>

#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "1.2"

int bclcookie[64];
Handle bclcookieh = INVALID_HANDLE;

int ClientCamera[MAXPLAYERS+1];

Handle var_ftb; // mp_fadetoblack
Handle var_fpd_enable;
Handle var_fpd_black;
Handle var_fpd_stay;
bool ftb = false; // mp_fadetoblack
bool fpd_enable = true;
int fpd_black = 0;
float fpd_stay = 0.0;
bool CL_Ragdoll[MAXPLAYERS+1];

char Attachment[64];

int game;
#define UNKNOWN 0
#define CSTRIKE 1
#define DODS	2
#define HL2DM	3

public Plugin myinfo = 
{
	name = "fpd (edited by Balimbanana)",
	author = "Eun",
	description = "first person death",
	version = PLUGIN_VERSION
};

public void OnPluginStart() 
{ 
	LoadTranslations("fpd.phrases");
	bclcookieh = RegClientCookie("FirstPersonDeaths", "First Person Deaths Settings", CookieAccess_Private);
	
	// set the game var
	SetGameVersion();
	
	// gamespecifed settings
	if (game == CSTRIKE)
	{
		Attachment = "forward";
	}
	else if (game == DODS)
	{
		Attachment = "head";
	}
	else if (game == HL2DM)
	{
		Attachment = "eyes";
	}
	else if (game == UNKNOWN)
	{
		Attachment = "forward";
	}

	CreateConVar("fpd_version", PLUGIN_VERSION, "First Person Death", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	var_fpd_enable = CreateConVar("fpd_enable", "1", "Enable / Disable FPD", _);
	var_fpd_black = CreateConVar("fpd_black", "0", "Duration to fade to black, 0 = disables", _);
	var_fpd_stay = CreateConVar("fpd_stay", "5", "Seconds to stay in ragdoll after death 0 = till round end", _);

	// events
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	// decide which mode depending on fadetoblack
	var_ftb = FindConVar("mp_fadetoblack");
	
	if (var_ftb != INVALID_HANDLE)
		ftb = GetConVarBool(var_ftb);
	else
		ftb = false;
		
	fpd_black = GetConVarInt(var_fpd_black);
		
	fpd_stay = GetConVarFloat(var_fpd_stay);

	// track changes of vars
	if (var_ftb != INVALID_HANDLE)
		HookConVarChange(var_ftb, Cvar_Changed);
	
	HookConVarChange(var_fpd_enable, Cvar_Changed);
	HookConVarChange(var_fpd_black, Cvar_Changed);
	HookConVarChange(var_fpd_stay, Cvar_Changed);
	
	//RegConsoleCmd("fpd", CurrentView);
	RegAdminCmd("fpds", CurrentView, ADMFLAG_ROOT, ".");
	RegConsoleCmd("fpd", SetFPD);
}

public Action SetFPD(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		if (bclcookie[client])
		{
			bclcookie[client] = 0;
			SetClientCookie(client, bclcookieh, "0");
			PrintToChat(client,"%T","TurnedOff",client);
		}
		else
		{
			bclcookie[client] = 1;
			SetClientCookie(client, bclcookieh, "1");
			PrintToChat(client,"%T","TurnedOn",client);
		}
		/*
		PrintToChat(client,"%T","InfDisplay",client);
		char cur[8];
		GetClientCookie(client,bclcookieh,cur,sizeof(cur));
		PrintToChat(client,"%T","InfCurSet",client,cur);
		*/
		return Plugin_Handled;
	}
	char h[8];
	GetCmdArg(1,h,sizeof(h));
	if (StrEqual(h,"on",false) || (StrEqual(h,"1",false)))
	{
		bclcookie[client] = 1;
		SetClientCookie(client, bclcookieh, "1");
		PrintToChat(client,"%T","TurnedOn",client);
	}
	if (StrEqual(h,"off",false) || (StrEqual(h,"0",false)))
	{
		bclcookie[client] = 0;
		SetClientCookie(client, bclcookieh, "0");
		PrintToChat(client,"%T","TurnedOff",client);
	}
	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
	bclcookie[client] = StringToInt(sValue);
}

public Action CurrentView(int client, int args)
{
	float angles0[3];
	GetClientEyeAngles(client, angles0);
	PrintToChatAll("GetClientEyeAngles: %f %f %f", angles0[0], angles0[1], angles0[2]);
	
	float angles1[3];
	GetClientAbsAngles(client, angles1); 
	PrintToChatAll("GetClientAbsAngles: %f %f %f", angles1[0], angles1[1], angles1[2]);
	
	float angles2[3];
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angles2);
	PrintToChatAll("m_angAbsRotation: %f %f %f", angles2[0], angles2[1], angles2[2]);
	
	float angles3[3];
	GetEntPropVector(client, Prop_Data, "m_angRotation", angles3);
	PrintToChatAll("m_angRotation: %f %f %f", angles3[0], angles3[1], angles3[2]);
}

public void OnEventShutdown()
{
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_spawn", OnPlayerSpawn);
}

public void Cvar_Changed(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == var_ftb)
	{
		ftb = GetConVarBool(var_ftb);
	}
	else if (convar == var_fpd_enable)
	{
		fpd_enable = GetConVarBool(var_fpd_enable);
	}
	else if (convar == var_fpd_black)
	{
		fpd_black = GetConVarInt(var_fpd_black);
	}
	
	else if (convar == var_fpd_stay)
	{
		fpd_stay = GetConVarFloat(var_fpd_stay);
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ClientOk(Client))
	{
		
		if (fpd_enable)
		{
			if (game == CSTRIKE)
			{
				/*
				// gsg and sas got not the attachment forward
				char ModelName[128];
				GetEntPropString(Client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
				if (StrContains(ModelName, "ct_gsg9.mdl", false) > -1 || StrContains(ModelName, "ct_sas.mdl", false) > -1)
				{
					SetEntityModel(Client, "models/player/ct_urban.mdl");
				}
				*/
			}
			if (game == HL2DM)
			{
				CL_Ragdoll[Client] = true;
			}
			else
			{
				QueryClientConVar(Client, "cl_ragdoll_physics_enable", ClientConVar, Client);
			}
		}
		
		// clear cam
		ClearCam(Client);		
	}
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if (!fpd_enable)
	{
		return Plugin_Continue;
	}
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (bclcookie[Client])
	{
		if (ClientOk(Client))
		{	
			if (CL_Ragdoll[Client])
			{
				int ragdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");	
				if (ragdoll < 0)
				{
					return Plugin_Continue;
				}
				SpawnCamAndAttach(Client, ragdoll);
			}
		}
	}
	return Plugin_Continue;
}

public void ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (StringToInt(cvarValue) > 0)
		CL_Ragdoll[client] = true;
	else
		CL_Ragdoll[client] = false;
}

public bool SpawnCamAndAttach(int Client, int Ragdoll)
{
	char ModelName[128];
	GetEntPropString(Client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
	if (!IsValidEntity(Ragdoll) || StrContains(ModelName, "ct_gsg9.mdl", false) > -1 || StrContains(ModelName, "ct_sas.mdl", false) > -1)
	{
		return false;
	}
	
	// Precache model
	char StrModel[64];
	//Format(StrModel, sizeof(StrModel), "models/error.mdl");
	Format(StrModel, sizeof(StrModel), "models/blackout.mdl");
	PrecacheModel(StrModel, true);
	
	// Spawn dynamic prop entity
	int Entity = CreateEntityByName("prop_dynamic");
	if (Entity == -1)
		return false;
	
	// Generate unique id for the entity
	char StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "fpd_RagdollCam%d", Entity);
	
	// Setup entity
	DispatchKeyValue(Entity, "targetname", StrEntityName);
	DispatchKeyValue(Entity, "model",		StrModel);
	DispatchKeyValue(Entity, "solid",		"0");
	DispatchKeyValue(Entity, "rendermode", "10"); // dont render
	DispatchKeyValue(Entity, "disableshadows", "1"); // no shadows
	
	float angles[3];
	GetClientEyeAngles(Client, angles);
	char CamTargetAngles[64];
	Format(CamTargetAngles, 64, "%f %f %f", angles[0], angles[1], angles[2]);
	DispatchKeyValue(Entity, "angles", CamTargetAngles); 
	
	SetEntityModel(Entity, StrModel);
	DispatchSpawn(Entity);
		
	// Set parent
	SetVariantString("!activator");
	AcceptEntityInput(Entity, "SetParent", Ragdoll, Entity, 0);
	
	// Set attachment
	SetVariantString(Attachment);
	AcceptEntityInput(Entity, "SetParentAttachment", Entity, Entity, 0);
	// this bricks the Angles of the Entity
	
	// Activate
	AcceptEntityInput(Entity, "TurnOn");
	
	// Set View
	SetClientViewEntity(Client, Entity);
	ClientCamera[Client] = Entity;
	
	if (!ftb)
	{
		if (fpd_stay > 0)	// stay in ragdoll for x seconds and ftb is disabled
		{
			CreateTimer(fpd_stay, ClearCamTimer, Client);	
		}
		if (fpd_black > 0)
		{
			PerformFade(Client, fpd_black, false);
		}
		//CreateTimer(1.0, ThinkTimer, Client); // Do this later
	}
	
	CreateTimer(0.1, ReValidateRagdoll, Ragdoll, TIMER_FLAG_NO_MAPCHANGE);

	return true;
} 

// reset to player
public Action ClearCamTimer(Handle timer, int Client)
{
	ClearCam(Client);
}

public Action ReValidateRagdoll(Handle timer, int Ragdoll)
{
	if (IsValidEntity(Ragdoll))
	{
		PropFieldType nPropFieldType;
		int datamapoffs = FindDataMapInfo(Ragdoll, "m_nRenderFX", nPropFieldType);
		if (datamapoffs != -1 && nPropFieldType == PropField_Integer)
		{
			int nRenderFX = GetEntData(Ragdoll, datamapoffs, 4);
			if (nRenderFX == 0)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidEntity(ClientCamera[i]))
					{
						if (HasEntProp(ClientCamera[i], Prop_Data, "m_hParent"))
						{
							int hParent = GetEntPropEnt(ClientCamera[i], Prop_Data, "m_hParent");
							if (hParent == Ragdoll)
							{
								ClearCam(i);
								break;
							}
						}
					}
				}
			}
		}
	}
}

public void ClearCam(int Client)
{
	if (ClientCamera[Client] && ClientOk(Client))
	{
		if (fpd_black)
		{
			PerformFade(Client, 0, true);
		}
		SetClientViewEntity(Client, Client);
		ClientCamera[Client] = false;
	}
}

public bool ClientOk(int Client)
{
	if (IsClientConnected(Client) && IsClientInGame(Client))
	{
		if (!IsFakeClient(Client))
		{
			if (GetEntProp(Client, Prop_Data, "m_iTeamNum") != 1)
			{	
				return true;
			}
		}
	}
	return false;
}

#define FFADE_IN		0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0002		// Fade out (not in)
#define FFADE_MODULATE	0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT	0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE		0x0010		// Purges all other fades, replacing them with this one

public bool PerformFade(int Client, int duration, bool inset)
{
	Handle hFadeClient = StartMessageOne("Fade", Client);
	BfWriteShort(hFadeClient,duration);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
	BfWriteShort(hFadeClient,0);		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
	if (inset)
	{
		BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_IN)); // fade type (in / out)
	}
	else
	{
		BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT)); // fade type (in / out)
	}
	BfWriteByte(hFadeClient, 0);	// fade red
	BfWriteByte(hFadeClient, 0);	// fade green
	BfWriteByte(hFadeClient, 0);	// fade blue
	BfWriteByte(hFadeClient, 255);	// fade alpha
	EndMessage();
	return true;
}

public void SetGameVersion()
{
	char gamestr[64];
	GetGameFolderName(gamestr, sizeof(gamestr));
	if (!strcmp(gamestr, "cstrike"))
		game = CSTRIKE;
	else if (!strcmp(gamestr, "dod"))
		game = DODS;
	else if (!strcmp(gamestr, "hl2mp") || !strcmp(gamestr, "synergy"))
		game = HL2DM;
	else
		game = UNKNOWN;
}

public Action ThinkTimer(Handle timer, int Client)
{
	if (ClientCamera[Client])
	{
		if (IsEntNearWall(ClientCamera[Client]))
		{
			if (fpd_black)
			{
				PerformFade(Client, 0, true);
			}
			SetClientViewEntity(Client, Client);
			ClientCamera[Client] = 0;
		}
		else
		{
			CreateTimer(1.0, ThinkTimer, Client);
		}
	}
}

stock bool IsEntNearWall(int ent)
{
	float vOrigin[3];
	float vec[3];
	float vAngles[3];
	Handle trace;
	GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", vOrigin);
	GetEntPropVector(ent, Prop_Data, "m_angAbsRotation", vAngles);	// <-- This dont works, because on SetAttachment this get currupt
	PrintToChatAll("%f %f %f |	%f %f %f", vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2] );
	trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, ent);						
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vec, trace);
		if (GetVectorDistance(vec, vOrigin) < 40)
		{
			CloseHandle(trace);
			return true;
		}
	}
	CloseHandle(trace);
	return false;
}

public bool TraceRayDontHitSelf(int entity, int mask, int data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}