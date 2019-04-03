within ThermoSysPro;
package Functions "General purpose functions"
  function ThermoRoot "Thermodynamic root"
    input Real x;
    input Real dx;
    output Real y;
  protected
    Real C3;
    Real C1;
    Real dx2;
    Real adx;
    Real sqrtdx;
  algorithm
    adx:=abs(dx);
    if x > adx then
      y:=sqrt(x);
    else
      if x < -adx then
        y:=-sqrt(-x);
      else
        dx2:=adx*adx;
        sqrtdx:=sqrt(adx);
        C3:=-0.25/(sqrtdx*dx2);
        C1:=0.5/sqrtdx - 3.0*C3*dx2;
        y:=(C1 + C3*x*x)*x;
      end if;
    end if;
    annotation(smoothOrder=1, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  end ThermoRoot;

  function ThermoSquare "Thermodynamic square"
    input Real x;
    input Real dx;
    output Real y;
  algorithm
    y:=if abs(x) > dx then x*abs(x) else x*dx;
    annotation(smoothOrder=1, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end ThermoSquare;

  function Interpolation "Interpolation"
    input Real u "Input";
    input Real X[:] "X vector";
    input Real Y[:] "Y vector";
    output Real y "Output";
  protected
    Integer i;
    Integer n;
    Real u1;
    Real u2;
    Real y1;
    Real y2;
  algorithm
    n:=size(X, 1);
    if u <= X[1] then
      y:=Y[1];
      i:=1;
    else
      if u >= X[n] then
        y:=Y[n];
        i:=n;
      else
        i:=2;
        while (i < n and u >= X[i]) loop
          i:=i + 1;
        end while;
        i:=i - 1;
        u1:=X[i];
        u2:=X[i + 1];
        y1:=Y[i];
        y2:=Y[i + 1];
        y:=y1 + (y2 - y1)*(u - u1)/(u2 - u1);
      end if;
    end if;
    annotation(smoothOrder=1, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end Interpolation;

  function LinearInterpolation "Linear interpolation"
    input Real TabX[:] "References table";
    input Real TabY[:] "Results table";
    input Real X "Reference value";
    output Real Y "Interpolated result";
    output Real DeltaYX "Y step wrt. X";
  protected
    Integer dimX=size(TabX, 1) "TabX dimension";
    Integer dimY=size(TabY, 1) "TabY dimension";
    Integer IndX=0 "Reference index";
    Boolean IndXcal "Computed index";
    Real ValNum;
    Real ValDen;
    Real DeltaYX2 "Step in Y w.r.t. X";
  algorithm
    if dimX <> dimY then
      assert(false, "LinearInterpolation: the dimensions of the tables are different");
    end if;
    IndXcal:=false;
    for i in 2:dimX - 1 loop
      if X <= TabX[i] and not IndXcal then
        IndX:=i;
        IndXcal:=true;
      end if;
    end for;
    if not IndXcal then
      IndX:=dimX;
    end if;
    ValNum:=integer(1000*TabY[IndX] + 0.5)/1000 - integer(1000*TabY[IndX - 1] + 0.5)/1000;
    ValDen:=integer(1000*TabX[IndX] + 0.5)/1000 - integer(1000*TabX[IndX - 1] + 0.5)/1000;
    DeltaYX:=ValNum/ValDen;
    DeltaYX2:=(TabY[IndX] - TabY[IndX - 1])/(TabX[IndX] - TabX[IndX - 1]);
    Y:=TabY[IndX - 1] + (X - TabX[IndX - 1])*DeltaYX;
    annotation(smoothorder=1, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
" "<html>
<h3><font color=\"#008000\" size=5>LinInt</font></h3>
<p>
Interpolation lin&eacute aire
</p>
<h3><font color=\"#008000\">Syntaxe</font></h3>
<pre>(Y,DeltaYX) = <b>LinInt</b>(TabX,TabY,X);</pre>
<h3><font color=\"#008000\">Description</font></h3>
<P>Effectue une interpolation lin&eacute aire pour calculer un coefficient
</P>
</html>", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  end LinearInterpolation;

  function TableLinearInterpolation "Table linear interpolation"
    input Real TabP[:] "1st reference table";
    input Real TabX[:] "2nd reference table";
    input Real TabY[:,:] "Results table";
    input Real P "1st reference value";
    input Real X "2nd reference value";
    output Real Y "Interpolated result";
    output Real DeltaYX "Y step wrt. X";
    output Real DeltaYP "Y step wrt. P";
  protected
    Integer dimP=size(TabP, 1) "TabP dimension";
    Integer dimX=size(TabX, 1) "TabX dimension";
    Integer dimY1=size(TabY, 1) "TabY 1st dimension";
    Integer dimY2=size(TabY, 2) "TabY 2nd dimension";
    Integer IndP=0 "Reference index";
    Boolean IndPcal "Computed index";
    Real Y1;
    Real DeltaYX1;
    Real Y2;
    Real DeltaYX2;
  algorithm
    if dimX <> dimY2 or dimP <> dimY1 then
      assert(false, "TableLinearInterpolation: the dimensions of the tables are different");
    end if;
    IndPcal:=false;
    for i in 2:dimP - 1 loop
      if P <= TabP[i] and not IndPcal then
        IndP:=i;
        IndPcal:=true;
      end if;
    end for;
    if not IndPcal then
      IndP:=dimP;
    end if;
    (Y1,DeltaYX1):=LinearInterpolation(TabX, TabY[IndP - 1,:], X);
    (Y2,DeltaYX2):=LinearInterpolation(TabX, TabY[IndP,:], X);
    DeltaYP:=(Y2 - Y1)/(TabP[IndP] - TabP[IndP - 1]);
    DeltaYX:=DeltaYX1 + (P - TabP[IndP - 1])*(DeltaYX2 - DeltaYX1)/(TabP[IndP] - TabP[IndP - 1]);
    Y:=Y1 + (P - TabP[IndP - 1])*DeltaYP;
    annotation(smoothOrder=2, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  end TableLinearInterpolation;

  annotation(Icon(coordinateSystem(extent={{0,0},{442,394}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Library", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
</html>"));
  function SmoothStep "Smooth step function"
    input Real x;
    input Real alpha=100;
    output Real y;
  algorithm
    y:=1/(1 + exp(-alpha*x/2));
    annotation(smoothorder=2, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2011</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.1</b></p>
</HTML>
"));
  end SmoothStep;

  function SmoothSign "Smooth sign function"
    input Real x;
    input Real alpha=100;
    output Real y;
  algorithm
    y:=SmoothStep(x, alpha) - SmoothStep(-x, alpha);
    annotation(smoothorder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2011</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.1</b></p>
</HTML>
"));
  end SmoothSign;

  function SmoothAbs "Smooth abs function"
    input Real x;
    input Real alpha=100;
    output Real y;
  algorithm
    y:=SmoothSign(x, alpha)*x;
    annotation(smoothorder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2011</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.1</b></p>
</HTML>
"));
  end SmoothAbs;

end Functions;
