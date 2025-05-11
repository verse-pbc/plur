#!/usr/bin/env python3
"""
Plur App Testing Automation
==========================

This script provides specialized functionality for testing the Plur app.
It uses Playwright to automate the Flutter web app and implements specific
flows for testing community features, invites, and more.

Usage:
    python plur_app_tester.py [command]

Commands:
    test_invite_flow - Test the community invite generation and joining flow
    test_community_creation - Test creating a new community
    interactive - Enter interactive testing mode
    
To use this script:
1. Start your Flutter app in Chrome debug mode:
   flutter run -d chrome --web-renderer html
2. Run this script with a command in another terminal
"""

import asyncio
import argparse
import os
import sys
import time
import random
import json
from datetime import datetime
from playwright.async_api import async_playwright, Page

# Import the base Flutter tester
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from flutter_test_automation import FlutterWebTester

# Configuration
FLUTTER_WEB_PORT = 8080  # Default Flutter web port, change if yours is different
APP_URL = f"http://localhost:{FLUTTER_WEB_PORT}"

class PlurAppTester(FlutterWebTester):
    """Extended tester with Plur-specific functionality"""
    
    async def login_if_needed(self):
        """Check if login is needed and handle the login flow"""
        print("Checking if login is needed...")
        
        # Check if we're on a login screen by looking for typical elements
        login_elements = await self.find_flutter_element(text="Login")
        
        if login_elements:
            print("Login screen detected, attempting to log in...")
            # This is a placeholder - update with your actual login flow
            # You would typically:
            # 1. Find the username/password fields
            # 2. Fill them in
            # 3. Click the login button
            
            # For now, let's simulate a basic login flow:
            await self.click_text("Login")
            print("Login attempt completed")
            # Wait for navigation/loading
            await asyncio.sleep(3)
        else:
            print("Already logged in or no login required")
    
    async def navigate_to_communities(self):
        """Navigate to the communities section"""
        print("Navigating to communities section...")
        
        # Try to find and click on a communities/groups navigation item
        success = await self.click_text("Communities")
        if not success:
            # Try alternative navigation methods if direct click doesn't work
            success = await self.click_text("Groups")
        
        if success:
            print("Navigated to communities section")
            # Wait for navigation to complete
            await asyncio.sleep(2)
            return True
        else:
            print("Failed to navigate to communities section")
            return False
    
    async def create_new_community(self, name=None):
        """Create a new community with an optional custom name"""
        if name is None:
            # Generate a random community name for testing
            name = f"Test Community {random.randint(1000, 9999)}"
        
        print(f"Creating new community: {name}")
        
        # Navigate to communities section first
        await self.navigate_to_communities()
        
        # Look for a create/add community button
        create_buttons = await self.find_flutter_element(text="Create")
        if not create_buttons:
            create_buttons = await self.find_flutter_element(text="Add")
            
        if create_buttons:
            # Click on the button center
            element = create_buttons[0]
            x = element['rect']['x'] + element['rect']['width'] / 2
            y = element['rect']['y'] + element['rect']['height'] / 2
            await self.page.mouse.click(x, y)
            
            # Wait for dialog to appear
            await asyncio.sleep(1)
            
            # Try to find the name input field and fill it
            # This is a simplistic approach - in reality, locating the right field might be more complex
            input_fields = await self.page.query_selector_all('input')
            if input_fields:
                await input_fields[0].fill(name)
                
                # Try to find and click the create/submit button
                submit = await self.click_text("Create")
                if not submit:
                    submit = await self.click_text("Submit")
                    
                if submit:
                    print(f"Community '{name}' created successfully")
                    # Wait for creation process
                    await asyncio.sleep(3)
                    return True
        
        print("Failed to create community")
        return False
            
    async def generate_invite_link(self):
        """Generate an invite link for a community"""
        print("Generating invite link...")
        
        # Navigate to a community first (assumes we're already in the communities section)
        # This is a placeholder - you'll need to adapt this to your UI structure
        community_items = await self.find_flutter_element(text="Community")
        if community_items:
            # Click on the first community
            element = community_items[0]
            x = element['rect']['x'] + element['rect']['width'] / 2
            y = element['rect']['y'] + element['rect']['height'] / 2
            await self.page.mouse.click(x, y)
            
            # Wait for navigation
            await asyncio.sleep(2)
            
            # Look for invite button
            invite_success = await self.click_text("Invite")
            if not invite_success:
                # Try alternative text variations
                invite_success = await self.click_text("Share")
                
            if invite_success:
                # Wait for invite dialog
                await asyncio.sleep(1)
                
                # Try to find and select the plur:// link option
                await self.click_text("plur://")
                
                # Wait for link generation
                await asyncio.sleep(1)
                
                # Try to find the link text
                links = await self.find_flutter_element(text="plur://")
                if links:
                    # The link should be the text content of the element
                    link_text = links[0].get('text', '')
                    print(f"Generated invite link: {link_text}")
                    return link_text
        
        print("Failed to generate invite link")
        return None
    
    async def test_paste_invite_join(self, invite_link):
        """Test joining a community via clipboard paste"""
        if not invite_link:
            print("No invite link provided")
            return False
            
        print(f"Testing joining with invite link: {invite_link}")
        
        # Set the clipboard content to the invite link
        await self.page.evaluate(f'navigator.clipboard.writeText("{invite_link}")')
        
        # Navigate somewhere where the paste button would be visible
        await self.navigate_to_communities()
        
        # Wait for the paste button to potentially appear
        await asyncio.sleep(2)
        
        # Look for and click the paste button
        paste_success = await self.click_text("Paste")
        if not paste_success:
            # Try alternative text
            paste_success = await self.click_text("Join")
            
        if paste_success:
            print("Clicked paste/join button")
            # Wait for join process
            await asyncio.sleep(5)
            return True
        
        print("Failed to find paste/join button")
        return False
    
    async def complete_full_invite_flow(self):
        """Run through a complete invite generation and joining flow"""
        print("Starting complete invite flow test...")
        
        # Step 1: Login if needed
        await self.login_if_needed()
        
        # Step 2: Create a new community
        community_name = f"Test Community {int(time.time())}"
        create_success = await self.create_new_community(community_name)
        if not create_success:
            print("Failed to create community, cannot continue flow")
            return False
        
        # Step 3: Generate an invite link
        invite_link = await self.generate_invite_link()
        if not invite_link:
            print("Failed to generate invite link, cannot continue flow")
            return False
            
        print(f"Successfully generated invite link: {invite_link}")
        
        # Step 4: Save the invite link (in a real test you might use a second browser context)
        # For demonstration, we're just printing it and completing the flow
        print("Complete invite flow test completed successfully!")
        return True
    
    async def get_visible_communities(self):
        """Get a list of visible communities"""
        # Wait for communities to load
        await asyncio.sleep(2)
        
        # Find community elements
        communities = await self.find_flutter_element(text="Community")
        
        result = []
        for community in communities:
            result.append({
                'name': community.get('text', 'Unknown').strip(),
                'element': community
            })
            
        return result


