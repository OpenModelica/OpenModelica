// name: FunctionUnitialized1
// keywords:
// status: correct
//
//

model FunctionUnitialized1
  Real y = f(time);
  function f
    input Real x;
    output Real y;
  protected
    Real z;
  algorithm
     y := z + x + y;
     y := y + 1;
  end f;
end FunctionUnitialized1;

// Result:
// function FunctionUnitialized1.f
//   input Real x;
//   output Real y;
//   protected Real z;
// algorithm
//   y := z + x + y;
//   y := y + 1.0;
// end FunctionUnitialized1.f;
//
// class FunctionUnitialized1
//   Real y = FunctionUnitialized1.f(time);
// end FunctionUnitialized1;
// [flattening/modelica/scodeinst/FunctionUnitialized1.mo:15:6-15:20:writable] Warning: z was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [flattening/modelica/scodeinst/FunctionUnitialized1.mo:15:6-15:20:writable] Warning: y was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
//
// endResult
