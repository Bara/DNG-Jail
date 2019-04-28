void MySQL_OnPluginStart()
{
	SQL_TConnect(sqlConnect, "jail");
}

public void sqlConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		SetFailState("[%s] (sqlConnect) Can't connect to database: \"jail\"", PL_NAME);
		return;
	}
	
	g_dDB = view_as<Database>(CloneHandle(hndl));
	
	Call_StartForward(g_hOnMySQLConnect);
	Call_PushCell(view_as<int>(g_dDB));
	Call_Finish();
	
	Freekill_CreateTables();
}

public int Native_GetDatabase(Handle plugin, int params)
{
	if (g_dDB != null)
	{
		return view_as<int>(g_dDB);
	}
	
	return -1;
}

void Freekill_CreateTables()
{
	char sQuery[1024];
	/*
		`id` INT NOT NULL AUTO_INCREMENT,
		`date` int(11) NOT NULL,
		`map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
		`vCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
		`vName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
		`aCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
		`aName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
		`reason` text COLLATE utf8mb4_unicode_ci NOT NULL,
	*/
	g_dDB.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `freekill_reports` (`id` INT NOT NULL AUTO_INCREMENT, `date` int(11) COLLATE utf8mb4_unicode_ci NOT NULL, `map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL, `vCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `vName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `aCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `aName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `reason` text COLLATE utf8mb4_unicode_ci NOT NULL, PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
	g_dDB.Query(Freekill_CreateReportsTable, sQuery);
	
	/*
		`id` INT NOT NULL AUTO_INCREMENT,
		`date` int(11) NOT NULL,
		`map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
		`vCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
		`vName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
		`aCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
		`aName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
		`banned` tinyint(1) NOT NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY (`vCommunityid`)
	*/
	g_dDB.Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `freekill_bans` (`id` INT NOT NULL AUTO_INCREMENT, `date` int(11) NOT NULL, `map` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL, `vCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `vName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `aCommunityid` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL, `aName` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL, `banned` tinyint(1) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY (`vCommunityid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
	g_dDB.Query(Freekill_CreateBansTable, sQuery);
}

public void Freekill_CreateReportsTable(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (Freekill_CreateReportsTable) Fail at Query: %s", PL_NAME, error);
		return;
	}
	delete results;
}

public void Freekill_CreateBansTable(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (Freekill_CreateBansTable) Fail at Query: %s", PL_NAME, error);
		return;
	}
	delete results;
	
	LoopClients(client)
		Freekill_GetStatus(client);
}

public void Freekill_InsertQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (Freekill_InsertQuery) Fail at Query: %s", PL_NAME, error);
		return;
	}
	
	delete results;
}

public void Freekill_InsertQueryBans(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (Freekill_InsertQueryBans) Fail at Query: %s", PL_NAME, error);
		return;
	}
	
	delete results;
}

public void Freekill_UpdateQueryBans(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (Freekill_UpdateQueryBans) Fail at Query: %s", PL_NAME, error);
		return;
	}
	
	delete results;
}

public void Freekill_GetStatusQuery(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || strlen(error) > 0)
	{
		SetFailState("[%s] (Freekill_GetStatusQuery) Fail at Query: %s", PL_NAME, error);
		return;
	}
	else
	{
		int client = GetClientOfUserId(data);
		
		if(IsClientValid(client))
		{
			if (results.FetchRow())
			{
				g_bFKBan[client] = view_as<bool>(results.FetchInt(0));
				g_bFKSQL[client] = true;
			}
			else
				g_bFKBan[client] = false;
		}
	}
	
	delete results;
}
