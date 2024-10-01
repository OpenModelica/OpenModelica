// name: Clock5
// keywords:
// status: correct
//

model Clock5
  record Clock
    Real t;
  end Clock;

  Clock c = Clock(1);
end Clock5;

// Result:
// class Clock5
//   Real c.t = 1.0;
// end Clock5;
// endResult
