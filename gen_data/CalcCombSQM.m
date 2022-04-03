function [Com_sqm_ma,Com_sqm_mv]=CalcCombSQM(I_E,I_P,I_L,Q_E,Q_P,Q_L,I_E_E,Q_E_E)
%% A New Signal Quality Monitoring Method for Anti-spoofing
%% GNSS Spoofing Detection by Means of Signal Quality Monitoring (SQM) Metric Combinations
ld = length(I_E);
delta = zeros(1,ld);
ratio = zeros(1,ld);
elp   = zeros(1,ld);
md    = zeros(1,ld);

for ind = 1:ld
    
    delta(ind) = (I_E(ind)-I_L(ind))/(2*I_P(ind));
    ratio(ind) = (I_E(ind)+I_L(ind))/(2*I_P(ind));
    elp(ind) = atan(Q_E(ind)/I_E(ind))-atan(Q_L(ind)/I_L(ind));
    md(ind) = (sqrt(I_E(ind) * I_E(ind) + Q_E(ind) * Q_E(ind)) - sqrt(I_L(ind) * I_L(ind) + Q_L(ind) * Q_L(ind)))/...
                    (2*sqrt(I_P(ind)* I_P(ind) + Q_P(ind) * Q_P(ind)));
end
            
Com_sqm = delta*0.5 + elp*0.5;
Com_sqm_ma = mean(Com_sqm);
Com_sqm_mv = std(Com_sqm);
            
            
% SQM_Ratio = (sqrt(I_E * I_E + Q_E * Q_E) + sqrt(I_L * I_L + Q_L * Q_L))/...
%                 (1*sqrt(I_P * I_P + Q_P * Q_P));
%             SQM_EP   = sqrt(I_E * I_E + Q_E * Q_E) - sqrt(I_P * I_P + Q_P * Q_P)/2;
%             SQM_LP   = sqrt(I_L * I_L + Q_L * Q_L) - sqrt(I_P * I_P + Q_P * Q_P)/2;