package Modelica "Modelica Standard Library (Version 3.2)"
extends Modelica.Icons.Package;

  package Media "Library of media property models"
  extends Modelica.Icons.Package;
  import SI = Modelica.SIunits;

  package Common
    "data structures and fundamental functions for fluid properties"
    extends Modelica.Icons.Package;

    type DerPressureByDensity = Real (final quantity="DerPressureByDensity",
          final unit="Pa.m3/kg");

    type DerPressureByTemperature = Real (final quantity=
            "DerPressureByTemperature", final unit="Pa/K");

    record GibbsDerivs
    "derivatives of dimensionless Gibbs-function w.r.t. dimensionless pressure and temperature"

      extends Modelica.Icons.Record;
      SI.Pressure p "pressure";
      SI.Temperature T "temperature";
      SI.SpecificHeatCapacity R "specific heat capacity";
      Real pi(unit="1") "dimensionless pressure";
      Real tau(unit="1") "dimensionless temperature";
      Real g(unit="1") "dimensionless Gibbs-function";
      Real gpi(unit="1") "derivative of g w.r.t. pi";
      Real gpipi(unit="1") "2nd derivative of g w.r.t. pi";
      Real gtau(unit="1") "derivative of g w.r.t. tau";
      Real gtautau(unit="1") "2nd derivative of g w.r.t. tau";
      Real gtaupi(unit="1") "mixed derivative of g w.r.t. pi and tau";
    end GibbsDerivs;

    record HelmholtzDerivs
    "derivatives of dimensionless Helmholtz-function w.r.t. dimensionless pressuredensity and temperature"
      extends Modelica.Icons.Record;
      SI.Density d "density";
      SI.Temperature T "temperature";
      SI.SpecificHeatCapacity R "specific heat capacity";
      Real delta(unit="1") "dimensionless density";
      Real tau(unit="1") "dimensionless temperature";
      Real f(unit="1") "dimensionless Helmholtz-function";
      Real fdelta(unit="1") "derivative of f w.r.t. delta";
      Real fdeltadelta(unit="1") "2nd derivative of f w.r.t. delta";
      Real ftau(unit="1") "derivative of f w.r.t. tau";
      Real ftautau(unit="1") "2nd derivative of f w.r.t. tau";
      Real fdeltatau(unit="1") "mixed derivative of f w.r.t. delta and tau";
    end HelmholtzDerivs;

    record NewtonDerivatives_ph
    "derivatives for fast inverse calculations of Helmholtz functions: p & h"

      extends Modelica.Icons.Record;
      SI.Pressure p "pressure";
      SI.SpecificEnthalpy h "specific enthalpy";
      DerPressureByDensity pd "derivative of pressure w.r.t. density";
      DerPressureByTemperature pt "derivative of pressure w.r.t. temperature";
      Real hd "derivative of specific enthalpy w.r.t. density";
      Real ht "derivative of specific enthalpy w.r.t. temperature";
    end NewtonDerivatives_ph;

    record NewtonDerivatives_pT
    "derivatives for fast inverse calculations of Helmholtz functions:p & T"

      extends Modelica.Icons.Record;
      SI.Pressure p "pressure";
      DerPressureByDensity pd "derivative of pressure w.r.t. density";
    end NewtonDerivatives_pT;

    function Helmholtz_ph
    "function to calculate analytic derivatives for computing d and t given p and h"
      extends Modelica.Icons.Function;
      input HelmholtzDerivs f "dimensionless derivatives of Helmholtz function";
      output NewtonDerivatives_ph nderivs
      "derivatives for Newton iteration to calculate d and t from p and h";
  protected
      SI.SpecificHeatCapacity cv "isochoric heat capacity";
    algorithm
      cv := -f.R*(f.tau*f.tau*f.ftautau);
      nderivs.p := f.d*f.R*f.T*f.delta*f.fdelta;
      nderivs.h := f.R*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
      nderivs.pd := f.R*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      nderivs.pt := f.R*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
      nderivs.ht := cv + nderivs.pt/f.d;
      nderivs.hd := (nderivs.pd - f.T*nderivs.pt/f.d)/f.d;
    end Helmholtz_ph;

    function Helmholtz_pT
    "function to calculate analytic derivatives for computing d and t given p and t"

      extends Modelica.Icons.Function;
      input HelmholtzDerivs f "dimensionless derivatives of Helmholtz function";
      output NewtonDerivatives_pT nderivs
      "derivatives for Newton iteration to compute d and t from p and t";
    algorithm
      nderivs.p := f.d*f.R*f.T*f.delta*f.fdelta;
      nderivs.pd := f.R*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
    end Helmholtz_pT;
    annotation (Documentation(info="<HTML><h4>Package description</h4>
      <p>Package Modelica.Media.Common provides records and functions shared by many of the property sub-packages.
      High accuracy fluid property models share a lot of common structure, even if the actual models are different.
      Common data structures and computations shared by these property models are collected in this library.
   </p>

</HTML>
",   revisions="<html>
      <ul>
      <li>First implemented: <i>July, 2000</i>
      by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
      for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
      </li>
      <li>Code reorganization, enhanced documentation, additional functions: <i>December, 2002</i>
      by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a> and move to Modelica
                            properties library.</li>
      <li>Inclusion into Modelica.Media: September 2003 </li>
      </ul>

      <address>Author: Hubertus Tummescheit, <br>
      Lund University<br>
      Department of Automatic Control<br>
      Box 118, 22100 Lund, Sweden<br>
      email: hubertus@control.lth.se
      </address>
</html>"));
  end Common;
  annotation (
    Documentation(info="<HTML>
<p>
This library contains <a href=\"modelica://Modelica.Media.Interfaces\">interface</a>
definitions for media and the following <b>property</b> models for
single and multiple substance fluids with one and multiple phases:
</p>
<ul>
<li> <a href=\"modelica://Modelica.Media.IdealGases\">Ideal gases:</a><br>
     1241 high precision gas models based on the
     NASA Glenn coefficients, plus ideal gas mixture models based
     on the same data.</li>
<li> <a href=\"modelica://Modelica.Media.Water\">Water models:</a><br>
     ConstantPropertyLiquidWater, WaterIF97 (high precision
     water model according to the IAPWS/IF97 standard)</li>
<li> <a href=\"modelica://Modelica.Media.Air\">Air models:</a><br>
     SimpleAir, DryAirNasa, and MoistAir</li>
<li> <a href=\"modelica://Modelica.Media.Incompressible\">
     Incompressible media:</a><br>
     TableBased incompressible fluid models (properties are defined by tables rho(T),
     HeatCapacity_cp(T), etc.)</li>
<li> <a href=\"modelica://Modelica.Media.CompressibleLiquids\">
     Compressible liquids:</a><br>
     Simple liquid models with linear compressibility</li>
</ul>
<p>
The following parts are useful, when newly starting with this library:
<ul>
<li> <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.</li>
<li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage\">Modelica.Media.UsersGuide.MediumUsage</a>
     describes how to use a medium model in a component model.</li>
<li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumDefinition\">
     Modelica.Media.UsersGuide.MediumDefinition</a>
     describes how a new fluid medium model has to be implemented.</li>
<li> <a href=\"modelica://Modelica.Media.UsersGuide.ReleaseNotes\">Modelica.Media.UsersGuide.ReleaseNotes</a>
     summarizes the changes of the library releases.</li>
<li> <a href=\"modelica://Modelica.Media.Examples\">Modelica.Media.Examples</a>
     contains examples that demonstrate the usage of this library.</li>
</ul>
<p>
Copyright &copy; 1998-2010, Modelica Association.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\"> http://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</HTML>"));
  end Media;

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Package;

  function sin "Sine"
    extends baseIcon1;
    input Modelica.SIunits.Angle u;
    output Real y;

  external "builtin" y=  sin(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},
                {-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},
                {-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},
                {29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{
                57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color={0,0,0}),
          Text(
            extent={{12,84},{84,36}},
            lineColor={192,192,192},
            textString="sin")}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-100,0},{84,0}}, color={95,95,95}),
          Polygon(
            points={{100,0},{84,6},{84,-6},{100,0}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{
                -43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{
                -14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{
                29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,
                -61.9},{63.9,-47.2},{72,-24.8},{80,0}},
            color={0,0,255},
            thickness=0.5),
          Text(
            extent={{-105,72},{-85,88}},
            textString="1",
            lineColor={0,0,255}),
          Text(
            extent={{70,25},{90,5}},
            textString="2*pi",
            lineColor={0,0,255}),
          Text(
            extent={{-103,-72},{-83,-88}},
            textString="-1",
            lineColor={0,0,255}),
          Text(
            extent={{82,-6},{102,-26}},
            lineColor={95,95,95},
            textString="u"),
          Line(
            points={{-80,80},{-28,80}},
            color={175,175,175},
            smooth=Smooth.None),
          Line(
            points={{-80,-80},{50,-80}},
            color={175,175,175},
            smooth=Smooth.None)}),
      Documentation(info="<html>
<p>
This function returns y = sin(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/sin.png\">
</p>
</html>"),   Library="ModelicaExternalC");
  end sin;

  function asin "Inverse sine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;

  external "builtin" y=  asin(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,
                -49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,
                52.7},{75.2,62.2},{77.6,67.5},{80,80}}, color={0,0,0}),
          Text(
            extent={{-88,78},{-16,30}},
            lineColor={192,192,192},
            textString="asin")}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Text(
            extent={{-40,-72},{-15,-88}},
            textString="-pi/2",
            lineColor={0,0,255}),
          Text(
            extent={{-38,88},{-13,72}},
            textString=" pi/2",
            lineColor={0,0,255}),
          Text(
            extent={{68,-9},{88,-29}},
            textString="+1",
            lineColor={0,0,255}),
          Text(
            extent={{-90,21},{-70,1}},
            textString="-1",
            lineColor={0,0,255}),
          Line(points={{-100,0},{84,0}}, color={95,95,95}),
          Polygon(
            points={{98,0},{82,6},{82,-6},{98,0}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},
                {-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{
                75.2,62.2},{77.6,67.5},{80,80}},
            color={0,0,255},
            thickness=0.5),
          Text(
            extent={{82,24},{102,4}},
            lineColor={95,95,95},
            textString="u"),
          Line(
            points={{0,80},{86,80}},
            color={175,175,175},
            smooth=Smooth.None),
          Line(
            points={{80,86},{80,-10}},
            color={175,175,175},
            smooth=Smooth.None)}),
      Documentation(info="<html>
<p>
This function returns y = asin(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
</p>
</html>"),   Library="ModelicaExternalC");
  end asin;

  function acos "Inverse cosine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;

  external "builtin" y=  acos(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-90,-80},{68,-80}}, color={192,192,192}),
          Polygon(
            points={{90,-80},{68,-72},{68,-88},{90,-80}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,80},{-79.2,72.8},{-77.6,67.5},{-73.6,59.4},{-66.3,
                49.8},{-53.5,37.3},{-30.2,19.7},{37.4,-24.8},{57.5,-40.8},{68.7,-52.7},
                {75.2,-62.2},{77.6,-67.5},{80,-80}}, color={0,0,0}),
          Text(
            extent={{-86,-14},{-14,-62}},
            lineColor={192,192,192},
            textString="acos")}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-100,-80},{84,-80}}, color={95,95,95}),
          Polygon(
            points={{98,-80},{82,-74},{82,-86},{98,-80}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-80,80},{-79.2,72.8},{-77.6,67.5},{-73.6,59.4},{-66.3,49.8},
                {-53.5,37.3},{-30.2,19.7},{37.4,-24.8},{57.5,-40.8},{68.7,-52.7},
                {75.2,-62.2},{77.6,-67.5},{80,-80}},
            color={0,0,255},
            thickness=0.5),
          Text(
            extent={{-30,88},{-5,72}},
            textString=" pi",
            lineColor={0,0,255}),
          Text(
            extent={{-94,-57},{-74,-77}},
            textString="-1",
            lineColor={0,0,255}),
          Text(
            extent={{60,-81},{80,-101}},
            textString="+1",
            lineColor={0,0,255}),
          Text(
            extent={{82,-56},{102,-76}},
            lineColor={95,95,95},
            textString="u"),
          Line(
            points={{-2,80},{84,80}},
            color={175,175,175},
            smooth=Smooth.None),
          Line(
            points={{80,82},{80,-86}},
            color={175,175,175},
            smooth=Smooth.None)}),
      Documentation(info="<html>
<p>
This function returns y = acos(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/acos.png\">
</p>
</html>"),   Library="ModelicaExternalC");
  end acos;

  function log "Natural (base e) logarithm (u shall be > 0)"
    extends baseIcon1;
    input Real u;
    output Real y;

  external "builtin" y=  log(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},
                {-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},
                {-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}},
              color={0,0,0}),
          Text(
            extent={{-6,-24},{66,-72}},
            lineColor={192,192,192},
            textString="log")}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={
          Line(points={{-100,0},{84,0}}, color={95,95,95}),
          Polygon(
            points={{100,0},{84,6},{84,-6},{100,0}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-78,-80},{-77.2,-50.6},{-76.4,-37},{-75.6,-28},{-74.8,-21.3},
                {-73.2,-11.4},{-70.8,-1.31},{-67.5,8.08},{-62.7,17.9},{-55.5,28},
                {-45,38.1},{-29.8,48.1},{-8.1,58},{24.1,68},{70.7,78.1},{82,80}},
            color={0,0,255},
            thickness=0.5),
          Text(
            extent={{-105,72},{-85,88}},
            textString="3",
            lineColor={0,0,255}),
          Text(
            extent={{60,-3},{80,-23}},
            textString="20",
            lineColor={0,0,255}),
          Text(
            extent={{-78,-7},{-58,-27}},
            textString="1",
            lineColor={0,0,255}),
          Text(
            extent={{84,26},{104,6}},
            lineColor={95,95,95},
            textString="u"),
          Text(
            extent={{-100,9},{-80,-11}},
            textString="0",
            lineColor={0,0,255}),
          Line(
            points={{-80,80},{84,80}},
            color={175,175,175},
            smooth=Smooth.None),
          Line(
            points={{82,82},{82,-6}},
            color={175,175,175},
            smooth=Smooth.None)}),
      Documentation(info="<html>
<p>
This function returns y = log(10) (the natural logarithm of u),
with u &gt; 0:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/log.png\">
</p>
</html>"),   Library="ModelicaExternalC");
  end log;

  partial function baseIcon1
    "Basic icon for mathematical function with y-axis on left side"

    annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
              -100},{100,100}}), graphics={
          Rectangle(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-80,68}}, color={192,192,192}),
          Polygon(
            points={{-80,90},{-88,68},{-72,68},{-80,90}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-150,150},{150,110}},
            textString="%name",
            lineColor={0,0,255})}),                          Diagram(
          coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Line(points={{-80,80},{-88,80}}, color={95,95,95}),
          Line(points={{-80,-80},{-88,-80}}, color={95,95,95}),
          Line(points={{-80,-90},{-80,84}}, color={95,95,95}),
          Text(
            extent={{-75,104},{-55,84}},
            lineColor={95,95,95},
            textString="y"),
          Polygon(
            points={{-80,98},{-86,82},{-74,82},{-80,98}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid)}),
      Documentation(info="<html>
<p>
Icon for a mathematical function, consisting of an y-axis on the left side.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
  end baseIcon1;

  partial function baseIcon2
    "Basic icon for mathematical function with y-axis in middle"

    annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
              -100},{100,100}}), graphics={
          Rectangle(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Line(points={{0,-80},{0,68}}, color={192,192,192}),
          Polygon(
            points={{0,90},{-8,68},{8,68},{0,90}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-150,150},{150,110}},
            textString="%name",
            lineColor={0,0,255})}),                          Diagram(graphics={
          Line(points={{0,80},{-8,80}}, color={95,95,95}),
          Line(points={{0,-80},{-8,-80}}, color={95,95,95}),
          Line(points={{0,-90},{0,84}}, color={95,95,95}),
          Text(
            extent={{5,104},{25,84}},
            lineColor={95,95,95},
            textString="y"),
          Polygon(
            points={{0,98},{-6,82},{6,82},{0,98}},
            lineColor={95,95,95},
            fillColor={95,95,95},
            fillPattern=FillPattern.Solid)}),
      Documentation(info="<html>
<p>
Icon for a mathematical function, consisting of an y-axis in the middle.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
  end baseIcon2;
  annotation (
    Invisible=true,
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
        graphics={Text(
          extent={{-59,-9},{42,-56}},
          lineColor={0,0,0},
          textString="f(x)")}),
    Documentation(info="<HTML>
<p>
This package contains <b>basic mathematical functions</b> (such as sin(..)),
as well as functions operating on
<a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
<a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
<a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
<a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
</p>

<dl>
<dt><b>Main Authors:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
    Marcus Baur<br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Institut f&uuml;r Robotik und Mechatronik<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>

<p>
Copyright &copy; 1998-2010, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\"> http://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</HTML>
",   revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Function tempInterpol2 added.</li>
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Icons for icon and diagram level introduced.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

</html>"));
  end Math;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;

    final constant Real pi=2*Modelica.Math.asin(1.0);

    final constant Real eps=1.e-15 "Biggest number such that 1.0 + eps = 1.0";

    final constant Real inf=1.e+60
    "Biggest Real number such that inf and -inf are representable on the machine";

    final constant SI.Acceleration g_n=9.80665
    "Standard acceleration of gravity on earth";
    annotation (
      Documentation(info="<html>
<p>
This package provides often needed constants from mathematics, machine
dependent constants and constants from nature. The latter constants
(name, value, description) are from the following source:
</p>

<dl>
<dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
<dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
    Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
    Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
\"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
</dl>

<p>CODATA is the Committee on Data for Science and Technology.</p>

<dl>
<dt><b>Main Author:</b></dt>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 11 16<br>
    D-82230 We&szlig;ling<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
</dl>

<p>
Copyright &copy; 1998-2010, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\"> http://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</html>
",   revisions="<html>
<ul>
<li><i>Nov 8, 2004</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Constants updated according to 2002 CODATA values.</li>
<li><i>Dec 9, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants updated according to 1998 CODATA values. Using names, values
       and description text from this source. Included magnetic and
       electric constant.</li>
<li><i>Sep 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants eps, inf, small introduced.</li>
<li><i>Nov 15, 1997</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"),
      Invisible=true,
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Line(
            points={{-34,-38},{12,-38}},
            color={0,0,0},
            thickness=0.5),
          Line(
            points={{-20,-38},{-24,-48},{-28,-56},{-34,-64}},
            color={0,0,0},
            thickness=0.5),
          Line(
            points={{-2,-38},{2,-46},{8,-56},{14,-64}},
            color={0,0,0},
            thickness=0.5)}),
      Diagram(graphics={
          Rectangle(
            extent={{200,162},{380,312}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{200,312},{220,332},{400,332},{380,312},{200,312}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{400,332},{400,182},{380,162},{380,312},{400,332}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{210,302},{370,272}},
            lineColor={160,160,164},
            textString="Library"),
          Line(
            points={{266,224},{312,224}},
            color={0,0,0},
            thickness=1),
          Line(
            points={{280,224},{276,214},{272,206},{266,198}},
            color={0,0,0},
            thickness=1),
          Line(
            points={{298,224},{302,216},{308,206},{314,198}},
            color={0,0,0},
            thickness=1),
          Text(
            extent={{152,412},{458,334}},
            lineColor={255,0,0},
            textString="Modelica.Constants")}));
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package Package "Icon for standard packages"

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Rectangle(
              extent={{-80,100},{100,-80}},
              lineColor={0,0,0},
              fillColor={215,230,240},
              fillPattern=FillPattern.Solid), Rectangle(
              extent={{-100,80},{80,-100}},
              lineColor={0,0,0},
              fillColor={240,240,240},
              fillPattern=FillPattern.Solid)}),
                                Documentation(info="<html>
<p>Standard package icon.</p>
</html>"));
    end Package;

    partial function Function "Icon for functions"

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Text(extent={{-140,162},{136,102}}, textString=
                                                   "%name"),
            Ellipse(
              extent={{-100,100},{100,-100}},
              lineColor={255,127,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-100,100},{100,-100}},
              lineColor={255,127,0},
              textString=
                   "f")}),Documentation(Error, info="<html>
<p>This icon indicates Modelica functions.</p>
</html>"));
    end Function;

    partial record Record "Icon for records"

      annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                -100},{100,100}}), graphics={
            Rectangle(
              extent={{-100,50},{100,-100}},
              fillColor={255,255,127},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Text(
              extent={{-127,115},{127,55}},
              textString="%name",
              lineColor={0,0,255}),
            Line(points={{-100,-50},{100,-50}}, color={0,0,0}),
            Line(points={{-100,0},{100,0}}, color={0,0,0}),
            Line(points={{0,50},{0,-100}}, color={0,0,0})}),
                                                          Documentation(info="<html>
<p>
This icon is indicates a record.
</p>
</html>"));
    end Record;

    partial package Library
    "This icon will be removed in future Modelica versions, use Package instead"

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Rectangle(
              extent={{-80,100},{100,-80}},
              lineColor={0,0,0},
              fillColor={215,230,240},
              fillPattern=FillPattern.Solid), Rectangle(
              extent={{-100,80},{80,-100}},
              lineColor={0,0,0},
              fillColor={240,240,240},
              fillPattern=FillPattern.Solid)}),
                                Documentation(info="<html>
<p>This icon of a package will be removed in future versions of the library.</p>
<h5>Note</h5>
<p>This icon will be removed in future versions of the Modelica Standard Library. Instead the icon <a href=\"modelica://Modelica.Icons.Package\">Package</a> shall be used.</p>
</html>"));
    end Library;
    annotation(Documentation(__Dymola_DocumentationClass=true, info="<html>
<p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>
<dl>
<dt><b>Main Authors:</b> </dt>
    <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dd><dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd><dd>Oberpfaffenhofen</dd><dd>Postfach 1116</dd><dd>D-82230 Wessling</dd><dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd><br>
    <dd>Christian Kral</dd><dd><a href=\"http://www.ait.ac.at/\">Austrian Institute of Technology, AIT</a></dd><dd>Mobility Department</dd><dd>Giefinggasse 2</dd><dd>1210 Vienna, Austria</dd><dd>email: <a href=\"mailto:christian.kral@ait.ac.at\">christian.kral@ait.ac.at</a></dd><br>
    <dd align=\"justify\">Johan Andreasson</dd><dd align=\"justify\"><a href=\"http://www.modelon.se/\">Modelon AB</a></dd><dd align=\"justify\">Ideon Science Park</dd><dd align=\"justify\">22370 Lund, Sweden</dd><dd align=\"justify\">email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
</dl>
<p>Copyright &copy; 1998-2010, Modelica Association, DLR, AIT, and Modelon AB. </p>
<p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
</html>"));
  end Icons;

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        annotation (Documentation(info="<HTML>
<p>
This package provides predefined types, such as <b>Angle_deg</b> (angle in
degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
which are in common use but are not part of the international standard on
units according to ISO 31-1992 \"General principles concerning quantities,
units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
the use of their multiples and of certain other units\".</p>
<p>If possible, the types in this package should not be used. Use instead
types of package Modelica.SIunits. For more information on units, see also
the book of Francois Cardarelli <b>Scientific Unit Conversion - A
Practical Guide to Metrication</b> (Springer 1997).</p>
<p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
definitions have been placed erroneously in Modelica.SIunits although they
are not SIunits. For backward compatibility, these type definitions are
still kept in Modelica.SIunits.</p>
</HTML>
"),   Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                  100}}), graphics={Text(
                extent={{-66,-13},{52,-67}},
                lineColor={0,0,0},
                textString="[km/h]")}));
      end NonSIunits;
      annotation (Icon(coordinateSystem(preserveAspectRatio=true,
                       extent={{-100,-100},{100,100}}), graphics),
                                Documentation(info="<HTML>
<p>This package provides conversion functions from the non SI Units
defined in package Modelica.SIunits.Conversions.NonSIunits to the
corresponding SI Units defined in package Modelica.SIunits and vice
versa. It is recommended to use these functions in the following
way (note, that all functions have one Real input and one Real output
argument):</p>
<pre>
  <b>import</b> SI = Modelica.SIunits;
  <b>import</b> Modelica.SIunits.Conversions.*;
     ...
  <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
  <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
  <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                      // to radian per seconds
</pre>

</HTML>
"));
    end Conversions;

    type Angle = Real (
        final quantity="Angle",
        final unit="rad",
        displayUnit="deg");

    type Length = Real (final quantity="Length", final unit="m");

    type Position = Length;

    type Volume = Real (final quantity="Volume", final unit="m3");

    type Acceleration = Real (final quantity="Acceleration", final unit="m/s2");

    type Density = Real (
        final quantity="Density",
        final unit="kg/m3",
        displayUnit="g/cm3",
        min=0);

    type SpecificVolume = Real (
        final quantity="SpecificVolume",
        final unit="m3/kg",
        min=0);

    type Pressure = Real (
        final quantity="Pressure",
        final unit="Pa",
        displayUnit="bar");

    type AbsolutePressure = Pressure (min=0);

    type Power = Real (final quantity="Power", final unit="W");

    type MassFlowRate = Real (quantity="MassFlowRate", final unit="kg/s");

    type ThermodynamicTemperature = Real (
        final quantity="ThermodynamicTemperature",
        final unit="K",
        min = 0,
        start = 288.15,
        displayUnit="degC")
    "Absolute temperature (use type TemperatureDifference for relative temperatures)"
                                                                                                        annotation(__Dymola_absoluteValue=true);

    type Temp_K = ThermodynamicTemperature;

    type Temperature = ThermodynamicTemperature;

    type SpecificHeatCapacity = Real (final quantity="SpecificHeatCapacity",
          final unit="J/(kg.K)");

    type SpecificEntropy = Real (final quantity="SpecificEntropy", final unit=
            "J/(kg.K)");

    type SpecificEnergy = Real (final quantity="SpecificEnergy", final unit=
            "J/kg");

    type SpecificEnthalpy = SpecificEnergy;

    type DerDensityByEnthalpy = Real (final unit="kg.s2/m5");

    type DerDensityByPressure = Real (final unit="s2/m2");

    type DerDensityByTemperature = Real (final unit="kg/(m3.K)");

    type DerEnergyByPressure = Real (final unit="J.m.s2/kg");

    type MolarMass = Real (final quantity="MolarMass", final unit="kg/mol",min=0);
    annotation (
      Invisible=true,
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={Text(
            extent={{-63,-13},{45,-67}},
            lineColor={0,0,0},
            textString="[kg.m2]")}),
      Documentation(info="<html>
<p>This package provides predefined types, such as <i>Mass</i>,
<i>Angle</i>, <i>Time</i>, based on the international standard
on units, e.g.,
</p>

<pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                     <b>final</b> unit     = \"rad\",
                     displayUnit    = \"deg\");
</pre>

<p>
as well as conversion functions from non SI-units to SI-units
and vice versa in subpackage
<a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
</p>

<p>
For an introduction how units are used in the Modelica standard library
with package SIunits, have a look at:
<a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
</p>

<p>
Copyright &copy; 1998-2010, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\"> http://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</html>",   revisions="<html>
<ul>
<li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
<li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
<li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
<li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
<li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
<li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
<li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
<li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
<li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
<li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
</ul>
</html>"),
      Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Rectangle(
            extent={{169,86},{349,236}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{169,236},{189,256},{369,256},{349,236},{169,236}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{369,256},{369,106},{349,86},{349,236},{369,256}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{179,226},{339,196}},
            lineColor={160,160,164},
            textString="Library"),
          Text(
            extent={{206,173},{314,119}},
            lineColor={0,0,0},
            textString="[kg.m2]"),
          Text(
            extent={{163,320},{406,264}},
            lineColor={255,0,0},
            textString="Modelica.SIunits")}));
  end SIunits;
annotation (
preferredView="info",
version="3.2",
versionBuild=7,
versionDate="2010-10-25",
dateModified = "2010-11-08 14:38:50Z",
revisionId="$Id:: package.mo 4362 2010-11-08 14:40:58Z #$",
uses(Complex(version="1.0"), ModelicaServices(version="1.1")),
conversion(
 noneFromVersion="3.1",
 noneFromVersion="3.0.1",
 noneFromVersion="3.0",
 from(version="2.1", script="modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2", script="modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2.1", script="modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2.2", script="modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")),
__Dymola_classOrder={"UsersGuide","Blocks","StateGraph","Electrical","Magnetic","Mechanics","Fluid","Media","Thermal",
      "Math","Utilities","Constants", "Icons", "SIunits"},
Settings(NewStateSelection=true),
Documentation(info="<HTML>
<p>
Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica&reg; language from the
Modelica Association, see
<a href=\"http://www.Modelica.org\">http://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li> <b>1280</b> models and blocks, and</li>
<li> <b>910</b> functions
</ul>
<p>
that are directly usable (= number of public, non-partial classes).
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2010, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.Haumer, Modelon,
TU Hamburg-Harburg, Politecnico di Milano.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\"> http://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</HTML>
"));
end Modelica;

package ThermoSysPro

  package Functions "General purpose functions"

    function ThermoSquare "Thermodynamic square"
      input Real x;
      input Real dx;
      output Real y;
    algorithm
      y:=if abs(x) > dx then x*abs(x) else x*dx;
      annotation(smoothOrder=1,                                                                      Icon(
            coordinateSystem(
            preserveAspectRatio=false,
            extent={{-100,-100},{100,100}},
            grid={2,2}), graphics),                                                                        Window(x=0.11, y=0.2, width=0.6, height=0.6), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end ThermoSquare;
    annotation (                                                              Icon(
          coordinateSystem(
          preserveAspectRatio=false,
          extent={{0,0},{442,394}},
          grid={2,2}), graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            textString =                                                                                                    "Library"),
          Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
          Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
          Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
          Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
          Text(
            extent={{-120,135},{120,70}},
            lineColor={255,0,0},
            textString =                                                                                                    "%name")}),                Window(x=0.05, y=0.26, width=0.25, height=0.25, library=1, autolayout=1), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
</html>"));
  end Functions;

  package InstrumentationAndControl "Instrumentation and control library"

    package Connectors "Connectors"

      connector InputReal
        input Real signal;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics),                                                            Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Polygon(
                points={{-100,100},{-100,-100},{100,0},{-100,100}},
                lineColor={0,0,255},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid)}),                                                                                                    Window(x=0.34, y=0.2, width=0.6, height=0.6), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
      end InputReal;

      connector OutputReal
        output Real signal;
        annotation (                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Polygon(
                points={{-100,100},{-100,-100},{100,0},{-100,100}},
                lineColor={0,0,255},
                fillColor={0,255,255},
                fillPattern=FillPattern.Solid)}),                                                                                                    Window(x=0.34, y=0.18, width=0.6, height=0.6), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
      end OutputReal;
      annotation (                                                              Window(x=0.05, y=0.26, width=0.25, height=0.25, library=1, autolayout=1), Icon(
            coordinateSystem(
            preserveAspectRatio=false,
            extent={{0,0},{311,211}},
            grid={2,2}), graphics={
            Rectangle(
              extent={{-100,-100},{80,50}},
              lineColor={0,0,255},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
              lineColor={0,0,255},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
              lineColor={0,0,255},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-120,135},{120,70}},
              lineColor={255,0,0},
              textString=                                                                                                    "%name"),
            Text(
              extent={{-90,40},{70,10}},
              lineColor={160,160,164},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid,
              textString=                                                                                                    "Library"),
            Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
            Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
            Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
            Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
            Polygon(
              points={{16,-71},{29,-67},{29,-74},{16,-71}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Polygon(
              points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid)}),                                                                                                    Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
    end Connectors;
    annotation (                                                              Window(x=0.05, y=0.01, width=0.25, height=0.25, library=1, autolayout=1), Icon(
        coordinateSystem(
        preserveAspectRatio=false,
        extent={{0,0},{312,210}},
        grid={2,2}), graphics={
        Rectangle(
          extent={{-100,-100},{80,50}},
          lineColor={0,0,255},
          fillColor={235,235,235},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
          lineColor={0,0,255},
          fillColor={235,235,235},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
          lineColor={0,0,255},
          fillColor={235,235,235},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-120,135},{120,70}},
          lineColor={255,0,0},
          textString =                                                                                                    "%name"),
        Text(
          extent={{-90,40},{70,10}},
          lineColor={160,160,164},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          textString =                                                                                                    "Library"),
        Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
        Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
        Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
        Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
        Polygon(
          points={{16,-71},{29,-67},{29,-74},{16,-71}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}),                                                                                                    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
</html>"));
  end InstrumentationAndControl;

  package Properties "Fluids properties library"

    package C3H3F5 "C3H3F5 properties library"

      function C3H3F5_Ph
      "11133-C3H3F5 physical properties as a function of P and h"
        input ThermoSysPro.Units.AbsolutePressure P "Pressure";
        input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
    protected
        ThermoSysPro.Units.AbsoluteTemperature Tsat "Saturation temperature";
        ThermoSysPro.Units.AbsolutePressure Psc "Critical pressure";
        ThermoSysPro.Units.AbsolutePressure Pcalc
        "Variable for the computation of the pressure";
        ThermoSysPro.Units.SpecificEnthalpy hcalc
        "Variable for the computation of the specific  enthalpy";
        ThermoSysPro.Units.SpecificEnthalpy hsatL "Boiling specific enthalpy";
        ThermoSysPro.Units.SpecificEnthalpy hsatV
        "Condensation specific enthalpy";
        Modelica.SIunits.SpecificEntropy ssatL "Boiling specific entropy";
        Modelica.SIunits.SpecificEntropy ssatV "Condensation specific entropy";
        Modelica.SIunits.Density rhoSatL "Boiling density";
        Modelica.SIunits.Density rhoSatV "Condensation density";
        Real A1;
        Real B1;
        Real C1;
        Real A2;
        Real B2;
        Real C2;
        Real D2;
        Real A3;
        Real B3;
        Real C3;
      algorithm
        Psc:=3640000;
        if P > Psc then
          Pcalc:=Psc/100000;
        elseif P <= 0 then
          Pcalc:=1/100000;
        else
          Pcalc:=P/100000;
        end if;
        if h > 640000 then
          hcalc:=640;
        elseif h < 100000 then
          hcalc:=100;
        else
          hcalc:=h/1000;
        end if;
        hsatV:=-2.74e-06*Pcalc^6 + 0.00032217*Pcalc^5 - 0.01489673*Pcalc^4 + 0.3425803*Pcalc^3 - 4.15381744*Pcalc^2 + 27.64876596*Pcalc + 385.22149853;
        hsatL:=-3.9275e-06*Pcalc^6 + 0.000478004*Pcalc^5 - 0.0227439765*Pcalc^4 + 0.5370471515*Pcalc^3 - 6.6496487588*Pcalc^2 + 46.8685173786*Pcalc + 166.7823742593;
        ssatV:=1000*(1.7e-09*Pcalc^6 - 2.159e-07*Pcalc^5 + 1.0223e-05*Pcalc^4 - 0.0002295813*Pcalc^3 + 0.0023692545*Pcalc^2 - 0.0062966866*Pcalc + 1.7667560947);
        ssatL:=1000*(-1.64e-08*Pcalc^6 + 1.9814e-06*Pcalc^5 - 9.34768e-05*Pcalc^4 + 0.002182751*Pcalc^3 - 0.0265228817*Pcalc^2 + 0.1740890297*Pcalc + 0.8685336198);
        rhoSatL:=5.7803e-06*Pcalc^6 - 0.0007528646*Pcalc^5 + 0.03773738*Pcalc^4 - 0.9314090824*Pcalc^3 + 11.9184348938*Pcalc^2 - 89.9582798898*Pcalc + 1467.5902188299;
        rhoSatV:=2.07e-06*Pcalc^6 - 0.00019163*Pcalc^5 + 0.00675913*Pcalc^4 - 0.10924667*Pcalc^3 + 0.84661954*Pcalc^2 + 2.83415571*Pcalc + 2.12959146;
        Tsat:=-3.3655e-06*Pcalc^6 + 0.0004044854*Pcalc^5 - 0.0190328128*Pcalc^4 + 0.4443722095*Pcalc^3 - 5.4337547883*Pcalc^2 + 36.7572359309*Pcalc + 246.4280421048;
        if hcalc >= hsatL and hcalc <= hsatV then
          pro.T:=Tsat;
          pro.x:=(hcalc - hsatL)/(hsatV - hsatL);
          pro.d:=rhoSatL*(1 - pro.x) + rhoSatV*pro.x;
          pro.s:=ssatL*(1 - pro.x) + ssatV*pro.x;
        elseif hcalc < hsatL then
          pro.T:=-0.0005311*hcalc^2 + 0.9990391*hcalc + 93.9602333;
          if pro.T > Tsat then
            pro.T:=Tsat;
          end if;
          pro.x:=0;
          pro.d:=-1.54e-05*hcalc^3 + 0.0095634*hcalc^2 - 3.8184877*hcalc + 1916.6958695;
          if pro.d < rhoSatL then
            pro.d:=rhoSatL;
          end if;
          pro.s:=1000*(-3.7e-06*hcalc^2 + 0.00516*hcalc + 0.1002293);
          if pro.s > ssatL then
            pro.s:=ssatL;
          end if;
        else
          A1:=6.98e-05*Pcalc - 0.0008618;
          B1:=-0.0858201*Pcalc + 1.8849272;
          C1:=27.0570743*Pcalc - 353.7594967;
          pro.T:=A1*hcalc^2 + B1*hcalc + C1;
          if pro.T < Tsat then
            pro.T:=Tsat;
          end if;
          pro.x:=1;
          A2:=-9.58e-08*Pcalc^2 + 6.742e-07*Pcalc - 2.691e-07;
          B2:=0.0001689*Pcalc^2 - 0.0011644*Pcalc + 0.000469;
          C2:=-0.0995131*Pcalc^2 + 0.6639841*Pcalc - 0.2724718;
          D2:=19.6224804*Pcalc^2 - 121.4944333*Pcalc + 52.8361115;
          pro.d:=A2*hcalc^3 + B2*hcalc^2 + C2*hcalc + D2;
          if pro.d > rhoSatV then
            pro.d:=rhoSatV;
          end if;
          A3:=-3.2e-09*Pcalc^2 + 1.779e-07*Pcalc - 3.7134e-06;
          B3:=3.4e-06*Pcalc^2 - 0.0001957*Pcalc + 0.0064718;
          C3:=-0.0001958*Pcalc^2 + 0.0194928*Pcalc - 0.1696592;
          pro.s:=1000*(A3*hcalc^2 + B3*hcalc + C3);
          if pro.s < ssatV then
            pro.s:=ssatV;
          end if;
        end if;
        annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
      end C3H3F5_Ph;
      annotation(Icon(graphics={
          Rectangle(
            extent={{-90,-90},{90,60}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-90,60},{-70,80},{110,80},{90,60},{-90,60}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{110,80},{110,-70},{90,-90},{90,60},{110,80}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-100,135},{140,70}},
            lineColor={255,0,0},
            textString=                                                                                                    "%name"),
          Text(
            extent={{-80,50},{80,20}},
            lineColor={160,160,164},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            textString=                                                                                                    "Library"),
          Rectangle(extent={{-22,4},{26,-25}}, lineColor={0,0,0}),
          Rectangle(extent={{-22,-46},{26,-75}}, lineColor={0,0,0}),
          Line(points={{26,-10},{59,-10},{59,-61},{26,-61}}, color={0,0,0}),
          Line(points={{-22,-62},{-54,-62},{-54,-11},{-22,-11}}, color={0,0,0})}));
    end C3H3F5;

    package Fluid "Generic fluid properties library"

      function Ph
        input ThermoSysPro.Units.AbsolutePressure P "Pressure";
        input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
        input Integer mode=0 "IF97 region - 0:automatic computation";
        input Integer fluid=1 "Fluid number - 1: IF97 - 2: C3H3F5";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation (Placement(
              transformation(extent={{-80,40},{-40,80}}, rotation=0)));
      algorithm
        if fluid == 1 then
          pro:=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
        elseif fluid == 2 then
          pro:=C3H3F5.C3H3F5_Ph(P, h);
        else
          assert(false, "Prop.Ph : incorrect fluid number");
        end if;
        annotation(smoothOrder=2,                                                                      Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Text(extent={{-134,104},{142,44}}, textString=                                                                                      "%name"),
              Ellipse(
                extent={{-100,40},{100,-100}},
                lineColor={255,127,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-84,-4},{84,-52}},
                lineColor={255,127,0},
                textString=                                                                                                    "fonction")}),                 Window(x=0.06, y=0.1, width=0.75, height=0.73), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
      end Ph;
      annotation (                                                              Icon(
          coordinateSystem(
          preserveAspectRatio=false,
          extent={{0,0},{312,210}},
          grid={2,2}), graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-110,125},{130,60}},
            lineColor={255,0,0},
            textString=                                                                                                    "%name"),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            textString=                                                                                                    "Library"),
          Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
          Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
          Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
          Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0})}),                                                                                                    Window(x=0.05, y=0.26, width=0.25, height=0.25, library=1, autolayout=1), Documentation(info="<html>
<p><b>Version 1.2</b></p>
</HTML>
"));
    end Fluid;

    package WaterSteam "Water/steam properties library"

      replaceable package IF97 =
        ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ;

      package BaseIF97
      "Modelica Physical Property Model: the new industrial formulation IAPWS-IF97"
        extends Modelica.Icons.Library;
        import SI = Modelica.SIunits;

        record IterationData
        "constants for iterations internal to some functions"
          extends Modelica.Icons.Record;
          constant Integer IMAX=50
          "maximum number of iterations for inverse functions";
          constant Real DELP=1e-06 "maximum iteration error in pressure, Pa";
          constant Real DELS=1e-08
          "maximum iteration error in specific entropy, J/{kg.K}";
          constant Real DELH=1e-08
          "maximum iteration error in specific entthalpy, J/kg";
          constant Real DELD=1e-08 "maximum iteration error in density, kg/m^3";
        end IterationData;

        record data "constant IF97 data and region limits"
          extends Modelica.Icons.Record;
          constant Modelica.SIunits.SpecificHeatCapacity RH2O=461.526
          "specific gas constant of water vapour";
          constant Modelica.SIunits.MolarMass MH2O=0.01801528
          "molar weight of water";
          constant Modelica.SIunits.Temperature TSTAR1=1386.0
          "normalization temperature for region 1 IF97";
          constant Modelica.SIunits.Pressure PSTAR1=16530000.0
          "normalization pressure for region 1 IF97";
          constant Modelica.SIunits.Temperature TSTAR2=540.0
          "normalization temperature for region 2 IF97";
          constant Modelica.SIunits.Pressure PSTAR2=1000000.0
          "normalization pressure for region 2 IF97";
          constant Modelica.SIunits.Temperature TSTAR5=1000.0
          "normalization temperature for region 5 IF97";
          constant Modelica.SIunits.Pressure PSTAR5=1000000.0
          "normalization pressure for region 5 IF97";
          constant Modelica.SIunits.SpecificEnthalpy HSTAR1=2500000.0
          "normalization specific enthalpy for region 1 IF97";
          constant Real IPSTAR=1e-06
          "normalization pressure for inverse function in region 2 IF97";
          constant Real IHSTAR=5e-07
          "normalization specific enthalpy for inverse function in region 2 IF97";
          constant Modelica.SIunits.Temperature TLIMIT1=623.15
          "temperature limit between regions 1 and 3";
          constant Modelica.SIunits.Temperature TLIMIT2=1073.15
          "temperature limit between regions 2 and 5";
          constant Modelica.SIunits.Temperature TLIMIT5=2273.15
          "upper temperature limit of 5";
          constant Modelica.SIunits.Pressure PLIMIT1=100000000.0
          "upper pressure limit for regions 1, 2 and 3";
          constant Modelica.SIunits.Pressure PLIMIT4A=16529200.0
          "pressure limit between regions 1 and 2, important for for two-phase (region 4)";
          constant Modelica.SIunits.Pressure PLIMIT5=10000000.0
          "upper limit of valid pressure in region 5";
          constant Modelica.SIunits.Pressure PCRIT=22064000.0
          "the critical pressure";
          constant Modelica.SIunits.Temperature TCRIT=647.096
          "the critical temperature";
          constant Modelica.SIunits.Density DCRIT=322.0 "the critical density";
          constant Modelica.SIunits.SpecificEntropy SCRIT=4412.02148223476
          "the calculated specific entropy at the critical point";
          constant Modelica.SIunits.SpecificEnthalpy HCRIT=2087546.84511715
          "the calculated specific enthalpy at the critical point";
          constant Real[5] n=array(348.05185628969, -1.1671859879975, 0.0010192970039326, 572.54459862746, 13.91883977887)
          "polynomial coefficients for boundary between regions 2 and 3";
          annotation(Documentation(info="<HTML>
 <h4>Record description</h4>
                           <p>Constants needed in the international steam properties IF97.
                           SCRIT and HCRIT are calculated from Helmholtz function for region 3.</p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <i>July, 2000</i>
       by Hubertus Tummescheit
       </li>
</ul>
 <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</HTML>
"));
        end data;

        record triple "triple point data"
          extends Modelica.Icons.Record;
          constant Modelica.SIunits.Temperature Ttriple=273.16
          "the triple point temperature";
          constant Modelica.SIunits.Pressure ptriple=611.657
          "the triple point temperature";
          constant Modelica.SIunits.Density dltriple=999.792520031618
          "the triple point liquid density";
          constant Modelica.SIunits.Density dvtriple=0.00485457572477861
          "the triple point vapour density";
          annotation(Documentation(info="<HTML>
 <h4>Record description</h4>
 <p>Vapour/liquid/ice triple point data for IF97 steam properties.</p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <i>July, 2000</i>
       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
       </li>
</ul>
 <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</HTML>
"));
        end triple;

        package Regions
        "functions to find the current region for given pairs of input variables"
          extends Modelica.Icons.Library;

          function boundary23ofT
          "boundary function for region boundary between regions 2 and 3 (input temperature)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature t "temperature (K)";
            output Modelica.SIunits.Pressure p "pressure";
        protected
            constant Real[5] n=data.n;
          algorithm
            p:=1000000.0*(n[1] + t*(n[2] + t*n[3]));
          end boundary23ofT;

          function boundary23ofp
          "boundary function for region boundary between regions 2 and 3 (input pressure)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.Temperature t "temperature (K)";
        protected
            constant Real[5] n=data.n;
            Real pi "dimensionless pressure";
          algorithm
            pi:=p/1000000.0;
            assert(p > triple.ptriple, "IF97 medium function boundary23ofp called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            t:=n[4] + ((pi - n[5])/n[3])^0.5;
          end boundary23ofp;

          function hlowerofp5
          "explicit lower specific enthalpy limit of region 5 as function of pressure"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real pi "dimensionless pressure";
          algorithm
            pi:=p/data.PSTAR5;
            assert(p > triple.ptriple, "IF97 medium function hlowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            h:=461526.0*(9.01505286876203 + pi*(-0.00979043490246092 + (-2.03245575263501e-05 + 3.36540214679088e-07*pi)*pi));
          end hlowerofp5;

          function hupperofp5
          "explicit upper specific enthalpy limit of region 5 as function of pressure"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real pi "dimensionless pressure";
          algorithm
            pi:=p/data.PSTAR5;
            assert(p > triple.ptriple, "IF97 medium function hupperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            h:=461526.0*(15.9838891400332 + pi*(-0.000489898813722568 + (-5.01510211858761e-08 + 7.5006972718273e-08*pi)*pi));
          end hupperofp5;

          function hlowerofp1
          "explicit lower specific enthalpy limit of region 1 as function of pressure"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real pi1 "dimensionless pressure";
            Real[3] o "vector of auxiliary variables";
          algorithm
            pi1:=7.1 - p/data.PSTAR1;
            assert(p > triple.ptriple, "IF97 medium function hlowerofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            o[1]:=pi1*pi1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            h:=639675.036*(0.173379420894777 + pi1*(-0.022914084306349 + pi1*(-0.00017146768241932 + pi1*(-4.18695814670391e-06 + pi1*(-2.41630417490008e-07 + pi1*(1.73545618580828e-11 + o[1]*pi1*(8.43755552264362e-14 + o[2]*o[3]*pi1*(5.35429206228374e-35 + o[1]*(-8.12140581014818e-38 + o[1]*o[2]*(-1.43870236842915e-44 + pi1*(1.73894459122923e-45 + (-7.06381628462585e-47 + 9.64504638626269e-49*pi1)*pi1)))))))))));
          end hlowerofp1;

          function hupperofp1
          "explicit upper specific enthalpy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real pi1 "dimensionless pressure";
            Real[3] o "vector of auxiliary variables";
          algorithm
            pi1:=7.1 - p/data.PSTAR1;
            assert(p > triple.ptriple, "IF97 medium function hupperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            o[1]:=pi1*pi1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            h:=639675.036*(2.42896927729349 + pi1*(-0.00141131225285294 + pi1*(0.00143759406818289 + pi1*(0.000125338925082983 + pi1*(1.23617764767172e-05 + pi1*(3.17834967400818e-06 + o[1]*pi1*(1.46754947271665e-08 + o[2]*o[3]*pi1*(1.86779322717506e-17 + o[1]*(-4.18568363667416e-19 + o[1]*o[2]*(-9.19148577641497e-22 + pi1*(4.27026404402408e-22 + (-6.66749357417962e-23 + 3.49930466305574e-24*pi1)*pi1)))))))))));
          end hupperofp1;

          function hlowerofp2
          "explicit lower specific enthalpy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real pi "dimensionless pressure";
            Real q1 "auxiliary variable";
            Real q2 "auxiliary variable";
            Real[18] o "vector of auxiliary variables";
          algorithm
            pi:=p/data.PSTAR2;
            assert(p > triple.ptriple, "IF97 medium function hlowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            q1:=572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
            q2:=-0.5 + 540.0/q1;
            o[1]:=q1*q1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            o[4]:=pi*pi;
            o[5]:=o[4]*o[4];
            o[6]:=q2*q2;
            o[7]:=o[6]*o[6];
            o[8]:=o[6]*o[7];
            o[9]:=o[5]*o[5];
            o[10]:=o[7]*o[7];
            o[11]:=o[9]*o[9];
            o[12]:=o[10]*o[10];
            o[13]:=o[12]*o[12];
            o[14]:=o[7]*q2;
            o[15]:=o[6]*q2;
            o[16]:=o[10]*o[6];
            o[17]:=o[13]*o[6];
            o[18]:=o[13]*o[6]*q2;
            h:=(4636975733.03507 + 3.74686560065793*o[2] + 3.57966647812489e-06*o[1]*o[2] + 2.81881548488163e-13*o[3] - 76465233.2452145*q1 - 0.00450789338787835*o[2]*q1 - 1.55131504410292e-09*o[1]*o[2]*q1 + o[1]*(2513837.07870341 - 4781981.98764471*o[10]*o[11]*o[12]*o[13]*o[4] + 49.9651389369988*o[11]*o[12]*o[13]*o[4]*o[5]*o[7] + o[15]*o[4]*(1.03746636552761e-13 - 0.00349547959376899*o[16] - 2.55074501962569e-07*o[8])*o[9] + (-242662.235426958*o[10]*o[12] - 3.46022402653609*o[16])*o[4]*o[5]*pi + o[4]*(0.109336249381227 - 2248.08924686956*o[14] - 354742.725841972*o[17] - 24.1331193696374*o[6])*pi - 3.09081828396912e-19*o[11]*o[12]*o[5]*o[7]*pi - 1.24107527851371e-08*o[11]*o[13]*o[4]*o[5]*o[6]*o[7]*pi + 3.99891272904219*o[5]*o[8]*pi + 0.0641817365250892*o[10]*o[7]*o[9]*pi + pi*(-4444.87643334512 - 75253.6156722047*o[14] - 43051.9020511789*o[6] - 22926.6247146068*q2) + o[4]*(-8.23252840892034 - 3927.0508365636*o[15] - 239.325789467604*o[18] - 76407.3727417716*o[8] - 94.4508644545118*q2) + 0.360567666582363*o[5]*(-0.0161221195808321 + q2)*(0.0338039844460968 + q2) + o[11]*(-0.000584580992538624*o[10]*o[12]*o[7] + 1332480.30241755*o[12]*o[13]*q2) + o[9]*(-73850273.6990986*o[18] + 2.24425477627799e-05*o[6]*o[7]*q2) + o[4]*o[5]*(-208438767.026518*o[17] - 1.24971648677697e-05*o[6] - 8442.30378348203*o[10]*o[6]*o[7]*q2) + o[11]*o[9]*(4.73594929247646e-22*o[10]*o[12]*q2 - 13.6411358215175*o[10]*o[12]*o[13]*q2 + 5.52427169406836e-10*o[13]*o[6]*o[7]*q2) + o[11]*o[5]*(2.67174673301715e-06*o[17] + 4.44545133805865e-18*o[12]*o[6]*q2 - 50.2465185106411*o[10]*o[13]*o[6]*o[7]*q2)))/o[1];
          end hlowerofp2;

          function hupperofp2
          "explicit upper specific enthalpy limit of region 2 as function of pressure"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real pi "dimensionless pressure";
            Real[2] o "vector of auxiliary variables";
          algorithm
            pi:=p/data.PSTAR2;
            assert(p > triple.ptriple, "IF97 medium function hupperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            o[1]:=pi*pi;
            o[2]:=o[1]*o[1]*o[1];
            h:=4160663.37647071 + pi*(-4518.48617188327 + pi*(-8.53409968320258 + pi*(0.109090430596056 + pi*(-0.000172486052272327 + pi*(4.2261295097284e-15 + pi*(-1.27295130636232e-10 + pi*(-3.79407294691742e-25 + pi*(7.56960433802525e-23 + pi*(7.16825117265975e-32 + pi*(3.37267475986401e-21 + (-7.5656940729795e-74 + o[1]*(-8.00969737237617e-134 + (1.6746290980312e-65 + pi*(-3.71600586812966e-69 + pi*(8.06630589170884e-129 + (-1.76117969553159e-103 + 1.88543121025106e-84*pi)*pi)))*o[1]))*o[2]))))))))));
          end hupperofp2;

          function d1n "density in region 1 as function of p and T"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Modelica.SIunits.Density d "density";
        protected
            Real pi "dimensionless pressure";
            Real pi1 "dimensionless pressure";
            Real tau "dimensionless temperature";
            Real tau1 "dimensionless temperature";
            Real gpi "dimensionless Gibbs-derivative w.r.t. pi";
            Real[11] o "auxiliary variables";
          algorithm
            pi:=p/data.PSTAR1;
            tau:=data.TSTAR1/T;
            pi1:=7.1 - pi;
            tau1:=tau - 1.222;
            o[1]:=tau1*tau1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            o[4]:=o[1]*o[2];
            o[5]:=o[1]*tau1;
            o[6]:=o[2]*tau1;
            o[7]:=pi1*pi1;
            o[8]:=o[7]*o[7];
            o[9]:=o[8]*o[8];
            o[10]:=o[3]*o[3];
            o[11]:=o[10]*o[10];
            gpi:=pi1*(pi1*((9.5038934535162e-05 + o[2]*(8.4812393955936e-06 + 2.55615384360309e-09*o[4]))/o[2] + pi1*((8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[2]*o[3])*o[5])/o[6] + pi1*(2.02584984300585e-06/o[3] + o[7]*pi1*(o[8]*o[9]*pi1*(o[7]*(o[7]*o[8]*(-7.63737668221055e-22/(o[1]*o[11]*o[2]) + pi1*(pi1*(-5.65070932023524e-23/(o[11]*o[3]) + 2.99318679335866e-24*pi1/(o[11]*o[3]*tau1)) + 3.5842867920213e-22/(o[1]*o[11]*o[2]*tau1))) - 3.33001080055983e-19/(o[1]*o[10]*o[2]*o[3]*tau1)) + 1.44400475720615e-17/(o[10]*o[2]*o[3]*tau1)) + (1.01874413933128e-08 + 1.39398969845072e-09*o[6])/(o[1]*o[3]*tau1))))) + (0.00094368642146534 + o[5]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[1]*o[2]*o[3]))*tau1))/o[5]) + (-0.00028319080123804 + o[1]*(0.00060706301565874 + o[4]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))))/(o[3]*tau1);
            d:=p/(data.RH2O*T*pi*gpi);
          end d1n;

          function d2n "density in region 2  as function of p and T"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Modelica.SIunits.Density d "density";
        protected
            Real pi "dimensionless pressure";
            Real tau "dimensionless temperature";
            Real tau2 "dimensionless temperature";
            Real gpi "dimensionless Gibbs-derivative w.r.t. pi";
            Real[12] o "auxiliary variables";
          algorithm
            pi:=p/data.PSTAR2;
            tau:=data.TSTAR2/T;
            tau2:=tau - 0.5;
            o[1]:=tau2*tau2;
            o[2]:=o[1]*tau2;
            o[3]:=o[1]*o[1];
            o[4]:=o[3]*o[3];
            o[5]:=o[4]*o[4];
            o[6]:=o[3]*o[4]*o[5]*tau2;
            o[7]:=o[3]*o[4]*tau2;
            o[8]:=o[1]*o[3]*o[4];
            o[9]:=pi*pi;
            o[10]:=o[9]*o[9];
            o[11]:=o[3]*o[5]*tau2;
            o[12]:=o[5]*o[5];
            gpi:=(1.0 + pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[2])*tau2)) + pi*(tau2*(-6.6065283340406e-05 + (-0.0003789797503263 + o[1]*(-0.007878555448671 + o[2]*(-0.087594591301146 - 5.3349095828174e-05*o[6])))*tau2) + pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[1]*(-9.683303171571e-05 + o[2]*(-0.0045101773626444 - 0.122004760687947*o[6])))*tau2 + pi*(tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2) + pi*(1.14610381688305e-05*o[1]*o[3]*tau2 + pi*(o[2]*(-1.00288598706366e-10 + o[7]*(-0.012702883392813 - 143.374451604624*o[1]*o[5]*tau2)) + pi*(-4.1341695026989e-17 + o[1]*o[4]*(-8.8352662293707e-06 - 0.272627897050173*o[8])*tau2 + pi*(o[4]*(9.0049690883672e-11 - 65.8490727183984*o[3]*o[4]*o[5]) + pi*(1.78287415218792e-07*o[7] + pi*(o[3]*(1.0406965210174e-18 + o[1]*(-1.0234747095929e-12 - 1.0018179379511e-08*o[3])*o[3]) + o[10]*o[9]*((-1.29412653835176e-09 + 1.71088510070544*o[11])*o[6] + o[9]*(-6.05920510335078*o[12]*o[4]*o[5]*tau2 + o[9]*(o[3]*o[5]*(1.78371690710842e-23 + o[1]*o[3]*o[4]*(6.1258633752464e-12 - 8.4004935396416e-05*o[7])*tau2) + pi*(-1.24017662339842e-24*o[11] + pi*(8.32192847496054e-05*o[12]*o[3]*o[5]*tau2 + pi*(o[1]*o[4]*o[5]*(1.75410265428146e-27 + (1.32995316841867e-15 - 2.26487297378904e-05*o[1]*o[5])*o[8])*pi - 2.93678005497663e-14*o[1]*o[12]*o[3]*tau2)))))))))))))))))/pi;
            d:=p/(data.RH2O*T*pi*gpi);
          end d2n;

          function hl_p_R4b
          "explicit approximation of liquid specific enthalpy on the boundary between regions 4 and 3"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real x "auxiliary variable";
          algorithm
            x:=Modelica.Math.acos(p/data.PCRIT);
            h:=(1 + x*(-0.494558695817518 + x*(1.3468000165649 + x*(-3.88938815320975 + x*(6.67938547288793 + x*(-6.75820241066552 + x*(3.5589197446565 + (-0.717981855497894 - 0.000115203294561782*x)*x)))))))*data.HCRIT;
            annotation(smoothOrder=5);
          end hl_p_R4b;

          function hv_p_R4b
          "explicit approximation of vapour specific enthalpy on the boundary between regions 4 and 3"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real x "auxiliary variable";
          algorithm
            x:=Modelica.Math.acos(p/data.PCRIT);
            h:=(1 + x*(0.488015371865569 + x*(0.207967074625069 + x*(-6.08412269842162 + x*(25.0888760229353 + x*(-48.3821518026952 + x*(45.6648916483321 + (-16.9855544296155 + 0.000661693646005769*x)*x)))))))*data.HCRIT;
            annotation(smoothOrder=5);
          end hv_p_R4b;

          function rhol_p_R4b
          "explicit approximation of liquid density on the boundary between regions 4 and 3"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.Density dl "liquid density";
        protected
            Real x "auxiliary variable";
          algorithm
            if p < data.PCRIT then
              x:=Modelica.Math.acos(p/data.PCRIT);
              dl:=(1 + x*(1.90322407909482 + x*(-2.53148618024011 + x*(-8.19144932384355 + x*(94.3419611677839 + x*(-369.367683362338 + x*(796.662791059829 + x*(-994.53853836007 + x*(673.25811770216 + (-191.430773364052 + 0.00052536560808895*x)*x)))))))))*data.DCRIT;
            else
              dl:=data.DCRIT;
            end if;
            annotation(smoothOrder=5);
          end rhol_p_R4b;

          function rhov_p_R4b
          "explicit approximation of vapour density on the boundary between regions 4 and 2"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.Density dv "vapour density";
        protected
            Real x "auxiliary variable";
          algorithm
            if p < data.PCRIT then
              x:=Modelica.Math.acos(p/data.PCRIT);
              dv:=(1 + x*(-1.84638508033626 + x*(-1.14478727188785 + x*(59.1870220307656 + x*(-403.539143181161 + x*(1437.20072453324 + x*(-3015.85354030752 + x*(3740.57903486701 + x*(-2537.3758172539 + (725.876197580378 - 0.00111511116583323*x)*x)))))))))*data.DCRIT;
            else
              dv:=data.DCRIT;
            end if;
            annotation(smoothOrder=5);
          end rhov_p_R4b;

          function boilingcurve_p "properties on the boiling curve"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output
            ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties
                                                                                         bpro
            "property record";
        protected
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives";
            Modelica.SIunits.Pressure plim=min(p, data.PCRIT - 1e-07)
            "pressure limited to critical pressure - epsilon";
            Boolean region3boundary
            "true if boundary between 2-phase and region 3";
            Real pv "partial derivative of p w.r.t v";
          algorithm
            bpro.R:=data.RH2O;
            bpro.T:=Basic.tsat(plim);
            bpro.dpT:=Basic.dptofT(bpro.T);
            region3boundary:=bpro.T > data.TLIMIT1;
            if not region3boundary then
              g:=Basic.g1(p, bpro.T);
              bpro.d:=p/(bpro.R*bpro.T*g.pi*g.gpi);
              bpro.h:=if p > plim then data.HCRIT else bpro.R*bpro.T*g.tau*g.gtau;
              bpro.s:=g.R*(g.tau*g.gtau - g.g);
              bpro.cp:=-bpro.R*g.tau*g.tau*g.gtautau;
              bpro.vt:=bpro.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              bpro.vp:=bpro.R*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
              bpro.pt:=-p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              bpro.pd:=-bpro.R*bpro.T*g.gpi*g.gpi/g.gpipi;
            else
              bpro.d:=rhol_p_R4b(plim);
              f:=Basic.f3(bpro.d, bpro.T);
              bpro.h:=hl_p_R4b(plim);
              bpro.s:=f.R*(f.tau*f.ftau - f.f);
              bpro.cv:=bpro.R*(-f.tau*f.tau*f.ftautau);
              bpro.pt:=bpro.R*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              bpro.pd:=bpro.R*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              pv:=-f.d*f.d*bpro.pd;
              bpro.vp:=1/pv;
              bpro.vt:=-bpro.pt/pv;
            end if;
          end boilingcurve_p;

          function dewcurve_p "properties on the dew curve"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output
            ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties
                                                                                         bpro
            "property record";
        protected
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives";
            Modelica.SIunits.Pressure plim=min(p, data.PCRIT - 1e-07)
            "pressure limited to critical pressure - epsilon";
            Boolean region3boundary
            "true if boundary between 2-phase and region 3";
            Real pv "partial derivative of p w.r.t v";
          algorithm
            bpro.R:=data.RH2O;
            bpro.T:=Basic.tsat(plim);
            bpro.dpT:=Basic.dptofT(bpro.T);
            region3boundary:=bpro.T > data.TLIMIT1;
            if not region3boundary then
              g:=Basic.g2(p, bpro.T);
              bpro.d:=p/(bpro.R*bpro.T*g.pi*g.gpi);
              bpro.h:=if p > plim then data.HCRIT else bpro.R*bpro.T*g.tau*g.gtau;
              bpro.s:=g.R*(g.tau*g.gtau - g.g);
              bpro.cp:=-bpro.R*g.tau*g.tau*g.gtautau;
              bpro.vt:=bpro.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              bpro.vp:=bpro.R*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
              bpro.pt:=-p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              bpro.pd:=-bpro.R*bpro.T*g.gpi*g.gpi/g.gpipi;
            else
              bpro.d:=rhov_p_R4b(plim);
              f:=Basic.f3(bpro.d, bpro.T);
              bpro.h:=hv_p_R4b(plim);
              bpro.s:=f.R*(f.tau*f.ftau - f.f);
              bpro.cv:=bpro.R*(-f.tau*f.tau*f.ftautau);
              bpro.pt:=bpro.R*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              bpro.pd:=bpro.R*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              pv:=-f.d*f.d*bpro.pd;
              bpro.vp:=1/pv;
              bpro.vt:=-bpro.pt/pv;
            end if;
          end dewcurve_p;

          function hvl_p
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input
            ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties
                                                                                        bpro
            "property record";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
          algorithm
            h:=bpro.h;
            annotation(derivative(noDerivative=bpro)=hvl_p_der, Inline=false, LateInline=true);
          end hvl_p;

          function hl_p
          "liquid specific enthalpy on the boundary between regions 4 and 3 or 1"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
          algorithm
            h:=hvl_p(p, boilingcurve_p(p));
          end hl_p;

          function hv_p
          "vapour specific enthalpy on the boundary between regions 4 and 3 or 2"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
          algorithm
            h:=hvl_p(p, dewcurve_p(p));
          end hv_p;

          function hvl_p_der
          "derivative function for the specific enthalpy along the phase boundary"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input
            ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties
                                                                                        bpro
            "property record";
            input Real p_der "derivative of pressure";
            output Real h_der
            "time derivative of specific enthalpy along the phase boundary";
          algorithm
            h_der:=(1/bpro.d - bpro.T*bpro.vt)*p_der + bpro.cp/bpro.dpT*p_der;
          end hvl_p_der;

          function rhol_T "density of saturated water"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature T "temperature";
            output Modelica.SIunits.Density d
            "density of water at the boiling point";
        protected
            Modelica.SIunits.Pressure p "saturation pressure";
          algorithm
            p:=Basic.psat(T);
            if T < data.TLIMIT1 then
              d:=d1n(p, T);
            elseif T < data.TCRIT then
              d:=rhol_p_R4b(p);
            else
              d:=data.DCRIT;
            end if;
          end rhol_T;

          function rhov_T "density of saturated vapour"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature T "temperature";
            output Modelica.SIunits.Density d
            "density of steam at the condensation point";
        protected
            Modelica.SIunits.Pressure p "saturation pressure";
          algorithm
            p:=Basic.psat(T);
            if T < data.TLIMIT1 then
              d:=d2n(p, T);
            elseif T < data.TCRIT then
              d:=rhov_p_R4b(p);
            else
              d:=data.DCRIT;
            end if;
          end rhov_T;

          function region_ph
          "return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific enthalpy"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            input Integer phase=0
            "phase: 2 for two-phase, 1 for one phase, 0 if not known";
            input Integer mode=0
            "mode: 0 means check, otherwise assume region=mode";
            output Integer region "region (valid values: 1,2,3,4,5) in IF97";
        protected
            Boolean hsubcrit;
            Modelica.SIunits.Temperature Ttest;
            constant Real[5] n=data.n;
            Modelica.SIunits.SpecificEnthalpy hl "bubble enthalpy";
            Modelica.SIunits.SpecificEnthalpy hv "dew enthalpy";
          algorithm
            if mode <> 0 then
              region:=mode;
            else
              hl:=hl_p(p);
              hv:=hv_p(p);
              if phase == 2 then
                region:=4;
              else
                if p < triple.ptriple or p > data.PLIMIT1 or h < hlowerofp1(p) or p < 10000000.0 and h > hupperofp5(p) or p >= 10000000.0 and h > hupperofp2(p) then
                  region:=-1;
                else
                  hsubcrit:=h < data.HCRIT;
                  if p < data.PLIMIT4A then
                    if hsubcrit then
                      if phase == 1 then
                        region:=1;
                      else
                        if h < Isentropic.hofpT1(p, Basic.tsat(p)) then
                          region:=1;
                        else
                          region:=4;
                        end if;
                      end if;
                    else
                      if h > hlowerofp5(p) then
                        if p < data.PLIMIT5 and h < hupperofp5(p) then
                          region:=5;
                        else
                          region:=-2;
                        end if;
                      else
                        if phase == 1 then
                          region:=2;
                        else
                          if h > Isentropic.hofpT2(p, Basic.tsat(p)) then
                            region:=2;
                          else
                            region:=4;
                          end if;
                        end if;
                      end if;
                    end if;
                  else
                    if hsubcrit then
                      if h < hupperofp1(p) then
                        region:=1;
                      else
                        if h < hl or p > data.PCRIT then
                          region:=3;
                        else
                          region:=4;
                        end if;
                      end if;
                    else
                      if h > hlowerofp2(p) then
                        region:=2;
                      else
                        if h > hv or p > data.PCRIT then
                          region:=3;
                        else
                          region:=4;
                        end if;
                      end if;
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end region_ph;

          function region_pT
          "return the current region (valid values: 1,2,3,5) in IF97, given pressure and temperature"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            input Integer mode=0
            "mode: 0 means check, otherwise assume region=mode";
            output Integer region
            "region (valid values: 1,2,3,5) in IF97, region 4 is impossible!";
          algorithm
            if mode <> 0 then
              region:=mode;
            else
              if p < data.PLIMIT4A then
                if T > data.TLIMIT2 then
                  region:=5;
                elseif T > Basic.tsat(p) then
                  region:=2;
                else
                  region:=1;
                end if;
              else
                if T < data.TLIMIT1 then
                  region:=1;
                elseif T < boundary23ofp(p) then
                  region:=3;
                else
                  region:=2;
                end if;
              end if;
            end if;
          end region_pT;
          annotation(Documentation(info="<HTML><h4>Package description</h4>
 <p>Package <b>Regions</b> contains a large number of auxiliary functions which are neede to compute the current region
 of the IAPWS/IF97 for a given pair of input variables as quickly as possible. The focus of this implementation was on
 computational efficiency, not on compact code. Many of the function values calulated in these functions could be obtained
 using the fundamental functions of IAPWS/IF97, but with considerable overhead. If the region of IAPWS/IF97 is known in advance,
 the input variable mode can be set to the region, then the somewhat costly region checks are omitted.
 The checking for the phase has to be done outside the region functions because many properties are not
 differentiable at the region boundary. If the input phase is 2, the output region will be set to 4 immediately.</p>
 <h4>Package contents</h4>
 <p> The main 4 functions in this package are the functions returning the appropriate region for two input variables.
 <ul>
 <li>Function <b>region_ph</b> compute the region of IAPWS/IF97 for input pair pressure and specific enthalpy.</li>
 <li>Function <b>region_ps</b> compute the region of IAPWS/IF97 for input pair pressure and specific entropy</li>
 <li>Function <b>region_dT</b> compute the region of IAPWS/IF97 for input pair density and temperature.</li>
 <li>Function <b>region_pT</b> compute the region of IAPWS/IF97 for input pair pressure and temperature (only ine phase region).</li>
 </ul>
 <p>In addition, functions of the boiling and condensation curves compute the specific enthalpy, specific entropy, or density on these
 curves. The functions for the saturation pressure and temperature are included in the package <b>Basic</b> because they are part of
 the original <a href=\"IF97documentation/IF97.pdf\">IAPWS/IF97 standards document</a>. These functions are also aliased to
 be used directly from package <b>Water</b>.
 </p>
 <ul>
 <li>Function <b>hl_p</b> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
 the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>hv_p</b> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
 the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>sl_p</b> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
 the critical  specific entropy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>sv_p</b> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
 the critical  specific entropyis returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>rhol_T</b> computes the liquid density as a function of temperature. For overcritical temperatures,
 the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>rhol_T</b> computes the vapour density as a function of temperature. For overcritical temperatures,
 the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
 </ul>
 </p>
 <p>All other functions are auxiliary functions called from the region functions to check a specific boundary.</p>
 <ul>
 <li>Function <b>boundary23ofT</b> computes the boundary pressure between regions 2 and 3 (input temperature)</li>
 <li>Function <b>boundary23ofp</b> computes the boundary temperature between regions 2 and 3 (input pressure)</li>
 <li>Function <b>hlowerofp5</b> computes the lower specific enthalpy limit of region 5 (input p, T=1073.15 K)</li>
 <li>Function <b>hupperofp5</b> computes the upper specific enthalpy limit of region 5 (input p, T=2273.15 K)</li>
 <li>Function <b>slowerofp5</b> computes the lower specific entropy limit of region 5 (input p, T=1073.15 K)</li>
 <li>Function <b>supperofp5</b> computes the upper specific entropy limit of region 5 (input p, T=2273.15 K)</li>
 <li>Function <b>hlowerofp1</b> computes the lower specific enthalpy limit of region 1 (input p, T=273.15 K)</li>
 <li>Function <b>hupperofp1</b> computes the upper specific enthalpy limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <b>slowerofp1</b> computes the lower specific entropy limit of region 1 (input p, T=273.15 K)</li>
 <li>Function <b>supperofp1</b> computes the upper specific entropy limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <b>hlowerofp2</b> computes the lower specific enthalpy limit of region 2 (input p, T=623.15 K)</li>
 <li>Function <b>hupperofp2</b> computes the upper specific enthalpy limit of region 2 (input p, T=1073.15 K)</li>
 <li>Function <b>slowerofp2</b> computes the lower specific entropy limit of region 2 (input p, T=623.15 K)</li>
 <li>Function <b>supperofp2</b> computes the upper specific entropy limit of region 2 (input p, T=1073.15 K)</li>
 <li>Function <b>d1n</b> computes the density in region 1 as function of pressure and temperature</li>
 <li>Function <b>d2n</b> computes the density in region 2 as function of pressure and temperature</li>
 <li>Function <b>dhot1ofp</b> computes the hot density limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <b>dupper1ofT</b>computes the high pressure density limit of region 1 (input T, p=100MPa)</li>
 <li>Function <b>hl_p_R4b</b> computes a high accuracy approximation to the liquid enthalpy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>hv_p_R4b</b> computes a high accuracy approximation to the vapour enthalpy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>sl_p_R4b</b> computes a high accuracy approximation to the liquid entropy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>sv_p_R4b</b> computes a high accuracy approximation to the vapour entropy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>rhol_p_R4b</b> computes a high accuracy approximation to the liquid density for temperatures > 623.15 K (input p)</li>
 <li>Function <b>rhov_p_R4b</b> computes a high accuracy approximation to the vapour density for temperatures > 623.15 K (input p)</li>
 </ul>
 </p>
<h4>Version Info and Revision history
</h4>
 <ul>
<li>First implemented: <i>July, 2000</i>
       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
       </li>
</ul>
<address>Authors: Hubertus Tummescheit, Jonas Eborn and Falko Jens Wagner<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
 <ul>
 <li>Initial version: July 2000</li>
 <li>Revised and extended for inclusion in Modelica.Thermal: December 2002</li>
</ul>
</HTML>
"));
        end Regions;

        package Basic "Base functions as described in IAWPS/IF97"
          extends Modelica.Icons.Library;

          function g1 "Gibbs function for region 1: g(p,T)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        protected
            Real pi1 "dimensionless pressure";
            Real tau1 "dimensionless temperature";
            Real[45] o "vector of auxiliary variables";
          algorithm
            g.p:=p;
            g.T:=T;
            g.R:=data.RH2O;
            g.pi:=max(p, triple.ptriple)/data.PSTAR1;
            g.tau:=data.TSTAR1/max(T, triple.Ttriple);
            pi1:=7.1 - g.pi;
            tau1:=-1.222 + g.tau;
            o[1]:=tau1*tau1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            o[4]:=o[3]*tau1;
            o[5]:=1/o[4];
            o[6]:=o[1]*o[2];
            o[7]:=o[1]*tau1;
            o[8]:=1/o[7];
            o[9]:=o[1]*o[2]*o[3];
            o[10]:=1/o[2];
            o[11]:=o[2]*tau1;
            o[12]:=1/o[11];
            o[13]:=o[2]*o[3];
            o[14]:=1/o[3];
            o[15]:=pi1*pi1;
            o[16]:=o[15]*pi1;
            o[17]:=o[15]*o[15];
            o[18]:=o[17]*o[17];
            o[19]:=o[17]*o[18]*pi1;
            o[20]:=o[15]*o[17];
            o[21]:=o[3]*o[3];
            o[22]:=o[21]*o[21];
            o[23]:=o[22]*o[3]*tau1;
            o[24]:=1/o[23];
            o[25]:=o[22]*o[3];
            o[26]:=1/o[25];
            o[27]:=o[1]*o[2]*o[22]*tau1;
            o[28]:=1/o[27];
            o[29]:=o[1]*o[2]*o[22];
            o[30]:=1/o[29];
            o[31]:=o[1]*o[2]*o[21]*o[3]*tau1;
            o[32]:=1/o[31];
            o[33]:=o[2]*o[21]*o[3]*tau1;
            o[34]:=1/o[33];
            o[35]:=o[1]*o[3]*tau1;
            o[36]:=1/o[35];
            o[37]:=o[1]*o[3];
            o[38]:=1/o[37];
            o[39]:=1/o[6];
            o[40]:=o[1]*o[22]*o[3];
            o[41]:=1/o[40];
            o[42]:=1/o[22];
            o[43]:=o[1]*o[2]*o[21]*o[3];
            o[44]:=1/o[43];
            o[45]:=1/o[13];
            g.g:=pi1*(pi1*(pi1*(o[10]*(-3.1679644845054e-05 + o[2]*(-2.8270797985312e-06 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.2425281908e-06 + (-6.5171222895601e-07 - 1.4341729937924e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-07*o[14] + o[16]*((-1.2734301741641e-09 - 1.7424871230634e-10*o[11])*o[36] + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.4478307828521e-20*o[32] + o[20]*(2.6335781662795e-23*o[30] + pi1*(-1.1947622640071e-23*o[28] + pi1*(1.8228094581404e-24*o[26] - 9.3537087292458e-26*o[24]*pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.00030001780793026 + (4.7661393906987e-05 + o[1]*(-4.4141845330846e-06 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.00028319080123804 + o[1]*(-0.00060706301565874 + o[6]*(-0.018990068218419 + tau1*(-0.032529748770505 + (-0.021841717175414 - 5.283835796993e-05*o[1])*tau1))))) + (0.14632971213167 + tau1*(-0.84548187169114 + tau1*(-3.756360367204 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.15772038513228 + (-0.016616417199501 + 0.00081214629983568*tau1)*tau1))))))/o[1];
            g.gpi:=pi1*(pi1*(o[10]*(9.5038934535162e-05 + o[2]*(8.4812393955936e-06 + 2.55615384360309e-09*o[6])) + pi1*(o[12]*(8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[13])*o[7]) + pi1*(2.02584984300585e-06*o[14] + o[16]*((1.01874413933128e-08 + 1.39398969845072e-09*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[34] + o[15]*(-3.3300108005598e-19*o[32] + o[20]*(-7.6373766822106e-22*o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.6507093202352e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(0.00094368642146534 + o[7]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[9]))*tau1))) + o[5]*(-0.00028319080123804 + o[1]*(0.00060706301565874 + o[6]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))));
            g.gpipi:=pi1*(o[10]*(-0.000190077869070324 + o[2]*(-1.69624787911872e-05 - 5.1123076872062e-09*o[6])) + pi1*(o[12]*(-2.69103382896e-05 + (-7.8205467474721e-06 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-06*o[14] + o[16]*((-7.131208975319e-08 - 9.757927889155e-09*o[11])*o[36] + o[19]*(-2.8880095144123e-16*o[34] + o[15]*(7.3260237612316e-18*o[32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*o[28] + pi1*(1.69521279607057e-21*o[26] - 9.2788790594118e-23*o[24]*pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052 + (9.5322787813974e-05 + o[1]*(-8.8283690661692e-06 - 1.45389992595188e-15*o[9]))*tau1));
            g.gtau:=pi1*(o[38]*(-0.00254871721114236 + o[1]*(0.0042494411096112 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.1123076872062e-09*o[37]) + pi1*(o[39]*(1.1212640954e-05 + (1.30342445791202e-06 - 1.4341729937924e-12*o[13])*o[7]) + pi1*(3.2413597488094e-06*o[5] + o[16]*((1.40077319158051e-08 + 1.04549227383804e-09*o[11])*o[45] + o[19]*(1.9941018075704e-17*o[44] + o[15]*(-4.4882754268415e-19*o[42] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.6595728296277e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.8350205789908e-24*o[41]*pi1))))))))))) + o[8]*(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
            g.gtautau:=pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.033995528876889 + (-0.037980136436838 - 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]*(-0.005662118528792 + o[6]*(-2.64851071985076e-05 - 1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 - 2.55615384360309e-08*o[37])*o[39] + pi1*(pi1*(-2.91722377392842e-05*o[38] + o[16]*(o[19]*(-5.9823054227112e-16*o[32] + o[15]*(o[20]*(3.9029628424262e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(2.98940751135026e-21*o[41] - 1.61070864317613e-22*pi1/(o[1]*o[22]*o[3]*tau1)))) + 1.43624813658928e-17/(o[22]*tau1))) + (-1.68092782989661e-07 - 7.3184459168663e-09*o[11])/(o[2]*o[3]*tau1))) + (-6.7275845724e-05 + (-3.9102733737361e-06 - 1.29075569441316e-11*o[13])*o[7])/(o[1]*o[2]*tau1))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]*(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 + 0.0162429259967136*tau1)*tau1))));
            g.gtaupi:=o[38]*(0.00254871721114236 + o[1]*(-0.0042494411096112 + (-0.018990068218419 + (0.021841717175414 + 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(-0.00283105926439602 + o[2]*(-9.5322787813974e-05 + o[1]*(2.64851071985076e-05 + 2.4716298741182e-14*o[9]))) + pi1*(o[12]*(-0.00038015573814065 + 1.53369230616185e-08*o[37]) + pi1*(o[39]*(-4.4850563816e-05 + (-5.2136978316481e-06 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-1.62067987440468e-05*o[5] + o[16]*((-1.12061855326441e-07 - 8.3639381907043e-09*o[11])*o[45] + o[19]*(-4.1876137958978e-16*o[44] + o[15]*(1.03230334817355e-17*o[42] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*o[26] + pi1*(2.2602837280941e-21*o[24] - 1.22720658527705e-22*o[41]*pi1))))))))));
          end g1;

          function g2 "Gibbs function for region 2: g(p,T)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        protected
            Real tau2 "dimensionless temperature";
            Real[55] o "vector of auxiliary variables";
          algorithm
            g.p:=p;
            g.T:=T;
            g.R:=data.RH2O;
            g.pi:=max(p, triple.ptriple)/data.PSTAR2;
            g.tau:=data.TSTAR2/max(T, triple.Ttriple);
            tau2:=-0.5 + g.tau;
            o[1]:=tau2*tau2;
            o[2]:=o[1]*tau2;
            o[3]:=-0.05032527872793*o[2];
            o[4]:=-0.057581259083432 + o[3];
            o[5]:=o[4]*tau2;
            o[6]:=-0.045996013696365 + o[5];
            o[7]:=o[6]*tau2;
            o[8]:=-0.017834862292358 + o[7];
            o[9]:=o[8]*tau2;
            o[10]:=o[1]*o[1];
            o[11]:=o[10]*o[10];
            o[12]:=o[11]*o[11];
            o[13]:=o[10]*o[11]*o[12]*tau2;
            o[14]:=o[1]*o[10]*tau2;
            o[15]:=o[10]*o[11]*tau2;
            o[16]:=o[1]*o[12]*tau2;
            o[17]:=o[1]*o[11]*tau2;
            o[18]:=o[1]*o[10]*o[11];
            o[19]:=o[10]*o[11]*o[12];
            o[20]:=o[1]*o[10];
            o[21]:=g.pi*g.pi;
            o[22]:=o[21]*o[21];
            o[23]:=o[21]*o[22];
            o[24]:=o[10]*o[12]*tau2;
            o[25]:=o[12]*o[12];
            o[26]:=o[11]*o[12]*o[25]*tau2;
            o[27]:=o[10]*o[12];
            o[28]:=o[1]*o[10]*o[11]*tau2;
            o[29]:=o[10]*o[12]*o[25]*tau2;
            o[30]:=o[1]*o[10]*o[25]*tau2;
            o[31]:=o[1]*o[11]*o[12];
            o[32]:=o[1]*o[12];
            o[33]:=g.tau*g.tau;
            o[34]:=o[33]*o[33];
            o[35]:=-5.3349095828174e-05*o[13];
            o[36]:=-0.087594591301146 + o[35];
            o[37]:=o[2]*o[36];
            o[38]:=-0.007878555448671 + o[37];
            o[39]:=o[1]*o[38];
            o[40]:=-0.0003789797503263 + o[39];
            o[41]:=o[40]*tau2;
            o[42]:=-6.6065283340406e-05 + o[41];
            o[43]:=o[42]*tau2;
            o[44]:=5.7870447262208e-06*tau2;
            o[45]:=-0.30195167236758*o[2];
            o[46]:=-0.172743777250296 + o[45];
            o[47]:=o[46]*tau2;
            o[48]:=-0.09199202739273 + o[47];
            o[49]:=o[48]*tau2;
            o[50]:=o[1]*o[11];
            o[51]:=o[10]*o[11];
            o[52]:=o[11]*o[12]*o[25];
            o[53]:=o[10]*o[12]*o[25];
            o[54]:=o[1]*o[10]*o[25];
            o[55]:=o[11]*o[12]*tau2;
            g.g:=g.pi*(-0.0017731742473213 + o[9] + g.pi*(tau2*(-3.3032641670203e-05 + (-0.00018948987516315 + o[1]*(-0.0039392777243355 + (-0.043797295650573 - 2.6674547914087e-05*o[13])*o[2]))*tau2) + g.pi*(2.0481737692309e-08 + (4.3870667284435e-07 + o[1]*(-3.227767723857e-05 + (-0.0015033924542148 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi*(g.pi*(2.2922076337661e-06*o[14] + g.pi*((-1.6714766451061e-11 + o[15]*(-0.0021171472321355 - 23.895741934104*o[16]))*o[2] + g.pi*(-5.905956432427e-18 + o[17]*(-1.2621808899101e-06 - 0.038946842435739*o[18]) + g.pi*(o[11]*(1.1256211360459e-11 - 8.2311340897998*o[19]) + g.pi*(1.9809712802088e-08*o[15] + g.pi*(o[10]*(1.0406965210174e-19 + (-1.0234747095929e-13 - 1.0018179379511e-09*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11 + 0.10693031879409*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*(o[27]*(8.9185845355421e-25 + (3.0629316876232e-13 - 4.2002467698208e-06*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24] + g.pi*(3.7826947613457e-06*o[29] + g.pi*(-1.2768608934681e-15*o[30] + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 - 9.436970724121e-07*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10 + (1.2790717852285e-08 + 4.8225372718507e-07*tau2)*tau2))))) + (-0.00560879118302 + g.tau*(0.07145273881455 + g.tau*(-0.4071049823928 + g.tau*(1.424081971444 + g.tau*(-4.38395111945 + g.tau*(-9.692768600217 + g.tau*(10.08665568018 + (-0.2840863260772 + 0.02126846353307*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);
            g.gpi:=(1.0 + g.pi*(-0.0017731742473213 + o[9] + g.pi*(o[43] + g.pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[1]*(-9.683303171571e-05 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi*(g.pi*(1.14610381688305e-05*o[14] + g.pi*((-1.00288598706366e-10 + o[15]*(-0.012702883392813 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17 + o[17]*(-8.8352662293707e-06 - 0.272627897050173*o[18]) + g.pi*(o[11]*(9.0049690883672e-11 - 65.849072718398*o[19]) + g.pi*(1.78287415218792e-07*o[15] + g.pi*(o[10]*(1.0406965210174e-18 + (-1.0234747095929e-12 - 1.0018179379511e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-09 + 1.71088510070544*o[24]) + o[21]*(-6.0592051033508*o[26] + o[21]*(o[27]*(1.78371690710842e-23 + (6.1258633752464e-12 - 8.4004935396416e-05*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24] + g.pi*(8.3219284749605e-05*o[29] + g.pi*(-2.93678005497663e-14*o[30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 - 2.26487297378904e-05*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2))))))/g.pi;
            g.gpipi:=(-1.0 + o[21]*(o[43] + g.pi*(1.22890426153854e-07 + (2.6322400370661e-06 + o[1]*(-0.00019366606343142 + (-0.0090203547252888 - 0.244009521375894*o[13])*o[2]))*tau2 + g.pi*(g.pi*(4.5844152675322e-05*o[14] + g.pi*((-5.0144299353183e-10 + o[15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16 + o[17]*(-5.3011597376224e-05 - 1.63576738230104*o[18]) + g.pi*(o[11]*(6.303478361857e-10 - 460.94350902879*o[19]) + g.pi*(1.42629932175034e-06*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12 - 9.0163614415599e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-08 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(o[27]*(3.389062123506e-22 + (1.16391404129682e-10 - 0.0015960937725319*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24] + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.4609161209486e-13*o[30] + o[31]*(4.0344361048474e-26 + o[18]*(3.05889228736295e-14 - 0.00052092078397148*o[32]))*g.pi)))))))))))) + tau2*(-9.461677147124e-09 + (1.5348861422742e-07 + o[44])*tau2)))))/o[21];
            g.gtau:=(0.0280439559151 + g.tau*(-0.2858109552582 + g.tau*(1.2213149471784 + g.tau*(-2.848163942888 + g.tau*(4.38395111945 + o[33]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*g.tau)*g.tau))))))/(o[33]*o[34]) + g.pi*(-0.017834862292358 + o[49] + g.pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[1]*(-0.015757110897342 + (-0.306581069554011 - 0.00096028372490713*o[13])*o[2]))*tau2 + g.pi*(4.3870667284435e-07 + o[1]*(-9.683303171571e-05 + (-0.0090203547252888 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*(1.60454534363627e-05*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-1.38839897890111e-05 - 0.97367106089347*o[18])*o[50] + g.pi*(o[14]*(9.0049690883672e-11 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-07*o[51] + g.pi*(o[2]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-09 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[52] + o[21]*(o[16]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27] + g.pi*(0.000200482822351322*o[53] + g.pi*(-4.9797574845256e-14*o[54] + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 - 5.4734430199902e-05*o[32]))*o[55]*g.pi)))))))))))) + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2))));
            g.gtautau:=(-0.1682637354906 + g.tau*(1.429054776291 + g.tau*(-4.8852597887136 + g.tau*(8.544491828664 + g.tau*(-8.7679022389 + o[33]*(-0.5681726521544 + 0.12761078119842*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.09199202739273 + (-0.34548755450059 - 1.5097583618379*o[2])*tau2 + g.pi*(-0.0003789797503263 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.03360993037175*o[13])*o[2]) + g.pi*((-0.00019366606343142 + (-0.045101773626444 - 48.395221739552*o[13])*o[2])*tau2 + g.pi*(2.558143570457e-08 + 2.89352236311042e-06*tau2 + g.pi*(9.6272720618176e-05*o[10]*tau2 + g.pi*((-1.00288598706366e-10 + o[15]*(-0.50811533571252 - 28435.9329015838*o[16]))*tau2 + g.pi*(o[11]*(-0.000138839897890111 - 23.3681054614434*o[18])*tau2 + g.pi*((6.303478361857e-10 - 10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-06*o[17] + g.pi*(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 - 1.823308647071e-07*o[10])*o[20]) + o[23]*(o[1]*o[11]*o[12]*(-6.5676921821352e-08 + 261.979281045521*o[24])*tau2 + o[21]*(-1074.49903832754*o[1]*o[10]*o[12]*o[25]*tau2 + o[21]*((3.389062123506e-22 + (3.6448887082716e-10 - 0.0094757567127157*o[15])*o[28])*o[32] + g.pi*(-2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[1]*o[12]*o[25]*tau2 + g.pi*(o[11]*o[12]*(4.750694688679e-26 + o[18]*(8.6446955947214e-14 - 0.0031198625213944*o[32]))*g.pi - 1.89230784411972e-12*o[10]*o[25]*tau2))))))))))))))));
            g.gtaupi:=-0.017834862292358 + o[49] + g.pi*(-6.6065283340406e-05 + (-0.0007579595006526 + o[1]*(-0.031514221794684 + (-0.61316213910802 - 0.00192056744981426*o[13])*o[2]))*tau2 + g.pi*(1.31612001853305e-06 + o[1]*(-0.00029049909514713 + (-0.0270610641758664 - 4.2701666240781*o[13])*o[2]) + g.pi*(-3.15389238237468e-09 + g.pi*(8.0227267181813e-05*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]*(-0.203246134285008 - 5018.1058061618*o[16])) + g.pi*((-9.7187928523078e-05 - 6.8156974262543*o[18])*o[50] + g.pi*(o[14]*(7.2039752706938e-10 - 2370.56661786234*o[19]) + g.pi*(2.3177363978443e-06*o[51] + g.pi*(o[2]*(4.1627860840696e-18 + (-1.0234747095929e-11 - 1.40254511313154e-07*o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-08 + 85.544255035272*o[24]) + o[21]*(-345.37469089099*o[52] + o[21]*(o[16]*(3.5674338142168e-22 + (2.14405218133624e-10 - 0.004032236899028*o[15])*o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(0.0044106220917291*o[53] + g.pi*(-1.14534422144089e-12*o[54] + (4.5606669011318e-26 + o[18]*(5.3198126736747e-14 - 0.00131362632479764*o[32]))*o[55]*g.pi)))))))))))) + (1.0232574281828e-07 + o[44])*tau2)));
          end g2;

          function f3 "Helmholtz function for region 3: f(d,T)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Density d "density";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives wrt delta and tau";
        protected
            Real[40] o "vector of auxiliary variables";
          algorithm
            f.T:=T;
            f.d:=d;
            f.R:=data.RH2O;
            f.tau:=data.TCRIT/T;
            f.delta:=if d == data.DCRIT and T == data.TCRIT then 1 - Modelica.Constants.eps else abs(d/data.DCRIT);
            o[1]:=f.tau*f.tau;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*f.tau;
            o[4]:=o[1]*f.tau;
            o[5]:=o[2]*o[2];
            o[6]:=o[1]*o[5]*f.tau;
            o[7]:=o[5]*f.tau;
            o[8]:=-0.64207765181607*o[1];
            o[9]:=0.88521043984318 + o[8];
            o[10]:=o[7]*o[9];
            o[11]:=-1.1524407806681 + o[10];
            o[12]:=o[11]*o[2];
            o[13]:=-1.2654315477714 + o[12];
            o[14]:=o[1]*o[13];
            o[15]:=o[1]*o[2]*o[5]*f.tau;
            o[16]:=o[2]*o[5];
            o[17]:=o[1]*o[5];
            o[18]:=o[5]*o[5];
            o[19]:=o[1]*o[18]*o[2];
            o[20]:=o[1]*o[18]*o[2]*f.tau;
            o[21]:=o[18]*o[5];
            o[22]:=o[1]*o[18]*o[5];
            o[23]:=0.25116816848616*o[2];
            o[24]:=0.078841073758308 + o[23];
            o[25]:=o[15]*o[24];
            o[26]:=-6.100523451393 + o[25];
            o[27]:=o[26]*f.tau;
            o[28]:=9.7944563083754 + o[27];
            o[29]:=o[2]*o[28];
            o[30]:=-1.70429417648412 + o[29];
            o[31]:=o[1]*o[30];
            o[32]:=f.delta*f.delta;
            o[33]:=-10.9153200808732*o[1];
            o[34]:=13.2781565976477 + o[33];
            o[35]:=o[34]*o[7];
            o[36]:=-6.9146446840086 + o[35];
            o[37]:=o[2]*o[36];
            o[38]:=-2.5308630955428 + o[37];
            o[39]:=o[38]*f.tau;
            o[40]:=o[18]*o[5]*f.tau;
            f.f:=-15.732845290239 + f.tau*(20.944396974307 + (-7.6867707878716 + o[3]*(2.6185947787954 + o[4]*(-2.808078114862 + o[1]*(1.2053369696517 - 0.0084566812812502*o[6]))))*f.tau) + f.delta*(o[14] + f.delta*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(4.8972281541877 + (-3.0502617256965 + o[15]*(0.039420536879154 + 0.12558408424308*o[2]))*f.tau)) + f.delta*(-0.2799932969871 + o[1]*(1.389979956946 + o[1]*(-2.018991502357 + o[16]*(-0.0082147637173963 - 0.47596035734923*o[17]))) + f.delta*(0.0439840744735 + o[1]*(-0.44476435428739 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + f.delta*(f.delta*(-0.022175400873096 + o[1]*(0.094260751665092 + 0.16436278447961*o[21]) + f.delta*(-0.013503372241348*o[1] + f.delta*(-0.014834345352472*o[22] + f.delta*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21]) + f.delta*(8.0964802996215e-05 - 4.4923899061815e-05*f.delta*o[22] - 0.00016557679795037*f.tau))))) + (0.10770512626332 + o[1]*(-0.32913623258954 - 0.50871062041158*o[20]))*f.tau))))) + 1.0658070028513*Modelica.Math.log(f.delta);
            f.fdelta:=(1.0658070028513 + f.delta*(o[14] + f.delta*(0.76986920373342 + o[31] + f.delta*(-0.8399798909613 + o[1]*(4.169939870838 + o[1]*(-6.056974507071 + o[16]*(-0.0246442911521889 - 1.42788107204769*o[17]))) + f.delta*(0.175936297894 + o[1]*(-1.77905741714956 + o[1]*(3.6228828287893 + 2.82089800351868*o[19])) + f.delta*(f.delta*(-0.133052405238576 + o[1]*(0.56556450999055 + 0.98617670687766*o[21]) + f.delta*(-0.094523605689436*o[1] + f.delta*(-0.118674762819776*o[22] + f.delta*(o[1]*(0.0052130658265276 + 0.0290780142333399*o[21]) + f.delta*(0.00080964802996215 - 0.00049416288967996*f.delta*o[22] - 0.0016557679795037*f.tau))))) + (0.5385256313166 + o[1]*(-1.6456811629477 - 2.5435531020579*o[20]))*f.tau))))))/f.delta;
            f.fdeltadelta:=(-1.0658070028513 + o[32]*(0.76986920373342 + o[31] + f.delta*(-1.6799597819226 + o[1]*(8.339879741676 + o[1]*(-12.113949014142 + o[16]*(-0.049288582304378 - 2.85576214409538*o[17]))) + f.delta*(0.527808893682 + o[1]*(-5.3371722514487 + o[1]*(10.868648486368 + 8.462694010556*o[19])) + f.delta*(f.delta*(-0.66526202619288 + o[1]*(2.82782254995276 + 4.9308835343883*o[21]) + f.delta*(-0.56714163413662*o[1] + f.delta*(-0.83072333973843*o[22] + f.delta*(o[1]*(0.04170452661222 + 0.232624113866719*o[21]) + f.delta*(0.0072868322696594 - 0.0049416288967996*f.delta*o[22] - 0.0149019118155333*f.tau))))) + (2.1541025252664 + o[1]*(-6.5827246517908 - 10.1742124082316*o[20]))*f.tau)))))/o[32];
            f.ftau:=20.944396974307 + (-15.3735415757432 + o[3]*(18.3301634515678 + o[4]*(-28.08078114862 + o[1]*(14.4640436358204 - 0.194503669468755*o[6]))))*f.tau + f.delta*(o[39] + f.delta*(f.tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[15]*(0.86725181134139 + 3.2651861903201*o[2]))*f.tau)) + f.delta*((2.779959913892 + o[1]*(-8.075966009428 + o[16]*(-0.131436219478341 - 12.37496929108*o[17])))*f.tau + f.delta*((-0.88952870857478 + o[1]*(3.6228828287893 + 18.3358370228714*o[19]))*f.tau + f.delta*(0.10770512626332 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20]) + f.delta*((0.188521503330184 + 4.2734323964699*o[21])*f.tau + f.delta*(-0.027006744482696*f.tau + f.delta*(-0.38569297916427*o[40] + f.delta*(f.delta*(-0.00016557679795037 - 0.00116802137560719*f.delta*o[40]) + (0.00115845907256168 + 0.084003152229649*o[21])*f.tau)))))))));
            f.ftautau:=-15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.72703033758 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + f.delta*(-2.5308630955428 + o[2]*(-34.573223420043 + (185.894192367068 - 174.645121293971*o[1])*o[7]) + f.delta*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*f.tau) + f.delta*(2.779959913892 + o[1]*(-24.227898028284 + o[16]*(-1.97154329217511 - 309.374232277*o[17])) + f.delta*(-0.88952870857478 + o[1]*(10.868648486368 + 458.39592557179*o[19]) + f.delta*(f.delta*(0.188521503330184 + 106.835809911747*o[21] + f.delta*(-0.027006744482696 + f.delta*(-9.6423244791068*o[21] + f.delta*(0.00115845907256168 + 2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724 - 330.66190326753*o[20])*f.tau)))));
            f.fdeltatau:=o[39] + f.delta*(f.tau*(-3.4085883529682 + o[2]*(58.766737850252 + (-42.703664159751 + o[15]*(1.73450362268278 + 6.5303723806402*o[2]))*f.tau)) + f.delta*((8.339879741676 + o[1]*(-24.227898028284 + o[16]*(-0.39430865843502 - 37.12490787324*o[17])))*f.tau + f.delta*((-3.5581148342991 + o[1]*(14.4915313151573 + 73.343348091486*o[19]))*f.tau + f.delta*(0.5385256313166 + o[1]*(-4.9370434888431 - 66.132380653505*o[20]) + f.delta*((1.1311290199811 + 25.6405943788192*o[21])*f.tau + f.delta*(-0.189047211378872*f.tau + f.delta*(-3.08554383331418*o[40] + f.delta*(f.delta*(-0.0016557679795037 - 0.0128482351316791*f.delta*o[40]) + (0.0104261316530551 + 0.75602837006684*o[21])*f.tau))))))));
          end f3;

          function g5 "base function for region 5: g(p,T)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Modelica.Media.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        protected
            Real[11] o "vector of auxiliary variables";
          algorithm
            g.p:=p;
            g.T:=T;
            g.R:=data.RH2O;
            g.pi:=max(p, triple.ptriple)/data.PSTAR5;
            g.tau:=data.TSTAR5/max(T, triple.Ttriple);
            o[1]:=g.tau*g.tau;
            o[2]:=-0.004594282089991*o[1];
            o[3]:=0.0021774678714571 + o[2];
            o[4]:=o[3]*g.tau;
            o[5]:=o[1]*g.tau;
            o[6]:=o[1]*o[1];
            o[7]:=o[6]*o[6];
            o[8]:=o[7]*g.tau;
            o[9]:=-7.9449656719138e-06*o[8];
            o[10]:=g.pi*g.pi;
            o[11]:=-0.013782846269973*o[1];
            g.g:=g.pi*(-0.00012563183589592 + o[4] + g.pi*(-3.9724828359569e-06*o[8] + 1.2919228289784e-07*o[5]*g.pi)) + (-0.024805148933466 + g.tau*(0.36901534980333 + g.tau*(-3.1161318213925 + g.tau*(-13.179983674201 + (6.8540841634434 - 0.32961626538917*g.tau)*g.tau + Modelica.Math.log(g.pi)))))/o[5];
            g.gpi:=(1.0 + g.pi*(-0.00012563183589592 + o[4] + g.pi*(o[9] + 3.8757684869352e-07*o[5]*g.pi)))/g.pi;
            g.gpipi:=(-1.0 + o[10]*(o[9] + 7.7515369738704e-07*o[5]*g.pi))/o[10];
            g.gtau:=g.pi*(0.0021774678714571 + o[11] + g.pi*(-3.5752345523612e-05*o[7] + 3.8757684869352e-07*o[1]*g.pi)) + (0.074415446800398 + g.tau*(-0.73803069960666 + (3.1161318213925 + o[1]*(6.8540841634434 - 0.65923253077834*g.tau))*g.tau))/o[6];
            g.gtautau:=(-0.297661787201592 + g.tau*(2.21409209881998 + (-6.232263642785 - 0.65923253077834*o[5])*g.tau))/(o[6]*g.tau) + g.pi*(-0.027565692539946*g.tau + g.pi*(-0.000286018764188897*o[1]*o[6]*g.tau + 7.7515369738704e-07*g.pi*g.tau));
            g.gtaupi:=0.0021774678714571 + o[11] + g.pi*(-7.1504691047224e-05*o[7] + 1.16273054608056e-06*o[1]*g.pi);
          end g5;

          function tph1 "inverse function for region 1: T(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            output Modelica.SIunits.Temperature T "temperature (K)";
        protected
            Real pi "dimensionless pressure";
            Real eta1 "dimensionless specific enthalpy";
            Real[3] o "vector of auxiliary variables";
          algorithm
            assert(p > triple.ptriple, "IF97 medium function tph1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            pi:=p/data.PSTAR2;
            eta1:=h/data.HSTAR1 + 1.0;
            o[1]:=eta1*eta1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            T:=-238.72489924521 - 13.391744872602*pi + eta1*(404.21188637945 + 43.211039183559*pi + eta1*(113.49746881718 - 54.010067170506*pi + eta1*(30.535892203916*pi + eta1*(-6.5964749423638*pi + o[1]*(-5.8457616048039 + o[2]*(pi*(0.0093965400878363 + (-2.5858641282073e-05 + 6.6456186191635e-08*pi)*pi) + o[2]*o[3]*(-0.0001528548241314 + o[1]*o[3]*(-1.0866707695377e-06 + pi*(1.157364750534e-07 + pi*(-4.0644363084799e-09 + pi*(8.0670734103027e-11 + pi*(-9.3477771213947e-13 + (5.8265442020601e-15 - 1.5020185953503e-17*pi)*pi))))))))))));
          end tph1;

          function tph2 "reverse function for region 2: T(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            output Modelica.SIunits.Temperature T "temperature (K)";
        protected
            Real pi "dimensionless pressure";
            Real pi2b "dimensionless pressure";
            Real pi2c "dimensionless pressure";
            Real eta "dimensionless specific enthalpy";
            Real etabc "dimensionless specific enthalpy";
            Real eta2a "dimensionless specific enthalpy";
            Real eta2b "dimensionless specific enthalpy";
            Real eta2c "dimensionless specific enthalpy";
            Real[8] o "vector of auxiliary variables";
          algorithm
            pi:=p*data.IPSTAR;
            eta:=h*data.IHSTAR;
            etabc:=h*0.001;
            if pi < 4.0 then
              eta2a:=eta - 2.1;
              o[1]:=eta2a*eta2a;
              o[2]:=o[1]*o[1];
              o[3]:=pi*pi;
              o[4]:=o[3]*o[3];
              o[5]:=o[3]*pi;
              T:=1089.8952318288 + (1.844574935579 - 0.0061707422868339*pi)*pi + eta2a*(849.51654495535 - 4.1792700549624*pi + eta2a*(-107.81748091826 + (6.2478196935812 - 0.31078046629583*pi)*pi + eta2a*(33.153654801263 - 17.344563108114*pi + o[2]*(-7.4232016790248 + pi*(-200.58176862096 + 11.670873077107*pi) + o[1]*(271.96065473796*pi + o[1]*(-455.11318285818*pi + eta2a*(1.3865724283226*o[4] + o[1]*o[2]*(3091.9688604755*pi + o[1]*(11.765048724356 + o[2]*(-13551.334240775*o[5] + o[2]*(-62.459855192507*o[3]*o[4]*pi + o[2]*(o[4]*(235988.32556514 + 7399.9835474766*pi) + o[1]*(19127.72923966*o[3]*o[4] + o[1]*(o[3]*(128127984.04046 - 551966.9703006*o[5]) + o[1]*(-985549096.23276*o[3] + o[1]*(2822454697.3002*o[3] + o[1]*(o[3]*(-3594897141.0703 + 3715408.5996233*o[5]) + o[1]*pi*(252266.40357872 + pi*(1722734991.3197 + pi*(12848734.66465 + (-13105236.545054 - 415351.64835634*o[3])*pi))))))))))))))))))));
            elseif pi < (0.00012809002730136*etabc - 0.67955786399241)*etabc + 905.84278514723 then
              eta2b:=eta - 2.6;
              pi2b:=pi - 2.0;
              o[1]:=pi2b*pi2b;
              o[2]:=o[1]*pi2b;
              o[3]:=o[1]*o[1];
              o[4]:=eta2b*eta2b;
              o[5]:=o[4]*o[4];
              o[6]:=o[4]*o[5];
              o[7]:=o[5]*o[5];
              T:=1489.5041079516 + 0.93747147377932*pi2b + eta2b*(743.07798314034 + o[2]*(0.00011032831789999 - 1.7565233969407e-18*o[1]*o[3]) + eta2b*(-97.708318797837 + pi2b*(3.3593118604916 + pi2b*(-0.021810755324761 + pi2b*(0.00018955248387902 + (2.8640237477456e-07 - 8.1456365207833e-14*o[2])*pi2b))) + o[5]*(3.3809355601454*pi2b + o[4]*(-0.10829784403677*o[1] + o[5]*(2.4742464705674 + (0.16844539671904 + o[1]*(0.0030891541160537 - 1.0779857357512e-05*pi2b))*pi2b + o[6]*(-0.63281320016026 + pi2b*(0.73875745236695 + (-0.046333324635812 + o[1]*(-7.6462712454814e-05 + 2.821728163504e-07*pi2b))*pi2b) + o[6]*(1.1385952129658 + pi2b*(-0.47128737436186 + o[1]*(0.0013555504554949 + (1.4052392818316e-05 + 1.2704902271945e-06*pi2b)*pi2b)) + o[5]*(-0.47811863648625 + (0.15020273139707 + o[2]*(-3.1083814331434e-05 + o[1]*(-1.1030139238909e-08 - 2.5180545682962e-11*pi2b)))*pi2b + o[5]*o[7]*(0.0085208123431544 + pi2b*(-0.002176411421975 + pi2b*(7.1280351959551e-05 + o[1]*(-1.0302738212103e-06 + (7.3803353468292e-08 + 8.6934156344163e-15*o[3])*pi2b))))))))))));
            else
              eta2c:=eta - 1.8;
              pi2c:=pi + 25.0;
              o[1]:=pi2c*pi2c;
              o[2]:=o[1]*o[1];
              o[3]:=o[1]*o[2]*pi2c;
              o[4]:=1/o[3];
              o[5]:=o[1]*o[2];
              o[6]:=eta2c*eta2c;
              o[7]:=o[2]*o[2];
              o[8]:=o[6]*o[6];
              T:=eta2c*((859777.2253558 + o[1]*(482.19755109255 + 1.126159740723e-12*o[5]))/o[1] + eta2c*((-583401318515.9 + (20825544563.171 + 31081.088422714*o[2])*pi2c)/o[5] + o[6]*(o[8]*(o[6]*(1.2324579690832e-07*o[5] + o[6]*(-1.1606921130984e-06*o[5] + o[8]*(2.7846367088554e-05*o[5] + (-0.00059270038474176*o[5] + 0.0012918582991878*o[5]*o[6])*o[8]))) - 10.842984880077*pi2c) + o[4]*(7326335090218.1 + o[7]*(3.7966001272486 + (-0.04536417267666 - 1.7804982240686e-11*o[2])*pi2c))))) + o[4]*(-3236839855524.2 + pi2c*(358250899454.47 + pi2c*(-10783068217.47 + o[1]*pi2c*(610747.83564516 + pi2c*(-25745.72360417 + (1208.2315865936 + 1.4559115658698e-13*o[5])*pi2c)))));
            end if;
          end tph2;

          function tsat
          "region 4 saturation temperature as a function of pressure"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.Temperature t_sat "temperature";
        protected
            Real pi "dimensionless pressure";
            Real[20] o "vector of auxiliary variables";
          algorithm
            pi:=max(min(p, data.PCRIT), triple.ptriple)*data.IPSTAR;
            o[1]:=pi^0.25;
            o[2]:=-3232555.0322333*o[1];
            o[3]:=pi^0.5;
            o[4]:=-724213.16703206*o[3];
            o[5]:=405113.40542057 + o[2] + o[4];
            o[6]:=-17.073846940092*o[1];
            o[7]:=14.91510861353 + o[3] + o[6];
            o[8]:=-4.0*o[5]*o[7];
            o[9]:=12020.82470247*o[1];
            o[10]:=1167.0521452767*o[3];
            o[11]:=-4823.2657361591 + o[10] + o[9];
            o[12]:=o[11]*o[11];
            o[13]:=o[12] + o[8];
            o[14]:=o[13]^0.5;
            o[15]:=-o[14];
            o[16]:=-12020.82470247*o[1];
            o[17]:=-1167.0521452767*o[3];
            o[18]:=4823.2657361591 + o[15] + o[16] + o[17];
            o[19]:=1/o[18];
            o[20]:=2.0*o[19]*o[5];
            t_sat:=0.5*(650.17534844798 + o[20] - (-4.0*(-0.23855557567849 + 1300.35069689596*o[19]*o[5]) + (650.17534844798 + o[20])^2.0)^0.5);
            annotation(derivative=tsat_der);
          end tsat;

          function dtsatofp
          "derivative of saturation temperature w.r.t. pressure"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Real dtsat(unit="K/Pa") "derivative of T w.r.t. p";
        protected
            Real pi "dimensionless pressure";
            Real[49] o "vector of auxiliary variables";
          algorithm
            pi:=p*data.IPSTAR;
            o[1]:=pi^0.75;
            o[2]:=1/o[1];
            o[3]:=-4.268461735023*o[2];
            o[4]:=sqrt(pi);
            o[5]:=1/o[4];
            o[6]:=0.5*o[5];
            o[7]:=o[3] + o[6];
            o[8]:=pi^0.25;
            o[9]:=-3232555.0322333*o[8];
            o[10]:=-724213.16703206*o[4];
            o[11]:=405113.40542057 + o[10] + o[9];
            o[12]:=-4*o[11]*o[7];
            o[13]:=-808138.758058325*o[2];
            o[14]:=-362106.58351603*o[5];
            o[15]:=o[13] + o[14];
            o[16]:=-17.073846940092*o[8];
            o[17]:=14.91510861353 + o[16] + o[4];
            o[18]:=-4*o[15]*o[17];
            o[19]:=3005.2061756175*o[2];
            o[20]:=583.52607263835*o[5];
            o[21]:=o[19] + o[20];
            o[22]:=12020.82470247*o[8];
            o[23]:=1167.0521452767*o[4];
            o[24]:=-4823.2657361591 + o[22] + o[23];
            o[25]:=2.0*o[21]*o[24];
            o[26]:=o[12] + o[18] + o[25];
            o[27]:=-4.0*o[11]*o[17];
            o[28]:=o[24]*o[24];
            o[29]:=o[27] + o[28];
            o[30]:=sqrt(o[29]);
            o[31]:=1/o[30];
            o[32]:=-o[30];
            o[33]:=-12020.82470247*o[8];
            o[34]:=-1167.0521452767*o[4];
            o[35]:=4823.2657361591 + o[32] + o[33] + o[34];
            o[36]:=o[30];
            o[37]:=-4823.2657361591 + o[22] + o[23] + o[36];
            o[38]:=o[37]*o[37];
            o[39]:=1/o[38];
            o[40]:=-1.72207339365771*o[30];
            o[41]:=21592.2055343628*o[8];
            o[42]:=o[30]*o[8];
            o[43]:=-8192.87114842946*o[4];
            o[44]:=-0.510632954559659*o[30]*o[4];
            o[45]:=-3100.02526152368*o[1];
            o[46]:=pi;
            o[47]:=1295.95640782102*o[46];
            o[48]:=2862.09212505088 + o[40] + o[41] + o[42] + o[43] + o[44] + o[45] + o[47];
            o[49]:=1/(o[35]*o[35]);
            dtsat:=data.IPSTAR*0.5*(2.0*o[15]/o[35] - 2.0*o[11]*(-3005.2061756175*o[2] - 0.5*o[26]*o[31] - 583.52607263835*o[5])*o[49] - 20953.4635664399*(o[39]*(1295.95640782102 + 5398.05138359071*o[2] + 0.25*o[2]*o[30] - 0.861036696828853*o[26]*o[31] - 0.255316477279829*o[26]*o[31]*o[4] - 4096.43557421473*o[5] - 0.255316477279829*o[30]*o[5] - 2325.01894614276/o[8] + 0.5*o[26]*o[31]*o[8]) - 2.0*(o[19] + o[20] + 0.5*o[26]*o[31])*o[48]*o[37]^(-3))/sqrt(o[39]*o[48]));
          end dtsatofp;

          function tsat_der "derivative function for tsat"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Real der_p(unit="Pa/s") "pressure derivatrive";
            output Real der_tsat(unit="K/s") "temperature derivative";
        protected
            Real dtp;
          algorithm
            dtp:=dtsatofp(p);
            der_tsat:=dtp*der_p;
          end tsat_der;

          function psat
          "region 4 saturation pressure as a functionx of temperature"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Modelica.SIunits.Pressure p_sat "pressure";
        protected
            Real[7] o "vector of auxiliary variables";
            Real C "auxiliary variable";
            Real B "auxiliary variable";
            Real A "auxiliary variable";
            Real Tlim=min(T, data.TCRIT);
          algorithm
            assert(T >= 273.16, "IF97 medium function psat: input temperature (= " + String(triple.ptriple) + " K).\n" + "lower than the triple point temperature 273.16 K");
            o[1]:=-650.17534844798 + Tlim;
            o[2]:=1/o[1];
            o[3]:=-0.23855557567849*o[2];
            o[4]:=o[3] + Tlim "theta";
            o[5]:=-4823.2657361591*o[4] "n7*theta";
            o[6]:=o[4]*o[4] "theta^2";
            o[7]:=14.91510861353*o[6] "n6*theta^2";
            C:=405113.40542057 + o[5] + o[7] "C";
            B:=-3232555.0322333 + 12020.82470247*o[4] - 17.073846940092*o[6];
            A:=-724213.16703206 + 1167.0521452767*o[4] + o[6];
            p_sat:=16000000.0*C*C*C*C*1/(-B + (-4.0*A*C + B*B)^0.5)^4.0;
            annotation(derivative=psat_der);
          end psat;

          function dptofT
          "derivative of pressure wrt temperature along the saturation pressure curve"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Real dpt(unit="Pa/K") "temperature derivative of pressure";
        protected
            Real[31] o "vector of auxiliary variables";
            Real Tlim "temperature limited to TCRIT";
          algorithm
            Tlim:=min(T, data.TCRIT);
            o[1]:=-650.17534844798 + Tlim;
            o[2]:=1/o[1];
            o[3]:=-0.23855557567849*o[2];
            o[4]:=o[3] + Tlim "theta";
            o[5]:=-4823.2657361591*o[4];
            o[6]:=o[4]*o[4] "theta^2";
            o[7]:=14.91510861353*o[6];
            o[8]:=405113.40542057 + o[5] + o[7];
            o[9]:=o[8]*o[8];
            o[10]:=o[9]*o[9];
            o[11]:=o[1]*o[1];
            o[12]:=1/o[11];
            o[13]:=0.23855557567849*o[12];
            o[14]:=1.0 + o[13] "dtheta";
            o[15]:=12020.82470247*o[4];
            o[16]:=-17.073846940092*o[6];
            o[17]:=-3232555.0322333 + o[15] + o[16];
            o[18]:=-4823.2657361591*o[14];
            o[19]:=29.83021722706*o[14]*o[4];
            o[20]:=o[18] + o[19];
            o[21]:=1167.0521452767*o[4];
            o[22]:=-724213.16703206 + o[21] + o[6];
            o[23]:=o[17]*o[17];
            o[24]:=-4.0*o[22]*o[8];
            o[25]:=o[23] + o[24];
            o[26]:=sqrt(o[25]);
            o[27]:=-12020.82470247*o[4];
            o[28]:=17.073846940092*o[6];
            o[29]:=3232555.0322333 + o[26] + o[27] + o[28];
            o[30]:=o[29]*o[29];
            o[31]:=o[30]*o[30];
            dpt:=1000000.0*((-64.0*o[10]*(-12020.82470247*o[14] + 34.147693880184*o[14]*o[4] + 0.5*(-4.0*o[20]*o[22] + 2.0*o[17]*(12020.82470247*o[14] - 34.147693880184*o[14]*o[4]) - 4.0*(1167.0521452767*o[14] + 2.0*o[14]*o[4])*o[8])/o[26]))/(o[29]*o[31]) + 64.0*o[20]*o[8]*o[9]/o[31]);
          end dptofT;

          function d2ptofT
          "Second derivative of pressure wrt temperature along the saturation pressure curve"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Real dpT(unit="Pa/K") "Temperature derivative of pressure";
            output Real dpTT(unit="Pa/(K.K)")
            "Second temperature derivative of pressure";
        protected
            Real A "Auxiliary variable";
            Real Ad "Auxiliary variable";
            Real A1 "Auxiliary variable";
            Real A2 "Auxiliary variable";
            Real B "Auxiliary variable";
            Real Bd "Auxiliary variable";
            Real B1 "Auxiliary variable";
            Real B2 "Auxiliary variable";
            Real C "Auxiliary variable";
            Real Cd "Auxiliary variable";
            Real C1 "Auxiliary variable";
            Real C2 "Auxiliary variable";
            Real D "Auxiliary variable";
            Real D1 "Auxiliary variable";
            Real Dd "Auxiliary variable";
            Real D2 "Auxiliary variable";
            Real th "Auxiliary variable";
            Real thd "Auxiliary variable";
            Real thdd "Auxiliary variable";
            Real v "Auxiliary variable";
            Real v2 "Auxiliary variable";
            Real v4 "Auxiliary variable";
            Real v5 "Auxiliary variable";
            Real v6 "Auxiliary variable";
            Real[16] o "vector of auxiliary variables";
            Real Tlim "temperature limited to TCRIT";
            parameter Real[10] n={1167.0521452767,-724213.16703206,-17.073846940092,12020.82470247,-3232555.0322333,14.91510861353,-4823.2657361591,405113.40542057,-0.23855557567849,650.17534844798};
          algorithm
            Tlim:=min(T, data.TCRIT);
            o[1]:=Tlim - n[10];
            th:=Tlim + n[9]/o[1];
            o[2]:=th*th "theta^2";
            A:=o[2] + n[1]*th + n[2];
            B:=n[3]*o[2] + n[4]*th + n[5];
            C:=n[6]*o[2] + n[7]*th + n[8];
            o[3]:=o[1]*o[1];
            o[4]:=o[3]*o[3];
            D:=B*B - 4.0*A*C;
            o[5]:=sqrt(D);
            v:=1/(o[5] - B);
            v2:=v*v;
            v4:=v2*v2;
            v5:=v4*v;
            v6:=v4*v2;
            o[6]:=2.0*C*v;
            o[7]:=o[6]*o[6];
            thd:=1.0 - n[9]/o[3];
            thdd:=2.0*n[9]/(o[3]*o[1]);
            Ad:=2.0*th + n[1];
            Bd:=2.0*n[3]*th + n[4];
            Cd:=2.0*n[6]*th + n[7];
            Dd:=2*B*Bd - 4*(Ad*C + Cd*A);
            A1:=Ad*thd;
            B1:=Bd*thd;
            C1:=Cd*thd;
            D1:=Dd*thd;
            o[8]:=C*C "C^2";
            o[9]:=o[8]*C "C^3";
            o[10]:=o[9]*C "C^4";
            o[11]:=1/o[5] "1/sqrt(D)";
            o[12]:=-B1 + 0.5*D1*o[11] "-B1 + 1/2*D1/sqrt(D)";
            o[13]:=o[12]*o[12];
            o[14]:=C1*C1 "C1^2";
            o[15]:=B1*B1 "B1^2";
            o[16]:=D*o[5] "D^3/2";
            dpT:=64.0*(C1*o[9]*v4 - o[10]*o[12]*v5)*1000000.0 "dpsat";
            A2:=Ad*thdd + thd*thd*2.0;
            B2:=Bd*thdd + thd*thd*2.0*n[3];
            C2:=Cd*thdd + thd*thd*2.0*n[6];
            D2:=2.0*(B*B2 + o[15]) - 4.0*(A2*C + 2.0*A1*C1 + A*C2);
            dpTT:=((192.0*o[8]*o[14] + 64.0*o[9]*C2)*v4 + (-512.0*C1*o[9]*o[12] - 64.0*o[10]*(-B2 - 0.25*D1*D1/o[16] + 0.5*D2*o[11]))*v5 + 320.0*o[10]*o[13]*v6)*1000000.0;
          end d2ptofT;

          function psat_der "derivative function for psat"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature T "temperature (K)";
            input Real der_T(unit="K/s") "temperature derivative";
            output Real der_psat(unit="Pa/s") "pressure";
        protected
            Real dpt;
          algorithm
            dpt:=dptofT(T);
            der_psat:=dpt*der_T;
          end psat_der;

          function h3ab_p "ergion 3 a b boundary for pressure/enthalpy"
            extends Modelica.Icons.Function;
            output Modelica.SIunits.SpecificEnthalpy h "Enthalpy";
            input Modelica.SIunits.Pressure p "Pressure";
        protected
            constant Real[:] n={2014.64004206875,3.74696550136983,-0.0219921901054187,8.7513168600995e-05};
            constant Modelica.SIunits.SpecificEnthalpy hstar=1000
            "normalization enthalpy";
            constant Modelica.SIunits.Pressure pstar=1000000.0
            "normalization pressure";
            Real pi=p/pstar "normalized specific pressure";
          algorithm
            h:=(n[1] + n[2]*pi + n[3]*pi^2 + n[4]*pi^3)*hstar;
            annotation(Documentation(info="<html>
      <p>
      &nbsp;Equation number 1 from:<br>
      <div style=\"text-align: center;\">&nbsp;[1] The international Association
      for the Properties of Water and Steam<br>
      &nbsp;Vejle, Denmark<br>
      &nbsp;August 2003<br>
      &nbsp;Supplementary Release on Backward Equations for the Fucnctions
      T(p,h), v(p,h) and T(p,s), <br>
      &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
      the Thermodynamic Properties of<br>
      &nbsp;Water and Steam</div>
      </p>
      </html>"));
          end h3ab_p;

          function T3a_ph "Region 3 a: inverse function T(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "Pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            output Modelica.SIunits.Temp_K T "Temperature";
        protected
            constant Real[:] n={-1.33645667811215e-07,4.55912656802978e-06,-1.46294640700979e-05,0.0063934131297008,372.783927268847,-7186.54377460447,573494.7521034,-2675693.29111439,-3.34066283302614e-05,-0.0245479214069597,47.8087847764996,7.64664131818904e-06,0.00128350627676972,0.0171219081377331,-8.51007304583213,-0.0136513461629781,-3.84460997596657e-06,0.00337423807911655,-0.551624873066791,0.72920227710747,-0.00992522757376041,-0.119308831407288,0.793929190615421,0.454270731799386,0.20999859125991,-0.00642109823904738,-0.023515586860454,0.00252233108341612,-0.00764885133368119,0.0136176427574291,-0.0133027883575669};
            constant Real[:] I={-12,-12,-12,-12,-12,-12,-12,-12,-10,-10,-10,-8,-8,-8,-8,-5,-3,-2,-2,-2,-1,-1,0,0,1,3,3,4,4,10,12};
            constant Real[:] J={0,1,2,6,14,16,20,22,1,5,12,0,2,4,10,2,0,1,3,4,0,2,0,1,1,0,1,0,3,4,5};
            constant Modelica.SIunits.SpecificEnthalpy hstar=2300000.0
            "normalization enthalpy";
            constant Modelica.SIunits.Pressure pstar=100000000.0
            "normalization pressure";
            constant Modelica.SIunits.Temp_K Tstar=760
            "normalization temperature";
            Real pi=p/pstar "normalized specific pressure";
            Real eta=h/hstar "normalized specific enthalpy";
          algorithm
            T:=sum(n[i]*(pi + 0.24)^I[i]*(eta - 0.615)^J[i] for i in 1:31)*Tstar;
            annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 2 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
          end T3a_ph;

          function T3b_ph "Region 3 b: inverse function T(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "Pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            output Modelica.SIunits.Temp_K T "Temperature";
        protected
            constant Real[:] n={3.2325457364492e-05,-0.000127575556587181,-0.000475851877356068,0.00156183014181602,0.105724860113781,-85.8514221132534,724.140095480911,0.00296475810273257,-0.00592721983365988,-0.0126305422818666,-0.115716196364853,84.9000969739595,-0.0108602260086615,0.0154304475328851,0.0750455441524466,0.0252520973612982,-0.0602507901232996,-3.07622221350501,-0.0574011959864879,5.03471360939849,-0.925081888584834,3.91733882917546,-77.314600713019,9493.08762098587,-1410437.19679409,8491662.30819026,0.861095729446704,0.32334644281172,0.873281936020439,-0.436653048526683,0.286596714529479,-0.131778331276228,0.00676682064330275};
            constant Real[:] I={-12,-12,-10,-10,-10,-10,-10,-8,-8,-8,-8,-8,-6,-6,-6,-4,-4,-3,-2,-2,-1,-1,-1,-1,-1,-1,0,0,1,3,5,6,8};
            constant Real[:] J={0,1,0,1,5,10,12,0,1,2,4,10,0,1,2,0,1,5,0,4,2,4,6,10,14,16,0,2,1,1,1,1,1};
            constant Modelica.SIunits.Temp_K Tstar=860
            "normalization temperature";
            constant Modelica.SIunits.Pressure pstar=100000000.0
            "normalization pressure";
            constant Modelica.SIunits.SpecificEnthalpy hstar=2800000.0
            "normalization enthalpy";
            Real pi=p/pstar "normalized specific pressure";
            Real eta=h/hstar "normalized specific enthalpy";
          algorithm
            T:=sum(n[i]*(pi + 0.298)^I[i]*(eta - 0.72)^J[i] for i in 1:33)*Tstar;
            annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 3 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
          end T3b_ph;

          function v3a_ph "Region 3 a: inverse function v(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "Pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            output Modelica.SIunits.SpecificVolume v "specific volume";
        protected
            constant Real[:] n={0.00529944062966028,-0.170099690234461,11.1323814312927,-2178.98123145125,-0.000506061827980875,0.556495239685324,-9.43672726094016,-0.297856807561527,93.9353943717186,0.0192944939465981,0.421740664704763,-3689141.2628233,-0.00737566847600639,-0.354753242424366,-1.99768169338727,1.15456297059049,5683.6687581596,0.00808169540124668,0.172416341519307,1.04270175292927,-0.297691372792847,0.560394465163593,0.275234661176914,-0.148347894866012,-0.0651142513478515,-2.92468715386302,0.0664876096952665,3.52335014263844,-0.0146340792313332,-2.24503486668184,1.10533464706142,-0.0408757344495612};
            constant Real[:] I={-12,-12,-12,-12,-10,-10,-10,-8,-8,-6,-6,-6,-4,-4,-3,-2,-2,-1,-1,-1,-1,0,0,1,1,1,2,2,3,4,5,8};
            constant Real[:] J={6,8,12,18,4,7,10,5,12,3,4,22,2,3,7,3,16,0,1,2,3,0,1,0,1,2,0,2,0,2,2,2};
            constant Modelica.SIunits.Volume vstar=0.0028
            "normalization temperature";
            constant Modelica.SIunits.Pressure pstar=100000000.0
            "normalization pressure";
            constant Modelica.SIunits.SpecificEnthalpy hstar=2100000.0
            "normalization enthalpy";
            Real pi=p/pstar "normalized specific pressure";
            Real eta=h/hstar "normalized specific enthalpy";
          algorithm
            v:=sum(n[i]*(pi + 0.128)^I[i]*(eta - 0.727)^J[i] for i in 1:32)*vstar;
            annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 4 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
          end v3a_ph;

          function v3b_ph "Region 3 b: inverse function v(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "Pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            output Modelica.SIunits.SpecificVolume v "specific volume";
        protected
            constant Real[:] n={-2.25196934336318e-09,1.40674363313486e-08,2.3378408528056e-06,-3.31833715229001e-05,0.00107956778514318,-0.271382067378863,1.07202262490333,-0.853821329075382,-2.15214194340526e-05,0.00076965608822273,-0.00431136580433864,0.453342167309331,-0.507749535873652,-100.475154528389,-0.219201924648793,-3.21087965668917,607.567815637771,0.000557686450685932,0.18749904002955,0.00905368030448107,0.285417173048685,0.0329924030996098,0.239897419685483,4.82754995951394,-11.8035753702231,0.169490044091791,-0.0179967222507787,0.0371810116332674,-0.0536288335065096,1.6069710109252};
            constant Real[:] I={-12,-12,-8,-8,-8,-8,-8,-8,-6,-6,-6,-6,-6,-6,-4,-4,-4,-3,-3,-2,-2,-1,-1,-1,-1,0,1,1,2,2};
            constant Real[:] J={0,1,0,1,3,6,7,8,0,1,2,5,6,10,3,6,10,0,2,1,2,0,1,4,5,0,0,1,2,6};
            constant Modelica.SIunits.Volume vstar=0.0088
            "normalization temperature";
            constant Modelica.SIunits.Pressure pstar=100000000.0
            "normalization pressure";
            constant Modelica.SIunits.SpecificEnthalpy hstar=2800000.0
            "normalization enthalpy";
            Real pi=p/pstar "normalized specific pressure";
            Real eta=h/hstar "normalized specific enthalpy";
          algorithm
            v:=sum(n[i]*(pi + 0.0661)^I[i]*(eta - 0.72)^J[i] for i in 1:30)*vstar;
            annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 5 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
          end v3b_ph;

          function g1L3
          "base function for region 1 with 3rd derivatives for sensitivities: g(p,T)"
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g
            "dimensionless Gibbs function and derivatives up to 3rd derivatives";
        protected
            Real pi1;
            Real tau1;
            Real[55] o;
          algorithm
            assert(p > ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple, "IF97 medium function g1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple) + " Pa (triple point pressure)");
            assert(p <= 100000000.0, "IF97 medium function g1: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
            assert(T >= 273.15, "IF97 medium function g1: the temperature (= " + String(T) + " K)  is lower than 273.15 K!");
            g.p:=p;
            g.T:=T;
            g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            g.pi:=p/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PSTAR1;
            g.tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TSTAR1/T;
            pi1:=7.1 - g.pi;
            tau1:=-1.222 + g.tau;
            o[1]:=tau1*tau1;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            o[4]:=o[3]*tau1;
            o[5]:=1/o[4];
            o[6]:=o[1]*o[2];
            o[7]:=o[1]*tau1;
            o[8]:=1/o[7];
            o[9]:=o[1]*o[2]*o[3];
            o[10]:=1/o[2];
            o[11]:=o[2]*tau1;
            o[12]:=1/o[11];
            o[13]:=o[2]*o[3];
            o[14]:=1/o[3];
            o[15]:=pi1*pi1;
            o[16]:=o[15]*pi1;
            o[17]:=o[15]*o[15];
            o[18]:=o[17]*o[17];
            o[19]:=o[17]*o[18]*pi1;
            o[20]:=o[15]*o[17];
            o[21]:=o[3]*o[3];
            o[22]:=o[21]*o[21];
            o[23]:=o[22]*o[3]*tau1;
            o[24]:=1/o[23];
            o[25]:=o[22]*o[3];
            o[26]:=1/o[25];
            o[27]:=o[1]*o[2]*o[22]*tau1;
            o[28]:=1/o[27];
            o[29]:=o[1]*o[2]*o[22];
            o[30]:=1/o[29];
            o[31]:=o[1]*o[2]*o[21]*o[3]*tau1;
            o[32]:=1/o[31];
            o[33]:=o[2]*o[21]*o[3]*tau1;
            o[34]:=1/o[33];
            o[35]:=o[1]*o[3]*tau1;
            o[36]:=1/o[35];
            o[37]:=5.85475673349302e-08*o[11];
            o[38]:=o[1]*o[3];
            o[39]:=1/o[38];
            o[40]:=1/o[6];
            o[41]:=o[1]*o[22]*o[3];
            o[42]:=1/o[41];
            o[43]:=1/o[22];
            o[44]:=o[1]*o[2]*o[21]*o[3];
            o[45]:=1/o[44];
            o[46]:=1/o[13];
            o[47]:=-0.00031703014781958*o[2];
            o[48]:=o[1]*o[2]*tau1;
            o[49]:=1/o[48];
            o[50]:=o[1]*o[22]*o[3]*tau1;
            o[51]:=1/o[50];
            o[52]:=o[22]*tau1;
            o[53]:=1/o[52];
            o[54]:=o[2]*o[3]*tau1;
            o[55]:=1/o[54];
            g.g:=pi1*(pi1*(pi1*(o[10]*(-3.1679644845054e-05 + o[2]*(-2.8270797985312e-06 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.2425281908e-06 + (-6.5171222895601e-07 - 1.4341729937924e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-07*o[14] + o[16]*((-1.2734301741641e-09 - 1.7424871230634e-10*o[11])*o[36] + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.4478307828521e-20*o[32] + o[20]*(2.6335781662795e-23*o[30] + pi1*(-1.1947622640071e-23*o[28] + pi1*(1.8228094581404e-24*o[26] - 9.3537087292458e-26*o[24]*pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.00030001780793026 + (4.7661393906987e-05 + o[1]*(-4.4141845330846e-06 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.00028319080123804 + o[1]*(-0.00060706301565874 + o[6]*(-0.018990068218419 + tau1*(-0.032529748770505 + (-0.021841717175414 - 5.283835796993e-05*o[1])*tau1))))) + (0.14632971213167 + tau1*(-0.84548187169114 + tau1*(-3.756360367204 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.15772038513228 + (-0.016616417199501 + 0.00081214629983568*tau1)*tau1))))))/o[1];
            g.gpi:=pi1*(pi1*(o[10]*(9.5038934535162e-05 + o[2]*(8.4812393955936e-06 + 2.55615384360309e-09*o[6])) + pi1*(o[12]*(8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[13])*o[7]) + pi1*(2.02584984300585e-06*o[14] + o[16]*((1.01874413933128e-08 + 1.39398969845072e-09*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[34] + o[15]*(-3.33001080055983e-19*o[32] + o[20]*(-7.63737668221055e-22*o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.65070932023524e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(0.00094368642146534 + o[7]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[9]))*tau1))) + o[5]*(-0.00028319080123804 + o[1]*(0.00060706301565874 + o[6]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))));
            g.gpipi:=pi1*(o[10]*(-0.000190077869070324 + o[2]*(-1.69624787911872e-05 - 5.11230768720618e-09*o[6])) + pi1*(o[12]*(-2.69103382896e-05 + (-7.82054674747212e-06 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-06*o[14] + o[16]*((-7.13120897531896e-08 - 9.75792788915504e-09*o[11])*o[36] + o[19]*(-2.8880095144123e-16*o[34] + o[15]*(7.32602376123163e-18*o[32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*o[28] + pi1*(1.69521279607057e-21*o[26] - 9.27887905941183e-23*o[24]*pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052 + (9.5322787813974e-05 + o[1]*(-8.8283690661692e-06 - 1.45389992595188e-15*o[9]))*tau1));
            g.gpipipi:=o[10]*(0.000190077869070324 + o[2]*(1.69624787911872e-05 + 5.11230768720618e-09*o[6])) + pi1*(o[12]*(5.38206765792e-05 + (1.56410934949442e-05 + 3.44201518510176e-12*o[13])*o[7]) + pi1*(2.43101981160702e-05*o[14] + o[16]*(o[36]*(4.27872538519138e-07 + o[37]) + o[19]*(5.48721807738337e-15*o[34] + o[15]*(-1.53846498985864e-16*o[32] + o[20]*(-5.77385677175118e-19*o[30] + pi1*(2.9104408751213e-19*o[28] + pi1*(-4.91611710860466e-20*o[26] + 2.78366371782355e-21*o[24]*pi1))))))));
            g.gtau:=pi1*(o[39]*(-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.11230768720618e-09*o[38]) + pi1*(o[40]*(1.1212640954e-05 + (1.30342445791202e-06 - 1.4341729937924e-12*o[13])*o[7]) + pi1*(3.24135974880936e-06*o[5] + o[16]*((1.40077319158051e-08 + 1.04549227383804e-09*o[11])*o[46] + o[19]*(1.9941018075704e-17*o[45] + o[15]*(-4.48827542684151e-19*o[43] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.65957282962769e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.83502057899078e-24*o[42]*pi1))))))))))) + o[8]*(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
            g.gtautau:=pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.0339955288768894 + (-0.037980136436838 + o[47])*o[6])) + pi1*(o[12]*(-0.00566211852879204 + o[6]*(-2.64851071985076e-05 - 1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 - 2.55615384360309e-08*o[38])*o[40] + pi1*(o[49]*(-6.7275845724e-05 + (-3.91027337373606e-06 - 1.29075569441316e-11*o[13])*o[7]) + pi1*(-2.91722377392842e-05*o[39] + o[16]*((-1.68092782989661e-07 - 7.31844591686628e-09*o[11])*o[55] + o[19]*(-5.9823054227112e-16*o[32] + o[15]*(1.43624813658928e-17*o[53] + o[20]*(3.90296284242622e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(2.98940751135026e-21*o[42] - 1.61070864317613e-22*o[51]*pi1))))))))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]*(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 + 0.0162429259967136*tau1)*tau1))));
            g.gtautautau:=pi1*(o[46]*(-0.28035889322566 + o[1]*(0.305959759892005 + (0.113940409310514 + o[47])*o[6])) + pi1*(o[40]*(0.0283105926439602 + o[6]*(-2.64851071985076e-05 - 2.96595584894183e-12*o[9])) + pi1*((0.00380155738140648 - 1.02246153744124e-07*o[38])*o[49] + pi1*(o[14]*(0.000470930920068 + (1.56410934949442e-05 - 1.03260455553053e-10*o[13])*o[7]) + pi1*(0.000291722377392842*o[36] + o[16]*((2.1852061788656e-06 + o[37])/o[9] + o[19]*(1.85451468104047e-14*o[43] + o[15]*(-4.73961885074464e-16/(o[1]*o[22]) + o[20]*(-1.56118513697049e-18*o[24] + pi1*(7.64169944058941e-19*o[42] + pi1*(-1.25555115476711e-19*o[51] + 6.92604716565734e-21*pi1/(o[2]*o[22]*o[3])))))))))))) + o[12]*(-3.51191309116008 + tau1*(5.07289123014684 + o[2]*(0.94632231079368 + (-0.398794012788024 + 0.0487287779901408*tau1)*tau1)));
            g.gpitau:=o[39]*(0.00254871721114236 + o[1]*(-0.00424944110961118 + (-0.018990068218419 + (0.021841717175414 + 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(-0.00283105926439602 + o[2]*(-9.5322787813974e-05 + o[1]*(2.64851071985076e-05 + 2.4716298741182e-14*o[9]))) + pi1*(o[12]*(-0.000380155738140648 + 1.53369230616185e-08*o[38]) + pi1*(o[40]*(-4.4850563816e-05 + (-5.21369783164808e-06 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-1.62067987440468e-05*o[5] + o[16]*((-1.12061855326441e-07 - 8.36393819070432e-09*o[11])*o[46] + o[19]*(-4.18761379589784e-16*o[45] + o[15]*(1.03230334817355e-17*o[43] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*o[26] + pi1*(2.2602837280941e-21*o[24] - 1.22720658527705e-22*o[42]*pi1))))))))));
            g.gpipitau:=o[10]*(0.00283105926439602 + o[2]*(9.5322787813974e-05 + o[1]*(-2.64851071985076e-05 - 2.4716298741182e-14*o[9]))) + pi1*(o[12]*(0.000760311476281296 - 3.06738461232371e-08*o[38]) + pi1*(o[40]*(0.000134551691448 + (1.56410934949442e-05 - 1.72100759255088e-11*o[13])*o[7]) + pi1*(6.48271949761872e-05*o[5] + o[16]*((7.84432987285086e-07 + o[37])*o[46] + o[19]*(8.37522759179568e-15*o[45] + o[15]*(-2.2710673659818e-16*o[43] + o[20]*(-8.12616878987203e-19*o[28] + pi1*(4.05382836177609e-19*o[26] + pi1*(-6.78085118428229e-20*o[24] + 3.80434041435885e-21*o[42]*pi1)))))))));
            g.gpitautau:=o[36]*(-0.0254871721114236 + o[1]*(0.0339955288768894 + (0.037980136436838 + 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]*(0.0113242370575841 + o[6]*(5.29702143970152e-05 + 3.95460779858911e-13*o[9])) + pi1*((0.00190077869070324 + 7.66846153080927e-08*o[38])*o[40] + pi1*(o[49]*(0.000269103382896 + (1.56410934949442e-05 + 5.16302277765264e-11*o[13])*o[7]) + pi1*(0.000145861188696421*o[39] + o[16]*((1.34474226391729e-06 + o[37])*o[55] + o[19]*(1.25628413876935e-14*o[32] + o[15]*(-3.30337071415535e-16*o[53] + o[20]*(-1.1318592243036e-18*o[26] + pi1*(5.59148739555323e-19*o[24] + pi1*(-9.26716328518579e-20*o[42] + 5.1542676581636e-21*o[51]*pi1))))))))));
          end g1L3;

          function g2L3
          "base function for region 2 with 3rd derivatives for sensitivities: g(p,T)"
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g
            "dimensionless Gibbs function and derivatives up to 3rd derivatives";
        protected
            Real pi2;
            Real tau2;
            Real[82] o;
          algorithm
            assert(p > ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple, "IF97 medium function g2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple) + " Pa (triple point pressure)");
            assert(p <= 100000000.0, "IF97 medium function g2: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
            assert(T >= 273.15, "IF97 medium function g2: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
            assert(T <= 1073.15, "IF97 medium function g2: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
            g.p:=p;
            g.T:=T;
            g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            g.pi:=p/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PSTAR2;
            g.tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TSTAR2/T;
            tau2:=-0.5 + g.tau;
            o[1]:=tau2*tau2;
            o[2]:=o[1]*tau2;
            o[3]:=-0.05032527872793*o[2];
            o[4]:=-0.057581259083432 + o[3];
            o[5]:=o[4]*tau2;
            o[6]:=-0.045996013696365 + o[5];
            o[7]:=o[6]*tau2;
            o[8]:=-0.017834862292358 + o[7];
            o[9]:=o[8]*tau2;
            o[10]:=o[1]*o[1];
            o[11]:=o[10]*o[10];
            o[12]:=o[11]*o[11];
            o[13]:=o[10]*o[11]*o[12]*tau2;
            o[14]:=o[1]*o[10]*tau2;
            o[15]:=o[10]*o[11]*tau2;
            o[16]:=o[1]*o[12]*tau2;
            o[17]:=o[1]*o[11]*tau2;
            o[18]:=o[1]*o[10]*o[11];
            o[19]:=o[10]*o[11]*o[12];
            o[20]:=o[1]*o[10];
            o[21]:=g.pi*g.pi;
            o[22]:=o[21]*o[21];
            o[23]:=o[21]*o[22];
            o[24]:=o[10]*o[12]*tau2;
            o[25]:=o[12]*o[12];
            o[26]:=o[11]*o[12]*o[25]*tau2;
            o[27]:=o[10]*o[12];
            o[28]:=o[1]*o[10]*o[11]*tau2;
            o[29]:=o[10]*o[12]*o[25]*tau2;
            o[30]:=o[1]*o[10]*o[25]*tau2;
            o[31]:=o[1]*o[11]*o[12];
            o[32]:=o[1]*o[12];
            o[33]:=g.tau*g.tau;
            o[34]:=o[33]*o[33];
            o[35]:=-5.3349095828174e-05*o[13];
            o[36]:=-0.087594591301146 + o[35];
            o[37]:=o[2]*o[36];
            o[38]:=-0.007878555448671 + o[37];
            o[39]:=o[1]*o[38];
            o[40]:=-0.0003789797503263 + o[39];
            o[41]:=o[40]*tau2;
            o[42]:=-6.6065283340406e-05 + o[41];
            o[43]:=o[42]*tau2;
            o[44]:=-0.244009521375894*o[13];
            o[45]:=-0.0090203547252888 + o[44];
            o[46]:=o[2]*o[45];
            o[47]:=-0.00019366606343142 + o[46];
            o[48]:=o[1]*o[47];
            o[49]:=2.6322400370661e-06 + o[48];
            o[50]:=o[49]*tau2;
            o[51]:=5.78704472622084e-06*tau2;
            o[52]:=o[21]*g.pi;
            o[53]:=1.15740894524417e-05*tau2;
            o[54]:=-0.30195167236758*o[2];
            o[55]:=-0.172743777250296 + o[54];
            o[56]:=o[55]*tau2;
            o[57]:=-0.09199202739273 + o[56];
            o[58]:=o[57]*tau2;
            o[59]:=o[1]*o[11];
            o[60]:=o[10]*o[11];
            o[61]:=o[11]*o[12]*o[25];
            o[62]:=o[10]*o[12]*o[25];
            o[63]:=o[1]*o[10]*o[25];
            o[64]:=o[11]*o[12]*tau2;
            o[65]:=-1.5097583618379*o[2];
            o[66]:=-0.345487554500592 + o[65];
            o[67]:=o[66]*tau2;
            o[68]:=o[10]*tau2;
            o[69]:=o[11]*tau2;
            o[70]:=o[1]*o[11]*o[12]*tau2;
            o[71]:=o[1]*o[10]*o[12]*o[25]*tau2;
            o[72]:=o[1]*o[12]*o[25]*tau2;
            o[73]:=o[10]*o[25]*tau2;
            o[74]:=o[11]*o[12];
            o[75]:=o[34]*o[34];
            o[76]:=-0.00192056744981426*o[13];
            o[77]:=-0.613162139108022 + o[76];
            o[78]:=o[2]*o[77];
            o[79]:=-0.031514221794684 + o[78];
            o[80]:=o[1]*o[79];
            o[81]:=-0.0007579595006526 + o[80];
            o[82]:=o[81]*tau2;
            g.g:=g.pi*(-0.0017731742473213 + o[9] + g.pi*(tau2*(-3.3032641670203e-05 + (-0.00018948987516315 + o[1]*(-0.0039392777243355 + (-0.043797295650573 - 2.6674547914087e-05*o[13])*o[2]))*tau2) + g.pi*(2.0481737692309e-08 + (4.3870667284435e-07 + o[1]*(-3.227767723857e-05 + (-0.0015033924542148 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi*(g.pi*(2.2922076337661e-06*o[14] + g.pi*((-1.6714766451061e-11 + o[15]*(-0.0021171472321355 - 23.895741934104*o[16]))*o[2] + g.pi*(-5.905956432427e-18 + o[17]*(-1.2621808899101e-06 - 0.038946842435739*o[18]) + g.pi*(o[11]*(1.1256211360459e-11 - 8.2311340897998*o[19]) + g.pi*(1.9809712802088e-08*o[15] + g.pi*(o[10]*(1.0406965210174e-19 + (-1.0234747095929e-13 - 1.0018179379511e-09*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11 + 0.10693031879409*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*(o[27]*(8.9185845355421e-25 + (3.0629316876232e-13 - 4.2002467698208e-06*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24] + g.pi*(3.7826947613457e-06*o[29] + g.pi*(-1.2768608934681e-15*o[30] + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 - 9.436970724121e-07*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10 + (1.2790717852285e-08 + 4.8225372718507e-07*tau2)*tau2))))) + (-0.00560879118302 + g.tau*(0.07145273881455 + g.tau*(-0.4071049823928 + g.tau*(1.424081971444 + g.tau*(-4.38395111945 + g.tau*(-9.692768600217 + g.tau*(10.08665568018 + (-0.2840863260772 + 0.02126846353307*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);
            g.gpi:=(1.0 + g.pi*(-0.0017731742473213 + o[9] + g.pi*(o[43] + g.pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[1]*(-9.683303171571e-05 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi*(g.pi*(1.14610381688305e-05*o[14] + g.pi*((-1.00288598706366e-10 + o[15]*(-0.012702883392813 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17 + o[17]*(-8.8352662293707e-06 - 0.272627897050173*o[18]) + g.pi*(o[11]*(9.0049690883672e-11 - 65.8490727183984*o[19]) + g.pi*(1.78287415218792e-07*o[15] + g.pi*(o[10]*(1.0406965210174e-18 + (-1.0234747095929e-12 - 1.0018179379511e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-09 + 1.71088510070544*o[24]) + o[21]*(-6.05920510335078*o[26] + o[21]*(o[27]*(1.78371690710842e-23 + (6.1258633752464e-12 - 8.4004935396416e-05*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24] + g.pi*(8.32192847496054e-05*o[29] + g.pi*(-2.93678005497663e-14*o[30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 - 2.26487297378904e-05*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2))))))/g.pi;
            g.gpipi:=(-1.0 + o[21]*(o[43] + g.pi*(1.22890426153854e-07 + o[50] + g.pi*(g.pi*(4.5844152675322e-05*o[14] + g.pi*((-5.0144299353183e-10 + o[15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16 + o[17]*(-5.30115973762242e-05 - 1.63576738230104*o[18]) + g.pi*(o[11]*(6.30347836185704e-10 - 460.943509028789*o[19]) + g.pi*(1.42629932175034e-06*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12 - 9.0163614415599e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-08 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(o[27]*(3.389062123506e-22 + (1.16391404129682e-10 - 0.0015960937725319*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24] + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.46091612094859e-13*o[30] + o[31]*(4.03443610484737e-26 + o[18]*(3.05889228736295e-14 - 0.000520920783971479*o[32]))*g.pi)))))))))))) + tau2*(-9.46167714712404e-09 + (1.5348861422742e-07 + o[51])*tau2)))))/o[21];
            g.gpipipi:=(2.0 + o[52]*(1.22890426153854e-07 + o[50] + g.pi*(g.pi*(0.000137532458025966*o[14] + g.pi*((-2.00577197412732e-09 + o[15]*(-0.25405766785626 - 2867.48903209248*o[16]))*o[2] + g.pi*(-1.24025085080967e-15 + o[17]*(-0.000265057986881121 - 8.17883691150519*o[18]) + g.pi*(o[11]*(3.78208701711422e-09 - 2765.66105417273*o[19]) + g.pi*(9.98409525225235e-06*o[15] + g.pi*(o[10]*(7.49301495132528e-17 + (-7.36901790906888e-11 - 7.21308915324792e-07*o[10])*o[20]) + o[23]*(o[13]*(-2.7176657305387e-07 + 359.285871148142*o[24]) + o[21]*(-1648.10378811141*o[26] + o[21]*(o[27]*(6.1003118223108e-21 + (2.09504527433427e-09 - 0.0287296879055743*o[15])*o[28]) + g.pi*(-4.71267116891399e-22*o[24] + g.pi*(0.0349520995948343*o[29] + g.pi*(-1.3567923853992e-11*o[30] + o[31]*(8.87575943066421e-25 + o[18]*(6.72956303219848e-13 - 0.0114602572473725*o[32]))*g.pi)))))))))))) + tau2*(-1.89233542942481e-08 + (3.0697722845484e-07 + o[53])*tau2))))/o[52];
            g.gtau:=(0.0280439559151 + g.tau*(-0.2858109552582 + g.tau*(1.2213149471784 + g.tau*(-2.848163942888 + g.tau*(4.38395111945 + o[33]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*g.tau)*g.tau))))))/(o[33]*o[34]) + g.pi*(-0.017834862292358 + o[58] + g.pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[1]*(-0.015757110897342 + (-0.306581069554011 - 0.000960283724907132*o[13])*o[2]))*tau2 + g.pi*(4.3870667284435e-07 + o[1]*(-9.683303171571e-05 + (-0.0090203547252888 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*(1.60454534363627e-05*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-1.38839897890111e-05 - 0.973671060893475*o[18])*o[59] + g.pi*(o[14]*(9.0049690883672e-11 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-07*o[60] + g.pi*(o[2]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-09 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[61] + o[21]*(o[16]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27] + g.pi*(0.000200482822351322*o[62] + g.pi*(-4.97975748452559e-14*o[63] + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 - 5.47344301999018e-05*o[32]))*o[64]*g.pi)))))))))))) + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2))));
            g.gtautau:=(-0.1682637354906 + g.tau*(1.429054776291 + g.tau*(-4.8852597887136 + g.tau*(8.544491828664 + g.tau*(-8.7679022389 + o[33]*(-0.5681726521544 + 0.12761078119842*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.09199202739273 + o[67] + g.pi*(-0.0003789797503263 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.0336099303717496*o[13])*o[2]) + g.pi*((-0.00019366606343142 + (-0.045101773626444 - 48.3952217395523*o[13])*o[2])*tau2 + g.pi*(2.558143570457e-08 + 2.89352236311042e-06*tau2 + g.pi*(9.62727206181762e-05*o[68] + g.pi*(g.pi*((-0.000138839897890111 - 23.3681054614434*o[18])*o[69] + g.pi*((6.30347836185704e-10 - 10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-06*o[17] + g.pi*(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 - 1.823308647071e-07*o[10])*o[20]) + o[23]*((-6.56769218213518e-08 + 261.979281045521*o[24])*o[70] + o[21]*(-1074.49903832754*o[71] + o[21]*((3.389062123506e-22 + (3.64488870827161e-10 - 0.00947575671271573*o[15])*o[28])*o[32] + g.pi*(-2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[72] + g.pi*(-1.89230784411972e-12*o[73] + (4.75069468867897e-26 + o[18]*(8.64469559472137e-14 - 0.0031198625213944*o[32]))*o[74]*g.pi)))))))))) + (-1.00288598706366e-10 + o[15]*(-0.50811533571252 - 28435.9329015838*o[16]))*tau2))))));
            g.gtautautau:=(1.1778461484342 + g.tau*(-8.574328657746 + g.tau*(24.426298943568 + g.tau*(-34.177967314656 + (26.3037067167 + 0.12761078119842*o[34])*g.tau))))/o[75] + g.pi*(-0.345487554500592 - 6.0390334473516*o[2] + g.pi*((-0.094542665384052 + (-9.19743208662033 - 1.14273763263949*o[13])*o[2])*tau2 + g.pi*(-0.00019366606343142 + (-0.180407094505776 - 1597.04231740523*o[13])*o[2] + g.pi*(2.89352236311042e-06 + g.pi*(0.000481363603090881*o[10] + g.pi*(-1.00288598706366e-10 + o[15]*(-7.11361469997528 - 938385.785752264*o[16]) + g.pi*(o[11]*(-0.001249559081011 - 537.466425613198*o[18]) + g.pi*((3.78208701711422e-09 - 352621.784407023*o[19])*o[68] + g.pi*(3.3993467168383e-05*o[59] + g.pi*((2.49767165044176e-18 + (-7.36901790906888e-11 - 2.1879703764852e-06*o[10])*o[20])*tau2 + o[23]*((-1.7732768891765e-06 + 12575.005490185*o[24])*o[31] + o[21]*(-59097.4471080146*o[1]*o[10]*o[12]*o[25] + o[21]*(o[12]*(6.1003118223108e-21 + (1.20281327372963e-08 - 0.435884808784923*o[15])*o[28])*tau2 + g.pi*(-4.71267116891399e-22*o[32] + g.pi*(0.531680444875706*o[1]*o[12]*o[25] + g.pi*(-7.00153902324298e-11*o[10]*o[25] + o[1]*o[10]*o[12]*(1.14016672528295e-24 + o[18]*(3.28498432599412e-12 - 0.174712301198087*o[32]))*g.pi*tau2))))))))))))))));
            g.gpitau:=-0.017834862292358 + o[58] + g.pi*(-6.6065283340406e-05 + o[82] + g.pi*(1.31612001853305e-06 + o[1]*(-0.00029049909514713 + (-0.0270610641758664 - 4.27016662407815*o[13])*o[2]) + g.pi*(-3.15389238237468e-09 + g.pi*(8.02272671818135e-05*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]*(-0.203246134285008 - 5018.10580616184*o[16])) + g.pi*((-9.71879285230777e-05 - 6.81569742625432*o[18])*o[59] + g.pi*(o[14]*(7.20397527069376e-10 - 2370.56661786234*o[19]) + g.pi*(2.3177363978443e-06*o[60] + g.pi*(o[2]*(4.1627860840696e-18 + (-1.0234747095929e-11 - 1.40254511313154e-07*o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-08 + 85.544255035272*o[24]) + o[21]*(-345.374690890994*o[61] + o[21]*(o[16]*(3.56743381421684e-22 + (2.14405218133624e-10 - 0.00403223689902797*o[15])*o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(0.00441062209172909*o[62] + g.pi*(-1.14534422144089e-12*o[63] + (4.56066690113181e-26 + o[18]*(5.31981267367469e-14 - 0.00131362632479764*o[32]))*o[64]*g.pi)))))))))))) + (1.0232574281828e-07 + o[51])*tau2)));
            g.gpipitau:=-6.6065283340406e-05 + o[82] + g.pi*(2.6322400370661e-06 + o[1]*(-0.00058099819029426 + (-0.0541221283517328 - 8.54033324815629*o[13])*o[2]) + g.pi*(-9.46167714712404e-09 + g.pi*(0.000320909068727254*o[20] + g.pi*(o[1]*(-1.50432898059549e-09 + o[15]*(-1.01623067142504 - 25090.5290308092*o[16])) + g.pi*((-0.000583127571138466 - 40.8941845575259*o[18])*o[59] + g.pi*(o[14]*(5.04278268948563e-09 - 16593.9663250364*o[19]) + g.pi*(1.85418911827544e-05*o[60] + g.pi*(o[2]*(3.74650747566264e-17 + (-9.2112723863361e-11 - 1.26229060181839e-06*o[10])*o[20]) + o[23]*(o[19]*(-5.62945044183016e-07 + 1283.16382552908*o[24]) + o[21]*(-5871.36974514691*o[61] + o[21]*(o[16]*(6.778124247012e-21 + (4.07369914453886e-09 - 0.0766125010815314*o[15])*o[28]) + g.pi*(-5.20874181827336e-22*o[27] + g.pi*(0.0926230639263108*o[62] + g.pi*(-2.51975728716995e-11*o[63] + (1.04895338726032e-24 + o[18]*(1.22355691494518e-12 - 0.0302134054703458*o[32]))*o[64]*g.pi)))))))))))) + (3.0697722845484e-07 + 1.73611341786625e-05*tau2)*tau2));
            g.gpitautau:=-0.09199202739273 + o[67] + g.pi*(-0.0007579595006526 + o[1]*(-0.094542665384052 + (-3.67897283464813 - 0.0672198607434992*o[13])*o[2]) + g.pi*((-0.00058099819029426 + (-0.135305320879332 - 145.185665218657*o[13])*o[2])*tau2 + g.pi*(1.0232574281828e-07 + o[53] + g.pi*(0.000481363603090881*o[68] + g.pi*(g.pi*((-0.000971879285230777 - 163.576738230104*o[18])*o[69] + g.pi*((5.04278268948563e-09 - 82969.831625182*o[19])*o[20] + g.pi*(2.78128367741315e-05*o[17] + g.pi*(o[1]*(1.24883582522088e-17 + (-9.2112723863361e-11 - 1.823308647071e-06*o[10])*o[20]) + o[23]*((-1.05083074914163e-06 + 4191.66849672833*o[24])*o[70] + o[21]*(-19340.9826898957*o[71] + o[21]*((6.778124247012e-21 + (7.28977741654322e-09 - 0.189515134254314*o[15])*o[28])*o[32] + g.pi*(-5.20874181827336e-22*o[16] + g.pi*(0.229352348769913*o[72] + g.pi*(-4.35230804147537e-11*o[73] + (1.14016672528295e-24 + o[18]*(2.07472694273313e-12 - 0.0748767005134657*o[32]))*o[74]*g.pi)))))))))) + (-6.01731592238196e-10 + o[15]*(-3.04869201427512 - 170615.597409503*o[16]))*tau2)))));
          end g2L3;

          function f3L3
          "Helmholtz function for region 3: f(d,T), including 3rd derivatives"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Density d "density";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd
                                                                                f
            "dimensionless Helmholtz function and dervatives wrt delta and tau";
        protected
            Real tau "dimensionless temperature";
            Real del "dimensionless density";
            Real[62] o "vector of auxiliary variables";
          algorithm
            f.T:=T;
            f.d:=d;
            f.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TCRIT/T;
            del:=if d == ThermoSysPro.Properties.WaterSteam.BaseIF97.data.DCRIT and T == ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TCRIT then 1 - Modelica.Constants.eps else abs(d/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.DCRIT);
            f.tau:=tau;
            f.delta:=del;
            o[1]:=tau*tau;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*tau;
            o[4]:=o[1]*tau;
            o[5]:=o[2]*o[2];
            o[6]:=o[1]*o[5]*tau;
            o[7]:=o[5]*tau;
            o[8]:=-0.64207765181607*o[1];
            o[9]:=0.88521043984318 + o[8];
            o[10]:=o[7]*o[9];
            o[11]:=-1.1524407806681 + o[10];
            o[12]:=o[11]*o[2];
            o[13]:=-1.2654315477714 + o[12];
            o[14]:=o[1]*o[13];
            o[15]:=o[1]*o[2]*o[5]*tau;
            o[16]:=o[2]*o[5];
            o[17]:=o[1]*o[5];
            o[18]:=o[5]*o[5];
            o[19]:=o[1]*o[18]*o[2];
            o[20]:=o[1]*o[18]*o[2]*tau;
            o[21]:=o[18]*o[5];
            o[22]:=o[1]*o[18]*o[5];
            o[23]:=0.25116816848616*o[2];
            o[24]:=0.078841073758308 + o[23];
            o[25]:=o[15]*o[24];
            o[26]:=-6.100523451393 + o[25];
            o[27]:=o[26]*tau;
            o[28]:=9.7944563083754 + o[27];
            o[29]:=o[2]*o[28];
            o[30]:=-1.70429417648412 + o[29];
            o[31]:=o[1]*o[30];
            o[32]:=del*del;
            o[33]:=-2.85576214409538*o[17];
            o[34]:=-0.0492885823043778 + o[33];
            o[35]:=o[16]*o[34];
            o[36]:=-12.113949014142 + o[35];
            o[37]:=o[1]*o[36];
            o[38]:=8.339879741676 + o[37];
            o[39]:=o[1]*o[38];
            o[40]:=del*o[32];
            o[41]:=-10.9153200808732*o[1];
            o[42]:=13.2781565976477 + o[41];
            o[43]:=o[42]*o[7];
            o[44]:=-6.9146446840086 + o[43];
            o[45]:=o[2]*o[44];
            o[46]:=-2.5308630955428 + o[45];
            o[47]:=o[46]*tau;
            o[48]:=o[18]*o[5]*tau;
            o[49]:=-174.645121293971*o[1];
            o[50]:=185.894192367068 + o[49];
            o[51]:=o[50]*o[7];
            o[52]:=-34.573223420043 + o[51];
            o[53]:=o[2]*o[52];
            o[54]:=6.53037238064016*o[2];
            o[55]:=1.73450362268278 + o[54];
            o[56]:=o[15]*o[55];
            o[57]:=-42.703664159751 + o[56];
            o[58]:=o[57]*tau;
            o[59]:=58.7667378502524 + o[58];
            o[60]:=o[2]*o[59];
            o[61]:=-3.40858835296824 + o[60];
            o[62]:=o[61]*tau;
            f.f:=-15.732845290239 + tau*(20.944396974307 + (-7.6867707878716 + o[3]*(2.6185947787954 + o[4]*(-2.808078114862 + o[1]*(1.2053369696517 - 0.0084566812812502*o[6]))))*tau) + del*(o[14] + del*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(4.8972281541877 + (-3.0502617256965 + o[15]*(0.039420536879154 + 0.12558408424308*o[2]))*tau)) + del*(-0.2799932969871 + o[1]*(1.389979956946 + o[1]*(-2.018991502357 + o[16]*(-0.0082147637173963 - 0.47596035734923*o[17]))) + del*(0.0439840744735 + o[1]*(-0.44476435428739 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + del*(del*(-0.022175400873096 + o[1]*(0.094260751665092 + 0.16436278447961*o[21]) + del*(-0.013503372241348*o[1] + del*(-0.014834345352472*o[22] + del*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21]) + del*(8.0964802996215e-05 - 4.4923899061815e-05*del*o[22] - 0.00016557679795037*tau))))) + (0.10770512626332 + o[1]*(-0.32913623258954 - 0.50871062041158*o[20]))*tau))))) + 1.0658070028513*Modelica.Math.log(del);
            f.fdelta:=(1.0658070028513 + del*(o[14] + del*(0.76986920373342 + o[31] + del*(-0.8399798909613 + o[1]*(4.169939870838 + o[1]*(-6.056974507071 + o[16]*(-0.0246442911521889 - 1.42788107204769*o[17]))) + del*(0.175936297894 + o[1]*(-1.77905741714956 + o[1]*(3.62288282878932 + 2.82089800351868*o[19])) + del*(del*(-0.133052405238576 + o[1]*(0.565564509990552 + 0.98617670687766*o[21]) + del*(-0.094523605689436*o[1] + del*(-0.118674762819776*o[22] + del*(o[1]*(0.00521306582652756 + 0.0290780142333399*o[21]) + del*(0.00080964802996215 - 0.000494162889679965*del*o[22] - 0.0016557679795037*tau))))) + (0.5385256313166 + o[1]*(-1.6456811629477 - 2.5435531020579*o[20]))*tau))))))/del;
            f.fdeltadelta:=(-1.0658070028513 + o[32]*(0.76986920373342 + o[31] + del*(-1.6799597819226 + o[39] + del*(0.527808893682 + o[1]*(-5.33717225144868 + o[1]*(10.868648486368 + 8.46269401055604*o[19])) + del*(del*(-0.66526202619288 + o[1]*(2.82782254995276 + 4.9308835343883*o[21]) + del*(-0.567141634136616*o[1] + del*(-0.830723339738432*o[22] + del*(o[1]*(0.0417045266122205 + 0.232624113866719*o[21]) + del*(0.00728683226965935 - 0.00494162889679965*del*o[22] - 0.0149019118155333*tau))))) + (2.1541025252664 + o[1]*(-6.5827246517908 - 10.1742124082316*o[20]))*tau)))))/o[32];
            f.fdeltadeltadelta:=(2.1316140057026 + o[40]*(-1.6799597819226 + o[39] + del*(1.055617787364 + o[1]*(-10.6743445028974 + o[1]*(21.7372969727359 + 16.9253880211121*o[19])) + del*(del*(-2.66104810477152 + o[1]*(11.311290199811 + 19.7235341375532*o[21]) + del*(-2.83570817068308*o[1] + del*(-4.98434003843059*o[22] + del*(o[1]*(0.291931686285543 + 1.62836879706703*o[21]) + del*(0.0582946581572748 - 0.0444746600711968*del*o[22] - 0.119215294524266*tau))))) + (6.4623075757992 + o[1]*(-19.7481739553724 - 30.5226372246948*o[20]))*tau))))/o[40];
            f.ftau:=20.944396974307 + (-15.3735415757432 + o[3]*(18.3301634515678 + o[4]*(-28.08078114862 + o[1]*(14.4640436358204 - 0.194503669468755*o[6]))))*tau + del*(o[47] + del*(tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[15]*(0.867251811341388 + 3.26518619032008*o[2]))*tau)) + del*((2.779959913892 + o[1]*(-8.075966009428 + o[16]*(-0.131436219478341 - 12.37496929108*o[17])))*tau + del*((-0.88952870857478 + o[1]*(3.62288282878932 + 18.3358370228714*o[19]))*tau + del*(0.10770512626332 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20]) + del*((0.188521503330184 + 4.27343239646986*o[21])*tau + del*(-0.027006744482696*tau + del*(-0.385692979164272*o[48] + del*(del*(-0.00016557679795037 - 0.00116802137560719*del*o[48]) + (0.00115845907256168 + 0.0840031522296486*o[21])*tau)))))))));
            f.ftautau:=-15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.72703033758 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + del*(-2.5308630955428 + o[53] + del*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*tau) + del*(2.779959913892 + o[1]*(-24.227898028284 + o[16]*(-1.97154329217511 - 309.374232277*o[17])) + del*(-0.88952870857478 + o[1]*(10.868648486368 + 458.395925571786*o[19]) + del*(del*(0.188521503330184 + 106.835809911746*o[21] + del*(-0.027006744482696 + del*(-9.6423244791068*o[21] + del*(0.00115845907256168 + 2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724 - 330.661903267527*o[20])*tau)))));
            f.ftautautau:=o[2]*(549.904903547034 + o[4]*(-2021.81624270064 + o[1]*(1591.04479994024 - 89.8606952945646*o[6]))) + del*(o[4]*(-138.292893680172 + (2416.62450077188 - 2619.67681940957*o[1])*o[7]) + del*(o[4]*(587.667378502524 + (-640.554962396265 + o[15]*(364.245760763383 + 1959.11171419205*o[2]))*tau) + del*((-48.455796056568 + o[16]*(-27.6016060904516 - 7424.98157464799*o[17]))*tau + del*(del*(-1.97481739553724 - 7935.88567842065*o[20] + del*(2564.05943788192*o[20] + o[32]*(-231.415787498563*o[20] + del*(50.4018913377892*o[20] - 0.700812825364314*o[20]*o[32])))) + (21.7372969727359 + 11001.5022137229*o[19])*tau))));
            f.fdeltatau:=o[47] + del*(o[62] + del*((8.339879741676 + o[1]*(-24.227898028284 + o[16]*(-0.394308658435022 - 37.1249078732399*o[17])))*tau + del*((-3.55811483429912 + o[1]*(14.4915313151573 + 73.3433480914857*o[19]))*tau + del*(0.5385256313166 + o[1]*(-4.9370434888431 - 66.1323806535054*o[20]) + del*((1.1311290199811 + 25.6405943788192*o[21])*tau + del*(-0.189047211378872*tau + del*(-3.08554383331418*o[48] + del*(del*(-0.0016557679795037 - 0.0128482351316791*del*o[48]) + (0.0104261316530551 + 0.756028370066837*o[21])*tau))))))));
            f.fdeltatautau:=-2.5308630955428 + o[53] + del*(-3.40858835296824 + o[2]*(293.833689251262 + (-256.221984958506 + o[15]*(36.4245760763383 + 163.259309516004*o[2]))*tau) + del*(8.339879741676 + o[1]*(-72.683694084852 + o[16]*(-5.91462987652534 - 928.122696830999*o[17])) + del*(-3.55811483429912 + o[1]*(43.4745939454718 + 1833.58370228714*o[19]) + del*(del*(1.1311290199811 + 641.014859470479*o[21] + del*(-0.189047211378872 + del*(-77.1385958328544*o[21] + del*(0.0104261316530551 + 18.9007092516709*o[21] - 0.321205878291977*o[21]*o[32])))) + (-9.8740869776862 - 1653.30951633764*o[20])*tau))));
            f.fdeltadeltatau:=o[62] + del*((16.679759483352 + o[1]*(-48.455796056568 + o[16]*(-0.788617316870045 - 74.2498157464799*o[17])))*tau + del*((-10.6743445028974 + o[1]*(43.4745939454718 + 220.030044274457*o[19]))*tau + del*(2.1541025252664 + o[1]*(-19.7481739553724 - 264.529522614022*o[20]) + del*((5.65564509990552 + 128.202971894096*o[21])*tau + del*(-1.13428326827323*tau + del*(-21.5988068331992*o[48] + del*(del*(-0.0149019118155333 - 0.128482351316791*del*o[48]) + (0.0834090532244409 + 6.0482269605347*o[21])*tau)))))));
          end f3L3;

          function g5L3
          "base function for region 5: g(p,T), including 3rd derivatives"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        protected
            Real tau "dimensionless temperature";
            Real pi "dimensionless pressure";
            Real[16] o "vector of auxiliary variables";
          algorithm
            assert(p > ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple, "IF97 medium function g5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple) + " Pa (triple point pressure)");
            assert(p <= ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT5, "IF97 medium function g5: input pressure (= " + String(p) + " Pa) is higher than 10 Mpa in region 5");
            assert(T <= 2273.15, "IF97 medium function g5: input temperature (= " + String(T) + " K) is higher than limit of 2273.15K in region 5");
            g.p:=p;
            g.T:=T;
            g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            pi:=p/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PSTAR5;
            tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TSTAR5/T;
            g.pi:=pi;
            g.tau:=tau;
            o[1]:=tau*tau;
            o[2]:=-0.004594282089991*o[1];
            o[3]:=0.0021774678714571 + o[2];
            o[4]:=o[3]*tau;
            o[5]:=o[1]*tau;
            o[6]:=o[1]*o[1];
            o[7]:=o[6]*o[6];
            o[8]:=o[7]*tau;
            o[9]:=-7.9449656719138e-06*o[8];
            o[10]:=pi*pi;
            o[11]:=o[10]*pi;
            o[12]:=-0.013782846269973*o[1];
            o[13]:=-0.027565692539946*tau;
            o[14]:=o[1]*o[6]*tau;
            o[15]:=o[1]*o[6];
            o[16]:=-7.15046910472242e-05*o[7];
            g.g:=pi*(-0.00012563183589592 + o[4] + pi*(-3.9724828359569e-06*o[8] + 1.2919228289784e-07*o[5]*pi)) + (-0.024805148933466 + tau*(0.36901534980333 + tau*(-3.1161318213925 + tau*(-13.179983674201 + (6.8540841634434 - 0.32961626538917*tau)*tau + Modelica.Math.log(pi)))))/o[5];
            g.gpi:=(1.0 + pi*(-0.00012563183589592 + o[4] + pi*(o[9] + 3.8757684869352e-07*o[5]*pi)))/pi;
            g.gpipi:=(-1.0 + o[10]*(o[9] + 7.7515369738704e-07*o[5]*pi))/o[10];
            g.gpipipi:=(2.0 + 7.7515369738704e-07*o[11]*o[5])/o[11];
            g.gtau:=pi*(0.0021774678714571 + o[12] + pi*(-3.57523455236121e-05*o[7] + 3.8757684869352e-07*o[1]*pi)) + (0.074415446800398 + tau*(-0.73803069960666 + (3.1161318213925 + o[1]*(6.8540841634434 - 0.65923253077834*tau))*tau))/o[6];
            g.gtautau:=(-0.297661787201592 + tau*(2.21409209881998 + (-6.232263642785 - 0.65923253077834*o[5])*tau))/(o[6]*tau) + pi*(o[13] + pi*(-0.000286018764188897*o[14] + 7.7515369738704e-07*pi*tau));
            g.gtautautau:=pi*(-0.027565692539946 + (-0.00200213134932228*o[15] + 7.7515369738704e-07*pi)*pi) + (1.48830893600796 + tau*(-8.85636839527992 + 18.696790928355*tau))/o[15];
            g.gpitau:=0.0021774678714571 + o[12] + pi*(o[16] + 1.16273054608056e-06*o[1]*pi);
            g.gpipitau:=o[16] + 2.32546109216112e-06*o[1]*pi;
            g.gpitautau:=o[13] + pi*(-0.000572037528377794*o[14] + 2.32546109216112e-06*pi*tau);
          end g5L3;
          annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p>Package BaseIF97/Basic computes the the fundamental functions for the 5 regions of the steam tables
          as described in the standards document <a href=\"Documentation/IF97documentation/IF97.pdf\">IF97.pdf</a>. The code of these
          functions has been generated using <b><i>Mathematica</i></b> and the add-on packages \"Format\" and \"Optimize\"
          to generate highly efficient, expression-optimized C-code from a symbolic representation of the thermodynamic
          functions. The C-code has than been transformed into Modelica code. An important feature of this optimization was to
          simultaneously optimize the functions and the directional derivatives because they share many common subexpressions.</p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>g1</b> computes the dimensionless Gibbs function for region 1 and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>g2</b> computes the dimensionless Gibbs function  for region 2 and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>g2metastable</b> computes the dimensionless Gibbs function for metastable vapour
          (adjacent to region 2 but 2-phase at equilibrium) and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>f3</b> computes the dimensionless Helmholtz function  for region 3 and all derivatives up
          to order 2 w.r.t delta and tau. Inputs: d and T.</li>
          <li>Function <b>g5</b>computes the dimensionless Gibbs function for region 5 and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>tph1</b> computes the inverse function T(p,h) in region 1.</li>
          <li>Function <b>tph2</b> computes the inverse function T(p,h) in region 2.</li>
          <li>Function <b>tps2a</b> computes the inverse function T(p,s) in region 2a.</li>
          <li>Function <b>tps2b</b> computes the inverse function T(p,s) in region 2b.</li>
          <li>Function <b>tps2c</b> computes the inverse function T(p,s) in region 2c.</li>
          <li>Function <b>tps2</b> computes the inverse function T(p,s) in region 2.</li>
          <li>Function <b>tsat</b> computes the saturation temperature as a function of pressure.</li>
          <li>Function <b>dtsatofp</b> computes the derivative of the saturation temperature w.r.t. pressure as
          a function of pressure.</li>
          <li>Function <b>tsat_der</b> computes the Modelica derivative function of tsat.</li>
          <li>Function <b>psat</b> computes the saturation pressure as a function of temperature.</li>
          <li>Function <b>dptofT</b>  computes the derivative of the saturation pressure w.r.t. temperature as
          a function of temperature.</li>
          <li>Function <b>psat_der</b> computes the Modelica derivative function of psat.</li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </HTML>
          "),       Documentation(info="<html>
       <p>
       &nbsp;Equation from:<br>
       <div style=\"text-align: center;\">&nbsp;[1] The international Association
       for the Properties of Water and Steam<br>
       &nbsp;Vejle, Denmark<br>
       &nbsp;August 2003<br>
       &nbsp;Supplementary Release on Backward Equations for the Fucnctions
       T(p,h), v(p,h) and T(p,s), <br>
       &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
       the Thermodynamic Properties of<br>
       &nbsp;Water and Steam</div>
       </p>
       </html>"));
        end Basic;

        package Isentropic
        "functions for calculating the isentropic enthalpy from pressure p and specific entropy s"
          extends Modelica.Icons.Library;

          function hofpT1
          "intermediate function for isentropic specific enthalpy in region 1"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real[13] o "vector of auxiliary variables";
            Real pi1 "dimensionless pressure";
            Real tau "dimensionless temperature";
            Real tau1 "dimensionless temperature";
          algorithm
            tau:=data.TSTAR1/T;
            pi1:=7.1 - p/data.PSTAR1;
            assert(p > triple.ptriple, "IF97 medium function hofpT1  called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            tau1:=-1.222 + tau;
            o[1]:=tau1*tau1;
            o[2]:=o[1]*tau1;
            o[3]:=o[1]*o[1];
            o[4]:=o[3]*o[3];
            o[5]:=o[1]*o[4];
            o[6]:=o[1]*o[3];
            o[7]:=o[3]*tau1;
            o[8]:=o[3]*o[4];
            o[9]:=pi1*pi1;
            o[10]:=o[9]*o[9];
            o[11]:=o[10]*o[10];
            o[12]:=o[4]*o[4];
            o[13]:=o[12]*o[12];
            h:=data.RH2O*T*tau*(pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6]))/o[5] + pi1*((0.00141552963219801 + o[3]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[1]*o[3]*o[4])))/o[3] + pi1*((0.000126718579380216 - 5.11230768720618e-09*o[5])/o[7] + pi1*((1.1212640954e-05 + o[2]*(1.30342445791202e-06 - 1.4341729937924e-12*o[8]))/o[6] + pi1*(o[9]*pi1*((1.40077319158051e-08 + 1.04549227383804e-09*o[7])/o[8] + o[10]*o[11]*pi1*(1.9941018075704e-17/(o[1]*o[12]*o[3]*o[4]) + o[9]*(-4.48827542684151e-19/o[13] + o[10]*o[9]*(pi1*(4.65957282962769e-22/(o[13]*o[4]) + pi1*(3.83502057899078e-24*pi1/(o[1]*o[13]*o[4]) - 7.2912378325616e-23/(o[13]*o[4]*tau1))) - 1.00075970318621e-21/(o[1]*o[13]*o[3]*tau1))))) + 3.24135974880936e-06/(o[4]*tau1)))))) + (-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))))/o[2]);
          end hofpT1;

          function hofpT2
          "intermediate function for isentropic specific enthalpy in region 2"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        protected
            Real[16] o "vector of auxiliary variables";
            Real pi "dimensionless pressure";
            Real tau "dimensionless temperature";
            Real tau2 "dimensionless temperature";
          algorithm
            assert(p > triple.ptriple, "IF97 medium function hofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
            pi:=p/data.PSTAR2;
            tau:=data.TSTAR2/T;
            tau2:=-0.5 + tau;
            o[1]:=tau*tau;
            o[2]:=o[1]*o[1];
            o[3]:=tau2*tau2;
            o[4]:=o[3]*tau2;
            o[5]:=o[3]*o[3];
            o[6]:=o[5]*o[5];
            o[7]:=o[6]*o[6];
            o[8]:=o[5]*o[6]*o[7]*tau2;
            o[9]:=o[3]*o[5];
            o[10]:=o[5]*o[6]*tau2;
            o[11]:=o[3]*o[7]*tau2;
            o[12]:=o[3]*o[5]*o[6];
            o[13]:=o[5]*o[6]*o[7];
            o[14]:=pi*pi;
            o[15]:=o[14]*o[14];
            o[16]:=o[7]*o[7];
            h:=data.RH2O*T*tau*((0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[1]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[1]*o[2]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296 - 0.30195167236758*o[4])*tau2) + pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[3]*(-0.015757110897342 + o[4]*(-0.306581069554011 - 0.000960283724907132*o[8])))*tau2 + pi*(4.3870667284435e-07 + o[3]*(-9.683303171571e-05 + o[4]*(-0.0090203547252888 - 1.42338887469272*o[8])) + pi*(-7.8847309559367e-10 + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2 + pi*(1.60454534363627e-05*o[9] + pi*((-5.0144299353183e-11 + o[10]*(-0.033874355714168 - 836.35096769364*o[11]))*o[3] + pi*((-1.38839897890111e-05 - 0.973671060893475*o[12])*o[3]*o[6] + pi*((9.0049690883672e-11 - 296.320827232793*o[13])*o[3]*o[5]*tau2 + pi*(2.57526266427144e-07*o[5]*o[6] + pi*(o[4]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[5])*o[9]) + o[14]*o[15]*(o[13]*(-2.34560435076256e-09 + 5.3465159397045*o[5]*o[7]*tau2) + o[14]*(-19.1874828272775*o[16]*o[6]*o[7] + o[14]*(o[11]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[10])*o[3]*o[5]*o[6]*tau2) + pi*(-1.24017662339842e-24*o[5]*o[7] + pi*(0.000200482822351322*o[16]*o[5]*o[7] + pi*(-4.97975748452559e-14*o[16]*o[3]*o[5] + o[6]*o[7]*(1.90027787547159e-27 + o[12]*(2.21658861403112e-15 - 5.47344301999018e-05*o[3]*o[7]))*pi*tau2)))))))))))))))));
          end hofpT2;
          annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p></p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>hofpT1</b> computes h(p,T) in region 1.</li>
          <li>Function <b>handsofpT1</b> computes (s,h)=f(p,T) in region 1, needed for two-phase properties.</li>
          <li>Function <b>hofps1</b> computes h(p,s) in region 1.</li>
          <li>Function <b>hofpT2</b> computes h(p,T) in region 2.</li>
          <li>Function <b>handsofpT2</b> computes (s,h)=f(p,T) in region 2, needed for two-phase properties.</li>
          <li>Function <b>hofps2</b> computes h(p,s) in region 2.</li>
          <li>Function <b>hofdT3</b> computes h(d,T) in region 3.</li>
          <li>Function <b>hofpsdt3</b> computes h(p,s,dguess,Tguess) in region 3, where dguess and Tguess are initial guess
          values for the density and temperature consistent with p and s.</li>
          <li>Function <b>hofps4</b> computes h(p,s) in region 4.</li>
          <li>Function <b>hofpT5</b> computes h(p,T) in region 5.</li>
          <li>Function <b>water_hisentropic</b> computes h(p,s,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
          <li>Function <b>water_hisentropic_dyn</b> computes h(p,s,dguess,Tguess,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
          values for the density and temperature consistent with p and s. This function should be preferred in
          dynamic simulations where good guesses are often available.</li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </HTML>
          "));
        end Isentropic;

        package Inverses "efficient inverses for selected pairs of variables"
          extends Modelica.Icons.Library;

          function fixdT "region limits for inverse iteration in region 3"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Density din "density";
            input Modelica.SIunits.Temperature Tin "temperature";
            output Modelica.SIunits.Density dout "density";
            output Modelica.SIunits.Temperature Tout "temperature";
        protected
            Modelica.SIunits.Temperature Tmin
            "approximation of minimum temperature";
            Modelica.SIunits.Temperature Tmax
            "approximation of maximum temperature";
          algorithm
            if din > 765.0 then
              dout:=765.0;
            elseif din < 110.0 then
              dout:=110.0;
            else
              dout:=din;
            end if;
            if dout < 390.0 then
              Tmax:=554.3557377 + dout*0.809344262;
            else
              Tmax:=1116.85 - dout*0.632948717;
            end if;
            if dout < data.DCRIT then
              Tmin:=data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1000000.0);
            else
              Tmin:=data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1440000.0);
            end if;
            if Tin < Tmin then
              Tout:=Tmin;
            elseif Tin > Tmax then
              Tout:=Tmax;
            else
              Tout:=Tin;
            end if;
          end fixdT;

          function dofp13 "density at the boundary between regions 1 and 3"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.Density d "density";
        protected
            Real p2 "auxiliary variable";
            Real[3] o "vector of auxiliary variables";
          algorithm
            p2:=7.1 - 6.04960677555959e-08*p;
            o[1]:=p2*p2;
            o[2]:=o[1]*o[1];
            o[3]:=o[2]*o[2];
            d:=57.4756752485113/(0.0737412153522555 + p2*(0.00145092247736023 + p2*(0.000102697173772229 + p2*(1.14683182476084e-05 + p2*(1.99080616601101e-06 + o[1]*p2*(1.13217858826367e-08 + o[2]*o[3]*p2*(1.35549330686006e-17 + o[1]*(-3.11228834832975e-19 + o[1]*o[2]*(-7.02987180039442e-22 + p2*(3.29199117056433e-22 + (-5.17859076694812e-23 + 2.73712834080283e-24*p2)*p2))))))))));
          end dofp13;

          function dofp23 "density at the boundary between regions 2 and 3"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            output Modelica.SIunits.Density d "density";
        protected
            Modelica.SIunits.Temperature T;
            Real[13] o "vector of auxiliary variables";
            Real taug "auxiliary variable";
            Real pi "dimensionless pressure";
            Real gpi23
            "derivative of g w.r.t. pi on the boundary between regions 2 and 3";
          algorithm
            pi:=p/data.PSTAR2;
            T:=572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
            o[1]:=(-13.91883977887 + pi)^0.5;
            taug:=-0.5 + 540.0/(572.54459862746 + 31.3220101646784*o[1]);
            o[2]:=taug*taug;
            o[3]:=o[2]*taug;
            o[4]:=o[2]*o[2];
            o[5]:=o[4]*o[4];
            o[6]:=o[5]*o[5];
            o[7]:=o[4]*o[5]*o[6]*taug;
            o[8]:=o[4]*o[5]*taug;
            o[9]:=o[2]*o[4]*o[5];
            o[10]:=pi*pi;
            o[11]:=o[10]*o[10];
            o[12]:=o[4]*o[6]*taug;
            o[13]:=o[6]*o[6];
            gpi23:=(1.0 + pi*(-0.0017731742473213 + taug*(-0.017834862292358 + taug*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[3])*taug)) + pi*(taug*(-6.6065283340406e-05 + (-0.0003789797503263 + o[2]*(-0.007878555448671 + o[3]*(-0.087594591301146 - 5.3349095828174e-05*o[7])))*taug) + pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[2]*(-9.683303171571e-05 + o[3]*(-0.0045101773626444 - 0.122004760687947*o[7])))*taug + pi*(taug*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*taug)*taug) + pi*(1.14610381688305e-05*o[2]*o[4]*taug + pi*(o[3]*(-1.00288598706366e-10 + o[8]*(-0.012702883392813 - 143.374451604624*o[2]*o[6]*taug)) + pi*(-4.1341695026989e-17 + o[2]*o[5]*(-8.8352662293707e-06 - 0.272627897050173*o[9])*taug + pi*(o[5]*(9.0049690883672e-11 - 65.8490727183984*o[4]*o[5]*o[6]) + pi*(1.78287415218792e-07*o[8] + pi*(o[4]*(1.0406965210174e-18 + o[2]*(-1.0234747095929e-12 - 1.0018179379511e-08*o[4])*o[4]) + o[10]*o[11]*((-1.29412653835176e-09 + 1.71088510070544*o[12])*o[7] + o[10]*(-6.05920510335078*o[13]*o[5]*o[6]*taug + o[10]*(o[4]*o[6]*(1.78371690710842e-23 + o[2]*o[4]*o[5]*(6.1258633752464e-12 - 8.4004935396416e-05*o[8])*taug) + pi*(-1.24017662339842e-24*o[12] + pi*(8.32192847496054e-05*o[13]*o[4]*o[6]*taug + pi*(o[2]*o[5]*o[6]*(1.75410265428146e-27 + (1.32995316841867e-15 - 2.26487297378904e-05*o[2]*o[6])*o[9])*pi - 2.93678005497663e-14*o[13]*o[2]*o[4]*taug)))))))))))))))))/pi;
            d:=p/(data.RH2O*T*pi*gpi23);
          end dofp23;

          function dofpt3 "inverse iteration in region 3: (d) = f(p,T)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.Temperature T "temperature (K)";
            input Modelica.SIunits.Pressure delp
            "iteration converged if (p-pre(p) < delp)";
            output Modelica.SIunits.Density d "density";
            output Integer error=0
            "error flag: iteration failed if different from 0";
        protected
            Modelica.SIunits.Density dguess "guess density";
            Integer i=0 "loop counter";
            Real dp "pressure difference";
            Modelica.SIunits.Density deld "density step";
            Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives wrt delta and tau";
            Modelica.Media.Common.NewtonDerivatives_pT nDerivs
            "derivatives needed in Newton iteration";
            Boolean found=false "flag for iteration success";
            Boolean supercritical "flag, true for supercritical states";
            Boolean liquid "flag, true for liquid states";
            Modelica.SIunits.Density dmin "lower density limit";
            Modelica.SIunits.Density dmax "upper density limit";
            Modelica.SIunits.Temperature Tmax "maximum temperature";
          algorithm
            assert(p >= data.PLIMIT4A, "BaseIF97.dofpt3: function called outside of region 3! p too low\n" + "p = " + String(p) + " Pa < " + String(data.PLIMIT4A) + " Pa");
            assert(T >= data.TLIMIT1, "BaseIF97.dofpt3: function called outside of region 3! T too low\n" + "T = " + String(T) + " K < " + String(data.TLIMIT1) + " K");
            assert(p >= Regions.boundary23ofT(T), "BaseIF97.dofpt3: function called outside of region 3! T too high\n" + "p = " + String(p) + " Pa, T = " + String(T) + " K");
            supercritical:=p > data.PCRIT;
            dmax:=dofp13(p);
            dmin:=dofp23(p);
            Tmax:=Regions.boundary23ofp(p);
            if supercritical then
              dguess:=dmin + (T - data.TLIMIT1)/(data.TLIMIT1 - Tmax)*(dmax - dmin);
            else
              liquid:=T < Basic.tsat(p);
              if liquid then
                dguess:=0.5*(Regions.rhol_p_R4b(p) + dmax);
              else
                dguess:=0.5*(Regions.rhov_p_R4b(p) + dmin);
              end if;
            end if;
            while (i < IterationData.IMAX and not found) loop
              d:=dguess;
              f:=Basic.f3(d, T);
              nDerivs:=Modelica.Media.Common.Helmholtz_pT(f);
              dp:=nDerivs.p - p;
              if abs(dp/p) <= delp then
                found:=true;
              end if;
              deld:=dp/nDerivs.pd;
              d:=d - deld;
              if d > dmin and d < dmax then
                dguess:=d;
              else
                if d > dmax then
                  dguess:=dmax - sqrt(Modelica.Constants.eps);
                else
                  dguess:=dmin + sqrt(Modelica.Constants.eps);
                end if;
              end if;
              i:=i + 1;
            end while;
            if not found then
              error:=1;
            end if;
            assert(error <> 1, "error in inverse function dofpt3: iteration failed");
          end dofpt3;

          function dtofph3 "inverse iteration in region 3: (d,T) = f(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            input Modelica.SIunits.Pressure delp "iteration accuracy";
            input Modelica.SIunits.SpecificEnthalpy delh "iteration accuracy";
            output Modelica.SIunits.Density d "density";
            output Modelica.SIunits.Temperature T "temperature (K)";
            output Integer error
            "error flag: iteration failed if different from 0";
        protected
            Modelica.SIunits.Temperature Tguess "initial temperature";
            Modelica.SIunits.Density dguess "initial density";
            Integer i "iteration counter";
            Real dh "Newton-error in h-direction";
            Real dp "Newton-error in p-direction";
            Real det "determinant of directional derivatives";
            Real deld "Newton-step in d-direction";
            Real delt "Newton-step in T-direction";
            Modelica.Media.Common.HelmholtzDerivs f
            "dimensionless Helmholtz function and dervatives wrt delta and tau";
            Modelica.Media.Common.NewtonDerivatives_ph nDerivs
            "derivatives needed in Newton iteration";
            Boolean found "flag for iteration success";
            Integer subregion "1 for subregion 3a, 2 for subregion 3b";
          algorithm
            if p < data.PCRIT then
              subregion:=if h < Regions.hl_p(p) + 10.0 then 1 else if h > Regions.hv_p(p) - 10.0 then 2 else 0;
              assert(subregion <> 0, "inverse iteration of dt from ph called in 2 phase region: this can not work");
            else
              subregion:=if h < Basic.h3ab_p(p) then 1 else 2;
            end if;
            T:=if subregion == 1 then Basic.T3a_ph(p, h) else Basic.T3b_ph(p, h);
            d:=if subregion == 1 then 1/Basic.v3a_ph(p, h) else 1/Basic.v3b_ph(p, h);
            i:=0;
            error:=0;
            while (i < IterationData.IMAX and not found) loop
              f:=Basic.f3(d, T);
              nDerivs:=Modelica.Media.Common.Helmholtz_ph(f);
              dh:=nDerivs.h - h;
              dp:=nDerivs.p - p;
              if abs(dh/h) <= delh and abs(dp/p) <= delp then
                found:=true;
              end if;
              det:=nDerivs.ht*nDerivs.pd - nDerivs.pt*nDerivs.hd;
              delt:=(nDerivs.pd*dh - nDerivs.hd*dp)/det;
              deld:=(nDerivs.ht*dp - nDerivs.pt*dh)/det;
              T:=T - delt;
              d:=d - deld;
              dguess:=d;
              Tguess:=T;
              i:=i + 1;
              (d,T):=fixdT(dguess, Tguess);
            end while;
            if not found then
              error:=1;
            end if;
            assert(error <> 1, "error in inverse function dtofph3: iteration failed");
          end dtofph3;

          function tofph5 "inverse iteration in region 5: (p,T) = f(p,h)"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Pressure p "pressure";
            input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            input Modelica.SIunits.SpecificEnthalpy reldh "iteration accuracy";
            output Modelica.SIunits.Temperature T "temperature (K)";
            output Integer error
            "error flag: iteration failed if different from 0";
        protected
            Modelica.Media.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
            Modelica.SIunits.SpecificEnthalpy proh "h for current guess in T";
            constant Modelica.SIunits.Temperature Tguess=1500
            "initial temperature";
            Integer i "iteration counter";
            Real relerr "relative error in h";
            Real dh "Newton-error in h-direction";
            Real dT "Newton-step in T-direction";
            Boolean found "flag for iteration success";
          algorithm
            i:=0;
            error:=0;
            T:=Tguess;
            found:=false;
            while (i < IterationData.IMAX and not found) loop
              g:=Basic.g5(p, T);
              proh:=data.RH2O*T*g.tau*g.gtau;
              dh:=proh - h;
              relerr:=dh/h;
              if abs(relerr) < reldh then
                found:=true;
              end if;
              dT:=dh/(-data.RH2O*g.tau*g.tau*g.gtautau);
              T:=T - dT;
              i:=i + 1;
            end while;
            if not found then
              error:=1;
            end if;
            assert(error <> 1, "error in inverse function tofph5: iteration failed");
          end tofph5;
          annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p></p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>fixdT</b> constrains density and temperature to allowed region</li>
          <li>Function <b>dofp13</b> computes d as a function of p at boundary between regions 1 and 3</li>
          <li>Function <b>dofp23</b> computes d as a function of p at boundary between regions 2 and 3</li>
          <li>Function <b>dofpt3</b> iteration to compute d as a function of p and T in region 3</li>
          <li>Function <b>dtofph3</b> iteration to compute d and T as a function of p and h in region 3</li>
          <li>Function <b>dtofps3</b> iteration to compute d and T as a function of p and s in region 3</li>
          <li>Function <b>dtofpsdt3</b> iteration to compute d and T as a function of p and s in region 3,
          with initial guesses</li>
          <li>Function <b>pofdt125</b> iteration to compute p as a function of p and T in regions 1, 2 and 5</li>
          <li>Function <b>tofph5</b> iteration to compute T as a function of p and h in region 5</li>
          <li>Function <b>tofps5</b> iteration to compute T as a function of p and s in region 5</li>
          <li>Function <b>tofpst5</b> iteration to compute T as a function of p and s in region 5, with initial guess in T</li>
          <li>Function <b></b></li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </HTML>
          "));
        end Inverses;
        annotation(Documentation(info="<HTML>
    <h4>Version Info and Revision history
        </h4>
        <ul>
        <li>First implemented: <i>July, 2000</i>
        by Hubertus Tummescheit
        for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
        </li>
      <li>Code reorganization, enhanced documentation, additional functions:   <i>December, 2002</i>
      by <a href=\"mailto:Hubertus.Tummescheit@modelon.se\">Hubertus Tummescheit</a> and moved to Modelica
      properties library.</li>
        </ul>
      <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
      </address>
        <P>In September 1997, the International Association for the Properties
        of Water and Steam (<A HREF=\"http://www.iapws.org\">IAPWS</A>) adopted a
        new formulation for the thermodynamic properties of water and steam for
        industrial use. This new industrial standard is called \"IAPWS Industrial
        Formulation for the Thermodynamic Properties of Water and Steam\" (IAPWS-IF97).
        The formulation IAPWS-IF97 replaces the previous industrial standard IFC-67.
        <P>Based on this new formulation, a new steam table, titled \"<a
        href=\"http://www.springer.de/cgi-bin/search_book.pl?isbn=3-540-64339-7\">Properties
        of Water and Steam</a>\" by W. Wagner and A. Kruse, was published by
        the Springer-Verlag, Berlin - New-York - Tokyo in April 1998. This
        steam table, ref. <a href=\"#steamprop\">[1]</a> is bilingual (English /
        German) and contains a complete description of the equations of
        IAPWS-IF97. This reference is the authoritative source of information
        for this implementation. A mostly identical version has been published by the International
        Association for the Properties
        of Water and Steam (<A HREF=\"http://www.iapws.org\">IAPWS</A>) with permission granted to re-publish the
        information if credit is given to IAPWS. This document is distributed with this library as
        <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a>.
        In addition, the equations published by <A HREF=\"http://www.iapws..org\">IAPWS</A> for
        the transport properties dynamic viscosity (standards document: <a href=\"IF97documentation/visc.pdf\">visc.pdf</a>)
        and thermal conductivity (standards document: <a href=\"IF97documentation/thcond.pdf\">thcond.pdf</a>)
        and equations for the surface tension (standards document: <a href=\"IF97documentation/surf.pdf\">surf.pdf</a>)
        are also implemented in this library and included for reference.
        <P>
        The functions in BaseIF97.mo are low level functions which should
        only be used in those exceptions when the standard user level
        functions in Water.mo do not contain the wanted properties.
        </p>
<P>Based on IAPWS-IF97, Modelica functions are available for calculating
the most common thermophysical properties (thermodynamic and transport
properties). The implementation requires part of the common medium
property infrastructure of the Modelica.Thermal.Properties library in the file
Common.mo. There are a few extensions from the version of IF97 as
documented in <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a> in order to improve performance for
dynamic simulations. Input variables for calculating the properties are
only implemented for a limited number of variable pairs which make sense as dynamic states: (p,h), (p,T), (p,s) and (d,T).
<hr size=3 width=\"70%\">
<p><a name=\"regions\"><h4>1. Structure and Regions of IAPWS-IF97</h4></a>
<P>The IAPWS Industrial Formulation 1997 consists of
a set of equations for different regions which cover the following range
of validity:
<table border=0 cellpadding=4 align=center>
<tr>
<td valign=\"top\">273,15 K &lt; <I>T</I> &lt; 1073,15 K</td>
<td valign=\"top\"><I>p</I> &lt; 100 MPa</td>
</tr>
<tr>
<td valign=\"top\">1073,15 K &lt; <I>T</I> &lt; 2273,15 K</td>
<td valign=\"top\"><I>p</I> &lt; 10 MPa</td>
</tr>
</table><br>
Figure 1 shows the 5 regions into which the entire range of validity of
IAPWS-IF97 is divided. The boundaries of the regions can be directly taken
from Fig. 1 except for the boundary between regions 2 and 3; this boundary,
which corresponds approximately to the isentropic line <nobr><I>s</I> = 5.047 kJ kg
<FONT SIZE=-1><sup>-1</sup></FONT>
K<FONT SIZE=-1><sup>-1</sup></FONT>,</nobr> is defined
by a corresponding auxiliary equation. Both regions 1 and 2 are individually
covered by a fundamental equation for the specific Gibbs free energy <nobr><I>g</I>(<I>
p</I>,<I>T </I>)</nobr>, region 3 by a fundamental equation for the specific Helmholtz
free energy <nobr><I>f </I>(<I> <FONT FACE=\"Symbol\">r</FONT></I>,<I>T
</I>)</nobr>, and the saturation curve, corresponding to region 4, by a saturation-pressure
equation <nobr><I>p</I><FONT SIZE=-1><sub>s</sub></FONT>(<I>T</I>)</nobr>. The high-temperature
region 5 is also covered by a <nobr><I>g</I>(<I> p</I>,<I>T </I>)</nobr> equation. These
5 equations, shown in rectangular boxes in Fig. 1, form the so-called <I>basic
equations</I>.
      <p>
      <img src=\"IF97documentation/if97.png\" alt=\"Regions and equations of IAPWS-IF97\"></p>
      <p align=center>Figure 1: Regions and equations of IAPWS-IF97</p>
<P>In addition to these basic equations, so-called <I>backward
equations</I> are provided for regions 1, 2, and 4 in form of
<nobr><I>T </I>(<I> p</I>,<I>h </I>)</nobr> and <nobr><I>T </I>(<I>
p</I>,<I>s </I>)</nobr> for regions 1 and 2, and <nobr><I>T</I><FONT
SIZE=-1><sub>s</sub> </FONT>(<I> p </I>)</nobr> for region 4. These
backward equations, marked in grey in Fig. 1, were developed in such a
way that they are numerically very consistent with the corresponding
basic equation. Thus, properties as functions of&nbsp; <I>p</I>,<I>h
</I>and of&nbsp;<I> p</I>,<I>s </I>for regions 1 and 2, and of
<I>p</I> for region 4 can be calculated without any iteration. As a
result of this special concept for the development of the new
industrial standard IAPWS-IF97, the most important properties can be
calculated extremely quickly. All modelica functions are optimized
with regard to short computing times.
<P>The complete description of the individual equations of the new industrial
formulation IAPWS-IF97 is given in <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a>. Comprehensive information on
IAPWS-IF97 (requirements, concept, accuracy, consistency along region boundaries,
and the increase of computing speed in comparison with IFC-67, etc.) can
be taken from <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a> or [2].
<P><a name=\"steamprop\">[1]<I>Wagner, W., Kruse, A.</I> Properties of Water
and Steam / Zustandsgr&ouml;&szlig;en von Wasser und Wasserdampf / IAPWS-IF97.
Springer-Verlag, Berlin, 1998.
<P>[2] <I>Wagner, W., Cooper, J. R., Dittmann, A., Kijima,
J., Kretzschmar, H.-J., Kruse, A., Mare� R., Oguchi, K., Sato, H., St&ouml;cker,
I., �fner, O., Takaishi, Y., Tanishita, I., Tr&uuml;benbach, J., and Willkommen,
Th.</I> The IAPWS Industrial Formulation 1997 for the Thermodynamic Properties
of Water and Steam. ASME Journal of Engineering for Gas Turbines and Power 122 (2000), 150 - 182.
<p>
<HR size=3 width=\"90%\">
<h4>2. Calculable Properties      </h4>
<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">
       <tbody>
       <tr>
       <td valign=\"top\" bgcolor=\"#cccccc\"><br>
      </td>
      <td valign=\"top\" bgcolor=\"#cccccc\"><b>Common name</b><br>
       </td>
       <td valign=\"top\" bgcolor=\"#cccccc\"><b>Abbreviation </b><br>
       </td>
       <td valign=\"top\" bgcolor=\"#cccccc\"><b>Unit</b><br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;1<br>
      </td>
      <td valign=\"top\">Pressure</td>
       <td valign=\"top\">p<br>
        </td>
       <td valign=\"top\">Pa<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;2<br>
      </td>
      <td valign=\"top\">Temperature</td>
       <td valign=\"top\">T<br>
       </td>
       <td valign=\"top\">K<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;3<br>
      </td>
      <td valign=\"top\">Density</td>
        <td valign=\"top\">d<br>
        </td>
       <td valign=\"top\">kg/m<sup>3</sup><br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;4<br>
      </td>
      <td valign=\"top\">Specific volume</td>
        <td valign=\"top\">v<br>
        </td>
       <td valign=\"top\">m<sup>3</sup>/kg<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;5<br>
      </td>
      <td valign=\"top\">Specific enthalpy</td>
       <td valign=\"top\">h<br>
       </td>
       <td valign=\"top\">J/kg<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;6<br>
      </td>
      <td valign=\"top\">Specific entropy</td>
       <td valign=\"top\">s<br>
       </td>
       <td valign=\"top\">J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;7<br>
      </td>
      <td valign=\"top\">Specific internal energy<br>
       </td>
       <td valign=\"top\">u<br>
       </td>
       <td valign=\"top\">J/kg<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;8<br>
      </td>
      <td valign=\"top\">Specific isobaric heat capacity</td>
       <td valign=\"top\">c<font size=\"-1\"><sub>p</sub></font><br>
       </td>
       <td valign=\"top\">J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;9<br>
      </td>
      <td valign=\"top\">Specific isochoric heat capacity</td>
       <td valign=\"top\">c<font size=\"-1\"><sub>v</sub></font><br>
       </td>
       <td valign=\"top\">J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">10<br>
      </td>
      <td valign=\"top\">Isentropic exponent, kappa<nobr>=       <font face=\"Symbol\">-</font>(v/p)
(dp/dv)<font size=\"-1\"><sub>s</sub> </font></nobr></td>
     <td valign=\"top\">kappa (     <font face=\"Symbol\">k</font>)<br>
     </td>
     <td valign=\"top\">1<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">11<br>
      </td>
      <td valign=\"top\">Speed of sound<br>
     </td>
     <td valign=\"top\">a<br>
     </td>
     <td valign=\"top\">m/s<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">12<br>
      </td>
      <td valign=\"top\">Dryness fraction<br>
     </td>
     <td valign=\"top\">x<br>
     </td>
     <td valign=\"top\">kg/kg<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">13<br>
      </td>
      <td valign=\"top\">Specific Helmholtz free energy,     f = u - Ts</td>
     <td valign=\"top\">f<br>
     </td>
     <td valign=\"top\">J/kg<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">14<br>
      </td>
      <td valign=\"top\">Specific Gibbs free energy,     g = h - Ts</td>
     <td valign=\"top\">g<br>
     </td>
     <td valign=\"top\">J/kg<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">15<br>
      </td>
      <td valign=\"top\">Isenthalpic exponent, <nobr> theta     = -(v/p)(dp/dv)<font
 size=\"-1\"><sub>h</sub></font></nobr></td>
     <td valign=\"top\">theta (<font face=\"Symbol\">q</font>)<br>
     </td>
     <td valign=\"top\">1<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">16<br>
      </td>
      <td valign=\"top\">Isobaric volume expansion coefficient,     alpha = v<font
 size=\"-1\"><sup>-1</sup></font>       (dv/dT)<font size=\"-1\"><sub>p</sub>
    </font></td>
     <td valign=\"top\">alpha  (<font face=\"Symbol\">a</font>)<br>
     </td>
       <td valign=\"top\">1/K<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">17<br>
      </td>
      <td valign=\"top\">Isochoric pressure coefficient,     <nobr>beta = p<font
 size=\"-1\"><sup><font face=\"Symbol\">-</font>1</sup>     </font>(dp/dT)<font
 size=\"-1\"><sub>v</sub></font></nobr>     </td>
     <td valign=\"top\">beta (<font face=\"Symbol\">b</font>)<br>
     </td>
     <td valign=\"top\">1/K<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">18<br>
      </td>
      <td valign=\"top\">Isothermal compressibility,     g<nobr>amma  = <font
 face=\"Symbol\">-</font>v        <sup><font size=\"-1\"><font face=\"Symbol\">-</font>1</font></sup>(dv/dp)<font
 size=\"-1\"><sub>T</sub></font></nobr> </td>
        <td valign=\"top\">gamma (<font face=\"Symbol\">g</font>)<br>
     </td>
     <td valign=\"top\">1/Pa<br>
     </td>
     </tr>
     <!-- <tr><td valign=\"top\">f</td><td valign=\"top\">Fugacity</td></tr> --> <tr>
     <td valign=\"top\">19<br>
      </td>
      <td valign=\"top\">Dynamic viscosity</td>
     <td valign=\"top\">eta (<font face=\"Symbol\">h</font>)<br>
     </td>
     <td valign=\"top\">Pa s<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">20<br>
      </td>
      <td valign=\"top\">Kinematic viscosity</td>
     <td valign=\"top\">nu (<font face=\"Symbol\">n</font>)<br>
     </td>
     <td valign=\"top\">m<sup>2</sup>/s<br>
     </td>
     </tr>
     <!-- <tr><td valign=\"top\">Pr</td><td valign=\"top\">Prandtl number</td></tr> --> <tr>
     <td valign=\"top\">21<br>
      </td>
      <td valign=\"top\">Thermal conductivity</td>
     <td valign=\"top\">lambda (<font face=\"Symbol\">l</font>)<br>
     </td>
     <td valign=\"top\">W/(m K)<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">22 <br>
      </td>
      <td valign=\"top\">Surface tension</td>
     <td valign=\"top\">sigma (<font face=\"Symbol\">s</font>)<br>
     </td>
     <td valign=\"top\">N/m<br>
     </td>
     </tr>
  </tbody>
</table>
        <p>The properties 1-11 are calculated by default with the functions for dynamic
        simulation, 2 of these variables are the dynamic states and are the inputs
        to calculate all other properties. In addition to these properties
        of general interest, the entries to the thermodynamic Jacobian matrix which render
        the mass- and energy balances explicit in the input variables to the property calculation are also calculated.
        For an explanatory example using pressure and specific enthalpy as states, see the Examples sub-package.</p>
        <p>The high-level calls to steam properties are grouped into records comprising both the properties of general interest
        and the entries to the thermodynamic Jacobian. If additional properties are
        needed the low level functions in BaseIF97 provide more choice.</p>
        <HR size=3 width=\"90%\">
        <h4>Additional functions</h4>
        <ul>
        <li>Function <b>boundaryvals_p</b> computes the temperature and the specific enthalpy and
        entropy on both phase boundaries as a function of p</li>
        <li>Function <b>boundaryderivs_p</b> is the Modelica derivative function of <b>boundaryvals_p</b></li>
        <li>Function <b>extraDerivs_ph</b> computes all entries to Bridgmans tables for all
        one-phase regions of IF97 using inputs (p,h). All 336 directional derivatives of the
        thermodynamic surface can be computed as a ratio of two entries in the return data, see package Common
        for details.</li>
        <li>Function <b>extraDerivs_pT</b> computes all entries to Bridgmans tables for all
        one-phase regions of IF97 using inputs (p,T).</li>
        </ul>
        </p>
        </HTML>"));
      end BaseIF97;

      package Common
        import SI = Modelica.SIunits;

        record GibbsDerivs
        "derivatives of dimensionless Gibbs-function w.r.t dimensionless pressure and temperature"
          extends Modelica.Icons.Record;
          Modelica.SIunits.Pressure p "pressure";
          Modelica.SIunits.Temperature T "temperature";
          Modelica.SIunits.SpecificHeatCapacity R "specific heat capacity";
          Real pi(unit="1") "dimensionless pressure";
          Real tau(unit="1") "dimensionless temperature";
          Real g(unit="1") "dimensionless Gibbs-function";
          Real gpi(unit="1") "derivative of g w.r.t. pi";
          Real gpipi(unit="1") "2nd derivative of g w.r.t. pi";
          Real gtau(unit="1") "derivative of g w.r.t. tau";
          Real gtautau(unit="1") "2nd derivative of g w.r.t tau";
          Real gtaupi(unit="1") "mixed derivative of g w.r.t. pi and tau";
        end GibbsDerivs;

        record HelmholtzDerivs
        "derivatives of dimensionless Helmholtz-function w.r.t dimensionless pressuredensity and temperature"
          extends Modelica.Icons.Record;
          Modelica.SIunits.Density d "density";
          Modelica.SIunits.Temperature T "temperature";
          Modelica.SIunits.SpecificHeatCapacity R "specific heat capacity";
          Real delta(unit="1") "dimensionless density";
          Real tau(unit="1") "dimensionless temperature";
          Real f(unit="1") "dimensionless Helmholtz-function";
          Real fdelta(unit="1") "derivative of f w.r.t. delta";
          Real fdeltadelta(unit="1") "2nd derivative of f w.r.t. delta";
          Real ftau(unit="1") "derivative of f w.r.t. tau";
          Real ftautau(unit="1") "2nd derivative of f w.r.t. tau";
          Real fdeltatau(unit="1") "mixed derivative of f w.r.t. delta and tau";
        end HelmholtzDerivs;

        record ThermoProperties_ph
          ThermoSysPro.Units.AbsoluteTemperature T(min=InitLimits.TMIN, max=InitLimits.TMAX, nominal=InitLimits.TNOM)
          "Temperature";
          Modelica.SIunits.Density d(min=InitLimits.DMIN, max=InitLimits.DMAX, nominal=InitLimits.DNOM)
          "Density";
          Modelica.SIunits.SpecificEnergy u(min=InitLimits.SEMIN, max=InitLimits.SEMAX, nominal=InitLimits.SENOM)
          "Specific inner energy";
          Modelica.SIunits.SpecificEntropy s(min=InitLimits.SSMIN, max=InitLimits.SSMAX, nominal=InitLimits.SSNOM)
          "Specific entropy";
          Modelica.SIunits.SpecificHeatCapacity cp(min=InitLimits.CPMIN, max=InitLimits.CPMAX, nominal=InitLimits.CPNOM)
          "Specific heat capacity at constant presure";
          Modelica.SIunits.DerDensityByEnthalpy ddhp
          "Derivative of density wrt. specific enthalpy at constant pressure";
          Modelica.SIunits.DerDensityByPressure ddph
          "Derivative of density wrt. pressure at constant specific enthalpy";
          Real duph(unit="m3/kg")
          "Derivative of specific inner energy wrt. pressure at constant specific enthalpy";
          Real duhp(unit="1")
          "Derivative of specific inner energy wrt. specific enthalpy at constant pressure";
          ThermoSysPro.Units.MassFraction x "Vapor mass fraction";
          annotation (                                                                    Window(x=0.21, y=0.32, width=0.6, height=0.6), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Rectangle(
                  extent={{-100,50},{100,-100}},
                  lineColor={0,0,255},
                  fillColor={255,255,127},
                  fillPattern=FillPattern.Solid),
                Text(extent={{-127,115},{127,55}}, textString =                                                                                                    "%name"),
                Line(points={{-100,-50},{100,-50}}, color={0,0,0}),
                Line(points={{-100,0},{100,0}}, color={0,0,0}),
                Line(points={{0,50},{0,-100}}, color={0,0,0})}),                                                                                                    Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end ThermoProperties_ph;

        function gibbsToProps_ph
          input GibbsDerivs g "dimensionless derivatives of the Gibbs function";
          output ThermoProperties_ph pro;
      protected
          Real vt;
          Real vp;
        algorithm
          pro.T:=min(max(g.T, InitLimits.TMIN), InitLimits.TMAX);
          pro.d:=max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple)/(g.R*pro.T*g.pi*g.gpi);
          pro.u:=g.T*g.R*(g.tau*g.gtau - g.pi*g.gpi);
          pro.s:=g.R*(g.tau*g.gtau - g.g);
          pro.cp:=-g.R*g.tau*g.tau*g.gtautau;
          vt:=g.R/max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple)*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
          vp:=g.R*g.T/(max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple)*max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple))*g.pi*g.pi*g.gpipi;
          pro.ddhp:=-pro.d*pro.d*vt/pro.cp;
          pro.ddph:=-pro.d*pro.d*(vp*pro.cp - vt/pro.d + g.T*vt*vt)/pro.cp;
          pro.duph:=-1/pro.d + g.p/(pro.d*pro.d)*pro.ddph;
          pro.duhp:=1 + g.p/(pro.d*pro.d)*pro.ddhp;
          annotation (                                                                    Window(x=0.05, y=0.05, width=0.54, height=0.72), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                    "fonction"),
                Text(extent={{-132,102},{144,42}}, textString=                                                                                                    "%name")}),Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"),       DymolaStoredErrors, Diagram(coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics));
        end gibbsToProps_ph;

        function helmholtzToProps_ph
          input HelmholtzDerivs f
          "dimensionless derivatives of the Helmholtz function";
          output ThermoProperties_ph pro;
      protected
          Real pd;
          Real pt;
      protected
          Real cv "Heat capacity at constant volume";
        algorithm
          pro.d:=f.d;
          pro.T:=f.T;
          pro.s:=f.R*(f.tau*f.ftau - f.f);
          pro.u:=f.R*f.T*f.tau*f.ftau;
          cv:=f.R*(-f.tau*f.tau*f.ftautau);
          pro.cp:=f.R*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
          pd:=f.R*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
          pt:=f.R*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
          pro.ddph:=f.d*(cv*f.d + pt)/(f.d*f.d*pd*cv + f.T*pt*pt);
          pro.ddhp:=-f.d*f.d*pt/(f.d*f.d*pd*cv + f.T*pt*pt);
          annotation(Icon(graphics={
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                   "fonction"),
                Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name")}),Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"),       Diagram(graphics));
        end helmholtzToProps_ph;

        record PhaseBoundaryProperties
        "thermodynamic base properties on the phase boundary"
          extends Modelica.Icons.Record;
          Modelica.SIunits.Density d "density";
          Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
          Modelica.SIunits.SpecificEnergy u "inner energy";
          Modelica.SIunits.SpecificEntropy s "specific entropy";
          Modelica.SIunits.SpecificHeatCapacity cp
          "heat capacity at constant pressure";
          Modelica.SIunits.SpecificHeatCapacity cv
          "heat capacity at constant volume";
          ThermoSysPro.Units.DerPressureByTemperature pt
          "derivative of pressure wrt temperature";
          ThermoSysPro.Units.DerPressureByDensity pd
          "derivative of pressure wrt density";
        end PhaseBoundaryProperties;

        function gibbsToBoundaryProps
        "calulate phase boundary property record from dimensionless Gibbs function"
          extends Modelica.Icons.Function;
          input GibbsDerivs g "dimensionless derivatives of Gibbs function";
          output PhaseBoundaryProperties sat "phase boundary properties";
      protected
          Real vt "derivative of specific volume w.r.t. temperature";
          Real vp "derivative of specific volume w.r.t. pressure";
        algorithm
          sat.d:=g.p/(g.R*g.T*g.pi*g.gpi);
          sat.h:=g.R*g.T*g.tau*g.gtau;
          sat.u:=g.T*g.R*(g.tau*g.gtau - g.pi*g.gpi);
          sat.s:=g.R*(g.tau*g.gtau - g.g);
          sat.cp:=-g.R*g.tau*g.tau*g.gtautau;
          sat.cv:=g.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
          vt:=g.R/g.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
          vp:=g.R*g.T/(g.p*g.p)*g.pi*g.pi*g.gpipi;
          sat.pt:=-g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
          sat.pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        end gibbsToBoundaryProps;

        function helmholtzToBoundaryProps
        "calulate phase boundary property record from dimensionless Helmholtz function"
          extends Modelica.Icons.Function;
          input HelmholtzDerivs f
          "dimensionless derivatives of Helmholtz function";
          output PhaseBoundaryProperties sat "phase boundary property record";
      protected
          SI.Pressure p "pressure";
        algorithm
          p:=f.R*f.d*f.T*f.delta*f.fdelta;
          sat.d:=f.d;
          sat.h:=f.R*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
          sat.s:=f.R*(f.tau*f.ftau - f.f);
          sat.u:=f.R*f.T*f.tau*f.ftau;
          sat.cp:=f.R*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
          sat.cv:=f.R*(-f.tau*f.tau*f.ftautau);
          sat.pt:=f.R*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
          sat.pd:=f.R*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        end helmholtzToBoundaryProps;

        function cv2Phase
          input PhaseBoundaryProperties liq;
          input PhaseBoundaryProperties vap;
          input Real x "Vapor mass fraction";
          input ThermoSysPro.Units.AbsoluteTemperature T;
          input ThermoSysPro.Units.AbsolutePressure p;
          output Modelica.SIunits.SpecificHeatCapacity cv;
      protected
          Real dpT;
          Real dxv;
          Real dvT;
          Real dvTl;
          Real dvTv;
          Real duTl;
          Real duTv;
          Real dxt;
        algorithm
          dxv:=if liq.d <> vap.d then liq.d*vap.d/(liq.d - vap.d) else 0.0;
          dpT:=(vap.s - liq.s)*dxv;
          dvTl:=(liq.pt - dpT)/liq.pd/liq.d/liq.d;
          dvTv:=(vap.pt - dpT)/vap.pd/vap.d/vap.d;
          dxt:=-dxv*(dvTl + x*(dvTv - dvTl));
          duTl:=liq.cv + (T*liq.pt - p)*dvTl;
          duTv:=vap.cv + (T*vap.pt - p)*dvTv;
          cv:=duTl + x*(duTv - duTl) + dxt*(vap.u - liq.u);
          annotation (                                                                    Window(x=0.08, y=0.14, width=0.6, height=0.61), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                    "fonction"),
                Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name")}),Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end cv2Phase;

        record PropThermoSat
          ThermoSysPro.Units.AbsolutePressure P "Pressure";
          ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
          Modelica.SIunits.Density rho "Density";
          ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
          Modelica.SIunits.SpecificHeatCapacity cp
          "Specific heat capacity at constant pressure";
          Real pt "Derivative of pressure wrt. temperature";
          Modelica.SIunits.SpecificHeatCapacity cv
          "Specific heat capacity at constant volume";
          annotation (                                                                    Window(x=0.15, y=0.32, width=0.6, height=0.6), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Rectangle(
                  extent={{-100,50},{100,-100}},
                  lineColor={0,0,255},
                  fillColor={255,255,127},
                  fillPattern=FillPattern.Solid),
                Text(extent={{-127,115},{127,55}}, textString=                                                                                                    "%name"),
                Line(points={{-100,-50},{100,-50}}, color={0,0,0}),
                Line(points={{-100,0},{100,0}}, color={0,0,0}),
                Line(points={{0,50},{0,-100}}, color={0,0,0})}),                                                                                                    Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end PropThermoSat;

        function gibbsPropsSat
          input ThermoSysPro.Units.AbsolutePressure P "Pressure";
          input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
          input GibbsDerivs g "D?riv?es de la fonction de Gibbs" annotation (Placement(
                transformation(extent={{-85,15},{-15,85}}, rotation=0)));
          output PropThermoSat sat annotation (Placement(transformation(extent={{15,
                    15},{85,85}}, rotation=0)));
        algorithm
          sat.P:=max(P, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple);
          sat.T:=max(T, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.Ttriple);
          sat.rho:=sat.P/(ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O*sat.T*g.pi*g.gpi);
          sat.h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O*sat.T*g.tau*g.gtau;
          sat.cp:=-ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O*g.tau*g.tau*g.gtautau;
          annotation (                                                                    Window(x=0.25, y=0.27, width=0.6, height=0.6), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                    "fonction"),
                Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name")}),Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end gibbsPropsSat;

        function gibbsToProps_pT
          input GibbsDerivs g "dimensionless derivatives of the Gibbs funciton";
          output ThermoProperties_pT pro;
      protected
          Real vt;
          Real vp;
        algorithm
          pro.d:=max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple)/(g.R*g.T*g.pi*g.gpi);
          pro.u:=g.T*g.R*(g.tau*g.gtau - g.pi*g.gpi);
          pro.h:=g.R*g.T*g.tau*g.gtau;
          pro.s:=g.R*(g.tau*g.gtau - g.g);
          pro.cp:=-g.R*g.tau*g.tau*g.gtautau;
          vt:=g.R/max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple)*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
          vp:=g.R*g.T/(max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple)*max(g.p, ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple))*g.pi*g.pi*g.gpipi;
          pro.ddpT:=-pro.d*pro.d*vp;
          pro.ddTp:=-pro.d*pro.d*vt;
          pro.duTp:=pro.cp - g.p*vt;
          pro.dupT:=-g.T*vt - g.p*vp;
          annotation (                                                                    Window(x=0.06, y=0.13, width=0.73, height=0.76), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                    "fonction"),
                Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name")}),Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end gibbsToProps_pT;

        record ThermoProperties_pT
          Modelica.SIunits.Density d(min=InitLimits.DMIN, max=InitLimits.DMAX, nominal=InitLimits.DNOM)
          "Density";
          ThermoSysPro.Units.SpecificEnthalpy h(min=InitLimits.SHMIN, max=InitLimits.SHMAX, nominal=InitLimits.SHNOM)
          "Specific enthalpy";
          Modelica.SIunits.SpecificEnergy u(min=InitLimits.SEMIN, max=InitLimits.SEMAX, nominal=InitLimits.SENOM)
          "Specific inner energy";
          Modelica.SIunits.SpecificEntropy s(min=InitLimits.SSMIN, max=InitLimits.SSMAX, nominal=InitLimits.SSNOM)
          "Specific entropy";
          Modelica.SIunits.SpecificHeatCapacity cp(min=InitLimits.CPMIN, max=InitLimits.CPMAX, nominal=InitLimits.CPNOM)
          "Specific heat capacity at constant presure";
          Modelica.SIunits.DerDensityByTemperature ddTp
          "Derivative of the density wrt. temperature at constant pressure";
          Modelica.SIunits.DerDensityByPressure ddpT
          "Derivative of the density wrt. presure at constant temperature";
          Modelica.SIunits.DerEnergyByPressure dupT
          "Derivative of the inner energy wrt. pressure at constant temperature";
          Modelica.SIunits.SpecificHeatCapacity duTp
          "Derivative of the inner energy wrt. temperature at constant pressure";
          ThermoSysPro.Units.MassFraction x "Vapor mass fraction";
          annotation (                                                                    Window(x=0.23, y=0.19, width=0.68, height=0.71), Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Rectangle(
                  extent={{-100,50},{100,-100}},
                  lineColor={0,0,255},
                  fillColor={255,255,127},
                  fillPattern=FillPattern.Solid),
                Text(extent={{-127,115},{127,55}}, textString=                                                                                                    "%name"),
                Line(points={{-100,-50},{100,-50}}, color={0,0,0}),
                Line(points={{-100,0},{100,0}}, color={0,0,0}),
                Line(points={{0,50},{0,-100}}, color={0,0,0})}),                                                                                                    Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end ThermoProperties_pT;

        function helmholtzToProps_pT
          input HelmholtzDerivs f;
          output ThermoProperties_pT pro;
      protected
          Real pd "derivative of pressure wrt. density";
          Real pt "derivative of pressure wrt. temperature";
          Real pv "derivative of pressure wrt. specific volume";
      protected
          Real cv "Heat capacity at constant volume";
        algorithm
          pro.d:=f.d;
          pro.s:=f.R*(f.tau*f.ftau - f.f);
          pro.h:=f.R*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
          pro.u:=f.R*f.T*f.tau*f.ftau;
          pd:=f.R*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
          pt:=f.R*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
          cv:=f.R*(-f.tau*f.tau*f.ftautau);
          pv:=-1/(f.d*f.d)*pd;
          pro.cp:=f.R*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
          pro.ddTp:=-pt/pd;
          pro.ddpT:=1/pd;
          pro.dupT:=(f.d - f.T*pt)/(f.d*f.d*pd);
          pro.duTp:=(-cv*f.d*f.d*pd + pt*f.d - f.T*pt*pt)/(f.d*f.d*pd);
          annotation (                                                                    Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}},
                grid={2,2}), graphics={
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                    "fonction"),
                Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name")}),Window(x=0.32, y=0.14, width=0.6, height=0.6), Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
        end helmholtzToProps_pT;

        record IF97PhaseBoundaryProperties
        "thermodynamic base properties on the phase boundary for IF97 steam tables"
          extends Modelica.Icons.Record;
          Modelica.SIunits.SpecificHeatCapacity R "specific heat capacity";
          Modelica.SIunits.Temperature T "temperature";
          Modelica.SIunits.Density d "density";
          Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
          Modelica.SIunits.SpecificEntropy s "specific entropy";
          Modelica.SIunits.SpecificHeatCapacity cp
          "heat capacity at constant pressure";
          Modelica.SIunits.SpecificHeatCapacity cv
          "heat capacity at constant volume";
          ThermoSysPro.Units.DerPressureByTemperature dpT
          "dp/dT derivative of saturation curve";
          ThermoSysPro.Units.DerPressureByTemperature pt
          "derivative of pressure wrt temperature";
          ThermoSysPro.Units.DerPressureByDensity pd
          "derivative of pressure wrt density";
          Real vt(unit="m3/(kg.K)")
          "derivative of specific volume w.r.t. temperature";
          Real vp(unit="m3/(kg.Pa)")
          "derivative of specific volume w.r.t. pressure";
        end IF97PhaseBoundaryProperties;

        function water_ph_r4
          input ThermoSysPro.Units.AbsolutePressure p;
          input ThermoSysPro.Units.SpecificEnthalpy h;
      protected
          Real x;
          Real dpT;
      public
          output ThermoProperties_ph pro;
      protected
          PhaseBoundaryProperties liq;
          PhaseBoundaryProperties vap;
          GibbsDerivs gl;
          GibbsDerivs gv;
          HelmholtzDerivs fl;
          HelmholtzDerivs fv;
          Modelica.SIunits.Density dl;
          Modelica.SIunits.Density dv;
          Real cv "Heat capacity at constant volume";
        algorithm
          pro.T:=BaseIF97.Basic.tsat(p);
          dpT:=BaseIF97.Basic.dptofT(pro.T);
          dl:=BaseIF97.Regions.rhol_p_R4b(p);
          dv:=BaseIF97.Regions.rhov_p_R4b(p);
          if p < BaseIF97.data.PLIMIT4A then
            gl:=BaseIF97.Basic.g1(p, pro.T);
            gv:=BaseIF97.Basic.g2(p, pro.T);
            liq:=gibbsToBoundaryProps(gl);
            vap:=gibbsToBoundaryProps(gv);
          else
            fl:=BaseIF97.Basic.f3(dl, pro.T);
            fv:=BaseIF97.Basic.f3(dv, pro.T);
            liq:=helmholtzToBoundaryProps(fl);
            vap:=helmholtzToBoundaryProps(fv);
          end if;
          x:=if vap.h <> liq.h then (h - liq.h)/(vap.h - liq.h) else 1.0;
          cv:=cv2Phase(liq=liq, vap=vap, x=x, p=p, T=pro.T);
          pro.d:=liq.d*vap.d/(vap.d + x*(liq.d - vap.d));
          pro.x:=x;
          pro.u:=x*vap.u + (1 - x)*liq.u;
          pro.s:=x*vap.s + (1 - x)*liq.s;
          pro.cp:=x*vap.cp + (1 - x)*liq.cp;
          pro.ddph:=pro.d*(pro.d*cv/dpT + 1.0)/(dpT*pro.T);
          pro.ddhp:=-pro.d*pro.d/(dpT*pro.T);
          annotation(Icon(graphics={
                Text(extent={{-134,104},{142,44}}, textString=  "%name"),
                Ellipse(
                  extent={{-100,40},{100,-100}},
                  lineColor={255,127,0},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-84,-4},{84,-52}},
                  lineColor={255,127,0},
                  textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.2</b></p>
</HTML>
"));
        end water_ph_r4;

        record GibbsDerivs3rd
        "derivatives of dimensionless Gibbs-function w.r.t dimensionless pressure and temperature, including 3rd derivatives"
          extends Modelica.Icons.Record;
          Modelica.SIunits.Pressure p "pressure";
          Modelica.SIunits.Temperature T "temperature";
          Modelica.SIunits.SpecificHeatCapacity R "specific heat capacity";
          Real pi(unit="1") "dimensionless pressure";
          Real tau(unit="1") "dimensionless temperature";
          Real g(unit="1") "dimensionless Gibbs-function";
          Real gpi(unit="1") "derivative of g w.r.t. pi";
          Real gpipi(unit="1") "2nd derivative of g w.r.t. pi";
          Real gpipipi(unit="1") "3rd derivative of g w.r.t. pi";
          Real gtau(unit="1") "derivative of g w.r.t. tau";
          Real gtautau(unit="1") "2nd derivative of g w.r.t tau";
          Real gtautautau(unit="1") "3rd derivative of g w.r.t tau";
          Real gpitau(unit="1") "mixed derivative of g w.r.t. pi and tau";
          Real gpitautau(unit="1")
          "mixed derivative of g w.r.t. pi and tau (2nd)";
          Real gpipitau(unit="1")
          "mixed derivative of g w.r.t. pi (2nd) and tau";
        end GibbsDerivs3rd;

        function gibbsToBoundaryProps3rd
        "calulate phase boundary property record from dimensionless Gibbs function"
          extends Modelica.Icons.Function;
          input ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g
          "dimensionless derivatives of Gibbs function";
          output
          ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd        sat
          "phase boundary properties";
      protected
          Real v "specific volume";
          Real vp3 "Third power of vp";
          Real ivp3 "Inverse of third power of vp";
        algorithm
          sat.d:=g.p/(g.R*g.T*g.pi*g.gpi);
          sat.h:=g.R*g.T*g.tau*g.gtau;
          sat.u:=g.T*g.R*(g.tau*g.gtau - g.pi*g.gpi);
          sat.s:=g.R*(g.tau*g.gtau - g.g);
          sat.cp:=-g.R*g.tau*g.tau*g.gtautau;
          sat.cv:=g.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
          sat.pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
          sat.pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
          v:=1/sat.d;
          sat.vt:=g.R/g.p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
          sat.vp:=g.R*g.T/(g.p*g.p)*g.pi*g.pi*g.gpipi;
          sat.vtt:=g.R*g.pi/g.p*g.tau/g.T*g.tau*g.gpitautau;
          sat.vtp:=g.R*g.pi*g.pi/(g.p*g.p)*(g.gpipi - g.tau*g.gpipitau);
          sat.vpp:=g.R*g.T*g.pi*g.pi*g.pi/(g.p*g.p*g.p)*g.gpipipi;
          sat.cpt:=g.R*g.tau*g.tau/g.T*(2*g.gtautau + g.tau*g.gtautautau);
          vp3:=sat.vp*sat.vp*sat.vp;
          ivp3:=1/vp3;
          sat.ptt:=-(sat.vtt*sat.vp*sat.vp - 2.0*sat.vt*sat.vtp*sat.vp + sat.vt*sat.vt*sat.vpp)*ivp3;
          sat.pdd:=-sat.vpp*ivp3*v*v*v*v - 2*v*sat.pd "= pvv/d^4";
          sat.ptd:=(sat.vtp*sat.vp - sat.vt*sat.vpp)*ivp3/(sat.d*sat.d)
          "= -ptv/d^2";
          sat.cvt:=(vp3*sat.cpt + sat.vp*sat.vp*sat.vt*sat.vt + 3.0*sat.vp*sat.vp*g.T*sat.vt*sat.vtt - 3.0*sat.vtp*sat.vp*g.T*sat.vt*sat.vt + g.T*sat.vt*sat.vt*sat.vt*sat.vpp)*ivp3;
        end gibbsToBoundaryProps3rd;

        record HelmholtzDerivs3rd
        "derivatives of dimensionless Helmholtz-function w.r.t dimensionless pressuredensity and temperature, including 3rd derivatives"
          extends Modelica.Icons.Record;
          Modelica.SIunits.Density d "density";
          Modelica.SIunits.Temperature T "temperature";
          Modelica.SIunits.SpecificHeatCapacity R "specific heat capacity";
          Real delta(unit="1") "dimensionless density";
          Real tau(unit="1") "dimensionless temperature";
          Real f(unit="1") "dimensionless Helmholtz-function";
          Real fdelta(unit="1") "derivative of f w.r.t. delta";
          Real fdeltadelta(unit="1") "2nd derivative of f w.r.t. delta";
          Real fdeltadeltadelta(unit="1") "3rd derivative of f w.r.t. delta";
          Real ftau(unit="1") "derivative of f w.r.t. tau";
          Real ftautau(unit="1") "2nd derivative of f w.r.t. tau";
          Real ftautautau(unit="1") "3rd derivative of f w.r.t. tau";
          Real fdeltatau(unit="1") "mixed derivative of f w.r.t. delta and tau";
          Real fdeltadeltatau(unit="1")
          "mixed derivative of f w.r.t. delta (2nd) and tau";
          Real fdeltatautau(unit="1")
          "mixed derivative of f w.r.t. delta and tau (2nd) ";
        end HelmholtzDerivs3rd;

        function helmholtzToBoundaryProps3rd
        "calulate phase boundary property record from dimensionless Helmholtz function"
          extends Modelica.Icons.Function;
          input ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f
          "dimensionless derivatives of Helmholtz function";
          output
          ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd        sat
          "phase boundary property record";
      protected
          Modelica.SIunits.Pressure p "pressure";
        algorithm
          p:=f.R*f.d*f.T*f.delta*f.fdelta;
          sat.d:=f.d;
          sat.h:=f.R*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
          sat.s:=f.R*(f.tau*f.ftau - f.f);
          sat.u:=f.R*f.T*f.tau*f.ftau;
          sat.cp:=f.R*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
          sat.cv:=f.R*(-f.tau*f.tau*f.ftautau);
          sat.pt:=f.R*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
          sat.pd:=f.R*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
          sat.pdd:=f.R*f.T*f.delta/f.d*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
          sat.ptt:=f.R*f.d*f.delta*f.tau*f.tau/f.T*f.fdeltatautau;
          sat.ptd:=f.R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
          sat.cvt:=f.R*f.tau*f.tau/f.T*(2.0*f.ftautau + f.tau*f.ftautautau);
          annotation(Icon(graphics));
        end helmholtzToBoundaryProps3rd;

        record PhaseBoundaryProperties3rd
        "thermodynamic base properties on the phase boundary"
          extends Modelica.Icons.Record;
          Modelica.SIunits.Temperature T "Temperature";
          ThermoSysPro.Units.DerPressureByTemperature dpT
          "dp/dT derivative of saturation curve";
          Modelica.SIunits.Density d "Density";
          Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          Modelica.SIunits.SpecificEnergy u "Inner energy";
          Modelica.SIunits.SpecificEntropy s "Specific entropy";
          Modelica.SIunits.SpecificHeatCapacity cp
          "Heat capacity at constant pressure";
          Modelica.SIunits.SpecificHeatCapacity cv
          "Heat capacity at constant volume";
          ThermoSysPro.Units.DerPressureByTemperature pt
          "Derivative of pressure wrt temperature";
          ThermoSysPro.Units.DerPressureByDensity pd
          "Derivative of pressure wrt density";
          Real cvt "Derivative of cv w.r.t. temperature";
          Real cpt "Derivative of cp w.r.t. temperature";
          Real ptt "2nd derivative of pressure wrt temperature";
          Real pdd "2nd derivative of pressure wrt density";
          Real ptd
          "Mixed derivative of pressure w.r.t. density and temperature";
          Real vt "Derivative of specific volume w.r.t. temperature";
          Real vp "Derivative of specific volume w.r.t. pressure";
          Real vtt "2nd derivative of specific volume w.r.t. temperature";
          Real vpp "2nd derivative of specific volume w.r.t. pressure";
          Real vtp
          "Mixed derivative of specific volume w.r.t. pressure and temperature";
        end PhaseBoundaryProperties3rd;
        annotation (                                                              Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{0,0},{442,394}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-100,-100},{80,50}},
                lineColor={0,0,255},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
                lineColor={0,0,255},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
                lineColor={0,0,255},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-90,40},{70,10}},
                lineColor={160,160,164},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "Library"),
              Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
              Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
              Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
              Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
              Text(
                extent={{-120,135},{120,70}},
                lineColor={255,0,0},
                textString=                                                                                                    "%name")}),                Window(x=0.45, y=0.01, width=0.35, height=0.49, library=1, autolayout=1), Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
      end Common;

      package IF97_packages

        package IF97_wAJ

          function Water_Ph
            input ThermoSysPro.Units.AbsolutePressure p "Pressure";
            input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
            input Integer mode=0 "IF97 region. 0:automatic";
        protected
            Integer phase;
            Integer region;
            Integer error;
            ThermoSysPro.Units.AbsoluteTemperature T;
            Modelica.SIunits.Density d;
            Boolean supercritical;
        public
            output
            ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph        pro annotation (Placement(
                  transformation(extent={{-90,15},{-43.3333,61.6667}}, rotation=0)));
        protected
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g annotation (Placement(
                  transformation(extent={{-90,-85},{-43.3333,-38.3333}}, rotation=0)));
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f annotation (Placement(
                  transformation(extent={{-23.3333,-85},{23.3333,-38.3333}}, rotation=
                     0)));
          algorithm
            supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
            phase:=if h < ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p) or h > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p) or supercritical then 1 else 2;
            region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase, mode);
            if region == 1 then
              T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
              pro.x:=if supercritical then -1 else 0;
            elseif region == 2 then
              T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
              pro.x:=if supercritical then -1 else 1;

            elseif region == 3 then
              (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=p, h=h, delp=1e-07, delh=1e-06);
              f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_ph(f);
              if h > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.HCRIT then
                pro.x:=if supercritical then -1 else 1;
              else
                pro.x:=if supercritical then -1 else 0;
              end if;

            elseif region == 4 then
              pro:=ThermoSysPro.Properties.WaterSteam.Common.water_ph_r4(p, h);

            elseif region == 5 then
              (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=p, h=h, reldh=1e-07);
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
              pro.x:=if supercritical then -1 else 1;
            else
              assert(false, "Water_Ph: Incorrect region number (" + String(region) + ")");
            end if;
            annotation(derivative(noDerivative=mode)=Water_Ph_der,                                                                      Icon(
                  coordinateSystem(
                  preserveAspectRatio=false,
                  extent={{-100,-100},{100,100}},
                  grid={2,2}), graphics={
                  Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Window(x=0.06, y=0.1, width=0.75, height=0.73), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end Water_Ph;

          function Water_sat_P
            input ThermoSysPro.Units.AbsolutePressure P "Pressure";
        protected
            ThermoSysPro.Units.AbsoluteTemperature T;
        public
            output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation (Placement(
                  transformation(extent={{-85,15},{-15,85}}, rotation=0)));
            output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation (Placement(
                  transformation(extent={{15,15},{85,85}}, rotation=0)));
        protected
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gl annotation (Placement(
                  transformation(extent={{-85,-85},{-15,-15}}, rotation=0)));
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gv annotation (Placement(
                  transformation(extent={{15,-85},{85,-15}}, rotation=0)));
          algorithm
            T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(P);
            gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(P, T);
            lsat:=ThermoSysPro.Properties.WaterSteam.Common.gibbsPropsSat(P, T, gl);
            gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(P, T);
            vsat:=ThermoSysPro.Properties.WaterSteam.Common.gibbsPropsSat(P, T, gv);
            annotation(derivative=Water_sat_P_der,                                                                      Window(x=0.34, y=0.21, width=0.6, height=0.6), Icon(
                  coordinateSystem(
                  preserveAspectRatio=false,
                  extent={{-100,-100},{100,100}},
                  grid={2,2}), graphics={
                  Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end Water_sat_P;

          function SpecificEnthalpy_PT
            input ThermoSysPro.Units.AbsolutePressure p "Pressure";
            input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
            input Integer mode=0 "IF97 region. 0:automatic";
            output ThermoSysPro.Units.SpecificEnthalpy H "Specific enthalpy";
        protected
            ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT pro;
          algorithm
            pro:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Water_PT(p, T, mode);
            H:=pro.h;
            annotation(derivative(noDerivative=mode)=SpecificEnthalpy_PT_der, Icon(graphics=
                   {
                  Text(extent={{-134,104},{142,44}}, textString=                                                         "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end SpecificEnthalpy_PT;

          function Water_PT
            input ThermoSysPro.Units.AbsolutePressure p "Pressure";
            input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
            input Integer mode=0 "IF97 region. 0:automatic";
            output
            ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT        pro;
        protected
            Integer region;
            Boolean supercritical;
            Integer error;
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f;
            Modelica.SIunits.Density d;
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g;
          algorithm
            supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
            region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T, mode);
            if region == 1 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_pT(g);
              pro.x:=if supercritical then -1 else 0;
            elseif region == 2 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_pT(g);
              pro.x:=if supercritical then -1 else 1;

            elseif region == 3 then
              (d,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData.DELP);
              f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_pT(f);
              pro.x:=if supercritical then -1 else 0;

            elseif region == 5 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
              pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_pT(g);
              pro.x:=if supercritical then -1 else 1;
            else
              assert(false, "Water_PT: Incorrect region number");
            end if;
            annotation(derivative(noDerivative=mode)=Water_PT_der, Icon(graphics={
                  Text(extent={{-134,104},{142,44}}, textString=                                              "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end Water_PT;

          function Water_Ph_der "Derivative function of Water_Ph"
            input ThermoSysPro.Units.AbsolutePressure p "Pressure";
            input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
            input Integer mode=0 "R?gion IF97 - 0:calcul automatique";
            input Real p_der "derivative of Pressure";
            input Real h_der "derivative of Specific enthalpy";
            output
            ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph        der_pro
            "Derivative";
        protected
            Integer phase;
            Integer region;
            Boolean supercritical;
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f
            "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
            Modelica.SIunits.Temperature T;
            Modelica.SIunits.SpecificHeatCapacity R "gas constant";
            Modelica.SIunits.Density rho "density";
            Real vt "derivative of specific volume w.r.t. temperature";
            Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
            Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
            Real vp "derivative of specific volume w.r.t. pressure";
            ThermoSysPro.Units.DerPressureByDensity pd
            "derivative of pressure wrt density";
            ThermoSysPro.Units.DerPressureByTemperature pt
            "derivative of pressure wrt temperature";
            Real dpT "dp/dT derivative of saturation curve";
            Real dxv "der of x wrt v";
            Real dvTl "der of v wrt T at boiling";
            Real dvTv "der of v wrt T at dew";
            Real dxT "der of x wrt T";
            Real duTl "der of u wrt T at boiling";
            Real duTv "der of u wrt T at dew";
            Real vtt "2nd derivative of specific volume w.r.t. temperature";
            Real cpt "derivative of cp w.r.t. temperature";
            Real cvt "derivative of cv w.r.t. temperature";
            Real dpTT "2nd der of p wrt T";
            Real dxdd "2nd der of x wrt d";
            Real dxTd "2nd der of x wrt d and T";
            Real dvTTl "2nd der of v wrt T at boiling";
            Real dvTTv "2nd der of v wrt T at dew";
            Real dxTT " 2nd der of x wrt T";
            Real duTTl "2nd der of u wrt T at boiling";
            Real duTTv "2nd der of u wrt T at dew";
            Integer error "error flag for inverse iterations";
            Modelica.SIunits.SpecificEnthalpy h_liq "liquid specific enthalpy";
            Modelica.SIunits.Density d_liq "liquid density";
            Modelica.SIunits.SpecificEnthalpy h_vap "vapour specific enthalpy";
            Modelica.SIunits.Density d_vap "vapour density";
            Real x "dryness fraction";
            ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd
                                                                                 liq
            "phase boundary property record";
            ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd
                                                                                 vap
            "phase boundary property record";
            Modelica.SIunits.Temperature t1
            "temperature at phase boundary, using inverse from region 1";
            Modelica.SIunits.Temperature t2
            "temperature at phase boundary, using inverse from region 2";
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fl
            "dimensionless Helmholtz function and dervatives wrt delta and tau";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fv
            "dimensionless Helmholtz function and dervatives wrt delta and tau";
            Modelica.SIunits.SpecificVolume v;
            Real ptt "2nd derivative of pressure wrt temperature";
            Real pdd "2nd derivative of pressure wrt density";
            Real ptd
            "mixed derivative of pressure w.r.t. density and temperature";
            Real vpp "2nd derivative of specific volume w.r.t. pressure";
            Real vtp
            "mixed derivative of specific volume w.r.t. pressure and temperature";
            Real vp3 "vp^3";
            Real ivp3 "1/vp3";
            Real detPH "Determinant";
            Real dht;
            Real dhd;
            Real ddhp;
            Real ddph;
            Real dtph;
            Real dthp;
            Real detPH_d;
            Real detPH_t;
            Real dhtt;
            Real dhtd;
            Real ddph_t;
            Real ddph_d;
            Real ddhp_t;
            Real ddhp_d;
            Real duhp_t;
            Real duph_t;
            Real duph_d;
            Real dupp;
            Real duph;
            Real duhh;
            Real dcp_d;
            Real rho2 "square of density";
            Real rho3 "cube of density";
            Real cp3 "cube of specific heat capacity";
            Real cpcpp;
            Real quotient;
            Real vt2;
            Real pt2;
            Real pt3;
          algorithm
            supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
            phase:=if h < ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p) or h > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p) or supercritical then 1 else 2;
            region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase, mode);
            R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            if region == 1 then
              T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, T);
              rho:=p/(R*T*g.pi*g.gpi);
              rho2:=rho*rho;
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
              vt2:=vt*vt;
              cp:=-R*g.tau*g.tau*g.gtautau;
              cp3:=cp*cp*cp;
              cpcpp:=cp*cp*p;
              vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
              v:=1/rho;
              vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
              vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
              vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
              cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
              pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
              pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
              vp3:=vp*vp*vp;
              ivp3:=1/vp3;
              ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt2*vpp)*ivp3;
              pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd "= pvv/d^4";
              ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
              cvt:=(vp3*cpt + vp*vp*vt2 + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt2 + T*vt2*vt*vpp)*ivp3;
              detPH:=cp*pd;
              dht:=cv + pt/rho;
              dhd:=(pd - T*pt/rho)/rho;
              ddph:=dht/detPH;
              ddhp:=-pt/detPH;
              dtph:=-dhd/detPH;
              dthp:=pd/detPH;
              detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
              detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
              dhtt:=cvt + ptt*v;
              dhtd:=(ptd - (T*ptt + pt)*v)*v;
              ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
              ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
              ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
              ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
              dupp:=-(2.0*cp3*vp + cp3*p*vpp - 2.0*cp*cp*vt*v - 2.0*cpcpp*vtp*v - cpcpp*vt*vp + 2.0*cp*cp*T*vt2 + 3.0*cpcpp*vt*T*vtp - 4.0*T*vtt*cp*p*vt*v + 3.0*T*T*vtt*cp*p*vt2 + cp*p*vtt/rho2 - cpt*p*vt/rho2 + 2.0*cpt*p*vt2*v*T - cpt*p*vt2*T^2)/cp3;
              duph:=-(vtp*cpcpp + cp*cp*vt - cp*p*vtt*v + 2.0*cp*p*vt*T*vtt + cpt*p*vt*v - cpt*p*vt2*T)/cp3;
              duhh:=-p*(cp*vtt - cpt*vt)/cp3;
              der_pro.x:=0.0;
              der_pro.duhp:=duph*p_der + duhh*h_der;
              der_pro.duph:=dupp*p_der + duph*h_der;
              der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
              der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
              der_pro.cp:=(-(T*vtt*cp + cpt/rho - cpt*T*vt)/cp)*p_der + cpt/cp*h_der;
              der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
              der_pro.u:=(-(p*vp*cp + cp*v - p*vt*v + p*vt2*T)/cp)*p_der + (cp - p*vt)/cp*h_der;
              der_pro.T:=(-v + T*vt)/cp*p_der + 1/cp*h_der;
              der_pro.d:=(-rho2*(vp*cp - vt/rho + T*vt2)/cp)*p_der + (-rho2*vt/cp)*h_der;
            elseif region == 2 then
              T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, T);
              rho:=p/(R*T*g.pi*g.gpi);
              rho2:=rho*rho;
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
              vt2:=vt*vt;
              cp:=-R*g.tau*g.tau*g.gtautau;
              cp3:=cp*cp*cp;
              cpcpp:=cp*cp*p;
              vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
              v:=1/rho;
              vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
              vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
              vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
              cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
              pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
              pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
              vp3:=vp*vp*vp;
              ivp3:=1/vp3;
              ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt2*vpp)*ivp3;
              pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd "= pvv/d^4";
              ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
              cvt:=(vp3*cpt + vp*vp*vt2 + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt2 + T*vt2*vt*vpp)*ivp3;
              detPH:=cp*pd;
              dht:=cv + pt/rho;
              dhd:=(pd - T*pt/rho)/rho;
              ddph:=dht/detPH;
              ddhp:=-pt/detPH;
              dtph:=-dhd/detPH;
              dthp:=pd/detPH;
              detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
              detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
              dhtt:=cvt + ptt*v;
              dhtd:=(ptd - (T*ptt + pt)*v)*v;
              ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
              ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
              ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
              ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
              dupp:=-(2.0*cp3*vp + cp3*p*vpp - 2.0*cp*cp*vt*v - 2.0*cpcpp*vtp*v - cpcpp*vt*vp + 2.0*cp*cp*T*vt2 + 3.0*cpcpp*vt*T*vtp - 4.0*T*vtt*cp*p*vt*v + 3.0*T*T*vtt*cp*p*vt2 + cp*p*vtt/rho2 - cpt*p*vt/rho2 + 2.0*cpt*p*vt2*v*T - cpt*p*vt2*T^2)/cp3;
              duph:=-(vtp*cpcpp + cp*cp*vt - cp*p*vtt*v + 2.0*cp*p*vt*T*vtt + cpt*p*vt*v - cpt*p*vt2*T)/cp3;
              duhh:=-p*(cp*vtt - cpt*vt)/cp3;
              der_pro.x:=0.0;
              der_pro.duhp:=duph*p_der + duhh*h_der;
              der_pro.duph:=dupp*p_der + duph*h_der;
              der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
              der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
              der_pro.cp:=(-(T*vtt*cp + cpt/rho - cpt*T*vt)/cp)*p_der + cpt/cp*h_der;
              der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
              der_pro.u:=(-(p*vp*cp + cp*v - p*vt*v + p*vt2*T)/cp)*p_der + (cp - p*vt)/cp*h_der;
              der_pro.T:=(-v + T*vt)/cp*p_der + 1/cp*h_der;
              der_pro.d:=(-rho2*(vp*cp - vt/rho + T*vt2)/cp)*p_der + (-rho2*vt/cp)*h_der;

            elseif region == 3 then
              (rho,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p, h, delp=1e-07, delh=1e-06);
              f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(rho, T);
              rho2:=rho*rho;
              rho3:=rho*rho2;
              pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              pt2:=pt*pt;
              pt3:=pt2*pt;
              cv:=abs(R*(-f.tau*f.tau*f.ftautau))
              "can be close to neg. infinity near critical point";
              cp:=(rho2*pd*cv + T*pt2)/(rho2*pd);
              pdd:=R*T*f.delta/rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
              ptt:=R*rho*f.delta*f.tau*f.tau/T*f.fdeltatautau;
              ptd:=R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
              cvt:=R*f.tau*f.tau/T*(2.0*f.ftautau + f.tau*f.ftautautau);
              cpt:=(cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2 - cp*ptd)/pd;
              detPH:=cp*pd;
              dht:=cv + pt/rho;
              dhd:=(pd - T*pt/rho)/rho;
              ddph:=dht/detPH;
              ddhp:=-pt/detPH;
              dtph:=-dhd/detPH;
              dthp:=pd/detPH;
              detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
              detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
              dhtt:=cvt + ptt*v;
              dhtd:=(ptd - (T*ptt + pt)*v)*v;
              ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
              ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
              ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
              ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
              dcp_d:=(detPH_d - cp*pdd)/pd;
              quotient:=1/(cv*rho2*pd + T*pt2)^3;
              dupp:=-(-4.0*ptt*p*cv*rho2*pd*T*pt + 2.0*p*cvt*rho2*T*pt2*pd - 2.0*ptt*p*T*pt2*rho*pd + 3.0*p*cv^2*rho3*ptd*T*pt + 3.0*p*cv*rho*T^2*pt2*ptt - 2.0*pt*p*cv*rho3*ptd*pd + 4.0*pt2*p*cv*rho2*ptd*T - 2.0*T^2*pt2*pt3 - 4.0*pt2*cv^2*rho3*pd*T - 4.0*pt3*cv*rho2*T*pd - p*cvt*rho*T^2*pt3 + ptt*p*cv*rho3*pd^2 - 2.0*p*cv^2*rho2*rho2*ptd*pd + 2.0*p*cv*rho2*pt2*pd + 2.0*p*cv*rho*pt3*T - pt*p*cvt*rho3*pd^2 + ptd*p*rho*T*pt3 + 5.0*pt*p*cv^2*rho3*pd + 2*pt*p*cv^2*rho2*rho2*pdd + pt2*p*cv*rho3*pdd + 2.0*pt2*pt2*p*T - 2.0*cv^3*rho3*rho2*pd^2 - 2.0*pt*cv^2*rho2*rho2*pd^2 - 2.0*pt2*pt2*cv*rho*T^2 + 2.0*ptt*p*T^2*pt3 - pt3*p*rho*pd + 2.0*p*cv^3*rho2*rho2*pd + p*cv^3*rho2*rho3*pdd)*quotient/rho;
              duph:=(-2.0*ptt*p*cv*rho2*pd*T*pt + p*cvt*rho2*T*pt2*pd - 2.0*ptt*p*T*pt2*rho*pd - 2.0*pt*p*cv*rho3*ptd*pd + 2.0*pt2*p*cv*rho2*ptd*T - T^2*pt3*pt2 - 2*pt3*cv*rho2*T*pd + ptt*p*cv*rho3*pd^2 - p*cv^2*rho2*rho2*ptd*pd + 2.0*p*cv*rho2*pt2*pd - pt*p*cvt*rho3*pd^2 + ptd*p*rho*T*pt3 + 2.0*pt*p*cv^2*rho3*pd + pt*p*cv^2*rho2*rho2*pdd + pt2*p*cv*rho3*pdd + pt2*pt2*p*T - pt*cv^2*rho2*rho2*pd^2 + ptt*p*T^2*pt3 - pt3*p*rho*pd)*quotient;
              duhh:=p*(-pt3*T*ptd + 2.0*ptd*cv*rho2*pd*pt - 2.0*pt2*cv*rho*pd + pt*cvt*rho2*pd^2 - pt2*cv*rho2*pdd + 2.0*pt2*T*ptt*pd - ptt*cv*rho2*pd^2 + pt3*pd)*rho2*quotient;
              der_pro.x:=0.0;
              der_pro.duhp:=duph*p_der + duhh*h_der;
              der_pro.duph:=dupp*p_der + duph*h_der;
              der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
              der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
              der_pro.cp:=(ddph*dcp_d + dtph*cpt)*p_der + (ddhp*dcp_d + dthp*cpt)*h_der;
              der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
              der_pro.u:=(cv*rho2*pd - pt*p + T*pt2)/(cv*rho2*pd + T*pt2)*h_der + (cv*rho2*pd - p*cv*rho - pt*p + T*pt2)/(rho*(cv*rho2*pd + T*pt2))*p_der;
              der_pro.T:=(-rho*pd + T*pt)/(rho2*pd*cv + T*pt*pt)*p_der + rho2*pd/(rho2*pd*cv + T*pt2)*h_der;
              der_pro.d:=rho*(cv*rho + pt)/(rho2*pd*cv + T*pt2)*p_der + (-rho2*pt/(rho2*pd*cv + T*pt2))*h_der;

            elseif region == 4 then
              h_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p);
              h_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p);
              x:=if h_vap <> h_liq then (h - h_liq)/(h_vap - h_liq) else 1.0;
              if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
                t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h_liq);
                t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h_vap);
                gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, t1);
                gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, t2);
                liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gl);
                vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gv);
                T:=t1 + x*(t2 - t1);
              else
                T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(p);
                d_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_T(T);
                d_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_T(T);
                fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_liq, T);
                fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_vap, T);
                liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fl);
                vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fv);
              end if;
              rho:=liq.d*vap.d/(vap.d + x*(liq.d - vap.d));
              rho2:=rho*rho;
              rho3:=rho*rho2;
              v:=1/rho;
              dxv:=if liq.d <> vap.d then liq.d*vap.d/(liq.d - vap.d) else 0.0;
              dpT:=if liq.d <> vap.d then (vap.s - liq.s)*dxv else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
              dvTl:=(liq.pt - dpT)/(liq.pd*liq.d*liq.d);
              dvTv:=(vap.pt - dpT)/(vap.pd*vap.d*vap.d);
              dxT:=-dxv*(dvTl + x*(dvTv - dvTl));
              duTl:=liq.cv + (T*liq.pt - p)*dvTl;
              duTv:=vap.cv + (T*vap.pt - p)*dvTv;
              cv:=duTl + x*(duTv - duTl) + dxT*(vap.u - liq.u);
              dpTT:=dxv*(vap.cv/T - liq.cv/T + dvTv*(vap.pt - dpT) - dvTl*(liq.pt - dpT));
              dxdd:=2.0*dxv/rho3;
              dxTd:=dxv*dxv*(dvTv - dvTl)/rho2;
              dvTTl:=((liq.ptt - dpTT)/(liq.d*liq.d) + dvTl*(liq.d*dvTl*(2.0*liq.pd + liq.d*liq.pdd) - 2.0*liq.ptd))/liq.pd;
              dvTTv:=((vap.ptt - dpTT)/(vap.d*vap.d) + dvTv*(vap.d*dvTv*(2.0*vap.pd + vap.d*vap.pdd) - 2.0*vap.ptd))/vap.pd;
              dxTT:=-dxv*(2.0*dxT*(dvTv - dvTl) + dvTTl + x*(dvTTv - dvTTl));
              duTTl:=liq.cvt + (liq.pt - dpT + T*(2.0*liq.ptt - liq.d*liq.d*liq.ptd*dvTl))*dvTl + (T*liq.pt - p)*dvTTl;
              duTTv:=vap.cvt + (vap.pt - dpT + T*(2.0*vap.ptt - vap.d*vap.d*vap.ptd*dvTv))*dvTv + (T*vap.pt - p)*dvTTv;
              cvt:=duTTl + x*(duTTv - duTTl) + 2.0*dxT*(duTv - duTl) + dxTT*(vap.u - liq.u);
              ptt:=dpTT;
              dht:=cv + dpT*v;
              dhd:=-T*dpT*v*v;
              detPH:=-dpT*dhd;
              dtph:=1.0/dpT;
              ddph:=dht/detPH;
              ddhp:=-dpT/detPH;
              detPH_d:=-2.0*v;
              detPH_t:=2.0*ptt/dpT + 1.0/T;
              dhtt:=cvt + ptt*v;
              dhtd:=-(T*ptt + dpT)*v*v;
              ddhp_t:=ddhp*(ptt/dpT - detPH_t);
              ddhp_d:=ddhp*(-detPH_d);
              ddph_t:=ddph*(dhtt/dht - detPH_t);
              ddph_d:=ddph*(dhtd/dht - detPH_d);
              duhp_t:=(ddhp*dpT + p*ddhp_t)/rho2;
              duph_t:=(ddph*dpT + p*ddph_t)/rho2;
              duph_d:=((-2.0*ddph/rho + ddph_d)*p + 1.0)/rho2;
              der_pro.x:=if h_vap <> h_liq then h_der/(h_vap - h_liq) else 0.0;
              der_pro.duhp:=dtph*duhp_t*p_der;
              der_pro.duph:=(ddph*duph_d + dtph*duph_t)*p_der + dtph*duhp_t*h_der;
              der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + ddhp*ddph_d*h_der;
              der_pro.ddhp:=ddhp*ddhp_d*h_der + ddhp*ddph_d*p_der;
              der_pro.cp:=0.0;
              der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
              der_pro.u:=(ddph*p/rho - 1.0)/rho*p_der + (ddhp*p/rho2 + 1.0)*h_der;
              der_pro.T:=1/dpT*p_der;
              der_pro.d:=rho*(rho*cv/dpT + 1.0)/(dpT*T)*p_der + (-rho2/(dpT*T))*h_der;

            elseif region == 5 then
              (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p, h, reldh=1e-07);
              assert(error == 0, "error in inverse iteration of steam tables");
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, T);
              rho:=p/(R*T*g.pi*g.gpi);
              rho2:=rho*rho;
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
              vt2:=vt*vt;
              cp:=-R*g.tau*g.tau*g.gtautau;
              cp3:=cp*cp*cp;
              cpcpp:=cp*cp*p;
              vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
              v:=1/rho;
              vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
              vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
              vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
              cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
              pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
              pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
              vp3:=vp*vp*vp;
              ivp3:=1/vp3;
              ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt2*vpp)*ivp3;
              pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd "= pvv/d^4";
              ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
              cvt:=(vp3*cpt + vp*vp*vt2 + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt2 + T*vt2*vt*vpp)*ivp3;
              detPH:=cp*pd;
              dht:=cv + pt/rho;
              dhd:=(pd - T*pt/rho)/rho;
              ddph:=dht/detPH;
              ddhp:=-pt/detPH;
              dtph:=-dhd/detPH;
              dthp:=pd/detPH;
              detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
              detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
              dhtt:=cvt + ptt*v;
              dhtd:=(ptd - (T*ptt + pt)*v)*v;
              ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
              ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
              ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
              ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
              dupp:=-(2.0*cp3*vp + cp3*p*vpp - 2.0*cp*cp*vt*v - 2.0*cpcpp*vtp*v - cpcpp*vt*vp + 2.0*cp*cp*T*vt2 + 3.0*cpcpp*vt*T*vtp - 4.0*T*vtt*cp*p*vt*v + 3.0*T*T*vtt*cp*p*vt2 + cp*p*vtt/rho2 - cpt*p*vt/rho2 + 2.0*cpt*p*vt2*v*T - cpt*p*vt2*T^2)/cp3;
              duph:=-(vtp*cpcpp + cp*cp*vt - cp*p*vtt*v + 2.0*cp*p*vt*T*vtt + cpt*p*vt*v - cpt*p*vt2*T)/cp3;
              duhh:=-p*(cp*vtt - cpt*vt)/cp3;
              der_pro.x:=0.0;
              der_pro.duhp:=duph*p_der + duhh*h_der;
              der_pro.duph:=dupp*p_der + duph*h_der;
              der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
              der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
              der_pro.cp:=(-(T*vtt*cp + cpt/rho - cpt*T*vt)/cp)*p_der + cpt/cp*h_der;
              der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
              der_pro.u:=(-(p*vp*cp + cp*v - p*vt*v + p*vt2*T)/cp)*p_der + (cp - p*vt)/cp*h_der;
              der_pro.T:=(-v + T*vt)/cp*p_der + 1/cp*h_der;
              der_pro.d:=(-rho2*(vp*cp - vt/rho + T*vt2)/cp)*p_der + (-rho2*vt/cp)*h_der;
            else
              assert(false, "Water_Ph_der: Incorrect region number");
            end if;
            annotation (                                                                    Window(x=0.22, y=0.2, width=0.6, height=0.6), Icon(
                  coordinateSystem(
                  preserveAspectRatio=false,
                  extent={{-100,-100},{100,100}},
                  grid={2,2}), graphics={
                  Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end Water_Ph_der;

          function Water_PT_der
            input ThermoSysPro.Units.AbsolutePressure p "pressure";
            input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
            input Integer mode=0 "R?gion IF97 - 0:calcul automatique";
            input Real p_der "Pression";
            input Real T_der "Temp?rature";
            output
            ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT        pro_der;
        protected
            Integer region;
            Boolean supercritical;
            Integer error;
            Modelica.SIunits.Density d;
            Modelica.SIunits.Pressure p_aux "pressure";
            Modelica.SIunits.Temperature T_aux "temperature";
            Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
            Modelica.SIunits.SpecificHeatCapacity R "gas constant";
            Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
            Real cpt "derivative of cp w.r.t. temperature";
            Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
            Real cvt "derivative of cv w.r.t. temperature";
            Modelica.SIunits.Density rho "density";
            Modelica.SIunits.SpecificEntropy s "specific entropy";
            ThermoSysPro.Units.DerPressureByTemperature pt
            "derivative of pressure wrt temperature";
            ThermoSysPro.Units.DerPressureByDensity pd
            "derivative of pressure wrt density";
            Real ptt "2nd derivative of pressure wrt temperature";
            Real pdd "2nd derivative of pressure wrt density";
            Real ptd
            "mixed derivative of pressure w.r.t. density and temperature";
            Real vt "derivative of specific volume w.r.t. temperature";
            Real vp "derivative of specific volume w.r.t. pressure";
            Real vtt "2nd derivative of specific volume w.r.t. temperature";
            Real vpp "2nd derivative of specific volume w.r.t. pressure";
            Real vtp
            "mixed derivative of specific volume w.r.t. pressure and temperature";
            Real x "dryness fraction";
            Real dpT "dp/dT derivative of saturation curve";
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f
            "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
            Real vp3 "vp^3";
            Real ivp3 "1/vp3";
            Modelica.SIunits.SpecificVolume v;
            Real rho2;
            Real quotient;
            Real quotient2;
            Real pd2;
            Real pd3;
            Real pt2;
            Real pt3;
          algorithm
            supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
            region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T, mode);
            R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            if region == 1 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, T);
              x:=0.0;
              h:=R*T*g.tau*g.gtau;
              s:=R*(g.tau*g.gtau - g.g);
              rho:=p/(R*T*g.pi*g.gpi);
              rho2:=rho*rho;
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
              vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
              cp:=-R*g.tau*g.tau*g.gtautau;
              cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
              vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
              vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
              vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
              cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
              pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
              pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
              v:=1/rho;
              vp3:=vp*vp*vp;
              ivp3:=1/vp3;
              ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt*vt*vpp)*ivp3;
              pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd;
              ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
              cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
              pro_der.x:=0;
              pro_der.duTp:=(-vt - T*vtt - p*vtp)*p_der + (cpt - p*vtt)*T_der;
              pro_der.dupT:=(-T*vtp - vp - p*vpp)*p_der + (-vt - T*vtt - p*vtp)*T_der;
              pro_der.ddpT:=-rho2*(vpp*p_der + vtp*T_der);
              pro_der.ddTp:=-rho2*(vtp*p_der + vtt*T_der);
              pro_der.cp:=(-T*vtt)*p_der + cpt*T_der;
              pro_der.s:=(-vt)*p_der + cp/T*T_der;
              pro_der.u:=(v - T*vt)*p_der + (cp - p*vt)*T_der;
              pro_der.h:=(v - T*vt)*p_der + cp*T_der;
              pro_der.d:=-rho2*(vp*p_der + vt*T_der);
            elseif region == 2 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, T);
              x:=1.0;
              h:=R*T*g.tau*g.gtau;
              s:=R*(g.tau*g.gtau - g.g);
              rho:=p/(R*T*g.pi*g.gpi);
              rho2:=rho*rho;
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
              vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
              cp:=-R*g.tau*g.tau*g.gtautau;
              cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
              vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
              vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
              vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
              cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
              pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
              pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
              v:=1/rho;
              vp3:=vp*vp*vp;
              ivp3:=1/vp3;
              ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt*vt*vpp)*ivp3;
              pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd;
              ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
              cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
              pro_der.x:=0;
              pro_der.duTp:=(-vt - T*vtt - p*vtp)*p_der + (cpt - p*vtt)*T_der;
              pro_der.dupT:=(-T*vtp - vp - p*vpp)*p_der + (-vt - T*vtt - p*vtp)*T_der;
              pro_der.ddpT:=-rho2*(vpp*p_der + vtp*T_der);
              pro_der.ddTp:=-rho2*(vtp*p_der + vtt*T_der);
              pro_der.cp:=(-T*vtt)*p_der + cpt*T_der;
              pro_der.s:=(-vt)*p_der + cp/T*T_der;
              pro_der.u:=(v - T*vt)*p_der + (cp - p*vt)*T_der;
              pro_der.h:=(v - T*vt)*p_der + cp*T_der;
              pro_der.d:=-rho2*(vp*p_der + vt*T_der);

            elseif region == 3 then
              (rho,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p, T, delp=1e-07);
              f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(rho, T);
              rho2:=rho*rho;
              h:=R*T*(f.tau*f.ftau + f.delta*f.fdelta);
              s:=R*(f.tau*f.ftau - f.f);
              pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              pd2:=pd*pd;
              pd3:=pd*pd2;
              pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              pt2:=pt*pt;
              pt3:=pt*pt*pt;
              cv:=R*(-f.tau*f.tau*f.ftautau);
              x:=0.0;
              pdd:=R*T*f.delta/rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
              ptt:=R*rho*f.delta*f.tau*f.tau/T*f.fdeltatautau;
              ptd:=R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
              cvt:=R*f.tau*f.tau/T*(2.0*f.ftautau + f.tau*f.ftautautau);
              cpt:=(cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2 - pt*ptd)/pd;
              pro_der.x:=0;
              quotient:=1/(rho2*pd);
              quotient2:=quotient/(rho*pd2);
              pro_der.duTp:=quotient2*(-(rho*pd2*T*ptt + ptd*rho*pd*p - 2.0*rho*pd*pt*T*ptd + rho*pd2*pt - 2.0*pt*pd*p + 2.0*pd*pt2*T - pt*pdd*rho*p + pdd*rho*pt2*T)*p_der + (rho2*rho*pd3*cvt - rho*pd2*ptt*p + 3.0*rho*pd2*pt*T*ptt + 2.0*ptd*rho*pd*pt*p - 3.0*ptd*rho*pd*pt2*T + rho*pd2*pt2 - 2.0*pt2*pd*p + 2.0*T*pt3*pd - pt2*pdd*rho*p + T*pt3*pdd*rho)*T_der);
              pro_der.dupT:=quotient2*((rho*pd2 - rho*pd*T*ptd - 2.0*pd*p + 2.0*pd*T*pt - pdd*rho*p + pdd*rho*T*pt)*p_der - (rho*pd2*T*ptt + ptd*rho*pd*p - 2.0*rho*pd*pt*T*ptd + rho*pd2*pt - 2.0*pt*pd*p + 2.0*pd*pt2*T - pt*pdd*rho*p + pdd*rho*pt2*T)*T_der);
              pro_der.ddpT:=-1/pd3*(pdd*p_der + (ptd*pd - pt*pdd)*T_der);
              pro_der.ddTp:=-1/pd3*((ptd*pd - pt*pdd)*p_der + (ptt*pd2 - 2.0*pt*ptd*pd + pt2*pdd)*T_der);
              pro_der.cp:=quotient2*(-T*(rho*pd2*ptt - 2.0*rho*pd*pt*ptd + 2.0*pd*pt2 + pdd*rho*pt^2)*p_der + (rho2*rho*pd3*cvt + 3.0*rho*pd2*pt*T*ptt + rho*pd2*pt2 - 3.0*ptd*rho*pd*pt2*T + 2.0*T*pt3*pd + T*pt3*pdd*rho)*T_der);
              pro_der.s:=quotient*(-pt*p_der + (cv*rho2*pd/T + pt2)*T_der);
              pro_der.u:=quotient*(-(-rho*pd + T*pt)*p_der + (cv*rho2*pd - pt*p + pt2*T)*T_der);
              pro_der.h:=quotient*((-rho*pd + T*pt)*p_der + (rho2*pd*cv + T*pt*pt)*T_der);
              pro_der.d:=1/pd*(p_der - pt*T_der);

            elseif region == 5 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, T);
              x:=1.0;
              h:=R*T*g.tau*g.gtau;
              s:=R*(g.tau*g.gtau - g.g);
              rho:=p/(R*T*g.pi*g.gpi);
              rho2:=rho*rho;
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
              vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
              cp:=-R*g.tau*g.tau*g.gtautau;
              cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
              vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
              vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
              vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
              cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
              pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
              pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
              v:=1/rho;
              vp3:=vp*vp*vp;
              ivp3:=1/vp3;
              ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt*vt*vpp)*ivp3;
              pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd;
              ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
              cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
              pro_der.x:=0;
              pro_der.duTp:=(-vt - T*vtt - p*vtp)*p_der + (cpt - p*vtt)*T_der;
              pro_der.dupT:=(-T*vtp - vp - p*vpp)*p_der + (-vt - T*vtt - p*vtp)*T_der;
              pro_der.ddpT:=-rho2*(vpp*p_der + vtp*T_der);
              pro_der.ddTp:=-rho2*(vtp*p_der + vtt*T_der);
              pro_der.cp:=(-T*vtt)*p_der + cpt*T_der;
              pro_der.s:=(-vt)*p_der + cp/T*T_der;
              pro_der.u:=(v - T*vt)*p_der + (cp - p*vt)*T_der;
              pro_der.h:=(v - T*vt)*p_der + cp*T_der;
              pro_der.d:=-rho2*(vp*p_der + vt*T_der);
            else
              assert(false, "Water_pT_der: error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ", region = " + String(region) + ")");
            end if;
            annotation(Icon(graphics={
                  Text(extent={{-134,104},{142,44}}, textString=  "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end Water_PT_der;

          function Water_sat_P_der
            input ThermoSysPro.Units.AbsolutePressure P "Pression";
            input Real P_der "derivative of pressure";
        protected
            ThermoSysPro.Units.AbsoluteTemperature T;
            ThermoSysPro.Units.DerPressureByTemperature dpT
            "dp/dT derivative of saturation curve";
            Modelica.SIunits.Density d "density";
            Modelica.SIunits.SpecificHeatCapacity cp
            "Chaleur sp?cifique ? pression constante";
            Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
            Real vt(unit="m3/(kg.K)")
            "derivative of specific volume w.r.t. temperature";
            Real vp(unit="m3/(kg.Pa)")
            "derivative of specific volume w.r.t. pressure";
            ThermoSysPro.Units.DerPressureByDensity pd
            "Derivative of pressure wrt density";
            Real vp3 "Third power of vp";
            Real ivp3 "Inverse of third power of vp";
            Real cvt "Derivative of cv w.r.t. temperature";
            Real cpt "Derivative of cp w.r.t. temperature";
            Real ptt "2nd derivative of pressure wrt temperature";
            Real vtt "2nd derivative of specific volume w.r.t. temperature";
            Real vpp "2nd derivative of specific volume w.r.t. pressure";
            Real vtp
            "Mixed derivative of specific volume w.r.t. pressure and temperature";
            Real v "specific volume";
            Real pv;
            Real tp;
            Real p2;
            Real pi2;
        public
            output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat dlsat annotation (Placement(
                  transformation(extent={{-85,15},{-15,85}}, rotation=0)));
            output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat dvsat annotation (Placement(
                  transformation(extent={{15,15},{85,85}}, rotation=0)));
        protected
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl annotation (Placement(
                  transformation(extent={{-85,-85},{-15,-15}}, rotation=0)));
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv annotation (Placement(
                  transformation(extent={{15,-85},{85,-15}}, rotation=0)));
          algorithm
            T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(P);
            gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(P, T);
            gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(P, T);
            dpT:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
            ptt:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.d2ptofT(T);
            tp:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dtsatofp(P);
            p2:=gl.p*gl.p;
            pi2:=gl.pi*gl.pi;
            d:=gl.p/(gl.R*T*gl.pi*gl.gpi);
            vp:=gl.R*T/p2*pi2*gl.gpipi;
            vt:=gl.R/gl.p*gl.pi*(gl.gpi - gl.tau*gl.gpitau);
            cp:=-gl.R*gl.tau*gl.tau*gl.gtautau;
            v:=1/d;
            cv:=gl.R*(-gl.tau*gl.tau*gl.gtautau + (gl.gpi - gl.tau*gl.gpitau)*(gl.gpi - gl.tau*gl.gpitau)/gl.gpipi);
            pd:=-gl.R*T*gl.gpi*gl.gpi/gl.gpipi;
            pv:=-pd*d*d;
            vtt:=gl.R*gl.pi/gl.p*gl.tau/T*gl.tau*gl.gpitautau;
            vtp:=gl.R*pi2/p2*(gl.gpipi - gl.tau*gl.gpipitau);
            vpp:=gl.R*T*pi2*gl.pi/(p2*gl.p)*gl.gpipipi;
            vp3:=vp*vp*vp;
            ivp3:=1/vp3;
            cpt:=gl.R*gl.tau*gl.tau/T*(2*gl.gtautau + gl.tau*gl.gtautautau);
            cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
            dlsat.pt:=ptt*tp*P_der;
            dlsat.cv:=cvt*tp*P_der;
            dlsat.cp:=(cvt*tp + vp*dpT + ((v*pv + T*dpT)*vtp + (vp*pv + tp*dpT)*vt))*P_der;
            dlsat.h:=(v - T*vt)*P_der + cp/dpT*P_der;
            dlsat.rho:=-d*d*(vp + vt/dpT)*P_der;
            dlsat.T:=tp*P_der;
            dlsat.P:=P_der;
            p2:=gv.p*gv.p;
            pi2:=gv.pi*gv.pi;
            d:=gv.p/(gv.R*T*gv.pi*gv.gpi);
            vp:=gv.R*T/p2*pi2*gv.gpipi;
            vt:=gv.R/gv.p*gv.pi*(gv.gpi - gv.tau*gv.gpitau);
            cp:=-gv.R*gv.tau*gv.tau*gv.gtautau;
            v:=1/d;
            cv:=gv.R*(-gv.tau*gv.tau*gv.gtautau + (gv.gpi - gv.tau*gv.gpitau)*(gv.gpi - gv.tau*gv.gpitau)/gv.gpipi);
            pd:=-gv.R*T*gv.gpi*gv.gpi/gv.gpipi;
            pv:=-pd*d*d;
            vtt:=gv.R*gv.pi/gv.p*gv.tau/T*gv.tau*gv.gpitautau;
            vtp:=gv.R*pi2/p2*(gv.gpipi - gv.tau*gv.gpipitau);
            vpp:=gv.R*T*pi2*gv.pi/(p2*gv.p)*gv.gpipipi;
            vp3:=vp*vp*vp;
            ivp3:=1/vp3;
            cpt:=gv.R*gv.tau*gv.tau/T*(2*gv.gtautau + gv.tau*gv.gtautautau);
            cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
            dvsat.pt:=ptt*tp*P_der;
            dvsat.cv:=cvt*tp*P_der;
            dvsat.cp:=(cvt*tp + vp*dpT + ((v*pv + T*dpT)*vtp + (vp*pv + tp*dpT)*vt))*P_der;
            dvsat.h:=(v - T*vt)*P_der + cp/dpT*P_der;
            dvsat.rho:=-d*d*(vp + vt/dpT)*P_der;
            dvsat.T:=tp*P_der;
            dvsat.P:=P_der;
            annotation (                                                                    Window(x=0.34, y=0.21, width=0.6, height=0.6), Icon(
                  coordinateSystem(
                  preserveAspectRatio=false,
                  extent={{-100,-100},{100,100}},
                  grid={2,2}), graphics={
                  Text(extent={{-134,104},{142,44}}, textString=                                                                                                    "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end Water_sat_P_der;

          function SpecificEnthalpy_PT_der
            input ThermoSysPro.Units.AbsolutePressure p "pressure";
            input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
            input Integer mode=0 "R?gion IF97 - 0:calcul automatique";
            input Real p_der "Pression";
            input Real T_der "Temp?rature";
            output Real H "specific enthalpy";
        protected
            Integer region;
            Boolean supercritical;
            Integer error;
            Modelica.SIunits.SpecificHeatCapacity R "gas constant";
            Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
            Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
            Modelica.SIunits.Density rho "density";
            ThermoSysPro.Units.DerPressureByTemperature pt
            "derivative of pressure wrt temperature";
            ThermoSysPro.Units.DerPressureByDensity pd
            "derivative of pressure wrt density";
            Real vt "derivative of specific volume w.r.t. temperature";
            ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g
            "dimensionless Gibbs funcion and dervatives wrt pi and tau";
            ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f
            "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
            Real rho2;
          algorithm
            supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
            region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T, mode);
            R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
            if region == 1 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
              rho:=p/(R*T*g.pi*g.gpi);
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              cp:=-R*g.tau*g.tau*g.gtautau;
              H:=(1/rho - T*vt)*p_der + cp*T_der;
            elseif region == 2 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
              rho:=p/(R*T*g.pi*g.gpi);
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              cp:=-R*g.tau*g.tau*g.gtautau;
              H:=(1/rho - T*vt)*p_der + cp*T_der;

            elseif region == 3 then
              (rho,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p, T, delp=1e-07);
              rho2:=rho*rho;
              f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(rho, T);
              pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              cv:=R*(-f.tau*f.tau*f.ftautau);
              H:=1/(rho2*pd)*((-rho*pd + T*pt)*p_der + (rho2*pd*cv + T*pt*p)*T_der);

            elseif region == 5 then
              g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
              rho:=p/(R*T*g.pi*g.gpi);
              vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              cp:=-R*g.tau*g.tau*g.gtautau;
              H:=(1/rho - T*vt)*p_der + cp*T_der;
            else
              assert(false, "Water_pT_der: error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ", region = " + String(region) + ")");
            end if;
            annotation(Icon(graphics={
                  Text(extent={{-134,104},{142,44}}, textString=  "%name"),
                  Ellipse(
                    extent={{-100,40},{100,-100}},
                    lineColor={255,127,0},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Text(
                    extent={{-84,-4},{84,-52}},
                    lineColor={255,127,0},
                    textString=                                                                                                    "fonction")}),                 Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
          end SpecificEnthalpy_PT_der;
          annotation (                                                              Icon(
                coordinateSystem(
                preserveAspectRatio=false,
                extent={{0,0},{312,220}},
                grid={2,2}), graphics={
                Rectangle(
                  extent={{-100,-100},{80,50}},
                  lineColor={0,0,255},
                  fillColor={235,235,235},
                  fillPattern=FillPattern.Solid),
                Polygon(
                  points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
                  lineColor={0,0,255},
                  fillColor={235,235,235},
                  fillPattern=FillPattern.Solid),
                Polygon(
                  points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
                  lineColor={0,0,255},
                  fillColor={235,235,235},
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-90,40},{70,10}},
                  lineColor={160,160,164},
                  fillColor={0,0,0},
                  fillPattern=FillPattern.Solid,
                  textString=                                                                                                    "Library"),
                Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
                Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
                Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
                Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
                Text(
                  extent={{-116,133},{124,68}},
                  lineColor={255,0,0},
                  textString=                                                                                                    "%name")}),                Window(x=0.05, y=0.51, width=0.25, height=0.26, library=1, autolayout=1), Documentation(info="<html>
<p><b>Version 1.2</b></p>
</HTML>
"));
        end IF97_wAJ;
      end IF97_packages;

      package InitLimits

        constant Real MINPOS=1e-09
        "minimal value for physical variables which are always > 0.0";

        constant Modelica.SIunits.Density DMIN=MINPOS "Minimum density";

        constant Modelica.SIunits.Density DMAX=100000.0 "Maximum densitye";

        constant Modelica.SIunits.Density DNOM=998.0 "Nominal density";

        constant Modelica.SIunits.SpecificEnergy SEMIN=-100000000.0
        "Minimum specific energy";

        constant Modelica.SIunits.SpecificEnergy SEMAX=100000000.0
        "Maximum specific energy";

        constant Modelica.SIunits.SpecificEnergy SENOM=1000000.0
        "Nominal specific energy";

        constant ThermoSysPro.Units.SpecificEnthalpy SHMIN=-1000000.0
        "Minimum specific enthalpy";

        constant ThermoSysPro.Units.SpecificEnthalpy SHMAX=100000000.0
        "Maximum specific enthalpy";

        constant ThermoSysPro.Units.SpecificEnthalpy SHNOM=1000000.0
        "Nominal specific enthalpy";

        constant Modelica.SIunits.SpecificEntropy SSMIN=-1000000.0
        "Minimum specific entropy";

        constant Modelica.SIunits.SpecificEntropy SSMAX=1000000.0
        "Maximum specific entropy";

        constant Modelica.SIunits.SpecificEntropy SSNOM=1000.0
        "Nominal specific entropy";

        constant Modelica.SIunits.SpecificHeatCapacity CPMIN=MINPOS
        "Minimum specific heat capacity";

        constant Modelica.SIunits.SpecificHeatCapacity CPMAX=Modelica.Constants.inf
        "Maximum specific heat capacity";

        constant Modelica.SIunits.SpecificHeatCapacity CPNOM=1000.0
        "Nominal specific heat capacity";

        constant ThermoSysPro.Units.AbsoluteTemperature TMIN=200
        "Minimum temperature";

        constant ThermoSysPro.Units.AbsoluteTemperature TMAX=6000
        "Maximum temperature";

        constant ThermoSysPro.Units.AbsoluteTemperature TNOM=320.0
        "Nominal temperature";
        annotation(Icon(graphics={
              Text(
                extent={{-120,135},{120,70}},
                lineColor={255,0,0},
                textString=                                   "%name"),
              Rectangle(
                extent={{-100,-100},{80,50}},
                lineColor={0,0,255},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
                lineColor={0,0,255},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
                lineColor={0,0,255},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-90,40},{70,10}},
                lineColor={160,160,164},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "Library"),
              Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
              Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
              Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
              Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0})}),                                                                                                    Window(x=0.45, y=0.01, width=0.51, height=0.74, library=1, autolayout=1), Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library  (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
      end InitLimits;
      annotation (                                                              Icon(
          coordinateSystem(
          preserveAspectRatio=false,
          extent={{0,0},{312,210}},
          grid={2,2}), graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-110,125},{130,60}},
            lineColor={255,0,0},
            textString=                                                                                                    "%name"),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            textString=                                                                                                    "Library"),
          Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
          Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
          Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
          Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0})}),                                                                                                    Window(x=0.05, y=0.26, width=0.25, height=0.25, library=1, autolayout=1), Documentation(info="<html>
<p><b>Version 1.2</b></p>
</HTML>
"));
    end WaterSteam;
  end Properties;

  package Units "Additional SI and non-SI units"

    type DerPressureByDensity =Real(final quantity="DerPressureByDensity", final unit="Pa.m3/kg");

    type DerPressureByTemperature =Real(final quantity="DerPressureByTemperature", final unit="Pa/K");

    type MassFraction =Real(final quantity="Mass fraction", final unit="1");

    type AbsoluteTemperature =Modelica.SIunits.Temperature(nominal=500, start=300, min=200, max=6000);

    type AbsolutePressure =Modelica.SIunits.AbsolutePressure(nominal=1000000.0, start=100000.0, min=100, max=1000000000.0);

    type SpecificEnthalpy =Modelica.SIunits.SpecificEnthalpy(nominal=1500000.0, start=1000000.0, min=-1000000.0, max=100000000.0);

    type DifferentialPressure =Modelica.SIunits.AbsolutePressure(nominal=100000.0, start=100000.0, min=-1000000000.0, max=1000000000.0);
    annotation(Icon(graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            lineColor={0,0,255},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-120,135},{120,70}},
            lineColor={255,0,0},
            textString =                                                                                                    "%name"),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            textString =                                                                                                    "Unites"),
          Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
          Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
          Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
          Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0})}),                                                                                                    Documentation(info="<html>
</html>"));
  end Units;

  package WaterSteam "Water/steam components library"

    package BoundaryConditions "Boundary conditions"

      model Sink "Water/steam sink"
        parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000
        "Fluid specific enthalpy (active if IEnthalpy connector is not connected)";
        ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
        Modelica.SIunits.MassFlowRate Q "Mass flow rate";
        ThermoSysPro.Units.SpecificEnthalpy h "Fluid specific enthalpy";
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation (Placement(
              transformation(
              origin={0,-50},
              extent={{10,-10},{-10,10}},
              rotation=270)));
        Connectors.FluidInlet C annotation (Placement(transformation(extent={{-110,
                  -10},{-90,10}}, rotation=0)));
      equation
        C.P=P;
        C.Q=Q;
        C.h_vol=h;
        if cardinality(ISpecificEnthalpy) == 0 then
          ISpecificEnthalpy.signal=h0;
        end if;
        h=ISpecificEnthalpy.signal;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{-90,0},{-40,0},{-54,10}}),
              Line(points={{-54,-10},{-40,0}}),
              Text(extent={{10,-40},{30,-60}}, textString=                                                                                                    "h"),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid)}),                                                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{10,-40},{30,-60}}, textString =                                                                                                    "h"),
              Line(points={{-92,0},{-40,0},{-54,10}}),
              Line(points={{-54,-10},{-40,0}})}),                                                                                                    Window(x=0.23, y=0.15, width=0.81, height=0.71), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end Sink;

      model SinkP "Water/steam sink with fixed pressure"
        parameter ThermoSysPro.Units.AbsolutePressure P0=100000 "Sink pressure";
        parameter ThermoSysPro.Units.AbsoluteTemperature T0=290
        "Sink temperature (active if option_temperature=1)";
        parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000
        "Sink specific enthalpy (active if option_temperature=2)";
        parameter Integer option_temperature=1
        "1:temperature fixed - 2:specific enthalpy fixed";
        parameter Integer mode=1
        "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
        Modelica.SIunits.MassFlowRate Q "Mass flow rate";
        ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
        ThermoSysPro.Units.SpecificEnthalpy h "Fluid enthalpy";
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
        "Propri?t?s de l'eau"                                                                   annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation (Placement(
              transformation(
              origin={50,0},
              extent={{-10,-10},{10,10}},
              rotation=180)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation (Placement(
              transformation(
              origin={0,-50},
              extent={{10,-10},{-10,10}},
              rotation=270)));
        Connectors.FluidInlet C annotation (Placement(transformation(extent={{-110,
                  -10},{-90,10}}, rotation=0)));
        InstrumentationAndControl.Connectors.InputReal ITemperature annotation (Placement(
              transformation(
              origin={0,50},
              extent={{-10,-10},{10,10}},
              rotation=270)));
      equation
        C.P=P;
        C.Q=Q;
        C.h_vol=h;
        if cardinality(IPressure) == 0 then
          IPressure.signal=P0;
        end if;
        P=IPressure.signal;
        if cardinality(ITemperature) == 0 then
          ITemperature.signal=T0;
        end if;
        if cardinality(ISpecificEnthalpy) == 0 then
          ISpecificEnthalpy.signal=h0;
        end if;
        if option_temperature == 1 then
          T=ITemperature.signal;
          h=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(P, T, 0);
        elseif option_temperature == 2 then
          h=ISpecificEnthalpy.signal;
          T=pro.T;
        else
          assert(false, "SinkPressureWaterSteam: incorrect option");
        end if;
        pro=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{-90,0},{-40,0},{-58,10}}),
              Line(points={{-40,0},{-58,-10}}),
              Text(extent={{40,28},{58,8}}, textString=                                                                                                    "P"),
              Text(extent={{-40,-40},{-10,-60}}, textString=                                                                                                    "h / T"),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={127,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{-94,26},{98,-30}}, textString=                                                                                                    "P")}),Window(x=0.06, y=0.16, width=0.67, height=0.71), Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{-90,0},{-40,0},{-58,10}}),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={127,255,0},
                fillPattern=FillPattern.Solid),
              Line(points={{-40,0},{-58,-10}}),
              Text(extent={{-94,26},{98,-30}}, textString =                                                                                                    "P"),
              Text(extent={{40,28},{58,8}}, textString =                                                                                                    "P"),
              Text(extent={{-40,-40},{-10,-60}}, textString =                                                                                                    "h / T")}),Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
      end SinkP;

      model SourceP "Water/steam source with fixed pressure"
        parameter ThermoSysPro.Units.AbsolutePressure P0=300000
        "Source pressure";
        parameter ThermoSysPro.Units.AbsoluteTemperature T0=290
        "Source temperature (active if option_temperature=1)";
        parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000
        "Source specific enthalpy (active if option_temperature=2)";
        parameter Integer option_temperature=1
        "1:temperature fixed - 2:specific enthalpy fixed";
        parameter Integer mode=1
        "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
        Modelica.SIunits.MassFlowRate Q "Mass flow rate";
        ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
        ThermoSysPro.Units.SpecificEnthalpy h "Fluid enthalpy";
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
        "Propri?t?s de l'eau"                                                                   annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation (Placement(
              transformation(extent={{-60,-10},{-40,10}}, rotation=0)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation (Placement(
              transformation(
              origin={0,-50},
              extent={{10,-10},{-10,10}},
              rotation=270)));
        Connectors.FluidOutlet C annotation (Placement(transformation(extent={{90,-10},
                  {110,10}}, rotation=0)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ITemperature annotation (Placement(
              transformation(
              origin={0,50},
              extent={{-10,-10},{10,10}},
              rotation=270)));
      equation
        C.P=P;
        C.Q=Q;
        C.h_vol=h;
        if cardinality(IPressure) == 0 then
          IPressure.signal=P0;
        end if;
        P=IPressure.signal;
        if cardinality(ITemperature) == 0 then
          ITemperature.signal=T0;
        end if;
        if cardinality(ISpecificEnthalpy) == 0 then
          ISpecificEnthalpy.signal=h0;
        end if;
        if option_temperature == 1 then
          T=ITemperature.signal;
          h=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(P, T, 0);
        elseif option_temperature == 2 then
          h=ISpecificEnthalpy.signal;
          T=pro.T;
        else
          assert(false, "SourcePressureWaterSteam: incorrect option");
        end if;
        pro=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{40,0},{90,0},{72,10}}),
              Line(points={{90,0},{72,-10}}),
              Text(extent={{-58,30},{-40,10}}, textString=                                                                                                    "P"),
              Text(extent={{-40,-40},{-10,-60}}, textString=                                                                                                    "h / T"),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={127,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{-94,28},{98,-28}}, textString=                                                                                                    "P")}),Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{40,0},{90,0},{72,10}}),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={127,255,0},
                fillPattern=FillPattern.Solid),
              Line(points={{90,0},{72,-10}}),
              Text(extent={{-94,28},{98,-28}}, textString =                                                                                                    "P"),
              Text(extent={{-58,30},{-40,10}}, textString =                                                                                                    "P"),
              Text(extent={{-40,-40},{-10,-60}}, textString =                                                                                                    "h / T")}),Window(x=0.45, y=0.01, width=0.35, height=0.49), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
      end SourceP;

      model SourcePQ
      "Water/steam source with fixed pressure and mass flow rate"
        parameter ThermoSysPro.Units.AbsolutePressure P0=300000
        "Fluid pressure (active if IPressure connector is not connected)";
        parameter Modelica.SIunits.MassFlowRate Q0=100
        "Mass flow (active if IMassFlow connector is not connected)";
        parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000
        "Fluid specific enthalpy (active if IEnthalpy connector is not connected)";
        ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
        Modelica.SIunits.MassFlowRate Q "Mass flow rate";
        ThermoSysPro.Units.SpecificEnthalpy h "Fluid specific enthalpy";
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IMassFlow annotation (Placement(
              transformation(
              origin={0,50},
              extent={{-10,-10},{10,10}},
              rotation=270)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation (Placement(
              transformation(extent={{-60,-10},{-40,10}}, rotation=0)));
        ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation (Placement(
              transformation(
              origin={0,-50},
              extent={{10,-10},{-10,10}},
              rotation=270)));
        Connectors.FluidOutlet C annotation (Placement(transformation(extent={{90,-10},
                  {110,10}}, rotation=0)));
      equation
        C.P=P;
        C.Q=Q;
        C.h_vol=h;
        if cardinality(IMassFlow) == 0 then
          IMassFlow.signal=Q0;
        end if;
        Q=IMassFlow.signal;
        if cardinality(IPressure) == 0 then
          IPressure.signal=P0;
        end if;
        P=IPressure.signal;
        if cardinality(ISpecificEnthalpy) == 0 then
          ISpecificEnthalpy.signal=h0;
        end if;
        h=ISpecificEnthalpy.signal;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{40,0},{90,0},{72,10}}),
              Line(points={{90,0},{72,-10}}),
              Text(extent={{-58,30},{-40,10}}, textString =                                                                                                    "P"),
              Text(extent={{-28,60},{-10,40}}, textString =                                                                                                    "Q"),
              Text(extent={{-30,-40},{-12,-60}}, textString =                                                                                                    "h"),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-22,20},{20,-24}},
                lineColor={0,0,255},
                textString =                                                                                                    "P Q")}),Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{40,0},{90,0},{72,10}}),
              Rectangle(
                extent={{-40,40},{40,-40}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Line(points={{90,0},{72,-10}}),
              Text(extent={{-30,60},{-10,40}}, textString =                                                                                                    "Q"),
              Text(extent={{-60,30},{-40,10}}, textString =                                                                                                    "P"),
              Text(extent={{-32,-40},{-12,-60}}, textString =                                                                                                    "h"),
              Text(
                extent={{-22,20},{20,-24}},
                lineColor={0,0,255},
                textString =                                                                                                    "P Q")}),Window(x=0.23, y=0.15, width=0.81, height=0.71), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end SourcePQ;
    end BoundaryConditions;

    package Connectors "Connectors"

      connector FluidInlet "Water/steam inlet fluid connector"
        ThermoSysPro.Units.AbsolutePressure P(start=100000.0)
        "Fluid pressure in the control volume";
        ThermoSysPro.Units.SpecificEnthalpy h_vol(start=100000.0)
        "Fluid specific enthalpy in the control volume";
        Modelica.SIunits.MassFlowRate Q(start=500)
        "Mass flow rate of the fluid crossing the boundary of the control volume";
        ThermoSysPro.Units.SpecificEnthalpy h(start=100000.0)
        "Specific enthalpy of the fluid crossing the boundary of the control volume";
        input Boolean a=true
        "Pseudo-variable for the verification of the connection orientation";
        output Boolean b
        "Pseudo-variable for the verification of the connection orientation";
        annotation (                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,255},
                fillColor={0,0,255},
                fillPattern=FillPattern.Solid)}),                                                                                                    Window(x=0.27, y=0.33, width=0.6, height=0.6), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",     revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end FluidInlet;

      connector FluidOutlet "Water/steam outlet fluid connector"
        ThermoSysPro.Units.AbsolutePressure P(start=100000.0)
        "Fluid pressure in the control volume";
        ThermoSysPro.Units.SpecificEnthalpy h_vol(start=100000.0)
        "Fluid specific enthalpy in the control volume";
        Modelica.SIunits.MassFlowRate Q(start=500)
        "Mass flow rate of the fluid crossing the boundary of the control volume";
        ThermoSysPro.Units.SpecificEnthalpy h(start=100000.0)
        "Specific enthalpy of the fluid crossing the boundary of the control volume";
        output Boolean a
        "Pseudo-variable for the verification of the connection orientation";
        input Boolean b=true
        "Pseudo-variable for the verification of the connection orientation";
        annotation (                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,255},
                fillColor={255,0,0},
                fillPattern=FillPattern.Solid)}),                                                                                                    Window(x=0.26, y=0.39, width=0.6, height=0.6), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",     revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end FluidOutlet;
    end Connectors;

    package HeatExchangers "Heat exchangers"

      model SimpleStaticCondenser "Simple static condenser"
        parameter Real Kc=10
        "Friction pressure loss coefficient for the hot side";
        parameter Real Kf=10
        "Friction pressure loss coefficient for the cold side";
        parameter Modelica.SIunits.Position z1c=0 "Hot inlet altitude";
        parameter Modelica.SIunits.Position z2c=0 "Hot outlet altitude";
        parameter Modelica.SIunits.Position z1f=0 "Cold inlet altitude";
        parameter Modelica.SIunits.Position z2f=0 "Cold outlet altitude";
        parameter Boolean continuous_flow_reversal=false
        "true: continuous flow reversal - false: discontinuous flow reversal";
        parameter Modelica.SIunits.Density p_rhoc=0
        "If > 0, fixed fluid density for the hot side";
        parameter Modelica.SIunits.Density p_rhof=0
        "If > 0, fixed fluid density for the cold side";
        parameter Integer modec=0
        "IF97 region of the water for the hot side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        parameter Integer modecs=0
        "IF97 region of the water at the outlet of the hot side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        parameter Integer modef=0
        "IF97 region of the water for the cold side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        Modelica.SIunits.Power W(start=1000000.0)
        "Power exchanged from the hot side to the cold side";
        ThermoSysPro.Units.AbsoluteTemperature Tec(start=500)
        "Fluid temperature at the inlet of the hot side";
        ThermoSysPro.Units.AbsoluteTemperature Tsc(start=400)
        "Fluid temperature at the outlet of the hot side";
        ThermoSysPro.Units.AbsoluteTemperature Tef(start=350)
        "Fluid temperature at the inlet of the cold side";
        ThermoSysPro.Units.AbsoluteTemperature Tsf(start=350)
        "Fluid temperature at the outlet of the cold side";
        ThermoSysPro.Units.DifferentialPressure DPfc(start=1000.0)
        "Friction pressure loss in the hot side";
        ThermoSysPro.Units.DifferentialPressure DPgc(start=100.0)
        "Gravity pressure loss in the hot side";
        ThermoSysPro.Units.DifferentialPressure DPc(start=1000.0)
        "Total pressure loss in the hot side";
        ThermoSysPro.Units.DifferentialPressure DPff(start=1000.0)
        "Friction pressure loss in the cold side";
        ThermoSysPro.Units.DifferentialPressure DPgf(start=100.0)
        "Gravity pressure loss in the cold side";
        ThermoSysPro.Units.DifferentialPressure DPf(start=1000.0)
        "Total pressure loss in the cold side";
        Modelica.SIunits.Density rhoc(start=998)
        "Density of the fluid in the hot side";
        Modelica.SIunits.Density rhof(start=998)
        "Density of the fluid in the cold side";
        Modelica.SIunits.MassFlowRate Qc(start=100) "Hot fluid mass flow rate";
        Modelica.SIunits.MassFlowRate Qf(start=100) "Cold fluid mass flow rate";
        Connectors.FluidInlet Ec annotation (Placement(transformation(extent={{-70,
                  -110},{-50,-90}}, rotation=0)));
        Connectors.FluidInlet Ef annotation (Placement(transformation(extent={{-110,
                  -10},{-90,10}}, rotation=0)));
        Connectors.FluidOutlet Sf annotation (Placement(transformation(extent={{90,
                  -11},{110,9}}, rotation=0)));
        Connectors.FluidOutlet Sc annotation (Placement(transformation(extent={{50,
                  -110},{70,-90}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proce annotation (Placement(
              transformation(extent={{-100,-100},{-80,-80}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph procs annotation (Placement(
              transformation(extent={{80,-100},{100,-80}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profe annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph promf annotation (Placement(
              transformation(extent={{-20,80},{0,100}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation (Placement(
              transformation(extent={{80,80},{100,100}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation (Placement(
              transformation(extent={{40,80},{60,100}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph promc annotation (Placement(
              transformation(extent={{0,-100},{20,-80}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profs annotation (Placement(
              transformation(extent={{-60,80},{-40,100}}, rotation=0)));
    protected
        constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n
        "Gravity constant";
        constant Real pi=Modelica.Constants.pi "pi";
        parameter Real eps=1.0 "Small number for pressure loss equation";
        parameter Modelica.SIunits.MassFlowRate Qeps=0.001
        "Small mass flow rate for continuous flow reversal";
      equation
        if continuous_flow_reversal then
          0=noEvent(if Qc > Qeps then Ec.h - Ec.h_vol else if Qc < -Qeps then Sc.h - Sc.h_vol else Ec.h - 0.5*((Ec.h_vol - Sc.h_vol)*Modelica.Math.sin(pi*Qc/2/Qeps) + Ec.h_vol + Sc.h_vol));
        else
          0=if Qc > 0 then Ec.h - Ec.h_vol else Sc.h - Sc.h_vol;
        end if;
        if continuous_flow_reversal then
          0=noEvent(if Qf > Qeps then Ef.h - Ef.h_vol else if Qf < -Qeps then Sf.h - Sf.h_vol else Ef.h - 0.5*((Ef.h_vol - Sf.h_vol)*Modelica.Math.sin(pi*Qf/2/Qeps) + Ef.h_vol + Sf.h_vol));
        else
          0=if Qf > 0 then Ef.h - Ef.h_vol else Sf.h - Sf.h_vol;
        end if;
        Ec.Q=Sc.Q;
        Qc=Ec.Q;
        Ef.Q=Sf.Q;
        Qf=Ef.Q;
        Sc.h=lsat.h;
        W=Qf*(Sf.h - Ef.h);
        W=Qc*(Ec.h - Sc.h);
        Ec.P - Sc.P=DPc;
        DPfc=Kc*ThermoSysPro.Functions.ThermoSquare(Qc, eps)/rhoc;
        DPgc=rhoc*g*(z2c - z1c);
        DPc=DPfc + DPgc;
        Ef.P - Sf.P=DPf;
        DPff=Kf*ThermoSysPro.Functions.ThermoSquare(Qf, eps)/rhof;
        DPgf=rhof*g*(z2f - z1f);
        DPf=DPff + DPgf;
        proce=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ec.P, Ec.h, modec);
        procs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sc.P, Sc.h, modecs);
        promc=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Ec.P + Sc.P)/2, (Ec.h + Sc.h)/2, modec);
        Tec=proce.T;
        Tsc=procs.T;
        (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Ec.P);
        if p_rhoc > 0 then
          rhoc=p_rhoc;
        else
          rhoc=promc.d;
        end if;
        profe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ef.P, Ef.h, modef);
        profs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sf.P, Sf.h, modef);
        promf=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Ef.P + Sf.P)/2, (Ef.h + Sf.h)/2, modef);
        Tef=profe.T;
        Tsf=profs.T;
        if p_rhof > 0 then
          rhof=p_rhof;
        else
          rhof=promf.d;
        end if;
        annotation (                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,60},{100,-60}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid), Line(
                points={{-60,-90},{-60,38},{0,-8},{60,40},{60,-90}},
                color={0,0,255},
                thickness=0.5)}),                                                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-100,60},{100,-60}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Line(
                points={{-60,-90},{-60,38},{0,-8},{60,40},{60,-90}},
                color={0,0,255},
                thickness=0.5),
              Text(
                extent={{-110,21},{-90,11}},
                lineColor={0,0,255},
                fillColor={255,213,170},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "Cold inlet"),
              Text(
                extent={{-46,-93},{-26,-103}},
                lineColor={0,0,255},
                fillColor={255,213,170},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "Hot inlet"),
              Text(
                extent={{28,-93},{48,-103}},
                lineColor={0,0,255},
                fillColor={255,213,170},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "Hot outlet"),
              Text(
                extent={{88,20},{110,9}},
                lineColor={0,0,255},
                fillColor={255,213,170},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "Cold outlet")}),Window(x=0.05, y=0.01, width=0.93, height=0.87), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"),       DymolaStoredErrors);
      end SimpleStaticCondenser;
    end HeatExchangers;

    package Junctions "Junctions"

      model Mixer2 "Mixer with two inlets"
        parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
        parameter Integer mode=0
        "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        Real alpha1 "Extraction coefficient for inlet 1 (<=1)";
        ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
        ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0)
        "Fluid specific enthalpy";
        ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
        Connectors.FluidInlet Ce2 annotation (Placement(transformation(extent={{-50,
                  -110},{-30,-90}}, rotation=0)));
        Connectors.FluidOutlet Cs annotation (Placement(transformation(extent={{90,
                  -10},{110,10}}, rotation=0)));
        Connectors.FluidInlet Ce1 annotation (Placement(transformation(extent={{-50,
                  90},{-30,110}}, rotation=0)));
        InstrumentationAndControl.Connectors.InputReal Ialpha1
        "Extraction coefficient for inlet 1 (<=1)"                                                        annotation (Placement(
              transformation(extent={{-80,50},{-60,70}}, rotation=0)));
        InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation (Placement(
              transformation(extent={{-20,50},{0,70}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
        "Propri?t?s de l'eau"                                                                   annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
      equation
        if cardinality(Ialpha1) == 0 then
          Ialpha1.signal=1;
        end if;
        P=Ce1.P;
        P=Ce2.P;
        P=Cs.P;
        Ce1.h_vol=h;
        Ce2.h_vol=h;
        Cs.h_vol=h;
        0=Ce1.Q + Ce2.Q - Cs.Q;
        0=Ce1.Q*Ce1.h + Ce2.Q*Ce2.h - Cs.Q*Cs.h;
        if cardinality(Ialpha1) <> 0 then
          Ce1.Q=Ialpha1.signal*Cs.Q;
        end if;
        alpha1=Ce1.Q/Cs.Q;
        Oalpha1.signal=alpha1;
        pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
        T=pro.T;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Polygon(
                points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{
                    -20,100},{-60,100},{-60,-100}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{-60,80},{-20,40}}, textString=                                                                                                    "1"),
              Text(extent={{-60,-40},{-20,-80}}, textString=                                                                                                    "2")}),Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Polygon(
                points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{
                    -20,100},{-60,100},{-60,-100}},
                lineColor={0,0,255},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{-60,80},{-20,40}}, textString =                                                                                                    "1"),
              Text(extent={{-60,-40},{-20,-80}}, textString =                                                                                                    "2")}),Window(x=0.33, y=0.09, width=0.71, height=0.88), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end Mixer2;

      model Splitter2 "Splitter with two outlets"
        parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
        parameter Integer mode=0
        "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
        ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
        ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0)
        "Fluid specific enthalpy";
        ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
        Connectors.FluidInlet Ce annotation (Placement(transformation(extent={{-110,
                  -10},{-90,10}}, rotation=0)));
        Connectors.FluidOutlet Cs1 annotation (Placement(transformation(extent={{30,
                  90},{50,110}}, rotation=0)));
        Connectors.FluidOutlet Cs2 annotation (Placement(transformation(extent={{30,
                  -110},{50,-90}}, rotation=0)));
        InstrumentationAndControl.Connectors.InputReal Ialpha1
        "Extraction coefficient for outlet 1 (<=1)"                                                        annotation (Placement(
              transformation(extent={{0,50},{20,70}}, rotation=0)));
        InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation (Placement(
              transformation(extent={{60,50},{80,70}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
        "Propri?t?s de l'eau"                                                                   annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
      equation
        if cardinality(Ialpha1) == 0 then
          Ialpha1.signal=1;
        end if;
        P=Ce.P;
        P=Cs1.P;
        P=Cs2.P;
        Ce.h_vol=h;
        Cs1.h_vol=h;
        Cs2.h_vol=h;
        0=Ce.Q - Cs1.Q - Cs2.Q;
        0=Ce.Q*Ce.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h;
        if cardinality(Ialpha1) <> 0 then
          Cs1.Q=Ialpha1.signal*Ce.Q;
        end if;
        alpha1=Cs1.Q/Ce.Q;
        Oalpha1.signal=alpha1;
        pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
        T=pro.T;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Polygon(
                points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{
                    20,20},{20,100},{60,100}},
                lineColor={0,0,0},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{20,80},{60,40}}, textString=                                                                                                    "1"),
              Text(extent={{20,-40},{60,-80}}, textString=                                                                                                    "2")}),Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Polygon(
                points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{
                    20,20},{20,100},{60,100}},
                lineColor={0,0,0},
                fillColor={255,255,0},
                fillPattern=FillPattern.Solid),
              Text(extent={{20,80},{60,40}}, textString =                                                                                                    "1"),
              Text(extent={{20,-40},{60,-80}}, textString =                                                                                                    "2")}),Window(x=0.33, y=0.09, width=0.71, height=0.88), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"),       DymolaStoredErrors);
      end Splitter2;
    end Junctions;

    package PressureLosses "Pressure losses"

      model PipePressureLoss "Pipe generic pressure loss"
        parameter Real K=10 "Friction pressure loss coefficient";
        parameter Modelica.SIunits.Position z1=0 "Inlet altitude";
        parameter Modelica.SIunits.Position z2=0 "Outlet altitude";
        parameter Boolean continuous_flow_reversal=false
        "true: continuous flow reversal - false: discontinuous flow reversal";
        parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
        parameter Modelica.SIunits.Density p_rho=0
        "If > 0, fixed fluid density";
        parameter Integer mode=0
        "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        ThermoSysPro.Units.DifferentialPressure deltaPf
        "Friction pressure loss";
        ThermoSysPro.Units.DifferentialPressure deltaPg "Gravity pressure loss";
        ThermoSysPro.Units.DifferentialPressure deltaP "Total pressure loss";
        Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
        Modelica.SIunits.Density rho(start=998) "Fluid density";
        ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
        ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0)
        "Average fluid pressure";
        ThermoSysPro.Units.SpecificEnthalpy h(start=100000)
        "Fluid specific enthalpy";
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
        "Propri?t?s de l'eau"                                                                   annotation (Placement(
              transformation(extent={{-100,80},{-80,102}}, rotation=0)));
        Connectors.FluidInlet C1 annotation (Placement(transformation(extent={{-110,
                  -10},{-90,10}}, rotation=0)));
        Connectors.FluidOutlet C2 annotation (Placement(transformation(extent={{90,
                  -10},{110,10}}, rotation=0)));
    protected
        constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n
        "Gravity constant";
        constant Real pi=Modelica.Constants.pi "pi";
        parameter Real eps=0.001 "Small number for pressure loss equation";
        parameter Modelica.SIunits.MassFlowRate Qeps=0.001
        "Small mass flow for continuous flow reversal";
      equation
        C1.P - C2.P=deltaP;
        C2.Q=C1.Q;
        C2.h=C1.h;
        h=C1.h;
        Q=C1.Q;
        if continuous_flow_reversal then
          0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
        else
          0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
        end if;
        deltaPf=K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
        deltaPg=rho*g*(z2 - z1);
        deltaP=deltaPf + deltaPg;
        Pm=(C1.P + C2.P)/2;
        pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
        T=pro.T;
        if p_rho > 0 then
          rho=p_rho;
        else
          rho=pro.d;
        end if;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,20},{100,-20}},
                lineColor={0,0,255},
                fillColor={85,255,85},
                fillPattern=FillPattern.Solid), Text(
                extent={{-12,14},{16,-14}},
                lineColor={0,0,255},
                fillColor={85,255,85},
                fillPattern=FillPattern.Solid,
                textString=                                                                                                    "K")}),Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,20},{100,-20}},
                lineColor={0,0,255},
                fillColor={85,255,85},
                fillPattern=FillPattern.Solid), Text(
                extent={{-12,14},{16,-14}},
                lineColor={0,0,255},
                fillColor={85,255,85},
                fillPattern=FillPattern.Solid,
                textString =                                                                                                    "K")}),Window(x=0.11, y=0.04, width=0.71, height=0.88), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end PipePressureLoss;

      model SingularPressureLoss "Singular pressure loss"
        parameter Real K=1000.0 "Pressure loss coefficient";
        parameter Boolean continuous_flow_reversal=false
        "true: continuous flow reversal - false: discontinuous flow reversal";
        parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
        parameter Modelica.SIunits.Density p_rho=0
        "If > 0, fixed fluid density";
        parameter Integer mode=0
        "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
        ThermoSysPro.Units.DifferentialPressure deltaP "Singular pressure loss";
        Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
        Modelica.SIunits.Density rho(start=998) "Fluid density";
        ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
        ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0)
        "Average fluid pressure";
        ThermoSysPro.Units.SpecificEnthalpy h(start=100000)
        "Fluid specific enthalpy";
        Connectors.FluidInlet C1 annotation (Placement(transformation(extent={{-110,
                  -10},{-90,10}}, rotation=0)));
        Connectors.FluidOutlet C2 annotation (Placement(transformation(extent={{90,
                  -10},{110,10}}, rotation=0)));
        ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation (Placement(
              transformation(extent={{-100,80},{-80,100}}, rotation=0)));
    protected
        constant Real pi=Modelica.Constants.pi "pi";
        parameter Real eps=0.001 "Small number for pressure loss equation";
        parameter Modelica.SIunits.MassFlowRate Qeps=0.001
        "Small mass flow for continuous flow reversal";
      equation
        C1.P - C2.P=deltaP;
        C2.Q=C1.Q;
        C2.h=C1.h;
        h=C1.h;
        Q=C1.Q;
        if continuous_flow_reversal then
          0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
        else
          0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
        end if;
        deltaP=K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
        Pm=(C1.P + C2.P)/2;
        pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
        T=pro.T;
        if p_rho > 0 then
          rho=p_rho;
        else
          rho=pro.d;
        end if;
        annotation (                                                                    Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Polygon(
                points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,
                    40}},
                lineColor={0,0,255},
                fillColor={128,255,0},
                fillPattern=FillPattern.Solid), Polygon(
                points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,
                    -40},{-60,-40}},
                lineColor={0,0,255},
                fillColor={128,255,0},
                fillPattern=FillPattern.Solid)}),                                                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Polygon(
                points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,
                    40}},
                lineColor={0,0,255},
                fillColor={128,255,0},
                fillPattern=FillPattern.Solid), Polygon(
                points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,
                    -40},{-60,-40}},
                lineColor={0,0,255},
                fillColor={128,255,0},
                fillPattern=FillPattern.Solid)}),                                                                                                    Window(x=0.09, y=0.2, width=0.66, height=0.69), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end SingularPressureLoss;
    end PressureLosses;

    package Sensors "Sensors"

      model SensorQ "Mass flow sensor"
        parameter Boolean continuous_flow_reversal=false
        "true : continuous flow reversal - false : discontinuous flow reversal";
        Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
        ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Measure annotation (Placement(
              transformation(
              origin={0,102},
              extent={{-10,-10},{10,10}},
              rotation=90)));
        Connectors.FluidInlet C1 annotation (Placement(transformation(extent={{-110,
                  -90},{-90,-70}}, rotation=0)));
        Connectors.FluidOutlet C2 annotation (Placement(transformation(extent={{92,
                  -90},{112,-70}}, rotation=0)));
    protected
        constant Real pi=Modelica.Constants.pi "pi";
        parameter Modelica.SIunits.MassFlowRate Qeps=0.001
        "Minimum mass flow for continuous flow reversal";
      equation
        C1.P=C2.P;
        C1.h=C2.h;
        C1.Q=C2.Q;
        Q=C1.Q;
        if continuous_flow_reversal then
          0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
        else
          0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
        end if;
        Measure.signal=Q;
        annotation (                                                                    Icon(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Ellipse(
                extent={{-60,92},{60,-28}},
                lineColor={0,0,255},
                fillColor={0,255,0},
                fillPattern=FillPattern.Solid),
              Line(points={{0,-28},{0,-80}}),
              Line(points={{-98,-80},{102,-80}}),
              Text(extent={{-60,60},{60,0}}, textString =                                                                                                    "Q")}),Window(x=0.25, y=0.19, width=0.6, height=0.6), Diagram(
              coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Ellipse(
                extent={{-60,92},{60,-28}},
                lineColor={0,0,255},
                fillColor={0,255,0},
                fillPattern=FillPattern.Solid),
              Line(points={{0,-28},{0,-80}}),
              Line(points={{-98,-80},{102,-80}}),
              Text(
                extent={{-60,60},{60,0}},
                lineColor={0,0,0},
                fillPattern=FillPattern.VerticalCylinder,
                fillColor={120,255,0},
                textString=                                                                                                    "Q")}),                                                           Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",       revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
      end SensorQ;
    end Sensors;
    annotation(Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
</html>"));
  end WaterSteam;
  annotation(Icon(graphics={
      Rectangle(
        extent={{-100,-100},{80,50}},
        lineColor={0,0,255},
        fillColor={235,235,235},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
        lineColor={0,0,255},
        fillColor={235,235,235},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
        lineColor={0,0,255},
        fillColor={235,235,235},
        fillPattern=FillPattern.Solid),
      Text(
        extent={{-120,135},{120,70}},
        lineColor={255,0,0},
        textString =                                                                                                    "%name"),
      Text(
        extent={{-90,40},{70,10}},
        lineColor={160,160,164},
        fillColor={0,0,0},
        fillPattern=FillPattern.Solid,
        textString =                                                                                                    "Library"),
      Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
      Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
      Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
      Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
      Polygon(
        points={{16,-71},{29,-67},{29,-74},{16,-71}},
        lineColor={0,0,0},
        fillColor={0,0,0},
        fillPattern=FillPattern.Solid),
      Polygon(
        points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}},
        lineColor={0,0,0},
        fillColor={0,0,0},
        fillPattern=FillPattern.Solid)}),                                                                                                    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
<p><b>ThermoSysPro Version 3.0</b> </p>
</html>"), uses(Modelica(version="3.2")),
  version="1",
  conversion(noneFromVersion=""));
end ThermoSysPro;

package DataReconciliationTests
  model ThermoSysProSimpleExple

    parameter Real rho=1000;
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1 annotation(Placement(visible=true, transformation(origin={-140.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP1 annotation(Placement(visible=true, transformation(origin={136.0591,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss1(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={-80.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-44.0534,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={43.7284,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss2(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={10.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss3(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={10.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss4(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain=Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={-20,
              27.8184},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(Q(
                                                     uncertain = Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={-20,
              -11.9274},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(
                                                     uncertain = Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={-110,
              8.1168},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(Q(
                                                     uncertain = Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={80,
              8.1168},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(sensorQ4.C2,pipePressureLoss4.C1) annotation(Line(visible=true, origin={95.4854,-0.1703}, points={{-5.2854,
            0.2871},{0.6599,0.2871},{0.6599,0.1703},{4.5146,0.1703}},                                                                                                    color={0,0,255}));
    connect(mixer21.Cs,sensorQ4.C1) annotation(Line(visible=true, origin={64.3305,-0.2621}, points={{
            -10.6021,0.2621},{2.4753,0.2621},{2.4753,0.3789},{5.6695,0.3789}},                                                                                            color={0,0,255}));
    connect(sensorQ3.C2,pipePressureLoss3.C1) annotation(Line(visible=true, origin={-4.5146,-20.1924}, points={{-5.2854,
            0.265},{0.6599,0.265},{0.6599,0.1924},{4.5146,0.1924}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2, pipePressureLoss2.C1)
                                              annotation(Line(visible=true, origin={-4.5146,20.1805}, points={{-5.2854,
            -0.3621},{0.6599,-0.3621},{0.6599,-0.1805},{4.5146,-0.1805}},                                                                                                  color={0,0,255}));
    connect(splitter21.Cs2,sensorQ3.C1) annotation(Line(visible=true, origin={-36.7652,-16.9235}, points={{-3.2882,
            6.9235},{-3.2882,-3.0039},{6.7652,-3.0039}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1, sensorQ2.C1)
                                        annotation(Line(visible=true, origin={-36.7652,16.8889}, points={{-3.2882,
            -6.8889},{-3.2882,2.9295},{6.7652,2.9295}},                                                                                                   color={0,0,255}));
    connect(sensorQ1.C2,pipePressureLoss1.C1) annotation(Line(visible=true, origin={-94.5146,-0.1703}, points={{-5.2854,
            0.2871},{0.6599,0.2871},{0.6599,0.1703},{4.5146,0.1703}},                                                                                                    color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-123.9998,-0.3639}, points={{-6.0002,
            0.3639},{0.8056,0.3639},{0.8056,0.4807},{3.9998,0.4807}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-59.2678,-0.0}, points={{
            -10.7322,0},{2.1144,0},{5.2144,0}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss3.C2,mixer21.Ce2) annotation(Line(visible=true, origin={33.5937,-16.7254}, points={{
            -13.5937,-3.2746},{6.1347,-3.2746},{6.1347,6.7254}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss2.C2,mixer21.Ce1) annotation(Line(visible=true, origin={33.5485,16.5671}, points={{
            -13.5485,3.4329},{6.1799,3.4329},{6.1799,-6.5671}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss4.C2,sinkP1.C) annotation(Line(visible=true, origin={124.024,-0.1018}, points={{-4.024,
            0.1018},{0.6553,0.1018},{2.0351,0.1018}},                                                                                                    color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}},     preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics),
        DymolaStoredErrors);
  end ThermoSysProSimpleExple;

  model FlatSimpleExple
    Real q1(uncertain=Uncertainty.refine)=1;
    Real q2(uncertain=Uncertainty.refine)=2;
    Real q3(uncertain=Uncertainty.refine);
    Real q4(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    q1=q2 + q3;
    q4=q2 + q3;
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}));
  end FlatSimpleExple;

  model VDI2048Exple
    Real mFDKEL(uncertain=Uncertainty.refine)=46.241;
    Real mFDKELL(uncertain=Uncertainty.refine)=45.668;
    Real mSPL(uncertain=Uncertainty.refine)=44.575;
    Real mSPLL(uncertain=Uncertainty.refine)=44.319;
    Real mV(uncertain=Uncertainty.refine);
    Real mHK(uncertain=Uncertainty.refine)=69.978;
    Real mA7(uncertain=Uncertainty.refine)=10.364;
    Real mA6(uncertain=Uncertainty.refine)=3.744;
    Real mA5(uncertain=Uncertainty.refine);
    Real mHDNK(uncertain=Uncertainty.refine);
    Real mD(uncertain=Uncertainty.refine)=2.092 annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}}),Bitmap(visible=true, origin={182.075,17.4625}, fileName="", imageSource="iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAACXBIWXMAAA7EAAAOxAGVKw4b
AAACj0lEQVQoFQGEAnv9AU1NTQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAABNTU3//03//////03//////03//////03//////03//////03//////01NTU0C
AAAAAACyAABOAACyAABOAACyAABOAACyAABOp6dZTk5OTk4Ap6enAACyAAAAAgAAAAAATgAA
sgAATgAAsgAATgAAsgAATgAAsqenp1lZAFlZAKenpwAATgAAAAIAAAAAALIAAE4AALIAAE4A
ALIAAE4AALIAAE4AAAAAAAAAAAAAAAAAALIAAAAEAAAAAABOAACyAABOAACyAABOAACyAABO
AACyWVmnp6enAAAAWVlZAABOAAAAAE1NTf//////Tf//////Tf//////Tf//////Tf//////
Tf//////Tf///01NTQIAAAAAAE4AALIAAE4AALJOTk5OTgAAAE4AALIAAE4AALIAAE4AALIA
AE4AAAACAAAAAACyAABOAACyTk5OWVlZWVlZTk4AAABOTk4ATk5OAACyAABOAACyAAAABAAA
AAAATgAAsk5OTllZWQAAAKenp1lZWU5Op4aGhgAAAE5OTrKysgAATgAAAAIAAAAAALJOTk5Z
WVkAAAAAAABZWVkAAABZWVl6enoAAACGhoZOTk4AALIAAAACAAAATk5OWVlZAAAAp6enAAAA
AAAAp6enAAAAWVlZenp6AAAAhoaGTk5OAAAAAgAAAFlZWQAAAAAAAFlZWaenpwAAAFlZWaen
pwAAAFlZWXp6egAAAIaGhgAAAAFNTU0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAB4KaX50xp77gAAAABJRU5ErkJggg==
", extent={{-2.075,0.0},{2.075,0.0}})}));
  equation
    mFDKEL + mFDKELL - mSPL - mSPLL + 0.4*mV=0;
    mSPL + mSPLL - mV - mHK - mA7 - mA6 - mA5=0;
    mA7 + mA6 + mA5 - mHDNK=0;
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png",
              imageSource =                                                                                                    "", extent={{-142.7312,-86.275},{142.7312,86.275}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png",
              imageSource=                                                                                                    "", extent={{-142.7312,-86.275},{142.7312,86.275}})}));
  end VDI2048Exple;


  model DistillationTower
    Real F(uncertain=Uncertainty.refine)=1;
    Real B(uncertain=Uncertainty.refine)=1;
    Real T(uncertain=Uncertainty.refine);
    Real xF1(uncertain=Uncertainty.refine);
    Real xF2(uncertain=Uncertainty.refine);
    Real xB1(uncertain=Uncertainty.refine)=1;
    Real xB2(uncertain=Uncertainty.refine);
    Real xT1(uncertain=Uncertainty.refine)=1;
    Real xT2(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    F*xF1 - B*xB1 - T*xT1=0;
    F*xF2 - B*xB2 - T*xT2=0;
    xF1 + xF2=100;
    xB1 + xB2=100;
    xT1 + xT2=100;
  end DistillationTower;

  model RedundancyTestCase1
    Real x1(uncertain=Uncertainty.refine)=1;
    Real x2(uncertain=Uncertainty.refine)=2;
    Real x3;
    Real x4;
    Real x5(uncertain=Uncertainty.refine);
    Real x6(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1-x2-x3 = 0;
    x2-x4 = 0;
    x3-x5 = 0;
    x4+x5-x6 = 0;
  end RedundancyTestCase1;

  model RedundancyTestCase2
    Real x1(uncertain=Uncertainty.refine)=1;
    Real x2(uncertain=Uncertainty.refine)=2;
    Real x3;
    Real x4;
    Real x5;
    Real x6                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1-x2-x3 = 0;
    x2-x4 = 0;
    x3-x5 = 0;
    x4+x5-x6 = 0;
  end RedundancyTestCase2;

  model RedundancyTestCase3
    Real x1(uncertain=Uncertainty.refine)=1;
    Real x2=2;
    Real x3;
    Real x4;
    Real x5;
    Real x6(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1-x2-x3 = 0;
    x2-x4 = 0;
    x3-x5 = 0;
    x4+x5-x6 = 0;
  end RedundancyTestCase3;

  model ExtractionSetSTest
    Real x1(uncertain=Uncertainty.refine);
    Real x2(uncertain=Uncertainty.refine);
    Real x3(uncertain=Uncertainty.refine);
    Real y1;
    Real y2;
    Real y3                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1+x2 = 0;
    x1-x2 = 0;
    y1 = x2+2*x3;
    x3-y1+y2=x2;
    y2+y3=0;
    y2-2*y3=3;
  end ExtractionSetSTest;

  model ExtractionSetS_NL_Test
    Real x1(uncertain=Uncertainty.refine);
    Real x2(uncertain=Uncertainty.refine);
    Real x3(uncertain=Uncertainty.refine);
    Real y1;
    Real y2;
    Real y3                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1+x2 = 0;
    x1-x2 = 0;
    y1 = x2+2*x3;
    x3-y1+y2=x2;
    y2+y3=0;
    y2*y3=3;
  end ExtractionSetS_NL_Test;
  
  // NEW TEST CASES  
  model TwoFlows
    Real Q1(uncertain=Uncertainty.refine); 
	Real Q2(uncertain=Uncertainty.refine); 
	Real Q3(uncertain=Uncertainty.refine);
    Real Q4(uncertain=Uncertainty.refine);
    Real y1, a;
  equation
	  y1 = 2;       // Eq1
	  a = 0.5;      // Eq2
	  Q1 = y1;      // Eq3
	  Q2 = a*y1 annotation(__OpenModelica_ApproximatedEquation=true); // Eq4 uncertain
	  Q1 = Q2 + Q3; // Eq5
	  Q4 = Q1 + Q2; // Eq6
  end TwoFlows;
  
  model Splitter
	 Real Q(uncertain=Uncertainty.refine);
	 Real Q1(uncertain=Uncertainty.refine);
	 Real Q2(uncertain=Uncertainty.refine);
	 Real y, y1, y2, a;
	 Real A, Y;
  equation
     Y = 2;       // Eq1
     y = Y;       // Eq2
     A = 0.5;     // Eq3
     a = A;       // Eq4
     y1 = a*y;    // Eq5
     y = y1 + y2; // Eq6
     Q = y;       // Eq7
     Q1 = y1;     // Eq8
     Q2 = y2;     // Eq9
  end Splitter;
  
  
  model Splitter1
	  Real Q1(uncertain=Uncertainty.refine); 
	  Real Q2(uncertain=Uncertainty.refine); 
	  Real Q3(uncertain=Uncertainty.refine);
	  Real P01,P02,P03,T1_P1,T2_P2,T3_P2,T1_P2,T2_P1;
	  Real T3_P1,V_Q1,V_Q2,V_Q3,T1_Q2,T1_Q2,T2_Q1,T3_Q1,V_P1,P,V_P2,V_P3,T1_Q1,T2_Q2,T3_Q2;
  equation
	  P01 = 3;			// Eq1
	  P02 = 1;			// Eq2
	  P03 = 1;			// Eq3
	  T1_P1 = P01;		// Eq4
	  T2_P2 = P02;		// Eq5
	  T3_P2 = P03;		// Eq6
	  T1_P1 - T1_P2 = Q1^2 annotation(__OpenModelica_ApproximatedEquation=true); // Eq7
	  T2_P1 - T2_P2 = Q2^2 annotation(__OpenModelica_ApproximatedEquation=true);// Eq8
	  T3_P1 - T3_P2 = Q3^2 annotation(__OpenModelica_ApproximatedEquation=true); // Eq9
	  V_Q1 = V_Q2 + V_Q3; // Eq10
	  V_Q1 = T1_Q2;	 	// Eq11    
	  T1_Q2 = Q1;		// Eq12
	  V_Q2 = T2_Q1;	 	// Eq13
	  T2_Q1 = Q2;		// Eq14
	  V_Q3 = T3_Q1;	 	// Eq15
	  T3_Q1 = Q3;		// Eq16
	  T1_P2 = V_P1;	 	// Eq17
	  V_P1 = P;			// Eq18  
	  T2_P1 = V_P2 ;	// Eq19
	  V_P2 = P; 		// Eq20 
	  T3_P1 = V_P3;	 	// Eq21
	  V_P3 = P;			// Eq22
	  T1_Q1 = Q1;		// Eq23
	  T2_Q2 = Q2;  		// Eq24
	  T3_Q2 = Q3;  		// Eq25
  end Splitter1;
  
  model Pipe1
    Real p;
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
  equation
    p=2;
    Q1 = Q2;
    Q1 = p;  
  end Pipe1; 
    
  model Pipe2
    Real p;
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    p=2;
    Q1 = y1; 
    Q2 = Q1; // Eq2
    y1 = y2; // Eq3
    Q1 = p;  // Eq4
  end Pipe2; 

  model Pipe3
    Real p=2;
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    Q1 = y1; // Eq1
    Q2 = y2; // Eq2
    y1 = y2; // Eq3
    Q1 = p;  // Eq4
  end Pipe3; 

  model Pipe4
    Real p;
    Real q; 
    Real Q1(uncertain=Uncertainty.refine);
    Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    p=2;
    q=1;
    Q1 = y1;   // Eq1
    Q2 = q*y2; // Eq2
    y1 = y2;   // Eq3
    Q1 = q*p;  // Eq4
  end Pipe4; 

  model Pipe5
    Real p;
    Real q;
    Real Q1(uncertain=Uncertainty.refine);
    Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    p=2;
    q=1;
    Q1 = y1;   // Eq1
    Q2 = q*y2; // Eq2
    y1 = q*y2; // Eq3
    Q1 = p;    // Eq4
  end Pipe5; 
  
  model ExtractionSetSTest2
    Real x1(uncertain=Uncertainty.refine);
    Real x2(uncertain=Uncertainty.refine);
    Real x3(uncertain=Uncertainty.refine);
    Real y1;
    Real y2;
    Real y3;
    Real z1;
    Real z2;
    Real z3;
    Real z4;
    Real z5 annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1 + x2 = 0;
    x1 - x2 = 0;
    y1 = x2 + 2*x3;
    x3 - y1 + y2 = x2;
    y2 + y3 = 0;
    y2 - 2*y3 = 3;
    z1 + z2 + z3 + y3 = 2;
    z2 + 2*z3 = x1 - x2;
    z3 = 2*x3;
    y1 + y2 + z4 = x2 + 3*x3 annotation(__OpenModelica_ApproximatedEquation=true);
    z4 - z5 = x1 - x3;
  end ExtractionSetSTest2;


  model ThermoSysProRedundancyTest1

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest1;

  model ThermoSysProRedundancyTest2

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5                                 annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6                                 annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest2;

  model ThermoSysProRedundancyTest3

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2                                 annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5                                 annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest3;

  model ThermoSysProRedundancyTest4

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest4;
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={235,235,235},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-100.0,-100.0},{80.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235},
            fillPattern =                                                                                                    FillPattern.Solid, points={{-100.0,50.0},{-80.0,70.0},{100.0,70.0},{80.0,50.0},{-100.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235},
            fillPattern =                                                                                                    FillPattern.Solid, points={{100.0,70.0},{100.0,-80.0},{80.0,-100.0},{80.0,50.0},{100.0,70.0}}),Text(visible=true, origin={-42.0755,7.2622},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-39.4379,-29.2276},{39.4379,29.2276}}, textString
            =                                                                                                    "Data reconciliation", fontName="Arial"),Bitmap(visible=true, origin={23.1899,-65.9119}, fileName="logoModelica.png",
            imageSource =                                                                                                    "", extent={{-53.1899,-18.4552},{53.1899,18.4552}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})),
    uses(Modelica(version="3.2"), ThermoSysPro(version="1")));
end DataReconciliationTests;
