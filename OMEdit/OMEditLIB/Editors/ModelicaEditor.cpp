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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "ModelicaEditor.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Options/OptionsDialog.h"
#include "Debugger/Breakpoints/BreakpointMarker.h"
#include "Util/Helper.h"
#include "Options/NotificationsDialog.h"

#include <QCompleter>
#include <QMenu>
#include <QMessageBox>


/*!
 * \class ModelicaEditor
 * \brief An editor for Modelica Text.
 */
/*!
 * \brief ModelicaEditor::ModelicaEditor
 * \param pParent
 */
ModelicaEditor::ModelicaEditor(QWidget *pParent)
  : BaseEditor(pParent), mLastValidText(""), mTextChanged(false)
{
  mpPlainTextEdit->setCanHaveBreakpoints(true);
  mpPlainTextEdit->setCompletionCharacters(".");
  /* set the document marker */
  if (isModelicaModelInPackageOneFile()) {
    mpDocumentMarker = new DocumentMarker(mpPlainTextEdit->document(), mpModelWidget->getLibraryTreeItem()->mClassInformation.lineNumberStart);
  } else {
    mpDocumentMarker = new DocumentMarker(mpPlainTextEdit->document());
  }
}

/*!
 * \brief ModelicaEditor::popUpCompleter()
 * show the popup for keywords and type for autocompletion
 */
void ModelicaEditor::popUpCompleter()
{
  QString word = wordUnderCursor();
  mpPlainTextEdit->clearCompleter();

  QList<CompleterItem> annotations;
  bool inAnnotation = getCompletionAnnotations(stringAfterWord("annotation"), annotations);
  mpPlainTextEdit->insertCompleterSymbols(annotations, ":/Resources/icons/completerAnnotation.svg");

  bool startsWithUpperCase = !word.isEmpty() && word[0].isUpper();

  if (!word.contains('.') && !inAnnotation) {
    // Suppose if user specially entered an upper case first letter,
    // it is definitely not a keyword...
    if (!startsWithUpperCase) {
      QStringList keywords = ModelicaHighlighter::getKeywords();
      mpPlainTextEdit->insertCompleterKeywords(keywords);
      QList<CompleterItem> codesnippets = getCodeSnippets();
      mpPlainTextEdit->insertCompleterCodeSnippets(codesnippets);
    }
    QStringList types = ModelicaHighlighter::getTypes();
    mpPlainTextEdit->insertCompleterTypes(types);
  }
  if (!inAnnotation) {
    QList<CompleterItem> classes, components;
    getCompletionSymbols(word, classes, components);

    std::sort(classes.begin(), classes.end());
    classes.erase(std::unique(classes.begin(), classes.end()), classes.end());

    std::sort(components.begin(), components.end());
    components.erase(std::unique(components.begin(), components.end()), components.end());

    mpPlainTextEdit->insertCompleterSymbols(classes, ":/Resources/icons/completerClass.svg");
    mpPlainTextEdit->insertCompleterSymbols(components, ":/Resources/icons/completerComponent.svg");
  }

  QCompleter *completer = mpPlainTextEdit->completer();
  QRect cr = mpPlainTextEdit->cursorRect();
  cr.setWidth(completer->popup()->sizeHintForColumn(0)+ completer->popup()->verticalScrollBar()->sizeHint().width());
  completer->complete(cr);
}

/*!
 * \brief ModelicaEditor::getCodeSnippets()
 * returns the list of CompleterItems to the autocompleter
 */
QList<CompleterItem> ModelicaEditor::getCodeSnippets()
{
  QList<CompleterItem> codesnippetslist;
  codesnippetslist << CompleterItem("function" ,"function name\n  \nend name;", "name")
                   << CompleterItem("block" ,"block name\n  \nend name;", "name")
                   << CompleterItem("model" ,"model name\n  \nend name;", "name")
                   << CompleterItem("class" ,"class name\n  \nend name;", "name")
                   << CompleterItem("connector" ,"connector name\n  \nend name;", "name")
                   << CompleterItem("package" ,"package name\n  \nend name;", "name")
                   << CompleterItem("record" ,"record name\n  \nend name;", "name")
                   << CompleterItem("while" ,"while condition loop\n  \nend while;", "condition")
                   << CompleterItem("if" ,"if condition then\n  \nend if;", "condition")
                   << CompleterItem("if" ,"if condition then\n  \nelseif condition then\n  \nelse\n  \nend if;", "condition")
                   << CompleterItem("for" ,"for condition loop\n  \nend for;", "condition")
                   << CompleterItem("when", "when condition then\n  \nend when;", "condition")
                   << CompleterItem("when", "when condition then\n  \nelsewhen condition then\n  \nend when;", "condition");
  return codesnippetslist;
}

