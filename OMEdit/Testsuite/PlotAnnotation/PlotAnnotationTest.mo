model PlotAnnotationTest
  Real x(start = 1, fixed = true);
equation
  der(x) = -x;
  annotation(Documentation(
    info = "Figure test documentation",
    figures = {Figure(
      title = "Annotated decay",
      preferred = true,
      plots = {Plot(
        curves = {Curve(y = x, legend = "State")}
      )}
    )}
  ));
end PlotAnnotationTest;
