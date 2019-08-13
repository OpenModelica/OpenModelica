push!(LOAD_PATH, @__DIR__)
push!(LOAD_PATH, joinpath(dirname(@__DIR__), "toJuliaOutput", "AbsynToSCodeOutput"))
println(LOAD_PATH)

totalMSL = joinpath(@__DIR__,"total.mo")
if !isfile(totalMSL)
  using OMJulia: OMCSession, sendExpression
  omc = OMCSession()
  sendExpression(omc, "loadModel(Modelica)")
  sendExpression(omc, "writeFile(\"total.mo\", list())")
end

import Absyn

import MetaModelica
import OpenModelicaParser

bounce() = OpenModelicaParser.parseFile(joinpath(dirname(dirname(@__DIR__)),"Examples","BouncingBall.mo"))
msl() = OpenModelicaParser.parseFile(joinpath(@__DIR__,"total.mo"))

show(bounce())
println()
@time bounce()
msl()
@time msl()
