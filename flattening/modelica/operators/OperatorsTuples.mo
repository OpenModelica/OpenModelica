// name: OperatorsTuples [BUG: https://trac.openmodelica.org/OpenModelica/ticket/1953]
// keywords: operators working of functions returning tuples
// status: correct
//
// Tests that tuple returning functions can be used in expressions
//

package Modelica
  package Math
    package Vectors
      function interpolate
        input Real[:] x;
        input Real[size(x, 1)] y;
        input Real xi;
        input Integer iLast = 1;
        output Real yi;
        output Integer iNew = 1;
      protected
        Integer i;
        Integer nx = size(x, 1);
        Real x1;
        Real x2;
        Real y1;
        Real y2;
      algorithm
        assert(nx > 0, "The table vectors must have at least 1 entry.");
        if nx == 1 then
          yi := y[1];
        else
          i := min(max(iLast, 1), nx - 1);
          if xi >= x[i] then
            while i < nx and xi >= x[i] loop
              i := i + 1;
            end while;
            i := i - 1;
          else
            while i > 1 and xi < x[i] loop
              i := i - 1;
            end while;
          end if;
          x1 := x[i];
          x2 := x[i + 1];
          y1 := y[i];
          y2 := y[i + 1];
          assert(x2 > x1, "Abszissa table vector values must be increasing");
          yi := y1 + ((y2 - y1) * (xi - x1)) / (x2 - x1);
          iNew := i;
        end if;
      end interpolate;
    end Vectors;
  end Math;
end Modelica;

model OperatorsTuples
  parameter Real[:, 2] pressure_drop = [0, 0; 1, 1];
  parameter Boolean anti_symmetric = true;
  parameter Integer n = 2;
  parameter Real m_flows[n] = {1, 2};
  Real x;
equation
  x = (Modelica.Math.Vectors.interpolate(pressure_drop[:, 1], sign(m_flows[1]) * pressure_drop[:, 2], abs(m_flows[2]), 1) / 2) +
      (-(Modelica.Math.Vectors.interpolate(pressure_drop[:, 1], sign(m_flows[1]) * pressure_drop[:, 2], abs(m_flows[2]), 1)));
end OperatorsTuples;

// Result:
// function Modelica.Math.Vectors.interpolate
//   input Real[:] x;
//   input Real[size(x, 1)] y;
//   input Real xi;
//   input Integer iLast = 1;
//   output Real yi;
//   output Integer iNew = 1;
//   protected Integer i;
//   protected Real x1;
//   protected Real x2;
//   protected Real y1;
//   protected Real y2;
//   protected Integer nx = size(x, 1);
// algorithm
//   assert(nx > 0, "The table vectors must have at least 1 entry.");
//   if nx == 1 then
//     yi := y[1];
//   else
//     i := min(max(iLast, 1), -1 + nx);
//     if xi >= x[i] then
//       while i < nx and xi >= x[i] loop
//         i := 1 + i;
//       end while;
//       i := -1 + i;
//     else
//       while i > 1 and xi < x[i] loop
//         i := -1 + i;
//       end while;
//     end if;
//     x1 := x[i];
//     x2 := x[1 + i];
//     y1 := y[i];
//     y2 := y[1 + i];
//     assert(x2 > x1, "Abszissa table vector values must be increasing");
//     yi := y1 + (y2 - y1) * (xi - x1) / (x2 - x1);
//     iNew := i;
//   end if;
// end Modelica.Math.Vectors.interpolate;
//
// class OperatorsTuples
//   parameter Real pressure_drop[1,1] = 0.0;
//   parameter Real pressure_drop[1,2] = 0.0;
//   parameter Real pressure_drop[2,1] = 1.0;
//   parameter Real pressure_drop[2,2] = 1.0;
//   parameter Boolean anti_symmetric = true;
//   parameter Integer n = 2;
//   parameter Real m_flows[1] = 1.0;
//   parameter Real m_flows[2] = 2.0;
//   Real x;
// equation
//   x = (-0.5) * Modelica.Math.Vectors.interpolate({0.0, 1.0}, {pressure_drop[1,2] * /*Real*/(sign(m_flows[1])), pressure_drop[2,2] * /*Real*/(sign(m_flows[1]))}, abs(m_flows[2]), 1)[1];
// end OperatorsTuples;
// endResult
