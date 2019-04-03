// name:     Ticket4304.mo
// keywords: assert
// status:   correct
//
// Check that assert in an initial equation works
//


model Ticket4304
  Real x(start=1.0, fixed=true) = -der(x);
initial equation
  assert(time < 0.5, "Test assert");
  terminate("at initialization");
initial algorithm
  assert(time < 0.6, "Test assert");
end Ticket4304;


// Result:
// class Ticket4304
//   Real x(start = 1.0, fixed = true) = -der(x);
// initial equation
//   assert(time < 0.5, "Test assert");
//   terminate("at initialization");
// initial algorithm
//   assert(time < 0.6, "Test assert");
// end Ticket4304;
// endResult
