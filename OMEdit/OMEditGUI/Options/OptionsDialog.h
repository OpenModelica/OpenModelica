/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef OPTIONSDIALOG_H
#define OPTIONSDIALOG_H

#include "MainWindow.h"
#include "Helper.h"
#include "Utilities.h"

class MainWindow;
class GeneralSettingsPage;
class LibrariesPage;
class ModelicaTextHighlighter;
class ModelicaTextEditorPage;
class GraphicalViewsPage;
class SimulationPage;
class MessagesPage;
class NotificationsPage;
class LineStylePage;
class FillStylePage;
class PlottingPage;
class FigaroPage;
class DebuggerPage;
class FMIPage;
class TLMPage;
class TLMEditorPage;
class TabSettings;

class OptionsDialog : public QDialog
{
  Q_OBJECT
public:
  OptionsDialog(MainWindow *pMainWindow);
  void readSettings();
  void readGeneralSettings();
  void readLibrariesSettings();
  void readModelicaTextSettings();
  void readGraphicalViewsSettings();
  void readSimulationSettings();
  void readMessagesSettings();
  void readNotificationsSettings();
  void readLineStyleSettings();
  void readFillStyleSettings();
  void readPlottingSettings();
  void readFigaroSettings();
  void readDebuggerSettings();
  void readFMISettings();
  void readTLMSettings();
  void readTLMEditorSettings();
  void saveGeneralSettings();
  void saveLibrariesSettings();
  void saveModelicaTextSettings();
  void saveTLMSettings();
  void saveTLMEditorSettings();
  void saveGraphicalViewsSettings();
  void saveSimulationSettings();
  void saveMessagesSettings();
  void saveNotificationsSettings();
  void saveLineStyleSettings();
  void saveFillStyleSettings();
  void savePlottingSettings();
  void saveFigaroSettings();
  void saveDebuggerSettings();
  void saveFMISettings();
  void setUpDialog();
  void addListItems();
  void createPages();
  MainWindow* getMainWindow() {return mpMainWindow;}
  GeneralSettingsPage* getGeneralSettingsPage() {return mpGeneralSettingsPage;}
  ModelicaTextEditorPage* getModelicaTextEditorPage() {return mpModelicaTextEditorPage;}
  GraphicalViewsPage* getGraphicalViewsPage() {return mpGraphicalViewsPage;}
  SimulationPage* getSimulationPage() {return mpSimulationPage;}
  MessagesPage* getMessagesPage() {return mpMessagesPage;}
  NotificationsPage* getNotificationsPage() {return mpNotificationsPage;}
  LineStylePage* getLineStylePage() {return mpLineStylePage;}
  FillStylePage* getFillStylePage() {return mpFillStylePage;}
  PlottingPage* getPlottingPage() {return mpPlottingPage;}
  FigaroPage* getFigaroPage() {return mpFigaroPage;}
  DebuggerPage* getDebuggerPage() {return mpDebuggerPage;}
  FMIPage* getFMIPage() {return mpFMIPage;}
  TLMPage* getTLMPage() {return mpTLMPage;}
  TLMEditorPage* getTLMEditorPage() {return mpTLMEditorPage;}
  void saveDialogGeometry();
  void show();
  TabSettings getModelicaTabSettings();
  TabSettings getTLMTabSettings();
signals:
  void modelicaTextSettingsChanged();
  void TLMEditorSettingsChanged();
  void updateLineWrapping();
public slots:
  void changePage(QListWidgetItem *current, QListWidgetItem *previous);
  void reject();
  void saveSettings();
private:
  MainWindow *mpMainWindow;
  GeneralSettingsPage *mpGeneralSettingsPage;
  LibrariesPage *mpLibrariesPage;
  ModelicaTextEditorPage *mpModelicaTextEditorPage;
  GraphicalViewsPage *mpGraphicalViewsPage;
  SimulationPage *mpSimulationPage;
  MessagesPage *mpMessagesPage;
  NotificationsPage *mpNotificationsPage;
  LineStylePage *mpLineStylePage;
  FillStylePage *mpFillStylePage;
  PlottingPage *mpPlottingPage;
  FigaroPage *mpFigaroPage;
  DebuggerPage *mpDebuggerPage;
  FMIPage *mpFMIPage;
  TLMPage *mpTLMPage;
  TLMEditorPage *mpTLMEditorPage;
  QSettings *mpSettings;
  QListWidget *mpOptionsList;
  QStackedWidget *mpPagesWidget;
  Label *mpChangesEffectLabel;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
};

