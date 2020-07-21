void decreaseNegatisphereLife( CBlob@ this , CBlob@ b )
{
	if(this is null){return;}
	if(b is null){return;}
	
	s8 life = this.get_s8("lifepoints");
	string blobname = b.getName();

	switch(blobname.getHash())
	{
		case 1370376319: //bees
		{
			this.set_s8("lifepoints", (life - 1));
		}
		break;
		case 829656850: //spores
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;
		case 1463630946: //spikeballs
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;
		case 1843332075: //ground rock spikes
		{
			this.set_s8("lifepoints", (life - 3));
		}
		break;
		case -825046729: //mushroom
		{
			this.set_s8("lifepoints", (life - 8));
		}
		break;
		case 131361395: //expunger
		{
			this.set_s8("lifepoints", (life - 2));
		}
		break;
		case -1661937901: //impaler
		{
			this.set_s8("lifepoints", (life - 5));
		}
		break;
		case -32608566: //crusader
		{
			this.set_s8("lifepoints", (life - 7));
		}
		break;
		case -1625426670: //orb
		{
			this.set_s8("lifepoints", (life - 4));
		}
		break;
		case -1214504009: //magic missile
		{
			this.set_s8("lifepoints", (life - 6));
		}
		break;
		default: //anything that one-shots it
		{
			this.set_s8("lifepoints", 0);
		}
	}
}

s8 negentropyDecoder( CBlob@ b )
{
	if(b is null){return -1;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case 1370376319: //bees
		{
			return 5;
		}
		break;
		case 829656850: //spores
		{
			return 5;
		}
		break;
		case 1463630946: //spikeballs
		{
			return 4;
		}
		break;
		case 1843332075: //ground rock spikes
		{
			return 3;
		}
		break;
		case -825046729: //mushroom
		{
			return 20;
		}
		break;
		case 131361395: //expunger
		{
			return 2;
		}
		break;
		case -1661937901: //impaler
		{
			return 15;
		}
		break;
		case -32608566: //crusader
		{
			return 15;
		}
		break;
		case 603057094: //executioner
		{
			return 40;
		}
		break;
		case -1625426670: //orb
		{
			return 10;
		}
		break;
		case -1214504009: //magic missile
		{
			return 10;
		}
		break;
		case -2014033180: //magic_barrier
		{
			return 20;
		}
		break;
		case 382419657: //rock_wall
		{
			return 15;
		}
		break;
		case 39628416: //no_teleport_barrier
		{
			return 25;
		}
		break;
		case -445081510: //negatisphere
		{
			return 20;
		}
		break;
		case 2016613317: //firebomb
		{
			return 30;
		}
		break;
		case -1418908460: //bunker_buster
		{
			return 30;
		}
		break;
		case 1174066691: //fire_sprite
		{
			return 20;
		}
		break;
		case -401411067: //lightning
		{
			return 100;
		}
		break;
		case 770505718: //leech
		{
			return 80;
		}
		break;
		case 18140583: //frost_ball
		{
			return 20;
		}
		break;
		case -286128466: //ice_prison
		{
			return 3;
		}
		break;
		case -824473937: //effect_missile
		{
			return 15;
		}
		break;
		case 452290988: //plant_aura
		{
			return 15;
		}
		break;
		case 1238003545: //meteor
		{
			return 50;
		}
		break;
		case 750462252: //mana_drain_circle
		{
			return -2;
		}
		break;
		case -1727909596: //arcane_circle
		{
			return -2;
		}
		break;
		case 882940767: //black_hole
		{
			return -2;
		}
		break;
		case -270118290: //black_hole_big
		{
			return -2;
		}
		break;
		case -1760442616: //mana_obelisk
		{
			return -3;
		}
		break;
		case -1612772378: //force_of_nature
		{
			return -3;
		}
		break;

		default: //unabsorvable
		{
			return -1;
		}
	}
	
	return -1;
}

bool voltageFieldDamage( CBlob@ b )
{
	if(b is null){return false;}

	string blobname = b.getName();
	switch(blobname.getHash())
	{
		case 603057094: //executioner
		{
			return false;
		}
		break;
		case -1625426670: //orb
		{
			return false;
		}
		break;
		case 39628416: //no_teleport_barrier
		{
			return false;
		}
		break;
		case -445081510: //negatisphere
		{
			return false;
		}
		break;
		case -1418908460: //bunker_buster
		{
			return false;
		}
		break;
		case -401411067: //lightning
		{
			return false;
		}
		break;
		case 770505718: //leech
		{
			return false;
		}
		break;
		case -824473937: //effect_missile
		{
			return false;
		}
		break;
		case 1238003545: //meteor
		{
			return false;
		}
		break;
		case 750462252: //mana_drain_circle
		{
			return false;
		}
		break;
		case -1727909596: //arcane_circle
		{
			return false;
		}
		break;
		case 882940767: //black_hole
		{
			return false;
		}
		break;
		case -270118290: //black_hole_big
		{
			return false;
		}
		break;
		case -1760442616: //mana_obelisk
		{
			return false;
		}
		break;
		case -1612772378: //force_of_nature
		{
			return false;
		}
		break;

		default: //damage anyways
		{
			return true;
		}
	}
	
	return true;
}