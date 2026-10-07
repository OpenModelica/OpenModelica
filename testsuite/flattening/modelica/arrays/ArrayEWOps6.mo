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
// [flattening/modelica/arrays/ArrayEWOps6.mo:26:3-26:24:writable] Warning: Components are deprecated in class.
//
// endResult
