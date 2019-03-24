# PlayerSkin With Flag And SQL Support

## Description
A simple plugin to manage player models with their arms mostly grown on random player's ideas and people who construbuted on creating it on allied modders forum.
You can hhave these features when using this plugin:
- Per map skin configurations
- User group skins
- Categories for skin selection menu
- Per player skin
- SQLite + mySQL db skin storing
- etc ...

LINK on AlliedModders: https://forums.alliedmods.net/showthread.php?t=293846

## ConVars

- sm_pskin_enable 1 --- Enable/Disable command !pskin in chat (useful if you only want to use automatic admin skin set feature).
- sm_cat_enable 0 --- Enable/Disable categorie support via categories.ini file (see the configuration if your going to use this).
- sm_start_menu 0 --- Enable/Disable showing menu to players on round start.
- sm_hide_options 0 --- hide menu options that people does not have permissions to use.
- sm_hide_teams 0 --- hide opposit team's skins to be shown in user menu.
- sm_mapskins_enable 1 --- let you choose whether you want map skins to be applied or not.
- sm_round_timeout 20.0 --0 restrict usage of !pskin after a time after round start (disable it by setting it to 0.0)

## Configurations

### Configuring database

- In order to use the plugin's database, you must add an entry for plugin's database in database.cfg like this:

```
"Databases"
{
    "driver_default"        "mysql"
    
    // When specifying "host", you may use an IP address, a hostname, or a socket file path
    
    "default"
    {
        "driver"            "default"
        "host"                "localhost"
        "database"            "sourcemod"
        "user"                "root"
        "pass"                ""
        //"timeout"            "0"
        //"port"            "0"
    }
    
    "storage-local"
    {
        "driver"            "sqlite"
        "database"            "sourcemod-local"
    }

    **"PlayerSkins"
    {
        "driver"            "sqlite"
        "database"            "PlayerSkins"
    }**

    "clientprefs"
    {
        "driver"            "sqlite"
        "host"                "localhost"
        "database"            "clientprefs-sqlite"
        "user"                "root"
        "pass"                ""
        //"timeout"            "0"
        //"port"            "0"
    }
}
```