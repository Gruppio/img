#!/bin/bash

# Michele Gruppioni 2016

function usage
{
  cat <<EOF

-------------------------------------
 $0 HELP 
-------------------------------------

$0 Is a tool that allow to display images and gif files in a terminal window.
A unique functionality of $0 is the possibility to export the result as a .sh script that can be run on any other compatible machine.
The output script does not require any dependency or installation.
This allow you to display an image or even an animation every time that you open the terminal or each time that someone ssh your server.

$0 require ImageMagick [ http://www.imagemagick.org ] in order to work 
For install ImageMagick on OSX:
sudo port install ImageMagick
or 
sudo brew install ImageMagick

For install ImageMagick on Ubuntu:
sudo apt-get install imagemagick

For install on other OS please check ImageMagick website [ http://www.imagemagick.org ]

-------------------------------------

Usage: $0 [options] <image/gif file>

  --help                                Print the help

  -o|--output <fileName>                Set the output script file name

  -w|--width <width>                    Set the output image width

  -h|--height <height>                  Set the output image height

  -v|--verbose                          Verbose mode 
  
  -d|--delay <delay>                    Set the delay in seconds between .Gif frames (ex 0.1) 

  -lf|--loop-forever                    The .Gif images will run forever ( works only with the -o option )
  
  -lt|--loop-times <times>              The .Gif images will run <times> times ( works only with the -o option )

  -ncfc|--no-character-form-correction  The output image will not care about the different height/width of the characters form
  
  -ntr|--no-terminal-resize             The terminal window will not be resized to the image dimension

-------------------------------------

Michele Gruppioni 2016

EOF
}

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
      usage
      exit 0
    ;;

    -o|--output)             
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

    -lt|--loop-times)
      loopTimes=$2
      shift
    ;;

    -ncfc|--no-character-form-correction)
      characterFormCorrectionEnabled=0
    ;;

    -ntr|--no-terminal-resize)
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
  touch ${outputFile}
  chmod +x ${outputFile}
fi

# Resize the terminal window size if needed
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

  if [[ $outputFile != "" ]]
  then
    printf "terminalWidth=\$(tput cols)\nterminalHeight=\$(tput lines)\nprintf \"${resizeTerminalCommand}\"" >> ${outputFile}
  else
    printf "${resizeTerminalCommand}"
  fi
fi


# If is a gif print all the frames
fileLowercase=$(echo "$imageFile" | awk '{print tolower($0)}')
if [[ $fileLowercase == *.gif ]]
then

  if [[ $verbose == 1 ]]
  then
    echo "Analyizing Gif frames..."
  fi

  if [[ $outputFile != "" ]]
  then
    if [[ $loopForever == 1 ]]
    then
      printf "\nwhile : \ndo" >> ${outputFile}
    else
      printf "\nfor (( i=0; i<${loopTimes}; i++ ))\ndo" >> ${outputFile}
    fi
  fi

  mkdir ${framesFolder}
  convert ${imageFile} -coalesce ${framesFolder}/${framesName}%d.jpg
  framesCount=$(convert ${imageFile} -format "%n" info:| tail -n 1)
  for (( i=0; i<$framesCount; i++ ))
  do
    if [[ $verbose == 1 ]]
    then
      echo "Analyizing frame ${i}/${framesCount}"
    fi

    frameFile="${framesFolder}/${framesName}${i}.jpg"
    drawImageCommand=$(imageToCommand "${frameFile}" "${resizeOption}" "${sampleOption}")
    rm ${frameFile}

    if [[ $outputFile != "" ]]
    then
      printf "\nsleep ${delay}\nclear\n printf \"${drawImageCommand}\"" >> ${outputFile}
    else
      clear
      printf "${drawImageCommand}"
    fi
  done
  rmdir ${framesFolder}

  if [[ $outputFile != "" ]]
  then
      printf "\ndone" >> ${outputFile}
  fi

else

  if [[ $verbose == 1 ]]
  then
    echo "Analyizing Image..."
  fi

  drawImageCommand=$(imageToCommand "${imageFile}" "${resizeOption}" "${sampleOption}")

  if [[ $outputFile != "" ]]
  then
    printf "clear\n printf \"${drawImageCommand}\"" >> ${outputFile}
  else
    #clear
    printf "${drawImageCommand}"
  fi

fi

# Restore the terminal window size if needed
if [[ $terminalResizeEnabled == 1 ]]
then
  if [[ $outputFile != "" ]]
  then
    restoreTerminalCommand="\033[8;\${terminalHeight};\${terminalWidth}t"
    printf "\nprintf \"${restoreTerminalCommand}\"" >> ${outputFile}
  fi
fi

exit 0


