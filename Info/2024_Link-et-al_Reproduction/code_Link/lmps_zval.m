clear all


AllData = xlsread('cbt-tax-database-2017xls.xls',2,'A397:R435');
zins = xlsread('final_buba_zins.xlsx',1,'A1:B75');
zins = zins(33:length(zins),:)
r(1) = 0.05
r(2) = 0.07
r(3) = 0.09

df = 1 ./ (1+r)

zins(:,3) = 1 ./ (1+(zins(:,2)/100))

% add sl in 2009 2010
AllData(31,9) = 0.1
AllData(32,9) = 0.1
AllData(31,10) = 4
AllData(32,10) = 4
AllData(31,11) = 3.4
AllData(32,11) = 3.4


for (ir = 1:3)
    for (t = 2:39)
        % machinery
        deprc_s = DBSL_depreciation(AllData(t,8), AllData(t,9), AllData(t,10), AllData(t,11))    
        AllData(t,16+ir) = PDV_depreciation(deprc_s, df(ir))
        % buildings
        deprc_s = DBSL_depreciation(AllData(t,3), AllData(t,4), AllData(t,5), AllData(t,6))
        if t < 12
            deprc_s = [repmat(0.1,1,4), repmat(0.05,1,3), repmat(0.025,1,18)]
        end    
        AllData(t,19+ir) = PDV_depreciation(deprc_s, df(ir))

    end
end

% vary interest rate over time
for (t = 2:39)
    % machines
    deprc_s = DBSL_depreciation(AllData(t,8), AllData(t,9), AllData(t,10), AllData(t,11))    
    AllData(t,23) = PDV_depreciation(deprc_s, zins(t-1,3))
    % buildings
    deprc_s = DBSL_depreciation(AllData(t,3), AllData(t,4), AllData(t,5), AllData(t,6))
    if t < 12
        deprc_s = [repmat(0.1,1,4), repmat(0.05,1,3), repmat(0.025,1,18)]
    end    
    AllData(t,24) = PDV_depreciation(deprc_s, zins(t-1,3))

end


xlswrite('cbt_with_z_with_zins.xlsx',AllData)

