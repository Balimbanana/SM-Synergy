#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.08"
#define UPDATE_URL "https://raw.githubusercontent.com/Balimbanana/SM-Synergy/master/enttoolsupdater.txt"

public Plugin:myinfo = 
{
	name = "EntTools",
	author = "Balimbanana",
	description = "Entity tools.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Balimbanana/SM-Synergy"
}

public OnPluginStart()
{
	RegAdminCmd("createhere",CreateStuff,ADMFLAG_BAN,"cc");
	RegAdminCmd("createthere",CreateStuffThere,ADMFLAG_BAN,"cct");
	RegAdminCmd("cc",CreateStuff,ADMFLAG_BAN,"cc");
	RegAdminCmd("cct",CreateStuffThere,ADMFLAG_BAN,"cct");
	RegAdminCmd("setmdl",SetTargMdl,ADMFLAG_ROOT,".");
	RegAdminCmd("cinp",cinp,ADMFLAG_BAN,"ent_fire");
	RegAdminCmd("entinput",cinp,ADMFLAG_BAN,"ent_fire");
	RegAdminCmd("changeclasses",changeclasses,ADMFLAG_BAN,"ChangeClasses");
	RegConsoleCmd("gi",getinf);
	RegAdminCmd("tn",sett,ADMFLAG_PASSWORD,"SetName");
	RegAdminCmd("sm_sep",setprops,ADMFLAG_ROOT,".");
	RegAdminCmd("listents",listents,ADMFLAG_KICK,".");
	RegAdminCmd("findents",listents,ADMFLAG_KICK,".");
}

public OnLibraryAdded(const char[] name)
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
			PrintToChat(client,"Please specify ent");
		else
			PrintToServer("Please specify ent");
		return Plugin_Handled;
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
		for (int v = 0; v<args+1; v++)
		{
			if (v > 1)
			{
				char tmp[64];
				char tmp2[64];
				GetCmdArg(v,tmp,sizeof(tmp));
				int v1 = v+1;
				GetCmdArg(v1,tmp2,sizeof(tmp2));
				DispatchKeyValue(stuff,tmp,tmp2);
				if (StrEqual(tmp,"origin",false))
				{
					char originch[3][16];
					ExplodeString(tmp2," ",originch,3,16);
					Original[0] = StringToFloat(originch[0]);
					Original[1] = StringToFloat(originch[1]);
					Original[2] = StringToFloat(originch[2]);
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
		bool vehiclemodeldefined = false;
		bool vehiclescriptdefined = false;
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
				PrintToChat(client,"Ep2 must be mounted to spawn a jalopy.");
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
		if (stuff == 0) stuff = CreateEntityByName(ent);
		if (stuff == -1)
		{
			PrintToChat(client,"Unable to create entity %s",ent);
			return Plugin_Handled;
		}
		char fullstr[512];
		Format(fullstr,sizeof(fullstr),"%s",ent);
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
						if ((!FileExists(tmp2,true,NULL_STRING)) && (!IsModelPrecached(tmp2)))
						{
							PrintToChat(client,"The model %s was not found.",tmp2);
							AcceptEntityInput(stuff,"kill");
							return Plugin_Handled;
						}
					}
					if (StrEqual(tmp,"vehiclescript",false))
					{
						vehiclescriptdefined = true;
						if (!FileExists(tmp2,true,NULL_STRING))
						{
							PrintToChat(client,"The vehiclescript %s was not found.",tmp2);
							PrintToChat(client,"Defaulting to \"scripts/vehicles/jeep_test.txt\"");
							Format(tmp2,sizeof(tmp2),"scripts/vehicles/jeep_test.txt");
						}
					}
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
				Format(fullstr,sizeof(fullstr),"%s %s %s",fullstr,tmp,tmp2);
				v++;
			}
		}
		if (((StrContains(ent,"prop_vehicle",false) != -1) || (StrEqual(ent,"generic_actor",false)) || (StrEqual(ent,"monster_generic",false))) && (!vehiclemodeldefined))
		{
			PrintToChat(client,"Model must be defined for this type of entity.");
			AcceptEntityInput(stuff,"kill");
			return Plugin_Handled;
		}
		if ((StrContains(ent,"prop_vehicle",false) != -1) && (!vehiclescriptdefined))
		{
			PrintToChat(client,"VehicleScript was not defined, defaulting to \"scripts/vehicles/jeep_test.txt\"");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		TeleportEntity(stuff, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
		PrintToConsole(client,"%s",fullstr);
		DispatchSpawn(stuff);
		ActivateEntity(stuff);
	}
	return Plugin_Handled;
}

