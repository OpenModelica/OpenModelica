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
 * \brief waitAndCheckSimulation
 * Spins the Qt event loop until all simulation processes tracked by \a output
 * have finished, then inspects their exit codes.
 *
 * The function handles two phases:
 * \list
 *   \li Phase 1 – compilation (and post-compilation linking).  Skipped when
 *       \a checkCompilation is \c false (re-simulation has no compilation step).
 *   \li Phase 2 – the actual simulation executable.  A brief gap exists between
 *       the compilation finishing and the simulation process being launched;
 *       the loop spins until the process handle becomes non-null before checking
 *       the exit code.
 * \endlist
 * \param output The SimulationOutputWidget that owns the running processes.
 * \param checkCompilation Pass \c true for a full simulate run, \c false for resimulate.
 * \return An error string describing the failure, or an empty string on success.
 */
static QString waitAndCheckSimulation(SimulationOutputWidget *output, bool checkCompilation)
{
    // Phase 1: wait for compilation (and post-compilation linking) to finish.
    while (output->isCompilationProcessRunning() || output->isPostCompilationProcessRunning()) {
        QCoreApplication::processEvents();
    }
    QCoreApplication::processEvents();

    if (checkCompilation) {
        QProcess *compilationProc = output->getCompilationProcess();
        if (!compilationProc || compilationProc->exitCode() != 0) {
            return QString("Compilation failed (exit code %1):\n%2")
                .arg(compilationProc ? compilationProc->exitCode() : -1)
                .arg(output->getCompilationOutput());
        }
    }

    // Phase 2: wait for simulation to start, then finish.
    // There is a brief gap between compilation finishing and the simulation process
    // being launched — during that gap all isXxxRunning() flags are false, so we
    // must not check exit codes yet.  We spin until the simulation process is running
    // or has already finished (non-null process pointer).
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
 * \brief MCPServer::handleSimulationTool
 * Dispatches MCP tool calls related to simulation and plotting.
 *
 * Handled tools:
 * \list
 *   \li \c getSimulationResultVariables – returns all variables (optionally
 *       filtered) from the simulation result tree for a given class.
 *   \li \c resimulate – updates editable parameter values in the result tree
 *       and re-runs the simulation without recompiling.
 *   \li \c simulate – compiles and runs a full simulation for the given class,
 *       temporarily suppressing the "save before simulation" prompt.
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
        // Temporarily disable "save before simulation" so MCP can simulate unsaved models
        QCheckBox *pSaveCheckBox = OptionsDialog::instance()->getSimulationPage()->getSaveClassBeforeSimulationCheckBox();
        bool savedChecked = pSaveCheckBox->isChecked();
        pSaveCheckBox->setChecked(false);
        mainWindow->simulate(pLibraryTreeItem);
        pSaveCheckBox->setChecked(savedChecked);
        QCoreApplication::processEvents();
        SimulationOutputWidget *simulationOutput = MessagesWidget::instance()->getSimulationOutputWidget(className);
        if (!simulationOutput) {
            return makeMCPError(id, QString("Simulation output not found for model: %1").arg(className));
        }
        QString error = waitAndCheckSimulation(simulationOutput, true);
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
