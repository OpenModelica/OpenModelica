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
 * Contributors 2011: Abhinn Kothari
 */

#include "OptionsWidget.h"

//! @class ModelicaTextSettings
//! @brief Defines the settings like font, style, keywords colors etc. for the Modelica Text.

//! Constructor
ModelicaTextSettings::ModelicaTextSettings()
{
    // This is a very convoluted way of asking for the default monospace font in Qt
    QFont font("I'm a font that does not exist, so that we will search for the style hint");
    font.setStyleHint(QFont::TypeWriter);
    QFontInfo info(font);
    // set default values, will be handy if we are unable to create the xml file
    setFontFamily(info.family());                     // get system font
    setFontSize(10);
    setTextRuleColor(QColor(0, 0, 0));                // black
    setKeywordRuleColor(QColor(139, 0, 0));           // dark red
    setTypeRuleColor(QColor(255, 10, 10));            // red
    setFunctionRuleColor(QColor(0, 0, 255));          // blue
    setQuotesRuleColor(QColor(0, 139, 0));            // dark green
    setCommentRuleColor(QColor(0, 150, 0));           // dark green
    setNumberRuleColor(QColor(139, 0, 139));          // purple
}

//! Sets the font for the Modelica Text.
//! @param fontFamily is the font to set.
void ModelicaTextSettings::setFontFamily(QString fontFamily)
{
    mFontFamily = fontFamily;
}

//! Returns the Modelica Text font.
//! @return mFontFamily the font family.
QString ModelicaTextSettings::getFontFamily()
{
    return mFontFamily;
}

//! Sets the font size for the Modelica Text.
//! @param fontSize is the font size to set.
void ModelicaTextSettings::setFontSize(int fontSize)
{
    mFontSize = fontSize;
}

//! Returns the Modelica Text font size.
//! @return mFontSize the font size.
int ModelicaTextSettings::getFontSize()
{
    return mFontSize;
}

//! Sets the color for the Modelica Text.
//! @param color is the color to set.
void ModelicaTextSettings::setTextRuleColor(QColor color)
{
    mTextRuleColor = color;
}

//! Returns the Modelica Text color.
//! @return mTextRuleColor the color.
QColor ModelicaTextSettings::getTextRuleColor()
{
    return mTextRuleColor;
}

//! Sets the color for the Modelica Text numbers.
//! @param color is the color to set.
void ModelicaTextSettings::setNumberRuleColor(QColor color)
{
    mNumberRuleColor = color;
}

//! Returns the Modelica Text numbers color.
//! @return mNumberRuleColor the color.
QColor ModelicaTextSettings::getNumberRuleColor()
{
    return mNumberRuleColor;
}

//! Sets the color for the Modelica Text keywords.
//! @param color is the color to set.
void ModelicaTextSettings::setKeywordRuleColor(QColor color)
{
    mKeyWordRuleColor = color;
}

//! Returns the Modelica Text keyword color.
//! @return mKeyWordRuleColor the color.
QColor ModelicaTextSettings::getKeywordRuleColor()
{
    return mKeyWordRuleColor;
}

//! Sets the color for the Modelica Text types.
//! @param color is the color to set.
void ModelicaTextSettings::setTypeRuleColor(QColor color)
{
    mTypeRuleColor = color;
}

//! Returns the Modelica Text types color.
//! @return mTypeRuleColor the color.
QColor ModelicaTextSettings::getTypeRuleColor()
{
    return mTypeRuleColor;
}

//! Sets the color for the Modelica Text functions.
//! @param color is the color to set.
void ModelicaTextSettings::setFunctionRuleColor(QColor color)
{
    mFunctionRuleColor = color;
}

//! Returns the Modelica Text functions color.
//! @return mFunctionRuleColor the color.
QColor ModelicaTextSettings::getFunctionRuleColor()
{
    return mFunctionRuleColor;
}

//! Sets the color for the Modelica Text quotes.
//! @param color is the color to set.
void ModelicaTextSettings::setQuotesRuleColor(QColor color)
{
    mQuotesRuleColor = color;
}

//! Returns the Modelica Text quotes color.
//! @return mQuotesRuleColor the color.
QColor ModelicaTextSettings::getQuotesRuleColor()
{
    return mQuotesRuleColor;
}

//! Sets the color for the Modelica Text comments.
//! @param color is the color to set.
void ModelicaTextSettings::setCommentRuleColor(QColor color)
{
    mCommentRuleColor = color;
}

//! Returns the Modelica Text comments color.
//! @return mCommentRuleColor the color.
QColor ModelicaTextSettings::getCommentRuleColor()
{
    return mCommentRuleColor;
}

//! @class OptionsWidget
//! @brief Creats an interface with options like Modelica Text, Pen Styles, Libraries etc.

//! Constructor
//! @param pParent is the pointer to MainWindow
OptionsWidget::OptionsWidget(MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint), mSettings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit")
{
    mpParentMainWindow = pParent;
    mpModelicaTextSettings = new ModelicaTextSettings();
    readModelicaTextSettings();

    setWindowTitle(QString(Helper::applicationName).append(" - Options"));
    setModal(true);

    mpGeneralSettingsPage = new GeneralSettingsPage(this);
    mpModelicaTextEditorPage = new ModelicaTextEditorPage(this);
    mpPenStylePage = new PenStylePage(this);
    mpBrushStylePage = new BrushStylePage(this);
    mpLibrariesPage = new LibrariesPage(this);
    // get the settings
    readSettings();
    // set up the Options Dialog
    setUpDialog();
}

