# Listing Pending Invites
This script allows you to export the list of pending invites in the targeted organization.  
Currently it will list the created date, email, and login if applicable.
  
## Usage

* Get a Personal Access Token that can access the organization API.  It won't need write access of any kind
* `./get_invites.py [Organization Name] [PAT]`  
  * The script will throw an error and remind you of the proper usage if either of these are omitted
  * Currently it is set up to page at 100 per page
* The script will run and dump the file into the `users.csv` file within the same directory
