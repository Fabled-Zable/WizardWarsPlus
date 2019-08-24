#include "Hitters.as"

void onTick( CBlob@ this )
{	
	//prevent leaving the map
	Vec2f pos = this.getPosition();
	if ( pos.y > (getMap().tilemapheight * getMap().tilesize) - 4.0f )
	{
		this.server_Hit(this, pos, Vec2f(0, 0), 1.0f, Hitters::fall);
	}
}