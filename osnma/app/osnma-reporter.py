#!/usr/bin/env python
import sys
sys.path.insert(0, '..')

import argparse
import datetime
import re
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.lines import Line2D

import util.gst as gst

DESCRIPTION="""
Produce visualization and compute statistics from authentication events.
"""

# Note: growing Python arrays dynamically is faster than growing numpy arrays,
# hence the 'read_X' use Python arrays inside the loops and only at the end
# convert the result into numpy arrays

def read_auths(log):
    """Read successful authentication from a log.

    :log: file with the output of the FGI-OSNMA.
    :returns: successful authentications as numpy array.
    Columns: wn, tow, prnd, prna, adkd.

    """
    pattern = re.compile(r'AUTH_OK: wn: (\d+), tow: (\d+), svid: (\d+), prna: (\d+), adkd: (\d+)')

    res = []
    with open(log, 'r') as f:
        for line in f:
            m = pattern.match(line)
            if m:
                wn = int(m.group(1))
                tow = int(m.group(2))
                prnd = int(m.group(3))
                prna = int(m.group(4))
                adkd = int(m.group(5))
                epoch = gst.gst2datetime(wn, tow)
                epoch = gst.gst2timestamp(wn, tow)
                record = [epoch, prnd, prna, adkd]
                res.append(record)

    # When empty, return a correctly shaped empty numpy array
    if len(res) == 0:
        res = np.zeros((0, 4))
    else:
        res = np.array(res)
    return np.array(res)

def read_invalid_tags(log):
    """Read successful authentication from a log.

    :log: file with the output of the FGI-OSNMA.
    :returns: failed authentications as numpy array.
    Columns: timestamp, prnd, prna, adkd.

    """
    pattern = re.compile(r'INVALID_TAG: wn: (\d+), tow: (\d+), svid: (\d+), prna: (\d+), adkd: (\d+)')
    res = []
    with open(log, 'r') as f:
        for line in f:
            m = pattern.match(line)
            if m:
                wn = int(m.group(1))
                tow = int(m.group(2))
                prnd = int(m.group(3))
                prna = int(m.group(4))
                adkd = int(m.group(5))
                epoch = gst.gst2timestamp(wn, tow)
                record = [epoch, prnd, prna, adkd]
                res.append(record)

    # When empty, return a correctly shaped empty numpy array
    if len(res) == 0:
        res = np.zeros((0, 4))
    else:
        res = np.array(res)

    # Make invalid ADKD=4 tags show up as PRND=0 for visualization purposes
    is_adkd4 = res[:, -1] == 4
    res[is_adkd4, 1] = 0
    return res

def read_crc_fails(log):
    """Read successful authentication from a log.

    :log: file with the output of the FGI-OSNMA.
    :returns: crc failures as numpy array.
    Columns: epoch, svid

    """
    pattern = re.compile(r'CRC_ERROR: wn: (\d+), tow: (\d+), svid: (\d+)')
    res = []
    with open(log, 'r') as f:
        for line in f:
            m = pattern.match(line)
            if m:
                wn = int(m.group(1))
                tow = int(m.group(2))
                svid = int(m.group(3))
                epoch = gst.gst2timestamp(wn, tow)
                record = [epoch, svid]
                res.append(record)

    # When empty, return a correctly shaped empty numpy array
    if len(res) == 0:
        res = np.zeros((0, 2))
    else:
        res = np.array(res)
    return res

def read_simultaneous_authentication_count(auths):
    """Return the number of simultaneous authentications from the list of
    authentications. Only ADKD=0 authentications are considered.

    :auths: authentications as returned from read_auths (fields: timestamp,
    prnd, prna, adkd)
    :returns: numpy array with columns (epoch, count)

    """
    available_epochs = np.unique(auths[:, 0])
    epoch0 = int(available_epochs[0])
    epochs = np.arange(epoch0, available_epochs[-1]+1, 30)

    # Intermediate data structure that makes computing this much more efficient
    # Cell i,j contains the authentication status (authentication or not) of
    # SVID i during the j:th subframe
    authentication_status = np.zeros((36, len(epochs)), dtype=bool)

    # Iterate through non ADKD=4 authentications
    for auth in auths[auths[:, -1] != 4]:
        ts = int(auth[0])
        # SVID 1 should be at index 0 etc
        prnd_id = int(auth[1]) - 1
        n_subframe = (ts - epoch0) // 30
        authentication_status[prnd_id, n_subframe] = 1

    counts = authentication_status.sum(axis=0)
    res = np.concatenate((epochs.reshape((-1, 1)), counts.reshape((-1, 1))), axis=1)
    return res

