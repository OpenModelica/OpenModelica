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

//! @file   plotwindow.h
//! @author harka011
//! @date   2011-02-03

//! @brief Tool drawing 2D plot graph, supports .plt .mat .csv and plot plotParametric plotAll

#ifndef PLOTWINDOW_H
#define PLOTWINDOW_H

#include <QMainWindow>
#include <QCheckBox>
#include <QComboBox>
#include <QToolButton>
#include <QLabel>
#include <QFile>
#include <QMdiSubWindow>
#include <QGroupBox>
#include <QPushButton>
#include <QListWidget>
#include <QDoubleSpinBox>
#include <QDialog>
#include <QStackedWidget>
#include <QTextStream>
#include <QDialogButtonBox>

#include "qwt_series_data.h"
#include "qwt_scale_draw.h"
#include "qwt_plot_curve.h"
#if QWT_VERSION >= 0x060000
#if QWT_VERSION < 0x060200
#include <qwt_compat.h>
#else
#define QwtArray QVector
#endif
#endif

namespace OMPlot
{
class Plot;
class PlotCurve;

class PlotWindow : public QMainWindow
{
  Q_OBJECT
public:
  enum PlotType {PLOT, PLOTALL, PLOTPARAMETRIC, PLOTINTERACTIVE, PLOTARRAY, PLOTARRAYPARAMETRIC};
private:
  Plot *mpPlot;
  QCheckBox *mpLogXCheckBox;
  QCheckBox *mpLogYCheckBox;
  QComboBox *mpGridComboBox;
  QToolButton *mpAutoScaleButton;
  QToolButton *mpSetupButton;
  QToolButton *mpStartSimulationToolButton;
  QToolButton *mpPauseSimulationToolButton;
  QLabel *mpSimulationSpeedLabel;
  QComboBox *mpSimulationSpeedComboBox;
  QTextStream *mpTextStream;
  QFile mFile;
  QStringList mVariablesList;
  PlotType mPlotType;
  QString mGridType;
  QString mXLabel;
  QString mYLabel;
  QString mXCustomLabel;
  QString mYCustomLabel;
  QString mYRightCustomLabel;
  QString mXUnit;
  QString mXDisplayUnit;
  QString mYUnit;
  QString mYDisplayUnit;
  QString mYRightUnit;
  QString mYRightDisplayUnit;
  QString mTimeUnit;
  QString mXRangeMin;
  QString mXRangeMax;
  QString mYRangeMin;
  QString mYRangeMax;
  QString mYRightRangeMin;
  QString mYRightRangeMax;
  double mCurveWidth;
  int mCurveStyle;
  QFont mLegendFont;
  double mTime;
  bool mIsInteractiveSimulation;
  QString mInteractiveTreeItemOwner;
  int mInteractivePort;
  QwtSeriesData<QPointF>* mpInteractiveData;
  QString mInteractiveModelName;
  bool mPrefixUnits;
  QMdiSubWindow *mpSubWindow;
public:
  PlotWindow(QStringList arguments = QStringList(), QWidget *parent = 0, bool isInteractiveSimulation = false, int toolbarIconSize = 0);

  ~PlotWindow();

