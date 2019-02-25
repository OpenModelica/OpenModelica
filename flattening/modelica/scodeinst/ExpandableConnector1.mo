// name: ExpandableConnector1
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

connector RealOutput = output Real;
connector RealInput = input Real;

expandable connector EngineBus
end EngineBus;

block Sensor
  RealOutput speed;
end Sensor;

block Actuator
  RealInput speed;
end Actuator;

model ExpandableConnector1
  EngineBus bus;
  Sensor sensor;
  Actuator actuator;
equation
  connect(bus.speed, sensor.speed);
  connect(bus.speed, actuator.speed);
end ExpandableConnector1;

// Result:
// class ExpandableConnector1
//   Real bus.speed "virtual variable in expandable connector";
//   Real sensor.speed;
//   Real actuator.speed;
// equation
//   bus.speed = actuator.speed;
//   bus.speed = sensor.speed;
// end ExpandableConnector1;
// endResult
