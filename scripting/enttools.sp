#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#pragma semicolon 1;
#pragma newdecls required;
#pragma dynamic 2097152;

#define PLUGIN_VERSION "1.32"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/enttoolsupdater.txt"

public Plugin myinfo = 
{
	name = "EntTools",
	author = "Balimbanana",
	description = "Entity tools.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

int showallcreated = 0;
int showalldeleted = 0;
int showalldeaths = 0;
bool showallnormsounds = false;
bool showallambsounds = false;

char CLClsSet[128][32];
Handle modelsarr = INVALID_HANDLE;

public void OnPluginStart()
{
	RegAdminCmd("createhere",CreateStuff,ADMFLAG_BAN,"cc");
	RegAdminCmd("createthere",CreateStuffThere,ADMFLAG_BAN,"cct");
	RegAdminCmd("cc",CreateStuff,ADMFLAG_BAN,"cc");
	RegAdminCmd("cct",CreateStuffThere,ADMFLAG_BAN,"cct");
	RegAdminCmd("ccmenu",CreateModel,ADMFLAG_BAN,"cctmdl");
	RegAdminCmd("setmdl",SetTargMdl,ADMFLAG_ROOT,".");
	RegAdminCmd("cinp",cinp,ADMFLAG_BAN,"ent_fire");
	RegAdminCmd("entinput",cinp,ADMFLAG_BAN,"ent_fire");
	RegAdminCmd("changeclasses",changeclasses,ADMFLAG_BAN,"ChangeClasses");
	RegConsoleCmd("gi",getinf);
	RegAdminCmd("tn",sett,ADMFLAG_PASSWORD,"SetName");
	RegAdminCmd("sm_sep",setprops,ADMFLAG_ROOT,".");
	RegAdminCmd("listents",listents,ADMFLAG_KICK,".");
	RegAdminCmd("findents",listents,ADMFLAG_KICK,".");
	RegAdminCmd("moveent",moveentity,ADMFLAG_KICK,".");
	Handle dbgcreate = CreateConVar("sm_showall_created", "0", "Shows all entities created in server console. 2 shows more info.", _, true, 0.0, true, 2.0);
	HookConVarChange(dbgcreate, dbghch);
	showallcreated = GetConVarInt(dbgcreate);
	CloseHandle(dbgcreate);
	dbgcreate = CreateConVar("sm_showall_deleted", "0", "Shows all entities deleted in server console.  2 shows more info.", _, true, 0.0, true, 2.0);
	HookConVarChange(dbgcreate, dbgcrehch);
	showalldeleted = GetConVarInt(dbgcreate);
	CloseHandle(dbgcreate);
	dbgcreate = CreateConVar("sm_showall_deaths", "0", "Shows all entities firing entity_death in server console.  2 shows more info.", _, true, 0.0, true, 2.0);
	HookConVarChange(dbgcreate, dbgdeahch);
	showalldeaths = GetConVarInt(dbgcreate);
	CloseHandle(dbgcreate);
	dbgcreate = CreateConVar("sm_showall_normsounds", "0", "Shows all normal sounds played in server console (skips stop flags).", _, true, 0.0, true, 1.0);
	HookConVarChange(dbgcreate, dbgnormsch);
	showallnormsounds = GetConVarBool(dbgcreate);
	CloseHandle(dbgcreate);
	dbgcreate = CreateConVar("sm_showall_ambientsounds", "0", "Shows all ambient sounds played in server console (skips stop flags).", _, true, 0.0, true, 1.0);
	HookConVarChange(dbgcreate, dbgambsch);
	showallambsounds = GetConVarBool(dbgcreate);
	CloseHandle(dbgcreate);
	HookEventEx("entity_killed",Event_EntityKilled,EventHookMode_Post);
	AddNormalSoundHook(listnormsounds);
	AddAmbientSoundHook(listambientsounds);
	modelsarr = CreateArray(1024);
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name,"updater",false))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action CreateStuff(int client, int args)
{
	char ent[64];
	GetCmdArg(1,ent,sizeof(ent));
	if (strlen(ent) < 1)
	{
		if (client != 0)
			PrintToConsole(client,"Please specify ent");
		else
			PrintToServer("Please specify ent");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		if ((IsValidEntity(1)) && (!IsDedicatedServer())) client = 1;
	}
	if (client == 0)
	{
		float Original[3];
		int stuff = CreateEntityByName(ent);
		if (stuff == -1)
		{
			PrintToConsole(client,"Unable to create entity %s",ent);
			return Plugin_Handled;
		}
		char fullstr[512];
		Format(fullstr,sizeof(fullstr),"%s",ent);
		char tmp[128];
		char tmp2[128];
		char originch[4][16];
		float vectmp[3];
		for (int v = 0; v<args+1; v++)
		{
			if (v > 1)
			{
				GetCmdArg(v,tmp,sizeof(tmp));
				int v1 = v+1;
				GetCmdArg(v1,tmp2,sizeof(tmp2));
				DispatchKeyValue(stuff,tmp,tmp2);
				if (StrEqual(tmp,"origin",false))
				{
					ExplodeString(tmp2," ",originch,4,16);
					Original[0] = StringToFloat(originch[0]);
					Original[1] = StringToFloat(originch[1]);
					Original[2] = StringToFloat(originch[2]);
				}
				if (StrEqual(tmp,"m_property",false))
				{
					if (v+2 < args+1)
					{
						v+=2;
						GetCmdArg(v,tmp,sizeof(tmp));
						if (HasEntProp(stuff,Prop_Data,tmp2))
						{
							PropFieldType type;
							FindDataMapInfo(stuff,tmp2,type);
							if (type != PropField_Unsupported)
							{
								if (type == PropField_String)
								{
									SetEntPropString(stuff,Prop_Data,tmp2,tmp);
								}
								else if (type == PropField_Entity)
								{
									SetEntPropEnt(stuff,Prop_Data,tmp2,StringToInt(tmp));
								}
								else if (type == PropField_Integer)
								{
									SetEntProp(stuff,Prop_Data,tmp2,StringToInt(tmp));
								}
								else if (type == PropField_Float)
								{
									SetEntPropFloat(stuff,Prop_Data,tmp2,StringToFloat(tmp));
								}
								else if (type == PropField_Vector)
								{
									ExplodeString(tmp," ",originch,4,16);
									vectmp[0] = StringToFloat(originch[0]);
									vectmp[1] = StringToFloat(originch[1]);
									vectmp[2] = StringToFloat(originch[2]);
									SetEntPropVector(stuff,Prop_Data,tmp2,vectmp);
								}
							}
						}
					}
				}
				Format(fullstr,sizeof(fullstr),"%s %s %s",fullstr,tmp,tmp2);
				v++;
			}
		}
		TeleportEntity(stuff, Original, NULL_VECTOR, NULL_VECTOR);
		PrintToConsole(client,"%s",fullstr);
		DispatchSpawn(stuff);
		ActivateEntity(stuff);
	}
	else if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		float PlayerOrigin[3];
		float Angles[3];
		float Location[3];
		char setparent[128];
		bool vehiclemodeldefined = false;
		bool vehiclescriptdefined = false;
		bool targnamedefined = false;
		GetClientAbsOrigin(client, Location);
		GetClientEyeAngles(client, Angles);
		PlayerOrigin[0] = (Location[0] + (100 * Cosine(DegToRad(Angles[1]))));
		PlayerOrigin[1] = (Location[1] + (100 * Sine(DegToRad(Angles[1]))));
		PlayerOrigin[2] = (Location[2] + 70);
		int stuff = 0;
		if (StrEqual(ent,"jalopy",false))
		{
			if ((!FileExists("models/vehicle.mdl",true,NULL_STRING)) && (!IsModelPrecached("models/vehicle.mdl")))
			{
				PrintToConsole(client,"Ep2 must be mounted to spawn a jalopy.");
				return Plugin_Handled;
			}
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_jeep_episodic");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/vehicle.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jalopy.txt");
		}
		else if ((StrEqual(ent,"jeep",false)) || (StrEqual(ent,"buggy",false)))
		{
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_jeep");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/buggy.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		else if ((StrEqual(ent,"jeepmp",false)) || (StrEqual(ent,"buggymp",false)) || (StrEqual(ent,"jeep2seat",false)) || (StrEqual(ent,"buggy2seat",false)))
		{
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_jeep");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/vehicles/buggy_p2.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		else if (StrEqual(ent,"airboat",false))
		{
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_airboat");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/airboat.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/airboat.txt");
		}
		else if (StrEqual(ent,"npc_bullsquid",false))
		{
			Format(ent,sizeof(ent),"npc_antlion");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_bullsquid");
			DispatchKeyValue(stuff,"classname","npc_bullsquid");
			DispatchKeyValue(stuff,"model","models/xenians/bullsquid.mdl");
			DispatchKeyValue(stuff,"RenderMode","10");
		}
		else if (StrEqual(ent,"npc_houndeye",false))
		{
			Format(ent,sizeof(ent),"npc_antlion");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_houndeye");
			DispatchKeyValue(stuff,"classname","npc_houndeye");
			DispatchKeyValue(stuff,"model","models/xenians/houndeye.mdl");
			DispatchKeyValue(stuff,"RenderMode","10");
		}
		else if (StrEqual(ent,"npc_alien_controller",false))
		{
			Format(ent,sizeof(ent),"generic_actor");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_alien_controller");
			DispatchKeyValue(stuff,"classname","npc_alien_controller");
			DispatchKeyValue(stuff,"model","models/xenians/controller.mdl");
		}
		else if (StrEqual(ent,"npc_alien_grunt",false))
		{
			Format(ent,sizeof(ent),"npc_combine_s");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_alien_grunt");
			DispatchKeyValue(stuff,"classname","npc_alien_grunt");
			DispatchKeyValue(stuff,"model","models/xenians/agrunt.mdl");
			DispatchKeyValue(stuff,"targetname","npc_alien_grunt");
			targnamedefined = true;
		}
		if (stuff == 0) stuff = CreateEntityByName(ent);
		if (stuff == -1)
		{
			PrintToConsole(client,"Unable to create entity %s",ent);
			return Plugin_Handled;
		}
		int ownerset = -1;
		Handle passedarr = CreateArray(64);
		Handle passedarrprops = CreateArray(64);
		char fullstr[512];
		Format(fullstr,sizeof(fullstr),"%s",ent);
		char tmpexpl[4][32];
		char tmp[64];
		char tmp2[512];
		float vectmp[3];
		for (int v = 0; v<args+1; v++)
		{
			if (v > 1)
			{
				GetCmdArg(v,tmp,sizeof(tmp));
				int v1 = v+1;
				int v1size = GetCmdArg(v1,tmp2,sizeof(tmp2));
				if (v1size > 0)
				{
					if (StrEqual(tmp,"model",false))
					{
						vehiclemodeldefined = true;
						if (StrContains(tmp2,".vmt",false) != -1)
						{
							char matchk[128];
							Format(matchk,sizeof(matchk),"materials/%s",tmp2);
							if ((!FileExists(matchk,true,NULL_STRING)) && (!IsModelPrecached(matchk)))
							{
								PrintToConsole(client,"The material %s was not found.",matchk);
								AcceptEntityInput(stuff,"kill");
								return Plugin_Handled;
							}
							else if (!IsModelPrecached(matchk))
							{
								PrecacheModel(matchk,true);
							}
						}
						else
						{
							if ((!FileExists(tmp2,true,NULL_STRING)) && (!IsModelPrecached(tmp2)))
							{
								PrintToConsole(client,"The model %s was not found.",tmp2);
								AcceptEntityInput(stuff,"kill");
								return Plugin_Handled;
							}
							else if (!IsModelPrecached(tmp2))
							{
								PrecacheModel(tmp2,true);
							}
						}
					}
					if (StrEqual(tmp,"vehiclescript",false))
					{
						vehiclescriptdefined = true;
						if (!FileExists(tmp2,true,NULL_STRING))
						{
							PrintToConsole(client,"The vehiclescript %s was not found.",tmp2);
							PrintToConsole(client,"Defaulting to \"scripts/vehicles/jeep_test.txt\"");
							Format(tmp2,sizeof(tmp2),"scripts/vehicles/jeep_test.txt");
						}
					}
					else if (StrEqual(tmp,"angles",false))
					{
						if ((StrEqual(tmp2,"myangles",false)) || (StrEqual(tmp2,"myangs",false)))
						{
							Format(tmp2,sizeof(tmp2),"%1.f %1.f %1.f",Angles[0],Angles[1],Angles[2]);
						}
						else
						{
							ExplodeString(tmp2," ",tmpexpl,4,32);
							Angles[0] = StringToFloat(tmpexpl[0]);
							Angles[1] = StringToFloat(tmpexpl[1]);
							Angles[2] = StringToFloat(tmpexpl[2]);
						}
					}
					else if (StrEqual(tmp,"owner",false))
					{
						if (StrEqual(tmp2,"!self",false))
						{
							ownerset = client;
						}
						else ownerset = StringToInt(tmp2);
					}
					else if (StrEqual(tmp,"parentname",false))
					{
						Format(setparent,sizeof(setparent),"%s",tmp2);
					}
					else if (StrEqual(tmp,"m_property",false))
					{
						if (v+2 < args+1)
						{
							v++;
							v1++;
							GetCmdArg(v,tmp,sizeof(tmp));
							GetCmdArg(v1,tmp2,sizeof(tmp2));
							TrimString(tmp);
							TrimString(tmp2);
							PushArrayString(passedarrprops,tmp);
							PushArrayString(passedarrprops,tmp2);
							ReplaceString(tmp2,sizeof(tmp2),"\\n","\n",false);
							if (HasEntProp(stuff,Prop_Data,tmp))
							{
								PropFieldType type;
								FindDataMapInfo(stuff,tmp,type);
								if ((type == PropField_String) || (type == PropField_String_T))
								{
									SetEntPropString(stuff,Prop_Data,tmp,tmp2);
								}
								else if (type == PropField_Entity)
								{
									SetEntPropEnt(stuff,Prop_Data,tmp,StringToInt(tmp2));
								}
								else if (type == PropField_Integer)
								{
									SetEntProp(stuff,Prop_Data,tmp,StringToInt(tmp2));
								}
								else if (type == PropField_Float)
								{
									SetEntPropFloat(stuff,Prop_Data,tmp,StringToFloat(tmp2));
								}
								else if (type == PropField_Vector)
								{
									ExplodeString(tmp2," ",tmpexpl,4,16);
									vectmp[0] = StringToFloat(tmpexpl[0]);
									vectmp[1] = StringToFloat(tmpexpl[1]);
									vectmp[2] = StringToFloat(tmpexpl[2]);
									SetEntPropVector(stuff,Prop_Data,tmp,vectmp);
								}
							}
						}
					}
					if (StrEqual(tmp,"targetname",false))
						if (targnamedefined)
							Format(tmp2,sizeof(tmp2),"%s%s",ent,tmp2);
					PushArrayString(passedarr,tmp);
					PushArrayString(passedarr,tmp2);
					DispatchKeyValue(stuff,tmp,tmp2);
					if (StrEqual(tmp,"origin",false))
					{
						char originch[3][16];
						ExplodeString(tmp2," ",originch,3,16);
						PlayerOrigin[0] = StringToFloat(originch[0]);
						PlayerOrigin[1] = StringToFloat(originch[1]);
						PlayerOrigin[2] = StringToFloat(originch[2]);
					}
				}
				Format(fullstr,sizeof(fullstr),"%s \"%s\" \"%s\"",fullstr,tmp,tmp2);
				v++;
			}
		}
		if (StrEqual(ent,"prop_vehicle_crane",false))
		{
			if (!vehiclescriptdefined) DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/crane.txt");
			if (!vehiclemodeldefined) DispatchKeyValue(stuff,"model","models/Cranes/crane_docks.mdl");
			if (FindStringInArray(passedarr,"magnetname") == -1)
			{
				char newmag[32];
				Format(newmag,sizeof(newmag),"cranemag%i",stuff);
				int magcreate = CreateEntityByName("phys_magnet");
				if (magcreate != -1)
				{
					DispatchKeyValue(magcreate,"targetname",newmag);
					DispatchKeyValue(magcreate,"skin","0");
					DispatchKeyValue(magcreate,"overridescript","damping,0.2,rotdamping,0.2,inertia,0.3");
					DispatchKeyValue(magcreate,"model","models/props_wasteland/cranemagnet01a.mdl");
					DispatchKeyValue(magcreate,"massScale","1000");
					DispatchKeyValue(magcreate,"disableshadows","0");
					float magorigin[3];
					if (FindStringInArray(passedarr,"angles") == -1) Angles[1] = 90.0;
					else Angles[1]+=90.0;
					magorigin[0] = (PlayerOrigin[0] + (834 * Cosine(DegToRad(Angles[1]))));
					magorigin[1] = (PlayerOrigin[1] + (834 * Sine(DegToRad(Angles[1]))));
					magorigin[2] = (PlayerOrigin[2] + 700);
					Angles[1]-=90.0;
					TeleportEntity(magcreate,magorigin,NULL_VECTOR,NULL_VECTOR);
					DispatchSpawn(magcreate);
					ActivateEntity(magcreate);
				}
				DispatchKeyValue(stuff,"magnetname",newmag);
			}
			vehiclescriptdefined = true;
			vehiclemodeldefined = true;
		}
		if (((StrContains(ent,"prop_vehicle",false) != -1) || (StrEqual(ent,"generic_actor",false)) || (StrEqual(ent,"monster_generic",false))) && (!vehiclemodeldefined))
		{
			PrintToConsole(client,"Model must be defined for this type of entity.");
			AcceptEntityInput(stuff,"kill");
			return Plugin_Handled;
		}
		if ((StrContains(ent,"prop_vehicle",false) != -1) && (!vehiclescriptdefined))
		{
			PrintToConsole(client,"VehicleScript was not defined, defaulting to \"scripts/vehicles/jeep_test.txt\"");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		TeleportEntity(stuff, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
		CloseHandle(passedarr);
		PrintToConsole(client,"%s",fullstr);
		DispatchSpawn(stuff);
		ActivateEntity(stuff);
		if (GetArraySize(passedarrprops) > 0)
		{
			Handle dp = CreateDataPack();
			WritePackCell(dp,stuff);
			WritePackCell(dp,passedarrprops);
			CreateTimer(0.1,PostSpawnSetProp,dp,TIMER_FLAG_NO_MAPCHANGE);
		}
		else CloseHandle(passedarrprops);
		if ((ownerset != -1) && (ownerset != 0))
		{
			Handle dp = CreateDataPack();
			WritePackCell(dp,ownerset);
			WritePackCell(dp,stuff);
			CreateTimer(0.1,ApplyOwner,dp);
		}
		if (strlen(setparent) > 0)
		{
			if (StrEqual(setparent,"!self",false))
			{
				SetVariantString("!activator");
				AcceptEntityInput(stuff,"SetParent",client);
			}
			else
			{
				SetVariantString(setparent);
				AcceptEntityInput(stuff,"SetParent");
			}
		}
	}
	return Plugin_Handled;
}

public Action PostSpawnSetProp(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int stuff = ReadPackCell(dp);
		Handle passedarrprops = ReadPackCell(dp);
		CloseHandle(dp);
		if (IsValidEntity(stuff))
		{
			char tmp[64];
			char tmp2[512];
			float vectmp[3];
			char tmpexpl[4][16];
			for (int i = 0;i<GetArraySize(passedarrprops);i++)
			{
				GetArrayString(passedarrprops,i,tmp,sizeof(tmp));
				i++;
				if (i >= GetArraySize(passedarrprops)) break;
				GetArrayString(passedarrprops,i,tmp2,sizeof(tmp2));
				ReplaceString(tmp2,sizeof(tmp2),"\\n","\n",false);
				if (HasEntProp(stuff,Prop_Data,tmp))
				{
					PropFieldType type;
					FindDataMapInfo(stuff,tmp,type);
					if ((type == PropField_String) || (type == PropField_String_T))
					{
						SetEntPropString(stuff,Prop_Data,tmp,tmp2);
					}
					else if (type == PropField_Entity)
					{
						SetEntPropEnt(stuff,Prop_Data,tmp,StringToInt(tmp2));
					}
					else if (type == PropField_Integer)
					{
						SetEntProp(stuff,Prop_Data,tmp,StringToInt(tmp2));
					}
					else if (type == PropField_Float)
					{
						SetEntPropFloat(stuff,Prop_Data,tmp,StringToFloat(tmp2));
					}
					else if (type == PropField_Vector)
					{
						ExplodeString(tmp2," ",tmpexpl,4,16);
						vectmp[0] = StringToFloat(tmpexpl[0]);
						vectmp[1] = StringToFloat(tmpexpl[1]);
						vectmp[2] = StringToFloat(tmpexpl[2]);
						SetEntPropVector(stuff,Prop_Data,tmp,vectmp);
					}
				}
			}
		}
		CloseHandle(passedarrprops);
	}
}

