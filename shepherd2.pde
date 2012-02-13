

const int lanes = 3;

/*BUZZER*/

const int buzzerFrequency  = 500; 
const int buzzerTime = 200;


/*READING VALUES*/

const int numReadings = 10;
int latestReadings[lanes] = {0};
int readings[lanes][numReadings] = {0};      // the readings from the analog input
int index = 0;                  // the index of the current reading
int total [lanes] = {0};                  // the running total
int average [lanes]= {0};                // the average

/*GAME STARTED*/

const int lowThreshold = 100;
const int highThreshold = 750;

unsigned long timeGameStarted = 0;

const int startPeriod = 2000;
int baselineThresholds[lanes] = {0}; 

/*SHEEP ARRAY*/

const int sheepThreshold = 100;
const int sheepBuffer = 5;

boolean sheepActive[lanes] = {false};

unsigned long sheepList[lanes][2][sheepBuffer] = {0};
int startColumn = 0; 
int endColumn = 1;

int sheepIndex[lanes] = {0};
int sheepNext[lanes] = {0};

/*SOLENOID FIRER*/
const int sheepWidth = {10};
const int firstDistance [lanes] = {25, 30, 30};
const int secondDistance[lanes] = {30, 40, 50};
const int holdTime = 500;


/*PINS*/

const int onLedPin = 8;
const int offLedPin = 9;
const int ldrPin[lanes] = {A0, A2, A1};
const int solenoidPin[lanes][2] = {3,4,5,6,7,8};
const int buzzerPin = 10;


/*FUNCTIONS*/

void beep() {
	tone(buzzerPin, buzzerFrequency, buzzerTime);
}

void solenoidBeep() {
	tone(buzzerPin, buzzerFrequency / 2, buzzerTime);
}

void checkReadings() {
	
	
	for (int lane = 0; lane < lanes; lane++) {
		
		// subtract the last reading:
		total[lane] = total[lane] - readings[lane][index];         
		// read from the sensor:  
		readings[lane][index] = latestReadings[lane] = analogRead(ldrPin[lane]); 
		// add the reading to the total:
		total[lane]= total[lane] + readings[lane][index];

		// calculate the average:
		average[lane] = total[lane] / numReadings;
		
	}
	
	// advance to the next position in the array:  
	index = index + 1;                    

	// if we're at the end of the array...
	if (index >= numReadings)              
	// ...wrap around to the beginning: 
	index = 0;
}

boolean checkGameRunning() {
	for (int lane = 0; lane < lanes; lane++){
		
		if (latestReadings[lane] > lowThreshold && latestReadings[lane] < highThreshold) {
			if (timeGameStarted == 0)
			{
				timeGameStarted = millis();
				Serial.println("Game Started");
				return(true);
			}
			else 
			{
				Serial.println();
				Serial.println("Game Running");
				digitalWrite(onLedPin, HIGH);
				digitalWrite(offLedPin, LOW);
				return (true);
			}
		}
	}
	
	Serial.println("Game Not Running");
	timeGameStarted = 0;
	digitalWrite(onLedPin, LOW);
	digitalWrite(offLedPin, HIGH);
		
	return (false);
}

void checkForSheep() {
	Serial.println("Checking for sheep");
	
	for (int lane = 0; lane < lanes; lane++)
	{
		if (sheepActive[lane] == false && latestReadings[lane] > (baselineThresholds[lane] + sheepThreshold))
		{
			//create sheep
			sheepActive[lane] = true;
			sheepList[lane][startColumn][sheepIndex[lane]] = millis();
			sheepList[lane][endColumn][sheepIndex[lane]] = 0;
			Serial.println("Sheep arrived");	
		}
		
		else if (sheepActive[lane] == true && latestReadings[lane] < baselineThresholds[lane] + sheepThreshold)
		{
			//end sheep
			sheepList[lane][endColumn][sheepIndex[lane]] = millis();
			sheepActive[lane] = false;
			sheepIndex[lane]++;
			
			Serial.println("Sheep passed");
			beep();
						
			if (sheepIndex[lane] >= sheepBuffer)
			{
				sheepIndex[lane] = 0;
			}
			
			//reset values
			Serial.println("Reset values");
			sheepList[lane][startColumn][sheepIndex[lane]] = 0;
			sheepList[lane][endColumn][sheepIndex[lane]] = 0;
		}
		else {
			Serial.println("No sheep");
		}
	}
}

