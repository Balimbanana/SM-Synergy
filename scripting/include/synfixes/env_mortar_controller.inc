void camthink(int entity)
{
	if (IsValidEntity(entity))
	{
		int pv = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if (IsValidEntity(pv))
		{
			float orgs[3];
			float angs[3];
			if (HasEntProp(pv,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(pv,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(pv,Prop_Send,"m_vecOrigin")) GetEntPropVector(pv,Prop_Send,"m_vecOrigin",orgs);
			GetEntPropVector(pv,Prop_Data,"m_angAbsRotation",angs);
			for (int i = 0;i<4;i++)
			{
				if (i >= 1) angs[1]+=90.0;
				float tmporgs[3];
				tmporgs[0] = (orgs[0] + (90.0 * Cosine(DegToRad(angs[1]))));
				tmporgs[1] = (orgs[1] + (90.0 * Sine(DegToRad(angs[1]))));
				tmporgs[2] = (orgs[2]);
				if (TR_PointOutsideWorld(tmporgs))
				{
					float stop[3];
					TeleportEntity(pv,NULL_VECTOR,NULL_VECTOR,stop);
				}
			}
			int controller = GetEntPropEnt(pv,Prop_Data,"m_hEffectEntity");
			if (IsValidEntity(controller))
			{
				float controllerpos[3];
				if (HasEntProp(controller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(controller,Prop_Data,"m_vecAbsOrigin",controllerpos);
				else if (HasEntProp(controller,Prop_Send,"m_vecOrigin")) GetEntPropVector(controller,Prop_Send,"m_vecOrigin",controllerpos);
				controllerpos[2] = orgs[2];
				float chkdist = GetVectorDistance(controllerpos,orgs,false);
				if (chkdist > 2000.0)
				{
					float stop[3];
					TeleportEntity(pv,NULL_VECTOR,NULL_VECTOR,stop);
				}
			}
		}
	}
}

public Action passmortar(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		float fhitpos[3];
		int mortar = ReadPackCell(dp);
		fhitpos[0] = ReadPackFloat(dp);
		fhitpos[1] = ReadPackFloat(dp);
		fhitpos[2] = ReadPackFloat(dp);
		if (IsValidEntity(mortar))
		{
			float orgs[3];
			if (HasEntProp(mortar,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(mortar,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(mortar,Prop_Send,"m_vecOrigin")) GetEntPropVector(mortar,Prop_Send,"m_vecOrigin",orgs);
			float toang[3];
			float shootvel[3];
			MakeVectorFromPoints(orgs,fhitpos,shootvel);
			GetVectorAngles(shootvel,toang);
			toang[0]+=90.0;
			TeleportEntity(mortar,NULL_VECTOR,toang,shootvel);
			CreateTimer(1.0,explodemort,mortar,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	CloseHandle(dp);
	return Plugin_Handled;
}

public Action explodemort(Handle timer, int mortar)
{
	if (IsValidEntity(mortar))
	{
		char cls[32];
		GetEntityClassname(mortar,cls,sizeof(cls));
		if (StrEqual(cls,"grenade_mortar_large",false)) ExplodeMortar(mortar);
	}
}

public MortarExplodeByBreak(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		ExplodeMortar(caller);
	}
}

public Action MortarExplode(int entity, int other)
{
	if (IsValidEntity(entity))
	{
		ExplodeMortar(entity);
	}
}

void ExplodeMortar(int entity)
{
	if (IsValidEntity(entity))
	{
		int randexpl = GetRandomInt(1,3);
		char snd[128];
		Format(snd,sizeof(snd),"weapons\\mortar\\mortar_explo%i.wav",randexpl);
		EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		int expl = CreateEntityByName("env_explosion");
		if (expl != -1)
		{
			float orgs[3];
			float angs[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
			GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
			TeleportEntity(expl,orgs,angs,NULL_VECTOR);
			DispatchKeyValue(expl,"imagnitude","1100");
			DispatchKeyValue(expl,"iradiusoverride","900");
			DispatchKeyValue(expl,"targetname","syn_mortarexpl");
			DispatchSpawn(expl);
			ActivateEntity(expl);
			AcceptEntityInput(expl,"Explode");
		}
		AcceptEntityInput(entity,"kill");
	}
}