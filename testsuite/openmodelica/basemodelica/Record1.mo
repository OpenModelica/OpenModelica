// name: Record1
// status: correct

model Record1
  record R
    Real x;
    Real y;
    final constant Integer n = 3;
  end R;

  R r1(x(start = 1)=1, y(start = 2));
  R r2(x(start = 3), y(start = 4));
equation
  r1 = R(0,0);
  r2 = R(0,0);
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Record1;

// Result:
// //! base 0.1.0
// package 'Record1'
//   record 'R'
//     Real 'x';
//     Real 'y';
//     final constant Integer 'n' = 3;
//   end 'R';
//
//   model 'Record1'
//     'R' 'r1'('x'(start = 1.0) = 1.0, 'y'(start = 2.0));
//     'R' 'r2'('x'(start = 3.0), 'y'(start = 4.0));
//   equation
//     'r1' = 'R'(0.0, 0.0, 3);
//     'r2' = 'R'(0.0, 0.0, 3);
//   end 'Record1';
// end 'Record1';
// endResult