//! Reads the settings from omedit.ini file.
void OptionsWidget::readSettings()
{
    mSettings.sync();
    readGeneralSettings();
    readModelicaTextSettings();
    readPenStyleSettings();
    readBrushStyleSettings();
    readLibrariesSettings();
}

//! Reads the General section settings from omedit.ini
void OptionsWidget::readGeneralSettings()
{
    if (mSettings.contains("plotting/viewmode"))
        mpGeneralSettingsPage->setViewMode(mSettings.value("plotting/viewmode").toString());
}

//! Reads the ModelicaText settings from omedit.ini
void OptionsWidget::readModelicaTextSettings()
{
    if (mSettings.contains("fontFamily"))
        mpModelicaTextSettings->setFontFamily(mSettings.value("fontFamily").toString());
    if (mSettings.contains("fontSize"))
        mpModelicaTextSettings->setFontSize(mSettings.value("fontSize").toInt());
    if (mSettings.contains("textRule/color"))
        mpModelicaTextSettings->setTextRuleColor(QColor(mSettings.value("textRule/color").toUInt()));
    if (mSettings.contains("keywordRule/color"))
        mpModelicaTextSettings->setKeywordRuleColor(QColor(mSettings.value("keywordRule/color").toUInt()));
    if (mSettings.contains("typeRule/color"))
        mpModelicaTextSettings->setTypeRuleColor(QColor(mSettings.value("typeRule/color").toUInt()));
    if (mSettings.contains("functionRule/color"))
        mpModelicaTextSettings->setFunctionRuleColor(QColor(mSettings.value("functionRule/color").toUInt()));
    if (mSettings.contains("quotesRule/color"))
        mpModelicaTextSettings->setQuotesRuleColor(QColor(mSettings.value("quotesRule/color").toUInt()));
    if (mSettings.contains("commentRule/color"))
        mpModelicaTextSettings->setCommentRuleColor(QColor(mSettings.value("commentRule/color").toUInt()));
    if (mSettings.contains("numberRule/color"))
        mpModelicaTextSettings->setNumberRuleColor(QColor(mSettings.value("numberRule/color").toUInt()));
}

//! Reads the PenStyle section settings from omedit.ini
void OptionsWidget::readPenStyleSettings()
{
    if (mSettings.contains("penstyle/color"))
    {
        if (mSettings.value("penstyle/color").toString().isEmpty())
        {
            mpPenStylePage->setPenColor(Qt::transparent);
            mpPenStylePage->setColorViewerPixmap(Qt::transparent);
        }
        else
        {
            mpPenStylePage->setPenColor(QColor(mSettings.value("penstyle/color").toUInt()));
            mpPenStylePage->setColorViewerPixmap(QColor(mSettings.value("penstyle/color").toUInt()));
        }
    }

    if (mSettings.contains("penstyle/pattern"))
        mpPenStylePage->setPenPattern(mSettings.value("penstyle/pattern").toString());
    if (mSettings.contains("penstyle/thickness"))
        mpPenStylePage->setPenThickness(mSettings.value("penstyle/thickness").toDouble());
    if (mSettings.contains("penstyle/smooth"))
        mpPenStylePage->setPenSmooth(mSettings.value("penstyle/smooth").toBool());
}

//! Reads the BrushStyle section settings from omedit.ini
void OptionsWidget::readBrushStyleSettings()
{
    if (mSettings.contains("brushstyle/color"))
    {
        if (mSettings.value("brushstyle/color").toString().isEmpty())
        {
            mpBrushStylePage->setBrushColor(Qt::transparent);
            mpBrushStylePage->setColorViewerPixmap(Qt::transparent);
        }
        else
        {
            mpBrushStylePage->setBrushColor(mSettings.value("brushstyle/color").toUInt());
            mpBrushStylePage->setColorViewerPixmap(QColor(mSettings.value("brushstyle/color").toUInt()));
        }
    }
    if (mSettings.contains("brushstyle/pattern"))
    {
        mpBrushStylePage->setBrushPattern(mSettings.value("brushstyle/pattern").toString());
        if(mpBrushStylePage->getBrushPattern()==Qt::NoBrush)
        {
            mpBrushStylePage->setBrushColor(Qt::transparent);
            mpBrushStylePage->setColorViewerPixmap(Qt::transparent);
            mpBrushStylePage->setNoColorCheckBox(true);
        }
    }

    if (mSettings.contains("brushstyle/color"))
    {
        if (mSettings.value("brushstyle/color").toString().isEmpty())
        {
            mpBrushStylePage->setBrushPattern("NoBrush");
        }
    }
}