def read_osnma_counts(log):
    """Read the OSNMA transmitter counts from the log file

    :log: FGI-OSNMA output log
    :returns: numpy array with columns (epoch, count)

    """
    # Parse the PRNAs from the log: only transmitters are in the PRNA (by
    # definition) and all transmitters ae guaranteed to be in a authentication
    # event (transmitting satellite will always have a self-auth attempt,
    # whether it succeeds or not). The exception to this if the tag sequence
    # verification fails, so that is taken into account separately.
    pattern = re.compile(r'.*wn: (\d+), tow: (\d+), svid: (\d+), prna: (\d+), adkd: (\d+)')
    pattern2 = re.compile(r'TAG_SEQUENCE_VERIFICATION_FAILED: wn: (\d+), tow: (\d+), svid: (\d+)')
    authattempts = []
    fd = open(log, 'r')
    for line in fd:
        m = pattern.match(line)
        m2 = pattern2.match(line)
        if m:
            wn = int(m.group(1))
            tow = int(m.group(2))
            prna = int(m.group(4))
            epoch = gst.gst2timestamp(wn, tow)
            authattempts.append([epoch, prna])
        if m2:
            wn = int(m2.group(1))
            tow = int(m2.group(2))
            prna = int(m2.group(3))
            epoch = gst.gst2timestamp(wn, tow)
            authattempts.append([epoch, prna])

    fd.close()
    authattempts = np.array(authattempts)

    available_epochs = np.unique(authattempts[:, 0])
    epoch0 = int(available_epochs[0])
    epochs = np.arange(epoch0, available_epochs[-1]+1, 30)

    # Intermediate data structure that makes computing this much more efficient
    # Cell i,j contains the transmitting status (transmitting OSNMA or not) of
    # SVID i during the j:th subframe
    transmitting_status = np.zeros((36, len(epochs)), dtype=bool)

    for attempt in authattempts:
        ts = int(attempt[0])
        # SVID 1 should be at index 0 etc
        prna_id = int(attempt[1]) - 1
        n_subframe = (ts - epoch0) // 30
        transmitting_status[prna_id, n_subframe] = 1

    counts = transmitting_status.sum(axis=0)
    res = np.concatenate((epochs.reshape((-1, 1)), counts.reshape((-1, 1))), axis=1)
    return res

def read_log_file(log, calc_auth_counts=False):
    """Read authentication and other events from a log file.

    :log: file to read the events from
    :calc_auth_counts: calculate authentication counts over time. Computing
    this over large datasets can take significant amount of time.
    :returns: (auths, invalid_tags, crc_fails, auth_counts)

    """
    print("reading file")
    auths = read_auths(log)
    print("authentications read")
    invalid_tags = read_invalid_tags(log)
    print("authentication failures read")
    crc_fails = read_crc_fails(log)
    print("CRC failures read")
    osnma_counts = read_osnma_counts(log)
    print("OSNMA transmitters read")
    auth_counts = None

    if calc_auth_counts:
        auth_counts = read_simultaneous_authentication_count(auths)
        print("Simultaneous authentication counts read")

    return (auths, invalid_tags, crc_fails, auth_counts, osnma_counts)

def dateformatter(epoch, pos=None):
    date = datetime.datetime.fromtimestamp(epoch)
    return date.strftime("%b") + ". " + date.strftime("%d") + "th\n" + date.strftime("%H:%M")

