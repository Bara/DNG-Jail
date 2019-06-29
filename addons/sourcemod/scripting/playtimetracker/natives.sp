public int Native_GetPlayerTimeT(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		return g_iPlayerTime[client][PlayerInfo_TimeT];
	
	return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
}

public int Native_GetPlayerTimeCT(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (IsClientInGame(client))
		return g_iPlayerTime[client][PlayerInfo_TimeCT];
	
	else return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
}