//! Reads the Libraries section settings from omedit.ini
void OptionsWidget::readLibrariesSettings()
{
    int i = 0;
    while(i < mpLibrariesPage->getLibrariesTree()->topLevelItemCount())
    {
        qDeleteAll(mpLibrariesPage->getLibrariesTree()->topLevelItem(i)->takeChildren());
        delete mpLibrariesPage->getLibrariesTree()->topLevelItem(i);
        i = 0;   //Restart iteration
    }
    // read the settings and add libraries
    mSettings.beginGroup("libraries");
    QStringList libraries = mSettings.childKeys();
    foreach (QString lib, libraries)
    {
        QStringList values;
        values << lib << mSettings.value(lib).toString();
        mpLibrariesPage->getLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
    }
    mSettings.endGroup();
}

//! Saves the General section settings to omedit.ini
void OptionsWidget::saveGeneralSettings()
{
    mSettings.setValue("plotting/viewmode", mpGeneralSettingsPage->getViewMode());

    if (mpGeneralSettingsPage->getViewMode().compare("SubWindow") == 0)
        mpParentMainWindow->mpPlotWindowContainer->setViewMode(QMdiArea::SubWindowView);
    else
        mpParentMainWindow->mpPlotWindowContainer->setViewMode(QMdiArea::TabbedView);
}

//! Saves the ModelicaText settings to omedit.ini
void OptionsWidget::saveModelicaTextSettings()
{
    mSettings.setValue("fontFamily", mpModelicaTextSettings->getFontFamily());
    mSettings.setValue("fontSize", mpModelicaTextSettings->getFontSize());
    mSettings.setValue("textRule/color", mpModelicaTextSettings->getTextRuleColor().rgba());
    mSettings.setValue("keywordRule/color", mpModelicaTextSettings->getKeywordRuleColor().rgba());
    mSettings.setValue("typeRule/color", mpModelicaTextSettings->getTypeRuleColor().rgba());
    mSettings.setValue("functionRule/color", mpModelicaTextSettings->getFunctionRuleColor().rgba());
    mSettings.setValue("quotesRule/color", mpModelicaTextSettings->getQuotesRuleColor().rgba());
    mSettings.setValue("commentRule/color", mpModelicaTextSettings->getCommentRuleColor().rgba());
    mSettings.setValue("numberRule/color", mpModelicaTextSettings->getNumberRuleColor().rgba());
}

//! Saves the PenStyle section settings to omedit.ini
void OptionsWidget::savePenStyleSettings()
{
    if (mpPenStylePage->getPenColor() == Qt::transparent)
        mSettings.setValue("penstyle/color", tr(""));
    else
        mSettings.setValue("penstyle/color", mpPenStylePage->getPenColor().rgba());
    mSettings.setValue("penstyle/pattern", mpPenStylePage->getPenPatternString());
    mSettings.setValue("penstyle/thickness", mpPenStylePage->getPenThickness());
    mSettings.setValue("penstyle/smooth", mpPenStylePage->getPenSmooth());
}

//! Saves the BrushStyle section settings to omedit.ini
void OptionsWidget::saveBrushStyleSettings()
{
    if (mpBrushStylePage->getBrushColor() == Qt::transparent)
    {
        mSettings.setValue("brushstyle/color", tr(""));
        mSettings.setValue("brushstyle/pattern", tr("NoBrush"));
    }
    else
    {   mSettings.setValue("brushstyle/color", mpBrushStylePage->getBrushColor().rgba());
        mSettings.setValue("brushstyle/pattern", mpBrushStylePage->getBrushPatternString());
    }
}

//! Saves the Libraries section settings to omedit.ini
void OptionsWidget::saveLibrariesSettings()
{
    // read the settings and add libraries
    mSettings.beginGroup("libraries");
    foreach (QString lib, mSettings.childKeys())
    {
        mSettings.remove(lib);
    }

    QTreeWidgetItemIterator it(mpLibrariesPage->getLibrariesTree());
    while (*it)
    {
        QTreeWidgetItem *pItem = dynamic_cast<QTreeWidgetItem*>(*it);
        mSettings.setValue(pItem->text(0), pItem->text(1));
        ++it;
    }
    mSettings.endGroup();
}

