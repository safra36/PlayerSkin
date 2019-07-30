#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "5.0.2 (Build 8)"
#define PLUGIN_AUTHOR "noBrain"
#define MAX_SKIN_PATH 256

Database db = null;

bool g_bIsSkinChangeAllowed = true;

Handle g_hTimerRoundChecker = null;

ConVar g_epskin = null;
ConVar g_gHaveCategories = null;
ConVar g_aAutoShowMenu = null;
ConVar g_cHideMenu = null;
ConVar g_cHideTeams = null;
ConVar g_cMapSkins = null;
ConVar g_cRoundStartTimeout = null;
ConVar g_cCTDefaultSkin = null;
ConVar g_cTDefualtSkin = null;
ConVar g_cCTDefaultArms = null;
ConVar g_cTDefualtArms = null;


char defArms[][] = { "models/weapons/ct_arms.mdl", "models/weapons/t_arms.mdl" };
char g_szFileSkinPath[PLATFORM_MAX_PATH], g_szFileAutoSkinPath[PLATFORM_MAX_PATH], g_szFileCategoryPath[PLATFORM_MAX_PATH], g_szFileUserSkinPath[PLATFORM_MAX_PATH], g_szFileMapSkins[PLATFORM_MAX_PATH];



public Plugin myinfo =  {

	name = "PlayerSkin",
	author = PLUGIN_AUTHOR,
	description = "Allow players to select their skins.",
	version = PLUGIN_VERSION,

};

public void OnPluginStart() 
{

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Pre);
	HookEvent("round_start", RoundStart, EventHookMode_Pre);
	
	
	RegConsoleCmd("sm_pskin", Command_PlayerSkin);
	RegConsoleCmd("sm_models", Command_PlayerSkin);
	RegConsoleCmd("sm_skins", Command_PlayerSkin);

	g_epskin = CreateConVar("sm_pskin_enable", "1", "Enable/Disable Command pskin");
	g_gHaveCategories = CreateConVar("sm_cat_enable", "0", "Enable/Disable categories support");
	g_aAutoShowMenu = CreateConVar("sm_start_menu", "0", "If true, will show skin menu to all users.");
	g_cHideMenu = CreateConVar("sm_hide_options", "0", "Hide menu options if the guy does not have access to the skin.");
	g_cHideTeams = CreateConVar("sm_hide_teams", "0", "Hide menu options for opposite team");
	g_cMapSkins = CreateConVar("sm_mapskins_enable", "1", "Enable/Disable per map skin system");
	g_cRoundStartTimeout = CreateConVar("sm_round_timeout", "20.0", "Set this to add a timeout for users to be able to use skins before that time.");
	g_cCTDefaultSkin = CreateConVar("sm_ct_skin", "", "Set a default skin for ct incase you don't want to use admin_skins.ini");
	g_cTDefualtSkin = CreateConVar("sm_t_skin", "", "Set a default skin for t incase you don't want to use admin_skins.ini");
	g_cCTDefaultArms = CreateConVar("sm_ct_arm", "", "Set a default skin for ct incase you don't want to use admin_skins.ini");
	g_cTDefualtArms = CreateConVar("sm_t_arm", "", "Set a default skin for t incase you don't want to use admin_skins.ini");
	
	//Delay loading database.
	
	//Define Created Paths
	BuildPath(Path_SM, g_szFileSkinPath, sizeof(g_szFileSkinPath), "configs/skin.ini");
	BuildPath(Path_SM, g_szFileAutoSkinPath, sizeof(g_szFileAutoSkinPath), "configs/admin_skin.ini");
	BuildPath(Path_SM, g_szFileCategoryPath, sizeof(g_szFileCategoryPath), "configs/categories.ini");
	BuildPath(Path_SM, g_szFileUserSkinPath, sizeof(g_szFileUserSkinPath), "configs/user_skins.ini");
	BuildPath(Path_SM, g_szFileMapSkins, sizeof(g_szFileMapSkins), "configs/mapskins.ini");
	
	//Auto-Create Configurations
	AutoExecConfig(true, "configs.playerskin");
	
	//Load Translations
	LoadTranslations("pskin.phrases.txt");
}

