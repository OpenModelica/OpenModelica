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

#include "DocumentationWidget.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Editors/HTMLEditor.h"
#include "Options/OptionsDialog.h"
#include "Modeling/Commands.h"

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QMenu>
#include <QDesktopServices>
#include <QApplication>
#include <QDesktopWidget>
#include <QWebFrame>
#include <QWidgetAction>
#include <QButtonGroup>
#include <QInputDialog>

/*!
 * \class DocumentationWidget
 * \brief Displays the model documentation.
 */
/*!
 * \brief DocumentationWidget::DocumentationWidget
 * \param pParent
 */
DocumentationWidget::DocumentationWidget(QWidget *pParent)
  : QWidget(pParent)
{
  setObjectName("DocumentationWidget");
  mDocumentationFile.setFileName(Utilities::tempDirectory() + "/DocumentationWidget.html");
  // documentation toolbar
  QToolBar *pDocumentationToolBar = new QToolBar;
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  pDocumentationToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  // create the previous action
  mpPreviousAction = new QAction(QIcon(":/Resources/icons/previous.svg"), tr("Previous (backspace)"), this);
  mpPreviousAction->setStatusTip(tr("Moves to previous documentation"));
  mpPreviousAction->setDisabled(true);
  connect(mpPreviousAction, SIGNAL(triggered()), SLOT(previousDocumentation()));
  // create the next action
  mpNextAction = new QAction(QIcon(":/Resources/icons/next.svg"), tr("Next (shift+backspace)"), this);
  mpNextAction->setStatusTip(tr("Moves to next documentation"));
  mpNextAction->setDisabled(true);
  connect(mpNextAction, SIGNAL(triggered()), SLOT(nextDocumentation()));
  // create the edit info action
  mpEditInfoAction = new QAction(QIcon(":/Resources/icons/edit-info.svg"), tr("Edit Info Documentation"), this);
  mpEditInfoAction->setStatusTip(tr("Starts editing info documentation"));
  mpEditInfoAction->setDisabled(true);
  connect(mpEditInfoAction, SIGNAL(triggered()), SLOT(editInfoDocumentation()));
  // create the edit revisions action
  mpEditRevisionsAction = new QAction(QIcon(":/Resources/icons/edit-revisions.svg"), tr("Edit Revisions Documentation"), this);
  mpEditRevisionsAction->setStatusTip(tr("Starts editing revisions documentation"));
  mpEditRevisionsAction->setDisabled(true);
  connect(mpEditRevisionsAction, SIGNAL(triggered()), SLOT(editRevisionsDocumentation()));
  // create the edit infoHeader action
  mpEditInfoHeaderAction = new QAction(QIcon(":/Resources/icons/edit-info-header.svg"), tr("Edit __OpenModelica_infoHeader Documentation"), this);
  mpEditInfoHeaderAction->setStatusTip(tr("Starts editing __OpenModelica_infoHeader documentation"));
  mpEditInfoHeaderAction->setDisabled(true);
  connect(mpEditInfoHeaderAction, SIGNAL(triggered()), SLOT(editInfoHeaderDocumentation()));
  // create the save action
  mpSaveAction = new QAction(QIcon(":/Resources/icons/save.svg"), Helper::save, this);
  mpSaveAction->setStatusTip(tr("Saves the edited documentation"));
  mpSaveAction->setDisabled(true);
  connect(mpSaveAction, SIGNAL(triggered()), SLOT(saveDocumentation()));
  // create the cancel action
  mpCancelAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::cancel, this);
  mpCancelAction->setStatusTip(tr("Cancels the documentation editing"));
  mpCancelAction->setDisabled(true);
  connect(mpCancelAction, SIGNAL(triggered()), SLOT(cancelDocumentation()));
  // add actions to documentation toolbar
  pDocumentationToolBar->addAction(mpPreviousAction);
  pDocumentationToolBar->addAction(mpNextAction);
  pDocumentationToolBar->addSeparator();
  pDocumentationToolBar->addAction(mpEditInfoAction);
  pDocumentationToolBar->addAction(mpEditRevisionsAction);
  pDocumentationToolBar->addAction(mpEditInfoHeaderAction);
  pDocumentationToolBar->addSeparator();
  pDocumentationToolBar->addAction(mpSaveAction);
  pDocumentationToolBar->addAction(mpCancelAction);
  // create the documentation viewer
  mpDocumentationViewer = new DocumentationViewer(this, false);
  mpDocumentationViewerFrame = new QFrame;
  mpDocumentationViewerFrame->setContentsMargins(0, 0, 0, 0);
  mpDocumentationViewerFrame->setFrameStyle(QFrame::StyledPanel);
  QHBoxLayout *pDocumentationViewerLayout = new QHBoxLayout;
  pDocumentationViewerLayout->setContentsMargins(0, 0, 0, 0);
  pDocumentationViewerLayout->addWidget(mpDocumentationViewer);
  mpDocumentationViewerFrame->setLayout(pDocumentationViewerLayout);
  // create the editors tab widget
  mpEditorsWidget = new QWidget;
  mpEditorsWidget->hide();
  // create a tab bar
  mpTabBar = new QTabBar;
  mpTabBar->setContentsMargins(0, 0, 0, 0);
  mpTabBar->addTab("");
  mpTabBar->addTab("");
  connect(mpTabBar, SIGNAL(currentChanged(int)), SLOT(toggleEditor(int)));
  // create the html editor widget
  mpHTMLEditorWidget = new QWidget;
  // editor toolbar
  mpEditorToolBar = new QToolBar;
  mpEditorToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  // create the html editor viewer
  mpHTMLEditor = new DocumentationViewer(this, true);
  mpHTMLEditorFrame = new QFrame;
  mpHTMLEditorFrame->setContentsMargins(0, 0, 0, 0);
  mpHTMLEditorFrame->setFrameStyle(QFrame::StyledPanel);
  QHBoxLayout *pHTMLEditorLayout = new QHBoxLayout;
  pHTMLEditorLayout->setContentsMargins(0, 0, 0, 0);
  pHTMLEditorLayout->addWidget(mpHTMLEditor);
  mpHTMLEditorFrame->setLayout(pHTMLEditorLayout);
  // editor actions
  // style combobox
  mpStyleComboBox = new QComboBox;
  mpStyleComboBox->setMinimumHeight(toolbarIconSize);
  mpStyleComboBox->setToolTip(tr("Style"));
  mpStyleComboBox->setStatusTip(tr("Sets the text style"));
  mpStyleComboBox->addItem(tr("Normal"), "p");
  mpStyleComboBox->addItem(tr("Heading 1"), "h1");
  mpStyleComboBox->addItem(tr("Heading 2"), "h2");
  mpStyleComboBox->addItem(tr("Heading 3"), "h3");
  mpStyleComboBox->addItem(tr("Heading 4"), "h4");
  mpStyleComboBox->addItem(tr("Heading 5"), "h5");
  mpStyleComboBox->addItem(tr("Heading 6"), "h6");
  mpStyleComboBox->addItem(tr("Preformatted"), "pre");
  connect(mpStyleComboBox, SIGNAL(currentIndexChanged(int)), SLOT(formatBlock(int)));
  // font combobox
  mpFontComboBox = new QFontComboBox;
  mpFontComboBox->setMinimumHeight(toolbarIconSize);
  mpFontComboBox->setToolTip(tr("Font"));
  mpFontComboBox->setStatusTip(tr("Sets the text font"));
  connect(mpFontComboBox, SIGNAL(currentFontChanged(QFont)), SLOT(fontName(QFont)));
  // font combobox
  mpFontSizeSpinBox = new QSpinBox;
  mpFontSizeSpinBox->setMinimumHeight(toolbarIconSize);
  mpFontSizeSpinBox->setToolTip(tr("Font Size"));
  mpFontSizeSpinBox->setStatusTip(tr("Sets the text font size"));
  mpFontSizeSpinBox->setMinimum(1);
  mpFontSizeSpinBox->setMaximum(7);
