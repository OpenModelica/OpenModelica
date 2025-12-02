// name: ImplicitRangeType2
// keywords:
// status: correct
//
//

model ImplicitRangeType2
  type E = enumeration(one, two, fish);
  Real x[E];
equation
  for i loop
    x[i] = 1;
  end for;
end ImplicitRangeType2;

// Result:
// class ImplicitRangeType2
//   Real x[E.one];
//   Real x[E.two];
//   Real x[E.fish];
// equation
//   x[E.one] = 1.0;
//   x[E.two] = 1.0;
//   x[E.fish] = 1.0;
// end ImplicitRangeType2;
// endResult
