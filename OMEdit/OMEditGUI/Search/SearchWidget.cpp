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
 * @author Arunkumar Palansiamy <arunkumar.palanisamy@liu.se>
 */

#include "SearchWidget.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Util/Helper.h"
#include "Options/OptionsDialog.h"

#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtConcurrent/QtConcurrent>
#endif
#include <QMenu>
#include <QHeaderView>

/*!
 * \brief SearchWidget::SearchWidget
 * \param pParent
 */
SearchWidget::SearchWidget(QWidget *pParent)
  : QWidget(pParent)
{
  qRegisterMetaType<SearchFileDetails>();
  mpSearch = new Search(this);
  connect(mpSearch,SIGNAL(setTreeWidgetItems(SearchFileDetails)),this,SLOT(updateTreeWidgetItems(SearchFileDetails)));
  connect(mpSearch,SIGNAL(setProgressBarRange(int)),this,SLOT(updateProgressBarRange(int)));
  connect(mpSearch,SIGNAL(setProgressBarValue(int,int)),this,SLOT(updateProgressBarValue(int,int)));
  connect(mpSearch,SIGNAL(setFoundFilesLabel(int)),this,SLOT(updateFoundFilesLabel(int)));
  // Labels
  Label * pSearchScopeLabel = new Label(tr("Scope:"));
  Label * pSearchForStringLabel = new Label(tr("Search for:"));
  Label * pSearchFilePatternLabel = new Label(tr("File Pattern:"));

  // combo box
  mpSearchScopeComboBox = new QComboBox;
  mpSearchScopeComboBox->setModel(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel());

  mpSearchStringComboBox= createEditableComboBox("");
  mpSearchFilePatternComboBox = createEditableComboBox(tr("*"));
  mpSearchButton = new QPushButton("Search");
  mpSearchButton->setFixedWidth(50);

  // Tree Widget
  mpSearchTreeWidget = new QTreeWidget();
  mpSearchTreeWidget->setColumnCount(1);
  mpSearchTreeWidget->header()->close();
  connect(mpSearchTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*, int)),this, SLOT(findAndOpenTreeWidgetItems(QTreeWidgetItem*,int)));

  // Progress Bar
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);

  QWidget *pSearchFirstPageWidget = new QWidget;
  QWidget *pSearchSecondPageWidget = new QWidget;
  mpSearchStackedWidget = new QStackedWidget;

  // first page
  QGridLayout * pSearchLayout = new QGridLayout;
  pSearchLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pSearchLayout->addWidget(pSearchScopeLabel,0,0);
  pSearchLayout->addWidget(mpSearchScopeComboBox,0,1);
  pSearchLayout->addWidget(pSearchForStringLabel,1,0);
  pSearchLayout->addWidget(mpSearchStringComboBox,1,1);
  pSearchLayout->addWidget(pSearchFilePatternLabel,2,0);
  pSearchLayout->addWidget(mpSearchFilePatternComboBox,2,1);
  pSearchLayout->addWidget(mpSearchButton,3,1);
  pSearchFirstPageWidget->setLayout(pSearchLayout);
  mpSearchStackedWidget->addWidget(pSearchFirstPageWidget);

  // second page
  QGridLayout * pSearchResultsLayout = new QGridLayout;
  pSearchResultsLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  mpProgressLabel = new Label;
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpProgressLabelFoundFiles = new Label;
  mpProgressLabelFoundFiles->setTextFormat(Qt::RichText);
  mpCancelButton = new QPushButton("Cancel");
  QPushButton * pSearchBack = new QPushButton("Back");
  pSearchResultsLayout->addWidget(mpProgressLabel,0,0,1,2);
  pSearchResultsLayout->addWidget(mpProgressLabelFoundFiles,0,2);
  pSearchResultsLayout->addWidget(pSearchBack,1,0);
  pSearchResultsLayout->addWidget(mpProgressBar,1,1);
  pSearchResultsLayout->addWidget(mpCancelButton,1,2);
  pSearchResultsLayout->addWidget(mpSearchTreeWidget,2,0,1,3);
  pSearchSecondPageWidget->setLayout(pSearchResultsLayout);
  mpSearchStackedWidget->addWidget(pSearchSecondPageWidget);

  connect(mpSearchButton, SIGNAL(clicked()), SLOT(searchInFiles()));
  connect(pSearchBack, SIGNAL(clicked()), SLOT(switchSearchPage()));
  connect(mpCancelButton,SIGNAL(clicked()), SLOT(cancelSearch()));
  connect(this,SIGNAL(setCancelSearch()),mpSearch,SLOT(updateCancelSearch()));

  QVBoxLayout *pSearchSetStackLayout = new QVBoxLayout;
  pSearchSetStackLayout->addWidget(mpSearchStackedWidget);
  setLayout(pSearchSetStackLayout);

}

