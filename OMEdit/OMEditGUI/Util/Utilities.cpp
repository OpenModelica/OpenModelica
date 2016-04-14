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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 *
 */

#include "MainWindow.h"
#include "Utilities.h"

MdiArea::MdiArea(QWidget *pParent)
  : QMdiArea(pParent)
{
  mpMainWindow = qobject_cast<MainWindow*>(pParent);
  setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setActivationOrder(QMdiArea::ActivationHistoryOrder);
  setDocumentMode(true);
#if QT_VERSION >= 0x040800
  setTabsClosable(true);
#endif
}

MainWindow* MdiArea::getMainWindow()
{
  return mpMainWindow;
}

TreeSearchFilters::TreeSearchFilters(QWidget *pParent)
  : QWidget(pParent)
{
  // create the search text box
  mpSearchTextBox = new QLineEdit;
  // show hide button
  mpShowHideButton = new QToolButton;
  QString text = tr("Show/hide filters");
  mpShowHideButton->setText(text);
  mpShowHideButton->setIcon(QIcon(":/Resources/icons/down.svg"));
  mpShowHideButton->setToolTip(text);
  mpShowHideButton->setAutoRaise(true);
  mpShowHideButton->setCheckable(true);
  connect(mpShowHideButton, SIGNAL(toggled(bool)), SLOT(showHideFilters(bool)));
  // filters widget
  mpFiltersWidget = new QWidget;
  // create the case sensitivity checkbox
  mpCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  // create the search syntax combobox
  mpSyntaxComboBox = new QComboBox;
  mpSyntaxComboBox->addItem(tr("Regular Expression"), QRegExp::RegExp);
  mpSyntaxComboBox->setItemData(0, tr("A rich Perl-like pattern matching syntax."), Qt::ToolTipRole);
  mpSyntaxComboBox->addItem(tr("Wildcard"), QRegExp::Wildcard);
  mpSyntaxComboBox->setItemData(1, tr("A simple pattern matching syntax similar to that used by shells (command interpreters) for \"file globbing\"."), Qt::ToolTipRole);
  mpSyntaxComboBox->addItem(tr("Fixed String"), QRegExp::FixedString);
  mpSyntaxComboBox->setItemData(2, tr("Fixed string matching."), Qt::ToolTipRole);
  // expand all button
  mpExpandAllButton = new QPushButton(Helper::expandAll);
  mpExpandAllButton->setAutoDefault(false);
  // collapse all button
  mpCollapseAllButton = new QPushButton(Helper::collapseAll);
  mpCollapseAllButton->setAutoDefault(false);
  // create the layout
  QGridLayout *pFiltersWidgetLayout = new QGridLayout;
  pFiltersWidgetLayout->setContentsMargins(0, 0, 0, 0);
  pFiltersWidgetLayout->setAlignment(Qt::AlignTop);
  pFiltersWidgetLayout->addWidget(mpCaseSensitiveCheckBox, 0, 0);
  pFiltersWidgetLayout->addWidget(mpSyntaxComboBox, 0, 1);
  pFiltersWidgetLayout->addWidget(mpExpandAllButton, 1, 0);
  pFiltersWidgetLayout->addWidget(mpCollapseAllButton, 1, 1);
  mpFiltersWidget->setLayout(pFiltersWidgetLayout);
  mpFiltersWidget->hide();
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpSearchTextBox, 0, 0);
  pMainLayout->addWidget(mpShowHideButton, 0, 1);
  pMainLayout->addWidget(mpFiltersWidget, 1, 0, 1, 2);
  setLayout(pMainLayout);
}

void TreeSearchFilters::showHideFilters(bool On)
{
  if (On) {
    mpFiltersWidget->show();
  } else {
    mpFiltersWidget->hide();
  }
}

/*!
 * \class FileDataNotifier
 * \brief Looks for new data on file. When data is available emits bytesAvailable SIGNAL.
 * \brief FileDataNotifier::FileDataNotifier
 * \param fileName
 */
FileDataNotifier::FileDataNotifier(const QString fileName)
{
  mFile.setFileName(fileName);
  mStop = false;
  mBytesAvailable = 0;
}

