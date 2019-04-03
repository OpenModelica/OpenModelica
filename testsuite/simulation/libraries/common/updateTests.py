#-------------------------------------------------------------------------------
# Name:        testbuilder
# Purpose:
#
# Author:      Christian Schubert and Bruno Scaglioni
#
# Created:     14/02/2013
# Copyright:   (c) Bruno Scaglioni 2013 / christian schubert 2012
# Licence:     OSMC-PL 1.2 http://openmodelica.org/osmc-pl/osmc-pl-1.2.txt
#-------------------------------------------------------------------------------
import subprocess
import shutil
import glob
import os
import re
import sys

DYMOLA_EXECUTABLE = 'C:/Program Files/Dymola 2013 FD01/bin/dymola.exe'
OPENMODELICAHOME = os.environ['OPENMODELICAHOME']
OPENMODELICALPATH = os.environ['OPENMODELICALIBRARY']
OMLIBRARY = "%s/Modelica 3.2.1/package.mo"%OPENMODELICALPATH
SERVICELIBRARY= "%s/ModelicaServices 3.2.1/package.mo"%OPENMODELICALPATH

testslist=['']


class Kind:
    Instantiation,Translation,Compilation,SuppressedSimulation,SimpleSimulation,VerifiedSimulation= range(6)
    
def testingString(type):
    if type==Kind.Instantiation:return 'OpenModelicaModelTesting.Kind.Instantiation'
    if type==Kind.Translation:return 'OpenModelicaModelTesting.Kind.Translation'    
    if type==Kind.Compilation:return 'OpenModelicaModelTesting.Kind.Compilation'
    if type==Kind.SuppressedSimulation:return 'OpenModelicaModelTesting.Kind.SuppressedSimulation'
    if type==Kind.SimpleSimulation:return 'OpenModelicaModelTesting.Kind.simpleSimulation'
    if type==Kind.VerifiedSimulation:return 'OpenModelicaModelTesting.Kind.VerifiedSimulation'
    

def main(tests=None):
    
    kindregexp=re.compile('modelTestingType := OpenModelicaModelTesting.Kind.[a-zA-Z]+')
    
    absPath = os.path.abspath(os.path.curdir);
    absPath=absPath.replace('\\','/')
    if tests==[] or tests==None:
        if testslist==[]:
            print('No tests provided, exiting')
            exit()
        tests=testslist
    for test in tests:
        if not test.endswith('.mos'): test=test+'.mos'
        if not os.path.exists(test):
            print('File not found for test %s\n'%test)
            continue
        f=open(test,'r')
        text=f.read()
        if not 'Please update the test' in text and not 'Update this test' in text:
            print('It seems test %s\n should not be updated, check manually'%test)
            continue
        f.close()
        testkind=re.search(kindregexp,text)
        if testkind: 
            testkind=testkind.group(0)
        else:
            print('Error, file %s malformed\n'%test)
            continue
        testkind=testkind[20:]
        
        if testkind==testingString(Kind.VerifiedSimulation):
            print('Test is verified simulation, nothing to do')
            continue
        
        if testkind==testingString(Kind.Instantiation):
            text=text.replace(testingString(Kind.Instantiation),testingString(Kind.Translation))
            print('Updating test %s to Translation, check result file'%test)
            
        if testkind==testingString(Kind.Translation):
            text=text.replace(testingString(Kind.Translation),testingString(Kind.Compilation))
            print('Updating test %s to Compilation, check result file'%test)
        
        if testkind==testingString(Kind.Compilation):
            text=text.replace(testingString(Kind.Compilation),testingString(Kind.SuppressedSimulation))
            print('Updating test %s to suppressed simulation, check result file'%test)    

        if testkind==testingString(Kind.SuppressedSimulation):
            text=text.replace(testingString(Kind.SuppressedSimulation),testingString(Kind.VerifiedSimulation)) 
            print('Updating test %s to verified simulation, check result file'%test) 

        
        #temporary write the file with new test configuration read output from OMC and put it in the string, then rewrite file
        f=open(test,'w')
        f.write(text)
        f.close()        
        
        ret = subprocess.check_output([OPENMODELICAHOME + '/bin/omc.exe', test])
        ret=ret.replace('\r\n','\n// ')
        ret=ret[:ret.rfind('\n// ')]
        ret=ret.replace(absPath.replace('\\','/')+'/','')
        temp=ret[ret.find('-0.05'):]
        ret=ret.replace('\r\n','\n')
        temp2=ret[ret.find('-0.05'):]
        text=text[:text.find('// Result:')]
        text=text+'// Result:\n// '+ret+'\n'+'// endResult'
        f=open(test,'w')
        f.write(text)
        f.close() 
    print('Finished!')
        

if __name__ == '__main__':
    main(sys.argv[1:])
