#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

float flDeathPos[MAXPLAYERS+1][3];
float flDeathAng[MAXPLAYERS+1][3];

new Float:EffectCoolTime[MAXPLAYERS+1];
new Float:ReviveCoolTime[MAXPLAYERS+1];

new plasma;

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void OnMapStart()
{
	plasma = PrecacheModel("materials/sprites/plasma.vmt");
}

public  void OnClientPutInServer(client)
{
	flDeathPos[client][0] = 0.0;
	flDeathPos[client][1] = 0.0;
	flDeathPos[client][2] = 0.0;
	
	flDeathAng[client][0] = 0.0;
	flDeathAng[client][1] = 0.0;
	flDeathAng[client][2] = 0.0;
	
	EffectCoolTime[client] = 0.0;
	ReviveCoolTime[client] = 0.0;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client > 0 && client <= MaxClients)
	{
		GetClientAbsOrigin(client, flDeathPos[client]);
		GetClientEyeAngles(client, flDeathAng[client]);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(AliveCheck(client) && GetAbility(client, "revive"))
	{
		if(CheckEffectCoolTime(client, 1.0))
		{
			decl Float:white[3];
			GetClientAbsOrigin(client, white);
			TE_SetupBeamRingPoint(white, 10.0, 500.0, plasma, plasma, 0, 1, 0.6, 10.0, 0.5, {255, 255, 255, 255}, 1, 0);
			TE_SendToAll();
			EffectCoolTime[client] = GetEngineTime();
		}
	}
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char strCmd[256];
	kv.GetSectionName(strCmd, 256);
	
	if(StrEqual(strCmd, "+use_action_slot_item_server") && IsPlayerAlive(client) && GetAbility(client, "revive"))
	{
		if(CheckReviveCoolTime(client, 20.0))
		{
			float flPos[3];
			GetClientAbsOrigin(client, flPos);
			SpawnThing("tf_zombie", client, GetClientTeam(client));
				
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(client))
				{
					float flDistance = GetVectorDistance(flPos, flDeathPos[i]);
					if(flDistance <= 300.0)
					{
						SetClientExp(client, 2, 1);
						
						TF2_RespawnPlayer(i);
								
						float flTimeImmunity = 3.0;
								
						TF2_AddCondition(i, TFCond_UberchargedCanteen, flTimeImmunity);
						TeleportEntity(i, flDeathPos[i], flDeathAng[i], NULL_VECTOR);
								
						Particle_Create(i, "teleporter_mvm_bot_persist", 0.0, flTimeImmunity);
								
						SetVariantString("randomnum:30");
						AcceptEntityInput(i, "AddContext");
		
						SetVariantString("TLK_RESURRECTED");
						AcceptEntityInput(i, "SpeakResponseConcept");
		
						AcceptEntityInput(i, "ClearContext");
					}
				}
			}
			ReviveCoolTime[client] = GetEngineTime();
		}
		else PrintToChat(client, "\x0320 초를 기다려야합니다. (%.1f 초)", GetEngineTime() - ReviveCoolTime[client]);
	}
	return Plugin_Continue;
} 

stock int Particle_Create(int iEntity, const char[] strParticleEffect, float flOffsetZ = 0.0, float flTimeExpire = 0.0, bool bParent = false)
{
	int iParticle = CreateEntityByName("info_particle_system");
	
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		float flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
	
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		if(bParent)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity);
		}
		
		if(flTimeExpire > 0.0)
		{
			char addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", flTimeExpire);
			SetVariantString(addoutput);
			AcceptEntityInput(iParticle, "AddOutput");
			AcceptEntityInput(iParticle, "FireUser1");
		}
		
		return iParticle;
	}
	
	return 0;
}

stock SpawnThing( String:entity[32] = "", victim, team = -1 )
{
	new ent = CreateEntityByName( entity ); 
	if ( IsValidEntity( ent ) )
	{
		DispatchSpawn( ent ); 
    
		if ( StrEqual( entity, "tf_zombie_spawner" ) ) {
			SetEntProp( ent, Prop_Data, "m_nSkeletonType", 1 ); 
			AcceptEntityInput( ent, "Enable" ); 
		}
		else if ( StrEqual( entity, "tf_zombie" ) ) {
			if ( team == 2 ) DispatchKeyValue( ent, "skin", "0" ); 
			else if ( team == 3 ) DispatchKeyValue( ent, "skin", "1" ); 
			SetEntProp( ent, Prop_Send, "m_iTeamNum", team ); 
		}
		else if ( StrEqual( entity, "eyeball_boss" ) ) SetEntProp( ent, Prop_Data, "m_iTeamNum", 5 ); 
		
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", victim);

		new Float:POSa[3], Float:POSe[3]; 
		GetClientAbsOrigin( victim, POSa ); 
		GetClientEyeAngles( victim, POSe ); 
		TeleportEntity( ent, POSa, POSe, NULL_VECTOR ); 
		
		CreateTimer(10.0, m_tSpawnSkeletonOnKill_TimerDuration, ent ); 
	}
}

public Action:m_tSpawnSkeletonOnKill_TimerDuration( Handle:timer, any:m_iEnt )
{
	if ( IsValidEntity( m_iEnt ) ) AcceptEntityInput( m_iEnt, "Kill" );
}

stock bool:CheckEffectCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - EffectCoolTime[iClient] >= fTime) return true;
	else return false;
}


stock bool:CheckReviveCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - ReviveCoolTime[iClient] >= fTime) return true;
	else return false;
}