//  mpFontSizeSpinBox->setSpecialValueText(tr("(Default)"));
  connect(mpFontSizeSpinBox, SIGNAL(valueChanged(int)), SLOT(fontSize(int)));
  // bold action
  mpBoldAction = new QAction(QIcon(":/Resources/icons/bold-icon.svg"), Helper::bold, this);
  mpBoldAction->setStatusTip(tr("Make your text bold"));
  mpBoldAction->setShortcut(QKeySequence("Ctrl+b"));
  mpBoldAction->setCheckable(true);
  connect(mpBoldAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::ToggleBold), SLOT(trigger()));
  // italic action
  mpItalicAction = new QAction(QIcon(":/Resources/icons/italic-icon.svg"), Helper::italic, this);
  mpItalicAction->setStatusTip(tr("Italicize your text"));
  mpItalicAction->setShortcut(QKeySequence("Ctrl+i"));
  mpItalicAction->setCheckable(true);
  connect(mpItalicAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::ToggleItalic), SLOT(trigger()));
  // underline action
  mpUnderlineAction = new QAction(QIcon(":/Resources/icons/underline-icon.svg"), Helper::underline, this);
  mpUnderlineAction->setStatusTip(tr("Underline your text"));
  mpUnderlineAction->setShortcut(QKeySequence("Ctrl+u"));
  mpUnderlineAction->setCheckable(true);
  connect(mpUnderlineAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::ToggleUnderline), SLOT(trigger()));
  // strikethrough action
  mpStrikethroughAction = new QAction(QIcon(":/Resources/icons/strikethrough-icon.svg"), tr("Strikethrough"), this);
  mpStrikethroughAction->setStatusTip(tr("Cross something out by drawing a line through it"));
  mpStrikethroughAction->setCheckable(true);
  connect(mpStrikethroughAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::ToggleStrikethrough), SLOT(trigger()));
  // subscript superscript action group
  QActionGroup *pSubscriptSuperscriptActionGroup = new QActionGroup(this);
  pSubscriptSuperscriptActionGroup->setExclusive(true);
  // subscript action
  mpSubscriptAction = new QAction(QIcon(":/Resources/icons/subscript-icon.svg"), tr("Subscript"), pSubscriptSuperscriptActionGroup);
  mpSubscriptAction->setStatusTip(tr("Type very small letters just below the line of text"));
  mpSubscriptAction->setCheckable(true);
  connect(mpSubscriptAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::ToggleSubscript), SLOT(trigger()));
  // superscript action
  mpSuperscriptAction = new QAction(QIcon(":/Resources/icons/superscript-icon.svg"), tr("Superscript"), pSubscriptSuperscriptActionGroup);
  mpSuperscriptAction->setStatusTip(tr("Type very small letters just above the line of text"));
  mpSuperscriptAction->setCheckable(true);
  connect(mpSuperscriptAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::ToggleSuperscript), SLOT(trigger()));
  // text color toobutton
  mTextColor = Qt::black;
  mpTextColorDialog = new QColorDialog;
  mpTextColorDialog->setWindowFlags(Qt::Widget);
  QMenu *pTextColorMenu = new QMenu;
  QWidgetAction *pTextColorWidgetAction = new QWidgetAction(this);
  pTextColorWidgetAction->setDefaultWidget(mpTextColorDialog);
  pTextColorMenu->addAction(pTextColorWidgetAction);
  connect(pTextColorMenu, SIGNAL(aboutToShow()), mpTextColorDialog, SLOT(show()));
  connect(pTextColorMenu, SIGNAL(aboutToHide()), mpTextColorDialog, SLOT(hide()));
  connect(mpTextColorDialog, SIGNAL(colorSelected(QColor)), pTextColorMenu, SLOT(hide()));
  connect(mpTextColorDialog, SIGNAL(colorSelected(QColor)), SLOT(applyTextColor(QColor)));
  connect(mpTextColorDialog, SIGNAL(rejected()), pTextColorMenu, SLOT(hide()));
  mpTextColorToolButton = new QToolButton;
  mpTextColorToolButton->setText(tr("Text Color"));
  mpTextColorToolButton->setToolTip(mpTextColorToolButton->text());
  mpTextColorToolButton->setStatusTip(tr("Change the color of your text"));
  mpTextColorToolButton->setMenu(pTextColorMenu);
  mpTextColorToolButton->setPopupMode(QToolButton::MenuButtonPopup);
  mpTextColorToolButton->setIcon(createPixmapForToolButton(mTextColor, QIcon(":/Resources/icons/text-color-icon.svg")));
  connect(mpTextColorToolButton, SIGNAL(clicked()), SLOT(applyTextColor()));
  // background color toolbutton
  mBackgroundColor = Qt::white;
  mpBackgroundColorDialog = new QColorDialog;
  mpBackgroundColorDialog->setWindowFlags(Qt::Widget);
  QMenu *pBackgroundColorMenu = new QMenu;
  QWidgetAction *pBackgroundColorWidgetAction = new QWidgetAction(this);
  pBackgroundColorWidgetAction->setDefaultWidget(mpBackgroundColorDialog);
  pBackgroundColorMenu->addAction(pBackgroundColorWidgetAction);
  connect(pBackgroundColorMenu, SIGNAL(aboutToShow()), mpBackgroundColorDialog, SLOT(show()));
  connect(pBackgroundColorMenu, SIGNAL(aboutToHide()), mpBackgroundColorDialog, SLOT(hide()));
  connect(mpBackgroundColorDialog, SIGNAL(colorSelected(QColor)), pBackgroundColorMenu, SLOT(hide()));
  connect(mpBackgroundColorDialog, SIGNAL(colorSelected(QColor)), SLOT(applyBackgroundColor(QColor)));
  connect(mpBackgroundColorDialog, SIGNAL(rejected()), pBackgroundColorMenu, SLOT(hide()));
  mpBackgroundColorToolButton = new QToolButton;
  mpBackgroundColorToolButton->setText(tr("Background Color"));
  mpBackgroundColorToolButton->setToolTip(mpBackgroundColorToolButton->text());
  mpBackgroundColorToolButton->setStatusTip(tr("Change the color of your text"));
  mpBackgroundColorToolButton->setMenu(pBackgroundColorMenu);
  mpBackgroundColorToolButton->setPopupMode(QToolButton::MenuButtonPopup);
  mpBackgroundColorToolButton->setIcon(createPixmapForToolButton(mBackgroundColor, QIcon(":/Resources/icons/background-color-icon.svg")));
  connect(mpBackgroundColorToolButton, SIGNAL(clicked()), SLOT(applyBackgroundColor()));
  // align left toolbutton
  mpAlignLeftToolButton = new QToolButton;
  mpAlignLeftToolButton->setText(tr("Align Left"));
  mpAlignLeftToolButton->setToolTip(mpAlignLeftToolButton->text());
  mpAlignLeftToolButton->setStatusTip(tr("Aligns the text to the left"));
  mpAlignLeftToolButton->setIcon(QIcon(":/Resources/icons/align-left.svg"));
  mpAlignLeftToolButton->setCheckable(true);
  mpAlignLeftToolButton->setChecked(true);
  connect(mpAlignLeftToolButton, SIGNAL(clicked()), SLOT(alignLeft()));
  // align center toolbutton
  mpAlignCenterToolButton = new QToolButton;
  mpAlignCenterToolButton->setText(tr("Align Center"));
  mpAlignCenterToolButton->setToolTip(mpAlignCenterToolButton->text());
  mpAlignCenterToolButton->setStatusTip(tr("Aligns the text to the center"));
  mpAlignCenterToolButton->setIcon(QIcon(":/Resources/icons/align-center.svg"));
  mpAlignCenterToolButton->setCheckable(true);
  connect(mpAlignCenterToolButton, SIGNAL(clicked()), SLOT(alignCenter()));
  // align right toolbutton
  mpAlignRightToolButton = new QToolButton;
  mpAlignRightToolButton->setText(tr("Align Right"));
  mpAlignRightToolButton->setToolTip(mpAlignRightToolButton->text());
  mpAlignRightToolButton->setStatusTip(tr("Aligns the text to the right"));
  mpAlignRightToolButton->setIcon(QIcon(":/Resources/icons/align-right.svg"));
  mpAlignRightToolButton->setCheckable(true);
  connect(mpAlignRightToolButton, SIGNAL(clicked()), SLOT(alignRight()));
  // justify toolbutton
  mpJustifyToolButton = new QToolButton;
  mpJustifyToolButton->setText(tr("Justify"));
  mpJustifyToolButton->setToolTip(mpJustifyToolButton->text());
  mpJustifyToolButton->setStatusTip(tr("Justifies the text evenly"));
  mpJustifyToolButton->setIcon(QIcon(":/Resources/icons/justify.svg"));
  mpJustifyToolButton->setCheckable(true);
  connect(mpJustifyToolButton, SIGNAL(clicked()), SLOT(justify()));
  // alignment button group
  QButtonGroup *pAlignmentButtonGroup = new QButtonGroup;
  pAlignmentButtonGroup->setExclusive(true);
  pAlignmentButtonGroup->addButton(mpAlignLeftToolButton);
  pAlignmentButtonGroup->addButton(mpAlignCenterToolButton);
  pAlignmentButtonGroup->addButton(mpAlignRightToolButton);
  pAlignmentButtonGroup->addButton(mpJustifyToolButton);
  // decrease indent action
  mpDecreaseIndentAction = new QAction(QIcon(":/Resources/icons/decrease-indent.svg"), tr("Decrease Indent"), this);
  mpDecreaseIndentAction->setStatusTip(tr("Decreases the indent by moving left"));
  connect(mpDecreaseIndentAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::Outdent), SLOT(trigger()));
  // increase indent action
  mpIncreaseIndentAction = new QAction(QIcon(":/Resources/icons/increase-indent.svg"), tr("Increase Indent"), this);
  mpIncreaseIndentAction->setStatusTip(tr("Increases the indent by moving right"));
  connect(mpIncreaseIndentAction, SIGNAL(triggered()), mpHTMLEditor->pageAction(QWebPage::Indent), SLOT(trigger()));
  // bullet list action
  mpBulletListAction = new QAction(QIcon(":/Resources/icons/bullet-list.svg"), tr("Bullet List"), this);
  mpBulletListAction->setStatusTip(tr("Creates a bulleted list"));
  mpBulletListAction->setCheckable(true);
  connect(mpBulletListAction, SIGNAL(triggered()), SLOT(bulletList()));
  // numbered list action
  mpNumberedListAction = new QAction(QIcon(":/Resources/icons/numbered-list.svg"), tr("Numbered List"), this);
  mpNumberedListAction->setStatusTip(tr("Creates a numbered list"));
  mpNumberedListAction->setCheckable(true);
  connect(mpNumberedListAction, SIGNAL(triggered()), SLOT(numberedList()));
  // link action
  mpLinkAction = new QAction(QIcon(":/Resources/icons/link.svg"), tr("Create Link"), this);
  mpLinkAction->setStatusTip(tr("Creates a link"));
  mpLinkAction->setEnabled(false);
  connect(mpLinkAction, SIGNAL(triggered()), SLOT(createLink()));
  // unklink action
  mpUnLinkAction = new QAction(QIcon(":/Resources/icons/unlink.svg"), tr("Remove Link"), this);
  mpUnLinkAction->setStatusTip(tr("Removes a link"));
  mpUnLinkAction->setEnabled(false);
  connect(mpUnLinkAction, SIGNAL(triggered()), SLOT(removeLink()));
  // add actions to editor toolbar
  mpEditorToolBar->addWidget(mpStyleComboBox);
  mpEditorToolBar->addWidget(mpFontComboBox);
  mpEditorToolBar->addWidget(mpFontSizeSpinBox);
  mpEditorToolBar->addAction(mpBoldAction);
  mpEditorToolBar->addAction(mpItalicAction);
  mpEditorToolBar->addAction(mpUnderlineAction);
  mpEditorToolBar->addAction(mpStrikethroughAction);
  mpEditorToolBar->addAction(mpSubscriptAction);
  mpEditorToolBar->addAction(mpSuperscriptAction);
  mpEditorToolBar->addSeparator();
  mpEditorToolBar->addWidget(mpTextColorToolButton);
  mpEditorToolBar->addWidget(mpBackgroundColorToolButton);
  mpEditorToolBar->addSeparator();
  mpEditorToolBar->addWidget(mpAlignLeftToolButton);
  mpEditorToolBar->addWidget(mpAlignCenterToolButton);
  mpEditorToolBar->addWidget(mpAlignRightToolButton);
  mpEditorToolBar->addWidget(mpJustifyToolButton);
  mpEditorToolBar->addSeparator();
  mpEditorToolBar->addAction(mpDecreaseIndentAction);
  mpEditorToolBar->addAction(mpIncreaseIndentAction);
  mpEditorToolBar->addSeparator();
  mpEditorToolBar->addAction(mpBulletListAction);
  mpEditorToolBar->addAction(mpNumberedListAction);
  mpEditorToolBar->addSeparator();
  mpEditorToolBar->addAction(mpLinkAction);
  mpEditorToolBar->addAction(mpUnLinkAction);
  // update the actions whenever the selectionChanged signal is raised.
  connect(mpHTMLEditor->page(), SIGNAL(selectionChanged()), SLOT(updateActions()));
  // add a layout to html editor widget
  QVBoxLayout *pHTMLWidgetLayout = new QVBoxLayout;
  pHTMLWidgetLayout->setAlignment(Qt::AlignTop);
  pHTMLWidgetLayout->setContentsMargins(0, 0, 0, 0);
  pHTMLWidgetLayout->setSpacing(0);
  pHTMLWidgetLayout->addWidget(mpEditorToolBar);
  pHTMLWidgetLayout->addWidget(mpHTMLEditorFrame, 1);
  mpHTMLEditorWidget->setLayout(pHTMLWidgetLayout);
  // create the HTMLEditor
  mpHTMLSourceEditor = new HTMLEditor(this);
  mpHTMLSourceEditor->hide();
  connect(mpHTMLEditor->page(), SIGNAL(contentsChanged()), SLOT(updateHTMLSourceEditor()));
  HTMLHighlighter *pHTMLHighlighter = new HTMLHighlighter(OptionsDialog::instance()->getHTMLEditorPage(), mpHTMLSourceEditor->getPlainTextEdit());
  connect(OptionsDialog::instance(), SIGNAL(HTMLEditorSettingsChanged()), pHTMLHighlighter, SLOT(settingsChanged()));
  // eidtors widget layout
  QVBoxLayout *pEditorsWidgetLayout = new QVBoxLayout;
  pEditorsWidgetLayout->setAlignment(Qt::AlignTop);
  pEditorsWidgetLayout->setContentsMargins(0, 0, 0, 0);
  pEditorsWidgetLayout->setSpacing(0);
  pEditorsWidgetLayout->addWidget(mpTabBar);
  pEditorsWidgetLayout->addWidget(mpHTMLEditorWidget);
  pEditorsWidgetLayout->addWidget(mpHTMLSourceEditor);
  mpEditorsWidget->setLayout(pEditorsWidgetLayout);
  mEditType = EditType::None;
  // navigation history list
  mpDocumentationHistoryList = new QList<DocumentationHistory>();
  mDocumentationHistoryPos = -1;
  // Documentation viewer layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setContentsMargins(0, 0, 0, 0);
  pGridLayout->addWidget(mpDocumentationViewerFrame);
  pGridLayout->addWidget(mpEditorsWidget);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(0);
  pMainLayout->addWidget(pDocumentationToolBar);
  pMainLayout->addLayout(pGridLayout, 1);
  setLayout(pMainLayout);
}

