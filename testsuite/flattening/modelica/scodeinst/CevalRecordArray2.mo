// name: CevalRecordArray2
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  record R
    Real x = 1.0;
    Real y = 2.0;
    Real z = 3.0;
  end R;

  constant R r[2];

  function f
    input Real x;
    output Real y;
  algorithm
    y := x * r[2].y;
  end f;
end P;


model CevalRecordArray2
  Real x = P.f(1.0);
end CevalRecordArray2;

// Result:
// class CevalRecordArray2
//   Real x = 2.0;
// end CevalRecordArray2;
// endResult
