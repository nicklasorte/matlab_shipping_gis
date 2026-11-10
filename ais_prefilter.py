"""Stream a MarineCadastre AIS CSV from stdin to stdout, keeping only rows whose
reported length is at least MIN_LENGTH meters (first argument).

Used by download_ais_day_rev1.m so a day's AIS file is never written to disk in
full (about 1 GB as CSV); the kept rows are about a tenth of that. The csv module
handles quoted vessel names that contain commas, which a plain grep or awk
split would not. All columns are passed through unchanged; MATLAB applies the
full ship filter afterward.
"""
import csv
import sys


def main():
    min_length = float(sys.argv[1])
    reader = csv.reader(sys.stdin)
    writer = csv.writer(sys.stdout, lineterminator="\n")
    header = next(reader)
    writer.writerow(header)
    key = [h.lower().replace("_", "") for h in header]
    col = key.index("length")
    for row in reader:
        try:
            if float(row[col]) >= min_length:
                writer.writerow(row)
        except (ValueError, IndexError):
            continue  # blank or malformed length: the ship filter would drop it anyway


if __name__ == "__main__":
    main()
