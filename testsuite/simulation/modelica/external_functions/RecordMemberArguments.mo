model ExtRecordMemberArguments
  record R
    Real A[2,3];
    Real b;
    Integer C[3];
    Integer d;
    Boolean E[:];
    Boolean f;
    String G[2];
    String h;
  end R;

  function foo
    input R r;

    external "C" foo(r.A, size(r.A, 1), size(r.A, 2), r.b, r.C, size(r.C, 1), r.d, r.E, size(r.E, 1), r.f, r.G, size(r.G, 1), r.h)
    annotation (

    Include="
void foo(const double* A, size_t dim_A_1, size_t dim_A_2, const double b, const int* C, size_t dim_C_1, int d, const int* E, size_t dim_E_1, int f, const char** G, size_t dim_G_1, const char* h) {
  size_t i, j;
  printf(\"A (%zu x %zu):\\n\", dim_A_1, dim_A_2);
  for (i = 0; i < dim_A_1; ++i) {
    printf(\"{\");
    for (j = 0; j < dim_A_2; ++j) {
      /* Modelica arrays are row-major: A[i*dim_A_2 + j] */
      printf(\"%g\", A[i*dim_A_2 + j]);
      if (j + 1 < dim_A_2) printf(\", \");
    }
    printf(\"}\\n\");
  }

  printf(\"b: %g\\n\", b);

  printf(\"C: {\");
  for (i = 0; i < dim_C_1; ++i) {
    printf(\"%d\", C[i]);
    if (i + 1 < dim_C_1) printf(\", \");
  }
  printf(\"}\\n\");

  printf(\"d: %d\\n\", d);

  printf(\"E: {\");
  for (i = 0; i < dim_E_1; ++i) {
    printf(\"%s\", E[i] ? \"true\" : \"false\");
    if (i + 1 < dim_E_1) printf(\", \");
  }
  printf(\"}\\n\");

  printf(\"f: %s\\n\", f ? \"true\" : \"false\");

  printf(\"G: {\");
  for (i = 0; i < dim_G_1; ++i) {
    printf(\"'%s'\", G[i] ? G[i] : \"(null)\");
    if (i + 1 < dim_G_1) printf(\", \");
  }
  printf(\"}\\n\");

  printf(\"h: '%s'\\n\", h ? h : \"(null)\");
  }
");
  end foo;

  R r(A = [1.0, 2.0, 3.0;
           4.0, 5.0, 6.0],
      b = 7.0,
      C = {-1, -2, -3},
      d = -4,
      E = {true, false},
      f = true,
      G = {"one", "two"},
      h = "scalar");
equation
  when sample(0.5, 1) then
    foo(r);
  end when;
end ExtRecordMemberArguments;
