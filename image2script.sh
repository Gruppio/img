#!/bin/bash

outputFile="out.sh"
heightWidthRatio=2
yOld=0
colorCodeOld=-1
width=100
height=50


echo "Creating Script..."

printf "printf \"" > ${outputFile}

convert $1 -resize ${width}x${height}\! -depth 8 -colorspace RGB +matte txt:- |
    tail -n +2 | tr -cs '0-9.\n'  ' ' |
      while read x y r g b junk; do

      	if [[ $y != $yOld ]]
      	then 
      		printf "\033[0m\n" >> ${outputFile}
      		yOld=$y
            colorCodeOld=-1
      	fi

      	r=$(($r/51))
		g=$(($g/51))
		b=$(($b/51))
		colorCode=$((16 + (36 * $r) + (6 * $g) + $b))

        if [[ $colorCode == $colorCodeOld ]]
        then
            printf " " >> ${outputFile}
        else
            printf "\033[48;5;${colorCode}m " >> ${outputFile}
        fi

        colorCodeOld=$colorCode
        #echo "$x,$y = rgb($r,$g,$b)"
      done

printf "\033[0m\n\"" >> ${outputFile}