public Action ApplyOwner(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int owner = ReadPackCell(dp);
		int entity = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(owner)) && (IsValidEntity(entity)))
		{
			if (HasEntProp(entity,Prop_Data,"m_hOwnerEntity")) SetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity",owner);
		}
	}
}

public Action CreateStuffThere(int client, int args)
{
	if (client == 0)
	{
		if ((IsValidEntity(1)) && (!IsDedicatedServer())) client = 1;
		else return Plugin_Handled;
	}
	char ent[64];
	GetCmdArg(1,ent,sizeof(ent));
	if (strlen(ent) < 1)
	{
		PrintToConsole(client,"Please specify ent");
		return Plugin_Handled;
	}
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		float Location[3];
		float fhitpos[3];
		float clangles[3];
		bool vehiclemodeldefined = false;
		bool vehiclescriptdefined = false;
		bool targnamedefined = false;
		char setparent[128];
		GetClientEyeAngles(client, clangles);
		GetClientEyePosition(client, Location);
		Location[0] = (Location[0] + (10 * Cosine(DegToRad(clangles[1]))));
		Location[1] = (Location[1] + (10 * Sine(DegToRad(clangles[1]))));
		Location[2] = (Location[2] + 10);
		Handle hhitpos = INVALID_HANDLE;
		TR_TraceRay(Location,clangles,MASK_SHOT,RayType_Infinite);
		TR_GetEndPosition(fhitpos,hhitpos);
		//To ensure they spawn above the ground
		fhitpos[2]+=15.0;
		if (StrEqual(ent,"npc_strider",false))
			fhitpos[2] = (fhitpos[2] + 165);
		else if ((StrEqual(ent,"npc_houndeye",false)) || (StrEqual(ent,"npc_bullsquid",false)))
			fhitpos[2]+=20.0;
		CloseHandle(hhitpos);
		int stuff = CreateEntityByName(ent);
		if (StrEqual(ent,"jalopy",false))
		{
			if ((!FileExists("models/vehicle.mdl",true,NULL_STRING)) && (!IsModelPrecached("models/vehicle.mdl")))
			{
				PrintToConsole(client,"Ep2 must be mounted to spawn a jalopy.");
				return Plugin_Handled;
			}
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_jeep_episodic");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/vehicle.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jalopy.txt");
		}
		else if ((StrEqual(ent,"jeep",false)) || (StrEqual(ent,"buggy",false)))
		{
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_jeep");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/buggy.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		else if ((StrEqual(ent,"jeepmp",false)) || (StrEqual(ent,"buggymp",false)) || (StrEqual(ent,"jeep2seat",false)) || (StrEqual(ent,"buggy2seat",false)))
		{
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_jeep");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/vehicles/buggy_p2.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		else if (StrEqual(ent,"airboat",false))
		{
			vehiclemodeldefined = true;
			vehiclescriptdefined = true;
			Format(ent,sizeof(ent),"prop_vehicle_airboat");
			stuff = CreateEntityByName(ent);
			DispatchKeyValue(stuff,"model","models/airboat.mdl");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/airboat.txt");
		}
		else if (StrEqual(ent,"npc_bullsquid",false))
		{
			Format(ent,sizeof(ent),"npc_antlion");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_bullsquid");
			DispatchKeyValue(stuff,"classname","npc_bullsquid");
			DispatchKeyValue(stuff,"model","models/xenians/bullsquid.mdl");
			DispatchKeyValue(stuff,"RenderMode","10");
		}
		else if (StrEqual(ent,"npc_houndeye",false))
		{
			Format(ent,sizeof(ent),"npc_antlion");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_houndeye");
			DispatchKeyValue(stuff,"classname","npc_houndeye");
			DispatchKeyValue(stuff,"model","models/xenians/houndeye.mdl");
			DispatchKeyValue(stuff,"RenderMode","10");
		}
		else if (StrEqual(ent,"npc_alien_controller",false))
		{
			Format(ent,sizeof(ent),"generic_actor");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_alien_controller");
			DispatchKeyValue(stuff,"classname","npc_alien_controller");
			DispatchKeyValue(stuff,"model","models/xenians/controller.mdl");
		}
		else if (StrEqual(ent,"npc_alien_grunt",false))
		{
			Format(ent,sizeof(ent),"npc_combine_s");
			stuff = CreateEntityByName(ent);
			Format(ent,sizeof(ent),"npc_alien_grunt");
			DispatchKeyValue(stuff,"classname","npc_alien_grunt");
			DispatchKeyValue(stuff,"model","models/xenians/agrunt.mdl");
			DispatchKeyValue(stuff,"targetname","npc_alien_grunt");
			targnamedefined = true;
		}
		if (stuff == 0) stuff = CreateEntityByName(ent);
		if (stuff == -1)
		{
			PrintToConsole(client,"Unable to create entity %s",ent);
			return Plugin_Handled;
		}
		int ownerset = -1;
		char fullstr[512];
		Format(fullstr,sizeof(fullstr),"%s",ent);
		Handle passedarr = CreateArray(64);
		for (int v = 0; v<args+1; v++)
		{
			if (v > 1)
			{
				char tmp[64];
				char tmp2[64];
				GetCmdArg(v,tmp,sizeof(tmp));
				int v1 = v+1;
				int v1size = GetCmdArg(v1,tmp2,sizeof(tmp2));
				if (v1size > 0)
				{
					if (StrEqual(tmp,"model",false))
					{
						vehiclemodeldefined = true;
						if (StrContains(tmp2,".vmt",false) != -1)
						{
							char matchk[128];
							Format(matchk,sizeof(matchk),"materials/%s",tmp2);
							if ((!FileExists(matchk,true,NULL_STRING)) && (!IsModelPrecached(matchk)))
							{
								PrintToConsole(client,"The material %s was not found.",matchk);
								AcceptEntityInput(stuff,"kill");
								return Plugin_Handled;
							}
							else if (!IsModelPrecached(matchk))
							{
								PrecacheModel(matchk,true);
							}
						}
						else
						{
							if ((!FileExists(tmp2,true,NULL_STRING)) && (!IsModelPrecached(tmp2)))
							{
								PrintToConsole(client,"The model %s was not found.",tmp2);
								AcceptEntityInput(stuff,"kill");
								return Plugin_Handled;
							}
							else if (!IsModelPrecached(tmp2))
							{
								PrecacheModel(tmp2,true);
							}
						}
					}
					if (StrEqual(tmp,"vehiclescript",false))
					{
						vehiclescriptdefined = true;
						if (!FileExists(tmp2,true,NULL_STRING))
						{
							PrintToConsole(client,"The vehiclescript %s was not found.",tmp2);
							PrintToConsole(client,"Defaulting to \"scripts/vehicles/jeep_test.txt\"");
							Format(tmp2,sizeof(tmp2),"scripts/vehicles/jeep_test.txt");
						}
					}
					else if (StrEqual(tmp,"angles",false))
					{
						if ((StrEqual(tmp2,"myangles",false)) || (StrEqual(tmp2,"myangs",false)))
						{
							Format(tmp2,sizeof(tmp2),"%1.f %1.f %1.f",clangles[0],clangles[1],clangles[2]);
						}
						else
						{
							char tmpexpl[4][32];
							ExplodeString(tmp2," ",tmpexpl,4,32);
							clangles[0] = StringToFloat(tmpexpl[0]);
							clangles[1] = StringToFloat(tmpexpl[1]);
							clangles[2] = StringToFloat(tmpexpl[2]);
						}
					}
					else if (StrEqual(tmp,"owner",false))
					{
						if (StrEqual(tmp2,"!self",false))
						{
							ownerset = client;
						}
						else ownerset = StringToInt(tmp2);
					}
					else if (StrEqual(tmp,"parentname",false))
					{
						Format(setparent,sizeof(setparent),"%s",tmp2);
					}
					if (StrEqual(tmp,"targetname",false))
						if (targnamedefined)
							Format(tmp2,sizeof(tmp2),"%s%s",ent,tmp2);
					PushArrayString(passedarr,tmp);
					PushArrayString(passedarr,tmp2);
					DispatchKeyValue(stuff,tmp,tmp2);
					if (StrEqual(tmp,"origin",false))
					{
						char originch[3][16];
						ExplodeString(tmp2," ",originch,3,16);
						Location[0] = StringToFloat(originch[0]);
						Location[1] = StringToFloat(originch[1]);
						Location[2] = StringToFloat(originch[2]);
					}
				}
				Format(fullstr,sizeof(fullstr),"%s %s %s",fullstr,tmp,tmp2);
				v++;
			}
		}
		if (StrEqual(ent,"prop_vehicle_crane",false))
		{
			if (!vehiclescriptdefined) DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/crane.txt");
			if (!vehiclemodeldefined) DispatchKeyValue(stuff,"model","models/Cranes/crane_docks.mdl");
			if (FindStringInArray(passedarr,"magnetname") == -1)
			{
				fhitpos[2]+=10.0;
				char newmag[32];
				Format(newmag,sizeof(newmag),"cranemag%i",stuff);
				int magcreate = CreateEntityByName("phys_magnet");
				if (magcreate != -1)
				{
					DispatchKeyValue(magcreate,"targetname",newmag);
					DispatchKeyValue(magcreate,"skin","0");
					DispatchKeyValue(magcreate,"overridescript","damping,0.2,rotdamping,0.2,inertia,0.3");
					DispatchKeyValue(magcreate,"model","models/props_wasteland/cranemagnet01a.mdl");
					DispatchKeyValue(magcreate,"massScale","1000");
					DispatchKeyValue(magcreate,"disableshadows","0");
					float magorigin[3];
					if (FindStringInArray(passedarr,"angles") == -1) clangles[1] = 90.0;
					else clangles[1]+=90.0;
					magorigin[0] = (fhitpos[0] + (834 * Cosine(DegToRad(clangles[1]))));
					magorigin[1] = (fhitpos[1] + (834 * Sine(DegToRad(clangles[1]))));
					magorigin[2] = (fhitpos[2] + 700);
					clangles[1]-=90.0;
					TeleportEntity(magcreate,magorigin,NULL_VECTOR,NULL_VECTOR);
					DispatchSpawn(magcreate);
					ActivateEntity(magcreate);
				}
				DispatchKeyValue(stuff,"magnetname",newmag);
			}
			vehiclescriptdefined = true;
			vehiclemodeldefined = true;
		}
		if (((StrContains(ent,"prop_vehicle",false) != -1) || (StrEqual(ent,"generic_actor",false)) || (StrEqual(ent,"monster_generic",false))) && (!vehiclemodeldefined))
		{
			PrintToConsole(client,"Model must be defined for this type of entity.");
			AcceptEntityInput(stuff,"kill");
			return Plugin_Handled;
		}
		if ((StrContains(ent,"prop_vehicle",false) != -1) && (!vehiclescriptdefined))
		{
			PrintToConsole(client,"VehicleScript was not defined, defaulting to \"scripts/vehicles/jeep_test.txt\"");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		CloseHandle(passedarr);
		PrintToConsole(client,"%s",fullstr);
		TeleportEntity(stuff, fhitpos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(stuff);
		ActivateEntity(stuff);
		if ((ownerset != -1) && (ownerset != 0))
		{
			Handle dp = CreateDataPack();
			WritePackCell(dp,ownerset);
			WritePackCell(dp,stuff);
			CreateTimer(0.1,ApplyOwner,dp);
		}
		if (strlen(setparent) > 0)
		{
			if (StrEqual(setparent,"!self",false))
			{
				SetVariantString("!activator");
				AcceptEntityInput(stuff,"SetParent",client);
			}
			else
			{
				SetVariantString(setparent);
				AcceptEntityInput(stuff,"SetParent");
			}
		}
	}
	return Plugin_Handled;
}

public Action CreateModel(int client, int args)
{
	Menu menu = new Menu(MenuHandlerCreateTop);
	menu.SetTitle("Create As");
	menu.AddItem("prop_physics_override", "Create as prop_physics");
	menu.AddItem("prop_dynamic_override", "Create as prop_dynamic");
	menu.ExitButton = true;
	menu.Display(client, 120);
	return Plugin_Handled;
}

void DisplayModelLists(int client)
{
	if (GetArraySize(modelsarr) < 1)
	{
		Handle hOpendir = OpenDirectory("models",true,NULL_STRING);
		if (hOpendir != INVALID_HANDLE)
		{
			char buff[128];
			while (ReadDirEntry(hOpendir, buff, sizeof(buff)))
			{
				if ((!(hOpendir == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
				{
					Format(buff,sizeof(buff),"models/%s",buff);
					if (StrContains(buff,".mdl",false) != -1)
					{
						PushArrayString(modelsarr,buff);
					}
					else if (StrContains(buff,".",false) == -1)
					{
						recursion(buff);
					}
				}
			}
		}
		CloseHandle(hOpendir);
	}
	Menu menu = new Menu(MenuHandlerCreateSub);
	menu.SetTitle("Models:");
	if (GetArraySize(modelsarr) > 0)
	{
		char mdlpaths[256];
		for (int i = 0;i<GetArraySize(modelsarr);i++)
		{
			GetArrayString(modelsarr,i,mdlpaths,sizeof(mdlpaths));
			menu.AddItem(mdlpaths,mdlpaths);
		}
	}
	menu.ExitButton = true;
	menu.Display(client, 300);
	return;
}

void recursion(char[] startpath)
{
	if (DirExists(startpath,true,NULL_STRING))
	{
		Handle hOpendir = OpenDirectory(startpath,true,NULL_STRING);
		if (hOpendir != INVALID_HANDLE)
		{
			char buff[256];
			while (ReadDirEntry(hOpendir, buff, sizeof(buff)))
			{
				if ((!(hOpendir == INVALID_HANDLE)) && (!(StrEqual(buff, "."))) && (!(StrEqual(buff, ".."))))
				{
					Format(buff,sizeof(buff),"%s/%s",startpath,buff);
					if (StrContains(buff,".mdl",false) != -1)
					{
						PushArrayString(modelsarr,buff);
					}
					else if (StrContains(buff,".",false) == -1)
					{
						recursion(buff);
					}
				}
			}
		}
		CloseHandle(hOpendir);
	}
	return;
}

public int MenuHandlerCreateTop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param2, info, sizeof(info));
		Format(CLClsSet[param1],sizeof(CLClsSet[]),"%s",info);
		DisplayModelLists(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlerCreateSub(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[256];
		menu.GetItem(param2, info, sizeof(info));
		int mdlcreate = CreateEntityByName(CLClsSet[param1]);
		if (mdlcreate != -1)
		{
			float Location[3];
			float fhitpos[3];
			float clangles[3];
			GetClientEyeAngles(param1, clangles);
			GetClientEyePosition(param1, Location);
			Location[0] = (Location[0] + (10 * Cosine(DegToRad(clangles[1]))));
			Location[1] = (Location[1] + (10 * Sine(DegToRad(clangles[1]))));
			Location[2] = (Location[2] + 10);
			Handle hhitpos = INVALID_HANDLE;
			TR_TraceRay(Location,clangles,MASK_SHOT,RayType_Infinite);
			TR_GetEndPosition(fhitpos,hhitpos);
			//To ensure it spawns above the ground
			fhitpos[2]+=15.0;
			CloseHandle(hhitpos);
			DispatchKeyValue(mdlcreate,"solid","6");
			DispatchKeyValue(mdlcreate,"model",info);
			TeleportEntity(mdlcreate, fhitpos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(mdlcreate);
			ActivateEntity(mdlcreate);
		}
		PrintToChat(param1,"Create %s %s",CLClsSet[param1],info);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public Action cinp(int client, int args)
{
	char fullinp[128];
	char firstarg[128];
	GetCmdArgString(fullinp, sizeof(fullinp));
	GetCmdArg(1,firstarg, sizeof(firstarg));
	if ((StrEqual(firstarg,"!picker",false)) && (args > 1))
	{
		int targ = GetClientAimTarget(client, false);
		if (targ == -1)
		{
			if (client == 0) PrintToServer("Invalid target.");
			else PrintToConsole(client,"Invalid target.");
			return Plugin_Handled;
		}
		char second[128];
		GetCmdArg(2,second,sizeof(second));
		char input[256];
		for (int i = 3;i<args+1;i++)
		{
			char argch[128];
			GetCmdArg(i,argch,sizeof(argch));
			if (i == 3)
				Format(input,sizeof(input),"%s",argch);
			else
				Format(input,sizeof(input),"%s %s",input,argch);
		}
		SetVariantString(input);
		AcceptEntityInput(targ,second);
		if (StrEqual(second,"SetMass",false))
		{
			char targn[128];
			if (HasEntProp(targ,Prop_Data,"m_iName")) GetEntPropString(targ,Prop_Data,"m_iName",targn,sizeof(targn));
			SetEntityMoveType(targ,MOVETYPE_NOCLIP);
			int convert = CreateEntityByName("phys_convert");
			if (convert != -1)
			{
				if (strlen(targn) < 1)
				{
					if (HasEntProp(targ,Prop_Data,"m_iName")) SetEntPropString(targ,Prop_Data,"m_iName","syntmpmasstarg");
					Format(targn,sizeof(targn),"syntmpmasstarg");
				}
				DispatchKeyValue(convert,"target",targn);
				DispatchKeyValue(convert,"swapmodel",targn);
				DispatchKeyValue(convert,"massoverride",input);
				DispatchSpawn(convert);
				ActivateEntity(convert);
				AcceptEntityInput(convert,"ConvertTarget");
				AcceptEntityInput(convert,"kill");
				if ((HasEntProp(targ,Prop_Data,"m_iName")) && (StrEqual(targn,"syntmpmasstarg",false)))
				{
					SetEntPropString(targ,Prop_Data,"m_iName","");
					CreateTimer(0.2,ResetTargn,targ,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		return Plugin_Handled;
	}
	PrintToConsole(client,"%s",fullinp);
	Handle arr = CreateArray(64);
	if (StrEqual(firstarg,"!self",false))
		PushArrayCell(arr,client);
	else if (StrEqual(firstarg,"!picker",false))
		PushArrayCell(arr,GetClientAimTarget(client, false));
	if (StrContains(fullinp,",",false) != -1)
	{
		int loginp = CreateEntityByName("logic_auto");
		DispatchKeyValue(loginp, "spawnflags","1");
		DispatchKeyValue(loginp, "OnMapSpawn",fullinp);
		DispatchSpawn(loginp);
		ActivateEntity(loginp);
		CloseHandle(arr);
		return Plugin_Handled;
	}
	else if ((strlen(firstarg) > 0) && (args > 1) && (StringToInt(firstarg) == 0))
	{
		if (StrContains(firstarg,"*",false) == 0)
		{
			char tmp[64];
			Format(tmp,sizeof(tmp),"%s",firstarg);
			ReplaceStringEx(tmp,sizeof(tmp),"*","");
			if (StrContains(tmp,"*",false) > 0)
			{
				PrintToConsole(client,"Unable to select multiple * at the moment.");
				CloseHandle(arr);
				return Plugin_Handled;
			}
		}
		findentsarrtarg(arr,firstarg);
		//Checks must be separate
		if (arr == INVALID_HANDLE)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",firstarg);
			else PrintToConsole(client,"No entities found with either classname or targetname of %s",firstarg);
			CloseHandle(arr);
			return Plugin_Handled;
		}
		else if (GetArraySize(arr) < 1)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",firstarg);
			else PrintToConsole(client,"No entities found with either classname or targetname of %s",firstarg);
			CloseHandle(arr);
			return Plugin_Handled;
		}
		else
		{
			char input[128];
			GetCmdArg(2,input,sizeof(input));
			ReplaceStringEx(fullinp,sizeof(fullinp),firstarg,"");
			ReplaceStringEx(fullinp,sizeof(fullinp),input,"");
			ReplaceStringEx(fullinp,sizeof(fullinp),"  ","");
			for (int i = 0;i<GetArraySize(arr);i++)
			{
				int j = GetArrayCell(arr,i);
				SetVariantString(fullinp);
				AcceptEntityInput(j,input);
			}
			if (client == 0) PrintToServer("%s %s %s",firstarg,input,fullinp);
			else PrintToConsole(client,"%s %s %s",firstarg,input,fullinp);
			CloseHandle(arr);
			return Plugin_Handled;
		}
	}
	if (StrEqual(firstarg,"name",false))
	{
		int targ = -1;
		char second[64];
		char third[32];
		char fourth[32];
		GetCmdArg(2, second, sizeof(second));
		GetCmdArg(3, third, sizeof(third));
		GetCmdArg(4, fourth, sizeof(fourth));
		for (int i = 0; i<MaxClients+1 ;i++)
		{
			if ((i != 0) && (IsClientConnected(i)) && (IsClientInGame(i)))
			{
				char nick[64];
				GetClientName(i, nick, sizeof(nick));
				if (StrContains( nick, second, true) != -1)
				{
					targ = i;
					if (client == 0)
						PrintToServer("Setting %s %s %s",nick,third,fourth);
					else
						PrintToConsole(client,"Setting %s %s %s",nick,third,fourth);
					break;
				}
			}
		}
		if (targ != -1)
		{
			char thisvar[64];
			char fifth[32];
			GetCmdArg(5, fifth, sizeof(fifth));
			if (strlen(fifth) > 0)
				Format(thisvar,sizeof(thisvar),"%s %s",fourth,fifth);
			else if (strlen(fourth) > 0)
				Format(thisvar,sizeof(thisvar),"%s",fourth);
			if (strlen(thisvar) > 0)
				SetVariantString(thisvar);
			AcceptEntityInput(targ,third);
		}
	}
	else
	{
		int targ = GetClientAimTarget(client, false);
		int addarg = 0;
		char first[32];
		GetCmdArg(1, first, sizeof(first));
		if (StrEqual(first,"!self",false))
		{
			targ = client;
			addarg = 1;
		}
		else if (StrEqual(first,"!picker",false))
			addarg = 1;
		if (targ != -1)
		{
			int varint = -1;
			if (args == 2+addarg)
			{
				char secondintchk[16];
				GetCmdArg(2+addarg, secondintchk, sizeof(secondintchk));
				float secondfl = StringToFloat(secondintchk);
				int secondint = StringToInt(secondintchk);
				if (StrEqual(secondintchk,"0",false) && (secondint == 0))
					varint = 0;
				else if (secondint > 0)
					varint = secondint;
				else if (secondfl != 0.0)
					SetVariantFloat(secondfl);
				else
					varint = -1;
			}
			else if (args == 3+addarg)
			{
				char secondintchk[16];
				GetCmdArg(3+addarg, secondintchk, sizeof(secondintchk));
				float secondfl = StringToFloat(secondintchk);
				int secondint = StringToInt(secondintchk);
				if (StrEqual(secondintchk,"0",false) && (secondint == 0))
					varint = 0;
				else if (secondint > 0)
					varint = secondint;
				else if (secondfl != 0.0)
					SetVariantFloat(secondfl);
				else
					varint = -1;
			}
			char firstplus[32];
			Format(firstplus,sizeof(firstplus),"%s ",first);
			ReplaceString(fullinp,sizeof(fullinp),firstplus,"");
			ReplaceString(fullinp,sizeof(fullinp),"\"","");
			if (varint == -1)
				SetVariantString(fullinp);
			else
				SetVariantInt(varint);
			AcceptEntityInput(targ,first);
		}
	}
	CloseHandle(arr);
	return Plugin_Handled;
}

public Action ResetTargn(Handle timer, int targ)
{
	if (IsValidEntity(targ))
	{
		if (HasEntProp(targ,Prop_Data,"m_iName")) SetEntPropString(targ,Prop_Data,"m_iName","");
	}
}

public Action SetTargMdl(int client, int args)
{
	if ((args < 2) || (client == 0))
	{
		if (client == 0) PrintToServer("Must specify model to set");
		else PrintToConsole(client,"Must specify model to set");
		return Plugin_Handled;
	}
	else
	{
		char first[64];
		GetCmdArg(1,first,sizeof(first));
		int targ = GetClientAimTarget(client,false);
		if (StrEqual(first,"!self",false))
			targ = client;
		else if (StrEqual(first,"!picker",false))
			targ = GetClientAimTarget(client, false);
		else if ((StringToInt(first) != 0) && (strlen(first) > 0))
			targ = StringToInt(first);
		if (targ == -1)
		{
			PrintToConsole(client,"Invalid target");
			return Plugin_Handled;
		}
		else
		{
			char mdltoset[128];
			GetCmdArg(2,mdltoset, sizeof(mdltoset));
			if ((!FileExists(mdltoset,true,NULL_STRING)) && (!IsModelPrecached(mdltoset)))
			{
				PrintToConsole(client,"The model %s was not found.",mdltoset);
				return Plugin_Handled;
			}
			if (!IsModelPrecached(mdltoset)) PrecacheModel(mdltoset,true);
			SetEntityModel(targ,mdltoset);
		}
	}
	return Plugin_Handled;
}

public Action changeclasses(int client, int args)
{
	if (args < 2) return Plugin_Handled;
	char h[32];
	char j[32];
	GetCmdArg(1,h,sizeof(h));
	GetCmdArg(2,j,sizeof(j));
	Handle arr = CreateArray(256);
	findentsarr(arr,MaxClients+1,h);
	if (arr != INVALID_HANDLE)
	{
		for (int i = 0;i<GetArraySize(arr);i++)
		{
			int ent = GetArrayCell(arr,i);
			float origin[3];
			float angles[3];
			char targn[64];
			if (HasEntProp(ent,Prop_Send,"m_vecOrigin")) GetEntPropVector(ent,Prop_Send,"m_vecOrigin",origin);
			else if (HasEntProp(ent,Prop_Send,"m_vecAbsOrigin")) GetEntPropVector(ent,Prop_Send,"m_vecAbsOrigin",origin);
			if (HasEntProp(ent,Prop_Send,"m_vecAngles")) GetEntPropVector(ent,Prop_Send,"m_vecAngles",angles);
			else if (HasEntProp(ent,Prop_Data,"m_angAbsRotation")) GetEntPropVector(ent,Prop_Data,"m_angAbsRotation",angles);
			else if (HasEntProp(ent,Prop_Send,"m_angAbsRotation")) GetEntPropVector(ent,Prop_Send,"m_angAbsRotation",angles);
			GetEntPropString(ent,Prop_Data,"m_iName",targn,sizeof(targn));
			int replaceent = CreateEntityByName(j);
			if (replaceent == -1)
			{
				PrintToConsole(client,"Cannot replace with null ent %s",j);
				return Plugin_Handled;
			}
			DispatchKeyValue(replaceent,"targetname",targn);
			if (args > 2)
			{
				for (int v = 3; v<args+1; v++)
				{
					if (v > 1)
					{
						char tmp[64];
						char tmp2[64];
						GetCmdArg(v,tmp,sizeof(tmp));
						int v1 = v+1;
						GetCmdArg(v1,tmp2,sizeof(tmp2));
						DispatchKeyValue(replaceent,tmp,tmp2);
						v++;
					}
				}
			}
			TeleportEntity(replaceent,origin,angles,NULL_VECTOR);
			DispatchSpawn(replaceent);
			ActivateEntity(replaceent);
			AcceptEntityInput(ent,"kill");
		}
		if (GetArraySize(arr) > 0)
			PrintToConsole(client,"Changed %i ents to %s",GetArraySize(arr),j);
	}
	CloseHandle(arr);
	return Plugin_Handled;
}

public Handle findentsarr(Handle arr, int ent, char[] clsname)
{
	if (arr == INVALID_HANDLE) return INVALID_HANDLE;
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		if (FindValueInArray(arr, thisent) == -1)
		{
			PushArrayCell(arr, thisent);
		}
		findentsarr(arr,thisent++,clsname);
	}
	if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}

public Handle findentsarrtargsub(Handle arr, int ent, char[] namechk, char[] clsname)
{
	if (arr == INVALID_HANDLE) return INVALID_HANDLE;
	int thisent = FindEntityByClassname(ent,clsname);
	if (IsValidEntity(thisent))
	{
		if ((StrEqual(clsname,namechk,false)) && (FindValueInArray(arr,thisent) == -1))
			PushArrayCell(arr, thisent);
		if ((HasEntProp(thisent,Prop_Data,"m_iName")) && (FindValueInArray(arr,thisent) == -1))
		{
			char fname[128];
			GetEntPropString(thisent,Prop_Data,"m_iName",fname,sizeof(fname));
			if (StrContains(fname,"\"",false) != -1) ReplaceString(fname,sizeof(fname),"\"","");
			if ((StrContains(namechk,"*",false) > 0) && (StrContains(namechk,"*",false) != 0))
			{
				char tmppass[64];
				Format(tmppass,sizeof(tmppass),"%s",namechk);
				ReplaceString(tmppass,sizeof(tmppass),"*","");
				if (StrContains(fname,tmppass,false) != -1)
				{
					if (FindValueInArray(arr,thisent) == -1) PushArrayCell(arr,thisent);
				}
			}
			else if ((StrContains(namechk,"*",false) == 0) && (StrContains(namechk,"*",false) > 0))
			{
				char tmppass[64];
				Format(tmppass,sizeof(tmppass),"%s",namechk);
				ReplaceString(tmppass,sizeof(tmppass),"*","");
				if (StrContains(fname,tmppass,false) != -1)
				{
					if (FindValueInArray(arr,thisent) == -1) PushArrayCell(arr,thisent);
				}
			}
			else if (StrContains(namechk,"*",false) == 0)
			{
				char tmppass[64];
				char tmpend[64];
				char tmpchar[16];
				Format(tmppass,sizeof(tmppass),"%s",namechk);
				ReplaceString(tmppass,sizeof(tmppass),"*","");
				int endpos = StrContains(fname,tmppass,false);
				if (endpos != -1)
				{
					Format(tmpchar,endpos+1,"%s",fname);
					if (strlen(tmpchar) < 1)
					{
						if (FindValueInArray(arr,thisent) == -1) PushArrayCell(arr,thisent);
					}
					else
					{
						Format(tmpend,sizeof(tmpend),"%s",fname);
						ReplaceStringEx(tmpend,sizeof(tmpend),tmpchar,"");
						ReplaceStringEx(tmpend,sizeof(tmpend),tmppass,"");
						if (strlen(tmpend) < 1)
						{
							if (FindValueInArray(arr,thisent) == -1) PushArrayCell(arr,thisent);
						}
					}
				}
			}
			if (StrEqual(fname,namechk,false))
				PushArrayCell(arr, thisent);
		}
		findentsarrtargsub(arr,thisent++,namechk,clsname);
	}
	if (GetArraySize(arr) < 1) findentsarr(arr,-1,namechk);
	if (arr != INVALID_HANDLE)
		if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}

public Handle findentsarrtarg(Handle arr, char[] namechk)
{
	if (arr == INVALID_HANDLE) return INVALID_HANDLE;
	findentsarrtargsub(arr,-1,namechk,"*");
	if (arr != INVALID_HANDLE)
		if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}

public Action listents(int client, int args)
{
	if (args < 1)
	{
		if (client == 0) PrintToServer("Must specify targetname or classname");
		else PrintToConsole(client,"Must specify targetname or classname");
		return Plugin_Handled;
	}
	char search[128];
	char fullinf[128];
	GetCmdArg(1,search,sizeof(search));
	if (args > 1) GetCmdArg(2,fullinf,sizeof(fullinf));
	if (strlen(search) > 0)
	{
		Handle arr = CreateArray(64);
		findentsarrtarg(arr,search);
		//Checks must be separate
		if (arr == INVALID_HANDLE)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",search);
			else PrintToConsole(client,"No entities found with either classname or targetname of %s",search);
			return Plugin_Handled;
		}
		else if (GetArraySize(arr) < 1)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",search);
			else PrintToConsole(client,"No entities found with either classname or targetname of %s",search);
			return Plugin_Handled;
		}
		else
		{
			if (client == 0) PrintToServer("There are %i entities that matched %s.",GetArraySize(arr),search);
			else PrintToConsole(client,"There are %i entities that matched %s.",GetArraySize(arr),search);
			char stateinf[1024];
			char scriptinf[512];
			int scrtmpi;
			float scrtmpf;
			for (int i = 0;i<GetArraySize(arr);i++)
			{
				if (StrEqual(fullinf,"full",false))
				{
					stateinf = "";
					scriptinf = "";
					int targ = GetArrayCell(arr,i);
					char ent[128];
					char targname[128];
					char globname[128];
					float vec[3];
					float offsetvec[3];
					float angs[3];
					int parent = 0;
					int ammotype = -1;
					vec[0] = -1.1;
					angs[0] = -1.1;
					char exprsc[24];
					char exprtargname[64];
					char scrtmp[64];
					int doorstate, sleepstate, exprsci;
					GetEntityClassname(targ, ent, sizeof(ent));
					GetEntPropString(targ,Prop_Data,"m_iName",targname,sizeof(targname));
					if (HasEntProp(targ,Prop_Data,"m_iGlobalname"))
						GetEntPropString(targ,Prop_Data,"m_iGlobalname",globname,sizeof(globname));
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",vec);
					if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",offsetvec);
					if (HasEntProp(targ,Prop_Send,"m_angRotation"))
						GetEntPropVector(targ,Prop_Send,"m_angRotation",angs);
					if (HasEntProp(targ,Prop_Data,"m_hParent"))
						parent = GetEntPropEnt(targ,Prop_Data,"m_hParent");
					if (HasEntProp(targ,Prop_Data,"m_nAmmoType"))
						ammotype = GetEntProp(targ,Prop_Data,"m_nAmmoType");
					if (HasEntProp(targ,Prop_Data,"m_hTargetEnt"))
					{
						exprsci = GetEntPropEnt(targ,Prop_Data,"m_hTargetEnt");
						if (IsValidEntity(exprsci))
						{
							GetEntityClassname(exprsci,exprsc,sizeof(exprsc));
							if (HasEntProp(exprsci,Prop_Data,"m_iName"))
								GetEntPropString(exprsci,Prop_Data,"m_iName",exprtargname,sizeof(exprtargname));
						}
					}
					char cmodel[64];
					GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
					int spawnflagsi = GetEntityFlags(targ);
					char inf[256];
					Format(inf,sizeof(inf),"\nID: %i %s %s ",targ,ent,cmodel);
					if (parent > 0)
					{
						char parentname[32];
						if (HasEntProp(parent,Prop_Data,"m_iName"))
							GetEntPropString(parent,Prop_Data,"m_iName",parentname,sizeof(parentname));
						char parentcls[32];
						GetEntityClassname(parent,parentcls,sizeof(parentcls));
						Format(stateinf,sizeof(stateinf),"%sParented to %i %s %s ",stateinf,parent,parentname,parentcls);
					}
					if (HasEntProp(targ,Prop_Data,"m_flRefireTime"))
					{
						float firetime = GetEntPropFloat(targ,Prop_Data,"m_flRefireTime");
						Format(stateinf,sizeof(stateinf),"%sRefireTime %f ",stateinf,firetime);
					}
					if (HasEntProp(targ,Prop_Data,"m_vehicleScript"))
					{
						GetEntPropString(targ,Prop_Data,"m_vehicleScript",scrtmp,sizeof(scrtmp));
						Format(stateinf,sizeof(stateinf),"%sVehicleScript %s ",stateinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_spawnEquipment"))
					{
						GetEntPropString(targ,Prop_Data,"m_spawnEquipment",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sAdditionalEquipment %s ",stateinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_nSkin"))
					{
						int sk = GetEntProp(targ,Prop_Data,"m_nSkin");
						Format(stateinf,sizeof(stateinf),"%sSkin %i ",stateinf,sk);
					}
					if (HasEntProp(targ,Prop_Data,"m_nHardwareType"))
					{
						int hdw = GetEntProp(targ,Prop_Data,"m_nHardwareType");
						Format(stateinf,sizeof(stateinf),"%sHardwareType %i ",stateinf,hdw);
					}
					if (HasEntProp(targ,Prop_Data,"m_state"))
					{
						int istate = GetEntProp(targ,Prop_Data,"m_state");
						Format(stateinf,sizeof(stateinf),"%sState %i ",stateinf,istate);
					}
					if (HasEntProp(targ,Prop_Data,"m_eDoorState"))
					{
						doorstate = GetEntProp(targ,Prop_Data,"m_eDoorState");
						Format(stateinf,sizeof(stateinf),"%sDoorState %i ",stateinf,doorstate);
					}
					if (HasEntProp(targ,Prop_Data,"m_SleepState"))
					{
						sleepstate = GetEntProp(targ,Prop_Data,"m_SleepState");
						Format(stateinf,sizeof(stateinf),"%sSleepState %i ",stateinf,sleepstate);
					}
					if (HasEntProp(targ,Prop_Data,"m_Type"))
					{
						int inpctype = GetEntProp(targ,Prop_Data,"m_Type");
						Format(stateinf,sizeof(stateinf),"%sNPCType %i ",stateinf,inpctype);
					}
					if (StrEqual(ent,"math_counter",false))
					{
						int offset = FindDataMapInfo(targ, "m_OutValue");
						Format(stateinf,sizeof(stateinf),"%sCurrentValue %i ",stateinf,RoundFloat(GetEntDataFloat(targ, offset)));
					}
					if (StrEqual(ent,"env_global",false))
					{
						int offset = FindDataMapInfo(targ, "m_outCounter");
						Format(stateinf,sizeof(stateinf),"%sCurrentValue %i ",stateinf,RoundFloat(GetEntDataFloat(targ, offset)));
					}
					if (HasEntProp(targ,Prop_Data,"m_spawnflags"))
					{
						int sf = GetEntProp(targ,Prop_Data,"m_spawnflags");
						Format(stateinf,sizeof(stateinf),"%sSpawnflags %i ",stateinf,sf);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszSubject"))
					{
						char subj[32];
						GetEntPropString(targ,Prop_Data,"m_iszSubject",subj,sizeof(subj));
						Format(stateinf,sizeof(stateinf),"%sSubject %s ",stateinf,subj);
					}
					if (HasEntProp(targ,Prop_Data,"m_bReciprocal"))
					{
						int recip = GetEntProp(targ,Prop_Data,"m_bReciprocal");
						Format(stateinf,sizeof(stateinf),"%sReciprocal %i ",stateinf,recip);
					}
					if (HasEntProp(targ,Prop_Data,"m_target"))
					{
						char targetstr[64];
						PropFieldType type;
						FindDataMapInfo(targ,"m_target",type);
						if (type == PropField_String)
						{
							GetEntPropString(targ,Prop_Data,"m_target",targetstr,sizeof(targetstr));
							Format(stateinf,sizeof(stateinf),"%sTarget %s ",stateinf,targetstr);
						}
						else if (type == PropField_Entity)
						{
							int targent = GetEntPropEnt(targ,Prop_Data,"m_target");
							if (targent != -1) Format(stateinf,sizeof(stateinf),"%sTarget %i ",stateinf,targent);
						}
					}
					if (HasEntProp(targ,Prop_Data,"m_hVehicle"))
					{
						int targent = GetEntPropEnt(targ,Prop_Data,"m_hVehicle");
						if (targent != -1) Format(stateinf,sizeof(stateinf),"%sVehicle %i ",stateinf,targent);
					}
					if (HasEntProp(targ,Prop_Data,"m_hPlayer"))
					{
						int targent = GetEntPropEnt(targ,Prop_Data,"m_hPlayer");
						if (targent != -1) Format(stateinf,sizeof(stateinf),"%sm_hPlayer %i ",stateinf,targent);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszEntry"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszEntry",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"m_iszEntry %s ",scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszPreIdle"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszPreIdle",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPreIdle %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszPlay"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszPlay",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPlay %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszPostIdle"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszPostIdle",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPostIdle %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszCustomMove"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszCustomMove",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszCustomMove %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszNextScript"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszNextScript",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszNextScript %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszEntity"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszEntity",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszEntity %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_fMoveTo"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_fMoveTo");
						Format(scriptinf,sizeof(scriptinf),"%sm_fMoveTo %i ",scriptinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_flRadius"))
					{
						scrtmpf = GetEntPropFloat(targ,Prop_Data,"m_flRadius");
						if (scrtmpf > 0.0)
							Format(scriptinf,sizeof(scriptinf),"%sm_flRadius %1.f ",scriptinf,scrtmpf);
					}
					if (HasEntProp(targ,Prop_Data,"m_flRepeat"))
					{
						scrtmpf = GetEntPropFloat(targ,Prop_Data,"m_flRepeat");
						Format(scriptinf,sizeof(scriptinf),"%sm_flRepeat %1.f ",scriptinf,scrtmpf);
					}
					if (HasEntProp(targ,Prop_Data,"m_bLoopActionSequence"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_bLoopActionSequence");
						Format(scriptinf,sizeof(scriptinf),"%sm_bLoopActionSequence %i ",scriptinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_bIgnoreGravity"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_bIgnoreGravity");
						Format(scriptinf,sizeof(scriptinf),"%sm_bIgnoreGravity %i ",scriptinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_bSynchPostIdles"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_bSynchPostIdles");
						Format(scriptinf,sizeof(scriptinf),"%sm_bSynchPostIdles %i ",scriptinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_bDisableNPCCollisions"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_bDisableNPCCollisions");
						Format(scriptinf,sizeof(scriptinf),"%sm_bDisableNPCCollisions %i ",scriptinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszTemplateEntityNames[0]"))
					{
						for (int j = 0;j<16;j++)
						{
							char tmpennam[48];
							Format(tmpennam,sizeof(tmpennam),"m_iszTemplateEntityNames[%i]",j);
							GetEntPropString(targ,Prop_Data,tmpennam,scrtmp,sizeof(scrtmp));
							if (strlen(scrtmp) > 0)
							{
								if (j < 9) Format(scriptinf,sizeof(scriptinf),"%sTemplate0%i %s ",scriptinf,j+1,scrtmp);
								else Format(scriptinf,sizeof(scriptinf),"%sTemplate%i %s ",scriptinf,j+1,scrtmp);
							}
						}
					}
					if (HasEntProp(targ,Prop_Data,"m_iszSound"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszSound",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszSound %s ",scriptinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_bCarriedByPlayer"))
					{
						int ownert = GetEntProp(targ,Prop_Data,"m_bCarriedByPlayer");
						int ownerphy = GetEntProp(targ,Prop_Data,"m_bHackedByAlyx");
						//This property seems to exist on a few ents and changes colors/speed/relations
						//SetEntProp(targ,Prop_Data,"m_bHackedByAlyx",1);
						Format(stateinf,sizeof(stateinf),"%sOwner: %i %i ",stateinf,ownert,ownerphy);
					}
					if (HasEntProp(targ,Prop_Data,"m_iDamageType"))
					{
						Format(stateinf,sizeof(stateinf),"%sDamageType: %i ",stateinf,GetEntProp(targ,Prop_Data,"m_iDamageType"));
					}
					if (HasEntProp(targ,Prop_Data,"m_bNegated"))
					{
						Format(stateinf,sizeof(stateinf),"%sNegated: %i ",stateinf,GetEntProp(targ,Prop_Data,"m_bNegated"));
					}
					if (HasEntProp(targ,Prop_Data,"m_iszDamageFilterName"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszDamageFilterName",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sDamageFilter: %s ",stateinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iszTemplateName"))
					{
						GetEntPropString(targ,Prop_Data,"m_iszTemplateName",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sTemplateName: %s ",stateinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_iFilterClass"))
					{
						GetEntPropString(targ,Prop_Data,"m_iFilterClass",scrtmp,sizeof(scrtmp));
						if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sFilterClass: %s ",stateinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_szMapName"))
					{
						char maptochange[128];
						GetEntPropString(targ,Prop_Data,"m_szMapName",maptochange,sizeof(maptochange));
						if (HasEntProp(targ,Prop_Data,"m_szLandmarkName"))
						{
							char landmark[64];
							GetEntPropString(targ,Prop_Data,"m_szLandmarkName",landmark,sizeof(landmark));
							Format(scriptinf,sizeof(scriptinf),"%sMap %s Landmark %s ",scriptinf,maptochange,landmark);
						}
						else Format(scriptinf,sizeof(scriptinf),"%sMap %s ",scriptinf,maptochange);
					}
					if (HasEntProp(targ,Prop_Data,"m_iDisabled"))
					{
						Format(stateinf,sizeof(stateinf),"%sStartDisabled %i ",stateinf,GetEntProp(targ,Prop_Data,"m_iDisabled"));
					}
					if (HasEntProp(targ,Prop_Data,"m_bDisabled"))
					{
						Format(stateinf,sizeof(stateinf),"%sDisabled %i ",stateinf,GetEntProp(targ,Prop_Data,"m_bDisabled"));
					}
					if ((StrContains(ent,"func_",false) == 0) && (HasEntProp(targ,Prop_Data,"m_toggle_state")))
					{
						int togglestate = GetEntProp(targ,Prop_Data,"m_toggle_state");
						if (togglestate == 1) Format(stateinf,sizeof(stateinf),"%sToggleState %i (Closed) ",stateinf,togglestate);
						else if (togglestate == 0) Format(stateinf,sizeof(stateinf),"%sToggleState %i (Open) ",stateinf,togglestate);
						else Format(stateinf,sizeof(stateinf),"%sToggleState %i ",stateinf,togglestate);
					}
					if ((StrEqual(ent,"func_brush",false)) && (HasEntProp(targ,Prop_Data,"m_fEffects")))
					{
						int enablestate = GetEntProp(targ,Prop_Data,"m_fEffects");
						if (enablestate == 32) Format(stateinf,sizeof(stateinf),"%sToggleState: Disabled ",stateinf);
						else Format(stateinf,sizeof(stateinf),"%sToggleState: Enabled ",stateinf);
					}
					if ((StrContains(ent,"trigger_",false) == 0) && (HasEntProp(targ,Prop_Data,"m_bDisabled")))
					{
						int enablestate = GetEntProp(targ,Prop_Data,"m_bDisabled");
						if (enablestate == 1) Format(stateinf,sizeof(stateinf),"%sToggleState: Disabled ",stateinf);
						else Format(stateinf,sizeof(stateinf),"%sToggleState: Enabled ",stateinf);
					}
					if (HasEntProp(targ,Prop_Send,"m_hEnt"))
					{
						int hEnt = GetEntPropEnt(targ,Prop_Send,"m_hEnt");
						Format(stateinf,sizeof(stateinf),"%sm_hEnt: %i ",stateinf,hEnt);
					}
					if (HasEntProp(targ,Prop_Send,"m_pPlayer"))
					{
						int hEnt = GetEntPropEnt(targ,Prop_Send,"m_pPlayer");
						Format(stateinf,sizeof(stateinf),"%sm_pPlayer: %i ",stateinf,hEnt);
					}
					if (HasEntProp(targ,Prop_Data,"m_hLinkedPortal"))
					{
						int hEnt = GetEntPropEnt(targ,Prop_Data,"m_hLinkedPortal");
						Format(stateinf,sizeof(stateinf),"%sm_hLinkedPortal: %i ",stateinf,hEnt);
					}
					if (HasEntProp(targ,Prop_Data,"m_bActivated"))
					{
						int hEnt = GetEntProp(targ,Prop_Data,"m_bActivated");
						Format(stateinf,sizeof(stateinf),"%sm_bActivated: %i ",stateinf,hEnt);
					}
					if (HasEntProp(targ,Prop_Data,"m_bInReload"))
					{
						int rel = GetEntProp(targ,Prop_Data,"m_bInReload");
						Format(stateinf,sizeof(stateinf),"%s\nm_bInReload: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Data,"m_bFireOnEmpty"))
					{
						int rel = GetEntProp(targ,Prop_Data,"m_bFireOnEmpty");
						Format(stateinf,sizeof(stateinf),"%sm_bFireOnEmpty: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Data,"m_iPrimaryAmmoType"))
					{
						int rel = GetEntProp(targ,Prop_Data,"m_iPrimaryAmmoType");
						Format(stateinf,sizeof(stateinf),"%sm_iPrimaryAmmoType: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Data,"m_iSecondaryAmmoType"))
					{
						int rel = GetEntProp(targ,Prop_Data,"m_iSecondaryAmmoType");
						Format(stateinf,sizeof(stateinf),"%sm_iSecondaryAmmoType: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Send,"m_iEntityQuality"))
					{
						int rel = GetEntProp(targ,Prop_Send,"m_iEntityQuality");
						Format(stateinf,sizeof(stateinf),"%sm_iEntityQuality: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Send,"m_iEntityLevel"))
					{
						int rel = GetEntProp(targ,Prop_Send,"m_iEntityLevel");
						Format(stateinf,sizeof(stateinf),"%sm_iEntityLevel: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Send,"m_iItemDefinitionIndex"))
					{
						int rel = GetEntProp(targ,Prop_Send,"m_iItemDefinitionIndex");
						Format(stateinf,sizeof(stateinf),"%sm_iItemDefinitionIndex: %i ",stateinf,rel);
					}
					if (HasEntProp(targ,Prop_Data,"m_nDissolveType"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nDissolveType");
						Format(stateinf,sizeof(stateinf),"%sm_nDissolveType: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_nBeamType"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nBeamType");
						Format(stateinf,sizeof(stateinf),"%sm_nBeamType: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_nBeamFlags"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nBeamFlags");
						Format(stateinf,sizeof(stateinf),"%sm_nBeamFlags: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_nNumBeamEnts"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nNumBeamEnts");
						Format(stateinf,sizeof(stateinf),"%sm_nNumBeamEnts: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_fAmplitude"))
					{
						scrtmpf = GetEntPropFloat(targ,Prop_Data,"m_fAmplitude");
						Format(stateinf,sizeof(stateinf),"%sm_fAmplitude: %1.1f ",stateinf,scrtmpf);
					}
					if (HasEntProp(targ,Prop_Data,"m_fWidth"))
					{
						scrtmpf = GetEntPropFloat(targ,Prop_Data,"m_fWidth");
						Format(stateinf,sizeof(stateinf),"%sm_fWidth: %1.1f ",stateinf,scrtmpf);
					}
					if (HasEntProp(targ,Prop_Data,"m_fEndWidth"))
					{
						scrtmpf = GetEntPropFloat(targ,Prop_Data,"m_fEndWidth");
						Format(stateinf,sizeof(stateinf),"%sm_fEndWidth: %1.1f ",stateinf,scrtmpf);
					}
					if (HasEntProp(targ,Prop_Data,"m_nHaloIndex"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nHaloIndex");
						Format(stateinf,sizeof(stateinf),"%sm_nHaloIndex: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_fHaloScale"))
					{
						scrtmpf = GetEntPropFloat(targ,Prop_Data,"m_fHaloScale");
						Format(stateinf,sizeof(stateinf),"%sm_fHaloScale: %1.1f ",stateinf,scrtmpf);
					}
					if (HasEntProp(targ,Prop_Data,"m_nRenderMode"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nRenderMode");
						Format(stateinf,sizeof(stateinf),"%s\nm_nRenderMode: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_nRenderFX"))
					{
						scrtmpi = GetEntProp(targ,Prop_Data,"m_nRenderFX");
						Format(stateinf,sizeof(stateinf),"%sm_nRenderFX: %i ",stateinf,scrtmpi);
					}
					if (HasEntProp(targ,Prop_Data,"m_vecEndPos"))
					{
						float vecTmp[3];
						GetEntPropVector(targ,Prop_Data,"m_vecEndPos",vecTmp);
						Format(stateinf,sizeof(stateinf),"%sm_vecEndPos: %1.1f %1.1f %1.1f ",stateinf,vecTmp[0],vecTmp[1],vecTmp[2]);
					}
					if ((HasEntProp(targ,Prop_Data,"m_iHealth")) && (HasEntProp(targ,Prop_Data,"m_iMaxHealth")))
					{
						int targh = GetEntProp(targ,Prop_Data,"m_iHealth");
						int targmh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
						int held = -1;
						if (HasEntProp(targ,Prop_Data,"m_bHeld"))
							held = GetEntProp(targ,Prop_Data,"m_bHeld");
						if (held != -1)
						{
							Format(stateinf,sizeof(stateinf),"%sHealth: %i Max Health: %i Held: %i",stateinf,targh,targmh,held);
						}
						else
						{
							Format(stateinf,sizeof(stateinf),"%sHealth: %i Max Health: %i",stateinf,targh,targmh);
						}
					}
					if (HasEntProp(targ,Prop_Data,"m_iszTemplateData"))
					{
						char scrtmplarger[512];
						GetEntPropString(targ,Prop_Data,"m_iszTemplateData",scrtmplarger,sizeof(scrtmplarger));
						if (strlen(scrtmplarger) > 0) Format(stateinf,sizeof(stateinf),"%s\nTemplateData: %s ",stateinf,scrtmplarger);
					}
					TrimString(stateinf);
					TrimString(scriptinf);
					if (strlen(targname) > 0)
						Format(inf,sizeof(inf),"%sName: %s ",inf,targname);
					if (strlen(globname) > 0)
						Format(inf,sizeof(inf),"%sGlobalName: %s ",inf,globname);
					if (ammotype != -1)
						Format(inf,sizeof(inf),"%sAmmoType: %i",inf,ammotype);
					if (spawnflagsi != 0)
						Format(inf,sizeof(inf),"%sEntSpawnflags: %i",inf,spawnflagsi);
					if (vec[0] != -1.1)
						Format(inf,sizeof(inf),"%s\nOrigin %f %f %f",inf,vec[0],vec[1],vec[2]);
					if (offsetvec[0] != -1.1)
						Format(inf,sizeof(inf),"%s\nOffset parent origin %f %f %f",inf,offsetvec[0],offsetvec[1],offsetvec[2]);
					if (angs[0] != -1.1)
						Format(inf,sizeof(inf),"%s Ang: %i %i %i",inf,RoundFloat(angs[0]),RoundFloat(angs[1]),RoundFloat(angs[2]));
					if (strlen(exprsc) > 0)
						Format(inf,sizeof(inf),"%s\nTarget: %s %i %s",inf,exprsc,exprsci,exprtargname);
					if ((strlen(scriptinf) > 1) && (strlen(stateinf) < 1)) PrintToConsole(client,"%s\n%s",inf,scriptinf);
					if ((strlen(stateinf) > 1) && (strlen(scriptinf) < 1)) PrintToConsole(client,"%s\n%s",inf,stateinf);
					if ((strlen(stateinf) > 1) && (strlen(scriptinf) > 1)) PrintToConsole(client,"%s\n%s\n%s",inf,stateinf,scriptinf);
					if ((strlen(stateinf) < 1) && (strlen(scriptinf) < 1)) PrintToConsole(client,"%s",inf);
					if (client != 0)
					{
						float clorigin[3];
						GetClientAbsOrigin(client,clorigin);
						float chkdist = GetVectorDistance(clorigin,vec,false);
						if (chkdist < 500.0)
						{
							PrintToConsole(client,"%i %s is %1.f away from you.",targ,targname,chkdist);
						}
					}
				}
				else
				{
					int j = GetArrayCell(arr,i);
					char clsname[32];
					GetEntityClassname(j,clsname,sizeof(clsname));
					char fname[64];
					float entorigin[3];
					if (HasEntProp(j,Prop_Data,"m_iName"))
						GetEntPropString(j,Prop_Data,"m_iName",fname,sizeof(fname));
					if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",entorigin);
					else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",entorigin);
					char displaymsg[256];
					Format(displaymsg,sizeof(displaymsg),"ID: %i %s %s Origin %f %f %f",j,clsname,fname,entorigin[0],entorigin[1],entorigin[2]);
					if ((StrEqual(clsname,"func_brush",false)) && (HasEntProp(j,Prop_Data,"m_fEffects")))
					{
						int enablestate = GetEntProp(j,Prop_Data,"m_fEffects");
						if (enablestate == 32) Format(displaymsg,sizeof(displaymsg),"%s ToggleState: Disabled",displaymsg);
						else Format(displaymsg,sizeof(displaymsg),"%s ToggleState: Enabled",displaymsg);
					}
					else if ((StrContains(clsname,"trigger_",false) == 0) && (HasEntProp(j,Prop_Data,"m_bDisabled")))
					{
						int enablestate = GetEntProp(j,Prop_Data,"m_bDisabled");
						if (enablestate == 1) Format(displaymsg,sizeof(displaymsg),"%s ToggleState: Disabled ",displaymsg);
						else Format(displaymsg,sizeof(displaymsg),"%s ToggleState: Enabled ",displaymsg);
					}
					if (client == 0) PrintToServer("%s",displaymsg);
					else PrintToConsole(client,"%s",displaymsg);
					if (client != 0)
					{
						float clorigin[3];
						GetClientAbsOrigin(client,clorigin);
						float chkdist = GetVectorDistance(clorigin,entorigin,false);
						if (chkdist < 500.0)
						{
							PrintToConsole(client,"%i %s is %1.f away from you.",j,fname,chkdist);
						}
					}
				}
			}
		}
		CloseHandle(arr);
	}
	return Plugin_Handled;
}

public Action moveentity(int client, int args)
{
	bool bOverridePos = false;
	if (args < 1)
	{
		PrintToConsole(client,"Must specify targetname or classname");
		return Plugin_Handled;
	}
	else if (args < 4)
	{
		char szChk[32];
		GetCmdArg(2,szChk,sizeof(szChk));
		if ((StrEqual(szChk,"!picker",false)) || (StrEqual(szChk,"!self",false)))
		{
			bOverridePos = true;
		}
		else
		{
			PrintToConsole(client,"Must specify origin");
			return Plugin_Handled;
		}
	}
	else if ((args > 4) && (args < 7))
	{
		PrintToConsole(client,"Must specify all angles to set or just origin");
		return Plugin_Handled;
	}
	char search[64];
	GetCmdArg(1,search,sizeof(search));
	char xch[16];
	char ych[16];
	char zch[16];
	if (bOverridePos)
	{
		GetCmdArg(2,xch,sizeof(xch));
		float vecOrgs[3];
		if (StrEqual(xch,"!self",false))
		{
			if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",vecOrgs);
			else if (HasEntProp(client,Prop_Data,"m_vecOrigin")) GetEntPropVector(client,Prop_Data,"m_vecOrigin",vecOrgs);
			Format(xch,sizeof(xch),"%1.1f",vecOrgs[0]);
			Format(ych,sizeof(ych),"%1.1f",vecOrgs[1]);
			Format(zch,sizeof(zch),"%1.1f",vecOrgs[2]);
		}
		else if (StrEqual(xch,"!picker",false))
		{
			if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",vecOrgs);
			else if (HasEntProp(client,Prop_Data,"m_vecOrigin")) GetEntPropVector(client,Prop_Data,"m_vecOrigin",vecOrgs);
			float vecAngs[3];
			if (client > 0) GetClientEyeAngles(client,vecAngs);
			vecOrgs[2]+=62.0;
			vecOrgs[0] = (vecOrgs[0] + (10 * Cosine(DegToRad(vecAngs[1]))));
			vecOrgs[1] = (vecOrgs[1] + (10 * Sine(DegToRad(vecAngs[1]))));
			vecOrgs[2] = (vecOrgs[2] + 10);
			TR_TraceRay(vecOrgs,vecAngs,MASK_SHOT,RayType_Infinite);
			TR_GetEndPosition(vecOrgs,INVALID_HANDLE);
			vecOrgs[2]+=2.0;
			Format(xch,sizeof(xch),"%1.1f",vecOrgs[0]);
			Format(ych,sizeof(ych),"%1.1f",vecOrgs[1]);
			Format(zch,sizeof(zch),"%1.1f",vecOrgs[2]);
		}
	}
	else
	{
		GetCmdArg(2,xch,sizeof(xch));
		GetCmdArg(3,ych,sizeof(ych));
		GetCmdArg(4,zch,sizeof(zch));
	}
	if (strlen(search) > 0)
	{
		Handle arr = CreateArray(64);
		if (StrEqual(search,"!picker",false))
		{
			int targ = GetClientAimTarget(client, false);
			if (targ != -1)
			{
				PushArrayCell(arr,targ);
			}
		}
		else
			findentsarrtarg(arr,search);
		//Checks must be separate
		if (arr == INVALID_HANDLE)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",search);
			else PrintToConsole(client,"No entities found with either classname or targetname of %s",search);
			return Plugin_Handled;
		}
		else if (GetArraySize(arr) < 1)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",search);
			else PrintToConsole(client,"No entities found with either classname or targetname of %s",search);
			return Plugin_Handled;
		}
		else
		{
			for (int i = 0;i<GetArraySize(arr);i++)
			{
				int targ = GetArrayCell(arr,i);
				char pich[16];
				char yawch[16];
				char rolch[16];
				float tporgs[3];
				float tpangs[3];
				if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",tporgs);
				else if (HasEntProp(targ,Prop_Send,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecAbsOrigin",tporgs);
				if (HasEntProp(targ,Prop_Send,"m_vecAngles")) GetEntPropVector(targ,Prop_Send,"m_vecAngles",tpangs);
				else if (HasEntProp(targ,Prop_Data,"m_angAbsRotation")) GetEntPropVector(targ,Prop_Data,"m_angAbsRotation",tpangs);
				else if (HasEntProp(targ,Prop_Send,"m_angAbsRotation")) GetEntPropVector(targ,Prop_Send,"m_angAbsRotation",tpangs);
				if (StrContains(xch,"+",false) == 0)
				{
					ReplaceString(xch,sizeof(xch),"+","");
					tporgs[0]+=StringToFloat(xch);
				}
				else if (StrContains(xch,"--",false) == 0)
				{
					ReplaceString(xch,sizeof(xch),"-","");
					tporgs[0]-=StringToFloat(xch);
				}
				else if (!StrEqual(xch,"same",false))
					tporgs[0] = StringToFloat(xch);
				if (StrContains(ych,"+",false) == 0)
				{
					ReplaceString(ych,sizeof(ych),"+","");
					tporgs[1]+=StringToFloat(ych);
				}
				else if (StrContains(ych,"--",false) == 0)
				{
					ReplaceString(ych,sizeof(ych),"-","");
					tporgs[1]-=StringToFloat(ych);
				}
				else if (!StrEqual(ych,"same",false))
					tporgs[1] = StringToFloat(ych);
				if (StrContains(zch,"+",false) == 0)
				{
					ReplaceString(zch,sizeof(zch),"+","");
					tporgs[2]+=StringToFloat(zch);
				}
				else if (StrContains(zch,"--",false) == 0)
				{
					ReplaceString(zch,sizeof(zch),"-","");
					tporgs[2]-=StringToFloat(zch);
				}
				else if (!StrEqual(zch,"same",false))
					tporgs[2] = StringToFloat(zch);
				if (args > 6)
				{
					GetCmdArg(5,pich,sizeof(pich));
					GetCmdArg(6,yawch,sizeof(yawch));
					GetCmdArg(7,rolch,sizeof(rolch));
					if (StrContains(pich,"+",false) == 0)
					{
						ReplaceString(pich,sizeof(pich),"+","");
						tpangs[0]+=StringToFloat(pich);
					}
					else if (StrContains(pich,"--",false) == 0)
					{
						ReplaceString(pich,sizeof(pich),"-","");
						tpangs[0]-=StringToFloat(pich);
					}
					else if (!StrEqual(pich,"same",false))
						tpangs[0] = StringToFloat(pich);
					if (StrContains(yawch,"+",false) == 0)
					{
						ReplaceString(yawch,sizeof(yawch),"+","");
						tpangs[1]+=StringToFloat(yawch);
					}
					else if (StrContains(yawch,"--",false) == 0)
					{
						ReplaceString(yawch,sizeof(yawch),"-","");
						tpangs[1]-=StringToFloat(yawch);
					}
					else if (!StrEqual(yawch,"same",false))
						tpangs[1] = StringToFloat(yawch);
					if (StrContains(rolch,"+",false) == 0)
					{
						ReplaceString(rolch,sizeof(rolch),"+","");
						tpangs[2]+=StringToFloat(rolch);
					}
					else if (StrContains(rolch,"--",false) == 0)
					{
						ReplaceString(rolch,sizeof(rolch),"-","");
						tpangs[2]-=StringToFloat(rolch);
					}
					else if (!StrEqual(rolch,"same",false))
						tpangs[2] = StringToFloat(rolch);
				}
				TeleportEntity(targ,tporgs,tpangs,NULL_VECTOR);
				if (client == 0) PrintToServer("Moved %i to origin %f %f %f angles %f %f %f",targ,tporgs[0],tporgs[1],tporgs[2],tpangs[0],tpangs[1],tpangs[2]);
				else PrintToConsole(client,"Moved %i to origin %f %f %f angles %f %f %f",targ,tporgs[0],tporgs[1],tporgs[2],tpangs[0],tpangs[1],tpangs[2]);
			}
		}
	}
	return Plugin_Handled;
}

public Action getinf(int client, int args)
{
	if (client == 0)
	{
		if ((IsValidEntity(1)) && (!IsDedicatedServer())) client = 1;
		else return Plugin_Handled;
	}
	int targ = GetClientAimTarget(client, false);
	if (targ != -1)
	{
		char ent[32];
		char targname[64];
		char globname[64];
		float vec[3];
		float angs[3];
		int parent = 0;
		int ammotype = -1;
		vec[0] = -1.1;
		angs[0] = -1.1;
		char exprsc[24];
		char exprtargname[64];
		int exprsci;
		int collgroup = -1;
		GetEntityClassname(targ, ent, sizeof(ent));
		GetEntPropString(targ,Prop_Data,"m_iName",targname,sizeof(targname));
		if (HasEntProp(targ,Prop_Data,"m_iGlobalname"))
			GetEntPropString(targ,Prop_Data,"m_iGlobalname",globname,sizeof(globname));
		if (HasEntProp(targ,Prop_Send,"m_vecOrigin"))
			GetEntPropVector(targ,Prop_Send,"m_vecOrigin",vec);
		if (HasEntProp(targ,Prop_Send,"m_angRotation"))
			GetEntPropVector(targ,Prop_Send,"m_angRotation",angs);
		if (HasEntProp(targ,Prop_Data,"m_hParent"))
			parent = GetEntPropEnt(targ,Prop_Data,"m_hParent");
		if (HasEntProp(targ,Prop_Data,"m_nAmmoType"))
			ammotype = GetEntProp(targ,Prop_Data,"m_nAmmoType");
		if (HasEntProp(targ,Prop_Data,"m_hTargetEnt"))
		{
			exprsci = GetEntPropEnt(targ,Prop_Data,"m_hTargetEnt");
			if (IsValidEntity(exprsci))
			{
				GetEntityClassname(exprsci,exprsc,sizeof(exprsc));
				if (HasEntProp(exprsci,Prop_Data,"m_iName"))
					GetEntPropString(exprsci,Prop_Data,"m_iName",exprtargname,sizeof(exprtargname));
			}
		}
		if (HasEntProp(targ,Prop_Data,"m_CollisionGroup"))
			collgroup = GetEntProp(targ,Prop_Data,"m_CollisionGroup");
		char cmodel[64];
		GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
		int spawnflagsi = GetEntityFlags(targ);
		int spawnflagse = GetEntProp(targ,Prop_Data,"m_spawnflags");
		PrintToChat(client,"%i %s %s",targ,ent,cmodel);
		if (parent > 0)
		{
			char parentname[32];
			if (HasEntProp(parent,Prop_Data,"m_iName"))
				GetEntPropString(parent,Prop_Data,"m_iName",parentname,sizeof(parentname));
			char parentcls[32];
			GetEntityClassname(parent,parentcls,sizeof(parentcls));
			PrintToChat(client,"Parented to %i %s %s",parent,parentname,parentcls);
		}
		char inf[172];
		if (strlen(targname) > 0)
			Format(inf,sizeof(inf),"Name: %s ",targname);
		if (strlen(globname) > 0)
			Format(inf,sizeof(inf),"%sGlobalName: %s ",inf,globname);
		if (ammotype != -1)
			Format(inf,sizeof(inf),"%sAmmoType: %i",inf,ammotype);
		if ((spawnflagsi != 0) || (spawnflagse != 0))
			Format(inf,sizeof(inf),"%sSpawnflags: %i EntSpawnFlags: %i",inf,spawnflagsi,spawnflagse);
		if (vec[0] != -1.1)
			Format(inf,sizeof(inf),"%s\nOrigin %i %i %i",inf,RoundFloat(vec[0]),RoundFloat(vec[1]),RoundFloat(vec[2]));
		if (angs[0] != -1.1)
			Format(inf,sizeof(inf),"%s Ang: %i %i %i",inf,RoundFloat(angs[0]),RoundFloat(angs[1]),RoundFloat(angs[2]));
		if (collgroup != -1)
			Format(inf,sizeof(inf),"%s CollisionGroup %i",inf,collgroup);
		if (strlen(exprsc) > 0)
			Format(inf,sizeof(inf),"%s\nTarget: %s %i %s",inf,exprsc,exprsci,exprtargname);
		if (HasEntProp(targ,Prop_Data,"m_vehicleScript"))
		{
			char vehscript[128];
			GetEntPropString(targ,Prop_Data,"m_vehicleScript",vehscript,sizeof(vehscript));
			if (strlen(vehscript) > 0)
				Format(inf,sizeof(inf),"%s\nVehicleScript: %s",inf,vehscript);
		}
		PrintToChat(client,"%s",inf);
		if (HasEntProp(targ,Prop_Data,"m_szMapName"))
		{
			char maptochange[128];
			GetEntPropString(targ,Prop_Data,"m_szMapName",maptochange,sizeof(maptochange));
			if (HasEntProp(targ,Prop_Data,"m_szLandmarkName"))
			{
				char landmark[64];
				GetEntPropString(targ,Prop_Data,"m_szLandmarkName",landmark,sizeof(landmark));
				PrintToChat(client,"Map %s Landmark %s",maptochange,landmark);
			}
			else PrintToChat(client,"Map %s",maptochange);
		}
		if (HasEntProp(targ,Prop_Data,"m_bCarriedByPlayer"))
		{
			int ownert = GetEntProp(targ,Prop_Data,"m_bCarriedByPlayer");
			int ownerphy = GetEntProp(targ,Prop_Data,"m_bHackedByAlyx");
			//This property seems to exist on a few ents and changes colors/speed/relations
			//SetEntProp(targ,Prop_Data,"m_bHackedByAlyx",1);
			PrintToChat(client,"Owner: %i %i",ownert,ownerphy);
		}
		if ((HasEntProp(targ,Prop_Data,"m_iHealth")) && (HasEntProp(targ,Prop_Data,"m_iMaxHealth")))
		{
			int targh = GetEntProp(targ,Prop_Data,"m_iHealth");
			int targmh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
			int held = -1;
			if (HasEntProp(targ,Prop_Data,"m_bHeld"))
				held = GetEntProp(targ,Prop_Data,"m_bHeld");
			if (held != -1)
				PrintToChat(client,"Health: %i Max Health: %i Held: %i",targh,targmh,held);
			else
				PrintToChat(client,"Health: %i Max Health: %i",targh,targmh);
		}
	}
	return Plugin_Handled;
}

public Action sett(int client, int args)
{
	int targ = GetClientAimTarget(client, false);
	if ((targ != -1) && (args > 0))
	{
		char ent[32];
		char targname[64];
		char arg2[64];
		GetCmdArg(1, arg2, sizeof(arg2));
		GetEntityClassname(targ, ent, sizeof(ent));
		DispatchKeyValue(targ,"targetname",arg2);
		ActivateEntity(targ);
		char cmodel[64];
		GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
		GetEntPropString(targ,Prop_Data,"m_iName",targname,sizeof(targname));
		PrintToConsole(client,"%s %s %s",ent,targname,cmodel);
	}
	else
	{
		PrintToConsole(client,"Not enough args, or invalid target");
	}
	return Plugin_Handled;
}

public Action setprops(int client, int args)
{
	char first[64];
	char typechk[64];
	GetCmdArg(1, first, sizeof(first));
	bool pdata = false;
	char pdatachk[64];
	if (args >= 4)
	{
		GetCmdArg(4,pdatachk,sizeof(pdatachk));
		if ((StrEqual(pdatachk,"prop_data",false)) || (StrEqual(pdatachk,"1",false)))
			pdata = true;
		if (args > 4)
		{
			GetCmdArg(5,typechk,sizeof(typechk));
		}
	}
	Handle arr = CreateArray(64);
	if (StrEqual(first,"!self",false))
		PushArrayCell(arr,client);
	else if (StrEqual(first,"!mywep",false))
	{
		if (HasEntProp(client,Prop_Data,"m_hActiveWeapon"))
		{
			int wep = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
			if (wep != -1) PushArrayCell(arr,wep);
		}
	}
	else if (StrEqual(first,"!picker",false))
		PushArrayCell(arr,GetClientAimTarget(client, false));
	else if ((StringToInt(first) != 0) && (strlen(first) > 0))
		PushArrayCell(arr,StringToInt(first));
	else
	{
		findentsarrtarg(arr,first);
	}
	if (arr == INVALID_HANDLE)
	{
		if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",first);
		else PrintToConsole(client,"No entities found with either classname or targetname of %s",first);
		return Plugin_Handled;
	}
	else if (GetArraySize(arr) < 1)
	{
		if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",first);
		else PrintToConsole(client,"No entities found with either classname or targetname of %s",first);
		return Plugin_Handled;
	}
	char propinf[512];
	char cls[64];
	for (int i = 0;i<GetArraySize(arr);i++)
	{
		int targ = GetArrayCell(arr,i);
		if ((targ != -1) && (IsValidEntity(targ)))
		{
			char propname[64];
			if (args == 2)
			{
				GetCmdArg(2, propname, sizeof(propname));
				bool datatypeunsupported = false;
				GetEntityClassname(targ,cls,sizeof(cls));
				PropFieldType datamaptype;
				int datamapoffs = FindDataMapInfo(targ,propname,datamaptype);
				if (StrEqual(propname,"classname",false))
					Format(propname,sizeof(propname),"m_iClassname");
				else if (StrEqual(propname,"model",false))
					Format(propname,sizeof(propname),"m_ModelName");
				if (HasEntProp(targ,Prop_Send,propname))
				{
					PropFieldType type;
					char srvcls[64];
					GetEntityNetClass(targ,srvcls,sizeof(srvcls));
					FindSendPropInfo(srvcls,propname,type);
					if (type == PropField_Unsupported) datatypeunsupported = true;
					if (type == PropField_String)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								GetEntPropString(targ,Prop_Send,propname,propinf,sizeof(propinf),j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
								else PrintToConsole(client,"%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
							}
						}
						else
						{
							GetEntPropString(targ,Prop_Send,propname,propinf,sizeof(propinf));
							if (client == 0) PrintToServer("%i %s %s is %s",targ,cls,propname,propinf);
							else PrintToConsole(client,"%i %s %s is %s",targ,cls,propname,propinf);
						}
					}
					else if (type == PropField_Entity)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								int enth = GetEntPropEnt(targ,Prop_Send,propname,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enth);
								else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enth);
							}
						}
						else
						{
							int enth = GetEntPropEnt(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s %s is %i",targ,cls,propname,enth);
							else PrintToConsole(client,"%i %s %s is %i",targ,cls,propname,enth);
						}
					}
					else if (type == PropField_Integer)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								int enti = GetEntProp(targ,Prop_Send,propname,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enti);
								else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enti);
							}
						}
						else
						{
							int enti = GetEntProp(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s %s is %i",targ,cls,propname,enti);
							else PrintToConsole(client,"%i %s %s is %i",targ,cls,propname,enti);
						}
					}
					else if (type == PropField_Float)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								float entf = GetEntPropFloat(targ,Prop_Send,propname,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %f",targ,cls,propname,j,entf);
								else PrintToConsole(client,"%i %s %s [%i] is %f",targ,cls,propname,j,entf);
							}
						}
						else
						{
							float entf = GetEntPropFloat(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s %s is %f",targ,cls,propname,entf);
							else PrintToConsole(client,"%i %s %s is %f",targ,cls,propname,entf);
						}
					}
					else if (type == PropField_Vector)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								float entvec[3];
								GetEntPropVector(targ,Prop_Send,propname,entvec,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
								else PrintToConsole(client,"%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
							}
						}
						else
						{
							float entvec[3];
							GetEntPropVector(targ,Prop_Send,propname,entvec);
							if (client == 0) PrintToServer("%i %s %s is %f %f %f",targ,cls,propname,entvec[0],entvec[1],entvec[2]);
							else PrintToConsole(client,"%i %s %s is %f %f %f",targ,cls,propname,entvec[0],entvec[1],entvec[2]);
						}
					}
				}
				if (HasEntProp(targ,Prop_Data,propname))
				{
					PropFieldType type;
					FindDataMapInfo(targ,propname,type);
					if (type == PropField_Unsupported) datatypeunsupported = true;
					if ((type == PropField_String) || (type == PropField_String_T))
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								GetEntPropString(targ,Prop_Data,propname,propinf,sizeof(propinf),j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
								else PrintToConsole(client,"%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
							}
						}
						else
						{
							GetEntPropString(targ,Prop_Data,propname,propinf,sizeof(propinf));
							if (client == 0) PrintToServer("%i %s is %s",targ,propname,propinf);
							else PrintToConsole(client,"%i %s is %s",targ,propname,propinf);
						}
					}
					else if (type == PropField_Entity)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								int enth = GetEntPropEnt(targ,Prop_Data,propname,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enth);
								else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enth);
							}
						}
						else
						{
							int enth = GetEntPropEnt(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s is %i",targ,propname,enth);
							else PrintToConsole(client,"%i %s is %i",targ,propname,enth);
						}
					}
					else if (type == PropField_Integer)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							bool useelement = false;
							if (StrEqual(propname,"m_iAmmo",false)) useelement = true;
							for (int j = 0;j<arrsize;j++)
							{
								int enti = 0;
								if (!useelement) enti = GetEntProp(targ,Prop_Data,propname,j);
								else enti = GetEntProp(targ,Prop_Data,propname,_,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enti);
								else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enti);
							}
						}
						else
						{
							int enti = GetEntProp(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s is %i",targ,propname,enti);
							else PrintToConsole(client,"%i %s is %i",targ,propname,enti);
						}
					}
					else if (type == PropField_Float)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								float entf = GetEntPropFloat(targ,Prop_Data,propname,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %f",targ,cls,propname,j,entf);
								else PrintToConsole(client,"%i %s %s [%i] is %f",targ,cls,propname,j,entf);
							}
						}
						else
						{
							float entf = GetEntPropFloat(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s is %f",targ,propname,entf);
							else PrintToConsole(client,"%i %s is %f",targ,propname,entf);
						}
					}
					else if (type == PropField_Vector)
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							for (int j = 0;j<arrsize;j++)
							{
								float entvec[3];
								GetEntPropVector(targ,Prop_Data,propname,entvec,j);
								if (client == 0) PrintToServer("%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
								else PrintToConsole(client,"%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
							}
						}
						else
						{
							float entvec[3];
							GetEntPropVector(targ,Prop_Data,propname,entvec);
							if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
							else PrintToConsole(client,"%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
						}
					}
				}
				if ((datamapoffs != -1) && (!HasEntProp(targ,Prop_Data,propname)) && (!HasEntProp(targ,Prop_Send,propname)))
				{
					if ((datamaptype == PropField_String) || (datamaptype == PropField_String_T))
					{
						GetEntDataString(targ,datamapoffs,propinf,sizeof(propinf));
						if (client == 0) PrintToServer("%i %s %s is %s",targ,cls,propname,propinf);
						else PrintToConsole(client,"%i %s %s is %s",targ,cls,propname,propinf);
					}
					else if (datamaptype == PropField_Entity)
					{
						int enth = GetEntDataEnt2(targ,datamapoffs);
						if (client == 0) PrintToServer("%i %s is %i",targ,propname,enth);
						else PrintToConsole(client,"%i %s is %i",targ,propname,enth);
					}
					else if (datamaptype == PropField_Integer)
					{
						int enti = GetEntData(targ,datamapoffs,4);
						if (client == 0) PrintToServer("%i %s is %i",targ,propname,enti);
						else PrintToConsole(client,"%i %s is %i",targ,propname,enti);
					}
					else if (datamaptype == PropField_Float)
					{
						float entf = GetEntDataFloat(targ,datamapoffs);
						if (client == 0) PrintToServer("%i %s is %f",targ,propname,entf);
						else PrintToConsole(client,"%i %s is %f",targ,propname,entf);
					}
					else if (datamaptype == PropField_Vector)
					{
						float entvec[3];
						GetEntDataVector(targ,datamapoffs,entvec);
						if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
						else PrintToConsole(client,"%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
					}
					else datamapoffs = -1;
				}
				if (((!HasEntProp(targ,Prop_Data,propname)) && (!HasEntProp(targ,Prop_Send,propname)) || (datatypeunsupported)) && (datamapoffs == -1))
				{
					if (client == 0) PrintToServer("%i %s doesn't have the %s property, or the type is unsupported.",targ,cls,propname);
					else PrintToConsole(client,"%i %s doesn't have the %s property, or the type is unsupported.",targ,cls,propname);
				}
			}
			else
			{
				bool usefloat = false;
				bool usestring = false;
				bool getpropinf = false;
				bool getent = false;
				bool usevec = false;
				int usearr = -1;
				char secondintchk[64];
				GetCmdArg(2, propname, sizeof(propname));
				if (StrEqual(propname,"maxhealth",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_iMaxHealth");
				}
				else if (StrEqual(propname,"health",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_iHealth");
				}
				else if (StrEqual(propname,"armor",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_ArmorValue");
				}
				else if (StrEqual(propname,"gravity",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_flGravity");
				}
				else if (StrEqual(propname,"friction",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_flFriction");
				}
				else if (StrEqual(propname,"speed",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_flSpeed");
				}
				else if (StrEqual(propname,"donstat",false))
				{
					pdata = false;
					Format(propname,sizeof(propname),"m_iSynergyDonorStat");
				}
				else if (StrEqual(propname,"hud",false) || StrEqual(propname,"suit",false))
				{
					pdata = false;
					Format(propname,sizeof(propname),"m_bWearingSuit");
				}
				else if (StrEqual(propname,"team",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_iTeamNum");
				}
				else if (StrEqual(propname,"mega",false))
				{
					pdata = false;
					Format(propname,sizeof(propname),"m_bMegaState");
					if (StrEqual(first,"!self",false)) targ = GetEntPropEnt(client,Prop_Data,"m_hActiveWeapon");
				}
				else if (StrEqual(propname,"rendermode",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_nRenderMode");
				}
				else if (StrEqual(propname,"classname",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_iClassname");
				}
				else if (StrEqual(propname,"model",false))
				{
					pdata = true;
					Format(propname,sizeof(propname),"m_ModelName");
				}
				GetCmdArg(3, secondintchk, sizeof(secondintchk));
				float secondfl = StringToFloat(secondintchk);
				int secondint = StringToInt(secondintchk);
				float secondvec[3];
				char vecchk[8][32];
				ExplodeString(secondintchk," ",vecchk,8,32);
				if (strlen(vecchk[2]) > 0)
				{
					usevec = true;
					secondvec[0] = StringToFloat(vecchk[0]);
					secondvec[1] = StringToFloat(vecchk[1]);
					secondvec[2] = StringToFloat(vecchk[2]);
				}
				if (HasEntProp(targ,Prop_Send,propname))
				{
					PropFieldType type;
					char srvcls[64];
					GetEntityNetClass(targ,srvcls,sizeof(srvcls));
					FindSendPropInfo(srvcls,propname,type);
					if ((type == PropField_String) || (type == PropField_String_T))
					{
						usestring = true;
					}
					else if (type == PropField_Entity)
					{
						getent = true;
					}
					else if (type == PropField_Integer)
					{
						usefloat = false;
						usestring = false;
					}
					else if (type == PropField_Float)
					{
						usefloat = true;
					}
					else if (type == PropField_Vector)
					{
						usevec = true;
					}
				}
				if (HasEntProp(targ,Prop_Data,propname))
				{
					PropFieldType type;
					FindDataMapInfo(targ,propname,type);
					if ((type == PropField_String) || (type == PropField_String_T))
					{
						usestring = true;
					}
					else if (type == PropField_Entity)
					{
						getent = true;
					}
					else if (type == PropField_Integer)
					{
						usefloat = false;
						usestring = false;
					}
					else if (type == PropField_Float)
					{
						usefloat = true;
					}
					else if (type == PropField_Vector)
					{
						usevec = true;
					}
				}
				if ((StrEqual(secondintchk,"fl",false)) || (StrEqual(secondintchk,"float",false)))
				{
					usefloat = true;
					usestring = false;
					getpropinf = true;
				}
				else if (StrEqual(secondintchk,"int",false))
				{
					usefloat = false;
					usestring = false;
					getpropinf = true;
				}
				else if (StrEqual(secondintchk,"ent",false))
				{
					usefloat = false;
					usestring = false;
					getent = true;
					getpropinf = true;
				}
				else if ((StrEqual(secondintchk,"str",false)) || (StrEqual(secondintchk,"char",false)))
				{
					usefloat = false;
					usestring = true;
					getpropinf = true;
				}
				else if ((StrEqual(secondintchk,"vec",false)) || (StrEqual(secondintchk,"vector",false)))
				{
					usefloat = false;
					usestring = false;
					usevec = true;
					getpropinf = true;
				}
				else if ((StrEqual(secondintchk,"arr",false)) || (StrEqual(secondintchk,"array",false)))
				{
					usefloat = false;
					usestring = false;
					usevec = false;
					usearr = 1;
					getpropinf = true;
				}
				else if ((StrEqual(typechk,"fl",false)) || (StrEqual(typechk,"float",false)))
				{
					usefloat = true;
					usestring = false;
					getpropinf = false;
				}
				else if (StrEqual(typechk,"int",false))
				{
					usefloat = false;
					usestring = false;
					getpropinf = false;
				}
				else if (StrEqual(typechk,"ent",false))
				{
					usefloat = false;
					usestring = false;
					getent = true;
					getpropinf = false;
				}
				else if ((StrEqual(typechk,"str",false)) || (StrEqual(typechk,"char",false)))
				{
					usefloat = false;
					usestring = true;
					getpropinf = false;
				}
				else if ((StrEqual(typechk,"vec",false)) || (StrEqual(typechk,"vector",false)))
				{
					usefloat = false;
					usestring = false;
					usevec = true;
					getpropinf = false;
				}
				else if (strlen(pdatachk) > 0)
				{
					if (HasEntProp(targ,Prop_Send,propname))
					{
						pdata = false;
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if (StringToInt(pdatachk) >= arrsize)
						{
							if (client == 0) PrintToServer("Array index out of bounds.");
							else PrintToConsole(client,"Array index out of bounds.");
							return Plugin_Handled;
						}
						else
						{
							usearr = StringToInt(pdatachk);
						}
					}
					else if (HasEntProp(targ,Prop_Data,propname))
					{
						pdata = true;
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if (StringToInt(pdatachk) >= arrsize)
						{
							if (client == 0) PrintToServer("Array index out of bounds.");
							else PrintToConsole(client,"Array index out of bounds.");
							return Plugin_Handled;
						}
						else
						{
							usearr = StringToInt(pdatachk);
						}
					}
				}
				else
				{
					
				}
				if (args == 3)
				{
					if (HasEntProp(targ,Prop_Send,propname)) pdata = false;
					else if (HasEntProp(targ,Prop_Data,propname)) pdata = true;
				}
				if (usevec)
				{
					if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
					{
						if (getpropinf)
						{
							GetEntPropVector(targ,Prop_Send,propname,secondvec);
							if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
							else PrintToConsole(client,"Set %i's %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropVector(targ,Prop_Send,propname,secondvec);
								if (client == 0) PrintToServer("Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
								else PrintToConsole(client,"Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropVector(targ,Prop_Send,propname,secondvec,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %f %f %f",targ,propname,usearr,secondvec[0],secondvec[1],secondvec[2]);
								else PrintToConsole(client,"Set %i's %s [%i] to %f %f %f",targ,propname,usearr,secondvec[0],secondvec[1],secondvec[2]);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
					{
						if (getpropinf)
						{
							GetEntPropVector(targ,Prop_Data,propname,secondvec);
							if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
							else PrintToConsole(client,"%i %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropVector(targ,Prop_Data,propname,secondvec);
								if (client == 0) PrintToServer("Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
								else PrintToConsole(client,"Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropVector(targ,Prop_Data,propname,secondvec,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %f %f %f",targ,propname,usearr,secondvec[0],secondvec[1],secondvec[2]);
								else PrintToConsole(client,"Set %i's %s [%i] to %f %f %f",targ,propname,usearr,secondvec[0],secondvec[1],secondvec[2]);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
						else PrintToConsole(client,"%i doesn't have the %s property.",targ,propname);
					}
				}
				else if (usefloat)
				{
					if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
					{
						if (getpropinf)
						{
							float flchk = GetEntPropFloat(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s is %f",targ,propname,flchk);
							else PrintToConsole(client,"Set %i's %s is %f",targ,propname,flchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropFloat(targ,Prop_Send,propname,secondfl);
								if (client == 0) PrintToServer("Set %i's %s to %f",targ,propname,secondfl);
								else PrintToConsole(client,"Set %i's %s to %f",targ,propname,secondfl);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropFloat(targ,Prop_Send,propname,secondfl,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %f",targ,propname,usearr,secondfl);
								else PrintToConsole(client,"Set %i's %s [%i] to %f",targ,propname,usearr,secondfl);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
					{
						if (getpropinf)
						{
							float flchk = GetEntPropFloat(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s is %f",targ,propname,flchk);
							else PrintToConsole(client,"%i %s is %f",targ,propname,flchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropFloat(targ,Prop_Data,propname,secondfl);
								if (client == 0) PrintToServer("Set %i's %s to %f",targ,propname,secondfl);
								else PrintToConsole(client,"Set %i's %s to %f",targ,propname,secondfl);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropFloat(targ,Prop_Data,propname,secondfl,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %f",targ,propname,usearr,secondfl);
								else PrintToConsole(client,"Set %i's %s [%i] to %f",targ,propname,usearr,secondfl);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
						else PrintToConsole(client,"%i doesn't have the %s property.",targ,propname);
					}
				}
				else if (usestring)
				{
					if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
					{
						if (getpropinf)
						{
							char chchk[64];
							GetEntPropString(targ,Prop_Send,propname,chchk,sizeof(chchk));
							if (client == 0) PrintToServer("%i %s is %s",targ,propname,chchk);
							else PrintToConsole(client,"%i %s is %s",targ,propname,chchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropString(targ,Prop_Send,propname,secondintchk);
								if (client == 0) PrintToServer("Set %i's %s to %s",targ,propname,secondintchk);
								else PrintToConsole(client,"Set %i's %s to %s",targ,propname,secondintchk);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropString(targ,Prop_Send,propname,secondintchk,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %s",targ,propname,usearr,secondintchk);
								else PrintToConsole(client,"Set %i's %s [%i] to %s",targ,propname,usearr,secondintchk);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
					{
						if (getpropinf)
						{
							char chchk[64];
							GetEntPropString(targ,Prop_Data,propname,chchk,sizeof(chchk));
							if (client == 0) PrintToServer("%i %s is %s",targ,propname,chchk);
							else PrintToConsole(client,"%i %s is %s",targ,propname,chchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropString(targ,Prop_Data,propname,secondintchk);
								if (client == 0) PrintToServer("Set %i's %s to %s",targ,propname,secondintchk);
								else PrintToConsole(client,"Set %i's %s to %s",targ,propname,secondintchk);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropString(targ,Prop_Data,propname,secondintchk,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %s",targ,propname,usearr,secondintchk);
								else PrintToConsole(client,"Set %i's %s [%i] to %s",targ,propname,usearr,secondintchk);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
						else PrintToConsole(client,"%i doesn't have the %s property.",targ,propname);
					}
				}
				else if (getent)
				{
					if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
					{
						if (getpropinf)
						{
							int intchk = GetEntPropEnt(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
							else PrintToConsole(client,"%i %s is %i",targ,propname,intchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropEnt(targ,Prop_Send,propname,secondint);
								if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
								else PrintToConsole(client,"Set %i's %s to %i",targ,propname,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropEnt(targ,Prop_Send,propname,secondint,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								else PrintToConsole(client,"Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
					{
						if (getpropinf)
						{
							int intchk = GetEntPropEnt(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
							else PrintToConsole(client,"%i %s is %i",targ,propname,intchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntPropEnt(targ,Prop_Data,propname,secondint);
								if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
								else PrintToConsole(client,"Set %i's %s to %i",targ,propname,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntPropEnt(targ,Prop_Data,propname,secondint,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								else PrintToConsole(client,"Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
						else PrintToConsole(client,"%i doesn't have the %s property.",targ,propname);
					}
				}
				else if ((usearr) && (getpropinf))
				{
					PropFieldType type;
					FindDataMapInfo(targ,propname,type);
					GetEntityClassname(targ,cls,sizeof(cls));
					if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Send,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							if ((type == PropField_String) || (type == PropField_String_T))
							{
								for (int j = 0;j<arrsize;j++)
								{
									GetEntPropString(targ,Prop_Send,propname,propinf,sizeof(propinf),j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
									else PrintToConsole(client,"%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
								}
							}
							else if (type == PropField_Entity)
							{
								for (int j = 0;j<arrsize;j++)
								{
									int enth = GetEntPropEnt(targ,Prop_Send,propname,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enth);
									else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enth);
								}
							}
							else if (type == PropField_Integer)
							{
								for (int j = 0;j<arrsize;j++)
								{
									int enti = GetEntProp(targ,Prop_Send,propname,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enti);
									else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enti);
								}
							}
							else if (type == PropField_Float)
							{
								for (int j = 0;j<arrsize;j++)
								{
									float entf = GetEntPropFloat(targ,Prop_Send,propname,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %f",targ,cls,propname,j,entf);
									else PrintToConsole(client,"%i %s %s [%i] is %f",targ,cls,propname,j,entf);
								}
							}
							else if (type == PropField_Vector)
							{
								for (int j = 0;j<arrsize;j++)
								{
									float entvec[3];
									GetEntPropVector(targ,Prop_Send,propname,entvec,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
									else PrintToConsole(client,"%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
								}
							}
						}
					}
					else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
					{
						int arrsize = GetEntPropArraySize(targ,Prop_Data,propname);
						if ((arrsize != 1) && (arrsize != 0))
						{
							if ((type == PropField_String) || (type == PropField_String_T))
							{
								for (int j = 0;j<arrsize;j++)
								{
									GetEntPropString(targ,Prop_Data,propname,propinf,sizeof(propinf),j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
									else PrintToConsole(client,"%i %s %s [%i] is %s",targ,cls,propname,j,propinf);
								}
							}
							else if (type == PropField_Entity)
							{
								for (int j = 0;j<arrsize;j++)
								{
									int enth = GetEntPropEnt(targ,Prop_Data,propname,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enth);
									else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enth);
								}
							}
							else if (type == PropField_Integer)
							{
								bool useelement = false;
								if (StrEqual(propname,"m_iAmmo",false)) useelement = true;
								for (int j = 0;j<arrsize;j++)
								{
									int enti = 0;
									if (!useelement) enti = GetEntProp(targ,Prop_Data,propname,j);
									else enti = GetEntProp(targ,Prop_Data,propname,_,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %i",targ,cls,propname,j,enti);
									else PrintToConsole(client,"%i %s %s [%i] is %i",targ,cls,propname,j,enti);
								}
							}
							else if (type == PropField_Float)
							{
								for (int j = 0;j<arrsize;j++)
								{
									float entf = GetEntPropFloat(targ,Prop_Data,propname,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %f",targ,cls,propname,j,entf);
									else PrintToConsole(client,"%i %s %s [%i] is %f",targ,cls,propname,j,entf);
								}
							}
							else if (type == PropField_Vector)
							{
								for (int j = 0;j<arrsize;j++)
								{
									float entvec[3];
									GetEntPropVector(targ,Prop_Data,propname,entvec,j);
									if (client == 0) PrintToServer("%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
									else PrintToConsole(client,"%i %s %s [%i] is %f %f %f",targ,cls,propname,j,entvec[0],entvec[1],entvec[2]);
								}
							}
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i does not have property of type",targ);
						else PrintToConsole(client,"%i does not have property of type",targ);
					}
				}
				else
				{
					if (HasEntProp(targ,Prop_Send,propname))
					{
						if (getpropinf)
						{
							int intchk = GetEntProp(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
							else PrintToConsole(client,"%i %s is %i",targ,propname,intchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntProp(targ,Prop_Send,propname,secondint);
								if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
								else PrintToConsole(client,"Set %i's %s to %i",targ,propname,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								bool useelement = false;
								if (StrEqual(propname,"m_iAmmo",false)) useelement = true;
								if (!useelement) SetEntProp(targ,Prop_Send,propname,secondint,usearr);
								else SetEntProp(targ,Prop_Send,propname,secondint,_,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								else PrintToConsole(client,"Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					if (HasEntProp(targ,Prop_Data,propname))
					{
						if (getpropinf)
						{
							int intchk = GetEntProp(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
							else PrintToConsole(client,"%i %s is %i",targ,propname,intchk);
						}
						else
						{
							if (usearr == -1)
							{
								SetEntProp(targ,Prop_Data,propname,secondint);
								if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
								else PrintToConsole(client,"Set %i's %s to %i",targ,propname,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
							else
							{
								SetEntProp(targ,Prop_Data,propname,secondint,usearr);
								if (client == 0) PrintToServer("Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								else PrintToConsole(client,"Set %i's %s [%i] to %i",targ,propname,usearr,secondint);
								if (targ > -1) ChangeEdictState(targ);
							}
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
						else PrintToConsole(client,"%i doesn't have the %s property.",targ,propname);
					}
				}
			}
		}
		else
		{
			if (client == 0) PrintToServer("Invalid target");
			else if (IsClientInGame(client)) PrintToConsole(client,"Invalid target");
		}
	}
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (showallcreated)
	{
		PrintToServer("Create %i %s",entity,classname);
		if (showallcreated > 1)
		{
			CreateTimer(0.1,CreateDebugSpawn,entity,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action CreateDebugSpawn(Handle timer, int entity)
{
	PrintEntInfoFor(entity);
}

public void OnEntityDestroyed(int entity)
{
	if (showalldeleted)
	{
		if (IsValidEntity(entity))
		{
			char cls[32];
			GetEntityClassname(entity,cls,sizeof(cls));
			PrintToServer("Delete %i %s",entity,cls);
			if (showalldeleted > 1)
			{
				PrintEntInfoFor(entity);
			}
		}
	}
}

void PrintEntInfoFor(int targ)
{
	if (IsValidEntity(targ))
	{
		char ent[128];
		char targname[128];
		char globname[128];
		float vec[3];
		float angs[3];
		int parent = 0;
		int ammotype = -1;
		vec[0] = -1.1;
		angs[0] = -1.1;
		char exprsc[24];
		char exprtargname[64];
		char stateinf[128];
		char scriptinf[256];
		char scrtmp[64];
		int doorstate, sleepstate, exprsci;
		GetEntityClassname(targ, ent, sizeof(ent));
		GetEntPropString(targ,Prop_Data,"m_iName",targname,sizeof(targname));
		if (HasEntProp(targ,Prop_Data,"m_iGlobalname"))
			GetEntPropString(targ,Prop_Data,"m_iGlobalname",globname,sizeof(globname));
		if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",vec);
		else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",vec);
		if (HasEntProp(targ,Prop_Send,"m_angRotation"))
			GetEntPropVector(targ,Prop_Send,"m_angRotation",angs);
		if (HasEntProp(targ,Prop_Data,"m_hParent"))
			parent = GetEntPropEnt(targ,Prop_Data,"m_hParent");
		if (HasEntProp(targ,Prop_Data,"m_nAmmoType"))
			ammotype = GetEntProp(targ,Prop_Data,"m_nAmmoType");
		if (HasEntProp(targ,Prop_Data,"m_hTargetEnt"))
		{
			exprsci = GetEntPropEnt(targ,Prop_Data,"m_hTargetEnt");
			if (IsValidEntity(exprsci))
			{
				GetEntityClassname(exprsci,exprsc,sizeof(exprsc));
				if (HasEntProp(exprsci,Prop_Data,"m_iName"))
					GetEntPropString(exprsci,Prop_Data,"m_iName",exprtargname,sizeof(exprtargname));
			}
		}
		char cmodel[64];
		GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
		int spawnflagsi = GetEntityFlags(targ);
		char inf[256];
		Format(inf,sizeof(inf),"\nID: %i %s %s ",targ,ent,cmodel);
		if (parent > 0)
		{
			char parentname[32];
			if (HasEntProp(parent,Prop_Data,"m_iName"))
				GetEntPropString(parent,Prop_Data,"m_iName",parentname,sizeof(parentname));
			char parentcls[32];
			GetEntityClassname(parent,parentcls,sizeof(parentcls));
			Format(stateinf,sizeof(stateinf),"%sParented to %i %s %s ",stateinf,parent,parentname,parentcls);
		}
		if (HasEntProp(targ,Prop_Data,"m_flRefireTime"))
		{
			float firetime = GetEntPropFloat(targ,Prop_Data,"m_flRefireTime");
			Format(stateinf,sizeof(stateinf),"%sRefireTime %f ",stateinf,firetime);
		}
		if (HasEntProp(targ,Prop_Data,"m_vehicleScript"))
		{
			GetEntPropString(targ,Prop_Data,"m_vehicleScript",scrtmp,sizeof(scrtmp));
			Format(stateinf,sizeof(stateinf),"%sVehicleScript %s ",stateinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_spawnEquipment"))
		{
			GetEntPropString(targ,Prop_Data,"m_spawnEquipment",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sAdditionalEquipment %s ",stateinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_nSkin"))
		{
			int sk = GetEntProp(targ,Prop_Data,"m_nSkin");
			Format(stateinf,sizeof(stateinf),"%sSkin %i ",stateinf,sk);
		}
		if (HasEntProp(targ,Prop_Data,"m_nHardwareType"))
		{
			int hdw = GetEntProp(targ,Prop_Data,"m_nHardwareType");
			Format(stateinf,sizeof(stateinf),"%sHardwareType %i ",stateinf,hdw);
		}
		if (HasEntProp(targ,Prop_Data,"m_state"))
		{
			int istate = GetEntProp(targ,Prop_Data,"m_state");
			Format(stateinf,sizeof(stateinf),"%sState %i ",stateinf,istate);
		}
		if (HasEntProp(targ,Prop_Data,"m_eDoorState"))
		{
			doorstate = GetEntProp(targ,Prop_Data,"m_eDoorState");
			Format(stateinf,sizeof(stateinf),"%sDoorState %i ",stateinf,doorstate);
		}
		if (HasEntProp(targ,Prop_Data,"m_SleepState"))
		{
			sleepstate = GetEntProp(targ,Prop_Data,"m_SleepState");
			Format(stateinf,sizeof(stateinf),"%sSleepState %i ",stateinf,sleepstate);
		}
		if (HasEntProp(targ,Prop_Data,"m_Type"))
		{
			int inpctype = GetEntProp(targ,Prop_Data,"m_Type");
			Format(stateinf,sizeof(stateinf),"%sNPCType %i ",stateinf,inpctype);
		}
		if (StrEqual(ent,"math_counter",false))
		{
			int offset = FindDataMapInfo(targ, "m_OutValue");
			Format(stateinf,sizeof(stateinf),"%sCurrentValue %i ",stateinf,RoundFloat(GetEntDataFloat(targ, offset)));
		}
		if (StrEqual(ent,"env_global",false))
		{
			int offset = FindDataMapInfo(targ, "m_outCounter");
			Format(stateinf,sizeof(stateinf),"%sCurrentValue %i ",stateinf,RoundFloat(GetEntDataFloat(targ, offset)));
		}
		if (HasEntProp(targ,Prop_Data,"m_spawnflags"))
		{
			int sf = GetEntProp(targ,Prop_Data,"m_spawnflags");
			Format(stateinf,sizeof(stateinf),"%sSpawnflags %i ",stateinf,sf);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszSubject"))
		{
			char subj[32];
			GetEntPropString(targ,Prop_Data,"m_iszSubject",subj,sizeof(subj));
			Format(stateinf,sizeof(stateinf),"%sSubject %s ",stateinf,subj);
		}
		if (HasEntProp(targ,Prop_Data,"m_bReciprocal"))
		{
			int recip = GetEntProp(targ,Prop_Data,"m_bReciprocal");
			Format(stateinf,sizeof(stateinf),"%sReciprocal %i ",stateinf,recip);
		}
		if (HasEntProp(targ,Prop_Data,"m_target"))
		{
			char targetstr[64];
			PropFieldType type;
			FindDataMapInfo(targ,"m_target",type);
			if (type == PropField_String)
			{
				GetEntPropString(targ,Prop_Data,"m_target",targetstr,sizeof(targetstr));
				Format(stateinf,sizeof(stateinf),"%sTarget %s ",stateinf,targetstr);
			}
			else if (type == PropField_Entity)
			{
				int targent = GetEntPropEnt(targ,Prop_Data,"m_target");
				if (targent != -1) Format(stateinf,sizeof(stateinf),"%sTarget %i ",stateinf,targent);
			}
		}
		if (HasEntProp(targ,Prop_Data,"m_hVehicle"))
		{
			int targent = GetEntPropEnt(targ,Prop_Data,"m_hVehicle");
			if (targent != -1) Format(stateinf,sizeof(stateinf),"%sVehicle %i ",stateinf,targent);
		}
		if (HasEntProp(targ,Prop_Data,"m_hPlayer"))
		{
			int targent = GetEntPropEnt(targ,Prop_Data,"m_hPlayer");
			if (targent != -1) Format(stateinf,sizeof(stateinf),"%sm_hPlayer %i ",stateinf,targent);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszEntry"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszEntry",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"m_iszEntry %s ",scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszPreIdle"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszPreIdle",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPreIdle %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszPlay"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszPlay",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPlay %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszPostIdle"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszPostIdle",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszPostIdle %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszCustomMove"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszCustomMove",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszCustomMove %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszNextScript"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszNextScript",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszNextScript %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszEntity"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszEntity",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszEntity %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_fMoveTo"))
		{
			int scrtmpi = GetEntProp(targ,Prop_Data,"m_fMoveTo");
			Format(scriptinf,sizeof(scriptinf),"%sm_fMoveTo %i ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_flRadius"))
		{
			float scrtmpi = GetEntPropFloat(targ,Prop_Data,"m_flRadius");
			if (scrtmpi > 0.0)
				Format(scriptinf,sizeof(scriptinf),"%sm_flRadius %1.f ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_flRepeat"))
		{
			float scrtmpi = GetEntPropFloat(targ,Prop_Data,"m_flRepeat");
			Format(scriptinf,sizeof(scriptinf),"%sm_flRepeat %1.f ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_bLoopActionSequence"))
		{
			int scrtmpi = GetEntProp(targ,Prop_Data,"m_bLoopActionSequence");
			Format(scriptinf,sizeof(scriptinf),"%sm_bLoopActionSequence %i ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_bIgnoreGravity"))
		{
			int scrtmpi = GetEntProp(targ,Prop_Data,"m_bIgnoreGravity");
			Format(scriptinf,sizeof(scriptinf),"%sm_bIgnoreGravity %i ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_bSynchPostIdles"))
		{
			int scrtmpi = GetEntProp(targ,Prop_Data,"m_bSynchPostIdles");
			Format(scriptinf,sizeof(scriptinf),"%sm_bSynchPostIdles %i ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_bDisableNPCCollisions"))
		{
			int scrtmpi = GetEntProp(targ,Prop_Data,"m_bDisableNPCCollisions");
			Format(scriptinf,sizeof(scriptinf),"%sm_bDisableNPCCollisions %i ",scriptinf,scrtmpi);
		}
		if (HasEntProp(targ,Prop_Data,"m_iszTemplateEntityNames[0]"))
		{
			for (int j = 0;j<16;j++)
			{
				char tmpennam[48];
				Format(tmpennam,sizeof(tmpennam),"m_iszTemplateEntityNames[%i]",j);
				GetEntPropString(targ,Prop_Data,tmpennam,scrtmp,sizeof(scrtmp));
				if (strlen(scrtmp) > 0)
				{
					if (j < 9) Format(scriptinf,sizeof(scriptinf),"%sTemplate0%i %s ",scriptinf,j+1,scrtmp);
					else Format(scriptinf,sizeof(scriptinf),"%sTemplate%i %s ",scriptinf,j+1,scrtmp);
				}
			}
		}
		if (HasEntProp(targ,Prop_Data,"m_iszSound"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszSound",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(scriptinf,sizeof(scriptinf),"%sm_iszSound %s ",scriptinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_bCarriedByPlayer"))
		{
			int ownert = GetEntProp(targ,Prop_Data,"m_bCarriedByPlayer");
			int ownerphy = GetEntProp(targ,Prop_Data,"m_bHackedByAlyx");
			//This property seems to exist on a few ents and changes colors/speed/relations
			//SetEntProp(targ,Prop_Data,"m_bHackedByAlyx",1);
			Format(stateinf,sizeof(stateinf),"%sOwner: %i %i ",stateinf,ownert,ownerphy);
		}
		if (HasEntProp(targ,Prop_Data,"m_iDamageType"))
		{
			Format(stateinf,sizeof(stateinf),"%sDamageType: %i ",stateinf,GetEntProp(targ,Prop_Data,"m_iDamageType"));
		}
		if (HasEntProp(targ,Prop_Data,"m_bNegated"))
		{
			Format(stateinf,sizeof(stateinf),"%sNegated: %i ",stateinf,GetEntProp(targ,Prop_Data,"m_bNegated"));
		}
		if (HasEntProp(targ,Prop_Data,"m_iszDamageFilterName"))
		{
			GetEntPropString(targ,Prop_Data,"m_iszDamageFilterName",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sDamageFilter: %s ",stateinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_iFilterClass"))
		{
			GetEntPropString(targ,Prop_Data,"m_iFilterClass",scrtmp,sizeof(scrtmp));
			if (strlen(scrtmp) > 0) Format(stateinf,sizeof(stateinf),"%sFilterClass: %s ",stateinf,scrtmp);
		}
		if (HasEntProp(targ,Prop_Data,"m_szMapName"))
		{
			char maptochange[128];
			GetEntPropString(targ,Prop_Data,"m_szMapName",maptochange,sizeof(maptochange));
			if (HasEntProp(targ,Prop_Data,"m_szLandmarkName"))
			{
				char landmark[64];
				GetEntPropString(targ,Prop_Data,"m_szLandmarkName",landmark,sizeof(landmark));
				Format(scriptinf,sizeof(scriptinf),"%sMap %s Landmark %s ",scriptinf,maptochange,landmark);
			}
			else Format(scriptinf,sizeof(scriptinf),"%sMap %s ",scriptinf,maptochange);
		}
		if (HasEntProp(targ,Prop_Data,"m_iDisabled"))
		{
			Format(stateinf,sizeof(stateinf),"%sStartDisabled %i ",stateinf,GetEntProp(targ,Prop_Data,"m_iDisabled"));
		}
		if ((StrContains(ent,"func_",false) == 0) && (HasEntProp(targ,Prop_Data,"m_toggle_state")))
		{
			int togglestate = GetEntProp(targ,Prop_Data,"m_toggle_state");
			if (togglestate == 1) Format(stateinf,sizeof(stateinf),"%sToggleState %i (Closed) ",stateinf,togglestate);
			else if (togglestate == 0) Format(stateinf,sizeof(stateinf),"%sToggleState %i (Open) ",stateinf,togglestate);
			else Format(stateinf,sizeof(stateinf),"%sToggleState %i ",stateinf,togglestate);
		}
		if ((StrEqual(ent,"func_brush",false)) && (HasEntProp(targ,Prop_Data,"m_fEffects")))
		{
			int enablestate = GetEntProp(targ,Prop_Data,"m_fEffects");
			if (enablestate == 32) Format(stateinf,sizeof(stateinf),"%sToggleState: Disabled ",stateinf);
			else Format(stateinf,sizeof(stateinf),"%sToggleState: Enabled ",stateinf);
		}
		if ((StrContains(ent,"trigger_",false) == 0) && (HasEntProp(targ,Prop_Data,"m_bDisabled")))
		{
			int enablestate = GetEntProp(targ,Prop_Data,"m_bDisabled");
			if (enablestate == 1) Format(stateinf,sizeof(stateinf),"%sToggleState: Disabled ",stateinf);
			else Format(stateinf,sizeof(stateinf),"%sToggleState: Enabled ",stateinf);
		}
		if (HasEntProp(targ,Prop_Send,"m_hEnt"))
		{
			int hEnt = GetEntPropEnt(targ,Prop_Send,"m_hEnt");
			Format(stateinf,sizeof(stateinf),"%sm_hEnt: %i ",stateinf,hEnt);
		}
		if (HasEntProp(targ,Prop_Send,"m_pPlayer"))
		{
			int hEnt = GetEntPropEnt(targ,Prop_Send,"m_pPlayer");
			Format(stateinf,sizeof(stateinf),"%sm_pPlayer: %i ",stateinf,hEnt);
		}
		if (HasEntProp(targ,Prop_Data,"m_hLinkedPortal"))
		{
			int hEnt = GetEntPropEnt(targ,Prop_Data,"m_hLinkedPortal");
			Format(stateinf,sizeof(stateinf),"%sm_hLinkedPortal: %i ",stateinf,hEnt);
		}
		if (HasEntProp(targ,Prop_Data,"m_bActivated"))
		{
			int hEnt = GetEntProp(targ,Prop_Data,"m_bActivated");
			Format(stateinf,sizeof(stateinf),"%sm_bActivated: %i ",stateinf,hEnt);
		}
		if ((HasEntProp(targ,Prop_Data,"m_iHealth")) && (HasEntProp(targ,Prop_Data,"m_iMaxHealth")))
		{
			int targh = GetEntProp(targ,Prop_Data,"m_iHealth");
			int targmh = GetEntProp(targ,Prop_Data,"m_iMaxHealth");
			int held = -1;
			if (HasEntProp(targ,Prop_Data,"m_bHeld"))
				held = GetEntProp(targ,Prop_Data,"m_bHeld");
			if (held != -1)
			{
				Format(stateinf,sizeof(stateinf),"%sHealth: %i Max Health: %i Held: %i",stateinf,targh,targmh,held);
			}
			else
			{
				Format(stateinf,sizeof(stateinf),"%sHealth: %i Max Health: %i",stateinf,targh,targmh);
			}
		}
		TrimString(stateinf);
		TrimString(scriptinf);
		if (strlen(targname) > 0)
			Format(inf,sizeof(inf),"%sName: %s ",inf,targname);
		if (strlen(globname) > 0)
			Format(inf,sizeof(inf),"%sGlobalName: %s ",inf,globname);
		if (ammotype != -1)
			Format(inf,sizeof(inf),"%sAmmoType: %i",inf,ammotype);
		if (spawnflagsi != 0)
			Format(inf,sizeof(inf),"%sEntSpawnflags: %i",inf,spawnflagsi);
		if (vec[0] != -1.1)
			Format(inf,sizeof(inf),"%s\nOrigin %f %f %f",inf,vec[0],vec[1],vec[2]);
		if (angs[0] != -1.1)
			Format(inf,sizeof(inf),"%s Ang: %i %i %i",inf,RoundFloat(angs[0]),RoundFloat(angs[1]),RoundFloat(angs[2]));
		if (strlen(exprsc) > 0)
			Format(inf,sizeof(inf),"%s\nTarget: %s %i %s",inf,exprsc,exprsci,exprtargname);
		if ((strlen(scriptinf) > 1) && (strlen(stateinf) < 1)) PrintToServer("%s\n%s",inf,scriptinf);
		if ((strlen(stateinf) > 1) && (strlen(scriptinf) < 1)) PrintToServer("%s\n%s",inf,stateinf);
		if ((strlen(stateinf) > 1) && (strlen(scriptinf) > 1)) PrintToServer("%s\n%s\n%s",inf,stateinf,scriptinf);
		if ((strlen(stateinf) < 1) && (strlen(scriptinf) < 1)) PrintToServer("%s",inf);
	}
}

public Action Event_EntityKilled(Handle event, const char[] name, bool Broadcast)
{
	if (showalldeaths)
	{
		char clsnamekilled[64];
		char clsnameatk[64];
		char clsnameinf[64];
		int killed = GetEventInt(event, "entindex_killed");
		int attacker = GetEventInt(event, "entindex_attacker");
		int inflictor = GetEventInt(event, "entindex_inflictor");
		if (IsValidEntity(killed))
		{
			GetEntityClassname(killed,clsnamekilled,sizeof(clsnamekilled));
			Format(clsnamekilled,sizeof(clsnamekilled)," %s",clsnamekilled);
		}
		if (IsValidEntity(attacker))
		{
			GetEntityClassname(attacker,clsnameatk,sizeof(clsnameatk));
			Format(clsnameatk,sizeof(clsnameatk)," %s",clsnameatk);
		}
		if (IsValidEntity(inflictor))
		{
			GetEntityClassname(inflictor,clsnameinf,sizeof(clsnameinf));
			Format(clsnameinf,sizeof(clsnameinf)," %s",clsnameinf);
		}
		PrintToServer("EntDeath killed: %i%s attacker: %i%s inflictor: %i%s",killed,clsnamekilled,attacker,clsnameatk,inflictor,clsnameinf);
		if (showalldeaths > 1)
		{
			PrintEntInfoFor(killed);
		}
	}
}

public Action listnormsounds(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if ((showallnormsounds) && (flags != SND_STOP) && (flags != SND_STOPLOOPING))
	{
		if ((StrContains(sample,"ambient/energy/zap",false) == -1) && (StrContains(sample,"shotgun_fire",false) == -1) && (StrContains(sample,"smg1_fire1.wav",false) == -1) && (!StrEqual(sample,"common/null.wav",false)))
		{
			char cls[32];
			if (IsValidEntity(entity)) GetEntityClassname(entity,cls,sizeof(cls));
			PrintToServer("NormalSound %s From %i %s Channel %i Vol %f Level %i Pitch %i Flags %i",sample,entity,cls,channel,volume,level,pitch,flags);
		}
	}
}

public Action listambientsounds(char sample[PLATFORM_MAX_PATH], int& entity, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
	if ((showallambsounds) && (flags != SND_STOP) && (flags != SND_STOPLOOPING))
	{
		char cls[32];
		if (IsValidEntity(entity)) GetEntityClassname(entity,cls,sizeof(cls));
		PrintToServer("AmbientSound %s From %i %s Vol %f Level %i Pitch %i Flags %i",sample,entity,cls,volume,level,pitch,flags);
	}
}

public void dbghch(Handle convar, const char[] oldValue, const char[] newValue)
{
	showallcreated = StringToInt(newValue);
}

public void dbgcrehch(Handle convar, const char[] oldValue, const char[] newValue)
{
	showalldeleted = StringToInt(newValue);
}

public void dbgdeahch(Handle convar, const char[] oldValue, const char[] newValue)
{
	showalldeaths = StringToInt(newValue);
}

public void dbgnormsch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) showallnormsounds = true;
	else showallnormsounds = false;
}

public void dbgambsch(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 1) showallambsounds = true;
	else showallambsounds = false;
}

public bool TraceEntityFilterPly(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		if ((entity < MaxClients+1) && (entity > 0)) return false;
	}
	return true;
}