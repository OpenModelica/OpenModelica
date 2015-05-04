within SiemensPower.Components.FlueGasZones;
model FlueGasZoneSingleTubeOwnMedia
  "Flue gas zone including a single water/steam tube as basis component for higher level flue gas zones"

  import SI = SiemensPower.Units;
  constant Real pi=Modelica.Constants.pi;

// replaceable package GasMedium =  SiemensPower.Media.ExhaustGas constrainedby
//    Modelica.Media.Interfaces.PartialMedium "Flue gas medium"
//      annotation (   choicesAllMatching=true, Dialog(group="Media"));

//  replaceable package H2OMedium = Modelica.Media.Water.WaterIF97_ph
//    constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium
//    "Water/steam medium"                            annotation (choicesAllMatching=
//        true, Dialog(group="Media"));

//  parameter Integer Np=10 "Number of parallel layers (= no of gas nodes)";
  parameter Integer numberOfTubeNodes=2 "Number of water nodes per tube";
  parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers" annotation(choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
  parameter Modelica.Fluid.Types.HydraulicResistance hydraulicResistance_gas=2
    "Hydraulic conductance (for gas pressure drop)";
  parameter SI.CoefficientOfHeatTransfer alphaOffset=0.5e3
    "alpha offset (in case of verysimple=true)"                    annotation(Dialog(tab="Inner heat transfer", enable=verysimple));
  parameter Real alphaFactor=1.0
    "Factor for state dependent alpha term (in case of verysimple=true)"                    annotation(Dialog(tab="Inner heat transfer", enable=verysimple));

  parameter Modelica.SIunits.MassFlowRate m_flow_start=19.05
    "Total water/steam mass flow rate" annotation (Dialog(tab="Initialization", group="Water flow"));
  parameter SiemensPower.Units.AbsolutePressure pIn_start=pOut_start+2e5
    "start value for inlet pressure"                            annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter SiemensPower.Units.AbsolutePressure pOut_start=137e5
    "start value for outlet pressure"                              annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter SiemensPower.Units.SpecificEnthalpy hIn_start=500e3
    "start value for inlet enthalpy"                                      annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter SiemensPower.Units.SpecificEnthalpy hOut_start=hIn_start
    "start value for outlet enthalpy"                                   annotation(Dialog(tab="Initialization", group="Water flow"));
  parameter SiemensPower.Units.Pressure pGas_start=1.0e5 "Gas pressure"
    annotation (Dialog(tab="Initialization", group="Gas"));
  parameter SiemensPower.Units.Temperature TGasIn_start=300.0
    "Inlet gas temperature"
    annotation (Dialog(tab="Initialization", group="Gas"));
  parameter SiemensPower.Units.Temperature TGasOut_start=TGasIn_start
    "Outlet gas temperature"
    annotation (Dialog(tab="Initialization", group="Gas"));
  parameter SiemensPower.Units.MassFlowRate m_flowGas_start=1
    "Gas mass flow rate" annotation (Dialog(tab="Initialization", group="Gas"));
  parameter SiemensPower.Utilities.Structures.FgzGeo geoFGZ
    "Geometry of flue gas zone"  annotation (Dialog(group="Geometry"));
  parameter SiemensPower.Utilities.Structures.Fins geoFins
    "Geometry of outer wall fins"   annotation (Dialog(group="Geometry"));
  parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
    "Geometry of tubes"                                                             annotation (Dialog(group="Geometry"));
  parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
    "Tube wall properties"                                                           annotation (Dialog(group="Media"));
  parameter Real cleanliness=1.0 "Cleanliness factor";
  parameter Real heatloss=0.5 "Heat loss to ambient in %";
//  parameter Boolean hasCriticalData=(if GasMedium.nX>1 then true else false) annotation(Dialog(tab="No input", enable=false));
  parameter SI.Length d_ch_Re = (if geoFins.finned then geoPipe.d_out else 0.5*pi*geoPipe.d_out) annotation(Dialog(tab="No input", enable=false));
  parameter SI.Area Ah=geoPipe.Nt*pi*geoPipe.d_out*geoPipe.L
    "Heat transfer area of unfinned tubes" annotation(Dialog(tab="No input", enable=false));

  SI.Temperature T;
  SI.Temperature TIn;
  SI.Temperature TOut;
  SI.Pressure p;
  SI.Pressure pIn;
  SI.Pressure pOut;
  SI.SpecificEnthalpy hIn;
  SI.SpecificEnthalpy hOut;
  SI.Density dOut;
//  SI.SpecificHeatCapacity cpGasIn;
//  SI.SpecificHeatCapacity cpGasOut;
  parameter Real R_s = 292.505;
  SiemensPower.Interfaces.portGasIn portGasIn(m_flow(start=m_flowGas_start))
    annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
           0)));
  SiemensPower.Interfaces.portGasOut portGasOut(m_flow(start=-m_flowGas_start)) annotation (Placement(
        transformation(extent={{80,-20},{120,20}}, rotation=0)));
   SiemensPower.Interfaces.FluidPort_a portIn(m_flow(start=m_flow_start))
    "water inlet"
    annotation (Placement(transformation(extent={{-20,-100},{20,-60}}, rotation=
           0)));
  SiemensPower.Interfaces.FluidPort_b portOut( m_flow(start=-m_flow_start))
    "water moutlet"
    annotation (Placement(transformation(extent={{-20,60},{20,100}}, rotation=0)));
  SiemensPower.Components.Pipes.TubeOwnMedia tube(
    numberOfNodes=numberOfTubeNodes,
    geoPipe=geoPipe,
    considerMassAccelaration=false,
    considerDynamicPressure=false,
    pIn_start=pIn_start,
    pOut_start=pOut_start,
    hIn_start=hIn_start,
    hOut_start=hOut_start,
    m_flow_start=m_flow_start,
    metal=metal,
    numberOfWallLayers=numberOfWallLayers,
    useINTH2O=false)             annotation (Placement(transformation(
        origin={-2,4},
        extent={{-10,-10},{10,10}},
        rotation=90)));

