clc
clear
warning('off','all')

[FileName, PathName] = uigetfile('*.xlsx');
FullPath = strcat(PathName,FileName);
data = xlsread(FullPath);
data(:,1)=[];
data(1,:)=[];

time=data(:,1)/1000;
accel=data(:,2:4);
gyro=data(:,5:7);
mag=data(:,8:10);
accelsqrt=data(:,11);
horizdir=data(:,12);

[roll,pitch,yaw,angv_roll,angv_pitch,angv_yaw,angv,angles]=dataFusion(accel,gyro,mag,time);

%% LOWPASS FILTER
time_length = time(end);
samp_freq = length(time)/time(end);
cutoff_freq = 30;
nyq_freq = floor(samp_freq/2);
if cutoff_freq > nyq_freq
    cutoff_freq = nyq_freq;
end
freq = samp_freq*(0:(time_length/2))/2;

for i=1:3
    accel_fourier = fft(accel(:,i));
    gyro_fourier = fft(gyro(:,i));
    mag_fourier = fft(mag(:,i));
    %P_accel = abs(accel_fourier/time_length); P_accel_new = P_accel(1:time_length/2+1);
    %P_accel_new(2:end-1) = 2*P_accel_new(2:end-1);
    accel_fourier = lowpass(accel_fourier,cutoff_freq,samp_freq);
    accel_filt(:,i) = ifft(accel_fourier);
    gyro_fourier = lowpass(gyro_fourier,cutoff_freq,samp_freq);
    gyro_filt(:,i) = ifft(gyro_fourier);
    mag_fourier = lowpass(mag_fourier,cutoff_freq,samp_freq);
    mag_filt(:,i) = ifft(mag_fourier);
end

[roll_filt,pitch_filt,yaw_filt,angv_roll_filt,angv_pitch_filt,angv_yaw_filt,angv_filt,angles_filt]=dataFusion(accel_filt,gyro_filt,mag_filt,time);

%% SAVITZKY-GOLAY FILTER
poly_order = 2;  
% frame lengths must be odd
frame_len_accel = 31;
frame_len_gyro = 39;
frame_len_mag = 31;
for i=1:3
    accel_sg(:,i) = sgolayfilt(accel(:,i),poly_order,frame_len_accel);
    gyro_sg(:,i) = sgolayfilt(gyro(:,i),poly_order,frame_len_gyro);
    mag_sg(:,i) = sgolayfilt(mag(:,i),poly_order,frame_len_mag);
    
    % both lowpass and SG filters
    accel_lfsg(:,i) = sgolayfilt(accel_filt(:,i),poly_order,frame_len_accel);
    gyro_lfsg(:,i) = sgolayfilt(gyro_filt(:,i),poly_order,frame_len_gyro);
    mag_lfsg(:,i) = sgolayfilt(mag_filt(:,i),poly_order,frame_len_mag);
end

[roll_sg,pitch_sg,yaw_sg,angv_roll_sg,angv_pitch_sg,angv_yaw_sg,angv_sg,angles_sg]=dataFusion(accel_sg,gyro_sg,mag_sg,time);
[roll_lfsg,pitch_lfsg,yaw_lfsg,angv_roll_lfsg,angv_pitch_lfsg,angv_yaw_lfsg,angv_lfsg,angles_lfsg]=dataFusion(accel_lfsg,gyro_lfsg,mag_lfsg,time);

figure(1);
subplot(2,2,1);plot(time,roll,time,pitch,time,yaw);title('R/P/Y from Raw Data');
subplot(2,2,2);plot(time,roll_filt,time,pitch_filt,time,yaw_filt);title('R/P/Y from LPF');
subplot(2,2,3);plot(time,roll_sg,time,pitch_sg,time,yaw_sg);title('R/P/Y from SGF');
subplot(2,2,4);plot(time,roll_lfsg,time,pitch_lfsg,time,yaw_lfsg);title('R/P/Y from LPF+SGF');

%compareFilters(accel,accel_filt,accel_sg,accel_lfsg,time,'Accel',2);
compareFilters(gyro,gyro_filt,gyro_sg,gyro_lfsg,time,'Gyro',3);
%compareFilters(mag,mag_filt,mag_sg,mag_lfsg,time,'Mag',4);


