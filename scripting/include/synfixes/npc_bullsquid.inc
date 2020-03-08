void setupsquid(int entity)
{
	if ((IsValidEntity(entity)) && (entity != 0))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if ((StrEqual(cls,"npc_bullsquid",false)) || (StrEqual(cls,"monster_bullchicken",false)))
		{
			if (FindStringInArray(precachedarr,"npc_bullsquid") == -1)
			{
				PrecacheSound("npc/antlion/idle1.wav",true);
				PrecacheSound("npc/antlion/idle2.wav",true);
				PrecacheSound("npc/antlion/idle3.wav",true);
				PrecacheSound("npc/antlion/idle4.wav",true);
				PrecacheSound("npc/antlion/idle5.wav",true);
				PrecacheSound("npc/antlion/pain1.wav",true);
				PrecacheSound("npc/antlion/pain2.wav",true);
				PrecacheSound("npc/antlion/attack_single1.wav",true);
				PrecacheSound("npc/antlion/attack_single2.wav",true);
				PrecacheSound("npc/antlion/attack_single3.wav",true);
				recursion("sound/npc/bullsquid/");
				recursion("sound/bullchicken/");
				PushArrayString(precachedarr,"npc_bullsquid");
			}
			float orgs[3];
			float angs[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
			if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
			if (HasEntProp(entity,Prop_Data,"m_bDisableJump")) SetEntProp(entity,Prop_Data,"m_bDisableJump",1);
			if (HasEntProp(entity,Prop_Data,"m_bAgitatedSound")) SetEntProp(entity,Prop_Data,"m_bAgitatedSound",0);
			PushArrayCell(squids,entity);
			int entmdl = CreateEntityByName("prop_dynamic");
			if (StrEqual(cls,"npc_bullsquid",false))
			{
				DispatchKeyValue(entmdl,"model","models/xenians/bullsquid.mdl");
			}
			else
			{
				DispatchKeyValue(entmdl,"model","models/bullsquid.mdl");
			}
			DispatchKeyValue(entmdl,"solid","0");
			float tmpset[3];
			tmpset[0] = orgs[0];
			tmpset[1] = orgs[1];
			tmpset[2] = orgs[2]-5.0;
			TeleportEntity(entmdl,tmpset,angs,NULL_VECTOR);
			DispatchSpawn(entmdl);
			ActivateEntity(entmdl);
			SetVariantString("!activator");
			AcceptEntityInput(entmdl,"SetParent",entity);
			PushArrayCell(squidsmdl,entmdl);
			SDKHookEx(entity,SDKHook_Think,squidthink);
			SDKHookEx(entity,SDKHook_OnTakeDamage,squidtkdmg);
			HookSingleEntityOutput(entity,"OnDeath",EntityOutput:OnCDeath);
			SetVariantString("0.5");
			AcceptEntityInput(entity,"SetModelScale");
			AcceptEntityInput(entity,"GagEnable");
			Handle dp = CreateDataPack();
			if (StrEqual(cls,"monster_bullchicken",false))
			{
				if (!IsModelPrecached("models/bullsquid.mdl")) PrecacheModel("models/bullsquid.mdl",true);
				WritePackString(dp,"models/bullsquid.mdl");
			}
			else
			{
				if (!IsModelPrecached("models/xenians/bullsquid.mdl")) PrecacheModel("models/xenians/bullsquid.mdl",true);
				WritePackString(dp,"models/xenians/bullsquid.mdl");
			}
			WritePackCell(dp,entity);
			WritePackString(dp,cls);
			CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
			customents = true;
		}
	}
}

void squidthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int mdlarr = FindValueInArray(squids,entity);
			if (mdlarr != -1)
			{
				int entmdl = GetArrayCell(squidsmdl,mdlarr);
				if ((IsValidEntity(entmdl)) && (HasEntProp(entity,Prop_Data,"m_nSequence")))
				{
					int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
					float Time = GetTickedTime();
					if (breaksnd[entity] > Time)
					{
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/pain1.wav");
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/pain2.wav");
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/idle1.wav");
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/idle2.wav");
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/idle3.wav");
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/idle4.wav");
						StopSound(entity,SNDCHAN_VOICE,"npc/antlion/idle5.wav");
						StopSound(entity,SNDCHAN_WEAPON,"npc/antlion/attack_single1.wav");
						StopSound(entity,SNDCHAN_WEAPON,"npc/antlion/attack_single2.wav");
						StopSound(entity,SNDCHAN_WEAPON,"npc/antlion/attack_single3.wav");
					}
					char mdl[64];
					GetEntPropString(entmdl,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
					int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
					int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
					if ((seq == 0) && (statechk == 3)) SetEntProp(entity,Prop_Data,"m_NPCState",2);
					if (GetEntProp(entity,Prop_Data,"m_iVolume") > 0) SetEntProp(entity,Prop_Data,"m_iVolume",0);
					if (!isattacking[entity])
					{
						int seqmdl = GetEntProp(entmdl,Prop_Data,"m_nSequence");
						if (seqmdl != seq)
						{
							SetEntProp(entmdl,Prop_Data,"m_nSequence",seq);
							switch(seq)
							{
								case 1:
								{
									SetVariantString("run");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 2:
								{
									SetVariantString("walk");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 3:
								{
									SetVariantString("turnL");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 4:
								{
									SetVariantString("turnR");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 5:
								{
									SetVariantString("turn180");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 6:
								{
									SetVariantString("idle");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 7:
								{
									if (StrEqual(mdl,"models/bullsquid.mdl",false)) SetVariantString("idle");
									else SetVariantString("idle2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 8:
								{
									if (StrEqual(mdl,"models/bullsquid.mdl",false)) SetVariantString("idle1");
									else SetVariantString("idle3");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 9:
								{
									SetVariantString("idle_combat");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 10:
								{
									SetVariantString("eat");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 11:
								{
									if (StrEqual(mdl,"models/bullsquid.mdl",false)) SetVariantString("whip");
									else SetVariantString("spin_whip");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 12:
								{
									SetVariantString("bite");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 13:
								{
									SetVariantString("bite2");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
								case 14:
								{
									SetVariantString("range");
									AcceptEntityInput(entmdl,"SetAnimation");
								}
							}
						}
						SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
						SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
						//SetEntityRenderMode(entity,RENDER_NONE);
						//SetEntityRenderMode(entmdl,RENDER_NORMAL);
					}
					if ((targ != -1) && (IsValidEntity(targ)) && (!isattacking[entity]) && (centnextatk[entity] < Time))
					{
						breaksnd[entity] = GetTickedTime()+0.5;
						float curorg[3];
						float enorg[3];
						if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
						if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
						else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
						float chkdist = GetVectorDistance(curorg,enorg,false);
						float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
						float whiprange = 165.0;
						float biterange = 100.0;
						float spitrange = 1200.0;
						Handle cvarchk = FindConVar("sk_bullsquid_whip_range");
						if (cvarchk != INVALID_HANDLE)
							whiprange = GetConVarFloat(cvarchk);
						cvarchk = FindConVar("sk_bullsquid_bite_range");
						if (cvarchk != INVALID_HANDLE)
							biterange = GetConVarFloat(cvarchk);
						cvarchk = FindConVar("sk_bullsquid_spit_range");
						if (cvarchk != INVALID_HANDLE)
							spitrange = GetConVarFloat(cvarchk);
						CloseHandle(cvarchk);
						if (chkdist <= biterange)
						{
							int rand = GetRandomInt(0,1);
							if (StrEqual(mdl,"models/bullsquid.mdl",false)) rand = 0;
							if (rand == 0)
							{
								SetVariantString("bite");
								AcceptEntityInput(entmdl,"SetAnimation");
							}
							else
							{
								SetVariantString("bite2");
								AcceptEntityInput(entmdl,"SetAnimation");
							}
							SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
							SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
							isattacking[entity] = true;
							centnextatk[entity] = Time+0.5;
							float damageForce[3];
							float dmgset = 25.0;
							float dmgforce = 20.0;
							Handle squidbite = FindConVar("sk_bullsquid_bite_dmg");
							if (squidbite != INVALID_HANDLE)
								dmgset = GetConVarFloat(squidbite);
							CloseHandle(squidbite);
							damageForce[0] = dmgforce;
							damageForce[1] = dmgforce;
							damageForce[2] = dmgforce;
							SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
							CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
							if (StrContains(mapbuf,"bm_bm_c",false) == -1)
							{
								char snd[64];
								if (StrEqual(mdl,"models/bullsquid.mdl",false)) Format(snd,sizeof(snd),"bullchicken\\bc_bite%i.wav",GetRandomInt(1,3));
								else Format(snd,sizeof(snd),"npc\\bullsquid\\attack%i.wav",GetRandomInt(1,2));
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
							}
						}
						else if (chkdist <= whiprange)
						{
							if (StrEqual(mdl,"models/bullsquid.mdl",false)) SetVariantString("whip");
							else SetVariantString("spin_whip");
							AcceptEntityInput(entmdl,"SetAnimation");
							SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
							SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
							isattacking[entity] = true;
							centnextatk[entity] = Time+0.5;
							float damageForce[3];
							float dmgset = 35.0;
							float dmgforce = 450.0;
							Handle squidwhip = FindConVar("sk_bullsquid_whip_dmg");
							if (squidwhip != INVALID_HANDLE)
								dmgset = GetConVarFloat(squidwhip);
							CloseHandle(squidwhip);
							Handle squidforce = FindConVar("sk_bullsquid_whip_force");
							if (squidforce != INVALID_HANDLE)
								dmgforce = GetConVarFloat(squidforce);
							CloseHandle(squidforce);
							damageForce[0] = dmgforce;
							damageForce[1] = dmgforce;
							damageForce[2] = dmgforce;
							SDKHooks_TakeDamage(targ,entity,entity,dmgset,DMG_CLUB,-1,damageForce,curorg);
							CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
							if (StrContains(mapbuf,"bm_bm_c",false) == -1)
							{
								char snd[64];
								if (StrEqual(mdl,"models/bullsquid.mdl",false))
								{
									int rand = GetRandomInt(1,3);
									if (rand == 1) Format(snd,sizeof(snd),"bullchicken\\bc_attackgrowl.wav");
									else Format(snd,sizeof(snd),"bullchicken\\bc_attackgrowl%i.wav",rand);
								}
								else Format(snd,sizeof(snd),"npc\\bullsquid\\tailswing%i.wav",GetRandomInt(1,2));
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
							}
						}
						else if ((chkdist <= spitrange) && (chkdist > 300.0) && (lastsaw > lastseen[entity]))
						{
							lastseen[entity] = lastsaw;
							SetVariantString("range");
							AcceptEntityInput(entmdl,"SetAnimation");
							SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
							SetEntProp(entmdl,Prop_Data,"m_nRenderFX",0);
							isattacking[entity] = true;
							centnextatk[entity] = Time+2.0;
							float dmgset = 5.0;
							Handle spitdmg = FindConVar("sk_bullsquid_spit_dmg");
							if (spitdmg != INVALID_HANDLE)
								dmgset = GetConVarFloat(spitdmg);
							CloseHandle(spitdmg);
							float angs[3];
							float loc[3];
							enorg[2]+=310.0;
							if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
							for (int i = 0;i<3;i++)
							{
								int randpos = GetRandomInt(70,80);
								loc[0] = (curorg[0] + (randpos * Cosine(DegToRad(angs[1]))));
								loc[1] = (curorg[1] + (randpos * Sine(DegToRad(angs[1]))));
								loc[2] = (curorg[2] + 25);
								float shootvel[3];
								MakeVectorFromPoints(loc,enorg,shootvel);
								float randheight = GetRandomFloat(30.0,40.0);
								//if (shootvel[2] < 0.0) shootvel[2]+=randheight;
								shootvel[2]+=randheight;
								int randside = GetRandomInt(0,4);
								float randamnt = GetRandomFloat(10.0,45.0);
								if (randside == 1) shootvel[0]+=randamnt;
								else if (randside == 2) shootvel[0]-=randamnt;
								else if (randside == 3) shootvel[1]+=randamnt;
								else if (randside == 4) shootvel[1]-=randamnt;
								//float randscale = GetRandomFloat(1.0,1.5);
								//ScaleVector(shootvel,randscale);
								//Blocked in Synergy 20.x forward
								int spitball = CreateEntityByName("grenade_spit");
								if (spitball != -1)
								{
									if (!FileExists("models/spitball_large.mdl",true,NULL_STRING)) DispatchKeyValue(spitball,"RenderMode","10");
									DispatchSpawn(spitball);
									ActivateEntity(spitball);
									SetEntPropEnt(spitball,Prop_Data,"m_hThrower",entity);
									SetEntPropFloat(spitball,Prop_Data,"m_flDamage",dmgset);
									TeleportEntity(spitball,loc,angs,shootvel);
								}
								/*
								int spitball = CreateEntityByName("generic_actor");
								if (spitball != -1)
								{
									DispatchKeyValue(spitball,"model","models/spitball_large.mdl");
									if (!FileExists("models/spitball_large.mdl",true,NULL_STRING)) DispatchKeyValue(spitball,"RenderMode","10");
									DispatchKeyValue(spitball,"classname","grenade_spit");
									DispatchKeyValue(spitball,"solid","6");
									TeleportEntity(spitball,loc,angs,shootvel);
									DispatchSpawn(spitball);
									ActivateEntity(spitball);
									SetEntProp(spitball,Prop_Data,"m_MoveType",5);
									SetEntPropEnt(spitball,Prop_Data,"m_hEffectEntity",entity);
									SDKHook(spitball, SDKHook_StartTouch, StartTouchBullSquidSpit);
									TeleportEntity(spitball,NULL_VECTOR,NULL_VECTOR,shootvel);
									if (HasEntProp(spitball,Prop_Data,"m_bloodColor")) SetEntProp(spitball,Prop_Data,"m_bloodColor",3);
									if (HasEntProp(spitball,Prop_Data,"m_bInvulnerable")) SetEntProp(spitball,Prop_Data,"m_bInvulnerable",1);
								}
								*/
							}
							if (StrContains(mapbuf,"bm_bm_c",false) == -1)
							{
								char snd[64];
								if (StrEqual(mdl,"models/bullsquid.mdl",false)) Format(snd,sizeof(snd),"bullchicken\\bc_attack%i.wav",GetRandomInt(2,3));
								else Format(snd,sizeof(snd),"npc\\bullsquid\\goo_attack%i.wav",GetRandomInt(1,3));
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
							}
							CreateTimer(0.8,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
}

public Action squidtkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((IsValidEntity(victim)) && (IsValidEntity(attacker)))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			StopSound(victim,SNDCHAN_VOICE,"npc/antlion/pain1.wav");
			StopSound(victim,SNDCHAN_VOICE,"npc/antlion/pain2.wav");
			breaksnd[victim] = GetTickedTime()+0.5;
			if ((GetEntProp(victim,Prop_Data,"m_iHealth") - damage) < 1)
			{
				if ((StrContains(mapbuf,"bm_c",false) == -1) && (StrContains(mapbuf,"xen_c",false) == -1) && (StrContains(mapbuf,"bm_damo",false) == -1))
					if (HasEntProp(victim,Prop_Data,"m_bForceServerRagdoll")) SetEntProp(victim,Prop_Data,"m_bForceServerRagdoll",1);
			}
			if (IsEntNetworkable(attacker))
			{
				char clschk[24];
				GetEntityClassname(attacker,clschk,sizeof(clschk));
				if (StrEqual(clschk,"grenade_spit",false))
				{
					int ownent = GetEntPropEnt(attacker,Prop_Data,"m_hThrower");
					if (ownent == victim)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
					else if ((IsValidEntity(ownent)) && (IsEntNetworkable(ownent)))
					{
						GetEntityClassname(ownent,clschk,sizeof(clschk));
						if (StrEqual(clschk,"npc_bullsquid",false))
						{
							damage = 0.0;
							return Plugin_Changed;
						}
					}
				}
				else if ((attacker == victim) || (StrEqual(clschk,"npc_bullsquid",false)))
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
			if (damage > 1.0)
			{
				char mdl[32];
				GetEntPropString(victim,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
				char snd[64];
				if (StrEqual(mdl,"models/bullsquid.mdl",false)) Format(snd,sizeof(snd),"bullchicken\\bc_pain%i.wav",GetRandomInt(1,4));
				else Format(snd,sizeof(snd),"npc\\bullsquid\\pain%i.wav",GetRandomInt(1,5));
				EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			}
		}
	}
	return Plugin_Continue;
}
/*
public Action StartTouchBullSquidSpit(int entity, int other)
{
	if (IsValidEntity(other))
	{
		char clschk[24];
		GetEntityClassname(other,clschk,sizeof(clschk));
		int attacker = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if ((!StrEqual(clschk,"npc_bullsquid",false)) && (!StrEqual(clschk,"grenade_spit",false)))
		{
			float damageForce[3];
			float dmgset = 5.0;
			Handle spitdmg = FindConVar("sk_bullsquid_spit_dmg");
			if (spitdmg != INVALID_HANDLE)
				dmgset = GetConVarFloat(spitdmg);
			CloseHandle(spitdmg);
			float dmgforce = 5.0;
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			if ((attacker != 0) && (IsValidEntity(attacker))) SDKHooks_TakeDamage(other,attacker,attacker,dmgset,DMG_ACID,-1,damageForce);
			else SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_ACID,-1,damageForce);
		}
		else return Plugin_Continue;
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
			int rand = GetRandomInt(1,4);
			char slimetex[64];
			if (rand == 1) Format(slimetex,sizeof(slimetex),"decals/slime_splat");
			else Format(slimetex,sizeof(slimetex),"decals/slime_splat_0%i",rand);
			DispatchKeyValue(decal,"texture",slimetex);
			TeleportEntity(decal,curorg,angs,NULL_VECTOR);
			DispatchSpawn(decal);
			ActivateEntity(decal);
			AcceptEntityInput(decal,"Activate");
		}
		if (FindStringInArray(precachedarr,"npc_bullsquid") == -1)
		{
			PrecacheSound("npc\\bullsquid\\splat1.wav",true);
			PrecacheSound("npc\\bullsquid\\splat2.wav",true);
			PushArrayString(precachedarr,"npc_bullsquid");
		}
		int radiusdmg = CreateEntityByName("env_explosion");
		if (radiusdmg != -1)
		{
			char bullradius[8];
			float dmgset = 5.0;
			Handle spitdmg = FindConVar("sk_bullsquid_spit_dmg");
			if (spitdmg != INVALID_HANDLE)
				dmgset = GetConVarFloat(spitdmg);
			CloseHandle(spitdmg);
			Format(bullradius,sizeof(bullradius),"%1.f",dmgset/2);
			TeleportEntity(radiusdmg,curorg,angs,NULL_VECTOR);
			DispatchKeyValue(radiusdmg,"imagnitude",bullradius);
			DispatchKeyValue(radiusdmg,"targetname","syn_gonarchspit");
			DispatchKeyValue(radiusdmg,"iradiusoverride","30");
			DispatchKeyValue(radiusdmg,"spawnflags","9084");
			DispatchKeyValue(radiusdmg,"rendermode","0");
			int attacker = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
			SetEntPropEnt(radiusdmg,Prop_Data,"m_hEffectEntity",attacker);
			DispatchSpawn(radiusdmg);
			ActivateEntity(radiusdmg);
			AcceptEntityInput(radiusdmg,"Explode");
		}
		char snd[128];
		Format(snd,sizeof(snd),"npc\\bullsquid\\splat%i.wav",GetRandomInt(1,2));
		EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
		AcceptEntityInput(entity,"kill");
	}
	return Plugin_Continue;
}
*/