LibraryTreeItem *ModelicaEditor::deepResolve(LibraryTreeItem *pItem, QStringList nameComponents)
{
  LibraryTreeItem *pCurrentItem = pItem;
  for (int i = 0; i < nameComponents.size(); ++i) {
    pCurrentItem = pCurrentItem->getComponentsClass(nameComponents[i]);
    if (!pCurrentItem)
      return 0;
  }
  return pCurrentItem;
}

QList<LibraryTreeItem*> ModelicaEditor::getCandidateContexts(QStringList nameComponents)
{
  QList<LibraryTreeItem*> result;
  QList<LibraryTreeItem*> roots;
  LibraryTreeItem *pItem = getModelWidget()->getLibraryTreeItem();
  while (pItem) {
    roots.append(pItem->getInheritedClassesDeepList());
    pItem = pItem->parent();
  }

  for (int i = 0; i < roots.size(); ++i) {
    LibraryTreeItem *pResolved = ModelicaEditor::deepResolve(roots[i], nameComponents);
    if (pResolved)
      result.append(pResolved);
  }
  return result;
}

/*!
 * \brief ModelicaEditor::wordUnderCursor
 * \return
 */
QString ModelicaEditor::wordUnderCursor()
{
  int end = mpPlainTextEdit->textCursor().position();
  int begin = end - 1;
  while (begin >= 0) {
    QChar ch = mpPlainTextEdit->document()->characterAt(begin);
    if (!(ch.isLetterOrNumber() || ch == '.' || ch == '_'))
      break;
    begin--;
  }
  begin++;
  return mpPlainTextEdit->document()->toPlainText().mid(begin, end - begin);
}

/*!
 * \brief ModelicaEditor::symbolAtPosition
 * Navigate to the Modelica class at position.
 * \param pos
 */
void ModelicaEditor::symbolAtPosition(const QPoint &pos)
{
  if (mpModelWidget) {
    QTextCursor cursor = mpPlainTextEdit->cursorForPosition(pos);
    cursor.select(QTextCursor::WordUnderCursor);

    int mid = cursor.position();
    int end = mid;

    while (end < cursor.block().length()) {
      QChar ch = mpPlainTextEdit->document()->characterAt(end);
      if (!(ch.isLetterOrNumber() || ch == '.' || ch == '_'))
        break;
      end++;
    }

    int begin = mid - 1;
    while (begin >= 0) {
      QChar ch = mpPlainTextEdit->document()->characterAt(begin);
      if (!(ch.isLetterOrNumber() || ch == '.' || ch == '_'))
        break;
      begin--;
    }
    begin++;

    mpModelWidget->navigateToClass(mpPlainTextEdit->document()->toPlainText().mid(begin, end - begin));
  }
}

/*!
 * \brief Returns the substring from the last occurrence of `word` to the cursor position
 * \param word Starting word of the substring
 * \return Resulting substring or Null QString if no `word` occurrence found up to the cursor position
 */
QString ModelicaEditor::stringAfterWord(const QString &word)
{
  int pos = mpPlainTextEdit->textCursor().position();
  QString plainText = mpPlainTextEdit->document()->toPlainText();
  int index = plainText.lastIndexOf(word, pos);
  if (index == -1)
    return QString();
  else
    return plainText.mid(index, pos - index);
}

void ModelicaEditor::getCompletionSymbols(QString word, QList<CompleterItem> &classes, QList<CompleterItem> &components)
{
  QStringList nameComponents = word.split('.');
  QString lastPart;
  if (!nameComponents.empty()) {
    lastPart = nameComponents.last();
    nameComponents.removeLast();
  } else {
    lastPart = "";
  }

  QList<LibraryTreeItem*> contexts = getCandidateContexts(nameComponents);

  for (int i = 0; i < contexts.size(); ++i) {
    contexts[i]->tryToComplete(classes, components, lastPart);
  }
}

/*!
 * \brief Looks up the root for annotation auto completion information
 */
