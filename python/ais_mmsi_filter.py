"""Stream a MarineCadastre AIS CSV from stdin to stdout, keeping only rows for
the MMSI numbers given (comma-separated, first argument).

Used by python/truth_ship_tracks.sh to pull the research-ship truth set's
positions from daily AIS files without writing the full day to disk. All
columns pass through unchanged.
"""
import csv
import sys


def main():
    keep = set(sys.argv[1].split(","))
    reader = csv.reader(sys.stdin)
    writer = csv.writer(sys.stdout, lineterminator="\n")
    header = next(reader)
    writer.writerow(header)
    col = [h.lower().replace("_", "") for h in header].index("mmsi")
    for row in reader:
        if len(row) > col and row[col] in keep:
            writer.writerow(row)


if __name__ == "__main__":
    main()
