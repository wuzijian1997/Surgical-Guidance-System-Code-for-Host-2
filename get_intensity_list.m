function intensity_list = get_intensity_list()
root_dir = 'G:\offline_data_chicken_breast\';
number = '3\degree';

intensity_list = [];

for i = -35 : 35
    dir_ = strcat(root_dir, number, num2str(i));
    [~, ~, intensity] = get_intensity(dir_);
    intensity_list = [intensity_list, intensity];
    disp(i)
end

x = -35:35;
y = intensity_list;
plot(x, y, '*')
