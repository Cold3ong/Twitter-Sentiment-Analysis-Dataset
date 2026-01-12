#!/usr/bin/env python3
import csv
import re
import sys
from collections import Counter

csv_path = r"data\stock_market_crash_2022.csv"

label_counter = Counter()
missing_text = 0
total = 0
len_counts = []
uniq_text = set()
hashtag_counter = Counter()
mention_counter = Counter()
ticker_counter = Counter()
non_ascii_counter = 0

hashtag_re = re.compile(r'#\w+')
mention_re = re.compile(r'@\w+')
ticker_re = re.compile(r'\$\w+')

with open(csv_path, 'r', encoding='utf-8', errors='replace') as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        total += 1
        if len(row) < 2:
            continue
        text = row[0].strip()
        label = row[-1].strip()
        try:
            label_val = int(label)
        except Exception:
            label_val = None
        label_counter[label_val] += 1
        if text == '':
            missing_text += 1
        len_counts.append(len(text))
        uniq_text.add(text)
        for m in hashtag_re.findall(text):
            hashtag_counter[m.lower()] += 1
        for m in mention_re.findall(text):
            mention_counter[m.lower()] += 1
        for m in ticker_re.findall(text):
            ticker_counter[m.upper()] += 1
        # count non-ascii presence
        if any(ord(c) > 127 for c in text):
            non_ascii_counter += 1

print('Total rows:', total)
print('Unique texts:', len(uniq_text))
print('Missing text:', missing_text)
print('Label distribution:')
for k,v in label_counter.most_common():
    print(' ', k, v)
print('Average text length:', sum(len_counts)/len(len_counts))
print('Max text length:', max(len_counts))
print('Min text length:', min(len_counts))
print('Rows with non-ascii characters:', non_ascii_counter)
print('Top 15 hashtags:')
for k,v in hashtag_counter.most_common(15):
    print('  ', k, v)
print('Top 10 mentions:')
for k,v in mention_counter.most_common(10):
    print('  ', k, v)
print('Top 10 tickers:')
for k,v in ticker_counter.most_common(10):
    print('  ', k, v)

# Summary statistics for distribution

from statistics import median

print('Median text length:', median(len_counts))

# Quick imbalance ratio

total_labeled = sum(v for k,v in label_counter.items() if k is not None)
if total_labeled > 0:
    for k,v in label_counter.items():
        if k is not None:
            print(f'Label {k}: {v} ({v/total_labeled:.2%})')


print('\nDone.')
