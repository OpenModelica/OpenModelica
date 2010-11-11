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

#include "DocumentationWidget.h"

DocumentationWidget::DocumentationWidget(MainWindow *pParent)
    : QWidget(pParent)
{
    mpParentMainWindow = pParent;
    mpDocumentationViewer = new DocumentationViewer(this);
    mpHeadingLabel = new QLabel;
    mpHeadingLabel->setFont(QFont("", Helper::headingFontSize - 5));

    mpPixmapLabel = new QLabel;
    mpPixmapLabel->setObjectName(tr("componentPixmap"));
    mpPixmapLabel->setMaximumSize(QSize(86, 86));
    mpPixmapLabel->setFrameStyle(QFrame::Sunken | QFrame::StyledPanel);

    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    horizontalLayout->addWidget(mpPixmapLabel);
    horizontalLayout->addWidget(mpHeadingLabel);

    QVBoxLayout *verticalLayout = new QVBoxLayout;
    verticalLayout->addLayout(horizontalLayout);
    verticalLayout->addWidget(mpDocumentationViewer);

    setLayout(verticalLayout);
}

void DocumentationWidget::show(QString className)
{
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

    QString documentation = mpParentMainWindow->mpOMCProxy->getDocumentationAnnotation(className);
    documentation = StringHandler::removeFirstLastCurlBrackets(documentation);
    documentation = StringHandler::removeFirstLastQuotes(documentation);
    mpDocumentationViewer->setHtml(documentation);
    setVisible(true);
}

DocumentationViewer::DocumentationViewer(DocumentationWidget *pParent)
    : QWebView(pParent)
{
    settings()->setFontFamily(QWebSettings::StandardFont, "Verdana");
    settings()->setFontSize(QWebSettings::DefaultFontSize, 10);

    mpParent = pParent;
}
