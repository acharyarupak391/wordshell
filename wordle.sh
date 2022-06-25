#!/bin/bash

WORD_LENGTH=5
GUESSES=6

# get bold character sequence
bold=$(tput bold)
normal=$(tput sgr0)

# define a hash table
declare -A GRID

# color codes
NO_MATCH=238
MATCH=34
WRONG_POSITION=172
RED=196
GREEN=82
PURPLE=51
CYAN=36
YELLOW=33

# print with 8-bit foreground color
function print_8bit_fg {
    # printf "\e[38;5;%sm %s \e[0m" "$1" "$2"
    printf "\e[38;5;%sm $2 \e[0m" "$1"
}

# print with 8-bit background color
function print_8bit_bg {
    printf "\033[48;5;%sm $2 \033[0m" "$1"
}

function contains_element {
    local item="$1"
    shift
    local arr=("$@")
    
    if [[ "${arr[*]}" =~ "${item}" ]]; then
        echo "true"
    fi
    
    if [[ ! "${arr[*]}" =~ "${item}" ]]; then
        echo "false"
    fi
}

function get_index {
    local item="$1"
    shift
    local arr=("$@")
    
    for i in "${!arr[@]}"; do
        if [[ "${arr[$i]}" == "${item}" ]]; then
            echo "$i"
        fi
    done
}

