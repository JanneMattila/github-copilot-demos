---
name: hello
description: A simple greeting skill that prints "Hello" to the console. Use this skill when the user asks you to say hello, greet them, or test that skills are working.
allowed-tools: shell
---

# Hello Skill

When invoked, run the `hello.sh` script (on Linux/macOS) or `hello.ps1` script (on Windows) from this skill's directory.

## Usage

- On **Linux/macOS**: Run `bash hello.sh`
- On **Windows**: Run `powershell -File hello.ps1`

The script accepts an optional name argument. If provided, greet that person. If not, greet "World".

### Examples

```bash
# Default greeting
bash hello.sh
# Output: Hello, World!

# Named greeting
bash hello.sh Alice
# Output: Hello, Alice!
```
