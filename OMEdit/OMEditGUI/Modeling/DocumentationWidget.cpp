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

#include <QNetworkRequest>
#include <QNetworkReply>

//! @class DocumentationWidget
//! @brief Displays the model documentation.

//! Constructor
//! @param pParent is the pointer to MainWindow.
DocumentationWidget::DocumentationWidget(MainWindow *pParent)
  : QWidget(pParent)
{
  setObjectName("DocumentationWidget");
  setMinimumWidth(175);
  mpMainWindow = pParent;
  mDocumentationFile.setFileName(Utilities::tempDirectory() + "/DocumentationWidget.html");
  // create previous and next buttons for documentation navigation
  // create the previous button
  mpPreviousToolButton = new QToolButton;
  mpPreviousToolButton->setText(Helper::previous);
  mpPreviousToolButton->setToolTip(tr("click to go on previous (backspace)"));
  mpPreviousToolButton->setIcon(QIcon(":/Resources/icons/previous.svg"));
  mpPreviousToolButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
  mpPreviousToolButton->setDisabled(true);
  connect(mpPreviousToolButton, SIGNAL(clicked()), SLOT(previousDocumentation()));
  // create the next button
  mpNextToolButton = new QToolButton;
  mpNextToolButton->setText(Helper::next);
  mpNextToolButton->setToolTip(tr("click to go on next (shift+backspace)"));
  mpNextToolButton->setIcon(QIcon(":/Resources/icons/next.svg"));
  mpNextToolButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
  mpNextToolButton->setDisabled(true);
  connect(mpNextToolButton, SIGNAL(clicked()), SLOT(nextDocumentation()));
  // create the documentation viewer
  mpDocumentationViewer = new DocumentationViewer(this);
  // navigation history list
  mpDocumentationHistoryList = new QList<DocumentationHistory>();
  mDocumentationHistoryPos = -1;
  // navigation buttons layout
  QHBoxLayout *pNavigationButtonsLayout = new QHBoxLayout;
  pNavigationButtonsLayout->setContentsMargins(0, 0, 0, 0);
  pNavigationButtonsLayout->setAlignment(Qt::AlignLeft);
  pNavigationButtonsLayout->addWidget(mpPreviousToolButton);
  pNavigationButtonsLayout->addWidget(mpNextToolButton);
  // Documentation viewer layout
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setContentsMargins(0, 0, 0, 0);
  pGridLayout->addWidget(mpDocumentationViewer);
  // add the documentation viewer to the frame for boxed rectangle around it.
  QFrame *layoutFrame = new QFrame;
  layoutFrame->setFrameStyle(QFrame::StyledPanel);
  layoutFrame->setLayout(pGridLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  //pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addLayout(pNavigationButtonsLayout);
  pMainLayout->addWidget(layoutFrame);
  setLayout(pMainLayout);
}

//! Destructor
DocumentationWidget::~DocumentationWidget()
{
  mDocumentationFile.remove();
  delete mpDocumentationHistoryList;
}

MainWindow* DocumentationWidget::getMainWindow()
{
  return mpMainWindow;
}

QToolButton* DocumentationWidget::getPreviousToolButton()
{
  return mpPreviousToolButton;
}

QToolButton* DocumentationWidget::getNextToolButton()
{
  return mpNextToolButton;
}

DocumentationViewer* DocumentationWidget::getDocumentationViewer()
{
  return mpDocumentationViewer;
}

void DocumentationWidget::showDocumentation(LibraryTreeItem *pLibraryTreeItem)
{
  /* Create a local file with the html we want to view as otherwise JavaScript does not run properly. */
  QString documentation = mpMainWindow->getOMCProxy()->getDocumentationAnnotation(pLibraryTreeItem);
  mDocumentationFile.open(QIODevice::WriteOnly | QIODevice::Text);
  QTextStream out(&mDocumentationFile);
  out.setCodec(Helper::utf8.toStdString().data());
  out << documentation;
  mDocumentationFile.close();
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
  }

  if (mDocumentationHistoryPos > 0) {
    mpPreviousToolButton->setDisabled(false);
  } else {
    mpPreviousToolButton->setDisabled(true);
  }

  if (mpDocumentationHistoryList->count() == (mDocumentationHistoryPos + 1)) {
    mpNextToolButton->setDisabled(true);
  } else {
    mpNextToolButton->setDisabled(false);
  }
}

void DocumentationWidget::previousDocumentation()
{
  if (mDocumentationHistoryPos > 0) {
    mDocumentationHistoryPos--;
    showDocumentation(mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem);
  }
}

