// name: IfEquationEval5
// keywords:
// status: correct
//

model IfEquationEval5
  parameter Integer N = 2;
  parameter Boolean simplified = false;
  parameter Boolean optional = false;
  Real x[N];
  Real y;
  Real z = cos(y) if optional;
equation
  for i in 1:N loop
    x[i] = time*i;
  end for;
  if simplified then
    y = time;
  else
    y = sin(time)*cos(1 - time);
  end if;
  annotation(__OpenModelica_commandLineOptions="--evaluateStructuralParameters=strictlyNecessary");
end IfEquationEval5;

// Result:
// class IfEquationEval5
//   final parameter Integer N = 2;
//   parameter Boolean simplified = false;
//   final parameter Boolean optional = false;
//   Real x[1];
//   Real x[2];
//   Real y;
// equation
//   x[1] = time;
//   x[2] = time * 2.0;
//   if simplified then
//     y = time;
//   else
//     y = sin(time) * cos(1.0 - time);
//   end if;
// end IfEquationEval5;
// endResult
