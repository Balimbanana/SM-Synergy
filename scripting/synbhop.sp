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
bool bhopdisable = false;
bool sxpmact = false;

#define PLUGIN_VERSION "0.2"
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
				if ((GetClientButtons(client) & button2) && (RoundFloat(suitpow) > 10))
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normsprintspeed);
				else
					SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normspeed);
				SetEntityGravity(client,1.0);
				SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
				clresetspeed[client] = false;
				clsecondchk[client] = false;
			}
			else
			{
				clsecondchk[client] = true;
				clreleased[client] = Time+0.1;
			}
		}
	}
}

public OnButtonPress(int client, int button)
{
	if (!bhopdisable)
	{
		int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
		float movemod = GetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue");
		if ((movemod > 0.9) && (groundchk != -1) && (!(GetClientButtons(client) & button2)))
		{
			SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",1.0);
			float curspeed = GetEntPropFloat(client,Prop_Send,"m_flMaxspeed");
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
		else if (groundchk == -1)
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

public OnButtonRelease(int client, int button)
{
	if (!bhopdisable)
	{
		int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
		if ((groundchk != -1) && (!(GetClientButtons(client) & button2)))
		{
			CreateTimer(0.1,releasebuff,client);
		}
	}
}

public Action releasebuff(Handle timer, int client)
{
	int groundchk = GetEntProp(client,Prop_Send,"m_hGroundEntity");
	if (groundchk != -1)
	{
		SetEntPropFloat(client,Prop_Send,"m_flMaxspeed",normspeed);
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
