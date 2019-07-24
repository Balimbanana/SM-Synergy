#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

float airaccel = 10.0;
float maxspeed = 450.0;
float normspeed = 190.0;
float normsprintspeed = 320.0;
float clreleased[MAXPLAYERS+1];
bool clresetspeed[MAXPLAYERS+1];
bool clsecondchk[MAXPLAYERS+1];
bool clapplied[MAXPLAYERS+1];
bool bhopdisable = false;
bool sxpmact = false;
bool hl1act = false;
int bhopmode = 1;

#define PLUGIN_VERSION "0.28"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synbhopupdater.txt"

public Plugin:myinfo = 
{
	name = "BHopping in Synergy",
	author = "Balimbanana",
	description = "Enables BHopping",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	Handle airaccelh = FindConVar("sv_airaccelerate");
	if (airaccelh == INVALID_HANDLE)
		airaccelh = CreateConVar("sv_airaccelerate", "10.0", "", _, true, 0.0, true, 1.0);
	airaccel = GetConVarFloat(airaccelh);
	HookConVarChange(airaccelh, airaccelchange);
	airaccelh = FindConVar("sv_maxaccel");
	if (airaccelh == INVALID_HANDLE)
		airaccelh = CreateConVar("sv_maxaccel", "450.0", "", _, true, 0.0, false, 10000.0);
	maxspeed = GetConVarFloat(airaccelh);
	HookConVarChange(airaccelh, maxspeedchg);
	airaccelh = FindConVar("hl2_normspeed");
	if (airaccelh == INVALID_HANDLE)
		airaccelh = CreateConVar("hl2_normspeed", "190.0", "", _, true, 0.0, false, 10000.0);
	normspeed = GetConVarFloat(airaccelh);
	HookConVarChange(airaccelh, normspeedchg);
	airaccelh = FindConVar("hl2_sprintspeed");
	if (airaccelh == INVALID_HANDLE)
		airaccelh = CreateConVar("hl2_sprintspeed", "320.0", "", _, true, 0.0, false, 10000.0);
	normsprintspeed = GetConVarFloat(airaccelh);
	HookConVarChange(airaccelh, runspeedchg);
	airaccelh = FindConVar("bhopdisable");
	if (airaccelh == INVALID_HANDLE)
		airaccelh = CreateConVar("bhopdisable", "0", "Enable or Disable BHopping", _, true, 0.0, true, 1.0);
	bhopdisable = GetConVarBool(airaccelh);
	HookConVarChange(airaccelh, disablech);
	airaccelh = FindConVar("bhopmode");
	if (airaccelh == INVALID_HANDLE)
		airaccelh = CreateConVar("bhopmode", "2", "Sets BHop mode, 1 is by speed mod, 2 is by velocity mod", _, true, 1.0, true, 2.0);
	bhopmode = GetConVarInt(airaccelh);
	HookConVarChange(airaccelh, modech);
	CloseHandle(airaccelh);
}

public void OnAllPluginsLoaded()
{
	Handle cvarchk = FindConVar("sxpm_awareness");
	if (cvarchk != INVALID_HANDLE)
	{
		sxpmact = true;
	}
	else sxpmact = false;
	CloseHandle(cvarchk);
}

public airaccelchange(Handle convar, const char[] oldValue, const char[] newValue)
{
	airaccel = StringToFloat(newValue);
}

public maxspeedchg(Handle convar, const char[] oldValue, const char[] newValue)
{
	maxspeed = StringToFloat(newValue);
}

public normspeedchg(Handle convar, const char[] oldValue, const char[] newValue)
{
	normspeed = StringToFloat(newValue);
}

public runspeedchg(Handle convar, const char[] oldValue, const char[] newValue)
{
	normsprintspeed = StringToFloat(newValue);
}

public disablech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
	{
		bhopdisable = true;
		for (int i = 1; i<MaxClients+1; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				if (IsPlayerAlive(i))
				{
					SetEntPropFloat(i,Prop_Send,"m_flMaxspeed",normspeed);
					SetEntityGravity(i,1.0);
					SetEntPropFloat(i,Prop_Send,"m_flLaggedMovementValue",1.0);
					clresetspeed[i] = false;
				}
			}
		}
	}
	else bhopdisable = false;
}

