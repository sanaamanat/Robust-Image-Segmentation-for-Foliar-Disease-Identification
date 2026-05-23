%% ============================================================
%  Robust Image Segmentation for Foliar Disease Identification
%  COMSATS University Islamabad, Lahore Campus
%  Department of Computer Engineering
%  Course: CPE 415 - Digital Image Processing Lab
%  Student Name : Sana Amanat / Areej Fatima
%  Reg Number   : FA23-BCE-108 / FA23-BCE-019
%% ============================================================

clc;          % Clear command window
clear all;    % Clear all variables
close all;    % Close all figure windows

%% ============================================================
%  STEP 1: READ IMAGE (POPUP WINDOW)
%% ============================================================

% Results folder path
results_path = 'C:\Users\SHOP WITH HOPE\Desktop\dip_project\FoliarDisease\results\';

% POPUP WINDOW - Browse and select any image
[filename, filepath] = uigetfile({'*.jpg;*.jpeg;*.png;*.JPG', ...
    'Image Files (*.jpg, *.jpeg, *.png)'}, ...
    'SELECT A LEAF IMAGE');

% Check if user cancelled
if isequal(filename, 0)
    error('No image selected! Please run again and select an image.');
end

% Read selected image
img_original = imread(fullfile(filepath, filename));
image_files(1).name = filename;

fprintf('Selected Image: %s\n', filename);

% Display Original Image
figure(1);
imshow(img_original);
title({'STEP 1: Original Leaf Image', filename}, ...
       'FontSize', 12, ...
       'FontWeight', 'bold', ...
       'Interpreter', 'none');
disp('Step 1 Done: Image Loaded Successfully!');

%% ============================================================
%  STEP 2: PREPROCESSING - Technique 1 (Gaussian Filter)
%% ============================================================

% Convert to grayscale
img_gray = rgb2gray(img_original);

% Apply Gaussian Filter (removes noise)
img_gaussian = imgaussfilt(img_gray, 2);

% Display comparison
figure(2);
subplot(1,2,1); 
imshow(img_gray);
title('Original Grayscale', 'FontSize', 12, 'Interpreter', 'none');
subplot(1,2,2);
imshow(img_gaussian);
title('After Gaussian Filter', 'FontSize', 12, 'Interpreter', 'none');
sgtitle('STEP 2: Gaussian Noise Filtering', 'FontSize', 14);
disp('Step 2 Done: Gaussian Filter Applied!');

%% ============================================================
%  STEP 3: PREPROCESSING - Technique 2 (CLAHE Enhancement)
%% ============================================================

% Apply CLAHE (improves contrast)
img_enhanced = adapthisteq(img_gaussian);

% Display comparison
figure(3);
subplot(1,3,1); imshow(img_gray);
title('Original Gray', 'FontSize', 11, 'Interpreter', 'none');
subplot(1,3,2); imshow(img_gaussian);
title('After Gaussian', 'FontSize', 11, 'Interpreter', 'none');
subplot(1,3,3); imshow(img_enhanced);
title('After CLAHE', 'FontSize', 11, 'Interpreter', 'none');
sgtitle('STEP 3: CLAHE Contrast Enhancement', 'FontSize', 14);
disp('Step 3 Done: CLAHE Enhancement Applied!');

%% ============================================================
%  STEP 4: SEGMENTATION - Method 1 (Otsu Thresholding)
%% ============================================================

% Auto calculate threshold using Otsu method
thresh = graythresh(img_enhanced);

% Create binary mask
img_binary = imbinarize(img_enhanced, thresh);

% Remove small noise particles
img_binary = bwareaopen(img_binary, 100);

% Display
figure(4);
subplot(1,2,1); imshow(img_original);
title('Original Image', 'FontSize', 12, 'Interpreter', 'none');
subplot(1,2,2); imshow(img_binary);
title('Otsu Segmentation Result', 'FontSize', 12, 'Interpreter', 'none');
sgtitle('STEP 4: Otsu Thresholding Segmentation', 'FontSize', 14);
disp('Step 4 Done: Otsu Segmentation Complete!');

%% ============================================================
%  STEP 5: SEGMENTATION - Method 2 (HSV Color-Based)
%  Works with Image Processing Toolbox only!
%% ============================================================

% Resize for faster processing
img_resized = imresize(img_original, [256 256]);

% Convert to HSV color space
img_hsv = rgb2hsv(img_resized);

% Extract channels
H = img_hsv(:,:,1);  % Hue
S = img_hsv(:,:,2);  % Saturation
V = img_hsv(:,:,3);  % Value (brightness)

%% 1. Threshold Segmentation
% Segment HEALTHY areas (green pixels)
healthy_mask = (H > 0.20 & H < 0.45) & S > 0.20;

% Segment DISEASED areas (brown/yellow pixels)
diseased_mask = (H > 0.05 & H < 0.20) & S > 0.25;

% FIX 1: Segment BACKGROUND (Adjusted for dark textured charcoal gray background)
background_mask = (S < 0.20) & (V < 0.50);


