// name: FuncBuiltinReinit
// keywords: reinit
// status: correct
// cflags: -d=newInst
//
// Tests the builtin reinit operator.
//

model FuncBuiltinReinit
  Real x;
algorithm
  when time > 1 then
    reinit(x, time);
  end when;
end FuncBuiltinReinit;

// Result:
// class FuncBuiltinReinit
//   Real x;
// algorithm
//   when time > 1.0 then
//     reinit(x, time);
//   end when;
// end FuncBuiltinReinit;
// endResult
