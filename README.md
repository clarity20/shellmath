# shellfloat
Introducing floating-point arithmetic libraries for the Bash shell, because
they said it couldn't be done -- and because:
![image info](./image.png)

## Usage
```
source path/to/shellfloat.sh
x=3.14159; y=2.718281828
sum=$(_shellfloat_add $x $y)
quotient=$(_shellfloat_divide myQuotient $x $y)

echo $x + $y = $sum
echo $x / $y = $quotient
```

## How it works
_shellfloat_ splits decimal numbers into their integer and fractional parts,
works with them as if they were integers, and recombines the results.

Because if we can get carrying, borrowing, place value, and the distributive
law right, then the sky's the limit! In other words:

_ad astra per aspera_.

## And now...
You can run your computations directly in Bash!

