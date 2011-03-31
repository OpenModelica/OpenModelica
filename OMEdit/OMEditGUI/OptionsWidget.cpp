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

#include "OptionsWidget.h"

ModelicaTextSettings::ModelicaTextSettings()
{
    // set default values, will be handy if we are unable to create the xml file
    setFontFamily(qApp->font().family());       // get system font
    //setFontFamily("Courier");
    setFontSize(10);
    setTextRuleColor(QColor(0, 0, 0));                // black
    setKeywordRuleColor(QColor(139, 0, 0));           // dark red
    setTypeRuleColor(QColor(255, 10, 10));            // red
    setFunctionRuleColor(QColor(0, 0, 255));          // blue
    setQuotesRuleColor(QColor(0, 139, 0));            // dark green
    setCommentRuleColor(QColor(0, 150, 0));           // dark green
    setNumberRuleColor(QColor(139, 0, 139));          // purple
}

void ModelicaTextSettings::setFontFamily(QString fontFamily)
{
    mFontFamily = fontFamily;
}

QString ModelicaTextSettings::getFontFamily()
{
    return mFontFamily;
}

void ModelicaTextSettings::setFontSize(int fontSize)
{
    mFontSize = fontSize;
}

int ModelicaTextSettings::getFontSize()
{
    return mFontSize;
}

void ModelicaTextSettings::setTextRuleColor(QColor color)
{
    mTextRuleColor = color;
}

QColor ModelicaTextSettings::getTextRuleColor()
{
    return mTextRuleColor;
}

void ModelicaTextSettings::setKeywordRuleColor(QColor color)
{
    mKeyWordRuleColor = color;
}

QColor ModelicaTextSettings::getNumberRuleColor()
{
    return mNumberRuleColor;
}

void ModelicaTextSettings::setNumberRuleColor(QColor color)
{
    mNumberRuleColor = color;
}

QColor ModelicaTextSettings::getKeywordRuleColor()
{
    return mKeyWordRuleColor;
}

void ModelicaTextSettings::setTypeRuleColor(QColor color)
{
    mTypeRuleColor = color;
}

QColor ModelicaTextSettings::getTypeRuleColor()
{
    return mTypeRuleColor;
}

void ModelicaTextSettings::setFunctionRuleColor(QColor color)
{
    mFunctionRuleColor = color;
}

QColor ModelicaTextSettings::getFunctionRuleColor()
{
    return mFunctionRuleColor;
}

void ModelicaTextSettings::setQuotesRuleColor(QColor color)
{
    mQuotesRuleColor = color;
}

QColor ModelicaTextSettings::getQuotesRuleColor()
{
    return mQuotesRuleColor;
}

void ModelicaTextSettings::setCommentRuleColor(QColor color)
{
    mCommentRuleColor = color;
}

QColor ModelicaTextSettings::getCommentRuleColor()
{
    return mCommentRuleColor;
}

OptionsWidget::OptionsWidget(MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint), settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "editor")
{
    mpParentMainWindow = pParent;
    mpModelicaTextSettings = new ModelicaTextSettings();

    setWindowTitle(QString(Helper::applicationName).append(" - Options"));
    setModal(true);

    // get the settings from the xml file
    readSettings();
    // set up the Options Dialog
    setUpDialog();
}

void OptionsWidget::readSettings()
{
    settings.sync();
    if (settings.contains("fontFamily"))
      mpModelicaTextSettings->setFontFamily(settings.value("fontFamily").toString());
    if (settings.contains("fontSize"))
      mpModelicaTextSettings->setFontSize(settings.value("fontSize").toInt());
    if (settings.contains("textRule/color"))
      mpModelicaTextSettings->setTextRuleColor(QColor(settings.value("textRule/color").toUInt()));
    if (settings.contains("keywordRule/color"))
      mpModelicaTextSettings->setKeywordRuleColor(QColor(settings.value("keywordRule/color").toUInt()));
    if (settings.contains("typeRule/color"))
      mpModelicaTextSettings->setTypeRuleColor(QColor(settings.value("typeRule/color").toUInt()));
    if (settings.contains("functionRule/color"))
      mpModelicaTextSettings->setFunctionRuleColor(QColor(settings.value("functionRule/color").toUInt()));
    if (settings.contains("quotesRule/color"))
      mpModelicaTextSettings->setQuotesRuleColor(QColor(settings.value("quotesRule/color").toUInt()));
    if (settings.contains("commentRule/color"))
      mpModelicaTextSettings->setCommentRuleColor(QColor(settings.value("commentRule/color").toUInt()));
    if (settings.contains("numberRule/color"))
      mpModelicaTextSettings->setNumberRuleColor(QColor(settings.value("numberRule/color").toUInt()));
}

