#include <a_samp>
#include <a_mysql>
#include <Pawn.CMD>

main() { }

#undef MAX_PLAYERS
#define MAX_PLAYERS 20

/* ------------------------- ENUM ---------------------------*/

enum 
{
    DIALOG_NULL,
    DIALOG_REGISTRO,
    DIALOG_LOGIN1,
    DIALOG_LOGIN2,
    DIALOG_LOGIN3
};

enum player_info
{
    pID,
    pPassword[50],
    pCorreo[120],
    pGenero,
    pSkin,
    pNivel,
    Float:pPosX,
    Float:pPosY,
    Float:pPosZ,
    pInterior,
    pVirtualWorld
}


/* ------------------------ VARIABLES ------------------------*/

new MySQL:Database;

new NombreJugador[MAX_PLAYERS][MAX_PLAYER_NAME];
new IsPlayerSpawn[MAX_PLAYERS];
new PlayerRegistro[MAX_PLAYERS];

new Text:TDLogin[4], Text:NombreServidor;

new PlayerInfo[MAX_PLAYERS][player_info];

/* ------------------------ CALLBACKS ------------------------ */

public OnGameModeInit() 
{
    print("Iniciando el GM");
    Database = mysql_connect("localhost", "root", "", "fenixzone");
    if(Database == MYSQL_INVALID_HANDLE)
    {
        print("Error con conexion a base de datos.");
        return 1;
    }
    SetGameModeText("FZ:RP v0.01 - Rol en español");
    SendRconCommand("hostname FZ Roleplay [S1] Rol en español");
    UsePlayerPedAnims();
    AddPlayerClass(23, 1685.6201, -2331.5374, -2.6797, 269.1424, 0, 0, 0, 0, 0, 0);

    SetTimer("TimerSegundo", 1000, 1);
    /* Textdraws */
    CargarTextDraws();
    return 1;
}

public OnPlayerConnect(playerid)
{
    GetPlayerName(playerid, NombreJugador[playerid], MAX_PLAYER_NAME);
    SetPlayerColor(playerid, 0xFFFFFF00);

    IsPlayerSpawn[playerid] = 0;
    PlayerRegistro[playerid] = 0;
    //reseteamos la variable
    new player_temp[player_info];
    PlayerInfo[playerid] = player_temp;

	if(IsPlayerNPC(playerid))
	{
		SetSpawnInfo(playerid, 0, 192, 1958.3299, 1343.1199, 15.3599, 269.1499, 0, 0, 0, 0, 0, 0);
		return 1;
	}
    new query[100];
    mysql_format(Database, query, sizeof query, "SELECT * FROM usuarios WHERE Username = '%s'", NombreJugador[playerid]);
    mysql_query(Database, query);
    new row;
    cache_get_row_count(row);
    if(row)
    {
        cache_get_value_name(0, "Password", PlayerInfo[playerid][pPassword], 50);
        cache_get_value_name_float(0, "posX", PlayerInfo[playerid][pPosX]);
        cache_get_value_name_float(0, "posY", PlayerInfo[playerid][pPosY]);
        cache_get_value_name_float(0, "posZ", PlayerInfo[playerid][pPosZ]);
        cache_get_value_name_int(0, "Interior", PlayerInfo[playerid][pInterior]);
        cache_get_value_name_int(0, "VirtualWorld", PlayerInfo[playerid][pVirtualWorld]);
        cache_get_value_name_int(0, "Nivel", PlayerInfo[playerid][pNivel]);
        cache_get_value_name_int(0, "Genero", PlayerInfo[playerid][pGenero]);
        cache_get_value_name_int(0, "Skin", PlayerInfo[playerid][pSkin]);

        SetSpawnInfo(playerid, PlayerInfo[playerid][pSkin], NO_TEAM, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ], 0.0, 0, 0, 0, 0, 0, 0);
        SetTimerEx("MostrarDialog", 1000, false, "i", playerid);
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_INPUT, "Registra una nueva cuenta", "Contraseña:", "Siguiente", "Salir");
    }

    for(new i; i < sizeof TDLogin; ++i) TextDrawShowForPlayer(playerid, TDLogin[i]);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(IsPlayerSpawn[playerid])
    {
        GuardarCuenta(playerid);
    }
    IsPlayerSpawn[playerid] = 0;
    return 1;
}


