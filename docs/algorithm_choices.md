## Algorithm and Architecture Choices — Design Rationale

HB-1169 is designed as an **accelerator-centric Visual-Inertial SLAM SoC**.  
Every algorithm and architectural choice is driven by **hardware efficiency**, **real-time constraints**, and **wearable-class power budgets**, rather than purely algorithmic optimality on CPUs.

This section explains **why specific algorithms and techniques were chosen**, and **why alternatives were not**.

---

## 1. Feature Detection and Description

### Choice: FAST Corner Detector  
**Chosen over:** Sobel, Harris, Shi–Tomasi, DoG (SIFT)

#### Why FAST?
FAST (Features from Accelerated Segment Test) is selected because it is **exceptionally hardware-friendly**:

- Operates on **local intensity comparisons**
- No gradients, no convolutions, no floating-point
- Only requires a **small fixed neighborhood** (circle of 16 pixels)
- Amenable to **fully parallel comparison logic**
- Deterministic latency (constant cycles per pixel)

In hardware:
- FAST can be implemented as **pure combinational logic + line/window buffers**
- No multipliers or dividers
- Easily pipelined to **1 pixel per cycle**

#### Why not Sobel or gradient-based methods?
Sobel and similar edge detectors:
- Require convolution (multipliers + adders)
- Produce edges, not stable keypoints
- Are sensitive to noise and illumination
- Need additional post-processing to derive corners

These properties make Sobel:
- Inefficient in RTL
- Poor as a standalone feature detector for SLAM

#### Why not Harris / Shi–Tomasi?
While Harris/Shi–Tomasi produce high-quality corners:
- They require gradient computation
- Involve matrix operations and eigenvalue estimation
- Are **computationally expensive** and **memory-intensive**

These are well-suited for CPUs/GPUs but **not ideal for low-power streaming hardware**.

---

## 2. Non-Maximum Suppression (NMS)

### Choice: Sliding-window NMS (3×3 or 5×5)

#### Why NMS?
FAST produces a large number of candidate corners.  
NMS ensures:
- Spatial sparsity
- Only the strongest corners are retained
- Reduced downstream compute and memory pressure

#### Why window-based NMS?
- Requires only **local comparisons**
- No global sorting
- Naturally streaming
- Simple comparator logic

This aligns perfectly with:
- Line buffers
- Window buffers
- Deterministic hardware pipelines

---

## 3. Orientation Estimation

### Choice: Intensity Centroid Method (ORB orientation)

#### Why this method?
The intensity centroid method computes orientation using first-order image moments:

- Uses **simple additions and multiplications**
- No gradients or histograms
- Works well with small patches
- Robust to noise

In hardware:
- Fixed-point arithmetic is sufficient
- Moments can be accumulated in a pipeline
- `atan2` can be approximated using **CORDIC or LUT**

#### Why not gradient-based orientation?
Gradient-based methods:
- Require Sobel filters
- Need magnitude and angle computation
- Increase hardware cost significantly

Centroid-based orientation provides a **much better cost–accuracy tradeoff** for embedded SLAM.

---

## 4. Descriptor Choice

### Choice: ORB / BRIEF Binary Descriptor  
**Chosen over:** SIFT, SURF, HOG

#### Why Binary Descriptors?
Binary descriptors are:
- Extremely compact (256 bits)
- Fast to compute
- Fast to match (Hamming distance)
- Robust enough for real-time SLAM

In hardware:
- Descriptor generation is **just comparisons**
- Matching is **XOR + popcount**
- No floating-point math

#### Why not SIFT or SURF?
SIFT/SURF:
- Use scale-space pyramids
- Require Gaussian filtering
- Involve floating-point operations
- Are memory-heavy

These are:
- Prohibitively expensive for wearable-class SoCs
- Ill-suited for deterministic RTL pipelines

ORB provides **~90% of the robustness at a fraction of the cost**.

---

## 5. Descriptor Matching

### Choice: Hamming Distance + KNN + Ratio Test

