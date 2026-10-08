package ExtLib "Minimal library depending on a pre-compiled external C library"
  function addOne "Computes x + 1 in the external library"
    input Real x;
    output Real y;
    external "C" y = addOne(x) annotation(
      Include = "#include \"addOne.h\"",
      IncludeDirectory = "modelica://ExtLib/Resources/Include",
      Library = "addOne",
      LibraryDirectory = "modelica://ExtLib/Resources/Library");
  end addOne;

  model Test "Model calling into the external library"
    Real x(start = 0, fixed = true) "State, so a CoSimulation FMU has something to integrate";
    output Real y;
  equation
    y = addOne(time);
    der(x) = y;
    annotation(experiment(StopTime = 1.0));
  end Test;
end ExtLib;
