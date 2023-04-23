enum ( += 100){
	TASK_AFK
};

public checkCamping(id){	
	id -= TASK_AFK;
	
	if( !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)){
		if( task_exists(id+TASK_AFK) )
			remove_task(id + TASK_AFK);
		return PLUGIN_CONTINUE;
	}
		
	if(userAfkValue[id] >= 100.00 ){
		print_color(0, "^x03Player^x04 %s ^x03was kicked due to AFK", userName[id]);
		server_cmd("kick #%d ^"You were kicked out due to AFK!!^"", get_user_userid(id));
		
		//logBB(id, LOG_AFK, "kick", "zostal wyrzucony za AFK'a");
		
		return PLUGIN_CONTINUE;
	}
	static Float:fVelocity[3];
	pev(id,pev_velocity,fVelocity);
	static button;
	button = get_user_button(id);	
	
	if(button != userButtonAfk[id]){
		userButtonAfk[id] = button;
		if(fVelocity[0] != 0|| fVelocity[1] != 0 || fVelocity[2] != 0 )
			userAfkValue[id] -= 0.30;
	} else  userAfkValue[id] += 0.05;
	
	userAfkValue[id] = floatclamp(userAfkValue[id], 0.00, 100.00);

	set_task(0.2, "checkCamping", id + TASK_AFK);
	return PLUGIN_CONTINUE;
}