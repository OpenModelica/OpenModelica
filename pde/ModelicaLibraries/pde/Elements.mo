package Elements "Geometrical elements" 
  
record Point1D "Point in R1" 
  parameter Coordinate x=0;
    annotation(Documentation(info="<HTML>
<pre>
Contains coordinate of point.
</pre>
</HTML>"));
end Point1D;
  
record Line1D "Line in R1" 
  parameter Coordinate x1=0;
  parameter Coordinate x2=1;
    annotation(Documentation(info="<HTML>
<pre>
Contains coordinates of end-points of line.
</pre>
</HTML>"));
end Line1D;
  
record Polygon1D "Polygon in R1" 
  parameter Coordinate x[:]={0};
    annotation(Documentation(info="<HTML>
<pre>
Contains coordinates of polygon-points.
</pre>
</HTML>"));
end Polygon1D;
  
record Point2D "Point in R2" 
  parameter Coordinate x1[2]={0,0};
    annotation(Documentation(info="<HTML>
<pre>
Contains coordinates of point.
</pre>
</HTML>"));
end Point2D;
  
record Line2D "Line in R2" 
  parameter Coordinate x1[2]={0,0};
  parameter Coordinate x2[2]={1,1};
    annotation(Documentation(info="<HTML>
<pre>
Contains coordinates of end-points of line.
</pre>
</HTML>"));
end Line2D;
  
record Polygon2D "Polygon in R2" 
  parameter Coordinate x[:,2]=[0,0];
    annotation(Documentation(info="<HTML>
<pre>
Contains coordinates of polygon-points.
</pre>
</HTML>"));
end Polygon2D;
  
record Curve2D "Composed boundary curve in R2" 
/* fails when called by function defineBdCurve
  Integer typeCurve[:]={1} "Index of curve type";
  Real auxCurve[:]=fill(1,0) "Auxiliary stuff curve geometry";
  Coordinate x[:,2]=[0,0] "Coordinate of curve-section (begin-point)";
*/
  //explicit for rectangle:
  parameter Integer typeCurve[4]={1,1,1,1} "Index of curve type";
  parameter Real auxCurve[1]=fill(1,1) "Auxiliary stuff curve geometry";
  parameter Coordinate x[4,2]=[0,0;0,0;0,0;0,0] 
      "Coordinate of curve-section (begin-point)";
    annotation(Documentation(info="<HTML>
<pre>
Specifies type of curve sections, contains coordinates of oriented curve sections by start point, 
and specifies additional data of curve sections.
</pre>
</HTML>"));
end Curve2D;
  
function default_bdfct1D "Default boundary function 1D" 
  input Real t;
  input Real a;
  output Real f_bd;
    annotation(Documentation(info="<HTML>
<pre>
Returns a constant value, may be redeclared as a time-dependent function.
</pre>
</HTML>"));
algorithm 
  f_bd := a;
end default_bdfct1D;
  
function default_bdfct2Dx "Default boundary< function" 
  input Real t;
  input Real a;
  input Integer n;
  output Real f_bd[n];
    annotation(Documentation(info="<HTML>
<pre>
Returns a constant value, may be redeclared as a time and/or space-dependent function.
</pre>
</HTML>"));
algorithm 
  f_bd := fill(a, n);
end default_bdfct2Dx;
  
function default_bdfct2Dy "Default boundary< function" 
  input Real t;
  input Real a;
  input Integer n;
  output Real f_bd[n-2];
    annotation(Documentation(info="<HTML>
<pre>
Returns a constant value, may be redeclared as a time and/or space-dependent function.
</pre>
</HTML>"));
algorithm 
  f_bd := fill(a, n-2);
end default_bdfct2Dy;
end Elements;