/*!
 * \brief DocumentationWidget::~DocumentationWidget
 */
DocumentationWidget::~DocumentationWidget()
{
  mDocumentationFile.remove();
  delete mpDocumentationHistoryList;
}

/*!
 * \brief DocumentationWidget::showDocumentation
 * Shows the documentaiton annotation. If we are editing a documentation then it is saved before showing the annotation.
 * \param pLibraryTreeItem
 */
void DocumentationWidget::showDocumentation(LibraryTreeItem *pLibraryTreeItem)
{
  // We only support documentation of Modelica classes.
  if (pLibraryTreeItem->getLibraryType() != LibraryTreeItem::Modelica) {
    return;
  }
  // if documentation is proctected then do not show it.
  if (pLibraryTreeItem->getAccess() < LibraryTreeItem::documentation) {
    // Remove the class documentation if it is showed previously.
    updateDocumentationHistory(pLibraryTreeItem);
    return;
  }
  if (mEditType != EditType::None) {
    saveDocumentation(pLibraryTreeItem);
    return;
  }
  QString documentation = MainWindow::instance()->getOMCProxy()->getDocumentationAnnotation(pLibraryTreeItem);
  writeDocumentationFile(documentation);
  mpDocumentationViewer->setUrl(QUrl::fromLocalFile(mDocumentationFile.fileName()));

  if ((mDocumentationHistoryPos >= 0) && (pLibraryTreeItem == mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem)) {
    /* reload url */
  } else {
    /* new url */
    /* remove all following urls */
    while (mpDocumentationHistoryList->count() > (mDocumentationHistoryPos+1)) {
      mpDocumentationHistoryList->removeLast();
    }
    /* append new url */
    mpDocumentationHistoryList->append(DocumentationHistory(pLibraryTreeItem));
    mDocumentationHistoryPos++;
    connect(pLibraryTreeItem, SIGNAL(unLoaded()), SLOT(updateDocumentationHistory()));
  }

  updatePreviousNextButtons();
  mpEditInfoAction->setDisabled(pLibraryTreeItem->isSystemLibrary());
  mpEditRevisionsAction->setDisabled(pLibraryTreeItem->isSystemLibrary());
  mpEditInfoHeaderAction->setDisabled(pLibraryTreeItem->isSystemLibrary());
  mpSaveAction->setDisabled(true);
  mpCancelAction->setDisabled(true);
  mpDocumentationViewerFrame->show();
  mpEditorsWidget->hide();
}

