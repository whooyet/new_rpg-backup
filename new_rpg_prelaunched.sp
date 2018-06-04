#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>
#include <sourcemod-misc>

ArrayList g_RocketOrigins[MAXPLAYERS + 1];
ArrayList g_RocketAngles[MAXPLAYERS + 1];
// Handle g_hSDKSetRocketDamage;

public void OnPluginStart()
{
	// StartPrepSDKCall(SDKCall_Entity);
	// PrepSDKCall_SetVirtual(130);
	// PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	// g_hSDKSetRocketDamage = EndPrepSDKCall();
	
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "prelaunched"))
	{	
		delete g_RocketOrigins[client];
		g_RocketOrigins[client] = new ArrayList(3);

		delete g_RocketAngles[client];
		g_RocketAngles[client] = new ArrayList(3);
	}
	else
	{
		if(g_RocketOrigins[client] != null)
		{
			delete g_RocketOrigins[client];
			delete g_RocketAngles[client];
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(AliveCheck(client) && GetAbility(client, "prelaunched"))
	{
		if (buttons & IN_ATTACK2)
		{
			if(g_RocketOrigins[client].Length > 0)
			{
				int active = GetActiveWeapon(client);

				for (int i = 0; i < g_RocketOrigins[client].Length; i++)
				{
					float vecOrigin[3];
					g_RocketOrigins[client].GetArray(i, vecOrigin, sizeof(vecOrigin));

					float vecAngles[3];
					g_RocketAngles[client].GetArray(i, vecAngles, sizeof(vecAngles));

					TF2_FireProjectile(vecOrigin, vecAngles, "tf_projectile_rocket", client, GetClientTeam(client), 1100.0, 90.0, false, active);
				}

				EmitSoundToClientSafe(client, "passtime/pass_to_me.wav");
				SpeakResponseConceptDelayed(client, "TLK_PLAYER_CHEERS", 0.3);

				g_RocketOrigins[client].Clear();
				g_RocketAngles[client].Clear();
			}
		}
	}
}


public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "tf_projectile_rocket")) SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawnPost);
}
public void OnRocketSpawnPost(int entity)
{
	int shooter = -1;
	if ((shooter = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity")) < 1 || !IsClientConnected(shooter) || !IsClientInGame(shooter)) return;

	if(!GetAbility(shooter, "prelaunched")) return;
	
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	g_RocketOrigins[shooter].PushArray(vecOrigin);

	float vecAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vecAngles);
	g_RocketAngles[shooter].PushArray(vecAngles);

	AcceptEntityInput(entity, "Kill");
	EmitSoundToClientSafe(shooter, "ui/hitsound_menu_note8.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, (100 + (g_RocketOrigins[shooter].Length * 3)));
}

int TF2_FireProjectile(float vPos[3], float vAng[3], const char[] classname = "tf_projectile_rocket", int iOwner = 0, int iTeam = 0, float flSpeed = 1100.0, float flDamage = 90.0, bool bCrit = false, int iWeapon = -1)
{
	int iRocket = CreateEntityByName(classname);

	if (IsValidEntity(iRocket))
	{
		float vVel[3];
		GetAngleVectors(vAng, vVel, NULL_VECTOR, NULL_VECTOR);

		ScaleVector(vVel, flSpeed);

		DispatchSpawn(iRocket);
		TeleportEntity(iRocket, vPos, vAng, vVel);

		// SDKCall(g_hSDKSetRocketDamage, iRocket, flDamage);
		
		if(StrEqual(classname, "tf_projectile_rocket")) SetEntDataFloat(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, flDamage, true);
		else SetEntPropFloat(iRocket, Prop_Send, "m_flDamage", flDamage);

		SetEntProp(iRocket, Prop_Send, "m_CollisionGroup", 0);
		SetEntProp(iRocket, Prop_Data, "m_takedamage", 0);
		SetEntProp(iRocket, Prop_Send, "m_bCritical", bCrit);
		SetEntProp(iRocket, Prop_Send, "m_nSkin", (iTeam - 2));
		SetEntProp(iRocket, Prop_Send, "m_iTeamNum", iTeam);
		SetEntPropVector(iRocket, Prop_Send, "m_vecMins", view_as<float>({0.0,0.0,0.0}));
		SetEntPropVector(iRocket, Prop_Send, "m_vecMaxs", view_as<float>({0.0,0.0,0.0}));

		SetVariantInt(iTeam);
		AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

		SetVariantInt(iTeam);
		AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0);

		if (iOwner > 0)
		{
			SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", iOwner);
		}

		if (iWeapon != -1)
		{
			SetEntPropEnt(iRocket, Prop_Send, "m_hOriginalLauncher", iWeapon); // GetEntPropEnt(baseRocket, Prop_Send, "m_hOriginalLauncher")
			SetEntPropEnt(iRocket, Prop_Send, "m_hLauncher", iWeapon); // GetEntPropEnt(baseRocket, Prop_Send, "m_hLauncher")
		}
	}

	return iRocket;
}
