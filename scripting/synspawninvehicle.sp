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

#define PLUGIN_VERSION "1.22"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synvehiclespawnupdater.txt"

Handle spawnplayers = INVALID_HANDLE;
bool vehiclemaphook = false;
bool spawninvehicles = true;
bool SetColl = false;
int spawninthisvehicle = -1;
//int collisiongroup = -1;
int WeapList = -1;

public Plugin myinfo =
{
	name = "SynFixesSpawnInVehicle",
	author = "Balimbanana",
	description = "Allows players to all spawn in vehicles if they spawn within a certain distance from them.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	HookEventEx("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	Handle spawninvehiclesh = CreateConVar("sm_spawninvehicles", "1", "Enable spawning players in vehicles, if vehicle spawners are close enough to the spawn point.", _, true, 0.0, true, 1.0);
	spawninvehicles = GetConVarBool(spawninvehiclesh);
	HookConVarChange(spawninvehiclesh, vehiclespawnch);
	CloseHandle(spawninvehiclesh);
	Handle cvar = FindConVar("sm_spawninvehicles_collisionset");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("sm_spawninvehicles_collisionset", "1", "Removes collision between vehicles when spawned in to.", _, true, 0.0, true, 1.0);
	SetColl = GetConVarBool(cvar);
	HookConVarChange(cvar,collsetch);
	CloseHandle(cvar);
	spawnplayers = CreateArray(128);
	RegConsoleCmd("stuck",stuckblck);
}

public void OnMapStart()
{
	//collisiongroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	spawninthisvehicle = -1;
	ClearArray(spawnplayers);
	int jstat = FindEntityByClassname(MaxClients+1,"prop_vehicle_jeep");
	int jspawn = FindEntityByClassname(MaxClients+1,"info_vehicle_spawn");
	int jstatmp = FindEntityByClassname(MaxClients+1,"prop_vehicle_mp");
	if ((jstat != -1) || (jspawn != -1) || (jstatmp != -1))
	{
		vehiclemaphook = true;
		HookEntityOutput("info_vehicle_spawn","OnSpawnVehicle",vehiclespawn);
		HookEntityOutput("prop_vehicle_jeep","PlayerOn",vehicleseatadjust);
	}
	else vehiclemaphook = false;
}

