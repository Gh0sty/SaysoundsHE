//*****************************************************************
//	------------------------------------------------------------- *
//						*** Menu Handling ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public OnAdminMenuReady(Handle:topmenu)
{
	/*************************************************************/
	/* Add a Play Admin Sound option to the SourceMod Admin Menu */
	/*************************************************************/

	/* Block us from being called twice */
	if (topmenu != hAdminMenu)
	{
		/* Save the Handle */
		hAdminMenu = topmenu;
		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		AddToTopMenu(hAdminMenu, "sm_admin_sounds", TopMenuObject_Item, Play_Admin_Sound,
					 server_commands, "sm_admin_sounds", ADMFLAG_GENERIC);
		AddToTopMenu(hAdminMenu, "sm_karaoke", TopMenuObject_Item, Play_Karaoke_Sound, server_commands, "sm_karaoke", ADMFLAG_CHANGEMAP);

		/* ####FernFerret#### */
		// Added two new items to the admin menu, the soundmenu hide (toggle) and the all sounds menu
		AddToTopMenu(hAdminMenu, "sm_all_sounds", TopMenuObject_Item, Play_All_Sound, server_commands, "sm_all_sounds", ADMFLAG_GENERIC);
		AddToTopMenu(hAdminMenu, "sm_sound_showmenu", TopMenuObject_Item, Set_Sound_Menu, server_commands, "sm_sound_showmenu", ADMFLAG_CHANGEMAP);
		/* ################## */
	}
}

public Play_Admin_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
						param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Play Admin Sound");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,admin_sounds);
}

public Play_Karaoke_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
						  param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Karaoke");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,karaoke_sounds);
}

/* ####FernFerret#### */
// Start FernFerret's Action Sounds Code
// This function sets parameters for showing the All Sounds item in the menu
public Play_All_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Play a Sound");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,all_sounds);
}

// Creates the SoundMenu show/hide item in the admin menu, it is a toggle
public Set_Sound_Menu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(GetConVarInt(cvarshowsoundmenu) == 1)
	{
		if (action == TopMenuAction_DisplayOption)
			Format(buffer, maxlength, "Hide Sound Menu");
		else if (action == TopMenuAction_SelectOption)
			SetConVarInt(cvarshowsoundmenu, 0);
	}
	else
	{
		if (action == TopMenuAction_DisplayOption)
			Format(buffer, maxlength, "Show Sound Menu");
		else if (action == TopMenuAction_SelectOption)
			SetConVarInt(cvarshowsoundmenu, 1);
	}
}

public Sound_Menu(client, sound_types:types)
{
	if (types >= admin_sounds)
	{
		new AdminId:aid = GetUserAdmin(client);
		new bool:isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if (!isadmin)
		{
			//PrintToChat(client,"[Say Sounds] You must be an admin view this menu!");
			PrintToChat(client,"\x04[Say Sounds] \x01%t", "AdminMenu");
			return;
		}
	}

	new Handle:soundmenu=CreateMenu(Menu_Select);
	SetMenuExitButton(soundmenu,true);
	SetMenuTitle(soundmenu,"Choose a sound to play.");

	decl String:title[PLATFORM_MAX_PATH+1];
	decl String:buffer[PLATFORM_MAX_PATH+1];
	decl String:karaokefile[PLATFORM_MAX_PATH+1];

	KvRewind(listfile);
	if (KvGotoFirstSubKey(listfile))
	{
		do
		{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (!StrEqual(buffer, "JoinSound") &&
				!StrEqual(buffer, "ExitSound") &&
				strncmp(buffer,"STEAM_",6,false))
			{
				if (!KvGetNum(listfile, "actiononly", 0) &&
					KvGetNum(listfile, "enable", 1))
				{
					new bool:admin = bool:KvGetNum(listfile, "admin",0);
					new bool:adult = bool:KvGetNum(listfile, "adult",0);
					if (!admin || types >= admin_sounds)
					{
						title[0] = '\0';
						KvGetString(listfile, "title", title, sizeof(title));
						if (!title[0])
							strcopy(title, sizeof(title), buffer);

						karaokefile[0] = '\0';
						KvGetString(listfile, "karaoke", karaokefile, sizeof(karaokefile));
						new bool:karaoke = (karaokefile[0] != '\0');
						if (!karaoke || types >= karaoke_sounds)
						{
							switch (types)
							{
								case karaoke_sounds:
								{
									if (!karaoke)
										continue;
								}
								case admin_sounds:
								{
									if (!admin)
										continue;
								}
								case all_sounds:
								{
									if (karaoke)
										StrCat(title, sizeof(title), " [Karaoke]");

									if (admin)
										StrCat(title, sizeof(title), " [Admin]");
								}
							}
							if(!adult)
							{
								AddMenuItem(soundmenu,buffer,title);
							}
						}
					}
				}
			}
		} while (KvGotoNextKey(listfile));
	}
	else
	{
		SetFailState("No subkeys found in the config file!");
	}

	DisplayMenu(soundmenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		decl String:SelectionInfo[PLATFORM_MAX_PATH+1];
		if (GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo)))
		{
			KvRewind(listfile);
			KvGotoFirstSubKey(listfile);
			decl String:buffer[PLATFORM_MAX_PATH];
			do
			{
				KvGetSectionName(listfile, buffer, sizeof(buffer));
				if (strcmp(SelectionInfo,buffer,false) == 0)
				{
					Submit_Sound(client,buffer);
					break;
				}
			} while (KvGotoNextKey(listfile));
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

//*****************************************************************
//	------------------------------------------------------------- *
//				*** Client Preferences Menu ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public SaysoundClientPref(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		ShowClientPrefMenu(client);
	}
}

