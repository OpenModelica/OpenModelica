// name: Record3
// status: correct
// cflags: -d=newInst -f

package P
  record R
    Real x;
    Real y;
  end R;

  record R2 = R;
end P;

model Record3
  record R3 = P.R2;
  P.R2 r1;
  R3 r2;
equation
  r1 = P.R2(0,0);
  r2 = R3(0,0);
end Record3;

// Result:
// //! base 0.1.0
// package 'Record3'
//   record 'P.R2'
//     Real 'x';
//     Real 'y';
//   end 'P.R2';
//
//   record 'R3'
//     Real 'x';
//     Real 'y';
//   end 'R3';
//
//   model 'Record3'
//     'P.R2' 'r1';
//     'R3' 'r2';
//   equation
//     'r1' = 'P.R2'(0.0, 0.0);
//     'r2' = 'R3'(0.0, 0.0);
//   end 'Record3';
// end 'Record3';
// endResult