def plot_authentication_timeline(data):
    """Produce a timeline with all of the authentication information in it.

    :data: triple of numpy arrays (auths, invalid_tags, failed_crcs) as
    received from read_log_file
    """
    auths, invalid_tags, failed_crcs, _, _ = data
    is_crossauth = auths[:, 1] != auths[:, 2]
    not_crossauth = np.logical_not(is_crossauth)
    is_adkd12 = auths[:, 3] == 12
    is_adkd4 = auths[:, 3] == 4
    is_adkd0 = auths[:, 3] == 0

    plt.rcParams["font.size"] = 16
    plt.gca().xaxis.set_major_formatter(dateformatter)
    s = 4
    # Separate some of the lines a little to improve readability
    linediff = 0.25

    plt.grid(1)
    plt.title(f"FGI-OSNMA: Satellite authentication status timeline")
    plt.ylabel("SVID")
    plt.yticks(np.arange(1, 37, dtype=int))

    sel = np.logical_and(is_adkd12, np.logical_not(is_crossauth))
    plt.scatter(auths[sel, 0], auths[sel, 1],
                c="#ff00ff", s=s)
    sel = np.logical_and(is_adkd12, is_crossauth)
    plt.scatter(auths[sel, 0], auths[sel, 1],
                c="#aaaa00", s=s)

    # ADKD=0
    sel = np.logical_and(not_crossauth, is_adkd0)
    plt.scatter(auths[sel, 0], auths[sel, 1] - linediff,
                c="#0000aa", s=s,
                label="Satellite authenticated itself (ADKD=0)")
    sel = np.logical_and(is_crossauth, is_adkd0)
    plt.scatter(auths[sel, 0], auths[sel, 1] + linediff,
                c="#00aa00", s=s)
    # ADKD=4
    sel = is_adkd4
    plt.scatter(auths[sel, 0], np.zeros(sel.sum()),
                c="black", s=s)

    # Failed to authenticate tag
    offsets = -linediff/2*np.ones(len(invalid_tags))
    is_selfauth = invalid_tags[:, 1] == invalid_tags[:, 2]
    offsets[is_selfauth] = -linediff / 2
    plt.scatter(invalid_tags[:, 0], invalid_tags[:, 1] + offsets,
                c="#cc0000", s=4*s,
                marker='x')

    # CRCs
    plt.scatter(failed_crcs[:, 0], failed_crcs[:, 1] + linediff,
                c="#cc0000", s=4*s,
                marker='|')

    markersize = 10
    custom_markers = [
            Line2D([0], [0], lw=0, color='w', markerfacecolor="#ff00ff", marker='o', markersize=markersize),
            Line2D([0], [0], lw=0, color='w', markerfacecolor="#aaaa00", marker='o', markersize=markersize),
            Line2D([0], [0], lw=0, color='w', markerfacecolor="#0000aa", marker='o', markersize=markersize),
            Line2D([0], [0], lw=0, color='w', markerfacecolor="#00aa00", marker='o', markersize=markersize),
            Line2D([0], [0], lw=0, color='w', markerfacecolor="black", marker='o', markersize=markersize),
            Line2D([0], [0], lw=0, color='r', markerfacecolor="#cc0000", marker='x', markersize=markersize),
            Line2D([0], [0], lw=0, color='r', markerfacecolor="#cc0000", marker='|', markersize=markersize),
            ]

    plt.legend(custom_markers, 
              ['Slow MAC self-authentication (ADKD=12)',
               'Slow MAC cross-authentication (ADKD=12)',
               'Satellite authenticated itself(ADKD=0)',
               'Cross authenticated satellite(ADKD=0)',
               'Galileo timing authentication (ADKD=4)',
               'Tag authentication failed',
               'Page with failed CRC',
               ],
               loc="upper right", bbox_to_anchor=(1.005, 1.005))
    plt.show()

