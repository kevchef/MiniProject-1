% function [T_W_C, P_inlier, X_inlier] = ransacLocalization(P, X, K)
% % computes the pose of the newest camera based on 2D-3D correspondences
% % database_keypoints: 2x516
% % p_W_landmarks: 3 x 516
% 
% % parameters
% max_reprojection_error = 1;
% keypoint_selection = 3;
% max_num_iteration = 10000;
% 
% for i = 1:max_num_iteration
%     % choose 3 random points
%     [P_sample, idx] = datasample(P, keypoint_selection, 2, 'Replace', false);
%     X_sample = X(:,idx);
% 
%     % normalize and transform query coordinates
%     P_sample_norm = K \ [P_sample; ones(1, length(P_sample))];
%     P_norm = vecnorm(P_sample_norm);
%     P_sample_norm = P_sample_norm ./ P_norm;
% 
%     poses = p3p( X_sample , P_sample_norm );
% 
%     % store the 2 valid transformations
% %     j = 1;
% %     for ii = 1:4:5
% %         R_C_W_p(:,:,j) = real(poses(:,ii+1:ii+3)');
% %         T_C_W_p(:,:,j) = - R_C_W_p(:,:,j) * real(poses(:,ii));
% %         j = j + 1;
% %     end
% 
%     % Decode p3p output
%     R_C_W_p = zeros(3, 3, 2);
%     t_C_W_p = zeros(3, 1, 2);
%     for ii = 0:1
%         R_W_C_ii = real(poses(:, (2+ii*4):(4+ii*4)));
%         t_W_C_ii = real(poses(:, (1+ii*4)));
%         R_C_W_p(:,:,ii+1) = R_W_C_ii';
%         t_C_W_p(:,:,ii+1) = -R_W_C_ii'*t_W_C_ii;
%     end
% 
%     % reproject all points using the two transformation matrices
% %     p_reprojected_1 = reprojectPoints(X', [R_C_W_p(:,:,1), t_C_W_p(:,:,1)], K)';
% %     p_reprojected_2 = reprojectPoints(X', [R_C_W_p(:,:,2), t_C_W_p(:,:,2)], K)';
% 
%     % Count inliers:
%     projected_points = projectPoints(...
%         R_C_W_p(:,:,1) * X + repmat(t_C_W_guess(:,:,1), ...
%         [1 size(X, 2)]), K);
%     difference = P - projected_points;
%     errors = sum(difference.^2, 1);
%     is_inlier = errors < pixel_tolerance^2;
%     
%     % If we use p3p, also consider inliers for the alternative solution.
%     if use_p3p
%         projected_points = projectPoints(...
%             (R_C_W_guess(:,:,2) * X) + ...
%             repmat(t_C_W_guess(:,:,2), ...
%             [1 size(X, 2)]), K);
%         difference = P - projected_points;
%         errors = sum(difference.^2, 1);
%         alternative_is_inlier = errors < pixel_tolerance^2;
%         if nnz(alternative_is_inlier) > nnz(is_inlier)
%             is_inlier = alternative_is_inlier;
%         end
%     end
% 
% 
% 
% 
% 
% 
% 
%     
% 
%     % calculate reprojection error and use the reprojection matrix with the
%     % smaller error
%     p_error_1 = sum((p_reprojected_1 - P).^2); 
%     p_error_2 = sum((p_reprojected_2 - P).^2);
% 
%     if sum(p_error_1) < sum(p_error_2)
%         M = [R_C_W_p(:,:,1), t_C_W_p(:,:,1)];
%         p_error = p_error_1;
% 
%     else
%         M = [R_C_W_p(:,:,2), t_C_W_p(:,:,2)];
%         p_error = p_error_2;
%     end
% 
%     % sort inliers and outliers
%     inliers = p_error < max_reprojection_error^2;
% 
%     if i == 1 | sum(inliers) > max_num_inliers_history
%         best_inlier_mask = inliers;
%         max_num_inliers_history(i) = sum(inliers);
%         R_C_W = M(1:3,1:3);
%         t_C_W = M(:,4);
%     else
%         max_num_inliers_history(i) = max_num_inliers_history(i-1);
%     end
% end
% 
% P_inlier = P(:, best_inlier_mask);
% X_inlier = X(:, best_inlier_mask);
% 
% T_W_C = inv([M; [0, 0, 0, 1]]);
% 
% 
% end




function [T_W_C, P_inlier, X_inlier] = ransacLocalization(P, X, K)
% query_keypoints should be 2x1000
% all_matches should be 1x1000 and correspond to the output from the
%   matchDescriptors() function from exercise 3.
% best_inlier_mask should be 1xnum_matched (!!!) and contain, only for the
%   matched keypoints (!!!), 0 if the match is an outlier, 1 otherwise.

num_iterations = 1000;
pixel_tolerance = 10;
k = 3;

% % Detect and match keypoints.
% query_harris = harris(query_image, harris_patch_size, harris_kappa);
% query_keypoints = selectKeypoints(...
%     query_harris, num_keypoints, nonmaximum_supression_radius);
% query_descriptors = describeKeypoints(...
%     query_image, query_keypoints, descriptor_radius);
% database_descriptors = describeKeypoints(...
%     database_image, database_keypoints, descriptor_radius);
% all_matches = matchDescriptors(...
%     query_descriptors, database_descriptors, match_lambda);
% % Drop unmatched keypoints and get 3d landmarks for the matched ones.
% P = query_keypoints(:, all_matches > 0);
% corresponding_matches = all_matches(all_matches > 0);
% X = p_W_landmarks(:, corresponding_matches);

% % Initialize RANSAC.
% best_inlier_mask = zeros(1, size(P, 2));
% % (row, col) to (u, v)
% P = flipud(P);

best_inlier_mask = zeros(1, size(P, 2));
max_num_inliers_history = zeros(1, num_iterations);
max_num_inliers = 0;

% RANSAC
for i = 1:num_iterations
    % Model from k samples (DLT or P3P)
    [X_sample, idx] = datasample(X, k, 2, 'Replace', false);
    P_sample = P(:, idx);
    
    % Backproject keypoints to unit bearing vectors.
    normalized_bearings = K\[P_sample; ones(1, 3)];
    for ii = 1:3
        normalized_bearings(:, ii) = normalized_bearings(:, ii) / ...
            norm(normalized_bearings(:, ii), 2);
    end

    poses = p3p(X_sample, normalized_bearings);

    % Decode p3p output
    R_C_W_guess = zeros(3, 3, 2);
    t_C_W_guess = zeros(3, 1, 2);
    for ii = 0:1
        R_W_C_ii = real(poses(:, (2+ii*4):(4+ii*4)));
        t_W_C_ii = real(poses(:, (1+ii*4)));
        R_C_W_guess(:,:,ii+1) = R_W_C_ii';
        t_C_W_guess(:,:,ii+1) = -R_W_C_ii'*t_W_C_ii;
    end
    
    % Count inliers:
    projected_points = projectPoints(...
        (R_C_W_guess(:,:,1) * X) + ...
        repmat(t_C_W_guess(:,:,1), ...
        [1 size(X, 2)]), K);
    difference = P - projected_points;
    errors = sum(difference.^2, 1);
    is_inlier = errors < pixel_tolerance^2;
    R_C_W_inlier = R_C_W_guess(:,:,1);
    t_C_W_inlier = t_C_W_guess(:,:,1);
    
    % also consider inliers for the alternative solution.
    projected_points = projectPoints(...
        (R_C_W_guess(:,:,2) * X) + ...
        repmat(t_C_W_guess(:,:,2), ...
        [1 size(X, 2)]), K);
    difference = P - projected_points;
    errors = sum(difference.^2, 1);
    alternative_is_inlier = errors < pixel_tolerance^2;
    if nnz(alternative_is_inlier) > nnz(is_inlier)
        is_inlier = alternative_is_inlier;
        R_C_W_inlier = R_C_W_guess(:,:,2);
        t_C_W_inlier = t_C_W_guess(:,:,2);
    end
    
    % TODO remove this threshold??
    min_inlier_count = 6;
    
    if nnz(is_inlier) > max_num_inliers && ...
            nnz(is_inlier) >= min_inlier_count
        max_num_inliers = nnz(is_inlier);        
        best_inlier_mask = is_inlier;
        R_C_W_best = R_C_W_inlier;
        t_C_W_best = t_C_W_inlier;
    end
    
    max_num_inliers_history(i) = max_num_inliers;
end

% if max_num_inliers == 0
%     R_C_W = [];
%     t_C_W = [];
% else
%     M_C_W = estimatePoseDLT(...
%         P(:, best_inlier_mask>0)', ...
%         X(:, best_inlier_mask>0)', K);
%     R_C_W = M_C_W(:, 1:3);
%     t_C_W = M_C_W(:, end);
% end

P_inlier = P(:, best_inlier_mask);
X_inlier = X(:, best_inlier_mask);

T_W_C = [R_C_W_best', -R_C_W_best'*t_C_W_best; 0,0,0,1];

end

