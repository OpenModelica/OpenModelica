// name: ExternalBuiltin2
// keywords: external builtin
// status: correct
//
// Checks that external "builtin" functions are handled correctly when used in a
// short class definition.
//

package Math
  function atan2
    input Real u1;
    input Real u2;
    output Real y;
    external "builtin" y = atan2(u1, u2);
  end atan2;
end Math;

model ExternalBuiltin2
  function atan2 = Math.atan2;
  Real x = Math.atan2(time, time);
end ExternalBuiltin2;

// Result:
// class ExternalBuiltin2
//   Real x = atan2(time, time);
// end ExternalBuiltin2;
// endResult
