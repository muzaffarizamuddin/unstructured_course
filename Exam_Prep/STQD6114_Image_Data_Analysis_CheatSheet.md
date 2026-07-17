# STQD6114 — Image Data Analysis: Theory Cheat Sheet
### 20 Likely Theory Questions with Model Answers (incl. Histogram Equalization calculation variations)

---

## Q1. What is a digital image? Define it mathematically.

**Model Answer:**
An image is a projection of a 3D scene onto a 2D projection plane. It can be defined as a two-variable function **f(x,y): R² → R**, where for every position (x,y) on the plane, f(x,y) gives the light intensity (gray level) at that point.

If x, y, and the values of f are all **finite and discrete** quantities, the image is called a **digital image**. A digital image is composed of a finite number of elements called **pixels (picture elements)**, each having a specific location (x,y) and a specific value (intensity/gray level).

---

## Q2. What is a pixel, and what are the three main types of digital images?

**Model Answer:**
A **pixel** ("picture element") is the smallest addressable element of a digital image; it has a location (row, column) and a value (intensity).

The three types of digital images are:

| Type | Representation | Description |
|---|---|---|
| **Binary image** | g(x,y) ∈ {0, 1} | Each pixel is 1 bit; 1 = white, 0 = black (black & white image) |
| **Grayscale image** | g(x,y) ∈ C, typically C = {0,…,255} | Each pixel corresponds to a light intensity, normally 8-bit (256 levels) |
| **Color image (RGB)** | gR(x,y) ∈ C, gG(x,y) ∈ C, gB(x,y) ∈ C | Each pixel contains a vector of 3 values representing Red, Green, and Blue channels |

---

## Q3. What is digital image processing, and what are its two main motivations?

**Model Answer:**
Digital image processing is a method of performing operations on a digital image to obtain an enhanced image or to extract useful information from it. It is a type of signal processing where the input is an image and the output may be an image or a set of characteristics/features associated with that image.

**Two motivations:**
1. Improvement of picture information for human interpretation.
2. Storage, transmission, and representation of digital image data for machine perception.

---

## Q4. Differentiate between low-level, mid-level, and high-level image processing.

**Model Answer:**

| Level | Description | Input → Output | Example |
|---|---|---|---|
| **Low-level** | Primitive operations | Image → Image | Noise reduction, sharpening, enhancement |
| **Mid-level** | Extracting attributes | Image → Attributes of image | Segmentation, edge detection, classification of individual objects |
| **High-level** | Making sense of recognized objects | Attributes → Meaning/decisions | Automatic character recognition, military recognition, autonomous navigation |

---

## Q5. Describe the phases (pipeline) of a typical image processing system.

**Model Answer:**
Starting from a **Problem Domain**, the general pipeline is:

1. **Image Acquisition** – the image is captured (e.g., by a camera) and digitized.
2. **Image Enhancement** – manipulating the image so the result is more suitable than the original for a specific application.
3. **Image Restoration** – recovering a degraded image using mathematical/probabilistic models.
4. **Morphological Processing** – extracting image components useful for representing shape.
5. **Segmentation** – separating an image into its constituent objects.
6. **Object Recognition** – assigning a label to an object based on its description.
7. **Representation & Description** – representation converts data into a form suitable for computer processing; description extracts features.

Two parallel/supporting branches feed into this pipeline:
- **Color Image Processing** – handles the processing of colored (e.g., RGB) images.
- **Image Compression** – reduces the storage space or transmission bandwidth needed for an image.

---

## Q6. What happens during the Image Acquisition phase? Name the components and sensor arrangements involved.

**Model Answer:**
Image acquisition is the step where the image is captured by a camera/sensor and digitized (if not already digital). Mathematically, f(x,y) = i(x,y)·r(x,y), where i(x,y) is the illumination source and r(x,y) is the reflectance of the scene element.

**Three components of image acquisition:**
1. Illumination (energy source)
2. Optical system (lens system)
3. Sensor system

**Three principal sensor arrangements:**
1. Single sensor
2. Line sensor
3. Array sensor

