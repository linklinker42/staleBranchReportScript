# staleBranchReportScript

This script generates a report of stale branches for a given repository or list of repositories.
A branch is considered stale when it has not been merged into master and its last commit is older
than 30 days.

## Usage

```
staleBranchReport -u <repository url> || -l <text file of repository urls> [OPTION]

Options:
	-w	: Working directory used to perform the git clone and to store the generated report. If not supplied, defaults to whatever directory the terminal is currently in.
	
```

## Examples

```
staleBranchReport -u ssh://git@com.mycompany:7999/et/someTool.git -w /e/reports
```

This will generate a report at /e/reports/staleBranchReport/repo-report-2018-09-28T11-05:00.txt
for the someTool repository in the Enterprise Tools project.

```
staleBranchReport -l /e/reports/repo-list.txt -w /e/reports
```
This will generate a report at /e/reports/staleBranchReport/repo-report-2018-09-28T11-05:00.txt
containing the reports for all the repositories in the repo-list.txt file.
