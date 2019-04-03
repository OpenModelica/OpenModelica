model ModifierVariabilityErrorParam
  Real x;
  parameter Real y = x;
end ModifierVariabilityErrorParam;

model ModifierVariabilityErrorVar
  Real x;
  Real y(start = x);
end ModifierVariabilityErrorVar;
