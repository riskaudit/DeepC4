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
   - `assess.m` - a script doing initial data exploration on dwelling counts.
   - `constrainedKMeans.m` - a function (original) to perform constrained K-means ([Polk 2024; Bradlet et al 2000](https://www.mathworks.com/matlabcentral/fileexchange/117355-constrained-k-means)).
   - `modelCC.m` - a script performing initial constrained clustering without deep representation learning yet.
2. In `code\downloadEOData`:
   - `downloadDynamicWorldLULC.py` - a script to download built area information from the Dynamic World V1 dataset via Google Earth Engine.
   - `downloadS1_whole.py` - a script to download Sentinel-1 SAR GRD dataset via Google Earth Engine.
   - `downloadS2_whole.py` - a script to download Sentinel-2 MSI dataset via Google Earth Engine.
3. In `code\helper`: 
   - `clusterLatent.m` - a function that inputs learned latent representation (Z) and information about constraints per vulnerability class to output label assignments and corresponding centroid locations.
   - `compareWithMETEORnGEM.m` - a script comparing the outputs of GEM and METEOR and generating figures. 
   - `computeLoss.m` - a function that inputs learned representation, information about constraints per vulnerability class, and bulding groundtruth data to output prediction loss.
   - `computeMetrics.m` - a script that inputs resulting cluster labels to output their corresponding precision (as calculated as the proportion of true positives considering overlapping classes).
   - `constrainedKMeans_DEC.m` - a function modified to consider deeply-learned representations using AutoEncoder and initial cluster centroids using building groundtruth data.
   - `createAE.m` - a function that constructs the architecture (deep and width) of the AutoEncoder network.
   - `crossValidation.m` - a script that performs k-fold cross validation and assesses the resulting precision values.
   - `downstreamMap.m` - a script that applies the learned weights and parameters of the DeepC4 for the entire country of Rwanda consisting of 416 sectors and outputs geospatial maps (in tif format) of roof, wall, height, and macro-taxonomy, including their corresponding precision maps.
   - `encodeConstraints.m` - a function that inputs initial or global-level information about constraints and then recalculates another set of constraints applicable to the available and limited building ground truth data.
   - `evaluateTrainScore.m` - a script that inputs the learned weights and pararameters of the DeepC4 and evaluates its training scores in terms of precision values.
   - `initializeLabels.m` - a function that processes the building ground truth data to output a randomly sampled initial clsuter centroids of labels to avoid computational error and to induce, in the beginning, a desired clustering behavior, given by the building ground truth data.
   - `loadCountryData.m` - a function that inputs all raw data and prepares all information ready for training and analysis.
   - `loadTrainData.m` - a function that loads the training data, which is a subset of the entire country of Rwanda (i.e., only 20 sectors have available building ground truth data).
   - `modelLoss.m` - a function that combines recontruction and prediction losses and computes for the gradient for DeepC4 learning.
   - `preprocessCensus.m` - a function that pre-processes all spreadsheet or tabular data of census information and other expert belief systems to output a machine-learning-ready data or array.
   - `preprocessLabels.m` - a function that pre-processes the raw geospatial map of available building ground truth data.


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