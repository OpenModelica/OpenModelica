// name: FunctionUnitialized7
// keywords:
// status: correct
//
// Checks that the compiler doesn't complain about uninitialized outputs in a
// function that will never return.
//

function f
  input Real x;
  output Real y;
protected
  Real z;
algorithm
  assert(false, "This function shouldn't be called");
  y := z * x;
end f;

model FunctionUnitialized7
  Real x = f(time);
end FunctionUnitialized7;

// Result:
// function f
//   input Real x;
//   output Real y;
//   protected Real z;
// algorithm
//   assert(false, "This function shouldn't be called");
//   y := z * x;
// end f;
//
// class FunctionUnitialized7
//   Real x = f(time);
// end FunctionUnitialized7;
// endResult
