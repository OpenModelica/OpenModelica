within SiemensPowerOMCtest.Components.FlueGasZones;
model FlueGasZoneSingleTube
  "Flue gas zone including a single water/steam tube as basis component for higher level flue gas zones"
  import SI = Modelica.SIunits;

  constant Real pi=Modelica.Constants.pi;

 replaceable package GasMedium =  SiemensPowerOMCtest.Media.ExhaustGas constrainedby
    Modelica.Media.Interfaces.PartialMedium "Flue gas medium"
      annotation (   choicesAllMatching=true, Dialog(group="Media"));

  replaceable package H2OMedium = Modelica.Media.Water.WaterIF97_ph
    constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium
    "Water/steam medium"                            annotation (choicesAllMatching=
        true, Dialog(group="Media"));

//  parameter Integer Np=10 "Number of parallel layers (= no of gas nodes)";
  parameter Integer numberOfTubeNodes=2 "Number of water nodes per tube"
                                                                        annotation (Dialog(group="Discretization"));
  parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers" annotation(Dialog(group="Discretization"), choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
  parameter Modelica.Fluid.Types.HydraulicResistance hydraulicResistance_gas=2
    "Hydraulic resistance for gas flow"            annotation(Dialog(group="Pressure loss"));
  replaceable model friction =
      SiemensPowerOMCtest.Utilities.PressureLoss.RoughnessFlow constrainedby
    SiemensPowerOMCtest.Utilities.PressureLoss.PartialFrictionSinglePhase
    "Inner flow friction pressure loss correlation"   annotation (Dialog(group="Pressure loss"), choicesAllMatching=true);

  replaceable model heattransfer =
      SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.SinglePhase
  constrainedby
    SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransferSinglePhase
    "Inner heat transfer correlation" annotation (Dialog(tab="Heat transfer", group="Inner heat transfer"),
      choicesAllMatching=true);

  parameter Boolean delayInnerHeatTransfer=false "With delay of qmf" annotation(Dialog(tab="Heat transfer", group="Inner heat transfer"));
  parameter SI.Time timeDelayOfInnerHeatTransfer=0.1
    "artificial delay time for qmf"                     annotation(Dialog(tab="Heat transfer", group="Inner heat transfer",enable=delayInnerHeatTransfer));
  parameter Modelica.SIunits.MassFlowRate m_flow_start=19.05
    "Total water/steam mass flow rate" annotation (Dialog(tab="Initialization", group="Water flow"));
  parameter H2OMedium.AbsolutePressure pIn_start = pOut_start+2e5
    "start value for inlet pressure"                            annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter H2OMedium.AbsolutePressure pOut_start = 137e5
    "start value for outlet pressure"                              annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter H2OMedium.SpecificEnthalpy hIn_start = 500e3
    "start value for inlet enthalpy"                                      annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter H2OMedium.SpecificEnthalpy hOut_start = hIn_start
    "start value for outlet enthalpy"                                   annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter GasMedium.AbsolutePressure pGas_start = 1.0e5 "Gas pressure"
    annotation (Dialog(tab="Initialization", group="Gas"));
  parameter GasMedium.Temperature TGasIn_start=300.0 "Inlet gas temperature"
    annotation (Dialog(tab="Initialization", group="Gas"));
  parameter GasMedium.Temperature TGasOut_start=TGasIn_start
    "Outlet gas temperature"
    annotation (Dialog(tab="Initialization", group="Gas"));
  parameter GasMedium.MassFlowRate m_flowGas_start=1 "Gas mass flow rate"
                         annotation (Dialog(tab="Initialization", group="Gas"));

  parameter Boolean initializeInletPressure = true
    "add steady state equation for pressure"                                                annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter Boolean initializeSteadyStateEnthalpies=true
    "lets initialize der(h)=0"                                                      annotation(evaluate=true, Dialog(tab="Initialization", group="Water flow"));
  parameter Boolean initializeSteadyStateInletEnthalpy=true
    "steady state initial condition for input enthalpy" annotation(evaluate=true, Dialog(tab="Initialization", group="Water flow", enable=initializeSteadyStateEnthalpies));
  parameter Boolean useHeatInput=true "Initialisation of qmf_del=qmf" annotation(Dialog(tab="Initialization",  group="Heat transfer"));
  parameter Boolean initializeWithZeroInnerHeatFlow=false
    "Initialisation of qmf_del=0"                                                       annotation(Dialog(tab="Initialization", group="Heat transfer",enable=(useHeatInput==false)));
  parameter String initializationOption="steadyState" "Initialisation option" annotation (Dialog(tab="Initialization",group="Wall"),
  choices(
    choice="noInit" "No initial equations",
    choice="steadyState" "Steady-state initialization",
    choice="fixedTemperature" "Fixed-temperatures initialization"));
  parameter H2OMedium.Temperature TWall_start[numberOfTubeNodes]=T_start
    "Start values for wall temperatures"
                                       annotation (Dialog(tab="Initialization",group="Wall"));

  parameter SiemensPowerOMCtest.Utilities.Structures.FgzGeo geoFGZ
    "Geometry of flue gas zone"  annotation (Dialog(group="Geometry"));
  parameter SiemensPowerOMCtest.Utilities.Structures.Fins geoFins
    "Geometry of outer wall fins"   annotation (Dialog(group="Geometry"));
  parameter SiemensPowerOMCtest.Utilities.Structures.PipeGeo geoPipe
    "Geometry of tubes"                                                             annotation (Dialog(group="Geometry"));
  parameter SiemensPowerOMCtest.Utilities.Structures.PropertiesMetal metal
    "Tube wall properties"                                                           annotation (Dialog(group="Media"));
  parameter Real cleanliness=1.0 "Cleanliness factor" annotation (Dialog(tab="Heat transfer", group="Outer heat transfer"));

  parameter Boolean computeHeatLossInPercent = true "instead of alpha and Tamb"
                                                                                annotation(Dialog(tab="Heat transfer", group="Heat loss to ambient"));
  parameter Real heatloss=0.5 "Heat loss to ambient in %" annotation (Dialog(tab="Heat transfer", group="Heat loss to ambient", enable=computeHeatLossInPercent));
  parameter SI.CoefficientOfHeatTransfer kLossToAmbient = 0.4
    "heat loss coefficient" annotation(Dialog(tab="Heat transfer", group="Heat loss to ambient", enable=not computeHeatLossInPercent));
  parameter GasMedium.Temperature T_ambient=300 "ambient temperature" annotation(Dialog(tab="Heat transfer", group="Heat loss to ambient", enable=not computeHeatLossInPercent));

  SiemensPowerOMCtest.Interfaces.portGasIn portGasIn(redeclare package Medium
      =                                                                         GasMedium, m_flow(start=m_flowGas_start))
    annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
           0)));
  SiemensPowerOMCtest.Interfaces.portGasOut portGasOut(
                                               redeclare package Medium = GasMedium, m_flow(start=-m_flowGas_start)) annotation (Placement(
        transformation(extent={{80,-20},{120,20}}, rotation=0)));
   Modelica.Fluid.Interfaces.FluidPort_a portIn(redeclare package Medium = H2OMedium, m_flow(start=m_flow_start))
    "water inlet"
    annotation (Placement(transformation(extent={{-20,-100},{20,-60}}, rotation=
           0)));
  Modelica.Fluid.Interfaces.FluidPort_b portOut(redeclare package Medium = H2OMedium, m_flow(start=-m_flow_start))
    "water moutlet"
    annotation (Placement(transformation(extent={{-20,60},{20,100}}, rotation=0)));

   SI.HeatFlowRate[numberOfTubeNodes] Q_flowToAmbient
    "Heat flow rates to ambient";

  SiemensPowerOMCtest.Components.Pipes.Tube tube(
    redeclare package Medium = H2OMedium,
    numberOfNodes=numberOfTubeNodes,
    geoPipe=geoPipe,
    considerDynamicPressure=false,
    pIn_start=pIn_start,
    pOut_start=pOut_start,
    hIn_start=hIn_start,
    hOut_start=hOut_start,
    m_flow_start=m_flow_start,
    metal=metal,
    numberOfWallLayers=numberOfWallLayers,
    redeclare model heattransfer = heattransfer,
    redeclare model Friction = friction,
    delayInnerHeatTransfer = delayInnerHeatTransfer,
    timeDelayOfInnerHeatTransfer = timeDelayOfInnerHeatTransfer,
    initializeSteadyStateEnthalpies=initializeSteadyStateEnthalpies,
    initializeSteadyStateInletEnthalpy=initializeSteadyStateInletEnthalpy,
    useHeatInput=useHeatInput,
    initializeWithZeroInnerHeatFlow=initializeWithZeroInnerHeatFlow,
    initOptWall=initializationOption,
    TWall_start=TWall_start,
    initializeInletPressure=initializeInletPressure)            annotation (Placement(transformation(
        origin={-2,4},
        extent={{-10,-10},{10,10}},
        rotation=90)));

