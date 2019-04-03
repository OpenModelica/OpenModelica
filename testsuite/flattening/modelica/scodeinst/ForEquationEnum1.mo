// name: ForEquationEnum1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model ForEquationEnum1
  type E = enumeration(one, two, three);
  E x[E];
equation
  for i in E loop
    x[i] = i;
  end for;
end ForEquationEnum1;

// Result:
// class ForEquationEnum1
//   enumeration(one, two, three) x[E.one];
//   enumeration(one, two, three) x[E.two];
//   enumeration(one, two, three) x[E.three];
// equation
//   x[E.one] = E.one;
//   x[E.two] = E.two;
//   x[E.three] = E.three;
// end ForEquationEnum1;
// endResult
