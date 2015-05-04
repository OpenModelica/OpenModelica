// name:     HeatTank
// keywords: replaceable connector
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


