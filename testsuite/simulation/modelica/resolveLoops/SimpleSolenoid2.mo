within ;
model SimpleSolenoid2
  "Simple network model of a lifting magnet with planar armature end face"

  parameter Modelica.SIunits.Resistance R=10 "Armature coil resistance";
  parameter Real N = 957 "Number of turns";

//yoke
  parameter Modelica.SIunits.Radius r_yokeOut=15e-3 "Outer yoke radius";
  parameter Modelica.SIunits.Radius r_yokeIn=13.5e-3 "Inner yoke radius";
  parameter Modelica.SIunits.Length l_yoke=35e-3 "Axial yoke length";
  parameter Modelica.SIunits.Length t_yokeBot=3.5e-3
    "Axial thickness of yoke bottom";

//pole
  parameter Modelica.SIunits.Length l_pole=6.5e-3 "Axial length of pole";
  parameter Modelica.SIunits.Length t_poleBot=3.5e-3
    "Axial thickness of bottom at pole side";

  parameter Modelica.SIunits.Length t_airPar=0.65e-3
    "Radial thickness of parasitic air gap due to slide guiding";

  parameter Modelica.Magnetic.FluxTubes.Material.SoftMagnetic.BaseData
    material=
    Modelica.Magnetic.FluxTubes.Material.SoftMagnetic.Steel.Steel_9SMnPb28()
    "Ferromagnetic material characteristics"
    annotation(choicesAllMatching=true, Dialog(group="Material"));

//armature
  parameter Modelica.SIunits.Radius r_arm=5e-3 "Armature radius = pole radius"
                                                                   annotation(Dialog(group="Armature and stopper"));
  parameter Modelica.SIunits.Length l_arm=26e-3 "Armature length"
                                                      annotation(Dialog(group="Armature and stopper"));
  parameter Modelica.SIunits.TranslationalSpringConstant c=
        1e11 "Spring stiffness between impact partners" annotation(Dialog(group="Armature and stopper"));
  parameter Modelica.SIunits.TranslationalDampingConstant d=
        400 "Damping coefficient between impact partners"   annotation(Dialog(group="Armature and stopper"));
  parameter Modelica.SIunits.Position x_min=0.25e-3
    "Stopper at minimum armature position"                                     annotation(Dialog(group="Armature and stopper"));
  parameter Modelica.SIunits.Position x_max=5e-3
    "Stopper at maximum armature position"                                  annotation(Dialog(group="Armature and stopper"));

  Modelica.SIunits.Position x(start=x_max, stateSelect=StateSelect.prefer)
    "Armature position, alias for flange position (identical with length of working air gap)";

protected
  parameter Modelica.SIunits.Density rho_steel=7853
    "Density for calculation of armature mass from geometry";

public
  Modelica.Magnetic.FluxTubes.Basic.Ground ground
    annotation (Placement(transformation(extent={{50,10},{70,30}},
        rotation=0)));
  Modelica.Magnetic.FluxTubes.Basic.ElectroMagneticConverter coil(
                                final N=N, i(fixed=true))
    "Electro-magnetic converter"
    annotation (Placement(transformation(
      origin={0,20},
      extent={{-10,-10},{10,10}},
      rotation=90)));

  Modelica.Magnetic.FluxTubes.Shapes.Force.HollowCylinderAxialFlux
    g_mAirWork(
    final mu_r=1,
    final dlBydx=1,
    final r_i=0,
    final r_o=r_arm,
    final useSupport=false,
    final l=flange.s)
    "Permeance of working air gap (between armature and pole end faces)"
    annotation (Placement(transformation(
      origin={-30,30},
      extent={{-10,10},{10,-10}},
      rotation=180)));

  Modelica.Magnetic.FluxTubes.Shapes.FixedShape.HollowCylinderRadialFlux
    g_mAirPar(
    final nonLinearPermeability=false,
    final mu_rConst=1,
    final l=t_yokeBot,
    final r_i=r_arm,
    final r_o=r_arm + t_airPar)
    "Permeance of parasitic radial air gap due to slide guiding"
    annotation (Placement(transformation(
      origin={80,50},
      extent={{-10,-10},{10,10}},
      rotation=90)));

  Modelica.Magnetic.FluxTubes.Shapes.FixedShape.HollowCylinderAxialFlux
    g_mFePole(
    final nonLinearPermeability=true,
    final material=material,
    final l=l_pole,
    final r_i=0,
    final r_o=r_arm) "Permeance of ferromagnetic pole"
    annotation (Placement(transformation(
      origin={-72,40},
      extent={{10,-10},{-10,10}},
      rotation=270)));

  Modelica.Magnetic.FluxTubes.Shapes.Force.LeakageAroundPoles
    g_mLeakWork(/*Phi(stateSelect=StateSelect.always),*/
    final mu_r=1,
    final dlBydx=1,
    final w=2*Modelica.Constants.pi
                *(r_arm + 0.0015),
    final r=0.003,
    final l=flange.s,
    final useSupport=false)
    "Permeance of leakage air gap around working air gap (between armature and pole side faces)"
    annotation (Placement(transformation(
      origin={-30,70},
      extent={{-10,10},{10,-10}},
      rotation=180)));
  Modelica.Electrical.Analog.Interfaces.PositivePin p "Electrical connector"
    annotation (Placement(transformation(extent={{-110,50},{-90,70}},
        rotation=0)));
  Modelica.Electrical.Analog.Interfaces.NegativePin n "Electrical connector"
    annotation (Placement(transformation(extent={{-90,-70},{-110,-50}},
        rotation=0)));
  Modelica.Mechanics.Translational.Interfaces.Flange_b flange
    "Flange of component"
    annotation (Placement(transformation(extent={{90,-10},{110,10}},
        rotation=0)));
