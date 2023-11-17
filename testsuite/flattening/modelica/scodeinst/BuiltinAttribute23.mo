// name: BuiltinAttribute23
// keywords:
// status: correct
// cflags: -d=newInst --newBackend
//

model BuiltinAttribute23
  parameter Real x0;
  type T = Real[3] (each start = x0);
  T t;
end BuiltinAttribute23;

// Result:
// class BuiltinAttribute23
//   parameter Real x0;
//   Real[3] t(start = array(x0 for $i1 in 1:3));
// end BuiltinAttribute23;
// endResult
