function angle_target = search_angle()
    %clc, clear, close all;
    aPosRng = theta;
    spot_num = 100;
    PA_Positions = round(1 + (length(intensityProfile) - 1) * rand(1, spot_num));
    TRUSPositionInit = -85.5;
    sampleTimes = 20;
    sum_error = 0;
    for i = 1 : spot_num
        PA_pos = PA_Positions(i);
        [iteration_times, spot_range] = coarseSearch(PA_pos, TRUSPositionInit, sampleTimes, intensityProfile, aPosRng);
        errors = fineSearch(spot_range, PA_pos, aPosRng, intensityProfile);
        sum_error = sum_error + errors;
    end
    aver_error = sum_error / spot_num;
    disp(['average error:', num2str(aver_error)]);
    %dist = getIntensityValueNearPeak(TRUSPosition, PA_Positions, intensityProfile, aPosRng);
    %intensity_value = getIntensityValue(TRUSPositionInit, PA_Positions, intensityProfile, aPosRng);


    %% Coarse-Search
    % Imaging range: -45 to 45 degrees
    % Sensitive range -5 to 5 degrees
    function [iteration_times, spot_range] = coarseSearch(PAPosition, TRUSPositionInit, sampleTimes, intensityProfile, aPosRng)
    % Intensity Threshold
    intensity_threshold = 0.2830;
    for i = 1 : sampleTimes
        TRUSPosition = TRUSPositionInit + 9 * (i - 1);
        intensity_value = getIntensityValue(TRUSPosition, PAPosition, intensityProfile, aPosRng);
        if (intensity_value < intensity_threshold)
            continue;
        else
            spot_range = [TRUSPosition - 4.5, TRUSPosition + 4.5];
            iteration_times = i;
            return;
        end
    end
    % If the intensity is out of the reference range
    iteration_times = 0;
    spot_range = 0;
    disp('Do not find a range where the PA spot locate!');
    return;
    end

    %% Fine-Search
    % spot_range: the output of coarseSearch(), [low_boundary, high_boundary]
    function errors = fineSearch(spot_range, PA_Positions, aPosRng, intensityProfile)
    results = [];
    errors = [];
    % Smaple
    sample_times = 10;
    sample_interval = 9 / sample_times;
    sample_angle = spot_range(1) : sample_interval : spot_range(2);
    sample_intensity = [];
    for j = 1 : length(sample_angle)
        sample_intensity = [sample_intensity, getIntensityValue(sample_angle(j), PA_Positions, intensityProfile, aPosRng)];
    end
    % Fit using Gaussian
    %[fit_Gaussian, ~] = GaussianFit(sample_angle, sample_intensity);
    f = fit(sample_angle', sample_intensity', 'gauss2');
    angle_ = spot_range(1) : 0.01 : spot_range(2);
    %intensity_fit = fit_Gaussian(angle_);
    intensity_fit = f(angle_);
    [~, idx] = max(intensity_fit);
    target_angle = angle_(idx);

    % Evaluation
    errors = [errors, abs(target_angle - aPosRng(PA_Positions))];
    % disp(['real position:', num2str(aPosRng(PA_Positions)),', calc pos:', num2str(target_angle), ', error:'...
    %     , num2str(abs(target_angle - aPosRng(PA_Positions)))]);
    end

    %% Calculate the intensity value 
    % Function getIngtensityValue() can return the PA spot's intensity
    % Used to obtain real intensity value
    function intensity_value = getIntensityValue(TRUSPosition, PAPosition, intensityProfile, aPosRng)
    % Calculate the distance between the TRUS and the PA spot
    dist = abs(TRUSPosition - aPosRng(PAPosition));
    % Generate intensity function of the distance between TRUS and PA spot 
    [~, idx_max] = max(intensityProfile);
    intensity_left = intensityProfile(1:idx_max);
    intensity_right = intensityProfile(end:-1:idx_max);
    dist_angle_left = [];
    dist_angle_right = [];
    for j = 1 : idx_max
        dist_angle_left = [dist_angle_left, abs(aPosRng(idx_max) - aPosRng(j))];
    end
    for j = length(intensityProfile) : -1 : idx_max
        dist_angle_right = [dist_angle_right, abs(aPosRng(idx_max) - aPosRng(j))];
    end
    [getIntensity, ~] = SmoothSplineFit((dist_angle_left + dist_angle_right) / 2, (intensity_left + ... 
    intensity_right) / 2);

    % x = 0 : 0.1 : 90;
    % y = getIntensity(x);
    % figure;
    % plot(x, y, '.')
    % grid on;
    % xlabel('Distance')
    % ylabel('Intensity')
    % %Calculate the intensity value
    intensity_value = getIntensity(dist);
    end

    %% The intensity function of distance between TRUS and PA spot (-9 to 9 degrees)
    % Only use to calculate intensity within -9 to 9 degrees.
    function intensity_value_nearpeak = getIntensityValueNearPeak(TRUSPosition, PAPosition, intensityProfile, aPosRng)
        [~, idx_max] = max(intensityProfile);
        dist_left = [];
        dist_right = [];
        for k = 82 : idx_max
            dist_left = [dist_left, abs(aPosRng(k) - aPosRng(idx_max))];
        end
        for k = 100 : -1 : idx_max  
            dist_right = [dist_right, abs(aPosRng(k) - aPosRng(idx_max))];
        end
        [fit_Fourier, ~] = GaussianFit((dist_right + dist_left) / 2, (intensityProfile(82 : idx_max) + ...
        intensityProfile(100: -1 : idx_max)) / 2);
        % Distance between TRUS and PA spot
        dist = abs(TRUSPosition - aPosRng(PAPosition));
        intensity_value_nearpeak = fit_Fourier(dist);
    end

    %% Smooth Spline Fit
    function [fitresult, gof] = SmoothSplineFit(dist_angle, intensity_temp)
    %CREATEFIT(DIST_ANGLE,INTENSITY_TEMP)
    %  Create a fit.
    %
    %  Data for 'SmoothSplineFit' fit:
    %      X Input : dist_angle
    %      Y Output: intensity_temp
    %  Output:
    %      fitresult : a fit object representing the fit.
    %      gof : structure with goodness-of fit info.

    [xData, yData] = prepareCurveData( dist_angle, intensity_temp );

    % Set up fittype and options.
    ft = fittype( 'smoothingspline' );

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft );

    %Plot fit with data.
    % figure( 'Name', 'SmoothSplineFit' );
    % h = plot( fitresult, xData, yData );
    % legend( h, 'intensity_temp vs. dist_angle', 'SmoothSplineFit', 'Location', 'NorthEast', 'Interpreter', 'none' );
    % % Label axes
    % xlabel( 'dist_angle', 'Interpreter', 'none' );
    % ylabel( 'intensity_temp', 'Interpreter', 'none' );
    % grid on
    end

    %% Gaussian Fit
    function [fitresult, gof] = GaussianFit(theta, intensity)
    %% Fit: 'Gaussian Fit'.
    [xData, yData] = prepareCurveData( theta, intensity );

    % Set up fittype and options.
    ft = fittype( 'gauss2' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [-Inf -Inf 0 -Inf -Inf 0];
    opts.StartPoint = [1 0 0.799669234748487 0.624802945047486 1 2.15444304382469];

    % Fit model to data.
    [fitresult, gof] = fit( xData, yData, ft, opts );

    % Plot fit with data.
    figure( 'Name', 'Gaussian Fit' );
    h = plot( fitresult, xData, yData );
    legend( h, 'intensity vs. theta', 'Gaussian Fit', 'Location', 'NorthEast', 'Interpreter', 'none' );
    % Label axes
    xlabel( 'theta', 'Interpreter', 'none' );
    ylabel( 'intensity', 'Interpreter', 'none' );
    grid on
    end
end