void ichythink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int scripting = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
			if ((!IsValidEntity(scripting)) || (scripting == 0))
			{
				int curh = GetEntProp(entity,Prop_Data,"m_iHealth");
				if (curh < 1)
				{
					int ichyprop = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
					if ((IsValidEntity(ichyprop)) && (ichyprop != 0))
						AcceptEntityInput(ichyprop,"Kill");
					SetEntProp(entity,Prop_Data,"m_MoveType",3);
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					SetEntProp(entity,Prop_Data,"m_nRenderMode",0);
					isattacking[entity] = 0;
				}
				else
				{
					int spawnflags = GetEntProp(entity,Prop_Data,"m_spawnflags");
					float Time = GetTickedTime();
					int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
					int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
					float curorg[3];
					float angs[3];
					char cls[24];
					GetEntityClassname(entity,cls,sizeof(cls));
					if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
					if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
					else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
					if ((!IsValidEntity(isattacking[entity])) || (isattacking[entity] == 0))
					{
						SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
						int prop = CreateEntityByName("prop_dynamic");
						if (prop != -1)
						{
							//Massive hitbox in certain directions makes this unusable
							//if ((StrContains(mapbuf,"bm_c",false) != -1) && (FileExists("models/xenians/ichthyosaur.mdl",true,NULL_STRING)))
							//{
							//	if (!IsModelPrecached("models/xenians/ichthyosaur.mdl")) PrecacheModel("models/xenians/ichthyosaur.mdl",true);
							//	DispatchKeyValue(prop,"model","models/xenians/ichthyosaur.mdl");
							//	SetEntityModel(entity,"models/xenians/ichthyosaur.mdl");
							//}
							if ((FileExists("models/icky.mdl",true,NULL_STRING)) && (StrEqual(cls,"monster_ichthyosaur",false)))
							{
								DispatchKeyValue(prop,"model","models/icky.mdl");
								if (!IsModelPrecached("models/icky.mdl")) PrecacheModel("models/icky.mdl",true);
								SetEntityModel(entity,"models/icky.mdl");
								float vmins[3];
								float vmaxs[3];
								vmins[0] = -38.0;
								vmins[1] = -38.0;
								vmins[2] = -38.0;
								vmaxs[0] = 38.0;
								vmaxs[1] = 38.0;
								vmaxs[2] = 38.0;
								SetEntPropVector(entity,Prop_Data,"m_vecMins",vmins);
								SetEntPropVector(entity,Prop_Data,"m_vecMaxs",vmaxs);
							}
							else DispatchKeyValue(prop,"model","models/ichthyosaur.mdl");
							if (FindStringInArray(precachedarr,"npc_ichthyosaur") == -1)
							{
								PrecacheSound("npc\\ichthyosaur\\water_breath.wav",true);
								PrecacheSound("npc\\ichthyosaur\\watermove1.wav",true);
								PrecacheSound("npc\\ichthyosaur\\watermove2.wav",true);
								PrecacheSound("npc\\ichthyosaur\\watermove3.wav",true);
								PrecacheSound("npc\\ichthyosaur\\underwatermove1.wav",true);
								PrecacheSound("npc\\ichthyosaur\\underwatermove2.wav",true);
								PrecacheSound("npc\\ichthyosaur\\underwatermove3.wav",true);
								PrecacheSound("npc\\ichthyosaur\\die1.wav",true);
								recursion("sound/ichy/");
								PushArrayString(precachedarr,"npc_ichthyosaur");
							}
							DispatchKeyValue(prop,"solid","0");
							DispatchKeyValue(prop,"DefaultAnim","swim");
							TeleportEntity(prop,curorg,angs,NULL_VECTOR);
							DispatchSpawn(prop);
							ActivateEntity(prop);
							isattacking[entity] = prop;
							SetVariantString("!activator");
							AcceptEntityInput(prop,"SetParent",entity);
							SetEntityMoveType(entity,MOVETYPE_FLYGRAVITY);
							SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",prop);
						}
					}
					int propseq = GetEntProp(isattacking[entity],Prop_Data,"m_nSequence");
					if ((propseq != seq) && (seq != 0))
					{
						SetEntProp(isattacking[entity],Prop_Data,"m_nSequence",seq);
					}
					else if ((seq == 0) && (propseq != 1))
					{
						SetVariantString("swim");
						AcceptEntityInput(isattacking[entity],"SetAnimation");
					}
					if (IsValidEntity(targ))
					{
						if (HasEntProp(targ,Prop_Data,"m_nWaterLevel"))
						{
							int waterlv = GetEntProp(targ,Prop_Data,"m_nWaterLevel");
							if (spawnflags & 1<<15) waterlv = 3;
							if (waterlv == 0)
							{
								targ = -1;
								SetEntPropEnt(entity,Prop_Data,"m_hEnemy",-1);
							}
						}
					}
					if ((IsValidEntity(targ)) && (targ != 0))
					{
						float enorg[3];
						if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
						float shootvel[3];
						MakeVectorFromPoints(curorg,enorg,shootvel);
						if (shootvel[2] < 0.0) shootvel[2]+=0.5;
						else shootvel[2]-=0.5;
						//ScaleVector(shootvel,1.0);
						TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
						if (StrEqual(cls,"monster_ichthyosaur",false))
						{
							if ((propseq == 9) || (propseq == 10))
							{
								float chkdist = GetVectorDistance(curorg,enorg,false);
								if (chkdist < 150.0)
								{
									if (centnextatk[entity] < Time)
									{
										char snd[64];
										Format(snd,sizeof(snd),"ichy\\ichy_bite%i.wav",GetRandomInt(1,2));
										EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
										float damageForce[3];
										float dmgset = 15.0;
										float dmgforce = 5.0;
										damageForce[0] = dmgforce;
										damageForce[1] = dmgforce;
										damageForce[2] = dmgforce;
										SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CRUSH,-1,damageForce);
										if (HasEntProp(targ,Prop_Data,"m_vecPunchAngleVel"))
										{
											float punchang[3];
											punchang[0] = -150.0;
											SetEntPropVector(targ,Prop_Data,"m_vecPunchAngleVel",punchang);
										}
										centnextatk[entity] = Time+1.0;
									}
								}
							}
						}
					}
					else
					{
						int waterlv = GetEntProp(entity,Prop_Data,"m_nWaterLevel");
						//32768 Allow out of water
						if (spawnflags & 1<<15) waterlv = 3;
						if (waterlv == 0) angs[0]+=20.0;
						if (waterlv <= 2)
						{
							angs[0]+=20.0;
							if (centnextsndtime[entity] < Time)
							{
								char snd[64];
								if (StrEqual(cls,"monster_ichthyosaur",false)) Format(snd,sizeof(snd),"ichy\\ichy_idle%i.wav",GetRandomInt(1,4));
								else if (FileExists("sound\\npc\\ichthyosaur\\watermove3.wav",true,NULL_STRING)) Format(snd,sizeof(snd),"npc\\ichthyosaur\\watermove%i.wav",GetRandomInt(1,3));
								if (strlen(snd) > 0) EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
								centnextsndtime[entity] = Time+1.5;
							}
						}
						float fhitpos[3];
						Handle hhitpos = INVALID_HANDLE;
						int rand = GetRandomInt(1,4);
						float randangadd = GetRandomFloat(10.0,70.0);
						if (rand == 1) angs[1]+=randangadd;
						else if (rand == 2) angs[1]-=randangadd;
						TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
						TR_GetEndPosition(fhitpos,hhitpos);
						float chkdist = GetVectorDistance(curorg,fhitpos,false);
						if (chkdist < 100.0)
						{
							angs[1]+=90.0;
							TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
							TR_GetEndPosition(fhitpos,hhitpos);
							chkdist = GetVectorDistance(curorg,fhitpos,false);
							if (chkdist < 100.0)
							{
								angs[1]+=90.0;
								TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
								TR_GetEndPosition(fhitpos,hhitpos);
								chkdist = GetVectorDistance(curorg,fhitpos,false);
								if (chkdist < 100.0)
								{
									angs[1]+=90.0;
									TR_TraceRayFilter(curorg,angs,MASK_SHOT,RayType_Infinite,TraceIchyFilter);
									TR_GetEndPosition(fhitpos,hhitpos);
								}
							}
						}
						float shootvel[3];
						MakeVectorFromPoints(curorg,fhitpos,shootvel);
						if (shootvel[2] < 0.0) shootvel[2]+=0.25;
						else shootvel[2]-=0.25;
						if (spawnflags & 1<<15) ScaleVector(shootvel,0.75);
						TeleportEntity(entity,NULL_VECTOR,NULL_VECTOR,shootvel);
					}
					if (centnextsndtime[entity] < Time)
					{
						if (StrEqual(cls,"monster_ichthyosaur",false))
						{
							char snd[64];
							Format(snd,sizeof(snd),"ichy\\ichy_idle%i.wav",GetRandomInt(1,4));
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
							centnextsndtime[entity] = Time+2.0;
						}
						else
						{
							if (FileExists("sound\\npc\\ichthyosaur\\underwatermove3.wav",true,NULL_STRING))
							{
								int randsnd = GetRandomInt(1,3);
								char snd[64];
								Format(snd,sizeof(snd),"npc\\ichthyosaur\\underwatermove%i.wav",randsnd);
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
								centnextsndtime[entity] = Time+2.0;
							}
							else if (FileExists("sound\\npc\\ichthyosaur\\water_breath.wav",true,NULL_STRING))
							{
								char snd[64];
								Format(snd,sizeof(snd),"npc\\ichthyosaur\\water_breath.wav");
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
								centnextsndtime[entity] = Time+7.0;
							}
						}
					}
				}
			}
		}
	}
}

public Action OnIchyFoundPlayer(const char[] output, int caller, int activator, float delay)
{
	float Time = GetTickedTime();
	if ((IsValidEntity(caller)) && (centnextsndtime[caller] < Time))
	{
		char snd[64];
		Format(snd,sizeof(snd),"ichy\\ichy_alert%i.wav",GetRandomInt(1,3));
		EmitSoundToAll(snd, caller, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		centnextsndtime[caller] = Time+1.0;
	}
}

public bool TraceIchyFilter(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if (StrEqual(clsname,"npc_ichthyosaur",false))
			return false;
	}
	return true;
}