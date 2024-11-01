function [labels,centroids] = constrainedKMeans_DEC(Z, K, tau, maxiter, labelsInitial)
%Written by Sam Polk (MITLL, 03-39) on 9/8/22. 

% Extract dataset size information
[D,n] = size(Z);

% Assign initial clusters and centroids
if ~isempty(labelsInitial)
    labels = onehotencode(labelsInitial,2,"ClassNames",1:K);
else
    labels = onehotencode(randi(K,n,1),2,"ClassNames",1:K);
end
Z_onehotencoded = repmat(Z,[1,1,K]).*repmat(reshape(labels,[1 n K]),[D 1 1]);
centroids = sum(Z_onehotencoded,2)./sum(repmat(reshape(labels,[1 n K]),[D 1 1]),2); % D n K

% Variable needed for while-loop.
iter = 1; centroid_loss = 1; centroid_loss_prev = 2;% Used to ensure that we not exceed maxiter iterations. 
% 
while iter<maxiter && centroid_loss>1e-4
    % iter

    % Below is our objective function. By default, this script uses 
    objectiveFunction = reshape(0.5*...
        pdist2(     double(sum(extractdata(Z_onehotencoded),3))',...
                    reshape(double(extractdata(centroids)),[K D]) ).^2,...
        [1,n*K]); % Squared Euclidean distance between data points and centroids, vectorized

    % Ensure at most one cluster to be assigned to each point:  
    % A1 has exactly n*K nonzero entries in a (n,n*K) matrix.
    A1 = sparse(repmat((1:n)',1,K),  reshape(1:K*n, [n,K]), ones(n, K));
    b1 = ones(n,1); 

    % Ensure at least one cluster to be assigned to each point: 
    % A2 has exactly n*K nonzero entries in a (n,n*K) matrix.
    A2 = sparse(repmat((1:n)',1,K),  reshape(1:K*n, [n,K]), -ones(n, K));
    b2 = -ones(n,1); 

    % Enforce minimum cluster size constraint:
    % A2 has exactly n*K nonzero entries in a (K,n*K) matrix.
    A3 = sparse(reshape(repmat((1:K)', 1,n)', [n*K,1]),1:n*K, -ones(1,n*K)); 
    b3 = -tau; 

    % Run linear program to get new cluster assignments
    options = optimoptions('intlinprog','Display','none');
    T = intlinprog(objectiveFunction, 1:n*K, [A1; A2; A3], [b1; b2; b3], [], [], zeros(n*K,1), ones(n*K,1), options);
    [~, labelsNew] = max(reshape(T,n,K), [], 2);


    labelsNewOneHot = onehotencode(labelsNew,2,"ClassNames",1:K);
    Z_onehotencoded_new = repmat(Z,[1,1,K]).*repmat(reshape(labelsNewOneHot,[1 n K]),[D 1 1]);
    centroidsNew = sum(Z_onehotencoded_new,2)./sum(repmat(reshape(labelsNewOneHot,[1 n K]),[D 1 1]),2); % D n K
    centroidsNew(isnan(centroidsNew))=0; % fix for empty cluster assignment
    labels = labelsNew;

    % Compare centroids from prior iteration and current iteration. 
    % The following condition will be true if labels do not change across
    % an iteration. We stop in this case and output the current labels.
    % diag(pdist2(centroids, centroidsNew)) 
    % % - this is a good metric for
    % evaluation for publication or paper
    centroid_loss = mse(extractdata(centroids),extractdata(centroidsNew)); %sum(diag(pdist2(extractdata(centroids(:)), extractdata(centroidsNew(:)))))
    if (sum(diag(pdist2(extractdata(centroids(:)), extractdata(centroidsNew(:)))) == zeros(K*D,1)) == K*D) || centroid_loss<=1e-4 || abs(centroid_loss-centroid_loss_prev)<=1e-4
        disp('cluster successful');
        labels = labelsNew;
        centroids = centroidsNew;
        % iter % show final iter
        break
    else
        % Take current centroids and move to next iteration.
        % centroid_loss
        % abs(centroid_loss-centroid_loss_prev)
        labels = labelsNew;
        centroid_loss_prev = centroid_loss;
        centroids = centroidsNew;
        iter = iter+1;
    end
end
        


   