clear;
clc;

% dimensions of the model
A = 0.2; %m
B = 0.1; %m
C = 0.05; %m
D = 0.05; %m
heater_thickness = 0.002; %m

% initialization temperatures
init_temp_heater = 80; %celcius
init_temp_obj = 20; %celcius
init_temp_border = 10; %celcius

material = 1;
% 1 - alumina, 2 - cooper, 3 - stainless steel
density = [2700, 8920, 7860]; %kg/m^3
sp_heat = [900, 380, 450]; %J/kgK
conduct = [237, 401, 58]; %W/mK

% numerical parameters
dt = 0.001; %s
dx = 0.001; %m
dy = 0.001; %m
nax = round(A/dx);
nay = round(A/dy);
nbx = round(B/dx);
nby = round(B/dy);
ncx = round(C/dx);
ncy = round(C/dy);
ndx = round(D/dx);
ndy = round(D/dy);

% thermal equation parameters for specified material
efx = (conduct(material)*dt)/(density(material)*sp_heat(material)*(dx^2));
efy = (conduct(material)*dt)/(density(material)*sp_heat(material)*(dy^2));

% boundary condition
bc = 2;

% heater heat transfer in boundary condition 2
P = 100; %W - power of heater
dT = (P*dt)/(sp_heat(material)*(D^2)*heater_thickness*density(material));

% plane of model declaration
% 0 - nothing, 1 - border, 2 - object, 3 - heater
plane = zeros(nay+2, nax+2);
plane(2:(ndy-1), 2:nax) = 2;
plane(2:(end-1), ncx:(end-ncx-1)) = 2;
plane(2, 2:(end-1)) = 1;
plane(2:ndy, 2) = 1;
plane(2:ndy, (end-1)) = 1;
plane(ndy, 2:ncx) = 1;
plane(ndy, (end-ncx-1):(end-1)) = 1;
plane(ndy:(end-1), ncx) = 1;
plane(ndy:(end-1), (end-ncx-1)) = 1;
plane((end-1), ncx:(end-ncx-1)) = 1;
plane((ndy/2):(ndy*3/2), (ncx+(nbx-ndx)/2):(ncx+(nbx+ndx)/2)) = 3;

% image(plane, 'CDataMapping', 'scaled');
% colorbar;

% plane of temperature declaration
plane_temp = zeros(nax+2, nay+2);
plane_temp(plane == 1) = init_temp_border;
plane_temp(plane == 2) = init_temp_obj;

if bc == 2
    plane_temp(plane == 3) = init_temp_obj;
else
    plane_temp(plane == 3) = init_temp_heater;
end

n_steps = 8000;

f1 = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
% surf(plane_temp, 'EdgeColor', '#8e8e8e', 'FaceColor', 'interp', 'LineWidth', 0.1);
% view(-135, 30);
% xlim([0 nax+2]);
% ylim([0 nay+2]);
% colorbar;
% saveas(f1,'heat_transfer_before.png');

for n=1:n_steps
    disp(n);
    
    surf(plane_temp, 'EdgeColor', '#8e8e8e', 'FaceColor', 'interp', 'LineWidth', 0.1);
    view(-135, 30);
    xlim([0 nax+2]);
    ylim([0 nay+2]);
    colorbar;

    if mod(n, 500) == 0
        name = sprintf('heat_alu_%d_.png', n);
        saveas(f1, name);
    end

    if n == 1500
        plane(plane==3) = 2;
    end

    new_plane = plane_temp;

    for i=1:nax
        for j=1:nay
            % if it is the object near heater
            if (plane(i, j) == 3 && bc == 2)
                new_plane(i,j) = plane_temp(i, j) + dT;
            % if it is the object
            elseif plane(i, j) == 2
                new_plane(i,j) = temp_next(i, j, plane_temp, efx, efy);
            end
        end
    end

    plane_temp = new_plane;
    pause(0.001);
end

surf(plane_temp, 'EdgeColor', '#8e8e8e', 'FaceColor', 'interp', 'LineWidth', 0.1);
view(-135, 30);
xlim([0 nax+2]);
ylim([0 nay+2]);
colorbar;
name = sprintf('heat_alu_%d_.png', n);
saveas(f1, name);

function temp_new = temp_next(i, j, temp, efx, efy)
    temp_l = temp(i, j-1);
    temp_r = temp(i, j+1);
    temp_down = temp(i+1, j);
    temp_up = temp(i-1, j);

    temp_new = temp(i, j) + efx*((temp_down+273.15) - 2*(temp(i, j)+273.15) + (temp_up+273.15)) ...
        + efy*((temp_r+273.15) - 2*(temp(i, j)+273.15) + (temp_l+273.15)); 
end








