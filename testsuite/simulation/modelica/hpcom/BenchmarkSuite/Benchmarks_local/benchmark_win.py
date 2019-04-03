#-------------------------------------------------------------------------------
# Name:        becnhmark models
# Purpose:
#
# Author:      waurich
#
# Created:     04.07.2014
# Copyright:   (c) waurich 2014
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import os
import glob
import shutil
import fnmatch
import re
import time
import subprocess
#-------------------------------------------------------------------------------
              # msl models
allModels = ["Modelica.Electrical.Analog.Examples.CauerLowPassSC",
             "Modelica.Fluid.Examples.BranchingDynamicPipes",
             "Modelica.Electrical.Spice3.Examples.Spice3BenchmarkFourBitBinaryAdder"]

             #(debug flags  ,   compiler flags)
allSettings = [
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=list +hpcomCode=pthreads_spin"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=list +hpcomCode=pthreads_spin"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=list +hpcomCode=pthreads_spin"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=mcp +hpcomCode=pthreads_spin"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=mcp +hpcomCode=pthreads_spin"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=mcp +hpcomCode=pthreads_spin"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=list +hpcomCode=pthreads"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=list +hpcomCode=pthreads"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=list +hpcomCode=pthreads"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=mcp +hpcomCode=pthreads"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=mcp +hpcomCode=pthreads"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=mcp +hpcomCode=pthreads"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=list +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=list +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=list +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=mcp +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=mcp +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=mcp +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=level +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=level +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=level +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=2 +hpcomScheduler=bls +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=4 +hpcomScheduler=bls +hpcomCode=openmp"), \
               ("hpcom,hpcomDump","+n=6 +hpcomScheduler=bls +hpcomCode=openmp")
               ]

omcPath = os.environ['OPENMODELICAHOME']
path = os.path.curdir
#-------------------------------------------------------------------------------
# Util
#-------------------------------------------------------------------------------
def simulate(mosFile):
    cmd =[omcPath+'/bin/omc.exe',mosFile]
    output = subprocess.check_output(cmd)
    return output

def checkForString(content,String):
    try:
        print "content: "+content
        regex = String+'(\d+[,.]*\d*)'
        regex1 = re.compile(regex)
        ##print 'regex:'+regex
        value = re.findall(regex1,content)
        print value
        value = value[0]
        return value
    except:
        return -1
#-------------------------------------------------------------------------------
def main():
    file = glob.glob(os.path.join(os.path.curdir, 'template.mos'))
    tmpFile = open(file[0],'r')
    template = tmpFile.read()
    resFileName = time.strftime("%x_") +"__" + time.strftime("%H_%M_%S")
    resFileName = resFileName.replace("/","_")
    resFileName = "result_"+resFileName
    resultFile = open(resFileName+".txt","w")
    for model in allModels:
        print model
        newMos = template.replace("TEMPLATE_MODEL",str(model))

        # serial run
        newMosSer = newMos.replace("TEMPLATE_DEBUGFLAGS","")
        newMosSer = newMosSer.replace("TEMPLATE_COMPILERFLAGS","")
        newMosFile = open(model+"_ser.mos",'w')
        newMosFile.write(newMosSer)
        newMosFile.close()
        newMosSer = path +'\\'+  model+"_ser.mos"
        print 'run serial  : ', newMosSer
        resultFile.write(str(model)+"\tserial simTime\n")
        avSerTime = 0.0;

        n1 = 3;
        for i in range(n1):
            print "serial run: "+str(i+1)+" for "+model
            content = simulate(newMosSer)
            simTime = checkForString(content, "timeSimulation = ")
            avSerTime = float(simTime) + avSerTime
            entry = "\t"+str(simTime)+"\n"
            resultFile.write(str(entry))
        avSerTime = avSerTime/n1;
        resultFile.write("AVERAGE SERIAL TIME "+str(model)+"\t"+str(avSerTime)+"\n")

        # profiling
        newMosProf = newMos.replace("TEMPLATE_DEBUGFLAGS","")
        newMosProf = newMosProf.replace("TEMPLATE_COMPILERFLAGS","+profiling=all")
        newMosFile = open(model+"_prof.mos",'w')
        newMosFile.write(newMosProf)
        newMosFile.close()
        newMosProf = path +'\\'+  model+"_prof.mos"
        print 'run profiling  : ', newMosProf
        simulate(newMosProf)

        #execute with clock flag
        exeFile = model + '.exe'
        print 'execute with clock flag  : ', exeFile
        subprocess.check_output([exeFile, '-clock=CYC'])

        # rename json
        jsonFile = model+'_prof.json'
        try:
            os.rename(jsonFile,model+'_eqs_prof.json')
        except:
            pass

        # clean directory
        output = subprocess.check_output(['python','cleanHpcOmTestsuite.py'])

        for setting in allSettings:
            debugStr = setting[0]
            compilerStr = setting[1]
            # run in parallel
            newMos = template.replace("TEMPLATE_MODEL",str(model))
            newMos = newMos.replace("TEMPLATE_DEBUGFLAGS",debugStr)
            newMos = newMos.replace("TEMPLATE_COMPILERFLAGS",compilerStr)
            newMosFile = open(model+".mos",'w')
            newMosFile.write(newMos)
            newMosFile.close()
            newMos = path +'\\'+  model+".mos"

            resultFile.write(model+" "+debugStr+" "+compilerStr+"\n")
            entry = "\t"+"simTime\t" + "predSpeedUp\t"+ "\n"
            resultFile.write(str(entry))


            n2 = 5;
            avParTime = 0.0;
            for i in range(n2):
                print 'run in parallel  : '+str(i+1) +": "+ newMos
                content = simulate(newMos)
                simTime = checkForString(content, "timeSimulation = ")
                predSpeedUp = checkForString(content, "processors is: ")
                avParTime = avParTime +float(simTime);
                entry = "\t"+str(simTime)+"\t" + str(predSpeedUp)+ "\n"
                resultFile.write(str(entry))
            avParTime = avParTime/n2;
            resultFile.write("AVERAGE PARALLEL TIME "+str(model)+"\t"+str(avParTime)+"\n\n")

             # clean directory
            subprocess.check_output(['python','cleanHpcOmTestsuite.py'])
            print "DONE!: "+str(model)
    return None


if __name__ == '__main__':
    main()

