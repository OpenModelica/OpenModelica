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
#include <QToolBar>
#include <QGridLayout>
#include <QVBoxLayout>

/*!
 * \brief SearchWidget::SearchWidget
 * \param pParent
 */
SearchWidget::SearchWidget(QWidget *pParent)
  : QWidget(pParent)
{
  qRegisterMetaType<SearchFileDetails>();
  // Labels
  Label *pSearchScopeLabel = new Label(tr("Scope:"));
  Label *pSearchForStringLabel = new Label(tr("Search for:"));
  Label *pSearchFilePatternLabel = new Label(tr("File Pattern:"));
  // scope combobox
  mpSearchScopeComboBox = new QComboBox;
  mpSearchScopeComboBox->setModel(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel());
  // search string combobox
  mpSearchStringComboBox = new QComboBox;
  mpSearchStringComboBox->setEditable(true);
  mpSearchStringComboBox->setFixedWidth(400);
  connect(mpSearchStringComboBox->lineEdit(), SIGNAL(returnPressed()), SLOT(searchInFiles()));
  // search file combobox
  mpSearchFilePatternComboBox = new QComboBox;
  mpSearchFilePatternComboBox->setEditable(true);
  mpSearchFilePatternComboBox->addItem("*");
  connect(mpSearchFilePatternComboBox->lineEdit(), SIGNAL(returnPressed()), SLOT(searchInFiles()));
  // search button
  mpSearchButton = new QPushButton("Search");
  connect(mpSearchButton, SIGNAL(clicked()), SLOT(searchInFiles()));
  // stack widget
  mpSearchStackedWidget = new QStackedWidget;
  connect(mpSearchStackedWidget, SIGNAL(currentChanged(int)), SLOT(enableDisableExpandCollapseAction(int)));
  // tool bar
  QToolBar *pSearchBrowserToolBar = new QToolBar;
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  pSearchBrowserToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  // clear action
  mpClearAction = new QAction(QIcon(":/Resources/icons/clear.svg"), tr("Clear All"), this);
  mpClearAction->setStatusTip(tr("clears all the result"));
  mpClearAction->setDisabled(false);
  connect(mpClearAction, SIGNAL(triggered()), SLOT(clearAll()));
  // expand action
  mpExpandAction = new QAction(QIcon(":/Resources/icons/down.svg"), tr("Expand All"), this);
  mpExpandAction->setStatusTip(tr("expand"));
  mpExpandAction->setDisabled(true);
  connect(mpExpandAction, SIGNAL(triggered()), SLOT(expandAll()));
  // Collapse action
  mpCollapseAction = new QAction(QIcon(":/Resources/icons/up.svg"), tr("Collapse All"), this);
  mpCollapseAction->setStatusTip(tr("collapse"));
  mpCollapseAction->setDisabled(true);
  connect(mpCollapseAction, SIGNAL(triggered()), SLOT(collapseAll()));
  // search history widget
  QWidget *pSearchHistoryWidget = new QWidget;
  Label *pSearchHistoryLabel = new Label(tr("History:"));
  mpSearchHistoryComboBox = new QComboBox;
  mpSearchHistoryComboBox->setFixedWidth(300);
  mpSearchHistoryComboBox->addItem("New Search");
  connect(mpSearchHistoryComboBox,SIGNAL(activated(int)), SLOT(switchSearchPage(int)));

  QGridLayout *pSearchHistoryLayout = new QGridLayout;
  pSearchHistoryLayout->setContentsMargins(0, 0, 0, 0);
  pSearchHistoryLayout->addWidget(pSearchHistoryLabel,0,0);
  pSearchHistoryLayout->addWidget(mpSearchHistoryComboBox,0,1);
  pSearchHistoryWidget->setLayout(pSearchHistoryLayout);
  // add toolbar actions
  pSearchBrowserToolBar->addAction(mpClearAction);
  pSearchBrowserToolBar->addAction(mpExpandAction);
  pSearchBrowserToolBar->addAction(mpCollapseAction);
  pSearchBrowserToolBar->addSeparator();
  pSearchBrowserToolBar->addWidget(pSearchHistoryWidget);
  // first page
  QWidget *pSearchFirstPageWidget = new QWidget;
  QGridLayout *pSearchLayout = new QGridLayout;
  pSearchLayout->setContentsMargins(0, 0, 0, 0);
  pSearchLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pSearchLayout->addWidget(pSearchScopeLabel, 0, 0);
  pSearchLayout->addWidget(mpSearchScopeComboBox, 0, 1);
  pSearchLayout->addWidget(pSearchForStringLabel, 1, 0);
  pSearchLayout->addWidget(mpSearchStringComboBox, 1, 1);
  pSearchLayout->addWidget(pSearchFilePatternLabel, 2, 0);
  pSearchLayout->addWidget(mpSearchFilePatternComboBox, 2, 1);
  pSearchLayout->addWidget(mpSearchButton, 3, 1, Qt::AlignRight);
  pSearchFirstPageWidget->setLayout(pSearchLayout);
  mpSearchStackedWidget->addWidget(pSearchFirstPageWidget);
  // search stack widget layout
  QVBoxLayout *pSearchSetStackLayout = new QVBoxLayout;
  pSearchSetStackLayout->setContentsMargins(5, 5, 5, 5);
  pSearchSetStackLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pSearchSetStackLayout->addWidget(mpSearchStackedWidget);
  // put everything in a frame so we get a nice border
  QFrame *pMainFrame = new QFrame;
  pMainFrame->setContentsMargins(0, 0, 0, 0);
  pMainFrame->setFrameStyle(QFrame::StyledPanel);
  pMainFrame->setLayout(pSearchSetStackLayout);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pSearchBrowserToolBar);
  pMainLayout->addWidget(pMainFrame);
  setLayout(pMainLayout);
}

