// name:     RedeclareRecordComponent1
// keywords: redeclare record binding #3467
// status:   correct
//
// Checks that redeclares of record components are handled correctly.
//

model RedeclareRecordComponent1
  record R
    replaceable Real x;
  end R;

  type MyReal = Real(quantity = "fish");
  record R2 = R(redeclare MyReal x);

  R2 r = R2(x = 1.0);
end RedeclareRecordComponent1;

// Result:
// function RedeclareRecordComponent1.R2 "Automatically generated record constructor for RedeclareRecordComponent1.R2"
//   input Real x(quantity = "fish");
//   output R2 res;
// end RedeclareRecordComponent1.R2;
//
// class RedeclareRecordComponent1
//   Real r.x(quantity = "fish") = 1.0;
// end RedeclareRecordComponent1;
// endResult