//! Sets up the Options Widget dialog
void OptionsWidget::setUpDialog()
{
    mpOptionsList = new QListWidget;
    mpOptionsList->setViewMode(QListView::ListMode);
    mpOptionsList->setMovement(QListView::Static);
    mpOptionsList->setIconSize(Helper::iconSize);
    mpOptionsList->setMaximumWidth(175);
    mpOptionsList->setCurrentRow(0, QItemSelectionModel::Select);
    connect(mpOptionsList, SIGNAL(currentItemChanged(QListWidgetItem*,QListWidgetItem*)), SLOT(changePage(QListWidgetItem*,QListWidgetItem*)));
    // add items to options list
    addListItems();
    // create pages
    createPages();
    // Create the buttons
    mpOkButton = new QPushButton(tr("OK"));
    mpOkButton->setAutoDefault(true);
    connect(mpOkButton, SIGNAL(clicked()), SLOT(saveSettings()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));

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

//! Adds items to the list view of Options Widget
void OptionsWidget::addListItems()
{
    // General Settings Item
    QListWidgetItem *generalSettingsItem = new QListWidgetItem(mpOptionsList);
    generalSettingsItem->setIcon(QIcon(":/Resources/icons/preferences.png"));
    generalSettingsItem->setText(tr("General"));
    mpOptionsList->item(0)->setSelected(true);
    // Modelica Text Item
    QListWidgetItem *modelicaTextEditorItem = new QListWidgetItem(mpOptionsList);
    modelicaTextEditorItem->setIcon(QIcon(":/Resources/icons/modeltext.png"));
    modelicaTextEditorItem->setText(tr("Modelica Text Editor"));
    // Pen Style Item
    QListWidgetItem *penStyleItem = new QListWidgetItem(mpOptionsList);
    penStyleItem->setIcon(QIcon(":/Resources/icons/linestyle.png"));
    penStyleItem->setText(tr("Pen Style"));
    // Brush Style Item
    QListWidgetItem *brushStyleItem = new QListWidgetItem(mpOptionsList);
    brushStyleItem->setIcon(QIcon(":/Resources/icons/brushstyle.png"));
    brushStyleItem->setText(tr("Brush Style"));
    // Libraries Item
    QListWidgetItem *librariesItem = new QListWidgetItem(mpOptionsList);
    librariesItem->setIcon(QIcon(":/Resources/icons/libraries.png"));
    librariesItem->setText(tr("Libraries"));
}

//! Creates pages for the Options Widget. The pages are created as stacked widget and are mapped with mpOptionsList.
void OptionsWidget::createPages()
{
    mpPagesWidget = new QStackedWidget;
    mpPagesWidget->addWidget(mpGeneralSettingsPage);
    mpPagesWidget->addWidget(mpModelicaTextEditorPage);
    mpPagesWidget->addWidget(mpPenStylePage);
    mpPagesWidget->addWidget(mpBrushStylePage);
    mpPagesWidget->addWidget(mpLibrariesPage);
}

//! Change the page in Options Widget when the mpOptionsList currentItemChanged Signal is raised.
void OptionsWidget::changePage(QListWidgetItem *current, QListWidgetItem *previous)
{
    if (!current)
        current = previous;

    mpPagesWidget->setCurrentIndex(mpOptionsList->row(current));
}

//! Reimplementation of QWidget's reject function. If user reject the settings then set them back to original.
void OptionsWidget::reject()
{
    // read the old settings from the file
    readSettings();
    // set the fields back to default values
    mpModelicaTextEditorPage->initializeFields();
    QDialog::reject();
}

//! Saves the settings to omedit.ini file.
void OptionsWidget::saveSettings()
{
    saveGeneralSettings();
    saveModelicaTextSettings();
    // emit the signal so that all syntax highlighters are updated
    emit modelicaTextSettingsChanged();
    savePenStyleSettings();
    saveBrushStyleSettings();
    saveLibrariesSettings();
    mSettings.sync();
    accept();
}

//! @class GeneralSettingsPage
//! @brief Creats an interface for genaral settings.

//! Constructor
//! @param pParent is the pointer to OptionsWidget
GeneralSettingsPage::GeneralSettingsPage(OptionsWidget *pParent)
    : QWidget(pParent)
{
    mpParentOptionsWidget = pParent;

    mpPlottingGroup = new QGroupBox(tr("Plotting"));

    mpViewModeLabel = new QLabel(tr("View Mode:"));
    mpTabbedViewRadioButton = new QRadioButton(tr("Tabbed View"));
    mpTabbedViewRadioButton->setChecked(true);
    mpSubWindowViewRadioButton = new QRadioButton(tr("SubWindow View"));
    QButtonGroup *pViewModeGroup = new QButtonGroup;
    pViewModeGroup->addButton(mpTabbedViewRadioButton);
    pViewModeGroup->addButton(mpSubWindowViewRadioButton);

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpViewModeLabel, 0, 0);
    mainLayout->addWidget(mpTabbedViewRadioButton, 1, 0);
    mainLayout->addWidget(mpSubWindowViewRadioButton, 2, 0);
    mpPlottingGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpPlottingGroup);

    setLayout(layout);
}

//! Returns the view mode for plotting view.
//! @return view mode as string
//! @see setViewMode(QString value);
QString GeneralSettingsPage::getViewMode()
{
    if (mpSubWindowViewRadioButton->isChecked())
        return "SubWindow";
    else
        return "Tabbed";
}

//! Sets the view mode for plotting view.
//! @param value the view mode to set.
//! @see getViewMode();
void GeneralSettingsPage::setViewMode(QString value)
{
    if (value.compare("SubWindow") == 0)
        mpSubWindowViewRadioButton->setChecked(true);
    else
        mpTabbedViewRadioButton->setChecked(true);
}

//! @class ModelicaTextEditorPage
//! @brief Creats an interface for Modelica Text settings.

//! Constructor
//! @param pParent is the pointer to OptionsWidget
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
    connect(mpItemColorPickButton, SIGNAL(clicked()), SLOT(pickColor()));

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
    highlighter = new ModelicaTextHighlighter(mpParentOptionsWidget->mpModelicaTextSettings, mpPreviewTextBox->document());
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

//! Adds the Modelica Text settings rules to the mpItemsList.
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

//! Returns the preview text.
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

//! Creates the font size combo box.
void ModelicaTextEditorPage::createFontSizeComboBox()
{
    mpFontSizeComboBox->addItems(Helper::fontSizes.split(","));
}