public void OnConfigsExecuted()
{
	PrintToServer("[PlayerSkin] Configs has executed.");
}
public void OnMapStart() 
{
	CreateDatabase();
	PrecacheAllModels();
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	//Check if the handle is null, if yes then kill the timer to avoid interrupts.
	if(g_hTimerRoundChecker != null)
	{
		KillTimer(g_hTimerRoundChecker);
		g_hTimerRoundChecker = null;
	}
	
	if(GetConVarFloat(g_cRoundStartTimeout) != 0.0)
	{
		//Allow users to use skin menu for this period of time.
		if(g_hTimerRoundChecker != null)
		{
			KillTimer(g_hTimerRoundChecker);
			g_hTimerRoundChecker = null;
			g_hTimerRoundChecker = CreateTimer(GetConVarFloat(g_cRoundStartTimeout), Timer_HandleRoundTimeout);
		}
		else
		{
			g_hTimerRoundChecker = CreateTimer(GetConVarFloat(g_cRoundStartTimeout), Timer_HandleRoundTimeout);
		}
		PrintToChatAll(" \x10[PlayerSkin] \x01You can now use skins for %f seconds.", GetConVarFloat(g_cRoundStartTimeout));
	}
	
	g_bIsSkinChangeAllowed = true;
}

public Action Timer_HandleRoundTimeout(Handle timer)
{
	g_bIsSkinChangeAllowed = false;
	PrintToChatAll(" \x10[PlayerSkin] \x01Skins are now disabled.");
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client) || IsFakeClient(client)){
		return;
	}
	if(GetConVarBool(g_aAutoShowMenu))
	{
		if(GetConVarBool(g_gHaveCategories))
		{
			if(IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client))
			{
				DisplaySkinMenu(client, true);
			}
		}
		else if(!GetConVarBool(g_gHaveCategories))
		{
			if(IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client))
			{
				DisplaySkinMenu(client, false);
			}
		}
	}
	if(IsUserWithSkins(client))
	{
		char UserSkin[MAX_SKIN_PATH], UserArms[MAX_SKIN_PATH];
		int i_iTeamNumber = GetClientTeam(client);
		GetUserSkins(client, UserSkin, sizeof(UserSkin), UserArms, sizeof(UserArms), i_iTeamNumber);
		SetModels(client, UserSkin, UserArms);
	}
	else if(ApplyUserSkin(client))
	{
		PrintToConsole(client, "[PlayerSkin] You have gained your skins!");
	}
	else if(GetConVarBool(g_cMapSkins))
	{
		if(ApplyMapSkins(client))
		{
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ApplyMapSkins", client);
		}
		else if(SetAdminSkins(client))
		{
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ApplyDefSkins", client);
		}
		else if(SetConVarSkins(client))
		{
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ApplyDefSkins", client);
		}
		else
		{
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "NoSkinHasBeenSet", client);
		}
	}
	else if(SetAdminSkins(client))
	{
		PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ApplyConVarSkins", client);
	}
	else if(SetConVarSkins(client))
	{
		PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ApplyConVarSkins", client);
	}
	else
	{
		PrintToChat(client, " \x10[PlayerSkin] \x01%T", "NoSkinHasBeenSet", client);
	}
	return;

}

stock bool SetModels(int client, char[] model, char[] arms)
{
	if(!IsModelPrecached(model))
	{
		PrecacheModel(model)
	}
	
	if(!IsModelPrecached(arms))
	{
		PrecacheModel(arms)
	}
	
	if(!StrEqual(model, "", false))
	{
		SetEntityModel(client, model);
		
		if(!IsClientWithArms(client))
		{
			if(!StrEqual(arms, "", false))
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
			}
			else
			{
				int g_iTeam = GetClientTeam(client);
				if(g_iTeam == 2)
				{
					SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
				}
				else if(g_iTeam == 3)
				{
					SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
				}
			}
		}
		else
		{
			PrintToServer("[PlayerSkin] Gloves detected, skipping setting arms ...");
		}
		
		return true;
	}
	else
	{
		return false;
	}
}

stock bool SetConVarSkins(int client)
{
	char i_iSkinCT[256], i_iSkinT[256], i_iArmsT[256], i_iArmsCT[256];

	GetConVarString(g_cCTDefaultSkin, i_iSkinCT, sizeof(i_iSkinCT));
	GetConVarString(g_cTDefualtSkin, i_iSkinT, sizeof(i_iSkinT));
	GetConVarString(g_cTDefualtArms, i_iArmsT, sizeof(i_iArmsT));
	GetConVarString(g_cCTDefaultArms, i_iArmsCT, sizeof(i_iArmsCT));

	int i_iClTeam = GetClientTeam(client);

	if(i_iClTeam == 2)
	{
		if(!StrEqual(i_iSkinT, "", false))
		{
			// Set client's skin based on the cvar
			SetModels(client, i_iSkinT, i_iArmsT);
			return true;
		}
		else
		{
			return false;
		}
	}
	else if(i_iClTeam == 3)
	{

		if(!StrEqual(i_iSkinCT, "", false))
		{
			// Set client's skin based on the cvar
			SetModels(client, i_iSkinCT, i_iArmsCT);
			return true;
		}
		else
		{
			return false;
		}
	}
	return false;
}

