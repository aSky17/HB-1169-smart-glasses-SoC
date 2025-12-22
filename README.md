# HB-1169 Smart Glasses SLAM SoC

HB-1169 is a **heterogeneous RISC-V System-on-Chip (SoC)** designed for **real-time Visual-Inertial SLAM (Simultaneous Localization and Mapping)** targeting **smart-glasses–class wearable devices**.

The SoC is **accelerator-centric**: heavy perception and SLAM workloads are offloaded to a dedicated **SLAM Compute Fabric**, while a RISC-V CPU handles system control, configuration, and software orchestration.

This project is a **full-stack architecture + RTL design effort**, focused on building a **modular, configurable, and verifiable SLAM hardware subsystem** using **only open and non-proprietary IP**.

---

## Key Design Goals

- Real-time, on-device Visual-Inertial SLAM
- Accelerator-first SoC architecture
- Deterministic latency and high throughput
- Streaming-friendly memory hierarchy
- Modular RTL suitable for ASIC or FPGA
- Verification-driven development (cocotb-based)

---

## High-Level SoC Architecture

HB-1169 is organized into **four major architectural domains**:

<p>
  <img src="docs\arch_overview.png" title="architecture overview">
</p>

## SoC Components Overview

### 1. Control Domain

The Control Domain is responsible for **system boot, configuration, scheduling, and supervision**.

**Components:**
- **CVA6 RISC-V Core (RV64IMAFC)**  
  - 64-bit Linux-capable application core  
  - Runs firmware / OS / SLAM orchestration software  
- Boot ROM
- Interrupt controller
- Timers and debug infrastructure

**Responsibilities:**
- Configure SLAM accelerators
- Program DMA transfers
- Launch and monitor compute jobs
- Handle exceptions and system events

The CPU **does not perform pixel-level computation**.

---

### 2. SLAM Compute Fabric (Core of the SoC)

The **SLAM Compute Fabric** is a **domain-specific accelerator cluster** optimized for vision and SLAM workloads.  
It operates on **streaming data and scratchpad memory**, not caches.

#### Compute Fabric Components

##### a) Feature Extractor Accelerator
Extracts robust visual features from incoming image frames.

**Pipeline:**
- FAST corner detection
- Non-Maximum Suppression (NMS)
- Orientation estimation
- ORB / BRIEF descriptor generation

**Output:**
- Keypoints: `(x, y, score, orientation)`
- 256-bit binary descriptors

Designed using:
- Line buffers and window buffers
- Fully streaming datapath
- Fixed-point arithmetic

---

##### b) Descriptor Matcher
Matches features between frames or keyframes.

**Functions:**
- Hamming distance computation (binary descriptors)
- K-Nearest Neighbor (KNN) search
- Lowe’s ratio test
- Optional geometric consistency filtering

**Output:**
- Matched feature pairs with confidence metrics

---

##### c) Tracker / Keyframe Manager
Maintains temporal coherence across frames.

**Functions:**
- Keypoint lifetime management
- Motion prediction (constant-velocity model)
- Keyframe selection based on parallax and motion
- Feature pruning and ranking

---

##### d) Depth / Stereo Engine (Optional)
Provides depth cues to improve pose estimation.

**Functions:**
- Block matching (SAD / ZNCC)
- Cost volume generation
- Winner-take-all disparity selection
- Confidence estimation

---

##### e) Pose Engine
Estimates camera pose from matched features.

**Functions:**
- RANSAC hypothesis generation
- PnP (Perspective-n-Point) solver
- Inlier counting and pose selection
- Fixed-point math for real-time execution

**Output:**
- Camera pose `(R, t)` with confidence

---

##### f) Vector Processing Unit (VPU)
A lightweight SIMD engine for algorithmic flexibility.

**Used for:**
- Custom vision kernels
- Descriptor post-processing
- Small matrix and vector math
- Algorithms not fully hardwired

---

##### g) Fabric Scheduler
Orchestrates accelerator execution.

**Responsibilities:**
- Job dispatch
- Dependency tracking
- Resource arbitration
- Interrupt generation on completion

---

##### h) Local Scratchpad Memory
A multi-bank SRAM tightly coupled to the Compute Fabric.

**Characteristics:**
- Deterministic latency
- Explicit data movement
- High bandwidth
- No cache coherence overhead

---

### 3. Memory & Interconnect Domain

Handles **data movement and arbitration** across the SoC.

**Components:**
- AXI-based interconnect / NoC
- Multi-bank system SRAM
- DMA engines
- AXI4 and AXI4-Stream bridges

**Design Philosophy:**
- Explicit DMA-based data transfers
- Streaming over load/store
- Scratchpad > cache for vision workloads

---

### 4. IO / Sensor Domain

Interfaces the SoC with external sensors.

**Components:**
- Camera interface (AXI-Stream)
- IMU interface (SPI / I²C)
- Timestamping and synchronization logic

**Function:**
- Real-time ingestion of visual and inertial data
- Sensor-to-compute streaming

