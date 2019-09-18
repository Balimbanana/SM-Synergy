void monstzomthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_nSequence"))
		{
			int curh = GetEntProp(entity,Prop_Data,"m_iHealth");
			if (curh > 0)
			{
				float Time = GetTickedTime();
				int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
				if (centnextatk[entity] < Time)
				{
					if (((seq == 8) || (seq == 9)) && (timesattacked[entity] <= 1))
					{
						if (FindStringInArray(precachedarr,"monster_zombie") == -1)
						{
							recursion("sound/zombie/");
							PushArrayString(precachedarr,"monster_zombie");
						}
						char snd[64];
						Format(snd,sizeof(snd),"zombie\\zo_attack%i.wav",GetRandomInt(1,2));
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
						int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
						if ((targ != 0) && (IsValidEntity(targ)))
						{
							float orgs[3];
							float targorgs[3];
							if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",orgs);
							else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",orgs);
							if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",targorgs);
							else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",targorgs);
							float chkdist = GetVectorDistance(orgs,targorgs,false);
							if (chkdist < 100.0)
							{
								float meleedmg = 10.0;
								char atk[32];
								if (seq == 8)
								{
									Format(atk,sizeof(atk),"sk_monster_zombie_dmg_one_slash");
									Time-=1.0;
									timesattacked[entity]++;
								}
								else if (seq == 9)
								{
									Format(atk,sizeof(atk),"sk_monster_zombie_dmg_both_slash");
									Time-=0.5;
									timesattacked[entity] = 2;
								}
								Handle cvarchk = FindConVar(atk);
								if (cvarchk != INVALID_HANDLE)
									meleedmg = GetConVarFloat(cvarchk);
								CloseHandle(cvarchk);
								float damageForce[3];
								float dmgforce = 10.0;
								damageForce[0] = dmgforce;
								damageForce[1] = dmgforce;
								damageForce[2] = dmgforce;
								SDKHooks_TakeDamage(targ,entity,entity,meleedmg,DMG_CLUB,-1,damageForce,orgs);
								Format(snd,sizeof(snd),"zombie\\claw_strike%i.wav",GetRandomInt(1,3));
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
							}
						}
						centnextatk[entity] = Time+2.0;
					}
					else timesattacked[entity] = 0;
				}
			}
		}
	}
}