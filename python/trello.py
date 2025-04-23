#!/usr/bin/env python3

import os
import sys
import json
import yaml
import requests
from pathlib import Path
from dotenv import load_dotenv

class TrelloAPI:
    BASE_URL = 'https://api.trello.com/1'
    CONFIG_FILE = Path.home() / '.trello_config.yml'
    
    def __init__(self):
        load_dotenv()
        self.api_key = os.getenv('TRELLO_API_KEY')
        self.secret = os.getenv('TRELLO_SECRET')
        
        if not self.api_key or not self.secret:
            # Try to read directly from .env file
            if os.path.exists('.env'):
                with open('.env', 'r') as f:
                    for line in f:
                        if line.startswith('TRELLO_API_KEY='):
                            self.api_key = line.strip().split('=')[1]
                        elif line.startswith('TRELLO_SECRET='):
                            self.secret = line.strip().split('=')[1]
        
        if not self.api_key:
            raise ValueError("TRELLO_API_KEY not found in .env file or environment variables")
        if not self.secret:
            raise ValueError("TRELLO_SECRET not found in .env file or environment variables")
        
        self.load_or_create_config()

    def load_or_create_config(self):
        if self.CONFIG_FILE.exists():
            with open(self.CONFIG_FILE, 'r') as f:
                config = yaml.safe_load(f)
                self.token = config['token']
                self.board_id = config['board_id']
                self.board_name = config['board_name']
        else:
            # Get token through authorization flow
            auth_url = f"https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&name=Server%20Token&key={self.api_key}"
            print("\nPlease visit this URL to authorize the application:")
            print(auth_url)
            self.token = input("\nEnter the token you received: ").strip()

            # Get boards and select one
            boards = self.get_boards()
            self.print_boards(boards)
            board_index = int(input("\nSelect board number: ")) - 1
            board = boards[board_index]
            self.board_id = board['id']
            self.board_name = board['name']

            # Save config
            self.save_config()

    def save_config(self):
        config = {
            'token': self.token,
            'board_id': self.board_id,
            'board_name': self.board_name
        }
        self.CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(self.CONFIG_FILE, 'w') as f:
            yaml.dump(config, f)

    def get_boards(self):
        response = requests.get(
            f"{self.BASE_URL}/members/me/boards",
            params={
                'key': self.api_key,
                'token': self.token,
                'fields': 'name,id'
            }
        )
        return response.json()

    def get_lists(self):
        response = requests.get(
            f"{self.BASE_URL}/boards/{self.board_id}/lists",
            params={
                'key': self.api_key,
                'token': self.token,
                'fields': 'name,id'
            }
        )
        return response.json()

    def get_all_cards(self):
        response = requests.get(
            f"{self.BASE_URL}/boards/{self.board_id}/cards",
            params={
                'key': self.api_key,
                'token': self.token,
                'fields': 'name,id,idList'
            }
        )
        return response.json()

    def move_card(self, card_id, list_id):
        response = requests.put(
            f"{self.BASE_URL}/cards/{card_id}",
            params={
                'key': self.api_key,
                'token': self.token,
                'idList': list_id
            }
        )
        return response.json()

    def print_boards(self, boards):
        print("\nAvailable boards:")
        for i, board in enumerate(boards, 1):
            print(f"{i}. {board['name']}")

def fuzzy_match(needle, haystack):
    needle = needle.lower()
    matches = [item for item in haystack if needle in item['name'].lower()]
    
    if not matches:
        print(f"\nNo matches found for '{needle}'")
        print("Available options:")
        for item in haystack:
            print(f"- {item['name']}")
        sys.exit(1)
    elif len(matches) == 1:
        return matches[0]
    else:
        print(f"\nMultiple matches found for '{needle}':")
        for i, match in enumerate(matches, 1):
            print(f"{i}. {match['name']}")
        index = int(input("Select number: ")) - 1
        return matches[index]

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <card_name> <column>")
        print(f"e.g. {sys.argv[0]} fcas testing")
        sys.exit(1)

    card_name = sys.argv[1]
    target_column = sys.argv[2]
    
    trello = TrelloAPI()
    
    # Get all lists and cards
    lists = trello.get_lists()
    cards = trello.get_all_cards()
    
    # Find card first
    card = fuzzy_match(card_name, cards)
    
    # Find target list
    target_list = fuzzy_match(target_column, lists)
    
    # Move the card
    if card['idList'] == target_list['id']:
        print(f"\nCard '{card['name']}' is already in list '{target_list['name']}'")
    else:
        current_list = next(l for l in lists if l['id'] == card['idList'])
        trello.move_card(card['id'], target_list['id'])
        print(f"\nMoved card '{card['name']}' from '{current_list['name']}' to '{target_list['name']}'")

if __name__ == "__main__":
    main() 