LibraryTreeItem *ModelicaEditor::getAnnotationCompletionRoot()
{
  LibraryTreeItem *pLibraryRoot = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItemOneLevel(Helper::OMEditInternal);
  LibraryTreeItem *pModelicaReference = 0;

  for (int i = 0; i < pLibraryRoot->childrenSize(); ++i) {
    if (pLibraryRoot->childAt(i)->getName() == "OpenModelica") {
      pModelicaReference = pLibraryRoot->childAt(i);
    }
  }

  if (pModelicaReference) {
    return deepResolve(pModelicaReference, QStringList() << "AutoCompletion" << "Annotations");
  } else {
    return 0;
  }
}

/*!
 * \brief Returns a collection of completion items for the parsed `stack` of nested annotations
 * \param stack A stack of nested annotations (f.e. "annotation(uses(Modelica(ver|" becomes ["uses", "Modelica"]
 * \param annotations Resulting collection of compeltion items
 */
void ModelicaEditor::getCompletionAnnotations(const QStringList &stack, QList<CompleterItem> &annotations)
{
  LibraryTreeItem *pReference = getAnnotationCompletionRoot();
  if (pReference) {
    LibraryTreeItem *pAnnotation = deepResolve(pReference, stack);
    if (pAnnotation) {
      for (int i = 0; i < pAnnotation->childrenSize(); ++i) {
        QString name = pAnnotation->childAt(i)->getName();
        annotations << CompleterItem(name, name + "(", name, pAnnotation->childAt(i)->getHTMLDescription());
      }
      QList<ElementInfo> components = pAnnotation->getComponentsList();
      for (int i = 0; i < components.size(); ++i) {
        QString componentName = components[i].getName();
        QString componentValue = components[i].getParameterValue(MainWindow::instance()->getOMCProxy(), pAnnotation->getNameStructure());
        annotations << CompleterItem(componentName, QString("%1 = %2").arg(componentName, componentValue), componentName, components[i].getHTMLDescription());
      }
    }
  }
}

/*!
 * \brief Resolves the annotation under cursor as a stack of nested names and returns completions
 * \param str A string starting with the "annotation" word up to the cursor position
 * \param annotations Resulting collection of completion items
 * \return Whether current cursor position is considered inside an annotation
 */
bool ModelicaEditor::getCompletionAnnotations(const QString &str, QList<CompleterItem> &annotations)
{
  QStringList stack;
  int lastWordStart = 0;
  bool insideWord = false;

  if (str.isEmpty())
    return false;

  for (int i = 0; i < str.size(); ++i) {
    QChar ch = str[i];

    // do not prevent other completions in case of unrelated unfinished annotation
    if (ch == ';')
      return false;

    // First, handle string literals
    if (ch == '"') {
      for (++i; i < str.size() && str[i] != '"'; ++i) {
        if (str[i] == '\\')
          ++i;
      }
      // skipped, restarting as usual
      --i;
      continue;
    }

    // Now, handle the stack of annotations
    if (ch == '(') {
      stack << str.mid(lastWordStart, i - lastWordStart).trimmed();
    }
    if (ch == ')') {
      if (stack.isEmpty()) {
        return false; // not in an annotation at all
      }
      stack.pop_back();
    }

    // Last, account for boundaries of words to be placed in stack
    bool partOfLiteral = ch.isLetterOrNumber() || ch == '_';
    if (!insideWord && partOfLiteral) {
      lastWordStart = i;
    }
    insideWord = partOfLiteral;
  }

  if (stack.isEmpty()) {
    return false;
  }
  stack.pop_front(); // pop 'annotation'
  getCompletionAnnotations(stack, annotations);
  return true;
}

/*!
 * \brief ModelicaEditor::getClassNames
 * Uses the OMC parseString API to check the class names inside the Modelica Text
 * \param errorString
 * \return QStringList a list of class names
 * \sa ModelWidget::modelicaEditorTextChanged()
 */
