#include "OpcUaClient.h"

#include "MainWindow.h"
#include "Plotting/PlotWindowContainer.h"
#include "Plotting/VariablesWidget.h"

#include <QThread>
#include <QDebug>

/*!
  Write the value value to the real node with id id.
  */
static bool writeReal(UA_Client *client, UA_NodeId id, UA_Double value)
{
  UA_WriteRequest wReq;
  UA_WriteRequest_init(&wReq);
  wReq.nodesToWrite = UA_WriteValue_new();
  wReq.nodesToWriteSize = 1;
  wReq.nodesToWrite[0].nodeId = id;
  wReq.nodesToWrite[0].attributeId = UA_ATTRIBUTEID_VALUE;
  wReq.nodesToWrite[0].value.hasValue = UA_TRUE;
  wReq.nodesToWrite[0].value.value.type = &UA_TYPES[UA_TYPES_DOUBLE];
  wReq.nodesToWrite[0].value.value.storageType = UA_VARIANT_DATA_NODELETE;
  wReq.nodesToWrite[0].value.value.data = &value;

  UA_WriteResponse wResp = UA_Client_Service_write(client, wReq);
  if (wResp.responseHeader.serviceResult != UA_STATUSCODE_GOOD) {
    UA_WriteRequest_deleteMembers(&wReq);
    UA_WriteResponse_deleteMembers(&wResp);
    return false;
  }
  UA_WriteRequest_deleteMembers(&wReq);
  UA_WriteResponse_deleteMembers(&wResp);

  return true;
}

/*!
  Write the value value to the bool node with id id.
  */
static bool writeBool(UA_Client *client, UA_NodeId id, UA_Boolean value)
{
  UA_WriteRequest wReq;
  UA_WriteRequest_init(&wReq);
  wReq.nodesToWrite = UA_WriteValue_new();
  wReq.nodesToWriteSize = 1;
  wReq.nodesToWrite[0].nodeId = id;
  wReq.nodesToWrite[0].attributeId = UA_ATTRIBUTEID_VALUE;
  wReq.nodesToWrite[0].value.hasValue = UA_TRUE;
  wReq.nodesToWrite[0].value.value.type = &UA_TYPES[UA_TYPES_BOOLEAN];
  wReq.nodesToWrite[0].value.value.storageType = UA_VARIANT_DATA_NODELETE;
  wReq.nodesToWrite[0].value.value.data = &value;

  UA_WriteResponse wResp = UA_Client_Service_write(client, wReq);
  if (wResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD) {
    UA_WriteRequest_deleteMembers(&wReq);
    UA_WriteResponse_deleteMembers(&wResp);
    return true;
  }
  UA_WriteRequest_deleteMembers(&wReq);
  UA_WriteResponse_deleteMembers(&wResp);
  return false;
}


/*!
  Contains OPC UA functionality to interact with an OPC UA server.
  */
OpcUaClient::OpcUaClient(SimulationOptions simulationOptions)
  : mSimulationOptions(simulationOptions)
{
  mpSampleThread = new QThread();
}

OpcUaClient::~OpcUaClient()
{
  mpOpcUaWorker->pauseInteractiveSimulation();

  UA_Client_disconnect(mpClient);
  UA_Client_delete(mpClient);
}

/*!
  Connect to an OPC UA server.
  */
bool OpcUaClient::connectToServer()
{
  std::string endPoint = "opc.tcp://localhost:" + std::to_string(mSimulationOptions.getInteractiveSimulationPortNumber());
  mpClient = UA_Client_new(UA_ClientConfig_standard);
  UA_StatusCode returnValue;
  do {
    Sleep::msleep(100);
    // QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
    returnValue = UA_Client_connect(mpClient, endPoint.c_str());
  } while (returnValue != UA_STATUSCODE_GOOD);
  // qDebug() << "Connected to OPC-UA server " << endPoint;
  return true;
}

/*!
  Browse the server after all the variable names and return them in a QStringList .
  All the variable names are added to the temporary data structure.
  Called one time when the simulation server is ready.
  */
