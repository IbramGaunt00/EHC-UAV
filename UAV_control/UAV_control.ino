
/* Copyright (c) 2013 JAMES T. KALFAS

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
   must display the following acknowledgement:
   This product includes software developed by the <organization>.
4. Neither the name of the <organization> nor the
   names of its contributors may be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY JAMES T. KALFAS ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL JAMES T. KALFAS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/


// the following is pseudocode

// establish communication with gps and IMU9
// set a sample rate
// establish communication with servos
// set servo default position
// print servo position two times per second
// read from input devices, print responses ONLY when they change (default values are 0 so the starting value will always be printed)
// establish "zeroed" positions for input devices (wherever they are currently reading when the program reaches this point)
// based on "zeroed" positions of the input devices, have the servos adjust to maintain that position. implement PID control here to allow servos to compensate at a reasonable rat


#include <LSM303.h>
#include <L3G.h>
#include <Servo.h>
#include <Wire.h>


LSM303 compass;

Servo lail;
Servo rail;
Servo rudder;
Servo elev;

int lailpos = 0;
int railpos = 0;
int rudderpos = 0;
int elevpos = 0;

int xhead=0;
int xerror=0;
int yhead=0;
int yerror=0;
int zhead=0;
int zerror=0;
int counts=0;
int prevcounts=0;
int samplecount=0;
int heading = 0;


void setup()
{
  Serial.begin(9600);  //sets serial sample rate for MINI IMU9
  Wire.begin();
  compass.init();
  compass.enableDefault();
}



void loop ()
{
  lail.attach(2);      //these 4 lines designate which servos are on which pins
  rail.attach(3);
  rudder.attach(4);
  elev.attach(5);
  
  lailpos = 90;        //these 8 lines set the servos to their middle positions. they may be edited to set default trim
  railpos = 90;
  rudderpos = 90;
  elevpos = 90;
  
  lail.write(lailpos);
  rail.write(railpos);
  rudder.write(rudderpos);
  elev.write(elevpos);
  
  compass.read();            // reads the compass from the MINI IMU9
  xhead= (int)compass.a.x;
  yhead= (int)compass.a.y;
  zhead= (int)compass.a.z;
  while(1)
  {
    
    prevcounts=counts;
    counts = millis();
    int heading = compass.heading((LSM303::vector){0,-1,0});
    //if (counts-prevcounts >= 2)
    //{
     // print output of accelerometer and gyro here
     xerror = ((int)compass.a.x)-xhead;
     yerror = ((int)compass.a.y)-yhead;
     zerror = ((int)compass.a.z)-zhead;
//******************************************************************* IMPORTANT: Each axis is named for the rotation of the aircraft (i.e. Yaw=x, Pitch=y and Roll=z)    
     if (xhead-xerror == !0)
     {
       rudder.write((int)(xhead-xerror)/5);
     }
     Serial.print("  X: ");
     Serial.print((int) compass.a.x);
     Serial.print("  Y: ");
     Serial.print((int) compass.a.y);
     Serial.print("  Z: ");
     Serial.print((int) compass.a.z);
     Serial.print(" Heading:  ");
     Serial.println(heading);
     Serial.print("      \r\n");
     Serial.print("  xhead:  ");
     Serial.print(xhead);
     Serial.print("  yhead:  ");
     Serial.print(yhead);
     Serial.print("  zhead:  ");
     Serial.print(zhead);
     Serial.print("  xerror:  ");
     Serial.print(xerror);
     Serial.print("  yerror:  ");
     Serial.print(yerror);
     Serial.print("  zerror:  ");
     Serial.print("      \r\n");
    
     
     delay(300);
     
    }
    
    // }
     
}



