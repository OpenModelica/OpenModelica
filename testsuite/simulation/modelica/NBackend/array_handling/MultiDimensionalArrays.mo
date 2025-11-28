package MultiDimensionalArrays
  model Test1
    Real[2,3] A;
  equation
    for i in 1:2 loop
      for j in 1:3 loop
        A[i,j] = i * sin(j*time);
      end for;
    end for;
  end Test1;

  model B
    Real[3] A;
    parameter Integer i;
  equation
    for j in 1:3 loop
      A[j] = i * sin(j*time);
    end for;
  end B;

  model Test2
    B[2] b(i = {1,2});
  end Test2;

  model C
    Real A;
    parameter Integer i;
    parameter Integer j;
  equation
    A = i * sin(j*time);
  end C;

  model D
    C[3] c(each i=i,j={1,2,3});
    parameter Integer i;
  end D;

  model Test3
    D[2] d(i = {1,2});
  end Test3;

  model Test4
    Test3[4] t;
  end Test4;
end MultiDimensionalArrays;