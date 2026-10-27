// name:     WatchDog1AlgorithmWhen
// keywords: watchdog, when
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

model WatchDog1
  eventPort dOn;
  eventPort dOff;
  eventPort dDeadline;
  eventPort dAlarm;
  discrete Boolean watchdogActive(start=false);  // Initially turned off
algorithm
  when change(dOn.signal) then                 // Event watchdog on
    watchdogActive := true;
  end when;

  when change(dOff.signal) then                // Event watchdog off
    watchdogActive := false;
    dAlarm.signal  := false;
  end when;

  when (change(dDeadline.signal) and watchdogActive) then   // Event Alarm!
    dAlarm.signal := true;
  end when;
end WatchDog1;

model WatchDogSystem1
  EventGenerator  turnOn(eventTime = 1);
  EventGenerator  turnOff(eventTime = 0.25);
  EventGenerator  deadlineEmitter(eventTime = 1.5);
  WatchDog1       watchdog;
equation
  connect(turnOn.dOutput,  watchdog.dOn);
  connect(turnOff.dOutput, watchdog.dOff);
  connect(deadlineEmitter.dOutput, watchdog.dDeadline);
end WatchDogSystem1;


// Result:
// class WatchDogSystem1
//   parameter Real turnOn.eventTime = 1.0;
//   discrete Boolean turnOn.dOutput.signal;
//   parameter Real turnOff.eventTime = 0.25;
//   discrete Boolean turnOff.dOutput.signal;
//   parameter Real deadlineEmitter.eventTime = 1.5;
//   discrete Boolean deadlineEmitter.dOutput.signal;
//   discrete Boolean watchdog.dOn.signal;
//   discrete Boolean watchdog.dOff.signal;
//   discrete Boolean watchdog.dDeadline.signal;
//   discrete Boolean watchdog.dAlarm.signal;
//   discrete Boolean watchdog.watchdogActive(start = false);
// equation
//   turnOn.dOutput.signal = watchdog.dOn.signal;
//   turnOff.dOutput.signal = watchdog.dOff.signal;
//   deadlineEmitter.dOutput.signal = watchdog.dDeadline.signal;
//   turnOn.dOutput.signal = time > turnOn.eventTime;
//   turnOff.dOutput.signal = time > turnOff.eventTime;
//   deadlineEmitter.dOutput.signal = time > deadlineEmitter.eventTime;
// algorithm
//   when change(watchdog.dOn.signal) then
//     watchdog.watchdogActive := true;
//   end when;
//   when change(watchdog.dOff.signal) then
//     watchdog.watchdogActive := false;
//     watchdog.dAlarm.signal := false;
//   end when;
//   when change(watchdog.dDeadline.signal) and watchdog.watchdogActive then
//     watchdog.dAlarm.signal := true;
//   end when;
// end WatchDogSystem1;
// [flattening/modelica/equations/WatchDog1AlgorithmWhen.mo:15:3-15:20:writable] Warning: Connector dOutput is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/equations/WatchDog1AlgorithmWhen.mo:21:3-21:16:writable] Warning: Connector dOn is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/equations/WatchDog1AlgorithmWhen.mo:22:3-22:17:writable] Warning: Connector dOff is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/equations/WatchDog1AlgorithmWhen.mo:23:3-23:22:writable] Warning: Connector dDeadline is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/equations/WatchDog1AlgorithmWhen.mo:24:3-24:19:writable] Warning: Connector dAlarm is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
//
// endResult
