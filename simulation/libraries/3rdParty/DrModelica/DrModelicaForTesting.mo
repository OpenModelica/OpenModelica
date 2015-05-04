within ;
package DrModelicaForTesting

  model VanDerPol  "Van der Pol oscillator model"
    Real x(start = 1);
    Real y(start = 1);
    parameter Real lambda = 0.3;
  equation
    der(x) = y;
    der(y) = - x + lambda*(1 - x*x)*y;

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end VanDerPol;

  model ABCDsystem
    parameter Integer n = 0;
    Real u[5] = {15, 4, 3, 9, 11};
    Real x[n];
    Real y[3];
    Real A[n, n], B[n, 5], C[3, n];
    Real D[3, 5] = fill(1, 3, 5);
  equation
    der(x) = A*x + B*u;             // This will disappear since x is empty
    y = C*x + D*u;                  // Which is: y = D*u

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end ABCDsystem;

  class Activate
    constant Real x = 4;
    Real y, z;
  equation
    when initial() then y = x + 3; // Equations to be activated at the beginning
    end when;
    when terminal() then z = x - 2; // Equations to be activated at the end of the simulation
    end when;

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end Activate;

  model CondAssign
    Real x(start = 35);
    Real y(start = 45);
    parameter Real z = 0;
  algorithm
    if x > 5 then
    x := 400;
    end if;
    if z > 10 then
    y := 500;
    end if;

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end CondAssign;

  function CondAssignFunc
    input Real z;
    output Real x = 35;
    output Real y = 45;
  algorithm
    if x > 5 then
    x := 400;
    end if;
    if z > 10 then
    y := 500;
    end if;
  end CondAssignFunc;

  model CondAssignFuncCall
    Real a, b;
  equation
    (a, b) = CondAssignFunc(5);

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end CondAssignFuncCall;

  model AlgorithmSection
    Real x, z, u;
    parameter Real w = 3, y = 2;
    Real x1, x2, x3;
  equation
    x = y*2;
    z = w;
  algorithm
    x1 := z  + x;
    x2 := y  - 5;
    x3 := x2 + y;
  equation
    u = x1 + x2;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end AlgorithmSection;

  class AppendElement
    Real[1, 3] PA=[1, 2, 3];
    // A row matrix value
    Real[3, 1] PB=[1; 2; 3];
    // A column matrix value
    Real[3] q={1,2,3};
    // A vector value

    Real[1, 4] XA1;
    Real[1, 4] XA2;
    Real[1, 4] XA3;
    Real[1, 4] XA4;
    // Row matrix variables
    Real[4, 1] XB1;
    Real[4, 1] XB2;
    // Column matrix variables
    Real[4] y;
  equation
    // Vector variable

    XA1 = [PA, 4];
    // Append OK, since 4 is promoted to {{4}}
    XA2 = cat(2, PA, {{4}});
    // Append OK, same as above but not promoted

    XB1 = [PB; 4];
    // Append OK, result is {{1}, {2}, {3}, {4}}
    XB2 = cat(1, PB, {{2}});
    // Append OK, same result

    y = cat(1, q, {4});
    // Vector append OK, result is {1, 2, 3, 4}

    XA3 = [-1, zeros(1, 2), 1];
    // Append OK, result is {{-1, 0, 0, 1}}
    XA4 = cat(2, {{-1}}, zeros(1, 2), {{1}});
    // Append OK, result is {{-1, 0, 0, 1}}

     annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end AppendElement;

  class AddEmpty
    Real[3, 0] A, B;
    Real[0, 0] C;
    Real ab[3, 0] = A + B; // Fine, the result is an empty matrix of type Real[3, 0]
    //Real ac = A + C; // Error,incompatible types Real[3, 0] and Real[0, 0]

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end AddEmpty;

  class AddSub1
    Real Add3[2, 2] = {{1, 1}, {2, 2}} + {{1, 2}, {3, 4}};
                      // Result: {{2, 3}, {5, 6}}
    Real Sub1[3] = {1, 2, 3} - {1, 2, 0};    // Result: {0, 0, 3}

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end AddSub1;

  class ArrayAlgebraFunc
    Real transp1[2, 2] = transpose([1, 2; 3, 4]); // Gives [1, 2; 3, 4] of type Integer[2, 2]
    Real transp2[2, 2, 1] = transpose({{{1},{2}},{{3},{4}}}); // Gives {{{1},{2}},{{3},{4}}} of type Integer[2, 2, 1]
    Real out[2, 2] = outerProduct({2, 1}, {3, 2}); // Gives {{6, 4}, {3, 2}}
    Real symm[2, 2] = symmetric({{1, 2}, {3, 1}}); // Gives {{1, 2}, {2, 1}}
    Real c[3] = cross({1, 0, 0}, {0, 1, 0}); // Gives {0, 0, 1}
    Real s[3, 3] = skew({1, 2, 3}); // Gives {{0, -3, 2}, {3, 0, -1}, {-2, 1, 0}};

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end ArrayAlgebraFunc;

  type Angle = Real(unit="rad"); // The type Angle is a subtype of Real

  class ArrayConstruct1
    Integer[3] a = {1, 2, 3}; // A 3-vector of type Integer[3]
    Real[3] b = array(1.0, 2.0, 3); // A 3-vector of type Real[3]
    Integer[2,3] c = {{11, 12, 13}, {21, 22, 23}}; // A 2x3 matrix of type Integer[2,3]
    Real[1,1,3] d ={{{1.0, 2.0, 3.0}}}; // A 1x1x3 array of type Real[1,1,3]
    Real[3] v = array(1, 2, 3.0); // The vector v is equal to {1.,2.,3.}
    parameter Angle alpha = 2.0; // The expanded type of alpha is Real
    Real[3] f = array(alpha, 2, 3.0); // A 3-vector of type Real[3]
    Angle[3] A = {1.0, alpha, 4}; // The expanded type of A is Real[3]

    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end ArrayConstruct1;



  model ArrayDim1
    import Modelica.SIunits.Voltage;
    parameter Integer n = 1;
    parameter Integer m = 2;
    parameter Integer k = 3;

    // 3-dimensional position vector
    Real[3] positionvector = {1, 2, 3};

    // transformation matrix
    Real[3,3] identitymatrix = {{1,0,0},{0,1,0},{0,0,1}};

    // A 3-dimensional array
    Integer[n,m,k] arr3d;

    // A boolean vector
    Boolean[2] truthvalues = {false, true};

    // A vector of voltage values
    Voltage[10] voltagevector;

  equation
    voltagevector = {1,2,3,4,5,6,7,8,9,0};
    for i in 1:n loop
    for j in 1:m loop
      for l in 1:k loop
      arr3d[i,j,l] = i+j+l;
      end for;
    end for;
    end for;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayDim1;

  model ArrayDim2
    import Modelica.SIunits.Voltage;
    parameter Integer n = 1;
    parameter Integer m = 2;
    parameter Integer k = 3;

    // 3-dimensional position vector
    Real positionvector[3] = {1, 2, 3};

    // transformation matrix
    Real identitymatrix[3,3] = {{1,0,0},{0,1,0},{0,0,1}};

    // A 3-dimensional array
    Integer arr3d[n,m,k];

    // A boolean vector
    Boolean truthvalues[2] = {false, true};

    // A vector of voltage values
    Voltage voltagevector[10];

  equation
    voltagevector = {1,2,3,4,5,6,7,8,9,0};
    for i in 1:n loop
    for j in 1:m loop
      for l in 1:k loop
      arr3d[i,j,l] = i+j+l;
      end for;
    end for;
    end for;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayDim2;

  model ArrayDim3
    parameter Integer n = 1;
    parameter Integer m = 2;
    parameter Integer k = 3;

    // 3-dimensional position vector
    Real[3] positionvector = {1, 2, 3};

    // transformation matrix
    Real[3,3] identitymatrix = {{1,0,0},{0,1,0},{0,0,1}};

    // A 3-dimensional array
    Integer[n,m,k] arr3d;

    // A boolean vector
    Boolean[2] truthvalues = {false, true};

  equation
    for i in 1:n loop
    for j in 1:m loop
      for l in 1:k loop
      arr3d[i,j,l] = i+j+l;
      end for;
    end for;
    end for;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayDim3;

  model ArrayDim4
    parameter Integer n = 1;
    parameter Integer m = 2;
    parameter Integer k = 3;

    // 3-dimensional position vector
    Real positionvector[3] = {1, 2, 3};

    // transformation matrix
    Real identitymatrix[3,3] = {{1,0,0},{0,1,0},{0,0,1}};

    // A 3-dimensional array
    Integer arr3d[n,m,k];

    // A boolean vector
    Boolean truthvalues[2] = {false, true};

  equation
    for i in 1:n loop
    for j in 1:m loop
      for l in 1:k loop
      arr3d[i,j,l] = i+j+l;
      end for;
    end for;
    end for;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayDim4;

  class ArrayDiv
    Real Div1[3];
  equation
    Div1 = {2, 4, 6} / 2;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayDiv;

  class Exp
    Real e1[2, 2];
    Real e2[2, 2];
  equation

    e1 = {{1, 2}, {1, 2}} ^ 0;
    // Result: {{1, 0}, {0, 1}}

    e2 = [1, 2; 1, 2] ^ 2;
    // Result: {{3, 6}, {3, 6}}

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Exp;

  record Person
    String       name;
    Integer       age;
    String[2]      children;
  end Person;

  function mkperson
    input String     name;
    input Integer   age;
    input String[2]  children;
    output Person p;
  algorithm
    p.name       := name;
    p.age       := age;
    p.children     := children;
  end mkperson;

  class PersonList
    Person[3] persons = {mkperson("John", 35, {"Carl", "Eva"} ),
              mkperson("Karin", 40, {"Anders", "Dan"} ),
              mkperson("Lisa", 37, {"John", "Daniel"} )
        };
  end PersonList;


  class getPerson
    PersonList pList;
    String name[3];
    Integer age[3];
    String[3, 2] children;
  equation
    name     = pList.persons.name;   // Returns: {"John", "Karin", "Lisa"}
    age     = pList.persons.age;  // Returns: {35, 40, 37}
    children   = pList.persons.children;  // Returns: {{"Carl", "Eva"},
                //     {"Anders", "Dan"},
                //     {"John", "Daniel"}}

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end getPerson;

  class ArrayIndex
    Real[2, 2] A = {{2, 3}, {4, 5}}; // Definition of array A
    Real A_Retrieval = A[2, 2]; // Retrieves the array element value 5
    Real B[2, 2];
    Real c;
  algorithm
    B := fill(1,2,2); // B will have the values {{1, 1}, {1, 1}}
    B[2, 1] := 8; // Assignment to the array element B[2, 1]
    c := A[1, 1];

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayIndex;

  class ArrayMult
    Real m1[3] = {1, 2, 3} * 2;       // Elementwise mult: {2, 4, 6};
    Real m2[3] = 3 * {1, 2, 3};       // Elementwise mult: {3, 6, 9};
    Real m3 = {1, 2, 3} * {1, 2, 2};     // Scalar product:    11;
    Real m4[2] = {{1, 2}, {3, 4}} * {1, 2};   // Matrix mult:    {5, 11};
    Real m5[1] = {1, 2, 3} * {{1}, {2}, {10}};    // Matrix mult:    {35};
    Real m6[1] = {1, 2, 3} * [1; 2; 10];       // Matrix mult:     {35};
    Real m7[2, 2] = {{1, 2}, {3, 4}} * {{1, 2}, {2, 1}};   // Matrix mult:   {{5, 4}, {11, 10}};
    Real m8[2, 2] = [1, 2; 3, 4] * [1, 2; 2, 1];   // Matrix mult: {{5, 4}, {11, 10}};

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayMult;

  class ArrayReduce
    Real minimum, maximum, summ, prod;
  equation
    minimum = min({1, -1, 7});              // Gives the value -1
    maximum = max([1, 2, 3; 4, 5, 6]);      // Gives the value 6
    summ    = sum({{1, 2, 3}, {4, 5, 6}});  // Gives the value 21
    prod    = product({3.14, 2, 2});        // Gives the value 12.56

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ArrayReduce;

  class AssertTest
    parameter Real lowlimit   = -5;
    parameter Real highlimit   =  5;
    parameter Real x = 7;
  equation
    assert(x >= lowlimit and x <= highlimit, "Variable x out of limit");
  end AssertTest;

  class AssertTestInst
    AssertTest assertTest(lowlimit = -2, highlimit = 6, x = 5);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end AssertTestInst;

  class AssertTest1
    parameter Real lowlimit;
    parameter Real highlimit;
    Real x = 5;
  equation
    assert(x >= lowlimit and x <= highlimit, "Variable x out of limit");
  end AssertTest1;

  class AssertTest2
    AssertTest assertTest1(lowlimit = 4, highlimit = 8);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end AssertTest2;

  class AssertTest3
    AssertTest assertTest1(lowlimit = 6, highlimit = 20);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end AssertTest3;

  model BouncingBall     "The bouncing ball model"
    constant Real g = 9.81;  // Gravitational acceleration
    parameter Real c = 0.9;  // Elasticity constant of ball
    parameter Real radius = 0.1;  // Radius of the ball
    Real height(start = 1);  // height above ground of the ball center
    Real velocity(start = 0);  // Velocity of the ball
  equation
    der(height) = velocity;
    der(velocity) = -g;
    when height <= radius then
    reinit(velocity, -c*pre(velocity));
    end when;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end BouncingBall;

  record ColorData "Superclass of Color"
    parameter Real red;
    parameter Real blue;
    Real green;
  end ColorData;

  class Color "Subclass of ColorData"
    extends ColorData;
  equation
    red + blue + green = 1;
  end Color;

  model Colors
    Color c(red=0.7,blue=0.1);
    Real k;
  equation
    k = c.green;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Colors;

