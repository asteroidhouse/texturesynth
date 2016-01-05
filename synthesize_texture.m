function output_image = synthesize_texture(input_image, output_rows, output_cols, window_size)
% Synthesizes texture to produce an output image of any size, given an
% input image containing a sample of the desired texture.
% 
% Inputs:
%   input_image: the image containing a sample of the texture to synthesize
%   output_rows: the desired number of rows in the synthesized image
%   output_cols: the desired number of columns in the synthesized image
%   window_size: the side length of the window used to scan across the
%                input image to look for patches that most closely match
%                the region that is being synthesized
% 
% Outputs:
%   output_image: an (output_rows x output_cols) image containing the
%                 synthesized texture

% For most of the computations below, window_size is assumed to be odd. If
% the user inputs an even window_size, we add 1 to make it odd. The
% rationale for adding 1 rather than subtracting 1 is that larger window
% sizes generally lead to better results, so the output will likely not be
% worse than the user expected.
if mod(window_size, 2) == 0
    window_size = window_size + 1;
end


half_window = floor(window_size / 2);

% Side length of the initial seed chosen randomly from the input image and
% placed in the centre of the output image at the start of the algorithm.
seed_size = 3;

[num_rows, num_cols, num_channels] = size(input_image);

% Create the initial image and map of filled pixels by copying a random 
% seed from the input image.
[output_image, filled_map] = seed_image(input_image, seed_size, output_rows, output_cols);

% To make it easy to retrieve the neighbourhood about any point in the 
% output image (including points at the edges of the image), we pad the 
% output image and map of filled pixels by a half-window sized border of 
% 0 values.
padded_output_image = padarray(output_image, [half_window half_window]);
padded_filled_map = padarray(filled_map, [half_window half_window]);

error_threshold = 0.1;
max_error_threshold = 0.3;

% num_horiz_candidates represents the number of times the window can slide
% (by 1 pixel) in the horizontal direction, and similarly, 
% num_vert_candidates is the number of times the window can slide
% vertically.
num_horiz_candidates = num_rows - window_size + 1;
num_vert_candidates = num_cols - window_size + 1;

% Preallocates an array of the correct size to hold candidate patches from
% the input image. Each candidate patch is represented as a column vector;
% since such a column vector is a reshaped square, it has window_size^2 
% elements. 
candidates = zeros(window_size^2, num_horiz_candidates * num_vert_candidates, num_channels);

% Create candidate patches for each of the channels, using a sliding window
% of size (window_size x window_size).
for channel = 1:num_channels
    candidates(:,:,channel) = im2col(input_image(:,:,channel), [window_size window_size], 'sliding');
end

% These two lines reshape the candidates array to have the colour channels 
% stacked vertically. That is, while the candidates array is (possibly)
% three-dimensional, the stacked_candidate_channels array is always
% two-dimensional; if there are three channels, then the channel values are
% stacked so that everything in the red channel comes first, and then
% beneach that everything in the blue channel, and at the bottom everything
% in the green channel.
permuted_candidates = permute(candidates,[1 3 2]);
stacked_candidate_channels = reshape(permuted_candidates,[],size(candidates,2),1);

% We create the gaussian out of the loop, because it is always the same.
sigma = 6.4;
gaussian = fspecial('gaussian', [window_size window_size], window_size / sigma);

% Reshape the gaussian matrix into a column vector, and replicate.
gaussian_vec = reshape(gaussian, [], 1);
% Repeat the gaussian vertically for each color channel.
gaussian_vec = repmat(gaussian_vec, size(candidates, 3), 1);

