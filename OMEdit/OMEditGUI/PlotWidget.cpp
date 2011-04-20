/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

#include "PlotWidget.h"

using namespace OMPlot;

PlotTreeItem::PlotTreeItem(QString text, QString parentName, QString nameStructure, QString fileName, QString tooltip, QTreeWidget *parent)
    : QTreeWidgetItem(parent)
{
    setName(text);
    setParentName(parentName);
    setNameStructure(nameStructure);
    setFileName(fileName);

    setText(0, mName);
    setToolTip(0, tooltip);
}

void PlotTreeItem::setName(QString name)
{
    mName = name;
}

QString PlotTreeItem::getName()
{
    return mName;
}

void PlotTreeItem::setParentName(QString parentName)
{
    mParentName = parentName;
}

QString PlotTreeItem::getParentName()
{
    return mParentName;
}

void PlotTreeItem::setNameStructure(QString nameStructure)
{
    mNameStructure = nameStructure;
}

QString PlotTreeItem::getNameStructure()
{
    return mNameStructure;
}

void PlotTreeItem::setFileName(QString fileName)
{
    mFileName = fileName;
}

QString PlotTreeItem::getFileName()
{
    return mFileName;
}

QString PlotTreeItem::getPlotVariable()
{
    return QString(mNameStructure).remove(0, mFileName.length() + 1);
}

PlotTree::PlotTree(PlotWidget *pParent)
    : QTreeWidget(pParent)
{
    mpParentPlotWidget = pParent;

    setContextMenuPolicy(Qt::DefaultContextMenu);
    setHeaderHidden(true);
    setColumnCount(1);
    setIndentation(Helper::treeIndentation);
    setContextMenuPolicy(Qt::CustomContextMenu);
    setExpandsOnDoubleClick(false);
}

PlotTreeItem* PlotTree::getTreeItem(QString name)
{
    QTreeWidgetItemIterator it(this);
    while (*it)
    {
        PlotTreeItem *pItem = dynamic_cast<PlotTreeItem*>((*it));
        if (pItem->getNameStructure() == name)
        {
            return pItem;
        }
        ++it;
    }
    return 0;
}

PlotWidget* PlotTree::getPlotWidget()
{
    return mpParentPlotWidget;
}

