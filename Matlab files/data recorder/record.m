maxSamples = 1000;

fprintf(1, 'Preparing Figures\n');

Gyro = zeros(maxSamples, 3);
Accel = zeros(maxSamples, 3);
Mag = zeros(maxSamples, 3);

scrsz = get(0,'ScreenSize');
figure('Position',[scrsz(3)/4 scrsz(4)/8 scrsz(3)/2 scrsz(4)*6/8])

subplot(3,1,1);
axis([0 maxSamples -2^15 2^15]);
title('Gyro');
hold on;
subplot(3,1,2);
axis([0 maxSamples -2^15 2^15]);
title('Accelerometer');
hold on;
subplot(3,1,3);
axis([0 maxSamples -2^10 2^10]);
title('Magnetometer');
hold on;

sampleLast = 1;

fprintf(1, 'Ready, press any key to go\n');
pause;

s = serial('COM62');
fopen(s);

fprintf(1, 'Collecting data...\n');
samples = 1;
tic
while samples <= maxSamples
    if s.BytesAvailable >= 10
        % check sync bytes
        bytes = fread(s, 2, 'uint8');
        if bytes(1) == 11
            % read data
            Gyro(samples,:) = double(fread(s, 3, 'int16'));
            Accel(samples,:) = double(fread(s, 3, 'int16'));
            Mag(samples,:) = double(fread(s, 3, 'int16'));
            
            % only update plot if we have some time
            if s.BytesAvailable <=20
                subplot(3,1,1);
                plot([sampleLast samples], [Gyro(sampleLast,:)' Gyro(samples,:)']);

                subplot(3,1,2);
                plot([sampleLast samples], [Accel(sampleLast,:)' Accel(samples,:)']);

                subplot(3,1,3);
                plot([sampleLast samples], [Mag(sampleLast,:)' Mag(samples,:)']);


                drawnow;
                sampleLast = samples;
            end
            
            samples = samples + 1;
        end
    end
end
rate = maxSamples/toc;
fclose(s);
delete(s);
clear s;

fprintf(1, 'Finished collecting data, average rate: %fHz\n', rate);
fprintf(1, 'redrawing graphs.\n');
subplot(3,1,1);
    cla;
    plot(Gyro);
    axis([0 maxSamples -2^15 2^15]);
    title('Gyro');
    hold off;
subplot(3,1,2);
    cla;
    plot(Accel);
    axis([0 maxSamples -2^15 2^15]);
    title('Accelerometer');
    hold off;
subplot(3,1,3);
    cla;
    plot(Mag);
    axis([0 maxSamples -2^10 2^10]);
    title('Magnetometer');
    hold off;
fprintf(1, 'Done.\n');

clear bytes maxSamples sampleLast samples scrsz rate;
save('lastrecord.mat', 'Accel', 'Gyro', 'Mag');

noiseStats();
