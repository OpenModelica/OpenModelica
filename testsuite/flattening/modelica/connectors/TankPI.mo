// name:     TankPI
// keywords: <insert keywords here>
// cflags: +std=2.x
// status:   correct
//
// <insert description here>
//
// Drmodelica: 12.1 Object Oriented Component-based (p. 386)
//
partial model BaseController
  parameter Real Ts(unit = "s") = 0.1  "Time period between discrete samples";
  parameter Real K = 2          "Gain";
  parameter Real T(unit = "s") = 10    "Time constant";
  ReadSignal cIn            "Input sensor level, connector";
  ActSignal  cOut            "Control to actuator, connector";
  parameter Real ref          "Reference level";
  Real error              "Deviation from reference level";
  Real outCtr              "Output control signal";
equation
  error = ref - cIn.val;
  cOut.act = outCtr;
end BaseController;

model PIcontinuousController
  extends BaseController(K = 2, T = 10);
  Real  x  "State variable of continuous PI controller";
equation
  der(x) = error/T;
  outCtr = K*(error + x);
end PIcontinuousController;

model LiquidSource
  LiquidFlow qOut;
  parameter Real flowLevel = 0.02;
equation
  qOut.lflow = if time > 150 then 3*flowLevel else flowLevel;
end LiquidSource;

connector LiquidFlow    "Liquid flow at inlets or outlets"
  Real lflow(unit = "m3/s");
end LiquidFlow;

connector ActSignal     "Signal to actuator for setting valve position"
  Real act;
end ActSignal;

connector ReadSignal     "Reading fluid level"
  Real val(unit = "m");
end ReadSignal;

function limitValue
  input  Real pMin;
  input  Real pMax;
  input  Real p;
  output Real pLim;
 algorithm
  pLim := if p>pMax then pMax
          else if p<pMin then pMin
          else p;
end limitValue;

model Tank
  ReadSignal     tSensor     "Connector, sensor reading tank level (m)";
  ActSignal      tActuator   "Connector, actuator controlling input flow";
  LiquidFlow     qIn         "Connector, flow (m3/s) through input valve";
  LiquidFlow     qOut        "Connector, flow (m3/s) through output valve";
  parameter Real area(unit = "m2")       =  0.5;
  parameter Real flowGain(unit = "m2/s") = 0.05;
  parameter Real minV= 0, maxV = 10;    // Limits for output valve flow
  Real           h(start = 0.0, unit = "m")   "Tank level";
 equation
  assert(minV>=0,"minV - minimum Valve level must be >= 0 ");
  der(h)      = (qIn.lflow - qOut.lflow)/area;    // Mass balance equation
  qOut.lflow  = limitValue(minV, maxV, -flowGain*tActuator.act);
  tSensor.val = h;
end Tank;

model TankPI
  LiquidSource           source(flowLevel=0.02);
  PIcontinuousController piContinuous(ref=0.25);
  Tank                   tank(area=1);
equation
  connect(source.qOut, tank.qIn);
  connect(tank.tActuator, piContinuous.cOut);
  connect(tank.tSensor, piContinuous.cIn);
end TankPI;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// Result:
// function limitValue
//   input Real pMin;
//   input Real pMax;
//   input Real p;
//   output Real pLim;
// algorithm
//   pLim := if p > pMax then pMax else if p < pMin then pMin else p;
// end limitValue;
//
// class TankPI
//   Real source.qOut.lflow(unit = "m3/s");
//   parameter Real source.flowLevel = 0.02;
//   parameter Real piContinuous.Ts(unit = "s") = 0.1 "Time period between discrete samples";
//   parameter Real piContinuous.K = 2.0 "Gain";
//   parameter Real piContinuous.T(unit = "s") = 10.0 "Time constant";
//   Real piContinuous.cIn.val(unit = "m");
//   Real piContinuous.cOut.act;
//   parameter Real piContinuous.ref = 0.25 "Reference level";
//   Real piContinuous.error "Deviation from reference level";
//   Real piContinuous.outCtr "Output control signal";
//   Real piContinuous.x "State variable of continuous PI controller";
//   Real tank.tSensor.val(unit = "m");
//   Real tank.tActuator.act;
//   Real tank.qIn.lflow(unit = "m3/s");
//   Real tank.qOut.lflow(unit = "m3/s");
//   parameter Real tank.area(unit = "m2") = 1.0;
//   parameter Real tank.flowGain(unit = "m2/s") = 0.05;
//   parameter Real tank.minV = 0.0;
//   parameter Real tank.maxV = 10.0;
//   Real tank.h(unit = "m", start = 0.0) "Tank level";
// equation
//   source.qOut.lflow = if time > 150.0 then 3.0 * source.flowLevel else source.flowLevel;
//   der(piContinuous.x) = piContinuous.error / piContinuous.T;
//   piContinuous.outCtr = piContinuous.K * (piContinuous.error + piContinuous.x);
//   piContinuous.error = piContinuous.ref - piContinuous.cIn.val;
//   piContinuous.cOut.act = piContinuous.outCtr;
//   assert(tank.minV >= 0.0, "minV - minimum Valve level must be >= 0 ");
//   der(tank.h) = (tank.qIn.lflow - tank.qOut.lflow) / tank.area;
//   tank.qOut.lflow = limitValue(tank.minV, tank.maxV, (-tank.flowGain) * tank.tActuator.act);
//   tank.tSensor.val = tank.h;
//   source.qOut.lflow = tank.qIn.lflow;
//   piContinuous.cOut.act = tank.tActuator.act;
//   piContinuous.cIn.val = tank.tSensor.val;
// end TankPI;
// endResult
