package ExtRecordStruct
  type Color = enumeration(red, green, blue);

  record Inner
    Integer i;
    Boolean b;
    annotation(CStructTag = "Inner");
  end Inner;

  record R
    Real x;
    Integer n;
    Boolean flag;
    Color c;
    Inner in1;
    String s;
    annotation(CStructTag = "R");
  end R;

  record Tagged
    Real value annotation(CName = "val");
    Integer count annotation(CName = "cnt");
    annotation(CStructTag = "MyComp_Tagged");
  end Tagged;

  record R1
    Real x;
    Integer y;
    annotation(CStructTag = "MyComp_R");
  end R1;

  record R2
    Real z;
    Real w;
    annotation(CStructTag = "MyComp_R2", Include = "struct MyComp_R2 {double a, w, z;};");
  end R2;

  function read
    input R r;
    output Real y;
  external "C" y = ers_read(r) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end read;

  function write
    input Real t;
    output R r;
  external "C" ers_write(t, r) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end write;

  function ret
    input Real t;
    output R r;
  external "C" r = ers_return(t) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end ret;

  function fill
    input Real t;
    input Integer n;
    output Inner a[n];
  external "C" ers_fill(t, a, size(a, 1)) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end fill;

  function sum
    input Inner a[:];
    output Real y;
  external "C" y = ers_sum(a, size(a, 1)) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end sum;

  function tagged
    input Tagged r;
    output Real y;
  external "C" y = ers_tagged(r) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end tagged;

  function foo
    input R1 r;
    output R2 r2;
  external "C" MyComp_foo(r, r2) annotation(Include = "#include \"fmi3_wasm_record_struct-f.c\"");
  end foo;

  model M
    R w = write(time);
    Real yw = read(w);
    R r = ret(time);
    Real yr = read(r);
    Inner a[3] = fill(time, 3);
    Real s = sum(a);
    Real t = tagged(Tagged(value = 2 + time, count = 3));
    R2 r2 = foo(R1(x = 1.5 + time, y = 2));
  end M;
end ExtRecordStruct;
