#!/bin/bash

################################################################################
############# Add Users To Organizations  @AdmiralAwkbar #######################
################################################################################
################################################################################

################################################################################
# LEGEND:
# This script is used to help mass add users to an organization in GitHub.com
# The script needs 3 pieces of data:
# - GitHub Organization name
# - GitHub Personal Access Token
# - List of user logins or emails(in the case of GHE Cloud) and roles
# After passing this information to the script, it will use the GitHub.com api
# and send emails to users to invite them to the GitHub.com organization.
# This can save users lots of time if they have many users they need to have
# join an organization
################################################################################


###########
# GLOBALS #
###########
ERROR_COUNT=0                       # Count of errors
GITHUB_URL="https://api.github.com" # Url to GitHub API
GITHUB_ORG=""                       # Name of the organization to add users
GITHUB_TOKEN=""                     # GitHub Personal Access Token read from user input
USER_LIST=""                        # Name and path of file with user logins or emails and roles

################################################################################
############################ FUNCTIONS #########################################
################################################################################
################################################################################

################################################################################
#### Function PrintUsage #######################################################
PrintUsage()
{
  cat <<EOM
Usage: get-repo-statistics [options] ORGANIZATION_NAME

Options:
    -h, --help                    : Show script help
    -d, --debug                   : Enable debug logging
    -u, --url                     : Set GHES URL (e.g. https://github.example.com) Defaults to https://api.github.com if omitted
    -t, --token                   : Set Personal Access Token with repo scope - Looks for GITHUB_TOKEN environment variable if omitted
    -o, --organization            : The name of the organization to which users will be added
    -i, --input                   : Path of the input file with users and their respective roles
    -e, --email                   : Specifies that users will be invited by their email rather than username - Only possible when on GitHub Enterprise Cloud 
  
Description:
invite_users_to_org scans an organization or list of organizations for all repositories and gathers size statistics for each repository

Example:
  ./invite_users_to_org -u https://github.example.com -t ABCDEFG1234567 -o my-org-name

EOM
  exit 0
}

################################################################################
#### Function DebugJQ ##########################################################
DebugJQ()
{
  # If Debug is on, print it out...
  if [[ $DEBUG == true ]]; then
    echo "$1" | jq '.'
  fi
}
################################################################################
#### Function Debug ############################################################
Debug()
{
  # If Debug is on, print it out...
  if [[ $DEBUG == true ]]; then
    echo "$1"
  fi
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      PrintUsage;
      ;;
    -u|--url)
      GITHUB_URL="$2/api/v3"
      shift 2
      ;;
    -d|--DEBUG)
      DEBUG=true
      shift
      ;;
    -e|--email)
      IS_EMAIL=true
      shift
      ;;
    -t|--token)
      GITHUB_TOKEN=$2
      shift 2
      ;;
    -o|--organization)
      GITHUB_ORG=$2
      shift 2
      ;;
    -i|--input)
      USER_LIST=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done


################################################################################
#### Function SendInvite #######################################################
SendInvite()
{
  ###########################
  # Set the input variables #
  ###########################
  USER=$1 # Email of end user
  USER_ROLE=$2  # Role for user

  #################################
  # Create and Run Curl to GitHub #
  #################################
  if [[ $IS_EMAIL == "true" ]]; then
    ###################################
    # Need to update to direct_member #
    ###################################
    if [ "$USER_ROLE" == "member" ]; then
      USER_ROLE="direct_member"
    fi
    
    INVITE_RESPONSE=$(curl -w '%{http_code}' -s -X POST --url "$GITHUB_URL/orgs/$GITHUB_ORG/invitations" \
      -H "accept: application/vnd.github.dazzler-preview+json" \
      -H "content-type: application/json" \
      -H "authorization: Bearer $GITHUB_TOKEN" \
      -d "{ \"email\": \"$USER\", \"role\": \"$USER_ROLE\" }")
  else
    Debug "curl -X PUT --url \"$GITHUB_URL/orgs/$GITHUB_ORG/memberships/$USER\" \
      -H \"accept: application/vnd.github.dazzler-preview+json\" \
      -H \"content-type: application/json\" \
      -H \"authorization: Bearer $GITHUB_TOKEN\" \
      -d \"{\"role\": \"$USER_ROLE\" }\""

    INVITE_RESPONSE=$(curl -w '%{http_code}' -s -X PUT --url "$GITHUB_URL/orgs/$GITHUB_ORG/memberships/$USER" \
      -H "accept: application/vnd.github.dazzler-preview+json" \
      -H "content-type: application/json" \
      -H "authorization: Bearer $GITHUB_TOKEN" \
      -d "{\"role\": \"$USER_ROLE\" }")

  fi

  INVITE_RESPONSE_CODE="${INVITE_RESPONSE:(-3)}"
  INVITE_RESPONSE_BODY="${INVITE_RESPONSE::${#INVITE_RESPONSE}-4}"

  Debug "${INVITE_RESPONSE}"

  if [[ "$INVITE_RESPONSE_CODE" != "200" ]]; then
    echo "ERROR --- Received error response code while inviting user: $USER"
    echo "${INVITE_RESPONSE_BODY}" | jq '.'
    ERROR_COUNT=$((ERROR_COUNT+1))
  else
    ERROR_MESSAGE=$(echo "${INVITE_RESPONSE_BODY}" | jq -r '.message')
    if [[ "$ERROR_MESSAGE" != "null" ]]; then
      echo "ERROR --- Errors occurred while inviting user: $USER"
      echo "${INVITE_RESPONSE_BODY}" | jq '.'
      ERROR_COUNT=$((ERROR_COUNT+1))
    fi
  fi
}

