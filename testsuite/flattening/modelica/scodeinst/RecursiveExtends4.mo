// name: RecursiveExtends4
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that the compiler catches recursive extends.
//

model RecursiveExtends4
  extends RecursiveExtends4.A.Icon1;

  model A
    extends RecursiveExtends4.A.Icon1;

    partial class Icon1 end Icon1;
  end A;
end RecursiveExtends4;

// Result:
// class RecursiveExtends4
// end RecursiveExtends4;
// endResult
