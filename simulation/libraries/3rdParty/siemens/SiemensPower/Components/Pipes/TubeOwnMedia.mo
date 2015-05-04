within SiemensPower.Components.Pipes;
model TubeOwnMedia
  "SimpleMedia-Tube (incl wall) with detailed energy , integrated momentum and mass balance"
  import SI = SiemensPower.Units;
  import SiemensPower.Utilities.initOpt;

  extends SiemensPower.Utilities.BaseClasses.PartialTwoPortTransport;
  constant Real g=Modelica.Constants.g_n;
  constant Real pi=Modelica.Constants.pi;
  //constant Medium.AbsolutePressure pcrit=Medium.fluidConstants[1].criticalPressure;
  //constant Medium.Temperature Tcrit=Medium.fluidConstants[1].criticalTemperature;

   parameter Boolean initializeInletPressure=true
    "mp or pp boundary conditions"                                               annotation(evaluate=true);
  parameter Integer numberOfNodes(min=2) = 2
    "Number of nodes for thermal variables"                                          annotation(Dialog(group="Geometry and pressure drop parameters"));
  parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe
    "Geometry of tube"                                                           annotation(Dialog(group="Geometry and pressure drop parameters"));
  parameter SI.MassFlowRate m_flowLaminar=0.001
    "(small) mass flow rate at wich laminar equals turbulent pressure drop" annotation(Dialog(group="Geometry and pressure drop parameters"));
  parameter Boolean considerDynamicMomentum=true
    "der(m_dot) accounted for, be careful!" annotation(evaluate=true);
  parameter Boolean considerMassAccelaration=true
    "Inertial phenomena d/dz(m_dot^2/d) accounted for" annotation(evaluate=true);
  parameter Boolean initializeSteadyStateEnthalpies=true
    "lets initialize der(h)=0"                                                      annotation(evaluate=true, Dialog(tab="Initialization"));
  parameter Boolean initializeSteadyStateInletEnthalpy=true
    "steady state initial condition for input enthalpy" annotation(evaluate=true, Dialog(tab="Initialization", enable=initializeSteadyStateEnthalpies));

  parameter Boolean useINTH2O=false
    "water/steam table: true = useINTH2O, false = TTSE";
  parameter Boolean considerDynamicPressure=false
    "With der(p)/d in enthalpy balance";
  parameter Boolean useDelayedPressure=false "Pressure delay";
  parameter Modelica.SIunits.Time timeDelayOfPressure=0.1
    "Artificial delay time for delay of pressure value" annotation(Dialog(enable=useDelayedPressure));
  parameter Real hydP=0.6 "Part of portIn for p";
  parameter Real hydM=0.4 "Part of portOut for m_flow";

  parameter SI.CoefficientOfHeatTransfer alphaOffset=10e3
    "alpha offset (in case of verysimple=true)"                    annotation(Dialog(tab="Inner heat transfer", enable=verysimple));
  parameter Real alphaFactor=0.0
    "Factor for state dependent alpha term (in case of verysimple=true)"                    annotation(Dialog(tab="Inner heat transfer", enable=verysimple));

  parameter Boolean delayInnerHeatTransfer=false "With delay of qMetalFluid" annotation(Dialog(tab="Inner heat transfer"));
  parameter Modelica.SIunits.Time timeDelayOfInnerHeatTransfer=1
    "artificial delay time for qMetalFluid"             annotation(Dialog(tab="Inner heat transfer",enable=delayInnerHeatTransfer));

  // Init parameters
  parameter Boolean useHeatInput=true
    "Initialisation of qMetalFluidDelayed=qMetalFluid"                                   annotation(Dialog(tab="Initialization", group="Heat transfer"));
  parameter Boolean initializeWithZeroInnerHeatFlow=false
    "Initialisation of qMetalFluidDelayed=0"                                                       annotation(Dialog(tab="Initialization",group="Heat transfer",enable=(useHeatInput==false) and delayInnerHeatTransfer));

  // wall parameters
 parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers" annotation(Dialog(group="Wall"),choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
 parameter initOpt initOptWall = initOpt.steadyState;

  parameter SI.Temperature T_wall_start[numberOfNodes]=T_start
    "start values for wall temperatures"
                                       annotation (Dialog(tab="Initialization",group="Wall"));
 parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
    "Wall metal properties"                                                      annotation (Dialog(group="Wall"));

  final parameter SI.Length di = geoPipe.d_out - 2*geoPipe.s;
  final parameter SI.Area A =  0.25*pi*di^2;
  final parameter SI.Length dz= geoPipe.L/numberOfNodes;
  final parameter SI.Volume V = A*geoPipe.L;
  final parameter SI.Volume V_total = geoPipe.Nt*V;

  SI.Temperature T[numberOfNodes](start=T_start);
  SI.Density d[numberOfNodes](start=rho0);
  SI.Density dAverage(start=sum(rho0)/numberOfNodes);
  SI.SpecificVolume vol[numberOfNodes];
  SI.SpecificVolume volAverage(start=1/SiemensPower.Media.TTSE.Utilities.rho_ph(0.5*(pIn_start+pOut_start),0.5*(hIn_start+hOut_start)));
  SI.SpecificEnthalpy h[numberOfNodes](start=SiemensPower.Utilities.Functions.my_linspace(hIn_start, hOut_start, numberOfNodes));
  SI.AbsolutePressure dpfric(start=0.015*geoPipe.L/(geoPipe.d_out-2*geoPipe.s)^5*m_flow_start/geoPipe.Nt*0.5*(1/rho0[1] + 1/rho0[numberOfNodes]));
  SI.AbsolutePressure dphyd(start=g*geoPipe.H*sum(rho0)/numberOfNodes);
  SI.HeatFlux qMetalFluidDelayed[numberOfNodes];
  SI.Length perimeter;
  SI.MassFlowRate m_flow(start=m_flow_start/geoPipe.Nt);
  SI.AbsolutePressure p(start=0.5*(pIn_start+pOut_start)) "pressure";
  SI.AbsolutePressure pUndelayed(start=0.5*(pIn_start+pOut_start));
  Real zeta "friction coefficient";
  SI.CoefficientOfHeatTransfer alpha;

   Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a gasSide[numberOfNodes](T(start=T_wall_start))
    "Outer wall heat port"
  annotation (extent=[-14,54; 14,78]);

  SiemensPower.Components.SolidComponents.Wall wall(
    numberOfNodes=numberOfNodes,
    numberOfWallLayers=numberOfWallLayers,
    metal=metal,
    length =   geoPipe.L,
    wallThickness=geoPipe.s,
    T_start =   T_wall_start,
    init=initOptWall,
    numberOfParallelTubes=geoPipe.Nt,
    diameterInner =   geoPipe.d_out - 2*geoPipe.s) "Metal wall of the tube"
                 annotation (extent=[-10,34; 10,54]);

  SiemensPower.Interfaces.portHeat heatport(
                               numberOfNodes=numberOfNodes, TWall = TWall)
    "Inner wall (masked) heat port "                                             annotation (extent=[-10,-8; 10,12]);