The acquisition chain flows: **World → Camera → Digitizer → Digital Image**.

---

## Q7. Differentiate between Image Enhancement and Image Restoration.

**Model Answer:**

| Aspect | Image Enhancement | Image Restoration |
|---|---|---|
| Definition | Process of manipulating an image so the result is **more suitable** than the original for a specific application | Process of **recovering** an image that has been degraded |
| Approach | Subjective; based on what looks better for the task | Objective; uses mathematical or probabilistic degradation models |
| Example | Increasing contrast, sharpening a blurred photo for viewing | Removing motion blur using a known blur model, denoising using a noise model |

---

## Q8. What is image sampling and image quantization? How do they differ?

**Model Answer:**
Digitization of an image involves two stages:
- **Sampling**: the discretization of the spatial coordinates (x,y). It determines the spatial resolution (number of pixels).
- **Quantization**: the discretization of the amplitude/gray level (intensity) values. It determines the number of gray levels (e.g., 256 levels for an 8-bit image).

Given a continuous image f(x,y), digitizing the coordinate values is called sampling, and digitizing the intensity values is called quantization. Both stages are needed to convert a continuous image into a digital image g(i,j) ∈ C.

---

## Q9. Explain the effect of reducing spatial resolution (sampling) on an image.

**Model Answer:**
Reducing the spatial sampling rate (fewer pixels, lower dpi) reduces the amount of spatial detail captured — the image becomes blocky/pixelated and fine details/edges are lost, even though the number of gray levels stays the same. For example, comparing images at 1250 dpi, 300 dpi, 150 dpi, and 72 dpi shows progressively coarser, blockier reproduction as dpi (sampling) decreases; at very low sampling (e.g., 72 dpi or "8 points" sampling of a face image), the image looks distinctly blocky and loses recognizable detail.

---

## Q10. Explain the effect of reducing the number of gray levels (quantization) on image quality.

**Model Answer:**
Reducing the number of quantization levels (fewer bits per pixel) reduces the number of distinguishable intensity values. This produces **false contouring** (visible banding) because smooth intensity gradients are approximated by a small number of steps. For example, an image displayed at 256, 64, 32, 16, 8, 4, and 2 gray levels shows increasingly visible banding/contouring as levels decrease, and by 2 levels the image becomes essentially a binary silhouette.

**Important note:** Low-frequency (smooth, slowly changing) areas of an image are **more sensitive** to quantization — coarse quantization causes visible banding/contouring most noticeably in smooth regions (e.g., sky, skin tones), while high-frequency/textured regions hide the effect better.

---

## Q11. What is color quantization and why is it needed?

**Model Answer:**
A high-quality color image commonly uses 256 levels per channel (R, G, B), giving 256³ = 16,777,216 possible colors. **Color quantization** is the process of displaying/storing an image using **fewer colors** than it actually contains.

This is done by selecting a representative subset of colors — called a **colormap or palette** (e.g., 256 colors with an 8-bit-per-pixel colour lookup table) — and mapping every other color in the image to its nearest representative color in the palette. Reducing the palette (e.g., from 256 → 16 → 4 → 2 colors) progressively degrades color detail/gradients in the image.

---

## Q12. Define image histogram and list its main uses.

**Model Answer:**
A **histogram** is the graphical representation of data; an **image histogram** represents the **relative frequency of occurrence** of each gray level in an image. It provides a global description of the appearance of an image and is a spatial-domain method.

**Uses of a histogram:**
- Determining digitizing parameters
- Measuring image properties: average, variance, entropy, contrast, area (for a given gray-level range)
- Threshold selection (e.g., for segmentation)
- Measuring image distance/similarity
- Image enhancement: **histogram equalization**, histogram stretching, histogram matching

A dark image has histogram values concentrated near 0; a light image has values concentrated near 255; a low-contrast image has values clustered in a narrow band; a high-contrast image has values spread across the full range.

---

## Q13. What is histogram equalization? Outline the general steps used to perform it.

