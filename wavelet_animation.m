% Generate a spectrum with 5 partially overlapping Gaussian peaks
t = linspace(0, 1, 512);
data = exp(-(t-0.2).^2/0.01) + ...
          0.8*exp(-(t-0.35).^2/0.02) + ...
          0.2*exp(-(t-0.5).^2/0.015) + ...
          0.9*exp(-(t-0.65).^2/0.02) + ...
          0.7*exp(-(t-0.8).^2/0.01);

% % Sample data
%data = randn(100, 256); % Replace with your actual data (100 signals, 256 points each)

% Wavelet settings
waveletName = 'db2'; % Daubechies wavelet
decompositionLevel = 3; % Level of decomposition

% Create a figure for the animation
figure;
for i = 1:size(data, 1)
    % Compute wavelet decomposition
    [coeffs, ~] = wavedec(data(i, :), decompositionLevel, waveletName);
    
    % Plot the coefficients
    plot(coeffs, 'LineWidth', 2);
    grid on;
    title(['Wavelet Decomposition Progress: Signal ', num2str(i)]);
    xlabel('Coefficient Index');
    ylabel('Value');
    
    % Pause or update the animation
    pause(0.1); % Adjust pause duration for desired animation speed
    drawnow; % Ensures the figure updates immediately
end

% Final message
disp('Animation complete.');