%% ANALYSIS

[turn1,turn2,fulltime,standtime] = analyzeData(accel,gyro,mag,roll,pitch,yaw,horizdir,time);
%analyzeData(accel_filt,gyro_filt,mag_filt,roll_filt,pitch_filt,yaw_filt,horizdir,time);
%analyzeData(accel_sg,gyro_sg,mag_sg,roll_sg,pitch_sg,yaw_sg,horizdir,time);
%[turn1_lfsg,turn2_lfsg,fulltime_lfsg] = analyzeData(accel_lfsg,gyro_lfsg,mag_lfsg,roll_lfsg,pitch_lfsg,yaw_lfsg,horizdir,time);

%
time(time>fulltime)=[];newtime=[];newaccel=[];
for n=1:length(time)
    if time(n)>=standtime
        newtime=[newtime time(n)];
        newaccel=[newaccel; accel(n,:)];
    end
end
accel=newaccel;time=newtime;
%

%% STEP COUNT
for i=1:length(time)
    accel_sqs(i) = real(sqrt(accel(i,1)^2+accel(i,2)^2+accel(i,3)^2));
end
time_separ = 0.25; ampl_min = mean(accel_sqs)*1.15;
[accel_peaks,accel_ind] = findpeaks(accel_sqs,time,'MinPeakDistance',time_separ,'MinPeakHeight',ampl_min);
figure(10);plot(time,accel_sqs);hold on;plot(accel_ind,accel_peaks,'o');hold off;

count_forw = 0;count_back = 0;
steps_forw = [];steps_back = [];
for i=1:length(accel_ind)
    if accel_ind(i) < turn1
        count_forw = count_forw + 1;
        steps_forw = [steps_forw; [accel_ind(i) accel_peaks(i)]];
    else
        count_back = count_back + 1;
        steps_back = [steps_back; [accel_ind(i) accel_peaks(i)]];
    end
end
disp([num2str(count_forw),' steps were taken forwards, and ',num2str(count_back),' steps were taken back.']);

%% CONSISTENT TIME BETWEEN STEPS
mean_step_time_forw = (steps_forw(end,1)-steps_forw(1,1))/(count_forw-1);
mean_step_time_back = (steps_back(end,1)-steps_back(1,1))/(count_back-1);

dev = 0.2; inconsis_steps=[];
for i=2:count_forw
    diff_step_time = steps_forw(i,1)-steps_forw(i-1,1);
    if ((diff_step_time > (1-dev)*mean_step_time_forw) && (diff_step_time < (1+dev)*mean_step_time_forw))
        continue
    else
        inconsis_steps=[inconsis_steps steps_forw(i,1)];
        disp(['Inconsistent step at ',num2str(steps_forw(i,1)),' seconds']);
    end
end
for i=2:count_back
    diff_step_time = steps_back(i,1)-steps_back(i-1,1);
    if ((diff_step_time > (1-dev)*mean_step_time_back) && (diff_step_time < (1+dev)*mean_step_time_back))
        continue
    else
        inconsis_steps = [inconsis_steps steps_back(i,1)];
        disp(['Inconsistent step at ',num2str(steps_back(i,1)),' seconds']);
    end
end
for i=1:length(time)
    gyro_sqs(i)=sqrt(gyro(i,1)^2+gyro(i,3)^2); %ignore y-rotation
end
consis_percent = (count_forw+count_back)-length(inconsis_steps);
consis_percent = consis_percent/(count_forw+count_back);
disp(['Subject displays ', num2str(consis_percent*100), '% consistency in gait.']);
%{
inconsis_gyro_sqs = [];
for i = 1:length(inconsis_steps)
    for j = 1:length(time)
        if inconsis_steps(i) == time(j)
            inconsis_gyro_sqs = [inconsis_gyro_sqs gyro_sqs(j)];
            break
        end
    end
end
figure(11);plot(time,gyro_sqs,inconsis_steps,inconsis_gyro_sqs,'o');
%}