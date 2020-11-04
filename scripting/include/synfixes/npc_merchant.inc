Handle merchantscr = INVALID_HANDLE;
Handle merchantscrd = INVALID_HANDLE;

public Action MerchantUse(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(caller))
	{
		//PrintToServer("NPCMerch %i %s activator %i",caller,output,activator);
		if ((activator > 0) && (activator < MaxClients+1))
		{
			char scr[128];
			GetEntPropString(caller,Prop_Data,"m_iszResponseContext",scr,sizeof(scr));
			if (strlen(scr) > 0)
			{
				Format(scr,sizeof(scr),"scripts/merchants/%s.txt",scr);
				//PrintToServer("NPCMerch use scr %s",scr);
				if (FileExists(scr,true,NULL_STRING))
				{
					int finddp = FindStringInArray(merchantscr,scr);
					if (finddp == -1)
					{
						Handle dp = CreateDataPack();
						Handle filehandlesub = OpenFile(scr,"r",true,NULL_STRING);
						if (filehandlesub != INVALID_HANDLE)
						{
							char scrline[64];
							while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
							{
								ReplaceString(scrline,sizeof(scrline),"\"","");
								ReplaceString(scrline,sizeof(scrline),"	"," ");
								TrimString(scrline);
								if (StrContains(scrline,"\"Name\"",false) != -1)
								{
									WritePackString(dp,scrline);
								}
								else if (StrContains(scrline," ",false) > 1)
								{
									WritePackString(dp,scrline);
								}
							}
						}
						CloseHandle(filehandlesub);
						WritePackString(dp,"endofpack");
						PushArrayString(merchantscr,scr);
						PushArrayCell(merchantscrd,dp);
						custentactive[activator] = caller;
						DisplayMerchMenu(activator,GetArraySize(merchantscrd)-1);
					}
					else
					{
						custentactive[activator] = caller;
						DisplayMerchMenu(activator,finddp);
					}
				}
			}
		}
	}
}

void DisplayMerchMenu(int activator, int finddp)
{
	Handle dp = GetArrayCell(merchantscrd,finddp);
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char data[128];
		char title[64];
		Handle items = CreateArray(64);
		ReadPackString(dp,data,sizeof(data));
		while (!StrEqual(data,"endofpack",false))
		{
			if (StrContains(data,"Name",false) == 0)
			{
				Format(title,sizeof(title),"%s",data);
				ReplaceStringEx(title,sizeof(title),"Name","",_,_,false);
				TrimString(title);
				/*
				char tmp[3][64];
				ExplodeString(data," ",tmp,3,64);
				TrimString(tmp[1]);
				TrimString(tmp[2]);
				if (strlen(tmp[2]) > 0) Format(title,sizeof(title),"%s",tmp[2]);
				else if (strlen(tmp[1]) > 0) Format(title,sizeof(title),"%s",tmp[1]);
				*/
			}
			else if (StrContains(data," ",false) != 0)
			{
				PushArrayString(items,data);
			}
			ReadPackString(dp,data,sizeof(data));
		}
		Menu menu = new Menu(MenuHandlersub);
		menu.SetTitle(title);
		char item[64];
		char itemdisplay[64];
		char rebuildupper[32][32];
		for (int i = 0;i<GetArraySize(items);i++)
		{
			GetArrayString(items,i,item,sizeof(item));
			Format(itemdisplay,sizeof(itemdisplay),"%s",item);
			ReplaceStringEx(itemdisplay,sizeof(itemdisplay),"weapon_","",-1,-1,false);
			int maxrun = ExplodeString(itemdisplay,"_",rebuildupper,32,32);
			itemdisplay = "";
			for (int j = 0;j<maxrun;j++)
			{
				if (strlen(rebuildupper[j]) > 0)
				{
					rebuildupper[j][0] &= ~(1 << 5);
					if (strlen(itemdisplay) > 0)
						Format(itemdisplay,sizeof(itemdisplay),"%s %s",itemdisplay,rebuildupper[j]);
					else
						Format(itemdisplay,sizeof(itemdisplay),"%s",rebuildupper[j]);
				}
				else break;
			}
			menu.AddItem(item,itemdisplay);
		}
		CloseHandle(items);
		menu.ExitButton = true;
		menu.Display(activator, 15);
	}
}