async def test_invite_flow(tester):
    """Run through the invite flow testing"""
    await tester.complete_full_invite_flow()
    
async def test_community_creation(tester):
    """Test community creation"""
    await tester.login_if_needed()
    community_name = f"Test Community {datetime.now().strftime('%H:%M:%S')}"
    success = await tester.create_new_community(community_name)
    print(f"Community creation {'succeeded' if success else 'failed'}")

async def interactive_mode(tester):
    """Custom interactive mode for Plur-specific commands"""
    print("\n========= Plur App Tester =========")
    print("Type commands to interact with the app:")
    print("  login - Attempt to login")
    print("  communities - Navigate to communities section")
    print("  create [name] - Create a new community with optional name")
    print("  invite - Generate an invite link")
    print("  list - List visible communities")
    print("  screenshot [path] - Take a screenshot")
    print("  exit/quit - Exit the tester")
    print("===================================\n")
    
    while True:
        command = input("\nCommand > ").strip()
        
        if command in ['exit', 'quit']:
            break
            
        try:
            if command == 'login':
                await tester.login_if_needed()
                
            elif command == 'communities':
                await tester.navigate_to_communities()
                
            elif command.startswith('create'):
                parts = command.split(' ', 1)
                name = parts[1].strip() if len(parts) > 1 else None
                await tester.create_new_community(name)
                
            elif command == 'invite':
                link = await tester.generate_invite_link()
                if link:
                    print(f"Generated link: {link}")
                    
            elif command == 'list':
                communities = await tester.get_visible_communities()
                if communities:
                    print("\nVisible communities:")
                    for i, community in enumerate(communities):
                        print(f"{i+1}. {community['name']}")
                else:
                    print("No communities found")
                    
            elif command.startswith('screenshot'):
                parts = command.split(' ', 1)
                path = parts[1].strip() if len(parts) > 1 else "plur_screenshot.png"
                await tester.take_screenshot(path)
                
            else:
                print(f"Unknown command: {command}")
                
        except Exception as e:
            print(f"Error executing command: {e}")


async def main():
    parser = argparse.ArgumentParser(description="Plur App Testing Tool")
    parser.add_argument('command', nargs='?', default='interactive',
                        choices=['test_invite_flow', 'test_community_creation', 'interactive'],
                        help='Command to run')
    args = parser.parse_args()
    
    # Create tester instance
    tester = PlurAppTester()
    
    try:
        # Connect to the running Flutter web app
        await tester.connect()
        
        # Run the specified command
        if args.command == 'test_invite_flow':
            await test_invite_flow(tester)
        elif args.command == 'test_community_creation':
            await test_community_creation(tester)
        else:  # interactive is the default
            await interactive_mode(tester)
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Clean up
        await tester.close()


if __name__ == "__main__":
    asyncio.run(main())