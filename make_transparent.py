import os
from rembg import remove
from PIL import Image

input_path = r"C:\Users\user\.gemini\antigravity-ide\brain\7f89d675-b6bd-485b-a169-89261a1e01e6\glowforge_logo_raw_1786086106127.png"
output_dir = r"C:\Users\user\.gemini\antigravity-ide\scratch\GlowForgeAI\frontend\assets"
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "logo.png")

print("Processing image...")
input_image = Image.open(input_path)
output_image = remove(input_image)
output_image.save(output_path)
print(f"Transparent logo saved to {output_path}")
