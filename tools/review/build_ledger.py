#!/usr/bin/env python3
"""Build the numbers ledger for the matlab_shipping_gis working paper.

Extracts every number from the paper body, tables, captions, and alt text,
classifies labels, ties each data number to a source in REPO/outputs (or a code
constant, or a cited outside source), and checks that the printed value matches
the source after rounding. Also runs consistency checks (repeated numbers, table
totals and percentages, figure and table order).

Usage: python3 -I build_ledger.py
Writes: /tmp/agent_scratch/ledger/numbers_ledger.csv and checks.json
"""
import csv, json, math, re, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract import tokens, PAPER
from labels import label_for
from sources import D, logval, R, O
from prose_map import PROSE, generic   # (line, printed[, occ]) -> spec

OUT = '/tmp/agent_scratch/ledger/numbers_ledger.csv'
rows = []

def num(s):
    return float(str(s).replace(',', ''))

def decimals(s):
    s = str(s).replace(',', '')
    return len(s.split('.')[1]) if '.' in s else 0

def compare(printed, exact, tol=None, pct=False):
    """Return (status, rounding note)."""
    if exact is None or (isinstance(exact, float) and math.isnan(exact)):
        return 'no_source', ''
    p = num(printed)
    e = float(exact) * (100.0 if pct else 1.0)
    if tol is None:
        tol = 0.5 * 10 ** (-decimals(printed)) + 1e-9
        note = f'rounded to {decimals(printed)} decimal(s)' if decimals(printed) else 'rounded to integer'
        if abs(e - round(e)) < 1e-9 and decimals(printed) == 0:
            note = 'exact'
    else:
        note = f'approximate, tolerance +/-{tol:g}'
    return ('match' if abs(p - e) <= tol else 'mismatch'), note

def add(tok, source_file='', field='', exact='', status='', rounding=''):
    rows.append(dict(line=tok['line'], section=tok['section'], printed=tok['printed'],
                     context=tok['ctx'], source_file=source_file, source_field=field,
                     exact_value=('' if exact is None else exact), rounding=rounding, status=status))

def add_cmp(tok, source_file, field, exact, tol=None, pct=False, note=''):
    st, rn = compare(tok['printed'], exact, tol, pct)
    if note:
        rn = (rn + '; ' + note) if rn else note
    ex = '' if exact is None else (round(float(exact) * (100 if pct else 1), 6))
    add(tok, source_file, field, ex, st, rn)

# ---------------------------------------------------------------- tables
lines = open(PAPER, encoding='utf-8').read().split('\n')
table_of_line = {}
cur = None
for i, l in enumerate(lines, 1):
    m = re.match(r'\*\*Table (\d+)\.', l)
    if m:
        cur = int(m.group(1)); continue
    if l.startswith('|') and cur:
        table_of_line[i] = cur
    elif l.strip() and not l.startswith('|'):
        if cur and i - 1 in table_of_line:
            cur = None

def col_of(tok):
    return tok['text'][:tok['start']].count('|') - 1

def cells(line_no):
    return [c.strip() for c in lines[line_no - 1].strip().strip('|').split('|')]

def is_header(line_no):
    t = table_of_line[line_no]
    first = min(k for k, v in table_of_line.items() if v == t)
    return line_no in (first, first + 1)

TABLE_TOTALS = []   # recomputation checks

def by_label(lst, key, val):
    for r in lst:
        if r[key] == val:
            return r
    return None

pp_by_name = {r['port']: r for r in D['pp']}
geo_by_name = {r['port']: r for r in D['geo_ports']}
corr_by_label = {r['label']: r for r in D['corr']}
corr_alias = {'Chesapeake Bay': 'Chesapeake Bay to Baltimore'}

def find_port(d, name):
    if name in d: return d[name]
    for k in d:
        if k.startswith(name + ','): return d[k]
    return None

