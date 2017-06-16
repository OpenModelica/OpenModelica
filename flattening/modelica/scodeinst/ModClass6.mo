// name: ModClass6
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  model B
    model C
      Real x = 1;
      Real y = 1;
      Real z = 1;
    end C;
  end B;
end A;

model ModClass6
  extends A(B(C(z = 2)));
  model D = B(C(x = 2));
  
  D.C b(y = 2);
end ModClass6;

// Result:
// class ModClass6
//   Real b.x = 2;
//   Real b.y = 2;
//   Real b.z = 2;
// end ModClass6;
// endResult
