#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1;
#pragma newdecls required;

char equipper[128];
int equip = -1;

public void OnPluginStart()
{
	Handle cvar = FindConVar("synsweps_spawnwith");
	if (cvar == INVALID_HANDLE) cvar = CreateConVar("synsweps_spawnwith", "weapon_medkit", "Change what custom weapons you can spawn with. Separate each with a space.");
	HookConVarChange(cvar,spawnwithch);
	CloseHandle(cvar);
}

public void OnMapStart()
{
	if ((GetMapHistorySize() > 0) && (strlen(equipper) > 0))
	{
		equip = CreateEntityByName("info_player_equip");
		if (equip != -1)
		{
			DispatchKeyValue(equip,"ResponseContext",equipper);
			DispatchSpawn(equip);
			ActivateEntity(equip);
		}
	}
}

public void spawnwithch(Handle convar, const char[] oldValue, const char[] newValue)
{
	Format(equipper,sizeof(equipper),"%s",newValue);
	if (IsValidEntity(equip))
	{
		SetEntPropString(equip,Prop_Data,"m_iszResponseContext",newValue);
	}
}
