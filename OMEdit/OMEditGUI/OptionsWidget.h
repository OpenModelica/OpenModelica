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

#include <QDomDocument>

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
    void setTextRuleColor(QString color);
    QColor getTextRuleColor();
    void setKeywordRuleColor(QString color);
    QColor getKeywordRuleColor();
    void setTypeRuleColor(QString color);
    QColor getTypeRuleColor();
    void setFunctionRuleColor(QString color);
    QColor getFunctionRuleColor();
    void setQuotesRuleColor(QString color);
    QColor getQuotesRuleColor();
    void setCommentRuleColor(QString color);
    QColor getCommentRuleColor();
private:
    QString mFontFamily;
    int mFontSize;
    QString mTextRuleColor;
    QString mKeyWordRuleColor;
    QString mTypeRuleColor;
    QString mFunctionRuleColor;
    QString mQuotesRuleColor;
    QString mCommentRuleColor;
};

class OptionsWidget : public QDialog
{
    Q_OBJECT
public:
    OptionsWidget(MainWindow *pParent);
    void getSettings();
    void readSettings(QString filePath);
    void createSettings(QString filePath);
    void setUpDialog();
    void addListItems();
    void createPages();

    MainWindow *mpParentMainWindow;
    ModelicaTextSettings *mpModelicaTextSettings;
signals:
    void modelicaTextSettingsChanged();
public slots:
    void changePage(QListWidgetItem *current, QListWidgetItem *previous);
    void reject();
    void saveSettings();
private:
    QListWidget *mpOptionsList;
    QStackedWidget *mpPagesWidget;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
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

#endif // OPTIONSWIDGET_H
