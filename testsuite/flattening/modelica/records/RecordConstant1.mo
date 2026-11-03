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
// class RecordConstant1
//   constant Real r2 = 2.0;
// end RecordConstant1;
// endResult
