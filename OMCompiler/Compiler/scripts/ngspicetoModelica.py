#!/usr/bin/python
# NgspicetoModelica.py is a python script to convert ngspice netlists to Modelica code. It is written by Rakhi R.  
# Copyright (C) 2014 Rakhi R Warriar, FOSSEE, IIT Bombay.
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

import sys
import os.path
from string import maketrans

def readNetlist(filename):
    """Read Ngspice Netlist and remove + from the start of lines"""
    netlist = []
    if os.path.exists(filename):
        try:
            f = open(filename)
        except:
            print("Error in opening file")
            sys.exit()
    else:
        print filename + " does not exist"
        sys.exit()

    data = f.read()
    data = data.splitlines()
    f.close()
    for eachline in data:
      eachline=eachline.strip()
      if len(eachline)>1:
        if eachline[0]=='+':
	  netlist.append(netlist.pop()+eachline.replace('+',' ',1))
        else:
          netlist.append(eachline)  
    return netlist

def separateNetlistInfo(netlist):
  """ Separate schematic data and option data"""
  optionInfo=[]
  schematicInfo=[]
 
  for eachline in netlist:
    if len(eachline) > 1:
     if eachline[0]=='*':
       continue
     elif eachline[0]=='.':
       optionInfo.append(eachline.lower())
     else:
       schematicInfo.append(eachline.lower())
  return optionInfo,schematicInfo


def addModel(optionInfo, dir_name):
   """ Add model parameters in the modelica file and create dictionary of model parameters"""
   modelName = []
   modelInfo = {}
   subcktName = []
   paramInfo = []
   transInfo = {}
   for eachline in optionInfo:
    words = eachline.split()
    if words[0] == '.include':
      name = words[1].split('.')
      if name[1] == 'lib':
        modelName.append(name[0])
      if name[1] == 'sub':
  	subcktName.append(name[0])
    elif words[0] == '.model':
      model = words[1]
      modelInfo[model] = {}
      eachline = eachline.replace(' = ','=')
      eachline = eachline.replace('= ','=')
      eachline = eachline.replace(' =','=')
      eachline = eachline.split('(')
      templine = eachline[0].split()
      trans = templine[1]
      transInfo[trans] = []
      if templine[2] in ['npn', 'pnp', 'pmos', 'nmos']:
        transInfo[trans] = templine[2]
      eachline = eachline[1].split()
      for eachitem in eachline:
        if len(eachitem) > 1:
         eachitem = eachitem.replace(')','')
         iteminfo = eachitem.split('=')
         for each in iteminfo:
          modelInfo[model][iteminfo[0]] = iteminfo[1]
    elif words[0] == '.param':
      paramInfo.append(eachline) 
   for eachmodel in modelName:
     filename = eachmodel + '.lib'
     filename = os.path.join(dir_name, filename)
     if os.path.exists(filename):
        try:
            f = open(filename)
        except:
            print("Error in opening file")
            sys.exit()
     else:
        print filename + " does not exist"
        sys.exit()

     data = f.read()
     data = data.lower()
     data = data.replace('+', '')
     data = data.replace('\n','')
     data = data.replace(' = ','=')
     data = data.replace('= ','=')
     data = data.replace(' =','=')
     newdata = data.split('(')
     templine_f = newdata[0].split()
     trans_f = templine_f[1]
     transInfo[trans_f] = []
     if templine_f[2] in ['npn', 'pnp', 'pmos', 'nmos']:
       transInfo[trans_f] = templine_f[2]
     newdata = newdata[1].split()
     modelInfo[eachmodel] = {}
     for eachline in newdata:
       if len(eachline) > 1:
        eachline = eachline.replace(')','')
        info = eachline.split('=')
        for eachitem in info:
         modelInfo[eachmodel][info[0]] = info[1] #dictn within a dictn
     f.close()
          
   return modelName, modelInfo, subcktName, paramInfo, transInfo     
     

def processParam(paramInfo):
    """ Process parameter info and update in Modelica syntax"""
    modelicaParam = []
    for eachline in paramInfo:
      eachline = eachline.split('.param')
      stat = 'parameter Real ' + eachline[1] + ';'
      stat = stat.translate(maketrans('{}', '  '))
      modelicaParam.append(stat)
    return modelicaParam


