#!/usr/bin/env python3
"""
Flutter Web App Testing Automation
=================================

This script provides tools to automate interaction with a Flutter web app 
running in Chrome. It uses Playwright to connect to the browser and perform
actions like clicking, typing, etc.

Usage:
    python flutter_test_automation.py

To use this script:
1. Start your Flutter app in Chrome debug mode:
   flutter run -d chrome --web-renderer html
2. Run this script in another terminal
3. Use the provided functions to interact with your app
"""

import asyncio
import os
import sys
import re
from playwright.async_api import async_playwright, Page

# Configuration
FLUTTER_WEB_PORT = 8080  # Default Flutter web port, change if yours is different
APP_URL = f"http://localhost:{FLUTTER_WEB_PORT}"
DEVTOOLS_PORT = None  # Will be detected automatically

class FlutterWebTester:
    def __init__(self):
        self.playwright = None
        self.browser = None
        self.page = None
        self.context = None
    
    async def connect(self):
        """Connect to a running Flutter web app in Chrome"""
        print(f"Connecting to Flutter web app at {APP_URL}...")
        
        # Start Playwright
        self.playwright = await async_playwright().start()
        
        # Launch a new browser if not already connected
        self.browser = await self.playwright.chromium.launch(headless=False)
        self.context = await self.browser.new_context()
        self.page = await self.context.new_page()
        
        # Navigate to the Flutter app
        await self.page.goto(APP_URL)
        print("Connected to Flutter web app!")
        
        # Add a debug message to verify we're connected
        await self.evaluate_js("console.log('Flutter Web Tester connected successfully');")
        
        # Wait for Flutter to initialize
        await asyncio.sleep(2)
    
    async def click(self, selector):
        """Click on an element using CSS selector"""
        await self.page.click(selector)
    
    async def type(self, selector, text):
        """Type text into an element"""
        await self.page.fill(selector, text)
    
    async def evaluate_js(self, js_code):
        """Run JavaScript in the context of the page"""
        return await self.page.evaluate(js_code)
    
    async def find_flutter_element(self, key=None, text=None, type=None):
        """Find a Flutter element by key, text content, or type"""
        # This is a simplistic approach - Flutter's DOM structure can be complex
        search_js = """
        (key, text, type) => {
            const elements = Array.from(document.querySelectorAll('*'));
            return elements.filter(el => {
                if (key && el.getAttribute('data-flutter-key') === key) return true;
                if (text && el.innerText && el.innerText.includes(text)) return true;
                if (type && el.getAttribute('data-flutter-widget-type') === type) return true;
                return false;
            }).map(el => ({ 
                tag: el.tagName, 
                id: el.id, 
                key: el.getAttribute('data-flutter-key'),
                type: el.getAttribute('data-flutter-widget-type'),
                text: el.innerText,
                rect: el.getBoundingClientRect().toJSON()
            }));
        }
        """
        return await self.page.evaluate(search_js, key, text, type)
    
    async def click_text(self, text):
        """Click on element containing specific text"""
        elements = await self.find_flutter_element(text=text)
        if not elements:
            print(f"Warning: No element found with text '{text}'")
            return False
        
        # Click in the center of the first found element
        element = elements[0]
        x = element['rect']['x'] + element['rect']['width'] / 2
        y = element['rect']['y'] + element['rect']['height'] / 2
        
        await self.page.mouse.click(x, y)
        return True
    
    async def take_screenshot(self, path="flutter_screenshot.png"):
        """Take a screenshot of the current state"""
        await self.page.screenshot(path=path)
        print(f"Screenshot saved to {path}")
    
    async def get_app_structure(self):
        """Get a structured representation of the Flutter app's current UI"""
        js = """
        () => {
            const getDetails = (el, depth = 0) => {
                const children = Array.from(el.children).map(child => getDetails(child, depth + 1));
                return {
                    tag: el.tagName,
                    id: el.id || undefined,
                    class: el.className || undefined,
                    type: el.getAttribute('data-flutter-widget-type') || undefined,
                    key: el.getAttribute('data-flutter-key') || undefined,
                    text: el.innerText?.trim() || undefined,
                    depth,
                    children: children.length ? children : undefined
                };
            };
            
            return getDetails(document.body);
        }
        """
        return await self.page.evaluate(js)
    
    async def press_key(self, key):
        """Press a specific keyboard key"""
        await self.page.keyboard.press(key)
    
    async def debug_flutter_rendering(self):
        """Debug Flutter rendering layers (useful for complex UI)"""
        js = """
        () => {
            if (window.flutter_inappwebview?.callHandler) {
                // This would work if running in a Flutter WebView with channel support
                return "Using Flutter WebView - cannot directly access Flutter rendering";
            }
            
            // For Flutter web, try to access internal state if exposed
            const debugInfo = {
                url: window.location.href,
                userAgent: navigator.userAgent,
                screenSize: {
                    width: window.innerWidth,
                    height: window.innerHeight
                },
                devicePixelRatio: window.devicePixelRatio,
                hasFlutter: !!window.flutter_inappwebview || 
                           !!window.flutterConfiguration || 
                           document.body.hasAttribute('flt-renderer'),
                renderer: document.body.getAttribute('flt-renderer')
            };
            
            return debugInfo;
        }
        """
        return await self.page.evaluate(js)
    
    async def wait_for_flutter_idle(self, timeout=30000):
        """Wait for Flutter animations and async operations to complete"""
        # This is a simplistic approach - ideally you'd connect to Flutter DevTools
        try:
            # Wait for any ongoing animations to complete
            await self.page.wait_for_function("""
                () => {
                    // Check if we can detect any active animations
                    const animationElements = document.querySelectorAll('[style*="animation"], [style*="transform"]');
                    for (const el of animationElements) {
                        const style = window.getComputedStyle(el);
                        if (style.animationPlayState === 'running' || 
                            style.transitionProperty !== 'none' && style.transitionDuration !== '0s') {
                            return false;
                        }
                    }
                    return true;
                }
            """, timeout=timeout)
            return True
        except Exception as e:
            print(f"Warning: Timeout waiting for Flutter idle state: {e}")
            return False
    
    async def close(self):
        """Close the browser and clean up resources"""
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()


