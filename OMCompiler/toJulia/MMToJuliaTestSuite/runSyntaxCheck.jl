#=
#    Julia program to run the syntax tests
=#
include("./syntaxCheck.jl")
using OMJulia: OMCSession, sendExpression
@time OMCSession(ARGS[1])
omc = size(ARGS, 1) == 1 ? OMCSession(ARGS[1]) : OMCSession()
SyntaxTest.syntaxCheck(omc)
