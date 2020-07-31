void FindDispensers(char[] input, char[] targn, float delay)
{
	Handle arr = CreateArray(64);
	FindAllByClassname(arr,-1,"env_dispenser");
	if (GetArraySize(arr) > 0)
	{
		for (int i = 0;i<GetArraySize(arr);i++)
		{
			int ent = GetArrayCell(arr,i);
			if (IsValidEntity(ent))
			{
				if (HasEntProp(ent,Prop_Data,"m_iName"))
				{
					char enttargn[64];
					GetEntPropString(ent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
					if (StrEqual(targn,enttargn,false))
					{
						if (StrEqual(input,"Activate",false))
						{
							if (delay > 0.1) CreateTimer(delay,EnvDispActivatedelay,ent,TIMER_FLAG_NO_MAPCHANGE);
							else EnvDispActivate(ent);
						}
						else if (StrEqual(input,"Break",false))
						{
							if (delay > 0.1) CreateTimer(delay,EnvDispBreakdelay,ent,TIMER_FLAG_NO_MAPCHANGE);
							else EnvDispBreak(ent);
						}
					}
				}
			}
		}
	}
	CloseHandle(arr);
}

public Action EnvDispActivatedelay(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		EnvDispActivate(entity);
	}
}

public Action EnvDispBreakdelay(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		EnvDispBreak(entity);
	}
}

void EnvDispActivate(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_iHealth"))
		{
			int cur = GetEntProp(entity,Prop_Data,"m_iHealth");
			int max = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
			if (cur < max)
			{
				SetEntProp(entity,Prop_Data,"m_iHealth",cur+1);
				char spawnmodel[64];
				GetEntPropString(entity,Prop_Data,"m_ModelName",spawnmodel,sizeof(spawnmodel));
				int skinmin = GetEntProp(entity,Prop_Data,"m_iTeamNum");
				int skinmax = GetEntProp(entity,Prop_Data,"m_iInitialTeamNum");
				float spawnpos[3];
				float spawnang[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",spawnpos);
				else if (HasEntProp(entity,Prop_Data,"m_vecOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecOrigin",spawnpos);
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",spawnang);
				if (strlen(spawnmodel) > 0)
				{
					if (FileExists(spawnmodel,true,NULL_STRING))
					{
						char randskin[4];
						Format(randskin,sizeof(randskin),"%i",GetRandomInt(skinmin,skinmax));
						int spawnent = CreateEntityByName("prop_physics_override");
						if (spawnent != -1)
						{
							DispatchKeyValue(spawnent,"solid","6");
							DispatchKeyValue(spawnent,"model",spawnmodel);
							DispatchKeyValue(spawnent,"skin",randskin);
							DispatchSpawn(spawnent);
							ActivateEntity(spawnent);
							TeleportEntity(spawnent,spawnpos,spawnang,NULL_VECTOR);
						}
					}
				}
			}
		}
	}
}

void EnvDispBreak(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_iHealth"))
		{
			int cur = GetEntProp(entity,Prop_Data,"m_iHealth");
			int max = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
			if (cur < max)
			{
				char spawnmodel[64];
				GetEntPropString(entity,Prop_Data,"m_ModelName",spawnmodel,sizeof(spawnmodel));
				int skinmin = GetEntProp(entity,Prop_Data,"m_iTeamNum");
				int skinmax = GetEntProp(entity,Prop_Data,"m_iInitialTeamNum");
				float spawnpos[3];
				float spawnang[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",spawnpos);
				else if (HasEntProp(entity,Prop_Data,"m_vecOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecOrigin",spawnpos);
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",spawnang);
				for (int i = cur;i < max+1;i++)
				{
					Handle dp = CreateDataPack();
					WritePackString(dp,spawnmodel);
					WritePackCell(dp,skinmin);
					WritePackCell(dp,skinmax);
					WritePackFloat(dp,spawnpos[0]);
					WritePackFloat(dp,spawnpos[1]);
					WritePackFloat(dp,spawnpos[2]);
					WritePackFloat(dp,spawnang[0]);
					WritePackFloat(dp,spawnang[1]);
					WritePackFloat(dp,spawnang[2]);
					float timenext = (0.1 + (i/10));
					CreateTimer(timenext,EnvDispenserBreakloop,dp,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		AcceptEntityInput(entity,"kill");
	}
}

public Action EnvDispenserBreakloop(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char spawnmodel[64];
		ReadPackString(dp,spawnmodel,sizeof(spawnmodel));
		int skinmin = ReadPackCell(dp);
		int skinmax = ReadPackCell(dp);
		float spawnpos[3];
		float spawnang[3];
		spawnpos[0] = ReadPackFloat(dp);
		spawnpos[1] = ReadPackFloat(dp);
		spawnpos[2] = ReadPackFloat(dp);
		spawnang[0] = ReadPackFloat(dp);
		spawnang[1] = ReadPackFloat(dp);
		spawnang[2] = ReadPackFloat(dp);
		CloseHandle(dp);
		if (strlen(spawnmodel) > 0)
		{
			if (FileExists(spawnmodel,true,NULL_STRING))
			{
				char randskin[4];
				Format(randskin,sizeof(randskin),"%i",GetRandomInt(skinmin,skinmax));
				int spawnent = CreateEntityByName("prop_physics_override");
				if (spawnent != -1)
				{
					DispatchKeyValue(spawnent,"solid","6");
					DispatchKeyValue(spawnent,"model",spawnmodel);
					DispatchKeyValue(spawnent,"skin",randskin);
					DispatchSpawn(spawnent);
					ActivateEntity(spawnent);
					TeleportEntity(spawnent,spawnpos,spawnang,NULL_VECTOR);
				}
			}
		}
	}
}