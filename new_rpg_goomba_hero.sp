#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define STOMP_SOUND "goomba/stomp.wav"
#define REBOUND_SOUND "goomba/rebound.wav"

new Goomba_SingleStomp[MAXPLAYERS+1] = 0;

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_StartTouch, OnStartTouch);
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
	HookEvent("player_death", EventDeath, EventHookMode_Pre);
}

public OnMapStart()
{
	PrecacheSound(STOMP_SOUND, true);
	PrecacheSound(REBOUND_SOUND, true);
	
	AddFileToDownloadsTable("sound/goomba/stomp.wav");
	AddFileToDownloadsTable("sound/goomba/rebound.wav");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_StartTouch, OnStartTouch);
}

public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "goomba_hero"))
	{
		TF2_AddCondition(client, TFCond:72, -1.0);
	}
	else
		if(TF2_IsPlayerInCondition(client, TFCond:72)) TF2_RemoveCondition(client, TFCond:72);
}


public EventDeath(Handle:event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(PlayerCheck(client) && PlayerCheck(attacker))
	{
		if(client != attacker)
		{
			if(GetAbility(attacker, "goomba_hero"))
			{
				new damageBits = GetEventInt(event, "damagebits");

				SetEventString(event, "weapon_logclassname", "goomba");
				SetEventString(event, "weapon", "taunt_scout");
				SetEventInt(event, "damagebits", damageBits |= DMG_ACID);
				SetEventInt(event, "customkill", 0);
				SetEventInt(event, "playerpenetratecount", 0);

				if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)) EmitSoundToClient(client, STOMP_SOUND, client);
			}
		}
	}
}

public Action:OnStartTouch(client, other)
{
    if(other > 0 && other <= MaxClients)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client) && GetAbility(client, "goomba_hero"))
        {
            decl Float:ClientPos[3];
            decl Float:VictimPos[3];
            decl Float:VictimVecMaxs[3];
            GetClientAbsOrigin(client, ClientPos);
            GetClientAbsOrigin(other, VictimPos);
            GetEntPropVector(other, Prop_Send, "m_vecMaxs", VictimVecMaxs);
            new Float:victimHeight = VictimVecMaxs[2];
            new Float:HeightDiff = ClientPos[2] - VictimPos[2];

            if(HeightDiff > victimHeight)
            {
                decl Float:vec[3];
                GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);

                if(vec[2] < 100.0 * -1.0)
                {
                    if(Goomba_SingleStomp[client] == 0)
                    {
                        if(GetClientTeam(client) != GetClientTeam(other))
                        {
							SDKHooks_TakeDamage(other, client, client, 999.0);
							EmitSoundToAll(REBOUND_SOUND, client);
							GOParticle(other);
							Goomba_SingleStomp[client] = 1;
							CreateTimer(0.5, SinglStompTimer, client);
                        }
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action:SinglStompTimer(Handle:timer, any:client) Goomba_SingleStomp[client] = 0;

stock GOParticle(client)
{
	new particle = AttachParticle(client, "mini_fireworks");
	if(particle != -1) CreateTimer(5.0, Timer_DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DeleteParticle(Handle:timer, any:ref)
{
    new particle = EntRefToEntIndex(ref);
    DeleteParticle(particle);
}


stock AttachParticle(entity, String:particleType[])
{
    new particle = CreateEntityByName("info_particle_system");
    decl String:tName[128];

    if(IsValidEdict(particle))
    {
        decl Float:pos[3] ;
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
        pos[2] += 74;
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

        Format(tName, sizeof(tName), "target%i", entity);

        DispatchKeyValue(entity, "targetname", tName);
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);

        SetVariantString(tName);
        SetVariantString("flag");
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");

        return particle;
    }
    return -1;
}

stock DeleteParticle(any:particle)
{
    if (particle > MaxClients && IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
            AcceptEntityInput(particle, "Kill");
        }
    }
}