void DocumentationWidget::nextDocumentation()
{
  if ((mDocumentationHistoryPos + 1) < mpDocumentationHistoryList->count()) {
    mDocumentationHistoryPos++;
    showDocumentation(mpDocumentationHistoryList->at(mDocumentationHistoryPos).mpLibraryTreeItem);
  }
}

//! @class DocumentationViewer
//! @brief A webview for displaying the html documentation.

//! Constructor
//! @param pParent is the pointer to DocumentationWidget.
DocumentationViewer::DocumentationViewer(DocumentationWidget *pParent)
  : QWebView(pParent)
{
  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  mpDocumentationWidget = pParent;
  mZoomFactor = 1.;
  setZoomFactor(mZoomFactor);
  // set DocumentationViewer settings
  settings()->setFontFamily(QWebSettings::StandardFont, Helper::systemFontInfo.family());
  settings()->setFontSize(QWebSettings::DefaultFontSize, Helper::systemFontInfo.pointSize());
  settings()->setAttribute(QWebSettings::LocalStorageEnabled, true);
  settings()->setDefaultTextEncoding(Helper::utf8.toStdString().data());
  // set DocumentationViewer web page policy
  page()->setLinkDelegationPolicy(QWebPage::DelegateAllLinks);
  connect(page(), SIGNAL(linkClicked(QUrl)), SLOT(processLinkClick(QUrl)));
  connect(page(), SIGNAL(linkHovered(QString,QString,QString)), SLOT(processLinkHover(QString,QString,QString)));
  createActions();
}

void DocumentationViewer::createActions()
{
  page()->action(QWebPage::SelectAll)->setShortcut(QKeySequence("Ctrl+a"));
  page()->action(QWebPage::Copy)->setShortcut(QKeySequence("Ctrl+c"));
}

/*!
 * \brief DocumentationViewer::processLinkClick
 * \param url
 * Slot activated when linkClicked signal of webview is raised.
 * Handles the link processing. Sends all the http starting links to the QDesktopServices and process all Modelica starting links.
 */
void DocumentationViewer::processLinkClick(QUrl url)
{
  // Send all http requests to desktop services for now.
  // if url contains http or mailto: send it to desktop services
  if ((url.toString().startsWith("http")) || (url.toString().startsWith("mailto:"))) {
    QDesktopServices::openUrl(url);
  } else if (url.scheme().compare("modelica") == 0) { // if the user has clicked on some Modelica Links like modelica://
    // remove modelica:/// from Qurl
    QString resourceLink = url.toString().mid(12);
    /* if the link is a resource e.g .html, .txt or .pdf */
    if (resourceLink.endsWith(".html") || resourceLink.endsWith(".txt") || resourceLink.endsWith(".pdf")) {
      QString resourceAbsoluteFileName = mpDocumentationWidget->getMainWindow()->getOMCProxy()->uriToFilename("modelica://" + resourceLink);
      QDesktopServices::openUrl("file:///" + resourceAbsoluteFileName);
    } else {
      LibraryTreeItem *pLibraryTreeItem = mpDocumentationWidget->getMainWindow()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(resourceLink);
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

//! Slot activated when QNetworkReply finished signal is raised.
//! Handles the link redirected to https.
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

//! Slot activated when linkHovered signal of web view is raised.
//! Writes the url to the status bar.
void DocumentationViewer::processLinkHover(QString link, QString title, QString textContent)
{
  Q_UNUSED(title);
  Q_UNUSED(textContent);
  if (link.isEmpty()) {
    mpDocumentationWidget->getMainWindow()->getStatusBar()->clearMessage();
  } else {
    mpDocumentationWidget->getMainWindow()->getStatusBar()->showMessage(link);
  }
}

//! Shows a context menu when user right click on the Messages tree.
//! Slot activated when DocumentationViewer::customContextMenuRequested() signal is raised.
void DocumentationViewer::showContextMenu(QPoint point)
{
  QMenu menu(this);
  // add QWebPage default actions
  menu.addAction(page()->action(QWebPage::SelectAll));
  menu.addAction(page()->action(QWebPage::Copy));
  menu.exec(mapToGlobal(point));
}

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
      mZoomFactor+=event->delta()/120.;
      if (mZoomFactor > 5.) mZoomFactor = 5.;
      if (mZoomFactor < .1) mZoomFactor = .1;
      setZoomFactor(mZoomFactor);
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
    mZoomFactor=1.;
    setZoomFactor(mZoomFactor);
  } else {
    QWebView::mouseDoubleClickEvent(event);
  }
}
