#!/bin/bash

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

  # parse chart.yaml and increment version
  version=$(yq e '.version' $2)

  # increment version
  new_version=$(increment_version -m $version)

  yq e '.version = "'"$new_version"'"' -i $2

  helm package $helm_dir
}

for d in */*/Chart.yaml ; do
  helm_dir=$(echo "$d" | sed 's|\(.*\)/.*|\1|')
  
  echo $helm_dir $d

  git diff --quiet $1 $2 -- $helm_dir || package_helm $helm_dir $d
done

for file in *.tgz ; do
  curl -u $CHARTMUSEUM_USERNAME:$CHARTMUSEUM_PASSWORD --data-binary "@$file" "$CHARTMUSEUM_URL/api/charts"
done

# cleanup files 
rm *.tgz