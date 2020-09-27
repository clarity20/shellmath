# shellfloat
Introducing floating-point arithmetic libraries for the Bash shell, because
they said it couldn't be done... and because:
![image info](./image.png)

## Quick start guide
For a quick-and-dirty introduction to `shellfloat` run the demo `e_demo.sh` 
with a small whole-number argument, say 15:
```
$ e_demo.sh 15
e = 2.7182818284589936
```
This script uses a few `shellfloat` API calls to calculate the mathematical
constant `e`. Take a look at the script. The APIs are invoked by 
subshelling them and the results are captured into strings using the syntax
familiar to shell programmers:
```
result = $( function_name  argument_1  argument_2 )
```
And you're good to go!

Now run the second demo program, `faster_e_demo.sh`:
```
$ faster_e_demo.sh 15
e = 2.7182818284589936
```
If you're running Windows, you should see a substantial speedup:
```
$ (time e_demo.sh 15) 2>&1 | awk '/real/ {print $2}'
0m0.926s
$ (time faster_e_demo.sh 15) 2>&1 | awk '/real/ {print $2}'
0m0.308s
```
The latter script uses a "trick" to avoid subshelling when making those API 
calls. See the scrip titself for details.

## Usage
```
bash-4.4.29% source path/to/shellfloat.sh
bash-4.4.29% x=3.14159; y=2.718281828
bash-4.4.29% sum=$(_shellfloat_add $x $y)
bash-4.4.29% quotient=$(_shellfloat_divide $x $y)

bash-4.4.29% echo $x + $y = $sum
bash-4.4.29% echo $x / $y = $quotient
```

## How it works
_shellfloat_ splits decimal numbers into their integer and fractional parts,
works with them as if they were integers, and recombines the results.

Because if we can get carrying, borrowing, place value, and the distributive
law right, then the sky's the limit! In other words:

        Ad astra per aspera.

## And now...
You can run your floating-point computations directly in Bash!

## Please see also:
[A short discussion on arbitrary precision and shellfloat](https://github.com/clarity20/shellfloat/wiki "arbitrary precision and shellfloat")
