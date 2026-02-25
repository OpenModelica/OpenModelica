model ExtRecordMemberArguments
  record R
    Real myRealMatrix[2,3];
    Real myRealVar;
    Integer myIntegerArray[3];
    Integer myIntegerVar;
    // TODO: Boolean arrays are still broken
    // Boolean myBooleanArray[:];
    Boolean myBooleanVar;
    String myStringArray[2];
    String myStringVar;
  end R;

  function foo
    input R r;

    external "C" foo(r.myRealMatrix, size(r.myRealMatrix, 1), size(r.myRealMatrix, 2), r.myRealVar, r.myIntegerArray, size(r.myIntegerArray, 1), r.myIntegerVar, r.myBooleanVar, r.myStringArray, size(r.myStringArray, 1), r.myStringVar)
    annotation (

    Include="
void foo(const double* myRealMatrix, size_t dim_myRealMatrix_1, size_t dim_myRealMatrix_2, const double myRealVar, const int* myIntegerArray, size_t dim_myIntegerArray_1, int myIntegerVar, int myBooleanVar, const char** myStringArray, size_t dim_myStringArray_1, const char* myStringVar) {
  size_t i, j;
  printf(\"myRealMatrix (%zu x %zu):\\n\", dim_myRealMatrix_1, dim_myRealMatrix_2);
  for (i = 0; i < dim_myRealMatrix_1; ++i) {
    printf(\"{\");
    for (j = 0; j < dim_myRealMatrix_2; ++j) {
      /* Modelica arrays are row-major: myRealMatrix[i*dim_myRealMatrix_2 + j] */
      printf(\"%g\", myRealMatrix[i*dim_myRealMatrix_2 + j]);
      if (j + 1 < dim_myRealMatrix_2) printf(\", \");
    }
    printf(\"}\\n\");
  }

  printf(\"myRealVar: %g\\n\", myRealVar);

  printf(\"myIntegerArray: {\");
  for (i = 0; i < dim_myIntegerArray_1; ++i) {
    printf(\"%d\", myIntegerArray[i]);
    if (i + 1 < dim_myIntegerArray_1) printf(\", \");
  }
  printf(\"}\\n\");

  printf(\"myIntegerVar: %d\\n\", myIntegerVar);

  /* TODO: Boolean arrays are still broken */
  // printf(\"myBooleanArray: {\");
  // for (i = 0; i < dim_myBooleanArray_1; ++i) {
  //   printf(\"%s\", myBooleanArray[i] ? \"true\" : \"false\");
  //   if (i + 1 < dim_myBooleanArray_1) printf(\", \");
  // }
  // printf(\"}\\n\");

  printf(\"myBooleanVar: %s\\n\", myBooleanVar ? \"true\" : \"false\");

  printf(\"myStringArray: {\");
  for (i = 0; i < dim_myStringArray_1; ++i) {
    printf(\"'%s'\", myStringArray[i] ? myStringArray[i] : \"(null)\");
    if (i + 1 < dim_myStringArray_1) printf(\", \");
  }
  printf(\"}\\n\");

  printf(\"myStringVar: '%s'\\n\", myStringVar ? myStringVar : \"(null)\");
  }
");
  end foo;

  R r(myRealMatrix = [1.0, 2.0, 3.0;
                      4.0, 5.0, 6.0],
      myRealVar = 7.0,
      myIntegerArray = {-1, -2, -3},
      myIntegerVar = -4,
      // myBooleanArray = {true, false, false, true, true, true},
      myBooleanVar = true,
      myStringArray = {"one", "two"},
      myStringVar = "scalar");
equation
  when sample(0.5, 1) then
    foo(r);
  end when;
end ExtRecordMemberArguments;