def separatePlot(schematicInfo):
   """ separate print plot and component statements"""
   compInfo = []
   plotInfo = []
   
   for eachline in schematicInfo:
    words = eachline.split()
    if words[0] == 'run':
      continue
    elif words[0] == 'plot' or words[0] == 'print':
      plotInfo.append(eachline)
    else:
      compInfo.append(eachline)
   return compInfo, plotInfo

def separateSource(compInfo):
   """Find if dependent sources are present in the schematic and if so make a dictionary with source details"""
   sourceInfo = {}
   source = []
   for eachline in compInfo:
     if eachline[0] in ['f', 'h']:
       source.append(words[3])
   if len(source) > 0:
     for eachline in compInfo:
       words_s = eachline.split()
       if words_s[0] in source:
         sourceInfo[words_s[0]] = words_s[1:3]
   return sourceInfo


def splitIntoVal(val):
   """ Split the number k,u,p,t,g etc into powers e3,e-6 etc"""
   for i in range(0,len(val),1):
       if val[i] in ['k','u','p','t','g','m','n','f']:
         newval = val.split(val[i])
         if val[i] == 'k':
           value = newval[0] + 'e3'
         if val[i] == 'u':
           value = newval[0] + 'e-6'
         if val[i] == 'p':
           value = newval[0] + 'e-12'
         if val[i] == 't':  
           value = newval[0] + 'e12'
         if val[i] == 'g':
           value = newval[0] + 'e9'
         if val[i] == 'm':
           if i != len(val)-1:
             if val[i+1] == 'e':
              value = newval[0] + 'e6'
           else:
            value = newval[0] +'e-3'
         if val[i] == 'n':
           value = newval[0] + 'e-9'       
         if val[i] == 'f':
           value = newval[0] +'e-15'
       else:
         value = val
   return value

def tryExists(wordNo, key,default):
    """ checks if entry for key exists in dictionary, else returns default"""
    try:
       keyval = modelInfo[words[wordNo]][key]
    except KeyError:
       keyval = str(default)
    return keyval
    
def compInit(compInfo, node, modelInfo, subcktName, dir_name, transInfo):
   """For each component in the netlist initialise it acc to Modelica format"""
#### initial processign to check if MOSFET is present. If so, library to be used is BondLib
   modelicaCompInit = []
   mosInfo = {}
   numNodesSub = {} 
   IfMOS = '0'
   for eachline in compInfo:
#     words = eachline.split()
     if eachline[0] == 'm':
       IfMOS = '1'
       break
   if len(subcktName) > 0:
     subOptionInfo = []
     subSchemInfo = []
     for eachsub in subcktName:
       filename_tem = eachsub + '.sub'
       filename_tem = os.path.join(dir_name, filename_tem)
       data = readNetlist(filename_tem)
       subOptionInfo, subSchemInfo = separateNetlistInfo(data)
       for eachline in subSchemInfo:
#        words = eachline.split()
        if eachline[0] == 'm':
          IfMOS = '1'
          break
   for eachline in compInfo:
     words = eachline.split()
     val = words[3]
     value = splitIntoVal(val)
     if eachline[0] == 'r':
       stat = 'Analog.Basic.Resistor ' + words[0] + '(R = ' + value + ');'
       modelicaCompInit.append(stat)
     elif eachline[0] == 'c':
       stat = 'Analog.Basic.Capacitor ' + words[0] + '(C = ' + value + ');'
       modelicaCompInit.append(stat)
     elif eachline[0] == 'l':
       stat = 'Analog.Basic.Inductor ' + words[0] + '(L = ' + value + ');'
       modelicaCompInit.append(stat) 
     elif eachline[0] == 'e':
       stat = 'Analog.Basic.VCV ' + words[0] + '(gain = ' + splitIntoVal(words[5]) + ');'
       modelicaCompInit.append(stat) 
     elif eachline[0] == 'g':
       stat = 'Analog.Basic.VCC ' + words[0] + '(transConductance = ' + splitIntoVal(words[5]) + ');'
       modelicaCompInit.append(stat) 
     elif eachline[0] == 'f':
       stat = 'Analog.Basic.CCC ' + words[0] + '(gain = ' + splitIntoVal(words[4]) + ');'
       modelicaCompInit.append(stat) 
     elif eachline[0] == 'h':
       stat = 'Analog.Basic.CCV ' + words[0] + '(transResistance = ' + splitIntoVal(words[4]) + ');'
       modelicaCompInit.append(stat) 
     elif eachline[0] == 'd':
       if len(words) > 3:
        n = float(modelInfo[words[3]]['n'])
        vt_temp = 0.025*n
        vt = str(vt_temp)
        stat = 'Analog.Semiconductors.Diode ' + words[0] + '(Ids = ' + modelInfo[words[3]]['is'] + ', Vt = ' + vt + ', R = 1e12' +');'
       else:
        stat = 'Analog.Semiconductors.Diode ' + words[0] +';'
       modelicaCompInit.append(stat)
     elif eachline[0] == 'q':
       trans = transInfo[words[4]]
       if trans == 'npn':
          start = 'Analog.Semiconductors.NPN '
       else:
          start = 'Analog.Semiconductors.PNP '
       inv_vak = float(tryExists(4, 'vaf', 50))
       vak_temp = 1/inv_vak
       vak = str(vak_temp)
       bf = tryExists(4, 'bf', 50)
       br = tryExists(4, 'br', 0.1)
       Is = tryExists(4, 'is', 1e-16)
       tf = tryExists(4, 'tf', 1.2e-10)
       tr = tryExists(4, 'tr', 5e-9)
       cjs = tryExists(4, 'cjs', 1e-12)
       cje = tryExists(4, 'cje', 4e-13)
       cjc = tryExists(4, 'cjc', 5e-13)
       vje = tryExists(4, 'vje', 0.8)
       mje = tryExists(4, 'mje', 0.4)
       vjc = tryExists(4, 'vjc', 0.8)
       mjc = tryExists(4, 'mjc', 0.333)
       stat = start + words[0] +'(Bf = ' + bf + ', Br = ' + br + ', Is = ' + splitIntoVal(Is) + ', Vak = ' + vak + ', Tauf = ' + splitIntoVal(tf) + ', Taur = ' + splitIntoVal(tr) + ', Ccs = ' + splitIntoVal(cjs) + ', Cje = ' + splitIntoVal(cje) + ', Cjc = ' + splitIntoVal(cjc) + ', Phie = ' + vje + ', Me = ' + mje + ', Phic = ' + vjc + ', Mc = ' + mjc + ');'
       modelicaCompInit.append(stat)
     elif eachline[0] == 'm':
       eachline = eachline.split(words[5])
       eachline = eachline[1]
       eachline = eachline.strip()
       eachline = eachline.replace(' = ', '=')
       eachline = eachline.replace('= ','=')
       eachline = eachline.replace(' =','=')
       eachline = eachline.replace(' * ', '*')
       eachline = eachline.replace(' + ', '+')
       eachline = eachline.replace(' { ', '')
       eachline = eachline.replace(' } ', '')
       eachline = eachline.split()
       mosInfo[words[0]] = {}
       for each in eachline:
         if len(each) > 1:
           each  = each.split('=')
           mosInfo[words[0]][each[0]] = each[1]
       trans = transInfo[words[5]]
       if trans == 'nmos':
          start = 'BondLib.Electrical.Analog.Spice.Mn '
       else:
          start = 'BondLib.Electrical.Analog.Spice.Mp '
       vto = tryExists(5, 'vto', 0)
       gam = tryExists(5, 'gamma', 0)
       phi = tryExists(5, 'phi', 0)
       ld = tryExists(5, 'ld', 0)
       uo = tryExists(5, 'uo', 0)
       lam  = tryExists(5, 'lambda', 0)
       tox = tryExists(5, 'tox', 3e-9)
       pb = tryExists(5, 'pb', 0.8)
       cj = tryExists(5, 'cj', 0)
       cjsw = tryExists(5, 'cjsw', 1e-9)
       mj = tryExists(5, 'mj', 0.33)
       mjsw = tryExists(5, 'mjsw', 0.33)
       cgdo = tryExists(5, 'cgdo', 0)
       js = tryExists(5, 'js', 0)
       cgbo = tryExists(5, 'cgbo', 0)
       cgso = tryExists(5, 'cgso', 0)
       try:
         l = mosInfo[words[0]]['l']
       except KeyError:
         l = '1e-6'
       try:
         w = mosInfo[words[0]]['w']
       except KeyError:
         w = '100e-6'
       try:
         As = mosInfo[words[0]]['as']
         ad = mosInfo[words[0]]['ad']
       except KeyError:
         As = '0'
         ad = '0'
       try:
         ps = mosInfo[words[0]]['ps']
         pd = mosInfo[words[0]]['pd']
       except KeyError:
         ps = '0'
         pd = '0'
       stat = start + words[0] + '(Tnom = 300, VT0 = ' + vto + ', GAMMA = ' + gam + ', PHI = ' + phi + ', LD = ' + splitIntoVal(ld) + ', U0 = ' + str(float(splitIntoVal(uo))*0.0001) + ', LAMBDA = ' + lam + ', TOX = ' + splitIntoVal(tox) + ', PB = ' + pb + ', CJ = ' + splitIntoVal(cj) + ', CJSW = ' + splitIntoVal(cjsw) + ', MJ = ' + mj + ', MJSW = ' + mjsw + ', CGD0 = ' + splitIntoVal(cgdo) + ', JS = ' + splitIntoVal(js) + ', CGB0 = ' + splitIntoVal(cgbo) + ', CGS0 = ' + splitIntoVal(cgso) + ', L = ' + splitIntoVal(l) + ', W = ' + w + ', Level = 1' + ', AD = ' + ad + ', AS = ' + As + ', PD = ' + pd + ', PS = ' + ps + ');'
       stat = stat.translate(maketrans('{}', '  '))
       modelicaCompInit.append(stat)
     elif eachline[0] == 'v':
       typ = words[3].split('(')
       if typ[0] == "pulse":
          per = words[9].split(')')
 #         if IfMOS == '0':
 #          stat = 'Spice3.Sources.V_pulse '+words[0]+'(TR = '+words[6]+', V2 = '+words[4]+', PW = '+words[8]+', PER = '+per[0]+', V1 = '+typ[1]+', TD = '+words[5]+', TF = '+words[7]+');'
 #         elif IfMOS == '1': 
          stat = 'Analog.Sources.TrapezoidVoltage '+words[0]+'(rising = '+words[6]+', V = '+words[4]+', width = '+words[8]+', period = '+per[0]+', offset = '+typ[1]+', startTime = '+words[5]+', falling = '+words[7]+');'
          modelicaCompInit.append(stat)
       if typ[0] == "sine":
          theta = words[7].split(')')