class GeneralSettingsPage : public QWidget
{
  Q_OBJECT
public:
  GeneralSettingsPage(OptionsDialog *pOptionsDialog);
  QComboBox* getLanguageComboBox();
  void setWorkingDirectory(QString value);
  QString getWorkingDirectory();
  QSpinBox* getToolbarIconSizeSpinBox() {return mpToolbarIconSizeSpinBox;}
  void setPreserveUserCustomizations(bool value);
  bool getPreserveUserCustomizations();
  void setTerminalCommand(QString value) {mpTerminalCommandTextBox->setText(value);}
  QString getTerminalCommand() {return mpTerminalCommandTextBox->text();}
  void setTerminalCommandArguments(QString value) {mpTerminalCommandArgumentsTextBox->setText(value);}
  QString getTerminalCommandArguments() {return mpTerminalCommandArgumentsTextBox->text();}
  QSpinBox* getLibraryIconSizeSpinBox() {return mpLibraryIconSizeSpinBox;}
  void setShowProtectedClasses(bool value);
  bool getShowProtectedClasses();
  void setModelingViewMode(QString value);
  QString getModelingViewMode();
  void setDefaultView(QString value);
  QString getDefaultView();
  QGroupBox* getEnableAutoSaveGroupBox();
  QSpinBox* getAutoSaveIntervalSpinBox();
  QCheckBox* getEnableAutoSaveForSingleClassesCheckBox();
  QCheckBox* getEnableAutoSaveForOneFilePackagesCheckBox();
  int getWelcomePageView();
  void setWelcomePageView(int view);
  QCheckBox* getShowLatestNewsCheckBox();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralSettingsGroupBox;
  Label *mpLanguageLabel;
  QComboBox *mpLanguageComboBox;
  Label *mpWorkingDirectoryLabel;
  QLineEdit *mpWorkingDirectoryTextBox;
  QPushButton *mpWorkingDirectoryBrowseButton;
  Label *mpToolbarIconSizeLabel;
  QSpinBox *mpToolbarIconSizeSpinBox;
  QCheckBox *mpPreserveUserCustomizations;
  Label *mpTerminalCommandLabel;
  QLineEdit *mpTerminalCommandTextBox;
  QPushButton *mpTerminalCommandBrowseButton;
  Label *mpTerminalCommandArgumentsLabel;
  QLineEdit *mpTerminalCommandArgumentsTextBox;
  QGroupBox *mpLibrariesBrowserGroupBox;
  Label *mpLibraryIconSizeLabel;
  QSpinBox *mpLibraryIconSizeSpinBox;
  QCheckBox *mpShowProtectedClasses;
  QGroupBox *mpModelingViewModeGroupBox;
  QRadioButton *mpModelingTabbedViewRadioButton;
  QRadioButton *mpModelingSubWindowViewRadioButton;
  QGroupBox *mpDefaultViewGroupBox;
  QRadioButton *mpIconViewRadioButton;
  QRadioButton *mpDiagramViewRadioButton;
  QRadioButton *mpTextViewRadioButton;
  QRadioButton *mpDocumentationViewRadioButton;
  QGroupBox *mpEnableAutoSaveGroupBox;
  Label *mpAutoSaveIntervalLabel;
  QSpinBox *mpAutoSaveIntervalSpinBox;
  Label *mpAutoSaveSecondsLabel;
  QCheckBox *mpEnableAutoSaveForSingleClassesCheckBox;
  QCheckBox *mpEnableAutoSaveForOneFilePackagesCheckBox;
  QGroupBox *mpWelcomePageGroupBox;
  QRadioButton *mpHorizontalViewRadioButton;
  QRadioButton *mpVerticalViewRadioButton;
  QCheckBox *mpShowLatestNewsCheckBox;
public slots:
  void selectWorkingDirectory();
  void selectTerminalCommand();
  void autoSaveIntervalValueChanged(int value);
};

