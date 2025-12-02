// name: WhenInitial3
// keywords:
// status: correct
//

model WhenInitial3
  Integer i;
equation
  when not initial() then
    i = 1;
  end when;
end WhenInitial3;

// Result:
// class WhenInitial3
//   Integer i;
// equation
//   when not initial() then
//     i = 1;
//   end when;
// end WhenInitial3;
// [flattening/modelica/scodeinst/WhenInitial3.mo:9:3-11:11:writable] Warning: initial() may only be used as a when condition (when initial() or when {..., initial(), ...}), but got condition 'not initial()'.
//
// endResult
