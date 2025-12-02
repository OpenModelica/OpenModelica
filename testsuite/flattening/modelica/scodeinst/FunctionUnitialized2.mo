// name: FunctionUnitialized2
// keywords:
// status: correct
//
//

model FunctionUnitialized2
  Real y = f(time);

  function f
    input Real x;
    output Real y;
  protected
    Real z, w, u;
  algorithm
    if x > 1 then
      z := 0;
    else
      u := 1;
    end if;

    y := z + w + u;
  end f;
end FunctionUnitialized2;

// Result:
// function FunctionUnitialized2.f
//   input Real x;
//   output Real y;
//   protected Real z;
//   protected Real w;
//   protected Real u;
// algorithm
//   if x > 1.0 then
//     z := 0.0;
//   else
//     u := 1.0;
//   end if;
//   y := z + w + u;
// end FunctionUnitialized2.f;
//
// class FunctionUnitialized2
//   Real y = FunctionUnitialized2.f(time);
// end FunctionUnitialized2;
// [flattening/modelica/scodeinst/FunctionUnitialized2.mo:22:5-22:19:writable] Warning: w was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
//
// endResult