package Modelica
  package SIunits
  type ElectricCurrent = Real (final quantity="ElectricCurrent", final unit="A");
  type Current = ElectricCurrent;
   type Voltage = ElectricPotential;
   type ElectricPotential = Real ( final quantity="ElectricPotential",
    final unit="V");
  end SIunits;
end Modelica;

  connector Pin
    import Modelica.SIunits.Voltage;
    import Modelica.SIunits.Current;
    Voltage v;
    flow Current i;
  end Pin;

  partial class TwoPin "Superclass of elements with two electrical pins"
    import Modelica.SIunits.Voltage;
    import Modelica.SIunits.Current;
    Pin p;
    Pin n;
    Voltage v;
    Current i;
  equation
    v = p.v - n.v;
    p.i + n.i = 0;
    i = p.i;
  end TwoPin;

  model Diode "Ideal diode"
    extends TwoPin;
    Real s;
    Boolean off;
  equation
    off = s < 0;
    if off then
    v = s;
    else
    v = 0;
    end if;
    i = if off then 0 else s;
  end Diode;

  model Circuit
    import Modelica.Electrical.Analog.Basic.*;
    import Modelica.Electrical.Analog.Sources.*;
    Diode d;
    Resistor R1;
    Ground G;
    SineVoltage src;
  equation
    connect(G.p, src.n);
    connect(src.p, R1.n);
    connect(R1.p, d.n);
    connect(d.p, src.p);
  end Circuit;


  class Concat3
    Real[2, 3] r1 = cat(1, {{1.0, 2.0, 3}}, {{4, 5, 6}});
    Real[2, 6] r2 = cat(2, r1, r1);
    Real[2, 3] r3 = cat(2, r1);
    Real[4, 3] r4 = cat(1, r1, r1);
    Real[:] r5 = cat(1, {1,2,3}, {4,time,6});

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Concat3;

  class ConcatArr1
    Real[5] c1 = cat(1, {1, 2}, {10, 12, 13}); // Result: {1, 2, 10, 12, 13}
    Real[2, 3] c2 = cat(2, {{1, 2}, {3, 4}}, {{10}, {11}}); // Result: {{1, 2, 10}, {3, 4, 11}}

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ConcatArr1;

  class ConcatArr2
    Real[2, 3] c3 = cat(2, [1, 2; 3, 4], [10; 11]); // Same result: {{1, 2, 10}, {3, 4, 11}}

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ConcatArr2;

  class ConcatArr4
    Real[1, 1, 1] A = {{{1}}};
    Real[1, 1, 2] B = {{{2, 3}}};
    Real[1, 1, 3] C = {{{4, 5, 6}}};
    Real[1, 1, 6] R = cat(3, A, B, C); // Result value: {{{1, 2, 3, 4, 5, 6}}};

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ConcatArr4;


  class ConstructFunc
    Real z[2,3]  = zeros(2, 3);  // Constructs the matrix {{0,0,0}, {0,0,0}}
    Real o[3]    = ones(3);      // Constructs the vector {1, 1, 1}
    Real f[2,2]  = fill(2.1,2,2); // Constructs the matrix {{2.1, 2.1}, {2.1, 2.1}}
    Boolean check[3, 4]  = fill(true, 3, 4);   // Fills a Boolean matrix
    Real id[3,3]    = identity(3);    // Creates the matrix {{1,0,0}, {0,1,0}, {0, 0, 1}}
    Real di[3,3] = diagonal({1, 2, 3}); // Creates the matrix {{1, 0, 0}, {0, 2, 0}, {0, 0, 3}}
    Real ls[5] = linspace(0.0, 8.0, 5);  // Computes the vector {0.0, 2.0, 4.0, 6.0, 8.0}

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ConstructFunc;

  model DAEexample
    Real x(start = 0.9);
    Real y;
    parameter Real a=2;
  equation
    (1 + 0.5*sin(y))*der(x) + der(y) = a*sin(time);
    x-y = exp(-0.9*x)*cos(y);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end DAEexample;

  class DimConvert
    Real[3] v1 =      {1.0, 2.0, 3.0};
    Real[3,1] m1 =    matrix(v1);     // m1 contains {{1.0}, {2.0}, {3.0}}
    Real[3] v2 =      vector(m1);     // v2 contains {1.0, 2.0, 3.0}

    Real[1,1,1] m2 =  {{{4}}};
    Real s1 =         scalar(m2);     // s1 contains 4.0
    Real[2,2,1] m3 =  {{{1.0}, {2.0}}, {{3.0}, {4.0}}};
    Real[2,2] m4 =    matrix(m3);     // m4 contains {{1.0, 2.0}, {3.0, 4.0}}

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end DimConvert;


  model DiscreteVectorStateSpace
    parameter Integer n = 5, m = 4, p = 2;
    parameter Real A[n, n] = fill(1, n, n);
    parameter Real B[n, m] = fill(2, n, m);
    parameter Real C[p, n] = fill(3, p, n);
    parameter Real D[p, m] = fill(4, p, m);
    parameter Real T = 1;
    input Real u[m];
    discrete output Real y[p];
  protected
    discrete Real x[n];// = fill(2, n);
  equation
    when sample(0, T) then
    x = A * pre(x) + B * u;
    y = C * pre(x) + D * u;
    end when;
  end DiscreteVectorStateSpace;

  model DVSSTest
    DiscreteVectorStateSpace dvss;
  equation
    dvss.u= fill(time,dvss.m);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end DVSSTest;

  model DoubleWhenSequential
    Boolean close;          // Possible conflicting definitions resolved by
    //parameter Real time = 2;      // sequential assignments in an algorithm section
  algorithm
    when time <= 2 then
    close := true;
    end when;

    when time <= 2 then
    close := false;
    end when;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end DoubleWhenSequential;

  function ewm
    input Real[3] positionvector;
    output Real[3] result;
  algorithm
    result := positionvector * 2;
  end ewm;

  model ElementWiseMultiplication
    Real inVector[3] = {3,6,1};
    Real result[3];
  equation
    result = ewm(inVector);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ElementWiseMultiplication;

  connector RealOutput = output Real;

  connector RealInput = input Real;

  expandable connector EngineBus  // Initially empty expandable connector

  end EngineBus;

  block Sensor

    RealOutput speed; // Non-input since it is an output

  end Sensor;

  block Actuator

    RealInput speed;  // Input

  end Actuator;

  model Engine

    EngineBus bus;

    Sensor sensor;

    Actuator actuator(speed=10);

  equation

    connect(bus.speed, sensor.speed);   // sensor.speed provides the non-input

    connect(bus.speed, actuator.speed); // actuator.speed is the input

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));

  end Engine;

  model Epidemics1
    Real Indv(start=0.005);
    Real S(start=0.995);
    Real R(start=0);
    parameter Real tau=0.8;
    parameter Real k=4.0 "recovery coefficient (from 4people infected one is recoved)" ;
  equation
    der(Indv) = tau * Indv * S - Indv / k;
    der(S) = -tau * Indv * S;
    der(R) = Indv/k;
    when (Indv < 10e-5) then
      terminate("Simulation terminated");
    end when;
    when (S < 10e-5) then
      terminate("Simulation terminated");
    end when;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Epidemics1;

  function f
    input Real a;
    input Real b;
    output Real c;
    output Real d;
    output Real e;
  algorithm
    c := a + b;
    d := a - b;
    e := a * b;
  end f;

  class EqualityEquationsCorrect
    Real x;
    Real y;
    Real z;
    Real u;
    Real v = 2;
  equation
    u = v;                    // Equality equations between two expressions
    (x, y, z) = f(1.0, 2.0);        // Correct!

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end EqualityEquationsCorrect;

  function PointOnCircle
    input Real angle "Angle in radians";
    input Real radius;
    output Real x; // 1:st result formal parameter
    output Real y; // 2:nd result formal parameter
  algorithm
    x := radius*cos(angle);//Modelica.Math.cos(angle);
    y := radius*sin(angle);//Modelica.Math.sin(angle);
  end PointOnCircle;

  class EquationCall
    Real px, py;
  equation
    (px, py) = PointOnCircle(1.2, 2);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end EquationCall;

  class Equations
    Real x(start = 2);        // Modification equation
    constant Integer one = 1;      // Declaration equation
  equation
    x = 3*one;            // Normal equation

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Equations;

  block FilterBlock1
    parameter Real T = 1 "Time constant";
    parameter Real k = 1 "Gain";
    input Real u = 1;
    output Real y;
  protected
    Real x;
  initial equation
    x = u; // if x is u since der(x) = (u - x)/T
  equation
    der(x) = (u - x)/T;
    y = k*x;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end FilterBlock1;

  class FiveForEquations
    Real[5] x;
  equation
    for i in 1:5 loop
    x[i] = i + 1;
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end FiveForEquations;

  function limitValue
    input  Real pMin;
    input  Real pMax;
    input  Real p;
    output Real pLim;
   algorithm
    pLim := if p>pMax then pMax
        else if p<pMin then pMin
        else p;
  end limitValue;

  model FlatTank
   // Tank related variables and parameters
    parameter Real flowLevel(unit = "m3/s") = 0.02;
    parameter Real area(unit = "m2")        = 1;
    parameter Real flowGain(unit = "m2/s")  = 0.05;
    Real           h(start = 0, unit = "m")     "Tank level";
    Real           qInflow(unit = "m3/s")       "Flow through input valve";
    Real           qOutflow(unit = "m3/s")      "Flow through output valve";

   // Controller related variables and parameters
    parameter Real K = 2                     "Gain";
    parameter Real T(unit = "s")  = 10       "Time constant";
    parameter Real minV = 0,  maxV = 10;  // Limits for flow output
    Real           ref = 0.25                "Reference level for control";
    Real           error                     "Deviation from reference level";
    Real           outCtr                    "Control signal without limiter";
    Real           x                         "State variable for controller";

  equation
    assert(minV>=0, "minV must be greater or equal to zero");
    der(h)   = (qInflow - qOutflow)/area;           // Mass balance equation
    qInflow    = if time > 150 then 3*flowLevel else flowLevel;
    qOutflow   = limitValue(minV, maxV, -flowGain*outCtr);
    error    = ref - h;
    der(x)   = error/T;
    outCtr   = K*(error + x);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end FlatTank;

  model HideVariable
    constant Integer k = 4;
    Real z[k + 1];
  algorithm
    for k in 1:k+1 loop // The iteration variable k gets values 1, 2, 3, 4, 5
    z[k] := k;
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end HideVariable;

  function h0                 // exp(x(t)+i1)
    annotation(derivative=h1);
    input  Integer i1;
    input  Real    x;
    input  Boolean linear;        // not used
    output Real    y;
   algorithm
    y := exp(x)+i1;
  end h0;

  function h1                 // (d/dt)(exp(x(t))
    annotation(derivative(order=2)=h2);
    input  Integer i1;
    input  Real    x;
    input  Boolean linear;
    input  Real    der_x;
    output Real    der_y;
  algorithm
    der_y := exp(x)*der_x;
  end h1;

  function h2                 // (d/dt)(exp(x(t)*der_x(t))
    input  Integer i1;
    input  Real    x;
    input  Boolean linear;
    input  Real    der_x;
    input  Real    der_2_x;
    output Real    der_2_y;
  algorithm
    der_2_y := exp(x)*der_x*der_x + exp(x)*der_2_x;
  end h2;

  // added by x06klasj
  model FuncDer
    Real fn0;
    Real fn1;
    Real fn2;
  algorithm
    fn0 := h0(2,5,true);
    fn1 := h1(2,5,true,fn0);
    fn2 := h2(2,5,true,fn0,fn1);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end FuncDer;

  function f1
    input Real x;
    input Real y;
    output Real r1;
    output Real r2;
    output Real r3;
  algorithm
    r1 := x;
    r2 := y;
    r3 := x*y;
  end f1;

  model fCall
    Real x[3];
    Real a, b, c;
  equation
    (a, b, c) = f(1.0, 2.0);
    (x[1], x[2], x[3]) = f1(3.0, 4.0);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end fCall;

  model HelloWorld
    Real x(start = 1);
    parameter Real a = 1;
  equation
    der(x) = - a * x;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end HelloWorld;

  class HideVariableForEquations
    constant Integer k = 4;
    Real     x[k + 1];
  equation
    for k in 1:k+1 loop  // The iteration variable k gets values 1, 2, 3, 4, 5
    x[k] = k;          // Uses of the iteration variable k
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end HideVariableForEquations;


  type Concentration = Real(final quantity ="Concentration",final unit = "mol/m3");

  class HydrogenIodide
    parameter Real k1 = 0.73;
    parameter Real k2 = 0.04;
    Concentration H2(start=5);
    Concentration I2(start=8);
    Concentration HI(start=0);
  equation
    der(H2) = k2*HI^2 - k1*H2*I2;
    der(I2) = k2*HI^2 - k1*H2*I2;
    der(HI) = 2*k1*H2*I2 - 2*k2*HI^2;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end HydrogenIodide;

  class IfEquation
    parameter Real u;
    parameter Real uMax;
    parameter Real uMin;
    Real y;
  equation
    if u > uMax then
    y = uMax;
    elseif u < uMin then
    y = uMin;
    else
    y = u;
    end if;

  end IfEquation;

  model Test
    IfEquation y1(u = 1.0, uMax = 2.0, uMin = 0.0);
    IfEquation y2(u = 0.0, uMax = 2.0, uMin = 0.0);
    IfEquation y3(u = 3.0, uMax = 2.0, uMin = 0.0);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Test;

  function mylog "Natural logarithm"
    input Real x;
    output Real y;
    external "C" y=log(x);
  end mylog;

  model LogCall1
    Real res;
  equation
    res = mylog(100);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end LogCall1;

  class LotkaVolterra
    parameter Real g_r =0.04 "Natural growth rate for rabbits";
    parameter Real d_rf=0.0005 "Death rate of rabbits due to foxes";
    parameter Real d_f =0.09 "Natural deathrate for foxes";
    parameter Real g_fr=0.1 "Efficency in growing foxes from rabbits";
    Real rabbits(start=700) "Rabbits,(R) with start population 700";
    Real foxes(start=10) "Foxes,(F) with start population 10";
  equation
    der(rabbits) = g_r*rabbits - d_rf*rabbits*foxes;
    der(foxes) = g_fr*d_rf*rabbits*foxes -d_f*foxes;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end LotkaVolterra;

  model LowPassFilter
    parameter Real T = 1;
    Real u;
    Real y(start = 1);
  equation
    T*der(y) + y = u;
  end LowPassFilter;

  model FiltersInSeries
    LowPassFilter F1(T = 2);
    LowPassFilter F2(T = 3);
  equation
    F1.u = sin(time);
    F2.u = F1.y;
  end FiltersInSeries;

  model ModifiedFiltersInSeries
    FiltersInSeries F12(F1(T = 6), F2(T = 11));
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end ModifiedFiltersInSeries;

  model Body "Generic body"
    Real mass;
    String name;
  end Body;

  model CelestialBody "Celestial body"
    extends Body;
    constant Real g = 6.672e-11;
    parameter Real radius;
  end CelestialBody;

  class Rocket
    extends Body;
    Real altitude(start = 59404);
    Real velocity(start = -2003);
    Real acceleration;
    Real thrust; // Thrust force on the rocket
    Real gravity; // Gravity forcefield
    parameter Real massLossRate = 0.000277;
  equation
    (thrust - mass*gravity) / mass = acceleration;
    der(mass) = -massLossRate * abs(thrust);
    der(altitude) = velocity;
    der(velocity) = acceleration;
  end Rocket;

  model MoonLanding
    parameter Real force1 = 36350;
    parameter Real force2 = 1308;
    parameter Real thrustEndTime = 210;
    parameter Real thrustDecreaseTime = 43.2;
    Rocket apollo(name = "Apollo13", mass(start=1038.358));
    CelestialBody moon(name = "moon", mass = 7.382e22,radius = 1.738e6);
  equation
    apollo.thrust = if (time < thrustDecreaseTime) then force1
    else if (time < thrustEndTime) then force2
    else 0;
    apollo.gravity = moon.g*moon.mass/(apollo.altitude + moon.radius)^2;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end MoonLanding;

  function MultipleResultsFunction
    input Real x;
    input Real y;
    output Real r1;
    output Real r2;
    output Real r3;
  algorithm
    r1 := x + y;
    r2 := x * y;
    r3 := x - y;
  end MultipleResultsFunction;

  class MRFcall
    Real a, b, c;
  equation
    (a, b, c) = MultipleResultsFunction(2.0, 1.0);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end MRFcall;

  function Multiply
    input Real x;
    input Real y;
    output Real result;
  algorithm
    result := x*y;
  end Multiply;

  model MultFuncCall
    Real res;
  equation
    res = Multiply(3.5, 2.0);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end MultFuncCall;

  function PolynomialEvaluator1
    input Real A[:]; // Array, size defined at function call time
    input Real x = 1.0; // Default value 1.0 for x
    output Real sum;
  protected
    Real xpower;
  algorithm
    sum := 0;
    xpower := 1;
    for i in 1:size(A, 1) loop
    sum := sum + A[i]*xpower;
    xpower := xpower*x;
    end for;
  end PolynomialEvaluator1;

  class PositionalCall
    Real p;
  equation
    p = PolynomialEvaluator1({1,2,3,4},21);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end PositionalCall;

  function polyeval
    input Real a[:];
    input Real x = 1;
    output Real y;
  protected
    Real xpower;
  algorithm
    y := 0;
    xpower := 1;
    for i in 1:size(a,1) loop
    y := y + a[i]*xpower;
    xpower := xpower * x;
    end for;
  end polyeval;

  model PolynomialEvaluator2
    Real inVector[3] = {3,8,5};
    Real result;
  equation
    result = polyeval(inVector);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end PolynomialEvaluator2;

  function PolynomialEvaluatorB
    input Real A[:]; // Array, size defined at function call time
    input Real x = 1.0; // Default value 1.0 for x
    output Real sum;
  protected
    Real xpower;
  algorithm
    sum := 0;
    xpower := 1;
    for i in 1:size(A, 1) loop
    sum := sum + A[i]*xpower;
    xpower := xpower*x;
    end for;
  end PolynomialEvaluatorB;

  class NamedCall
    Real p;
  equation
    p = PolynomialEvaluatorB(A = {1, 2, 3, 4}, x = 21);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end NamedCall;

  block PolynomialEvaluator
    parameter Real c[:];
    input Real x;
    output Real y;
  protected
    parameter Integer n = size(c, 1) - 1;
    Real xpowers[n + 1];
  equation
    xpowers[1] = 1;
    for i in 1:n loop
    xpowers[i + 1] = xpowers[i]*x;
    end for;
    y = c[1] * xpowers[n + 1];
  end PolynomialEvaluator;

  class PolyEvaluate1
    Real p;
    PolynomialEvaluator polyeval(c = {1, 2, 3, 4});
  equation
    polyeval.x = time;
    p = polyeval.y;              // p gets the result
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end PolyEvaluate1;


  class PolyEvaluate2
    Real p;
    PolynomialEvaluator polyeval(c = {1, 2, 3, 4}, x = time, y = p);
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));

  end PolyEvaluate2;

  class RangeVector
    Real v1[5] = 2.7 : 6.8; // v1 is {2.7, 3.7, 4.7, 5.7, 6.7}
    Real v2[5] = {2.7, 3.7, 4.7, 5.7, 6.7}; // v2 is equal to v1
    Integer v3[3] = 3 : 5; // v3 is {3, 4, 5}
    Integer v4empty[0] = 3 : 2; // v4empty is an empty Integer vector
    Real v5[4] = 1.0 : 2 : 8; // v5 is {1.0, 3.0, 5.0, 7.0}
    Integer v6[5] = 1 : -1 : -3; // v6 is {1, 0, -1, -2, -3}
    Real[0] v7none;  // v7 none is an empty Real vector
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end RangeVector;

  model Sampler
    parameter Real sample_interval = 0.1        "Sample period";
    Real x(start=5);
    Real y;
  equation
    der(x) = -x;
    when sample(0, sample_interval) then
    y = x;
    end when;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Sampler;

  connector InPort            "Connector with input signals of type Real"
    parameter Integer n = 1        "Dimension of signal vector";
    input Real     signal[n]      "Real input signals";
  end InPort;
  connector OutPort            "Connector with output signals of type Real"
    parameter Integer n = 1        "Dimension of signal vector";
    output Real     signal[n]      "Real output signals";
  end OutPort;              // From Modelica.Blocks.Interfaces
  type Time=Real(quantity="Time",unit="s");
  partial block MO             "Multiple Output continuous control block"
    parameter Integer nout = 1      "Number of outputs";
    OutPort       outPort(n = nout)  "Connector of Real output signals";
  protected
    Real n[nout] = outPort.signal;
  end MO;                  // From Modelica.Blocks.Interfaces

  block Step                   "Generate step signals of type Real"
    parameter Real   height[:] = {1}      "Heights of steps";
    parameter Real   offset[:] = {0}      "Offset of output signals";
    parameter Time startTime[:] = {0}     "Output = offset for time < startTime";

    extends MO(final nout =   max([size(height, 1);
          size(offset, 1);
          size(startTime, 1)]) );
  protected
    parameter Real p_height[nout] =
        (if size(height, 1) == 1 then
        ones(nout)*height[1]
        else
        height);
    parameter Real p_offset[nout] =
        (if size(offset, 1) == 1 then
        ones(nout)*offset[1]
        else
        offset);
    parameter Time p_startTime[nout] =
        (if size(startTime, 1) == 1 then
        ones(nout)*startTime[1]
        else
        startTime);

  equation
    for i in 1:nout loop                  // A regular equation structure
    outPort.signal[i] = p_offset[i] +
          (if time < p_startTime[i] then 0 else p_height[i]);
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Step;                        // From Modelica.Blocks.Sources

  model SumZ
    parameter Integer n = 5;
    parameter Real[n] z = {10, 20, 30, 40, 50};
    Real sum(start = 0);
  algorithm
    sum := 0;
    for i in 1:n loop
    sum := sum + z[i];
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end SumZ;

  class SumVector
    Real sum;
    parameter Real v[5] = {100, 200, -300, 400, 500};
    parameter Integer n = size(v, 1);
  algorithm
    sum := 0;
    for i in 1:n loop
    if v[i] > 0 then
      sum := sum + v[i];
    elseif v[i] > -1 then
      sum := sum + v[i] - 1;
    else
      sum := sum - v[i];
    end if;
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end SumVector;

  model TwoRateSampler
    discrete Real x,y;
    Boolean fastSample;
    Boolean slowSample;
    Integer cyCounter(start=0);          // Cyclic count 0,1,2,3,4, 0,1,2,3,4,...
   equation
    fastSample = sample(0,1);          // Define the fast clock
    when fastSample then
    cyCounter  = if pre(cyCounter) < 5 then pre(cyCounter)+1 else 0;
    slowSample = pre(cyCounter) == 0;       // Define the slow clock
    end when;
   equation
    when fastSample then              // fast sampling
    x = sin(time);
    end when;
   equation
    when slowSample then                // slow sampling (5-times slower)
    y = log(time);
    end when;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end TwoRateSampler;

  class OneReturnValue
    Real a = 1, b = 0, c = 1;

    Real s1[3] = sin({a, b, c});
          // Vector argument, result: {sin(a), sin(b), sin(c)}
    Real s2[2, 2] = sin([1, 2; 3, 4]);
          // Matrix argument, result: [sin(1), sin(2); sin(3), sin(4)]
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end OneReturnValue;

  class SumVec
    Real[3] v1 = {1, 2, 3};
    Real[3] v2 = {6, 4, 5};
    Real[3] v3 = {3, 7, 6};
    Real[3] v4 = {1, 3, 8};
    Real[2, 3] M1 = {v1, v2};
    Real[2, 3] M2 = {v3, v4};
    Real sv1[2] = atan2SumVec(M1, M2); // atan2SumVec({v1, v2}, {v3, v4}) <=> {atan2(sum(v1), sum(v2)), atan2(sum(v3), sum(v4))}
    Real sv2[2] = atan2SumVec({{1, 2}, {3, 4}}, {{6, 7},{8, 9}}); // {atan2(sum({1, 2}), sum({3, 4})), atan2(sum({6,7}), sum({8, 9}))}
    // <=> {atan2(3, 7), atan2(13, 17) }
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end SumVec;

  connector eventPort
    discrete Boolean signal;
  end eventPort;

  model EventGenerator
    parameter Real eventTime = 1;
    eventPort dOutput;
  equation
    dOutput.signal = time > eventTime;
  end EventGenerator;

  model WatchDog1
    eventPort dOn;
    eventPort dOff;
    eventPort dDeadline;
    eventPort dAlarm;
    discrete Boolean watchdogActive(start=false);  // Initially turned off
  algorithm
    when change(dOn.signal) then                 // Event watchdog on
    watchdogActive := true;
    end when;

    when change(dOff.signal) then                // Event watchdog off
    watchdogActive := false;
    dAlarm.signal  := false;
    end when;

    when (change(dDeadline.signal) and watchdogActive) then   // Event Alarm!
    dAlarm.signal := true;
    end when;
  end WatchDog1;

  model WatchDogSystem1
    EventGenerator  turnOn(eventTime = 1);
    EventGenerator  turnOff(eventTime = 0.25);
    EventGenerator  deadlineEmitter(eventTime = 1.5);
    WatchDog1       watchdog;
  equation
    connect(turnOn.dOutput,  watchdog.dOn);
    connect(turnOff.dOutput, watchdog.dOff);
    connect(deadlineEmitter.dOutput, watchdog.dDeadline);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WatchDogSystem1;

  model WatchDog2
     eventPort dOn;
     eventPort dOff;
     eventPort dDeadline;
     eventPort dAlarm;

     Real internalTime1, internalTime2;

  equation
     when change(dOn.signal)then
     internalTime1 = time;
     end when;

     when change(dOff.signal)then
     internalTime2 = time;
     end when;

     when change(dDeadline.signal) and time>internalTime1 and internalTime1>internalTime2 then
     dAlarm.signal=true;
     end when;
  end WatchDog2;

  model WatchDogSystem2
    EventGenerator  turnOn(eventTime=1);
    EventGenerator  turnOff(eventTime=0.25);
    EventGenerator  deadlineEmitter(eventTime=1.5);
    WatchDog2       watchdog;
  equation
    connect(turnOn.dOutput,watchdog.dOn);
    connect(turnOff.dOutput,watchdog.dOff);
    connect(deadlineEmitter.dOutput, watchdog.dDeadline);

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WatchDogSystem2;


  model WhenEquation
    Real x(start = 1);
    discrete Real y1;
    parameter Real y2 = 3;
    discrete Real y3;
  equation
    x = time - y2;
    when x > 2 then
    y1 = sin(x);
    y3 = 2*x + y1 + y2;
    end when;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenEquation;

  model WhenPriority
    Boolean close;
    parameter Real x = 5;
  algorithm
    when x >= 5 then
    close := true;
    elsewhen x <= 5 then
    close := false;
    end when;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenPriority;

  class WhenStat
    Real x(start=1);
    Real y1;
    parameter Real y2 = 5;
    Real y3;
  algorithm
    when x > 2 then
    y1 := sin(x);
    y3 := 2*x + pre(y1) + y2;
    end when;
  equation
    der(x) = 2*x;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenStat;

  class WhenStat2
    Real x(start = 1);
    Real y1;
    parameter Real y2 = 5;
    Real y3;
  algorithm
    when {x > 2, sample(0, 2), x < 5} then
    y1 := sin(x);
    y3 := 2*x + y1 + y2;
    end when;
  equation
    der(x) = 2*x;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenStat2;

  class WhenStat3
    Real x(start = 1);
    Real y1;
    Real y2;
    Real y3;

  algorithm
    when x > 2 then
    y1 := sin(x);
    end when;

  equation
    y2 = sin(y1);

  algorithm
    when x > 2 then
    y3 := 2*x + pre(y1) + y2;
    end when;

  equation
    der(x) = 2*x;

    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenStat3;

  model WhenValidResult
    Real x;
    Real y;
  equation
    x + y = 5;                  // Equation to be used to compute x
    when sample(0, 2) then
    y = 7; // - 2*x;              // Correct, y is a result variable from the when
    end when;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenValidResult;

  class WhenSet
    Real x;
    parameter Real y2 = 3;
    discrete Real y1;
    discrete Real y3;
  equation
    x = time - y2;
    when {x > 2, sample(0, 2), x < 5} then
    y1 = sin(x);
    y3 = 2*x + y1 + y2;
    end when;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end WhenSet;

  model Xpowers1
    parameter Real x = 10;
    Real a = 1;
    parameter Integer n = 5;
    Real xpowers[n];
    Real y;
  equation
    xpowers[1] = 1;
    xpowers[2] = xpowers[1]*x;
    xpowers[3] = xpowers[2]*x;
    xpowers[4] = xpowers[3]*x;
    xpowers[4 + 1] = xpowers[4]*x;
    y = a * xpowers[5];
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Xpowers1;

  model Xpowers2
    parameter Real x=10;
    Real xpowers[n];
    parameter Integer i=1;
    parameter Integer n = 5;
  equation
    xpowers[1]=1;
    for i in 1:n-1 loop
    xpowers[i + 1] = xpowers[i]*x;
    end for;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Xpowers2;

  model Xpowers3
    parameter Real x=10;
    Real xpowers[n+1];
    parameter Integer n = 5;
  equation
    xpowers[1]=1;
    xpowers[2:n+1] = xpowers[1:n]*x;
    annotation (experiment(
            StartTime = 0,
            StopTime=1,
            NumberOfIntervals=200));
  end Xpowers3;

  model SmoothAndEvents
    Real x,y,z;
    parameter Real p;
  equation
    x = if time<1 then 2 else time-2;           // time<1 generates events
    y = smooth(0, if time<0 then 0 else time);  // may avoid events
    z = smooth(1,noEvent(if x<0 then 0 else sqrt(x)*x)); // noEvent is necessary
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end SmoothAndEvents;

  model WhenPriorityX
    discrete Real x;
  equation
    when time>=2 then       // Higher priority
     x = pre(x)+1.5;
    elsewhen time>=1 then   // Lower priority
     x = pre(x)+1;
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end WhenPriorityX;

  model SynchCounters    // Two synchronized counters
    Boolean slowPulses;
    Boolean fastPulses;
    Integer count, slowCount;
  equation
    fastPulses = sample(1,1);
    when fastPulses then        // Count every second
     count      = pre(count)+1;
     slowPulses = mod(count,2)==0;     // true when count=2,4,6,...
    end when;
    when slowPulses then        // Count every 2nd second
     slowCount = pre(slowCount)+1;
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end SynchCounters;

  model MultipleEvents
    discrete Integer x(start=1);
    Boolean          signal(start=False);
  equation
    when x==2 then      // Event handler A
     x = pre(x)+1;         // x becomes 2+1 = 3
    elsewhen x==3 then  // Event handler B
     x = pre(x)+5;         // x becomes 3+5 = 8
    end when;
    when time>=2 then   // Event handler C
     x = 2;                  // x becomes 2
    elsewhen time>=2 then  // Event handler D
     signal = true;
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end MultipleEvents;

  model SimplePeriodicSampler
    parameter Real T=1  "Sample period";
    input     Real u    "Input used at sample events";
    discrete output Real y  "Output computed at sample events";
  protected
    discrete Real x;    // discrete state variable
  equation
    when sample(0,T) then
    x = f(pre(x),u);  // state update expression
    y = h(pre(x),u);  // output expression
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end SimplePeriodicSampler;

  model DiscreteScalarStateSpace
    parameter Real a, b, c, d;
    parameter Real T=1;
    input     Real u;
    discrete output Real y;
  protected
    discrete Real x;
  equation
    when sample(0,T) then
    x = a*pre(x) + b*u;
    y = c*pre(x) + d*u;
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end DiscreteScalarStateSpace;

  model SampleSignalGenerator
    parameter Real  startTime = 0;
    parameter Real  period = 1;
    output Boolean  outSignal;
  equation
    outSignal = sample(startTime, period);
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end SampleSignalGenerator;

  function firstGeneration
    input Integer M[:,:];
    input Integer I[:,:];
    output Integer G[size(M,1),size(M,1)] = M;
  algorithm
    for i in 1:size(I,1) loop
    G[I[i,1],I[i,2]] := 1;
    end for;
  end firstGeneration;

  function nextGeneration
    input  Integer M[:,:];
    output Integer G[size(M,1),size(M,1)];
  protected
    Integer borderSum,iW,iE,jN,jS;  // West,East,North,South
    parameter Integer n=size(M,1);
  algorithm
    for i in 1:n loop
    for j in 1:n loop
       iW := mod(i-2+n,n)+1; iE := mod(i+n,n)+1;
       jS := mod(j-2+n,n)+1; jN := mod(j+n,n)+1;
       borderSum := M[iW,j] + M[iE,j] + M[iW,jS] + M[i,jS] +
       M[iE,jS] + M[iW,jN] + M[i,jN] + M[iE,jN];
       if borderSum==3 then
       G[i,j] := 1;           // Alive
       elseif borderSum==2 then
       G[i,j] := M[i,j];      // Unchanged
       else
       G[i,j] := 0;           // Dead
       end if;
    end for;
    end for;
  end nextGeneration;

  model GameOfLife
    parameter Integer n=10;
    parameter Integer initialAlive[:,2]={{2,2},{2,1},{1,2},{3,3},{3,2}};
    Integer lifeHistory[n,n](start=zeros(n,n));
  initial equation
    lifeHistory = firstGeneration(pre(lifeHistory),initialAlive);
  equation
    when sample(0.1,0.1) then
    lifeHistory = nextGeneration(pre(lifeHistory));
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end GameOfLife;

  model BasicVolume1  "First version with physical types"
    import Modelica.SIunits.*;
    parameter Real               R = 287;
    Pressure    P;
    Volume      V;
    Mass        m;
    Temperature T;
  equation   // "Boundary" conditions
    V=1e-3;     // volume is 1 liter
    T=293;      // 20 deg Celsius
    m=0.00119;  // mass of 1 liter air at K=293
    // Equation of state (ideal gas)
    P*V=m*R*T;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end BasicVolume1;

  model BasicVolume2  "Conservation of Mass"
    import Modelica.SIunits.*;
    parameter SpecificHeatCapacity R = 287;
    Pressure       P;
    Volume         V;
    Mass           m(start=0.00119);     // Added: start value
    Temperature    T;
    MassFlowRate   mdot_in;              // Added: mass inflow
    MassFlowRate   mdot_out;             // Added: mass outflow
  equation
    // Boundary conditions
    V=1e-3;
    T=293;
    mdot_in=0.1e-3;                      // Added!
    mdot_out=0.01e-3;                    // Added!
    // Conservation of mass
    der(m)=mdot_in-mdot_out;             // Added!
    // Equation of state (ideal gas)
    P*V=m*R*T;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end BasicVolume2;



  model BasicVolume3
    import Modelica.SIunits.*;
    parameter SpecificInternalEnergy u_0 = 209058;  // Added!  Air at T=293K
    parameter SpecificHeatCapacity   c_v = 717;     // Added!
    parameter Temperature            T_0 = 293;     // Added!
    parameter Mass                   m_0 = 0.00119; // Added!
    parameter SpecificHeatCapacity   R   = 287;
    Pressure               P;
    Volume                 V;
    Mass                   m(start=m_0);            // Added part!
    Temperature            T;
    MassFlowRate           mdot_in, mdot_out;
    SpecificEnthalpy       h_in, h_out;             // Added!
    SpecificEnthalpy       h;                       // Added!
    Enthalpy               H;                       // Added!
    SpecificInternalEnergy u;                       // Added!
    InternalEnergy         U(start=u_0*m_0);        // Added!
  equation
    // Boundary conditions
    V        = 1e-3;
    mdot_in  = 0.1e-3;
    mdot_out = 0.01e-3;
    h_in     = 300190;                              // Added: Air at T = 300K
    h_out    = h;                                   // Added!
    // Conservation of mass
    der(m)   = mdot_in-mdot_out;
    // Conservation of energy
    der(U)   = h_in*mdot_in-h_out*mdot_out;         // Added!
    // Specific internal energy (ideal gas)
    u = U/m;                                        // Added!
    u = u_0+c_v*(T-T_0);                            // Added!
    // Specific enthalpy
    H = U+P*V;                                      // Added!
    h = H/m;                                        // Added!
    // Equation of state (ideal gas)
    P*V = m*R*T;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end BasicVolume3;


  model SimpleValveFlow
    import Modelica.SIunits;
    parameter SIunits.Area A = 1e-4;
    parameter Real         beta = 5.0e-5;
    SIunits.Pressure       P_in, P_out;
    SIunits.MassFlowRate   mdot;
  equation  // Boundary conditions
    P_in  = 1.2e5;
    P_out = 1.0e5;
    // Constitutive relation
    beta*A^2*(P_in - P_out) = mdot^2;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end SimpleValveFlow;

  class PopulationGrowth
    parameter Real g = 0.04    "Growth factor of population";
    parameter Real d = 0.0005  "Death factor of population";
    Real           P(start=10) "Population size, initially 10";
  equation
    der(P) = (g-d)*P;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end PopulationGrowth;


  class KyenesianModel
    parameter Real a = 0.5    "Consumption fraction";
    parameter Real b = 0.5    "Investment fraction of consumption increase";
    Real      GNP(start=0)         "Gross National Product";
    Real      consumption(start=0) "Consumption";
    Real      investments(start=0) "Investments";
    Real      expenses(start=0)    "Government expenses";
  equation
    when sample(0, 1) then
    GNP         = consumption + investments + expenses;
    consumption = a * pre(GNP);
    investments = b * (consumption - pre(consumption));
    end when;
    when time >= 1.0 then    // Increase expenses by 1 at year 1
    expenses = pre(expenses)+1;
    end when;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end KyenesianModel;


  function initialPressure
    import Modelica.SIunits.*;
    input Integer n;
    output Real p[n];
  protected
    parameter Length L=10;
  algorithm
    for i in 1:n loop
    p[i]:=exp(-(-L/2+(i-1)/(n-1)*L)^2);
    end for;
  end initialPressure;

  model WaveEquationSample
    import Modelica.SIunits;
    parameter SIunits.Length   L=10 "Length of duct";
    parameter Integer          n=30 "Number of sections";
    parameter SIunits.Length   dL=L/n "Section length";
    parameter SIunits.Velocity c=1;
    SIunits.Pressure[n]  p(start=initialPressure(n));
    Real[n]              dp(start=fill(0,n));
  equation
    p[1]=exp(-(-L/2)^2);
    p[n]=exp(-(L/2)^2);
    dp=der(p);
    for i in 2:n-1 loop
    der(dp[i]) = c^2*(p[i+1]-2*p[i]+p[i-1])/dL^2;
    end for;
    annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end WaveEquationSample;

  model PointGravity
     import Modelica.Mechanics.MultiBody.Parts;
     inner Modelica.Mechanics.MultiBody.World world(gravityType=2,mue=1,
                           gravitySphereDiameter=0.1);
     Parts.Body  body1(m=1,r_0_start={0,0.6,0},
     v_0_start={1,0,0},sphereDiameter=0.1,I_11=0.1,I_22=0.1,I_33=0.1);
     Parts.Body  body2(m=1,r_0_start={0.6,0.6,0},
     v_0_start={0.6,0,0},sphereDiameter=0.1,I_11=0.1,I_22=0.1,I_33=0.1);
     annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end PointGravity;

  model doublePendulumCylinders
     import Modelica.Mechanics.MultiBody.Parts;
     import Modelica.Mechanics.MultiBody.Joints;
     import Modelica.Mechanics.MultiBody.Types;
     parameter Real L1=0.3 "length of 1st arm";
     parameter Real L2=0.4 "length of 2nd arm";
     parameter Real D=0.1 "diameter";
     inner Modelica.Mechanics.MultiBody.World world;
     Joints.Revolute revolute1;
     Joints.Revolute revolute2;
     Parts.BodyCylinder body1(r={L1,0,0},diameter=D);
     Parts.BodyCylinder body2(r={L2,0,0},diameter=D,color={255,255,0});
  equation
     connect(world.frame_b, revolute1.frame_a);
     connect(revolute1.frame_b, body1.frame_a);
     connect(revolute2.frame_b, body2.frame_a);
     connect(body1.frame_b, revolute2.frame_a);
     annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end doublePendulumCylinders;

  model PendulumLoop2D
     import Modelica.Mechanics.MultiBody.Parts;
     import Modelica.Mechanics.MultiBody.Joints;
     import Modelica.Mechanics.MultiBody.Types;
     inner Modelica.Mechanics.MultiBody.World  world;
     Parts.BodyCylinder  body1(r={1,0,0},diameter=0.1,color={125,125,125});
     Parts.BodyCylinder  body2(r={0.5,0,0},diameter=0.1);
     Parts.BodyCylinder  body3(r={-0.9,0,0},diameter=0.1,color={0,255,0});
     Parts.BodyCylinder  body4(r={0.5,0,0},diameter=0.1);
     Joints.Revolute     revolute1(startValuesFixed=true,phi_start=-60);
     Joints.Revolute     revolute2;
     Joints.Revolute     revolute3;
     Joints.Revolute     revolute4(planarCutJoint=true);
  equation
     connect(world.frame_b, body1.frame_a);
     connect(body1.frame_b, revolute1.frame_a);
     connect(revolute1.frame_b, body2.frame_a);
     connect(world.frame_b, revolute3.frame_a);
     connect(revolute3.frame_b, body4.frame_a);
     connect(body2.frame_b, revolute2.frame_a);
     connect(body3.frame_a, revolute2.frame_b);
     connect(revolute4.frame_b, body3.frame_b);
     connect(body4.frame_b, revolute4.frame_a);
     annotation (experiment(
        StartTime = 0,
        StopTime=1,
        NumberOfIntervals=200));
  end PendulumLoop2D;












end DrModelicaForTesting;
