// name: FuncMap1
// keywords: function map array reduction
// status: correct
// cflags: -d=newInst
//
// checks mapping functions are typed correctly.


model C
  function F
    input Integer a;
    input Integer b;
    output Integer c = a;
  end F;

  Integer b[3];
  Integer c[3];
  Integer d[3];
equation 
  b = {1,2,3};
  c = array(F(b[i],b[i]) for i in 1:size(b,1));
  d = {F(b[i],i) for i in 1:size(b,1)};
end C;


// Result:
// function C.F
//   input Integer a;
//   input Integer b;
//   output Integer c = a;
// end C.F;
//
// class C
//   Integer b[1];
//   Integer b[2];
//   Integer b[3];
//   Integer c[1];
//   Integer c[2];
//   Integer c[3];
//   Integer d[1];
//   Integer d[2];
//   Integer d[3];
// equation
//   b[1] = 1;
//   b[2] = 2;
//   b[3] = 3;
//   c = array(C.F(b[i], b[i]) for i in 1:3);
//   d = array(C.F(b[i], i) for i in 1:3);
// end C;
// endResult
