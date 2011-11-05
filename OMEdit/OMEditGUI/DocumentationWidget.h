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

#ifndef DOCUMENTATIONWIDGET_H
#define DOCUMENTATIONWIDGET_H

#include <QtWebKit>

#include "mainwindow.h"


class DocumentationViewer;
class DocumentationEditor;

class DocumentationWidget : public QWidget
{
    Q_OBJECT
private:
    bool mIsCustomModel;
public slots:
    void editDocumentation();
    void saveChanges();
public:
    DocumentationWidget(MainWindow *pParent);
    ~DocumentationWidget();
    void show(QString className);
    void showDocumentationEditView(QString className);
    void setIsCustomModel(bool isCustomModel);
    bool isCustomModel();

    MainWindow *mpParentMainWindow;
    DocumentationViewer *mpDocumentationViewer;
    DocumentationEditor *mpDocumentationEditor;
    QPlainTextEdit *mpHeadingLabel;
    QLabel *mpPixmapLabel;
    QPushButton *mpEditButton;
    QPushButton *mpSaveButton;
    QDialogButtonBox *mpButtonBox;
    QString mClassName;
protected:
    virtual void paintEvent(QPaintEvent *event);
};
class ModelicaTextSettings;

//class for editing the documentation
class DocumentationEditor : public QTextEdit
{
    Q_OBJECT
public:
    DocumentationEditor(DocumentationWidget *pParent);
    QString getModelName();
    void findText(const QString &text, bool forward);
    bool validateText();
    DocumentationWidget *mpParentDocumentationWidget;
    ModelicaTextSettings *mpModelicaTextSettings;

signals:
    bool focusOut();
};


class DocumentationViewer : public QWebView
{
    Q_OBJECT
private:
    QUrl mBaseUrl;
public:
    DocumentationViewer(DocumentationWidget *pParent);
    void setBaseUrl(QString url);
    QUrl getBaseUrl();

    DocumentationWidget *mpParentDocumentationWidget;
public slots:
    void processLinkClick(QUrl url);
    void requestFinished();
    void processLinkHover(QString link, QString title, QString textContent);
protected:
    virtual void mousePressEvent(QMouseEvent *event);
};

#endif // DOCUMENTATIONWIDGET_H
