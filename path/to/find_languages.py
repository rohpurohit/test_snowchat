import os

def find_languages(directory):
    languages = set()
    for root, _, files in os.walk(directory):
        for file in files:
            _, ext = os.path.splitext(file)
            if ext:
                languages.add(ext[1:])  # Add the extension without the dot
    return languages

if __name__ == "__main__":
    directory_to_scan = '.'  # Change this to the desired directory
    found_languages = find_languages(directory_to_scan)
    print("Languages found in the repository:")
    for lang in found_languages:
        print(f"- {lang}")
