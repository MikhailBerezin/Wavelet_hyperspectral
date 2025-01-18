# Wavelet_hyperspectral
Performs wavelet comression of hyperspectral conversion

# Wavelet_hyperspectral
Performs wavelet compression of hyperspectral conversion
Wavelet Transform Function
The `wavelet_transform` function is developed by the Berezin Lab, Washington University, 2025. This MATLAB function enables users to apply wavelet compression to hyperspectral datasets. The compression process deletes bands based on the decomposition level, using a coefficient (default: 1.1) to adjust the number of retained bands.
**Key Features**
1. Interactive File Selection:
   - Prompts the user to select a `.mat` file containing hyperspectral data with variables `Image` (required) and `Wavelength` (optional).
2. Wavelet Compression:
   - Supports various wavelet types (`db`, `coif`, `sym`, etc.).
   - Allows selection of decomposition levels to control compression.
3. Visualization:
   - Extracts and plots the middle spectrum of the original and compressed datasets.
4. Data Saving:
   - Saves the middle spectrum of the original and compressed datasets as `.xlsx` files.
   - Saves the compressed datacube as a `.mat` file in the selected folder.
5. Compression Statistics:
   - Calculates the compression ratio and displays a summary dialog with details.

**HOW TO USE**

1. Run the Function:
   Call the function `wavelet_transform` from the MATLAB command window.
2. Select Hyperspectral Data:
   Choose a `.mat` file with an `Image` variable (3D datacube) and optionally `Wavelength`.
3. Configure Compression:
   - Select wavelet type and decomposition level through the user interface.
   - Apply the compression process.
4. View and Save Results:
   - Visualize the middle spectrum before and after compression.
   - Save the compressed datacube and spectrum.
Parameters and Options
- Wavelet Types: Choose from `db1`, `db2`, `coif1`, `sym2`, etc.
- Decomposition Levels: Select levels from `1` to `10`, controlling the compression depth.
- Keep Fraction: Adjusts bands retained based on `1.1 × 2^(-level)` logic.
File Outputs
1. Compressed Datacube:
   - Saved as `Wavelet_compressed_datacube_<wavelet_type>_<level>.mat`.
2. Spectrum Excel Files:
   - Original spectrum: `original_wavelength_spectrum.xlsx`.
   - Compressed spectrum: `compressed_wavelength_spectrum.xlsx`.
Compression Details
- Middle Spectrum:
  The function extracts the spectrum from the central pixel of the dataset and plots both original and compressed spectra for comparison.
- Compression Ratio:
  Calculates the ratio between the original and compressed data sizes.
wavelet_transform();

**Dependencies**
- MATLAB Wavelet Toolbox
- Compatible with MATLAB R2022b or newer.
