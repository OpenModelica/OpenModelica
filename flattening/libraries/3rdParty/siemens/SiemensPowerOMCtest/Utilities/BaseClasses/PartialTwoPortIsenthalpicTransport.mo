within SiemensPowerOMCtest.Utilities.BaseClasses;
partial model PartialTwoPortIsenthalpicTransport
  "Partial element transporting fluid between two ports without storing mass or enthalpy"
  import SI = Modelica.SIunits;
  import CO = Modelica.Constants;
  extends SiemensPowerOMCtest.Utilities.BaseClasses.PartialTwoPortTransport(
      hOut_start=hIn_start, final useEnergyStorage=false);

   // Advanced
   parameter Boolean allowFlowReversal = true "Allow flow reversal" annotation(Dialog(tab = "Advanced"));
   parameter SiemensPowerOMCtest.Utilities.Types.regularizationType regType=
      SiemensPowerOMCtest.Utilities.Types.regularizationType.no
    "kind of regularization of flow reversal"
   annotation(Evaluate=true, Dialog(tab = "Advanced", group="Upstream"));
  parameter Medium.MassFlowRate m_flow_small = m_flow_start/100
    "Small mass flow rate for regularization of zero flow"
    annotation(Dialog(tab = "Advanced", group="Upstream", enable=smoothUpstreamMedium and allowFlowReversal));

  Medium.ThermodynamicState stateUpstream "state for upstream medium";
  Medium.MassFlowRate m_flow(start=m_flow_start)
    "Mass flow rate from portIn to portOut (m_flow > 0 is design flow direction)";

protected
  Medium.AbsolutePressure p;
  Medium.SpecificEnthalpy h;
  Medium.MassFraction Xi[Medium.nXi] "Gas composition";
  Real fromleft; //0 ..1

equation
assert(if (not regType == Types.regularizationType.no) then allowFlowReversal else true,"flow reversal should be allowed in order to use upstream state smoothing.");
  // no mass storage
  m_flow = portIn.m_flow;
  portIn.m_flow + portOut.m_flow = 0;

  // upstream medium
  if (not regType == SiemensPowerOMCtest.Utilities.Types.regularizationType.no) then
     if noEvent(m_flow>m_flow_small) then
       fromleft = 1;
     elseif noEvent(m_flow<-m_flow_small) then
       fromleft = 0;
     else
       if (regType == SiemensPowerOMCtest.Utilities.Types.regularizationType.cos) then
         fromleft = 0.5*(1 - cos(0.5*(m_flow/m_flow_small+1)*CO.pi));
       else
         fromleft = 0.5*(1 - 0.5*m_flow/m_flow_small*((m_flow/m_flow_small)^2-3)); // Modelica.Fluid.Utilities.regStep
       end if;
     end if;
  elseif (allowFlowReversal) then
     if (m_flow>0) then
       fromleft = 1;
     else
       fromleft = 0;
     end if;
  else
    fromleft=1;
  end if;
  p = fromleft*portIn.p+(1-fromleft)*portOut.p;
  h  = fromleft*inStream(portIn.h_outflow) +(1-fromleft)*inStream(portOut.h_outflow);
  Xi = fromleft*inStream(portIn.Xi_outflow)+(1-fromleft)*inStream(portOut.Xi_outflow);
  stateUpstream = Medium.setState_phX(p, h, Xi);

 annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics),
    Documentation(info="<html>
<p>
This component transports fluid between its two ports, without
storing mass or energy.
When using this partial component, an equation for the momentum
balance has to be added by specifying a relationship
between the pressure drop \"portIn.p - portOut.p\" and the
mass flow rate \"m_flow = portIn.m_flow\".
</p>
</html>

<HTML>
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
</html>"));
end PartialTwoPortIsenthalpicTransport;
