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
#include <QToolBar>
#include <QMenu>
#include <QDesktopServices>
#include <QApplication>
#include <QDesktopWidget>
#include <QWebFrame>

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
  setMinimumWidth(175);
  mDocumentationFile.setFileName(Utilities::tempDirectory() + "/DocumentationWidget.html");
  // create previous and next buttons for documentation navigation
  // create the previous button
  mpPreviousToolButton = new QToolButton;
  mpPreviousToolButton->setText(Helper::previous);
  mpPreviousToolButton->setToolTip(tr("Previous (backspace)"));
  mpPreviousToolButton->setIcon(QIcon(":/Resources/icons/previous.svg"));
  mpPreviousToolButton->setAutoRaise(true);
  mpPreviousToolButton->setDisabled(true);
  connect(mpPreviousToolButton, SIGNAL(clicked()), SLOT(previousDocumentation()));
  // create the next button
  mpNextToolButton = new QToolButton;
  mpNextToolButton->setText(Helper::next);
  mpNextToolButton->setToolTip(tr("Next (shift+backspace)"));
  mpNextToolButton->setIcon(QIcon(":/Resources/icons/next.svg"));
  mpNextToolButton->setAutoRaise(true);
  mpNextToolButton->setDisabled(true);
  connect(mpNextToolButton, SIGNAL(clicked()), SLOT(nextDocumentation()));
  // create the edit info button
  mpEditInfoToolButton = new QToolButton;
  mpEditInfoToolButton->setText(tr("Edit Info"));
  mpEditInfoToolButton->setToolTip(tr("Edit Info Documentation"));
  mpEditInfoToolButton->setIcon(QIcon(":/Resources/icons/edit-info.svg"));
  mpEditInfoToolButton->setAutoRaise(true);
  mpEditInfoToolButton->setDisabled(true);
  connect(mpEditInfoToolButton, SIGNAL(clicked()), SLOT(editInfoDocumentation()));
  // create the edit revisions button
  mpEditRevisionsToolButton = new QToolButton;
  mpEditRevisionsToolButton->setText(tr("Edit Revisions"));
  mpEditRevisionsToolButton->setToolTip(tr("Edit Revisions Documentation"));
  mpEditRevisionsToolButton->setIcon(QIcon(":/Resources/icons/edit-revisions.svg"));
  mpEditRevisionsToolButton->setAutoRaise(true);
  mpEditRevisionsToolButton->setDisabled(true);
  connect(mpEditRevisionsToolButton, SIGNAL(clicked()), SLOT(editRevisionsDocumentation()));
  // create the edit infoHeader button
  mpEditInfoHeaderToolButton = new QToolButton;
  mpEditInfoHeaderToolButton->setText(tr("Edit __OpenModelica_infoHeader"));
  mpEditInfoHeaderToolButton->setToolTip(tr("Edit __OpenModelica_infoHeader Documentation"));
  mpEditInfoHeaderToolButton->setIcon(QIcon(":/Resources/icons/edit-info-header.svg"));
  mpEditInfoHeaderToolButton->setAutoRaise(true);
  mpEditInfoHeaderToolButton->setDisabled(true);
  connect(mpEditInfoHeaderToolButton, SIGNAL(clicked()), SLOT(editInfoHeaderDocumentation()));
  // create the save button
  mpSaveToolButton = new QToolButton;
  mpSaveToolButton->setText(Helper::save);
  mpSaveToolButton->setToolTip(tr("Save Documentation"));
  mpSaveToolButton->setIcon(QIcon(":/Resources/icons/save.svg"));
  mpSaveToolButton->setAutoRaise(true);
  mpSaveToolButton->setDisabled(true);
  connect(mpSaveToolButton, SIGNAL(clicked()), SLOT(saveDocumentation()));
  // create the cancel button
  mpCancelToolButton = new QToolButton;
  mpCancelToolButton->setText(Helper::cancel);
  mpCancelToolButton->setToolTip(tr("Cancel Documentation"));
  mpCancelToolButton->setIcon(QIcon(":/Resources/icons/delete.svg"));
  mpCancelToolButton->setAutoRaise(true);
  mpCancelToolButton->setDisabled(true);
  connect(mpCancelToolButton, SIGNAL(clicked()), SLOT(cancelDocumentation()));
  // create the documentation viewer
  mpDocumentationViewer = new DocumentationViewer(this, false);
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
  // editor buttons
  QToolButton *pBoldToolButton = new QToolButton;
  pBoldToolButton->setText(tr("Bold"));
  pBoldToolButton->setToolTip(tr("Cancel Documentation"));
  pBoldToolButton->setIcon(QIcon(":/Resources/icons/delete.svg"));
  pBoldToolButton->setToolButtonStyle(Qt::ToolButtonIconOnly);
  QStatusBar *pEditorButtonsStatusBar = new QStatusBar;
  pEditorButtonsStatusBar->setObjectName("ModelStatusBar");
  pEditorButtonsStatusBar->setStyleSheet("QStatusBar{border-bottom: none;} QStatusBar::item{margin-bottom: -1px;}");
  pEditorButtonsStatusBar->setSizeGripEnabled(false);
