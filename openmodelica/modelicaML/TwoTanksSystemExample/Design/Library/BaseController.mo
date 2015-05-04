//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Design.Library;

partial model BaseController "New_Comment "
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="BaseController", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  parameter Real K "Gain ";
  parameter Real T(unit = "s") "Time constant ";
  parameter Real ref "Reference level ";
  Real error "Deviation from reference level ";
  Real outCtr "Output control signal ";
  TwoTanksSystemExample.Design.Two_Tanks_System.Interfaces.ReadSignal cIn "Input sensor level, connector ";
  TwoTanksSystemExample.Design.Two_Tanks_System.Interfaces.ActSignal cOut "Control to actuator, connector ";
  equation
    error = ref - cIn.val;

end BaseController;

