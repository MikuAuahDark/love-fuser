import argparse
import json

from jsmin import jsmin

if __name__ == "__main__":
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--set-output", action="store_true", help="Output to GitHub Actions variable")
    parser.add_argument("name", type=str, nargs="+", help="Variable to retrieve")
    args = parser.parse_args()
    # Load metadata.json
    with open("metadata.json", "r", encoding="UTF-8") as f:
        metadata = json.loads(jsmin(f.read()))
    for name in args.name:
        # Special case: Prevent "windows" and "android" fields
        if name == "windows" or name == "android":
            raise RuntimeError("'windows' and 'android' fields are forbidden.")
        else:
            value = metadata[name] or ""
        # Print
        if args.set_output:
            print(f"::set-output name={name}::{value}")
        else:
            print(value)
