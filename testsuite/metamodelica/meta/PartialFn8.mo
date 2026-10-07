// name:     PartialFn8
// keywords: PartialFn
// status:  correct
//
// Using function pointers, partially evaluated functions
//

partial function Integrand
  input Real x;
  output Real y;
end Integrand;

function Sine   // Sine is a function with 3 input arguments, of which one is inherited
  extends Integrand;
  input Real A;
  input Real w;
algorithm
  y:=A*w*x;
end Sine;

function quadrature "Integrate function y=f(x) from x1 to x2"
  input Real x1;
  input Real x2;
  input Integrand integrand;
  output Real integral;
algorithm
  integral :=(x2-x1)*(integrand(x1) + integrand(x2))/2;
end quadrature;

model PartialFn8
  Real ww;
  Real area;
algorithm
  area  := 0;
  ww    := 2*time;
  area  := area + quadrature(0, 1,
                   integrand = function Sine(A=2, w=ww));  // Named argument integrand
end PartialFn8;
