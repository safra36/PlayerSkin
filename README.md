# PlayerSkin With Flag And SQL Support

## Description
A simple plugin to manage player models with their arms mostly grown on random player's ideas and people who construbuted on creating it on allied modders forum.
You can hhave these features when using this plugin:
- Per map skin configurations;
- User group skins;
- Categories for skin selection menu;
- Per player skin;
- SQLite + MySQL db skin storing;
- etc;

**Link on AlliedModders:** https://forums.alliedmods.net/showthread.php?t=293846

## ConVars
- `sm_pskin_enable 1` - Enable/Disable command `!pskin` in chat. ***(Useful if you only want to use automatic admin skin set feature)***
- `sm_cat_enable 0` - Enable/Disable categorie support via categories.ini file. ***(See the configuration if your going to use this)***
- `sm_start_menu 0` - Enable/Disable showing menu to players on round start.
- `sm_hide_options 0` - hide menu options that people does not have permissions to use.
- `sm_hide_teams 0` - hide opposit team's skins to be shown in user menu
- `sm_mapskins_enable 1` - let you choose whether you want map skins to be applied or not.
- `sm_round_timeout 20.0` - restrict usage of `!pskin` after a time after round start. ***(Disable it by setting it to 0.0)***
- `sm_ct_skin ""` - Add a default skin for CT.
- `sm_t_skin ""` -  Add a default skin for T.
- `sm_ct_arm ""` - Add a default arm for CT.
- `sm_t_arm ""` - Add a default arm for T.
- `sm_arms_delay` - Set a delay before the arms being set ***(must be float, 0.0 means disabled)***

## Configurations

### Configuring Database
- In order to use the plugin's database, you must add an entry for plugin's database in `databases.cfg` like this:
```
"Databases"
{
    "PlayerSkins"
	{
		"driver"		"sqlite"
		"database"		"PlayerSkins"
	}
}
```

### Configuring `skins.ini`
- This file is use by menu that plugin will show to users when they type the chat trigger `"!skins"` and is also used by category file:
```
"Skins" {
    "santagirl" //This is the section name, and is not important it can be anything even same for every skin.
    {
        "Name"        	"Santa Girl [T]" 																	//This is the name that will be shown into the menu as the skin's identifier to the users.
        "Skin"       	"models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie.mdl" 			// The skin's Model path
        "Arms"       	"models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie_arms.mdl" 	//The skin's Arms path
        "Team"        	"2" 																				//The team number which the skin is for (2 = Terror, 3= Counter , Leave it empty for both teams)
        "Flag"			"z" 																				//The admin flag which will be able to use this skin (Leave it empty to make it public)
        "u_id"       	"skin_santagirl" 																	//The skin's unique id which must be unique per skin in the menu (this is used for the menu to detect which skin the user has chosen)
        "catgroup"    	"cat_female" 																		//This is the cat id that will help catergoties to detect that this is for blabla category
    }
 } 
```

### Configuring `admin_skins.ini`
- This file is used to setup an automated skin system to change user's skins.
```
"Admin_Skins" {
    "USER_FLAGS_CHAR"
    {
        //You can leave it empty if there is no default skin for the team on the current flag.
        "SkinT" 	"DEFAULT TERROR MODEL PATH FOR THE FLAG"
        "ArmsT" 	"DEFAULT TERROR ARM PATH FOR THE FLAG"
        "SkinCT"    "DEFAULT COUNTER-TERROR MODEL PATH FOR THE FLAG"
        "ArmsCT"    "DEFAULT COUNTER-TERROR ARM PATH FOR THE FLAG"
    }
    //It's a pre-defined config key that will be used for non-admin users.
    "def"
    {
        "SkinT" 	"Default skin for non-admin users (T)"
        "ArmsT" 	"Default arms for non-admin users (T)"
        "SkinCT"    "Default skin for non-admin users (CT)"
        "ArmsCT"    "Default arms for non-admin users (CT)"
    }
    "z"
    {
        "SkinT" 	"models/player/custom_player/kuristaja/deadpool/deadpool.mdl"
        "ArmsT"  	"models/player/custom_player/kuristaja/deadpool/deadpool_arms.mdl"
        "SkinCT"    "models/player/custom_player/kuristaja/ak/batman/batmanv2.mdl"
        "ArmsCT"    "models/player/custom_player/kuristaja/ak/batman/batman_arms.mdl"
    }
 } 
```

