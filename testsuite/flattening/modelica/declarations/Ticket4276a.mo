// name:     Ticket4276a.mo
// keywords: declaration
// status:   incorrect
//
// Check that you cannot assign to parameter(fixed=true)
//


model Ticket4276a
  parameter Real a(fixed=true);
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
end Ticket4276a;


// Result:
// Error processing file: Ticket4276a.mo
// [flattening/modelica/declarations/Ticket4276a.mo:22:3-22:17:writable] Error: Trying to assign to parameter component a(fixed=true) in (a, x) := Ticket4276a.f(2.0)
// Error: Error occurred while flattening model Ticket4276a
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
