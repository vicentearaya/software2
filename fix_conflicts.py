import os
import re

files_with_markers = [
    "backend/main.py",
    "backend/models.py", 
    "backend/routers/auth.py",
    "backend/routers/ingesta.py",
    "backend/routers/readings.py",
    "backend/seed.py",
    "backend/tests/test_api.py"
]

def clean_merge_conflicts(file_path):
    """Remove merge conflict markers, keeping both versions intelligently"""
    if not os.path.exists(file_path):
        print(f"  File not found: {file_path}")
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern: <<<<<<< HEAD ... ======= ... >>>>>>> commit
    pattern = r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9]+\n'
    
    def merge_sections(match):
        head_version = match.group(1)
        incoming_version = match.group(2)
        
        # For imports: merge both lines
        if 'import' in head_version or 'from' in head_version:
            return head_version + '\n' + incoming_version
        
        # For functions/code: check if they're the same
        if head_version.strip() == incoming_version.strip():
            return head_version
        
        # Keep both versions
        return head_version + '\n' + incoming_version
    
    content = re.sub(pattern, merge_sections, content, flags=re.DOTALL)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ Cleaned: {file_path}")
        return True
    else:
        print(f"✗ Already clean: {file_path}")
        return False

print("=== Limpiando conflict markers ===\n")
for f_path in files_with_markers:
    clean_merge_conflicts(f_path)

print("\n=== Verificando que no quedan markers ===\n")
for f_path in files_with_markers:
    if os.path.exists(f_path):
        with open(f_path, 'r', encoding='utf-8') as f:
            content = f.read()
            if '<<<<<<< HEAD' in content:
                print(f"⚠️ Still has markers: {f_path}")
            else:
                print(f"✓ Clean: {f_path}")
