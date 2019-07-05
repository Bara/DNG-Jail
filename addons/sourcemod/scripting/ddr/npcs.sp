// Location of NPCs
float g_fNpcDj[3];

// Enitys of NPCs
int g_iNpcDj;

public Action Timer_CheckNPCs(Handle Timer, any data)
{
	CheckNPCRange();
	return Plugin_Continue;
}

void PreCacheNPCModels()
{
	PrecacheModel(NPC_MODEL_DJ);
}

void InitNPCs()
{
	int entindex = -1;
	char stringname[20];
	
	while ((entindex = FindEntityByClassname(entindex, "info_teleport_destination")) != -1)
	{
		GetEntPropString(entindex, Prop_Data, "m_iName", stringname, sizeof(stringname));

		if (StrEqual(stringname, "npc_dj"))
		{
			GetEntPropVector(entindex, Prop_Send, "m_vecOrigin", g_fNpcDj);
			AcceptEntityInput(entindex, "Kill");
			g_iNpcDj = SpawnNPC("NPC_DJ", NPC_MODEL_DJ, "Wave", g_fNpcDj);
		}
	}
}

int SpawnNPC(char name[64], char model[512], char defAni[64], float pos[3], float angle[3] = NULL_VECTOR)
{
	int entity = CreateEntityByName("prop_dynamic");
	
	DispatchKeyValue(entity, "targetname", name);
	DispatchKeyValue(entity, "model", model);
	DispatchKeyValue(entity, "DefaultAnim", defAni);
	DispatchKeyValue(entity, "solid", "2"); //Use bounding box
	
	DispatchSpawn(entity);
	
	TeleportEntity(entity, pos, angle, NULL_VECTOR);
	
	return entity;
}

public Action NPC_Touch(int npc, int client)
{
	if (Hide_IsActive() || Zombie_IsActive())
	{
		return;
	}

	if (!IsClientValid(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if (npc == g_iTriggerDJ)
	{
		NPCTouchDj(client);
	}
}

void NPCTouchDj(int client)
{
	OpenSongsList(client);
}

void CheckNPCRange()
{
	if (IsValidEntity(g_iNpcDj))
	{
		LoopClients(j)
		{
			if (!IsClientValid(j))
				continue;
			
			if (!IsPlayerAlive(j))
				continue;
			
			if (Entity_InRange(g_iNpcDj, j, 128.0))
			{
				NPC_LookAtClient(g_iNpcDj, j);
				break;
			}
		}
	}
}

void NPC_LookAtClient(int npc, int client)
{
	float angle[3], vec[3], vecClient[3], vecNPC[3];
	
	GetEntPropVector(npc, Prop_Send, "m_vecOrigin", vecNPC);
	GetClientAbsOrigin(client, vecClient);
	
	MakeVectorFromPoints(vecNPC, vecClient, vec);
	
	GetVectorAngles(vec, angle);
	angle[0] = 0.0;
	angle[2] = 0.0;
	
	TeleportEntity(npc, NULL_VECTOR, angle, NULL_VECTOR);
} 

stock bool Entity_InRange(int entity, int target, float distance)
{
	if (Entity_GetDistance(entity, target) > distance) {
		return false;
	}

	return true;
}

float Entity_GetDistance(int  entity, int  target)
{
	float targetVec[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetVec);

	return Entity_GetDistanceOrigin(entity, targetVec);
}

float Entity_GetDistanceOrigin(int  entity, const float vec[3])
{
	float entityVec[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityVec);

	return GetVectorDistance(entityVec, vec);
}