replaceable SiemensPowerOMCtest.Utilities.HeatTransfer.HeatTransfer_constAlpha
    heatTransfer(
    redeclare package Medium = GasMedium,
    numberOfNodes=numberOfTubeNodes,
    lengthRe=lengthCharacteristicRe,
    lengthNu = 0.5*pi*geoPipe.d_out,
    AHeatTransfer=Ah,
    ACrossFlow=geoFGZ.Lw*geoFGZ.Ld,
    geoFGZ=geoFGZ,
    geoFins=geoFins,
    geoPipe=geoPipe,
    m_flow=m_flow,
    state=state_gas) constrainedby
    SiemensPowerOMCtest.Utilities.HeatTransfer.HeatTransferBaseClass(
    redeclare package Medium = GasMedium,
    numberOfNodes=numberOfTubeNodes,
    lengthRe=lengthCharacteristicRe,
    lengthNu = 0.5*pi*geoPipe.d_out,
    AHeatTransfer=Ah,
    ACrossFlow=geoFGZ.Lw*geoFGZ.Ld,
    geoFGZ=geoFGZ,
    geoFins=geoFins,
    geoPipe=geoPipe,
    m_flow=m_flow,
    state=state_gas) "Convective heat transfer"
            annotation (Dialog(tab="Heat transfer", group="Outer heat transfer"),editButton=true,choicesAllMatching,
    Placement(transformation(extent={{-72,-58},{-32,-18}},rotation=0)));

  GasMedium.BaseProperties mediumGasOut(
    p(start=pGas_start),
    T(start=TGasOut_start));
  GasMedium.BaseProperties mediumGas(
    p(start=pGas_start),
    T(start=0.5*(TGasOut_start+TGasIn_start)));
   GasMedium.BaseProperties mediumGasIn(
    p(start=pGas_start),
    T(start=TGasIn_start));
  GasMedium.MassFlowRate m_flowGas(start=m_flowGas_start) "Mass flow rate";
  GasMedium.ThermodynamicState state_gas( T(start=0.5*(TGasIn_start+TGasOut_start)),  p(start=pGas_start))
    "gas medium properties";
  GasMedium.MassFlowRate m_flow(start=m_flowGas_start) "Mass flow rate";
  inner GasMedium.Temperature TWall[numberOfTubeNodes];
  SI.Volume V_gas "volume of gas layer";
  SI.TemperatureDifference deltaT[numberOfTubeNodes];

