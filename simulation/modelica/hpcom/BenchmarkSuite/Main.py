'''
Created on 13.10.2013

@author: Marcus
'''
from Config import MoScript
from PreHandler import ScriptPreHandler
from Executor import MoScriptExecutor
from Evaluator import SimTimeFilter, SimResultFilter

import numpy
import os
import sys
import glob
from Exporter import ExcelResultExporter
from time import gmtime, strftime

# list of scripts : fileName, useHpcOm, numberOfThreads, scheduler, additionalInfo
simulationScripts = [
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', False, 1, ''),  
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 1, 'list'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 2, 'list'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 4, 'list'),		
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 1, 'listr'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 2, 'listr'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 4, 'listr'),	
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 1, 'level'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 2, 'level'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 4, 'level'),						  
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 1, 'ext', 'taskGraphModelica.Fluid.Examples.BranchingDynamicPipes_ext'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 2, 'ext', 'taskGraphModelica.Fluid.Examples.BranchingDynamicPipes_ext'),
#						MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 4, 'ext', 'taskGraphModelica.Fluid.Examples.BranchingDynamicPipes_ext'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', False, 1, ''),  
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 1, 'list'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 2, 'list'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 4, 'list'),		
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 1, 'listr'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 2, 'listr'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 4, 'listr'),	
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 1, 'level'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 2, 'level'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 4, 'level'),						  
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 1, 'ext', 'taskGraphModelica.Mechanics.MultiBody.Examples.Loops.EngineV6_ext'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 2, 'ext', 'taskGraphModelica.Mechanics.MultiBody.Examples.Loops.EngineV6_ext'),
#						MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 4, 'ext', 'taskGraphModelica.Mechanics.MultiBody.Examples.Loops.EngineV6_ext'),						  
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', False, 1, ''),  
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 1, 'list'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 2, 'list'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 4, 'list'),		
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 1, 'listr'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 2, 'listr'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 4, 'listr'),	
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 1, 'level'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 2, 'level'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 4, 'level'),						  
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 1, 'ext', 'taskGraphHpcOm_Syn_Pipe_NElements_1000_ext'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 2, 'ext', 'taskGraphHpcOm_Syn_Pipe_NElements_1000_ext'),
#                       MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 4, 'ext', 'taskGraphHpcOm_Syn_Pipe_NElements_1000_ext'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', False, 1, ''),  
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 1, 'list'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 2, 'list'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 4, 'list'),		
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 1, 'listr'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 2, 'listr'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 4, 'listr'),	
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 1, 'level'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 2, 'level'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 4, 'level'),						  
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 1, 'ext', 'taskGraphModelica.Electrical.Analog.Examples.CauerLowPassSC_ext'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 2, 'ext', 'taskGraphModelica.Electrical.Analog.Examples.CauerLowPassSC_ext'),
#						MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 4, 'ext', 'taskGraphModelica.Electrical.Analog.Examples.CauerLowPassSC_ext'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', False, 1, ''),  
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 1, 'list'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 2, 'list'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 4, 'list'),		
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 1, 'listr'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 2, 'listr'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 4, 'listr'),	
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 1, 'level'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 2, 'level'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 4, 'level'),						  
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 1, 'ext', 'taskGraphHpcOm_Syn_NPendulum_50_ext'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 2, 'ext', 'taskGraphHpcOm_Syn_NPendulum_50_ext'),
#                       MoScript('HpcOm_Syn_NPendulum_50.mos', True, 4, 'ext', 'taskGraphHpcOm_Syn_NPendulum_50_ext'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', False, 1, ''),  
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 1, 'list'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 2, 'list'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 4, 'list'),		
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 1, 'listr'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 2, 'listr'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 4, 'listr'),	
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 1, 'level'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 2, 'level'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 4, 'level'),						  
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 1, 'ext', 'taskGraphWire.Wire_500_ext'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 2, 'ext', 'taskGraphWire.Wire_500_ext'),
#                       MoScript('HpcOm_Syn_Wire_500.mos', True, 4, 'ext', 'taskGraphWire.Wire_500_ext'),
					]

restoreFiles = [MoScript('Modelica.Fluid.Examples.BranchingDynamicPipes.mos', True, 4, 'list'),
				MoScript('Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6.mos', True, 4, 'list'),
				MoScript('HpcOm_Syn_Pipe_NElements_1000.mos', True, 4, 'list'),
				MoScript('Modelica.Electrical.Analog.Examples.CauerLowPassSC.mos', True, 4, 'list'),
				MoScript('HpcOm_Syn_NPendulum_50.mos', True, 4, 'list'),
				MoScript('HpcOm_Syn_Wire_500.mos', True, 4, 'list')
			]

workDir = './Benchmarks/'
resultFolder = 'Results'
replications = 1
dependency_files = ('*.mo', '*.mos', '*_prof.xml', '*_ext.graphml')

if __name__ == '__main__':
	preHandler = [ScriptPreHandler()]
	resultFile = resultFolder + '/' + strftime('%Y_%m_%d___%H_%M_%S', gmtime()) + '.xls'
	resultOutput = resultFolder + '/' + strftime('%Y_%m_%d___%H_%M_%S', gmtime()) + '.txt'
	exporter = ExcelResultExporter(resultFile)
	exporter.open()
	exporter.writeRow(0,['Model', 'HpcomEnabled', 'NumberOfCores', 'HpcomScheduler', 'Average', 'Min', 'Max', 'Std', 'Valid'])
	rowIndex = 1
	
	resultString = ''
	#run all benchmarks
	for s in simulationScripts:
		print 'start handling script ' + str(s)
		for ph in preHandler:
			ph.handle(s, workDir)
		
		times = []
		filterResults = []
		for r in range(replications):    
			res = MoScriptExecutor.execute(s, workDir)
			resultString = resultString + "Script: " + str(s) + " replication: " + str(r) + "\n"
			resultString = resultString + "++++++++++++++++++++++++++++++++++++++++\n"
			resultString = resultString + res + "\n"
			simTime = SimTimeFilter.getFilterValue(res)
			resFiles = SimResultFilter.checkIfFilesEqual(res)
			
			if(s.useHpcOm):
				resTg = SimResultFilter.checkIfTaskGraphCorrect(res)
			else:
				resTg = True
			
			times.append(float(simTime))
			filterResults.append((resFiles,resTg))
			print 'simulation time: ' + str(simTime) + ' valid: ' + str(resFiles) + ',' + str(resTg)
		
		tAverage = numpy.mean(times)
		tMin = min(times)
		tMax = max(times)
		tStd = numpy.std(times)
		valid = str(len(filter(lambda x: x[0] and x[1], filterResults))) + ' of ' + str(len(filterResults))
		
		print 'average: ' + str(tAverage) + ' min: ' + str(tMin) + ' max: ' + str(tMax) + ' std: ' + str(tStd) + ' valid: ' + valid
		
		exporter.writeRow(rowIndex, [str(s.fileName), str(s.useHpcOm), s.numberOfCores, str(s.hpcomScheduler), tAverage, tMin, tMax, tStd, valid])
		rowIndex = rowIndex + 1
		print 'finished'
		
	exporter.close()
	resultFile = open(resultOutput, 'w+')
	resultFile.write(resultString)
	resultFile.close()
	
	#restore the mos-files
	for s in restoreFiles:
		for ph in preHandler:
			ph.handle(s, workDir)
	
	#clean the benchmark directory
	files_grabbed = []
	for files in dependency_files:
		files_grabbed.extend(glob.glob(workDir + files))
		
	for file in set(glob.glob(workDir + '*')).difference(set(files_grabbed)):
		os.remove(file)
			
		