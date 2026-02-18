within ;
package BenchmarksForResizeableArrays "Library with benchmark models to evaluate that arrays can be resized after translation"
  package ArrayEquations "Models with array equations"
    extends .Modelica.Icons.ExamplesPackage;

    model CascadedFirstOrder1
      "First order blocks connected in series (defined with array equation)"
      extends .Modelica.Icons.Example;

      parameter Integer N=10;
      parameter Real tau=0.1 "Time constant";
      Real u;
      Real x[N](each start=0, each fixed=true);
    equation
               u = 1;
      tau*der(x) = cat(1, {u-x[1]}, x[1:N-1]-x[2:N]);
    annotation(experiment(StopTime=2.0), Documentation(revisions="<html>
    <ul>
    <li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
    </ul>
    <p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
    </html>"));
    end CascadedFirstOrder1;

    model CascadedFirstOrder2
      "First order blocks connected in series (defined with array equation)"
      extends .Modelica.Icons.Example;

      parameter Integer N=10;
      parameter Real tau=0.1 "Time constant";
      Real u;
      Real x[N](each start=0, each fixed=true);
    equation
               u = 1;
      tau*der(x) = cat(1, {u}, x[1:N-1]) - x;
    annotation(experiment(StopTime=2.0), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
</html>"));
    end CascadedFirstOrder2;

    model CascadedFirstOrder3
      "First order blocks connected in series (defined with array equation)"
      extends .Modelica.Icons.Example;

      parameter Integer N=10;
      parameter Real tau=0.1 "Time constant";
      Real u;
      Real x[N](each start=0, each fixed=true);
    equation
               u = 1;
      tau*der(x) = vector([u-x[1]; x[1:N-1] - x[2:N]]);

    annotation(experiment(StopTime=2.0), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
</html>"));
    end CascadedFirstOrder3;

    model CascadedFirstOrder4
      "First order blocks connected in series (defined with array equation)"
      extends .Modelica.Icons.Example;

      parameter Integer N=10;
      parameter Real tau=0.1 "Time constant";
      Real u;
      Real x[N](each start=0, each fixed=true);
    equation
               u = 1;
      tau*der(x) = vector([u; x[1:N-1]]) - x;

    annotation(experiment(StopTime=2.0), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
</html>"));
    end CascadedFirstOrder4;

    model InsulatedRodWithArrayEquations
      "Insulated rod (implemented with array equations)"
        import    Modelica.Units.SI;
        extends  .Modelica.Icons.Example;
        parameter Integer nT(min=2)=10 "number of inner nodes";
        parameter SI.Length L=1 "length";
        parameter SI.Area A=0.0004 "area";
        parameter SI.Density rho=7500 "density";
        parameter SI.ThermalConductivity lambda=74 "thermal conductivity";
        parameter SI.SpecificHeatCapacity c=450 "specifc heat capacity";
        parameter SI.Temperature T0=293 "initial temperature";

        SI.Temperature T[nT](each start=T0,each fixed=true) "temperatures at inner nodes";
        SI.HeatFlowRate Q_flow[nT+1];

        SI.HeatFlowRate port_a_Q_flow;
        SI.HeatFlowRate port_b_Q_flow;
        SI.Temperature port_a_T;
        SI.Temperature port_b_T;
    protected
        Real dx;
        Real k1;
        Real k2;
        Real k3;
    equation
        // Constants
        dx = L/nT;
        k1 = lambda*A/dx;
        k2 = rho*c*A*dx;
        k3 = 2*k1;

        // Connection equations
        port_a_T = if time<2000 then 300 else 320;  // temperature source at port_a
        port_b_Q_flow = 0;  // insulation at port_b

        // Acausal part of rod model (depending on the connection of port_a and port_b, equations
        // are either solved for port_a_Q_flow/port_b_Q_flow or for port_a_T/port_b.T)
        port_a_Q_flow = k3*(port_a_T - T[1]);
        port_b_Q_flow = k3*(T[nT] - port_b_T);

        // Causal part of rod model (independently how port_a/port_b are connected
        // equations are always solved for Q_flow and der(T))
        Q_flow = cat(1, {port_a_Q_flow}, k1*(T[1:nT-1] - T[2:nT]), {port_b_Q_flow});
        der(T) = (Q_flow[1:nT] - Q_flow[2:nT+1])/k2;

      annotation(experiment(StopTime=5000), Documentation(info="<html>


</html>", revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist and Martin Otter: Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a>, <a href=\"https://www.dlr.de/en/fk\">Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts</a></p>
</html>"));
    end InsulatedRodWithArrayEquations;

    model InsulatedRodWithFunction
      "Insulated rod (implemented with a function call)"
      import  Modelica.Units.SI;
      extends BaseClasses.InsulatedBaseRod;
    protected
      function innerInsulatedRod "Causal part of rod model"
        input SI.Temperature T[:];
        input Real k1;
        input Real k2;
        input SI.HeatFlowRate port_a_Q_flow;
        input SI.HeatFlowRate port_b_Q_flow;
        output Real der_T[size(T,1)];
      protected
        Integer nT = size(T,1);
        SI.HeatFlowRate Q_flow[nT+1];
      algorithm
        Q_flow[1] := port_a_Q_flow;
        for i in 2:nT loop
          Q_flow[i] := k1*(T[i-1] - T[i]);
        end for;
        Q_flow[nT+1] := -port_b_Q_flow;

        for i in 1:nT loop
          der_T[i] := (Q_flow[i] - Q_flow[i + 1])/k2;
        end for;
      end innerInsulatedRod;
    equation
        // Causal part of rod model (independently how port_a/port_b are connected
        // equations are always solved for Q_flow and der(T))
        der(T) = innerInsulatedRod(T, k1, k2, port_a_Q_flow, port_b_Q_flow);

      annotation(experiment(StopTime=5000), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
    end InsulatedRodWithFunction;

    model WaterHammer "Water hammer model producing shock waves"
       import    Modelica.Units.SI;
       extends .Modelica.Icons.Example;
        parameter Integer n=10;
        parameter SI.Length L=100 "Length of the pipe";
        parameter SI.Diameter D=0.05 "Pipe diameter";

        parameter SI.Density rho=1000 "Density of water";
        parameter SI.Pressure B=21e8 "Bulk modulus of water";
        parameter SI.Time tClose=0.01 "Time at which the valve closes";
        parameter SI.MassFlowRate Q0=0.0002 "Initial flow rate";
        parameter Real f=0.05 "Darcy-Weisbach friction factor (dimensionless)";

        SI.Area A "Cross-sectional area of the pipe (m^2)";
        SI.Velocity c "Speed of sound in water (m/s)";
        SI.Length dx "Length of each pipe segment (m)";
        SI.Time dt "Time step for stability (s)";
        SI.Pressure p[n+1](start=fill(3e5, n+1), fixed=true) "Pressure at each node (Pa)";
        SI.VolumeFlowRate Q[n] "Flow rate in each segment (m^3/s)";
        SI.Velocity V[n](start=fill(0.1, n), fixed=true) "Speed of flow in each segment (m/s)";
        SI.MassFlowRate Qend "Flow rate at the end of the pipe (m^3/s)";
        SI.MassFlowRate QPlusEnds[n+2];
        Real valveOpen "1 if valve is open, 0 if closed";
    equation
        A=3.1415*D^2/4;
        c=sqrt(B/rho);
        dx=L / n;
        dt=dx / c;
        Q = V*A;
        valveOpen = if time < tClose then 1 else 0;
        Qend = Q0 * valveOpen;
        der(V) = -(p[2:n+1] - p[1:n]) / (rho * dx) - (f / (2 * D)) .* V .* abs(V);
        QPlusEnds = cat(1, {Q[1]}, Q, {Qend});
        der(p) = B*(-(QPlusEnds[2:n+2] - QPlusEnds[1:n+1]) / (A * dx));
      annotation(experiment(StopTime=0.3), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Cl&eacute;ment Co&iuml;c: Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Cl&eacute;ment Co&iuml;c.</p>

</html>"));
    end WaterHammer;

    package BaseClasses "Utility base classes"
      extends .Modelica.Icons.BasesPackage;
      partial model InsulatedBaseRod
        "Base class of an insulated rod (common equations of different implementations)"
          import    Modelica.Units.SI;
          extends  .Modelica.Icons.Example;
          parameter Integer nT(min=2)=10 "number of inner nodes";
          parameter SI.Length L=1 "length";
          parameter SI.Area A=0.0004 "area";
          parameter SI.Density rho=7500 "density";
          parameter SI.ThermalConductivity lambda=74 "thermal conductivity";
          parameter SI.SpecificHeatCapacity c=450 "specifc heat capacity";
          parameter SI.Temperature T0=293 "initial temperature";

          SI.Temperature T[nT](each start=T0,each fixed=true) "temperatures at inner nodes";

          SI.HeatFlowRate port_a_Q_flow;
          SI.HeatFlowRate port_b_Q_flow;
          SI.Temperature port_a_T;
          SI.Temperature port_b_T;
      protected
          parameter Real dx = L/nT;
          parameter Real k1 = lambda*A/dx;
          parameter Real k2 = rho*c*A*dx;
          parameter Real k3 = 2*k1;
      equation
          // Connetion equations
          port_a_T = if time<2000 then 300 else 320;  // temperature source at port_a
          port_b_Q_flow = 0;  // insulation at port_b

          // Acausal part of rod model (depending on the connection of port_a and port_b, equations
          // are either solved for port_a_Q_flow/port_b_Q_flow or for port_a_T/port_b.T)
          port_a_Q_flow = k3*(port_a_T - T[1]);
          port_b_Q_flow = k3*(T[nT] - port_b_T);
      end InsulatedBaseRod;
    end BaseClasses;
  end ArrayEquations;

  package ArrayEquationsWithIndexReduction
    "Models with array equations that need to be differentiated"
    extends .Modelica.Icons.ExamplesPackage;

  model SlidingMass3D "Sliding mass in 3D"
    extends .Modelica.Icons.Example;
    parameter Real n[3] = {1,2,3};
    parameter Real m=1;
    parameter Real eps_m(min=0) = 0 "Small mass added to degree-of-freedom";
    Real u=0 "Generalized driving force";
    Real s(start=0.1, fixed=true);
    Real sd(start=0.2, fixed=true);
    Real r[3];
    Real v[3];
    Real f[3];
  equation
    r = n*s;
    v = der(r);
    f = m*der(v)+10*r;
    sd = der(s);
    0 = u + n*f - eps_m*der(sd); // scalar equation assigned for scalar der(sd)

  annotation(experiment(StopTime=5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
  end SlidingMass3D;

    model ExtraEquationColoring
      "Extra equation coloring needed when arrays are not expanded during index reduction"
      extends .Modelica.Icons.Example;
      Real n[3];
      Real l;
      Real e[3];
      Real s(start=1, fixed=true);
      Real r[3];
    equation
      l = sqrt(n*n);
      e = 2*n/l;
      r = e*s;
      e*der(r) = der(s) - s;
      n = {1,2,2*time};

    annotation(experiment(StopTime=1.5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>", info="<html>
<p>Standard index reduction on this model fails, if arrays are not expanded and only symbol information is used.
Instead, the index reduction algorithm must be slightly modified. The details for the <b>extension</b> of the
Pantelides algorithm (Constantinos C. Pantelides (1988): <i>The Consistent Initialization of Differential-Algebraic Systems</i>.
In: SIAM Journal on Scientific and Statistical Computing 9.2, pp. 213&ndash;231.
DOI: <a href=\"https://dx.doi.org/10.1137/0909014\">10.1137/0909014</a>) is provided in section 3 of</p>
<blockquote>
Martin Otter and Hilding Elmqvist (2025): <i>Resizable Arrays in Object-Oriented Modeling</i>. International Modelica & FMI Conference 2025.
</blockquote>

<p>
Other index reduction algorithms would need to be modified correspondingly.
An explanation for this model is given in the reference above.
</p>
</html>"));
    end ExtraEquationColoring;

  end ArrayEquationsWithIndexReduction;

  package ForLoops "Models with arrays and for-loops"
    extends .Modelica.Icons.ExamplesPackage;

    model CascadedFirstOrder "First order blocks connected in series (defined with for-loop)"
      extends .Modelica.Icons.Example;
      parameter Integer N=10;
      parameter Real tau=0.1 "Time constant";
      Real u;
      Real x[N](each start=0, each fixed=true);
    equation
      u = 1;
      for i in 1:N loop
        tau*der(x[i]) = (if i == 1 then u else x[i-1]) - x[i];
      end for;

    annotation(experiment(StopTime=2.0), Documentation(revisions="<html>
<ul>
<li>2016-04-05 by Francesco Casella: Initial version in the <a href=\"https://github.com/casella/ScalableTestSuite\">ScalableTestSuite</a>.</li>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>):  Adapted so that it can be processed without expanding arrays.</li>
</ul>
</html>"));
    end CascadedFirstOrder;

    model CocurrentHeatExchanger "Cocurrent heat exchanger from ScalableTestSuite (adapted for balanced array equations)"
      extends .Modelica.Icons.Example;
      import    Modelica.Units.SI;
      parameter Integer N = 10 "number of nodes";
      parameter SI.Length L=10 "length of the channels";
      parameter SI.MassFlowRate wB=1 "mass flow rate of fluid B";
      parameter SI.Area areaA=5e-5 "cross sectional area of channel A";
      parameter SI.Area areaB=5e-5 "cross sectional area of channel B";
      parameter SI.Density rhoA=1000 "density of fluid A";
      parameter SI.Density rhoB=1000 "density of fluid B";
      parameter SI.SpecificHeatCapacity cpA=4200
        "specific heat capacity of fluid A";
      parameter SI.SpecificHeatCapacity cpB=4200
        "specific heat capacity of fluid B";
      parameter SI.SpecificHeatCapacity cpW=2000
        "specific heat capacity of the wall";
      parameter SI.CoefficientOfHeatTransfer gammaA=4000
        "heat transfer coefficient of fluid A";
      parameter SI.CoefficientOfHeatTransfer gammaB=10000
        "heat transfer coefficient of fluid B";
      parameter SI.Length omega=0.1 "perimeter";
      SI.Length l "length of each wall segment";
      SI.MassFlowRate wA "mass flow rate of fluid A";
      SI.HeatFlowRate QA[N - 1]
        "heat flow rate of fluid A in the segments";
      SI.HeatFlowRate QB[N - 1]
        "heat flow rate of fluid B in the segments";
      SI.Temperature TA[N] "temperature nodes on channel A";
      SI.Temperature TB[N] "temperature nodes on channel B";
      SI.Temperature TAtilde[N - 1](each start=300, fixed=true) "temperature states on channel A";
      SI.Temperature TBtilde[N - 1](each start=300, fixed=true) "temperature states on channel B";
      SI.Temperature TW[N - 1](each start=300, fixed=true) "temperatures on the wall segments";
      SI.HeatFlowRate QtotA "total heat flow rate of fluid A";
      SI.HeatFlowRate QtotB "total heat flow rate of fluid B";
    equation
      l = L / (N - 1);
      TA = cat(1, {if time < 8 then 300 else 301}, TAtilde);
      TB = cat(1, {310}, TBtilde);

      wA = if time < 15 then 1 else 1.1;
      for i in 1:N - 1 loop
        rhoA * l * cpA * areaA * der(TAtilde[i]) = wA * cpA * TA[i] - wA * cpA * TA[i + 1] + QA[i];
        rhoB * l * cpB * areaB * der(TBtilde[i]) = wB * cpB * TB[i] - wB * cpB * TB[i + 1] - QB[i];
        QA[i] = (TW[i] - (TA[i] + TA[i + 1]) / 2) * gammaA * omega * l;
        QB[i] = ((TB[i] + TB[i + 1]) / 2 - TW[i]) * gammaB * omega * l;
        cpW / (N - 1) * der(TW[i]) = (-QA[i]) + QB[i];
      end for;
      QtotA = sum(QA);
      QtotB = sum(QB);

      annotation(experiment(StopTime=20), Documentation(revisions="<html>
<ul>
<li>2015-11-05 by Kaan Sezginer, Francesco Casella: Initial version in the <a href=\"https://github.com/casella/ScalableTestSuite\">ScalableTestSuite</a>.</li>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>):
    Adapted so that it can be processed without expanding arrays.</li>
</ul>
</html>"));
    end CocurrentHeatExchanger;
  end ForLoops;

  package ComponentArrays "Models with component arrays and for-loops"
      extends .Modelica.Icons.ExamplesPackage;
    model FiltersInSeries
        extends .Modelica.Icons.Example;
        model Filter
            input Real u;
            output Real x;
            parameter Real tau = 0.1;
        equation
            tau*der(x) = u-x;
        end Filter;
        parameter Integer N = 10 "Number of filters";
        Filter f[N](each x(start=0, fixed=true), u = cat(1, {1}, f[1:N-1].x));
    annotation(experiment(StopTime=2.0), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
</html>"));
    end FiltersInSeries;

    model TransmissionLine "Model of a transmission line, where a segment is defined with a resistor, capacitor and inductor"
        import Modelica.Electrical.Analog.Basic;
        extends .Modelica.Icons.Example;
        model TransmissionLineSegment
            parameter Real dx = 1 "Length of the segment in meters";
            parameter Real resistancePerMeter = 0.01;
            parameter Real inductancePerMeter = 0.001;
            parameter Real capacitancePerMeter = 1e-9;
            parameter Real conductancePerMeter = 1e-6;

            Modelica.Electrical.Analog.Interfaces.Pin p;
            Modelica.Electrical.Analog.Interfaces.Pin n;

            Basic.Resistor r(R=resistancePerMeter*dx);
            Basic.Inductor l(L=inductancePerMeter*dx, i(start=0,fixed=true));
            Basic.Capacitor c(C=capacitancePerMeter*dx, v(start=0,fixed=true));
            Basic.Conductor g(G=conductancePerMeter*dx);
            Basic.Ground ground;
        equation
            connect(p, r.p);
            // connect(l.n, g.p, c.p, n);
            connect(l.n, g.p);
            connect(g.p, c.p);
            connect(c.p, n);

            connect(r.n, l.p);

            //connect(g.n, c.n, ground.p);
            connect(g.n, c.n);
            connect(c.n, ground.p);
        end TransmissionLineSegment;

        parameter Integer N = 10 "Number of segments";
        parameter Real length = 1000 "Length of in meters";

        TransmissionLineSegment segments[N](dx=fill(length/N, N));

        Basic.Ground ground;
        Basic.Resistor load(R=100);
        Modelica.Electrical.Analog.Sources.ConstantVoltage
             source(V=10);
    equation
        // Connect the segments in series
        for i in 1:N-1 loop
            connect(segments[i].n, segments[i+1].p);
        end for;

        // Connect the first segment to the source
        connect(source.p, segments[1].p);
        connect(source.n, ground.p);
        // Connect the last segment to the load
        connect(segments[N].n, load.p);
        connect(load.n, ground.p);

    annotation(experiment(StopTime=0.01), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
</html>"));
    end TransmissionLine;
  end ComponentArrays;

  package ErrorsIfArraysNotExpanded
    "Models that are correct, but lead to errors if arrays are not expanded"
    extends .Modelica.Icons.ExamplesPackage;
    model LinearSystemOfEquations
      "Array assignment not possible if arrays are not expanded (can be detected early because assignment of extended system fails)"
      extends .Modelica.Icons.Example;
      parameter Real n[2] = {1,2};
      parameter Real A[2,2]= [1,2;-3,-2];
      Real y1[2];
      Real y2[2];
    equation
      y1 = n*time;
      A*y2 = y1;
    annotation(experiment(StopTime=1.5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
    end LinearSystemOfEquations;

    model ModelThatRequiresScalarization
      "Index reduction not possible if arrays are not expanded (results in infinite looping during index reduction)"
      extends .Modelica.Icons.Example;
      parameter Real n[3]={1,2,3};
      Real s(start=1, fixed=true);
      Real r[3];
    equation
        r = n*s;
        der(r)*n = -s;
    annotation(experiment(StopTime=1.5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>", info="<html>
<p>If this model is processed without expanding its arrays, index reduction will not terminate and an infinite loop occurs.
Typically, this loop is terminated after reaching some limit. Either a tool prints an error and explains the situation or the model
is again processed with arrays expanded. For details, see the discussion of Model 2 in </p>
<blockquote>
Martin Otter and Hilding Elmqvist (2025): <i>Resizable Arrays in Object-Oriented Modeling</i>. International Modelica & FMI Conference 2025.
</blockquote>
</html>"));
    end ModelThatRequiresScalarization;

    model WrongNumberOfArrayEquations
      "Number of non-expanded arrays is not equal to number of non-expanded variables"
      extends .Modelica.Icons.Example;
          parameter Real m = 1.0 "Mass of point mass";
          parameter Real L = 1.0 "Length of the pendulum";
          parameter Real g = 9.81 "Gravity";

          Real theta(start=2, fixed=true) "Angle of pendulum";
          Real der_theta(start=0, fixed=true) "Derivative of theta";
          Real r[2] "Position of mass point";
          Real v[2] "Velocity of mass point";
          Real T "Tension in rod";
    equation
          r = L*{sin(theta), -cos(theta)};
          m*der(v) = -T*{sin(theta), -cos(theta)} - m*{0, g};
          der(r) = v;
          der(theta) = der_theta;
    annotation(experiment(StopTime=1.5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
    end WrongNumberOfArrayEquations;

    model MixedAlgebraicAndStatesArray
      "Cascaded first order block, where an element of a vector is algebraic and the other elements are states"
      extends .Modelica.Icons.Example;

      parameter Integer N=3;
      parameter Real tau=0.1 "Time constant";
      Real u;
      Real x[N];
    equation
      u = 1;
      x[1] = u;
      for i in 2:N loop
        tau*der(x[i]) = x[i-1] - x[i];
      end for;

    annotation(experiment(StopTime=2.0), Documentation(info="<html>
<p>
This model is a variant of a set of cascaded first order blocks (model ScalableTestSuite.Elementary.SimpleODE.Models.CascadedFirstOrder)
from the <a href=\"https://github.com/casella/ScalableTestSuite\">ScalableTestSuite</a>.
In this model element x[1] is an algebraic variable, whereas elements x[2:N] are states.
Such a model can only be processed if arrays are expanded.
However, it is easy to rewrite the model, for example, in the form
<a href=\"modelica://BenchmarksForResizeableArrays.ForLoops.CascadedFirstOrder\">BenchmarksForResizeableArrays.ForLoops.CascadedFirstOrder</a>,
so that it can be processed without array expansion.
</p>

<p>
In similar cases, you need to split the arrays in different pieces so that all elements of an array are either algebraic or states.
</p>
</html>",
    revisions="<html>
<ul>
<li>2025-05-02 by Hilding Elmqvist (<a href=\"http://www.mogram.net/\">Mogram AB</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 <a href=\"http://www.mogram.net/\">Mogram AB</a></p>
</html>"));
    end MixedAlgebraicAndStatesArray;

  model SlidingMass3DthatRequiresScalarization
      "Index reduction of sliding mass in 3D not possible if arrays are not expanded"
    extends .Modelica.Icons.Example;
    parameter Real n[3] = {1,2,3};
    parameter Real m=1;
    Real u=0 "Generalized driving force";
    Real s(start=0.1, fixed=true);
    Real sd(start=0.2, fixed=true);
    Real r[3];
    Real v[3];
    Real f[3];
  equation
    r = n*s;
    v = der(r);
    f = m*der(v)+10*r;
    sd = der(s);
    0 = u + n*f; // equation cannot be assigned without expanding the arrays

  annotation(experiment(StopTime=5),
  Documentation(info="<html>
<p>
This is a (correct) model of a sliding mass in 3D that can only be processed if the arrays are expanded (index reduction is only possible with expanded arrays), as explained in
</p>

<blockquote>
<i>Martin Otter, Hilding Elmqvist (2025): Resizable Arrays in Object-Oriented Modeling. International Modelica & FMI Conference 2025.</i>
</blockquote>

<p>
However, the model can be slightly changed as shown in <a href=\"modelica://BenchmarksForResizeableArrays.ArrayEquationsWithIndexReduction.SlidingMass3D\">SlidingMass3D</a>,
in order that it can be processed with the new methods presented in the reference above - without expanding the arrays. This is a general method that works for all
tree-structured multibody systems. It is also possible to treat multibody systems with kinematic loops without array expansion, but this needs a slightly different design
of a corresponding library.
</p>
</html>",   revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
  end SlidingMass3DthatRequiresScalarization;

  model FailedConsistencyCheckOfSlidingMass3Db
    "Index reduction of sliding mass in 3D not possible if arrays are not expanded"
    extends .Modelica.Icons.Example;
    parameter Real n[3] = {1,2,3};
    parameter Real m=1;
    Real s(start=0.1, fixed=true);
    Real sd(start=0.2, fixed=true);
    Real r[3];
    Real v[3];
    Real f[3];
  equation
    r = n*s;
    v = der(r);
    f = m*der(v)+10*r;
    sd = der(s);
    0 = n*f; // equation cannot be assigned without expanding the arrays

  annotation(experiment(StopTime=5),
  Documentation(info="<html>
<p>
This is a (correct) model of a sliding mass in 3D that can only be processed if the arrays are expanded (index reduction is only possible with expanded arrays), as explained in
</p>

<blockquote>
<i>Martin Otter, Hilding Elmqvist (2025): Resizable Arrays in Object-Oriented Modeling. International Modelica & FMI Conference 2025.</i>
</blockquote>

<p>
However, the model can be slightly changed as shown in <a href=\"modelica://BenchmarksForResizeableArrays.ArrayEquationsWithIndexReduction.SlidingMass3D\">SlidingMass3D</a>,
in order that it can be processed with the new methods presented in the reference above - without expanding the arrays. This is a general method that works for all
tree-structured multibody systems. It is also possible to treat multibody systems with kinematic loops without array expansion, but this needs a slightly different design
of a corresponding library.
</p>
</html>",   revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
  end FailedConsistencyCheckOfSlidingMass3Db;
  end ErrorsIfArraysNotExpanded;

  package ErrorsIfArraysNotExpandedCorrected
    "Rewritten models of package ErrorsIfArraysNotExpanded, so that processing is possible without array expansion"
    extends .Modelica.Icons.ExamplesPackage;
    model FailedConsistencyCheckCorrected
      "Rewritten model FailedConsistencyCheck so that processing possible without array expansion"
      extends .Modelica.Icons.Example;
      parameter Real n[2] = {1,2};
      parameter Real A[2,2]= [1,2;-3,-2];
      Real y1[2];
      Real y2[2];
    equation
      y1 = n*time;
      y2 = Modelica.Math.Matrices.solve(A,y1);
    annotation(experiment(StopTime=1.5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
    end FailedConsistencyCheckCorrected;

    model InfiniteLoopingCorrected
      "Rewritten model InfiniteLooping so that processing possible without array expansion"
      extends .Modelica.Icons.Example;
      parameter Real n1=1;
      parameter Real n2[2]={2,3};
      Real s(start=1, fixed=true);
      Real r1;
      Real r2[size(n2,1)];
    equation
       r1 = n1*s;
       r2 = n2*s;
       der(r1)*n1 + der(r2)*n2 = -s;
    annotation(experiment(StopTime=1.5), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
    end InfiniteLoopingCorrected;

    model WrongNumberOfArrayEquationsCorrected
      "Rewritten model WrongNumberOfEquations so that processing possible without array expansion"
      extends .Modelica.Icons.Example;
      parameter Real m = 1.0 "Mass of point mass";
      parameter Real L = 1.0 "Length of the pendulum";
      parameter Real g = 9.81 "Gravity";
      parameter Real m_small(min=0) = 0 "Small mass added to degree-of-freedom";

      Real theta(start=2, fixed=true) "Angle of pendulum";
      Real der_theta(start=0, fixed=true) "Derivative of theta";
      Real r[2] "Position of mass point";
      Real v[2] "Velocity of mass point";
      Real f[2] "Force in the revolute joint";

    equation
      r = L*{sin(theta), -cos(theta)};
      m*der(v) = f - m*{0, g};
      der(r) = v;
      der(theta) = der_theta;
      0 = f*{cos(theta), sin(theta)} + m_small*der(der_theta);
    annotation(experiment(StopTime=3), Documentation(revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
    end WrongNumberOfArrayEquationsCorrected;

  model SlidingMass3DthatRequiresScalarizationCorrected
    "Index reduction of sliding mass in 3D not possible if arrays are not expanded"
    extends .Modelica.Icons.Example;
    parameter Real n[3] = {1,2,3};
    parameter Real m=1;
    parameter Real eps_m(min=0) = 0;
    Real s(start=0.1, fixed=true);
    Real sd(start=0.2, fixed=true);
    Real r[3];
    Real v[3];
    Real f[3];
  equation
    r = n*s;
    v = der(r);
    f = m*der(v);
    sd = der(s);
    0 = n*f - eps_m*der(sd); // equation cannot be assigned without expanding the arrays

  annotation(experiment(StopTime=5),
  Documentation(info="<html>
<p>
This is a (correct) model of a sliding mass in 3D that can only be processed if the arrays are expanded (index reduction is only possible with expanded arrays), as explained in
</p>

<blockquote>
<i>Martin Otter, Hilding Elmqvist (2025): Resizable Arrays in Object-Oriented Modeling. International Modelica & FMI Conference 2025.</i>
</blockquote>

<p>
However, the model can be slightly changed as shown in <a href=\"modelica://BenchmarksForResizeableArrays.ArrayEquationsWithIndexReduction.SlidingMass3D\">SlidingMass3D</a>,
in order that it can be processed with the new methods presented in the reference above - without expanding the arrays. This is a general method that works for all
tree-structured multibody systems. It is also possible to treat multibody systems with kinematic loops without array expansion, but this needs a slightly different design
of a corresponding library.
</p>
</html>",   revisions="<html>
<ul>
<li>2025-05-02 by Martin Otter (<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>): Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>)</p>
</p>
</html>"));
  end SlidingMass3DthatRequiresScalarizationCorrected;
  end ErrorsIfArraysNotExpandedCorrected;
  annotation (uses(Modelica(version="4.0.0")), Documentation(info="<html>
<p>Library <b>BenchmarksForResizeableArrays</b> is a <b>free</b> package providing benchmark models with arrays.
The goal is that the arrays can be resized after translation of the models (and before simulation starts).
</p>

<p>
These benchmarks shall help Modelica tools to support this desireable feature.
Furthermore, users can check in a simple way, whether a Modelica tool supports array resizing after translation
(just translate and after translation you should be able to change array dimensions).
This is especially valuable when exporting a model as Functional Mock-up Unit (FMU), because the FMU need no longer
be regenerated when array sizes shall be changed.</p>

<p>
The models in this library are presented and discussed in the following publication:<p>

<blockquote>
Martin Otter, Hilding Elmqvist (2025): <i>Resizable Arrays in Object-Oriented Modeling</i>.
International Modelica & FMI Conference 2025.
</blockquote>

<p>
Note, in subpackage <a href=\"modelica://BenchmarksForResizeableArrays.ErrorsIfArraysNotExpanded\">ErrorsIfArraysNotExpanded</a>
models are provided that cannot be processed without expanding array equations and arrays (at least internally). It is explained
how these models need to be (slightly) modified, in order that symbolic processing <b>without expanding array equations and arrays</b> becomes
possible.
</p>
</html>", revisions="<html>
<ul>
<li>2025-05-31 by Martin Otter, Hilding Elmqvist, Cl&eacute;ment Co&iuml;c: Initial version.</li>
</ul>
<p>Copyright &copy; 2025 Deutsches Zentrum f&uuml;r Luft- und Raumfahr e.V. - Institute of Vehicle Concepts .(<a href=\"https://www.dlr.de/en/fk\">DLR-FK</a>), <a href=\"http://www.mogram.net/\">Mogram AB</a>, Cl&eacute;ment Co&iuml;c.</p>
<p><i>This Modelica package is&nbsp;<u>free</u>&nbsp;software and the use is completely at&nbsp;<u>your own risk</u>; it can be redistributed with or without modification under the terms of the <a href=\"https://opensource.org/license/bsd-2-clause\">2-Clause BSD license</a>, </i>that is reproduced here:</p>
<blockquote>Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:</blockquote>
<blockquote>1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.</blockquote>
<blockquote>2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.</blockquote>
<blockquote>THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS &ldquo;AS IS&rdquo; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. </blockquote>
<p>Some of the models have been derived from other sources, as documented at the respective model, and summarized here:</p>
<ul>
<li>Models <a href=\"modelica://BenchmarksForResizeableArrays.ArrayEquations.CascadedFirstOrder1\">ArrayEquations.CascadedFirstOrder</a>, <a href=\"modelica://BenchmarksForResizeableArrays.ForLoops.CascadedFirstOrder\">ForLoops.CascadeFirstOrder</a>, <a href=\"modelica://BenchmarksForResizeableArrays.ForLoops.CocurrentHeatExchanger\">ForLoops.ConcurrentHeatExchanger</a><br>are derived from models of the <a href=\"https://github.com/casella/ScalableTestSuite\">ScalableTestSuite</a>, &copy; 2015 Politecnico di Milano under the <a href=\"https://github.com/casella/ScalableTestSuite?tab=BSD-3-Clause-1-ov-file#readme\">BSD-3-Clause license</a>. See also:<br><i>F. Casella (2015): &quot;Simulation of Large-Scale Models in Modelica: State of the Art and Future Perspectives&quot;, Proceedings of the 11th International Modelica Conference</i>, DOI: <a href=\"https://doi.org/10.3384/ecp15118459\">10.3384/ecp15118459</a>. </li>
<li>Models <a href=\"modelica://BenchmarksForResizeableArrays.ArrayEquations.InsulatedRodWithArrayEquations\">InsulatedRod1</a>, <a href=\"modelica://BenchmarksForResizeableArrays.ArrayEquations.InsulatedRodWithFunction\">InsulatedRod2</a><br>are derived from the model in <i>Appendix B.1. Heated Rod with Acausal Built-In Component</i> from <i>A. Neumayr, M. Otter (2023): Modelling and Simulation of Physical Systems with Dynamically Changing Degrees of Freedom. Electronics, 12(3), 500,</i> DOI: <a href=\"https://doi.org/10.3390/electronics12030500\">10.3390/electronics12030500</a>. &copy; 2023 by the authors. Licensee MDPI, Basel, Switzerland. This article is an open access article distributed under the terms and conditions of the Creative Commons Attribution (CC BY) license (<a href=\"https://creativecommons.org/licenses/by/4.0/\">https://creativecommons.org/licenses/by/4.0/</a>). </li>
</ul>
<p>This library was developed in the European ITEA4 project <a href=\"https://itea4.org/project/openscaling.html\">OpenSCALING - Open Standards for SCALable virtual engineerING and operation</a>. The work of Martin Otter from <a href=\"https://www.dlr.de/en/fk\">DLR-FK</a> to develop this library was funded by the German Federal Ministry of Education and Research (BMBF, grant number 01IS23062C). </p>
</html>"));
end BenchmarksForResizeableArrays;