//brain

#define SERVER_ONLY

#include "BrainCommon.as"
#include "PressOldKeys.as";
#include "AnimalConsts.as";

void onInit( CBrain@ this )
{
	CBlob @blob = this.getBlob();
	blob.set_u8( delay_property , 5+XORRandom(5));
	blob.set_u8(state_property, MODE_IDLE);

	if (!blob.exists(terr_rad_property)) 
	{
		blob.set_f32(terr_rad_property, 32.0f);
	}

	if (!blob.exists(target_searchrad_property))
	{
		blob.set_f32(target_searchrad_property, 1028.0f);
	}

	if (!blob.exists(personality_property))
	{
		blob.set_u8(personality_property,0);
	}

	if (!blob.exists(target_lose_random))
	{
		blob.set_u8(target_lose_random,14);
	}

	if (!blob.exists("random move freq"))
	{
		blob.set_u8("random move freq",2);
	}	

	if (!blob.exists("target dist"))
	{
		blob.set_u32("target dist",0);
	}	
	
//	this.getCurrentScript().removeIfTag	= "dead";   
//	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
//	this.getCurrentScript().runProximityTag = "player";
//	this.getCurrentScript().runProximityRadius = 200.0f;
	//this.getCurrentScript().tickFrequency = 5;

	//Vec2f terpos = blob.getPosition();
	//terpos += blob.getRadius();
	//blob.set_Vec2f(terr_pos_property, terpos);
}


