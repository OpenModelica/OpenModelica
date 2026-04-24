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

#include <QtGlobal>
#include "MCPServer.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 4, 0) && __has_include(<QtHttpServer>)

#include "MCPServerPrivate.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Plotting/VariablesWidget.h"
#include "Simulation/SimulationOutputWidget.h"
#include "Options/OptionsDialog.h"
#include "OMPlot.h"
#include "qwt_plot_renderer.h"
#include "PlotWindow.h"
#include <QSettings>
#include <QFile>
#include <QJsonDocument>

// ──────────────────────────────────────────────────────────────
// File-local helpers
// ──────────────────────────────────────────────────────────────

static const QJsonObject notifyToolsImageWasReturned =
    makeContent("Returned the image. If you cannot see it, use a different tool as you do not have vision capabilities.");

/*!
 * \brief getSimulationResultVariablesRecursive
 * Recursively walks the variables tree rooted at \a item and appends every
 * variable that matches \a filter to \a result.  Each entry is a JSON object
 * with keys \c value, \c unit and \c editable.
 * \param item The root tree item to start the traversal from.
 * \param result JSON object that receives the collected variable entries.
 * \param filter Regular-expression string used to filter variable names.
 * \param onlyEditable When true only editable (parameter) variables are included.
 */
static void getSimulationResultVariablesRecursive(VariablesTreeItem *item, QJsonObject &result, const QString &filter, bool onlyEditable) {
    QRegularExpression re(filter);
    if ((item->isEditable() || item->getExistInResultFile()) && re.match(item->getPlotVariable()).hasMatch()) {
        QJsonObject variable;
        variable.insert("value", item->getValue(item->getDisplayUnit(), item->getUnit()).toString());
        variable.insert("unit", item->getUnit());
        variable.insert("editable", item->isEditable());
        result.insert(item->getPlotVariable(), variable);
    }
    for (VariablesTreeItem *child : item->mChildren) {
        getSimulationResultVariablesRecursive(child, result, filter, onlyEditable);
    }
}

/*!
 * \brief getPlotImage
 * Renders the Qwt plot contained in \a pPlotWindow into an in-memory image
 * with a white background.
 * \param pPlotWindow The plot window whose contents are to be rendered.
 * \return A QImage containing the rendered plot.
 */
static QImage getPlotImage(OMPlot::PlotWindow *pPlotWindow) {
    QwtPlotRenderer plotRenderer;
    QwtPlot *plot = pPlotWindow->getPlot();
    plotRenderer.setDiscardFlag(QwtPlotRenderer::DiscardBackground);
    QImage plotImage(plot->size(), QImage::Format_ARGB32_Premultiplied);
    plotImage.fill(Qt::white);
    QPainter painter;
    painter.begin(&plotImage);
    QRect rect = plot->geometry();
    painter.setWindow(rect);
    plotRenderer.render(plot, &painter, rect);
    painter.end();
    return plotImage;
}

// ──────────────────────────────────────────────────────────────
// MCPServer member implementations
// ──────────────────────────────────────────────────────────────

/*!
 * \brief waitAndCheckCompilation
 * Spins the Qt event loop until the compilation (and any post-compilation
 * linking) tracked by \a output has finished, then checks the exit code.
 * \param output The SimulationOutputWidget that owns the compilation process.
 * \return An error string on failure, or an empty string on success.
 */
static QString waitAndCheckCompilation(SimulationOutputWidget *output)
{
    QCoreApplication::processEvents(); // Important: the flag is set in a slot, so we must process events to observe it.
    while (output->isCompilationProcessRunning() || output->isPostCompilationProcessRunning()) {
        QCoreApplication::processEvents();
    }
    QCoreApplication::processEvents();

    QProcess *compilationProc = output->getCompilationProcess();
    if (!compilationProc || compilationProc->exitCode() != 0) {
        return QString("Compilation failed (exit code %1):\n%2")
            .arg(compilationProc ? compilationProc->exitCode() : -1)
            .arg(output->getCompilationOutput());
    }
    return QString();
}

