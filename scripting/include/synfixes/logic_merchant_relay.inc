void logmerches(int ent, int activator, char[] input, char[] targn, char[] parampass, float delay)
{
	int thisent = FindEntityByClassname(ent,"logic_*");
	if ((IsValidEntity(thisent)) && (thisent != -1))
	{
		char enttargn[128];
		GetEntPropString(thisent,Prop_Data,"m_iName",enttargn,sizeof(enttargn));
		if (StrEqual(targn,enttargn,false))
		{
			if (delay > 0.1)
			{
				Handle dp = CreateDataPack();
				WritePackCell(dp,thisent);
				WritePackCell(dp,activator);
				WritePackString(dp,parampass);
				WritePackString(dp,input);
				CreateTimer(delay,merchantinputdelay,dp,TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				LogMerchInputs(thisent,activator,input,parampass);
			}
		}
		logmerches(thisent++,activator,input,targn,parampass,delay);
	}
}

public Action merchantinputdelay(Handle timer, Handle dp)
{
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		int ent = ReadPackCell(dp);
		int activator = ReadPackCell(dp);
		char parampass[64];
		char input[64];
		ReadPackString(dp,parampass,sizeof(parampass));
		ReadPackString(dp,input,sizeof(input));
		CloseHandle(dp);
		LogMerchInputs(ent,activator,input,parampass);
	}
}

public void LogMerchInputs(int ent, int activator, char[] input, char[] parampass)
{
	//PrintToServer("LogMerchInputs %i %i %s %s",ent,activator,input,parampass);
	if ((activator != 0) && (IsValidEntity(activator)))
	{
		if (HasEntProp(activator,Prop_Data,"m_iFrags"))
		{
			int points = GetEntProp(activator,Prop_Data,"m_iFrags");
			if (StrEqual(input,"Purchase",false))
			{
				int cost = GetEntProp(ent,Prop_Data,"m_iHealth");
				if (points >= cost)
				{
					SetEntProp(activator,Prop_Data,"m_iFrags",points-cost);
					char purchasesnd[64];
					GetEntPropString(ent,Prop_Data,"m_iszResponseContext",purchasesnd,sizeof(purchasesnd));
					if (strlen(purchasesnd) > 0)
					{
						if ((StrContains(purchasesnd,".mp3",false) == -1) && (StrContains(purchasesnd,".wav",false) == -1))
						{
							int chan,sndlvl,pitch;
							float vol;
							GetGameSoundParams(purchasesnd,chan,sndlvl,vol,pitch,purchasesnd,sizeof(purchasesnd),0);
						}
						if (StrContains(purchasesnd,"#",false) == 0) ReplaceString(purchasesnd,sizeof(purchasesnd),"#","");
						if (strlen(purchasesnd) > 0)
						{
							if (FindStringInArray(precachedarr,purchasesnd) == -1)
							{
								PrecacheSound(purchasesnd,true);
								PushArrayString(precachedarr,purchasesnd);
							}
							EmitSoundToAll(purchasesnd, activator, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
						}
					}
					AcceptEntityInput(ent,"FireUser1",activator);
				}
				else
				{
					char costdiff[32];
					Format(costdiff,sizeof(costdiff),"This costs %i you have %i",cost,points);
					PrintToChat(activator,"%s",costdiff);
					//SetHudTextParams(-1.0, 0.7, 1.0, 200, 200, 200, 255, 1, 1.0, 1.0, 1.0);
					//ShowHudText(activator,3,"%s",costdiff);
					AcceptEntityInput(ent,"FireUser2",activator);
				}
			}
		}
		if (StrEqual(input,"SetPurchaseCost",false))
		{
			int cost = GetEntProp(ent,Prop_Data,"m_iHealth");
			if (StringToInt(parampass) < cost)
			{
				AcceptEntityInput(ent,"FireUser3",activator);
			}
			SetEntProp(ent,Prop_Data,"m_iHealth",StringToInt(parampass));
		}
		else if (StrEqual(input,"Disable",false))
		{
			AcceptEntityInput(ent,"FireUser4",activator);
		}
	}
}

public Action LogMerchPurchased(const char[] output, int caller, int activator, float delay)
{
	//PrintToServer("LogMerch %i %s activator %i",caller,output,activator);
	char targn[128];
	GetEntPropString(caller,Prop_Data,"m_iName",targn,sizeof(targn));
	float origin[3];
	if (HasEntProp(caller,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(caller,Prop_Data,"m_vecAbsOrigin",origin);
	else if (HasEntProp(caller,Prop_Send,"m_vecOrigin")) GetEntPropVector(caller,Prop_Send,"m_vecOrigin",origin);
	readoutputstp(caller,targn,"OnPurchased","ForceSpawn",origin,activator);
}

public Action LogMerchNotEnough(const char[] output, int caller, int activator, float delay)
{
	//PrintToServer("LogMerch %i %s activator %i",caller,output,activator);
}

public Action LogMerchCashReduced(const char[] output, int caller, int activator, float delay)
{
	//PrintToServer("LogMerch %i %s activator %i",caller,output,activator);
}

public Action LogMerchDisabled(const char[] output, int caller, int activator, float delay)
{
	//PrintToServer("LogMerch %i %s activator %i",caller,output,activator);
}

public Action MerchantBlockDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	damage = 0.0;
	return Plugin_Changed;
}