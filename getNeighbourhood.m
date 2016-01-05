function [neighbourhood, mask] = getNeighbourhood(padded_output_image, padded_filled_map, pix_row, pix_col, window_size)
% Returns the (window_size x window_size) neighbourhood about the point 
% (pix_row, pix_col) from a padded output_image, as well as a mask
% indicating which pixel positions are valid (have been filled by the
% algorithm).
% 
% Inputs:
%   padded_output_image: the output image, padded by a half_window margin
%                        on all sides
%   padded_filled_map: the map of filled pixel positions, padded by a
%                      half-window margin on all sides
%   pix_row: the row of the pixel at the center of the neighbourhood
%   pix_col: the col of the pixel at the center of the neighbourhood
%   window_size: the side length of the neighbourhood/mask
% 
% Outputs:
%   neighbourhood: a square (window_size x window_size) region about the
%                  point (pix_row, pix_col) in the output image
%   mask: a square (window_size x window_size region about the point 
%         (pix_row, pix_col) in the filled map
% 
% Note: window_size should be odd

half_window = floor(window_size / 2);

% Add a half window to pix_row and pix_col, to get past the margin of the
% padded images
pix_row = pix_row + half_window;
pix_col = pix_col + half_window;

neighbourhood = padded_output_image(pix_row-half_window:pix_row+half_window, pix_col-half_window:pix_col+half_window, :);
mask = padded_filled_map(pix_row-half_window:pix_row+half_window, pix_col-half_window:pix_col+half_window, :);