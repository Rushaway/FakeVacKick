#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool isBeingKicked;

public Plugin myinfo =
{
	name = "Fake VAC kick",
	author = "Invex | Byte, .Rushaway",
	description = "Kick a player from server with fake VAC notice",
	version = "2.0",
	url = ""
}

public void OnPluginStart()
{
	RegAdminCmd("sm_fakevackick", Command_FakeVACKick, ADMFLAG_KICK, "sm_fakevackick <#userid|name>");
	HookEvent( "player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre );

	isBeingKicked = false;
}

public Action Command_FakeVACKick(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakevackick <#userid|name>");
		return Plugin_Handled;
	}

	char Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	char arg[65];
	int len = BreakString(Arguments, arg, sizeof(arg));

	if (len == -1) // Safely null terminate
	{
		len = 0;
		Arguments[0] = '\0';
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
		arg,
		client, 
		target_list, 
		MAXPLAYERS, 
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml)) > 0)
	{
		isBeingKicked = true; //Set bool

		char reason[64];
		Format(reason, sizeof(reason), Arguments[len]);

		PrintToChatAll("\x02Player %s left the game (VAC banned from secure server)", target_name);

		int kick_self = 0;

		for (int i = 0; i < target_count; i++)
		{
			if (target_list[i] == client) // Kick everyone else first 
				kick_self = client;
			else
				PerformKick(target_list[i]);
		}

		if (kick_self)
			PerformKick(client);
	}
	else
		ReplyToTargetError(client, target_count);

	return Plugin_Handled;
}

void PerformKick(int target) //Kick client showing VAC ban message
{
	KickClient(target, "%s", "You have been VAC banned");
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) //Block the regular player has left message
{
	if (isBeingKicked)  // Overwrite Disconnection Message
	{
		SetEventBroadcast(event, true);
		isBeingKicked = false;
	}

	return Plugin_Continue;
}