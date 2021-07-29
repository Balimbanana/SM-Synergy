Handle merchantscr = INVALID_HANDLE;
Handle merchantscrd = INVALID_HANDLE;
Handle hMerchCVar = INVALID_HANDLE;
char szMerchPropType[32];
int iMerchantCType = 0;

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
						//char rebuildupper[32][32];
						int iReadLines = 0;
						char szNull[64][2];
						Handle dp = CreateDataPack();
						Handle filehandlesub = OpenFile(scr,"r",true,NULL_STRING);
						if (filehandlesub != INVALID_HANDLE)
						{
							char scrline[256];
							while(!IsEndOfFile(filehandlesub)&&ReadFileLine(filehandlesub,scrline,sizeof(scrline)))
							{
								iReadLines++;
								int iCategory = ExplodeString(scrline,"\"",szNull,64,2);
								ReplaceString(scrline,sizeof(scrline),"\"","");
								ReplaceString(scrline,sizeof(scrline),"	"," ");
								TrimString(scrline);
								if (StrContains(scrline,"\"Name\"",false) != -1)
								{
									WritePackString(dp,scrline);
								}
								else if ((iCategory == 3) && (iReadLines > 1))
								{
									Format(scrline,sizeof(scrline),"szCategory\"%s",scrline);
									WritePackString(dp,scrline);
								}
								else if (StrContains(scrline," ",false) > 1)
								{
									/*
									int maxrun = ExplodeString(scrline," ",rebuildupper,32,32);
									scrline = "";
									for(int j = 0;j<maxrun;j++)
									{
										if (strlen(rebuildupper[j]) > 0)
										{
											if (j == maxrun-1) Format(scrline,sizeof(scrline),"%s $%s",scrline,rebuildupper[j]);
											else
											{
												if (strlen(scrline) < 1)
													Format(scrline,sizeof(scrline),"%s",rebuildupper[j]);
												else
													Format(scrline,sizeof(scrline),"%s %s",scrline,rebuildupper[j]);
											}
										}
									}
									if (strlen(scrline) > 0)
									*/
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
		bool bCategorized = false;
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
			else if (StrContains(data,"szCategory\"",false) == 0)
			{
				ReplaceStringEx(data,sizeof(data),"szCategory\"","",_,_,false);
				if (!bCategorized)
				{
					bCategorized = true;
					ClearArray(items);
				}
				PushArrayString(items,data);
			}
			else if ((StrContains(data," ",false) != 0) && (!bCategorized))
			{
				PushArrayString(items,data);
			}
			ReadPackString(dp,data,sizeof(data));
		}
		MenuCreateSetup(activator,items,title,bCategorized,finddp);
	}
}

void MenuCreateSetup(int client, Handle items, char[] title, bool bCategorized, int finddp)
{
	if ((IsValidEntity(client)) && (items != INVALID_HANDLE))
	{
		Menu menu;
		if (!bCategorized)
		{
			menu = new Menu(MenuHandlersub);
			menu.ExitBackButton = true;
			switch(iMerchantCType)
			{
				case 0:
					Format(title,64,"%s Cost: Kills",title);
				case 1:
					Format(title,64,"%s Cost: Score",title);
				case 2:
					Format(title,64,"%s Cost: Custom",title);
			}
		}
		else menu = new Menu(MenuHandlercategory);
		menu.SetTitle(title);
		char item[256];
		char itemdisplay[64];
		char rebuildupper[16][32];
		int iFindSpace = -1;
		for (int i = 0;i<GetArraySize(items);i++)
		{
			GetArrayString(items,i,item,sizeof(item));
			Format(itemdisplay,sizeof(itemdisplay),"%s",item);
			if (StrContains(itemdisplay,"srvcmd",false) != -1)
			{
				iFindSpace = StrContains(itemdisplay,"srvcmd",false);
				if (iFindSpace != -1)
				{
					Format(itemdisplay,iFindSpace+1,"%s",itemdisplay);
				}
			}
			else
			{
				if (!bCategorized)
				{
					iFindSpace = StrContains(itemdisplay," ",false);
					if (iFindSpace != -1)
					{
						Format(itemdisplay,iFindSpace+1,"%s",itemdisplay);
					}
				}
			}
			ReplaceStringEx(itemdisplay,sizeof(itemdisplay),"weapon_","",-1,-1,false);
			int maxrun = ExplodeString(itemdisplay,"_",rebuildupper,16,32);
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
			maxrun = ExplodeString(item," ",rebuildupper,16,32);
			if (!bCategorized) Format(itemdisplay,sizeof(itemdisplay),"%s ($%s)",itemdisplay,rebuildupper[maxrun-1]);
			else Format(item,sizeof(item),"%i_%s",finddp,item);
			menu.AddItem(item,itemdisplay);
		}
		CloseHandle(items);
		menu.ExitButton = true;
		menu.Display(client, 15);
	}
}

