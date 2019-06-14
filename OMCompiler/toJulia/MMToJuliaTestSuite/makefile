allTests : syntaxTest semanticTest
syntaxTest :
	julia runSyntaxCheck.jl ${OMC_EXEC}
semanticTest : syntaxTest
	julia runSemanticCheck.jl ${OMC_EXEC}
clean :
	rm ./OutputPrimitives/*.jl ./OutputAlgorithms/*.jl ./OutputEquations/*.jl *~