//  pEditorButtonsStatusBar->addWidget(pBoldToolButton);
  // create the html editor viewer
  mpHTMLEditor = new DocumentationViewer(this, true);
  // add a layout to html editor widget
  QVBoxLayout *pHTMLWidgetLayout = new QVBoxLayout;
  pHTMLWidgetLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pHTMLWidgetLayout->setContentsMargins(0, 0, 0, 0);
  pHTMLWidgetLayout->setSpacing(0);
  pHTMLWidgetLayout->addWidget(pEditorButtonsStatusBar);
  pHTMLWidgetLayout->addWidget(mpHTMLEditor, 1);
  mpHTMLEditorWidget->setLayout(pHTMLWidgetLayout);
  // create the HTMLEditor
  mpHTMLSourceEditor = new HTMLEditor(this);
  mpHTMLSourceEditor->hide();
  HTMLHighlighter *pHTMLHighlighter = new HTMLHighlighter(OptionsDialog::instance()->getHTMLEditorPage(), mpHTMLSourceEditor->getPlainTextEdit());
  connect(OptionsDialog::instance(), SIGNAL(HTMLEditorSettingsChanged()), pHTMLHighlighter, SLOT(settingsChanged()));
  // eidtors widget layout
  QVBoxLayout *pEditorsWidgetLayout = new QVBoxLayout;
  pEditorsWidgetLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
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
  // Documentation buttons layout
  QHBoxLayout *pNavigationButtonsLayout = new QHBoxLayout;
  pNavigationButtonsLayout->setContentsMargins(0, 0, 0, 0);
  pNavigationButtonsLayout->setSpacing(0);
  pNavigationButtonsLayout->setAlignment(Qt::AlignLeft);
  pNavigationButtonsLayout->addWidget(mpPreviousToolButton);
  pNavigationButtonsLayout->addWidget(mpNextToolButton);
  // navigation buttons frame
  QFrame *pNavigationButtonsFrame = new QFrame;
  pNavigationButtonsFrame->setLayout(pNavigationButtonsLayout);
  // edit buttons layout
  QHBoxLayout *pEditButtonsLayout = new QHBoxLayout;
  pEditButtonsLayout->setContentsMargins(0, 0, 0, 0);
  pEditButtonsLayout->setSpacing(0);
  pEditButtonsLayout->setAlignment(Qt::AlignLeft);
  pEditButtonsLayout->addWidget(mpEditInfoToolButton);
  pEditButtonsLayout->addWidget(mpEditRevisionsToolButton);
  pEditButtonsLayout->addWidget(mpEditInfoHeaderToolButton);
  // edit buttons frame
  QFrame *pEditButtonsFrame = new QFrame;
  pEditButtonsFrame->setLayout(pEditButtonsLayout);
  // save buttons layout
  QHBoxLayout *pSaveButtonsLayout = new QHBoxLayout;
  pSaveButtonsLayout->setContentsMargins(0, 0, 0, 0);
  pSaveButtonsLayout->setSpacing(0);
  pSaveButtonsLayout->setAlignment(Qt::AlignLeft);
  pSaveButtonsLayout->addWidget(mpSaveToolButton);
  pSaveButtonsLayout->addWidget(mpCancelToolButton);
  // save buttons frame
  QFrame *pSaveButtonsFrame = new QFrame;
  pSaveButtonsFrame->setLayout(pSaveButtonsLayout);
  // buttons status bar
  QStatusBar *pDocumentationButtonsStatusBar = new QStatusBar;
  pDocumentationButtonsStatusBar->setObjectName("ModelStatusBar");
  pDocumentationButtonsStatusBar->setSizeGripEnabled(false);
  pDocumentationButtonsStatusBar->addWidget(pNavigationButtonsFrame);
  pDocumentationButtonsStatusBar->addWidget(pEditButtonsFrame);
  pDocumentationButtonsStatusBar->addWidget(pSaveButtonsFrame);
  // Documentation viewer layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setContentsMargins(0, 0, 0, 0);
  pGridLayout->addWidget(mpDocumentationViewer);
  pGridLayout->addWidget(mpEditorsWidget);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pDocumentationButtonsStatusBar);
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
  mpEditInfoToolButton->setDisabled(pLibraryTreeItem->isSystemLibrary());
  mpEditRevisionsToolButton->setDisabled(pLibraryTreeItem->isSystemLibrary());
  mpEditInfoHeaderToolButton->setDisabled(pLibraryTreeItem->isSystemLibrary());
  mpSaveToolButton->setDisabled(true);
  mpCancelToolButton->setDisabled(true);
  mpDocumentationViewer->show();
  mpEditorsWidget->hide();
}

