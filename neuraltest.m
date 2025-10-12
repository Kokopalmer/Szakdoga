test = [30,60,3,0.100000000000000,600,28.9701970443351,25,25,25,25,1,0.800000000000000];
nNets = 10;
nSamples = size(test,1);
PREDICTED_vec_0531 = zeros(nNets, nSamples);

for i = 1:nNets
    PREDICTED_vec_0531(i,:) = sim(bootstat{i,1}, test.');
end

PREDICTED_mean_0531   = mean(PREDICTED_vec_0531, 1);
PREDICTED_mean_0531