protected
  parameter SI.AbsolutePressure pFkt[numberOfNodes] = SiemensPower.Utilities.Functions.my_linspace(pIn_start,pOut_start,numberOfNodes);
  parameter SI.SpecificEnthalpy hFkt[numberOfNodes] = SiemensPower.Utilities.Functions.my_linspace(hIn_start,hOut_start,numberOfNodes);
  parameter SI.Density rhoIn = SiemensPower.Media.TTSE.Utilities.rho_ph(pIn_start,hIn_start);
  parameter SI.Density rhoOut = SiemensPower.Media.TTSE.Utilities.rho_ph(pOut_start,hOut_start);

  final parameter SI.Temperature T_start[numberOfNodes]=SiemensPower.Media.TTSE.Utilities.T_ph(pFkt,hFkt)
    "start values for fluid temperatures";
  final parameter SI.Density rho0[numberOfNodes]=SiemensPower.Utilities.Functions.my_linspace(rhoIn, rhoOut,numberOfNodes);

//  final parameter SI.Temperature T_start[numberOfNodes]=SiemensPower.Media.TTSE.Utilities.T_ph(SiemensPower.Utilities.Functions.my_linspace(pIn_start,pOut_start,numberOfNodes),SiemensPower.Utilities.Functions.my_linspace(hIn_start,hOut_start,numberOfNodes))
//    "start values for fluid temperatures";
//  final parameter SI.Density rho0[numberOfNodes]=SiemensPower.Utilities.Functions.my_linspace(SiemensPower.Media.TTSE.Utilities.rho_ph(pIn_start,hIn_start), SiemensPower.Media.TTSE.Utilities.rho_ph(pOut_start,hOut_start), numberOfNodes);

  SI.HeatFlux qMetalFluid[numberOfNodes];
  Real drdp[numberOfNodes];
  Real drdh[numberOfNodes];
  //inner SI.Temperature TWall[numberOfNodes];
  SI.Temperature TWall[numberOfNodes];
  Integer TTSEid(start=0);

