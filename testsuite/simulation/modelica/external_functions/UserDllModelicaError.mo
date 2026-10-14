package UserDllModelicaError
  function bar
    input Real t;
    output Real y;
    external "C" y = userdll_bar(t) annotation(
      Library = "UserDllModelicaError",
      Include = "double userdll_bar(double t);");
  end bar;

  model Test "ModelicaError from a shared library during the simulation"
    discrete Real y(start = 0, fixed = true);
  equation
    when sample(0, 0.1) then
      y = bar(time);
    end when;
  end Test;
end UserDllModelicaError;
