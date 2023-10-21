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
  declare helm_dir="$1" chart_path="$2"

  echo "Packaging chart found in directory $helm_dir"

  # get latest version from chartmuseum
  chart_name=$(yq e '.name' "$chart_path")

  if grep -qE "^${helm_dir}\$" vendored-charts; then
    echo "Using version in vendored chart"
  else
    echo "Upgrading $chart_name from $version to $new_version"
    version=$(curl -s "$CHARTMUSEUM_URL/api/charts/$chart_name" | jq -r "$versionJQ")
    if [[ -z "$version" ]]; then
      version="0.0.0"
    fi

    new_version="$(increment_version -m "$version")"
    yq e '.version = "'"$new_version"'"' -i "$chart_path"
  fi

  if [[ "$chart_name" == "ack-chart" ]]; then
    echo "Force setting repository for all dependencies"
    yq e '.dependencies[].repository = env(CHARTMUSEUM_URL)' -i "$chart_path"
    echo "Updating dependencies"
    helm dependency update "$helm_dir"
    echo "Building dependencies"
    helm dependency build "$helm_dir"
  fi
}

failures=0

for chart_path in $1/*/Chart.yaml ; do
  helm_dir=$(echo "$chart_path" | sed 's|\(.*\)/.*|\1|')
  chart_name=$(yq e '.name' "$chart_path")
  must_package=false
  if curl -sS --fail "$CHARTMUSEUM_URL/api/charts/$chart_name"; then
    echo "Checking diffs for $helm_dir"
    git diff --quiet $2 $3 -- "$helm_dir" || must_package=true
  else
    echo "Missing $helm_dir chart in chartmuseum"
    must_package=true
  fi
  if [[ "$must_package" == true ]]; then
    package_helm "$helm_dir" "$chart_path" || {
      echo "Failed to package $helm_dir"
      failures=$((failures+1))
    }
  fi
done

if [[ "$failures" -gt 0 ]]; then
  echo "Failed run due to ${failures} failures"
  exit 1
fi
