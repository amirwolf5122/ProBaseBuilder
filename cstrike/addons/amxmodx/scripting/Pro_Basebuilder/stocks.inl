#include <amxmodx>
#include <fun>

stock barMenu(gText[], iLen, type, amount, const symbolOne[], const symbolTwo[]){
	new line = 0;
	for(new i = 0; i < type; i++) line += format(gText[line], iLen - line - 1, "\y%s\d", symbolOne);
	for(new i = 0; i < amount-type; i++)  line += format(gText[line], iLen - line - 1, "%s", symbolTwo);        
}

stock stringBuffer(flags, buffer[], size) {
	format(buffer, size, "");
	for (new i = 0; i < sizeof(lightCharacter); i++)
	if (flags & (1 << i)) format(buffer, size, "%c", lightCharacter[i]);
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id) {
	static tr;
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr);
	
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
		return true;
	return false;
}

stock setGlow(id, r,g,b,d){
	if (!is_user_alive(id)) return;
	
	set_rendering(id, kRenderFxGlowShell, 	r,g,b,	kRenderNormal, 	d);
}
public removeGlow(id){
	if (!is_user_alive(id)) return;
	
	setGlow(id,0,0,0,0);
}

stock formatm(const format[], any:...){
	static gText[256];
	vformat(gText, sizeof(gText) -1 , format, 2);
	return gText;
}

stock Remove(ent) 
{
	set_pev(ent, pev_solid, SOLID_NOT);
	set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW);
}
stock bool:hasOption(var, option){
	return !!(var&(1<<option));
}
stock addOption(&var, option){
	var |= (1<<option);
}
stock removeOption(&var, option){
	var &= ~(1<<option);
}

stock Create_TE_PLAYERATTACHMENT(id, entity, vOffset, iSprite, life){

	if(!id) message_begin(MSG_ALL, SVC_TEMPENTITY);
	else message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entity);			// entity
	write_coord(vOffset);			// vertical offset ( attachment origin.z = player origin.z + vertical offset )
	write_short(iSprite);			// model index
	write_short(life);			// (life * 10 )
	message_end();
}

public drawLine(id, Float:fOriginStart[3], Float:fOriginEnd[3],red, green, blue, life, width, noise){
	message_begin(MSG_ONE,SVC_TEMPENTITY, _, id) ;
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,fOriginStart[0]);
	engfunc(EngFunc_WriteCoord,fOriginStart[1]);
	engfunc(EngFunc_WriteCoord,fOriginStart[2]);
	engfunc(EngFunc_WriteCoord,fOriginEnd[0]);
	engfunc(EngFunc_WriteCoord,fOriginEnd[1]);
	engfunc(EngFunc_WriteCoord,fOriginEnd[2]);
	write_short(sprite_bluez);
	write_byte(0);
	write_byte(25);
	write_byte(life);
	write_byte(width);
	write_byte(noise);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(255);
	write_byte(255);
	message_end();
}