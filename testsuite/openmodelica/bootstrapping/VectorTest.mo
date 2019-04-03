encapsulated package StringVector
  import BaseVector;
  extends BaseVector(redeclare type T = String, defaultValue = "");
  annotation(__OpenModelica_Interface="util");
end StringVector;

function print_vector
  input StringVector.Vector inVector;
protected
  Integer sz = StringVector.size(inVector);
  Integer capacity = StringVector.capacity(inVector);
algorithm
  print("[");
  for i in 1:sz loop
    print(StringVector.get(inVector, i));
    if i <> capacity then print(", "); end if;
  end for;

  for i in (sz+1):capacity loop
    print("_");
    if i <> capacity then print(", "); end if;
  end for;
  print("]\n");
end print_vector;

partial function test
protected
  StringVector.Vector vec;
end test;

// Tests basic operations
function test1 extends test;
algorithm
  vec := StringVector.new(4);
  print("isEmpty = " + boolString(StringVector.isEmpty(vec)) + "\n");
  StringVector.add(vec, "test1"); print_vector(vec);
  print("isEmpty = " + boolString(StringVector.isEmpty(vec)) + "\n");
  StringVector.add(vec, "test2"); print_vector(vec);
  StringVector.add(vec, "test3"); print_vector(vec);
  StringVector.add(vec, "test4"); print_vector(vec);
  StringVector.add(vec, "test5"); print_vector(vec);
  StringVector.add(vec, "test6"); print_vector(vec);
  StringVector.add(vec, "test7"); print_vector(vec);
  StringVector.add(vec, "test8"); print_vector(vec);
  StringVector.add(vec, "test9"); print_vector(vec);
  StringVector.add(vec, "test10"); print_vector(vec);
  StringVector.set(vec, 5, "test5b"); print_vector(vec);
  StringVector.set(vec, 1, "test1b"); print_vector(vec);
  StringVector.set(vec, 10, "test10b"); print_vector(vec);
end test1;

// Tests resizing operations.
function test2 extends test;
algorithm
  vec := StringVector.new(); print_vector(vec);
  StringVector.reserve(vec, 5); print_vector(vec);
  StringVector.resize(vec, 6, "test"); print_vector(vec);
  StringVector.resize(vec, 3, "test2"); print_vector(vec);
  StringVector.trim(vec); print_vector(vec);
  StringVector.resize(vec, 10, "test2"); print_vector(vec);
  StringVector.pop(vec); print_vector(vec);
  StringVector.trim(vec); print_vector(vec);
  StringVector.pop(vec); print_vector(vec);
end test2;

// Tests fill operations.
function test3 extends test;
algorithm
  vec := StringVector.newFill(8, "123"); print_vector(vec);
  StringVector.fill(vec, "abc"); print_vector(vec);
  StringVector.fill(vec, "xyz", 3); print_vector(vec);
  StringVector.fill(vec, "123", 5, 7); print_vector(vec);
end test3;

// Checks that attempting to write to an element out of bounds fails.
function test4 extends test;
algorithm
  vec := StringVector.new(4);
  StringVector.set(vec, 1, "test");
end test4;