SearchWidget::~SearchWidget()
{
  // when the mainwindow closes check whether any ongoing search operation is running emit the stop signal and stop the thread
  emit setCancelSearch();
}

/*!
 * \brief SearchWidget::createEditableComboBox
 * \creates a editable Combobox
 */
QComboBox *SearchWidget::createEditableComboBox(const QString &text)
{
  QComboBox *mEditableComboBox = new QComboBox;
  mEditableComboBox->setEditable(true);
  mEditableComboBox->addItem(text);
  mEditableComboBox->setFixedWidth(400);
  mEditableComboBox->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
  return mEditableComboBox;
}

/*!
 * \brief SearchWidget::updateComboBoxSearchStrings
 * \update the editable Combobox when user searches for searchingstring and filepatter for the session
 */
void SearchWidget::updateComboBoxSearchStrings(QComboBox *ComboBox)
{
  if (ComboBox->findText(ComboBox->currentText()) == -1)
    ComboBox->addItem(ComboBox->currentText());
}

/*!
 * \brief SearchWidget::searchInFiles
 * Start the search functionality using QTConcurrent
 */
void SearchWidget::searchInFiles()
{
  /*do search only if searchstring is available and files opened in library tree browser */
  if(mpSearchStringComboBox->currentText().isEmpty() | (mpSearchScopeComboBox->count()==1))
  {
    return;
  }
  mpSearchStackedWidget->setCurrentIndex(1);
  updateComboBoxSearchStrings(mpSearchStringComboBox);
  updateComboBoxSearchStrings(mpSearchFilePatternComboBox);
  /* start the search in seperate thread using QtConcurrent */
  QtConcurrent::run(mpSearch, &Search::run);
}

/*!
 * \brief SearchWidget::cancelSearch
 * SLOT function to cancel the current search operation
 */
void SearchWidget::cancelSearch()
{
  emit setCancelSearch();
}

/*!
 * \brief SearchWidget::cancelSearch
 * SLOT to switch back to the main search page
 * Clear all the results when going back
 */
void SearchWidget::switchSearchPage()
{
  /* emit the signal to make sure the thread is stopped if search is not completed fully
   and user press the back button */
  emit setCancelSearch();
  /* switch the search page and clear all the items */
  mpSearchStackedWidget->setCurrentIndex(0);
  mpProgressBar->setValue(0);
  mpSearchTreeWidget->clear();
  mpProgressLabel->clear();
  mpProgressLabelFoundFiles->clear();
}

/*!
 * \brief SearchWidget::findAndOpenTreeWidgetItems
 * SLOT function to open the search results from the
 * tree items in the editor,and to the corresponding line number
 */
void SearchWidget::findAndOpenTreeWidgetItems(QTreeWidgetItem *item, int column)
{
  QVariant value = item->data(column,Qt::UserRole);
  if (!value.isNull())
  {
    SearchFileDetails filedetails = qvariant_cast<SearchFileDetails>(value);
    QString line = QString::number(filedetails.mSearchLines.firstKey());
    MainWindow::instance()->findFileAndGoToLine(filedetails.mfilename,line);
  }
}

/*!
 * \brief SearchWidget::updateTreeWidgetItems
 * SLOT function to fill the treewidgetitems
 * from the found search results which updates
 * each tree item with filename and subchild with line numbers and
 * found lines
 */
void SearchWidget::updateTreeWidgetItems(SearchFileDetails filedetails)
{
  QTreeWidgetItem *mtreeWidgetItem = new QTreeWidgetItem();
  mtreeWidgetItem->setText(0,filedetails.mfilename);
  mpSearchTreeWidget->insertTopLevelItem(0,mtreeWidgetItem);
  mpSearchTreeWidget->resizeColumnToContents(0);

  QMap<int, QString> map =filedetails.mSearchLines;
  QMap<int, QString>::iterator m;
  for (m = map.begin(); m != map.end(); ++m)
  {
    // addTreeChild(mtreeWidgetItem,filedata[var].file,i.key(),i.value());
    QTreeWidgetItem *mtreeItemchild = new QTreeWidgetItem();
    mtreeItemchild->setText(0,tr("%1 %2").arg(QString::number(m.key())).arg(m.value()));
    QMap<int, QString> mapdata;
    mapdata[m.key()]=m.value();
    mtreeItemchild->setData(0,Qt::UserRole,QVariant::fromValue(SearchFileDetails(filedetails.mfilename,mapdata)));
    mtreeWidgetItem->addChild(mtreeItemchild);
  }
}