stock bool SetAdminSkins(int client)
{
	if(IsUserAdmin(client))
	{
		bool s_gSkinFound = false;
		char SectionName[16];
		Handle kv = CreateKeyValues("Admin_Skins");
		FileToKeyValues(kv, g_szFileAutoSkinPath);
		KvGotoFirstSubKey(kv, true);
		do
		{
			KvGetSectionName(kv, SectionName, sizeof(SectionName));
			
			if(GetUserAcsessValue(SectionName) == GetUserFlagBits(client))
			{
				s_gSkinFound = true;
				break;
			}
		}
		while(s_gSkinFound == false && KvGotoNextKey(kv, true));
		if(s_gSkinFound)
		{
			int ClientTeam = GetClientTeam(client);
			if(ClientTeam == 2)
			{
				char SkinPathT[128], ArmsPathT[128];
				KvGetString(kv, "SkinT", SkinPathT, sizeof(SkinPathT));
				KvGetString(kv, "ArmsT", ArmsPathT, sizeof(ArmsPathT));
				SetModels(client, SkinPathT, ArmsPathT);
				CloseHandle(kv);
				return true;
			}
			else if(ClientTeam == 3)
			{
				char SkinPathCT[128], ArmsPathCT[128];
				KvGetString(kv, "SkinCT", SkinPathCT, sizeof(SkinPathCT));
				KvGetString(kv, "ArmsCT", ArmsPathCT, sizeof(ArmsPathCT));
				SetModels(client, SkinPathCT, ArmsPathCT);
				CloseHandle(kv);
				return true;
			}
		}
		CloseHandle(kv);
		return false;
	}
	else if(!IsUserAdmin(client))
	{
		Handle kv = CreateKeyValues("Admin_Skins");
		FileToKeyValues(kv, g_szFileAutoSkinPath);
		if(KvJumpToKey(kv, "def", false))
		{
			int ClientTeam = GetClientTeam(client);
			if(ClientTeam == 2)
			{
				char SkinPathT[128], ArmsPathT[128];
				KvGetString(kv, "SkinT", SkinPathT, sizeof(SkinPathT));
				KvGetString(kv, "ArmsT", ArmsPathT, sizeof(ArmsPathT));
				SetModels(client, SkinPathT, ArmsPathT);
				CloseHandle(kv);
				return true;
			}
			else if(ClientTeam == 3)
			{
				char SkinPathCT[128], ArmsPathCT[128];
				KvGetString(kv, "SkinCT", SkinPathCT, sizeof(SkinPathCT));
				KvGetString(kv, "ArmsCT", ArmsPathCT, sizeof(ArmsPathCT));
				SetModels(client, SkinPathCT, ArmsPathCT);
				CloseHandle(kv);
				return true;
			}
		}
		CloseHandle(kv);
		return false;
	}
	return false;
}