#### Why Hamming Distance?
- XOR + popcount → extremely efficient in hardware
- Parallelizable
- Deterministic latency

Perfect match for binary descriptors.

#### Why KNN + Ratio Test?
- Reduces false matches
- Improves robustness in dynamic scenes
- Avoids expensive geometric verification early

#### Why not brute-force geometric checks?
Geometric verification (RANSAC-level checks) is:
- Deferred to the pose engine
- Too expensive to perform for all candidate matches

The matcher performs **cheap pruning**, not final validation.

---

## 6. Tracking and Keyframe Management

### Choice: Feature-based Tracking (not direct methods)

#### Why feature-based SLAM?
Feature-based SLAM:
- Scales well with hardware acceleration
- Allows selective processing (keyframes)
- Robust to illumination changes
- Enables explicit dataflow control

Direct methods (photometric error minimization):
- Require dense pixel processing
- High memory bandwidth
- Difficult to accelerate deterministically

For wearable SoCs, **feature-based SLAM is a better architectural fit**.

---

## 7. Depth Estimation

### Choice: Block Matching (SAD / ZNCC)

#### Why SAD / ZNCC?
- Simple arithmetic operations
- Regular memory access
- Streaming-friendly
- Well-studied in hardware

#### Why not neural depth estimation?
- Requires large models
- Heavy MAC usage
- High power consumption
- Poor determinism

Classical stereo methods remain **more efficient for embedded SLAM**.

---

## 8. Pose Estimation

### Choice: RANSAC + PnP

#### Why RANSAC?
- Robust to outliers
- Naturally parallelizable
- Can be bounded in iterations
- Works well with feature-based SLAM

#### Why PnP?
- Standard formulation for camera pose
- Well-understood
- Can be implemented with fixed-point arithmetic
- Allows hardware acceleration of core math

#### Why not full bundle adjustment in hardware?
- Too complex
- Large sparse matrix operations
- Better suited for CPU or offloaded selectively

The SoC accelerates **core pose estimation**, not global optimization.

---

## 9. Vector Processing Unit (VPU)

### Choice: Custom SIMD VPU (not GPU)

#### Why a VPU?
- Provides algorithmic flexibility
- Offloads irregular compute
- Enables experimentation and tuning
- Smaller and more power-efficient than a GPU

#### Why not a GPU?
- GPUs require complex schedulers
- High area and power
- Poor fit for small wearable devices

The VPU complements fixed-function accelerators.

---

## 10. Memory Architecture

### Choice: Scratchpad + DMA (not cache-centric)

#### Why Scratchpad Memory?
- Deterministic latency
- Explicit data movement
- No cache coherence overhead
- Easier to reason about in hardware

#### Why not cache-heavy design?
Caches:
- Introduce unpredictability
- Increase verification complexity
- Provide limited benefit for streaming workloads

SLAM workloads benefit more from **explicitly managed memory**.

---

## 11. Interconnect Choice

### Choice: AXI + AXI-Stream

#### Why AXI?
- Industry standard
- Widely supported
- Clean separation of control vs data

#### Why AXI-Stream?
- Ideal for camera data
- No addressing overhead
- Natural backpressure handling

---

## 12. SoC-Level Architectural Philosophy

In summary, HB-1169 follows these principles:

- Prefer **algorithmic simplicity** over theoretical optimality
- Prefer **deterministic pipelines** over dynamic scheduling
- Prefer **explicit dataflow** over implicit caching
- Prefer **hardware-scalable algorithms**
- Prefer **modularity and verifiability**

Every algorithm choice is driven by:
> *“Can this be implemented efficiently, predictably, and scalably in RTL?”*

---

## Conclusion

HB-1169 is not a software SLAM system mapped to hardware.  
It is a **hardware-first SLAM architecture**, where algorithms are chosen *because* they map cleanly to silicon.

This philosophy enables:
- Real-time performance
- Lower power consumption
- Clear verification strategy
- Scalable RTL design
