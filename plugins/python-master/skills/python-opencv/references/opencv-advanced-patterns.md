# OpenCV Advanced Patterns Reference

## Background Subtraction

### MOG2 (Gaussian Mixture Models)

```python
import cv2

cap = cv2.VideoCapture("video.mp4")
fgbg = cv2.createBackgroundSubtractorMOG2(
    history=500,        # Number of frames for background model
    varThreshold=16,    # Threshold for foreground/background segmentation
    detectShadows=True  # Detect shadows (gray in mask)
)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Apply background subtraction
    fgmask = fgbg.apply(frame)

    # Remove shadows (optional)
    fgmask_no_shadow = cv2.threshold(fgmask, 200, 255, cv2.THRESH_BINARY)[1]

    cv2.imshow('Original', frame)
    cv2.imshow('Foreground Mask', fgmask)

    if cv2.waitKey(30) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

### KNN Background Subtractor

```python
import cv2

fgbg = cv2.createBackgroundSubtractorKNN(
    history=500,
    dist2Threshold=400.0,  # Threshold for Mahalanobis distance
    detectShadows=True
)

# Usage same as MOG2
fgmask = fgbg.apply(frame)
```

## Object Tracking

### Single Object Tracking

```python
import cv2

# Available trackers
TRACKERS = {
    "csrt": cv2.TrackerCSRT_create,      # Most accurate, slower
    "kcf": cv2.TrackerKCF_create,         # Good balance
    "mil": cv2.TrackerMIL_create,         # Handles occlusion
    "mosse": cv2.legacy.TrackerMOSSE_create,  # Fastest
}

cap = cv2.VideoCapture("video.mp4")
ret, frame = cap.read()

# Select ROI for tracking
bbox = cv2.selectROI("Select Object", frame, fromCenter=False)
cv2.destroyWindow("Select Object")

# Initialize tracker
tracker = TRACKERS["csrt"]()
tracker.init(frame, bbox)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Update tracker
    success, bbox = tracker.update(frame)

    if success:
        x, y, w, h = [int(v) for v in bbox]
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
    else:
        cv2.putText(frame, "Tracking failure", (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.75, (0, 0, 255), 2)

    cv2.imshow("Tracking", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

### Multi-Object Tracking

```python
import cv2

trackers = cv2.legacy.MultiTracker_create()

cap = cv2.VideoCapture("video.mp4")
ret, frame = cap.read()

# Select multiple ROIs
bboxes = cv2.selectROIs("Select Objects", frame, fromCenter=False)
cv2.destroyWindow("Select Objects")

# Initialize trackers
for bbox in bboxes:
    tracker = cv2.TrackerCSRT_create()
    trackers.add(tracker, frame, tuple(bbox))

while True:
    ret, frame = cap.read()
    if not ret:
        break

    success, boxes = trackers.update(frame)

    for i, box in enumerate(boxes):
        x, y, w, h = [int(v) for v in box]
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
        cv2.putText(frame, f"Object {i+1}", (x, y - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    cv2.imshow("Multi-Object Tracking", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

## Camera Calibration

### Chessboard Calibration

```python
import cv2
import numpy as np
import glob

# Chessboard dimensions (inner corners)
CHESSBOARD = (9, 6)

# Prepare object points
objp = np.zeros((CHESSBOARD[0] * CHESSBOARD[1], 3), np.float32)
objp[:, :2] = np.mgrid[0:CHESSBOARD[0], 0:CHESSBOARD[1]].T.reshape(-1, 2)

objpoints = []  # 3D points in real world
imgpoints = []  # 2D points in image plane

images = glob.glob("calibration_images/*.jpg")

for fname in images:
    img = cv2.imread(fname)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Find chessboard corners
    ret, corners = cv2.findChessboardCorners(gray, CHESSBOARD, None)

    if ret:
        objpoints.append(objp)

        # Refine corner positions
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
        corners2 = cv2.cornerSubPix(gray, corners, (11, 11), (-1, -1), criteria)
        imgpoints.append(corners2)

        # Draw corners (for visualization)
        cv2.drawChessboardCorners(img, CHESSBOARD, corners2, ret)

# Calibrate camera
ret, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(
    objpoints, imgpoints, gray.shape[::-1], None, None
)

# mtx: Camera matrix (intrinsic parameters)
# dist: Distortion coefficients
# rvecs, tvecs: Rotation and translation vectors

# Save calibration
np.savez("calibration.npz", mtx=mtx, dist=dist)

# Undistort images
def undistort(img, mtx, dist):
    h, w = img.shape[:2]
    newcameramtx, roi = cv2.getOptimalNewCameraMatrix(mtx, dist, (w, h), 1, (w, h))
    undistorted = cv2.undistort(img, mtx, dist, None, newcameramtx)

    # Crop image
    x, y, w, h = roi
    undistorted = undistorted[y:y+h, x:x+w]
    return undistorted
```

## Optical Flow

### Dense Optical Flow (Farneback)

```python
import cv2
import numpy as np

cap = cv2.VideoCapture("video.mp4")
ret, frame1 = cap.read()
prvs = cv2.cvtColor(frame1, cv2.COLOR_BGR2GRAY)

# Create HSV image for visualization
hsv = np.zeros_like(frame1)
hsv[..., 1] = 255

while True:
    ret, frame2 = cap.read()
    if not ret:
        break

    next_gray = cv2.cvtColor(frame2, cv2.COLOR_BGR2GRAY)

    # Calculate dense optical flow
    flow = cv2.calcOpticalFlowFarneback(
        prvs, next_gray,
        None,           # flow: output
        pyr_scale=0.5,  # Pyramid scale
        levels=3,       # Number of pyramid levels
        winsize=15,     # Window size
        iterations=3,   # Iterations at each pyramid level
        poly_n=5,       # Size of pixel neighborhood
        poly_sigma=1.2, # Standard deviation for Gaussian
        flags=0
    )

    # Convert flow to polar coordinates
    mag, ang = cv2.cartToPolar(flow[..., 0], flow[..., 1])

    # Encode as HSV
    hsv[..., 0] = ang * 180 / np.pi / 2  # Hue = direction
    hsv[..., 2] = cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX)  # Value = magnitude

    # Convert to BGR
    bgr = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)

    cv2.imshow('Optical Flow', bgr)
    if cv2.waitKey(30) & 0xFF == ord('q'):
        break

    prvs = next_gray

