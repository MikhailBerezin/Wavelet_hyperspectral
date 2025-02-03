
# Wavelet_hyperspectral

*Cite: Hridoy Biswas, Rui Tang, Shamim Mollah, Mikhail Berezin, "Wavelet-Based Compression Method for Scale-Preserving SWIR Hyperspectral Data" 2025


The `wavelet_transform` function is developed by the Berezin Lab, Washington University, 2025. This MATLAB function enables users to apply wavelet compression to hyperspectral datasets. The compression process deletes bands based on the decomposition level, using a compression coefficient (default: 1.1) to adjust the number of retained bands. The parameter can be adjusted if nessesary


**STEP 1.**  

Performs wavelet compression of hyperspectral data with `wavelet_transform' or with 'wavelet_transform_entropy'

**Key Features**
1. Interactive File Selection:
   - Prompts the user to select a `.mat` file containing hyperspectral data with variables `Image` (required) and `Wavelength` (optional).
2. Wavelet Compression:
   - Supports various wavelet types (`db`, `coif`, `sym`, etc.).
   - Allows selection of decomposition levels to control compression.
3. Visualization:
   - Extracts and plots the spectrum of the original and compressed datasets (the middle part of the image is used as an example).
4. Data Saving:
   - Saves the middle spectrum of the original and compressed datasets as `.xlsx` files.
   - Saves the compressed datacube as a `.mat` file in the selected folder.
5. Compression Statistics:
   - Calculates the compression ratio and displays a summary dialog with details.

**HOW TO USE**

1. Run the Function:
   - Call the function `wavelet_transform` from the MATLAB command window. Alternatively run the function 'wavelet_transform_entropy'
2. Select Hyperspectral Data:
   - Choose a `.mat` file with an `Image` variable (3D datacube) and optionally `Wavelength`.
3. Configure Compression:
   - Select wavelet type and decomposition level through the user interface.
   - Apply the compression process.
4. View and Save Results:
   - Visualize the middle spectrum before and after compression.
   - Save the compressed datacube and spectrum.

**Parameters and Options
    - Wavelet Types: Choose from `db1`, `db2`, `coif1`, `sym2`, etc.
    - Decomposition Levels: Select levels from `1` to `10`, controlling the compression depth. For the entropy function select a threshold, and two different DbN
    - Crop bands: Adjusts bands retained using a retaining parameter (default 1.1).

**File Outputs**
1. Compressed Datacube:
   - Saved as `Wavelet_compressed_datacube_<wavelet_type>_<level>.mat`.
2. Spectrum Excel Files:
   - Original spectrum: `original_wavelength_spectrum.xlsx`.
   - Compressed spectrum: `compressed_wavelength_spectrum.xlsx`.

**Compression Details
   - Middle Spectrum: The function extracts the spectrum from the central pixel of the dataset and plots both original and compressed spectra for comparison.
   - Compression Ratio: Calculates the ratio between the original and compressed data sizes.


**STEP 2.**  
# ChannelToWavelength Function

The function maps the wavelengths of the original dataset to the compressed dataset, ensuring that the relationship between channels and wavelengths is accurately preserved. This function is part of the **Berezin Lab** at **Washington University**, 2025.

**Key Features**
    - Opens and processes two Excel files: the original dataset and the compressed dataset.
    - Smooths the intensity data using a moving average filter.
    - Finds the largest peaks in both spectra to establish a mapping.
    - Maps all channels to wavelengths using a linear fit.
    - Visualizes the original, compressed, and mapped spectra using modern MATLAB UI features.
    - Calculates correlation and RMSE between normalized spectra.
    - Allows users to save the new wavelength scale in an Excel file.

**User Interface**
    - Displays the original spectrum, compressed spectrum, matched wavelengths, and compressed spectrum with matched wavelengths.
    - Compares normalized spectra to visualize the matching quality.
    - A dialog box prompts the user to save the new wavelength scale.

**How to Use**
    1. Run the function in MATLAB.
    2. Select the **Original Excel spectra file** containing wavelengths and intensities.
    3. Select the **Compressed Excel spectra file** containing a list of channels and intensities.
    4. View the plots for original, compressed, and matched spectra.
    5. Check the correlation and RMSE in the command window.
    6. Save the new wavelength scale as an Excel file.

 **Output**
    - Displays the correlation coefficient between the original and compressed spectra.
    - Shows the root mean square error for matched spectra.
    - Saves the new wavelength scale file as an Excel file.

**Function Details**
    - Smoothing: Averages intensity over three points.
    - Mapping: Uses a linear fit between channels and wavelengths based on the first, peak, and last points.

** Alternative STEP 2**: 
function AccurateChannelToWavelengthCropping(varargin)
similar to the STEP 1 except it crops the bands of the compressed image to improve the matching process


# Dependencies
    - MATLAB Wavelet Toolbox
    - Compatible with MATLAB R2022b or newer.


