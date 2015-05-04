within SiemensPower.Utilities.Structures;
record Fins "Geometry parameters for fins"
  import SI = Modelica.SIunits;

  parameter Boolean finned=true "Is finned tube";
  parameter Boolean serrated=true "Is serrated (not solid fins)" annotation(Dialog(enable=finned));
  parameter SI.Length h=0.01 "height of fins" annotation(Dialog(enable=finned));
  parameter SI.Length s=0.001 "width of fins" annotation(Dialog(enable=finned));
  parameter SI.Length b=0.005 "base height " annotation(Dialog(enable=finned and serrated));
  parameter SI.Length w=0.004 "segment width" annotation(Dialog(enable=finned and serrated));
  parameter SI.WaveNumber n=270 "no of fins per meter" annotation(Dialog(enable=finned));
 parameter String material="X 8 CrNiTi 18.10" " fin material"
    annotation(Dialog(enable=finned), choices(
    choice="Standardfunktion DEFAalt" "Standardfunktion DEFAalt",
    choice= "St 35.8" "St 35.8",
    choice= "St 45.8" "St 45.8",
    choice= "15 Mo 3" "15 Mo 3",
    choice= "13 CrMo 4.4" "13 CrMo 4.4",
    choice= "10 CrMo 9.10" "10 CrMo 9.10",
    choice= "X 8 CrNiTi 18.10" "X 8 CrNiTi 18.10",
    choice= "X 10 CrMoVNb 9.1" "X 10 CrMoVNb 9.1",
    choice= "X 20 CrMoV 12.1" "X 20 CrMoV 12.1",
    choice= "AISI 409" "AISI 409",
    choice= "AISI 304" "AISI 304"));

  annotation (Documentation(info="<HTML>
<p>These parameters are needed to specify fin parameters.<p>
</HTML>
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
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
   revisions="<html>
<ul>
<li> June 2007, added by Haiko Steuer
</ul>
</html>"));
end Fins;
