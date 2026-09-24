import os
import re

def remove_comments(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to remove single line (//) and multi-line (/* */) comments
    # Also handles /// doc comments
    content = re.sub(r'//.*', '', content)
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    
    # Remove empty lines left behind
    content = re.sub(r'\n\s*\n', '\n', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            remove_comments(os.path.join(root, file))
print('Comments removed.')
