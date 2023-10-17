#!/bin/bash
set -eo pipefail

versionJQ='
def handle: .[] | [.version] | sort_by( split(".") | map(tonumber) ) | last ;
def error: "" ;
def process: try handle catch error;
process'

# Based on: https://github.com/fmahnke/shell-semver/blob/master/increment_version.sh
# Increment a version string using Semantic Versioning (SemVer) terminology.
increment_version () {
    # Parse command line options.

    while getopts ":Mmp" Option
    do
    case $Option in
        M ) major=true;;
        m ) minor=true;;
        p ) patch=true;;
    esac
    done

    shift $(($OPTIND - 1))

    version=$1

    # Build array from version string.

    a=( ${version//./ } )

    # If version string is missing or has the wrong number of members, show usage message.

    if [ ${#a[@]} -ne 3 ]
    then
    echo "usage: $(basename $0) [-Mmp] major.minor.patch"
    exit 1
    fi

    # Increment version numbers as requested.

    if [ ! -z $major ]
    then
    ((a[0]++))
    a[1]=0
    a[2]=0
    fi

    if [ ! -z $minor ]
    then
    ((a[1]++))
    a[2]=0
    fi

    if [ ! -z $patch ]
    then
    ((a[2]++))
    fi

    echo "${a[0]}.${a[1]}.${a[2]}"
}

package_helm() {
  local helm_dir=$1

  echo "Packaging chart found in directory $1"

  # get latest version from chartmuseum
  name=$(yq e '.name' $2)
  version=$(curl -s "$CHARTMUSEUM_URL/api/charts/$name" | jq -r "$versionJQ")

  if [ -z $version ]
  then
    version="0.0.0"
  fi

  # increment version
  new_version=$(increment_version -m $version)

  echo "Upgrading $name from $version to $new_version"

  yq e '.version = "'"$new_version"'"' -i $2

  helm package $helm_dir
}

for d in $1/*/Chart.yaml ; do
  helm_dir=$(echo "$d" | sed 's|\(.*\)/.*|\1|')

  echo "Checking diffs for $helm_dir"
  
  git diff --quiet $2 $3 -- $helm_dir || package_helm $helm_dir $d
done

if ls *.tgz 1> /dev/null 2>&1; then
  for file in *.tgz ; do
    echo "Uploading package $file to chartmuseum"

    curl -s -u $CHARTMUSEUM_USERNAME:$CHARTMUSEUM_PASSWORD --data-binary "@$file" "$CHARTMUSEUM_URL/api/charts"
  done

  # cleanup files 
  rm *.tgz
else
  echo "No tgz files found"
fi