void apachethink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				if ((chkdist < 3000.0) && (lastsaw > lastseen[entity]))
				{
					//m_hCrashPoint crash point ent m_bInvulnerable m_vecDesiredPosition
					float lorg[3];
					int leftfind = CreateEntityByName("prop_dynamic");
					if (leftfind != -1)
					{
						DispatchKeyValue(leftfind,"rendermode","10");
						DispatchKeyValue(leftfind,"solid","0");
						DispatchKeyValue(leftfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(leftfind);
						ActivateEntity(leftfind);
						TeleportEntity(leftfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(leftfind,"SetParent",entity);
						SetVariantString("rocketpodl");
						AcceptEntityInput(leftfind,"SetParentAttachment");
						if (HasEntProp(leftfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(leftfind,Prop_Data,"m_vecAbsOrigin",lorg);
						else if (HasEntProp(leftfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(leftfind,Prop_Send,"m_vecOrigin",lorg);
						AcceptEntityInput(leftfind,"kill");
					}
					angs[0]+=20.0;
					float loc[3];
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (lorg[0] + (300 * Cosine(DegToRad(angs[1]))));
						loc[1] = (lorg[1] + (300 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (lorg[0] + (275 * Cosine(DegToRad(angs[1]))));
						loc[1] = (lorg[1] + (275 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (lorg[2] - 100);
					if (angs[0] > 30.0) loc[2]-=50.0;
					float shootvel[3];
					MakeVectorFromPoints(loc,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,2.0);
					int missile = CreateEntityByName("rpg_missile");
					if (missile != -1)
					{
						DispatchSpawn(missile);
						ActivateEntity(missile);
						TeleportEntity(missile,loc,angs,shootvel);
						SetEntPropEnt(missile,Prop_Data,"m_hOwnerEntity",entity);
					}
					float rorg[3];
					int rightfind = CreateEntityByName("prop_dynamic");
					if (rightfind != -1)
					{
						DispatchKeyValue(rightfind,"rendermode","10");
						DispatchKeyValue(rightfind,"solid","0");
						DispatchKeyValue(rightfind,"model","models/props_junk/popcan01a.mdl");
						DispatchSpawn(rightfind);
						ActivateEntity(rightfind);
						TeleportEntity(rightfind,curorg,NULL_VECTOR,NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(rightfind,"SetParent",entity);
						SetVariantString("rocketpodr");
						AcceptEntityInput(rightfind,"SetParentAttachment");
						if (HasEntProp(rightfind,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(rightfind,Prop_Data,"m_vecAbsOrigin",rorg);
						else if (HasEntProp(rightfind,Prop_Send,"m_vecOrigin")) GetEntPropVector(rightfind,Prop_Send,"m_vecOrigin",rorg);
						AcceptEntityInput(rightfind,"kill");
					}
					if (((angs[1] > 45.0) && (angs[1] < 135.0)) || ((angs[1] > -135.0) && (angs[1] < -45.0)))
					{
						loc[0] = (rorg[0] + (350 * Cosine(DegToRad(angs[1]))));
						loc[1] = (rorg[1] + (350 * Sine(DegToRad(angs[1]))));
					}
					else
					{
						loc[0] = (rorg[0] + (325 * Cosine(DegToRad(angs[1]))));
						loc[1] = (rorg[1] + (325 * Sine(DegToRad(angs[1]))));
					}
					loc[2] = (rorg[2] - 100);
					if (angs[0] > 30.0) loc[2]-=50.0;
					MakeVectorFromPoints(loc,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,2.0);
					missile = CreateEntityByName("rpg_missile");
					if (missile != -1)
					{
						DispatchSpawn(missile);
						ActivateEntity(missile);
						TeleportEntity(missile,loc,angs,shootvel);
						SetEntPropEnt(missile,Prop_Data,"m_hOwnerEntity",entity);
					}
					//CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					timesattacked[entity]++;
					if (timesattacked[entity] > 9)
					{
						centnextatk[entity] = Time+10;
						timesattacked[entity] = 0;
					}
					else
					{
						centnextatk[entity] = Time+0.5;
					}
					lastseen[entity] = lastsaw;
				}
			}
		}
	}
}

public Action apachetkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((IsValidEntity(victim)) && (IsValidEntity(inflictor)))
	{
		if (HasEntProp(inflictor,Prop_Data,"m_hOwnerEntity"))
		{
			int ownerent = GetEntPropEnt(inflictor,Prop_Data,"m_hOwnerEntity");
			if (ownerent == victim)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		if (((attacker < MaxClients+1) && (attacker > 0)) || ((inflictor < MaxClients+1) && (inflictor > 0)))
		{
			int health = GetEntProp(victim,Prop_Data,"m_iHealth");
			if (health-damage < 1)
			{
				Handle entkilled = CreateEvent("synergy_entity_death");
				SetEventInt(entkilled,"killercolor",-16083416);
				SetEventInt(entkilled,"victimcolor",-1052689);
				char weap[24];
				char clsname2[24];
				GetEntityClassname(inflictor,clsname2,sizeof(clsname2));
				if ((attacker < MaxClients+1) && (attacker > 0))
					GetClientWeapon(attacker,weap,sizeof(weap));
				else if ((inflictor < MaxClients+1) && (inflictor > 0))
					GetClientWeapon(inflictor,weap,sizeof(weap));
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
				else
				{
					ReplaceString(weap,sizeof(weap),"weapon_","",false);
				}
				SetEventString(entkilled,"weapon",weap);
				SetEventInt(entkilled,"killerID",attacker);
				SetEventInt(entkilled,"victimID",victim);
				SetEventBool(entkilled,"suicide",false);
				char tmpchar[96];
				GetClientName(attacker,tmpchar,sizeof(tmpchar));
				SetEventString(entkilled,"killername",tmpchar);
				SetEventString(entkilled,"victimname","Apache");
				SetEventInt(entkilled,"iconcolor",-1052689);
				FireEvent(entkilled,false);
			}
		}
	}
	return Plugin_Continue;
}