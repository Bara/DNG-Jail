
public Action Command_CTList(int client, int args)
{
	ShowCTVerifyList(client);
}

public Action Command_CTBanList(int client, int args)
{
	ShowCTBanList(client);
}

public Action Command_VerifyCT(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%T", "VERCT - Usage", client);
		return Plugin_Handled;
	}
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = FindTarget(client, arg1, true, true);
	
	if (target < 1)
	{
		return Plugin_Handled;
	}
		
	if(g_bBanned[target])
	{
		CReplyToCommand(client, "%T", "Banned Player", client, target);
		return Plugin_Handled;
	}
		
	if(!g_bVerify[target])
		VerifyClient(target, client);
	else
		UnVerifyClient(target, client);
	
	return Plugin_Handled;
}

public Action Command_VerifyTempCT(int client, int args)
{
	if (args != 1)
	{
		CReplyToCommand(client, "%T", "VERTMPCT - Usage", client);
		
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = FindTarget(client, arg1, true, true);
	
	if (target < 1)
	{
		return Plugin_Handled;
	}
		
	if(g_bBanned[target])
	{
		CReplyToCommand(client, "%T", "Banned Player", client, target);
		return Plugin_Handled;
	}
		
	if(!g_bVerify[target])
		TempVerifyClient(target, client);
	else
		UnTempVerifyClient(target, client);
	
	return Plugin_Handled;
}

public Action Command_CTBan(int client, int args)
{
	if(args < 2)
	{
		// Command -      1       -   2    -   3
		// sm_ctban <Name/#UserID> <Rounds> <Reason>
		CReplyToCommand(client, "%T", "CTBAN - Usage", client);
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, true);
	
	if (target < 1)
	{
		return Plugin_Handled;
	}
	
	char arg2[12];
	GetCmdArg(2, arg2, sizeof(arg2));
	int iRounds = StringToInt(arg2);
	
	char sReason[128], sBuffer[128];
	if(args == 1)
		Format(sReason, sizeof(sReason), "No reason");
	else 
	{
		for (int i = 3; i <= args; i++)
		{
			GetCmdArg(i, sBuffer, sizeof(sBuffer));
			Format(sReason, sizeof(sReason), "%s %s", sReason , sBuffer);
		}
	}
	
	if(!g_bBanned[target])
		BanCTClient(target, client, iRounds, sReason);
	else
		CReplyToCommand(client, "%T", "Already Banned Player", client, target);
	
	return Plugin_Handled;
}

public Action Command_CTUnBan(int client, int args)
{
	if(args != 1)
	{
		CReplyToCommand(client, "%T", "CTUNBAN - Usage", client);
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, true);
	
	if (target < 1)
	{
		return Plugin_Handled;
	}
	
	if(g_bBanned[target])
		UnBanCTClient(target, client);
	else
		CReplyToCommand(client, "%T", "Isnot Banned Player", client, target);
	
	return Plugin_Handled;
}
