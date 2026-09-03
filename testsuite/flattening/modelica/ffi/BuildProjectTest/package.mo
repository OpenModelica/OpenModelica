package BuildProjectTest "External C that only exists as a CMake build project"
  function scale
    input Real x;
    output Real y;
  external "C" y = buildProjectTest_scale(x)
    annotation(Library = "BuildProjectTestLib",
               Include = "#include \"BuildProjectTestLib.h\"");
  end scale;
end BuildProjectTest;
