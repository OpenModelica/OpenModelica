// name: FunctionUnitialized8
// keywords:
// status: correct
//
// Checks that the compiler doesn't complain about uninitialized variables in
// functions that aren't called in the flat model.
//

function f
  input Real x;
  output Real y; // Uninitialized output
end f;

function f2
  input Real x;
  output Real y;
protected
  Real z; // Uninitialized local variable
algorithm
  y := x * z;
end f2;

function f3
  input Real x;
  output Real y = x;
end f3;

model FunctionUnitialized8
  parameter Boolean b = true annotation(Evaluate=true);
  Real x = if b then f3(time) else f(time);
  Real y = if b then f3(time) else f2(time);
end FunctionUnitialized8;

// Result:
// function f3
//   input Real x;
//   output Real y = x;
// end f3;
//
// class FunctionUnitialized8
//   final parameter Boolean b = true;
//   Real x = f3(time);
//   Real y = f3(time);
// end FunctionUnitialized8;
// endResult
