// name:     Enumeration6
// keywords: enumeration enum
// status:   correct
//
//
//

package P

type EE =
     enumeration(world "Resolve in world frame",
                 frame_a "Resolve in frame_a",
                 frame_resolve "Resolve in frame_resolve (frame_resolve must be connected)");

 type E = enumeration(a,b,c);

 model h
  // Types.Color axisColor_x=Types.FrameColor;
  replaceable type E=enumeration(j, l, k);
  Real hh[E];
 equation
  hh[E.j] = 1.0;
  hh[E.l] = 2.0;
  hh[E.k] = 3.0;
 end h;


end P;

model Enumeration6

   P.h t; //(redeclare type E=enumeration(a1, b2, c1));
   import P.EE;
   import P.E;
   parameter EE frame_r_in = EE.frame_a;
   parameter EE frame_r_out = frame_r_in;
   Real x(stateSelect=StateSelect.default);
   Real[EE] z;
   EE ee(start = EE.world);
   E f(quantity="quant_str_enumeration",min = E.a,max = E.b,fixed = true,start = E.c);
equation
   x = if frame_r_out == EE.frame_a then 0.0 else 1.0;
   for e in EE loop
     z[e] = if frame_r_out <= EE.frame_a then 0.0 else 1.0;
   end for;
   ee = EE.frame_a;
   f = E.b;
end Enumeration6;

// Result:
// class Enumeration6
//   Real t.hh[P.h.E.j];
//   Real t.hh[P.h.E.l];
//   Real t.hh[P.h.E.k];
//   parameter enumeration(world, frame_a, frame_resolve) frame_r_in = P.EE.frame_a;
//   parameter enumeration(world, frame_a, frame_resolve) frame_r_out = frame_r_in;
//   Real x(stateSelect = StateSelect.default);
//   Real z[P.EE.world];
//   Real z[P.EE.frame_a];
//   Real z[P.EE.frame_resolve];
//   enumeration(world, frame_a, frame_resolve) ee(start = P.EE.world);
//   enumeration(a, b, c) f(quantity = "quant_str_enumeration", min = P.E.a, max = P.E.b, start = P.E.c, fixed = true);
// equation
//   t.hh[P.h.E.j] = 1.0;
//   t.hh[P.h.E.l] = 2.0;
//   t.hh[P.h.E.k] = 3.0;
//   x = if frame_r_out == P.EE.frame_a then 0.0 else 1.0;
//   z[P.EE.world] = if frame_r_out <= P.EE.frame_a then 0.0 else 1.0;
//   z[P.EE.frame_a] = if frame_r_out <= P.EE.frame_a then 0.0 else 1.0;
//   z[P.EE.frame_resolve] = if frame_r_out <= P.EE.frame_a then 0.0 else 1.0;
//   ee = P.EE.frame_a;
//   f = P.E.b;
// end Enumeration6;
// endResult
