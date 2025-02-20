import json
import re
from bs4 import BeautifulSoup, Tag

def evaluate_code(code, data):
    """Evaluates expressions using the provided data dictionary."""
    try:
        return str(eval(code, {}, data))
    except Exception as e:
        return f"Error: {e}"

def process_loops(element, data):
    """Recursively processes elements with x-for loops and replaces them with repeated elements."""
    for child in list(element.find_all(attrs={"x-for": True})):  # Use list() to avoid mutation issues
        loop_expression = child["x-for"].strip()
        match = re.match(r"(\w+)\s+in\s+(.+)", loop_expression)

        if not match:
            continue  # Skip invalid expressions

        var_name, list_name = match.groups()
        
        try:
            eval(list_name, {}, data)
        except Exception as e:
            return ""
        
        loop_list = eval(list_name, {}, data)
        # print("test => ", list)
        
        parent = child.parent
        for item in loop_list:
            new_element = child.__copy__()
            new_element.attrs.pop("x-for")  # Remove x-for attribute in generated elements
            updated_data = {**data, var_name: item}  # Convert item to DotDict

            process_loops(new_element, updated_data)  # Recursively process nested loops

            new_html = evaluate_template(str(new_element), updated_data)
            new_soup = BeautifulSoup(new_html, "html.parser")

            child.insert_before(new_soup)  # Insert each new element BEFORE the original

        child.extract()  # Remove the original template element

def evaluate_template(template, data):
    """Evaluates mustache-style placeholders and recursively processes loops."""
    soup = BeautifulSoup(template, "html.parser")

    # Recursively handle loops before evaluating mustache expressions
    process_loops(soup, data)

    pattern = r"\{\{(.*?)\}\}"  # Regex to find {{ ... }}

    def replacer(match):
        expression = match.group(1).strip()
        return evaluate_code(expression, data)

    return re.sub(pattern, replacer, str(soup))

def test(template, data, output):
    # Read from template file
    # print(template)
    template_code = open(template, "r").read()
    data_code = json.loads(open(data, "r").read())
    output_code = evaluate_template(template_code, data_code)
    
    print(output_code)
    