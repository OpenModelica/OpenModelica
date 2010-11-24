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
    setFontFamily("Courier");
    setFontSize(8);
    setTextRuleColor("0, 0, 0");                // black
    setKeywordRuleColor("255, 0, 0");           // red
    setTypeRuleColor("0, 139, 0");              // dark green
    setFunctionRuleColor("0, 0, 255");          // blue
    setQuotesRuleColor("0, 139, 139");          // dark cyan
    setCommentRuleColor("139, 0, 0");           // dark red
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

void ModelicaTextSettings::setTextRuleColor(QString color)
{
    mTextRuleColor = color;
}

QColor ModelicaTextSettings::getTextRuleColor()
{
    QStringList list = mTextRuleColor.split(",", QString::SkipEmptyParts);
    int red = static_cast<QString>(list.at(0)).trimmed().toInt();
    int green = static_cast<QString>(list.at(1)).trimmed().toInt();
    int blue = static_cast<QString>(list.at(2)).trimmed().toInt();
    return QColor(red, green, blue);
}

void ModelicaTextSettings::setKeywordRuleColor(QString color)
{
    mKeyWordRuleColor = color;
}

QColor ModelicaTextSettings::getKeywordRuleColor()
{
    QStringList list = mKeyWordRuleColor.split(",", QString::SkipEmptyParts);
    int red = static_cast<QString>(list.at(0)).trimmed().toInt();
    int green = static_cast<QString>(list.at(1)).trimmed().toInt();
    int blue = static_cast<QString>(list.at(2)).trimmed().toInt();
    return QColor(red, green, blue);
}

void ModelicaTextSettings::setTypeRuleColor(QString color)
{
    mTypeRuleColor = color;
}

QColor ModelicaTextSettings::getTypeRuleColor()
{
    QStringList list = mTypeRuleColor.split(",", QString::SkipEmptyParts);
    int red = static_cast<QString>(list.at(0)).trimmed().toInt();
    int green = static_cast<QString>(list.at(1)).trimmed().toInt();
    int blue = static_cast<QString>(list.at(2)).trimmed().toInt();
    return QColor(red, green, blue);
}

void ModelicaTextSettings::setFunctionRuleColor(QString color)
{
    mFunctionRuleColor = color;
}

QColor ModelicaTextSettings::getFunctionRuleColor()
{
    QStringList list = mFunctionRuleColor.split(",", QString::SkipEmptyParts);
    int red = static_cast<QString>(list.at(0)).trimmed().toInt();
    int green = static_cast<QString>(list.at(1)).trimmed().toInt();
    int blue = static_cast<QString>(list.at(2)).trimmed().toInt();
    return QColor(red, green, blue);
}

void ModelicaTextSettings::setQuotesRuleColor(QString color)
{
    mQuotesRuleColor = color;
}

QColor ModelicaTextSettings::getQuotesRuleColor()
{
    QStringList list = mQuotesRuleColor.split(",", QString::SkipEmptyParts);
    int red = static_cast<QString>(list.at(0)).trimmed().toInt();
    int green = static_cast<QString>(list.at(1)).trimmed().toInt();
    int blue = static_cast<QString>(list.at(2)).trimmed().toInt();
    return QColor(red, green, blue);
}

void ModelicaTextSettings::setCommentRuleColor(QString color)
{
    mCommentRuleColor = color;
}

QColor ModelicaTextSettings::getCommentRuleColor()
{
    QStringList list = mCommentRuleColor.split(",", QString::SkipEmptyParts);
    int red = static_cast<QString>(list.at(0)).trimmed().toInt();
    int green = static_cast<QString>(list.at(1)).trimmed().toInt();
    int blue = static_cast<QString>(list.at(2)).trimmed().toInt();
    return QColor(red, green, blue);
}

OptionsWidget::OptionsWidget(MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    mpParentMainWindow = pParent;
    mpModelicaTextSettings = new ModelicaTextSettings();

    setWindowTitle(QString(Helper::applicationName).append(" - Options"));
    setModal(true);

    // get the settings from the xml file
    getSettings();
    // set up the Options Dialog
    setUpDialog();
}