protected
  final parameter H2OMedium.Temperature T_start[numberOfTubeNodes]=H2OMedium.temperature_phX(linspace(pIn_start,pOut_start,numberOfTubeNodes),linspace(hIn_start,hOut_start,numberOfTubeNodes), H2OMedium.reference_X)
    "start values for fluid temperatures";
  final parameter SI.Length lengthCharacteristicRe = (if geoFins.finned then geoPipe.d_out else 0.5*pi*geoPipe.d_out);
  final parameter SI.Area Ah=geoPipe.Nt*pi*geoPipe.d_out*geoPipe.L
    "Heat transfer area of unfinned tubes";

  Real temperatureRate[numberOfTubeNodes];

// Real [numberOfTubeNodes] logarithm;

public
  SiemensPowerOMCtest.Components.SolidComponents.Fins fins(
    numberOfNodes=numberOfTubeNodes,
    geoFins=geoFins,
    geoPipe=geoPipe,
    metal=metal,
    T_start=TWall_start)    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={-28,4})));
  SiemensPowerOMCtest.Interfaces.portHeat heatPortToGas(numberOfNodes=numberOfTubeNodes)
    annotation (Placement(transformation(extent={{-62,-28},{-42,-8}})));
initial equation
  der(mediumGasOut.h)=0;

equation

// heat transfer inputs
  state_gas=mediumGas.state;
  m_flow = m_flowGas;

