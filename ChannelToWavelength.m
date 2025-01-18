function ChannelToWavelength (varargin)
% Berezin Lab, Washington University 2025
% This function maps wavelenths of the original dataset to the compressed dataset
% 
% Open original Excel file
[originalFile, originalPath] = uigetfile('*.xlsx', 'Select the Original Excel File');
if isequal(originalFile, 0)
    disp('User selected Cancel');
    return;
else
    originalFilePath = fullfile(originalPath, originalFile);
end

% Select the compressed Excel file
[compressedFile, compressedPath] = uigetfile('*.xlsx', 'Select the Compressed Excel File', originalPath);
if isequal(compressedFile, 0)
    disp('User selected Cancel');
    return;
else
    compressedFilePath = fullfile(compressedPath, compressedFile);
end

% Load data from selected Excel files
wavelengthData = readtable(originalFilePath);
channelData = readtable(compressedFilePath);

% Extract data from tables
wavelength = wavelengthData{:, 1};
intensity = wavelengthData{:, 2};

% Adjust the first column of the compressed data to start from 1 and increment by 1
numChannels = height(channelData); % Get the number of rows in the compressed data
channels = (1:numChannels)'; % Create a column vector [1, 2, 3, ..., numChannels]

intensity_channel = channelData{:, 2}; % Extract the intensity data from the compressed file


% Smooth the intensity data using a moving average filter (average over three points)
kernel = ones(1, 3) / 3;
smoothed_intensity = conv(intensity, kernel, 'same');

% Find the single largest peak in both spectra
[maxIntensity, idxWavelength] = max(smoothed_intensity);
peakWavelength = wavelength(idxWavelength);
[maxIntensityChannel, idxChannel] = max(intensity_channel);
peakChannel = channels(idxChannel);

% Include the first and last channel and corresponding wavelengths for a better linear fit
xPoints = [channels(1), peakChannel, channels(end)];
yPoints = [wavelength(1), peakWavelength, wavelength(end)];

% Linear fit using the first, peak, and last points
coeffs = polyfit(xPoints, yPoints, 1);

% Apply the correlation to map all channel numbers to wavelengths
mapped_wavelengths = coeffs(1) * channels + coeffs(2);



% Create the main uifigure
fig1 = uifigure('Name', 'Spectra Matching Analysis', 'Position', [100, 100, 600, 600], 'Color', [0.9 0.9 0.9]);

% Create UI Axes for plotting with modern UI style
ax1 = uiaxes(fig1, 'Position', [50, 450, 500, 100]);
ax2 = uiaxes(fig1, 'Position', [50, 325, 500, 100]);
ax3 = uiaxes(fig1, 'Position', [50, 200, 500, 100]);
ax4 = uiaxes(fig1, 'Position', [50, 75, 500, 100]);

% Set consistent font and style for all UIAxes
all_axes = [ax1, ax2, ax3, ax4];
for ax = all_axes
    ax.FontName = 'Arial';
    ax.FontSize = 10;
    ax.XColor = 'k';
    ax.YColor = 'k';
    ax.Box = 'on'; % Ensures the plot box is drawn around the data
    ax.GridColor = [0.9, 0.9, 0.9]; % Light gray grid
    ax.GridAlpha = 0.3; % Slightly transparent grid
    ax.MinorGridColor = [0.9, 0.9, 0.9];
    ax.MinorGridAlpha = 0.3;
    grid(ax, 'on');
end

% Plotting to visualize the peaks and mappings
plot(ax1, wavelength, intensity, '-b', 'DisplayName', 'Original Spectrum');
hold(ax1, 'on');
plot(ax1, wavelength, smoothed_intensity, '-r', 'DisplayName', 'Smoothed Original Spectrum');
plot(ax1, peakWavelength, maxIntensity, 'g*', 'MarkerSize', 10, 'DisplayName', 'Largest Peak');
title(ax1, 'Original Spectrum');
xlabel(ax1, 'Wavelength');
ylabel(ax1, 'Intensity');
legend(ax1, 'show');

plot(ax2, channels, intensity_channel, '-g', 'DisplayName', 'Compressed Spectrum');
hold(ax2, 'on');
plot(ax2, peakChannel, maxIntensityChannel, 'vr', 'MarkerSize', 8, 'DisplayName', 'Largest Peak');
title(ax2, 'Compressed');
xlabel(ax2, 'Channel');
ylabel(ax2, 'Intensity');
legend(ax2, 'show');

