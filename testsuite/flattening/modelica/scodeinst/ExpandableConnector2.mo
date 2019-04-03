// name: ExpandableConnector2
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

connector RealOutput = output Real;
connector RealInput = input Real;

expandable connector EngineBus
  Real speed;
  Real T;
end EngineBus;

block Sensor
  RealOutput speed;
end Sensor;

model ExpandableConnector2
  EngineBus bus;
  Sensor sensor;
equation
  connect(bus.speed, sensor.speed);
end ExpandableConnector2;

// Result:
// class ExpandableConnector2
//   Real bus.speed;
//   Real sensor.speed;
// equation
//   bus.speed = sensor.speed;
// end ExpandableConnector2;
// endResult