/*!
 * \brief FileDataNotifier::exit
 * Reimplementation of QThread::exit()
 * Sets mStop to true.
 * \param retcode
 */
void FileDataNotifier::exit(int retcode)
{
  mStop = true;
  QThread::exit(retcode);
}

/*!
 * \brief FileDataNotifier::run
 * Reimplentation of QThread::run().
 * Looks for when is new data available for reading on file.
 * Emits the bytesAvailable SIGNAL.
 */
void FileDataNotifier::run()
{
  if (mFile.open(QIODevice::ReadOnly)) {
    while(!mStop) {
      // if file doesn't exist then break.
      if (!mFile.exists()) {
        break;
      }
      // if file has bytes available to read.
      if (mFile.bytesAvailable() > mBytesAvailable) {
        mBytesAvailable = mFile.bytesAvailable();
        emit bytesAvailable(mFile.bytesAvailable());
      }
      Sleep::sleep(1);
    }
  }
}

/*!
 * \brief FileDataNotifier::start
 * Reimplementation of QThread::start()
 * Sets mStop to false.
 * \param priority
 */
void FileDataNotifier::start(Priority priority)
{
  mStop = false;
  QThread::start(priority);
}

Label::Label(QWidget *parent, Qt::WindowFlags flags)
  : QLabel(parent, flags), mElideMode(Qt::ElideNone), mText("")
{
  setTextInteractionFlags(Qt::TextSelectableByMouse);
}

Label::Label(const QString &text, QWidget *parent, Qt::WindowFlags flags)
  : QLabel(text, parent, flags), mElideMode(Qt::ElideNone), mText(text)
{
  setTextInteractionFlags(Qt::TextSelectableByMouse);
  setToolTip(text);
}

QSize Label::minimumSizeHint() const
{
  if (pixmap() != NULL || mElideMode == Qt::ElideNone)
    return QLabel::minimumSizeHint();
  const QFontMetrics &fm = fontMetrics();
  QSize size(fm.width("..."), fm.height()+5);
  return size;
}

QSize Label::sizeHint() const
{
  if (pixmap() != NULL || mElideMode == Qt::ElideNone)
    return QLabel::sizeHint();
  const QFontMetrics& fm = fontMetrics();
  QSize size(fm.width(mText), fm.height()+5);
  return size;
}

void Label::setText(const QString &text)
{
  mText = text;
  setToolTip(text);
  QLabel::setText(text);
}

void Label::resizeEvent(QResizeEvent *event)
{
  if (mElideMode != Qt::ElideNone)
  {
    QFontMetrics fm(fontMetrics());
    QString str = fm.elidedText(mText, mElideMode, event->size().width());
    QLabel::setText(str);
  }
  QLabel::resizeEvent(event);
}

FixedCheckBox::FixedCheckBox(QWidget *parent)
 : QCheckBox(parent)
{
  setCheckable(false);
  mDefaultValue = false;
  mTickState = false;
}

void FixedCheckBox::setTickState(bool defaultValue, bool tickState)
{
  mDefaultValue = defaultValue;
  mTickState = tickState;
}

QString FixedCheckBox::tickStateString()
{
  if (mDefaultValue) {
    return "";
  } else if (mTickState) {
    return "true";
  } else {
    return "false";
  }
}

/*!
  Reimplementation of QCheckBox::paintEvent.\n
  Draws a custom checkbox suitable for fixed modifier.
  */
void FixedCheckBox::paintEvent(QPaintEvent *event)
{
  Q_UNUSED(event);
  QStylePainter p(this);
  QStyleOptionButton opt;
  opt.initFrom(this);
  if (mDefaultValue) {
    p.setBrush(QColor(225, 225, 225));
  } else {
    p.setBrush(Qt::white);
  }
  p.drawRect(opt.rect.adjusted(0, 0, -1, -1));
  // if is checked then draw a tick
  if (mTickState) {
    p.setRenderHint(QPainter::Antialiasing);
    QPen pen = p.pen();
    pen.setWidthF(1.5);
    p.setPen(pen);
    QVector<QPoint> lines;
    lines << QPoint(opt.rect.left() + 3, opt.rect.center().y());
    lines << QPoint(opt.rect.center().x() - 1, opt.rect.bottom() - 3);
    lines << QPoint(opt.rect.center().x() - 1, opt.rect.bottom() - 3);
    lines << QPoint(opt.rect.width() - 3, opt.rect.top() + 3);
    p.drawLines(lines);
  }
}