public OnPlayerSpawn(playerid)
{
    if(!IsPlayerSpawn[playerid])//Login - Registro
    {
        IsPlayerSpawn[playerid] = 1;
        if(PlayerRegistro[playerid] == 1)//Registro
        {
            PlayerInfo[playerid][pNivel] = 1;
        }
        else //Login
        {

        }
        CargarObjetos(playerid);
        PlayerRegistro[playerid] = 0;
        SendClientMessage(playerid, -1, "{DBED15}El servidor está en constante crecimiento. Publica tus sugerencias en el foro.");
        SendClientMessage(playerid, -1, "{FFFFFF}Escribe {DBED15}/ayuda{FFFFFF} para recibir ayuda.");
        SendClientMessage(playerid, -1, "Para recibir ayuda de otros jugadores, usa {DBED15}/n {FFFFFF}({DBED15}y tu pregunta{FFFFFF}).");
        SetPlayerScore(playerid, PlayerInfo[playerid][pNivel]);
        SetPlayerInterior(playerid, PlayerInfo[playerid][pInterior]);
        SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pVirtualWorld]);
        for(new i; i < sizeof TDLogin; ++i) TextDrawHideForPlayer(playerid, TDLogin[i]);
        TextDrawShowForPlayer(playerid, NombreServidor);
    }
    else
    {

    }
    return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(IsPlayerSpawn[playerid] || IsPlayerNPC(playerid))
	{
		return 1;
	}
	return 0;
}

