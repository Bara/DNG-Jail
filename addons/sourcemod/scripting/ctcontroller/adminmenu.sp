Handle g_hAdminMenu = null;

public void OnAllPluginsLoaded()
{
	Handle topmenu = null;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);
}

public void OnAdminMenuReady(Handle topmenu)
{
	if(topmenu == g_hAdminMenu)
		return;
	
	g_hAdminMenu = topmenu;
	CreateTimer(1.0, Timer_AttachAdminMenu);
}

public Action Timer_AttachAdminMenu(Handle timer)
{
	TopMenuObject menu_category = AddToTopMenu(g_hAdminMenu, "ctcontroller", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT, "ctcontroller", ADMFLAG_BAN);
	if( menu_category == INVALID_TOPMENUOBJECT )
		return;
	
	AddToTopMenu(g_hAdminMenu, "sm_verct", TopMenuObject_Item, AdminMenu_VerCT, menu_category, "sm_verct", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "sm_vertmpct", TopMenuObject_Item, AdminMenu_VerTMPCT, menu_category, "sm_vertmpct", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "sm_ctunban", TopMenuObject_Item, AdminMenu_CTUnBan, menu_category, "sm_ctunban", ADMFLAG_BAN);
}

public void Handle_Category(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "AdminMenu: Main");
	else if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "AdminMenu: Main");
}

public void AdminMenu_VerCT(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "AdminMenu: Verify");
	else if (action == TopMenuAction_SelectOption)
		ShowVerifyPlayers(param, false);
}

public void AdminMenu_VerTMPCT(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "AdminMenu: Temp Verify");
	else if (action == TopMenuAction_SelectOption)
		ShowVerifyPlayers(param, true);
}

public void AdminMenu_CTUnBan(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "AdminMenu: CTUnBan");
	else if (action == TopMenuAction_SelectOption)
		ShowCTUnBanPlayers(param);
}

void ShowVerifyPlayers(int client, bool temp)
{
	Handle hMenu = null;
	
	if(temp)
		hMenu = CreateMenu(MenuHandler_TempVerifyPlayer);
	else
		hMenu = CreateMenu(MenuHandler_VerifyPlayer);
	
	SetMenuTitle(hMenu, "AdminMenu: ChoosePlayer", client);
	SetMenuExitBackButton(hMenu, true);
	
	char sName[MAX_NAME_LENGTH], sTarget[18];
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientValid(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
		{
			if(g_bBanned[i] || !CanUserTarget(client, i))
				continue;
			
			GetClientName(i, sName, sizeof(sName));
			int iUserID = GetClientUserId(i);
			IntToString(iUserID, sTarget, sizeof(sTarget));
			
			if(!g_bVerify[i])
				Format(sName, sizeof(sName), "[ ] %s", sName);
			else
				Format(sName, sizeof(sName), "[X] %s", sName);
			
			AddMenuItem(hMenu, sTarget, sName);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

void ShowCTUnBanPlayers(int client)
{
	Handle hMenu = hMenu = CreateMenu(MenuHandler_CTUnbanPlayer);
	
	SetMenuTitle(hMenu, "AdminMenu: ChoosePlayer", client);
	SetMenuExitBackButton(hMenu, true);
	
	char sName[MAX_NAME_LENGTH], sTarget[18];
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientValid(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
		{
			if(!g_bBanned[i] || !CanUserTarget(client, i))
				continue;
				
			GetClientName(i, sName, sizeof(sName));
			int iUserID = GetClientUserId(i);
			IntToString(iUserID, sTarget, sizeof(sTarget));
			
			Format(sName, sizeof(sName), "%s", sName);
			
			AddMenuItem(hMenu, sTarget, sName);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_VerifyPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_Cancel)
	{
		if(IsClientValid(param1))
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu != null)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		int userid = StringToInt(info);
		int target = GetClientOfUserId(userid);

		if(!g_bVerify[target])
			VerifyClient(target, param1);
		else
			UnVerifyClient(target, param1);
	}
}

public int MenuHandler_TempVerifyPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_Cancel)
	{
		if(IsClientValid(param1))
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu != null)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		int userid = StringToInt(info);
		int target = GetClientOfUserId(userid);
		
		if(!g_bVerify[target])
			TempVerifyClient(target, param1);
		else
			UnTempVerifyClient(target, param1);
	}
}

public int MenuHandler_CTUnbanPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_Cancel)
	{
		if(IsClientValid(param1))
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu != null)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		int userid = StringToInt(info);
		int target = GetClientOfUserId(userid);

		UnBanCTClient(target, param1);
	}
}
