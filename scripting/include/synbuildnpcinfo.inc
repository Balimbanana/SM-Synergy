#if defined _SynBuildNPCInfo_included
	#endinput
#endif
#define _SynBuildNPCInfo_included

bool SynNPCInfRunning = false;

/**
 * Returns array of custom ent names
 */
native Handle GetNPCNames();

/**
 * Returns array of custom ent indexes
 */
native Handle GetNPCEnts();