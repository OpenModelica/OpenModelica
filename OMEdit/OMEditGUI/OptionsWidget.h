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

#ifndef OPTIONSWIDGET_H
#define OPTIONSWIDGET_H

#include "mainwindow.h"

class MainWindow;

class ModelicaTextSettings
{
public:
    ModelicaTextSettings();
    void setFontFamily(QString fontFamily);
    QString getFontFamily();
    void setFontSize(int fontSize);
    int getFontSize();
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
    int mFontSize;
    QColor mTextRuleColor;
    QColor mNumberRuleColor;
    QColor mKeyWordRuleColor;
    QColor mTypeRuleColor;
    QColor mFunctionRuleColor;
    QColor mQuotesRuleColor;
    QColor mCommentRuleColor;
};

class GeneralSettingsPage;
class ModelicaTextEditorPage;
class PenStylePage;
class BrushStylePage;

class OptionsWidget : public QDialog
{
    Q_OBJECT
public:
    OptionsWidget(MainWindow *pParent);
    void readSettings();
    void readGeneralSettings();
    void readModelicaTextSettings();
    void readPenStyleSettings();
    void readBrushStyleSettings();
    void saveGeneralSettings();
    void saveModelicaTextSettings();
    void savePenStyleSettings();
    void saveBrushStyleSettings();
    void setUpDialog();
    void addListItems();
    void createPages();

    MainWindow *mpParentMainWindow;
    ModelicaTextSettings *mpModelicaTextSettings;
    GeneralSettingsPage *mpGeneralSettingsPage;
    ModelicaTextEditorPage *mpModelicaTextEditorPage;
    PenStylePage *mpPenStylePage;
    BrushStylePage *mpBrushStylePage;
signals:
    void modelicaTextSettingsChanged();
public slots:
    void changePage(QListWidgetItem *current, QListWidgetItem *previous);
    void reject();
    void saveSettings();
private:
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
    GeneralSettingsPage(OptionsWidget *pParent);
    QString getViewMode();
    void setViewMode(QString value);

    OptionsWidget *mpParentOptionsWidget;
private:
    QGroupBox *mpPlottingGroup;
    QLabel *mpViewModeLabel;
    QRadioButton *mpTabbedViewRadioButton;
    QRadioButton *mpSubWindowViewRadioButton;
};

class ModelicaTextEditorPage : public QWidget
{
    Q_OBJECT
public:
    ModelicaTextEditorPage(OptionsWidget *pParent);
    void addListItems();
    QString getPreviewText();
    void createFontSizeComboBox();
    void initializeFields();

    OptionsWidget *mpParentOptionsWidget;
private:
    QGroupBox *mpFontColorsGroup;
    QLabel *mpFontFamilyLabel;
    QFontComboBox *mpFontFamilyComboBox;
    QLabel *mpFontSizeLabel;
    QComboBox *mpFontSizeComboBox;
    QLabel *mpItemsLabel;
    QListWidget *mpItemsList;
    QLabel *mpItemColorLabel;
    QPushButton *mpItemColorPickButton;
    QLabel *mpPreviewLabel;
    QTextEdit *mpPreviewTextBox;

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
    void fontSizeChanged(int index);
    void pickColor();
};

class PenStylePage : public QWidget
{
    Q_OBJECT
public:
    PenStylePage(OptionsWidget *pParent);
    void setPenColor(QColor color);
    QColor getPenColor();
    void setPenPattern(QString pattern);
    QString getPenPatternString();
    Qt::PenStyle getPenPattern();
    void setPenThickness(double thickness);
    double getPenThickness();
    void setPenSmooth(bool smooth);
    bool getPenSmooth();
    void setNoColorCheckBox(bool state);
    bool getNoColorCheckBox();
    void setColorViewerPixmap(QColor color);

    OptionsWidget *mpParentOptionsWidget;
private:
    QGroupBox *mpPenStyleGroup;
    QLabel *mpColorLabel;
    QLabel *mpColorViewerLabel;
    QPushButton *mpColorPickButton;
    QCheckBox *mpNoColorCheckBox;
    QColor mPenColor;
    QString mPenColorString;
    QLabel *mpPatternLabel;
    QComboBox *mpPatternsComboBox;
    QLabel *mpThicknessLabel;
    QDoubleSpinBox *mpThicknessSpinBox;
    QLabel *mpArrowLabel;
    QComboBox *mpArrowComboBox;
    QLabel *mpSmoothLabel;
    QCheckBox *mpSmoothCheckBox;
public slots:
    void pickColor();
    void noColorChecked(int state);
};

class BrushStylePage : public QWidget
{
    Q_OBJECT
public:
    BrushStylePage(OptionsWidget *pParent);
    void setBrushColor(QColor color);
    QColor getBrushColor();
    void setBrushPattern(QString pattern);
    QString getBrushPatternString();
    Qt::BrushStyle getBrushPattern();
    void setNoColorCheckBox(bool state);
    bool getNoColorCheckBox();
    void setColorViewerPixmap(QColor color);

    OptionsWidget *mpParentOptionsWidget;
private:
    QGroupBox *mpBrushStyleGroup;
    QLabel *mpColorLabel;
    QLabel *mpColorViewerLabel;
    QPushButton *mpColorPickButton;
    QColor mBrushColor;
    QString mBrushColorString;
    QCheckBox *mpNoColorCheckBox;
    QLabel *mpPatternLabel;
    QComboBox *mpPatternsComboBox;
public slots:
    void pickColor();
    void noColorChecked(int state);
};

#endif // OPTIONSWIDGET_H
