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

/*
 * RCS: $Id$
 */

#include <QNetworkRequest>
#include <QNetworkReply>
#include "DocumentationWidget.h"

//! @class DocumentationWidget
//! @brief Displays the model documentation.

//! Constructor
//! @param pParent is the pointer to MainWindow.
DocumentationWidget::DocumentationWidget(MainWindow *pParent)
  : QWidget(pParent), mDocumentationFile(QDir::tempPath() + "/OpenModelica/OMEdit/DocumentationWidget.html")
{
  setObjectName("DocumentationWidget");
  mpParentMainWindow = pParent;
  mpDocumentationViewer = new DocumentationViewer(this);
  mpDocumentationEditor = new DocumentationEditor(this);
  mpUrlHistory = new QList<UrlSrc>();
  mUrlHistoryPos = -1;
  mpHeadingLabel = new QPlainTextEdit;
  mpHeadingLabel->setObjectName("DocumentationLabel");
  mpHeadingLabel->setReadOnly(true);
  mpHeadingLabel->setFont(QFont("", Helper::headingFontSize - 5));
  mpPixmapLabel = new QLabel;
  mpPixmapLabel->setObjectName("componentPixmap");
  mpPixmapLabel->setMaximumSize(QSize(86, 86));
  mpPixmapLabel->setFrameStyle(QFrame::Sunken | QFrame::StyledPanel);
  mpPixmapLabel->setAlignment(Qt::AlignCenter);
  // create buttons
  mpEditButton = new QPushButton(Helper::edit);
  mpEditButton->setAutoDefault(true);
  mpEditButton->setMaximumSize(QSize(120,20));
  mpEditButton->setVisible(false);
  connect(mpEditButton, SIGNAL(clicked()), SLOT(editDocumentation()));
  mpSaveButton = new QPushButton(Helper::save);
  mpSaveButton->setAutoDefault(false);
  mpSaveButton->setMaximumSize(QSize(100,20));
  mpSaveButton->setVisible(false);
  connect(mpSaveButton, SIGNAL(clicked()), SLOT(saveChanges()));
  mpBackButton = new QPushButton(Helper::backwardBrush);
  mpBackButton->setAutoDefault(false);
  mpBackButton->setMaximumSize(QSize(120,20));
  mpBackButton->setVisible(false);
  connect(mpBackButton, SIGNAL(clicked()), SLOT(back()));
  mpForwardButton = new QPushButton(Helper::forwardBrush);
  mpForwardButton->setAutoDefault(false);
  mpForwardButton->setMaximumSize(QSize(120,20));
  mpForwardButton->setVisible(false);
  connect(mpForwardButton, SIGNAL(clicked()), SLOT(forward()));
  QHBoxLayout *horizontalLayout = new QHBoxLayout;
  horizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  horizontalLayout->addWidget(mpPixmapLabel);
  horizontalLayout->addWidget(mpHeadingLabel);
  QHBoxLayout *horizontalLayout2 = new QHBoxLayout;
  horizontalLayout2->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  horizontalLayout2->addWidget(mpBackButton);
  horizontalLayout2->addWidget(mpForwardButton);
  QHBoxLayout *horizontalLayout3 = new QHBoxLayout;
  horizontalLayout3->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  horizontalLayout3->addWidget(mpSaveButton);
  horizontalLayout3->addWidget(mpEditButton);
  // set layout
  QVBoxLayout *verticalLayout = new QVBoxLayout;
  verticalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  verticalLayout->addLayout(horizontalLayout);
  verticalLayout->addLayout(horizontalLayout2);
  verticalLayout->addLayout(horizontalLayout3);
  verticalLayout->addWidget(mpDocumentationViewer,1);
  verticalLayout->addWidget(mpDocumentationEditor,1);
  setLayout(verticalLayout);
  mpDocumentationViewer->setVisible(false);
  mpDocumentationEditor->setVisible(false);
  mpPixmapLabel->setVisible(false);
}

//! Destructor
DocumentationWidget::~DocumentationWidget()
{
  mDocumentationFile.remove();
  delete mpDocumentationViewer;
  delete mpDocumentationEditor;
}

