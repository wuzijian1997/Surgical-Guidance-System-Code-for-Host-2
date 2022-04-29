function [iteration_times, spot_range] = coarse_search(TRUS_pos_init, sample_times, sensitive_range, ros_node)
    pub_angle = ros.Publisher(ros_node, '/theta', 'std_msgs/Float64','DataFormat','struct');
    sub_angle = ros.Subscriber(ros_node,'/real_angle','std_msgs/Float64','DataFormat','struct');
    msg_rorate_angle = rosmessage(pub_angle);
    for i = 1 : sample_times
        % command TURS rotate
        msg_rorate_angle.Data = TRUS_pos_init + sensitive_range * (i - 1);
        % msg_rorate_angle.data = 150.0;
        send(pub_angle, msg_rorate_angle);
        disp('msg sent!');
        pause(1)
        while isempty(sub_angle.LatestMessage)
            pause(1)
            disp('waiting for sub_angle')
        end
        while abs(sub_angle.LastestMessage.data - msg_rorate_angle.data) >= 0.1
            pause(1);
        end
        disp('rotated to goal angle');
        % calculate intensity from beam forming image
        TRUSPosition = TRUS_pos_init + sensitive_range * (i - 1);
        [~, ~, intensity_value] = calculate_PA_coordinates();
        if (intensity_value == 0)
            continue;
        else
            % extend the range a bit to guarantee success
            spot_range = [TRUSPosition - (0.5 * sensitive_range + 1.5), TRUSPosition + (0.5 * sensitive_range + 1.5)];
            iteration_times = i;
            clear('pub_angle');
            return;
        end
    end
    
    % If the intensity is out of the reference range
    iteration_times = 0;
    spot_range = 0;
    disp('Do not find a range where the PA spot locate!');
    clear('pub_angle');
    return;
end