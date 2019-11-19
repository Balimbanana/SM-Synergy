void assassinthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		float Time = GetTickedTime();
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (!StrEqual(cls,"monster_human_assassin",false))
		{
			if (lastseen[entity] < Time)
			{
				if (isattacking[entity])
				{
					SetVariantString("player D_FR 40");
					AcceptEntityInput(entity,"SetRelationship");
					isattacking[entity] = 0;
				}
				else
				{
					SetVariantString("player D_HT 99");
					AcceptEntityInput(entity,"SetRelationship");
					isattacking[entity] = 1;
				}
				lastseen[entity] = Time+GetRandomFloat(5.0,15.0);
			}
		}
		int targ = GetEntPropEnt(entity,Prop_Data,"m_hTarget");
		if ((targ != 0) && (IsValidEntity(targ)))
		{
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			float curorg[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
			float angs[3];
			if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
			float enorg[3];
			if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
			else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
			if (HasEntProp(targ,Prop_Data,"m_bDucked"))
			{
				if (GetEntProp(targ,Prop_Data,"m_bDucked") > 0) enorg[2]-=20.0;
			}
			float chance = GetRandomFloat(0.0,100.0);
			float targvec[3];
			MakeVectorFromPoints(curorg,enorg,targvec);
			float toang[3];
			GetVectorAngles(targvec,toang);
			float chkdist = GetVectorDistance(curorg,enorg,false);
			bool withinradius = false;
			int kickseq = 22;
			if (StrEqual(cls,"monster_human_assassin",false))
			{
				kickseq = 7;
				if (HasEntProp(entity,Prop_Data,"m_hActiveWeapon"))
				{
					int wep = GetEntPropEnt(entity,Prop_Data,"m_hActiveWeapon");
					if (IsValidEntity(wep))
					{
						if (GetEntProp(wep,Prop_Data,"m_nRenderMode") != 10) SetEntProp(wep,Prop_Data,"m_nRenderMode",10);
						if (GetEntProp(wep,Prop_Data,"m_nRenderFX") != 6) SetEntProp(wep,Prop_Data,"m_nRenderFX",6);
					}
				}
				if (HasEntProp(entity,Prop_Data,"m_bShouldPatrol"))
				{
					if (!GetEntProp(entity,Prop_Data,"m_bShouldPatrol")) SetEntProp(entity,Prop_Data,"m_bShouldPatrol",1);
				}
			}
			if (angs[1] > toang[1])
			{
				if ((angs[1]-toang[1] > 180) && (angs[1]-toang[1] < 220)) withinradius = false;
				else if ((toang[1]-angs[1] < -180) && (toang[1]-angs[1] > -220)) withinradius = false;
				else withinradius = true;
			}
			else if (toang[1] > angs[1])
			{
				if ((toang[1]-angs[1] > 180) && (toang[1]-angs[1] < 220)) withinradius = false;
				else if ((angs[1]-toang[1] < -180) && (angs[1]-toang[1] > -220)) withinradius = false;
				else withinradius = true;
			}
			if ((centlastang[entity] < Time) && (chance > 80.0) && (withinradius) && (chkdist > 100.0))
			{
				int mdl = CreateEntityByName("prop_dynamic");
				if (mdl != -1)
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					if (StrEqual(cls,"monster_human_assassin",false))
					{
						DispatchKeyValue(mdl,"model","models/hassassin.mdl");
						DispatchKeyValue(mdl,"DefaultAnim","grenadethrow");
					}
					else
					{
						DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
						DispatchKeyValue(mdl,"DefaultAnim","grenade");
					}
					DispatchKeyValue(mdl,"solid","0");
					TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
					DispatchSpawn(mdl);
					ActivateEntity(mdl);
					SetVariantString("!activator");
					AcceptEntityInput(mdl,"SetParent",entity);
					float shootvel[3];
					float loc[3];
					loc[0] = (curorg[0] + (80 * Cosine(DegToRad(angs[1]))));
					loc[1] = (curorg[1] + (80 * Sine(DegToRad(angs[1]))));
					loc[2] = curorg[2] + 60.0;
					MakeVectorFromPoints(loc,enorg,shootvel);
					float randthrow = GetRandomFloat(15.0,25.0);
					shootvel[2]+=randthrow;
					ScaleVector(shootvel,2.0);
					int grenade = CreateEntityByName("npc_grenade_frag"); //npc_contactgrenade
					if (grenade != -1)
					{
						TeleportEntity(grenade,loc,angs,NULL_VECTOR);
						SetEntPropFloat(grenade,Prop_Data,"m_flDetonateTime",Time+5.0);
						DispatchSpawn(grenade);
						ActivateEntity(grenade);
						SetEntPropEnt(grenade,Prop_Data,"m_hThrower",entity);
						SetEntProp(grenade,Prop_Data,"m_bIsLive",1);
						SetVariantString("3");
						AcceptEntityInput(grenade,"SetTimer");
						Handle data = CreateDataPack();
						WritePackCell(data,mdl);
						WritePackString(data,"prop_dynamic");
						CreateTimer(0.2,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.2,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
						TeleportEntity(grenade,NULL_VECTOR,NULL_VECTOR,shootvel);
					}
				}
				float rand = GetRandomFloat(15.0,25.0);
				centlastang[entity] = Time+rand;
			}
			if ((!isattacking[entity]) && (centlastposchk[entity] < Time))
			{
				centlastposchk[entity] = Time+2.0;
				if (chkdist < 400.0)
				{
					int randflip = GetRandomInt(0,2);
					switch(randflip)
					{
						case 0:
						{
							//Do a backflip
							int mdl = CreateEntityByName("prop_dynamic");
							if (mdl != -1)
							{
								SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
								if (StrEqual(cls,"monster_human_assassin",false))
								{
									DispatchKeyValue(mdl,"model","models/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","fly_up");
								}
								else
								{
									DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","Flip_all");
								}
								DispatchKeyValue(mdl,"solid","0");
								TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
								DispatchSpawn(mdl);
								ActivateEntity(mdl);
								SetVariantString("!activator");
								AcceptEntityInput(mdl,"SetParent",entity);
								float shootvel[3];
								curorg[2]+=1.0;
								MakeVectorFromPoints(curorg,enorg,shootvel);
								float randjump = GetRandomFloat(15.0,25.0);
								shootvel[2]+=randjump;
								shootvel[0] = shootvel[0]-shootvel[0]-shootvel[0];
								shootvel[1] = shootvel[1]-shootvel[1]-shootvel[1];
								ScaleVector(shootvel,8.0);
								TeleportEntity(entity,curorg,angs,shootvel);
								Handle data = CreateDataPack();
								WritePackCell(data,mdl);
								WritePackString(data,"prop_dynamic");
								CreateTimer(0.5,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						case 1:
						{
							int mdl = CreateEntityByName("prop_dynamic");
							if (mdl != -1)
							{
								SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
								if (StrEqual(cls,"monster_human_assassin",false))
								{
									DispatchKeyValue(mdl,"model","models/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","jump");
								}
								else
								{
									DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","flip_L");
								}
								DispatchKeyValue(mdl,"solid","0");
								TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
								DispatchSpawn(mdl);
								ActivateEntity(mdl);
								SetVariantString("!activator");
								AcceptEntityInput(mdl,"SetParent",entity);
								float shootvel[3];
								curorg[2]+=1.0;
								MakeVectorFromPoints(curorg,enorg,shootvel);
								float randjump = GetRandomFloat(15.0,25.0);
								shootvel[2]+=randjump;
								shootvel[0] = shootvel[0]-shootvel[0]-shootvel[0];
								shootvel[1] = shootvel[1]-shootvel[1]-shootvel[1];
								shootvel[1]+=90.0;
								ScaleVector(shootvel,8.0);
								TeleportEntity(entity,curorg,angs,shootvel);
								Handle data = CreateDataPack();
								WritePackCell(data,mdl);
								WritePackString(data,"prop_dynamic");
								CreateTimer(0.5,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						case 2:
						{
							int mdl = CreateEntityByName("prop_dynamic");
							if (mdl != -1)
							{
								SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
								if (StrEqual(cls,"monster_human_assassin",false))
								{
									DispatchKeyValue(mdl,"model","models/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","jump");
								}
								else
								{
									DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","flip_R");
								}
								DispatchKeyValue(mdl,"solid","0");
								TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
								DispatchSpawn(mdl);
								ActivateEntity(mdl);
								SetVariantString("!activator");
								AcceptEntityInput(mdl,"SetParent",entity);
								float shootvel[3];
								curorg[2]+=1.0;
								MakeVectorFromPoints(curorg,enorg,shootvel);
								float randjump = GetRandomFloat(15.0,25.0);
								shootvel[2]+=randjump;
								shootvel[0] = shootvel[0]-shootvel[0]-shootvel[0];
								shootvel[1] = shootvel[1]-shootvel[1]-shootvel[1];
								shootvel[1]-=90.0;
								ScaleVector(shootvel,8.0);
								TeleportEntity(entity,curorg,angs,shootvel);
								Handle data = CreateDataPack();
								WritePackCell(data,mdl);
								WritePackString(data,"prop_dynamic");
								CreateTimer(0.5,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
			}
			if ((seq == kickseq) && (centnextatk[entity] < Time))
			{
				float damageForce[3];
				damageForce[0]=10.0;
				damageForce[1]=10.0;
				damageForce[2]=10.0;
				float dmgset = 5.0;
				SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
				int randkick = GetRandomInt(1,6);
				char snd[64];
				Format(snd,sizeof(snd),"npc\\assassin\\kick0%i.wav",randkick);
				centnextatk[entity] = Time+1.0;
			}
			else if ((centnextatk[entity] < Time) && (withinradius))
			{
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				float lastenemy = GetEntPropFloat(entity,Prop_Data,"m_flLastEnemyTime");
				if (lastsaw > lastenemy-1.0)
				{
					if (StrEqual(cls,"monster_human_assassin",false))
					{
						int bulletmuzzle = CreateEntityByName("env_muzzleflash");
						if (bulletmuzzle != -1)
						{
							DispatchKeyValue(bulletmuzzle,"scale","0.5");
							DispatchSpawn(bulletmuzzle);
							ActivateEntity(bulletmuzzle);
							SetVariantString("!activator");
							AcceptEntityInput(bulletmuzzle,"SetParent",entity);
							SetVariantString("0");
							AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
							AcceptEntityInput(bulletmuzzle,"Fire");
							Handle dp = CreateDataPack();
							WritePackCell(dp,bulletmuzzle);
							WritePackString(dp,"env_muzzleflash");
							CreateTimer(0.2,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
							if (HasEntProp(bulletmuzzle,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(bulletmuzzle,Prop_Data,"m_vecAbsOrigin",curorg);
							else if (HasEntProp(bulletmuzzle,Prop_Send,"m_vecOrigin")) GetEntPropVector(bulletmuzzle,Prop_Send,"m_vecOrigin",curorg);
							if (HasEntProp(bulletmuzzle,Prop_Data,"m_angAbsRotation")) GetEntPropVector(bulletmuzzle,Prop_Data,"m_angAbsRotation",angs);
							float loc[3];
							loc[0] = (curorg[0] + (20 * Cosine(DegToRad(angs[1]))));
							loc[1] = (curorg[1] + (20 * Sine(DegToRad(angs[1]))));
							loc[2] = curorg[2] + 1.0;
							NPCShootBullet(entity,"weapon_glock",loc,toang,0.5);
						}
						int rand = GetRandomInt(1,2);
						switch(rand)
						{
							case 1:
							{
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\pl_gun1.wav");
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
							}
							case 2:
							{
								char snd[64];
								Format(snd,sizeof(snd),"weapons\\pl_gun2.wav");
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
							}
						}
						centnextatk[entity] = Time+0.2;
						if (timesattacked[entity] > 10)
						{
							centnextatk[entity] = Time+5.0;
							timesattacked[entity] = 0;
						}
						else timesattacked[entity]++;
					}
					else
					{
						int randside = GetRandomInt(0,1);
						if (randside == 0)
						{
							int findleft = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
							if (findleft != -1)
							{
								if (HasEntProp(findleft,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(findleft,Prop_Data,"m_vecAbsOrigin",curorg);
								else if (HasEntProp(findleft,Prop_Send,"m_vecOrigin")) GetEntPropVector(findleft,Prop_Send,"m_vecOrigin",curorg);
								if (HasEntProp(findleft,Prop_Data,"m_angAbsRotation")) GetEntPropVector(findleft,Prop_Data,"m_angAbsRotation",angs);
								//int spitball = CreateEntityByName("prop_physics");
								//if (spitball != -1)
								//{
								float loc[3];
								loc[0] = (curorg[0] + (20 * Cosine(DegToRad(angs[1]))));
								loc[1] = (curorg[1] + (20 * Sine(DegToRad(angs[1]))));
								loc[2] = curorg[2] + 1.0;
								/*
								ScaleVector(shootvel,3.0);
								DispatchKeyValue(spitball,"model","models/props_junk/popcan01a.mdl");
								DispatchSpawn(spitball);
								ActivateEntity(spitball);
								if (!IsModelPrecached("models/weapons/rifleshell.mdl")) PrecacheModel("models/weapons/rifleshell.mdl",true);
								SetEntityModel(spitball,"models/weapons/rifleshell.mdl");
								SetEntityMoveType(spitball,MOVETYPE_FLY);
								SDKHook(spitball, SDKHook_StartTouch, StartTouchBullet);
								TeleportEntity(spitball,loc,angs,shootvel);
								Handle dp = CreateDataPack();
								WritePackCell(dp,spitball);
								WritePackString(dp,"prop_physics");
								CreateTimer(0.5,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
								*/
								NPCShootBullet(entity,"weapon_glock",loc,toang,0.5);
								int bulletmuzzle = GetEntPropEnt(findleft,Prop_Data,"m_hEffectEntity");
								if (bulletmuzzle == -1)
								{
									bulletmuzzle = CreateEntityByName("env_muzzleflash");
									if (bulletmuzzle != -1)
									{
										DispatchKeyValue(bulletmuzzle,"scale","0.5");
										DispatchSpawn(bulletmuzzle);
										ActivateEntity(bulletmuzzle);
										SetVariantString("!activator");
										AcceptEntityInput(bulletmuzzle,"SetParent",findleft);
										SetVariantString("muzzle");
										AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
										SetEntPropEnt(findleft,Prop_Data,"m_hEffectEntity",bulletmuzzle);
										AcceptEntityInput(bulletmuzzle,"Fire");
									}
								}
								else
								{
									AcceptEntityInput(bulletmuzzle,"Fire");
								}
								int rand = GetRandomInt(1,2);
								switch(rand)
								{
									case 1:
									{
										char snd[64];
										Format(snd,sizeof(snd),"weapons\\glock\\single.wav");
										EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									}
									case 2:
									{
										char snd[64];
										Format(snd,sizeof(snd),"weapons\\glock\\single_npc.wav");
										EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									}
								}
								centnextatk[entity] = Time+0.2;
								if (timesattacked[entity] > 10)
								{
									centnextatk[entity] = Time+5.0;
									timesattacked[entity] = 0;
									rand = GetRandomInt(1,2);
									switch(rand)
									{
										case 1:
										{
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
											EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
										}
										case 2:
										{
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\glock\\reload_npc.wav");
											EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
										}
									}
								}
								else timesattacked[entity]++;
							}
						}
						else
						{
							int findright = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
							if (findright != -1)
							{
								if (HasEntProp(findright,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(findright,Prop_Data,"m_vecAbsOrigin",curorg);
								else if (HasEntProp(findright,Prop_Send,"m_vecOrigin")) GetEntPropVector(findright,Prop_Send,"m_vecOrigin",curorg);
								if (HasEntProp(findright,Prop_Data,"m_angAbsRotation")) GetEntPropVector(findright,Prop_Data,"m_angAbsRotation",angs);
								float loc[3];
								loc[0] = (curorg[0] + (20 * Cosine(DegToRad(angs[1]))));
								loc[1] = (curorg[1] + (20 * Sine(DegToRad(angs[1]))));
								loc[2] = curorg[2] + 1.0;
								NPCShootBullet(entity,"weapon_glock",loc,toang,0.5);
								int bulletmuzzle = GetEntPropEnt(findright,Prop_Data,"m_hEffectEntity");
								if (bulletmuzzle == -1)
								{
									bulletmuzzle = CreateEntityByName("env_muzzleflash");
									if (bulletmuzzle != -1)
									{
										DispatchKeyValue(bulletmuzzle,"scale","0.5");
										DispatchSpawn(bulletmuzzle);
										ActivateEntity(bulletmuzzle);
										SetVariantString("!activator");
										AcceptEntityInput(bulletmuzzle,"SetParent",findright);
										SetVariantString("muzzle");
										AcceptEntityInput(bulletmuzzle,"SetParentAttachment");
										SetEntPropEnt(findright,Prop_Data,"m_hEffectEntity",bulletmuzzle);
										AcceptEntityInput(bulletmuzzle,"Fire");
									}
								}
								else
								{
									AcceptEntityInput(bulletmuzzle,"Fire");
								}
								int rand = GetRandomInt(1,2);
								switch(rand)
								{
									case 1:
									{
										char snd[64];
										Format(snd,sizeof(snd),"weapons\\glock\\single.wav");
										EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									}
									case 2:
									{
										char snd[64];
										Format(snd,sizeof(snd),"weapons\\glock\\single_npc.wav");
										EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
									}
								}
								centnextatk[entity] = Time+0.2;
								if (timesattacked[entity] > 10)
								{
									centnextatk[entity] = Time+5.0;
									timesattacked[entity] = 0;
									rand = GetRandomInt(1,2);
									switch(rand)
									{
										case 1:
										{
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\glock\\reload.wav");
											EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
										}
										case 2:
										{
											char snd[64];
											Format(snd,sizeof(snd),"weapons\\glock\\reload_npc.wav");
											EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
										}
									}
								}
								else timesattacked[entity]++;
							}
						}
					}
				}
			}
		}
	}
}

public Action assassintkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			char cls[32];
			GetEntityClassname(victim,cls,sizeof(cls));
			int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
			float Time = GetTickedTime();
			if (damage > curh)
			{
				char snd[64];
				int randdeath = GetRandomInt(1,6);
				if (StrEqual(cls,"monster_human_assassin",false))
				{
					randdeath = GetRandomInt(1,4);
					Format(snd,sizeof(snd),"common\\bodydrop%i.wav",randdeath);
					if (FileExists(snd,true,NULL_STRING))
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else
				{
					Format(snd,sizeof(snd),"npc\\assassin\\death0%i.wav",randdeath);
					EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
			}
			else if ((damage > 1) && (centnextsndtime[victim] < Time))
			{
				char snd[64];
				int rand = GetRandomInt(1,20);
				if (rand == 17) Format(snd,sizeof(snd),"npc\\assassin\\pain1.wav");
				else if (rand == 18) Format(snd,sizeof(snd),"npc\\assassin\\pain2.wav");
				else if (rand == 19) Format(snd,sizeof(snd),"npc\\assassin\\pain3.wav");
				else if (rand == 20) Format(snd,sizeof(snd),"npc\\assassin\\pain4.wav");
				else Format(snd,sizeof(snd),"npc\\assassin\\pain0%i.wav",rand);
				int randchanceflip = GetRandomInt(1,20);
				int targ = GetEntPropEnt(victim,Prop_Data,"m_hTarget");
				if ((randchanceflip > 18) && (targ != 0) && (IsValidEntity(targ)))
				{
					float curorg[3];
					if (HasEntProp(victim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecAbsOrigin",curorg);
					else if (HasEntProp(victim,Prop_Send,"m_vecOrigin")) GetEntPropVector(victim,Prop_Send,"m_vecOrigin",curorg);
					float angs[3];
					if (HasEntProp(victim,Prop_Data,"m_angAbsRotation")) GetEntPropVector(victim,Prop_Data,"m_angAbsRotation",angs);
					float enorg[3];
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
					else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
					int randflip = GetRandomInt(0,2);
					switch(randflip)
					{
						case 0:
						{
							//Do a backflip
							int mdl = CreateEntityByName("prop_dynamic");
							if (mdl != -1)
							{
								SetEntProp(victim,Prop_Data,"m_nRenderFX",6);
								if (StrEqual(cls,"monster_human_assassin",false))
								{
									DispatchKeyValue(mdl,"model","models/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","jump");
								}
								else
								{
									DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","Flip_all");
								}
								DispatchKeyValue(mdl,"solid","0");
								TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
								DispatchSpawn(mdl);
								ActivateEntity(mdl);
								SetVariantString("!activator");
								AcceptEntityInput(mdl,"SetParent",victim);
								float shootvel[3];
								curorg[2]+=1.0;
								MakeVectorFromPoints(curorg,enorg,shootvel);
								float randjump = GetRandomFloat(15.0,25.0);
								shootvel[2]+=randjump;
								shootvel[0] = shootvel[0]-shootvel[0]-shootvel[0];
								shootvel[1] = shootvel[1]-shootvel[1]-shootvel[1];
								ScaleVector(shootvel,8.0);
								TeleportEntity(victim,curorg,angs,shootvel);
								Handle data = CreateDataPack();
								WritePackCell(data,mdl);
								WritePackString(data,"prop_dynamic");
								CreateTimer(0.5,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(0.5,resetatk,victim,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						case 1:
						{
							int mdl = CreateEntityByName("prop_dynamic");
							if (mdl != -1)
							{
								SetEntProp(victim,Prop_Data,"m_nRenderFX",6);
								if (StrEqual(cls,"monster_human_assassin",false))
								{
									DispatchKeyValue(mdl,"model","models/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","jump");
								}
								else
								{
									DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","flip_L");
								}
								DispatchKeyValue(mdl,"solid","0");
								TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
								DispatchSpawn(mdl);
								ActivateEntity(mdl);
								SetVariantString("!activator");
								AcceptEntityInput(mdl,"SetParent",victim);
								float shootvel[3];
								curorg[2]+=1.0;
								MakeVectorFromPoints(curorg,enorg,shootvel);
								float randjump = GetRandomFloat(15.0,25.0);
								shootvel[2]+=randjump;
								shootvel[0] = shootvel[0]-shootvel[0]-shootvel[0];
								shootvel[1] = shootvel[1]-shootvel[1]-shootvel[1];
								shootvel[1]+=90.0;
								ScaleVector(shootvel,8.0);
								TeleportEntity(victim,curorg,angs,shootvel);
								Handle data = CreateDataPack();
								WritePackCell(data,mdl);
								WritePackString(data,"prop_dynamic");
								CreateTimer(0.5,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(0.5,resetatk,victim,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						case 2:
						{
							int mdl = CreateEntityByName("prop_dynamic");
							if (mdl != -1)
							{
								SetEntProp(victim,Prop_Data,"m_nRenderFX",6);
								if (StrEqual(cls,"monster_human_assassin",false))
								{
									DispatchKeyValue(mdl,"model","models/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","jump");
								}
								else
								{
									DispatchKeyValue(mdl,"model","models/humans/hassassin.mdl");
									DispatchKeyValue(mdl,"DefaultAnim","flip_R");
								}
								DispatchKeyValue(mdl,"solid","0");
								TeleportEntity(mdl,curorg,angs,NULL_VECTOR);
								DispatchSpawn(mdl);
								ActivateEntity(mdl);
								SetVariantString("!activator");
								AcceptEntityInput(mdl,"SetParent",victim);
								float shootvel[3];
								curorg[2]+=1.0;
								MakeVectorFromPoints(curorg,enorg,shootvel);
								float randjump = GetRandomFloat(15.0,25.0);
								shootvel[2]+=randjump;
								shootvel[0] = shootvel[0]-shootvel[0]-shootvel[0];
								shootvel[1] = shootvel[1]-shootvel[1]-shootvel[1];
								shootvel[1]-=90.0;
								ScaleVector(shootvel,8.0);
								TeleportEntity(victim,curorg,angs,shootvel);
								Handle data = CreateDataPack();
								WritePackCell(data,mdl);
								WritePackString(data,"prop_dynamic");
								CreateTimer(0.5,cleanup,data,TIMER_FLAG_NO_MAPCHANGE);
								CreateTimer(0.5,resetatk,victim,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
				centnextsndtime[victim] = Time+1.0;
			}
		}
	}
	return Plugin_Continue;
}