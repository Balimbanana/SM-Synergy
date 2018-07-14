#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "HealthShow",
	author = "Balimbanana",
	description = "Shows health of npcs while looking at them.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1141375#post1141375"
}

int showenonly = true;
int showtype = 0;
bool numtype = false;
Handle airelarr = INVALID_HANDLE;
Handle htarr = INVALID_HANDLE;
float antispamchk[MAXPLAYERS+1];

public void OnPluginStart()
{
	Handle cvarh = CreateConVar("sm_healthshow_enemies", "1", "Only show enemy health", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarh, cvarch);
	cvarh = CreateConVar("sm_healthshow_type", "0", "Change the type of message used to show health, 3 is disabled", _, true, 0.0, true, 3.0);
	HookConVarChange(cvarh, cvarht);
	cvarh = CreateConVar("sm_healthshow_num", "0", "Change how health is shown, 0 is percent, 1 is exact health", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarh, cvarhn);
	CloseHandle(cvarh);
	airelarr = CreateArray(64);
	htarr = CreateArray(64);
	AutoExecConfig(true,"healthshow");
}

public void OnMapStart()
{
	ClearArray(airelarr);
	ClearArray(htarr);
}

public cvarch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
		showenonly = true;
	else
		showenonly = false;
}

public cvarht(Handle convar, const char[] oldValue, const char[] newValue)
{
	if ((StringToInt(newValue) >= 1) && (StringToInt(newValue) <= 3))
		showtype = StringToInt(newValue);
	else
		showtype = 0;
}

public cvarhn(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1)
		numtype = true;
	else
		numtype = false;
}

bool IsInViewCtrl(int client)
{
	if ((IsValidEntity(client)) && (IsClientConnected(client)))
	{
		int m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
		char classname[20];
		if(IsValidEdict(m_hViewEntity) && GetEdictClassname(m_hViewEntity,classname,sizeof(classname)))
			if(StrEqual(classname, "point_viewcontrol"))
				return true;
	}
	return false;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if (IsPlayerAlive(client) && !IsFakeClient(client))
	{
		int targ = GetClientAimTarget(client,false);
		if ((targ != -1) && (targ > MaxClients))
		{
			char clsname[32];
			GetEntityClassname(targ,clsname,sizeof(clsname));
			if ((StrContains(clsname,"npc_",false) != -1) && (!StrEqual(clsname,"npc_furniture")) && (StrContains(clsname,"turret",false) == -1) && (StrContains(clsname,"grenade",false) == -1) && (StrContains(clsname,"satchel",false) == -1) && (!IsInViewCtrl(client)))
			{
				if (showenonly)
				{
					if (GetNPCAlly(clsname))
					{
						int maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
						int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
						ReplaceString(clsname,sizeof(clsname),"npc_","");
						clsname[0] &= ~(1 << 5);
						float Time = GetTickedTime();
						if ((antispamchk[client] <= Time) && (curh > 0))
						{
							antispamchk[client] = Time + 0.07;
							PrintTheMsg(client,curh,maxh,clsname);
						}
					}
				}
				else
				{
					int maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
					int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
					ReplaceString(clsname,sizeof(clsname),"npc_","");
					clsname[0] &= ~(1 << 5);
					float Time = GetTickedTime();
					if ((antispamchk[client] <= Time) && (curh > 0))
					{
						antispamchk[client] = Time + 0.07;
						PrintTheMsg(client,curh,maxh,clsname);
					}
				}
			}
		}
	}
}

