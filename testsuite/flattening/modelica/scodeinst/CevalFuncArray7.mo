// name: CevalFuncArray7
// keywords:
// status: correct
//
//

function f
  input Real value;
  output Real result[2,2,1] = fill(0,2,2,1);
algorithm
  result[2,1,1] := value;
end f;

model CevalFuncArray7
  parameter Real value = 4.32e-3 annotation(Evaluate=true);
  parameter Real result[2,2,1] = f(value);
end CevalFuncArray7;

// Result:
// class CevalFuncArray7
//   final parameter Real value = 0.00432;
//   parameter Real result[1,1,1] = 0.0;
//   parameter Real result[1,2,1] = 0.0;
//   parameter Real result[2,1,1] = 0.00432;
//   parameter Real result[2,2,1] = 0.0;
// end CevalFuncArray7;
// endResult
