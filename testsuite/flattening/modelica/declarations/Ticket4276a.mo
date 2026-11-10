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
// [flattening/modelica/declarations/Ticket4276a.mo:10:3-10:31:writable] Error: Parameter a has neither value nor start value, and is fixed during initialization (fixed=true).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
