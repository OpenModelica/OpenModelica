// name:     Derivative1
// keywords: functions,index reduction
// status:   correct
//
// This demonstrates the use of the derivative annotation
// in order to allow index reduction to work.
// Note that the non-real input must be a parameter
// to guarantee that there are no missed discontinuities.
// The solution has x=u.

package FooFunctions
function foo0
  annotation(derivative=foo1);
  input Real x;
  input Boolean b;
  output Real y;
algorithm
  if b then
    y:=sin(x);
  else
    y:=x;
  end if;
end foo0;

function foo1
  annotation(derivative(order=1)=foo2);
  input Real x;
  input Boolean b;
  input Real der_x;
  output Real der_y;
algorithm
  if b then
    der_y:=cos(x)*der_x;
  else
    der_y:=der_x;
  end if;
end foo1;

function foo2
  input Real x;
  input Boolean b;
  input Real der_x;
  input Real der_2_x;
  output Real der_2_y;
algorithm
  if b then
    der_2_y:=cos(x)*der_2_x-sin(x)*der_x*der_x;
  else
    der_2_y:=der_2_x;
  end if;
end foo2;
end FooFunctions;

model Derivative1
  Real x[3];
  Real u[3](each fixed=false);
  type IC=Real(start=0,fixed=true);
  IC ic[2]=x[1:2]-u[1:2];
  parameter Boolean b=true;
equation
  x[1]=FooFunctions.foo0(exp(time),b);
  der(x[1:2])=x[2:3];
  x[3]=u[3];
  der(u[1:2])=u[2:3];
end Derivative1;

// Result:
// function FooFunctions.foo0
//   input Real x;
//   input Boolean b;
//   output Real y;
// algorithm
//   if b then
//     y := sin(x);
//   else
//     y := x;
//   end if;
// end FooFunctions.foo0;
//
// function FooFunctions.foo1
//   input Real x;
//   input Boolean b;
//   input Real der_x;
//   output Real der_y;
// algorithm
//   if b then
//     der_y := cos(x) * der_x;
//   else
//     der_y := der_x;
//   end if;
// end FooFunctions.foo1;
//
// function FooFunctions.foo2
//   input Real x;
//   input Boolean b;
//   input Real der_x;
//   input Real der_2_x;
//   output Real der_2_y;
// algorithm
//   if b then
//     der_2_y := cos(x) * der_2_x - sin(x) * der_x ^ 2.0;
//   else
//     der_2_y := der_2_x;
//   end if;
// end FooFunctions.foo2;
//
// class Derivative1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real u[1](fixed = false);
//   Real u[2](fixed = false);
//   Real u[3](fixed = false);
//   Real ic[1](start = 0.0, fixed = true);
//   Real ic[2](start = 0.0, fixed = true);
//   parameter Boolean b = true;
// equation
//   ic = {x[1] - u[1], x[2] - u[2]};
//   x[1] = FooFunctions.foo0(exp(time), b);
//   der(x[1]) = x[2];
//   der(x[2]) = x[3];
//   x[3] = u[3];
//   der(u[1]) = u[2];
//   der(u[2]) = u[3];
// end Derivative1;
// endResult
