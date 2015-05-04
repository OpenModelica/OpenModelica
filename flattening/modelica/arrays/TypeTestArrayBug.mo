class TypeTestArrayBug

  type Wrong = Real[2](unit = "m");
  Wrong w;

  type Good = Wrong[2](each quantity = "Good");
  Good g;

  type Bubu = Real(unit = "m");
  type B = Bubu[2];
  B[3] z(each quantity = "Length");

  type A = B[10](each quantity = "SomeQ");
  A[4] a[5](each nominal = 5);

end TypeTestArrayBug;

