#!/bin/bash

case $# in
  1)  
    "${0}" "${1}" "${1}"
    ;;  
  2)  
    convert "${1}" +profile '*' "${2}"
    ;;  
  *)  
    echo "Usage:"
    echo "  ${0} image"
    echo "  ${0} image-file target-file"
    ;;  
esac