QStringList OpcUaClient::fetchVariableNamesFromServer()
{
  UA_BrowseRequest browseRequest;
  UA_BrowseRequest_init(&browseRequest);
  browseRequest.requestedMaxReferencesPerNode = 0;
  browseRequest.nodesToBrowse = UA_BrowseDescription_new();
  browseRequest.nodesToBrowseSize = 1;
  browseRequest.nodesToBrowse[0].nodeId = UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER); /* browse objects folder */
  browseRequest.nodesToBrowse[0].resultMask = UA_BROWSERESULTMASK_ALL; /* return everything */
  UA_BrowseResponse browseResponse = UA_Client_Service_browse(mpClient, browseRequest);

  QStringList variablesList;
  for (size_t i = 0; i < browseResponse.resultsSize; ++i) {
    for (size_t j = 0; j < browseResponse.results[i].referencesSize; ++j) {
      UA_ReferenceDescription *ref = &(browseResponse.results[i].references[j]);
      if (ref->nodeId.nodeId.identifierType == UA_NODEIDTYPE_NUMERIC) {
        int nodeId = ref->nodeId.nodeId.identifier.numeric;
        QString variableName = QString::fromUtf8((char *)ref->browseName.name.data, ref->browseName.name.length);
        if (!variableName.startsWith("$")) {
          Variable *pVariable = new Variable(nodeId, variableIsWritable(nodeId));
          if (variableIsReal(nodeId)) {
            double variableValue = readReal(nodeId);
            pVariable->checkBounds(variableValue);
            pVariable->setIsBool(false);
            // append the list used in the variable widget
            variablesList << variableName;
          } else if (variableIsBool(nodeId)) {
            int variableValue = readBool(nodeId);
            pVariable->checkBounds(variableValue);
            pVariable->setIsBool(true);
            // append the list used in the variable widget
            variablesList << variableName;
          }
          mVariables.insert(variableName, pVariable);
          // manually set plotting bounds
          pVariable->setXBounds(mSimulationOptions.getStartTime().toDouble(), mSimulationOptions.getStopTime().toDouble());
        }
      }
    }
  }
  UA_BrowseRequest_deleteMembers(&browseRequest);
  UA_BrowseResponse_deleteMembers(&browseResponse);
  return variablesList;
}

/*!
  Called when a variable is checked in the variable tree.
  */
void OpcUaClient::checkVariable(int nodeId, VariablesTreeItem *pVariablesTreeItem)
{
  // item checked, inform the backend
  mCheckedVariables.insert(nodeId, pVariablesTreeItem);
  if (!mSimulationOptions.isInteractiveSimulationWithSteps()) {
    emit mpOpcUaWorker->emitSendAddMonitoredItem(nodeId, pVariablesTreeItem->getPlotVariable());
  }
}

/*!
  Called when a variable is unchecked in the variable tree.
  */
void OpcUaClient::unCheckVariable(int nodeId, const QString &name)
{
  mCheckedVariables.remove(nodeId);
  if (!mSimulationOptions.isInteractiveSimulationWithSteps()) {
    emit mpOpcUaWorker->emitSendRemoveMonitoredItem(name);
  }
}

/*!
  Use the write mask to check if a variable is writable.
  */
bool OpcUaClient::variableIsWritable(int nodeId)
{
  // highlevel client functionality used
  UA_UInt32 isWritable;
  UA_Client_readWriteMaskAttribute(mpClient, UA_NODEID_NUMERIC(1, nodeId), &isWritable);
  if (isWritable == 1) {
   return true;
  }
  return false;
}

/*!
  Two kind of datatypes are used in the OPC UA interface. Booleans and reals.
  Check if a variable is of type real.
  */
bool OpcUaClient::variableIsReal(int nodeId)
{
  UA_ReadRequest rReq;
  UA_ReadRequest_init(&rReq);
  rReq.nodesToRead = (UA_ReadValueId*)UA_Array_new(1, &UA_TYPES[UA_TYPES_READVALUEID]);
  rReq.nodesToReadSize = 1;
  rReq.nodesToRead[0].nodeId = UA_NODEID_NUMERIC(1, nodeId);
  rReq.nodesToRead[0].attributeId = UA_ATTRIBUTEID_VALUE;

  UA_ReadResponse rResp = UA_Client_Service_read(mpClient, rReq);
  if (rResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD &&
      rResp.resultsSize > 0 && rResp.results[0].hasValue &&
      UA_Variant_isScalar(&rResp.results[0].value) &&
      rResp.results[0].value.type == &UA_TYPES[UA_TYPES_DOUBLE]) {
    UA_ReadRequest_deleteMembers(&rReq);
    UA_ReadResponse_deleteMembers(&rResp);
    return true;
  }
  UA_ReadRequest_deleteMembers(&rReq);
  UA_ReadResponse_deleteMembers(&rResp);
  return false;
}