/*!
 * \brief DocumentationWidget::updatePreviousNextButtons
 * Updates the previous and next button.
 */
void DocumentationWidget::updatePreviousNextButtons()
{
  // update previous button
  if (mDocumentationHistoryPos > 0) {
    mpPreviousToolButton->setDisabled(false);
  } else {
    mpPreviousToolButton->setDisabled(true);
  }
  // update next button
  if (mpDocumentationHistoryList->count() == (mDocumentationHistoryPos + 1)) {
    mpNextToolButton->setDisabled(true);
  } else {
    mpNextToolButton->setDisabled(false);
  }
}

/*!
 * \brief DocumentationWidget::writeDocumentationFile
 * \param documentation
 */
void DocumentationWidget::writeDocumentationFile(QString documentation)
{
  /* Create a local file with the html we want to view as otherwise JavaScript does not run properly. */
  mDocumentationFile.open(QIODevice::WriteOnly | QIODevice::Text);
  QTextStream out(&mDocumentationFile);
  out.setCodec(Helper::utf8.toStdString().data());
  out << documentation;
  mDocumentationFile.close();
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
      mpPreviousToolButton->setDisabled(true);
      mpNextToolButton->setDisabled(true);
      mpEditInfoToolButton->setDisabled(true);
      mpEditRevisionsToolButton->setDisabled(true);
      mpEditInfoHeaderToolButton->setDisabled(true);
      mpSaveToolButton->setDisabled(false);
      mpCancelToolButton->setDisabled(false);
      mpDocumentationViewer->hide();
      mpEditorsWidget->show();
      mpTabBar->setCurrentIndex(0);
      mpHTMLEditor->setFocus(Qt::ActiveWindowFocusReason);
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
      mpPreviousToolButton->setDisabled(true);
      mpNextToolButton->setDisabled(true);
      mpEditInfoToolButton->setDisabled(true);
      mpEditRevisionsToolButton->setDisabled(true);
      mpEditInfoHeaderToolButton->setDisabled(true);
      mpSaveToolButton->setDisabled(false);
      mpCancelToolButton->setDisabled(false);
      mpDocumentationViewer->hide();
      mpEditorsWidget->show();
      mpTabBar->setCurrentIndex(0);
      mpHTMLEditor->setFocus(Qt::ActiveWindowFocusReason);
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
      mpPreviousToolButton->setDisabled(true);
      mpNextToolButton->setDisabled(true);
      mpEditInfoToolButton->setDisabled(true);
      mpEditRevisionsToolButton->setDisabled(true);
      mpEditInfoHeaderToolButton->setDisabled(true);
      mpSaveToolButton->setDisabled(false);
      mpCancelToolButton->setDisabled(false);
      mpDocumentationViewer->hide();
      mpEditorsWidget->show();
      mpTabBar->setCurrentIndex(0);
      mpHTMLEditor->setFocus(Qt::ActiveWindowFocusReason);
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
      if (mpHTMLEditor->isModified()) {
        mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(mpHTMLEditor->page()->mainFrame()->toHtml());
      }
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
  mpEditInfoToolButton->setDisabled(false);
  mpEditRevisionsToolButton->setDisabled(false);
  mpEditInfoHeaderToolButton->setDisabled(false);
  mpSaveToolButton->setDisabled(true);
  mpCancelToolButton->setDisabled(true);
  mpDocumentationViewer->show();
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
      if (mpHTMLEditor->isModified()) {
        mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(mpHTMLEditor->page()->mainFrame()->toHtml());
      } else {
        LibraryTreeItem *pLibraryTreeItem = mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem;
        if (pLibraryTreeItem && !pLibraryTreeItem->isNonExisting()) {
          QList<QString> documentation = MainWindow::instance()->getOMCProxy()->getDocumentationAnnotationInClass(pLibraryTreeItem);
          if (mEditType == EditType::Info) {
            mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(documentation.at(0));
          } else if (mEditType == EditType::Revisions) {
            mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(documentation.at(1));
          } else if (mEditType == EditType::InfoHeader) {
            mpHTMLSourceEditor->getPlainTextEdit()->setPlainText(documentation.at(2));
          }
        }
      }
      mpHTMLSourceEditor->getPlainTextEdit()->setFocus(Qt::ActiveWindowFocusReason);
      break;
    case 0:
    default:
      mpHTMLSourceEditor->hide();
      mpHTMLEditorWidget->show();
      mpHTMLEditor->setFocus(Qt::ActiveWindowFocusReason);
      break;
  }
}

