// name:     Cat1
// keywords: cat
// status:   correct
//
// Tests the builtin cat operator.
//

type MyType = enumeration(divisionType1,divisionType2);

partial model myPartialModel
  parameter Integer n (min = 1) = 2;
  parameter MyType myDivision = MyType.divisionType1;
  parameter Real[n] x;
  parameter Real[n] y;
  Real[n] z;
equation
  for i in 1:n loop
    z[i] = x[i] * y[i];
  end for;
end myPartialModel;

model Cat1
  parameter Real a(fixed = false);
  parameter Real b(fixed = false);

  final parameter Real[n] aDivisions = if n == 1 then {a} else fill(a/n, n);
  final parameter Real[n] bDivisions =
    if n == 1 then {b}
    elseif myDivision == MyType.divisionType1 then cat(1, {b/(n-1)/2}, fill(b/(n-1), n-2), {b/(n-1)/2})
    else fill(b/n, n);
  extends myPartialModel(final x = aDivisions,
                         final y = bDivisions);

end Cat1;

// Result:
// class Cat1
//   parameter Real a(fixed = false);
//   parameter Real b(fixed = false);
//   final parameter Real aDivisions[1] = a / 2.0;
//   final parameter Real aDivisions[2] = a / 2.0;
//   final parameter Real bDivisions[1] = b / 2.0;
//   final parameter Real bDivisions[2] = b / 2.0;
//   final parameter Integer n(min = 1) = 2;
//   parameter enumeration(divisionType1, divisionType2) myDivision = MyType.divisionType1;
//   final parameter Real x[1] = aDivisions[1];
//   final parameter Real x[2] = aDivisions[2];
//   final parameter Real y[1] = bDivisions[1];
//   final parameter Real y[2] = bDivisions[2];
//   Real z[1];
//   Real z[2];
// equation
//   z[1] = x[1] * y[1];
//   z[2] = x[2] * y[2];
// end Cat1;
// endResult