SearchWidget::~SearchWidget()
{
  // when the mainwindow closes check whether any ongoing search operation is running emit the stop signal and stop the thread
  emit setCancelSearch();
  deleteSearchResultWidgets();
}

/*!
 * \brief SearchWidget::updateComboBoxSearchStrings
 * \update the editable Combobox when user searches for searchingstring and filepatter for the session
 */
void SearchWidget::updateComboBoxSearchStrings(QComboBox *pComboBox)
{
  if (pComboBox->findText(pComboBox->currentText()) == -1) {
    pComboBox->addItem(pComboBox->currentText());
  }
}

/*!
 * \brief SearchWidget::deleteSearchResultWidgets
 * \deletes the result widget object from the stackwidget
 */
void SearchWidget::deleteSearchResultWidgets()
{
  for (int i = 0; i < mSearchResultWidgetobjects.size(); ++i) {
    delete mSearchResultWidgetobjects[i];
  }
  mSearchResultWidgetobjects.clear();
}

/*!
 * \brief SearchWidget::searchInFiles
 * Start the search functionality using QTConcurrent
 */
void SearchWidget::searchInFiles()
{
  /*do search only if searchstring is available and files opened in library tree browser */
  if(mpSearchStringComboBox->currentText().isEmpty() | (mpSearchScopeComboBox->count() == 1)) {
    return;
  }
  updateComboBoxSearchStrings(mpSearchStringComboBox);
  updateComboBoxSearchStrings(mpSearchFilePatternComboBox);
  /* create a new instance of searchresult widget and search widget for every new search */
  mpSearchResultWidget = new SearchResultWidget;
  mSearchResultWidgetobjects.append(mpSearchResultWidget);
  mpSearch = new Search(this);
  connect(mpSearch, SIGNAL(setTreeWidgetItems(SearchFileDetails)), mpSearchResultWidget, SLOT(updateTreeWidgetItems(SearchFileDetails)));
  connect(mpSearch, SIGNAL(setProgressBarRange(int)), mpSearchResultWidget, SLOT(updateProgressBarRange(int)));
  connect(mpSearch, SIGNAL(setProgressBarValue(int,int)), mpSearchResultWidget, SLOT(updateProgressBarValue(int,int)));
  connect(mpSearch, SIGNAL(setFoundFilesLabel(int)), mpSearchResultWidget, SLOT(updateFoundFilesLabel(int)));
  connect(mpSearch, SIGNAL(setProgressBarCancelValue(int,int)), mpSearchResultWidget, SLOT(updateProgressBarCancelValue(int,int)));
  connect(mpSearch, SIGNAL(setProgressBarFinishedValue(int)), mpSearchResultWidget, SLOT(updateProgressBarFinishedValue(int)));
  connect(mpSearchResultWidget, SIGNAL(setCancelSearchResult()), mpSearch, SLOT(updateCancelSearch()));
  /*emit the signals to stop any ongoing search operation when mainwindow is closed*/
  connect(this, SIGNAL(setCancelSearch()), mpSearch, SLOT(updateCancelSearch()));

  mpSearchStackedWidget->addWidget(mpSearchResultWidget);
  mpSearchStackedWidget->setCurrentWidget(mpSearchResultWidget);
  QString searchHistoryItem = QString("%1-%2: %3").arg(tr("Project")).arg(mpSearchScopeComboBox->currentText()).arg(mpSearchStringComboBox->currentText());
  mpSearchHistoryComboBox->addItem(searchHistoryItem);
  mpSearchHistoryComboBox->setCurrentIndex(mpSearchHistoryComboBox->findText(searchHistoryItem));
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
 */
void SearchWidget::switchSearchPage(int index)
{
  mpSearchStackedWidget->setCurrentIndex(index);
}

/*!
 * \brief SearchWidget::expandAll
 * SLOT to expand all the items in tree widget from the SearchResultWidget
 */
void SearchWidget::expandAll()
{
  if(mpSearchStackedWidget->currentIndex()!=0){
    mSearchResultWidgetobjects[mpSearchStackedWidget->currentIndex()-1]->getSearchTreeWidget()->expandAll();
  }
}

/*!
 * \brief SearchWidget::expandAll
 * SLOT to collapse all the items in tree widget from the SearchResultWidget
 */
void SearchWidget::collapseAll()
{
  if(mpSearchStackedWidget->currentIndex()!=0){
    mSearchResultWidgetobjects[mpSearchStackedWidget->currentIndex()-1]->getSearchTreeWidget()->collapseAll();
  }
}

/*!
 * \brief SearchWidget::clearAll
 * SLOT to clear all the search result pages from the stackwidget
 */
void SearchWidget::clearAll()
{
  deleteSearchResultWidgets();
  for (int j = mpSearchHistoryComboBox->count()-1; j > 0; --j) {
    mpSearchHistoryComboBox->removeItem(j);
  }
}

/*!
 * \brief SearchWidget::clearAll
 * SLOT to enable and disable expand and collapse action for search results
 */
void SearchWidget::enableDisableExpandCollapseAction(int index)
{
  if(index > 0){
    mpExpandAction->setDisabled(false);
    mpCollapseAction->setDisabled(false);
  }
  else{
    mpExpandAction->setDisabled(true);
    mpCollapseAction->setDisabled(true);
  }
}

/*!
 * \brief SearchResultWidget::SearchResultWidget
 * \class which handles the results for the search operation
 * \create a instance of this class and add to stack widget for each search operation
 * \param pParent
 */

SearchResultWidget::SearchResultWidget(QWidget *pParent)
  : QWidget(pParent)
{
  mpProgressLabel = new Label;
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpProgressLabelFoundFiles = new Label;
  mpProgressLabelFoundFiles->setTextFormat(Qt::RichText);
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelSearch()));

  // Progress Bar
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);

  // Tree Widget
  mpSearchTreeWidget = new QTreeWidget();
  mpSearchTreeWidget->setColumnCount(1);
  mpSearchTreeWidget->header()->close();
  connect(mpSearchTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*, int)),this, SLOT(findAndOpenTreeWidgetItems(QTreeWidgetItem*,int)));

  QWidget *pSearchResultPageWidget = new QWidget;
  QGridLayout *pSearchResultsLayout = new QGridLayout;
  pSearchResultsLayout->setContentsMargins(0, 0, 0, 0);
  pSearchResultsLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pSearchResultsLayout->addWidget(mpProgressLabel, 0, 0, 1, 2);
  pSearchResultsLayout->addWidget(mpProgressLabelFoundFiles, 0, 2);
  pSearchResultsLayout->addWidget(mpProgressBar, 1, 0);
  pSearchResultsLayout->addWidget(mpCancelButton, 1, 2);
  pSearchResultsLayout->addWidget(mpSearchTreeWidget, 2, 0, 1, 3);
  pSearchResultPageWidget->setLayout(pSearchResultsLayout);

  QVBoxLayout *pSearchSetStackLayout = new QVBoxLayout;
  pSearchSetStackLayout->setContentsMargins(5, 5, 5, 5);
  pSearchSetStackLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pSearchSetStackLayout->addWidget(pSearchResultPageWidget);
  setLayout(pSearchSetStackLayout);
}

