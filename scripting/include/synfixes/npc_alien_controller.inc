void controllerthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_flPoseParameter"))
		{
			float orgs[3];
			float angs[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
			if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
			if (HasEntProp(entity,Prop_Data,"m_MoveType"))
			{
				int mvtype = GetEntProp(entity,Prop_Data,"m_MoveType");
				if (mvtype != 4)
				{
					SetEntProp(entity,Prop_Data,"m_MoveType",4);
					if (HasEntProp(entity, Prop_Data, "m_ModelName"))
					{
						char mdlchk[64];
						GetEntPropString(entity, Prop_Data, "m_ModelName", mdlchk, sizeof(mdlchk));
						if (!StrEqual(mdlchk, "models/xenians/controller.mdl", false))
						{
							if (!IsModelPrecached("models/xenians/controller.mdl")) PrecacheModel("models/xenians/controller.mdl",true);
							SetEntityModel(entity, "models/xenians/controller.mdl");
						}
					}
				}
			}
			int targ = isattacking[entity];
			if ((targ != 0) && (IsValidEntity(targ)))
			{
				float enorg[3];
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float toang[3];
				float shootvel[3];
				float loc[3];
				enorg[2]+=30.0;
				MakeVectorFromPoints(orgs,enorg,shootvel);
				GetVectorAngles(shootvel,toang);
				if (angs[1] > toang[1])
				{
					if (angs[1]-toang[1] > 180) angs[1]+=5.0;
					else if (toang[1]-angs[1] < -180) angs[1]+=5.0;
					else angs[1]-=5.0;
				}
				else if (toang[1] > angs[1])
				{
					if (toang[1]-angs[1] > 180) angs[1]-=5.0;
					else if (angs[1]-toang[1] < -180) angs[1]-=5.0;
					else angs[1]+=5.0;
				}
				if (angs[1] < 0.0) angs[1]+=360.0;
				if (angs[1] > 360) angs[1]-=360.0;
				if ((toang[1]-angs[1] > 6.0) || (angs[1]-toang[1] > 6.0))
				{
					TeleportEntity(entity,NULL_VECTOR,angs,NULL_VECTOR);
				}
				if (GetArraySize(controllers) > 0)
				{
					int rand = GetRandomInt(1,2);
					if (rand == 1) angs[1]+=90.0;
					else angs[1]-=90.0;
					for (int i = 0;i<GetArraySize(controllers);i++)
					{
						int j = GetArrayCell(controllers,i);
						if ((IsValidEntity(j)) && (j != entity))
						{
							float otherorg[3];
							if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",otherorg);
							else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",otherorg);
							float chkdist = GetVectorDistance(orgs,otherorg,false);
							if (chkdist < 50.0)
							{
								float randfl = GetRandomFloat(-90.0,90.0);
								angs[1]+=randfl;
								loc[0] = (orgs[0] + (50 * Cosine(DegToRad(angs[1]))));
								loc[1] = (orgs[1] + (50 * Sine(DegToRad(angs[1]))));
								loc[2] = orgs[2];
								angs[1]-=randfl;
								MakeVectorFromPoints(loc,otherorg,shootvel);
								ScaleVector(shootvel,3.0);
								TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
							}
						}
					}
					if (rand == 1) angs[1]-=90.0;
					else angs[1]+=90.0;
				}
				float Time = GetTickedTime();
				float chkdist = GetVectorDistance(orgs,enorg,false);
				if (chkdist < 80.0)
				{
					if (centlastposchk[entity] < Time)
					{
						enorg[2]-=90.0;
						if (GetRandomInt(1,2) == 1) angs[1]+=90.0;
						else angs[1]-=90.0;
						loc[0] = (orgs[0] + (50 * Cosine(DegToRad(angs[1]))));
						loc[1] = (orgs[1] + (50 * Sine(DegToRad(angs[1]))));
						loc[2] = orgs[2];
						MakeVectorFromPoints(enorg,loc,shootvel);
						ScaleVector(shootvel,2.0);
						TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
						centlastposchk[entity] = Time+1.0;
					}
				}
				else if (chkdist < 100.0)
				{
					enorg[2]+=30.0;
					MakeVectorFromPoints(enorg,orgs,shootvel);
					TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
				}
				else if (chkdist > 350.0)
				{
					//movetowards
					enorg[2]+=30.0;
					MakeVectorFromPoints(orgs,enorg,shootvel);
					ScaleVector(shootvel,0.5);
					TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
				}
				else if ((chkdist > 150.0) && (centlastposchk[entity] < Time))
				{
					float randheight = GetRandomFloat(30.0,70.0);
					enorg[2]+=randheight;
					float angadj = angs[1];
					if (GetRandomInt(1,2) == 1) angadj+=90.0;
					else angadj-=90.0;
					loc[0] = (orgs[0] + (50 * Cosine(DegToRad(angadj))));
					loc[1] = (orgs[1] + (50 * Sine(DegToRad(angadj))));
					loc[2] = orgs[2];
					MakeVectorFromPoints(enorg,loc,shootvel);
					TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
					centlastposchk[entity] = Time+1.0;
				}
				else if ((chkdist > 100.0) && (centlastposchk[entity] < Time))
				{
					float randheight = GetRandomFloat(30.0,70.0);
					enorg[2]+=randheight;
					float angadj = angs[1];
					if (GetRandomInt(1,2) == 1) angadj+=45.0;
					else angadj-=45.0;
					loc[0] = (orgs[0] + (50 * Cosine(DegToRad(angadj))));
					loc[1] = (orgs[1] + (50 * Sine(DegToRad(angadj))));
					loc[2] = orgs[2];
					MakeVectorFromPoints(enorg,loc,shootvel);
					TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
					centlastposchk[entity] = Time+1.0;
				}
				if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
				{
					loc[0] = (orgs[0] + (100 * Cosine(DegToRad(angs[1]))));
					loc[1] = (orgs[1] + (100 * Sine(DegToRad(angs[1]))));
				}
				else
				{
					loc[0] = (orgs[0] + (80 * Cosine(DegToRad(angs[1]))));
					loc[1] = (orgs[1] + (80 * Sine(DegToRad(angs[1]))));
				}
				loc[2] = (orgs[2] + 15);
				Handle hhitpos = INVALID_HANDLE;
				TR_TraceRayFilter(loc,toang,MASK_SOLID,RayType_Infinite,TraceEntityFilter,entity);
				targ = TR_GetEntityIndex(hhitpos);
				CloseHandle(hhitpos);
				if ((targ != -1) && (targ != 0))
				{
					if (centnextatk[entity] < Time)
					{
						int mdl = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
						if (centlastang[entity] < Time)
						{
							if ((mdl != 0) && (IsValidEntity(mdl)))
							{
								AcceptEntityInput(mdl,"kill");
								SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
							}
							else
							{
								mdl = CreateEntityByName("prop_dynamic");
								if (mdl != -1)
								{
									DispatchKeyValue(mdl,"solid","0");
									DispatchKeyValue(mdl,"model","models/xenians/controller.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","attack1");
									TeleportEntity(mdl,orgs,angs,NULL_VECTOR);
									DispatchSpawn(mdl);
									ActivateEntity(mdl);
									SetVariantString("!activator");
									AcceptEntityInput(mdl,"SetParent",entity);
									SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",mdl);
									SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
								}
							}
							centlastang[entity] = Time + 3.0;
						}
						else if ((mdl != 0) && (IsValidEntity(mdl))) SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
						timesattacked[entity]++;
						if (timesattacked[entity] > 2)
						{
							centnextatk[entity] = Time + 5.0;
							timesattacked[entity] = 0;
						}
						else centnextatk[entity] = Time + 0.3;
						CreateTimer(1.0,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
						int orb = CreateEntityByName("generic_actor");
						if (orb != -1)
						{
							DispatchKeyValue(orb,"rendermode","10");
							DispatchKeyValue(orb,"renderfx","5");
							DispatchKeyValue(orb,"rendercolor","0 0 0");
							DispatchKeyValue(orb,"renderamt","0");
							DispatchKeyValue(orb,"solid","6");
							DispatchKeyValue(orb,"modelscale","1.0");
							DispatchKeyValue(orb,"model","models/roller.mdl");
							loc[2]+=20.0;
							enorg[2]-=20.0;
							MakeVectorFromPoints(loc,enorg,shootvel);
							TeleportEntity(orb,loc,toang,NULL_VECTOR);
							DispatchSpawn(orb);
							ActivateEntity(orb);
							SetEntProp(orb,Prop_Data,"m_MoveType",4);
							SetEntProp(orb,Prop_Data,"m_nRenderMode",10);
							SetEntProp(orb,Prop_Data,"m_nRenderFX",6);
							if (HasEntProp(orb,Prop_Data,"m_bloodColor")) SetEntProp(orb,Prop_Data,"m_bloodColor",4);
							SDKHook(orb, SDKHook_StartTouch, StartTouchOrb);
							SDKHook(orb, SDKHook_OnTakeDamage, orbtkdmg);
							isattacking[orb] = entity;
							SetEntProp(orb,Prop_Data,"m_iHealth",300);
							int orbball = CreateEntityByName("env_sprite");
							if (orbball != -1)
							{
								if (!IsModelPrecached("materials/sprites/animglow01.vmt")) PrecacheModel("materials/sprites/animglow01.vmt",true);
								DispatchKeyValue(orbball,"model","sprites/animglow01.vmt");
								DispatchKeyValue(orbball,"scale","0.6");
								DispatchKeyValue(orbball,"rendermode","9");
								DispatchKeyValue(orbball,"rendercolor","0 255 0");
								DispatchKeyValue(orbball,"spawnflags","1");
								DispatchKeyValue(orbball,"GlowProxySize","5.0");
								DispatchKeyValue(orbball,"HDRColorScale","1.0");
								DispatchKeyValue(orbball,"framerate","10");
								TeleportEntity(orbball,loc,toang,NULL_VECTOR);
								DispatchSpawn(orbball);
								ActivateEntity(orbball);
								SetVariantString("!activator");
								AcceptEntityInput(orbball,"SetParent",orb);
							}
							TeleportEntity(orb,NULL_VECTOR,NULL_VECTOR,shootvel);
							Handle dp = CreateDataPack();
							WritePackCell(dp,orb);
							WritePackString(dp,"generic_actor");
							CreateTimer(10.0,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
						}
						EmitSoundToAll("npc\\alien_controller\\con_throw1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
					}
				}
				else if (lastseen[entity] < Time) isattacking[entity] = -1;
				if ((centnextatk[entity] < Time) && ((targ == -1) || (targ == 0)))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					int mdl = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
					if ((mdl != 0) && (IsValidEntity(mdl)))
					{
						SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",-1);
						AcceptEntityInput(mdl,"Kill");
					}
				}
			}
			else
			{
				float Time = GetTickedTime();
				if (GetArraySize(entlist) > 0)
				{
					float curorg[3];
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
					for (int j = 0;j<GetArraySize(entlist);j++)
					{
						int i = GetArrayCell(entlist,j);
						if (IsValidEntity(i))
						{
							char cls[64];
							GetEntityClassname(i,cls,sizeof(cls));
							if ((!StrEqual(cls,"npc_alien_controller",false)) && (!StrEqual(cls,"npc_alien_grunt",false)) && (!StrEqual(cls,"npc_alien_slave",false)) && (!StrEqual(cls,"npc_bullseye",false)) && (!StrEqual(cls,"npc_maker",false)) && (!StrEqual(cls,"npc_template_maker",false)) && (!StrEqual(cls,"env_xen_portal",false)) && (!StrEqual(cls,"env_xen_portal_template",false)))
							{
								float enorg[3];
								if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",enorg);
								else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",enorg);
								float fhitpos[3];
								float toang[3];
								float shootvel[3];
								MakeVectorFromPoints(curorg,enorg,shootvel);
								GetVectorAngles(shootvel,toang);
								Handle hhitpos = INVALID_HANDLE;
								TR_TraceRay(curorg,toang,MASK_SHOT,RayType_Infinite);
								TR_GetEndPosition(fhitpos,hhitpos);
								CloseHandle(hhitpos);
								float chkdist = GetVectorDistance(fhitpos,enorg,false);
								if (chkdist < 200)
								{
									isattacking[entity] = i;
									lastseen[entity] = Time + 3.0;
									//PrintToServer("Targeting %i %s",i,cls);
									char snd[64];
									Format(snd,sizeof(snd),"npc\\alien_controller\\con_alert%i.wav",GetRandomInt(1,2));
									EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									break;
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action controllertkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			if (damage > 200) damage = 5.0;
			int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
			float Time = GetTickedTime();
			if (damage > curh)
			{
				char snd[64];
				Format(snd,sizeof(snd),"npc\\alien_controller\\con_die1.wav");
				EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
			else if ((damage > 1) && (centnextsndtime[victim] < Time))
			{
				char snd[64];
				int rand = GetRandomInt(1,3);
				Format(snd,sizeof(snd),"npc\\alien_controller\\con_pain%i.wav",rand);
				centnextsndtime[victim] = Time+1.0;
				int mdl = GetEntPropEnt(victim,Prop_Data,"m_hEffectEntity");
				if ((mdl != 0) && (IsValidEntity(mdl)))
				{
					char randatk[32];
					Format(randatk,sizeof(randatk),"flinch%i",GetRandomInt(1,2));
					SetVariantString(randatk);
					AcceptEntityInput(mdl,"SetAnimation");
					SetVariantString("OnUser4 !self:SetAnimation:attack2:1:1,0,-1");
					AcceptEntityInput(mdl,"AddOutput");
					AcceptEntityInput(mdl,"FireUser4");
					SetEntProp(victim,Prop_Data,"m_nRenderFX",6);
				}
				else
				{
					mdl = CreateEntityByName("prop_dynamic");
					if (mdl != -1)
					{
						float orgs[3];
						float angs[3];
						if (HasEntProp(victim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecAbsOrigin",orgs);
						else if (HasEntProp(victim,Prop_Send,"m_vecOrigin")) GetEntPropVector(victim,Prop_Send,"m_vecOrigin",orgs);
						if (HasEntProp(victim,Prop_Data,"m_angRotation")) GetEntPropVector(victim,Prop_Data,"m_angRotation",angs);
						DispatchKeyValue(mdl,"solid","0");
						DispatchKeyValue(mdl,"model","models/xenians/controller.mdl");
						DispatchKeyValue(mdl,"DefaultAnim","flinch1");
						TeleportEntity(mdl,orgs,angs,NULL_VECTOR);
						DispatchSpawn(mdl);
						ActivateEntity(mdl);
						SetVariantString("!activator");
						AcceptEntityInput(mdl,"SetParent",victim);
						SetEntPropEnt(victim,Prop_Data,"m_hEffectEntity",mdl);
						SetVariantString("OnUser4 !self:SetAnimation:attack2:1:1,0,-1");
						AcceptEntityInput(mdl,"AddOutput");
						AcceptEntityInput(mdl,"FireUser4");
						SetEntProp(victim,Prop_Data,"m_nRenderFX",6);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action StartTouchOrb(int entity, int other)
{
	if (IsValidEntity(other))
	{
		char clschk[24];
		GetEntityClassname(other,clschk,sizeof(clschk));
		int attacker = isattacking[entity];
		if ((!StrEqual(clschk,"npc_alien_slave",false)) && (!StrEqual(clschk,"npc_alien_grunt",false)) && (!StrEqual(clschk,"npc_alien_controller",false)))
		{
			float damageForce[3];
			float dmgset = 5.0;
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			if ((attacker != 0) && (IsValidEntity(attacker))) SDKHooks_TakeDamage(other,attacker,attacker,dmgset,DMG_BULLET,-1,damageForce);
			else SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_BULLET,-1,damageForce);
		}
		AcceptEntityInput(entity,"kill");
		isattacking[entity] = 0;
	}
}

public Action orbtkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iMaxHealth"))
		{
			int curh = GetEntProp(victim,Prop_Data,"m_iMaxHealth");
			if (damage > curh)
			{
				AcceptEntityInput(victim,"kill");
			}
		}
	}
}