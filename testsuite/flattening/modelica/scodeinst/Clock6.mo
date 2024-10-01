// name: Clock6
// keywords:
// status: correct
//

package P
  record Clock
    Real t;
  end Clock;
end P;

model Clock6
  P.Clock Clock = P.Clock(1);
equation
  Clock.t = der(time);
end Clock6;

// Result:
// class Clock6
//   Real Clock.t = 1.0;
// equation
//   Clock.t = der(time);
// end Clock6;
// endResult
