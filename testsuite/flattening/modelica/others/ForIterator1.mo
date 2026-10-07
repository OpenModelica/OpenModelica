// name:     ForIterator1
// keywords: for iterator
// status:   correct
//
// For iterator handling
//

model ForIterator1

  function func
    input Integer x1;
    output Integer y1;
    output Integer y2;
    output Real y3;
    output Real y4;
  protected
    Integer arrFunc1[5];
    Real arrFunc2[5];
    Integer arrFunc3[3,4];
    Real arrFunc4[3,4];
  algorithm
    arrFunc1 := {5+i for i in 1:5};
    arrFunc2 := array(5.3*j for j in 1:5);
    arrFunc3 := {3*j+i for j in 1:4,i in {1,2,3}};
    arrFunc4 := array(3.5*j*i for j in 1:4,i in 1:3);
    y1 := sum(3*i for i in 1:5);
    y2 := arrFunc1[1]+arrFunc3[3,2];
    y3 := arrFunc2[2];
    y4 := arrFunc4[2,2];
  end func;

  Integer i1,i2;
  Real r1,r2;
  Real arr1[5];
  Integer arr2[5];
  Real arr3[3,5];
  Integer arr4[3,5];
equation
  arr1 = {5.3+i for i in 1:5};
  arr2 = array(5*j for j in 1:5);
  arr3 = {3*j*i for j in 1:5,i in 1:3};
  arr4 = array(3*j*i for j in 1:5,i in 1:3);
  (i1,i2,r1,r2) = func(3);
end ForIterator1;

// Result:
// class ForIterator1
//   Integer i1;
//   Integer i2;
//   Real r1;
//   Real r2;
//   Real arr1[1];
//   Real arr1[2];
//   Real arr1[3];
//   Real arr1[4];
//   Real arr1[5];
//   Integer arr2[1];
//   Integer arr2[2];
//   Integer arr2[3];
//   Integer arr2[4];
//   Integer arr2[5];
//   Real arr3[1,1];
//   Real arr3[1,2];
//   Real arr3[1,3];
//   Real arr3[1,4];
//   Real arr3[1,5];
//   Real arr3[2,1];
//   Real arr3[2,2];
//   Real arr3[2,3];
//   Real arr3[2,4];
//   Real arr3[2,5];
//   Real arr3[3,1];
//   Real arr3[3,2];
//   Real arr3[3,3];
//   Real arr3[3,4];
//   Real arr3[3,5];
//   Integer arr4[1,1];
//   Integer arr4[1,2];
//   Integer arr4[1,3];
//   Integer arr4[1,4];
//   Integer arr4[1,5];
//   Integer arr4[2,1];
//   Integer arr4[2,2];
//   Integer arr4[2,3];
//   Integer arr4[2,4];
//   Integer arr4[2,5];
//   Integer arr4[3,1];
//   Integer arr4[3,2];
//   Integer arr4[3,3];
//   Integer arr4[3,4];
//   Integer arr4[3,5];
// equation
//   arr1 = array(5.3 + /*Real*/(i) for i in 1:5);
//   arr2 = array(5 * j for j in 1:5);
//   arr3 = /*Real[3, 5]*/(array(array(3 * j * i for j in 1:5) for i in 1:3));
//   arr4 = array(array(3 * j * i for j in 1:5) for i in 1:3);
//   i1 = 45;
//   i2 = 15;
//   r1 = 10.6;
//   r2 = 14.0;
// end ForIterator1;
// endResult
