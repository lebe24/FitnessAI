"""Turn the free-text workout_logs blob into structured rows."""
import re, json

SET_SPLIT = re.compile(r'\s*\|\s*')
SET_HEAD  = re.compile(r'^set\s*(\d+)\s*:\s*(.*)$', re.I)
# reps may be: "10", "8–10", "15 each side", "30 sec", "10 per leg"
QTY = re.compile(
    r'^(?P<qty>\d+(?:\s*[–-]\s*\d+)?)\s*'
    r'(?P<unit>sec|secs|seconds)?\s*'
    r'(?P<side>each\s*side|per\s*leg|each\s*leg|per\s*side)?\s*'
    r'(?:reps?)?\s*(?:@\s*(?P<kg>[\d.]+)\s*kg)?\s*$', re.I)

def _num(v):
    """'8–10' → (8, 10); '10' → (10, 10)."""
    if v is None: return (None, None)
    parts = re.split(r'\s*[–-]\s*', v.strip())
    try:
        lo = int(parts[0]); hi = int(parts[-1])
        return (lo, hi)
    except ValueError:
        return (None, None)

def parse_prescription(entry):
    """The planned target: sets × reps, or a hold in seconds."""
    reps = (entry.get('reps') or '').strip()
    per_side = bool(re.search(r'each|per\s', reps, re.I))
    is_time  = bool(re.search(r'sec', reps, re.I))
    lo, hi = _num(re.sub(r'(sec\w*|each\s*side|per\s*leg|each\s*leg)', '', reps, flags=re.I))
    return {
        'prescribed_sets': entry.get('sets'),
        'prescribed_reps_min': None if is_time else lo,
        'prescribed_reps_max': None if is_time else hi,
        'prescribed_duration_sec': lo if is_time else None,
        'is_per_side': per_side,
        'raw_prescription': reps or None,
    }

def parse_sets(notes):
    """'set 1: 10 reps @ 113kg | set 2: ...' → [{set_number, reps, weight_kg, ...}]"""
    out = []
    if not notes or not re.search(r'set\s*\d+\s*:', notes, re.I):
        return out
    for chunk in SET_SPLIT.split(notes):
        m = SET_HEAD.match(chunk.strip())
        if not m:
            continue
        n, body = int(m.group(1)), m.group(2).strip()
        q = QTY.match(body)
        if not q:
            out.append({'set_number': n, 'reps': None, 'weight_kg': None,
                        'duration_sec': None, 'per_side': False,
                        'unparsed': body})
            continue
        lo, hi = _num(q.group('qty'))
        is_time = bool(q.group('unit'))
        out.append({
            'set_number': n,
            'reps': None if is_time else lo,
            'reps_upper': None if (is_time or hi == lo) else hi,
            'duration_sec': lo if is_time else None,
            'weight_kg': float(q.group('kg')) if q.group('kg') else None,
            'per_side': bool(q.group('side')),
            'unparsed': None,
        })
    return out

def is_performed(entry):
    return bool(re.search(r'set\s*\d+\s*:', entry.get('notes') or '', re.I))

def coaching_note(entry):
    """Planned entries carry 'muscle groups | cue' in notes."""
    n = entry.get('notes') or ''
    if is_performed(entry) or not n: return (None, None)
    if '|' in n:
        muscles, cue = n.split('|', 1)
        return (muscles.strip() or None, cue.strip() or None)
    return (None, n.strip())
