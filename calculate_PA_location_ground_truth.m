% clear, clc, close all;
% rosshutdown
% setenv('ROS_MASTER_URI','http://10.0.0.101:11311')
% setenv('ROS_IP','10.0.0.112')
% setenv('ROS_HOSTNAME','10.0.0.112')
% rosinit
%clear; rosshutdown; rosinit; node_matlab = ros.Node('/node_matlab', 'http://10.0.0.101:11311'); pub_angle = ros.Publisher(node_matlab, '/theta', 'std_msgs/Float64','DataFormat','struct', 'IsLatching', false);
% node_matlab = ros.Node('/node_matlab', 'http://10.0.0.101:11311');
% pub_angle = ros.Publisher(node_matlab, '/theta', 'std_msgs/Float64','DataFormat','struct', 'IsLatching', false);
% msg_rorate_angle = rosmessage(pub_angle);
% sub_angle = ros.Subscriber(node_matlab,'/real_angle','std_msgs/Float64','DataFormat','struct');


%% set parameters
function [] = calculate_PA_location_ground_truth(start_pos, end_pos, sample_num)

angle_list = [];
u_list = [];
v_list = [];
intensity_list = [];

for i = start_pos : 1 :end_pos
    msg_rorate_angle.data = i;
    send(pub_angle, msg_rorate_angle);
    pause(1);
%     while isempty(sub_angle.LatestMessage)
%         pause(1);
%         disp('Waiting for real angle from labview!');
%     end
%     while abs(sub_angle.LatestMessage.data - msg_rorate_angle.data) >= 0.1
%         pause(1);
%         disp('sub_angle is not correct!');
%     end
    disp('Please download data using GUI!');
    pause;
%     folder_num = string(i);
%     folder_name = 'G:\offline_data_phantom\9\degree' + folder_num;
%     mkdir(folder_name);
%     copyfile('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\PA_buf1500', folder_name);
    [u, v, intensity] = calculate_PA_coordinates(node_matlab, i);
    u_list = [u_list, u];
    v_list = [v_list, v];
    angle_list = [angle_list, i];
    intensity_list = [intensity_list, intensity];
end

disp('sample done!');

figure;
plot(start_pos : end_pos, intensity_list, 'r*');

prompt = 'Please fill in quaternion: ';
q = input(prompt);
prompt = 'Please fill in translation: ';
t = input(prompt);

% q_list = [q_list, q];
% t_list = [t_list, t];

% Convert to struct

sample = struct;

for j = 1 : (len(angle_list) + 2)
    if j <= len(angle_list)
        sample(j) = {angle_list(j), u_list(j), v_list(j), intensity_list(j)};
    else 
        if j == len(angle_list) + 1
            sample(j) = q;
        else
            sample(j) = t;
        end
    end
end

% Convert to .yaml format

yaml_name = strcat('sample', num2str(sample_num), 'yaml');

yaml.dumpFile(yaml_name, sample)
