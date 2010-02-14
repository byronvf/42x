About Free42

Free42 is a complete re-implementation of the HP-42S scientific programmable
RPN calculator, which was made from 1988 until 1995 by Hewlett-Packard.
Free42 is a complete rewrite and contains no HP code whatsoever.
At this time, the author supports versions that run on Pocket PC, Microsoft
Windows, PalmOS, Unix, and Mac OS X (application and Dashboard widget).


Installing Free42:

Copy Free42 Decimal (or Free42 Binary, or both) to wherever you want it, e.g.
in /Applications or somewhere in your home directory.
When Free42 runs, it will create three additional files; they are state.bin,
print.bin, and keymap.txt, and they are used to store the calculator's internal
state, the contents of the print-out window, and the keyboard map,
respectively. These files will be stored in the directory
$HOME/Library/Application Support/Free42.
Free42 comes with two skins built in, but you may use different ones, by
placing them in the directory $HOME/Library/Application Support/Free42. They
will show up in the Skin menu immediately.


Uninstalling Free42:

Remove Free42 Decimal, Free42 Binary, and the directory
$HOME/Library/Application Support/Free42 and its contents.


Documentation

The ultimate documentation for Free42 is the manual for the HP-42S. You can
obtain this manual in PDF format by purchasing the CD or DVD set from The
Museum of HP Calculators (http://hpmuseum.org/). Alternatively, there is an
independently written HP-42S/Free42 manual, by Jose Lauro Strapasson, which
you can download free at http://joselauro.com/42s.pdf.


Keyboard Mapping

You don't have to use the mouse to press the keys of the emulated calculator
keyboard; all keys can be operated using the PC's keyboard as well. The
standard keyboard mapping is as follows:

Sigma+:   F1, or 'a' as in "Accumulate"
Sigma-:   Shift F1, or 'A' (Shift a)
1/X:      F2, or 'v' as in "inVerse"
Y^X:      Shift F2, or 'V' (Shift v)
SQRT:     F3, or 'q' as in "sQuare root"
X^2:      Shift F3, or 'Q' (Shift q)
LOG:      F4, or 'o' as in "lOg, not ln"
10^X:     Shift F4, or 'O' (Shift o)
LN:       F5, or 'l' as in "Ln, not log"
E^X:      Shift F5, or 'L" (Shift l)
XEQ:      F6, or 'x' as in "Xeq"
GTO:      Shift F6, or 'X' (Shift x)

STO:      'm' as in "Memory"
COMPLEX:  'M' (Shift m)
RCL:      'r' as in "Rcl"
%:        'R' (Shift r)
Rdown:    'd' as in "Down"
pi:       'D' (Shift d)
SIN:      's' as in "Sin"
ASIN:     'S' (Shift s)
COS:      'c' as in "Cos"
ACOS:     'C' (Shift c)
TAN:      't' as in "Tan"
ATAN:     'T' (Shift t)

ENTER:    Enter or Return
ALPHA:    Shift Enter or Shift Return
X<>Y:     'w' as in "sWap"
LASTX:    'W' (Shift w)
+/-:      'n' as in "Negative"
MODES:    'N' (Shift n)
E:        'e' as in "Exponent" (duh...)
DISP:     'E' (Shift e)
<-:       Backspace
CLEAR:    Shift Backspace

<Up>:     CursorUp
BST:      Shift CursorUp
7:        '7'
SOLVER:   '&' (Shift 7)
8:        '8'
Integral: Alt 8 (can't use Shift 8 because that's 'x' (multiply))
9:        '9'
MATRIX:   '(' (Shift 9)
divide:   '/'
STAT:     '?' (Shift /)

<Down>:   CursorDown
SST:      Shift CursorDown
4:        '4'
BASE:     '$' (Shift 4)
5:        '5'
CONVERT:  '%' (Shift 5)
6:        '6'
FLAGS:    '^' (Shift 6)
multiply: '*'
PROB:     Ctrl 8 (can't use Shift * because '*' is shifted itself (Shift 8))

Shift:    Shift
1:        '1'
ASSIGN:   '!' (Shift 1)
2:        '2'
CUSTOM:   '@' (Shift 2)
3:        '3'
PGM.FCN:  '#' (Shift 3)
subtract: '-'
PRINT:    '_' (Shift -)

EXIT:     Escape
OFF:      Shift Escape
0:        '0'
TOP.FCN:  ')' (Shift 0)
.:        . or ,
SHOW:     '<' or '>' (Shift . or Shift ,)
R/S:      '\' (ummm... because it's close to Enter (or Return))
PRGM:     '|' (Shift \)
add:      '+'
CATALOG:  '=' (Can't use Shift + because + is shifted itself (shift =))

In A..F mode (meaning the "A..F" submenu of the BASE menu), the PC keyboard
keys A through F are mapped to the top row of the calculator's keyboard (Sigma+
through XEQ); these mappings override any other mappings that may be defined
for A through F.

In ALPHA mode, all PC keyboard keys that normally generate printable ASCII
characters, enter those characters into the ALPHA register (or to the command
argument, if a command with an alphanumeric argument is being entered). These
mappings override any other mappings that may be defined for those keys.


What's the deal with the "Decimal" and "Binary"?

Starting with release 1.4, Free42 comes in decimal and binary versions. The two
look and behave identically; the only difference is the way they represent
numbers internally.
Free42 Decimal uses Hugh Steers' 7-digit base-10000 BCD20 library, which
effectively gives 25 decimal digits of precision, with exponents ranging from
-10000 to +9999. Each number consumes 16 bytes of memory.
Free42 Binary uses the Mac's FPU; it represents numbers as IEEE-754 compatible
double precision binary floating point, which consumes 8 bytes per number, and
gives an effective precision of nearly 16 decimal digits, with exponents
ranging from -308 to +307 (actually, exponents can be less than -308; such
small numbers are "denormalized" and don't have the full precision of
"normalized" numbers).
The binary version has the advantage of being much faster than the decimal
version; also, it uses less memory. However, numbers such as 0.1 (one-tenth)
cannot be represented exactly in binary, since they are repeating fractions
then. This inexactness can cause some HP-42S programs to fail.
If you understand the issues surrounding binary floating point, and you do not
rely on legacy software that may depend on the exactness of decimal fractions,
you may use Free42 Binary and enjoy its speed advantage. If, on the other hand,
you need full HP-42S compatibility, you should use Free42 Decimal.
If you don't fully understand the above, it is best to play safe and use
Free42 Decimal.


Free42 is (C) 2004-2010, by Thomas Okken
BCD support (C) 2005-2009, by Hugh Steers / voidware
Contact the author at thomas_okken@yahoo.com
Look for updates, and versions for other operating systems, at
http://thomasokken.com/free42/
