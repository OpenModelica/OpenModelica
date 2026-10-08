within ;

package OuterParameterDialogMWE

  partial model CharacteristicValues
    outer parameter Modelica.Units.SI.Time globalTime  "Global characteristic time";

    parameter Modelica.Units.SI.Time localTime = globalTime "Local characteristic time"
      annotation(Dialog(group = "Characteristic values"));
  end CharacteristicValues;

  partial model PartialComponent
    extends CharacteristicValues;
  end PartialComponent;

  model Component
    extends PartialComponent;
    annotation(
      Icon(graphics = {Rectangle(origin = {12, 1}, extent = {{-48, 51}, {48, -51}})}));
  end Component;

  model System
    inner parameter Modelica.Units.SI.Time globalTime = 3600 "Global characteristic time";

    Component Component1
      annotation(Placement(transformation(origin = {0, 0},
            extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  end System;
  annotation (uses(Modelica(version="4.0.0")));
end OuterParameterDialogMWE;