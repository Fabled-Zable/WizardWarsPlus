void updateLaserPositions(CBlob@ this)
{
	Vec2f thisPos = this.getPosition();
	Vec2f destination = this.get_Vec2f("aim pos");
	
	Vec2f aimPos = destination;
	Vec2f aimVec = aimPos - thisPos;
	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();
	
	Vec2f shootVec = destination-thisPos;
	
	Vec2f normal = (Vec2f(aimVec.y, -aimVec.x));
	normal.Normalize();
	
	array<Vec2f> laser_positions;
	
	float[] positions;
	positions.push_back(0);
	for (int i = 0; i < MAX_LASER_POSITIONS; i++)
	{
		positions.push_back( _laser_r.NextFloat() );
	}		
	positions.sortAsc();
	
	const f32 sway = 40.0f;
	const f32 jaggedness = 0.01f;
	
	Vec2f prevPoint = thisPos;
	f32 prevDisplacement = 0.0f;
	for (int i = 1; i < positions.length; i++)
	{
		float pos = positions[i];
 
		// used to prevent sharp angles by ensuring very close positions also have small perpendicular variation.
		float scale = (shootVec.Length() * jaggedness) * (pos - positions[i - 1]);
 
		// defines an envelope. Points near the middle of the bolt can be further from the central line.
		float envelope = pos > 0.95f ? 20 * (1 - pos) : 1;
 
		float displacement = _laser_r.NextFloat()*sway*2.0f - sway;
		displacement -= (displacement - prevDisplacement) * (1 - scale);
		displacement *= envelope;
 
		Vec2f point = thisPos + shootVec*pos + normal*displacement;
		
		laser_positions.push_back(prevPoint);
		prevPoint = point;
		prevDisplacement = displacement;
	}
	laser_positions.push_back(destination);
	
	this.set("laser positions", laser_positions);
	
	array<Vec2f> laser_vectors;
	for (int i = 0; i < laser_positions.length-1; i++)
	{
		laser_vectors.push_back(laser_positions[i+1] - laser_positions[i]);
	}		
	this.set("laser vectors", laser_vectors);	
}