/*!
  Check if a variable is of type bool.
  */
bool OpcUaClient::variableIsBool(int nodeId)
{
  UA_ReadRequest rReq;
  UA_ReadRequest_init(&rReq);
  rReq.nodesToRead = (UA_ReadValueId*)UA_Array_new(1, &UA_TYPES[UA_TYPES_READVALUEID]);
  rReq.nodesToReadSize = 1;
  rReq.nodesToRead[0].nodeId = UA_NODEID_NUMERIC(1, nodeId);
  rReq.nodesToRead[0].attributeId = UA_ATTRIBUTEID_VALUE;

  UA_ReadResponse rResp = UA_Client_Service_read(mpClient, rReq);
  if (rResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD &&
      rResp.resultsSize > 0 && rResp.results[0].hasValue &&
      UA_Variant_isScalar(&rResp.results[0].value) &&
      rResp.results[0].value.type == &UA_TYPES[UA_TYPES_BOOLEAN]) {
    UA_ReadRequest_deleteMembers(&rReq);
    UA_ReadResponse_deleteMembers(&rResp);
    return true;
  }
  UA_ReadRequest_deleteMembers(&rReq);
  UA_ReadResponse_deleteMembers(&rResp);
  return false;
}

/*!
  Read the value of a real node with the provided id, return the result.
  */
double OpcUaClient::readReal(int id)
{
  double res = -1;
  UA_ReadRequest rReq;
  UA_ReadRequest_init(&rReq);
  rReq.nodesToRead = (UA_ReadValueId*)UA_Array_new(1, &UA_TYPES[UA_TYPES_READVALUEID]);
  rReq.nodesToReadSize = 1;
  rReq.nodesToRead[0].nodeId = UA_NODEID_NUMERIC(1, id);
  rReq.nodesToRead[0].attributeId = UA_ATTRIBUTEID_VALUE;

  UA_ReadResponse rResp = UA_Client_Service_read(mpClient, rReq);
  if (rResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD &&
          rResp.resultsSize > 0 && rResp.results[0].hasValue &&
          UA_Variant_isScalar(&rResp.results[0].value) &&
          rResp.results[0].value.type == &UA_TYPES[UA_TYPES_DOUBLE]) {
    res = *(UA_Double*)rResp.results[0].value.data;
  }
  UA_ReadRequest_deleteMembers(&rReq);
  UA_ReadResponse_deleteMembers(&rResp);
  return res;
}

/*!
  Read the bool value of the provided id, return the result as an integer.
  -1 indicates an error.
  */
int OpcUaClient::readBool(int id)
{
  int res = -1;
  UA_ReadRequest rReq;
  UA_ReadRequest_init(&rReq);
  rReq.nodesToRead = (UA_ReadValueId*)UA_Array_new(1, &UA_TYPES[UA_TYPES_READVALUEID]);
  rReq.nodesToReadSize = 1;
  rReq.nodesToRead[0].nodeId = UA_NODEID_NUMERIC(1, id);
  rReq.nodesToRead[0].attributeId = UA_ATTRIBUTEID_VALUE;

  UA_ReadResponse rResp = UA_Client_Service_read(mpClient, rReq);
  if(rResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD &&
          rResp.resultsSize > 0 && rResp.results[0].hasValue &&
          UA_Variant_isScalar(&rResp.results[0].value) &&
          rResp.results[0].value.type == &UA_TYPES[UA_TYPES_BOOLEAN]) {
    res = *(UA_Boolean*)rResp.results[0].value.data;
  }
  UA_ReadRequest_deleteMembers(&rReq);
  UA_ReadResponse_deleteMembers(&rResp);
  return res;
}

/*!
  Called when a value is entered in the variable tree.
  Write the new value to the corresponding node.
  */
void OpcUaClient::writeValue(const QVariant &value, const QString &name)
{
  int nodeId = mVariables.value(name)->getNodeId();
  if (variableIsReal(nodeId)) {
    writeReal(mpClient, UA_NODEID_NUMERIC(1, nodeId), value.toDouble());
  } else if (variableIsBool(nodeId)) {
    writeBool(mpClient, UA_NODEID_NUMERIC(1, nodeId), value.toBool());
  }
}

