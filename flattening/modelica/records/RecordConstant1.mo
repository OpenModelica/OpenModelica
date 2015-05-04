// name:     RecordConstant1
// keywords: record, constant
// status:   correct
//
// Checks that it's possible to look up components through record constants.
//

package P
  record R
    Real r;
  end R;

  constant R cr(r = 2.0);
end P;

model RecordConstant1
  constant Real r2 = P.cr.r;
end RecordConstant1;

// Result:
// function P.R "Automatically generated record constructor for P.R"
//   input Real r;
//   output R res;
// end P.R;
//
// function P.R$cr "Automatically generated record constructor for P.R$cr"
//   input Real r;
//   output R$cr res;
// end P.R$cr;
//
// class RecordConstant1
//   constant Real r2 = 2.0;
// end RecordConstant1;
// endResult
