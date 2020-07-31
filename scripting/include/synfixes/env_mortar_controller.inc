int bMortarControls[128];

enum
{
	bPressedForward = (1 << 0),
	bPressedLeft = (1 << 1),
	bPressedRight = (1 << 2),
	bPressedBack = (1 << 3)
}

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
			float aimdown[3];
			float groundpos[3];
			aimdown[0] = 90.0;
			Handle hhitpos = TR_TraceRayFilterEx(orgs,aimdown,MASK_SHOT,RayType_Infinite,TraceEntityFilter,entity);
			TR_GetEndPosition(groundpos,hhitpos);
			CloseHandle(hhitpos);
			if (GetVectorDistance(groundpos,orgs,false) < 150.0)
			{
				orgs[0] = groundpos[0];
				orgs[1] = groundpos[1];
				orgs[2] = groundpos[2];
			}
			orgs[2]+=5.0;
			GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
			TeleportEntity(expl,orgs,angs,NULL_VECTOR);
			DispatchKeyValue(expl,"imagnitude","1100");
			DispatchKeyValue(expl,"iradiusoverride","1200");
			DispatchKeyValue(expl,"targetname","syn_mortarexpl");
			DispatchSpawn(expl);
			ActivateEntity(expl);
			AcceptEntityInput(expl,"Explode");
		}
		AcceptEntityInput(entity,"kill");
	}
}

public Action env_mortarcontrolleractivate(int entity, int activator, int caller, UseType type, float value)
{
	//PrintToServer("EntUse %i %i %i %i",entity,activator,caller,type);
	if ((activator < MaxClients) && (activator > 0))
	{
		int uiact = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if (IsValidEntity(uiact))
		{
			int plyact = GetEntPropEnt(uiact,Prop_Data,"m_player");
			if (plyact == -1) AcceptEntityInput(uiact,"Activate",activator);
			else if (plyact == activator) AcceptEntityInput(uiact,"Deactivate",activator);
		}
	}
}

