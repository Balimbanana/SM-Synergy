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
#pragma dynamic 2097152;

#define PLUGIN_VERSION "0.1"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/synportalutilupdater.txt"

int WeapList = -1;
char szMap[64];
bool bMapStarted = false;
bool HasPickedUpPortal2 = false;
bool bReloadNextMap = false;

public Plugin myinfo = 
{
	name = "Syn Portal Utils",
	author = "Balimbanana",
	description = "Synergy Portal fixes and utils",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	RegConsoleCmd("dropweapon",DropPortalGun);
	AddCommandListener(flushcmd,"blckreset");
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
	bReloadNextMap = true;
}

public void OnMapStart()
{
	HookEntityOutput("prop_portal","OnPlacedSuccessfully",PortalPlaced);
	GetCurrentMap(szMap,sizeof(szMap));
	if ((StrContains(szMap,"escape_",false) == 0) || (StrContains(szMap,"testchmb_a_",false) == 0))
	{
		CreateTimer(1.0,TimerCheckPortalPos,_,TIMER_FLAG_NO_MAPCHANGE);
	}
	bMapStarted = true;
	int ent = -1;
	while((ent = FindEntityByClassname(ent,"prop_physics")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			SetupPortalBox(ent);
		}
	}
	if (FileExists("sound/vo/aperture_ai/generic_security_camera_destroyed-1.wav",true,NULL_STRING)) PrecacheSound("vo/aperture_ai/generic_security_camera_destroyed-1.wav",true);
	if (FileExists("sound/vo/aperture_ai/generic_security_camera_destroyed-2.wav",true,NULL_STRING)) PrecacheSound("vo/aperture_ai/generic_security_camera_destroyed-2.wav",true);
	if (FileExists("sound/vo/aperture_ai/generic_security_camera_destroyed-3.wav",true,NULL_STRING)) PrecacheSound("vo/aperture_ai/generic_security_camera_destroyed-3.wav",true);
	if (FileExists("sound/vo/aperture_ai/generic_security_camera_destroyed-4.wav",true,NULL_STRING)) PrecacheSound("vo/aperture_ai/generic_security_camera_destroyed-4.wav",true);
	if (FileExists("sound/vo/aperture_ai/generic_security_camera_destroyed-5.wav",true,NULL_STRING)) PrecacheSound("vo/aperture_ai/generic_security_camera_destroyed-5.wav",true);
}

public Action OnLevelInit(const char[] mapName, char mapEntities[2097152])
{
	bMapStarted = false;
	ReplaceString(mapEntities,sizeof(mapEntities),"\"classname\" \"point_energy_ball_launcher\"","\"classname\" \"point_combine_ball_launcher\"",false);
	ReplaceString(mapEntities,sizeof(mapEntities),"\"OnPostSpawnBall\" ","\"OnUser3\" ",false);
	if (bReloadNextMap)
	{
		bReloadNextMap = false;
		ReloadPlugin(INVALID_HANDLE);
	}
	return Plugin_Changed;
}