public OnPlayerRequestClass(playerid, classid)
{
    if(IsPlayerSpawn[playerid] && !IsPlayerNPC(playerid)/* && NivelAdmin[playerid] <= 3*/)
    {
        SpawnPlayer(playerid);
        ForceClassSelection(playerid);
        SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_LOGIN1:
        {
            if(!response)
            {
                Kick(playerid);
                return 1;
            }
            if(strlen(inputtext) < 2)
            {
                SendClientMessage(playerid, 0xAFAFAFAA, "Contraseña incorrecta.");
                ShowPlayerDialog(playerid, DIALOG_LOGIN1, DIALOG_STYLE_INPUT, "Contraseña incorrecta - Intenta nuevamente", "Ingresa tu contraseña:", "Entrar", "Salir"); 
                return 1;
            }
            if(strcmp(inputtext, PlayerInfo[playerid][pPassword], true) == 0)
            {
                new query[150];
                mysql_format(Database, query, sizeof query, "SELECT * FROM usuarios WHERE Username = '%s' LIMIT 1", NombreJugador[playerid]);
                mysql_tquery(Database, query, "OnPlayerLogin", "ii", playerid, PlayerInfo[playerid][pID]);
            }
            else
            {
                SendClientMessage(playerid, 0xAFAFAFAA, "Contraseña incorrecta.");
                ShowPlayerDialog(playerid, DIALOG_LOGIN1, DIALOG_STYLE_INPUT, "Contraseña incorrecta - Intenta nuevamente", "Ingresa tu contraseña:", "Entrar", "Salir"); 
            }
        }
        case DIALOG_REGISTRO:
        {
            if(!response)
            {
                Kick(playerid);
                return 1;
            }
            if(strlen(inputtext) < 2)
            {
                ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_INPUT, "Registra una nueva cuenta", "Ingresa la contraseña que quieres utilizar.", "Siguiente", "Salir");
                return 1;
            }
            if(strfind(inputtext, "DELETE", true) != -1 || strfind(inputtext, "'", true) != -1)
            {
                ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_INPUT, "Registra una nueva cuenta", "Ingresa la contraseña que quieres utilizar.", "Siguiente", "Salir");
                return 1;
            }
            format(PlayerInfo[playerid][pPassword], 50, "%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_LOGIN2, DIALOG_STYLE_INPUT, "Ingresa tu dirección de e-mail", "Ingresa un e-mail válido para recuperar tu contraseña en caso de perderla.\n\nTu e-mail:", "Siguiente", "Salir");
        }
        case DIALOG_LOGIN2:
        {
            if(!response)
            {
                Kick(playerid);
                return 1;
            }
            if(strlen(inputtext) < 2)
            {
                ShowPlayerDialog(playerid, DIALOG_LOGIN2, DIALOG_STYLE_INPUT, "Ingresa tu dirección de e-mail", "Ingresa un e-mail válido para recuperar tu contraseña en caso de perderla.\n\nTu e-mail:", "Siguiente", "Salir");
                return 1;
            }
            if(strfind(inputtext, ".", true) == -1 || strfind(inputtext, "@", true) == -1 || strfind(inputtext, "DELETE", true) != -1 || strfind(inputtext, "'", true) != -1)
            {
                ShowPlayerDialog(playerid, DIALOG_LOGIN2, DIALOG_STYLE_INPUT, "Ingresa tu dirección de e-mail", "Ingresa un e-mail válido para recuperar tu contraseña en caso de perderla.\n\nTu e-mail:", "Siguiente", "Salir");
                return 1;
            }
            new query[150], row;
            mysql_format(Database, query, sizeof query, "SELECT * FROM usuarios WHERE Correo = '%s'", inputtext);
            mysql_query(Database, query);
            cache_get_row_count(row);
            if(row)
            {
                PlayerRegistro[playerid] = 1;
                SendClientMessage(playerid, 0xFF9900AA, "Para recuperar tu contraseña, ingresa a http://rol.fenixzone.com/perdida.php");
                KickEx(playerid);
                return 1;
            }
            format(PlayerInfo[playerid][pCorreo], 120, "%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_LOGIN3, DIALOG_STYLE_LIST, "¿Eres hombre o mujer?", "Hombre\nMujer", "Registrar", "Salir");
        }
        case DIALOG_LOGIN3:
        {
            if(!response)
            {
                Kick(playerid);
                return 1;
            }
            if(listitem == 0)
            {
                PlayerInfo[playerid][pSkin] = 250;
                PlayerInfo[playerid][pGenero] = 1;
            }   
            else if(listitem == 1) 
            {
                PlayerInfo[playerid][pSkin] = 11;
                PlayerInfo[playerid][pGenero] = 2;
            }
            else return Kick(playerid);
            PlayerRegistro[playerid] = 1;
            SetSpawnInfo(playerid, 0, NO_TEAM, 1714.7008, -1898.6792, 13.5665, 269.1499, 0, 0, 0, 0, 0, 0);
            new string[200];
            for(new i; i < 20; ++i) SendClientMessage(playerid, -1, "");
            format(string, sizeof string, "{FFFFFF}Felicitaciones {00CCFF}%s{FFFFFF}, tu cuenta fue creada correctamente.", NombreJugador[playerid]);
            SendClientMessage(playerid, 0xAFAFAFAA, string);
            mysql_format(Database, string, sizeof string, "INSERT INTO usuarios (`Username`,`Correo`,`Password`,`Genero`,`Skin`,`Nivel`) VALUES ('%s','%s','%s','%i','%i','1')", NombreJugador[playerid], PlayerInfo[playerid][pCorreo], PlayerInfo[playerid][pPassword], PlayerInfo[playerid][pGenero], PlayerInfo[playerid][pSkin]);
            mysql_query(Database, string);
            PlayerInfo[playerid][pID] = cache_insert_id();
            SpawnPlayer(playerid);
        }
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    return 1;
}
/* ---------------- COMANDOS --------------------------*/

CMD:n(playerid, params[])
{
    return 1;
}

CMD:ayuda(playerid, params[])
{
    return 1;
}

/* ----------------- ----------------------- */

forward Descongelar(playerid);
public Descongelar(playerid) return TogglePlayerControllable(playerid, 1);

forward SpawnPlayerEx(playerid);
public SpawnPlayerEx(playerid) return SpawnPlayer(playerid);

forward Kickear(playerid);
public Kickear(playerid) return Kick(playerid);

forward TimerSegundo();
public TimerSegundo()
{
    for(new i, j = GetPlayerPoolSize(); i <= j; ++i)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!IsPlayerSpawn[i] && PlayerRegistro[i] == 0)
        {
            for(new m; m < 20; ++m) SendClientMessage(i, 1, "");
        }
    }
    return 1;
}


forward OnPlayerLogin(playerid, id);
public OnPlayerLogin(playerid, id)
{
    new id2;
    cache_get_value_name_int(0, "id", id2);
    if(id != id2)
    {
        return 1;
    }
    PlayerRegistro[playerid] = 2;
    SendClientMessage(playerid, -1, "-----------------------------------------------------------------------------------------------------");
    format(string, sizeof string, "{FFFFFF}Hola {00CCFF} %s{FFFFFF}, te vimos por última vez el 00/00/00", NombreJugador[playerid]);
    SendClientMessage(playerid, -1, string);
    SendClientMessage(playerid, -1, "-----------------------------------------------------------------------------------------------------");
    SendClientMessage(playerid, -1, "Cargando datos del juego...");
    SetTimerEx("SpawnPlayerEx", 3000, false, "i", playerid);
    return 1;
}