public int MenuHandlersub(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (param1 > 0) && (param1 < MaxClients+1))
	{
		char info[256];
		char data[16][64];
		menu.GetItem(param2, info, sizeof(info));
		int iCostpos = ExplodeString(info," ",data,16,64);
		TrimString(data[0]);
		TrimString(data[iCostpos-1]);
		/*
		if (strlen(data[2]) > 0)
		{
			TrimString(data[2]);
			Format(data[1],sizeof(data[]),"%s",data[2]);
		}
		*/
		int points = 0;
		switch(iMerchantCType)
		{
			case 0:
				points = GetEntProp(param1,Prop_Data,"m_iFrags");
			case 1:
				points = GetEntProp(param1,Prop_Data,"m_iPoints");
			case 2:
			{
				if (HasEntProp(param1,Prop_Data,szMerchPropType))
				{
					points = GetEntProp(param1,Prop_Data,szMerchPropType);
				}
			}
		}
		int cost = StringToInt(data[iCostpos-1]);
		//PrintToServer("Activator %i has %i cost is %i",param1,points,cost);
		if (points >= cost)
		{
			switch(iMerchantCType)
			{
				case 0:
					SetEntProp(param1,Prop_Data,"m_iFrags",points-cost);
				case 1:
					SetEntProp(param1,Prop_Data,"m_iPoints",points-cost);
				case 2:
				{
					if (HasEntProp(param1,Prop_Data,szMerchPropType))
					{
						SetEntProp(param1,Prop_Data,szMerchPropType,points-cost);
					}
				}
			}
			if (iCostpos > 0)
			{
				Format(info,sizeof(info),"%s",data[0]);
				for (int i = 1;i<iCostpos;i++)
				{
					Format(info,sizeof(info),"%s %s",info,data[i]);
				}
			}
			CreateCustomItem(param1,info,cost);
			MerchSpeakRef(custentactive[param1],param1,1);
		}
		else
		{
			PrintToChat(param1,"Not enough money. You have %i, you need %i",points,cost);
			MerchSpeakRef(custentactive[param1],param1,2);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == -6)
		{
			MerchantUse("OnUser1",custentactive[param1],param1,0.0);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int MenuHandlercategory(Menu menu, MenuAction action, int param1, int param2)
{
	if ((action == MenuAction_Select) && (param1 > 0) && (param1 < MaxClients+1))
	{
		char info[256];
		char szDP[3][8];
		menu.GetItem(param2, info, sizeof(info));
		int finddp = ExplodeString(info,"_",szDP,3,8);
		finddp = StringToInt(szDP[0]);
		ReplaceStringEx(info,sizeof(info),szDP[0],"",_,_,false);
		ReplaceStringEx(info,sizeof(info),"_","",_,_,false);
		if (finddp >= GetArraySize(merchantscrd)) return -1;
		Handle dp = GetArrayCell(merchantscrd,finddp);
		if (dp != INVALID_HANDLE)
		{
			ResetPack(dp);
			char data[128];
			char title[64];
			Handle items = CreateArray(64);
			bool bBeginItems = false;
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
				else if (StrContains(data,"szCategory\"",false) == 0)
				{
					ReplaceStringEx(data,sizeof(data),"szCategory\"","",_,_,false);
					if (StrEqual(data,info,false))
					{
						bBeginItems = true;
					}
					else bBeginItems = false;
				}
				else if ((StrContains(data," ",false) != 0) && (bBeginItems))
				{
					PushArrayString(items,data);
				}
				ReadPackString(dp,data,sizeof(data));
			}
			MenuCreateSetup(param1,items,title,false,finddp);
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
		char basecls[128];
		char infcls[64];
		int iFindSpace = StrContains(info," ",false);
		if (iFindSpace != -1)
		{
			Format(basecls,iFindSpace+1,"%s",info);
		}
		else Format(basecls,sizeof(basecls),"%s",info);
		if (StrContains(info,"srvcmd",false) != -1)
		{
			iFindSpace = StrContains(info,"srvcmd",false);
			if (iFindSpace != -1)
			{
				Format(infcls,iFindSpace+1,"%s",info);
				Format(basecls,sizeof(basecls),"%s",info);
				ReplaceStringEx(basecls,sizeof(basecls),infcls,"",_,_,false);
				ReplaceStringEx(basecls,sizeof(basecls),"srvcmd ","",_,_,false);
				char data[16][64];
				TrimString(basecls);
				if (StrContains(basecls,"'",false) != -1)
				{
					ReplaceStringEx(basecls,sizeof(basecls),"'","",_,_,false);
					iFindSpace = ExplodeString(basecls,"'",data,16,64);
					Format(basecls,sizeof(basecls),"%s",data[0]);
				}
				else iFindSpace = ExplodeString(basecls," ",data,16,64);
				Format(basecls,sizeof(basecls),"%s",data[0]);
				for (int i = 1;i<iFindSpace;i++)
				{
					Format(basecls,sizeof(basecls),"%s",basecls,data[i]);
				}
				char szCL[4];
				Format(szCL,sizeof(szCL),"%i",client);
				ReplaceString(basecls,sizeof(basecls),"$1",szCL,false);
				//Add merch dbg message
				ServerCommand("%s",basecls);
			}
		}
		else
		{
			Format(infcls,sizeof(infcls),"%s",basecls);
			if (StrEqual(basecls,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
			else if (StrEqual(basecls,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
			else if ((StrEqual(basecls,"weapon_glock",false)) || (StrEqual(basecls,"weapon_pistol_worker",false)) || (StrEqual(basecls,"weapon_flaregun",false)) || (StrEqual(basecls,"weapon_manhack",false)) || (StrEqual(basecls,"weapon_manhackgun",false)) || (StrEqual(basecls,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
			else if ((StrEqual(basecls,"weapon_medkit",false)) || (StrEqual(basecls,"weapon_healer",false)) || (StrEqual(basecls,"weapon_snark",false)) || (StrEqual(basecls,"weapon_hivehand",false)) || (StrEqual(basecls,"weapon_satchel",false)) || (StrEqual(basecls,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
			else if ((StrEqual(basecls,"weapon_mp5",false)) || (StrEqual(basecls,"weapon_sl8",false)) || (StrEqual(basecls,"weapon_uzi",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
			else if ((StrEqual(basecls,"weapon_gauss",false)) || (StrEqual(basecls,"weapon_tau",false)) || (StrEqual(basecls,"weapon_sniperrifle",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
			else if (StrEqual(basecls,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
			else if (StrEqual(basecls,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
			else if (StrContains(basecls,"custom_",false) != -1)
			{
				char weapscr[72];
				Format(weapscr,sizeof(weapscr),"scripts/%s.txt",basecls);
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
				if (!StrEqual(infcls,basecls,false)) DispatchKeyValue(createitem,"classname",infcls);
				float orgs[3];
				if (HasEntProp(client,Prop_Data,"m_vecAbsOrigin")) GetEntPropVector(client,Prop_Data,"m_vecAbsOrigin",orgs);
				else if (HasEntProp(client,Prop_Send,"m_vecOrigin")) GetEntPropVector(client,Prop_Send,"m_vecOrigin",orgs);
				orgs[2]+=20.0;
				TeleportEntity(createitem,orgs,NULL_VECTOR,NULL_VECTOR);
				if (iFindSpace != -1)
				{
					char data[16][64];
					//PrintToServer("KeysSet %s",info);
					int iMaxKeys = ExplodeString(info," ",data,16,64);
					for (int i = 1;i<iMaxKeys;i++)
					{
						if (strlen(data[i+1]) > 0)
							DispatchKeyValue(createitem,data[i],data[i+1]);
						i++;
					}
				}
				DispatchSpawn(createitem);
				ActivateEntity(createitem);
			}
			else
			{
				int points = 0;
				switch(iMerchantCType)
				{
					case 0:
						points = GetEntProp(client,Prop_Data,"m_iFrags");
					case 1:
						points = GetEntProp(client,Prop_Data,"m_iPoints");
					case 2:
					{
						if (HasEntProp(client,Prop_Data,szMerchPropType))
						{
							points = GetEntProp(client,Prop_Data,szMerchPropType);
						}
					}
				}
				PrintToChat(client,"Failed to create \"%s\" ask for it to be added to ent list.",basecls);
				PrintToChat(client,"You have been refunded %i",cost);
				switch(iMerchantCType)
				{
					case 0:
						SetEntProp(client,Prop_Data,"m_iFrags",points+cost);
					case 1:
						SetEntProp(client,Prop_Data,"m_iPoints",points+cost);
					case 2:
					{
						if (HasEntProp(client,Prop_Data,szMerchPropType))
						{
							SetEntProp(client,Prop_Data,szMerchPropType,points+cost);
						}
					}
				}
			}
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
						case 7:
						{
							//Vort
							if (FindStringInArray(precachedarr,"npc_merchant_vort") == -1)
							{
								recursion("sound/vo/canals/");
								recursion("sound/vo/npc/vortigaunt/");
								PushArrayString(precachedarr,"npc_merchant_vort");
							}
							if (response == 0)
							{
								switch (GetRandomInt(0,8))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\canals\\vort_reckoning.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\beofservice.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\dreamed.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\fmhonorsus.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\greetingsfm.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\isitthefm.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\itishonor.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\mystery.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\vmono_17.wav");
								}
							}
							else if (response == 1)
							{
								switch (GetRandomInt(0,8))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\affirmed.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\allwehave.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\asyouwish.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\certainly.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\done.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\fmcanuse.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\gladly.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\honorours.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\keepfmsafe.wav");
								}
							}
							else if (response == 2)
							{
								switch (GetRandomInt(0,11))
								{
									case 0:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\alldear.wav");
									case 1:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\calm.wav");
									case 2:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\giveover.wav");
									case 3:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\hopeless.wav");
									case 4:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\opaque.wav");
									case 5:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\regrettable.wav");
									case 6:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\seenworse.wav");
									case 7:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\undeserving.wav");
									case 8:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\vanswer01.wav");
									case 9:
									{
										int randsnd = GetRandomInt(1,14);
										if (randsnd < 10) Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\vanswer0%i.wav",randsnd);
										else Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\vanswer%i.wav",randsnd);
									}
									case 10:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\vmono_12.wav");
									case 11:
										Format(snd,sizeof(snd),"vo\\npc\\vortigaunt\\vmono_25.wav");
								}
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