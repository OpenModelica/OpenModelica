/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

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