% Loop as long as there are still unfilled positions, indicated by 0's in
% the filled_map.
while ~all(all(filled_map))
    
    % Keeps track of whether we have found a matching pixel in this
    % iteration, or not.
    found_match = logical(0);
    
    % Get a list (column vector) of all unfilled pixels
    unfilled_pixels = getUnfilledPixels(filled_map);
    
    for pixel = unfilled_pixels
        [pix_row, pix_col] = ind2sub(size(filled_map), pixel);
        
        % Find the neighbourhood around the current pixel to be filled,
        % as well as a mask showing which pixels in that neighbourhood have
        % been filled. The neighbourhood and mask are both taken from the
        % padded images, to simplify the edge cases.
        [neighbourhood, mask] = getNeighbourhood(padded_output_image, padded_filled_map, pix_row, pix_col, window_size);
        
        % Reshape the neighbourhood into a column. If the neighbourhood
        % has three colour channels, then the values for the colour
        % channels will be stacked vertically: first, the red channel, then
        % the blue, and then green. If it has only one channel, then this
        % works as well, flattening the 2D neighbourhood into a column.
        neighbourhood_vec = reshape(neighbourhood, [], 1);
        % Create a matrix where every column is the neighbourhood, and
        % there are as many columns as there are candidate patches.
        neighbourhood_rep = repmat(neighbourhood_vec, 1, size(candidates, 2));
        
        % Reshape the mask into a column vector.
        mask_vec = reshape(mask, [], 1);
        % Repeat the mask vertically as many times are there are channels.
        % This is because all the channels are masked by a single 2D mask,
        % and when we want to do calculations with multiple channels, we
        % have to multiply all channels by the same mask.
        mask_vec = repmat(mask_vec, size(candidates, 3), 1);
        
        % Find the sum of the valid gaussian elements.
        weight = sum(mask_vec .* gaussian_vec);
        
        % Create a row vector that is essentially a normalized version of
        % the gaussian, with only valid elements (corresponding to 1s in
        % the filled map).
        gaussian_mask = ((gaussian_vec .* mask_vec) / weight)';
        
        % Compute the distances between the current neighbourhood and all
        % of the candidate patches.
        % This line multiplies the row vector gaussian_mask with a matrix
        % of squared errors on the right, yielding a row vector of
        % gaussian-weighted distances between the neighbourhood under
        % consideration and each of the candidate patches in the input
        % image. The row-vector multiplication implicitly sums over the
        % squared distances, while at the same time weighting the distances
        % by their positions within the gaussian.
        distances = gaussian_mask * ((stacked_candidate_channels - neighbourhood_rep) .^ 2);
        
        min_value = min(distances);
        min_threshold = min_value * (1 + error_threshold);
        % Find the positions (indexes) of all distances less than the
        % threshold.
        min_positions = find(distances <= min_threshold);
        
        % Select a patch at random from all the patches with minimum 
        % distances.
        random_col = randi(length(min_positions));
        selected_patch = min_positions(random_col);
        selected_error = distances(selected_patch);
        
        if selected_error < max_error_threshold
           [matched_row, matched_col] = ind2sub([(num_rows-window_size+1) (num_cols-window_size+1)], selected_patch);
           
           % The matched_row and matched_col values correspond to the
           % upper-left corner of the matched candidate patch. We want to
           % take the central point, so we half_window to get there.
           matched_row = matched_row + half_window;
           matched_col = matched_col + half_window;
           
           % Copy the pixel in the middle of the matched candidate into the
           % pixel location we are synthesizing.
           output_image(pix_row, pix_col, :) = input_image(matched_row, matched_col, :);
           
           % Record the fact that a match was found.
           filled_map(pix_row, pix_col) = 1;
           found_match = logical(1);
        end
    end
    
    imshow(output_image);
    
    % Update the interior of the padded images, to reflect the updated
    % pixel that was added (or not) to the output image in this iteration.
    padded_output_image(half_window+1:half_window+output_rows, half_window+1:half_window+output_cols,:) = output_image;
    padded_filled_map(half_window+1:half_window+output_rows, half_window+1:half_window+output_cols) = filled_map;
    
    % If there was no match for any unfilled pixel, we need to make the
    % error threshold higher, or there will be no more progress.
    if ~found_match
        max_error_threshold = max_error_threshold * 1.1;
    end
end