### Configuring `categories.ini`
- With this file you can setup categories and use them after turning on the related cvar
```
"Categories" {
    "EXAMPLE_CATEGORY"
    {
        "Name"        "MENU SHOWING NAME"
        "Flag"        "FLAGS THAT WILL BE CHECKED AND ADDED TO THE MENU"
        "u_id"        "Menu Unique ID"
		"catgroup"    "cat_ID"
    }
    "Admins"
    {
        "Name"        "Admins"
        "Flag"        "z"
        "u_id"        "menu_admin"
        "catgroup"    "cat_admin"
    }
    "Vips"
    {
        "Name"        "Vips"
        "Flag"        "r"
        "u_id"        "menu_vip"
        "catgroup"    "cat_vip"
    }
    "Users"
    {
        "Name"        "Users"
        "Flag"        ""
        "u_id"        "menu_users"
        "catgroup"    "cat_normal"
    }
 }  
```

### Configuring Skin per SteamID
- Uses steamid64 to setup skins for a particular steamid
```
"userids" {
    "SteamId_64"
    {
        "CT" //Team Number = 3 (for use in other modes and not csgo)
        {
            "Skin"    "Model Path"
            "Arms"    "Arms Path"
        }
        "T" //Team Number = 3 (for use in other modes and not csgo)
        {
            "Skin"    "Model Path"
            "Arms"    "Arms Path"
        }
    }
    "76561198123013657"
    {
        "CT"
        {
            "Skin"    "models/player/custom_player/caleon1/harleyquinn/harleyquinn.mdl"
            "Arms"    "models/player/custom_player/caleon1/harleyquinn/harleyquinn_arms.mdl"
        }
        "T"
        {
            "Skin"    "models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie.mdl"
            "Arms"    "models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie_arms.mdl"
        }
    }
 }  
```

### Configuring Skin per Map
- This will be used to setup per map skins ***(Does not support prefix)***
```
"mapskins" {
    "MAP_NAME"
    {
        "CT"
        {
            "Skin"        ""
            "Arms"        ""
        }
        "T"
        {
            "Skin"        ""
            "Arms"        ""
        }
    }
	"de_dust2"
    {
        "CT"
        {
            "Skin"        "models/player/custom_player/kuristaja/cso2/gsg9/gsg9.mdl"
            "Arms"        "models/player/custom_player/kuristaja/cso2/gsg9/gsg9_arms.mdl"
        }
        "T"
        {
            "Skin"        "models/player/custom_player/kuristaja/cso2/gsg9/gsg9.mdl"
            "Arms"        "models/player/custom_player/kuristaja/cso2/gsg9/gsg9_arms.mdl"
        }
    }
 } 
```


## Adding Glove Plugin Support
since i didn't want the plugin to have seperated versions i just made this version edit-ready which means i just commented everything you be needing to make the plugin compatible with that plugin, in-order to achive that, put these lines of code instead of line starting at `211 to 302`
also don't forget to uncomment the `#include` at the top of the file

```
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

		if(GetConVarFloat(g_cDelayArmSet) == 0.0)
		{
			if(!IsClientWithArms(client))
			{
				if(!StrEqual(arms, "", false))
				{
					// SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
					Gloves_SetArmsModel(client, arms);
				}
				else
				{
					int g_iTeam = GetClientTeam(client);
					if(g_iTeam == 2)
					{
						// SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
						Gloves_SetArmsModel(client, defArms[1]);
					}
					else if(g_iTeam == 3)
					{
						// SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
						Gloves_SetArmsModel(client, defArms[0]);
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
			Format(g_szClientPendingArms[client], sizeof(g_szClientPendingArms[]), arms)
			CreateTimer(GetConVarFloat(g_cDelayArmSet), Timer_HandleArmsSet, client);
			return true;
		}
	}
	else
	{
		return false;
	}
}

public Action Timer_HandleArmsSet(Handle timer, any client)
{
	if(!IsClientWithArms(client))
	{
		if(!StrEqual(g_szClientPendingArms[client], "", false))
		{
			// SetEntPropString(client, Prop_Send, "m_szArmsModel", g_szClientPendingArms[client]);
			Gloves_SetArmsModel(client, g_szClientPendingArms[client]);
			Format(g_szClientPendingArms[client], sizeof(g_szClientPendingArms[]), "")
		}
		else
		{
			int g_iTeam = GetClientTeam(client);
			if(g_iTeam == 2)
			{
				// SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
				Gloves_SetArmsModel(client, defArms[1]);
			}
			else if(g_iTeam == 3)
			{
				// SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
				Gloves_SetArmsModel(client, defArms[0]);
			}

			Format(g_szClientPendingArms[client], sizeof(g_szClientPendingArms[]), "")
		}
	}
	else
	{
		PrintToServer("[PlayerSkin] Gloves detected, skipping setting arms ...");
	}
}
```