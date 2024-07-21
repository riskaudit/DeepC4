# %%
import ee
import geemap
import multiprocessing
import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import norm, gamma, f, chi2
import pandas as pd
import IPython.display as disp
import json
import csv 
import os
import datetime
import requests
import shutil
from retry import retry
from datetime import datetime
from datetime import timedelta
import time
from osgeo import gdal
from multiprocessing import cpu_count
from multiprocessing.pool import ThreadPool
%matplotlib inline
ee.Authenticate()
ee.Initialize(opt_url='https://earthengine-highvolume.googleapis.com')

# %%
def ymdList(imgcol):
    def iter_func(image, newlist):
        date = ee.Number.parse(image.date().format("YYYYMMdd"));
        newlist = ee.List(newlist);
        return ee.List(newlist.add(date).sort())
    ymd = imgcol.iterate(iter_func, ee.List([]))
    return list(ee.List(ymd).reduce(ee.Reducer.frequencyHistogram()).getInfo().keys())
@retry(tries=10, delay=5, backoff=2)
def download_url(args):
    t0 = time.time()
    url = downloader(args[0],args[2])
    fn = args[1] 
    try:
        r = requests.get(url)
        with open(fn, 'wb') as f:
            f.write(r.content)
        return(url, time.time() - t0)
    except Exception as e:
        print('Exception in download_url():', e)
@retry(tries=10, delay=5, backoff=2)
def downloader(ee_object,region): 
    try:
        #download image
        if isinstance(ee_object, ee.image.Image):
            # print('Its Image')
            url = ee_object.getDownloadUrl({
                    'scale': 10, #463.831083333,
                    'crs': 'EPSG:4326',
                    'region': region,
                    'format': 'GEO_TIFF'
                })
            return url
        
        #download imagecollection
        elif isinstance(ee_object, ee.imagecollection.ImageCollection):
            print('Its ImageCollection')
            ee_object_new = ee_object.mosaic()
            url = ee_object_new.getDownloadUrl({
                    'scale': 10, #463.83108333310,
                    'crs': 'EPSG:4326',
                    'region': region,
                    'format': 'GEO_TIFF'
                })
            return url
    except:
        print("Could not download")
@retry(tries=10, delay=5, backoff=2)
def download_parallel(args):
    cpus = cpu_count()
    results = ThreadPool(cpus - 1).imap_unordered(download_url, args)
    for result in results:
        print('url:', result[0], 'time (s):', result[1])
t0 = time.time()
from datetime import datetime
from time import mktime

# %%

output_path = '/Users/joshuadimasaka/Desktop/PhD/GitHub/rwa'
ims = []
fns = []
rgns = []
# %%
lsib = ee.FeatureCollection("FAO/GAUL/2015/level0");
fcollection = lsib.filterMetadata('ADM0_NAME','equals','Rwanda');
aoi = ee.Geometry.MultiPolygon(fcollection.getInfo()['features'][0]['geometry']['coordinates'])
Map = geemap.Map()
Map.addLayer(aoi)
Map
# %%
startDATE = ee.Date('2015-01-01')
endDATE = ee.Date('2023-12-31')
im_coll1 = (ee.ImageCollection('GOOGLE/DYNAMICWORLD/V1')
            .filterBounds(aoi)
            .filterDate(startDATE,endDATE)
            .sort('system:time_start'))
ymdlistvariable = ymdList(im_coll1)
ymd_year = [el[:4] for el in ymdlistvariable]
uniq_year = list(map(int, list(set(ymd_year))))
uniq_year.sort()
yr = []
# %%
for i in range(len(uniq_year)):
    startDATE = ee.Date(str(uniq_year[i]) + '-01-01')
    endDATE = ee.Date(str(uniq_year[i]) + '-12-31')

    im1 = im_coll1.filterDate(startDATE,endDATE).select('built').mean().clip(aoi)
    im2 = im_coll1.filterDate(startDATE,endDATE).select('label').mode().clip(aoi)

    ims.append(im1)
    ims.append(im2)

    fns.append(str(output_path+'/'+str(uniq_year[i])+"_DYNNAMICWORLD_builtAveProb.tif"))
    fns.append(str(output_path+'/'+str(uniq_year[i])+"_DYNNAMICWORLD_labelModeCat.tif"))
    
    rgns.append(aoi)
    rgns.append(aoi)

    yr.append(uniq_year[i])
    yr.append(uniq_year[i])

# %%
for i in range(14,16):
    print(i)
    print(yr[i])
    ims_selected = ims[i]
    uniq_year_selected = yr[i]
    fishnet = geemap.fishnet(aoi, rows=10, cols=10)

    if i % 2:
        geemap.download_ee_image_tiles(image=ims_selected, 
                                            features=fishnet, 
                                            prefix=str(uniq_year_selected)+"_DYNNAMICWORLD_labelModeCat_LEVEL0_RWA_",
                                            out_dir=output_path, 
                                            scale=10, 
                                            crs='EPSG:4326')
    else:
        geemap.download_ee_image_tiles(image=ims_selected, 
                                            features=fishnet, 
                                            prefix=str(uniq_year_selected)+"_DYNNAMICWORLD_builtAveProb_LEVEL0_RWA_",
                                            out_dir=output_path, 
                                            scale=10, 
                                            crs='EPSG:4326')
# %%
