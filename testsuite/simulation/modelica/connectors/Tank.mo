// name:     Tank
// keywords: replaceable connector
// status:   correct
//
// Drmodelica: 4.4 Parameterization and extension of Interfaces (p. 136).
//

connector Stream   //Connector class
  Real pressure;
  Real volumeFlowRate;
end Stream;


model Tank
  parameter Real area = 1;
  replaceable connector TankStream = Stream;    // Class parameterization
  TankStream inlet, outlet;              // The connectors
  Real level(start=2);
equation
  inlet.volumeFlowRate = 1;
  inlet.pressure = 1;

  // Mass balance
  area * der(level) = inlet.volumeFlowRate + outlet.volumeFlowRate;

  outlet.pressure = inlet.pressure;
  outlet.volumeFlowRate = 2;

end Tank;


// class Tank
// parameter Real area = 1;
// Real inlet.pressure;
// Real inlet.volumeFlowRate;
// Real outlet.pressure;
// Real outlet.volumeFlowRate;
// Real level(start = 2.0);
// equation
//   inlet.volumeFlowRate = 1.0;
//   inlet.pressure = 1.0;
//   area * der(level) = inlet.volumeFlowRate + outlet.volumeFlowRate;
//   outlet.pressure = inlet.pressure;
//   outlet.volumeFlowRate = 2.0;
// end Tank;