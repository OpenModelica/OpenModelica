/****************************************************************************
** Meta object code from reading C++ file 'notebook.h'
**
** Created: fr 27. jan 11:08:11 2006
**      by: The Qt Meta Object Compiler version 58 (Qt 4.0.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "notebook.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'notebook.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 58
#error "This file was generated using the moc from 4.0.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__NotebookWindow[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      52,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // slots: signature, parameters, type, tag, flags
      22,   21,   21,   21, 0x0a,
      36,   21,   21,   21, 0x0a,
      54,   21,   21,   21, 0x0a,
      71,   21,   21,   21, 0x0a,
      88,   21,   21,   21, 0x0a,
     109,   21,   21,   21, 0x0a,
     130,   21,   21,   21, 0x0a,
     154,   21,   21,   21, 0x0a,
     176,   21,   21,   21, 0x0a,
     202,   21,   21,   21, 0x0a,
     232,   21,   21,   21, 0x0a,
     251,   21,   21,   21, 0x0a,
     270,   21,   21,   21, 0x0a,
     290,   21,   21,   21, 0x0a,
     309,   21,   21,   21, 0x0a,
     329,   21,   21,   21, 0x08,
     348,  339,   21,   21, 0x08,
     366,   21,   21,   21, 0x28,
     377,   21,   21,   21, 0x08,
     395,  389,   21,   21, 0x08,
     420,   21,   21,   21, 0x08,
     438,   21,   21,   21, 0x08,
     447,   21,   21,   21, 0x08,
     454,   21,   21,   21, 0x08,
     471,   21,   21,   21, 0x08,
     479,   21,   21,   21, 0x08,
     499,  492,   21,   21, 0x08,
     521,   21,   21,   21, 0x08,
     535,  492,   21,   21, 0x08,
     556,  492,   21,   21, 0x08,
     581,  492,   21,   21, 0x08,
     606,  492,   21,   21, 0x08,
     634,  492,   21,   21, 0x08,
     660,  492,   21,   21, 0x08,
     690,  492,   21,   21, 0x08,
     724,  492,   21,   21, 0x08,
     747,  492,   21,   21, 0x08,
     770,  492,   21,   21, 0x08,
     794,  492,   21,   21, 0x08,
     817,   21,   21,   21, 0x08,
     831,   21,   21,   21, 0x08,
     844,   21,   21,   21, 0x08,
     858,   21,   21,   21, 0x08,
     869,   21,   21,   21, 0x08,
     885,   21,   21,   21, 0x08,
     905,   21,   21,   21, 0x08,
     915,   21,   21,   21, 0x08,
     926,   21,   21,   21, 0x08,
     938,   21,   21,   21, 0x08,
     953,   21,   21,   21, 0x08,
     970,   21,   21,   21, 0x08,
     989,   21,   21,   21, 0x08,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__NotebookWindow[] = {
    "IAEX::NotebookWindow\0\0updateMenus()\0updateStyleMenu()\0"
    "updateEditMenu()\0updateFontMenu()\0updateFontFaceMenu()\0"
    "updateFontSizeMenu()\0updateFontStretchMenu()\0updateFontColorMenu()\0"
    "updateTextAlignmentMenu()\0updateVerticalAlignmentMenu()\0"
    "updateBorderMenu()\0updateMarginMenu()\0updatePaddingMenu()\0"
    "updateWindowMenu()\0updateWindowTitle()\0newFile()\0filename\0"
    "openFile(QString)\0openFile()\0closeFile()\0event\0"
    "closeEvent(QCloseEvent*)\0aboutQTNotebook()\0saveas()\0save()\0"
    "quitOMNotebook()\0print()\0selectFont()\0action\0changeStyle(QAction*)\0"
    "changeStyle()\0changeFont(QAction*)\0changeFontFace(QAction*)\0"
    "changeFontSize(QAction*)\0changeFontStretch(QAction*)\0"
    "changeFontColor(QAction*)\0changeTextAlignment(QAction*)\0"
    "changeVerticalAlignment(QAction*)\0changeBorder(QAction*)\0"
    "changeMargin(QAction*)\0changePadding(QAction*)\0changeWindow(QAction*)\0"
    "insertImage()\0insertLink()\0openOldFile()\0pureText()\0createNewCell()\0"
    "deleteCurrentCell()\0cutCell()\0copyCell()\0pasteCell()\0moveCursorUp()\0"
    "moveCursorDown()\0groupCellsAction()\0inputCellsAction()\0"
};

const QMetaObject IAEX::NotebookWindow::staticMetaObject = {
    { &DocumentView::staticMetaObject, qt_meta_stringdata_IAEX__NotebookWindow,
      qt_meta_data_IAEX__NotebookWindow, 0 }
};

const QMetaObject *IAEX::NotebookWindow::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::NotebookWindow::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__NotebookWindow))
	return static_cast<void*>(const_cast<NotebookWindow*>(this));
    return DocumentView::qt_metacast(_clname);
}

int IAEX::NotebookWindow::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = DocumentView::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: updateMenus(); break;
        case 1: updateStyleMenu(); break;
        case 2: updateEditMenu(); break;
        case 3: updateFontMenu(); break;
        case 4: updateFontFaceMenu(); break;
        case 5: updateFontSizeMenu(); break;
        case 6: updateFontStretchMenu(); break;
        case 7: updateFontColorMenu(); break;
        case 8: updateTextAlignmentMenu(); break;
        case 9: updateVerticalAlignmentMenu(); break;
        case 10: updateBorderMenu(); break;
        case 11: updateMarginMenu(); break;
        case 12: updatePaddingMenu(); break;
        case 13: updateWindowMenu(); break;
        case 14: updateWindowTitle(); break;
        case 15: newFile(); break;
        case 16: openFile(*(QString*)_a[1]); break;
        case 17: openFile(); break;
        case 18: closeFile(); break;
        case 19: closeEvent(*(QCloseEvent**)_a[1]); break;
        case 20: aboutQTNotebook(); break;
        case 21: saveas(); break;
        case 22: save(); break;
        case 23: quitOMNotebook(); break;
        case 24: print(); break;
        case 25: selectFont(); break;
        case 26: changeStyle(*(QAction**)_a[1]); break;
        case 27: changeStyle(); break;
        case 28: changeFont(*(QAction**)_a[1]); break;
        case 29: changeFontFace(*(QAction**)_a[1]); break;
        case 30: changeFontSize(*(QAction**)_a[1]); break;
        case 31: changeFontStretch(*(QAction**)_a[1]); break;
        case 32: changeFontColor(*(QAction**)_a[1]); break;
        case 33: changeTextAlignment(*(QAction**)_a[1]); break;
        case 34: changeVerticalAlignment(*(QAction**)_a[1]); break;
        case 35: changeBorder(*(QAction**)_a[1]); break;
        case 36: changeMargin(*(QAction**)_a[1]); break;
        case 37: changePadding(*(QAction**)_a[1]); break;
        case 38: changeWindow(*(QAction**)_a[1]); break;
        case 39: insertImage(); break;
        case 40: insertLink(); break;
        case 41: openOldFile(); break;
        case 42: pureText(); break;
        case 43: createNewCell(); break;
        case 44: deleteCurrentCell(); break;
        case 45: cutCell(); break;
        case 46: copyCell(); break;
        case 47: pasteCell(); break;
        case 48: moveCursorUp(); break;
        case 49: moveCursorDown(); break;
        case 50: groupCellsAction(); break;
        case 51: inputCellsAction(); break;
        }
        _id -= 52;
    }
    return _id;
}
