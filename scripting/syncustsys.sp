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

#define PLUGIN_VERSION "0.2"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/syncustsys.txt"

bool HeavyCrowbar = false;
bool DoubleDamage = false;
bool RapidFire = false;
bool PistolExplosions = false;
bool HealthRegen = false;
int HealthRegenStep = 1;
float HeavyCrowbarScale = 900.0; //default crowbar dmg 10 up to 9000
float centnextatk[2048];
char pistolexpldmg[16] = "40";
Handle thinkingents = INVALID_HANDLE;
bool CLHasProperty[128][5];

public Plugin myinfo =
{
	name = "SynCustomSystems",
	author = "Balimbanana",
	description = "Allows things like pistol explosions, double damage, rapid fire, heavy crowbar.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public void OnPluginStart()
{
	thinkingents = CreateArray(2048);
	Handle cvar = FindConVar("syn_heavycrowbar");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_heavycrowbar", "0", "Allow heavy crowbar.", _, true, 0.0, true, 1.0);
	HookConVarChange(cvar, heavycrowbch);
	HeavyCrowbar = GetConVarBool(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("syn_heavycrowbar_scale");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_heavycrowbar_scale", "900.0", "Multiply crowbar damage by this amount.", _, true, 1.0, false);
	HookConVarChange(cvar, heavycrowbscalech);
	HeavyCrowbarScale = GetConVarFloat(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("syn_doubledamage");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_doubledamage", "0", "Allow double damage.", _, true, 0.0, true, 1.0);
	HookConVarChange(cvar, doubledamagech);
	DoubleDamage = GetConVarBool(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("syn_rapidfire");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_rapidfire", "0", "Allow rapid fire.", _, true, 0.0, true, 1.0);
	HookConVarChange(cvar, rapidfirech);
	RapidFire = GetConVarBool(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("syn_pistolexplosions");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_pistolexplosions", "0", "Allow pistol explosions.", _, true, 0.0, true, 1.0);
	HookConVarChange(cvar, pistolexplosionsch);
	PistolExplosions = GetConVarBool(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("syn_pistolexplosions_damage");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_pistolexplosions_damage", "40", "Pistol explosions damage.", _, true, 0.0, false);
	HookConVarChange(cvar, pistolexplosionsdmgch);
	GetConVarString(cvar,pistolexpldmg,sizeof(pistolexpldmg));
	CloseHandle(cvar);
	cvar = FindConVar("syn_healthregen");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_healthregen", "0", "Allow health regen.", _, true, 0.0, true, 1.0);
	HookConVarChange(cvar, healthregench);
	HealthRegen = GetConVarBool(cvar);
	CloseHandle(cvar);
	cvar = FindConVar("syn_healthregen_step");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("syn_healthregen_step", "1", "Sets how much health regen heals per second.", _, true, 0.0, false);
	HookConVarChange(cvar, healthregenstepch);
	HealthRegenStep = GetConVarInt(cvar);
	CloseHandle(cvar);
	RegAdminCmd("syn_adminproperty",ApplyProperty,ADMFLAG_ROOT,".");
	CreateTimer(1.0,ReHookNPCS,_,TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0,HealthRegenTicks,_,TIMER_REPEAT);
}

public void OnMapStart()
{
	ClearArray(thinkingents);
	for (int i = 0;i<2048;i++)
	{
		centnextatk[i] = 0.0;
	}
	for (int i = 0;i<128;i++)
	{
		CLHasProperty[i][0] = false;
		CLHasProperty[i][1] = false;
		CLHasProperty[i][2] = false;
		CLHasProperty[i][3] = false;
		CLHasProperty[i][4] = false;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name,"updater",false))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnEntityDestroyed(int entity)
{
	if ((entity > 0) && (entity < 2048))
	{
		centnextatk[entity] = 0.0;
		int find = FindValueInArray(thinkingents,entity);
		if (find != -1) RemoveFromArray(thinkingents,find);
	}
}

public void OnGameFrame()
{
	if (GetArraySize(thinkingents) > 0)
	{
		for (int i = 0;i<GetArraySize(thinkingents);i++)
		{
			int entity = GetArrayCell(thinkingents,i);
			if (IsValidEntity(entity))
			{
				char cls[32];
				GetEntityClassname(entity,cls,sizeof(cls));
				if (StrEqual(cls,"env_explosion",false))
				{
					if (GetGameTime() >= centnextatk[entity])
					{
						AcceptEntityInput(entity,"Explode");
						AcceptEntityInput(entity,"kill");
					}
				}
				else if (StrEqual(cls,"weapon_pistol",false))
				{
					if (centnextatk[entity] > GetGameTime())
					{
						SetEntPropFloat(entity,Prop_Data,"m_flNextPrimaryAttack",centnextatk[entity]);
						if (HasEntProp(entity,Prop_Send,"m_flSoonestPrimaryAttack")) SetEntPropFloat(entity,Prop_Send,"m_flSoonestPrimaryAttack",centnextatk[entity]);
					}
				}
			}
		}
	}
}

public int Updater_OnPluginUpdated()
{
	Handle nullpl = INVALID_HANDLE;
	ReloadPlugin(nullpl);
}

public Action ApplyProperty(int client, int args)
{
	if (args < 2)
	{
		PrintToConsole(client,"Syntax: syn_adminproperty <client> <property>");
		return Plugin_Handled;
	}
	else
	{
		char name[64];
		GetCmdArg(1,name,sizeof(name));
		char type[32];
		GetCmdArg(2,type,sizeof(type));
		int targ = -1;
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientConnected(i))
				{
					if (IsClientInGame(i))
					{
						char clname[64];
						GetClientName(i,clname,sizeof(clname));
						if (StrContains(clname,name,false) != -1)
						{
							targ = i;
							break;
						}
					}
				}
			}
		}
		if (targ == -1)
		{
			PrintToConsole(client,"Unable to find client %s",name);
			return Plugin_Handled;
		}
		bool setval = false;
		if (args > 2)
		{
			char h[4];
			GetCmdArg(3,h,sizeof(h));
			if (StringToInt(h) < 1) setval = false;
			else setval = true;
		}
		if (StrContains(type,"Crowbar",false) != -1)
		{
			if (args > 2)
			{
				CLHasProperty[targ][0] = setval;
				PrintToConsole(client,"Set %N HeavyCrowbar to %i",targ,CLHasProperty[targ][0]);
			}
			else
			{
				if (CLHasProperty[targ][0])
				{
					CLHasProperty[targ][0] = false;
				}
				else
				{
					CLHasProperty[targ][0] = true;
				}
				PrintToConsole(client,"Set %N HeavyCrowbar to %i",targ,CLHasProperty[targ][0]);
			}
		}
		else if (StrContains(type,"Double",false) != -1)
		{
			if (args > 2)
			{
				CLHasProperty[targ][1] = setval;
				PrintToConsole(client,"Set %N DoubleDamage to %i",targ,CLHasProperty[targ][1]);
			}
			else
			{
				if (CLHasProperty[targ][1])
				{
					CLHasProperty[targ][1] = false;
				}
				else
				{
					CLHasProperty[targ][1] = true;
				}
				PrintToConsole(client,"Set %N DoubleDamage to %i",targ,CLHasProperty[targ][1]);
			}
		}
		else if (StrContains(type,"Rapid",false) != -1)
		{
			if (args > 2)
			{
				CLHasProperty[targ][2] = setval;
				PrintToConsole(client,"Set %N RapidFire to %i",targ,CLHasProperty[targ][2]);
			}
			else
			{
				if (CLHasProperty[targ][2])
				{
					CLHasProperty[targ][2] = false;
				}
				else
				{
					CLHasProperty[targ][2] = true;
				}
				PrintToConsole(client,"Set %N RapidFire to %i",targ,CLHasProperty[targ][2]);
			}
		}
		else if (StrContains(type,"Pistol",false) != -1)
		{
			if (args > 2)
			{
				CLHasProperty[targ][3] = setval;
				PrintToConsole(client,"Set %N Pistol Explosions to %i",targ,CLHasProperty[targ][3]);
			}
			else
			{
				if (CLHasProperty[targ][3])
				{
					CLHasProperty[targ][3] = false;
				}
				else
				{
					CLHasProperty[targ][3] = true;
				}
				PrintToConsole(client,"Set %N Pistol Explosions to %i",targ,CLHasProperty[targ][3]);
			}
		}
		else if (StrContains(type,"Regen",false) != -1)
		{
			if (args > 2)
			{
				CLHasProperty[targ][4] = setval;
				PrintToConsole(client,"Set %N HealthRegen to %i",targ,CLHasProperty[targ][4]);
			}
			else
			{
				if (CLHasProperty[targ][4])
				{
					CLHasProperty[targ][4] = false;
				}
				else
				{
					CLHasProperty[targ][4] = true;
				}
				PrintToConsole(client,"Set %N HealthRegen to %i",targ,CLHasProperty[targ][4]);
			}
		}
	}
	return Plugin_Handled;
}

public Action ReHookNPCS(Handle timer)
{
	for (int i = MaxClients+1;i<2048;i++)
	{
		if (IsValidEntity(i))
		{
			char classname[32];
			GetEntityClassname(i,classname,sizeof(classname));
			if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false)) || (StrEqual(classname,"prop_physics",false)) || (StrEqual(classname,"func_breakable",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)))
			{
				SDKHook(i,SDKHook_OnTakeDamage,TakeDamageNPCS);
			}
		}
	}
}

