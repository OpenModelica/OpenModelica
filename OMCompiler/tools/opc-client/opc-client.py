#!/usr/bin/env python3

# Initial attempt at testing the OPC interface with real-time plotting

from opcua import Client
from opcua import ua
from time import sleep

import matplotlib.pyplot as plt
import numpy as np
import sys, traceback
import matplotlib.animation as animation
import threading

from PySide.QtCore import *
from PySide.QtGui import *

guiState = {"run":None, "rt":None, "stop":None}
app = QApplication([])
buttonRun = QPushButton("Run")
def buttonRunAction():
  if guiState["run"]:
    try:
      guiState["run"](True)
    except:
      pass
buttonRun.clicked.connect(buttonRunAction)

buttonPause = QPushButton("Pause")
def buttonPauseAction():
  if guiState["run"]:
    try:
      guiState["run"](False)
    except:
      pass
buttonPause.clicked.connect(buttonPauseAction)

buttonStop = QPushButton("Stop")
def buttonStopAction():
  if guiState["stop"]:
    try:
      guiState["stop"](True)
    except:
      pass
buttonPause.clicked.connect(buttonStopAction)

curTime = QLineEdit()
curTime.setReadOnly(True)

rtScaling = QLineEdit()
def rtScalingChanged():
  global rtScaling
  s = rtScaling.text()
  print("rtScalingChanged:",s)
  if guiState["rt"]:
    try:
      guiState["rt"](float(s))
    except:
      print("rtScaling failed...")
      traceback.print_exc(file=sys.stdout)
rtScaling.returnPressed.connect(rtScalingChanged)

main_widget = QWidget()
layout = QVBoxLayout(main_widget)
layout.addWidget(buttonRun)
layout.addWidget(buttonPause)
layout.addWidget(buttonStop)
layout.addWidget(curTime)
layout.addWidget(rtScaling)
main_widget.show()

class SubHandler(object):
  def __init__(self, client, vals):
    self.client = client
    self.timeNode = client.get_root_node().get_child(["0:Objects","1:time"])
    self.time = self.timeNode.get_value()
    self.vals = vals
    self.names = {}
    for node in client.get_root_node().get_child("0:Objects").get_children():
      self.names[(node.nodeid.NamespaceIndex,node.nodeid.Identifier)] = node.get_browse_name()
    #self.fig = plt.figure()
    #self.ax = self.fig.add_subplot(111)

  def datachange_notification(self, node, val, data):
    try:
      s = (node.nodeid.NamespaceIndex,node.nodeid.Identifier)
      if self.timeNode==node:
        self.time = val
      elif not s in self.vals:
        #line, = self.ax.plot([self.time], [val], 'r-') # Returns a tuple of line objects, thus the comma
        line = None
        self.vals[s] = (self.names[s],line,[(self.time,val)])
      else:
        self.vals[s][2].append((self.time,val))
        #lst = [list(t) for t in zip(*self.vals[s][2])]
        #self.vals[s][1].set_xdata(lst[0])
        #self.vals[s][1].set_ydata(lst[1])
        #self.fig.canvas.draw()
      # print("Python: New data change event", node, val, self.client)
    except Exception as e:
      print("datachange_notification failed: ", e)

  def event_notification(self, event):
    try:
      print("Python: New event", event)
    except:
      print("event_notification failed")

  def publish_callback(self, publishresult):
    pass

