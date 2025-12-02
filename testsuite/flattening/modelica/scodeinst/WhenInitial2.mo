// name: WhenInitial2
// keywords:
// status: correct
//

model WhenInitial2
  Integer i;
equation
  when initial() then
    i = 1;
  end when;
end WhenInitial2;

// Result:
// class WhenInitial2
//   Integer i;
// equation
//   when initial() then
//     i = 1;
//   end when;
// end WhenInitial2;
// endResult