/*!
  Read the current simulation time by contacting the remote with help of open62541 high level functionality.
  */
double OpcUaClient::getCurrentSimulationTime()
{
  UA_Variant *currentTime = UA_Variant_new();
  UA_Client_readValueAttribute(mpClient, UA_NODEID_NUMERIC(0, 10004), currentTime);
  return *(double*)currentTime->data;
}

/*!
  Thread used to fetch data from the OPC UA remote.
  It can be done by using subscriptions or contacting the remote directly each time step (simulate with steps).
  */
OpcUaWorker::OpcUaWorker(OpcUaClient *pClient, bool simulateWithSteps)
 : mpParentClient(pClient), mSimulateWithSteps(simulateWithSteps), mSampleInterval(10), mSpeedValue(1.0), mServerSampleInterval(5)
{
  setInterval(mSampleInterval);
  if (!mSimulateWithSteps) {
    createSubscription();
  }
}

OpcUaWorker::~OpcUaWorker()
{
}

void OpcUaWorker::setInterval(double interval)
{
  mInterval = interval;
}

void OpcUaWorker::startInteractiveSimulation()
{
  mClock.start();
  mIsRunning = true;

  if (!mSimulateWithSteps) {
    writeReal(mpParentClient->getClient(), UA_NODEID_NUMERIC(0, 10002), mSpeedValue);
    writeBool(mpParentClient->getClient(), UA_NODEID_NUMERIC(0, 10001), true);
  }

  while(mIsRunning) {
    const double elapsed = mClock.elapsed();
    sample();

    if (mSimulateWithSteps) {
      if (mInterval > 0.0) {
        const double ms = mInterval - (mClock.elapsed() - elapsed);
        if (ms > 0.0) {
          QTime waitTime= QTime::currentTime().addMSecs(ms);
          while (QTime::currentTime() < waitTime) {
            QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
          }
        }
      }
    } else {
      QCoreApplication::processEvents(QEventLoop::AllEvents, 100);
      Sleep::msleep(mServerSampleInterval);
    }
  }
}

void OpcUaWorker::pauseInteractiveSimulation()
{
  mIsRunning = false;
  if (!mSimulateWithSteps) {
    writeBool(mpParentClient->getClient(), UA_NODEID_NUMERIC(0, 10001), false);
  }
}

/*!
  Called in intervals.
  setInterval(ms) can be usd to adjust the time between each call.
  */
void OpcUaWorker::sample()
{
  // draw selected curve lines
  emit sendUpdateCurves();
  if (mSimulateWithSteps) {
    // append the new values
    appendVariableValues();
    // step the simulation by contacting the remote server
    stepSimulation();
  } else {
    UA_Client_Subscriptions_manuallySendPublishRequest(mpParentClient->getClient());
    insertValues();
  }
}

void OpcUaWorker::setVariablesTreeItemRoot(VariablesTreeItem * pVariablesTreeItemRoot)
{
  mpVariablesTreeItemRoot = pVariablesTreeItemRoot;
}

/*!
 * Adjust the sample interval according to the value entered by the user.
 */
void OpcUaWorker::setSpeed(QString value)
{
  bool isFloat = true;
  double speedValue = value.toFloat(&isFloat);
  if (isFloat && speedValue > 0.0) {
    mSpeedValue = speedValue;
    setInterval(mSampleInterval / speedValue);
  } else if (isFloat && speedValue == 0.0) {
    mSpeedValue = 0.0;
  }
  if (isFloat) {
    writeReal(mpParentClient->getClient(), UA_NODEID_NUMERIC(0, 10002), mSpeedValue);
  }
}

/*!
  Simulate with steps. For each checked variable, contact the remote and fetch the data.
  */
void OpcUaWorker::appendVariableValues()
{
  // fetch checked variables data only
  for (auto & p : mpParentClient->getCheckedVariables()) {
    Variable *pVariable = mpParentClient->getVariables()->value(p->getPlotVariable());
    int nodeId = pVariable->getNodeId();
    double variableValue;
    if (pVariable->isBool()) {
      variableValue = mpParentClient->readBool(nodeId);
    } else {
      variableValue = mpParentClient->readReal(nodeId);
    }

    pVariable->insertData(mpParentClient->getCurrentSimulationTime(), variableValue);
    pVariable->checkBounds(variableValue);
    checkMinMaxValues(variableValue);
  }
}

