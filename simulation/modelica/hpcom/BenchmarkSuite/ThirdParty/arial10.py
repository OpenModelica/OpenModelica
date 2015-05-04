'''
Character width dictionary and convenience functions for column sizing
with xlwt when Arial 10 is the standard font.  Widths were determined
experimentally using Excel 2000 on Windows XP.  I have no idea how well
these will work on other setups.  For example, I don't know if system
video settings will affect the results.  I do know for sure that this
module won't be applicable to other fonts in general.

//John Yeung  2009-09-02
'''

charwidths = {
    '0': 262.637,
    '1': 262.637,
    '2': 262.637,
    '3': 262.637,
    '4': 262.637,
    '5': 262.637,
    '6': 262.637,
    '7': 262.637,
    '8': 262.637,
    '9': 262.637,
    'a': 262.637,
    'b': 262.637,
    'c': 262.637,
    'd': 262.637,
    'e': 262.637,
    'f': 146.015,
    'g': 262.637,
    'h': 262.637,
    'i': 117.096,
    'j': 88.178,
    'k': 233.244,
    'l': 88.178,
    'm': 379.259,
    'n': 262.637,
    'o': 262.637,
    'p': 262.637,
    'q': 262.637,
    'r': 175.407,
    's': 233.244,
    't': 117.096,
    'u': 262.637,
    'v': 203.852,
    'w': 321.422,
    'x': 203.852,
    'y': 262.637,
    'z': 233.244,
    'A': 321.422,
    'B': 321.422,
    'C': 350.341,
    'D': 350.341,
    'E': 321.422,
    'F': 291.556,
    'G': 350.341,
    'H': 321.422,
    'I': 146.015,
    'J': 262.637,
    'K': 321.422,
    'L': 262.637,
    'M': 379.259,
    'N': 321.422,
    'O': 350.341,
    'P': 321.422,
    'Q': 350.341,
    'R': 321.422,
    'S': 321.422,
    'T': 262.637,
    'U': 321.422,
    'V': 321.422,
    'W': 496.356,
    'X': 321.422,
    'Y': 321.422,
    'Z': 262.637,
    ' ': 146.015,
    '!': 146.015,
    '"': 175.407,
    '#': 262.637,
    '$': 262.637,
    '%': 438.044,
    '&': 321.422,
    '\'': 88.178,
    '(': 175.407,
    ')': 175.407,
    '*': 203.852,
    '+': 291.556,
    ',': 146.015,
    '-': 175.407,
    '.': 146.015,
    '/': 146.015,
    ':': 146.015,
    ';': 146.015,
    '<': 291.556,
    '=': 291.556,
    '>': 291.556,
    '?': 262.637,
    '@': 496.356,
    '[': 146.015,
    '\\': 146.015,
    ']': 146.015,
    '^': 203.852,
    '_': 262.637,
    '`': 175.407,
    '{': 175.407,
    '|': 146.015,
    '}': 175.407,
    '~': 291.556}

# By default, Excel displays column widths in units equal to the width
# of '0' (the zero character) in the standard font.  For me, this is
# Arial 10, but it can be changed by the user.  The BIFF file format
# stores widths in units 1/256th that size.
#
# Within Excel, the smallest incrementable amount for column width
# is the pixel.  However many pixels it takes to draw '0' is how many
# increments there are between a width of 1 and a width of 2.  A
# request for a finer increment will be rounded to the nearest pixel.
# For Arial 10, this is 9 pixels, but different fonts will of course
# require different numbers of pixels, and thus have different column
# width granularity.
#
# So far so good, but there is a wrinkle.  Excel pads the first unit
# of column width by 7 pixels.  At least this is the padding when the
# standard font is Arial 10 or Courier New 10, the two fonts I've tried.
# It don't know if it's different for different fonts.  For Arial 10,
# with a padding of 7 pixels and a 9-pixel-wide '0', this results in 16
# increments to get from width 0 (hidden) to width 1.  Ten columns of
# width 1 are 160 pixels wide while five columns of width 2 are 125
# pixels wide.  A single column of width 10 is only 97 pixels wide.
#
# The punch line is that pixels are the true measure of width, and
# what Excel reports as the column width is wonky between 0 and 1.
# The only way I know to find out the padding for a desired font is
# to set that font as the standard font in Excel and count pixels.


def colwidth(n):
    '''Translate human-readable units to BIFF column width units'''
    if n <= 0:
        return 0
    if n <= 1:
        return n * 456
    return 200 + n * 256


def fitwidth(data, bold=False):
    '''Try to autofit Arial 10'''
    maxunits = 0
    for ndata in data.split("\n"):
        units = 220
        for char in ndata:
            if char in charwidths:
                units += charwidths[char]
            else:
                units += charwidths['0']
        if maxunits < units:
            maxunits = units
    if bold:
        maxunits *= 1.1
    return max(maxunits, 700)  # Don't go smaller than a reported width of 2


def fitheight(data, bold=False):
    '''Try to autofit Arial 10'''
    rowlen = len(data.split("\n"))
    if rowlen > 1:
        units = 230 * rowlen
    else:
        units = 290
    if bold:
        units *= 1.1
    return int(units)