// name:     Tank
// keywords: replaceable connector
// status:   correct
//
//
//

connector Stream   //Connector class
  Real pressure;
  flow Real volumeFlowRate;
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


// Result:
// class Tank
//   parameter Real area = 1.0;
//   Real inlet.pressure;
//   Real inlet.volumeFlowRate;
//   Real outlet.pressure;
//   Real outlet.volumeFlowRate;
//   Real level(start = 2.0);
// equation
//   inlet.volumeFlowRate = 1.0;
//   inlet.pressure = 1.0;
//   area * der(level) = inlet.volumeFlowRate + outlet.volumeFlowRate;
//   outlet.pressure = inlet.pressure;
//   outlet.volumeFlowRate = 2.0;
//   inlet.volumeFlowRate = 0.0;
//   outlet.volumeFlowRate = 0.0;
// end Tank;
// endResult