public Action Command_PlayerSkin(int client, int args) 
{
	if(GetConVarBool(g_epskin))
	{
		if(g_bIsSkinChangeAllowed)
		{
			if(GetConVarBool(g_gHaveCategories))
			{
				DisplaySkinMenu(client, true);
				return Plugin_Handled;
			}
			else if(!GetConVarBool(g_gHaveCategories))
			{
				DisplaySkinMenu(client, false);
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ReachedLimit", client);
			return Plugin_Handled;
		}
		
	}
	else
	{
		PrintToChat(client, " \x10[PlayerSkin] \x01%T", "CommandDisabled", client);
		return Plugin_Continue;
	}
	return Plugin_Continue;

}

stock void DisplaySkinMenu(int client, bool HaveCategories) {

	if(HaveCategories)
	{
		if(GetConVarBool(g_cHideMenu))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenuHandle);
			SetMenuTitle(menu, "Select a Category :");
			Handle kt = CreateKeyValues("Categories");
			FileToKeyValues(kt, g_szFileCategoryPath);
			KvGotoFirstSubKey(kt, false);
			do
			{
				char g_szUserFlags[32];
				KvGetString(kt, "Name", SkinName, sizeof(SkinName));
				KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
				KvGetString(kt, "Flag", g_szUserFlags, sizeof(g_szUserFlags));
				int g_iUserAccessValue = GetUserAcsessValue(g_szUserFlags);
				if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue))
				{
					AddMenuItem(menu, UniqueId, SkinName);
				}
			}
			while(KvGotoNextKey(kt, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kt);
		}
		else if(!GetConVarBool(g_cHideMenu))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenuHandle);
			SetMenuTitle(menu, "Select a Category :");
			Handle kt = CreateKeyValues("Categories");
			FileToKeyValues(kt, g_szFileCategoryPath);
			KvGotoFirstSubKey(kt, false);
			do
			{
				KvGetString(kt, "Name", SkinName, sizeof(SkinName));
				KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
				AddMenuItem(menu, UniqueId, SkinName);
			}
			while(KvGotoNextKey(kt, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kt);
		}
	}
	else if(!HaveCategories)
	{
		if(GetConVarBool(g_cHideMenu) && GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				char g_szUserFlags[32];
				int g_iTeamNum = KvGetNum(kv, "Team", 0);
				KvGetString(kv, "Flag", g_szUserFlags, sizeof(g_szUserFlags));
				int g_iUserAccessValue = GetUserAcsessValue(g_szUserFlags);
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(g_iTeamNum != 0)
				{
					if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue) && GetClientTeam(client) == g_iTeamNum)
					{
						AddMenuItem(menu, UniqueId, SkinName);
					}
				}
				else
				{
					if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue))
					{
						AddMenuItem(menu, UniqueId, SkinName);
					}
				}
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
		else if(GetConVarBool(g_cHideMenu) && !GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				char g_szUserFlags[32];
				KvGetString(kv, "Flag", g_szUserFlags, sizeof(g_szUserFlags));
				int g_iUserAccessValue = GetUserAcsessValue(g_szUserFlags);
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue))
				{
					AddMenuItem(menu, UniqueId, SkinName);
				}
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
		else if(!GetConVarBool(g_cHideMenu) && GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				int g_iTeamNum = KvGetNum(kv, "Team", 0);
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(g_iTeamNum != 0)
				{
					if(GetClientTeam(client) == g_iTeamNum)
					{
						AddMenuItem(menu, UniqueId, SkinName);
					}
				}
				else
				{
					AddMenuItem(menu, UniqueId, SkinName);
				}
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
		else if(!GetConVarBool(g_cHideMenu) && !GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				AddMenuItem(menu, UniqueId, SkinName);
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
	}
}

public int SkinMenuHandle(Handle menu, MenuAction action, int param1, int param2)
{

	char SkinName[32], UniqueId[32], Flag[64], ADMFlag[64];

	switch (action) 
	{
		case MenuAction_Select: 
		{
			Handle kv = CreateKeyValues("Categories");
			FileToKeyValues(kv, g_szFileCategoryPath);
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);
			do
			{
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(StrEqual(item, UniqueId, false))
				{
					KvGetString(kv, "catgroup", ADMFlag, sizeof(ADMFlag));
					Handle smenu = CreateMenu(SkinMenu);
					AddMenuItem(smenu, "def", "Choose Default Skin");
					Handle kt = CreateKeyValues("skins");
					FileToKeyValues(kt, g_szFileSkinPath);
					KvGotoFirstSubKey(kt, false);
					do
					{
						KvGetString(kt, "catgroup", Flag, sizeof(Flag));
						if(StrEqual(ADMFlag, Flag, false))
						{
							KvGetString(kt, "Name", SkinName, sizeof(SkinName));
							KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
							if(GetConVarBool(g_cHideTeams))
							{
								int g_iTeamNum = KvGetNum(kt, "Team", 0);
								if(g_iTeamNum != 0)
								{
									if(GetClientTeam(param1) == g_iTeamNum)
									{
										AddMenuItem(smenu, UniqueId, SkinName);
									}
								}
								else
								{
									AddMenuItem(smenu, UniqueId, SkinName);
								}
							}
							else
							{
								AddMenuItem(smenu, UniqueId, SkinName);
							}
						}
					}
					while(KvGotoNextKey(kt, false));
					DisplayMenu(smenu, param1, MENU_TIME_FOREVER);
					SetMenuExitButton(smenu, true);
					CloseHandle(kt);
					CloseHandle(kv);
				}
				else
				{
					KvGotoNextKey(kv, false);
				}
			}
			while(!StrEqual(item, UniqueId));
			
		}
		case MenuAction_End: 
		{

			//CloseHandle(kv);
			CloseHandle(menu);
		}
	}
}



