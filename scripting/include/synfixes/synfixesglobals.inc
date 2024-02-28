#include <synfixes>

char mapbuf[64];
char glotext[2048][64];
Handle entlist = INVALID_HANDLE;
Handle entnames = INVALID_HANDLE;
Handle hounds = INVALID_HANDLE;
Handle houndsmdl = INVALID_HANDLE;
Handle squids = INVALID_HANDLE;
Handle squidsmdl = INVALID_HANDLE;
Handle tents = INVALID_HANDLE;
Handle tentsmdl = INVALID_HANDLE;
Handle tentssnd = INVALID_HANDLE;
Handle grenlist = INVALID_HANDLE;
Handle tripmines = INVALID_HANDLE;
Handle controllers = INVALID_HANDLE;
Handle precachedarr = INVALID_HANDLE;
Handle d_li = INVALID_HANDLE;
Handle d_ht = INVALID_HANDLE;
Handle customrelations = INVALID_HANDLE;
Handle customentlist = INVALID_HANDLE;
Handle templateslist = INVALID_HANDLE;
Handle templatetargs = INVALID_HANDLE;
Handle templateents = INVALID_HANDLE;
float centnextatk[2048];
float centlastposchk[2048];
float centlastang[2048];
float lastseen[2048];
float centnextsndtime[2048];
float centlasttouch[2048];
float breaksnd[2048];
int custentactive[128];
int isattacking[2048];
int timesattacked[2048];
int gargfiretarg[2048][5];
int matmod = -1;
int slavezap = 10;
int debuglvl = 0;
int debugoowlvl = 0;
int collisiongroup = -1;
int headgroup = 2;
int difficulty = 1;
int bulletindx = -1;
int iActiveSpawnEnt = -1;
int iActiveSpawner = -1;
bool bHasInit[2048];
bool showcc[128];
bool customents = false;
bool relsetvort = false;
bool relsetzsec = false;
bool relsethound = false;
bool relsetabram = false;
bool relsetsci = false;
bool relsetsec = false;

public Action restoretargn(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char restoretn[64];
		ReadPackString(dp,restoretn,sizeof(restoretn));
		int entity = ReadPackCell(dp);
		int logcoll = ReadPackCell(dp);
		if ((logcoll != 0) && (IsValidEntity(logcoll)))
			AcceptEntityInput(logcoll,"DisableCollisions");
		if ((entity != 0) && (IsValidEntity(entity)) && (strlen(restoretn) > 0))
		{
			SetEntPropString(entity,Prop_Data,"m_iName",restoretn);
			char addoutp[72];
			Format(addoutp,sizeof(addoutp),"targetname %s",restoretn);
			SetVariantString(addoutp);
			AcceptEntityInput(entity,"AddOutput");
		}
	}
}

public Action enttkdmgcust(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ((IsValidEntity(victim)) && (damage > 1.0))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
			float Time = GetTickedTime();
			if (centnextsndtime[victim] < Time)
			{
				Handle dp = CreateDataPack();
				WritePackCell(dp,victim);
				WritePackCell(dp,curh);
				CreateTimer(0.1,posttkdmg,dp,TIMER_FLAG_NO_MAPCHANGE);
				centnextsndtime[victim] = Time+0.5;
			}
		}
	}
	return Plugin_Continue;
}