public modech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) < 1)
	{
		bhopmode = 1;
	}
	else
	{
		bhopmode = StringToInt(newValue);
	}
}

int button1 = (1 << 1);
int button2 = (1 << 17);
int button3 = (1 << 3);
int g_LastButtons[MAXPLAYERS+1];

public OnClientDisconnect_Post(int client)
{
	g_LastButtons[client] = 0;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if (buttons & button1) {
		if (!(g_LastButtons[client] & button1)) {
			OnButtonPress(client, button1);
		}
	} else if ((g_LastButtons[client] & button1)) {
		OnButtonRelease(client, button1);
	}
	if (buttons & button2) {
		if (!(g_LastButtons[client] & button2)) {
			OnButtonPress2(client, button2);
		}
	} else if ((g_LastButtons[client] & button2)) {
		OnButtonRelease2(client, button2);
	}
	if (buttons & button3) {
		if (!(g_LastButtons[client] & button3)) {
			OnButtonPress2(client, button3);
		}
	} else if ((g_LastButtons[client] & button3)) {
		OnButtonRelease2(client, button3);
	}
	g_LastButtons[client] = buttons;
	float Time = GetTickedTime();
	if ((clreleased[client] < Time) && (clresetspeed[client]))
	{
		int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
		if (groundchk != -1)
		{
			//secondchk allows for large jumps and/or antigrav
			if (clsecondchk[client])
			{
				float suitpow = 11.0;
				if (HasEntProp(client,Prop_Send,"m_flSuitPower"))
					suitpow = GetEntPropFloat(client,Prop_Send,"m_flSuitPower");
				if ((buttons & button2) && (RoundFloat(suitpow) > 10) && (!hl1act))
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normsprintspeed);
				else if ((buttons & button2) && (hl1act))
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normspeed);
				else if (hl1act)
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normsprintspeed);
				else
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normspeed);
				SetEntityGravity(client,1.0);
				SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
				clresetspeed[client] = false;
				clsecondchk[client] = false;
				clapplied[client] = false;
			}
			else
			{
				clsecondchk[client] = true;
				clreleased[client] = Time+0.1;
			}
		}
		else if ((bhopmode == 2) && (!clapplied[client]))
		{
			float shootvel[3];
			if (HasEntProp(client,Prop_Send,"m_vecVelocity[0]")) shootvel[0] = GetEntPropFloat(client,Prop_Send,"m_vecVelocity[0]");
			if (HasEntProp(client,Prop_Send,"m_vecVelocity[1]")) shootvel[1] = GetEntPropFloat(client,Prop_Send,"m_vecVelocity[1]");
			shootvel[0] = shootvel[0] * (1.0 + airaccel * 0.0129);
			shootvel[1] = shootvel[1] * (1.0 + airaccel * 0.0129);
			if (HasEntProp(client,Prop_Send,"m_vecVelocity[2]")) shootvel[2] = GetEntPropFloat(client,Prop_Send,"m_vecVelocity[2]");
			TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,shootvel);
			clresetspeed[client] = true;
			clapplied[client] = true;
			clreleased[client] = Time+0.15;
		}
	}
}

