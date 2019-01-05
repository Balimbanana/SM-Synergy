#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.61"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/healthdisplayupdater.txt"

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
Handle liarr = INVALID_HANDLE;
Handle globalsarr = INVALID_HANDLE;
bool bugbaitpicked = false;
float antispamchk[MAXPLAYERS+1];

Handle bclcookieh = INVALID_HANDLE;
Handle bclcookie2h = INVALID_HANDLE;
Handle bclcookie3h = INVALID_HANDLE;
Handle bclcookie4h = INVALID_HANDLE;
Handle bclcookie4fh = INVALID_HANDLE;
int bclcookie[MAXPLAYERS+1];
bool bclcookie2[MAXPLAYERS+1];
int bclcookie3[MAXPLAYERS+1];
int bclcookie4[MAXPLAYERS+1][3];
int bclcookie4f[MAXPLAYERS+1][3];

public void OnPluginStart()
{
	airelarr = CreateArray(64);
	htarr = CreateArray(64);
	liarr = CreateArray(64);
	globalsarr = CreateArray(16);
	bclcookieh = RegClientCookie("HealthDisplayType", "HealthDisplay type Settings", CookieAccess_Private);
	bclcookie2h = RegClientCookie("HealthDisplayNum", "HealthDisplay num Settings", CookieAccess_Private);
	bclcookie3h = RegClientCookie("HealthDisplayFriend", "HealthDisplay friend Settings", CookieAccess_Private);
	bclcookie4h = RegClientCookie("HealthDisplayColors", "HealthDisplay color Settings", CookieAccess_Private);
	bclcookie4fh = RegClientCookie("HealthDisplayEnemyColors", "HealthDisplay enemy color Settings", CookieAccess_Private);
	RegConsoleCmd("hpmenu",showinf);
	RegConsoleCmd("hitpointmenu",showinf);
	RegConsoleCmd("sm_healthdisplay",showinf);
	RegConsoleCmd("sm_healthtype",sethealthtype);
	RegConsoleCmd("sm_healthnum",sethealthnum);
	RegConsoleCmd("sm_healthfriendlies",sethealthfriendly);
	RegConsoleCmd("sm_healthcolor",Display_HudSelect);
	RegConsoleCmd("sm_healthfriendcol",Display_HudFriendSelect);
	RegConsoleCmd("sm_healthenemycol",Display_HudEnemySelect);
	CreateTimer(10.0,cleararr,_,TIMER_REPEAT);
	CreateTimer(0.1,ShowTimer,_,TIMER_REPEAT);
}

public void OnMapStart()
{
	ClearArray(airelarr);
	ClearArray(htarr);
	ClearArray(liarr);
	ClearArray(globalsarr);
	bugbaitpicked = false;
	CreateTimer(1.0,reloadclcookies);
	HookEntityOutput("weapon_bugbait", "OnPlayerPickup", EntityOutput:onbugbaitpickup);
}

public OnLibraryAdded(const char[] name)
{
    if (StrEqual(name,"updater",false))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action showinf(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	menu.SetTitle("HealthDisplay Settings");
	menu.AddItem("type","Health Message Type");
	menu.AddItem("friendlies","Health Friendlies Settings");
	menu.AddItem("num","Health Number Settings");
	menu.AddItem("color","Health Message Colors");
	menu.ExitButton = true;
	menu.Display(client, 120);
	if (args != 10)
	{
		PrintToChat(client,"!healthtype <1-4>");
		PrintToChat(client,"Sets the type of message that is displayed for health stats. 4 disables.");
		PrintToChat(client,"!healthfriendlies <0-2>");
		PrintToChat(client,"Sets whether or not to show friendly npc health.");
		PrintToChat(client,"!healthnum <1-2>");
		PrintToChat(client,"Sets the way health is shown, 1 is percent, 2 is hit points.");
		PrintToChat(client,"!healthcolor Shows menu for setting enemy and friendlies colors. Only applies to !healthtype 1");
	}
	return Plugin_Handled;
}

public Action sethealthtype(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (args < 1)
	{
		PrintToChat(client,"Usage: !healthtype <1-4>");
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
		PrintToChat(client,"Usage: !healthfriendlies <0-2>");
		PrintToChat(client,"Sets whether or not to show friendly npc health. 2 shows Friend: name or Enemy: name");
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
			bclcookie3[client] = 0;
			SetClientCookie(client, bclcookie3h, "0");
		}
		else if (numset == 1)
		{
			PrintToChat(client,"Set HealthDisplay to show friendly npcs health.");
			bclcookie3[client] = 1;
			SetClientCookie(client, bclcookie3h, "1");
		}
		else if (numset == 2)
		{
			PrintToChat(client,"Set HealthDisplay to show friendly npcs health with friend: or enemy:.");
			bclcookie3[client] = 2;
			SetClientCookie(client, bclcookie3h, "2");
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
		PrintToChat(client,"Usage: !healthnum <1-2>");
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
			char sValue[32];
			GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie[client] = 0;
				SetClientCookie(client, bclcookieh, "0");
			}
			else
				bclcookie[client] = StringToInt(sValue);
			GetClientCookie(client, bclcookie2h, sValue, sizeof(sValue));
			if (StringToInt(sValue) == 0)
				bclcookie2[client] = false;
			else if (StringToInt(sValue) == 1)
				bclcookie2[client] = true;
			else
			{
				bclcookie2[client] = false;
				SetClientCookie(client, bclcookie2h, "0");
			}
			GetClientCookie(client, bclcookie3h, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie3[client] = 0;
				SetClientCookie(client, bclcookie3h, "0");
			}
			else if (StringToInt(sValue) == 1)
				bclcookie3[client] = 1;
			else if (StringToInt(sValue) == 2)
				bclcookie3[client] = 2;
			GetClientCookie(client, bclcookie4h, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie4[client][0] = 255;
				bclcookie4[client][1] = 255;
				bclcookie4[client][2] = 0;
				SetClientCookie(client, bclcookie4h, "255 255 0");
			}
			else
			{
				char tmpc[3][8];
				ExplodeString(sValue," ",tmpc,3,8);
				bclcookie4[client][0] = StringToInt(tmpc[0]);
				bclcookie4[client][1] = StringToInt(tmpc[1]);
				bclcookie4[client][2] = StringToInt(tmpc[2]);
			}
			GetClientCookie(client, bclcookie4fh, sValue, sizeof(sValue));
			if (strlen(sValue) < 1)
			{
				bclcookie4f[client][0] = 255;
				bclcookie4f[client][1] = 176;
				bclcookie4f[client][2] = 0;
				SetClientCookie(client, bclcookie4fh, "255 176 0");
			}
			else
			{
				char tmpc[3][8];
				ExplodeString(sValue," ",tmpc,3,8);
				bclcookie4f[client][0] = StringToInt(tmpc[0]);
				bclcookie4f[client][1] = StringToInt(tmpc[1]);
				bclcookie4f[client][2] = StringToInt(tmpc[2]);
			}
		}
	}
}

