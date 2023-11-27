#include <sourcemod>
#include <sdktools>

#pragma semicolon 1;
#pragma newdecls required;

public Plugin myinfo =
{
	name = "Entity Registration",
	author = "Balim",
	description = "Allows for registration of custom entities by config.",
	version = "0.1",
	url = "https://github.com/Balimbanana/SM-Synergy"
}

Handle g_hSDKCallInstallFactory, g_hSDKCallFindFactory, g_hSDKCallEntityFactory;
Handle hCustomClasses;
Handle hCustomClassInfo;

public void OnPluginStart()
{
	RegServerCmd("regfactory", LinkFactory);
	
	hCustomClasses = CreateArray(128);
	hCustomClassInfo = CreateArray(128);
	
	char szSMPath[256];
	char szGameData[256];
	BuildPath(Path_SM, szSMPath, sizeof(szSMPath), "gamedata");
	Format(szGameData, sizeof(szGameData), "%s/entityreg.txt", szSMPath);
	if (FileExists(szGameData, true, NULL_STRING))
	{
		Handle hGameData = LoadGameConfigFile("entityreg");
		if (hGameData != INVALID_HANDLE)
		{
			// ENTITY FACTORY
			StartPrepSDKCall(SDKCall_Static);
			if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "EntityFactoryDictionary"))
			{
				PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
				g_hSDKCallEntityFactory = EndPrepSDKCall();
			}
			
			StartPrepSDKCall(SDKCall_Raw);
			if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEntityFactoryDictionary::FindFactory"))
			{
				PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
				PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
				g_hSDKCallFindFactory = EndPrepSDKCall();
			}
			
			StartPrepSDKCall(SDKCall_Raw);
			if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEntityFactoryDictionary::InstallFactory"))
			{
				PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
				PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
				g_hSDKCallInstallFactory = EndPrepSDKCall();
			}
			//
			if (g_hSDKCallEntityFactory == INVALID_HANDLE)
				PrintToServer("Failed to get EntityFactoryDictionary signature!");
			if (g_hSDKCallFindFactory == INVALID_HANDLE)
				PrintToServer("Failed to get CEntityFactoryDictionary::FindFactory signature!");
			if (g_hSDKCallInstallFactory == INVALID_HANDLE)
				PrintToServer("Failed to get CEntityFactoryDictionary::InstallFactory signature!");
			
			if (g_hSDKCallInstallFactory != INVALID_HANDLE && g_hSDKCallFindFactory != INVALID_HANDLE && g_hSDKCallEntityFactory != INVALID_HANDLE)
			{
				BuildPath(Path_SM, szSMPath, sizeof(szSMPath), "configs");
				Format(szGameData, sizeof(szGameData), "%s/entityregistration.cfg", szSMPath);
				ReplaceString(szGameData, sizeof(szGameData), "\\", "/", false);
				if (FileExists(szGameData, true, NULL_STRING))
				{
					KeyValues hKV = CreateKeyValues("Entities");
					if (!FileToKeyValues(hKV, szGameData))
					{
						PrintToServer("Failed to get entity list!");
						CloseHandle(hKV);
					}
					else
					{
						bool bFirst = KvGotoFirstSubKey(hKV, true);
						char szEntityClass[128];
						char szTemp[128];
						while (bFirst || KvGotoNextKey(hKV, true))
						{
							bFirst = false;
							KvGetSectionName(hKV, szEntityClass, sizeof(szEntityClass));
							KvGetString(hKV, "baseclass", szTemp, sizeof(szTemp), "");
							
							if (strlen(szTemp) < 1)
							{
								continue;
							}
							
							if (RegisterEntity(szTemp, szEntityClass))
							{
								PrintToServer("New registration '%s' with baseclass '%s' succeeded", szEntityClass, szTemp);
							}
							
							KvGetString(hKV, "model", szTemp, sizeof(szTemp), "");
							char szMaxHealth[64];
							KvGetString(hKV, "maxhealth", szMaxHealth, sizeof(szMaxHealth), "8");
							int nSkin = KvGetNum(hKV, "skin", 0);
							int nBody = KvGetNum(hKV, "body", 0);
							
							Handle dp = CreateDataPack();
							WritePackString(dp, szTemp);
							// Stored as a string so you can use CVars potentially
							WritePackString(dp, szMaxHealth);
							WritePackCell(dp, nSkin);
							WritePackCell(dp, nBody);
							
							PushArrayString(hCustomClasses, szEntityClass);
							PushArrayCell(hCustomClassInfo, dp);
						}
						CloseHandle(hKV);
					}
				}
				else
				{
					PrintToServer("There is no '%s' for automatic registration.", szGameData);
				}
			}
		}
		CloseHandle(hGameData);
	}
}

bool RegisterEntity(char[] szBase, char[] szNew)
{
	Address CheckIfExists = view_as<Address>(SDKCall(g_hSDKCallFindFactory, SDKCall(g_hSDKCallEntityFactory), szNew));
	//PrintToServer("RegisterEntity Base: %s New: %s Addr: %i", szBase, szNew, CheckIfExists);
	if (!CheckIfExists)
	{
		Address FindFactory = view_as<Address>(SDKCall(g_hSDKCallFindFactory, SDKCall(g_hSDKCallEntityFactory), szBase));
		if (view_as<int>(FindFactory) > 0)
		{
			SDKCall(g_hSDKCallInstallFactory, SDKCall(g_hSDKCallEntityFactory), FindFactory, szNew);
			
			return true;
		}
	}
	else return false;
	
	return false;
}