forward MostrarDialog(playerid);
public MostrarDialog(playerid) 
{
    ShowPlayerDialog(playerid, DIALOG_LOGIN1, DIALOG_STYLE_PASSWORD, "Esta cuenta está registrada", "Ingresa tu contraseña:", "Entrar", "Salir"); 
    return 1;
}

/* ----------------------------- FUNCIONES ---------------------------*/

CargarObjetos(playerid)
{
    TogglePlayerControllable(playerid, 0);
    GameTextForPlayer(playerid, "~r~Cargando...~n~~w~ Espera por favor", 5000, 4);
    SetTimerEx("Descongelar", 5000, false, "i", playerid);
    return 1;
}

KickEx(playerid)
{
    SetTimerEx("Kickear", 1000, false, "i", playerid);
    return 1;
}

GuardarCuenta(playerid)
{
    printf("Guardando cuenta de %s (%d)", NombreJugador[playerid], playerid);
    GetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
    PlayerInfo[playerid][pVirtualWorld] = GetPlayerVirtualWorld(playerid);
    PlayerInfo[playerid][pInterior] = GetPlayerInterior(playerid);
    new query[500];
    mysql_format(Database, query, sizeof query, "UPDATE usuarios SET `posX`='%f',`posY`='%f',`posZ`='%f',`Interior`='%i',`VirtualWorld`='%i' WHERE `ID`='%i'", PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ], PlayerInfo[playerid][pInterior], PlayerInfo[playerid][pVirtualWorld], PlayerInfo[playerid][pID]);
    mysql_tquery(Database, query);
    return 1;
}

CargarTextDraws()
{
    TDLogin[0] = TextDrawCreate(0.0, 0.0, "---");
    TextDrawUseBox(TDLogin[0], 1);
    TextDrawBoxColor(TDLogin[0], 255);
    TextDrawTextSize(TDLogin[0], 640.0, -69.0);
    TextDrawAlignment(TDLogin[0], 0);
    TextDrawBackgroundColor(TDLogin[0], 255);
    TextDrawFont(TDLogin[0], 3);
    TextDrawLetterSize(TDLogin[0], 1.0, 12.1999);
    TextDrawColor(TDLogin[0], 255);
    TextDrawSetOutline(TDLogin[0], 1);
    TextDrawSetProportional(TDLogin[0], 1);
    TextDrawSetShadow(TDLogin[0], 1);

    TDLogin[1] = TextDrawCreate(0.0, 337.0, "---");
    TextDrawUseBox(TDLogin[1], 1);
    TextDrawBoxColor(TDLogin[1], 255);
    TextDrawTextSize(TDLogin[1], 640.0, -60.0);
    TextDrawAlignment(TDLogin[0], 0);
    TextDrawBackgroundColor(TDLogin[1], 255);
    TextDrawFont(TDLogin[1], 3);
    TextDrawLetterSize(TDLogin[1], 0.8999, 15.0);
    TextDrawColor(TDLogin[1], 255);
    TextDrawSetOutline(TDLogin[1], 1);
    TextDrawSetProportional(TDLogin[1], 1);
    TextDrawSetShadow(TDLogin[0], 1);

    TDLogin[2] = TextDrawCreate(190.0, 350.0, "WEB: HTTP://ROL.FENIXZONE.COM");
    TextDrawFont(TDLogin[2], 1);
    TextDrawColor(TDLogin[2], 0x6699FFFF);

    TDLogin[3] = TextDrawCreate(120.0, 50.0, "FenixZone Roleplay");
    TextDrawLetterSize(TDLogin[3], 1.2, 2.0999);
	TextDrawFont(TDLogin[3], 3);

    NombreServidor = TextDrawCreate(437.0, 430.0, "www.FenixZone.com - Servidor RP 1");
    TextDrawBackgroundColor(NombreServidor, 255);
	TextDrawFont(NombreServidor, 1);
	TextDrawLetterSize(NombreServidor, 0.2899, 1.2);
	TextDrawColor(NombreServidor, -1);
	TextDrawSetOutline(NombreServidor, 0);
	TextDrawSetProportional(NombreServidor, 1);
	TextDrawSetShadow(NombreServidor, 1);
	TextDrawSetSelectable(NombreServidor, 0);
    return 1;
}