public int SkinMenu(Handle menu, MenuAction action, int param1, int param2) {

	char SkinName[32], SkinPath[128], ArmPath[128], UniqueId[32], Flag[16], StriTeamID[32];
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, g_szFileSkinPath);

	switch (action) {

		case MenuAction_Select: {

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);

			do {

				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));

				if (StrEqual(item, "def")) 
				{
					if(DeleteUserSkin(param1, GetClientTeam(param1)))
					{
						PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "SavedSkinsRemoved", param1);
					}
					else
					{
						PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "SavedSkinsRemoveFail", param1);
					}
					CloseHandle(kv);
					CloseHandle(menu);
					break;

				}
				
				if (StrEqual(item, UniqueId)) 
				{
					int iTeamID = KvGetNum(kv, "Team");
					KvGetString(kv, "Team", StriTeamID, sizeof(StriTeamID));

					if(!StrEqual(StriTeamID, ""))
					{
						if(GetClientTeam(param1) != iTeamID) 
						{
							PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "WrongTeam", param1);
							return;
						}
					}
					
					
					
					KvGetString(kv, "Name", SkinName, sizeof(SkinName));
					KvGetString(kv, "Skin", SkinPath, sizeof(SkinPath));
					KvGetString(kv, "Arms", ArmPath, sizeof(ArmPath));
					KvGetString(kv, "Flag", Flag, sizeof(Flag));
					
					if(StrEqual(Flag, "", false))
					{
						if(!IsModelPrecached(SkinPath))
						{
							PrecacheModel(SkinPath);
						}
						
						if(!StrEqual(SkinPath, "", false))
						{
							SetEntityModel(param1, SkinPath);
							
							PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "SelectedSkin", param1, SkinName);
							
							if(!StrEqual(ArmPath, "", false))
							{
								SetEntPropString(param1, Prop_Send, "m_szArmsModel", ArmPath);
								AddUserSkin(param1, SkinPath, ArmPath, GetClientTeam(param1));
							}
							else if(StrEqual(ArmPath, "", false)) 
							{
								if(GetClientTeam(param1) == 3)
								{
									SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[0]);
									AddUserSkin(param1, SkinPath, defArms[0], GetClientTeam(param1));
								}
								else if(GetClientTeam(param1) == 2)
								{
									SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[1]);
									AddUserSkin(param1, SkinPath, defArms[1], GetClientTeam(param1));
								}
							}
						}
						else
						{
							PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "InvalidSkin", param1);
						}
					}
					else if(!StrEqual(Flag, "", false))
					{
						int UserFlag = GetUserAcsessValue(Flag);
						if(CheckCommandAccess(param1, "command_PlayerVIP", UserFlag))
						{
							if(!IsModelPrecached(SkinPath))
							{
								PrecacheModel(SkinPath);
							}
							
							PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "SelectedSkin", param1, SkinName);
							
							if(!StrEqual(SkinPath, "", false))
							{
								SetEntityModel(param1, SkinPath);
								
								
								if(!StrEqual(ArmPath, "", false))
								{
									SetEntPropString(param1, Prop_Send, "m_szArmsModel", ArmPath);
									AddUserSkin(param1, SkinPath, ArmPath, GetClientTeam(param1));
								}
								else if(StrEqual(ArmPath, "", false)) 
								{
									if(GetClientTeam(param1) == 3)
									{
										SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[0]);
										AddUserSkin(param1, SkinPath, defArms[0], GetClientTeam(param1));
									}
									else if(GetClientTeam(param1) == 2)
									{
										SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[1]);
										AddUserSkin(param1, SkinPath, defArms[1], GetClientTeam(param1));
									}
								}
							}
						}
						else if(!CheckCommandAccess(param1, "command_PlayerVIP", UserFlag))
						{
							PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "NoPermissions", param1);
							return;
						}
					}
				} 
				else 
				{
					KvGotoNextKey(kv, false);
				}

			} while (!StrEqual(item, UniqueId));
		}
		case MenuAction_End: {

			if(kv != INVALID_HANDLE)
			{
				CloseHandle(kv);
			}
			
			if(menu != INVALID_HANDLE)
			{
				CloseHandle(menu);
			}
		}
	}
}

bool IsUserAdmin(int client)
{
	if(GetUserFlagBits(client) == 0)
	{
		return false;
	}
	else if(GetUserFlagBits(client) != 0)
	{
		return true;
	}
	return false;
}

