// name: NoEvent2
// keywords: noEvent
// status: correct
// cflags: -d=newInst
//
// Tests the builtin noEvent operator.
//

model NoEvent3
  Real x = noEvent(if time > 1 then 0 else 1);
end NoEvent3;

// Result:
// class NoEvent3
//   Real x = if noEvent(time > 1.0) then 0.0 else 1.0;
// end NoEvent3;
// endResult
