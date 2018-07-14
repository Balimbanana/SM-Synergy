#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "HealthDisplay",
	author = "Balimbanana",
	description = "Shows health of npcs while looking at them.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

Handle airelarr = INVALID_HANDLE;
Handle htarr = INVALID_HANDLE;
float antispamchk[MAXPLAYERS+1];

Handle bclcookieh = INVALID_HANDLE;
Handle bclcookie2h = INVALID_HANDLE;
Handle bclcookie3h = INVALID_HANDLE;
int bclcookie[MAXPLAYERS+1];
bool bclcookie2[MAXPLAYERS+1];
bool bclcookie3[MAXPLAYERS+1];

public void OnPluginStart()
{
	airelarr = CreateArray(64);
	htarr = CreateArray(64);
	bclcookieh = RegClientCookie("HealthDisplayType", "HealthDisplay type Settings", CookieAccess_Private);
	bclcookie2h = RegClientCookie("HealthDisplayNum", "HealthDisplay num Settings", CookieAccess_Private);
	bclcookie3h = RegClientCookie("HealthDisplayFriend", "HealthDisplay friend Settings", CookieAccess_Private);
	RegConsoleCmd("sm_healthdisplay",showinf);
	RegConsoleCmd("sm_healthtype",sethealthtype);
	RegConsoleCmd("sm_healthnum",sethealthnum);
	RegConsoleCmd("sm_healthfriendlies",sethealthfriendly);
}

public void OnMapStart()
{
	ClearArray(airelarr);
	ClearArray(htarr);
	CreateTimer(1.0,reloadclcookies);
}

public Action showinf(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	PrintToChat(client,"sm_healthtype <1-4>");
	PrintToChat(client,"Sets the type of message that is displayed for health stats. 4 disables.");
	PrintToChat(client,"sm_healthfriendlies <0-1>");
	PrintToChat(client,"Sets whether or not to show friendly npc health.");
	PrintToChat(client,"sm_healthnum <1-2>");
	PrintToChat(client,"Sets the way health is shown, 1 is percent, 2 is hit points.");
	return Plugin_Handled;
}

public Action sethealthtype(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"Usage: sm_healthtype <1-4>");
		PrintToChat(client,"Sets the type of message that is displayed for health stats.\n4 disables.");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		if (numset == 0)
		{
			PrintToChat(client,"Invalid number");
		}
		else if (numset == 1)
		{
			PrintToChat(client,"Set HealthDisplay to show HudText.");
			bclcookie[client] = 0;
			SetClientCookie(client, bclcookieh, "0");
		}
		else if (numset == 2)
		{
			PrintToChat(client,"Set HealthDisplay to show Hint.");
			bclcookie[client] = 1;
			SetClientCookie(client, bclcookieh, "1");
		}
		else if (numset == 3)
		{
			PrintToChat(client,"Set HealthDisplay to show CenterText.");
			bclcookie[client] = 2;
			SetClientCookie(client, bclcookieh, "2");
		}
		else
		{
			PrintToChat(client,"Disabled HealthDisplay.");
			bclcookie[client] = 3;
			SetClientCookie(client, bclcookieh, "3");
		}
	}
	return Plugin_Handled;
}

public Action sethealthfriendly(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"Usage: sm_healthfriend <0-1>");
		PrintToChat(client,"Sets whether or not to show friendly npc health.");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		if (numset == 0)
		{
			PrintToChat(client,"Set HealthDisplay to hide friendly npcs health.");
			bclcookie3[client] = false;
			SetClientCookie(client, bclcookie3h, "0");
		}
		else if (numset == 1)
		{
			PrintToChat(client,"Set HealthDisplay to show friendly npcs health.");
			bclcookie3[client] = true;
			SetClientCookie(client, bclcookie3h, "1");
		}
		else
		{
			PrintToChat(client,"Invalid number");
		}
	}
	return Plugin_Handled;
}

public Action sethealthnum(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"Usage: sm_healthnum <1-2>");
		PrintToChat(client,"Sets the way health is shown, 1 is percent, 2 is hit points.");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		int numset = StringToInt(h);
		if ((numset == 0) || (numset > 2))
		{
			PrintToChat(client,"Invalid number");
		}
		else if (numset == 1)
		{
			PrintToChat(client,"Set HealthDisplay to show percentage.");
			bclcookie2[client] = false;
			SetClientCookie(client, bclcookie2h, "0");
		}
		else if (numset == 2)
		{
			PrintToChat(client,"Set HealthDisplay to show hit points.");
			bclcookie2[client] = true;
			SetClientCookie(client, bclcookie2h, "1");
		}
	}
	return Plugin_Handled;
}

public Action reloadclcookies(Handle timer)
{
	for (int client = 1;client<MaxClients;client++)
	{
		if (IsClientConnected(client))
		{
			char sValue[4];
			GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie[client] = 0;
				SetClientCookie(client, bclcookieh, "0");
			}
			else
				bclcookie[client] = StringToInt(sValue);
			GetClientCookie(client, bclcookie2h, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie2[client] = false;
				SetClientCookie(client, bclcookie2h, "0");
			}
			else
				bclcookie2[client] = true;
			GetClientCookie(client, bclcookie3h, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie3[client] = false;
				SetClientCookie(client, bclcookie3h, "0");
			}
			else if (StringToInt(sValue) == 1)
				bclcookie3[client] = true;
		}
	}
}

