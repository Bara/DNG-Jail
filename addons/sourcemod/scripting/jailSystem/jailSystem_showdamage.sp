void Showdamage_PlayerHurt(int client, int damage)
{
	if (!g_cEnableShowDamage.BoolValue)
	{
		return;
	}

	PrintCenterText(client, "- %i HP", damage);
}