//! Initialize all fields with default values.
void ModelicaTextEditorPage::initializeFields()
{
    int currentIndex;
    // select font family item
    currentIndex = mpFontFamilyComboBox->findText(mpParentOptionsWidget->mpModelicaTextSettings->getFontFamily(), Qt::MatchExactly);
    mpFontFamilyComboBox->setCurrentIndex(currentIndex);
    // select font size item
    currentIndex = mpFontSizeComboBox->findText(QString::number(mpParentOptionsWidget->mpModelicaTextSettings->getFontSize()), Qt::MatchExactly);
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

//! Changes the font family when mpFontFamilyComboBox currentFontChanged signal is raised.
void ModelicaTextEditorPage::fontFamilyChanged(QFont font)
{
    mpParentOptionsWidget->mpModelicaTextSettings->setFontFamily(font.family());
    emit updatePreview();
}

//! Changes the font size when mpFontSizeComboBox currentIndexChanged signal is raised.
void ModelicaTextEditorPage::fontSizeChanged(int index)
{
    mpParentOptionsWidget->mpModelicaTextSettings->setFontSize(mpFontSizeComboBox->itemText(index).toInt());
    emit updatePreview();
}

//! Picks a color for one of the Modelica Text Settings rules.
//! This method is called when mpColorPickButton clicked signal raised.
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

//! @class PenStylePage
//! @brief Creats an interface for PenStyle settings.

//! Constructor
//! @param pParent is the pointer to OptionsWidget
PenStylePage::PenStylePage(OptionsWidget *pParent)
    : QWidget(pParent)
{
    mpParentOptionsWidget = pParent;

    mpPenStyleGroup = new QGroupBox(tr("Pen Style"));

    mpColorLabel = new QLabel(tr("Color:"));
    mpColorViewerLabel = new QLabel(tr(""));
    mpColorPickButton = new QPushButton(tr("Pick Color"));
    connect(mpColorPickButton, SIGNAL(clicked()), SLOT(pickColor()));
    mpNoColorCheckBox = new QCheckBox(tr("No Color"));
    connect(mpNoColorCheckBox, SIGNAL(stateChanged(int)), SLOT(noColorChecked(int)));

    mpPatternLabel = new QLabel(tr("Pattern:"));
    mpPatternsComboBox = new QComboBox;
    mpPatternsComboBox->setIconSize(Helper::iconSize);
    mpPatternsComboBox->addItem(QIcon(Helper::solidPenIcon), Helper::solidPen, Helper::solidPenStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::dashPenIcon), Helper::dashPen, Helper::dashPenStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::dotPenIcon), Helper::dotPen, Helper::dotPenStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::dashDotPenIcon), Helper::dashDotPen, Helper::dashDotPenStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::dashDotDotPenIcon), Helper::dashDotDotPen, Helper::dashDotDotPenStyle);

    mpThicknessLabel = new QLabel(tr("Thickness:"));
    mpThicknessSpinBox = new QDoubleSpinBox;
    // change the locale to C so that decimal char is changed from ',' to '.'
    mpThicknessSpinBox->setLocale(QLocale("C"));
    mpThicknessSpinBox->setRange(0.25, 100.0);
    mpThicknessSpinBox->setSingleStep(0.5);

    mpSmoothLabel = new QLabel(tr("Smooth:"));
    mpSmoothCheckBox = new QCheckBox(tr("Bezier Curve"));

    // set default values
    setPenColor(Qt::blue);                     // blue
    setColorViewerPixmap(getPenColor());
    setPenPattern(tr("Solid"));                // Qt::SolidLine
    setPenThickness(0.25);
    setPenSmooth(false);

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpColorLabel, 0, 0);
    mainLayout->addWidget(mpColorViewerLabel, 0, 1);
    mainLayout->addWidget(mpColorPickButton, 1, 0);
    mainLayout->addWidget(mpNoColorCheckBox, 1, 1);
    mainLayout->addWidget(mpPatternLabel, 2, 0, 1, 2);
    mainLayout->addWidget(mpPatternsComboBox, 3, 0);
    mainLayout->addWidget(mpThicknessLabel, 4, 0, 1, 2);
    mainLayout->addWidget(mpThicknessSpinBox, 5, 0);
    mainLayout->addWidget(mpSmoothLabel, 6, 0, 1, 2);
    mainLayout->addWidget(mpSmoothCheckBox, 7, 0);
    mpPenStyleGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpPenStyleGroup);

    setLayout(layout);
}

//! Sets the pen color
//! @param color to set.
void PenStylePage::setPenColor(QColor color)
{
    mPenColor = color;
}

//! Returns the pen color
QColor PenStylePage::getPenColor()
{
    // if user selects no pen color and selects a brush color then return pen color as transparent
    if ((mpNoColorCheckBox->checkState() == Qt::Checked) and
        (mpParentOptionsWidget->mpBrushStylePage->getBrushColor().spec() != QColor::Invalid))
        return Qt::transparent;
    // if user selects no pen color and selects no brush color then return pen color as black(default)
    else if ((mpNoColorCheckBox->checkState() == Qt::Checked) and
             (mpParentOptionsWidget->mpBrushStylePage->getBrushColor().spec() == QColor::Invalid))
        return Qt::black;
    else
        return mPenColor;
}

