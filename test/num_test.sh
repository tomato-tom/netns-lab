#!/bin/bash


count=3
if [[ $1 =~ ^[0-9]+$ ]]; then
    count=$1
fi

echo $count


num=3
if [[ $num =~ ^[0-9]{1,3}$ ]]; then
    if [[ $num < 255 ]]; then
        echo $num
    else
        echo "not mach"
    fi
else
    echo "not mach"
fi

num=00004.89
if [ $num -gt 0 ] && [ $num -lt 255 ]; then
    count=$(( 10#${num} ))
	echo $count
else
	echo not match
fi


num=0
if [[ $num =~ ^[0-9]{1,3}$ ]]; then
    if [ $num -lt 255 ]; then
        count=$(( 10#${num} ))
        echo $count
    else
        echo "not mach"
    fi
else
    echo "not mach"
fi