public Action CreateStuffThere(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	char ent[64];
	GetCmdArg(1,ent,sizeof(ent));
	if (strlen(ent) < 1)
	{
		PrintToChat(client,"Please specify ent");
		return Plugin_Handled;
	}
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		float Location[3];
		float fhitpos[3];
		float clangles[3];
		bool vehiclemodeldefined = false;
		bool vehiclescriptdefined = false;
		GetClientEyeAngles(client, clangles);
		GetClientEyePosition(client, Location);
		Location[0] = (Location[0] + (10 * Cosine(DegToRad(clangles[1]))));
		Location[1] = (Location[1] + (10 * Sine(DegToRad(clangles[1]))));
		Location[2] = (Location[2] + 10);
		Handle hhitpos = INVALID_HANDLE;
		TR_TraceRay(Location,clangles,MASK_SHOT,RayType_Infinite);
		TR_GetEndPosition(fhitpos,hhitpos);
		//To ensure they spawn above the ground
		fhitpos[2] = (fhitpos[2] + 15);
		if (StrEqual(ent,"npc_strider",false))
			fhitpos[2] = (fhitpos[2] + 165);
		CloseHandle(hhitpos);
		int stuff = CreateEntityByName(ent);
		if (StrEqual(ent,"jalopy",false))
		{
			if ((!FileExists("models/vehicle.mdl",true,NULL_STRING)) && (!IsModelPrecached("models/vehicle.mdl")))
			{
				PrintToChat(client,"Ep2 must be mounted to spawn a jalopy.");
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
		if (stuff == 0) stuff = CreateEntityByName(ent);
		if (stuff == -1)
		{
			PrintToChat(client,"Unable to create entity %s",ent);
			return Plugin_Handled;
		}
		char fullstr[512];
		Format(fullstr,sizeof(fullstr),"%s",ent);
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
						if ((!FileExists(tmp2,true,NULL_STRING)) && (!IsModelPrecached(tmp2)))
						{
							PrintToChat(client,"The model %s was not found.",tmp2);
							AcceptEntityInput(stuff,"kill");
							return Plugin_Handled;
						}
					}
					if (StrEqual(tmp,"vehiclescript",false))
					{
						vehiclescriptdefined = true;
						if (!FileExists(tmp2,true,NULL_STRING))
						{
							PrintToChat(client,"The vehiclescript %s was not found.",tmp2);
							PrintToChat(client,"Defaulting to \"scripts/vehicles/jeep_test.txt\"");
							Format(tmp2,sizeof(tmp2),"scripts/vehicles/jeep_test.txt");
						}
					}
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
		if (((StrContains(ent,"prop_vehicle",false) != -1) || (StrEqual(ent,"generic_actor",false)) || (StrEqual(ent,"monster_generic",false))) && (!vehiclemodeldefined))
		{
			PrintToChat(client,"Model must be defined for this type of entity.");
			AcceptEntityInput(stuff,"kill");
			return Plugin_Handled;
		}
		if ((StrContains(ent,"prop_vehicle",false) != -1) && (!vehiclescriptdefined))
		{
			PrintToChat(client,"VehicleScript was not defined, defaulting to \"scripts/vehicles/jeep_test.txt\"");
			DispatchKeyValue(stuff,"vehiclescript","scripts/vehicles/jeep_test.txt");
		}
		PrintToConsole(client,"%s",fullstr);
		TeleportEntity(stuff, fhitpos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(stuff);
		ActivateEntity(stuff);
	}
	return Plugin_Handled;
}

public Action cinp(int client, int args)
{
	char fullinp[128];
	char firstarg[64];
	GetCmdArgString(fullinp, sizeof(fullinp));
	GetCmdArg(1,firstarg, sizeof(firstarg));
	if ((StrEqual(firstarg,"!picker",false)) && (args > 2))
	{
		int targ = GetClientAimTarget(client, false);
		if (targ == -1)
		{
			if (client == 0) PrintToServer("Invalid target.");
			else PrintToChat(client,"Invalid target.");
			return Plugin_Handled;
		}
		char second[64];
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
		return Plugin_Handled;
	}
	PrintToConsole(client,"%s",fullinp);
	if (StrContains(fullinp,",",false) != -1)
	{
		int loginp = CreateEntityByName("logic_auto");
		DispatchKeyValue(loginp, "spawnflags","1");
		DispatchKeyValue(loginp, "OnMapSpawn",fullinp);
		DispatchSpawn(loginp);
		ActivateEntity(loginp);
		return Plugin_Handled;
	}
	else if ((strlen(firstarg) > 0) && (args > 2) && (StringToInt(firstarg) == 0))
	{
		Handle arr = CreateArray(64);
		findentsarrtarg(arr,firstarg);
		//Checks must be separate
		if (arr == INVALID_HANDLE)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",firstarg);
			else PrintToChat(client,"No entities found with either classname or targetname of %s",firstarg);
			return Plugin_Handled;
		}
		else if (GetArraySize(arr) < 1)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",firstarg);
			else PrintToChat(client,"No entities found with either classname or targetname of %s",firstarg);
			return Plugin_Handled;
		}
		else
		{
			char input[64];
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
			else PrintToChat(client,"%s %s %s",firstarg,input,fullinp);
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
						PrintToChat(client,"Setting %s %s %s",nick,third,fourth);
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
				GetCmdArg(2+addarg, secondintchk, sizeof(secondintchk))
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
				GetCmdArg(3+addarg, secondintchk, sizeof(secondintchk))
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
	return Plugin_Handled;
}

public Action SetTargMdl(int client, int args)
{
	if ((args < 1) || (client == 0))
	{
		if (client == 0) PrintToServer("Must specify model to set");
		else PrintToChat(client,"Must specify model to set");
		return Plugin_Handled;
	}
	else
	{
		int targ = GetClientAimTarget(client,false);
		if (targ == -1)
		{
			PrintToChat(client,"Invalid target");
			return Plugin_Handled;
		}
		else
		{
			char mdltoset[128];
			GetCmdArg(1,mdltoset, sizeof(mdltoset));
			if ((!FileExists(mdltoset,true,NULL_STRING)) && (!IsModelPrecached(mdltoset)))
			{
				PrintToChat(client,"The model %s was not found.",mdltoset);
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
			char fname[32];
			GetEntPropString(thisent,Prop_Data,"m_iName",fname,sizeof(fname));
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
	for (int i = 1;i<2048;i++)
	{
		if (IsValidEntity(i) && IsEntNetworkable(i))
		{
			char clsname[32];
			GetEntityClassname(i,clsname,sizeof(clsname));
			if ((StrEqual(clsname,namechk,false)) && (FindValueInArray(arr,i) == -1))
				PushArrayCell(arr, i);
			if ((HasEntProp(i,Prop_Data,"m_iName")) && (FindValueInArray(arr,i) == -1))
			{
				char fname[32];
				GetEntPropString(i,Prop_Data,"m_iName",fname,sizeof(fname));
				if (StrEqual(fname,namechk,false))
					PushArrayCell(arr, i);
			}
		}
	}
	if (GetArraySize(arr) < 1) findentsarrtargsub(arr,-1,namechk,"logic_relay");
	if (arr != INVALID_HANDLE)
		if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}

public Action listents(int client, int args)
{
	if (args < 1)
	{
		if (client == 0) PrintToServer("Must specify targetname or classname");
		else PrintToChat(client,"Must specify targetname or classname");
		return Plugin_Handled;
	}
	char search[64];
	char fullinf[16];
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
			else PrintToChat(client,"No entities found with either classname or targetname of %s",search);
			return Plugin_Handled;
		}
		else if (GetArraySize(arr) < 1)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",search);
			else PrintToChat(client,"No entities found with either classname or targetname of %s",search);
			return Plugin_Handled;
		}
		else
		{
			for (int i = 0;i<GetArraySize(arr);i++)
			{
				if (StrEqual(fullinf,"full",false))
				{
					int targ = GetArrayCell(arr,i);
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
					char stateinf[128];
					char scriptinf[256];
					char scrtmp[64];
					int doorstate, sleepstate, exprsci;
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
					char cmodel[64];
					GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
					int spawnflagsi = GetEntityFlags(targ);
					if (client == 0) PrintToServer("%i %s %s",targ,ent,cmodel);
					else PrintToChat(client,"%i %s %s",targ,ent,cmodel);
					if (parent > 0)
					{
						char parentname[32];
						if (HasEntProp(parent,Prop_Data,"m_iName"))
							GetEntPropString(parent,Prop_Data,"m_iName",parentname,sizeof(parentname));
						char parentcls[32];
						GetEntityClassname(parent,parentcls,sizeof(parentcls));
						if (client == 0) PrintToServer("Parented to %i %s %s",parent,parentname,parentcls);
						else PrintToChat(client,"Parented to %i %s %s",parent,parentname,parentcls);
					}
					if (HasEntProp(targ,Prop_Data,"m_vehicleScript"))
					{
						GetEntPropString(targ,Prop_Data,"m_vehicleScript",scrtmp,sizeof(scrtmp));
						Format(stateinf,sizeof(stateinf),"%sVehicleScript %s ",stateinf,scrtmp);
					}
					if (HasEntProp(targ,Prop_Data,"m_spawnEquipment"))
					{
						GetEntPropString(targ,Prop_Data,"m_spawnEquipment",scrtmp,sizeof(scrtmp));
						Format(stateinf,sizeof(stateinf),"%sAdditionalEquipment %s ",stateinf,scrtmp);
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
								if (j < 10) Format(scriptinf,sizeof(scriptinf),"%sTemplate0%i %s ",scriptinf,j,scrtmp);
								else Format(scriptinf,sizeof(scriptinf),"%sTemplate%i %s ",scriptinf,j,scrtmp);
							}
						}
					}
					TrimString(scriptinf);
					char inf[172];
					if (strlen(targname) > 0)
						Format(inf,sizeof(inf),"Name: %s ",targname);
					if (strlen(globname) > 0)
						Format(inf,sizeof(inf),"%sGlobalName: %s ",inf,globname);
					if (ammotype != -1)
						Format(inf,sizeof(inf),"%sAmmoType: %i",inf,ammotype);
					if (spawnflagsi != 0)
						Format(inf,sizeof(inf),"%sSpawnflags: %i",inf,spawnflagsi);
					if (vec[0] != -1.1)
						Format(inf,sizeof(inf),"%s\nOrigin %f %f %f",inf,vec[0],vec[1],vec[2]);
					if (angs[0] != -1.1)
						Format(inf,sizeof(inf),"%s Ang: %i %i %i",inf,RoundFloat(angs[0]),RoundFloat(angs[1]),RoundFloat(angs[2]));
					if (strlen(exprsc) > 0)
						Format(inf,sizeof(inf),"%s\nTarget: %s %i %s",inf,exprsc,exprsci,exprtargname);
					if (client == 0) PrintToServer("%s",inf);
					else PrintToChat(client,"%s",inf);
					if (strlen(scriptinf) > 1) PrintToConsole(client,"%s",scriptinf);
					if (HasEntProp(targ,Prop_Data,"m_bCarriedByPlayer"))
					{
						int ownert = GetEntProp(targ,Prop_Data,"m_bCarriedByPlayer");
						int ownerphy = GetEntProp(targ,Prop_Data,"m_bHackedByAlyx");
						//This property seems to exist on a few ents and changes colors/speed/relations
						//SetEntProp(targ,Prop_Data,"m_bHackedByAlyx",1);
						if (client == 0) PrintToServer("Owner: %i %i",ownert,ownerphy);
						else PrintToChat(client,"Owner: %i %i",ownert,ownerphy);
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
							if (client == 0) PrintToServer("Health: %i Max Health: %i Held: %i",targh,targmh,held);
							else PrintToChat(client,"Health: %i Max Health: %i Held: %i",targh,targmh,held);
						}
						else
						{
							if (client == 0) PrintToServer("Health: %i Max Health: %i",targh,targmh);
							else PrintToChat(client,"Health: %i Max Health: %i",targh,targmh);
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
					if (client == 0) PrintToServer("ID: %i %s %s Origin %f %f %f",j,clsname,fname,entorigin[0],entorigin[1],entorigin[2]);
					else PrintToChat(client,"ID: %i %s %s Origin %f %f %f",j,clsname,fname,entorigin[0],entorigin[1],entorigin[2]);
				}
			}
		}
		CloseHandle(arr);
	}
	return Plugin_Handled;
}