def print_statistics(data):
    """Print some statistics related to authentication events.

    :data: data as received from read_log_file

    """
    auths, invalid_tags, failed_crcs, auth_counts, osnma_counts = data

    epochs = np.arange(auths[0, 0], auths[-1, 0] + 1, 30, dtype=int)
    # Epochs where you have 4 or more satellites vs all epochs
    # Note: auth counts already contains non-ADKD=4 authentications
    fix_ratio = np.sum(auth_counts[:, 1] >= 4) / len(epochs)
    print("% of time when 4 or more satellites are authenticated:", fix_ratio)

    p = [5, 10, 25, 50, 75, 90, 95, 100]
    percentiles = np.percentile(auth_counts[:, 1], p)
    print("Percentiles")
    print(p)
    print(percentiles)
    print("Mean simultaneous authenticated satellites:", auth_counts[:, 1].mean())
    print("Max simultaneous authenticated satellites:", auth_counts[:, 1].max())
    print("Min simultaneous authenticated satellites:", auth_counts[:, 1].min())

    print("Authentications ADKD=0:", (auths[:, -1] == 0).sum())
    print("Authentications ADKD=4:", (auths[:, -1] == 4).sum())
    adkd4_auth_epochs = np.unique(auths[auths[:, -1] == 4, 0])
    # You are supposed to get ADKD authentications once every two subframes, hence the division by 2
    print("Authentication % ADKD=4:",  len(adkd4_auth_epochs) / (len(epochs) // 2))
    print("Authentications ADKD=12:", (auths[:, -1] == 12).sum())

    print("Self-authentications ADKD=0:", (auths[:, 1] == auths[:, 2]).sum())
    print("Cross-authentications ADKD=0:", (auths[:, 1] != auths[:, 2]).sum())
    print("Ratio self-auths/all-auths", (auths[:, 1] == auths[:, 2]).mean())

    print("Authentications failed:", invalid_tags.shape[0])

    print("Failed CRCs:", failed_crcs.shape[0])

def plot_auth_count_timeline(auth_count):
    """Produce a visualization with the number of simultaneous authenticated
    satellites over time.

    :auth_count: authentication counts as gained from read_log_file

    """
    plt.rcParams["font.size"] = 21
    plt.grid()
    plt.gca().xaxis.set_major_formatter(dateformatter)
    plt.ylabel("Number of simultaneous authenticated satellites")
    plt.plot(auth_count[:, 0], auth_count[:, 1], c="b", linewidth=1)
    plt.show()

def plot_osnma_transmitter_count_timeline(osnma_counts):
    """Produce a visualization with the number of satellites transmitting OSNMA
    data over time.

    :osnma_counts: OSNMA transmitter counts as gained from read_log_file

    """
    plt.rcParams["font.size"] = 21
    plt.grid()
    plt.gca().xaxis.set_major_formatter(dateformatter)
    plt.ylabel("Number of satellites transmitting OSNMA data")
    plt.plot(osnma_counts[:, 0], osnma_counts[:, 1], c="b", linewidth=1)
    plt.show()

def main(args):
    to_calc_auth_counts = args.all or args.auth_count_timeline
    data = read_log_file(args.input, to_calc_auth_counts)

    if args.all or args.timeline:
        plot_authentication_timeline(data)
    if args.all or args.osnma_transmitter_count:
        plot_osnma_transmitter_count_timeline(data[4])
    if args.all or args.stats:
        print_statistics(data)
    if to_calc_auth_counts:
        plot_auth_count_timeline(data[3])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument("-i", "--input", type=str, required=True,
                        help="Authentication events as received from osnma-cli to visualize")
    parser.add_argument("-t", "--timeline", action="store_true",
                        help="Produce authentication status timeline")
    parser.add_argument("-s", "--stats", action="store_true",
                        help="Report statistics")
    parser.add_argument("-c", "--auth-count-timeline", action="store_true",
                        help="Produce timeline of simultaneous authenticated satellites")
    parser.add_argument("-o", "--osnma-transmitter-count", action="store_true",
                        help="Produce timeline of number of satellites transmitting OSNMA data")

    parser.add_argument("-a", "--all", action="store_true",
                        help="Report all")
    args = parser.parse_args()

    main(args)
