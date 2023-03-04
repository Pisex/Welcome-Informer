#include <sourcemod>
#include <csgo_colors>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <lvl_ranks>
#include <shop>
#include <FirePlayersStats>
#include <vip_core>
#undef REQUIRE_EXTENSIONS
#include <geoip>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Welcome Informer", 
	author = "Pisex", 
	description = "Позволяет выводить в чат информацию о игроку", 
	version = "1.6.0", 
	url = "Discord => Pisex#0023"
};

stock const char g_sLogFile[] = "addons/sourcemod/logs/welcome_informer.log";

char g_sShitBuffer[256],
	g_sPlayerRank[MAXPLAYERS+1][64], 
	g_sMsg[2048],
	g_sImmunityFlags[64],
	g_sVipGroups[256];

int ClientMessage[MAXPLAYERS+1],
g_iTopPosition[MAXPLAYERS+1],
g_iTypePoint,
g_iHelloMessage,
g_iHelloCountry,
g_iHelloCity,
g_iHelloRank,
g_iHelloTop,
g_iHelloExp,
g_iHelloAdmin,
g_iHelloVIP,
g_iHelloCredits,
g_iHelloLog,
g_iExitMessage,
g_iExitCountry,
g_iExitCity,
g_iExitRank,
g_iExitTop,
g_iExitExp,
g_iExitAdmin,
g_iExitVIP,
g_iExitCredits,
g_iExitCreditsSession,
g_iExitPointsSession,
g_iExitLog,
g_iShowMsg[MAXPLAYERS+1];

Handle CookieCredits;

public void OnPluginStart()
{
	LoadTranslations("welcome_informer.phrases");
	
	char buffer[PLATFORM_MAX_PATH];
    KeyValues KV = CreateKeyValues("Welcome");
    BuildPath(Path_SM, buffer, sizeof buffer, "configs/welcome_info.ini");
    if(!KV.ImportFromFile(buffer))
			SetFailState("Welcome Info - Файл конфигураций не найден");
    FileToKeyValues(KV, buffer);
    KvRewind(KV);
	g_iTypePoint				=KvGetNum(KV,"PointType");

    g_iHelloMessage 			= KvGetNum(KV,"HelloMsg");
    g_iHelloCity 				= KvGetNum(KV,"HelloCity");
    g_iHelloCountry 			= KvGetNum(KV,"HelloCountry");
    g_iHelloRank 				= KvGetNum(KV,"HelloRank");
    g_iHelloTop 				= KvGetNum(KV,"HelloTop");
    g_iHelloExp 				= KvGetNum(KV,"HelloExp");
    g_iHelloAdmin 				= KvGetNum(KV,"HelloAdmin");
    g_iHelloVIP 				= KvGetNum(KV,"HelloVIP");
    g_iHelloCredits 			= KvGetNum(KV,"HelloCredits");
    g_iHelloLog 				= KvGetNum(KV,"HelloLog");

    g_iExitMessage 				= KvGetNum(KV,"ExitMsg");
    g_iExitCity 				= KvGetNum(KV,"ExitCity");
    g_iExitCountry 				= KvGetNum(KV,"ExitCountry");
    g_iExitRank 				= KvGetNum(KV,"ExitRank");
    g_iExitTop 					= KvGetNum(KV,"ExitTop");
    g_iExitExp 					= KvGetNum(KV,"ExitExp");
    g_iExitAdmin 				= KvGetNum(KV,"ExitAdmin");
    g_iExitVIP					= KvGetNum(KV,"ExitVIP");
    g_iExitCredits 				= KvGetNum(KV,"ExitCredits");
    g_iExitCreditsSession 		= KvGetNum(KV,"ExitCreditsSession");
    g_iExitPointsSession 		= KvGetNum(KV,"ExitPointSession");
    g_iExitLog					= KvGetNum(KV,"ExitLog");

	KvGetString(KV,"Admin_Immunity",g_sImmunityFlags,sizeof g_sImmunityFlags);
	KvGetString(KV,"VIP_GroupImmunity",g_sVipGroups,sizeof g_sVipGroups);
	
	HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
	
	CookieCredits = RegClientCookie("Credits", "Кредиты при входе в игру", CookieAccess_Private);

	if (!g_iTypePoint && (g_iHelloRank || g_iExitRank)) LoadTranslations("lr_core_ranks.phrases");
	else if(g_iTypePoint && (g_iHelloRank || g_iExitRank)) LoadTranslations("FirePlayersStatsRanks.phrases");
}

