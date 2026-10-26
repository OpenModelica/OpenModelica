// name:     WhenSemantics1
// keywords: when semantics
// status:   correct
//
// Simple when

model WhenSemantics1
  Real x,y,z;
equation
  y=sin(time)+x+z;
  when sample(0.1,0.1) then
    x=pre(y);
  end when;
  when {sample(0.1,0.1),time>=0.15,time>=0.25} then
    z=time;
  end when;
end WhenSemantics1;

// Result:
// class WhenSemantics1
//   Real x;
//   Real y;
//   Real z;
// equation
//   y = sin(time) + x + z;
//   when sample(0.1, 0.1) then
//   x = pre(y);
//   end when;
//   when {sample(0.1, 0.1), time >= 0.15, time >= 0.25} then
//   z = time;
//   end when;
// end WhenSemantics1;
// endResult
