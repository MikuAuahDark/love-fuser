from jsmin import jsmin
import json
import os
import shutil


def generate_desktop_entry(name: str, desc: str, cat: list) -> str:
    realcat = ""
    if cat != None and len(cat) > 0:
        realcat = ";".join(cat) + ";"
    return f"""[Desktop Entry]
Name={name}
Comment={desc}
Exec=run.sh %f
Type=Application
Categories={realcat}
Terminal=false
Icon=game
"""


def load_metadata(path):
    with open(path, "rb") as f:
        return json.loads(jsmin(str(f.read(), "UTF-8")))


if __name__ == "__main__":
    installdir = os.getenv("INSTALLPREFIX")
    md = load_metadata("metadata.json")
    # Copy wrapper run script
    shutil.copyfile("scripts/wrapper_script_linux.sh", f"{installdir}/bin/run.sh")
    os.chmod(f"{installdir}/bin/run.sh", 0o755)
    # Generate desktop entry file
    with open(f"{installdir}/game.desktop", "w", encoding="UTF-8") as f:
        f.write(generate_desktop_entry(md["name"], md["description"], md["linux"]["additionalCategory"]))
    # Load icon
    icon = md["linux"]["icon"]
    if icon:
        ext = icon.find(".")
        if ext != -1:
            exts = icon[ext:]
        else:
            # Assume png
            exts = ".png"
        shutil.copyfile(icon, f"{installdir}/game{exts}")
    else:
        shutil.copyfile("love/platform/unix/love.svg", f"{installdir}/game.svg")
