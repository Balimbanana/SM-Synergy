void hgruntthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		if (HasEntProp(entity,Prop_Data,"m_NPCState"))
		{
			int statechk = GetEntProp(entity,Prop_Data,"m_NPCState");
			int sleepchk = GetEntProp(entity,Prop_Data,"m_SleepState");
			//0 none - 4 scripting
			if ((statechk != 0) && (statechk != 4) && (sleepchk == 0))
			{
				float Time = GetTickedTime();
				if (centnextsndtime[entity] < Time)
				{
					int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
					if (FindStringInArray(precachedarr,"npc_human_grunt") == -1)
					{
						recursion("sound/vo/npc/hgrunt/");
						PushArrayString(precachedarr,"npc_human_grunt");
					}
					if ((statechk == 1) && (timesattacked[entity] != 1))
					{
						int rand = GetRandomInt(0,12);
						char snd[64];
						if (rand > 9) Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_CLEAR%i.wav",rand);
						else Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_CLEAR0%i.wav",rand);
						if (strlen(snd) > 0)
						{
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
					if ((statechk == 3) && (seq == 49))
					{
						int rand = GetRandomInt(0,7);
						char snd[64];
						Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_THROW0%i.wav",rand);
						if (strlen(snd) > 0)
						{
							EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
					else if (statechk == 3)
					{
						int enemyply = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
						if ((enemyply < MaxClients+1) && (enemyply > 0))
						{
							int rand = GetRandomInt(0,4);
							char snd[64];
							switch(rand)
							{
								case 0: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT01.wav");
								case 1: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT04.wav");
								case 2: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT06.wav");
								case 3: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT10.wav");
								case 4: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT12.wav");
							}
							if (strlen(snd) > 0)
							{
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
						else
						{
							int rand = GetRandomInt(0,7);
							char snd[64];
							switch(rand)
							{
								case 0: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT00.wav");
								case 1: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT02.wav");
								case 2: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT03.wav");
								case 3: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT05.wav");
								case 4: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT07.wav");
								case 5: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT08.wav");
								case 6: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT09.wav");
								case 7: Format(snd,sizeof(snd),"vo\\npc\\hgrunt\\HG_ALERT11.wav");
							}
							if (strlen(snd) > 0)
							{
								EmitSoundToAll(snd, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
							}
						}
					}
					timesattacked[entity] = statechk;
					centnextsndtime[entity] = Time+6.0+GetRandomFloat(1.0,5.0);
				}
			}
		}
	}
}

void grenthink(int entity)
{
	if ((IsValidEntity(entity)) && (IsEntNetworkable(entity)))
	{
		int curh = GetEntProp(entity,Prop_Data,"m_iHealth");
		if (curh < 1)
		{
			if ((isattacking[entity] != 0) && (IsValidEntity(isattacking[entity])))
			{
				AcceptEntityInput(isattacking[entity],"kill");
				isattacking[entity] = 0;
			}
		}
		char curweap[24];
		int weap;
		if (HasEntProp(entity,Prop_Data,"m_hActiveWeapon"))
		{
			weap = GetEntPropEnt(entity,Prop_Data,"m_hActiveWeapon");
			if ((IsValidEntity(weap)) && (weap != 0))
				GetEntityClassname(weap,curweap,sizeof(curweap));
		}
		if ((HasEntProp(entity,Prop_Data,"m_nSequence")) && (StrEqual(curweap,"weapon_rpg",false)))
		{
			int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
			if ((IsValidEntity(isattacking[entity])) && (isattacking[entity] != 0) && (seq != 0))
			{
				AcceptEntityInput(isattacking[entity],"kill");
				//SetEntityRenderMode(entity,RENDER_NORMAL);
				//SetEntityRenderMode(weap,RENDER_NORMAL);
				SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
				SetEntProp(weap,Prop_Data,"m_nRenderFX",0);
				isattacking[entity] = 0;
			}
			else if ((seq == 0) && (isattacking[entity] == 0))
			{
				//SetEntityRenderMode(entity,RENDER_NONE);
				//SetEntityRenderMode(weap,RENDER_NONE);
				SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
				SetEntProp(weap,Prop_Data,"m_nRenderFX",6);
				int entmdl = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdl,"model","models/humans/marine.mdl");
				DispatchKeyValue(entmdl,"solid","0");
				float origin[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angRotation")) GetEntPropVector(entity,Prop_Data,"m_angRotation",angs);
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",origin);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
				TeleportEntity(entmdl,origin,angs,NULL_VECTOR);
				DispatchSpawn(entmdl);
				ActivateEntity(entmdl);
				SetVariantString("!activator");
				AcceptEntityInput(entmdl,"SetParent",entity);
				SetEntProp(entmdl,Prop_Data,"m_nSequence",22);
				int body = GetEntProp(entity,Prop_Data,"m_nBody");
				SetEntProp(entmdl,Prop_Data,"m_nBody",body);
				isattacking[entity] = entmdl;
				int entmdlweap = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(entmdlweap,"model","models/weapons/w_rocket_launcher.mdl");
				DispatchKeyValue(entmdlweap,"solid","0");
				TeleportEntity(entmdlweap,origin,angs,NULL_VECTOR);
				DispatchSpawn(entmdlweap);
				ActivateEntity(entmdlweap);
				SetVariantString("!activator");
				AcceptEntityInput(entmdlweap,"SetParent",entmdl);
				SetVariantString("anim_attachment_RH");
				AcceptEntityInput(entmdlweap,"SetParentAttachment");
			}
		}
	}
}