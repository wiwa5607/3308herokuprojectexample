#!/bin/bash
COMMAND="FALSE"
DOC="FALSE"
INSTALL="FALSE"
DOCS="FALSE"
TEST="FALSE"
RSYNC="FALSE"
POSITIONAL=()
if [[ $# -eq 0 ]] ; then
    echo 'Usage: -options'
    echo -e 'Options:\n -i -> executable generation,\n -d -> documentation generation,\n -t -> unit testing,\n -e -> execute python script,\n -dox -> Doxygen documentation (deprecated),\n -s -> rsync with server to update files'
    exit 0
fi
while [[ $# -gt 0 ]]
do
    key="$1"
    
    case $key in
        -e|--execute)
            COMMAND="TRUE"
            shift # past argument
        ;;
        -dox|--doxygen)
            DOC="TRUE"
            shift
        ;;
        -i|--install)
            INSTALL="TRUE"
            shift
        ;;
        -d|--documentation)
            DOCS="TRUE"
            shift
        ;;
        -t|--test)
            TEST="TRUE"
            shift
        ;;
        -s|--sync)
            RSYNC="TRUE"
            shift
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ $TEST = "TRUE" ]
then   
    cd dynamic_commands/tests
    echo "Starting Testing"
    (OUTPUT=$(pytest test.py -rak)
    
    if [ $? != 0 ]
    then 
        echo "$OUTPUT" > test.log
        echo "Testing Failed. Output written to test.log"
    else
        echo "Success"
    fi 
    ) &
    cd ..
    cd ..
fi

if [ $DOC = "TRUE" ] 
then
    cd dynamic_commands
    doxygen doxygen/Doxyfile
    cd doxygen/latex
    make
    cd ..
    cd ..
    cd ..
    touch dynamic_commands/documentation.pdf
    cp dynamic_commands/doxygen/latex/refman.pdf dynamic_commands/documentation.pdf
fi

if [ $INSTALL = "TRUE" ]
then
    cd dynamic_commands
    pyinstaller --distpath ./executable/dist/ --workpath ./executable/build/ -F --specpath ./executable/ -n smartOBD main.py 
    cd ..
    cp dynamic_commands/executable/dist/smartOBD dynamic_commands/smartOBDexecutable
    cp dynamic_commands/smartOBDexecutable SmartOBD/nodejs/views/pages/downloads/smartOBDexecutable
fi


if [ $COMMAND = "TRUE" ]
then
    sudo python dynamic_commands/main.py
fi

if [ $DOCS = "TRUE" ]
then
    cd dynamic_commands/docs
    make html
    make latexpdf
    cd ..
    cd ..
    cp dynamic_commands/docs/build/latex/smartOBD.pdf dynamic_commands/documentation.pdf
fi

while true; do
    echo "Waiting for all jobs to complete"
    wait -n || exit 1          # if one of the background jobs failed, abort
    [[ "$(jobs)" ]] && { echo "Done"; break; }   # exit this loop if no more jobs
done