% Berezin Lab, Washington University 2025

function AccurateChannelToWavelengthCropping(varargin)

% This function maps wavelengths of the original dataset to the compressed dataset

% Open original Excel file
[originalFile, originalPath] = uigetfile('*.xlsx', 'Select the Original Excel File');
if isequal(originalFile, 0)
    disp('User selected Cancel');
    return;
else
    originalFilePath = fullfile(originalPath, originalFile);
end

% select the compressed Excel file
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

% Calculate the maximum number of channels that can be deleted (10% from each side)
max_deletable_channels = floor(numChannels * 0.1);

% Initialize variables to track the maximum correlation and optimal range
max_correlation = -1;
optimal_left = 1;
optimal_right = numChannels;

for left = 1:max_deletable_channels
    for right = numChannels:-1:(numChannels - max_deletable_channels + left)
        current_channels = channels(left:right);
        current_intensity_channel = intensity_channel(left:right);
        
        % Ensure there are at least two points for interpolation
        if length(current_channels) < 2
            continue; % Skip this iteration if less than 2 points
        end
        
        % Linear fit using the first and last points
        xPoints = [current_channels(1), current_channels(end)];
        yPoints = [wavelength(1), wavelength(end)];
        coeffs = polyfit(xPoints, yPoints, 1);
        
        % Map the current channels to wavelengths
        mapped_wavelengths = coeffs(1) * current_channels + coeffs(2);
        
        % Interpolate the channel-based intensities to the same wavelength points as the original spectrum
        interpolated_intensities = interp1(mapped_wavelengths, current_intensity_channel, wavelength, 'linear', 'extrap');
        
        % Normalize the smoothed original intensity data
        norm_intensity = (smoothed_intensity - min(smoothed_intensity)) / (max(smoothed_intensity) - min(smoothed_intensity));
        
        % Normalize the interpolated intensity data
        norm_interpolated_intensities = (interpolated_intensities - min(interpolated_intensities)) / (max(interpolated_intensities) - min(interpolated_intensities));
        
        % Calculate correlation between the original and interpolated spectra
        correlation_value = corr(norm_intensity, norm_interpolated_intensities);
        
        % Update the maximum correlation and optimal range
        if correlation_value > max_correlation
            max_correlation = correlation_value;
            optimal_left = left;
            optimal_right = right;
        end
    end
end

% Apply the optimal range
optimal_channels = channels(optimal_left:optimal_right);
optimal_intensity_channel = intensity_channel(optimal_left:optimal_right);

% Identify the bands that have been cut
cut_left_channels = channels(1:optimal_left-1);
cut_right_channels = channels(optimal_right+1:end);
cut_channels = [cut_left_channels; cut_right_channels];

% Convert the list of cut channels to a string for display
cut_channels_str = sprintf('%d, ', cut_channels);
cut_channels_str = cut_channels_str(1:end-2); % Remove the last comma and space

% Display the cut channels in an alert box
% fig4 = uifigure;
% cut_message = ['Channels that have been cut from the compressed dataset: ', cut_channels_str];
% uialert(fig4, cut_message, 'Channels Cut Information', 'Icon', 'info');

% Linear fit using the optimal channels
xPoints = [optimal_channels(1), optimal_channels(end)];
yPoints = [wavelength(1), wavelength(end)];
coeffs = polyfit(xPoints, yPoints, 1);

% Map the optimal channels to wavelengths
mapped_wavelengths = coeffs(1) * optimal_channels + coeffs(2);

% Create the main uifigure
fig1 = uifigure('Name', 'Spectra Matching Analysis', 'Position', [100, 100, 600, 600], 'Icon', 'idcube-icon-transparent.png', 'Color', [0.9 0.9 0.9]);

% Create UI Axes for plotting with modern UI style
ax1 = uiaxes(fig1, 'Position', [50, 450, 500, 100]);
ax2 = uiaxes(fig1, 'Position', [50, 325, 500, 100]);
ax3 = uiaxes(fig1, 'Position', [50, 200, 500, 100]);
ax4 = uiaxes(fig1, 'Position', [50, 75, 500, 100]);

 setappdata(0, 'fig1', fig1)



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
title(ax1, 'Original Spectrum');
xlabel(ax1, 'Wavelength');
ylabel(ax1, 'Intensity');
legend(ax1, 'show');




