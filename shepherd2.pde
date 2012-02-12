

const int lanes = 3;
/*READING VALUES*/

int readings[lanes] = {0};


/*PINS*/

const int onLedPin = 9;
const int offLedPin = 8;
const int ldrPin[lanes] = {A0, A1, A2};
const int solenoidPin[lanes][2] = {3,4,5,6,7,8};



/*FUNCTIONS*/

void checkReadings() {
	Serial.println();
	for (int lane = 0; lane < lanes; lane++)
	{
		readings[lane] = analogRead(ldrPin[lane]);
		
		Serial.print(readings[lane]);
		Serial.print(";");
	}
}


/*SETUP*/

void setup() {

	Serial.begin(9600);
	
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
	checkReadings();
	
	digitalWrite (onLedPin, HIGH); 
	digitalWrite (offLedPin, HIGH); 
	
	for (int lane = 0; lane < lanes; lane++)
	{
		
	}
	
	
	
}

