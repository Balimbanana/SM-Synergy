#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//This is basically just a snippet to allow combine ball death event to trigger.
//This only happens on specific entities such as npc_vortigaunt, where no death event is fired when they are dissolved.

public OnPluginStart()
{
	CreateTimer(0.1,findents);
}

public Action findents(Handle timer)
{
	findent(-1,"npc_vortigaunt");
}

public OnEntityCreated(entity, const char[] classname)
{
	if (StrEqual(classname,"npc_vortigaunt",false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((damagetype == 67108865) && (attacker > 0) && (attacker < MaxClients+1))
	{
		char viccls[24];
		GetEntityClassname(victim,viccls,sizeof(viccls));
		ReplaceString(viccls,sizeof(viccls),"npc_","");
		viccls[0] &= ~(1 << 5);
		Handle syncballkill = CreateEvent("synergy_entity_death");
		SetEventInt(syncballkill,"killercolor",-16083416);
		SetEventInt(syncballkill,"victimcolor",-3644216);
		SetEventString(syncballkill,"weapon","combine_ball");
		SetEventInt(syncballkill,"killerID",attacker);
		SetEventInt(syncballkill,"victimID",victim);
		SetEventBool(syncballkill,"suicide",false);
		char tmpchar[64];
		GetClientName(attacker,tmpchar,sizeof(tmpchar));
		SetEventString(syncballkill,"killername",tmpchar);
		SetEventString(syncballkill,"victimname",viccls);
		SetEventInt(syncballkill,"iconcolor",-1052689);
		CreateTimer(2.0,combballekill,syncballkill);
		FireEntityOutput(victim,"OnDeath",attacker,0.0);
	}
}

public Action combballekill(Handle timer, Handle event)
{
	if (event != INVALID_HANDLE) FireEvent(event,false);
}

public Action findent(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent,clsname);
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		SDKHook(thisent, SDKHook_OnTakeDamage, OnTakeDamage);
		findent(thisent++,clsname);
	}
	return Plugin_Handled;
}