public Action cleararr(Handle timer)
{
	//This is to force recheck of ai relationships as the lowest impact check possible.
	ClearArray(htarr);
	ClearArray(liarr);
	ClearArray(airelarr);
}

public OnClientCookiesCached(int client)
{
	char sValue[32];
	GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie[client] = 0;
		SetClientCookie(client, bclcookieh, "0");
	}
	else
		bclcookie[client] = StringToInt(sValue);
	GetClientCookie(client, bclcookie2h, sValue, sizeof(sValue));
	if (StringToInt(sValue) == 0)
		bclcookie2[client] = false;
	else if (StringToInt(sValue) == 1)
		bclcookie2[client] = true;
	else
	{
		bclcookie2[client] = false;
		SetClientCookie(client, bclcookie2h, "0");
	}
	GetClientCookie(client, bclcookie3h, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie3[client] = 0;
		SetClientCookie(client, bclcookie3h, "0");
	}
	else if (StringToInt(sValue) == 1)
		bclcookie3[client] = 1;
	else if (StringToInt(sValue) == 2)
		bclcookie3[client] = 2;
	GetClientCookie(client, bclcookie4h, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie4[client][0] = 255;
		bclcookie4[client][1] = 255;
		bclcookie4[client][2] = 0;
		SetClientCookie(client, bclcookie4h, "255 255 0");
	}
	else
	{
		char tmpc[3][8];
		ExplodeString(sValue," ",tmpc,3,8);
		//PrintToServer("%s %s %s Original: %s",tmpc[0],tmpc[1],tmpc[2],sValue);
		bclcookie4[client][0] = StringToInt(tmpc[0]);
		bclcookie4[client][1] = StringToInt(tmpc[1]);
		bclcookie4[client][2] = StringToInt(tmpc[2]);
	}
	GetClientCookie(client, bclcookie4fh, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie4f[client][0] = 255;
		bclcookie4f[client][1] = 255;
		bclcookie4f[client][2] = 0;
		SetClientCookie(client, bclcookie4fh, "255 255 0");
	}
	else
	{
		char tmpc[3][8];
		ExplodeString(sValue," ",tmpc,3,8);
		bclcookie4f[client][0] = StringToInt(tmpc[0]);
		bclcookie4f[client][1] = StringToInt(tmpc[1]);
		bclcookie4f[client][2] = StringToInt(tmpc[2]);
	}
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

public bool TraceEntityFilter(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if (StrEqual(clsname,"func_vehicleclip",false))
			return false;
	}
	return true;
}

