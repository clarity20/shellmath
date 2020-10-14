# shellfloat
Introducing floating-point arithmetic libraries for the Bash shell, because
they said it couldn't be done... and because:

.

![image info](./image.png)

## Quick-start guide
For a quick-and-dirty introduction to `shellfloat` run the demo `e_demo.sh` 
with a small whole-number argument, say 15:
```
$ e_demo.sh 15
e = 2.7182818284589936
```

This script uses a few `shellfloat` API calls to calculate *e*, the mathematical
constant also known as [Euler's number](https://oeis.org/A001113). The argument
*15* tells the script to compute the *15th-degree* 
Maclaurin polynomial for *e*. Take a look inside the script to see how it uses
the `shellfloat` APIs `_shellfloat_add` and `_shellfloat_divide`.

There is another demo script very much like this one but *different*, and the
sensitive user can *feel* the difference. Try the following, but don't blink 
or you'll miss it ;)
```
$ faster_e_demo.sh 15
e = 2.7182818284589936
```

Did you feel the difference? To drive the point home, try the `-t` option with
both scripts, as I did from my minGW terminal running on Windows 10 with Intel i3
Core CPU:
```
$ for n in {1..5}; do faster_e_demo.sh -t 15 2>&1; done | awk '/^real/ {print $2}'
0m0.055s
0m0.051s
0m0.056s
0m0.054s
0m0.054s

$ for n in {1..10}; do e_demo.sh -t 15 2>&1; done | awk '/^real/ {print $2}'
0m0.498s
0m0.594s
0m0.536s
0m0.511s
0m0.580s
```

Do keep in mind that every invocation of either script exercises the shellfloat 
arithmetic subroutines 31 times. You can find further discussion of runtime efficiency
[here](https://github.com/clarity20/shellfloat/wiki/Shellfloat-and-runtime-efficiency "Shellfloat and runtime efficiency").

The comment header in `faster_e_demo.sh` explains the difference. The code shows
how to make the faster version work for you.

## Usage
The API defines the four basic operations `_shellfloat_{add,subtract,multiply,divide}`.
Operands can be integers or floating-point (decimal) numbers presented in either standard
or scientific notation:
```
_shellfloat_add  1.009  4.223e-2
```
Addition and multiplication are of arbitrary arity; try 
```
_shellfloat_add  1  2  3  4  5  6
```
for instance. Subtraction and division, OTOH, are exclusively binary operations. 

Also included are `_shellfloat_getReturnValue{,s}` to improve performance; see 
`faster_e_demo.sh` for examples.

## Background
The Bash shell does not have built-in operators for decimal arithmetic, making it
something of an oddity among well-known programming languages. For the most part,
practitioners in need of powerful computational building blocks have naturally opted
for *other* languages and tools. Their widespread availability has diverted attention
from the possibility of *implementing* floating-point in Bash and a neophyte might
acquire the impression that this ***cannot*** be done:

+ From the indispensable _Bash FAQ_ (on _Greg's Wiki_): [How can I calculate with floating point numbers?](http://mywiki.wooledge.org/BashFAQ/022)  
  *"For most operations... an external program must be used."*
+ From Mendel Cooper's wonderful and encyclopedic _Advanced Bash Scripting Guide_:  
  [Bash does not understand floating point arithmetic. Use bc instead.](https://tldp.org/LDP/abs/html/ops.html#NOFLOATINGPOINT)
+ From a community discussion on Stack Overflow, _How do I use floating point division in bash?_  
  The user's [preferred answer](https://stackoverflow.com/questions/12722095/how-do-i-use-floating-point-division-in-bash#12722107)
  is a good example of _prevailing thought_ on this subject.

Meanwhile, 

+ Bash maintainer (BDFL?) Chet Ramey sounds a different note in [The Bash Reference Guide, Section 6.5] (https://tiswww.case.edu/php/chet/bash/bashref.html#Shell-Arithmetic)
  describing only what built-in shell arithmetic ***can*** do.

But finally, a glimmer of hope:

+ A [diamond-in-the-rough](http://stackoverflow.com/a/24431665/3776858) buried elsewhere
  on Stack Overflow.  
  This down-and-dirty milestone computes the decimal quotient of two integer arguments. At a casual
  glance, this seems to be inspired by the [Euclidean algorithm](https://mathworld.wolfram.com/EuclideanAlgorithm.html)
  for computing GCDs, an entirely different approach than `shellfloat`'s.

Please try `shellfloat` on for size and draw your own conclusions!

## How it works
`shellfloat` splits decimal numbers into their integer and fractional parts,
performs the appropriate integer operations on the parts, and recombines the results.
(In the spirit of Bash, numerical overflow is silently ignored.)

Because if we can get carrying, borrowing, place value, and the distributive
law right, then the sky's the limit! In other words:

        Ad astra per aspera.

## And now...
You can run your floating-point computations directly in Bash!

## Please see also:
[A short discussion on arbitrary precision and shellfloat](https://github.com/clarity20/shellfloat/wiki/Shellfloat-and-arbitrary-precision-arithmetic)
