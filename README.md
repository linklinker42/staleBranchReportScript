# staleBranchReportScript

This script generates a report of stale branches for all the projects in Bitbucket (Except user projects).
A branch is considered stale when it has not been merged into master and its last commit is older
than 90 days.

## Usage

```
staleBranchReport [OPTIONS]

Options:
	-e	: E-mail address or addresses to send the report to.
	-d	: Sets the age in days for when a branch is considered stale. [default: 90]
	
```

## Examples

```
staleBranchReport -e "johnSmith@mail.mil janeSmith@mail.mil" -d 30
```

This will generate a report and e-mail it to myEmail@mail.mil.
