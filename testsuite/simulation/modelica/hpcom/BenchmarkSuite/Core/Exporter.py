'''
Created on 14.10.2013

@author: Marcus
'''
import arial10
import xlwt

class ExcelResultExporter(object):
    @property
    def filePath(self):
        return self.__filePath

    @filePath.setter
    def filePath(self, value):
        self.__filePath = value

    def __init__(self, filePath=''):
        self.__filePath = filePath
        self.__fileOpen = False

    def open(self):
        self.__book = xlwt.Workbook(encoding="utf-8")
        self.__sheet = FitSheetWrapper(self.__book.add_sheet("Benchmark",cell_overwrite_ok=True))
        self.__fileOpen = True

    def close(self):
        self.__book.save(self.__filePath)
        self.__fileOpen = False

    def writeRow(self,rowIndex,values=[]):
        if(not self.__fileOpen):
            self.open()

        for i in range(0,len(values)):
            self.__sheet.write(rowIndex, i, values[i])

class FitSheetWrapper(object):
    """Try to fit columns to max size of any entry.
    To use, wrap this around a worksheet returned from the 
    workbook's add_sheet method, like follows:

        sheet = FitSheetWrapper(book.add_sheet(sheet_name))

    The worksheet interface remains the same: this is a drop-in wrapper
    for auto-sizing columns.
    """
    def __init__(self, sheet):
        self.sheet = sheet
        self.widths = dict()

    def write(self, r, c, label='', *args, **kwargs):
        self.sheet.write(r, c, label, *args, **kwargs)
        width = arial10.fitwidth(str(label))
        if width > self.widths.get(c, 0):
            self.widths[c] = int(width)
            self.sheet.col(c).width = int(width)

    def __getattr__(self, attr):
        return getattr(self.sheet, attr)