################################################################################
#### Function GetUserInput #####################################################
GetUserInput()
{
  # Need to get the following information from the user:
  # - Name of the GitHub.com Organization
  # - Path and filename of the user file
  # - GitHub.com Personal Access Token


  if [[ -z "${GITHUB_ORG}" ]]; then
    ##########################
    ##########################
    ## Get the Organization ##
    ##########################
    ##########################
    echo "---------------------------------------------"
    echo "Type the GitHub Organization that you want to invite users to,"
    echo "Followed by [ENTER]:"

    #####################
    # Read the Org name #
    #####################
    read -r GITHUB_ORG
  fi 

  # Clean any whitespace that may be enetered
  ORG_NAME_NO_WHITESPACE="$(echo "${GITHUB_ORG}" | tr -d '[:space:]')"
  GITHUB_ORG=$ORG_NAME_NO_WHITESPACE

  # Validate the Org Name
  if [ ${#GITHUB_ORG} -le 1 ]; then
    echo "Error! You must give a valid Organization name!"
    exit 1
  fi

  ##################
  # Print the name #
  ##################
  echo "Organization:[$GITHUB_ORG]"

  if [[ -z "${USER_LIST}" ]]; then
    ########################
    ########################
    ## Get the Input File ##
    ########################
    ########################
    echo "---------------------------------------------"
    echo "Note: The file should either be in the format:"
    echo "  user.email@address,role"
    echo "  user.email2@address,role"
    echo "  etc..."
    echo ""
    echo "or in the format:"
    echo "  user-login1,role"
    echo "  user-login2,role"
    echo "  etc..."
    echo ""
    echo "Note: the role can be either: member or admin"
    echo ""
    echo "Type the full name and path of the user input file,"
    echo "Followed by [ENTER]:"

    ######################
    # Read the user list #
    ######################
    read -r USER_LIST
  fi
  ##############################
  # Need to validate User_List #
  ##############################
  REGEX=" |'"
  # Check for spaces
  if [[ $USER_LIST =~ $REGEX ]]; then
    echo "ERROR!!! You cannot have a file path with space characters!"
    echo "Fix the full path and try again..."
    exit 1
  fi

  # Check the file exists
  if [ ! -f "$USER_LIST" ]; then
    echo "ERROR!!! Please verify the file exists!"
    echo "Cound NOT find file at:[$USER_LIST]"
    exit 1
  fi

  #################################
  # Print the user list file path #
  #################################
  Debug "User List:[$USER_LIST]"

  if [[ -z "${GITHUB_TOKEN}" ]]; then
    ###################################
    ###################################
    ## Get the Personal Access Token ##
    ###################################
    ###################################
    echo "---------------------------------------------"
    echo "Note: The following input will not be displayed back to the screen"
    echo ""
    echo "Type in your GitHub Personal Access Token,"
    echo "Followed by [ENTER]:"

    #########################
    # Read the GitHub Token #
    #########################
    read -r -s GITHUB_TOKEN
  fi

  ##########################
  # Need to validate token #
  ##########################
  REGEX=" |'"
  # Check for spaces
  if [[ $GITHUB_TOKEN =~ $REGEX ]]; then
    echo "ERROR!!! You cannot have a GitHub PAT with space characters!"
    echo "Fix the PAT and try again..."
    exit 1
  fi

  ###################
  # Print the Token #
  ###################
  # Dont print this if not needed
  #echo "Token:[$GITHUB_TOKEN]"

  # Validate that if EMAIL is specified, this will be run again GHEC
  if [[ "${IS_EMAIL}" == true && "${GITHUB_URL}" !=  "https://api.github.com" ]]; then
    echo "ERROR!!! GitHub Enterprise Server doesn't support inviting users to an organization by email address."
    echo "  Please provide a list of usernames instead."
    exit 1
  fi

}
################################################################################
#### Function ValidateUserFile #################################################
ValidateUserFile()
{
  # Need to validate:
  # - The data is parseable
  echo "---------------------------------------------"
  echo "Validating User list format and data integrity..."
  ###################################
  # Remove all whitespace from file #
  ###################################
  # sed -i 's/\s//g' "$USER_LIST"

  ####################################
  # Remove all empty lines from file #
  ####################################
  # sed -i '/^$/d' "$USER_LIST"

  #########################
  # Convert to lower case #
  #########################
  # Cant use sed on this due to Mac sucks on GNU
  #sed -i 's/.*/\L\1/g' $USER_LIST

  while IFS=, read -r NAME ROLE
  do
    ###################################
    # Validate we have both variables #
    ###################################
    test -z "$NAME" && echo "ERROR!!! Line:[$LINE] has no valid user email!" 1>&2 && exit 1
    test -z "$ROLE" && echo "ERROR!!! Line:[$LINE] has no valid role!" 1>&2 && exit 1

    #############################
    # Validate email has length #
    #############################
    # at a minimum you would need a@b
    if [ ${#NAME} -lt 3 ]; then
      echo "ERROR!!! Line:[$LINE] has no valid email! Email must be provided"
      exit 1
    fi

    ###############################################
    # Validate the role is either admin or member #
    ###############################################
    if [ "$ROLE" != "admin" ] && [ "$ROLE" != "member" ];then
      echo "ERROR!!! Line:[$LINE] has no valid role! Role must be [member] or [admin]"
      exit 1
    fi

  done < "$USER_LIST"

  ####################################
  # Print we have validated the file #
  ####################################
  echo "User List has been validated"
}
################################################################################
#### Function ParseUsers #######################################################
ParseUsers()
{
    # Need to complete the following:
    # - Parse the user file
    # - Get user email and role
    # Send data to SendEnvite function
    echo "---------------------------------------------"
    while IFS=, read -r NAME ROLE
    do

      ROLE=$(echo "$ROLE" | tr -d '\r')

      ####################################
      # Send the invitiation to the user #
      ####################################
      SendInvite "$NAME" "$ROLE"

    done < "$USER_LIST"
}
################################################################################
#### Function Header ###########################################################
Header()
{
  # Basic print information about program
  echo ""
  echo "---------------------------------------------"
  echo "---------------------------------------------"
  echo "---- Invite users to GitHub Organization ----"
  echo "---------------------------------------------"
  echo "---------------------------------------------"
  echo "This program will take a list of user emails and roles"
  echo "and send GitHub invites to them."
  echo "---------------------------------------------"
}
################################################################################
#### Function Footer ###########################################################
Footer()
{
  #####################################
  # Prints as we close the script out #
  #####################################
  echo "---------------------------------------------"
  echo "---------------------------------------------"
  if [ $ERROR_COUNT -eq 0 ]; then
    echo "Process Completed Successfully"
    echo "All users were successfully invited"
    echo "---------------------------------------------"
  else
    echo "ERRORS FOUND! COUNT:[$ERROR_COUNT]"
    echo "Please validate output text for failed user invites"
    echo "---------------------------------------------"
    exit "$ERROR_COUNT"
  fi
}
################################################################################
############################## MAIN ############################################
################################################################################

##########
# Header #
##########
Header

##################
# Get User Input #
##################
GetUserInput

#################
# Validate File #
#################
ValidateUserFile

###############
# Parse Users #
###############
ParseUsers

##########
# Footer #
##########
Footer
