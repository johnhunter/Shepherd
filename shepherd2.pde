const int onLedPin = 9;
const int offLedPin = 8;

const int lanes = 3;

const int ldrPin[lanes] = {A0, A1, A2};

const int solenoidPin[lanes][2] = {3,4,5,6,7,8};


/*SETUP*/

void setup() {

	pinMode (onLedPin, OUTPUT);
	pinMode (offLedPin, OUTPUT);
	
	for (int lane = 0; lane < lanes; lane++)
	{
		pinMode (ldrPin[lane],INPUT);
		pinMode (solenoidPin[lane][0], OUTPUT);
		pinMode (solenoidPin[lane][1], OUTPUT);
	}

}

/*MAIN LOOP*/

void loop()
{
	digitalWrite (onLedPin, HIGH); 
	digitalWrite (offLedPin, HIGH); 
	
	for (int lane = 0; lane < lanes; lane++)
	{
		
	}
	
	
	
}