/*!
 * \brief waitAndCheckSimulationRun
 * Spins the Qt event loop until the simulation executable tracked by \a output
 * has started and finished, then checks the exit code.
 *
 * There is a brief gap between compilation finishing and the simulation process
 * being launched — during that gap all \c isXxxRunning() flags are false, so we
 * must not check exit codes yet.  We spin until the process handle becomes
 * non-null before inspecting it.
 * \param output The SimulationOutputWidget that owns the simulation process.
 * \return An error string on failure, or an empty string on success.
 */
static QString waitAndCheckSimulationRun(SimulationOutputWidget *output)
{
    QCoreApplication::processEvents(); // Important: the flag is set in a slot, so we must process events to observe it.
    while (!output->isSimulationProcessRunning() && !output->getSimulationProcess()) {
        QCoreApplication::processEvents();
    }
    while (output->isSimulationProcessRunning()) {
        QCoreApplication::processEvents();
    }
    QCoreApplication::processEvents();

    QProcess *simulationProc = output->getSimulationProcess();
    if (!simulationProc || simulationProc->exitCode() != 0) {
        QString log = output->getSimulationStandardOutput();
        QString err = output->getSimulationStandardError();
        if (!err.isEmpty()) {
            log += "\n" + err;
        }
        return QString("Simulation failed (exit code %1):\n%2")
            .arg(simulationProc ? simulationProc->exitCode() : -1)
            .arg(log);
    }
    return QString();
}

/*!
 * \brief waitAndCheckSimulation
 * Convenience wrapper that runs both the compilation phase and the simulation
 * run phase in sequence.
 *
 * \param output The SimulationOutputWidget that owns the running processes.
 * \param checkCompilation Pass \c true for a full simulate run (has a
 *        compilation phase); pass \c false for resimulate (no compilation step).
 * \return An error string describing the failure, or an empty string on success.
 */
static QString waitAndCheckSimulation(SimulationOutputWidget *output, bool checkCompilation)
{
    if (checkCompilation) {
        QString err = waitAndCheckCompilation(output);
        if (!err.isEmpty()) return err;
    }
    return waitAndCheckSimulationRun(output);
}

/*!
 * \brief checkExternalFunctions
 * Reads the \c {outputFileName}_external_functions.json file produced by the
 * compiler and verifies that every external C function it lists is present in
 * the MCP whitelist stored in QSettings under the key
 * \c MCP/allowedExternalFunctions.
 *
 * The whitelist is a QStringList.  An absent or empty whitelist means no
 * external functions are allowed.  A missing JSON file (model has no external
 * functions) is treated as clean.
 *
 * \param simOpts SimulationOptions from the completed build-only run, used to
 *        locate the JSON file via \c getWorkingDirectory() and
 *        \c getOutputFileName().
 * \return An error string naming the first forbidden function, or an empty
 *         string if all external functions are whitelisted (or none exist).
 */