void OptionsWidget::setUpDialog()
{
    mpOptionsList = new QListWidget;
    mpOptionsList->setViewMode(QListView::ListMode);
    mpOptionsList->setMovement(QListView::Static);
    mpOptionsList->setIconSize(Helper::iconSize);
    mpOptionsList->setMaximumWidth(150);
    mpOptionsList->setCurrentRow(0, QItemSelectionModel::Select);
    connect(mpOptionsList, SIGNAL(currentItemChanged(QListWidgetItem*,QListWidgetItem*)),
            SLOT(changePage(QListWidgetItem*,QListWidgetItem*)));

    // add items to options list
    addListItems();

    // create pages
    createPages();

    // Create the buttons
    mpOkButton = new QPushButton(tr("OK"));
    mpOkButton->setAutoDefault(true);
    connect(mpOkButton, SIGNAL(pressed()), SLOT(saveSettings()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    horizontalLayout->addWidget(mpOptionsList);
    horizontalLayout->addWidget(mpPagesWidget, 1);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addLayout(horizontalLayout, 0, 0);
    mainLayout->addWidget(mpButtonBox, 4, 0);

    setLayout(mainLayout);
}

void OptionsWidget::addListItems()
{
    QListWidgetItem *modelicaTextEditorItem = new QListWidgetItem(mpOptionsList);
    modelicaTextEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.png"));
    modelicaTextEditorItem->setText(tr("Modelica Text Editor"));
}

void OptionsWidget::createPages()
{
    mpPagesWidget = new QStackedWidget;
    mpPagesWidget->addWidget(new ModelicaTextEditorPage(this));
}

void OptionsWidget::changePage(QListWidgetItem *current, QListWidgetItem *previous)
{
    if (!current)
        current = previous;

    mpPagesWidget->setCurrentIndex(mpOptionsList->row(current));
}

void OptionsWidget::reject()
{
    // read the old settings from the file
    readSettings();
    // set the fields back to default values
    dynamic_cast<ModelicaTextEditorPage*>(mpPagesWidget->widget(0))->initializeFields();
    QDialog::reject();
}

void OptionsWidget::saveSettings()
{
    settings.setValue("fontFamily",mpModelicaTextSettings->getFontFamily());
    settings.setValue("fontSize",mpModelicaTextSettings->getFontSize());
    settings.setValue("textRule/color",mpModelicaTextSettings->getTextRuleColor().rgba());
    settings.setValue("keywordRule/color",mpModelicaTextSettings->getKeywordRuleColor().rgba());
    settings.setValue("typeRule/color",mpModelicaTextSettings->getTypeRuleColor().rgba());
    settings.setValue("functionRule/color",mpModelicaTextSettings->getFunctionRuleColor().rgba());
    settings.setValue("quotesRule/color",mpModelicaTextSettings->getQuotesRuleColor().rgba());
    settings.setValue("commentRule/color",mpModelicaTextSettings->getCommentRuleColor().rgba());
    settings.setValue("numberRule/color",mpModelicaTextSettings->getNumberRuleColor().rgba());
    settings.sync();
    // emit the signal so that all syntax highlighters are updated
    emit modelicaTextSettingsChanged();
    accept();
}

ModelicaTextEditorPage::ModelicaTextEditorPage(OptionsWidget *pParent)
    : QWidget(pParent)
{
    mpParentOptionsWidget = pParent;
    mpFontColorsGroup = new QGroupBox(tr("Font and Colors"));

    mpFontFamilyLabel = new QLabel(tr("Font Family:"));
    mpFontFamilyComboBox = new QFontComboBox;
    int currentIndex;
    currentIndex = mpFontFamilyComboBox->findText(mpParentOptionsWidget->mpModelicaTextSettings->getFontFamily(),
                                                  Qt::MatchExactly);
    mpFontFamilyComboBox->setCurrentIndex(currentIndex);
    connect(mpFontFamilyComboBox, SIGNAL(currentFontChanged(QFont)), SLOT(fontFamilyChanged(QFont)));

    mpFontSizeLabel = new QLabel(tr("Font Size:"));
    mpFontSizeComboBox = new QComboBox;
    createFontSizeComboBox();
    currentIndex = mpFontSizeComboBox->findText(QString::number(mpParentOptionsWidget->mpModelicaTextSettings->getFontSize()),
                                                Qt::MatchExactly);
    mpFontSizeComboBox->setCurrentIndex(currentIndex);
    connect(mpFontSizeComboBox, SIGNAL(currentIndexChanged(int)), SLOT(fontSizeChanged(int)));

    mpItemColorLabel = new QLabel(tr("Item Color:"));
    mpItemColorPickButton = new QPushButton(tr("Pick Color"));
    connect(mpItemColorPickButton, SIGNAL(pressed()), SLOT(pickColor()));

    mpItemsLabel = new QLabel(tr("Items:"));
    mpItemsList = new QListWidget;
    mpItemsList->setMaximumHeight(90);

    // Add items to list
    addListItems();

    // make first item in the list selected
    mpItemsList->setCurrentRow(0, QItemSelectionModel::Select);

    mpPreviewLabel = new QLabel(tr("Preview:"));
    mpPreviewTextBox = new QTextEdit;
    mpPreviewTextBox->setReadOnly(false);
    mpPreviewTextBox->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpPreviewTextBox->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpPreviewTextBox->setTabStopWidth(Helper::tabWidth);
    mpPreviewTextBox->setText(getPreviewText());

    ModelicaTextHighlighter *highlighter;
    highlighter = new ModelicaTextHighlighter(mpParentOptionsWidget->mpModelicaTextSettings,
                                              mpPreviewTextBox->document());
    connect(this, SIGNAL(updatePreview()), highlighter, SLOT(settingsChanged()));
    connect(mpParentOptionsWidget, SIGNAL(modelicaTextSettingsChanged()), highlighter, SLOT(settingsChanged()));

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(mpFontFamilyLabel, 0, 0);
    mainLayout->addWidget(mpFontSizeLabel, 0, 1);
    mainLayout->addWidget(mpFontFamilyComboBox, 1, 0);
    mainLayout->addWidget(mpFontSizeComboBox, 1, 1);
    mainLayout->addWidget(mpItemsLabel, 2, 0);
    mainLayout->addWidget(mpItemColorLabel, 2, 1);
    mainLayout->addWidget(mpItemsList, 3, 0);
    mainLayout->addWidget(mpItemColorPickButton, 3, 1, Qt::AlignTop);
    mainLayout->addWidget(mpPreviewLabel, 4, 0, 1, 2);
    mainLayout->addWidget(mpPreviewTextBox, 5, 0, 1, 2);
    mpFontColorsGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpFontColorsGroup);

    setLayout(layout);
}

void ModelicaTextEditorPage::addListItems()
{
    // don't change the text of items as it is being used in pickColor slot to identify the items
    mpTextItem = new QListWidgetItem(mpItemsList);
    mpTextItem->setText(tr("Text"));
    mpTextItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getTextRuleColor());

    mpNumberItem = new QListWidgetItem(mpItemsList);
    mpNumberItem->setText(tr("Number"));
    mpNumberItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getNumberRuleColor());

    mpKeywordItem = new QListWidgetItem(mpItemsList);
    mpKeywordItem->setText(tr("Keyword"));
    mpKeywordItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getKeywordRuleColor());

    mpTypeItem = new QListWidgetItem(mpItemsList);
    mpTypeItem->setText(tr("Type"));
    mpTypeItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getTypeRuleColor());

    mpFunctionItem = new QListWidgetItem(mpItemsList);
    mpFunctionItem->setText(tr("Function"));
    mpFunctionItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getFunctionRuleColor());

    mpQuotesItem = new QListWidgetItem(mpItemsList);
    mpQuotesItem->setText(tr("Quotes"));
    mpQuotesItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getQuotesRuleColor());

    mpCommentItem = new QListWidgetItem(mpItemsList);
    mpCommentItem->setText(tr("Comment"));
    mpCommentItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getCommentRuleColor());
}

