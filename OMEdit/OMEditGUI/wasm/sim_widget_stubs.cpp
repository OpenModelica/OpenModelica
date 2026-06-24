// No-op bodies for the excluded sim/OMS-sim output widgets' moc-referenced
// methods (their .cpp are QProcess-driven and excluded, but the headers are still
// moc'd). Never run on wasm: the ctors are guarded out at the call sites. No ctor
// is defined here so the vtable isn't emitted in this TU.

#include "Simulation/SimulationOutputWidget.h"
#include "OMS/OMSSimulationOutputWidget.h"

// ---- SimulationOutputTree ----
int SimulationOutputTree::getDepth(const QModelIndex &) const { return 0; }
void SimulationOutputTree::showContextMenu(QPoint) {}
void SimulationOutputTree::callLayoutChanged(int, int, int) {}
void SimulationOutputTree::selectAllMessages() {}
void SimulationOutputTree::copyMessages() {}

// ---- SimulationOutputWidget ----
void SimulationOutputWidget::start() {}
void SimulationOutputWidget::reSimulate(bool) {}
void SimulationOutputWidget::socketDisconnected() {}
void SimulationOutputWidget::openSimulationLogFile() {}
void SimulationOutputWidget::readSimulationProgress() {}
void SimulationOutputWidget::openTransformationBrowser(QUrl) {}
void SimulationOutputWidget::openTransformationalDebugger() {}
void SimulationOutputWidget::cancelCompilationOrSimulation() {}
void SimulationOutputWidget::createSimulationProgressSocket() {}

// ---- OMSSimulationOutputWidget ----
void OMSSimulationOutputWidget::writeSimulationOutput(const QString &, StringHandler::SimulationMessageType) {}
void OMSSimulationOutputWidget::simulationDataPublished(const QByteArray &) {}
void OMSSimulationOutputWidget::simulationReply(const QByteArray &, const QString &, const QString &) {}
void OMSSimulationOutputWidget::simulationProcessStarted() {}
void OMSSimulationOutputWidget::readSimulationStandardOutput() {}
void OMSSimulationOutputWidget::readSimulationStandardError() {}
void OMSSimulationOutputWidget::cancelSimulation() {}
void OMSSimulationOutputWidget::pauseSimulation() {}
void OMSSimulationOutputWidget::continueSimulation() {}
void OMSSimulationOutputWidget::endSimulation() {}
