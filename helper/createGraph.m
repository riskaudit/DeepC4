function [A_batch] = createGraph(X_batch,nelem,k)

    A_batch = cell(length(nelem),1);
    for i = 1:length(nelem)

        n_colrow = size(X_batch{i,1},1);
        A = logical(sparse(n_colrow,n_colrow));
        for j = 1:n_colrow
            D = pdist2([X_batch{i,1}(j,11) X_batch{i,1}(j,12)],...
                       [X_batch{i,1}(:,11) X_batch{i,1}(:,12)])';
            [~ , I] = mink(D,k+1);
            A(j,I) = 1;
        end
        A = A | A';
        A_batch{i,1} = A;
    
    end 

end