plot(ax3, channels, mapped_wavelengths, '-o', 'DisplayName', 'Matched Wavelengths');
xlabel(ax3, 'Channel');
ylabel(ax3, 'Wavelength');
legend(ax3, 'show');

% Interpolate the channel-based intensities to the same wavelength points as the original spectrum
interpolated_intensities = interp1(mapped_wavelengths, intensity_channel, wavelength, 'linear', 'extrap');

% Normalize the smoothed original intensity data
norm_intensity = (smoothed_intensity - min(smoothed_intensity)) / (max(smoothed_intensity) - min(smoothed_intensity));

% Normalize the interpolated intensity data
norm_interpolated_intensities = (interpolated_intensities - min(interpolated_intensities)) / (max(interpolated_intensities) - min(interpolated_intensities));

% Calculate correlation between the original and interpolated spectra
correlation_value = corr(norm_intensity, norm_interpolated_intensities);

% Calculate RMSE
errors = norm_intensity - norm_interpolated_intensities;  % differences between normalized values
rmse = sqrt(mean(errors.^2));  % square errors, average them, and take the square root

% Update the title of the third plot with RMSE
title(ax3, ['Matching Wavelengths Across Channels (RMSE = ' num2str(rmse) ')']);

plot(ax4, mapped_wavelengths, intensity_channel, '-k', 'DisplayName', 'Intensity by Matched Wavelengths');
title(ax4, 'Compressed spectrum with matched wavelengths');
xlabel(ax4, 'Matched Wavelength');
ylabel(ax4, 'Intensity');
legend(ax4, 'show');

% Display RMSE and Correlation in the command window
disp(['Normalized RMSE: ' num2str(rmse)]);
disp(['Correlation between Original and Compressed Spectra with matched wavelenghts: ' num2str(correlation_value)]);

% Create a separate uifigure for the comparison of normalized spectra
fig2 = uifigure('Name', 'Comparison of Normalized Spectra', 'Position', [100, 100, 600, 300], 'Color', [0.9 0.9 0.9]);

% Create UI Axes in the new uifigure
ax5 = uiaxes(fig2, 'Position', [50, 50, 500, 200]);
ax5.FontName = 'Arial';
ax5.FontSize = 10;
ax5.XColor = 'k';
ax5.YColor = 'k';
ax5.Box = 'on';
ax5.GridColor = [0.9, 0.9, 0.9];
ax5.GridAlpha = 0.3;
ax5.MinorGridColor = [0.9, 0.9, 0.9];
ax5.MinorGridAlpha = 0.3;
grid(ax5, 'on');

% Plot the comparison of normalized spectra
plot(ax5, wavelength, norm_intensity, '-b', 'DisplayName', 'Normalized Original Spectrum');
hold(ax5, 'on');
plot(ax5, wavelength, norm_interpolated_intensities, '-r', 'DisplayName', 'Normalized Compressed Spectrum w. matched wavelenghts');
title(ax5, ['Comparison of Normalized Spectra (Correlation = ' num2str(correlation_value) ')']);
xlabel(ax5, 'Wavelength (nm)');
ylabel(ax5, 'Normalized Intensity');
legend(ax5, 'show');


% Save the new wavelengths file 
fig3 = uifigure('Name', '', 'Position', [600, 300, 370, 175]);
saveResponse = uiconfirm(fig3, 'Do you want to save the new scale?', ...
                         'Save New Wavelengths', ...
                         'Options', {'Yes', 'No'}, ...
                         'DefaultOption', 1, ...
                         'CancelOption', 2);

% Handle the response
if strcmp(saveResponse, 'Yes')
    % Save the new wavelengths Excel file
   delete(fig3)
    [newFileName, newFilePath] = uiputfile('*.xlsx', 'Saving the new scale', originalPath);
    if isequal(newFileName, 0)
        disp('User selected Cancel');
        return;
    else
        delete(fig3)
        newFilePath = fullfile(newFilePath, newFileName);
    end
    
    % Save the new wavelengths in the selected location
    newWavelengthsTable = table(mapped_wavelengths, 'VariableNames', {'Matched_Wavelengths'});
    writetable(newWavelengthsTable, newFilePath);
    disp(['File saved: ', newFilePath]);
    delete(fig3)
else
    delete(fig3)
    disp('User chose not to save the file.');
end


