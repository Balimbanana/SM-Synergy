int istargeted[2048];

void tentaclethink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int mdlarr = FindValueInArray(tents,entity);
			if (mdlarr != -1)
			{
				int entmdl = GetArrayCell(tentsmdl,mdlarr);
				if (IsValidEntity(entmdl))
				{
					if (HasEntProp(entmdl,Prop_Data,"m_hParent"))
					{
						int parentchk = GetEntPropEnt(entmdl,Prop_Data,"m_hParent");
						if (parentchk != -1) AcceptEntityInput(entmdl,"ClearParent");
					}
					int seqmdl = GetEntProp(entmdl,Prop_Data,"m_nSequence");
					int seq = isattacking[entmdl];
					int targ = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
					if (!IsValidEntity(targ))
					{
						if ((targ > 0) && (targ < 2048)) istargeted[targ] = 0;
						SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
						targ = -1;
					}
					else if (HasEntProp(targ,Prop_Data,"m_iHealth"))
					{
						if (GetEntProp(targ,Prop_Data,"m_iHealth") < 1)
						{
							istargeted[targ] = 0;
							SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
							targ = -1;
						}
					}
					//bottomfloor += 100.0 floor_idle
					//firstfloor += 292.0 level1_idle
					//secondfloor += 484.0 level2_idle
					//thirdfloor += 675.0 level3_idle
					int mvfloor;
					float origin[3];
					if (HasEntProp(entmdl,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entmdl,Prop_Data,"m_vecAbsOrigin",origin);
					else if (HasEntProp(entmdl,Prop_Send,"m_vecOrigin")) GetEntPropVector(entmdl,Prop_Send,"m_vecOrigin",origin);
					for (int k = 0;k<GetArraySize(grenlist);k++)
					{
						int i = GetArrayCell(grenlist,k);
						if ((IsValidEntity(i)) && (IsEntNetworkable(i)))
						{
							char clschk[24];
							GetEntityClassname(i,clschk,sizeof(clschk));
							if (StrEqual(clschk,"npc_grenade_frag",false))
							{
								float plyorg[3];
								if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorg);
								else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorg);
								if ((seqmdl > 3) && (seqmdl < 11))
								{
									//atfloor0
									origin[2]+=100.0;
									mvfloor = 0;
								}
								else if ((seqmdl > 10) && (seqmdl < 18))
								{
									//atfloor1
									origin[2]+=292.0;
									mvfloor = 1;
								}
								else if ((seqmdl > 17) && (seqmdl < 25))
								{
									//atfloor2
									origin[2]+=484.0;
									mvfloor = 2;
								}
								else if ((seqmdl > 24) && (seqmdl < 32))
								{
									//atfloor3
									origin[2]+=675.0;
									mvfloor = 3;
								}
								float closest;
								int closestt;
								for (int h = 0;h<GetArraySize(tents);h++)
								{
									int j = GetArrayCell(tents,h);
									float atkorg[3];
									if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",atkorg);
									else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",atkorg);
									atkorg[2] = plyorg[2];
									float chkdist = GetVectorDistance(atkorg,plyorg,false);
									if (chkdist < 500.0)
									{
										if ((chkdist < closest) || (closest == 0.0))
										{
											closest = chkdist;
											closestt = j;
										}
									}
								}
								if ((closest != 0.0) && (closestt != 0))
								{
									if (FindValueInArray(tents,istargeted[i]) == -1) istargeted[i] = 0;
									if ((istargeted[i] != 0) && (IsValidEntity(istargeted[i])))
									{
										float atkorg[3];
										if (HasEntProp(istargeted[i],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(istargeted[i],Prop_Data,"m_vecAbsOrigin",atkorg);
										else if (HasEntProp(istargeted[i],Prop_Send,"m_vecOrigin")) GetEntPropVector(istargeted[i],Prop_Send,"m_vecOrigin",atkorg);
										atkorg[2] = plyorg[2];
										float chkdist = GetVectorDistance(origin,atkorg,false);
										chkdist+=10.0;
										if (chkdist < closest)
										{
											SetEntPropEnt(istargeted[i],Prop_Data,"m_hTargetEnt",-1);
											istargeted[i] = 0;
										}
									}
									if (istargeted[i] == 0)
									{
										SetEntPropEnt(closestt,Prop_Data,"m_hTargetEnt",i);
										istargeted[i] = closestt;
										break;
									}
								}
							}
						}
					}
					int neartents = 1;
					float curang[3];
					float entorg[3];
					GetEntPropVector(entity,Prop_Data,"m_angRotation",curang);
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",entorg);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",entorg);
					for (int l = 0;l<GetArraySize(tents);l++)
					{
						int j = GetArrayCell(tents,l);
						if (j != entity)
						{
							float orgtmp[3];
							if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",orgtmp);
							else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",orgtmp);
							orgtmp[2] = entorg[2];
							if (GetVectorDistance(orgtmp,entorg,false) < 250.0)
							{
								neartents++;
							}
						}
					}
					if (!IsValidEntity(targ))
					{
						for (int k = 0;k<GetArraySize(entlist);k++)
						{
							int i = GetArrayCell(entlist,k);
							if ((IsValidEntity(i)) && (IsEntNetworkable(i)))
							{
								char clschk[24];
								GetEntityClassname(i,clschk,sizeof(clschk));
								if ((!StrEqual(clschk,"npc_tentacle",false)) && ((StrContains(clschk,"npc_human",false) == 0) || (StrContains(clschk,"npc_alien",false) == 0)) || (StrEqual(clschk,"player",false)))
								{
									float plyorg[3];
									if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",plyorg);
									else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",plyorg);
									bool withinradius = true;
									//Radius = (360/neartents)-10 = +/- radius
									if (neartents > 0)
									{
										float shootvel[3];
										float toang[3];
										MakeVectorFromPoints(entorg,plyorg,shootvel);
										GetVectorAngles(shootvel,toang);
										float maxradius = (360.0/neartents);
										float negradius = maxradius-360.0;
										if (curang[1] > toang[1])
										{
											if ((curang[1]-toang[1] > 0) && (curang[1]-toang[1] < maxradius)) withinradius = true;
											else if ((toang[1]-curang[1] < -1) && (toang[1]-curang[1] < negradius)) withinradius = true;
											else withinradius = false;
										}
										else if (toang[1] > curang[1])
										{
											if ((toang[1]-curang[1] > 0) && (toang[1]-curang[1] < maxradius)) withinradius = true;
											else if ((curang[1]-toang[1] < -1) && (curang[1]-toang[1] < negradius)) withinradius = true;
											else withinradius = false;
										}
									}
									if (withinradius)
									{
										if ((seqmdl > 3) && (seqmdl < 11))
										{
											//atfloor0
											origin[2]+=100.0;
											mvfloor = 0;
										}
										else if ((seqmdl > 10) && (seqmdl < 18))
										{
											//atfloor1
											origin[2]+=292.0;
											mvfloor = 1;
										}
										else if ((seqmdl > 17) && (seqmdl < 25))
										{
											//atfloor2
											origin[2]+=484.0;
											mvfloor = 2;
										}
										else if ((seqmdl > 24) && (seqmdl < 32))
										{
											//atfloor3
											origin[2]+=675.0;
											mvfloor = 3;
										}
										float closest;
										int closestt;
										for (int h = 0;h<GetArraySize(tents);h++)
										{
											int j = GetArrayCell(tents,h);
											float atkorg[3];
											if (HasEntProp(j,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(j,Prop_Data,"m_vecAbsOrigin",atkorg);
											else if (HasEntProp(j,Prop_Send,"m_vecOrigin")) GetEntPropVector(j,Prop_Send,"m_vecOrigin",atkorg);
											atkorg[2] = plyorg[2];
											float chkdist = GetVectorDistance(atkorg,plyorg,false);
											float maxdist;
											if (i < MaxClients+1) maxdist = 480.0;
											else maxdist = 400.0;
											if (chkdist < maxdist)
											{
												if ((chkdist < closest) || (closest == 0.0))
												{
													closest = chkdist;
													closestt = j;
												}
											}
										}
										if ((closest != 0.0) && (closestt != 0))
										{
											if (FindValueInArray(tents,istargeted[i]) == -1) istargeted[i] = 0;
											if ((istargeted[i] != 0) && (IsValidEntity(istargeted[i])))
											{
												float atkorg[3];
												if (HasEntProp(istargeted[i],Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(istargeted[i],Prop_Data,"m_vecAbsOrigin",atkorg);
												else if (HasEntProp(istargeted[i],Prop_Send,"m_vecOrigin")) GetEntPropVector(istargeted[i],Prop_Send,"m_vecOrigin",atkorg);
												atkorg[2] = origin[2];
												float chkdist = GetVectorDistance(origin,atkorg,false);
												chkdist+=10.0;
												if (chkdist < closest)
												{
													SetEntPropEnt(closestt,Prop_Data,"m_hTargetEnt",-1);
													istargeted[i] = 0;
												}
											}
											if (istargeted[i] == 0)
											{
												SetEntPropEnt(closestt,Prop_Data,"m_hTargetEnt",i);
												istargeted[i] = closestt;
											}
										}
									}
								}
							}
						}
					}
					float Time = GetTickedTime();
					int sndtarg = GetArrayCell(tentssnd,mdlarr);
					//Attachments Tip Eye
					if (centnextatk[entity] < Time)
					{
						if (targ != -1)
							if (istargeted[targ] != entity) targ = -1;
						if (targ == -1)
						{
							if (IsValidEntity(sndtarg))
							{
								char snd[64];
								int rand = GetRandomInt(1,10);
								Format(snd,sizeof(snd),"npc\\tentacle\\tent_sing_close%i.wav",rand);
								EmitSoundToAll(snd,sndtarg,SNDCHAN_AUTO,SNDLEVEL_DISHWASHER);
								centnextatk[entity] = Time+4.0;
							}
							float tiporg[3];
							if (HasEntProp(sndtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(sndtarg,Prop_Data,"m_vecAbsOrigin",tiporg);
							else if (HasEntProp(sndtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(sndtarg,Prop_Send,"m_vecOrigin",tiporg);
							float lowestdist;
							int clpass;
							for (int i = 1;i<MaxClients+1;i++)
							{
								if ((IsValidEntity(i)) && (IsClientInGame(i)))
								{
									float plyorg[3];
									GetClientAbsOrigin(i,plyorg);
									float chkdist = GetVectorDistance(tiporg,plyorg,false);
									if (((chkdist < lowestdist) || (lowestdist == 0.0)) && (istargeted[clpass] != 0))
									{
										lowestdist = chkdist;
										clpass = i;
									}
								}
							}
							if ((lowestdist < 600.0) && (lowestdist != 0.0))
							{
								SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",clpass);
								istargeted[clpass] = 0;
								SetEntProp(entity,Prop_Data,"m_nSequence",seq);
							}
						}
						if ((IsValidEntity(targ)) && (targ != 0))
						{
							origin[0] = 0.0;
							origin[1] = 0.0;
							origin[2] = 0.0;
							if (HasEntProp(entmdl,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entmdl,Prop_Data,"m_vecAbsOrigin",origin);
							else if (HasEntProp(entmdl,Prop_Send,"m_vecOrigin")) GetEntPropVector(entmdl,Prop_Send,"m_vecOrigin",origin);
							if ((seqmdl > 3) && (seqmdl < 11))
							{
								//atfloor0
								origin[2]+=100.0;
								mvfloor = 0;
							}
							else if ((seqmdl > 10) && (seqmdl < 18))
							{
								//atfloor1
								origin[2]+=292.0;
								mvfloor = 1;
							}
							else if ((seqmdl > 17) && (seqmdl < 25))
							{
								//atfloor2
								origin[2]+=484.0;
								mvfloor = 2;
							}
							else if ((seqmdl > 24) && (seqmdl < 32))
							{
								//atfloor3
								origin[2]+=675.0;
								mvfloor = 3;
							}
							float plyorg[3];
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",plyorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",plyorg);
							float chkorg[3];
							chkorg[0] = origin[0];
							chkorg[1] = origin[1];
							chkorg[2] = plyorg[2];
							float chkdist = GetVectorDistance(chkorg,plyorg,false);
							float shootvel[3];
							float toang[3];
							MakeVectorFromPoints(chkorg,plyorg,shootvel);
							GetVectorAngles(shootvel,toang);
							TR_TraceRayFilter(chkorg,toang,MASK_SHOT_HULL,RayType_Infinite,TraceEntityFilter,entmdl);
							int trtarg = TR_GetEntityIndex();
							if ((chkdist > 500.0) || (trtarg < 1))
							{
								SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
								if (istargeted[targ] == entity) istargeted[targ] = 0;
								targ = -1;
							}
							else if (origin[2] > plyorg[2])
							{
								if (origin[2]-plyorg[2] > 110.0)
								{
									if (mvfloor == 3)
									{
										seq = GetRandomInt(18,21);
									}
									else if (mvfloor == 2)
									{
										seq = GetRandomInt(11,14);
									}
									else if (mvfloor == 1)
									{
										seq = GetRandomInt(4,7);
									}
									char snd[64];
									int rand = GetRandomInt(1,4);
									Format(snd,sizeof(snd),"npc\\tentacle\\tent_move%i.wav",rand);
									EmitSoundToAll(snd,sndtarg,SNDCHAN_AUTO,SNDLEVEL_DISHWASHER);
									isattacking[entmdl] = seq;
								}
							}
							else if (origin[2] < plyorg[2])
							{
								if (plyorg[2]-origin[2] > 110.0)
								{
									if (mvfloor == 2)
									{
										seq = GetRandomInt(25,28);
									}
									else if (mvfloor == 1)
									{
										seq = GetRandomInt(18,21);
									}
									else if (mvfloor == 0)
									{
										seq = GetRandomInt(11,14);
									}
									isattacking[entmdl] = seq;
								}
							}
							centnextatk[entity] = Time+2.0;
						}
					}
					/*
					float cyclechk = GetEntPropFloat(entmdl,Prop_Data,"m_flCycle");
					if (cyclechk == centlasttouch[entmdl])
					{
						float plyorg[3];
						if (IsValidEntity(targ))
						{
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",plyorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",plyorg);
						}
						if (origin[2] > plyorg[2])
						{
							if (origin[2]-plyorg[2] > 120.0)
							{
								if (mvfloor == 3)
								{
									seq = GetRandomInt(18,21);
								}
								else if (mvfloor == 2)
								{
									seq = GetRandomInt(11,14);
								}
								else if (mvfloor == 1)
								{
									seq = GetRandomInt(4,7);
								}
								if (seq != 0)
									isattacking[entmdl] = seq;
							}
						}
						else if (origin[2] < plyorg[2])
						{
							if (plyorg[2]-origin[2] > 120.0)
							{
								if (mvfloor == 2)
								{
									seq = GetRandomInt(25,28);
								}
								else if (mvfloor == 1)
								{
									seq = GetRandomInt(18,21);
								}
								else if (mvfloor == 0)
								{
									seq = GetRandomInt(11,14);
								}
								if (seq != 0)
									isattacking[entmdl] = seq;
							}
						}
						SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
						cyclechk+=0.02;
						if (cyclechk > 1.0) cyclechk = 0.0;
						SetEntPropFloat(entmdl,Prop_Data,"m_flCycle",cyclechk);
						int animset = GetEntProp(entmdl,Prop_Data,"m_bClientSideAnimation");
						if (animset == 0) SetEntProp(entmdl,Prop_Data,"m_bClientSideAnimation",0);
						else if (timesattacked[entity] > 1)
						{
							SetEntProp(entmdl,Prop_Data,"m_bClientSideAnimation",1);
							timesattacked[entity] = 0;
						}
						timesattacked[entity]++;
						ChangeEdictState(entmdl);
						targ = -1;
					}
					centlasttouch[entmdl] = cyclechk;
					*/
					if ((seqmdl != seq) && (seq != 0))
					{
						bool contseqset = true;
						if (IsValidEntity(targ))
						{
							if (centnextatk[targ] > Time)
								contseqset = false;
						}
						if (contseqset)
						{
							char atkanim[32];
							switch(seq)
							{
								case 1:
								{
									SetVariantString("gesture_level1_idle_blend");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 2:
								{
									SetVariantString("gesture_level2_idle_blend");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 3:
								{
									SetVariantString("gesture_level3_idle_blend");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 4:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle");
								}
								case 5:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle2");
								}
								case 6:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle3");
								}
								case 7:
								{
									Format(atkanim,sizeof(atkanim),"floor_idle4");
								}
								case 8:
								{
									SetVariantString("floor_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 9:
								{
									SetVariantString("floor_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 10:
								{
									SetVariantString("floor_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 11:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle");
								}
								case 12:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle2");
								}
								case 13:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle3");
								}
								case 14:
								{
									Format(atkanim,sizeof(atkanim),"level1_idle4");
								}
								case 15:
								{
									SetVariantString("level1_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 16:
								{
									SetVariantString("level1_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 17:
								{
									SetVariantString("level1_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 18:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle");
								}
								case 19:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle2");
								}
								case 20:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle3");
								}
								case 21:
								{
									Format(atkanim,sizeof(atkanim),"level2_idle4");
								}
								case 22:
								{
									SetVariantString("level2_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 23:
								{
									SetVariantString("level2_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 24:
								{
									SetVariantString("level2_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 25:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle");
								}
								case 26:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle2");
								}
								case 27:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle3");
								}
								case 28:
								{
									Format(atkanim,sizeof(atkanim),"level3_idle4");
								}
								case 29:
								{
									SetVariantString("level3_strike1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 30:
								{
									SetVariantString("level3_strike2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 31:
								{
									SetVariantString("level3_strike3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 32:
								{
									Format(atkanim,sizeof(atkanim),"floor_to_level1");
								}
								case 33:
								{
									Format(atkanim,sizeof(atkanim),"level1_to_floor");
									
								}
								case 34:
								{
									Format(atkanim,sizeof(atkanim),"level1_to_level2");
								}
								case 35:
								{
									Format(atkanim,sizeof(atkanim),"level2_to_level1");
								}
								case 36:
								{
									Format(atkanim,sizeof(atkanim),"level0_to_level2");
								}
								case 37:
								{
									Format(atkanim,sizeof(atkanim),"level2_to_level0");
								}
								case 38:
								{
									Format(atkanim,sizeof(atkanim),"level2_to_level3");
								}
								case 39:
								{
									Format(atkanim,sizeof(atkanim),"level3_to_level2");
								}
								case 40:
								{
									Format(atkanim,sizeof(atkanim),"floor_to_level3");
								}
								case 41:
								{
									Format(atkanim,sizeof(atkanim),"level3_to_floor");
								}
								case 42:
								{
									Format(atkanim,sizeof(atkanim),"level1_to_level3");
								}
								case 43:
								{
									Format(atkanim,sizeof(atkanim),"level3_to_level1");
								}
								case 44:
								{
									Format(atkanim,sizeof(atkanim),"level3_idlerear");
								}
								case 45:
								{
									Format(atkanim,sizeof(atkanim),"level2_idlerear");
								}
								case 46:
								{
									Format(atkanim,sizeof(atkanim),"level1_idlerear");
								}
								case 47:
								{
									Format(atkanim,sizeof(atkanim),"floor_idlerear");
								}
								case 48:
								{
									SetVariantString("floor_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 49:
								{
									SetVariantString("level1_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 50:
								{
									SetVariantString("level2_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 51:
								{
									SetVariantString("level3_tap");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 52:
								{
									SetVariantString("tentacle_controlroom_smash");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 53:
								{
									SetVariantString("gesture_rotateright");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 54:
								{
									SetVariantString("gesture_rotateleft");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 55:
								{
									SetVariantString("death1");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 56:
								{
									SetVariantString("death2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 57:
								{
									SetVariantString("death3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
							}
							if (strlen(atkanim) > 4)
							{
								SetVariantString(atkanim);
								AcceptEntityInput(entmdl,"SetAnimation");
								//SetVariantString(atkanim);
								//AcceptEntityInput(entmdl,"SetDefaultAnimation");
								seqmdl = GetEntProp(entmdl,Prop_Data,"m_nSequence");
								//SetEntProp(entity,Prop_Data,"m_nSequence",seqmdl);
							}
							//SetEntProp(entmdl,Prop_Data,"m_nSequence",seq);
							isattacking[entmdl] = seq;
						}
					}
					if ((IsValidEntity(targ)) && (targ != 0) && (IsValidEntity(sndtarg)))
					{
						float enorg[3];
						float tiporg[3];
						if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
						if (HasEntProp(sndtarg,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(sndtarg,Prop_Data,"m_vecAbsOrigin",tiporg);
						else if (HasEntProp(sndtarg,Prop_Send,"m_vecOrigin")) GetEntPropVector(sndtarg,Prop_Send,"m_vecOrigin",tiporg);
						//if ((tiporg[2]-enorg[2] < 200.0) && (enorg[2]-tiporg[2] < 200.0))
						//{
						float toang[3];
						float angs[3];
						if (HasEntProp(entmdl,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entmdl,Prop_Data,"m_angAbsRotation",angs);
						if (centlastposchk[entmdl] < Time)
						{
							float loc[3];
							loc[0] = (tiporg[0] + (60 * Cosine(DegToRad(angs[1]))));
							loc[1] = (tiporg[1] + (60 * Sine(DegToRad(angs[1]))));
							loc[2] = (tiporg[2] - 25);
							float shootvel[3];
							MakeVectorFromPoints(loc,enorg,shootvel);
							GetVectorAngles(shootvel,toang);
							centlastang[entmdl] = toang[1];
							centlastposchk[entmdl] = Time+2.0;
						}
						else
						{
							toang[1] = centlastang[entmdl];
						}
						bool withinradius = true;
						//Radius = (360/neartents)-10 = +/- radius
						if (neartents > 0)
						{
							float maxradius = (360.0/neartents);
							float negradius = maxradius-360.0;
							if (curang[1] > toang[1])
							{
								if ((curang[1]-toang[1] > 0) && (curang[1]-toang[1] < maxradius)) withinradius = true;
								else if ((toang[1]-curang[1] < -1) && (toang[1]-curang[1] < negradius)) withinradius = true;
								else withinradius = false;
							}
							else if (toang[1] > curang[1])
							{
								if ((toang[1]-curang[1] > 0) && (toang[1]-curang[1] < maxradius)) withinradius = true;
								else if ((curang[1]-toang[1] < -1) && (curang[1]-toang[1] < negradius)) withinradius = true;
								else withinradius = false;
							}
						}
						if (angs[1] > toang[1])
						{
							if (angs[1]-toang[1] > 180) angs[1]+=2.5;
							else if (toang[1]-angs[1] < -180) angs[1]+=2.5;
							else angs[1]-=2.5;
						}
						else if (toang[1] > angs[1])
						{
							if (toang[1]-angs[1] > 180) angs[1]-=2.5;
							else if (angs[1]-toang[1] < -180) angs[1]-=2.5;
							else angs[1]+=2.5;
						}
						if (angs[1] < 0.0) angs[1]+=360.0;
						if (angs[1] > 360) angs[1]-=360.0;
						if (withinradius)
						{
							TeleportEntity(entmdl,NULL_VECTOR,angs,NULL_VECTOR);
							
							if (centnextatk[targ] < Time)
							{
								float chkdist = GetVectorDistance(tiporg,enorg,false);
								if ((chkdist < 250.0) && (tiporg[2] > enorg[2]))
								{
									centnextatk[targ] = Time+0.7;
									char atk[64];
									int randatk = GetRandomInt(1,3);
									if ((seqmdl > 3) && (seqmdl < 11))
									{
										//atfloor0
										Format(atk,sizeof(atk),"floor_strike%i",randatk);
									}
									else if ((seqmdl > 10) && (seqmdl < 18))
									{
										//atfloor1
										Format(atk,sizeof(atk),"level1_strike%i",randatk);
									}
									else if ((seqmdl > 17) && (seqmdl < 25))
									{
										//atfloor2
										Format(atk,sizeof(atk),"level2_strike%i",randatk);
									}
									else if ((seqmdl > 24) && (seqmdl < 32))
									{
										//atfloor3
										Format(atk,sizeof(atk),"level3_strike%i",randatk);
									}
									if (strlen(atk) > 4)
									{
										SetVariantString(atk);
										AcceptEntityInput(entmdl,"SetAnimation");
										//seq = GetEntProp(entmdl,Prop_Data,"m_nSequence");
										isattacking[entmdl] = seqmdl;
										SetEntProp(entity,Prop_Data,"m_nSequence",seqmdl);
										CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
									}
								}
								else
								{
									float lowestdist;
									int clpass;
									for (int i = 1;i<MaxClients+1;i++)
									{
										if ((IsValidEntity(i)) && (IsClientInGame(i)))
										{
											float plyorg[3];
											GetClientAbsOrigin(i,plyorg);
											chkdist = GetVectorDistance(tiporg,plyorg,false);
											if ((chkdist < lowestdist) || (lowestdist == 0.0))
											{
												lowestdist = chkdist;
												clpass = i;
											}
										}
									}
									if ((lowestdist < 200.0) && (lowestdist != 0.0))
									{
										centnextatk[clpass] = Time+0.7;
										char atk[64];
										int randatk = GetRandomInt(1,3);
										if ((seqmdl > 3) && (seqmdl < 11))
										{
											//atfloor0
											Format(atk,sizeof(atk),"floor_strike%i",randatk);
										}
										else if ((seqmdl > 10) && (seqmdl < 18))
										{
											//atfloor1
											Format(atk,sizeof(atk),"level1_strike%i",randatk);
										}
										else if ((seqmdl > 17) && (seqmdl < 25))
										{
											//atfloor2
											Format(atk,sizeof(atk),"level2_strike%i",randatk);
										}
										else if ((seqmdl > 24) && (seqmdl < 32))
										{
											//atfloor3
											Format(atk,sizeof(atk),"level3_strike%i",randatk);
										}
										if (strlen(atk) > 1)
										{
											SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",clpass);
											SetVariantString(atk);
											AcceptEntityInput(entmdl,"SetAnimation");
											//seq = GetEntProp(entmdl,Prop_Data,"m_nSequence");
											isattacking[entmdl] = seqmdl;
											isattacking[clpass] = 0;
											SetEntProp(entity,Prop_Data,"m_nSequence",seqmdl);
											CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
										}
									}
								}
							}
						}
						else
						{
							if ((targ > 0) && (targ < 2048)) istargeted[targ] = 0;
							SetEntPropEnt(entity,Prop_Data,"m_hTargetEnt",-1);
							targ = -1;
						}
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
					//SetEntityRenderMode(entity,RENDER_NONE);
					//SetEntityRenderMode(entmdl,RENDER_NORMAL);
				}
			}
		}
	}
}

public Action tentacletkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			if ((attacker < MaxClients+1) && (attacker > 0))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}