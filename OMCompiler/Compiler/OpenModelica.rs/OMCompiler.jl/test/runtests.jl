import OMCompiler
using Test

if isempty(get(ENV, "OPENMODELICAHOME", ""))
  @warn "OPENMODELICAHOME is not set; skipping the OMCompiler tests"
else
  OMCompiler.init()

  @testset "OMCompiler" begin
    @test OMCompiler.evaluate("1 + 1") == "2\n"
    @test OMCompiler.evaluate("""loadString("
      model M
        parameter Real k = 2;
        Real x(start = 1);
      equation
        der(x) = -k * x;
      end M;")""") == "true\n"

    (fm, fns) = OMCompiler.instantiate("M")
    @test OMCompiler.typename(fm) === :NFFlatModel
    @test isempty(fns)
    @test length(fm.variables) == 2
    @test [OMCompiler.apply("ComponentRef.toString", v.name) for v in fm.variables] == ["k", "x"]
    @test fm.variables[1].attributes.variability == OMCompiler.EnumLiteral(:Variability, :PARAMETER, 3)

    local eq = only(fm.equations)
    @test OMCompiler.ctor(eq) === :EQUALITY
    @test OMCompiler.ctor(eq.lhs) === :CALL
    @test OMCompiler.apply("Equation.toString", eq) == "der(x) = -k * x"
    @test OMCompiler.nodeid(eq) == OMCompiler.nodeid(only(fm.equations))

    @test_throws ErrorException OMCompiler.instantiate("NoSuchModel")
  end
end
