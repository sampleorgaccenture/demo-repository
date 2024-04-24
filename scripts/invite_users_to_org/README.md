# Invite user(s) to GitHub.com Organization

This script will help mass invite users to a **GitHub.com** Organization.

## Prerequisites

To run the script you will need the following:
- Name of the GitHub.com Organization you want to invite users towards
- A GitHub Personal Access Token with admin rights to the Organization
  - [Create a GitHub PAT](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
- A list of all users emails to invite
  - The file should look like as follows:
  - **Note:** most members will be added with role:`member`, only Organization admins should have role `admin`

```text
user.email@company.com,admin
user2.email@company.com,admin
user3.email@company.com,member
user4.email@company.com,member
user5.email@company.com,member
...
```

## How to use

- Download the script to your local machine
- Make the file executable
  - `chmod +x invite-users-to-org.sh`
- Execute the file
  - `./invite-users-to-org.sh` (if the .csv file contains all the login-ids)
  - `./invite-users-to-org.sh --email` (if the .csv file contains all the user emails)
- Provide the script with information when prompted
- **Example** Run below:

  ```bash
  ---------------------------------------------
  ---------------------------------------------
  ---- Invite users to GitHub Organization ----
  ---------------------------------------------
  ---------------------------------------------
  This program will take a list of user emails and roles
  and send GitHub invites to them.
  ---------------------------------------------
  ---------------------------------------------
  Type the GitHub Organization that you want to invite users to,
  Followed by [ENTER]:

  YourOrgName

  Organization:[YourOrgName]

  ---------------------------------------------
  Note: The file should be in the format:
    user.email@address,role
    user.email2@address,role
    etc...
  Note: the role can be either: member or admin

  Type the full name and path of the user input file,
  Followed by [ENTER]:

  /path/to/file.csv

  ---------------------------------------------
  Note: The following input will not be displayed back to the screen

  Type in your GitHub Personal Access Token,
  Followed by [ENTER]:

  SOMEGITHUBTOKEN
  ```

- The script will then run to completion and send email invites to all users in the list