public Action LinkFactory(int args)
{
	if (args >= 2)
	{
		if (g_hSDKCallInstallFactory != INVALID_HANDLE && g_hSDKCallFindFactory != INVALID_HANDLE && g_hSDKCallEntityFactory != INVALID_HANDLE)
		{
			char szBase[64], szNew[64];
			GetCmdArg(1, szBase, sizeof(szBase));
			GetCmdArg(2, szNew, sizeof(szNew));
			
			PrintToServer("Begin attempt install '%s' with base '%s'", szNew, szBase);
			PrintToServer("EntFactoryAddr: %i", SDKCall(g_hSDKCallEntityFactory));
			
			Address FindFactory = view_as<Address>(SDKCall(g_hSDKCallFindFactory, SDKCall(g_hSDKCallEntityFactory), szBase));
			
			if (!FindFactory)
			{
				PrintToServer("Factory was not found for entity '%s'", szBase);
				return Plugin_Handled;
			}
			
			PrintToServer("Addr %i", FindFactory);
			
			SDKCall(g_hSDKCallInstallFactory, SDKCall(g_hSDKCallEntityFactory), FindFactory, szNew);
			
			PrintToServer("Installed");
		}
		else
		{
			PrintToServer("Failed to get registration addresses!");
		}
	}
	
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetArraySize(hCustomClasses) > 0)
	{
		int iFindInArr = FindStringInArray(hCustomClasses, classname);
		if (iFindInArr != -1)
		{
			ApplyEntityProperties(entity, iFindInArr);
			CreateTimer(0.1, PostCreateReApply, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action PostCreateReApply(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{
		char szClassname[128];
		GetEntPropString(entity, Prop_Data, "m_iClassname", szClassname, sizeof(szClassname));
		
		int iFindInArr = FindStringInArray(hCustomClasses, szClassname);
		if (iFindInArr != -1)
		{
			ApplyEntityProperties(entity, iFindInArr);
		}
	}
}

void ApplyEntityProperties(int entity, int iFindInArr)
{
	Handle dp = GetArrayCell(hCustomClassInfo, iFindInArr);
	if (dp != INVALID_HANDLE)
	{
		ResetPack(dp);
		char szModel[128];
		char szMaxHealth[64];
		char szSkin[32];
		char szBody[32];
		int nSkin = 0;
		int nBody = 0;
		ReadPackString(dp, szModel, sizeof(szModel));
		ReadPackString(dp, szMaxHealth, sizeof(szMaxHealth));
		ReadPackString(dp, szSkin, sizeof(szSkin));
		ReadPackString(dp, szBody, sizeof(szBody));
		
		// Allow for random range KV "skin" "0-5" would be a random int from 0 to 5
		// Body will also allow for this
		if (StrContains(szSkin, "-", false) > 0)
		{
			char szNullBuffs[3][3];
			ExplodeString(szSkin, "-", szNullBuffs, 3, 3);
			nSkin = GetRandomInt(StringToInt(szNullBuffs[0]), StringToInt(szNullBuffs[1]));
		}
		else
			nSkin = StringToInt(szSkin);
		
		if (StrContains(szBody, "-", false) > 0)
		{
			char szNullBuffs[3][3];
			ExplodeString(szBody, "-", szNullBuffs, 3, 3);
			nBody = GetRandomInt(StringToInt(szNullBuffs[0]), StringToInt(szNullBuffs[1]));
		}
		else
			nBody = StringToInt(szBody);
		
		if (strlen(szModel) > 3)
		{
			DispatchKeyValue(entity, "model", szModel);
			if (!IsModelPrecached(szModel)) PrecacheModel(szModel);
			
			if (HasEntProp(entity, Prop_Data, "m_ModelName"))
				SetEntPropString(entity, Prop_Data, "m_ModelName", szModel);
			
			SetEntityModel(entity, szModel);
		}
		
		if (HasEntProp(entity, Prop_Data, "m_nSkin"))
			SetEntProp(entity, Prop_Data, "m_nSkin", nSkin);
		if (HasEntProp(entity, Prop_Data, "m_nBody"))
			SetEntProp(entity, Prop_Data, "m_nBody", nBody);
		
		if (StringToInt(szMaxHealth) < 1 || (StrContains(szMaxHealth, "sk", false) != -1))
		{
			Handle cv = FindConVar(szMaxHealth);
			if (cv != INVALID_HANDLE)
			{
				GetConVarString(cv, szMaxHealth, sizeof(szMaxHealth));
				DispatchKeyValue(entity, "max_health", szMaxHealth);
				if (HasEntProp(entity, Prop_Data, "m_iMaxHealth"))
					SetEntProp(entity, Prop_Data, "m_iMaxHealth", GetConVarInt(cv));
			}
			CloseHandle(cv);
		}
		else
		{
			DispatchKeyValue(entity, "max_health", szMaxHealth);
			if (HasEntProp(entity, Prop_Data, "m_iMaxHealth"))
				SetEntProp(entity, Prop_Data, "m_iMaxHealth", StringToInt(szMaxHealth));
		}
	}
}