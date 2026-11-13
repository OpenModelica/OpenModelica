// name:     HelloWorld
// keywords: equation
// status:   correct
//
// Equation handling
// Drmodelica: 2.1 Hello World (p. 19)
//

model HelloWorld
  Real x(start = 1);
  parameter Real a = 1;
equation
  der(x) = - a * x;
end HelloWorld;

// class HelloWorld
// Real x(start = 1.0);
// parameter Real a = 1;
// equation
//    der(x) = (-a) * x;
// end HelloWorld;
