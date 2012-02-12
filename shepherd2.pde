const int onLedPin = 9;
const int offLedPin = 8;


void setup() {

	pinMode (onLedPin, OUTPUT);
	pinMode (offLedPin, OUTPUT);
}

void loop()
{
	digitalWrite (onLedPin, HIGH); 
	digitalWrite (offLedPin, HIGH); 
	
}