//! Sets the pen pattern
//! @param pattern to set.
void PenStylePage::setPenPattern(QString pattern)
{
    int index = mpPatternsComboBox->findText(pattern, Qt::MatchExactly);
    if (index != -1)
        mpPatternsComboBox->setCurrentIndex(index);
}

//! Returns the pen pattern as string
//! @see getPenPattern();
QString PenStylePage::getPenPatternString()
{
    return mpPatternsComboBox->currentText();
}

//! Returns the pen pattern Qt pattern style
//! @see getPenPatternString();
Qt::PenStyle PenStylePage::getPenPattern()
{
    return Qt::PenStyle(mpPatternsComboBox->itemData(mpPatternsComboBox->currentIndex()).toInt());
}

//! Sets the pen thickness
//! @param thickness to set.
void PenStylePage::setPenThickness(double thickness)
{
    mpThicknessSpinBox->setValue(thickness);
}

//! Returns the pen thickness
double PenStylePage::getPenThickness()
{
    return mpThicknessSpinBox->value();
}

//! Sets whether the pen used will be smooth (for splines) or not.
//! @param smooth
void PenStylePage::setPenSmooth(bool smooth)
{
    mpSmoothCheckBox->setChecked(smooth);
}

//! Returns the pen smooth
bool PenStylePage::getPenSmooth()
{
    return mpSmoothCheckBox->isChecked();
}

//! Updates the state of the mpNoColorCheckBox
//! @param state to set
void PenStylePage::setNoColorCheckBox(bool state)
{
    mpNoColorCheckBox->setChecked(state);
}

//! Returns state of mpNoColorCheckBox
bool PenStylePage::getNoColorCheckBox()
{
    if (mpNoColorCheckBox->checkState() == Qt::Checked)
        return true;
    else if (mpNoColorCheckBox->checkState() == Qt::Checked)
        return false;
}

//! Sets the colot for the color viewer box.
//! @param color to set
void PenStylePage::setColorViewerPixmap(QColor color)
{
    QPixmap pixmap(Helper::iconSize);
    pixmap.fill(color);
    mpColorViewerLabel->setPixmap(pixmap);
}

//! Opens the color picker dialog. The user selects the color and the color saved as a pen color.
void PenStylePage::pickColor()
{
    QColor color = QColorDialog::getColor();

    if (color.spec() == QColor::Invalid)
        return;

    setPenColor(color);
    setColorViewerPixmap(color);
    mpNoColorCheckBox->setChecked(false);
}

//! Sets the color viewer box to black if the selected color is invalid or sets it to transparent if no color selected.
void PenStylePage::noColorChecked(int state)
{
    if (state == Qt::Checked)
    {
        // if user selects no color checkbox and no brush color is specified use black color for pen
        if (mpParentOptionsWidget->mpBrushStylePage->getBrushColor().spec() != QColor::Invalid)
        {
            setColorViewerPixmap(Qt::black);
        }
        // if user selects no color checkbox and brush color is specified use transparent color for pen then
        else
        {
            setColorViewerPixmap(Qt::transparent);
        }
    }
    else if (state == Qt::Unchecked)
    {
        if (getPenColor().spec() != QColor::Invalid)
        {
            setColorViewerPixmap(getPenColor());
        }
    }
}

//! @class BrushStylePage
//! @brief Creats an interface for BrushStyle settings.

//! Constructor
//! @param pParent is the pointer to OptionsWidget
BrushStylePage::BrushStylePage(OptionsWidget *pParent)
    : QWidget(pParent)
{
    mpParentOptionsWidget = pParent;

    mpBrushStyleGroup = new QGroupBox(tr("Brush Style"));

    mpColorLabel = new QLabel(tr("Color:"));
    mpColorViewerLabel = new QLabel(tr(""));
    mpColorPickButton = new QPushButton(tr("Pick Color"));
    connect(mpColorPickButton, SIGNAL(clicked()), SLOT(pickColor()));
    mpNoColorCheckBox = new QCheckBox(tr("No Color"));
    connect(mpNoColorCheckBox, SIGNAL(stateChanged(int)), SLOT(noColorChecked(int)));

    mpPatternLabel = new QLabel(tr("Pattern:"));
    mpPatternsComboBox = new QComboBox;
    mpPatternsComboBox->setIconSize(Helper::iconSize);
    mpPatternsComboBox->addItem(tr("NoBrush"), Qt::NoBrush);
    mpPatternsComboBox->addItem(QIcon(Helper::solidBrushIcon), Helper::solidBrush, Helper::solidBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::horizontalBrushIcon), Helper::horizontalBrush, Helper::horizontalBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::verticalBrushIcon), Helper::verticalBrush, Helper::verticalBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::crossBrushIcon), Helper::crossBrush, Helper::crossBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::forwardBrushIcon), Helper::forwardBrush, Helper::forwardBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::backwardBrushIcon), Helper::backwardBrush, Helper::backwardBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::crossDiagBrushIcon), Helper::crossDiagBrush, Helper::crossDiagBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::horizontalCylinderBrushIcon), Helper::horizontalCylinderBrush, Helper::horizontalCylinderBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::verticalCylinderBrushIcon), Helper::verticalCylinderBrush, Helper::verticalCylinderBrushStyle);
    mpPatternsComboBox->addItem(QIcon(Helper::sphereBrushIcon), Helper::sphereBrush, Helper::sphereBrushStyle);

    // set default values
    setBrushColor(QColor (0, 0, 255));            // transparent
    setColorViewerPixmap(getBrushColor());
    setBrushPattern(tr("NoBrush"));              // Qt::NoBrushPattern

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpColorLabel, 0, 0);
    mainLayout->addWidget(mpColorViewerLabel, 0, 1);
    mainLayout->addWidget(mpColorPickButton, 1, 0);
    mainLayout->addWidget(mpNoColorCheckBox, 1, 1);
    mainLayout->addWidget(mpPatternLabel, 2, 0, 1, 2);
    mainLayout->addWidget(mpPatternsComboBox, 3, 0);
    mpBrushStyleGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpBrushStyleGroup);

    setLayout(layout);
}

