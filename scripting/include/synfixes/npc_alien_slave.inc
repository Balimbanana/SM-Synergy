void aslavethink(int entity)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity,Prop_Data,"m_hEnemy"))
		{
			int targ = GetEntPropEnt(entity,Prop_Data,"m_hEnemy");
			float Time = GetTickedTime();
			if ((targ != -1) && (IsValidEntity(targ)) && (centnextatk[entity] < Time) && (!isattacking[entity]))
			{
				int seq = GetEntProp(entity,Prop_Data,"m_nSequence");
				float curorg[3];
				if (HasEntProp(entity,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(entity,Prop_Data,"m_vecAbsOrigin",curorg);
				else if (HasEntProp(entity,Prop_Send,"m_vecOrigin")) GetEntPropVector(entity,Prop_Send,"m_vecOrigin",curorg);
				float enorg[3];
				float angs[3];
				if (HasEntProp(entity,Prop_Data,"m_angAbsRotation")) GetEntPropVector(entity,Prop_Data,"m_angAbsRotation",angs);
				if (HasEntProp(targ,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(targ,Prop_Data,"m_vecAbsOrigin",enorg);
				else if (HasEntProp(targ,Prop_Send,"m_vecOrigin")) GetEntPropVector(targ,Prop_Send,"m_vecOrigin",enorg);
				float chkdist = GetVectorDistance(curorg,enorg,false);
				float meleerange = 75.0;
				Handle cvarchk = FindConVar("sk_alien_slave_claw_range");
				if (cvarchk != INVALID_HANDLE)
					meleerange = GetConVarFloat(cvarchk);
				CloseHandle(cvarchk);
				float targvec[3];
				MakeVectorFromPoints(curorg,enorg,targvec);
				float toang[3];
				GetVectorAngles(targvec,toang);
				bool withinradius = false;
				if (angs[1] > toang[1])
				{
					if ((angs[1]-toang[1] > 180) && (angs[1]-toang[1] < 220)) withinradius = false;
					else if ((toang[1]-angs[1] < -180) && (toang[1]-angs[1] > -220)) withinradius = false;
					else withinradius = true;
				}
				else if (toang[1] > angs[1])
				{
					if ((toang[1]-angs[1] > 180) && (toang[1]-angs[1] < 220)) withinradius = false;
					else if ((angs[1]-toang[1] < -180) && (angs[1]-toang[1] > -220)) withinradius = false;
					else withinradius = true;
				}
				if ((chkdist <= meleerange) && (seq != 40) && (withinradius))
				{
					SetVariantString("nullfil");
					AcceptEntityInput(entity,"SetEnemyFilter");
					SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((!IsValidEntity(propset)) || (propset == 0))
					{
						int propshow = CreateEntityByName("prop_dynamic");
						if (propshow != -1)
						{
							DispatchKeyValue(propshow,"solid","0");
							DispatchKeyValue(propshow,"model","models/vortigaunt_slave.mdl");
							DispatchKeyValue(propshow,"DefaultAnim","MeleeHigh3");
							TeleportEntity(propshow,curorg,angs,NULL_VECTOR);
							DispatchSpawn(propshow);
							ActivateEntity(propshow);
							SetVariantString("!activator");
							AcceptEntityInput(propshow,"SetParent",entity);
							int rand = GetRandomInt(36,40);
							if (rand == 40) rand = 62;
							SetEntProp(propshow,Prop_Data,"m_nSequence",rand);
							float tmp;
							tmp+=propshow;
							centlastang[entity] = tmp;
						}
					}
					isattacking[entity] = targ;
					centnextatk[entity] = Time+1.0;
					CreateTimer(0.7,resetatk,entity,TIMER_FLAG_NO_MAPCHANGE);
					//Seq 36 - 39 || 62
				}
				else
				{
					int propset;
					if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
					if ((IsValidEntity(propset)) && (propset != 0))
					{
						char clschk[24];
						GetEntityClassname(propset,clschk,sizeof(clschk));
						if (StrEqual(clschk,"prop_dynamic",false))
							AcceptEntityInput(propset,"kill");
						centlastang[entity] = 0.0;
					}
					SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
				}
			}
			else if ((isattacking[entity]) && (centnextatk[entity] > Time))
			{
				SetEntProp(entity,Prop_Data,"m_nRenderFX",6);
				/*
				int propset;
				if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
				if ((IsValidEntity(propset)) && (propset != 0))
				{
					char clschk[24];
					GetEntityClassname(propset,clschk,sizeof(clschk));
					if (StrEqual(clschk,"prop_dynamic",false))
						AcceptEntityInput(propset,"kill");
					centlastang[entity] = 0.0;
				}
				*/
			}
			else if ((!isattacking[entity]) && (targ == -1))
			{
				SetEntProp(entity,Prop_Data,"m_nRenderFX",0);
				int propset;
				if (RoundFloat(centlastang[entity]) > 0) propset = RoundFloat(centlastang[entity]);
				if ((IsValidEntity(propset)) && (propset != 0))
				{
					char clschk[24];
					GetEntityClassname(propset,clschk,sizeof(clschk));
					if (StrEqual(clschk,"prop_dynamic",false))
						AcceptEntityInput(propset,"kill");
					centlastang[entity] = 0.0;
				}
			}
		}
	}
}