public Action getinf(int client, int args)
{
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
		char cmodel[64];
		GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
		int spawnflagsi = GetEntityFlags(targ);
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
		if (spawnflagsi != 0)
			Format(inf,sizeof(inf),"%sSpawnflags: %i",inf,spawnflagsi);
		if (vec[0] != -1.1)
			Format(inf,sizeof(inf),"%s\nOrigin %i %i %i",inf,RoundFloat(vec[0]),RoundFloat(vec[1]),RoundFloat(vec[2]));
		if (angs[0] != -1.1)
			Format(inf,sizeof(inf),"%s Ang: %i %i %i",inf,RoundFloat(angs[0]),RoundFloat(angs[1]),RoundFloat(angs[2]));
		if (strlen(exprsc) > 0)
			Format(inf,sizeof(inf),"%s\nTarget: %s %i %s",inf,exprsc,exprsci,exprtargname);
		PrintToChat(client,"%s",inf);
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
		PrintToChat(client,"%s %s %s",ent,targname,cmodel);
	}
	else
	{
		PrintToChat(client,"Not enough args, or invalid target");
	}
	return Plugin_Handled;
}

public Action setprops(int client, int args)
{
	int targ = -1;
	char first[32];
	char typechk[16];
	GetCmdArg(1, first, sizeof(first));
	bool pdata = false;
	if (args >= 4)
	{
		char pdatachk[32];
		GetCmdArg(4,pdatachk,sizeof(pdatachk));
		if ((StrEqual(pdatachk,"prop_data",false)) || (StrEqual(pdatachk,"1",false)))
			pdata = true;
		if (args > 4)
		{
			GetCmdArg(5,typechk,sizeof(typechk));
		}
	}
	if (StrEqual(first,"!self",false))
		targ = client;
	else if (StrEqual(first,"!picker",false))
		targ = GetClientAimTarget(client, false);
	else if ((StringToInt(first) != 0) && (strlen(first) > 0))
		targ = StringToInt(first);
	else
	{
		Handle arr = CreateArray(64);
		findentsarrtarg(arr,first);
		//Checks must be separate
		if (arr == INVALID_HANDLE)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",first);
			else PrintToChat(client,"No entities found with either classname or targetname of %s",first);
			return Plugin_Handled;
		}
		else if (GetArraySize(arr) < 1)
		{
			if (client == 0) PrintToServer("No entities found with either classname or targetname of %s",first);
			else PrintToChat(client,"No entities found with either classname or targetname of %s",first);
			return Plugin_Handled;
		}
		else
		{
			if (args > 1)
			{
				char propname[32];
				char cls[64];
				GetCmdArg(2, propname, sizeof(propname));
				for (int i = 0;i<GetArraySize(arr);i++)
				{
					targ = GetArrayCell(arr,i);
					GetEntityClassname(targ,cls,sizeof(cls));
					if (HasEntProp(targ,Prop_Send,propname))
					{
						PropFieldType type;
						FindDataMapInfo(targ,propname,type);
						if (type == PropField_String)
						{
							char propinf[64];
							GetEntPropString(targ,Prop_Send,propname,propinf,sizeof(propinf));
							if (client == 0) PrintToServer("%i %s %s is %s",targ,cls,propname,propinf);
							else PrintToChat(client,"%i %s %s is %s",targ,cls,propname,propinf);
						}
						else if (type == PropField_Entity)
						{
							int enth = GetEntPropEnt(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s %s is %i",targ,cls,propname,enth);
							else PrintToChat(client,"%i %s %s is %i",targ,cls,propname,enth);
						}
						else if (type == PropField_Integer)
						{
							int enti = GetEntProp(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s %s is %i",targ,cls,propname,enti);
							else PrintToChat(client,"%i %s %s is %i",targ,cls,propname,enti);
						}
						else if (type == PropField_Float)
						{
							float entf = GetEntPropFloat(targ,Prop_Send,propname);
							if (client == 0) PrintToServer("%i %s %s is %f",targ,cls,propname,entf);
							else PrintToChat(client,"%i %s %s is %f",targ,cls,propname,entf);
						}
						else if (type == PropField_Vector)
						{
							float entvec[3];
							GetEntPropVector(targ,Prop_Send,propname,entvec);
							if (client == 0) PrintToServer("%i %s %s is %f %f %f",targ,cls,propname,entvec[0],entvec[1],entvec[2]);
							else PrintToChat(client,"%i %s %s is %f %f %f",targ,cls,propname,entvec[0],entvec[1],entvec[2]);
						}
					}
					else if (HasEntProp(targ,Prop_Data,propname))
					{
						PropFieldType type;
						FindDataMapInfo(targ,propname,type);
						if ((type == PropField_String) || (type == PropField_String_T))
						{
							char propinf[64];
							GetEntPropString(targ,Prop_Data,propname,propinf,sizeof(propinf));
							if (client == 0) PrintToServer("%i %s %s is %s",targ,cls,propname,propinf);
							else PrintToChat(client,"%i %s %s is %s",targ,cls,propname,propinf);
						}
						else if (type == PropField_Entity)
						{
							int enth = GetEntPropEnt(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s %s is %i",targ,cls,propname,enth);
							else PrintToChat(client,"%i %s %s is %i",targ,cls,propname,enth);
						}
						else if (type == PropField_Integer)
						{
							int enti = GetEntProp(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s %s is %i",targ,cls,propname,enti);
							else PrintToChat(client,"%i %s %s is %i",targ,cls,propname,enti);
						}
						else if (type == PropField_Float)
						{
							float entf = GetEntPropFloat(targ,Prop_Data,propname);
							if (client == 0) PrintToServer("%i %s %s is %f",targ,cls,propname,entf);
							else PrintToChat(client,"%i %s %s is %f",targ,cls,propname,entf);
						}
						else if (type == PropField_Vector)
						{
							float entvec[3];
							GetEntPropVector(targ,Prop_Data,propname,entvec);
							if (client == 0) PrintToServer("%i %s %s is %f %f %f",targ,cls,propname,entvec[0],entvec[1],entvec[2]);
							else PrintToChat(client,"%i %s %s is %f %f %f",targ,cls,propname,entvec[0],entvec[1],entvec[2]);
						}
					}
					else
					{
						if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,cls,propname);
						else PrintToChat(client,"%i doesn't have the %s property.",targ,cls,propname);
					}
				}
			}
			return Plugin_Handled;
		}
	}
	if ((targ != -1) && (IsValidEntity(targ)))
	{
		char propname[32];
		if (args == 2)
		{
			GetCmdArg(2, propname, sizeof(propname));
			if (HasEntProp(targ,Prop_Send,propname))
			{
				PropFieldType type;
				FindDataMapInfo(targ,propname,type);
				if (type == PropField_String)
				{
					char propinf[64];
					GetEntPropString(targ,Prop_Send,propname,propinf,sizeof(propinf));
					if (client == 0) PrintToServer("%i %s is %s",targ,propname,propinf);
					else PrintToChat(client,"%i %s is %s",targ,propname,propinf);
					return Plugin_Handled;
				}
				else if (type == PropField_Entity)
				{
					int enth = GetEntPropEnt(targ,Prop_Send,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,enth);
					else PrintToChat(client,"%i %s is %i",targ,propname,enth);
					return Plugin_Handled;
				}
				else if (type == PropField_Integer)
				{
					int enti = GetEntProp(targ,Prop_Send,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,enti);
					else PrintToChat(client,"%i %s is %i",targ,propname,enti);
					return Plugin_Handled;
				}
				else if (type == PropField_Float)
				{
					float entf = GetEntPropFloat(targ,Prop_Send,propname);
					if (client == 0) PrintToServer("%i %s is %f",targ,propname,entf);
					else PrintToChat(client,"%i %s is %f",targ,propname,entf);
					return Plugin_Handled;
				}
				else if (type == PropField_Vector)
				{
					float entvec[3];
					GetEntPropVector(targ,Prop_Send,propname,entvec);
					if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
					else PrintToChat(client,"%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
					return Plugin_Handled;
				}
			}
			if (HasEntProp(targ,Prop_Data,propname))
			{
				PropFieldType type;
				FindDataMapInfo(targ,propname,type);
				if ((type == PropField_String) || (type == PropField_String_T))
				{
					char propinf[64];
					GetEntPropString(targ,Prop_Data,propname,propinf,sizeof(propinf));
					if (client == 0) PrintToServer("%i %s is %s",targ,propname,propinf);
					else PrintToChat(client,"%i %s is %s",targ,propname,propinf);
					return Plugin_Handled;
				}
				else if (type == PropField_Entity)
				{
					int enth = GetEntPropEnt(targ,Prop_Data,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,enth);
					else PrintToChat(client,"%i %s is %i",targ,propname,enth);
					return Plugin_Handled;
				}
				else if (type == PropField_Integer)
				{
					int enti = GetEntProp(targ,Prop_Data,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,enti);
					else PrintToChat(client,"%i %s is %i",targ,propname,enti);
					return Plugin_Handled;
				}
				else if (type == PropField_Float)
				{
					float entf = GetEntPropFloat(targ,Prop_Data,propname);
					if (client == 0) PrintToServer("%i %s is %f",targ,propname,entf);
					else PrintToChat(client,"%i %s is %f",targ,propname,entf);
					return Plugin_Handled;
				}
				else if (type == PropField_Vector)
				{
					float entvec[3];
					GetEntPropVector(targ,Prop_Data,propname,entvec);
					if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
					else PrintToChat(client,"%i %s is %f %f %f",targ,propname,entvec[0],entvec[1],entvec[2]);
					return Plugin_Handled;
				}
			}
			if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
			else PrintToChat(client,"%i doesn't have the %s property.",targ,propname);
			return Plugin_Handled;
		}
		bool usefloat = false;
		bool usestring = false;
		bool getpropinf = false;
		bool getent = false;
		bool usevec = false;
		char secondintchk[16];
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
		GetCmdArg(3, secondintchk, sizeof(secondintchk));
		float secondfl = StringToFloat(secondintchk);
		int secondint = StringToInt(secondintchk);
		float secondvec[3];
		char vecchk[4][16];
		ExplodeString(secondintchk," ",vecchk,4,16);
		if (strlen(vecchk[2]) > 0)
		{
			usevec = true;
			secondvec[0] = StringToFloat(vecchk[0]);
			secondvec[1] = StringToFloat(vecchk[1]);
			secondvec[2] = StringToFloat(vecchk[2]);
		}
		if ((((secondint > 0) || (secondint < 0)) || (StrEqual(secondintchk,"0",false))) && (StrContains(secondintchk,".",false) == -1))
		{
			usefloat = false;
			usestring = false;
		}
		else if (secondfl != 0.0)
			usefloat = true;
		else
			usestring = true;
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
		else
		{
			if (client == 0) PrintToServer("%s %f %i",secondintchk,secondfl,secondint);
			else PrintToChat(client,"%s %f %i",secondintchk,secondfl,secondint);
		}
		if (usevec)
		{
			if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
			{
				if (getpropinf)
				{
					GetEntPropVector(targ,Prop_Send,propname,secondvec);
					if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
					else PrintToChat(client,"Set %i's %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
				}
				else
				{
					SetEntPropVector(targ,Prop_Send,propname,secondvec);
					if (client == 0) PrintToServer("Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
					else PrintToChat(client,"Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
				}
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				if (getpropinf)
				{
					GetEntPropVector(targ,Prop_Data,propname,secondvec);
					if (client == 0) PrintToServer("%i %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
					else PrintToChat(client,"%i %s is %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
				}
				else
				{
					SetEntPropVector(targ,Prop_Data,propname,secondvec);
					if (client == 0) PrintToServer("Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
					else PrintToChat(client,"Set %i's %s to %f %f %f",targ,propname,secondvec[0],secondvec[1],secondvec[2]);
				}
			}
			else
			{
				if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
				else PrintToChat(client,"%i doesn't have the %s property.",targ,propname);
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
					else PrintToChat(client,"Set %i's %s is %f",targ,propname,flchk);
				}
				else
				{
					SetEntPropFloat(targ,Prop_Send,propname,secondfl);
					if (client == 0) PrintToServer("Set %i's %s to %f",targ,propname,secondfl);
					else PrintToChat(client,"Set %i's %s to %f",targ,propname,secondfl);
				}
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				if (getpropinf)
				{
					float flchk = GetEntPropFloat(targ,Prop_Data,propname);
					if (client == 0) PrintToServer("%i %s is %f",targ,propname,flchk);
					else PrintToChat(client,"%i %s is %f",targ,propname,flchk);
				}
				else
				{
					SetEntPropFloat(targ,Prop_Data,propname,secondfl);
					if (client == 0) PrintToServer("Set %i's %s to %f",targ,propname,secondfl);
					else PrintToChat(client,"Set %i's %s to %f",targ,propname,secondfl);
				}
			}
			else
			{
				if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
				else PrintToChat(client,"%i doesn't have the %s property.",targ,propname);
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
					else PrintToChat(client,"%i %s is %s",targ,propname,chchk);
				}
				else
				{
					SetEntPropString(targ,Prop_Send,propname,secondintchk);
					if (client == 0) PrintToServer("Set %i's %s to %s",targ,propname,secondintchk);
					else PrintToChat(client,"Set %i's %s to %s",targ,propname,secondintchk);
				}
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				if (getpropinf)
				{
					char chchk[64];
					GetEntPropString(targ,Prop_Data,propname,chchk,sizeof(chchk));
					if (client == 0) PrintToServer("%i %s is %s",targ,propname,chchk);
					else PrintToChat(client,"%i %s is %s",targ,propname,chchk);
				}
				else
				{
					SetEntPropString(targ,Prop_Data,propname,secondintchk);
					if (client == 0) PrintToServer("Set %i's %s to %s",targ,propname,secondintchk);
					else PrintToChat(client,"Set %i's %s to %s",targ,propname,secondintchk);
				}
			}
			else
			{
				if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
				else PrintToChat(client,"%i doesn't have the %s property.",targ,propname);
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
					else PrintToChat(client,"%i %s is %i",targ,propname,intchk);
				}
				else
				{
					SetEntPropEnt(targ,Prop_Send,propname,secondint);
					if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
					else PrintToChat(client,"Set %i's %s to %i",targ,propname,secondint);
				}
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				if (getpropinf)
				{
					int intchk = GetEntPropEnt(targ,Prop_Data,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
					else PrintToChat(client,"%i %s is %i",targ,propname,intchk);
				}
				else
				{
					SetEntPropEnt(targ,Prop_Data,propname,secondint);
					if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
					else PrintToChat(client,"Set %i's %s to %i",targ,propname,secondint);
				}
			}
			else
			{
				if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
				else PrintToChat(client,"%i doesn't have the %s property.",targ,propname);
			}
		}
		else
		{
			if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
			{
				if (getpropinf)
				{
					int intchk = GetEntProp(targ,Prop_Send,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
					else PrintToChat(client,"%i %s is %i",targ,propname,intchk);
				}
				else
				{
					SetEntProp(targ,Prop_Send,propname,secondint);
					if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
					else PrintToChat(client,"Set %i's %s to %i",targ,propname,secondint);
				}
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				if (getpropinf)
				{
					int intchk = GetEntProp(targ,Prop_Data,propname);
					if (client == 0) PrintToServer("%i %s is %i",targ,propname,intchk);
					else PrintToChat(client,"%i %s is %i",targ,propname,intchk);
				}
				else
				{
					SetEntProp(targ,Prop_Data,propname,secondint);
					if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
					else PrintToChat(client,"Set %i's %s to %i",targ,propname,secondint);
				}
			}
			else
			{
				if (client == 0) PrintToServer("%i doesn't have the %s property.",targ,propname);
				else PrintToChat(client,"%i doesn't have the %s property.",targ,propname);
			}
		}
	}
	else
	{
		if (client == 0) PrintToServer("Invalid target");
		else PrintToChat(client,"Invalid target");
	}
	return Plugin_Handled;
}