function get_index_of_substring {
    local string="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    local substring="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
    local index=0
    
    while [[ "${string:$index:${#substring}}" != "${substring}" ]]; do
        index=$((index+1))
        
        # break if index is greater than string length
        if [[ $index -gt ${#string} ]]; then
            index=""
            break
        fi
    done
    
    echo "$index"
}

function print_word {
    local word="$1"
    shift
    local color_array=("$@")
    for (( i=0; i<$WORD_LENGTH; i++ )); do
        local LETTER="${word:i:1}"
        print_8bit_bg "${color_array[i]}" "$LETTER"
        printf " "
    done
    printf "\n"
}

function print_empty_grid {
    # print empty grid
    for (( i=0; i<$GUESSES; i++ )); do
        for (( j=0; j<$WORD_LENGTH; j++ )); do
            print_8bit_bg 238 " "
            printf " "
        done
        printf "\n\n"
    done
}


function print_title {
    printf "\n\t\t\t"
    local title="WORDSHELL"
    # loop through each character of the title
    for (( i=0; i<${#title}; i++ )); do
        local letter="${title:i:1}"
        print_8bit_bg $MATCH "${bold}$letter"
        printf " "
    done
    printf "${normal}\n\n\n"
}

function update_grid_new {
    local word="$1"
    local row="$2"
    
    local -A accepted_indexes;
    for (( i=0; i<$WORD_LENGTH; i++ )); do
        local -a val=()
        if [[ "${word:i:1}" == "${WORD:i:1}" ]]; then
            accepted_indexes["$i"]="true"
            val[0]=$MATCH
        else
            accepted_indexes["$i"]="false"
            val[0]=$NO_MATCH
        fi
        val[1]=$(echo ${word:i:1}  | tr '[:lower:]' '[:upper:]')
        GRID["$row,$i"]="${val[@]}"
    done
    
    # prinf accepted indexes hash table
    for key in "${!accepted_indexes[@]}"; do
        echo "$key -> ${accepted_indexes[$key]}"
        printf "\n"
    done
    
    # print grid
    for (( j=0; j<$WORD_LENGTH; j++ )); do
        local arr="${GRID["$row,$j"]}"
        printf "$j: $arr\n"
    done
    
    printf "\n"
    
    for (( i=0; i<$WORD_LENGTH; i++ )); do
        # check if index is in accepted_indexes
        if [[ "${accepted_indexes[$i]}" == "true" ]]
        then
            continue
        fi
        
        local -a val=()
        
        # chec if letter is not in WORD
        local index=$(get_index_of_substring "${WORD}" "${word:i:1}")
        if [[ ! -n "$index" ]]
        then
            val[0]=$NO_MATCH
        elif [[ -n "$index" ]] && [[ "${accepted_indexes[$i]}" == "false" ]]
        then
            accepted_indexes["$index"]="true"
            val[0]=$WRONG_POSITION
        else
            val[0]=$NO_MATCH
        fi
        
        val[1]=$(echo ${word:i:1}  | tr '[:lower:]' '[:upper:]')
        GRID["$row,$i"]="${val[@]}"
    done
    
}

function update_grid {
    local word="$1"
    local row="$2"
    
    for (( i=0; i<$WORD_LENGTH; i++ )); do
        local -a val=()
        
        if [[ "${word:i:1}" == "${WORD:i:1}" ]]; then
            val[0]=$MATCH
            
            elif [[ $WORD == *"${word:i:1}"* ]]; then
            val[0]=$WRONG_POSITION
            
        else
            val[0]=$NO_MATCH
        fi
        
        val[1]=$(echo ${word:i:1}  | tr '[:lower:]' '[:upper:]')
        GRID["$row,$i"]="${val[@]}"
    done
    
}

function print_grid {
    for (( i=0; i<$GUESSES; i++ )); do
        printf " "
        for (( j=0; j<$WORD_LENGTH; j++ )); do
            local letter="${GRID["$i,$j"]}"
            # printf "$i $j => ${GRID["$i,$j"]}\n"
            print_8bit_bg ${letter[0]} "${bold}${letter[1]}"
            printf " "
        done
        printf "\n\n"
    done
    printf "${normal}"
}

function init_empty_grid {
    for (( i=0; i<$GUESSES; i++ )); do
        for (( j=0; j<$WORD_LENGTH; j++ )); do
            local -a val=()
            val[0]=$NO_MATCH
            val[1]="-"
            GRID["$i,$j"]="${val[@]}"
        done
    done
}

COMMON_FILE_NAME="data/common.txt"
VALID_FILE_NAME="data/valid.txt"

# get the path of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COMMON_FILE_PATH="$DIR/$COMMON_FILE_NAME"
VALID_FILE_PATH="$DIR/$VALID_FILE_NAME"

init_empty_grid

WORD=$(shuf -n 1 $COMMON_FILE_PATH | tr -dc '[:alpha:]' | tr '[:upper:]' '[:lower:]')
WORD="crane"

update_grid_new "drama" 0
exit

ERROR=""

guess=0
while [ $guess -lt $GUESSES ]
do
    # print title and grid
    print_title
    print_grid
    
    # check if ERROR is not empty
    if [ ! -z "$ERROR" ]; then
        print_8bit_fg $RED "${bold}${ERROR}${normal}\n"
    else
        printf " "
    fi
    
    read -p "Guess the word: " word
    
    # convert word to lowercase
    word=$(echo $word | tr '[:upper:]' '[:lower:]')
    
    # check if word length is equal to WORD_LENGTH
    if [ ${#word} -ne $WORD_LENGTH ]; then
        ERROR="Word must be a $WORD_LENGTH letter word!"
    elif grep -wq "$word" "$COMMON_FILE_PATH" || grep -wq "$word" "$VALID_FILE_PATH" || [[ "$word" == "$WORD" ]]
    then
        update_grid_new $word $guess
        # update_grid $word $guess
        guess=$((guess+1))
        ERROR=""
    else
        ERROR="'$word' is not in the dictionary"
    fi
    
    # clear the terminal
    echo $(clear)
    
    # check if word is correct
    if [[ "$word" == "$WORD" ]]; then
        # print title and grid
        print_title
        print_grid
        
        print_8bit_fg $GREEN "\n ${bold}Congratulations! You guessed the word!${normal}\n"
        break
        
        elif [ $guess -eq $GUESSES ]; then
        # print title and grid
        print_title
        print_grid
        
        print_8bit_fg $RED "\n ${bold}Oops, you lost. The word was '$WORD'${normal}\n"
        break
    fi
    
done


