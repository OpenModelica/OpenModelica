// name:     ArrayEWOps6
// keywords: array
// status:   correct
//
// Tests various array operators.

function f
  input Real x[2, 1];
  output Real y[9];
protected
  Real c[2, 1];
  Real s[1, 2] = [1, 2];
  Real z[9];
algorithm
  for i in 1:3 loop
    for j in 1:3 loop
      c := [i; j];
      z[(i-1)*3+j] := scalar(exp(-((1.0 ./ s) .^ 2) * ((x - c) .^ 2)));
    end for;
  end for;

  y := z / sum(z);
end f;

class ArrayEWOps6
  Real x[9] = f([1; 2]);
end ArrayEWOps6;

// Result:
// function f
//   input Real[2, 1] x;
//   output Real[9] y;
//   protected Real[2, 1] c;
//   protected Real[1, 2] s = {{1.0, 2.0}};
//   protected Real[9] z;
// algorithm
//   for i in 1:3 loop
//     for j in 1:3 loop
//       c := {{/*Real*/(i)}, {/*Real*/(j)}};
//       z[3 * (-1 + i) + j] := exp((-((x[1,1] - c[1,1]) / s[1,1]) ^ 2.0) - ((x[2,1] - c[2,1]) / s[1,2]) ^ 2.0);
//     end for;
//   end for;
//   y := {z[1] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[2] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[3] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[4] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[5] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[6] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[7] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[8] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9]), z[9] / (z[1] + z[2] + z[3] + z[4] + z[5] + z[6] + z[7] + z[8] + z[9])};
// end f;
//
// class ArrayEWOps6
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real x[6];
//   Real x[7];
//   Real x[8];
//   Real x[9];
// equation
//   x = {0.21966918422987414, 0.2820608158142204, 0.21966918422987414, 0.0808117767370727, 0.10376437529809651, 0.0808117767370727, 0.004023381453337195, 0.005166124047115023, 0.004023381453337195};
// end ArrayEWOps6;
// endResult
