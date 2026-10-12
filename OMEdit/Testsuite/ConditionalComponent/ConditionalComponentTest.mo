within ;
package ConditionalComponentTest

  model ConditionalComponents
    parameter Boolean useSensor = true;

    Real conditionalComponent if useSensor annotation(
      Placement(transformation(origin = {-10, 10}, extent = {{-10, -10}, {10, 10}})));
    Real normalComponent annotation(
      Placement(transformation(origin = {10, -10}, extent = {{-10, -10}, {10, 10}})));
  end ConditionalComponents;

end ConditionalComponentTest;
