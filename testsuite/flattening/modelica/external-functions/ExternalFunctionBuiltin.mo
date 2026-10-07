// name: ExternalFunctionBuiltin
// status: correct
//
// MSL 3.2 started defining sin,cos,etc as external "builtin"
// This tests that such definitions work correctly

class ExternalFunctionBuiltin
  function sin
    input Real r;
    output Real o;
  external "builtin";
  end sin;
  function sin2
    input Real r;
    output Real o;
    external "builtin" o=sin(r);
  end sin2;
  function cos
    input Real r;
    output Real o;
    external "C";
  end cos;
  function cos2
    input Real r;
    output Real o;
    external "C" o=cos(r);
  end cos2;
  Real r1 = sin(time);
  Real r2 = sin2(time);
  Real r3 = cos(time);
  Real r4 = cos2(time);
end ExternalFunctionBuiltin;

// Result:
// class ExternalFunctionBuiltin
//   Real r1 = sin(time);
//   Real r2 = sin(time);
//   Real r3 = cos(time);
//   Real r4 = cos(time);
// end ExternalFunctionBuiltin;
// [flattening/modelica/external-functions/ExternalFunctionBuiltin.mo:28:3-28:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/external-functions/ExternalFunctionBuiltin.mo:29:3-29:23:writable] Warning: Components are deprecated in class.
// [flattening/modelica/external-functions/ExternalFunctionBuiltin.mo:30:3-30:22:writable] Warning: Components are deprecated in class.
// [flattening/modelica/external-functions/ExternalFunctionBuiltin.mo:31:3-31:23:writable] Warning: Components are deprecated in class.
//
// endResult
