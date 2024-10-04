// name: EvaluateFalse1
// keywords:
// status: correct
//

model EvaluateFalse1
  constant Real a = 5.0;
  parameter Real x = 2.0 annotation(Evaluate = false);
  parameter Real y = 3.0;
  Real z;
equation
  if x < a then
    z = 15 *y;
  else
    z = 10 * y;
  end if;
end EvaluateFalse1;

// Result:
// class EvaluateFalse1
//   constant Real a = 5.0;
//   parameter Real x = 2.0;
//   parameter Real y = 3.0;
//   Real z;
// equation
//   if x < 5.0 then
//     z = 15.0 * y;
//   else
//     z = 10.0 * y;
//   end if;
// end EvaluateFalse1;
// endResult
