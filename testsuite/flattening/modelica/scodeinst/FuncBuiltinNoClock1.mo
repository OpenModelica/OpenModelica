// name: FuncBuiltinNoClock1
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinNoClock1
  Real x, y;
  Clock c1 = Clock(0.1);
equation
  when c1 then
    y = noClock(x);
  end when;
end FuncBuiltinNoClock1;

// Result:
// class FuncBuiltinNoClock1
//   Real x;
//   Real y;
//   Clock c1 = Clock(0.1);
// equation
//   when c1 then
//     y = noClock(x);
//   end when;
// end FuncBuiltinNoClock1;
// endResult
