void ospreythink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_iHealth"))
		{
			if (GetEntProp(entity,Prop_Data,"m_iHealth") > 0)
			{
				if (HasEntProp(entity,Prop_Data,"m_flPoseParameter"))
				{
					if (HasEntProp(entity,Prop_Data,"m_MoveType"))
					{
						int mvtype = GetEntProp(entity,Prop_Data,"m_MoveType");
						if (mvtype != 0) SetEntProp(entity,Prop_Data,"m_MoveType",0);
					}
					int animprop = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
					if ((animprop != 0) && (IsValidEntity(animprop)) && (!isattacking[entity]))
					{
						float Time = GetTickedTime();
						int soundent = GetEntPropEnt(animprop,Prop_Data,"m_hEffectEntity");
						if ((soundent != 0) && (IsValidEntity(soundent)))
						{
							if (centnextsndtime[soundent] < Time)
							{
								AcceptEntityInput(soundent,"PlaySound");
								centnextsndtime[soundent] = Time+20.5;
							}
						}
						else if ((soundent == 0) || (!IsValidEntity(soundent)))
						{
							soundent = CreateEntityByName("ambient_generic");
							if (soundent != -1)
							{
								char proptargn[64];
								GetEntPropString(animprop,Prop_Data,"m_iName",proptargn,sizeof(proptargn));
								if (strlen(proptargn) < 1)
								{
									Format(proptargn,sizeof(proptargn),"ospreyprop%i",animprop);
									SetEntPropString(animprop,Prop_Data,"m_iName",proptargn);
								}
								DispatchKeyValue(soundent,"message","npc/osprey/osprey_hover.wav");
								DispatchKeyValue(soundent,"spawnflags","32");
								DispatchKeyValue(soundent,"health","10");
								DispatchKeyValue(soundent,"SourceEntityName",proptargn);
								DispatchSpawn(soundent);
								ActivateEntity(soundent);
								SetEntPropEnt(animprop,Prop_Data,"m_hEffectEntity",soundent);
							}
						}
						//float rotorlang = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",5);
						//float rotorrang = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",6);
						//Get by current speed
						float landgear = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",9);
						if (landgear < 1.0) SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",1.0,9);
						//BeginRappellingGrunts PData Str NPCTemplate# - pose 8 back door - pose 7 passenger door
						//Spawn templates with "waitingtorappel 1" and fire BeginRappel
						int animset = GetEntProp(entity,Prop_Data,"m_bClientSideAnimation");
						if (animset == 1) SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",0);
						else if (timesattacked[animprop] > 1)
						{
							SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",1);
							timesattacked[animprop] = 0;
						}
						timesattacked[animprop]++;
						ChangeEdictState(entity);
					}
					else if ((animprop != 0) && (IsValidEntity(animprop)) && (isattacking[entity]))
					{
						float Time = GetTickedTime();
						int soundent = GetEntPropEnt(animprop,Prop_Data,"m_hEffectEntity");
						if ((soundent != 0) && (IsValidEntity(soundent)))
						{
							if (centnextsndtime[soundent] < Time)
							{
								AcceptEntityInput(soundent,"PlaySound");
								centnextsndtime[soundent] = Time+20.5;
							}
						}
						int parenttrain = GetEntPropEnt(entity,Prop_Data,"m_hParent");
						if ((parenttrain != 0) && (IsValidEntity(parenttrain)))
						{
							AcceptEntityInput(parenttrain,"Stop");
							if ((timesattacked[entity] < 6) && (centnextatk[entity] < Time))
							{
								float backdoor = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",8);
								if ((backdoor < 0.99) && (backdoor+0.05 < 1.0)) SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",backdoor+0.05,8);
								else SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",0.99,8);
								if (backdoor == 0.99)
								{
									//BeginRappellingGrunts PData Str NPCTemplate# - pose 8 back door - pose 7 passenger door
									//Spawn templates with "waitingtorappel 1" and fire BeginRappel
									float backdoorpos[3];
									float angs[3];
									int attachfind = CreateEntityByName("prop_dynamic_override");
									if (attachfind != -1)
									{
										DispatchKeyValue(attachfind,"rendermode","10");
										DispatchKeyValue(attachfind,"targetname","rappelfrom");
										DispatchKeyValue(attachfind,"solid","0");
										DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
										DispatchSpawn(attachfind);
										ActivateEntity(attachfind);
										if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
										if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",backdoorpos);
										else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",backdoorpos);
										if (isattacking[animprop] >= 1)
										{
											angs[1]-=10.0;
											isattacking[animprop] = 0;
										}
										else
										{
											angs[1]+=10.0;
											isattacking[animprop]++;
										}
										backdoorpos[0] = (backdoorpos[0] - (190 * Cosine(DegToRad(angs[1]))));
										backdoorpos[1] = (backdoorpos[1] - (190 * Sine(DegToRad(angs[1]))));
										backdoorpos[2] = (backdoorpos[2] - 160);
										angs[0] = 0.0;
										angs[2] = 0.0;
										TeleportEntity(attachfind,backdoorpos,angs,NULL_VECTOR);
									}
									//asfasf
									//attachments center - side
									//Find target pos angs clear parent timesattacked = templatenum
									//Make sure clear spawn pos on all spawned parent tp ent to mdl pos/angs continue flying
									//m_sNPCTemplate[0] to [5]
									int templent = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
									if (IsValidEntity(templent))
									{
										char tmplspawn[64];
										Format(tmplspawn,sizeof(tmplspawn),"m_iszTemplateEntityNames[%i]",timesattacked[entity]);
										if (HasEntProp(templent,Prop_Data,tmplspawn))
										{
											char templatename[128];
											GetEntPropString(templent,Prop_Data,tmplspawn,templatename,sizeof(templatename));
											if ((strlen(templatename) > 0) && (GetArraySize(templatetargs) > 0))
											{
												int find = FindStringInArray(templatetargs,templatename);
												if (find != -1)
												{
													if (debuglvl >= 2) PrintToServer("osprey spawn custom ent %s",templatename);
													int logcoll = CreateEntityByName("logic_collision_pair");
													if (logcoll != -1)
													{
														char proptargn[64];
														GetEntPropString(animprop,Prop_Data,"m_iName",proptargn,sizeof(proptargn));
														if (strlen(proptargn) < 1)
														{
															Format(proptargn,sizeof(proptargn),"ospreyprop%i",animprop);
															SetEntPropString(animprop,Prop_Data,"m_iName",proptargn);
														}
														DispatchKeyValue(logcoll,"attach1",proptargn);
														DispatchKeyValue(logcoll,"attach2",templatename);
														DispatchKeyValue(logcoll,"StartDisabled","1");
														DispatchSpawn(logcoll);
														ActivateEntity(logcoll);
														AcceptEntityInput(logcoll,"DisableCollisions");
														Handle dp2 = CreateDataPack();
														WritePackCell(dp2,logcoll);
														WritePackString(dp2,"logic_collision_pair");
														CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
													}
													Handle dp = GetArrayCell(templateents,find);
													restoreentarr(dp,attachfind,true);
												}
											}
										}
										timesattacked[entity]++;
										centnextatk[entity] = Time + 0.5;
									}
									Handle dp2 = CreateDataPack();
									WritePackCell(dp2,attachfind);
									WritePackString(dp2,"prop_dynamic");
									CreateTimer(0.5,cleanup,dp2,TIMER_FLAG_NO_MAPCHANGE);
								}
							}
							else
							{
								//Need to fire finish dropoff
								float backdoor = GetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",8);
								if (backdoor-0.01 > 0.0) SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",backdoor-0.01,8);
								else SetEntPropFloat(entity,Prop_Data,"m_flPoseParameter",0.0,8);
								if (backdoor == 0.0)
								{
									AcceptEntityInput(parenttrain,"StartForward");
									isattacking[entity] = false;
									timesattacked[entity] = 0;
								}
							}
							int animset = GetEntProp(entity,Prop_Data,"m_bClientSideAnimation");
							if (animset == 0) SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",1);
							else if (timesattacked[animprop] > 0)
							{
								SetEntProp(entity,Prop_Data,"m_bClientSideAnimation",0);
								timesattacked[animprop] = 0;
							}
							timesattacked[animprop]++;
							ChangeEdictState(entity);
						}
					}
				}
			}
		}
	}
}