within SiemensPower.Utilities.Structures;
record FgzGeo "Geometry parameters for a flue gas zone"
  import SI = Modelica.SIunits;

  parameter SI.Length pt=0.1 "Transverse pitch between tubes";
  parameter SI.Length pl=0.1 "Longitudal pitch between tubes";
  parameter SI.Length Lw=10 "Width of flue gas zone";
  parameter SI.Length Ld=15 "Depth of flue gas zone > tube's length ";
  parameter SI.Length Lh=5 "Height of flue gas zone";
  parameter Integer Nr=1 "Number of tube layers in bundle";
  parameter Boolean staggered=true
    "Staggered tube arrangement instead of inline";

  annotation (Documentation(info="<HTML>
<p>These parameters are needed to specify the geoemtry of a flue gas zone.<p>
The figure shows the meaning of the parameters for a vertical and a horizontal boiler: <br>
<img src=\"../Documents/fluegaszone.gif\"  alt=\"Bild\">
<p>
Note that for a fired boiler, the pl parameter is not in use.
</p>
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
<li> January 2007, added by Haiko Steuer
</ul>
</html>"));
end FgzGeo;
