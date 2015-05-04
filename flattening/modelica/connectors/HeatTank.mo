// name:     HeatTank
// keywords: replaceable connector
// cflags: +std=2.x
// status:   correct
//
// Error in implementation, replaceable connector.
// Drmodelica: 4.4 Parameterization and extension of Interfaces (p. 136).
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

connector HeatStream
  extends Stream;
  Real temp;
end HeatStream;

model HeatTank
  extends Tank(redeclare connector TankStream = HeatStream);
  Real level(start=2);
  Real temp;
equation

  inlet.temp = 25;

  // Energy balance for temperature effects
  area*level*der(temp) =
       inlet.volumeFlowRate*inlet.temp +
         outlet.volumeFlowRate*outlet.temp;

  outlet.temp = temp;

end HeatTank;


// Result:
// class HeatTank
//   parameter Real area = 1.0;
//   Real inlet.pressure;
//   Real inlet.volumeFlowRate;
//   Real inlet.temp;
//   Real outlet.pressure;
//   Real outlet.volumeFlowRate;
//   Real outlet.temp;
//   Real level(start = 2.0);
//   Real temp;
// equation
//   inlet.temp = 25.0;
//   area * level * der(temp) = inlet.volumeFlowRate * inlet.temp + outlet.volumeFlowRate * outlet.temp;
//   outlet.temp = temp;
//   inlet.volumeFlowRate = 1.0;
//   inlet.pressure = 1.0;
//   area * der(level) = inlet.volumeFlowRate + outlet.volumeFlowRate;
//   outlet.pressure = inlet.pressure;
//   outlet.volumeFlowRate = 2.0;
//   inlet.volumeFlowRate = 0.0;
//   outlet.volumeFlowRate = 0.0;
// end HeatTank;
// endResult