stock int GetUserAcsessValue(char[] flags)
{
	int UserFlagNum = 0;
	if(StrContains(flags, "a", false) != -1)
	{
		UserFlagNum = UserFlagNum + 1;
	}
	if(StrContains(flags, "b", false) != -1)
	{
		UserFlagNum = UserFlagNum + 2;
	}
	if(StrContains(flags, "c", false) != -1)
	{
		UserFlagNum = UserFlagNum + 4;
	}
	if(StrContains(flags, "d", false) != -1)
	{
		UserFlagNum = UserFlagNum + 8;
	}
	if(StrContains(flags, "e", false) != -1)
	{
		UserFlagNum = UserFlagNum + 16;
	}
	if(StrContains(flags, "f", false) != -1)
	{
		UserFlagNum = UserFlagNum + 32;
	}
	if(StrContains(flags, "g", false) != -1)
	{
		UserFlagNum = UserFlagNum + 64;
	}
	if(StrContains(flags, "h", false) != -1)
	{
		UserFlagNum = UserFlagNum + 128;
	}
	if(StrContains(flags, "i", false) != -1)
	{
		UserFlagNum = UserFlagNum + 256;
	}
	if(StrContains(flags, "j", false) != -1)
	{
		UserFlagNum = UserFlagNum + 512;
	}
	if(StrContains(flags, "k", false) != -1)
	{
		UserFlagNum = UserFlagNum + 1024;
	}
	if(StrContains(flags, "l", false) != -1)
	{
		UserFlagNum = UserFlagNum + 2024;
	}
	if(StrContains(flags, "m", false) != -1)
	{
		UserFlagNum = UserFlagNum + 4096;
	}
	if(StrContains(flags, "n", false) != -1)
	{
		UserFlagNum = UserFlagNum + 8192;
	}
	if(StrContains(flags, "z", false) != -1)
	{
		UserFlagNum = UserFlagNum + 16384;
	}
	if(StrContains(flags, "o", false) != -1)
	{
		UserFlagNum = UserFlagNum + 32768;
	}
	if(StrContains(flags, "p", false) != -1)
	{
		UserFlagNum = UserFlagNum + 65536;
	}
	if(StrContains(flags, "q", false) != -1)
	{
		UserFlagNum = UserFlagNum + 131072;
	}
	if(StrContains(flags, "r", false) != -1)
	{
		UserFlagNum = UserFlagNum + 262144;
	}
	if(StrContains(flags, "s", false) != -1)
	{
		UserFlagNum = UserFlagNum + 524288;
	}
	if(StrContains(flags, "t", false) != -1)
	{
		UserFlagNum = UserFlagNum + 1048576;
	}
	return UserFlagNum;
}

stock bool ApplyUserSkin(int client)
{
	char SteamAuth[32];
	GetClientAuthId(client, AuthId_SteamID64, SteamAuth, sizeof(SteamAuth));
	Handle kv = CreateKeyValues("userids");
	FileToKeyValues(kv, g_szFileUserSkinPath);
	if(KvJumpToKey(kv, SteamAuth, false))
	{
		char g_szSkins[128], g_szArms[128];
		int g_iTeamNum = GetClientTeam(client);
		if(g_iTeamNum == 2)
		{
			if(KvJumpToKey(kv, "T", false))
			{
				KvGetString(kv, "Skin", g_szSkins, sizeof(g_szSkins));
				KvGetString(kv, "Arms", g_szArms, sizeof(g_szArms));
				if(SetModels(client, g_szSkins, g_szArms))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				CloseHandle(kv);
				return false;
			}
		}
		else if(g_iTeamNum == 3)
		{
			if(KvJumpToKey(kv, "CT", false))
			{
				KvGetString(kv, "Skin", g_szSkins, sizeof(g_szSkins));
				KvGetString(kv, "Arms", g_szArms, sizeof(g_szArms));
				if(SetModels(client, g_szSkins, g_szArms))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				CloseHandle(kv);
				return false;
			}
		}
		else
		{
			CloseHandle(kv);
			return false;
		}
	}
	else
	{
		CloseHandle(kv);
		return false;
	}
}

stock void PrecacheAllModels()
{
	char Arms[128], Skin[128];
	PrecacheModel(defArms[0]);
	PrecacheModel(defArms[1]);

	Handle kv = CreateKeyValues("Skins");
	Handle kt = CreateKeyValues("Admin_Skins");
	FileToKeyValues(kv, g_szFileSkinPath);
	FileToKeyValues(kt, g_szFileAutoSkinPath);
	KvGotoFirstSubKey(kv, false);
	KvGotoFirstSubKey(kt, false);

	do 
	{
	
		KvGetString(kv, "Skin", Skin, sizeof(Skin), "");
		KvGetString(kv, "Arms", Arms, sizeof(Arms), "");

		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}

		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kv, false));
	
	do 
	{
	
		KvGetString(kt, "SkinT", Skin, sizeof(Skin), "");
		KvGetString(kt, "ArmsT", Arms, sizeof(Arms), "");
		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}
		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kt, false));
	
	do 
	{
	
		KvGetString(kt, "SkinCT", Skin, sizeof(Skin), "");
		KvGetString(kt, "ArmsCT", Arms, sizeof(Arms), "");
		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}
		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kt, false));

	CloseHandle(kv);
	CloseHandle(kt);
}