def table_token(tok):
    t = table_of_line[tok['line']]
    ln = tok['line']
    if is_header(ln):
        k = label_for(tok)
        add(tok, status='label', rounding=k or 'table header')
        return
    c = col_of(tok)
    row = cells(ln)
    PF = 'outputs/2024_2025/'
    if t == 1 and c == 0:
        add_cmp(tok, 'init_shipping_zone_rev1.m:41', 'p.filt.min_length_m', 100); return
    if t == 1:
        day = '10-Jul-2024' if c in (1, 2) else '09-Jul-2025'
        f = [r for r in D['funnel'] if r['day'] == day]
        step = ['All reports', 'Ship type kept', 'and length 100 m or more',
                'and IMO number (or military or law enforcement)', 'and inside the analysis grid'].index(row[0])
        fld = 'reports' if c in (1, 3) else 'ships'
        add_cmp(tok, PF + 'ais_filter_funnel.csv', f'{fld} (step {step + 1}, {day})', num(f[step][fld]))
    elif t == 2:
        day = '10-Jul-2024' if c == 1 else '09-Jul-2025'
        f = [r for r in D['bytype'] if r['day'] == day]
        if row[0] == 'Total':
            s = sum(int(r['ships']) for r in f)
            fun = [r for r in D['funnel'] if r['day'] == day][-1]
            add_cmp(tok, PF + 'ais_filter_by_type.csv', f'sum of ships ({day}); funnel last step = {fun["ships"]}', s)
            TABLE_TOTALS.append(('Table 2 total ' + day, tok['printed'], s, int(fun['ships'])))
        else:
            g = {'Cargo': 'Cargo', 'Tanker': 'Tanker', 'Passenger': 'Passenger', 'Towing': 'Towing',
                 'Military': 'Military', 'Law enforcement': 'Law enforcement', 'Dredging': 'Dredging',
                 'Other and unknown': 'Other and unknown'}[row[0]]
            r = [x for x in f if x['group'].startswith(g)][0]
            add_cmp(tok, PF + 'ais_filter_by_type.csv', f'ships, {r["group"]}, {day}', num(r['ships']))
    elif t == 3:
        if c == 0:   # numbers inside the Source text (4, 2, 50, 73)
            spec = {'4': ('init_shipping_zone_rev1.m:57', 'p.min_unique_ships', 4),
                    '2': ('init_shipping_zone_rev1.m:61', 'p.port_min_unique_ships', 2),
                    '50': ('init_shipping_zone_rev1.m:60', 'p.port_relax_km', 50),
                    '73': (PF + 'shipping_zone_2024_2025_run.log', 'Port approaches ... 73 deep-draft ports', 73)}[tok['printed']]
            add_cmp(tok, *spec)
            return
        vals = {'AIS cells': logval('log48', r'AIS source cells \(unique_ships rule\): (\d+)'),
                'Port approaches': logval('log48', r'Port approaches: (\d+)'),
                'NOAA fairways': logval('log48', r'Fairway cells: \d+ \((\d+) not'),
                'S-band racons': logval('log48', r'Racons: \d+ in the grid \((\d+) cells'),
                }
        if row[0].startswith('Total'):
            s = sum(vals.values())
            add_cmp(tok, PF + 'shipping_zone_2024_2025_run.log', 'sum of the four source counts', s)
            TABLE_TOTALS.append(('Table 3 total', tok['printed'], s, None))
        else:
            k = [k for k in vals if row[0].startswith(k)][0]
            add_cmp(tok, PF + 'shipping_zone_2024_2025_run.log', k, vals[k])
    elif t == 4:
        name = row[1]
        g = find_port(geo_by_name, name)
        if c == 0:
            order = sorted(D['geo_ports'], key=lambda r: -int(r['ships']))
            exact = [r['port'] for r in order].index(g['port']) + 1
            add_cmp(tok, PF + 'viz/geo_ports.csv', 'rank by ships (descending)', exact)
        elif c == 2:
            add_cmp(tok, PF + 'viz/geo_ports.csv', 'rank (USACE total-tonnage rank)', num(g['rank']))
        else:
            fld = {3: 'ships', 4: 'tanker', 5: 'cargo', 6: 'passenger', 7: 'government'}[c]
            add_cmp(tok, PF + 'viz/geo_ports.csv', f'{fld} ({name})', num(g[fld]))
    elif t == 5:
        name = row[1]
        p = find_port(pp_by_name, name)
        if p is None:
            add(tok, status='no_source', rounding=f'port {name!r} not found in principal_port_check'); return
        f = PF + 'shipping_zone_2024_2025_principal_port_check.csv'
        if c == 0:
            add_cmp(tok, f, f'rank ({name})', num(p['rank']))
        elif c == 2:
            add_cmp(tok, f, f'foreign_tons/1e6 ({name})', num(p['foreign_tons']) / 1e6)
        elif c == 3:
            add_cmp(tok, f, f'gap_to_ship_cell_km ({name})', num(p['gap_to_ship_cell_km']))
        else:
            add(tok, status='label', rounding='unexpected number in table cell')
    elif t == 6:
        lab = corr_alias.get(row[0], row[0])
        r = corr_by_label.get(lab)
        f = PF + 'viz/corridor_summary.csv'
        if c == 1:   # "22 km below Richmond"
            mk = [m for m in D['marks'] if m['corridor'] == 'james' and m['name'] == 'Richmond'][0]
            add_cmp(tok, PF + 'viz/corridor_marks.csv', 'james Richmond off_path_km (route end to Richmond)', num(mk['off_path_km']))
            return
        fld = {2: 'length_km', 3: 'ships_entrance', 4: 'ships_head', 5: 'share_head', 6: 'ships_head_y0', 7: 'ships_head_y1'}[c]
        if fld == 'share_head':
            exact = num(r['ships_head']) / num(r['ships_entrance'])
            add_cmp(tok, f, f'ships_head/ships_entrance ({lab}); file share_head={r["share_head"]}', exact, pct=True)
            TABLE_TOTALS.append((f'Table 6 share {lab}', tok['printed'], round(100 * exact, 2), None))
        else:
            add_cmp(tok, f, f'{fld} ({lab})', num(r[fld]))
    elif t == 7:
        if c == 1:
            b = [x for x in D['bands'] if row[0].startswith(x['f_low_mhz'])][0]
            add_cmp(tok, PF + 'shipping_zone_2024_2025_band_zones.csv', f'distance_km ({row[0]} MHz)', num(b['distance_km']))
        else:
            add(tok, status='label', rounding='band edge (MHz)')
    elif t == 8:
        rule = row[0]
        H = D['rules']['hawaii']; C = D['rules']['calibration']
        f = PF + 'islands/route_rules.json'
        if c == 0:
            spec = {'4': ('init_shipping_zone_rev1.m:57', 'p.min_unique_ships', 4),
                    '2': (f, 'hawaii.min_ships_2 (rule definition)', 2),
                    '6': ('init_shipping_zone_hawaii_rev1.m:47', 'p.min_ship_days', 6),
                    '3': (f, 'calibration.T (NOAA transit cutoff)', C['T'])}.get(tok['printed'])
            if spec: add_cmp(tok, *spec)
            else: add(tok, status='label', rounding=label_for(tok) or 'year in source title')
            return
        key = ('min_ships_4' if rule.startswith('At least 4') else 'min_ships_2' if rule.startswith('At least 2')
               else 'ship_days_6' if 'ship-days' in rule else 'noaa_3')
        if c == 1:
            exact = {'min_ships_4': 1.0, 'ship_days_6': C['ship_days_jaccard']['6'], 'noaa_3': C['noaa_jaccard']['3']}.get(key)
            add_cmp(tok, f, f'calibration Jaccard ({key}); 1.00 is the reference rule itself', exact)
        elif c == 2:
            add_cmp(tok, f, f'hawaii.{key}.route_cells', H[key]['route_cells'])
        elif c == 3:
            add_cmp(tok, f, f'hawaii.{key}.ports_connected_to_hub', H[key]['ports_connected_to_hub'])