/*!
  Contact the remote and write true to the step node. Uses high level functionality.
  UA_NODEID_NUMERIC(0, 10000) should probably be using OMC_OPC_NODEID_STEP.
  */
void OpcUaWorker::stepSimulation()
{
  // set the step variable to true
  writeBool(mpParentClient->getClient(), UA_NODEID_NUMERIC(0, 10000), UA_TRUE);
}

/*!
  Called to catch the min max values. The information can be used useful to the plotting window.
  */
void OpcUaWorker::checkMinMaxValues(const double& value)
{
  if (value < mMinMaxValues.first) {
    mMinMaxValues.first = value;
    emit sendUpdateYAxis(mMinMaxValues.first, mMinMaxValues.second);
  } else if ( value > mMinMaxValues.second ) {
    mMinMaxValues.second = value;
    emit sendUpdateYAxis(mMinMaxValues.first, mMinMaxValues.second);
  }
}

/*!
  Create a subscription to the remote.
  */
void OpcUaWorker::createSubscription()
{
  UA_SubscriptionSettings subscriptionSettings = UA_SubscriptionSettings_standard;
  subscriptionSettings.requestedPublishingInterval = mServerSampleInterval;
  subscriptionSettings.maxNotificationsPerPublish = 4096;
  UA_Client_Subscriptions_new(mpParentClient->getClient(), subscriptionSettings, &mSubscriptionId);
  monitorTime();
}

/*!
  Contact the remote and write true to the step node. Uses high level functionality.
  UA_NODEID_NUMERIC(0, 10004) should probably be using OMC_OPC_NODEID_TIME.
  */
void OpcUaWorker::monitorTime()
{
  UA_UInt32 monitorId = 1;
  UA_NodeId time = UA_NODEID_NUMERIC(0, 10004);
  if (UA_STATUSCODE_GOOD != UA_Client_Subscriptions_addMonitoredItem(mpParentClient->getClient(), mSubscriptionId, time, UA_ATTRIBUTEID_VALUE,
                                           &timeChanged, mpParentClient->getClient(), &monitorId)) {
    qDebug() << "Monitor time failed";
  }
}

/*!
  Subscriptions make use of c style code. QThreadStorage will be used as a cache for
  subscription values. Values will be stored in the calling thread's memory stack.
  */
QThreadStorage<double> OpcUaWorker::mCurrentTime;
QThreadStorage<QMap<UA_UInt32, Variable*>> OpcUaWorker::mMonitorIds;
QThreadStorage<QMap<UA_UInt32, double>> OpcUaWorker::mCurrentValues;

/*!
  A time step has been taken. Cache the value and make another step.
  */
void OpcUaWorker::timeChanged(UA_UInt32 handle, UA_DataValue *pValue, void *pClient)
{
  Q_UNUSED(handle);
  if (pValue->hasValue) {
    // catch the time value
    mCurrentTime.setLocalData(*(UA_Double*)pValue->value.data);
  }
  /* if (mSimulateWithSteps) */ {
    writeBool((UA_Client*) pClient, UA_NODEID_NUMERIC(0, 10000), UA_TRUE);
  }
}

/*!
  Inserts the data to the Variable data structure.
  */
void OpcUaWorker::insertValues()
{
  for (const auto &p : mMonitorIds.localData()) {
    double value = mCurrentValues.localData().value(mMonitorIds.localData().key(p));
    p->insertData(mCurrentTime.localData(), value);
    checkMinMaxValues(value);
  }
}

/*!
  A boolean value has been changed.
  Update the cached value and check bounds for the new value.
  */
void OpcUaWorker::boolChanged(UA_UInt32 handle, UA_DataValue *pValue, void *pClient)
{
  Q_UNUSED(pClient);
  if (pValue->hasValue) {
    // remember the value until next time the server notify a change
    double variableValue = *(UA_Boolean*)pValue->value.data;
    mCurrentValues.localData().insert(handle, variableValue);
    mMonitorIds.localData().value(handle)->checkBounds(variableValue);
  }
}

/*!
  A real value has been changed.
  Update the cached value and check bounds for the new value.
  */