QStringList ModelicaEditor::getClassNames(QString *errorString)
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QStringList classNames;
  LibraryTreeItem *pLibraryTreeItem = mpModelWidget->getLibraryTreeItem();
  if (mpPlainTextEdit->toPlainText().isEmpty()) {
    *errorString = tr("Start and End modifiers are different");
    return QStringList();
  } else {
    QString modelicaText = mpPlainTextEdit->toPlainText();
    QString stringToParse = modelicaText;
    if (!modelicaText.startsWith("within")) {
      if (pLibraryTreeItem->isInPackageOneFile()) {
        stringToParse = pLibraryTreeItem->getClassTextBefore() + modelicaText + pLibraryTreeItem->getClassTextAfter();
        // first we try to parse whole string so that we get correct line numbers for errors if any (see Ticket #3969).
        classNames = pOMCProxy->parseString(stringToParse, pLibraryTreeItem->getFileName());
        // if the whole string parses successfully then parse the subset for just this class.
        if (classNames.size() > 0) {
          stringToParse = QString("within %1;%2").arg(pLibraryTreeItem->parent()->getNameStructure()).arg(modelicaText);
          classNames = pOMCProxy->parseString(stringToParse, pLibraryTreeItem->getFileName());
        }
      } else {
        stringToParse = QString("within %1;%2").arg(pLibraryTreeItem->parent()->getNameStructure()).arg(modelicaText);
        classNames = pOMCProxy->parseString(stringToParse, pLibraryTreeItem->getFileName());
      }
    } else {
      classNames = pOMCProxy->parseString(stringToParse, pLibraryTreeItem->getFileName());
    }
  }
  // if user is defining multiple top level classes.
  if (classNames.size() > 1) {
    *errorString = QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg(pLibraryTreeItem->getNameStructure())
        .arg(classNames.join(","));
    return QStringList();
  }
  bool existModel = false;
  QStringList existingmodelsList;
  // check if the class already exists
  foreach(QString className, classNames) {
    if (pLibraryTreeItem->getNameStructure().compare(className) != 0) {
      if (MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className)) {
        existingmodelsList.append(className);
        existModel = true;
      }
    }
  }
  // check if existModel is true
  if (existModel) {
    *errorString = QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES)).arg(existingmodelsList.join(",")).append("\n")
        .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(""));
    return QStringList();
  }
  return classNames;
}

/*!
 * \brief ModelicaEditor::validateText
 * When user make some changes in the ModelicaEditor text then this method validates the text and show text correct options.
 * \param pLibraryTreeItem
 * \return
 */
bool ModelicaEditor::validateText(LibraryTreeItem **pLibraryTreeItem)
{
  if (isTextChanged()) {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!mpModelWidget->modelicaEditorTextChanged(pLibraryTreeItem)) {
      QSettings *pSettings = Utilities::getApplicationSettings();
      int answer = -1;
      if (pSettings->contains("textEditor/revertPreviousOrFixErrorsManually")) {
        answer = pSettings->value("textEditor/revertPreviousOrFixErrorsManually").toInt();
      }
      if (answer < 0 || OptionsDialog::instance()->getNotificationsPage()->getAlwaysAskForTextEditorErrorCheckBox()->isChecked()) {
        NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::RevertPreviousOrFixErrorsManually,
                                                                            NotificationsDialog::CriticalIcon,
                                                                            MainWindow::instance());
        pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::ERROR_IN_TEXT).arg("Modelica")
                                                         .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGE_BROWSER))
                                                         .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
        pNotificationsDialog->getOkButton()->setText(Helper::revertToLastCorrectVersion);
        pNotificationsDialog->getOkButton()->setAutoDefault(false);
        pNotificationsDialog->getCancelButton()->setText(Helper::fixErrorsManually);
        pNotificationsDialog->getCancelButton()->setAutoDefault(true);
        pNotificationsDialog->getButtonBox()->removeButton(pNotificationsDialog->getOkButton());
        pNotificationsDialog->getButtonBox()->removeButton(pNotificationsDialog->getCancelButton());
        pNotificationsDialog->getButtonBox()->addButton(pNotificationsDialog->getCancelButton(), QDialogButtonBox::ActionRole);
        pNotificationsDialog->getButtonBox()->addButton(pNotificationsDialog->getOkButton(), QDialogButtonBox::ActionRole);
        // we set focus to this widget here so when the error dialog is closed Qt gives back the focus to this widget.
        mpPlainTextEdit->setFocus(Qt::ActiveWindowFocusReason);
        answer = pNotificationsDialog->exec();
      }
      switch (answer) {
        case QMessageBox::RejectRole:
          setTextChanged(false);
          // revert back to last correct version
          setPlainText(mLastValidText);
          return true;
        case QMessageBox::AcceptRole:
        default:
          setTextChanged(true);
          return false;
      }
    } else {
      setTextChanged(false);
      mLastValidText = mpPlainTextEdit->toPlainText();
    }
  }
  /* Update the Library Browser when Modelica text change is done
   * See discussion #10728
   */
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showHideProtectedClasses();
  return true;
}

