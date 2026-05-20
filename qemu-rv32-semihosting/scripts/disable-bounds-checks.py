#!/usr/bin/env python3
"""
Disable bounds checks in wasm2c-generated code for performance experiments.
"""

import sys

def disable_bounds_checks(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check for MEMCHECK_DEFAULT32 or MEMCHECK_GENERAL definitions
        if '#define MEMCHECK_DEFAULT32' in line or '#define MEMCHECK_GENERAL' in line:
            macro_name = 'MEMCHECK_DEFAULT32' if 'DEFAULT32' in line else 'MEMCHECK_GENERAL'
            
            # Emit opening #ifdef DISABLE_BOUNDS_CHECKS guard
            result.append(f'#ifdef DISABLE_BOUNDS_CHECKS\n')
            result.append(f'#define {macro_name}(mem, a, t) (void)0\n')
            result.append(f'#else\n')
            
            # Collect the full macro definition (including line continuations with \)
            macro_lines = [line]
            while i + 1 < len(lines) and macro_lines[-1].rstrip().endswith('\\'):
                i += 1
                macro_lines.append(lines[i])
            
            # Emit the original definition
            result.extend(macro_lines)
            
            # Close the guard
            result.append(f'#endif\n')
            
            i += 1
        else:
            result.append(line)
            i += 1
    
    # Write back
    with open(filepath, 'w') as f:
        f.writelines(result)
    
    print(f"Disabled bounds checks in {filepath}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.wasm.c>")
        sys.exit(1)
    
    disable_bounds_checks(sys.argv[1])
