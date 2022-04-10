clear;
clc;

n_particles = 10;
n_steps = 100;

x = zeros(n_particles, 1);
y = zeros(n_particles, 1);


for n=2:n_steps
    dx = randn(n_particles, 1);
    dy = randn(n_particles, 1);
    x = [x x(:, n-1)+dx];
    y = [y y(:, n-1)+dy];
    plot(x', y');
    xlabel("x coordinate");
    ylabel("y coordinate");
    xlim([-50 50]);
    ylim([-50 50]);
    pause(0.001);
end

plot(xcorr(x))
plot(ycorr(x))

sq_xy = x.^2 + y.^2;
means_sq = mean(sq_xy);
plot(means_sq);


