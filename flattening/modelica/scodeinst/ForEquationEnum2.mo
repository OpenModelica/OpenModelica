// name: ForEquationEnum2.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquationEnum2
  type E = enumeration(one, two, three);
  E x[E];
equation
  for i in E.one:E.three loop
    x[i] = i;
  end for;
end ForEquationEnum2;

// Result:
// class ForEquationEnum2
//   enumeration(one, two, three) x[E.one];
//   enumeration(one, two, three) x[E.two];
//   enumeration(one, two, three) x[E.three];
// equation
//   x[E.one] = E.one;
//   x[E.two] = E.two;
//   x[E.three] = E.three;
// end ForEquationEnum2;
// endResult
