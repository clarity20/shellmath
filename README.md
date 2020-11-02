# Shellfloat
Introducing floating-point arithmetic libraries for the Bash shell, because
they said it couldn't be done... and because:

.

![image info](./image.png)

## Quick-start guide
Download this project and source the file `shellmath.sh` into your shell script.
Then fire away at the shellmath API.

The ___basic___ API looks like this:
```
    _shellmath_add        arg1   arg2  [...]  argN
    _shellmath_subtract   arg1   arg2
    _shellmath_multiply   arg1   arg2  [...]  argN
    _shellmath_divide     arg1   arg2
```

The ___extended___ API introduces one more function:
```
    _shellmath_getReturnValue   arg
```

This function optimizes away the need for ___$(___ subshelling ___)___ in order to capture `shellmath`'s output.
To use this feature, just be sure to set `__shellmath_isOptimized=1` at the top
of your script. (You can find an example in `faster_e_demo.sh`.)

Operands to the _shellmath_ functions can be integers or floating-point 
(decimal) numbers presented in either standard or scientific notation:
```
    _shellmath_add   1.009   4.223e-2
    _shellmath_getReturnValue   sum
```
Addition and multiplication are of arbitrary arity; try this on for size:
```
    _shellmath_multiply  1  2  3  4  5  6
    _shellmath_getReturnValue   sixFactorial
```
Subtraction and division, OTOH, are exclusively binary operations. 

## The demos
For a gentler introduction to `shellmath` run the demo `e_demo.sh` 
with a small whole-number argument, say 15:
```
$ e_demo.sh 15
e = 2.7182818284589936
```

This script uses a few `shellmath` API calls to calculate *e*, the mathematical
constant also known as [Euler's number](https://oeis.org/A001113). The argument 
*15* tells the script to evaluate the *15th-degree* Maclaurin polynomial for *e*.
(That's the Taylor polynomial centered at 0.) Take a look inside the script to
see how it uses the `shellmath` APIs.

There is another demo script very much like this one but *different*, and the
sensitive user can *feel* the difference. Try the following, but don't blink 
or you'll miss it ;)
```
$ faster_e_demo.sh 15
e = 2.7182818284589936
```

Did you feel the difference? Try the `-t` option with both scripts. Here are my results
when running from my minGW64 command prompt on Windows 10 with an Intel i3 Core CPU:
```
$ for n in {1..5}; do faster_e_demo.sh -t 15 2>&1; done | awk '/^real/ {print $2}'
0m0.055s
0m0.051s
0m0.056s
0m0.054s
0m0.054s

$ for n in {1..5}; do e_demo.sh -t 15 2>&1; done | awk '/^real/ {print $2}'
0m0.498s
0m0.594s
0m0.536s
0m0.511s
0m0.580s
```

(When sizing up these timings, do keep in mind that ___we are timing the
computation of e from its Maclaurin polynomial. Every invocation of either
script is exercising the shellmath arithmetic subroutines 31 times.___)

The comment header in `faster_e_demo.sh` explains the optimization and shows
how to put this faster version to work for you.

You can find further discussion of shellmath's runtime efficiency
[here](https://github.com/clarity20/shellmath/wiki/Shellfloat-and-runtime-efficiency).

## Background
The Bash shell does not have built-in operators for decimal arithmetic, making it
something of an oddity among well-known, contemporary programming languages. For the most part,
practitioners in need of powerful computational building blocks have naturally opted
for *other* languages and tools. Their widespread availability has diverted attention
from the possibility of *implementing* floating-point in Bash and it's easy to assume
that this ***cannot*** be done:

+ From the indispensable _Bash FAQ_ (on _Greg's Wiki_): [How can I calculate with floating point numbers?](http://mywiki.wooledge.org/BashFAQ/022)  
  *"For most operations... an external program must be used."*
+ From Mendel Cooper's wonderful and encyclopedic _Advanced Bash Scripting Guide_:  
  [Bash does not understand floating point arithmetic. Use bc instead.](https://tldp.org/LDP/abs/html/ops.html#NOFLOATINGPOINT)
+ From a community discussion on Stack Overflow, _How do I use floating point division in bash?_  
  The user's [preferred answer](https://stackoverflow.com/questions/12722095/how-do-i-use-floating-point-division-in-bash#12722107)
  is a good example of _prevailing thought_ on this subject.

Meanwhile, 

+ Bash maintainer (BDFL?) Chet Ramey sounds a (brighter?) note in [The Bash Reference Guide, Section 6.5](https://tiswww.case.edu/php/chet/bash/bashref.html#Shell-Arithmetic)
  by emphasizing what the built-in arithmetic operators ***can*** do.

But finally, a glimmer of hope:

+ A [diamond-in-the-rough](http://stackoverflow.com/a/24431665/3776858) buried elsewhere
  on Stack Overflow.  
  This down-and-dirty milestone computes the decimal quotient of two integer arguments. At a casual
  glance, it seems to have drawn inspiration from the [Euclidean algorithm](https://mathworld.wolfram.com/EuclideanAlgorithm.html)
  for computing GCDs, an entirely different approach than `shellmath`'s.

Please try `shellmath` on for size and draw your own conclusions!

## How it works
`shellmath` splits decimal numbers into their integer and fractional parts,
performs the appropriate integer operations on the parts, and recombines the results.
(In the spirit of Bash, numerical overflow is silently ignored.)

Because if we can get carrying, borrowing, place value, and the distributive
law right, then the sky's the limit! As they say-- erm, as they ___said___ in Rome,

        Ad astra per aspera.

## And now...
You can run your floating-point calculations directly in Bash!

## Please see also:
[A short discussion on arbitrary precision and shellmath](https://github.com/clarity20/shellmath/wiki/Shellfloat-and-arbitrary-precision-arithmetic)
