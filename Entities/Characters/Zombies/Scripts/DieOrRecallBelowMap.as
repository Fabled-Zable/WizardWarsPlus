#include "Hitters.as"
void onInit( CBlob@ this )
{	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath);
}

void onTick( CBlob@ this )
{	
	//prevent leaving the map
	Vec2f pos = this.getPosition();
	if ( pos.y > (getMap().tilemapheight * getMap().tilesize) - 4.0f )
	{
		bool die = true;
	
		CPlayer@ ownerPlayer = this.getDamageOwnerPlayer();
		if ( ownerPlayer !is null )
		{
			CBlob@ ownerBlob = ownerPlayer.getBlob();
			if ( ownerBlob !is null && !ownerBlob.hasTag("dead") && this.getPlayer() is null )
			{
				Vec2f ownerPos = ownerBlob.getPosition();
				//this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 2.0f, Hitters::fire, true);
				this.setPosition( ownerPos );
				this.setVelocity( Vec2f(0,0) );
				ParticleZombieLightning( ownerPos );
				
				die = false;
			}
		}
		else
		{
			die = true;
		}
		
		if ( die == true)
			this.server_Die();
	}

	//prevent zombie spam a bit
	if(getPlayersCount() < 2 || this.getDamageOwnerPlayer() is null)
	{
		this.server_Die();
	}
}