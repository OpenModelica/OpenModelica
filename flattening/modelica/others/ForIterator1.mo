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
// function ForIterator1.func
//   input Integer x1;
//   output Integer y1;
//   output Integer y2;
//   output Real y3;
//   output Real y4;
//   protected Integer[5] arrFunc1;
//   protected Real[5] arrFunc2;
//   protected Integer[3, 4] arrFunc3;
//   protected Real[3, 4] arrFunc4;
// algorithm
//   arrFunc1 := {6, 7, 8, 9, 10};
//   arrFunc2 := {5.3, 10.6, 15.899999999999999, 21.2, 26.5};
//   arrFunc3 := {{4, 7, 10, 13}, {5, 8, 11, 14}, {6, 9, 12, 15}};
//   arrFunc4 := {{3.5, 7.0, 10.5, 14.0}, {7.0, 14.0, 21.0, 28.0}, {10.5, 21.0, 31.5, 42.0}};
//   y1 := 45;
//   y2 := arrFunc1[1] + arrFunc3[3,2];
//   y3 := arrFunc2[2];
//   y4 := arrFunc4[2,2];
// end ForIterator1.func;
//
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
//   arr1[1] = 6.3;
//   arr1[2] = 7.3;
//   arr1[3] = 8.3;
//   arr1[4] = 9.3;
//   arr1[5] = 10.3;
//   arr2[1] = 5;
//   arr2[2] = 10;
//   arr2[3] = 15;
//   arr2[4] = 20;
//   arr2[5] = 25;
//   arr3[1,1] = 3.0;
//   arr3[1,2] = 6.0;
//   arr3[1,3] = 9.0;
//   arr3[1,4] = 12.0;
//   arr3[1,5] = 15.0;
//   arr3[2,1] = 6.0;
//   arr3[2,2] = 12.0;
//   arr3[2,3] = 18.0;
//   arr3[2,4] = 24.0;
//   arr3[2,5] = 30.0;
//   arr3[3,1] = 9.0;
//   arr3[3,2] = 18.0;
//   arr3[3,3] = 27.0;
//   arr3[3,4] = 36.0;
//   arr3[3,5] = 45.0;
//   arr4[1,1] = 3;
//   arr4[1,2] = 6;
//   arr4[1,3] = 9;
//   arr4[1,4] = 12;
//   arr4[1,5] = 15;
//   arr4[2,1] = 6;
//   arr4[2,2] = 12;
//   arr4[2,3] = 18;
//   arr4[2,4] = 24;
//   arr4[2,5] = 30;
//   arr4[3,1] = 9;
//   arr4[3,2] = 18;
//   arr4[3,3] = 27;
//   arr4[3,4] = 36;
//   arr4[3,5] = 45;
//   (i1, i2, r1, r2) = (45, 15, 10.6, 14.0);
// end ForIterator1;
// endResult
