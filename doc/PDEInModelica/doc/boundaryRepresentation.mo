package BoundaryRepresentation
  partial function cur
    input Real u;
    output Real x;
    output Real y;
  end cur;
  function arc
    extends cur;
    parameter Real r;
    parameter Real cx;
    parameter Real cy;
  algorithm
    x:=cx + r * cos(u);
    y:=cy + r * sin(u);
  end arc;
  function line
    extends cur;
    parameter Real x1;
    parameter Real y1;
    parameter Real x2;
    parameter Real y2;
  algorithm
    x:=x1 + (x2 - x1) * u;
    y:=y1 + (y2 - y1) * u;
  end line;
  function bezier3
    extends cur;
    //start-point
    parameter Real x1;
    parameter Real y1;
    //end-point
    parameter Real x2;
    parameter Real y2;
    //start-control-point
    parameter Real cx1;
    parameter Real cy1;
    //end-control-point
    parameter Real cx2;
    parameter Real cy2;
  algorithm
    x:=(1 - u) ^ 3 * x1 + 3 * (1 - u) ^ 2 * u * cx1 + 3 * (1 - u) * u ^ 2 * cx2 + u ^ 3 * x2;
    y:=(1 - u) ^ 3 * y1 + 3 * (1 - u) ^ 2 * u * cy1 + 3 * (1 - u) * u ^ 2 * cy2 + u ^ 3 * y2;
  end bezier3;
  record Curve
    function curveFun = line;
    // to be replaced with another fun
    parameter Real uStart;
    parameter Real uEnd;
  end Curve;
  record Boundary
    constant Integer NCurves;
    Curve curves[NCurves];
    //    for i in 1:(NCurves-1) loop
    //assert(Curve[i].curveFun(Curve[i].uEnd) = Curve[i+1].curveFun(Curve[i+1].uStart), String(i)+"th curve and "+String(i+1)+"th curve are not connected.",level = AssertionLevel.error);
    //    end for;
    //    assert(curves[NCurves].curveFun(curves[NCurves].uEnd) =
    //                          curves[1].curveFun(curves[1].uStart),
    //                          String(NCurves)+"th curve and first curve are not connected.",
    //                          level = AssertionLevel.error);
  end Boundary;
  record DomainHalfCircle
    constant Real pi = Modelica.Constants.pi;
    arc myArcFun(cx = 0, cy = 0, r = 1);
    Curve myArc(curveFun = myArcFun, uStart = pi / 2, uEnd = (pi * 3) / 2);
    line myLineFun(x1 = 0, y1 = -1, x2 = 0, y2 = 1);
    Curve myLine(curveFun = myLineFun, uStart = 0, uEnd = 1);
    line myLine2(curveFun = line(x1 = 0, y1 = -1, x2 = 0, y2 = 1), uStart = pi / 2, uEnd = (pi * 3) / 2);
    Boundary b(NCurves = 2, curves = {myArc,myLine});
    //new externaly defined type Domain2D and operator interior:
    Domain2D d = interior Boundary;
  end DomainHalfCircle;
end BoundaryRepresentation;