/*!
 * \brief ModelicaEditor::storeLeadingSpaces
 * Stores the leading spaces information in the text block user data.
 * \param leadingSpacesMap
 */
void ModelicaEditor::storeLeadingSpaces(QMap<int, int> leadingSpacesMap)
{
  QTextBlock block = mpPlainTextEdit->document()->firstBlock();
  while (block.isValid()) {
    TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(block);
    if (pTextBlockUserData) {
      pTextBlockUserData->setLeadingSpaces(leadingSpacesMap.value(block.blockNumber() + 1, -1));
    }
    block = block.next();
  }
}

/*!
 * \brief ModelicaEditor::getPlainText
 * Reads the leading spaces information from the text block user data and inserts them to the actual string.
 * \return
 */
QString ModelicaEditor::getPlainText()
{
  LibraryTreeItem *pLibraryTreeItem = mpModelWidget->getLibraryTreeItem();
  if (pLibraryTreeItem->isInPackageOneFile()) {
    QString text;
    QTextBlock block = mpPlainTextEdit->document()->firstBlock();
    while (block.isValid()) {
      TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(block);
      if (pTextBlockUserData) {
        if (pTextBlockUserData->getLeadingSpaces() == -1) {
          TextBlockUserData *pFirstBlockUserData = BaseEditorDocumentLayout::userData(mpPlainTextEdit->document()->firstBlock());
          if (pFirstBlockUserData) {
            if (pFirstBlockUserData->getLeadingSpaces() == -1) {
              pTextBlockUserData->setLeadingSpaces(pLibraryTreeItem->getNestedLevelInPackage());
            } else {
              pTextBlockUserData->setLeadingSpaces(pFirstBlockUserData->getLeadingSpaces());
            }
          } else {
            pTextBlockUserData->setLeadingSpaces(0);
          }
        }
        text += QString(pTextBlockUserData->getLeadingSpaces(), ' ');
      }
      text += block.text();
      block = block.next();
      if (block.isValid()) { // not last block
        text += "\n";
      }
    }
    return text;
  } else {
    return mpPlainTextEdit->toPlainText();
  }
}

/*!
 * \brief ModelicaEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void ModelicaEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = BaseEditor::createStandardContextMenu();
  pMenu->addSeparator();
  pMenu->addAction(mpOpenClassAction);
  pMenu->addSeparator();
  pMenu->addAction(mpToggleCommentSelectionAction);
  pMenu->addSeparator();
  pMenu->addAction(mpFoldAllAction);
  pMenu->addAction(mpUnFoldAllAction);
  mContextMenuStartPosition = point;
  mContextMenuStartPositionValid = true;
  pMenu->exec(mapToGlobal(point));
  mContextMenuStartPositionValid = false;
  delete pMenu;
}

/*!
 * \brief ModelicaEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 * \param useInserText
 */
void ModelicaEditor::setPlainText(const QString &text, bool useInserText)
{
  QMap<int, int> leadingSpacesMap;
  QString contents = text;
  // store and remove leading spaces
  if (mpModelWidget->getLibraryTreeItem()->isInPackageOneFile()) {
    leadingSpacesMap = StringHandler::getLeadingSpaces(contents);
    contents = StringHandler::removeLeadingSpaces(contents);
  }
  // Only set the text when it is really new
  if (contents != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    if (!useInserText) {
      mpPlainTextEdit->setPlainText(contents);
    } else {
      QTextCursor textCursor (mpPlainTextEdit->document());
      textCursor.beginEditBlock();
      textCursor.select(QTextCursor::Document);
      textCursor.insertText(contents);
      textCursor.endEditBlock();
      mpPlainTextEdit->setTextCursor(textCursor);
    }
    if (mpModelWidget->getLibraryTreeItem()->isInPackageOneFile()) {
      storeLeadingSpaces(leadingSpacesMap);
    }
    setTextChanged(false);
    mForceSetPlainText = false;
    mLastValidText = contents;
    /* ticket:4409 Object moving in block diagram unfolds all annotations in text view.
     * Make sure ModelicaHighlighter::highlightBlock is called before calling foldAll.
     */
    OptionsDialog::instance()->emitModelicaEditorSettingsChanged();
    mpPlainTextEdit->foldAll();
  }
}