/*!
 * \brief Utilities::parseMetaModelText
 * Parses the MetaModel text against the schema.
 * \param pMessageHandler
 * \param contents
 */
void Utilities::parseMetaModelText(MessageHandler *pMessageHandler, QString contents)
{
  QFile schemaFile(QString(":/Resources/XMLSchema/tlmModelDescription.xsd"));
  schemaFile.open(QIODevice::ReadOnly);
  const QString schemaText(QString::fromUtf8(schemaFile.readAll()));
  schemaFile.close();
  const QByteArray schemaData = schemaText.toUtf8();

  QXmlSchema schema;
  schema.setMessageHandler(pMessageHandler);
  schema.load(schemaData);
  if (!schema.isValid()) {
    pMessageHandler->setFailed(true);
  } else {
    QXmlSchemaValidator validator(schema);
    if (!validator.validate(contents.toUtf8())) {
      pMessageHandler->setFailed(true);
    }
  }
}

/*!
 * \brief Utilities::convertUnit
 * Converts the value using the unit offset and scale factor.
 * \param value
 * \param offset
 * \param scaleFactor
 * \return
 */
qreal Utilities::convertUnit(qreal value, qreal offset, qreal scaleFactor)
{
  return (value - offset) / scaleFactor;
}

Label* Utilities::getHeadingLabel(QString heading)
{
  Label *pHeadingLabel = new Label(heading);
  pHeadingLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  return pHeadingLabel;
}

QFrame* Utilities::getHeadingLine()
{
  QFrame *pHeadingLine = new QFrame();
  pHeadingLine->setFrameShape(QFrame::HLine);
  pHeadingLine->setFrameShadow(QFrame::Sunken);
  return pHeadingLine;
}

QTextCharFormat Utilities::getParenthesesMatchFormat()
{
  QTextCharFormat parenthesesMatchFormat;
  parenthesesMatchFormat.setForeground(Qt::red);
  parenthesesMatchFormat.setBackground(QColor(160, 238, 160));
  return parenthesesMatchFormat;
}

QTextCharFormat Utilities::getParenthesesMisMatchFormat()
{
  QTextCharFormat parenthesesMisMatchFormat;
  parenthesesMisMatchFormat.setBackground(Qt::red);
  return parenthesesMisMatchFormat;
}

void Utilities::highlightCurrentLine(QPlainTextEdit *pPlainTextEdit)
{
  QList<QTextEdit::ExtraSelection> selections = pPlainTextEdit->extraSelections();
  QTextEdit::ExtraSelection selection;
  QColor lineColor = QColor(232, 242, 254);
  selection.format.setBackground(lineColor);
  selection.format.setProperty(QTextFormat::FullWidthSelection, true);
  selection.cursor = pPlainTextEdit->textCursor();
  selection.cursor.clearSelection();
  selections.append(selection);
  pPlainTextEdit->setExtraSelections(selections);
}

