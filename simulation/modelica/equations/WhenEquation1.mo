// name:     WhenEquation1
// keywords: when
// status:   correct
//
// Conditional Equations with when-Equations and elsewhen-Equations
//

model WhenEquation1
  Real phi(start=0);
  Real sp;
  Integer pos(start=0);
  Integer toggle(start=0);

  equation
    der(phi)=1;
    sp=sin(phi*10);
    when sin(sp) < 0 then
      toggle=-1;
      pos=pre(pos)+1;
    elsewhen sin(sp)>0 then
      toggle=1;
      pos=pre(pos)+1;
    end when;
end WhenEquation1;

// class WhenEquation1
// Real phi(start = 0.0);
// Real sp;
// Integer pos(start = 0);
// Integer toggle(start = 0);
// equation
//   der(phi) = 1.0;
//   sp = sin(10.0 * phi);
// when sin(sp) < 0.0 then
//   toggle = -1;
//   pos = 1 + pre(pos);
//   else  when sin(sp) > 0.0 then
//   toggle = 1;
//   pos = 1 + pre(pos);
//   end when;
// end WhenEquation1;