public void OnClientPostAdminCheck(int iClient)
{
	if(ClientMessage[iClient] == 0)CreateTimer(1.0,ontimer,iClient,TIMER_FLAG_NO_MAPCHANGE);
}

public Action ontimer(Handle timer, int iClient)
{
	if (IsClientInGame(iClient) && !IsFakeClient(iClient) && g_iHelloMessage)
	{
		char sIP[16];
		GetClientIP(iClient, sIP, sizeof sIP);
		
		Format(g_sMsg, sizeof g_sMsg, "%t", "hello", iClient);
		
		if(g_iHelloLog)
		{
			char SteamId64[32],
				City[32],
				Country[32];
			GeoipCountry(sIP, Country, sizeof(Country), "ru");
			GeoipCity(sIP, City, sizeof(City), "ru");
			GetClientAuthId(iClient, AuthId_Steam2, SteamId64, sizeof SteamId64);
			LogToFile(g_sLogFile, "Игрок %L зашёл на сервер.IP: %s. Местоположение: %s,%s.(STEAMID64: %s)", iClient,sIP,Country,City,SteamId64);
		}
		if(g_iHelloCountry || g_iHelloCity)
		{
			Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "geo_text");
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iHelloCountry && GetGeoipCountry(sIP))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iHelloCity && GetGeoipCity(sIP))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iHelloRank && GetPoint_RankName(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if(!g_iTypePoint)
		{
			if (g_iHelloExp)
			{
				if(g_iHelloRank)
				{
					if(g_iHelloTop) Format(g_sShitBuffer, sizeof(g_sShitBuffer), " {DEFAULT}({GREEN}%t", "rank_xp", LR_GetClientInfo(iClient, ST_EXP));
					else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT}({GREEN}%t{DEFAULT})\n", "rank_xp", LR_GetClientInfo(iClient, ST_EXP));
				}
				else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{RED}- %t\n", "rank_xp", LR_GetClientInfo(iClient, ST_EXP));
				StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			}
			if (g_iHelloTop)
			{
				if(g_iHelloRank)
				{
					if(g_iHelloTop) Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT},{GREEN}%t{DEFAULT})\n", "rank_top", LR_GetClientInfo(iClient, ST_PLACEINTOP));
					else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT}({GREEN}%t{DEFAULT})\n", "rank_top", LR_GetClientInfo(iClient, ST_PLACEINTOP));
				}
				else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{RED}- %t\n", "rank_top", LR_GetClientInfo(iClient, ST_PLACEINTOP));
				StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			}
		}
		else
		{
			if (g_iHelloExp)
			{
				if(g_iHelloRank)
				{
					if(g_iHelloTop) Format(g_sShitBuffer, sizeof(g_sShitBuffer), " {DEFAULT}({GREEN}%t", "rank_xp", RoundToCeil(FPS_GetPoints(iClient)));
					else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT}({GREEN}%t{DEFAULT})\n", "rank_xp", RoundToCeil(FPS_GetPoints(iClient)));
				}
				else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{RED}- %t\n", "rank_xp", RoundToCeil(FPS_GetPoints(iClient)));
				StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			}
			if (g_iHelloTop)
			{
				if(g_iHelloRank)
				{
					if(g_iHelloTop) Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT},{GREEN}%t{DEFAULT})\n", "rank_top", g_iTopPosition[iClient]);
					else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT}({GREEN}%t{DEFAULT})\n", "rank_top", g_iTopPosition[iClient]);
				}
				else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{RED}- %t\n", "rank_top", g_iTopPosition[iClient]);
				StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			}
		}
		if(g_iHelloCredits && GetCredits(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			SetClientIntCookie(iClient, CookieCredits, Shop_GetClientCredits(iClient));
		}
		if(g_iHelloVIP && GetVip(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if(g_iHelloAdmin && GetAdmin(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if(!g_iShowMsg[iClient]) CGOPrintToChatAll(g_sMsg);
		ClientMessage[iClient] = 1;
	}
}

public void Event_Disconnect(Event event, const char[] sName, bool dontBroadcast)
{
	char
	sIP[16];
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < iClient < MAXPLAYERS && IsClientInGame(iClient) && !IsFakeClient(iClient) && g_iExitMessage)
	{
		GetClientIP(iClient, sIP, sizeof sIP);
		
		Format(g_sMsg, sizeof g_sMsg, "%t", "exit", iClient);
		
		
		if(g_iExitLog)
		{
			char SteamId64[32],
				City[32],
				Country[32];
			GeoipCountry(sIP, Country, sizeof(Country), "ru");
			GeoipCity(sIP, City, sizeof(City), "ru");
			GetClientAuthId(iClient, AuthId_SteamID64, SteamId64, sizeof SteamId64);
			LogToFile(g_sLogFile, "Игрок %L Вышел с сервера.IP: %s. Местоположение: %s,%s.(STEAMID64: %s)", iClient,sIP,Country,City,SteamId64);
		}
		
		if (g_iExitPointsSession && GetPoint_Session(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		
		if(g_iExitCountry || g_iExitCity)
		{
			Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "geo_text");
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		
		if (g_iExitCountry && GetGeoipCountry(sIP))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iExitCity && GetGeoipCity(sIP))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iExitRank && GetPoint_RankName(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if(!g_iTypePoint)
		{
			if (g_iExitExp)
			{
				if(g_iExitRank)
				{
					if(g_iExitExp) Format(g_sShitBuffer, sizeof(g_sShitBuffer), " {DEFAULT}({GREEN}%t", "rank_xp", LR_GetClientInfo(iClient, ST_EXP));
					else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT}({GREEN}%t{DEFAULT})\n", "rank_xp", LR_GetClientInfo(iClient, ST_EXP));
				}
				else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{RED}- %t\n", "rank_xp", LR_GetClientInfo(iClient, ST_EXP));
				StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			}
			if (g_iExitTop)
			{
				if(g_iExitRank)
				{
					if(g_iExitTop) Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT},{GREEN}%t{DEFAULT})\n", "rank_top", LR_GetClientInfo(iClient, ST_PLACEINTOP));
					else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{DEFAULT}({GREEN}%t{DEFAULT})\n", "rank_top", LR_GetClientInfo(iClient, ST_PLACEINTOP));
				}
				else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "{RED}- %t\n", "rank_top", LR_GetClientInfo(iClient, ST_PLACEINTOP));
				StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
			}
		}
		else
		{

		}
		if (g_iExitCredits && GetCredits(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iExitCreditsSession && GetCreditsSession(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iExitAdmin && GetAdmin(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if (g_iExitVIP && GetVip(iClient))
		{
			StrCat(g_sMsg, sizeof g_sMsg, g_sShitBuffer);
		}
		if(!g_iShowMsg[iClient]) CGOPrintToChatAll(g_sMsg);
		ClientMessage[iClient] = 0;
	}
}

bool GetGeoipCity(char[] ip)
{
	GeoipCity(ip, g_sShitBuffer, sizeof(g_sShitBuffer), "ru");
	if(g_iHelloCountry) Format(g_sShitBuffer, sizeof(g_sShitBuffer), ", %t\n", "geo_city", g_sShitBuffer);
	else if(g_iExitCountry) Format(g_sShitBuffer, sizeof(g_sShitBuffer), ", %t\n", "geo_city", g_sShitBuffer);
	else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t\n", "geo_city", g_sShitBuffer);
	return true;
}

bool GetGeoipCountry(char[] ip)
{
	GeoipCountry(ip, g_sShitBuffer, sizeof(g_sShitBuffer), "ru");
	if(g_iHelloCity) Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "geo_country", g_sShitBuffer);		
	else if(g_iExitCity) Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "geo_country", g_sShitBuffer);
	else Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t\n", "geo_country", g_sShitBuffer);
	return true;
}

bool GetPoint_RankName(int iClient)
{
	if(!g_iTypePoint)
	{
		int ranknum = LR_GetClientInfo(iClient, ST_RANK);
		if (ranknum > 0)--ranknum;
		LR_GetRankNames().GetString(ranknum, g_sShitBuffer, sizeof(g_sShitBuffer));
		Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "rank", g_sShitBuffer);
	}
	else
	{
		FPS_GetRanks(iClient, g_sPlayerRank[iClient], sizeof(g_sPlayerRank[]));
		Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "rank", FindTranslationRank(iClient, g_sPlayerRank[iClient]));
	}
	return true;
}

