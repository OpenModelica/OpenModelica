within SiemensPowerOMCtest.Components.SolidComponents;
model WallWithTension "Wall aggregate measuring tension"
  import SI = Modelica.SIunits;
  extends SiemensPowerOMCtest.Components.SolidComponents.Wall;

  parameter SiemensPowerOMCtest.Utilities.Structures.StressCoefficients stress
    "Tension parameters"                                                                     annotation(Dialog(group="Material"));
  SI.TemperatureDifference dT;
  SI.Pressure ft;
  SI.Pressure fm;
  Modelica.Blocks.Interfaces.RealInput p_in "inside fluid pressure at inlet"
                    annotation (Placement(transformation(extent={{-130,-20},{
            -90,20}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealOutput tension
    "inside tangential+thermal tension at inlet"
                    annotation (Placement(transformation(extent={{90,-10},{110,
            10}}, rotation=0)));

equation
  if (wallThickness>0) then
    dT = sum(layer[1:numberOfWallLayers].T[1])/numberOfWallLayers - port_int[1].T;
    fm=stress.alpha_m*diameterInner/(2*wallThickness) * p_in;
    ft=stress.alpha_t*stress.beta*stress.E/(1-stress.eta) * dT;
  else
    dT = 0.0;
    fm = 0.0;
    ft = 0.0;
  end if;
  tension=ft+fm;

 annotation (Documentation(info="<HTML>
<p>These wall is the same as <b>wall</b> but includes a measurement of the stress at the inner wall (at tube inlet).
It is computed as sum of the thermal and the tangential (mechanical) stress.
This wall is used in the <b>tube_with_tension</b> component, for which an example is given.
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td> <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
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
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}), graphics),
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}), graphics));
end WallWithTension;