#          if IfMOS == '0':
#           stat = 'Spice3.Sources.V_sin '+words[0]+'(VO = '+typ[1]+', VA = '+words[4]+', FREQ = '+words[5]+', TD = '+words[6]+', THETA = '+theta[0]+');'
#          elif IfMOS == '1':
          stat = 'Analog.Sources.SineVoltage '+words[0]+'(offset = '+typ[1]+', V = '+words[4]+', freqHz = '+words[5]+', startTime = '+words[6]+', phase = '+theta[0]+');'
          modelicaCompInit.append(stat)
       if typ[0] == "pwl":
#          if IfMOS == '0':
#           keyw = 'Spice3.Sources.V_pwl '
#          elif IfMOS == '1':
          keyw = 'Analog.Sources.TableVoltage '
          stat = keyw + words[0] + '(table = [' + typ[1] + ',' + words[4] + ';' 
          length = len(words);
          for i in range(6,length,2):
             if i == length-2:
               w = words[i].split(')')
               stat = stat + words[i-1] + ',' + w[0] 
             else:
               stat = stat + words[i-1] + ',' + words[i] + ';'
          stat = stat + ']);'
          modelicaCompInit.append(stat) 
       if typ[0] == words[3] and typ[0] != "dc":
          val_temp = typ[0].split('v')
#          if IfMOS  == '0':
          stat = 'Analog.Sources.ConstantVoltage ' + words[0] + '(V = ' + val_temp[0] + ');'