public void OnClientAuthorized(int client, const char[] szAuth)
{
	if ((spawninvehicles) && (vehiclemaphook))
		if (FindValueInArray(spawnplayers,client) == -1)
			PushArrayCell(spawnplayers,client);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if ((spawninvehicles) && (vehiclemaphook))
	{
		int client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (FindValueInArray(spawnplayers,client) == -1)
			PushArrayCell(spawnplayers,client);
		if (IsValidEntity(spawninthisvehicle)) CreateTimer(0.1,waitforlive,client,TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(5.0,removesparr,client,TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action waitforlive(Handle timer, int client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client) && !IsFakeClient(client))
	{
		bool hasweapons = false;
		int ViewEnt = -1;
		if (HasEntProp(client,Prop_Data,"m_hViewEntity")) ViewEnt = GetEntPropEnt(client,Prop_Data,"m_hViewEntity");
		if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
		if (WeapList != -1)
		{
			char clschk[32];
			int curweps = 0;
			bool validweap = false;
			for (int l; l<104; l += 4)
			{
				int tmpi = GetEntDataEnt2(client,WeapList + l);
				if ((tmpi != 0) && (IsValidEntity(tmpi)))
				{
					GetEntityClassname(tmpi,clschk,sizeof(clschk));
					if (strlen(clschk) > 1)
					{
						curweps++;
						if (HasEntProp(client,Prop_Data,"m_hActiveWeapon"))
						{
							if (IsValidEntity(GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon"))) validweap = true;
						}
						else validweap = true;
						if ((curweps > 2) && (validweap))
						{
							hasweapons = true;
							break;
						}
					}
				}
			}
		}
		if ((hasweapons) && (ViewEnt == -1)) CreateTimer(0.5,spawninvehicle,client,TIMER_FLAG_NO_MAPCHANGE);
		else if (IsValidEntity(spawninthisvehicle)) CreateTimer(1.0,waitforlive,client,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if ((IsClientConnected(client)) && (!IsFakeClient(client)))
	{
		CreateTimer(1.0,waitforlive,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action stuckblck(int client, int args)
{
	if (!IsValidEntity(client)) return Plugin_Handled;
	if ((client == 0) || (!IsPlayerAlive(client))) return Plugin_Handled;
	int vckent = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if (vckent != -1)
	{
		SetEntPropEnt(client,Prop_Data,"m_hMoveParent",-1);
		SetEntPropEnt(client,Prop_Data,"m_hParent",-1);
		SetEntPropEnt(client,Prop_Data,"m_pParent",-1);
		SetEntProp(client,Prop_Data,"m_fFlags",257);
		SetEntProp(client,Prop_Data,"m_iEFlags",38011920);
		SetEntProp(client,Prop_Data,"m_MoveType",2);
		SetEntProp(client,Prop_Data,"m_bDrawViewmodel",1);
		SetEntProp(client,Prop_Data,"m_iHideHUD",2048);
		setupvehicle(vckent,client,false);
		int clweap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
		if (clweap != -1)
			if (HasEntProp(clweap,Prop_Data,"m_fEffects")) SetEntProp(clweap,Prop_Data,"m_fEffects",161);
	}
	return Plugin_Continue;
}

public Action removesparr(Handle timer, int client)
{
	int find = FindValueInArray(spawnplayers,client);
	if (find != -1)
		RemoveFromArray(spawnplayers,find);
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
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public void OnEntityDestroyed(int entity)
{
	if ((entity > 0) && (entity < 2048) && (IsValidEntity(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_hPlayer"))
		{
			int cl = GetEntPropEnt(entity,Prop_Data,"m_hPlayer");
			if (IsValidEntity(cl))
			{
				setupvehicle(entity,cl,false);
			}
		}
	}
}

void setupvehicle(int vehicle, int client, bool enterexit)
{
	if ((!enterexit) && (IsValidEntity(vehicle)))
	{
		if (HasEntProp(vehicle,Prop_Data,"m_hPlayer")) SetEntPropEnt(vehicle,Prop_Data,"m_hPlayer",-1);
		if (HasEntProp(vehicle,Prop_Data,"m_hMoveChild")) SetEntPropEnt(vehicle,Prop_Data,"m_hMoveChild",-1);
		if (HasEntProp(vehicle,Prop_Data,"m_bIsOn")) SetEntProp(vehicle,Prop_Data,"m_bIsOn",0);
		if (HasEntProp(vehicle,Prop_Data,"m_iOnlyUser")) SetEntProp(vehicle,Prop_Data,"m_iOnlyUser",-1);
		if (HasEntProp(vehicle,Prop_Data,"bRunningEnterExit")) SetEntProp(vehicle,Prop_Data,"bRunningEnterExit",1);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.throttle")) SetEntPropFloat(vehicle,Prop_Data,"m_controls.throttle",0.0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.steering")) SetEntPropFloat(vehicle,Prop_Data,"m_controls.steering",0.0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.brake")) SetEntPropFloat(vehicle,Prop_Data,"m_controls.brake",0.0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.boost")) SetEntPropFloat(vehicle,Prop_Data,"m_controls.boost",0.0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.handbrake")) SetEntProp(vehicle,Prop_Data,"m_controls.handbrake",1);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.handbrakeLeft")) SetEntProp(vehicle,Prop_Data,"m_controls.handbrakeLeft",0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.handbrakeRight")) SetEntProp(vehicle,Prop_Data,"m_controls.handbrakeRight",0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.brakepedal")) SetEntProp(vehicle,Prop_Data,"m_controls.brakepedal",0);
		if (IsValidEntity(client))
		{
			if (IsClientConnected(client))
			{
				if (IsClientInGame(client))
				{
					if (IsPlayerAlive(client))
					{
						CreateTimer(0.1,resetclvec,client,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
		char vehicletype[32];
		GetEntityClassname(vehicle,vehicletype,sizeof(vehicletype));
		if (StrEqual(vehicletype,"prop_vehicle_airboat"))
		{
			SetEntPropFloat(vehicle,Prop_Data,"m_maxThrottle",1.0);
			SetEntPropFloat(vehicle,Prop_Data,"m_flMaxRevThrottle",-1.0);
		}
	}
	else if ((enterexit) && (IsValidEntity(vehicle)) && (IsValidEntity(client)))
	{
		if (SetColl)
		{
			//if (HasEntProp(vehicle,Prop_Data,"m_CollisionGroup")) SetEntProp(vehicle,Prop_Data,"m_CollisionGroup",5);
			char targn[64];
			char targn2[64];
			if (HasEntProp(vehicle,Prop_Data,"m_iName")) GetEntPropString(vehicle,Prop_Data,"m_iName",targn,sizeof(targn));
			if (strlen(targn) < 1)
			{
				Format(targn,sizeof(targn),"synveh%i",vehicle);
				SetEntPropString(vehicle,Prop_Data,"m_iName",targn);
			}
			for (int i = 1;i<MaxClients+1;i++)
			{
				if ((IsValidEntity(i)) && (i != client))
				{
					if (IsClientConnected(i))
					{
						if (IsClientInGame(i))
						{
							if (IsPlayerAlive(i))
							{
								if (HasEntProp(i,Prop_Data,"m_hVehicle"))
								{
									int clveh = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
									if (IsValidEntity(clveh))
									{
										if (HasEntProp(clveh,Prop_Data,"m_iName")) GetEntPropString(clveh,Prop_Data,"m_iName",targn2,sizeof(targn2));
										if (strlen(targn2) < 1)
										{
											Format(targn2,sizeof(targn2),"synveh%i",clveh);
											SetEntPropString(clveh,Prop_Data,"m_iName",targn2);
										}
										int logcoll = CreateEntityByName("logic_collision_pair");
										if (logcoll != -1)
										{
											DispatchKeyValue(logcoll,"attach1",targn);
											DispatchKeyValue(logcoll,"attach2",targn2);
											DispatchKeyValue(logcoll,"StartDisabled","1");
											DispatchSpawn(logcoll);
											ActivateEntity(logcoll);
											AcceptEntityInput(logcoll,"DisableCollisions");
											Handle dp2 = CreateDataPack();
											WritePackCell(dp2,logcoll);
											WritePackString(dp2,"logic_collision_pair");
											CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
										}
									}
								}
							}
						}
					}
				}
			}
			CreateTimer(2.0,resetcollision,vehicle,TIMER_REPEAT);
		}
		//SetEntData(vehicle,collisiongroup,5,4,true);
		if (HasEntProp(vehicle,Prop_Data,"m_hPlayer")) SetEntPropEnt(vehicle,Prop_Data,"m_hPlayer",client);
		if (HasEntProp(vehicle,Prop_Data,"m_hMoveChild")) SetEntPropEnt(vehicle,Prop_Data,"m_hMoveChild",client);
		if (HasEntProp(vehicle,Prop_Data,"m_bIsOn")) SetEntProp(vehicle,Prop_Data,"m_bIsOn",1);
		if (HasEntProp(vehicle,Prop_Data,"m_iNumberOfEntries")) SetEntProp(vehicle,Prop_Data,"m_iNumberOfEntries",1);
		if (HasEntProp(vehicle,Prop_Data,"m_bSequenceLoops")) SetEntProp(vehicle,Prop_Data,"m_bSequenceLoops",1);
		if (HasEntProp(vehicle,Prop_Data,"bWasRunningAnim")) SetEntProp(vehicle,Prop_Data,"bWasRunningAnim",1);
		if (HasEntProp(vehicle,Prop_Data,"bRunningEnterExit")) SetEntProp(vehicle,Prop_Data,"bRunningEnterExit",0);
		if (HasEntProp(vehicle,Prop_Data,"m_controls.handbrake")) SetEntProp(vehicle,Prop_Data,"m_controls.handbrake",0);
		HookSingleEntityOutput(vehicle,"PlayerOff",exitspawnvehicle,true);
	}
}

public Action cleanup(Handle timer, Handle data)
{
	ResetPack(data);
	int cleanupent = ReadPackCell(data);
	char clsname[32];
	ReadPackString(data,clsname,sizeof(clsname));
	CloseHandle(data);
	if ((IsValidEntity(cleanupent)) && (cleanupent != 0))
	{
		char tmpcls[32];
		GetEntityClassname(cleanupent,tmpcls,sizeof(tmpcls));
		if (StrEqual(tmpcls,clsname,false))
		{
			if (StrEqual(tmpcls,"logic_collision_pair",false)) AcceptEntityInput(cleanupent,"DisableCollisions");
			AcceptEntityInput(cleanupent,"kill");
		}
	}
}

public Action resetclvec(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		if (IsClientConnected(client))
		{
			if (IsClientInGame(client))
			{
				if (IsPlayerAlive(client))
				{
					float resetvec[3];
					SetEntPropVector(client,Prop_Data,"m_vecViewOffset",resetvec);
				}
			}
		}
	}
}

public Action spawninvehicle(Handle timer, int i)
{
	if ((IsValidEntity(spawninthisvehicle)) && (IsValidEntity(i)))
	{
		int team = 0;
		if (HasEntProp(i,Prop_Data,"m_iTeamNum")) team = GetEntProp(i,Prop_Data,"m_iTeamNum");
		if (team != 0) return Plugin_Handled;
		int vehchk = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
		if (vehchk != -1) return Plugin_Handled;
		char clschk[32];
		GetEntityClassname(spawninthisvehicle,clschk,sizeof(clschk));
		if (StrEqual(clschk,"info_vehicle_spawn",false))
		{
			char vehscript[128];
			if (HasEntProp(spawninthisvehicle,Prop_Data,"m_iVehicleScript")) GetEntPropString(spawninthisvehicle,Prop_Data,"m_iVehicleScript",vehscript,sizeof(vehscript));
			char vehmdl[128];
			if (HasEntProp(spawninthisvehicle,Prop_Data,"m_ModelName")) GetEntPropString(spawninthisvehicle,Prop_Data,"m_ModelName",vehmdl,sizeof(vehmdl));
			char vehicletype[32];
			Format(vehicletype,sizeof(vehicletype),"prop_vehicle_jeep");
			if (HasEntProp(spawninthisvehicle,Prop_Data,"m_iVehicleType"))
			{
				int vehtype = GetEntProp(spawninthisvehicle,Prop_Data,"m_iVehicleType");
				switch (vehtype)
				{
					case 1:
						Format(vehicletype,sizeof(vehicletype),"prop_vehicle_jeep");
					case 2:
						Format(vehicletype,sizeof(vehicletype),"prop_vehicle_airboat");
					case 3:
						Format(vehicletype,sizeof(vehicletype),"prop_vehicle_jeep_episodic");
					case 4:
						Format(vehicletype,sizeof(vehicletype),"prop_vehicle_mp");
				}
			}
			if ((StrEqual(vehmdl,"models\\vehicles\\buggy_p2.mdl",false)) && (StrEqual(vehicletype,"prop_vehicle_jeep",false)))
			{
				//Need to set up specifics on spawning in jeep class instead of mp class while using mp models
				int find = FindValueInArray(spawnplayers,i);
				if (find != -1)
					RemoveFromArray(spawnplayers,find);
				return Plugin_Handled;
			}
			float vehicleorg[3];
			float vehicleangs[3];
			if (HasEntProp(spawninthisvehicle,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(spawninthisvehicle,Prop_Data,"m_vecAbsOrigin",vehicleorg);
			else if (HasEntProp(spawninthisvehicle,Prop_Send,"m_vecOrigin")) GetEntPropVector(spawninthisvehicle,Prop_Send,"m_vecOrigin",vehicleorg);
			if (HasEntProp(spawninthisvehicle,Prop_Data,"m_angRotation")) GetEntPropVector(spawninthisvehicle,Prop_Data,"m_angRotation",vehicleangs);
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i))
				{
					if (IsClientInGame(i))
					{
						if (IsPlayerAlive(i))
						{
							int curvchk = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
							if (curvchk == -1)
							{
								float plyorg[3];
								GetClientAbsOrigin(i,plyorg);
								float chkdist = GetVectorDistance(plyorg,vehicleorg);
								if (chkdist < 302.0)
								{
									TeleportEntity(i,vehicleorg,vehicleangs,NULL_VECTOR);
									int vehiclenext = CreateEntityByName(vehicletype);
									if (vehiclenext != -1)
									{
										TeleportEntity(i,vehicleorg,vehicleangs,NULL_VECTOR);
										if (GetEntProp(spawninthisvehicle,Prop_Data,"m_bEnableGun")) DispatchKeyValue(vehiclenext,"EnableGun","1");
										DispatchKeyValue(vehiclenext,"VehicleScript",vehscript);
										DispatchKeyValue(vehiclenext,"model",vehmdl);
										DispatchKeyValue(vehiclenext,"solid","6");
										TeleportEntity(vehiclenext,vehicleorg,vehicleangs,NULL_VECTOR);
										DispatchSpawn(vehiclenext);
										ActivateEntity(vehiclenext);
										SetVariantString("!activator");
										AcceptEntityInput(vehiclenext,"EnterVehicleImmediate",i);
										SetEntPropEnt(i,Prop_Data,"m_hVehicle",vehiclenext);
										SetEntPropEnt(i,Prop_Data,"m_hParent",vehiclenext);
										SetEntPropEnt(i,Prop_Data,"m_pParent",vehiclenext);
										SetEntPropEnt(i,Prop_Data,"m_hMoveParent",vehiclenext);
										SetEntProp(i,Prop_Data,"m_iHideHUD",3328);
										SetEntProp(i,Prop_Data,"m_fFlags",256);
										SetEntProp(i,Prop_Data,"m_iEFlags",38016016);
										SetEntProp(i,Prop_Data,"m_MoveType",8);
										SetEntProp(i,Prop_Data,"m_bDrawViewmodel",0);
										SetEntProp(i,Prop_Data,"m_CollisionGroup",11);
										setupvehicle(vehiclenext,i,true);
										float orgoverride[3];
										if (StrEqual(vehicletype,"prop_vehicle_airboat"))
										{
											orgoverride[0] = -0.08;
											orgoverride[1] = -10.99;
											orgoverride[2] = 34.29;
											SetEntProp(vehiclenext,Prop_Data,"m_iEFlags",9175056);
											SetEntPropFloat(vehiclenext,Prop_Data,"m_maxThrottle",2.3);
											SetEntPropFloat(vehiclenext,Prop_Data,"m_flMaxRevThrottle",-2.0);
										}
										else
										{
											orgoverride[0] = -9.42;
											orgoverride[1] = -39.47;
											orgoverride[2] = 29.76;
										}
										SetEntPropVector(i,Prop_Data,"m_vecOrigin",orgoverride);
										int clweap = GetEntPropEnt(i,Prop_Data,"m_hActiveWeapon");
										if (clweap != -1)
											if (HasEntProp(clweap,Prop_Data,"m_fEffects")) SetEntProp(clweap,Prop_Data,"m_fEffects",161);
										int find = FindValueInArray(spawnplayers,i);
										if (find != -1)
											RemoveFromArray(spawnplayers,find);
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action resetcollision(Handle timer, int vehicle)
{
	if (IsValidEntity(vehicle))
	{
		char cls[32];
		GetEntityClassname(vehicle,cls,sizeof(cls));
		if (StrContains(cls,"vehicle",false) != -1)
		{
			/*
			float vehicleorg[3];
			if (HasEntProp(vehicle,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(vehicle,Prop_Data,"m_vecAbsOrigin",vehicleorg);
			Handle arr = CreateArray(128);
			bool resetcoll = true;
			findcolliding(-1,cls,vehicle,arr);
			if (GetArraySize(arr) > 0)
			{
				for (int i = 0;i<GetArraySize(arr);i++)
				{
					int j = GetArrayCell(arr,i);
					if (IsValidEntity(j))
					{
						float orgs[3];
						if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",orgs);
						float chkdist = GetVectorDistance(orgs,vehicleorg);
						if (chkdist < 150.0)
						{
							resetcoll = false;
						}
					}
				}
			}
			CloseHandle(arr);
			if (resetcoll)
			{
				if (HasEntProp(vehicle,Prop_Data,"m_CollisionGroup"))
				{
					SetEntProp(vehicle,Prop_Data,"m_CollisionGroup",7);
				}
				KillTimer(timer);
			}
			*/
			char targn[64];
			char targn2[64];
			if (HasEntProp(vehicle,Prop_Data,"m_iName")) GetEntPropString(vehicle,Prop_Data,"m_iName",targn,sizeof(targn));
			if (strlen(targn) < 1)
			{
				Format(targn,sizeof(targn),"synveh%i",vehicle);
				SetEntPropString(vehicle,Prop_Data,"m_iName",targn);
			}
			for (int i = 1;i<MaxClients+1;i++)
			{
				if (IsValidEntity(i))
				{
					if (IsClientConnected(i))
					{
						if (IsClientInGame(i))
						{
							if (IsPlayerAlive(i))
							{
								if (HasEntProp(i,Prop_Data,"m_hVehicle"))
								{
									int clveh = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
									if ((IsValidEntity(clveh)) && (clveh != vehicle))
									{
										if (HasEntProp(clveh,Prop_Data,"m_iName")) GetEntPropString(clveh,Prop_Data,"m_iName",targn2,sizeof(targn2));
										if (strlen(targn2) < 1)
										{
											Format(targn2,sizeof(targn2),"synveh%i",clveh);
											SetEntPropString(clveh,Prop_Data,"m_iName",targn2);
										}
										int logcoll = CreateEntityByName("logic_collision_pair");
										if (logcoll != -1)
										{
											DispatchKeyValue(logcoll,"attach1",targn);
											DispatchKeyValue(logcoll,"attach2",targn2);
											DispatchKeyValue(logcoll,"StartDisabled","1");
											DispatchSpawn(logcoll);
											ActivateEntity(logcoll);
											AcceptEntityInput(logcoll,"DisableCollisions");
											Handle dp2 = CreateDataPack();
											WritePackCell(dp2,logcoll);
											WritePackString(dp2,"logic_collision_pair");
											CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
										}
									}
								}
							}
						}
					}
				}
			}
		}
		else KillTimer(timer);
	}
	else KillTimer(timer);
}

void findcolliding(int ent, char[] cls, int vehicle, Handle arr)
{
	int thisent = FindEntityByClassname(ent,cls);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if (thisent != vehicle)
		{
			PushArrayCell(arr,thisent);
		}
		findcolliding(thisent++,cls,vehicle,arr);
	}
	return;
}

public Action vehiclespawn(const char[] output, int caller, int activator, float delay)
{
	if ((spawninvehicles) && (vehiclemaphook))
	{
		if (IsValidEntity(caller))
		{
			char clschk[32];
			GetEntityClassname(caller,clschk,sizeof(clschk));
			if (StrEqual(clschk,"info_vehicle_spawn",false))
			{
				int vehicle = -1;
				char vehscript[128];
				if (HasEntProp(caller,Prop_Data,"m_iVehicleScript")) GetEntPropString(caller,Prop_Data,"m_iVehicleScript",vehscript,sizeof(vehscript));
				char vehmdl[128];
				if (HasEntProp(caller,Prop_Data,"m_ModelName")) GetEntPropString(caller,Prop_Data,"m_ModelName",vehmdl,sizeof(vehmdl));
				char vehicletype[32];
				Format(vehicletype,sizeof(vehicletype),"prop_vehicle_jeep");
				if (HasEntProp(caller,Prop_Data,"m_iVehicleType"))
				{
					int vehtype = GetEntProp(caller,Prop_Data,"m_iVehicleType");
					switch (vehtype)
					{
						case 1:
							Format(vehicletype,sizeof(vehicletype),"prop_vehicle_jeep");
						case 2:
							Format(vehicletype,sizeof(vehicletype),"prop_vehicle_airboat");
						case 3:
							Format(vehicletype,sizeof(vehicletype),"prop_vehicle_jeep_episodic");
						case 4:
							Format(vehicletype,sizeof(vehicletype),"prop_vehicle_mp");
					}
				}
				if ((StrEqual(vehmdl,"models\\vehicles\\buggy_p2.mdl",false)) && (StrEqual(vehicletype,"prop_vehicle_jeep",false)))
				{
					//Need to set up specifics on spawning in jeep class instead of mp class while using mp models
					int find = FindValueInArray(spawnplayers,activator);
					if (find != -1)
						RemoveFromArray(spawnplayers,find);
					return Plugin_Continue;
				}
				float vehicleorg[3];
				float vehicleangs[3];
				if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",vehicleorg);
				else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",vehicleorg);
				if (HasEntProp(caller,Prop_Data,"m_angRotation")) GetEntPropVector(caller,Prop_Data,"m_angRotation",vehicleangs);
				if (HasEntProp(caller,Prop_Data,"pLastVehicleSpawned")) vehicle = GetEntPropEnt(caller,Prop_Data,"pLastVehicleSpawned");
				spawninthisvehicle = caller;
				if ((IsValidEntity(vehicle)) && (vehicle != 0))
				{
					for (int j = 0;j<GetArraySize(spawnplayers);j++)
					{
						int i = GetArrayCell(spawnplayers,j);
						if (IsValidEntity(i))
						{
							if (IsClientConnected(i))
							{
								if (IsClientInGame(i))
								{
									if ((IsPlayerAlive(i)) && (vehicle != -1))
									{
										bool hasweapons = false;
										int ViewEnt = -1;
										if (HasEntProp(i,Prop_Data,"m_hViewEntity")) ViewEnt = GetEntPropEnt(i,Prop_Data,"m_hViewEntity");
										if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
										if (WeapList != -1)
										{
											int curweps = 0;
											bool validweap = false;
											for (int l; l<104; l += 4)
											{
												int tmpi = GetEntDataEnt2(i,WeapList + l);
												if ((tmpi != 0) && (IsValidEntity(tmpi)))
												{
													GetEntityClassname(tmpi,clschk,sizeof(clschk));
													if (strlen(clschk) > 1)
													{
														curweps++;
														if (HasEntProp(i,Prop_Data,"m_hActiveWeapon"))
														{
															if (IsValidEntity(GetEntPropEnt(i,Prop_Data,"m_hActiveWeapon"))) validweap = true;
														}
														else validweap = true;
														if ((curweps > 2) && (validweap))
														{
															hasweapons = true;
															break;
														}
													}
												}
											}
										}
										if ((hasweapons) && (ViewEnt == -1))
										{
											int curvchk = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
											if (curvchk == -1)
											{
												float plyorg[3];
												GetClientAbsOrigin(i,plyorg);
												float chkdist = GetVectorDistance(plyorg,vehicleorg);
												if (chkdist < 302.0)
												{
													ActivateEntity(vehicle);
													TeleportEntity(i,vehicleorg,vehicleangs,NULL_VECTOR);
													SetEntPropEnt(i,Prop_Data,"m_hVehicle",vehicle);
													SetEntPropEnt(i,Prop_Data,"m_hParent",vehicle);
													SetEntPropEnt(i,Prop_Data,"m_pParent",vehicle);
													SetEntPropEnt(i,Prop_Data,"m_hMoveParent",vehicle);
													SetEntProp(i,Prop_Data,"m_iHideHUD",3328);
													SetEntProp(i,Prop_Data,"m_fFlags",256);
													SetEntProp(i,Prop_Data,"m_iEFlags",38016016);
													SetEntProp(i,Prop_Data,"m_MoveType",8);
													SetEntProp(i,Prop_Data,"m_bDrawViewmodel",0);
													SetEntProp(i,Prop_Data,"m_CollisionGroup",11);
													setupvehicle(vehicle,i,true);
													float orgoverride[3];
													if (StrEqual(vehicletype,"prop_vehicle_airboat"))
													{
														orgoverride[0] = -0.08;
														orgoverride[1] = -10.99;
														orgoverride[2] = 34.29;
														SetEntProp(vehicle,Prop_Data,"m_iEFlags",9175056);
														SetEntPropFloat(vehicle,Prop_Data,"m_maxThrottle",2.3);
														SetEntPropFloat(vehicle,Prop_Data,"m_flMaxRevThrottle",-2.0);
													}
													else
													{
														orgoverride[0] = -9.42;
														orgoverride[1] = -39.47;
														orgoverride[2] = 29.76;
													}
													SetEntPropVector(i,Prop_Data,"m_vecOrigin",orgoverride);
													int clweap = GetEntPropEnt(i,Prop_Data,"m_hActiveWeapon");
													if (clweap != -1)
														if (HasEntProp(clweap,Prop_Data,"m_fEffects")) SetEntProp(clweap,Prop_Data,"m_fEffects",161);
													vehicle = -1;
												}
											}
										}
										else if (IsValidEntity(spawninthisvehicle)) CreateTimer(1.0,waitforlive,i,TIMER_FLAG_NO_MAPCHANGE);
									}
									else if (IsPlayerAlive(i))
									{
										int curvchk = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
										float plyorg[3];
										if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorg);
										else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorg);
										float chkdist = GetVectorDistance(plyorg,vehicleorg,false);
										if ((curvchk == -1) && (chkdist < 302.0))
										{
											int vehiclenext = CreateEntityByName(vehicletype);
											if (vehiclenext != -1)
											{
												TeleportEntity(i,vehicleorg,vehicleangs,NULL_VECTOR);
												if (GetEntProp(caller,Prop_Data,"m_bEnableGun")) DispatchKeyValue(vehiclenext,"EnableGun","1");
												DispatchKeyValue(vehiclenext,"VehicleScript",vehscript);
												DispatchKeyValue(vehiclenext,"model",vehmdl);
												DispatchKeyValue(vehiclenext,"solid","6");
												TeleportEntity(vehiclenext,vehicleorg,vehicleangs,NULL_VECTOR);
												DispatchSpawn(vehiclenext);
												ActivateEntity(vehiclenext);
												SetEntPropEnt(i,Prop_Data,"m_hVehicle",vehiclenext);
												SetEntPropEnt(i,Prop_Data,"m_hParent",vehiclenext);
												SetEntPropEnt(i,Prop_Data,"m_pParent",vehiclenext);
												SetEntPropEnt(i,Prop_Data,"m_hMoveParent",vehiclenext);
												SetEntProp(i,Prop_Data,"m_iHideHUD",3328);
												SetEntProp(i,Prop_Data,"m_fFlags",256);
												SetEntProp(i,Prop_Data,"m_iEFlags",38016016);
												SetEntProp(i,Prop_Data,"m_MoveType",8);
												SetEntProp(i,Prop_Data,"m_bDrawViewmodel",0);
												SetEntProp(i,Prop_Data,"m_CollisionGroup",11);
												setupvehicle(vehiclenext,i,true);
												float orgoverride[3];
												if (StrEqual(vehicletype,"prop_vehicle_airboat"))
												{
													orgoverride[0] = -0.08;
													orgoverride[1] = -10.99;
													orgoverride[2] = 34.29;
													SetEntProp(vehiclenext,Prop_Data,"m_iEFlags",9175056);
													SetEntPropFloat(vehiclenext,Prop_Data,"m_maxThrottle",2.3);
													SetEntPropFloat(vehiclenext,Prop_Data,"m_flMaxRevThrottle",-2.0);
												}
												else
												{
													orgoverride[0] = -9.42;
													orgoverride[1] = -39.47;
													orgoverride[2] = 29.76;
												}
												SetEntPropVector(i,Prop_Data,"m_vecOrigin",orgoverride);
												int clweap = GetEntPropEnt(i,Prop_Data,"m_hActiveWeapon");
												if (clweap != -1)
													if (HasEntProp(clweap,Prop_Data,"m_fEffects")) SetEntProp(clweap,Prop_Data,"m_fEffects",161);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action exitspawnvehicle(const char[] output, int caller, int activator, float delay)
{
	if ((IsValidEntity(activator)) && (activator <= MaxClients) && (activator > 0))
	{
		if (IsClientInGame(activator))
		{
			float orgs[3];
			if (HasEntProp(activator,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(activator,Prop_Data,"m_vecAbsOrigin",orgs);
			SetEntPropEnt(activator,Prop_Data,"m_hMoveParent",-1);
			SetEntPropEnt(activator,Prop_Data,"m_hParent",-1);
			SetEntProp(activator,Prop_Data,"m_fFlags",257);
			SetEntProp(activator,Prop_Data,"m_iEFlags",38011920);
			SetEntProp(activator,Prop_Data,"m_MoveType",2);
			SetEntProp(activator,Prop_Data,"m_bDrawViewmodel",1);
			float resetvec[3];
			SetEntPropVector(activator,Prop_Data,"m_vecViewOffset",resetvec);
			TeleportEntity(activator,orgs,NULL_VECTOR,NULL_VECTOR);
		}
	}
}

public Action vehicleseatadjust(const char[] output, int caller, int activator, float delay)
{
	if ((IsValidEntity(caller)) && (IsValidEntity(activator)) && (activator <= MaxClients) && (activator > 0))
	{
		Handle dp = CreateDataPack();
		WritePackCell(dp,caller);
		WritePackCell(dp,activator);
		CreateTimer(2.5,seatadjtimer,dp,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action seatadjtimer(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int vehicle = ReadPackCell(dp);
		int client = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(vehicle)) && (IsValidEntity(client)) && (client <= MaxClients) && (client > 0))
		{
			char mdl[128];
			GetEntPropString(vehicle,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
			//PrintToServer("Enter %i %i %s",vehicle,client,mdl);
			if (StrEqual(mdl,"models/vehicles/combine_apcdrivable.mdl",false))
			{
				float seatadj[3];
				seatadj[0] = 1.0;
				seatadj[1] = -30.5;
				seatadj[2] = 60.0;
				SetEntPropVector(client,Prop_Data,"m_vecOrigin",seatadj);
			}
		}
	}
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	int killed = GetEventInt(event, "entindex_killed");
	if ((killed > 0) && (killed < MaxClients+1))
	{
		if (HasEntProp(killed,Prop_Data,"m_hVehicle"))
		{
			int vehiclechk = GetEntPropEnt(killed,Prop_Data,"m_hVehicle");
			if (vehiclechk != -1)
			{
				char cls[24];
				GetEntityClassname(vehiclechk,cls,sizeof(cls));
				if ((!StrEqual(cls,"prop_vehicle_prisoner_pod",false)) && (StrContains(cls,"choreo",false) == -1))
				{
					//int vehicleowner = -1;
					//if (HasEntProp(vehiclechk,Prop_Data,"m_iOnlyUser")) vehicleowner = GetEntProp(vehiclechk,Prop_Data,"m_iOnlyUser");
					setupvehicle(vehiclechk,killed,false);
					SetEntPropEnt(killed,Prop_Data,"m_hMoveParent",-1);
					SetEntPropEnt(killed,Prop_Data,"m_hParent",-1);
					SetEntPropEnt(killed,Prop_Data,"m_pParent",-1);
					SetEntProp(killed,Prop_Data,"m_iHideHUD",2048);
					int clweap = GetEntPropEnt(killed,Prop_Data,"m_hActiveWeapon");
					if (clweap != -1)
						if (HasEntProp(clweap,Prop_Data,"m_fEffects")) SetEntProp(clweap,Prop_Data,"m_fEffects",161);
					/*
					//m_bRespawnOnOwnerDeath
					bool removeveh = true;
					if (vehicleowner != killed)
					{
						for (int i = 1;i<MaxClients+1;i++)
						{
							if (IsValidEntity(i))
							{
								if (IsClientConnected(i))
								{
									if (IsClientInGame(i))
									{
										if (IsPlayerAlive(i))
										{
											int curveh = GetEntPropEnt(i,Prop_Data,"m_hVehicle");
											if (curveh == vehiclechk)
											{
												removeveh = false;
												break;
											}
										}
									}
								}
							}
						}
					}
					if (removeveh) AcceptEntityInput(vehiclechk,"kill");
					*/
				}
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	int find = FindValueInArray(spawnplayers,client);
	if (find != -1)
		RemoveFromArray(spawnplayers,find);
	if (IsValidEntity(client))
	{
		int vckent = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
		if (vckent != -1)
		{
			setupvehicle(vckent,client,false);
		}
	}
}

int g_LastButtons[128];

public void OnClientDisconnect_Post(int client)
{
	g_LastButtons[client] = 0;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (buttons & IN_SPEED) {
		if (!(g_LastButtons[client] & IN_SPEED)) {
			OnButtonPressBoostchk(client,IN_SPEED);
		}
	}
	g_LastButtons[client] = buttons;
}

public void OnButtonPressBoostchk(int client, int button)
{
	if (IsValidEntity(client))
	{
		if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			if (HasEntProp(client,Prop_Data,"m_hVehicle"))
			{
				int vehicle = GetEntPropEnt(client,Prop_Data,"m_hVehicle");
				if (IsValidEntity(vehicle))
				{
					char cls[32];
					GetEntityClassname(vehicle,cls,sizeof(cls));
					if (StrEqual(cls,"prop_vehicle_mp",false))
					{
						if ((HasEntProp(vehicle,Prop_Data,"m_nBoostTimeLeft")) && (HasEntProp(vehicle,Prop_Data,"m_nSpeed")))
						{
							int boosttime = GetEntProp(vehicle,Prop_Data,"m_nBoostTimeLeft");
							int speedchk = GetEntProp(vehicle,Prop_Data,"m_nSpeed");
							int hasboost = GetEntProp(vehicle,Prop_Data,"m_nHasBoost");
							if ((boosttime == 100) && (hasboost > 0) && (speedchk > 20))
							{
								CreateTimer(0.1,boostveh,vehicle,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
			}
		}
	}
}

public Action boostveh(Handle timer, int vehicle)
{
	if (IsValidEntity(vehicle))
	{
		if (HasEntProp(vehicle,Prop_Data,"m_hPlayer"))
		{
			int plychk = GetEntPropEnt(vehicle,Prop_Data,"m_hPlayer");
			if (IsValidEntity(plychk) && (plychk < MaxClients+1))
			{
				SetEntPropFloat(vehicle,Prop_Data,"m_controls.boost",1.0);
				ChangeEdictState(vehicle);
			}
		}
	}
}

public void vehiclespawnch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		spawninvehicles = true;
	else
		spawninvehicles = false;
}

public void collsetch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
		SetColl = true;
	else
		SetColl = false;
}