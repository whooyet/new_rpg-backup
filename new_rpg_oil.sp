#include <sdktools>
#include <sdkhooks>
#include <new_rpg>

#define MODEL_DEFAULTPHYSICS "models/props_2fort/coffeepot.mdl"
#define MODEL_FIRELEAK                  "models/props_farm/haypile001.mdl"

#define SOUND_FIRELEAK_OIL "physics/flesh/flesh_bloody_impact_hard1.wav"
#define PARTICLE_FIRE "buildingdamage_dispenser_fire1"
#define PARTICLE_AREA_FIRE_BLUE "player_glowblue"

#define    MAX_EDICT_BITS    11
#define    MAX_EDICTS        (1 << MAX_EDICT_BITS)

new Float:CoolTime[MAXPLAYERS+1];
new g_iOilLeakDamageOwner[MAXPLAYERS+1] = 0;
new g_iOilLeakDamage[MAXPLAYERS+1] = 0;

new Handle:g_hOilLeakEntities = INVALID_HANDLE;
new g_iOilLeakStatus[MAX_EDICTS + 1] = 0;

public OnPluginStart()
{
	g_hOilLeakEntities = CreateArray();
}

public OnClientPutInServer(i) CoolTime[i] = 0.0;


public OnMapStart()
{
	PrecacheModel(MODEL_DEFAULTPHYSICS, true);
	PrecacheModel(MODEL_FIRELEAK, true);
	
	PrecacheParticleSystem("peejar_trail_blu"); 
	PrecacheParticleSystem("peejar_trail_red");
	PrecacheParticleSystem(PARTICLE_FIRE);
	PrecacheParticleSystem(PARTICLE_AREA_FIRE_BLUE);
	
	PrecacheSound(SOUND_FIRELEAK_OIL, true);
}


public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
{
	if(AliveCheck(client) && GetAbility(client, "oil"))
	{
		if(iButtons & IN_ATTACK2)
		{
			if(CheckCoolTime(client, 0.75))
			{
				Attribute_1056_OilLeak(client);
				CoolTime[client] = GetEngineTime();
			}
		}
		PrintToChatAll("%d", GetFlamethrowerStrength(client));
		
		new attacker = g_iOilLeakDamageOwner[client];
		if(PlayerCheck(attacker))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);
			
			SDKHooks_TakeDamage(attacker, client, client, 2 + (g_iOilLeakDamage[client] * 1.5), (1 << 24), weapon);
			
			g_iOilLeakDamage[client] += 2;
		} else
		{
			g_iOilLeakDamage[client] -= 4;
			if(g_iOilLeakDamage[client] < 0) g_iOilLeakDamage[client] = 0;
		}
		g_iOilLeakDamageOwner[client] = -1;
	}
}

stock Attribute_1056_OilLeak(client)
{
	EmitSoundToAll(SOUND_FIRELEAK_OIL, client, SNDCHAN_WEAPON, _, SND_CHANGEVOL|SND_CHANGEPITCH, 1.0, GetRandomInt(60, 140));
	
	if(g_hOilLeakEntities == INVALID_HANDLE) g_hOilLeakEntities = CreateArray();
	
	new entity = CreateEntityByName("prop_physics_override");
	if(IsValidEdict(entity))
	{
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntityModel(entity, MODEL_DEFAULTPHYSICS);
		DispatchSpawn(entity);
		
		AcceptEntityInput(entity, "DisableCollision");
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, _, _, _, 0);
		
		decl String:strName[10];
		Format(strName, sizeof(strName), "tf2leak");
		DispatchKeyValue(entity, "targetname", strName);
		
		decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3];
		GetClientEyePosition(client, fOrigin);
		GetClientEyeAngles(client, fAngles);
		AnglesToVelocity(fAngles, fVelocity, 600.0);
		
		TeleportEntity(entity, fOrigin, fAngles, fVelocity);
		
		new team = GetClientTeam(client);
		
		if(team == 3)
		{
			AttachParticle(entity, "peejar_trail_blu");
			AttachParticle(entity, "peejar_trail_blu");
			AttachParticle(entity, "peejar_trail_blu");
			AttachParticle(entity, "peejar_trail_blu");
			AttachParticle(entity, "peejar_trail_blu");
			AttachParticle(entity, "peejar_trail_blu");
			AttachParticle(entity, "peejar_trail_blu");
		} else if(team == 2)
		{
			AttachParticle(entity, "peejar_trail_red");
			AttachParticle(entity, "peejar_trail_red");
			AttachParticle(entity, "peejar_trail_red");
			AttachParticle(entity, "peejar_trail_red");
			AttachParticle(entity, "peejar_trail_red");
			AttachParticle(entity, "peejar_trail_red");
			AttachParticle(entity, "peejar_trail_red");
		}
		
		g_iOilLeakStatus[entity] = 0;
		CreateTimer(0.1, ThinkHook, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		char addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::10:1");
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

	}
}

