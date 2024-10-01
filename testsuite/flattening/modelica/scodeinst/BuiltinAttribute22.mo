// name: BuiltinAttribute22
// keywords:
// status: correct
//

model BuiltinAttribute22
  type T = Real[3] (unit = {"m", "m", "m"});

  function f
    input T x;
  end f;
equation
  f({time, time, time});
end BuiltinAttribute22;

// Result:
// function BuiltinAttribute22.f
//   input Real[3] x(unit = {"m", "m", "m"});
// end BuiltinAttribute22.f;
//
// class BuiltinAttribute22
// equation
//   BuiltinAttribute22.f({time, time, time});
// end BuiltinAttribute22;
// endResult
