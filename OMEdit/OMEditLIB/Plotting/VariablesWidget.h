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

#include "Simulation/SimulationOptions.h"
#include "PlotWindow.h"
#include "Animation/TimeManager.h"

#include <QDomDocument>
#include <QTreeView>

class OMCProxy;
class TreeSearchFilters;
class Label;
class VariableNode;

typedef QPair<int,QString> IntStringPair;
Q_DECLARE_METATYPE(IntStringPair)

class VariablesTreeItem
{
public:
  VariablesTreeItem(const QVector<QVariant> &variableItemData, VariablesTreeItem *pParent = 0, bool isRootItem = false);
  ~VariablesTreeItem();
  void setVariableItemData(const QVector<QVariant> &variableItemData);
  bool isRootItem() {return mIsRootItem;}
  QString getFilePath() {return mFilePath;}
  QString getFileName() {return mFileName;}
  QString getPlotVariable();
  QString getVariableName() {return mVariableName;}
  bool isString() const;
  bool isValueChanged() {return mValueChanged;}
  QString getUnit() {return mUnit;}
  QString getDisplayUnit() {return mDisplayUnit;}
  QString getPreviousUnit() {return mPreviousUnit;}
  QStringList getDisplayUnits() {return mDisplayUnits;}
  QStringList getUses() {return mUses;}
  QStringList getInitialUses() {return mInitialUses;}
  QList<IntStringPair> getDefinedIn() {return mDefinedIn;}
  QString getInfoFileName() {return mInfoFileName;}
  bool getExistInResultFile() const {return mExistInResultFile;}
  bool isChecked() const {return mChecked;}
  void setChecked(bool set) {mChecked = set;}
  bool isEditable() const {return mEditable;}
  void setEditable(bool set) {mEditable = set;}
  void setVariability(QString variability) {mVariability = variability;}
  bool isParameter() const {return mVariability.compare("parameter") == 0;}
  bool isMainArray() const {return mIsMainArray;}
  bool isMainArrayProtected() const;
  SimulationOptions getSimulationOptions() {return mSimulationOptions;}
  void setSimulationOptions(SimulationOptions simulationOptions) {mSimulationOptions = simulationOptions;}
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

  QVector<VariablesTreeItem*> mChildren;
  /* See issue #14192
   * We need a hash to speed up the search for child items.
   * We maintain both mChildren vector and mChildrenHash hash.
   * One is ordered vector and other is unordered hash.
   */
  QHash<QString, VariablesTreeItem*> mChildrenHash;
private:
  VariablesTreeItem *mpParentVariablesTreeItem;
  bool mIsRootItem;
  QString mFilePath;
  QString mFileName;
  QString mVariableName;
  QString mDisplayVariableName;
  QString mType;
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
  QStringList mUses, mInitialUses;
  QList<IntStringPair> mDefinedIn;
  QString mInfoFileName;
  bool mExistInResultFile;
};

class VariablesTreeView;

class VariableTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  VariableTreeProxyModel(QObject *parent = 0);
protected:
  virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
  virtual bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;
};

class VariablesTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  VariablesTreeModel(VariablesTreeView *pVariablesTreeView = 0);
  VariablesTreeItem* getRootVariablesTreeItem() {return mpRootVariablesTreeItem;}
  VariablesTreeItem* getActiveVariablesTreeItem() {return mpActiveVariablesTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
  QModelIndex parent(const QModelIndex & index) const override;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;
  Qt::ItemFlags flags(const QModelIndex &index) const override;
  VariablesTreeItem* findVariablesTreeItem(const QString &name, VariablesTreeItem *pVariablesTreeItem, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  VariablesTreeItem* findVariablesTreeItemOneLevel(const QString &name, VariablesTreeItem *pVariablesTreeItem = 0, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  VariablesTreeItem* findVariablesTreeItemFromClassNameTopLevel(const QString &className) const;
  void updateVariablesTreeItem(VariablesTreeItem *pVariablesTreeItem, int column);
  QModelIndex variablesTreeItemIndex(VariablesTreeItem *pVariablesTreeItem, int column = 0) const;
  bool insertVariablesItems(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions);
  void parseInitXml(QXmlStreamReader &xmlReader, SimulationOptions simulationOptions, QStringList *variablesList);
  bool removeVariableTreeItem(QString variable, bool closeInteractivePlotWindow);
  void unCheckVariables(VariablesTreeItem *pVariablesTreeItem);
  void plotAllVariables(VariablesTreeItem *pVariablesTreeItem, OMPlot::PlotWindow *pPlotWindow);
private:
  VariablesTreeView *mpVariablesTreeView;
  VariablesTreeItem *mpRootVariablesTreeItem;
  VariablesTreeItem *mpActiveVariablesTreeItem;
  QHash<QString, QHash<QString,QString> > mScalarVariablesHash;
  void filterVariableTreeItem(VariableNode *pParentVariableNode, VariablesTreeItem *pParentVariablesTreeItem);
  void insertVariablesItems(VariableNode *pParentVariableNode, VariablesTreeItem *pParentVariablesTreeItem);
  QHash<QString, QString> parseScalarVariable(QXmlStreamReader &xmlReader);
  void getVariableInformation(ModelicaMatReader *pMatReader, QString variableToFind, QString *type, QString *value, bool *changeAble, QString *variability,
                              QString *unit, QString *displayUnit, QString *description);
signals:
  void itemChecked(const QModelIndex &index, qreal curveThickness, int curveStyle, bool shiftKey);
  void unitChanged(const QModelIndex &index);
  void valueEntered(const QModelIndex &index);
  void variableTreeItemRemoved(QString variable);
public slots:
  void removeVariableTreeItem();
  void enableTimeControls();
  void filterDependencies();
  void openTransformationsBrowser();
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
  virtual void mouseReleaseEvent(QMouseEvent *event) override;
  virtual void keyPressEvent(QKeyEvent *event) override;
};

typedef struct {
  QString fileName;
  QString variableName;
  QString unit;
  QString displayUnit;
  bool isString;
} PlotParametricVariable;

typedef struct {
  PlotParametricVariable xVariable;
  QVector<PlotParametricVariable> yVariables;
} PlotParametricCurve;

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
  void enableVisualizationControls(bool enable);
  void insertVariablesItemsToTree(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions);
  void variablesUpdated();
  void updateVariablesTreeHelper(QMdiSubWindow *pSubWindow);
  void readVariablesAndUpdateXML(VariablesTreeItem *pVariablesTreeItem, QString outputFileName,
                                 QHash<QString, QHash<QString, QString> > *variables);
  void findVariableAndUpdateValue(QDomDocument xmlDocument, QHash<QString, QHash<QString, QString> > variables);
  void reSimulate(bool showSetup);
  void updateInitXmlFile(VariablesTreeItem *pVariablesTreeItem, SimulationOptions simulationOptions);
  void initializeVisualization();
  void updateVisualization();
  void updatePlotWindows();
  void updateBrowserTime(double time);
  QPair<double, bool> readVariableValue(QString variable, double time, bool reportError = true);
  void closeResultFile();
private:
  TreeSearchFilters *mpTreeSearchFilters;
  Label *mpSimulationTimeLabel;
  QComboBox *mpSimulationTimeComboBox;
  Label *mpTimeControlsDescriptionLabel;
  QSlider *mpSimulationTimeSlider;
  int mSliderRange;
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
  QVector<PlotParametricCurve> mPlotParametricCurves;
  QMdiSubWindow *mpLastActiveSubWindow;
  ModelicaMatReader mModelicaMatReader;
  csv_data *mpCSVData;
  QFile mPlotFileReader;
  void selectInteractivePlotWindow(VariablesTreeItem *pVariablesTreeItem);
  void openResultFile(VariablesTreeItem *pVariablesTreeItem, double &startTime, double &stopTime);
  void checkVariable(const QModelIndex &index, bool checkState);
  void unCheckVariableAndErrorMessage(const QModelIndex &index, const QString &errorMessage);
  void unCheckCurveVariable(const QString &variable);
  void updateDisplayUnitAndValue(const QString &unitPrefix, const QString &displayUnit, VariablesTreeItem *pVariablesTreeItem);
public slots:
  void plotVariables(const QModelIndex &index, qreal curveThickness, int curveStyle, bool shiftKey, OMPlot::PlotCurve *pPlotCurve = 0, OMPlot::PlotWindow *pPlotWindow = 0);
  void unitChanged(const QModelIndex &index);
  void updatePlottedVariablesDisplayUnitAndValue();
  void simulationTimeChanged(int value);
  void valueEntered(const QModelIndex &index);
  void timeUnitChanged(int index);
  void updateVariablesTree(QMdiSubWindow *pSubWindow);
  void showContextMenu(QPoint point);
  void findVariables();
  void directReSimulate();
  void showReSimulateSetup();
  void rewindVisualization();
private slots:
  void playVisualization();
  void pauseVisualization();
  void visualizationTimeChanged();
  void visualizationSpeedChanged();
  void incrementVisualization();
signals:
  void updateDynamicSelect(double time);
  void resetDynamicSelect();
};

#endif // VARIABLESWIDGET_H
