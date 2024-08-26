#!/bin/bash

# outputs to _site with the following structure:
# index.yml
# This script is from the stashapp/CommunityScrapers repo https://github.com/stashapp/CommunityScrapers/blob/stable/build_site.sh

# Directory where the repo is cloned
repo_dir=$(pwd)
stable_dir="$repo_dir/stable"

# Ensure the stable directory exists and clear previous outputs
rm -rf "$stable_dir"
mkdir -p "$stable_dir"
> "$stable_dir/index.yml"

buildScraper()
{
    branch=$1

    echo "Processing branch: $branch"

    # Checkout the branch
    git checkout $branch
    git pull origin $branch

    # Get the latest commit hash and date for the branch
    version=$(git log -n 1 --pretty=format:%h)
    updated=$(TZ=UTC0 git log -n 1 --date="format-local:%F %T" --pretty=format:%ad)

    # Create a directory for the output (if not already existing)
    outdir="${repo_dir}/output_${branch}"
    mkdir -p "$outdir"

    # Define the zip file path
    zipfile=$(realpath "$outdir/fanscrape_${branch}.zip")

    # Zip the specific files
    zip -r "$zipfile" fanscrape.py fanscrape.yml requirements.txt

    # Determine the name to use in index.yml
    if [ "$branch" = "main" ]; then
        name="fanscrape"
    else
        name="fanscrape-$branch"
    fi

    # Write to index.yml
    echo "- id: fanscrape
  name: \"$name\"
  version: $version
  date: $updated
  path: $zipfile
  sha256: $(sha256sum "$zipfile" | cut -d' ' -f1)" >> "$outdir"/index.yml

    echo "" >> "$outdir"/index.yml
}

# Get a list of all branches
branches=$(git for-each-ref --format='%(refname:short)' refs/heads/)

# Loop over each branch and process it
for branch in $branches; do
    buildScraper $branch
done

# Print completion message
echo "Zipping complete, and index.yml has been updated for all branches."