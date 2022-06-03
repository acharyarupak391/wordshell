#!/bin/bash

# not in word #3a3a3c rgb(58, 58, 60) 8
# correct position #538d4e rgb(83 141 78) 34
# wrong position #b59f3b rgb(181, 159, 59) 172

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

# select only 5-letter words from words.txt and write to out.txt
# grep -E '^.{6}$' words.txt > out.txt

FILE_NAME="new.txt"

# get the path of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FILE_PATH="$DIR/$FILE_NAME"

init_empty_grid

WORD=$(shuf -n 1 $FILE_PATH | tr -dc '[:alpha:]' | tr '[:upper:]' '[:lower:]')

ERROR=""

guess=0
while [ $guess -lt $GUESSES ]
do
    # print title and grid
    print_title
    print_grid
    
    # check if ERROR is not empty
    if [ ! -z "$ERROR" ]; then
        print_8bit_fg $RED " ${bold}${ERROR}${normal}\n"
    fi
    
    read -p " Guess the word: " word
    
    # convert word to lowercase
    word=$(echo $word | tr '[:upper:]' '[:lower:]')
    
    # check if word length is equal to WORD_LENGTH
    if [ ${#word} -ne $WORD_LENGTH ]; then
        ERROR="Word must be a $WORD_LENGTH letter word!"
    elif grep -wq "$word" "$FILE_PATH" || [[ "$word" == "$WORD" ]]
    then
        update_grid $word $guess
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
        
        print_8bit_fg $RED "\n ${bold}Sorry, you lost. The word was '$WORD'${normal}\n"
        break
    fi
    
done


