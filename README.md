# Robust Image Segmentation for Foliar Disease Identification

This system detects and classifies tomato leaf diseases via an interactive GUI. It processes digital photographs through noise filtering and contrast enhancement, applying dual segmentation techniques to isolate infections. The pipeline automatically classifies the disease type, calculates infection severity, and provides actionable treatment recommendations for an automated, end-to-end diagnosis.

---

## 🚀 Key Features
* **Dual Segmentation:** High-accuracy boundary detection designed specifically for isolating complex foliar infections.
* **Interactive GUI:** A clean user interface allowing seamless uploading, processing, and visualization of leaf images.
* **Severity Analytics:** Automatically calculates the exact surface area percentage of leaf damage to assess infection progression.
* **Actionable Insights:** Provides diagnostic treatment suggestions right inside the application window based on the classified disease.

---

## 🛠️ Tools & Technologies
* **Development Environment:** MATLAB
* **Core Techniques:** Spatial filtering, contrast stretching, image segmentation, morphological operations

---

## 📊 Dataset & Testing

### Full Dataset
The model and segmentation pipeline were verified using the **PlantVillage Dataset**. You can download the full image set directly from the original source to replicate the complete training and testing phases.

### Local Testing (Quick Start)
A lightweight subset of sample images is included directly in the `/dataset` folder of this repository so you can test the application instantly.

**To run the pipeline:**
1. Open MATLAB and run the `GUIFile.m` script.
2. Click the **Upload Image** button on the interactive GUI.
3. Navigate to the `/dataset` folder inside this project directory.
4. Select any sample image (e.g., `early_blight.png`) to watch the dual-segmentation and automated disease classification execute in real-time.