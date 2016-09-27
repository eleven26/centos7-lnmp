#!/usr/bin/env bash
function get_unpacked_name(){
    filename=$1
    while true
    do
        extension="${filename##*.}"
        filename="${filename%.*}"
        if [[ ${extension} != "tar" && ${extension} != "gz" && ${extension} != "bz2" && ${extension} != "xz" ]]
        then
            echo "${filename}"
            return 0
        else
            extension="${filename##*.}"
            if [[ ${extension} == ${filename} ]]
            then
                echo "${filename}"
                return 0
            fi
        fi
    done
}
