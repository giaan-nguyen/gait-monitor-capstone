function [first_turn,final_turn_to_sit,stop_time,stand] = analyzeData(accel,gyro,mag,roll,pitch,yaw,horizdir,time)
% SITTING/STANDING
count = length(time);
accelxav = sum(accel(:,1))/count;
accelyav = sum(accel(:,2))/count;
accelzav = sum(accel(:,3))/count;
accelmag = sqrt(accelxav^2+accelyav^2+accelzav^2);

gyroxav = sum(gyro(:,1))/count;
gyroyav = sum(gyro(:,2))/count;
gyrozav = sum(gyro(:,3))/count;
gyromag = sqrt(gyroxav^2+gyroyav^2+gyrozav^2);

magxav = sum(mag(:,1))/count;
magyav = sum(mag(:,2))/count;
magzav = sum(mag(:,3))/count;
magmag = sqrt(magxav^2+magyav^2+magzav^2);

status1 = zeros(1,count);
for t = 1:count
    if sqrt(gyro(t,1)^2+gyro(t,2)^2+gyro(t,3)^2) < 15
        status(1,t) = "sitting";
    else
        status(1,t) = "standing";
        stand = ['Timestamp of standing is ', num2str(time(t)), ' seconds'];
        disp(stand)
        stand = time(t)
        break
    end
end

% WALKING FORWARD/BACK, TURNING AROUND
horizmean = sum(horizdir)/count;
for t1 = t:count
    if horizdir(t1) > horizmean
        status(1,t1) = "walking forward";
    else
        status(1,t1) = "turned around";
        turn = ['Timestamp of turning around is ', num2str(time(t1)), ' seconds'];
        disp(turn)
        break
    end
end
first_turn = time(t1);

for t2 = t1:count
    if horizdir(t2) < horizmean
        status(1, t2) = "walking back";
    else
        status(1, t2) = "turning to sit";
        turntosit = ['Timestamp of turning to sit is ', num2str(time(t2)), ' seconds'];
        disp(turntosit)
        break
    end
end
final_turn_to_sit = time(t2);

 for t3 = t2:count-1 
     p1 = [roll(t3+1) pitch(t3+1) yaw(t3+1)];
     p = [roll(t3) pitch(t3) yaw(t3)];
     diff = abs(sum(p) - sum(p1));
     if diff > .01
        status(1, t3) = 'sitting down';
     else
         status(1, t3) = 'END';
         endtime = ['Timestamp of the end of the test is ', num2str(time(t3)), ' seconds'];
         disp(endtime)
         break
     end
 end
stop_time = time(t3);

v1 = 3/(time(t1)-time(t));
v2 = 3/(time(t2)-time(t1));

vel1 = ['The velocity walking the first three meters was ', num2str(v1), ' meters per second.'];
disp(vel1)
vel2 = ['The velocity walking the second three meters was ', num2str(v2), ' meters per second.'];
disp(vel2)
tot = ['The overall test duration was ', num2str(time(t3)), ' seconds.'];
disp(tot);

end

