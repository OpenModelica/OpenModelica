package DivTest
  constant Integer nx = 10;
  constant Integer ny = 10;
  
  function foo
    input Real a;
    output Real dst[nx,ny];
  protected
    parglobal Real parDst[nx,ny];
    parglobal Integer x;
    parglobal Integer y;
  algorithm
    parfor i in 1:nx*ny loop
      y := div((i-1), nx) + 1;
      x := i - (y-1) * nx;
      parDst[x,y] := x*y;
    end parfor;
    dst := parDst;
  end foo;

  function bar
    input Real a;
    output Real dst[nx,ny];
  protected
    Integer i2x[nx*ny];
    Integer i2y[nx*ny];
    parglobal Integer pi2x[nx*ny];
    parglobal Integer pi2y[nx*ny];
    parglobal Real parDst[nx,ny];
    parglobal Integer x;
    parglobal Integer y;
  algorithm
    for i in 1:nx, j in 1:ny loop
      i2x[i+(j-1)*nx] := i;
      i2y[i+(j-1)*nx] := j;
    end for;
    pi2x := i2x;
    pi2y := i2y;
    parfor i in 1:nx*ny loop
      y := pi2y[i];
      x := pi2x[i];
      parDst[x,y] := x*y;
    end parfor;
    dst := parDst;
  end bar;
end DivTest;