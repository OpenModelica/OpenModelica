// name: PackageConstant3
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  record R
    Real x = ext_func();
  end R;

  parameter R r[3];

  function ext_func
    output Real x;

    external "C";
  end ext_func;
end P;

model M
  Real x = P.r[1].x;
end M;

// Result:
// class M
//   parameter Real P.r[1].x = P.ext_func();
//   parameter Real P.r[2].x = P.ext_func();
//   parameter Real P.r[3].x = P.ext_func();
//   Real x = P.r[1].x;
// end M;
// endResult
