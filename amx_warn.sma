#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <fakemeta>

#define MAX_WARN 3

#define TAG "[WARN]"

#define ACCES ADMIN_KICK

#define BAN_TIME 120

#define PLUGIN "Warn System"
#define AUTHOR "Doctor"
#define VERSION "1.0"

new g_warns[33];

new g_dede;


enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	YELLOW = 1, // NORMAL alias
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}
 
new TeamName[][] =
{
	"",
	"TERRORIST",
	"CT",	
	"SPECTATOR"
}


public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR);
	register_concmd("amx_warn","cmd_warn",ACCES,"amx_warn <NUME>");
        g_dede = nvault_open("warn_vaults");
        register_forward(FM_ClientUserInfoChanged, "ClientUserInfoChanged")
}

public ClientUserInfoChanged(id)
{
        static const name[] = "name"
        static szOldName[32], szNewName[32]
        pev(id, pev_netname, szOldName, charsmax(szOldName))
        if( szOldName[0] )
        {
                get_user_info(id, name, szNewName, charsmax(szNewName))
                if( !equal(szOldName, szNewName) )
                {
                        set_user_info(id, name, szOldName)
                        ColorChat(id, TEAM_COLOR,"^1%s^4 Pe acest server nu este permisa schimbarea numelui !");
                        return FMRES_HANDLED
                }
        }
        return FMRES_IGNORED
}

public cmd_warn(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED;
	
	new arg[33]
	read_argv(1, arg, charsmax(arg) - 1)
	new target = cmd_target(id, arg, 7)
	new admin_name[35], player_name[35];
	get_user_name(target, player_name, charsmax(player_name) - 1);
	get_user_name(id, admin_name, charsmax(admin_name) - 1);
	
	
	if(!target)
	{
		return 1
	}
	
	if(g_warns[target] < MAX_WARN)
	{
		g_warns[target]++;
		ColorChat(0, TEAM_COLOR, "^4%s^1 Adminul ^4%s^1 i-a dat un avertisment lui ^4%s",TAG,admin_name,player_name);
		return 0
	}

	else
	{
		server_cmd("amx_ban 120 #%d %s Ai fost banat !",get_user_userid(target), TAG);
		return 0
	}

	return 0
}


public SaveData(id)
{
        new PlayerName[35];
        get_user_name(id,PlayerName,34);
        
        new vaultkey[64],vaultdata[256];
        format(vaultkey,63,"%s",PlayerName);
        format(vaultdata,255,"%i",g_warns[id]);
        nvault_set(g_dede,vaultkey,vaultdata);
        return PLUGIN_CONTINUE;
}
public LoadData(id)
{
        new PlayerName[35];
        get_user_name(id,PlayerName,34);
        
        new vaultkey[64],vaultdata[256];
        format(vaultkey,63,"%s",PlayerName);
        format(vaultdata,255,"%i",g_warns[id]);
        nvault_get(g_dede,vaultkey,vaultdata,255);
        
        replace_all(vaultdata, 255, "`", " ");
        
        new playerw[32]
        
        parse(vaultdata, playerw, 31);
        
        g_warns[id] = str_to_num(playerw);
        
        return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	SaveData(id)
}

public client_putinserver(id)
{
	LoadData(id)
	new szName[35];
	get_user_name(id, szName, charsmax(szName) - 1);
	ColorChat(id, TEAM_COLOR, "^4%s ^1Buna ^4%s^1 ai ^3%i^1 warn-uri la ^4%s^1 vei primi ban, ai grija !",TAG,szName,g_warns[id],MAX_WARN);
	ColorChat(id, TEAM_COLOR, "^4%s ^1Plugin creat si configurat de catre ^4%s",TAG,AUTHOR);
}


ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	new message[256];
 
	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}
	 
	vformat(message[1], 251, msg, 4);
 
	// Make sure message is not longer than 192 character. Will crash the server.
	message[191] = '^0';
 
	new team, ColorChange, index, MSG_Type;
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}

	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);
 

	ShowColorMessage(index, MSG_Type, message);
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}
 
ShowColorMessage(id, type, message[])
{
	static get_user_msgid_saytext;
	if(!get_user_msgid_saytext)
	{
		get_user_msgid_saytext = get_user_msgid("SayText");
	}
	message_begin(type, get_user_msgid_saytext, _, id);
	write_byte(id)	
	write_string(message);
	message_end();	
}
 
Team_Info(id, type, team[])
{
	static bool:teaminfo_used;
	static get_user_msgid_teaminfo;
	if(!teaminfo_used)
	{
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
		teaminfo_used = true;
	}
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();
 
	return 1;
}
 
ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}
 
	return 0;
}
 
FindPlayer()
{
	new i = -1;
	static iMaxPlayers;
	if( !iMaxPlayers )
	{
		iMaxPlayers = get_maxplayers( );
	}
	while(i <= iMaxPlayers)
	{
		if(is_user_connected(++i))
			return i;
	}
 
	return -1;
}