void OpcUaWorker::realChanged(UA_UInt32 handle, UA_DataValue *pValue, void *pClient)
{
  Q_UNUSED(pClient);
  if (pValue->hasValue) {
    // remember the value until next time the server notify a change
    double variableValue = *(UA_Double*)pValue->value.data;
    mCurrentValues.localData().insert(handle, variableValue);
    mMonitorIds.localData().value(handle)->checkBounds(variableValue);
  }
}

/*!
  This slot is called when a variable is checked in subscription mode.
  Start to monitor the variable.
  */
void OpcUaWorker::addMonitoredItem(int nodeId, const QString &variableName)
{
  UA_UInt32 monitorId = 1;
  UA_NodeId monitoredItem = UA_NODEID_NUMERIC(1, nodeId);

  Variable *pVariable = mpParentClient->getVariables()->value(variableName);
  if (pVariable->isBool()) {
    UA_Client_Subscriptions_addMonitoredItem(mpParentClient->getClient(), mSubscriptionId, monitoredItem, UA_ATTRIBUTEID_VALUE,
                                             &boolChanged, mpParentClient->getClient(), &monitorId);
  } else {
    UA_Client_Subscriptions_addMonitoredItem(mpParentClient->getClient(), mSubscriptionId, monitoredItem, UA_ATTRIBUTEID_VALUE,
                                           &realChanged, mpParentClient->getClient(), &monitorId);
  }
  pVariable->setMonitoredItemId(monitorId);
  mMonitorIds.localData().insert(monitorId, pVariable);
}

/*!
  This slot is called when a variable is unchecked in subscription mode.
  Remove it from the monitored items.
  */
void OpcUaWorker::removeMonitoredItem(const QString& variableName)
{
  Variable *pVariable = mpParentClient->getVariables()->value(variableName);
  UA_Client_Subscriptions_removeMonitoredItem(mpParentClient->getClient(), mSubscriptionId, pVariable->getMonitoredItemId());
  mMonitorIds.localData().remove(pVariable->getMonitoredItemId());
}

/*!
  Data structure to handle data between the OPC UA server and OMPlot.
  */
Variable::Variable(int id, bool isWritable)
{
  // starting bounds
  mCurveBounds.setRect(0.0, 0.0, -2.0, 1.0);
  mNodeId = id;
  mIsWritable = isWritable;
  mXAxisVector = 0;
  mYAxisVector = 0;
}

Variable::~Variable() {}

/*!
  Determines where the data is to be stored.
  */
void Variable::setAxisVectors(QPair<QVector<double>*, QVector<double>*> axes)
{
  mXAxisVector = axes.first;
  mYAxisVector = axes.second;
}

/*!
  Inserts new data in the vectors.
  */
void Variable::insertData(const double& xValue, const double& yValue)
{
  if (mXAxisVector != 0 && mYAxisVector != 0)
  {
    mXAxisVector->push_back(xValue);
    mYAxisVector->push_back(yValue);
  }
}

/*!
  Returns a QPointF of the values at position i.
  */
QPointF Variable::sample(size_t i) const
{
  return QPointF(mXAxisVector->at(i), mYAxisVector->at(i));
}

/*!
  Returns the number of points currently held.
  */
size_t Variable::size() const
{
  return mXAxisVector->size();
}

/*!
  Returns the bounding rectangle.
  */
QRectF Variable::boundingRect() const
{
  return mCurveBounds;
}

/*!
  Sets the y bounds of the bounding rectangle.
  */
void Variable::setYBounds(const double &minValue, const double &maxValue)
{
  // not very intuitive, look after how qrectf works.
  mCurveBounds.setBottom(maxValue);
  mCurveBounds.setTop(minValue);
}

/*!
  Sets the x bounds of the bounding rectangle.
  */
void Variable::setXBounds(const double &startBound, const double &stopBound)
{
  mCurveBounds.setLeft(startBound);
  mCurveBounds.setRight(stopBound);
}

/*!
  Checks the current bounds and updates them if suitable.
  */
void Variable::checkBounds(const double &value)
{
  if (value > minMaxBounds.second) {
    minMaxBounds.second = value;
    mCurveBounds.setBottom(value);
  } else if (value < minMaxBounds.first) {
    minMaxBounds.first = value;
    mCurveBounds.setTop(value);
  }
}