/*!
 * \brief SearchResultWidget::findAndOpenTreeWidgetItems
 * SLOT function to open the search results from the
 * tree items in the editor and to the corresponding line number
 */
void SearchResultWidget::findAndOpenTreeWidgetItems(QTreeWidgetItem *item, int column)
{
  QVariant value = item->data(column, Qt::UserRole);
  if (!value.isNull()) {
    SearchFileDetails filedetails = qvariant_cast<SearchFileDetails>(value);
    if (!filedetails.mSearchLines.isEmpty()) {
      QString line = QString::number(filedetails.mSearchLines.begin().key());
      MainWindow::instance()->findFileAndGoToLine(filedetails.mFileName, line);
    }
  }
}

/*!
 * \brief SearchWidget::updateTreeWidgetItems
 * SLOT function to fill the treewidgetitems
 * from the found search results which updates
 * each tree item with filename and subchild with line numbers and
 * found lines
 */
void SearchResultWidget::updateTreeWidgetItems(SearchFileDetails fileDetails)
{
  QTreeWidgetItem *pTreeWidgetItem = new QTreeWidgetItem();
  pTreeWidgetItem->setText(0, fileDetails.mFileName);
  mpSearchTreeWidget->insertTopLevelItem(0, pTreeWidgetItem);
  mpSearchTreeWidget->resizeColumnToContents(0);
  QMap<int, QString> map = fileDetails.mSearchLines;
  QMap<int, QString>::iterator m;
  for (m = map.begin(); m != map.end(); ++m) {
    // addTreeChild(mtreeWidgetItem,filedata[var].file,i.key(),i.value());
    QTreeWidgetItem *pTreeItemchild = new QTreeWidgetItem();
    pTreeItemchild->setText(0, QString("%1 %2").arg(QString::number(m.key())).arg(m.value()));
    QMap<int, QString> mapData;
    mapData[m.key()] = m.value();
    pTreeItemchild->setData(0, Qt::UserRole, QVariant::fromValue(SearchFileDetails(fileDetails.mFileName, mapData)));
    pTreeWidgetItem->addChild(pTreeItemchild);
  }
}