**Model Answer:**
**Histogram equalization** is a spatial-domain image enhancement technique that redistributes (normalizes) the gray-level values of an image so that the output histogram is as close as possible to a flat (uniform) profile, thereby improving contrast — especially useful for images that are too dark, too light, or low-contrast.

**General steps:**
1. **Step 1:** Compute the frequency of occurrence, fₓ, of each gray level in the image (i.e., build the original histogram).
2. **Step 2:** Perform the equalization calculation:
   - Compute **PDF** (Probability Density Function) = fₓ / n, where n is the total number of pixels.
   - Compute **CDF** (Cumulative Distribution Function) = running sum of PDF values up to that gray level.
   - Multiply each CDF value by **(L − 1)**, where L is the number of gray levels (e.g., L = 8 for a 3-bit image, L = 256 for an 8-bit image).
   - **Round off** each CDF×(L−1) value to the nearest integer to obtain the new (equalized) gray level.
3. **Step 3:** Build the new histogram/mapping table (old gray level → new gray level).
4. **Step 4:** Apply the mapping to every pixel to produce the output (equalized) image, and plot the new histogram if required.

*(See Q17–Q20 below for four fully worked numerical variations of this calculation.)*

---

## Q14. Give the formula for local image contrast, and explain the difference between low-contrast and high-contrast images.

**Model Answer:**
The **local contrast** at an image point p, relative to its neighborhood n, is defined as:

**C = | (Iₚ − Iₙ) / Iₙ |**

where Iₚ is the intensity of the point and Iₙ is the intensity of its neighborhood.

*Worked example:* If Iₚ = 0.3 and Iₙ = 0.1, then C = |0.3 − 0.1| / 0.1 = **2**. If Iₚ = 0.7 and Iₙ = 0.5, then C = |0.7 − 0.5| / 0.5 = **0.4**. The first case has much higher local contrast than the second.

The contrast definition for an **entire** image is ambiguous, but in general an image is said to have **high contrast** if its gray levels fill (span) the entire available range (e.g., 0–255), giving a crisp, well-differentiated appearance. A **low-contrast** image has gray levels clustered in a narrow band, giving a flat, washed-out or dull appearance.

---

## Q15. What is adaptive (local) histogram? Give examples of its applications.

**Model Answer:**
An **adaptive/local histogram** is a histogram computed over a small local region (window) of an image rather than the whole image, because global histograms cannot capture localized variations in intensity/appearance.

**Examples of applications:**
- Pattern detection (e.g., matching a small target patch, like a stop sign, against a scene)
- Adaptive (local) contrast enhancement
- Adaptive thresholding
- Object tracking

---

## Q16. Explain morphological image processing, and describe the Erosion and Dilation operations with their properties.

**Model Answer:**
**Morphological processing** is a comprehensive set of image-processing operations that process an image based on **shape**. A **structuring element** is applied to the input image, producing an output image of the same size, where each output pixel value is based on comparing the corresponding input pixel with its neighbors.

| Operation | Effect | Properties |
|---|---|---|
| **Erosion** | Shrinks the image pixels — removes pixels on object boundaries | Can split apart joined objects; can strip away small extrusions/protrusions |
| **Dilation** | Expands the image pixels — adds pixels on object boundaries | Can repair breaks (gaps) in an object; can repair (fill) intrusions/notches |

Morphological operations are commonly used on binary images (e.g., fingerprint images) and are the basis for more advanced operations such as **opening** (erosion followed by dilation) and **closing** (dilation followed by erosion).

---

## Q17. HISTOGRAM EQUALIZATION — Worked Calculation (Variation 1: 5×5 image, 3-bit / L = 8)

**Question:** Given the 5×5 grayscale image below (gray levels 0–7, i.e., a 3-bit image, L = 8), perform histogram equalization. Show the PDF, CDF, and new (equalized) gray levels.

```
Image (5x5):
3  3  7  7  6
5  2  2  3  4
6  6  4  4  5
5  7  3  6  0
7  6  5  5  4
```

**Model Answer:**

Total number of pixels, n = 25. L − 1 = 8 − 1 = **7**.

