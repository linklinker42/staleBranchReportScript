#!/bin/sh
set -e

################################################################################
#	Name: staleBranchReport.sh
#	Purpose: This script generates a report listing branches that have not been 
#	merged into master and their last commit is older than 30 days. This script 
#	can run against one or many repositories.
#	Usage: The script requires a repository url or a text file with a list of urls.
#	A working directory can also be specified but if one isn't then it defaults to
#	the current directory.
#	Overview of steps:
#		1. Creates a 'staleBranchReport' folder to output the report to and to temporarily
#			store the git projects.
#		2. Perform git clone and then check for stale branches.
################################################################################

main() {
SCRIPTNAME="staleBranchReport"
WORKING_FOLDER="staleBranchReport"
USAGE="Usage: $SCRIPTNAME -u repo_url || -l repo_list_file [ -w working_directory ]"

while getopts "u:l:w:" opt; do
	case $opt in
		u ) repo_url=$OPTARG;;
		l ) repo_list_file=$OPTARG;;
		w ) working_directory=$OPTARG;;
		\?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
		: ) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
		* ) echo "Unimplimented option: -$OPTARG" >&2; exit 1;;
	esac
done

if [ -z "$repo_url" ] && [ -z "$repo_list_file" ]; then
	echo "Error: The repository url must be specified" >&2
	echo "	$USAGE" >&2
	exit 1
fi

if [ ! -z "$repo_url" ] && [ ! -z "$repo_list_file" ]; then
	echo "Error: Only the repository url or a repository list file should be provided" >&2
	echo "	$USAGE" >&2
	exit 1
fi

current_date=`date --iso-8601='hours'`
report_name=repo-report-$current_date

echo
echo "Defining defaults"
if [ -z "$working_directory" ]; then
	echo
	echo "Working directory not specified."
	echo "Using \"$PWD\""
	working_directory=$PWD
fi

BASE_DIR=$working_directory/$WORKING_FOLDER
REPO_DIR=$BASE_DIR/repo

if [ ! -d "$BASE_DIR" ]; then
	mkdir -p $BASE_DIR
fi

report_file=$BASE_DIR/$report_name.txt

if [ ! -z "$repo_list_file" ] && [ ! -f "$repo_list_file" ]; then
	echo "Error: Repo list file not found." >&2
	exit 1
fi

echo
echo "BitBucket Stale Branch Report" | tee -a $report_file
echo "Report date: $current_date" | tee -a $report_file
echo "Begin..." | tee -a $report_file
echo

if [ ! -z "$repo_list_file" ]; then
	while read p; do
		if [ ! -z "$p" ]; then
			checkRepo $p
		fi
	done < $repo_list_file
else
	checkRepo $repo_url
fi

echo "...End" | tee -a $report_file
}

checkRepo() {
repo_url=$1

project_key=$(echo $repo_url | cut -d'/' -f4)
repo_name=$(echo $repo_url | cut -d'/' -f5 | cut -d'.' -f1)

echo "Checking $project_key/$repo_name"
echo
echo "Project: $project_key/$repo_name" >> $report_file

if [ -d "$REPO_DIR" ]; then
	rm -rf $REPO_DIR
fi

mkdir -p $REPO_DIR
cd $REPO_DIR

git clone $repo_url . --no-checkout

for branch in `git branch -r --no-merge master`
do
echo -e $branch \\t`git log -n 1 --format="%ci, %cr, %an, %ae" --since="30 days ago" $branch` >> ../$report_name.txt
done

rm -rf $REPO_DIR
echo
}

main $@