#          elif IfMOS == '1':
#           stat = 'Analog.Sources.ConstantVoltage ' + words[0] + '(V = ' + val_temp[0] + ');'
          modelicaCompInit.append(stat)
       elif typ[0] == words[3] and typ[0] == "dc":
#          if IfMOS  == '0':
#           stat = 'Spice3.Sources.V_constant ' + words[0] + '(V = ' + words[4] + ');'    
#          elif IfMOS == '1':
          stat = 'Analog.Sources.ConstantVoltage ' + words[0] + '(V = ' + words[4] + ');'    
          modelicaCompInit.append(stat)
     elif eachline[0] == 'x':
       temp_line = eachline.split()
       temp = temp_line[0].split('x')
       index = temp[1]
       for i in range(0,len(temp_line),1):
         if temp_line[i] in subcktName:
           subname = temp_line[i]
           numNodesSub[subname] = i - 1
           point = i
       if len(temp_line) > point + 1:
         rem = temp_line[point+1:len(temp_line)]
         rem_new = ','.join(rem)
         stat = subname + ' ' + subname +'_instance' + index + '(' +  rem_new + ');'
       else:
         stat = subname + ' ' + subname +'_instance' + index + ';'
       modelicaCompInit.append(stat)
     else:
       continue
   if '0' in node:
      modelicaCompInit.append('Analog.Basic.Ground g;')
   return modelicaCompInit, numNodesSub

def getSubInterface(subname, numNodesSub):
   """ Get the list of nodes for subcircuit in .subckt line"""
   subOptionInfo_p = []
   subSchemInfo_p = []
   filename_t = subname + '.sub'
   filename_t = os.path.join(dir_name, filename_t)
   data_p = readNetlist(filename_t)
   subOptionInfo_p, subSchemInfo_p = separateNetlistInfo(data_p)
   if len(subOptionInfo_p) > 0:
     newline = subOptionInfo_p[0]
     newline = newline.split('.subckt '+ subname)       
     intLine = newline[1].split()
     newindex = numNodesSub[subname]
     nodesInfoLine = intLine[0:newindex]
   return nodesInfoLine 


def getSubParamLine(subname, numNodesSub, subParamInfo, dir_name):
   """ Take subcircuit name and give the info related to parameters in the first line and initislise it in """
#   nodeSubInterface = []
   subOptionInfo_p = []
   subSchemInfo_p = []
   filename_t = subname + '.sub'
   filename_t = os.path.join(dir_name, filename_t)
   data_p = readNetlist(filename_t)
   subOptionInfo_p, subSchemInfo_p = separateNetlistInfo(data_p)
   if len(subOptionInfo_p) > 0:
     newline = subOptionInfo_p[0]
     newline = newline.split('.subckt '+ subname)       
     intLine = newline[1].split()
     newindex = numNodesSub[subname]
     appen_line = intLine[newindex:len(intLine)]
     appen_param = ','.join(appen_line)
     paramLine = 'parameter Real ' + appen_param + ';'
     paramLine = paramLine.translate(maketrans('{}', '  '))
     subParamInfo.append(paramLine)
   return subParamInfo

