// name:     Ticket4276b.mo
// keywords: declaration
// status:   correct
//
// Check that you can assign to parameter(fixed=false)
//


model Ticket4276b
  parameter Real a(fixed=false);
  Real x;
  
  impure function f
    input Real t;
    output Real a;
    output Real b;
  algorithm
    a := t;
    b := t;
  end f;
initial algorithm
  (a, x) := f(2);
equation
  x = 1;
end Ticket4276b;


// Result:
// impure function Ticket4276b.f
//   input Real t;
//   output Real a;
//   output Real b;
// algorithm
//   a := t;
//   b := t;
// end Ticket4276b.f;
//
// class Ticket4276b
//   parameter Real a(fixed = false);
//   Real x;
// initial algorithm
//   (a, x) := Ticket4276b.f(2.0);
// equation
//   x = 1.0;
// end Ticket4276b;
// endResult
