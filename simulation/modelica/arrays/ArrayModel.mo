model ArrayModel

   function lift
      input Real x;
      input Real y;
      output Real[1] z;
    algorithm
      z := {x};
    end lift;

    parameter Real x = 10;
    Real z[1];
equation
    z = lift(x, 0.0);
end ArrayModel;
