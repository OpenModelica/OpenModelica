// status: correct
// bug #2525

model InitialReduction
  parameter Integer n = 10;
  Real T[n];
initial equation
  T = linspace(200, 300, n);
equation
  for i loop
    der(T[i]) = 1;
  end for;
end InitialReduction;

// Result:
// class InitialReduction
//   parameter Integer n = 10;
//   Real T[1];
//   Real T[2];
//   Real T[3];
//   Real T[4];
//   Real T[5];
//   Real T[6];
//   Real T[7];
//   Real T[8];
//   Real T[9];
//   Real T[10];
// initial equation
//   T[1] = 200.0;
//   T[2] = 211.1111111111111;
//   T[3] = 222.2222222222222;
//   T[4] = 233.3333333333333;
//   T[5] = 244.4444444444445;
//   T[6] = 255.5555555555555;
//   T[7] = 266.6666666666666;
//   T[8] = 277.7777777777778;
//   T[9] = 288.8888888888889;
//   T[10] = 300.0;
// equation
//   der(T[1]) = 1.0;
//   der(T[2]) = 1.0;
//   der(T[3]) = 1.0;
//   der(T[4]) = 1.0;
//   der(T[5]) = 1.0;
//   der(T[6]) = 1.0;
//   der(T[7]) = 1.0;
//   der(T[8]) = 1.0;
//   der(T[9]) = 1.0;
//   der(T[10]) = 1.0;
// end InitialReduction;
// endResult
