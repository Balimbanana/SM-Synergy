float flSentryFireRate = 0.2;

void sentriesthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_flPoseParameter"))
		{
			int disabled = 0;
			if (HasEntProp(entity,Prop_Data,"m_iHealth"))
			{
				if (GetEntProp(entity,Prop_Data,"m_iHealth") < 1)
				{
					SDKUnhook(entity,SDKHook_Think,sentriesthink);
				}
			}
			if (HasEntProp(entity,Prop_Data,"m_bDisabled")) disabled = GetEntProp(entity,Prop_Data,"m_bDisabled");
			int targ = isattacking[entity];
			if ((IsValidEntity(targ)) && (targ != 0) && (!disabled))
			{
				char cls[32];
				GetEntityClassname(entity,cls,sizeof(cls));
				int prop = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
				int animprop = GetEntPropEnt(entity,Prop_Data,"m_hParent");
				if ((IsValidEntity(prop)) && (prop != 0))
				{
					int seq = GetEntProp(prop,Prop_Data,"m_nSequence");
					if (seq != 2)
					{
						SetVariantString("deploy");
						AcceptEntityInput(prop,"SetAnimation");
						char snd[64];
						if (StrEqual(cls,"npc_sentry_ceiling",false)) Format(snd,sizeof(snd),"npc\\sentry_ceiling\\deploy.wav");
						else Format(snd,sizeof(snd),"npc\\sentry_ground\\deploy.wav");
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
					}
				}
				float Time = GetTickedTime();
				if (centlastposchk[entity] < Time)
				{
					if ((IsValidEntity(prop)) && (prop != 0)) SetEntProp(prop,Prop_Data,"m_nRenderFX",6);
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					SetEntProp(entity,Prop_Data,"m_nRenderMode",0);
				}
				int withinradius = 0;
				float enorg[3];
				float orgs[3];
				float angs[3];
				float sentryang[3];
				if ((IsValidEntity(animprop)) && (animprop != 0))
				{
					if (HasEntProp(animprop,Prop_Data,"m_angAbsRotation")) GetEntPropVector(animprop,Prop_Data,"m_angAbsRotation",sentryang);
					if (HasEntProp(animprop,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(animprop,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(animprop,Prop_Send,"m_vecOrigin")) GetEntPropVector(animprop,Prop_Send,"m_vecOrigin",orgs);
				}
				else
				{
					if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",sentryang);
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
					orgs[2]-=10.0;
				}
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
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
					SetVariantString("muzzle");
					AcceptEntityInput(attachfind,"SetParentAttachment");
					if (HasEntProp(attachfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(attachfind,Prop_Data,"m_angAbsRotation",angs);
					if (StrEqual(cls,"npc_sentry_ground",false))
						angs[2]+=90.0;
					AcceptEntityInput(attachfind,"kill");
				}
				float toang[3];
				angs[1]+=sentryang[1];
				if (angs[1] < 0.0) angs[1]+=360.0;
				if (angs[1] < 0.0) angs[1]+=360.0;
				if (angs[1] > 360) angs[1]-=360.0;
				if (angs[1] > 360) angs[1]-=360.0;
				float shootvel[3];
				if (StrEqual(cls,"npc_sentry_ceiling",false))
				{
					//enorg[2]+=300.0;
					if (HasEntProp(targ,Prop_Data,"m_bDucked"))
					{
						if (GetEntProp(targ,Prop_Data,"m_bDucked") > 0) enorg[2]-=50.0;
					}
				}
				MakeVectorFromPoints(orgs,enorg,shootvel);
				GetVectorAngles(shootvel,toang);
				if (StrEqual(cls,"npc_sentry_ground",false))
				{
					if ((sentryang[2] > 60.0) || (sentryang[2] < -60.0))
					{
						if (HasEntProp(entity,Prop_Data,"m_bDisabled")) SetEntProp(entity,Prop_Data,"m_bDisabled",1);
					}
					if (HasEntProp(targ,Prop_Data,"m_bDucked"))
					{
						if (GetEntProp(targ,Prop_Data,"m_bDucked") > 0) toang[0]+=10.0;
					}
					/*
					char lasereye[64];
					Format(lasereye,sizeof(lasereye),"syn_lasereye%i",entity);
					char laserend[64];
					Format(laserend,sizeof(laserend),"syn_laserend%i",entity);
					int eyeattach = CreateEntityByName("info_target");
					if (eyeattach != -1)
					{
						DispatchKeyValue(eyeattach,"targetname",lasereye);
						DispatchSpawn(eyeattach);
						ActivateEntity(eyeattach);
						SetVariantString("!activator");
						if ((IsValidEntity(animprop)) && (animprop != 0)) AcceptEntityInput(eyeattach,"SetParent",animprop);
						else AcceptEntityInput(eyeattach,"SetParent",entity);
						SetVariantString("laser");
						AcceptEntityInput(eyeattach,"SetParentAttachment");
					}
					int laser = CreateEntityByName("env_beam");
					if (laser != -1)
					{
						DispatchKeyValue(laser,"TextureScroll","0");
						DispatchKeyValue(laser,"texture","sprites/turret_laserbeam.vmt");
						DispatchKeyValue(laser,"StrikeTime","1");
						DispatchKeyValue(laser,"spawnflags","1");
						DispatchKeyValue(laser,"rendercolor","255 255 255");
						DispatchKeyValue(laser,"renderamt","255");
						DispatchKeyValue(laser,"Radius","256");
						DispatchKeyValue(laser,"LightningStart",lasereye);
						DispatchKeyValue(laser,"LightningEnd",laserend);
						DispatchKeyValue(laser,"BoltWidth","4");
						DispatchKeyValue(laser,"framerate","10");
						DispatchKeyValue(laser,"TouchType","0");
					}
					*/
				}
				float pose = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",0);
				float prevpose = pose;
				float posepitch = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",1);
				/*
				if (StrEqual(cls,"npc_sentry_ceiling",false))
				{
					angs[1]+=sentryang[1];
					angs[0] = (180.0*posepitch)-100.0;
					angs[0]+=10.0;
					if (toang[0] > 90.0) toang[0]-=360.0;
					if (angs[0] < 0.0) angs[0]+=95.0;
					if (angs[1] < 0.0) angs[1]+=360.0;
					if (angs[1] < 0.0) angs[1]+=360.0;
					if (angs[1] > 360) angs[1]-=360.0;
					if (angs[1] > 360) angs[1]-=360.0;
					if (angs[1] > toang[1])
					{
						if (angs[1]-toang[1] > 180) pose+=0.06;
						else if (toang[1]-angs[1] < -180) pose+=0.06;
						else pose-=0.06;
					}
					else if (toang[1] > angs[1])
					{
						if (toang[1]-angs[1] > 180) pose-=0.06;
						else if (angs[1]-toang[1] < -180) pose-=0.06;
						else pose+=0.06;
					}
					if (angs[0] > toang[0]) posepitch-=0.03;
					else posepitch+=0.03;
					if (posepitch < 0.2) posepitch = 0.2;
					if (posepitch > 0.8) posepitch = 0.8;
					if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)))
					{
						if (pose < prevpose) pose+=0.04;
						else pose-=0.04;
					}
					else if ((toang[1]-angs[1] < 15.0) || (angs[1]-toang[1] < 15.0))
					{
						if (pose < prevpose) pose+=0.01;
						else pose-=0.01;
					}
				}
				else
				{
				*/
				if (sentryang[1] < 0.0) sentryang[1]+=360.0;
				if (angs[0] < 0.0) angs[0] = angs[0]-angs[0]+angs[0];
				if (toang[0] > 90.0) toang[0]-=360.0;
				if (angs[0] > 90.0) angs[0]-=360.0;
				angs[0] = (180.0*posepitch)-70.0;
				float chkdist = GetVectorDistance(orgs,enorg,false);
				if (chkdist > 200.0)
				{
					toang[0]+=toang[0]/10;
				}
				if (angs[0] > toang[0]) posepitch-=0.03;
				else posepitch+=0.03;
				if (StrEqual(cls,"npc_sentry_ceiling",false))
				{
					if (sentryang[1] < 180.0) angs[1] -= sentryang[1];
					else angs[1] += sentryang[1];
				}
				else angs[1] = -90.0+sentryang[1]+(180.0*pose);
				if (angs[1] > 360.0) angs[1]-=360.0;
				if (angs[1] > 360.0) angs[1]-=360.0;
				if (angs[1] < 0.0) angs[1]+=360.0;
				if (angs[1] < 0.0) angs[1]+=360.0;
				if (sentryang[1] > toang[1])
				{
					if ((sentryang[1]-toang[1] > 0) && (sentryang[1]-toang[1] < 90)) withinradius++;
					else if ((toang[1]-sentryang[1] < -1) && (toang[1]-sentryang[1] < -270)) withinradius++;
					else withinradius--;
				}
				else if (toang[1] > sentryang[1])
				{
					if ((toang[1]-sentryang[1] > 0) && (toang[1]-sentryang[1] < 90)) withinradius++;
					else if ((sentryang[1]-toang[1] < -1) && (sentryang[1]-toang[1] < -270)) withinradius++;
					else withinradius--;
				}
				if (withinradius > 0)
				{
					if (angs[1] > toang[1])
					{
						if (angs[1]-toang[1] > 90) pose+=0.08;
						else if (toang[1]-angs[1] < -90) pose+=0.08;
						else pose-=0.08;
					}
					else if (toang[1] > angs[1])
					{
						if (toang[1]-angs[1] > 90) pose-=0.08;
						else if (angs[1]-toang[1] < -90) pose-=0.08;
						else pose+=0.08;
					}
					if (toang[1] < 0.0) toang[1]+=180.0;
					if (toang[1] < 0.0) toang[1]+=180.0;
					if (toang[1] < 0.0) toang[1]+=180.0;
					if (toang[1] > 180.0) toang[1]-=180.0;
					if (toang[1] > 180.0) toang[1]-=180.0;
					if (toang[1] > 180.0) toang[1]-=180.0;
					if (angs[1] < 0.0) angs[1]+=360.0;
					if (angs[1] > 180.0) angs[1]-=360.0;
					if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)) || (((angs[1]-toang[1] < 183.0) && (angs[1]-toang[1] > 177.0)) && (angs[1]-toang[1] > 0.0)) || (((toang[1]-angs[1] < 182.0) && (toang[1]-angs[1] > 178.0)) && (toang[1]-angs[1] > 0.0)))
					{
						if (pose < prevpose) pose+=0.07;
						else pose-=0.07;
					}
					else if (((toang[1]-angs[1] < 15.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 15.0)) && (angs[1]-toang[1] > 0.0)) || (((angs[1]-toang[1] < 186.0) && (angs[1]-toang[1] > 174.0)) && (angs[1]-toang[1] > 0.0)) || (((toang[1]-angs[1] < 186.0) && (toang[1]-angs[1] > 174.0)) && (toang[1]-angs[1] > 0.0)))
					{
						if (pose < prevpose) pose+=0.05;
						else pose-=0.05;
					}
				}
				if ((toang[1]-angs[1] < 6.0) || (angs[1]-toang[1] < 6.0))
				{
					if (pose < prevpose) pose+=0.01;
					else pose-=0.01;
				}
				if ((toang[1]-angs[1] > 2.0) || (angs[1]-toang[1] > 2.0))
				{
					if (pose < 0.00)
					{
						pose = 0.0;
						if (StrEqual(cls,"npc_sentry_ceiling",false)) pose = 1.0;
						if (StrEqual(cls,"npc_sentry_ground",false)) withinradius--;
					}
					else if (pose > 1.00)
					{
						pose = 1.0;
						if (StrEqual(cls,"npc_sentry_ceiling",false)) pose = 0.0;
						if (StrEqual(cls,"npc_sentry_ground",false)) withinradius--;
					}
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",pose,0);
				}
				else withinradius++;
				//PrintToServer("%1.f To %1.f from %1.f var %1.f targ %i",sentryang[1],toang[1],angs[1],toang[1]-angs[1],targ);
				if ((toang[0]-angs[0] > 3.0) || (angs[0]-toang[0] > 3.0))
				{
					if (posepitch < 0.00)
					{
						posepitch = 0.0;
						withinradius++;
					}
					else if (posepitch > 1.00)
					{
						posepitch = 1.0;
						withinradius++;
					}
					SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",posepitch,1);
				}
				else withinradius++;
				int animset = GetEntProp(entity,Prop_Data,"m_bClientSideAnimation");
				if (animset == 0) SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",0);
				else if (timesattacked[entity] > 1)
				{
					SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",1);
					timesattacked[entity] = 0;
				}
				timesattacked[entity]++;
				ChangeEdictState(entity);
				if ((centnextatk[entity] < Time) && (withinradius == 2))
				{
					centnextatk[entity] = Time+flSentryFireRate;
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
					else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
					if (StrEqual(cls,"npc_sentry_ceiling",false))
					{
						if (((sentryang[1] < 315.0) && (sentryang[1] > 135.0)) || ((sentryang[1] > -315.0) && (sentryang[1] < -135.0)))
						{
							orgs[0] = (orgs[0] - (50 * Cosine(DegToRad(angs[1]))));
							orgs[1] = (orgs[1] - (50 * Sine(DegToRad(angs[1]))));
						}
						else
						{
							orgs[0] = (orgs[0] + (50 * Cosine(DegToRad(angs[1]))));
							orgs[1] = (orgs[1] + (50 * Sine(DegToRad(angs[1]))));
						}
						//orgs[2]-=10.0;
						enorg[2]+=20.0;
					}
					else
					{
						if (((sentryang[1] < 315.0) && (sentryang[1] > 135.0)) || ((sentryang[1] > -315.0) && (sentryang[1] < -135.0)))
						{
							orgs[0] = (orgs[0] - (20 * Cosine(DegToRad(angs[1]))));
							orgs[1] = (orgs[1] - (20 * Sine(DegToRad(angs[1]))));
						}
						else
						{
							orgs[0] = (orgs[0] + (20 * Cosine(DegToRad(angs[1]))));
							orgs[1] = (orgs[1] + (20 * Sine(DegToRad(angs[1]))));
						}
						orgs[2]+=46.0;
						enorg[2]+=50.0;
						if (HasEntProp(targ,Prop_Data,"m_bDucked"))
						{
							if (GetEntProp(targ,Prop_Data,"m_bDucked") > 0) enorg[2]-=30.0;
						}
					}
					MakeVectorFromPoints(orgs,enorg,shootvel);
					GetVectorAngles(shootvel,toang);
					float fhitpos[3];
					Handle hhitpos = INVALID_HANDLE;
					if ((IsValidEntity(animprop)) && (animprop != 0)) TR_TraceRayFilter(orgs,toang,MASK_VISIBLE,RayType_Infinite,TraceEntityFilter,animprop);
					else TR_TraceRayFilter(orgs,toang,MASK_VISIBLE,RayType_Infinite,TraceEntityFilter,entity);
					targ = TR_GetEntityIndex(hhitpos);
					TR_GetEndPosition(fhitpos,hhitpos);
					CloseHandle(hhitpos);
					if ((targ != -1) && (targ != 0))
					{
						if (GetEntProp(entity,Prop_Data,"m_iAmmo",0) != -10)
						{
							int bulletmuzzle = CreateEntityByName("env_muzzleflash");
							if (bulletmuzzle != -1)
							{
								DispatchKeyValue(bulletmuzzle,"scale","0.8");
								DispatchKeyValue(bulletmuzzle,"OnUser1","!self,kill,,0.1,-1");
								DispatchSpawn(bulletmuzzle);
								ActivateEntity(bulletmuzzle);
								SetVariantString("!activator");
								AcceptEntityInput(bulletmuzzle,"SetParent",entity);
								SetVariantString("muzzle");
								AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
								if ((StrEqual(cls,"npc_sentry_ground",false)) && (IsValidEntity(animprop)) && (animprop != 0))
								{
									AcceptEntityInput(bulletmuzzle,"ClearParent");
									float tmporgs[3];
									tmporgs[0] = (orgs[0] - (2 * Cosine(DegToRad(toang[1]))));
									tmporgs[1] = (orgs[1] - (2 * Sine(DegToRad(toang[1]))));
									tmporgs[2] = orgs[2]+5.0;
									TeleportEntity(bulletmuzzle,tmporgs,toang,NULL_VECTOR);
								}
								AcceptEntityInput(bulletmuzzle,"Fire");
								AcceptEntityInput(bulletmuzzle,"FireUser1");
							}
							NPCShootBullet(entity,"weapon_sentry",orgs,toang,1.0);
							char snd[64];
							if (StrEqual(cls,"npc_sentry_ceiling",false)) Format(snd,sizeof(snd),"npc\\sentry_ceiling\\shoot1.wav");
							else Format(snd,sizeof(snd),"npc\\sentry_ground\\single.wav");
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
						}
						else
						{
							char snd[64];
							Format(snd,sizeof(snd),"weapons\\mp5\\empty.wav");
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
						}
						lastseen[entity] = Time + 3.0;
					}
					else if (lastseen[entity] < Time)
					{
						isattacking[entity] = -1;
					}
				}
				else if ((withinradius <= 0) && (lastseen[entity] < Time))
				{
					isattacking[entity] = -1;
				}
			}
			else if (!disabled)
			{
				float Time = GetTickedTime();
				if (GetArraySize(entlist) > 0)
				{
					float curorg[3];
					float angs[3];
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
					if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
					curorg[2]-=10.0;
					char sentrycls[32];
					GetEntityClassname(entity,sentrycls,sizeof(sentrycls));
					if (StrEqual(sentrycls,"npc_sentry_ceiling",false))
						curorg[2]-=20.0;
					else
					{
						curorg[2]+=30.0;
						angs[2]+=90.0;
						float vecs[3];
						vecs[0] = 1.0;
						vecs[1] = 1.0;
						vecs[2] = 1.0;
						SetEntPropVector(entity,Prop_Data,"m_vecMaxs",vecs);
						vecs[0] = -16.0;
						vecs[1] = -12.0;
						vecs[2] = -1.0;
						SetEntPropVector(entity,Prop_Data,"m_vecMins",vecs);
						vecs[0] = 0.0;
						vecs[1] = 0.0;
						vecs[2] = 0.0;
						SetEntPropVector(entity,Prop_Data,"m_vecOrigin",vecs);
						if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) SetEntPropVector(entity,Prop_Send,"m_vecOrigin",vecs);
					}
					int animprop = GetEntPropEnt(entity,Prop_Data,"m_hParent");
					int trent;
					if ((IsValidEntity(animprop)) && (animprop != 0)) trent = animprop;
					else trent = entity;
					float topdist = 0.0;
					float dist = 0.0;
					for (int j = 0;j<GetArraySize(entlist);j++)
					{
						int i = GetArrayCell(entlist,j);
						if (IsValidEntity(i))
						{
							char cls[64];
							GetEntityClassname(i,cls,sizeof(cls));
							if ((!StrEqual(cls,"npc_human_grunt",false)) && (!StrEqual(cls,"npc_human_medic",false)) && (!StrEqual(cls,"npc_human_grenadier",false)) && (!StrEqual(cls,"npc_human_commander",false)) && (!StrEqual(cls,"npc_sentry_ground",false)) && (!StrEqual(cls,"npc_sentry_ceiling",false)) && (!StrEqual(cls,"npc_abrams",false)) && (!StrEqual(cls,"npc_bullseye",false)) && (!StrEqual(cls,"npc_maker",false)) && (!StrEqual(cls,"npc_template_maker",false)) && (!StrEqual(cls,"env_xen_portal",false)) && (!StrEqual(cls,"env_xen_portal_template",false)) && (StrContains(cls,"item",false) == -1) && (StrContains(cls,"info",false) == -1) && (StrContains(cls,"game",false) == -1) && (StrContains(cls,"env",false) == -1) && (StrContains(cls,"trigger",false) == -1) && (StrContains(cls,"logic",false) == -1))
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
								TR_TraceRayFilter(curorg,toang,MASK_SHOT,RayType_Infinite,TraceEntityFilter,trent);
								TR_GetEndPosition(fhitpos,hhitpos);
								CloseHandle(hhitpos);
								bool withinradius = true;
								if (StrEqual(sentrycls,"npc_sentry_ground",false))
								{
									if (angs[1] > toang[1])
									{
										if ((angs[1]-toang[1] > 0) && (angs[1]-toang[1] < 90)) withinradius = true;
										else if ((toang[1]-angs[1] < -1) && (toang[1]-angs[1] < -270)) withinradius = true;
										else withinradius = false;
									}
									else if (toang[1] > angs[1])
									{
										if ((toang[1]-angs[1] > 0) && (toang[1]-angs[1] < 90)) withinradius = true;
										else if ((angs[1]-toang[1] < -1) && (angs[1]-toang[1] < -270)) withinradius = true;
										else withinradius = false;
									}
								}
								dist = GetVectorDistance(fhitpos,enorg,false);
								//if ((chkdist < 100) && (withinradius))
								if ((withinradius) && ((dist < 150.0) && ((dist < topdist) || (topdist == 0.0))))
								{
									topdist = dist;
									isattacking[entity] = i;
									//PrintToServer("Targeting %i %s",i,cls);
									if (dist < 100.0)
									{
										lastseen[entity] = Time + 3.0;
										char snd[64];
										if (StrEqual(sentrycls,"npc_sentry_ceiling",false)) Format(snd,sizeof(snd),"npc\\sentry_ceiling\\ping2.wav");
										else Format(snd,sizeof(snd),"npc\\sentry_ground\\ping.wav");
										EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
										break;
									}
								}
							}
						}
					}
				}
			}
			else
			{
				isattacking[entity] = -1;
				int rendermd = GetEntProp(entity,Prop_Data,"m_nRenderFX");
				if (rendermd != 6) SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
				char cls[24];
				GetEntityClassname(entity,cls,sizeof(cls));
				int prop = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
				if (!IsValidEntity(prop))
				{
					prop = CreateEntityByName("prop_dynamic");
					if (prop != -1)
					{
						float orgs[3];
						float angs[3];
						if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
						else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
						if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
						//orgs[2]-=10.0;
						DispatchKeyValue(prop,"solid","0");
						if (StrEqual(cls,"npc_sentry_ceiling",false)) DispatchKeyValue(prop,"model","models/NPCs/sentry_ceiling.mdl");
						else DispatchKeyValue(prop,"model","models/NPCs/sentry_ground.mdl");
						TeleportEntity(prop,orgs,angs,NULL_VECTOR);
						DispatchSpawn(prop);
						ActivateEntity(prop);
						SetVariantString("!activator");
						AcceptEntityInput(prop,"SetParent",entity);
						SetVariantString("retract");
						AcceptEntityInput(prop,"SetAnimation");
						SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",prop);
					}
				}
				if (prop != -1)
				{
					int seq = GetEntProp(prop,Prop_Data,"m_nSequence");
					if (seq != 3)
					{
						float pose = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",0);
						float posepitch = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",1);
						rendermd = GetEntProp(prop,Prop_Data,"m_nRenderMode");
						if (rendermd != 0) SetEntProp(prop,Prop_Data,"m_nRenderMode",0);
						SetEntProp(prop,Prop_Data,"m_nRenderFX",0);
						SetVariantString("retract");
						AcceptEntityInput(prop,"SetAnimation");
						SetEntPropFloat(prop,Prop_Data,"m_flPoseParameter",pose,0);
						SetEntPropFloat(prop,Prop_Data,"m_flPoseParameter",posepitch,0);
						char snd[64];
						if (StrEqual(cls,"npc_sentry_ceiling",false)) Format(snd,sizeof(snd),"npc\\sentry_ceiling\\retract.wav");
						else Format(snd,sizeof(snd),"npc\\sentry_ground\\retract.wav");
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
					}
				}
			}
		}
	}
}

