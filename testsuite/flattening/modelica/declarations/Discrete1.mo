// name:     Discrete1
// keywords: declaration
// status:   correct
//
// Test the `discrete' keyword

class Discrete1
  discrete Real x;
equation
  when time>0.5 then
    x=time;
  end when;
end Discrete1;

// Result:
// class Discrete1
//   discrete Real x;
// equation
//   when time > 0.5 then
//     x = time;
//   end when;
// end Discrete1;
// [flattening/modelica/declarations/Discrete1.mo:8:3-8:18:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/Discrete1.mo:10:3-12:11:writable] Warning: Equation sections are deprecated in class.
//
// endResult
