// name:     WatchDog2EquationWhen
// keywords: watchdog equation-when
// status:   correct
//
// <insert description here>
//
// Drmodelica: 13.2 WatchDog System. (p. 435)
//
connector eventPort
  discrete Boolean signal;
end eventPort;

model EventGenerator
  parameter Real eventTime = 1;
  eventPort dOutput;
equation
  dOutput.signal = time > eventTime;
end EventGenerator;

model WatchDog2
   eventPort dOn;
   eventPort dOff;
   eventPort dDeadline;
   eventPort dAlarm;

   Real internalTime1, internalTime2;

equation
   when change(dOn.signal)then
     internalTime1 = time;
   end when;

   when change(dOff.signal)then
     internalTime2 = time;
   end when;

   when change(dDeadline.signal) and time>internalTime1 and internalTime1>internalTime2 then
     dAlarm.signal=true;
   end when;
end WatchDog2;

model WatchDogSystem2
  EventGenerator  turnOn(eventTime=1);
  EventGenerator  turnOff(eventTime=0.25);
  EventGenerator  deadlineEmitter(eventTime=1.5);
  WatchDog2       watchdog;
equation
    connect(turnOn.dOutput,watchdog.dOn);
    connect(turnOff.dOutput,watchdog.dOff);
    connect(deadlineEmitter.dOutput, watchdog.dDeadline);
end WatchDogSystem2;


// class WatchDogSystem2
// parameter Real turnOn.eventTime = 1;
// discrete Boolean turnOn.dOutput.signal;
// parameter Real turnOff.eventTime = 0.25;
// discrete Boolean turnOff.dOutput.signal;
// parameter Real deadlineEmitter.eventTime = 1.5;
// discrete Boolean deadlineEmitter.dOutput.signal;
// discrete Boolean watchdog.dOn.signal;
// discrete Boolean watchdog.dOff.signal;
// discrete Boolean watchdog.dDeadline.signal;
// discrete Boolean watchdog.dAlarm.signal;
// Real watchdog.internalTime1;
// Real watchdog.internalTime2;
// equation
//   turnOn.dOutput.signal = time > turnOn.eventTime;
//   turnOff.dOutput.signal = time > turnOff.eventTime;
//   deadlineEmitter.dOutput.signal = time > deadlineEmitter.eventTime;
//   when change(watchdog.dOn.signal) then
//   watchdog.internalTime1 = time;
//   end when;
//   when change(watchdog.dOff.signal) then
//   watchdog.internalTime2 = time;
//   end when;
//   when change(watchdog.dDeadline.signal) AND time > watchdog.internalTime1 AND watchdog.internalTime1 > watchdog.internalTime2 then
//   watchdog.dAlarm.signal = true;
//   end when;
//   deadlineEmitter.dOutput.signal = watchdog.dDeadline.signal;
//   turnOff.dOutput.signal = watchdog.dOff.signal;
//   turnOn.dOutput.signal = watchdog.dOn.signal;
// end WatchDogSystem2;
