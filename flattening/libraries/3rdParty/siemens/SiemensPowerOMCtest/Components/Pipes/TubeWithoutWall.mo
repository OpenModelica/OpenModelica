within SiemensPowerOMCtest.Components.Pipes;
model TubeWithoutWall
  "Tube with detailed energy, integrated momentum and mass balance"
  import SI = Modelica.SIunits;
  extends SiemensPowerOMCtest.Utilities.BaseClasses.BaseTube;

  replaceable model Friction =
      SiemensPowerOMCtest.Utilities.PressureLoss.RoughnessFlow constrainedby
    SiemensPowerOMCtest.Utilities.PressureLoss.PartialFrictionSinglePhase
    "Friction pressure loss correlation"   annotation (Dialog(group="Geometry and correlations"),choicesAllMatching=true);
  parameter String locationMassflow="interpolation"
    "location of mass flow rate"
      annotation(choices(choice="inlet" "inlet",
                         choice="outlet" "outlet",
                         choice="interpolation" "interpolation"),evaluate=true);
  parameter Boolean useDelayedPressure=false "Pressure delay" annotation(Dialog(tab="Advanced"),evaluate=true);
  parameter SI.Time timeDelayOfPressure=0.1
    "Artificial delay time for delay of pressure value" annotation(Dialog(tab="Advanced"),enable=useDelayedPressure);

  Medium.AbsolutePressure p(start=hydP*pIn_start + (1-hydP)*pOut_start)
    "pressure";

protected
  final parameter Real hydM=(if (locationMassflow=="inlet") then 1.0 else if (locationMassflow=="outlet") then 0.0 else  0.4)
    "Part of portIn for p";
  final parameter Real hydP=1-hydM "Part of portIn for m_flow";
  Medium.AbsolutePressure pUndelayed(start=hydP*pIn_start + (1-hydP)*pOut_start);
  Friction friction(geoPipe=geoPipe, dz=geoPipe.L, m_flow=m_flows[1], p=p, rho=d_av, h=fluid[1].h, eta=eta[1], steamQuality = 1.5, xdo=0.9);

initial equation
  // m_flow
  if (considerDynamicMomentum and useDynamicMassBalance) then
        der(m_flows[1]) = 0;
  end if;

  // d oder p
 if (useDynamicMassBalance and initializeInletPressure) then
   //der(d_av)=0;
    der(p) = 0;
 end if;

equation
  // lumped pressure and mass flow rate
  if (locationMassflow=="inlet") then
    pUndelayed = portOut.p;
    m_flowsZero = portIn.m_flow/geoPipe.Nt;
  elseif (locationMassflow=="outlet") then
    pUndelayed = portIn.p;
    m_flowsZero = -portOut.m_flow/geoPipe.Nt;
  else
    pUndelayed = hydP*portIn.p + (1-hydP)*portOut.p;
    m_flowsZero = (hydM*portIn.m_flow - (1-hydM)*portOut.m_flow)/geoPipe.Nt;
  end if;
  if useDelayedPressure then
     der(p) = (pUndelayed-p)/timeDelayOfPressure;
  else
     p = pUndelayed;
  end if;
  m_flows = m_flowsZero*ones(numberOfNodes);

  //  pressure loss
  dpfric=friction.dp;
  dphyd=g*geoPipe.H*d_av;

  // mass balance
  if (useDynamicMassBalance) then
      VTotal*der(d_av) =  portIn.m_flow + portOut.m_flow;
  else
      portIn.m_flow + portOut.m_flow = 0;
  end if;

  // momentum balance
  if considerDynamicMomentum then
      geoPipe.L/A*der(m_flows[1]) = portIn.p-portOut.p -(dpfric+dphyd);
  else
      portIn.p-portOut.p  = dpfric+dphyd;
  end if;

 // water/steam properties
  fluid.p = p*ones(numberOfNodes);

  annotation (Documentation(info="<HTML>
<p>This tube model comes with a detailed energy, but integrated momentum and mass balance.
See <a href=\"./Documents/tube_integration.pdf\"> pdf documentation </a>for details of the integration of the hydrodynamic equations.
Both heat transfer and friction pressure drop can be selected from a set of correlations.
 </p>
<h3>Model restrictions</h3>
<ul>
<li>Mass accelaration pressure drop is not considered</li>
<li>The tube comes without wall. It is not possibel to connect external heating</li>
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
</HTML>"));
end TubeWithoutWall;
