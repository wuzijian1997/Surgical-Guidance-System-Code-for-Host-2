function target_angle = fine_search(spot_range, ros_node, pub, sub)
    pub_angle = pub;
    sub_angle = sub;
    msg_rorate_angle = rosmessage(pub_angle);
    TRUS_pos_init = spot_range(1);
    sample_interval = 1;
    sample_angle = spot_range(1): sample_interval : spot_range(2);
    sample_intensity = [];
    for i = 1 : length(sample_angle)
        % command TURS rotate
        msg_rorate_angle.data = TRUS_pos_init + sample_interval * (i - 1);
        send(pub_angle, msg_rorate_angle);
        disp('msg sent!');
        pause(1)
        while isempty(sub_angle.LatestMessage)
            pause(1)
            disp('waiting for sub_angle')
        end
        while abs(sub_angle.LatestMessage.data - msg_rorate_angle.data) >= 0.1
            pause(1);
            disp('not move to the correct position')
        end
        disp('rotated to goal angle');
        % calculate intensity from beam forming image
        disp('Please refresh data!')
        pause; % wait until press any key
        [~, ~, intensity_value] = calculate_PA_coordinates(ros_node, msg_rorate_angle.data);
        sample_intensity = [sample_intensity, intensity_value];
    end
    
    % Fit using Gaussian
    f = fit(sample_angle', sample_intensity', 'gauss2');
    angle_ = spot_range(1) : 0.01 : spot_range(2);
    intensity_fit = f(angle_);
    [~, idx] = max(intensity_fit);
    target_angle = angle_(idx);
end