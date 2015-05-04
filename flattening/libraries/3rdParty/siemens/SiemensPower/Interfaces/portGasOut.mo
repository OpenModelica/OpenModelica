within SiemensPower.Interfaces;
connector portGasOut "Gas connector with outlined icon"
  extends SiemensPower.Interfaces.FluidPort;
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Ellipse(
          extent={{-100,100},{100,-100}},
          lineColor={0,191,0},
          fillColor={0,191,0},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{-80,80},{80,-80}},
          lineColor={0,191,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(extent={{-88,192},{112,98}}, textString="%name")}),
                                                         Icon(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
          Ellipse(
          extent={{-100,100},{100,-100}},
          lineColor={0,191,0},
          fillColor={0,191,0},
          fillPattern=FillPattern.Solid), Ellipse(
          extent={{-80,80},{80,-80}},
          lineColor={0,191,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid)}),
                            Documentation(
info="<html>This connector differs from the Modelica.Fluid standard connector only in the annotation</html><HTML>
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
<li> December 2006, added to SiemensPower by Haiko Steuer
<li>original from SiemensLib</li>
</ul>
</html>"));

end portGasOut;
