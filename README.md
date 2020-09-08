# shellfloat
Introducing floating-point arithmetic libraries for the Bash shell, because
they said it couldn't be done... and because:
![image info](./image.png)

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

_Ad astra per aspera_.

## And now...
You can run your computations directly in Bash!

## Please see also:
[A short discussion on arbitrary precision and shellfloat](https://github.com/clarity20/shellfloat/wiki "arbitrary precision and shellfloat")
