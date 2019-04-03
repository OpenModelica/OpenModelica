model ArrayInitSorting

function foo
  input Integer a "size of first internal array";
  input Integer b "size of second internal array";
  input Integer c "size of output array, which is a+b and is known from the outside";
  output Real[c] returnValue;
protected
  Real[c] array1 = cat(1,array0,array2);
  parameter Real array0[a] = {i for i in 1:a};
  parameter Real array2[b] = {i*i for i in 1:b};

  Real[c] array4 = cat(1,array3,array5);
  Real array3[a] = {i for i in 1:a};
  Real array5[b] = {i*i for i in 1:b};

algorithm
  returnValue := array1 .+ array4;
end foo;

    parameter Integer a = 3 "size of first array in function foo";
    parameter Integer b = 2 "size of second array in function foo";
    parameter Integer c = a+b "total size of output array, return from function foo";
    parameter Real result[c] = foo(a,b,c);
end ArrayInitSorting;
