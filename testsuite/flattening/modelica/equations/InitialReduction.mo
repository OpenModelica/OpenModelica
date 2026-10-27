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
//   final parameter Integer n = 10;
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
//   T = array(200.0 + 100.0 * (/*Real*/(i) - 1.0) / 9.0 for i in 1:10);
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
