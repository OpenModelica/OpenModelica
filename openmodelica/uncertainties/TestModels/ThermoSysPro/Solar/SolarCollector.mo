within ThermoSysPro.Solar;
model SolarCollector "Solar Collector"
  parameter Modelica.SIunits.Length f=1 "Focal length";
  parameter Real RimAngle=90 "Rim Angle";
  parameter Modelica.SIunits.Length L=1 "Width of the collector";
  parameter Integer Ns=10 "Number of cells";
  parameter Modelica.SIunits.Diameter DTube=0.1 "Tube diameter";
  parameter Modelica.SIunits.Diameter DGlass=0.11 "Glass diameter";
  parameter Modelica.SIunits.Length e=0.0001 "Glass thickness";
  parameter Real TauN=0.91 "Glass transmittivity at normal incidence";
  parameter Real AlphaN=0.97 "Tube absorptivity at normal incidence";
  parameter Real AlphaGlass=0.03 "Glass absorptivity at normal incidence";
  parameter Real EpsTube=0.06 "Tube emissivity";
  parameter Real EpsGlass=0.86 "Glass emissivity";
  parameter Real R=0.8 "Mirror reflectivity";
  parameter Real Gamma=0.83 "Intercept factor";
  parameter Modelica.SIunits.ThermalConductivity Lambda=0.00262 "Gas thermal conductivity";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer h=3.06 "Heat transfer coefficient";
  parameter Modelica.SIunits.SpecificHeatCapacity cp_glass=720 "Glass heat capacity";
  parameter Modelica.SIunits.Density rho_glass=2500 "Glass density";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0=350 "Initial temperature (active if steady_state=false)";
  parameter Boolean steady_state=true "true: start from steady state - false: start from T0";
  Real PhiSun(start=1) "Radiation flux";
  Real Theta(start=0) "Incidence angle";
  ThermoSysPro.Units.AbsoluteTemperature Twall[Ns](start=fill(350, Ns)) "Pipe wall temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tatm(start=300) "Atmospheric temperature";
  Real WTube[Ns](start=fill(1, Ns)) "Flux to the pipe";
  Modelica.SIunits.Area AReflector(start=1) "Reflector surface";
  Modelica.SIunits.Area AGlass(start=1) "Glass surface";
  Modelica.SIunits.Area ATube(start=1) "Pipe surface";
  Modelica.SIunits.Mass dM(start=1) "Glass mass";
  Real OptEff(start=1) "Optical efficiency";
  Real IAM(start=1) "Incidence angle modifier";
  Real TauAlphaN(start=1) "Transmittivity-absorptivity factor";
  Modelica.SIunits.Power WRadWall[Ns](start=fill(0, Ns)) "Radiation of the wall";
  Modelica.SIunits.Power WConvWall[Ns](start=fill(0, Ns)) "Convection of the wall";
  Modelica.SIunits.Power WCondWall[Ns](start=fill(0, Ns)) "Conduction of the wall";
  Modelica.SIunits.Power WRadGlass[Ns](start=fill(0, Ns)) "Radiation of the glass layer";
  Modelica.SIunits.Power WConvGlass[Ns](start=fill(0, Ns)) "Convection of the glass layer";
  Modelica.SIunits.Power WAbsGlass[Ns](start=fill(0, Ns)) "Absorption of the glass layer";
  ThermoSysPro.Units.AbsoluteTemperature Tsky(start=300) "Sky temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tglass[Ns](start=fill(300, Ns)) "Glass temperature";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,60},{80,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,60},{80,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Bitmap(extent={{-72,58},{84,-38}}, fileName="../../../EDF_EUROSYSLIB/documentation/solarcollector.bmp")}), DymolaStoredErrors, Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Guillaume Larrignon</li>
<li>
    Baligh El Hefni</li>
<li>
    Benoît Bride</li>
</ul>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISun "Flux (W/m²)" annotation(Placement(transformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IncidenceAngle "Degré" annotation(Placement(transformation(x=-90.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal AtmTemp "Atmospheric temperature (K)" annotation(Placement(transformation(x=-90.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort ITemperature[Ns] annotation(Placement(transformation(x=90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  constant Real sigma=5.67e-08 "Bolzmann constant";
initial equation
  if steady_state then
    for i in 1:Ns loop
      der(Tglass[i])=0;
    end for;
  else
    for i in 1:Ns loop
      Tglass[i]=T0;
    end for;
  end if;
equation
  PhiSun=ISun.signal;
  Theta=IncidenceAngle.signal;
  Tatm=AtmTemp.signal;
  AReflector=f*4*Modelica.Math.tan(RimAngle*pi/180.0/2)*L;
  AGlass=pi*DGlass*L;
  dM=rho_glass*pi*((DGlass + 2*e)^2 - DGlass^2)/4*L/Ns;
  ATube=pi*DTube*L;
  IAM=Modelica.Math.cos(Theta*pi/180);
  TauAlphaN=TauN*AlphaN*1/(1 - (1 - TauN)*AlphaN);
  OptEff=IAM*TauAlphaN*Gamma*R;
  Tsky=0.0552*Tatm^1.5;
  for i in 1:Ns loop
    Twall[i]=ITemperature[i].T;
    ITemperature[i].W=WTube[i];
    WRadWall[i]=ATube/Ns*sigma*EpsTube*(Twall[i]^4 - Tglass[i]^4);
    WConvWall[i]=0;
    WCondWall[i]=ATube/Ns*Lambda*(Twall[i] - Tglass[i])/(DTube/2*Modelica.Math.log(DGlass/DTube));
    WRadGlass[i]=AGlass/Ns*sigma*EpsGlass*(Tglass[i]^4 - Tsky^4);
    WConvGlass[i]=AGlass/Ns*h*(Tglass[i] - Tatm);
    WAbsGlass[i]=PhiSun*AReflector/Ns*AlphaGlass*IAM*Gamma*R;
    dM*cp_glass*der(Tglass[i])=WAbsGlass[i] + WCondWall[i] + WConvWall[i] + WRadWall[i] - WConvGlass[i] - WRadGlass[i];
    -WTube[i]=OptEff*PhiSun*AReflector/Ns - WRadGlass[i] - WConvGlass[i];
  end for;
end SolarCollector;
