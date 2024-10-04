// name: Clock1
// keywords:
// status: correct
//

model Clock1
  model Clock
    Real t;
  end Clock;

  Clock c;
end Clock1;

// Result:
// class Clock1
//   Real c.t;
// end Clock1;
// endResult
