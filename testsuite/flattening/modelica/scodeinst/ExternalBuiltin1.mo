// name: ExternalBuiltin1
// keywords: external builtin
// status: correct
//
// Checks that external "builtin" functions are handled correctly.
//

package Math
  function atan2
    input Real u1;
    input Real u2;
    output Real y;
    external "builtin" y = atan2(u1, u2);
  end atan2;
end Math;

model ExternalBuiltin1
  Real x = Math.atan2(time, time);
end ExternalBuiltin1;

// Result:
// class ExternalBuiltin1
//   Real x = atan2(time, time);
// end ExternalBuiltin1;
// endResult
