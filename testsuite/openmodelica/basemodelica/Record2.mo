// name: Record2
// status: correct
// cflags: -d=newInst -f

model Record2
  record R
    Real x;
    Real y;
  end R;

  R r1(x(start = 1), y(start = 2));
  R r2(x(start = 3), y(start = 4));
  R r3(x(start = 5));
  R r4(y(start = 6));
  R r5;
  R r6(x(start = 1.0)) = R(1.0, 2.0);
equation
  r1 = R(0,0);
  r2 = R(0,0);
end Record2;

// Result:
// package 'Record2'
//   record 'R'
//     Real 'x';
//     Real 'y';
//   end 'R';
//
//   model 'Record2'
//     'R' 'r1'('x'(start = 1.0), 'y'(start = 2.0));
//     'R' 'r2'('x'(start = 3.0), 'y'(start = 4.0));
//     'R' 'r3'('x'(start = 5.0));
//     'R' 'r4'('y'(start = 6.0));
//     'R' 'r5';
//     'R' 'r6'('x'(start = 1.0)) = 'R'(1.0, 2.0);
//   equation
//     'r1' = 'R'(0.0, 0.0);
//     'r2' = 'R'(0.0, 0.0);
//   end 'Record2';
// end 'Record2';
// endResult
