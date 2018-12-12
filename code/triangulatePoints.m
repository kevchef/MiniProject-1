function [keep_triang, X_new] = triangulatePoints(C, F, T, T_mat)
%triangulatePoints triangulates every point. 
% input:
% C: all keypoints in current frame in pixel coordinates, 2xM
% F: all keypoints in previous frames in pixel coordinates, 2xM
% T: Transformation matrix from current camera to World, 4x4
% T_mat: Matrix containing all transformation matrices for every keypoint
% in F as a row vector, 16xM
% output: 
% keep_triang: logical vector, containing ones for points in C for 
% which baseline is large enough 1xN
% X_new: stores newly triangulated points, 3xnnz(keep_triang)

keep_triang = [];
X_new = [];

Tc = T(1:3,:);

for i=1:size(C,2)
    c = [C(:,i); 1];
    f = [F(:,i); 1];
    Tf = reshape(T_mat(:,i),[4 4]);

    Tff = Tf(1:3,:);
    
    % TODO: only keep points that are triangulated with a min. accuracy!
    X = linearTriangulation(c,f,Tc,Tff);
    X = X(1:3);
    
    if(checkBaseline(X, T, Tf(:,end), 0.2))
        keep_triang = [keep_triang true];
        X_new = [X_new X]; 
    else
        keep_triang = [keep_triang false];
    end
end

keep_triang = logical(keep_triang);

end



