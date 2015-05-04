within SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer;
partial model PartialHeatTransfer
  "Base class for friction pressure loss correlations"

 parameter SiemensPowerOMCtest.Utilities.Structures.PipeGeo geoPipe annotation(Dialog(tab="Advanced",enable=false));
 final parameter Modelica.SIunits.Length diameterInner = geoPipe.d_out-2*geoPipe.s;

 input Modelica.SIunits.Pressure p;
 input Modelica.SIunits.SpecificEnthalpy h;
 input Modelica.SIunits.Density rho;
 input Modelica.SIunits.DynamicViscosity eta;
 input Modelica.SIunits.SpecificHeatCapacity cp;
 input Modelica.SIunits.ThermalConductivity lambda;
 input Real steamQuality;
 input Modelica.SIunits.MassFlowRate m_flow;
 input Modelica.SIunits.TemperatureDifference dT;

 Modelica.SIunits.CoefficientOfHeatTransfer alpha;
 Real xdo;
 Boolean isSinglePhase;

annotation (Documentation(info="<html>
  Any derived inner heat transfer correlation must define the relations for the following two quantities:
  <ul>
      <li> Heat transfer coefficient  <b>alpha</b>
      <li> location of boiling crisis (dry-out) <b> xdo </b> (for single phase flow, this will bot be used, so just give a dummy value)
  </ul>
</html><HTML>
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
</HTML>"));
end PartialHeatTransfer;