public Action:ThinkHook(Handle:hTimer, any:iEntityRef)
{
	new entity = EntRefToEntIndex(iEntityRef);
	if(!IsValidEntity(entity)) return Plugin_Stop;
	new iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!PlayerCheck(iOwner)) return Plugin_Stop;
	if(!GetAbility(iOwner, "oil")) return Plugin_Stop;
	
	if(GetFlamethrowerStrength(iOwner) >= 2)
	{
		PrintToChatAll("a");
		decl Float:vOrigin2[3];
		Entity_GetAbsOrigin(iOwner, vOrigin2);
		Attribute_1056_IgniteLeak(entity, vOrigin2);
	}
	
	Attribute_1056_OilThink(entity);
	return Plugin_Continue;
}
	
stock Attribute_1056_OilThink(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!PlayerCheck(owner)) return -1;

	decl Float:vOrigin[3];
	Entity_GetAbsOrigin(entity, vOrigin);
	
	if(g_iOilLeakStatus[entity] == 0)
	{
		new Float:vAngleDown[3];
		vAngleDown[0] = 90.0;
		new Handle:hTrace = TR_TraceRayFilterEx(vOrigin, vAngleDown, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
		if(TR_DidHit(hTrace))
		{
			decl Float:vEnd[3];
			TR_GetEndPosition(vEnd, hTrace);
			if(GetVectorDistance(vEnd, vOrigin) / 50.0 <= 0.4)
			{
				new Float:vStop[3];
				SetEntityMoveType(entity, MOVETYPE_NONE);
				TeleportEntity(entity, vEnd, NULL_VECTOR, vStop);
				
				SetEntityRenderColor(entity, _, _, _, 255);
				SetEntityRenderMode(entity, RENDER_NONE);
				SetEntityModel(entity, MODEL_FIRELEAK);
				g_iOilLeakStatus[entity] = 1;
				
				PrintToChatAll("%d", GetFlamethrowerStrength(owner));

			}
		}
		CloseHandle(hTrace);
	}
	else if(g_iOilLeakStatus[entity] == 2)
	{
		for(new client = 0; client <= MaxClients; client++)
		{
			if(AliveCheck(client) && GetClientTeam(client) != GetClientTeam(owner) || client == owner)
			{
				if(Entity_GetDistanceOrigin(client, vOrigin) / 50.0 <= 1.5)
				{
					g_iOilLeakDamageOwner[owner] = client;
				}
			}
		}
	}
	
	return owner;
}

