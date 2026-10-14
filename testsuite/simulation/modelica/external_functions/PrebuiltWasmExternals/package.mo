package PrebuiltWasmExternals
  impure function increment
    output Integer n;
  external "C" n = pwe_increment()
    annotation(Include = "#include \"counter_increment.c\"",
      IncludeDirectory = "modelica://PrebuiltWasmExternals/Resources/C-Sources");
  end increment;

  impure function count
    output Integer n;
  external "C" n = pwe_count()
    annotation(Include = "#include \"counter_count.c\"",
      IncludeDirectory = "modelica://PrebuiltWasmExternals/Resources/C-Sources");
  end count;

  function twice
    input Real x;
    output Real y;
  external "C" y = pwe_twice(x)
    annotation(Include = "#include \"twice.c\"",
      IncludeDirectory = "modelica://PrebuiltWasmExternals/Resources/C-Sources");
  end twice;

  class Accumulator
    extends ExternalObject;
    function constructor
      output Accumulator acc;
    external "C" acc = pwe_accumulator_new()
      annotation(Include = "#include \"accumulator.c\"",
        IncludeDirectory = "modelica://PrebuiltWasmExternals/Resources/C-Sources");
    end constructor;

    function destructor
      input Accumulator acc;
    external "C" pwe_accumulator_free(acc)
      annotation(Include = "#include \"accumulator.c\"",
        IncludeDirectory = "modelica://PrebuiltWasmExternals/Resources/C-Sources");
    end destructor;
  end Accumulator;

  impure function accumulate
    input Accumulator acc;
    input Real x;
    output Real sum;
  external "C" sum = pwe_accumulate(acc, x)
    annotation(Include = "#include \"accumulator.c\"",
      IncludeDirectory = "modelica://PrebuiltWasmExternals/Resources/C-Sources");
  end accumulate;

  model Counter
    discrete Integer incremented(start = 0, fixed = true);
    discrete Integer counted(start = 0, fixed = true);
    Real y = twice(time);
    Accumulator acc = Accumulator();
    discrete Real total(start = 0, fixed = true);
  algorithm
    when sample(0, 0.25) then
      incremented := increment();
      counted := count();
      total := accumulate(acc, 0.5);
    end when;
  end Counter;
end PrebuiltWasmExternals;
