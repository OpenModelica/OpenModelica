//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Design.Two_Tanks_System;

model TanksConnectedPI
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="TanksConnectedPI", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  TwoTanksSystemExample.Design.Two_Tanks_System.Components.LiquidSource source;
  TwoTanksSystemExample.Design.Two_Tanks_System.Components.Tank tank1;
  TwoTanksSystemExample.Design.Two_Tanks_System.Components.Tank tank2(tank_length = 1);
  TwoTanksSystemExample.Design.Two_Tanks_System.Components.PIcontinuousController piContinuous1(ref = 0.25);
  TwoTanksSystemExample.Design.Two_Tanks_System.Components.PIcontinuousController piContinuous2(ref = 0.4);
  equation
    connect(source.qOut, tank1.qIn);
    connect(piContinuous1.cIn, tank1.tSensor);
    connect(piContinuous1.cOut, tank1.tActuator);
    connect(tank1.qOut, tank2.qIn);
    connect(piContinuous2.cIn, tank2.tSensor);
    connect(piContinuous2.cOut, tank2.tActuator);

end TanksConnectedPI;

