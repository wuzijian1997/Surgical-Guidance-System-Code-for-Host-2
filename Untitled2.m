% Convert to struct

addpath(genpath('./yaml-1.5.2'));

angle_list = [1,2,3];
u_list = [1,2,3];
v_list = [1,2,3];
intensity_list = [1,2,3];
q = [4,4,4];
t = [5,5,5];

sample = struct;

for j = 1 : (length(angle_list) + 2)
    if j <= length(angle_list)
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


