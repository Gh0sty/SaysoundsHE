//*****************************************************************
//	------------------------------------------------------------- *
//				*** Manage precaching resources ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
	#define DONT_DOWNLOAD	0
	#define DOWNLOAD		1
	#define ALWAYS_DOWNLOAD 2

	enum State { Unknown=0, Defined, Download, Force, Precached };

	new Handle:cvarDownloadThreshold	= INVALID_HANDLE;
	new Handle:cvarSoundThreshold		= INVALID_HANDLE;
	new Handle:cvarSoundLimitMap		= INVALID_HANDLE;

	new g_iSoundCount			= 0;
	new g_iDownloadCount		= 0;
	new g_iRequiredCount		= 0;
	new g_iPrevDownloadIndex	= 0;
	new g_iDownloadThreshold	= -1;
	new g_iSoundThreshold		= -1;
	new g_iSoundLimit			= -1;

	// Trie to hold precache status of sounds
	new Handle:g_soundTrie = INVALID_HANDLE;

	stock bool:FakePrecacheSound(const String:szPath[])
	{
		decl String:buffer[PLATFORM_MAX_PATH+1];
		Format(buffer, sizeof(buffer), "*%s", szPath);
		AddToStringTable(FindStringTable("soundprecache"), szPath);
	}
	
	stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=false)
	{
		new State:value = Unknown;
		if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
		{
			if (force || value >= Force || g_iSoundLimit <= 0 ||
				(g_soundTrie ? GetTrieSize(g_soundTrie) : 0) < g_iSoundLimit)
			{
				(gb_csgo ? FakePrecacheSound(sound) : PrecacheSound(sound, preload))
				SetTrieValue(g_soundTrie, sound, Precached);
			}
			else
				return false;
		}
		return true;
	}

	stock SetupSound(const String:sound[], bool:force=false, download=DOWNLOAD,
					 bool:precache=false, bool:preload=false)
	{
		new State:value = Unknown;
		new bool:update = !GetTrieValue(g_soundTrie, sound, value);
		if (update || value < Defined)
		{
			g_iSoundCount++;
			value  = Defined;
			update = true;
		}

		if (value < Download && download && g_iDownloadThreshold != 0)
		{
			decl String:file[PLATFORM_MAX_PATH+1];
			Format(file, sizeof(file), "sound/%s", sound);

			if (FileExists(file))
			{
				if (download < 0)
				{
					if (!strncmp(file, "ambient", 7) ||
						!strncmp(file, "beams", 5) ||
						!strncmp(file, "buttons", 7) ||
						!strncmp(file, "coach", 5) ||
						!strncmp(file, "combined", 8) ||
						!strncmp(file, "commentary", 10) ||
						!strncmp(file, "common", 6) ||
						!strncmp(file, "doors", 5) ||
						!strncmp(file, "friends", 7) ||
						!strncmp(file, "hl1", 3) ||
						!strncmp(file, "items", 5) ||
						!strncmp(file, "midi", 4) ||
						!strncmp(file, "misc", 4) ||
						!strncmp(file, "music", 5) ||
						!strncmp(file, "npc", 3) ||
						!strncmp(file, "physics", 7) ||
						!strncmp(file, "pl_hoodoo", 9) ||
						!strncmp(file, "plats", 5) ||
						!strncmp(file, "player", 6) ||
						!strncmp(file, "resource", 8) ||
						!strncmp(file, "replay", 6) ||
						!strncmp(file, "test", 4) ||
						!strncmp(file, "ui", 2) ||
						!strncmp(file, "vehicles", 8) ||
						!strncmp(file, "vo", 2) ||
						!strncmp(file, "weapons", 7))
					{
						// If the sound starts with one of those directories
						// assume it came with the game and doesn't need to
						// be downloaded.
						download = 0;
					}
					else
						download = 1;
				}

				if (download > 0 &&
					(download > 1 || g_iDownloadThreshold < 0 ||
					 (g_iSoundCount > g_iPrevDownloadIndex &&
					  g_iDownloadCount < g_iDownloadThreshold + g_iRequiredCount)))
				{
					AddFileToDownloadsTable(file);

					update = true;
					value  = Download;
					g_iDownloadCount++;

					if (download > 1)
						g_iRequiredCount++;

					if (download <= 1 || g_iSoundCount == g_iPrevDownloadIndex + 1)
						g_iPrevDownloadIndex = g_iSoundCount;
				}
			}
		}

		if (value < Precached && (precache || (g_iSoundThreshold > 0 &&
											   g_iSoundCount < g_iSoundThreshold)))
		{
			if (force || g_iSoundLimit <= 0 &&
				(g_soundTrie ? GetTrieSize(g_soundTrie) : 0) < g_iSoundLimit)
			{
				(gb_csgo ? FakePrecacheSound(sound) : PrecacheSound(sound, preload))

				if (value < Precached)
				{
					value  = Precached;
					update = true;
				}
			}
		}
		else if (force && value < Force)
		{
			value  = Force;
			update = true;
		}

		if (update)
			SetTrieValue(g_soundTrie, sound, value);
	}

	stock PrepareAndEmitSound(const clients[],
					 numClients,
					 const String:sample[],
					 entity = SOUND_FROM_PLAYER,
					 channel = SNDCHAN_AUTO,
					 level = SNDLEVEL_NORMAL,
					 flags = SND_NOFLAGS,
					 Float:volume = SNDVOL_NORMAL,
					 pitch = SNDPITCH_NORMAL,
					 speakerentity = -1,
					 const Float:origin[3] = NULL_VECTOR,
					 const Float:dir[3] = NULL_VECTOR,
					 bool:updatePos = true,
					 Float:soundtime = 0.0)
	{
		if (PrepareSound(sample))
		{
			EmitSound(clients, numClients, sample, entity, channel,
						level, flags, volume, pitch, speakerentity,
						origin, dir, updatePos, soundtime);
			}
		}
	}

	stock PrepareAndEmitSoundToClient(client,
					 const String:sample[],
					 entity = SOUND_FROM_PLAYER,
					 channel = SNDCHAN_AUTO,
					 level = SNDLEVEL_NORMAL,
					 flags = SND_NOFLAGS,
					 Float:volume = SNDVOL_NORMAL,
					 pitch = SNDPITCH_NORMAL,
					 speakerentity = -1,
					 const Float:origin[3] = NULL_VECTOR,
					 const Float:dir[3] = NULL_VECTOR,
					 bool:updatePos = true,
					 Float:soundtime = 0.0)
	{
		if (PrepareSound(sample))
		{
			EmitSoundToClient(client, sample, entity, channel,
								  level, flags, volume, pitch, speakerentity,
								  origin, dir, updatePos, soundtime);
		}
	}
#endif