class LibrariesPage : public QWidget
{
  Q_OBJECT
public:
  LibrariesPage(OptionsDialog *pOptionsDialog);
  QTreeWidget* getSystemLibrariesTree();
  QCheckBox* getForceModelicaLoadCheckBox();
  QTreeWidget* getUserLibrariesTree();
  OptionsDialog *mpOptionsDialog;
private:
  QGroupBox *mpSystemLibrariesGroupBox;
  Label *mpSystemLibrariesNoteLabel;
  QTreeWidget *mpSystemLibrariesTree;
  QPushButton *mpAddSystemLibraryButton;
  QPushButton *mpRemoveSystemLibraryButton;
  QPushButton *mpEditSystemLibraryButton;
  QDialogButtonBox *mpSystemLibrariesButtonBox;
  QCheckBox *mpForceModelicaLoadCheckBox;
  QGroupBox *mpUserLibrariesGroupBox;
  QTreeWidget *mpUserLibrariesTree;
  QPushButton *mpAddUserLibraryButton;
  QPushButton *mpRemoveUserLibraryButton;
  QPushButton *mpEditUserLibraryButton;
  QDialogButtonBox *mpUserLibrariesButtonBox;
  Label *mpModelicaPathLabel;
private slots:
  void openAddSystemLibrary();
  void removeSystemLibrary();
  void openEditSystemLibrary();
  void openAddUserLibrary();
  void removeUserLibrary();
  void openEditUserLibrary();
};

class AddSystemLibraryDialog : public QDialog
{
  Q_OBJECT
public:
  AddSystemLibraryDialog(LibrariesPage *pLibrariesPage);
  bool nameExists(QTreeWidgetItem *pItem = 0);

  LibrariesPage *mpLibrariesPage;
  Label *mpNameLabel;
  QComboBox *mpNameComboBox;
  Label *mpValueLabel;
  QLineEdit *mpVersionTextBox;
  QPushButton *mpOkButton;
  bool mEditFlag;
private slots:
  void addSystemLibrary();
};

class AddUserLibraryDialog : public QDialog
{
  Q_OBJECT
public:
  AddUserLibraryDialog(LibrariesPage *pLibrariesPage);
  bool pathExists(QTreeWidgetItem *pItem = 0);

  LibrariesPage *mpLibrariesPage;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpPathBrowseButton;
  Label *mpEncodingLabel;
  QComboBox *mpEncodingComboBox;
  QPushButton *mpOkButton;
  bool mEditFlag;
private slots:
  void browseUserLibraryPath();
  void addUserLibrary();
};

