#!/bin/bash

imageFile=$1
outputFile="out.sh"
terminalWidth=$(tput cols)
terminalHeight=$(tput lines)
outputWidth=$terminalWidth
outputHeight=$((terminalHeight / 2))
#characterWidthHeightRatio=0.5

yOld=0
colorCodeOld=-1

# Read Image width ang Image Height
imageSize=$(convert $imageFile -format "%w %h" info: | tr -cs '0-9.\n'  ' ')
read -r imageWidth imageHeight <<< "$imageSize"

#imageWidthHeightRatio=$(echo "$imageWidth/$imageHeight" | bc -l)

resizeOption=""

# Resize by adapting the ImageWidth to OutputWidth
widthScaleRatio=$(echo "$outputWidth/$imageWidth" | bc -l)
heightFloat=$(echo "imageHeight * $widthScaleRatio" | bc -l)
height=$(echo "($heightFloat+0.5)/1" | bc -l)

echo "$height"

#if (( $width > $height ))
#then
#  height=$outputHeight
#  widthFloat=$(echo "$height * $widthRatio" | bc -l)
#  width=
#  resizeOption="-resize x${outputHeight}"
#else
#  resizeOption="-resize ${outputWidth}"
#fi

echo "$resizeOption"

#echo "W: $widthRatio, h: $heightRatio"

#if (( $(echo "$num1 > $num2" |bc -l) )); then
#echo "($RESULT+0.5)/1" | bc 


# -resize ${width}x${height}\!


echo "Creating Script..."

printf "printf \"" > ${outputFile}

convert $imageFile ${resizeOption} -depth 8 -colorspace RGB +matte txt:- |
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