public Action HealthRegenTicks(Handle timer)
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
						if ((CLHasProperty[i][4]) || (HealthRegen))
						{
							int maxh = GetEntProp(i,Prop_Data,"m_iMaxHealth");
							int curh = GetEntProp(i,Prop_Data,"m_iHealth");
							if (curh+HealthRegenStep < maxh)
							{
								SetEntProp(i,Prop_Data,"m_iHealth",curh+HealthRegenStep);
							}
							else
							{
								SetEntProp(i,Prop_Data,"m_iHealth",maxh);
							}
						}
					}
				}
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (((StrContains(classname,"npc_",false) != -1) || (StrContains(classname,"monster_",false) != -1) || (StrEqual(classname,"generic_actor",false)) || (StrEqual(classname,"generic_monster",false)) || (StrEqual(classname,"prop_physics",false)) || (StrEqual(classname,"func_breakable",false))) && (!StrEqual(classname,"npc_enemyfinder_combinecannon",false)) && (!StrEqual(classname,"npc_bullseye",false)) && (!StrEqual(classname,"npc_maker",false)) && (!StrEqual(classname,"npc_template_maker",false)))
	{
		SDKHook(entity,SDKHook_OnTakeDamage,TakeDamageNPCS);
	}
}

public Action TakeDamageNPCS(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ((attacker > 0) && (attacker < MaxClients+1) && (IsValidEntity(attacker)) && (damage > 0.1))
	{
		if (((HeavyCrowbar) || (CLHasProperty[attacker][0])) && (HasEntProp(attacker,Prop_Data,"m_hActiveWeapon")))
		{
			int curweap = GetEntPropEnt(attacker,Prop_Data,"m_hActiveWeapon");
			if (IsValidEntity(curweap))
			{
				char weapcls[32];
				GetEntityClassname(curweap,weapcls,sizeof(weapcls));
				if (StrEqual(weapcls,"weapon_crowbar",false))
				{
					damage = damage*HeavyCrowbarScale;
					return Plugin_Changed;
				}
			}
		}
		if ((DoubleDamage) || (CLHasProperty[attacker][1]))
		{
			damage = damage*2.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if ((PistolExplosions) || (RapidFire) || (CLHasProperty[client][3]) || (CLHasProperty[client][2]))
	{
		if (IsValidEntity(client))
		{
			if (HasEntProp(client,Prop_Data,"m_hActiveWeapon"))
			{
				if ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2) && (!(buttons & IN_ZOOM)))
				{
					int weap = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
					if (IsValidEntity(weap))
					{
						if ((PistolExplosions) || (CLHasProperty[client][3]))
						{
							char weapcls[32];
							GetEntityClassname(weap,weapcls,sizeof(weapcls));
							if ((StrEqual(weapcls,"weapon_pistol",false)) && (buttons & IN_ATTACK))
							{
								if (HasEntProp(weap,Prop_Data,"m_iClip1"))
								{
									int curamm = GetEntProp(weap,Prop_Send,"m_iClip1");
									if (curamm > 0)
									{
										if (centnextatk[weap] < GetGameTime())
										{
											if (!RapidFire) centnextatk[weap] = GetGameTime()+1.0;
											SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+0.1);
											SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+0.1);
											if (HasEntProp(weap,Prop_Send,"m_flSoonestPrimaryAttack")) SetEntPropFloat(weap,Prop_Send,"m_flSoonestPrimaryAttack",GetGameTime()+0.1);
											float plyfirepos[3];
											float plyang[3];
											float endpos[3];
											GetClientEyeAngles(client,plyang);
											GetClientEyePosition(client,plyfirepos);
											TR_TraceRayFilter(plyfirepos, plyang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
											TR_GetEndPosition(endpos);
											endpos[2]+=2.0;
											int ent = CreateEntityByName("env_explosion");
											if (ent != -1)
											{
												DispatchKeyValue(ent,"iMagnitude",pistolexpldmg);
												//DispatchKeyValue(ent,"iRadiusOverride","50");
												DispatchKeyValue(ent,"rendermode","0");
												//DispatchKeyValue(ent,"fireballsprite","sprites/zerogxplode.spr");
												TeleportEntity(ent,endpos,NULL_VECTOR,NULL_VECTOR);
												DispatchSpawn(ent);
												ActivateEntity(ent);
												SetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity",client);
												//AcceptEntityInput(ent,"Explode");
												//AcceptEntityInput(ent,"Kill");
												centnextatk[ent] = GetGameTime()+0.001;
												PushArrayCell(thinkingents,ent);
											}
											if (!RapidFire)
											{
												if (FindValueInArray(thinkingents,weap) == -1) PushArrayCell(thinkingents,weap);
											}
											SetEntProp(weap,Prop_Data,"m_iClip1",curamm-1);
										}
									}
								}
							}
						}
						if ((RapidFire) || (CLHasProperty[client][2]))
						{
							if (HasEntProp(weap,Prop_Data,"m_flNextPrimaryAttack"))
							{
								float nextatk = GetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack");
								if (centnextatk[client] > GetGameTime()+3.0) centnextatk[client] = GetGameTime();
								if (centnextatk[client] < nextatk)
								{
									SetEntPropFloat(weap,Prop_Data,"m_flNextPrimaryAttack",GetGameTime()+0.1);
									SetEntPropFloat(weap,Prop_Data,"m_flNextSecondaryAttack",GetGameTime()+0.1);
									if (HasEntProp(weap,Prop_Send,"m_bNeedPump"))
									{
										SetEntProp(weap,Prop_Send,"m_bNeedPump",0);
									}
									centnextatk[client] = nextatk+0.05;
								}
							}
						}
					}
				}
			}
		}
	}
}

