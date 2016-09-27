#!/usr/bin/env bash
function get_unpacked_name(){
    filename=$1
    extension="${filename##*.}"
    while true
    do
        if [[ ${extension} != "tar" && ${extension} != "gz" && ${extension} != "bz2" && ${extension} != "xz" ]]
        then
            echo "${filename}"
            return 0
        else
            filename="${filename%.*}"
            extension="${filename##*.}"
        fi
    done
}

echo `get_unpacked_name mysql-5.7.15-linux-glibc2.5-x86_64.tar.gz`