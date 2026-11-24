package UserDllCompilerDirectory
  pure function f
    input Real t;
    output Real y;
    external "C" y = userdll_compiler_directory(t) annotation(
      Library = "UserDllCompilerDirectory",
      Include = "double userdll_compiler_directory(double t);");
  end f;

  model Test
    Real y = f(time);
  end Test;
end UserDllCompilerDirectory;
