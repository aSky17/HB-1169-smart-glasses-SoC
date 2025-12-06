# HB-1169-smart-glasses-SoC
A RISC-V SoC with a dedicated SLAM Compute Fabric – a set of reusable hardware engines optimized for real-time smart-glass visual SLAM.

SG-SLAM is a heterogeneous RISC-V System-on-Chip (SoC) designed to enable real-time Visual-Inertial SLAM (Simultaneous Localization and Mapping) on smart-glasses-class wearable devices.
The SoC integrates a CVA6 application core with a domain-specific SLAM Compute Fabric, enabling efficient on-device processing of perception workloads such as feature extraction, matching, and pose optimization.

The project is an architecture + RTL design effort. It focuses on designing and synthesizing a modular, configurable, and verifiable hardware subsystem tailored for SLAM workloads — without relying on any proprietary IP.

## Architecture
HB-1169 consists of:

 -> CVA6 RISC-V Core (RV64IMAFC) — 64-bit Linux-capable main core.
 -> SLAM Compute Fabric — Cluster of compute engines for domain-specific SLAM workloads.
 -> System SRAM / DRAM Interface
 -> AXI Interconnect — Connects CPU, fabric, and memory.
 -> Ibex Controller — For always-on IMU and power management tasks.

<p align="center">
  <img src="docs\arch_overview.png" width="350" title="hover text">
</p>