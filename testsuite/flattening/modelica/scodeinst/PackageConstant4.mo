// name: PackageConstant4
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  record R
    Real x;
  end R;

  parameter R r1(x = ext_func());
  parameter R r2[1] = {r1};

  function ext_func
    output Real x;

    external "C";
  end ext_func;
end P;

model PackageConstant4
  Real x = P.r2[1].x;
end PackageConstant4;

// Result:
// function P.ext_func
//   output Real x;
//
//   external "C" x = ext_func();
// end P.ext_func;
//
// class PackageConstant4
//   parameter Real P.r1.x = P.ext_func();
//   parameter Real P.r2[1].x = P.r1.x;
//   Real x = P.r2[1].x;
// end PackageConstant4;
// endResult