%% 2. Generate Colored Segmentation Map
seg_result = zeros(256, 256, 3, 'uint8');
seg_result(:,:,1) = uint8(diseased_mask)   * 255; % Red   = diseased
seg_result(:,:,2) = uint8(healthy_mask)    * 200; % Green = healthy
seg_result(:,:,3) = uint8(background_mask) * 255; % Blue  = background

% Display
figure(5);
subplot(1,3,1); imshow(img_resized);
title('Original Leaf', 'FontSize', 11, 'Interpreter', 'none');
subplot(1,3,2); imshow(seg_result);
title('Color Map (R=Disease G=Healthy B=BG)', 'FontSize', 11, 'Interpreter', 'none');
subplot(1,3,3); imshow(diseased_mask);
title('Diseased Region Only', 'FontSize', 11, 'Interpreter', 'none');
sgtitle('STEP 5: HSV Color-Based Segmentation', 'FontSize', 14);
disp('Step 5 Done: Color Segmentation Complete!');

%% ============================================================
%  STEP 6: DISEASE DETECTION + SUGGESTION FEATURE
%% ============================================================

%% Calculate Disease and Health Ratios
% FIX 2: Calculate total plant area instead of the whole image canvas [numel(H)]
total_leaf_pixels = sum(healthy_mask(:)) + sum(diseased_mask(:));

% Prevent division by zero errors if an image is completely background
if total_leaf_pixels == 0
    total_leaf_pixels = 1; 
end

% Ratios are now relative to the actual leaf size
brown_ratio   = sum(diseased_mask(:)) / total_leaf_pixels;
yellow_ratio  = sum((H > 0.12 & H < 0.20 & S > 0.4), 'all') / total_leaf_pixels;
healthy_ratio = sum(healthy_mask(:)) / total_leaf_pixels;


% Disease Classification Logic
if  brown_ratio > 0.15 && brown_ratio > yellow_ratio
    disease = 'Early Blight';
    severity   = 'HIGH';
    suggestion = ['1. Apply Mancozeb or Chlorothalonil fungicide.' newline ...
                  '2. Remove infected plants immediately.' newline ...
                  '3. Do NOT compost diseased material.' newline ...
                  '4. Avoid working in wet conditions.' newline ...
                  '5. Use resistant tomato varieties next season.'];

elseif brown_ratio > 0.05 && brown_ratio <= 0.15
    disease    = 'Leaf Mold';
    severity   = 'MEDIUM';
    suggestion = ['1. Improve air circulation around plants.' newline ...
                  '2. Reduce humidity levels in growing area.' newline ...
                  '3. Apply Potassium bicarbonate spray.' newline ...
                  '4. Remove affected leaves carefully.' newline ...
                  '5. Water at base only, not on leaves.'];

elseif healthy_ratio > 0.80 && brown_ratio < 0.10 && yellow_ratio < 0.10

    disease    = 'Healthy Leaf';
    severity   = 'NONE';
    suggestion = ['1. No treatment needed at this time.' newline ...
                  '2. Continue regular watering schedule.' newline ...
                  '3. Apply balanced fertilizer monthly.' newline ...
                  '4. Monitor regularly for early disease signs.' newline ...
                  '5. Maintain proper plant spacing.'];
else
    disease    = 'Unknown - Needs Manual Check';
    severity   = 'UNKNOWN';
    suggestion = ['1. Take a clearer image for better analysis.' newline ...
                  '2. Consult an agricultural expert.' newline ...
                  '3. Check for pest damage manually.'];
end

% Display result on image
figure(6);
imshow(img_resized);
title(sprintf('Detected: %s  |  Severity: %s', disease, severity), ...
      'FontSize', 13, ...
      'Color', 'red', ...
      'FontWeight', 'bold', ...
      'Interpreter', 'none');
sgtitle('STEP 6: Disease Detection Result', 'FontSize', 14);

% Print result to Command Window
fprintf('\n================================================\n');
fprintf('         DISEASE DETECTION RESULT              \n');
fprintf('================================================\n');
fprintf(' Image Analyzed  : %s\n', image_files(1).name);
fprintf(' Detected Disease: %s\n', disease);
fprintf(' Severity Level  : %s\n', severity);
fprintf('------------------------------------------------\n');
fprintf(' Color Analysis:\n');
fprintf('   Brown  Ratio  : %.2f%%\n', brown_ratio  * 100);
fprintf('   Yellow Ratio  : %.2f%%\n', yellow_ratio * 100);
fprintf('   Healthy Ratio : %.2f%%\n', healthy_ratio * 100);
fprintf('------------------------------------------------\n');
fprintf(' TREATMENT SUGGESTION:\n%s\n', suggestion);
fprintf('================================================\n\n');
disp('Step 6 Done: Disease Detected & Suggestion Generated!');

%% ============================================================
%  STEP 7: QUALITY METRICS (PSNR & MSE)
%% ============================================================

% Convert to double for calculation
original_d = double(img_gray);
enhanced_d = double(img_enhanced);

% Calculate MSE
MSE = mean((original_d(:) - enhanced_d(:)).^2);

% Calculate PSNR
if MSE == 0
    PSNR = Inf;