//! Slot activated when ModelicaTextEdit's QTextDocument contentsChanged SIGNAL is raised.
//! Sets the model as modified so that user knows that his current model is not saved.
void ModelicaEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the system library class. */
    if (mpModelWidget->getLibraryTreeItem()->isSystemLibrary() && !mForceSetPlainText) {
      mpInfoBar->showMessage(tr("<b>Warning: </b>You are changing a system library class. System libraries are always read-only. Your changes will not be saved."));
    } else if (mpModelWidget->isElementMode() && !mForceSetPlainText) {
      mpInfoBar->showMessage(tr("<b>Warning: </b>Cannot modify the text in the element mode. Your changes will not be saved."));
    } else if (mpModelWidget->getLibraryTreeItem()->isReadOnly() && !mForceSetPlainText) {
      /* if user is changing the read-only class. */
      mpInfoBar->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    } else {
      /* if user is changing, the normal class. */
      if (!mForceSetPlainText) {
        contentsChanged();
        setTextChanged(true);
      }
      /* Keep the line numbers and the block information for the line breakpoints updated */
      if (charsRemoved != 0) {
        mpDocumentMarker->updateBreakpointsLineNumber();
        mpDocumentMarker->updateBreakpointsBlock(mpPlainTextEdit->document()->findBlock(position));
      } else {
        const QTextBlock posBlock = mpPlainTextEdit->document()->findBlock(position);
        const QTextBlock nextBlock = mpPlainTextEdit->document()->findBlock(position + charsAdded);
        if (posBlock != nextBlock) {
          mpDocumentMarker->updateBreakpointsLineNumber();
          mpDocumentMarker->updateBreakpointsBlock(posBlock);
          mpDocumentMarker->updateBreakpointsBlock(nextBlock);
        } else {
          mpDocumentMarker->updateBreakpointsBlock(posBlock);
        }
      }
    }
  }
}

/*!
 * \brief ModelicaEditor::toggleCommentSelection
 */
void ModelicaEditor::toggleCommentSelection()
{
  BaseEditor::toggleCommentSelection();
}

//! @class ModelicaTextHighlighter
//! @brief A syntax highlighter for ModelicaEditor.

//! Constructor
ModelicaHighlighter::ModelicaHighlighter(ModelicaEditorPage *pModelicaEditorPage, QPlainTextEdit *pPlainTextEdit)
  : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpModelicaEditorPage = pModelicaEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void ModelicaHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
#if QT_VERSION >= QT_VERSION_CHECK(5, 11, 0)
  mpPlainTextEdit->setTabStopDistance((qreal)(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).horizontalAdvance(QLatin1Char(' '))));
#else // QT_VERSION_CHECK
  mpPlainTextEdit->setTabStopWidth(mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
#endif // QT_VERSION_CHECK
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpModelicaEditorPage->getColor("Text"));
  mKeywordFormat.setForeground(mpModelicaEditorPage->getColor("Keyword"));
  mTypeFormat.setForeground(mpModelicaEditorPage->getColor("Type"));
  mSingleLineCommentFormat.setForeground(mpModelicaEditorPage->getColor("Comment"));
  mMultiLineCommentFormat.setForeground(mpModelicaEditorPage->getColor("Comment"));
  mFunctionFormat.setForeground(mpModelicaEditorPage->getColor("Function"));
  mQuotationFormat.setForeground(mpModelicaEditorPage->getColor("Quotes"));
  // Priority: keyword > func() > ident > number. Yes, the order matters :)
  mNumberFormat.setForeground(mpModelicaEditorPage->getColor("Number"));
  rule.mPattern = QRegExp("[0-9][0-9]*([.][0-9]*)?([eE][+-]?[0-9]*)?");
  rule.mFormat = mNumberFormat;
  mHighlightingRules.append(rule);
  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);
  // functions
  rule.mPattern = QRegExp("\\b[A-Za-z0-9_]+(?=\\()");
  rule.mFormat = mFunctionFormat;
  mHighlightingRules.append(rule);
  // keywords
  QStringList keywordPatterns = getKeywords();
  foreach (const QString &pattern, keywordPatterns) {
    QString newPattern = QString("\\b%1\\b").arg(pattern);
    rule.mPattern = QRegExp(newPattern);
    rule.mFormat = mKeywordFormat;
    mHighlightingRules.append(rule);
  }
  // Modelica types
  QStringList typePatterns = getTypes();
  foreach (const QString &pattern, typePatterns) {
    QString newPattern = QString("\\b%1\\b").arg(pattern);
    rule.mPattern = QRegExp(newPattern);
    rule.mFormat = mTypeFormat;
    mHighlightingRules.append(rule);
  }
}

