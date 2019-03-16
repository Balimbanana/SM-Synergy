#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <updater>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.05"
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
	RegAdminCmd("cinp",cinp,ADMFLAG_BAN,"ent_fire");
	RegAdminCmd("entinput",cinp,ADMFLAG_BAN,"ent_fire");
	RegAdminCmd("changeclasses",changeclasses,ADMFLAG_BAN,"ChangeClasses");
	RegConsoleCmd("gi",getinf);
	RegAdminCmd("tn",sett,ADMFLAG_PASSWORD,"SetName");
	RegAdminCmd("sm_sep",setprops,ADMFLAG_ROOT,".");
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
		bool vehiclemodeldefined = false
		GetClientAbsOrigin(client, Location);
		GetClientEyeAngles(client, Angles);
		PlayerOrigin[0] = (Location[0] + (100 * Cosine(DegToRad(Angles[1]))));
		PlayerOrigin[1] = (Location[1] + (100 * Sine(DegToRad(Angles[1]))));
		PlayerOrigin[2] = (Location[2] + 70);
		int stuff = CreateEntityByName(ent);
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
		if ((StrContains(ent,"prop_vehicle",false) != -1) && (!vehiclemodeldefined))
		{
			PrintToChat(client,"Model must be defined for this type of entity.");
			return Plugin_Handled;
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
		TeleportEntity(stuff, fhitpos, NULL_VECTOR, NULL_VECTOR);
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
						if (!FileExists(tmp2,true,NULL_STRING))
						{
							PrintToChat(client,"The model %s was not found.",tmp2);
							return Plugin_Handled;
						}
					}
					DispatchKeyValue(stuff,tmp,tmp2);
				}
				Format(fullstr,sizeof(fullstr),"%s %s %s",fullstr,tmp,tmp2);
				v++;
			}
		}
		PrintToConsole(client,"%s",fullstr);
		DispatchSpawn(stuff);
		ActivateEntity(stuff);
	}
	return Plugin_Handled;
}

public Action cinp(int client, int args)
{
	char fullinp[64];
	char firstarg[16];
	GetCmdArgString(fullinp, sizeof(fullinp));
	GetCmdArg(1,firstarg, sizeof(firstarg));
	PrintToConsole(client,"%s",fullinp);
	if (StrContains(fullinp,",",false) != -1)
	{
		int loginp = CreateEntityByName("logic_auto");
		DispatchKeyValue(loginp, "spawnflags","1");
		DispatchKeyValue(loginp, "OnMapSpawn",fullinp);
		DispatchSpawn(loginp);
		ActivateEntity(loginp);
	}
	else if (StrEqual(firstarg,"name",false))
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
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		if((thisent >= 0) && (FindValueInArray(arr, thisent) == -1))
		{
			PushArrayCell(arr, thisent);
		}
		findentsarr(arr,thisent++,clsname);
	}
	if (GetArraySize(arr) > 0) return arr;
	return INVALID_HANDLE;
}