else
    PSNR = 10 * log10(255^2 / MSE);
end

% Display metrics figure
figure(7);
subplot(1,2,1);
imshow(img_gray);
title('Original Grayscale', 'FontSize', 12, 'Interpreter', 'none');
subplot(1,2,2);
imshow(img_enhanced);
title(sprintf('Enhanced | PSNR: %.2f dB | MSE: %.4f', PSNR, MSE), ...
      'FontSize', 11, 'Interpreter', 'none');
sgtitle('STEP 7: Quality Metrics Evaluation', 'FontSize', 14);

% Print metrics
fprintf('================================================\n');
fprintf('           QUALITY METRICS REPORT              \n');
fprintf('================================================\n');
fprintf(' MSE  : %.4f  (lower = better quality)\n', MSE);
fprintf(' PSNR : %.2f dB (higher = better quality)\n', PSNR);
if PSNR > 30
    fprintf(' Result: EXCELLENT quality enhancement!\n');
else
    fprintf(' Result: Acceptable enhancement.\n');
end
fprintf('================================================\n\n');
disp('Step 7 Done: Quality Metrics Calculated!');

%% ============================================================
%  STEP 8: SAVE ALL RESULTS TO RESULTS FOLDER
%% ============================================================

% Save Figure 1 - Original Image
figure(1);
saveas(gcf, fullfile(results_path, '01_Original_Image.png'));

% Save Figure 2 - Gaussian Filter
figure(2);
saveas(gcf, fullfile(results_path, '02_Gaussian_Filter.png'));

% Save Figure 3 - CLAHE Enhancement
figure(3);
saveas(gcf, fullfile(results_path, '03_CLAHE_Enhancement.png'));

% Save Figure 4 - Otsu Segmentation
figure(4);
saveas(gcf, fullfile(results_path, '04_Otsu_Segmentation.png'));

% Save Figure 5 - Color Segmentation
figure(5);
saveas(gcf, fullfile(results_path, '05_Color_Segmentation.png'));

% Save Figure 6 - Disease Detection
figure(6);
saveas(gcf, fullfile(results_path, '06_Disease_Detection.png'));

% Save Figure 7 - Quality Metrics
figure(7);
saveas(gcf, fullfile(results_path, '07_Quality_Metrics.png'));

% Save Text Report
report_file = fullfile(results_path, 'Disease_Report.txt');
fid = fopen(report_file, 'w');
fprintf(fid, '================================================\n');
fprintf(fid, '  FOLIAR DISEASE DETECTION REPORT\n');
fprintf(fid, '  COMSATS University Islamabad, Lahore Campus\n');
fprintf(fid, '  CPE 415 - Digital Image Processing Lab\n');
fprintf(fid, '  Student : Sana Amanat | FA23-BCE-108\n');
fprintf(fid, '================================================\n');
fprintf(fid, ' Image Analyzed  : %s\n', image_files(1).name);
fprintf(fid, ' Detected Disease: %s\n', disease);
fprintf(fid, ' Severity Level  : %s\n', severity);
fprintf(fid, '------------------------------------------------\n');
fprintf(fid, ' Color Analysis:\n');
fprintf(fid, '   Brown  Ratio  : %.2f%%\n', brown_ratio  * 100);
fprintf(fid, '   Yellow Ratio  : %.2f%%\n', yellow_ratio * 100);
fprintf(fid, '   Healthy Ratio : %.2f%%\n', healthy_ratio * 100);
fprintf(fid, '------------------------------------------------\n');
fprintf(fid, ' TREATMENT SUGGESTION:\n%s\n', suggestion);
fprintf(fid, '================================================\n');
fprintf(fid, ' QUALITY METRICS:\n');
fprintf(fid, '   MSE  : %.4f\n', MSE);
fprintf(fid, '   PSNR : %.2f dB\n', PSNR);
fprintf(fid, '================================================\n');
fclose(fid);

fprintf('\n All 7 figures + text report saved!\n');
disp('Step 8 Done: All Results Saved Successfully!');

%% ============================================================
%  FINAL SUMMARY
%% ============================================================

fprintf('\n================================================\n');
fprintf('        PROJECT COMPLETE SUMMARY                \n');
fprintf('================================================\n');
fprintf(' Student         : Sana Amanat - Areej Fatima\n');
fprintf(' Reg No          : FA23-BCE-108 - FA23-BCE-019\n');
fprintf(' Preprocessing 1 : Gaussian Filter\n');
fprintf(' Preprocessing 2 : CLAHE Enhancement\n');
fprintf(' Segmentation  1 : Otsu Thresholding\n');
fprintf(' Segmentation  2 : HSV Color-Based\n');
fprintf(' Disease Found   : %s\n', disease);
fprintf(' Severity        : %s\n', severity);
fprintf(' PSNR            : %.2f dB\n', PSNR);
fprintf(' MSE             : %.4f\n', MSE);
fprintf(' Results Saved   : %s\n', results_path);
fprintf('================================================\n');
disp('ALL STEPS COMPLETED! PROJECT IS READY!');