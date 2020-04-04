void zomthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_nSequence"))
		{
			float Time = GetTickedTime();
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			if (centnextatk[entity] < Time)
			{
				if ((seq == 31) || (seq == 33) || (seq == 98))
				{
					Time-=0.3;
					if (FileExists("npc\\zombie\\pound_door1.wav",true,NULL_STRING))
						EmitSoundToAll("npc\\zombie\\pound_door1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					else
						EmitSoundToAll("npc\\zombie\\zombie_pound_door.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if (seq == 32)
				{
					Time+=3.0;
					if (FileExists("npc\\zombie\\pound_door1.wav",true,NULL_STRING))
						EmitSoundToAll("npc\\zombie\\pound_door1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					else
						EmitSoundToAll("npc\\zombie\\zombie_pound_door.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if (seq == 34)
				{
					if (FileExists("npc\\zombie\\pound_door1.wav",true,NULL_STRING))
						EmitSoundToAll("npc\\zombie\\pound_door1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					else
						EmitSoundToAll("npc\\zombie\\zombie_pound_door.wav", entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if ((seq == 59) || (seq == 60))
				{
					int rand = GetRandomInt(1,5);
					char snd[64];
					Format(snd,sizeof(snd),"npc\\zombie\\moan%i.wav",rand);
					if (rand == 5) Time+=12.0;
					EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				else if ((seq == 78) || (seq == 8) || (seq == 10) || (seq == 12) || (seq == 14) || (seq == 16) || (seq == 18) || (seq == 20) || (seq == 22) || (seq == 24))
				{
					if (FileExists("sound\\npc\\zombie\\alert1.wav",true,NULL_STRING))
					{
						int rand = GetRandomInt(1,6);
						char snd[64];
						switch(rand)
						{
							case 1:
								Format(snd,sizeof(snd),"npc\\zombie\\alert1.wav");
							case 2:
								Format(snd,sizeof(snd),"npc\\zombie\\alert2.wav");
							case 3:
								Format(snd,sizeof(snd),"npc\\zombie\\alert05.wav");
							case 4:
								Format(snd,sizeof(snd),"npc\\zombie\\alert06.wav");
							case 5:
								Format(snd,sizeof(snd),"npc\\zombie\\alert07.wav");
							case 6:
								Format(snd,sizeof(snd),"npc\\zombie\\alert08.wav");
						}
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\zombie_alert%i.wav",rand);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
				}
				else if ((seq > 54) && (seq < 58))
				{
					if (FileExists("sound\\npc\\zombie\\idle1.wav",true,NULL_STRING))
					{
						int rand = GetRandomInt(1,6);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\idle%i.wav",rand);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						int rand = GetRandomInt(1,14);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\zombie_voice_idle%i.wav",rand);
						EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					Time+=1.0;
				}
				centnextatk[entity] = Time+0.8;
			}
		}
	}
}

public Action zomtkdmg(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsValidEntity(victim))
	{
		if (HasEntProp(victim,Prop_Data,"m_iHealth"))
		{
			if (HasEntProp(victim,Prop_Data,"m_bForceServerRagdoll")) SetEntProp(victim,Prop_Data,"m_bForceServerRagdoll",1);
			float Time = GetTickedTime();
			if (centnextatk[victim] < Time)
			{
				int curh = GetEntProp(victim,Prop_Data,"m_iHealth");
				if (damage > curh)
				{
					if (FileExists("sound\\npc\\zombie\\die1.wav",true,NULL_STRING))
					{
						int rand = GetRandomInt(1,5);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\die%i.wav",rand);
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					else
					{
						int rand = GetRandomInt(1,3);
						char snd[64];
						Format(snd,sizeof(snd),"npc\\zombie\\zombie_die%i.wav",rand);
						EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
					}
					char cls[24];
					GetEntityClassname(victim,cls,sizeof(cls));
					if (StrEqual(cls,"npc_zombie_security",false))
					{
						if (FileExists("models/zombies/zombie_guard.mdl"))
						{
							if (!IsModelPrecached("models/zombies/zombie_guard.mdl")) PrecacheModel("models/zombies/zombie_guard.mdl",true);
							SetEntityModel(victim,"models/zombies/zombie_guard.mdl");
							AcceptEntityInput(victim,"BecomeRagdoll");
						}
					}
				}
				else if (damage > 1)
				{
					int rand = GetRandomInt(1,10);
					char snd[64];
					if ((!FileExists("sound\\npc\\zombie\\pain08.wav",true,NULL_STRING)) && (rand > 6)) rand = 6;
					if (rand < 7)
						Format(snd,sizeof(snd),"npc\\zombie\\pain%i.wav",rand);
					else if (rand < 10)
						Format(snd,sizeof(snd),"npc\\zombie\\pain0%i.wav",rand);
					else
						Format(snd,sizeof(snd),"npc\\zombie\\pain10.wav");
					EmitSoundToAll(snd, victim, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				}
				centnextatk[victim] = Time+0.2;
			}
		}
	}
	return Plugin_Continue;
}