/*!
 * \brief SearchWidget::updateProgressBarRange
 * SLOT to update the progressbarrange in the GUI
 */
void SearchWidget::updateProgressBarRange(int size)
{
  mpProgressBar->setRange(0,size);
}

/*!
 * \brief SearchWidget::updateProgressBarValue
 * SLOT to update the progressbarvalue in the GUI
 * in incremental order according to file search
 */
void SearchWidget::updateProgressBarValue(int value, int size)
{
  mpProgressBar->setValue(value+1);
  mpProgressLabel->setText(tr("Searching <b>%1</b> of <b>%2</b> files. Please wait for a while").arg(QString::number(value+1)).arg(QString::number(size)));
}

/*!
 * \brief SearchWidget::updateFoundFilesLabel
 * SLOT to update the number of foundfiles from
 * the search results
 */
void SearchWidget::updateFoundFilesLabel(int value)
{
  mpProgressLabelFoundFiles->setText(tr("<b>%1</b> FOUND").arg(value));
}

/*!
 * \brief SearchFileDetails::SearchFileDetails
 * class to store the results of Search. with
 * filename and Qmap as parameters
 */
SearchFileDetails::SearchFileDetails(QString filename, QMap<int,QString> Linenumbers)
{
  mfilename=filename;
  mSearchLines=Linenumbers;
}

/*!
 * \brief Search::Search
 * class which runs the Search operation
 * in a seperate thread
 */

Search::Search(QObject *parent):
  QObject(parent)
{
  mStop = false;
}

/*!
 * \brief Search::run
 * main function which runs the Search operation
 * in a seperate thread using the QTConcurrent
 */
void Search::run()
{
  mStop = false;
  SearchWidget *mSearchWidget=MainWindow::instance()->getSearchWidget();
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  QStringList filelist;
  QString searchString = mSearchWidget->getSearchStringComboBox()->currentText();
  QStringList pattern= mSearchWidget->getSearchFilePatternComboBox()->currentText().split(',');
  if(!searchString.isEmpty())
  {
    if(mSearchWidget->getSearchScopeComboBox()->currentIndex()!=0)
    {
      LibraryTreeItem *pLibraryTreeItem=pLibraryTreeModel->getRootLibraryTreeItem()->child(mSearchWidget->getSearchScopeComboBox()->currentIndex());
      getFiles(pLibraryTreeItem->getFileName(),pattern, filelist);
    }
    else
    {
      // start the index from 1 as 0 is dummy root item
      for (int i = 1; i < pLibraryTreeModel->getRootLibraryTreeItem()->childrenSize(); ++i)
      {
        LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem()->child(i);
        getFiles(pLibraryTreeItem->getFileName(),pattern, filelist);
      }
    }
    emit setProgressBarRange(filelist.size());
    int count=1;
    for (int i = 0; i < filelist.size(); ++i)
    {
      // check for cancel operation
      if(mStop)
      {
        return;
      }
      emit setProgressBarValue(i,filelist.size());
      QString fileName = filelist.at(i);
      QFile file(fileName);
      if (file.open(QIODevice::ReadOnly)) {
        QString line;
        QStringList foundLines;
        QMap<int,QString> linecounts;
        QTextStream in(&file);
        int linenumber = 0;
        bool value=false;
        while (!in.atEnd()) {
          line = in.readLine();
          linenumber+=1;
          if (line.contains(searchString, Qt::CaseInsensitive))
          {
            foundLines << line;
            linecounts[linenumber].append(line);
            //break;
            value=true;
          }
        }
        if(value==true)
        {
          emit setTreeWidgetItems(SearchFileDetails(fileName,linecounts));
          emit setFoundFilesLabel(count);
          count+=1;
        }
      }
    }
    if (count==1)
      emit setFoundFilesLabel(0);
  }
}

/*!
 * \brief Search::getFiles
 * function which runs the Search collects the
 * list of files to be searched from the inputs
 * given from the user in the GUI
 */
void Search::getFiles(QString path, QStringList pattern, QStringList &filelist)
{
  QFileInfo fileinfo(path);
  if(fileinfo.isFile())
  {
    filelist.append((path));
  }
  if(fileinfo.isDir())
  {
    QDirIterator it(path,QStringList() << pattern,QDir::Files,QDirIterator::Subdirectories);
    while (it.hasNext()) {
      QFile f(it.next());
      filelist.append(f.fileName());
    }
  }
}

/*!
 * \brief Search::updateCancelSearch
 * SLOT which stops the current search operation
 */
void Search::updateCancelSearch()
{
  mStop = true;
}