// Function which returns list of keywords for the highlighter
QStringList ModelicaHighlighter::getKeywords()
{
  QStringList keywordsList;
  keywordsList   << "algorithm"
                 << "and"
                 << "annotation"
                 << "assert"
                 << "block"
                 << "break"
                 << "class"
                 << "connect"
                 << "connector"
                 << "constant"
                 << "constrainedby"
                 << "der"
                 << "discrete"
                 << "each"
                 << "else"
                 << "elseif"
                 << "elsewhen"
                 << "encapsulated"
                 << "end"
                 << "enumeration"
                 << "equation"
                 << "expandable"
                 << "extends"
                 << "external"
                 << "false"
                 << "final"
                 << "flow"
                 << "for"
                 << "function"
                 << "if"
                 << "import"
                 << "impure"
                 << "in"
                 << "initial"
                 << "inner"
                 << "input"
                 << "loop"
                 << "model"
                 << "not"
                 << "operator"
                 << "or"
                 << "outer"
                 << "output"
                 << "optimization"
                 << "package"
                 << "parameter"
                 << "partial"
                 << "protected"
                 << "public"
                 << "pure"
                 << "record"
                 << "redeclare"
                 << "replaceable"
                 << "return"
                 << "stream"
                 << "then"
                 << "true"
                 << "type"
                 << "when"
                 << "while"
                 << "within";
  return keywordsList;
}

// Function which returns list of types for the highlighter
QStringList ModelicaHighlighter::getTypes()
{
  QStringList typesList;
  typesList << "String"
            << "Integer"
            << "Boolean"
            << "Real";
  return typesList;
}

/*!
 * \brief ModelicaTextHighlighter::highlightMultiLine
 * Highlights the multilines text.
 * Quoted text or multiline comments.
 * \param text
 */
