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

/**
 * Returns LI array of entity classnames
 */
native Handle GetLIList();

/**
 * Returns HT array of entity classnames
 */
native Handle GetHTList();