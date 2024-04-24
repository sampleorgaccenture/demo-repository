#!/usr/local/bin/python3
'''This script exports all pending invites for an organization'''

import re
import sys
import csv
import requests  # pylint: disable=import-error


def print_users(file_name, users):
    '''Writes the users list to a csv file specified by file_name'''
    with open(file_name, 'w') as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        writer.writerow(['created_at', 'login', 'email'])
        for user in users:
            writer.writerow(user.values())

    print(f'Wrote user list to {file_name}')


if len(sys.argv) != 3:
    print(f'Error: This must be called with the organization and your PAT, '
          f'EG: {sys.argv[0]} orgName TOKEN')
    sys.exit(1)

ORG = sys.argv[1]
URL = f'https://api.github.com/orgs/{ORG}/invitations'
TOKEN = sys.argv[2]

PARAMS = {'per_page': 100,
          'page': 1}

HEADERS = {'Content-Type': 'application/json',
           'Accept': 'application/vnd.github.dazzler-preview+json',
           'Authorization': f'Bearer {TOKEN}'}


RESPONSE = requests.get(url=URL, params=PARAMS, headers=HEADERS)

PAGE = 2
USERS = list(map(lambda x: {'created_at': x['created_at'],
                            'login': x['login'],
                            'email': x['email']}, RESPONSE.json()))

if 'Link' not in RESPONSE.headers:
    print_users('users.csv', USERS)
    sys.exit(0)

LAST_PAGE = re.search('&page=([0-9]+)>;', RESPONSE.headers['Link'].split(',')[1]).group(1)


for i in range(2, int(LAST_PAGE)+1):
    PARAMS['page'] = i
    RESPONSE = requests.get(url=URL, params=PARAMS, headers=HEADERS)
    USERS = USERS + list(map(lambda x: {'created_at': x['created_at'],
                                        'login': x['login'],
                                        'email': x['email']}, RESPONSE.json()))

print_users('users.csv', USERS)

sys.exit(0)
