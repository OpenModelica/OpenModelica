
package RefAir
    package AirUtilities

      record R
         Real x;
         Integer y;
      end R;

      package Basic
        constant R Constants(x = 1, y = 2);
        package Utilities
          function f
            input Real x;
            output Real y;
          algorithm
            y := x + Constants.x;
          end f;
        end Utilities;
      end Basic;
    end AirUtilities;
end RefAir;

package Constants
  constant Real blah;
end Constants;

partial package RefAirPartial
    package AirUtilities
      record R
         Real x;
         Integer y;
      end R;
      package Basic
        constant R Constants(x = 100, y = 200);
        package Utilities
          function f
            input Real x;
            output Real y;
          algorithm
            y := x + Constants.x;
          end f;
        end Utilities;
      end Basic;
    end AirUtilities;
end RefAirPartial;

package M
  replaceable package Medium = RefAirPartial;
  constant Real u = Medium.AirUtilities.Basic.Utilities.f(10);
end M;

model U
  replaceable package Medium = RefAirPartial;
  package B = M(redeclare package Medium = Medium);
  Real x = B.u;
end U;

model Dependency
  package B = M(redeclare package Medium = RefAir);
  Real x = B.u;
  // U u(redeclare package Medium = RefAir);
end Dependency;