async def interactive_mode(tester):
    """Interactive mode for testing"""
    print("\n========= Flutter Web App Tester =========")
    print("Type commands to interact with the app:")
    print("  click <text> - Click on element with text")
    print("  type <selector> <text> - Type text into element")
    print("  screenshot [path] - Take a screenshot")
    print("  structure - Print app structure")
    print("  wait - Wait for Flutter to be idle")
    print("  exit/quit - Exit the tester")
    print("=========================================\n")
    
    while True:
        command = input("\nCommand > ").strip()
        
        if command in ['exit', 'quit']:
            break
            
        try:
            if command.startswith('click '):
                text = command[6:].strip()
                result = await tester.click_text(text)
                print(f"Click {'succeeded' if result else 'failed'}")
                
            elif command.startswith('type '):
                parts = command[5:].strip().split(' ', 1)
                if len(parts) == 2:
                    selector, text = parts
                    await tester.type(selector, text)
                    print(f"Typed '{text}' into '{selector}'")
                else:
                    print("Invalid format. Use: type <selector> <text>")
                    
            elif command.startswith('screenshot'):
                parts = command.split(' ', 1)
                path = parts[1].strip() if len(parts) > 1 else "flutter_screenshot.png"
                await tester.take_screenshot(path)
                
            elif command == 'structure':
                structure = await tester.get_app_structure()
                
                def print_structure(node, indent=0):
                    node_desc = f"{' ' * indent}● {node['tag']}"
                    if node.get('type'):
                        node_desc += f" ({node['type']})"
                    if node.get('text') and len(node['text']) < 30:
                        node_desc += f": {node['text']}"
                    print(node_desc)
                    
                    if node.get('children'):
                        for child in node['children']:
                            print_structure(child, indent + 2)
                
                print("\nApp Structure:")
                print_structure(structure)
                
            elif command == 'wait':
                print("Waiting for Flutter to be idle...")
                result = await tester.wait_for_flutter_idle()
                print(f"Wait {'completed' if result else 'timed out'}")
                
            else:
                print(f"Unknown command: {command}")
                
        except Exception as e:
            print(f"Error executing command: {e}")


async def main():
    # Create tester instance
    tester = FlutterWebTester()
    
    try:
        # Connect to the running Flutter web app
        await tester.connect()
        
        # Show Flutter debug info
        debug_info = await tester.debug_flutter_rendering()
        print("\nFlutter Debug Info:")
        for key, value in debug_info.items():
            print(f"  {key}: {value}")
        
        # Enter interactive mode
        await interactive_mode(tester)
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Clean up
        await tester.close()


if __name__ == "__main__":
    asyncio.run(main())