static QString checkExternalFunctions(const SimulationOptions &simOpts)
{
    QString jsonPath = simOpts.getWorkingDirectory() + "/" + simOpts.getOutputFileName() + "_external_functions.json";
    QFile jsonFile(jsonPath);
    if (!jsonFile.exists() || !jsonFile.open(QIODevice::ReadOnly)) {
        return QString("Could not read external functions file: %1").arg(jsonPath);
    }
    QJsonDocument doc = QJsonDocument::fromJson(jsonFile.readAll());
    jsonFile.close();
    if (!doc.isArray()) {
        return QString("External functions file is not a valid JSON array: %1").arg(jsonPath);
    }
    QJsonArray externalFunctions = doc.array();

    QSettings *pSettings = Utilities::getApplicationSettings();
    QStringList whitelist = pSettings->value("modelContextProtocol/allowedExternalFunctions").toStringList();
    if (!pSettings->contains("modelContextProtocol/defaultAllowedExternalFunctions") || pSettings->value("modelContextProtocol/defaultAllowedExternalFunctions").toBool()) {
        // Append the default allowed functions to the whitelist, unless the user has explicitly disabled that.
        const QStringList defaultAllowedExternalFunctions = {
          "ModelicaFFT_kiss_fftr",
          "ModelicaIO_readMatrixSizes",
          "ModelicaIO_readRealMatrix",
          "ModelicaInternal_chdir",
          "ModelicaInternal_countLines",
          "ModelicaInternal_fullPathName",
          "ModelicaInternal_getNumberOfFiles",
          "ModelicaInternal_getTime",
          "ModelicaInternal_getcwd",
          "ModelicaInternal_getenv",
          "ModelicaInternal_getpid",
          "ModelicaInternal_print",
          "ModelicaInternal_readDirectory",
          "ModelicaInternal_readFile",
          "ModelicaInternal_readLine",
          "ModelicaInternal_setenv",
          "ModelicaInternal_stat",
          "ModelicaRandom_automaticGlobalSeed",
          "ModelicaRandom_impureRandom_xorshift1024star",
          "ModelicaRandom_setInternalState_xorshift1024star",
          "ModelicaRandom_xorshift1024star",
          "ModelicaRandom_xorshift128plus",
          "ModelicaRandom_xorshift64star",
          "ModelicaStandardTables_CombiTable1D_close",
          "ModelicaStandardTables_CombiTable1D_getDer2Value",
          "ModelicaStandardTables_CombiTable1D_getDerValue",
          "ModelicaStandardTables_CombiTable1D_getDerValue",
          "ModelicaStandardTables_CombiTable1D_getValue",
          "ModelicaStandardTables_CombiTable1D_getValue",
          "ModelicaStandardTables_CombiTable1D_getValue",
          "ModelicaStandardTables_CombiTable1D_init3",
          "ModelicaStandardTables_CombiTable1D_maximumAbscissa",
          "ModelicaStandardTables_CombiTable1D_minimumAbscissa",
          "ModelicaStandardTables_CombiTable2D_close",
          "ModelicaStandardTables_CombiTable2D_getDer2Value",
          "ModelicaStandardTables_CombiTable2D_getDerValue",
          "ModelicaStandardTables_CombiTable2D_getDerValue",
          "ModelicaStandardTables_CombiTable2D_getValue",
          "ModelicaStandardTables_CombiTable2D_getValue",
          "ModelicaStandardTables_CombiTable2D_getValue",
          "ModelicaStandardTables_CombiTable2D_init3",
          "ModelicaStandardTables_CombiTable2D_maximumAbscissa",
          "ModelicaStandardTables_CombiTable2D_minimumAbscissa",
          "ModelicaStandardTables_CombiTimeTable_close",
          "ModelicaStandardTables_CombiTimeTable_getDer2Value",
          "ModelicaStandardTables_CombiTimeTable_getDerValue",
          "ModelicaStandardTables_CombiTimeTable_getDerValue",
          "ModelicaStandardTables_CombiTimeTable_getValue",
          "ModelicaStandardTables_CombiTimeTable_getValue",
          "ModelicaStandardTables_CombiTimeTable_getValue",
          "ModelicaStandardTables_CombiTimeTable_init3",
          "ModelicaStandardTables_CombiTimeTable_maximumTime",
          "ModelicaStandardTables_CombiTimeTable_minimumTime",
          "ModelicaStandardTables_CombiTimeTable_nextTimeEvent",
          "ModelicaStreams_closeFile",
          "ModelicaStrings_compare",
          "ModelicaStrings_hashString",
          "ModelicaStrings_length",
          "ModelicaStrings_scanIdentifier",
          "ModelicaStrings_scanInteger",
          "ModelicaStrings_scanReal",
          "ModelicaStrings_scanString",
          "ModelicaStrings_skipWhiteSpace",
          "ModelicaStrings_substring",
          "exit",
          "ModelicaInternal_temporaryFileName"
        };
        // Not allowed by default (user can override this):
        // ModelicaIO_writeRealMatrix, ModelicaInternal_copyFile, ModelicaInternal_mkdir, ModelicaInternal_removeFile
        // ModelicaInternal_rename, ModelicaInternal_rmdir, system
        whitelist.append(defaultAllowedExternalFunctions);
    }
    QStringList forbiddenFunctions;

    for (const QJsonValue &fn : externalFunctions) {
        QString fnName = fn.toString();
        if (!whitelist.contains(fnName)) {
            forbiddenFunctions.append(fnName);
        }
    }
    if (!forbiddenFunctions.isEmpty()) {
        return QString("Model uses external functions %1 which are not in the MCP allowed list (modelContextProtocol/allowedExternalFunctions).").arg(forbiddenFunctions.join(", "));
    }
    return QString();
}

