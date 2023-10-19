from pathlib import Path


def read_fixture(filename):
    return open(Path(__file__).with_name(filename)).read()
