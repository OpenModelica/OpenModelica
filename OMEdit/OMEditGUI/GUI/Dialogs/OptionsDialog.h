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
class ModelicaTextSettings;
class ModelicaTextEditorPage;
class GraphicalViewsPage;
class SimulationPage;
class NotificationsPage;
class LineStylePage;
class FillStylePage;
class CurveStylePage;
class FigaroPage;

class OptionsDialog : public QDialog
{
  Q_OBJECT
public:
  OptionsDialog(MainWindow *pParent);
  ~OptionsDialog();
  void readSettings();
  void readGeneralSettings();
  void readLibrariesSettings();
  void readModelicaTextSettings();
  void readGraphicalViewsSettings();
  void readSimulationSettings();
  void readNotificationsSettings();
  void readLineStyleSettings();
  void readFillStyleSettings();
  void readCurveStyleSettings();
  void readFigaroSettings();
  void saveGeneralSettings();
  void saveLibrariesSettings();
  void saveModelicaTextSettings();
  void saveGraphicalViewsSettings();
  void saveSimulationSettings();
  void saveNotificationsSettings();
  void saveLineStyleSettings();
  void saveFillStyleSettings();
  void saveCurveStyleSettings();
  void saveFigaroSettings();
  void setUpDialog();
  void addListItems();
  void createPages();
  MainWindow* getMainWindow();
  GeneralSettingsPage* getGeneralSettingsPage();
  ModelicaTextSettings* getModelicaTextSettings();
  ModelicaTextEditorPage* getModelicaTextEditorPage();
  GraphicalViewsPage* getGraphicalViewsPage();
  SimulationPage* getSimulationPage();
  NotificationsPage* getNotificationsPage();
  LineStylePage* getLineStylePage();
  FillStylePage* getFillStylePage();
  CurveStylePage* getCurveStylePage();
  FigaroPage* getFigaroPage();
signals:
  void modelicaTextSettingsChanged();
  void updateLineWrapping();
public slots:
  void changePage(QListWidgetItem *current, QListWidgetItem *previous);
  void reject();
  void saveSettings();
private:
  MainWindow *mpMainWindow;
  GeneralSettingsPage *mpGeneralSettingsPage;
  LibrariesPage *mpLibrariesPage;
  ModelicaTextSettings *mpModelicaTextSettings;
  ModelicaTextEditorPage *mpModelicaTextEditorPage;
  GraphicalViewsPage *mpGraphicalViewsPage;
  SimulationPage *mpSimulationPage;
  NotificationsPage *mpNotificationsPage;
  LineStylePage *mpLineStylePage;
  FillStylePage *mpFillStylePage;
  CurveStylePage *mpCurveStylePage;
  FigaroPage *mpFigaroPage;
  QSettings mSettings;
  QListWidget *mpOptionsList;
  QStackedWidget *mpPagesWidget;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
};

class GeneralSettingsPage : public QWidget
{
  Q_OBJECT
public:
  GeneralSettingsPage(OptionsDialog *pParent);
  QComboBox* getLanguageComboBox();
  void setWorkingDirectory(QString value);
  QString getWorkingDirectory();
  void setPreserveUserCustomizations(bool value);
  bool getPreserveUserCustomizations();
  void setShowProtectedClasses(bool value);
  bool getShowProtectedClasses();
  void setModelingViewMode(QString value);
  QString getModelingViewMode();
  void setPlottingViewMode(QString value);
  QString getPlottingViewMode();
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
  QCheckBox *mpPreserveUserCustomizations;
  QGroupBox *mpLibrariesBrowserGroupBox;
  QCheckBox *mpShowProtectedClasses;
  QGroupBox *mpModelingViewModeGroupBox;
  QRadioButton *mpModelingTabbedViewRadioButton;
  QRadioButton *mpModelingSubWindowViewRadioButton;
  QGroupBox *mpPlottingViewModeGroupBox;
  QRadioButton *mpPlottingTabbedViewRadioButton;
  QRadioButton *mpPlottingSubWindowViewRadioButton;
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
  void autoSaveIntervalValueChanged(int value);
};

