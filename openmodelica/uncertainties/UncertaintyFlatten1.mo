// name:     UncertaintyFlatten1
// keywords: uncertainty, distribution, uncertain
// status:   correct
//
// This is a simple test of uncertainty attributes.
//


model UncertaintyFlatten1
  input Real u=2*time+1;
  input Real u2(distribution=d,uncertain=Uncertainty.given);
  output Real y;
  Real y2(uncertain=Uncertainty.sought);
  parameter Distribution d = Distribution("normal",{0,0.1},{"my","sigma"});

  parameter String s = "normal";
  parameter Real[2] arr = {1,0.5};
  parameter String[2] sarr = {"my","sigma"};
  input Real u3(distribution=Distribution(s,arr,sarr));

  input Real u4(distribution = Distribution("normal",{3,4},{"my","sigma"}));

equation
   y=u+1+u4;
   y2 = y+u2+u3;
end UncertaintyFlatten1;
// Result:
// function Distribution "Automatically generated record constructor for Distribution"
//   input String name;
//   input Real[:] params;
//   input String[:] paramNames;
//   output Distribution res;
// end Distribution;
//
// class UncertaintyFlatten1
//   input Real u = 1.0 + 2.0 * time;
//   input Real u2(uncertainty = Uncertainty.given, distribution = Distribution(name = d.name, params = d.params, paramNames = d.params));
//   output Real y;
//   Real y2(uncertainty = Uncertainty.sought);
//   parameter String d.name = "normal" "the name of the distibution, e.g \"normal\" ";
//   parameter Real d.params[1] = 0.0 "parameter values for the specified distribution, e.g {0,0.1} for a normal distribution";
//   parameter Real d.params[2] = 0.1 "parameter values for the specified distribution, e.g {0,0.1} for a normal distribution";
//   parameter String d.paramNames[1] = "my" "the parameter names for the specified distribution, e.g {\"my\",\"sigma\"} for a normal distribution";
//   parameter String d.paramNames[2] = "sigma" "the parameter names for the specified distribution, e.g {\"my\",\"sigma\"} for a normal distribution";
//   parameter String s = "normal";
//   parameter Real arr[1] = 1.0;
//   parameter Real arr[2] = 0.5;
//   parameter String sarr[1] = "my";
//   parameter String sarr[2] = "sigma";
//   input Real u3(distribution = Distribution(name = s, params = {arr[1], arr[2]}, paramNames = {sarr[1], sarr[2]}));
//   input Real u4(distribution = Distribution(name = "normal", params = {3.0, 4.0}, paramNames = {"my", "sigma"}));
// equation
//   y = 1.0 + u + u4;
//   y2 = y + u2 + u3;
// end UncertaintyFlatten1;
// endResult
