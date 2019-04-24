public void sqlLoadClient(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlLoadClient) Fail at Query: %s", CNAME, error);
		return;
	}
	else
	{
		int client = GetClientOfUserId(data);
			
		if(preIsClientValid(client))
		{
			if (results.RowCount > 0 && results.FetchRow())
			{
				g_bVerify[client] = view_as<bool>(results.FetchInt(0));
				g_bBanned[client] = view_as<bool>(results.FetchInt(1));
				
				if (g_bBanned[client])
				{
					if (results.FetchInt(2) > 0)
					{
						g_iRounds[client] = results.FetchInt(2);
					}
					else if (results.FetchInt(2) == 0)
					{
						g_iRounds[client] = -1;
					}

					results.FetchString(3, g_sReason[client], sizeof(g_sReason[]));
				}
				
				g_bReady[client] = true;
				
				if(bLogMessage && bDebug)
					LogMessage("[sqlLoadClient] \"%L\" - Verify: %d - Banned: %d - Rounds: %d", client, g_bVerify[client], g_bBanned[client], g_iRounds[client]);
			}
			else
			{
				g_bVerify[client] = false;
				g_bBanned[client] = false;
				g_bReady[client] = true;
				
				if(bLogMessage && bDebug)
					LogMessage("[sqlLoadClient] \"%L\" - Verify: %d - Banned: %d", client, g_bVerify[client], g_bBanned[client]);
			}
		}
	}
}

public void sqlConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		SetFailState("[%s] (sqlConnect) Can't connect to database: \"ctcontroller\"", CNAME);
		return;
	}
	
	g_dDB = view_as<Database>(CloneHandle(hndl));
	
	CreateTable();
}

public void sqlCreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlCreateTable) Fail at Query: %s", CNAME, error);
		return;
	}
	delete results;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			if (GetClientAuthId(i, AuthId_SteamID64, g_sClientID[i], sizeof(g_sClientID[])))
				LoadClient(i);
		}
	}
	
	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `ct_controller_logs` ( `id` INT NOT NULL AUTO_INCREMENT, `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `communityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `action` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `value` tinyint(1) NOT NULL, `rounds` int(11) NOT NULL, `reason` text COLLATE utf8mb4_unicode_ci NOT NULL, `adminid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `date` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
	
	if(bLogMessage && bDebug)
		LogMessage(sQuery);
	
	g_dDB.Query(sqlCreateLogsTable, sQuery);
}

public void sqlCreateLogsTable(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlCreateLogsTable) Fail at Query: %s", CNAME, error);
		return;
	}
	delete results;
}

public void sqlInsertLog(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlInsertLog) Fail at Query: %s", CNAME, error);
		return;
	}
	delete results;
}

public void sqlVeriyClient(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlVeriyClient) Fail at Query: %s", CNAME, error);
		return;
	}
	
	delete results;
}

public void sqlCTBanClient(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlCTBanClient) Fail at Query: %s", CNAME, error);
		return;
	}
	
	delete results;
}

public void sqlCTUnBanClient(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlCTUnBanClient) Fail at Query: %s", CNAME, error);
		return;
	}
	
	delete results;
}

public void sqlInsertUnVeriyClient(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlInsertUnVeriyClient) Fail at Query: %s", CNAME, error);
		return;
	}
	
	delete results;
}

public void sqlUpdateUnVeriyClient(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlUpdateUnVeriyClient) Fail at Query: %s", CNAME, error);
		return;
	}
	
	delete results;
}

public void sqlUpdateRounds(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (sqlUpdateRounds) Fail at Query: %s", CNAME, error);
		return;
	}
	
	delete results;
}
