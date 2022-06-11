function [] = compareFilters(raw,lpf,sgf,lpf_sgf,timePoints,text,fig_no)

figure(fig_no);

subplot(2,2,1);
plot(timePoints,raw(:,1),timePoints,raw(:,2),timePoints,raw(:,3));
title(['Raw ',text]);legend('X','Y','Z');

subplot(2,2,2);
plot(timePoints,lpf(:,1),timePoints,lpf(:,2),timePoints,lpf(:,3));
title(['LPF ',text]);legend('X','Y','Z');

subplot(2,2,3);plot(timePoints,sgf(:,1),timePoints,sgf(:,2),timePoints,sgf(:,3));
title(['SGF ',text]);legend('X','Y','Z');

subplot(2,2,4);plot(timePoints,lpf_sgf(:,1),timePoints,lpf_sgf(:,2),timePoints,lpf_sgf(:,3));
title(['LPF+SGF ',text]);legend('X','Y','Z');
end

