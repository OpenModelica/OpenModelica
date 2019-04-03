encapsulated package IntVector
  import BasePVector;
  extends BasePVector(redeclare type T = Integer);
  annotation(__OpenModelica_Interface="util");
end IntVector;

function test1
  "Tests add and get."
protected
  IntVector.Vector vec = IntVector.new();
algorithm
  for i in 1:2000 loop
    vec := IntVector.add(vec, i);
  end for;
  
  for i in 1:2000 loop
    assert(IntVector.get(vec, i) == i, "test1: Got wrong value back!");
  end for;
end test1;

function test2
  "Tests addList."
protected
  IntVector.Vector vec = IntVector.new();
algorithm
  vec := IntVector.addList(vec, list(i for i in 1:15));
  vec := IntVector.addList(vec, list(i for i in 16:40));
  assert(IntVector.size(vec) == 40, "test2: vec has wrong size!");

  for i in 1:40 loop
    assert(IntVector.get(vec, i) == i, "test2: Got wrong value back!");
  end for;
end test2;

function test3
  "Tests set."
protected
  IntVector.Vector vec = IntVector.new();
algorithm
  for i in 1:2000 loop
    vec := IntVector.add(vec, i);
  end for;

  for i in 1:2000 loop
    vec := IntVector.set(vec, i, i*2);
  end for;

  for i in 1:2000 loop
    assert(IntVector.get(vec, i) == i*2, "test3: Got wrong value back!");
  end for;
end test3;

function test4
  "Tests persistence."
protected
  IntVector.Vector vec = IntVector.new();
  IntVector.Vector vec2;
algorithm
  vec := IntVector.add(vec, 1);
  vec2 := IntVector.add(vec, 2);
  vec := IntVector.add(vec, 3);
  assert(IntVector.size(vec) == IntVector.size(vec2),
    "test4: vec and vec2 should have the same size!");
  assert(IntVector.get(vec, 2) == 3, "test4: Wrong value in vec!");
  assert(IntVector.get(vec2, 2) == 2, "test4: Wrong value in vec2!");
end test4;

function test5
  "Tests last and pop."
protected
  IntVector.Vector vec = IntVector.new();
algorithm
  vec := IntVector.addList(vec, list(i for i in 1:2000));
  
  for i in 0:1999 loop
    assert(IntVector.last(vec) == 2000-i, "test5: Got wrong value back!");
    vec := IntVector.pop(vec);
  end for;

  assert(IntVector.isEmpty(vec), "test5: vec is not empty!");
end test5;

function test6
  "Tests map and fold."
protected
  function add1
    input Integer x;
    output Integer y = x + 1;
  end add1;

  IntVector.Vector vec = IntVector.new();
  Integer s;
algorithm
  vec := IntVector.addList(vec, list(i for i in 0:99));
  vec := IntVector.map(vec, add1);
  s := IntVector.fold(vec, intAdd, 0);
  assert(s == 5050, "test6: sum is wrong!");
end test6;

function test7
  "Tests fromList and toList."
protected
  IntVector.Vector vec = IntVector.new();
  list<Integer> lst;
algorithm
  vec := IntVector.fromList(list(i for i in 1:2000));
  lst := IntVector.toList(vec);
  
  for i in 1:2000 loop
    assert(listHead(lst) == i, "Got wrong value back!");
    lst := listRest(lst);
  end for;
end test7;

function test8
protected
  IntVector.Vector vec = IntVector.new();
  array<Integer> arr;
  Integer n;
algorithm
  vec := IntVector.fromArray(listArray(list(i for i in 1:2000)));
  arr := IntVector.toArray(vec);

  for i in 1:2000 loop
    assert(arr[i] == i, "Got wrong value back!");
  end for;
end test8;

// Code generation isn't quite working for BasePVector when calling the test
// functions from a script, so this model is used as a workaround.
model PVectorTest
algorithm
  when terminal() then
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    test8();
  end when;
end PVectorTest;