bool GetCredits(int iClient)
{
	Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "credits", Shop_GetClientCredits(iClient));
	return true;
}

bool GetCreditsSession(int iClient)
{
	int credits;
	char CreditsSession[12];
	GetClientCookie(iClient, CookieCredits,CreditsSession,sizeof CreditsSession);
	credits = Shop_GetClientCredits(iClient) - StringToInt(CreditsSession);
	
	Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "credits_session", credits);
	return true;
}

bool GetAdmin(int iClient)
{
	if(!(GetUserFlagBits(iClient) & (ReadFlagString(g_sImmunityFlags))))
	{
		Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%s", GetUserAdmin(iClient) != INVALID_ADMIN_ID ? "{RED}- {DEFAULT}Админ права: {GREEN}Присутствуют \n":"");
		return true;
	}
	else
	{
		g_iShowMsg[iClient] = 1;
		return false;
	}
}

bool GetPoint_Session(int iClient)
{
	if(!g_iTypePoint)
		Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "rank_session", LR_GetClientInfo(iClient, ST_EXP, true));
	else
		Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "rank_session", RoundToCeil(FPS_GetPoints(iClient,true)));

	return true;
}

bool GetVip(int iClient)
{
	char sBufs[8][32];
	ExplodeString(g_sVipGroups, ";", sBufs, 8, 32);
	if((VIP_GetClientVIPGroup(iClient, g_sShitBuffer, sizeof(g_sShitBuffer)) == true))
	{
		if(!strcmp(g_sShitBuffer,sBufs[0]) || !strcmp(g_sShitBuffer,sBufs[1]) || !strcmp(g_sShitBuffer,sBufs[2]) || !strcmp(g_sShitBuffer,sBufs[3]) || !strcmp(g_sShitBuffer,sBufs[4]) || !strcmp(g_sShitBuffer,sBufs[5]) || !strcmp(g_sShitBuffer,sBufs[6]) || !strcmp(g_sShitBuffer,sBufs[7]))
		{
			g_iShowMsg[iClient] = 1;
			return false;
		}
		else
		{
			Format(g_sShitBuffer, sizeof(g_sShitBuffer), "%t", "vip", g_sShitBuffer);
			return true;
		}
	}
	return false;
} 

stock int GetClientIntCookie(int iClient, Handle hCookie) {
    char szBuffer[13];
    GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));
    return StringToInt(szBuffer);
}

stock void SetClientIntCookie(int iClient, Handle hCookie, int iValue) {
    char szBuffer[13];
    IntToString(iValue, szBuffer, sizeof(szBuffer));
    SetClientCookie(iClient, hCookie, szBuffer);
}

public void FPS_OnPlayerPosition(int iClient, int iPosition, int iPlayersCount)
{
	g_iTopPosition[iClient] = iPosition;
}