/*!
 * \brief MCPServer::handleSimulationTool
 * Dispatches MCP tool calls related to simulation and plotting.
 *
 * Handled tools:
 * \list
 *   \li \c getSimulationResultVariables – returns all variables (optionally
 *       filtered) from the simulation result tree for a given class.
 *   \li \c resimulate – updates editable parameter values in the result tree
 *       and re-runs the simulation without recompiling.
 *   \li \c simulate – compiles and runs a full simulation for the given class.
 *       Uses a two-phase approach: first a build-only compile to check external
 *       C functions against the MCP whitelist (QSettings key
 *       \c MCP/allowedExternalFunctions), then the full compile+run if the
 *       check passes.  The simulation executable is never launched if forbidden
 *       external functions are detected.
 *   \li \c plot – plots a set of variables from the simulation result; returns
 *       an image when \a vision is \c true, or raw time-series data from the
 *       .mat result file when \a vision is \c false.
 *   \li \c showPlot – captures the currently active plot window as an image
 *       (\a vision mode) or notifies the caller that vision is unavailable.
 * \endlist
 * \param toolName Name of the MCP tool to execute.
 * \param id       JSON-RPC request id echoed back in the response.
 * \param arguments Tool arguments as a JSON object.
 * \param vision   Whether the client supports receiving images.
 * \return A QHttpServerResponse containing the MCP tool result or error.
 */
