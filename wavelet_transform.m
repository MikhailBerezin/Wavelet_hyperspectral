function wavelet_transform(varargin)

% Berezin Lab, Washington University 2025
    % Bands are deleted based on the decomposition level, where the level corresponds to a power of 2
    % Coefficient 1.1 is used to increase the number of bands

    % Prompt the user to select a file to load hyperspectral data
    [fileName, pathName] = uigetfile({'*.mat', 'MAT-files (*.mat)'}, 'Select Hyperspectral Data File');
    
    % Check if the user canceled the file selection
    if isequal(fileName, 0)
        disp('User canceled file selection. Exiting script.');
        return;
    end
    
    % Load the selected file
    fullFilePath = fullfile(pathName, fileName);
    try
        loadedData = load(fullFilePath);
        
        % Check for the required variable 'Image'
        if isfield(loadedData, 'Image')
            image = loadedData.Image;
        else
            error('The selected file must contain the variable "Image".');
        end
        
        % Check for optional 'Wavelength' variable
        if isfield(loadedData, 'Wavelength')
            wavelength = loadedData.Wavelength; % Extract Wavelength vector
        else
            disp('No "Wavelength" variable found in the selected file. Using band indices instead.');
            wavelength = 1:size(image, 3); % Use band indices if no wavelength is provided
        end
    catch ME
        disp(['Error loading file: ', ME.message]);
        return;
    end

    % Extract the middle spectrum
    [n_rows, n_cols, n_bands] = size(image);
    mid_row = ceil(n_rows / 2);
    mid_col = ceil(n_cols / 2);
    middle_spectrum = squeeze(image(mid_row, mid_col, :));

    data = reshape(image, [n_rows * n_cols, n_bands]);

    % Plot the middle spectrum
    figure('Name', 'Original Wavelength Spectrum', 'NumberTitle', 'off');
    plot(wavelength, middle_spectrum, 'LineWidth', 2);
    xlabel('Wavelength or Band Index');
    ylabel('Intensity');
    title('Original Wavelength Spectrum');
    grid on;

    % Save the middle spectrum as an Excel file
    try
        excelFileName = fullfile(pathName, 'original_wavelength_spectrum.xlsx');
        spectrumData = [wavelength(:), middle_spectrum(:)]; % Combine wavelength and spectrum into two columns
        writematrix(spectrumData, excelFileName);
        disp(['Middle spectrum saved as Excel file: ', excelFileName]);
    catch ME
        disp(['Error saving middle spectrum to Excel file: ', ME.message]);
    end

    % Continue with wavelet compression logic
    % Create a figure for the Wavelet input dialog
    waveletFig = uifigure('Name', 'Wavelet Input', ...
                          'NumberTitle', 'off', ...
                          'Position', [400 400 350 250], ...
                          'WindowStyle', 'modal', ...
                          'Resize', 'off', ...
                          'AutoResizeChildren', 'off');

    % Color definition for buttons
    green_btn = [77, 194, 115] / 255;
    white_text = [1, 1, 1]; % White text color

    % Wavelet types and decomposition levels
    wavelet_types = {'db1', 'db2', 'db3', 'db4', 'db5', 'db6', 'db7', 'db8', 'db9', 'db10', ...
                     'coif1', 'coif2', 'coif3', 'coif4', 'coif5', ...
                     'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7', 'sym8'};
    decomposition_levels = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10'};

    % Dropdown for wavelet types
    uilabel(waveletFig, 'Text', 'Select the type of wavelet:', ...
            'Position', [20 180 310 22], ...
            'FontColor', white_text);
    waveletDropdown = uidropdown(waveletFig, ...
                                 'Items', wavelet_types, ...
                                 'Position', [20 150 310 22]);

    % Dropdown for decomposition levels
    uilabel(waveletFig, 'Text', 'Select the level of decomposition:', ...
            'Position', [20 120 310 22], ...
            'FontColor', white_text);
    levelDropdown = uidropdown(waveletFig, ...
                               'Items', decomposition_levels, ...
                               'Position', [20 90 310 22]);

    % Apply button
    applyButton = uibutton(waveletFig, 'push', ...
                           'Position', [125 20 100 30], ...
                           'Text', 'Apply', ...
                           'BackgroundColor', green_btn, ...
                           'FontColor', white_text, ...
                           'ButtonPushedFcn', @(btn, event) applyCallback());

  


    % Callback function for the Apply button
   function applyCallback()
        wavelet_type = waveletDropdown.Value;
        level = str2double(levelDropdown.Value);
        close(waveletFig);

        % Create a progress dialog
        progressDialogFigure = uifigure('Name', 'Processing', ...
                                        'Position', [390, 300, 400, 110], ...
                                        'MenuBar', 'none', ...
                                        'ToolBar', 'none', ...
                                        'NumberTitle', 'off', ...
                                        'WindowStyle', 'modal');
        progressDialog = uiprogressdlg(progressDialogFigure, 'Title', 'Please wait...', ...
                                       'Message', 'Starting compression...', ...
                                       'Indeterminate', 'on', ...
                                       'Cancelable', 'of');

        % Reshape data into 2D matrix (pixels x bands)
        wavelet_coeffs = cell(n_rows * n_cols, 1);
        for i = 1:n_rows * n_cols
            if progressDialog.CancelRequested
                disp('User cancelled. Exiting script.');
                close(progressDialog);
                return;
            end
            wavelet_coeffs{i} = wavedec(data(i, :), level, wavelet_type);
        end

        % Update progress dialog
        progressDialog.Value = 0.6;
        progressDialog.Message = 'Applying wavelet transform...';

        % Determine how many bands to keep based on the decomposition level
         keep_fraction = 1.1*2^(-level); % The fraction of bands to keep
         
            % keep_fraction = 1; % Switch to keep all bands 
        num_bands_to_keep = max(3, round(n_bands * keep_fraction)); % Ensure at least 3 bands is kept

        % Trim the coefficients based on the number of bands to keep
        trimmed_coeffs = cell(size(wavelet_coeffs));
        for i = 1:numel(wavelet_coeffs)
            trimmed_coeffs{i} = wavelet_coeffs{i}(1:num_bands_to_keep);
        end
        compressed_data_3D = image(:, :, 1:num_bands_to_keep);
        compressed_wavelength =(1:num_bands_to_keep)';

        % Convert the cell array to a 2D matrix
        compressed_data = cell2mat(trimmed_coeffs);
        compressed_data_3D = reshape(compressed_data, [n_rows, n_cols, num_bands_to_keep]);

        % Prompt the user to select a folder to save the compressed datacube
        pathstr = getappdata(0, 'default_directory');
        prompt_folder = uigetdir(pathstr, 'Select a folder to save the compressed datacube');

        % Check if user clicked cancel
        if isequal(prompt_folder, 0)
            disp('User clicked cancel. Exiting script.');
            close(progressDialog);
            return;
        end

        % Create a unique filename based on the wavelet type and level
        filename = sprintf('Wavelet_compressed_datacube_%s_%d.mat', wavelet_type, level);
        save(fullfile(prompt_folder, filename), 'compressed_data_3D', '-v7.3');

        % Update progress dialog
        progressDialog.Value = 0.9;
        progressDialog.Message = 'Saving compressed data...';

        % Calculate the compression ratio
        original_size = numel(image) * 2; % Each pixel is 2 bytes
        compressed_size = numel(compressed_data) * 2; % Each coefficient is 2 bytes
        compression_ratio = original_size / compressed_size;

        % Close the progress dialog
        progressDialog.Value = 1;
        progressDialog.Message = 'Compression complete!';
        close(progressDialog);        
        close(progressDialogFigure);

        % Extract the middle spectrum from the compressed dataset
        middle_spectrum_compressed = squeeze(compressed_data_3D(mid_row, mid_col, :));

        % Plot the middle spectrum of the compressed dataset
        figure('Name', 'Compressed Wavelength Spectrum', 'NumberTitle', 'off');
        plot(compressed_wavelength, middle_spectrum_compressed, 'LineWidth', 2);
        xlabel('Wavelength or Band Index');
        ylabel('Intensity');
%         title('Compressed Wavelength Spectrum');
        
        grid on;

        % Save the middle spectrum from the compressed dataset as an Excel file
        try
            excelFileNameCompressed = fullfile(pathName, 'compressed_wavelength_spectrum.xlsx');
            spectrumDataCompressed = [compressed_wavelength(:), middle_spectrum_compressed(:)]; % Combine wavelength and spectrum into two columns
            writematrix(spectrumDataCompressed, excelFileNameCompressed);
            disp(['Middle spectrum from the compressed dataset saved as Excel file: ', excelFileNameCompressed]);
        catch ME
            disp(['Error saving compressed spectrum to Excel file: ', ME.message]);
        end

        
        message = sprintf('Wavelet type: %s\nLevel of decomposition: %d\nSize of saved file: %.2f MB\nCompression Ratio: %.2f', ...
                          wavelet_type, level, (dir(fullfile(prompt_folder, filename)).bytes) / 1024^2, compression_ratio);
        msgbox(message, 'Compression', 'help');
        % Define the message and title
message = 'Wavelet compression is complete. You might open the compressed file. You can also match a scale.';
title = 'Compression Complete';

% Create the message box with an 'OK' button
msgbox(message, title, 'help');



    
    end
end