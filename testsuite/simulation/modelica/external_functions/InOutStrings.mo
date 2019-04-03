function ext1
  input Integer i[:];
  output Integer j;
  external "C" j = fkn1(i, size(i, 1)) annotation(Library="libInOutStrings1.o");
end ext1;

class c1
  Integer x(start = 1);
  parameter Integer b=4;
  equation
    x = ext1({1, 2, 3, b});
end c1;

function ext2
  input String i[:];
  output Integer j;
  external "C" j = fkn2(i, size(i, 1)) annotation(Library="libInOutStrings2.o");
end ext2;

class c2
  Integer x(start = 1);
  equation
    x = ext2({"1", "2", "3", "4"});
end c2;