/*!
 * \brief SearchResultWidget::updateProgressBarRange
 * SLOT to update the progressbarrange in the GUI
 */
void SearchResultWidget::updateProgressBarRange(int size)
{
  mpProgressBar->setRange(0,size);
}

/*!
 * \brief SearchResultWidget::updateProgressBarValue
 * SLOT to update the progressbarvalue in the GUI
 * in incremental order according to file search
 */
void SearchResultWidget::updateProgressBarValue(int value, int size)
{
  mpProgressBar->setValue(value+1);
  mpProgressLabel->setText(tr("Searching <b>%1</b> of <b>%2</b> files. Please wait for a while.").arg(QString::number(value+1)).arg(QString::number(size)));
}

/*!
 * \brief SearchResultWidget::updateProgressBarCancelValue
 * SLOT to update the progressbarcancelvalue in the GUI
 * when the user cancels the search and update the results
 */
void SearchResultWidget::updateProgressBarCancelValue(int value, int size)
{
  mpProgressBar->setValue(size);
  mpProgressLabel->setText(tr("Searched <b>%1</b> of <b>%2</b> files. Search Cancelled.").arg(QString::number(value+1)).arg(QString::number(size)));
  mpCancelButton->setEnabled(false);
}

/*!
 * \brief SearchResultWidget::updateProgressBarFinishedValue
 * SLOT to update the progressbarFinishedvalue in the GUI
 * when the search is finished and update the results
 */
