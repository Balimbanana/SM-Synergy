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
 */
native void SynFixesReadCache(int client, char[] cache);
