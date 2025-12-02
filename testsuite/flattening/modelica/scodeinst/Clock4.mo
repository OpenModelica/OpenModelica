// name: Clock4
// keywords:
// status: correct
//

model Clock4
  model Clock
    Real t;
  end Clock;

  .Clock c = .Clock();
end Clock4;

// Result:
// class Clock4
//   Clock c = Clock();
// end Clock4;
// endResult
