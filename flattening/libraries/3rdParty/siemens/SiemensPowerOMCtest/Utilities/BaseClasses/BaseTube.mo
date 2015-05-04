within SiemensPowerOMCtest.Utilities.BaseClasses;
partial model BaseTube "Base class for spatial discretized tubes"
  import SI = Modelica.SIunits;
  extends SiemensPowerOMCtest.Utilities.BaseClasses.PartialTwoPortTransport(pIn_start=pOut_start, XOut_start=XIn_start);
  constant Real g=Modelica.Constants.g_n;
  constant Real pi=Modelica.Constants.pi;

  parameter Integer numberOfNodes(min=2) = 2
    "Number of nodes for thermal variables";
  parameter SiemensPowerOMCtest.Utilities.Structures.PipeGeo geoPipe
    "Geometry of tube" annotation(Dialog(group="Geometry and correlations"));

  // Initialization
  parameter Boolean initializeInletPressure = true
    "add steady state equation for pressure"  annotation(Dialog(tab="Initialization"));
  parameter Boolean initializeSteadyStateEnthalpies=true
    "lets initialize der(h)=0" annotation(evaluate=true, Dialog(tab="Initialization"));
  parameter Boolean initializeSteadyStateInletEnthalpy=true
    "steady state initial condition for input enthalpy" annotation(evaluate=true, Dialog(tab="Initialization", enable=initializeSteadyStateEnthalpies));
  parameter Medium.SpecificEnthalpy h_start[numberOfNodes] = hIn_start*ones(numberOfNodes) + (hOut_start-hIn_start)*linspace(1/numberOfNodes,1,numberOfNodes)
    "guess values for initial enthalpy vector"  annotation(Dialog(tab="Advanced", group="Initialization"));
  parameter SI.HeatFlowRate Q_flow_start[numberOfNodes] = (hOut_start-hIn_start)*m_flow_start/(geoPipe.Nt*numberOfNodes)*ones(numberOfNodes)
    "Detailed start values for heat flow"  annotation(Dialog(tab="Advanced", group="Initialization"));

  // Advanced
  parameter SI.Volume additionalVolume=0
    "Additional volume to total tubes volumes"
                                              annotation(Dialog(tab="Advanced"));
  parameter Boolean useDynamicMassBalance=true "consider mass storage" annotation(Dialog(tab="Advanced", group="Dynamics"),Evaluate=true);
  parameter Boolean considerDynamicMomentum=true
    "der(m_flow) accounted for, be careful!"  annotation(Dialog(tab="Advanced", group="Dynamics"),evaluate=true);
  parameter Boolean considerDynamicPressure=false
    "With der(p)/d in enthalpy balance (for shock waves)"  annotation(Dialog(tab="Advanced", group="Dynamics"),Evaluate=true);
  parameter SI.Area heatedArea=geoPipe.Nt*geoPipe.L*Modelica.Constants.pi*diameterInner
    "Total Area for heat transfer" annotation(Dialog(tab="Advanced", group="Inner heat transfer"));

  final parameter SI.Length diameterInner = geoPipe.d_out - 2*geoPipe.s;
  final parameter SI.Length dz= geoPipe.L/numberOfNodes;
  final parameter SI.Volume V = geoPipe.A*geoPipe.L+additionalVolume/geoPipe.Nt;
  final parameter SI.Area A = geoPipe.A * (1.0+ additionalVolume/(geoPipe.Nt*geoPipe.A*geoPipe.L));
  final parameter SI.Volume VTotal = geoPipe.Nt*V;
  final parameter SI.Volume VCell= V/numberOfNodes annotation(Evaluate=true);
  final parameter Real sinphi = geoPipe.H / geoPipe.L;

  Medium.BaseProperties fluid[numberOfNodes](each preferredMediumStates=preferredStates,
                            p(start=linspace(pIn_start,pOut_start,numberOfNodes)),
                            h(start=h_start),
                            each Xi(start=XIn_start[1:Medium.nXi]));
  Medium.MassFlowRate m_flows[numberOfNodes](each start=m_flow_start/geoPipe.Nt);
  Medium.Density d_av(start=sum(d_start)/numberOfNodes);
  SI.SpecificVolume vol_av(start=1/Medium.density_phX(0.5*(pIn_start+pOut_start), 0.5*(hIn_start+hOut_start),XIn_start));
  SI.Pressure dpfric(start= dpFric_start);
  SI.Pressure dphyd(start=dpHyd_start);

protected
  final parameter SI.Pressure dpHyd_start = g*geoPipe.H*sum(Medium.density_phX(linspace(pIn_start,pOut_start,numberOfNodes),h_start, XIn_start));
  final parameter SI.Pressure dpFric_start = max(0.0, pIn_start-pOut_start-dpHyd_start);
  final parameter Medium.Temperature T_start[numberOfNodes]=Medium.temperature_phX(linspace(pIn_start, pOut_start, numberOfNodes),h_start, XIn_start)
    "start values for fluid temperatures";
  final parameter Medium.Density d_start[numberOfNodes]=Medium.density_phX(linspace(pIn_start, pOut_start, numberOfNodes),h_start,XIn_start);
  final parameter SI.HeatFlux q_start =  m_flow_start*(hOut_start-hIn_start)/heatedArea;
  Medium.MassFlowRate m_flowsZero(start=m_flow_start/geoPipe.Nt);
  Medium.Temperature T[numberOfNodes](start=T_start);
  Medium.Density d[numberOfNodes](start=d_start);
  SI.SpecificVolume vol[numberOfNodes](each start=1/Medium.density_phX(0.5*(pIn_start+pOut_start), 0.5*(hIn_start+hOut_start),XIn_start));
  Medium.SpecificHeatCapacity cp[numberOfNodes];
  Medium.DynamicViscosity eta[numberOfNodes];
  Medium.ThermalConductivity lambda[numberOfNodes];
  SI.HeatFlowRate E_flows[numberOfNodes](start=-Q_flow_start);
  Medium.MassFlowRate M_flows[numberOfNodes,Medium.nXi];
  replaceable SI.HeatFlux qHeating[numberOfNodes](each start=q_start)=zeros(numberOfNodes);