cap.release()
cv2.destroyAllWindows()
```

### Sparse Optical Flow (Lucas-Kanade)

```python
import cv2
import numpy as np

cap = cv2.VideoCapture("video.mp4")
ret, old_frame = cap.read()
old_gray = cv2.cvtColor(old_frame, cv2.COLOR_BGR2GRAY)

# Detect initial points to track
feature_params = dict(
    maxCorners=100,
    qualityLevel=0.3,
    minDistance=7,
    blockSize=7
)
p0 = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)

# Lucas-Kanade parameters
lk_params = dict(
    winSize=(15, 15),
    maxLevel=2,
    criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03)
)

# Create mask for drawing
mask = np.zeros_like(old_frame)

while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Calculate optical flow
    p1, st, err = cv2.calcOpticalFlowPyrLK(
        old_gray, frame_gray, p0, None, **lk_params
    )

    # Select good points
    if p1 is not None:
        good_new = p1[st == 1]
        good_old = p0[st == 1]

    # Draw tracks
    for i, (new, old) in enumerate(zip(good_new, good_old)):
        a, b = new.ravel().astype(int)
        c, d = old.ravel().astype(int)
        mask = cv2.line(mask, (a, b), (c, d), (0, 255, 0), 2)
        frame = cv2.circle(frame, (a, b), 5, (0, 0, 255), -1)

    img = cv2.add(frame, mask)
    cv2.imshow('Sparse Optical Flow', img)

    if cv2.waitKey(30) & 0xFF == ord('q'):
        break

    old_gray = frame_gray.copy()
    p0 = good_new.reshape(-1, 1, 2)

cap.release()
cv2.destroyAllWindows()
```

## Image Stitching (Panorama)

```python
import cv2
import numpy as np

def stitch_images(images):
    """Stitch multiple images into a panorama."""
    stitcher = cv2.Stitcher_create(cv2.Stitcher_PANORAMA)
    status, panorama = stitcher.stitch(images)

    if status == cv2.Stitcher_OK:
        return panorama
    elif status == cv2.Stitcher_ERR_NEED_MORE_IMGS:
        raise ValueError("Need more images")
    elif status == cv2.Stitcher_ERR_HOMOGRAPHY_EST_FAIL:
        raise ValueError("Homography estimation failed")
    elif status == cv2.Stitcher_ERR_CAMERA_PARAMS_ADJUST_FAIL:
        raise ValueError("Camera parameter adjustment failed")

