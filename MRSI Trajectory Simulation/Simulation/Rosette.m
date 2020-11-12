% Rosette.m
% Jamie Near, McGill University 2019.
% 
% USAGE:
% Rosette(par)
% 
% DESCRIPTION:
% This function takes in a parameter sturucture (par) and outputs the
% corresponding rosette trajectory form the parameters. The formulas to
% create the rosette trajectory comes from Schirda et al. 2019.
%
% INPUTS:
% par = parameter structure
% par.omega1 = angular turning rate of trajectory
% par.omega2 = osilitory rate of trajectroy. (how fast the trajectory
% completes one cicle in the rosette)
% par.kMax = maxium k space coordinates
% par.dwellTime = dwell time of scan
% par.readOutTime = read out time
% par.cycleTime = one spectral dwell time. (ie. the time to complete one
% cycle)
% par.slewRate = gradient slew rate
% par.nAngInts = number of angular interleaves
% par.repetitionTime = TR, time between scans.
%
% OUTPUTS:
% inputTraj   = the original k space trajectory
% gradentTraj     = the gradient trajectory
% finalKSpaceTraj = the trajectory after acounting for scanner slew rates
% gMax = the max gradient needed for the trajectory
% maxSlewRate = the max slew rate needed for the trajectory (excluding the
% inital ramping).

function [inputTraj, gradientTraj, finalKSpaceTraj, gMax, scanTime, maxSlewRate, rampingPoints] = Rosette(par)
%%
    %some example numbers taken from Schirda et al. 2019
    if(nargin < 1)
        par.omega1 = 400 * 2 * pi; %rad / s
        par.omega2 = 400 * 2 * pi; %rad/ s
        par.kMax = 3.56*100; %cm^-1 -> m^-1
        par.dwellTime = 5/100000; %us ->s
        par.readOutTime = 50/1000; %ms -> s 
        par.cycleTime = pi/(par.omega1); %one spectral dwell time, ie. length of one spectral point
        par.slewRate = 200/1000; %mt/m/ms -> T/m/ms
        par.nAngInts = 128; %number of turns
        par.repetitionTime = 1; %seconds
    end
    %128 by 128
    %fov = 18cm
    %spectralBandwidth = 800Hz
    %spectralPoints = 40
    %voxel size = 1.4mm
    
 %%   
    omega1 = par.omega1;
    omega2 = par.omega2;
    kMax = par.kMax;
    gyromagneticRatio = 2.675222005e8;    
    gMax = kMax * max(omega1, omega2) / gyromagneticRatio; %T/m
    slewRate = par.slewRate;
    scanTime = (par.readOutTime) * par.nAngInts;
    maxSlewRate = kMax * (omega1^2 + omega2^2) / (gyromagneticRatio * 1000); %T/m/ms
    
    t = 0:par.dwellTime:par.readOutTime;
    inputTraj(:,1) = kMax*sin(omega1*t).*exp(1i*omega2*t);

    %creating rosette trajectory in k space
    for rotation = 1:par.nAngInts
        rotationAngle = ((rotation - 1)/par.nAngInts)*2*pi;
        rotationConverter = exp(1i*rotationAngle); 
        inputTraj(:,rotation) = rotationConverter*inputTraj(:,1);
    end

    %calculating the gradient trajectory
    gradientTraj = ones(size(inputTraj,1), par.nAngInts);
    for i = 1:par.nAngInts
        gradientTraj(1:end-1,i) = diff(inputTraj(:,i))/(par.dwellTime * gyromagneticRatio);
        gradientTraj(end,i) = gradientTraj(end-1,i);
    end
    %adding ramping function to the data
    
    rampFinal = gMax / slewRate;  
    rampFinal = rampFinal / 1000; % changing to seconds
    rampTime = 0:par.dwellTime:rampFinal; %time interval for the ramp
    rampFunction = (1/rampFinal) * rampTime;  %factor to apply to 
    for i = 1:par.nAngInts
      gradientTraj(1:numel(rampFunction), i) = gradientTraj(1:numel(rampFunction), i).*rampFunction';
    end

    
    finalKSpaceTraj = ones(size(gradientTraj));
    for i = 1:par.nAngInts
        finalKSpaceTraj(:,i) = cumtrapz(t,gradientTraj(:,i))*gyromagneticRatio;
    end
    finalKSpaceTraj = [imag(finalKSpaceTraj), real(finalKSpaceTraj)];
    
    rampingPoints = size(rampTime,1);
    
    
    
end