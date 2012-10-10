#include <String.h>
#include "Wire.h"
#define DS1307_ADDRESS 0x68

int pastseconds, seconds, minutes, hours, weekDay, day, month, year;
unsigned long dayseconds;
String test, data, time; // These are used by GPSPartyTime
String theData; // This is what will be written to the microSD card

void setup(){
  Wire.begin();
  Serial.begin(4800);
  Serial.println("hello world!");
  pinMode(2, OUTPUT);
  digitalWrite(2, LOW);
  digitalWrite(13, HIGH);
  delay(500);
  digitalWrite(13, LOW);
  Initializer();
  pastseconds = seconds;
}

void loop()
{ 
  getTime();
  if (seconds != pastseconds){
    TimeStomper();
    //TimePrinter();
    Serial.println(theData);
    digitalWrite(13, HIGH);
    digitalWrite(13, LOW);
  }
}

///////////////////////////////////////////////////////
//////////////////  Initializer  //////////////////////
///////////////////////////////////////////////////////
//  Initializer will get the time from the RTC, and  //
//  if it's wrong, it will call setRTC() to set it   //
//  correctly. Once the time is correct, it will     //
//  be printed out once, and Initializer will end.   //
///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

void Initializer(){

  getTime();

  Serial.println("This is the correct time:");
  TimePrinter();

  delay(500);

}

//////////////////////////////////////////////////////
////////////////////  getTime  ///////////////////////
//////////////////////////////////////////////////////

void getTime()
{ 
  if (seconds == 80) // Clock doesn't know what time it is
  {
    Serial.println("Time is incorrect. Stand by.");
    setRTC();
  }

  Wire.beginTransmission(DS1307_ADDRESS); // Reset the register pointer
  Wire.send(0);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_ADDRESS, 7); // Get the 7 bytes from the RTC

  seconds = bcdToDec(Wire.receive());
  minutes = bcdToDec(Wire.receive());
  hours = bcdToDec(Wire.receive() & 0b111111); //24 hours time
  weekDay = bcdToDec(Wire.receive()); //0-6 -> Sunday - Saturday
  day = bcdToDec(Wire.receive());
  month = bcdToDec(Wire.receive());
  year = bcdToDec(Wire.receive());
  if (month == 00)  Serial.println("Clock is disconnected");
}
//////////////////////////////////////////////////////
////////////////////  setRTC  ////////////////////////
//////////////////////////////////////////////////////

void setRTC(){

  // 0) Set all the time ints to 00
  // 1) Turn on the GPS
  // 2) Run the GPS code (it won't do anything until it gets an 'A')
  // 3) If month var != 00, turn off GPS

  GPSPartyTime();

  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0); //stop Oscillator

  Wire.send(decToBcd(seconds));
  Wire.send(decToBcd(minutes));
  Wire.send(decToBcd(hours));
  Wire.send(decToBcd(weekDay));
  Wire.send(decToBcd(day));
  Wire.send(decToBcd(month));
  Wire.send(decToBcd(year));

  Wire.send(0); //start 

  Wire.endTransmission();

}

//////////////////////////////////////////////////////
////////////////  dec/Bcd converters  ////////////////
//////////////////////////////////////////////////////

byte decToBcd(byte val){
  // Convert normal decimal numbers to binary coded decimal
  return ( (val/10*16) + (val%10) );
}

byte bcdToDec(byte val)  {
  // Convert binary coded decimal to normal decimal numbers
  return ( (val/16*10) + (val%16) );
}

//////////////////////////////////////////////////////
//////////////////  GPSPartyTime  ////////////////////
//////////////////////////////////////////////////////

void GPSPartyTime(){
  TimePrinter();
  digitalWrite(2, HIGH);
  Serial.println("Serial Monitor is prepped for crashing.");
  while (seconds == 80){
    for (int j=0; j<4; j++){
      char c = Serial.read();             // c is GPS char
      if(c == '$')                        // if c is a $, store it in data
        data = c;          

      do{
        c = Serial.read();
      }              // Ignore all the ys (those are -1s)
      while(c == -1);

      while(c != '$'){                    // Until the next time the GPS sends a $,
        data += c;                        // add c to the data string,
        do {
          c = Serial.read();
        }            // but still ignoring any ys
        while(c == -1);
      }
      test = "abcd";                       // Feed the data string into the test string
      for(int i=0; i<4; i++){              // 
        test[i] = data[i];
        delay(1);                          // This delay makes it work. WTF.
      }
      if(test == "PRMC"){                  // We are right at the edge of the GPRMC line!
        //Serial.println("I caught the signal! Parsing the time...");
        if(data[16] == 'A'){                // Unless the data is valid, do nothing.
          // A = valid data. V = bad data.

          hours = (data[5] - '0')*10 + (data[6] - '0'); // Convert ASCII value to int value
          minutes = (data[7] - '0')*10 + (data[8] - '0');
          seconds = (data[9] - '0')*10 + (data[10] - '0');
          day = (data[55] - '0')*10 + (data[56] - '0');
          month = (data[57] - '0')*10 + (data[58] - '0');
          year = (data[59] - '0')*10 + (data[60] - '0');
          dayseconds = ((long)seconds + 60*(long)minutes + 3600*(long)hours);

          hours = hourconverter(hours); // Convert hours based on time zone

          Serial.println("The time has been pulled from space. It is now correct.");
          delay(1500);

        }
      }
    }
    data = ""; // Otherwise data will grow, and we will never find "PRMC"
  }
  digitalWrite(2, LOW);
}

//////////////////////////////////////////////////////
//////////////////  hourconverter  ///////////////////
//////////////////////////////////////////////////////

int hourconverter(int)
// The GPS is 5 hours ahead of EST.
// This just converts the hour from the GPS to EST.
{
  if((hours-5) < 0)
  {
    hours += 19;         // If the hour of the GPS IS between 00-04
  }
  else
  {
    hours -= 5;          // If the hour of the GPS time is greater than 05
  }
  return hours;
}

//////////////////////////////////////////////////////
///////////////////  TimePrinter  ////////////////////
//////////////////////////////////////////////////////

void TimePrinter()
{
  if(day < 10) Serial.print(0);
  Serial.print(day);
  Serial.print('/');
  if(month < 10) Serial.print(0);
  Serial.print(month);
  Serial.print('/');
  if(year < 10) Serial.print(0);
  Serial.print(year);
  Serial.print("  ");

  if(hours < 10) Serial.print(0);
  Serial.print(hours);
  Serial.print(':');
  if(minutes < 10) Serial.print(0);
  Serial.print(minutes);
  Serial.print(':');
  if(seconds < 10) Serial.print(0);
  Serial.print(seconds);
  Serial.println();
}

//////////////////////////////////////////////////////
///////////////////  TimeStomper  ////////////////////
//////////////////////////////////////////////////////

void TimeStomper()
{
  getTime();
  accel1 = analogRead(A0);
  if(hours < 10) {
    theData = ('0');
    theData += ((int)hours);
  }
  else theData = ((int)hours);
  if(minutes < 10) theData += ('0');
  theData += ((int)minutes);
  if(seconds < 10) theData += ('0');
  theData += ((int)seconds);
  theData += (' ');
  theData += int(accel1);
}
//////////////////////////////////////////////////////
///////////////////  TimeStomper  ////////////////////
//////////////////////////////////////////////////////

void TimeStomper()
{
  getTime();
  accel1 = analogRead(A0);
  theData = ((long)dayseconds);
  theData += (' ');
  theData += int(accel1);
}







