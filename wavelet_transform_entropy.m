function wavelet_transform(varargin)
    % Berezin Lab, Washington University 2025
    % Perform wavelet compression with entropy-based classification
    % Sharp spectra (low entropy): Use Db1
    % Smooth spectra (high entropy): Use Db3

    % Prompt the user to select a file to load hyperspectral data
    [fileName, pathName] = uigetfile({'*.mat', 'MAT-files (*.mat)'}, 'Select Hyperspectral Data File');
    
    if isequal(fileName, 0)
        disp('User canceled file selection. Exiting script.');
        return;
    end
    
    % Load the selected file
    fullFilePath = fullfile(pathName, fileName);
    try
        loadedData = load(fullFilePath);
        if isfield(loadedData, 'Image')
            image = loadedData.Image;
        else
            error('The selected file must contain the variable "Image".');
        end
        
        if isfield(loadedData, 'Wavelength')
            wavelength = loadedData.Wavelength;
        else
            disp('No "Wavelength" variable found in the selected file. Using band indices instead.');
            wavelength = 1:size(image, 3);
        end
    catch ME
        disp(['Error loading file: ', ME.message]);
        return;
    end

    % Reshape data into 2D matrix (pixels x bands)
    [n_rows, n_cols, n_bands] = size(image);
    data = reshape(image, [n_rows * n_cols, n_bands]);

    % Compute entropy for each spectrum
    entropyThreshold = 8.78; % Adjust based on data
    entropyValues = zeros(n_rows * n_cols, 1);
    waveletTypes = cell(n_rows * n_cols, 1);
tic
    for i = 1:n_rows * n_cols
        spectrum = data(i, :);
        spectrum = spectrum / sum(spectrum + eps); % Normalize
        entropyValues(i) = -sum(spectrum .* log2(spectrum + eps)); % Shannon entropy
        
        % Classify based on entropy
        if entropyValues(i) > entropyThreshold
            waveletTypes{i} = 'db3'; % Smooth spectrum
        else
            waveletTypes{i} = 'db1'; % Sharp spectrum
        end
    end

    % Reshape entropy values and classification into 2D
    entropyMap = reshape(entropyValues, [n_rows, n_cols]);
    classificationMap = reshape(cellfun(@(x) strcmp(x, 'db3'), waveletTypes), [n_rows, n_cols]);

    % Visualization of classification
    figure('Name', 'Entropy Classification', 'NumberTitle', 'off');
%     imagesc(classificationMap);
       
%     colormap([1 0 0; 0 0 1]); % Red for sharp (Db1), Blue for smooth (Db3)

     imagesc(entropyMap);
    colorbar('Ticks', [0, 1], 'TickLabels', {'Sharp (Db1)', 'Smooth (Db3)'});
    title('Classification Map: Sharp (Red) vs Smooth (Blue)');
    xlabel('X Pixel');
    ylabel('Y Pixel');

    % Perform wavelet compression based on entropy classification
    level = 3; % Example decomposition level
    wavelet_coeffs = cell(n_rows * n_cols, 1);
    for i = 1:n_rows * n_cols
        waveletType = waveletTypes{i};
        wavelet_coeffs{i} = wavedec(data(i, :), level, waveletType);
    end
toc
    % Determine how many bands to keep based on the decomposition level
    keep_fraction = 1.1 * 2^(-level); % Fraction of bands to keep
    num_bands_to_keep = max(3, round(n_bands * keep_fraction));
    trimmed_coeffs = cell(size(wavelet_coeffs));
    for i = 1:numel(wavelet_coeffs)
        trimmed_coeffs{i} = wavelet_coeffs{i}(1:num_bands_to_keep);
    end

    % Convert to 3D matrix
    compressed_data = cell2mat(trimmed_coeffs);
    compressed_data_3D = reshape(compressed_data, [n_rows, n_cols, num_bands_to_keep]);

    % Save the compressed datacube
    prompt_folder = uigetdir(pathName, 'Select a folder to save the compressed datacube');
    if isequal(prompt_folder, 0)
        disp('User clicked cancel. Exiting script.');
        return;
    end

    filename = sprintf('Wavelet_compressed_entropy_%d.mat', level);
    Image = compressed_data_3D;
    save(fullfile(prompt_folder, filename), 'Image', '-v7.3');

    % Calculate compression ratio
    original_size = numel(image) * 2; % Bytes
    compressed_size = numel(compressed_data) * 2; % Bytes
    compression_ratio = original_size / compressed_size;

    % Display results
    disp(['Compression complete. Compression Ratio: ', num2str(compression_ratio)]);
end
