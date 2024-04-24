# Invite users to GitHub.com Organization (Python Edition)

This script will help mass invite users to a **GitHub.com** Organization.

## Prerequisites

To run the script you will need the following:
- Name of the gitHub.com Organization you want to invite users towards
- A GitHub Personal Access Token with admin rights to the Organization
  - [Create a GitHub PAT](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
- A list of all users emails to invite
  - The file should look like as follows:
  - **Note:** most members will be added with role:`direct_member`, only Organization admins should have role `admin`

```text
user.email@company.com,admin
user2.email@company.com,admin
user3.email@company.com,direct_member
user4.email@company.com,direct_member
user5.email@company.com,direct_member
...
```

## How to use

- Download the script to your local machine
- Make the file executable
  - `pip install -r requirements.txt`
- Execute the file
  - Usage: `invite_users_to_org.py -o <organization> -t <github_personal_token> -i <file>`
  - Example: `python3 invite-users-to-org.py -o org_name -t PAT -i users.csv`

