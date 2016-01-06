#!/bin/bash

# Michele Gruppioni 2016

function imageToCommand
{
  imageFile=$1
  resizeOption=$2
  sampleOption=$3

  yOld=0
  colorCodeOld=-1

  convert ${imageFile} ${resizeOption} ${sampleOption} -depth 8 -colorspace RGB +matte txt:- |
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
      done

  printf "\033[0m\n"
}

function isAGif
{
  fileLowercase=$(echo "$1" | awk '{print tolower($0)}')
  if [[ $fileLowercase == *.gif ]]
  then
    echo 1
  else
    echo 0
  fi
}


imageFile=""
outputFile=""
outputWidth=-1
outputHeight=-1
characterWidthHeightRatio=50
characterFormCorrectionEnabled=1
terminalResizeEnabled=1
verbose=0
resizeOption=""
sampleOption=""
delay=0.2
loopForever=0
loopTimes=1
framesFolder="frames"
framesName="frame_"

terminalWidth=$(tput cols)
terminalHeight=$(tput lines)
terminalDoubleHeight=$(($terminalHeight*2))

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
      outputHeight=$(($2*2))
      shift 
    ;;

    -v|--verbose)
      verbose=1
    ;;

    -d|--delay)
      delay=$2
      shift
    ;;

    -lf|--loop-forever)
      loopForever=1
    ;;

    -ln|--loop-times)
      loopTimes=$2
      shift
    ;;

    --disable-character-form-correction)
      characterFormCorrectionEnabled=0
    ;;

    --disable-terminal-resize)
      terminalResizeEnabled=0
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

if [[ $verbose == 1 ]]
then
  echo "Creating Terminal Image..."
fi

# Read Image width ang Image Height
imageSize=$(convert $imageFile -format "%w %h" info: | tr -cs '0-9.\n'  ' ')
read -r imageWidth imageHeight <<< "$imageSize"

# Resize the image to desired size if specified otherwise by adapting the ImageWidth to OutputWidth
if [[ $outputWidth == -1 && $outputHeight == -1 ]]
then 

  imageRectRatio=$(echo "$imageWidth/$imageHeight" | bc -l)
  terminalRectRatio=$(echo "$terminalWidth/$terminalDoubleHeight" | bc -l)
  #echo "$imageRectRatio - $terminalRectRatio"
  if (( $(echo $imageRectRatio'>'$terminalRectRatio | bc -l) ))
  then 
    outputWidth=$terminalWidth
    resizeOption="-resize ${outputWidth}"
  else
    outputHeight=$(($terminalDoubleHeight))
    resizeOption="-resize x${outputHeight}"
  fi
  
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

# If the ouptut is to a file create it
if [[ $outputFile != "" ]]
then
  printf "" > ${outputFile}
fi

resizeTerminalCommand=""
if [[ $terminalResizeEnabled == 1 ]]
then
  if [[ $outputWidth != -1 ]]
  then
    terminalWidth=$outputWidth
  fi

  if [[ $outputHeight != -1 ]]
  then
    terminalHeight=$outputHeight
  fi

  resizeTerminalCommand="\033[8;${terminalHeight};${terminalWidth}t"
fi

drawImageCommand=""
drawImageCommand+=$(imageToCommand "${imageFile}" "${resizeOption}" "${sampleOption}")

if [[ $outputFile != "" ]]
then
  printf "clear\n printf \"${drawImageCommand}\"" > ${outputFile}
else
  clear
  printf "${drawImageCommand}"
fi

# If is a gif print all the frames
isGif=$(isAGif $imageFile)
if [[ $isGif == 1 ]]
then
  mkdir frames
  convert ${imageFile} -coalesce frames/frame_%d.jpg
  rm frames/frame_0.jpg
  framesCount=$(convert ${imageFile} -format "%n" info:| tail -n 1)
  for (( i=1; i<$framesCount; i++ ))
  do
    if [[ $verbose == 1 ]]
    then
      echo "Analyizing frame ${i}/${framesCount}"
    fi

    frame="frames/frame_${i}.jpg"
    drawImageCommand=$(imageToCommand "${frame}" "${resizeOption}" "${sampleOption}")
    rm "frames/frame_${i}.jpg"
    if [[ $outputFile != "" ]]
    then
      printf "\nsleep 0.2\nclear\n printf \"${drawImageCommand}\"" >> ${outputFile}
    else
      clear
      printf "${drawImageCommand}"
    fi

  done
  rmdir frames
fi

exit 0