class LibrariesPage : public QWidget
{
  Q_OBJECT
public:
  LibrariesPage(OptionsDialog *pParent);
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
  Label *mpLibrariesNoteLabel;
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
  AddSystemLibraryDialog(LibrariesPage *pParent);
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
  AddUserLibraryDialog(LibrariesPage *pParent);
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

class ModelicaTextSettings
{
public:
  ModelicaTextSettings();
  void setFontFamily(QString fontFamily);
  QString getFontFamily();
  void setFontSize(double fontSize);
  double getFontSize();
  void setTextRuleColor(QColor color);
  QColor getTextRuleColor();
  void setNumberRuleColor(QColor color);
  QColor getNumberRuleColor();
  void setKeywordRuleColor(QColor color);
  QColor getKeywordRuleColor();
  void setTypeRuleColor(QColor color);
  QColor getTypeRuleColor();
  void setFunctionRuleColor(QColor color);
  QColor getFunctionRuleColor();
  void setQuotesRuleColor(QColor color);
  QColor getQuotesRuleColor();
  void setCommentRuleColor(QColor color);
  QColor getCommentRuleColor();
private:
  QString mFontFamily;
  double mFontSize;
  QColor mTextRuleColor;
  QColor mNumberRuleColor;
  QColor mKeyWordRuleColor;
  QColor mTypeRuleColor;
  QColor mFunctionRuleColor;
  QColor mQuotesRuleColor;
  QColor mCommentRuleColor;
};

class ModelicaTextEditorPage : public QWidget
{
  Q_OBJECT
public:
  ModelicaTextEditorPage(OptionsDialog *pParent);
  void addListItems();
  QString getPreviewText();
  void initializeFields();
  QCheckBox* getSyntaxHighlightingCheckbox();
  QCheckBox* getLineWrappingCheckbox();
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpGeneralGroupBox;
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
  QListWidgetItem *mpTextItem;
  QListWidgetItem *mpNumberItem;
  QListWidgetItem *mpKeywordItem;
  QListWidgetItem *mpTypeItem;
  QListWidgetItem *mpFunctionItem;
  QListWidgetItem *mpQuotesItem;
  QListWidgetItem *mpCommentItem;
signals:
  void updatePreview();
public slots:
  void fontFamilyChanged(QFont font);
  void fontSizeChanged(double newValue);
  void pickColor();
};

class GraphicalViewsPage : public QWidget
{
  Q_OBJECT
public:
  GraphicalViewsPage(OptionsDialog *pParent);
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
  SimulationPage(OptionsDialog *pParent);
  QComboBox* getMatchingAlgorithmComboBox();
  QComboBox* getIndexReductionMethodComboBox();
  QLineEdit* getOMCFlagsTextBox();
  QCheckBox *getSaveClassBeforeSimulationCheckBox() {return mpSaveClassBeforeSimulationCheckBox;}
  QCheckBox* getAlwaysShowTransformationsCheckBox() {return mpAlwaysShowTransformationsCheckBox;}
  QCheckBox* getGenerateOperationsCheckBox() {return mpGenerateOperationsCheckBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpSimulationGroupBox;
  Label *mpMatchingAlgorithmLabel;
  QComboBox *mpMatchingAlgorithmComboBox;
  Label *mpIndexReductionMethodLabel;
  QComboBox *mpIndexReductionMethodComboBox;
  Label *mpOMCFlagsLabel;
  QLineEdit *mpOMCFlagsTextBox;
  QCheckBox *mpSaveClassBeforeSimulationCheckBox;
  QGroupBox *mpTransformationalDebuggerGroupBox;
  QCheckBox *mpAlwaysShowTransformationsCheckBox;
  QCheckBox *mpGenerateOperationsCheckBox;
};

class NotificationsPage : public QWidget
{
  Q_OBJECT
public:
  NotificationsPage(OptionsDialog *pParent);
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
  LineStylePage(OptionsDialog *pParent);
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
  FillStylePage(OptionsDialog *pParent);
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

class CurveStylePage : public QWidget
{
  Q_OBJECT
public:
  CurveStylePage(OptionsDialog *pParent);
  void setCurvePattern(int pattern);
  int getCurvePattern();
  void setCurveThickness(qreal thickness);
  qreal getCurveThickness();
private:
  OptionsDialog *mpOptionsDialog;
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
  FigaroPage(OptionsDialog *pParent);
  QLineEdit* getFigaroLibraryFileTextBox() {return mpFigaroLibraryFileTextBox;}
  QComboBox* getFigaroModeComboBox() {return mpFigaroModeComboBox;}
  QLineEdit* getFigaroProcessTextBox() {return mpFigaroProcessTextBox;}
private:
  OptionsDialog *mpOptionsDialog;
  QGroupBox *mpFigaroGroupBox;
  Label *mpFigaroLibraryFileLabel;
  QLineEdit *mpFigaroLibraryFileTextBox;
  QPushButton *mpBrowseFigaroLibraryFileButton;
  Label *mpFigaroModeLabel;
  QComboBox *mpFigaroModeComboBox;
  Label *mpFigaroProcessLabel;
  QLineEdit *mpFigaroProcessTextBox;
  QPushButton *mpBrowseFigaroProcessButton;
private slots:
  void browseFigaroLibraryFile();
  void browseFigaroProcessFile();
};

#endif // OPTIONSDIALOG_H
