within SiemensPower.Components.Pipes;
model TubeWithoutWall
  "Tube with detailed energy, integrated momentum and mass balance"
  import SI = Modelica.SIunits;
  extends SiemensPower.Utilities.BaseClasses.BaseTube;

  replaceable model Friction =
      SiemensPower.Utilities.PressureLoss.OverallFlow;  //constrainedby
 //   SiemensPower.Utilities.PressureLoss.PartialFrictionSinglePhase
 //   "Friction pressure loss correlation"   annotation (Dialog(group="Geometry and correlations"),choicesAllMatching=true);

  Medium.AbsolutePressure p(start=hydP*pIn_start + (1-hydP)*pOut_start)
    "pressure";

protected
  final parameter Real hydM= 0.4 "Part of portIn for p";
  final parameter Real hydP=1-hydM "Part of portIn for m_flow";
  Friction friction(geoPipe=geoPipe, dz=geoPipe.L, m_flow=m_flows[1], p=p, rho=d_av, h=fluid[1].h, eta=eta[1], steamQuality = 1.5, xdo=0.9);

initial equation
  // m_flow
    der(m_flows[1]) = 0;

  // d oder p
   //der(d_av)=0;
    der(p) = 0;

equation
  // lumped pressure and mass flow rate

    p = hydP*portIn.p + (1-hydP)*portOut.p;
    m_flowsZero = (hydM*portIn.m_flow - (1-hydM)*portOut.m_flow)/geoPipe.Nt;

   m_flows = m_flowsZero*ones(numberOfNodes);

  //  pressure loss
  dpfric=friction.dp;
  dphyd=g*geoPipe.H*d_av;

  // mass balance
   VTotal*der(d_av) =  portIn.m_flow + portOut.m_flow;

  // momentum balance
     geoPipe.L/A*der(m_flows[1]) = portIn.p-portOut.p -(dpfric+dphyd);

 // water/steam properties
  fluid.p = p*ones(numberOfNodes);

  annotation (Documentation(info="<HTML>
<p>This tube model comes with a detailed energy, but integrated momentum and mass balance.
See <a href=\"../Documents/tube_integration.pdf\"> pdf documentation </a>for details of the integration of the hydrodynamic equations.
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
                           <td>internal </td>
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
</HTML>"));
end TubeWithoutWall;
