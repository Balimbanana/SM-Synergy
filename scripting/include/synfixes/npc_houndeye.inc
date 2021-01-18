void setuphound(int entity)
{
	if ((IsValidEntity(entity)) && (entity != 0))
	{
		char cls[32];
		GetEntityClassname(entity,cls,sizeof(cls));
		if ((StrEqual(cls,"npc_houndeye",false)) || (StrEqual(cls,"monster_houndeye",false)))
		{
			if (StrEqual(cls,"npc_houndeye",false))
			{
				if (FileExists("models/_monsters/xen/houndeye.mdl",true,NULL_STRING))
				{
					if (!IsModelPrecached("models/_monsters/xen/houndeye.mdl")) PrecacheModel("models/_monsters/xen/houndeye.mdl",true);
				}
				else
				{
					if (!IsModelPrecached("models/xenians/houndeye.mdl")) PrecacheModel("models/xenians/houndeye.mdl",true);
				}
			}
			else
			{
				if (!IsModelPrecached("models/houndeye.mdl")) PrecacheModel("models/houndeye.mdl",true);
			}
			if (FindStringInArray(precachedarr,"npc_houndeye") == -1)
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
				PrecacheSound("npc\\houndeye\\blast1.wav",true);
				PrecacheSound("npc\\houndeye\\he_step1.wav",true);
				PrecacheSound("npc\\houndeye\\he_step2.wav",true);
				PrecacheSound("npc\\houndeye\\he_step3.wav",true);
				PrecacheSound("npc\\houndeye\\charge1.wav",true);
				PrecacheSound("npc\\houndeye\\charge2.wav",true);
				PrecacheSound("npc\\houndeye\\charge3.wav",true);
				PrecacheSound("npc\\houndeye\\die1.wav",true);
				PrecacheSound("npc\\houndeye\\pain1.wav",true);
				PrecacheSound("npc\\houndeye\\pain2.wav",true);
				PrecacheSound("npc\\houndeye\\pain3.wav",true);
				if (FileExists("sound/npc/houndeye/he_pain1.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_pain1.wav",true);
				if (FileExists("sound/npc/houndeye/he_pain2.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_pain2.wav",true);
				if (FileExists("sound/npc/houndeye/he_pain3.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_pain3.wav",true);
				if (FileExists("sound/npc/houndeye/he_pain4.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_pain4.wav",true);
				if (FileExists("sound/npc/houndeye/he_pain5.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_pain5.wav",true);
				if (FileExists("sound/npc/houndeye/he_die1.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_die1.wav",true);
				if (FileExists("sound/npc/houndeye/he_die2.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_die2.wav",true);
				if (FileExists("sound/npc/houndeye/he_die3.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_die3.wav",true);
				if (FileExists("sound/npc/houndeye/he_blast1.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_blast1.wav",true);
				if (FileExists("sound/npc/houndeye/he_blast2.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_blast2.wav",true);
				if (FileExists("sound/npc/houndeye/he_blast3.wav",true,NULL_STRING)) PrecacheSound("npc\\houndeye\\he_blast3.wav",true);
				if (FileExists("sound/houndeye/he_attack1.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_attack1.wav",true);
				if (FileExists("sound/houndeye/he_attack2.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_attack2.wav",true);
				if (FileExists("sound/houndeye/he_attack3.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_attack3.wav",true);
				if (FileExists("sound/houndeye/he_blast1.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_blast1.wav",true);
				if (FileExists("sound/houndeye/he_blast2.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_blast2.wav",true);
				if (FileExists("sound/houndeye/he_blast3.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_blast3.wav",true);
				if (FileExists("sound/houndeye/he_die1.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_die1.wav",true);
				if (FileExists("sound/houndeye/he_die2.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_die2.wav",true);
				if (FileExists("sound/houndeye/he_die3.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_die3.wav",true);
				if (FileExists("sound/houndeye/he_pain1.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_pain1.wav",true);
				if (FileExists("sound/houndeye/he_pain2.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_pain2.wav",true);
				if (FileExists("sound/houndeye/he_pain3.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_pain3.wav",true);
				if (FileExists("sound/houndeye/he_pain4.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_pain4.wav",true);
				if (FileExists("sound/houndeye/he_pain5.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_pain5.wav",true);
				if (FileExists("sound/houndeye/he_hunt1.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_hunt1.wav",true);
				if (FileExists("sound/houndeye/he_hunt2.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_hunt2.wav",true);
				if (FileExists("sound/houndeye/he_hunt3.wav",true,NULL_STRING)) PrecacheSound("houndeye\\he_hunt3.wav",true);
				PushArrayString(precachedarr,"npc_houndeye");
			}
			float orgs[3];
			float angs[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
			if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
			if (HasEntProp(entity,Prop_Data,"m_bDisableJump")) SetEntProp(entity,Prop_Data,"m_bDisableJump",1);
			if (HasEntProp(entity,Prop_Data,"m_bAgitatedSound")) SetEntProp(entity,Prop_Data,"m_bAgitatedSound",0);
			if (FindValueInArray(hounds,entity) == -1)
			{
				PushArrayCell(hounds,entity);
				int entmdl = CreateEntityByName("prop_dynamic");
				if (StrEqual(cls,"npc_houndeye",false))
				{
					if (FileExists("models/_monsters/xen/houndeye.mdl",true,NULL_STRING)) DispatchKeyValue(entmdl,"model","models/_monsters/xen/houndeye.mdl");
					else DispatchKeyValue(entmdl,"model","models/xenians/houndeye.mdl");
				}
				else
				{
					DispatchKeyValue(entmdl,"model","models/houndeye.mdl");
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
				PushArrayCell(houndsmdl,entmdl);
				SDKHookEx(entity,SDKHook_Think,houndthink);
				SDKHookEx(entity,SDKHook_OnTakeDamage,houndtkdmg);
				HookSingleEntityOutput(entity,"OnDeath",EntityOutput:OnCDeath);
				char houndtargn[64];
				int boundbox = CreateEntityByName("generic_actor");
				if (boundbox != -1)
				{
					Format(houndtargn,sizeof(houndtargn),"syn_houndmdls%i",boundbox);
					if (StrEqual(cls,"npc_houndeye",false))
					{
						if (FileExists("models/_monsters/xen/houndeye.mdl",true,NULL_STRING)) DispatchKeyValue(boundbox,"model","models/_monsters/xen/houndeye.mdl");
						else DispatchKeyValue(boundbox,"model","models/xenians/houndeye.mdl");
					}
					else
					{
						DispatchKeyValue(boundbox,"model","models/houndeye.mdl");
					}
					DispatchKeyValue(boundbox,"targetname",houndtargn);
					DispatchKeyValue(boundbox,"solid","6");
					DispatchKeyValue(boundbox,"modelscale","1.2");
					DispatchKeyValue(boundbox,"rendermode","10");
					DispatchKeyValue(boundbox,"renderfx","6");
					DispatchKeyValue(boundbox,"renderamt","0");
					tmpset[2] = orgs[2]+5.0;
					TeleportEntity(boundbox,tmpset,angs,NULL_VECTOR);
					DispatchSpawn(boundbox);
					ActivateEntity(boundbox);
					SetVariantString("!activator");
					AcceptEntityInput(boundbox,"SetParent",entity);
					SetEntProp(boundbox,Prop_Data,"m_bloodColor",2);
					SetEntProp(boundbox,Prop_Data,"m_iHealth",1000);
					SetEntProp(boundbox,Prop_Data,"m_iMaxHealth",1000);
					SDKHookEx(boundbox,SDKHook_OnTakeDamage,houndbboxtkdmg);
					SetEntPropEnt(entity,Prop_Data,"m_hEffectEntity",boundbox);
				}
				char targn[64];
				char restoretn[64];
				if (HasEntProp(entity,Prop_Data,"m_iName")) GetEntPropString(entity,Prop_Data,"m_iName",targn,sizeof(targn));
				if (strlen(targn) < 1)
				{
					Format(targn,sizeof(targn),"syn_hounds%i",entity);
					SetEntPropString(entity,Prop_Data,"m_iName",targn);
				}
				else
				{
					Format(restoretn,sizeof(restoretn),"%s",targn);
					Format(targn,sizeof(targn),"syn_hounds%i",entity);
					SetEntPropString(entity,Prop_Data,"m_iName",targn);
					char targadd[72];
					Format(targadd,sizeof(targadd),"targetname %s",targn);
					SetVariantString(targadd);
					AcceptEntityInput(entity,"AddOutput");
				}
				int logcoll = CreateEntityByName("logic_collision_pair");
				if (logcoll != -1)
				{
					DispatchKeyValue(logcoll,"attach1",targn);
					DispatchKeyValue(logcoll,"attach2",houndtargn);
					DispatchKeyValue(logcoll,"StartDisabled","1");
					DispatchSpawn(logcoll);
					ActivateEntity(logcoll);
				}
				if (!relsethound)
				{
					setuprelations("npc_houndeye");
					relsethound = true;
				}
				SetVariantString("0.6");
				AcceptEntityInput(entity,"SetModelScale");
				Handle dp = CreateDataPack();
				if (StrEqual(cls,"npc_houndeye",false))
				{
					if (FileExists("models/_monsters/xen/houndeye.mdl",true,NULL_STRING)) WritePackString(dp,"models/_monsters/xen/houndeye.mdl");
					else WritePackString(dp,"models/xenians/houndeye.mdl");
				}
				else
				{
					WritePackString(dp,"models/houndeye.mdl");
				}
				WritePackCell(dp,entity);
				WritePackString(dp,cls);
				CreateTimer(0.5,resetmdl,dp,TIMER_FLAG_NO_MAPCHANGE);
				if (strlen(restoretn) > 0)
				{
					if ((IsValidEntity(logcoll)) && (logcoll != 0)) AcceptEntityInput(logcoll,"DisableCollisions");
					Handle dppass = CreateDataPack();
					WritePackString(dppass,restoretn);
					WritePackCell(dppass,entity);
					WritePackCell(dppass,logcoll);
					CreateTimer(0.1,restoretargn,dppass,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			customents = true;
		}
	}
}

void houndthink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int mdlarr = FindValueInArray(hounds,entity);
			if (mdlarr != -1)
			{
				int houndmdl = GetArrayCell(houndsmdl,mdlarr);
				if (IsValidEntity(houndmdl))
				{
					if (HasEntProp(entity,Prop_Data,"m_nSequence"))
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
						if ((isattacking[entity]) && (centnextatk[entity] > Time))
						{
							if ((IsValidEntity(matmod)) && (matmod != 0) && (matmod != -1))
							{
								int chargei = RoundFloat((1.7-(centnextatk[entity]-Time))*100.0);
								if (chargei < 1) chargei = 1;
								char charge[8];
								Format(charge,sizeof(charge),"%i",chargei);
								SetVariantString(charge);
								AcceptEntityInput(matmod,"SetMaterialVar");
							}
							else
							{
								matmod = CreateEntityByName("material_modify_control");
								if (matmod == -1) matmod = 0;
								else
								{
									int propstat = CreateEntityByName("prop_dynamic");
									DispatchKeyValue(propstat,"rendermode","10");
									DispatchKeyValue(propstat,"renderfx","5");
									DispatchKeyValue(propstat,"targetname","syn_matmodprop");
									DispatchKeyValue(propstat,"model","models/xenians/houndeye.mdl");
									DispatchKeyValue(propstat,"solid","0");
									DispatchSpawn(propstat);
									ActivateEntity(propstat);
									DispatchKeyValue(matmod,"targetname","syn_matmodmod");
									DispatchKeyValue(matmod,"materialName","models/xenians/houndeye/houndeye.vmt");
									DispatchKeyValue(matmod,"materialVar","$selfillumtint");
									DispatchSpawn(matmod);
									ActivateEntity(matmod);
									SetVariantString("!activator");
									AcceptEntityInput(matmod,"SetParent",propstat);
									SetVariantString("Attachment01");
									AcceptEntityInput(matmod,"SetParentAttachment");
								}
							}
						}
						char cls[24];
						GetEntityClassname(entity,cls,sizeof(cls));
						if ((targ != -1) && (IsValidEntity(targ)) && (!isattacking[entity]) && (centnextatk[entity] < Time))
						{
							float curorg[3];
							float enorg[3];
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
							if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
							else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
							float chkdist = GetVectorDistance(curorg,enorg,false);
							if (chkdist < 120.0)
							{
								SetEntPropEnt(entity,Prop_Data,"m_hEnemy",-1);
								/*
								float resetorgs[3];
								SetEntPropVector(houndmdl,Prop_Data,"m_vecOrigin",resetorgs);
								int scriptseq = CreateEntityByName("scripted_sequence");
								if (scriptseq != -1)
								{
									char targn[64];
									if (HasEntProp(houndmdl,Prop_Data,"m_iName")) GetEntPropString(houndmdl,Prop_Data,"m_iName",targn,sizeof(targn));
									if (strlen(targn) < 1)
									{
										Format(targn,sizeof(targn),"syn_houndmdls%i",houndmdl);
										SetEntPropString(houndmdl,Prop_Data,"m_iName",targn);
									}
									DispatchKeyValue(scriptseq,"m_iszEntity",targn);
									DispatchKeyValue(scriptseq,"m_flRadius","0");
									DispatchKeyValue(scriptseq,"m_fMoveTo","0");
									DispatchKeyValue(scriptseq,"spawnflags","4336");
									DispatchKeyValue(scriptseq,"m_iszPlay","attack");
									DispatchKeyValue(scriptseq,"targetname","syn_houndseq");
									DispatchSpawn(scriptseq);
									ActivateEntity(scriptseq);
									AcceptEntityInput(scriptseq,"BeginSequence");
									Handle dp = CreateDataPack();
									WritePackCell(dp,scriptseq);
									WritePackString(dp,"scripted_sequence");
									CreateTimer(0.1,cleanup,dp);
								}
								*/
								SetVariantString("attack");
								AcceptEntityInput(houndmdl,"SetAnimation");
								SetVariantString("nullfil");
								AcceptEntityInput(entity,"SetEnemyFilter");
								SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
								SetEntProp(houndmdl,Prop_Data,"m_nRenderFX",0);
								//SetEntityRenderMode(entity,RENDER_NONE);
								//SetEntityRenderMode(houndmdl,RENDER_NORMAL);
								isattacking[entity] = true;
								centnextatk[entity] = Time+2.0;
								int rand = GetRandomInt(1,3);
								char snd[64];
								if (StrEqual(cls,"npc_houndeye",false)) Format(snd,sizeof(snd),"npc\\houndeye\\charge%i.wav",rand);
								else Format(snd,sizeof(snd),"houndeye\\he_attack%i.wav",rand);
								EmitSoundToAll(snd, entity, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
								CreateTimer(1.6,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
								if ((IsValidEntity(matmod)) && (matmod != 0) && (matmod != -1))
								{
									SetVariantString("0");
									AcceptEntityInput(matmod,"SetMaterialVar");
								}
							}
						}
						int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
						int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
						if ((seq == 0) && (statechk == 3)) SetEntProp(entity,Prop_Data,"m_NPCState",2);
						if (seq == 0)
						{
							if (!isattacking[entity])
							{
								char mdl[64];
								if (HasEntProp(houndmdl,Prop_Data,"m_ModelName")) GetEntPropString(houndmdl,Prop_Data,"m_ModelName",mdl,sizeof(mdl));
								if (StrEqual(mdl,"models/houndeye.mdl",false))
								{
									char randidle[16];
									Format(randidle,sizeof(randidle),"idle%i",GetRandomInt(1,3));
									SetVariantString(randidle);
									AcceptEntityInput(houndmdl,"SetAnimation");
								}
								else
								{
									SetVariantString("idle4");
									AcceptEntityInput(houndmdl,"SetAnimation");
								}
							}
							SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
							SetEntProp(houndmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(houndmdl,RENDER_NORMAL);
						}
						else if (!isattacking[entity])
						{
							int seqmdl = GetEntProp(houndmdl,Prop_Data,"m_nSequence");
							if (seqmdl != seq)
							{
								SetEntProp(houndmdl,Prop_Data,"m_nSequence",seq);
								ChangeEdictState(houndmdl);
								/*
								char anim[32];
								Format(anim,sizeof(anim),"idle4");
								switch(seq)
								{
									case 0:
										Format(anim,sizeof(anim),"ragdoll");
									case 1:
										Format(anim,sizeof(anim),"idle4");
									case 2:
										Format(anim,sizeof(anim),"run");
									case 3:
										Format(anim,sizeof(anim),"die");
									case 4:
										Format(anim,sizeof(anim),"die1");
									case 5:
										Format(anim,sizeof(anim),"die2");
									case 6:
										Format(anim,sizeof(anim),"die3");
									case 7:
										Format(anim,sizeof(anim),"attack");
									case 8:
										Format(anim,sizeof(anim),"attack2");
									case 9:
										Format(anim,sizeof(anim),"attack3");
									case 10:
										Format(anim,sizeof(anim),"falling");
									case 11:
										Format(anim,sizeof(anim),"flinch_small");
									case 12:
										Format(anim,sizeof(anim),"flinch_small2");
									case 13:
										Format(anim,sizeof(anim),"die_crumple");
									case 14:
										Format(anim,sizeof(anim),"running_junp");
									case 15:
										Format(anim,sizeof(anim),"walk_limp");
									case 16:
										Format(anim,sizeof(anim),"walk_limp2");
									case 17:
										Format(anim,sizeof(anim),"walk_limp3");
									case 18:
										Format(anim,sizeof(anim),"walk2");
									case 19:
										Format(anim,sizeof(anim),"leaderlook");
									case 20:
										Format(anim,sizeof(anim),"madidle");
									case 21:
										Format(anim,sizeof(anim),"madidle2");
									case 22:
										Format(anim,sizeof(anim),"madidle3");
									case 23:
										Format(anim,sizeof(anim),"180l");
									case 24:
										Format(anim,sizeof(anim),"180r");
									case 25:
										Format(anim,sizeof(anim),"jumpback");
									case 26:
										Format(anim,sizeof(anim),"land");
									case 27:
										Format(anim,sizeof(anim),"whimper");
									case 28:
										Format(anim,sizeof(anim),"eat");
									case 29:
										Format(anim,sizeof(anim),"sleep1");
									case 30:
										Format(anim,sizeof(anim),"sleep2");
									case 31:
										Format(anim,sizeof(anim),"sleeptostand2");
									case 32:
										Format(anim,sizeof(anim),"sleep3");
									case 33:
										Format(anim,sizeof(anim),"sleeptostand3");
									case 34:
										Format(anim,sizeof(anim),"gotosleep1");
									case 35:
										Format(anim,sizeof(anim),"sleeptostand1");
									case 36:
										Format(anim,sizeof(anim),"houndeye_jump_windowc1a1c");
									case 37:
										Format(anim,sizeof(anim),"WatchTV");
									case 38:
										Format(anim,sizeof(anim),"watchTV_to_Idle");
								}
								int scriptseq = CreateEntityByName("scripted_sequence");
								if (scriptseq != -1)
								{
									float resetorgs[3];
									SetEntPropVector(houndmdl,Prop_Data,"m_vecOrigin",resetorgs);
									char targn[64];
									if (HasEntProp(houndmdl,Prop_Data,"m_iName")) GetEntPropString(houndmdl,Prop_Data,"m_iName",targn,sizeof(targn));
									if (strlen(targn) < 1)
									{
										Format(targn,sizeof(targn),"syn_houndmdls%i",houndmdl);
										SetEntPropString(houndmdl,Prop_Data,"m_iName",targn);
									}
									DispatchKeyValue(scriptseq,"m_iszEntity",targn);
									DispatchKeyValue(scriptseq,"m_flRadius","0");
									DispatchKeyValue(scriptseq,"m_fMoveTo","0");
									DispatchKeyValue(scriptseq,"spawnflags","4336");
									DispatchKeyValue(scriptseq,"m_iszPlay",anim);
									DispatchKeyValue(scriptseq,"targetname","syn_houndseq");
									DispatchSpawn(scriptseq);
									ActivateEntity(scriptseq);
									AcceptEntityInput(scriptseq,"BeginSequence");
									Handle dp = CreateDataPack();
									WritePackCell(dp,scriptseq);
									WritePackString(dp,"scripted_sequence");
									CreateTimer(0.1,cleanup,dp);
								}
								*/
							}
							SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
							SetEntProp(houndmdl,Prop_Data,"m_nRenderFX",0);
							//SetEntityRenderMode(entity,RENDER_NONE);
							//SetEntityRenderMode(houndmdl,RENDER_NORMAL);
						}
						if ((seq == 2) && (!isattacking[entity]) && (centnextatk[entity] < Time))
						{
							int rand = GetRandomInt(1,3);
							centnextatk[entity] = Time+0.1;
							char snd[64];
							if (StrEqual(cls,"npc_houndeye",false)) Format(snd,sizeof(snd),"npc\\houndeye\\he_step%i.wav",rand);
							else Format(snd,sizeof(snd),"houndeye\\he_hunt%i.wav",rand);
							EmitSoundToAll(snd, entity, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
						}
						if (HasEntProp(entity,Prop_Data,"m_flModelScale"))
						{
							float mdlscale = GetEntPropFloat(houndmdl,Prop_Data,"m_flModelScale");
							float entscale = GetEntPropFloat(entity,Prop_Data,"m_flModelScale");
							entscale+=0.4;
							if (entscale != mdlscale)
							{
								SetEntPropFloat(houndmdl,Prop_Data,"m_flModelScale",entscale);
							}
						}
					}
				}
			}
		}
	}
}

public Action houndtkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			StopSound(victim,SNDCHAN_VOICE,"npc/antlion/pain1.wav");
			StopSound(victim,SNDCHAN_VOICE,"npc/antlion/pain2.wav");
			breaksnd[victim] = GetTickedTime()+0.5;
			char cls[24];
			GetEntityClassname(victim,cls,sizeof(cls));
			int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
			if (damage > curh)
			{
				if ((StrContains(mapbuf,"bm_c",false) == -1) && (StrContains(mapbuf,"xen_c",false) == -1) && (StrContains(mapbuf,"bm_damo",false) == -1))
					if (HasEntProp(victim,Prop_Data,"m_bForceServerRagdoll")) SetEntProp(victim,Prop_Data,"m_bForceServerRagdoll",1);
				if (StrEqual(cls,"npc_houndeye",false))
				{
					if (FileExists("sound/npc/houndeye/he_die1.wav",true,NULL_STRING))
					{
						char snd[128];
						Format(snd,sizeof(snd),"npc\\houndeye\\he_die%i.wav",GetRandomInt(1,3));
						EmitSoundToAll(snd, victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
					}
					else EmitSoundToAll("npc\\houndeye\\die1.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
				}
				else
				{
					char snd[128];
					Format(snd,sizeof(snd),"houndeye\\he_die%i.wav",GetRandomInt(1,3));
					EmitSoundToAll(snd, victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
				}
				int bbox = GetEntPropEnt(victim,Prop_Data,"m_hEffectEntity");
				if (IsValidEntity(bbox))
				{
					AcceptEntityInput(bbox,"kill");
				}
			}
			else if (damage > 1)
			{
				int rand = GetRandomInt(0,5);
				if (StrEqual(cls,"npc_houndeye",false))
				{
					switch(rand)
					{
						case 1:
						{
							if (FileExists("sound/npc/houndeye/he_pain1.wav",true,NULL_STRING)) EmitSoundToAll("npc\\houndeye\\he_pain1.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
							else EmitSoundToAll("npc\\houndeye\\pain1.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
						}
						case 2:
						{
							if (FileExists("sound/npc/houndeye/he_pain2.wav",true,NULL_STRING)) EmitSoundToAll("npc\\houndeye\\he_pain2.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
							else EmitSoundToAll("npc\\houndeye\\pain2.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
						}
						case 3:
						{
							if (FileExists("sound/npc/houndeye/he_pain3.wav",true,NULL_STRING)) EmitSoundToAll("npc\\houndeye\\he_pain3.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
							else EmitSoundToAll("npc\\houndeye\\pain3.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
						}
					}
				}
				else
				{
					char snd[64];
					Format(snd,sizeof(snd),"houndeye\\he_pain%i.wav",rand);
					EmitSoundToAll(snd, victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action houndbboxtkdmg(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			int parchk = GetEntPropEnt(victim,Prop_Data,"m_hParent");
			if (parchk != -1)
			{
				float damageForce[3];
				damageForce[0] = 5.0;
				damageForce[1] = 5.0;
				damageForce[2] = 5.0;
				if (damage > 200) damage = 5.0;
				breaksnd[parchk] = GetTickedTime()+0.5;
				if (damage > 1)
				{
					int rand = GetRandomInt(0,5);
					char cls[24];
					GetEntityClassname(parchk,cls,sizeof(cls));
					if (StrEqual(cls,"npc_houndeye",false))
					{
						switch(rand)
						{
							case 1:
							{
								if (FileExists("sound/npc/houndeye/he_pain1.wav",true,NULL_STRING)) EmitSoundToAll("npc\\houndeye\\he_pain1.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
								else EmitSoundToAll("npc\\houndeye\\pain1.wav", parchk, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
							}
							case 2:
							{
								if (FileExists("sound/npc/houndeye/he_pain2.wav",true,NULL_STRING)) EmitSoundToAll("npc\\houndeye\\he_pain2.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
								else EmitSoundToAll("npc\\houndeye\\pain2.wav", parchk, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
							}
							case 3:
							{
								if (FileExists("sound/npc/houndeye/he_pain3.wav",true,NULL_STRING)) EmitSoundToAll("npc\\houndeye\\he_pain3.wav", victim, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
								else EmitSoundToAll("npc\\houndeye\\pain3.wav", parchk, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
							}
						}
					}
					else
					{
						char snd[64];
						Format(snd,sizeof(snd),"houndeye\\he_pain%i.wav",rand);
						EmitSoundToAll(snd, parchk, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER);
					}
				}
				SDKHooks_TakeDamage(parchk,attacker,inflictor,damage,damagetype,-1,damageForce);
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}