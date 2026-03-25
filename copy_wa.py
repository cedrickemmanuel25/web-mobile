import os
import shutil

src_dir = r'C:\Users\yaoce\Downloads'
dest_dir = r'c:\Users\yaoce\web-mobile\ivoirepay_mobile\assets\images'

if not os.path.exists(dest_dir):
    os.makedirs(dest_dir)

files = [f for f in os.listdir(src_dir) if f.startswith('WhatsApp Image')]
print(f"Found {len(files)} WhatsApp images")

for i, f in enumerate(files):
    src_path = os.path.join(src_dir, f)
    dest_path = os.path.join(dest_dir, f"wa_{i}.jpg")
    shutil.copy2(src_path, dest_path)
    print(f"Copied {f} to wa_{i}.jpg")
