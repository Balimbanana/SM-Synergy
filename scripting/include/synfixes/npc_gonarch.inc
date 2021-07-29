bool bCheckedMdl[2048];

void gonarchthink(int entity)
{
	if (IsValidEntity(entity))
	{
		int scripting = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
		int curh = GetEntProp(entity,Prop_Data,"m_iHealth");
		if (entity > MaxClients)
		{
			if (!bCheckedMdl[entity])
			{
				bCheckedMdl[entity] = true;
				if (FileExists("models/xenians/gonarch.mdl",true,NULL_STRING))
				{
					if (!IsModelPrecached("models/xenians/gonarch.mdl")) PrecacheModel("models/xenians/gonarch.mdl",true);
					SetEntityModel(entity,"models/xenians/gonarch.mdl");
				}
				else
				{
					if (!IsModelPrecached("models/gonarch.mdl")) PrecacheModel("models/gonarch.mdl",true);
					SetEntityModel(entity,"models/gonarch.mdl");
				}
				float vMins[3];
				float vMaxs[3];
				vMins[0] = -30.0;
				vMins[1] = -30.0;
				vMins[2] = 0.0;
				vMaxs[0] = 30.0;
				vMaxs[1] = 30.0;
				vMaxs[2] = 72.0;
				SetEntPropVector(entity,Prop_Data,"m_vecMins",vMins);
				SetEntPropVector(entity,Prop_Data,"m_vecMaxs",vMaxs);
			}
		}
		if ((scripting == -1) && (curh > 1))
		{
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			if ((seq == 1) || (seq == 6))
			{
				//Prevent flinch anim
				SetEntProp(entity,Prop_Data,"m_nSequence",0);
				seq = 0;
			}
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			if ((targ != 0) && (IsValidEntity(targ)))
			{
				float Time = GetTickedTime();
				float curorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
				float targpos[3];
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",targpos);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",targpos);
				float chkdist = GetVectorDistance(curorg,targpos,false);
				if ((seq >= 14) && (seq <= 16) && (centnextatk[entity] < Time))
				{
					float damageForce[3];
					damageForce[0] = 100.0;
					damageForce[1] = 100.0;
					damageForce[2] = 100.0;
					float dmgset = 30.0;
					Handle dmgcvar = FindConVar("sk_gonarch_dmg_strike");
					if (dmgcvar != INVALID_HANDLE)
					{
						dmgset = GetConVarFloat(dmgcvar);
					}
					CloseHandle(dmgcvar);
					targpos[2]+=0.2;
					TeleportEntity(targ,targpos,NULL_VECTOR,NULL_VECTOR);
					SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
					char snd[64];
					Format(snd,sizeof(snd),"gonarch\\gon_attack%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					centnextatk[entity] = Time + 1.0;
				}
				else if ((GetRandomInt(0,100) > 95) && (centnextatk[entity] < Time) && (timesattacked[entity] < 11))
				{
					int babycrab = CreateEntityByName("npc_headcrab");
					if (babycrab != -1)
					{
						Handle dp = CreateDataPack();
						DispatchKeyValue(babycrab,"classname","npc_babycrab");
						DispatchKeyValue(babycrab,"rendermode","10");
						DispatchKeyValue(babycrab,"renderfx","6");
						DispatchKeyValue(babycrab,"renderamt","0");
						DispatchKeyValue(babycrab,"rendercolor","0 0 0");
						if (FileExists("models/xenians/babyheadcrab.mdl",true,NULL_STRING))
						{
							WritePackString(dp,"models/xenians/babyheadcrab.mdl");
							DispatchKeyValue(babycrab,"model","models/xenians/babyheadcrab.mdl");
						}
						else
						{
							WritePackString(dp,"models/xenians/headcrab.mdl");
							DispatchKeyValue(babycrab,"model","models/xenians/headcrab.mdl");
						}
						WritePackCell(dp,babycrab);
						WritePackString(dp,"npc_babycrab");
						CreateTimer(0.1,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
						TeleportEntity(babycrab,curorg,angs,NULL_VECTOR);
						DispatchSpawn(babycrab);
						ActivateEntity(babycrab);
						SetEntPropEnt(babycrab,Prop_Data,"m_hEffectEntity",entity);
						ChangeEdictState(babycrab);
					}
					int decal = CreateEntityByName("infodecal");
					if (decal != -1)
					{
						DispatchKeyValue(decal,"texture","decals/slime_acid_gon");
						TeleportEntity(decal,curorg,angs,NULL_VECTOR);
						DispatchSpawn(decal);
						ActivateEntity(decal);
						AcceptEntityInput(decal,"Activate");
					}
					timesattacked[entity]++;
					centnextatk[entity] = Time + 1.0;
					char snd[64];
					Format(snd,sizeof(snd),"gonarch\\gon_birth%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					int scriptseq = CreateEntityByName("scripted_sequence");
					if (scriptseq != -1)
					{
						char entname[64];
						GetEntPropString(entity,Prop_Data,"m_iName",entname,sizeof(entname));
						if (strlen(entname) < 1)
						{
							Format(entname,sizeof(entname),"gonarch%i",entity);
							SetEntPropString(entity,Prop_Data,"m_iName",entname);
						}
						DispatchKeyValue(scriptseq,"spawnflags","80");
						DispatchKeyValue(scriptseq,"m_iszEntity",entname);
						if (GetRandomInt(0,1) == 1) DispatchKeyValue(scriptseq,"m_iszPlay","BALLSACK");
						else DispatchKeyValue(scriptseq,"m_iszPlay","spawn");
						DispatchKeyValue(scriptseq,"m_fMoveTo","0");
						DispatchKeyValue(scriptseq,"m_flRadius","0");
						TeleportEntity(scriptseq,curorg,angs,NULL_VECTOR);
						DispatchSpawn(scriptseq);
						ActivateEntity(scriptseq);
						AcceptEntityInput(scriptseq,"BeginSequence");
						Handle dp = CreateDataPack();
						WritePackCell(dp,scriptseq);
						WritePackString(dp,"scripted_sequence");
						CreateTimer(1.0,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if ((centlastang[entity] < Time) && (chkdist > 100.0))
				{
					for (int i = GetRandomInt(1,MaxClients);i<MaxClients+1;i++)
					{
						if (i != targ)
						{
							if (IsClientConnected(i))
							{
								if (IsClientInGame(i))
								{
									if (IsPlayerAlive(i))
									{
										targ = i;
										break;
									}
								}
							}
						}
					}
					if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",targpos);
					else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",targpos);
					char snd[64];
					Format(snd,sizeof(snd),"gonarch\\gon_attack%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					int spitball = CreateEntityByName("generic_actor");
					if (spitball != -1)
					{
						DispatchKeyValue(spitball,"classname","prop_physics");
						float shootvel[3];
						float toang[3];
						targpos[2]-=50.0;
						MakeVectorFromPoints(curorg,targpos,shootvel);
						GetVectorAngles(shootvel,toang);
						//ScaleVector(shootvel,1.5);
						shootvel[2]+=140.0;
						curorg[2]+=190.0;
						if (GetRandomInt(0,1) == 1) DispatchKeyValue(spitball,"model","models/xen_props/gib/gon_spitgib1.mdl");
						else DispatchKeyValue(spitball,"model","models/xen_props/gon_spit.mdl");
						//DispatchKeyValue(spitball,"spawnflags","16");
						DispatchKeyValue(spitball,"solid","6");
						TeleportEntity(spitball,curorg,toang,NULL_VECTOR);
						DispatchSpawn(spitball);
						ActivateEntity(spitball);
						SetEntProp(spitball,Prop_Data,"m_MoveType",5);
						SetEntPropEnt(spitball,Prop_Data,"m_hEffectEntity",entity);
						int effect = CreateEntityByName("info_particle_system");
						if (effect != -1)
						{
							DispatchKeyValue(effect,"effect_name","spit_leak");
							DispatchKeyValue(effect,"start_active","1");
							TeleportEntity(effect,curorg,toang,NULL_VECTOR);
							DispatchSpawn(effect);
							ActivateEntity(effect);
							SetVariantString("!activator");
							AcceptEntityInput(effect,"SetParent",spitball);
							AcceptEntityInput(effect,"Start");
						}
						TeleportEntity(spitball,NULL_VECTOR,NULL_VECTOR,shootvel);
						HookSingleEntityOutput(spitball,"OnBreak",EntityOutput:GonarchSpitByBreak);
						SDKHook(spitball, SDKHook_StartTouch, StartTouchGonarchSpit);
						Handle dp = CreateDataPack();
						WritePackCell(dp,spitball);
						WritePackString(dp,"prop_physics");
						CreateTimer(10.0,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
						if (HasEntProp(spitball,Prop_Data,"m_bloodColor")) SetEntProp(spitball,Prop_Data,"m_bloodColor",3);
					}
					int scriptseq = CreateEntityByName("scripted_sequence");
					if (scriptseq != -1)
					{
						char entname[64];
						GetEntPropString(entity,Prop_Data,"m_iName",entname,sizeof(entname));
						if (strlen(entname) < 1)
						{
							Format(entname,sizeof(entname),"gonarch%i",entity);
							SetEntPropString(entity,Prop_Data,"m_iName",entname);
						}
						DispatchKeyValue(scriptseq,"spawnflags","80");
						DispatchKeyValue(scriptseq,"m_iszEntity",entname);
						if (GetRandomInt(0,1) == 1) DispatchKeyValue(scriptseq,"m_iszPlay","ACT_RANGE_ATTACK1");
						else DispatchKeyValue(scriptseq,"m_iszPlay","mortar");
						DispatchKeyValue(scriptseq,"m_fMoveTo","0");
						DispatchKeyValue(scriptseq,"m_flRadius","0");
						TeleportEntity(scriptseq,curorg,angs,NULL_VECTOR);
						DispatchSpawn(scriptseq);
						ActivateEntity(scriptseq);
						AcceptEntityInput(scriptseq,"BeginSequence");
						Handle dp = CreateDataPack();
						WritePackCell(dp,scriptseq);
						WritePackString(dp,"scripted_sequence");
						CreateTimer(1.0,cleanup,dp,TIMER_FLAG_NO_MAPCHANGE);
					}
					centlastang[entity] = Time + GetRandomFloat(2.0,6.0);
				}
				//ACT_RANGE_ATTACK1
				//models/xen_props/gib/gon_spitgib1.mdl
				//models/xen_props/gon_spit.mdl
				//info_particle_system spit_leak
			}
			else
			{
				float Time = GetTickedTime();
				if (centnextsndtime[entity] < Time)
				{
					char snd[64];
					Format(snd,sizeof(snd),"gonarch\\gon_sack%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					centnextsndtime[entity] = Time + 5.0;
				}
			}
		}
	}
}

public Action gonarchtkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
			if ((damage > curh) && (curh != 1))
			{
				AcceptEntityInput(victim,"StopScripting");
				if ((attacker > 0) && (attacker < MaxClients+1))
				{
					Handle entkilled = CreateEvent("synergy_entity_death");
					SetEventInt(entkilled,"killercolor",-16083416);
					SetEventInt(entkilled,"victimcolor",-16777041);
					char weap[24];
					GetClientWeapon(attacker,weap,sizeof(weap));
					char clsname2[32];
					if (IsValidEntity(inflictor)) GetEntityClassname(inflictor,clsname2,sizeof(clsname2));
					if (StrContains(clsname2,"npc_",false) != -1)
					{
						Format(weap,sizeof(weap),"%s",clsname2);
						ReplaceString(weap,sizeof(weap),"npc_","",false);
					}
					else if ((StrEqual(clsname2,"prop_physics",false)) || (StrEqual(clsname2,"rpg_missile",false)))
					{
						Format(weap,sizeof(weap),"%s",clsname2);
						ReplaceString(weap,sizeof(weap),"prop_","",false);
					}
					if (strlen(weap) < 1)
						Format(weap,sizeof(weap),"hands");
					else if (StrEqual(weap,"weapon_rpg",false))
					{
						Format(weap,sizeof(weap),"rpg_missile");
					}
					else
					{
						ReplaceString(weap,sizeof(weap),"weapon_","",false);
					}
					if (StrEqual(weap,"crossbow",false)) Format(weap,sizeof(weap),"crossbow_bolt");
					SetEventString(entkilled,"weapon",weap);
					SetEventInt(entkilled,"killerID",attacker);
					SetEventInt(entkilled,"victimID",victim);
					SetEventBool(entkilled,"suicide",false);
					char tmpchar[96];
					GetClientName(attacker,tmpchar,sizeof(tmpchar));
					SetEventString(entkilled,"killername",tmpchar);
					SetEventString(entkilled,"victimname","Gonarch");
					SetEventInt(entkilled,"iconcolor",-1052689);
					FireEvent(entkilled,false);
				}
				SetEntProp(victim,Prop_Data,"m_iHealth",1);
				damage = 0.0;
				AcceptEntityInput(victim,"StartScripting");
				int scriptseq = CreateEntityByName("scripted_sequence");
				if (scriptseq != -1)
				{
					float curorg[3];
					float angs[3];
					if (HasEntProp(victim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecAbsOrigin",curorg);
					else if (HasEntProp(victim,Prop_Send,"m_vecOrigin")) GetEntPropVector(victim,Prop_Send,"m_vecOrigin",curorg);
					GetEntPropVector(victim,Prop_Data,"m_angRotation",angs);
					char entname[64];
					GetEntPropString(victim,Prop_Data,"m_iName",entname,sizeof(entname));
					if (strlen(entname) < 1)
					{
						Format(entname,sizeof(entname),"gonarch%i",victim);
						SetEntPropString(victim,Prop_Data,"m_iName",entname);
					}
					DispatchKeyValue(scriptseq,"spawnflags","80");
					DispatchKeyValue(scriptseq,"m_iszEntity",entname);
					DispatchKeyValue(scriptseq,"m_iszPlay","falldeath");
					DispatchKeyValue(scriptseq,"m_fMoveTo","0");
					DispatchKeyValue(scriptseq,"m_flRadius","0");
					TeleportEntity(scriptseq,curorg,angs,NULL_VECTOR);
					DispatchSpawn(scriptseq);
					ActivateEntity(scriptseq);
					SetEntPropEnt(scriptseq,Prop_Data,"m_hEffectEntity",victim);
					AcceptEntityInput(scriptseq,"BeginSequence");
					HookSingleEntityOutput(scriptseq,"OnEndSequence",EntityOutput:gonarchdead);
					HookSingleEntityOutput(scriptseq,"OnCancelSequence",EntityOutput:gonarchdead);
				}
				return Plugin_Changed;
			}
			else if ((curh == 1) && (!isattacking[victim]))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			else if (HasEntProp(victim,Prop_Data,"m_nSequence"))
			{
				int seq = GetEntProp(victim,Prop_Data,"m_nSequence");
				if ((seq == 1) || (seq == 6))
				{
					SetEntProp(victim,Prop_Data,"m_nSequence",0);
				}
			}
			/*
			else
			{
				SetEntProp(victim,Prop_Data,"m_iHealth",curh-RoundFloat(damage));
				damage = 0.0;
				return Plugin_Changed;
			}
			*/
		}
	}
	return Plugin_Continue;
}

public gonarchdead(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		if (HasEntProp(caller,Prop_Data,"m_hEffectEntity"))
		{
			int ent = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
			if (IsValidEntity(ent))
			{
				isattacking[ent] = 1;
				SetVariantString("0");
				AcceptEntityInput(ent,"SetHealth");
			}
			AcceptEntityInput(caller,"kill");
		}
	}
}

public GonarchSpitByBreak(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		char clschk[24];
		GetEntityClassname(activator,clschk,sizeof(clschk));
		int attacker = GetEntPropEnt(caller,Prop_Data,"m_hEffectEntity");
		if ((StrContains(clschk,"npc_alien_",false) == -1) && (StrContains(clschk,"crab",false) == -1))
		{
			float damageForce[3];
			float dmgset = 20.0;
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			if ((attacker != 0) && (IsValidEntity(attacker))) SDKHooks_TakeDamage(activator,attacker,attacker,dmgset,DMG_ACID,-1,damageForce);
			else SDKHooks_TakeDamage(activator,caller,caller,dmgset,DMG_ACID,-1,damageForce);
		}
		int decal = CreateEntityByName("infodecal");
		if (decal != -1)
		{
			float curorg[3];
			float angs[3];
			if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",curorg);
			else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",curorg);
			GetEntPropVector(caller,Prop_Data,"m_angRotation",angs);
			DispatchKeyValue(decal,"texture","decals/slime_acid_gon");
			TeleportEntity(decal,curorg,angs,NULL_VECTOR);
			DispatchSpawn(decal);
			ActivateEntity(decal);
			AcceptEntityInput(decal,"Activate");
		}
	}
}

public Action StartTouchGonarchSpit(int entity, int other)
{
	if (IsValidEntity(other))
	{
		char clschk[24];
		GetEntityClassname(other,clschk,sizeof(clschk));
		int attacker = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if ((StrContains(clschk,"npc_alien_",false) == -1) && (StrContains(clschk,"crab",false) == -1))
		{
			float damageForce[3];
			float dmgset = 20.0;
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			if ((attacker != 0) && (IsValidEntity(attacker))) SDKHooks_TakeDamage(other,attacker,attacker,dmgset,DMG_ACID,-1,damageForce);
			else SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_ACID,-1,damageForce);
		}
	}
	if (IsValidEntity(entity))
	{
		float curorg[3];
		float angs[3];
		if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
		else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
		GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
		int decal = CreateEntityByName("infodecal");
		if (decal != -1)
		{
			DispatchKeyValue(decal,"texture","decals/slime_acid_gon");
			TeleportEntity(decal,curorg,angs,NULL_VECTOR);
			DispatchSpawn(decal);
			ActivateEntity(decal);
			AcceptEntityInput(decal,"Activate");
		}
		if (FindStringInArray(precachedarr,"npc_gonarch_spit") == -1)
		{
			PrecacheSound("physics\\flesh\\flesh_squishy_impact_hard1.wav",true);
			PrecacheSound("physics\\flesh\\flesh_squishy_impact_hard2.wav",true);
			PrecacheSound("physics\\flesh\\flesh_squishy_impact_hard3.wav",true);
			PrecacheSound("physics\\flesh\\flesh_squishy_impact_hard4.wav",true);
			PushArrayString(precachedarr,"npc_gonarch_spit");
		}
		int radiusdmg = CreateEntityByName("env_explosion");
		if (radiusdmg != -1)
		{
			TeleportEntity(radiusdmg,curorg,angs,NULL_VECTOR);
			DispatchKeyValue(radiusdmg,"imagnitude","30");
			DispatchKeyValue(radiusdmg,"targetname","syn_gonarchspit");
			DispatchKeyValue(radiusdmg,"iradiusoverride","150");
			DispatchKeyValue(radiusdmg,"spawnflags","9084");
			DispatchKeyValue(radiusdmg,"rendermode","0");
			int attacker = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			SetEntPropEnt(radiusdmg,Prop_Data,"m_hEffectEntity",attacker);
			DispatchSpawn(radiusdmg);
			ActivateEntity(radiusdmg);
			AcceptEntityInput(radiusdmg,"Explode");
		}
		char snd[128];
		Format(snd,sizeof(snd),"physics\\flesh\\flesh_squishy_impact_hard%i.wav",GetRandomInt(1,4));
		EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		AcceptEntityInput(entity,"kill");
	}
}