//*****************************************************************
//	------------------------------------------------------------- *
//						*** Checking stuff ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
bool:HasClientFlags (const String:flags[], client)
{
	new len = strlen(flags);
	
	if (len == 0)
		return false;
	
	new AdminFlag:flag;
	
	for (new i = 0; i < len; i++)
	{
		if (!FindFlagByChar(flags[i], flag))
		{
			LogError("Ivalid flag detected: %c", flags[i]);
		}
		else if ((GetUserFlagBits(client) & FlagToBit(flag)))// || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			return true;
	}
	return false;
}

public IsValidClient (client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client) || IsClientReplay(client) || IsClientSourceTV(client))
		return false;

	return IsClientInGame(client);
}

public IsDeadClient (client)
{
	if (IsValidClient(client) && !IsPlayerAlive(client))
		return true;

	return false;
}

public HearSound (client)
{	
	if (IsPlayerAlive(client) && !hearalive)
		return false;
	else
		return true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}

bool:checkSamplingRate(const String:filelocation[])
{
	new Handle:h_Soundfile = OpenSoundFile(filelocation,true);
	new samplerate;
	if (h_Soundfile != INVALID_HANDLE)
		samplerate = GetSoundSamplingRate(h_Soundfile);
	else
	{
		LogError("<checkSamplingRate> INVALID_HANDLE for file \"%s\" ", filelocation);
		CloseHandle(h_Soundfile);
		return false;
	}
	CloseHandle(h_Soundfile);

	if (samplerate > 44100)
	{
		LogError("Invalid sample rate (\%d Hz) for file \"%s\", sample rate should not be above 44100 Hz", samplerate, filelocation);
		return false;
	}
	return true;
}
//*****************************************************************
//	------------------------------------------------------------- *
//				*** Checking Client Preferences ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
bool:checkClientCookies(iClient, iCase)
{
	new String:cookie[4];

	switch (iCase)
	{
		case CHK_CHATMSG:	/* Chat message */
		{
			GetClientCookie(iClient, g_sschatmsg_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1"))
				return true;
			else if(StrEqual(cookie, "0"))
				return false;
			else
			{
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_sschatmsg_cookie, "1");
				return true;
			}
		}
		case CHK_SAYSOUNDS:	/* Say sounds */
		{
			GetClientCookie(iClient, g_sssaysound_cookie, cookie, sizeof(cookie));
			// Switching form on/off, yes/no to 1/0 but for the old cookies we'll have to check both
			if (StrEqual(cookie, "on") || StrEqual(cookie, "1"))
				return true;
			else if(StrEqual(cookie, "off") || StrEqual(cookie, "0"))
				return false;
			else
			{
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_sssaysound_cookie, "1");
				return true;
			}
		}
		case CHK_EVENTS:	/* Event Sounds */
		{
			GetClientCookie(iClient, g_ssevents_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1"))
				return true;
			else if(StrEqual(cookie, "0"))
				return false;
			else
			{
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_ssevents_cookie, "1");
				return true;
			}
		}
		case CHK_KARAOKE:	/* Karaoke */
		{
			GetClientCookie(iClient, g_sskaraoke_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1"))
				return true;
			else if(StrEqual(cookie, "0"))
				return false;
			else
			{
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_sskaraoke_cookie, "1");
				return true;
			}
		}
		case CHK_BANNED:	/* Banned */
		{
			GetClientCookie(iClient, g_ssban_cookie, cookie, sizeof(cookie));
			// Switching form on/off, yes/no to 1/0 but for the old cookies we'll have to check both
			if (StrEqual(cookie, "on") || StrEqual(cookie, "1"))
				return true;
			else if(StrEqual(cookie, "off") || StrEqual(cookie, "0"))
				return false;
			else
			{
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_ssban_cookie, "0");
				return false;
			}
		}
		case CHK_GREETED:	/* Greeted */
		{
			GetClientCookie(iClient, g_ssgreeted_cookie, cookie, sizeof(cookie));
			// Switching form on/off, yes/no to 1/0 but for the old cookies we'll have to check both
			if (StrEqual(cookie, "yes") || StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "no") || StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_ssgreeted_cookie, "0");
				return false;
			}
		}
		default:
		{
			return true;
		}
	}
	return true;
}