stock Attribute_1056_IgniteLeak(ent, Float:vPos[3])
{
	PrintToChatAll("A");
	decl Float:vOrigin[3];
	decl Float:vFire[3];

	Entity_GetAbsOrigin(ent, vOrigin);
	if(g_iOilLeakStatus[ent] == 1 && GetVectorDistance(vOrigin, vPos) / 50.0 <= 3.0)
	{
		PrintToChatAll("A");
		g_iOilLeakStatus[ent] = 2;
 
		vFire[2] = 5.0;
				
		vFire[0] = 22.0;
		vFire[1] = 22.0;
		AttachParticle(ent, PARTICLE_FIRE, _, vFire);
				
		vFire[0] = 22.0;
		vFire[1] = -22.0;
		AttachParticle(ent, PARTICLE_FIRE, _, vFire);
				
		vFire[0] = -22.0;
		vFire[1] = 22.0;
		AttachParticle(ent, PARTICLE_FIRE, _, vFire);
				
		vFire[0] = -22.0;
		vFire[1] = -22.0;
		AttachParticle(ent, PARTICLE_FIRE, _, vFire);
				
		vFire[0] = 0.0;
		vFire[1] = 0.0;
		AttachParticle(ent, PARTICLE_FIRE, _, vFire);
				
		new String:strParticle[16];
		if(GetClientTeam(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")) == 3) Format(strParticle, sizeof(strParticle), "%s", PARTICLE_AREA_FIRE_BLUE);
		if(!StrEqual(strParticle, "")) AttachParticle(ent, strParticle, _, vFire);
	}
}

public bool:TraceRayDontHitPlayers(entity, mask)
{
	if(AliveCheck(entity)) return false;
	
	return true;
}


stock AnglesToVelocity(Float:fAngle[3], Float:fVelocity[3], Float:fSpeed = 1.0)
{
	fVelocity[0] = Cosine(DegToRad(fAngle[1]));
	fVelocity[1] = Sine(DegToRad(fAngle[1]));
	fVelocity[2] = Sine(DegToRad(fAngle[0])) * -1.0;
	
	NormalizeVector(fVelocity, fVelocity);
	
	ScaleVector(fVelocity, fSpeed);
}

stock AttachParticle(ent, String:particleType[], Float:time = 0.0, Float:addPos[3] = NULL_VECTOR, Float:addAngle[3] = NULL_VECTOR, bool:bShow = true, String:strVariant[] = "", bool:bMaintain = false)
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		decl String:tName[32];
		Entity_GetAbsOrigin(ent, pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
		if(bShow)
		{
			SetVariantString(tName);
		} else
		{
			SetVariantString("!activator");
		}
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		if(!StrEqual(strVariant, ""))
		{
			SetVariantString(strVariant);
			if(bMaintain) AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", ent, particle, 0);
			else AcceptEntityInput(particle, "SetParentAttachment", ent, particle, 0);
		}
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if(time > 0.0) CreateTimer(time, RemoveParticle, particle);
	}
	else LogError("AttachParticle: could not create info_particle_system");
	return particle;
}

public Action:RemoveParticle(Handle:timer, any:particle)
{
	if(particle >= 0 && IsValidEntity(particle))
	{
		new String:classname[32];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "Stop");
			AcceptEntityInput(particle, "Kill");
			AcceptEntityInput(particle, "Deactivate");
			particle = -1;
		}
	}
}

stock GetFlamethrowerStrength(client)
{
	if(!AliveCheck(client)) return 0;
	if(!GetAbility(client, "oil")) return 0;
	new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsClassname(entity, "tf_weapon_flamethrower")) return 0;
	
	new strength = GetEntProp(entity, Prop_Send, "m_iActiveFlames");
	return strength;
}

stock bool:IsClassname(entity, String:strClassname[])
{
	if(entity <= 0) return false;
	if(!IsValidEdict(entity)) return false;
	
	decl String:strClassname2[32];
	GetEdictClassname(entity, strClassname2, sizeof(strClassname2));
	if(!StrEqual(strClassname, strClassname2, false)) return false;
	
	return true;
}

stock Float:Entity_GetDistanceOrigin(entity, const Float:vec[3])
{
    new Float:entityVec[3];
    Entity_GetAbsOrigin(entity, entityVec);
    
    return GetVectorDistance(entityVec, vec);
}


stock Entity_GetAbsOrigin(entity, Float:vec[3])
{
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

stock bool:CheckCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - CoolTime[iClient] >= fTime) return true;
	else return false;
}
