// Runner Movement

#include "SpaceshipVars.as"

void onInit(CMovement@ this)
{
	SpaceshipVars moveVars;

	moveVars.engineFactor = 1.0f; //multiplier for engine output force
	moveVars.maxSpeedFactor = 1.0f; //multiplier for max speed
	moveVars.turnSpeedFactor = 1.0f; //multiplier for turn speed
	moveVars.dragFactor = 1.0f; //multiplier for drag

	moveVars.firingRateFactor = 1.0f; //lower is higher rate
	moveVars.firingSpradFactor = 1.0f; //multiplier for bullet spread

	this.getBlob().set("moveVars", moveVars);
}