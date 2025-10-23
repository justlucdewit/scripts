# Todolist CLI

import os
import datetime
from colorama import init, Fore, Style
import readchar

SELECTED_INDEX = 1
OPTION_LIST = [ "a", "b", "c", "d" ]

BOTTOM_MESSAGE = "Welcome to 2do CLI V1.0"

def clear_screen():
    if os.name == 'nt':
        os.system('cls')
    else:
        os.system('clear')
        
# Function for reading the todo list and parsing it into the option list
def load_option_list(date):
    global OPTION_LIST
    homedir = os.environ.get('HOME')
    
    with open(f'{homedir}/notes/work', 'r') as file:
        content = file.readlines()
        
        in_correct_date = False
        matching_lines_found = []
        for line in content:
            if in_correct_date:
                if line.strip() == "":
                    in_correct_date = False
                else:
                    line = line.removeprefix(' - ').strip()
                    matching_lines_found.append(line)
            else:
                if line.startswith(f'## {date}'):
                    in_correct_date = True
        
        OPTION_LIST = []
        for line in (matching_lines_found):
            rest = line[2:].split('|')
            
            todo_entry = {
                "status": line[0],
                "description": rest[1].strip(),
                "project": rest[0].split(" ")[1],
                "time": rest[0].split(" ")[0][1:-1]
            }
            
            OPTION_LIST.append(todo_entry)
            
def save_option_list(date):
    global OPTION_LIST
    
    homedir = os.environ.get('HOME')
    
    new_content = ""
    with open(f'{homedir}/notes/work', "r") as file:
        old_content = file.readlines()
        
        in_correct_date = False
        for line in old_content:
            if in_correct_date:
                if line.strip() == "":
                    in_correct_date = False
                    for task in OPTION_LIST:
                        new_content += f" - {task['status']} [{task['time']}] {task['project']} | {task['description']}\n"
                    new_content += "\n"
            else:
                new_content += line
                if line.startswith(f'## {date}'):
                    in_correct_date = True
    
    with open(f'{homedir}/notes/work', "w") as file:
        file.write(new_content)
  
def draw_screen(date, bottom_bar=True):
    global SELECTED_INDEX
    global OPTION_LIST
    global BOTTOM_MESSAGE
    
    clear_screen()
        
    # Get terminal size
    terminal_size = os.get_terminal_size()
    term_width = terminal_size.columns
    term_height = terminal_size.lines
        
    # Print the top menu
    date_line = f" {Fore.BLUE}{date}{Style.RESET_ALL}"
    print(date_line)
    print("-" * term_width) # Separator line
    lines_printed = 2
    
    longest_project_code_length = 0
    for todo_item in OPTION_LIST:
        lines_printed += 1
        if len(todo_item["project"]) > longest_project_code_length:
            longest_project_code_length = len(todo_item["project"])
    
    for index, todo_item in enumerate(OPTION_LIST):
        project_code_string = todo_item['project'].rjust(longest_project_code_length, " ")
        
        if index == SELECTED_INDEX:
            print(f"{Fore.GREEN} - {todo_item['status']} [{todo_item['time']}] {project_code_string}{Style.RESET_ALL} | {todo_item['description']}")
        else:
            print(f" - {todo_item['status']} [{todo_item['time']}] {project_code_string} | {todo_item['description']}")
            
    # Empty lines until 2 lines before bottom
    print("\n" * (term_height - lines_printed - 4))
    print("-" * term_width) # Separator line
    
    if bottom_bar:
        print(f" {BOTTOM_MESSAGE}")

def prompt_for_userinput(p):
    clear_screen()
    
    # Draw the screen
    date = datetime.datetime.now().strftime("%d/%m/%Y")
    draw_screen(date, False)

    return input(p)

def start_interactive_mode():
    global SELECTED_INDEX
    global OPTION_LIST
    global BOTTOM_MESSAGE
    
    date = datetime.datetime.now().strftime("%d/%m/%Y")
    
    load_option_list(date)
    
    while True:
        # Draw screen
        draw_screen(date)
        
        # Get user input
        key = readchar.readchar()
        
        # Quit
        if key == "q":
            clear_screen()
            break
        
        # Move selector up
        if key == "j":
            SELECTED_INDEX += 1
            if SELECTED_INDEX > len(OPTION_LIST) - 1:
                SELECTED_INDEX = 0
        
        # Move selector down
        if key == "k":
            SELECTED_INDEX -= 1
            if SELECTED_INDEX < 0:
                SELECTED_INDEX = len(OPTION_LIST) - 1
        
        # Set status using number keys
        status_keys_map = {
            "0": "❌",
            "1": "📋",
            "2": "🚧",
            "3": "✅"
        }
        
        if key in status_keys_map:
            new_status = status_keys_map[key]
            OPTION_LIST[SELECTED_INDEX]["status"] = new_status
            save_option_list(date)
            
        # Moving items using shift+j and shift+k
        if key == "K" and SELECTED_INDEX != 0:
            OPTION_LIST[SELECTED_INDEX], OPTION_LIST[SELECTED_INDEX - 1] = OPTION_LIST[SELECTED_INDEX - 1], OPTION_LIST[SELECTED_INDEX]
            SELECTED_INDEX -= 1
            save_option_list(date)
            
        if key == "J" and SELECTED_INDEX != len(OPTION_LIST) - 1:
            OPTION_LIST[SELECTED_INDEX], OPTION_LIST[SELECTED_INDEX + 1] = OPTION_LIST[SELECTED_INDEX + 1], OPTION_LIST[SELECTED_INDEX]
            SELECTED_INDEX += 1
            save_option_list(date)
        
        # Deleting items
        if key == "d":
            del OPTION_LIST[SELECTED_INDEX]
            BOTTOM_MESSAGE = "Item deleted..."
            save_option_list(date)
            
        # Creating new items
        if key == "c":
            description = prompt_for_userinput("Task description > ")
            todo_entry = {
                "status": "📋",
                "description": description,
                "project": "?",
                "time": "0.00"
            }
            
            OPTION_LIST.append(todo_entry)
            BOTTOM_MESSAGE = "Item created..."
            save_option_list(date)
        
        # Editing items
        if key == "p":
            project_code = prompt_for_userinput("Project code > ")
            OPTION_LIST[SELECTED_INDEX]["project"] = project_code
            BOTTOM_MESSAGE = "Changed project code..."
            save_option_list(date)
            
        if key == "t":
            project_code = prompt_for_userinput("Duration > ")
            OPTION_LIST[SELECTED_INDEX]["time"] = project_code
            BOTTOM_MESSAGE = "Changed task duration..."
            save_option_list(date)
            
        if key == "e":
            project_code = prompt_for_userinput("Description > ")
            OPTION_LIST[SELECTED_INDEX]["description"] = project_code
            BOTTOM_MESSAGE = "Changed project description..."
            save_option_list(date)
        
        # TODO: DUPLICATE ITEM
        
        # TODO: MOVING DATE
        # TODO: COPY ITEM
        # TODO: PASTE ITEM

start_interactive_mode()