p = [0.0163, 0.0016, 0.0257;
     0.0032, -0.0032, 0.0264;
     -0.0008, 0.0053, 0.025;
     0.0147, 0.0038, 0.0255;
     0.0050, -0.0009, 0.0262;
     -0.0013, -0.0033, 0.0266;
     -0.0023, 0.0076, 0.0249;
     0.0096, 0.0011, 0.026;
     ];

figure;
plot3(p(:,1), p(:,2), p(:,3), 'r*')
grid on