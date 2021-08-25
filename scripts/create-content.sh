#!/bin/bash

########################
### Helper functions ###
########################

# These function must be declared first, otherwise bash won't recognize them

#TODO: add logic for when a certain file is not found
function expand_configuration_files () {
  echo "Start expanding the configuration files"

  mkdir -p "$ROOTDIR/$SOURCEDIR"

  for directory in $SOURCE_DIRECTORIES
  do
    local CONFIG_FILE=$(find $SOURCEDIR/$directory -type f -name "*.json")
    local SOURCE_NAME=$(jq -r .naam "$CONFIG_FILE")   #TODO: add logic for when property 'naam' is not present --> take name of the directory
    local DESCRIPTION_FILE=$(find "$SOURCEDIR/$directory/beschrijving" -type f -name "*.md")
    local NORMALIZED_SOURCE_NAME=$(echo $SOURCE_NAME | tr -dc '[:alnum:]\n\r ' | tr ' ' '-' | tr [:upper:] [:lower:])

    mkdir -p "$ROOTDIR/$SOURCEDIR/$NORMALIZED_SOURCE_NAME"

    #TODO: expand document names in configuration file

    cp "$CONFIG_FILE" "$ROOTDIR/$SOURCEDIR/$NORMALIZED_SOURCE_NAME/$NORMALIZED_SOURCE_NAME.json"
    cp "$DESCPRIPTION_FILE" "$ROOTDIR/$SOURCEDIR/$NORMALIZED_SOURCE_NAME/description.md"
  done

  echo "Done expanding and copying configuration files."
}

# TODO: extract only directories in 'bronnen' and no duplicates
function get_changed_source_directories () {
  echo "Extracting only the directories that were changed."

  local ALL_DIRECTORIES=()
  for file in $CHANGED_FILES
  do
    IFS='/ ' read -r -a path <<< "$file"
    [[ ${path[0]} == 'bronnen' ]] && ALL_DIRECTORIES+=("${path[1]}")
  done

  SOURCE_DIRECTORIES=($(printf "%s\n" "${ALL_DIRECTORIES[@]}" | sort -u | tr '\n' ' '))
}

function get_all_source_directories () {
  echo "Extracting all directories."

  local ALL_DIRECTORIES=()
  for directory in $(ls -d bronnen/*)
  do
    IFS='/ ' read -r -a path <<< "$directory"
    ALL_DIRECTORIES+=("${path[1]}")
  done
  
  SOURCE_DIRECTORIES=($(printf "%s\n" "${ALL_DIRECTORIES[@]}" | sort -u | tr '\n' ' '))
}

###################
### Script code ###
###################

ROOTDIR=$1
REPOSITORY_NAME=$2
SOURCEDIR='bronnen'

mkdir -p "$ROOTDIR"

declare -ga SOURCE_DIRECTORIES

#TODO: change this function to use curl and fetch commit hash from git repository of website
jq -n '{commit: "50c12dc7ed94a594de08db00ad75284d3db73eb7"}' > "$ROOTDIR/commit.json"

jq . "$ROOTDIR/commit.json"
if [ $? -eq 0 ]; then
  PREV_COMMIT=$(jq -r .commit "$ROOTDIR/commit.json")
  CHANGED_FILES=$(git diff --name-only "$PREV_COMMIT")

  OTHER_FOLDERS_CHANGED="false"
  for file in $CHANGED_FILES
  do
    [[ $file =~ bronnen\/[a-zA-Z/.]* ]] || { echo "Found a file that was added in other directory than 'bronnen'"; OTHER_FOLDERS_CHANGED="true"; }
  done

  [[ $OTHER_FOLDERS_CHANGED == "true" ]] && get_all_source_directories || get_changed_source_directories

else
  echo "No previous commit hash was found. All directories will be processed."
  get_all_source_directories
fi

expand_configuration_files

