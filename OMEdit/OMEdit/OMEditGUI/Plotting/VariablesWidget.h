/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef VARIABLESWIDGET_H
#define VARIABLESWIDGET_H

#include <QDomDocument>

#include "Simulation/SimulationOptions.h"
#include "PlotWindow.h"
#include "Animation/TimeManager.h"

class OMCProxy;
class TreeSearchFilters;
class Label;

class VariablesTreeItem
{
public:
  VariablesTreeItem(const QVector<QVariant> &variableItemData, VariablesTreeItem *pParent = 0, bool isRootItem = false);
  ~VariablesTreeItem();
  QList<VariablesTreeItem*> getChildren() const {return mChildren;}
  bool isRootItem() {return mIsRootItem;}
  QString getFilePath() {return mFilePath;}
  QString getFileName() {return mFileName;}
  QString getPlotVariable();
  QString getVariableName() {return mVariableName;}
  bool isValueChanged() {return mValueChanged;}
  QString getUnit() {return mUnit;}
  QString getDisplayUnit() {return mDisplayUnit;}
  QString getPreviousUnit() {return mPreviousUnit;}
  QStringList getDisplayUnits() {return mDisplayUnits;}
  bool isChecked() const {return mChecked;}
  void setChecked(bool set) {mChecked = set;}
  bool isEditable() const {return mEditable;}
  void setEditable(bool set) {mEditable = set;}
  void setVariability(QString variability) {mVariability = variability;}
  bool isParameter() const {return mVariability.compare("parameter") == 0;}
  bool isMainArray() const {return mIsMainArray;}
  SimulationOptions getSimulationOptions() {return mSimulationOptions;}
  void setSimulationOptions(SimulationOptions simulationOptions) {mSimulationOptions = simulationOptions;}
  bool isActive() const {return mActive;}
  void setActive();
  QIcon getVariableTreeItemIcon(QString name) const;
  void insertChild(int position, VariablesTreeItem *pVariablesTreeItem);
  VariablesTreeItem* child(int row);
  void removeChildren();
  void removeChild(VariablesTreeItem *pVariablesTreeItem);
  int columnCount() const;
  bool setData(int column, const QVariant &value, int role = Qt::EditRole);
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  VariablesTreeItem* parent() {return mpParentVariablesTreeItem;}
  VariablesTreeItem* parent() const {return mpParentVariablesTreeItem;}
  VariablesTreeItem* rootParent();
  QVariant getValue(QString fromUnit, QString toUnit);
private:
  QList<VariablesTreeItem*> mChildren;
  VariablesTreeItem *mpParentVariablesTreeItem;
  bool mIsRootItem;
  QString mFilePath;
  QString mFileName;
  QString mVariableName;
  QString mDisplayVariableName;
  QString mValue;
  bool mValueChanged;
  QString mUnit;
  QString mDisplayUnit;
  QString mPreviousUnit;
  QStringList mDisplayUnits;
  QString mDescription;
  QString mToolTip;
  bool mChecked;
  bool mEditable;
  QString mVariability;
  bool mIsMainArray;
  SimulationOptions mSimulationOptions;
protected:
  bool mActive;
};

class VariablesTreeView;
class VariablesTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  VariablesTreeModel(VariablesTreeView *pVariablesTreeView = 0);
  VariablesTreeItem* getRootVariablesTreeItem() {return mpRootVariablesTreeItem;}
  VariablesTreeItem* getActiveVariablesTreeItem() {return mpActiveVariablesTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  VariablesTreeItem* findVariablesTreeItem(const QString &name, VariablesTreeItem *root) const;
  QModelIndex variablesTreeItemIndex(const VariablesTreeItem *pVariablesTreeItem) const;
  QModelIndex variablesTreeItemIndexHelper(const VariablesTreeItem *pVariablesTreeItem, const VariablesTreeItem *pParentVariablesTreeItem,
                                           const QModelIndex &parentIndex) const;
  void parseInitXml(QXmlStreamReader &xmlReader);
  void insertVariablesItems(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions);
  bool removeVariableTreeItem(QString variable);
  void unCheckVariables(VariablesTreeItem *pVariablesTreeItem);
  void plotAllVariables(VariablesTreeItem *pVariablesTreeItem, OMPlot::PlotWindow *pPlotWindow);
private:
  VariablesTreeView *mpVariablesTreeView;
  VariablesTreeItem *mpRootVariablesTreeItem;
  VariablesTreeItem *mpActiveVariablesTreeItem;
  QHash<QString, QHash<QString,QString> > mScalarVariablesHash;
  QHash<QString, QString> parseScalarVariable(QXmlStreamReader &xmlReader);
  void getVariableInformation(ModelicaMatReader *pMatReader, QString variableToFind, QString *value, bool *changeAble, QString *variability,
                              QString *unit, QString *displayUnit, QString *description);
signals:
  void itemChecked(const QModelIndex &index, qreal curveThickness, int curveStyle);
  void unitChanged(const QModelIndex &index);
  void valueEntered(const QModelIndex &index);
  void variableTreeItemRemoved(QString variable);
public slots:
  void removeVariableTreeItem();
  void setVariableTreeItemActive();
};

class VariableTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  VariableTreeProxyModel(QObject *parent = 0);
protected:
  virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
  virtual bool lessThan(const QModelIndex &left, const QModelIndex &right) const;
};

class VariablesWidget;
class VariablesTreeView : public QTreeView
{
  Q_OBJECT
public:
  VariablesTreeView(VariablesWidget *pVariablesWidget);
  VariablesWidget* getVariablesWidget() {return mpVariablesWidget;}
private:
  VariablesWidget *mpVariablesWidget;
protected:
  virtual void mouseReleaseEvent(QMouseEvent *event);
  virtual void keyPressEvent(QKeyEvent *event);
};

class VariablesWidget : public QWidget
{
  Q_OBJECT
public:
  VariablesWidget(QWidget *pParent = 0);
  TreeSearchFilters* getTreeSearchFilters() {return mpTreeSearchFilters;}
  QComboBox* getSimulationTimeComboBox() {return mpSimulationTimeComboBox;}
  VariableTreeProxyModel* getVariableTreeProxyModel() {return mpVariableTreeProxyModel;}
  VariablesTreeModel* getVariablesTreeModel() {return mpVariablesTreeModel;}
  VariablesTreeView* getVariablesTreeView() {return mpVariablesTreeView;}
  void insertVariablesItemsToTree(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions);
  void addSelectedInteractiveVariables(const QString &modelName, const QList<QString> &selectedVariables);
  void variablesUpdated();
  void updateVariablesTreeHelper(QMdiSubWindow *pSubWindow);
  void readVariablesAndUpdateXML(VariablesTreeItem *pVariablesTreeItem, QString outputFileName,
                                 QHash<QString, QHash<QString, QString> > *variables);
  void findVariableAndUpdateValue(QDomDocument xmlDocument, QHash<QString, QHash<QString, QString> > variables);
  void reSimulate(bool showSetup);
  void interactiveReSimulation(QString modelName);
  void updateInitXmlFile(SimulationOptions simulationOptions);
  void initializeVisualization(SimulationOptions simulationOptions);
  double readVariableValue(QString variable, double time);
private:
  TreeSearchFilters *mpTreeSearchFilters;
  Label *mpSimulationTimeLabel;
  QComboBox *mpSimulationTimeComboBox;
  QSlider *mpSimulationTimeSlider;
  QToolBar *mpToolBar;
  QAction *mpRewindAction;
  QAction *mpPlayAction;
  QAction *mpPauseAction;
  Label *mpTimeLabel;
  QLineEdit *mpTimeTextBox;
  Label *mpSpeedLabel;
  QComboBox *mpSpeedComboBox;
  TimeManager *mpTimeManager;
  VariableTreeProxyModel *mpVariableTreeProxyModel;
  VariablesTreeModel *mpVariablesTreeModel;
  VariablesTreeView *mpVariablesTreeView;
  QList<QStringList> mPlotParametricVariables;
  QHash<QString, QList<QString>> mSelectedInteractiveVariables;
  QString mFileName;
  QMdiSubWindow *mpLastActiveSubWindow;
  ModelicaMatReader mModelicaMatReader;
  csv_data *mpCSVData;
  QFile mPlotFileReader;
  void selectInteractivePlotWindow(VariablesTreeItem *pVariablesTreeItem);
  void closeResultFile();
  void openResultFile();
  void updateVisualization();
public slots:
  void plotVariables(const QModelIndex &index, qreal curveThickness, int curveStyle,
                     OMPlot::PlotCurve *pPlotCurve = 0, OMPlot::PlotWindow *pPlotWindow = 0);
  void unitChanged(const QModelIndex &index);
  void simulationTimeChanged(int timePercent);
  void valueEntered(const QModelIndex &index);
  void timeUnitChanged(QString unit);
  void updateVariablesTree(QMdiSubWindow *pSubWindow);
  void showContextMenu(QPoint point);
  void findVariables();
  void directReSimulate();
  void showReSimulateSetup();
  void rewindVisualization();
private slots:
  void playVisualization();
  void pauseVisualization();
  void visulizationTimeChanged();
  void visualizationSpeedChanged();
  void incrementVisualization();
signals:
  void updateDynamicSelect(double time);
};

#endif // VARIABLESWIDGET_H