PlotWidget::PlotWidget(MainWindow *pParent)
    : QWidget(pParent)
{
    mpParentMainWindow = pParent;

    mpPlotTree = new PlotTree(this);

    mpVerticalLayout = new QVBoxLayout(this);
    mpVerticalLayout->setContentsMargins(0, 0, 0, 0);
    mpVerticalLayout->addWidget(mpPlotTree);

    createActions();
    setLayout(mpVerticalLayout);

    connect(mpPlotTree, SIGNAL(itemChanged(QTreeWidgetItem*,int)), SLOT(plotVariables(QTreeWidgetItem*,int)));
    connect(mpPlotTree, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
    connect(pParent->mpPlotWindowContainer, SIGNAL(subWindowActivated(QMdiSubWindow*)),
            this, SLOT(updatePlotVariablesTree(QMdiSubWindow*)));
    connect(this, SIGNAL(removePlotFile(PlotTreeItem*)), pParent->mpPlotWindowContainer,
            SLOT(updatePlotWindows(PlotTreeItem*)));
}

void PlotWidget::createActions()
{
    mpDeleteResultAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete Result"), this);
    mpDeleteResultAction->setStatusTip(tr("Delete the result"));
    connect(mpDeleteResultAction, SIGNAL(triggered()), SLOT(deletePlotTreeItem()));
}

QList<QString> PlotWidget::readPlotVariables(QString fileName)
{
    // need to replace \\ to / so that QFile can close the file properly, otherwise we can't open it second time
    QString filePath = QString(Helper::tmpPath.replace("\\", "/")).append("/").append(fileName);

    QFile simulationResultFile(filePath);
    simulationResultFile.open(QIODevice::ReadOnly);

    QList<QString> plotVariablesList;
    QTextStream inStream(&simulationResultFile);
    QTextStream temp(&simulationResultFile);

    inStream.seek(temp.readAll().indexOf("n string variables"));
    // read this line that says n string variables
    inStream.readLine();
    // now read the variables until the end
    while (!inStream.atEnd())
    {
        QString line = inStream.readLine();
        line = line.mid(line.lastIndexOf("//") + 2, (line.length() - 1)).trimmed();
        plotVariablesList.append(line);
    }
    simulationResultFile.close();
    return plotVariablesList;
}

void PlotWidget::addPlotVariablestoTree(QString fileName, QList<QString> plotVariablesList)
{
    mpPlotTree->blockSignals(false);
    // Remove the simulation result if we already had it in tree
    int count = mpPlotTree->topLevelItemCount();

    for (int i = 0 ; i < count ; i++)
    {
        PlotTreeItem *pItem = dynamic_cast<PlotTreeItem*>(mpPlotTree->topLevelItem(i));
        if (pItem->getNameStructure() == fileName)
        {
            emit removePlotFile(pItem);
            qDeleteAll(pItem->takeChildren());
            delete pItem;
            break;
        }
    }

    // insert the top level item in tree
    QString toolTip = QString("Simulation Result File: ").append(fileName).append("\nLocation: ").append(Helper::tmpPath).append("/").append(fileName);
    PlotTreeItem *newTreePost = new PlotTreeItem(fileName, tr(""), fileName, fileName, toolTip, (QTreeWidget*)0);
    mpPlotTree->insertTopLevelItem(0, newTreePost);

    // create two lists from plotVariablesList one contains der's
    QStringList derPlotVariables;
    QStringList derContainer;
    QStringList plotVariables;
    foreach (QString plotVariable, plotVariablesList)
    {
        if (plotVariable.startsWith("der("))
        {
            QString str = plotVariable;
            str.chop((str.lastIndexOf("der(")/4)+1);
            derPlotVariables.append(str.mid(str.lastIndexOf("der(") + 4));
            derContainer.append(plotVariable.left(plotVariable.lastIndexOf("der(") + 4));
        }
        else
            plotVariables.append(plotVariable);
    }

    QString parentStructure;
    // add derPlotVariables to tree
    int j = 0;
    foreach(QString plotVariable, derPlotVariables)
    {
        QStringList variables = plotVariable.split(".");
        parentStructure = newTreePost->getNameStructure();
        for (int i = 0 ; i < variables.size() ; i++)
        {
            // if its the last variable in the list make it der
            if (i == variables.size() - 1)
            {
                QString derPrependString = derContainer.at(j);
                int size = derPrependString.count("der(");
                QString derAppendString;
                derAppendString = QString(derAppendString.toStdString().append(size, ')').c_str());
                QString structure = QString(newTreePost->getNameStructure()).append(".")
                                    .append(derPrependString).append(variables.join(".")).append(derAppendString);
                variables[i].prepend(derPrependString).append(derAppendString);
                // make sure you dont add any node twice
                if (!mpPlotTree->getTreeItem(structure))
                    addPlotVariableToTree(fileName, parentStructure, variables[i], structure, true);
            }
            else
            {
                // make sure you dont add any node twice
                if (!mpPlotTree->getTreeItem(QString(parentStructure).append(".").append(variables[i])))
                    addPlotVariableToTree(fileName, parentStructure, variables[i]);
                parentStructure.append(".").append(variables[i]);
            }
        }
        j++;
    }
    // add plotVariables to tree
    foreach(QString plotVariable, plotVariables)
    {
        QStringList variables = plotVariable.split(".");
        parentStructure = newTreePost->getNameStructure();
        for (int i = 0 ; i < variables.size() ; i++)
        {
            // make sure you dont add any node twice
            if (!mpPlotTree->getTreeItem(QString(parentStructure).append(".").append(variables[i])))
                addPlotVariableToTree(fileName, parentStructure, variables[i]);
            parentStructure.append(".").append(variables[i]);
        }
    }
    // sort items and expand the current plot variables node and collapse all others
    mpPlotTree->setSortingEnabled(true);
    mpPlotTree->sortItems(0, Qt::AscendingOrder);
    // collapse all tree items
    count = mpPlotTree->topLevelItemCount();
    for (int i = 0 ; i < count ; i++)
    {
        mpPlotTree->topLevelItem(i)->setExpanded(false);
    }
    newTreePost->setExpanded(true);
    mpPlotTree->blockSignals(false);
}

void PlotWidget::addPlotVariableToTree(QString fileName, QString parentStructure, QString childName, QString fullStructure, bool derivative)
{
    QString nameStructure;
    if (derivative)
        nameStructure = fullStructure;
    else
        nameStructure = QString(parentStructure).append(".").append(childName);

    PlotTreeItem *parentItem = mpPlotTree->getTreeItem(parentStructure);
    QString toolTip = QString("File: ").append(fileName).append("\nVariable: ").append(childName);
    PlotTreeItem *newTreePost = new PlotTreeItem(childName, parentItem->getName(), nameStructure, fileName, toolTip, (QTreeWidget*)0);
    newTreePost->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
    newTreePost->setCheckState(0, Qt::Unchecked);
    if (parentItem)
    {
        parentItem->addChild(newTreePost);
        if (parentItem->childCount() > 0)
            parentItem->setData(0, Qt::CheckStateRole, QVariant());
    }
}

void PlotWidget::plotVariables(QTreeWidgetItem *item, int column)
{
    if (!item->parent())
        return;

    PlotTreeItem *pItem = dynamic_cast<PlotTreeItem*>(item);

    try
    {
        // get the current window, if no window found simply return
        PlotWindow *pPlotWindow = mpParentMainWindow->mpPlotWindowContainer->getCurrentWindow();
        if (!pPlotWindow)
        {
            mpPlotTree->blockSignals(true);
            pItem->setCheckState(column, Qt::Unchecked);
            mpPlotTree->blockSignals(false);
            mpParentMainWindow->mpMessageWidget->printGUIInfoMessage(tr("No plot window is active for plotting. Please select a plot window or open a new."));
            return;
        }
        // if plottype is PLOT then
        if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
        {
            // check the item checkstate
            if (pItem->checkState(column) == Qt::Checked)
            {
                pPlotWindow->openFile(QString(Helper::tmpPath).append("/").append(pItem->getFileName()));
                pPlotWindow->setVariablesList(QStringList(pItem->getPlotVariable()));
                pPlotWindow->plot();
                pPlotWindow->fitInView();
                pPlotWindow->getPlot()->updateGeometry();
                pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
            }
            // if user unchecks the variable then remove it from the plot
            else if (pItem->checkState(column) == Qt::Unchecked)
            {
                foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
                {
                    QString curveTitle = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text());
                    if (curveTitle.compare(pItem->getNameStructure()) == 0)
                    {
                        pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                        pPlotCurve->detach();
                        pPlotWindow->fitInView();
                        pPlotWindow->getPlot()->updateGeometry();
                        pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
                        break;
                    }
                }
            }
        }
        // if plottype is PLOTPARAMETRIC then
        else
        {
            // check the item checkstate
            if (pItem->checkState(column) == Qt::Checked)
            {
                // if mPlotParametricVariables is empty just add one QStringlist with 1 varibale to it
                if (mPlotParametricVariables.isEmpty())
                {
                    mPlotParametricVariables.append(QStringList(pItem->getPlotVariable()));
                    mFileName = pItem->getFileName();
                }
                // if mPlotParametricVariables is not empty then add one string to its last element
                else
                {
                    if (mPlotParametricVariables.last().size() < 2)
                    {
                        if (mFileName.compare(pItem->getFileName()) != 0)
                        {
                            mpPlotTree->blockSignals(true);
                            pItem->setCheckState(0, Qt::Unchecked);
                            mpParentMainWindow->mpMessageWidget->printGUIInfoMessage(GUIMessages::getMessage(GUIMessages::PLOT_PARAMETRIC_DIFF_FILES));
                            mpPlotTree->blockSignals(false);
                            return;
                        }
                        mPlotParametricVariables.last().append(QStringList(pItem->getPlotVariable()));
                        pPlotWindow->openFile(QString(Helper::tmpPath).append("/").append(pItem->getFileName()));
                        pPlotWindow->setVariablesList(mPlotParametricVariables.last());
                        pPlotWindow->plotParametric();
                        if (mPlotParametricVariables.size() > 1)
                        {
                            pPlotWindow->setXLabel(tr(""));
                            pPlotWindow->setYLabel(tr(""));
                        }
                        pPlotWindow->fitInView();
                        pPlotWindow->getPlot()->updateGeometry();
                        pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
                    }
                    else
                    {
                        mPlotParametricVariables.append(QStringList(pItem->getPlotVariable()));
                        mFileName = pItem->getFileName();
                    }
                }
            }
            // if user unchecks the variable then remove it from the plot
            else if (pItem->checkState(column) == Qt::Unchecked)
            {
                // remove the variable from mPlotParametricVariables list
                foreach (QStringList list, mPlotParametricVariables)
                {
                    if (list.contains(pItem->getPlotVariable()))
                    {
                        // if list has only one variable then clear the list and return;
                        if (list.size() < 2)
                        {
                            mPlotParametricVariables.removeOne(list);
                            break;
                        }
                        // if list has more than two variables then remove both and remove the curve
                        else
                        {
                            QString itemTitle = QString(list.last()).append("(").append(list.first()).append(")");
                            foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
                            {
                                QString curveTitle = pPlotCurve->title().text();
                                if ((curveTitle.compare(itemTitle) == 0) and (pItem->getFileName().compare(pPlotCurve->getFileName()) == 0))
                                {
                                    mpPlotTree->blockSignals(true);
                                    // uncheck the x variable
                                    QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
                                    PlotTreeItem *pTreeItem;
                                    pTreeItem = mpPlotTree->getTreeItem(xVariable);
                                    if (pTreeItem)
                                        pTreeItem->setCheckState(0, Qt::Unchecked);
                                    // uncheck the y variable
                                    QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
                                    pTreeItem = mpPlotTree->getTreeItem(yVariable);
                                    if (pTreeItem)
                                        pTreeItem->setCheckState(0, Qt::Unchecked);
                                    mpPlotTree->blockSignals(false);
                                    pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                                    pPlotCurve->detach();
                                    pPlotWindow->fitInView();
                                    pPlotWindow->getPlot()->updateGeometry();
                                    pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
                                    break;
                                }
                            }
                            mPlotParametricVariables.removeOne(list);
                            if (mPlotParametricVariables.size() == 1)
                            {
                                if (mPlotParametricVariables.last().size() > 1)
                                {
                                    pPlotWindow->setXLabel(mPlotParametricVariables.last().at(0));
                                    pPlotWindow->setYLabel(mPlotParametricVariables.last().at(1));
                                }
                                else
                                {
                                    pPlotWindow->setXLabel(tr(""));
                                    pPlotWindow->setYLabel(tr(""));
                                }
                            }
                            else
                            {
                                pPlotWindow->setXLabel(tr(""));
                                pPlotWindow->setYLabel(tr(""));
                            }
                        }
                    }
                }
            }
        }
    }
    catch (PlotException &e)
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(e.what());
    }
}