# Usage
images = [cv2.imread(f"image{i}.jpg") for i in range(1, 5)]
panorama = stitch_images(images)
cv2.imwrite("panorama.jpg", panorama)
```

### Manual Stitching with Homography

```python
import cv2
import numpy as np

def stitch_pair(img1, img2):
    """Stitch two images using feature matching and homography."""
    gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
    gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)

    # Detect and compute features
    sift = cv2.SIFT_create()
    kp1, des1 = sift.detectAndCompute(gray1, None)
    kp2, des2 = sift.detectAndCompute(gray2, None)

    # Match features
    bf = cv2.BFMatcher()
    matches = bf.knnMatch(des1, des2, k=2)

    # Apply ratio test
    good = []
    for m, n in matches:
        if m.distance < 0.75 * n.distance:
            good.append(m)

    if len(good) < 4:
        raise ValueError("Not enough matches")

    # Get matched points
    src_pts = np.float32([kp1[m.queryIdx].pt for m in good]).reshape(-1, 1, 2)
    dst_pts = np.float32([kp2[m.trainIdx].pt for m in good]).reshape(-1, 1, 2)

    # Find homography
    H, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)

    # Warp image
    h1, w1 = img1.shape[:2]
    h2, w2 = img2.shape[:2]

    # Calculate output size
    corners1 = np.float32([[0, 0], [w1, 0], [w1, h1], [0, h1]]).reshape(-1, 1, 2)
    corners1_transformed = cv2.perspectiveTransform(corners1, H)

    all_corners = np.concatenate([
        corners1_transformed,
        np.float32([[0, 0], [w2, 0], [w2, h2], [0, h2]]).reshape(-1, 1, 2)
    ])

    x_min, y_min = np.int32(all_corners.min(axis=0).ravel() - 0.5)
    x_max, y_max = np.int32(all_corners.max(axis=0).ravel() + 0.5)

    # Translation matrix
    translation = np.array([
        [1, 0, -x_min],
        [0, 1, -y_min],
        [0, 0, 1]
    ])

    # Warp and combine
    result = cv2.warpPerspective(
        img1, translation @ H,
        (x_max - x_min, y_max - y_min)
    )
    result[-y_min:h2 - y_min, -x_min:w2 - x_min] = img2

    return result
```

## Face Detection

### Haar Cascade (Classic)

```python
import cv2

# Load pre-trained classifier
face_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
)
eye_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + 'haarcascade_eye.xml'
)