# ---------------------------------------------------------------- main loop
toks = tokens()
heading_lines = {i for i, l in enumerate(lines, 1) if l.startswith('#')}
unmapped = []
occ_count = {}
for tok in toks:
    ln = tok['line']
    if ln in heading_lines:
        add(tok, status='label', rounding='section heading'); continue
    if ln in table_of_line:
        table_token(tok); continue
    key = (ln, tok['printed']); occ_count[key] = occ_count.get(key, 0) + 1
    spec = PROSE.get((ln, tok['printed'], occ_count[key])) or PROSE.get(key)
    if spec is None:
        k = label_for(tok)
        if k:
            add(tok, status='label', rounding=k); continue
        spec = generic(tok)
    if spec is None:
        unmapped.append(tok)
        add(tok, status='no_source', rounding='no source found in REPO outputs, code, or a cited outside source')
        continue
    spec(tok, add, add_cmp)

# ---------------------------------------------------------------- consistency checks
checks = {}
# 1. Same quantity printed in more than one place (concept groups; values read from the ledger)
by_lp = {}
for r in rows:
    by_lp.setdefault((r['line'], r['printed']), []).append(r)
CONCEPTS = {
    'Ships within 3 km of Baton Rouge, 2025': [(125, '139'), (274, '138'), (269, '138')],
    'Ships within 3 km of Baton Rouge, both years': [(125, '263'), (266, '262'), (474, '262'), (644, '262')],
    'AIS route cells (4+ ships, tug-barges included)': [(104, '658,865'), (436, '658,867')],
    'Ships per filtered ship, 1 in N': [(57, '12'), (498, '11')],
    'Inland river ports, nearest distance to route (km)': [(243, '50'), (452, '48')],
    'Route extent above Baton Rouge (km)': [(125, '35'), (460, '5')],
    'Baton Rouge river km above Head of Passes': [(277, '356'), (277, '352'), (460, '352')],
    'Precision at 100 m (%)': [(85, '99.6'), (116, '99.6'), (506, '99.6')],
    'Recall at 100 m (%)': [(85, '98.1'), (116, '98.1'), (506, '98.1')],
    'Matched ships (GT check)': [(85, '4,129'), (87, '4,129'), (116, '4,129'), (510, '4,129')],
    'Deep-draft ports on the route network': [(120, '69'), (163, '69')],
    'Hawaii route cells': [(341, '7,310'), (348, '7,310'), (364, '7,310')],
    'Alaska ship-track cells': [(373, '26,983'), (404, '26,983')],
    'PR/USVI ship-track cells (MATLAB)': [(412, '41,237'), (428, '41,237')],
    'Galveston ships within 10 km': [(143, '2,953'), (554, '2,953')],
    'Mississippi corridor ships at entrance': [(266, '2,095'), (644, '2,095')],
    'Mississippi ships reaching Baton Rouge, continuation vs Table 6': [(474, '300'), (474, '262')],
    'Share reaching head, Mississippi: Table 6 vs Figure A-4b (%)': [(266, '13'), (468, '7')],
}
conc = []
for name, keys in CONCEPTS.items():
    vals = []
    for k in keys:
        for r in by_lp.get(k, []):
            vals.append((r['line'], r['printed'], r['source_file'], str(r['exact_value'])))
    distinct = sorted({num(v[1]) for v in vals})
    conc.append({'concept': name, 'values': vals, 'agree': len(distinct) == 1})
