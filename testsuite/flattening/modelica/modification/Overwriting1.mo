// name:     Overwriting1
// keywords: modification,equation
// status:   correct
//
// The modification does not overwrite the equation

partial class A
  Real x, u;
equation
  x = 2.0 * u;
end A;

class Overwriting1 = A(x = 5.0) annotation(__OpenModelica_commandLineOptions="-d=-newInst");

// Result:
// class Overwriting1
//   Real x = 5.0;
//   Real u;
// equation
//   x = 2.0 * u;
// end Overwriting1;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
