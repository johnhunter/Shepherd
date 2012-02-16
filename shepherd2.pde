/*SHEPHERD - Leap Sheep Cheating Machine*/

/*BUZZER*/

const int buzzerFrequency  = 500; 
const int buzzerTime = 200;

/*READING VALUES*/

const int lanes = 3;
const int numReadings = 10;
int latestReadings[lanes] = {0};
int readings[lanes][numReadings] = {0};
int index = 0;
int total [lanes] = {0};
int average [lanes]= {0};

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

const float firstDistance [lanes] = {1, 1, 1};
const float secondDistance[lanes] = {2, 2, 2};
const int holdTime = 500;


/*PINS*/

const int onLedPin = 8;
const int offLedPin = 9;
const int ldrPin[lanes] = {A0, A2, A1};
const int solenoidPin[lanes][2] = {5,4,6,8,7,3};
const int buzzerPin = 10;


/*FUNCTIONS*/

void resetSolenoids() {
	for (int lane =0; lane < lanes; lane++)
	{
		digitalWrite(solenoidPin[lane][0], LOW);
		digitalWrite(solenoidPin[lane][1], LOW);
		//Serial.println("Resetting solenoid");	
	}
}

void testSolenoids(){
	for (int lane = 0; lane < lanes; lane++)
	{
		for (int i = 0; i <= lane; i++)
		{
			beep();
			delay(500);
		}
		digitalWrite(solenoidPin[lane][0], HIGH);
		delay(1000);
		
		digitalWrite(solenoidPin[lane][0], LOW);
		
		for (int i = 0; i <= lane; i++)
		{
			solenoidBeep();
			delay(500);
		}
		digitalWrite(solenoidPin[lane][1], HIGH);
		delay(1000);
		digitalWrite(solenoidPin[lane][1], LOW);
		delay(1000);
	}
}
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
	resetSolenoids();
	digitalWrite(onLedPin, LOW);
	digitalWrite(offLedPin, HIGH);
	resetSolenoids();
	
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
		
	for (int lane = 0; lane < lanes; lane++)
	{		
		// calculate speeds and times
		unsigned long sheepSpottedTime = sheepList[lane][startColumn][sheepNext[lane]];
		unsigned long sheepEndedTime = sheepList[lane][endColumn][sheepNext[lane]];
		
		if (sheepEndedTime != 0)
		{
			unsigned long sheepTime = (sheepEndedTime - sheepSpottedTime);
			unsigned long sheepExpectedFirst = sheepEndedTime + (firstDistance[lane] * sheepTime);
			unsigned long sheepExpectedSecond = sheepEndedTime + (secondDistance[lane] * sheepTime);
			
			/*
			Serial.print("sheepSpottedTime = ");
			Serial.println(sheepSpottedTime);
			Serial.print("sheepEndedTime = ");
			Serial.println(sheepEndedTime);
			Serial.print("sheepTime = ");
			Serial.println(sheepTime);
			Serial.print("sheepExpectedFirst = ");
			Serial.println(sheepExpectedFirst);
			Serial.print("sheepExpectedSecond = ");
			Serial.println(sheepExpectedSecond);
			*/
			
			if (millis() > sheepExpectedFirst && millis() < (sheepExpectedFirst + holdTime)) {
				digitalWrite(solenoidPin[lane][0], HIGH);
				Serial.println("Solenoid:");
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
					sheepNext[lane] = 0;
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
	
	//testSolenoids();

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
          			//sheepListPrint();
          			fireSolenoids();
          		}
          	}
}

