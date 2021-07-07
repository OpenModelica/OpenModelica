/*
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

//! @file   plotwindow.h
//! @author harka011
//! @date   2011-02-03

//! @brief Tool drawing 2D plot graph, supports .plt .mat .csv and plot plotParametric plotAll

#ifndef PLOTWINDOW_H
#define PLOTWINDOW_H

#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QPrinter>
#include <QPrintDialog>
#else
#include <QtGui>
#endif
#include <QtCore>

#include <qwt_plot.h>
#include <qwt_text.h>
#include <qwt_plot_curve.h>
#include <qwt_plot_picker.h>
#include <qwt_scale_draw.h>
#include <qwt_picker_machine.h>
#include <qwt_plot_grid.h>
#include <qwt_curve_fitter.h>
#include <qwt_legend.h>
#include <qwt_plot_zoomer.h>
#include <qwt_plot_panner.h>
#include <qwt_scale_engine.h>
#if QWT_VERSION >= 0x060000
#include <qwt_compat.h>
#endif
#include <stdexcept>
#include "util/read_matlab4.h"
#include "util/read_csv.h"
#include "OMPlot.h"

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
  QToolButton *mpGridButton;
  QToolButton *mpDetailedGridButton;
  QToolButton *mpNoGridButton;
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
  QString mXUnit;
  QString mXDisplayUnit;
  QString mYUnit;
  QString mYDisplayUnit;
  QString mTimeUnit;
  QString mXRangeMin;
  QString mXRangeMax;
  QString mYRangeMin;
  QString mYRangeMax;
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
  bool mCanUseXPrefixUnits;
  bool mCanUseYPrefixUnits;
  QMdiSubWindow *mpSubWindow;
public:
  PlotWindow(QStringList arguments = QStringList(), QWidget *parent = 0, bool isInteractiveSimulation = false);

  ~PlotWindow();

  void setUpWidget();
  void initializePlot(QStringList arguments);
  void setVariablesList(QStringList variables);
  void setPlotType(PlotType type);
  PlotType getPlotType();
  void initializeFile(QString file);
  void getStartStopTime(double &start, double &stop);
  void setupToolbar();
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
  void setXUnit(QString xUnit) {mXUnit = xUnit;}
  QString getXUnit() {return mXUnit;}
  void setXDisplayUnit(QString xDisplayUnit) {mXDisplayUnit = xDisplayUnit;}
  QString getXDisplayUnit() {return mXDisplayUnit;}
  void setYUnit(QString yUnit) {mYUnit = yUnit;}
  QString getYUnit() {return mYUnit;}
  void setYDisplayUnit(QString yDisplayUnit) {mYDisplayUnit = yDisplayUnit;}
  QString getYDisplayUnit() {return mYDisplayUnit;}
  void setTimeUnit(QString timeUnit) {mTimeUnit = timeUnit;}
  QString getTimeUnit() {return mTimeUnit;}
  void setXRange(double min, double max);
  QString getXRangeMin();
  QString getXRangeMax();
  void setYRange(double min, double max);
  QString getYRangeMin();
  QString getYRangeMax();
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
  bool canUseXPrefixUnits() const;
  void setCanUseXPrefixUnits(bool canUseXPrefixUnits);
  bool canUseYPrefixUnits() const;
  void setCanUseYPrefixUnits(bool canUseYPrefixUnits);
  void checkForErrors(QStringList variables, QStringList variablesPlotted);
  Plot* getPlot();
  void receiveMessage(QStringList arguments);
  void closeEvent(QCloseEvent *event);
  void setTime(double time){mTime = time;}
  double getTime() {return mTime;}
  void updateTimeText(QString unit);
  void updateCurves();
  void updateYAxis(QPair<double, double> minMaxValues);
  void updatePlot();
signals:
  void closingDown();
public slots:
  void enableZoomMode(bool on);
  void enablePanMode(bool on);
  void exportDocument();
  void printPlot();
  void setGrid(bool on);
  void setDetailedGrid(bool on);
  void setNoGrid(bool on);
  void fitInView();
  void setLogX(bool on);
  void setLogY(bool on);
  void setAutoScale(bool on);
  bool toggleSign(PlotCurve *pPlotCurve, bool checked);
  void showSetupDialog();
  void showSetupDialog(QString variable);
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
  QCheckBox *mpPrefixUnitsCheckbox;
  /* buttons */
  QPushButton *mpOkButton;
  QPushButton *mpApplyButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public:
  SetupDialog(PlotWindow *pPlotWindow);
  void selectVariable(QString variable);
  bool setupPlotCurve(VariablePageWidget *pVariablePageWidget);
public slots:
  void variableSelected(QListWidgetItem *current, QListWidgetItem *previous);
  void autoScaleChecked(bool checked);
  void saveSetup();
  void applySetup();
};

}

#endif // PLOTWINDOW_H