% Plot 2
plot(ax2, optimal_channels, optimal_intensity_channel, '-g', 'DisplayName', 'Optimal Compressed Spectrum');
title(ax2, 'Optimal Compressed');
xlabel(ax2, 'Channel');
ylabel(ax2, 'Intensity');
legend(ax2, 'show');
setappdata(0, 'ax2', ax2)

% Create toolbar and button attached to the axes
tb2 = axtoolbar(ax2, 'default');  % Attach the toolbar to the uiaxes
btnCopy = axtoolbarbtn(tb2, 'state', 'Icon', 'wave_icon.png', 'Tooltip', 'Copy Spectrum to Clipboard');
btnCopy.ValueChangedFcn = @copy_spectrum_to_clipboard_ax2;

% Plot 3
plot(ax3, optimal_channels, mapped_wavelengths, '-o', 'DisplayName', 'Matched Wavelengths');
xlabel(ax3, 'Channel');
ylabel(ax3, 'Wavelength');
legend(ax3, 'show');
setappdata(0, 'ax3', ax3)

% Create toolbar and button attached to the axes
tb3 = axtoolbar(ax3, 'default');  % Attach the toolbar to the uiaxes
btnCopy = axtoolbarbtn(tb3, 'state', 'Icon', 'wave_icon.png', 'Tooltip', 'Copy Spectrum to Clipboard');
btnCopy.ValueChangedFcn = @copy_spectrum_to_clipboard_ax3;

% Interpolate the optimal intensity data to the same wavelength points as the original spectrum
interpolated_intensities = interp1(mapped_wavelengths, optimal_intensity_channel, wavelength, 'linear', 'extrap');

% Normalize the interpolated intensity data
norm_interpolated_intensities = (interpolated_intensities - min(interpolated_intensities)) / (max(interpolated_intensities) - min(interpolated_intensities));

% Calculate RMSE for the optimal correlation
errors = norm_intensity - norm_interpolated_intensities;  % differences between normalized values
rmse = sqrt(mean(errors.^2));  % square errors, average them, and take the square root

% Update the title of the third plot with RMSE
title(ax3, ['Matching Wavelengths Across Channels (Optimal RMSE = ' num2str(rmse) ')']);

% Plot 4
plot(ax4, mapped_wavelengths, optimal_intensity_channel, '-k', 'DisplayName', 'Intensity by Matched Wavelengths');
title(ax4, 'Optimal Compressed spectrum with matched wavelengths');
xlabel(ax4, 'Matched Wavelength');
ylabel(ax4, 'Intensity');
legend(ax4, 'show');
setappdata(0, 'ax4', ax4)

% Create toolbar and button attached to the axes
tb4 = axtoolbar(ax4, 'default');  % Attach the toolbar to the uiaxes
btnCopy = axtoolbarbtn(tb4, 'state', 'Icon', 'wave_icon.png', 'Tooltip', 'Copy Spectrum to Clipboard');
btnCopy.ValueChangedFcn = @copy_spectrum_to_clipboard_ax4;

% Display RMSE and Correlation in the command window
disp(['Optimal Normalized RMSE: ' num2str(rmse)]);
disp(['Optimal Correlation between Original and Compressed Spectra with matched wavelengths: ' num2str(max_correlation)]);

% Create a separate uifigure for the comparison of normalized spectra
fig2 = uifigure('Name', 'Comparison of Normalized Spectra', 'Position', [100, 100, 600, 300], 'Icon', 'idcube-icon-transparent.png', 'Color', [0.9 0.9 0.9]);

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
plot(ax5, wavelength, norm_interpolated_intensities, '-r', 'DisplayName', 'Normalized Optimal Compressed Spectrum');
title(ax5, ['Comparison of Normalized Spectra (Optimal Correlation = ' num2str(max_correlation) ')']);
xlabel(ax5, 'Wavelength (nm)');
ylabel(ax5, 'Normalized Intensity');
legend(ax5, 'show');

