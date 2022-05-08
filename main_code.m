clear, clc;
rosshutdown

setenv('ROS_MASTER_URI','http://10.0.0.101:11311')
setenv('ROS_IP','10.0.0.112')
setenv('ROS_HOSTNAME','10.0.0.112')
rosinit

node_matlab = ros.Node('/node_matlab');
% message type must on the list given by calling rosmsg("list")
sub_trigger = ros.Subscriber(node_matlab,'/naive_registration/trigger_enable_msg','std_msgs/Bool','DataFormat','struct');
pub_pos = ros.Publisher(node_matlab, '/naive_registration/PA_coordinates', 'geometry_msgs/Point','DataFormat','struct');
pause(1)

while isempty(sub_trigger.LatestMessage)
    pause(1)
end

while sub_trigger.LatestMessage.data
    disp('program running!')
    % coarse search
    % image range -30 to 30 degree
    % start from -27 degree, end at 27 degree, interval 6 degree, maximum sample 10 images
    TRUS_pos_init = -27;
    sample_times_max = 10;
    sensitive_range = 6;
    ros_node = node_matlab;
    [iteration_coarse_search, spot_range] = coarse_search(TRUS_pos_init, sample_times_max, sensitive_range, ros_node);

    % rotate to the lower boundary of spot_range
    pub_angle = ros.Publisher(node_matlab, '/theta', 'std_msgs/Float64','DataFormat','struct');
    sub_angle = ros.Subscriber(node_matlab,'/real_angle','std_msgs/Float64','DataFormat','struct');
    msg_rorate_angle = rosmessage(pub_angle);
    msg_rorate_angle.data = spot_range(1);    
    send(pub_angle, msg_rorate_angle);
    while abs(sub_angle.LastestMessage.data - msg_rorate_angle.data) >= 0.1
        pause(1);
    end
    disp('rotated to the initial angle of the fine search!')
    clear('pub_angle', 'sub_angle');

    % fine search
    target_angle = fine_search(spot_range, ros_node);

    % rotate to the target angle
    pub_angle = ros.Publisher(node_matlab, '/theta', 'std_msgs/Float64','DataFormat','struct');
    msg_rorate_angle = rosmessage(pub_angle);
    msg_rorate_angle.data = target_angle;
    send(pub_angle, msg_rorate_angle);
    pause(1);
    while abs(sub_angle.LastestMessage.data - msg_rorate_angle.data) >= 0.1
        pause(1);
    end
    disp('Arrive at the target angle, search completed!');
    
    % calculate PA coordinate 
    % this coordinate is in the gray image, not the original image
    [x, y, ~] = calculate_PA_coordinates(ros_node);
    
    % transform the coordinates from the 2D PA image to the Cartesian frame
    r = 5; % the radius of the TRUS
    [x_M, y_M, z_M] = PAImage2Cartesian(x, y, target_angle, r);
    
    msg_PA_coordinates = rosmessage(pub_pos);
    msg_PA_coordinates.x = x_M;
    msg_PA_coordinates.y = y_M;
    msg_PA_coordinates.z = z_M;
%     msg_PA_coordinates.x = 66.6666;
%     msg_PA_coordinates.y = 99.9999;
%     msg_PA_coordinates.z = 33.3333;
    disp(msg_PA_coordinates);
    send(pub_pos, msg_PA_coordinates);
end
clear('/node_matlab');
rosshutdown