void Utilities::highlightParentheses(QPlainTextEdit *pPlainTextEdit, QTextCharFormat parenthesesMatchFormat,
                                     QTextCharFormat parenthesesMisMatchFormat)
{
  if (pPlainTextEdit->isReadOnly()) {
    return;
  }

  QTextCursor backwardMatch = pPlainTextEdit->textCursor();
  QTextCursor forwardMatch = pPlainTextEdit->textCursor();
  if (pPlainTextEdit->overwriteMode()) {
    backwardMatch.movePosition(QTextCursor::Right);
  }

  const TextBlockUserData::MatchType backwardMatchType = TextBlockUserData::matchCursorBackward(&backwardMatch);
  const TextBlockUserData::MatchType forwardMatchType = TextBlockUserData::matchCursorForward(&forwardMatch);
  QList<QTextEdit::ExtraSelection> selections = pPlainTextEdit->extraSelections();

  if (backwardMatchType == TextBlockUserData::NoMatch && forwardMatchType == TextBlockUserData::NoMatch) {
    pPlainTextEdit->setExtraSelections(selections);
    return;
  }

  if (backwardMatch.hasSelection()) {
    QTextEdit::ExtraSelection selection;
    if (backwardMatchType == TextBlockUserData::Mismatch) {
      selection.cursor = backwardMatch;
      selection.format = parenthesesMisMatchFormat;
      selections.append(selection);
    } else {
      selection.cursor = backwardMatch;
      selection.format = parenthesesMatchFormat;

      selection.cursor.setPosition(backwardMatch.selectionStart());
      selection.cursor.setPosition(selection.cursor.position() + 1, QTextCursor::KeepAnchor);
      selections.append(selection);

      selection.cursor.setPosition(backwardMatch.selectionEnd());
      selection.cursor.setPosition(selection.cursor.position() - 1, QTextCursor::KeepAnchor);
      selections.append(selection);
    }
  }

  if (forwardMatch.hasSelection()) {
    QTextEdit::ExtraSelection selection;
    if (forwardMatchType == TextBlockUserData::Mismatch) {
      selection.cursor = forwardMatch;
      selection.format = parenthesesMisMatchFormat;
      selections.append(selection);
    } else {
      selection.cursor = forwardMatch;
      selection.format = parenthesesMatchFormat;

      selection.cursor.setPosition(forwardMatch.selectionStart());
      selection.cursor.setPosition(selection.cursor.position() + 1, QTextCursor::KeepAnchor);
      selections.append(selection);

      selection.cursor.setPosition(forwardMatch.selectionEnd());
      selection.cursor.setPosition(selection.cursor.position() - 1, QTextCursor::KeepAnchor);
      selections.append(selection);
    }
  }
  pPlainTextEdit->setExtraSelections(selections);
}

/*!
 * \brief Utilities::getProcessId
 * Returns the process id.
 * \param pProcess
 * \return
 */
qint64 Utilities::getProcessId(QProcess *pProcess)
{
  qint64 processId = 0;
#if (QT_VERSION >= QT_VERSION_CHECK(5, 3, 0))
  processId = pProcess->processId();
#else /* Qt4 */
#ifdef WIN32
  _PROCESS_INFORMATION *procInfo = pProcess->pid();
  if (procInfo) {
    processId = procInfo->dwProcessId;
  }
#else
  processId = pProcess->pid();
#endif /* WIN32 */
#endif /* QT_VERSION */
  return processId;
}

#ifdef WIN32
/* adrpo: found this on http://stackoverflow.com/questions/1173342/terminate-a-process-tree-c-for-windows
 * thanks go to: mjmarsh & Firas Assaad
 * adapted to recurse on children ids
 */
void Utilities::killProcessTreeWindows(DWORD myprocID)
{
  PROCESSENTRY32 pe;
  HANDLE hSnap = NULL, hProc = NULL;

  memset(&pe, 0, sizeof(PROCESSENTRY32));
  pe.dwSize = sizeof(PROCESSENTRY32);

  hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (Process32First(hSnap, &pe))
  {
    BOOL bContinue = TRUE;

    // kill child processes
    while (bContinue)
    {
      // only kill child processes
      if (pe.th32ParentProcessID == myprocID)
      {
        HANDLE hChildProc = NULL;

        // recurse
        killProcessTreeWindows(pe.th32ProcessID);

        hChildProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);

        if (hChildProc)
        {
          TerminateProcess(hChildProc, 1);
          CloseHandle(hChildProc);
        }
      }

      bContinue = Process32Next(hSnap, &pe);
    }

    // kill the main process
    hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, myprocID);

    if (hProc)
    {
      TerminateProcess(hProc, 1);
      CloseHandle(hProc);
    }
  }
}
#endif
