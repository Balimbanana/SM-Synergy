void abramsthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_flPoseParameter"))
		{
			float Time = GetTickedTime();
			if (lastseen[entity] < Time)
			{
				isattacking[entity] = -1;
				lastseen[entity] = Time+5.0;
			}
			int targ = isattacking[entity];
			if ((IsValidEntity(targ)) && (targ != 0))
			{
				int boundbox = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
				float enorg[3];
				float orgs[3];
				float entangs[3];
				float angs[3];
				float gun1orgs[3];
				float gun2orgs[3];
				float gun1angs[3];
				float gun2angs[3];
				int withinradius = 0;
				float driverangs[3];
				int driver = GetEntPropEnt(entity,Prop_Data,"m_hParent");
				bool withinradius2 = false;
				bool withinradius3 = false;
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
				if ((driver != 0) && (IsValidEntity(driver)))
				{
					if (HasEntProp(driver,Prop_Data,"m_angAbsRotation")) GetEntPropVector(driver,Prop_Data,"m_angAbsRotation",entangs);
				}
				else if (HasEntProp(boundbox,Prop_Data,"m_angAbsRotation")) GetEntPropVector(boundbox,Prop_Data,"m_angAbsRotation",entangs);
				int attachfind = CreateEntityByName("prop_dynamic");
				if (attachfind != -1)
				{
					DispatchKeyValue(attachfind,"rendermode","10");
					DispatchKeyValue(attachfind,"solid","0");
					DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
					DispatchSpawn(attachfind);
					ActivateEntity(attachfind);
					SetVariantString("!activator");
					AcceptEntityInput(attachfind,"SetParent",entity);
					SetVariantString("gun");
					AcceptEntityInput(attachfind,"SetParentAttachment");
					if (HasEntProp(attachfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(attachfind,Prop_Data,"m_angAbsRotation",angs);
					AcceptEntityInput(attachfind,"kill");
				}
				attachfind = CreateEntityByName("prop_dynamic");
				if (attachfind != -1)
				{
					DispatchKeyValue(attachfind,"rendermode","10");
					DispatchKeyValue(attachfind,"solid","0");
					DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
					DispatchSpawn(attachfind);
					ActivateEntity(attachfind);
					SetVariantString("!activator");
					AcceptEntityInput(attachfind,"SetParent",boundbox);
					SetVariantString("minigun1_muzzle");
					AcceptEntityInput(attachfind,"SetParentAttachment");
					if (HasEntProp(attachfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(attachfind,Prop_Data,"m_angAbsRotation",gun1angs);
					SetVariantString("minigun1");
					AcceptEntityInput(attachfind,"SetParentAttachment");
					if (HasEntProp(attachfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(attachfind,Prop_Data,"m_vecAbsOrigin",gun1orgs);
					else if (HasEntProp(attachfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(attachfind,Prop_Send,"m_vecOrigin",gun1orgs);
					AcceptEntityInput(attachfind,"kill");
				}
				attachfind = CreateEntityByName("prop_dynamic");
				if (attachfind != -1)
				{
					DispatchKeyValue(attachfind,"rendermode","10");
					DispatchKeyValue(attachfind,"solid","0");
					DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
					DispatchSpawn(attachfind);
					ActivateEntity(attachfind);
					SetVariantString("!activator");
					AcceptEntityInput(attachfind,"SetParent",boundbox);
					SetVariantString("minigun2_muzzle");
					AcceptEntityInput(attachfind,"SetParentAttachment");
					if (HasEntProp(attachfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(attachfind,Prop_Data,"m_angAbsRotation",gun2angs);
					SetVariantString("minigun2");
					AcceptEntityInput(attachfind,"SetParentAttachment");
					if (HasEntProp(attachfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(attachfind,Prop_Data,"m_vecAbsOrigin",gun2orgs);
					else if (HasEntProp(attachfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(attachfind,Prop_Send,"m_vecOrigin",gun2orgs);
					AcceptEntityInput(attachfind,"kill");
				}
				float toang[3];
				float pose = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",0);
				float prevpose = pose;
				//angs[1] = angs[1]-(180.0*pose);
				//angs[1]+=180.0;
				angs[1]+=entangs[1];
				if (angs[1] < 0.0) angs[1]+=360.0;
				if (angs[1] > 360) angs[1]-=360.0;
				if (angs[1] > 360) angs[1]-=360.0;
				if (gun1angs[1] < 0.0) gun1angs[1]+=360.0;
				if (gun1angs[1] > 360) gun1angs[1]-=360.0;
				if (gun2angs[1] < 0.0) gun2angs[1]+=360.0;
				if (gun2angs[1] > 360) gun2angs[1]-=360.0;
				
				float loc[3];
				loc[0] = (orgs[0]);
				loc[1] = (orgs[1]);
				loc[2] = (orgs[2] + 60);
				float shootvel[3];
				enorg[2]+=10.0;
				if (HasEntProp(targ,Prop_Data,"m_bDucked"))
				{
					if (GetEntProp(targ,Prop_Data,"m_bDucked") > 0) enorg[2]-=10.0;
				}
				MakeVectorFromPoints(loc,enorg,shootvel);
				GetVectorAngles(shootvel,toang);
				if (angs[1] > toang[1])
				{
					if (angs[1]-toang[1] > 180) pose+=0.01;
					else if (toang[1]-angs[1] < -180) pose+=0.01;
					else pose-=0.01;
				}
				else if (toang[1] > angs[1])
				{
					if (toang[1]-angs[1] > 180) pose-=0.01;
					else if (angs[1]-toang[1] < -180) pose-=0.01;
					else pose+=0.01;
				}
				if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)))
				{
					if (pose < prevpose) pose+=0.005;
					else pose-=0.005;
				}
				else if ((toang[1]-angs[1] < 15.0) || (angs[1]-toang[1] < 15.0))
				{
					if (pose < prevpose) pose+=0.0025;
					else pose-=0.0025;
				}
				if ((toang[1]-angs[1] > 2.0) || (angs[1]-toang[1] > 2.0))
				{
					if (pose < 0.00)
					{
						pose = 0.0;
					}
					else if (pose > 1.00)
					{
						pose = 1.0;
					}
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",pose,0);
					/*
					float posetur2 = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",2);
					if (posetur2-0.01 < 0.00) posetur2 = 1.0;
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",posetur2-0.01,2);
					float posetur1 = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",3);
					if (posetur1-0.01 < 0.00) posetur1 = 1.0;
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",posetur1-0.01,3);
					float posetur1pitch = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",7);
					if (posetur1pitch-0.01 < 0.00) posetur1pitch = 1.0;
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",posetur1pitch-0.01,7);
					*/
				}
				else withinradius++;
				float posepitch = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",1);
				angs[0] = (180.0*posepitch)-110.0;
				if (toang[0] > 90.0) toang[0]-=360.0;
				toang[0]=toang[0]*5.0;
				if (angs[0] > toang[0])
				{
					posepitch-=0.02;
				}
				else posepitch+=0.02;
				if ((toang[0]-angs[0] > 3.0) || (angs[0]-toang[0] > 3.0))
				{
					if (posepitch < 0.00)
					{
						posepitch = 0.0;
					}
					else if (posepitch > 1.00)
					{
						posepitch = 1.0;
					}
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",posepitch,1);
				}
				else withinradius++;
				float shootvel2[3];
				MakeVectorFromPoints(gun1orgs,enorg,shootvel2);
				GetVectorAngles(shootvel2,toang);
				pose = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",2);
				prevpose = pose;
				gun1angs[1]+=angs[1];
				gun1angs[1]+=10.0;
				if (entangs[1] < 0.0) toang[1]+=angs[1];
				else toang[1]+=angs[1]+90.0; //entangs
				if (gun1angs[1] < 0.0) gun1angs[1]+=360.0;
				if (gun1angs[1] > 360) gun1angs[1]-=360.0;
				if (gun1angs[1] > 360) gun1angs[1]-=360.0;
				if (toang[1] < 0.0) toang[1]+=360.0;
				if (toang[1] > 360) toang[1]-=360.0;
				if (toang[1] > 360) toang[1]-=360.0;
				if (gun1angs[1] > toang[1])
				{
					if (gun1angs[1]-toang[1] > 180) pose+=0.02;
					else if (toang[1]-gun1angs[1] < -180) pose+=0.02;
					else pose-=0.02;
				}
				else if (toang[1] > gun1angs[1])
				{
					if (toang[1]-gun1angs[1] > 180) pose-=0.02;
					else if (gun1angs[1]-toang[1] < -180) pose-=0.02;
					else pose+=0.02;
				}
				if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)))
				{
					if (pose < prevpose) pose+=0.015;
					else pose-=0.015;
				}
				else if ((toang[1]-angs[1] < 20.0) || (angs[1]-toang[1] < 20.0))
				{
					if (pose < prevpose) pose+=0.01;
					else pose-=0.01;
				}
				if ((toang[1]-gun1angs[1] > 3.0) || (gun1angs[1]-toang[1] > 3.0))
				{
					if (pose < 0.00)
					{
						pose = 1.0;
					}
					else if (pose > 1.00)
					{
						pose = 0.0;
					}
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",pose,2);
				}
				else withinradius2 = true;
				float shootvel3[3];
				MakeVectorFromPoints(gun2orgs,enorg,shootvel3);
				GetVectorAngles(shootvel3,toang);
				pose = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",3);
				prevpose = pose;
				gun2angs[1]+=angs[1];
				gun2angs[1]+=10.0;
				if (entangs[1] < 0.0) toang[1]+=angs[1];
				else toang[1]+=angs[1]+90.0; //entangs
				if (gun2angs[1] < 0.0) gun2angs[1]+=360.0;
				if (gun2angs[1] > 360) gun2angs[1]-=360.0;
				if (gun2angs[1] > 360) gun2angs[1]-=360.0;
				if (toang[1] < 0.0) toang[1]+=360.0;
				if (toang[1] > 360) toang[1]-=360.0;
				if (toang[1] > 360) toang[1]-=360.0;
				//PrintToServer("Curang %1.f To %1.f Entang %1.f pose %f",gun2angs[1],toang[1],entangs[1],pose);
				if (gun2angs[1] > toang[1])
				{
					if (gun2angs[1]-toang[1] > 180) pose+=0.02;
					else if (toang[1]-gun2angs[1] < -180) pose+=0.02;
					else pose-=0.02;
				}
				else if (toang[1] > gun2angs[1])
				{
					if (toang[1]-gun2angs[1] > 180) pose-=0.02;
					else if (gun2angs[1]-toang[1] < -180) pose-=0.02;
					else pose+=0.02;
				}
				if ((toang[1]-gun2angs[1] > 2.0) || (gun2angs[1]-toang[1] > 2.0))
				{
					if (pose < 0.00)
					{
						pose = 0.0;
					}
					else if (pose > 1.00)
					{
						pose = 1.0;
					}
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",pose,3);
				}
				else withinradius3 = true;
				int animset = GetEntProp(entity,Prop_Data,"m_bClientSideAnimation");
				if (animset == 0) SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",0);
				else if (timesattacked[entity] > 1)
				{
					SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",1);
					timesattacked[entity] = 0;
				}
				timesattacked[entity]++;
				ChangeEdictState(entity);
				if (centnextatk[entity] < Time)
				{
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
					if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
					if ((driver != 0) && (IsValidEntity(driver)))
					{
						if (HasEntProp(driver,Prop_Data,"m_angAbsRotation"))
						{
							GetEntPropVector(driver,Prop_Data,"m_angAbsRotation",driverangs);
							driverangs[1]+=45.0;
							if (driverangs[1] > 360.0) driverangs[1]-=360.0;
							if ((angs[0] != driverangs[0]) || (angs[1] != driverangs[1]) || (angs[2] != driverangs[2]))
							{
								//TeleportEntity(entity,NULL_VECTOR,driverangs,NULL_VECTOR);
								if ((boundbox != 0) && (IsValidEntity(boundbox))) TeleportEntity(boundbox,orgs,driverangs,NULL_VECTOR);
							}
						}
					}
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
					else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
					float chkdist = GetVectorDistance(orgs,enorg,false);
					if ((chkdist < 1000.0) && (withinradius == 2))
					{
						//m_hCrashPoint crash point ent m_bInvulnerable m_vecDesiredPosition
						float lorg[3];
						int cannonfind = CreateEntityByName("prop_dynamic");
						if (cannonfind != -1)
						{
							DispatchKeyValue(cannonfind,"rendermode","10");
							DispatchKeyValue(cannonfind,"solid","0");
							DispatchKeyValue(cannonfind,"model","models/props_junk/popcan01a.mdl");
							DispatchSpawn(cannonfind);
							ActivateEntity(cannonfind);
							TeleportEntity(cannonfind,orgs,NULL_VECTOR,NULL_VECTOR);
							SetVariantString("!activator");
							AcceptEntityInput(cannonfind,"SetParent",entity);
							SetVariantString("muzzle");
							AcceptEntityInput(cannonfind,"SetParentAttachment");
							if (HasEntProp(cannonfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(cannonfind,Prop_Data,"m_vecAbsOrigin",lorg);
							else if (HasEntProp(cannonfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(cannonfind,Prop_Send,"m_vecOrigin",lorg);
							if (HasEntProp(cannonfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(cannonfind,Prop_Data,"m_angAbsRotation",angs);
							AcceptEntityInput(cannonfind,"kill");
						}
						lorg[2]+=5.0;
						MakeVectorFromPoints(lorg,enorg,shootvel);
						char snd[128];
						int randsnd = GetRandomInt(3,5);
						Format(snd,sizeof(snd),"weapons/weap_explode/explode%i.wav",randsnd);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
						float fhitpos[3];
						GetVectorAngles(shootvel,toang);
						Handle hhitpos = INVALID_HANDLE;
						TR_TraceRay(lorg,toang,MASK_SHOT,RayType_Infinite);
						TR_GetEndPosition(fhitpos,hhitpos);
						CloseHandle(hhitpos);
						int endpoint = CreateEntityByName("env_explosion");
						TeleportEntity(endpoint,fhitpos,NULL_VECTOR,NULL_VECTOR);
						DispatchKeyValue(endpoint,"imagnitude","300");
						DispatchKeyValue(endpoint,"targetname","syn_abramsblast");
						DispatchKeyValue(endpoint,"iradiusoverride","150");
						DispatchKeyValue(endpoint,"rendermode","0");
						DispatchSpawn(endpoint);
						ActivateEntity(endpoint);
						SetEntPropEnt(endpoint,Prop_Data,"m_hEffectEntity",entity);
						AcceptEntityInput(endpoint,"Explode");
						if (HasEntProp(entity,Prop_Data,"m_hEffectEntity"))
						{
							int turretflash = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
							if (turretflash != -1) AcceptEntityInput(turretflash,"Fire");
						}
						centnextatk[entity] = Time+7.0;
					}
				}
				int addtarg = -1;
				if ((centlastposchk[entity] < Time) && (withinradius2))
				{
					if (GetArraySize(entlist) > 0)
					{
						for (int j = 0;j<GetArraySize(entlist);j++)
						{
							int i = GetArrayCell(entlist,j);
							if (IsValidEntity(i))
							{
								char cls[64];
								GetEntityClassname(i,cls,sizeof(cls));
								if ((!StrEqual(cls,"npc_human_grunt",false)) && (!StrEqual(cls,"npc_human_medic",false)) && (!StrEqual(cls,"npc_human_grenadier",false)) && (!StrEqual(cls,"npc_human_commander",false)) && (!StrEqual(cls,"npc_sentry_ground",false)) && (!StrEqual(cls,"npc_abrams",false)))
								{
									float enorgtmp[3];
									if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",enorgtmp);
									else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",enorgtmp);
									float chkdist = GetVectorDistance(gun1orgs,enorgtmp,false);
									if ((chkdist < 800) && (i != targ))
									{
										addtarg = i;
										break;
									}
								}
							}
						}
					}
					if ((addtarg == -1) && (targ != -1)) addtarg = targ;
					else
					{
						if (HasEntProp(addtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(addtarg,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(addtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(addtarg,Prop_Send,"m_vecOrigin",enorg);
					}
					centlastposchk[entity] = Time+0.2;
					MakeVectorFromPoints(gun1orgs,enorg,shootvel2);
					GetVectorAngles(shootvel2,toang);
					loc[0] = (gun1orgs[0] + (120 * Cosine(DegToRad(gun1angs[1]))));
					loc[1] = (gun1orgs[1] + (120 * Sine(DegToRad(gun1angs[1]))));
					loc[2] = (gun1orgs[2] + 15);
					Handle hhitpos = INVALID_HANDLE;
					TR_TraceRayFilter(loc,toang,MASK_SOLID,RayType_Infinite,TraceEntityFilter,entity);
					addtarg = TR_GetEntityIndex(hhitpos);
					CloseHandle(hhitpos);
					if ((addtarg != -1) && (addtarg != 0))
					{
						int bulletmuzzle = CreateEntityByName("env_muzzleflash");
						if (bulletmuzzle != -1)
						{
							DispatchKeyValue(bulletmuzzle,"scale","0.8");
							DispatchSpawn(bulletmuzzle);
							ActivateEntity(bulletmuzzle);
							SetVariantString("!activator");
							AcceptEntityInput(bulletmuzzle,"SetParent",entity);
							SetVariantString("minigun1_muzzle");
							AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
							AcceptEntityInput(bulletmuzzle,"Fire");
							Handle dp2 = CreateDataPack();
							WritePackCell(dp2,bulletmuzzle);
							WritePackString(dp2,"env_muzzleflash");
							CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
						}
						float damageForce[3];
						float dmgset = 5.0;
						float dmgforce = 5.0;
						damageForce[0] = dmgforce;
						damageForce[1] = dmgforce;
						damageForce[2] = dmgforce;
						SDKHooks_TakeDamage(addtarg,entity,entity,dmgset,DMG_BULLET,-1,damageForce);
						char snd[64];
						Format(snd,sizeof(snd),"weapons\\50cal\\single%i.wav",GetRandomInt(1,3));
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
					}
				}
				if ((centlastang[entity] < Time) && (withinradius3))
				{
					if (GetArraySize(entlist) > 0)
					{
						for (int j = 0;j<GetArraySize(entlist);j++)
						{
							int i = GetArrayCell(entlist,j);
							if (IsValidEntity(i))
							{
								char cls[64];
								GetEntityClassname(i,cls,sizeof(cls));
								if ((!StrEqual(cls,"npc_human_grunt",false)) && (!StrEqual(cls,"npc_human_medic",false)) && (!StrEqual(cls,"npc_human_grenadier",false)) && (!StrEqual(cls,"npc_human_commander",false)) && (!StrEqual(cls,"npc_sentry_ground",false)) && (!StrEqual(cls,"npc_abrams",false)))
								{
									float enorgtmp[3];
									if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",enorgtmp);
									else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",enorgtmp);
									float chkdist = GetVectorDistance(gun2orgs,enorgtmp,false);
									if ((chkdist < 800) && (i != targ) && (addtarg != targ))
									{
										addtarg = i;
										break;
									}
								}
							}
						}
					}
					if ((addtarg == -1) && (targ != -1)) addtarg = targ;
					else
					{
						if (HasEntProp(addtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(addtarg,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(addtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(addtarg,Prop_Send,"m_vecOrigin",enorg);
					}
					centlastang[entity] = Time+0.1;
					GetVectorAngles(shootvel3,toang);
					loc[0] = (gun2orgs[0] + (120 * Cosine(DegToRad(gun2angs[1]))));
					loc[1] = (gun2orgs[1] + (120 * Sine(DegToRad(gun2angs[1]))));
					loc[2] = (gun2orgs[2] + 15);
					Handle hhitpos = INVALID_HANDLE;
					TR_TraceRayFilter(loc,toang,MASK_SOLID,RayType_Infinite,TraceEntityFilter,entity);
					targ = TR_GetEntityIndex(hhitpos);
					CloseHandle(hhitpos);
					if ((targ != -1) && (targ != 0))
					{
						int bulletmuzzle = CreateEntityByName("env_muzzleflash");
						if (bulletmuzzle != -1)
						{
							DispatchKeyValue(bulletmuzzle,"scale","0.5");
							DispatchSpawn(bulletmuzzle);
							ActivateEntity(bulletmuzzle);
							SetVariantString("!activator");
							AcceptEntityInput(bulletmuzzle,"SetParent",entity);
							SetVariantString("minigun2_muzzle");
							AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
							AcceptEntityInput(bulletmuzzle,"Fire");
							Handle dp2 = CreateDataPack();
							WritePackCell(dp2,bulletmuzzle);
							WritePackString(dp2,"env_muzzleflash");
							CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
						}
						float damageForce[3];
						float dmgset = 2.0;
						float dmgforce = 5.0;
						damageForce[0] = dmgforce;
						damageForce[1] = dmgforce;
						damageForce[2] = dmgforce;
						SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_BULLET,-1,damageForce);
						char snd[64];
						Format(snd,sizeof(snd),"weapons\\m4\\single%i.wav",GetRandomInt(1,2));
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
					}
				}
			}
			else
			{
				if (GetArraySize(entlist) > 0)
				{
					float curorg[3];
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
					curorg[2]+=250.0;
					for (int j = 0;j<GetArraySize(entlist);j++)
					{
						int i = GetArrayCell(entlist,j);
						if (IsValidEntity(i))
						{
							char cls[64];
							GetEntityClassname(i,cls,sizeof(cls));
							if ((!StrEqual(cls,"npc_human_grunt",false)) && (!StrEqual(cls,"npc_human_medic",false)) && (!StrEqual(cls,"npc_human_grenadier",false)) && (!StrEqual(cls,"npc_human_commander",false)) && (!StrEqual(cls,"npc_sentry_ground",false)) && (!StrEqual(cls,"npc_abrams",false)) && (!StrEqual(cls,"npc_bullseye",false)) && (!StrEqual(cls,"npc_maker",false)) && (!StrEqual(cls,"npc_template_maker",false)) && (!StrEqual(cls,"env_xen_portal",false)) && (!StrEqual(cls,"env_xen_portal_template",false)))
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
									//PrintToServer("Targeting %i %s",i,cls);
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

public Action abramstkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((IsValidEntity(victim)) && (damagetype == 64))
	{
		char clschk[24];
		GetEntityClassname(victim,clschk,sizeof(clschk));
		if (StrEqual(clschk,"npc_abrams",false))
		{
			float damageForce[3];
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			SDKHooks_TakeDamage(victim,attacker,inflictor,damage,damagetype,-1,damageForce);
			damage = 0.0;
			return Plugin_Changed;
		}
		int parentchk = GetEntPropEnt(victim,Prop_Data,"m_hParent");
		if (parentchk != -1)
		{
			if (HasEntProp(parentchk,Prop_Data,"m_iHealth"))
			{
				float damageForce[3];
				float dmgforce = 5.0;
				damageForce[0] = dmgforce;
				damageForce[1] = dmgforce;
				damageForce[2] = dmgforce;
				SDKHooks_TakeDamage(parentchk,attacker,inflictor,damage,damagetype,-1,damageForce);
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	damage = 0.0;
	return Plugin_Changed;
}