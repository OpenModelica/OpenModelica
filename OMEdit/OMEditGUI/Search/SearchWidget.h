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
 * @author Arunkumar Palanisamy <arunkumar.palanisamy@liu.se>
 */
#include <QWidget>
#include <QLineEdit>
#include <QComboBox>
#include <QTreeWidget>
#include <QPushButton>
#include <QStackedWidget>
#include <QProgressBar>

class Label;
class SearchFileDetails;
class Search;
class SearchWidget : public QWidget
{
  Q_OBJECT
public:
  SearchWidget(QWidget *pParent = 0);
  ~SearchWidget();
  QComboBox *createEditableComboBox(const QString &text);
  QProgressBar *getProgressBar() {return mpProgressBar;}
  QComboBox *getSearchScopeComboBox() {return mpSearchScopeComboBox;}
  QComboBox *getSearchStringComboBox() {return mpSearchStringComboBox;}
  QComboBox *getSearchFilePatternComboBox() {return mpSearchFilePatternComboBox;}
  void updateComboBoxSearchStrings(QComboBox *ComboBox);
signals:
  void setCancelSearch();
public slots:
  void searchInFiles();
  void cancelSearch();
  void switchSearchPage();
  void findAndOpenTreeWidgetItems(QTreeWidgetItem *item, int column);
  void updateTreeWidgetItems(SearchFileDetails);
  void updateProgressBarRange(int);
  void updateProgressBarValue(int,int);
  void updateFoundFilesLabel(int);
private:
  Label * mpSearchForLabel;
  Label * mpProgressLabel;
  Label * mpProgressLabelFoundFiles;
  QPushButton * mpCancelButton;
  QPushButton * mpSearchButton;
  QComboBox * mpSearchScopeComboBox;
  QComboBox * mpSearchStringComboBox;
  QComboBox * mpSearchFilePatternComboBox;
  QTreeWidget* mpSearchTreeWidget;
  QStackedWidget * mpSearchStackedWidget;
  QProgressBar * mpProgressBar;
  Search *mpSearch;
};

class SearchFileDetails
{
public:
  SearchFileDetails () {}
  SearchFileDetails(QString filename, QMap<int,QString> Linenumbers);
  QString mfilename;
  QMap<int,QString> mSearchLines;
};

Q_DECLARE_METATYPE(SearchFileDetails)

class Search : public QObject
{
  Q_OBJECT
public:
  Search(QObject * parent = 0);
  void run();
  void getFiles(QString path, QStringList pattern, QStringList & filelist);
signals:
  void setTreeWidgetItems(SearchFileDetails);
  void setProgressBarRange(int);
  void setProgressBarValue(int,int);
  void setFoundFilesLabel(int);
public slots:
  void updateCancelSearch();
private:
  bool mStop;
};
