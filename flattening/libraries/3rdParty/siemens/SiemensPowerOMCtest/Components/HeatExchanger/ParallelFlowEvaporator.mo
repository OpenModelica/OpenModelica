within SiemensPowerOMCtest.Components.HeatExchanger;
model ParallelFlowEvaporator
  "Evaporator with parallel rows according to Cottam design"
  import SI = Modelica.SIunits;
replaceable package GasMedium =  SiemensPowerOMCtest.Media.ExhaustGas constrainedby
    Modelica.Media.Interfaces.PartialMedium "Flue gas medium"
    annotation (   choicesAllMatching=true, Dialog(group="Media"));

replaceable package WaterMedium = Modelica.Media.Water.WaterIF97_ph
  constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium
    "Water/steam medium"                          annotation (choicesAllMatching=
      true, Dialog(group="Media"));

parameter Integer numberOfTubeLayers(min=1)=1 "Number of tube layers";
parameter Integer numberOfCellsPerLayer=20
    "Number of water/steam cells per tube layer"                                        annotation (Dialog(group="Discretization"));
parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers" annotation (Dialog(group="Discretization"), choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
replaceable model friction =
    SiemensPowerOMCtest.Utilities.PressureLoss.RoughnessFlow constrainedby
    SiemensPowerOMCtest.Utilities.PressureLoss.PartialFrictionSinglePhase
    "Inner flow friction pressure loss correlation" annotation (Dialog(group="Pressure loss"), choicesAllMatching=true);
parameter Modelica.Fluid.Types.HydraulicResistance hydraulicResistanceGasFLow=2
    "Hydraulic resistance for gas flow"
  annotation(Dialog(group="Pressure loss"));

parameter SiemensPowerOMCtest.Utilities.Structures.FgzGeo geoFGZ(
    pt=0.085,
    pl=0.09,
    Lw=3.6,
    Ld=21,
    Lh=0.09,
    Nr=14,
    staggered=true) "Geometry of flue gas zone"  annotation (Dialog(group="Geometry"));
 parameter SiemensPowerOMCtest.Utilities.Structures.Fins geoFins(
    h=0.016,
    s=0.001,
    n=294,
    finned=true,
    w=0.0044,
    serrated=true) "Geometry of outer wall fins" annotation (Dialog(group="Geometry"));
 parameter SiemensPowerOMCtest.Utilities.Structures.PropertiesMetal
    propertiesMetal "Tube wall properties"                                       annotation (Dialog(group="Media"));
 parameter SiemensPowerOMCtest.Utilities.Structures.PipeGeo geoPipe(
    Nt=40,
    L=21,
    H=21,
    d_out=0.0381,
    s=0.00325,
    zeta_add=0.75) "Geometry of tubes" annotation (Dialog(group="Geometry"));

  replaceable model innerHeatTransfer =
      SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.SinglePhase
    constrainedby
    SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransferSinglePhase
    "Inner heat transfer correlation"
                                    annotation (Dialog(tab="Heat transfer", group="Inner heat transfer"),
    choicesAllMatching=true);
parameter Boolean delayInnerHeatTransfer= false "With delay of qmf" annotation(Dialog(tab="Heat transfer", group="Inner heat transfer"));
parameter SI.Time timeDelayOfInnerHeatTransfer=0.1
    "artificial delay time for qmf"                   annotation(Dialog(tab="Heat transfer", group="Inner heat transfer",enable=delayInnerHeatTransfer));

replaceable model outerHeatTransfer =
    SiemensPowerOMCtest.Utilities.HeatTransfer.HeatTransfer_constAlpha constrainedby
    SiemensPowerOMCtest.Utilities.HeatTransfer.HeatTransferBaseClass
    "Convective heat transfer"
   annotation (Dialog(tab="Heat transfer", group="Outer heat transfer"),editButton=true,choicesAllMatching);

parameter Real cleanlinessFactor = 1.0 annotation (Dialog(tab="Heat transfer", group="Outer heat transfer"));
parameter Real heatloss = 0.5 "Heat loss to ambient in %" annotation (Dialog(tab="Heat transfer", group="Heat loss to ambient"));
parameter Boolean hasMixerVolume = false "Mixer has volume "
                                                            annotation(Dialog(group="Geometry"));
parameter SI.Volume V=0.1 "Volume of mixer" annotation(Dialog(group="Geometry", enable=hasMixerVolume));
parameter Modelica.Fluid.Types.HydraulicResistance
    hydraulicResistanceSplitterOut =                                              2000
    "Hydraulic resistance at splitter outlets"
                                             annotation(Dialog(group="Pressure loss"));

parameter Modelica.SIunits.MassFlowRate m_flowGas_start=228.68
    "Flue gas mass flow rate"
                            annotation (Dialog(tab="Initialization", group="Flue gas flow"));
parameter GasMedium.Temperature TGasIn_start=390 "Inlet gas temperature"
  annotation (Dialog(tab="Initialization", group="Flue gas flow"));
