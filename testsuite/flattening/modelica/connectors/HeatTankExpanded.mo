// name:     HeatTankExpanded
// keywords:
// cflags: +std=2.x
// status:   correct
//
//
//

model HeatTankExpanded  //Modelica Book version, Added start values etc.
  parameter Real Area=1;          // and some inlet and outlet equations
  TankStream inlet, outlet;
  Real level(start=2);
  Real temp;

  connector TankStream
    Real pressure;
    flow Real volumeFlowRate;
    Real temp;
  end TankStream;

equation
  inlet.volumeFlowRate = 1;
  inlet.pressure = 1;
  inlet.temp = 25;
 // Mass balance:
  Area*der(level) = inlet.volumeFlowRate + outlet.volumeFlowRate;
  outlet.pressure = inlet.pressure;
  // Energy balance:
  Area*level*der(temp) = inlet.volumeFlowRate * inlet.temp +
                         outlet.volumeFlowRate * outlet.temp;

  outlet.temp = temp;
  outlet.volumeFlowRate = 2;
end HeatTankExpanded;

// Result:
// class HeatTankExpanded
//   parameter Real Area = 1.0;
//   Real inlet.pressure;
//   Real inlet.volumeFlowRate;
//   Real inlet.temp;
//   Real outlet.pressure;
//   Real outlet.volumeFlowRate;
//   Real outlet.temp;
//   Real level(start = 2.0);
//   Real temp;
// equation
//   inlet.volumeFlowRate = 1.0;
//   inlet.pressure = 1.0;
//   inlet.temp = 25.0;
//   Area * der(level) = inlet.volumeFlowRate + outlet.volumeFlowRate;
//   outlet.pressure = inlet.pressure;
//   Area * level * der(temp) = inlet.volumeFlowRate * inlet.temp + outlet.volumeFlowRate * outlet.temp;
//   outlet.temp = temp;
//   outlet.volumeFlowRate = 2.0;
//   inlet.volumeFlowRate = 0.0;
//   outlet.volumeFlowRate = 0.0;
// end HeatTankExpanded;
// endResult
