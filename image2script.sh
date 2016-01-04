#!/bin/bash
imageFile=""
outputFile="out.sh"
terminalWidth=$(tput cols)
terminalHeight=$(tput lines)
outputWidth=-1
outputHeight=-1
characterWidthHeightRatio=0.5

yOld=0
colorCodeOld=-1
resizeOption=""

while (( "$#" ))
do
  case $1 in
    -h|--help)  
      echo "Help"
      exit 0
    ;;

    -o)             
      outputFile=$2
      shift 
    ;;

    -w|--width)     
      outputWidth=$2
      shift 
    ;;

    -h|--height)     
      outputHeight=$2
      shift 
    ;;

    *) imageFile=$1 ;;

  esac
  shift
done

if [[ $imageFile == "" ]]
then
  echo "Error Missing Image"
  exit -1
fi

# Main

echo "Creating Script..."

# Read Image width ang Image Height
imageSize=$(convert $imageFile -format "%w %h" info: | tr -cs '0-9.\n'  ' ')
read -r imageWidth imageHeight <<< "$imageSize"

# Resize the image to desired size if specified

# Resize by adapting the ImageWidth to OutputWidth
if [[ $outputWidth == -1 && $outputHeight == -1 ]]
then 
  widthScaleRatio=$(echo "$outputWidth/$imageWidth" | bc -l)
  heightFloat=$(echo "$imageHeight*$widthScaleRatio*$characterWidthHeightRatio" | bc -l)
  outputHeight=$(echo "($heightFloat+0.5)/1" | bc)
  resizeOption="-resize ${outputWidth}x${outputHeight}!"
elif [[ $outputWidth == -1 ]]
then
  resizeOption="-resize x${outputHeight}"
elif [[ $outputHeight == -1 ]]
then
  resizeOption="-resize ${outputWidth}"
else
  resizeOption="-resize ${outputWidth}x${outputHeight}!"
fi

printf "printf \"" > ${outputFile}

convert $imageFile ${resizeOption} -sample 100x50%\! -depth 8 -colorspace RGB +matte txt:- |
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


exit 0
