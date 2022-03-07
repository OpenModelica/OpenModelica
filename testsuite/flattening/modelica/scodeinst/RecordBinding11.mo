// name: RecordBinding11
// keywords:
// status: correct
// cflags: -d=newInst
//

package PartialMedium
  constant Real h_default = setState_pTX();

  function setState_pTX
    output Real state;
  algorithm
    state := f();
  end setState_pTX;

  record Coefficients
    constant Real[:, 4] res = ones(3, 4);
  end Coefficients;

  constant Coefficients coefficients;

  function f
    output Real delta;
  protected
    final constant Integer nRes = size(coefficients.res, 1);
    final constant Real[nRes, 4] b = coefficients.res;
  algorithm
    delta := sum(b[1, i] for i in 1:nRes);
  end f;
end PartialMedium;

model RecordBinding11
  parameter Real h_start = PartialMedium.h_default;
end RecordBinding11;

// Result:
// class RecordBinding11
//   parameter Real h_start = 3.0;
// end RecordBinding11;
// endResult
