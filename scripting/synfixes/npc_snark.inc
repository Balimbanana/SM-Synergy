void snarkthink(int entity)
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
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float lastsaw = GetEntPropFloat(entity,Prop_Data,"m_flLastSawPlayerTime");
				float jumprange = 200.0;
				if ((chkdist <= jumprange) && (lastsaw > lastseen[entity]))
				{
					isattacking[entity] = true;
					lastseen[entity] = lastsaw;
					float shootvel[3];
					curorg[2]+=0.1;
					MakeVectorFromPoints(curorg,enorg,shootvel);
					if (shootvel[2] < 0.0) shootvel[2]+=15.0;
					else shootvel[2]-=15.0;
					ScaleVector(shootvel,8.0);
					TeleportEntity(entity,curorg,angs,shootvel);
					CreateTimer(0.5,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					char cls[32];
					GetEntityClassname(entity,cls,sizeof(cls));
					int rand = GetRandomInt(1,3);
					char snd[64];
					if (StrEqual(cls,"npc_snark",false)) Format(snd,sizeof(snd),"npc\\snark\\deploy%i.wav",rand);
					else Format(snd,sizeof(snd),"squeek\\sqk_hunt%i.wav",rand);
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
			}
			if (HasEntProp(entity,Prop_Data,"m_iHealth"))
			{
				if (GetEntProp(entity,Prop_Data,"m_iHealth") < 1)
					AcceptEntityInput(entity,"kill");
			}
		}
	}
}

public Action StartTouchSnark(int entity, int other)
{
	if ((IsValidEntity(other)) && (isattacking[entity]))
	{
		float damageForce[3];
		float dmgset = 5.0;
		float dmgforce = 5.0;
		damageForce[0] = dmgforce;
		damageForce[1] = dmgforce;
		damageForce[2] = dmgforce;
		SDKHooks_TakeDamage(other,entity,entity,dmgset,DMG_CLUB,-1,damageForce);
		char cls[32];
		char snd[64];
		GetEntityClassname(entity,cls,sizeof(cls));
		if (StrEqual(cls,"npc_snark",false))
		{
			int rand = GetRandomInt(1,5);
			Format(snd,sizeof(snd),"npc\\snark\\bite0%i.wav",rand);
			int pitchshift = 100+(10*timesattacked[entity]);
			EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, pitchshift);
		}
		else
		{
			Format(snd,sizeof(snd),"squeek\\sqk_deploy1.wav");
			int pitchshift = 100+(10*timesattacked[entity]);
			EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN, pitchshift);
		}
		if (timesattacked[entity] >= 10)
		{
			timesattacked[entity] = 0;
			if (StrEqual(cls,"npc_snark",false)) Format(snd,sizeof(snd),"npc\\snark\\blast1.wav");
			else Format(snd,sizeof(snd),"squeek\\sqk_blast1.wav");
			EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			SetVariantInt(0);
			AcceptEntityInput(entity,"SetHealth");
		}
		else timesattacked[entity]++;
	}
}