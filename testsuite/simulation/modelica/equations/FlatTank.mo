// name:     FlatTank
// keywords: <insert keywords here>
// status:   correct
//
// Drmodelica: 12.1 Traditional Methodology (p. 385)
//

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

model FlatTank
 // Tank related variables and parameters
  parameter Real flowLevel(unit = "m3/s") = 0.02;
  parameter Real area(unit = "m2")        = 1;
  parameter Real flowGain(unit = "m2/s")  = 0.05;
  Real           h(start = 0, unit = "m")     "Tank level";
  Real           qInflow(unit = "m3/s")       "Flow through input valve";
  Real           qOutflow(unit = "m3/s")      "Flow through output valve";

 // Controller related variables and parameters
  parameter Real K = 2                     "Gain";
  parameter Real T(unit = "s")  = 10       "Time constant";
  parameter Real minV = 0,  maxV = 10;  // Limits for flow output
  Real           ref = 0.25                "Reference level for control";
  Real           error                     "Deviation from reference level";
  Real           outCtr                    "Control signal without limiter";
  Real           x                         "State variable for controller";

equation
  assert(minV>=0, "minV must be greater or equal to zero");
  der(h)   = (qInflow - qOutflow)/area;           // Mass balance equation
  qInflow    = if time > 150 then 3*flowLevel else flowLevel;
  qOutflow   = limitValue(minV, maxV, -flowGain*outCtr);
  error    = ref - h;
  der(x)   = error/T;
  outCtr   = K*(error + x);
end FlatTank;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class FlatTank
// parameter Real flowLevel(unit = "m3/s") = 0.02;
// parameter Real area(unit = "m2") = 1;
// parameter Real flowGain(unit = "m2/s") = 0.05;
// Real h(unit = "m", start = 0.0) "Tank level";
// Real qInflow(unit = "m3/s") "Flow through input valve";
// Real qOutflow(unit = "m3/s") "Flow through output valve";
// parameter Real K = 2 "Gain";
// parameter Real T(unit = "s") = 10 "Time constant";
// parameter Real minV = 0;
// parameter Real maxV = 10;
// Real ref "Reference level for control";
// Real error "Deviation from reference level";
// Real outCtr "Control signal without limiter";
// Real x "State variable for controller";
// equation
//   ref = 0.25;
// assert(minV >= 0.0,"minV must be greater or equal to zero");
//   der(h) = (qInflow - qOutflow) / area;
//   qInflow = if time > 150.0 then 3.0 * flowLevel else flowLevel;
//   qOutflow = limitValue(minV,maxV,(-flowGain) * outCtr);
//   error = ref - h;
//   der(x) = error / T;
//  outCtr = K * (error + x);
// end FlatTank;
