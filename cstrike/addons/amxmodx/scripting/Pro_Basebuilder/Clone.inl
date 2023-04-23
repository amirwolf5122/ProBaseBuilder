
stock getRotateBlock(ent, type)	return pev(ent, pev_team) != type;

public impulseClone(id){
	if( !serverLetClone ){
		return PLUGIN_CONTINUE
	}
	if( isPlayer(g_iOwnedEnt[id]) ){
		return PLUGIN_CONTINUE
	}
	if( userClaimed[id]>=limitBlocks ){
		print_color(id, "%s ^x01You have already reached your block limit!", MODNAME);
		return PLUGIN_CONTINUE
	}
	
	userClone[id] = !userClone[id];
	return PLUGIN_HANDLED;
}

public createClone(entView){
	new ent=create_entity("func_wall")
	if( !pev_valid(ent) ){
		return -1;
	}
	new szClassName[16]
	pev(entView, pev_classname, szClassName, sizeof(szClassName))
	set_pev(ent,pev_classname, szClassName)
	
	pev(entView, pev_model, szClassName, sizeof(szClassName))
	set_pev(ent,pev_model, szClassName)
	
	
	set_pev(ent,pev_solid, pev(entView, pev_solid))
	set_pev(ent,pev_movetype, pev(entView, pev_movetype))
	set_pev(ent,pev_modelindex, pev(entView, pev_modelindex))
	set_pev(ent,pev_body, pev(entView, pev_body))
	set_pev(ent,pev_skin, pev(entView, pev_skin))
	set_pev(ent,pev_flags, pev(entView, pev_flags))
	set_pev(ent,pev_spawnflags, pev(entView, pev_spawnflags))
	set_pev(ent,pev_team, pev(entView, pev_team))
	
	new Float:fFloat[3]
	pev(entView, pev_mins, fFloat)
	set_pev(ent, pev_mins, fFloat)
	
	pev(entView, pev_maxs, fFloat)
	set_pev(ent, pev_maxs, fFloat)	
	
	pev(entView, pev_vuser3, fFloat)
	set_pev(ent, pev_vuser3, fFloat)
	
	pev(entView, pev_vuser1, fFloat)
	set_pev(ent, pev_vuser1, fFloat)	
	
	pev(entView, pev_origin, fFloat)
	entity_set_origin(ent, fFloat)
	set_pev(ent, pev_iuser4, 3)
	
	return ent;
		
}


public makeBarrierNoSolid(){
	if (g_iEntBarrier){
		set_pev(g_iEntBarrier,pev_solid,SOLID_NOT);
		set_pev(g_iEntBarrier,pev_rendercolor, Float:{64.0, 255.0, 64.0} );
		set_pev(g_iEntBarrier,pev_renderamt, Float:{60.0} );
	}
}