public PrintTheMsg(int client, int curh, int maxh, char clsname[32])
{
	char hudbuf[32];
	if (StrEqual(clsname,"monk",false)) Format(clsname,sizeof(clsname),"Father Grigori");
	else if (StrEqual(clsname,"kleiner",false)) Format(clsname,sizeof(clsname),"Isaac Kleiner");
	else if (StrEqual(clsname,"mossman",false)) Format(clsname,sizeof(clsname),"Judith Mossman");
	else if (StrEqual(clsname,"magnusson",false)) Format(clsname,sizeof(clsname),"Arne Magnusson");
	else if (StrEqual(clsname,"breen",false)) Format(clsname,sizeof(clsname),"Dr Breen");
	else if (StrEqual(clsname,"alyx",false)) Format(clsname,sizeof(clsname),"Alyx Vance");
	else if (StrEqual(clsname,"eli",false)) Format(clsname,sizeof(clsname),"Eli Vance");
	if (numtype)
		Format(hudbuf,sizeof(hudbuf),"%s (%i)",clsname,curh);
	else
		Format(hudbuf,sizeof(hudbuf),"%s (%1.f%%)",clsname,(FloatDiv(float(curh),float(maxh))*100));
	if (showtype == 0)
	{
		SetHudTextParams(-1.0, 0.55, 0.1, 255, 255, 0, 255, 0, 0.1, 0.0, 0.1);
		ShowHudText(client,0,"%s",hudbuf);
	}
	else if (showtype == 1)
	{
		float Time = GetTickedTime();
		antispamchk[client] = Time + 0.5;
		PrintHintText(client,hudbuf);
	}
	else if (showtype == 2)
	{
		PrintCenterText(client,hudbuf);
	}
}

public OnClientDisconnect(int client)
{
	antispamchk[client] = 0.0;
}

bool GetNPCAlly(char[] clsname)
{
	if (StrEqual(clsname,"npc_alyx",false) || StrEqual(clsname,"npc_dog",false) || StrEqual(clsname,"npc_barney",false) || StrEqual(clsname,"npc_citizen",false) || StrEqual(clsname,"npc_vortigaunt",false) || StrEqual(clsname,"npc_magnusson",false) || StrEqual(clsname,"npc_eli",false) || StrEqual(clsname,"npc_mossman",false) || StrEqual(clsname,"npc_monk",false) || StrEqual(clsname,"npc_kleiner",false))
		return false;
	if (GetArraySize(airelarr) < 1)
		findairel(MaxClients+1,"ai_relationship");
	if (GetArraySize(htarr) > 0)
	{
		if (FindStringInArray(htarr,clsname) != -1) return false;
	}
	else
	{
		for (int i = 0;i<GetArraySize(airelarr);i++)
		{
			char itmp[32];
			GetArrayString(airelarr, i, itmp, sizeof(itmp));
			int rel = StringToInt(itmp);
			if (IsValidEntity(rel))
			{
				char clsnamechk[16];
				GetEntityClassname(rel, clsnamechk, sizeof(clsnamechk));
				if (StrEqual(clsnamechk,"ai_relationship",false))
				{
					char subj[32];
					GetEntPropString(rel,Prop_Data,"m_iszSubject",subj,sizeof(subj));
					if (StrContains(clsname,subj,false) != -1)
					{
						char targ[32];
						GetEntPropString(rel,Prop_Data,"m_target",targ,sizeof(targ));
						int disp = GetEntProp(rel,Prop_Data,"m_iDisposition");
						int act = GetEntProp(rel,Prop_Data,"m_bIsActive");
						//disp 1 = D_HT // 2 = D_NT // 3 = D_LI // 4 = D_FR
						if ((StrContains(targ,"player",false) != -1) && (disp == 3) && (act != 0))
						{
							if (FindStringInArray(htarr,subj) == -1)
								PushArrayString(htarr,subj);
							return false;
						}
						else if ((StrContains(targ,"player",false) != -1) && (disp == 1) && (act != 0))
							return true;
					}
				}
			}
			else
				findairel(MaxClients+1,"ai_relationship");
		}
	}
	return true;
}

public Action findairel(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		char prevtmp[16];
		Format(prevtmp, sizeof(prevtmp), "%i", thisent);
		if((thisent >= 0) && (FindStringInArray(airelarr, prevtmp) == -1))
		{
			char subj[32];
			GetEntPropString(thisent,Prop_Data,"m_iszSubject",subj,sizeof(subj));
			if (StrContains(subj,"player",false) == -1)
			{
				PushArrayString(airelarr, prevtmp);
			}
		}
		findairel(thisent++,clsname);
	}
	return Plugin_Handled;
}