/*!
 * \brief DocumentationWidget::execCommand
 * Calls the document.execCommand API.
 * \param commandName
 * \sa DocumentationWidget::execCommand(commandName, valueArgument)
 */
void DocumentationWidget::execCommand(const QString &commandName)
{
  QWebFrame *pWebFrame = mpHTMLEditor->page()->mainFrame();
  QString javaScript = QString("document.execCommand(\"%1\", false, null)").arg(commandName);
  pWebFrame->evaluateJavaScript(javaScript);
}

/*!
 * \brief DocumentationWidget::execCommand
 * Calls the document.execCommand API.
 * \param command
 * \param valueArgument
 * \sa DocumentationWidget::execCommand(commandName)
 */
void DocumentationWidget::execCommand(const QString &command, const QString &valueArgument)
{
  QWebFrame *pWebFrame = mpHTMLEditor->page()->mainFrame();
  QString javaScript = QString("document.execCommand(\"%1\", false, \"%2\")").arg(command).arg(valueArgument);
  pWebFrame->evaluateJavaScript(javaScript);
}

/*!
 * \brief DocumentationWidget::queryCommandState
 * Calls the document.queryCommandState API.\n
 * Returns true if the command is enabled e.g., if the text is bold then document.queryCommandState("bold", false, null) returns true.
 * \param commandName
 * \return
 */
bool DocumentationWidget::queryCommandState(const QString &commandName)
{
  QWebFrame *pWebFrame = mpHTMLEditor->page()->mainFrame();
  QString javaScript = QString("document.queryCommandState(\"%1\")").arg(commandName);
  QVariant result = pWebFrame->evaluateJavaScript(javaScript);
  return result.toString().simplified().toLower() == "true";
}

/*!
 * \brief DocumentationWidget::queryCommandValue
 * Calls the document.queryCommandValue API.\n
 * Returns the command value e.g., if the text is heading 1 then document.queryCommandValue("formatBlock", false, null) returns h1.
 * \param commandName
 * \return
 */
QString DocumentationWidget::queryCommandValue(const QString &commandName)
{
  QWebFrame *pWebFrame = mpHTMLEditor->page()->mainFrame();
  QString javaScript = QString("document.queryCommandValue(\"%1\")").arg(commandName);
  QVariant result = pWebFrame->evaluateJavaScript(javaScript);
  return result.toString();
}

/*!
 * \brief DocumentationWidget::createPixmapForToolButton
 * Creates a new pixmap which contains the QIcon and the QColor in the bottom.
 * \param color
 * \param icon
 * \return
 */
QPixmap DocumentationWidget::createPixmapForToolButton(QColor color, QIcon icon)
{
  QSize size = mpEditorToolBar->iconSize();
  int height = (size.height() * 20) / 100;
  QPixmap upperPixmap = icon.pixmap(size.width(), size.height() - height);
  QPixmap collagePixmap(size);
  collagePixmap.fill(Qt::transparent);
  QPainter painter(&collagePixmap);
  painter.drawPixmap(upperPixmap.rect(), upperPixmap);
  QPixmap bottomPixmap(size.width(), height);
  bottomPixmap.fill(color);
  painter.drawPixmap(QRect(0, upperPixmap.height(), bottomPixmap.width(), bottomPixmap.height()), bottomPixmap);
  return collagePixmap;
}

/*!
 * \brief DocumentationWidget::updatePreviousNextButtons
 * Updates the previous and next button.
 */
void DocumentationWidget::updatePreviousNextButtons()
{
  // update previous button
  if (mDocumentationHistoryPos > 0) {
    mpPreviousAction->setDisabled(false);
  } else {
    mpPreviousAction->setDisabled(true);
  }
  // update next button
  if (mpDocumentationHistoryList->count() == (mDocumentationHistoryPos + 1)) {
    mpNextAction->setDisabled(true);
  } else {
    mpNextAction->setDisabled(false);
  }
}

/*!
 * \brief DocumentationWidget::writeDocumentationFile
 * \param documentation
 */
void DocumentationWidget::writeDocumentationFile(QString documentation)
{
  /* Create a local file with the html we want to view as otherwise JavaScript does not run properly. */
  mDocumentationFile.open(QIODevice::WriteOnly);
  QTextStream out(&mDocumentationFile);
  out.setCodec(Helper::utf8.toStdString().data());
  out << documentation;
  mDocumentationFile.close();
}

/*!
 * \brief DocumentationWidget::isLinkSelected
 * Returns true if a link is selected.
 * \return
 */
bool DocumentationWidget::isLinkSelected()
{
  QWebFrame *pWebFrame = mpHTMLEditor->page()->mainFrame();
  QString javaScript = QString("function isLinkSelected() {"
                               "  if (document.getSelection().anchorNode.parentNode.nodeName == 'A') {"
                               "    return true;"
                               "  } else {"
                               "    return false;"
                               "  }"
                               "}"
                               "isLinkSelected()");
  QVariant result = pWebFrame->evaluateJavaScript(javaScript);
  return result.toString().simplified().toLower() == "true";
}

/*!
 * \brief DocumentationWidget::updateDocumentationHistory
 * \param pLibraryTreeItem
 * Removes the corresponding LibraryTreeItem from the DocumentationHistory.
 */
