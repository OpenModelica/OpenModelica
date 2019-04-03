within SiemensPower.Utilities.BaseClasses;
partial model BaseTube "Base class for spatial discretized tubes"
  import SI = Modelica.SIunits;
  extends SiemensPower.Utilities.BaseClasses.PartialTwoPortTransport(pIn_start=pOut_start, XOut_start=XIn_start);
  constant Real g=Modelica.Constants.g_n;
  constant Real pi=Modelica.Constants.pi;

  parameter Integer numberOfNodes(min=1) = 2
    "Number of nodes for thermal variables";
  parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
    "Geometry of tube" annotation(Dialog(group="Geometry and correlations"));

  // Initialization
  parameter Boolean initializeInletPressure = true
    "add steady state equation for pressure"  annotation(Dialog(tab="Initialization"));
  parameter Boolean initializeSteadyStateEnthalpies=true
    "lets initialize der(h)=0" annotation(evaluate=true, Dialog(tab="Initialization"));
  parameter Boolean initializeSteadyStateInletEnthalpy=true
    "steady state initial condition for input enthalpy" annotation(evaluate=true, Dialog(tab="Initialization", enable=initializeSteadyStateEnthalpies));
  parameter Medium.SpecificEnthalpy h_start[numberOfNodes] = hIn_start*ones(numberOfNodes) + (hOut_start-hIn_start)*equalCellDistribution
    "guess values for initial enthalpy vector"  annotation(Dialog(tab="Advanced", group="Initialization"));
  parameter SI.HeatFlowRate Q_flow_start[numberOfNodes] = (hOut_start-hIn_start)*m_flow_start/(geoPipe.Nt*numberOfNodes)*ones(numberOfNodes)
    "Detailed start values for heat flow"  annotation(Dialog(tab="Advanced", group="Initialization"));

  // Advanced
  parameter SI.Area heatedArea=geoPipe.Nt*geoPipe.L*Modelica.Constants.pi*diameterInner
    "Total Area for heat transfer" annotation(Dialog(tab="Advanced", group="Inner heat transfer"));

  final parameter SI.Length diameterInner = geoPipe.d_out - 2*geoPipe.s;
  final parameter SI.Length dz= geoPipe.L/numberOfNodes;
  final parameter SI.Volume V = geoPipe.A*geoPipe.L;
  final parameter SI.Area A = geoPipe.A;
  final parameter SI.Volume VTotal = geoPipe.Nt*V;
  final parameter SI.Volume VCell= V/numberOfNodes annotation(Evaluate=true);
  final parameter Real sinphi = geoPipe.H / geoPipe.L;

  Medium.BaseProperties fluid[numberOfNodes](each preferredMediumStates=true,
                            p(start=pressureDistribution_start),
                            h(start=h_start),
                            each Xi(start=XIn_start[1:Medium.nXi]));
  Medium.MassFlowRate m_flows[numberOfNodes](each start=m_flow_start/geoPipe.Nt);
  Medium.Density d_av(start=sum(d_start)/numberOfNodes);
  SI.SpecificVolume vol_av(start=1/Medium.density_phX(0.5*(pIn_start+pOut_start), 0.5*(hIn_start+hOut_start),XIn_start));
  SI.Pressure dpfric(start= dpFric_start);
  SI.Pressure dphyd(start=dpHyd_start);

