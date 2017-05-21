#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iHGLevel,
		g_iHGHealth,
		g_iHGButton[MAXPLAYERS+1];
Handle	g_hHealthGiver = null;

public Plugin myinfo = {name = "[LR] Module - Health Giver", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Health Giver] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Health Giver] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("player_spawn", PlayerSpawn);
	g_hHealthGiver = RegClientCookie("LR_HealthGiver", "LR_HealthGiver", CookieAccess_Private);
	LoadTranslations("levels_ranks_healthgiver.phrases");
	
	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/healthgiver.ini");
	KeyValues hLR_HG = new KeyValues("LR_HealthGiver");

	if(!hLR_HG.ImportFromFile(sPath) || !hLR_HG.GotoFirstSubKey())
	{
		SetFailState("[%s Health Giver] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_HG.Rewind();

	if(hLR_HG.JumpToKey("Settings"))
	{
		g_iHGLevel = hLR_HG.GetNum("rank", 0);
		g_iHGHealth = hLR_HG.GetNum("value", 125);
	}
	else SetFailState("[%s Health Giver] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_HG;
}

public void PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{	
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(iClient) && !g_iHGButton[iClient] && (LR_GetClientRank(iClient) >= g_iHGLevel))
	{
		SetEntProp(iClient, Prop_Send, "m_iHealth", g_iHGHealth);
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == g_iHGLevel)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);

		if(LR_GetClientRank(iClient) >= g_iHGLevel)
		{
			switch(g_iHGButton[iClient])
			{
				case 0: FormatEx(sText, sizeof(sText), "%t", "HG_On", g_iHGHealth);
				case 1: FormatEx(sText, sizeof(sText), "%t", "HG_Off", g_iHGHealth);
			}

			hMenu.AddItem("HealthGiver", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%t", "HG_RankClosed", g_iHGHealth, g_iHGLevel);
			hMenu.AddItem("HealthGiver", sText, ITEMDRAW_DISABLED);
		}
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == g_iHGLevel)
	{
		if(strcmp(sInfo, "HealthGiver") == 0)
		{
			switch(g_iHGButton[iClient])
			{
				case 0: g_iHGButton[iClient] = 1;
				case 1: g_iHGButton[iClient] = 0;
			}
			
			LR_MenuInventory(iClient);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sCookie[8];
	GetClientCookie(iClient, g_hHealthGiver, sCookie, sizeof(sCookie));
	g_iHGButton[iClient] = StringToInt(sCookie);
} 

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sBuffer[8];
		FormatEx(sBuffer, sizeof(sBuffer), "%i", g_iHGButton[iClient]);
		SetClientCookie(iClient, g_hHealthGiver, sBuffer);		
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}