// relevant medium for heat transfer
  mediumGas.p  = (portGasIn.p+portGasOut.p)/2;
  mediumGas.T = 0.5*(mediumGasIn.T+mediumGasOut.T);
  mediumGas.Xi = inStream(portGasIn.Xi_outflow);

  mediumGasIn.p  = portGasIn.p;
  mediumGasOut.p  = portGasOut.p;
  m_flowGas*hydraulicResistance_gas = portGasIn.p - portGasOut.p; // gas pressure drop

  m_flowGas = portGasIn.m_flow;
  portGasIn.m_flow + portGasOut.m_flow = 0;

  mediumGasIn.h = inStream(portGasIn.h_outflow);
  mediumGasIn.Xi  = mediumGas.Xi;
  mediumGasOut.Xi = mediumGas.Xi;

  portGasIn.h_outflow = mediumGasOut.h;
  portGasOut.h_outflow = mediumGasOut.h;

  portGasIn.Xi_outflow = inStream(portGasOut.Xi_outflow);
  portGasOut.Xi_outflow = inStream(portGasIn.Xi_outflow);

  V_gas=geoFGZ.Lh*geoFGZ.Lw*(geoFGZ.Ld-geoPipe.L*geoPipe.d_out/geoFGZ.pt);
  m_flowGas*(actualStream(portGasIn.h_outflow) - actualStream(portGasOut.h_outflow))+sum(heatPortToGas.Q_flow +Q_flowToAmbient) =
         V_gas*mediumGasOut.d*der(mediumGasOut.h);

   if (computeHeatLossInPercent) then

    Q_flowToAmbient = heatPortToGas.Q_flow*heatloss/100.0;
  else
    Q_flowToAmbient = ones(numberOfTubeNodes)/numberOfTubeNodes*kLossToAmbient*(T_ambient-mediumGas.T)*2*geoFGZ.Lh*(geoFGZ.Lw+geoFGZ.Ld);
  end if;

 // heat transfer

 for i in 1:numberOfTubeNodes loop

   if noEvent((TWall[i] - mediumGasOut.T > 1e-4) or (TWall[i] - mediumGasOut.T < -1e-4)) then
       temperatureRate[i] = (TWall[i] - mediumGasIn.T)/(TWall[i] - mediumGasOut.T);
   elseif noEvent(TWall[i] - mediumGasOut.T > 0) then
       temperatureRate[i] = (TWall[i] - mediumGasIn.T)/1e-4;
   else
      temperatureRate[i] =  -(TWall[i] - mediumGasIn.T)/1e-4;
   end if;

   if (abs(mediumGasOut.T-mediumGasIn.T) <1e-5) then
      deltaT[i] = TWall[i] - mediumGasOut.T;
   else
      deltaT[i] = (mediumGasOut.T- mediumGasIn.T) / Modelica.Math.log(max(1e-6, temperatureRate[i]));
   end if;

 heatPortToGas.Q_flow[i]=cleanliness*heatTransfer.heatingSurfaceFactor*heatTransfer.alpha[i]*Ah/numberOfTubeNodes*deltaT[i];
   end for;

  connect(tube.portIn, portIn) annotation (Line(points={{-2,-6},{-2,-43.25},{0,
          -43.25},{0,-80}},            color={0,127,255}));
  connect(tube.portOut, portOut) annotation (Line(points={{-2,14},{-2,44.35},{0,
          44.35},{0,80}},    color={0,127,255}));

  connect(fins.heatportsGas, heatPortToGas.port) annotation (Line(
      points={{-32.4,4},{-52,4},{-52,-14.6}},
      color={191,0,0},
      pattern=LinePattern.None,
      smooth=Smooth.None));

  connect(fins.heatportsTube, tube.heatPort) annotation (Line(
      points={{-25.6,4.1},{-16.8,4.1},{-16.8,4},{-8.6,4}},
      color={191,0,0},
      smooth=Smooth.None));
annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},
            {100,100}}), graphics={Text(
          extent={{-72,24},{76,-16}},
          lineColor={0,0,0},
          textString="%name")}),            Diagram(coordinateSystem(
          preserveAspectRatio=true,  extent={{-100,-100},{100,100}}), graphics),
  Documentation(
     info="<HTML>
        <p>
           This is a flue gas zone including a single water/steam tube as basis component for higher level flue gas zones  <br>
The flue gas flows perpendicular to the water/steam
          <ul>
               <li> The gas flow is modeled using a simple quasi stationary pressure drop.
               <li> The water/steam flow and inner heat transfer is modeled using the <bf>Components.Pipes.Tube</bf> model.
               <li> The outer heat transfer gas-metal can be chosen from
                    <ul>
                       <li> Escoa correlation, see <i>Chris Weierman, Correlations ease the selection of finned tubes, The Oil and Gas Journal, Sept. 6, 1976</i>;
                            Update (Fintube Corp. <a href=\"http://www.fintubetech.com/escoa/manual.exe\">ESCOA Engineering Manual</a>) from July 2002.
                       <li> Simple heat transfer with constant heat transfer coefficient.
                    </ul>
          </ul>
<p>
           The model restrictions are:
                <ul>
                        <li> Cross flow configurations (gas flow is perpendicular to water/steam flow)
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
                           <td><b>Checked by: </b>   </td>
                           <td>  Stephanie Vogel          </td>
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
end FlueGasZoneSingleTube;