void OptionsWidget::getSettings()
{
    QString filePath = QString(QDir::tempPath()).append("/").append(Helper::settingsFileName);
    QFile settingsFile(filePath);
    // check if the file exists, if it exists then get the settings
    if (!settingsFile.exists())
        createSettings(filePath);

    readSettings(filePath);
}

void OptionsWidget::readSettings(QString filePath)
{
    QDomDocument xmlDocument;
    QFile settingsFile(filePath);
    settingsFile.open(QIODevice::ReadOnly);

    if (!xmlDocument.setContent(&settingsFile))
    {
        settingsFile.close();
        return;
    }
    settingsFile.close();

    // parse the xml file
    QDomNodeList modelicaTextNodes = xmlDocument.elementsByTagName("ModelicaText");
    for (int i = 0 ; i < modelicaTextNodes.length() ; i++)
    {
        QDomElement modelicaTextElement = modelicaTextNodes.item(i).toElement();
        // font family element
        QDomElement element = modelicaTextElement.firstChildElement();
        mpModelicaTextSettings->setFontFamily(element.attribute("value"));
        // font size element
        element = element.nextSiblingElement();
        mpModelicaTextSettings->setFontSize(element.attribute("value").toInt());
        // highlight rules element
        element = element.nextSiblingElement();
        // TextRule Element
        element = element.firstChildElement();
        mpModelicaTextSettings->setTextRuleColor(element.attribute("value"));
        // KeywordRule Element
        element = element.nextSiblingElement();
        mpModelicaTextSettings->setKeywordRuleColor(element.attribute("value"));
        // TypeRule Element
        element = element.nextSiblingElement();
        mpModelicaTextSettings->setTypeRuleColor(element.attribute("value"));
        // FunctionRule Element
        element = element.nextSiblingElement();
        mpModelicaTextSettings->setFunctionRuleColor(element.attribute("value"));
        // QuotesRule Element
        element = element.nextSiblingElement();
        mpModelicaTextSettings->setQuotesRuleColor(element.attribute("value"));
        // CommentRule Element
        element = element.nextSiblingElement();
        mpModelicaTextSettings->setCommentRuleColor(element.attribute("value"));
    }
}