void SearchResultWidget::updateProgressBarFinishedValue(int value)
{
  mpProgressBar->setValue(value);
  mpProgressLabel->setText(tr("Searched <b>%1</b> of <b>%2</b> files. Search Completed.").arg(QString::number(value)).arg(QString::number(value)));
  mpCancelButton->setEnabled(false);
}

/*!
 * \brief SearchResultWidget::updateFoundFilesLabel
 * SLOT to update the number of foundfiles from
 * the search results
 */
void SearchResultWidget::updateFoundFilesLabel(int value)
{
  mpProgressLabelFoundFiles->setText(tr("<b>%1</b> FOUND").arg(value));
}

/*!
 * \brief SearchResultWidget::cancelSearch
 * SLOT to cance the current ongoing search operation
 */
void SearchResultWidget::cancelSearch()
{
  emit setCancelSearchResult();
}

/*!
 * \brief SearchFileDetails::SearchFileDetails
 * class to store the results of Search. with
 * filename and Qmap as parameters
 */
SearchFileDetails::SearchFileDetails(QString fileName, QMap<int,QString> Linenumbers)
{
  mFileName = fileName;
  mSearchLines = Linenumbers;
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
  SearchWidget *pSearchWidget = MainWindow::instance()->getSearchWidget();
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  QStringList filelist;
  QString searchString = pSearchWidget->getSearchStringComboBox()->currentText();
  QStringList pattern= pSearchWidget->getSearchFilePatternComboBox()->currentText().split(',');
  if (!searchString.isEmpty()) {
    if (pSearchWidget->getSearchScopeComboBox()->currentIndex() != 0) {
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem()->child(pSearchWidget->getSearchScopeComboBox()->currentIndex());
      getFiles(pLibraryTreeItem->getFileName(), pattern, filelist);
    } else {
      // start the index from 1 as 0 is dummy root item
      for (int i = 1; i < pLibraryTreeModel->getRootLibraryTreeItem()->childrenSize(); ++i) {
        LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem()->child(i);
        getFiles(pLibraryTreeItem->getFileName(), pattern, filelist);
      }
    }
    emit setProgressBarRange(filelist.size());
    int count=1;
    for (int i = 0; i < filelist.size(); ++i) {
      Sleep::msleep(10);
      // check for cancel operation
      if (mStop) {
        emit setProgressBarCancelValue(i,filelist.size());
        emit setFoundFilesLabel(count-1);
        return;
      }
      emit setProgressBarValue(i,filelist.size());
      QString fileName = filelist.at(i);
      QFile file(fileName);
      if (file.open(QIODevice::ReadOnly)) {
        QString line;
        QStringList foundLines;
        QMap<int,QString> lineCounts;
        QTextStream in(&file);
        int linenumber = 0;
        bool value=false;
        while (!in.atEnd()) {
          line = in.readLine();
          linenumber+=1;
          if (line.contains(searchString, Qt::CaseInsensitive)) {
            foundLines << line;
            lineCounts[linenumber].append(line);
            //break;
            value=true;
          }
        }
        if (value==true) {
          emit setTreeWidgetItems(SearchFileDetails(fileName, lineCounts));
          emit setFoundFilesLabel(count);
          count+=1;
        }
      }
    }
    emit setProgressBarFinishedValue(filelist.size());
    if (count==1) {
      emit setFoundFilesLabel(0);
    }
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


