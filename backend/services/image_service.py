import io
import cv2
import numpy as np
from rembg import remove
from PIL import Image

def remove_background(image_bytes: bytes) -> bytes:
    """Removes the background from the provided image bytes using rembg."""
    output_image = remove(image_bytes)
    return output_image

def auto_enhance(image_bytes: bytes) -> bytes:
    """Enhances brightness and contrast using OpenCV."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Auto balance brightness and contrast
    # Convert to LAB color space
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l_channel, a, b = cv2.split(lab)
    
    # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    cl = clahe.apply(l_channel)
    
    # Merge the CLAHE enhanced L-channel back
    limg = cv2.merge((cl, a, b))
    
    # Convert back to BGR color space
    enhanced_img = cv2.cvtColor(limg, cv2.COLOR_LAB2BGR)
    
    # Encode back to bytes
    is_success, buffer = cv2.imencode(".jpg", enhanced_img)
    if is_success:
        return buffer.tobytes()
    else:
        raise ValueError("Failed to encode image")

def sharpen(image_bytes: bytes) -> bytes:
    """Sharpens a blurry image using OpenCV."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    kernel = np.array([[-1,-1,-1], [-1,9,-1], [-1,-1,-1]])
    sharpened = cv2.filter2D(img, -1, kernel)
    is_success, buffer = cv2.imencode(".jpg", sharpened)
    return buffer.tobytes()

def sketch(image_bytes: bytes) -> bytes:
    """Converts image to a pencil sketch."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    inv = 255 - gray
    blur = cv2.GaussianBlur(inv, (21, 21), 0)
    sketch = cv2.divide(gray, 255 - blur, scale=256)
    is_success, buffer = cv2.imencode(".jpg", sketch)
    return buffer.tobytes()

def black_white(image_bytes: bytes) -> bytes:
    """Converts image to black and white."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    is_success, buffer = cv2.imencode(".jpg", gray)
    return buffer.tobytes()