//! Opens the color picker dialog. The user selects the color and the color saved as a brush color.
void BrushStylePage::pickColor()
{
    QColor color = QColorDialog::getColor();

    if (color.spec() == QColor::Invalid)
        return;

    setBrushColor(color);
    mpNoColorCheckBox->setChecked(false);
    setColorViewerPixmap(color);

    // if a brush color is picked up and user has selected no color for pen then make the pen color transparent
    if (mpParentOptionsWidget->mpPenStylePage->getNoColorCheckBox())
        setColorViewerPixmap(Qt::transparent);
}

//! Sets the color viewer box to transparent if no color selected.
void BrushStylePage::noColorChecked(int state)
{
    if (state == Qt::Checked)
    {
        setColorViewerPixmap(Qt::transparent);
    }
    else if (state == Qt::Unchecked)
    {
        setColorViewerPixmap(getBrushColor());
    }
}

//! Sets the brush color
//! @param color to set
void BrushStylePage::setBrushColor(QColor color)
{
    mBrushColor = color;
}

//! Returns the brush color
//! @param brush color
QColor BrushStylePage::getBrushColor()
{
    if (mpNoColorCheckBox->checkState() == Qt::Checked)
        return Qt::transparent;
    else
        return mBrushColor;
}

//! Sets the brush pattern
//! @param pattern to set
void BrushStylePage::setBrushPattern(QString pattern)
{
    int index = mpPatternsComboBox->findText(pattern, Qt::MatchExactly);
    if (index != -1)
        mpPatternsComboBox->setCurrentIndex(index);
}

//! Returns the brush pattern as string
//! @see getBrushPattern();
QString BrushStylePage::getBrushPatternString()
{
    return mpPatternsComboBox->currentText();
}

//! Returns the brush pattern as Qt brush style
//! @see getBrushPatternString();
Qt::BrushStyle BrushStylePage::getBrushPattern()
{
    return Qt::BrushStyle(mpPatternsComboBox->itemData(mpPatternsComboBox->currentIndex()).toInt());
}

//! Sets the state of mpNoColorCheckBox
//! @param state to set
void BrushStylePage::setNoColorCheckBox(bool state)
{
    mpNoColorCheckBox->setChecked(state);
}

//! Returns the state of the mpNoColorCheckBox
bool BrushStylePage::getNoColorCheckBox()
{
    if (mpNoColorCheckBox->checkState() == Qt::Checked)
        return true;
    else if (mpNoColorCheckBox->checkState() == Qt::Checked)
        return false;
}

//! Sets the color viewer box color
//! @param color to set
void BrushStylePage::setColorViewerPixmap(QColor color)
{
    QPixmap pixmap(Helper::iconSize);
    pixmap.fill(color);
    mpColorViewerLabel->setPixmap(pixmap);
}

//! @class LibrariesPage
//! @brief Creats an interface for Libraries settings.

//! Constructor
//! @param pParent is the pointer to OptionsWidget
LibrariesPage::LibrariesPage(OptionsWidget *pParent)
    : QWidget(pParent)
{
    mpParentOptionsWidget = pParent;
    // libraries groupbox
    mpLibrariesGroup = new QGroupBox(tr("Libraries"));
    // libraries table
    mpLibrariesTree = new QTreeWidget;
    mpLibrariesTree->setObjectName(tr("LibrariesTree"));
    mpLibrariesTree->setIndentation(0);
    mpLibrariesTree->setColumnCount(2);
    QStringList labels;
    labels << "Name" << "Value";
    mpLibrariesTree->setHeaderLabels(labels);

    mpAddButton = new QPushButton(tr("Add"));
    connect(mpAddButton, SIGNAL(clicked()), SLOT(openAddLibrary()));
    mpRemoveButton = new QPushButton(tr("Remove"));
    connect(mpRemoveButton, SIGNAL(clicked()), SLOT(removeLibrary()));
    mpEditButton = new QPushButton(tr("Edit"));
    connect(mpEditButton, SIGNAL(clicked()), SLOT(openEditLibrary()));

    mpButtonBox = new QDialogButtonBox(Qt::Vertical);
    mpButtonBox->addButton(mpAddButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpRemoveButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpEditButton, QDialogButtonBox::ActionRole);

    mpLibrariesAddLabel = new QLabel(Helper::librariesAddNote);

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpLibrariesTree, 0, 0);
    mainLayout->addWidget(mpButtonBox, 0, 1);
    mainLayout->addWidget(mpLibrariesAddLabel, 1, 0, 1, 2);
    mpLibrariesGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpLibrariesGroup);

    setLayout(layout);
}

