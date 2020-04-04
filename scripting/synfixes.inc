#if defined _SynFixes_included
	#endinput
#endif
#define _SynFixes_included

bool SynFixesRunning = false;

/**
 * Returns array of custom ents
 */
native Handle GetCustomEntList();

/**
 * Read specific entity cache to rebuild ents
 *
 * @param client			client index to print debug info to
 * @param cache				path to the cache to read
 * @param offsetpos			position to offset spawned ents
 */
native void SynFixesReadCache(int client, char[] cache, float offsetpos[3]);

/**
 * Forward for hooking entity inputs
 * @param input				input string passed as of current
 * @param activator			activator which fired input
 * @param inputtarget		input is being fired to this entity
 * @param parameter		parameter of input being fired
 */
forward void SFHookEntityInput(char[] input, int activator, char[] inputtarget, char[] parameter);

/**
 * Add entity input to hook
 * @param input				input string to hook
 */
native void SFAddHookEntityInput(char[] input);