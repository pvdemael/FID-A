%Simulating the trjaectory of the basic cartesian MRSI trajectory

function [traj, scanTime] = cartMRSI(par)
%%
    if(nargin < 1)
        par.dwellTime = 125/100000; %us ->s
        par.Fov = 0.18; %FoV in m
        par.imageSize = [128, 128]; %voxels in the x and y direction
        par.readOutTime = 50/1000; %ms -> s 
        par.repetitionTime = 1; %s
    end
    %calculating the same image parameters as the default parameters in Rosette.m 
%%
    %updating local variables from parameters
    Fov = par.Fov;
    deltaFov = Fov/par.imageSize(1);
    deltaK = 1/Fov;
    FovK = 1/deltaFov;
    readoutTime = par.readOutTime;
    dwellTime = par.dwellTime;
    
    %calculating trajectory for each shot
    kSpaceX = -FovK/2 + deltaK/2:deltaK:FovK/2 - deltaK/2;
    kSpaceY = -FovK/2 + deltaK/2:deltaK:FovK/2 - deltaK/2;
    [meshx, meshy] = meshgrid(kSpaceX, kSpaceY);
    meshy = meshy .* 1i;
    traj = meshx + meshy;
    traj = repmat(traj, [1,1,readoutTime/dwellTime]);
    
    
    
    
    
    
    scanTime = (par.repetitionTime) * par.imageSize(1) * par.imageSize(2);
end
    