| Gray level | Frequency (fₓ) | PDF = fₓ/n | CDF = ΣPDF | CDF × 7 | New gray level (rounded) |
|---|---|---|---|---|---|
| 0 | 1 | 0.04 | 0.04 | 0.28 | 0 |
| 1 | 0 | 0.00 | 0.04 | 0.28 | 0 |
| 2 | 2 | 0.08 | 0.12 | 0.84 | 1 |
| 3 | 4 | 0.16 | 0.28 | 1.96 | 2 |
| 4 | 4 | 0.16 | 0.44 | 3.08 | 3 |
| 5 | 5 | 0.20 | 0.64 | 4.48 | 4 |
| 6 | 5 | 0.20 | 0.84 | 5.88 | 6 |
| 7 | 4 | 0.16 | 1.00 | 7.00 | 7 |

**New gray-level mapping:** 0→0, 1→0, 2→1, 3→2, 4→3, 5→4, 6→6, 7→7

**Equalized image:**
```
2  2  7  7  6
4  1  1  2  3
6  6  3  3  4
4  7  2  6  0
7  6  4  4  3
```

---

## Q18. HISTOGRAM EQUALIZATION — Worked Calculation (Variation 2: 4×4 image, L = 8, showing the rounding step clearly)

**Question:** Given the 4×4 grayscale image below (gray levels 0–7, L = 8), perform histogram equalization.

```
Image (4x4):
1  1  2  2
1  3  3  2
4  4  5  5
6  6  7  7
```

**Model Answer:**

Total number of pixels, n = 16. L − 1 = **7**.

| Gray level | Frequency (fₓ) | PDF = fₓ/n | CDF = ΣPDF | CDF × 7 | New gray level (rounded) |
|---|---|---|---|---|---|
| 0 | 0 | 0.0000 | 0.0000 | 0.000 | 0 |
| 1 | 3 | 0.1875 | 0.1875 | 1.3125 | 1 |
| 2 | 3 | 0.1875 | 0.3750 | 2.625 | 3 |
| 3 | 2 | 0.1250 | 0.5000 | 3.500 | 4 |
| 4 | 2 | 0.1250 | 0.6250 | 4.375 | 4 |
| 5 | 2 | 0.1250 | 0.7500 | 5.250 | 5 |
| 6 | 2 | 0.1250 | 0.8750 | 6.125 | 6 |
| 7 | 2 | 0.1250 | 1.0000 | 7.000 | 7 |

**New gray-level mapping:** 0→0, 1→1, 2→3, 3→4, 4→4, 5→5, 6→6, 7→7

**Key teaching point:** Notice gray levels 3 and 4 both map to the **same** new value (4) — histogram equalization can merge (compress) adjacent gray levels together when the CDF changes slowly, which is a normal and expected outcome, not an error.

---

## Q19. HISTOGRAM EQUALIZATION — Worked Calculation (Variation 3: 4-bit image, L = 16)

**Question:** A 4-bit grayscale image (L = 16 gray levels, i.e., levels 0–15) has 20 pixels distributed only across gray levels 0–3, with the frequencies below. Perform histogram equalization.

| Gray level | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Frequency | 2 | 4 | 6 | 8 |

**Model Answer:**

Total number of pixels, n = 20. Since this is a **4-bit image**, L = 16, so **L − 1 = 15** (not 7 — this is the key difference from a 3-bit image).

| Gray level | Frequency | PDF = fₓ/n | CDF = ΣPDF | CDF × 15 | New gray level (rounded) |
|---|---|---|---|---|---|
| 0 | 2 | 0.10 | 0.10 | 1.5 | 2 |
| 1 | 4 | 0.20 | 0.30 | 4.5 | 5 |
| 2 | 6 | 0.30 | 0.60 | 9.0 | 9 |
| 3 | 8 | 0.40 | 1.00 | 15.0 | 15 |

**New gray-level mapping:** 0→2, 1→5, 2→9, 3→15

**Key teaching point:** For an L-level image, the multiplier is always **(L − 1)**. A 3-bit image uses ×7, a 4-bit image uses ×15, and (as in Q20) a standard 8-bit image uses ×255 — always double-check the bit depth stated in the question before multiplying.

