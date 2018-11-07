#!/bin/bash
set -e

################################################################################
#	Name: staleBranchReport.sh
#	Purpose: This script generates a report listing branches that have not been 
#	merged into master and their last commit is older than 90 days. This script 
#	runs against all projects in Bitbucket (Except user projects).
#	Overview of steps:
#		1. Traverse through the repository folders.
#		2. Parse the project and repository names from the repository-config file.
#		3. Check the repository for stale branches.
#		4. Generate report file.
#		5. E-mail report if e-mail option was passed.
################################################################################

TEMPVAR=""
main() {
SCRIPTNAME="staleBranchReport"
USAGE="Usage: $SCRIPTNAME [-e <email_address>...] [-d <days_old>]

-e <email_address>...  E-mail address or addresses to send the report to. Ex. -e \"johnSmith@mail.mil janeSmith@mail.mil\"
-d <days_old>          Sets the age in days for when a branch is considered stale. [default: 90]"
GIT_PATH="/usr/local/bin/git"
REPO_FOLDER_LOCATION="/opt/apps/stash_home/shared/data/repositories"
REPO_BASE_URL="https://example.com"

CURRENT_DIRECTORY=$PWD

current_date=`date --iso-8601='date'`
REPORT_FILENAME="staleBranchReport-${current_date}.txt"

while getopts ":e:d:h" opt; do
  case $opt in
    e ) email="$OPTARG";;
	d ) days="$OPTARG";;
	h ) echo "$USAGE"; exit 0;;
	\? ) echo "Invalid option: -$OPTARG" >&2; echo "$USAGE"; exit 1;;
	: ) echo "Option -$OPTARG requires an argument." >&2; echo "$USAGE"; exit 1;;
	* ) echo "Unimplemented option: -$OPTARG" >&2; echo "$USAGE"; exit 1;;
  esac
done

echo "Running Stale Branch Report..."

if [ ! -z "$email" ]; then
  echo "Report will be e-mailed to $email."
fi

if [ -z "$days" ]; then
  days="90"
fi

echo "Branches are considered stale if older than $days days."

cd $REPO_FOLDER_LOCATION

fileList=(*/)
declare -A projectArray

for f in "${fileList[@]}"; do
  repo_config_path="${f}repository-config"
  if [ -f $repo_config_path ]; then
    project=$(echo $(grep 'project' $repo_config_path | cut -d'=' -f2))
    repository=$(echo $(grep 'repository' $repo_config_path | cut -d'=' -f2))
    if [[ ! $project == ~* ]]; then
      echo "Checking ${project}/${repository} in ${f}"
      cd $f

      checkRepo $project $repository

      if [ ! -z "${TEMPVAR}" ]; then
        if [ -z "${projectArray[$project]}" ]; then
          projectArray[$project]+="==========================\n"
          projectArray[$project]+="PROJECT [$project]\n"
          projectArray[$project]+="==========================\n"
        fi
        projectArray[$project]+="\n${TEMPVAR}\n"
      fi

      cd ..
    fi
  fi
done

echo "BitBucket Stale Branch Report" >> ${CURRENT_DIRECTORY}/${REPORT_FILENAME}
echo "Report date: $current_date" >> ${CURRENT_DIRECTORY}/${REPORT_FILENAME}
echo "Stale branch age: $days days" >> ${CURRENT_DIRECTORY}/${REPORT_FILENAME}

for x in "${projectArray[@]}"; do
  echo -e "$x" >> ${CURRENT_DIRECTORY}/${REPORT_FILENAME}
  echo -e "==========================\n" >> ${CURRENT_DIRECTORY}/${REPORT_FILENAME}
done

if [ ! -z "$email" ]; then
  echo "E-mailing report to $email."
  echo "Bitbucket Stale Branch Report for $current_date." | mailx -s "Stale Branch Report $current_date" -r "LOGSA Bamboo <no-reply@mail.mil>" -a ${CURRENT_DIRECTORY}/${REPORT_FILENAME} $email
fi

echo "Finished!"

return 0
}

checkRepo() {

project_key=$1
repo_name=$2
repo_url="${REPO_BASE_URL}/projects/${project_key}/repos/${repo_name}"
TEMPVAR=""
checkRepoText="\tRepository: $repo_name\n\tURL: $repo_url\n"
checkRepoText+="\tBranches:\n"
branchText=""

if [ ! -z "$($GIT_PATH branch)" ]; then
  for branch in $($GIT_PATH branch --no-merge master | tr '*' ' '); do
    commits=$($GIT_PATH log -n 1 --since="$days days ago" $branch)
    if [ -z "$commits" ]; then
      branchText+="\n\t\t${branch} \n\t\t$($GIT_PATH log -n 1 --format="%ci, %cr, %an, %ae" $branch)"
    fi
  done
fi

if [ ! -z "$branchText" ]; then
  TEMPVAR+="${checkRepoText}${branchText}"
fi
}

main "$@"