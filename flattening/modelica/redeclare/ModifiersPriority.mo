// name:     ModifiersPriority.mo
// keywords: extends modifier handling
// status:   correct
//
// check that modifiers on extends are not lost (constrainedby mods for short class def)
//

package ModifiersPriority
   class X
     parameter Real x = 1;
   end X;

   class Y
     parameter Real x = 2;
     parameter Real y = 3;
   end Y;

   package P
     constant Real u = 500;
     replaceable class A = X(x = u);
   end P;

   package P2 = P(redeclare class A = Y, u = 10);

end ModifiersPriority;

model M
  ModifiersPriority.P2.A a;
end M;

// Result:
// class M
//   parameter Real a.x = 10.0;
//   parameter Real a.y = 3.0;
// end M;
// endResult