checks['repeated_numbers'] = conc
# 1b. Same source field printed with different values anywhere
fld = {}
for r in rows:
    if r['status'] in ('match', 'mismatch') and r['source_field']:
        fld.setdefault((r['source_file'], r['source_field']), set()).add(r['printed'])
checks['same_field_different_print'] = [(k[0], k[1], sorted(v)) for k, v in fld.items()
                                         if len({round(num(x), 6) for x in v}) > 1]
# 2. Table totals and percentages
checks['table_totals'] = TABLE_TOTALS
t4 = []
for ln, t in table_of_line.items():
    if t == 4 and not is_header(ln):
        c = cells(ln); parts = sum(num(x) for x in c[4:8])
        t4.append((c[1], num(c[3]), parts, parts <= num(c[3])))
checks['table4_type_columns_le_total'] = t4
t5_names = [cells(ln)[1] for ln, t in table_of_line.items() if t == 5 and not is_header(ln)]
deep_names = [r['port'] for r in D['pp'] if r['type'] != 'I' and float(r['foreign_tons']) >= 1e6]
t5_rows = [find_port(pp_by_name, n)['port'] for n in t5_names if find_port(pp_by_name, n)]
checks['table5_vs_deep_draft'] = {'table_rows': len(t5_names), 'deep_draft_in_source': len(deep_names),
    'missing_from_table': sorted(set(deep_names) - set(t5_rows)), 'extra_in_table': sorted(set(t5_rows) - set(deep_names)),
    'ranks_ascending': [int(cells(ln)[0]) for ln, t in sorted(table_of_line.items()) if t == 5 and not is_header(ln)] ==
                       sorted(int(cells(ln)[0]) for ln, t in table_of_line.items() if t == 5 and not is_header(ln)),
    'on_network_yes': sum(1 for ln, t in table_of_line.items() if t == 5 and not is_header(ln) and cells(ln)[4] == 'Yes'),
    'yes_no_match_source': all((cells(ln)[4] == 'Yes') == (find_port(pp_by_name, cells(ln)[1])['reached'] == '1' and find_port(pp_by_name, cells(ln)[1])['on_route_network'] == '1')
                               for ln, t in table_of_line.items() if t == 5 and not is_header(ln)),
    'in25_match_source': all((cells(ln)[5] == 'Yes') == (find_port(pp_by_name, cells(ln)[1])['in_25km_zone'] == '1')
                             for ln, t in table_of_line.items() if t == 5 and not is_header(ln))}
