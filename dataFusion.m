function [roll_n,pitch_n,yaw_n,angv_roll_n,angv_pitch_n,angv_yaw_n,angv_n,angles_n] = dataFusion(accelD,gyroD,magD,timePoints)
count=1;
while count<=length(timePoints)
%     [orientation, angvelo] = fuse(accelerometerdata, gyrodata, mangdata); 
%     radius = 1;                          %radius is needed to convert angular velocity to linear velocity, need to figure out a real way of determining radius
%     v = radius * angvelo;
   
     %code based on data fusion paper
     
    roll_n(count) = rad2deg(atan2(real(accelD(count,2)),real(accelD(count,3))));
    pitch_n(count) = rad2deg(atan2(-real((accelD(count,1))),real((sqrt(accelD(count,2)^2 + accelD(count,3)^2)))));
    yaw_n(count) = rad2deg(atan2(real(magD(count,2)),real(magD(count,1))));
    
    if count>1
        if roll_n(count-1)>150 && roll_n(count)<-150
            roll_n(count)=roll_n(count)+360;
        end
        if pitch_n(count-1)>150 && pitch_n(count)<-150
            pitch_n(count)=pitch_n(count)+360;
        end
        if yaw_n(count-1)>150 && yaw_n(count)<-150
            yaw_n(count)=yaw_n(count)+360;
        end
    end
    
   % angle = angvelo * a(y, 1)  %a(y, 1) is the time value for a data point
    
    Mx(count) = magD(count,1) * cos(pitch_n(count)) + magD(count,3) * sin(pitch_n(count));
    My(count) = magD(count,1) * sin(roll_n(count)) * sin(pitch_n(count)) + magD(count,2) * cos(roll_n(count))- magD(count,3) * sin(roll_n(count)) * cos(pitch_n(count));
   
    if count==1
        deltatime=timePoints(count);
    else
        deltatime=timePoints(count)-timePoints(count-1);
    end 
    %component angular velocities
    angv_roll_n(count) = deg2rad(roll_n(count))/deltatime;
    angv_pitch_n(count) = deg2rad(pitch_n(count))/deltatime;
    angv_yaw_n(count) = deg2rad(yaw_n(count))/deltatime;
    
    angv_n(count) = sqrt(angv_roll_n(count)^2 +angv_pitch_n(count)^2 +angv_yaw_n(count)^2);
    angles_n(count)=angv_n(count)/deltatime;
    count = count+1;
end
end

