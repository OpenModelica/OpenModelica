within ;
package DerivativeOfInput "Models that need derivatives of top-level inputs, see #9802"
  model Alias "Inverse of a first-order filter, y is an alias of the input"
    input Real u_top;
    Real u;
    Real y;
    parameter Real tau = 1;
  equation
    tau*der(y) + y = u;
    y = u_top;
  end Alias;

  model NegatedAliasChain
    input Real u_top;
    Real u, y, z;
  equation
    der(y) + y = u;
    y = z;
    z = -u_top;
  end NegatedAliasChain;

  model IndexReduction "y is no alias, the input is differentiated by index reduction"
    input Real u_top;
    Real u, y;
  equation
    der(y) + y = u;
    y = 2*u_top;
  end IndexReduction;

  model SecondDerivative "Inverse of a second-order filter"
    input Real u_top;
    Real u, x1, x2;
  equation
    der(x1) = x2;
    der(x2) = -x1 - x2 + u;
    x1 = u_top;
  end SecondDerivative;

  model DerOfExpression
    input Real u_top;
    Real y;
  equation
    y = der(2*u_top);
  end DerOfExpression;

  model NoDerivative "No derivative of the input is needed"
    input Real u_top;
    Real x, y;
  equation
    der(x) = -x + y;
    y = u_top;
  end NoDerivative;

  model Feedthrough "The output depends on the input, its derivative on der(u)"
    input Real u;
    output Real y;
    Real x(start = 0, fixed = true);
  equation
    der(x) = -x + u;
    y = x + 2*u;
  end Feedthrough;

  model InverseWithOutput "Needs der(u_top) for the dynamics, not only for der(y)"
    input Real u_top;
    output Real u;
    Real y;
  equation
    der(y) + y = u;
    y = u_top;
  end InverseWithOutput;
end DerivativeOfInput;
