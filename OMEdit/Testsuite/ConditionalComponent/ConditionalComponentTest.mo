within ;
package ConditionalComponentTest

  model RealComponent
    Real x;
  end RealComponent;

  model ConditionalComponents
    parameter Boolean useSensor = true;

    RealComponent conditionalComponent if useSensor annotation(
      Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})));
    RealComponent normalComponent annotation(
      Placement(transformation(origin = {10, -10}, extent = {{-10, -10}, {10, 10}})));
  end ConditionalComponents;

end ConditionalComponentTest;
