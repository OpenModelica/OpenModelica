// name: FuncVectorizatio1
// keywords: vectorization function map array reduction
// status: correct
// cflags: -d=newInst
//
// checks mixed vectorization where some arguments are vectorized while others are applied as is.

model C
  function F
    input Integer a;
    input Integer b;
    output Integer c = a;
  end F;

  Integer b[3];
  Integer c[3];
equation 
  b = {1,2,3};
  c = F(1, b);
  c = F(b, 1);
end C;


// Result:
// function F
//   input Integer a;
//   input Integer b;
//   output Integer c = a;
// end F;
//
// class C
//   Integer b[1];
//   Integer b[2];
//   Integer b[3];
//   Integer c[1];
//   Integer c[2];
//   Integer c[3];
// equation
//   b[1] = 1;
//   b[2] = 2;
//   b[3] = 3;
//   c = array(F(1, b[$i1]) for $i1 in 1:3);
//   c = array(F(b[$i1], 1) for $i1 in 1:3);
// end C;
// endResult
