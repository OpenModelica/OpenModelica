within ThermoSysPro.Thermal.HeatTransfer;
model HeatExchangerWallAsym "Heat exchanger wall"
  parameter Modelica.SIunits.Length L=1 "Tube length";
  parameter Modelica.SIunits.Diameter D=0.2 "Internal tube diameter";
  parameter Modelica.SIunits.Thickness e=0.002 "Wall thickness";
  parameter Modelica.SIunits.ThermalConductivity lambda=26 "Wall thermal conductivity";
  parameter Integer N1=1 "Dimension of thermal connector on side 1";
  parameter Integer N2=1 "Dimension of thermal connector on side 2";
  parameter Integer Ns=1 "Number of sections inside the wall. Should be the least common multiple of N1 and N2";
  parameter Modelica.SIunits.SpecificHeatCapacity cpw=1000 "Wall specific heat capacity";
  parameter Modelica.SIunits.Density rhow=7800 "Wall density";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0=350 "Initial temperature (active if steady_state=false)";
  parameter Boolean steady_state=true "true: start from steady state - false: start from T0";
  parameter Real ntubes=1 "Number of pipes in parallel";
  Modelica.SIunits.Power dW1[Ns](start=fill(300000.0, Ns), nominal=fill(300000.0, Ns)) "Power in section i of side 1";
  Modelica.SIunits.Power dW2[Ns](start=fill(300000.0, Ns), nominal=fill(300000.0, Ns)) "Power in section i of side 2";
  ThermoSysPro.Units.AbsoluteTemperature Tp1[Ns](start=fill(300, Ns)) "Wall temperature in section i of side 1";
  ThermoSysPro.Units.AbsoluteTemperature Tp2[Ns](start=fill(300, Ns)) "Wall temperature in section i of side 2";
  ThermoSysPro.Units.AbsoluteTemperature Tp[Ns](start=fill(300, Ns)) "Average wall temperature in section i";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,10},{100,-10}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-80,40},{-20,20}}, fillColor={0,0,255}, textString="2"),Text(lineColor={0,0,255}, extent={{-80,-20},{-20,-40}}, fillColor={0,0,255}, textString="1")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,10},{100,-10}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-80,30},{-20,10}}, fillColor={0,0,255}, textString="Side 2"),Text(lineColor={0,0,255}, extent={{-80,-10},{-20,-30}}, fillColor={0,0,255}, textString="Side 1")}), DymolaStoredErrors, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Guillaume Larrignon</li>
</ul>
</html>
"));
  ThermoSysPro.Thermal.Connectors.ThermalPort WT2[N2] "Side 2" annotation(Placement(transformation(x=0.0, y=20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort WT1[N1] "Side 1" annotation(Placement(transformation(x=0.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.Length dx=L/Ns "Section length";
  parameter Modelica.SIunits.Mass dM=ntubes*rhow*pi*((D + 2*e)^2 - D^2)/4*dx "Wall section mass";
  parameter Integer b1=div(Ns, N1);
  parameter Integer b2=div(Ns, N2);
initial equation
  if steady_state then
    for i in 1:Ns loop
      der(Tp[i])=0;
    end for;
  else
    for i in 1:Ns loop
      Tp[i]=T0;
    end for;
  end if;
equation
  for i in 1:N1 loop
    for j in 1:b1 loop
      WT1[i].T=Tp1[(i - 1)*b1 + j];
      WT1[i].W=dW1[(i - 1)*b1 + j];
    end for;
  end for;
  for i in 1:N2 loop
    for j in 1:b2 loop
      WT2[i].T=Tp2[(i - 1)*b2 + j];
      WT2[i].W=dW2[(i - 1)*b2 + j];
    end for;
  end for;
  for i in 1:Ns loop
    dW1[i]=2*pi*dx*ntubes*lambda*(Tp1[i] - Tp[i])/Modelica.Math.log(1 + e/D);
    dW2[i]=2*pi*dx*ntubes*lambda*(Tp2[i] - Tp[i])/Modelica.Math.log(1 + e/D);
    dM*cpw*der(Tp[i])=dW2[i] + dW1[i];
  end for;
end HeatExchangerWallAsym;