public Action TimerCheckPortalPos(Handle timer)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent,"prop_portal")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			if (HasEntProp(ent,Prop_Data,"m_bActivated"))
			{
				if (GetEntProp(ent,Prop_Data,"m_bActivated"))
				{
					float vecOrigin[3];
					float vecCamOrigin[3];
					if (HasEntProp(ent,Prop_Data,"m_vecOrigin")) GetEntPropVector(ent,Prop_Data,"m_vecOrigin",vecOrigin);
					else if (HasEntProp(ent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(ent,Prop_Data,"m_vecAbsOrigin",vecOrigin);
					int cameraent = -1;
					while((cameraent = FindEntityByClassname(cameraent,"npc_security_camera")) != INVALID_ENT_REFERENCE)
					{
						if (IsValidEntity(cameraent))
						{
							if (HasEntProp(cameraent,Prop_Data,"m_bEnabled"))
							{
								if (GetEntProp(cameraent,Prop_Data,"m_bEnabled"))
								{
									if (HasEntProp(cameraent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(cameraent,Prop_Data,"m_vecAbsOrigin",vecCamOrigin);
									else if (HasEntProp(cameraent,Prop_Data,"m_vecOrigin")) GetEntPropVector(cameraent,Prop_Data,"m_vecOrigin",vecCamOrigin);
									if (GetVectorDistance(vecOrigin,vecCamOrigin,false) < 50.0)
									{
										AcceptEntityInput(cameraent,"Ragdoll");
									}
								}
							}
						}
					}
				}
			}
		}
	}
	CreateTimer(0.5,TimerCheckPortalPos,_,TIMER_FLAG_NO_MAPCHANGE);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if ((StrEqual(classname,"prop_physics",false)) && (bMapStarted))
	{
		if (!SDKHookEx(entity,SDKHook_Spawn,SpawnPost)) CreateTimer(0.1,SpawnPostTimer,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(classname,"weapon_portalgun",false))
	{
		SDKHookEx(entity,SDKHook_StartTouch,StartTouchPortalGun);
		HookSingleEntityOutput(entity,"OnPlayerUse",TouchPortalGunOutput);
		HookSingleEntityOutput(entity,"OnPlayerPickup",TouchPortalGunOutput);
	}
	else if (StrEqual(classname,"prop_combine_ball",false))
	{
		CreateTimer(0.1,SpawnPostCombineBallTimer,entity,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void SpawnPost(int entity)
{
	SDKUnhook(entity,SDKHook_Spawn,SpawnPost);
	SetupPortalBox(entity);
}

public Action SpawnPostTimer(Handle timer, int entity)
{
	SetupPortalBox(entity);
}

void SetupPortalBox(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_ModelName"))
		{
			char szModel[64];
			GetEntPropString(entity,Prop_Data,"m_ModelName",szModel,sizeof(szModel));
			if (StrEqual(szModel,"models/props/metal_box.mdl",false))
			{
				if (HasEntProp(entity,Prop_Data,"m_iszOverrideScript"))
				{
					char szOverrideScr[32];
					GetEntPropString(entity,Prop_Data,"m_iszOverrideScript",szOverrideScr,sizeof(szOverrideScr));
					if (StrContains(szOverrideScr,"mass",false) == -1)
					{
						float vecOrigin[3], vecAngles[3];
						char szSF[8], szSkin[4], szBody[4], szName[128];
						if (HasEntProp(entity,Prop_Data,"m_vecOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecOrigin",vecOrigin);
						else if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",vecOrigin);
						if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",vecAngles);
						else if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",vecAngles);
						if (HasEntProp(entity,Prop_Data,"m_nSkin")) Format(szSkin,sizeof(szSkin),"%i",GetEntProp(entity,Prop_Data,"m_nSkin"));
						if (HasEntProp(entity,Prop_Data,"m_nBody")) Format(szBody,sizeof(szBody),"%i",GetEntProp(entity,Prop_Data,"m_nBody"));
						if (HasEntProp(entity,Prop_Data,"m_spawnflags")) Format(szSF,sizeof(szSF),"%i",GetEntProp(entity,Prop_Data,"m_spawnflags"));
						if (HasEntProp(entity,Prop_Data,"m_iName")) GetEntPropString(entity,Prop_Data,"m_iName",szName,sizeof(szName));
						int iRemake = CreateEntityByName("prop_physics");
						if (IsValidEntity(iRemake))
						{
							AcceptEntityInput(entity,"kill");
							DispatchKeyValue(iRemake,"OverrideScript","mass,35");
							DispatchKeyValue(iRemake,"model",szModel);
							DispatchKeyValue(iRemake,"spawnflags",szSF);
							DispatchKeyValue(iRemake,"skin",szSkin);
							DispatchKeyValue(iRemake,"body",szBody);
							DispatchKeyValue(iRemake,"targetname",szName);
							TeleportEntity(iRemake,vecOrigin,vecAngles,NULL_VECTOR);
							DispatchSpawn(iRemake);
							ActivateEntity(iRemake);
						}
					}
				}
			}
		}
	}
}

public Action SpawnPostCombineBallTimer(Handle timer, int entity)
{
	SetupCombineBall(entity);
}

void SetupCombineBall(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hSpawner"))
		{
			int hSpawner = GetEntPropEnt(entity,Prop_Data,"m_hSpawner");
			if (IsValidEntity(hSpawner))
			{
				AcceptEntityInput(hSpawner,"FireUser3");
				SetEntProp(entity,Prop_Data,"m_nMaxBounces",5);
			}
		}
	}
}

public void PortalPlaced(const char[] output, int caller, int activator, float delay)
{
	// Activator is portalgun
	if ((IsValidEntity(activator)) && (IsValidEntity(caller)))
	{
		// Do not check placed portal 2s
		if (HasEntProp(caller,Prop_Data,"m_bIsPortal2"))
		{
			if (GetEntProp(caller,Prop_Data,"m_bIsPortal2")) return;
			if ((HasEntProp(activator,Prop_Data,"m_hOwner")) && (HasEntProp(activator,Prop_Data,"m_bCanFirePortal2")))
			{
				// Only apply to portalguns that cannot fire portal 2
				if (!GetEntProp(activator,Prop_Data,"m_bCanFirePortal2"))
				{
					int client = GetEntPropEnt(activator,Prop_Data,"m_hOwner");
					if ((IsValidEntity(client)) && (client > 0) && (client < MaxClients+1))
					{
						int ent = -1;
						while((ent = FindEntityByClassname(ent,"prop_portal")) != INVALID_ENT_REFERENCE)
						{
							if (IsValidEntity(ent))
							{
								if (ent != caller)
								{
									if (HasEntProp(ent,Prop_Data,"m_bActivated"))
									{
										if (GetEntProp(ent,Prop_Data,"m_bActivated"))
										{
											if (GetEntProp(ent,Prop_Data,"m_bIsPortal2"))
											{
												if ((HasEntProp(ent,Prop_Data,"m_iLinkageGroupID")) && (HasEntProp(ent,Prop_Data,"m_hLinkedPortal")))
												{
													if ((GetEntPropEnt(ent,Prop_Data,"m_hLinkedPortal") == -1) && (!GetEntProp(ent,Prop_Data,"m_iLinkageGroupID")))
													{
														SetEntPropEnt(ent,Prop_Data,"m_hLinkedPortal",caller);
														SetEntPropEnt(caller,Prop_Data,"m_hLinkedPortal",ent);
														//SetEntProp(caller,Prop_Data,"m_iLinkageGroupID",0);
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
		}
	}
	return;
}

public void OnClientConnected(int client)
{
	// Fixes some crashes when first rendering portals
	ClientCommand(client,"mat_queue_mode 0");
}

public Action flushcmd(int client, const char[] command, int argc)
{
	Handle cvar = FindConVar("sv_cheats");
	if (cvar != INVALID_HANDLE)
	{
		if (GetConVarInt(cvar) < 1)
			SendConVarValue(client,cvar,"0");
	}
	CloseHandle(cvar);
	return Plugin_Handled;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if ((client > 0) && (client < MaxClients+1))
	{
		Handle cvar = FindConVar("sv_cheats");
		if (cvar != INVALID_HANDLE)
		{
			if (GetConVarInt(cvar) < 1)
				SendConVarValue(client,cvar,"1");
		}
		CloseHandle(cvar);
		// Fixes a lot of particle effects
		ClientCommand(client,"reload_particleseffects_client");
		ClientCommand(client,"blckreset");
		CreateTimer(0.1,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	int killed = GetEventInt(event, "entindex_killed");
	if (IsValidEntity(killed))
	{
		if ((killed > 0) && (killed < MaxClients+1))
		{
			if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
			if (WeapList != -1)
			{
				char clschk[32];
				for (int l; l<104; l += 4)
				{
					int tmpi = GetEntDataEnt2(killed,WeapList + l);
					if ((tmpi != 0) && (IsValidEntity(tmpi)))
					{
						GetEntityClassname(tmpi,clschk,sizeof(clschk));
						if (StrEqual(clschk,"weapon_portalgun",false))
						{
							SetEntProp(tmpi,Prop_Data,"m_fEffects",129);
							break;
						}
					}
				}
			}
		}
	}
}

public Action clspawnpost(Handle timer, int client)
{
	if (IsValidEntity(client) && IsPlayerAlive(client))
	{
		SDKHookEx(client, SDKHook_WeaponSwitch, OnWeaponUse);
	}
	else if (IsClientConnected(client))
	{
		CreateTimer(0.5,clspawnpost,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnWeaponUse(int client, int weapon)
{
	if ((IsValidEntity(client)) && (IsValidEntity(weapon)))
	{
		char szCls[32];
		GetEntPropString(weapon,Prop_Data,"m_iClassname",szCls,sizeof(szCls));
		if (StrEqual(szCls,"weapon_portalgun",false))
		{
			// Fixes weapon holding position
			SetVariantString("anim_attachment_RH");
			AcceptEntityInput(weapon,"SetParentAttachment");
			SetEntProp(weapon,Prop_Data,"m_fEffects",16);
			float vecOffs[3];
			vecOffs[0] = -5.0;
			SetEntPropVector(weapon,Prop_Data,"m_vecOrigin",vecOffs);
			vecOffs[0] = 0.0;
			vecOffs[1] = 180.0;
			SetEntPropVector(weapon,Prop_Data,"m_angRotation",vecOffs);
			
			if (HasEntProp(weapon,Prop_Data,"m_bCanFirePortal1"))
			{
				// Need to ensure can fire portal 2 when on later levels, and not be able to on early levels
				if ((HasPickedUpPortal2) || (StrEqual(szMap,"testchmb_a_08",false)) || (StrEqual(szMap,"testchmb_a_09",false)) || (StrContains(szMap,"testchmb_a_1",false) == 0))
				{
					SetEntProp(weapon,Prop_Data,"m_bCanFirePortal1",1);
					SetEntProp(weapon,Prop_Data,"m_bCanFirePortal2",1);
				}
				else
				{
					SetEntProp(weapon,Prop_Data,"m_bCanFirePortal1",1);
					SetEntProp(weapon,Prop_Data,"m_bCanFirePortal2",0);
				}
			}
		}
	}
}

public Action DropPortalGun(int client, int args)
{
	if (IsValidEntity(client))
	{
		if (HasEntProp(client,Prop_Data,"m_hActiveWeapon"))
		{
			int ent = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(ent))
			{
				char szCls[32];
				GetEntPropString(ent,Prop_Data,"m_iClassname",szCls,sizeof(szCls));
				if (StrEqual(szCls,"weapon_portalgun",false))
				{
					SetEntProp(ent,Prop_Data,"m_fEffects",129);
				}
			}
		}
	}
	return Plugin_Continue;
}

public void TouchPortalGunOutput(const char[] output, int caller, int activator, float delay)
{
	if ((IsValidEntity(caller)) && (activator > 0) && (activator < MaxClients+1))
	{
		UnhookSingleEntityOutput(caller,output,TouchPortalGunOutput);
		CheckTouchPortalgun(caller,activator);
	}
}

public Action StartTouchPortalGun(int entity, int other)
{
	if (IsValidEntity(entity))
	{
		if ((other < MaxClients+1) && (other > 0))
		{
			UnhookSingleEntityOutput(entity,"OnPlayerUse",TouchPortalGunOutput);
			UnhookSingleEntityOutput(entity,"OnPlayerPickup",TouchPortalGunOutput);
			SDKUnhook(entity,SDKHook_StartTouch,StartTouchPortalGun);
			CheckTouchPortalgun(entity,other);
		}
	}
}

void CheckTouchPortalgun(int entity, int client)
{
	if ((IsValidEntity(entity)) && (IsValidEntity(client)))
	{
		if (HasEntProp(entity,Prop_Data,"m_bCanFirePortal1"))
		{
			// Fixes issue of picking up the second portal gun upgrade which can fire portal 2 but cannot fire 1
			if (GetEntProp(entity,Prop_Data,"m_bCanFirePortal2"))
			{
				if (!GetEntProp(entity,Prop_Data,"m_bCanFirePortal1")) SetEntProp(entity,Prop_Data,"m_bCanFirePortal1",1);
				HasPickedUpPortal2 = true;
				int ent = -1;
				while((ent = FindEntityByClassname(ent,"weapon_portalgun")) != INVALID_ENT_REFERENCE)
				{
					if (IsValidEntity(ent))
					{
						if (HasEntProp(ent,Prop_Data,"m_bCanFirePortal2"))
						{
							SetEntProp(ent,Prop_Data,"m_bCanFirePortal2",1);
						}
					}
				}
			}
			if (WeapList == -1) WeapList = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
			if (WeapList != -1)
			{
				char clschk[32];
				for (int l; l<104; l += 4)
				{
					int tmpi = GetEntDataEnt2(client,WeapList + l);
					if ((tmpi != 0) && (IsValidEntity(tmpi)) && (tmpi != entity))
					{
						GetEntityClassname(tmpi,clschk,sizeof(clschk));
						if (StrEqual(clschk,"weapon_portalgun",false))
						{
							// Remove currently equipped portal gun so the one being picked up fires its OnPlayerPickup outputs
							AcceptEntityInput(tmpi,"kill");
							break;
						}
					}
				}
			}
		}
	}
}