void DocumentationWidget::updateDocumentationHistory(LibraryTreeItem *pLibraryTreeItem)
{
  if (pLibraryTreeItem) {
    int index = mpDocumentationHistoryList->indexOf(DocumentationHistory(pLibraryTreeItem));
    if (index > -1) {
      mpDocumentationHistoryList->removeOne(DocumentationHistory(pLibraryTreeItem));
      if (index == mDocumentationHistoryPos) {
        if (!(index == 0 && !mpDocumentationHistoryList->isEmpty())) {
          mDocumentationHistoryPos--;
        }
      } else if (index < mDocumentationHistoryPos) {
        mDocumentationHistoryPos--;
      } else if (index > mDocumentationHistoryPos) {
        // do nothing
      }
      updatePreviousNextButtons();
      if (mDocumentationHistoryPos > -1) {
        cancelDocumentation();
        showDocumentation(mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem);
      } else {
        mpEditInfoAction->setDisabled(true);
        mpEditRevisionsAction->setDisabled(true);
        mpEditInfoHeaderAction->setDisabled(true);
        mpSaveAction->setDisabled(true);
        mpCancelAction->setDisabled(true);
        mpDocumentationViewer->setHtml(""); // clear if we don't have any documentation to show
        mpDocumentationViewerFrame->show();
        mpEditorsWidget->hide();
        mEditType = EditType::None;
      }
    }
  }
}

/*!
 * \brief DocumentationWidget::previousDocumentation
 * Moves to the previous documentation.\n
 * Slot activated when clicked signal of mpPreviousToolButton is raised.
 */
void DocumentationWidget::previousDocumentation()
{
  if (mDocumentationHistoryPos > 0) {
    mDocumentationHistoryPos--;
    showDocumentation(mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem);
  }
}

/*!
 * \brief DocumentationWidget::nextDocumentation
 * Moves to the next documentation.\n
 * Slot activated when clicked signal of mpNextToolButton is raised.
 */
void DocumentationWidget::nextDocumentation()
{
  if ((mDocumentationHistoryPos + 1) < mpDocumentationHistoryList->count()) {
    mDocumentationHistoryPos++;
    showDocumentation(mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem);
  }
}

/*!
 * \brief DocumentationWidget::editInfoDocumentation
 * Starts editing the info section of documentation annotation.\n
 * Slot activated when clicked signal of mpEditInfoToolButton is raised.
 */
void DocumentationWidget::editInfoDocumentation()
{
  if (mDocumentationHistoryPos >= 0) {
    LibraryTreeItem *pLibraryTreeItem = mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem;
    if (pLibraryTreeItem && !pLibraryTreeItem->isNonExisting()) {
      // get the info documentation
      QList<QString> info = MainWindow::instance()->getOMCProxy()->getDocumentationAnnotationInClass(pLibraryTreeItem);
      writeDocumentationFile(info.at(0));
      mpHTMLEditor->setUrl(QUrl::fromLocalFile(mDocumentationFile.fileName()));
      // put the info documentation in the source editor
      mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(info.at(0));
      mpTabBar->setTabText(0, tr("Info Editor"));
      mpTabBar->setTabText(1, tr("Info Source"));
      mEditType = EditType::Info;
      // update the buttons
      mpPreviousAction->setDisabled(true);
      mpNextAction->setDisabled(true);
      mpEditInfoAction->setDisabled(true);
      mpEditRevisionsAction->setDisabled(true);
      mpEditInfoHeaderAction->setDisabled(true);
      mpSaveAction->setDisabled(false);
      mpCancelAction->setDisabled(false);
      mpDocumentationViewerFrame->hide();
      mpEditorsWidget->show();
      mpTabBar->setCurrentIndex(0);
      mpHTMLEditor->setFocusInternal();
    }
  }
}

/*!
 * \brief DocumentationWidget::editRevisionsDocumentation
 * Starts editing the revisions section of the documentation annotation.\n
 * Slot activated when clicked signal of mpEditRevisionsToolButton is raised.
 */
void DocumentationWidget::editRevisionsDocumentation()
{
  if (mDocumentationHistoryPos >= 0) {
    LibraryTreeItem *pLibraryTreeItem = mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem;
    if (pLibraryTreeItem && !pLibraryTreeItem->isNonExisting()) {
      // get the revision documentation
      QList<QString> revisions = MainWindow::instance()->getOMCProxy()->getDocumentationAnnotationInClass(pLibraryTreeItem);
      writeDocumentationFile(revisions.at(1));
      mpHTMLEditor->setUrl(QUrl::fromLocalFile(mDocumentationFile.fileName()));
      // put the info documentation in the source editor
      mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(revisions.at(1));
      mpTabBar->setTabText(0, tr("Revisions Editor"));
      mpTabBar->setTabText(1, tr("Revisions Source"));
      mEditType = EditType::Revisions;
      // update the buttons
      mpPreviousAction->setDisabled(true);
      mpNextAction->setDisabled(true);
      mpEditInfoAction->setDisabled(true);
      mpEditRevisionsAction->setDisabled(true);
      mpEditInfoHeaderAction->setDisabled(true);
      mpSaveAction->setDisabled(false);
      mpCancelAction->setDisabled(false);
      mpDocumentationViewerFrame->hide();
      mpEditorsWidget->show();
      mpTabBar->setCurrentIndex(0);
      mpHTMLEditor->setFocusInternal();
    }
  }
}

/*!
 * \brief DocumentationWidget::editInfoHeaderDocumentation
 * Starts editing the __OpenModelica_infoHeader section of the documentation annotation.\n
 * Slot activated when clicked signal of mpEditInfoHeaderToolButton is raised.
 */
void DocumentationWidget::editInfoHeaderDocumentation()
{
  if (mDocumentationHistoryPos >= 0) {
    LibraryTreeItem *pLibraryTreeItem = mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem;
    if (pLibraryTreeItem && !pLibraryTreeItem->isNonExisting()) {
      // get the __OpenModelica_infoHeader documentation annotation
      QList<QString> infoHeader = MainWindow::instance()->getOMCProxy()->getDocumentationAnnotationInClass(pLibraryTreeItem);
      writeDocumentationFile(infoHeader.at(2));
      mpHTMLEditor->setUrl(QUrl::fromLocalFile(mDocumentationFile.fileName()));
      // put the info documentation in the source editor
      mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(infoHeader.at(2));
      mpTabBar->setTabText(0, tr("__OpenModelica_infoHeader Editor"));
      mpTabBar->setTabText(1, tr("__OpenModelica_infoHeader Source"));
      mEditType = EditType::InfoHeader;
      // update the buttons
      mpPreviousAction->setDisabled(true);
      mpNextAction->setDisabled(true);
      mpEditInfoAction->setDisabled(true);
      mpEditRevisionsAction->setDisabled(true);
      mpEditInfoHeaderAction->setDisabled(true);
      mpSaveAction->setDisabled(false);
      mpCancelAction->setDisabled(false);
      mpDocumentationViewerFrame->hide();
      mpEditorsWidget->show();
      mpTabBar->setCurrentIndex(0);
      mpHTMLEditor->setFocusInternal();
    }
  }
}

/*!
 * \brief DocumentationWidget::saveDocumentation
 * Saves the documentaiton annotation. If pLibraryTreeItem is 0 then the documentation of the editing class is shown after save.\n
 * Otherwise the documentation of pLibraryTreeItem is shown.
 * Slot activated when clicked signal of mpSaveToolButton is raised.
 * \param pNextLibraryTreeItem
 */
