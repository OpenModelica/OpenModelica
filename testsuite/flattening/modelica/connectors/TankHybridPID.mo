// name:     TankHybridPID
// keywords: <insert keywords here>
// cflags: +std=2.x
// status:   correct
//
// <insert description here>
//
function LimitValue
  input Real pMin;
  input Real pMax;
  input Real p;
  output Real pLim;
algorithm
  pLim := if p>pMax then pMax
          else if p<pMin then pMin
          else p;
end LimitValue;

connector ReadSignal
  Real val;
end ReadSignal;

connector ActSignal
  Real act;
end ActSignal;

connector LiquidFlow
  Real lflow;
end LiquidFlow;



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


partial model PIDcontroller
  parameter Real Ts = 0.1;            // sampling time[s]
  parameter Real K = 2;               // gain
  parameter Real T = 10;              // time constant[s]
  parameter Real minV = 0, maxV = 1;  // limits for output
  Real      ref, error, outCtr;
  ReadSignal cInp;
  ActSignal  cOut;
equation
  error = ref - cInp.val;
  cOut.act = LimitValue(minV, maxV, outCtr);
end PIDcontroller;

model PIDcontinuousController
  extends PIDcontroller(K = 2, T = 10, maxV = 0.02);
  Real  x;                     //state variable of continuous controller
  Real  y;                     //state variable of continuous controller
equation
  der(x) = error/T;
  y= T*der(error);
  outCtr = K * (x+error+y);
end PIDcontinuousController;

model PIDdiscreteController
  extends BaseController(K = 2, T = 10);
  discrete Real x;        // State variable of discrete controller
  discrete Real y;        // State variable of discrete controller
equation
  when sample(0, Ts) then
    x = pre(x) + error * Ts / T;
    y = T*(error-pre(error));
    outCtr = K * (x + error + y);
  end when;
end PIDdiscreteController;

model Tank
  ReadSignal     tSensor    "Connector, sensor reading tank level (m)";
  ActSignal      tActuator  "Connector, actuator controlling input flow";
  LiquidFlow     qIn        "Connector, flow (m3/s) through input valve";
  LiquidFlow     qOut       "Connector, flow (m3/s) through output valve";
  parameter Real area(unit = "m2")       =  0.5;
  parameter Real flowGain(unit = "m2/s") = 0.05;
  parameter Real minV= 0, maxV = 10;     // Limits for output valve flow
  Real           h(start = 0.0, unit = "m")   "Tank level";
 equation
  assert(minV>=0,"minV - minimum Valve level must be >= 0 ");
  der(h)      = (qIn.lflow - qOut.lflow)/area;   // Mass balance equation
  qOut.lflow  = LimitValue(minV, maxV, -flowGain*tActuator.act);
  tSensor.val = h;
end Tank;

model LiquidSource
  LiquidFlow qOut;
  parameter Real flowLevel = 0.02;
equation
  qOut.lflow = if time > 150 then 3*flowLevel else flowLevel;
end LiquidSource;

model TankHybridPID
  LiquidSource        source(flowLevel=0.02);
  PIDdiscreteController    pidDiscrete(ref=0.25);
  Tank                  tank(area=1);
equation
  connect(source.qOut, tank.qIn);
  connect(tank.tActuator, pidDiscrete.cOut );
  connect(tank.tSensor, pidDiscrete.cIn );
end TankHybridPID;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// function LimitValue
// input Real pMin;
// input Real pMax;
// input Real p;
// output Real pLim;
// algorithm
//   pLim := if p > pMax then pMax else if p < pMin then pMin else p;
// end LimitValue;
//
// Result:
// function LimitValue
//   input Real pMin;
//   input Real pMax;
//   input Real p;
//   output Real pLim;
// algorithm
//   pLim := if p > pMax then pMax else if p < pMin then pMin else p;
// end LimitValue;
//
// class TankHybridPID
//   Real source.qOut.lflow;
//   parameter Real source.flowLevel = 0.02;
//   parameter Real pidDiscrete.Ts(unit = "s") = 0.1 "Time period between discrete samples";
//   parameter Real pidDiscrete.K = 2.0 "Gain";
//   parameter Real pidDiscrete.T(unit = "s") = 10.0 "Time constant";
//   Real pidDiscrete.cIn.val;
//   Real pidDiscrete.cOut.act;
//   parameter Real pidDiscrete.ref = 0.25 "Reference level";
//   Real pidDiscrete.error "Deviation from reference level";
//   Real pidDiscrete.outCtr "Output control signal";
//   discrete Real pidDiscrete.x;
//   discrete Real pidDiscrete.y;
//   Real tank.tSensor.val;
//   Real tank.tActuator.act;
//   Real tank.qIn.lflow;
//   Real tank.qOut.lflow;
//   parameter Real tank.area(unit = "m2") = 1.0;
//   parameter Real tank.flowGain(unit = "m2/s") = 0.05;
//   parameter Real tank.minV = 0.0;
//   parameter Real tank.maxV = 10.0;
//   Real tank.h(unit = "m", start = 0.0) "Tank level";
// equation
//   source.qOut.lflow = if time > 150.0 then 3.0 * source.flowLevel else source.flowLevel;
//   when sample(0.0, pidDiscrete.Ts) then
//     pidDiscrete.x = pre(pidDiscrete.x) + pidDiscrete.error * pidDiscrete.Ts / pidDiscrete.T;
//     pidDiscrete.y = pidDiscrete.T * (pidDiscrete.error - pre(pidDiscrete.error));
//     pidDiscrete.outCtr = pidDiscrete.K * (pidDiscrete.x + pidDiscrete.error + pidDiscrete.y);
//   end when;
//   pidDiscrete.error = pidDiscrete.ref - pidDiscrete.cIn.val;
//   pidDiscrete.cOut.act = pidDiscrete.outCtr;
//   assert(tank.minV >= 0.0, "minV - minimum Valve level must be >= 0 ");
//   der(tank.h) = (tank.qIn.lflow - tank.qOut.lflow) / tank.area;
//   tank.qOut.lflow = LimitValue(tank.minV, tank.maxV, (-tank.flowGain) * tank.tActuator.act);
//   tank.tSensor.val = tank.h;
//   source.qOut.lflow = tank.qIn.lflow;
//   pidDiscrete.cOut.act = tank.tActuator.act;
//   pidDiscrete.cIn.val = tank.tSensor.val;
// end TankHybridPID;
// endResult
