/**
 * Copyright (c) 2005 voidware ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#ifndef __bcdmath_h__
#define __bcdmath_h__

#include "bcd.h"

//BCD pi() BCD_SECT;
BCD sin(const BCD&) BCD_SECT;
BCD cos(const BCD&) BCD_SECT;
BCD tan(const BCD&) BCD_SECT;
BCD exp(const BCD&) BCD_SECT;
BCD log(const BCD&) BCD_SECT;
BCD atan(const BCD&) BCD_SECT;
BCD pow(const BCD&, int4 n) BCD_SECT;
BCD pow(const BCD&, const BCD&) BCD_SECT;
BCD atan2(const BCD& y, const BCD& x) BCD_SECT;
BCD asin(const BCD&) BCD_SECT;
BCD acos(const BCD&) BCD_SECT;
BCD modtwopi(const BCD&) BCD_SECT;
BCD log10(const BCD&) BCD_SECT;
BCD hypot(const BCD& a, const BCD& b) BCD_SECT;
BCD fmod(const BCD& a, const BCD& b) BCD_SECT;
BCD ln1p(const BCD&) BCD_SECT;
BCD expm1(const BCD&) BCD_SECT;
BCD gammaFactorial(const BCD&) BCD_SECT;

#endif // bcdmath
