// name: MultiInheritanceRedeclare1
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Integer i = 3;
  constant Integer j = 5;
end P;

model A
  replaceable package P end P;
  Integer x = P.i;
end A;

model B
  replaceable package P end P;
  Integer y = P.j;
end B;

model C
  extends A;
  extends B;
end C;

model MultiInheritanceRedeclare1
  C c(redeclare package P = P);
end MultiInheritanceRedeclare1;

// Result:
// class MultiInheritanceRedeclare1
//   Integer c.x = P.i;
//   Integer c.y = P.j;
// end MultiInheritanceRedeclare1;
// endResult
