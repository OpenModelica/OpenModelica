// name: ArrayBoundsEq2
// keywords:
// status: correct
//

model ArrayBoundsEq2
  Real x[2] = ones(2);
  Real y;
equation
  if y >= 3 then
    y = x[3];
  else
    y = x[2];
  end if;
end ArrayBoundsEq2;

// Result:
// class ArrayBoundsEq2
//   Real x[1];
//   Real x[2];
//   Real y;
// equation
//   x = {1.0, 1.0};
//   if y >= 3.0 then
//     y = x[3];
//   else
//     y = x[2];
//   end if;
// end ArrayBoundsEq2;
// endResult
