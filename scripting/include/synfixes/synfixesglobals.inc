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
int isattacking[2048];
int timesattacked[2048];
int matmod = -1;
int slavezap = 10;
int debuglvl = 0;
int debugoowlvl = 0;
int collisiongroup = -1;
int headgroup = 2;
int difficulty = 1;
bool showcc[65];
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
						float chkdist = GetVectorDistance(emitorgs,orgs,false)
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

NPCShootBullet(int entity, char[] curweap, float orgs[3], float angs[3], float maxspread)
{
	if (IsValidEntity(entity))
	{
		float endpos[3];
		TE_Start("Shotgun Shot");
		float bulletstartpos[3];
		bulletstartpos[0] = (orgs[0] + (60 * Cosine(DegToRad(angs[1]))));
		bulletstartpos[1] = (orgs[1] + (60 * Sine(DegToRad(angs[1]))));
		bulletstartpos[2] = orgs[2];
		TE_WriteVector("m_vecOrigin", bulletstartpos);
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
		TE_WriteVector("m_vecDir", shootvel);
		TE_WriteNum("m_iAmmoID", 1);
		TE_WriteNum("m_iSeed", 0);
		TE_WriteNum("m_iShots", 1);
		//Can only write players to this effect
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