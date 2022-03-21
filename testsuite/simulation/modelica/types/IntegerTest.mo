
model IntegerTest "test #7354"
  Integer z;
  Integer y;
algorithm
  z := 2147483647; // 2^31 - 1
  print("z: 2147483647: " + String(z) + "\n");
  z := z * 2;
  print("z * 2: " + String(z) + "\n");
  z := 2147483647; // 2^31 - 1
  print("z: 2147483647: " + String(z) + "\n");
  z := z + 10;
  print("z + 10: " + String(z) + "\n");
  y := div(z, 2);
  print("div(z, 2): " + String(y) + "\n");
end IntegerTest;
