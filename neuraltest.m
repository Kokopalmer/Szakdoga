test = [33.3333
    0.0000
  120.0000
    0.3500
   -0.0159
   21.0000
   21.7000
   21.6000
   21.5000
   21.7000
    1.0000
    1.5000];
nNets = 10;
nSamples = size(test,1);
PREDICTED_vec_0531 = zeros(nNets, nSamples);

for i = 1:nNets
    PREDICTED_vec_0531(i,:) = sim(bootstat{i,1}, test.');
end

PREDICTED_mean_0531   = mean(PREDICTED_vec_0531, 1);
PREDICTED_mean_0531