replaceable SiemensPower.Utilities.HeatTransfer.HeatTransfer_constAlpha
    heatTransfer(
    numberOfNodes=numberOfTubeNodes,
    lengthRe=d_ch_Re,
    lengthNu = 0.5*pi*geoPipe.d_out,
    AHeatTransfer=Ah,
    ACrossFlow=geoFGZ.Lw*geoFGZ.Ld,
    geoFGZ=geoFGZ,
    geoFins=geoFins,
    geoPipe=geoPipe)
      constrainedby SiemensPower.Utilities.HeatTransfer.HeatTransferBaseClass(
    numberOfNodes=numberOfTubeNodes,
    lengthRe=d_ch_Re,
    lengthNu = 0.5*pi*geoPipe.d_out,
    AHeatTransfer=Ah,
    ACrossFlow=geoFGZ.Lw*geoFGZ.Ld,
    geoFGZ=geoFGZ,
    geoFins=geoFins,
    geoPipe=geoPipe) "Convective heat transfer"
            annotation (Dialog(tab="General", group="Outer heat transfer"),editButton=true,choicesAllMatching,
    Placement(transformation(extent={{-72,-46},{-32,-6}}, rotation=0)));
    //redeclare package Medium = GasMedium,
                   //,
    //state=state
  //  m_flow=m_flow,
 //   m_flow=m_flow,

//  GasMedium.BaseProperties mediumOut(
//    p(start=pGas_start),
//    T(start=TGasOut_start));
 // GasMedium.BaseProperties medium(
 //   p(start=pGas_start),
//    T(start=0.5*(TGasOut_start+TGasIn_start)));
//   GasMedium.BaseProperties mediumIn(
//    p(start=pGas_start),
//    T(start=TGasIn_start));
  SiemensPower.Units.MassFlowRate m_flowGas(start=m_flowGas_start)
    "Mass flow rate";
 // GasMedium.ThermodynamicState state(T(start=0.5*(TGasIn_start+TGasOut_start)),  p(start=pGas_start))
 //   "gas medium properties";
  SiemensPower.Units.MassFlowRate m_flow(start=m_flowGas_start)
    "Mass flow rate";
  inner SiemensPower.Units.Temperature TWall[numberOfTubeNodes];

  SI.Volume VGas "volume of gas layer";
//  SI.Temperature TwallOutAv;
  SI.TemperatureDifference dT[numberOfTubeNodes];
 SiemensPower.Interfaces.portHeat heatPortToWall(numberOfNodes=numberOfTubeNodes, TWall = TWall);

SI.HeatFlowRate[numberOfTubeNodes] Q_flowToAmbient "Heat flow rates to ambient";
initial equation
  der(hOut)=0;

equation

  m_flow = m_flowGas;

  p  = (portGasIn.p+portGasOut.p)/2;
  T = 0.5*(TIn+TOut);

  //medium.Xi = inStream(portGasIn.Xi_outflow);

  hIn = SiemensPower.Utilities.Functions.hT_FDBR82(TIn);
  hOut = SiemensPower.Utilities.Functions.hT_FDBR82(TOut);

  pIn  = portGasIn.p;
  pOut  = portGasOut.p;
  m_flowGas*hydraulicResistance_gas = portGasIn.p - portGasOut.p; // gas pressure drop

  m_flowGas = portGasIn.m_flow;
  portGasIn.m_flow + portGasOut.m_flow = 0;

  hIn = inStream(portGasIn.h_outflow);

  portGasIn.h_outflow = hOut;
  portGasOut.h_outflow = hOut;

//  portGasIn.Xi_outflow = inStream(portGasOut.Xi_outflow);
//  portGasOut.Xi_outflow = inStream(portGasIn.Xi_outflow);
  VGas=geoFGZ.Lh*geoFGZ.Lw*(geoFGZ.Ld-geoPipe.L*geoPipe.d_out/geoFGZ.pt);
  m_flowGas*(actualStream(portGasIn.h_outflow) - actualStream(portGasOut.h_outflow))+sum(heatPortToWall.Q_flow +Q_flowToAmbient)  =  VGas*dOut*der(hOut);
  pOut = dOut * R_s * TOut;
// dOut = 0.536;
 //RhoGas = 0.52;//pGas / (R_s *TGas);
 Q_flowToAmbient = heatPortToWall.Q_flow*heatloss/100.0;

 for i in 1:numberOfTubeNodes loop

  dT[i] = TWall[i] - 0.5*(TOut+TIn);

heatPortToWall.Q_flow[i]=cleanliness*heatTransfer.heatingSurfaceFactor*heatTransfer.alpha[i]*Ah/numberOfTubeNodes*dT[i];
  end for;

  connect(tube.portIn, portIn) annotation (Line(points={{-2,-6},{-2,-43.25},{0,
          -43.25},{0,-80}},            color={0,127,255}));
  connect(tube.portOut, portOut) annotation (Line(points={{-2,14},{-2,44.35},{0,
          44.35},{0,80}},    color={0,127,255}));
  connect(heatPortToWall.port, tube.gasSide) annotation (Line(points={{-52,-12},
          {-52,4},{-8.6,4}},      color={191,0,0}));

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
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
     </HTML>",
     revisions="<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>"));
end FlueGasZoneSingleTubeOwnMedia;