void PlotWidget::updatePlotVariablesTree(QMdiSubWindow *window)
{
    if (!window and mpParentMainWindow->mpPlotWindowContainer->subWindowList().size() != 0)
        return;

    // first clear all the check boxes in the tree
    mpPlotTree->blockSignals(true);
    QTreeWidgetItemIterator it(mpPlotTree);
    while (*it)
    {
        if ((*it)->childCount() == 0)
            (*it)->setCheckState(0, Qt::Unchecked);
        ++it;
    }
    mpPlotTree->blockSignals(false);
    // all plotwindows are closed down then simply return
    if (mpParentMainWindow->mpPlotWindowContainer->subWindowList().size() == 0)
        return;

    PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(window->widget());

    // now loop through the curves and tick variables in the tree whose curves are on the plot
    mpPlotTree->blockSignals(true);
    foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
    {
        PlotTreeItem *pTreeItem;
        if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
        {
            pTreeItem = mpPlotTree->getTreeItem(QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text()));
            if (pTreeItem)
                pTreeItem->setCheckState(0, Qt::Checked);
        }
        else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC)
        {
            // check the xvariable
            QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
            pTreeItem = mpPlotTree->getTreeItem(xVariable);
            if (pTreeItem)
                pTreeItem->setCheckState(0, Qt::Checked);
            // check the y variable
            QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
            pTreeItem = mpPlotTree->getTreeItem(yVariable);
            if (pTreeItem)
                pTreeItem->setCheckState(0, Qt::Checked);
        }
    }
    mpPlotTree->blockSignals(false);
}

void PlotWidget::showContextMenu(QPoint point)
{
    QTreeWidgetItem *item = 0;
    item = mpPlotTree->itemAt(point);

    // check if we have item at point and if the item is toplevelitem....because you can only delete toplevel items
    if (item and !item->parent())
    {
        mSelectedPlotTreeItem = dynamic_cast<PlotTreeItem*>(item);
        QMenu menu(this);
        menu.addAction(mpDeleteResultAction);
        menu.exec(mapToGlobal(point));
    }
}

void PlotWidget::deletePlotTreeItem()
{
    emit removePlotFile(mSelectedPlotTreeItem);
    qDeleteAll(mSelectedPlotTreeItem->takeChildren());
    delete mSelectedPlotTreeItem;
}