public Action getinf(int client, int args)
{
	int targ = GetClientAimTarget(client, false);
	if (targ != -1)
	{
		PrintToChat(client,"%i",targ);
		char ent[32];
		char targname[64];
		char globname[64];
		float vec[3];
		float angs[3];
		int parent = 0;
		int ammotype = -1;
		vec[0] = -1.1;
		angs[0] = -1.1;
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
		char cmodel[64];
		GetEntPropString(targ,Prop_Data,"m_ModelName",cmodel,sizeof(cmodel));
		int spawnflagsi = GetEntityFlags(targ);
		PrintToChat(client,"%s %s",ent,cmodel);
		if (parent > 0)
		{
			char parentname[32];
			if (HasEntProp(parent,Prop_Data,"m_iName"))
				GetEntPropString(parent,Prop_Data,"m_iName",parentname,sizeof(parentname));
			char parentcls[32];
			GetEntityClassname(parent,parentcls,sizeof(parentcls));
			PrintToChat(client,"Parented to %i %s %s",parent,parentname,parentcls);
		}
		char inf[128];
		if (strlen(targname) > 0)
			Format(inf,sizeof(inf),"Name: %s ",targname);
		if (strlen(globname) > 0)
			Format(inf,sizeof(inf),"%sGlobalName: %s ",inf,globname);
		if (ammotype != -1)
			Format(inf,sizeof(inf),"%sAmmoType: %i",inf,ammotype);
		if (spawnflagsi != 0)
			Format(inf,sizeof(inf),"%sSpawnflags: %i",inf,spawnflagsi);
		if (vec[0] != -1.1)
			Format(inf,sizeof(inf),"%s\nVec: %i %i %i",inf,RoundFloat(vec[0]),RoundFloat(vec[1]),RoundFloat(vec[2]));
		if (angs[0] != -1.1)
			Format(inf,sizeof(inf),"%s Ang: %i %i %i",inf,RoundFloat(angs[0]),RoundFloat(angs[1]),RoundFloat(angs[2]));
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
	GetCmdArg(1, first, sizeof(first));
	bool pdata = false;
	if (args == 4)
	{
		char pdatachk[32];
		GetCmdArg(4,pdatachk,sizeof(pdatachk));
		if ((StrEqual(pdatachk,"prop_data",false)) || (StrEqual(pdatachk,"1",false)))
			pdata = true;
	}
	if (StrEqual(first,"!self",false))
		targ = client;
	else if (StrEqual(first,"!picker",false))
		targ = GetClientAimTarget(client, false);
	else
		targ = StringToInt(first);
	if ((targ != -1) && (IsValidEntity(targ)))
	{
		bool usefloat = false;
		bool usestring = false;
		char secondintchk[16];
		char propname[32];
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
		GetCmdArg(3, secondintchk, sizeof(secondintchk))
		float secondfl = StringToFloat(secondintchk);
		int secondint = StringToInt(secondintchk);
		PrintToChat(client,"%s %f %i",secondintchk,secondfl,secondint);
		if ((((secondint > 0) || (secondint < 0)) || (StrEqual(secondintchk,"0",false))) && (StrContains(secondintchk,".",false) == -1))
		{
			usefloat = false;
			usestring = false;
		}
		else if (secondfl != 0.0)
			usefloat = true;
		else
			usestring = true;
		if (usefloat)
		{
			if ((!pdata) && (HasEntProp(targ,Prop_Send,propname)))
			{
				SetEntPropFloat(targ,Prop_Send,propname,secondfl);
				if (client == 0) PrintToServer("Set %i's %s to %f",targ,propname,secondfl);
				else PrintToChat(client,"Set %i's %s to %f",targ,propname,secondfl);
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				SetEntPropFloat(targ,Prop_Data,propname,secondfl);
				if (client == 0) PrintToServer("Set %i's %s to %f",targ,propname,secondfl);
				else PrintToChat(client,"Set %i's %s to %f",targ,propname,secondfl);
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
				SetEntPropString(targ,Prop_Send,propname,secondintchk);
				if (client == 0) PrintToServer("Set %i's %s to %s",targ,propname,secondintchk);
				else PrintToChat(client,"Set %i's %s to %s",targ,propname,secondintchk);
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				SetEntPropString(targ,Prop_Data,propname,secondintchk);
				if (client == 0) PrintToServer("Set %i's %s to %s",targ,propname,secondintchk);
				else PrintToChat(client,"Set %i's %s to %s",targ,propname,secondintchk);
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
				SetEntProp(targ,Prop_Send,propname,secondint);
				if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
				else PrintToChat(client,"Set %i's %s to %i",targ,propname,secondint);
			}
			else if ((pdata) && (HasEntProp(targ,Prop_Data,propname)))
			{
				SetEntProp(targ,Prop_Data,propname,secondint);
				if (client == 0) PrintToServer("Set %i's %s to %i",targ,propname,secondint);
				else PrintToChat(client,"Set %i's %s to %i",targ,propname,secondint);
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