def nodeSeparate(compInfo, ifSub, subname, subcktName):
   """ separate the node numbers and create nodes in modelica file; the nodes in the subckt line should not be inside protected keyword. pinInit is the one that goes under protected keyword."""
   node = []
   nodeTemp = []
   nodeDic = {}
   pinInit = 'Modelica.Electrical.Analog.Interfaces.Pin '
   pinProtectedInit = 'Modelica.Electrical.Analog.Interfaces.Pin '
   protectedNode = []
   for eachline in compInfo:
     words = eachline.split()
     if eachline[0] in ['m', 'e', 'g', 't']:
      nodeTemp.append(words[1])
      nodeTemp.append(words[2])
      nodeTemp.append(words[3])
      nodeTemp.append(words[4])
     elif eachline[0] in ['q', 'j']:
      nodeTemp.append(words[1])
      nodeTemp.append(words[2])
      nodeTemp.append(words[3])
     elif eachline[0] == 'x':
      templine = eachline.split()
      for i in range(0,len(templine),1):
        if templine[i] in subcktName:
          point = i   
      nodeTemp.extend(words[1:point])
     else:
      nodeTemp.append(words[1])
      nodeTemp.append(words[2])
   for i in nodeTemp:
    if i not in node:
      node.append(i)
   for i in range(0, len(node),1):
     nodeDic[node[i]] = 'n' + node[i]
     if ifSub == '0':
       if i != len(node)-1:
        pinInit = pinInit + nodeDic[node[i]] + ', '
       else:
        pinInit = pinInit + nodeDic[node[i]] 
     else:
       nonprotectedNode = getSubInterface(subname, numNodesSub)
       if node[i] in nonprotectedNode:
        continue
       else:
        protectedNode.append(node[i])
   if ifSub == '1': 
     if len(nonprotectedNode) > 0:    
      for i in range(0, len(nonprotectedNode),1):
        if i != len(nonprotectedNode)-1:
         pinProtectedInit = pinProtectedInit + nodeDic[nonprotectedNode[i]] + ','
        else:
         pinProtectedInit = pinProtectedInit + nodeDic[nonprotectedNode[i]]
     if len(protectedNode) > 0:
      for i in range(0, len(protectedNode),1):
        if i != len(protectedNode)-1: 
         pinInit = pinInit + nodeDic[protectedNode[i]] + ','
        else:
         pinInit = pinInit + nodeDic[protectedNode[i]] 
   pinInit = pinInit + ';'
   pinProtectedInit = pinProtectedInit + ';'
   return node, nodeDic, pinInit, pinProtectedInit
  
def connectInfo(compInfo, node, nodeDic, numNodesSub):
   """Make node connections in the modelica netlist"""
   connInfo = []
   sourcesInfo = separateSource(compInfo)
   for eachline in compInfo:
     words = eachline.split()
     if eachline[0] == 'r' or eachline[0] == 'c' or eachline[0] == 'd' or eachline[0] == 'l' or eachline[0] == 'v':
       conn = 'connect(' + words[0] + '.p,' + nodeDic[words[1]] + ');'
       connInfo.append(conn)
       conn = 'connect(' + words[0] + '.n,' + nodeDic[words[2]] + ');'
       connInfo.append(conn)
     elif eachline[0] == 'q':
       conn = 'connect(' + words[0] + '.C,' + nodeDic[words[1]] + ');'
       connInfo.append(conn)
       conn = 'connect(' + words[0] + '.B,' + nodeDic[words[2]] + ');'
       connInfo.append(conn)
       conn = 'connect(' + words[0] + '.E,' + nodeDic[words[3]] + ');'
       connInfo.append(conn)
     elif eachline[0] == 'm':
       conn = 'connect(' + words[0] + '.D,' + nodeDic[words[1]] + ');'
       connInfo.append(conn)
       conn = 'connect(' + words[0] + '.G,' + nodeDic[words[2]] + ');'
       connInfo.append(conn)
       conn = 'connect(' + words[0] + '.S,' + nodeDic[words[3]] + ');'
       connInfo.append(conn)
       conn = 'connect(' + words[0] + '.B,' + nodeDic[words[4]] + ');'
       connInfo.append(conn)
     elif eachline[0] in ['f','h']:
      vsource = words[3]
      sourceNodes = sourcesInfo[vsource]
      sourceNodes = sourceNodes.split()
      conn = 'connect(' + words[0] + '.p1,'+ nodeDic[sourceNodes[0]] + ');'
      connInfo.append(conn)
      conn = 'connect(' + words[0] + '.n1,'+ nodeDic[sourceNodes[1]] + ');'
      connInfo.append(conn)
      conn = 'connect(' + words[0] + '.p2,'+ nodeDic[words[1]] + ');'
      connInfo.append(conn)
      conn = 'connect(' + words[0] + '.n2,'+ nodeDic[words[2]] + ');'
      connInfo.append(conn)
     elif eachline[0] in ['g','e']:
      conn = 'connect(' + words[0] + '.p1,'+ nodeDic[words[3]] + ');'
      connInfo.append(conn)
      conn = 'connect(' + words[0] + '.n1,'+ nodeDic[words[4]] + ');'
      connInfo.append(conn)
      conn = 'connect(' + words[0] + '.p2,'+ nodeDic[words[1]] + ');'
      connInfo.append(conn)
      conn = 'connect(' + words[0] + '.n2,'+ nodeDic[words[2]] + ');'
      connInfo.append(conn)
     elif eachline[0] == 'x':
      templine = eachline.split()
      temp = templine[0].split('x')
      index = temp[1]
      for i in range(0,len(templine),1):
        if templine[i] in subcktName:
          subname = templine[i]
      nodeNumInfo = getSubInterface(subname, numNodesSub)
      for i in range(0, numNodesSub[subname], 1):
