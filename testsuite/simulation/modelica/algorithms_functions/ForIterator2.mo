// name:     ForIterator2
// keywords: for iterator
// status:   correct
//
// For iterator handling
//

package ForIterator2

  function func
    output Real y1;
    output Real y2;
    output Real y3;
    output Real y4;
    output Integer y5;
    output Integer y6;
    output Integer y7;
    output Integer y8;
  protected
    Integer arrFunc1[4,4];
    Integer arr[4,4];
    Real arrFunc2[2,3];
  algorithm
    arr := {i+j for i in 1:4,j in {1,3,5,7}};
    arrFunc1 := {arr[i,j] for i in 1:4,j in 1:4};
    arrFunc2 := {3*j+2*i for i in 1.0 : 1.0 : 3.0,j in 1:2};
    y1 := sum(3*i for i in {1.0,3.5,6.5,7.0});
    y2 := max(5+j for j in 1.0 : 1.5 : 5.5);
    y3 := arrFunc2[2,1];
    y4 := arrFunc2[1,2];
    y5 := arrFunc1[1,1];
    y6 := arrFunc1[3,1];
    y7 := arrFunc1[4,2];
    y8 := arrFunc1[3,3];
  end func;

end ForIterator2;

model M
algorithm
  ForIterator2.func();
end M;

// class ForIterator2
// Integer i1;
// Integer i2;
// Integer i3;
// Integer i4;
// Real r1;
// Real r2;
// Real r3;
// Real r4;
// equation
//   (r1,r2,r3,r4,i1,i2,i3,i4) = (54.0,10.5,7.0,8.0,2,4,7,8);
// end ForIterator2;

