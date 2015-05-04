within SiemensPower.Utilities.Structures;
record PipeGeo "Geometry parameters for a tube"
  import SI = Modelica.SIunits;

  parameter Integer Nt=1 "Number of parallel tubes";
  parameter SI.Length L=1 "Length of tube";
  parameter SI.Length H=0 "Height difference between outlet and inlet";
  parameter SI.Length d_out=0.038 "Outer diameter of the tube";
  parameter SI.Length s=0.003 "Thickness of the wall";
  parameter SI.Length r=0.03e-3
    "Inner roughness (friction coefficient) of the wall";
  parameter Real zeta_add=0 "Additive friction loss coefficient (for bendings)";
  parameter Boolean isCylindric=true
    "assume circular (NOT quadratic) inner cross sectional area";
  final parameter SI.Area A = (if isCylindric then 0.25*Modelica.Constants.pi else 1.0)*(d_out-2*s)^2
    "inner cross sectional area";

 annotation (Documentation(info="<HTML>
<p>These parameters are needed to specify the geoemtry of a pipe:
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
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"));
end PipeGeo;
