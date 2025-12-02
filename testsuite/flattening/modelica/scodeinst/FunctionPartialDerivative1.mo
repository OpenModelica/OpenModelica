// name: FunctionPartialDerivative1
// keywords:
// status: correct
//

model FunctionPartialDerivative1
  function f
    input Real x;
    output Real y = x^2;
  end f;

  function df = der(f, x);

  Real y = df(0);
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end FunctionPartialDerivative1;

// Result:
// function FunctionPartialDerivative1.df = der(FunctionPartialDerivative1.f, x);
//
// class FunctionPartialDerivative1
//   Real y = FunctionPartialDerivative1.df(0.0);
// end FunctionPartialDerivative1;
// endResult
