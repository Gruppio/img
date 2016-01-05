#!/bin/bash



function hasExtension
{
  fileLowercase=$(echo "$1" | awk '{print tolower($0)}')
  extensionLowercase=$(echo "$1" | awk '{print tolower($0)}')
  if [[ $fileLowercase == *.txt ]]
  then
    echo 1
  else
    echo 0
  fi
}

hasExtension "asa.txt" "txt"