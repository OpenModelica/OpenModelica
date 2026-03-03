model ExtRecordMemberArguments
  record R
    Boolean myBooleanArray[:];
    Boolean myBooleanMatrix[2,3];
  end R;

  function foo
    input R r;

    external "C" foo(r.myBooleanArray, size(r.myBooleanArray, 1), r.myBooleanMatrix, size(r.myBooleanMatrix, 1), size(r.myBooleanMatrix, 2))
    annotation (

    Include="
void foo(const int* myBooleanArray, size_t dim_myBooleanArray_1, const int* myBooleanMatrix, size_t dim_myBooleanMatrix_1, size_t dim_myBooleanMatrix_2) {
  size_t i, j;

  printf(\"myBooleanArray: {\");
  for (i = 0; i < dim_myBooleanArray_1; ++i) {
    printf(\"%s\", myBooleanArray[i] ? \"true\" : \"false\");
    if (i + 1 < dim_myBooleanArray_1) printf(\", \");
  }
  printf(\"}\\n\");

  printf(\"myBooleanMatrix (%zu x %zu):\\n\", dim_myBooleanMatrix_1, dim_myBooleanMatrix_2);
  for (i = 0; i < dim_myBooleanMatrix_1; ++i) {
    printf(\"{\");
    for (j = 0; j < dim_myBooleanMatrix_2; ++j) {
      /* Modelica arrays are row-major: myBooleanMatrix[i*dim_myBooleanMatrix_2 + j] */
      printf(\"%s\", myBooleanMatrix[i*dim_myBooleanMatrix_2 + j] ? \"true\" : \"false\");
      if (j + 1 < dim_myBooleanMatrix_2) printf(\", \");
    }
    printf(\"}\\n\");
  }
}
");
  end foo;

  R r(myBooleanArray = {true, false, false, true, true, true},
      myBooleanMatrix = {{true, false, true}, {false, true, false}});
equation
  when sample(0.5, 1) then
    foo(r);
  end when;
end ExtRecordMemberArguments;
