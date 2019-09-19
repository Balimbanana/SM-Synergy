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
						DisplayMerchMenu(activator,GetArraySize(merchantscrd)-1);
					}
					else
					{
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
				char tmp[3][64];
				ExplodeString(data," ",tmp,3,64);
				TrimString(tmp[1]);
				TrimString(tmp[2]);
				if (strlen(tmp[2]) > 0) Format(title,sizeof(title),"%s",tmp[2]);
				else if (strlen(tmp[1]) > 0) Format(title,sizeof(title),"%s",tmp[1]);
			}
			else if (StrContains(data," ",false) != 0)
			{
				PushArrayString(items,data);
			}
			ReadPackString(dp,data,sizeof(data));
		}
		Menu menu = new Menu(MenuHandlersub);
		menu.SetTitle(title);
		for (int i = 0;i<GetArraySize(items);i++)
		{
			char item[64];
			GetArrayString(items,i,item,sizeof(item));
			menu.AddItem(item,item);
		}
		CloseHandle(items);
		menu.ExitButton = true;
		menu.Display(activator, MENU_TIME_FOREVER);
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
		int points = GetEntProp(param1,Prop_Data,"m_iPoints");
		int cost = StringToInt(data[1]);
		//PrintToServer("Activator %i has %i cost is %i",param1,points,cost);
		if (points >= cost)
		{
			SetEntProp(param1,Prop_Data,"m_iPoints",points-cost);
			CreateCustomItem(param1,data[0],cost);
		}
		else
		{
			PrintToChat(param1,"Not enough money. You have %i, you need %i",points,cost);
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
		if (StrEqual(info,"weapon_gluon",false)) Format(basecls,sizeof(basecls),"weapon_shotgun");
		else if (StrEqual(info,"weapon_handgrenade",false)) Format(basecls,sizeof(basecls),"weapon_frag");
		else if ((StrEqual(info,"weapon_glock",false)) || (StrEqual(info,"weapon_pistol_worker",false)) || (StrEqual(info,"weapon_flaregun",false)) || (StrEqual(info,"weapon_manhack",false)) || (StrEqual(info,"weapon_manhackgun",false)) || (StrEqual(info,"weapon_manhacktoss",false))) Format(basecls,sizeof(basecls),"weapon_pistol");
		else if ((StrEqual(info,"weapon_medkit",false)) || (StrEqual(info,"weapon_snark",false)) || (StrEqual(info,"weapon_hivehand",false)) || (StrEqual(info,"weapon_hornetgun",false)) || (StrEqual(info,"weapon_satchel",false)) || (StrEqual(info,"weapon_tripmine",false))) Format(basecls,sizeof(basecls),"weapon_slam");
		else if ((StrEqual(info,"weapon_mp5",false)) || (StrEqual(info,"weapon_m4",false)) || (StrEqual(info,"weapon_sl8",false)) || (StrEqual(info,"weapon_g36c",false)) || (StrEqual(info,"weapon_oicw",false))) Format(basecls,sizeof(basecls),"weapon_smg1");
		else if ((StrEqual(info,"weapon_gauss",false)) || (StrEqual(info,"weapon_tau",false))) Format(basecls,sizeof(basecls),"weapon_ar2");
		else if (StrEqual(info,"weapon_cguard",false)) Format(basecls,sizeof(basecls),"weapon_stunstick");
		else if (StrEqual(info,"weapon_axe",false)) Format(basecls,sizeof(basecls),"weapon_pipe");
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
			int points = GetEntProp(client,Prop_Data,"m_iPoints");
			PrintToChat(client,"Failed to create \"%s\" ask for it to be added to ent list.",basecls);
			PrintToChat(client,"You have been refunded %i",cost);
			SetEntProp(client,Prop_Data,"m_iPoints",points+cost);
		}
	}
}