algorithm
//    when (initial()) then
//      if not useINTH2O then
//       TTSEid:=SiemensPower.Media.TTSE.init_ttse();
//      else
       TTSEid:=0;
//      end if;
//    end when;

initial equation

   // h
  if (initializeSteadyStateInletEnthalpy and initializeSteadyStateEnthalpies) then
        der(h[1])=0;
  end if;
  if initializeSteadyStateEnthalpies then
      for j in 2:numberOfNodes loop
         der(h[j]) = 0;
     end for;
  end if;

  // m_flow
  if (considerDynamicMomentum) then
        der(m_flow) = 0;
  end if;

   // p (or d)
  if (initializeInletPressure) then
      der(p) = 0;
  end if;

  // qMetalFluidDelayed
  if (useHeatInput and delayInnerHeatTransfer) then
          qMetalFluidDelayed=qMetalFluid;
  elseif (initializeWithZeroInnerHeatFlow) then
        qMetalFluidDelayed=zeros(numberOfNodes);
  end if;

equation

  perimeter=pi*di;
  dAverage=sum(d)/numberOfNodes;
  volAverage=sum(vol)/numberOfNodes;
  for j in 1:numberOfNodes loop
      vol[j]=1.0/d[j];
  end for;

  portIn.h_outflow = h[1];
  portOut.h_outflow = h[numberOfNodes];

  // pressure and mass flow rate
  pUndelayed = hydP*portIn.p + (1-hydP)*portOut.p;
  if useDelayedPressure then
        der(p) = (pUndelayed-p)/timeDelayOfPressure;
  else
        p = pUndelayed;
  end if;
  m_flow = (hydM*portIn.m_flow - (1-hydM)*portOut.m_flow)/geoPipe.Nt;

  // friction pressure loss
 zeta=((1.14-2*Modelica.Math.log10(geoPipe.r/di))^(-2)+geoPipe.zeta_add*di/geoPipe.L);
 dpfric = zeta*m_flow*(abs(m_flow)+m_flowLaminar)*volAverage*geoPipe.L/(2*A^2*di);

  // hydrostatic pressure drop;
  dphyd=g*geoPipe.H*dAverage;

    // mass balance
 // der(dAverage) + (-portOut.m_flow-portIn.m_flow)/(geoPipe.Nt*V) = 0;
    (1/numberOfNodes)*(sum(drdp)*der(p) + drdh*der(h))  + (-portOut.m_flow-portIn.m_flow)/(geoPipe.Nt*V) = 0;

  // momentum balance
  if (considerDynamicMomentum) then
    if (considerMassAccelaration) then
      der(m_flow) + dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L+ m_flow^2*(1/d[numberOfNodes]-1/d[1])/V = 0;
    else
      der(m_flow) + dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L = 0;
    end if;
  else
    if (considerMassAccelaration) then
      dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L+ m_flow^2*(1/d[numberOfNodes]-1/d[1])/V = 0;
    else
      dphyd*A/geoPipe.L + A*(portOut.p-portIn.p)/geoPipe.L  + dpfric*A/geoPipe.L = 0;
    end if;
  end if;
 // energy balance
//   if (m_flow<0) then
    if (considerDynamicPressure) then
      der(h[1]) + (max(0, -m_flow)*(h[2]-h[1])+max(0,m_flow)*(h[1]-inStream(portIn.h_outflow)))/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di) + der(p)/d[1];
    else
      der(h[1]) + (max(0, -m_flow)*(h[2]-h[1])+max(0,m_flow)*(h[1]-inStream(portIn.h_outflow)))/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di);
    end if;
//  else
//    if (considerDynamicPressure) then
//      der(h[1]) + m_flow*(h[1]-inStream(portIn.h_outflow))/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di) + der(p)/d[1];
//    else
//      der(h[1]) + m_flow*(h[1]-inStream(portIn.h_outflow))/(A*d[1]*dz) = 4*qMetalFluidDelayed[1]/(d[1]*di);
//    end if;
//  end if;

for j in 2:(numberOfNodes-1) loop
//    if (m_flow<0) then
    if (considerDynamicPressure) then
      der(h[j]) + max(0,-m_flow)*(h[j+1]-h[j])/(A*d[j]*dz) + max(0,m_flow)*(h[j]-h[j-1])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di) + der(p)/d[j];
    else
      der(h[j]) + max(0,-m_flow)*(h[j+1]-h[j])/(A*d[j]*dz) + max(0,m_flow)*(h[j]-h[j-1])/(A*d[j]*dz)= 4*qMetalFluidDelayed[j]/(d[j]*di);
    end if;
