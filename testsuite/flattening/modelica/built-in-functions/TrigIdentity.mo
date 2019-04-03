// name: TrigIdentity
// status: correct

model TrigIdentity
  Real x = sin(time)^2 + cos(time)^2;
  Real y = sin(asin(time));
  Real z = 2*sin(time)*cos(time);
end TrigIdentity;

// Result:
// class TrigIdentity
//   Real x = 1.0;
//   Real y = sin(asin(time));
//   Real z = sin(2.0 * time);
// end TrigIdentity;
// endResult
