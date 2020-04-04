public Action SynthScannerAttack(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEntity(activator))
	{
		float damageForce[3];
		float dmgset = 5.0;
		float dmgforce = 5.0;
		damageForce[0] = dmgforce;
		damageForce[1] = dmgforce;
		damageForce[2] = dmgforce;
		SDKHooks_TakeDamage(activator,caller,caller,dmgset,DMG_SONIC,-1,damageForce);
	}
}