---

## Q20. HISTOGRAM EQUALIZATION — Worked Calculation (Variation 4: standard 8-bit image, L = 256)

**Question:** An 8-bit grayscale image (L = 256, the most common real-world case) has 10 pixels with the frequencies below. Perform histogram equalization.

| Gray level | 0 | 50 | 100 | 200 |
|---|---|---|---|---|
| Frequency | 1 | 2 | 3 | 4 |

**Model Answer:**

Total number of pixels, n = 10. This is a standard **8-bit image**, so L = 256 and **L − 1 = 255**.

| Gray level | Frequency | PDF = fₓ/n | CDF = ΣPDF | CDF × 255 | New gray level (rounded) |
|---|---|---|---|---|---|
| 0 | 1 | 0.1 | 0.1 | 25.5 | 26 |
| 50 | 2 | 0.2 | 0.3 | 76.5 | 77 |
| 100 | 3 | 0.3 | 0.6 | 153.0 | 153 |
| 200 | 4 | 0.4 | 1.0 | 255.0 | 255 |

**New gray-level mapping:** 0→26, 50→77, 100→153, 200→255

**Key teaching point:** This variation matters because most real photographs are 8-bit (256 gray levels per channel), so an exam question that simply says "a grayscale image" (without specifying 3-bit/8 levels like the lecture's teaching example) most likely expects **L − 1 = 255**, not 7. Always state the value of L you are using and where it comes from (bit depth of the image) before doing the calculation.

---
---

# PART 2 — Applied / "Importance of..." Style Questions

*The lecturer noted that exam questions tend to be **less technical/mathematical** and more about explaining the **importance, relevance, and real-world impact** of a concept. The 10 questions below are written in that style — no formulas required, just clear, well-organized explanations.*

---

## Q21. Why is image data analysis important in today's world?

**Model Answer:**
Images now make up a huge share of the data generated daily — from smartphone photos and social media, to medical scans, satellite imagery, and CCTV footage. Unlike structured numeric data, an image cannot be directly interpreted by a computer without processing, so image data analysis is what turns raw pixels into **usable information** — detecting objects, diagnosing disease, verifying identity, guiding vehicles, or simply making a photo look better. As more industries (healthcare, security, retail, transport, agriculture) become data-driven, the ability to extract meaning from images has become a core, everyday requirement rather than a niche skill.

---

## Q22. Discuss the importance of image enhancement in practical applications.

**Model Answer:**
Raw images captured in the real world are rarely perfect — they may be dark, blurry, noisy, or low-contrast due to poor lighting, motion, or cheap sensors. Image enhancement is important because it makes an image **more suitable for its intended purpose**, whether that purpose is human viewing (e.g., sharpening a family photo) or downstream machine analysis (e.g., a clearer X-ray helps a radiologist, and a higher-contrast satellite image helps a mapping algorithm detect roads). Without enhancement, later steps like segmentation and object recognition would perform poorly because they depend on clear, well-differentiated visual information.

---

## Q23. Why is histogram equalization useful in real-world image processing, beyond the calculation itself?

**Model Answer:**
Histogram equalization is important because it provides an **automatic, low-cost way to improve contrast** without needing to manually adjust brightness or tone. This matters in situations where images are captured under inconsistent or poor lighting conditions — for example, medical X-rays, satellite/aerial photography, security camera footage taken at night, or old/degraded photographs. By spreading out the intensity values across the full available range, previously hidden details in very dark or very bright regions become visible, which can directly improve outcomes such as a doctor spotting an anomaly or a security system identifying a person more clearly.

---

## Q24. Discuss the importance of image compression in modern applications.

**Model Answer:**
Image (and video) compression is essential because uncompressed visual data is extremely large — a single uncompressed photo can be over a megabyte, and video multiplies this dramatically. Compression (e.g., JPEG achieving roughly 16:1, DVD video around 48:1) makes it practical to **store, transmit, and stream** images and video efficiently over limited bandwidth and storage, which underpins everyday technologies like social media, video calls, cloud photo storage, and streaming services. Without compression, the internet and mobile data infrastructure we rely on today would be far slower and far more expensive to operate.

---

## Q25. Why is color quantization important in practical image display and storage?

**Model Answer:**
Even though modern displays can technically represent millions of colors, storing and transmitting full-color information for every pixel is often unnecessary and costly. Color quantization allows an image to be represented with a much smaller palette of representative colors while still looking visually acceptable, which reduces file size and memory/bandwidth requirements. This is important in contexts like low-bandwidth web graphics, older or low-resource devices, GIF animations, and any situation where storage efficiency matters more than perfect color fidelity — it's a practical trade-off between visual quality and resource cost.

---

## Q26. Discuss the importance of morphological image processing in real-world applications such as biometrics or medical imaging.

**Model Answer:**
Morphological operations (erosion, dilation, etc.) are important because they let a system clean up and refine the **shape** of objects in an image — repairing broken lines, removing small noise specks, or separating touching objects — before further analysis is done. This matters enormously in applications like fingerprint recognition (where ridge lines must be clear and continuous for accurate matching), medical imaging (where organ or tumor boundaries need to be clean for measurement), and industrial inspection (where defects need to be reliably isolated from the background). Without this shape "clean-up" step, later recognition or measurement steps would be far less accurate.

---

## Q27. Explain the importance of image segmentation in fields like autonomous driving or medical diagnosis.

**Model Answer:**
Segmentation is the step where a computer tries to separate meaningful objects from the rest of an image, and it is important because almost no higher-level task (recognition, measurement, decision-making) can happen without it. In autonomous driving, segmentation is what allows a vehicle to distinguish the road, pedestrians, other cars, and obstacles from each other in real time — a safety-critical task. In medical diagnosis, segmentation allows a tumor, organ, or lesion to be isolated from surrounding tissue so its size and characteristics can be measured accurately. In both cases, poor segmentation directly translates into poor, and potentially dangerous, downstream decisions.

---

## Q28. Why is it important to understand image sampling and quantization when choosing equipment like cameras or scanners?

**Model Answer:**
Sampling (spatial resolution) and quantization (number of gray/color levels) directly determine how much detail an image can capture and how smooth its tones appear. Understanding this is important practically because it affects real decisions — for example, choosing a higher-resolution camera or scanner (better sampling) for tasks needing fine detail like printing or forensic analysis, versus accepting a lower resolution for simple web thumbnails to save storage. Similarly, understanding quantization helps explain why a "cheaper" or older sensor may produce visible banding in smooth areas like skies or skin tones, guiding decisions about when higher bit-depth equipment is worth the cost.

---

## Q29. Discuss the real-world consequences of poor image quality (due to inadequate sampling or quantization) in fields like healthcare or security.

**Model Answer:**
Poor sampling or quantization is not just a cosmetic issue — it can have serious real-world consequences. In healthcare, an X-ray or MRI with insufficient spatial resolution or gray-level detail may hide a small tumor or fracture, leading to missed or delayed diagnosis. In security and surveillance, low-resolution CCTV footage may make it impossible to identify a face or license plate, undermining investigations. In autonomous systems, poor image quality can cause a vehicle or robot to misinterpret its surroundings, creating safety risks. This illustrates why the technical choices behind image acquisition matter well beyond the field of computer science itself.

---

## Q30. Why is image data analysis relevant to a data scientist, even outside dedicated computer vision roles?

**Model Answer:**
As organizations increasingly deal with unstructured data (text, audio, and images) alongside traditional tabular data, a data scientist who understands image data analysis is better equipped to work with a wider range of real business problems — from quality inspection in manufacturing, to analyzing customer-uploaded photos in retail, to processing scanned documents. Even a basic understanding of concepts like image enhancement, compression, and feature extraction helps a data scientist communicate effectively with specialized computer vision teams, evaluate whether an image-based solution is feasible, and recognize how image preprocessing choices (e.g., poor quality input images) can silently affect the performance of any downstream model.

