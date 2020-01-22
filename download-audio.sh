#!/bin/bash

:<<'README'
Author:         Yamikani Chinamale
Date:           14-Nov-2019
Description:    A script that downloads audio files from a website.
                This version downloads the free audio Bible from Biblica and creates appropriate
                directories per testament, book and chapter.

Disclaimer:     This script is for education purposes only.
                Get permission from websites/owners of audio content before downloading.
                
README

SCRIPTPATH=`cd $(dirname ${0}); pwd -P`
TIMESTAMP=`date "+%d-%m-%Y %H:%M:%S"`
EPOCHTIME=`date +'%s'`

SCRIPTBASE=`basename -s .sh ${0}`
SCRIPTLOG="${SCRIPTPATH}/${SCRIPTBASE}.log"
SCRIPTLOGTEMP="${SCRIPTPATH}/${SCRIPTBASE}_tmp.log"
CONFIG="${SCRIPTPATH}/${SCRIPTBASE}.config"

HASH60="############################################################"
LINE60="------------------------------------------------------------"

# start log
printf "%s\n%s\n" > "${SCRIPTLOG}"
printf "%s\n%s\n" > "${SCRIPTLOGTEMP}"

create_testament() {
    if [[ ! -d "${SCRIPTPATH}/${1}" ]]
    then
        printf "Creating directory %s\n" "${SCRIPTPATH}/${1}" | tee -a ${SCRIPTLOG}
        mkdir "${SCRIPTPATH}/${1}"
    else
        printf "Directory already exists %s\n" "${SCRIPTPATH}/${1}" | tee -a ${SCRIPTLOG}
    fi
}

create_book(){
    testament=${1}
    bookname=`echo "${2}" | awk -F':' '{print $1}' | sed "s,^ *,,g" | sed "s, *$,,g"`
    max_chapters=`echo "${2}" | awk -F':' '{print $2}' | sed "s,^ *,,g" | sed "s, *$,,g"`
    echo "Downloading ${bookname}, ${max_chapters} chapters ..."

    if [[ ! -d "${SCRIPTPATH}/${testament}/${bookname}" ]]
    then
        printf "Creating directory %s\n" "${SCRIPTPATH}/${testament}/${bookname}" | tee -a ${SCRIPTLOG}
        mkdir -p "${SCRIPTPATH}/${testament}/${bookname}"
    else
        printf "Directory already exists %s\n" "${SCRIPTPATH}/${testament}/${bookname}" | tee -a ${SCRIPTLOG}
    fi

    urlbase="https://www.biblica.com/bible/nivuk"

    for chapter in $(seq 1 $max_chapters)
    do 
        urlbook=`echo "${bookname}" | tr '[:upper:]' '[:lower:]' | sed "s, ,-,g"`
        urlpage="${urlbase}/${urlbook}/${chapter}/"
        html=`wget "${urlpage}" -q -O -`

        printf "Downloading %s Chp. %s\n" "${bookname}" "${chapter}"
        # extract audio link from html content
        audiolink=`echo "${html}" | grep -i 'source' | grep -i 'stream' | grep -i .mp3 | awk -F'\"' '{print $2}'`
        wget -nv -c "${audiolink}" -O "${SCRIPTPATH}/${testament}/${bookname}/Chapter_${chapter}.mp3" >> ${SCRIPTLOGTEMP} 2>&1
        
        sleep 3s
    done
}

comment_chp() {
    # add hash to beginning of downloaded chapter
    sed -i "s,${line},#${line},g" ${CONFIG}
}

main() {

    testament=""
    book=""
    chapter=""

    while read -r line
    do
        # handle empty lines & commented lines
        if [[ ${line} == "" ]] || [[ `echo ${line} | grep -i '^#[a-zA-Z0-9]' | wc -l` -gt 0 ]]
        then
            printf "Ignoring: %s\n" "${line}" | tee -a ${SCRIPTLOG}
            continue
        fi

        # handle testaments
        if [[ ${line}  =~ "##" ]]
        then
            testament="${line:2}"
            create_testament "${testament}"

        # handle books
        else
            bookline="${line}"
            create_book "${testament}" "${bookline}"
            comment_chp "${line}"
        fi
    done < ${CONFIG}
}

main ${@}