QHttpServerResponse MCPServer::handleSimulationTool(const QString &toolName, QJsonValue id, QJsonObject arguments, bool vision)
{
    if (toolName == "getSimulationResultVariables") {
        MainWindow *mainWindow = MainWindow::instance();
        QString className = arguments.value("className").toString(); // required
        bool onlyEditable = true;
        QString filter;
        if (arguments.contains("onlyEditable") && !arguments.value("onlyEditable").toBool()) {
            onlyEditable = false;
        }
        if (arguments.contains("filter")) {
            filter = arguments.value("filter").toString();
        }
        VariablesWidget *pVariablesWidget = mainWindow->getVariablesWidget();
        VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
        VariablesTreeItem *foundResultFile = pVariablesTreeModel->findVariablesTreeItemFromClassNameTopLevel(className);
        if (!foundResultFile) {
            return makeMCPError(id, QString("No simulation results found for model: %1").arg(className));
        }
        QJsonObject tunableVariables;
        getSimulationResultVariablesRecursive(foundResultFile, tunableVariables, filter, onlyEditable);
        return makeMCPToolResponse(id, makeContent(tunableVariables));
    }
    if (toolName == "resimulate") {
        MainWindow *mainWindow = MainWindow::instance();
        QString className = arguments.value("className").toString(); // required
        VariablesWidget *pVariablesWidget = mainWindow->getVariablesWidget();
        VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
        VariablesTreeItem *foundResultFile = pVariablesTreeModel->findVariablesTreeItemFromClassNameTopLevel(className);
        if (!foundResultFile) {
            return makeMCPError(id, QString("No simulation results found for model: %1").arg(className));
        }
        QJsonObject variables = arguments.value("variables").toObject();
        for (const auto &plotName : variables.keys()) {
            QString varName = foundResultFile->getFileName()+"."+plotName;
            VariablesTreeItem *foundVariable = pVariablesTreeModel->findVariablesTreeItem(varName, foundResultFile);
            if (!foundVariable) {
                return makeMCPError(id, QString("Variable not found in simulation results: %1").arg(plotName));
            }
            if (!foundVariable->isEditable()) {
                return makeMCPError(id, QString("Variable is not editable during resimulation: %1. Use the getSimulationResultVariables tool call to see which variables can be edited (which ones can be unexpected, for example if a parameter is calculated from another).").arg(plotName));
            }
            QModelIndex index = pVariablesTreeModel->variablesTreeItemIndex(foundVariable, 1 /* value */);
            pVariablesTreeModel->setData(index, variables.value(plotName).toVariant(), Qt::EditRole);
        }
        pVariablesWidget->reSimulate(foundResultFile->getSimulationOptions(), foundResultFile, false);
        QCoreApplication::processEvents();
        SimulationOutputWidget *simulationOutput = MessagesWidget::instance()->getSimulationOutputWidget(className);
        if (!simulationOutput) {
            return makeMCPError(id, QString("Simulation output not found for model: %1").arg(className));
        }
        QString error = waitAndCheckSimulation(simulationOutput, false);
        if (!error.isEmpty()) {
            return makeMCPError(id, QString("Resimulation of %1: %2").arg(className, error));
        }
        return makeMCPToolResponse(id, makeContent("Resimulation successful"));
    }
    if (toolName == "simulate") {
        MainWindow *mainWindow = MainWindow::instance();
        QString className = arguments.value("className").toString(); // required
        LibraryTreeItem *pLibraryTreeItem = mainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
        if (!pLibraryTreeItem) {
            return makeMCPError(id, QString("Model not found: %1").arg(className));
        }

        // Guard against concurrent simulate calls.  The waitAndCheckCompilation and
        // waitAndCheckSimulationRun helpers spin with QCoreApplication::processEvents(),
        // which allows the Qt HTTP server to dispatch a second incoming simulate request
        // before the first one has finished.  Two concurrent make(1) processes sharing
        // the same working directory race on the generated C source files and produce
        // spurious build errors (e.g. "PID_Controller_literals.h: No such file").
        static bool simulationInProgress = false;
        if (simulationInProgress) {
            return makeMCPError(id, QString("A simulation is already in progress. "
                                           "Wait for it to finish before calling simulate again."));
        }
        simulationInProgress = true;
        // Use a local struct so the flag is always cleared when this scope exits,
        // whether by return, exception, or fall-through.
        struct SimulationGuard {
            ~SimulationGuard() { simulationInProgress = false; }
        } guard;
        Q_UNUSED(guard)

        // Temporarily disable "save before simulation" so MCP can simulate unsaved models.
        QCheckBox *pSaveCheckBox = OptionsDialog::instance()->getSimulationPage()->getSaveClassBeforeSimulationCheckBox();
        bool savedChecked = pSaveCheckBox->isChecked();
        pSaveCheckBox->setChecked(false);

        // ── Phase 1: build only ────────────────────────────────────────────────
        // Compile the model without launching the simulation executable so that
        // we can inspect the generated external-functions manifest before any
        // untrusted binary ever runs.
        // Close any old (completed) simulation output tabs for this class first so
        // that getSimulationOutputWidget() reliably finds the one we are about to
        // create rather than a stale tab from a previous run.
        MessagesWidget::instance()->closeSimulationOutputWidgets(className);
        QCoreApplication::processEvents();
        mainWindow->simulateBuildOnly(pLibraryTreeItem);
        pSaveCheckBox->setChecked(savedChecked);
        QCoreApplication::processEvents();

        SimulationOutputWidget *buildOutput = MessagesWidget::instance()->getSimulationOutputWidget(className);
        if (!buildOutput) {
            return makeMCPError(id, QString("Translation of %1 failed. Check the Messages window for details.").arg(className));
        }

        // ── Phase 2: external-function whitelist check ─────────────────────────
        // translateModel() (called inside simulateBuildOnly) is synchronous, so the
        // _external_functions.json manifest is already on disk before compilation
        // has had a chance to finish (or to delete any intermediate files).
        QString externalFunctionError = checkExternalFunctions(buildOutput->getSimulationOptions());
        if (!externalFunctionError.isEmpty()) {
            return makeMCPError(id, QString("Simulation of %1 blocked: %2").arg(className, externalFunctionError));
        }

        // ── Phase 3: wait for compilation, then run the executable ────────────
        QString compilationError = waitAndCheckCompilation(buildOutput);
        if (!compilationError.isEmpty()) {
            return makeMCPError(id, QString("Compilation of %1: %2").arg(className, compilationError));
        }

        buildOutput->startSimulationAfterBuild();
        QString error = waitAndCheckSimulationRun(buildOutput);
        if (!error.isEmpty()) {
            return makeMCPError(id, QString("Simulation of %1: %2").arg(className, error));
        }
        return makeMCPToolResponse(id, makeContent(QString("Simulation of %1 finished successfully.").arg(className)));
    }
    if (toolName == "plot" && vision) {
        MainWindow *mainWindow = MainWindow::instance();
        QString className = arguments.value("className").toString(); // required
        VariablesWidget *pVariablesWidget = mainWindow->getVariablesWidget();
        VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
        VariablesTreeItem *foundResultFile = pVariablesTreeModel->findVariablesTreeItemFromClassNameTopLevel(className);
        if (!foundResultFile) {
            return makeMCPError(id, QString("No simulation results found for model: %1").arg(className));
        }
        QList<VariablesTreeItem*> variablesToPlot;
        QJsonArray variables = arguments.value("variables").toArray();
        for (const auto &variable : variables) {
            QString plotName = variable.toString();
            QString varName = foundResultFile->getFileName()+"."+plotName;
            VariablesTreeItem *foundVariable = pVariablesTreeModel->findVariablesTreeItem(varName, foundResultFile);
            if (!foundVariable || !foundVariable->getExistInResultFile()) {
                return makeMCPError(id, QString("Variable not found in simulation results: %1").arg(plotName));
            }
            variablesToPlot.append(foundVariable);
        }
        OMPlot::PlotWindow *pPlotWindow = mainWindow->getPlotWindowContainer()->addPlotWindow();
        if (pPlotWindow == nullptr) {
            return makeMCPError(id, QString("Could not create plot window"));
        }
        for (VariablesTreeItem *variable : variablesToPlot) {
            QModelIndex index = pVariablesTreeModel->variablesTreeItemIndex(variable);
            pVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
        }
        QImage plotImage = getPlotImage(pPlotWindow);
        return makeMCPToolResponse(id, makeContent(plotImage));
    }
    if (toolName == "plot" && !vision) {
        MainWindow *mainWindow = MainWindow::instance();
        QString className = arguments.value("className").toString(); // required
        VariablesWidget *pVariablesWidget = mainWindow->getVariablesWidget();
        VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
        VariablesTreeItem *foundResultFile = pVariablesTreeModel->findVariablesTreeItemFromClassNameTopLevel(className);
        if (!foundResultFile) {
            return makeMCPError(id, QString("No simulation results found for model: %1").arg(className));
        }
        QJsonArray variables = arguments.value("variables").toArray();
        QString fileName = foundResultFile->getFilePath() + "/" + foundResultFile->getFileName();
        if (!fileName.endsWith(".mat")) {
            return makeMCPError(id, QString("Simulation result file is not a .mat file: %1").arg(fileName));
        }
        ModelicaMatReader reader;
        const char *err = omc_new_matlab4_reader(fileName.toUtf8().constData(), &reader);
        if (err || reader.nrows <= 0) {
            return makeMCPError(id, QString("Could not read .mat file %1: %2").arg(fileName).arg(err));
        }
        QJsonObject parameters, vars_result;
        variables.append("time"); // always include time
        for (const auto &variable : variables) {
            QString plotName = variable.toString();
            ModelicaMatVariable_t *var = omc_matlab4_find_var(&reader, plotName.toUtf8().constData());
            if (!var) {
                omc_free_matlab4_reader(&reader);
                return makeMCPError(id, QString("Could not find variable %1 in .mat file %2").arg(plotName).arg(fileName));
            }
            if (var->isParam) {
                // Parameters have a single value in reader.params (1-based index)
                parameters.insert(plotName, reader.params[var->index - 1]);
            } else {
                double *d = omc_matlab4_read_vals(&reader, var->index);
                if (!d) {
                    omc_free_matlab4_reader(&reader);
                    return makeMCPError(id, QString("Could not read variable %1 from .mat file %2").arg(plotName).arg(fileName));
                }
                QJsonArray values;
                for (uint32_t i = 0; i < reader.nrows; i++) {
                    values.append(d[i]);
                }
                vars_result.insert(plotName, values);
            }
        }
        QJsonObject result;
        result.insert("parameters", parameters);
        result.insert("variables", vars_result);
        return makeMCPToolResponse(id, QJsonArray{makeContent(result)});
    }
    if (toolName == "showPlot" && vision) {
        MainWindow *mainWindow = MainWindow::instance();
        OMPlot::PlotWindow *pPlotWindow = mainWindow->getPlotWindowContainer()->getCurrentWindow();
        if (pPlotWindow == nullptr) {
            return makeMCPError(id, QString("No active plot window"));
        }
        QImage plotImage = getPlotImage(pPlotWindow);
        return makeMCPToolResponse(id, makeContent(plotImage));
    }
    if (toolName == "showPlot" && !vision) {
        return makeMCPToolResponse(id, notifyToolsImageWasReturned);
    }
    return makeMCPError(id, QString("Tool not found: %1").arg(toolName));
}

#endif
