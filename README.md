# shellfloat
Introducing floating-point arithmetic libraries for the Bash shell, because
they said it couldn't be done... and because:

.

![image info](./image.png)

## Quick start guide
For a quick-and-dirty introduction to `shellfloat` run the demo `e_demo.sh` 
with a small whole-number argument, say 15:
```
$ e_demo.sh 15
e = 2.7182818284589936
```

This script uses a few `shellfloat` API calls to calculate the mathematical
constant *e*. The number *15* instructs the script to compute the *15th-degree* 
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
arithmetic subroutines 31 times. You can find further discussion of runtime 
efficiency here:
[Shellfloat and runtime efficiency](https://github.com/clarity20/shellfloat/wiki "Shellfloat and runtime efficiency")

The comment header in `fasder_e_demo.sh` explains the difference. The code shows
how to make the faster version work for you.

## Background
The Bash shell does not have built-in facilities for decimal arithmetic, making
it an oddity among well-known programming languages. Practitioners in need of
powerful computational building blocks have naturally opted to use *other*
programming languages instead.

In the spirit of this history it is widely said that floating-point math 
***cannot*** be done in Bash, but strictly speaking this is not true:

+ "" []

You are invited to try _shellfloat_ on for size and draw your own conclusions!

## How it works
_shellfloat_ splits decimal numbers into their integer and fractional parts,
performs the appropriate integer operations on the parts, and recombines the results.
(In the spirit of Bash, numerical overflow is ignored silently.)

Because if we can get carrying, borrowing, place value, and the distributive
law right, then the sky's the limit! In other words:

        *Ad astra per aspera.*

## And now...
You can run your floating-point computations directly in Bash!

## Please see also:
[A short discussion on arbitrary precision and shellfloat](https://github.com/clarity20/shellfloat/wiki "Shellfloat and arbitrary precision arithmetic")