public Action SetupSentryDelay(Handle timer, int propphy)
{
	if (IsValidEntity(propphy))
	{
		int entity = GetEntPropEnt(propphy,Prop_Data,"m_hEffectEntity");
		if (entity != -1)
		{
			float orgs[3];
			float angs[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
			if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
			orgs[2]+=3.0;
			TeleportEntity(propphy,orgs,angs,NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(entity,"SetParent",propphy);
		}
		if (FindStringInArray(precachedarr,"npc_sentry_ground") == -1)
		{
			PrecacheSound("weapons\\mp5\\empty.wav",true);
			recursion("sound/npc/sentry_ground/");
			PushArrayString(precachedarr,"npc_sentry_ground");
		}
		int mhchk = GetEntProp(entity,Prop_Data,"m_iMaxHealth");
		Handle cvar = FindConVar("sk_sentry_ground_health");
		if (cvar != INVALID_HANDLE)
		{
			int cvarh = GetConVarInt(cvar);
			if (mhchk != cvarh)
			{
				SetEntProp(entity,Prop_Data,"m_iHealth",cvarh);
				SetEntProp(entity,Prop_Data,"m_iMaxHealth",cvarh);
			}
		}
		CloseHandle(cvar);
		if (HasEntProp(entity,Prop_Data,"m_bloodColor")) SetEntProp(entity,Prop_Data,"m_bloodColor",3);
		if (HasEntProp(entity,Prop_Data,"m_MoveType")) SetEntProp(entity,Prop_Data,"m_MoveType",3);
		//SetEntProp(entity,Prop_Data,"m_MoveType",0);
		SetEntData(entity, collisiongroup, 17, 4, true);
		//SetVariantString("1.1");
		//AcceptEntityInput(entity,"SetModelScale");
		if (HasEntProp(entity,Prop_Data,"m_flModelScale")) SetEntPropFloat(entity,Prop_Data,"m_flModelScale",1.1);
		float vecs[3];
		vecs[0] = 1.0;
		vecs[1] = 1.0;
		vecs[2] = 1.0;
		SetEntPropVector(entity,Prop_Data,"m_vecMaxs",vecs);
		vecs[0] = -16.0;
		vecs[1] = -12.0;
		vecs[2] = -1.0;
		SetEntPropVector(entity,Prop_Data,"m_vecMins",vecs);
		//SetEntProp(entity,Prop_Data,"m_MoveType",0);
		SetEntData(entity, collisiongroup, 17, 4, true);
		SDKHookEx(entity,SDKHook_Think,sentriesthink);
		SDKHookEx(entity,SDKHook_OnTakeDamage,notkdmg);
		char targn[64];
		GetEntPropString(propphy,Prop_Data,"m_iName",targn,sizeof(targn));
		int keepupright = CreateEntityByName("phys_keepupright");
		if (keepupright != -1)
		{
			DispatchKeyValue(keepupright,"spawnflags","0");
			DispatchKeyValue(keepupright,"attach1",targn);
			DispatchKeyValue(keepupright,"angularlimit","10");
			DispatchSpawn(keepupright);
			ActivateEntity(keepupright);
			AcceptEntityInput(keepupright,"TurnOn");
		}
	}
}