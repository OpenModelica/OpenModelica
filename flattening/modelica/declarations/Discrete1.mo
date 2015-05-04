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
//   x = time;
//   end when;
// end Discrete1;
// endResult
