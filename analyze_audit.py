import subprocess, re, pathlib, time, json, os, shutil

# Use the same flutter the shell sees
FLUTTER = shutil.which('flutter') or 'C:\\Users\\Tsayter\\flutter\\bin\\flutter.bat'
if not FLUTTER or not pathlib.Path(FLUTTER).exists():
    FLUTTER = 'flutter.bat'  # let subprocess resolve via PATH passed below

root = pathlib.Path.cwd()
if not (root / 'lib').exists():
    raise SystemExit('no lib/ in cwd; run from project root')

files = sorted(root.glob('lib/**/*.dart'))
results = []
env = dict(os.environ)
env['PATH'] = ('C:\\Users\\Tsayter\\flutter\\bin;' + env.get('PATH', ''))

for fn in files:
    try:
        # use .bat explicitly on Windows so subprocess can find it
        cmd = ['cmd', '/c', 'flutter.bat', 'analyze', str(fn)]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=90, env=env)
    except subprocess.TimeoutExpired:
        results.append({'file': str(fn.relative_to(root)), 'kind': 'timeout'})
        continue
    buf = out.stdout or out.stderr
    m = re.search(r'Analyzing\s+(.+\.dart)\s*\.\.\.\s*([xX!.EF]+)\s*$', buf, re.M)
    summary = m.group(2) if m else None
    issues = []
    for sev, msg, _, path, line, detail in re.findall(
        r'(error|warning|info|note)\s+-\s+(.+)\n\s*((?:lib|test)/|[a-zA-Z]):(.+?):(\d+)\s+-\s+(.+)',
        buf,
    ):
        issues.append({
            'file': path.rstrip('/'),
            'line': int(line),
            'level': sev,
            'message': msg.strip(),
            'detail': detail.strip(),
        })
    results.append({
        'file': str(fn.relative_to(root)),
        'summary': summary,
        'issue_count': len(issues),
        'issues': issues,
        'stderr_preview': (out.stderr or '')[:300],
    })

seen = {}
compact = []
for r in results:
    if r.get('kind') == 'timeout':
        compact.append({'file': r['file'], 'level': 'timeout'})
        continue
    for it in r.get('issues', []):
        k = (it['file'], it['line'], it['message'])
        if k in seen:
            continue
        seen[k] = it
        compact.append({'file': it['file'], 'line': it['line'], 'level': it['level'], 'message': it['message'], 'detail': it['detail']})

compact.sort(key=lambda x: (x['file'], x['line']))
total_issues = sum(r.get('issue_count', 0) for r in results)
has_errors = any(r.get('summary', '').lower().startswith('x') or r.get('summary', '').lower().startswith('!') for r in results)

out_obj = {
    'flutter_cmd': FLUTTER,
    'analyzed_files': len(files),
    'total_issues': total_issues,
    'files_with_errors': [r['file'] for r in results if r.get('summary', '').lower().startswith('x') or r.get('summary', '').lower().startswith('!')],
    'has_errors': has_errors,
    'issues_sample': compact[:220],
    'all_issue_count': len(compact),
}

print(json.dumps(out_obj, indent=2))
