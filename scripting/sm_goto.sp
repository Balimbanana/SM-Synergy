#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include "dbi.inc"
#pragma semicolon 1;
#pragma newdecls required;

float gotocd[MAXPLAYERS+1];
//Handle colh = INVALID_HANDLE; //OC checks
Handle bclcookieh = INVALID_HANDLE;
bool bclcookie[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Player-Teleport by Dr. HyperKiLLeR",
	author = "Dr. HyperKiLLeR Edited by Balimbanana for Synergy",
	description = "Go to a player or teleport a player to you",
	version = "1.2.0.2",
	url = ""
};

public void OnPluginStart()
{
	bclcookieh = RegClientCookie("GotoRestrict", "SM_Goto Restrict Settings", CookieAccess_Private);
	//RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY,"Go to a player");
	RegConsoleCmd("sm_goto", Command_Goto);
	RegConsoleCmd("sm_moveto", Command_Goto);
	RegConsoleCmd("sm_nogoto", setnogoto);
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY,"Teleport a player to you");

	CreateConVar("goto_version", "1.2", "Dr. HyperKiLLeRs Player Teleport",FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//colh = FindConVar("mp_playercollide");
}

public void OnMapStart()
{
	CreateTimer(1.0,reloadclcookies);
}

public Action setnogoto(int client, int args)
{
	if (client == 0) return Plugin_Handled;
	int numset;
	if (args < 1)
	{
		if (bclcookie[client]) numset = 0;
		if (!bclcookie[client]) numset = 1;
	}
	else
	{
		char h[4];
		GetCmdArg(1,h,sizeof(h));
		numset = StringToInt(h);
	}
	if (numset == 0)
	{
		PrintToChat(client,"Allowed people to goto you.");
		bclcookie[client] = false;
		SetClientCookie(client, bclcookieh, "");
	}
	else if (numset == 1)
	{
		PrintToChat(client,"Disabled people from going to you.");
		bclcookie[client] = true;
		SetClientCookie(client, bclcookieh, "true");
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
				bclcookie[client] = false;
				SetClientCookie(client, bclcookieh, "");
			}
			else
				bclcookie[client] = true;
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[32];
	GetClientCookie(client, bclcookieh, sValue, sizeof(sValue));
	if (strlen(sValue) < 1)
	{
		bclcookie[client] = false;
		SetClientCookie(client, bclcookieh, "");
	}
	else
		bclcookie[client] = true;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char szCL[4];
		menu.GetItem(param2, szCL, sizeof(szCL));
		int Player = StringToInt(szCL);
		GoToPlayer(param1,Player);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlerBring(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char szCL[4];
		menu.GetItem(param2, szCL, sizeof(szCL));
		int Player = StringToInt(szCL);
		BringPlayer(param1, Player);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action Command_Goto(int Client, int args)
{
	if (!Client) return Plugin_Handled;
	
	if (args < 1)
	{
		if (GetClientCount(true) > 1)
		{
			Menu menu = new Menu(MenuHandler);
			menu.SetTitle("GoTo Player:");
			char indx[4];
			char szName[64];
			for (int i = 1;i<MaxClients+1;i++)
			{
				if (IsValidEntity(i))
				{
					if ((IsClientConnected(i)) && (i != Client))
					{
						Format(indx,sizeof(indx),"%i",i);
						GetClientName(i,szName,sizeof(szName));
						menu.AddItem(indx,szName);
					}
				}
			}
			menu.ExitButton = true;
			menu.Display(Client, 120);
		}
		else
		{
			PrintToConsole(Client, "Usage: sm_goto <name>");
			PrintToChat(Client, "Usage:\x04 sm_goto <name>");
		}
		return Plugin_Handled;
	}
	
	//Declare:
	int Player;
	char PlayerName[64];
	char Name[64];
	
	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	
	//Find:
	for(int X = 1; X <= MaxClients; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if((StrContains(Name, PlayerName, false) != -1) && (X != Client) && (IsClientInGame(X))) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{

		//Print:
		PrintToConsole(Client, "Could not find client \x04%s", PlayerName);

		//Return:
		return Plugin_Handled;
	}
	GoToPlayer(Client,Player);
	
	return Plugin_Handled;
}

void GoToPlayer(int Client, int Player)
{
	if ((IsValidEntity(Client)) && (IsValidEntity(Player)))
	{
		if (IsPlayerAlive(Player))
		{
			int vckcl = GetEntProp(Client, Prop_Send, "m_hVehicle");
			if ((GetEntityRenderFx(Client) == RENDERFX_DISTORT) || (vckcl != -1))
			{
				PrintToChat(Client,"You cannot do that at this time...");
				return;
			}
			
			float Time = GetTickedTime();
			
			if (gotocd[Client] > Time)
			{
				PrintToChat(Client,"You cannot do that for another %i seconds...",RoundToCeil(gotocd[Client]-Time));
				return;
			}
			float TeleportOrigin[3];
			float PlayerOrigin[3];
			char Name[64];
			//Syn checks
			int a = GetEntProp(Client,Prop_Data,"m_iTeamNum");
			int b = GetEntProp(Player,Prop_Data,"m_iTeamNum");
			if (a != b)
			{
				PrintToChat(Client,"Must be on same team.");
				return;
			}
			/* OC checks
			int a = GetClientTeam(Client);
			int b = GetClientTeam(Player);
			if (a != b)
			{
				PrintToChat(Client,"Must be on same team.");
				return;
			}
			*/
			//Initialize
			GetClientName(Player, Name, sizeof(Name));
			GetClientAbsOrigin(Player, PlayerOrigin);
			
			if (bclcookie[Player])
			{
				PrintToChat(Client,"%s has goto disabled.",Name);
				return;
			}
			
			//Math
			float tpang[3];
			GetClientEyeAngles(Player,tpang);
			tpang[2] = 0.0;
			
			TeleportOrigin[0] = PlayerOrigin[0];
			TeleportOrigin[1] = PlayerOrigin[1];
			
			int vck = GetEntProp(Player, Prop_Send, "m_hVehicle");
			int crouching = GetEntProp(Player, Prop_Send, "m_bDucked");
			if (vck != -1)
				TeleportOrigin[2] = (PlayerOrigin[2] + 47.0);
			else if (crouching)
			{
				TeleportOrigin[2] = (PlayerOrigin[2] + 0.1);
				SetEntProp(Client, Prop_Send, "m_bDucking", 1);
			}
			else
				TeleportOrigin[2] = (PlayerOrigin[2] + 3);
			/* OC collision check
			if (GetConVarInt(colh) == 0)
				TeleportOrigin[2] = (PlayerOrigin[2] + 3);
			else
				TeleportOrigin[2] = (PlayerOrigin[2] + 73);
			*/
			
			//Teleport
			TeleportEntity(Client, TeleportOrigin, tpang, NULL_VECTOR);
			gotocd[Client] = Time + 20.0;
			
			if ((HasEntProp(Client, Prop_Data, "m_hCtrl")) && (HasEntProp(Player, Prop_Data, "m_hCtrl")))
			{
				SetEntPropEnt(Client, Prop_Data, "m_hCtrl", GetEntPropEnt(Player, Prop_Data, "m_hCtrl"));
			}
		}
		else
		{
			if (Client == 0) PrintToConsole(Client,"Client %N is not alive.",Player);
			else
			{
				PrintToChat(Client,"Client %N is not alive.",Player);
				PrintToConsole(Client,"Client %N is not alive.",Player);
			}
		}
	}
	return;
}

public Action Command_Bring(int Client, int args)
{
	if (!Client) return Plugin_Handled;
	
	if (args < 1)
	{
		/*
		//Print:
		PrintToConsole(Client, "Usage: sm_bring <name>");
		PrintToChat(Client, "Usage:\x04 sm_bring <name>");

		//Return:
		return Plugin_Handled;
		*/
		
		if (GetClientCount(true) > 1)
		{
			Menu menu = new Menu(MenuHandlerBring);
			menu.SetTitle("Bring Player:");
			char indx[4];
			char szName[64];
			for (int i = 1;i<MaxClients+1;i++)
			{
				if (IsValidEntity(i))
				{
					if ((IsClientConnected(i)) && (i != Client))
					{
						Format(indx,sizeof(indx),"%i",i);
						GetClientName(i,szName,sizeof(szName));
						menu.AddItem(indx,szName);
					}
				}
			}
			menu.ExitButton = true;
			menu.Display(Client, 120);
		}
		else
		{
			PrintToConsole(Client, "Usage: sm_bring <name>");
			PrintToChat(Client, "Usage:\x04 sm_bring <name>");
		}
		return Plugin_Handled;
	}
	
	//Declare:
	int Player;
	char PlayerName[32];
	char Name[32];
	
	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	
	//Find:
	for(int X = 1; X <= MaxClients; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{

		//Print:
		PrintToConsole(Client, "Could not find client \x04%s", PlayerName);

		//Return:
		return Plugin_Handled;
	}
	
	BringPlayer(Client, Player);
	
	return Plugin_Handled;
}

void BringPlayer(int Client, int Player)
{
	if (IsValidEntity(Client) && IsValidEntity(Player))
	{
		if (IsPlayerAlive(Player))
		{
			float TeleportOrigin[3];
			float PlayerOrigin[3];
			
			//Initialize
			GetCollisionPoint(Client, PlayerOrigin);
			
			//Math
			TeleportOrigin[0] = PlayerOrigin[0];
			TeleportOrigin[1] = PlayerOrigin[1];
			TeleportOrigin[2] = (PlayerOrigin[2] + 4);
			
			//Teleport
			TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			if (Client == 0) PrintToConsole(Client,"Client %N is not alive.",Player);
			else
			{
				PrintToChat(Client,"Client %N is not alive.",Player);
				PrintToConsole(Client,"Client %N is not alive.",Player);
			}
		}
	}
	return;
}

// Trace

stock void GetCollisionPoint(int client, float pos[3])
{
	float vOrigin[3];
	float vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
	return;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}  

public void OnClientDisconnect(int client)
{
	gotocd[client] = 0.0;
	bclcookie[client] = false;
}