class C Real x; end C;
record B String name; Integer age; end B;
block Mul input Real x; output Real result; equation result = x; end Mul;
type vector3D = Real[3](each start = 5, nominal = {1, 2, 3, 4, 5});
function f input Real x; output Real result; algorithm result := x; end f;
type sizeE = enumeration(Small, Medium, Large);
model M "A class comment" parameter Integer i = 1; Real r = 4 if i > 0 "A component comment"; end M;
model ReplaceableClass replaceable model M1 end M1; end ReplaceableClass;
connector RealSignal replaceable type SignalType = Real; extends SignalType; end RealSignal;
model ProtectedClass protected model M1 end M1; end ProtectedClass;
type Resistance = Real(final quantity="Resistance",final unit="Ohm");

connector RealInput = input Real;
connector RealInput3 = flow constant input Real[3];
connector RealConnect = stream Real;

package TestPack
 function Ext
   input Real x;
   input Real y;
   input Real z;
   output Real u;
   external "C" u = externFunc(x,y,z);
 end Ext;

 function NoExt
   input Real x;
   output Real y;
 algorithm
   y := x;
 end NoExt;

model MyModel
  Modelica.Electrical.Analog.Basic.Resistor r1;
  Modelica.Electrical.Analog.Basic.Capacitor c1;
end MyModel;

end TestPack;

model M1
  Modelica.Electrical.Analog.Basic.Resistor resistor1(phi(start = 1));
end M1;

model state1
  annotation(__Dymola_state=true);
end state1;

model SimpleSMwithAnnotations "Simple state machine"
  inner Integer i(start = 0);
  Integer j;
  
  block State1
    outer output Integer i;
    output Integer j(start = 10);
  equation
    i = previous(i) + 2;
    j = previous(j) - 1
    annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
  end State1;

  State1 state1 annotation(Placement(transformation(extent={{-62,40},{-26,76}})));

  block State2
    outer output Integer i;
  equation
    i = previous(i) - 1;
    annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
  end State2;

  State2 state2 annotation(Placement(transformation(extent={{-64,-8},{-26,30}})));
equation
  j = 2*state1.j;
  transition(state1, state2, i > 10, immediate = false, reset = true, synchronize = false, priority = 1) annotation(Line(points={{-24,58},
          {-16,50},{-24,11}},                                                                                                  color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(textString = "%condition", extent={{12,-2},
          {12,-8}},                                                                                                                                                                                                        lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Left));
  transition(state2, state1, i < 1, immediate = false, reset = true, synchronize = false, priority = 1) annotation(Line(points={{-66,11},
          {-76,42},{-64,58}},                                                                                                    color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(textString = "%condition", extent = {{-6, 4}, {-6, 10}}, lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Right));
  initialState(state1) annotation(Line(points={{-45.2004,78},{-46,86}},      color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier, arrow = {Arrow.Filled, Arrow.None}));
  annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent={{
              -72,96},{-22,86}},                                                                                                    lineColor = {0, 0, 0}, fontSize = 10,
            horizontalAlignment =                                                                                                   TextAlignment.Left, textString = "%declarations"),
                                                                                                  Text(extent={{
              -58,-12},{-8,-22}},                                                                                                   lineColor=
              {0,0,0},                                                                                                    fontSize=
              10,
            horizontalAlignment=TextAlignment.Left,
          textString="%equations")}),                                                                                                    experiment(StopTime = 30), __Dymola_experimentSetupOutput);
end SimpleSMwithAnnotations;
