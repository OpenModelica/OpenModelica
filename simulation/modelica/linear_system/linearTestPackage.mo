within ;
  //
  //  Package that defines a set of test problems
  //  for linear equation system solvers.
  //


package linear_system

  function random "Pseudo random number generator"
    input Integer seedIn[3] "Seed from last call";
    output Real x "Random number between 0 and 1";
    output Integer seedOut[3] "Modified seed for next call";
  algorithm
    seedOut[1] := rem((171*seedIn[1]), 30269);
    seedOut[2] := rem((172*seedIn[2]), 30307);
    seedOut[3] := rem((170*seedIn[3]), 30323);
    // Zero is a poor seed, therefore substitute 1;
    for i in 1:3 loop
      if seedOut[i] == 0 then
        seedOut[i] := 1;
      end if;
    end for;
    x := rem((seedOut[1]/30269.0 + seedOut[2]/30307.0 + seedOut[3]/30323.0), 1.0);
  end random;

  function getMatrix1
    input Integer N;
    input Integer seedIn[3];
    output Real A[N,N];
  protected
    Integer seed[3];
    Real x;
  algorithm
    seed := seedIn;
    for i in 1:N loop
      for j in 1:N loop
        (x,seed) := random(seed);
        A[i,j] := x;
      end for;
    end for;
  end getMatrix1;

  function getRHS
    input Integer N;
    input Integer seedIn[3];
    output Real b[N,1];
  protected
     Integer seed[3];
     Real x;
  algorithm
    seed := seedIn;
    for i in 1:N loop
      (x, seed) := random(seed);
      b[i,1] := x;
    end for;
  end getRHS;

  function getRHSt
    input Integer N;
    input Integer seedIn[3];
    input Real t;
    output Real b[N,1];
  protected
     Integer seed[3];
     Real x;
  algorithm
    seed := seedIn;
    for i in 1:N loop
      (x, seed) := random(seed);
      b[i,1] := x*(t+1)^3 + 2*sin(x)*(t+2)^5 + sqrt(t+1)*exp(-x);
    end for;
  end getRHSt;


  model problem1 "simple const random dense linear system"
    parameter Integer N = 40;
    parameter Integer seed[3] = {12,1627,7218};
    Real x[N,1];
    Real x_res[N,1];
    Real A[N,N] = getMatrix1(N, seed);
    Real b[N,1] = getRHS(N, seed);
  equation
    x_res = A*x - b;
    A*x = b;
  end problem1;

  model problem4 "A*x = b , where A is simple const random dense matrix"
    constant Integer N = 20;
    constant Integer seed[3] = {12,1627,7218};
    Real x[N,1];
    Real x_res[N,1];
    constant Real A[N,N] = getMatrix1(N, seed);
    Real b[N,1] = getRHSt(N, seed, time);
    Real max_res(start = 1.0, fixed=true);
  equation
    x_res = A*x - b;
    A*x = b;
    der(max_res) = abs(max(x_res))+abs(min(x_res));
  end problem4;

  model ConstantSingularConsistent
    Real a, b, c;
  equation
    a + b = 3;
    b + c = 2;
    a - c = 1;
  end ConstantSingularConsistent;

  model ConstantSingularInconsistent
    Real a, b, c;
  equation
    a + b = 3;
    b + c = 2;
    a - c = 4;
  end ConstantSingularInconsistent;

  model problem2
    Real u0;
    Real i1(start=1),i2(start=1),i3(start=1);
    Real u1(start=1),u2(start=1),u3(start=1);
    parameter Real r1=10;
    parameter Real r2=10;
    parameter Real r3=10;
  equation
    u0 = sin(time)*10;
    u1-r1*i1=0;
    u2-r2*i2=0;
    u3-r3*i3=0;
    u1+u3=u0;
    u2-u3=0;
    i1-i2-i3=0;
  end problem2;

  model problem3
    Real x[2], b[2] = {59.17, 46.78};
    Real A[2,2] = [[0.003,59.14+time];[5.291, -6.130]];
  equation
    A * x = b;
  end problem3;

end linear_system;