public MenuHandlerClientPref(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		if (param2 == 0)
		{
			// Saysounds
			if(!checkClientCookies(param1, CHK_SAYSOUNDS))
				SetClientCookie(param1, g_sssaysound_cookie, "1");
			else
				SetClientCookie(param1, g_sssaysound_cookie, "0");
		}
		else if (param2 == 1)
		{
			// Action Sounds
			if(!checkClientCookies(param1, CHK_EVENTS))
			{
				SetClientCookie(param1, g_ssevents_cookie, "1");
			}
			else
			{
				SetClientCookie(param1, g_ssevents_cookie, "0");
			}	
		}
		else if (param2 == 2)
		{
			// Karaoke
			if(!checkClientCookies(param1, CHK_KARAOKE))
				SetClientCookie(param1, g_sskaraoke_cookie, "1");
			else
				SetClientCookie(param1, g_sskaraoke_cookie, "0");
		}
		else if (param2 == 3)
		{
			// Chat Message
			if(!checkClientCookies(param1, CHK_CHATMSG))
				SetClientCookie(param1, g_sschatmsg_cookie, "1");
			else
				SetClientCookie(param1, g_sschatmsg_cookie, "0");
		}
		ShowClientPrefMenu(param1);
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowClientPrefMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandlerClientPref);
	decl String:buffer[100];

	Format(buffer, sizeof(buffer), "%T", "SaysoundsMenu", client);
	SetMenuTitle(menu, buffer);

	// Saysounds
	if(!checkClientCookies(client, CHK_SAYSOUNDS))
		Format(buffer, sizeof(buffer), "%T", "EnableSaysound", client);
	else
		Format(buffer, sizeof(buffer), "%T", "DisableSaysound", client);

	AddMenuItem(menu, "SaysoundPref", buffer);

	// Action Sounds
	if(!checkClientCookies(client, CHK_EVENTS))
		Format(buffer, sizeof(buffer), "%T", "EnableEvents", client);
	else
		Format(buffer, sizeof(buffer), "%T", "DisableEvents", client);

	AddMenuItem(menu, "EventPref", buffer);

	// Karaoke
	if(!checkClientCookies(client, CHK_KARAOKE))
		Format(buffer, sizeof(buffer), "%T", "EnableKaraoke", client);
	else
		Format(buffer, sizeof(buffer), "%T", "DisableKaraoke", client);

	AddMenuItem(menu, "KaraokePref", buffer);

	// Chat Messages
	if(!checkClientCookies(client, CHK_CHATMSG))
		Format(buffer, sizeof(buffer), "%T", "EnableChat", client);
	else
		Format(buffer, sizeof(buffer), "%T", "DisableChat", client);

	AddMenuItem(menu, "ChatPref", buffer);

	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 0);
}