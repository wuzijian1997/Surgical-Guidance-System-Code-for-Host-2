clear, clc, close all
In1 = [];
In2 = [];
In3 = [];

for i = -7:3
    if i < 0
        path = strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\source1\scan_-0', num2str(abs(i)),'deg');
    else
        path = strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\source1\scan_0', num2str(i),'deg');
    end
    [x, y, intensity] = calculate_PA_coordinates(path);
    In1 = [In1,intensity];
end
figure(30)
plot(-7:3, In1, '*')
hold on
plot(-7:3, In1)

for i = 12:22
    if i < 0
        path = strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\source2\scan_-', num2str(abs(i)),'deg');
    else
        path = strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\source2\scan_', num2str(i),'deg');
    end
    [x, y, intensity] = calculate_PA_coordinates(path);
    In2 = [In2,intensity];
end
figure(31)
plot(12:22, In2, '*')
hold on
plot(12:22, In2)

for i = 12:22
    if i < 0
        path = strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\source3\scan_-', num2str(abs(i)),'deg');
    else
        path = strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\source3\scan_', num2str(i),'deg');
    end
    [x, y, intensity] = calculate_PA_coordinates(path);
    In3 = [In3,intensity];
end
figure(32)
plot(12:22, In3, '*')
hold on
plot(12:22, In3)