//! Returns the Libraries Tree instance.
QTreeWidget* LibrariesPage::getLibrariesTree()
{
    return mpLibrariesTree;
}

//! Slot activated when mpAddButton clicked signal is raised.
//! Creates an instance of AddLibraryWidget and show it.
void LibrariesPage::openAddLibrary()
{
    AddLibraryWidget *pAddLibraryWidget = new AddLibraryWidget(this);
    pAddLibraryWidget->show();
}

//! Slot activated when mpRemoveButton clicked signal is raised.
//! Removes the selected tree item
void LibrariesPage::removeLibrary()
{
    if (mpLibrariesTree->selectedItems().size() > 0)
    {
        mpLibrariesTree->removeItemWidget(mpLibrariesTree->selectedItems().at(0), 0);
        delete mpLibrariesTree->selectedItems().at(0);
    }
}

//! Slot activated when mpEditButton clicked signal is raised.
//! Opens the AddLibraryWidget in edit mode and pass it the selected tree item.
void LibrariesPage::openEditLibrary()
{
    if (mpLibrariesTree->selectedItems().size() > 0)
    {
        AddLibraryWidget *pAddLibraryWidget = new AddLibraryWidget(this);
        pAddLibraryWidget->setWindowTitle(QString(Helper::applicationName).append(" - Edit Library"));
        pAddLibraryWidget->mEditFlag = true;
        pAddLibraryWidget->mpNameTextBox->setText(mpLibrariesTree->selectedItems().at(0)->text(0));
        pAddLibraryWidget->mpValueTextBox->setText(mpLibrariesTree->selectedItems().at(0)->text(1));
        pAddLibraryWidget->show();
    }
}

//! @class AddLibraryWidget
//! @brief Creats an interface for Adding new Libraries.

//! Constructor
//! @param pParent is the pointer to LibrariesPage
AddLibraryWidget::AddLibraryWidget(LibrariesPage *pParent)
    : QDialog(pParent, Qt::WindowTitleHint), mEditFlag(false)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Add Library"));
    setAttribute(Qt::WA_DeleteOnClose);
    setModal(true);

    mpParentLibrariesPage = pParent;

    mpNameLabel = new QLabel(tr("Name:"));
    mpNameTextBox = new QLineEdit;
    mpValueLabel = new QLabel(tr("Value:"));
    mpValueTextBox = new QLineEdit;
    mpOkButton = new QPushButton(tr("OK"));
    connect(mpOkButton, SIGNAL(clicked()), SLOT(addLibrary()));

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpNameLabel, 0, 0);
    mainLayout->addWidget(mpNameTextBox, 0, 1);
    mainLayout->addWidget(mpValueLabel, 1, 0);
    mainLayout->addWidget(mpValueTextBox, 1, 1);
    mainLayout->addWidget(mpOkButton, 2, 0, 1, 2, Qt::AlignRight);

    setLayout(mainLayout);
}

//! Returns tree if the name exists in the tree's first column.
bool AddLibraryWidget::nameExists(QTreeWidgetItem *pItem)
{
    QTreeWidgetItemIterator it(mpParentLibrariesPage->getLibrariesTree());
    while (*it)
    {
        QTreeWidgetItem *pChildItem = dynamic_cast<QTreeWidgetItem*>(*it);
        // edit case
        if (pItem)
        {
            if (pChildItem != pItem)
            {
                if (pChildItem->text(0).compare(mpNameTextBox->text()) == 0)
                {
                    return true;
                }
            }
        }
        // add case
        else
        {
            if (pChildItem->text(0).compare(mpNameTextBox->text()) == 0)
            {
                return true;
            }
        }
        ++it;
    }
    return false;
}

//! Slot activated when mpOkButton clicked signal is raised.
//! Add/Edit the library in the tree.
void AddLibraryWidget::addLibrary()
{
    // if name text box is empty show error and return
    if (mpNameTextBox->text().isEmpty())
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ENTER_NAME).
                              arg("a"), tr("OK"));
        return;
    }
    // if value text box is empty show error and return
    if (mpValueTextBox->text().isEmpty())
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ENTER_NAME).
                              arg("the value for a"), tr("OK"));
        return;
    }
    // if user is adding a new library
    if (!mEditFlag)
    {
        if (nameExists())
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS),
                                  tr("OK"));
            return;
        }
        QStringList values;
        values << mpNameTextBox->text() << mpValueTextBox->text();
        mpParentLibrariesPage->getLibrariesTree()->addTopLevelItem(new QTreeWidgetItem(values));
    }
    // if user is editing old library
    else if (mEditFlag)
    {
        QTreeWidgetItem *pItem = mpParentLibrariesPage->getLibrariesTree()->selectedItems().at(0);
        if (nameExists(pItem))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error", GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS),
                                  tr("OK"));
            return;
        }
        pItem->setText(0, mpNameTextBox->text());
        pItem->setText(1, mpValueTextBox->text());
    }
    accept();
}
