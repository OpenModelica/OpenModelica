package FFITest
  package Scalars
    function real1
      input Real x;
      output Real y;
    external "C" y = real1_ext(x);
      annotation(Library="FFITestLib");
    end real1;

    model Real1
      constant Real x = real1(1);
    end Real1;

    function real2
      input Real x;
      input Real y;
      input Real z;
      output Real r;
    external "C" r = real2_ext(x, y, z);
      annotation(Library="FFITestLib");
    end real2;

    model Real2
      constant Real r = real2(1, 2, 3);
    end Real2;

    function real3
      input Real x;
      input Real y;
      output Real r;
    external "C" real3_ext(x, y, r);
      annotation(Library="FFITestLib");
    end real3;

    model Real3
      constant Real r = real3(5, 2);
    end Real3;

    function integer1
      input Integer x;
      output Integer y;
    external "C" y = integer1_ext(x);
      annotation(Library="FFITestLib");
    end integer1;

    model Integer1
      constant Integer x = integer1(42);
    end Integer1;

    function integer2
      input Integer x;
      input Integer y;
      input Integer z;
      output Integer r;
    external "C" r = integer2_ext(x, y, z);
      annotation(Library="FFITestLib");
    end integer2;

    model Integer2
      constant Integer r = integer2(4, 5, 6);
    end Integer2;

    function boolean1
      input Boolean x;
      output Boolean y;
    external "C" y = boolean1_ext(x);
      annotation(Library="FFITestLib");
    end boolean1;

    model Boolean1
      constant Boolean b1 = boolean1(false);
      constant Boolean b2 = boolean1(true);
    end Boolean1;

    function boolean2
      input Boolean x;
      input Boolean y;
      input Boolean z;
      output Boolean r;
    external "C" r = boolean2_ext(x, y, z);
      annotation(Library="FFITestLib");
    end boolean2;

    model Boolean2
      constant Boolean b1 = boolean2(true, false, true);
      constant Boolean b2 = boolean2(false, false, false);
    end Boolean2;

    type E1 = enumeration(one, two, three);

    function enum1
      input E1 x;
      output E1 y;
    external "C" y = enum1_ext(x);
      annotation(Library="FFITestLib");
    end enum1;

    model Enum1
      constant E1 x1 = enum1(E1.one);
      constant E1 x2 = enum1(E1.two);
    end Enum1;

    function enum2
      input E1 x;
      input E1 y;
      output E1 r;
    external "C" r = enum2_ext(x, y);
      annotation(Library="FFITestLib");
    end enum2;

    model Enum2
      constant E1 x = enum2(E1.one, E1.two);
    end Enum2;

    model Enum3
      constant E1 x = enum1(E1.three);
    end Enum3;

    function string1
      input String x;
      output Integer y;
    external "C" y = string1_ext(x);
      annotation(Library="FFITestLib");
    end string1;

    model String1
      constant Integer x = string1("string1 test");
    end String1;

    function string2
      output String s;
    protected
      Boolean eof;
    external "C" s = ModelicaInternal_readLine("String2.mos", 1, eof);
      annotation(Library="ModelicaExternalC");
    end string2;

    model String2
      constant String s = string2();
    end String2;
  end Scalars;

  package Arrays
    function realArray1
      input Real x[:];
      output Real y[size(x, 1)];
    external "C" realArray1_ext(x, size(x, 1), y);
      annotation(Library="FFITestLib");
    end realArray1;

    model RealArray1
      constant Real[:] x = realArray1({1, 2, 3});
    end RealArray1;

    function stringArray1
      input String s[:];
      output Integer lens[size(s, 1)];
    external "C" stringArray1_ext(s, size(s, 1), lens);
      annotation(Library="FFITestLib");
    end stringArray1;

    model StringArray1
      constant Integer lens[:] = stringArray1({"test", "hello", "world"});
    end StringArray1;
  end Arrays;

  package Records
    record R1
      Real x;
    end R1;

    function record1
      input R1 r1;
      output Real x;
    external "C" x = record1_ext(r1);
      annotation(Library="FFITestLib");
    end record1;

    model Record1
      constant R1 r1(x = 4.2);
      constant Real x = record1(r1);
    end Record1;

    record R2
      Real x;
      Real y;
      Real z;
    end R2;

    function record2
      input Real x;
      input Real y;
      input Real z;
      output R2 r2;
    external "C" record2_ext(r2, x, y, z);
      annotation(Library="FFITestLib");
    end record2;

    model Record2
      constant R2 r2 = record2(3.0, 2.0, 1.0);
    end Record2;

    record R3
      Integer i1;
      Real r;
      Integer i2;
    end R3;

    function record3
      input Integer i1;
      input Real r;
      input Integer i2;
      output R3 r3;
    external "C" record3_ext(r3, i1, r, i2);
      annotation(Library="FFITestLib");
    end record3;

    model Record3
      constant R3 r3 = record3(1, 2, 3);
    end Record3;

    record R4
      Real x;
      R2 r2;
      Real y;
    end R4;

    function record4
      input Real arr[5];
      output R4 r4;
    external "C" record4_ext(arr, r4);
      annotation(Library="FFITestLib");
    end record4;

    model Record4
      constant R4 r4 = record4({6, 5, 4, 3, 2});
    end Record4;

    function record5
      input Real x;
      output R1 r1;
    external "C" r1 = record5_ext(x);
      annotation(Library="FFITestLib");
    end record5;

    model Record5
      constant R1 r1 = record5(1);
    end Record5;
  end Records;

  package ErrorChecking
    function missingFunction1
      output Real x;
    external "C" x = missingFunction1_ext();
      annotation(Library="FFITestLib");
    end missingFunction1;

    model MissingFunction1
      constant Real x = missingFunction1();
    end MissingFunction1;

    function arrayResult1
      output Real[3] x;
    external "C" x = arrayResult1_ext();
      annotation(Library="FFITestLib");
    end arrayResult1;

    model ArrayResult1
      constant Real x[:] = arrayResult1();
    end ArrayResult1;

    function exception1
      output Integer x;
    external "C" x = exception1_ext()
      annotation(Library="FFITestLib");
    end exception1;

    model Exception1
      constant Integer x = exception1();
    end Exception1;

    function crash1
      output Integer x;
    external "C" x = crash1_ext()
      annotation(Library="FFITestLib");
    end crash1;

    model Crash1
      constant Integer x = crash1();
    end Crash1;
  end ErrorChecking;

  package ExternalC
    function countLines
      input String filename;
      output Integer lines;
    external "C" lines = ModelicaInternal_countLines(filename);
      annotation(Library="ModelicaExternalC");
    end countLines;

    model ModelicaInternal_countLines
      constant Integer lines = countLines("ModelicaInternal_countLines.mos");
    end ModelicaInternal_countLines;

    function scanReal
      input String string;
      input Integer startIndex = 1;
      input Boolean unsigned = false;
      output Real number;
    protected
      Integer nextIndex;
    external "C" ModelicaStrings_scanReal(string, startIndex, unsigned, nextIndex, number);
      annotation(Library="ModelicaExternalC");
    end scanReal;

    model ModelicaStrings_scanReal
      constant Real x = scanReal("4.234");
    end ModelicaStrings_scanReal;

    function scanInteger
      input String string;
      input Integer startIndex = 1;
      input Boolean unsigned = false;
      output Integer number;
    protected
      Integer nextIndex;
    external "C" ModelicaStrings_scanInteger(string, startIndex, unsigned, nextIndex, number);
      annotation(Library="ModelicaExternalC");
    end scanInteger;

    model ModelicaStrings_scanInteger
      constant Integer x = scanInteger("4524");
    end ModelicaStrings_scanInteger;

    function scanString
      input String string;
      input Integer startIndex = 1;
      output String outString;
    protected
      Integer nextIndex;
    external "C" ModelicaStrings_scanString(string, startIndex, nextIndex, outString);
      annotation(Library="ModelicaExternalC");
    end scanString;

    model ModelicaStrings_scanString
      constant String s1 = scanString("test\"hello\"", 5);
      constant String s2 = scanString("test\"hello\"", 1);
    end ModelicaStrings_scanString;

    function readMatrixSizes
      input String fileName;
      input String matrixName;
      output Integer[2] dims;
    external "C" ModelicaIO_readMatrixSizes(fileName, matrixName, dims)
      annotation(Library = {"ModelicaIO", "ModelicaMatIO", "zlib"});
    end readMatrixSizes;

    function readRealMatrix
      input String fileName;
      input String matrixName;
      input Integer nrow;
      input Integer ncol;
      input Boolean verbose = true;
      output Real[nrow, ncol] matrix;
    external "C" ModelicaIO_readRealMatrix(fileName, matrixName, matrix, nrow, ncol, verbose)
      annotation(Library= {"ModelicaIO", "ModelicaMatIO", "zlib"});
    end readRealMatrix;

    model ModelicaIO_readRealMatrix
      constant String fileName = "matrix.mat";
      constant String matrixName = "matrix";
      constant Integer dims[:] = readMatrixSizes(fileName, matrixName);
      constant Real mat[:, :] = readRealMatrix(fileName, matrixName, dims[1], dims[2]);
    end ModelicaIO_readRealMatrix;

    record RegexResult
      Integer numMatches;
      String matches[:];
    end RegexResult;

    function regex
      input String str;
      input String re;
      input Integer maxMatches = 1;
      input Boolean extended = true;
      input Boolean caseInsensitive = false;
      output RegexResult result(redeclare String matches[3]);
    external "C" result.numMatches = OpenModelica_regex(str, re, maxMatches, extended, caseInsensitive, result.matches);
    end regex;

    model OpenModelica_regex
      constant RegexResult res = regex("hello world!", "([A-Za-z]*) ([A-Za-z]*)", 3);
    end OpenModelica_regex;
  end ExternalC;
end FFITest;