%  save the new wavelengths file
fig3 = uifigure('Name', '', 'Position', [600, 300, 370, 205], 'Icon', 'idcube-icon-transparent.png');
saveResponse = uiconfirm(fig3, {'Channels cut to match the scale. Crop them manually from the compressed dataset:', cut_channels_str,...
        'Save the new scale?'}, ...
                         'Save New Wavelengths', ...
                         'Options', {'Yes', 'No'}, ...
                         'DefaultOption', 1, ...
                         'CancelOption', 2);

% Handle the response
if strcmp(saveResponse, 'Yes')
    % save the new wavelengths Excel file
    delete(fig3);
    [newFileName, newFilePath] = uiputfile('*.xlsx', 'Saving the new scale', originalPath);
    if isequal(newFileName, 0)
        disp('User selected Cancel');
        return;
    else
        newFilePath = fullfile(newFilePath, newFileName);
    end
    
    % Save the new wavelengths in the selected location
    newWavelengthsTable = table(mapped_wavelengths, 'VariableNames', {'Matched_Wavelengths'});
    writetable(newWavelengthsTable, newFilePath);
    disp(['File saved: ', newFilePath]);
else
    disp('User chose not to save the file.');
end

% Clean up the figure after the decision
delete(fig3);

end
function copy_spectrum_to_clipboard_ax2(~, ~)
   
%     fig1 = getappdata(0, 'fig1');
ax2 = getappdata(0, 'ax2');
    
    % Retrieve the xData and yData from the plotted spectrum
    hLine_2 = findobj(ax2, 'Type', 'line');
    if isempty(hLine_2)
        disp('No spectrum found to copy.');
        return;
    end

    xData = get(hLine_2, 'XData');
    yData = get(hLine_2, 'YData');   
    
    % Combine xData and yData into a single matrix
    spectrum = [xData(:), yData(:)];  % Ensuring column vectors
    
    % Convert to string for clipboard
    spectrumStr = sprintf('%.6f\t%.6f\n', spectrum');
    
    % Copy the combined data to the clipboard
    clipboard('copy', spectrumStr);
    
    disp('Spectrum copied to clipboard with axis directions considered.');
end


function copy_spectrum_to_clipboard_ax3(~, ~)
   
%     fig1 = getappdata(0, 'fig1');
ax3 = getappdata(0, 'ax3');
    
    % Retrieve the xData and yData from the plotted spectrum
    hLine_2 = findobj(ax3, 'Type', 'line');
    if isempty(hLine_2)
        disp('No spectrum found to copy.');
        return;
    end

    xData = get(hLine_2, 'XData');
    yData = get(hLine_2, 'YData');   
    
    % Combine xData and yData into a single matrix
    spectrum = [xData(:), yData(:)];  % Ensuring column vectors
    
    % Convert to string for clipboard
    spectrumStr = sprintf('%.6f\t%.6f\n', spectrum');
    
    % Copy the combined data to the clipboard
    clipboard('copy', spectrumStr);
    
    disp('Spectrum copied to clipboard with axis directions considered.');
end
function copy_spectrum_to_clipboard_ax4(~, ~)
   
%     fig1 = getappdata(0, 'fig1');
ax4 = getappdata(0, 'ax4');
    
    % Retrieve the xData and yData from the plotted spectrum
    hLine_2 = findobj(ax4, 'Type', 'line');
    if isempty(hLine_2)
        disp('No spectrum found to copy.');
        return;
    end

    xData = get(hLine_2, 'XData');
    yData = get(hLine_2, 'YData');   
    
    % Combine xData and yData into a single matrix
    spectrum = [xData(:), yData(:)];  % Ensuring column vectors
    
    % Convert to string for clipboard
    spectrumStr = sprintf('%.6f\t%.6f\n', spectrum');
    
    % Copy the combined data to the clipboard
    clipboard('copy', spectrumStr);
    
    disp('Spectrum copied to clipboard with axis directions considered.');
end