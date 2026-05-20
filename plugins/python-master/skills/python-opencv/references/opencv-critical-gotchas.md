# OpenCV Critical Gotchas

Use this reference for the OpenCV mistakes that most often cause silent bugs in Python computer-vision code: BGR/RGB confusion, coordinate ordering, failed image loads, unreleased video resources, and dtype overflow.

## 1. BGR vs RGB Color Format

**The #1 source of OpenCV bugs.** OpenCV uses BGR, not RGB.

```python
import cv2
import numpy as np
from matplotlib import pyplot as plt

# OpenCV reads images in BGR format
img_bgr = cv2.imread("image.jpg")  # BGR!

# WRONG: Display BGR directly with Matplotlib
# plt.imshow(img_bgr)  # Colors will be wrong!

# CORRECT: Convert to RGB for Matplotlib
img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
plt.imshow(img_rgb)
plt.show()

# CORRECT: Save with OpenCV (expects BGR)
cv2.imwrite("output.jpg", img_bgr)  # Correct colors

# WRONG: Save RGB with OpenCV
# cv2.imwrite("output.jpg", img_rgb)  # Colors will be wrong!
```

**PIL/Pillow Integration:**

```python
from PIL import Image
import cv2
import numpy as np

# PIL uses RGB, OpenCV uses BGR
pil_image = Image.open("image.jpg")  # RGB
cv_image = np.array(pil_image)       # Still RGB!
cv_image_bgr = cv2.cvtColor(cv_image, cv2.COLOR_RGB2BGR)  # Now BGR

# Going back to PIL
cv_result = cv2.GaussianBlur(cv_image_bgr, (5, 5), 0)
cv_result_rgb = cv2.cvtColor(cv_result, cv2.COLOR_BGR2RGB)
pil_result = Image.fromarray(cv_result_rgb)
```

## 2. Coordinate System Confusion (x,y vs row,col)

```python
import cv2
import numpy as np

img = cv2.imread("image.jpg")

# Shape returns (height, width, channels) = (rows, cols, channels)
height, width, channels = img.shape
print(f"Image: {width}x{height}")  # width x height for display

# NumPy indexing: img[row, col] = img[y, x]
pixel = img[100, 200]  # Row 100, Column 200 = y=100, x=200

# OpenCV drawing functions use (x, y)
cv2.rectangle(img, (x1, y1), (x2, y2), color, thickness)
cv2.circle(img, (center_x, center_y), radius, color, thickness)
cv2.putText(img, "text", (x, y), font, scale, color)

# ROI slicing: img[y1:y2, x1:x2]
roi = img[100:200, 150:300]  # rows 100-200, cols 150-300
```

## 3. imread Returns None on Failure

```python
import cv2

# DANGEROUS: No error raised, just returns None!
img = cv2.imread("nonexistent.jpg")
# img is None, but no exception!

# ALWAYS check the result
img = cv2.imread("image.jpg")
if img is None:
    raise FileNotFoundError(f"Could not load image: image.jpg")

# Better: Use pathlib to check first
from pathlib import Path
import numpy as np

def load_image(path: str) -> np.ndarray:
    """Load image with proper error handling."""
    if not Path(path).exists():
        raise FileNotFoundError(f"Image file not found: {path}")

    img = cv2.imread(path)
    if img is None:
        raise ValueError(f"Could not decode image: {path}")

    return img
```

## 4. VideoCapture Memory Leaks

```python
import cv2

# ALWAYS release VideoCapture resources
cap = cv2.VideoCapture(0)  # or video file path

try:
    if not cap.isOpened():
        raise RuntimeError("Cannot open camera")

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Process frame...
        cv2.imshow('frame', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
finally:
    cap.release()
    cv2.destroyAllWindows()

# OR use context manager pattern
class VideoCapture:
    def __init__(self, source):
        self.cap = cv2.VideoCapture(source)
        if not self.cap.isOpened():
            raise RuntimeError(f"Cannot open video source: {source}")

    def __enter__(self):
        return self.cap

    def __exit__(self, *args):
        self.cap.release()

# Usage
with VideoCapture(0) as cap:
    ret, frame = cap.read()
```

## 5. Data Type Issues

```python
import cv2
import numpy as np

# OpenCV expects uint8 (0-255) for most operations
img = cv2.imread("image.jpg")  # dtype: uint8

# Arithmetic can overflow!
result = img + 50  # WRONG: overflow wraps around
result = cv2.add(img, 50)  # CORRECT: saturates at 255

# Float operations need conversion
img_float = img.astype(np.float32) / 255.0  # Normalize to 0-1
# ... do operations ...
img_uint8 = (img_float * 255).astype(np.uint8)  # Convert back

# Some functions require specific dtypes
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)  # uint8
edges = cv2.Canny(gray, 100, 200)  # Requires uint8 input
```
