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

#include "DocumentationWidget.h"

DocumentationWidget::DocumentationWidget(MainWindow *pParent)
    : QWidget(pParent)
{
    mpParentMainWindow = pParent;
    mpDocumentationViewer = new DocumentationViewer(this);
    mpDocumentationEditor = new DocumentationEditor(this);
    setIsCustomModel(false);
    mpHeadingLabel = new QLabel;
    mpHeadingLabel->setFont(QFont("", Helper::headingFontSize - 5));
    mpHeadingLabel->setAlignment(Qt::AlignTop);

    mpPixmapLabel = new QLabel;
    mpPixmapLabel->setObjectName(tr("componentPixmap"));
    mpPixmapLabel->setMaximumSize(QSize(86, 86));
    mpPixmapLabel->setFrameStyle(QFrame::Sunken | QFrame::StyledPanel);
    mpPixmapLabel->setAlignment(Qt::AlignCenter);

    mpEditButton = new QPushButton(tr("Edit"));
    mpEditButton->setAutoDefault(true);
    mpEditButton->setMaximumSize(QSize(100,20));
    connect(mpEditButton, SIGNAL(pressed()), SLOT(editDocumentation()));
    mpSaveButton = new QPushButton(tr("Save"));
    mpSaveButton->setAutoDefault(false);
    mpSaveButton->setMaximumSize(QSize(100,20));
    connect(mpSaveButton, SIGNAL(pressed()), SLOT(saveChanges()));
    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    horizontalLayout->addWidget(mpPixmapLabel);
    horizontalLayout->addWidget(mpHeadingLabel);
    horizontalLayout->addWidget(mpSaveButton);
    horizontalLayout->addWidget(mpEditButton);

    QVBoxLayout *verticalLayout = new QVBoxLayout;
    verticalLayout->addLayout(horizontalLayout);
    verticalLayout->addWidget(mpDocumentationViewer);
    verticalLayout->addWidget(mpDocumentationEditor);

    setLayout(verticalLayout);
}

DocumentationWidget::~DocumentationWidget()
{
    delete mpDocumentationViewer;
    delete mpDocumentationEditor;
}

void DocumentationWidget::show(QString className)
{
    mClassName=className;
    mpHeadingLabel->setText(className);    

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
    if (isCustomModel())
    {
        mpEditButton->setVisible(true);
        mpEditButton->setDisabled(false);
        mpSaveButton->setVisible(true);
        mpSaveButton->setDisabled(true);
    }
    else
    {
        mpEditButton->setVisible(false);
        mpSaveButton->setVisible(false);
    }
    QString documentation = mpParentMainWindow->mpOMCProxy->getDocumentationAnnotation(className);
    mpDocumentationViewer->setHtml(documentation, mpDocumentationViewer->getBaseUrl());
    mpDocumentationViewer->setVisible(true);
    mpDocumentationEditor->setVisible(false);
}

void DocumentationWidget::showDocumentationEditView(QString className)
{
    mpDocumentationViewer->hide();
    // get the already existing documentation text of the model
    mpDocumentationEditor->toPlainText();
    if (!mpParentMainWindow->mpOMCProxy->getDocumentationAnnotation(className).isEmpty())
        mpDocumentationEditor->setPlainText(mpParentMainWindow->mpOMCProxy->getDocumentationAnnotation(className));
    else
        mpDocumentationEditor->setPlainText("<html>\n\n</html>");
    mpDocumentationEditor->setFocus();
    mpDocumentationEditor->show();
}

void DocumentationWidget::setIsCustomModel(bool isCustomModel)
{
    mIsCustomModel = isCustomModel;
}

bool DocumentationWidget::isCustomModel()
{
    return mIsCustomModel;
}

void DocumentationWidget::editDocumentation()
{
    showDocumentationEditView(mClassName);
    mpEditButton->setDisabled(true);
    mpSaveButton->setDisabled(false);
}

void DocumentationWidget::saveChanges()
{
    QString doc = mpDocumentationEditor->toPlainText();
    if(doc.startsWith("<html>", Qt::CaseInsensitive) && doc.endsWith("</html>", Qt::CaseInsensitive))
    {
        mpParentMainWindow->mpOMCProxy->addClassAnnotation(mClassName,"annotate=Documentation(info = \""+doc+"\")");
        show(mClassName);
    }
    else
    {
        QString message = QString(GUIMessages::getMessage(GUIMessages::INCORRECT_HTML_TAGS));
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(message);
    }
}

DocumentationEditor::DocumentationEditor(DocumentationWidget *pParent)
    : QTextEdit(pParent)
{
    mpParentDocumentationWidget = pParent;
    setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    setTabStopWidth(Helper::tabWidth);
    setObjectName(tr("DocumentationEditor"));
    setAutoFormatting(QTextEdit::AutoNone);
    setAcceptRichText(false);
    this->setFontFamily(qApp->font().family());             // get system font
    this->setFontPointSize(10.0);
}

DocumentationViewer::DocumentationViewer(DocumentationWidget *pParent)
    : QWebView(pParent)
{
    mpParentDocumentationWidget = pParent;
    // set the base url for documentation.
    mpParentDocumentationWidget->mpParentMainWindow->mpOMCProxy->sendCommand("getNamedAnnotation(Modelica,version)");
    QString versionStr = StringHandler::unparseStrings(mpParentDocumentationWidget->mpParentMainWindow->mpOMCProxy->getResult()).at(0);
    // We need to replace the back slashes(\) with forward slash(/), since QWebView baseurl doesn't handle it.
    QString baseUrl = QString(Helper::OpenModelicaLibrary).replace("\\", "/").append("/Modelica ").append(versionStr).append("/Images/");
    setBaseUrl(baseUrl);
    // set page font settings
    settings()->setFontFamily(QWebSettings::StandardFont, "Verdana");
    settings()->setFontSize(QWebSettings::DefaultFontSize, 10);
    // set page links settings
    page()->setLinkDelegationPolicy(QWebPage::DelegateAllLinks);

    connect(this, SIGNAL(linkClicked(QUrl)), SLOT(processLinkClick(QUrl)));
    connect(this->page(), SIGNAL(linkHovered(QString,QString,QString)), SLOT(processLinkHover(QString,QString,QString)));
}

void DocumentationViewer::setBaseUrl(QString url)
{
    mBaseUrl.setUrl(url);
}

QUrl DocumentationViewer::getBaseUrl()
{
    return mBaseUrl;
}

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

    // if the user has clicked on some Modelica Links like Modelica://
    else if (url.toString().startsWith("Modelica"))
    {
        // remove Modelica:// from link
        QString className;
        className = url.toString().mid(10, url.toString().length() - 1);
        // send the new className to DocumentationWidget
        mpParentDocumentationWidget->show(className);
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

void DocumentationViewer::requestFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(const_cast<QObject*>(sender()));
    QUrl possibleRedirectedUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();

    //if the url contains https
    if (possibleRedirectedUrl.toString().contains("https"))
        QDesktopServices::openUrl(possibleRedirectedUrl);
    else
        this->load(reply->url());

    reply->deleteLater();
}

void DocumentationViewer::processLinkHover(QString link, QString title, QString textContent)
{
    Q_UNUSED(title);
    Q_UNUSED(textContent);

    if (link.isEmpty())
        mpParentDocumentationWidget->mpParentMainWindow->mpStatusBar->clearMessage();
    else
        mpParentDocumentationWidget->mpParentMainWindow->mpStatusBar->showMessage(link);
}

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
