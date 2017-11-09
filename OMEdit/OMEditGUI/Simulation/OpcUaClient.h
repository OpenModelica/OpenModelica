#ifndef OPCUACLIENT_H
#define OPCUACLIENT_H

#include "OMPlot.h"
#include "open62541.h"
#include "SimulationOptions.h"

class VariablesTreeItem;
class OpcUaWorker;
class Variable;

class OpcUaClient : public QObject
{
  Q_OBJECT
public:
  OpcUaClient(SimulationOptions simulationOptions);
  ~OpcUaClient();

  bool connectToServer();
  QStringList fetchVariableNamesFromServer();
  QMap<QString, Variable*> *getVariables() {return &mVariables;}
  UA_Client* getClient() {return mpClient;}
  bool variableIsWritable(int nodeId);
  bool variableIsReal(int nodeId);
  double readReal(int id);
  bool variableIsBool(int nodeId);
  int readBool(int id);
  void writeValue(const QVariant &value, const QString &name);
  double getCurrentSimulationTime();
  QMap<int, VariablesTreeItem*> getCheckedVariables() {return mCheckedVariables;}
  void checkVariable(int nodeId, VariablesTreeItem *pVariablesTreeItem);
  void unCheckVariable(int nodeId, const QString &name);
  SimulationOptions getSimulationOptions() {return mSimulationOptions;}
  void setTargetPlotWindow(OMPlot::PlotWindow* pTargetPlotWindow) {mpTargetPlotWindow = pTargetPlotWindow;}
  OMPlot::PlotWindow* getTargetPlotWindow() {return mpTargetPlotWindow;}
  void setOpcUaWorker(OpcUaWorker *pOpcUaWorker) {mpOpcUaWorker = pOpcUaWorker;}
  OpcUaWorker* getOpcUaWorker() {return mpOpcUaWorker;}
  QThread* getSampleThread() {return mpSampleThread;}
private:
  UA_Client *mpClient;
  QThread *mpSampleThread;
  OpcUaWorker* mpOpcUaWorker;
  QMap<QString, Variable*> mVariables;
  QMap<int, VariablesTreeItem*> mCheckedVariables;
  SimulationOptions mSimulationOptions;
  OMPlot::PlotWindow *mpTargetPlotWindow;
};

class OpcUaWorker : public QObject
{
  Q_OBJECT
public:
  OpcUaWorker(OpcUaClient *pClient, bool simulateWithSteps);
  ~OpcUaWorker();
  void stepSimulation();
  double getCurrentSimulationTime();
  void checkMinMaxValues(const double& value);
  void setSampleInterval(double interval);
  double getSampleInterval() {return mSampleInterval;}
  void setVariablesTreeItemRoot(VariablesTreeItem * pVariablesTreeItemRoot);
  VariablesTreeItem* getVariablesTreeItemRoot() {return mpVariablesTreeItemRoot;}
  QThreadStorage<QMap<UA_UInt32, Variable*>>* getMonitorIds() {return &mMonitorIds;}
public slots:
  void addMonitoredItem(int nodeId, const QString &variableName);
  void removeMonitoredItem(const QString &variableName);
  void startInteractiveSimulation();
  void pauseInteractiveSimulation();
  void emitSendAddMonitoredItem(int nodeId, QString plotVariable) {emit sendAddMonitoredItem(nodeId, plotVariable);}
  void emitSendRemoveMonitoredItem(QString name) {emit sendRemoveMonitoredItem(name);}
private slots:
  void setSpeed(QString value);
protected:
  void sample();
private:
  void appendVariableValues();
  void setInterval(double interval);
  QPair<double, double> mMinMaxValues;
  OpcUaClient *mpParentClient;
  VariablesTreeItem *mpVariablesTreeItemRoot;
  QTime mClock;
  bool mSimulateWithSteps;
  const double mSampleInterval;
  double mInterval, mSpeedValue, mServerSampleInterval;
  bool mIsRunning;

  void createSubscription();
  void monitorTime();
  static void timeChanged(UA_UInt32 handle, UA_DataValue *pValue, void *pClient);
  static void realChanged(UA_UInt32 handle, UA_DataValue *pValue, void *pClient);
  static void boolChanged(UA_UInt32 handle, UA_DataValue *pValue, void *pClient);
  void insertValues();
  static QThreadStorage<QMap<UA_UInt32, Variable*>> mMonitorIds;
  static QThreadStorage<QMap<UA_UInt32, double>> mCurrentValues;
  static QThreadStorage<double> mCurrentTime;
  static QThreadStorage<int> mInt;
  UA_UInt32 mSubscriptionId;
signals:
  void sendUpdateCurves();
  void sendUpdateYAxis(double, double);
  void sendAddMonitoredItem(int, QString);
  void sendRemoveMonitoredItem(QString);
};

class Variable : public QwtSeriesData<QPointF>
{
public:
  Variable(int id, bool isWritable);
  ~Variable();

  QVector<double> *getXAxisData() {return mXAxisVector;}
  QVector<double> *getYAxisData() {return mYAxisVector;}
  int getNodeId() {return mNodeId;}
  bool isWritable() {return mIsWritable;}
  void insertData(const double& xValue, const double& yValue);
  void setAxisVectors(QPair<QVector<double>*, QVector<double>*> axes);
  void setXBounds(const double &startBound, const double &stopBound);
  void setYBounds(const double &mixValue, const double &maxValue);
  virtual QPointF sample( size_t i ) const;
  virtual size_t size() const;
  virtual QRectF boundingRect() const;
  void checkBounds(const double &value);
  void setMonitoredItemId(UA_UInt32 value) {mMonitordItemId = value;}
  UA_UInt32 getMonitoredItemId() {return mMonitordItemId;}
  void setIsBool(bool isBool) {mIsBool = isBool;}
  bool isBool() {return mIsBool;}
private:
  QPair<double, double> minMaxBounds;
  QVector<double> *mXAxisVector;
  QVector<double> *mYAxisVector;
  QRectF mCurveBounds;
  int mNodeId;
  UA_UInt32 mMonitordItemId;
  bool mIsWritable;
  bool mIsBool;
};

#endif // OPCUACLIENT_H