class ModelicaTextEditorPage : public QWidget
{
  Q_OBJECT
public:
  ModelicaTextEditorPage(OptionsDialog *pOptionsDialog);
  QComboBox *getTabPolicyComboBox() {return mpTabPolicyComboBox;}
  QSpinBox *getTabSizeSpinBox() {return mpTabSizeSpinBox;}
  QSpinBox *getIndentSpinBox() {return mpIndentSpinBox;}
  QCheckBox* getSyntaxHighlightingCheckbox() {return mpSyntaxHighlightingCheckbox;}
  QCheckBox* getLineWrappingCheckbox() {return mpLineWrappingCheckbox;}
  QFontComboBox* getFontFamilyComboBox() {return mpFontFamilyComboBox;}
  DoubleSpinBox* getFontSizeSpinBox() {return mpFontSizeSpinBox;}
  void addListItems();
  void setTextRuleColor(QColor color);
  QColor getTextRuleColor() {return mTextColor;}
  void setNumberRuleColor(QColor color);
  QColor getNumberRuleColor() {return mNumberColor;}
  void setKeywordRuleColor(QColor color);
  QColor getKeywordRuleColor() {return mKeywordColor;}
  void setTypeRuleColor(QColor color);
  QColor getTypeRuleColor() {return mTypeColor;}
  void setFunctionRuleColor(QColor color);
  QColor getFunctionRuleColor() {return mFunctionColor;}
  void setQuotesRuleColor(QColor color);
  QColor getQuotesRuleColor() {return mQuotesColor;}
  void setCommentRuleColor(QColor color);
  QColor getCommentRuleColor() {return mCommentColor;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpTabsAndIndentation;
  Label *mpTabPolicyLabel;
  QComboBox *mpTabPolicyComboBox;
  Label *mpTabSizeLabel;
  QSpinBox *mpTabSizeSpinBox;
  Label *mpIndentSizeLabel;
  QSpinBox *mpIndentSpinBox;
  QGroupBox *mpSyntaxHighlightAndTextWrappingGroupBox;
  QCheckBox *mpSyntaxHighlightingCheckbox;
  QCheckBox *mpLineWrappingCheckbox;
  QGroupBox *mpFontColorsGroupBox;
  Label *mpFontFamilyLabel;
  QFontComboBox *mpFontFamilyComboBox;
  Label *mpFontSizeLabel;
  DoubleSpinBox *mpFontSizeSpinBox;
  Label *mpItemsLabel;
  QListWidget *mpItemsList;
  Label *mpItemColorLabel;
  QPushButton *mpItemColorPickButton;
  Label *mpPreviewLabel;
  QPlainTextEdit *mpPreviewPlainTextBox;
  QColor mTextColor;
  QListWidgetItem *mpTextItem;
  QColor mNumberColor;
  QListWidgetItem *mpNumberItem;
  QColor mKeywordColor;
  QListWidgetItem *mpKeywordItem;
  QColor mTypeColor;
  QListWidgetItem *mpTypeItem;
  QColor mFunctionColor;
  QListWidgetItem *mpFunctionItem;
  QColor mQuotesColor;
  QListWidgetItem *mpQuotesItem;
  QColor mCommentColor;
  QListWidgetItem *mpCommentItem;
signals:
  void updatePreview();
public slots:
  void setLineWrapping();
  void pickColor();
};

class GraphicalViewsPage : public QWidget
{
  Q_OBJECT
public:
  GraphicalViewsPage(OptionsDialog *pOptionsDialog);
  void setIconViewExtentLeft(double extentLeft);
  double getIconViewExtentLeft();
  void setIconViewExtentBottom(double extentBottom);
  double getIconViewExtentBottom();
  void setIconViewExtentRight(double extentRight);
  double getIconViewExtentRight();
  void setIconViewExtentTop(double extentTop);
  double getIconViewExtentTop();
  void setIconViewGridHorizontal(double gridHorizontal);
  double getIconViewGridHorizontal();
  void setIconViewGridVertical(double gridVertical);
  double getIconViewGridVertical();
  void setIconViewScaleFactor(double scaleFactor);
  double getIconViewScaleFactor();
  void setIconViewPreserveAspectRation(bool preserveAspectRation);
  bool getIconViewPreserveAspectRation();
  void setDiagramViewExtentLeft(double extentLeft);
  double getDiagramViewExtentLeft();
  void setDiagramViewExtentBottom(double extentBottom);
  double getDiagramViewExtentBottom();
  void setDiagramViewExtentRight(double extentRight);
  double getDiagramViewExtentRight();
  void setDiagramViewExtentTop(double extentTop);
  double getDiagramViewExtentTop();
  void setDiagramViewGridHorizontal(double gridHorizontal);
  double getDiagramViewGridHorizontal();
  void setDiagramViewGridVertical(double gridVertical);
  double getDiagramViewGridVertical();
  void setDiagramViewScaleFactor(double scaleFactor);
  double getDiagramViewScaleFactor();
  void setDiagramViewPreserveAspectRation(bool preserveAspectRation);
  bool getDiagramViewPreserveAspectRation();
private:
  OptionsDialog *mpOptionsDialog;
  QTabWidget *mpGraphicalViewsTabWidget;
  QWidget *mpIconViewWidget;
  QGroupBox *mpIconViewExtentGroupBox;
  Label *mpIconViewLeftLabel;
  DoubleSpinBox *mpIconViewLeftSpinBox;
  Label *mpIconViewBottomLabel;
  DoubleSpinBox *mpIconViewBottomSpinBox;
  Label *mpIconViewRightLabel;
  DoubleSpinBox *mpIconViewRightSpinBox;
  Label *mpIconViewTopLabel;
  DoubleSpinBox *mpIconViewTopSpinBox;
  QGroupBox *mpIconViewGridGroupBox;
  Label *mpIconViewGridHorizontalLabel;
  DoubleSpinBox *mpIconViewGridHorizontalSpinBox;
  Label *mpIconViewGridVerticalLabel;
  DoubleSpinBox *mpIconViewGridVerticalSpinBox;
  QGroupBox *mpIconViewComponentGroupBox;
  Label *mpIconViewScaleFactorLabel;
  DoubleSpinBox *mpIconViewScaleFactorSpinBox;
  QCheckBox *mpIconViewPreserveAspectRatioCheckBox;
  QWidget *mpDiagramViewWidget;
  QGroupBox *mpDiagramViewExtentGroupBox;
  Label *mpDiagramViewLeftLabel;
  DoubleSpinBox *mpDiagramViewLeftSpinBox;
  Label *mpDiagramViewBottomLabel;
  DoubleSpinBox *mpDiagramViewBottomSpinBox;
  Label *mpDiagramViewRightLabel;
  DoubleSpinBox *mpDiagramViewRightSpinBox;
  Label *mpDiagramViewTopLabel;
  DoubleSpinBox *mpDiagramViewTopSpinBox;
  QGroupBox *mpDiagramViewGridGroupBox;
  Label *mpDiagramViewGridHorizontalLabel;
  DoubleSpinBox *mpDiagramViewGridHorizontalSpinBox;
  Label *mpDiagramViewGridVerticalLabel;
  DoubleSpinBox *mpDiagramViewGridVerticalSpinBox;
  QGroupBox *mpDiagramViewComponentGroupBox;
  Label *mpDiagramViewScaleFactorLabel;
  DoubleSpinBox *mpDiagramViewScaleFactorSpinBox;
  QCheckBox *mpDiagramViewPreserveAspectRatioCheckBox;
};

class SimulationPage : public QWidget
{
  Q_OBJECT
public:
  SimulationPage(OptionsDialog *pOptionsDialog);
  QComboBox* getMatchingAlgorithmComboBox() {return mpMatchingAlgorithmComboBox;}
  QComboBox* getIndexReductionMethodComboBox() {return mpIndexReductionMethodComboBox;}
  QComboBox* getTargetLanguageComboBox() {return mpTargetLanguageComboBox;}
  QComboBox* getTargetCompilerComboBox() {return mpTargetCompilerComboBox;}
  QLineEdit* getOMCFlagsTextBox() {return mpOMCFlagsTextBox;}
  QCheckBox *getSaveClassBeforeSimulationCheckBox() {return mpSaveClassBeforeSimulationCheckBox;}
  void setOutputMode(QString value);
  QString getOutputMode();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpSimulationGroupBox;
  Label *mpMatchingAlgorithmLabel;
  QComboBox *mpMatchingAlgorithmComboBox;
  Label *mpIndexReductionMethodLabel;
  QComboBox *mpIndexReductionMethodComboBox;
  Label *mpTargetLanguageLabel;
  QComboBox *mpTargetLanguageComboBox;
  Label *mpCompilerLabel;
  QComboBox *mpTargetCompilerComboBox;
  Label *mpOMCFlagsLabel;
  QLineEdit *mpOMCFlagsTextBox;
  QCheckBox *mpSaveClassBeforeSimulationCheckBox;
  QGroupBox *mpOutputGroupBox;
  QRadioButton *mpStructuredRadioButton;
  QRadioButton *mpFormattedTextRadioButton;
};

class MessagesPage : public QWidget
{
  Q_OBJECT
public:
  MessagesPage(OptionsDialog *pOptionsDialog);
  QSpinBox* getOutputSizeSpinBox() {return mpOutputSizeSpinBox;}
  QCheckBox* getResetMessagesNumberBeforeSimulationCheckBox() {return mpResetMessagesNumberBeforeSimulationCheckBox;}
  QFontComboBox* getFontFamilyComboBox() {return mpFontFamilyComboBox;}
  DoubleSpinBox* getFontSizeSpinBox() {return mpFontSizeSpinBox;}
  void setNotificationColor(QColor color) {mNotificaitonColor = color;}
  QColor getNotificationColor() {return mNotificaitonColor;}
  void setNotificationPickColorButtonIcon();
  void setWarningColor(QColor color) {mWarningColor = color;}
  QColor getWarningColor() {return mWarningColor;}
  void setWarningPickColorButtonIcon();
  void setErrorColor(QColor color) {mErrorColor = color;}
  QColor getErrorColor() {return mErrorColor;}
  void setErrorPickColorButtonIcon();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpOutputSizeLabel;
  QSpinBox *mpOutputSizeSpinBox;
  QCheckBox *mpResetMessagesNumberBeforeSimulationCheckBox;
  QGroupBox *mpFontColorsGroupBox;
  Label *mpFontFamilyLabel;
  QFontComboBox *mpFontFamilyComboBox;
  Label *mpFontSizeLabel;
  DoubleSpinBox *mpFontSizeSpinBox;
  Label *mpNotificationColorLabel;
  QPushButton *mpNotificationColorButton;
  QColor mNotificaitonColor;
  Label *mpWarningColorLabel;
  QPushButton *mpWarningColorButton;
  QColor mWarningColor;
  Label *mpErrorColorLabel;
  QPushButton *mpErrorColorButton;
  QColor mErrorColor;
public slots:
  void pickNotificationColor();
  void pickWarningColor();
  void pickErrorColor();
};

class NotificationsPage : public QWidget
{
  Q_OBJECT
public:
  NotificationsPage(OptionsDialog *pOptionsDialog);
  QCheckBox* getQuitApplicationCheckBox();
  QCheckBox* getItemDroppedOnItselfCheckBox();
  QCheckBox* getReplaceableIfPartialCheckBox();
  QCheckBox* getInnerModelNameChangedCheckBox();
  QCheckBox* getSaveModelForBitmapInsertionCheckBox();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpNotificationsGroupBox;
  QCheckBox *mpQuitApplicationCheckBox;
  QCheckBox *mpItemDroppedOnItselfCheckBox;
  QCheckBox *mpReplaceableIfPartialCheckBox;
  QCheckBox *mpInnerModelNameChangedCheckBox;
  QCheckBox *mpSaveModelForBitmapInsertionCheckBox;
};

class LineStylePage : public QWidget
{
  Q_OBJECT
public:
  LineStylePage(OptionsDialog *pOptionsDialog);
  void setLineColor(QColor color);
  QColor getLineColor();
  void setLinePickColorButtonIcon();
  void setLinePattern(QString pattern);
  QString getLinePattern();
  void setLineThickness(qreal thickness);
  qreal getLineThickness();
  void setLineStartArrow(QString startArrow);
  QString getLineStartArrow();
  void setLineEndArrow(QString endArrow);
  QString getLineEndArrow();
  void setLineArrowSize(qreal size);
  qreal getLineArrowSize();
  void setLineSmooth(bool smooth);
  bool getLineSmooth();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpLineStyleGroupBox;
  Label *mpLineColorLabel;
  QPushButton *mpLinePickColorButton;
  QColor mLineColor;
  Label *mpLinePatternLabel;
  QComboBox *mpLinePatternComboBox;
  Label *mpLineThicknessLabel;
  DoubleSpinBox *mpLineThicknessSpinBox;
  Label *mpLineStartArrowLabel;
  QComboBox *mpLineStartArrowComboBox;
  Label *mpLineEndArrowLabel;
  QComboBox *mpLineEndArrowComboBox;
  Label *mpLineArrowSizeLabel;
  DoubleSpinBox *mpLineArrowSizeSpinBox;
  Label *mpLineSmoothLabel;
  QCheckBox *mpLineSmoothCheckBox;
public slots:
  void linePickColor();
};

class FillStylePage : public QWidget
{
  Q_OBJECT
public:
  FillStylePage(OptionsDialog *pOptionsDialog);
  void setFillColor(QColor color);
  QColor getFillColor();
  void setFillPickColorButtonIcon();
  void setFillPattern(QString pattern);
  QString getFillPattern();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpFillStyleGroupBox;
  Label *mpFillColorLabel;
  QPushButton *mpFillPickColorButton;
  QColor mFillColor;
  Label *mpFillPatternLabel;
  QComboBox *mpFillPatternComboBox;
public slots:
  void fillPickColor();
};

class PlottingPage : public QWidget
{
  Q_OBJECT
public:
  PlottingPage(OptionsDialog *pOptionsDialog);
  void setPlottingViewMode(QString value);
  QString getPlottingViewMode();
  QCheckBox* getAutoScaleCheckBox() {return mpAutoScaleCheckBox;}
  void setCurvePattern(int pattern);
  int getCurvePattern();
  void setCurveThickness(qreal thickness);
  qreal getCurveThickness();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  QCheckBox *mpAutoScaleCheckBox;
  QGroupBox *mpPlottingViewModeGroupBox;
  QRadioButton *mpPlottingTabbedViewRadioButton;
  QRadioButton *mpPlottingSubWindowViewRadioButton;
  QGroupBox *mpCurveStyleGroupBox;
  Label *mpCurvePatternLabel;
  QComboBox *mpCurvePatternComboBox;
  Label *mpCurveThicknessLabel;
  DoubleSpinBox *mpCurveThicknessSpinBox;
};

class FigaroPage : public QWidget
{
  Q_OBJECT
public:
  FigaroPage(OptionsDialog *pOptionsDialog);
  QLineEdit* getFigaroDatabaseFileTextBox() {return mpFigaroDatabaseFileTextBox;}
  QLineEdit* getFigaroOptionsTextBox() {return mpFigaroOptionsFileTextBox;}
  QLineEdit* getFigaroProcessTextBox() {return mpFigaroProcessTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpFigaroGroupBox;
  Label *mpFigaroDatabaseFileLabel;
  QLineEdit *mpFigaroDatabaseFileTextBox;
  QPushButton *mpBrowseFigaroDatabaseFileButton;
  Label *mpFigaroOptionsFileLabel;
  QLineEdit *mpFigaroOptionsFileTextBox;
  QPushButton *mpBrowseFigaroOptionsFileButton;
  Label *mpFigaroProcessLabel;
  QLineEdit *mpFigaroProcessTextBox;
  QPushButton *mpBrowseFigaroProcessButton;
private slots:
  void browseFigaroLibraryFile();
  void browseFigaroOptionsFile();
  void browseFigaroProcessFile();
};

class DebuggerPage : public QWidget
{
  Q_OBJECT
public:
  DebuggerPage(OptionsDialog *pOptionsDialog);
  void setGDBPath(QString path);
  QString getGDBPath();
  QSpinBox* getGDBCommandTimeoutSpinBox() {return mpGDBCommandTimeoutSpinBox;}
  QSpinBox* getGDBOutputLimitSpinBox() {return mpGDBOutputLimitSpinBox;}
  QCheckBox* getDisplayCFramesCheckBox() {return mpDisplayCFramesCheckBox;}
  QCheckBox* getDisplayUnknownFramesCheckBox() {return mpDisplayUnknownFramesCheckBox;}
  QCheckBox* getClearOutputOnNewRunCheckBox() {return mpClearOutputOnNewRunCheckBox;}
  QCheckBox* getClearLogOnNewRunCheckBox() {return mpClearLogOnNewRunCheckBox;}
  QCheckBox* getAlwaysShowTransformationsCheckBox() {return mpAlwaysShowTransformationsCheckBox;}
  QCheckBox* getGenerateOperationsCheckBox() {return mpGenerateOperationsCheckBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpAlgorithmicDebuggerGroupBox;
  Label *mpGDBPathLabel;
  QLineEdit *mpGDBPathTextBox;
  QPushButton *mpGDBPathBrowseButton;
  Label *mpGDBCommandTimeoutLabel;
  QSpinBox *mpGDBCommandTimeoutSpinBox;
  Label *mpGDBOutputLimitLabel;
  QSpinBox *mpGDBOutputLimitSpinBox;
  QCheckBox *mpDisplayCFramesCheckBox;
  QCheckBox *mpDisplayUnknownFramesCheckBox;
  QCheckBox *mpClearOutputOnNewRunCheckBox;
  QCheckBox *mpClearLogOnNewRunCheckBox;
  QGroupBox *mpTransformationalDebuggerGroupBox;
  QCheckBox *mpAlwaysShowTransformationsCheckBox;
  QCheckBox *mpGenerateOperationsCheckBox;
public slots:
  void browseGDBPath();
};

class FMIPage : public QWidget
{
  Q_OBJECT
public:
  FMIPage(OptionsDialog *pOptionsDialog);
  void setFMIExportVersion(double version);
  double getFMIExportVersion();
  void setFMIExportType(QString type);
  QString getFMIExportType();
  QLineEdit* getFMUNameTextBox() {return mpFMUNameTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpExportGroupBox;
  QGroupBox *mpVersionGroupBox;
  QRadioButton *mpVersion1RadioButton;
  QRadioButton *mpVersion2RadioButton;
  QGroupBox *mpTypeGroupBox;
  QRadioButton *mpModelExchangeRadioButton;
  QRadioButton *mpCoSimulationRadioButton;
  QRadioButton *mpModelExchangeCoSimulationRadioButton;
  Label *mpFMUNameLabel;
  QLineEdit *mpFMUNameTextBox;
};

class TLMPage : public QWidget
{
  Q_OBJECT
public:
  TLMPage(OptionsDialog *pOptionsDialog);
  QLineEdit* getTLMPluginPathTextBox() {return mpTLMPluginPathTextBox;}
  QLineEdit* getTLMManagerProcessTextBox() {return mpTLMManagerProcessTextBox;}
  QLineEdit* getTLMMonitorProcessTextBox() {return mpTLMMonitorProcessTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
  Label *mpTLMPluginPathLabel;
  QLineEdit *mpTLMPluginPathTextBox;
  QPushButton *mpBrowseTLMPluginPathButton;
  Label *mpTLMManagerProcessLabel;
  QLineEdit *mpTLMManagerProcessTextBox;
  QPushButton *mpBrowseTLMManagerProcessButton;
  Label *mpTLMMonitorProcessLabel;
  QLineEdit *mpTLMMonitorProcessTextBox;
  QPushButton *mpBrowseTLMMonitorProcessButton;
private slots:
  void browseTLMPluginPath();
  void browseTLMManagerProcess();
  void browseTLMMonitorProcess();
};

class TLMEditorPage : public QWidget
{
  Q_OBJECT
public:
  TLMEditorPage(OptionsDialog *pOptionsDialog);
  QComboBox *getTabPolicyComboBox() {return mpTabPolicyComboBox;}
  QSpinBox *getTabSizeSpinBox() {return mpTabSizeSpinBox;}
  QSpinBox *getIndentSpinBox() {return mpIndentSpinBox;}
  QCheckBox* getSyntaxHighlightingCheckbox() {return mpSyntaxHighlightingCheckbox;}
  QCheckBox* getLineWrappingCheckbox() {return mpLineWrappingCheckbox;}
  QFontComboBox* getFontFamilyComboBox() {return mpFontFamilyComboBox;}
  DoubleSpinBox* getFontSizeSpinBox() {return mpFontSizeSpinBox;}
  void addListItems();
  void setTextRuleColor(QColor color);
  QColor getTextRuleColor(){return mTextColor;}
  void setQuotesRuleColor(QColor color);
  QColor getQuotesRuleColor(){return mQuotesColor;}
  void setCommentRuleColor(QColor color);
  QColor getCommentRuleColor(){return mCommentColor;}
  void setTagRuleColor(QColor color);
  QColor getTagRuleColor(){return mTagColor;}
  void setElementRuleColor(QColor color);
  QColor getElementRuleColor(){return mElementColor;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpTabsAndIndentation;
  Label *mpTabPolicyLabel;
  QComboBox *mpTabPolicyComboBox;
  Label *mpTabSizeLabel;
  QSpinBox *mpTabSizeSpinBox;
  Label *mpIndentSizeLabel;
  QSpinBox *mpIndentSpinBox;
  QGroupBox *mpSyntaxHighlightAndTextWrappingGroupBox;
  QCheckBox *mpSyntaxHighlightingCheckbox;
  QCheckBox *mpLineWrappingCheckbox;
  QGroupBox *mpFontColorsGroupBox;
  Label *mpFontFamilyLabel;
  QFontComboBox *mpFontFamilyComboBox;
  Label *mpFontSizeLabel;
  DoubleSpinBox *mpFontSizeSpinBox;
  Label *mpItemsLabel;
  QListWidget *mpItemsList;
  Label *mpItemColorLabel;
  QPushButton *mpItemColorPickButton;
  Label *mpPreviewLabel;
  QPlainTextEdit *mpPreviewPlainTextBox;
  QColor mTextColor;
  QListWidgetItem *mpTextItem;
  QColor mQuotesColor;
  QListWidgetItem *mpQuotesItem;
  QColor mCommentColor;
  QListWidgetItem *mpCommentItem;
  QColor mTagColor;
  QListWidgetItem *mpTagItem;
  QColor mElementColor;
  QListWidgetItem *mpElementItem;
signals:
  void updatePreview();
public slots:
  void setLineWrapping();
  void pickColor();
};

#endif // OPTIONSDIALOG_H