stock bool ApplyMapSkins(int client)
{
	// PrintToServer("I got called!");
	char TeamCTSkin[128], TeamTSkin[128], TeamCTArms[128], TeamTArms[128], CurrentMapName[32];
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));	
	Handle kv = CreateKeyValues("mapskins");
	FileToKeyValues(kv, g_szFileMapSkins);
	if(KvJumpToKey(kv, CurrentMapName, false))
	{
		if(GetClientTeam(client) == 2)
		{
			if(KvJumpToKey(kv, "T", false))
			{
				KvGetString(kv, "Skin", TeamTSkin, sizeof(TeamTSkin), "");
				KvGetString(kv, "Arms", TeamTArms, sizeof(TeamTArms), "");
				if(SetModels(client, TeamTSkin, TeamTArms))
				{
					return true;
				}
				else
				{
					CloseHandle(kv);
					return false;
				}
			}
		}
		else if(GetClientTeam(client) == 3)
		{
			if(KvJumpToKey(kv, "CT", false))
			{
				KvGetString(kv, "Skin", TeamCTSkin, sizeof(TeamCTSkin), "");
				KvGetString(kv, "Arms", TeamCTArms, sizeof(TeamCTArms), "");
				if(SetModels(client, TeamCTSkin, TeamCTArms))
				{
					return true;
				}
				else
				{
					CloseHandle(kv);
					return false;
				}
			}
		}
		else
		{
			//PrintToServer("NO TEAM");
			CloseHandle(kv);
			return false;
		}
	}
	else
	{
		//PrintToServer("No MAP");
		CloseHandle(kv);
		return false;
	}
	
	return false;
}