public OnButtonPress(int client, int button)
{
	if (!bhopdisable)
	{
		int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
		int ladderchk = GetEntPropEnt(client,Prop_Send,"m_hLadder");
		float movemod = GetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue");
		int vckent = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		//PrintToServer("Chks %i %i %1.f %i",groundchk,ladderchk,movemod,vckent);
		if ((movemod > 0.9) && (vckent == -1) && (ladderchk == -1) && (groundchk != -1) && (!(GetClientButtons(client) & button2)))
		{
			SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
			float curspeed = GetEntPropFloat(client,Prop_Send,"m_flMaxspeed");
			if (bhopmode == 1)
			{
				clreleased[client] = GetTickedTime()+0.8;
				clresetspeed[client] = true;
				if (curspeed < maxspeed)
				{
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",curspeed+airaccel);
					if (curspeed+airaccel > 450.0)
					{
						float mvval = 1.0 + (curspeed+airaccel) * 0.0001;
						float gravset = 1.0-mvval+1.5;
						if ((gravset < 0.2) && (!sxpmact))
							SetEntityGravity(client,0.2);
						else if (!sxpmact)
							SetEntityGravity(client,gravset);
						SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",mvval);
					}
				}
				if (curspeed > maxspeed)
				{
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",maxspeed);
					if (maxspeed > 450.0)
					{
						float mvval = 1.0 + (curspeed+airaccel) * 0.0001;
						float gravset = 1.0-mvval+1.5;
						if ((gravset < 0.2) && (!sxpmact))
							SetEntityGravity(client,0.2);
						else if (!sxpmact)
							SetEntityGravity(client,gravset);
						SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",mvval);
					}
				}
			}
			else if (bhopmode == 2)
			{
				SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",maxspeed);
				clreleased[client] = GetTickedTime()+0.05;
				clresetspeed[client] = true;
				//CreateTimer(0.1,shootoff,client,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if ((groundchk == -1) && (bhopmode == 1))
		{
			clreleased[client] = GetTickedTime()+0.1;
			clresetspeed[client] = true;
		}
		/*
		if (GetClientButtons(client) & button2)
		{
			clresetspeed[client] = false;
		}
		*/
	}
}

public Action shootoff(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		float shootvel[3];
		if (HasEntProp(client,Prop_Send,"m_vecVelocity[0]")) shootvel[0] = GetEntPropFloat(client,Prop_Send,"m_vecVelocity[0]");
		if (HasEntProp(client,Prop_Send,"m_vecVelocity[1]")) shootvel[1] = GetEntPropFloat(client,Prop_Send,"m_vecVelocity[1]");
		//ScaleVector(shootvel,1.0+(airaccel/10));
		if (shootvel[0] > 0.0) shootvel[0]+=airaccel;
		else shootvel[0]-=airaccel;
		if (shootvel[1] > 0.0) shootvel[1]+=airaccel;
		else shootvel[1]-=airaccel;
		if (HasEntProp(client,Prop_Send,"m_vecVelocity[2]")) shootvel[2] = GetEntPropFloat(client,Prop_Send,"m_vecVelocity[2]");
		TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,shootvel);
	}
}

public OnButtonRelease(int client, int button)
{
	if (!bhopdisable)
	{
		int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
		if ((groundchk != -1) && (!(GetClientButtons(client) & button2)))
		{
			clreleased[client] = GetTickedTime()+0.8;
			clresetspeed[client] = true;
		}
	}
}

public OnButtonPress2(int client, int button)
{
	if (!bhopdisable)
	{
		int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
		float movemod = GetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue");
		if ((movemod > 0.9) && (groundchk == -1))
		{
			SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
			float curspeed = GetEntPropFloat(client,Prop_Send,"m_flMaxspeed");
			clresetspeed[client] = false;
			if (curspeed < maxspeed)
			{
				SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",curspeed+airaccel);
			}
			if (curspeed > maxspeed)
				SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",maxspeed);
		}
	}
}

public OnButtonRelease2(int client, int button)
{
	if (!bhopdisable)
		CreateTimer(0.1, buttonrelease2timer, client);
}

public Action buttonrelease2timer(Handle timer, any client)
{
	if (IsValidEntity(client))
	{
		float movemod = GetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue");
		if (movemod > 0.9)
		{
			SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
			float curspeed = GetEntPropFloat(client,Prop_Send,"m_flMaxspeed");
			clreleased[client] = GetTickedTime()+0.8;
			clresetspeed[client] = true;
			if (curspeed > maxspeed)
				SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",maxspeed);
		}
	}
}

public OnLibraryAdded(const char[] name)
{
    if (StrEqual(name,"updater",false))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public void OnMapStart()
{
	if ((FileExists("sound/scientist/scream01.wav",true,NULL_STRING)) && (FileExists("models/bullsquid.mdl",true,NULL_STRING)) && (FileExists("materials/halflife/!c1a1cw00.vtf",true,NULL_STRING))) hl1act = true;
	else hl1act = false;
}