//public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
public Action ShowTimer(Handle timer)
{
	for (int client = 1;client<MaxClients+1;client++)
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client) && !IsFakeClient(client) && (bclcookie[client] != 3))
			{
				int targ = GetClientAimTarget(client,false);
				if ((targ != -1) && (targ > MaxClients))
				{
					char clsname[32];
					GetEntityClassname(targ,clsname,sizeof(clsname));
					int vck = GetEntProp(client,Prop_Send,"m_hVehicle");
					if ((StrContains(clsname,"clip",false) != -1) || ((StrContains(clsname,"prop_vehicle",false) != -1) && (vck != -1)))
					{
						float PlayerOrigin[3];
						float Location[3];
						float clang[3];
						GetClientEyePosition(client, Location);
						GetClientEyeAngles(client,clang);
						PlayerOrigin[0] = (Location[0] + (60 * Cosine(DegToRad(clang[1]))));
						PlayerOrigin[1] = (Location[1] + (60 * Sine(DegToRad(clang[1]))));
						PlayerOrigin[2] = (Location[2] + 10);
						Location[0] = (PlayerOrigin[0] + (10 * Cosine(DegToRad(clang[1]))));
						Location[1] = (PlayerOrigin[1] + (10 * Sine(DegToRad(clang[1]))));
						Location[2] = (PlayerOrigin[2] + 10);
						if (vck != -1)
						{
							Location[0] = (PlayerOrigin[0] - (10 * Cosine(DegToRad(clang[1]))));
							Location[1] = (PlayerOrigin[1] - (10 * Sine(DegToRad(clang[1]))));
							Location[2] = (PlayerOrigin[2] - 10);
						}
						Handle hhitpos = INVALID_HANDLE;
						TR_TraceRayFilter(Location,clang,MASK_VISIBLE_AND_NPCS,RayType_Infinite,TraceEntityFilter);
						targ = TR_GetEntityIndex(hhitpos);
						CloseHandle(hhitpos);
						if (targ != -1)
							GetEntityClassname(targ,clsname,sizeof(clsname));
					}
					if (targ != -1)
					{
						if (StrEqual(clsname,"generic_actor",false))
						{
							char targn[64];
							if (HasEntProp(targ,Prop_Data,"m_iName"))
							{
								GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
								if (StrContains(targn,"lamar",false) != -1)
									Format(clsname,sizeof(clsname),"npc_lamarr");
							}
						}
						if (HasEntProp(targ,Prop_Data,"m_nRenderMode"))
							if (GetEntProp(targ,Prop_Data,"m_nRenderMode") == 10) targ = -1;
					}
					if ((targ != -1) && ((StrContains(clsname,"npc_",false) != -1) || (StrContains(clsname,"monster_",false) != -1)) && (!StrEqual(clsname,"npc_furniture")) && (!StrEqual(clsname,"npc_bullseye")) && (StrContains(clsname,"grenade",false) == -1) && (StrContains(clsname,"satchel",false) == -1) && (!IsInViewCtrl(client)) || (StrEqual(clsname,"prop_vehicle_apc",false)))
					{
						bool ismonster = false;
						if (!bclcookie3[client])
						{
							if (!GetNPCAlly(clsname))
							{
								int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
								if (StrContains(clsname,"monster_",false) != -1)
								{
									ReplaceString(clsname,sizeof(clsname),"monster_","");
									ismonster = true;
								}
								else ReplaceString(clsname,sizeof(clsname),"npc_","");
								int maxh = 20;
								if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
								{
									maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
									if (StrEqual(clsname,"combine_camera",false))
										maxh = 50;
									else if (StrEqual(clsname,"antlion_grub",false))
										maxh = 1;
									else if (StrEqual(clsname,"combinedropship",false))
										maxh = 100;
									else if (maxh == 0)
									{
										char cvarren[32];
										if (ismonster) Format(cvarren,sizeof(cvarren),"hl1_sk_%s_health",clsname);
										else Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
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
										if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
											Format(clsname,sizeof(clsname),"Combine Elite");
										else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
											Format(clsname,sizeof(clsname),"Combine Shotgunner");
										else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
											Format(clsname,sizeof(clsname),"Combine Guard");
										else
											Format(clsname,sizeof(clsname),"Combine Soldier");
									}
									else if (StrEqual(clsname,"citizen",false))
									{
										char targn[64];
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
										if (StrEqual(cmodel,"models/odessa.mdl",false)) Format(clsname,sizeof(clsname),"Odessa Cubbage");
										else if (StrContains(cmodel,"models/humans/group03m/",false) == 0) Format(clsname,sizeof(clsname),"Rebel Medic");
										else if (StrEqual(targn,"griggs",false)) Format(clsname,sizeof(clsname),"Griggs");
										else if (StrEqual(targn,"sheckley",false)) Format(clsname,sizeof(clsname),"Sheckley");
										else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Refugee");
										else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Rebel");
									}
									else if (StrEqual(clsname,"cscanner",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Claw Scanner");
									}
									else if (StrEqual(clsname,"vortigaunt",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Uriah");
										else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Vortigaunt Slave");
									}
									else if (StrEqual(clsname,"antlion",false))
									{
										char cmodel[64];
										GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
										if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Antlion Worker");
									}
									else if (StrEqual(clsname,"antlionguard",false))
									{
										Format(clsname,sizeof(clsname),"Antlion Guard");
										if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Antlion Guardian");
									}
									else if (StrEqual(clsname,"rollermine",false))
									{
										curh = 1;
										maxh = 1;
									}
									antispamchk[client] = Time + 0.07;
									PrintTheMsg(client,curh,maxh,clsname);
								}
							}
						}
						else if (bclcookie3[client] == 1)
						{
							int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
							if (StrContains(clsname,"monster_",false) != -1)
							{
								ReplaceString(clsname,sizeof(clsname),"monster_","");
								ismonster = true;
							}
							else ReplaceString(clsname,sizeof(clsname),"npc_","");
							int maxh = 20;
							if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
							{
								maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
								if (StrEqual(clsname,"combine_camera",false))
									maxh = 50;
								else if (StrEqual(clsname,"antlion_grub",false))
									maxh = 1;
								else if (StrEqual(clsname,"combinedropship",false))
									maxh = 100;
								else if (maxh == 0)
								{
									char cvarren[32];
									if (ismonster) Format(cvarren,sizeof(cvarren),"hl1_sk_%s_health",clsname);
									else Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
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
									if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
										Format(clsname,sizeof(clsname),"Combine Elite");
									else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
											Format(clsname,sizeof(clsname),"Combine Shotgunner");
									else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
										Format(clsname,sizeof(clsname),"Combine Guard");
									else
										Format(clsname,sizeof(clsname),"Combine Soldier");
								}
								else if (StrEqual(clsname,"citizen",false))
								{
									char targn[64];
									char cmodel[64];
									GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
									if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
									if (StrEqual(cmodel,"models/odessa.mdl",false)) Format(clsname,sizeof(clsname),"Odessa Cubbage");
									else if (StrContains(cmodel,"models/humans/group03m/",false) == 0) Format(clsname,sizeof(clsname),"Rebel Medic");
									else if (StrEqual(targn,"griggs",false)) Format(clsname,sizeof(clsname),"Griggs");
									else if (StrEqual(targn,"sheckley",false)) Format(clsname,sizeof(clsname),"Sheckley");
									else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Refugee");
									else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Rebel");
								}
								else if (StrEqual(clsname,"cscanner",false))
								{
									char cmodel[64];
									GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
									if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Claw Scanner");
								}
								else if (StrEqual(clsname,"vortigaunt",false))
								{
									char cmodel[64];
									GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
									if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Uriah");
									else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Vortigaunt Slave");
								}
								else if (StrEqual(clsname,"antlion",false))
								{
									char cmodel[64];
									GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
									if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Antlion Worker");
								}
								else if (StrEqual(clsname,"antlionguard",false))
								{
									Format(clsname,sizeof(clsname),"Antlion Guard");
									if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Antlion Guardian");
								}
								else if (StrEqual(clsname,"rollermine",false))
								{
									curh = 1;
									maxh = 1;
								}
								antispamchk[client] = Time + 0.07;
								PrintTheMsg(client,curh,maxh,clsname);
							}
						}
						else
						{
							char friendfoe[32];
							Format(friendfoe,sizeof(friendfoe),clsname);
							int curh = GetEntProp(targ,Prop_Data,"m_iHealth");
							if (StrContains(clsname,"monster_",false) != -1)
							{
								ReplaceString(clsname,sizeof(clsname),"monster_","");
								ismonster = true;
							}
							else ReplaceString(clsname,sizeof(clsname),"npc_","");
							int maxh = 20;
							if (HasEntProp(targ,Prop_Data,"m_iMaxHealth"))
							{
								maxh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
								if (StrEqual(clsname,"combine_camera",false))
									maxh = 50;
								else if (StrEqual(clsname,"antlion_grub",false))
									maxh = 1;
								else if (StrEqual(clsname,"combinedropship",false))
									maxh = 100;
								else if (maxh == 0)
								{
									char cvarren[32];
									if (ismonster) Format(cvarren,sizeof(cvarren),"hl1_sk_%s_health",clsname);
									else Format(cvarren,sizeof(cvarren),"sk_%s_health",clsname);
									Handle cvarchk = FindConVar(cvarren);
									if (cvarchk == INVALID_HANDLE)
										maxh = 20;
									else
										maxh = GetConVarInt(cvarchk);
								}
							}
							if (StrEqual(clsname,"rollermine",false))
							{
								curh = 1;
								maxh = 1;
							}
							float Time = GetTickedTime();
							if ((antispamchk[client] <= Time) && (curh > 0))
							{
								antispamchk[client] = Time + 0.07;
								PrintTheMsgf(client,curh,maxh,friendfoe,targ);
							}
						}
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
	else if (StrEqual(clsname,"combinegunship",false)) Format(clsname,sizeof(clsname),"Combine Gunship");
	else if (StrEqual(clsname,"prop_vehicle_apc",false)) Format(clsname,sizeof(clsname),"Combine APC");
	else if (StrEqual(clsname,"npc_fastzombie",false)) Format(clsname,sizeof(clsname),"Fast Zombie");
	else if (StrEqual(clsname,"npc_headcrab_fast",false)) Format(clsname,sizeof(clsname),"Fast Headcrab");
	else if (StrEqual(clsname,"npc_headcrab_poison",false)) Format(clsname,sizeof(clsname),"Poison Headcrab");
	else if (StrEqual(clsname,"npc_headcrab_black",false)) Format(clsname,sizeof(clsname),"Black Headcrab");
	else if (StrEqual(clsname,"npc_poisonzombie",false)) Format(clsname,sizeof(clsname),"Poison Zombie");
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
		float perch = FloatDiv(float(curh),float(maxh))*100;
		if (perch < 1.0)
			perch = 1.0;
		Format(hudbuf,sizeof(hudbuf),"%s (%1.f%%)",clsname,perch);
	}
	if (bclcookie[client] == 0)
	{
		SetHudTextParams(-1.0, 0.55, 0.1, bclcookie4[client][0], bclcookie4[client][1], bclcookie4[client][2], 255, 0, 0.1, 0.0, 0.1);
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

public PrintTheMsgf(int client, int curh, int maxh, char clsname[32], int targ)
{
	bool targetally = false;
	if (StrEqual(clsname,"npc_metropolice",false))
		if (GetCopAlly()) Format(clsname,sizeof(clsname),"Friend: Metropolice");
		else Format(clsname,sizeof(clsname),"Enemy: Metropolice");
	char targn[32];
	if (HasEntProp(targ,Prop_Data,"m_iName"))
	{
		GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
		if (strlen(targn) > 0)
			if (GetNPCAllyTarg(targn))
				targetally = true;
	}
	if ((GetNPCAlly(clsname)) || (targetally))
	{
		if (StrEqual(clsname,"npc_combine_s",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
				Format(clsname,sizeof(clsname),"Friend: Combine Elite");
			else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
				Format(clsname,sizeof(clsname),"Friend: Combine Shotgunner");
			else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
				Format(clsname,sizeof(clsname),"Friend: Combine Guard");
			else
				Format(clsname,sizeof(clsname),"Friend: Combine Soldier");
		}
		else if (StrEqual(targn,"griggs",false)) Format(clsname,sizeof(clsname),"Friend: Griggs");
		else if (StrEqual(targn,"sheckley",false)) Format(clsname,sizeof(clsname),"Friend: Sheckley");
		else if (StrEqual(clsname,"npc_citizen",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/odessa.mdl",false))
				Format(clsname,sizeof(clsname),"Friend: Odessa Cubbage");
			else if (StrContains(cmodel,"models/humans/group03m/",false) == 0)
				Format(clsname,sizeof(clsname),"Friend: Rebel Medic");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Friend: Refugee");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Friend: Rebel");
		}
		else if (StrEqual(clsname,"npc_monk",false)) Format(clsname,sizeof(clsname),"Friend: Father Grigori");
		else if (StrEqual(clsname,"npc_kleiner",false)) Format(clsname,sizeof(clsname),"Friend: Isaac Kleiner");
		else if (StrEqual(clsname,"npc_mossman",false)) Format(clsname,sizeof(clsname),"Friend: Judith Mossman");
		else if (StrEqual(clsname,"npc_magnusson",false)) Format(clsname,sizeof(clsname),"Friend: Arne Magnusson");
		else if (StrEqual(clsname,"npc_breen",false)) Format(clsname,sizeof(clsname),"Friend: Dr Breen");
		else if (StrEqual(clsname,"npc_alyx",false)) Format(clsname,sizeof(clsname),"Friend: Alyx Vance");
		else if (StrEqual(clsname,"npc_eli",false)) Format(clsname,sizeof(clsname),"Friend: Eli Vance");
		else if (StrEqual(clsname,"npc_antlionworker",false)) Format(clsname,sizeof(clsname),"Friend: Antlion Worker");
		else if (StrEqual(clsname,"npc_antlion",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Antlion Worker");
		}
		else if (StrEqual(clsname,"npc_antlionguard",false))
		{
			Format(clsname,sizeof(clsname),"Friend: Antlion Guard");
			if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Friend: Antlion Guardian");
		}
		else if (StrEqual(clsname,"npc_cscanner",false))
		{
			Format(clsname,sizeof(clsname),"Friend: City Scanner");
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Claw Scanner");
		}
		else if (StrEqual(clsname,"npc_vortigaunt",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Uriah");
			else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Friend: Vortigaunt Slave");
		}
		else if (StrEqual(clsname,"npc_combinegunship",false)) Format(clsname,sizeof(clsname),"Friend: Combine Gunship");
		else if (StrEqual(clsname,"prop_vehicle_apc",false)) Format(clsname,sizeof(clsname),"Friend: Combine APC");
		else if (StrEqual(clsname,"npc_gman",false)) Format(clsname,sizeof(clsname),"Government Man");
		else if (StrEqual(clsname,"npc_fastzombie",false)) Format(clsname,sizeof(clsname),"Friend: Fast Zombie");
		else if (StrEqual(clsname,"npc_poisonzombie",false)) Format(clsname,sizeof(clsname),"Friend: Poison Zombie");
		else if (StrEqual(clsname,"npc_headcrab_fast",false)) Format(clsname,sizeof(clsname),"Friend: Fast Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_poison",false)) Format(clsname,sizeof(clsname),"Friend: Poison Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_black",false)) Format(clsname,sizeof(clsname),"Friend: Black Headcrab");
		if (StrContains(clsname,"monster_",false) != -1) ReplaceString(clsname,sizeof(clsname),"monster","Friend: ");
		else ReplaceString(clsname,sizeof(clsname),"npc","Friend: ");
		int upper = ReplaceStringEx(clsname,sizeof(clsname),"_"," ");
		if (upper != -1)
			clsname[upper] &= ~(1 << 5);
	}
	else
	{
		if (StrEqual(clsname,"npc_combine_s",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/combine_super_soldier.mdl",false))
				Format(clsname,sizeof(clsname),"Enemy: Combine Elite");
			else if (GetEntProp(targ,Prop_Data,"m_nSkin") == 1)
				Format(clsname,sizeof(clsname),"Enemy: Combine Shotgunner");
			else if (StrEqual(cmodel,"models/combine_soldier_prisonguard.mdl",false))
				Format(clsname,sizeof(clsname),"Enemy: Combine Guard");
			else
				Format(clsname,sizeof(clsname),"Enemy: Combine Soldier");
		}
		else if (StrEqual(clsname,"npc_citizen",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/odessa.mdl",false))
				Format(clsname,sizeof(clsname),"Enemy: Odessa Cubbage");
			else if (StrContains(cmodel,"models/humans/group03m/",false) == 0)
				Format(clsname,sizeof(clsname),"Enemy: Rebel Medic");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 2) Format(clsname,sizeof(clsname),"Enemy: Refugee");
			else if (GetEntProp(targ,Prop_Data,"m_Type") == 3) Format(clsname,sizeof(clsname),"Enemy: Rebel");
		}
		else if (StrEqual(clsname,"npc_monk",false)) Format(clsname,sizeof(clsname),"Enemy: Father Grigori");
		else if (StrEqual(clsname,"npc_kleiner",false)) Format(clsname,sizeof(clsname),"Enemy: Isaac Kleiner");
		else if (StrEqual(clsname,"npc_mossman",false)) Format(clsname,sizeof(clsname),"Enemy: Judith Mossman");
		else if (StrEqual(clsname,"npc_magnusson",false)) Format(clsname,sizeof(clsname),"Enemy: Arne Magnusson");
		else if (StrEqual(clsname,"npc_breen",false)) Format(clsname,sizeof(clsname),"Enemy: Dr Breen");
		else if (StrEqual(clsname,"npc_alyx",false)) Format(clsname,sizeof(clsname),"Enemy: Alyx Vance");
		else if (StrEqual(clsname,"npc_eli",false)) Format(clsname,sizeof(clsname),"Enemy: Eli Vance");
		else if (StrEqual(clsname,"npc_antlionworker",false)) Format(clsname,sizeof(clsname),"Enemy: Antlion Worker");
		else if (StrEqual(clsname,"npc_antlion",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/antlion_worker.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Antlion Worker");
		}
		else if (StrEqual(clsname,"npc_antlionguard",false))
		{
			Format(clsname,sizeof(clsname),"Enemy: Antlion Guard");
			if (GetEntProp(targ,Prop_Data,"m_bCavernBreed") == 1) Format(clsname,sizeof(clsname),"Enemy: Antlion Guardian");
		}
		else if (StrEqual(clsname,"npc_cscanner",false))
		{
			Format(clsname,sizeof(clsname),"Enemy: City Scanner");
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/shield_scanner.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Claw Scanner");
		}
		else if (StrEqual(clsname,"npc_vortigaunt",false))
		{
			char cmodel[64];
			GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
			if (StrEqual(cmodel,"models/vortigaunt_doctor.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Uriah");
			else if (StrEqual(cmodel,"models/vortigaunt_slave.mdl",false)) Format(clsname,sizeof(clsname),"Enemy: Vortigaunt Slave");
		}
		else if (StrEqual(clsname,"npc_combinegunship",false)) Format(clsname,sizeof(clsname),"Enemy: Combine Gunship");
		else if (StrEqual(clsname,"prop_vehicle_apc",false)) Format(clsname,sizeof(clsname),"Enemy: Combine APC");
		else if (StrEqual(clsname,"npc_gman",false)) Format(clsname,sizeof(clsname),"Government Man");
		else if (StrEqual(clsname,"npc_fastzombie",false)) Format(clsname,sizeof(clsname),"Enemy: Fast Zombie");
		else if (StrEqual(clsname,"npc_poisonzombie",false)) Format(clsname,sizeof(clsname),"Enemy: Poison Zombie");
		else if (StrEqual(clsname,"npc_headcrab_fast",false)) Format(clsname,sizeof(clsname),"Enemy: Fast Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_poison",false)) Format(clsname,sizeof(clsname),"Enemy: Poison Headcrab");
		else if (StrEqual(clsname,"npc_headcrab_black",false)) Format(clsname,sizeof(clsname),"Enemy: Black Headcrab");
		if (StrContains(clsname,"monster_",false) != -1) ReplaceString(clsname,sizeof(clsname),"monster","Enemy: ");
		else ReplaceString(clsname,sizeof(clsname),"npc","Enemy: ");
		int upper = ReplaceStringEx(clsname,sizeof(clsname),"_"," ");
		if (upper != -1)
			clsname[upper] &= ~(1 << 5);
	}
	char hudbuf[32];
	if (StrContains(clsname,"_",false) != -1)
	{
		int upper = ReplaceStringEx(clsname,sizeof(clsname),"_"," ");
		if (upper != -1)
			clsname[upper] &= ~(1 << 5);
	}
	if (bclcookie2[client])
		Format(hudbuf,sizeof(hudbuf),"%s (%i HP)",clsname,curh);
	else
	{
		float perch = FloatDiv(float(curh),float(maxh))*100;
		if (perch < 1.0)
			perch = 1.0;
		Format(hudbuf,sizeof(hudbuf),"%s (%1.f%%)",clsname,perch);
	}
	if (bclcookie[client] == 0)
	{
		if (StrContains(clsname,"enemy",false) != -1)
			SetHudTextParams(-1.0, 0.55, 0.1, bclcookie4[client][0], bclcookie4[client][1], bclcookie4[client][2], 255, 0, 0.1, 0.0, 0.1);
		else
			SetHudTextParams(-1.0, 0.55, 0.1, bclcookie4f[client][0], bclcookie4f[client][1], bclcookie4f[client][2], 255, 0, 0.1, 0.0, 0.1);
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
	bclcookie4[client][0] = 255;
	bclcookie4[client][1] = 255;
	bclcookie4[client][2] = 0;
	bclcookie4f[client][0] = 255;
	bclcookie4f[client][1] = 255;
	bclcookie4f[client][2] = 0;
}

bool GetCopAlly()
{
	if (GetArraySize(globalsarr) > 0)
	{
		for (int i = 0;i<GetArraySize(globalsarr);i++)
		{
			char itmp[32];
			GetArrayString(globalsarr, i, itmp, sizeof(itmp));
			int glo = StringToInt(itmp);
			if (IsValidEntity(glo))
			{
				char state[64];
				GetEntPropString(glo,Prop_Data,"m_iName",state,sizeof(state));
				char state2[64];
				GetEntPropString(glo,Prop_Data,"m_globalstate",state2,sizeof(state2));
				int initstate = GetEntProp(glo,Prop_Data,"m_initialstate");
				if ((StrEqual(state,"global.precriminal",false)) || (StrEqual(state2,"gordon_precriminal",false)))
					if (initstate > 0)
					{
						return true;
					}
			}
		}
	}
	return false;
}

public Action findglobals(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char prevtmp[16];
		Format(prevtmp, sizeof(prevtmp), "%i", thisent);
		if((thisent >= 0) && (FindStringInArray(globalsarr, prevtmp) == -1))
		{
			PushArrayString(globalsarr, prevtmp);
		}
		findglobals(thisent++,clsname);
	}
	return Plugin_Handled;
}

bool GetNPCAllyTarg(char[] clsname)
{
	if (FindStringInArray(liarr,clsname) != -1) return true;
	return false;
}

bool GetNPCAlly(char[] clsname)
{
	if (GetArraySize(airelarr) < 1)
		findairel(MaxClients+1,"ai_relationship");
	if (GetArraySize(htarr) > 0)
	{
		if (FindStringInArray(liarr,clsname) != -1) return true;
		else if (FindStringInArray(htarr,clsname) != -1) return false;
		else return true;
	}
	else
	{
		addht("npc_combine_s");
		addht("npc_metropolice");
		addht("prop_vehicle_apc");
		addht("npc_breen");
		addht("npc_barnacle");
		addht("npc_combine_camera");
		addht("npc_helicopter");
		addht("npc_cscanner");
		addht("npc_rollermine");
		addht("npc_combinegunship");
		addht("npc_combinedropship");
		addht("npc_manhack");
		addht("npc_strider");
		addht("npc_sniper");
		addht("npc_zombie");
		addht("npc_zombie_torso");
		addht("npc_zombine");
		addht("npc_fastzombie");
		addht("npc_poisonzombie");
		addht("npc_headcrab");
		addht("npc_headcrab_poison");
		addht("npc_headcrab_black");
		addht("npc_headcrab_fast");
		addht("npc_gargantua");
		addht("npc_hunter");
		addht("npc_advisor");
		addht("npc_antlion");
		addht("npc_antlionworker");
		addht("npc_antlionguard");
		addht("monster_alien_slave");
		addht("monster_bullchicken");
		addht("monster_headcrab");
		addht("monster_ichthyosaur");
		addht("monster_tentacle");
		addht("monster_sentry");
		addht("monster_houndeye");
		addht("monster_barnacle");
		addht("monster_apache");
		addht("monster_zombie");
		addht("monster_alien_grunt");
		addht("monster_bigmomma");
		addht("monster_babycrab");
		addht("monster_gargantua");
		addht("monster_human_assassin");
		addht("monster_human_grunt");
		addht("monster_miniturret");
		addht("monster_nihilanth");
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
					char targ[32];
					GetEntPropString(rel,Prop_Data,"m_target",targ,sizeof(targ));
					int disp = GetEntProp(rel,Prop_Data,"m_iDisposition");
					int act = GetEntProp(rel,Prop_Data,"m_bIsActive");
					//disp 1 = D_HT // 2 = D_NT // 3 = D_LI // 4 = D_FR
					if ((StrContains(targ,"player",false) != -1) && (disp == 1) && (act != 0))
					{
						addht(subj);
					}
					else if ((StrContains(targ,"player",false) != -1) && (disp == 3) && (act != 0))
					{
						//PrintToServer("Rem %s %i",subj,disp);
						int find = FindStringInArray(htarr,subj);
						if (find != -1)
						{
							RemoveFromArray(htarr,find);
						}
						if (FindStringInArray(liarr,subj) == -1)
							PushArrayString(liarr,subj);
					}
				}
			}
			else
				findairel(MaxClients+1,"ai_relationship");
		}
		if (GetAntAlly())
		{
			int find = FindStringInArray(htarr,"npc_antlion");
			if (find != -1)
				RemoveFromArray(htarr,find);
		}
	}
	if (GetArraySize(htarr) > 0)
	{
		if (FindStringInArray(liarr,clsname) != -1) return true;
		else if (FindStringInArray(htarr,clsname) != -1) return false;
		else return true;
	}
	return true;
}

addht(char[] addht)
{
	if (FindStringInArray(htarr,addht) == -1)
		PushArrayString(htarr,addht);
	int findli = FindStringInArray(liarr,addht);
	if (findli != -1)
		RemoveFromArray(liarr,findli);
}

bool GetAntAlly()
{
	if (bugbaitpicked)
		return true;
	if (GetArraySize(globalsarr) > 0)
	{
		for (int i = 0;i<GetArraySize(globalsarr);i++)
		{
			char itmp[32];
			GetArrayString(globalsarr, i, itmp, sizeof(itmp));
			int glo = StringToInt(itmp);
			if (IsValidEntity(glo))
			{
				char state[64];
				GetEntPropString(glo,Prop_Data,"m_iName",state,sizeof(state));
				char state2[64];
				GetEntPropString(glo,Prop_Data,"m_globalstate",state2,sizeof(state2));
				int offs = FindDataMapInfo(glo, "m_counter");
				int initstate = GetEntData(glo, offs);
				if ((StrEqual(state,"antlions_friendly",false)) || (StrEqual(state2,"antlion_allied",false)))
					if (initstate > 0)
						return true;
			}
		}
	}
	return false;
}

public Action onbugbaitpickup(const char[] output, int caller, int activator, float delay)
{
	bugbaitpicked = true;
	UnhookEntityOutput("weapon_bugbait", "OnPlayerPickup", EntityOutput:onbugbaitpickup);
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
			int act = GetEntProp(thisent,Prop_Data,"m_bIsActive");
			if ((StrContains(subj,"player",false) == -1) && (act != 0))
			{
				PushArrayString(airelarr, prevtmp);
			}
		}
		findairel(thisent++,clsname);
	}
	return Plugin_Handled;
}

public Action Display_HudTypes(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	menu.SetTitle("HealthDisplay Number Settings");
	menu.AddItem("settext","Show as HudText");
	menu.AddItem("sethint","Show as Hint");
	menu.AddItem("setcent","Show as Center Text");
	menu.AddItem("setdisable","Disable HealthDisplay");
	menu.AddItem("backtotop","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudNum(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	menu.SetTitle("HealthDisplay Number Settings");
	menu.AddItem("setperc","Show as percent");
	menu.AddItem("sethp","Show as HP");
	menu.AddItem("backtotop","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudFriendlies(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	Menu menu = new Menu(PanelHandlerDisplayFull);
	menu.SetTitle("HealthDisplay Friendlies Settings");
	menu.AddItem("friend0","Show Only Enemies");
	menu.AddItem("friend1","Show Friends and Enemies");
	menu.AddItem("friend2","Show Enemy: name Friend: name");
	menu.AddItem("backtotop","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudSelect(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (bclcookie[client] != 0)
	{
		PrintToChat(client,"Colors only apply to !healthtype 1");
		return Plugin_Handled;
	}
	if (bclcookie3[client] != 2) PrintToChat(client,"Friendlies colors only applies to !healthfriendlies 2");
	Menu menu = new Menu(PanelHandlerDisplayt);
	menu.SetTitle("HealthDisplay Colors");
	menu.AddItem("friendlies","Friendlies Colors");
	menu.AddItem("enemies","Enemies Colors");
	menu.AddItem("back","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudFriendSelect(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (bclcookie[client] != 0)
	{
		PrintToChat(client,"Colors only apply to !healthtype 1");
		return Plugin_Handled;
	}
	Menu menu = new Menu(PanelHandlerDisplay);
	menu.SetTitle("HealthDisplay Friendlies Color");
	menu.AddItem("ff red","Red");
	menu.AddItem("ff green","Green");
	menu.AddItem("ff blue","Blue");
	menu.AddItem("ff yellow","Yellow");
	menu.AddItem("ff white","White");
	menu.AddItem("ff purple","Purple");
	menu.AddItem("back","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public Action Display_HudEnemySelect(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	if (bclcookie[client] != 0)
	{
		PrintToChat(client,"Colors only apply to !healthtype 1");
		return Plugin_Handled;
	}
	Menu menu = new Menu(PanelHandlerDisplay);
	menu.SetTitle("HealthDisplay Enemy Color");
	menu.AddItem("en red","Red");
	menu.AddItem("en green","Green");
	menu.AddItem("en blue","Blue");
	menu.AddItem("en yellow","Yellow");
	menu.AddItem("en white","White");
	menu.AddItem("en purple","Purple");
	menu.AddItem("back","Back");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

public PanelHandlerDisplayFull(Menu menu, MenuAction action, int param1, int param2)
{
	char info[128];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		if (StrEqual(info,"type",false)) Display_HudTypes(param1,0);
		else if (StrEqual(info,"friendlies",false)) Display_HudFriendlies(param1,0);
		else if (StrEqual(info,"num",false)) Display_HudNum(param1,0);
		else if (StrEqual(info,"color",false)) Display_HudSelect(param1,0);
		else if (StrEqual(info,"setperc",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show percentage.");
			bclcookie2[param1] = false;
			SetClientCookie(param1, bclcookie2h, "0");
			Display_HudNum(param1,0);
		}
		else if (StrEqual(info,"sethp",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show hit points.");
			bclcookie2[param1] = true;
			SetClientCookie(param1, bclcookie2h, "1");
			Display_HudNum(param1,0);
		}
		else if (StrEqual(info,"friend0",false))
		{
			PrintToChat(param1,"Set HealthDisplay to hide friendly npcs health.");
			bclcookie3[param1] = 0;
			SetClientCookie(param1, bclcookie3h, "0");
			Display_HudFriendlies(param1,0);
		}
		else if (StrEqual(info,"friend1",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show friendly npcs health.");
			bclcookie3[param1] = 1;
			SetClientCookie(param1, bclcookie3h, "1");
			Display_HudFriendlies(param1,0);
		}
		else if (StrEqual(info,"friend2",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show friendly npcs health with friend: or enemy:.");
			bclcookie3[param1] = 2;
			SetClientCookie(param1, bclcookie3h, "2");
			Display_HudFriendlies(param1,0);
		}
		else if (StrEqual(info,"settext",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show HudText.");
			bclcookie[param1] = 0;
			SetClientCookie(param1, bclcookieh, "0");
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"sethint",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show Hint.");
			bclcookie[param1] = 1;
			SetClientCookie(param1, bclcookieh, "1");
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"setcent",false))
		{
			PrintToChat(param1,"Set HealthDisplay to show CenterText.");
			bclcookie[param1] = 2;
			SetClientCookie(param1, bclcookieh, "2");
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"setdisable",false))
		{
			PrintToChat(param1,"Disabled HealthDisplay.");
			bclcookie[param1] = 3;
			SetClientCookie(param1, bclcookieh, "3");
			Display_HudTypes(param1,0);
		}
		else if (StrEqual(info,"backtotop",false)) showinf(param1,10);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public PanelHandlerDisplayt(Menu menu, MenuAction action, int param1, int param2)
{
	char info[128];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		if (StrEqual(info,"friendlies",false))
		{
			Display_HudFriendSelect(param1,0);
		}
		else if (StrEqual(info,"enemies",false))
		{
			Display_HudEnemySelect(param1,0);
		}
		else if (StrEqual(info,"back",false))
		{
			showinf(param1,10);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public PanelHandlerDisplay(Menu menu, MenuAction action, int param1, int param2)
{
	char info[128];
	menu.GetItem(param2, info, sizeof(info));
	if (action == MenuAction_Select)
	{
		if (StrEqual(info,"back",false))
			Display_HudSelect(param1,0);
		if (StrEqual(info,"en red",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 0;
			bclcookie4[param1][2] = 0;
			SetClientCookie(param1, bclcookie4h, "255 0 0");
		}
		else if (StrEqual(info,"en green",false))
		{
			bclcookie4[param1][0] = 0;
			bclcookie4[param1][1] = 255;
			bclcookie4[param1][2] = 0;
			SetClientCookie(param1, bclcookie4h, "0 255 0");
		}
		else if (StrEqual(info,"en blue",false))
		{
			bclcookie4[param1][0] = 0;
			bclcookie4[param1][1] = 0;
			bclcookie4[param1][2] = 255;
			SetClientCookie(param1, bclcookie4h, "0 0 255");
		}
		else if (StrEqual(info,"en yellow",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 255;
			bclcookie4[param1][2] = 0;
			SetClientCookie(param1, bclcookie4h, "255 255 0");
		}
		else if (StrEqual(info,"en white",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 255;
			bclcookie4[param1][2] = 255;
			SetClientCookie(param1, bclcookie4h, "255 255 255");
		}
		else if (StrEqual(info,"en purple",false))
		{
			bclcookie4[param1][0] = 255;
			bclcookie4[param1][1] = 0;
			bclcookie4[param1][2] = 255;
			SetClientCookie(param1, bclcookie4h, "255 0 255");
		}
		else if (StrEqual(info,"ff red",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 0;
			bclcookie4f[param1][2] = 0;
			SetClientCookie(param1, bclcookie4fh, "255 0 0");
		}
		else if (StrEqual(info,"ff green",false))
		{
			bclcookie4f[param1][0] = 0;
			bclcookie4f[param1][1] = 255;
			bclcookie4f[param1][2] = 0;
			SetClientCookie(param1, bclcookie4fh, "0 255 0");
		}
		else if (StrEqual(info,"ff blue",false))
		{
			bclcookie4f[param1][0] = 0;
			bclcookie4f[param1][1] = 0;
			bclcookie4f[param1][2] = 255;
			SetClientCookie(param1, bclcookie4fh, "0 0 255");
		}
		else if (StrEqual(info,"ff yellow",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 255;
			bclcookie4f[param1][2] = 0;
			SetClientCookie(param1, bclcookie4fh, "255 255 0");
		}
		else if (StrEqual(info,"ff white",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 255;
			bclcookie4f[param1][2] = 255;
			SetClientCookie(param1, bclcookie4fh, "255 255 255");
		}
		else if (StrEqual(info,"ff purple",false))
		{
			bclcookie4f[param1][0] = 255;
			bclcookie4f[param1][1] = 0;
			bclcookie4f[param1][2] = 255;
			SetClientCookie(param1, bclcookie4fh, "255 0 255");
		}
		if (StrContains(info,"ff ",false) != -1) Display_HudFriendSelect(param1,0);
		else if (StrContains(info,"en ",false) != -1) Display_HudEnemySelect(param1,0);
		else Display_HudSelect(param1,0);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
