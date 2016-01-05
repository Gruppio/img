#!/bin/bash

function imageToCommand
{
  imageFile=$1
  resizeOption=$2
  sampleOption=$3

  yOld=0
  colorCodeOld=-1

  convert $imageFile ${resizeOption} ${sampleOption} -depth 8 -colorspace RGB +matte txt:- |
    tail -n +2 | tr -cs '0-9.\n'  ' ' |
      while read x y r g b junk; do

        if [[ $y != $yOld ]]
        then 
          printf "\033[0m\n"
          yOld=$y
          colorCodeOld=-1
        fi

        r=$(($r/51))
        g=$(($g/51))
        b=$(($b/51))
        colorCode=$((16 + (36 * $r) + (6 * $g) + $b))

        if [[ $colorCode == $colorCodeOld ]]
        then
            printf " "
        else
            printf "\033[48;5;${colorCode}m "
        fi

        colorCodeOld=$colorCode
        #echo "$x,$y = rgb($r,$g,$b)"
      done

  printf "\033[0m\n"
}


imageFile=""
outputFile=""
outputWidth=-1
outputHeight=-1
characterWidthHeightRatio=50
characterFormCorrectionEnabled=1
verbose=1
resizeOption=""
sampleOption=""

while (( "$#" ))
do
  case $1 in
    --help)  
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

    --disable-character-form-correction)
      characterFormCorrectionEnabled=0
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

# Resize the image to desired size if specified otherwise by adapting the ImageWidth to OutputWidth
if [[ $outputWidth == -1 && $outputHeight == -1 ]]
then 
  outputWidth=$(tput cols) # Terminal Width
  resizeOption="-resize ${outputWidth}"
elif [[ $outputWidth != -1 && $outputHeight == -1 ]]
then
  resizeOption="-resize ${outputWidth}"
elif [[ $outputWidth == -1 && $outputHeight != -1 ]]
then
  resizeOption="-resize x${outputHeight}"
else
  resizeOption="-resize ${outputWidth}x${outputHeight}!"
fi


if [[ $characterFormCorrectionEnabled == 1 ]]
then 
  sampleOption="-sample 100x${characterWidthHeightRatio}%!"
fi

# Resize the r
#printf '\e[8;50;100t' 

drawImageCommand=$(imageToCommand "${imageFile}" "${resizeOption}" "${sampleOption}")

if [[ $outputFile != "" ]]
then
  printf "${drawImageCommand}" >> ${outputFile}
else
  printf "${drawImageCommand}"
fi



#printf "printf \"" > ${outputFile}

  
  #printf "$drawImageCommand" > aaa.txt

echo "Done"



exit 0