void DocumentationWidget::saveDocumentation(LibraryTreeItem *pNextLibraryTreeItem)
{
  if (mDocumentationHistoryPos >= 0) {
    LibraryTreeItem *pLibraryTreeItem = mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem;
    if (pLibraryTreeItem && !pLibraryTreeItem->isNonExisting()) {
      QList<QString> documentation = MainWindow::instance()->getOMCProxy()->getDocumentationAnnotationInClass(pLibraryTreeItem);
      // old documentation annotation
      QString oldDocAnnotationString = "annotate=Documentation(";
      if (!documentation.at(0).isEmpty()) {
        oldDocAnnotationString.append("info=\"").append(StringHandler::escapeStringQuotes(documentation.at(0))).append("\"");
      }
      if (!documentation.at(1).isEmpty()) {
        oldDocAnnotationString.append(", revisions=\"").append(StringHandler::escapeStringQuotes(documentation.at(1))).append("\"");
      }
      if (!documentation.at(2).isEmpty()) {
        oldDocAnnotationString.append(", __OpenModelica_infoHeader=\"").append(StringHandler::escapeStringQuotes(documentation.at(2))).append("\"");
      }
      oldDocAnnotationString.append(")");
      // new documentation annotation
      QString newDocAnnotationString = "annotate=Documentation(";
      if (mEditType == EditType::Info) { // if editing the info section
        if (!mpHTMLSourceEditor->getPlainTextEdit()->toPlainText().isEmpty()) {
          newDocAnnotationString.append("info=\"").append(StringHandler::escapeStringQuotes(mpHTMLSourceEditor->getPlainTextEdit()->toPlainText())).append("\"");
        }
        if (!documentation.at(1).isEmpty()) {
          newDocAnnotationString.append(", revisions=\"").append(StringHandler::escapeStringQuotes(documentation.at(1))).append("\"");
        }
        if (!documentation.at(2).isEmpty()) {
          newDocAnnotationString.append(", __OpenModelica_infoHeader=\"").append(StringHandler::escapeStringQuotes(documentation.at(2))).append("\"");
        }
      } else if (mEditType == EditType::Revisions) { // if editing the revisions section
        if (!documentation.at(0).isEmpty()) {
          newDocAnnotationString.append("info=\"").append(StringHandler::escapeStringQuotes(documentation.at(0))).append("\"");
        }
        if (!mpHTMLSourceEditor->getPlainTextEdit()->toPlainText().isEmpty()) {
          newDocAnnotationString.append(", revisions=\"").append(StringHandler::escapeStringQuotes(mpHTMLSourceEditor->getPlainTextEdit()->toPlainText())).append("\"");
        }
        if (!documentation.at(2).isEmpty()) {
          newDocAnnotationString.append(", __OpenModelica_infoHeader=\"").append(StringHandler::escapeStringQuotes(documentation.at(2))).append("\"");
        }
      } else if (mEditType == EditType::InfoHeader) { // if editing the __OpenModelica_infoHeader section
        if (!documentation.at(0).isEmpty()) {
          newDocAnnotationString.append("info=\"").append(StringHandler::escapeStringQuotes(documentation.at(0))).append("\"");
        }
        if (!documentation.at(1).isEmpty()) {
          newDocAnnotationString.append(", revisions=\"").append(StringHandler::escapeStringQuotes(documentation.at(1))).append("\"");
        }
        if (!mpHTMLSourceEditor->getPlainTextEdit()->toPlainText().isEmpty()) {
          newDocAnnotationString.append(", __OpenModelica_infoHeader=\"").append(StringHandler::escapeStringQuotes(mpHTMLSourceEditor->getPlainTextEdit()->toPlainText())).append("\"");
        }
      }
      newDocAnnotationString.append(")");
      // if we have ModelWidget for class then put the change on undo stack.
      if (pLibraryTreeItem->getModelWidget()) {
        UpdateClassAnnotationCommand *pUpdateClassExperimentAnnotationCommand;
        pUpdateClassExperimentAnnotationCommand = new UpdateClassAnnotationCommand(pLibraryTreeItem, oldDocAnnotationString,
                                                                                   newDocAnnotationString);
        pLibraryTreeItem->getModelWidget()->getUndoStack()->push(pUpdateClassExperimentAnnotationCommand);
        pLibraryTreeItem->getModelWidget()->updateModelText();
      } else {
        // send the documentation annotation to OMC
        MainWindow::instance()->getOMCProxy()->addClassAnnotation(pLibraryTreeItem->getNameStructure(), newDocAnnotationString);
        LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
        pLibraryTreeModel->updateLibraryTreeItemClassText(pLibraryTreeItem);
      }
      /* ticket:5190 Save the class when documentation save button is hit. */
      MainWindow::instance()->getLibraryWidget()->saveLibraryTreeItem(pLibraryTreeItem);
      mEditType = EditType::None;
      showDocumentation(pNextLibraryTreeItem ? pNextLibraryTreeItem : pLibraryTreeItem);
    }
  }
}

/*!
 * \brief DocumentationWidget::cancelDocumentation
 * Cancels the editing of documentation annotation.
 * Slot activated when clicked signal of mpCancelToolButton is raised.
 */
void DocumentationWidget::cancelDocumentation()
{
  updatePreviousNextButtons();
  mpEditInfoAction->setDisabled(false);
  mpEditRevisionsAction->setDisabled(false);
  mpEditInfoHeaderAction->setDisabled(false);
  mpSaveAction->setDisabled(true);
  mpCancelAction->setDisabled(true);
  mpDocumentationViewerFrame->show();
  mpEditorsWidget->hide();
  mEditType = EditType::None;
}

/*!
 * \brief DocumentationWidget::toggleEditor
 * Slot activated when mpTabBar currentIndexChanged SIGNAL is raised.\n
 * Switches between editor and source.
 * \param tabIndex
 */
void DocumentationWidget::toggleEditor(int tabIndex)
{
  switch (tabIndex) {
    case 1:
      mpHTMLEditorWidget->hide();
      mpHTMLSourceEditor->show();
      mpHTMLSourceEditor->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
      break;
    case 0:
    default:
      if (mpHTMLSourceEditor->getPlainTextEdit()->document()->isModified()) {
        writeDocumentationFile(mpHTMLSourceEditor->getPlainTextEdit()->toPlainText());
        mpHTMLEditor->setUrl(QUrl::fromLocalFile(mDocumentationFile.fileName()));
      }
      mpHTMLSourceEditor->hide();
      mpHTMLEditorWidget->show();
      mpHTMLEditor->setFocusInternal();
      break;
  }
}

/*!
 * \brief DocumentationWidget::updateActions
 * Slot activated when QWebView::page() selecionChanged SIGNAL is raised.\n
 * Updates the actions according to the cursor position.
 */
void DocumentationWidget::updateActions()
{
  bool state = mpStyleComboBox->blockSignals(true);
  QString format = queryCommandValue("formatBlock");
  int currentIndex = mpStyleComboBox->findData(format);
  if (currentIndex > -1) {
    mpStyleComboBox->setCurrentIndex(currentIndex);
  } else {
    mpStyleComboBox->setCurrentIndex(0);
  }
  mpStyleComboBox->blockSignals(state);
  state = mpFontComboBox->blockSignals(true);
  QString fontName = queryCommandValue("fontName");
  // font name has extra single quote around it so remove it.
  fontName = StringHandler::removeFirstLastSingleQuotes(fontName);
  currentIndex = mpFontComboBox->findText(fontName, Qt::MatchExactly);
  if (currentIndex > -1) {
    mpFontComboBox->setCurrentIndex(currentIndex);
  }
  mpFontComboBox->blockSignals(state);
  bool ok;
  int fontSize = queryCommandValue("fontSize").toInt(&ok);
  if (ok) {
    state = mpFontSizeSpinBox->blockSignals(true);
    mpFontSizeSpinBox->setValue(fontSize);
    mpFontSizeSpinBox->blockSignals(state);
  }
  mpBoldAction->setChecked(mpHTMLEditor->pageAction(QWebPage::ToggleBold)->isChecked());
  mpItalicAction->setChecked(mpHTMLEditor->pageAction(QWebPage::ToggleItalic)->isChecked());
  mpUnderlineAction->setChecked(mpHTMLEditor->pageAction(QWebPage::ToggleUnderline)->isChecked());
  mpStrikethroughAction->setChecked(mpHTMLEditor->pageAction(QWebPage::ToggleStrikethrough)->isChecked());
  mpSubscriptAction->setChecked(mpHTMLEditor->pageAction(QWebPage::ToggleSubscript)->isChecked());
  mpSuperscriptAction->setChecked(mpHTMLEditor->pageAction(QWebPage::ToggleSuperscript)->isChecked());
  mpAlignLeftToolButton->setChecked(queryCommandState("justifyLeft"));
  mpAlignCenterToolButton->setChecked(queryCommandState("justifyCenter"));
  mpAlignRightToolButton->setChecked(queryCommandState("justifyRight"));
  mpJustifyToolButton->setChecked(queryCommandState("justifyFull"));
  mpBulletListAction->setChecked(queryCommandState("insertUnorderedList"));
  mpNumberedListAction->setChecked(queryCommandState("insertOrderedList"));
  mpLinkAction->setEnabled(!mpHTMLEditor->page()->selectedText().isEmpty());
  mpUnLinkAction->setEnabled(!mpHTMLEditor->page()->selectedText().isEmpty() && isLinkSelected());
}

