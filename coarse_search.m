function [iteration_times, spot_range] = coarse_search(TRUS_pos_init, sample_times, sensitive_range, ros_node, pub, sub)
    pub_angle = pub;
    sub_angle = sub;
    msg_rorate_angle = rosmessage(pub_angle);
    for i = 1 : sample_times
        % command TURS rotate
        msg_rorate_angle.data = TRUS_pos_init + sensitive_range * (i - 1);
        % msg_rorate_angle.data = 150.0;
        send(pub_angle, msg_rorate_angle);
        disp('msg sent!');
        pause(1)
        while isempty(sub_angle.LatestMessage)
            disp(sub_angle.LatestMessage);
            disp('waiting for sub_angle');
        end
        % 
        while abs(sub_angle.LatestMessage.data - msg_rorate_angle.data) >= 0.1
            pause(1);
            disp('not move to the correct position');
        end
        disp('rotated to goal angle');
        % calculate intensity from beam forming image
        TRUSPosition = TRUS_pos_init + sensitive_range * (i - 1);
        disp('Please refresh data using GUI!')
        pause; % wait until press any key
        [~, ~, intensity_value] = calculate_PA_coordinates(ros_node, msg_rorate_angle.data);
        if (intensity_value == 0)
            continue;
        else
            % extend the range a bit to guarantee success
            spot_range = [TRUSPosition - (0.5 * sensitive_range + 3), TRUSPosition + (0.5 * sensitive_range + 3)];
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