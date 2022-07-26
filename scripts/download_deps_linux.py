import argparse
import os


def run_command(command: str):
    ret = os.system(command)
    if ret != 0:
        raise RuntimeError(f"Command returned {ret}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("url", type=str, help="tarball url")
    parser.add_argument("dest", type=str, help="tarball new folder name")
    args = parser.parse_args()
    # Get filename
    filename: str = os.path.basename(args.url)
    query = filename.find("?")
    if query != -1:
        filename = filename[:query]
    # Get folder name when extracting
    basename = filename[: filename.find(".tar")]
    # tar flags
    tarflags = "xzf" if filename[-3:] == ".gz" else "xf"
    # Execute
    run_command(f"curl -Lfo {filename} {args.url}")
    run_command(f"tar {tarflags} {filename}")
    run_command(f"mv {basename} {args.dest}")
