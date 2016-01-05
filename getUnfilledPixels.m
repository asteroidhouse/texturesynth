function unfilled_pixels = getUnfilledPixels(filled_map)
% Returns a list (column vector) of positions of the next layer of unfilled 
% pixels. The 
%
% Inputs:
%   filled_map: a binary matrix with 1s representing filled pixels
% 
% Outputs:
%   unfilled_pixels: a column vector with positions of the next layer
%                    (onion skin order) of pixels that need to be filled

% Subtract the original image from its 1-pixel dilation, and return the
% positions of the non-zero elements of the difference image.
SE = strel('square', 3);
dilated_map = imdilate(filled_map, SE);
diff_image = dilated_map - filled_map;
% These pixels will be in a single column, not pairs of (row, col)
unfilled_pixels = find(diff_image)'; 