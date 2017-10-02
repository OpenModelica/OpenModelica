// name: ComponentAttr1
// keywords: extends visibility
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model ComponentAttr1
  protected A a;  
end ComponentAttr1;
