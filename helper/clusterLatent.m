function [  labelsLocal, ...
            labelsLocalH, ...
            labelsLocalW, ...
            centroids, ...
            centroidsH, ...
            centroidsW ...
            ] = clusterLatent(  optCluster, ...
                                subZ, ...
                                constraints_array, ...
                                constraints_array_H, ...
                                constraints_array_W, ...
                                subtemp, ...
                                subtempH)

    [   labelsInitial, ...
        labelsInitialH, ...
        labelsInitialW] = initializeLabels( subtemp, ...
                                            subtempH, ...
                                            constraints_array, ...
                                            constraints_array_H, ...
                                            constraints_array_W);

    if optCluster == 1
        disp('roof')
        [labelsLocal,centroids] = constrainedKMeans_DEC(subZ(1,:), ...
            sum(constraints_array(:,3)~=0), ...
            constraints_array(constraints_array(:,3)>0,4), 50, labelsInitial);
        disp('height')
        [labelsLocalH,centroidsH] = constrainedKMeans_DEC(subZ(2,:), ...
            sum(constraints_array_H(:,3)~=0), ...
            constraints_array_H(constraints_array_H(:,3)>0,4), 50, labelsInitialH);
        disp('wall')
        [labelsLocalW,centroidsW] = constrainedKMeans_DEC(subZ(3,:), ...
            sum(constraints_array_W(:,3)~=0), ...
            constraints_array_W(constraints_array_W(:,3)>0,4), 50, labelsInitialW);
    end

end