public Action posttkdmg(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int victim = ReadPackCell(dp);
		int lasth = ReadPackCell(dp);
		CloseHandle(dp);
		if (IsValidEntity(victim))
		{
			if (HasEntProp(victim,Prop_Data,"m_iHealth"))
			{
				char cls[32];
				GetEntityClassname(victim,cls,sizeof(cls));
				int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
				if (lasth != curh)
				{
					char snd[64];
					if (StrEqual(cls,"npc_human_scientist",false))
					{
						if (GetRandomInt(1,2) == 1)
							Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\ow0%i.wav",GetRandomInt(1,8));
						else
						{
							int randsound = GetRandomInt(1,20);
							if (randsound < 10) Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\pain0%i.wav",randsound);
							else Format(snd,sizeof(snd),"vo\\npc\\scientist_male01\\pain%i.wav",randsound);
						}
					}
					else if (StrEqual(cls,"npc_human_security",false))
					{
						if (FileExists("sound/vo/npc/barneys/pain16.wav",true,NULL_STRING))
						{
							int rand = GetRandomInt(1,16);
							if (rand < 10) Format(snd,sizeof(snd),"vo\\npc\\barneys\\pain0%i.wav",rand);
							else Format(snd,sizeof(snd),"vo\\npc\\barneys\\pain%i.wav",rand);
						}
						else
						{
							int rand = GetRandomInt(1,10);
							if (rand < 10) Format(snd,sizeof(snd),"vo\\npc\\barney\\ba_pain0%i.wav",rand);
							else Format(snd,sizeof(snd),"vo\\npc\\barney\\ba_pain%i.wav",rand);
						}
					}
					if (strlen(snd) > 0)
					{
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
						char ccform[64];
						Format(ccform,sizeof(ccform),"%s",snd);
						ReplaceString(ccform,sizeof(ccform),"\\","/");
						float sciorgs[3];
						float orgs[3];
						if (HasEntProp(victim,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(victim,Prop_Data,"m_vecAbsOrigin",sciorgs);
						else if (HasEntProp(victim,Prop_Send,"m_vecOrigin")) GetEntPropVector(victim,Prop_Send,"m_vecOrigin",sciorgs);
						for (int k = 1;k<MaxClients+1;k++)
						{
							if (IsValidEntity(k))
							{
								if (IsClientConnected(k))
								{
									if (IsClientInGame(k))
									{
										QueryClientConVar(k,"closecaption",checkccsettings,0);
										if (HasEntProp(k,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(k,Prop_Data,"m_vecAbsOrigin",orgs);
										else if (HasEntProp(k,Prop_Send,"m_vecOrigin")) GetEntPropVector(k,Prop_Send,"m_vecOrigin",orgs);
										float chkdist = GetVectorDistance(sciorgs,orgs,false)
										if (chkdist < 768.0)
										{
											if (showcc[k]) ClientCommand(k,"cc_emit %s",ccform);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

void EmitCC(int emitentity, char[] snd, float distance)
{
	if (IsValidEntity(emitentity))
	{
		float emitorgs[3];
		float orgs[3];
		if (HasEntProp(emitentity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(emitentity,Prop_Data,"m_vecAbsOrigin",emitorgs);
		else if (HasEntProp(emitentity,Prop_Send,"m_vecOrigin")) GetEntPropVector(emitentity,Prop_Send,"m_vecOrigin",emitorgs);
		char ccform[128];
		Format(ccform,sizeof(ccform),"%s",snd);
		ReplaceString(ccform,sizeof(ccform),"\\","/");
		for (int k = 1;k<MaxClients+1;k++)
		{
			if (IsValidEntity(k))
			{
				if (IsClientConnected(k))
				{
					if (IsClientInGame(k))
					{
						QueryClientConVar(k,"closecaption",checkccsettings,0);
						if (HasEntProp(k,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(k,Prop_Data,"m_vecAbsOrigin",orgs);
						else if (HasEntProp(k,Prop_Send,"m_vecOrigin")) GetEntPropVector(k,Prop_Send,"m_vecOrigin",orgs);
						float chkdist = GetVectorDistance(emitorgs,orgs,false);
						if (chkdist < distance)
						{
							if (showcc[k])
							{
								if (debuglvl == 3) PrintToServer("EmitCC %s to %i",ccform,k);
								ClientCommand(k,"cc_emit %s",ccform);
							}
						}
					}
				}
			}
		}
	}
}

void NPCShootBullet(int entity, char[] curweap, float orgs[3], float angs[3], float maxspread)
{
	if (IsValidEntity(entity))
	{
		float endpos[3];
		//TE_Start("Shotgun Shot");
		float bulletstartpos[3];
		bulletstartpos[0] = (orgs[0] + (60 * Cosine(DegToRad(angs[1]))));
		bulletstartpos[1] = (orgs[1] + (60 * Sine(DegToRad(angs[1]))));
		bulletstartpos[2] = orgs[2];
		//TE_WriteVector("m_vecOrigin", bulletstartpos);
		float spread = GetRandomFloat(-maxspread,maxspread);
		angs[0] = angs[0]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[1] = angs[1]+spread;
		spread = GetRandomFloat(-maxspread,maxspread);
		angs[2] = angs[2]+spread;
		TR_TraceRayFilter(orgs, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilter, entity);
		TR_GetEndPosition(endpos);
		float shootvel[3];
		MakeVectorFromPoints(orgs,endpos,shootvel);
		int hitgroup = TR_GetHitGroup();
		int targ = TR_GetEntityIndex();
		//TE_WriteVector("m_vecDir", shootvel);
		//TE_WriteNum("m_iAmmoID", 1);
		//TE_WriteNum("m_iSeed", 0);
		//TE_WriteNum("m_iShots", 1);
		//Can only write players to this effect
		/*
		for (int i = 1;i<MaxClients+1;i++)
		{
			if (IsValidEntity(i))
			{
				TE_WriteNum("m_iPlayer", i);
				break;
			}
		}
		TE_WriteFloat("m_flSpread", 0.0);
		TE_WriteNum("m_bDoImpacts", 1);
		TE_WriteNum("m_bDoTracers", 1);
		TE_SendToAll(0.0);
		*/
		TE_Start("Client Projectile");
		ScaleVector(shootvel,10.0);
		TE_WriteVector("m_vecVelocity",shootvel);
		ScaleVector(shootvel,0.1);
		TE_WriteVector("m_vecOrigin",bulletstartpos);
		TE_WriteNum("m_nModelIndex",bulletindx);
		TE_WriteNum("m_nLifeTime",1);
		TE_WriteNum("m_hOwner",entity);
		TE_SendToAll(0.0);
		if (HasEntProp(entity,Prop_Data,"m_flFlashTime")) SetEntPropFloat(entity,Prop_Data,"m_flFlashTime",GetGameTime()+0.5);
		if ((targ != 0) && (IsValidEntity(targ)) && (targ != entity))
		{
			char clsname[32];
			GetEntityClassname(targ,clsname,sizeof(clsname));
			float damage = 1.0;
			char weapdmg[32];
			Format(weapdmg,sizeof(weapdmg),"%s",curweap);
			ReplaceStringEx(weapdmg,sizeof(weapdmg),"weapon_","sk_npc_dmg_");
			Handle cvar = FindConVar(weapdmg);
			if (cvar == INVALID_HANDLE)
			{
				ReplaceStringEx(weapdmg,sizeof(weapdmg),"sk_npc_dmg_","sk_dmg_");
				cvar = FindConVar(weapdmg);
			}
			if (cvar != INVALID_HANDLE)
			{
				damage = GetConVarFloat(cvar);
				float inflictscale = 1.0;
				char scalechk[32];
				Format(scalechk,sizeof(scalechk),"sk_dmg_take_scale%i",difficulty);
				Handle scaleh = FindConVar(scalechk);
				if (scaleh != INVALID_HANDLE) inflictscale = GetConVarFloat(scaleh);
				CloseHandle(scaleh);
				damage = damage/inflictscale;
				if (hitgroup == headgroup) damage = damage*2.0;
			}
			CloseHandle(cvar);
			if ((StrContains(clsname,"prop_",false) != -1) || (StrEqual(clsname,"func_breakable",false)) || (StrContains(clsname,"item_",false) == 0))
			{
				SDKHooks_TakeDamage(targ,entity,entity,damage,DMG_BULLET,-1,shootvel,orgs);
				ScaleVector(shootvel,1.5);
				float maxscaler = damage*2.0;
				if (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
				{
					while (((shootvel[0] > maxscaler) || (shootvel[1] > maxscaler) || (shootvel[2] > maxscaler)) || (shootvel[0] < -maxscaler) || (shootvel[1] < -maxscaler) || (shootvel[2] < -maxscaler))
					{
						ScaleVector(shootvel,0.95);
					}
				}
				TeleportEntity(targ,NULL_VECTOR,NULL_VECTOR,shootvel);
			}
			else
			{
				ScaleVector(shootvel,2.0);
				SDKHooks_TakeDamage(targ,entity,entity,damage,DMG_BULLET,-1,shootvel,orgs);
			}
		}
	}
}

void RunSeq(int entity, float origin[3], float angs[3], char anim[128], char entryanim[128], int moveto, bool loop, bool bPriority = false)
{
	/*
	moveto:
	0 : "No"
	1 : "Walk"
	2 : "Run"
	3 : "Custom movement"
	4 : "Instantaneous"
	5 : "No - Turn to Face"
	*/
	//PrintToServer("RunSeq %i %s %s",entity,entryanim,anim);
	if ((IsValidEntity(entity)) && (strlen(anim) > 0))
	{
		char clsres[64];
		if ((IsValidEntity(gargfiretarg[entity][4])) && (gargfiretarg[entity][4] != 0))
		{
			GetEntityClassname(gargfiretarg[entity][4],clsres,sizeof(clsres));
			if (StrEqual(clsres,"scripted_sequence",false))
			{
				AcceptEntityInput(gargfiretarg[entity][4],"CancelSequence");
				AcceptEntityInput(gargfiretarg[entity][4],"kill");
			}
			gargfiretarg[entity][4] = 0;
		}
		if (HasEntProp(entity,Prop_Data,"m_hTargetEnt"))
		{
			int scrent = GetEntPropEnt(entity,Prop_Data,"m_hTargetEnt");
			if (IsValidEntity(scrent))
			{
				if (HasEntProp(scrent,Prop_Data,"m_iName"))
				{
					char scrname[8];
					GetEntPropString(scrent,Prop_Data,"m_iName",scrname,sizeof(scrname));
					if (strlen(scrname) > 0) return;
				}
				if (HasEntProp(scrent,Prop_Data,"m_iszPlay"))
				{
					char scranim[128];
					GetEntPropString(scrent,Prop_Data,"m_iszPlay",scranim,sizeof(scranim));
					if (StrEqual(scranim,anim,false)) return;
				}
				AcceptEntityInput(scrent,"CancelSequence");
				AcceptEntityInput(scrent,"kill");
			}
		}
		int scrgo = CreateEntityByName("scripted_sequence");
		if (scrgo != -1)
		{
			GetEntityClassname(entity,clsres,sizeof(clsres));
			ReplaceStringEx(clsres,sizeof(clsres),"npc_","",-1,-1,false);
			char targn[64];
			GetEntPropString(entity,Prop_Data,"m_iName",targn,sizeof(targn));
			if (strlen(targn) < 1)
			{
				Format(targn,sizeof(targn),"%s%i",clsres,entity);
				SetEntPropString(entity,Prop_Data,"m_iName",targn);
			}
			char mvch[8];
			Format(mvch,sizeof(mvch),"%i",moveto);
			if (strlen(entryanim) > 1) DispatchKeyValue(scrgo,"m_iszEntry",entryanim);
			DispatchKeyValue(scrgo,"m_iszPlay",anim);
			DispatchKeyValue(scrgo,"m_iszEntity",targn);
			DispatchKeyValue(scrgo,"m_fMoveTo",mvch);
			/*
			16 Start on Spawn
			128 Don't Teleport NPC On End
			*/
			if (!bPriority)
				DispatchKeyValue(scrgo, "spawnflags", "144");
			else
			{
				DispatchKeyValue(scrgo, "spawnflags", "720");
				Format(targn, sizeof(targn), "%sscript", targn);
				DispatchKeyValue(scrgo, "targetname", "prioscr");
			}
			DispatchKeyValue(scrgo,"m_bDisableNPCCollisions","1");
			if (loop) DispatchKeyValue(scrgo,"m_bLoopActionSequence","1");
			DispatchKeyValue(scrgo,"OnEndSequence","!self,kill,,0.1,-1");
			origin[2]+=2.0;
			angs[0] = 0.0;
			angs[2] = 0.0;
			if (TR_PointOutsideWorld(origin))
			{
				float vMaxs[3];
				GetEntPropVector(0,Prop_Data,"m_WorldMaxs",vMaxs);
				while ((TR_PointOutsideWorld(origin)) && (origin[2] < vMaxs[2]))
				{
					origin[2]+=10.0;
				}
			}
			TeleportEntity(scrgo,origin,angs,NULL_VECTOR);
			DispatchSpawn(scrgo);
			ActivateEntity(scrgo);
			AcceptEntityInput(scrgo,"BeginSequence");
			gargfiretarg[entity][4] = scrgo;
		}
	}
	return;
}

void DoRadialDamage(int entity, float angle, float maxdistance, float radius, char damagecvar[64], int dmgtype, float forcescale)
{
	if (IsValidEntity(entity))
	{
		if (GetArraySize(entlist) > 0)
		{
			char npccls[64];
			GetEntityClassname(entity,npccls,sizeof(npccls));
			float curorg[3];
			if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
			else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
			/*
			curorg[0] = (curorg[0] + (90 * Cosine(DegToRad(angle))));
			curorg[1] = (curorg[1] + (90 * Sine(DegToRad(angle))));
			*/
			curorg[2]+=1.0;
			float toang[3];
			float shootvel[3];
			float enorg[3];
			float damageForce[3];
			float dmgset = 20.0;
			float dmgforce = 40.0;
			char cvarcls[64];
			Format(cvarcls,sizeof(cvarcls),"%s",npccls);
			ReplaceStringEx(cvarcls,sizeof(cvarcls),"npc_","",-1,-1,false);
			if (strlen(damagecvar) < 1) Format(cvarcls,sizeof(cvarcls),"sk_dmg_%s",cvarcls);
			else Format(cvarcls,sizeof(cvarcls),"sk_dmg_%s_%s",cvarcls,damagecvar);
			Handle cvar = FindConVar(cvarcls);
			if (cvar != INVALID_HANDLE)
			{
				dmgset = GetConVarFloat(cvar);
				dmgforce = dmgset*2.0;
			}
			CloseHandle(cvar);
			damageForce[0] = dmgforce;
			damageForce[1] = dmgforce;
			damageForce[2] = dmgforce;
			for (int j = 0;j<GetArraySize(entlist);j++)
			{
				int i = GetArrayCell(entlist,j);
				if (IsValidEntity(i))
				{
					char cls[64];
					GetEntityClassname(i,cls,sizeof(cls));
					if ((!StrEqual(cls,npccls,false)) && (!StrEqual(cls,"npc_gargantua",false)) && (!StrEqual(cls,"npc_bullseye",false)) && (!StrEqual(cls,"npc_maker",false)) && (!StrEqual(cls,"npc_template_maker",false)) && (!StrEqual(cls,"env_xen_portal",false)) && (!StrEqual(cls,"env_xen_portal_template",false)))
					{
						if (HasEntProp(i,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(i,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(i,Prop_Send,"m_vecOrigin")) GetEntPropVector(i,Prop_Send,"m_vecOrigin",enorg);
						if (GetVectorDistance(curorg,enorg,false) < maxdistance)
						{
							MakeVectorFromPoints(curorg,enorg,shootvel);
							GetVectorAngles(shootvel,toang);
							bool withinradius = CheckWithinRadius(angle,toang[1],radius);
							if (withinradius)
							{
								if (forcescale != 0.0)
								{
									enorg[2]+=1.0;
									ScaleVector(shootvel,forcescale);
									TeleportEntity(i,enorg,NULL_VECTOR,shootvel);
								}
								SDKHooks_TakeDamage(i,entity,entity,dmgset,dmgtype,-1,damageForce,curorg);
							}
						}
					}
				}
			}
			Handle propsarr = CreateArray(1024);
			FindAllByClassname(propsarr,-1,"prop_physics");
			if (GetArraySize(propsarr) > 0)
			{
				for (int i = 0;i<GetArraySize(propsarr);i++)
				{
					int ent = GetArrayCell(propsarr,i);
					if (IsValidEntity(ent))
					{
						if (HasEntProp(ent,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(ent,Prop_Data,"m_vecAbsOrigin",enorg);
						else if (HasEntProp(ent,Prop_Send,"m_vecOrigin")) GetEntPropVector(ent,Prop_Send,"m_vecOrigin",enorg);
						if (GetVectorDistance(curorg,enorg,false) < maxdistance)
						{
							MakeVectorFromPoints(curorg,enorg,shootvel);
							GetVectorAngles(shootvel,toang);
							bool withinradius = CheckWithinRadius(angle,toang[1],radius*1.2);
							if (withinradius)
							{
								curorg[2]-=90.0;
								enorg[0] = (enorg[0] + (90 * Cosine(DegToRad(angle))));
								enorg[1] = (enorg[1] + (90 * Sine(DegToRad(angle))));
								MakeVectorFromPoints(curorg,enorg,shootvel);
								if (forcescale != 0.0)
								{
									enorg[2]+=1.0;
									ScaleVector(shootvel,forcescale*2.0);
									TeleportEntity(ent,enorg,NULL_VECTOR,shootvel);
								}
								curorg[2]+=90.0;
								SDKHooks_TakeDamage(ent,entity,entity,dmgset,dmgtype,-1,damageForce,curorg);
							}
						}
					}
				}
			}
			CloseHandle(propsarr);
		}
	}
}

bool CheckWithinRadius(float angle, float toang, float radius)
{
	if (angle > toang)
	{
		if ((angle-toang > 0) && (angle-toang < radius)) return true;
		else if ((toang-angle < -1) && (toang-angle > (0.0-radius))) return true;
		else return false;
	}
	else if (toang > angle)
	{
		if ((toang-angle > 0) && (toang-angle < radius)) return true;
		else if ((angle-toang < -1) && (angle-toang > (0.0-radius))) return true;
		else return false;
	}
	return false;
}

public bool TraceEntityFilter(int entity, int mask, any data){
	if (IsValidEntity(entity))
	{
		if (IsValidEntity(data))
		{
			// If my parent, ignore
			if (HasEntProp(data, Prop_Data, "m_hParent"))
			{
				int parent = GetEntPropEnt(data, Prop_Data, "m_hParent");
				if (entity == parent) return false;
			}
			// If parented to me, ignore
			if (HasEntProp(entity, Prop_Data, "m_hParent"))
			{
				int parent = GetEntPropEnt(entity, Prop_Data, "m_hParent");
				if (parent == data) return false;
			}
		}
		char clsname[32];
		GetEntityClassname(entity, clsname, sizeof(clsname));
		if ((StrEqual(clsname, "func_vehicleclip", false)) || (StrEqual(clsname, "npc_sentry_ceiling", false)) || (entity == data))
			return false;
	}
	return true;
}

public bool TraceEntityFilterPly(int entity, int mask, any data){
	if ((entity != -1) && (IsValidEntity(entity)))
	{
		if (IsValidEntity(data))
		{
			// If my parent, ignore
			if (HasEntProp(data,Prop_Data,"m_hParent"))
			{
				int parent = GetEntPropEnt(data, Prop_Data, "m_hParent");
				if (entity == parent) return false;
			}
			// If parented to me, ignore
			if (HasEntProp(entity, Prop_Data, "m_hParent"))
			{
				int parent = GetEntPropEnt(entity, Prop_Data, "m_hParent");
				if (parent == data) return false;
			}
		}
		if ((entity < MaxClients+1) && (entity > 0)) return false;
		char clsname[32];
		GetEntityClassname(entity,clsname,sizeof(clsname));
		if ((StrEqual(clsname,"func_vehicleclip",false)) || (StrEqual(clsname,"npc_sentry_ceiling",false)) || (entity == data))
			return false;
	}
	return true;
}

public Action ResetSoundEnd(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int entity = ReadPackCell(dp);
		char snd[128];
		ReadPackString(dp,snd,sizeof(snd));
		int channel = ReadPackCell(dp);
		CloseHandle(dp);
		if ((IsValidEntity(entity)) && (strlen(snd) > 0))
		{
			StopSound(entity,channel,snd);
		}
	}
}

bool GetBaseClassFor(char[] szCls, char[] szSetBuff, int iszBuffSize)
{
	if ((StrEqual(szCls,"npc_human_grunt",false)) || (StrEqual(szCls,"npc_human_commander",false)) || (StrEqual(szCls,"npc_human_grenadier",false)) || (StrEqual(szCls,"npc_human_medic",false)) || (StrEqual(szCls,"npc_assassin",false)) || (StrEqual(szCls,"npc_human_assassin",false)) || (StrEqual(szCls,"monster_human_assassin",false))) Format(szSetBuff,iszBuffSize,"npc_combine_s");
	else if ((StrEqual(szCls,"npc_alien_grunt",false)) || (StrEqual(szCls,"monster_alien_grunt",false)) || (StrEqual(szCls,"npc_alien_grunt_unarmored",false))) Format(szSetBuff,iszBuffSize,"npc_combine_s");
	else if (StrEqual(szCls,"monster_gargantua",false)) Format(szSetBuff,iszBuffSize,"npc_gargantua");
	else if ((StrEqual(szCls,"monster_scientist",false)) || (StrEqual(szCls,"monster_scientist_dead",false))) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if (StrEqual(szCls,"monster_sitting_scientist",false)) Format(szSetBuff,iszBuffSize,"prop_dynamic");
	else if ((StrEqual(szCls,"monster_barney",false)) || (StrEqual(szCls,"monster_barney_dead",false))) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if (StrEqual(szCls,"monster_ichthyosaur",false)) Format(szSetBuff,iszBuffSize,"npc_ichthyosaur");
	else if (StrEqual(szCls,"monster_gman",false)) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if (StrEqual(szCls,"monster_barnacle",false)) Format(szSetBuff,iszBuffSize,"npc_barnacle");
	else if (StrEqual(szCls,"monster_zombie",false)) Format(szSetBuff,iszBuffSize,"npc_zombie");
	else if ((StrEqual(szCls,"monster_human_grunt",false)) || (StrEqual(szCls,"monster_hgrunt_dead",false))) Format(szSetBuff,iszBuffSize,"npc_combine_s");
	else if (StrEqual(szCls,"monster_cockroach",false)) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if ((StrEqual(szCls,"monster_bullchicken",false)) || (StrEqual(szCls,"monster_houndeye",false)) || (StrEqual(szCls,"npc_bullsquid",false)) || (StrEqual(szCls,"npc_houndeye",false))) Format(szSetBuff,iszBuffSize,"npc_antlion");
	else if (StrEqual(szCls,"npc_human_security",false)) Format(szSetBuff,iszBuffSize,"npc_citizen");
	else if (StrEqual(szCls,"npc_human_scientist",false)) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if (StrEqual(szCls,"npc_human_scientist_female",false)) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if (StrEqual(szCls,"npc_alien_slave",false)) Format(szSetBuff,iszBuffSize,"npc_vortigaunt");
	else if (StrEqual(szCls,"npc_human_scientist_kleiner",false)) Format(szSetBuff,iszBuffSize,"npc_kleiner");
	else if (StrEqual(szCls,"npc_human_scientist_eli",false)) Format(szSetBuff,iszBuffSize,"npc_eli");
	else if ((StrEqual(szCls,"npc_zombie_security",false)) || (StrEqual(szCls,"npc_zombie_worker",false)) || (StrEqual(szCls,"npc_gonarch",false))) Format(szSetBuff,iszBuffSize,"npc_zombine");
	else if (StrEqual(szCls,"npc_babycrab",false)) Format(szSetBuff,iszBuffSize,"npc_headcrab");
	else if ((StrEqual(szCls,"npc_snark",false)) || (StrEqual(szCls,"monster_snark",false))) Format(szSetBuff,iszBuffSize,"npc_headcrab_fast");
	else if (StrEqual(szCls,"npc_zombie_security_torso",false)) Format(szSetBuff,iszBuffSize,"npc_zombie");
	else if (StrEqual(szCls,"npc_zombie_scientist",false)) Format(szSetBuff,iszBuffSize,"npc_zombie");
	else if (StrEqual(szCls,"npc_zombie_scientist_torso",false)) Format(szSetBuff,iszBuffSize,"npc_zombie_torso");
	else if ((StrEqual(szCls,"npc_human_grunt",false)) || (StrEqual(szCls,"npc_human_commander",false)) || (StrEqual(szCls,"npc_human_grenadier",false)) || (StrEqual(szCls,"npc_human_medic",false))) Format(szSetBuff,iszBuffSize,"npc_combine_s");
	else if (StrEqual(szCls,"npc_odell",false)) Format(szSetBuff,iszBuffSize,"npc_citizen");
	else if ((StrEqual(szCls,"npc_osprey",false)) || (StrEqual(szCls,"npc_tentacle",false)) || (StrEqual(szCls,"npc_abrams",false)) || (StrEqual(szCls,"npc_bmsgargantua",false)) || (StrEqual(szCls,"npc_merchant",false))) Format(szSetBuff,iszBuffSize,"generic_actor");
	else if (StrEqual(szCls,"npc_sentry_ceiling",false)) Format(szSetBuff,iszBuffSize,"npc_turret_ceiling");
	else if (StrEqual(szCls,"npc_synth_scanner",false)) Format(szSetBuff,iszBuffSize,"npc_cscanner");
	else if (StrEqual(szCls,"env_xen_portal",false)) Format(szSetBuff,iszBuffSize,"npc_maker");
	else if (StrEqual(szCls,"trigger_auto",false)) Format(szSetBuff,iszBuffSize,"logic_relay");
	else if (StrEqual(szCls,"env_xen_portal_template",false)) Format(szSetBuff,iszBuffSize,"npc_template_maker");
	else if (StrEqual(szCls,"env_mortar_launcher",false)) Format(szSetBuff,iszBuffSize,"info_target");
	else if (StrEqual(szCls,"env_mortar_controller",false)) Format(szSetBuff,iszBuffSize,"prop_physics_override");
	else if (StrEqual(szCls,"multi_manager",false)) Format(szSetBuff,iszBuffSize,"logic_relay");
	else if (StrEqual(szCls,"prop_train_awesome",false)) Format(szSetBuff,iszBuffSize,"prop_dynamic");
	else if (StrEqual(szCls,"prop_train_apprehension",false)) Format(szSetBuff,iszBuffSize,"prop_dynamic_override");
	else if (StrEqual(szCls," item_ammo_smg1_grenade",false)) Format(szSetBuff,iszBuffSize,"item_ammo_smg1_grenade");
	else if (StrEqual(szCls,"npc_sentry_ground",false)) Format(szSetBuff,iszBuffSize,"npc_turret_floor");
	else if ((StrEqual(szCls,"info_player_rebel",false)) || (StrEqual(szCls,"info_player_combine",false)) || (StrEqual(szCls,"info_player_deathmatch",false))) Format(szSetBuff,iszBuffSize,"info_player_coop");
	else if ((StrEqual(szCls,"weapon_gluon",false)) || (StrEqual(szCls,"weapon_goop",false))) Format(szSetBuff,iszBuffSize,"weapon_shotgun");
	else if (StrEqual(szCls,"weapon_isa_knife",false)) Format(szSetBuff,iszBuffSize,"weapon_crowbar");
	else if (StrEqual(szCls,"weapon_handgrenade",false)) Format(szSetBuff,iszBuffSize,"weapon_frag");
	else if ((StrEqual(szCls,"weapon_glock",false)) || (StrEqual(szCls,"weapon_pistol_worker",false)) || (StrEqual(szCls,"weapon_flaregun",false)) || (StrEqual(szCls,"weapon_manhack",false)) || (StrEqual(szCls,"weapon_manhackgun",false)) || (StrEqual(szCls,"weapon_manhacktoss",false)) || (StrEqual(szCls,"weapon_p911",false)) || (StrEqual(szCls,"weapon_pistol2",false))) Format(szSetBuff,iszBuffSize,"weapon_pistol");
	else if ((StrEqual(szCls,"weapon_medkit",false)) || (StrEqual(szCls,"weapon_healer",false)) || (StrEqual(szCls,"weapon_snark",false)) || (StrEqual(szCls,"weapon_hivehand",false)) || (StrEqual(szCls,"weapon_molotov",false))) Format(szSetBuff,iszBuffSize,"weapon_slam");
	else if ((StrEqual(szCls,"weapon_mp5",false)) || (StrEqual(szCls,"weapon_sl8",false)) || (StrEqual(szCls,"weapon_uzi",false)) || (StrEqual(szCls,"weapon_camera",false)) || (StrEqual(szCls,"weapon_smg3",false)) || (StrEqual(szCls,"weapon_smg4",false))) Format(szSetBuff,iszBuffSize,"weapon_smg1");
	else if ((StrEqual(szCls,"weapon_gauss",false)) || (StrEqual(szCls,"weapon_tau",false)) || (StrEqual(szCls,"weapon_sniperrifle",false)) || (StrEqual(szCls,"weapon_vc32sniperrifle",false)) || (StrEqual(szCls,"weapon_bhg",false))) Format(szSetBuff,iszBuffSize,"weapon_ar2");
	else if (StrEqual(szCls,"weapon_cguard",false)) Format(szSetBuff,iszBuffSize,"weapon_stunstick");
	else if (StrEqual(szCls,"weapon_axe",false)) Format(szSetBuff,iszBuffSize,"weapon_pipe");
	else if (StrEqual(szCls,"npc_apache",false)) Format(szSetBuff,iszBuffSize,"npc_helicopter");
	else if (StrEqual(szCls,"item_longjump",false)) Format(szSetBuff,iszBuffSize,"item_healthkit");
	else if (StrEqual(szCls,"item_custom",false)) Format(szSetBuff,iszBuffSize,"item_ammo_smg1");
	else return false;
	return true;
}