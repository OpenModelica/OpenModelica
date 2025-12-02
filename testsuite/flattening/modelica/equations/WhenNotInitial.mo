// status: correct

model WhenNotInitial
  discrete Real r(start=0, fixed=true);
equation
  when not initial() then
    r=1;
  end when;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end WhenNotInitial;

// Result:
// class WhenNotInitial
//   discrete Real r(start = 0.0, fixed = true);
// equation
//   when not initial() then
//     r = 1.0;
//   end when;
// end WhenNotInitial;
// [flattening/modelica/equations/WhenNotInitial.mo:6:3-8:11:writable] Warning: initial() may only be used as a when condition (when initial() or when {..., initial(), ...}), but got condition 'not initial()'.
//
// endResult
