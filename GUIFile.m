
classdef FoliarDiseaseApp < matlab.apps.AppBase

    % Properties
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        TitleLabel      matlab.ui.control.Label
        UploadButton    matlab.ui.control.Button
        AnalyzeButton   matlab.ui.control.Button
        SaveButton      matlab.ui.control.Button
        OriginalAxes    matlab.ui.control.UIAxes
        ResultAxes      matlab.ui.control.UIAxes
        SegmentAxes     matlab.ui.control.UIAxes
        DiseaseLabel    matlab.ui.control.Label
        SeverityLabel   matlab.ui.control.Label
        PSNRLabel       matlab.ui.control.Label
        MSELabel        matlab.ui.control.Label
        SuggestionArea  matlab.ui.control.TextArea
        StatusLabel     matlab.ui.control.Label
        img_original    
        filename        
        filepath        
    end

    methods (Access = private)

        % Analyze Button Pushed
        function AnalyzeButtonPushed(app, ~)

            if isempty(app.img_original)
                app.StatusLabel.Text = 'Please upload an image first!';
                app.StatusLabel.FontColor = [1 0 0];
                return;
            end

            app.StatusLabel.Text = 'Analyzing image...';
            app.StatusLabel.FontColor = [0 0.5 0];
            drawnow;

            img = app.img_original;

            %% PREPROCESSING
            % Gaussian Filter
            img_gray     = rgb2gray(img);
            img_gaussian = imgaussfilt(img_gray, 2);

            % CLAHE Enhancement
            img_enhanced = adapthisteq(img_gaussian);

            %% SEGMENTATION - Otsu
            thresh     = graythresh(img_enhanced);
            img_binary = imbinarize(img_enhanced, thresh);
            img_binary = bwareaopen(img_binary, 100);

            %% SEGMENTATION - HSV Color Based
            img_resized     = imresize(img, [256 256]);
            img_hsv         = rgb2hsv(img_resized);
            H               = img_hsv(:,:,1);
            S               = img_hsv(:,:,2);
            V               = img_hsv(:,:,3);
            
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


           %% 3. Calculate Disease and Health Ratios
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


            if  yellow_ratio > 0.10 && yellow_ratio > brown_ratio
                disease    = 'Late Blight';
                severity   = 'HIGH';
                suggestion = sprintf(['Treatment Suggestions:\n' ...
                    '1. Apply Copper-based fungicide immediately.\n' ...
                    '2. Remove and destroy all infected leaves.\n' ...
                    '3. Avoid overhead watering.\n' ...
                    '4. Ensure proper plant spacing.\n' ...
                    '5. Rotate crops next season.']);

            elseif brown_ratio > 0.15 && brown_ratio > yellow_ratio
    disease = 'Early Blight';
                severity   = 'HIGH';
                suggestion = sprintf(['Treatment Suggestions:\n' ...
                    '1. Apply Mancozeb fungicide immediately.\n' ...
                    '2. Remove infected plants immediately.\n' ...
                    '3. Do NOT compost diseased material.\n' ...
                    '4. Avoid working in wet conditions.\n' ...
                    '5. Use resistant varieties next season.']);

            elseif brown_ratio > 0.05 && brown_ratio <= 0.15
                disease    = 'Leaf Mold';
                severity   = 'MEDIUM';
                suggestion = sprintf(['Treatment Suggestions:\n' ...
                    '1. Improve air circulation around plants.\n' ...
                    '2. Reduce humidity levels.\n' ...
                    '3. Apply Potassium bicarbonate spray.\n' ...
                    '4. Remove affected leaves carefully.\n' ...
                    '5. Water at base only, not on leaves.']);

            elseif healthy_ratio > 0.80 && brown_ratio < 0.10 && yellow_ratio < 0.10
                disease    = 'Healthy Leaf';
                severity   = 'NONE';
                suggestion = sprintf(['No Treatment Needed:\n' ...
                    '1. Continue regular watering schedule.\n' ...
                    '2. Apply balanced fertilizer monthly.\n' ...
                    '3. Monitor regularly for early signs.\n' ...
                    '4. Maintain proper plant spacing.\n' ...
                    '5. Keep growing area clean.']);
            else
                disease    = 'Unknown - Check Manually';
                severity   = 'UNKNOWN';
                suggestion = sprintf(['Suggestions:\n' ...
                    '1. Take a clearer image.\n' ...
                    '2. Consult an agricultural expert.\n' ...
                    '3. Check for pest damage manually.']);
            end

            %% QUALITY METRICS
            original_d = double(img_gray);
            enhanced_d = double(img_enhanced);
            MSE        = mean((original_d(:) - enhanced_d(:)).^2);
            if MSE == 0
                PSNR = Inf;
            else
                PSNR = 10 * log10(255^2 / MSE);
            end

            %% UPDATE APP DISPLAY

            % Show original image
            imshow(img, 'Parent', app.OriginalAxes);
            title(app.OriginalAxes, 'Original Image', 'FontSize', 11);

            % Show segmentation result
            imshow(seg_result, 'Parent', app.ResultAxes);
            title(app.ResultAxes, 'Color Segmentation', 'FontSize', 11);

            % Show disease mask
            imshow(diseased_mask, 'Parent', app.SegmentAxes);
            title(app.SegmentAxes, 'Disease Region', 'FontSize', 11);

            % Update result labels
            app.DiseaseLabel.Text  = sprintf('Disease  :  %s', disease);
            app.SeverityLabel.Text = sprintf('Severity :  %s', severity);
            app.PSNRLabel.Text     = sprintf('PSNR     :  %.2f dB', PSNR);
            app.MSELabel.Text      = sprintf('MSE      :  %.4f', MSE);

            % Color code severity
            if strcmp(severity, 'HIGH')
                app.DiseaseLabel.FontColor  = [1 0 0];
                app.SeverityLabel.FontColor = [1 0 0];
            elseif strcmp(severity, 'MEDIUM')
                app.DiseaseLabel.FontColor  = [1 0.5 0];
                app.SeverityLabel.FontColor = [1 0.5 0];
            else
                app.DiseaseLabel.FontColor  = [0 0.6 0];
                app.SeverityLabel.FontColor = [0 0.6 0];
            end

            % Update suggestion box
            app.SuggestionArea.Value = suggestion;

            % Update status
            app.StatusLabel.Text      = 'Analysis Complete!';
            app.StatusLabel.FontColor = [0 0.6 0];

            % Enable save button
            app.SaveButton.Enable = 'on';
        end

        % Upload Button Pushed
        function UploadButtonPushed(app, ~)
            [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.JPG', ...
                'Image Files'}, 'Select a Leaf Image');

            if isequal(file, 0)
                app.StatusLabel.Text      = 'No image selected!';
                app.StatusLabel.FontColor = [1 0 0];
                return;
            end

            app.img_original = imread(fullfile(path, file));
            app.filename     = file;
            app.filepath     = path;

            % Show image immediately after upload
            imshow(app.img_original, 'Parent', app.OriginalAxes);
            title(app.OriginalAxes, 'Original Image', 'FontSize', 11);

            app.StatusLabel.Text      = sprintf('Image Loaded: %s', file);
            app.StatusLabel.FontColor = [0 0.5 1];

            % Enable analyze button
            app.AnalyzeButton.Enable = 'on';
        end

    function SaveButtonPushed(app, ~)
    results_path = 'C:\Users\SHOP WITH HOPE\Desktop\dip_project\FoliarDisease\results\';
    
    % exportapp works correctly with uifigure
    save_file = fullfile(results_path, 'App_Result.png');
    exportapp(app.UIFigure, save_file);
    
    app.StatusLabel.Text      = 'Result saved to results folder!';
    app.StatusLabel.FontColor = [0 0.6 0];