equation
  x = flange.s;
  connect(g_mAirWork.flange,g_mLeakWork. flange)
                                             annotation (Line(points={{
        -30,40},{-30,52},{34,52},{34,80},{-30,80}}, color={0,127,0}));
  connect(coil.n, n) annotation (Line(points={{6,10},{6,-60},{-100,-60}},
      color={0,0,255}));
  connect(coil.port_p, g_mAirWork.port_p) annotation (Line(points={{-6,30},
        {-20,30}},     color={255,127,0}));
  connect(g_mFePole.port_p, g_mAirWork.port_n) annotation (Line(points=
        {{-72,30},{-40,30}}, color={255,127,0}));
  connect(ground.port, g_mAirPar.port_p) annotation (Line(
      points={{60,30},{60,40},{80,40}},
      color={255,127,0},
      smooth=Smooth.None));
  connect(g_mFePole.port_n, g_mAirPar.port_n) annotation (Line(
      points={{-72,50},{-72,88},{80,88},{80,60}},
      color={255,127,0},
      smooth=Smooth.None));
  connect(coil.p, p) annotation (Line(
      points={{-6,10},{-28,10},{-28,-16},{-56,-16},{-56,-6},{-100,-6},{-100,60}},
      color={0,0,255},
      smooth=Smooth.None));

  connect(coil.port_n, ground.port) annotation (Line(
      points={{6,30},{60,30}},
      color={255,127,0},
      smooth=Smooth.None));
  connect(flange, g_mLeakWork.flange) annotation (Line(
      points={{100,0},{34,0},{34,80},{-30,80}},
      color={0,127,0},
      smooth=Smooth.None));
  connect(g_mLeakWork.port_n, g_mAirWork.port_n) annotation (Line(
      points={{-40,70},{-40,30}},
      color={255,127,0},
      smooth=Smooth.None));
  connect(g_mLeakWork.port_p, g_mAirWork.port_p) annotation (Line(
      points={{-20,70},{-20,30}},
      color={255,127,0},
      smooth=Smooth.None));
  annotation (__Dymola_Images(Parameters(source=
            "modelica://Modelica/Resources/Images/Magnetic/FluxTubes/Examples/SolenoidActuator/Solenoid_dimensions.png")),
    Window(
      x=0.16,
      y=0.15,
      width=0.6,
      height=0.6),
    Icon(coordinateSystem(
      preserveAspectRatio=true,
      extent={{-100,-100},{100,100}},
      grid={2,2}), graphics={
      Rectangle(
        extent={{-90,100},{90,-100}},
        lineColor={255,255,255},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{90,-30},{-4,30}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-40,-30},{-90,30}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-80,-100},{-90,100}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{90,90},{-90,100}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{90,-100},{-90,-90}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{90,40},{80,100}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{90,-100},{80,-40}},
        lineColor={255,128,0},
        fillColor={255,128,0},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-70,80},{70,40}},
        lineColor={255,213,170},
        fillColor={255,213,170},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-70,-40},{70,-80}},
        lineColor={255,213,170},
        fillColor={255,213,170},
        fillPattern=FillPattern.Solid),
      Text(
        extent={{0,160},{0,120}},
        lineColor={0,0,255},
        textString="%name")}),
    Diagram(coordinateSystem(
      preserveAspectRatio=false,
      extent={{-100,-100},{100,100}},
      grid={2,2}), graphics),
  Documentation(info="<html>
<p>
Please refer to the <b>Parameters</b> section for a schematic drawing of this axisymmetric lifting magnet.
In the half-section below, the flux tube elements of the actuator's magnetic circuit are superimposed on a field plot obtained with FEA. The magnetomotive force imposed by the coil is modelled as one lumped element. As a result, the radial leakage flux between armature and yoke that occurs especially at large working air gaps can not be considered properly. This leads to a a higher total reluctance and lower inductance respectively compared to FEA for large working air gaps (i.e., armature close to x_max). Please have a look at the comments associated with the individual model components for a short explanation of their purpose in the model.
</p>

<IMG src=\"modelica://Modelica/Resources/Images/Magnetic/FluxTubes/Examples/SolenoidActuator/SimpleSolenoidModel_fluxTubePartitioning.png\" ALT=\"Field lines and assigned flux tubes of the simple solenoid model\">

<p>
The coupling coefficient c_coupl in the coil is set to 1 in this example, since leakage flux is accounted for explicitly with the flux tube element G_mLeakWork. Although this leakage model is rather simple, it describes the reluctance force due to the leakage field sufficiently, especially at large air gaps. With decreasing air gap length, the influence of the leakage flux on the actuator's net reluctance force decreases due to the increasing influence of the main working air gap G_mAirWork.
</p>

<p>
During model-based actuator design, the radii and lengths of the flux tube elements (and hence their cross-sectional areas and flux densities) should be assigned with parametric equations so that common design rules are met (e.g., allowed flux density in ferromagnetic parts, allowed current density and required cross-sectional area of winding). For simplicity, those equations are omitted in the example. Instead, the found values are assigned to the model elements directly.
</p>
</html>"),
    uses(Modelica(version="3.2")));
end SimpleSolenoid2;