/*!
 * \brief DocumentationWidget::formatBlock
 * SLOT activated when style combobox is changed.
 * \param index
 */
void DocumentationWidget::formatBlock(int index)
{
  QString format = mpStyleComboBox->itemData(index).toString();
  execCommand("formatBlock", format);
}

/*!
 * \brief DocumentationWidget::fontName
 * Sets the text font name.
 * \param font
 */
void DocumentationWidget::fontName(QFont font)
{
//  execCommand("styleWithCSS", "true");
  execCommand("fontName", font.family());
//  execCommand("styleWithCSS", "false");
}

/*!
 * \brief DocumentationWidget::fontSize
 * Sets the text font size.
 * \param size
 */
void DocumentationWidget::fontSize(int size)
{
//  execCommand("styleWithCSS", "true");
  execCommand("fontSize", QString::number(size));
//  execCommand("styleWithCSS", "false");
}

/*!
 * \brief DocumentationWidget::applyTextColor
 * SLOT activated when text color button is clicked.\n
 * \sa DocumentationWidget::applyTextColor(QColor color)
 */
void DocumentationWidget::applyTextColor()
{
  applyTextColor(mTextColor);
}

/*!
 * \brief DocumentationWidget::applyTextColor
 * SLOT activated when user selects a text color.\n
 * Applies the text color by executing command foreColor.
 * \param color
 */
void DocumentationWidget::applyTextColor(QColor color)
{
  mTextColor = color;
  mpTextColorToolButton->setIcon(createPixmapForToolButton(mTextColor, QIcon(":/Resources/icons/text-color-icon.svg")));
  execCommand("foreColor", color.name());
}

/*!
 * \brief DocumentationWidget::applyBackgroundColor
 * SLOT activated when background color button is clicked.\n
 * \sa DocumentationWidget::applyBackgroundColor(QColor color)
 */
void DocumentationWidget::applyBackgroundColor()
{
  applyBackgroundColor(mBackgroundColor);
}

/*!
 * \brief DocumentationWidget::applyBackgroundColor
 * SLOT activated when user selects a baclground color.\n
 * Applies the text color by executing command hiliteColor.
 * \param color
 */
void DocumentationWidget::applyBackgroundColor(QColor color)
{
  mBackgroundColor = color;
  mpBackgroundColorToolButton->setIcon(createPixmapForToolButton(mBackgroundColor, QIcon(":/Resources/icons/background-color-icon.svg")));
  execCommand("hiliteColor", color.name());
}

/*!
 * \brief DocumentationWidget::alignLeft
 * Aligns the text left by executing command justifyLeft.
 */
void DocumentationWidget::alignLeft()
{
  execCommand("justifyLeft");
}

/*!
 * \brief DocumentationWidget::alignCenter
 * Aligns the text center by executing command justifyCenter.
 */
void DocumentationWidget::alignCenter()
{
  execCommand("justifyCenter");
}

/*!
 * \brief DocumentationWidget::alignRight
 * Aligns the text right by executing command justifyRight.
 */
void DocumentationWidget::alignRight()
{
  execCommand("justifyRight");
}

/*!
 * \brief DocumentationWidget::justify
 * Justifies the text by executing command justifyFull.
 */
void DocumentationWidget::justify()
{
  execCommand("justifyFull");
}

/*!
 * \brief DocumentationWidget::bulletList
 * Inserts the unordered list.
 */
void DocumentationWidget::bulletList()
{
  execCommand("insertUnorderedList");
}

/*!
 * \brief DocumentationWidget::numberedList
 * Inserts the ordered list.
 */
void DocumentationWidget::numberedList()
{
  execCommand("insertOrderedList");
}

/*!
 * \brief DocumentationWidget::createLink
 * Creates a link.
 */
void DocumentationWidget::createLink()
{
  QWebFrame *pWebFrame = mpHTMLEditor->page()->mainFrame();
  QString javaScript = QString("function getLinkHref() {"
                               "  if (document.getSelection().anchorNode.parentNode.nodeName == 'A') {"
                               "    if (document.getSelection().anchorNode.parentNode.hasAttribute('href')) {"
                               "      return document.getSelection().anchorNode.parentNode.getAttribute('href');"
                               "    }"
                               "  }"
                               "  return '';"
                               "}"
                               "getLinkHref()");
  QString href = pWebFrame->evaluateJavaScript(javaScript).toString();
  href = QInputDialog::getText(this, tr("Create Link"), "Enter URL", QLineEdit::Normal, href);
  execCommand("createLink", href);
}

/*!
 * \brief DocumentationWidget::removeLink
 * Removes the link.
 */
void DocumentationWidget::removeLink()
{
  execCommand("unlink");
}

/*!
 * \brief DocumentationWidget::updateHTMLSourceEditor
 * Slot activated when QWebView::page() contentsChanged SIGNAL is rasied.\n
 * Updates the contents of the HTML source editor.
 */
void DocumentationWidget::updateHTMLSourceEditor()
{
  mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(mpHTMLEditor->page()->mainFrame()->toHtml());
}

/*!
 * \brief DocumentationWidget::updateDocumentationHistory
 * Slot activated when LibraryTreeItem unloaded SIGNAL is raised.
 */
void DocumentationWidget::updateDocumentationHistory()
{
  updateDocumentationHistory(qobject_cast<LibraryTreeItem*>(sender()));
}

/*!
 * \class DocumentationViewer
 * \brief A webview for displaying the html documentation.
 */
/*!
 * \brief DocumentationViewer::DocumentationViewer
 * \param pDocumentationWidget
 * \param isContentEditable
 */
DocumentationViewer::DocumentationViewer(DocumentationWidget *pDocumentationWidget, bool isContentEditable)
  : QWebView(pDocumentationWidget)
{
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  mpDocumentationWidget = pDocumentationWidget;
  resetZoom();
  // set DocumentationViewer settings
  settings()->setFontFamily(QWebSettings::StandardFont, Helper::systemFontInfo.family());
  settings()->setFontSize(QWebSettings::DefaultFontSize, Helper::systemFontInfo.pointSize());
  settings()->setAttribute(QWebSettings::LocalStorageEnabled, true);
  settings()->setDefaultTextEncoding(Helper::utf8.toStdString().data());
  // set DocumentationViewer web page policy
  page()->setContentEditable(isContentEditable);
  page()->setLinkDelegationPolicy(QWebPage::DelegateAllLinks);
  connect(page(), SIGNAL(linkClicked(QUrl)), SLOT(processLinkClick(QUrl)));
  connect(page(), SIGNAL(linkHovered(QString,QString,QString)), SLOT(processLinkHover(QString,QString,QString)));
  createActions();
}

