void bmsgargthink(int entity)
{
	if (IsValidEntity(entity))
	{
		//poseparam 1 aimup
		//poseparam 2 bodyrot right
		//poseparam 3 headrotate right
		//poseparam 4 headrotate up
		//poseparam 5 headrotate left
		//poseparam 6 bodyrotatefast 0.0 right, 1.0 left
		//poseparam 7 look up 0.0 up, 1.0 down
		if (HasEntProp(entity,Prop_Data,"m_flPoseParameter"))
		{
			if (HasEntProp(entity,Prop_Data,"m_hEffectEntity"))
			{
				bool targreset = false;
				int mdlset = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
				float entpos[3];
				float entangs[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",entpos);
				else if (HasEntProp(entity,Prop_Data,"m_vecOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecOrigin",entpos);
				if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",entangs);
				if (!IsValidEntity(mdlset))
				{
					mdlset = CreateEntityByName("prop_dynamic_override");
					if (mdlset != -1)
					{
						char clsres[64];
						GetEntityClassname(entity,clsres,sizeof(clsres));
						ReplaceStringEx(clsres,sizeof(clsres),"npc_","",-1,-1,false);
						char targn[128];
						char boundbtarg[130];
						GetEntPropString(entity,Prop_Data,"m_iName",targn,sizeof(targn));
						if (strlen(targn) < 1)
						{
							Format(targn,sizeof(targn),"%s%i",clsres,entity);
							SetEntPropString(entity,Prop_Data,"m_iName",targn);
						}
						Format(boundbtarg,sizeof(boundbtarg),"%sbbgarg",targn);
						DispatchKeyValue(mdlset,"model","models/xenians/garg.mdl");
						DispatchKeyValue(mdlset,"solid","0");
						DispatchKeyValue(mdlset,"DefaultAnim","idle");
						DispatchKeyValue(mdlset,"DisableShadow","1");
						//DispatchKeyValue(mdlset,"targetname",boundbtarg);
						TeleportEntity(mdlset,entpos,entangs,NULL_VECTOR);
						DispatchSpawn(mdlset);
						ActivateEntity(mdlset);
						SetVariantString("!activator");
						AcceptEntityInput(mdlset,"SetParent",entity);
						SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",mdlset);
						SetEntProp(entity,Prop_Data,"m_nRenderMode",10);
						SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
						if (HasEntProp(entity, Prop_Data, "m_bloodColor")) SetEntProp(entity, Prop_Data, "m_bloodColor", 2);
						int garghitbox = CreateEntityByName("generic_actor");
						if (garghitbox != -1)
						{
							DispatchKeyValue(garghitbox, "model", "models/xenians/garg.mdl");
							DispatchKeyValue(garghitbox, "targetname", boundbtarg);
							//DispatchKeyValue(garghitbox, "RenderMode", "10");
							DispatchKeyValue(garghitbox, "RenderFX", "6");
							DispatchKeyValue(garghitbox, "shadowcastdist", "0");
							DispatchKeyValue(garghitbox, "DisableShadows", "1");
							TeleportEntity(garghitbox, entpos, entangs, NULL_VECTOR);
							DispatchSpawn(garghitbox);
							ActivateEntity(garghitbox);
							SetVariantString("!activator");
							AcceptEntityInput(garghitbox, "SetParent", entity);
							if (!IsModelPrecached("models/xenians/garg.mdl")) PrecacheModel("models/xenians/garg.mdl", true);
							SetEntityModel(garghitbox, "models/xenians/garg.mdl");
							
							Handle dp = CreateDataPack();
							WritePackString(dp, "models/xenians/garg.mdl");
							WritePackCell(dp, garghitbox);
							WritePackString(dp, "generic_actor");
							CreateTimer(0.1, resetmdl, dp, TIMER_FLAG_NO_MAPCHANGE);
							
							SetEntPropEnt(garghitbox, Prop_Data, "m_hEffectEntity", entity);
							SDKHookEx(garghitbox, SDKHook_OnTakeDamage, bmsgargtkdmg);
							if (HasEntProp(garghitbox, Prop_Data, "m_bloodColor")) SetEntProp(garghitbox, Prop_Data, "m_bloodColor", 2);
							float vMins[3];
							float vMaxs[3];
							vMins[0] = -30.0;
							vMins[1] = -30.0;
							vMaxs[0] = 30.0;
							vMaxs[1] = 30.0;
							vMaxs[2] = 238.0;
							SetEntPropVector(garghitbox, Prop_Data, "m_vecMins", vMins);
							SetEntPropVector(garghitbox, Prop_Data, "m_vecMaxs", vMaxs);
							SetEntProp(garghitbox, Prop_Data, "m_iHealth", 999);
							SetEntProp(garghitbox, Prop_Data, "m_iMaxHealth", 999);
							SetEntPropEnt(mdlset, Prop_Data, "m_hEffectEntity", garghitbox);
						}
						/*
						float vMins[3];
						float vMaxs[3];
						GetEntPropVector(mdlset, Prop_Data, "m_vecMins", vMins);
						GetEntPropVector(mdlset, Prop_Data, "m_vecMaxs", vMaxs);
						SetEntPropVector(entity, Prop_Data, "m_vecMins", vMins);
						SetEntPropVector(entity, Prop_Data, "m_vecMaxs", vMaxs);
						*/
						int sprite = CreateEntityByName("env_sprite");
						if (sprite != -1)
						{
							DispatchKeyValue(sprite, "spawnflags", "1");
							DispatchKeyValue(sprite, "GlowProxySize", "1");
							DispatchKeyValue(sprite, "HDRColorScale", "1");
							DispatchKeyValue(sprite, "model", "sprites/glow01.spr");
							DispatchKeyValue(sprite, "framerate", "1");
							DispatchKeyValue(sprite, "RenderMode", "9");
							DispatchKeyValue(sprite, "scale", "0.8");
							DispatchKeyValue(sprite, "rendercolor", "255 128 0");
							DispatchSpawn(sprite);
							ActivateEntity(sprite);
							SetVariantString("!activator");
							AcceptEntityInput(sprite, "SetParent", mdlset);
							SetVariantString("eyes");
							AcceptEntityInput(sprite, "SetParentAttachment");
							float offs[3];
							offs[0] = -3.0;
							offs[1] = 6.0;
							SetEntPropVector(sprite, Prop_Data, "m_vecOrigin", offs);
							//SetEntPropEnt(mdlset, Prop_Data, "m_hEffectEntity", sprite);
						}
						Handle dp = CreateDataPack();
						WritePackString(dp,targn);
						WritePackString(dp,boundbtarg);
						CreateTimer(0.1,GargResetColl,dp,TIMER_FLAG_NO_MAPCHANGE);
						setuprelations("npc_bmsgargantua");
					}
				}
				
				int gargbb = GetEntPropEnt(mdlset, Prop_Data, "m_hEffectEntity");
				if (IsValidEntity(gargbb))
				{
					// Keep at no offset, certain triggers and brushes are pushing this off
					float vecNoOffset[3];
					if (HasEntProp(gargbb, Prop_Data, "m_vecOrigin"))
						SetEntPropVector(gargbb, Prop_Data, "m_vecOrigin", vecNoOffset);
					if (HasEntProp(gargbb, Prop_Send, "m_vecOrigin"))
						SetEntPropVector(gargbb, Prop_Send, "m_vecOrigin", vecNoOffset);
				}
				
				int seq = GetEntProp(entity, Prop_Data, "m_nSequence");
				int mdlseq = GetEntProp(mdlset, Prop_Data, "m_nSequence");
				if (mdlseq != seq)
				{
					char sequencename[64];
					switch(seq)
					{
						case 0:
							Format(sequencename,sizeof(sequencename),"idle");
						case 1:
							Format(sequencename,sizeof(sequencename),"angryidle");
						case 2:
							Format(sequencename,sizeof(sequencename),"physflinch_mid");
						case 3:
							Format(sequencename,sizeof(sequencename),"gesture_physflinch_chest");
						case 4:
							Format(sequencename,sizeof(sequencename),"gesture_physflinch_small");
						case 5:
							Format(sequencename,sizeof(sequencename),"gesture_physflinch_stomach");
						case 6:
							Format(sequencename,sizeof(sequencename),"gesture_physflinch_l");
						case 7:
							Format(sequencename,sizeof(sequencename),"gesture_physflinch_r");
						case 8:
							Format(sequencename,sizeof(sequencename),"fire1");
						case 9:
							Format(sequencename,sizeof(sequencename),"roar1");
						case 10:
							Format(sequencename,sizeof(sequencename),"roar2");
						case 11:
							Format(sequencename,sizeof(sequencename),"melee1");
						case 12:
							Format(sequencename,sizeof(sequencename),"melee2");
						case 13:
							Format(sequencename,sizeof(sequencename),"st_shake_tower_enter");
						case 14:
							Format(sequencename,sizeof(sequencename),"st_shake_tower_exit");
						case 15:
							Format(sequencename,sizeof(sequencename),"st_shake_tower_idle");
						case 16:
							Format(sequencename,sizeof(sequencename),"powerup_ending_enter");
						case 17:
							Format(sequencename,sizeof(sequencename),"powerup_ending_idle");
						case 18:
							Format(sequencename,sizeof(sequencename),"powerup_ending_exit");
						case 19:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding01_enter");
						case 20:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding01_exit");
						case 21:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding01_idle");
						case 22:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding02_idle");
						case 23:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding02_exit");
						case 24:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding02_enter");
						case 25:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding03_exit");
						case 26:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding03_enter");
						case 27:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding03_idle");
						case 28:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding04_enter");
						case 29:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding04_exit");
						case 30:
							Format(sequencename,sizeof(sequencename),"powerup_tramholding04_idle");
						case 31:
							Format(sequencename,sizeof(sequencename),"powerup_roomexit_idle");
						case 32:
							Format(sequencename,sizeof(sequencename),"powerup_roomexit_exit");
						case 33:
							Format(sequencename,sizeof(sequencename),"powerup_roomexit_enter");
						case 34:
							Format(sequencename,sizeof(sequencename),"powerup_gargentrance");
						case 35:
							Format(sequencename,sizeof(sequencename),"powerup_electrocute");
						case 36:
							Format(sequencename,sizeof(sequencename),"powerup_wirestangled");
						case 37:
							Format(sequencename,sizeof(sequencename),"st_gatesmash");
						case 38:
							Format(sequencename,sizeof(sequencename),"charge_run");
						case 39:
							Format(sequencename,sizeof(sequencename),"st_doorsmash1");
						case 40:
							Format(sequencename,sizeof(sequencename),"st_doorsmash2");
						case 41:
							Format(sequencename,sizeof(sequencename),"st_doorsmash2_dent");
						case 42:
							Format(sequencename,sizeof(sequencename),"st_doorsmash2_loop");
						case 43:
							Format(sequencename,sizeof(sequencename),"st_gatesmash_c2a5h");
						case 44:
							Format(sequencename,sizeof(sequencename),"gesture_turn_right_45");
						case 45:
							Format(sequencename,sizeof(sequencename),"gesture_turn_right_90");
						case 46:
							Format(sequencename,sizeof(sequencename),"gesture_turn_left_45");
						case 47:
							Format(sequencename,sizeof(sequencename),"gesture_turn_left_90");
						case 48:
							Format(sequencename,sizeof(sequencename),"Run_all");
						case 49:
							Format(sequencename,sizeof(sequencename),"walk_all");
						case 50:
							Format(sequencename,sizeof(sequencename),"layer_Aim_all");
						case 51:
							Format(sequencename,sizeof(sequencename),"aim_walk_all_delta");
						case 52:
							Format(sequencename,sizeof(sequencename),"layer_walk_aiming");
						case 53:
							Format(sequencename,sizeof(sequencename),"walk_aiming_all");
						case 54:
							Format(sequencename,sizeof(sequencename),"layer_run_aiming");
						case 55:
							Format(sequencename,sizeof(sequencename),"run_aiming_all");
						case 56:
							Format(sequencename,sizeof(sequencename),"head_rot_z");
						case 57:
							Format(sequencename,sizeof(sequencename),"head_rot_y");
						case 58:
							Format(sequencename,sizeof(sequencename),"head_rot_x");
						case 59:
							Format(sequencename,sizeof(sequencename),"body_rot_z");
						case 60:
							Format(sequencename,sizeof(sequencename),"spine_rot_z");
					}
					if (strlen(sequencename) > 0)
					{
						//PrintToServer("SetAnim %s",sequencename);
						SetVariantString(sequencename);
						AcceptEntityInput(mdlset,"SetAnimation");
						SetEntPropString(mdlset,Prop_Data,"m_iszDefaultAnim",sequencename);
					}
				}
				float Time = GetTickedTime();
				if (lastseen[entity] < Time)
				{
					isattacking[entity] = -1;
					lastseen[entity] = Time+GetRandomFloat(3.0,6.0);
					targreset = true;
				}
				if (HasEntProp(entity, Prop_Data, "m_hTargetEnt"))
				{
					int scrent = GetEntPropEnt(entity, Prop_Data, "m_hTargetEnt");
					if (IsValidEntity(scrent))
					{
						if (HasEntProp(scrent, Prop_Data, "m_iName"))
						{
							char namechk[9];
							GetEntPropString(scrent, Prop_Data, "m_iName", namechk, sizeof(namechk));
							if (strlen(namechk) > 0) return;
						}
					}
				}
				if (HasEntProp(entity, Prop_Data, "m_SleepState"))
				{
					int sleepstate = GetEntProp(entity, Prop_Data, "m_SleepState");
					if (sleepstate != 0) return;
				}
				if (centnextatk[mdlset] <= Time)
				{
					//check for prop_physics with models starting with models/props_vehicles, melee maybe?
					centnextatk[mdlset] = Time+2.0;
					float loc[3];
					loc[0] = (entpos[0] + (40 * Cosine(DegToRad(entangs[1]))));
					loc[1] = (entpos[1] + (40 * Sine(DegToRad(entangs[1]))));
					loc[2] = (entpos[2] + 10);
					Handle hhitpos = TR_TraceRayFilterEx(loc,entangs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,entity);
					int hitent = TR_GetEntityIndex(hhitpos);
					CloseHandle(hhitpos);
					if ((!IsValidEntity(hitent)) || (hitent == 0))
					{
						loc[0] = (entpos[0] + (40 * Cosine(DegToRad(entangs[1]))));
						loc[1] = (entpos[1] + (40 * Sine(DegToRad(entangs[1]))));
						loc[2] = (entpos[2] + 50);
						hhitpos = TR_TraceRayFilterEx(loc,entangs,MASK_SHOT,RayType_Infinite,TraceEntityFilter,entity);
						hitent = TR_GetEntityIndex(hhitpos);
						CloseHandle(hhitpos);
					}
					if ((IsValidEntity(hitent)) && (hitent != 0))
					{
						char hitcls[32];
						GetEntityClassname(hitent,hitcls,sizeof(hitcls));
						if ((StrEqual(hitcls,"prop_physics",false)) || (StrEqual(hitcls,"prop_vehicle_jeep",false)) || (StrEqual(hitcls,"prop_vehicle_airboat",false)))
						{
							if (HasEntProp(hitent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(hitent,Prop_Data,"m_vecAbsOrigin",loc);
							else if (HasEntProp(hitent,Prop_Send,"m_vecOrigin")) GetEntPropVector(hitent,Prop_Send,"m_vecOrigin",loc);
							if (GetVectorDistance(entpos,loc,false) < 225.0)
							{
								if (isattacking[mdlset] == 1)
								{
									GargStopFire(entity,mdlset,entpos,entangs);
								}
								isattacking[mdlset] = 2;
								char atkanim[128];
								Format(atkanim,sizeof(atkanim),"melee%i",GetRandomInt(1,2));
								RunSeq(entity,entpos,entangs,atkanim,"",2,false);
								char snd[64];
								Format(snd,sizeof(snd),"npc\\garg\\garg_claw%i.wav",GetRandomInt(1,4));
								EmitAmbientSound(snd, entpos, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								EmitAmbientSound(snd, entpos, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								EmitAmbientSound("npc\\garg\\garg_attack1.wav", entpos, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								centnextatk[entity] = Time+1.7;
								DoRadialDamage(entity,entangs[1],250.0,30.0,"melee",DMG_CLUB,1.5);
								loc[0] = (entpos[0] + (200 * Cosine(DegToRad(entangs[1]))));
								loc[1] = (entpos[1] + (200 * Sine(DegToRad(entangs[1]))));
								loc[2] = (entpos[2] + 150);
								float shootvel[3];
								MakeVectorFromPoints(entpos,loc,shootvel);
								ScaleVector(shootvel,10.0);
								Handle dp = CreateDataPack();
								WritePackCell(dp,hitent);
								WritePackFloat(dp,shootvel[0]);
								WritePackFloat(dp,shootvel[1]);
								WritePackFloat(dp,shootvel[2]);
								CreateTimer(0.5,LaunchTarget,dp,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
				int targ = isattacking[entity];
				if ((IsValidEntity(targ)) && (targ != 0))
				{
					float enorg[3];
					float orgs[3];
					float angs[3];
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
					
					// Always push all players away if too close
					float shootvel[3];
					for (int i = 0; i < MaxClients+1; i++)
					{
						if (IsValidEntity(i))
						{
							if (HasEntProp(i, Prop_Data, "m_vecAbsOrigin")) GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", enorg);
							else if (HasEntProp(i, Prop_Send, "m_vecOrigin")) GetEntPropVector(i, Prop_Send, "m_vecOrigin", enorg);
							if (GetVectorDistance(orgs, enorg, false) < 100.0)
							{
								// Only lateral
								enorg[2] = orgs[2];
								MakeVectorFromPoints(orgs, enorg, shootvel);
								ScaleVector(shootvel, 5.0);
								TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, shootvel);
							}
						}
					}
					
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
					else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
					//if (HasEntProp(mdlset,Prop_Data,"m_angAbsRotation")) GetEntPropVector(mdlset,Prop_Data,"m_angAbsRotation",entangs);
					int attachfind = CreateEntityByName("prop_dynamic");
					if (attachfind != -1)
					{
						DispatchKeyValue(attachfind,"rendermode","10");
						DispatchKeyValue(attachfind,"solid","0");
						DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(attachfind);
						ActivateEntity(attachfind);
						SetVariantString("!activator");
						AcceptEntityInput(attachfind,"SetParent",mdlset);
						SetVariantString("eyes");
						AcceptEntityInput(attachfind,"SetParentAttachment");
						if (HasEntProp(attachfind,Prop_Data,"m_angAbsRotation")) GetEntPropVector(attachfind,Prop_Data,"m_angAbsRotation",angs);
						AcceptEntityInput(attachfind,"kill");
					}
					float toang[3];
					float pose = GetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",3);
					float prevpose = pose;
					//angs[1] = angs[1]-(180.0*pose);
					//angs[1]+=180.0;
					angs[1] = 145.0*pose-77.5;
					angs[1]+=entangs[1];
					if (angs[1] < 0.0) angs[1]+=360.0;
					if (angs[1] > 360) angs[1]-=360.0;
					if (angs[1] > 360) angs[1]-=360.0;
					float loc[3];
					loc[0] = (orgs[0]);
					loc[1] = (orgs[1]);
					loc[2] = (orgs[2] + 60);
					enorg[2]-=10.0;
					if (HasEntProp(targ,Prop_Data,"m_bDucked"))
					{
						if (GetEntProp(targ,Prop_Data,"m_bDucked") > 0) enorg[2]-=45.0;
					}
					MakeVectorFromPoints(loc,enorg,shootvel);
					GetVectorAngles(shootvel,toang);
					//PrintToServer("EyeAng %1.f ent %1.f to %1.f",angs[1],entangs[1],toang[1]);
					if (angs[1] > toang[1])
					{
						if (angs[1]-toang[1] > 180) pose+=0.05;
						else if (toang[1]-angs[1] < -180) pose+=0.05;
						else pose-=0.05;
					}
					else if (toang[1] > angs[1])
					{
						if (toang[1]-angs[1] > 180) pose-=0.05;
						else if (angs[1]-toang[1] < -180) pose-=0.05;
						else pose+=0.05;
					}
					if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)))
					{
						if (pose < prevpose) pose+=0.04;
						else pose-=0.04;
					}
					else if ((toang[1]-angs[1] < 15.0) || (angs[1]-toang[1] < 15.0))
					{
						if (pose < prevpose) pose+=0.02;
						else pose-=0.02;
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
						SetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",pose,3);
					}
					float posepitch = GetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",4);
					angs[0] = (160.0*posepitch)-80.0;
					if (toang[0] > 90.0) toang[0]-=360.0;
					//toang[0]=toang[0]*5.0;
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
						SetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",posepitch,4);
					}
					float chkdist = GetVectorDistance(orgs,enorg,false);
					if (chkdist < 1024.0)
					{
						//rotate arms to target
						posepitch = GetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",1);
						angs[0] = (160.0*posepitch)-80.0;//-110.0
						if (toang[0] > 90.0) toang[0]-=360.0;
						//toang[0]=toang[0]*5.0;
						if (angs[0] > toang[0])
						{
							posepitch-=0.02;
						}
						else posepitch+=0.02;
						if ((toang[0]-angs[0] > 3.0) || (angs[0]-toang[0] > 3.0))
						{
							if (posepitch < 0.20)
							{
								posepitch = 0.20;
							}
							else if (posepitch > 0.65)
							{
								posepitch = 0.65;
							}
							SetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",posepitch,1);
						}
						pose = GetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",2);
						prevpose = pose;
						angs[1] = 160.0*pose-80;
						angs[1]+=entangs[1];
						if (angs[1] < 0.0) angs[1]+=360.0;
						if (angs[1] > 360) angs[1]-=360.0;
						if (angs[1] > 360) angs[1]-=360.0;
						/*
						loc[0] = (orgs[0] + (50 * Cosine(DegToRad(angs[1]))));
						loc[1] = (orgs[1] + (50 * Sine(DegToRad(angs[1]))));
						loc[2] = (orgs[2]);
						*/
						MakeVectorFromPoints(loc,enorg,shootvel);
						GetVectorAngles(shootvel,toang);
						//PrintToServer("EyeAng %1.f ent %1.f to %1.f",angs[1],entangs[1],toang[1]);
						if (angs[1] > toang[1])
						{
							if (angs[1]-toang[1] > 180) pose+=0.05;
							else if (toang[1]-angs[1] < -180) pose+=0.05;
							else pose-=0.05;
						}
						else if (toang[1] > angs[1])
						{
							if (toang[1]-angs[1] > 180) pose-=0.05;
							else if (angs[1]-toang[1] < -180) pose-=0.05;
							else pose+=0.05;
						}
						if (((toang[1]-angs[1] < 6.0) && (toang[1]-angs[1] > 0.0)) || (((angs[1]-toang[1] < 6.0)) && (angs[1]-toang[1] > 0.0)))
						{
							if (pose < prevpose) pose+=0.03;
							else pose-=0.03;
						}
						else if ((toang[1]-angs[1] < 15.0) || (angs[1]-toang[1] < 15.0))
						{
							if (pose < prevpose) pose+=0.02;
							else pose-=0.02;
						}
						if ((toang[1]-angs[1] > 2.0) || (angs[1]-toang[1] > 2.0))
						{
							if (pose < 0.02)
							{
								pose = 0.01;
							}
							else if (pose > 0.98)
							{
								pose = 0.98;
							}
							SetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",pose,2);
						}
						if (centnextatk[entity] < Time)
						{
							bool withinradius = CheckWithinRadius(entangs[1],toang[1],20.0);
							float faceang[3];
							faceang[1] = toang[1];
							if ((!withinradius) && (chkdist < 350.0))
							{
								TeleportEntity(entity,NULL_VECTOR,faceang,NULL_VECTOR);
								withinradius = true;
							}
							
							if ((chkdist < 250.0) && (withinradius))
							{
								if (isattacking[mdlset] == 1)
								{
									GargStopFire(entity,mdlset,orgs,entangs);
								}
								isattacking[mdlset] = 2;
								char atkanim[128];
								Format(atkanim,sizeof(atkanim),"melee%i",GetRandomInt(1,2));
								RunSeq(entity,orgs,faceang,atkanim,"",2,false);
								char snd[64];
								Format(snd,sizeof(snd),"npc\\garg\\garg_claw%i.wav",GetRandomInt(1,4));
								EmitAmbientSound(snd, orgs, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								EmitAmbientSound(snd, orgs, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								EmitAmbientSound("npc\\garg\\garg_attack1.wav", orgs, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								centnextatk[entity] = Time+1.7;
								DoRadialDamage(entity,entangs[1],250.0,40.0,"melee",DMG_CLUB,1.5);
							}
							else if ((withinradius) && (!isattacking[mdlset]) && (chkdist < 450.0))
							{
								isattacking[mdlset] = 1;
								RunSeq(entity,orgs,angs,"fire1","",2,true);
								char targpointr[32];
								Format(targpointr,sizeof(targpointr),"firepointr%i",entity);
								char targpointl[32];
								Format(targpointl,sizeof(targpointl),"firepointl%i",entity);
								float offs[3];
								offs[0] = 300.0;
								float offorg[3];
								angs[1]+=30.0;
								offorg[0] = (orgs[0] + (50 * Cosine(DegToRad(angs[1]))));
								offorg[1] = (orgs[1] + (50 * Sine(DegToRad(angs[1]))));
								offorg[2] = (orgs[2] - (50 * Sine(DegToRad(angs[0]))))+50.0;
								angs[1]-=60.0;
								int targr = CreateEntityByName("prop_dynamic_override");
								if (targr != -1)
								{
									DispatchKeyValue(targr,"targetname",targpointr);
									DispatchKeyValue(targr,"rendermode","10");
									DispatchKeyValue(targr,"solid","0");
									DispatchKeyValue(targr,"disableshadows","1");
									DispatchKeyValue(targr,"disablereceiveshadows","1");
									DispatchKeyValue(targr,"model","models/props_junk/popcan01a.mdl");
									TeleportEntity(targr,offorg,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(targr);
									ActivateEntity(targr);
									SetVariantString("!activator");
									AcceptEntityInput(targr,"SetParent",mdlset);
									SetVariantString("FireR");
									AcceptEntityInput(targr,"SetParentAttachment");
									SetEntPropVector(targr,Prop_Data,"m_vecOrigin",offs);
									gargfiretarg[entity][0] = targr;
								}
								int effect = CreateEntityByName("info_particle_system");
								if (effect != -1)
								{
									DispatchKeyValue(effect,"effect_name","gargantua_flame");
									DispatchKeyValue(effect,"start_active","1");
									DispatchKeyValue(effect,"cpoint1",targpointr);
									TeleportEntity(effect,offorg,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(effect);
									ActivateEntity(effect);
									SetVariantString("!activator");
									AcceptEntityInput(effect,"SetParent",mdlset);
									SetVariantString("FireR");
									AcceptEntityInput(effect,"SetParentAttachment");
									AcceptEntityInput(effect,"Start");
									gargfiretarg[entity][2] = effect;
								}
								offorg[0] = (orgs[0] + (50 * Cosine(DegToRad(angs[1]))));
								offorg[1] = (orgs[1] + (50 * Sine(DegToRad(angs[1]))));
								offorg[2] = (orgs[2] - (50 * Sine(DegToRad(angs[0]))))+50.0;
								angs[1]+=30.0;
								targr = CreateEntityByName("prop_dynamic_override");
								if (targr != -1)
								{
									DispatchKeyValue(targr,"targetname",targpointl);
									DispatchKeyValue(targr,"rendermode","10");
									DispatchKeyValue(targr,"solid","0");
									DispatchKeyValue(targr,"disableshadows","1");
									DispatchKeyValue(targr,"disablereceiveshadows","1");
									DispatchKeyValue(targr,"model","models/props_junk/popcan01a.mdl");
									TeleportEntity(targr,offorg,NULL_VECTOR,NULL_VECTOR);
									DispatchSpawn(targr);
									ActivateEntity(targr);
									SetVariantString("!activator");
									AcceptEntityInput(targr,"SetParent",mdlset);
									SetVariantString("FireL");
									AcceptEntityInput(targr,"SetParentAttachment");
									SetEntPropVector(targr,Prop_Data,"m_vecOrigin",offs);
									gargfiretarg[entity][1] = targr;
								}
								effect = CreateEntityByName("info_particle_system");
								if (effect != -1)
								{
									DispatchKeyValue(effect,"effect_name","gargantua_flame");
									DispatchKeyValue(effect,"start_active","1");
									DispatchKeyValue(effect,"cpoint1",targpointl);
									TeleportEntity(effect,offorg,NULL_VECTOR,NULL_VECTOR);
									//PrintToServer("Create Effect %i at %1.f %1.f %1.f targ %s",effect,offorg[0],offorg[1],offorg[2],targpointl);
									DispatchSpawn(effect);
									ActivateEntity(effect);
									SetVariantString("!activator");
									AcceptEntityInput(effect,"SetParent",mdlset);
									SetVariantString("FireL");
									AcceptEntityInput(effect,"SetParentAttachment");
									AcceptEntityInput(effect,"Start");
									gargfiretarg[entity][3] = effect;
								}
								EmitAmbientSound("npc\\garg\\garg_beam_start.wav", orgs, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								EmitAmbientSound("npc\\garg\\garg_beam_start.wav", orgs, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
								DoRadialDamage(entity,entangs[1],450.0,15.0,"fire",DMG_BURN|DMG_SONIC,0.0);
							}
							else if (((toang[1]-entangs[1] < 10.0) || (entangs[1]-toang[1] < 10.0)) && (isattacking[mdlset] == 1) && (chkdist < 450.0))
							{
								DoRadialDamage(entity,entangs[1],450.0,15.0,"fire",DMG_BURN|DMG_SONIC,0.0);
								centnextatk[entity] = Time+0.5;
							}
							else if ((isattacking[mdlset] == 2) && (chkdist > 250.0))
							{
								isattacking[mdlset] = 0;
								if (centnextsndtime[mdlset] < Time)
								{
									char snd[64];
									Format(snd,sizeof(snd),"npc\\garg\\garg_roar%i_short.wav",GetRandomInt(1,4));
									EmitAmbientSound(snd, entpos, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
									centnextsndtime[mdlset] = Time+1.5;
								}
							}
							else if ((isattacking[mdlset] == 1) && (chkdist > 450.0))
							{
								GargStopFire(entity,mdlset,orgs,angs);
							}
						}
						else if ((isattacking[mdlset] == 1) && (chkdist > 450.0))
						{
							GargStopFire(entity,mdlset,orgs,angs);
						}
					}
					else
					{
						//rotate arms to default position
						pose = GetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",2);
						if (pose != 0.5)
						{
							if (pose > 0.5) pose-=0.02;
							else if (pose < 0.5) pose+=0.02;
							if (pose < 0.01)
							{
								pose = 0.01;
							}
							else if (pose > 0.60)
							{
								pose = 0.60;
							}
							if ((pose < 0.51) && (pose > 0.47)) pose = 0.5;
							SetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",pose,2);
						}
						posepitch = GetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",1);
						if (posepitch != 0.5)
						{
							if (posepitch > 0.5) posepitch-=0.02;
							else if (posepitch < 0.5) posepitch+=0.02;
							if (posepitch < 0.01)
							{
								posepitch = 0.01;
							}
							else if (posepitch > 0.60)
							{
								posepitch = 0.60;
							}
							if ((posepitch < 0.51) && (posepitch > 0.47)) posepitch = 0.5;
							SetEntPropFloat(mdlset,Prop_Data,"m_flPoseParameter",posepitch,1);
						}
					}
					int animset = GetEntProp(mdlset,Prop_Data,"m_bClientSideAnimation");
					if (animset == 0) SetEntProp(mdlset,Prop_Data,"m_bClientSideAnimation",0);
					else if (timesattacked[mdlset] > 1)
					{
						SetEntProp(mdlset,Prop_Data,"m_bClientSideAnimation",1);
						timesattacked[mdlset] = 0;
					}
					timesattacked[mdlset]++;
					ChangeEdictState(mdlset);
					float oowchk[3];
					float aimdown[3];
					aimdown[0] = 90.0;
					if ((isattacking[mdlset] == 0) && (chkdist < 2048) && (centnextatk[entity] < Time))
					{
						oowchk[0] = (enorg[0] - (75 * Cosine(DegToRad(toang[1]))));
						oowchk[1] = (enorg[1] - (75 * Sine(DegToRad(toang[1]))));
						oowchk[2] = enorg[2]+10.0;
						if (!TR_PointOutsideWorld(oowchk))
						{
							Handle hhitpos = TR_TraceRayFilterEx(oowchk,aimdown,MASK_SHOT,RayType_Infinite,TraceEntityFilter,mdlset);
							TR_GetEndPosition(oowchk,hhitpos);
							CloseHandle(hhitpos);
							oowchk[2]+=250.0;
							if (!TR_PointOutsideWorld(oowchk))
							{
								centnextatk[entity] = Time+1.0;
								oowchk[2]-=245.0;
								if (!TR_PointOutsideWorld(oowchk))
									RunSeq(entity,oowchk,toang,"idle","",2,false);
							}
							else
							{
								oowchk[0] = (entpos[0] + (50 * Cosine(DegToRad(toang[1]))));
								oowchk[1] = (entpos[1] + (50 * Sine(DegToRad(toang[1]))));
								oowchk[2] = entpos[2]+10.0;
								if (!TR_PointOutsideWorld(oowchk))
								{
									hhitpos = TR_TraceRayFilterEx(oowchk, aimdown, MASK_SHOT, RayType_Infinite, TraceEntityFilterPly, mdlset);
									TR_GetEndPosition(oowchk,hhitpos);
									CloseHandle(hhitpos);
									oowchk[2]+=250.0;
									if (!TR_PointOutsideWorld(oowchk))
									{
										oowchk[2]-=245.0;
										centnextatk[entity] = Time+1.0;
										if (!TR_PointOutsideWorld(oowchk))
											RunSeq(entity,oowchk,toang,"idle","",2,false);
									}
								}
							}
						}
					}
					else
					{
						oowchk[0] = orgs[0];
						oowchk[1] = orgs[1];
						oowchk[2] = orgs[2] + 250.0;
						if (!TR_PointOutsideWorld(oowchk))
						{
							Handle hhitpos = TR_TraceRayFilterEx(oowchk, aimdown, MASK_SHOT, RayType_Infinite, TraceEntityFilterPly, entity);
							TR_GetEndPosition(oowchk,hhitpos);
							int hTargetEnt = TR_GetEntityIndex(hhitpos);
							CloseHandle(hhitpos);
							if (hTargetEnt <= 0 && (oowchk[2] > (orgs[2] + 10.0)) && (oowchk[2] < (orgs[2] + 200.0)) && (!TR_PointOutsideWorld(oowchk)))
							{
								TeleportEntity(entity, oowchk, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
				else if ((isattacking[mdlset] == 1) && (!targreset))
				{
					GargStopFire(entity,mdlset,entpos,entangs);
				}
				else
				{
					if (centnextsndtime[entity] < Time)
					{
						char sndidle[64];
						Format(sndidle,sizeof(sndidle),"npc\\garg\\garg_idle%i.wav",GetRandomInt(1,2));
						EmitAmbientSound(sndidle, entpos, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
						centnextsndtime[entity] = Time+3.0;
					}
					if (GetArraySize(entlist) > 0)
					{
						float curorg[3];
						curorg[0] = (entpos[0] + (30 * Cosine(DegToRad(entangs[1]))));
						curorg[1] = (entpos[1] + (30 * Sine(DegToRad(entangs[1]))));
						curorg[2] = (entpos[2] + 250.0);//vMaxs 250
						float fhitpos[3];
						float toang[3];
						float shootvel[3];
						float enorg[3];
						float chkdist = 999.0;
						float topdist = 0.0;
						float dist = 0.0;
						for (int j = 0;j<GetArraySize(entlist);j++)
						{
							int i = GetArrayCell(entlist,j);
							if (IsValidEntity(i))
							{
								char cls[64];
								GetEntityClassname(i,cls,sizeof(cls));
								if ((!StrEqual(cls,"npc_bmsgargantua",false)) && (StrContains(cls,"weapon_",false) == -1) && (StrContains(cls,"item_",false) == -1) && (!StrEqual(cls,"npc_enemyfinder",false)) && (!StrEqual(cls,"npc_gargantua",false)) && (!StrEqual(cls,"npc_bullseye",false)) && (!StrEqual(cls,"npc_maker",false)) && (!StrEqual(cls,"npc_template_maker",false)) && (!StrEqual(cls,"env_xen_portal",false)) && (!StrEqual(cls,"env_xen_portal_template",false)) && (StrContains(cls,"npc_barnacle",false) == -1))
								{
									if (StrEqual(cls,"generic_actor",false))
									{
										if (HasEntProp(i,Prop_Data,"m_hEffectEntity"))
										{
											if (GetEntPropEnt(i,Prop_Data,"m_hEffectEntity") == entity) continue;
										}
									}
									if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",enorg);
									else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",enorg);
									MakeVectorFromPoints(curorg,enorg,shootvel);
									GetVectorAngles(shootvel,toang);
									Handle hhitpos = TR_TraceRayFilterEx(curorg,toang,MASK_SHOT,RayType_Infinite,TraceEntityFilter,entity);
									TR_GetEndPosition(fhitpos,hhitpos);
									int hitent = TR_GetEntityIndex(hhitpos);
									CloseHandle(hhitpos);
									chkdist = GetVectorDistance(fhitpos,enorg,false);
									dist = GetVectorDistance(entpos,enorg,false);
									//PrintToServer("Hit %i aim %i %1.f %1.f %1.f en %1.f %1.f %1.f",hitent,i,fhitpos[0],fhitpos[1],fhitpos[2],enorg[0],enorg[1],enorg[2]);
									if (((chkdist < 200.0) && ((dist < topdist) || (topdist == 0.0))) || (hitent == i))
									{
										topdist = dist;
										isattacking[entity] = i;
										if (dist < 500.0) break;
										//break;
									}
								}
							}
						}
					}
					else
					{
						for (int i = 1;i<MaxClients+1;i++)
						{
							if (IsValidEntity(i))
							{
								if (FindValueInArray(entlist,i) == -1) PushArrayCell(entlist,i);
							}
						}
					}
					if (((isattacking[entity] == 0) || (!IsValidEntity(isattacking[entity]))) && (centnextatk[mdlset] <= Time) && (!targreset))
					{
						//Rand roam
						float roamorg[3];
						float randfl = GetRandomFloat(-160.0,160.0);
						int randdist = GetRandomInt(20,120);
						roamorg[0] = (entpos[0] + (randdist * Cosine(DegToRad(randfl))));
						roamorg[1] = (entpos[1] + (randdist * Sine(DegToRad(randfl))));
						roamorg[2] = (entpos[2] + 250.0);
						if (TR_PointOutsideWorld(roamorg))
						{
							while (TR_PointOutsideWorld(roamorg))
							{
								randfl = GetRandomFloat(-160.0,160.0);
								randdist = GetRandomInt(20,120);
								roamorg[0] = (entpos[0] + (randdist * Cosine(DegToRad(randfl))));
								roamorg[1] = (entpos[1] + (randdist * Sine(DegToRad(randfl))));
								roamorg[2] = (entpos[2] + 10.0);
							}
						}
						roamorg[2] = (entpos[2] + 10.0);
						float toang[3];
						float shootvel[3];
						MakeVectorFromPoints(entpos,roamorg,shootvel);
						GetVectorAngles(shootvel,toang);
						RunSeq(entity,roamorg,toang,"idle","",1,false);
						centnextatk[mdlset] = Time+GetRandomFloat(1.0,3.0);
					}
				}
				targreset = false;
			}
		}
	}
}

void GargStopFire(int entity, int mdlset, float orgs[3], float angs[3])
{
	EmitAmbientSound("npc\\garg\\garg_beam_start.wav", orgs, entity, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
	EmitAmbientSound("npc\\garg\\garg_beam_stop.wav", orgs, entity, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
	for (int i = 0;i<4;i++)
	{
		if ((IsValidEntity(gargfiretarg[entity][i])) && (gargfiretarg[entity][i] != 0))
		{
			AcceptEntityInput(gargfiretarg[entity][i],"kill");
			gargfiretarg[entity][i] = 0;
		}
	}
	isattacking[mdlset] = 0;
	RunSeq(entity, orgs, angs, "idle", "", 0, false);
}

public Action bmsgargtkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	bool AllowDmg = false;
	char dmgcls[32];
	if (IsValidEntity(victim)) GetEntityClassname(victim,dmgcls,sizeof(dmgcls));
	if (IsValidEntity(attacker))
	{
		char atkcls[64];
		GetEntityClassname(attacker,atkcls,sizeof(atkcls));
		if (StrContains(atkcls,"grenade",false) != -1)
		{
			AllowDmg = true;
			if ((attacker > MaxClients) && (attacker == inflictor) && (HasEntProp(attacker,Prop_Data,"m_hEffectEntity")))
			{
				int atkchk = GetEntPropEnt(attacker,Prop_Data,"m_hEffectEntity");
				if ((IsValidEntity(atkchk)) && (atkchk < MaxClients+1)) attacker = atkchk;
			}
		}
	}
	if (StrEqual(dmgcls,"generic_actor",false))
	{
		int dmgvic = GetEntPropEnt(victim,Prop_Data,"m_hEffectEntity");
		if (IsValidEntity(dmgvic))
		{
			float atkorg[3];
			if (IsValidEntity(attacker))
			{
				if (HasEntProp(attacker,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(attacker,Prop_Data,"m_vecAbsOrigin",atkorg);
			}
			int health = GetEntProp(dmgvic,Prop_Data,"m_iHealth");
			if ((health > 0) && ((damagetype == 64) || (AllowDmg)))
			{
				SDKHooks_TakeDamage(dmgvic, attacker, inflictor, damage, damagetype, -1, atkorg, atkorg);
			}
		}
		SetEntProp(victim, Prop_Data, "m_iHealth", GetEntProp(victim, Prop_Data, "m_iMaxHealth"));
		damage = 0.0;
		return Plugin_Changed;
	}
	//PrintToServer("%i tkdmg from %i %i %1.f type %i",victim,attacker,inflictor,damage,damagetype);
	if (IsValidEntity(victim))
	{
		if ((damagetype == 64) || (AllowDmg))
		{
			if ((!IsValidEntity(isattacking[victim])) || (isattacking[victim] == 0))
			{
				isattacking[victim] = attacker;
			}
		}
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		if ((health-damage <= 0) || (health < 1))
		{
			float orgs[3];
			float angs[3];
			if (HasEntProp(victim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(victim,Prop_Data,"m_vecOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecOrigin",orgs);
			if (HasEntProp(victim,Prop_Data,"m_angRotation")) GetEntPropVector(victim,Prop_Data,"m_angRotation",angs);
			EmitAmbientSound("npc\\garg\\garg_beam_start.wav", orgs, victim, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
			EmitAmbientSound("npc\\garg\\garg_beam_stop.wav", orgs, victim, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
			for (int i = 0;i<4;i++)
			{
				if ((IsValidEntity(gargfiretarg[victim][i])) && (gargfiretarg[victim][i] != 0))
				{
					AcceptEntityInput(gargfiretarg[victim][i],"kill");
					gargfiretarg[victim][i] = 0;
				}
			}
			if (HasEntProp(victim, Prop_Data, "m_hTargetEnt"))
			{
				int scrent = GetEntPropEnt(victim, Prop_Data, "m_hTargetEnt");
				if (IsValidEntity(scrent))
				{
					AcceptEntityInput(scrent, "CancelSequence");
				}
			}
			int mdlset = GetEntPropEnt(victim, Prop_Data, "m_hEffectEntity");
			if (IsValidEntity(mdlset))
			{
				isattacking[mdlset] = 5;
				SetEntProp(mdlset, Prop_Data, "m_nRenderFX", 0);
				SetEntProp(mdlset, Prop_Data, "m_nRenderMode", 0);
				//SetEntProp(victim, Prop_Data, "m_nRenderFX", 6);
				AcceptEntityInput(mdlset, "ClearParent");
				SetVariantString("powerup_electrocute");
				AcceptEntityInput(mdlset, "SetAnimation");
				if (HasEntProp(mdlset, Prop_Data, "m_iszDefaultAnim"))
					SetEntPropString(mdlset, Prop_Data, "m_iszDefaultAnim", "powerup_electrocute");
			}
			RunSeq(victim, orgs, angs, "powerup_electrocute", "", 0, false, true);
			CreateTimer(7.2,DissolveGarg, victim, TIMER_FLAG_NO_MAPCHANGE);
			SetEntProp(victim, Prop_Data, "m_iHealth", 5);
			damage = 10.0;
			return Plugin_Changed;
		}
	}
	damage = 0.0;
	return Plugin_Changed;
}

public Action DissolveGarg(Handle timer, int entity)
{
	if ((IsValidEntity(entity)) && (entity != 0))
	{
		AcceptEntityInput(entity,"kill");
	}
}

public Action LaunchTarget(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		float shootvel[3];
		int hitent = ReadPackCell(dp);
		shootvel[0] = ReadPackFloat(dp);
		shootvel[1] = ReadPackFloat(dp);
		shootvel[2] = ReadPackFloat(dp);
		CloseHandle(dp);
		if (IsValidEntity(hitent))
		{
			TeleportEntity(hitent,NULL_VECTOR,NULL_VECTOR,shootvel);
		}
	}
}

public Action GargResetColl(Handle timer, Handle dppass)
{
	if (dppass != INVALID_HANDLE)
	{
		char targn[128];
		char boundbtarg[128];
		ResetPack(dppass);
		ReadPackString(dppass,targn,sizeof(targn));
		ReadPackString(dppass,boundbtarg,sizeof(boundbtarg));
		CloseHandle(dppass);
		int logcoll = CreateEntityByName("logic_collision_pair");
		if (logcoll != -1)
		{
			DispatchKeyValue(logcoll,"attach1",targn);
			DispatchKeyValue(logcoll,"attach2",boundbtarg);
			DispatchKeyValue(logcoll,"StartDisabled","1");
			DispatchSpawn(logcoll);
			ActivateEntity(logcoll);
			AcceptEntityInput(logcoll,"DisableCollisions");
			Handle dp = CreateDataPack();
			WritePackCell(dp,logcoll);
			WritePackString(dp,"logic_collision_pair");
			CreateTimer(0.5,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}