QString ModelicaTextEditorPage::getPreviewText()
{
    QString previewText;
    previewText.append("class HelloWorld /* block\n"
                       "comment */\n"
                       "\tReal x(start = 1); // Line comment\n"
                       "\tparameter Real a = 1.573;\n"
                       "\tString str = \"a\\\"bc\n"
                       "123\";\n"
                       "equation\n"
                       "\tder(x) = - a * x;\n"
                       "end HelloWorld;\n");

    return previewText;
}

void ModelicaTextEditorPage::createFontSizeComboBox()
{
    QStringList sizesList;
    sizesList << "6" << "7" << "8" << "9" << "10" << "11" << "12"
              << "14" << "16" << "18" << "20" << "22" << "24" << "26" << "28"
              << "36" << "48" << "72";
    mpFontSizeComboBox->addItems(sizesList);
}

void ModelicaTextEditorPage::initializeFields()
{
    int currentIndex;
    // select font family item
    currentIndex = mpFontFamilyComboBox->findText(mpParentOptionsWidget->mpModelicaTextSettings->getFontFamily(),
                                                  Qt::MatchExactly);
    mpFontFamilyComboBox->setCurrentIndex(currentIndex);
    // select font size item
    currentIndex = mpFontSizeComboBox->findText(QString::number(mpParentOptionsWidget->mpModelicaTextSettings->getFontSize()),
                                                Qt::MatchExactly);
    mpFontSizeComboBox->setCurrentIndex(currentIndex);
    // make first item in the list selected
    mpItemsList->setCurrentRow(0, QItemSelectionModel::Select);
    // refresh the preview textbox
    mpPreviewTextBox->setText(getPreviewText());
    // update list items
    mpTextItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getTextRuleColor());
    mpNumberItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getNumberRuleColor());
    mpKeywordItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getKeywordRuleColor());
    mpTypeItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getTypeRuleColor());
    mpFunctionItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getFunctionRuleColor());
    mpQuotesItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getQuotesRuleColor());
    mpCommentItem->setForeground(mpParentOptionsWidget->mpModelicaTextSettings->getCommentRuleColor());
}