protected
  final parameter Real equalCellDistribution[numberOfNodes] = (if numberOfNodes==1 then ones(numberOfNodes) else linspace(1/numberOfNodes,1,numberOfNodes));
  final parameter SI.Pressure pressureDistribution_start[numberOfNodes] = (if numberOfNodes==1 then pOut_start*ones(numberOfNodes) else linspace(pIn_start, pOut_start, numberOfNodes));
  final parameter SI.Pressure dpHyd_start = g*geoPipe.H*sum(d_start)/numberOfNodes;
  final parameter SI.Pressure dpFric_start = max(0.0, pIn_start-pOut_start-dpHyd_start);
  final parameter Medium.Temperature T_start[numberOfNodes]=Medium.temperature_phX(pressureDistribution_start,h_start, XIn_start)
    "start values for fluid temperatures";
  final parameter Medium.Density d_start[numberOfNodes]=Medium.density_phX(pressureDistribution_start,h_start,XIn_start);
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
  if (initializeSteadyStateInletEnthalpy and initializeSteadyStateEnthalpies) then
        der(fluid[1].h)=0;
  end if;
  if (initializeSteadyStateEnthalpies) then
      for j in 2:numberOfNodes loop
        der(fluid[j].h) = 0;
     end for;
  end if;
  for j in 1:numberOfNodes loop
    fluid[j].Xi = XIn_start[1:Medium.nXi];
  end for;

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
  if (numberOfNodes>1) then
    E_flows[1]= max(0,m_flowsZero) *(inStream(portIn.h_outflow)-fluid[1].h)+max(0,-m_flows[1])*(fluid[2].h-fluid[1].h);
    M_flows[1,:]= max(0,m_flowsZero) *(inStream(portIn.Xi_outflow)-fluid[1].Xi)+max(0,-m_flows[1])*(fluid[2].Xi-fluid[1].Xi);
    for j in 2:(numberOfNodes-1) loop
        E_flows[j]=max(0,m_flows[j-1])*(fluid[j-1].h-fluid[j].h)+max(0,-m_flows[j])*(fluid[j+1].h-fluid[j].h);
        M_flows[j,:]=max(0,m_flows[j-1])*(fluid[j-1].Xi-fluid[j].Xi)+max(0,-m_flows[j])*(fluid[j+1].Xi-fluid[j].Xi);
    end for;
    E_flows[numberOfNodes]=max(0,m_flows[numberOfNodes-1])*(fluid[numberOfNodes-1].h-fluid[numberOfNodes].h)+max(0,-m_flows[numberOfNodes])*(inStream(portOut.h_outflow)-fluid[numberOfNodes].h);
    M_flows[numberOfNodes,:]=max(0,m_flows[numberOfNodes-1])*(fluid[numberOfNodes-1].Xi-fluid[numberOfNodes].Xi)+max(0,-m_flows[numberOfNodes])*(inStream(portOut.Xi_outflow)-fluid[numberOfNodes].Xi);
  else
    E_flows[1]= max(0,m_flowsZero) *(inStream(portIn.h_outflow)-fluid[1].h)+max(0,-m_flows[1])*(inStream(portOut.h_outflow)-fluid[1].h);
    M_flows[1,:]= max(0,m_flowsZero) *(inStream(portIn.Xi_outflow)-fluid[1].Xi)+max(0,-m_flows[1])*(inStream(portOut.Xi_outflow)-fluid[1].Xi);
  end if;
 // energy + substance balance
    portIn.h_outflow = fluid[1].h;
    portOut.h_outflow= fluid[numberOfNodes].h;
    portIn.Xi_outflow = fluid[1].Xi;
    portOut.Xi_outflow= fluid[numberOfNodes].Xi;
  for j in 1:numberOfNodes loop
        VCell*fluid[j].d*der(fluid[j].h) = E_flows[j] + heatedArea*qHeating[j]/(numberOfNodes*geoPipe.Nt);
        VCell*fluid[j].d*der(fluid[j].Xi) = M_flows[j,:];
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
<li> mass densities d[1], ...d[numberOfNodes] for each cell + continuity equation(s)
<li> specific enthalpies h[1], ..., h[numberOfNodes] (energy balances)
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
                           <td>public </td>
                </tr>
           </table>
          <p><b><font style=\"font-size: 10pt; \">License, Copyright and Disclaimer</font></b> </p>
<p>
<blockquote><br/>Licensed by Siemens AG under the Siemens Modelica License 2</blockquote>
<blockquote><br/>Copyright  2007-2012 Siemens AG. All rights reserved.</blockquote>
<blockquote><br/>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Siemens Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"../Documents/SiemensModelicaLicense2.html\">Siemens Modelica License 2 </a>.</blockquote>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram);
end BaseTube;
