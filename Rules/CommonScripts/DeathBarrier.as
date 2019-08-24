// red barrier of death around maps

const f32 BARRIER_PERCENT = 0.175f;
bool barrier_set = false;

bool shouldBarrier( CRules@ this )
{
	return true;
}

void onTick( CRules@ this )
{
	if ( shouldBarrier(this) )
	{
		if(!barrier_set)
		{
			barrier_set = true;
			addBarrier();
		}
		
		f32 top_x1, top_x2, top_y1, top_y2;
		getTopBarrierPositions( top_x1, top_x2, top_y1, top_y2 );
		
		f32 left_x1, left_x2, left_y1, left_y2;
		getLeftBarrierPositions( left_x1, left_x2, left_y1, left_y2 );
		
		f32 right_x1, right_x2, right_y1, right_y2;
		getRightBarrierPositions( right_x1, right_x2, right_y1, right_y2 );

		CBlob@[] blobsInBox;
		if (getMap().getBlobsInBox( Vec2f(top_x1,top_y1), Vec2f(top_x2,top_y2), @blobsInBox ))
		{
			for (uint i = 0; i < blobsInBox.length; i++)
			{
				CBlob @b = blobsInBox[i];
				if (b.getPlayer() !is null)
				{
					Vec2f pos = b.getPosition();
					
					f32 f = b.getMass() * 2.0f;
					
					b.server_SetHealth(-1.0f);
					b.server_Die();
				}
			}
		}
		if (getMap().getBlobsInBox( Vec2f(left_x1,left_y1), Vec2f(left_x2,left_y2), @blobsInBox ))
		{
			for (uint i = 0; i < blobsInBox.length; i++)
			{
				CBlob @b = blobsInBox[i];
				if (b.getPlayer() !is null)
				{
					Vec2f pos = b.getPosition();
					
					f32 f = b.getMass() * 2.0f;
					
				}
			}
		}
		if (getMap().getBlobsInBox( Vec2f(right_x1,right_y1), Vec2f(right_x2,right_y2), @blobsInBox ))
		{
			for (uint i = 0; i < blobsInBox.length; i++)
			{
				CBlob @b = blobsInBox[i];
				if (b.getPlayer() !is null)
				{
					Vec2f pos = b.getPosition();
					
					f32 f = b.getMass() * 2.0f;
					
					b.server_SetHealth(-1.0f);
					b.server_Die();
				}
			}
		}
	}
	else
	{
		if(barrier_set)
		{
			removeBarrier();
			barrier_set = false;
		}
	}
}

void onRestart(CRules@ this)
{
	barrier_set = false;
}


void onRender( CRules@ this )
{
	if (shouldBarrier( this ))
	{
		f32 top_x1, top_x2, top_y1, top_y2;
		getTopBarrierPositions( top_x1, top_x2, top_y1, top_y2 );
		GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(Vec2f( top_x1, top_y1 )), getDriver().getScreenPosFromWorldPos(Vec2f( top_x2, top_y2)), SColor( 100, 235, 0, 0 ) );
		
		f32 left_x1, left_x2, left_y1, left_y2;
		getLeftBarrierPositions( left_x1, left_x2, left_y1, left_y2 );
		GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(Vec2f( left_x1, left_y1 )), getDriver().getScreenPosFromWorldPos(Vec2f( left_x2, left_y2)), SColor( 100, 235, 0, 0 ) ); 
		
		f32 right_x1, right_x2, right_y1, right_y2;
		getRightBarrierPositions( right_x1, right_x2, right_y1, right_y2 );
		GUI::DrawRectangle( getDriver().getScreenPosFromWorldPos(Vec2f( right_x1, right_y1 )), getDriver().getScreenPosFromWorldPos(Vec2f( right_x2, right_y2)), SColor( 100, 235, 0, 0 ) ); 
	}
}

void getTopBarrierPositions( f32 &out top_x1, f32 &out top_x2, f32 &out top_y1, f32 &out top_y2 )
{
	CMap@ map = getMap();
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	top_x1 = 0;
	top_x2 = mapWidth - 1*map.tilesize;
	top_y1 = 0;
	top_y2 = barrierWidth;
}

void getLeftBarrierPositions( f32 &out left_x1, f32 &out left_x2, f32 &out left_y1, f32 &out left_y2 )
{
	CMap@ map = getMap();
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	left_x1 = 0;
	left_x2 = barrierWidth;
	left_y1 = 0;
	left_y2 = mapHeight;
}

void getRightBarrierPositions( f32 &out right_x1, f32 &out right_x2, f32 &out right_y1, f32 &out right_y2 )
{
	CMap@ map = getMap();
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapHeight = map.tilemapheight * map.tilesize;
	const f32 barrierWidth = 1*map.tilesize;
	
	right_x1 = mapWidth - barrierWidth - 1*map.tilesize;
	right_x2 = mapWidth - 1*map.tilesize;
	right_y1 = 0;
	right_y2 = mapHeight;
}

/**
 * Adding the barrier sector to the map
 */

void addBarrier()
{
	CMap@ map = getMap();
	
	f32 top_x1, top_x2, top_y1, top_y2;
	getTopBarrierPositions( top_x1, top_x2, top_y1, top_y2 );	
	Vec2f top_ul(top_x1,top_y1);
	Vec2f top_lr(top_x2,top_y2);	
	if(map.getSectorAtPosition( (top_ul + top_lr) * 0.5, "barrier" ) is null)
		map.server_AddSector( Vec2f(top_x1, top_y1), Vec2f(top_x2, top_y2), "barrier" );
	
	f32 left_x1, left_x2, left_y1, left_y2;
	getLeftBarrierPositions( left_x1, left_x2, left_y1, left_y2 );	
	Vec2f left_ul(left_x1,left_y1);
	Vec2f left_lr(left_x2,left_y2);	
	if(map.getSectorAtPosition( (left_ul + left_lr) * 0.5, "barrier" ) is null)
		map.server_AddSector( Vec2f(left_x1, left_y1), Vec2f(left_x2, left_y2), "barrier" );
	
	f32 right_x1, right_x2, right_y1, right_y2;
	getRightBarrierPositions( right_x1, right_x2, right_y1, right_y2 );	
	Vec2f right_ul(right_x1,right_y1);
	Vec2f right_lr(right_x2,right_y2);	
	if(map.getSectorAtPosition( (right_ul + right_lr) * 0.5, "barrier" ) is null)
		map.server_AddSector( Vec2f(right_x1, right_y1), Vec2f(right_x2, right_y2), "barrier" );
}

/**
 * Removing the barrier sector from the map
 */

void removeBarrier()
{
	CMap@ map = getMap();
	
	f32 top_x1, top_x2, top_y1, top_y2;
	getTopBarrierPositions( top_x1, top_x2, top_y1, top_y2 );
	
	Vec2f ul(top_x1,top_y1);
	Vec2f lr(top_x2,top_y2);
	
	map.RemoveSectorsAtPosition( (ul + lr) * 0.5 , "barrier" );
}

void onPlayerDie( CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData )
{
	if (victim.getBlob() !is null)
	{
		CBlob@ b = victim.getBlob();

		SetScreenFlash( 200, 250, 250, 250 );
		ShakeScreen( 800, 100, b.getPosition() );
		if (getNet().isClient())
			Sound::Play("/Eliminated.ogg");
						
			ParticleAnimated( "Entities/Effects/Sprites/Swirl.png",
				b.getPosition(),
				Vec2f(0.0,0.0f),
				1.0f, 1.0f, 
				3, 
				0.0f, true );
	}
}