/*!
 * \brief DocumentationViewer::setFocusInternal
 * Sets the focus on QWebView.\n
 * QWebView need an initial mouse click to show the cursor.
 */
void DocumentationViewer::setFocusInternal()
{
  setFocus(Qt::ActiveWindowFocusReason);
  QPoint center = QPoint(0, 0);
  QMouseEvent *pMouseEvent1 = new QMouseEvent(QEvent::MouseButtonPress, center, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
  QMouseEvent *pMouseEvent2 = new QMouseEvent(QEvent::MouseButtonRelease, center, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
  QApplication::postEvent(this, pMouseEvent1);
  QApplication::postEvent(this, pMouseEvent2);
}

/*!
 * \brief DocumentationViewer::createActions
 */
void DocumentationViewer::createActions()
{
  page()->action(QWebPage::SelectAll)->setShortcut(QKeySequence("Ctrl+a"));
  page()->action(QWebPage::Copy)->setShortcut(QKeySequence("Ctrl+c"));
}

/*!
 * \brief DocumentationViewer::resetZoom
 * Resets the zoom. \n
 * QWebView seems to be using fixed 96 dpi so set a proper base zoomfactor for high resolution screens.
 */
void DocumentationViewer::resetZoom()
{
  QWidget *pScreenWidget = QApplication::desktop()->screen();
  qreal zoomFactor = pScreenWidget->logicalDpiX() / 96;
  setZoomFactor(zoomFactor < 1 ? 1 : zoomFactor);
}

/*!
 * \brief DocumentationViewer::processLinkClick
 * \param url
 * Slot activated when linkClicked signal of webview is raised.
 * Handles the link processing. Sends all the http starting links to the QDesktopServices and process all Modelica starting links.
 */
void DocumentationViewer::processLinkClick(QUrl url)
{
  if (page()->isContentEditable()) {
    return;
  }
  // Send all http requests to desktop services for now.
  // if url contains http or mailto: send it to desktop services
  if ((url.toString().startsWith("http")) || (url.toString().startsWith("mailto:"))) {
    QDesktopServices::openUrl(url);
  } else if (url.scheme().compare("modelica") == 0) { // if the user has clicked on some Modelica Links like modelica://
    // remove modelica:/// from Qurl
    QString resourceLink = url.toString().mid(12);
    /* if the link is a resource e.g .html, .txt or .pdf */
    if (resourceLink.endsWith(".html") || resourceLink.endsWith(".txt") || resourceLink.endsWith(".pdf")) {
      QString resourceAbsoluteFileName = MainWindow::instance()->getOMCProxy()->uriToFilename("modelica://" + resourceLink);
      QDesktopServices::openUrl("file:///" + resourceAbsoluteFileName);
    } else {
      LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(resourceLink);
      // send the new className to DocumentationWidget
      if (pLibraryTreeItem) {
        mpDocumentationWidget->showDocumentation(pLibraryTreeItem);
      }
    }
  } else { // if it is normal http request then check if its not redirected to https
    QNetworkAccessManager* accessManager = page()->networkAccessManager();
    QNetworkRequest request(url);
    QNetworkReply* reply = accessManager->get(request);
    connect(reply, SIGNAL(finished()), SLOT(requestFinished()));
  }
}

/*!
 * \brief DocumentationViewer::requestFinished
 * Slot activated when QNetworkReply finished signal is raised.\n
 * Handles the link redirected to https.
 */
void DocumentationViewer::requestFinished()
{
  QNetworkReply *reply = qobject_cast<QNetworkReply*>(const_cast<QObject*>(sender()));
  QUrl possibleRedirectedUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
  //if the url contains https
  if (possibleRedirectedUrl.toString().contains("https")) {
    QDesktopServices::openUrl(possibleRedirectedUrl);
  } else {
    load(reply->url());
  }
  reply->deleteLater();
}

/*!
 * \brief DocumentationViewer::processLinkHover
 * Slot activated when linkHovered signal of web view is raised.\n
 * Writes the url to the status bar.
 * \param link
 * \param title
 * \param textContent
 */
void DocumentationViewer::processLinkHover(QString link, QString title, QString textContent)
{
  Q_UNUSED(title);
  Q_UNUSED(textContent);
  if (link.isEmpty()) {
    MainWindow::instance()->getStatusBar()->clearMessage();
  } else {
    MainWindow::instance()->getStatusBar()->showMessage(link);
  }
}

/*!
 * \brief DocumentationViewer::showContextMenu
 * Shows a context menu when user right click on the Messages tree.\n
 * Slot activated when DocumentationViewer::customContextMenuRequested() signal is raised.
 * \param point
 */
void DocumentationViewer::showContextMenu(QPoint point)
{
  QMenu menu(this);
  // add QWebPage default actions
  menu.addAction(page()->action(QWebPage::SelectAll));
  menu.addAction(page()->action(QWebPage::Copy));
  menu.exec(mapToGlobal(point));
}

/*!
 * \brief DocumentationViewer::createWindow
 * \param type
 * \return
 */
QWebView* DocumentationViewer::createWindow(QWebPage::WebWindowType type)
{
  Q_UNUSED(type);
  QWebView *webView = new QWebView;
  QWebPage *newWeb = new QWebPage(webView);
  webView->setAttribute(Qt::WA_DeleteOnClose, true);
  webView->setPage(newWeb);
  webView->show();
  return webView;
}

/*!
 * \brief DocumentationViewer::keyPressEvent
 * Reimplementation of keypressevent.
 * Defines what to do for backspace and shift+backspace buttons.
 * \param event
 */
void DocumentationViewer::keyPressEvent(QKeyEvent *event)
{
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  // if editable QWebView
  if (page()->isContentEditable()) {
    if (!shiftModifier && (event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return)) {
//      mpDocumentationWidget->execCommand("insertHTML", "<p><br></p>");
      QWebView::keyPressEvent(event);
    } else {
      QWebView::keyPressEvent(event);
    }
  } else { // if non-editable QWebView
    if (shiftModifier && !controlModifier && event->key() == Qt::Key_Backspace) {
      if (mpDocumentationWidget->getNextAction()->isEnabled()) {
        mpDocumentationWidget->nextDocumentation();
      }
    } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Backspace) {
      if (mpDocumentationWidget->getPreviousAction()->isEnabled()) {
        mpDocumentationWidget->previousDocumentation();
      }
    } else if (controlModifier && event->key() == Qt::Key_A) {
      page()->triggerAction(QWebPage::SelectAll);
    } else {
      QWebView::keyPressEvent(event);
    }
  }
}

/*!
 * \brief DocumentationViewer::wheelEvent
 * Reimplementation of wheelevent.
 * Defines what to do for control+scrolling the wheel
 * \param event
 */
void DocumentationViewer::wheelEvent(QWheelEvent *event)
{
  if (event->orientation() == Qt::Vertical && event->modifiers().testFlag(Qt::ControlModifier)) {
    qreal zf = zoomFactor();
    /* ticket:4349 Take smaller steps for zooming.
     * Also set the minimum zoom to readable size.
     */
    if (event->delta() > 0) {
      zf += 0.1;
      zf = zf > 5 ? 5 : zf;
    } else {
      zf -= 0.1;
      zf = zf < 0.5 ? 0.5 : zf;
    }
    setZoomFactor(zf);
  } else {
    QWebView::wheelEvent(event);
  }
}

/*!
 * \brief DocumentationViewer::mouseDoubleClickEvent
 * Reimplementation of mousedoubleclickevent.
 * Defines what to do for control+doubleclick
 * \param event
 */
void DocumentationViewer::mouseDoubleClickEvent(QMouseEvent *event)
{
  if (event->modifiers().testFlag(Qt::ControlModifier)) {
    resetZoom();
  } else {
    QWebView::mouseDoubleClickEvent(event);
  }
}