void OptionsWidget::createSettings(QString filePath)
{
    //! @todo need to modify it because it can be accessed by to instances at the same time
    QDomDocument xmlDocument;
    // create root element
    QDomElement rootElement = xmlDocument.createElement("root");
    xmlDocument.appendChild(rootElement);
    // create Modelica Text element
    QDomElement modelicaTextElement = xmlDocument.createElement("ModelicaText");
    rootElement.appendChild(modelicaTextElement);
    // create Font Family Element
    QDomElement fontFamilyElement = xmlDocument.createElement("FontFamily");
    fontFamilyElement.setAttribute("value", mpModelicaTextSettings->getFontFamily());
    modelicaTextElement.appendChild(fontFamilyElement);
    // create Font Family Element
    QDomElement fontSizeElement = xmlDocument.createElement("FontSize");
    fontSizeElement.setAttribute("value", mpModelicaTextSettings->getFontSize());
    modelicaTextElement.appendChild(fontSizeElement);
    // create Highlight Rules Element
    QDomElement highlightRulesElement = xmlDocument.createElement("HighlightRules");
    modelicaTextElement.appendChild(highlightRulesElement);
    // create Text Rule Element
    QDomElement textRuleElement = xmlDocument.createElement("TextRule");
    textRuleElement.setAttribute("value", QString::number(mpModelicaTextSettings->getTextRuleColor().red())
                                 .append(", ")
                                 .append(QString::number(mpModelicaTextSettings->getTextRuleColor().green()))
                                 .append(", ")
                                 .append(QString::number(mpModelicaTextSettings->getTextRuleColor().blue())));
    highlightRulesElement.appendChild(textRuleElement);
    // create Keyword Rule Element
    QDomElement keywordRuleElement = xmlDocument.createElement("KeywordRule");
    keywordRuleElement.setAttribute("value", QString::number(mpModelicaTextSettings->getKeywordRuleColor().red())
                                    .append(", ")
                                    .append(QString::number(mpModelicaTextSettings->getKeywordRuleColor().green()))
                                    .append(", ")
                                    .append(QString::number(mpModelicaTextSettings->getKeywordRuleColor().blue())));
    highlightRulesElement.appendChild(keywordRuleElement);
    // create Type Rule Element
    QDomElement typeRuleElement = xmlDocument.createElement("TypeRule");
    typeRuleElement.setAttribute("value", QString::number(mpModelicaTextSettings->getTypeRuleColor().red())
                                 .append(", ")
                                 .append(QString::number(mpModelicaTextSettings->getTypeRuleColor().green()))
                                 .append(", ")
                                 .append(QString::number(mpModelicaTextSettings->getTypeRuleColor().blue())));
    highlightRulesElement.appendChild(typeRuleElement);
    // create Function Rule Element
    QDomElement functionRuleElement = xmlDocument.createElement("FunctionRule");
    functionRuleElement.setAttribute("value", QString::number(mpModelicaTextSettings->getFunctionRuleColor().red())
                                     .append(", ")
                                     .append(QString::number(mpModelicaTextSettings->getFunctionRuleColor().green()))
                                     .append(", ")
                                     .append(QString::number(mpModelicaTextSettings->getFunctionRuleColor().blue())));
    highlightRulesElement.appendChild(functionRuleElement);
    // create Quotes Rule Element
    QDomElement quotesRuleElement = xmlDocument.createElement("QuotesRule");
    quotesRuleElement.setAttribute("value", QString::number(mpModelicaTextSettings->getQuotesRuleColor().red())
                                   .append(", ")
                                   .append(QString::number(mpModelicaTextSettings->getQuotesRuleColor().green()))
                                   .append(", ")
                                   .append(QString::number(mpModelicaTextSettings->getQuotesRuleColor().blue())));
    highlightRulesElement.appendChild(quotesRuleElement);
    // create Comment Rule Element
    QDomElement commentRuleElement = xmlDocument.createElement("CommentRule");
    commentRuleElement.setAttribute("value", QString::number(mpModelicaTextSettings->getCommentRuleColor().red())
                                    .append(", ")
                                    .append(QString::number(mpModelicaTextSettings->getCommentRuleColor().green()))
                                    .append(", ")
                                    .append(QString::number(mpModelicaTextSettings->getCommentRuleColor().blue())));
    highlightRulesElement.appendChild(commentRuleElement);

    QFile settingsFile(filePath);
    settingsFile.open(QIODevice::WriteOnly);
    QTextStream textStream(&settingsFile);
    textStream << xmlDocument.toString();
    settingsFile.close();
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
    QString filePath = QString(QDir::tempPath()).append("/").append(Helper::settingsFileName);
    readSettings(filePath);
    // set the fields back to default values
    dynamic_cast<ModelicaTextEditorPage*>(mpPagesWidget->widget(0))->initializeFields();
    QDialog::reject();
}

void OptionsWidget::saveSettings()
{
    // delete the settings file and create a new one
    QString filePath = QString(QDir::tempPath()).append("/").append(Helper::settingsFileName);
    QFile::remove(filePath);
    // create a new file now
    createSettings(filePath);
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
    mpPreviewTextBox->setReadOnly(true);
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
    previewText.append("class HelloWorld\n");
    previewText.append("\tReal x(start = 1);\n");
    previewText.append("\tparameter Real a = 1;\n");
    previewText.append("equation\n");
    previewText.append("\tder(x) = - a * x;\n");
    previewText.append("end HelloWorld;\n");

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
    // convert color to rgb string
    QString colorString = QString(QString::number(color.red())).append(", ")
                                  .append(QString::number(color.green())).append(", ")
                                  .append(QString::number(color.blue()));
    // if item is text item
    if (item->text().toLower().compare("text") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setTextRuleColor(colorString);
    }
    else if (item->text().toLower().compare("keyword") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setKeywordRuleColor(colorString);
    }
    else if(item->text().toLower().compare("type") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setTypeRuleColor(colorString);
    }
    else if(item->text().toLower().compare("function") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setFunctionRuleColor(colorString);
    }
    else if(item->text().toLower().compare("quotes") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setQuotesRuleColor(colorString);
    }
    else if(item->text().toLower().compare("comment") == 0)
    {
        mpParentOptionsWidget->mpModelicaTextSettings->setCommentRuleColor(colorString);
    }
    // change the color of item
    item->setForeground(color);
    emit updatePreview();
}