void ModelicaTextEditorPage::fontFamilyChanged(QFont font)
{
    mpParentOptionsWidget->mpModelicaTextSettings->setFontFamily(font.family());
    emit updatePreview();
}

void ModelicaTextEditorPage::fontSizeChanged(int index)
{
    mpParentOptionsWidget->mpModelicaTextSettings->setFontSize(mpFontSizeComboBox->itemText(index).toInt());
    emit updatePreview();
}

void ModelicaTextEditorPage::pickColor()
{
    QColor color = QColorDialog::getColor();
    QListWidgetItem *item = mpItemsList->currentItem();
    // if item is text item
    if (item->text().toLower().compare("text") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setTextRuleColor(color);
    }
    else if (item->text().toLower().compare("keyword") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setKeywordRuleColor(color);
    }
    else if(item->text().toLower().compare("type") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setTypeRuleColor(color);
    }
    else if(item->text().toLower().compare("function") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setFunctionRuleColor(color);
    }
    else if(item->text().toLower().compare("quotes") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setQuotesRuleColor(color);
    }
    else if(item->text().toLower().compare("comment") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setCommentRuleColor(color);
    }
    else if(item->text().toLower().compare("number") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setNumberRuleColor(color);
    }
    // change the color of item
    item->setForeground(color);
    emit updatePreview();
}
