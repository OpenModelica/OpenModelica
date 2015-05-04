model UnevaluateableFixedAttribute
  parameter Boolean preferredStates=true;
  parameter Boolean preferredStatesUnfixed(fixed=false);
  parameter Boolean preferredStatesUnfixedStart(fixed=false,start=true);
  Real x(fixed = preferredStates);
  Real y(fixed = preferredStatesUnfixed);
  Real z(fixed = preferredStatesUnfixedStart);
initial equation
  preferredStatesUnfixed = true;
  preferredStatesUnfixedStart = false;
equation
  der(z) = time;
  0 = x + z^2;
  y = x + z;
end UnevaluateableFixedAttribute;
