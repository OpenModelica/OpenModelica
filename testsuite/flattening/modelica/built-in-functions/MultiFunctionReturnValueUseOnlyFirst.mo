// name: MultiFunctionReturnValueUseOnlyFirst [BUG: https://trac.openmodelica.org/OpenModelica/ticket/1969]
// keywords: abs
// status: correct
//
// Testing the built-in abs function that gets a tuple input from another function call
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

model MultiFunctionReturnValueUseOnlyFirst
equation
  assert(abs(Modelica.Math.Vectors.interpolate({ 0,  2,  4,  6,  8, 10},{10, 20, 30, 40, 50, 60},5)) < 0.1,"Only a Test");
end MultiFunctionReturnValueUseOnlyFirst;

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
// class MultiFunctionReturnValueUseOnlyFirst
// equation
//   assert(false, "Only a Test");
// end MultiFunctionReturnValueUseOnlyFirst;
// endResult