parameter GasMedium.Temperature TGasOut_start = TGasIn_start
    "Outlet gas temperature"
  annotation (Dialog(tab="Initialization", group="Flue gas flow"));
parameter Modelica.SIunits.MassFlowRate m_flow_start=19.05
    "Total water/steam mass flow rate"
                                     annotation (Dialog(tab="Initialization", group="Water flow"));
parameter GasMedium.AbsolutePressure pIn_start=pOut_start+2e5
    "start value for inlet pressure"                          annotation(Dialog(tab="Initialization", group="Water flow"));
parameter GasMedium.AbsolutePressure pOut_start=137e5
    "start value for outlet pressure"                            annotation(Dialog(tab="Initialization", group="Water flow"));
parameter GasMedium.SpecificEnthalpy hIn_start=500e3
    "start value for inlet enthalpy"                                    annotation(Dialog(tab="Initialization", group="Water flow"));
parameter GasMedium.SpecificEnthalpy hOut_start=hIn_start
    "start value for outlet enthalpy"                                 annotation(Dialog(tab="Initialization", group="Water flow"));

 parameter Boolean initializeInletPressure = true
    "add steady state equation for pressure"                                               annotation(Dialog(tab="Initialization", group="Water flow"));
parameter Boolean initializeSteadyStateEnthalpies=true
    "lets initialize der(h)=0"                                                    annotation(evaluate=true, Dialog(tab="Initialization", group="Water flow"));
parameter Boolean initializeSteadyStateInletEnthalpy=true
    "steady state initial condition for input enthalpy"
                                                      annotation(evaluate=true, Dialog(tab="Initialization", group="Water flow", enable=initializeSteadyStateEnthalpies));
parameter Boolean useHeatInput=true "Initialisation of qmf_del=qmf" annotation(Dialog(tab="Initialization",  group="Heat transfer"));
parameter Boolean initializeWithZeroInnerHeatFlow=false
    "Initialisation of qmf_del=0"                                                     annotation(Dialog(tab="Initialization", group="Heat transfer",enable=(useHeatInput==false)));
parameter String initOptWall = "steadyState" "Initialisation option" annotation (Dialog(tab="Initialization",group="Wall"),
choices(
  choice="noInit" "No initial equations",
  choice="steadyState" "Steady-state initialization",
  choice="fixedTemperature" "Fixed-temperatures initialization"));

SiemensPowerOMCtest.Components.FlueGasZones.FlueGasZoneSingleTube[numberOfTubeLayers]
    flueGasZone(
    redeclare each package GasMedium = GasMedium,
  each numberOfTubeNodes=
         numberOfCellsPerLayer,
  each numberOfWallLayers=
             numberOfWallLayers,
  each geoPipe=
            geoPipe,
  each m_flowGas_start=
                  m_flowGas_start,
  each TGasIn_start= TGasIn_start,
  each TGasOut_start=TGasOut_start,
  each cleanliness=cleanlinessFactor,
  each geoFins=
           geoFins,
  each geoFGZ=
           geoFGZ,
  each metal=propertiesMetal,
  each heatloss=heatloss,
  each m_flow_start=
               m_flow_start/numberOfTubeLayers,
  each pIn_start=
          pIn_start,
  each pOut_start=
          pOut_start,
  each hIn_start=
          hIn_start,
  each hOut_start=
          hOut_start,
  redeclare each model heattransfer = innerHeatTransfer,
  redeclare each model friction = friction,
  redeclare package H2OMedium = WaterMedium,
  redeclare outerHeatTransfer heatTransfer,
  each delayInnerHeatTransfer=
                     delayInnerHeatTransfer,
  each timeDelayOfInnerHeatTransfer=
               timeDelayOfInnerHeatTransfer,
  each hydraulicResistance_gas=
         hydraulicResistanceGasFLow,
  each initializeSteadyStateEnthalpies=
                    initializeSteadyStateEnthalpies,
  each initializeSteadyStateInletEnthalpy=
                              initializeSteadyStateInletEnthalpy,
  each useHeatInput= useHeatInput,
  each initializeWithZeroInnerHeatFlow=
                initializeWithZeroInnerHeatFlow,
  each initializationOption=initOptWall,
  each initializeInletPressure=
              initializeInletPressure)
  annotation (Placement(transformation(extent={{-10,-10},{10,10}}, rotation=0)));

SiemensPowerOMCtest.Components.Junctions.SplitterMixer splitter(
  V=0.1*(numberOfTubeLayers+1),
  h_start=hIn_start,
  hasVolume=false,
  p_start=pIn_start,
  hasPressureDrop=true,
  numberOfPortsSplit=numberOfTubeLayers,
  m_flow_start=m_flow_start,
  redeclare package Medium = WaterMedium,
  resistanceHydraulic=hydraulicResistanceSplitterOut)           annotation (Placement(transformation(extent={{-10,-50},{10,
          -30}}, rotation=0)));