stock bool IsValidClient(int client){
	if( MaxClients > client > 0 && IsClientConnected(client) && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}

stock bool IsClientWithArms(int client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_hMyWearables") != -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}



///////////////////////////////
//			Database
///////////////////////////////

stock void CreateDatabase()
{
	char err[255];
	db = SQL_Connect("PlayerSkins", true, err, sizeof(err));
	if (db == null)
	{
		PrintToServer("[PlayerSkin] Cannot connect to the database, error: %s", err);
	}
	else
	{
		if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS userskins (id VARCHAR(256) NOT NULL, t_skin VARCHAR(256) NOT NULL, t_arm VARCHAR(256) NOT NULL, ct_skin VARCHAR(256) NOT NULL, ct_arm VARCHAR(256) NOT NULL);"))
		{
			SQL_GetError(db, err, sizeof(err));
			PrintToServer("[PlayerSkin] Failed to create the table, error: %s", err);
		}
		else
		{
			PrintToServer("[PlayerSkin] Table has created if not existed.");
		}
	}
}


stock bool AddUserSkin(int client, char[] skin, char[] arms, int team)
{
	char err[255], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	if (db == null)
	{
		PrintToServer("[PlayerSkin] Cannot connect to the database, error: %s", err);
		return false;
	}
	else
	{
		if (IsUserOnDatabase(client))
		{
			PrintToServer("[PlayerSkin] User is already on database");
			char Query[512];
			
			if(team == 2)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET t_skin='%s', t_arm='%s' WHERE id='%s'", skin, arms, SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else if(team == 3)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET ct_skin='%s', ct_arm='%s' WHERE id='%s'", skin, arms, SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
		}
		else
		{
			PrintToServer("[PlayerSkin] New user data being inserted.");
			DBStatement statement = null;
			char Query[512];
			
			if(team == 2)
			{
				Format(Query, sizeof(Query), "INSERT INTO userskins (id, ct_skin, ct_arm, t_skin, t_arm) VALUES(? ,?, ?, ?, ?)");
				
				statement = SQL_PrepareQuery(db, Query, err, sizeof(err));
				if (statement == null)
				{
					PrintToServer("[PlayerSkin] An error occured, error: %s", err);
					delete statement;
					return false;
				}
				else
				{
					SQL_BindParamString(statement, 0, SteamAuth, false);
					SQL_BindParamString(statement, 0, SteamAuth, false);
					SQL_BindParamString(statement, 1, "", false);
					SQL_BindParamString(statement, 2, "", false);
					SQL_BindParamString(statement, 3, skin, false);
					SQL_BindParamString(statement, 4, arms, false);
					
					if (!SQL_Execute(statement))
					{
						delete statement;
						PrintToServer("[PlayerSkin] SQL did not executed: %s", err);
						return false;
					}
					else
					{
						delete statement;
						PrintToServer("[PlayerSkin] SQL executed.");
						return true;
					}
				}
			}
			else if(team == 3)
			{
				Format(Query, sizeof(Query), "INSERT INTO userskins (id, ct_skin, ct_arm, t_skin, t_arm) VALUES(? ,?, ?, ?, ?)");
				
				statement = SQL_PrepareQuery(db, Query, err, sizeof(err));
				if (statement == null)
				{
					PrintToServer("[PlayerSkin] An error occured, error: %s", err);
					delete statement;
					return false;
				}
				else
				{
					SQL_BindParamString(statement, 0, SteamAuth, false);
					SQL_BindParamString(statement, 1, skin, false);
					SQL_BindParamString(statement, 2, arms, false);
					SQL_BindParamString(statement, 3, "", false);
					SQL_BindParamString(statement, 4, "", false);
					
					if (!SQL_Execute(statement))
					{
						delete statement;
						return false;
					}
					else
					{
						delete statement;
						return true;
					}
				}
			}
			else
			{
				return false;
			}
		}
	}
}

stock bool DeleteUserSkin(int client, int team)
{
	char err[255], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	if (db == null)
	{
		PrintToServer("[PlayerSkin] Cannot connect to the database, error: %s", err);
		return false;
	}
	else
	{
		if (IsUserOnDatabase(client))
		{
			PrintToServer("[PlayerSkin] User is already on database");
			char Query[128];
			
			// Format(Query, sizeof(Query), "DELETE FROM userskins WHERE id='%s'", SteamAuth);
			
			if(team == 2)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET t_skin='', t_arm='' WHERE id='%s'", SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else if(team == 3)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET ct_skin='', ct_arm='' WHERE id='%s'", SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
			
		}
		else
		{
			return false;
		}
	}
}

stock bool IsUserOnDatabase(int client)
{
	char Query[128], SteamAuth[32], err[255];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	DBResultSet hQuery = null;
	Format(Query, sizeof(Query), "SELECT * FROM userskins");
	hQuery = SQL_Query(db, Query);
	while (SQL_FetchRow(hQuery))
	{
		SQL_FetchString(hQuery, 0, Query, sizeof(Query));
		if (StrEqual(Query, SteamAuth, false))
		{
			delete hQuery;
			return true;
		}
	}
	
	delete hQuery;
	return false;
}

stock void GetUserSkins(int client, char[] skin, int maxskinlen, char[] arms, int maxarmslen, int team)
{
	DBResultSet hQuery = null;
	char Query[128], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	
	if(IsUserOnDatabase(client))
	{
		if(team == 2)
		{
			Format(Query, sizeof(Query), "SELECT t_skin, t_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				Format(skin, maxskinlen, "");
				Format(arms, maxarmslen, "");
			}
			else
			{
				SQL_FetchString(hQuery, 0, skin, maxskinlen);
				SQL_FetchString(hQuery, 1, arms, maxarmslen);
			}
		}
		else if(team == 3)
		{
			Format(Query, sizeof(Query), "SELECT ct_skin, ct_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				Format(skin, maxskinlen, "");
				Format(arms, maxarmslen, "");
			}
			else
			{
				SQL_FetchString(hQuery, 0, skin, maxskinlen);
				SQL_FetchString(hQuery, 1, arms, maxarmslen);
			}
		}
		else
		{
			Format(skin, maxskinlen, "");
			Format(arms, maxarmslen, "");
		}
	}
	else
	{
		Format(skin, maxskinlen, "");
		Format(arms, maxarmslen, "");
	}
}


stock bool IsUserWithSkins(int client)
{
	DBResultSet hQuery = null;
	char Query[128], SteamAuth[32], SkinsPath[MAX_SKIN_PATH], ArmsPath[MAX_SKIN_PATH];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	int team = GetClientTeam(client);
	
	// PrintToServer("#1");
	
	if(IsUserOnDatabase(client))
	{
		// PrintToServer("#2");
		if(team == 2)
		{
			// PrintToServer("#3");
			Format(Query, sizeof(Query), "SELECT t_skin, t_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				return false;
			}
			else
			{
				SQL_FetchString(hQuery, 0, SkinsPath, sizeof(SkinsPath));
				SQL_FetchString(hQuery, 1, ArmsPath, sizeof(ArmsPath));
				
				// PrintToServer("IsUserWithSkins Has Passed Execution.");
				// PrintToServer("UserSkin: %s", SkinsPath);
				
				if(!StrEqual(SkinsPath, "", false))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
		}
		else if(team == 3)
		{
			Format(Query, sizeof(Query), "SELECT ct_skin, ct_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				return false;
			}
			else
			{
				SQL_FetchString(hQuery, 0, SkinsPath, sizeof(SkinsPath));
				SQL_FetchString(hQuery, 1, ArmsPath, sizeof(ArmsPath));
				
				// PrintToServer("IsUserWithSkins Has Passed Execution.");
				// PrintToServer("UserSkin: %s", SkinsPath);
				
				if(!StrEqual(SkinsPath, "", false))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}
