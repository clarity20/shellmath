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
constant `e`. Now take a look at the script. The APIs are exercised using 
the familiar shell-function syntax:
```
result = $(function_name  argument_1  argument_2)
```

Now run the second demo program, `faster_e_demo.sh`:
```
$ faster_e_demo.sh 15
e = 2.7182818284589936
```

This is a faster version of the same script. If you're running Cygwin or minGW
over Windows, the speedup will be quite substantial; here are my timings. And
keep in mind that each encompasses ***31*** calls to the `shellfloat` arithmetic
APIs plus a few other commands:
```
$ ####  __Before:__  ####
$ (time e_demo.sh 15) 2>&1 | awk '/real/ {print $2}'
0m0.598s
$
$ ####  __After:__  ####
$ (time faster_e_demo.sh 15) 2>&1 | awk '/real/ {print $2}'
0m0.122s
```

This script uses a "trick" to avoid subshelling when making those API 
calls. See the script itself for details.

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
[A short discussion on arbitrary precision and shellfloat](https://github.com/clarity20/shellfloat/wiki "arbitrary precision and shellfloat")
