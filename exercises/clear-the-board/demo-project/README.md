# logtool

Summarise application logs from the command line.

## Install

    pip install .

## Usage

    logtool summary app.log          # count entries by level
    logtool errors app.log --json    # errors as JSON, one per line
    logtool tail app.log             # follow the log as it grows

## Log format

One entry per line:

    2026-11-10 09:15:02 ERROR db: connection refused

## Running the tests

    pytest
