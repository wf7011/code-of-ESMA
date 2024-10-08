% This program simulates the propagation of viscoacoustic waves in a 2D gas chimney model using the ESMA algorithm.
% Author: [Feng Wang]
%Require: data for wave velocity and the Q model to the 2D gas chimney model.
% Date: April 18, 2024

clear
close all

Q = load ('gas_chimney_Q.txt'); 
v = load ('gas_chimney_vel.txt'); 
v = v(41:end,:);
Q = Q(41:end,:);

[Nz,Nx]  = size(v);

[idx_Q, ia, ib] = unique(Q);

cgamma = zeros(length(idx_Q),1);

for ii = 1:length(idx_Q)

cgamma(ii,:) = (1/pi)*atan(1/idx_Q(ii)); %fractional order

end

%---------Riker wavelet------------
fp     = 15;
fp_ref = 100;
dt     = 1e-3;
T      = 0.5;
Nstep  = T/dt;

s  = wavelet(fp,dt,T );

W0 = 2*pi*fp_ref;

C  = zeros(Nz,Nx);

for ii = 1:length(idx_Q)

IDX = find(Q == idx_Q(ii) );

C(IDX) = v(IDX).^2.*(cos(pi*cgamma(ii)./2)).^2*W0.^(-2*cgamma(ii));

clear IDX

end

C_gamma = zeros(Nz,Nx);

for ii = 1:length(idx_Q)

IDX = find(Q == idx_Q(ii) );

C_gamma(IDX) = C(IDX).*2.*sin(2*pi*cgamma(ii))/pi;

clear IDX

end

% --- Generate Gaussian nodes and weights ---------

My       = 8;% Memory length

beta     = 0.05346*T + 0.209;%Scale factor
node     = zeros(My,length(idx_Q));
omega    = node;


 for ii = 1:length(idx_Q)

[nodes, omegas] = Laguerre_Gauss_FSU(My, 4*cgamma(ii)-1, beta);
delete('temp*')
node(:,ii) = nodes;
omega(:,ii) = omegas;

clear nodes omegas

 end


Y        = zeros(My,Nz,Nx);
WT       = zeros(My,Nz,Nx);

%--------------matrix----------

for kk = 1: My

 for ii = 1:length(idx_Q)

IDX = find(Q == idx_Q(ii) );

Y (kk,IDX) = node(kk,ii);
WT(kk,IDX) = omega(kk,ii);


clear IDX

 end


end


v1    =  zeros( Nz,Nx );
v3    =  zeros( Nz,Nx ); 
phi   =  zeros( My,Nz,Nx);
sigma =  zeros( Nz,Nx);
rou   = ones(Nz,Nx);

%------------meshing---------

dx      = 12.5;
dz      = 12.5;
LX      = dx*(Nz-1);
LZ      = dz*(Nx-1);
 
%-------------- PML--------------
 N_PML = 20;

[aaz,bbz,aax,bbx] = cpml(1e-2,[Nz Nx],N_PML,max(v(:)),dt,dx);
sigma_z = -log(bbz)/dt;
sigma_x = -log(bbx)/dt;


sigma_z(1:20,:) = 0;

%-----------Set receiver position-----------------

sx  = (Nx-1)/2*dx;
sz  = 0;
gx  = (0:2:(Nx-1))*dx;

HZ  = dx*20;

gz  = HZ*ones(size(gx));
ng  = numel(gx);
g   = 1:ng;


seis = zeros(Nstep ,numel(gx));%Synthetic seismic data

nbc = 0;

[isx,isz,igx,igz] = adjust_sr(sx,sz,gx,gz,dx,nbc);

igz = ones(1,length(igx));

%--------------Finite difference-----------
nn   = 6;
dxd  =  FDcoeffDx(nn);
ddz0 =  dxd';
ddz1 =  [dxd 0]';
ddx0 =  ddz0';
ddx1 =  ddz1';

pic_num = 1;   

tic

for k = 1:Nstep 

%------------------------Stress excitation source loading------------------------ 

F1 = 0;
F2 = 0;

%----------------velocity--------------

  dsigmax = imfilter(sigma,ddx0)./dx;
  dsigmaz = imfilter(sigma,ddz0)./dx;


    v1 = update_velocity_PML(v1, dsigmax, dt,rou,sigma_x);
    v3 = update_velocity_PML(v3, dsigmaz, dt,rou,sigma_z);

 %----------------stress--------------


 dv1 = imfilter(v1,ddx1)./dx;
 dv3 =  imfilter(v3,ddz1)./dx;


[sigma, phi] = update_stress_response_2D_Marmus( phi, Y,WT, dv1,dv3,Nx,Nz, dt, C_gamma,rou,F1,F2,sigma_x,sigma_z);

 sigma(2,Nx/2)  =  sigma(2,Nx/2) + s(k);


sigma_TT = sigma(1:end,:);


for ig = 1:ng

seis(k,ig)= sigma_TT(igz(ig),igx(ig));

end



end

toc

figure(100)
pcolor(flipud(sigma_TT))
shading interp;
colormap("bone")
colorbar;
axis equal
axis tight
    
 








                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                