// name: CevalFuncArray6
// keywords:
// status: correct
//
//

function f
  input Real x;
  output Real[3, 1] table;
protected
  Real[:] v = linspace(0, 1, 3);
algorithm
  table[:, 1] := 1.*(acos(1 .- v));
end f;

model CevalFuncArray6
  parameter Real[:, 1] table = f(1) annotation(Evaluate=true);
end CevalFuncArray6;

// Result:
// class CevalFuncArray6
//   final parameter Real table[1,1] = 0.0;
//   final parameter Real table[2,1] = 1.0471975511965979;
//   final parameter Real table[3,1] = 1.5707963267948966;
// end CevalFuncArray6;
// endResult