void onTick( CBrain@ this )
{
	CBlob @blob = this.getBlob();
	
	if ( blob.getPlayer() !is null )
		return;

	u8 delay = blob.get_u8(delay_property);
	delay--;

	// set territory
	if (blob.getTickSinceCreated() == 10)
	{
		//Vec2f terpos = blob.getPosition();
		//terpos += blob.getRadius();
		//blob.set_Vec2f(terr_pos_property, terpos);
	//	printf("set territory " + blob.getPosition().x + " " + blob.getPosition().y );
	}

	if (delay == 0)
	{
		delay = 4+XORRandom(4);
		Vec2f pos = blob.getPosition();
		
		CMap@ map = blob.getMap();
		if (map.isTileSolid( Vec2f( pos.x, pos.y )))
		{
			// stuck?
			//if (map.isTileSolid( Vec2f( pos.x, pos.y +8.0 ) 
			blob.server_Die();
		}
		bool facing_left = blob.isFacingLeft();
		JumpOverObstacles(blob);
		{
			u8 mode = blob.get_u8(state_property);
			u8 personality = blob.get_u8(personality_property);
		
			//printf("mode " + mode);

			//"blind" attacking
			if (mode == MODE_TARGET) //always targetting
			{
				CBlob@ target = getBlobByNetworkID(blob.get_netid(target_property));
				
				if (target is null || target.getTeamNum() == blob.getTeamNum() || blob.hasAttached() || XORRandom( blob.get_u8(target_lose_random) ) == 0 || target.isInInventory() )
				{
					mode = MODE_IDLE;
				}
				else
				{
					if (!target.hasTag("player"))
					{
						// try to find player target
						f32 search_radius = blob.get_f32(target_searchrad_property);
						
						string name = blob.getName();
						
						CBlob@[] blobs;
						blob.getMap().getBlobsInRadius( pos, search_radius, @blobs );
						f32 best_dist = 99999999;
						for (uint step = 0; step < blobs.length; ++step)
						{
							//TODO: sort on proximity? done by engine?
							CBlob@ other = blobs[step];

							if (other is blob) continue; //lets not run away from / try to eat ourselves...

							if ( personality & SCARED_BIT != 0 ) //scared
							{
								if (other.getRadius() > blob.getRadius() && other.hasTag("flesh")) // not scared of same or smaller creatures
								{
									mode = MODE_FLEE;
									blob.set_netid(target_property,other.getNetworkID());
									break;
								}
							}

							if (personality & AGGRO_BIT != 0 ) //aggressive
							{
								//TODO: flags for these...
								if (blob.getName() == "Greg") 
								{
									bool otherzombies =  (XORRandom(4) == 0) || !other.hasTag("zombie");
									if (other.getName() != name && //dont eat same type of blob
										other.hasTag("flesh") && otherzombies && !other.hasTag("dead")) //attack flesh blobs
									{
										Vec2f tpos = other.getPosition();									  
										f32 dist = (tpos - pos).getLength();
										if (dist < best_dist)
										{
											mode = MODE_TARGET;
											blob.set_netid(target_property,other.getNetworkID());
											best_dist=dist;
											if (XORRandom(8) == 0) break;
										}
									}								
								}
								else
								if (other.getTeamNum() != blob.getTeamNum() && other.hasTag("flesh") && !other.hasTag("dead") && !other.hasTag("trader")) //attack flesh blobs
								{
									Vec2f tpos = other.getPosition();									  
									f32 dist = (tpos - pos).getLength();
										if (dist < best_dist)
										{
											mode = MODE_TARGET;
											blob.set_netid(target_property,other.getNetworkID());
											best_dist=dist;
											if (XORRandom(8) == 0) break;
										}
								}
							}
						}
					}
					
					Vec2f tpos = target.getPosition();

					f32 search_radius = blob.get_f32(target_searchrad_property);

					if ((tpos - pos).getLength() >= (search_radius))
					{
						mode = MODE_IDLE;
					}

					//if (personality & DONT_GO_DOWN_BIT == 0 || (blob.isOnGround() && tpos.y <= pos.y+3*blob.getRadius()))
					{	
						
						blob.setKeyPressed( (tpos.x < pos.x) ? key_left : key_right, true);
						blob.setKeyPressed( (tpos.y < pos.y) ? key_up : key_down, true);
					}
				}
			}
			//"blind" fleeing
			else if (mode == MODE_FLEE)
			{
				CBlob@ target = getBlobByNetworkID(blob.get_netid(target_property));

				if (target is null || target.isInInventory())
				{
					mode = MODE_IDLE;
				}
				else
				{						
					Vec2f tpos = target.getPosition();
					const f32 search_radius = blob.get_f32(target_searchrad_property);
					if ((tpos - pos).getLength() >= search_radius*3.0f)
					{
						mode = MODE_IDLE;
					}
					else
					{
						blob.setKeyPressed( (tpos.x > pos.x) ? key_left : key_right, true);
						blob.setKeyPressed( (tpos.y > pos.y) ? key_up : key_down, true);
					}
				}


			}
			// has a friend
			else if (mode == MODE_FRIENDLY)
			{
				CBlob@ friend = getBlobByNetworkID(blob.get_netid(friend_property));	  
				if (friend is null )
				{
					mode = MODE_IDLE;
				}
				else
				{
					Vec2f tpos = friend.getPosition();									  
					const f32 search_radius = blob.get_f32(target_searchrad_property);		  
					const f32 dist = (tpos - pos).getLength();
					if (dist >= search_radius)
					{
						//mode = MODE_IDLE;	  search until death sets us apart
					}
					if (blob.getRadius()*2.0f < dist)
					{					
						blob.setKeyPressed( (tpos.x < pos.x) ? key_left : key_right, true);
						//blob.setKeyPressed( (tpos.y < pos.y) ? key_up : key_down, true); hack for land animal
					}
				}
			}
			else //mode == idle
			{
				if (personality != 0) //we have a special personality
				{
					f32 search_radius = blob.get_f32(target_searchrad_property);
					string name = blob.getName();

					CBlob@[] blobs;
					blob.getMap().getBlobsInRadius( pos, search_radius, @blobs );
					f32 best_dist=99999999;
					for (uint step = 0; step < blobs.length; ++step)
					{
						//TODO: sort on proximity? done by engine?
						CBlob@ other = blobs[step];

						if (other is blob) continue; //lets not run away from / try to eat ourselves...

						if ( personality & SCARED_BIT != 0 ) //scared
						{
							if (other.getRadius() > blob.getRadius() && other.hasTag("flesh")) // not scared of same or smaller creatures
							{
								mode = MODE_FLEE;
								blob.set_netid(target_property,other.getNetworkID());
								break;
							}
						}

						if (personality & AGGRO_BIT != 0 ) //aggressive
						{
									//TODO: flags for these...
								if (blob.getName() == "Greg") 
								{
									bool otherzombies =  (XORRandom(4) == 0) || !other.hasTag("zombie");
									if (other.getName() != name && //dont eat same type of blob
										other.hasTag("flesh") && otherzombies && !other.hasTag("dead")) //attack flesh blobs
									{
										Vec2f tpos = other.getPosition();									  
										f32 dist = (tpos - pos).getLength();
										if (dist < best_dist)
										{
										mode = MODE_TARGET;
										blob.set_netid(target_property,other.getNetworkID());
										best_dist=dist;
										if (XORRandom(8) == 0) break;
										}
									}								
								}
								else
								if (other.getTeamNum() != blob.getTeamNum() && other.hasTag("flesh") && !other.hasTag("dead")) //attack flesh blobs
								{
									Vec2f tpos = other.getPosition();									  
									f32 dist = (tpos - pos).getLength();
									if (dist < best_dist)
									{
									mode = MODE_TARGET;
									blob.set_netid(target_property,other.getNetworkID());
									best_dist=dist;
									if (XORRandom(8) == 0) break;
									}
								}

						}
					}
					
					if (mode != MODE_TARGET)
					{
						for (uint step = 0; step < blobs.length; ++step)
						{
							//TODO: sort on proximity? done by engine?
							CBlob@ other = blobs[step];

							if (other is blob) continue; //lets not run away from / try to eat ourselves...
					
							if (other.getName() == "lantern" || other.getName() == "stone_door" || other.getName() == "wooden_door")
							{
								Vec2f tpos = other.getPosition();									  
								f32 dist = (tpos - pos).getLength();
							
								if (dist < best_dist)
								{
								mode = MODE_TARGET;
								blob.set_netid(target_property,other.getNetworkID());
								best_dist=dist;
								if (XORRandom(8) == 0) break;
								}
							}
						}
					}
				}
				
							u8 randomMoveFrequency = blob.get_u8("random move freq");
							if (XORRandom(randomMoveFrequency) == 0 || blob.isOnWall())
							{
							//blob.wasKeyPressed(key_right)
								bool dir = XORRandom(8)>=4;
								bool idling = XORRandom(8)>=6;
								blob.setKeyPressed(dir ? key_left : key_right, true);
								blob.set_u8("idling",idling?1:0);
								blob.set_u8("left",dir?1:0);
								
							} else
							{
								u8 idling=blob.get_u8("idling");
								if (idling==0)
								{
								u8 dir=blob.get_u8("left");
								blob.setKeyPressed(dir==1 ? key_left : key_right, true);
								}
							}
							bool rnd_up =XORRandom(randomMoveFrequency*2) == 0;
							if (rnd_up && (blob.isOnCeiling() || blob.isOnGround()))
							{
								bool dir = XORRandom(8)>=6;
								blob.setKeyPressed(dir ? key_up:key_down, true);
							}
							else
							{
								if (blob.wasKeyPressed(key_up) && !rnd_up) blob.setKeyPressed(key_up,true);
							}
/*
				if (blob.getTickSinceCreated() > 30) // delay so we dont get false terriroty pos
				{
					Vec2f territory_pos = blob.get_Vec2f(terr_pos_property);
					f32 territory_range = blob.get_f32(terr_rad_property);

					Vec2f territory_dir = (territory_pos - pos);
					////("territory " + territory_pos.x + " " + territory_pos.y );
						//	printf("territory_dir " + territory_dir.Length() + " " + territory_range  );
					if (territory_dir.Length() > territory_range && !blob.hasAttached() )
					{
						//head towards territory

						blob.setKeyPressed( (territory_dir.x < 0.0f) ? key_left : key_right, true);
						blob.setKeyPressed( (territory_dir.y > 0.0f) ? key_down : key_up, true);
					}
					else
					{	   					
						if (personality & TAMABLE_BIT != 0 && blob.hasAttached()) // shake off anyone riding
						{
							blob.setKeyPressed(blob.wasKeyPressed(key_right) ? key_left : key_right, true);
						}
						else
						if (personality & STILL_IDLE_BIT == 0)
						{
							u8 randomMoveFrequency = blob.get_u8("random move freq");
							//change direction at random or when on wall
							
							if (XORRandom(randomMoveFrequency) == 0 || blob.isOnWall())
							{
								blob.setKeyPressed((XORRandom(255)>127) ? key_left : key_right, true);
							}

							if (XORRandom(randomMoveFrequency) == 0 || blob.isOnCeiling() || blob.isOnGround())
							{
								blob.setKeyPressed(blob.wasKeyPressed(key_down) ? key_down : key_down, true);
							}
						}
					}
				}
*/
			}

			blob.set_u8(state_property, mode);
		}
	}
	else
	{
		PressOldKeys( blob );
	}

	blob.set_u8(delay_property, delay);
}
