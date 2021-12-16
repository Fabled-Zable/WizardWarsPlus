// Runner Common

shared class SpaceshipVars
{
	f32 engineMult = 1.0f; //multiplier for engine output force
	f32 maxSpeedMult = 1.0f; //multiplier for max speed
	f32 turnSpeedMult = 1.0f; //multiplier for turn speed
	f32 dragMult = 1.0f; //multiplier for drag

	f32 firingRateMult = 1.0f; //lower is higher rate
	f32 firingSpradMult = 1.0f; //multiplier for bullet spread
};

//cleanup all vars here - reset clean slate for next frame
void CleanUp(CMovement@ this, CBlob@ thisBlob, SpaceshipVars@ moveVars)
{
	//reset all the vars here
	moveVars.engineMult = 1.0f;
	moveVars.maxSpeedMult = 1.0f;
	moveVars.turnSpeedMult = 1.0f;
    moveVars.dragMult = 1.0f;

    moveVars.firingRateMult = 1.0f;
    moveVars.firingSpradMult = 1.0f;
}