public void ExplodeDelay(int entity)
{
	SDKUnhook(entity,SDKHook_SpawnPost,ExplodeDelay);
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity,"Explode");
	}
}

public void OnClientDisconnect_Post(int client)
{
	centnextatk[client] = 0.0;
	CLHasProperty[client][0] = false;
	CLHasProperty[client][1] = false;
	CLHasProperty[client][2] = false;
	CLHasProperty[client][3] = false;
	CLHasProperty[client][4] = false;
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (IsValidEntity(entity))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"npc_hornet",false)) return false;
	}
	return true;
}

public void heavycrowbch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) HeavyCrowbar = true;
	else HeavyCrowbar = false;
}

public void heavycrowbscalech(Handle convar, const char[] oldValue, const char[] newValue)
{
	HeavyCrowbarScale = StringToFloat(newValue);
}

public void doubledamagech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) DoubleDamage = true;
	else DoubleDamage = false;
}

public void rapidfirech(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) RapidFire = true;
	else RapidFire = false;
}

public void pistolexplosionsch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) PistolExplosions = true;
	else PistolExplosions = false;
}

public void pistolexplosionsdmgch(Handle convar, const char[] oldValue, const char[] newValue)
{
	Format(pistolexpldmg,sizeof(pistolexpldmg),"%s",newValue);
}

public void healthregench(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) HealthRegen = true;
	else HealthRegen = false;
}

public void healthregenstepch(Handle convar, const char[] oldValue, const char[] newValue)
{
	HealthRegenStep = StringToInt(newValue);
}