t6_order = [num(cells(ln)[5].rstrip('%')) for ln, t in sorted(table_of_line.items()) if t == 6 and not is_header(ln)]
checks['table6_sorted_by_share_desc'] = t6_order == sorted(t6_order, reverse=True)
# 3. Figure and table numbering and first citation
caps, refs = [], {}
for i, l in enumerate(lines, 1):
    m = re.match(r'\*\*(Figure|Table) ((?:A-)?\d+[a-c]?)\.', l)
    if m:
        caps.append((m.group(1), m.group(2), i)); continue
    for m in re.finditer(r'\b(Figures?|Tables?)\s+((?:A-)?\d+[a-c]?)(?:\s+and\s+((?:A-)?\d+[a-c]?))?', l):
        kind = 'Figure' if m.group(1).startswith('Fig') else 'Table'
        for n in (m.group(2), m.group(3)):
            if n: refs.setdefault((kind, n), i)
def order_key(n):
    m = re.match(r'(A-)?(\d+)([a-c]?)', n); return (1 if m.group(1) else 0, int(m.group(2)), m.group(3))
fig = []
prev = {}
for kind, n, ln in caps:
    first = refs.get((kind, n))
    seq_ok = kind not in prev or order_key(n) > order_key(prev[kind])
    prev[kind] = n
    fig.append({'item': f'{kind} {n}', 'caption_line': ln, 'first_cited_line': first,
                'cited_before': (first is not None and first < ln), 'in_order': seq_ok})
checks['figure_table_order'] = fig
json.dump(checks, open('/tmp/agent_scratch/ledger/checks.json', 'w'), indent=1, default=str)

# ---------------------------------------------------------------- write
for i, r in enumerate(rows, 1):
    r['id'] = f'N{i:04d}'
    r['section'] = r['section'] + f' (line {r["line"]})'
cols = ['id', 'section', 'printed', 'context', 'source_file', 'source_field', 'exact_value', 'rounding', 'status']
with open(OUT, 'w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore')
    w.writeheader(); w.writerows(rows)
checks['unmapped'] = [(t['line'], t['printed'], t['ctx']) for t in unmapped]
json.dump(checks, open('/tmp/agent_scratch/ledger/checks.json', 'w'), indent=1, default=str)
from collections import Counter
print(Counter(r['status'] for r in rows))
print('unmapped', len(unmapped))
