// name:     FuncDer
// keywords: Function Annotations
// status:   correct
//
// Something wrong with Boolean and  der_2_y := exp(x)*der_x*der_x + exp(x)*der_2_x; in h2
// Drmodelica: 11.1 Function Annotations (p. 372)
//

function h0                 // exp(x(t)+i1)
  annotation(derivative=h1);
  input  Integer i1;
  input  Real    x;
  input  Boolean linear;        // not used
  output Real    y;
 algorithm
  y := exp(x)+i1;
end h0;

function h1                 // (d/dt)(exp(x(t))
  annotation(derivative(order=2)=h2);
  input  Integer i1;
  input  Real    x;
  input  Boolean linear;
  input  Real    der_x;
  output Real    der_y;
algorithm
  der_y := exp(x)*der_x;
end h1;

function h2                 // (d/dt)(exp(x(t)*der_x(t))
  input  Integer i1;
  input  Real    x;
  input  Boolean linear;
  input  Real    der_x;
  input  Real    der_2_x;
  output Real    der_2_y;
algorithm
  der_2_y := exp(x)*der_x*der_x + exp(x)*der_2_x;
end h2;

// added by x06klasj
model FuncDer
  Real fn0;
  Real fn1;
  Real fn2;
algorithm
  fn0 := h0(2,5,true);
  fn1 := h1(2,5,true,fn0);
  fn2 := h2(2,5,true,fn0,fn1);
end FuncDer;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// Result:
// function h0
//   input Integer i1;
//   input Real x;
//   input Boolean linear;
//   output Real y;
// algorithm
//   y := exp(x) + /*Real*/(i1);
// end h0;
//
// function h1
//   input Integer i1;
//   input Real x;
//   input Boolean linear;
//   input Real der_x;
//   output Real der_y;
// algorithm
//   der_y := exp(x) * der_x;
// end h1;
//
// function h2
//   input Integer i1;
//   input Real x;
//   input Boolean linear;
//   input Real der_x;
//   input Real der_2_x;
//   output Real der_2_y;
// algorithm
//   der_2_y := exp(x) * (der_x ^ 2.0 + der_2_x);
// end h2;
//
// class FuncDer
//   Real fn0;
//   Real fn1;
//   Real fn2;
// algorithm
//   fn0 := 150.4131591025766;
//   fn1 := h1(2, 5.0, true, fn0);
//   fn2 := h2(2, 5.0, true, fn0, fn1);
// end FuncDer;
// endResult