public void env_mortarcontroller(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		//PrintToServer("Output %s from %i to %i",output,activator,caller);
		if (HasEntProp(caller,Prop_Data,"m_hEffectEntity"))
		{
			int pv = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if (IsValidEntity(pv))
			{
				float orgs[3];
				float angs[3];
				if (HasEntProp(pv,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(pv,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(pv,Prop_Send,"m_vecOrigin")) GetEntPropVector(pv,Prop_Send,"m_vecOrigin",orgs);
				GetEntPropVector(pv,Prop_Data,"m_angAbsRotation",angs);
				float Time = GetTickedTime();
				if (StrEqual(output,"PlayerOff",false))
				{
					bMortarControls[activator] = 0;
					AcceptEntityInput(pv,"Disable",activator);
					float stop[3];
					TeleportEntity(pv,NULL_VECTOR,NULL_VECTOR,stop);
					
				}
				else if ((StrEqual(output,"PressedAttack",false)) && (centnextatk[caller] < Time))
				{
					int mortarcontrol = GetEntPropEnt(pv,Prop_Data,"m_hEffectEntity");
					if (IsValidEntity(mortarcontrol))
					{
						char mortarfirefrom[64];
						GetEntPropString(mortarcontrol,Prop_Data,"m_iszResponseContext",mortarfirefrom,sizeof(mortarfirefrom));
						if (strlen(mortarfirefrom) > 0)
						{
							int firefrom = findtrack(-1,"env_mortar_launcher",mortarfirefrom);
							if ((!IsValidEntity(firefrom)) || (firefrom == 0)) firefrom = pv;
							if (IsValidEntity(firefrom))
							{
								float fhitpos[3];
								float shootvel[3];
								float firefrompos[3];
								float toang[3];
								Handle hhitpos = INVALID_HANDLE;
								TR_TraceRayFilter(orgs,angs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,pv);
								TR_GetEndPosition(fhitpos,hhitpos);
								CloseHandle(hhitpos);
								if (HasEntProp(firefrom,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(firefrom,Prop_Data,"m_vecAbsOrigin",firefrompos);
								else if (HasEntProp(firefrom,Prop_Send,"m_vecOrigin")) GetEntPropVector(firefrom,Prop_Send,"m_vecOrigin",firefrompos);
								MakeVectorFromPoints(firefrompos,orgs,shootvel);
								GetVectorAngles(shootvel,toang);
								int mortar = CreateEntityByName("prop_physics_override");
								if (mortar != -1)
								{
									DispatchKeyValue(mortar,"model","models/props_st/st_missile.mdl");
									DispatchKeyValue(mortar,"solid","6");
									DispatchKeyValue(mortar,"spawnflags","32");//16 32
									DispatchKeyValue(mortar,"inertiaScale","5.0");
									DispatchKeyValue(mortar,"massScale","5");
									DispatchKeyValue(mortar,"health","1");
									DispatchKeyValue(mortar,"classname","grenade_mortar_large");
									TeleportEntity(mortar,firefrompos,toang,NULL_VECTOR);
									DispatchSpawn(mortar);
									ActivateEntity(mortar);
									ScaleVector(shootvel,2.0);
									TeleportEntity(mortar,NULL_VECTOR,NULL_VECTOR,shootvel);
									SetEntPropEnt(mortar,Prop_Data,"m_hEffectEntity",pv);
									Handle dppass = CreateDataPack();
									WritePackCell(dppass,mortar);
									WritePackFloat(dppass,fhitpos[0]);
									WritePackFloat(dppass,fhitpos[1]);
									WritePackFloat(dppass,fhitpos[2]);
									CreateTimer(1.0,passmortar,dppass,TIMER_FLAG_NO_MAPCHANGE);
									centnextatk[caller] = Time + 3.0;
									if (FindStringInArray(precachedarr,"env_mortar_launcher") == -1)
									{
										char searchprecache[128];
										Format(searchprecache,sizeof(searchprecache),"sound/weapons/mortar/");
										recursion(searchprecache);
										PushArrayString(precachedarr,"env_mortar_launcher");
									}
									char snd[128];
									int randlaunch = GetRandomInt(1,3);
									if (randlaunch == 3) Format(snd,sizeof(snd),"weapons\\mortar\\mortar_launch_shell.wav");
									else Format(snd,sizeof(snd),"weapons\\mortar\\mortar_launch%i.wav",randlaunch);
									EmitSoundToAll(snd, mortar, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									HookSingleEntityOutput(mortar,"OnBreak",MortarExplodeByBreak);
									SDKHook(mortar,SDKHook_StartTouch,MortarExplode);
								}
							}
						}
					}
				}
				else if ((StrContains(output,"Unpressed",false) == -1) && (!StrEqual(output,"PressedAttack",false)))
				{
					float loc[3];
					if (StrEqual(output,"PressedMoveLeft",false))
					{
						angs[1]+=90.0;
						if (bMortarControls[activator] & bPressedForward) angs[1]-=45.0;
						else if (bMortarControls[activator] & bPressedBack) angs[1]+=45.0;
						if (!(bMortarControls[activator] & bPressedLeft)) bMortarControls[activator] |= bPressedLeft;
					}
					if (StrEqual(output,"PressedMoveRight",false))
					{
						angs[1]-=90.0;
						if (bMortarControls[activator] & bPressedForward) angs[1]+=45.0;
						else if (bMortarControls[activator] & bPressedBack) angs[1]-=45.0;
						if (!(bMortarControls[activator] & bPressedRight)) bMortarControls[activator] |= bPressedRight;
					}
					if (StrEqual(output,"PressedBack",false))
					{
						angs[1]-=180.0;
						if (bMortarControls[activator] & bPressedRight) angs[1]+=45.0;
						else if (bMortarControls[activator] & bPressedLeft) angs[1]-=45.0;
						if (!(bMortarControls[activator] & bPressedBack)) bMortarControls[activator] |= bPressedBack;
					}
					if (StrEqual(output,"PressedForward",false))
					{
						if (bMortarControls[activator] & bPressedRight) angs[1]-=45.0;
						else if (bMortarControls[activator] & bPressedLeft) angs[1]+=45.0;
						if (!(bMortarControls[activator] & bPressedForward)) bMortarControls[activator] |= bPressedForward;
					}
					loc[0] = (orgs[0] + (100.0 * Cosine(DegToRad(angs[1]))));
					loc[1] = (orgs[1] + (100.0 * Sine(DegToRad(angs[1]))));
					loc[2] = (orgs[2]);
					if (!TR_PointOutsideWorld(loc))
					{
						float shootvel[3];
						MakeVectorFromPoints(orgs,loc,shootvel);
						TeleportEntity(pv,NULL_VECTOR,NULL_VECTOR,shootvel);
					}
				}
				else if (StrContains(output,"Unpressed",false) != -1)
				{
					if (StrEqual(output,"UnpressedMoveLeft",false))
					{
						if (bMortarControls[activator] & bPressedLeft) bMortarControls[activator] -= bPressedLeft;
					}
					if (StrEqual(output,"UnpressedMoveRight",false))
					{
						if (bMortarControls[activator] & bPressedRight) bMortarControls[activator] -= bPressedRight;
					}
					if (StrEqual(output,"UnpressedBack",false))
					{
						if (bMortarControls[activator] & bPressedBack) bMortarControls[activator] -= bPressedBack;
					}
					if (StrEqual(output,"UnpressedForward",false))
					{
						if (bMortarControls[activator] & bPressedForward) bMortarControls[activator] -= bPressedForward;
					}
					if (bMortarControls[activator] & bPressedLeft)
					{
						angs[1]+=90.0;
						if (bMortarControls[activator] & bPressedForward) angs[1]-=45.0;
						else if (bMortarControls[activator] & bPressedBack) angs[1]+=45.0;
					}
					else if (bMortarControls[activator] & bPressedRight)
					{
						angs[1]-=90.0;
						if (bMortarControls[activator] & bPressedForward) angs[1]+=45.0;
						else if (bMortarControls[activator] & bPressedBack) angs[1]-=45.0;
					}
					else if (bMortarControls[activator] & bPressedBack)
					{
						angs[1]-=180.0;
						if (bMortarControls[activator] & bPressedRight) angs[1]+=45.0;
						else if (bMortarControls[activator] & bPressedLeft) angs[1]-=45.0;
					}
					else if (bMortarControls[activator] & bPressedForward)
					{
						if (bMortarControls[activator] & bPressedRight) angs[1]-=45.0;
						else if (bMortarControls[activator] & bPressedLeft) angs[1]+=45.0;
					}
					if (bMortarControls[activator] != 0)
					{
						float loc[3];
						loc[0] = (orgs[0] + (100.0 * Cosine(DegToRad(angs[1]))));
						loc[1] = (orgs[1] + (100.0 * Sine(DegToRad(angs[1]))));
						loc[2] = (orgs[2]);
						if (!TR_PointOutsideWorld(loc))
						{
							float shootvel[3];
							MakeVectorFromPoints(orgs,loc,shootvel);
							TeleportEntity(pv,NULL_VECTOR,NULL_VECTOR,shootvel);
						}
					}
				}
				if (bMortarControls[activator] == 0)
				{
					float stop[3];
					TeleportEntity(pv,NULL_VECTOR,NULL_VECTOR,stop);
				}
			}
		}
	}
}