#        conn = 'connect(' + subname + '_instance' + index + '.' + nodeDic[nodeNumInfo[i]] + ',' + nodeDic[words[i+1]] + ');'
        conn = 'connect(' + subname + '_instance' + index + '.' + 'n'+ nodeNumInfo[i] + ',' + nodeDic[words[i+1]] + ');'
        connInfo.append(conn)              
     else:
     #elif eachline[0] == 'q':
     #elif eachline[0] == 'j':
       continue
   if '0' in node:
     conn = 'connect(g.p,n0);'
     connInfo.append(conn)
   return connInfo
## For testing
     

if len(sys.argv) < 2:
  filename=raw_input('Enter file name: ')
else:
  filename=sys.argv[1]
dir_name = os.path.dirname(os.path.realpath(filename))
file_basename = os.path.basename(filename)
#print dir_name
#print file_basename

# get all the required info
lines=readNetlist(filename)
optionInfo, schematicInfo=separateNetlistInfo(lines)
modelName, modelInfo, subcktName, paramInfo, transInfo = addModel(optionInfo, dir_name)
modelicaParamInit = processParam(paramInfo)
compInfo, plotInfo = separatePlot(schematicInfo)
IfMOS = '0'
for eachline in compInfo:
 words = eachline.split()
 if eachline[0] == 'm':
  IfMOS = '1'
  break
if len(subcktName) > 0:
 subOptionInfo = []
 subSchemInfo = []
 for eachsub in subcktName:
  filename_temp = eachsub + '.sub'
  filename_temp = os.path.join(dir_name, filename_temp)
  #print filename_temp
  data = readNetlist(filename_temp)
  subOptionInfo, subSchemInfo = separateNetlistInfo(data)
  for eachline in subSchemInfo:
   words = eachline.split()
   if eachline[0] == 'm':
    IfMOS = '1'
    break
node, nodeDic, pinInit, pinProtectedInit = nodeSeparate(compInfo, '0', [], subcktName)
modelicaCompInit, numNodesSub  = compInit(compInfo,node, modelInfo, subcktName, dir_name, transInfo)
connInfo = connectInfo(compInfo, node, nodeDic, numNodesSub)

####Extract subckt data
def procesSubckt(subcktName, dir_name):
   """ Process the subcircuit file .sub in the project folder"""
#   subcktDic = {}
   subOptionInfo = []
   subSchemInfo = []
   subModel = []
   subModelInfo = {}
   subsubName = [] 
   subParamInfo = []
   nodeSubInterface = []
   nodeSub = []
   nodeDicSub = {}
   pinInitsub = []
   connSubInfo = []
   if len(subcktName) > 0:
    for eachsub in subcktName:
     filename = eachsub + '.sub'
     basename = filename
     filename = os.path.join(dir_name, filename)
     #print filename
     data = readNetlist(filename)
     subOptionInfo, subSchemInfo = separateNetlistInfo(data)
     if len(subOptionInfo) > 0:
       newline = subOptionInfo[0]
       subInitLine = newline
       newline = newline.split('.subckt')       
       intLine = newline[1].split()
       for i in range(0,len(intLine),1):
         nodeSubInterface.append(intLine[i])
     subModel, subModelInfo, subsubName, subParamInfo, subtransInfo = addModel(subOptionInfo, dir_name)
     IfMOSsub = '0'
     for eachline in subSchemInfo:
