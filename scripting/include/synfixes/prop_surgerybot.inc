void surgerybotthink(int entity)
{
	if (IsValidEntity(entity))
	{
		int activeent = GetEntPropEnt(entity,Prop_Data,"m_hEffectEntity");
		if (IsValidEntity(activeent))
		{
			if (HasEntProp(activeent,Prop_Data,"m_bEmit"))
			{
				int active = GetEntProp(activeent,Prop_Data,"m_bEmit");
				int seqchk = GetEntProp(entity,Prop_Data,"m_nSequence");
				if ((active == 0) && (seqchk != 2))
				{
					SetVariantString("shutdown");
					AcceptEntityInput(entity,"SetAnimation");
					SetVariantString("");
					AcceptEntityInput(entity,"SetDefaultAnimation");
					char attachments[64];
					GetEntPropString(activeent,Prop_Data,"m_iName",attachments,sizeof(attachments));
					Format(attachments,sizeof(attachments),"%sattachments",attachments);
					int loginp = CreateEntityByName("logic_auto");
					if (loginp != -1)
					{
						char input[128];
						DispatchKeyValue(loginp,"spawnflags","1");
						Format(input,sizeof(input),"%s,TurnOff,,2,-1",attachments);
						DispatchKeyValue(loginp,"OnMapSpawn",input);
						Format(input,sizeof(input),"%s,Disable,,2,-1",attachments);
						DispatchKeyValue(loginp,"OnMapSpawn",input);
						Format(input,sizeof(input),"%s,StopSpark,,2,-1",attachments);
						DispatchKeyValue(loginp,"OnMapSpawn",input);
						DispatchSpawn(loginp);
						ActivateEntity(loginp);
					}
				}
				if ((active == 1) && (seqchk != 1))
				{
					SetVariantString("active");
					AcceptEntityInput(entity,"SetAnimation");
					SetVariantString("");
					AcceptEntityInput(entity,"SetDefaultAnimation");
					char attachments[64];
					GetEntPropString(activeent,Prop_Data,"m_iName",attachments,sizeof(attachments));
					Format(attachments,sizeof(attachments),"%sattachments",attachments);
					int loginp = CreateEntityByName("logic_auto");
					if (loginp != -1)
					{
						char input[128];
						DispatchKeyValue(loginp,"spawnflags","1");
						Format(input,sizeof(input),"%s,TurnOn,,0,-1",attachments);
						DispatchKeyValue(loginp,"OnMapSpawn",input);
						Format(input,sizeof(input),"%s,Enable,,0,-1",attachments);
						DispatchKeyValue(loginp,"OnMapSpawn",input);
						Format(input,sizeof(input),"%s,StartSpark,,0,-1",attachments);
						DispatchKeyValue(loginp,"OnMapSpawn",input);
						DispatchSpawn(loginp);
						ActivateEntity(loginp);
					}
				}
			}
		}
	}
}