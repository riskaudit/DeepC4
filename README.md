# **Deep Conditional Census-Constrained Clustering (DeepC4) for Large-scale Multi-task Disaggregation of Urban Morphology**

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8099812.svg)](https://doi.org/10.5281/zenodo.13119552) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


In addition to our [Zenodo](https://doi.org/10.5281/zenodo.13119552) data repository, this GitHub repository contains the codes for our research **(Spatial Disaggregation of Rwandan Building Exposure and Vulnerability via Weakly Supervised Conditional Census-Constrained Clustering (C4) using Earth Observation Data)** submiited for American Geophysical Union Annual Meeting 2024 to be held in Washington, D.C. on 9th-13th of December 2024. If you have any questions, please contact [jtd33@cam.ac.uk](mailto:jtd33@cam.ac.uk).

---

## **1. AGU24 Presentation Details**

+ ✅ NH23B - Advancing Building & Population Inventories to Support Equity & Inclusion
+ 📍 Hall B-C (Poster Hall), Walter E. Washington Convention Center
+ 🗓️ Tuesday, 10 Dec 2024
+ 🕚 13:40 - 17:30 EST
+ 🌐 https://agu.confex.com/agu/agu24/meetingapp.cgi/Paper/1610379  
+ #️⃣ Poster Number: NH23B-2291
+ 🤝 iPoster: https://agu24.ipostersessions.com/Default.aspx?s=5F-F4-76-49-91-04-29-F9-F5-AD-B8-AC-5A-6E-54-66

## **2. Installation**

This code depends on [MATLAB R2024b](https://uk.mathworks.com/), [QGIS 3.28.13-Firenze](https://www.qgis.org/en/site/forusers/download.html), or any newer versions. The MATLAB toolboxes for [Mapping](https://uk.mathworks.com/products/mapping.html), [Financial](https://uk.mathworks.com/products/finance.html), [Statistics and Machine Learning](https://uk.mathworks.com/help/stats/getting-started-12.html), and [Deep Learning](https://uk.mathworks.com/help/deeplearning/ug/deep-learning-in-matlab.html) must also be installed to enable the data import and export of GeoTIFF files (*.tif) and perform the deep learning training.

## **3. Code**

Due to the limited file storage capacity in GitHub, we provide all data and results (>45GB) in our Zenodo repository. The `DeepC4.m` is the main script, which calls and implement all other functions. 

1. In `code\baseline`:
   - `analyzeLabels.m`
   - `assess.m`
   - `constrainedKMeans.m`
   - `modelCC.m`
2. In `code\downloadEOData`:
   - `downloadDynamicWorldLULC.py`
   - `downloadS1_whole.py`
   - `downloadS2_whole.py`
3. In `code\helper`: 
   - `clusterLatent.m`
   - `compareWithMETEORnGEM.m`
   - `computeLoss.m`
   - `computeMetrics.m`
   - `constrainedKMeans_DEC.m`
   - `createAE.m`
   - `crossValidation.m` 
   - `downstreamMap.m`
   - `encodeConstraints.m`
   - `evaluateTrainScore.m`
   - `initializeLabels.m`
   - `loadCountryData.m`
   - `loadTrainData.m`
   - `modelLoss.m`
   - `preprocessCensus.m`
   - `preprocessLabels.m`


## **4. Repository Structure**

```
.
├── DeepC4.m
├── LICENSE
├── README.md
└── code
    ├── baseline
    │   ├── analyzeLabels.m
    │   ├── assess.m
    │   ├── constrainedKMeans.m
    │   └── modelCC.m
    ├── downloadEOData
    │   ├── downloadDynamicWorldLULC.py
    │   ├── downloadS1_whole.py
    │   └── downloadS2_whole.py
    └── helper
        ├── clusterLatent.m
        ├── compareWithMETEORnGEM.m
        ├── computeLoss.m
        ├── computeMetrics.m
        ├── constrainedKMeans_DEC.m
        ├── createAE.m
        ├── crossValidation.m
        ├── downstreamMap.m
        ├── encodeConstraints.m
        ├── evaluateTrainScore.m
        ├── initializeLabels.m
        ├── loadCountryData.m
        ├── loadTrainData.m
        ├── modelLoss.m
        ├── preprocessCensus.m
        └── preprocessLabels.m
```

## **7. Acknowledgements**
This work is funded by the **UKRI Centre for Doctoral Training in Application of Artificial Intelligence to the study of Environmental Risks (AI4ER) (EP/S022961/1)** and the **Helmholtz
Information & Data Science Academy (HIDA)** for providing financial support enabling a short-term research stay in the German Aerospace Center.

## **8. Want to cite this GitHub repository?**
Feel free to use our recommended BibTex-formatted entry below.
```
@proceedings{dimasaka_2024_14207720,
  title        = {{Deep Conditional Census-Constrained Clustering 
                   (DeepC4) for Large-scale Multi-task Disaggregation
                   of Urban Morphology}},
  year         = 2024,
  publisher    = {Zenodo},
  month        = nov,
  doi          = {10.5281/zenodo.14207720},
  url          = {https://doi.org/10.5281/zenodo.14207720}
}
```