img = cv2.imread("faces.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Detect faces
faces = face_cascade.detectMultiScale(
    gray,
    scaleFactor=1.1,   # Image pyramid scale
    minNeighbors=5,    # Minimum neighbors for valid detection
    minSize=(30, 30)   # Minimum face size
)

for (x, y, w, h) in faces:
    cv2.rectangle(img, (x, y), (x + w, y + h), (255, 0, 0), 2)

    # Detect eyes within face region
    roi_gray = gray[y:y + h, x:x + w]
    roi_color = img[y:y + h, x:x + w]

    eyes = eye_cascade.detectMultiScale(roi_gray)
    for (ex, ey, ew, eh) in eyes:
        cv2.rectangle(roi_color, (ex, ey), (ex + ew, ey + eh), (0, 255, 0), 2)

cv2.imshow('Face Detection', img)
cv2.waitKey(0)
```

### DNN Face Detection (More Accurate)

```python
import cv2
import numpy as np

# Download model files from OpenCV GitHub
# https://github.com/opencv/opencv/tree/master/samples/dnn/face_detector

# Load DNN model
modelFile = "res10_300x300_ssd_iter_140000.caffemodel"
configFile = "deploy.prototxt"
net = cv2.dnn.readNetFromCaffe(configFile, modelFile)

img = cv2.imread("faces.jpg")
h, w = img.shape[:2]

# Prepare blob
blob = cv2.dnn.blobFromImage(
    img, 1.0, (300, 300),
    (104.0, 177.0, 123.0),  # Mean values
    swapRB=False, crop=False
)

# Run inference
net.setInput(blob)
detections = net.forward()

# Draw detections
confidence_threshold = 0.5
for i in range(detections.shape[2]):
    confidence = detections[0, 0, i, 2]

    if confidence > confidence_threshold:
        box = detections[0, 0, i, 3:7] * np.array([w, h, w, h])
        x1, y1, x2, y2 = box.astype(int)

        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
        text = f"{confidence:.2f}"
        cv2.putText(img, text, (x1, y1 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
```

## ArUco Markers

```python
import cv2
import numpy as np

# Get ArUco dictionary
aruco_dict = cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_6X6_250)
parameters = cv2.aruco.DetectorParameters()
detector = cv2.aruco.ArucoDetector(aruco_dict, parameters)

# Generate marker
marker_id = 42
marker_size = 200
marker_img = cv2.aruco.generateImageMarker(aruco_dict, marker_id, marker_size)
cv2.imwrite(f"marker_{marker_id}.png", marker_img)

# Detect markers
img = cv2.imread("scene_with_markers.jpg")
corners, ids, rejected = detector.detectMarkers(img)

if ids is not None:
    # Draw detected markers
    cv2.aruco.drawDetectedMarkers(img, corners, ids)

    # Estimate pose (requires camera calibration)
    # rvecs, tvecs, _ = cv2.aruco.estimatePoseSingleMarkers(
    #     corners, marker_length, camera_matrix, dist_coeffs
    # )

cv2.imshow('ArUco Detection', img)
cv2.waitKey(0)
```

## Histogram Operations

### Histogram Calculation

```python
import cv2
import numpy as np
from matplotlib import pyplot as plt

img = cv2.imread("image.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Calculate histogram
hist = cv2.calcHist([gray], [0], None, [256], [0, 256])

# Plot histogram
plt.figure()
plt.title("Grayscale Histogram")
plt.xlabel("Bins")
plt.ylabel("# of Pixels")
plt.plot(hist)
plt.xlim([0, 256])
plt.show()

# Color histogram
colors = ('b', 'g', 'r')
plt.figure()
for i, col in enumerate(colors):
    hist = cv2.calcHist([img], [i], None, [256], [0, 256])
    plt.plot(hist, color=col)
plt.xlim([0, 256])
plt.show()
```

### Histogram Equalization

```python
import cv2

img = cv2.imread("image.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Simple equalization
equalized = cv2.equalizeHist(gray)

# CLAHE (Contrast Limited Adaptive Histogram Equalization)
clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
clahe_result = clahe.apply(gray)

# For color images, apply to V channel in HSV
hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
hsv[:, :, 2] = cv2.equalizeHist(hsv[:, :, 2])
color_equalized = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)
```

## Thresholding Techniques

```python
import cv2

img = cv2.imread("image.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Global thresholding
_, thresh_binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)
_, thresh_binary_inv = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)
_, thresh_trunc = cv2.threshold(gray, 127, 255, cv2.THRESH_TRUNC)
_, thresh_tozero = cv2.threshold(gray, 127, 255, cv2.THRESH_TOZERO)
_, thresh_tozero_inv = cv2.threshold(gray, 127, 255, cv2.THRESH_TOZERO_INV)

# Otsu's thresholding (automatic threshold selection)
_, thresh_otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

# Adaptive thresholding (for uneven lighting)
thresh_adaptive_mean = cv2.adaptiveThreshold(
    gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 11, 2
)
thresh_adaptive_gaussian = cv2.adaptiveThreshold(
    gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
)
```

## Hough Transforms

### Hough Line Detection

```python
import cv2
import numpy as np

img = cv2.imread("image.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 50, 150)

# Standard Hough Transform
lines = cv2.HoughLines(edges, 1, np.pi / 180, 200)

if lines is not None:
    for rho, theta in lines[:, 0]:
        a = np.cos(theta)
        b = np.sin(theta)
        x0 = a * rho
        y0 = b * rho
        x1 = int(x0 + 1000 * (-b))
        y1 = int(y0 + 1000 * (a))
        x2 = int(x0 - 1000 * (-b))
        y2 = int(y0 - 1000 * (a))
        cv2.line(img, (x1, y1), (x2, y2), (0, 0, 255), 2)

# Probabilistic Hough Transform (more efficient)
lines_p = cv2.HoughLinesP(
    edges,
    rho=1,
    theta=np.pi / 180,
    threshold=100,
    minLineLength=100,
    maxLineGap=10
)

if lines_p is not None:
    for x1, y1, x2, y2 in lines_p[:, 0]:
        cv2.line(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
```

### Hough Circle Detection

```python
import cv2
import numpy as np

img = cv2.imread("image.jpg")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
gray = cv2.medianBlur(gray, 5)

circles = cv2.HoughCircles(
    gray,
    cv2.HOUGH_GRADIENT,
    dp=1,                # Inverse ratio of accumulator resolution
    minDist=50,          # Minimum distance between centers
    param1=50,           # Upper threshold for Canny
    param2=30,           # Accumulator threshold for detection
    minRadius=10,
    maxRadius=100
)

if circles is not None:
    circles = np.uint16(np.around(circles))
    for i in circles[0, :]:
        # Draw outer circle
        cv2.circle(img, (i[0], i[1]), i[2], (0, 255, 0), 2)
        # Draw center
        cv2.circle(img, (i[0], i[1]), 2, (0, 0, 255), 3)
```

## Image Inpainting

```python
import cv2
import numpy as np

img = cv2.imread("damaged_image.jpg")
mask = cv2.imread("mask.jpg", cv2.IMREAD_GRAYSCALE)

# Ensure mask is binary
_, mask = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)

# Inpaint using Navier-Stokes method
result_ns = cv2.inpaint(img, mask, inpaintRadius=3, flags=cv2.INPAINT_NS)

# Inpaint using Fast Marching Method
result_telea = cv2.inpaint(img, mask, inpaintRadius=3, flags=cv2.INPAINT_TELEA)
```

## GrabCut Segmentation

```python
import cv2
import numpy as np

img = cv2.imread("image.jpg")
mask = np.zeros(img.shape[:2], np.uint8)

# Initialize models
bgdModel = np.zeros((1, 65), np.float64)
fgdModel = np.zeros((1, 65), np.float64)

# Define rectangle containing foreground object
rect = (50, 50, 450, 290)  # (x, y, width, height)

# Run GrabCut
cv2.grabCut(img, mask, rect, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_RECT)

# Create mask where sure and likely foreground
mask2 = np.where((mask == 2) | (mask == 0), 0, 1).astype('uint8')

# Apply mask
result = img * mask2[:, :, np.newaxis]
```

## Watermark Addition

```python
import cv2
import numpy as np

def add_watermark(img, watermark, position='bottom-right', opacity=0.5):
    """Add a semi-transparent watermark to an image."""
    h_img, w_img = img.shape[:2]
    h_wm, w_wm = watermark.shape[:2]

    # Ensure watermark has alpha channel
    if watermark.shape[2] == 3:
        watermark = cv2.cvtColor(watermark, cv2.COLOR_BGR2BGRA)

    # Calculate position
    positions = {
        'top-left': (10, 10),
        'top-right': (w_img - w_wm - 10, 10),
        'bottom-left': (10, h_img - h_wm - 10),
        'bottom-right': (w_img - w_wm - 10, h_img - h_wm - 10),
        'center': ((w_img - w_wm) // 2, (h_img - h_wm) // 2)
    }
    x, y = positions.get(position, position)

    # Create output image
    output = img.copy()
    if output.shape[2] == 3:
        output = cv2.cvtColor(output, cv2.COLOR_BGR2BGRA)

    # Blend watermark
    roi = output[y:y + h_wm, x:x + w_wm]
    watermark_rgb = watermark[:, :, :3]
    watermark_alpha = watermark[:, :, 3] / 255.0 * opacity

    for c in range(3):
        roi[:, :, c] = (
            watermark_alpha * watermark_rgb[:, :, c] +
            (1 - watermark_alpha) * roi[:, :, c]
        )

    output[y:y + h_wm, x:x + w_wm] = roi

    return cv2.cvtColor(output, cv2.COLOR_BGRA2BGR)
```

## Performance Benchmarking

```python
import cv2
import time
import numpy as np

def benchmark_operation(func, *args, iterations=100):
    """Benchmark an OpenCV operation."""
    # Warm up
    for _ in range(10):
        func(*args)

    # Benchmark
    times = []
    for _ in range(iterations):
        start = time.perf_counter()
        func(*args)
        end = time.perf_counter()
        times.append(end - start)

    return {
        'mean': np.mean(times) * 1000,  # ms
        'std': np.std(times) * 1000,
        'min': np.min(times) * 1000,
        'max': np.max(times) * 1000
    }

# Example usage
img = np.random.randint(0, 256, (1080, 1920, 3), dtype=np.uint8)

results = benchmark_operation(cv2.GaussianBlur, img, (5, 5), 0)
print(f"GaussianBlur: {results['mean']:.2f} +/- {results['std']:.2f} ms")
```
