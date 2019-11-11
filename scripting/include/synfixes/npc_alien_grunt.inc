void agruntthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
			if ((seq == 0) && (statechk == 3)) SetEntProp(entity,Prop_Data,"m_NPCState",2);
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				char entmdl[64];
				if (HasEntProp(entity,Prop_Data,"m_ModelName")) GetEntPropString(entity,Prop_Data,"m_ModelName",entmdl,sizeof(entmdl));
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				float meleerange = 75.0;
				float jumprange = 166.0;
				float hornetminrange = 256.0;
				float hornetmaxrange = 2048.0;
				Handle cvarchk = FindConVar("sk_alien_grunt_melee_range");
				if (cvarchk != INVALID_HANDLE)
					meleerange = GetConVarFloat(cvarchk);
				cvarchk = FindConVar("sk_alien_grunt_melee_jump_range");
				if (cvarchk != INVALID_HANDLE)
					jumprange = GetConVarFloat(cvarchk);
				cvarchk = FindConVar("sk_alien_grunt_hornet_min_range");
				if (cvarchk != INVALID_HANDLE)
					hornetminrange = GetConVarFloat(cvarchk);
				cvarchk = FindConVar("sk_alien_grunt_hornet_max_range");
				if (cvarchk != INVALID_HANDLE)
					hornetmaxrange = GetConVarFloat(cvarchk);
				CloseHandle(cvarchk);
				float targvec[3];
				MakeVectorFromPoints(curorg,enorg,targvec);
				float toang[3];
				GetVectorAngles(targvec,toang);
				bool withinradius = false;
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
				int meleeanim = 16;
				int meleeanim2 = 20;
				if (StrEqual(entmdl,"models/agrunt.mdl",false))
				{
					meleeanim = 9;
					meleeanim2 = 1;
					meleerange+=25.0;
					hornetminrange-=80.0;
					jumprange = 1.0;
				}
				if ((chkdist <= meleerange) && ((seq == meleeanim) || (seq == meleeanim2)) && (withinradius))
				{
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if (StrEqual(entmdl,"models/agrunt.mdl",false))
					{
						char snd[64];
						Format(snd,sizeof(snd),"npc\\agrunt\\ag_attack%i.wav",GetRandomInt(1,3));
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
						if ((IsValidEntity(propset)) && (propset != 0))
						{
							char randanim[32];
							Format(randanim,sizeof(randanim),"mattack%i",GetRandomInt(2,3));
							SetVariantString(randanim);
							AcceptEntityInput(propset,"SetAnimation");
						}
						else
						{
							int propshow = CreateEntityByName("prop_dynamic");
							if (propshow != -1)
							{
								DispatchKeyValue(propshow,"solid","0");
								DispatchKeyValue(propshow,"model","models/agrunt.mdl");
								if (GetRandomInt(0,1) == 0) DispatchKeyValue(propshow,"DefaultAnim","mattack2");
								else DispatchKeyValue(propshow,"DefaultAnim","mattack3");
								TeleportEntity(propshow,curorg,angs,NULL_VECTOR);
								DispatchSpawn(propshow);
								ActivateEntity(propshow);
								SetVariantString("!activator");
								AcceptEntityInput(propshow,"SetParent",entity);
								int rand = GetRandomInt(17,19);
								SetEntProp(propshow,Prop_Data,"m_nSequence",rand);
								float tmp;
								tmp+=propshow;
								centlastang[entity] = tmp;
							}
						}
					}
					else if ((IsValidEntity(propset)) && (propset != 0))
					{
						char clschk[24];
						GetEntityClassname(propset,clschk,sizeof(clschk));
						if (StrEqual(clschk,"prop_dynamic",false))
							AcceptEntityInput(propset,"kill");
						centlastang[entity] = 0.0;
						SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					}
					else SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					isattacking[entity] = true;
					centnextatk[entity] = Time+0.5;
					float damageForce[3];
					float dmgset = 25.0;
					float dmgforce = 40.0;
					Handle meleedmg = FindConVar("sk_alien_grunt_melee_dmg");
					if (meleedmg != INVALID_HANDLE)
						dmgset = GetConVarFloat(meleedmg);
					CloseHandle(meleedmg);
					damageForce[0] = dmgforce;
					damageForce[1] = dmgforce;
					damageForce[2] = dmgforce;
					SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
					CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
				}
				else if ((chkdist <= jumprange) && (withinradius))
				{
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((!IsValidEntity(propset)) || (propset == 0))
					{
						int propshow = CreateEntityByName("prop_dynamic");
						if (propshow != -1)
						{
							DispatchKeyValue(propshow,"solid","0");
							if (StrEqual(entmdl,"models/agrunt.mdl",false))
							{
								DispatchKeyValue(propshow,"model","models/agrunt.mdl");
								if (GetRandomInt(0,1) == 0) DispatchKeyValue(propshow,"DefaultAnim","mattack2");
								else DispatchKeyValue(propshow,"DefaultAnim","mattack3");
							}
							else
							{
								DispatchKeyValue(propshow,"model","models/xenians/agrunt.mdl");
								DispatchKeyValue(propshow,"DefaultAnim","attack_leap");
							}
							TeleportEntity(propshow,curorg,angs,NULL_VECTOR);
							DispatchSpawn(propshow);
							ActivateEntity(propshow);
							SetVariantString("!activator");
							AcceptEntityInput(propshow,"SetParent",entity);
							int rand = GetRandomInt(17,19);
							SetEntProp(propshow,Prop_Data,"m_nSequence",rand);
							float tmp;
							tmp+=propshow;
							centlastang[entity] = tmp;
						}
					}
					centnextatk[entity] = Time+1.0;
					float damageForce[3];
					float dmgset = 30.0;
					float dmgforce = 450.0;
					Handle meleedmg = FindConVar("sk_alien_grunt_melee_dmg");
					if (meleedmg != INVALID_HANDLE)
						dmgset = GetConVarFloat(meleedmg)*1.2;
					CloseHandle(meleedmg);
					damageForce[0] = dmgforce;
					damageForce[1] = dmgforce;
					damageForce[2] = dmgforce;
					SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
					CreateTimer(1.0,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
				}
				else if ((chkdist <= hornetmaxrange) && (chkdist > hornetminrange) && (lastsaw > lastseen[entity]) && (withinradius))
				{
					int attachfind = CreateEntityByName("prop_dynamic");
					if (attachfind != -1)
					{
						DispatchKeyValue(attachfind,"rendermode","10");
						DispatchKeyValue(attachfind,"solid","0");
						DispatchKeyValue(attachfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(attachfind);
						ActivateEntity(attachfind);
						TeleportEntity(attachfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(attachfind,"SetParent",entity);
						if (StrEqual(entmdl,"models/agrunt.mdl",false)) SetVariantString("0");
						else SetVariantString("rightclaw");
						AcceptEntityInput(attachfind,"SetParentAttachment");
						if (HasEntProp(attachfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(attachfind,Prop_Data,"m_vecAbsOrigin",curorg);
						else if (HasEntProp(attachfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(attachfind,Prop_Send,"m_vecOrigin",curorg);
						AcceptEntityInput(attachfind,"kill");
					}
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if (StrEqual(entmdl,"models/agrunt.mdl",false))
					{
						char snd[64];
						Format(snd,sizeof(snd),"npc\\agrunt\\ag_attack%i.wav",GetRandomInt(1,3));
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
						if ((IsValidEntity(propset)) && (propset != 0))
						{
							char randanim[32];
							Format(randanim,sizeof(randanim),"attack3_2");
							if (enorg[2] > curorg[2]+20.0) Format(randanim,sizeof(randanim),"attack3_1");
							SetVariantString(randanim);
							AcceptEntityInput(propset,"SetAnimation");
						}
						else
						{
							int propshow = CreateEntityByName("prop_dynamic");
							if (propshow != -1)
							{
								DispatchKeyValue(propshow,"solid","0");
								DispatchKeyValue(propshow,"model","models/agrunt.mdl");
								char randanim[32];
								Format(randanim,sizeof(randanim),"attack3_2");
								if (enorg[2] > curorg[2]+20.0) Format(randanim,sizeof(randanim),"attack3_1");
								DispatchKeyValue(propshow,"DefaultAnim",randanim);
								TeleportEntity(propshow,curorg,angs,NULL_VECTOR);
								DispatchSpawn(propshow);
								ActivateEntity(propshow);
								SetVariantString("!activator");
								AcceptEntityInput(propshow,"SetParent",entity);
								int rand = GetRandomInt(17,19);
								SetEntProp(propshow,Prop_Data,"m_nSequence",rand);
								float tmp;
								tmp+=propshow;
								centlastang[entity] = tmp;
							}
						}
					}
					else if ((IsValidEntity(propset)) && (propset != 0))
					{
						char clschk[24];
						GetEntityClassname(propset,clschk,sizeof(clschk));
						if (StrEqual(clschk,"prop_dynamic",false))
							AcceptEntityInput(propset,"kill");
						centlastang[entity] = 0.0;
						SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					}
					else SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
					if (StrEqual(entmdl,"models/agrunt.mdl",false))
					{
						int context = 19;
						if (enorg[2] > curorg[2]+10.0) context = 18;
						SetEntProp(entity,Prop_Data,"m_nSequence",context);
					}
					else
					{
						int rand = GetRandomInt(41,42);
						SetEntProp(entity,Prop_Data,"m_nSequence",rand);
					}
					lastseen[entity] = lastsaw;
					isattacking[entity] = true;
					centnextatk[entity] = Time+0.5;
					float loc[3];
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (curorg[0] + (55 * Cosine(DegToRad(angs[1]))));
						loc[1] = (curorg[1] + (55 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (curorg[0] + (35 * Cosine(DegToRad(angs[1]))));
						loc[1] = (curorg[1] + (35 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (curorg[2] - 5);
					float shootvel[3];
					enorg[2]+=20.0;
					if (HasEntProp(targ,Prop_Data,"m_bDucked"))
					{
						if (GetEntProp(targ,Prop_Data,"m_bDucked") < 1) enorg[2]+=30.0;
					}
					MakeVectorFromPoints(loc,enorg,shootvel);
					//if (shootvel[2] < 0.0) shootvel[2]+=25.0;
					//else shootvel[2]-=25.0;
					ScaleVector(shootvel,1.25);
					int spitball = CreateEntityByName("generic_actor");
					if (spitball != -1)
					{
						//DispatchKeyValue(spitball,"model","models/props_junk/popcan01a.mdl");
						if (StrEqual(entmdl,"models/agrunt.mdl",false)) DispatchKeyValue(spitball,"model","models/hornet.mdl");
						else DispatchKeyValue(spitball,"model","models/weapons/w_hornet.mdl");
						DispatchKeyValue(spitball,"classname","npc_hornet");
						TeleportEntity(spitball,loc,angs,NULL_VECTOR);
						DispatchSpawn(spitball);
						ActivateEntity(spitball);
						//if (!IsModelPrecached("models/weapons/w_hornet.mdl")) PrecacheModel("models/weapons/w_hornet.mdl",true);
						//SetEntityModel(spitball,"models/weapons/w_hornet.mdl");
						SetEntityMoveType(spitball,MOVETYPE_FLY);
						SDKHook(spitball, SDKHook_StartTouch, StartTouchHornet);
						//TeleportEntity(spitball,loc,angs,shootvel);
						if (!StrEqual(entmdl,"models/agrunt.mdl",false))
						{
							int effect = CreateEntityByName("info_particle_system");
							if (effect != -1)
							{
								DispatchKeyValue(effect,"effect_name","hornet_trail");
								DispatchKeyValue(effect,"start_active","1");
								TeleportEntity(effect,loc,angs,NULL_VECTOR);
								DispatchSpawn(effect);
								ActivateEntity(effect);
								SetVariantString("!activator");
								AcceptEntityInput(effect,"SetParent",spitball);
								AcceptEntityInput(effect,"Start");
								Handle dp = CreateDataPack();
								WritePackCell(dp,effect);
								WritePackString(dp,"info_particle_system");
								CreateTimer(2.0,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						SetEntProp(spitball,Prop_Data,"m_MoveType",4);
						TeleportEntity(spitball,NULL_VECTOR,NULL_VECTOR,shootvel);
						/*
						int ent = CreateEntityByName("env_spritetrail");
						DispatchKeyValue(ent,"lifetime","2.0");
						DispatchKeyValue(ent,"startwidth","8.0");
						DispatchKeyValue(ent,"endwidth","6.0");
						DispatchKeyValue(ent,"spritename","sprites/bluelaser1.vmt");
						DispatchKeyValue(ent,"renderamt","150");
						DispatchKeyValue(ent,"rendermode","5");
						char colorstr[64];
						Format(colorstr,sizeof(colorstr),"145 42 42");
						DispatchKeyValue(ent,"rendercolor",colorstr);
						TeleportEntity(ent,loc,NULL_VECTOR,NULL_VECTOR);
						DispatchSpawn(ent);
						ActivateEntity(ent);
						SetVariantString("!activator");
						AcceptEntityInput(ent,"SetParent",spitball);
						*/
					}
					CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action StartTouchHornet(int entity, int other)
{
	if (IsValidEntity(other))
	{
		char clschk[24];
		GetEntityClassname(other,clschk,sizeof(clschk));
		if (StrContains(clschk,"npc_alien_",false) == -1)
		{
			float damageForce[3];
			float dmgset = 5.0;
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_CLUB,-1,damageForce);
			char entmdl[64];
			if (HasEntProp(entity,Prop_Data,"m_ModelName")) GetEntPropString(entity,Prop_Data,"m_ModelName",entmdl,sizeof(entmdl));
			if (StrEqual(entmdl,"models/hornet.mdl",false))
			{
				char snd[64];
				Format(snd,sizeof(snd),"npc\\agrunt\\ag_fire%i.wav",GetRandomInt(1,3));
				EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
			}
			else
			{
				int rand = GetRandomInt(1,2);
				switch(rand)
				{
					case 1:
					{
						char snd[64];
						Format(snd,sizeof(snd),"weapons\\hivehand\\bug_impact.wav");
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					case 2:
					{
						char snd[64];
						Format(snd,sizeof(snd),"weapons\\hivehand\\single.wav");
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
			}
			int effect = CreateEntityByName("info_particle_system");
			if (effect != -1)
			{
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				DispatchKeyValue(effect,"effect_name","grenade_hornet_detonate");
				DispatchKeyValue(effect,"start_active","1");
				TeleportEntity(effect,curorg,angs,NULL_VECTOR);
				DispatchSpawn(effect);
				ActivateEntity(effect);
				AcceptEntityInput(effect,"Start");
				Handle dp = CreateDataPack();
				WritePackCell(dp,effect);
				WritePackString(dp,"info_particle_system");
				CreateTimer(0.5,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		AcceptEntityInput(entity,"kill");
	}
}

public Action agrunttkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ((IsValidEntity(victim)) && (IsValidEntity(attacker)))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			if (IsEntNetworkable(attacker))
			{
				char clschk[24];
				GetEntityClassname(attacker,clschk,sizeof(clschk));
				if ((attacker == victim) || (StrEqual(clschk,"npc_alien_grunt",false)))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
				else if (damage > 4.0)
				{
					float Time = GetTickedTime();
					if (centlastposchk[victim] <= Time)
					{
						char snd[64];
						char entmdl[64];
						if (HasEntProp(victim,Prop_Data,"m_ModelName")) GetEntPropString(victim,Prop_Data,"m_ModelName",entmdl,sizeof(entmdl));
						if (StrEqual(entmdl,"models/agrunt.mdl",false)) Format(snd,sizeof(snd),"npc\\agrunt\\ag_pain%i.wav",GetRandomInt(1,5));
						else Format(snd,sizeof(snd),"npc\\alien_grunt\\PAIN_%i.wav",GetRandomInt(1,4));
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
						centlastposchk[victim] = Time+2.5;
					}
				}
				if (GetEntProp(victim,Prop_Data,"m_iHealth")-damage < 1.0)
				{
					char snd[64];
					char entmdl[64];
					if (HasEntProp(victim,Prop_Data,"m_ModelName")) GetEntPropString(victim,Prop_Data,"m_ModelName",entmdl,sizeof(entmdl));
					if (StrEqual(entmdl,"models/agrunt.mdl",false))
					{
						Format(snd,sizeof(snd),"npc\\agrunt\\ag_die%i.wav",GetRandomInt(1,5));
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}