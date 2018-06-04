#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public OnClientPutInServer(i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
    PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl", true);
    PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl", true);
    PrecacheModel("models/props_halloween/bumpercar_cage.mdl", true);

    /*PrecacheScriptSound("BumperCar.Spawn");
    PrecacheScriptSound("BumperCar.SpawnFromLava");
    PrecacheScriptSound("BumperCar.GoLoop");
    PrecacheScriptSound("BumperCar.Screech");
    PrecacheScriptSound("BumperCar.HitGhost");
    PrecacheScriptSound("BumperCar.Bump");
    PrecacheScriptSound("BumperCar.BumpIntoAir");
    PrecacheScriptSound("BumperCar.SpeedBoostStart");
    PrecacheScriptSound("BumperCar.SpeedBoostStop");
    PrecacheScriptSound("BumperCar.Jump");
    PrecacheScriptSound("BumperCar.JumpLand");*/
    //PrecacheScriptSound("sf14.Merasmus.DuckHunt.BonusDucks"); // BonusDi

    PrecacheSound(")weapons/bumper_car_accelerate.wav"); // From McKay again, I have no idea why the string has to be like this
    PrecacheSound(")weapons/bumper_car_decelerate.wav");
    PrecacheSound(")weapons/bumper_car_decelerate_quick.wav");
    PrecacheSound(")weapons/bumper_car_go_loop.wav");
    PrecacheSound(")weapons/bumper_car_hit_ball.wav");
    PrecacheSound(")weapons/bumper_car_hit_ghost.wav");
    PrecacheSound(")weapons/bumper_car_hit_hard.wav");
    PrecacheSound(")weapons/bumper_car_hit_into_air.wav");
    PrecacheSound(")weapons/bumper_car_jump.wav");
    PrecacheSound(")weapons/bumper_car_jump_land.wav");
    PrecacheSound(")weapons/bumper_car_screech.wav");
    PrecacheSound(")weapons/bumper_car_spawn.wav");
    PrecacheSound(")weapons/bumper_car_spawn_from_lava.wav");
    PrecacheSound(")weapons/bumper_car_speed_boost_start.wav");
    PrecacheSound(")weapons/bumper_car_speed_boost_stop.wav");
    
    decl String:szSnd[64];
    for(new i = 1; i <= 8; i++)
    {
        FormatEx(szSnd, sizeof(szSnd), "weapons/bumper_car_hit%i.wav", i);
        PrecacheSound(szSnd);
    }


    PrecacheParticleSystem("kartimpacttrail");
    PrecacheParticleSystem("kart_dust_trail_red");
    PrecacheParticleSystem("kart_dust_trail_blue");
    PrecacheParticleSystem("kartdamage_4");
}

public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "bumpercar"))
	{
		TF2_AddCondition(client, TFCond_HalloweenKart, -1.0);
		AnimateClientCar(client, true);
	}
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenKart)) TF2_RemoveCondition(client, TFCond_HalloweenKart);
	}
}

public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(AliveCheck(attacker) && AliveCheck(client))
	{
		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenKart) && GetAbility(client, "bumpercar"))
		{
			fDamage = 999.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock AnimateClientCar(iClient, bool bExit)
{
	static float flEnterDuration = 1.55;
	static float flExitDuration = 0.8;
	static iEnterSequences[] = {-1, 329, 294, 378, 290, 229, 280, 286, 293, 370};
	static iExitSequences[] = {-1, 334, 299, 383, 295, 234, 285, 291, 298, 375};
	new TFClassType:class = TF2_GetPlayerClass(iClient);
	if (bExit)
	{
		TF2_AddCondition(iClient, TFCond_HalloweenKart, flExitDuration - 0.12);
	}
	TF2_AddCondition(iClient, TFCond_HalloweenKartNoTurn, bExit ? flExitDuration : flEnterDuration);
	TE_Start("PlayerAnimEvent");
	TE_WriteNum("m_iPlayerIndex", iClient);
	TE_WriteNum("m_iEvent", 21);
	TE_WriteNum("m_nData", bExit ? iExitSequences[class] : iEnterSequences[class]);
	TE_SendToAll();
}