if __name__ == "__main__":
  vals = {}
  workerRunning = True
  client = Client("opc.tcp://localhost:4841", timeout=0.3)
  client.connect()
  print("Children of Objects are:")
  for n in client.get_root_node().get_child("0:Objects").get_children():
    b = 1==int(n.get_attribute(ua.AttributeIds.WriteMask).Value.Value)
    if b:
      print(n.get_browse_name())
      v = n.get_value()
      if type(v)==float:
        print("Adding writable float",n.get_browse_name())
        labelFloat = QLineEdit(str(n.get_browse_name()))
        labelFloat.setReadOnly(True)

        inputFloat = QLineEdit(str(v))
        def buttonPressed(inputFloat=inputFloat, n=n):
          try:
            n.set_value(float(inputFloat.text()))
          except:
            pass
        inputFloat.returnPressed.connect(buttonPressed)

        wid = QWidget()
        layoutFloat = QHBoxLayout(wid)
        layoutFloat.addWidget(labelFloat)
        layoutFloat.addWidget(inputFloat)
        layout.addWidget(wid)
      elif type(v)==bool:
        print("Adding writable bool",n.get_browse_name())
        cb = QCheckBox(str(n.get_browse_name()))
        cb.setCheckState(Qt.Checked if v else Qt.Unchecked)
        def buttonChecked(i, n=n):
          print("set %s=%s %d" % (n.get_browse_name(), i == Qt.Checked, i))
          n.set_value(bool(i == Qt.Checked))
        cb.stateChanged.connect(buttonChecked)
        layout.addWidget(cb)

      else:
        print("  %s, writable type %s" % (n.get_browse_name(), type(v)))
  client.disconnect()

  def worker():
    global vals, workerRunning, guiState, curTime, rtScaling, once
    client.connect()

    try:
      # Client has a few methods to get proxy to UA nodes that should always be in address space such as Root or Objects
      root = client.get_root_node()
      print("Objects node is: ", root)
      print("name of root is", root.get_browse_name())

      # Node objects have methods to read and write node attributes as well as browse or populate address space
      objs = root.get_child("0:Objects")
      step = objs.get_child("1:OpenModelica.step")
      run = objs.get_child("1:OpenModelica.run")
      use_stop = objs.get_child("1:OpenModelica.enableStopTime")
      rt = objs.get_child("1:OpenModelica.realTimeScalingFactor")
      time = objs.get_child("1:time")
      var = objs.get_child("1:" + sys.argv[1])

      handler = SubHandler(client, vals)
      sub = client.create_subscription(200, handler)
      #sub2 = client.create_subscription(500, handler)
      handle = sub.subscribe_data_change([time,var])
      #handle = sub2.subscribe_data_change(var)
      #handle2 = sub.subscribe_data_change([dervar])

      print(use_stop.get_browse_name())
      use_stop.set_value(False)
      guiState["run"] = run.set_value
      guiState["rt"] = rt.set_value
      guiState["stop"] = use_stop.set_value

      if rtScaling.text().strip()=="":
        rtScaling.setText("%.2f" % rt.get_value())

      while workerRunning:
        client.send_hello()
        curTime.setText("Time %.2f, scaling %.2f" % (handler.time, rt.get_value()))
        sleep(0.05)
        vals = handler.vals

      # print(handler.vals)

      try:
        sub.unsubscribe(handle)
        sub.unsubscribe(handle2)
        sub.delete()
      except:
        pass

      # get a specific node knowing its node id
      #var = client.get_node(ua.NodeId(1002, 2))
      #var = client.get_node("ns=3;i=2002")
      #print(var)
      #var.get_data_value() # get value of node as a DataValue object
      #var.get_value() # get value of node as a python builtin
      #var.set_value(ua.Variant([23], ua.VariantType.Int64)) #set node value using explicit data type
      #var.set_value(3.9) # set node value using implicit data type
    except:
      traceback.print_exc(file=sys.stdout)
    finally:
      try:
        client.disconnect()
      except:
        pass
    return False
  thr = threading.Thread(target=worker)
  thr.daemon = True
  thr.start()

  def animate(frameno):
    global thr
    if not thr.is_alive():
      thr.join()
      thr = threading.Thread(target=worker)
      thr.daemon = True
      thr.start()
    v = list(vals.values())[0]
    lst = [list(t) for t in zip(*v[2])]
    line[0].set_xdata(lst[0])
    line[0].set_ydata(lst[1])
    ax.set_xlim([lst[0][0],lst[0][-1]])
    minVal = min(lst[1])
    maxVal = max(lst[1])
    delta = 0.01 * (abs(minVal)+abs(maxVal))
    ax.set_ylim([minVal-delta,maxVal+delta])
    #x = mu + sigma * np.random.randn(10000)
    #n, _ = np.histogram(x, bins, normed=True)
    #for rect, h in zip(patches, n):
    #    rect.set_height(h)

  ok = False
  for i in range(0,30):
    sleep(0.1)
    if len(vals)==1:
      ok = True
      break
  if not ok:
    workerRunning = False
    assert(ok)

  fig, ax = plt.subplots()

  v = list(vals.values())[0]
  lst = [list(t) for t in zip(*v[2])]
  line = plt.plot(lst[0], lst[1], label=v[0])


  ani = animation.FuncAnimation(fig, animate, blit=False, interval=10,
                                repeat=True)
  plt.show()