public OnClientCookiesCached(int client)
{
	char sValue[4];
	GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie[client] = 0;
		SetClientCookie(client, bclcookieh, "0");
	}
	else
		bclcookie[client] = StringToInt(sValue);
	GetClientCookie(client, bclcookie2h, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie2[client] = false;
		SetClientCookie(client, bclcookie2h, "0");
	}
	else
		bclcookie2[client] = true;
	GetClientCookie(client, bclcookie3h, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie3[client] = false;
		SetClientCookie(client, bclcookie3h, "0");
	}
	else if (StringToInt(sValue) == 1)
		bclcookie3[client] = true;
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
				if (!bclcookie3[client])
				{
					if (GetNPCAlly(clsname))
					{
						int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
						ReplaceString(clsname,sizeof(clsname),"npc_","");
						int maxh = 20;
						if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
						{
							maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
							if (StrEqual(clsname,"combine_camera",false))
								maxh = 50;
							else if (maxh == 0)
							{
								char cvarren[32];
								Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
								Handle cvarchk = FindConVar(cvarren);
								if (cvarchk == INVALID_HANDLE)
									maxh = 20;
								else
									maxh = GetConVarInt(cvarchk);
							}
						}
						clsname[0] &= ~(1 << 5);
						float Time = GetTickedTime();
						if ((antispamchk[client] <= Time) && (curh > 0))
						{
							if (StrEqual(clsname,"combine_s",false))
							{
								char cmodel[64];
								GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
								if (StrContains( cmodel, "models/combine_super_soldier.mdl") != -1) //Elite
									Format(clsname,sizeof(clsname),"Combine Elite");
								else if (StrContains( cmodel, "models/combine_soldier_prisonguard.mdl") != -1) //Shotgunner
									Format(clsname,sizeof(clsname),"Combine Prison Guard");
								else
									Format(clsname,sizeof(clsname),"Combine Soldier");
							}
							antispamchk[client] = Time + 0.07;
							PrintTheMsg(client,curh,maxh,clsname);
						}
					}
				}
				else
				{
					int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
					ReplaceString(clsname,sizeof(clsname),"npc_","");
					int maxh = 20;
					if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
					{
						maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
						if (StrEqual(clsname,"combine_camera",false))
							maxh = 50;
						else if (maxh == 0)
						{
							char cvarren[32];
							Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
							Handle cvarchk = FindConVar(cvarren);
							if (cvarchk == INVALID_HANDLE)
								maxh = 20;
							else
								maxh = GetConVarInt(cvarchk);
						}
					}
					clsname[0] &= ~(1 << 5);
					float Time = GetTickedTime();
					if ((antispamchk[client] <= Time) && (curh > 0))
					{
						if (StrEqual(clsname,"combine_s",false))
						{
							char cmodel[64];
							GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
							if (StrContains( cmodel, "models/combine_super_soldier.mdl") != -1) //Elite
								Format(clsname,sizeof(clsname),"Combine Elite");
							else if (StrContains( cmodel, "models/combine_soldier_prisonguard.mdl") != -1) //Shotgunner
								Format(clsname,sizeof(clsname),"Combine Prison Guard");
							else
								Format(clsname,sizeof(clsname),"Combine Soldier");
						}
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
	else if (StrEqual(clsname,"antlionworker",false)) Format(clsname,sizeof(clsname),"Antlion Worker");
	else if (StrEqual(clsname,"cscanner",false)) Format(clsname,sizeof(clsname),"City Scanner");
	else if (StrContains(clsname,"_",false) != -1)
	{
		int upper = ReplaceStringEx(clsname,sizeof(clsname),"_"," ");
		if (upper != -1)
			clsname[upper] &= ~(1 << 5);
	}
	if (bclcookie2[client])
		Format(hudbuf,sizeof(hudbuf),"%s (%i HP)",clsname,curh);
	else
	{
		Format(hudbuf,sizeof(hudbuf),"%s (%1.f%%)",clsname,FloatDiv(float(curh),float(maxh))*100);
	}
	if (bclcookie[client] == 0)
	{
		SetHudTextParams(-1.0, 0.55, 0.1, 255, 255, 0, 255, 0, 0.1, 0.0, 0.1);
		ShowHudText(client,0,"%s",hudbuf);
	}
	else if (bclcookie[client] == 1)
	{
		float Time = GetTickedTime();
		antispamchk[client] = Time + 0.5;
		PrintHintText(client,hudbuf);
	}
	else if (bclcookie[client] == 2)
	{
		PrintCenterText(client,hudbuf);
	}
}

public OnClientDisconnect(int client)
{
	antispamchk[client] = 0.0;
	bclcookie[client] = 0;
	bclcookie2[client] = false;
	bclcookie3[client] = false;
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
