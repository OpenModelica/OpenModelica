// name: FuncBuiltinScalar2
// keywords: scalar
// status: correct
// cflags: -d=newInst
//
// Tests the builtin scalar operator.
//

model FuncBuiltinScalar2
  function f
    input Real u[:];
    output Real y = n;
  protected
    Integer n = scalar(size(u)) - 1;
  end f;

  Real x[1] = {1};
  Real y = f(x);
end FuncBuiltinScalar2;

// Result:
// function FuncBuiltinScalar2.f
//   input Real[:] u;
//   output Real y = /*Real*/(n);
//   protected Integer n = size(u, 1) - 1;
// end FuncBuiltinScalar2.f;
//
// class FuncBuiltinScalar2
//   Real x[1];
//   Real y = FuncBuiltinScalar2.f(x);
// equation
//   x = {1.0};
// end FuncBuiltinScalar2;
// endResult