public int MenuHandlersub(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (param1 > 0) && (param1 < MaxClients+1))
	{
		char info[128];
		char data[4][64];
		menu.GetItem(param2, info, sizeof(info));
		ExplodeString(info," ",data,4,64);
		TrimString(data[0]);
		TrimString(data[1]);
		if (strlen(data[2]) > 0)
		{
			TrimString(data[2]);
			Format(data[1],sizeof(data[]),"%s",data[2]);
		}
		int points = GetEntProp(param1,Prop_Data,"m_iFrags");
		int cost = StringToInt(data[1]);
		//PrintToServer("Activator %i has %i cost is %i",param1,points,cost);
		if (points >= cost)
		{
			SetEntProp(param1,Prop_Data,"m_iFrags",points-cost);
			CreateCustomItem(param1,data[0],cost);
			MerchSpeakRef(custentactive[param1],param1,1);
		}
		else
		{
			PrintToChat(param1,"Not enough money. You have %i, you need %i",points,cost);
			MerchSpeakRef(custentactive[param1],param1,2);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void CreateCustomItem(int client, char[] info, int cost)
{
	if (IsValidEntity(client))
	{
		char basecls[64];
		Format(basecls,sizeof(basecls),"%s",info);
		if (StrEqual(basecls,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
		else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
		else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
		else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
		else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
		else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
		else if (StrEqual(basecls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
		else if (StrEqual(basecls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
		else if (StrContains(info,"custom_",false) != -1)
		{
			char weapscr[72];
			Format(weapscr,sizeof(weapscr),"scripts/%s.txt",info);
			if (FileExists(weapscr,true,NULL_STRING))
			{
				Handle filehandlesub = OpenFile(weapscr,"r",true,NULL_STRING);
				if (filehandlesub != INVALID_HANDLE)
				{
					char scrline[64];
					while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
					{
						TrimString(scrline);
						if (StrContains(scrline,"\"anim_prefix\"",false) != -1)
						{
							ReplaceStringEx(scrline,sizeof(scrline),"\"anim_prefix\"","",_,_,false);
							ReplaceString(scrline,sizeof(scrline),"\"","");
							TrimString(scrline);
							if (StrEqual(scrline,"python",false)) Format(scrline,sizeof(scrline),"357");
							else if (StrEqual(scrline,"gauss",false)) Format(scrline,sizeof(scrline),"shotgun");
							else if (StrEqual(scrline,"smg2",false)) Format(scrline,sizeof(scrline),"smg1");
							Format(scrline,sizeof(scrline),"weapon_%s",scrline);
							Format(basecls,sizeof(basecls),"%s",scrline);
							break;
						}
					}
				}
				CloseHandle(filehandlesub);
			}
		}
		int createitem = CreateEntityByName(basecls);
		if (createitem != -1)
		{
			if (!StrEqual(info,basecls,false)) DispatchKeyValue(createitem,"classname",info);
			float orgs[3];
			if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
			else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
			orgs[2]+=20.0;
			TeleportEntity(createitem,orgs,NULL_VECTOR,NULL_VECTOR);
			DispatchSpawn(createitem);
			ActivateEntity(createitem);
		}
		else
		{
			int points = GetEntProp(client,Prop_Data,"m_iFrags");
			PrintToChat(client,"Failed to create \"%s\" ask for it to be added to ent list.",basecls);
			PrintToChat(client,"You have been refunded %i",cost);
			SetEntProp(client,Prop_Data,"m_iFrags",points+cost);
		}
	}
}

bool MerchSpeakRef(int entity, int client, int response)
{
	if ((IsValidEntity(entity)) && (entity > 0) && (entity < 2048))
	{
		float Time = GetTickedTime();
		if (centnextsndtime[entity] < Time)
		{
			centnextsndtime[entity] = Time+2.0;
			if (HasEntProp(entity,Prop_Data,"m_initialDelay"))
			{
				int speakref = RoundFloat(GetEntPropFloat(entity,Prop_Data,"m_initialDelay"));
				if (speakref != 0)
				{
					char snd[128];
					switch (speakref)
					{
						case 1:
						{
							//Male
							if (FindStringInArray(precachedarr,"npc_merchant_male") == -1)
							{
								recursion("sound/vo/npc/male01/");
								PrecacheSound("vo\\trainyard\\male01\\cit_pedestrian05.wav",true);
								PushArrayString(precachedarr,"npc_merchant_male");
							}
							//response 0 greet, 1 buy, 2 not enough money
							if (response == 0)
							{
								switch (GetRandomInt(0,11))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\heydoc01.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\heydoc02.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\hi01.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\hi02.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\ahgordon01.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\ahgordon02.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\abouttime01.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\abouttime02.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\docfreeman01.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\docfreeman02.wav");
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\evenodds.wav");
									case 11:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\thislldonicely01.wav");
								}
							}
							else if (response == 1)
							{
								switch (GetRandomInt(0,10))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\yougotit02.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\yeah02.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\squad_affirm01.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\squad_affirm07.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\nice.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\fantastic01.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\fantastic02.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer01.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer25.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer32.wav");
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer33.wav");
								}
							}
							else if (response == 2)
							{
								switch (GetRandomInt(0,20))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\trainyard\\male01\\cit_pedestrian05.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\vanswer13.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\question05.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\question11.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\gordead_ans02.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer02.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer04.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer11.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer12.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer14.wav");
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer17.wav");
									case 11:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer21.wav");
									case 12:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer29.wav");
									case 13:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer35.wav");
									case 14:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer37.wav");
									case 15:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer38.wav");
									case 16:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer39.wav");
									case 17:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\answer40.wav");
									case 18:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\sorrydoc01.wav");
									case 19:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\sorrydoc02.wav");
									case 20:
										Format(snd,sizeof(snd),"vo\\npc\\male01\\sorrydoc04.wav");
								}
							}
							if (strlen(snd) > 0)
							{
								if (response == 2) EmitSoundToClient(client,snd,entity,SNDCHAN_VOICE,SNDLEVEL_NORMAL);
								else EmitSoundToAll(snd, entity, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
							}
						}
						case 2:
						{
							//Female
							if (FindStringInArray(precachedarr,"npc_merchant_female") == -1)
							{
								recursion("sound/vo/npc/female01/");
								PrecacheSound("vo\\trainyard\\female01\\cit_pedestrian05.wav",true);
								PushArrayString(precachedarr,"npc_merchant_female");
							}
							if (response == 0)
							{
								switch (GetRandomInt(0,9))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\heydoc01.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\heydoc02.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\hi01.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\hi02.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\ahgordon01.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\ahgordon02.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\abouttime01.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\abouttime02.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\docfreeman01.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\docfreeman02.wav");
								}
							}
							else if (response == 1)
							{
								switch (GetRandomInt(0,10))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\yougotit02.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\yeah02.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\squad_affirm01.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\squad_affirm07.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\nice.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\fantastic01.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\fantastic02.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer01.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer25.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer32.wav");
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer33.wav");
								}
							}
							else if (response == 2)
							{
								switch (GetRandomInt(0,18))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\trainyard\\female01\\cit_pedestrian05.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\vanswer13.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\question05.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\question11.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\gordead_ans02.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer02.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer04.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer11.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer12.wav");
									case 9:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer17.wav");
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer21.wav");
									case 11:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer29.wav");
									case 12:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer37.wav");
									case 13:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer38.wav");
									case 14:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer39.wav");
									case 15:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\answer40.wav");
									case 16:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\sorrydoc01.wav");
									case 17:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\sorrydoc02.wav");
									case 18:
										Format(snd,sizeof(snd),"vo\\npc\\female01\\sorrydoc04.wav");
								}
							}
							if (strlen(snd) > 0)
							{
								if (response == 2) EmitSoundToClient(client,snd,entity,SNDCHAN_VOICE,SNDLEVEL_NORMAL);
								else EmitSoundToAll(snd, entity, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
							}
						}
						case 3:
						{
							//Monk
							if (FindStringInArray(precachedarr,"npc_merchant_monk") == -1)
							{
								recursion("sound/vo/ravenholm/");
								PushArrayString(precachedarr,"npc_merchant_monk");
							}
							if (response == 0)
							{
								centnextsndtime[entity]+=1.0;
								int randsnd = GetRandomInt(1,22);
								if ((randsnd == 19) || (randsnd == 8)) randsnd++;
								if (randsnd < 10) Format(snd,sizeof(snd),"vo\\ravenholm\\monk_rant0%i.wav",randsnd);
								else
								{
									Format(snd,sizeof(snd),"vo\\ravenholm\\monk_rant%i.wav",randsnd);
								}
							}
							else if (response == 1)
							{
								switch (GetRandomInt(0,3))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_rant19.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_kill05.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_kill08.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_kill09.wav");
								}
							}
							else if (response == 2)
							{
								switch (GetRandomInt(0,2))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_kill04.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_kill10.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\ravenholm\\monk_rant08.wav");
								}
							}
							if (strlen(snd) > 0)
							{
								if (response == 2) EmitSoundToClient(client,snd,entity,SNDCHAN_VOICE,SNDLEVEL_NORMAL);
								else EmitSoundToAll(snd, entity, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
							}
						}
						case 4:
						{
							//Unknown
							if (FindStringInArray(precachedarr,"npc_merchant_unknown") == -1)
							{
								recursion("sound/ambient/levels/citadel/");
								PushArrayString(precachedarr,"npc_merchant_unknown");
							}
							Format(snd,sizeof(snd),"ambient\\levels\\citadel\\strange_talk%i.wav",GetRandomInt(4,11));
							EmitSoundToAll(snd, entity, SNDCHAN_VOICE, SNDLEVEL_TRAIN);
						}
						case 5:
						{
							//Breen
							if (FindStringInArray(precachedarr,"npc_merchant_gman") == -1)
							{
								recursion("sound/vo/citadel/");
								recursion("sound/vo/gman_misc/");
								recursion("sound/vo/breencast/");
								PushArrayString(precachedarr,"npc_merchant_gman");
							}
							if (response == 0)
							{
								switch (GetRandomInt(0,2))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\breencast\\br_tofreeman01.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\breencast\\br_tofreeman02.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\citadel\\br_guest_a.wav");
								}
							}
							else if (response == 1)
							{
								Format(snd,sizeof(snd),"vo\\citadel\\br_guest_b.wav");
							}
							else if (response == 2)
							{
								switch (GetRandomInt(0,7))
								{
									case 0:
									{
										Format(snd,sizeof(snd),"vo\\citadel\\br_circum.wav");
										Handle dp = CreateDataPack();
										WritePackCell(dp,entity);
										WritePackString(dp,snd);
										WritePackCell(dp,SNDCHAN_VOICE);
										CreateTimer(7.0,ResetSoundEnd,dp,TIMER_FLAG_NO_MAPCHANGE);
									}
									case 1:
										Format(snd,sizeof(snd),"vo\\citadel\\br_goback.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\citadel\\br_laugh01.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\citadel\\br_mock04.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\citadel\\br_mock05.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\citadel\\br_mock06.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\citadel\\br_mock07.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\citadel\\br_mock13.wav");
								}
							}
							if (strlen(snd) > 0)
							{
								if (response == 2) EmitSoundToClient(client,snd,entity,SNDCHAN_VOICE,SNDLEVEL_NORMAL);
								else EmitSoundToAll(snd, entity, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
							}
						}
						case 6:
						{
							//GMan
							if (FindStringInArray(precachedarr,"npc_merchant_gman") == -1)
							{
								recursion("sound/vo/citadel/");
								recursion("sound/vo/gman_misc/");
								recursion("sound/vo/breencast/");
								PushArrayString(precachedarr,"npc_merchant_gman");
							}
							if (response == 0)
							{
								Format(snd,sizeof(snd),"vo\\citadel\\gman_exit0%i.wav",GetRandomInt(1,4));
							}
							else if (response == 1)
							{
								Format(snd,sizeof(snd),"vo\\gman_misc\\gman_03.wav");
							}
							else if (response == 2)
							{
								Format(snd,sizeof(snd),"vo\\citadel\\gman_exit07.wav");
								Handle dp = CreateDataPack();
								WritePackCell(dp,entity);
								WritePackString(dp,snd);
								WritePackCell(dp,SNDCHAN_VOICE);
								CreateTimer(7.0,ResetSoundEnd,dp,TIMER_FLAG_NO_MAPCHANGE);
							}
							if (strlen(snd) > 0)
							{
								if (response == 2) EmitSoundToClient(client,snd,entity,SNDCHAN_VOICE,SNDLEVEL_NORMAL);
								else EmitSoundToAll(snd, entity, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
							}
						}
					}
				}
			}
		}
	}
}