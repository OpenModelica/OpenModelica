// name: InnerOuterReplaceable3
// keywords:
// status: correct
// cflags: -d=newInst
//

block A
  outer parameter C c;
end A;

model B
  inner replaceable A a;
end B;

model C
  replaceable model BC = B;
  outer BC bc;
end C;

model D
  extends B;
end D;

model E
  inner parameter C c;
  inner replaceable D bc;
end E;

model InnerOuterReplaceable3
  extends E(redeclare B bc);
end InnerOuterReplaceable3;


// Result:
// class InnerOuterReplaceable3
// end InnerOuterReplaceable3;
// endResult
