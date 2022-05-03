function [x_M, y_M, z_M] = PAImage2Cartesian(u, v, theta, r)
x_M = u;
y_M = (r + v) * cos(theta);
z_M = (r + v) * sin(theta);
end