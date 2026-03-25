import os
import datetime

src_dir = r'C:\Users\yaoce\Downloads'
files = []
for f in os.listdir(src_dir):
    path = os.path.join(src_dir, f)
    if os.path.isfile(path):
        mtime = os.path.getmtime(path)
        dt = datetime.datetime.fromtimestamp(mtime)
        files.append((f, dt, os.path.getsize(path)))

files.sort(key=lambda x: x[1], reverse=True)
for f, dt, size in files[:30]:
    print(f"{dt.strftime('%Y-%m-%d %H:%M:%S')} - {size:8} - {f}")