void ModelicaHighlighter::highlightMultiLine(const QString &text)
{
  /* Hand-written recognizer beats the crap known as QRegEx ;) */
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  bool foldingState = false;
  QTextBlock previousTextBlck = currentBlock().previous();
  TextBlockUserData *pPreviousTextBlockUserData = BaseEditorDocumentLayout::userData(previousTextBlck);
  if (pPreviousTextBlockUserData) {
    foldingState = pPreviousTextBlockUserData->foldingState();
  }
  QRegExp annotationRegExp("\\bannotation\\b");
  int annotationIndex = annotationRegExp.indexIn(text);
  // store parentheses info
  Parentheses parentheses;
  TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(currentBlock());
  if (pTextBlockUserData) {
    pTextBlockUserData->clearParentheses();
    pTextBlockUserData->setFoldingIndent(0);
    pTextBlockUserData->setFoldingEndIncluded(false);
  }
  while (index < text.length()) {
    switch (blockState) {
      /* if the block already has single line comment then don't check for multi line comment and quotes. */
      case 1:
        if (text[index] == '/' && index+1<text.length() && text[index+1] == '/') {
          index++;
          blockState = 1; /* don't change the blockstate. */
        }
        break;
      case 2:
        if (text[index] == '*' && index+1<text.length() && text[index+1] == '/') {
          index++;
          setFormat(startIndex, index-startIndex+1, mMultiLineCommentFormat);
          blockState = 0;
        }
        break;
      case 3:
        if (text[index] == '\\') {
          index++;
        } else if (text[index] == '"') {
          setFormat(startIndex, index-startIndex+1, mQuotationFormat);
          blockState = 0;
        }
        break;
      default:
        /* check if single line comment then set the blockstate to 1. */
        if (text[index] == '/' && index+1<text.length() && text[index+1] == '/') {
          startIndex = index++;
          setFormat(startIndex, text.length(), mSingleLineCommentFormat);
          blockState = 1;
        } else if (text[index] == '/' && index+1<text.length() && text[index+1] == '*') {
          startIndex = index++;
          blockState = 2;
        } else if (text[index] == '"') {
          startIndex = index;
          blockState = 3;
        }
    }
    // if no single line comment, no multi line comment and no quotes then store the parentheses
    if (pTextBlockUserData && (blockState < 1 || blockState > 3 || mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getMatchParenthesesCommentsQuotesCheckBox()->isChecked())) {
      if (text[index] == '(' || text[index] == '{' || text[index] == '[') {
        parentheses.append(Parenthesis(Parenthesis::Opened, text[index], index));
      } else if (text[index] == ')' || text[index] == '}' || text[index] == ']') {
        parentheses.append(Parenthesis(Parenthesis::Closed, text[index], index));
      }
    }
    if (pTextBlockUserData && foldingState) {
      // if no single line comment, no multi line comment and no quotes then check for annotation end
      if (blockState < 1 || blockState > 3) {
        if (text[index] == ';') {
          if (pTextBlockUserData) {
            QString endText = text.mid(index + 1);
            /* if we have some text after closing the annotation then we don't want to fold it.
             * ticket:4310 But if the ending text is just white space then fold it.
             */
            if (index == text.length() - 1 || TabSettings::firstNonSpace(endText) == endText.length()) {
              if (annotationIndex < 0) { // if we have one line annotation, we don't want to fold it.
                pTextBlockUserData->setFoldingIndent(1);
              }
              pTextBlockUserData->setFoldingEndIncluded(true);
            } else {
              pTextBlockUserData->setFoldingIndent(0);
            }
          }
          foldingState = false;
        } else if (pTextBlockUserData && annotationIndex < 0) { // if we have one line annotation, we don't want to fold it.
          pTextBlockUserData->setFoldingIndent(1);
        }
      } else if (pTextBlockUserData && annotationIndex < 0) { // if we have one line annotation, we don't want to fold it.
        pTextBlockUserData->setFoldingIndent(1);
      } else if (pTextBlockUserData && startIndex < annotationIndex) {  // if we have annotation word before quote or comment block is starting then fold.
        pTextBlockUserData->setFoldingIndent(1);
      }
    } else {
      // if no single line comment, no multi line comment and no quotes then check for annotation start
      if (blockState < 1 || blockState > 3) {
        if (text[index] == 'a' && index+9<text.length() && text[index+1] == 'n' && text[index+2] == 'n' && text[index+3] == 'o'
            && text[index+4] == 't' && text[index+5] == 'a' && text[index+6] == 't' && text[index+7] == 'i' && text[index+8] == 'o'
            && text[index+9] == 'n') {
          if (index+9 == text.length() - 1) { // if we just have annotation keyword in the line
            index = index + 8;
            foldingState = true;
          } else if (index+10<text.length() && (text[index+10] == '(' || text[index+10] == ' ')) { // if annotation keyword is followed by '(' or space.
            index = index + 9;
            foldingState = true;
          }
        }
      }
    }
    index++;
  }
  if (pTextBlockUserData) {
    pTextBlockUserData->setParentheses(parentheses);
    if (foldingState) {
      pTextBlockUserData->setFoldingState(true);
      // Hanldle empty blocks inside annotaiton section
      if (text.isEmpty() && foldingState) {
        pTextBlockUserData->setFoldingIndent(1);
      }
    }
    // set text block user data
    setCurrentBlockUserData(pTextBlockUserData);
  }
  switch (blockState) {
    case 2:
      setFormat(startIndex, text.length()-startIndex, mMultiLineCommentFormat);
      setCurrentBlockState(2);
      break;
    case 3:
      setFormat(startIndex, text.length()-startIndex, mQuotationFormat);
      setCurrentBlockState(3);
      break;
  }
}

//! Reimplementation of QSyntaxHighlighter::highlightBlock
void ModelicaHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpModelicaEditorPage->getOptionsDialog()->getTextEditorPage()->getSyntaxHighlightingGroupBox()->isChecked()) {
    return;
  }
  // set text block state
  setCurrentBlockState(0);
  TextBlockUserData *pTextBlockUserData = BaseEditorDocumentLayout::userData(currentBlock());
  if (pTextBlockUserData) {
    pTextBlockUserData->setFoldingState(false);
  }
  setFormat(0, text.length(), mpModelicaEditorPage->getColor("Text"));
  foreach (const HighlightingRule &rule, mHighlightingRules) {
    QRegExp expression(rule.mPattern);
    int index = expression.indexIn(text);
    while (index >= 0) {
      int length = expression.matchedLength();
      setFormat(index, length, rule.mFormat);
      index = expression.indexIn(text, index + length);
    }
  }
  highlightMultiLine(text);
}

/*!
 * \brief ModelicaHighlighter::settingsChanged
 * Slot activated whenever ModelicaEditor text settings changes.
 */
void ModelicaHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}