//! Shows the documentation of a model
//! @param className the model name
void DocumentationWidget::show(QString className, bool isCustomModel)
{
  mClassName = className;
  mpHeadingLabel->setPlainText(className);

  LibraryComponent *libraryComponent = mpParentMainWindow->mpLibrary->getLibraryComponentObject(className);
  if(libraryComponent)
  {
    mpPixmapLabel->setVisible(true);
    mpPixmapLabel->setPixmap(libraryComponent->getComponentPixmap(QSize(75, 75)));
  }
  else
  {
    mpPixmapLabel->setVisible(false);
  }
  // show edit and save buttons if show is called for a custom model
  if (isCustomModel)
  {
    mpEditButton->setVisible(true);
    //mpEditButton->setDisabled(false);
    mpEditButton->setText(Helper::edit);
    mpSaveButton->setVisible(true);
    mpSaveButton->setDisabled(true);
  }
  else
  {
    mpEditButton->setVisible(false);
    mpSaveButton->setVisible(false);
  }
  QString documentation = mpParentMainWindow->mpOMCProxy->getDocumentationAnnotation(className);
  //! @todo Ugly way to update images links. Fix it ASAP.
  //! @todo Fix MSL to use image link as modelica://.
  // We need to replace the back slashes(\) with forward slash(/), since QWebView baseurl doesn't handle it.
  documentation = documentation.replace("src=\"../Images", "src=\"" + QString(Helper::OpenModelicaLibrary).replace("\\", "/").append("/Modelica ").append(Helper::OpenModelicaLibraryVersion).append("/Images"));
  /* Create a local file with the html we want to view as otherwise
   * JavaScript does not run properly.
   */
  mDocumentationFile.open(QIODevice::WriteOnly | QIODevice::Text);
  QTextStream out(&mDocumentationFile);
  out << documentation;
  mDocumentationFile.close();

  if ((mUrlHistoryPos >= 0) && (className == mpUrlHistory->at(mUrlHistoryPos).url))
  {
    /* reload url */
  }
  else
  {
    /* new url */
    /* remove all following urls */
    while (mpUrlHistory->count() > (mUrlHistoryPos+1))
    {
      mpUrlHistory->removeLast();
    }
    /* append new url */
    mpUrlHistory->append(UrlSrc(className, isCustomModel));
    mUrlHistoryPos++;
  }
  if (mUrlHistoryPos > 0)
  {
      mpBackButton->setDisabled(false);
  }
  else
  {
      mpBackButton->setDisabled(true);
  }
  if (mpUrlHistory->count() == (mUrlHistoryPos+1))
  {
      mpForwardButton->setDisabled(true);
  }
  else
  {
      mpForwardButton->setDisabled(false);
  }

  mpDocumentationViewer->setUrl(mDocumentationFile.fileName());
  mpDocumentationViewer->setVisible(true);
  mpBackButton->setVisible(true);
  mpForwardButton->setVisible(true);

  mpDocumentationEditor->hide();
}

//! Shows the documenation editing view.
//! @param className the model name
void DocumentationWidget::showDocumentationEditView(QString className)
{
  mpDocumentationViewer->hide();
  // get the already existing documentation text of the model
  QString doc = mpParentMainWindow->mpOMCProxy->getDocumentationAnnotation(className);
  if (!doc.isEmpty())
    mpDocumentationEditor->setPlainText(doc);
  else
    mpDocumentationEditor->setPlainText("<html>\n\n</html>");
  mpDocumentationEditor->setFocus();
  mpDocumentationEditor->show();
}

//! Reimplementation of paintevent. Draws a rectangle around QWidget
void DocumentationWidget::paintEvent(QPaintEvent *event)
{
  QPainter painter(this);
  painter.setPen(Qt::gray);
  QRect rectangle = rect();
  rectangle.setWidth(rect().width() - 1);
  rectangle.setHeight(rect().height() - 1);
  painter.drawRect(rectangle);
  QWidget::paintEvent(event);
}

void DocumentationWidget::editDocumentation()
{
  if (mpSaveButton->isEnabled() == false)
  {
    showDocumentationEditView(mClassName);
    //mpEditButton->setDisabled(true);
    mpEditButton->setText(Helper::cancel);
    mpSaveButton->setDisabled(false);
    mpBackButton->setDisabled(true);
    mpForwardButton->setDisabled(true);
  }
  else
  {
    show(mClassName,true);
  }
}

//! Save the changes made to the documentation of the model.
void DocumentationWidget::saveChanges()
{
  QString doc = mpDocumentationEditor->toPlainText();
  if(doc.startsWith("<html>", Qt::CaseInsensitive) && doc.endsWith("</html>", Qt::CaseInsensitive))
  {
    mpParentMainWindow->mpOMCProxy->addClassAnnotation(mClassName,"annotate=Documentation(info = \""+StringHandler::escape(doc)+"\")");
    show(mClassName,true);
  }
  else
  {
    QString message = QString(GUIMessages::getMessage(GUIMessages::INCORRECT_HTML_TAGS));
    mpParentMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, message, Helper::scriptingKind,
                                                                       Helper::errorLevel, 0, mpParentMainWindow->mpMessageWidget->mpProblem));
  }
}

