function [outputArg1,outputArg2] = createGraph(X_batch,nelem)

    A = cell(length(nelem),1);
    for i = 1:length(nelem)
        
        s01 = repmat( X_batch{i,1}(:,1), [1 size(X_batch{i,1},1)] );
        s02 = repmat( X_batch{i,1}(:,2), [1 size(X_batch{i,1},1)] );
        s03 = repmat( X_batch{i,1}(:,3), [1 size(X_batch{i,1},1)] );
        s04 = repmat( X_batch{i,1}(:,4), [1 size(X_batch{i,1},1)] );
        s05 = repmat( X_batch{i,1}(:,5), [1 size(X_batch{i,1},1)] );
        s06 = repmat( X_batch{i,1}(:,6), [1 size(X_batch{i,1},1)] );
        s07 = repmat( X_batch{i,1}(:,7), [1 size(X_batch{i,1},1)] );
        s08 = repmat( X_batch{i,1}(:,8), [1 size(X_batch{i,1},1)] );
        s09 = repmat( X_batch{i,1}(:,9), [1 size(X_batch{i,1},1)] );
        s10 = repmat( X_batch{i,1}(:,10), [1 size(X_batch{i,1},1)] );
        s11 = repmat( X_batch{i,1}(:,11), [1 size(X_batch{i,1},1)] );
        s12 = repmat( X_batch{i,1}(:,12), [1 size(X_batch{i,1},1)] );
        s13 = repmat( X_batch{i,1}(:,13), [1 size(X_batch{i,1},1)] );
        s14 = repmat( X_batch{i,1}(:,14), [1 size(X_batch{i,1},1)] );


        A = ...
            ( (sb.*sb') + (sc.*sc') + (sd.*sd') ) ./ ...
                    ( sqrt(sb.^2+sc.^2+sd.^2) .* sqrt(sb'.^2+sc'.^2+sd'.^2) ) ;
        save("data\graph\Aattribute_cosine_"+ string(i) + ".mat","Aattribute_cosine","-mat")
    end 

end

