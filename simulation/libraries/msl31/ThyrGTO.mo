within ;
model ThyrGTO "Characteristic of ideal thyristors"

  extends Modelica.Icons.Example;

  Modelica.Electrical.Analog.Ideal.IdealThyristor IdealThyristor1(Vknee=1)
                           annotation (Placement(transformation(extent={{-20,0},
            {0,20}}, rotation=0)));
  Modelica.Electrical.Analog.Sources.SineVoltage SineVoltage1(V=10,
      offset=0,
    freqHz=50)
              annotation (Placement(transformation(
        origin={-40,-10},
        extent={{-10,-10},{10,10}},
        rotation=270)));
  Modelica.Electrical.Analog.Basic.Ground Ground1
  annotation (Placement(transformation(extent={{-50,-60},{-30,-40}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Resistor R3(R=1.e-3)
  annotation (Placement(transformation(extent={{40,0},{60,20}}, rotation=0)));

  Modelica.Electrical.Analog.Ideal.IdealGTOThyristor IdealGTOThyristor1(Vknee=1)
                              annotation (Placement(transformation(extent={{-20,
            -30},{0,-10}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Resistor R1(R=1.e-3)
  annotation (Placement(transformation(extent={{40,-30},{60,-10}}, rotation=0)));

  Modelica.Blocks.Sources.BooleanPulse booleanPulse(
    period=0.02,
    startTime=0.0035,
    width=20) annotation (Placement(transformation(extent={{-50,28},{-30,48}})));
equation
  connect(IdealThyristor1.n, R3.p)
  annotation (Line(points={{0,10},{40,10}}, color={0,0,255}));
  connect(Ground1.p, SineVoltage1.n)
  annotation (Line(points={{-40,-40},{-40,-20}}, color={0,0,255}));
  connect(SineVoltage1.p, IdealThyristor1.p)
  annotation (Line(points={{-40,0},{-40,10},{-20,10}}, color={0,0,255}));
  connect(IdealGTOThyristor1.n, R1.p)
  annotation (Line(points={{0,-20},{40,-20}}, color={0,0,255}));
  connect(R3.n, R1.n)
  annotation (Line(points={{60,10},{60,-20}}, color={0,0,255}));
  connect(R1.n, Ground1.p)
  annotation (Line(points={{60,-20},{60,-40},{-40,-40}}, color={0,0,255}));
  connect(IdealGTOThyristor1.p, IdealThyristor1.p)
  annotation (Line(points={{-20,-20},{-20,10}}, color={0,0,255}));
  connect(IdealGTOThyristor1.fire, IdealThyristor1.fire)
  annotation (Line(points={{-3,-9},{-3,-2.5},{-2,-2.5},{-2,5},{-3,5},{-3,21}},
        color={255,0,255}));
  connect(booleanPulse.y, IdealThyristor1.fire) annotation (Line(
      points={{-29,38},{-3,38},{-3,21}},
      color={255,0,255},
      smooth=Smooth.None));
annotation (Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}), graphics),Documentation(info="<html>
<p>Two examples of thyristors are shown: the <b>ideal thyristor</b> and the <b>ideal GTO thyristor</b> with <i>Vknee=5</i></p>
<p>Simulate until T=2 s. Plot in separate windows:<br>
IdealThyristor1.i and IdealGTOThyristor1.i<br/>
IdealThyristor1.v and IdealGTOThyristor1.v</p>
</html>",
   revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Mai 7, 2004   </i>
       by Christoph Clauss<br> realized<br>
       </li>
</ul>
</html>"),  Documentation(info="<HTML>
<P>
Two examples of thyristors are shown:<br><br>
the <b>ideal thyristor</b>  <br>
and the <b>ideal GTO thyristor</b>  with <i>Vknee=5</i>  <br><br>
</P>
<P>
Simulate until T=2 s.
</P>
<P>
Plot in separate windows:<br> <br>
IdealThyristor1.i and IdealGTOThyristor1.i <br>
IdealThyristor1.v and IdealGTOThyristor1.v <br>
</P>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Mai 7, 2004   </i>
       by Christoph Clauss<br> realized<br>
       </li>
</ul>
</HTML>
"),
  experiment(StopTime=0.05),
    uses(Modelica(version="3.2")),
    __Dymola_experimentSetupOutput);
end ThyrGTO;