//! Go to previous document
void DocumentationWidget::back()
{
  if (mUrlHistoryPos > 0)
  {
      mUrlHistoryPos--;
      show(mpUrlHistory->at(mUrlHistoryPos).url,mpUrlHistory->at(mUrlHistoryPos).isCustomModel);
  }
}

//! Go to next document
void DocumentationWidget::forward()
{
  if ((mUrlHistoryPos+1) < mpUrlHistory->count())
  {
      mUrlHistoryPos++;
      show(mpUrlHistory->at(mUrlHistoryPos).url,mpUrlHistory->at(mUrlHistoryPos).isCustomModel);
  }
}

//! @class DocumentationEditor
//! @brief An editor for editing the documentation of the model.

//! Constructor
//! @param pParent is the pointer to DocumentationWidget.
DocumentationEditor::DocumentationEditor(DocumentationWidget *pParent)
  : QTextEdit(pParent)
{
  mpParentDocumentationWidget = pParent;
  setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  setTabStopWidth(Helper::tabWidth);
  setObjectName("DocumentationEditor");
  setAutoFormatting(QTextEdit::AutoNone);
  setAcceptRichText(false);
  setFontFamily(qApp->font().family());             // get system font
  setFontPointSize(10.0);
}

//! @class DocumentationViewer
//! @brief A webview for displaying the html documentation.

//! Constructor
//! @param pParent is the pointer to DocumentationWidget.
DocumentationViewer::DocumentationViewer(DocumentationWidget *pParent)
  : QWebView(pParent)
{
  mpParentDocumentationWidget = pParent;
  // set page font settings
  settings()->setFontFamily(QWebSettings::StandardFont, "Verdana");
  settings()->setFontSize(QWebSettings::DefaultFontSize, 10);
  settings()->setAttribute(QWebSettings::LocalStorageEnabled, 1);
  // set page links settings
  page()->setLinkDelegationPolicy(QWebPage::DelegateAllLinks);

  connect(this, SIGNAL(linkClicked(QUrl)), SLOT(processLinkClick(QUrl)));
  connect(page(), SIGNAL(linkHovered(QString,QString,QString)), SLOT(processLinkHover(QString,QString,QString)));
}

//! Slot activated when linkClicked signal of webview is raised.
//! Handles the link processing. Sends all the http starting links to the QDesktopServices and process all Modelica starting links.
void DocumentationViewer::processLinkClick(QUrl url)
{
  //! @todo
  /* Send all http requests to desktop services for now. If we need to display web pages then we will change it,
       but for now else portion is never reached. */

  // if url contains http or mailto: send it to desktop services
  if ((url.toString().startsWith("http")) or (url.toString().startsWith("mailto:")))
  {
    QDesktopServices::openUrl(url);
  }

  //! @todo Fix MSL to one standard. Some places the links are reference as Modelica:/ and at some places as modelica://
  // if the user has clicked on some Modelica Links like Modelica:/
  else if (url.toString().startsWith("Modelica", Qt::CaseInsensitive))
  {
    // remove Modelica:/ from link
    QString className;
    className = url.toString().mid(10, url.toString().length() - 1);
    // send the new className to DocumentationWidget
    mpParentDocumentationWidget->show(className, false);
  }
  // if it is normal http request then check if its not redirected to https
  else
  {
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
  if (possibleRedirectedUrl.toString().contains("https"))
    QDesktopServices::openUrl(possibleRedirectedUrl);
  else
    load(reply->url());

  reply->deleteLater();
}

//! Slot activated when linkHovered signal of web view is raised.
//! Writes the url to the status bar.
void DocumentationViewer::processLinkHover(QString link, QString title, QString textContent)
{
  Q_UNUSED(title);
  Q_UNUSED(textContent);

  if (link.isEmpty())
    mpParentDocumentationWidget->mpParentMainWindow->mpStatusBar->clearMessage();
  else
    mpParentDocumentationWidget->mpParentMainWindow->mpStatusBar->showMessage(link);
}

//! Reimplementation of mousePressEvent.
//! Disables the webview rightclick.
void DocumentationViewer::mousePressEvent(QMouseEvent *event)
{
  // dont allow right click on Documentation Viewer
  if (event->button() == Qt::LeftButton)
  {
    QWebView::mousePressEvent(event);
  }
  else if (event->button() == Qt::RightButton)
  {
    event->ignore();
  }
}

QWebView *DocumentationViewer::createWindow(QWebPage::WebWindowType type)
{
    Q_UNUSED(type);

    QWebView *webView = new QWebView;
    QWebPage *newWeb = new QWebPage(webView);
    webView->setAttribute(Qt::WA_DeleteOnClose, true);
    webView->setPage(newWeb);
    webView->show();

    return webView;
}
