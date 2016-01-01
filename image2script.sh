#!/bin/bash

imageFile=$1
outputFile="out.sh"
yOld=0
colorCodeOld=-1
width=100
height=55

imageSize=$(convert $imageFile -format "%w %h" info: | tr -cs '0-9.\n'  ' ')
read -r imageWidth imageHeight <<< "$imageSize"

imageWidthHeightRatio=$(echo "$imageWidth/$imageHeight" | bc -l)
echo "$imageWidthHeightRatio"
#if (( $(echo "$num1 > $num2" |bc -l) )); then
#echo "($RESULT+0.5)/1" | bc 

echo "Creating Script..."

printf "printf \"" > ${outputFile}

convert $imageFile -resize ${width}x${height}\! -depth 8 -colorspace RGB +matte txt:- |
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
