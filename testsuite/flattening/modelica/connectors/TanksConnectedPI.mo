// name:      TanksConnectedPI
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

model TanksConnectedPI
  LiquidSource  source(flowLevel = 0.02);
  Tank          tank1(area = 1);
  Tank          tank2(area = 1.3);
  PIcontinuousController piContinuous1(ref = 0.25);
  PIcontinuousController piContinuous2(ref = 0.4);
 equation
  connect(source.qOut,tank1.qIn);
  connect(tank1.tActuator,piContinuous1.cOut);
  connect(tank1.tSensor,piContinuous1.cIn);
  connect(tank1.qOut,tank2.qIn);
  connect(tank2.tActuator,piContinuous2.cOut);
  connect(tank2.tSensor,piContinuous2.cIn);
end TanksConnectedPI;

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
// class TanksConnectedPI
//   Real source.qOut.lflow(unit = "m3/s");
//   parameter Real source.flowLevel = 0.02;
//   Real tank1.tSensor.val(unit = "m");
//   Real tank1.tActuator.act;
//   Real tank1.qIn.lflow(unit = "m3/s");
//   Real tank1.qOut.lflow(unit = "m3/s");
//   parameter Real tank1.area(unit = "m2") = 1.0;
//   parameter Real tank1.flowGain(unit = "m2/s") = 0.05;
//   parameter Real tank1.minV = 0.0;
//   parameter Real tank1.maxV = 10.0;
//   Real tank1.h(unit = "m", start = 0.0) "Tank level";
//   Real tank2.tSensor.val(unit = "m");
//   Real tank2.tActuator.act;
//   Real tank2.qIn.lflow(unit = "m3/s");
//   Real tank2.qOut.lflow(unit = "m3/s");
//   parameter Real tank2.area(unit = "m2") = 1.3;
//   parameter Real tank2.flowGain(unit = "m2/s") = 0.05;
//   parameter Real tank2.minV = 0.0;
//   parameter Real tank2.maxV = 10.0;
//   Real tank2.h(unit = "m", start = 0.0) "Tank level";
//   parameter Real piContinuous1.Ts(unit = "s") = 0.1 "Time period between discrete samples";
//   parameter Real piContinuous1.K = 2.0 "Gain";
//   parameter Real piContinuous1.T(unit = "s") = 10.0 "Time constant";
//   Real piContinuous1.cIn.val(unit = "m");
//   Real piContinuous1.cOut.act;
//   parameter Real piContinuous1.ref = 0.25 "Reference level";
//   Real piContinuous1.error "Deviation from reference level";
//   Real piContinuous1.outCtr "Output control signal";
//   Real piContinuous1.x "State variable of continuous PI controller";
//   parameter Real piContinuous2.Ts(unit = "s") = 0.1 "Time period between discrete samples";
//   parameter Real piContinuous2.K = 2.0 "Gain";
//   parameter Real piContinuous2.T(unit = "s") = 10.0 "Time constant";
//   Real piContinuous2.cIn.val(unit = "m");
//   Real piContinuous2.cOut.act;
//   parameter Real piContinuous2.ref = 0.4 "Reference level";
//   Real piContinuous2.error "Deviation from reference level";
//   Real piContinuous2.outCtr "Output control signal";
//   Real piContinuous2.x "State variable of continuous PI controller";
// equation
//   source.qOut.lflow = if time > 150.0 then 3.0 * source.flowLevel else source.flowLevel;
//   assert(tank1.minV >= 0.0, "minV - minimum Valve level must be >= 0 ");
//   der(tank1.h) = (tank1.qIn.lflow - tank1.qOut.lflow) / tank1.area;
//   tank1.qOut.lflow = limitValue(tank1.minV, tank1.maxV, (-tank1.flowGain) * tank1.tActuator.act);
//   tank1.tSensor.val = tank1.h;
//   assert(tank2.minV >= 0.0, "minV - minimum Valve level must be >= 0 ");
//   der(tank2.h) = (tank2.qIn.lflow - tank2.qOut.lflow) / tank2.area;
//   tank2.qOut.lflow = limitValue(tank2.minV, tank2.maxV, (-tank2.flowGain) * tank2.tActuator.act);
//   tank2.tSensor.val = tank2.h;
//   der(piContinuous1.x) = piContinuous1.error / piContinuous1.T;
//   piContinuous1.outCtr = piContinuous1.K * (piContinuous1.error + piContinuous1.x);
//   piContinuous1.error = piContinuous1.ref - piContinuous1.cIn.val;
//   piContinuous1.cOut.act = piContinuous1.outCtr;
//   der(piContinuous2.x) = piContinuous2.error / piContinuous2.T;
//   piContinuous2.outCtr = piContinuous2.K * (piContinuous2.error + piContinuous2.x);
//   piContinuous2.error = piContinuous2.ref - piContinuous2.cIn.val;
//   piContinuous2.cOut.act = piContinuous2.outCtr;
//   source.qOut.lflow = tank1.qIn.lflow;
//   piContinuous1.cOut.act = tank1.tActuator.act;
//   piContinuous1.cIn.val = tank1.tSensor.val;
//   tank1.qOut.lflow = tank2.qIn.lflow;
//   piContinuous2.cOut.act = tank2.tActuator.act;
//   piContinuous2.cIn.val = tank2.tSensor.val;
// end TanksConnectedPI;
// endResult