SiemensPowerOMCtest.Components.Junctions.SplitterMixer mixer(
  h_start=hOut_start,
  resistanceHydraulic=2,
  hasPressureDrop=false,
  p_start=pOut_start,
  numberOfPortsSplit=numberOfTubeLayers,
  m_flow_start=-m_flow_start,
  redeclare package Medium = WaterMedium,
  hasVolume=hasMixerVolume,
  V=V)            annotation (Placement(transformation(extent={{-10,60},{12,
          36}}, rotation=0)));

Modelica.Fluid.Interfaces.FluidPort_b portSteamOut(redeclare package Medium =
      WaterMedium)
  annotation (Placement(transformation(extent={{20,80},{-20,120}}, rotation=0)));
Modelica.Fluid.Interfaces.FluidPort_a portWaterIn(redeclare package Medium =
      WaterMedium)
  annotation (Placement(transformation(extent={{-20,-120},{20,-80}}, rotation=
         0)));
SiemensPowerOMCtest.Interfaces.portGasOut portGasOut(
                                             redeclare package Medium = GasMedium, m_flow(start=-m_flowGas_start)) annotation (Placement(
      transformation(extent={{80,-20},{120,20}}, rotation=0)));
SiemensPowerOMCtest.Interfaces.portGasIn portGasIn(redeclare package Medium = GasMedium, m_flow(start=m_flowGas_start))
  annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
         0)));
equation

connect(flueGasZone[1].portGasIn,portGasIn)
  annotation (Line(points={{-10,0},{-100,0}}, color={0,191,0}));
for i in 1:(numberOfTubeLayers-1) loop
    connect(flueGasZone[i].portGasOut,flueGasZone[i + 1].portGasIn);
end for;
connect(flueGasZone[numberOfTubeLayers].portGasOut,
                                   portGasOut) annotation (Line(points={{10,0},
        {100,0}}, color={0,191,0}));
connect(splitter.portMix, portWaterIn)
  annotation (Line(points={{0,-49},{0,-100}}, color={0,127,255}));
connect(mixer.portMix, portSteamOut) annotation (Line(points={{1,58.8},{1,58.4},{
        0,58.4},{0,100}}, color={0,127,255}));
connect(flueGasZone.portIn,splitter.portsSplit) annotation (Line(points={{0,-8},
        {0,-31}}, color={0,127,255}));
connect(mixer.portsSplit,flueGasZone.portOut) annotation (Line(points={{1,37.2},{
        1,22.6},{0,22.6},{0,8}}, color={0,127,255}));
annotation (uses(Modelica(version="2.2.1"), SiemensPower(version="0.9")),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
          100,100}}),
            graphics),
  Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
          100}}), graphics={
      Rectangle(
        extent={{-64,60},{-54,-60}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-24,60},{-14,-60}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{16,60},{26,-60}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{54,60},{64,-60}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-64,-70},{64,-60}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-64,60},{64,70}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-4,80},{6,70}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Rectangle(
        extent={{-4,-70},{6,-80}},
        lineColor={0,0,255},
        pattern=LinePattern.None,
        fillColor={0,128,255},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{-80,4},{-68,4},{-68,8},{-64,0},{-68,-6},{-68,-2},{-80,-2},{-80,
            4}},
        lineColor={255,0,0},
        fillColor={255,0,0},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{-46,4},{-34,4},{-34,8},{-30,0},{-34,-6},{-34,-2},{-46,-2},{-46,
            4}},
        lineColor={255,0,0},
        fillColor={255,0,0},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{-6,4},{6,4},{6,8},{10,0},{6,-6},{6,-2},{-6,-2},{-6,4}},
        lineColor={255,0,0},
        fillColor={255,0,0},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{34,4},{46,4},{46,8},{50,0},{46,-6},{46,-2},{34,-2},{34,4}},
        lineColor={255,0,0},
        fillColor={255,0,0},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{66,4},{76,4},{76,8},{80,0},{76,-6},{76,-2},{66,-2},{66,4}},
        lineColor={255,0,0},
        fillColor={255,0,0},
        fillPattern=FillPattern.Solid)}),
    Documentation(
   info="<HTML>
        <p>
           This is an evaporator with parallel rows according to Cottam design
          <ul>
               <li> The gas flow is modeled using a simple quasi stationary pressure drop.
               <li> The water/steam flow and inner heat transfer is modeled using the <bf>Components.Pipes.Tube</bf> model.
               <li> The outer heat transfer gas-propertiesMetal  can be chosen from
                    <ul>
                       <li> Escoa correlation, see <i>Chris Weierman, Correlations ease the selection of finned tubes, The Oil and Gas Journal, Sept. 6, 1976</i>;
                            Update (Fintube Corp. <a href=\"http://www.fintubetech.com/escoa/manual.exe\">ESCOA Engineering Manual</a>) from July 2002.
                       <li> Simple heat transfer with constant heat transfer coefficient.
                    </ul>
          </ul>
<p>
           The model restrictions are:
                <ul>
                        <li> see composits
                </ul>
        </p>
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
     </HTML>",
   revisions="<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>"));
end ParallelFlowEvaporator;
