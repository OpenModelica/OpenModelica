// name:     ArrayEWOps7
// keywords: array
// status:   correct
//
// Checks that .* becomes * when scalarized.

model ArrayEWOps7
  parameter Real Delta_x[3] = {0.5, 0.25, 0.15};
  final parameter Real mass = sum({1, 2, 3}.*(2*Delta_x));
end ArrayEWOps7;

// Result:
// class ArrayEWOps7
//   parameter Real Delta_x[1] = 0.5;
//   parameter Real Delta_x[2] = 0.25;
//   parameter Real Delta_x[3] = 0.15;
//   final parameter Real mass = 2.0 * Delta_x[1] + 2.0 * 2.0 * Delta_x[2] + 3.0 * 2.0 * Delta_x[3];
// end ArrayEWOps7;
// endResult
