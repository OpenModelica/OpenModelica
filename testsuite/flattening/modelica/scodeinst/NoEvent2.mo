// name: NoEvent2
// keywords: noEvent
// status: correct
// cflags: -d=newInst
//
// Tests the builtin noEvent operator.
//

model NoEvent2
  Real x;
equation
  if noEvent(time > 1) then
    x = time;
  else
    x = time * 2; 
  end if;
end NoEvent2;

// Result:
// class NoEvent2
//   Real x;
// equation
//   if noEvent(time > 1.0) then
//     x = time;
//   else
//     x = time * 2.0;
//   end if;
// end NoEvent2;
// endResult
