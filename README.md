# PlayerSkin (Flag & SQL/MySQL Support)

### Description
A simple plugin to manage player models with their arms mostly grown on random player's ideas and people who construbuted on creating it on allied modders forum.
You can hhave these features when using this plugin:
- Per map skin configurations;
- User per skins;
- Skin por SteamID_64;
- Per player skin;
- Categories for skin selection menu;
- Support SQLite + MySQL;
- Etc;

**Link on AlliedModders:** https://forums.alliedmods.net/showthread.php?t=293846

### ConVars
- `sm_pskin_enable 1` - Enable/Disable command `!pskin` in chat; ***(Useful if you only want to use automatic admin skin set feature)***
- `sm_cat_enable 0` - Enable/Disable categorie support via categories.ini file; ***(See the configuration if your going to use this)***
- `sm_start_menu 0` - Enable/Disable showing menu to players on round start;
- `sm_hide_options 0` - hide menu options that people does not have permissions to use;
- `sm_hide_teams 0` - hide opposit team's skins to be shown in user menu;
- `sm_mapskins_enable 1` - let you choose whether you want map skins to be applied or not;
- `sm_round_timeout 20.0` - restrict usage of `!pskin` after a time after round start; ***(Disable it by setting it to 0.0)***
- `sm_ct_skin ""` - Add a default skin for CT;
- `sm_t_skin ""` - Add a default skin for T;
- `sm_ct_arm ""` - Add a default arm for CT;
- `sm_t_arm ""` - Add a default arm for T;

### Commands
- `sm_pskin` - Abre o menu de skins;
- `sm_models` - Abre o menu de skins;
- `sm_skins` - Abre o menu de skins;

### Configuring Database
- In order to use the plugin's database, you must add an entry for plugin's database in `databases.cfg` like this:
```
"PlayerSkins"
{
	"driver"		"sqlite"
	"database"		"PlayerSkins"
}
```

### Configuring `skins.ini`
- This file is use by menu that plugin will show to users when they type the chat trigger `"!skins"` and is also used by category file.
```
"Skins"
{
    "santagirl" //This is the section name, and is not important it can be anything even same for every skin.
    {
        "Name"        	"Santa Girl [T]" 																	//This is the name that will be shown into the menu as the skin's identifier to the users
        "Skin"       	"models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie.mdl" 			//The skin's Model path
        "Arms"       	"models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie_arms.mdl" 	//The skin's Arms path
        "Team"        	"2" 																				//The team number which the skin is for (2 = Terror, 3= Counter, Leave it empty for both teams)
        "Flag"			"z" 																				//The admin flag which will be able to use this skin (Leave it empty to make it public)
        "u_id"       	"skin_santagirl" 																	//The skin's unique id which must be unique per skin in the menu (this is used for the menu to detect which skin the user has chosen)
        "catgroup"    	"cat_female" 																		//This is the cat id that will help catergoties to detect that this is for blabla category
    }
} 
```

### Configuring `adminskins.ini`
- This file is used to setup an automated skin system to change user's skins.
```
"AdminSkins"
{
    //It's a pre-defined config key that will be used for non-admin users.
    "def"
    {
		//You can leave it empty if there is no default skin for the team on the current flag.
        "SkinT" 	""
        "ArmsT" 	""
        "SkinCT"    ""
        "ArmsCT"    ""
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
- With this file you can setup categories and use them after turning on the related cvar.
```
"Categories"
{
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

### Configuring `userskins.ini`
- Uses SteamID_64 to setup skins for a particular Steam_ID.
```
"UserIds"
{
    "SteamId_64"
    {
        "CT" //Team Number = 3 (for use in other modes and not csgo)
        {
            "Skin"    "models/player/custom_player/caleon1/harleyquinn/harleyquinn.mdl"
            "Arms"    "models/player/custom_player/caleon1/harleyquinn/harleyquinn_arms.mdl"
        }
        "T" //Team Number = 3 (for use in other modes and not csgo)
        {
            "Skin"    "models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie.mdl"
            "Arms"    "models/player/custom_player/kuristaja/cso2/natalie_santagirl/natalie_arms.mdl"
        }
    }
}  
```

### Configuring `mapskins.ini`
- This will be used to setup per map skins. ***(Does not support prefix)***
```
"MapSkins"
{
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