end

    end

    % App creation
    methods (Access = public)

        function app = FoliarDiseaseApp

            % Create main window
            app.UIFigure                 = uifigure('Visible', 'off');
            app.UIFigure.Position        = [100 50 950 650];
            app.UIFigure.Name            = 'Foliar Disease Detection System - CPE 415';
            app.UIFigure.Color           = [0.95 0.97 0.95];

            % Title
            app.TitleLabel               = uilabel(app.UIFigure);
            app.TitleLabel.Position      = [50 600 860 35];
            app.TitleLabel.Text          = 'FOLIAR DISEASE DETECTION SYSTEM — CPE 415 | Sana Amanat/Areej fatima | FA23-BCE-108/FA23-BCE-019';
            app.TitleLabel.FontSize      = 14;
            app.TitleLabel.FontWeight    = 'bold';
            app.TitleLabel.FontColor     = [0.1 0.4 0.1];
            app.TitleLabel.HorizontalAlignment = 'center';

            % Upload Button
            app.UploadButton             = uibutton(app.UIFigure, 'push');
            app.UploadButton.Position    = [50 550 180 40];
            app.UploadButton.Text        = '📂  Upload Leaf Image';
            app.UploadButton.FontSize    = 13;
            app.UploadButton.FontWeight  = 'bold';
            app.UploadButton.BackgroundColor = [0.2 0.6 0.2];
            app.UploadButton.FontColor   = [1 1 1];
            app.UploadButton.ButtonPushedFcn = @(btn,event) UploadButtonPushed(app,event);

            % Analyze Button
            app.AnalyzeButton            = uibutton(app.UIFigure, 'push');
            app.AnalyzeButton.Position   = [250 550 180 40];
            app.AnalyzeButton.Text       = '🔍  Analyze Disease';
            app.AnalyzeButton.FontSize   = 13;
            app.AnalyzeButton.FontWeight = 'bold';
            app.AnalyzeButton.BackgroundColor = [0.1 0.4 0.8];
            app.AnalyzeButton.FontColor  = [1 1 1];
            app.AnalyzeButton.Enable     = 'off';
            app.AnalyzeButton.ButtonPushedFcn = @(btn,event) AnalyzeButtonPushed(app,event);

            % Save Button
            app.SaveButton               = uibutton(app.UIFigure, 'push');
            app.SaveButton.Position      = [450 550 180 40];
            app.SaveButton.Text          = '💾  Save Result';
            app.SaveButton.FontSize      = 13;
            app.SaveButton.FontWeight    = 'bold';
            app.SaveButton.BackgroundColor = [0.6 0.3 0.8];
            app.SaveButton.FontColor     = [1 1 1];
            app.SaveButton.Enable        = 'off';
            app.SaveButton.ButtonPushedFcn = @(btn,event) SaveButtonPushed(app,event);

            % Status Label
            app.StatusLabel              = uilabel(app.UIFigure);
            app.StatusLabel.Position     = [650 555 280 30];
            app.StatusLabel.Text         = 'Upload an image to begin...';
            app.StatusLabel.FontSize     = 12;
            app.StatusLabel.FontColor    = [0.4 0.4 0.4];
            app.StatusLabel.FontWeight   = 'bold';

            % Original Image Axes
            app.OriginalAxes             = uiaxes(app.UIFigure);
            app.OriginalAxes.Position    = [30 280 280 250];
            title(app.OriginalAxes, 'Original Image', 'FontSize', 11);

            % Segmentation Result Axes
            app.ResultAxes               = uiaxes(app.UIFigure);
            app.ResultAxes.Position      = [330 280 280 250];
            title(app.ResultAxes, 'Color Segmentation', 'FontSize', 11);

            % Disease Mask Axes
            app.SegmentAxes              = uiaxes(app.UIFigure);
            app.SegmentAxes.Position     = [630 280 280 250];
            title(app.SegmentAxes, 'Disease Region', 'FontSize', 11);

            % Results Panel Labels
            app.DiseaseLabel             = uilabel(app.UIFigure);
            app.DiseaseLabel.Position    = [50 240 400 28];
            app.DiseaseLabel.Text        = 'Disease  :  --';
            app.DiseaseLabel.FontSize    = 13;
            app.DiseaseLabel.FontWeight  = 'bold';

            app.SeverityLabel            = uilabel(app.UIFigure);
            app.SeverityLabel.Position   = [50 210 400 28];
            app.SeverityLabel.Text       = 'Severity :  --';
            app.SeverityLabel.FontSize   = 13;
            app.SeverityLabel.FontWeight = 'bold';

            app.PSNRLabel                = uilabel(app.UIFigure);
            app.PSNRLabel.Position       = [50 180 400 25];
            app.PSNRLabel.Text           = 'PSNR     :  --';
            app.PSNRLabel.FontSize       = 12;

            app.MSELabel                 = uilabel(app.UIFigure);
            app.MSELabel.Position        = [50 155 400 25];
            app.MSELabel.Text            = 'MSE      :  --';
            app.MSELabel.FontSize        = 12;

            % Suggestion Text Area
            app.SuggestionArea           = uitextarea(app.UIFigure);
            app.SuggestionArea.Position  = [470 30 450 230];
            app.SuggestionArea.Value     = 'Treatment suggestions will appear here after analysis...';
            app.SuggestionArea.FontSize  = 12;
            app.SuggestionArea.Editable  = 'off';

            % Suggestion Label
            sug_label                    = uilabel(app.UIFigure);
            sug_label.Position           = [470 260 200 25];
            sug_label.Text               = 'Treatment Suggestions:';
            sug_label.FontSize           = 12;
            sug_label.FontWeight         = 'bold';
            sug_label.FontColor          = [0.1 0.4 0.1];

            % Show app
            app.UIFigure.Visible = 'on';
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end