  void setUpWidget(int toolbarIconSize);
  void initializePlot(QStringList arguments);
  void setVariablesList(QStringList variables);
  void setPlotType(PlotType type);
  bool isPlot() const {return mPlotType == PlotWindow::PLOT;}
  bool isPlotAll() const {return mPlotType == PlotWindow::PLOTALL;}
  bool isPlotParametric() const {return mPlotType == PlotWindow::PLOTPARAMETRIC;}
  bool isPlotInteractive() const {return mPlotType == PlotWindow::PLOTINTERACTIVE;}
  bool isPlotArray() const {return mPlotType == PlotWindow::PLOTARRAY;}
  bool isPlotArrayParametric() const {return mPlotType == PlotWindow::PLOTARRAYPARAMETRIC;}
  PlotType getPlotType() const {return mPlotType;}
  void initializeFile(QString file);
  void getStartStopTime(double &start, double &stop);
  void setupToolbar(int toolbarIconSize);
  void plot(PlotCurve *pPlotCurve = 0);
  void plotParametric(PlotCurve *pPlotCurve = 0);
  void plotArray(double time, PlotCurve *pPlotCurve = 0);
  void plotArrayParametric(double time, PlotCurve *pPlotCurve = 0);
  QPair<QVector<double>*, QVector<double>*> plotInteractive(PlotCurve *pPlotCurve = 0);
  void setInteractiveOwner(const QString &interactiveTreeItemOwner);
  void setInteractivePort(const int port);
  void setInteractivePlotData(QwtSeriesData<QPointF>* pInteractiveData);
  void setSubWindow(QMdiSubWindow *pSubWindow) {mpSubWindow = pSubWindow;}
  QMdiSubWindow* getSubWindow() {return mpSubWindow;}
  void setInteractiveModelName(const QString &modelName);
  QString getInteractiveOwner() {return mInteractiveTreeItemOwner;}
  int getInteractivePort() {return mInteractivePort;}
  void setTitle(QString title);
  void setGrid(QString grid);
  QString getGrid();
  QCheckBox* getLogXCheckBox();
  QCheckBox* getLogYCheckBox();
  QToolButton* getAutoScaleButton() {return mpAutoScaleButton;}
  QToolButton* getStartSimulationButton() {return mpStartSimulationToolButton;}
  QToolButton* getPauseSimulationButton() {return mpPauseSimulationToolButton;}
  QComboBox* getSimulationSpeedBox() {return mpSimulationSpeedComboBox;}
  void setXLabel(const QString &label) {mXLabel = label;}
  QString getXLabel() const {return mXLabel;}
  void setYLabel(const QString &label) {mYLabel = label;}
  QString getYLabel() const {return mYLabel;}
  void setXCustomLabel(const QString &label) {mXCustomLabel = label;}
  QString getXCustomLabel() const {return mXCustomLabel;}
  void setYCustomLabel(const QString &label) {mYCustomLabel = label;}
  QString getYCustomLabel() const {return mYCustomLabel;}
  void setYRightCustomLabel(const QString& label) {mYRightCustomLabel = label;}
  QString getYRightCustomLabel() const {return mYRightCustomLabel;}
  void setXUnit(QString xUnit) {mXUnit = xUnit;}
  QString getXUnit() {return mXUnit;}
  void setXDisplayUnit(QString xDisplayUnit) {mXDisplayUnit = xDisplayUnit;}
  QString getXDisplayUnit() {return mXDisplayUnit;}
  void setYUnit(QString yUnit) {mYUnit = yUnit;}
  QString getYUnit() {return mYUnit;}
  void setYDisplayUnit(QString yDisplayUnit) {mYDisplayUnit = yDisplayUnit;}
  QString getYDisplayUnit() {return mYDisplayUnit;}
  void setYRightUnit(QString yUnit) { mYRightUnit = yUnit; }
  QString getYRightUnit() { return mYRightUnit; }
  void setYRightDisplayUnit(QString yDisplayUnit) { mYRightDisplayUnit = yDisplayUnit; }
  QString getYRightDisplayUnit() { return mYRightDisplayUnit; }
  void setTimeUnit(QString timeUnit) {mTimeUnit = timeUnit;}
  QString getTimeUnit() {return mTimeUnit;}
  void setXRange(double min, double max);
  QString getXRangeMin();
  QString getXRangeMax();
  void setYRange(double min, double max);
  QString getYRangeMin();
  QString getYRangeMax();
  void setYRightRange(double min, double max);
  QString getYRightRangeMin();
  QString getYRightRangeMax();
  void setCurveWidth(double width);
  double getCurveWidth();
  void setCurveStyle(int style);
  int getCurveStyle();
  void setLegendFont(QFont font);
  QFont getLegendFont();
  void setLegendPosition(QString position);
  QString getLegendPosition();
  void setFooter(QString footer);
  QString getFooter();
  bool getPrefixUnits() const;
  void setPrefixUnits(bool prefixUnits);
  void checkForErrors(QStringList variables, QStringList variablesPlotted);
  Plot* getPlot();
  void receiveMessage(QStringList arguments);
  void closeEvent(QCloseEvent *event);
  void setTime(double time){mTime = time;}
  double getTime() {return mTime;}
  void updateTimeText();
  void updatePlot();
  void emitPrefixUnitsChanged();
private:
  void setInteractiveControls(bool enabled);
signals:
  void closingDown();
  void prefixUnitsChanged();
private slots:
  void fitInView();
public slots:
  void updateCurves();
  void updateYAxis(QPair<double, double> minMaxValues);
  void enableZoomMode(bool on);
  void enablePanMode(bool on);
  void exportDocument();
  void printPlot();
  void setGrid(int index);
  void setLogX(bool on);
  void setLogY(bool on);
  void setAutoScale(bool on);
  bool toggleSign(PlotCurve *pPlotCurve, bool checked);
  void setYAxisRight(PlotCurve* pPlotCurve, bool right);
  void showSetupDialog();
  void showSetupDialog(QString variable);
  void interactiveSimulationStarted();
  void interactiveSimulationPaused();
};

//Exception classes
class PlotException : public std::runtime_error
{
public:
  PlotException(const char *e) : std::runtime_error(e) {}
  PlotException(const QString str) : std::runtime_error(str.toStdString().c_str()) {}
};

class NoFileException : public PlotException
{
public:
  NoFileException(const char *fileName) : PlotException(fileName) {}
};

class NoVariableException : public PlotException
{
public:
  NoVariableException(const char *varName) : PlotException(varName) {}
};

class SetupDialog;
class VariablePageWidget : public QWidget
{
  Q_OBJECT
private:
  PlotCurve *mpPlotCurve;
  QGroupBox *mpGeneralGroupBox;
  QLabel *mpLegendLabel;
  QLineEdit *mpLegendTextBox;
  QPushButton *mpResetLabelButton;
  QLabel *mpFileLabel;
  QLabel *mpFileTextBox;
  QGroupBox *mpAppearanceGroupBox;
  QLabel *mpColorLabel;
  QPushButton *mpPickColorButton;
  QColor mCurveColor;
  QCheckBox *mpAutomaticColorCheckBox;
  QLabel *mpPatternLabel;
  QComboBox *mpPatternComboBox;
  QLabel *mpThicknessLabel;
  QDoubleSpinBox *mpThicknessSpinBox;
  QCheckBox *mpHideCheckBox;
  QCheckBox *mpToggleSignCheckBox;
  QCheckBox *mpRightYAxisCheckBox;
public:
  VariablePageWidget(PlotCurve *pPlotCurve, SetupDialog *pSetupDialog);
  void setCurvePickColorButtonIcon();
  PlotCurve* getPlotCurve() {return mpPlotCurve;}
  QLineEdit* getLegendTextBox() {return mpLegendTextBox;}
  void setCurveColor(QColor color) {mCurveColor = color;}
  QColor getCurveColor() {return mCurveColor;}
  QCheckBox* getAutomaticColorCheckBox() {return mpAutomaticColorCheckBox;}
  QComboBox* getPatternComboBox() {return mpPatternComboBox;}
  QDoubleSpinBox* getThicknessSpinBox() {return mpThicknessSpinBox;}
  QCheckBox* getHideCheckBox() {return mpHideCheckBox;}
  QCheckBox* getToggleSignCheckBox() const {return mpToggleSignCheckBox;}
  QCheckBox* getYRightAxisCheckBox() const {return mpRightYAxisCheckBox;}
public slots:
  void resetLabel();
  void pickColor();
};

class SetupDialog : public QDialog
{
  Q_OBJECT
private:
  PlotWindow *mpPlotWindow;
  QTabWidget *mpSetupTabWidget;
  /* variables tab */
  QWidget *mpVariablesTab;
  QLabel *mpVariableLabel;
  QListWidget *mpVariablesListWidget;
  QStackedWidget *mpVariablePagesStackedWidget;
  /* titles tab */
  QWidget *mpTitlesTab;
  QLabel *mpPlotTitleLabel;
  QLineEdit *mpPlotTitleTextBox;
  QLabel *mpTitleFontSizeLabel;
  QDoubleSpinBox *mpTitleFontSizeSpinBox;
  QLabel *mpVerticalAxisLabel;
  QLineEdit *mpVerticalAxisTextBox;
  QLabel *mpVerticalAxisTitleFontSizeLabel;
  QDoubleSpinBox *mpVerticalAxisTitleFontSizeSpinBox;
  QLabel *mpVerticalAxisNumbersFontSizeLabel;
  QDoubleSpinBox *mpVerticalAxisNumbersFontSizeSpinBox;
  QLabel* mpRightVerticalAxisLabel;
  QLineEdit* mpRightVerticalAxisTextBox;
  QLabel* mpRightVerticalAxisTitleFontSizeLabel;
  QDoubleSpinBox* mpRightVerticalAxisTitleFontSizeSpinBox;
  QLabel* mpRightVerticalAxisNumbersFontSizeLabel;
  QDoubleSpinBox* mpRightVerticalAxisNumbersFontSizeSpinBox;
  QLabel *mpHorizontalAxisLabel;
  QLineEdit *mpHorizontalAxisTextBox;
  QLabel *mpHorizontalAxisTitleFontSizeLabel;
  QDoubleSpinBox *mpHorizontalAxisTitleFontSizeSpinBox;
  QLabel *mpHorizontalAxisNumbersFontSizeLabel;
  QDoubleSpinBox *mpHorizontalAxisNumbersFontSizeSpinBox;
  QLabel *mpPlotFooterLabel;
  QLineEdit *mpPlotFooterTextBox;
  QLabel *mpFooterFontSizeLabel;
  QDoubleSpinBox *mpFooterFontSizeSpinBox;
  /* legend tab */
  QWidget *mpLegendTab;
  QLabel *mpLegendPositionLabel;
  QComboBox *mpLegendPositionComboBox;
  QLabel *mpLegendFontSizeLabel;
  QDoubleSpinBox *mpLegendFontSizeSpinBox;
  /* range tab */
  QWidget *mpRangeTab;
  QCheckBox *mpAutoScaleCheckbox;
  QGroupBox *mpXAxisGroupBox;
  QLabel *mpXMinimumLabel;
  QLineEdit *mpXMinimumTextBox;
  QLabel *mpXMaximumLabel;
  QLineEdit *mpXMaximumTextBox;
  QGroupBox *mpYAxisGroupBox;
  QLabel *mpYMinimumLabel;
  QLineEdit *mpYMinimumTextBox;
  QLabel *mpYMaximumLabel;
  QLineEdit *mpYMaximumTextBox;
  QGroupBox* mpYRightAxisGroupBox;
  QLabel* mpYRightMinimumLabel;
  QLineEdit* mpYRightMinimumTextBox;
  QLabel* mpYRightMaximumLabel;
  QLineEdit* mpYRightMaximumTextBox;
  QCheckBox *mpPrefixUnitsCheckbox;
  /* buttons */
  QPushButton *mpOkButton;
  QPushButton *mpApplyButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public:
  SetupDialog(PlotWindow *pPlotWindow);
  void selectVariable(QString variable);
  void setupPlotCurve(VariablePageWidget *pVariablePageWidget, bool prefixUnitsChanged);
public slots:
  void variableSelected(QListWidgetItem *current, QListWidgetItem *previous);
  void autoScaleChecked(bool checked);
  void saveSetup();
  void applySetup();
};

}

#endif // PLOTWINDOW_H