void sheepListPrint () {
	Serial.print("Sheep Times @ ");
	Serial.print(millis());
	for (int lane = 0; lane < lanes; lane++)
	{
		Serial.println();
		Serial.print(sheepIndex[lane]);
		Serial.print(";");
		Serial.print(sheepList[lane][startColumn][sheepIndex[lane]]);
		Serial.print(";");
		Serial.print(sheepList[lane][endColumn][sheepIndex[lane]]);
		Serial.print(";");
	}
}

void readingsPrint () {
	Serial.print("Readings @ ");
	Serial.println(millis());
	for (int lane = 0; lane < lanes; lane++)
	{
		Serial.println(latestReadings[lane]);
	}
}

void averagesPrint (){
	Serial.print("Averages @ ");
	Serial.println(millis());
	for (int lane = 0; lane < lanes; lane++)
	{
		Serial.println(average[lane]);
	}
}


void fireSolenoids() {
	Serial.println();
	Serial.println("Check solenoids");
		
	for (int lane = 0; lane < lanes; lane++)
	{
		// calculate speeds and times
		unsigned long sheepSpottedTime = sheepList[lane][startColumn][sheepNext[lane]];
		unsigned long sheepEndedTime = sheepList[lane][endColumn][sheepNext[lane]];
	
		if (sheepEndedTime != 0)
		{
			unsigned long speed = (sheepEndedTime - sheepSpottedTime) / sheepWidth;

			unsigned long sheepExpectedFirst = sheepEndedTime + (firstDistance[lane] / speed);
			unsigned long sheepExpectedSecond = sheepEndedTime + (secondDistance[lane] / speed);
			
			//serial out
			Serial.print("sheepSpottedTime = ");
			Serial.println(sheepSpottedTime);
			Serial.print("sheepEndedTime = ");
			Serial.println(sheepEndedTime);
			Serial.print("speed = ");
			Serial.println(speed);
			Serial.print("sheepExpectedFirst = ");
			Serial.println(sheepEndedTime);
			Serial.print("sheepExpectedSecond = ");
			Serial.println(speed);

			if (millis() > sheepExpectedFirst && millis() < (sheepExpectedFirst + holdTime)) {
				digitalWrite(solenoidPin[lane][0], HIGH);
				Serial.println("Solenoid down");
				solenoidBeep();
			}
			
			else if (millis() > (sheepExpectedFirst + holdTime)) {
			digitalWrite(solenoidPin[lane][0], LOW);
			Serial.println("Solenoid up");
			}

			if (millis() > sheepExpectedSecond && millis() < (sheepExpectedSecond + holdTime)) {
				digitalWrite(solenoidPin[lane][1], HIGH);
				Serial.println("Solenoid down");
				solenoidBeep();
			}

			else if (millis() > (sheepExpectedSecond + holdTime)) {
				digitalWrite(solenoidPin[lane][1], LOW);
				Serial.println("Solenoid up");
				
				sheepNext[lane]++;

				if (sheepNext[lane] >= sheepBuffer) {
					sheepIndex[lane] = 0;
				}
			}
		}
	}
}

/*SETUP*/

void setup() {

	Serial.begin(9600);
	
	pinMode (onLedPin, OUTPUT);
	pinMode (offLedPin, OUTPUT);
	pinMode (buzzerPin, OUTPUT);
	
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
	
    if (checkGameRunning() == true)
    {
        if (millis() < (timeGameStarted + startPeriod))
            {
				for (int lane = 0; lane < lanes; lane++) {
					Serial.println("Starting");
                	baselineThresholds[lane] = average[lane];
					//resetting variables - needs tidying up
					sheepIndex[lane] = 0;
					sheepNext[lane] = 0;
					sheepList[lane][startColumn][sheepIndex[lane]] = 0;
					sheepList[lane][endColumn][sheepIndex[lane]] = 0;
					//averagesPrint();
				}
            }
        else {
			checkForSheep();
			//readingsPrint();
			sheepListPrint();
			//fireSolenoids();
		}
	}
}

