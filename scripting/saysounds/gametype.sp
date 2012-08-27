//*****************************************************************
//	------------------------------------------------------------- *
//					*** Get the game/mod type ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
#tryinclude <gametype>
#if !defined _gametype_included
	enum Game { undetected, tf2, cstrike, csgo, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
	stock Game:GameType = undetected;

	stock Game:GetGameType()
	{
		if (GameType == undetected)
		{
			new String:modname[30];
			GetGameFolderName(modname, sizeof(modname));
			if (StrEqual(modname,"cstrike",false))
				GameType=cstrike;
			else if (StrEqual(modname,"csgo",false)) 
				GameType=csgo;
			else if (StrEqual(modname,"tf",false)) 
				GameType=tf2;
			else if (StrEqual(modname,"dod",false)) 
				GameType=dod;
			else if (StrEqual(modname,"hl2mp",false)) 
				GameType=hl2mp;
			else if (StrEqual(modname,"Insurgency",false)) 
				GameType=insurgency;
			else if (StrEqual(modname,"left4dead", false)) 
				GameType=l4d;
			else if (StrEqual(modname,"left4dead2", false)) 
				GameType=l4d2;
			else if (StrEqual(modname,"zps",false)) 
				GameType=zps;
			else
				GameType=other_game;
		}
		return GameType;
	}
#endif