within SiemensPowerOMCtest.Pipes;
model Tube
  "Tube (incl wall) with detailed energy, integrated momentum and mass balance"

  import SI = Modelica.SIunits;
extends SiemensPowerOMCtest.Pipes.TubeWithoutWall(final useEnergyStorage=true,
      redeclare SI.HeatFlux qHeating=qMetalFluidDelayed);

  // heat transfer parameters
  replaceable model heattransfer =
      SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.SinglePhase
  constrainedby
    SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransferSinglePhase
    "Inner heat transfer correlation" annotation (Dialog(group="Geometry and correlations"),
      choicesAllMatching=true);
  parameter Boolean delayInnerHeatTransfer=false "With delay of qMetalFluid" annotation(Dialog(tab="Advanced", group="Inner heat transfer"));
  parameter SI.Time timeDelayOfInnerHeatTransfer=0.1
    "artificial delay time for qMetalFluid"             annotation(Dialog(tab="Advanced", group="Inner heat transfer",enable=delayInnerHeatTransfer));

  // Initialization
  parameter Boolean useHeatInput=true
    "Initialisation of qMetalFluidDelayed=qMetalFluid"                                   annotation(Dialog(enable=delayInnerHeatTransfer,tab="Initialization", group="Heat transfer delay"));
  parameter Boolean initializeWithZeroInnerHeatFlow=false
    "Initialisation of qMetalFluidDelayed=0"                                                       annotation(Dialog(tab="Initialization",group="Heat transfer delay",enable=(useHeatInput==false) and delayInnerHeatTransfer));
  parameter SI.CoefficientOfHeatTransfer alpha_start = 10000
    "Heat transfer coefficient (not too small for valid wall temperature)"                                                        annotation(Dialog(tab="Initialization"));

  // Wall
  parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers" annotation(Dialog(group="Wall"),choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
  parameter String initOptWall="steadyState" "Initialisation option" annotation (Dialog(tab="Initialization",group="Wall"),
  choices(
    choice="noInit" "No initial equations",
    choice="steadyState" "Steady-state initialization",
    choice="fixedTemperature" "Fixed-temperatures initialization"));
  parameter Medium.Temperature TWall_start[numberOfNodes]=T_start+q_start/alpha_start*ones(numberOfNodes)
    "start values for wall temperatures"
                                       annotation (Dialog(tab="Initialization",group="Wall"));
  parameter SiemensPowerOMCtest.Utilities.Structures.PropertiesMetal metal
    "Wall metal properties"                                                      annotation (Dialog(group="Wall"));
  parameter SiemensPowerOMCtest.Utilities.Structures.StressCoefficients
    stressCoeffofWall "Tension parameters"
                         annotation(Dialog(group="Wall"));

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort[numberOfNodes](T(
        start=TWall_start), Q_flow(start=geoPipe.Nt*Q_flow_start))
    "Outer wall heat port"
  annotation (Placement(transformation(extent={{-14,54},{14,78}}, rotation=0),
        iconTransformation(extent={{-14,54},{14,78}})));

 SiemensPowerOMCtest.Components.SolidComponents.WallWithTension wall(
    numberOfNodes=numberOfNodes,
    numberOfWallLayers=numberOfWallLayers,
    metal=metal,
    length =   geoPipe.L,
    wallThickness=geoPipe.s,
    T_start =   TWall_start,
    initOpt=initOptWall,
    numberOfParallelTubes=geoPipe.Nt,
    diameterInner =   geoPipe.d_out - 2*geoPipe.s,
    stress=stressCoeffofWall) "Metal wall of the tube"
                 annotation (Placement(transformation(extent={{-10,34},{10,54}},
          rotation=0)));

  SiemensPowerOMCtest.Interfaces.portHeat heatport(
                               numberOfNodes=numberOfNodes)
    "inner wall (masked) heat port "                                            annotation (Placement(
        transformation(extent={{-10,-8},{10,12}}, rotation=0)));

  SI.CoefficientOfHeatTransfer alpha[numberOfNodes];

protected
  heattransfer HT[numberOfNodes](each geoPipe=geoPipe, m_flow=m_flows, rho=d, p=fluid.p, h=fluid.h, eta=eta, cp=cp, lambda=lambda, each
      steamQuality = 1.5, dT=TWall-fluid.T);
  SI.HeatFlux qMetalFluidDelayed[numberOfNodes]( each start=q_start);
  SI.HeatFlux qMetalFluid[numberOfNodes]( each start=q_start);
  inner Medium.Temperature TWall[numberOfNodes](start=TWall_start);

initial equation

   // qMetalFluidDelayed
   if (useHeatInput and delayInnerHeatTransfer) then
          qMetalFluidDelayed=qMetalFluid;
   elseif (initializeWithZeroInnerHeatFlow) then
        qMetalFluidDelayed=zeros(numberOfNodes);
   end if;

equation
  portIn.p = wall.p_in;

  // metal-fluid heat transfer
  for j in 1:numberOfNodes loop
     alpha[j] = HT[j].alpha;
     qMetalFluid[j] = alpha[j] * (TWall[j]-fluid[j].T);
  end for;
  if (delayInnerHeatTransfer) then
        der(qMetalFluidDelayed) = (qMetalFluid-qMetalFluidDelayed)/timeDelayOfInnerHeatTransfer;
  else
        qMetalFluidDelayed=qMetalFluid;
  end if;
  heatport.Q_flow = heatedArea/numberOfNodes*qMetalFluidDelayed;

  connect(heatPort, wall.port_ext)
                                  annotation (Line(points={{1.77636e-015,66},{
          1.77636e-016,66},{1.77636e-016,48.9}}, color={191,0,0}));
  connect(wall.port_int, heatport.port) annotation (Line(points={{-0.1,39.4},{
          -0.1,32.7},{0,32.7},{0,5.4}}, color={191,0,0}));

  annotation (Documentation(info="<HTML>
<p>This tube model comes with a detailed energy, but integrated momentum and mass balance.
See <a href=\"./Documents/tube_integration.pdf\"> pdf documentation </a>for details of the integration of the hydrodynamic equations.
Both heat transfer and friction pressure drop can be selected from a set of correlations.
 </p>
<h3>Model restrictions</h3>
<ul>
<li>Mass accelaration pressure drop is not considered</li>
<li>dynamic mass balance has no effect if medium is incompressible </li>
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
                           <td> </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>

</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"), Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},
            {100,100}}),
                   graphics),
    Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,100}}),
                    graphics={Rectangle(
          extent={{-90,40},{92,54}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid), Rectangle(
          extent={{-90,-54},{92,-40}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}));
end Tube;
