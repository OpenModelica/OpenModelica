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

model PackageConstant3
  Real x = P.r[1].x;
end PackageConstant3;

// Result:
// function P.ext_func
//   output Real x;
//
//   external "C" x = ext_func();
// end P.ext_func;
//
// class PackageConstant3
//   parameter Real P.r[1].x = P.ext_func();
//   parameter Real P.r[2].x = P.ext_func();
//   parameter Real P.r[3].x = P.ext_func();
//   Real x = P.r[1].x;
// end PackageConstant3;
// endResult
