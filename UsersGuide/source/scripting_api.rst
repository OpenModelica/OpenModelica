:tocdepth: 2

.. _scripting-api :

Scripting API
~~~~~~~~~~~~~

The following are short summaries of OpenModelica scripting commands.
These commands are useful for loading and saving classes, reading and
storing data, plotting of results, and various other tasks.

The arguments passed to a scripting function should follow syntactic and
typing rules for Modelica and for the scripting function in question. In
the following tables we briefly indicate the types or character of the
formal parameters to the functions by the following notation:

-  String typed argument, e.g. "hello", "myfile.mo".

-  TypeName – class, package or function name, e.g. MyClass,
       Modelica.Math.

-  VariableName – variable name, e.g. ``v1``, ``v2``, ``vars1[2].x``, etc.

-  Integer or Real typed argument, e.g. 35, 3.14, xintvariable.

-  options – optional parameters with named formal parameter passing.

OpenModelica Scripting Commands
###############################

The following are brief descriptions of the scripting commands available
in the OpenModelica environment. All commands are shown in alphabetical order:

.. include :: interface.inc

Simulation Parameter Sweep
##########################

Following example shows how to update the parameters and re-run the simulation without compiling the model.

.. code-block :: modelica

  loadFile("BouncingBall.mo");
  getErrorString();
  // build the model once
  buildModel(BouncingBall);
  getErrorString();
  for i in 1:3 loop
    // We update the parameter e start value from 0.7 to "0.7 + i".
    value := 0.7 + i;
    // call the generated simulation code to produce a result file BouncingBall%i%_res.mat
    system("./BouncingBall -override=e="+String(value)+" -r=BouncingBall" + String(i) + "_res.mat");
    getErrorString();
  end for;

We used the `BouncingBall.mo <https://github.com/OpenModelica/OMCompiler/blob/master/Examples/BouncingBall.mo>`__ in the example above.
The above example produces three result files each containing different start value for *e* i.e., 1.7, 2.7, 3.7.

Examples
########

The following is an interactive session with the OpenModelica
environment including some of the abovementioned commands and examples.
First we start the system, and use the command line interface from
OMShell, OMNotebook, or command window of some of the other tools.

We type in a very small model:

.. omc-loadstring ::

  model Test "Testing OpenModelica Scripts"
    Real x, y;
  equation
    x = 5.0+time; y = 6.0;
  end Test;

We give the command to flatten a model:

.. omc-mos ::
  :parsed:

  instantiateModel(Test)

A range expression is typed in:

.. omc-mos ::

  a:=1:10

It is multiplied by 2:

.. omc-mos ::

  a*2

The variables are cleared:

.. omc-mos ::

  clearVariables()

We print the loaded class test from its internal representation:

.. omc-mos ::
  :parsed:

  list(Test)

We get the name and other properties of a class:

.. omc-mos ::

  getClassNames()
  getClassComment(Test)
  isPartial(Test)
  isPackage(Test)
  isModel(Test)
  checkModel(Test)

The common combination of a simulation followed by getting a value and
doing a plot:

.. omc-mos ::

  simulate(Test, stopTime=3.0)
  val(x , 2.0)

.. omc-gnuplot :: testmodel

  y

.. omc-gnuplot :: testmodel-plotall
  :plotall:

Interactive Function Calls, Reading, and Writing
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We enter an assignment of a vector expression, created by the range
construction expression 1:12, to be stored in the variable x. The type
and the value of the expression is returned.

.. omc-mos ::

  x := 1:12

The function bubblesort is called to sort this vector in descending
order. The sorted result is returned together with its type. Note that
the result vector is of type Real[:], instantiated as Real[12], since
this is the declared type of the function result. The input Integer
vector was automatically converted to a Real vector according to the
Modelica type coercion rules.

.. omc-mos ::

  loadFile(getInstallationDirectoryPath() + "/share/doc/omc/testmodels/bubblesort.mo")
  bubblesort(x)

Now we want to try another small application, a simplex algorithm for
optimization. First read in a small matrix containing coefficients that
define a simplex problem to be solved:

.. omc-mos ::
  :combine-lines: 8

  a := {
    {-1,-1,-1, 0, 0, 0, 0, 0, 0},
    {-1, 1, 0, 1, 0, 0, 0, 0, 5},
    { 1, 4, 0, 0, 1, 0, 0, 0, 45},
    { 2, 1, 0, 0, 0, 1, 0, 0, 27},
    { 3,-4, 0, 0, 0, 0, 1, 0, 24},
    { 0, 0, 1, 0, 0, 0, 0, 1, 4}
  }

.. omc-loadstring ::

  function pivot1
    input Real b[:,:];
    input Integer p;
    input Integer q;
    output Real a[size(b,1),size(b,2)];
  protected
    Integer M;
    Integer N;
  algorithm
    a := b;
    N := size(a,1)-1;
    M := size(a,2)-1;
    for j in 1:N loop
      for k in 1:M loop
        if j<>p and k<>q then
         a[j,k] := a[j,k]-0.3*j;
        end if;
      end for;
    end for;
    a[p,q] := 0.05;
  end pivot1;

  function misc_simplex1
    input Real matr[:,:];
    output Real x[size(matr,2)-1];
    output Real z;
    output  Integer q;
    output  Integer p;
  protected
    Real a[size(matr,1),size(matr,2)];
    Integer M;
    Integer N;
  algorithm
    N := size(a,1)-1;
    M := size(a,2)-1;
    a := matr;
    p:=0;q:=0;
    a := pivot1(a,p+1,q+1);
    while not (q==(M) or p==(N)) loop
      q := 0;
      while not (q == (M) or a[0+1,q+1]>1) loop
        q:=q+1;
      end while;
      p := 0;
      while not (p == (N) or a[p+1,q+1]>0.1) loop
        p:=p+1;
      end while;
      if (q < M) and (p < N) and(p>0) and (q>0) then
        a := pivot1(a,p,q);
      end if;
    if(p<=0) and (q<=0) then
       a := pivot1(a,p+1,q+1);
    end if;
    if(p<=0) and (q>0) then
       a := pivot1(a,p+1,q);
    end if;
    if(p>0) and (q<=0) then
       a := pivot1(a,p,q+1);
    end if;
    end while;
    z := a[1,M];
    x := {a[1,i] for i in 1:size(x,1)};
    for i in 1:10 loop
     for j in 1:M loop
      x[j] := x[j]+x[j]*0.01;
     end for;
    end for;
  end misc_simplex1;

Then call the simplex algorithm implemented as the Modelica function
simplex1. This function returns four results, which are represented as a
tuple of four return values:

.. omc-mos ::

  misc_simplex1(a)
