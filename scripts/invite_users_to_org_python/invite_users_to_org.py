#!/usr/bin/env python3
# -*- coding: utf_8 -*-
"""invite_users_to_org.py"""
import csv
import getopt
import sys

import requests
from requests.exceptions import RequestException

USAGE_TEXT = "Usage: invite_users_to_org.py -o <organization> -t <github_personal_token> -i <file>"

try:
    opts, args = getopt.getopt(
        sys.argv[1:], "o:t:i:h", ["organization=", "token=", "input=", "help"]
    )
    for opt, arg in opts:
        if opt in ("-o", "--organization"):
            github_org = arg
        elif opt in ("-t", "--token"):
            github_token = arg
        elif opt in ("-i", "--input"):
            input_file = arg
        elif opt in ("-h", "--help"):
            print(USAGE_TEXT)
            sys.exit()
except getopt.GetoptError as err:
    print(err)
    print(USAGE_TEXT)
    sys.exit(1)

try:
    ENDPOINT = f"https://api.github.com/orgs/{github_org}/invitations"
    HEADERS = {
        "Content-Type": "application/json",
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {github_token}",
    }
    with open(input_file, encoding="utf8", newline="") as f:
        csvreader = csv.reader(f)
        for row in csvreader:
            email = row[0]
            role = row[1]
            r = requests.post(
                ENDPOINT, headers=HEADERS, json={"email": email, "role": role}
            )
            print(email, role, r.status_code, r.reason)
except RequestException as err:
    print(err)
    sys.exit(2)