//  else
//    if (considerDynamicPressure) then
//      der(h[j]) + m_flow*(h[j]-h[j-1])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di) + der(p)/d[j];
//    else
//      der(h[j]) + m_flow*(h[j]-h[j-1])/(A*d[j]*dz) = 4*qMetalFluidDelayed[j]/(d[j]*di);
//    end if;
//  end if;
end for;

//  if (m_flow<0) then
    if (considerDynamicPressure) then
      der(h[numberOfNodes]) + max(0,-m_flow)*(inStream(portOut.h_outflow)-h[numberOfNodes])/(A*d[numberOfNodes]*dz) + max(0,m_flow)*(h[numberOfNodes]-h[numberOfNodes-1])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di) + der(p)/d[numberOfNodes];
    else
      der(h[numberOfNodes]) + max(0,-m_flow)*(inStream(portOut.h_outflow)-h[numberOfNodes])/(A*d[numberOfNodes]*dz) + max(0,m_flow)*(h[numberOfNodes]-h[numberOfNodes-1])/(A*d[numberOfNodes]*dz)= 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di);
    end if;
//  else
//    if (considerDynamicPressure) then
//      der(h[numberOfNodes]) + m_flow*(h[numberOfNodes]-h[numberOfNodes-1])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di) + der(p)/d[numberOfNodes];
//    else
//      der(h[numberOfNodes]) + m_flow*(h[numberOfNodes]-h[numberOfNodes-1])/(A*d[numberOfNodes]*dz) = 4*qMetalFluidDelayed[numberOfNodes]/(d[numberOfNodes]*di);
//    end if;
//  end if;

 // water/steam properties
 //p = sum(SiemensPower.Media.IntH2O.p_rhoh(dAverage,h[3]);
 for j in 1:numberOfNodes loop
    if useINTH2O then
       T[j] =  SiemensPower.Media.IntH2O.T_rhoh(d[j],h[j]);
      (d[j],drdp[j],drdh[j]) =  SiemensPower.Media.IntH2O.rho_ph_dpdh(p, h[j]);
    else  // TTSE
        T[j]    = SiemensPower.Media.TTSE.Utilities.T_ph(p, h[j]);
        d[j]  = SiemensPower.Media.TTSE.Utilities.rho_ph(p, h[j]);
        drdp[j] = SiemensPower.Media.TTSE.Utilities.rho_ph_dp(p, h[j]);
        drdh[j] = SiemensPower.Media.TTSE.Utilities.rho_ph_dh(p, h[j]);

    end if;
 end for;

  // Inner heat transfer
  alpha = alphaOffset + 400*Modelica.Fluid.Utilities.regRoot(abs(m_flow)/A)*alphaFactor;
  qMetalFluid = alpha * (TWall-T);
  heatport.Q_flow = perimeter*geoPipe.Nt*dz*qMetalFluidDelayed;
  if (delayInnerHeatTransfer) then
        der(qMetalFluidDelayed) = (qMetalFluid-qMetalFluidDelayed)/timeDelayOfInnerHeatTransfer;
  else
        qMetalFluidDelayed=qMetalFluid;
  end if;

  connect(gasSide, wall.port_ext) annotation (points=[1.77636e-015,66;
        1.77636e-016,66; 1.77636e-016,48.9], style(color=42, rgbcolor={191,0,0}));
  connect(wall.port_int, heatport.port) annotation (points=[-0.1,39.4; -0.1,
        32.7; 0,32.7; 0,5.4], style(color=42, rgbcolor={191,0,0}));

annotation (Documentation(info="<HTML>
<p>This tube model comes with a detailed energy balance, but <b>integrated</b> momentum and mass balance.
See <a href=\"../Documents/tube_integration.pdf\"> pdf documentation </a>for details.<br>
The tube is heated. The water/steam media is simplified: You can chose between:
<ul>
<li> inth20
<li> Ideal steam
</ul>
<p>

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
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>

</HTML>",
      revisions="<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"), Icon(graphics={
        Rectangle(
          extent={{-80,54},{80,-60}},
          fillColor={0,255,255},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Text(
          extent={{-76,30},{78,-26}},
          lineColor={0,0,0},
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid,
          textString="%name"),
        Rectangle(
          extent={{-80,54},{80,40}},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-80,-46},{80,-60}},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          lineColor={0,0,0})}),
    Diagram(graphics));
end TubeOwnMedia;
