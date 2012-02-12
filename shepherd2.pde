

const int lanes = 3;


/*READING VALUES*/

const int numReadings = 10;

int latestReadings[lanes] = {0};
int readings[lanes][numReadings] = {0};      // the readings from the analog input
int index = 0;                  // the index of the current reading
int total [lanes] = {0};                  // the running total
int average [lanes]= {0};                // the average

/*GAME STARTED*/

const int lowThreshold = 100;
const int highThreshold = 600;

unsigned long timeGameStarted = 0;

const int startPeriod = 2000;
int baselineThresholds[lanes] = {0}; 

/*SHEEP ARRAY*/

const int sheepThreshold = 100;
const int sheepBuffer = 5;

boolean sheepActive[lanes] = {false};

int sheepList[lanes][2][sheepBuffer] = {0};
int startColumn = 0; 
int endColumn = 1;

int sheepIndex[lanes] = {0};


/*PINS*/

const int onLedPin = 8;
const int offLedPin = 9;
const int ldrPin[lanes] = {A0, A1, A2};
const int solenoidPin[lanes][2] = {3,4,5,6,7,8};



/*FUNCTIONS*/

void checkReadings() {
	
	Serial.println(millis());
	
	for (int lane = 0; lane < lanes; lane++) {
		
		// subtract the last reading:
		total[lane] = total[lane] - readings[lane][index];         
		// read from the sensor:  
		readings[lane][index] = latestReadings[lane] = analogRead(ldrPin[lane]); 
		// add the reading to the total:
		total[lane]= total[lane] + readings[lane][index];

		// calculate the average:
		average[lane] = total[lane] / numReadings;
		
		Serial.print(readings[lane][index]);
		Serial.print(";");
		Serial.print(average[lane]);
		Serial.print(";");
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
		if (latestReadings[lane] > (baselineThresholds[lane] + sheepThreshold))
		{
			//create sheep
			sheepActive[lane] = true;
			sheepList[lane][startColumn][sheepIndex[lane]] = millis();
		}
		
		if (sheepActive[lane] == true && latestReadings[lane] < baselineThresholds[lane] + sheepThreshold)
		{
			//end sheep
			sheepList[lane][startColumn][sheepIndex[lane]] = millis();
			sheepActive[lane] = false;
			sheepIndex[lane]++;
			Serial.println("Sheep passed");
			delay(4000);
			
			if (sheepIndex[lane] >= sheepBuffer)
			{
				sheepIndex[lane] = 0;
			}
		}
	}
}

void fireSolenoids() {
	Serial.println("Checking whether to fire solenoids");
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
     
    if (checkGameRunning() == true)
    {
        for (int lane = 0; lane < lanes; lane++)
        {
            if (millis() < (timeGameStarted + startPeriod))
            {
                baselineThresholds[lane] = average[lane];
            }
             
            else {
                checkForSheep();
                fireSolenoids();
            }
        }
    }
}

