#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Synergy Save/Teleport",
	author = "Balimbanana",
	description = "Allows people to save and teleport to their saved positions.",
	version = "1.0",
	url = "https://github.com/Balimbanana/SM-Synergy"
}

float saveposx[MAXPLAYERS];
float saveposy[MAXPLAYERS];
float saveposz[MAXPLAYERS];
float saveangx[MAXPLAYERS];
float saveangy[MAXPLAYERS];
float saveangz[MAXPLAYERS];
bool saveset[MAXPLAYERS];
int citshowcl[MAXPLAYERS];
bool citshowset = true;
char citeffect[128];
float teleportcd = 1.0;
float antispamchk[MAXPLAYERS];

public void OnPluginStart()
{
	RegConsoleCmd("s", savepos);
	RegConsoleCmd("t", teleport);
	Handle citshowh = CreateConVar("savetp_effect","models/effects/portalfunnel.mdl","Change the effect that shows where players saves are, none or 0 to disable.");
	GetConVarString(citshowh,citeffect,sizeof(citeffect));
	HookConVarChange(citshowh, citshowch);
	CloseHandle(citshowh);
	Handle teleportcdh = CreateConVar("savetp_cooldown","1.0","Sets cooldown time to stop spamming teleport.", _, true, 0.0, true, 120.0);
	HookConVarChange(teleportcdh, teleportcdch);
	CloseHandle(teleportcdh);
}

public citshowch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if ((StrEqual(newValue, "none")) || (StrEqual(newValue, "0")))
	{
		citshowset = false;
	}
	else
	{
		if (FileExists(newValue,true,NULL_STRING))
		{
			Format(citeffect,sizeof(citeffect),newValue);
			citshowset = true;
		}
		else
		{
			PrintToServer("The effect %s was not found.",newValue);
			citshowset = false;
		}
	}
}

public teleportcdch(Handle convar, const char[] oldValue, const char[] newValue)
{
	teleportcd = StringToFloat(newValue);
}

public Action savepos(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	if (saveset[client])
	{
		if (citshowcl[client] != 0)
		{
			AcceptEntityInput(citshowcl[client],"kill");
			citshowcl[client] = 0;
		}
	}
	float curpos[3];
	float curang[3];
	GetClientAbsOrigin(client,curpos);
	GetClientEyeAngles(client,curang);
	saveposx[client] = curpos[0];
	saveposy[client] = curpos[1];
	saveposz[client] = curpos[2];
	saveangx[client] = curang[0];
	saveangy[client] = curang[1];
	saveangz[client] = curang[2];
	saveset[client] = true;
	if (citshowset)
	{
		if (FileExists(citeffect,true,NULL_STRING))
		{
			int citshow = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(citshow,"model",citeffect);
			DispatchKeyValue(citshow,"modelscale","0.025");
			DispatchKeyValue(citshow,"spawnflags","256");
			DispatchKeyValue(citshow,"solid","0");
			DispatchKeyValue(citshow,"DisableShadows","1");
			curang[0] = 180.0;
			curang[2] = 0.0;
			curpos[2]+=10.0;
			TeleportEntity(citshow,curpos,curang,NULL_VECTOR);
			DispatchSpawn(citshow);
			ActivateEntity(citshow);
			citshowcl[client] = citshow;
		}
	}
	PrintToChat(client,"Saved position!");
	return Plugin_Handled;
}

public Action teleport(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	float Time = GetTickedTime();
	if ((saveset[client]) && (antispamchk[client] <= Time+0.1))
	{
		float setpos[3];
		float setang[3];
		setpos[0] = saveposx[client];
		setpos[1] = saveposy[client];
		setpos[2] = saveposz[client];
		setang[0] = saveangx[client];
		setang[1] = saveangy[client];
		setang[2] = saveangz[client];
		TeleportEntity(client,setpos,setang,NULL_VECTOR);
		antispamchk[client] = Time + teleportcd;
	}
	else if (antispamchk[client] > Time)
		PrintToChat(client,"You cannot do that for another %.1f seconds...",antispamchk[client]-Time);
	else
		PrintToChat(client,"You do not have a saved position...");
	return Plugin_Handled;
}

public OnClientDisconnect(int client)
{
	saveposx[client] = 0.0;
	saveposy[client] = 0.0;
	saveposz[client] = 0.0;
	saveangx[client] = 0.0;
	saveangy[client] = 0.0;
	saveangz[client] = 0.0;
	antispamchk[client] = 0.0;
	if (citshowcl[client] != 0)
	{
		AcceptEntityInput(citshowcl[client],"kill");
		citshowcl[client] = 0;
	}
}

public void OnMapStart()
{
	for (int i = 0;i<MaxClients+1;i++)
	{
		saveset[i] = false;
		citshowcl[i] = 0;
		antispamchk[i] = 0.0;
	}
}