#      words = eachline.split()
      if eachline[0] == 'm':
        IfMOSsub = '1'
        break
     if len(subsubName) > 0:
      subsubOptionInfo = []
      subsubSchemInfo = []
      for eachsub in subsubName:
       filename_st = eachsub + '.sub'
       filename_stemp = os.path.join(dir_name, filename_st)
       data = readNetlist(filename_stemp)
       subsubOptionInfo, subsubSchemInfo = separateNetlistInfo(data)
       for eachline in subsubSchemInfo:
#        words = eachline.split()
        if eachline[0] == 'm':
         IfMOSsub = '1'
         break
     modelicaSubParam =  processParam(subParamInfo)
     nodeSub, nodeDicSub, pinInitSub, pinProtectedInitSub = nodeSeparate(subSchemInfo, '1', eachsub, subsubName)
     modelicaSubCompInit, numNodesSubsub = compInit(subSchemInfo, nodeSub, subModelInfo, subsubName, dir_name, subtransInfo)
     modelicaSubParamNew = getSubParamLine(eachsub, numNodesSub, modelicaSubParam, dir_name)
     connSubInfo = connectInfo(subSchemInfo, nodeSub, nodeDicSub, numNodesSubsub)
     newname = basename.split('.')
     newfilename = newname[0]
     outfilename = newfilename+ ".mo"
     outfilename = os.path.join(dir_name, outfilename)
     out = open(outfilename,"w")
     out.writelines('model ' + newfilename)
     out.writelines('\n')
     if IfMOSsub == '0':
      out.writelines('import Modelica.Electrical.*;')
     elif IfMOSsub == '1':
      out.writelines('import BondLib.Electrical.*;')
     out.writelines('\n') 
     for eachline in modelicaSubParamNew:
       if len(subParamInfo) == 0:
         continue
       else:
        out.writelines(eachline) 
        out.writelines('\n') 
     for eachline in modelicaSubCompInit:
      if len(subSchemInfo) == 0:
       continue
      else:
       out.writelines(eachline)
       out.writelines('\n')
     out.writelines(pinProtectedInitSub)
     out.writelines('\n')
     if pinInitSub != 'Modelica.Electrical.Analog.Interfaces.Pin ;':
      out.writelines('protected')
      out.writelines('\n')
      out.writelines(pinInitSub)
      out.writelines('\n')
     out.writelines('equation')
     out.writelines('\n')
     for eachline in connSubInfo:
       if len(connSubInfo) == 0:
        continue
       else:
        out.writelines(eachline)
        out.writelines('\n')
     out.writelines('end '+ newfilename + ';')
     out.writelines('\n')
     out.close()
   
   return data, subOptionInfo, subSchemInfo, subModel, subModelInfo, subsubName, subParamInfo, modelicaSubCompInit, modelicaSubParam, nodeSubInterface, nodeSub, nodeDicSub, pinInitSub, connSubInfo 

if len(subcktName) > 0:
 data, subOptionInfo, subSchemInfo, subModel, subModelInfo, subsubName, subParamInfo, modelicaSubCompInit, modelicaSubParam,  nodeSubInterface, nodeSub, nodeDicSub, pinInitSub, connSubInfo = procesSubckt(subcktName, dir_name)

# creating final output

newfile = file_basename.split('.')
newfilename = newfile[0]
outfile = newfilename + ".mo"
outfile = os.path.join(dir_name, outfile)
out = open(outfile,"w")
out.writelines('model ' + newfilename)
out.writelines('\n')
if IfMOS == '0':
 out.writelines('import Modelica.Electrical.*;')
elif IfMOS == '1':
 out.writelines('import BondLib.Electrical.*;')
#out.writelines('import Modelica.Electrical.*;')
out.writelines('\n')

for eachline in modelicaParamInit:
  if len(paramInfo) == 0:
    continue
  else:
    out.writelines(eachline)
    out.writelines('\n')
for eachline in modelicaCompInit:
  if len(compInfo) == 0:
    continue
  else:
    out.writelines(eachline)
    out.writelines('\n')

out.writelines('protected')
out.writelines('\n')
out.writelines(pinInit)
out.writelines('\n')
out.writelines('equation')
out.writelines('\n')

for eachline in connInfo:
  if len(connInfo) == 0:
    continue
  else:
    out.writelines(eachline)
    out.writelines('\n')

out.writelines('end '+ newfilename + ';')
out.writelines('\n')


out.close()


