//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Requirements;

model Volume_of_the_tank1
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="Volume of the tank1", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«requirement»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="Rq", fontName="Arial")}));
  input Real tank_volume;
  constant Real design_value= 0.8;
  Boolean violated;
  algorithm

  // code generated from the Activity "evaluate requirement" (ConditionalAlgorithm(Diagram))

  // if/when-else code
  if tank_volume > design_value   or   tank_volume < design_value then
      // OpaqueAction: "evaluate requirement.violated"
      violated := true;
    else
      // OpaqueAction: "evaluate requirement.not violated"
      violated := false;
  end if;
end Volume_of_the_tank1;

