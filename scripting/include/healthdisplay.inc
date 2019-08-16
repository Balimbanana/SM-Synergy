#if defined _HealthDisplay_included
	#endinput
#endif
#define _HealthDisplay_included

/**
 * Get NPC Ally towards clients
 *
 * @param clsname			target classname to check
 * @param target			The index of the target friend/enemy
 */
native bool CheckNPCAlly(const char[] entclsname, int entitytarget);