/*!
 * \brief DocumentationWidget::updateDocumentationHistory
 * Slot activated when LibraryTreeItem unloaded SIGNAL is raised.\n
 * Removes the corresponding LibraryTreeItem from the DocumentationHistory.
 */
void DocumentationWidget::updateDocumentationHistory()
{
  LibraryTreeItem *pLibraryTreeItem = qobject_cast<LibraryTreeItem*>(sender());
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
        mpEditInfoToolButton->setDisabled(true);
        mpEditRevisionsToolButton->setDisabled(true);
        mpEditInfoHeaderToolButton->setDisabled(true);
        mpSaveToolButton->setDisabled(true);
        mpCancelToolButton->setDisabled(true);
        mpDocumentationViewer->setHtml(""); // clear if we don't have any documentation to show
        mpDocumentationViewer->show();
        mpEditorsWidget->hide();
        mEditType = EditType::None;
      }
    }
  }
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
  setZoomFactor(pScreenWidget->logicalDpiX() / 96);
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

void DocumentationViewer::paintEvent(QPaintEvent *event)
{
  QWebView::paintEvent(event);
  QPainter painter(this);
  painter.setPen(Qt::gray);
  QRect rectangle = rect();
  rectangle.setWidth(rect().width() - 1);
  rectangle.setHeight(height() - 1);
  painter.drawRect(rectangle);
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
  if (page()->isContentEditable()) {
    QWebView::keyPressEvent(event);
    return;
  }
  bool shiftModifier = event->modifiers().testFlag(Qt::ShiftModifier);
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  if (shiftModifier && !controlModifier && event->key() == Qt::Key_Backspace) {
    if (mpDocumentationWidget->getNextToolButton()->isEnabled()) {
      mpDocumentationWidget->nextDocumentation();
    }
  } else if (!shiftModifier && !controlModifier && event->key() == Qt::Key_Backspace) {
    if (mpDocumentationWidget->getPreviousToolButton()->isEnabled()) {
      mpDocumentationWidget->previousDocumentation();
    }
  } else if (controlModifier && event->key() == Qt::Key_A) {
    page()->triggerAction(QWebPage::SelectAll);
  } else {
    QWebView::keyPressEvent(event);
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
    zf += event->delta()/120.;
    if (zf > 5.) zf = 5.;
    if (zf < .1) zf = .1;
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