initial equation

  // h
 if (useEnergyStorage) then
  if (initializeSteadyStateInletEnthalpy and initializeSteadyStateEnthalpies) then
        der(fluid[1].h)=0;
  end if;
  if (initializeSteadyStateEnthalpies) then
      for j in 2:numberOfNodes loop
        der(fluid[j].h) = 0;
     end for;
  end if;
  end if;

  if (useSubstanceStorage) then
    for j in 1:(numberOfNodes) loop
     // der(fluid[j].Xi)  = zeros(Medium.nXi);
     fluid[j].Xi = XIn_start[1:Medium.nXi];
    end for;
 end if;

equation
  // thermodynamic properties
  fluid.d = d;
  fluid.T = T;
  for j in 1:numberOfNodes loop
      vol[j]=1.0/fluid[j].d;
  end for;
  d_av=sum(d)/numberOfNodes;
  vol_av=sum(vol)/numberOfNodes;
  eta = Medium.dynamicViscosity(fluid.state);
  cp = Medium.specificHeatCapacityCp(fluid.state);
  lambda = Medium.thermalConductivity(fluid.state);

  // transport flows
  E_flows[1]= max(0,m_flowsZero) *(inStream(portIn.h_outflow)-fluid[1].h)+max(0,-m_flows[1])*(fluid[2].h-fluid[1].h);
  M_flows[1,:]= max(0,m_flowsZero) *(inStream(portIn.Xi_outflow)-fluid[1].Xi)+max(0,-m_flows[1])*(fluid[2].Xi-fluid[1].Xi);
  for j in 2:(numberOfNodes-1) loop
      E_flows[j]=max(0,m_flows[j-1])*(fluid[j-1].h-fluid[j].h)+max(0,-m_flows[j])*(fluid[j+1].h-fluid[j].h);
      M_flows[j,:]=max(0,m_flows[j-1])*(fluid[j-1].Xi-fluid[j].Xi)+max(0,-m_flows[j])*(fluid[j+1].Xi-fluid[j].Xi);
  end for;
  E_flows[numberOfNodes]=max(0,m_flows[numberOfNodes-1])*(fluid[numberOfNodes-1].h-fluid[numberOfNodes].h)+max(0,-m_flows[numberOfNodes])*(inStream(portOut.h_outflow)-fluid[numberOfNodes].h);
  M_flows[numberOfNodes,:]=max(0,m_flows[numberOfNodes-1])*(fluid[numberOfNodes-1].Xi-fluid[numberOfNodes].Xi)+max(0,-m_flows[numberOfNodes])*(inStream(portOut.Xi_outflow)-fluid[numberOfNodes].Xi);

 // energy + substance balance
  if useEnergyStorage then
    portIn.h_outflow = fluid[1].h;
    portOut.h_outflow= fluid[numberOfNodes].h;
  end if;
  if useSubstanceStorage then
    portIn.Xi_outflow = fluid[1].Xi;
    portOut.Xi_outflow= fluid[numberOfNodes].Xi;
  end if;
  for j in 1:numberOfNodes loop
     if useEnergyStorage then
        if considerDynamicPressure then
           VCell*(fluid[j].d*der(fluid[j].h)-der(fluid[j].p)) = E_flows[j] + heatedArea*qHeating[j]/(numberOfNodes*geoPipe.Nt);
        else
           VCell*fluid[j].d*der(fluid[j].h) = E_flows[j] + heatedArea*qHeating[j]/(numberOfNodes*geoPipe.Nt);
        end if;
     else
        fluid[j].h = Modelica.Fluid.Utilities.regStep(m_flowsZero, inStream(portIn.h_outflow), inStream(portOut.h_outflow));
     end if;

     if useSubstanceStorage then
        VCell*fluid[j].d*der(fluid[j].Xi) = M_flows[j,:];
     else
        fluid[j].Xi = Modelica.Fluid.Utilities.regStep(m_flowsZero, inStream(portIn.Xi_outflow), inStream(portOut.Xi_outflow));
     end if;
  end for;

  annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}), graphics={Rectangle(
          extent={{-90,40},{92,-40}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={0,149,255}), Text(
          extent={{-100,-50},{100,-90}},
          lineColor={0,0,0},
          textString="%name")}),
    Documentation(info="<HTML>
<p>This base class describes the geometry and most important variables for the water/steam flow in a pipe.<br>
It will be a 1-dimensional flow model.
In the derived class, the following quantities/equations have to be set:<br>
<ul>
<li> pressure(s)
<li> mass flow rate(s) + momentum balance(s) incl hydrostatic and friction pressure drop
<li> mass densities d[1], ..d[numberOfNodes] for each cell + continuity equation(s)
<li> specific enthalpies h[1], .., h[numberOfNodes] (energy balances)
<li>
</ul>
<p>
</HTML><HTML>
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
</HTML>"),
    Diagram);
end BaseTube;
