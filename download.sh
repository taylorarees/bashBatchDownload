#!/bin/bash

url=$1
dev=false

# Set the URL in development mode
if [ "$dev" = true ]; then
  url="https://objectstorage.us-ashburn-1.oraclecloud.com/p/X2FDHgjV4e9HqHnhsxkajNdP6S-I-onokYIgZ9yOVBmI6LyIXxg1BA-QtfAHwS3A/n/idfa0xm5fax7/b/ps1Test/o/"
fi

# Request URL input if not provided
if [ -z "$url" ]; then
  read -p "Please enter the PAR: " url
fi

# Fetch the JSON from the URL
curlOutput=$(curl -s "$url")

# Check if the output is not empty or null
if [ -n "$curlOutput" ]; then
  # Check if the JSON contains the "objects" property
  if grep -q '"objects":' <<< "$curlOutput"; then
    echo "$curlOutput"

    # Extract folder name from URL
    IFS='/' read -r -a urlParts <<< "$url"
    folderName="${urlParts[${#urlParts[@]} - 3]}"

    # Create parent directory if it doesn't exist
    if [ ! -d "$folderName" ]; then
      mkdir -p "$folderName"
    fi

    # Iterate through each object, create folders, and download files
    while IFS= read -r obj; do
      objName=$(echo "$obj" | sed -n 's/.*"name": "\(.*\)".*/\1/p')
      if [[ "$objName" == */ ]]; then
        fullPath="$folderName/$objName"
        if [ ! -d "$fullPath" ]; then
          mkdir -p "$fullPath"
        fi
      else
        downloadUrl="$url$objName"
        localPath="$folderName/$objName"
        curl -s "$downloadUrl" -o "$localPath"
      fi
    done <<< "$(echo "$curlOutput" | sed -n '/"objects":/,$p' | sed -n '/^ *{/,$p')"
  else
    # Prompt to regenerate PAR if no JSON object detected
    echo "Error: Recreate the PAR with 'Enable Object Listing' enabled and run the script with the new PAR" >&2
    exit 1
  fi
else
  # Error if the URL did not return valid JSON
  echo "Error: The URL did not return valid JSON. Please check the URL and try again." >&2
  exit 1
fi
