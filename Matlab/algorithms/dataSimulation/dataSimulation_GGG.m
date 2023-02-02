function [dataSimulation] = dataSimulation_GGG(n,ds,SNRgc,SNRlc,SNRd,noises,ntimes_noise,sparse_ratio,seed)
% The simulation of Gaussian-Gaussian-Gaussian (G-G-G) data sets 
% according to the ESCA model. 
%
% Input:
%      n: samples;
%      ds: number of variables of each data set;
%      SNRgc: SNR of the global common structure;
%      SNRlc: SNRs of the local common structures;
%      SNRd: SNRs of the distinct structures;
%      noises: noise levels;
%      ntimes_noise: require signal strength is ntimes larger than the noise;
%      sparse_ratio: sparse ratio of the simulated loading matrix
%      seed: if seed exists, set seed to reproduce the simulation
%
% Output:
%       dataSimulation.
%                      X1: simulated binary data X1
%                      X2: simulated quantitative data X2
%                      Theta_simu: simulated Theta
%                      mu_simu: simulated mu
%                      Z_simu: simulated Z 
%                      E_simu: simulated noise term E

% reproduce the demo or not
if(nargin==9), rng(seed); end % set seed to reproduce the results

% parameters used in the simulation
Rgc  = 3;         % number of PCs for the global common structure
Rlc  = [3, 3, 3]; % number of PCs for the local common structures
Rd   = [3, 3, 3]; % number of PCs for the distint structures 
sumR = Rgc + sum(Rlc) + sum(Rd);

% noise levels used in the data simulation process
SNRs = [SNRgc, SNRlc, SNRd];

% form the block sparse pattern
blocks_sparse_index = cell(7,1);
blocks_sparse_index{1} = 1:sum(ds);        % C123
blocks_sparse_index{2} = 1:sum(ds(1:2));   % C12
blocks_sparse_index{3} = [1:ds(1), (sum(ds(1:2))+1):sum(ds)]; % C13
blocks_sparse_index{4} = (sum(ds(1))+1):sum(ds); % C23
blocks_sparse_index{5} = 1:sum(ds(1)); % D1
blocks_sparse_index{6} = (ds(1)+1):(sum(ds(1:2))); % D2
blocks_sparse_index{7} = (sum(ds(1:2))+1):sum(ds); % D3

% status of if the condition is satisfied
rejection = 0;

% reference 
rejection_ref = [all(SNRgc)*ones(1,3),all(SNRlc)*ones(1,9),all(SNRd)*ones(1,9)];

% times of simulation
times_simu = 0;

while (rejection == 0),
    
    rejection_vec = nan(1,sumR);
    
    % simulate data sets
	[dataSimulation] = dataSimulation_GGG_pro(n,ds,SNRgc,SNRlc,SNRd,noises,sparse_ratio);
	U_simu = dataSimulation.U_simu;
	D_simu = dataSimulation.D_simu;
	V_simu = dataSimulation.V_simu;
	E_simu = dataSimulation.E_simu;

    % test if all the components are larger than ntimes of the noise
    for i = 1:length(SNRs)
        % index out the structures
        index_factors = (3*(i - 1)+1):3*i;
        Theta_factors = U_simu(:,index_factors)*diag(D_simu(index_factors,1))*V_simu(:,index_factors)';
        index_variables = blocks_sparse_index{i};
        Theta_factors = Theta_factors(:,index_variables);
        E_factors     = E_simu(:,index_variables);
        
        % compare the signal to noise level
        [~,signal_factors,~] = fastSVD(Theta_factors,3);
        signal_factors       = diag(signal_factors);
        [~,noise_factor,~]   = fastSVD(E_factors,1);
        noise_factor = diag(noise_factor);
        rejection_vec(1,index_factors) =  max(0,sign(signal_factors - ntimes_noise*noise_factor));
    end
    
    % test if the simulated structure is proper
    rejection = all(rejection_vec == rejection_ref);
    
    times_simu = times_simu + 1;
  
end
dataSimulation.times_simu = times_simu;

end

